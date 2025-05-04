// 导入依赖模块和类
import { DataService } from "../data_base/data_base";  // 数据库服务
import { AppStorageV2, router } from "@kit.ArkUI";  // 状态管理和路由
import { StepClass } from "../entity/step_class";  // 步数数据模型
import { SleepClass } from "../entity/sleep_class";  // 睡眠数据模型
import { WaterClass } from "../entity/water_class";  // 饮水数据模型
import { TargetClass } from "../entity/target_class";  // 目标数据模型
import { hilog } from "@kit.PerformanceAnalysisKit";  // 日志工具
import { notificationManager } from "@kit.NotificationKit";  // 通知管理
import { BusinessError } from "@kit.BasicServicesKit";  // 错误类型

// 新增类型声明：交互反馈动画配置
interface FeedbackConfig {
  pressScale: number;  // 按下时缩放比例
  duration: number;    // 动画持续时间
}

@Entry
@Component
export struct Health {
  // UI状态管理
  @State loadingProgress: number = 0;  // 加载进度百分比
  @State isLoading: boolean = true;    // 是否处于加载状态
  @State message: string = 'Hello World';  // 测试文本
  @State private isPressed1: boolean = false;  // 步数卡片按压状态
  @State private isPressed2: boolean = false;  // 睡眠卡片按压状态
  @State private isPressed3: boolean = false;  // 饮水卡片按压状态

  // 交互反馈动画配置参数
  private feedbackConfig: FeedbackConfig = {
    pressScale: 0.98,     // 按下时缩放比例
    duration: 100         // 动画时长
  }

  // 获取上下文和数据库实例
  context: Context = getContext(this) as Context;
  data_service: DataService = AppStorageV2.connect(DataService, "data_service",
    () => new DataService(this.context))!;

  // 当前日期（ISO格式）
  @State today: string = new Date().toISOString().split('T')[0];

  // 数据绑定：步数、睡眠、饮水信息
  @StorageLink('step_info') @Watch('onDataChange') step_info: StepClass = new StepClass();
  @StorageLink('sleep_info') @Watch('onDataChange') sleep_info: SleepClass = new SleepClass();
  @StorageLink('sleep_hours') @Watch('onDataChange') sleep_hours: number = 0;
  @StorageLink('sleep_minutes') @Watch('onDataChange') sleep_minutes: number = 0;
  @StorageLink('water_info') @Watch('onDataChange') water_info: WaterClass = new WaterClass();
  @StorageLink('water_cup') water_cup: number = -1;
  @State water_interval: number = 500;  // 饮水杯容量
  @StorageLink('target_info') @Watch('onDataChange') target_info: TargetClass = new TargetClass();

  // 动画进度值
  @State animatedStepProgress: number = 0;   // 步数动画进度
  @State animatedSleepProgress: number = 0;  // 睡眠动画进度
  @State animatedWaterProgress: number = 0;  // 饮水动画进度

  // 标签页状态
  @StorageLink('activeTabIndex') @Watch('onTabChange') activeTabIndex: number = 0;
  @State dataChanged: boolean = false;  // 数据变更标志

  // 通知状态数组：[步数通知, 睡眠通知, 饮水通知]
  @StorageLink('show_notify') show_notify: boolean[] = [false, false, false];

  // 公共样式：固定宽高100
  @Styles w_100_h_100() {
    .width(100)
    .height(100)
  }

  // 数据变更监听器
  onDataChange(propertyName: string): void {
    console.info(`[test123] ${propertyName} onDataChange `);
    this.judge_reach_target();  // 检查目标达成情况
    this.dataChanged = true;    // 标记数据已变更
  }

  // 标签页变更监听器
  onTabChange(propertyName: string): void {
    console.info(`[test123] ${propertyName} onTabChange   ${this.activeTabIndex} `);
    if (!this.isLoading && this.dataChanged && this.activeTabIndex === 0) {
      this.startAnimation();  // 重新启动动画
      this.dataChanged = false;  // 重置变更标志
    }
  }

