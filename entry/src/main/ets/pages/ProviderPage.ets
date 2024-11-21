import SocketProxyService from "../rpc/SocketProxyService"
import {  Provider,  } from '../ipc/IClashManager';
import { ActionLabel } from "./compoments/common";
import { Icon } from "./compoments/icons";

@Component
export struct ProviderPage {
  @Consume('router') routerInfos: NavPathStack
  @State providers: Provider[] = []
  configPath: string = ""
  async  aboutToAppear(): Promise<void> {
    this.providers = await SocketProxyService.queryProviders()
  }
  build() {
    NavDestination() {
      Scroll(){
        Column(){
          ForEach(this.providers, (item: Provider)=>{
            ProviderItem({ provider:item })
          })
        }
      }.width('100%').height('100%')
    }.title("外部资源")
  }
}

@Component
export struct ProviderItem {
  @Prop provider: Provider
  icon: string = "ic_baseline_swap_vert"
  color: Color | string = Color.Black
  @State isLoading: boolean = false
  time():string{
    let time = "最近"
    let now = new Date().getTime()
    let total = (now - this.provider.updatedAt) / 60 / 1000
    time += (total.toFixed(0) + "分钟")
    return time ;
  }
  build() {
    Row(){
      Column(){
        Text(this.provider.name).fontColor(this.color)
        Blank().height(5)
        Text(`${this.provider.type}(${this.provider.vehicleType})`).fontColor(this.color).fontSize(12)
      }.padding(10).alignItems(HorizontalAlign.Start).layoutWeight(1)
      Text(this.time())
      if (!this.isLoading){
        Icon({icon:$r(`app.media.${this.icon}`), iconColor: this.color}).onClick(async ()=>{
          this.isLoading = true
          await SocketProxyService.updateProvider(this.provider.type, this.provider.name)
          this.isLoading = false
        })
      }else {
        Row(){
          LoadingProgress().size({width:30, height:30})
        }.padding(10)

      }
    }.alignItems(VerticalAlign.Center).margin({left:10, right: 10, top:5, bottom:5})
  }
}