// 跳转页面入口函数
@Builder
export function Advertisement_Builder() {
  Advertisement()
}

@Component
struct Advertisement {
  pathStack: NavPathStack = new NavPathStack()

  aboutToAppear(): void {
    setTimeout(() => {
      this.pathStack.replacePathByName("Layout", null, false);
    },3000)
  }

  build() {
    NavDestination() {
      // Button("点击跳转下一页")
        // .onClick(() => {
        //   this.pathStack.pushPathByName("Layout", null, false);
        // })

      Stack({alignContent: Alignment.TopEnd}) {
        Image($r('app.media.ad'))
          .width('100%')
          .height('100%')
          .expandSafeArea([SafeAreaType.SYSTEM],[SafeAreaEdge.TOP, SafeAreaEdge.BOTTOM])

        Button('跳过')
          .backgroundColor(Color.Grey)
          .margin(15)
          .onClick(() => {
            this.pathStack.replacePathByName("Layout", null, false);
          })

      }



    }
    // .title('广告页')
    .onReady((context: NavDestinationContext) => {
      this.pathStack = context.pathStack
    })
  }
}