  // 组件即将显示时执行
  async aboutToAppear(): Promise<void> {
    console.info(`[test123] aboutToAppear`);
    this.isLoading = true;  // 开始加载

    // 异步加载各模块数据
    this.step_info = await this.data_service.step_query_data(this.today);
    this.sleep_info = await this.data_service.sleep_query_data(this.today);
    this.water_info = await this.data_service.water_query_data(this.today);
    this.target_info = await this.data_service.target_query_data();

    // 初始化数据检查（若无数据则插入默认数据）
    if (this.step_info.date === 'default') {
      await this.data_service.step_insert_data(this.today);
      this.step_info = await this.data_service.step_query_data(this.today);
    }
    if (this.sleep_info.date === 'default') {
      await this.data_service.sleep_insert_data(this.today);
      this.sleep_info = await this.data_service.sleep_query_data(this.today);
    }
    if (this.water_info.date === 'default') {
      await this.data_service.water_insert_data(this.today);
      this.water_info = await this.data_service.water_query_data(this.today);
    }

    // 睡眠数据格式转换
    this.sleep_hours = Math.floor(this.sleep_info.sleep / 60);
    this.sleep_minutes = this.sleep_info.sleep % 60;

    // 饮水杯数计算
    this.water_cup = Math.floor(this.water_info.water / this.water_interval);

    this.isLoading = false;  // 加载完成
    this.startAnimation();   // 启动动画
  }



