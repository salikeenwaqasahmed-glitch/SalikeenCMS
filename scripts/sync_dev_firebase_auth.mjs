#!/usr/bin/env node
/**
 * Sync short dev QA accounts on salikeencms (Firebase Auth).
 * Creates new @dev.cms.com users and removes legacy long email names.
 *
 * Usage: node scripts/sync_dev_firebase_auth.mjs
 */

import { readFileSync } from 'fs';
import { homedir } from 'os';
import { join } from 'path';

const DEV_PROJECT = 'salikeencms';
const DEV_PASSWORD = '12345678';

const NEW_DEV_EMAILS = [
  'meditor@dev.cms.com',
  'feditor@dev.cms.com',
  'mapprove@dev.cms.com',
  'fapprove@dev.cms.com',
  'madmin@dev.cms.com',
  'fadmin@dev.cms.com',
];

const LEGACY_DEV_EMAILS = new Set([
  'dev@dev.cms.com',
  'maleeditordev@dev.cms.com',
  'femaleeditordev@dev.cms.com',
  'maleapprovaldev@dev.cms.com',
  'femaleapprovaldev@dev.cms.com',
  'maleadmindev@dev.cms.com',
  'femaleadmindev@dev.cms.com',
]);

function loadRefreshToken() {
  const path = join(homedir(), '.config', 'configstore', 'firebase-tools.json');
  const raw = JSON.parse(readFileSync(path, 'utf8'));
  const token = raw?.tokens?.refresh_token;
  if (!token) throw new Error('No firebase refresh token. Run: firebase login');
  return token;
}

async function accessToken(refreshToken) {
  const body = new URLSearchParams({
    client_id: '563584335869-fgrhgmd47bqnekij5i8b5pr03ho849e6.apps.googleusercontent.com',
    client_secret: 'j9iVZfS8kkCEFUPaAeJV0sAi',
    refresh_token: refreshToken,
    grant_type: 'refresh_token',
  });
  const res = await fetch('https://oauth2.googleapis.com/token', {
    method: 'POST',
    headers: { 'Content-Type': 'application/x-www-form-urlencoded' },
    body,
  });
  const json = await res.json();
  if (!json.access_token) {
    throw new Error(`Token refresh failed: ${json.error ?? JSON.stringify(json)}`);
  }
  return json.access_token;
}

async function listUsers(projectId, token) {
  const users = [];
  let pageToken = '';
  do {
    const url = new URL(
      `https://identitytoolkit.googleapis.com/v1/projects/${projectId}/accounts:batchGet`,
    );
    if (pageToken) url.searchParams.set('pageToken', pageToken);
    const res = await fetch(url, {
      headers: { Authorization: `Bearer ${token}` },
    });
    const json = await res.json();
    if (json.error) throw new Error(`${projectId} list: ${json.error.message}`);
    for (const u of json.users ?? []) users.push(u);
    pageToken = json.nextPageToken ?? '';
  } while (pageToken);
  return users;
}

async function createUser(projectId, email, password, token) {
  const res = await fetch(
    `https://identitytoolkit.googleapis.com/v1/projects/${projectId}/accounts`,
    {
      method: 'POST',
      headers: {
        Authorization: `Bearer ${token}`,
        'Content-Type': 'application/json',
      },
      body: JSON.stringify({
        email,
        password,
        emailVerified: true,
      }),
    },
  );
  const json = await res.json();
  if (json.error?.message?.includes('EMAIL_EXISTS')) return 'exists';
  if (json.error) throw new Error(`${email}: ${json.error.message}`);
  return 'created';
}

async function updatePassword(projectId, localId, password, token) {
  const res = await fetch(
    `https://identitytoolkit.googleapis.com/v1/projects/${projectId}/accounts:update`,
    {
      method: 'POST',
      headers: {
        Authorization: `Bearer ${token}`,
        'Content-Type': 'application/json',
      },
      body: JSON.stringify({
        localId,
        password,
        emailVerified: true,
      }),
    },
  );
  const json = await res.json();
  if (json.error) throw new Error(`update ${localId}: ${json.error.message}`);
}

async function deleteUser(projectId, localId, token) {
  const res = await fetch(
    `https://identitytoolkit.googleapis.com/v1/projects/${projectId}/accounts:delete`,
    {
      method: 'POST',
      headers: {
        Authorization: `Bearer ${token}`,
        'Content-Type': 'application/json',
      },
      body: JSON.stringify({ localId }),
    },
  );
  const json = await res.json();
  if (json.error) throw new Error(json.error.message);
}

async function main() {
  const token = await accessToken(loadRefreshToken());
  const users = await listUsers(DEV_PROJECT, token);
  const byEmail = new Map(
    users.map((u) => [(u.email ?? '').toLowerCase(), u]),
  );

  for (const email of NEW_DEV_EMAILS) {
    const existing = byEmail.get(email);
    if (existing) {
      await updatePassword(DEV_PROJECT, existing.localId, DEV_PASSWORD, token);
      console.log(`UPDATED ${email}`);
      continue;
    }
    const status = await createUser(DEV_PROJECT, email, DEV_PASSWORD, token);
    console.log(`${status === 'created' ? 'CREATED' : 'EXISTS'} ${email}`);
  }

  let removed = 0;
  for (const user of users) {
    const email = (user.email ?? '').toLowerCase();
    if (!LEGACY_DEV_EMAILS.has(email)) continue;
    await deleteUser(DEV_PROJECT, user.localId, token);
    console.log(`DELETED legacy ${email}`);
    removed++;
  }

  console.log(`Done. ${NEW_DEV_EMAILS.length} dev accounts on ${DEV_PROJECT}, removed ${removed} legacy.`);
}

main().catch((e) => {
  console.error(e.message ?? e);
  process.exit(1);
});
