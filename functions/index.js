const functions = require("firebase-functions");
const admin = require("firebase-admin");
const axios = require("axios");

admin.initializeApp();

// URL do webhook do N8N (configure isso nas variáveis de ambiente)
const N8N_WEBHOOK_URL = process.env.N8N_WEBHOOK_URL || "YOUR_N8N_WEBHOOK_URL";

/**
 * Trigger que ouve a criação de novas mensagens na subcoleção 'messages' de um lead.
 * Caminho: leads/{leadId}/messages/{messageId}
 */
exports.sendMessageToN8N = functions.firestore
  .document("leads/{leadId}/messages/{messageId}")
  .onCreate(async (snap, context) => {
    const messageData = snap.data();
    const messageId = context.params.messageId;
    const leadId = context.params.leadId;

    // Verifica se o status é 'pending_send'
    if (messageData.status === "pending_send") {
      try {
        console.log(`Processing message ${messageId} for lead ${leadId}`);

        // Payload para o N8N
        const payload = {
          messageId: messageId,
          leadId: leadId,
          text: messageData.texto,
          customerPhone: messageData.telefone_destino,
          senderUid: messageData.remetente_uid,
          sentAt: messageData.sent_at,
          ...messageData
        };

        // Envia para o N8N
        const response = await axios.post(N8N_WEBHOOK_URL, payload);

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
  });
