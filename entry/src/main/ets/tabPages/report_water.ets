import { DataService } from '../data_base/data_base';
import { ChartDateClass } from '../entity/chart_date_class';
import { WaterClass } from '../entity/water_class';
import { AppStorageV2 } from '@kit.ArkUI';

interface LegendItems{
  color: string;
  text: string;
}

@Entry
@Component
struct Report_water {
  // 当前选中的图表索引（未使用）
  @State currentIndex: number = 0

  // 加载进度百分比（顶部进度环使用）
  @State loadingProgress: number = 0

  // 加载状态标志（控制加载动画显示）
  @State isLoading: boolean = true;

  // 柱状图动画进度（0-100，控制柱状图增长动画）
  @State animationProgress: number = 0;

  // 图例配置（目前只有一个饮水量条目）
  private legend_items: LegendItems[]= [
    { color: '#4682B4', text: '饮水量' }
  ]

  // Canvas上下文配置（开启抗锯齿）
  private settings: RenderingContextSettings = new RenderingContextSettings(true)

  // 柱状图和折线图的Canvas渲染上下文
  private context_canvas_bar: CanvasRenderingContext2D = new CanvasRenderingContext2D(this.settings)
  private context_canvas_line: CanvasRenderingContext2D = new CanvasRenderingContext2D(this.settings)

