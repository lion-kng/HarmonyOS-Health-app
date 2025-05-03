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
  @State currentIndex: number = 0
  @State loadingProgress: number = 0
  @State isLoading: boolean = true;
  @State animationProgress: number = 0; // 新增，控制柱状图动画进度

  private legend_items: LegendItems[]= [
    { color: '#4682B4', text: '饮水量' }
  ]

  private settings: RenderingContextSettings = new RenderingContextSettings(true)
  private context_canvas_bar: CanvasRenderingContext2D = new CanvasRenderingContext2D(this.settings)
  private context_canvas_line: CanvasRenderingContext2D = new CanvasRenderingContext2D(this.settings)
  private monthAbbreviations: string[] = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];

  @State water_data_set: ChartDateClass =
    new ChartDateClass('water', '饮水周报', '#4682B4', new Array(7).fill(0))
  context: Context = getContext(this) as Context
  data_service: DataService = AppStorageV2.connect(DataService, "data_service", () => new DataService(this.context))!
  @State today: string = new Date().toISOString().split('T')[0];
  @StorageLink('water_info') water_info: WaterClass = new WaterClass()
  @State water_info_week: WaterClass[] = []

  async aboutToAppear(): Promise<void> {
    this.isLoading = true
    console.info('[water] 开始获取当天数据')
    this.water_info = await this.data_service.water_query_data(this.today)
    if (this.water_info.date === 'default') {
      console.info('[water] 插入默认数据')
      await this.data_service.water_insert_data(this.today)
      this.water_info = await this.data_service.water_query_data(this.today)
    }

    console.info('[water] 开始获取周数据')
    this.water_info_week = await this.data_service.water_query_data_week(this.today)

    // 初始化图表数据（饮水量）
    this.water_data_set.data = this.water_info_week.map(item => item.water)
    console.info('[water] 数据初始化完成')


    //修改数据
    const date = new Date(this.today);
    let formattedDate = date.toISOString().split('T')[0];
    let s:WaterClass=new WaterClass(formattedDate,1600)

    // this.data_service.water_update_data(formattedDate,s)

    date.setDate(date.getDate() - 1);
    formattedDate = date.toISOString().split('T')[0];
    s=new WaterClass(formattedDate,1400)
    this.data_service.water_update_data(formattedDate,s)

    date.setDate(date.getDate() - 1);
    formattedDate = date.toISOString().split('T')[0];
    s=new WaterClass(formattedDate,2100)
    this.data_service.water_update_data(formattedDate,s)

    date.setDate(date.getDate() - 1);
    formattedDate = date.toISOString().split('T')[0];
    s=new WaterClass(formattedDate,1700)
    this.data_service.water_update_data(formattedDate,s)

    date.setDate(date.getDate() - 1);
    formattedDate = date.toISOString().split('T')[0];
    s=new WaterClass(formattedDate,1800)
    this.data_service.water_update_data(formattedDate,s)






    this.isLoading = false

    // 数据加载完成后，开始柱状图动画
    this.startAnimation()


  }

  build() {
    if (this.isLoading) {
      this.ProgressLoading()
    } else {
      Scroll() {
        Column() {
          // 标题
          Text(this.water_data_set.title)
            .fontSize(24)
            .margin({ bottom: 15 })
            .fontColor(this.water_data_set.color)
            .fontWeight(FontWeight.Bold)

          // 图表切换
          Swiper() {
            // 分层柱状图
            Canvas(this.context_canvas_bar)
              .width('100%')
              .height(400)
              .backgroundColor(Color.White)
              .borderRadius(12)
              .onReady(() => this.drawChart('bar'))

            // 折线图
            Canvas(this.context_canvas_line)
              .width('100%')
              .height(400)
              .backgroundColor(Color.White)
              .borderRadius(12)
              .onReady(() => this.drawChart('line'))
          }
          .indicatorStyle({
            color: '#dbdbdb',
            selectedColor: '#4682B4', // 修改为新颜色
            size: 8
          })
          .index(this.currentIndex)
          .onChange((index: number) => this.currentIndex = index)
          .margin({ bottom: 20 })

          // 数据明细
          Column() {
            ForEach(this.water_info_week.slice().reverse(), (item: WaterClass, index: number) => {
              Row() {
                // 图标区域
                Image($r('app.media.water'))
                  .width('20%')
                  .margin({ right: 0, left: 0 })

                // 数据区域
                Stack() {
                  Row() {
                    // 饮水量
                    Column() {
                      Text('饮水量')
                        .fontSize(18)
                        .fontColor('#666')
                      Text(`${item.water} 毫升`)
                        .fontSize(18)
                        .fontColor('#4682B4') // 修改为新颜色
                        .margin({ right: 8 })
                        .fontWeight(FontWeight.Bold)
                    }
                    .layoutWeight(1)

                  }
                  .width('100%')

                  // 日期
                  Text(this.formatDisplayDate(item.date))
                    .fontSize(14)
                    .fontColor('#999')
                    .position({ x: '70%', y: '5%' })
                }
                .width('75%')
                .height('100%')
                .backgroundColor(Color.White)
                .borderRadius(8)

              }
              .height(90)

              if(index != 6) Divider().strokeWidth(0.5).color('#eee')
            })
          }
          .backgroundColor(Color.White)
          .borderRadius(12)
          .margin({ bottom: 20 })
        }
        .width('100%')
        .padding(10)
      }
      .scrollBar(BarState.Off)
      .expandSafeArea([SafeAreaType.SYSTEM],[SafeAreaEdge.TOP, SafeAreaEdge.BOTTOM])
      .backgroundColor('#ececec')
    }
  }

  // 格式化显示日期
  private formatDisplayDate(dateStr: string): string {
    const date = new Date(dateStr);
    const month = this.monthAbbreviations[date.getMonth()];
    return `${month} ${date.getDate()}, ${date.getFullYear()}`;
  }

  // 绘制图表
  private drawChart(type: string) {
    const ctx = type === 'bar' ? this.context_canvas_bar : this.context_canvas_line
    const canvasWidth = ctx.width
    const canvasHeight = ctx.height - 30
    const maxValue = Math.max(...this.water_data_set.data)
    console.info(`[123]   Width=${canvasWidth}     Height${canvasHeight}  `)

    ctx.clearRect(0, 0, canvasWidth, canvasHeight)
    this.drawMonthLabel(ctx, canvasWidth,type)

    if (type === 'bar') {
      this.drawStackedBarChart(ctx, canvasWidth, canvasHeight, maxValue)
    } else {
      this.drawLineChart(ctx, canvasWidth, canvasHeight, maxValue)
    }

    this.drawDataLabels(ctx, canvasWidth, canvasHeight, maxValue, type)
    this.drawDateLabels(ctx, canvasWidth, canvasHeight)
  }

  // 分层柱状图绘制
  private drawStackedBarChart(ctx: CanvasRenderingContext2D, canvasWidth: number, canvasHeight: number, maxValue: number) {
    const margin = 30
    const totalBars = 7
    const availableWidth = canvasWidth - margin * 2
    const barWidth = Math.min(40, availableWidth / (totalBars * 1.5))
    const spacing = barWidth / 2
    const verticalPadding = 40

    this.water_info_week.forEach((item, i) => {
      const total = item.water || 1 // 避免除零错误
      const x = margin + i * (barWidth + spacing)
      const totalHeight = (total / maxValue) * (canvasHeight - verticalPadding * 2)

      // 控制柱状图的高度动画
      const animatedHeight = (this.animationProgress / 100) * totalHeight; // 根据动画进度计算当前柱状图高度

      // 绘制饮水量条
      ctx.fillStyle = '#4682B4'
      ctx.fillRect(x, canvasHeight - (verticalPadding-25) - animatedHeight, barWidth, animatedHeight)
      // ctx.fillRect(x, canvasHeight - (verticalPadding-25) -totalHeight, barWidth, totalHeight)
    })
  }

  // 绘制图例
  private drawLegend(ctx: CanvasRenderingContext2D, canvasWidth: number) {
    ctx.font = '12px "HarmonyOS Sans"'

    this.legend_items.forEach((item, index) => {
      const x = canvasWidth - 180 + index * 60
      const y = 35

      ctx.fillStyle = item.color
      ctx.fillRect(x, y, 12, 12)

      ctx.fillStyle = '#333'
      ctx.textAlign = 'left'
      const baseSize = canvasWidth / 20;
      const fontSize = Math.max(48, Math.min(72, baseSize * 3));
      ctx.font = `${fontSize}px "HarmonyOS Sans"`;
      ctx.fillText(item.text, x + 16, y + 10)
    })
  }

  // 折线图绘制
  private drawLineChart(ctx: CanvasRenderingContext2D, canvasWidth: number, canvasHeight: number, maxValue: number) {
    const margin = 30
    const verticalPadding = 40

    const chartMaxHeight = canvasHeight - verticalPadding * 2

    const availableWidth_bar = canvasWidth - margin * 2
    const barWidth = availableWidth_bar / (7 * 1.5)

    const pointSpacing = (canvasWidth - margin * 2 - barWidth * 1.5) / 6

    ctx.beginPath()
    ctx.strokeStyle = '#4682B4' // 修改为新颜色
    ctx.lineWidth = 4
    ctx.lineJoin = 'round'

    this.water_info_week.forEach((item, i) => {
      const yPos = canvasHeight - (verticalPadding-25) - (item.water / maxValue) * chartMaxHeight
      const x = margin + i * pointSpacing + barWidth / 2
      const y = yPos + 5

      if (i === 0) {
        ctx.moveTo(x, y)
      } else {
        ctx.lineTo(x, y)
      }
    })
    ctx.stroke()

    this.water_info_week.forEach((item, i) => {
      const yPos = canvasHeight - (verticalPadding-25) - (item.water / maxValue) * chartMaxHeight
      const x = margin + i * pointSpacing + barWidth / 2
      const y = yPos + 5

      ctx.beginPath()
      ctx.arc(x, y, 6, 0, Math.PI * 2)
      ctx.fillStyle = '#4682B4' // 修改为新颜色
      ctx.fill()

      ctx.beginPath()
      ctx.arc(x, y, 4, 0, Math.PI * 2)
      ctx.fillStyle = Color.White
      ctx.fill()
    })
  }

  // 数据标签
  private drawDataLabels(ctx: CanvasRenderingContext2D, canvasWidth: number, canvasHeight: number, maxValue: number, type: string) {
    const margin = 30
    const totalBars = 7
    const availableWidth = canvasWidth - margin * 2
    const barWidth = Math.min(40, availableWidth / (totalBars * 1.5))
    const spacing = barWidth / 2
    const verticalPadding = 40

    ctx.textBaseline = 'middle'
    ctx.textAlign = 'center'

    this.water_info_week.forEach((item, i) => {
      const x = margin + i * (barWidth + spacing) + barWidth / 2
      const total = item.water || 1
      const totalHeight = (total / maxValue) * (canvasHeight - verticalPadding * 2)

      const labelY = canvasHeight - (verticalPadding-25) - totalHeight-10
      const baseSize = canvasWidth / 20;
      const fontSize = Math.max(48, Math.min(72, baseSize * 3));
      ctx.fillStyle = '#4682B4' // 修改为新颜色
      ctx.font = `bold ${fontSize}px \"HarmonyOS Sans\"`;
      ctx.fillText(`${item.water}`, x, labelY)
    })
  }

  // 日期标签
  private drawDateLabels(ctx: CanvasRenderingContext2D, canvasWidth: number, canvasHeight: number) {
    const margin = 30
    const totalBars = 7
    const availableWidth = canvasWidth - margin * 2
    const barWidth = Math.min(40, availableWidth / (totalBars * 1.5))
    const spacing = barWidth / 2
    const verticalPadding = 40

    const baseSize = canvasWidth / 20;
    const fontSize = Math.max(48, Math.min(72, baseSize * 3));
    ctx.font = `${fontSize}px \"HarmonyOS Sans\"`;
    ctx.fillStyle = Color.Black // 使用中性灰提升可读性
    ctx.textBaseline = 'top' // 文字从Y坐标顶部开始绘制
    ctx.textAlign = 'center'

    this.water_info_week.forEach((item, i) => {
      const x = margin + i * (barWidth + spacing) + barWidth / 2
      const date = new Date(item.date)

      const labelY = canvasHeight - (verticalPadding-25)
      ctx.fillText(`${date.getDate()}`, x, labelY)
    })
  }

  // 月份标签
  private drawMonthLabel(ctx: CanvasRenderingContext2D, canvasWidth: number,type:string) {
    if (this.water_info_week.length === 0) return

    const lastDate = new Date(this.water_info_week[6].date)
    const month = this.monthAbbreviations[lastDate.getMonth()]
    const year = lastDate.getFullYear()

    ctx.font = 'bold 90px "HarmonyOS Sans"';
    ctx.fillStyle = Color.Black;
    ctx.textAlign = 'center'
    if(type==='bar') ctx.fillText(`${month} ${year}`, canvasWidth / 2, 0)
    else ctx.fillText(`${month} ${year}`, canvasWidth / 2, 25)

  }

  // 加载动画
  @Builder
  ProgressLoading() {
    Column() {
      Progress({ value: this.loadingProgress, total: 100 })
        .width(80)
        .height(80)
        .color(Color.Green)

      Text(`${Math.floor(this.loadingProgress)}%`)
        .fontSize(18)
        .margin({ top: 12 })
    }
    .onAppear(() => {
      animateTo({ duration: 3000 }, () => this.loadingProgress = 100) // 加入动画效果，3秒内填充到100%
    })
  }


  // 启动柱状图动画
  private startAnimation() {
    // 在此处可以逐步更新进度条
    animateTo({ duration: 300 }, () => {
      this.loadingProgress = 100;  // 更新进度条为100%
      this.animateChartGrowth();   // 启动柱状图动画
    });
  }

  // 控制柱状图逐渐增长
  private animateChartGrowth() {
    const maxValue = Math.max(...this.water_data_set.data);
    const animationInterval = setInterval(() => {
      this.animationProgress += 1; // 每次更新进度
      if (this.animationProgress >= 100) {
        clearInterval(animationInterval); // 动画结束时停止更新
        this.animationProgress = 100;
      }
      // 重新绘制柱状图
      this.drawChart('bar');
    }, 5); // 每30ms更新一次柱状图
  }







}
