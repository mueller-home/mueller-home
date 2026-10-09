// StaffKeeping 0.31 – geschützter, wiederholbarer Löschlauf.
// Deployment: Supabase Edge Functions, JWT-Prüfung aktiviert lassen.
// SUPABASE_SERVICE_ROLE_KEY ausschliesslich serverseitig als Function Secret.
import { createClient } from 'https://esm.sh/@supabase/supabase-js@2';

const cors = {
  'Access-Control-Allow-Origin': 'https://www.mueller-home.me',
  'Access-Control-Allow-Headers': 'authorization, x-client-info, apikey, content-type',
  'Access-Control-Allow-Methods': 'POST, OPTIONS',
  'Vary': 'Origin',
};
function json(status: number, data: unknown): Response {
  return new Response(JSON.stringify(data), { status, headers: { ...cors, 'Content-Type': 'application/json' } });
}
function assertNoError<T>(result: { data: T; error: {message:string}|null }): T {
  if (result.error) throw new Error(result.error.message);
  return result.data;
}
Deno.serve(async (request) => {
  if (request.method === 'OPTIONS') return new Response(null, { status: 204, headers: cors });
  if (request.method !== 'POST') return json(405, { error: 'Nur POST erlaubt' });
  const origin = request.headers.get('Origin');
  if (origin && origin !== 'https://www.mueller-home.me') return json(403, { error: 'Herkunft nicht zugelassen' });
  const jwt = request.headers.get('Authorization')?.replace(/^Bearer\s+/i,'');
  if (!jwt) return json(401, { error: 'Anmeldung erforderlich' });
  const url = Deno.env.get('SUPABASE_URL');
  const anonKey = Deno.env.get('SUPABASE_ANON_KEY');
  const serviceKey = Deno.env.get('SUPABASE_SERVICE_ROLE_KEY');
  if (!url || !anonKey || !serviceKey) return json(500, { error: 'Backend nicht eingerichtet' });
  const client = createClient(url, anonKey, { global: { headers: { Authorization: `Bearer ${jwt}` } } });
  const service = createClient(url, serviceKey, { auth: { autoRefreshToken: false, persistSession: false } });
  let requestId: string | null = null;
  try {
    const body = await request.json();
    requestId = typeof body.request_id === 'string' && /^[a-f0-9-]{36}$/i.test(body.request_id) ? body.request_id : null;
    if (!requestId) return json(400, { error: 'Ungültige Löschauftrags-ID' });
    const user = assertNoError(await client.auth.getUser(jwt));
    if (!user.user) return json(401, { error: 'Ungültige Anmeldung' });
    const permitted = assertNoError(await client.rpc('sk_can_execute_business_deletion', { p_request_id: requestId }));
    if (!permitted) return json(403, { error: 'Keine Berechtigung für diesen Löschlauf' });
    const work = assertNoError(await service.rpc('sk_deletion_prepare', { p_request_id: requestId })) as {stage:string,business_id:string|null,users:string[]};
    if (work.stage !== 'database_removed') {
      const businessId = work.business_id;
      if (!businessId) throw Error('Betriebs-ID fehlt');
      for (const bucket of ['sk-business-logos','sk-business-photos']) {
        const store = service.storage.from(bucket);
        // In 0.31 sind pro Betrieb maximal 6 Medien vorgesehen. Mehrfachseiten dennoch berücksichtigen.
        let offset = 0;
        const paths: string[] = [];
        while (true) {
          const files = assertNoError(await store.list(businessId,{limit:100,offset}));
          const batch = files || [];
          paths.push(...batch.filter(f => f.name && f.name !== '.emptyFolderPlaceholder').map(f=>`${businessId}/${f.name}`));
          if (batch.length < 100) break;
          offset += 100;
        }
        if (paths.length) assertNoError(await store.remove(paths));
      }
      assertNoError(await service.rpc('sk_deletion_remove_database', { p_request_id: requestId }));
    }
    const users = Array.isArray(work.users) ? work.users : [];
    for (const id of users) {
      const result = await service.auth.admin.deleteUser(id);
      if (result.error && !/not found|does not exist/i.test(result.error.message)) throw new Error('Auth-Konto konnte nicht entfernt werden: '+result.error.message);
    }
    assertNoError(await service.rpc('sk_deletion_complete', { p_request_id: requestId }));
    return json(200, { status:'completed' });
  } catch (error) {
    if (requestId) {
      try { await service.rpc('sk_deletion_failed', { p_request_id:requestId,p_error:String(error instanceof Error ? error.message : error).slice(0,400) }); } catch { /* Originalfehler unverändert zurückgeben */ }
    }
    return json(409, { error: error instanceof Error ? error.message : 'Löschvorgang fehlgeschlagen – bitte prüfen' });
  }
});
