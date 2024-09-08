@Component
export struct Icon {
  icon!: Resource
  iconSize: number = 30
  iconColor: Color | string = Color.Black
  build(){
    Row(){
      Image(this.icon)
        .width(this.iconSize)
        .height(this.iconSize)
        .fillColor(this.iconColor)
    }.padding(10).clickEffect({level:ClickEffectLevel.MIDDLE, scale:0.5})
  }
}