  build() {
    if (this.isLoading) {
      this.ProgressLoading() // 显示加载动画
    }
    else{

      Scroll() {
      Column({ space: 20 }) {

        // 第一片区域 - 环形进度展示区
        Row() {
          // 步数进度环
          Column({ space: 8 }) {  // 垂直排列进度环和文本
            Stack() {  // 叠加背景环和进度环
              // 背景灰环（固定显示100%）
              Progress({
                value: 100,
                type: ProgressType.Ring,
              })
                .style({ strokeWidth: 10 })  // 环的宽度
                .w_100_h_100()  // 自定义样式：宽高100
                .color('#E0E0E0')  // 灰色背景

              // 动态绿色进度环（绑定动画值）
              Progress({
                value: this.animatedStepProgress,  // 绑定动画进度值
                type: ProgressType.Ring,
              })
                .style({ strokeWidth: 10 })
                .w_100_h_100()
                .color('#4CAF50')  // 绿色进度

              // 中心文本显示
              Column({ space: 4 }) {
                Text(`${Math.min(100,
                  this.step_info.step > 0 && this.target_info.step_target > 0 ?
                  Math.round((this.step_info.step / this.target_info.step_target) * 100) : 0)}%`)
                  .fontSize(16)
                  .fontWeight(FontWeight.Bold)
                  .fontColor('#4CAF50')
              }
            }

            Text('步数')  // 标题文本
              .fontSize(16)
              .fontColor('#4CAF50')
              .fontWeight(FontWeight.Bold)

            // 具体数值显示（当前值/目标值）
            Text(`${this.step_info.step}/${this.target_info.step_target}`)
              .fontSize(14)
              .fontColor('#666')  // 灰色字体
          }
          .layoutWeight(1)  // 均分水平空间
          .onClick(() => onJumpClick_step())  // 点击跳转步数报表

          // 睡眠进度环（结构同上）
          Column({ space: 8 }) {
            Stack() {
              // 背景环（灰色）
              Progress({
                value: 100,
                type: ProgressType.Ring,
              })
                .style({ strokeWidth: 10 })
                .w_100_h_100()
                .color('#E0E0E0')

              // 动态紫色进度环
              Progress({
                value: this.animatedSleepProgress,
                type: ProgressType.Ring,
              })
                .style({ strokeWidth: 10 })
                .w_100_h_100()
                .color('#6968d3')

              // 百分比文本计算
              Column({ space: 4 }) {
                Text(`${Math.min(100,
                  this.sleep_info.sleep > 0 && this.target_info.sleep_target > 0 ?
                  Math.round((this.sleep_info.sleep / this.target_info.sleep_target) * 100) : 0)}%`)
                  .fontSize(16)
                  .fontWeight(FontWeight.Bold)
                  .fontColor('#6968d3')
              }
            }

            Text('睡眠')  // 标题
              .fontSize(16)
              .fontColor('#6968d3')
              .fontWeight(FontWeight.Bold)

            // 时间格式转换（分钟→小时+分钟）
            Text(`${Math.floor(this.sleep_info.sleep/60)}h${this.sleep_info.sleep%60}m/${Math.floor(this.target_info.sleep_target/60)}h${this.target_info.sleep_target%60}m`)
              .fontSize(14)
              .fontColor('#666')
          }
          .layoutWeight(1)
          .onClick(() => onJumpClick_sleep())

          // 饮水进度环（结构同上）
          Column({ space: 8 }) {
            Stack() {
              // 背景环（灰色）
              Progress({
                value: 100,
                type: ProgressType.Ring,
              })
                .style({ strokeWidth: 10 })
                .w_100_h_100()
                .color('#E0E0E0')

              // 动态蓝色进度环
              Progress({
                value: this.animatedWaterProgress,
                type: ProgressType.Ring,
              })
                .style({ strokeWidth: 10 })
                .w_100_h_100()
                .color('#4682B4')

              // 百分比计算
              Column({ space: 4 }) {
                Text(`${Math.min(100,
                  this.water_info.water > 0 && this.target_info.water_target > 0 ?
                  Math.round((this.water_info.water / this.target_info.water_target) * 100) : 0)}%`)
                  .fontSize(16)
                  .fontWeight(FontWeight.Bold)
                  .fontColor('#4682B4')
              }
            }

            Text('饮水')  // 标题
              .fontSize(16)
              .fontColor('#4682B4')
              .fontWeight(FontWeight.Bold)

            // 饮水数据展示
            Text(`${this.water_info.water}/${this.target_info.water_target}ml`)
              .fontSize(14)
              .fontColor('#666')
          }
          .layoutWeight(1)
          .onClick(() => onJumpClick_water())
        }
        // 容器样式设置
        .width('100%')        // 宽度占满
        .height(180)          // 固定高度
        .padding(10)          // 内边距
        .backgroundColor('#FFFFFF')  // 白色背景
        .borderRadius(15)      // 圆角边框
        // 第二片区域 - 步数展示卡片
        Row() {
          Image($r('app.media.step')) // 显示步数图标
            .width(100)
            .margin({ right: 0, left: 0 })
            .fillColor(Color.Orange) // 设置图标填充颜色为橙色

          Text('步数') // 显示“步数”文字
            .fontColor(Color.Green) // 设置文字颜色为绿色
            .fontSize(32) // 设置文字大小为32
            .margin({ top: -20 }) // 调整文字位置

          Column() { // 步数数据展示区域
            Row() { // 当前步数展示
              Text(`${this.step_info.step}`) // 动态显示当前步数
                .fontColor(Color.Green) // 设置文字颜色为绿色
                .fontSize(45) // 设置文字大小为45
                .fontWeight(FontWeight.Bold) // 设置文字加粗
              Text("步") // 显示“步”单位
                .fontColor(Color.Green) // 设置文字颜色为绿色
                .fontSize(24) // 设置文字大小为24
                .margin({ top: 10 }) // 调整文字位置
            }
            .width('100%') // 设置宽度为100%
            .justifyContent(FlexAlign.End) // 右对齐内容

            Row() { // 目标步数展示
              Text(`/${this.target_info.step_target}步`) // 动态显示目标步数
                .fontColor(Color.Green) // 设置文字颜色为绿色
                .fontSize(16) // 设置文字大小为16
            }
            .width('100%') // 设置宽度为100%
            .justifyContent(FlexAlign.End) // 右对齐内容
          }
          .width('100%') // 设置宽度为100%
          .justifyContent(FlexAlign.End) // 右对齐内容
          .layoutWeight(1) // 设置布局权重
          .margin({ right: 8 }) // 设置右边距
        }
        .height(150) // 设置卡片高度为150
        .width('100%') // 设置卡片宽度为100%
        .backgroundColor("#edfbef") // 设置背景颜色
        .borderRadius(15) // 设置圆角半径为15
        .scale({
          x: this.isPressed1 ? this.feedbackConfig.pressScale : 1, // 按压时缩放效果
          y: this.isPressed1 ? this.feedbackConfig.pressScale : 1
        })
        .animation({ curve: Curve.EaseOut, duration: this.feedbackConfig.duration }) // 设置动画效果
        .onTouch((event: TouchEvent) => { // 触摸事件处理
          if (event.type === TouchType.Down) { // 手指按下时
            animateTo({ duration: this.feedbackConfig.duration }, () => {
              this.isPressed1 = true; // 触发按压状态
            })
          } else if (event.type === TouchType.Up || event.type === TouchType.Cancel) { // 手指抬起或取消时
            animateTo({ duration: this.feedbackConfig.duration }, () => {
              this.isPressed1 = false; // 取消按压状态
            })
          }
        })
        .onClick(() => { // 点击事件处理
          console.log('点击了步数区域') // 打印日志
          onJumpClick_step() // 跳转到步数报告页面
        })


        // 第三片区域 - 睡眠信息展示卡片
        Row() {
          // 睡眠图标
          Image($r('app.media.sleep'))  // 使用资源管理器加载睡眠图标
            .width(100)                 // 固定宽度
            .margin({ right: 0, left: 0 }) // 水平方向无边距

          // 标题文本
          Text('睡眠')                  // 主标题
            .fontColor('#6968d3')       // 紫色字体
            .fontSize(32)               // 字号32
            .margin({ top: -20 })       // 向上偏移20单位调整垂直位置

          // 睡眠数据展示区域
          Column() {
            // 当前睡眠时间展示
            Row() {
              // 小时数值
              Text(`${this.sleep_hours}`)  // 绑定小时数据
                .fontColor('#6968d3')      // 紫色字体
                .fontSize(45)              // 大字号突出显示
                .fontWeight(FontWeight.Bold) // 加粗字体
              // 小时单位
              Text("h")                    // 小时单位
                .fontColor('#6968d3')
                .fontSize(24)              // 较小字号
                .margin({ top: 10 })       // 顶部边距调整
              // 分钟数值
              Text(`${this.sleep_minutes}`) // 绑定分钟数据
                .fontColor('#6968d3')
                .fontSize(45)
                .fontWeight(FontWeight.Bold)
              // 分钟单位
              Text("m")                    // 分钟单位
                .fontColor('#6968d3')
                .fontSize(24)
                .margin({ top: 10 })
            }
            .justifyContent(FlexAlign.End) // 子元素右对齐
            .width('100%')               // 宽度占满父容器

            // 目标睡眠时间展示
            Row() {
              // 目标小时部分
              Text(`/${Math.floor(this.target_info.sleep_target/60)}`) // 计算目标小时
                .fontColor('#6968d3')
                .fontSize(16)
              // 小时单位
              Text("h")
                .fontColor('#6968d3')
                .fontSize(16)
              // 目标分钟部分
              Text(`${this.target_info.sleep_target%60}`) // 计算目标分钟
                .fontColor('#6968d3')
                .fontSize(16)
              // 分钟单位
              Text("m")
                .fontColor('#6968d3')
                .fontSize(16)
            }
            .width('100%')               // 宽度占满
            .justifyContent(FlexAlign.End) // 右对齐
          }
          .layoutWeight(1)               // 剩余空间均分
          .margin({ right: 8 })          // 右侧留白
        }
        .height(150)                     // 固定高度
        .width('100%')                 // 宽度占满
        .backgroundColor('#deddf5')      // 紫色系浅色背景
        // 按压反馈效果（已注释）
        // .backgroundColor(this.isPressed2 ? '#F0F0F0' : '#deddf5')
        .borderRadius(15)                // 圆角边框

        // 缩放动画配置
        .scale({
          x: this.isPressed2 ? this.feedbackConfig.pressScale : 1, // 按下时X轴缩放
          y: this.isPressed2 ? this.feedbackConfig.pressScale : 1  // 按下时Y轴缩放
        })

        // 触摸事件处理
        .onTouch((event: TouchEvent) => {
          if (event.type === TouchType.Down) { // 按下事件
            animateTo({ duration: this.feedbackConfig.duration }, () => {
              this.isPressed2 = true; // 启用按压状态
            })
          } else if (event.type === TouchType.Up || event.type === TouchType.Cancel) { // 抬起/取消
            animateTo({ duration: this.feedbackConfig.duration }, () => {
              this.isPressed2 = false; // 恢复原始状态
            })
          }
        })

        // 点击事件处理
        .onClick(() => {
          // 日志记录（此处注释可能为原始调试信息）
          console.log('点击了步数区域') // 注意：此处应为"睡眠区域"
          onJumpClick_sleep() // 跳转到睡眠报表页面
        })



        // 第四片区域 - 饮水信息展示卡片
        Row() {
          // 饮水图标
          Image($r('app.media.water'))  // 使用资源管理器加载饮水图标（需确保资源存在）
            .width(80)                  // 固定宽度80
            .margin({ right: 0, left: 20 }) // 左侧留白20，右侧无边距
            .fillColor('#87CEEB')        // 设置图标填充颜色为淡蓝色

          // 标题文本
          Text('饮水')                  // 主标题
            .fontColor('#4682B4')       // 钢蓝色字体
            .fontSize(32)               // 字号32
            .margin({ top: -20 })       // 向上偏移20单位调整垂直位置

          // 数据展示区域
          Column() {
            // 当前饮水量展示
            Row() {
              // 饮水量数值
              Text(`${this.water_info.water}`)  // 绑定当前饮水量数据
                .fontColor('#4682B4')          // 钢蓝色字体
                .fontSize(45)                  // 大字号突出显示
                .fontWeight(FontWeight.Bold)   // 加粗字体
              // 单位显示
              Text("ml")                      // 毫升单位
                .fontColor('#4682B4')          // 同色系
                .fontSize(24)                  // 较小字号
                .margin({ top: 10 })           // 顶部边距调整
            }
            .width('100%')                   // 宽度占满父容器
            .justifyContent(FlexAlign.End)     // 子元素右对齐

            // 目标饮水量展示
            Row() {
              // 目标值显示
              Text(`/${this.target_info.water_target}ml`)  // 绑定目标饮水量数据
                .fontColor('#4682B4')                  // 同色系
                .fontSize(16)                          // 较小字号
            }
            .width('100%')                           // 宽度占满
            .justifyContent(FlexAlign.End)             // 右对齐
          }
          .layoutWeight(1)                         // 剩余空间均分
          .margin({ right: 8 })                    // 右侧留白
        }
        .height(150)                               // 固定高度150（与其它卡片统一）
        .width('100%')                           // 宽度占满
        .backgroundColor('#F0F8FF')              // 设置淡蓝色背景
        // 按压反馈效果（已注释）
        // .backgroundColor(this.isPressed3 ? '#F0F8FF' : Color.White)
        .borderRadius(15)                          // 圆角边框

        // 缩放动画配置
        .scale({
          x: this.isPressed3 ? this.feedbackConfig.pressScale : 1, // 按下时X轴缩放
          y: this.isPressed3 ? this.feedbackConfig.pressScale : 1  // 按下时Y轴缩放
        })

        // 触摸事件处理
        .onTouch((event: TouchEvent) => {
          if (event.type === TouchType.Down) { // 手指按下事件
            animateTo({ duration: this.feedbackConfig.duration }, () => {
              this.isPressed3 = true; // 启用按压状态
            })
          } else if (event.type === TouchType.Up || event.type === TouchType.Cancel) { // 抬起/取消
            animateTo({ duration: this.feedbackConfig.duration }, () => {
              this.isPressed3 = false; // 恢复原始状态
            })
          }
        })

        // 点击事件处理
        .onClick(async () => {
          // 以下为原始饮水量增加逻辑（已注释）
          // this.water_cup = Math.min(this.water_cup + 1, Math.floor(3500 / this.water_interval))
          // this.water_info.water = this.water_cup * this.water_interval
          // await this.data_service.water_update_data(this.today, this.water_info)

          // 当前执行页面跳转
          onJumpClick_water() // 跳转到饮水报表页面
        })

        .margin({ bottom: 20 })  // 底部留白20


      }
      .width('100%')
      // .height('100%')
      .padding({
        left: 10,
        right: 10,
        top: 5,
        bottom: 5
      })

    }
    .scrollBar(BarState.Off) // 隐藏滚动条
    .height('100%')
    .width('100%')


  }
  }

