const { onDocumentCreated } = require("firebase-functions/v2/firestore");
const { defineSecret } = require("firebase-functions/params");
const admin = require("firebase-admin");
const axios = require("axios");

admin.initializeApp();

const n8nWebhookUrl = defineSecret("N8N_WEBHOOK_URL");

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
