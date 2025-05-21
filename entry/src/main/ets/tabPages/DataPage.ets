// 导入依赖模块
import { DataService } from "../data_base/data_base";  // 数据库服务
import { AppStorageV2 } from "@kit.ArkUI";  // 状态管理
import { StepClass } from "../entity/step_class";  // 步数数据模型
import { WaterClass } from "../entity/water_class";  // 饮水数据模型
import { SleepClass } from "../entity/sleep_class";  // 睡眠数据模型
import { TargetClass } from "../entity/target_class";  // 目标数据模型
import { notificationManager } from "@kit.NotificationKit";  // 通知管理
import { BusinessError } from "@kit.BasicServicesKit";  // 错误类型
import { hilog } from "@kit.PerformanceAnalysisKit";  // 日志工具

/**
 * 自定义UI样式扩展
 * @description 定义统一的UI组件样式
 */
// 数据行样式：固定高度和宽度
@Extend(Row) function dataRowStyle() {
  .height(75)
  .width('100%')
  .backgroundColor(Color.White)
}

// 标题文本样式：指定字体大小和颜色
@Extend(Text) function titleStyle(color: string) {
  .fontSize(32)
  .fontColor(color)
  .margin({ left: 18 })
}

// 数值文本样式：指定字体大小、颜色和对齐方式
@Extend(Text) function valueTextStyle(color: string, width: string = '30%') {
  .fontSize(32)
  .fontColor(color)
  .textAlign(TextAlign.Center)
  .width(width)
}

// 输入框样式：数字输入框样式定义
@Extend(TextInput) function valueInputStyle(color: string, width: string = '45%') {
  .type(InputType.Number)  // 限制输入类型为数字
  .fontSize(32)
  .fontColor(color)
  .textAlign(TextAlign.Center)
  .width(width)
  .height('80%')  // 输入框高度占父容器的80%
}

// 单位文本样式：带边距的单位文本样式
@Extend(Text) function unitTextStyle(color: string) {
  .fontSize(32)
  .fontColor(color)
  .margin({ right: 8, left: 8 })  // 左右边距
}

@Entry
@Component
export struct Data_page {
  // UI状态管理
  @State loadingProgress: number = 0  // 加载进度百分比
  @State isLoading: boolean = true    // 是否处于加载状态
  @State message: string = 'Hello World';  // 测试文本
  @State today: string = new Date().toISOString().split('T')[0];  // 当前日期（ISO格式）
  @State today_chinese: string = ''  // 中文格式日期（未使用）

  // 数据绑定：步数、睡眠、饮水信息
  @StorageLink('step_info') step_info: StepClass = new StepClass()
  @StorageLink('sleep_info') sleep_info: SleepClass = new SleepClass()
  @StorageLink('sleep_hours') sleep_hours: number = 0
  @StorageLink('sleep_minutes') sleep_minutes: number = 0;

  // 深度睡眠数据
  @State deep_sleep_hours: number = 0
  @State deep_sleep_minutes: number = 0

  // 浅度睡眠数据
  @State light_sleep_hours: number = 0
  @State light_sleep_minutes: number = 0

  // REM睡眠数据
  @State rem_sleep_hours: number = 0
  @State rem_sleep_minutes: number = 0

  @State sleep_time: Date = new Date()  // 睡眠时间（未使用）

  // 饮水相关状态
  @StorageLink('water_info') water_info: WaterClass = new WaterClass()
  @StorageLink('water_range') water_range: number[] = []  // 饮水区间数据
  @State water_cup: number = -1  // 当前饮水杯数
  @StorageLink('water_interval') water_interval: number = 500  // 每杯容量

  // 目标信息和通知状态
  @StorageLink('target_info') target_info:TargetClass=new TargetClass()
  @StorageLink('show_notify') show_notify: boolean[] = [false, false, false]  // 通知状态数组

  // 获取上下文和数据库实例
  context: Context = getContext(this) as Context
  data_service: DataService = AppStorageV2.connect(DataService, "data_service",
    () => new DataService(this.context))!

