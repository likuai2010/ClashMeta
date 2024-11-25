import  { OverrideSlot, Proxy, ProxyGroup, ProxySort, ProxyType, TunnelState } from '../entryability/ClashViewModel'
import { Icon } from './compoments/icons'
import { JSON } from '@kit.ArkTS'
import clashProxyService from '../rpc/SocketProxyService'
import profileViewModel from '../entryability/ProfileViewModel'
import { promptAction } from '@kit.ArkUI'
import { Selection } from '../entryability/SelectionRepo'
import { Profile } from '../entryability/ProfileRepo'

@Component
struct ProxyNode {
  @Prop name: string
  @Prop type : string = "Trojan"
  @Prop delay: string = ""
  @Prop selected: boolean = false
  build() {
    Column(){
      Text(this.name).fontColor(this.selected ? Color.White : Color.Black)
      Blank().height(5)
      Row(){
        Text(this.type).fontColor(this.selected ? Color.White : Color.Black)
        if (this.delay !== "65535"){
          Text(this.delay + "ms").fontColor(this.selected ? Color.White : Color.Black)
        }
      }.justifyContent(FlexAlign.SpaceBetween).width("100%")
    }.alignItems(HorizontalAlign.Start).width("100%").padding(5).backgroundColor(this.selected ? "#1e4376" : Color.White).border({radius:5})
  }
}

interface MenuInfo{
  label: string
  value: string
}

@Component
export struct ProxysPage {
  replay: NavigationMenuItem = {'value': "", 'icon': "resources/base/media/ic_baseline_flash_on.svg", 'action': ()=> {}}
  more: NavigationMenuItem = {'value': "", 'icon': "resources/base/media/ic_baseline_more_vert.svg", 'action': ()=> {}}
  proxy: string[] = []
  @StorageLink('lastGroupName') lastGroupName: string = ""

  @Builder
  Radio() {
    Radio({value:"", group:""})
  }
  @State  proxyModel: TunnelState = TunnelState.None
  @State layoutModel: number = 2
  @State  sortModel:ProxySort = ProxySort.Default

  @State testing: boolean = false

  @Builder
  ModelMenu() {
    this.buildMenu([
      {label:"不修改", value: TunnelState.None},
      {label:"直连模式", value: TunnelState.Direct},
      {label:"全局模式", value: TunnelState.Global},
      {label:"规则模式", value: TunnelState.Rule},
    ], this.proxyModel, async  (value)=>{
      this.proxyModel = value as TunnelState
      let o = await clashProxyService.queryOverride(OverrideSlot.Session)
      if (value == TunnelState.None){
         o.mode == undefined
      } else {
        o.mode = value as TunnelState
      }
      await clashProxyService.patchOverride(OverrideSlot.Session, o)
      const configPath = await profileViewModel.getActiveConfigPath()
      if (configPath){
        await clashProxyService.load(configPath!)
        this.fetchProxyGroupList()
      }
    })
  }
  @Builder
  buildMenu(list: MenuInfo[], selected: String, onChange:(value: string)=>void){
    Menu() {
      ForEach(list, (m: MenuInfo) => {
        MenuItem({ content: m.label })
          .selectIcon(true)
          .selected(selected == m.value)
          .onClick(() => {
            onChange(m.value)
          })
      }, (m: MenuInfo) => JSON.stringify(m))
    }
  }

  @Builder
  LayoutMenu() {
    this.buildMenu([
      {label:"单列", value: "1"},
      {label:"双列", value: "2"},
      {label:"多列", value: "3"},
    ], this.layoutModel + "", (value)=>{
      this.layoutModel  = parseInt(value)
    })
  }
  @Builder
  SortMenu() {
    this.buildMenu([
      {label:"默认", value: ProxySort.Default},
      {label:"名称", value: ProxySort.Title},
      {label:"延迟", value: ProxySort.Delay},
    ], this.sortModel, (value)=>{
      this.sortModel = value as ProxySort
      this.fetchProxyGroupList()
    })
  }

