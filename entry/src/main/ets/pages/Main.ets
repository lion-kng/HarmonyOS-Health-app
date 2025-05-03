// 导入依赖模块
import { tabData } from "../entity/tab_class"  // 标签页配置数据
import { TabClass } from "../entity/tab_class"  // 标签页实体类
import { Data_page } from "../tabPages/DataPage";  // 数据管理页面
import { Health } from "../tabPages/Health";  // 健康主页
import { Mine1 } from "../tabPages/Mine1";  // 我的页面
import { AppStorageV2 } from "@kit.ArkUI";  // 状态管理

/**
 * 应用主页面结构
 * @description 包含底部导航栏的三页应用
 */
@Entry
@Component
struct Main_page {
  // 测试文本状态
  @State message: string = 'Hello World';

  // 当前活动标签页索引（存储在AppStorage）
  @StorageLink('activeTabIndex') activeTabIndex: number = 0

  // 当前显示的索引（局部状态）
  @State current_index:number=0

  // 标签页数据源
  tabData:TabClass[]=tabData

  /**
   * 构建标签栏项
   * @param item 标签页配置
   * @param index 标签页索引
   */
  @Builder get_TabBar(item:TabClass, index:number){
    Column({space:5}){
      // 图标
      Image(item.icon)
        .width(24)
          // 根据当前索引切换颜色
        .fillColor(this.current_index === index ? '#63AAAA' : '#7A7A7A ')

      // 标签文字
      Text(item.text)
        .fontSize(14)
          // 颜色切换
        .fontColor(this.current_index === index ? '#63AAAA' : '#7A7A7A ')
        .fontWeight(FontWeight.Bold)
    }
  }

  /**
   * 获取标签页内容
   * @param index 当前标签索引
   * @returns 对应页面组件
   */
  @Builder get_TabContent(index:number){
    // 根据索引返回对应页面
    if(index===0) Health()
    else if(index===1) Data_page()
    else if(index===2) Mine1()
  }

  build() {
    RelativeContainer() {
      // 标签页容器
      Tabs({barPosition:BarPosition.End}){  // 标签栏位置在底部
        // 遍历生成标签页
        ForEach(this.tabData,(item:TabClass,index:number)=>{
          TabContent(){  // 标签页内容区域
            this.get_TabContent(index)  // 动态加载对应页面
          }
          .tabBar(this.get_TabBar(item,index))  // 设置自定义tabBar
          // 安全区域扩展（排除系统默认边距）
          .expandSafeArea([SafeAreaType.SYSTEM],[SafeAreaEdge.TOP, SafeAreaEdge.BOTTOM])
          .backgroundColor('#ececec')  // 页面背景色
        })
      }
      .onChange((index:number)=>{  // 标签页切换监听
        this.current_index=index  // 更新当前索引
        console.info('current_index',this.current_index)
        this.activeTabIndex=index  // 同步到AppStorage
      })
      .backgroundColor('#dedede')  // 容器背景色
      // 安全区域扩展（排除系统默认边距）
      .expandSafeArea([SafeAreaType.SYSTEM],[SafeAreaEdge.TOP, SafeAreaEdge.BOTTOM])

    }
    .height('100%')  // 占满屏幕高度
    .width('100%')   // 占满屏幕宽度
  }
}