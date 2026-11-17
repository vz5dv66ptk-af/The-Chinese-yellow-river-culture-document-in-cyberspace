import{store}from'../models/store';
import router from'@ohos.router';
import abilityAccessCtrl from'@ohos.abilityAccessCtrl';
import common from'@ohos.app.ability.common';
import Want from'@ohos.app.ability.Want';

@Entry
@Component
export struct mine{
@State favNum:number=0;
@State noteNum:number=0;
@State folderNum:number=0;

@State micState:string='未允许';
@State locState:string='未允许';

aboutToAppear():void{
this.favNum=store.favs.length;
this.noteNum=store.notes.length;
this.folderNum=store.folderNames.length;
this.refreshPerm();
}

//读系统里的真实授权状态，用户在设置里改完回来点一下“刷新”就行
async refreshPerm(){
const at=abilityAccessCtrl.createAtManager();
const ctx=getContext(this) as common.UIAbilityContext;
const tok=ctx.applicationInfo.accessTokenId;
const m=await at.checkAccessToken(tok,'ohos.permission.MICROPHONE');
const l=await at.checkAccessToken(tok,'ohos.permission.LOCATION');
this.micState=(m===abilityAccessCtrl.GrantStatus.PERMISSION_GRANTED)?'已允许':'未允许';
this.locState=(l===abilityAccessCtrl.GrantStatus.PERMISSION_GRANTED)?'已允许':'未允许';
}

//权限只在系统设置里改，应用里不弹框、也不改状态
toSetting(){
const ctx=getContext(this) as common.UIAbilityContext;
const w:Want={
bundleName:'com.huawei.hmos.settings',
abilityName:'com.huawei.hmos.settings.MainAbility',
uri:'application_info_entry',
parameters:{pushParams:ctx.applicationInfo.name}
};
ctx.startAbility(w);
}

build(){
Scroll(){
Column(){
Row(){
Stack(){
Text('黄').fontSize(26).fontWeight(700).fontColor('#FFF6E6')
}
.width(60).height(60).borderRadius(30).backgroundColor('#8A6D2F')
Column(){
Text('黄河文化爱好者').fontSize(17).fontWeight(600).fontColor('#2E2410')
Text('沿黄收藏 · 慢慢攒').fontSize(12).fontColor('#A08A5C').margin({top:4})
}.alignItems(HorizontalAlign.Start).margin({left:14})
}
.width('92%').margin({top:26})

Row(){
Column(){
Text(this.favNum.toString()).fontSize(20).fontWeight(700).fontColor('#3A2C14')
Text('收藏').fontSize(11).fontColor('#A08A5C').margin({top:3})
}.layoutWeight(1)
Column(){
Text(this.folderNum.toString()).fontSize(20).fontWeight(700).fontColor('#3A2C14')
Text('收藏夹').fontSize(11).fontColor('#A08A5C').margin({top:3})
}.layoutWeight(1)
Column(){
Text(this.noteNum.toString()).fontSize(20).fontWeight(700).fontColor('#3A2C14')
Text('笔记').fontSize(11).fontColor('#A08A5C').margin({top:3})
}.layoutWeight(1)
}
.width('92%').padding({top:16,bottom:16}).borderRadius(14).backgroundColor('#FFFDF6')
.margin({top:18}).shadow({radius:4,color:'#12000000',offsetY:2})

Column(){
Row(){
Text('权限管理').fontSize(15).fontWeight(700).fontColor('#3A2C14').layoutWeight(1)
Text('刷新').fontSize(11).fontColor('#8A6D2F')
.onClick(()=>{this.refreshPerm();})
}.width('100%')
Text('权限只在系统设置里改，这里不改').fontSize(11).fontColor('#A08A5C').margin({top:4}).width('100%')
Row(){
Column(){
Text('麦克风').fontSize(14).fontColor('#3A2C14').width('100%')
Text('青鸾听你说话，语音提问要用').fontSize(11).fontColor('#A08A5C').margin({top:3}).width('100%')
}.layoutWeight(1).alignItems(HorizontalAlign.Start)
Text(this.micState).fontSize(12).fontColor('#8A7A58').margin({right:8})
Button('去设置').height(30).fontSize(12).backgroundColor('#E8D4AE').fontColor('#5A4A2A')
.onClick(()=>{this.toSetting();})
}.width('100%').margin({top:14})
Row(){
Column(){
Text('地理位置').fontSize(14).fontColor('#3A2C14').width('100%')
Text('按你在的地方推荐附近的遗址').fontSize(11).fontColor('#A08A5C').margin({top:3}).width('100%')
}.layoutWeight(1).alignItems(HorizontalAlign.Start)
Text(this.locState).fontSize(12).fontColor('#8A7A58').margin({right:8})
Button('去设置').height(30).fontSize(12).backgroundColor('#E8D4AE').fontColor('#5A4A2A')
.onClick(()=>{this.toSetting();})
}.width('100%').margin({top:14})
Row(){
Column(){
Text('听筒').fontSize(14).fontColor('#3A2C14').width('100%')
Text('语音讲解从听筒放，贴耳收听').fontSize(11).fontColor('#A08A5C').margin({top:3}).width('100%')
}.layoutWeight(1).alignItems(HorizontalAlign.Start)
Button('去设置').height(30).fontSize(12).backgroundColor('#E8D4AE').fontColor('#5A4A2A')
.onClick(()=>{this.toSetting();})
}.width('100%').margin({top:14})
}
.width('92%').padding(16).borderRadius(14).backgroundColor('#FFFDF6')
.margin({top:14}).shadow({radius:4,color:'#12000000',offsetY:2})
.alignItems(HorizontalAlign.Start)

Column(){
Text('关于黄河记忆').fontSize(15).fontWeight(700).fontColor('#3A2C14').width('100%')
Text('黄河记忆是一份沿黄流域的文物数字档案：从青海源头到山东入海口，收录遗址与文物 121 件（组），每件都有档案表和三段释读。四件文物有实物扫描的真实 3D 模型，可以在展厅里转着看。').fontSize(13).fontColor('#6B5B39').margin({top:8}).lineHeight(20)
Text('资料来源：《黄河记忆档案馆 · 资料卷》与《黄河文化文物图录》。页面里的数据为学习整理所用，尺寸、藏地以各博物馆公布为准。').fontSize(13).fontColor('#6B5B39').margin({top:8}).lineHeight(20)
}
.width('92%').padding(16).borderRadius(14).backgroundColor('#FFFDF6')
.margin({top:14}).shadow({radius:4,color:'#12000000',offsetY:2})
.alignItems(HorizontalAlign.Start)

Button('退出登录').width('92%').height(42).margin({top:22})
.backgroundColor('#D8CBA6').fontColor('#5A4A2A').fontSize(14)
.onClick(()=>{
store.clearLogin();
router.replaceUrl({url:'pages/login'});
})
Text('黄河记忆 · 原生版 1.0').fontSize(11).fontColor('#A08A5C').margin({top:16,bottom:26})
}
.width('100%').alignItems(HorizontalAlign.Center)
}
.width('100%').height('100%')
.backgroundColor('#F7F1E3')
.scrollBar(BarState.Off)
}
}
