// report_sleep.ts
import { DataService } from '../data_base/data_base';
import { ChartDateClass } from '../entity/chart_date_class';
import { SleepClass } from '../entity/sleep_class';
import { AppStorageV2 } from '@kit.ArkUI';


interface LegendItems{
  color: string;
  text: string;
}


@Entry
@Component
struct Report_sleep {
  // 当前选中的索引（用于切换图表或标签）
  @State currentIndex: number = 0

  // 加载进度百分比（0-100）
  @State loadingProgress: number = 0

  // 加载状态标志（控制加载动画显示）
  @State isLoading: boolean = true

  // 柱状图动画进度（0-1）
  @State animationProgress: number = 0

  // 图例配置项（颜色+文本）
  private legend_items: LegendItems[]= [
    { color: '#1976D2', text: '深睡' },
    { color: '#64B5F6', text: '浅睡' },
    { color: '#ffaf3b', text: 'REM' }
  ]

  // Canvas上下文配置（抗锯齿开启）
  private settings: RenderingContextSettings = new RenderingContextSettings(true)

  // 柱状图专用Canvas渲染上下文
  private context_canvas_bar: CanvasRenderingContext2D = new CanvasRenderingContext2D(this.settings)

  // 折线图专用Canvas渲染上下文
  private context_canvas_line: CanvasRenderingContext2D = new CanvasRenderingContext2D(this.settings)

  // 月份缩写列表（用于X轴时间轴）
  private monthAbbreviations: string[] = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec']

  // 睡眠周报图表数据集（初始化为空数组）
  @State sleep_data_set: ChartDateClass =
    new ChartDateClass('sleep', '睡眠周报', '#2196F3', new Array(7).fill(0))

  // 应用上下文对象
  context: Context = getContext(this) as Context

  // 数据服务实例（通过AppStorage连接）
  data_service: DataService = AppStorageV2.connect(DataService, "data_service", () => new DataService(this.context))!

  // 当前日期字符串（YYYY-MM-DD格式）
  @State today: string = new Date().toISOString().split('T')[0]

  // 本地存储的睡眠数据（绑定到'sleep_info'键）
  @StorageLink('sleep_info') sleep_info: SleepClass = new SleepClass()

  // 周睡眠数据数组（存储最近7天数据）
  @State sleep_info_week: SleepClass[] = []

  // 组件挂载前生命周期钩子
  async aboutToAppear(): Promise<void> {
    this.isLoading = true // 开启加载状态

    // 获取当天睡眠数据
    console.info('[sleep] 开始获取当天数据')
    this.sleep_info = await this.data_service.sleep_query_data(this.today)

    // 如果是默认数据则插入新数据
    if (this.sleep_info.date === 'default') {
      console.info('[sleep] 插入默认数据')
      await this.data_service.sleep_insert_data(this.today)
      this.sleep_info = await this.data_service.sleep_query_data(this.today)
    }

    // 获取周数据
    console.info('[sleep] 开始获取周数据')
    this.sleep_info_week = await this.data_service.sleep_query_data_week(this.today)

    // 初始化图表数据（总睡眠时长）
    this.sleep_data_set.data = this.sleep_info_week.map(item => item.sleep)
    console.info('[sleep] 数据初始化完成')


    // const date = new Date(this.today);
    // let formattedDate = date.toISOString().split('T')[0];
    //
    // let s:SleepClass=new SleepClass(formattedDate,360,1,150,170,40)
    // this.data_service.sleep_update_data(formattedDate,s)

    // date.setDate(date.getDate() - 1);
    // formattedDate = date.toISOString().split('T')[0];
    // s=new SleepClass(formattedDate,480,2,200,200,80)
    // this.data_service.sleep_update_data(formattedDate,s)
    //
    // date.setDate(date.getDate() - 1);
    // formattedDate = date.toISOString().split('T')[0];
    // s=new SleepClass(formattedDate,300,5,100,150,50)
    // this.data_service.sleep_update_data(formattedDate,s)
    //
    // date.setDate(date.getDate() - 1);
    // formattedDate = date.toISOString().split('T')[0];
    // s=new SleepClass(formattedDate,400,2,200,170,30)
    // this.data_service.sleep_update_data(formattedDate,s)
    //
    // date.setDate(date.getDate() - 1);
    // formattedDate = date.toISOString().split('T')[0];
    // s=new SleepClass(formattedDate,420,1,250,150,20)
    // this.data_service.sleep_update_data(formattedDate,s)

    // date.setDate(date.getDate() - 1);
    // formattedDate = date.toISOString().split('T')[0];
    // s=new SleepClass(formattedDate,390,4,100,250,40)
    // this.data_service.sleep_update_data(formattedDate,s)
    //
    // date.setDate(date.getDate() - 1);
    // formattedDate = date.toISOString().split('T')[0];
    // s=new SleepClass(formattedDate,420,2,150,200,70)
    // this.data_service.sleep_update_data(formattedDate,s)


    this.isLoading = false // 关闭加载状态

    // 启动动画
    this.startAnimation()
  }