  /**
   * 生命周期方法 - 组件即将显示
   * @description 初始化数据和状态
   */
  async aboutToAppear() {
    this.isLoading = true  // 开始加载

    // 异步加载各模块数据
    this.step_info = await this.data_service.step_query_data(this.today)
    this.sleep_info = await this.data_service.sleep_query_data(this.today)
    this.water_info = await this.data_service.water_query_data(this.today)
    this.target_info = await this.data_service.target_query_data()

    // 初始化数据检查（若无数据则插入默认数据）
    if (this.step_info.date === 'default') {
      console.info(`[步数数据] step原来没有数据，插入默认数据`)
      await this.data_service.step_insert_data(this.today)
      this.step_info = await this.data_service.step_query_data(this.today)
    }

    if (this.sleep_info.date === 'default') {
      console.info(`[test] 原来没有数据，插入默认数据`)
      await this.data_service.sleep_insert_data(this.today)
      this.sleep_info = await this.data_service.sleep_query_data(this.today)
    }

    if (this.water_info.date === 'default') {
      console.info(`[test] 原来没有数据，插入默认数据`)
      await this.data_service.water_insert_data(this.today)
      this.water_info = await this.data_service.water_query_data(this.today)
    }

    // 输出初始化日志
    console.info(`[start]today=${this.today}`)
    console.info(`[start]step_info=${JSON.stringify(this.step_info)}`)
    console.info(`[start]sleep_info=${JSON.stringify(this.sleep_info)}`)
    console.info(`[start]water_info=${JSON.stringify(this.water_info)}`)

    // 把日期处理为中文格式（当前未使用）
    this.produce_ymd()

    // 睡眠数据转换
    this.sleep_hours = Math.floor(this.sleep_info.sleep / 60)  // 总睡眠小时
    this.sleep_minutes = this.sleep_info.sleep % 60  // 总睡眠分钟

    // 各睡眠阶段转换
    this.deep_sleep_hours = Math.floor(this.sleep_info.deep / 60)  // 深度睡眠小时
    this.deep_sleep_minutes = this.sleep_info.deep % 60  // 深度睡眠分钟
    this.light_sleep_hours = Math.floor(this.sleep_info.light / 60)  // 浅度睡眠小时
    this.light_sleep_minutes = this.sleep_info.light % 60  // 浅度睡眠分钟
    this.rem_sleep_hours = Math.floor(this.sleep_info.rem / 60)  // REM睡眠小时
    this.rem_sleep_minutes = this.sleep_info.rem % 60  // REM睡眠分钟

    // 饮水数据转换
    this.water_interval = this.target_info.water_interval  // 获取饮水目标间隔
    this.get_water_range()  // 获取饮水范围
    this.water_cup = Math.floor(this.water_info.water / this.water_interval)  // 计算当前杯数

    this.isLoading = false  // 加载完成
  }


