#!/usr/bin/env node
/**
 * Remove stray Firebase Auth users (uses firebase CLI login refresh token).
 *
 * Dev project (salikeencms): drops all @cms.com prod staff + dev@dev.cms.com
 * Prod project (salikeencms-prod): drops any @dev.cms.com dev QA accounts
 *
 * Usage: node scripts/prune_firebase_auth.mjs
 */

import { readFileSync } from 'fs';
import { homedir } from 'os';
import { join } from 'path';

const DEV_PROJECT = 'salikeencms';
const PROD_PROJECT = 'salikeencms-prod';

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

function shouldDeleteDevProject(email) {
  const e = email.toLowerCase();
  if (e === 'dev@dev.cms.com') return true;
  return e.endsWith('@cms.com') && !e.endsWith('@dev.cms.com');
}

function shouldDeleteProdProject(email) {
  return email.toLowerCase().endsWith('@dev.cms.com');
}

async function pruneProject(projectId, predicate, token) {
  const users = await listUsers(projectId, token);
  let deleted = 0;
  for (const user of users) {
    const email = user.email ?? '';
    if (!email || !predicate(email)) continue;
    await deleteUser(projectId, user.localId, token);
    console.log(`DELETED [${projectId}] ${email}`);
    deleted++;
  }
  return deleted;
}

async function main() {
  const token = await accessToken(loadRefreshToken());

  const devRemoved = await pruneProject(DEV_PROJECT, shouldDeleteDevProject, token);
  const prodRemoved = await pruneProject(
    PROD_PROJECT,
    shouldDeleteProdProject,
    token,
  );

  console.log(`Done. Removed ${devRemoved} from ${DEV_PROJECT}, ${prodRemoved} from ${PROD_PROJECT}.`);
}

main().catch((e) => {
  console.error(e.message ?? e);
  process.exit(1);
});