  build() {
    if (this.isLoading) {
      this.ProgressLoading()
    } else {
      Scroll() {
        Column() {
          // 标题
          Text(this.sleep_data_set.title)
            .fontSize(24)
            .margin({ bottom: 15 })
            .fontColor(this.sleep_data_set.color)
            .fontWeight(FontWeight.Bold)

          // 图表切换容器（支持左右滑动切换）
          Swiper() {
            // 分层柱状图画布
            Canvas(this.context_canvas_bar)
              .width('100%')         // 宽度撑满父容器
              .height(400)           // 固定高度400px
              .backgroundColor(Color.White) // 白色背景
              .borderRadius(12)      // 圆角边框
              .onReady(() => this.drawChart('bar')) // 画布就绪后绘制柱状图

            // 折线图画布
            Canvas(this.context_canvas_line)
              .width('100%')
              .height(400)
              .backgroundColor(Color.White)
              .borderRadius(12)
              .onReady(() => this.drawChart('line')) // 画布就绪后绘制折线图
          }
          .indicatorStyle({
            color: '#dbdbdb',        // 未选中指示器颜色
            selectedColor: '#2196F3', // 选中状态颜色
            size: 8                  // 指示器大小
          })
          .index(this.currentIndex)  // 绑定当前索引
          .onChange((index: number) => this.currentIndex = index) // 索引变化回调
          .margin({ bottom: 20 })    // 底部外边距

          // 数据明细列表容器
          Column() {
            // 反向遍历周睡眠数据（最新数据在最前）
            ForEach(this.sleep_info_week.slice().reverse(), (item: SleepClass, index: number) => {
              Row() {
                // 图标区域（睡眠小图标）
                Image($r('app.media.sleep'))
                  .width('25%')        // 图标区域占25%宽度
                  .margin({ right: 0, left: -20 }) // 左侧负边距修正对齐

                // 数据展示区域
                Stack() {
                  // 四列睡眠数据展示
                  Row() {
                    // 深睡数据列
                    Column() {
                      Text('深睡')
                        .fontSize(18)
                        .fontColor('#666') // 灰色标签
                      Text(`${this.formatSleepTime(item.deep)}`) // 格式化睡眠时间
                        .fontSize(18)
                        .fontColor('#1976D2') // 深蓝色数值
                        .margin({ right: 8 })
                        .fontWeight(FontWeight.Bold) // 加粗显示
                    }
                    .layoutWeight(1) // 均分宽度

                    // 浅睡数据列
                    Column() {
                      Text('浅睡')
                        .fontSize(18)
                        .fontColor('#666')
                      Text(`${this.formatSleepTime(item.light)}`)
                        .fontSize(18)
                        .fontColor('#64B5F6') // 浅蓝色数值
                        .margin({ right: 8 })
                        .fontWeight(FontWeight.Bold)
                    }
                    .layoutWeight(1)

                    // 苏醒次数列
                    Column() {
                      Text('苏醒')
                        .fontSize(18)
                        .fontColor('#666')
                      Text(`${item.wake}次`) // 次数单位显示
                        .fontSize(18)
                        .fontColor('#F44336') // 红色数值
                        .margin({ right: 8 })
                        .fontWeight(FontWeight.Bold)
                    }
                    .layoutWeight(1)

                    // REM睡眠数据列
                    Column() {
                      Text('REM')
                        .fontSize(18)
                        .fontColor('#666')
                      Text(`${this.formatSleepTime(item.rem)}`)
                        .fontSize(18)
                        .fontColor('#9C27B0') // 紫色数值
                        .fontWeight(FontWeight.Bold)
                    }
                    .layoutWeight(1)

                  }
                  .width('100%') // 占满容器宽度

                  // 日期标签（右上角定位）
                  Text(this.formatDisplayDate(item.date)) // 日期格式化
                    .fontSize(14)
                    .fontColor('#999') // 浅灰色日期
                    .position({ x: '70%', y: '5%' }) // 相对定位到右上角
                }
                .width('75%')  // 数据区域占75%宽度
                .height('100%') // 高度撑满父容器
              }
              .height(90)      // 固定行高
              .backgroundColor(Color.White) // 白色背景
              .borderRadius(8) // 圆角边框

              // 最后一行不显示分割线
              if(index != 6) Divider()
                .strokeWidth(0.5) // 分割线粗细
                .color('#eee')    // 浅灰色分割线
            })
          }
          // 容器样式配置
          .backgroundColor(Color.White) // 白色背景
          .borderRadius(12)             // 圆角边框
          .margin({ bottom: 20 })       // 底部外边距



        }
        .width('100%')
        .padding(10)
      }
      .scrollBar(BarState.Off)
      .expandSafeArea([SafeAreaType.SYSTEM],[SafeAreaEdge.TOP, SafeAreaEdge.BOTTOM])
      .backgroundColor('#ececec')
    }
  }
  // 格式化睡眠时间（分钟转小时+分钟）
  private formatSleepTime(minutes: number): string {
    const hours = Math.floor(minutes / 60) // 计算完整小时数
    const mins = minutes % 60             // 计算剩余分钟数
    return `${hours}h${mins.toString().padStart(2, '0')}m` // 返回格式：XhYYm
  }

