const { onDocumentCreated } = require("firebase-functions/v2/firestore");
const { onCall } = require("firebase-functions/v2/https");
const { defineSecret } = require("firebase-functions/params");
const admin = require("firebase-admin");
const axios = require("axios");

admin.initializeApp();

const n8nWebhookUrl = defineSecret("N8N_WEBHOOK_URL");

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
