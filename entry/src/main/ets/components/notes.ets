import{EntryItem,ENTRIES}from'../models/data';
import{NoteItem,store,todayStr,openTitle}from'../models/store';
import promptAction from'@ohos.promptAction';

@Component
export struct notes{
@State list:NoteItem[]=[];
@State editing:boolean=false;
@State editId:number=0;
@State nTitle:string='';
@State nText:string='';
@State nLink:string='';
@State linkOpts:SelectOption[]=[];
@State linkIndex:number=0;

aboutToAppear():void{
let opts:SelectOption[]=[{value:'不关联'}];
for(let i:number=0;i<ENTRIES.length;i++){
opts.push({value:ENTRIES[i].title});
}
this.linkOpts=opts;
this.refresh();
//从详情页点记笔记过来的，noteLink里放着要关联的文物，直接打开编辑器
if(store.noteLink!==''){
this.startNew(store.noteLink);
store.noteLink='';
}
}

refresh():void{
this.list=[...store.notes];
}

startNew(link:string):void{
this.editId=0;
this.nTitle='';
this.nText='';
this.nLink=link;
this.linkIndex=link===''?0:this.findLinkIndex(link);
this.editing=true;
}

findLinkIndex(title:string):number{
let idx:number=ENTRIES.findIndex((e:EntryItem)=>e.title===title);
return idx>=0?idx+1:0;
}

startEdit(n:NoteItem):void{
this.editId=n.id;
this.nTitle=n.title;
this.nText=n.text;
this.nLink=n.link;
this.linkIndex=this.findLinkIndex(n.link);
this.editing=true;
}

saveNote():void{
if(this.nTitle.trim()===''&&this.nText.trim()===''){
promptAction.showToast({message:'标题和内容都没写'});
return;
}
if(this.editId===0){
let nid:number=store.notes.reduce((max:number,n:NoteItem)=>n.id>max?n.id:max,0)+1;
store.notes.unshift({id:nid,title:this.nTitle.trim()===''?'无标题笔记':this.nTitle,link:this.nLink,text:this.nText,date:todayStr()});
console.log('新笔记存好了');
}else{
let target:NoteItem|undefined=store.notes.find((n:NoteItem)=>n.id===this.editId);
if(target!==undefined){
target.title=this.nTitle;
target.link=this.nLink;
target.text=this.nText;
}
console.log('笔记改好了');
}
this.editing=false;
store.save();
this.refresh();
}

deleteNote():void{
let idx:number=store.notes.findIndex((n:NoteItem)=>n.id===this.editId);
if(idx>=0){store.notes.splice(idx,1);}
store.save();
this.editing=false;
this.refresh();
promptAction.showToast({message:'笔记删了'});
}

build(){
Scroll(){
Column(){
Stack(){
Image($rawfile('assets/erlitou.jpg')).width('100%').height(120).objectFit(ImageFit.Cover)
Column(){
Text('我的笔记').fontSize(22).fontWeight(700).fontColor('#FFF6E6')
Text('共 '+this.list.length+' 条 · 看展的时候随手记').fontSize(12).fontColor('#F3E3BC').margin({top:5})
}.width('100%').alignItems(HorizontalAlign.Start).padding({left:20,top:40})
}.width('100%')

if(!this.editing){
Button('＋ 写笔记').width('92%').height(42).margin({top:16})
.backgroundColor('#8A6D2F').fontSize(15)
.onClick(()=>{
this.startNew('');
})
}

if(this.editing){
Column(){
Text(this.editId===0?'写笔记':'编辑笔记').fontSize(16).fontWeight(700).fontColor('#3A2C14').width('100%')
TextInput({text:this.nTitle,placeholder:'笔记标题'})
.width('100%').height(42).backgroundColor($r('app.color.white')).borderRadius(10).margin({top:12})
.placeholderFont({size:14})
.onChange((value:string)=>{
this.nTitle=value;
})
Row(){
Text('关联文物：').fontSize(13).fontColor('#5A4A2A')
Select(this.linkOpts)
.selected(this.linkIndex)
.value(this.nLink===''?'不关联':this.nLink)
.font({size:13})
.onSelect((index:number)=>{
this.linkIndex=index;
this.nLink=index===0?'':ENTRIES[index-1].title;
console.log('关联到:',this.nLink);
})
}.width('100%').margin({top:10})
TextArea({text:this.nText,placeholder:'写点什么...'})
.width('100%').height(150).backgroundColor($r('app.color.white')).borderRadius(10).margin({top:10})
.fontSize(14)
.onChange((value:string)=>{
this.nText=value;
})
Row({space:10}){
Button('保存').layoutWeight(1).height(40).backgroundColor('#8A6D2F').fontSize(14)
.onClick(()=>{
this.saveNote();
})
Button('取消').layoutWeight(1).height(40).backgroundColor('#D8CBA6').fontColor('#5A4A2A').fontSize(14)
.onClick(()=>{
this.editing=false;
})
if(this.editId>0){
Button('删除').layoutWeight(1).height(40).backgroundColor('#B04A2A').fontSize(14)
.onClick(()=>{
this.deleteNote();
})
}
}.width('100%').margin({top:14})
}
.width('92%').padding(16).borderRadius(14).backgroundColor('#FFFDF6').margin({top:16})
.shadow({radius:5,color:'#14000000',offsetY:2})
}

Column({space:12}){
if(this.list.length===0&&!this.editing){
Text('还没有笔记，点上面写第一条').fontSize(13).fontColor('#8A7A58').padding({top:20})
}
ForEach(this.list,(n:NoteItem)=>{
Column(){
Row(){
Text(n.title).fontSize(15).fontWeight(600).fontColor('#2E2410').layoutWeight(1)
Text(n.date).fontSize(11).fontColor('#A08A5C')
}.width('100%')
Text(n.text).fontSize(13).fontColor('#6B5B39').margin({top:6}).maxLines(3).width('100%')
if(n.link!==''){
Text('关联文物：'+n.link+' ›').fontSize(12).fontColor('#8A6D2F').margin({top:8})
.onClick(()=>{
openTitle(n.link);
})
}
}
.width('100%').padding(14).borderRadius(14).backgroundColor('#FFFDF6')
.shadow({radius:4,color:'#12000000',offsetY:2})
.alignItems(HorizontalAlign.Start)
.onClick(()=>{
this.startEdit(n);
})
},(n:NoteItem)=>n.id.toString())
}
.width('92%').margin({top:16,bottom:26})
}
.width('100%').alignItems(HorizontalAlign.Center)
}
.width('100%').height('100%')
.backgroundColor('#F7F1E3')
.scrollBar(BarState.Off)
}
}
