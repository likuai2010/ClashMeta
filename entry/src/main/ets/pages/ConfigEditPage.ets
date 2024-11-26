import { Profile, ProfileType } from '../entryability/ProfileRepo'
import { ActionInput, ActionLabel } from './compoments/common'
import { Icon } from './compoments/icons'
import { picker } from '@kit.CoreFileKit'

import profileViewModel, { FetchStatus } from '../entryability/ProfileViewModel'
import { JSON } from '@kit.ArkTS'
import { promptAction } from '@kit.ArkUI'
import { emitter } from '@kit.BasicServicesKit'
import { EventIds } from '../rpc/EventConstants'

@Component
export struct ConfigEditPage {
  @Consume('router') routerInfos: NavPathStack
  @State pending: Profile = new Profile()
  @Builder
  MoreMenu(){
    Row(){
      Icon({
        icon:$r("app.media.ic_baseline_save")
      }).onClick(async ()=>{
        this.save()
      })
    }
  }
  dialogController?: CustomDialogController =  new CustomDialogController({
    builder: Loading({ title: "添加配置", text: "下载配置中"}),
    autoCancel: false,
    alignment: DialogAlignment.Center,
    customStyle: true
  })
  async save(){
    try {
      this.dialogController?.open()
      const result = await profileViewModel.addProfile(this.pending, (status)=>{
        emitter.emit({eventId:EventIds.FetchStatusChange},{data:status})
      })
      this.dialogController?.close()
      if(result)
        this.routerInfos.pop(true)
    } catch (e) {
      this.dialogController?.close()
      promptAction.showToast({message: "保存失败:" + e.message})
    }

  }
  async  aboutToAppear(): Promise<void> {
    await profileViewModel.init(getContext(this))
    let params = this.routerInfos.getParamByName("config-edit") as string[]
    this.pending = await profileViewModel.getProfile(params[0])
  }
  build() {
    NavDestination() {
      Column() {
        Row(){
          Icon({icon:$r("app.media.ic_outline_info"), iconSize:25})
          Text("仅接受 CLash 配置文件(包含代理/规则)")
        }
        ActionInput({title:"名称", icon: "ic_outline_label", value: this.pending.name, defaultValue:"新配置", onChange:(v)=>{
            console.debug("testTag", v)
            this.pending.name = v
        }})
        ActionInput({title:"URL", icon: "ic_outline_inbox",unit:"https(s)", value: this.pending.source, defaultValue: "仅接受 http(s) 类型", onChange:(v)=>{
            console.debug("testTag", v)
            this.pending.source = v
            this.pending.type = ProfileType.Url
        }})
        ActionInput({title:"自动更新",icon: "ic_outline_update", unit:"分钟", value: this.pending.interval == 0 ? "" : `${this.pending.interval}(分钟)`, defaultValue: "已禁用" ,onChange:(v)=>{
          console.debug("testTag", v)
          try {
            let interval =  parseInt(v)
            if(Number.isNaN(interval)){
              this.pending.interval = 0
            }else{
              this.pending.interval = parseInt(v)
            }
          } catch (e) {
            this.pending.interval = 0
          }
        } })
        ActionLabel({title: "浏览文件", icon: "ic_outline_folder", change: ()=>{
          let filePicker = new picker.DocumentViewPicker(getContext(this))
          let options = new picker.DocumentSelectOptions()
          filePicker.select(options).then((documentSelectResult)=>{
            this.pending.source = documentSelectResult[0];
            this.pending.type = ProfileType.File
          })
        }})
      }.width('100%').height('100%')
    }.title("添加配置").menus(this.MoreMenu())
  }
}


