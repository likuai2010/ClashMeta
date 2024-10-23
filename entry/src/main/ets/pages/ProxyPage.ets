import  { OverrideSlot, Proxy, ProxyGroup, ProxySort, TunnelState } from '../entryability/ClashViewModel'
import { Icon } from './compoments/icons'
import { HashMap, JSON } from '@kit.ArkTS'
import clashProxyService from '../ipc/ClashProxyService'
import { promptAction } from '@kit.ArkUI'
import profileViewModel from '../entryability/ProfileViewModel'
import { Profile } from '../entryability/ProfileRepo'
import { Selection } from '../entryability/SelectionRepo'
import logger from './logs'

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
  @State active: number = 0
  profile?: Profile
  @State groupNames: string[] = []
  @State groupDict: HashMap<string, ProxyGroup> = new HashMap()

  aboutToAppear(): void {
    this.fetchProxyGroupList()
  }
  async fetchProxyGroupList(){
    this.proxyModel = (await clashProxyService.queryOverride(OverrideSlot.Session)).mode || TunnelState.None
    let names = await clashProxyService.queryProxyGroupNames(false)
    console.debug("fetchProxyGroupList ", names,  this.proxyModel)
    let dict: HashMap<string, ProxyGroup> = new HashMap()
    for (let n of names){
      const proxyGroup = await clashProxyService.queryProxyGroup(n, this.sortModel)
      dict.set(n, proxyGroup)
    }
    this.groupDict = dict
    this.groupNames = names
    try {
      this.profile = await profileViewModel.getActive()
      let selection = await profileViewModel.getSelection(this.profile?.uuid)
      if (selection){
        this.tabIndexes = this.groupNames.indexOf(selection!.proxy)
        const groupName = this.groupNames[this.tabIndexes];
        const groupInfo = this.groupDict.get(groupName);

        this.active = groupInfo.proxies.findIndex((p)=>p.name == selection!.selected)
        logger.log("initNode name: ", `${selection!.proxy}  ${selection.selected}`)
        logger.log("initNode index: ", `${this.tabIndexes}  ${this.active}`)
        setTimeout(()=>{
          this.controller.changeIndex(this.tabIndexes)
        }, 100)
      }else{
        logger.log("initNode: ", `selection: null`)
        promptAction.showToast({message: `selection: null`})
      }
    } catch (e) {
      promptAction.showToast({message: `getSelection error: ${e}`})
    }

  }
  async selectNode(i: number, g: string, node: Proxy){
    this.active = i
    let result = await clashProxyService.patchSelector(g, node.name)
    if (this.profile){
      logger.log("selectNode ${}:  ", `|${g}  ${node.name}`)
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
          ForEach( this.groupNames, (g:string)=>{
            TabContent() {
              Scroll(this.scroller) {
                GridRow({ columns: this.layoutModel, gutter: 5 }) {
                  if(this.groupDict.hasKey(g)){
                    ForEach(this.groupDict.get(g).proxies, (item: Proxy, i)=>{
                      GridCol({ span: 1 }) {
                        ProxyNode({name: item.title, type: item.subtitle, selected: this.active == i, delay: item.delay + ""}).onClick(()=>{
                          this.selectNode(i, g, item)
                        })
                      }
                    }, (d: Proxy)=> JSON.stringify(d))
                  }
                }
              }.padding(5).height("100%").backgroundColor("#ffececec")
            }
            .tabBar(g)
          }, (i:string) => i)
        }.barMode(BarMode.Scrollable).onChange((index)=>{
          this.tabIndexes = index
        })
      }.width('100%')
    }.menus(this.MoreMenu(this.testing)).title("代理")
  }
}