  build() {
    if (this.isLoading) {
      this.ProgressLoading() // 显示加载动画
    }
    else {

      Scroll() {
        Column({ space: 12 }) {

          //显示日期
          Text(this.today_chinese)
            .titleStyle('Color.Black')
            .width('100%')
            .height(50)


          // 步数相关数据编辑区域
          Column() {
            // 修改步数部分
            Row() {
              // 标题文本（绿色）
              Text('步数')
                .titleStyle('#008800')  // 使用预定义标题样式

              // 输入区域
              Row() {
                // 步数输入框
                TextInput({ text: this.step_info.step.toString() })
                  .valueInputStyle('#008800', '45%')  // 输入框样式
                  .onSubmit(async (enterKey: EnterKeyType, event: SubmitEvent) => {
                    // 提交事件处理
                    this.step_info.step = Number(event.text);  // 更新步数
                    await this.data_service.step_update_data(this.today, this.step_info);  // 持久化存储

                    // 达标判断逻辑
                    if (this.step_info.step >= this.target_info.step_target) {
                      if(!this.show_notify[0]){
                        this.step_show_notify()  // 触发通知
                        this.show_notify[0]=true  // 标记已通知
                      }
                    }
                  })

                // 单位文本
                Text('步')
                  .unitTextStyle('#008800')  // 使用预定义单位样式
              }
              .justifyContent(FlexAlign.End)  // 右对齐
              .layoutWeight(1)  // 布局权重
            }
            .dataRowStyle()  // 应用数据行样式

            // 修改距离部分
            Row() {
              // 标题文本（蓝色）
              Text('距离')
                .titleStyle('#2196F3')  // 使用标题样式

              // 距离输入区域
              Row({ space: 5 }) {
                // 整数部分输入框
                TextInput({ text: Math.floor(this.step_info.distance).toString() })
                  .valueInputStyle('#2196F3', '20%')  // 输入框样式
                  .onSubmit(async (enterKey: EnterKeyType, event: SubmitEvent) => {
                    // 更新整数部分
                    this.step_info.distance = Number(event.text) + this.step_info.distance % 1;
                    await this.data_service.step_update_data(this.today, this.step_info);
                  })

                // 小数点符号
                Text('.')
                  .fontSize(32)
                  .fontColor('#2196F3')

                // 小数部分输入框
                TextInput({ text: (this.step_info.distance % 1).toFixed(2).substring(2) })
                  .valueInputStyle('#2196F3', '30%')  // 输入框样式
                  .onSubmit(async (enterKey: EnterKeyType, event: SubmitEvent) => {
                    // 更新小数部分
                    this.step_info.distance = Math.floor(this.step_info.distance) + Number('0.' + event.text);
                    await this.data_service.step_update_data(this.today, this.step_info);
                  })

                // 单位文本
                Text('km')
                  .unitTextStyle('#2196F3')  // 使用单位样式
              }
              .justifyContent(FlexAlign.End)  // 右对齐
              .layoutWeight(1)  // 布局权重
            }
            .dataRowStyle()  // 应用数据行样式

            // 修改卡路里部分
            Row() {
              // 标题文本（橙色）
              Text('卡路里')
                .titleStyle('#FF5722')  // 使用标题样式

              // 卡路里输入区域
              Row() {
                // 卡路里输入框
                TextInput({ text: this.step_info.calorie.toString() })
                  .valueInputStyle('#FF5722', '45%')  // 输入框样式
                  .onSubmit(async (enterKey: EnterKeyType, event: SubmitEvent) => {
                    // 提交事件处理
                    this.step_info.calorie = Number(event.text);  // 更新卡路里值
                    await this.data_service.step_update_data(this.today, this.step_info);  // 持久化存储
                  })

                // 单位文本
                Text('kcal')
                  .unitTextStyle('#FF5722')  // 使用单位样式
              }
              .justifyContent(FlexAlign.End)  // 右对齐
              .layoutWeight(1)  // 布局权重
            }
            .dataRowStyle()  // 应用数据行样式
          } //column步数组


          // 睡眠相关数据编辑区域
          Column() {
            // 修改总睡眠时间部分
            Row() {
              // 标题文本（紫色）
              Text('睡眠')
                .titleStyle('#6968d3')  // 使用预定义标题样式

              // 时间输入区域
              Row({ space: 5 }) {
                // 小时输入
                Text(this.sleep_hours.toString())
                  .valueTextStyle('#6968d3','20%')  // 输入框样式
                  .onClick(() => {
                    // 点击弹出时间选择器
                    TimePickerDialog.show({
                      selected: this.sleep_time,  // 当前选中时间
                      useMilitaryTime: true,  // 使用24小时制
                      onAccept: async (value: TimePickerResult) => {
                        // 更新小时和分钟
                        this.sleep_hours = value.hour
                        this.sleep_minutes = value.minute
                        // 计算总睡眠分钟数
                        this.sleep_info.sleep = this.sleep_hours * 60 + this.sleep_minutes
                        // 持久化存储
                        await this.data_service.sleep_update_data(this.today, this.sleep_info)
                        // 更新时间对象
                        this.sleep_time.setHours(value.hour, value.minute)

                        // 达标判断逻辑
                        if (this.sleep_info.sleep >= this.target_info.sleep_target) {
                          if(!this.show_notify[1]){
                            this.sleep_show_notify()  // 触发通知
                            this.show_notify[1]=true  // 标记已通知
                          }
                        }

                        //如果深睡、浅睡、REM都为0，就置为3：5：2
                        if(this.sleep_info.deep==0&&this.sleep_info.light==0&&this.sleep_info.rem==0){
                          this.sleep_info.deep=Math.floor (0.3*this.sleep_info.sleep)
                          this.sleep_info.light=Math.floor (0.5*this.sleep_info.sleep)
                          this.sleep_info.rem=Math.floor(0.2*this.sleep_info.sleep)
                          this.deep_sleep_hours=Math.floor(this.sleep_info.deep/60)
                          this.light_sleep_hours=Math.floor(this.sleep_info.light/60)
                          this.rem_sleep_hours=Math.floor(this.sleep_info.rem/60)
                          this.deep_sleep_minutes=this.sleep_info.deep%60
                          this.light_sleep_minutes=this.sleep_info.light%60
                          this.rem_sleep_minutes=this.sleep_info.rem%60
                          await this.data_service.sleep_update_data(this.today, this.sleep_info)
                        }

                      }
                    })
                  })

                // 小时单位
                Text('h')
                  .fontSize(32)
                  .fontColor('#6968d3')

                // 分钟输入
                Text(this.sleep_minutes.toString())
                  .valueTextStyle('#6968d3','20%')  // 输入框样式
                  .onClick(() => {
                    // 点击弹出时间选择器（与上面逻辑相同）
                    TimePickerDialog.show({
                      selected: this.sleep_time,
                      useMilitaryTime: true,
                      onAccept: async (value: TimePickerResult) => {
                        this.sleep_hours = value.hour
                        this.sleep_minutes = value.minute
                        this.sleep_info.sleep = value.hour * 60 + value.minute
                        await this.data_service.sleep_update_data(this.today, this.sleep_info)
                        this.sleep_time.setHours(value.hour, value.minute)
                      }
                    })
                  })

                // 分钟单位
                Text('m')
                  .fontSize(32)
                  .fontColor('#6968d3')
                  .margin({ right: 8 })  // 右边距
              }
              .justifyContent(FlexAlign.End)  // 右对齐
              .layoutWeight(1)  // 布局权重
            }
            .dataRowStyle()  // 应用数据行样式

            // 深度睡眠时间修改部分
            Row() {
              // 标题文本（深蓝色）
              Text('深睡')
                .titleStyle('#1976D2')  // 使用标题样式

              // 深度睡眠时间输入区域
              Row({ space: 5 }) {
                // 小时输入
                Text(this.deep_sleep_hours.toString())
                  .valueTextStyle('#1976D2','20%')  // 输入框样式
                  .onClick(() => {
                    // 点击事件处理
                    TimePickerDialog.show({
                      selected: this.sleep_time,  // 当前选中时间
                      useMilitaryTime: true,  // 24小时制
                      onAccept: async (value: TimePickerResult) => {
                        // 更新深度睡眠小时
                        this.deep_sleep_hours = value.hour
                        // 更新深度睡眠分钟
                        this.deep_sleep_minutes = value.minute
                        // 计算深度睡眠总分钟
                        this.sleep_info.deep = value.hour * 60 + value.minute
                        // 持久化存储
                        await this.data_service.sleep_update_data(this.today, this.sleep_info)
                        // 更新时间对象
                        this.sleep_time.setHours(value.hour, value.minute)
                      }
                    })
                  })

                // 小时单位
                Text('h')
                  .fontSize(32)
                  .fontColor('#1976D2')

                // 分钟输入
                Text(this.deep_sleep_minutes.toString())
                  .valueTextStyle('#1976D2','20%')  // 输入框样式
                  .onClick(() => {
                    TimePickerDialog.show({
                      selected: this.sleep_time,
                      useMilitaryTime: true,
                      onAccept: async (value: TimePickerResult) => {
                        // 更新深度睡眠小时
                        this.deep_sleep_hours = value.hour
                        // 更新深度睡眠分钟
                        this.deep_sleep_minutes = value.minute
                        // 计算总分钟
                        this.sleep_info.deep = value.hour * 60 + value.minute
                        // 持久化存储
                        await this.data_service.sleep_update_data(this.today, this.sleep_info)
                        // 更新时间对象
                        this.sleep_time.setHours(value.hour, value.minute)
                      }
                    })
                  })

                // 分钟单位
                Text('m')
                  .fontSize(32)
                  .fontColor('#1976D2')
                  .margin({ right: 8 })  // 右边距
              }
              .justifyContent(FlexAlign.End)  // 右对齐
              .layoutWeight(1)  // 布局权重
            }
            .dataRowStyle()  // 应用数据行样式

            // 浅度睡眠时间修改部分
            Row() {
              // 标题文本（浅蓝色）
              Text('浅睡')
                .titleStyle('#64B5F6')  // 使用标题样式

              // 浅度睡眠时间输入区域
              Row({ space: 5 }) {
                // 小时输入
                Text(this.light_sleep_hours.toString())
                  .valueTextStyle('#64B5F6','20%')  // 输入框样式
                  .onClick(() => {
                    TimePickerDialog.show({
                      selected: this.sleep_time,
                      useMilitaryTime: true,
                      onAccept: async (value: TimePickerResult) => {
                        // 更新浅度睡眠小时
                        this.light_sleep_hours = value.hour
                        // 更新浅度睡眠分钟
                        this.light_sleep_minutes = value.minute
                        // 计算总分钟
                        this.sleep_info.light = value.hour * 60 + value.minute
                        // 持久化存储
                        await this.data_service.sleep_update_data(this.today, this.sleep_info)
                        // 更新时间对象
                        this.sleep_time.setHours(value.hour, value.minute)
                      }
                    })
                  })

                // 小时单位
                Text('h')
                  .fontSize(32)
                  .fontColor('#64B5F6')

                // 分钟输入
                Text(this.light_sleep_minutes.toString())
                  .valueTextStyle('#64B5F6','20%')  // 输入框样式
                  .onClick(() => {
                    TimePickerDialog.show({
                      selected: this.sleep_time,
                      useMilitaryTime: true,
                      onAccept: async (value: TimePickerResult) => {
                        // 更新浅度睡眠小时
                        this.light_sleep_hours = value.hour
                        // 更新浅度睡眠分钟
                        this.light_sleep_minutes = value.minute
                        // 计算总分钟
                        this.sleep_info.light = value.hour * 60 + value.minute
                        // 持久化存储
                        await this.data_service.sleep_update_data(this.today, this.sleep_info)
                        // 更新时间对象
                        this.sleep_time.setHours(value.hour, value.minute)
                      }
                    })
                  })

                // 分钟单位
                Text('m')
                  .fontSize(32)
                  .fontColor('#64B5F6')
                  .margin({ right: 8 })  // 右边距
              }
              .justifyContent(FlexAlign.End)  // 右对齐
              .layoutWeight(1)  // 布局权重
            }
            .dataRowStyle()  // 应用数据行样式

            // REM睡眠时间修改部分
            Row() {
              // 标题文本（橙色）
              Text('REM')
                .titleStyle('#ffaf3b')  // 使用标题样式

              // REM睡眠时间输入区域
              Row({ space: 5 }) {
                // 小时输入
                Text(this.rem_sleep_hours.toString())
                  .valueTextStyle('#ffaf3b','20%')  // 输入框样式
                  .onClick(() => {
                    TimePickerDialog.show({
                      selected: this.sleep_time,
                      useMilitaryTime: true,
                      onAccept: async (value: TimePickerResult) => {
                        // 更新REM小时
                        this.rem_sleep_hours = value.hour
                        // 更新REM分钟
                        this.rem_sleep_minutes = value.minute
                        // 计算总分钟
                        this.sleep_info.rem = value.hour * 60 + value.minute
                        // 持久化存储
                        await this.data_service.sleep_update_data(this.today, this.sleep_info)
                        // 更新时间对象
                        this.sleep_time.setHours(value.hour, value.minute)
                      }
                    })
                  })

                // 小时单位
                Text('h')
                  .fontSize(32)
                  .fontColor('#ffaf3b')

                // 分钟输入
                Text(this.rem_sleep_minutes.toString())
                  .valueTextStyle('#ffaf3b','20%')  // 输入框样式
                  .onClick(() => {
                    TimePickerDialog.show({
                      selected: this.sleep_time,
                      useMilitaryTime: true,
                      onAccept: async (value: TimePickerResult) => {
                        // 更新REM小时
                        this.rem_sleep_hours = value.hour
                        // 更新REM分钟
                        this.rem_sleep_minutes = value.minute
                        // 计算总分钟
                        this.sleep_info.rem = value.hour * 60 + value.minute
                        // 持久化存储
                        await this.data_service.sleep_update_data(this.today, this.sleep_info)
                        // 更新时间对象
                        this.sleep_time.setHours(value.hour, value.minute)
                      }
                    })
                  })

                // 分钟单位
                Text('m')
                  .fontSize(32)
                  .fontColor('#ffaf3b')
                  .margin({ right: 8 })  // 右边距
              }
              .justifyContent(FlexAlign.End)  // 右对齐
              .layoutWeight(1)  // 布局权重
            }
            .dataRowStyle()  // 应用数据行样式
          } //column睡眠组


          // 修改饮水设置区域
          Row() {
            // 标题文本（钢蓝色）
            Text('饮水')
              .titleStyle('#4682B4')  // 使用预定义标题样式

            // 饮水操作区域
            Row({ space: 5 }) {
              // 减少饮水量按钮
              Button('-')
                .width(70)
                .height(70)
                .fontSize(54)
                .fontWeight(700)
                .fontColor('#2f5676')  // 深蓝色字体
                .backgroundColor(Color.White)  // 白色背景
                .onClick(async () => {
                  // 点击时减少一杯饮水量（最小为0）
                  this.water_cup = Math.max(this.water_cup - 1, 0)
                  // 计算总毫升数
                  this.water_info.water = this.water_cup * this.water_interval
                  // 更新数据库
                  await this.data_service.water_update_data(this.today, this.water_info)
                })

              // 当前饮水量显示（可点击编辑）
              Text((this.water_info.water).toString())
                .backgroundColor('#f3f3f3')  // 浅灰色背景
                .valueTextStyle('#4682B4','30%')  // 使用预定义文本样式
                .height('80%')  // 高度占父容器80%
                .borderRadius(15)  // 圆角边框
                .onClick(() => {
                  // 点击弹出文本选择器
                  TextPickerDialog.show({
                    range: this.water_range.map(item => item.toString()),  // 显示范围（已转换为字符串）
                    selected: this.water_cup,  // 当前选中值
                    onAccept: async (value: TextPickerResult) => {
                      // 更新饮水杯数
                      this.water_cup = Number(value.value) / this.water_interval;
                      // 计算总毫升数
                      this.water_info.water = this.water_cup * this.water_interval
                      // 持久化存储
                      await this.data_service.water_update_data(this.today, this.water_info)

                      // 达标检测逻辑
                      if(this.water_info.water >= this.target_info.water_target){
                        if(!this.show_notify[2]){
                          this.water_show_notify()  // 触发通知
                          this.show_notify[2] = true  // 标记已通知
                        }
                      }
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
          .dataRowStyle()  // 应用数据行样式
          .onClick(async () => {
            // 整行点击增加饮水量
            this.water_cup = Math.min(
              this.water_cup + 1,
              Math.floor(3500 / this.water_interval)  // 最大值限制（3500ml）
            )
            // 计算总毫升数
            this.water_info.water = this.water_cup * this.water_interval
            // 持久化存储
            await this.data_service.water_update_data(this.today, this.water_info)

            // 达标检测逻辑
            if(this.water_info.water >= this.target_info.water_target){
              if(!this.show_notify[2]){
                this.water_show_notify()  // 触发通知
                this.show_notify[2] = true  // 标记已通知
              }
            }
          })

        }
        .width('100%')
        // .height('100%')
      }
      .scrollBar(BarState.Off) // 隐藏滚动条
      .height('100%')
      .width('100%')
    }
  }

  /**
   * 加载进度动画构建器
   * @description 显示环形加载动画并显示进度百分比
   */
  @Builder
  ProgressLoading() {
    Column() {
      Stack() {
        // 背景灰色圆环（固定100%）
        Circle()
          .width(80)
          .height(80)
          .fill(Color.Transparent)  // 透明填充
          .stroke('#EEE')  // 灰色描边
          .strokeWidth(8)  // 描边宽度

        // 动态蓝色进度环
        Shape() {
          Path()
            .width(80)
            .height(80)
              // SVG路径命令：从(-40,0)开始绘制半径40的圆
              // M-40 0 = 移动到起始点(-40,0)
              // A40 40 = 画圆（X/Y半径都是40）
              // 0 1 1 = 大弧标志（1）和顺时针方向（1）
              // 40 0 = 结束点坐标(40,0)
            .commands(`M-40 0 A40 40 0 1 1 40 0`)
        }
        .stroke(Color.Blue)  // 蓝色描边
        .fill(Color.Transparent)  // 透明填充
        .strokeWidth(8)  // 描边宽度
        .strokeLineCap(LineCapStyle.Round)  // 圆角端点样式
        // 旋转动画实现
        .rotate({
          // 角度计算：3.6=360°/100%，-90°偏移使0%从顶部开始
          angle: this.loadingProgress * 3.6 - 90,
          centerX: '50%',  // 旋转中心X
          centerY: '50%'   // 旋转中心Y
        })
      }

      // 进度百分比显示
      Text(`${Math.floor(this.loadingProgress)}%`)
        .fontSize(20)  // 字号20
        .margin({ top: 16 })  // 上边距16
    }
    // 组件显示时启动动画
    .onAppear(() => {
      // 启动1秒动画达到100%进度
      animateTo({ duration: 1000 }, () => this.loadingProgress = 100)
    })
  }

  /**
   * 日期格式转换函数
   * @description 将ISO格式日期转换为中文日期格式
   * @example "2023-04-05" → "2023年4月5日"
   */
  produce_ymd(): void {
    // 提取年份（前4位）
    const yearPart = this.today.slice(0, 4);

    // 提取并处理月份（第5-7位）
    const month = this.today.slice(5, 7);
    // 去除前导0（如04→4）
    const monthPart = month.startsWith('0') ? month[1] : month;

    // 提取并处理日期（第8-10位）
    const day = this.today.slice(8, 10);
    // 去除前导0（如05→5）
    const dayPart = day.startsWith('0') ? day[1] : day;

    // 拼接中文日期格式
    this.today_chinese = yearPart + '年' + monthPart + '月' + dayPart + '日'
  }

  /**
   * 生成饮水量选择范围
   * @description 根据间隔生成0-3500ml的饮水量选项
   * @example 当water_interval=500时，生成[0,500,1000,...,3500]
   */
  get_water_range(): void {
    // 生成0-3500范围的饮水量选项
    for (let i = 0; i <= 3500; i += this.water_interval) {
      // 将数值转换为字符串添加到water_range数组
      this.water_range.push(i)
    }
  }
  /**
   * 步数达标通知方法
   * @description 创建并发送步数目标达成系统通知
   */
  step_show_notify(){
    // 创建通知请求对象
    let notificationRequest: notificationManager.NotificationRequest = {
      id: 1,  // 通知ID（唯一标识）
      // 通知槽位类型（服务信息类）
      notificationSlotType: notificationManager.SlotType.SERVICE_INFORMATION,
      content: {
        // 通知内容类型（基础文本类型）
        notificationContentType: notificationManager.ContentType.NOTIFICATION_CONTENT_BASIC_TEXT,
        normal: {
          title: '步数',  // 通知标题
          // 通知正文（包含具体目标值）
          text: '今日步数：' + this.target_info.step_target + '步 已达标！'
        }
      }
    };

    // 发布通知
    notificationManager.publish(notificationRequest, (err: BusinessError) => {
      if (err) {
        // 错误日志记录（包含错误码和消息）
        hilog.error(0, '0',
          `Failed to publish notification. Code is ${err.code}, message is ${err.message}`);
        return;
      }
      // 成功日志记录
      hilog.info(1, '1', 'Succeeded in publishing notification.');
    });
  }

  /**
   * 睡眠目标达标通知方法
   * @description 创建并发送睡眠目标达成系统通知
   */
  sleep_show_notify(){
    let notificationRequest: notificationManager.NotificationRequest = {
      id: 2,  // 通知ID（唯一标识）
      notificationSlotType: notificationManager.SlotType.SERVICE_INFORMATION,
      content: {
        notificationContentType: notificationManager.ContentType.NOTIFICATION_CONTENT_BASIC_TEXT,
        normal: {
          title: '睡眠',  // 通知标题
          // 通知正文（包含格式化后的小时/分钟）
          text: '今日睡眠：' +
          Math.floor(this.target_info.sleep_target/60) + 'h' +
            this.target_info.sleep_target%60 + 'm' +
            ' 已达标！'
        }
      }
    };

    notificationManager.publish(notificationRequest, (err: BusinessError) => {
      if (err) {
        hilog.error(0, '0',
          `Failed to publish notification. Code is ${err.code}, message is ${err.message}`);
        return;
      }
      hilog.info(1, '1', 'Succeeded in publishing notification.');
    });
  }

  /**
   * 饮水目标达标通知方法
   * @description 创建并发送饮水目标达成系统通知
   */
  water_show_notify(){
    let notificationRequest: notificationManager.NotificationRequest = {
      id: 3,  // 通知ID（唯一标识）
      notificationSlotType: notificationManager.SlotType.SERVICE_INFORMATION,
      content: {
        notificationContentType: notificationManager.ContentType.NOTIFICATION_CONTENT_BASIC_TEXT,
        normal: {
          title: '饮水',  // 通知标题
          // 通知正文（包含具体目标值）
          text: '今日饮水量：' +
          this.target_info.water_target +
            'ml 已达标！'
        }
      }
    };

    notificationManager.publish(notificationRequest, (err: BusinessError) => {
      if (err) {
        hilog.error(0, '0',
          `Failed to publish notification. Code is ${err.code}, message is ${err.message}`);
        return;
      }
      hilog.info(1, '1', 'Succeeded in publishing notification.');
    });
  }
}
