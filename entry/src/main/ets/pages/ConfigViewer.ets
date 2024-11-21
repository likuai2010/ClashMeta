import fs from "@ohos.file.fs"
import { promptAction } from '@kit.ArkUI'


@Component
export struct ConfigViewer {
  @Consume('router') routerInfos: NavPathStack
  @State content: string = ""
  configPath: string = ""
  aboutToAppear(): void {
    let params = this.routerInfos.getParamByName("config-viewer") as string[]
    const configPath = params[0]
    if (configPath != undefined){
      this.configPath = configPath
    }
    fs.access(this.configPath).then((res)=>{
      if(res){
        this.content = readConfig(this.configPath)
      }else{
        promptAction.showToast({message:"文件不存在:" + this.configPath})
      }
    })
  }
  build() {
    NavDestination() {
      Scroll(){
        Text(this.content)
      }.width('100%').height('100%')
    }.title("config.yaml").backgroundColor(Color.White)
  }
}
export function readConfig(filePath: string): string {
  return fs.readTextSync(filePath, {encoding: 'utf-8'})
}
