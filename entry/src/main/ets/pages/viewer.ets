import router from'@ohos.router';
import{webview}from'@kit.ArkWeb';
import{util}from'@kit.ArkTS';
import resourceManager from'@ohos.resourceManager';

class glbBridge{
mgr:resourceManager.ResourceManager|undefined=undefined;

private fileNameOf(key:string):string{
if(key==='sancai')return'assets/sancai-camel.glb';
if(key==='ox')return'assets/gilt-ox.glb';
if(key==='horse')return'assets/bronze-horse.glb';
if(key==='mirror')return'assets/star-mirror.glb';
return'';
}

private cachedKey:string='';
private cachedData:Uint8Array=new Uint8Array(0);

readGlbChunk(key:string,offset:number,length:number):string{
const m:resourceManager.ResourceManager|undefined=this.mgr;
if(m===undefined)throw new Error('resourceManager没准备好');
const path:string=this.fileNameOf(key);
if(path==='')throw new Error('不认识的key:'+key);
if(this.cachedKey!==key){
this.cachedData=m.getRawFileContentSync(path);
this.cachedKey=key;
}
const start=Math.max(0,Math.floor(offset));
const end=Math.min(this.cachedData.length,start+Math.max(0,Math.floor(length)));
return new util.Base64Helper().encodeToStringSync(this.cachedData.slice(start,end));
}
}

@Entry
@Component
export struct viewer{
controller:webview.WebviewController=new webview.WebviewController();
@State relicKey:string='sancai';
@State opened:boolean=false;
@State failed:boolean=false;
private tries:number=0;
private timerID:number=-1;
private bridge:glbBridge=new glbBridge();

aboutToAppear():void{
this.bridge.mgr=getContext(this).resourceManager;
const params=router.getParams() as Record<string,string>|undefined;
const key:string|undefined=params!==undefined?params['relicKey']:undefined;
if(key==='sancai'||key==='ox'||key==='horse'||key==='mirror'||key==='dongjing'){
this.relicKey=key;
}
}

aboutToDisappear():void{
this.stopTimer();
}
private jsCode():string{
let fn:string='';
if(this.relicKey==='dongjing'){
fn=`if(typeof openCityVR==='function'){openCityVR();}`;
}else{
fn=`if(typeof openRelic3D==='function'){openRelic3D('${this.relicKey}');}`;
}
return `(function(){try{if(window.location.hash!=='#${this.relicKey}'){window.location.hash='#${this.relicKey}';}var a=document.getElementById('viewer');var b=document.getElementById('cityViewer');if((a&&a.classList.contains('show'))||(b&&b.classList.contains('show'))){return 'ok';}${fn}a=document.getElementById('viewer');b=document.getElementById('cityViewer');if((a&&a.classList.contains('show'))||(b&&b.classList.contains('show'))){return 'ok';}return 'wait';}catch(e){return 'wait';}})()`;
}
private tryOnce():void{
if(this.opened){
this.stopTimer();
return;
}
this.tries++;
this.controller.runJavaScript(this.jsCode(),(error:Error,result:string)=>{
if(!error&&(result==='ok'||result==='"ok"')){
this.opened=true;
this.failed=false;
this.stopTimer();
}else if(this.tries>=30){
this.failed=true;
this.stopTimer();
}
});
}
private startCalling():void{
this.stopTimer();
this.tryOnce();
this.timerID=setInterval(()=>{
this.tryOnce();
},600);
}

private stopTimer():void{
if(this.timerID!==-1){
clearInterval(this.timerID);
this.timerID=-1;
}
}

private reload():void{
this.stopTimer();
this.opened=false;
this.failed=false;
this.tries=0;
this.controller.refresh();
}

build(){
Column(){
Row(){
Text('‹').fontSize(26).fontColor('#FFF6E6').width(40).height(40).textAlign(TextAlign.Center)
.onClick(()=>{
router.back();
})
Column(){
Text(this.relicKey==='dongjing'?'北宋东京城 · 全息 VR':'3D 文物展厅')
.fontSize(17).fontWeight(700).fontColor('#FFF6E6')
Text(this.relicKey==='dongjing'?'全息投影 · 可旋转缩放':'真实扫描模型 · 可旋转缩放')
.fontSize(11).fontColor('#D9C8A4').margin({top:2})
}
.alignItems(HorizontalAlign.Start).layoutWeight(1)
}
.width('100%').padding({left:8,right:16,top:12,bottom:10}).backgroundColor('#1C150C')

Stack(){
Web({src:$rawfile('viewer_3d.html'),controller:this.controller})
.javaScriptAccess(true)
.javaScriptProxy({object:this.bridge,name:'__glbNative',methodList:['readGlbChunk'],controller:this.controller})
.domStorageAccess(true)
.fileAccess(true)
.width('100%').height('100%')
.onConsole((event)=>{
//把网页里的 [3D] 诊断信息（WebGL 是否可用、失败原因）转到 DevEco 的 Log 面板，过滤关键字 [3D]
if(event){
const msg:string=event.message.getMessage();
if(msg.indexOf('[3D]')>=0||msg.indexOf('WebGL')>=0){
console.error('viewer_3d '+msg);
}
}
return false;
})
.onPageEnd(()=>{
if(!this.opened){
this.startCalling();
}
})
if(!this.opened){
Column(){
if(this.failed){
Text('展厅没打开').fontSize(17).fontWeight(700).fontColor('#3A2C14')
Text('模型文件比较大，加载没跟上').fontSize(12).fontColor('#8A7A58').margin({top:8})
Button('重新加载').height(40).fontSize(14).backgroundColor('#8A6D2F').margin({top:18})
.onClick(()=>{
this.reload();
})
}else{
LoadingProgress().width(38).height(38).color('#8A6D2F')
Text('展厅加载中…').fontSize(14).fontColor('#5A4A2A').margin({top:12})
Text(this.relicKey==='dongjing'?'正在打开东京城全息场景':'正在打开真实扫描模型').fontSize(11).fontColor('#A08A5C').margin({top:5})
}
}
.width('100%').height('100%').backgroundColor('#F7F1E3')
.justifyContent(FlexAlign.Center).alignItems(HorizontalAlign.Center)
}
}
.layoutWeight(1).width('100%')
}
.width('100%').height('100%')
.backgroundColor('#1C150C')
}
}