  // 格式化显示日期（YYYY-MM-DD → Mon DD, YYYY）
  private formatDisplayDate(dateStr: string): string {
    const date = new Date(dateStr) // 创建日期对象
    const month = this.monthAbbreviations[date.getMonth()] // 获取月份缩写
    return `${month} ${date.getDate()}, ${date.getFullYear()}` // 返回格式：Mon DD, YYYY
  }

  // 图表主绘制函数（根据类型选择绘制方式）
  private drawChart(type: string) {
    // 获取当前画布上下文
    const ctx = type === 'bar' ? this.context_canvas_bar : this.context_canvas_line

    // 获取画布尺寸（减去底部留白）
    const canvasWidth = ctx.width
    const canvasHeight = ctx.height - 30

    // 获取数据最大值（用于比例计算）
    const maxValue = Math.max(...this.sleep_data_set.data)

    // 清除画布内容
    ctx.clearRect(0, 0, canvasWidth, canvasHeight)

    // 绘制月份时间轴标签
    this.drawMonthLabel(ctx, canvasWidth, type)

    // 根据图表类型执行不同绘制逻辑
    if (type === 'bar') {
      // 绘制分层柱状图
      this.drawStackedBarChart(ctx, canvasWidth, canvasHeight, maxValue)
    } else {
      // 绘制折线图
      this.drawLineChart(ctx, canvasWidth, canvasHeight, maxValue)
    }

    // 绘制数据标签（数值/百分比）
    this.drawDataLabels(ctx, canvasWidth, canvasHeight, maxValue, type)

    // 绘制日期标签（X轴）
    this.drawDateLabels(ctx, canvasWidth, canvasHeight)
  }

