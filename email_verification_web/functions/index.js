/**
 * Import function triggers from their respective submodules:
 *
 * const {onCall} = require("firebase-functions/v2/https");
 * const {onDocumentWritten} = require("firebase-functions/v2/firestore");
 *
 * See a full list of supported triggers at https://firebase.google.com/docs/functions
 */
const functions = require('firebase-functions');

exports.redirectAuthAction = functions.https.onRequest((req, res) => {
  const link = req.query.link; // Get the encoded link from Dynamic Link
  const mode = req.query.mode || (link && new URLSearchParams(new URL(link).search).get('mode'));
  const oobCode = req.query.oobCode || (link && new URLSearchParams(new URL(link).search).get('oobCode'));

  if (!mode || !oobCode) {
    return res.status(400).send('Invalid request: missing mode or oobCode');
  }

  if (mode === 'resetPassword') {
    return res.redirect(`https://eauth-5e352.web.app/reset-password?mode=resetPassword&oobCode=${oobCode}`);
  } else if (mode === 'verifyEmail') {
    return res.redirect(`https://eauth-5e352.web.app/verify-email?mode=verifyEmail&oobCode=${oobCode}`);
  } else {
    return res.status(400).send('Invalid mode');
  }
});
// Create and deploy your first functions
// https://firebase.google.com/docs/functions/get-started

// exports.helloWorld = onRequest((request, response) => {
//   logger.info("Hello logs!", {structuredData: true});
//   response.send("Hello from Firebase!");
// });
