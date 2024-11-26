
import { Icon } from "./compoments/icons"
import { ConfigItem, ConfigItemType } from "./SettingsPage"
import { emitter } from "@kit.BasicServicesKit"
import { EventIds } from "../rpc/EventConstants"


@Component
export struct ConfigItemEdit {
  @Consume('router') routerInfos: NavPathStack
  @State content: string = ""
  @Prop config: ConfigItem
  aboutToAppear(): void {
   const type = this.config.type
      if( this.config.value == undefined){
        if (type == ConfigItemType.StringArray) {
            this.content = "[]"
        } else if(type == ConfigItemType.Map){
            this.content = "{}"
        }
      } else {
        this.content = JSON.stringify(this.config.value, null, 2)
      }
  }
  @Builder
  saveMenu(){
    Row(){
      Icon({
        icon:$r("app.media.ic_baseline_save")
      }).onClick(async ()=>{
        let value = this.content
        if(this.content != ""){
          if (this.config.type == ConfigItemType.StringArray || this.config.type == ConfigItemType.Map){
            value = JSON.parse(this.content)
          }
        }
        emitter.emit({eventId: EventIds.ConfigItemEdit}, {data: {
          key: this.config.key,
          value: this.content == "" ? undefined : value
        }})
        this.routerInfos.pop()
      })
    }
  }
  build() {
    NavDestination() {
      TextArea({text:this.content}).onChange((e)=>{
        this.content = e
      }).width('100%').height('100%')
    }.title("编辑").backgroundColor(Color.White).menus(this.saveMenu)
  }
}