  // 分层柱状图绘制方法
  private drawStackedBarChart(ctx: CanvasRenderingContext2D, canvasWidth: number, canvasHeight: number, maxValue: number) {
    // 布局配置
    const margin = 30                  // 左右边距
    const totalBars = 7                // 总共7天数据
    const availableWidth = canvasWidth - margin * 2 // 可用绘制宽度
    const barWidth = Math.min(40, availableWidth / (totalBars * 1.5)) // 动态计算柱宽
    const spacing = barWidth / 2       // 柱间距
    const verticalPadding = 40         // 垂直留白

    // 遍历周数据绘制柱状图
    this.sleep_info_week.forEach((item, i) => {
      // 数据校验（防止除零错误）
      const total = item.sleep || 1
      const validTotal = Math.max(total, item.deep + item.light + item.rem)

      // 计算各睡眠阶段占比
      const deepRatio = item.deep / validTotal
      const lightRatio = item.light / validTotal
      const remRatio = item.rem / validTotal

      // 计算柱形位置
      const x = margin + i * (barWidth + spacing)

      // 动画高度计算（基于最大值比例和动画进度）
      const totalHeight = (validTotal / maxValue) * (canvasHeight - verticalPadding * 2)
      const animatedHeight = (this.animationProgress / 100) * totalHeight

      // 分层绘制柱状图（从下到上：深睡→浅睡→REM）

      // 深睡部分
      ctx.fillStyle = '#1976D2'
      ctx.fillRect(
        x,
        canvasHeight - (verticalPadding-25) - animatedHeight * deepRatio, // Y坐标计算
        barWidth,
        animatedHeight * deepRatio // 动态高度
      )

      // 浅睡部分
      ctx.fillStyle = '#64B5F6'
      ctx.fillRect(
        x,
        canvasHeight - (verticalPadding-25) - animatedHeight * (deepRatio + lightRatio),
        barWidth,
        animatedHeight * lightRatio
      )

      // REM部分
      ctx.fillStyle = '#ffaf3b'
      ctx.fillRect(
        x,
        canvasHeight - (verticalPadding-25) - animatedHeight * (deepRatio + lightRatio + remRatio),
        barWidth,
        animatedHeight * remRatio
      )

      // 调试日志输出睡眠构成比例
      console.info(`[睡眠构成] 日期：${item.date} 深睡：${(deepRatio*100).toFixed(1)}% ` +
        `浅睡：${(lightRatio*100).toFixed(1)}% REM：${(remRatio*100).toFixed(1)}%`)
    })

    // 绘制图例说明
    this.drawLegend(ctx, canvasWidth)
  }
  // 绘制图例说明
  private drawLegend(ctx: CanvasRenderingContext2D, canvasWidth: number) {
    ctx.font = '12px "HarmonyOS Sans"' // 设置图例字体样式

    // 遍历图例配置项绘制
    this.legend_items.forEach((item, index) => {
      // 计算图例位置（水平排列）
      const x = canvasWidth - 180 + index * 60 // 右侧对齐计算
      const y = 30 // 固定垂直位置

      // 绘制颜色方块
      ctx.fillStyle = item.color
      ctx.fillRect(x, y, 12, 12) // 12x12像素色块

      // 绘制文字说明
      ctx.fillStyle = '#333' // 文字颜色
      ctx.textAlign = 'left' // 文字左对齐

      // 动态字体大小计算（基于画布宽度）
      const baseSize = canvasWidth / 20
      const fontSize = Math.max(48, Math.min(72, baseSize * 3)) // 限制字体大小范围
      ctx.font = `${fontSize}px \"HarmonyOS Sans\"` // 设置字体大小
      ctx.fillText(item.text, x + 16, y ) // 文字绘制位置（色块右侧）
    })
  }

