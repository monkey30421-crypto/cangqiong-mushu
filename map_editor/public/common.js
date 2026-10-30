export const $=(s,root=document)=>root.querySelector(s);
export const $$=(s,root=document)=>[...root.querySelectorAll(s)];
export const esc=value=>String(value??'').replace(/[&<>"']/g,c=>({'&':'&amp;','<':'&lt;','>':'&gt;','"':'&quot;',"'":'&#39;'}[c]));
export const asset=path=>'/game-assets/'+path.replace(/^res:\/\/assets\//,'').split('/').map(encodeURIComponent).join('/');
export const copy=value=>structuredClone(value);
export async function api(url,data){const r=await fetch(url,data===undefined?{}:{method:'POST',headers:{'Content-Type':'application/json'},body:JSON.stringify(data)});const value=await r.json();if(!r.ok)throw Error(value.error||'请求失败');return value;}
export function toast(message,error=false){const el=$('#toast');el.textContent=message;el.classList.toggle('error',error);el.style.display='block';clearTimeout(toast.timer);toast.timer=setTimeout(()=>el.style.display='none',error?7000:3500);}
export function options(values,current,empty){let html=empty===undefined?'':`<option value="">${esc(empty)}</option>`;for(const entry of values){const [value,label]=Array.isArray(entry)?entry:[entry,entry];html+=`<option value="${esc(value)}" ${String(value)===String(current)?'selected':''}>${esc(label)}</option>`;}return html;}
export const num=(label,value,key,min=0,step='any')=>`<label class="field"><span>${esc(label)}</span><input type="number" data-key="${esc(key)}" value="${esc(value)}" min="${min}" step="${step}"></label>`;
export const short=path=>path?.split('/').at(-1)||'';
export function download(name,value){const url=URL.createObjectURL(new Blob([JSON.stringify(value,null,2)],{type:'application/json'}));const a=document.createElement('a');a.href=url;a.download=name;a.click();setTimeout(()=>URL.revokeObjectURL(url),1000);}
