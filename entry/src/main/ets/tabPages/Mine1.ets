import { DataService } from "../data_base/data_base";
import { AppStorageV2 } from "@kit.ArkUI";
import { TargetClass } from "../entity/target_class";

@Entry
@Component
export struct Mine1 {
  // 获取当前组件上下文
  context: Context = getContext(this) as Context

  // 连接数据库服务（单例模式）
  data_service: DataService = AppStorageV2.connect(DataService, "data_service",
    () => new DataService(this.context))!

  // UI加载进度百分比
  @State loadingProgress: number = 0

  // 是否处于加载状态
  @State isLoading: boolean = true

  // 目标信息（从AppStorage链接）
  @StorageLink('target_info') target_info:TargetClass = new TargetClass()

  // 睡眠时间转换（小时/分钟）
  @State sleep_hours: number = 0
  @State sleep_minutes: number = 0;
  // 睡眠时间对象（可能用于时间选择器）
  @State sleep_time: Date = new Date()

  // 饮水相关状态
  @StorageLink('water_range') water_range: number[] = []  // 饮水范围数组
  @StorageLink('water_interval') water_interval: number = 500  // 每杯容量
  @State water_cup: number = -1  // 当前饮水杯数（-1表示未初始化）

  /**
   * 组件即将显示时执行
   * @description 初始化目标数据和状态
   */
  async aboutToAppear(): Promise<void> {
    this.isLoading = true  // 开始加载

    // 查询目标数据
    this.target_info = await this.data_service.target_query_data()
    console.info(`[target]  ${JSON.stringify(this.target_info)}`)

    // 睡眠时间格式转换（分钟→小时+分钟）
    this.sleep_hours = Math.floor(this.target_info.sleep_target / 60)
    this.sleep_minutes = this.target_info.sleep_target % 60

    // 同步饮水间隔设置
    this.water_interval = this.target_info.water_interval

    // 生成饮水量选择范围（如[0,500,1000,...]）
    this.get_water_range()

    // 计算当前杯数（可能存在问题：water_interval可能为0）
    this.water_cup = Math.floor(this.target_info.water_target / this.water_interval)

    this.isLoading = false  // 加载完成

  }