  // 折线图绘制方法
  private drawLineChart(ctx: CanvasRenderingContext2D, canvasWidth: number, canvasHeight: number, maxValue: number) {
    // 布局配置
    const margin = 30                  // 边距
    const verticalPadding = 40         // 垂直留白

    const chartMaxHeight = canvasHeight - verticalPadding * 2 // 可用图表高度

    // 计算柱状图宽度（用于对齐折线点）
    const availableWidth_bar = canvasWidth - margin * 2
    const barWidth = availableWidth_bar / (7 * 1.5) // 柱状图基础宽度

    // 计算折线点间距
    const availableWidth = canvasWidth - margin * 2 - barWidth*1.5 // 可用宽度减去柱宽
    const pointSpacing = availableWidth / 6 // 6个间隔绘制7个点

    // 第一步：绘制折线连接线
    ctx.beginPath()
    ctx.strokeStyle = '#2196F3' // 折线颜色
    ctx.lineWidth = 4           // 线条粗细
    ctx.lineJoin = 'round'      // 圆角连接点

    this.sleep_info_week.forEach((item, i) => {
      // 数据点坐标计算
      const total = Math.max(item.sleep, item.deep + item.light + item.rem) // 数据校验
      const yPos = canvasHeight - (verticalPadding-25) - (total / maxValue) * chartMaxHeight // Y坐标
      const x = margin + i * pointSpacing + barWidth/2 // X坐标（居中对齐柱状图）
      const y = yPos + 5 // 微调Y坐标

      if (i === 0) {
        ctx.moveTo(x, y) // 起始点
      } else {
        ctx.lineTo(x, y) // 连接线
      }
    })
    ctx.stroke() // 绘制折线

    // 第二步：绘制数据点（带内外圆的样式）
    this.sleep_info_week.forEach((item, i) => {
      // 重复坐标计算
      const total = Math.max(item.sleep, item.deep + item.light + item.rem)
      const yPos = canvasHeight - (verticalPadding-25) - (total / maxValue) * chartMaxHeight
      const x = margin + i * pointSpacing + barWidth/2
      const y = yPos + 5

      // 外层大圆
      ctx.beginPath()
      ctx.arc(x, y, 6, 0, Math.PI * 2) // 半径6
      ctx.fillStyle = '#2196F3' // 蓝色填充
      ctx.fill()

      // 内层小圆（白色中心点）
      ctx.beginPath()
      ctx.arc(x, y, 4, 0, Math.PI * 2) // 半径4
      ctx.fillStyle = Color.White // 白色填充
      ctx.fill()
    })
  }
  // 数据标签（支持分层显示）
  private drawDataLabels(ctx: CanvasRenderingContext2D, canvasWidth: number, canvasHeight: number, maxValue: number, type: string) {
    // 布局配置参数
    const margin = 30
    const totalBars = 7
    const availableWidth = canvasWidth - margin * 2
    const barWidth = Math.min(40, availableWidth / (totalBars * 1.5)) // 动态计算柱宽
    const spacing = barWidth / 2 // 柱间距
    const verticalPadding = 40 // 垂直留白

    // 动态字体设置（基于画布宽度）
    const baseFontSize = canvasWidth / 35
    const mainFontSize = Math.min(28, Math.max(18, baseFontSize)) // 字体大小限制范围
    const ratioFontSize = mainFontSize * 0.8 // 百分比标签字号

    // 文字对齐方式设置
    ctx.textBaseline = 'middle' // 垂直中线对齐
    ctx.textAlign = 'center' // 水平居中对齐

    // 遍历数据集绘制标签
    this.sleep_info_week.forEach((item, i) => {
      // 计算X轴中心坐标
      const x = margin + i * (barWidth + spacing) + barWidth / 2

      // 数据校验（防止除零错误）
      const total = item.sleep || 1
      const validTotal = Math.max(total, item.deep + item.light + item.rem)

      // 计算各睡眠阶段比例
      const deepRatio = item.deep / validTotal
      const lightRatio = item.light / validTotal
      const remRatio = item.rem / validTotal

      // 动态高度计算
      const totalHeight = (validTotal / maxValue) * (canvasHeight - verticalPadding * 2)

      // 各层标签Y坐标计算
      const deepY = canvasHeight - (verticalPadding-25) - totalHeight * deepRatio/2 // 深睡层中点
      const lightY = canvasHeight - (verticalPadding-25) - totalHeight*(deepRatio + lightRatio/2) // 浅睡层中点
      const remY = canvasHeight - (verticalPadding-25) - totalHeight*(deepRatio + lightRatio + remRatio/2) // REM层中点
      const totalY = canvasHeight - (verticalPadding-25) - totalHeight - 10 // 总时长顶部标签

      // 动态字体大小计算
      const baseSize = canvasWidth / 20
      const fontSize = Math.max(48, Math.min(72, baseSize * 3))
      ctx.font = `bold ${fontSize}px \"HarmonyOS Sans\"`

      // 分层标签绘制（仅柱状图显示百分比）
      if(type === 'bar') {
        // 深睡百分比
        ctx.fillStyle = '#333'
        ctx.fillText(`${Math.round(deepRatio * 100)}%`, x, deepY)

        // 浅睡百分比
        ctx.fillStyle = '#333'
        ctx.fillText(`${Math.round(lightRatio * 100)}%`, x, lightY)

        // REM百分比
        ctx.fillStyle = '#333'
        ctx.fillText(`${Math.round(remRatio * 100)}%`, x, remY)
      }

      // 总时长标签（所有类型显示）
      ctx.font = `bold ${fontSize}px \"HarmonyOS Sans\"`
      ctx.fillStyle = '#5857cd' // 紫色标题
      ctx.fillText(
        `${Math.floor(validTotal/60)}h${validTotal%60}m`, // 格式化时间
        x,
        totalY
      )
    })
  }

