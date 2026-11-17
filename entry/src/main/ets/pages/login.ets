import { http } from '@kit.NetworkKit';
import { hilog } from '@kit.PerformanceAnalysisKit';
import { JSON } from '@kit.ArkTS';
import router from'@ohos.router';
import promptAction from'@ohos.promptAction';
import common from'@ohos.app.ability.common';
import Want from'@ohos.app.ability.Want';
import{store}from'../models/store';

@Entry
@Component
export struct login{
@State message:string='欢迎光临';
@State username:string='';
@State password:string='';

aboutToAppear():void{
this.username=store.userName;
}

async goApp(name:string,bd:string){
const ctx=getContext(this) as common.UIAbilityContext;
const w:Want={bundleName:bd};
console.log('点了第三方登录:',name,bd);
try{
await ctx.startAbility(w);
console.log('拉起成功:',name);
}catch(e){
console.log('拉起失败:',name);
promptAction.showToast({message:'还没装'+name+'，装好后再点这里'});
}
}

login(){
let data:string=JSON.stringify({username:this.username,password:this.password});
let req=http.createHttp()
req.request("http://127.0.0.1:8788/login",{
method:http.RequestMethod.POST,
extraData:data
},(err,data)=>{
if(!err){
let obj:Record<string,Object>=JSON.parse(data.result as string) as Record<string,Object>;
hilog.info(0x0000,'test','Succeeded in loading the content.');
}
})
}

build(){
Column(){
Column(){
Column(){
Text('河图·文明之源').fontSize(30).fontColor('#ffef7f09').margin({right:30})
Text('黄河文化分布式数字档案').fontSize(10).fontColor('#fff6c304').margin({left:30})
}.width('100%').justifyContent(FlexAlign.SpaceBetween)

Column({space:0}){
Image($rawfile('yellowriver.png'))
.width(300).height(170)
.margin(15).borderRadius(20)
.onClick(()=>{
this.message='黄河';
})
Text(this.message).fontSize(40).fontColor('#fff0c090')
Text('登录以开启全部服务').fontSize(20).fontColor('#ff0e0e11')
}.width('100%')

Column({space:10}){
TextInput({text:this.username,placeholder:'手机号/邮箱/用户名'})
.height(45)
.padding(2)
.borderRadius(0)
.backgroundColor($r('app.color.white'))
.placeholderFont({size:12})
.placeholderColor('#99999999')
.border({width:{bottom:1},color:'#666666'})
.onChange((value:string)=>{
this.username=value;
})

TextInput({text:this.password,placeholder:'密码'})
.type(InputType.Password)
.height(45)
.padding(2)
.borderRadius(0)
.backgroundColor($r('app.color.white'))
.placeholderFont({size:12})
.placeholderColor('#99999999')
.border({width:{bottom:1},color:'#666666'})
.onChange((value:string)=>{
this.password=value;
})
}.width('100%').padding(20)


Row({space:10}){
Text('短信验证码登录').fontSize(10).fontColor('#ff06f1f1').fontWeight(500)
Text('忘记密码').fontSize(10).fontColor('#ff06f1f1').fontWeight(500)
}.width('100%').justifyContent(FlexAlign.SpaceEvenly)

Column({space:10}){
Button('登录',{stateEffect:true}).width('85%').height(40).margin({top:20})
  .onClick((event: ClickEvent) => {
    console.log(`username: ${this.username}, password: ${this.password}`);
    if (this.username === 'Aihara' && this.password === 'AKA911911') {
      console.log('--> 登录成功');
      store.setLogin(this.username);
      promptAction.showToast({ message: '登录成功' });
      router.replaceUrl({ url: 'pages/Main' });
    } else {
      if (this.username === '' || this.password === '') {
        promptAction.showToast({ message: '请填写用户名和密码' });
      } else {
        promptAction.showToast({ message: '用户名或密码错误' });
      }
    }
  })

Column({space:15}){
Text('用户注册').fontSize(10).fontColor('#ff06ddf8').fontWeight(400)
}
.onClick((event:ClickEvent)=>{
console.log('点用户注册了');
})
.width('100%')
}.width('100%').padding(20)

Column(){
Text('其他方式登录').fontSize(10).fontColor('#ff818383')
.fontWeight(200).margin({top:40})
}

Row({space:10}){
Image($rawfile('qq2.png')).width(30).height(30)
.onClick(()=>{this.goApp('QQ','com.tencent.qq');})
Image($rawfile('wechat-.png')).width(30).height(30)
.onClick(()=>{this.goApp('微信','com.tencent.wechat');})
Image($rawfile('dingding.png')).width(30).height(30)
.onClick(()=>{this.goApp('钉钉','com.alibaba.dingtalk');})
Image($rawfile('huawei.png')).width(40).height(30)
}.width('100%').padding(20).justifyContent(FlexAlign.Center)

Text('点图标用对应 App 登录').fontSize(10).fontColor('#ff818383').fontWeight(200)
}.width('100%').padding(40)
}
.width('100%').height('100%')
.backgroundColor('#FFF9F0')
}
}
