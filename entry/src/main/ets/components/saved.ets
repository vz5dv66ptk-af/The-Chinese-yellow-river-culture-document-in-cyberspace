import{FavInfo,store,isFav,removeFav,moveFav,favCount,favInfo,openTitle}from'../models/store';
import{imgSrc}from'../models/data';
import promptAction from'@ohos.promptAction';

@Component
export struct saved{
@State favList:string[]=[];
@State folderSel:string='';
@State kindSel:string='全部';
@State query:string='';
@State menuFor:string='';
@State showNew:boolean=false;
@State newName:string='';

aboutToAppear():void{
this.refresh();
}

refresh():void{
this.favList=[...store.favs];
}

kindOf(title:string):string{
let info:FavInfo=favInfo(title);
return info.kind;
}

visibleList():string[]{
return this.favList.filter((t:string)=>{
if(this.folderSel!==''&&store.folderOf[t]!==this.folderSel){return false;}
if(this.kindSel!=='全部'&&this.kindOf(t)!==this.kindSel){return false;}
if(this.query!==''&&t.indexOf(this.query)<0){return false;}
return true;
});
}

build(){
Scroll(){
Column(){
Stack(){
Image($rawfile('assets/longmen.jpg')).width('100%').height(120).objectFit(ImageFit.Cover)
Column(){
Text('我的收藏').fontSize(22).fontWeight(700).fontColor('#FFF6E6')
Text(this.favList.length+' 件藏品 · '+store.folderNames.length+' 个收藏夹').fontSize(12).fontColor('#F3E3BC').margin({top:5})
}.width('100%').alignItems(HorizontalAlign.Start).padding({left:20,top:40})
}.width('100%')

Row(){
Text('我的收藏夹').fontSize(16).fontWeight(700).fontColor('#3A2C14').layoutWeight(1)
Text('左右滑动查看全部').fontSize(11).fontColor('#A08A5C')
}.width('92%').margin({top:16,bottom:10})
Scroll(){
Row({space:12}){
ForEach(store.folderNames,(f:string)=>{
Column(){
Image($rawfile(store.folderImgs[f]!==undefined?store.folderImgs[f]:'assets/erlitou.jpg'))
.width(150).height(92).borderRadius(12).objectFit(ImageFit.Cover)
Text(f).fontSize(14).fontWeight(600).fontColor('#2E2410').margin({top:6}).width(150)
Text(favCount(f)+' 件藏品').fontSize(11).fontColor('#A08A5C').margin({top:2}).width(150)
}
.padding(6).borderRadius(14)
.backgroundColor(this.folderSel===f?'#EFE3BC':'#FFFDF6')
.border({width:this.folderSel===f?1:0,color:'#8A6D2F'})
.onClick(()=>{
this.folderSel=this.folderSel===f?'':f;
this.menuFor='';
})
})
Column(){
Text('＋').fontSize(26).fontColor('#8A6D2F')
Text('新建收藏夹').fontSize(12).fontColor('#8A6D2F').margin({top:4})
}
.width(110).height(140).justifyContent(FlexAlign.Center)
.borderRadius(14).backgroundColor('#FFF6DC')
.onClick(()=>{
this.showNew=true;
})
}
.padding({left:16,right:16})
}
.scrollable(ScrollDirection.Horizontal).scrollBar(BarState.Off).width('100%')
if(this.showNew){
Row(){
TextInput({text:this.newName,placeholder:'新收藏夹的名字'})
.layoutWeight(1).height(38).backgroundColor($r('app.color.white')).borderRadius(10)
.placeholderFont({size:13})
.onChange((value:string)=>{
this.newName=value;
})
Button('建好').height(38).margin({left:10}).backgroundColor('#8A6D2F').fontSize(13)
.onClick(()=>{
let name:string=this.newName.trim();
if(name===''){
promptAction.showToast({message:'先写个名字'});
return;
}
if(store.folderNames.includes(name)){
promptAction.showToast({message:'已经有这个夹子了'});
return;
}
store.folderNames.push(name);
store.folderImgs[name]='assets/erlitou.jpg';
store.save();
this.newName='';
this.showNew=false;
this.refresh();
})
Button('算了').height(38).margin({left:8}).backgroundColor('#D8CBA6').fontSize(13).fontColor('#5A4A2A')
.onClick(()=>{
this.showNew=false;
})
}
.width('92%').margin({top:10})
}
if(this.folderSel!==''){
Row(){
Text('正在看「'+this.folderSel+'」').fontSize(12).fontColor('#8A6D2F').layoutWeight(1)
Text('查看全部').fontSize(12).fontColor('#8A6D2F')
.onClick(()=>{
this.folderSel='';
})
}
.width('92%').margin({top:10}).padding(10).borderRadius(10).backgroundColor('#F6ECD2')
}

Row({space:8}){
ForEach(['全部','遗址','文物','图集'],(k:string)=>{
Text(k).fontSize(13)
.fontColor(this.kindSel===k?$r('app.color.white'):'#5A4A2A')
.backgroundColor(this.kindSel===k?'#8A6D2F':'#EFE7CF')
.padding({left:18,right:18,top:7,bottom:7}).borderRadius(16)
.onClick(()=>{
this.kindSel=k;
})
})
}.width('92%').margin({top:14})

Row(){
TextInput({text:this.query,placeholder:'搜索藏品名称'})
.layoutWeight(1).height(40).backgroundColor($r('app.color.white')).borderRadius(12)
.placeholderFont({size:13}).placeholderColor('#99999999')
.onChange((value:string)=>{
this.query=value;
})
Text('最近收藏').fontSize(13).fontColor('#5A4A2A')
.padding({left:14,right:14,top:10,bottom:10}).backgroundColor($r('app.color.white')).borderRadius(12).margin({left:10})
}.width('92%').margin({top:12})

Column(){
if(this.visibleList().length===0){
Text('暂无符合条件的收藏').fontSize(14).fontColor('#8A7A58').padding({top:26})
Text('试试切换筛选或搜索其他关键词').fontSize(12).fontColor('#A08A5C').padding({top:6,bottom:26})
}
ForEach(this.visibleList(),(t:string)=>{
Column(){
Row(){
Row(){
Image(imgSrc(favInfo(t).img)).alt($rawfile('assets/cat-'+favInfo(t).img.split('cat-')[1])).width(76).height(76).borderRadius(12).objectFit(ImageFit.Cover)
Column(){
Text(t).fontSize(16).fontWeight(600).fontColor('#2E2410')
Text(favInfo(t).place).fontSize(12).fontColor('#8A7A58').margin({top:4})
Row({space:6}){
Text(favInfo(t).era).fontSize(10).fontColor('#8A6D2F').backgroundColor('#F1E8D2')
.padding({left:7,right:7,top:2,bottom:2}).borderRadius(6)
Text(store.folderOf[t]!==undefined?store.folderOf[t]:'').fontSize(10).fontColor('#8A6D2F').backgroundColor('#F1E8D2')
.padding({left:7,right:7,top:2,bottom:2}).borderRadius(6)
}.margin({top:5})
Text('收藏于 '+favInfo(t).date).fontSize(11).fontColor('#A08A5C').margin({top:5})
}.layoutWeight(1).alignItems(HorizontalAlign.Start).margin({left:12})
}
.layoutWeight(1)
.onClick(()=>{
openTitle(t);
})
Text('···').fontSize(18).fontColor('#8A7A58').padding(8)
.onClick(()=>{
this.menuFor=this.menuFor===t?'':t;
})
}
.width('100%')
if(this.menuFor===t){
Row(){
Text('查看详情').fontSize(12).fontColor('#8A6D2F')
.padding({left:10,right:10,top:6,bottom:6}).backgroundColor('#F1E8D2').borderRadius(8)
.onClick(()=>{
openTitle(t);
})
Text('取消收藏').fontSize(12).fontColor('#B04A2A')
.padding({left:10,right:10,top:6,bottom:6}).backgroundColor('#F6E3D8').borderRadius(8).margin({left:8})
.onClick(()=>{
removeFav(t);
this.menuFor='';
this.refresh();
promptAction.showToast({message:'已取消收藏'});
})
}.width('100%').margin({top:10})
Row(){
Text('移入：').fontSize(12).fontColor('#8A7A58')
ForEach(store.folderNames,(f:string)=>{
Text(f).fontSize(12)
.fontColor(store.folderOf[t]===f?$r('app.color.white'):'#5A4A2A')
.backgroundColor(store.folderOf[t]===f?'#8A6D2F':'#F1E8D2')
.padding({left:9,right:9,top:5,bottom:5}).borderRadius(8).margin({left:6})
.onClick(()=>{
moveFav(t,f);
this.menuFor='';
this.refresh();
})
})
}.width('100%').margin({top:8})
}
}
.width('100%').padding({top:12,bottom:12})
.border({width:{bottom:1},color:'#EDE4CB'})
},(t:string)=>t)
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
