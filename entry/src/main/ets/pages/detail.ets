import{EntryItem,realKeyOf,imgSrc}from'../models/data';
import{store,isFavEntry,toggleFavEntry,resolveEntry}from'../models/store';
import router from'@ohos.router';
import promptAction from'@ohos.promptAction';

@Entry
@Component
export struct detail{
@State e:EntryItem|undefined=undefined;
@State faved:boolean=false;

aboutToAppear():void{
const params=router.getParams() as Record<string,string>|undefined;
let title:string=params!==undefined?params['title']:'';
if(store.detail!==undefined&&store.detail.title===title){
this.e=store.detail;
}else{
this.e=resolveEntry(title);
}
if(this.e!==undefined){
this.faved=isFavEntry(this.e);
}
console.log('打开详情:',title);
}
@Builder
factRow(name:string,value:string){
Row(){
Text(name).fontSize(13).fontColor('#A08A5C').width(76)
Text(value===''?'—':value).fontSize(13).fontColor('#2E2410').layoutWeight(1)
}
.width('100%').padding({top:9,bottom:9})
.border({width:{bottom:1},color:'#EFE6CC'})
}
@Builder
section(name:string,text:string){
if(text!==''){
Column(){
Text(name).fontSize(16).fontWeight(700).fontColor('#3A2C14').width('100%')
Text(text).fontSize(14).fontColor('#4A3B20').margin({top:8}).lineHeight(22)
}
.width('100%').margin({top:20}).alignItems(HorizontalAlign.Start)
}
}

build(){
Column(){
Row(){
Text('‹').fontSize(26).width(40).height(40).textAlign(TextAlign.Center)
.onClick(()=>{
router.back();
})
Text('文化档案').fontSize(16).fontWeight(600).fontColor('#2E2410').layoutWeight(1)
}
.width('100%').padding({left:6,right:16,top:10,bottom:8}).backgroundColor('#F7F1E3')
if(this.e===undefined){
Text('没找到这条').fontSize(15).fontColor('#8A7A58').margin({top:60})
}else{
Scroll(){
Column(){
Image(imgSrc(this.e.img)).alt($rawfile('assets/cat-'+this.e.img.split('cat-')[1])).width('100%').height(260).objectFit(ImageFit.Cover)
Column(){
Text(this.e.title).fontSize(22).fontWeight(700).fontColor('#2E2410').width('100%')
Text(this.e.summary).fontSize(13).fontColor('#6B5B39').margin({top:8}).lineHeight(19).width('100%')
Divider().margin({top:14,bottom:6}).color('#C9A959')
this.factRow('年代',this.e.eraFull)
this.factRow('出土地点',this.e.loc)
this.factRow('形制尺寸',this.e.spec)
this.factRow('材质',this.e.material)
this.factRow('现藏',this.e.museum)
if(this.e.form!==''){this.section('器形与做法',this.e.form);}
if(this.e.story!==''){this.section('发现经过',this.e.story);}
if(this.e.meaning!==''){this.section('考古意义',this.e.meaning);}
if(this.e.form===''&&this.e.story===''&&this.e.meaning===''){this.section('档案详解',this.e.detail);}
if(this.e.related!==''){
Text('相关条目：'+this.e.related).fontSize(12).fontColor('#A08A5C').margin({top:20}).width('100%')
}
Row({space:12}){
Button(this.faved?'★ 已收藏':'☆ 收藏').layoutWeight(1).height(42).fontSize(14)
.backgroundColor(this.faved?'#8A6D2F':'#D8CBA6').fontColor(this.faved?$r('app.color.white'):'#5A4A2A')
.onClick(()=>{
if(this.e!==undefined){
this.faved=toggleFavEntry(this.e);
promptAction.showToast({message:this.faved?'收藏好了':'取消收藏了'});
}
})
Button('记笔记').layoutWeight(1).height(42).fontSize(14)
.backgroundColor('#D8CBA6').fontColor('#5A4A2A')
.onClick(()=>{
if(this.e!==undefined){
store.noteLink=this.e.title;
router.replaceUrl({url:'pages/Main',params:{tab:'4'}});
}
})
}.width('100%').margin({top:22})
//只有四件真实模型的才有这个按钮
if(realKeyOf(this.e.title)!==''){
Button('进入 3D 展厅').width('100%').height(44).fontSize(15)
.backgroundColor('#3A2C14').margin({top:12})
.onClick(()=>{
router.pushUrl({url:'pages/viewer',params:{relicKey:realKeyOf(this.e!.title)}});
})
}
if(this.e.title==='北宋东京城遗址'){
Button('进入东京城 · 全息 VR 漫游').width('100%').height(44).fontSize(15)
.backgroundColor('#14505C').margin({top:12})
.onClick(()=>{
router.pushUrl({url:'pages/viewer',params:{relicKey:'dongjing'}});
})
}
}
.width('100%').padding({left:18,right:18,top:16,bottom:30})
.alignItems(HorizontalAlign.Start)
}
.width('100%').alignItems(HorizontalAlign.Center)
}
.layoutWeight(1).scrollBar(BarState.Off)
}
}
.width('100%').height('100%')
.backgroundColor('#F7F1E3')
}
}
