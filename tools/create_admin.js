/*
Create admin user in Firebase Auth and corresponding Firestore `users/{uid}` document.
Usage:
  1) Obtain a Firebase service account JSON from Firebase Console -> Project Settings -> Service accounts -> Generate new private key.
  2) Save it somewhere secure, e.g. `c:\letsplay\serviceAccountKey.json`.
  3) Run (PowerShell):
     $env:GOOGLE_APPLICATION_CREDENTIALS = "C:\letsplay\serviceAccountKey.json"
     node tools/create_admin.js --email=letsplaysup2025@gmail.com --username=letsplay_admin --password=P@ssw0rd

Or provide `--serviceAccount=path/to/key.json` instead of env var.

Notes:
 - This script requires Node.js (14+) and the `firebase-admin` package.
 - Install deps: `npm init -y; npm i firebase-admin` in the repository root.
 - Keep the service account key private; do NOT commit it to source control.
*/

const fs = require('fs');
const path = require('path');
const admin = require('firebase-admin');
const readline = require('readline');

function getArg(name) {
  const pref = `--${name}=`;
  const arg = process.argv.find(a => a.startsWith(pref));
  return arg ? arg.slice(pref.length) : null;
}

async function main() {
  const email = getArg('email');
  const username = getArg('username');
  let password = getArg('password');
  const serviceAccountPath = getArg('serviceAccount') || process.env.GOOGLE_APPLICATION_CREDENTIALS || path.resolve(__dirname, '..', 'serviceAccountKey.json');

  if (!email || !username) {
    console.error('Missing required argument. Usage: node tools/create_admin.js --email=... --username=... [--password=... ] [--serviceAccount=path]');
    process.exit(1);
  }

  // If password wasn't provided as an argument, prompt for it securely
  if (!password) {
    password = await promptHidden('Enter password (input hidden): ');
    if (!password) {
      console.error('Password not provided. Aborting.');
      process.exit(1);
    }
  }

  // helper: prompt without echoing input
  function promptHidden(query) {
    return new Promise((resolve) => {
      const rl = readline.createInterface({ input: process.stdin, output: process.stdout });
      rl.stdoutMuted = true;
      rl.question(query, (value) => {
        rl.close();
        process.stdout.write('\n');
        resolve(value);
      });
      rl._writeToOutput = function _writeToOutput(stringToWrite) {
        if (rl.stdoutMuted) rl.output.write('*');
        else rl.output.write(stringToWrite);
      };
    });
  }

  if (!fs.existsSync(serviceAccountPath)) {
    console.error(`Service account file not found at ${serviceAccountPath}. Either set --serviceAccount or GOOGLE_APPLICATION_CREDENTIALS env var pointing to the key.`);
    process.exit(1);
  }

  const serviceAccount = require(serviceAccountPath);

  try {
    admin.initializeApp({
      credential: admin.credential.cert(serviceAccount),
    });
  } catch (e) {
    console.error('Failed to initialize Firebase Admin SDK:', e);
    process.exit(1);
  }

  const auth = admin.auth();
  const db = admin.firestore();

  try {
    // Check if user already exists
    let userRecord;
    try {
      userRecord = await auth.getUserByEmail(email);
      console.log(`Auth user already exists: uid=${userRecord.uid}`);
    } catch (err) {
      if (err.code === 'auth/user-not-found' || err.code === 'auth/user-not-found') {
        // create user
        userRecord = await auth.createUser({
          email,
          password,
          emailVerified: true,
          displayName: username,
        });
        console.log(`Created auth user: uid=${userRecord.uid}`);
      } else {
        throw err;
      }
    }

    const uid = userRecord.uid;

    // Upsert Firestore users/{uid}
    const userDocRef = db.collection('users').doc(uid);
    const now = new Date().toISOString();

    const docData = {
      uid,
      email,
      username,
      name: 'Admin',
      phone: '',
      emergencyPhone: '',
      dateOfBirth: '',
      gender: 'Other',
      role: 'Admin',
      metrics: { PAC: 50, SHO: 50, PAS: 50, DRI: 50, DEF: 50, PHY: 50 },
      createdAt: now,
      updatedAt: now,
    };

    await userDocRef.set(docData, { merge: true });
    console.log(`Firestore user doc created/updated at users/${uid}`);

    console.log('Admin creation complete. You can now sign in with the provided credentials.');
    process.exit(0);
  } catch (e) {
    console.error('Error creating admin:', e);
    process.exit(1);
  }
}

main();
