import { router } from '@kit.ArkUI';



function onJumpClick(): void {
  router.pushUrl({
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
export struct Recommend {
  swiperList:string[]=[
    "http://yjy-teach-oss.oss-cn-beijing.aliyuncs.com/HeimaCloudMusic/banner1.png",
    "http://yjy-teach-oss.oss-cn-beijing.aliyuncs.com/HeimaCloudMusic/banner2.png",
    "http://yjy-teach-oss.oss-cn-beijing.aliyuncs.com/HeimaCloudMusic/banner3.png",
    "http://yjy-teach-oss.oss-cn-beijing.aliyuncs.com/HeimaCloudMusic/banner4.png"
  ]




  build() {
    Column({space:10}){
      Row(){
        Image($r('app.media.ic_search'))
          .width(24)
          .fillColor('#817d83')
        TextInput({placeholder:'日落大道🚩'})
          .placeholderColor('#817d83')
          .fontColor('#999')
          .fontSize(16)
          .padding({left:5})
          .layoutWeight(1)
        Image($r('app.media.ic_code'))
          .width(24)
          .fillColor('#817d83')
          .padding({right:5})
      }
      .width('100%')
      .padding({left:8,right:8})
      .backgroundColor('#2d2b29')
      .borderRadius(20)
      Swiper(){
        ForEach(this.swiperList,(item:string)=>{
          Image(item)
            .width('100%')
            .border({radius:10})
        })
      }
      .autoPlay(true)

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
    .width('100%')
    .height('100%')
    .padding({left:10,right:10,top:5,bottom:5})
  }
}