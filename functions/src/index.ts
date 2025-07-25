import {onDocumentCreated} from "firebase-functions/v2/firestore";
import * as admin from "firebase-admin";
import * as logger from "firebase-functions/logger";

// Inicializa a aplicação de administração do Firebase
admin.initializeApp();

const db = admin.firestore();
const fcm = admin.messaging();

/**
 * Acionado sempre que um novo documento é criado na coleção 'notifications'.
 * Envia uma notificação em massa para todos os utilizadores.
 */
export const sendGlobalNotification = onDocumentCreated(
  "notifications/{notificationId}",
  async (event) => {
    const snapshot = event.data;
    if (!snapshot) {
      logger.log("Não há dados associados ao evento");
      return;
    }
    const notificationData = snapshot.data();

    const title = notificationData.title;
    const body = notificationData.body;

    const usersSnapshot = await db.collection("users").get();

    const tokens = usersSnapshot.docs
      .map((doc) => doc.data().fcmToken as string | undefined)
      .filter((token): token is string => !!token);

    if (tokens.length === 0) {
      logger.log("Nenhum token encontrado para enviar notificações.");
      return;
    }

    const payload: admin.messaging.MulticastMessage = {
      notification: {
        title: title,
        body: body,
      },
      tokens: tokens,
    };

    try {
      const response = await fcm.sendEachForMulticast(payload);
      logger.log(
        "Notificações enviadas com sucesso:",
        `${response.successCount} mensagens.`
      );
    } catch (error) {
      logger.error("Erro ao enviar notificações:", error);
    }
  });

/**
 * NOVO: Acionado sempre que uma nova mensagem é criada numa sala de chat.
 * Envia uma notificação para o destinatário da mensagem.
 */
export const sendChatNotification = onDocumentCreated(
  "chat_rooms/{chatRoomId}/messages/{messageId}",
  async (event) => {
    const snapshot = event.data;
    if (!snapshot) {
      logger.log("Não há dados na mensagem de chat.");
      return;
    }
    const messageData = snapshot.data();
    const chatRoomId = event.params.chatRoomId;

    const senderId = messageData.senderId;
    const messageText = messageData.text;

    // 1. Obtém os dados da sala de chat para encontrar o destinatário
    const chatRoomDoc = await db.collection("chat_rooms").doc(chatRoomId).get();
    const chatRoomData = chatRoomDoc.data();
    if (!chatRoomData) return;

    const participants = chatRoomData.participants as string[];
    const recipientId = participants.find((id) => id !== senderId);

    if (!recipientId) return;

    // 2. Obtém o token FCM do destinatário e o nome do remetente
    const recipientDoc = await db.collection("users").doc(recipientId).get();
    const senderDoc = await db.collection("users").doc(senderId).get();

    const recipientToken = recipientDoc.data()?.fcmToken;
    const senderName = senderDoc.data()?.name ?? "Alguém";

    if (!recipientToken) {
      logger.log("Destinatário não tem um token FCM.");
      return;
    }

    // 3. Cria e envia a notificação
    const payload: admin.messaging.Message = {
      notification: {
        title: `Nova mensagem de ${senderName}`,
        body: messageText,
      },
      token: recipientToken,
    };

    try {
      await fcm.send(payload);
      logger.log("Notificação de chat enviada com sucesso!");
    } catch (error) {
      logger.error("Erro ao enviar notificação de chat:", error);
    }
  });
