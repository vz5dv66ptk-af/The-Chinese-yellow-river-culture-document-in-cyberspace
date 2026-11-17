import{EntryItem,ENTRIES,ERAS,TYPES,PROVINCES,entriesOfProvince,HOT,PERSONAL,TIMELINE,TlItem,entryByTitle,realKeyOf,imgSrc}from'../models/data';
import{openEntry,openTitle}from'../models/store';
import router from'@ohos.router'

interface TlBand{
  name:string;
  from:number;
  to:number;
  color:string}
const TL_BANDS:TlBand[]=[
{name:'新石器时代',from:-7000,to:-2070,color:'#38e2935f'},
{name:'夏',from:-2070,to:-1600,color:'#38A9713D'},
{name:'商',from:-1600,to:-1046,color:'#388C6A2F'},
{name:'周',from:-1046,to:-221,color:'#387A8450'},
{name:'秦汉',from:-221,to:220,color:'#389C6644'},
{name:'魏晋南北朝',from:220,to:589,color:'#38687D6B'},
{name:'隋唐',from:589,to:907,color:'#38A85B32'},
{name:'宋',from:907,to:1200,color:'#385F7A8A'}];

const TL_MIN:number=-7000;
const TL_MAX:number=1200;
const TL_W:number=4400;

const TL_TICKS:number[]=[-7000,-6500,-6000,-5500,-5000,-4500,-4000,-3500,-3000,-2500,-2000,-1500,-1000,-500,0,500,1000];

