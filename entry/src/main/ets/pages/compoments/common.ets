import { Icon } from './icons'

@Component
export struct ActionCard {
  @Prop title: string
  @Prop value?: String
  icon: string = "adb"
  @Prop isRunning?: boolean = undefined
  click?: ()=>void
  fColor(){
    if(this.isRunning == undefined)
      return Color.Black
    else{
      return Color.White
    }
  }

  bgColor(){
    if(this.isRunning == undefined)
      return Color.White
    else if(this.isRunning){
      return $r("app.color.color_clash")
    }else{
      return $r("app.color.color_clash_stopped")
    }
  }
  build() {
    Row(){
      Icon({icon:$r(`app.media.${this.icon}`), iconColor:this.fColor()})
      Column(){
        Text(this.title).fontColor(this.fColor())
        Blank().height(8)
        if (this.value) {
          Text(this.value as string).fontColor(this.fColor())
        }
      }.padding(10).alignItems(HorizontalAlign.Start).layoutWeight(1)
    }.alignItems(VerticalAlign.Center)
    .backgroundColor(this.bgColor())
    .margin({left:10, right: 10, top:5, bottom:5})
    .height(80)
    .border({radius:8, width:0})
    .shadow({radius:4})
    .borderStyle(BorderStyle.Solid).onClick(()=>{
      if (this.click)
        this.click()
    })
  }
}

@Component
export struct ActionLabel {
  @Prop title: string
  @Prop subTitle?: string
  icon: string = "ic_baseline_more_vert"
  color: Color | string = Color.Black
  @State isSwitch?: boolean = undefined
  click?: ()=>void
  build() {
    Row(){
      Icon({icon:$r(`app.media.${this.icon}`), iconColor: this.color})
      Column(){
        Text(this.title).fontColor(this.color)
        Blank().height(5)
        if (this.subTitle != null){
          Text(this.subTitle).fontColor(this.color).fontSize(12)
        }
      }.padding(10).alignItems(HorizontalAlign.Start).layoutWeight(1)
      if (this.isSwitch != undefined){
        Toggle( { type: ToggleType.Switch, isOn: this.isSwitch })
      }
    }.alignItems(VerticalAlign.Center).margin({left:10, right: 10, top:5, bottom:5}).onClick(()=>{
      if(this.isSwitch != undefined){
        this.isSwitch = !this.isSwitch
      }
      if (this.click)
        this.click()
    })
  }
}
@Component
export struct ActionInput {
  @Prop value: string = ""
  @Prop defaultValue: string = ""
  @Prop title: string
  @Prop unit: string = "名称"
  dialogController: CustomDialogController | null = new CustomDialogController({
    builder: CustomInputDialog({
      confirm: (value:string) => {
        if (this.onChange)
          this.onChange(value)
      },
      subTitle: this.unit,
      textValue: this.value != "" ? this.value : ""
    })
  })

  icon: string = "ic_baseline_more_vert"
  color: Color | string = Color.Black
  onChange?: (value:string) => void
  build() {
    Row(){
      Icon({icon:$r(`app.media.${this.icon}`), iconColor: this.color})
      Column(){
        Text(this.title).fontColor(this.color).fontSize(12)
        Row(){
          Text(this.value == "" ? this.defaultValue : this.value).textOverflow({overflow: TextOverflow.Ellipsis}).maxLines(1).layoutWeight(1).fontSize(18)
          Icon({icon:$r(`app.media.ic_baseline_edit`), iconColor: this.color, iconSize: 18})
        }.width("100$").border({width: {bottom:1}, style: {bottom: BorderStyle.Solid}})
      }.padding(10).alignItems(HorizontalAlign.Start).layoutWeight(1).onClick(()=>{
        this.dialogController?.open()
      })
    }.margin({left:10, right: 10, top:5, bottom:5})
  }
}


@CustomDialog
export struct CustomInputDialog {
  title: string = "标题"
  subTitle: string = "名称"
  @Prop textValue: string
  controller?: CustomDialogController
  inputController?: TextInputController = new TextInputController()
  confirm: (val:string) => void = (val:string) => {
  }
  onPageShow(): void {
    this.inputController?.setTextSelection(0, 1, { menuPolicy:MenuPolicy.SHOW})
    this.inputController?.caretPosition(0)
  }
  build() {
    Column({ space: 20 }) {
      Text(this.title)
        .fontSize(20)
      Stack({alignContent:Alignment.TopStart}){
        TextInput({text: this.textValue, controller: this.inputController, }).defaultFocus(true).onChange((value)=>{
            this.textValue = value
        })
          .borderRadius(1).borderColor(Color.Black).borderStyle(BorderStyle.Solid).borderWidth(1).padding(15)
          .onSubmit(()=>{
              this.controller?.close()
              this.confirm(this.textValue)
        })
        Row(){
          Text(this.subTitle).fontSize(10)
        }.backgroundColor(Color.White).offset({x:10, y: -10})
      }.padding(10)
      Flex({ justifyContent: FlexAlign.SpaceAround }) {
        Button('取消')
          .onClick(() => {
            if (this.controller != undefined) {
              this.controller.close()
            }
          }).backgroundColor(0xffffff).fontColor(Color.Black)
        Button('确认')
          .onClick(() => {
            if (this.controller != undefined && this.textValue != '') {
              this.controller.close()
            } else if (this.controller != undefined) {
              this.controller.close()
            }
            this.confirm(this.textValue)
          }).backgroundColor(0xffffff).fontColor(Color.Red)
      }.margin({ bottom: 10 })
    }.borderRadius(10).padding({ top: 20 })
  }
}
