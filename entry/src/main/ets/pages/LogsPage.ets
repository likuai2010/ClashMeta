import fs from "@ohos.file.fs"
import { promptAction } from '@kit.ArkUI'
import SocketProxyService from "../rpc/SocketProxyService"


@Component
export struct LogsPage {
  @Consume('router') routerInfos: NavPathStack
  @State content: string = ""
  @State logs: string[] = []
  configPath: string = ""
  aboutToAppear(): void {
    SocketProxyService.setLogObserver((v)=>{
      console.log("xxxx", v)
    })
  }
  build() {
    NavDestination() {
      Scroll(){
        Column(){
          ForEach(this.logs, (item: a)=>{
          })
        }
      }.width('100%').height('100%')
    }.title("config.yaml").backgroundColor(Color.White)
  }
}
export function readConfig(filePath: string): string {
  return fs.readTextSync(filePath, {encoding: 'utf-8'})
}
