import{SiteItem,SITES,CITYNODES,CityNode,imgSrc}from'../models/data';
import{openSite}from'../models/store';
import router from'@ohos.router';

const RIVER:number[][]=[[168,206],[438,188],[714,166],[1005,116],[1180,140],[1246,250],[1246,330],[1300,330],[1352,288],[1492,276],[1602,260],[1722,260],[1840,238],[1938,206],[1996,196]];
const TRIB1:number[][]=[[520,298],[992,360],[1136,424],[1300,345],[1352,300]];
const TRIB2:number[][]=[[318,116],[438,188]];
interface Pt{x:number;y:number}

@Entry
@Component
export struct map{
@State sorted:SiteItem[]=[];
@State tick:number=0;
@State active:string='';
private timerID:number=-1;
private ready:boolean=false;
private mapScroller:Scroller=new Scroller();
private ctx:CanvasRenderingContext2D=new CanvasRenderingContext2D(new RenderingContextSettings(true));
private pathPts:Pt[]=[];

aboutToAppear():void{
let out:SiteItem[]=[...SITES];
out.sort((a:SiteItem,b:SiteItem)=>{
return a.x-b.x;
});
this.sorted=out;
this.buildPath();
this.timerID=setInterval(()=>{
this.tick++;
this.drawScene();
},50);
}

aboutToDisappear():void{
if(this.timerID>=0){
clearInterval(this.timerID);
this.timerID=-1;
}
}

buildPath():void{
let pts:Pt[]=[];
for(let i:number=0;i<RIVER.length;i++){
pts.push({x:RIVER[i][0]*0.75,y:RIVER[i][1]*0.75});
}
let out:Pt[]=[];
out.push(pts[0]);
for(let i:number=1;i<pts.length-1;i++){
let sx:number=out[out.length-1].x;
let sy:number=out[out.length-1].y;
let mx:number=(pts[i].x+pts[i+1].x)/2;
let my:number=(pts[i].y+pts[i+1].y)/2;
for(let j:number=1;j<=16;j++){
let t:number=j/16;
let u:number=1-t;
out.push({x:u*u*sx+2*u*t*pts[i].x+t*t*mx,y:u*u*sy+2*u*t*pts[i].y+t*t*my});
}
}
out.push(pts[pts.length-1]);
this.pathPts=out;
}
pointAt(frac:number):Pt{
if(this.pathPts.length===0){
return{x:0,y:0};
}
let f:number=frac*(this.pathPts.length-1);
let i:number=Math.floor(f);
let t:number=f-i;
let a:Pt=this.pathPts[i];
let b:Pt=this.pathPts[Math.min(i+1,this.pathPts.length-1)];
return{x:a.x+(b.x-a.x)*t,y:a.y+(b.y-a.y)*t};
}

drawScene():void{
if(!this.ready||this.pathPts.length===0){
return;
}
let c:CanvasRenderingContext2D=this.ctx;
c.clearRect(0,0,1500,375);
for(let i:number=0;i<4;i++){
let mx:number=i*430+120+Math.sin(this.tick*0.011+i*1.7)*36;
let my:number=64+i*82;
c.beginPath();
c.ellipse(mx,my,120,19,0,0,Math.PI*2);
c.fillStyle='rgba(255,251,235,0.10)';
c.fill();
}

c.beginPath();
c.setLineDash([5,6]);
for(let i:number=0;i<TRIB1.length;i++){
if(i===0){c.moveTo(TRIB1[i][0]*0.75,TRIB1[i][1]*0.75);}else{c.lineTo(TRIB1[i][0]*0.75,TRIB1[i][1]*0.75);}
}
for(let i:number=0;i<TRIB2.length;i++){
if(i===0){c.moveTo(TRIB2[i][0]*0.75,TRIB2[i][1]*0.75);}else{c.lineTo(TRIB2[i][0]*0.75,TRIB2[i][1]*0.75);}
}
c.strokeStyle='rgba(160,125,45,0.55)';
c.lineWidth=1.5;
c.stroke();
c.setLineDash([]);
for(let pass:number=0;pass<2;pass++){
c.beginPath();
for(let i:number=0;i<this.pathPts.length;i++){
if(i===0){c.moveTo(this.pathPts[i].x,this.pathPts[i].y);}else{c.lineTo(this.pathPts[i].x,this.pathPts[i].y);}
}
c.strokeStyle=pass===0?'rgba(201,169,89,0.30)':'#C9A959';
c.lineWidth=pass===0?9:3;
c.stroke();
}
for(let k:number=0;k<3;k++){
let p:Pt=this.pointAt((this.tick*0.006+k/3)%1);
c.beginPath();
c.arc(p.x,p.y,4,0,Math.PI*2);
c.shadowBlur=14;
c.shadowColor='#E8B93B';
c.fillStyle='#FFE9A8';
c.fill();
c.shadowBlur=0;
}
let bp:Pt=this.pointAt((this.tick*0.0016)%1);
c.save();
c.translate(bp.x,bp.y-4);
c.beginPath();
c.moveTo(-9,3);
c.lineTo(9,3);
c.lineTo(6,8);
c.lineTo(-6,8);
c.closePath();
c.fillStyle='#7A4A21';
c.fill();
c.beginPath();
c.moveTo(0,3);
c.lineTo(0,-10);
c.strokeStyle='#5A3A16';
c.lineWidth=1.5;
c.stroke();
c.beginPath();
c.moveTo(1,-10);
c.lineTo(1,-1);
c.lineTo(9,-1);
c.closePath();
c.fillStyle='#F5E7C3';
c.fill();
c.restore();
}
build(){
Column(){
Row(){
Text('‹').fontSize(26).width(40).height(40).textAlign(TextAlign.Center)
.onClick(()=>{
router.back();
})
Column(){
Text('黄河文化地图').fontSize(16).fontWeight(600).fontColor('#2E2410')
Text('沿着黄河 · 自西向东').fontSize(11).fontColor('#A08A5C')
}.layoutWeight(1).alignItems(HorizontalAlign.Start)
}
.width('100%').padding({left:6,right:16,top:10,bottom:8}).backgroundColor('#F7F1E3')
Scroll(this.mapScroller){
Stack(){
Image($rawfile('assets/scroll-map-wide.jpg')).width(1500).height(375).objectFit(ImageFit.Cover)
Canvas(this.ctx).width(1500).height(375).position({x:0,y:0})
.onReady(()=>{
this.ready=true;
this.drawScene();
})
ForEach(CITYNODES,(n:CityNode,index:number)=>{
Text(n.name).fontSize(9).fontColor('#7A5A14').backgroundColor('#EAD9A8E6')
.padding({left:4,right:4,top:1,bottom:1}).borderRadius(6)
.border({width:1,color:'#C9A959'})
.scale({x:1+0.07*Math.sin(this.tick*0.12+index*0.9),y:1+0.07*Math.sin(this.tick*0.12+index*0.9)})
.position({x:n.x*0.75-16,y:n.y*0.75-8})
})
ForEach(this.sorted,(s:SiteItem,index:number)=>{
Stack(){
Stack().width(19+(((this.tick%36)/36+index*0.17)%1)*18).height(19+(((this.tick%36)/36+index*0.17)%1)*18).borderRadius(999).backgroundColor('#C9A959').opacity(0.5*(1-((this.tick%36)/36+index*0.17)%1))
Text((index+1).toString()).fontSize(this.active===s.label?12:10).fontWeight(700).fontColor($r('app.color.white')).textAlign(TextAlign.Center)
.width(this.active===s.label?25:19).height(this.active===s.label?25:19).borderRadius(13)
.backgroundColor(this.active===s.label?'#B5522F':'#B8860B')
.border({width:1,color:'#FFF3D6'})
}
.width(40).height(40)
.position({x:s.x*0.75-20,y:s.y*0.75-20})
.onClick(()=>{
this.active=s.label;
openSite(s);
})
})
}
.width(1500).height(375)
}
.scrollable(ScrollDirection.Horizontal).scrollBar(BarState.Off).width('100%')

Text('点位列表 · 自西向东（点一条，长卷滚过去）').fontSize(15).fontWeight(700).fontColor('#3A2C14')
.width('92%').margin({top:14,bottom:6})
Scroll(){
Column(){
ForEach(this.sorted,(s:SiteItem,index:number)=>{
Row(){
Text((index+1).toString()).fontSize(12).fontWeight(700).fontColor($r('app.color.white')).textAlign(TextAlign.Center)
.width(22).height(22).borderRadius(11).backgroundColor(this.active===s.label?'#B5522F':'#B8860B')
Image(imgSrc(s.img)).alt($rawfile('assets/cat-'+s.img.split('cat-')[1])).width(52).height(52).borderRadius(10).objectFit(ImageFit.Cover).margin({left:10})
Column(){
Text(s.label).fontSize(15).fontWeight(600).fontColor('#2E2410')
Text(s.place+' · '+s.era).fontSize(11).fontColor('#A08A5C').margin({top:3})
}
.layoutWeight(1).alignItems(HorizontalAlign.Start).margin({left:10})
Text('›').fontSize(18).fontColor('#C9B98F')
}
.width('100%').padding({top:9,bottom:9})
.border({width:{bottom:1},color:'#EDE4CB'})
.onClick(()=>{
this.active=s.label;
this.mapScroller.scrollTo({xOffset:Math.max(0,s.x*0.75-180),yOffset:0,animation:{duration:650,curve:Curve.EaseInOut}});
})
},(s:SiteItem)=>s.label)
}
.width('92%')
}
.layoutWeight(1).scrollBar(BarState.Off).width('100%')
}
.width('100%').height('100%').alignItems(HorizontalAlign.Center)
.backgroundColor('#F7F1E3')
}
}
