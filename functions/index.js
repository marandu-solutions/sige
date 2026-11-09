const { onDocumentCreated } = require("firebase-functions/v2/firestore");
const { onCall, HttpsError } = require("firebase-functions/v2/https");
const { defineSecret } = require("firebase-functions/params");
const admin = require("firebase-admin");
const axios = require("axios");

admin.initializeApp();

const n8nWebhookUrl = defineSecret("N8N_WEBHOOK_URL");
const metaAppId = defineSecret("META_APP_ID");
const metaAppSecret = defineSecret("META_APP_SECRET");

/**
 * Resilient secret resolver: checks Secret Manager first, falls back to process.env.
 */
function resolveSecret(secretRef, envKey) {
  try {
    const val = secretRef.value();
    if (val && typeof val === "string" && val.trim() !== "") {
      return val.trim();
    }
  } catch (_) {}
  return (process.env[envKey] || "").trim();
}

/**
 * Helper to extract descriptive error message and code from Meta Graph API errors
 */
function handleMetaAxiosError(error, stepDescription) {
  if (error instanceof HttpsError) {
    throw error;
  }
  console.error(`[completeWhatsAppEmbeddedSignup] Erro em ${stepDescription}:`, error.message);
  if (error.response) {
    const status = error.response.status;
    const metaError = error.response.data && error.response.data.error;
    const msg = metaError
      ? `${metaError.message} (code: ${metaError.code}${metaError.error_subcode ? `, subcode: ${metaError.error_subcode}` : ""})`
      : error.message;

    if (status === 400 || status === 401) {
      if (metaError && (metaError.error_subcode === 36009 || metaError.code === 100)) {
        throw new HttpsError("invalid-argument", `Código de autorização Meta inválido ou expirado: ${msg}`);
      }
      throw new HttpsError("unauthenticated", `Falha de autenticação com a Meta Graph API: ${msg}`);
    }
    if (status === 403) {
      throw new HttpsError("permission-denied", `Permissão negada pela Meta Graph API: ${msg}`);
    }
    if (status === 404) {
      throw new HttpsError("not-found", `Recurso não encontrado na Meta Graph API (${stepDescription}): ${msg}`);
    }
    if (status === 429) {
      throw new HttpsError("resource-exhausted", `Limite de requisições à Meta Graph API excedido (rate limit): ${msg}`);
    }
    if (status >= 500) {
      throw new HttpsError("unavailable", `Servidor da Meta Graph API temporariamente indisponível (HTTP ${status}): ${msg}`);
    }
    throw new HttpsError("internal", `Erro retornado pela Meta Graph API (${stepDescription}): ${msg}`);
  } else if (error.code === "ECONNABORTED" || (error.message && error.message.includes("timeout"))) {
    throw new HttpsError("deadline-exceeded", `Tempo limite esgotado ao comunicar com a Meta Graph API (${stepDescription}).`);
  } else {
    throw new HttpsError("unavailable", `Falha na conexão de rede com a Meta Graph API (${stepDescription}): ${error.message}`);
  }
}

/**
 * Função Callable para enviar vídeos (que excedem o limite do Firestore)
 * Envia o Base64 diretamente para o N8N e salva o registro no Firestore.
 */
