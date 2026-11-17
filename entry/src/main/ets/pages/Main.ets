import router from'@ohos.router';
import{home}from '../components/main';
import{saved}from'../components/saved';
import{knowledge}from'../components/knowledge';
import{assistant}from'../components/assistant';
import{notes}from'../components/notes';
import{mine}from'../components/mine';

@Entry
@Component
export struct Main{
@State currentTab:number=0;

aboutToAppear():void{
const params=router.getParams() as Record<string,string>|undefined;
if(params!==undefined&&params['tab']!==undefined){
this.currentTab=Number(params['tab']);
}
}

build(){
Column(){
Tabs({barPosition:BarPosition.End,index:this.currentTab}){
TabContent(){
home()
}.tabBar('首页')
TabContent(){
saved()
}.tabBar('收藏')
TabContent(){
knowledge()
}.tabBar('知识库')
TabContent(){
assistant()
}.tabBar('助手')
TabContent(){
notes()
}.tabBar('笔记')
TabContent(){
mine()
}.tabBar('我的')
}
.barMode(BarMode.Fixed)
.onChange((index:number)=>{
this.currentTab=index;
console.log('切到第',index,'个tab');
})
.layoutWeight(1)
}
.width('100%').height('100%')
.backgroundColor('#F7F1E3')
}
}
