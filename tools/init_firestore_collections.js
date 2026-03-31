/*
Initialize Firestore collections for Let's Play App
Creates all necessary collections with initial structure and sample data

Usage:
  1) Set up service account JSON (see create_admin.js for instructions)
  2) Run: 
     $env:GOOGLE_APPLICATION_CREDENTIALS = "C:\letsplay\serviceAccountKey.json"
     node tools/init_firestore_collections.js

Options:
  --serviceAccount=path  Path to service account JSON
  --clearAll             Clear existing data before initialization (dangerous!)
*/

const fs = require('fs');
const path = require('path');
const admin = require('firebase-admin');

function getArg(name) {
  const pref = `--${name}`;
  return process.argv.includes(pref);
}

function getArgValue(name) {
  const pref = `--${name}=`;
  const arg = process.argv.find(a => a.startsWith(pref));
  return arg ? arg.slice(pref.length) : null;
}

async function main() {
  const serviceAccountPath = getArgValue('serviceAccount') || 
                             process.env.GOOGLE_APPLICATION_CREDENTIALS || 
                             path.resolve(__dirname, '..', 'serviceAccountKey.json');
  const clearAll = getArg('clearAll');

  if (!fs.existsSync(serviceAccountPath)) {
    console.error(`❌ Service account file not found at ${serviceAccountPath}`);
    console.error('Set GOOGLE_APPLICATION_CREDENTIALS or use --serviceAccount=path');
    process.exit(1);
  }

  const serviceAccount = require(serviceAccountPath);

  try {
    admin.initializeApp({
      credential: admin.credential.cert(serviceAccount),
    });
    console.log('✅ Firebase Admin SDK initialized');
  } catch (e) {
    console.error('❌ Failed to initialize Firebase Admin SDK:', e.message);
    process.exit(1);
  }

  const db = admin.firestore();
  const now = admin.firestore.FieldValue.serverTimestamp();

  try {
    // Clear existing collections if requested
    if (clearAll) {
      console.log('⚠️  Clearing existing collections...');
      await clearCollection(db, 'users');
      await clearCollection(db, 'matches');
      await clearCollection(db, 'fields');
      await clearCollection(db, 'roleRequests');
      await clearCollection(db, 'notifications');
      console.log('✅ Collections cleared');
    }

    console.log('\n📦 Initializing collections...\n');

    // 1. USERS COLLECTION
    console.log('👥 Creating users collection...');
    const usersRef = db.collection('users');
    
    // Sample users (these won't have auth accounts, just Firestore docs for structure)
    const sampleUsers = [
      {
        id: 'sample_admin_001',
        uid: 'sample_admin_001',
        email: 'admin@letsplay.com',
        username: 'admin',
        name: 'Admin User',
        phone: '+1234567890',
        emergencyPhone: '+1234567899',
        dateOfBirth: '1990-01-01',
        gender: 'Male',
        role: 'Admin',
        position: 'Not Applicable',
        country: 'Jordan',
        metrics: { PAC: 80, SHO: 75, PAS: 85, DRI: 70, DEF: 60, PHY: 75 },
        createdAt: now,
        updatedAt: now,
      },
      {
        id: 'sample_organizer_001',
        uid: 'sample_organizer_001',
        email: 'organizer@letsplay.com',
        username: 'organizer1',
        name: 'Organizer User',
        phone: '+1234567891',
        emergencyPhone: '+1234567892',
        dateOfBirth: '1992-05-15',
        gender: 'Male',
        role: 'Organizer',
        position: 'Not Applicable',
        country: 'Jordan',
        metrics: { PAC: 70, SHO: 65, PAS: 75, DRI: 60, DEF: 55, PHY: 70 },
        createdAt: now,
        updatedAt: now,
      },
      {
        id: 'sample_player_001',
        uid: 'sample_player_001',
        email: 'player1@letsplay.com',
        username: 'player1',
        name: 'Player One',
        phone: '+1234567893',
        emergencyPhone: '+1234567894',
        dateOfBirth: '1995-08-20',
        gender: 'Male',
        role: 'Player',
        position: 'Forward',
        country: 'Jordan',
        metrics: { PAC: 85, SHO: 80, PAS: 70, DRI: 85, DEF: 50, PHY: 75 },
        createdAt: now,
        updatedAt: now,
      },
      {
        id: 'sample_player_002',
        uid: 'sample_player_002',
        email: 'player2@letsplay.com',
        username: 'player2',
        name: 'Player Two',
        phone: '+1234567895',
        emergencyPhone: '+1234567896',
        dateOfBirth: '1994-03-10',
        gender: 'Female',
        role: 'Player',
        position: 'Midfielder',
        country: 'Jordan',
        metrics: { PAC: 75, SHO: 70, PAS: 85, DRI: 80, DEF: 65, PHY: 70 },
        createdAt: now,
        updatedAt: now,
      },
    ];

    for (const user of sampleUsers) {
      await usersRef.doc(user.id).set(user);
    }
    console.log(`✅ Created ${sampleUsers.length} sample users`);

    // 2. FIELDS COLLECTION
    console.log('\n⚽ Creating fields collection...');
    const fieldsRef = db.collection('fields');
    
    const sampleFields = [
      {
        id: 'field_001',
        name: 'Amman Sports Complex',
        address: 'Abdali, Amman, Jordan',
        latitude: 31.9566,
        longitude: 35.9450,
        size: '11x11',
        surface: 'Grass',
        pricePerHour: 50.0,
        amenities: ['Parking', 'Lighting', 'Changing Rooms', 'Water'],
        availability: true,
        images: [],
        contactPhone: '+962791234567',
        description: 'Professional grass field with excellent facilities',
        createdAt: now,
        updatedAt: now,
      },
      {
        id: 'field_002',
        name: 'Irbid Indoor Arena',
        address: 'University Street, Irbid, Jordan',
        latitude: 32.5556,
        longitude: 35.8528,
        size: '7x7',
        surface: 'Indoor',
        pricePerHour: 35.0,
        amenities: ['Parking', 'Air Conditioning', 'Changing Rooms', 'Cafeteria'],
        availability: true,
        images: [],
        contactPhone: '+962791234568',
        description: 'Climate-controlled indoor arena perfect for year-round play',
        createdAt: now,
        updatedAt: now,
      },
      {
        id: 'field_003',
        name: 'Aqaba Beach Football',
        address: 'South Beach, Aqaba, Jordan',
        latitude: 29.5321,
        longitude: 35.0063,
        size: '5x5',
        surface: 'Sand',
        pricePerHour: 40.0,
        amenities: ['Beach View', 'Showers', 'Lighting'],
        availability: true,
        images: [],
        contactPhone: '+962791234569',
        description: 'Unique beach football experience with Red Sea views',
        createdAt: now,
        updatedAt: now,
      },
    ];

    for (const field of sampleFields) {
      await fieldsRef.doc(field.id).set(field);
    }
    console.log(`✅ Created ${sampleFields.length} sample fields`);

    // 3. MATCHES COLLECTION
    console.log('\n🏆 Creating matches collection...');
    const matchesRef = db.collection('matches');
    
    const tomorrow = new Date();
    tomorrow.setDate(tomorrow.getDate() + 1);
    const nextWeek = new Date();
    nextWeek.setDate(nextWeek.getDate() + 7);

    const sampleMatches = [
      {
        id: 'match_001',
        title: 'Friday Night League',
        fieldId: 'field_001',
        fieldName: 'Amman Sports Complex',
        date: tomorrow.toISOString().split('T')[0],
        time: '19:00',
        duration: 90,
        maxPlayers: 22,
        currentPlayers: 15,
        pricePerPlayer: 5.0,
        status: 'Open',
        organizerId: 'sample_organizer_001',
        organizerName: 'Organizer User',
        players: [
          { id: 'sample_player_001', name: 'Player One', position: 'Forward' },
          { id: 'sample_player_002', name: 'Player Two', position: 'Midfielder' },
        ],
        description: 'Competitive 11v11 match. All skill levels welcome!',
        createdAt: now,
        updatedAt: now,
      },
      {
        id: 'match_002',
        title: 'Indoor Futsal Tournament',
        fieldId: 'field_002',
        fieldName: 'Irbid Indoor Arena',
        date: nextWeek.toISOString().split('T')[0],
        time: '18:00',
        duration: 60,
        maxPlayers: 14,
        currentPlayers: 8,
        pricePerPlayer: 7.0,
        status: 'Open',
        organizerId: 'sample_organizer_001',
        organizerName: 'Organizer User',
        players: [
          { id: 'sample_player_001', name: 'Player One', position: 'Forward' },
        ],
        description: 'Fast-paced futsal tournament. Limited spots!',
        createdAt: now,
        updatedAt: now,
      },
    ];

    for (const match of sampleMatches) {
      await matchesRef.doc(match.id).set(match);
    }
    console.log(`✅ Created ${sampleMatches.length} sample matches`);

    // 4. ROLE REQUESTS COLLECTION
    console.log('\n📋 Creating roleRequests collection...');
    const roleRequestsRef = db.collection('roleRequests');
    
    const sampleRoleRequests = [
      {
        id: 'request_001',
        userId: 'sample_player_001',
        userName: 'Player One',
        userEmail: 'player1@letsplay.com',
        requestedRole: 'Organizer',
        currentRole: 'Player',
        reason: 'I have experience organizing football events and would like to contribute.',
        status: 'Pending',
        createdAt: now,
        updatedAt: now,
      },
    ];

    for (const request of sampleRoleRequests) {
      await roleRequestsRef.doc(request.id).set(request);
    }
    console.log(`✅ Created ${sampleRoleRequests.length} sample role requests`);

    // 5. NOTIFICATIONS COLLECTION (structure only)
    console.log('\n🔔 Creating notifications collection structure...');
    const notificationsRef = db.collection('notifications');
    
    // Create a single sample notification to establish the collection
    await notificationsRef.doc('sample_notification_001').set({
      id: 'sample_notification_001',
      userId: 'sample_player_001',
      title: 'Welcome to Let\'s Play!',
      message: 'Your account has been created successfully.',
      type: 'System',
      read: false,
      createdAt: now,
    });
    console.log('✅ Created notifications collection structure');

    console.log('\n' + '='.repeat(60));
    console.log('✅ ALL COLLECTIONS INITIALIZED SUCCESSFULLY!');
    console.log('='.repeat(60));
    console.log('\n📊 Summary:');
    console.log(`  • Users: ${sampleUsers.length} sample documents`);
    console.log(`  • Fields: ${sampleFields.length} sample documents`);
    console.log(`  • Matches: ${sampleMatches.length} sample documents`);
    console.log(`  • Role Requests: ${sampleRoleRequests.length} sample documents`);
    console.log(`  • Notifications: Collection structure created`);
    console.log('\n💡 Note: Sample users are Firestore-only. Create real users via app signup or create_admin.js');
    
    process.exit(0);

  } catch (e) {
    console.error('\n❌ Error initializing collections:', e);
    process.exit(1);
  }
}

// Helper function to clear a collection
async function clearCollection(db, collectionName) {
  const collectionRef = db.collection(collectionName);
  const snapshot = await collectionRef.get();
  
  if (snapshot.empty) {
    console.log(`  ℹ️  ${collectionName}: already empty`);
    return;
  }

  const batch = db.batch();
  snapshot.docs.forEach(doc => {
    batch.delete(doc.ref);
  });
  
  await batch.commit();
  console.log(`  ✅ ${collectionName}: deleted ${snapshot.size} documents`);
}

main();