exports.sendVideoMessage = onCall(
  {
    secrets: [n8nWebhookUrl],
    maxInstances: 10,
    timeoutSeconds: 300, // Aumentar timeout para uploads lentos
    memory: "1GiB", // Mais memória para processar base64 grande se necessário
  },
  async (request) => {
    // Verifica autenticação
    if (!request.auth) {
      throw new HttpsError('unauthenticated', 'O usuário deve estar autenticado.');
    }

    const { 
      tenantId, 
      atendimentoId, 
      text, 
      base64Video, 
      customerPhone, 
      senderUid, 
      leadId 
    } = request.data;

    if (!base64Video) {
      throw new HttpsError('invalid-argument', 'O vídeo em Base64 é obrigatório.');
    }

    // 1. Cria referência e ID antecipadamente
    const db = admin.firestore();
    const ref = db.collection('tenant').doc(tenantId).collection('interactions').doc();
    const interactionId = ref.id;
    const now = admin.firestore.Timestamp.now();

    // 2. Prepara dados da mensagem para o Firestore (SEM o base64, anexo_url null)
    const messageData = {
      tenant_id: tenantId,
      atendimento_id: atendimentoId,
      texto: text || '',
      is_usuario: true,
      data_envio: now,
      sent_at: now,
      status: 'pending_send',
      remetente_uid: senderUid,
      remetente_tipo: 'vendedor',
      telefone_destino: customerPhone,
      lead_id: leadId,
      mensagemTipo: 'VideoMessage',
      anexo_url: null, 
      anexo_tipo: 'video/mp4'
    };

    const webhookUrl = n8nWebhookUrl.value();
    
    // 3. Payload para o N8N (Estrutura idêntica ao sendMessageToN8N)
    // A única diferença é que dentro de rawMessage, anexo_url recebe o base64
    const payload = {
      interactionId: interactionId,
      tenantId: tenantId,
      text: messageData.texto,
      customerPhone: messageData.telefone_destino,
      senderUid: messageData.remetente_uid,
      sentAt: now,
      messageType: messageData.anexo_tipo ? messageData.anexo_tipo : 'text',
      rawMessage: {
        ...messageData,
        anexo_url: base64Video // Envia o base64 aqui
      }
    };

    try {
      console.log(`Sending video to N8N for tenant ${tenantId}`);
      const response = await axios.post(webhookUrl, payload);
      console.log("N8N response:", response.status);
      
      messageData.status = 'sent';
      messageData.n8n_response_status = response.status;
    } catch (error) {
      console.error("Error sending video to N8N:", error);
      messageData.status = 'error';
      messageData.error_message = error.message || "Unknown error";
    }

    // 4. Salva no Firestore
    await ref.set(messageData);

    // 5. Atualiza o card de atendimento
    await db.collection('tenant').doc(tenantId).collection('atendimentos').doc(atendimentoId).update({
      'ultima_mensagem': '🎥 Vídeo',
      'ultima_mensagem_data': now,
      'mensagens_nao_lidas': 0,
      'data_ultima_atualizacao': now,
    });

    return { success: true, id: interactionId };
  }
);

/**
 * Trigger que ouve a criação de novas mensagens na coleção 'interactions' dentro de um tenant.
 * Caminho: tenant/{tenantId}/interactions/{interactionId}
 */
exports.sendMessageToN8N = onDocumentCreated(
  {
    document: "tenant/{tenantId}/interactions/{interactionId}",
    secrets: [n8nWebhookUrl],
  },
  async (event) => {
    const snap = event.data;
    if (!snap) {
      console.log("No data associated with the event");
      return;
    }
    
    const messageData = snap.data();
    const interactionId = event.params.interactionId;
    const tenantId = event.params.tenantId;

    // Filtra para enviar apenas mensagens com status 'pending_send'
    // O service cria com status 'pending_send' quando enviada pelo app.
    if (messageData.status === "pending_send") {
      try {
        console.log(`Processing interaction ${interactionId} for tenant ${tenantId}`);

        const webhookUrl = n8nWebhookUrl.value();

        // Payload para o N8N
        const payload = {
          interactionId: interactionId,
          tenantId: tenantId,
          text: messageData.texto,
          customerPhone: messageData.telefone_destino,
          senderUid: messageData.remetente_uid,
          sentAt: messageData.data_envio || messageData.sent_at,
          messageType: messageData.anexo_tipo ? messageData.anexo_tipo : 'text', // Define o tipo da mensagem
          rawMessage: messageData
        };

        // Envia para o N8N
        const response = await axios.post(webhookUrl, payload);

        console.log("Response from N8N:", response.status);

        // Atualiza o status para 'sent' se sucesso
        await snap.ref.update({
          status: "sent",
          n8n_response_status: response.status,
          processed_at: admin.firestore.FieldValue.serverTimestamp()
        });

      } catch (error) {
        console.error("Error sending to N8N:", error);

        // Atualiza o status para 'error' se falha
        await snap.ref.update({
          status: "error",
          error_message: error.message || "Unknown error",
          processed_at: admin.firestore.FieldValue.serverTimestamp()
        });
      }
    }
  }
);

