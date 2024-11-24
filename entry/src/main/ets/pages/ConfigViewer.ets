import fs from "@ohos.file.fs"
import { promptAction } from '@kit.ArkUI'
import { Icon } from "./compoments/icons"


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
  @Builder
  saveMenu(){
    Row(){
      Icon({
        icon:$r("app.media.ic_baseline_save")
      }).onClick(async ()=>{
        this.saveConfig()
      })
    }
  }
  noChange = true
  saveConfig(){
    if(!this.noChange){
      promptAction.showDialog({title:"保存配置", message: "确定保存当前配置?", buttons: [{text:"确定", color: "#ccc" }]}, ).then((v)=>{
        if(v.index == 0){
          saveConfig(this.configPath, this.content)
          this.routerInfos.pop()
        }
      })
    }else{
      this.routerInfos.pop()
    }
  }
  build() {
    NavDestination() {
      TextArea({text:this.content}).onChange((e)=>{
        this.content = e
        this.noChange = false
      }).width('100%').height('100%')
    }.title("config.yaml").backgroundColor(Color.White).menus(this.saveMenu)
  }
}
export function readConfig(filePath: string): string {
  return fs.readTextSync(filePath, {encoding: 'utf-8'})
}

export function saveConfig(filePath: string, data: string ) {
  if(data != null ){
    const file = fs.openSync(filePath, fs.OpenMode.CREATE | fs.OpenMode.READ_WRITE | fs.OpenMode.TRUNC)
    fs.writeSync(file.fd, data);
    fs.fsyncSync(file.fd)
    fs.closeSync(file);
  }
}