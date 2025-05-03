import { router } from '@kit.ArkUI';

@Entry
@Component
struct router_page {
  @State message: string = 'Hello router!';

  build() {
    RelativeContainer() {
      Column(){
        Text(this.message)
          .id('PageHelloWorld')
          .fontSize($r('app.float.page_text_font_size'))
          .fontWeight(FontWeight.Bold)
          .alignRules({
            center: { anchor: '__container__', align: VerticalAlign.Center },
            middle: { anchor: '__container__', align: HorizontalAlign.Center }
          })
          .onClick(() => {
            this.message = 'Welcome';
          })

        Button('返回')
          .onClick(() => {
            router.back();
          })
      }
      .alignRules({  // 关键修改1：设置Column容器居中
        center: { anchor: '__container__', align: VerticalAlign.Center },
        middle: { anchor: '__container__', align: HorizontalAlign.Center }
      })
      .width('100%')
      .alignItems(HorizontalAlign.Center)  // 关键修改2：设置子项水平居中
      .justifyContent(FlexAlign.Center)    // 关键修改3：设置子项垂直居中


    }
    .height('100%')
    .width('100%')
  }
}