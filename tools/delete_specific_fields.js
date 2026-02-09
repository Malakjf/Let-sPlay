const admin = require('firebase-admin');
const serviceAccount = require('../serviceAccountKey.json');

// Initialize Firebase Admin
admin.initializeApp({
  credential: admin.credential.cert(serviceAccount)
});

const db = admin.firestore();

// Specify which fields to delete by name
const FIELDS_TO_DELETE = [
  'Amman Sports Complex',
  'Irbid Indoor Arena',
  'Aqaba Beach Football'
];

async function deleteSpecificFields() {
  try {
    console.log('🔍 Fetching all fields...');
    const fieldsSnapshot = await db.collection('fields').get();
    
    if (fieldsSnapshot.empty) {
      console.log('✅ No fields found in database.');
      return;
    }

    console.log(`📊 Found ${fieldsSnapshot.size} total fields`);
    
    const fieldsToDelete = [];
    
    fieldsSnapshot.forEach(doc => {
      const data = doc.data();
      const fieldName = data.name || '';
      
      if (FIELDS_TO_DELETE.includes(fieldName)) {
        fieldsToDelete.push({
          id: doc.id,
          name: fieldName,
          ref: doc.ref
        });
      }
    });

    if (fieldsToDelete.length === 0) {
      console.log('✅ No matching fields found to delete.');
      return;
    }

    console.log(`\n⚠️  Found ${fieldsToDelete.length} fields to delete:`);
    fieldsToDelete.forEach(field => {
      console.log(`  - ${field.name} (ID: ${field.id})`);
    });

    // Delete the matching fields
    const batch = db.batch();
    fieldsToDelete.forEach(field => {
      batch.delete(field.ref);
    });

    console.log('\n🗑️  Deleting fields...');
    await batch.commit();
    
    console.log(`✅ Successfully deleted ${fieldsToDelete.length} fields!`);
    
  } catch (error) {
    console.error('❌ Error deleting fields:', error);
    process.exit(1);
  }
  
  process.exit(0);
}

// Run the deletion
deleteSpecificFields();