  /**
   * 加载动画构建器
   * @description 显示圆形进度加载动画，包含背景环和动态进度环
   */
  @Builder
  ProgressLoading() {
    Column() {
      Stack() {
        // 背景圆环（静态灰色）
        Circle()
          .width(80)
          .height(80)
          .fill(Color.Transparent)  // 透明填充
          .stroke('#EEE')  // 灰色描边
          .strokeWidth(8)  // 描边宽度8

        // 动态蓝色进度环
        Shape() {
          Path()
            .width(80)
            .height(80)
              // SVG路径命令：从(-40,0)开始绘制半径40的圆弧
            .commands(`M-40 0 A40 40 0 1 1 40 0`)
        }
        .stroke(Color.Blue)  // 蓝色描边
        .fill(Color.Transparent)  // 透明填充
        .strokeWidth(8)  // 描边宽度8
        .strokeLineCap(LineCapStyle.Round)  // 圆角端点样式

        // 添加旋转动画
        .rotate({
          // 计算旋转角度：3.6=360°/100%，-90°偏移使0%从顶部开始
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
    // 组件显示时触发加载动画
    .onAppear(() => {
      // 1秒动画达到100%进度
      animateTo({ duration: 1000 }, () => this.loadingProgress = 100)
    })
  }

  /**
   * 健康指标圆环动画方法
   * @description 启动步数、睡眠、饮水三个指标的进度动画
   */
  private startAnimation(): void {
    // 重置动画值为0
    this.animatedStepProgress = 0
    this.animatedSleepProgress = 0
    this.animatedWaterProgress = 0

    // 在下一帧启动动画（延迟200ms确保UI已渲染）
    setTimeout(() => {
      // 计算目标进度值（0-100%）
      const stepTarget = this.step_info.step > 0 && this.target_info.step_target > 0 ?
      Math.min(100, (this.step_info.step / this.target_info.step_target) * 100) : 0

      const sleepTarget = this.sleep_info.sleep > 0 && this.target_info.sleep_target > 0 ?
      Math.min(100, (this.sleep_info.sleep / this.target_info.sleep_target) * 100) : 0

      const waterTarget = this.water_info.water > 0 && this.target_info.water_target > 0 ?
      Math.min(100, (this.water_info.water / this.target_info.water_target) * 100) : 0

      // 启动动画
      animateTo({
        duration: 1000, // 1秒动画时长
        curve: Curve.EaseOut, // 缓出曲线（开始快结束慢）
        onFinish: () => {
          // 动画完成时确保最终值精确匹配
          this.animatedStepProgress = stepTarget
          this.animatedSleepProgress = sleepTarget
          this.animatedWaterProgress = waterTarget
        }
      }, () => {
        // 动画过程中更新进度值
        this.animatedStepProgress = stepTarget
        this.animatedSleepProgress = sleepTarget
        this.animatedWaterProgress = waterTarget
      })
    }, 200) // 短暂延迟确保UI已准备好
  }


  /**
   * 健康目标达成检测函数
   * @description 检测步数、睡眠、饮水目标是否达成并触发通知
   */
  judge_reach_target(){
    // 检查步数目标是否达成
    if (this.step_info.step >= this.target_info.step_target &&
      this.target_info.step_target > 0 &&
      !this.show_notify[0]) {
      this.step_show_notify()  // 显示步数达标通知
      this.show_notify[0] = true  // 标记步数通知已发送
    }

    // 检查睡眠目标是否达成
    if (this.sleep_info.sleep >= this.target_info.sleep_target &&
      this.target_info.sleep_target > 0 &&
      !this.show_notify[1]) {
      // 输出调试日志（包含目标值和当前值）
      console.info('睡眠时间已超过目标' +
      this.target_info.sleep_target +
        '<' +
      this.sleep_info.sleep)

      this.sleep_show_notify()  // 显示睡眠达标通知
      this.show_notify[1] = true  // 标记睡眠通知已发送
    }

    // 检查饮水目标是否达成
    if(this.water_info.water >= this.target_info.water_target &&
      this.target_info.water_target > 0 &&
      !this.show_notify[2]){
      this.water_show_notify()  // 显示饮水达标通知
      this.show_notify[2] = true  // 标记饮水通知已发送
    }
  }

  /**
   * 步数目标达成通知方法
   * @description 创建并发送步数达标系统通知
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
        // 记录错误日志（包含错误码和消息）
        hilog.error(0, '0',
          `Failed to publish notification. Code is ${err.code}, message is ${err.message}`);
        return;
      }
      // 记录成功日志
      hilog.info(1, '1', 'Succeeded in publishing notification.');
    });
  }

  /**
   * 睡眠目标达成通知方法
   * @description 创建并发送睡眠达标系统通知
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
   * 饮水目标达成通知方法
   * @description 创建并发送饮水达标系统通知
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
/**
 * 跳转到步数报表页面
 * @description 当用户点击步数卡片时触发的页面跳转函数
 */
function onJumpClick_step(): void {
  // 使用标准路由模式跳转到步数报表页面
  router.pushUrl({
    url: 'tabPages/report_step' // 目标页面路径
  },
    router.RouterMode.Standard, // 标准路由模式（不会在历史栈中创建新记录）
    (err) => {  // 错误回调处理
      if (err) {
        // 记录错误日志，包含错误码和错误信息
        console.error(`Invoke pushUrl failed, code is ${err.code}, message is ${err.message}`);
        return;
      }
      // 记录成功日志
      console.info('Invoke pushUrl succeeded.');
    });
}

/**
 * 跳转到睡眠报表页面
 * @description 当用户点击睡眠卡片时触发的页面跳转函数
 */
function onJumpClick_sleep(): void {
  // 使用标准路由模式跳转到睡眠报表页面
  router.pushUrl({
    url: 'tabPages/report_sleep' // 目标页面路径
  },
    router.RouterMode.Standard, // 标准路由模式
    (err) => {
      if (err) {
        // 记录错误日志，包含错误码和错误信息
        console.error(`Invoke pushUrl failed, code is ${err.code}, message is ${err.message}`);
        return;
      }
      // 记录成功日志
      console.info('Invoke pushUrl succeeded.');
    });
}

/**
 * 跳转到饮水报表页面
 * @description 当用户点击饮水卡片时触发的页面跳转函数
 */
function onJumpClick_water(): void {
  // 使用标准路由模式跳转到饮水报表页面
  router.pushUrl({
    url: 'tabPages/report_water' // 目标页面路径
  },
    router.RouterMode.Standard, // 标准路由模式
    (err) => {
      if (err) {
        // 记录错误日志，包含错误码和错误信息
        console.error(`Invoke pushUrl failed, code is ${err.code}, message is ${err.message}`);
        return;
      }
      // 记录成功日志
      console.info('Invoke pushUrl succeeded.');
    });
}