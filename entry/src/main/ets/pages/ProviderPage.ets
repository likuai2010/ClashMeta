import SocketProxyService from "../rpc/SocketProxyService"
import {  Provider,  } from '../ipc/IClashManager';
import { Icon } from "./compoments/icons";
import { emitter } from "@kit.BasicServicesKit";
import { EventIds } from "../rpc/EventConstants";

@Component
export struct ProviderPage {
  @Builder
  MoreMenu(){
    Row(){
      // Icon({
      //   icon:$r("app.media.ic_baseline_save")
      // }).onClick(async ()=>
      // {
      //   emitter.emit({eventId:allFetch})
      // })
    }
  }

  @Consume('router') routerInfos: NavPathStack
  @State providers: Provider[] = []
  configPath: string = ""
  async  aboutToAppear(): Promise<void> {
    this.providers = await SocketProxyService.queryProviders()
  }
  async fetchProvider(){
    this.providers = await SocketProxyService.queryProviders()
  }
  build() {
    NavDestination() {
      Scroll(){
        Column(){
          ForEach(this.providers, (item: Provider)=>{
            ProviderItem({ provider: item, onFetch:()=>{
              this.fetchProvider()
            }})
          })
        }
      }.width('100%').height('100%')
    }.title("外部资源").menus(this.MoreMenu())
  }
}

@Component
export struct ProviderItem {
  @Prop provider: Provider
  icon: string = "ic_baseline_swap_vert"
  color: Color | string = Color.Black
  onFetch?: ()=> void
  @State isLoading: boolean = false
  time():string{
    let time = "最近"
    let now = new Date().getTime()
    let total = (now - this.provider.updatedAt) / 60 / 1000
    time += (total.toFixed(0) + "分钟")
    return time ;
  }
  aboutToAppear(): void {
    emitter.on({eventId: EventIds.AllFetch}, ()=>{
      this.fetchProvider()
    })
  }
  async fetchProvider(){
    this.isLoading = true
    await SocketProxyService.updateProvider(this.provider.type, this.provider.name)
    this.isLoading = false
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
            this.fetchProvider()
        })
      }else {
        Row(){
          LoadingProgress().size({width:30, height:30})
        }.padding(10)

      }
    }.alignItems(VerticalAlign.Center).margin({left:10, right: 10, top:5, bottom:5})
  }
}