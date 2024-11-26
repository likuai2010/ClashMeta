import fs from "@ohos.file.fs"
import SocketProxyService from "../rpc/SocketProxyService"
export interface LogInfo{
    level: string
    message: string
    time: string
}

class BasicDataSource implements IDataSource {
  private listeners: DataChangeListener[] = [];
  private originDataArray: LogInfo[] = [];

  public totalCount(): number {
    return 0;
  }

  public getData(index: number): LogInfo {
    return this.originDataArray[index];
  }

  registerDataChangeListener(listener: DataChangeListener): void {
    if (this.listeners.indexOf(listener) < 0) {
      console.info('add listener');
      this.listeners.push(listener);
    }
  }

  unregisterDataChangeListener(listener: DataChangeListener): void {
    const pos = this.listeners.indexOf(listener);
    if (pos >= 0) {
      console.info('remove listener');
      this.listeners.splice(pos, 1);
    }
  }

  notifyDataReload(): void {
    this.listeners.forEach(listener => {
      listener.onDataReloaded();
    })
  }

  notifyDataAdd(index: number): void {
    this.listeners.forEach(listener => {
      listener.onDataAdd(index);
    })
  }

  notifyDataChange(index: number): void {
    this.listeners.forEach(listener => {
      listener.onDataChange(index);
    })
  }

  notifyDataDelete(index: number): void {
    this.listeners.forEach(listener => {
      listener.onDataDelete(index);
    })
  }

  notifyDataMove(from: number, to: number): void {
    this.listeners.forEach(listener => {
      listener.onDataMove(from, to);
    })
  }

  notifyDatasetChange(operations: DataOperation[]): void {
    this.listeners.forEach(listener => {
      listener.onDatasetChange(operations);
    })
  }
}


class LogsSource extends  BasicDataSource {
  private dataArray: LogInfo[] = [];

  public totalCount(): number {
    return this.dataArray.length;
  }

  public getData(index: number): LogInfo {
    return this.dataArray[index];
  }

  public addData(index: number, data: LogInfo): void {
    this.dataArray.splice(index, 0, data);
    this.notifyDataAdd(index);
  }

  public pushData(data: LogInfo): void {
    this.dataArray.push(data);
    this.notifyDataAdd(this.dataArray.length - 1);
  }

}

@Component
export struct LogsPage {
  @Consume('router') routerInfos: NavPathStack
  @StorageLink('setLogObserver') setLogObserver: boolean = true
  @State content: string = ""
  @State logs: LogInfo[] = []
  private data: LogsSource = new LogsSource();
  configPath: string = ""
  logHandler: ()=>void = ()=>{}
  @Builder
  logsMenu(){
    Row(){
      Toggle( { type: ToggleType.Switch, isOn: this.setLogObserver }).onChange(async (value)=>{
        this.setLogObserver =value
        if(this.setLogObserver){
          this.logHandler = await SocketProxyService.setLogObserver((v)=>{
            try {
              this.data.pushData(JSON.parse(v))
            } catch (e) {
              console.log("setLogObserver faile", v, e)
            }
          })
        }else{
          this.logHandler()
        }
      })
    }.padding(10)
  }

  async  aboutToAppear(): Promise<void> {
    this.logs = []
    let i=0;
    if(this.setLogObserver){
      this.logHandler = await SocketProxyService.setLogObserver((v)=>{
        try {
          this.data.pushData(JSON.parse(v))
        } catch (e) {
          console.log("setLogObserver faile", v, e)
        }
      })
    }

  }
  build() {
    NavDestination() {
      Scroll(){
       Column(){
         LazyForEach(this.data, (item: LogInfo) => {
           Column(){
             Row() {
               Text(item.level).fontWeight(FontWeight.Bold)
               Blank().width(10)
               Text(new Date(item.time).toLocaleString())
             }.width("100%").justifyContent(FlexAlign.Start)
             Blank().width(5)
             Text(item.message).fontSize(12)
           }.alignItems(HorizontalAlign.Start).margin({ left: 10, right: 10, top:10 })
         }, (item: string) => item)
       }.reverse(true)
      }.align(Alignment.Top).height('100%')
    }.title("日志").menus(this.logsMenu).backgroundColor(Color.White)
  }
}
export function readConfig(filePath: string): string {
  return fs.readTextSync(filePath, {encoding: 'utf-8'})
}
