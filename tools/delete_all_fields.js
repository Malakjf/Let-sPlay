const admin = require('firebase-admin');
const serviceAccount = require('../serviceAccountKey.json');

// Initialize Firebase Admin
admin.initializeApp({
  credential: admin.credential.cert(serviceAccount)
});

const db = admin.firestore();

async function deleteAllFields() {
  try {
    console.log('🔍 Fetching all fields...');
    const fieldsSnapshot = await db.collection('fields').get();
    
    if (fieldsSnapshot.empty) {
      console.log('✅ No fields found. Database is already clean.');
      return;
    }

    console.log(`📊 Found ${fieldsSnapshot.size} fields to delete`);
    
    // Confirm deletion
    console.log('\n⚠️  WARNING: This will permanently delete all fields!');
    console.log('Fields to be deleted:');
    
    fieldsSnapshot.forEach(doc => {
      const data = doc.data();
      console.log(`  - ${data.name || 'Unnamed'} (ID: ${doc.id})`);
    });

    // Delete all fields
    const batch = db.batch();
    fieldsSnapshot.docs.forEach(doc => {
      batch.delete(doc.ref);
    });

    console.log('\n🗑️  Deleting all fields...');
    await batch.commit();
    
    console.log('✅ Successfully deleted all fields!');
    
  } catch (error) {
    console.error('❌ Error deleting fields:', error);
    process.exit(1);
  }
  
  process.exit(0);
}

// Run the deletion
deleteAllFields();