  @Builder
  MyMenu() {
    Menu() {
      MenuItem({ startIcon: $r("app.media.ic_baseline_flash_on"), content: "模式",builder: this.ModelMenu })
      MenuItem({
        startIcon: $r("app.media.ic_baseline_flash_on"),
        content: "布局",
        builder: this.LayoutMenu
      })
      MenuItem({ startIcon: $r("app.media.ic_baseline_flash_on"), content: "排序", builder: this.SortMenu })
    }
  }
  @Builder
  MoreMenu(test: boolean){
    Row(){
      Icon({
        icon:$r("app.media.ic_baseline_flash_on"),
        iconColor: test ? "#ccc": Color.Black,
        iconSize: 30,
      }).onClick(async ()=>{
        if (this.testing){
            return
        }
        this.testing = true
        try {
          await clashProxyService.healthCheck(this.groupNames[this.tabIndexes])
          this.testing = false
          this.fetchProxyGroupList()
        } catch (e) {
          promptAction.showToast({message: e.message})
          this.testing = false
        }

      })
      Icon({
        icon:$r("app.media.ic_baseline_more_vert")
      }).bindMenu(this.MyMenu)
    }
  }
  scroller: Scroller = new Scroller();
  private controller: TabsController = new TabsController();
  @State tabIndexes: number = 0
  @State selectionsDict: Map<string, string> = new Map()
  profile?: Profile
  @State groupNames: string[] = []
  @State groupDict: Map<string, ProxyGroup> = new Map()

  async  aboutToAppear(): Promise<void> {
    await this.fetchProxyGroupList()
    let tabIndexes = this.groupNames.indexOf(this.lastGroupName)
    setTimeout(()=>{
      this.controller.changeIndex(tabIndexes)
    }, 50)
  }
  async fetchProxyGroupList(){
    this.proxyModel = (await clashProxyService.queryOverride(OverrideSlot.Session)).mode || TunnelState.None
    let names = await clashProxyService.queryProxyGroupNames(false)
    console.debug("fetchProxyGroupList ", names,  this.proxyModel)
    let groupDict:Map<string, ProxyGroup> = new Map()
    for (let n of names){
      const proxyGroup = await clashProxyService.queryProxyGroup(n, this.sortModel)
      groupDict.set(n, proxyGroup)
    }
    this.groupDict = groupDict
    this.groupNames = Array.from(this.groupDict.keys())
    try {
      this.profile = await profileViewModel.getActive()
      const selections = await profileViewModel.getSelection(this.profile?.uuid)
      this.selectionsDict = new Map()
      selections.forEach((s)=>{
        this.selectionsDict.set(s.proxy, s.selected)
      })
    } catch (e) {
      promptAction.showToast({message: `getSelection error: ${e}`})
    }

  }
  async selectNode(i: number, g: string, node: Proxy){
    this.selectionsDict.set(g, node.name)
    let result = await clashProxyService.patchSelector(g, node.name)
    if (this.profile && result){
      await profileViewModel.updateSelection(new Selection(this.profile!.uuid, g, node.name))
    }
    if(!result){
      promptAction.showToast({message: `切换节点失败： ${g} ${node.name}`})
    }
  }
  build() {
    NavDestination() {
      Column() {
        Tabs({ barPosition: BarPosition.Start, controller: this.controller }) {
          ForEach(Array.from(this.groupNames), (g:string)=>{
            TabContent() {
              Scroll(this.scroller) {
                GridRow({ columns: this.layoutModel, gutter: 5 }) {
                  ForEach( Array.from(this.groupDict.get(g)?.proxies ?? []), (item: Proxy, i)=>{
                    GridCol({ span: 1 }) {
                      if ( this.groupDict.get(g)?.type != ProxyType.Selector){
                        ProxyNode({name: item.title, type: item.subtitle, selected: this.groupDict.get(g)?.now == item.name})
                      }else{
                        ProxyNode({name: item.title, type: item.subtitle, selected: this.selectionsDict.get(g) == item.name, delay: item.delay + ""}).onClick(()=>{
                          this.selectNode(i, g, item)
                        })
                      }
                    }
                  }, (d: Proxy)=> JSON.stringify(d))
                }
              }.padding(5).height("100%").backgroundColor("#ffececec")
            }
            .tabBar(g)
          }, (i:string) => i)
        }.barMode(BarMode.Scrollable).onChange((index)=>{
          this.tabIndexes = index
          this.lastGroupName = this.groupNames[index]
        })
      }.width('100%')
    }.menus(this.MoreMenu(this.testing)).title("代理")
  }
}
