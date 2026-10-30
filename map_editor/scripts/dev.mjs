import {createServer} from 'node:http';
import {readFile,stat,realpath} from 'node:fs/promises';
import {resolve,join,extname,sep} from 'node:path';
import {editorRoot,gameRoot,userRoot,initialBackup,resource,spine,json} from './store.mjs';
import {readMaps,saveMaps} from './maps.mjs';
import {configPayload,saveConfig} from './game-data.mjs';
import {previewResource,previewSnapshot} from './preview-resources.mjs';
const endpoints={'/api/characters':'characters','/api/character-actions':'actions','/api/monster-actions':'monsters','/api/items':'items'};
const mime={'.html':'text/html; charset=utf-8','.js':'text/javascript; charset=utf-8','.mjs':'text/javascript; charset=utf-8','.css':'text/css; charset=utf-8','.json':'application/json; charset=utf-8','.spine-json':'application/json; charset=utf-8','.atlas':'text/plain; charset=utf-8','.png':'image/png','.jpg':'image/jpeg','.jpeg':'image/jpeg','.svg':'image/svg+xml'};
export function editorServer({root=gameRoot,runtime=userRoot}={}){return createServer(async(req,res)=>{
 try{
  const url=new URL(req.url,'http://localhost');res.setHeader('Cache-Control','no-store');
  res.setHeader('X-Content-Type-Options','nosniff');
  const send=data=>{res.setHeader('Content-Type','application/json; charset=utf-8');res.end(JSON.stringify(data));};
  if(req.method==='POST'){
   if(req.headers.origin&&new URL(req.headers.origin).host!==req.headers.host)throw Error('仅允许本机编辑器保存');
   if(!req.headers['content-type']?.startsWith('application/json'))throw Error('请求需要 JSON 数据');
   let body='';for await(const chunk of req){body+=chunk;if(body.length>2000000)throw Error('配置数据过大');}const input=JSON.parse(body);
   if(url.pathname==='/api/maps'){send(await saveMaps(input,root,runtime));return;}
   if(endpoints[url.pathname]){send(await saveConfig(endpoints[url.pathname],input.config,input.etag,root));return;}
   res.statusCode=404;send({error:'未知接口'});return;
  }
  if(req.method!=='GET'){res.statusCode=405;res.end();return;}
  if(url.pathname==='/api/health'){send({ok:true,root,restored:true});return;}
  if(url.pathname==='/api/preview-resources'){send(await previewSnapshot(JSON.parse(url.searchParams.get('paths')||'[]'),root));return;}
  if(url.pathname==='/api/maps'){const data=await readMaps(root,runtime);send({maps:data.maps,revision:data.revision});return;}
  if(endpoints[url.pathname]){send(await configPayload(endpoints[url.pathname],root));return;}
  if(url.pathname==='/character-resource'){
   const path=url.searchParams.get('path');
   if(path?.endsWith('.tres')){const result=await previewResource(path,root),info=result.info;send({spine:{...info,revision:result.revision,textures:result.textures,animations:Object.keys(info.animations),clips:info.animations}});return;}
   const file=await resource(path,root);res.setHeader('Content-Type',mime[extname(file)]||'application/octet-stream');res.end(await readFile(file));return;
  }
  if(url.pathname.startsWith('/game-assets/')||url.pathname.startsWith('/character-assets/')){
   const relative=decodeURIComponent(url.pathname.replace(/^\/(?:game-assets|character-assets)\//,''));const file=await resource('res://assets/'+relative,root);res.setHeader('Content-Type',mime[extname(file)]||'application/octet-stream');res.end(await readFile(file));return;
  }
  const base=url.pathname.startsWith('/vendor/')?join(editorRoot,'dist'):join(editorRoot,'public');
  const path=['/','/actions','/characters','/monster-actions','/items'].includes(url.pathname)?'/index.html':decodeURIComponent(url.pathname);
  const file=resolve(base,'.'+path);if(!file.startsWith(base+sep)||(await stat(file)).isDirectory())throw Object.assign(Error('页面不存在'),{status:404});
  res.setHeader('Content-Type',mime[extname(file)]||'application/octet-stream');res.end(await readFile(file));
 }catch(error){res.statusCode=error.status||400;res.setHeader('Content-Type','application/json; charset=utf-8');res.end(JSON.stringify({error:error.message}));}
 });}
if(process.argv[1]?.endsWith('/dev.mjs')){
 const {buildEditor}=await import('./build.mjs');await buildEditor();
 const backup=await initialBackup();console.log('原配置备份：'+backup);
 const port=Number(process.env.PORT||3000),server=editorServer();
 server.on('error',error=>{console.error(error.code==='EADDRINUSE'?`${port} 端口被占用，请关闭原编辑器服务后重试。`:error);process.exitCode=1;});
 server.listen(port,'127.0.0.1',()=>console.log(`地图编辑器已启动： http://localhost:${port}`));
 for(const signal of ['SIGTERM','SIGINT'])process.on(signal,()=>server.close(()=>process.exit(0)));
}