@Entry
@Component
export struct home{
@State query:string='';
@State eraSel:string='';
@State typeSel:string='';
@State results:EntryItem[]=[];

@State tlNodes:TlItem[]=[];
@State tlLanes:number[]=[];
@State tlProg:number=0;

aboutToAppear():void{
let arr:TlItem[]=[...TIMELINE];
arr.sort((a:TlItem,b:TlItem)=>{
return a.y-b.y;
});
let lanes:number[]=[];
let last:number[]=[-9999,-9999];
for(let i:number=0;i<arr.length;i++){
let x:number=this.tlX(arr[i].y);
let lane:number=0;
if(last[0]+82<=x){
lane=0;
}else if(last[1]+82<=x){
lane=1;
}else{
lane=last[0]<=last[1]?0:1;
}
lanes.push(lane);
last[lane]=x;
}
this.tlNodes=arr;
this.tlLanes=lanes;
}
tlX(y:number):number{
return(y-TL_MIN)/(TL_MAX-TL_MIN)*TL_W;
}

filtering():boolean{
return this.query!==''||this.eraSel!==''||this.typeSel!=='';
}

applyFilter():void{
this.results=ENTRIES.filter((e:EntryItem)=>{
if(this.eraSel!==''&&e.era!==this.eraSel){return false;}
if(this.typeSel!==''&&e.type!==this.typeSel){return false;}
if(this.query!==''){
let text:string=e.title+e.summary+e.loc+e.city+e.eraFull;
if(text.indexOf(this.query)<0){return false;}
}
return true;
});
console.log('筛选出',this.results.length,'件');
}

build(){
Scroll(){
Column(){

Stack(){
Image($rawfile('assets/hero.jpg')).width('100%').height(190).objectFit(ImageFit.Cover)
Column(){
Text('黄河记忆·文明之源').fontSize(28).fontColor('#FFF6E6').fontWeight(700)
Text('黄河 · 千年文脉 · 连接过去与未来').fontSize(12).fontColor('#F3E3BC').margin({top:6})
}.width('100%').alignItems(HorizontalAlign.Start).padding({left:20,top:56})
}.width('100%')

Row(){
Text('🔍').fontSize(14).margin({left:12,right:6})
TextInput({text:this.query,placeholder:'搜索遗址、文物、关键词...'})
.layoutWeight(1).height(40).backgroundColor(Color.Transparent)
.placeholderFont({size:13}).placeholderColor('#99999999')
.onChange((value:string)=>{
this.query=value;
this.applyFilter();
})
}
.width('92%').height(44).borderRadius(22).backgroundColor($r('app.color.white'))
.margin({top:-22}).shadow({radius:8,color:'#22000000',offsetY:2})

Column(){
Row(){
Text('◷').fontSize(15).margin({right:8})
Text('按年代').fontSize(15).fontWeight(700).fontColor('#3A2C14')
}.width('100%').margin({bottom:8})
Flex({direction:FlexDirection.Row,wrap:FlexWrap.Wrap}){
ForEach(ERAS,(t:string)=>{
Text(t).fontSize(12)
.fontColor(this.eraSel===t?$r('app.color.white'):'#5A4A2A')
.backgroundColor(this.eraSel===t?'#8A6D2F':'#F1E8D2')
.padding({left:10,right:10,top:5,bottom:5}).borderRadius(12).margin({right:8,bottom:8})
.onClick(()=>{
this.eraSel=this.eraSel===t?'':t;
this.applyFilter();
})
})
}.width('100%')
Divider().margin({top:4,bottom:12}).color('#E7DCC2')

Row(){
Text('▦').fontSize(15).margin({right:8})
Text('按类型').fontSize(15).fontWeight(700).fontColor('#3A2C14')
}.width('100%').margin({bottom:8})
Flex({direction:FlexDirection.Row,wrap:FlexWrap.Wrap}){
ForEach(TYPES,(t:string)=>{
Text(t).fontSize(12)
.fontColor(this.typeSel===t?$r('app.color.white'):'#5A4A2A')
.backgroundColor(this.typeSel===t?'#8A6D2F':'#F1E8D2')
.padding({left:10,right:10,top:5,bottom:5}).borderRadius(12).margin({right:8,bottom:8})
.onClick(()=>{
this.typeSel=this.typeSel===t?'':t;
this.applyFilter();
})
})
}.width('100%')
}
.width('92%').padding(16).borderRadius(16).backgroundColor('#FFFDF6')
.margin({top:14}).shadow({radius:6,color:'#18000000',offsetY:2})

if(this.filtering()){
Column(){
Text('筛选结果 '+this.results.length+' 件').fontSize(16).fontWeight(700).fontColor('#3A2C14')
.width('100%').margin({bottom:10})
if(this.results.length===0){
Text('没有符合条件的，换个筛选试试').fontSize(13).fontColor('#8A7A58').padding({top:10,bottom:10})
}
ForEach(this.results,(e:EntryItem)=>{

Row(){
Image(imgSrc(e.img)).alt($rawfile('assets/cat-'+e.img.split('cat-')[1])).width(64).height(64).borderRadius(10).objectFit(ImageFit.Cover)

Column(){
Text(e.title).fontSize(15).fontWeight(600).fontColor('#2E2410')
Text(e.era+' · '+e.city).fontSize(11).fontColor('#A08A5C').margin({top:3})
Text(e.summary).fontSize(12).fontColor('#6B5B39').margin({top:3}).maxLines(1)
}.layoutWeight(1).alignItems(HorizontalAlign.Start).margin({left:12})
}
.width('100%').padding({top:8,bottom:8})
.onClick(()=>{
openEntry(e);
})
},(e:EntryItem)=>e.title)
}
.width('92%').margin({top:16}).alignItems(HorizontalAlign.Start)
}

Row(){
Text('♨ 热门推荐').fontSize(17).fontWeight(700).fontColor('#3A2C14').layoutWeight(1)
}.width('92%').margin({top:20,bottom:10})
Scroll(){
Row({space:12}){
ForEach(HOT,(t:string)=>{
Column(){
Image(imgSrc(entryByTitle(t)!==undefined?entryByTitle(t)!.img:'assets/hero.jpg')).alt($rawfile('assets/cat-'+(entryByTitle(t)!==undefined?entryByTitle(t)!.img:'assets/hero.jpg').split('cat-')[1])).width(150).height(104).borderRadius(12).objectFit(ImageFit.Cover)
Text(t).fontSize(14).fontWeight(600).fontColor('#2E2410').margin({top:7}).width(150).maxLines(1)
Text(entryByTitle(t)!==undefined?entryByTitle(t)!.era+' · '+entryByTitle(t)!.city:'').fontSize(11).fontColor('#A08A5C').margin({top:2}).width(150)
}
.onClick(()=>{
openTitle(t);
})
})
}
.padding({left:16,right:16})
}
.scrollable(ScrollDirection.Horizontal).scrollBar(BarState.Off).width('100%')

ForEach(PROVINCES,(p:string)=>{
Row(){
Text(p).fontSize(20).fontWeight(700).fontColor('#3A2C14').layoutWeight(1)
Text(entriesOfProvince(p).length+' 件').fontSize(11).fontColor('#A08A5C')
}.width('92%').margin({top:22,bottom:6})
Divider().width('92%').color('#C9A959')
Scroll(){
Row({space:12}){
ForEach(entriesOfProvince(p),(e:EntryItem)=>{
Column(){
Image(imgSrc(e.img)).alt($rawfile('assets/cat-'+e.img.split('cat-')[1])).width(150).height(104).borderRadius(12).objectFit(ImageFit.Cover)
Text(e.title).fontSize(14).fontWeight(600).fontColor('#2E2410').margin({top:7}).width(150).maxLines(1)
Text(e.era+' · '+e.city).fontSize(11).fontColor('#A08A5C').margin({top:2}).width(150)
}

.onClick(()=>{
openEntry(e);
})
},(e:EntryItem)=>e.title)
}
.padding({left:16,right:16,top:8})
}
.scrollable(ScrollDirection.Horizontal).scrollBar(BarState.Off).width('100%')
},(p:string)=>p)

Stack(){
Image($rawfile('assets/scroll-map.jpg')).width('100%').height(112).borderRadius(16).objectFit(ImageFit.Cover)
Column().width('100%').height(112).borderRadius(16)
.linearGradient({direction:GradientDirection.Right,colors:[['#D917120B',0.0],['#4717120B',0.65],['#0517120B',1.0]]})
Column(){
Text('黄河文化地图').fontSize(18).fontWeight(700).fontColor('#FFF6E6')
Text('沿着黄河，探寻文化的脉络 ›').fontSize(12).fontColor('#F3E3BC').margin({top:5})
}.width('100%').alignItems(HorizontalAlign.Start).padding({left:18,top:30})
}
.width('92%').margin({top:20})
.onClick(()=>{
router.push({url:'pages/map'});
})

Row(){
Text('历史时间轴').fontSize(17).fontWeight(700).fontColor('#3A2C14').layoutWeight(1)
Text('从史前到宋').fontSize(11).fontColor('#A08A5C')
}.width('92%').margin({top:22,bottom:10})
Scroll(){
Stack(){
ForEach(TL_BANDS,(b:TlBand)=>{
Column(){
Text(b.name).fontSize(9).fontColor('#8A6D2F').margin({top:5})
}
.width(this.tlX(b.to)-this.tlX(b.from)).height(188).backgroundColor(b.color)
.position({x:this.tlX(b.from),y:0}).alignItems(HorizontalAlign.Center)
},(b:TlBand)=>b.name)

Column().width(TL_W).height(2).backgroundColor('#C9A959').position({x:0,y:92})

ForEach(TL_TICKS,(t:number)=>{
Column().width(1).height(7).backgroundColor('#B89B4E').position({x:this.tlX(t),y:88})
Text(t<0?'前'+(-t):(t===0?'元年':''+t)).fontSize(8).fontColor('#A08A5C').width(44).textAlign(TextAlign.Center)
.position({x:this.tlX(t)-22,y:172})
},(t:number)=>t.toString())

ForEach(this.tlNodes,(n:TlItem,index:number)=>{
Column(){
Image(imgSrc(n.img)).alt($rawfile('assets/cat-'+n.img.split('cat-')[1])).width(36).height(36).borderRadius(18).objectFit(ImageFit.Cover)
.border({width:2,color:'#C9A959'})
Text(n.title).fontSize(9).fontColor('#2E2410').width(76).textAlign(TextAlign.Center).maxLines(1).margin({top:3})
Text(n.date).fontSize(7).fontColor('#A08A5C').width(76).textAlign(TextAlign.Center).maxLines(1)
}
.width(76).position({x:this.tlX(n.y)-38,y:this.tlLanes[index]===0?6:100})
.onClick(()=>{
openTitle(n.target);
})
},(n:TlItem)=>n.title)
}
.width(TL_W).height(188)
}
.scrollable(ScrollDirection.Horizontal).scrollBar(BarState.Off).width('100%')
.onScroll((xOffset:number,yOffset:number)=>{
this.tlProg=Math.min(1,Math.max(0,xOffset/(TL_W-358)));
})

Stack({alignContent:Alignment.Start}){
Column().width('100%').height(3).backgroundColor('#E7DCC2').borderRadius(2)
Column().width((this.tlProg*100)+'%').height(3).backgroundColor('#C9A959').borderRadius(2)
}
.width('92%').margin({top:8})


Row(){
Text('为你推荐').fontSize(17).fontWeight(700).fontColor('#3A2C14').layoutWeight(1)
}.width('92%').margin({top:22,bottom:10})
Column({space:12}){
ForEach(PERSONAL,(t:string)=>{
Column(){
Row(){
Image(imgSrc(entryByTitle(t)!==undefined?entryByTitle(t)!.img:'assets/hero.jpg')).alt($rawfile('assets/cat-'+(entryByTitle(t)!==undefined?entryByTitle(t)!.img:'assets/hero.jpg').split('cat-')[1])).width(96).height(76).borderRadius(12).objectFit(ImageFit.Cover)
Column(){
Text(t).fontSize(15).fontWeight(600).fontColor('#2E2410')
Text(entryByTitle(t)!==undefined?entryByTitle(t)!.summary:'').fontSize(12).fontColor('#6B5B39').margin({top:4}).maxLines(2)
Text(entryByTitle(t)!==undefined?entryByTitle(t)!.eraFull:'').fontSize(11).fontColor('#A08A5C').margin({top:4})
}.layoutWeight(1).alignItems(HorizontalAlign.Start).margin({left:12})
}
.width('100%')
.onClick(()=>{
openTitle(t);
})
if(realKeyOf(t)!==''){
Row(){
Text('进入 3D 展厅 ›').fontSize(12).fontColor('#8A6D2F').margin({left:10})
}
.width('100%').margin({top:9})
.onClick(()=>{
router.pushUrl({url:'pages/viewer',params:{relicKey:realKeyOf(t)}});
})
}
}
.width('100%').padding(12).borderRadius(14).backgroundColor('#FFFDF6')
.shadow({radius:5,color:'#14000000',offsetY:2})
})
}
.width('92%').margin({bottom:26})
}
.width('100%').alignItems(HorizontalAlign.Center)
}
.width('100%').height('100%')
.backgroundColor('#F7F1E3')
.scrollBar(BarState.Off)
}
}
