import * as S from '/vendor/spine.js';
import {api,asset,esc} from './common.js';
const HERO='res://assets/character/art/player_animations/Character-data.tres';
async function info(path){return (await api('/character-resource?path='+encodeURIComponent(path))).spine;}
const liveAsset=(path,revision)=>asset(path)+(revision?'?v='+encodeURIComponent(revision):'');
function queue(c,infos){for(const i of new Map(infos.map(i=>[i.skeleton,i])).values()){c.assetManager.loadText(liveAsset(i.skeleton,i.revision));const aliases=i.textures?Object.fromEntries(i.textures.map(t=>[t.name,liveAsset(t.path,i.revision)])):undefined;c.assetManager.loadTextureAtlas(liveAsset(i.atlas,i.revision),undefined,undefined,aliases);}}
function data(c,i){const loader=new S.AtlasAttachmentLoader(c.assetManager.get(liveAsset(i.atlas,i.revision)));return new S.SkeletonJson(loader).readSkeletonData(JSON.parse(c.assetManager.get(liveAsset(i.skeleton,i.revision))));}
function instance(d,animation,loop=true){const skeleton=new S.Skeleton(d),state=new S.AnimationState(new S.AnimationStateData(d));state.data.defaultMix=0;if(animation&&d.findAnimation(animation))state.setAnimation(0,animation,loop);state.apply(skeleton);skeleton.updateWorldTransform(S.Physics.update);return {skeleton,state,data:d,age:0,duration:d.findAnimation(animation)?.duration||.05};}
function advance(o,dt){o.age+=dt;o.state.update(dt);o.state.apply(o.skeleton);o.skeleton.update(dt);o.skeleton.updateWorldTransform(S.Physics.update);}
function cleanup(c){c.assetManager.dispose();c.renderer.dispose();}
export class NativePreview{
 constructor(stage,description){this.stage=stage;this.description=description;this.version=0;this.paused=false;this.flip=1;this.scale=1;this.instances=[];this.starts=0;this.disposed=false;}
 async show({resource=HERO,animation,upper,lower,effects=[],profile=null},{reload=false}={}){
  const version=++this.version,paused=this.paused;this.stop();this.stage.innerHTML='<div class="preview-message">正在载入游戏资源…</div>';this.paused=reload?paused:false;this.starts=0;this.options={resource,animation,upper,lower,effects,profile};
  try{
   const selected=[upper,lower].filter(Boolean).map(v=>effects.find(e=>e.file===v.file)?.resource).filter(Boolean);
   this.watchUrl='/api/preview-resources?paths='+encodeURIComponent(JSON.stringify([...new Set([resource,...selected,'res://assets/character/art/common_shadow.png'])]));
   const snapshot=await api(this.watchUrl);if(version!==this.version||this.disposed)return;this.fingerprint=snapshot.revision;
   if(resource.endsWith('.png')){this.stage.innerHTML=`<img class="preview-image" src="${liveAsset(resource,snapshot.revision)}" alt="角色模型"><div class="preview-message">实时读取游戏静态模型</div>`;return;}
   const bodyInfo=await info(resource),selections=[['lower',lower],['upper',upper]].filter(([,v])=>v).map(([plane,v])=>({plane,selection:v,effect:effects.find(e=>e.file===v.file)}));
   for(const v of selections){if(!v.effect)throw Error('未找到特效 '+v.selection.file);v.info=await info(v.effect.resource);}
   if(version!==this.version||this.disposed)return;this.stage.innerHTML='<canvas aria-label="角色与特效实时预览"></canvas><div class="preview-message">模型原点 / 等比例预览</div>';const canvas=this.stage.querySelector('canvas');canvas.dataset.resourceRevision=snapshot.revision;canvas.dataset.sourceHash=bodyInfo.skeletonData.hash||'';this.stage.dataset.resourceRevision=snapshot.revision;let body,definitions=[],fx=[],baseScale=1;
   this.stage.dispatchEvent(new CustomEvent('preview-resources-updated',{detail:{resource,body:bodyInfo,effects:selections.map(v=>({file:v.selection.file,info:v.info}))}}));
   const shadowUrl=liveAsset('res://assets/character/art/common_shadow.png',snapshot.revision);
   const trigger=()=>{if(!body)return;for(const def of definitions){const o=instance(def.data,def.animation,false);o.plane=def.plane;fx.push(o);this.starts++;}canvas.dataset.effectStarts=this.starts;};this.trigger=trigger;
   this.player=new S.SpineCanvas(canvas,{webglConfig:{alpha:true,antialias:true,preserveDrawingBuffer:true},app:{
    loadAssets:c=>{queue(c,[bodyInfo,...selections.map(s=>s.info)]);c.assetManager.loadTexture(shadowUrl);},
    initialize:c=>{const d=data(c,bodyInfo),chosen=animation==='__hold_last_frame__'?null:animation||d.animations.find(a=>a.name==='idle')?.name||d.animations[0]?.name;if(chosen&&!d.findAnimation(chosen)){this.fail('源资源中已无动画 '+chosen+'，请重新选择');return;}body=instance(d,chosen,true);definitions=selections.map(v=>({plane:v.plane,data:data(c,v.info),animation:v.selection.animation}));baseScale=Math.min(1.8,270/(d.height||145),260/(d.width||76));this.scale=baseScale;
     body.state.addListener({event:(_,e)=>{if(e.data.name==='action')trigger();},complete:()=>canvas.dataset.cycles=Number(canvas.dataset.cycles||0)+1});
     // Install the listener before applying the animation at time zero, so action@0 fires on every replay.
     if(chosen){body.state.setAnimation(0,chosen,true);body.state.apply(body.skeleton);}canvas.dataset.ready='true';canvas.dataset.animation=chosen||'hold';this.stage.querySelector('.preview-message').textContent=chosen||'沿用最后一帧（游戏运行时）';
     this.replay=()=>{fx=[];this.starts=0;if(chosen){body.state.setAnimation(0,chosen,true);body.state.apply(body.skeleton);}this.paused=false;};
     const events=bodyInfo.clips?.[chosen]?.events||[];if(this.description){this.description.innerHTML=`<p>动作时长 ${Math.round(body.duration*1000)} ms</p><p>${events.length?events.map(e=>`<span class="event-tag">${esc(e.name)} · ${Math.round((e.time||0)*1000)} ms</span>`).join(''):'当前动作无事件'}</p>`+(definitions.length&&!events.some(e=>e.name==='action')?'<p>此动作没有 action 事件，可手动预览特效。</p>':'')+`<p>上下层特效共用角色原点与缩放，每次 action 事件独立触发一次。</p><p title="${esc(bodyInfo.skeleton)}">骨骼：${esc(bodyInfo.skeleton.split('/').at(-1))}</p><p class="preview-live-status">${reload?'已自动重载最新游戏资源':'实时检测游戏资源 · 每秒更新'}</p>`;}
    },
    update:(_,dt)=>{if(this.paused||!body)return;dt=Math.min(dt,.1);advance(body,dt);for(const o of fx)advance(o,dt);fx=fx.filter(o=>o.age<o.duration);canvas.dataset.activeEffects=fx.length;},
    render:c=>{if(!body)return;const r=c.renderer;r.camera.setViewport(380,400);r.camera.position.set(190,200,0);
     // Reset the reference viewport each frame, then fit both axes with the same scale.
     // The sidebar changes width responsively and must not stretch the skeleton or VFX.
     r.resize(S.ResizeMode.Fit);c.clear(0,0,0,0);r.begin();const shadow=c.assetManager.get(shadowUrl);const sh=(profile?.shadowScalePercent??100)/100;let jump=0;if(profile)jump=Number(this.jump||0);const shrink=jump<=1?1-.6*jump:Math.max(0,.8-.4*jump);const sw=105*baseScale*sh*shrink,hh=29*baseScale*sh*shrink;r.drawTexture(shadow,190-sw/2,74-hh/2,sw,hh);
     const pose=o=>{o.skeleton.x=190;o.skeleton.y=74+jump*(profile?.h||130)*baseScale;o.skeleton.scaleX=this.flip*baseScale;o.skeleton.scaleY=baseScale;o.skeleton.updateWorldTransform(S.Physics.pose);r.drawSkeleton(o.skeleton);};fx.filter(o=>o.plane==='lower').forEach(pose);pose(body);fx.filter(o=>o.plane==='upper').forEach(pose);
     if(profile){const color=new S.Color(.55,.95,.7,.8),height=profile.h*baseScale,width=profile.x*baseScale;r.rect(false,190-width/2,74+jump*profile.h*baseScale,width,height,color);}r.line(178,74,202,74,new S.Color(.85,.74,.47,.8));r.line(190,66,190,82,new S.Color(.85,.74,.47,.8));r.end();},
    error:(_,errors)=>this.fail('模型加载失败：'+Object.values(errors).join('；')),dispose:cleanup
   }});
  }catch(e){if(version===this.version)this.fail(e.message);}
  finally{if(version===this.version&&!this.disposed)this.scheduleWatch(version);}
 }
 scheduleWatch(version){clearTimeout(this.watchTimer);this.watchTimer=setTimeout(async()=>{
  if(this.disposed||version!==this.version)return;
  try{if(!document.hidden){const snapshot=await api(this.watchUrl);if(this.disposed||version!==this.version)return;if(snapshot.revision!==this.fingerprint){await this.show(this.options,{reload:true});return;}const status=this.description?.querySelector('.preview-live-status');if(status)status.textContent=snapshot.resources.some(r=>r.pending)?'资源正在写入，等待导出完成…':'实时检测游戏资源 · 每秒更新';}}
  catch{const status=this.description?.querySelector('.preview-live-status');if(status)status.textContent='资源正在替换，稍后自动重试…';}
  if(!this.disposed&&version===this.version)this.scheduleWatch(version);
 },1000);}
 refresh(){return this.show(this.options,{reload:true});}
 fail(text){this.stage.innerHTML=`<div class="preview-message">${esc(text)}</div>`;console.error(text);}
 stop(){clearTimeout(this.watchTimer);this.player?.dispose();this.player=null;this.trigger=null;this.replay=null;}
 dispose(){this.disposed=true;this.version++;this.stop();}
}
export class MapSpineOverlay{
 constructor(canvas,getView){this.canvas=canvas;this.getView=getView;this.version=0;this.disposed=false;}
 async setMap(map){if(this.kind===map.kind)return;this.kind=map.kind;const version=++this.version;this.player?.clear(0,0,0,0);this.player?.dispose();this.player=null;if(map.kind==='city')return;
  try{const [tree,portal]=await Promise.all([info('res://assets/scene/effects/altar_tree/jitanshu_m-data.tres'),info('res://assets/scene/effects/teleport/chuanson_fuben-data.tres')]);if(version!==this.version||this.disposed)return;let t,p;
   this.player=new S.SpineCanvas(this.canvas,{webglConfig:{alpha:true,antialias:true},app:{loadAssets:c=>queue(c,[tree,portal]),initialize:c=>{t=instance(data(c,tree),'3');p=instance(data(c,portal),'1');this.canvas.dataset.ready='true';},update:(_,dt)=>{if(t){advance(t,Math.min(dt,.1));advance(p,Math.min(dt,.1));}},render:c=>{const {map,view,width,height,visible}=this.getView();c.clear(0,0,0,0);if(!t||!visible||map.kind==='city')return;const r=c.renderer;r.camera.setViewport(width/view.zoom,height/view.zoom);r.camera.position.set(view.x+width/view.zoom/2,-view.y-height/view.zoom/2,0);r.resize(S.ResizeMode.Stretch);r.begin();const pose=(o,x,y)=>{o.skeleton.x=x;o.skeleton.y=-y;o.skeleton.updateWorldTransform(S.Physics.pose);r.drawSkeleton(o.skeleton);};for(const e of map.portals)pose(p,...e.effect);pose(t,map.altar[0]+15.00003,map.altar[1]-21);r.end();},error:(_,e)=>console.error('地图 Spine 资源加载失败',e),dispose:cleanup}});
  }catch(e){console.error(e);}
 }
 dispose(){this.disposed=true;this.version++;this.player?.dispose();}
}
