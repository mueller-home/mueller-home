// StaffKeeping 0.31.9 – Supabase scheduled dispatch. Never expose Postmark token in browser.
import { createClient } from 'https://esm.sh/@supabase/supabase-js@2';
const env=(name:string)=>Deno.env.get(name)||'';
const htmlEscape=(value:string)=>String(value).replace(/[&<>"']/g,c=>({ '&':'&amp;','<':'&lt;','>':'&gt;','"':'&quot;',"'":'&#39;' }[c]||c));
Deno.serve(async req=>{
 if(req.method!=='POST') return new Response('Method not allowed',{status:405});
 const secret=env('SUPABASE_SERVICE_ROLE_KEY');
 const expectedCronToken=env('SK_MAIL_CRON_TOKEN');
 if(!secret||!expectedCronToken)return new Response('Missing server configuration',{status:503});
 // The Supabase gateway must still validate the Bearer service_role JWT (verify_jwt=true).
 // Our application-level secret is independent of the database service_role key.
 const receivedCronToken=req.headers.get('x-sk-cron-token')||'';
 const sha256=async (s:string)=>new Uint8Array(await crypto.subtle.digest('SHA-256',new TextEncoder().encode(s)));
 const expectedHash=await sha256(expectedCronToken);
 const actualHash=await sha256(receivedCronToken);
 let delta=0;
 for(let i=0;i<expectedHash.length;i++)delta|=expectedHash[i]^actualHash[i];
 if(!receivedCronToken||delta!==0){
  // Diagnostics contain only a categorical reason. Never log headers, tokens, hashes or JWTs.
  const reason=!receivedCronToken?'missing_header':'token_mismatch';
  console.warn(JSON.stringify({component:'sk-registration-mails',version:'0.31.9',event:'cron_auth_rejected',reason}));
  return new Response('Forbidden',{status:403,headers:{'X-SK-Cron-Diagnostic':reason,'Cache-Control':'no-store'}});
 }
 console.info(JSON.stringify({component:'sk-registration-mails',version:'0.31.9',event:'cron_auth_accepted'}));
 const url=env('SUPABASE_URL'),postmark=env('POSTMARK_SERVER_TOKEN'),from=env('SK_MAIL_FROM')||'noreply@mueller-home.me';
 if(!url||!postmark)return new Response('Missing server configuration',{status:503});
 const db=createClient(url,secret,{auth:{persistSession:false}});
 const {data:items,error}=await db.rpc('sk_mail_claim_batch',{p_limit:10});
 if(error)return new Response('Queue unavailable: '+error.message,{status:500});
 const results=[];
 for(const item of items||[]){
  const decision=item.decision as string;
  const heading=decision==='approved'?'Registrierung freigegeben':decision==='changes_requested'?'Bitte Unternehmensprofil nachbessern':'Registrierung abgelehnt';
  const body=decision==='approved'?'Dein Betrieb ist jetzt für den Marktplatz freigegeben.':
   decision==='changes_requested'?'Bitte bearbeite dein Unternehmensprofil und reiche es erneut zur Prüfung ein.':
   'Der Registrierungsantrag wurde abgelehnt.';
  const reason=decision==='approved'?'':`\n\nBegründung: ${item.review_message||'Keine Begründung hinterlegt.'}`;
  const message=`Hallo,\n\n${body}${reason}\n\nÖffne StaffKeeping: https://www.mueller-home.me/staffkeeping/\n\nStaffKeeping`;
  const html=`<p>Hallo,</p><p>${htmlEscape(body)}</p>${reason?`<p><strong>Begründung:</strong> ${htmlEscape(item.review_message||'Keine Begründung hinterlegt.')}</p>`:''}<p><a href="https://www.mueller-home.me/staffkeeping/">StaffKeeping öffnen</a></p><p>StaffKeeping</p>`;
  let ok=false,messageId='',failure='';
  try{
   const response=await fetch('https://api.postmarkapp.com/email',{
    method:'POST',headers:{'X-Postmark-Server-Token':postmark,'Content-Type':'application/json','Accept':'application/json'},
    body:JSON.stringify({From:from,To:item.recipient_email,Subject:`StaffKeeping: ${heading}`,TextBody:message,HtmlBody:html,MessageStream:'outbound'})
   });
   const data=await response.json();ok=response.ok&&data.ErrorCode===0;
   messageId=data.MessageID||'';failure=ok?'':String(data.Message||response.status);
  }catch(e){failure=String(e);}
  const {error:finishError}=await db.rpc('sk_mail_finish',{p_id:item.id,p_ok:ok,p_message_id:messageId,p_error:failure});
  results.push({id:item.id,ok,recorded:!finishError});
 }
 return new Response(JSON.stringify({processed:results.length,results,version:'0.31.9'}),{headers:{'Content-Type':'application/json','Cache-Control':'no-store'}});
});
