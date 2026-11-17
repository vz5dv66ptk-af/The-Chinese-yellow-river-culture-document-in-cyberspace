import{EntryItem,ENTRIES,ERAS,TYPES,TOPICS,TopicItem,topicMatch,imgSrc}from'../models/data';
import{openEntry,openTitle}from'../models/store';

@Component
export struct knowledge{
@State eraSel:string='';
@State typeSel:string='';
@State topicSel:string='';
@State query:string='';

countType(t:string):number{
return ENTRIES.filter((e:EntryItem)=>e.type===t).length;
}

countTopic(name:string):number{
return ENTRIES.filter((e:EntryItem)=>topicMatch(e,name)).length;
}
list():EntryItem[]{
return ENTRIES.filter((e:EntryItem)=>{
if(this.eraSel!==''&&e.era!==this.eraSel){return false;}
if(this.typeSel!==''&&e.type!==this.typeSel){return false;}
if(this.topicSel!==''&&!topicMatch(e,this.topicSel)){return false;}
if(this.query!==''&&(e.title+e.summary+e.loc).indexOf(this.query)<0){return false;}
return true;
});
}

build(){
Scroll(){
Column(){
Stack(){
Image($rawfile('assets/scroll-map.jpg')).width('100%').height(120).objectFit(ImageFit.Cover)
Column().width('100%').height(120)
.linearGradient({direction:GradientDirection.Right,colors:[['#A617120B',0.0],['#3317120B',1.0]]})
Column(){
Text('知识库').fontSize(22).fontWeight(700).fontColor('#FFF6E6')
Text('沿黄文物档案 · 文物库共 121 件').fontSize(12).fontColor('#F3E3BC').margin({top:5})
}.width('100%').alignItems(HorizontalAlign.Start).padding({left:20,top:40})
}.width('100%')

Column(){
Row(){
Text('知识图谱').fontSize(16).fontWeight(700).fontColor('#3A2C14').layoutWeight(1)
Text('简化版').fontSize(11).fontColor('#A08A5C')
}.width('100%').margin({bottom:8})
Stack(){
Text('二里头\n遗址').fontSize(12).fontWeight(700).fontColor($r('app.color.white')).textAlign(TextAlign.Center)
.width(76).height(76).borderRadius(38).backgroundColor('#8A6D2F')
.position({x:142,y:76})
.onClick(()=>{
openTitle('二里头遗址');
})
Text('绿松石\n龙形器').fontSize(10).fontColor('#5A4A2A').textAlign(TextAlign.Center)
.width(58).height(58).borderRadius(29).backgroundColor('#EFE3BC')
.position({x:36,y:20})
.onClick(()=>{
openTitle('绿松石龙形器');
})
Text('妇好鸮尊').fontSize(10).fontColor('#5A4A2A').textAlign(TextAlign.Center)
.width(58).height(58).borderRadius(29).backgroundColor('#EFE3BC')
.position({x:262,y:16})
.onClick(()=>{
openTitle('妇好鸮尊');
})
Text('殷墟甲骨').fontSize(10).fontColor('#5A4A2A').textAlign(TextAlign.Center)
.width(58).height(58).borderRadius(29).backgroundColor('#EFE3BC')
.position({x:20,y:130})
.onClick(()=>{
openTitle('殷墟甲骨');
})
Text('何尊').fontSize(10).fontColor('#5A4A2A').textAlign(TextAlign.Center)
.width(58).height(58).borderRadius(29).backgroundColor('#EFE3BC')
.position({x:282,y:128})
.onClick(()=>{
openTitle('何尊');
})
Text('后母戊\n青铜方鼎').fontSize(10).fontColor('#5A4A2A').textAlign(TextAlign.Center)
.width(58).height(58).borderRadius(29).backgroundColor('#EFE3BC')
.position({x:150,y:168})
.onClick(()=>{
openTitle('后母戊青铜方鼎');
})
}
.width('100%').height(240).backgroundColor('#FBF6E9').borderRadius(14)
Text('二里头文化关系图 · 点击节点，查看关联说明').fontSize(11).fontColor('#A08A5C').margin({top:8})
}
.width('92%').margin({top:16}).alignItems(HorizontalAlign.Start)

Row(){
Text('专题探索').fontSize(16).fontWeight(700).fontColor('#3A2C14').layoutWeight(1)
Text('点击专题，筛选相关文物').fontSize(11).fontColor('#A08A5C')
}.width('92%').margin({top:18,bottom:10})
Flex({direction:FlexDirection.Row,wrap:FlexWrap.Wrap}){
ForEach(TOPICS,(tp:TopicItem)=>{
Column(){
Text(tp.name).fontSize(14).fontWeight(600)
.fontColor(this.topicSel===tp.name?$r('app.color.white'):'#3A2C14')
Text(this.countTopic(tp.name)+' 件').fontSize(11)
.fontColor(this.topicSel===tp.name?'#F3E3BC':'#A08A5C').margin({top:4})
}
.width('30%').padding({top:14,bottom:14}).borderRadius(12).margin({right:8,bottom:8})
.backgroundColor(this.topicSel===tp.name?'#8A6D2F':'#FFFDF6')
.alignItems(HorizontalAlign.Center)
.onClick(()=>{
this.topicSel=this.topicSel===tp.name?'':tp.name;
})
})
}.width('92%')

Row(){
Text('文物库').fontSize(16).fontWeight(700).fontColor('#3A2C14').layoutWeight(1)
Text('共 '+this.list().length+' 件').fontSize(11).fontColor('#A08A5C')
}.width('92%').margin({top:14,bottom:10})
Scroll(){
Row({space:8}){
Text('全部').fontSize(12)
.fontColor(this.eraSel===''?$r('app.color.white'):'#5A4A2A')
.backgroundColor(this.eraSel===''?'#8A6D2F':'#F1E8D2')
.padding({left:12,right:12,top:6,bottom:6}).borderRadius(13)
.onClick(()=>{
this.eraSel='';
})
ForEach(ERAS,(t:string)=>{
Text(t).fontSize(12)
.fontColor(this.eraSel===t?$r('app.color.white'):'#5A4A2A')
.backgroundColor(this.eraSel===t?'#8A6D2F':'#F1E8D2')
.padding({left:12,right:12,top:6,bottom:6}).borderRadius(13)
.onClick(()=>{
this.eraSel=this.eraSel===t?'':t;
})
})
}
.padding({left:16,right:16})
}
.scrollable(ScrollDirection.Horizontal).scrollBar(BarState.Off).width('100%')
Flex({direction:FlexDirection.Row,wrap:FlexWrap.Wrap}){
ForEach(TYPES,(t:string)=>{
Text(t+' '+this.countType(t)).fontSize(12)
.fontColor(this.typeSel===t?$r('app.color.white'):'#5A4A2A')
.backgroundColor(this.typeSel===t?'#8A6D2F':'#F1E8D2')
.padding({left:10,right:10,top:5,bottom:5}).borderRadius(12).margin({right:8,bottom:8})
.onClick(()=>{
this.typeSel=this.typeSel===t?'':t;
})
})
}.width('92%').margin({top:10})
TextInput({text:this.query,placeholder:'在文物库里搜...'})
.width('92%').height(40).backgroundColor($r('app.color.white')).borderRadius(12)
.placeholderFont({size:13}).placeholderColor('#99999999')
.onChange((value:string)=>{
this.query=value;
})

Column(){
if(this.list().length===0){
Text('没有符合条件的文物').fontSize(14).fontColor('#8A7A58').padding({top:26,bottom:26})
}
ForEach(this.list(),(e:EntryItem,index:number)=>{
Row(){
Text((index+1).toString()).fontSize(13).fontColor('#B08968').width(28)
Image(imgSrc(e.img)).alt($rawfile('assets/cat-'+e.img.split('cat-')[1])).width(60).height(60).borderRadius(10).objectFit(ImageFit.Cover)
Column(){
Row(){
Text(e.title).fontSize(15).fontWeight(600).fontColor('#2E2410').layoutWeight(1)
Text(e.type).fontSize(10).fontColor('#8A6D2F').backgroundColor('#F1E8D2')
.padding({left:7,right:7,top:2,bottom:2}).borderRadius(6)
}
Text(e.eraFull+' · '+e.city).fontSize(11).fontColor('#A08A5C').margin({top:3})
Text(e.summary).fontSize(12).fontColor('#6B5B39').margin({top:3}).maxLines(2)
}
.layoutWeight(1).alignItems(HorizontalAlign.Start).margin({left:12})
}
.width('100%').padding({top:9,bottom:9})
.border({width:{bottom:1},color:'#EDE4CB'})
.onClick(()=>{
openEntry(e);
})
},(e:EntryItem)=>e.title)
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
