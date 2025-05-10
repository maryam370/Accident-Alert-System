const express = require('express');
const bodyParser = require('body-parser');
const admin = require('firebase-admin');

// Parse the JSON string stored in the environment variable
const serviceAccount = JSON.parse(process.env.GOOGLE_CREDENTIALS);

admin.initializeApp({
  credential: admin.credential.cert(serviceAccount),
});

const app = express();
app.use(bodyParser.json());

app.post('/send-notification', (req, res) => {
  const { token, title, body } = req.body;

  const message = {
    notification: {
      title: title,
      body: body,
    },
    token: token, // the device's FCM token
  };

  admin.messaging().send(message)
    .then((response) => {
      console.log('Successfully sent message:', response);
      res.status(200).send('Notification sent successfully');
    })
    .catch((error) => {
      console.log('Error sending message:', error);
      res.status(500).send('Error sending notification');
    });
});

const port = 3000;
app.listen(port, () => {
  console.log(`Server running on port ${port}`);
});