  build() {
    if (this.isLoading) {
      this.ProgressLoading() // 显示加载动画
    }
    else {

      Column() {
        // 头像栏 - 用户信息展示区域
        Row() {
          // 头像图标
          Image($r('app.media.head'))  // 资源文件中的头像图片
            .width(60)                // 设置固定宽度
            .height(60)               // 设置固定高度
            .borderRadius(5)           // 微圆角（非完全圆形）
            .margin({
              right: 18,
              left: 18
            })  // 左右外边距

          // 用户名及辅助信息
          Column() {
            // 主用户名显示
            Text('userName')          // 用户名文本
              .fontSize(28)            // 大字号突出显示
              .fontWeight("bold")      // 加粗字体
              .fontColor(Color.Black)  // 黑色字体
              .margin({ top: -20 })    // 向上微调位置

            // 点击提示文本
            Text("点击查看资料")      // 辅助说明文本
              .fontSize(12)            // 小字号
              .fontColor(Color.Gray)    // 灰色字体
          }
          .layoutWeight(1)  // 剩余空间均分
          .alignItems(HorizontalAlign.Start)  // 水平左对齐

          // 右侧更多按钮
          Image($r('app.media.more'))  // 更多图标资源
            .width(50)
            .height(50)
            .margin({
              top: 20,
              left: 'auto'  // 配合父容器实现右对齐
            })
            .alignSelf(ItemAlign.Center)  // 垂直居中对齐
            .onClick(() => {
              // 点击事件处理（当前未实现）
              // 开发者可在此添加跳转个人资料页逻辑
            })
        }
        // 行容器样式设置
        .alignItems(VerticalAlign.Center)  // 垂直居中对齐
        .height(200)                      // 固定高度200
        .width('100%')                   // 宽度占满
        .backgroundColor(Color.White)     // 白色背景
        .expandSafeArea([SafeAreaType.SYSTEM],[SafeAreaEdge.TOP, SafeAreaEdge.BOTTOM])  // 适配系统安全区域
        .border({
          width: {
            bottom: 1  // 底部边框宽度
          },
          color: {
            bottom: "#EEE"  // 底部边框颜色
          }
        })
        // 注释保留的调试样式
        // .backgroundColor(Color.Pink)  // 用于调试的高亮背景色


        // 步数目标设置栏
        Row() {
          // 目标文本（绿色）
          Text('步数目标')
            .fontSize(32)  // 大字号突出显示
            .fontColor(Color.Green)  // 绿色字体
            .margin({ left: 18 })  // 左侧留白

          // 输入区域
          Row() {
            // 步数目标输入框
            TextInput({ text: this.target_info.step_target.toString() })
              .type(InputType.Number)  // 限制输入类型为数字
              .fontSize(32)  // 字号32
              .fontColor(Color.Green)  // 绿色字体
              .textAlign(TextAlign.Center)  // 居中对齐
              .width('50%')  // 宽度占50%
              .height('80%')  // 高度占80%
              .onSubmit(async (enterKey: EnterKeyType, event: SubmitEvent) => {
                // 提交事件处理
                this.target_info.step_target = Number(event.text);  // 更新步数目标
                await this.data_service.target_update_data(this.target_info)  // 持久化存储
              })

            // 单位文本
            Text('步')
              .fontSize(32)  // 字号32
              .fontColor(Color.Green)  // 绿色字体
              .margin({ right: 8, left: 8 })  // 内边距
          }
          .justifyContent(FlexAlign.End)  // 右对齐
          .layoutWeight(1)  // 布局权重
        }
        .height(75)  // 固定高度75
        .width('100%')  // 宽度占满
        .backgroundColor(Color.White)  // 白色背景
        .margin({top: -20})  // 上边距-20（微调位置）

        // 睡眠目标设置栏
        Row() {
          // 目标文本（紫色）
          Text('睡眠目标')
            .fontSize(32)  // 大字号
            .fontColor('#6968d3')  // 紫色字体
            .margin({ left: 18 })  // 左侧留白

          // 时间输入区域
          Row({ space: 5 }) {
            // 小时输入
            Text(this.sleep_hours.toString())
              .fontSize(32)  // 字号32
              .width('20%')  // 宽度20%
              .textAlign(TextAlign.Center)  // 居中对齐
              .fontColor('#6968d3')  // 累色字体
              .onClick(() => {
                // 点击弹出时间选择器
                TimePickerDialog.show({
                  selected: this.sleep_time,  // 当前选中时间
                  useMilitaryTime: true,  // 使用24小时制
                  onAccept: async (value: TimePickerResult) => {
                    // 更新小时和分钟
                    this.sleep_hours = value.hour
                    this.sleep_minutes = value.minute
                    // 计算总分钟数
                    this.target_info.sleep_target = this.sleep_hours * 60 + this.sleep_minutes
                    // 持久化存储
                    await this.data_service.target_update_data(this.target_info)
                    this.sleep_time.setHours(value.hour, value.minute)  // 更新时间对象
                  }
                })
              })

            // 小时单位
            Text('h')
              .fontSize(32)  // 字号32
              .fontColor('#6968d3')  // 紫色字体

            // 分钟输入
            Text(this.sleep_minutes.toString())
              .fontSize(32)  // 字号32
              .width('20%')  // 宽度20%
              .textAlign(TextAlign.Center)  // 居中对齐
              .fontColor('#6968d3')  // 紫色字体
              .onClick(() => {
                // 点击弹出时间选择器
                TimePickerDialog.show({
                  selected: this.sleep_time,  // 当前时间
                  useMilitaryTime: true,  // 24小时制
                  onAccept: async (value: TimePickerResult) => {
                    // 更新小时和分钟
                    this.sleep_hours = value.hour
                    this.sleep_minutes = value.minute
                    // 计算总分钟
                    this.target_info.sleep_target = this.sleep_hours * 60 + this.sleep_minutes
                    // 持久化存储
                    await this.data_service.target_update_data(this.target_info)
                    // 更新时间对象
                    this.sleep_time.setHours(value.hour, value.minute)
                  }
                })
              })

            // 分钟单位
            Text('m')
              .fontSize(32)  // 字号32
              .fontColor('#6968d3')  // 紫色字体
              .margin({ right: 8 })  // 右边距
          }
          .justifyContent(FlexAlign.End)  // 右对齐
          .layoutWeight(1)  // 布局权重
        }
        .height(75)  // 固定高度75
        .width('100%')  // 宽度占满
        .backgroundColor(Color.White)  // 白色背景
        .margin({top: 10, bottom: 10})  // 上下边距


        // 饮水目标设置区域
        Row() {
          // 目标文本（钢蓝色）
          Text('饮水目标')
            .fontSize(32)  // 大字号突出显示
            .fontColor('#4682B4')  // 钢蓝色字体
            .margin({ left: 18 })  // 左侧留白

          // 目标值输入区域
          Row({ space: 5 }) {
            // 当前饮水目标显示（可点击编辑）
            Text(this.target_info.water_target.toString())
              .backgroundColor('#f3f3f3')  // 浅灰色背景
              .fontSize(32)
              .width('40%')  // 宽度占40%
              .height('80%')  // 高度占80%
              .borderRadius(15)  // 圆角边框
              .textAlign(TextAlign.Center)  // 文字居中
              .fontColor('#4682B4')  // 钢蓝色字体
              .onClick(() => {
                // 点击弹出文本选择器
                TextPickerDialog.show({
                  range: this.water_range.map(item => item.toString()),  // 转换为字符串数组
                  selected: this.water_cup,  // 当前选中杯数
                  onAccept: async (value: TextPickerResult) => {
                    // 更新杯数和饮水目标
                    this.water_cup = Number(value.value) / this.water_interval;
                    this.target_info.water_target = this.water_cup * this.water_interval
                    // 持久化存储
                    await this.data_service.target_update_data(this.target_info)
                  }
                })
              })

            // 单位文本
            Text('ml')
              .fontSize(32)
              .fontColor('#4682B4')
              .margin({ right: 8 })  // 右边距
          }
          .justifyContent(FlexAlign.End)  // 右对齐
          .layoutWeight(1)  // 布局权重
        }
        .height(75)  // 固定高度75
        .width('100%')  // 宽度占满
        .backgroundColor(Color.White)  // 白色背景

        // 分割线
        Divider()

        // 杯子容量设置区域
        Row() {
          // 标题文本（钢蓝色）
          Text('杯子容量')
            .fontSize(32)
            .fontColor('#4682B4')
            .margin({ left: 18 })

          // 容量输入区域
          Row() {
            // 输入框（数字类型）
            TextInput({ text: this.target_info.water_interval.toString() })
              .type(InputType.Number)  // 限制输入类型为数字
              .fontSize(32)
              .fontColor('#4682B4')
              .textAlign(TextAlign.Center)  // 居中对齐
              .width('40%')  // 宽度占40%
              .height('80%')  // 高度占80%
              .onSubmit(async (enterKey: EnterKeyType, event: SubmitEvent) => {
                // 提交事件处理
                this.water_interval = Number(event.text);  // 更新间隔值
                this.target_info.water_interval = Number(event.text);  // 同步到目标对象
                // 持久化存储
                await this.data_service.target_update_data(this.target_info)
                this.get_water_range()  // 重新生成选择范围
              })

            // 单位文本
            Text('ml')
              .fontSize(32)
              .fontColor('#4682B4')
              .margin({ right: 8, left: 8 })  // 左右边距
          }
          .justifyContent(FlexAlign.End)  // 右对齐
          .layoutWeight(1)  // 布局权重
        }
        .height(75)  // 固定高度75
        .width('100%')  // 宽度占满
        .backgroundColor(Color.White)  // 白色背景


        // 其他内容...
      }//column
      .height('100%')

    }//else

  }//build




