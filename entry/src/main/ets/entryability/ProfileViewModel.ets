import { Profile, ProfileRepo, ProfileType } from './ProfileRepo'
import { common } from '@kit.AbilityKit'
import fs from '@ohos.file.fs'
import { nativeFetchAndValid, nativeInit,} from 'libentry.so'
import { promptAction } from '@kit.ArkUI'
import { Selection, SelectionRepo } from './SelectionRepo'
import { fileUri } from '@kit.CoreFileKit'
import SocketProxyService from '../rpc/SocketProxyService'

export interface FetchStatus{
  action:string
  args:string[]
  progress: number
  max: number
}
export class ProfileViewModel{
  repo: ProfileRepo = new ProfileRepo()
  selectionRepo: SelectionRepo = new SelectionRepo()
  context: common.Context | undefined
  running: boolean = false
  async init(context:common.Context){
    this.context = context
    await this.repo.init(context)
    await this.selectionRepo.init(this.repo.store)
  }
  async  getProfileList(): Promise<Profile[]>{
    return await this.repo.queryAll()
  }
  async getActive(): Promise<Profile | undefined>{
    let profile =  await this.repo.queryAll()
    return profile.find((p) => p.active)
  }
  async getProfile(uuid: string | undefined): Promise<Profile>{
    try {
      let profile =  await this.repo.query(uuid)
      if (profile)
        return profile
    }catch (e){
      console.error("Clash", e, e.stack)
    }
    return new Profile();
  }
  async getSelection(uuid: string | null = null): Promise<Selection[]>{
    if (uuid == null)
      uuid = (await this.getActive())?.uuid ?? ""
    return await this.selectionRepo.query(uuid)
  }
  private async saveProfile(profile: Profile){
    await this.repo.addOrUpdate(profile)
  }
  async  updateSelection(select: Selection){
    await this.selectionRepo.addOrUpdate(select)
  }

  async testSelection(){
    await this.updateSelection(new Selection("testId", "proxy", "node"))
    let dd = await this.getSelection("testId")
    promptAction.showToast({message: `测试数据读写: ${JSON.stringify(dd)}`})
  }
  async testIConSelection(){
    await this.updateSelection(new Selection("testId2", '🚀 节点选择', '♻️ 自动选择'))
    let dd = await this.getSelection("testId2")
    promptAction.showToast({message: `测试数据读写: ${JSON.stringify(dd)}`})
  }

  async updateProfile(profile:Profile){
    await this.repo.addOrUpdate(profile)
  }

  async activeProfile(profile: Profile){
    profile.active = true
    const list = await this.getProfileList()
    for (let d of list){
      if(d.uuid != profile.uuid){
        d.active = false
        await this.saveProfile(d)
      }
      else{
        d.active = true
        await this.saveProfile(d)
      }
    }
    if(this.running){
      let configPath = await this.getConfigPath(profile)
      await SocketProxyService.load(configPath)
      const selection = await this.selectionRepo.query(profile.uuid)
      selection.forEach((s)=>{
        SocketProxyService.patchSelector(s.proxy, s.selected)
      })
    }
  }
  async delete(uuid: string){
    await this.repo.delete(uuid)
    await this.selectionRepo.delete(uuid)
  }
  async addProfile(profile:Profile, onUpdate:(value:FetchStatus)=>void): Promise<boolean>{
    const configPath = await this.getConfigPath(profile)
    let result = false
    if (profile.source.startsWith("http")) {
      profile.type = ProfileType.Url
      result = await this.download(configPath, profile.source, false, onUpdate)
    }else{
      profile.type = ProfileType.File
      await fs.copy(profile.source, fileUri.getUriFromPath(configPath +  "/config.yaml"))
      result = await this.download(configPath, "", true, onUpdate)
    }
    if(result){
      await this.saveProfile(profile)
      return true
    }else{
      promptAction.showToast({message:"添加配置失败"})
      return false
    }
  }
  async loadConfig(targetUri:string): Promise<string>{
    let configPath =  this.context?.tempDir + "/config.yaml"

    return configPath;
  }

  async download(configPath:string, url: string, force: boolean, onUpdate:(value:FetchStatus)=>void): Promise<boolean>{
    return new Promise((resolve, reject)=>{
      nativeFetchAndValid(configPath, url, force, (type:string, value:string)=>{
        if (type == "fetch_complete"){
            if(value != ""){
              console.log("nativeFetchAndValid " + type + ":", value);
              promptAction.showToast({message: `下载失败: ${value}`, duration:3000 })
              resolve(true)
            } else {
              if(fs.accessSync(configPath + "/config.yaml")){
                resolve(true)
              }else{
                resolve(false)
              }
            }
        }else {
          console.log("nativeFetchAndValid " + type + ":", value);
          let status = JSON.parse(value.trim()) as FetchStatus
          onUpdate(status)
        }
      })
    })
  }
  async getConfigPath(profile: Profile): Promise<string>{
    const imported = this.context?.filesDir +"/import/"
    if(!await fs.access(imported, fs.AccessModeType.EXIST)){
       await fs.mkdir(imported)
    }

    const configPath = imported + profile.uuid

    if(!await fs.access(configPath, fs.AccessModeType.EXIST)){
      await fs.mkdir(configPath)
    }
    if(!await fs.access(configPath + "/providers", fs.AccessModeType.EXIST)){
      await fs.mkdir(configPath + "/providers")
    }
    return configPath
  }

  async getActiveConfigPath(): Promise<string | undefined>{
    const profile = await this.getActive()
    if (!profile)
      return undefined
    return this.getConfigPath(profile)
  }
  async getHome():Promise<string>{
    const home = this.context?.filesDir +"/home/"
    if (!await fs.access(home, fs.AccessModeType.EXIST)){
      await fs.mkdir(home)
    }
    return home;
  }
  async initGeoIp(){
    let geoIp = await readFile(this.context?.resourceDir + "/geoip.metadb")
    writeFile(await this.getHome() + "geoip.metadb", geoIp)
    let geoSite = await readFile(this.context?.resourceDir + "/geosite.dat")
    writeFile(await this.getHome() + "geosite.dat", geoSite)
    // if(bytes != null){
    //   nativeInstallSideloadGeoip(bytes)
    // }
  }
}
export async  function readFile(filePath: string): Promise<Uint8Array | null> {
  if(!await fs.access(filePath))
    return null;
  const file = await fs.open(filePath)
  const stats = await fs.stat(filePath)
  let bufSize = stats.size;
  let buf = new ArrayBuffer(bufSize);
  await fs.read(file.fd, buf, { offset: 0, length: bufSize });
  await fs.close(file);
  return new Uint8Array(buf);
}
export function writeFile(filePath: string, data: Uint8Array | null) {
  if(data != null && data.byteLength > 0){
    const file = fs.openSync(filePath, fs.OpenMode.CREATE | fs.OpenMode.READ_WRITE)
    fs.writeSync(file.fd, data.buffer);
    fs.fsyncSync(file.fd)
    fs.closeSync(file);
  }
}
export default new ProfileViewModel()