import{EntryItem,SiteItem,ENTRIES,SITES,entryByTitle}from'./data';
import router from'@ohos.router';
import promptAction from'@ohos.promptAction';
import { distributedKVStore } from '@kit.ArkData';
import { distributedDeviceManager } from '@kit.DistributedServiceKit';
import { common } from '@kit.AbilityKit';
export interface NoteItem{
id:number;title:string;link:string;text:string;date:string;
}
export interface FavInfo{
title:string;place:string;era:string;kind:string;img:string;date:string;
}
export class store{
static favs:string[]=['二里头遗址','彩陶双耳罐','龙门石窟','青铜鼎','汴梁古城','青铜纵目面具'];
static folderOf:Record<string,string>={'二里头遗址':'待看清单','彩陶双耳罐':'仰韶彩陶','龙门石窟':'石窟造像','青铜鼎':'青铜重器','汴梁古城':'待看清单','青铜纵目面具':'青铜重器'};
static folderNames:string[]=['仰韶彩陶','青铜重器','石窟造像','待看清单'];
static folderImgs:Record<string,string>={'仰韶彩陶':'assets/pottery.jpg','青铜重器':'assets/ding.jpg','石窟造像':'assets/longmen.jpg','待看清单':'assets/erlitou.jpg'};
static seedInfo:Record<string,FavInfo>={
'二里头遗址':{title:'二里头遗址',place:'洛阳 · 偃师区',era:'夏代',kind:'遗址',img:'assets/erlitou.jpg',date:'10-12'},
'彩陶双耳罐':{title:'彩陶双耳罐',place:'马家窑文化 · 半山类型',era:'新石器',kind:'文物',img:'assets/pottery.jpg',date:'10-11'},
'龙门石窟':{title:'龙门石窟',place:'洛阳',era:'北魏',kind:'遗址',img:'assets/longmen.jpg',date:'10-08'},
'青铜鼎':{title:'青铜鼎',place:'郑州',era:'商代',kind:'文物',img:'assets/ding.jpg',date:'09-30'},
'汴梁古城':{title:'汴梁古城',place:'开封 · 龙亭区',era:'宋代',kind:'遗址',img:'assets/kaifeng.jpg',date:'09-27'},
'青铜纵目面具':{title:'青铜纵目面具',place:'三星堆文化',era:'商代',kind:'文物',img:'assets/mask.webp',date:'09-19'}};
static notes:NoteItem[]=[
{id:1,title:'贾湖骨笛笔记',link:'贾湖骨笛',text:'八千年前的骨笛还能吹出完整的七声音阶。做笛子之前先在骨管上算孔距，说明当时已经有音律的概念了，不只是随便钻几个孔。',date:'10-18'},
{id:2,title:'龙门看展记录',link:'龙门石窟',text:'奉先寺的卢舍那大佛是唐代开凿的，站在下面看压迫感很强。下次去洛阳，要留一整天慢慢看西山石窟。',date:'10-21'}];
static detail:EntryItem|undefined=undefined;
static noteLink:string='';
static kv:distributedKVStore.SingleKVStore|undefined=undefined;
static dm:distributedDeviceManager.DeviceManager|undefined=undefined;
static userName:string='';

//启动时由 EntryAbility 调用，打开鸿蒙分布式数据库，把收藏、收藏夹、笔记、用户名读回来
static async init(ctx:common.Context):Promise<void>{
try{
let mgr:distributedKVStore.KVManager=distributedKVStore.createKVManager({context:ctx,bundleName:'com.hetu.appname'});
store.kv=await mgr.getKVStore<distributedKVStore.SingleKVStore>('hetu_local',{
createIfMissing:true,encrypt:false,backup:false,autoSync:true,
kvStoreType:distributedKVStore.KVStoreType.SINGLE_VERSION,
securityLevel:distributedKVStore.SecurityLevel.S1
});
store.dm=distributedDeviceManager.createDeviceManager('com.hetu.appname');
await store.load();
console.log('分布式数据库已就绪');
}catch(e){
console.error('分布式数据库打开失败');
}
}

private static async kvGet(key:string):Promise<string>{
let kv:distributedKVStore.SingleKVStore|undefined=store.kv;
if(kv===undefined){return '';}
try{
return await kv.get(key) as string;
}catch(e){
return '';
}
}

private static async load():Promise<void>{
let rawFavs:string=await store.kvGet('favs');
if(rawFavs!==''){store.favs=JSON.parse(rawFavs) as string[];}
let rawFolders:string=await store.kvGet('folderOf');
if(rawFolders!==''){store.folderOf=JSON.parse(rawFolders) as Record<string,string>;}
let rawNotes:string=await store.kvGet('notes');
if(rawNotes!==''){store.notes=JSON.parse(rawNotes) as NoteItem[];}
let rawNames:string=await store.kvGet('folderNames');
if(rawNames!==''){store.folderNames=JSON.parse(rawNames) as string[];}
let rawImgs:string=await store.kvGet('folderImgs');
if(rawImgs!==''){store.folderImgs=JSON.parse(rawImgs) as Record<string,string>;}
store.userName=await store.kvGet('userName');
}

static save():void{
store.persist();
}

private static async persist():Promise<void>{
let kv:distributedKVStore.SingleKVStore|undefined=store.kv;
if(kv===undefined){return;}
try{
await kv.put('favs',JSON.stringify(store.favs));
await kv.put('folderOf',JSON.stringify(store.folderOf));
await kv.put('notes',JSON.stringify(store.notes));
await kv.put('folderNames',JSON.stringify(store.folderNames));
await kv.put('folderImgs',JSON.stringify(store.folderImgs));
await kv.put('userName',store.userName);
store.syncAll();
}catch(e){
console.error('分布式数据库写入失败');
}
}

//本机改完就推给同账号的可信设备，网络恢复后由 autoSync 继续补齐
private static syncAll():void{
let kv:distributedKVStore.SingleKVStore|undefined=store.kv;
let dm:distributedDeviceManager.DeviceManager|undefined=store.dm;
if(kv===undefined||dm===undefined){return;}
try{
let ids:string[]=[];
dm.getAvailableDeviceListSync().forEach((d:distributedDeviceManager.DeviceBasicInfo)=>{
let nid:string|undefined=d.networkId;
if(nid!==undefined){ids.push(nid);}
});
if(ids.length>0){kv.sync(ids,distributedKVStore.SyncMode.PUSH_PULL);}
}catch(e){
console.error('跨设备同步失败');
}
}

static setLogin(name:string):void{
store.userName=name;
store.save();
}

static clearLogin():void{
store.userName='';
store.save();
}
}
const ALIAS:Record<string,string>={'彩陶双耳罐':'彩陶漩涡纹双耳罐','汴梁古城':'北宋东京城遗址'};
export function isFav(title:string):boolean{
return store.favs.includes(title);
}
export function autoFolder(type:string):string{
if(type==='陶器'){return '仰韶彩陶';}
if(type==='青铜器'){return '青铜重器';}
if(type==='石刻造像'){return '石窟造像';}
return '待看清单';
}
export function toggleFav(e:EntryItem):boolean{
let i:number=store.favs.indexOf(e.title);
if(i>=0){
store.favs.splice(i,1);
store.save();
console.log('取消收藏:',e.title);
return false;
}
store.favs.push(e.title);
store.folderOf[e.title]=autoFolder(e.type);
store.save();
console.log('收藏了:',e.title,'进夹子:',store.folderOf[e.title]);
return true;
}
export function removeFav(title:string):void{
let i:number=store.favs.indexOf(title);
if(i>=0){store.favs.splice(i,1);}
store.save();
}
export function moveFav(title:string,folder:string):void{
store.folderOf[title]=folder;
store.save();
console.log('移动收藏:',title,'->',folder);
}
export function favCount(folder:string):number{
return store.favs.filter((t:string)=>store.folderOf[t]===folder).length;
}
export function favInfo(title:string):FavInfo{
let seed:FavInfo|undefined=store.seedInfo[title];
if(seed!==undefined){return seed;}
let e:EntryItem|undefined=entryByTitle(title);
if(e!==undefined){
return{title:e.title,place:e.city===''?'':e.province+' · '+e.city,era:e.era,kind:e.type==='遗址建筑'?'遗址':(e.type==='书画'?'图集':'文物'),img:e.img,date:'刚刚'};
}
return{title:title,place:'',era:'',kind:'文物',img:'assets/hero.jpg',date:''};
}
export function resolveEntry(title:string):EntryItem|undefined{
let e:EntryItem|undefined=entryByTitle(title);
if(e!==undefined){return e;}
let real:string|undefined=ALIAS[title];
if(real!==undefined){
e=entryByTitle(real);
if(e!==undefined){return e;}
title=real;
}
let site:SiteItem|undefined=SITES.find((s:SiteItem)=>s.label===title);
if(site!==undefined){
return siteToEntry(site);
}
let seed:FavInfo|undefined=store.seedInfo[title];
if(seed!==undefined){
return{title:seed.title,era:seed.era,eraFull:seed.era,summary:seed.place,loc:seed.place,type:seed.kind==='遗址'?'遗址建筑':'青铜器',city:'',province:'',spec:'',material:'—',museum:'',img:seed.img,detail:seed.place,form:'',meaning:'',story:'',related:''};
}
return undefined;
}
export function siteToEntry(s:SiteItem):EntryItem{
return{title:s.label,era:s.era,eraFull:s.era,summary:s.summary,loc:s.place,type:'遗址建筑',city:'',province:'',spec:'',material:'—',museum:'',img:s.img,detail:s.summary,form:'',meaning:'',story:'',related:''};
}
export function openEntry(e:EntryItem):void{
store.detail=e;
router.pushUrl({url:'pages/detail',params:{title:e.title}});
}
export function openTitle(title:string):void{
let e:EntryItem|undefined=resolveEntry(title);
if(e!==undefined){
openEntry(e);
}else{
promptAction.showToast({message:'这条暂时没有详情'});
}
}
export function openSite(s:SiteItem):void{
openEntry(siteToEntry(s));
}
export function isFavEntry(e:EntryItem):boolean{
if(isFav(e.title)){return true;}
return Object.keys(ALIAS).some((k:string)=>ALIAS[k]===e.title&&isFav(k));
}
export function toggleFavEntry(e:EntryItem):boolean{
if(isFav(e.title)){return toggleFav(e);}
let aliasKey:string|undefined=Object.keys(ALIAS).find((k:string)=>ALIAS[k]===e.title);
if(aliasKey!==undefined&&isFav(aliasKey)){
removeFav(aliasKey);
return false;
}
return toggleFav(e);
}
export function todayStr():string{
let d:Date=new Date();
return(d.getMonth()+1)+'-'+d.getDate();
}