  // 生成水位范围数组，从0到3500，间隔为water_interval
  get_water_range(): void {
    this.water_range = []
    for (let i = 0; i <= 3500; i += this.water_interval) {
      this.water_range.push(i)
    }
  }

  // 使用装饰器定义进度加载组件
  @Builder
  ProgressLoading() {
    Column() {
      Stack() {
        // 背景圆环（灰色）
        Circle()
          .width(80)
          .height(80)
          .fill(Color.Transparent)   // 透明填充
          .stroke('#EEE')            // 边框颜色
          .strokeWidth(8)             // 边框宽度

        // 进度圆环（蓝色）
        Shape() {
          Path()
            .width(80)
            .height(80)
            .commands(`M-40 0 A40 40 0 1 1 40 0`) // 绘制半圆路径
        }
        .stroke(Color.Blue)          // 进度条颜色
        .fill(Color.Transparent)     // 无填充
        .strokeWidth(8)               // 进度条宽度
        .strokeLineCap(LineCapStyle.Round) // 圆角端点
        .rotate({
          angle: this.loadingProgress * 3.6 - 90, // 旋转角度计算（百分比转角度）
          centerX: '50%',            // 旋转中心X
          centerY: '50%'             // 旋转中心Y
        })
      }

      // 进度百分比文本
      Text(`${Math.floor(this.loadingProgress)}%`)
        .fontSize(20)                 // 字体大小
        .margin({ top: 16 })          // 顶部边距
    }
    .onAppear(() => {
      // 组件出现时启动动画
      animateTo({ duration: 1000 }, () => {
        this.loadingProgress = 100    // 动画持续1秒，进度到100%
      })
    })
  }

}