  // 日期标签绘制
  private drawDateLabels(ctx: CanvasRenderingContext2D, canvasWidth: number, canvasHeight: number) {
    // 布局参数
    const margin = 30
    const totalBars = 7
    const availableWidth = canvasWidth - margin * 2
    const barWidth = Math.min(40, availableWidth / (totalBars * 1.5)) // 柱宽计算
    const spacing = barWidth / 2 // 间距计算
    const verticalPadding = 40 // 与柱状图绘制保持一致

    // 动态字体大小
    const baseSize = canvasWidth / 20
    const fontSize = Math.max(48, Math.min(72, baseSize * 3))
    ctx.font = `${fontSize}px \"HarmonyOS Sans\"`

    // 文字样式
    ctx.fillStyle = Color.Black // 黑色文字
    ctx.textBaseline = 'top' // 顶部对齐
    ctx.textAlign = 'center' // 居中对齐

    // 遍历数据集绘制日期标签
    this.sleep_info_week.forEach((item, i) => {
      // 计算X坐标（柱中心）
      const x = margin + i * (barWidth + spacing) + barWidth / 2

      // 解析日期
      const date = new Date(item.date)

      // 计算标签位置（柱底下方）
      const labelY = canvasHeight - (verticalPadding-25)

      // 格式化日期显示
      const day = date.getDate().toString().padStart(2, ' ') // 日期补零
      const month = this.monthAbbreviations[date.getMonth()] // 月份缩写

      // 绘制日期标签
      ctx.fillText(`${day}`, x, labelY) // 日期（居中）
      // ctx.fillText(`${month}`, x, labelY + 18) // 月份（已注释）
    })
  }

  // 月份标签绘制
  private drawMonthLabel(ctx: CanvasRenderingContext2D, canvasWidth: number, type: string) {
    // 空数据保护
    if (this.sleep_info_week.length === 0) return

    // 获取最新日期
    const lastDate = new Date(this.sleep_info_week[6].date)
    const month = this.monthAbbreviations[lastDate.getMonth()] // 月份缩写
    const year = lastDate.getFullYear() // 年份

    // 设置字体样式
    ctx.font = 'bold 90px "HarmonyOS Sans"'
    ctx.fillStyle = Color.Black // 黑色文字
    ctx.textAlign = 'center' // 居中对齐

    // 根据图表类型设置绘制位置
    if(type === 'bar') {
      ctx.fillText(`${month} ${year}`, canvasWidth / 2, 0) // 柱状图顶部
    } else {
      ctx.fillText(`${month} ${year}`, canvasWidth / 2, 25) // 折线图稍低位置
    }
  }
  // 加载进度指示器组件
  @Builder
  ProgressLoading() {
    Column() {
      // 圆形进度条（系统组件）
      Progress({ value: this.loadingProgress, total: 100 }) // 绑定加载进度
        .width(80)         // 固定宽度
        .height(80)        // 固定高度
        .color(Color.Blue) // 进度条颜色

      // 进度百分比文本
      Text(`${Math.floor(this.loadingProgress)}%`)
        .fontSize(18)       // 字体大小
        .margin({ top: 12 }) // 顶部间距
    }
    .onAppear(() => {
      // 组件挂载时启动动画
      animateTo({ duration: 1000 }, () => {
        this.loadingProgress = 100; // 1秒内过渡到100%
      })
    })
  }

  // 启动加载动画序列
  private startAnimation() {
    // 第一阶段动画：进度条加载
    animateTo({ duration: 300 }, () => {
      this.loadingProgress = 100; // 快速填充进度条
      // 第二阶段动画：柱状图生长
      this.animateChartGrowth(); // 启动图表动画
    });
  }

  // 柱状图生长动画控制器
  private animateChartGrowth() {
    const maxValue = Math.max(...this.sleep_data_set.data); // 获取最大数据值

    // 创建定时动画（5ms刷新间隔）
    const animationInterval = setInterval(() => {
      this.animationProgress += 1; // 逐步增加动画进度

      // 动画完成条件判断
      if (this.animationProgress >= 100) {
        clearInterval(animationInterval); // 清除定时器
        this.animationProgress = 100;     // 确保最终值
      }

      // 每帧重绘图表
      this.drawChart('bar'); // 触发柱状图重绘
    }, 5); // 5ms/帧（约200fps）
  }

}