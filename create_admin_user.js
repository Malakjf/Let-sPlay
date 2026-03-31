// Script to create admin user document in Firestore
const admin = require('firebase-admin');
const serviceAccount = require('./serviceAccountKey.json');

admin.initializeApp({
  credential: admin.credential.cert(serviceAccount)
});

const db = admin.firestore();

async function createAdminUser() {
  const userId = '6qzjF0VPJVUkYsI4rorXAVxchiS2';
  const adminData = {
    uid: userId,
    email: 'letsplaysup2025@gmail.com',
    username: 'letsplaysup2025',
    role: 'Admin',
    phone: '',
    emergencyPhone: '',
    dateOfBirth: '',
    gender: 'Not specified',
    metrics: {
      PAC: 0,
      SHO: 0,
      PAS: 0,
      DRI: 0,
      DEF: 0,
      PHY: 0
    },
    createdAt: admin.firestore.FieldValue.serverTimestamp(),
    updatedAt: admin.firestore.FieldValue.serverTimestamp()
  };

  try {
    await db.collection('users').doc(userId).set(adminData);
    console.log('✅ Admin user document created successfully!');
    process.exit(0);
  } catch (error) {
    console.error('❌ Error creating admin user:', error);
    process.exit(1);
  }
}

createAdminUser();