  // 月份缩写数组（用于显示Jan-Dec）
  private monthAbbreviations: string[] = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];

  // 饮水数据集（初始化为7个0的数组）
  @State water_data_set: ChartDateClass =
    new ChartDateClass('water', '饮水周报', '#4682B4', new Array(7).fill(0))

  // 获取应用上下文和数据服务
  context: Context = getContext(this) as Context
  data_service: DataService = AppStorageV2.connect(DataService, "data_service", () => new DataService(this.context))!

  // 当前日期字符串（YYYY-MM-DD格式）
  @State today: string = new Date().toISOString().split('T')[0];

  // 当天饮水数据（从持久化存储获取）
  @StorageLink('water_info') water_info: WaterClass = new WaterClass()

  // 当周饮水数据数组
  @State water_info_week: WaterClass[] = []

  /**
   * 页面加载前执行的数据初始化方法
   * 包含数据获取、默认值处理、图表数据初始化和动画启动
   */
  async aboutToAppear(): Promise<void> {
    this.isLoading = true // 开始加载状态
    console.info('[water] 开始获取当天数据')

    // 获取当天饮水数据
    this.water_info = await this.data_service.water_query_data(this.today)

    // 如果是默认数据（无记录），插入初始数据
    if (this.water_info.date === 'default') {
      console.info('[water] 插入默认数据')
      await this.data_service.water_insert_data(this.today)
      this.water_info = await this.data_service.water_query_data(this.today)
    }

    console.info('[water] 开始获取周数据')
    // 获取最近7天的饮水数据
    this.water_info_week = await this.data_service.water_query_data_week(this.today)

    // 初始化图表数据（提取饮水量数值）
    this.water_data_set.data = this.water_info_week.map(item => item.water)
    console.info('[water] 数据初始化完成')

    // // === 测试数据插入（实际使用时应删除） ===
    // const date = new Date(this.today);
    // let formattedDate = date.toISOString().split('T')[0];
    // let s:WaterClass=new WaterClass(formattedDate,1600)
    // // this.data_service.water_update_data(formattedDate,s)
    //
    // // 模拟历史数据插入（倒序插入过去5天数据）
    // date.setDate(date.getDate() - 1);
    // formattedDate = date.toISOString().split('T')[0];
    // s=new WaterClass(formattedDate,1400)
    // this.data_service.water_update_data(formattedDate,s)
    //
    // date.setDate(date.getDate() - 1);
    // formattedDate = date.toISOString().split('T')[0];
    // s=new WaterClass(formattedDate,2100)
    // this.data_service.water_update_data(formattedDate,s)
    //
    // date.setDate(date.getDate() - 1);
    // formattedDate = date.toISOString().split('T')[0];
    // s=new WaterClass(formattedDate,1700)
    // this.data_service.water_update_data(formattedDate,s)
    //
    // date.setDate(date.getDate() - 1);
    // formattedDate = date.toISOString().split('T')[0];
    // s=new WaterClass(formattedDate,1800)
    // this.data_service.water_update_data(formattedDate,s)
    // === 测试数据结束 ===

    this.isLoading = false // 结束加载状态

    // 数据加载完成后，开始柱状图动画
    this.startAnimation()
  }
  build() {
    if (this.isLoading) {
      this.ProgressLoading()
    } else {
      Scroll() {
        Column() {
          // 标题区域
          Text(this.water_data_set.title) // 动态绑定图表标题（"饮水周报"）
            .fontSize(24) // 字号24
            .margin({ bottom: 15 }) // 底部留白15
            .fontColor(this.water_data_set.color) // 文字颜色与图表主色一致
            .fontWeight(FontWeight.Bold) // 加粗字体

          // 图表切换容器
          Swiper() {
            // 柱状图画布
            Canvas(this.context_canvas_bar)
              .width('100%') // 宽度占满父容器
              .height(400) // 固定高度400px
              .backgroundColor(Color.White) // 白色背景
              .borderRadius(12) // 圆角12px
              .onReady(() => this.drawChart('bar')) // 画布就绪时绘制柱状图

            // 折线图画布
            Canvas(this.context_canvas_line)
              .width('100%')
              .height(400)
              .backgroundColor(Color.White)
              .borderRadius(12)
              .onReady(() => this.drawChart('line')) // 画布就绪时绘制折线图
          }
          .indicatorStyle({ // 设置指示器样式
            color: '#dbdbdb', // 默认颜色
            selectedColor: '#4682B4', // 选中颜色（钢蓝色）
            size: 8 // 指示器大小
          })
          .index(this.currentIndex) // 绑定当前索引
          .onChange((index: number) => this.currentIndex = index) // 监听切换事件
          .margin({ bottom: 20 }) // 底部留白20

          // 数据明细列表
          Column() {
            // 遍历倒序的本周饮水数据
            ForEach(this.water_info_week.slice().reverse(), (item: WaterClass, index: number) => {
              Row() {
                // 图标列
                Image($r('app.media.water')) // 引用资源文件中的水滴图标
                  .width('20%') // 图标宽度占20%
                  .margin({ right: 0, left: 0 }) // 无左右边距

                // 数据详情容器
                Stack() {
                  Row() {
                    // 数据指标列
                    Column() {
                      Text('饮水量') // 标题
                        .fontSize(18) // 字号18
                        .fontColor('#666') // 灰色文字
                      Text(`${item.water} 毫升`) // 具体数值
                        .fontSize(18)
                        .fontColor('#4682B4') // 蓝色数值
                        .margin({ right: 8 }) // 右边距8
                        .fontWeight(FontWeight.Bold) // 加粗显示
                    }
                    .layoutWeight(1) // 占据剩余空间

                  }
                  .width('100%') // 宽度占满

                  // 日期标签
                  Text(this.formatDisplayDate(item.date)) // 格式化日期显示
                    .fontSize(14) // 小字号
                    .fontColor('#999') // 浅灰色
                    .position({ x: '70%', y: '5%' }) // 右上角定位
                }
                .width('75%') // 数据区宽度75%
                .height('100%') // 高度撑满
                .backgroundColor(Color.White) // 白色背景
                .borderRadius(8) // 圆角8px

              }
              .height(90) // 每条记录固定高度90px

              if(index != 6) Divider().strokeWidth(0.5).color('#eee') // 最后一条不显示分割线
            })
          }
          .backgroundColor(Color.White) // 列表容器背景色
          .borderRadius(12) // 圆角
          .margin({ bottom: 20 }) // 底部留白
        }
        .width('100%') // 宽度占满
        .padding(10) // 内边距10
      }
      .scrollBar(BarState.Off) // 隐藏滚动条
      .expandSafeArea([SafeAreaType.SYSTEM],[SafeAreaEdge.TOP, SafeAreaEdge.BOTTOM]) // 适配系统安全区域
      .backgroundColor('#ececec') // 灰色背景
    }
  }
  /**
   * 格式化日期字符串为显示格式（月缩写 日, 年）
   * @param dateStr - ISO格式的日期字符串（如"2023-08-15"）
   * @returns 格式化后的日期字符串（如"Aug 15, 2023"）
   */
  private formatDisplayDate(dateStr: string): string {
    const date = new Date(dateStr); // 解析日期字符串
    const month = this.monthAbbreviations[date.getMonth()]; // 获取月份缩写（0索引）
    return `${month} ${date.getDate()}, ${date.getFullYear()}`; // 组合显示格式
  }

  /**
   * 通用图表绘制方法
   * @param type - 图表类型 ('bar' 或 'line')
   */
  private drawChart(type: string) {
    // 根据图表类型选择画布上下文
    const ctx = type === 'bar' ? this.context_canvas_bar : this.context_canvas_line
    const canvasWidth = ctx.width
    const canvasHeight = ctx.height - 30 // 留出底部空白区域
    const maxValue = Math.max(...this.water_data_set.data) // 获取数据最大值

    // 清除画布内容
    ctx.clearRect(0, 0, canvasWidth, canvasHeight)

    // 绘制月份标题（仅使用当前周数据）
    this.drawMonthLabel(ctx, canvasWidth, type)

    // 绘制主体图表
    if (type === 'bar') {
      this.drawStackedBarChart(ctx, canvasWidth, canvasHeight, maxValue) // 绘制分层柱状图
    } else {
      this.drawLineChart(ctx, canvasWidth, canvasHeight, maxValue) // 绘制折线图
    }

    // 绘制数据标签和日期标签
    this.drawDataLabels(ctx, canvasWidth, canvasHeight, maxValue, type)
    this.drawDateLabels(ctx, canvasWidth, canvasHeight)
  }

  /**
   * 分层柱状图绘制（当前实际为普通柱状图）
   * @param ctx - Canvas上下文
   * @param canvasWidth - 画布宽度
   * @param canvasHeight - 画布高度
   * @param maxValue - 数据最大值（用于比例计算）
   */
  private drawStackedBarChart(
    ctx: CanvasRenderingContext2D,
    canvasWidth: number,
    canvasHeight: number,
    maxValue: number
  ) {
    const margin = 30 // 画布边距
    const totalBars = 7 // 固定7天数据
    const availableWidth = canvasWidth - margin * 2 // 可用宽度
    const barWidth = Math.min(40, availableWidth / (totalBars * 1.5)) // 计算柱宽（最大40px）
    const spacing = barWidth / 2 // 柱间距
    const verticalPadding = 40 // 垂直留白

    this.water_info_week.forEach((item, i) => {
      const total = item.water || 1 // 防止除零错误
      const x = margin + i * (barWidth + spacing) // 计算X坐标
      const totalHeight = (total / maxValue) * (canvasHeight - verticalPadding * 2) // 计算柱高

      // 动画高度计算
      const animatedHeight = (this.animationProgress / 100) * totalHeight;

      // 绘制饮水量柱状图
      ctx.fillStyle = '#4682B4'
      ctx.fillRect(
        x,
        canvasHeight - (verticalPadding-25) - animatedHeight, // Y坐标计算
        barWidth,
        animatedHeight
      )
    })
  }

  /**
   * 绘制图例（当前仅支持单一图例项）
   * @param ctx - Canvas上下文
   * @param canvasWidth - 画布宽度
   */
  private drawLegend(ctx: CanvasRenderingContext2D, canvasWidth: number) {
    ctx.font = '12px "HarmonyOS Sans"' // 设置默认字体

    this.legend_items.forEach((item, index) => {
      const x = canvasWidth - 180 + index * 60 // 计算X坐标
      const y = 35 // 固定Y坐标

      // 绘制颜色方块
      ctx.fillStyle = item.color
      ctx.fillRect(x, y, 12, 12)

      // 绘制文字说明
      ctx.fillStyle = '#333' // 文字颜色
      ctx.textAlign = 'left' // 左对齐
      const baseSize = canvasWidth / 20;
      const fontSize = Math.max(48, Math.min(72, baseSize * 3));
      ctx.font = `${fontSize}px "HarmonyOS Sans"`; // 设置字体
      ctx.fillText(item.text, x + 16, y + 10) // 绘制文字
    })
  }

  /**
   * 折线图绘制方法
   * @param ctx - Canvas上下文
   * @param canvasWidth - 画布宽度
   * @param canvasHeight - 画布高度
   * @param maxValue - 数据最大值（用于比例计算）
   */
  private drawLineChart(
    ctx: CanvasRenderingContext2D,
    canvasWidth: number,
    canvasHeight: number,
    maxValue: number
  ) {
    const margin = 30 // 画布边距
    const verticalPadding = 40 // 垂直留白

    const chartMaxHeight = canvasHeight - verticalPadding * 2 // 图表可用高度

    // 计算点间距
    const availableWidth_bar = canvasWidth - margin * 2
    const barWidth = availableWidth_bar / (7 * 1.5) // 柱宽计算
    const pointSpacing = (canvasWidth - margin * 2 - barWidth * 1.5) / 6 // 计算点间距

    // 初始化折线路径
    ctx.beginPath()
    ctx.strokeStyle = '#4682B4' // 线条颜色
    ctx.lineWidth = 4 // 线宽
    ctx.lineJoin = 'round' // 圆角连接

    // 绘制折线
    this.water_info_week.forEach((item, i) => {
      // 计算点坐标
      const yPos = canvasHeight - (verticalPadding-25) - (item.water / maxValue) * chartMaxHeight // Y坐标
      const x = margin + i * pointSpacing + barWidth / 2 // X坐标
      const y = yPos + 5 // 微调Y坐标

      if (i === 0) {
        ctx.moveTo(x, y) // 移动到第一个点
      } else {
        ctx.lineTo(x, y) // 连接后续点
      }
    })
    ctx.stroke() // 绘制折线

    // 绘制数据点
    this.water_info_week.forEach((item, i) => {
      // 重新计算点坐标
      const yPos = canvasHeight - (verticalPadding-25) - (item.water / maxValue) * chartMaxHeight
      const x = margin + i * pointSpacing + barWidth / 2
      const y = yPos + 5

      // 绘制外层圆环
      ctx.beginPath()
      ctx.arc(x, y, 6, 0, Math.PI * 2)
      ctx.fillStyle = '#4682B4'
      ctx.fill()

      // 绘制内层白点
      ctx.beginPath()
      ctx.arc(x, y, 4, 0, Math.PI * 2)
      ctx.fillStyle = Color.White
      ctx.fill()
    })
  }

  /**
   * 绘制数据标签（柱状图顶部的数值显示）
   * @param ctx - Canvas上下文
   * @param canvasWidth - 画布宽度
   * @param canvasHeight - 画布高度
   * @param maxValue - 数据最大值
   * @param type - 图表类型（未使用）
   */
  private drawDataLabels(
    ctx: CanvasRenderingContext2D,
    canvasWidth: number,
    canvasHeight: number,
    maxValue: number,
    type: string
  ) {
    const margin = 30 // 画布边距
    const totalBars = 7 // 固定7天数据
    const availableWidth = canvasWidth - margin * 2 // 可用宽度
    const barWidth = Math.min(40, availableWidth / (totalBars * 1.5)) // 柱宽计算
    const spacing = barWidth / 2 // 柱间距
    const verticalPadding = 40 // 垂直留白

    // 设置文字样式
    ctx.textBaseline = 'middle' // 垂直居中对齐
    ctx.textAlign = 'center' // 水平居中对齐

    this.water_info_week.forEach((item, i) => {
      // 计算坐标
      const x = margin + i * (barWidth + spacing) + barWidth / 2 // X坐标
      const total = item.water || 1 // 防止除零错误
      const totalHeight = (total / maxValue) * (canvasHeight - verticalPadding * 2) // 计算高度

      // 计算标签位置
      const labelY = canvasHeight - (verticalPadding-25) - totalHeight - 10 // 稍微上移

      // 设置字体样式
      const baseSize = canvasWidth / 20;
      const fontSize = Math.max(48, Math.min(72, baseSize * 3));
      ctx.fillStyle = '#4682B4' // 文字颜色
      ctx.font = `bold ${fontSize}px \"HarmonyOS Sans\"`; // 字体设置

      // 绘制文本
      ctx.fillText(`${item.water}`, x, labelY)
    })
  }

  /**
   * 绘制日期标签（柱状图底部的日期显示）
   * @param ctx - Canvas上下文
   * @param canvasWidth - 画布宽度
   * @param canvasHeight - 画布高度
   */
  private drawDateLabels(
    ctx: CanvasRenderingContext2D,
    canvasWidth: number,
    canvasHeight: number
  ) {
    const margin = 30 // 画布边距
    const totalBars = 7 // 固定7天数据
    const availableWidth = canvasWidth - margin * 2 // 可用宽度
    const barWidth = Math.min(40, availableWidth / (totalBars * 1.5)) // 柱宽计算
    const spacing = barWidth / 2 // 柱间距
    const verticalPadding = 40 // 垂直留白

    // 设置字体样式
    const baseSize = canvasWidth / 20;
    const fontSize = Math.max(48, Math.min(72, baseSize * 3));
    ctx.font = `${fontSize}px \"HarmonyOS Sans\"`;
    ctx.fillStyle = Color.Black // 文字颜色
    ctx.textBaseline = 'top' // 垂直顶部对齐
    ctx.textAlign = 'center' // 水平居中对齐

    this.water_info_week.forEach((item, i) => {
      // 计算X坐标
      const x = margin + i * (barWidth + spacing) + barWidth / 2

      // 创建日期对象
      const date = new Date(item.date)

      // 计算Y坐标（画布底部上方）
      const labelY = canvasHeight - (verticalPadding-25)

      // 绘制日期（仅显示日）
      ctx.fillText(`${date.getDate()}`, x, labelY)
    })
  }

  /**
   * 绘制月份标签（顶部标题）
   * @param ctx - Canvas上下文
   * @param canvasWidth - 画布宽度
   * @param type - 图表类型（控制标签位置）
   */
  private drawMonthLabel(
    ctx: CanvasRenderingContext2D,
    canvasWidth: number,
    type: string
  ) {
    if (this.water_info_week.length === 0) return; // 无数据则返回

    // 获取最后一个日期
    const lastDate = new Date(this.water_info_week[6].date)

    // 获取月份缩写和年份
    const month = this.monthAbbreviations[lastDate.getMonth()]
    const year = lastDate.getFullYear()

    // 设置字体样式
    ctx.font = 'bold 90px "HarmonyOS Sans"';
    ctx.fillStyle = Color.Black;
    ctx.textAlign = 'center' // 水平居中对齐

    // 根据图表类型设置不同的Y坐标
    if(type === 'bar') {
      ctx.fillText(`${month} ${year}`, canvasWidth / 2, 0) // 柱状图顶部
    } else {
      ctx.fillText(`${month} ${year}`, canvasWidth / 2, 25) // 折线图稍下偏移
    }
  }
  /**
   * 加载动画组件（环形进度条）
   * 展示数据加载进度并带动画效果
   */
  @Builder
  ProgressLoading() {
    Column() {
      // 环形进度条组件
      Progress({ value: this.loadingProgress, total: 100 })
        .width(80) // 宽度80px
        .height(80) // 高度80px
        .color(Color.Green) // 进度条颜色为绿色

      // 进度百分比文本显示
      Text(`${Math.floor(this.loadingProgress)}%`)
        .fontSize(18) // 文字大小
        .margin({ top: 12 }) // 顶部边距12px
    }
    .onAppear(() => {
      // 组件显示时启动3秒动画
      animateTo({ duration: 3000 }, () =>
      this.loadingProgress = 100 // 3秒内从0%到100%
      )
    })
  }

  /**
   * 启动柱状图增长动画
   * 1. 先完成顶部进度条动画（300ms到100%）
   * 2. 然后启动柱状图逐帧增长动画
   */
  private startAnimation() {
    // 使用ArkUI动画API执行进度条动画
    animateTo({ duration: 300 }, () => {
      this.loadingProgress = 100;  // 设置进度条为满
      this.animateChartGrowth();   // 启动柱状图动画
    });
  }

  /**
   * 控制柱状图逐帧增长动画
   * 通过定时器逐步增加animationProgress值
   * 触发图表重绘实现柱状图生长效果
   */
  private animateChartGrowth() {
    const maxValue = Math.max(...this.water_data_set.data); // 获取最大数据值
    const animationInterval = setInterval(() => {
      this.animationProgress += 1; // 每次递增1%动画进度

      // 动画结束条件判断
      if (this.animationProgress >= 100) {
        clearInterval(animationInterval); // 清除定时器
        this.animationProgress = 100; // 保证最终值准确
      }

      // 重新绘制柱状图（动画进度会动态影响柱高）
      this.drawChart('bar');
    }, 5); // 5ms刷新间隔（约200帧完成动画）
  }


}
