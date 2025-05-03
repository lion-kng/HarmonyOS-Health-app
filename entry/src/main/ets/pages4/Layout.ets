import { tabData } from "../entity/tab_class"
import { Find } from "./Find"
import { Mine } from "./Mine"
import { Moment } from "./Moment"
import { Recommend } from "./Recommend"

interface TabClass{
  text:string
  icon:ResourceStr
}

// 跳转页面入口函数
@Builder
export function Layout_Builder() {
  Layout()
}

@ComponentV2
struct Layout {
  @Local current_index:number=0
  pathStack: NavPathStack = new NavPathStack()
  tab_data:TabClass[]=[
    {text:'推荐',icon:$r('app.media.ic_recommend')}
    ,{text:'发现',icon:$r('app.media.ic_find')}
    ,{text:'动态',icon:$r('app.media.ic_moment')}
    ,{text:'我的',icon:$r('app.media.ic_mine')}

  ]

  tab_info:TabClass[]=tabData


  @Builder tab_builder(item:TabClass,index:number){
    Column({space:5}){
      Image(item.icon)
        .width(24)
        .fillColor(this.current_index === index ? '#E85A88' : '#63AAAA')
      Text(item.text)
        .fontSize(14)
        .fontColor(this.current_index === index ? '#E85A88' : '#63AAAA')
    }
  }
  @Builder
  private get_TabContent(index:number): void{
    if(index===0) Recommend()
    else if(index===1) Find()
    else if(index===2) Moment()
    else if(index===3) Mine()
  }
  // 新增内容选择函数


  build() {

    NavDestination() {
      Tabs({barPosition:BarPosition.End}) {
        ForEach(this.tab_data,(item:TabClass,index:number)=>{
          TabContent(){
            this.get_TabContent(index)
          }
          .tabBar(this.tab_builder(item,index))
          .expandSafeArea([SafeAreaType.SYSTEM],[SafeAreaEdge.TOP, SafeAreaEdge.BOTTOM])
          .backgroundColor('#131215')



        })


      }
      .onChange((index:number)=>{
        this.current_index=index
      })
      .backgroundColor('#3B3F42')
      .expandSafeArea([SafeAreaType.SYSTEM],[SafeAreaEdge.TOP, SafeAreaEdge.BOTTOM])

    }
    // .title('布局页')
    .onReady((context: NavDestinationContext) => {
      this.pathStack = context.pathStack
    })
  }
}