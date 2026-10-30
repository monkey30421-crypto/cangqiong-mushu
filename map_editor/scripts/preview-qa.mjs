import assert from 'node:assert/strict';
import {mkdir} from 'node:fs/promises';
import {fileURLToPath} from 'node:url';
import {chromium} from '/Users/junjiehou/.cache/codex-runtimes/codex-primary-runtime/dependencies/node/node_modules/playwright/index.mjs';

const folder=fileURLToPath(new URL('../qa/',import.meta.url));
await mkdir(folder,{recursive:true});
const browser=await chromium.launch({
 executablePath:'/Applications/Google Chrome.app/Contents/MacOS/Google Chrome',
 headless:true,
 args:['--enable-webgl','--use-gl=angle','--use-angle=swiftshader','--enable-unsafe-swiftshader']
});
const errors=[];
try{
 for(const dpr of [1,2]){
  const context=await browser.newContext({viewport:{width:1440,height:1000},deviceScaleFactor:dpr});
  const page=await context.newPage();
  page.on('pageerror',error=>errors.push(error.message));
  // Observe the runtime's real projection after resize; rendering behavior is unchanged.
  await page.route('**/spine-preview.js',async route=>{
   const response=await route.fetch();
   await route.fulfill({response,body:await response.text()+`
const originalResize=S.SceneRenderer.prototype.resize;
S.SceneRenderer.prototype.resize=function(...args){
 originalResize.apply(this,args);
 if(this.canvas.closest('#preview-stage'))window.previewProjection={
  width:this.canvas.clientWidth,height:this.canvas.clientHeight,
  bufferWidth:this.canvas.width,bufferHeight:this.canvas.height,
  worldWidth:this.camera.viewportWidth,worldHeight:this.camera.viewportHeight
 };
};
const originalDraw=S.SceneRenderer.prototype.drawSkeleton;
S.SceneRenderer.prototype.drawSkeleton=function(skeleton,...args){
 if(this.canvas.closest('#preview-stage')){
  if(Math.abs(Math.abs(skeleton.scaleX)-Math.abs(skeleton.scaleY))>1e-6)window.nonuniformSkeleton=true;
  window.previewScales||=[];
  if(window.previewScales.length<200)window.previewScales.push(Math.abs(skeleton.scaleX));
 }
 return originalDraw.call(this,skeleton,...args);
};
`});
  });
  for(const route of ['/characters','/actions','/monster-actions']){
   await page.goto((process.env.EDITOR_URL||'http://127.0.0.1:3000')+route);
   await page.waitForSelector('#preview-stage canvas[data-ready="true"]');
   for(const width of [1440,1024,1920]){
    await page.setViewportSize({width,height:1000});
    await page.waitForFunction(()=>{const c=document.querySelector('#preview-stage canvas'),p=window.previewProjection;return p&&p.width===c.clientWidth&&p.height===c.clientHeight;});
    const p=await page.evaluate(()=>window.previewProjection);
    const x=p.bufferWidth/p.worldWidth,y=p.bufferHeight/p.worldHeight;
    assert(Math.abs(x-y)<1e-6,`${route} @ ${width}, DPR ${dpr}: X=${x}, Y=${y}`);
    assert(!await page.evaluate(()=>window.nonuniformSkeleton),route+' 模型缩放不一致');
    console.log('UNIFORM_PREVIEW',route,width,'DPR',dpr,'px/world',x.toFixed(4));
   }
   if(route!=='/characters'){
    await page.locator(`[data-select="${route==='/actions'?15:3}"]`).click();
    await page.waitForSelector('#preview-stage canvas[data-ready="true"]');
    await page.locator('#trigger-fx').click();
    await page.waitForTimeout(700);
    const scales=await page.evaluate(()=>window.previewScales);
    assert(scales.length>0);assert(scales.every(s=>Math.abs(s-scales[0])<1e-6),'角色与特效缩放应保持相同');
    if(route==='/actions'){
     await page.waitForFunction(()=>Number(document.querySelector('#preview-stage canvas').dataset.effectStarts)>=3);
    }
   }
   if(dpr===1)await page.locator('.preview-panel').screenshot({path:folder+route.slice(1)+'-aspect-fixed.png'});
  }
  await context.close();
 }
 assert.deepEqual(errors,[]);
 console.log('PREVIEW_ASPECT_QA_OK');
}finally{await browser.close();}
