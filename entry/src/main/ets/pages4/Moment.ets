import { router } from '@kit.ArkUI';



function onJumpClick(): void {
  router.replaceUrl({
    url: 'pages5/router_page' // 目标url
  }, router.RouterMode.Standard, (err) => {
    if (err) {
      console.error(`Invoke pushUrl failed, code is ${err.code}, message is ${err.message}`);
      return;
    }
    console.info('Invoke pushUrl succeeded.');
  });
}



@Entry
@Component
export struct Moment {
  build() {
    Column() {
      Text('动态')
        .fontSize(36)
        .fontColor(Color.White)
      Button(){
        Text('通过页面路由跳转')
          .fontColor(Color.White)
          .fontSize(18)
      }
      .onClick(()=>{
        onJumpClick()
      })
      .height(50)
      .width(200)




    }




  }
}