@Component
export  struct ConfigsPage {
  @Consume('router') routerInfos: NavPathStack
  @State configList: Profile[] = []
  @State activeId: string = ""
  @Builder
  MoreMenu(){
    Row(){
      Icon({
        icon:$r("app.media.ic_baseline_replay"),
      }).onClick(()=>{

      })
      Icon({
        icon:$r("app.media.ic_baseline_add")
      }).onClick(()=>{
        this.routerInfos.pushPath({name:"config-edit"})
      })
    }
  }
  async aboutToAppear(): Promise<void> {
    await profileViewModel.init(getContext(this))
    this.routerInfos.setInterception({
      willShow: async (from: NavDestinationContext | "navBar", to: NavDestinationContext | "navBar",
        operation: NavigationOperation, animated: boolean) => {
        this.initPage()
      }
    })
    this.initPage()
  }
  async initPage(){
    this.configList = await profileViewModel.getProfileList()
    console.debug("testPage", JSON.stringify(this.configList))
    this.activeId = (await profileViewModel.getActive())?.uuid ?? ""
  }
  async deleteProfile(uuid: string){
    await profileViewModel.delete(uuid)
    this.initPage()
  }
  build() {
    NavDestination() {
      Column() {
        ForEach(this.configList, (config: Profile)=>{
          ConfigItem({profile:config, active: this.activeId == config.uuid, onDelete: ()=>{
            this.deleteProfile(config.uuid)
          }, onCheck: async ()=>{
            this.activeId = config.uuid
            profileViewModel.activeProfile(config)
          }})
        },(item: Profile)=> JSON.stringify(item))

      }.width('100%').height('100%')
    }.title("配置").menus(this.MoreMenu())
  }
}

@CustomDialog
export struct Loading {
  title?: string | Resource
  text: string | Resource = ""
  @State fetchStatus: FetchStatus = {} as FetchStatus
  controller: CustomDialogController
  aboutToAppear(): void {
    emitter.on({
      eventId: EventIds.FetchStatusChange,
    }, (eventData)=>{
      if (eventData.data)
        this.fetchStatus = eventData.data as FetchStatus
    })
  }
  build() {
    Column(){
      Text(this.title).fontSize(18)
      Row(){
        LoadingProgress().height(100).width(80)
        Column(){
          Text(this.text).maxLines(2).textOverflow({overflow: TextOverflow.Ellipsis})
          if (this.fetchStatus?.action){
            Text(`(${this.fetchStatus.progress}/${this.fetchStatus.max}):${this.fetchStatus.args[0]}`)
          }
        }.layoutWeight(1)
      }.height(100)

    }.padding(20)
    .alignItems(HorizontalAlign.Start).backgroundColor(Color.White).borderRadius(10)
    .width("333vp")
    .height(140)
  }
}

@Component
struct ConfigItem {
  @Consume('router') routerInfos: NavPathStack
  @Builder
  ConfigOption(){
    Column(){
      Blank().height(30)
      ActionLabel({ title:"查看配置", icon:"ic_baseline_edit", change: async ()=>{
        this.showSheet = false
        const configPath = await profileViewModel.getConfigPath(this.profile) + "/config.yaml"
        this.routerInfos.pushPath({name:"config-viewer", param: configPath})
      }})
      ActionLabel({ title:"编辑", icon:"ic_baseline_edit", change:()=>{
        this.showSheet = false
        this.routerInfos.pushPath({name:"config-edit", param:this.profile.uuid})
      }})
      ActionLabel({ title:"删除" , icon:"ic_outline_delete", color: Color.Red, change:()=>{
         if(this.onDelete)
           this.onDelete()
          this.showSheet = false
      }})
    }
  }
  @ObjectLink profile: Profile;
  @Prop active: boolean
  onDelete?: ()=>void
  onCheck?: ()=>void
  @State showSheet: boolean = false
  build() {
    Row(){
      Radio({
        value: "",
        group: ''
      }).checked(this.active).onClick(()=>{
        if(this.onCheck){
          this.onCheck()
        }
      })
      Column(){
        Text(this.profile.name)
        Blank().height(8)
        Text(this.profile.type  == 1 ? "URL":"File")
      }.padding(10).alignItems(HorizontalAlign.Start).layoutWeight(1)
      Text("3 min ago")
      Icon({icon:$r("app.media.ic_baseline_more_vert")}).bindSheet(this.showSheet, this.ConfigOption, {height: 250, dragBar: true, shouldDismiss:()=>{
        this.showSheet = false
      } }).onClick(()=>{
        this.showSheet = true
      })
    }.padding({left:10 }).margin({left:10, right: 10, top:5, bottom:5}).height(85)
    .onClick(()=>{
      if(this.onCheck){
        this.onCheck()
      }
    })
    .borderColor(Color.Black)
    .shadow({radius:4})
    .borderStyle(BorderStyle.Solid)
    .border({radius:8})
  }
}

