import fs from "@ohos.file.fs"
import { hilog } from '@kit.PerformanceAnalysisKit'

export class Logger{
  logFd: number = 0
  constructor() {
    try {
      const file = fs.openSync("/data/storage/el2/base/haps/entry/files/log.txt", fs.OpenMode.CREATE | fs.OpenMode.READ_WRITE | fs.OpenMode.APPEND)
      this.logFd = file.fd
    } catch (e) {
      console.error("Logger error",e.message, e.stack)
    }

  }
  public log(tag: string, message:string){
    hilog.info(0x0000, tag, message);
    this.writeFile(tag + ":"+ message)
  }
  clear(){
    fs.unlink("/data/storage/el2/base/haps/entry/files/log.txt")
  }
  async  writeFile(message:string){
    const timestamp = new Date().toISOString();
    const logMessage = `${timestamp} - ${message}\n`;
    try {
      await fs.write(this.logFd, logMessage)
      await fs.fsync(this.logFd)
    } catch (e) {
      console.log("Logger error", e.message)
    }

  }
}

export default new Logger()