/**
 * Callable Function: completeWhatsAppEmbeddedSignup
 * Troca o código OAuth da Meta pelo access_token definitivo, registra webhooks na WABA,
 * consulta metadados do número e persiste atômica e segregadamente no Firestore.
 * Suporta modo simulado se o code iniciar com 'mock_' ou 'sim_'.
 */
exports.completeWhatsAppEmbeddedSignup = onCall(
  {
    secrets: [metaAppId, metaAppSecret],
    maxInstances: 10,
    timeoutSeconds: 60,
    memory: "512MiB",
  },
  async (request) => {
    // 1. Verificação de Autenticação
    if (!request.auth || !request.auth.uid) {
      throw new HttpsError(
        "unauthenticated",
        "O usuário deve estar autenticado para vincular números do WhatsApp."
      );
    }
    const uid = request.auth.uid;

    // 2. Validação dos Parâmetros de Entrada
    if (!request.data || typeof request.data !== "object") {
      throw new HttpsError(
        "invalid-argument",
        "O payload da requisição deve ser um objeto JSON válido."
      );
    }

    const { tenantId, code, wabaId, phoneNumberId } = request.data;
    const missing = [];
    if (!tenantId || typeof tenantId !== "string" || !tenantId.trim()) missing.push("tenantId");
    if (!code || typeof code !== "string" || !code.trim()) missing.push("code");
    if (!wabaId || typeof wabaId !== "string" || !wabaId.trim()) missing.push("wabaId");
    if (!phoneNumberId || typeof phoneNumberId !== "string" || !phoneNumberId.trim()) missing.push("phoneNumberId");

    if (missing.length > 0) {
      throw new HttpsError(
        "invalid-argument",
        `Parâmetros obrigatórios ausentes ou inválidos: ${missing.join(", ")}.`
      );
    }

    const cleanTenantId = tenantId.trim();
    const cleanCode = code.trim();
    const cleanWabaId = wabaId.trim();
    const cleanPhoneNumberId = phoneNumberId.trim();

    // Sanitização contra path traversal
    if (
      cleanTenantId.includes("/") ||
      cleanWabaId.includes("/") ||
      cleanPhoneNumberId.includes("/")
    ) {
      throw new HttpsError(
        "invalid-argument",
        "Identificadores (tenantId, wabaId, phoneNumberId) não podem conter barras (/)."
      );
    }

    // 3. Verificação de Modo de Simulação / Sandbox vs Produção Meta Graph API
    const isSimulation = cleanCode.startsWith("mock_") || cleanCode.startsWith("sim_");

    let appId = "";
    let appSecret = "";

    if (!isSimulation) {
      appId = resolveSecret(metaAppId, "META_APP_ID");
      appSecret = resolveSecret(metaAppSecret, "META_APP_SECRET");

      if (!appId || !appSecret) {
        console.error("[completeWhatsAppEmbeddedSignup] Credenciais da Meta não configuradas no servidor.");
        throw new HttpsError(
          "failed-precondition",
          "As credenciais da Meta (META_APP_ID e META_APP_SECRET) não estão configuradas no servidor."
        );
      }
    }

    const db = admin.firestore();

    // 4. Verificação de Conflito Multi-Tenant (Anti-Hijacking)
    const routingRef = db.collection("whatsapp_routing").doc(cleanPhoneNumberId);
    const existingRoutingSnap = await routingRef.get();
    if (existingRoutingSnap.exists) {
      const existingTenantId = existingRoutingSnap.data().tenant_id;
      if (existingTenantId && existingTenantId !== cleanTenantId) {
        throw new HttpsError(
          "already-exists",
          `Este número de WhatsApp já está associado a outra organização (${existingTenantId}). Desvincule-o antes de conectar.`
        );
      }
    }

    let accessToken = "";
    let phoneMeta = {};

    if (isSimulation) {
      console.log(
        `[completeWhatsAppEmbeddedSignup] Modo SIMULAÇÃO detectado para tenant: ${cleanTenantId}, phoneId: ${cleanPhoneNumberId}`
      );
      accessToken = `EAAG_mock_permanent_token_${Date.now()}_${Math.random().toString(36).substring(2, 9)}`;
      phoneMeta = {
        display_phone_number: "+55 11 98877-6655",
        verified_name: "SIGE Demo Enterprise",
        quality_rating: "GREEN",
        messaging_limit_tier: "TIER_1K",
        code_verification_status: "VERIFIED",
      };
    } else {
      const graphVersion = "v21.0";
      const graphBaseUrl = "https://graph.facebook.com";
      const requestTimeout = 15000;

      // Passo 5a: Troca de code por access_token permanente
      try {
        console.log(`[completeWhatsAppEmbeddedSignup] Solicitando access_token para appId=${appId}`);
        const tokenResponse = await axios.get(`${graphBaseUrl}/${graphVersion}/oauth/access_token`, {
          params: {
            client_id: appId,
            client_secret: appSecret,
            code: cleanCode,
          },
          headers: {
            Accept: "application/json",
          },
          timeout: requestTimeout,
        });

        if (!tokenResponse.data || !tokenResponse.data.access_token) {
          throw new HttpsError("internal", "A resposta da Meta Graph API não contém um access_token válido.");
        }
        accessToken = tokenResponse.data.access_token;
      } catch (err) {
        handleMetaAxiosError(err, "troca de token OAuth (/oauth/access_token)");
      }

      // Passo 4b: Inscrição da WABA no Webhook do App (subscribed_apps)
      try {
        console.log(`[completeWhatsAppEmbeddedSignup] Inscrevendo WABA ${cleanWabaId} em subscribed_apps`);
        await axios.post(
          `${graphBaseUrl}/${graphVersion}/${cleanWabaId}/subscribed_apps`,
          {},
          {
            headers: {
              Authorization: `Bearer ${accessToken}`,
              "Content-Type": "application/json",
              Accept: "application/json",
            },
            timeout: requestTimeout,
          }
        );
      } catch (err) {
        handleMetaAxiosError(err, "inscrição de webhook (/{wabaId}/subscribed_apps)");
      }

      // Passo 4c: Consulta de metadados oficiais do número
      try {
        console.log(`[completeWhatsAppEmbeddedSignup] Consultando metadados do número ${cleanPhoneNumberId}`);
        const metaResponse = await axios.get(`${graphBaseUrl}/${graphVersion}/${cleanPhoneNumberId}`, {
          params: {
            fields: "display_phone_number,verified_name,quality_rating,code_verification_status,messaging_limit_tier",
          },
          headers: {
            Authorization: `Bearer ${accessToken}`,
            Accept: "application/json",
          },
          timeout: requestTimeout,
        });
        phoneMeta = metaResponse.data || {};
      } catch (err) {
        handleMetaAxiosError(err, "consulta de metadados do número (/{phoneNumberId})");
      }
    }

    // 5. Preservação de Estado Existente & Definição de Defaults
    const publicNumberRef = db
      .collection("tenant")
      .doc(cleanTenantId)
      .collection("whatsapp_numbers")
      .doc(cleanPhoneNumberId);

    const existingPublicSnap = await publicNumberRef.get();
    const isExisting = existingPublicSnap.exists;
    const existingData = isExisting ? existingPublicSnap.data() : {};

    let isDefault = true;
    if (!isExisting) {
      const existingNumbersSnap = await db
        .collection("tenant")
        .doc(cleanTenantId)
        .collection("whatsapp_numbers")
        .where("status", "==", "connected")
        .limit(1)
        .get();
      isDefault = existingNumbersSnap.empty;
    } else {
      isDefault = existingData.is_default !== undefined ? existingData.is_default : true;
    }

    const nowServer = admin.firestore.FieldValue.serverTimestamp();
    const nowIso = new Date().toISOString();

    const originalConnectedAt = (isExisting && existingData.connected_at) ? existingData.connected_at : nowServer;
    let originalConnectedAtIso = nowIso;
    if (isExisting && existingData.connected_at) {
      if (typeof existingData.connected_at.toDate === "function") {
        originalConnectedAtIso = existingData.connected_at.toDate().toISOString();
      } else if (typeof existingData.connected_at === "string") {
        originalConnectedAtIso = existingData.connected_at;
      }
    }

    const originalCreatedAt = (existingRoutingSnap.exists && existingRoutingSnap.data().created_at)
      ? existingRoutingSnap.data().created_at
      : nowServer;

    // 6. Persistência Atômica Segregada via db.batch()
    const batch = db.batch();

    // 6a. Cofre Privado (Server-Only): tenant_secrets/{tenantId}/whatsapp_tokens/{phoneNumberId}
    const vaultRef = db
      .collection("tenant_secrets")
      .doc(cleanTenantId)
      .collection("whatsapp_tokens")
      .doc(cleanPhoneNumberId);

    const secretVaultPayload = {
      tenant_id: cleanTenantId,
      waba_id: cleanWabaId,
      phone_number_id: cleanPhoneNumberId,
      access_token: accessToken,
      token_type: "system_user_permanent",
      scopes: ["whatsapp_business_management", "whatsapp_business_messaging"],
      created_by_uid: uid,
      is_simulation: isSimulation,
      created_at: originalCreatedAt,
      updated_at: nowServer,
    };
    batch.set(vaultRef, secretVaultPayload, { merge: true });

    // 6b. Tabela Global de Roteamento O(1): whatsapp_routing/{phoneNumberId}
    const routingPayload = {
      phone_number_id: cleanPhoneNumberId,
      waba_id: cleanWabaId,
      tenant_id: cleanTenantId,
      active: true,
      created_at: originalCreatedAt,
      updated_at: nowServer,
    };
    batch.set(routingRef, routingPayload, { merge: true });

    // 6c. Registro Público no Tenant: tenant/{tenantId}/whatsapp_numbers/{phoneNumberId}
    const publicNumberPayload = {
      id: cleanPhoneNumberId,
      tenant_id: cleanTenantId,
      waba_id: cleanWabaId,
      phone_number_id: cleanPhoneNumberId,
      display_phone_number: phoneMeta.display_phone_number || "+55 11 98877-6655",
      verified_name: phoneMeta.verified_name || "SIGE Demo Enterprise",
      quality_rating: phoneMeta.quality_rating || "GREEN",
      messaging_limit_tier: phoneMeta.messaging_limit_tier || "TIER_1K",
      code_verification_status: phoneMeta.code_verification_status || "VERIFIED",
      status: "connected",
      webhook_subscribed: true,
      is_default: isDefault,
      ia_ativa_neste_numero: isExisting ? (existingData.ia_ativa_neste_numero ?? true) : true,
      connected_by_uid: uid,
      connected_at: originalConnectedAt,
      last_sync_at: nowServer,
      updated_at: nowServer,
    };
    batch.set(publicNumberRef, publicNumberPayload, { merge: true });

    try {
      await batch.commit();
      console.log(
        `[completeWhatsAppEmbeddedSignup] Conexão concluída e comitada com sucesso para ${cleanPhoneNumberId} (tenant: ${cleanTenantId})`
      );
    } catch (batchErr) {
      console.error("[completeWhatsAppEmbeddedSignup] Falha no commit do db.batch():", batchErr);
      throw new HttpsError("internal", "Falha interna ao persistir dados do WhatsApp no Firestore.");
    }

    // 7. Retorno Seguro com Timestamps ISO (evita {} na desserialização do cliente)
    return {
      success: true,
      simulated: isSimulation,
      number: {
        ...publicNumberPayload,
        connected_at: originalConnectedAtIso,
        last_sync_at: nowIso,
        updated_at: nowIso,
      },
    };
  }
);
