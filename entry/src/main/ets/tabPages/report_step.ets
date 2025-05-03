import { DataService } from '../data_base/data_base';
import { ChartDateClass } from '../entity/chart_date_class';
import { StepClass } from '../entity/step_class';
import { AppStorageV2 } from '@kit.ArkUI';

@Entry
@Component
struct Report_step {
  @State currentIndex: number = 0
  @State loadingProgress: number=0
  @State message: string = 'Hello World';
  @State isLoading: boolean = true;
  @State animationProgress: number = 0; // 控制柱状图和折线图的动画进度

  //用来配置CanvasRenderingContext2D对象的参数，包括是否开启抗锯齿，true表明开启抗锯齿。
  private settings: RenderingContextSettings = new RenderingContextSettings(true)
  //用来创建CanvasRenderingContext2D对象，通过在canvas中调用CanvasRenderingContext2D对象来绘制。
  private context_canvas_bar: CanvasRenderingContext2D = new CanvasRenderingContext2D(this.settings)
  private context_canvas_line: CanvasRenderingContext2D = new CanvasRenderingContext2D(this.settings)

  private monthAbbreviations: string[] = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];


  @State step_data_set: ChartDateClass =
    new ChartDateClass('step', '步数周报', '#4CAF50', [100, 100, 100, 100, 100, 100, 100])
  context: Context = getContext(this) as Context
  data_service: DataService = AppStorageV2.connect(DataService, "data_service", () => new DataService(this.context))!
  @State today: string = new Date().toISOString().split('T')[0];
  @StorageLink('step_info') step_info: StepClass = new StepClass()
  @State step_info_week: StepClass[] = []

  async aboutToAppear(): Promise<void> {
    this.isLoading = true

    console.info(`[step] 开始获取当天数据`)
    this.step_info = await this.data_service.step_query_data(this.today)
    if (this.step_info.date === 'default') {
      console.info(`[step] 原来没有数据，插入默认数据`)
      await this.data_service.step_insert_data(this.today)
      this.step_info = await this.data_service.step_query_data(this.today)
    }
    console.info(`[step] 开始获取周数据`)
    this.step_info_week = await this.data_service.step_query_data_week(this.today)
    console.info(`[step] step_info_week_length=${this.step_info_week.length}`)
    for (let i = 0; i < this.step_info_week.length; i++) {
      if (this.step_info_week[i].date === 'default') {
        console.info(`[step] 原来没有数据，插入默认数据`)
        await this.data_service.step_insert_data(this.step_info_week[i].date)
        this.step_info_week[i] = await this.data_service.step_query_data(this.step_info_week[i].date)
        console.info(`[step] this.step_info_week=${this.step_info_week[i].date}`)
      }
    }
    console.info(`[step] 获取周数据完毕`)
    for(let i=0;i<this.step_info_week.length;i++){
      this.step_data_set.data[i] = this.step_info_week[i].step
    }
    for(let i=0;i<this.step_info_week.length;i++){
      console.info(`[step] this.step_info_week[${i}]=${this.step_info_week[i].step}`)
    }



    // let s:StepClass = new StepClass(this.today,4297,3.29,116)
    // this.data_service.step_update_data(this.today,s)
    //
    // const date = new Date(this.today);
    // date.setDate(date.getDate() - 1);
    // let formattedDate = date.toISOString().split('T')[0];
    // s=new StepClass(formattedDate,11340,8.19,306)
    // this.data_service.step_update_data(formattedDate,s)
    //
    // date.setDate(date.getDate() - 1);
    // formattedDate = date.toISOString().split('T')[0];
    // s=new StepClass(formattedDate,14068,1.16,380)
    // this.data_service.step_update_data(formattedDate,s)
    //
    // date.setDate(date.getDate() - 1);
    // formattedDate = date.toISOString().split('T')[0];
    // s=new StepClass(formattedDate,11240,0.44,303)
    // this.data_service.step_update_data(formattedDate,s)
    //
    // date.setDate(date.getDate() - 1);
    // formattedDate = date.toISOString().split('T')[0];
    // s=new StepClass(formattedDate,17926,1.52,484)
    // this.data_service.step_update_data(formattedDate,s)

    // date.setDate(date.getDate() - 1);
    // formattedDate = date.toISOString().split('T')[0];
    // s=new StepClass(formattedDate,7674,1.08,207)
    // this.data_service.step_update_data(formattedDate,s)
    //
    // date.setDate(date.getDate() - 1);
    // formattedDate = date.toISOString().split('T')[0];
    // s=new StepClass(formattedDate,9432,1.37,255)
    // this.data_service.step_update_data(formattedDate,s)

    this.isLoading = false



    // 数据加载完成后，开始柱状图动画
    this.startAnimation()
  }

  build() {
    if (this.isLoading) {
      this.ProgressLoading() // 显示加载动画
    }
    else{
      Scroll(){





    Column() {

      //第一部分某某周报
      Text(this.step_data_set.title)
        .fontSize(24)
        .margin({ bottom: 10 })
        .fontColor(this.step_data_set.color)
        .fontWeight(FontWeight.Bold)
        // .backgroundColor(Color.Yellow)



      // 关键修改：为每个 Canvas 创建独立的 context
      // const chartContext = new CanvasRenderingContext2D(this.settings);

      //第二部分图标
      Swiper() {
        // 柱状图页
        Canvas(this.context_canvas_bar)
          .width('100%')
          .height(420)
          .backgroundColor(Color.White)
          .borderRadius(10)
          .onReady(() => {
            this.drawChart('bar') // 修改绘制方式
          })

        // 折线图页
        Canvas(this.context_canvas_line)
          .width('100%')
          .height(420)
          .backgroundColor(Color.White)
          .borderRadius(10)
          .onReady(() => {
            this.drawChart('line') // 修改绘制方式
          })
      }
      .autoPlay(false)
      .indicatorStyle({
        // color: '#4CAF50',
        color: '#dbdbdb',
        selectedColor: '#4CAF50',
        size: 8
      })
      .index(this.currentIndex)
      .onChange((index: number) => {
        this.currentIndex = index
      })
      .margin({bottom:20})


      //第三部分 介绍


      Column(){
        ForEach(this.step_info_week.slice().reverse(), (item: StepClass, index: number) => {
          Row(){
            Image($r('app.media.step'))
              .width('25%')
              .margin({ right: 0, left: 0 })
              .fillColor(Color.Orange)
              // .backgroundColor(Color.Red)

            Stack(){
              Row() {
                // 步数
                Column() {
                  Text('步数')
                    .fontSize(14)
                    .fontColor('#666')
                  Text(`${item.step.toLocaleString()}`)
                    .fontSize(20)
                    .fontColor('#4CAF50')
                    .fontWeight(FontWeight.Bold)
                }
                // .backgroundColor(Color.White)
                .layoutWeight(1)
                // .margin({ right: 5 })

                // 距离（动态单位）
                Column() {
                  Text('距离')
                    .fontSize(14)
                    .fontColor('#666')
                  Text(`${item.distance >= 1 ?
                    item.distance.toFixed(1) + 'km' :
                    (item.distance * 1000).toFixed(0) + 'm'}`)
                    .fontSize(20)
                    .fontColor('#2196F3')
                    .fontWeight(FontWeight.Bold)
                }
                // .backgroundColor(Color.Grey)
                .layoutWeight(1)
                // .margin({ right: 5 })

                // 卡路里
                Column() {
                  Text('卡路里')
                    .fontSize(14)
                    .fontColor('#666')
                  Text(`${item.calorie}kcal`)
                    .fontSize(20)
                    .fontColor('#FF9800')
                    .fontWeight(FontWeight.Bold)
                }
                .margin({right:8})
                // .backgroundColor(Color.Blue)
                .layoutWeight(1)
              }//row
              .width('100%')

              Text(this.formatDisplayDate(item.date))
                .fontSize(14)
                .fontColor('#999')
                // .margin({ top: 8, right: 8 }) // 调整间距
                .position({ x: '65%', y: '5%' }) // 关键定位属性
                // .align(Alignment.TopEnd) // 对齐方式
                // .width('100%') // 占满容器宽度


            }//stack
            .height('100%')
            .width('75%')
            // .backgroundColor(Color.Pink)






          }//row
          .width('100%')
          .height(100)
          // .padding(10)
          // .backgroundColor(Color.Brown)
          // .borderRadius(12)
          // .shadow({ radius: 4, color: '#20000000', offsetX: 1, offsetY: 1 })






          if(index!=6) Divider()

        })//ForEach
      }//column
      .backgroundColor(Color.White)
      .borderRadius(15)



    }//column
    .width('100%')
    .padding(10)
    // .height('100%')




      }//scroll
      .scrollBar(BarState.Off) // 隐藏滚动条
      .height('100%')
      .width('100%')
      .expandSafeArea([SafeAreaType.SYSTEM],[SafeAreaEdge.TOP, SafeAreaEdge.BOTTOM])
      .backgroundColor('#ececec')


   }//else
  }//build






  @Builder
  ProgressLoading() {
    Column() {
      Stack() {
        // 背景圆环
        Circle()
          .width(80)
          .height(80)
          .fill(Color.Transparent)
          .stroke('#EEE')
          .strokeWidth(8)

        // 进度圆环
        // 替换原Circle进度环代码
        Shape() {
          Path()
            .width(80)
            .height(80)
            .commands(`M-40 0 A40 40 0 1 1 40 0`) // 基础圆弧路径
        }
        .stroke(Color.Blue)
        .fill(Color.Transparent)
        .strokeWidth(8)
        .strokeLineCap(LineCapStyle.Round)
        // 添加旋转动画
        .rotate({
          angle: this.loadingProgress * 3.6 - 90, // 将进度转换为旋转角度
          centerX: '50%',
          centerY: '50%'
        })
      }

      Text(`${Math.floor(this.loadingProgress)}%`)
        .fontSize(20)
        .margin({ top: 16 })
    }
    .onAppear(() => {
      animateTo({ duration: 1000 }, () => this.loadingProgress = 100)
    })
  }



  private drawDataLabels(ctx: CanvasRenderingContext2D, data: number[],
    canvasWidth: number, canvasHeight: number, type: string, color: string): void {

    // 计算柱状参数
    const totalBars = data.length;
    const margin = 20;
    const availableWidth = canvasWidth - margin * 2;
    // const barWidth = Math.min(40, availableWidth / (totalBars * 1.5));
    const barWidth = availableWidth / (totalBars * 1.5)
    const spacing = barWidth / 2;


    // 动态设置字体大小，放大3倍（基于初始大小16–24px，共48–72px）
    const baseSize = canvasWidth / 20;
    const fontSize = Math.max(48, Math.min(72, baseSize * 3));
    ctx.font = `bold ${fontSize}px \"HarmonyOS Sans\"`;
    ctx.textBaseline = 'bottom';
    ctx.textAlign = 'center';

    const maxValue = Math.max(...data);


    // 日期标签参数
    // const dateFontSize = fontSize / 1.5; // 日期字体稍小
    // ctx.font = `${dateFontSize}px \"HarmonyOS Sans\"`;
    // ctx.textBaseline = 'top'; // 日期文字基线对齐顶部

    data.forEach((value, i) => {
      // 计算文字位置：在柱顶上方留出一定间距
      // const barHeight = (value / maxValue) * (canvasHeight - margin * 2);
      const verticalPadding = 40
      const barHeight = (value / maxValue) * (canvasHeight - verticalPadding * 2);

      const x = margin + i * (barWidth + spacing) + barWidth / 2;

      const labelBottomY = canvasHeight - margin+15 - barHeight ; // 10为下标日期的高度
      const labelTopY = labelBottomY - fontSize/4 ;
      const y = Math.max(margin, labelTopY);
      console.info(`[height]   y=${y}  margin=${margin}  labelTopY=${labelTopY}`)
      // const minY = margin + fontSize; // 最小显示位置
      // const baseY = canvasHeight - margin - barHeight;
      //
      //
      // // const y = canvasHeight - margin - barHeight - (fontSize / 4);
      // const y = Math.max(minY, baseY - (fontSize / 8));
      const text = `${value}`; // 仅显示数字


      // 增加动态透明度处理
      ctx.fillStyle = `rgba(38,150,105,${value/maxValue > 0.6 ? 1 : 0.3})`;
      // 增加文字阴影
      // ctx.shadowColor = 'rgba(240,240,240,0.9)';
      // ctx.shadowColor = 'rgba(100,100,100,0.7)';
      ctx.shadowColor = 'rgba(200,200,200,0.4)';
      ctx.shadowBlur = 2;

      // 添加描边提升对比度
      ctx.lineWidth = 3;
      ctx.strokeStyle = 'rgba(0, 0, 0, 0.7)';
      ctx.strokeText(text, x, y);

      // 填充文字
      // ctx.fillStyle = '#FFFFFF';
      ctx.fillText(text, x, y);







    });
  }

  private drawDateLabels(
    ctx: CanvasRenderingContext2D,
    data: StepClass[],
    color: string,
    canvasWidth: number,
    canvasHeight: number
  ): void {
    // 保存原始绘图状态
    ctx.save();

    // 基础参数计算
    const totalBars = data.length;
    const margin = 20;
    const availableWidth = canvasWidth - margin * 2;
    const barWidth = Math.min(40, availableWidth / (totalBars * 1.5));
    const spacing = barWidth / 2;


    // 动态字体设置（比数据标签小1/3）
    const baseSize = canvasWidth / 20;
    const fontSize = Math.max(48, Math.min(72, baseSize * 3));
    ctx.font = `${fontSize}px \"HarmonyOS Sans\"`;
    ctx.textBaseline = 'top';
    ctx.textAlign = 'center';
    ctx.fillStyle = Color.Black;

    data.forEach((item, i) => {
      if (!item?.date) return;

      // 计算柱体中心X坐标
      const x = margin + i * (barWidth + spacing) + barWidth / 2;

      // 计算日期标签Y坐标（柱底下方10px）
      // const dateY = canvasHeight - 30 + 0; // 与drawBarChart的30px留空对齐
      const verticalPadding = 15;
      const dateY = canvasHeight - verticalPadding ; // 底部留空区上方10px
      // 提取日期中的日部分
      const day = item.date.split('-')[2];
      const dayPart= day.startsWith('0') ? day[1] : day;
      ctx.fillText(dayPart, x, dateY);
    });

    // 恢复原始状态
    ctx.restore();
  }



  // 绘制月份方法
  private drawMonthLabel(
    ctx: CanvasRenderingContext2D,
    data: StepClass[],
    color: string,
    canvasWidth: number
  ): void {
    ctx.save();

    // 获取最后一个有效日期的年月（修改点）
    const validDates = data.filter(item => item?.date);
    if (validDates.length === 0) return;
    const lastValidDate = validDates[validDates.length - 1].date;

    // 解析日期
    // const [year, monthStr] = lastValidDate.split('-');
    const year=lastValidDate.split('-')[0];
    const monthStr=lastValidDate.split('-')[1];
    const monthIndex = parseInt(monthStr) - 1;

    // 组合显示文本
    const displayText = `${this.monthAbbreviations[monthIndex]} ${year}`;

    // 设置样式（保持不变）
    ctx.font = 'bold 90px "HarmonyOS Sans"';
    ctx.fillStyle = Color.Black;
    ctx.textAlign = 'center';
    ctx.textBaseline = 'top';

    // 计算位置（画布顶部中央）
    const x = canvasWidth / 2;
    const y = 0;
    // const verticalPadding = 40;
    // const y = verticalPadding / 2;

    // 添加文字阴影
    ctx.shadowColor = 'rgba(0,0,0,0.2)';
    ctx.shadowBlur = 4;
    ctx.shadowOffsetY = 2;

    // 绘制文本
    ctx.fillText(displayText, x, y);

    ctx.restore();
  }


  // 新增方法：绘制柱状图
  private drawBarChart(
    ctx: CanvasRenderingContext2D,
    data: number[],
    color: string,
    canvasWidth: number,
    canvasHeight: number,
    maxValue: number
  ): void {
    const totalBars = data.length;
    const margin = 20;
    const availableWidth = canvasWidth - margin * 2;
    const barWidth = availableWidth / (totalBars * 1.5);
    const spacing = barWidth / 2;

    data.forEach((value, i) => {
      const x = 20 + i * (barWidth + spacing); // 左侧留出20px边距
      ctx.fillStyle = color;

      // 动态控制柱状图的高度
      const verticalPadding = 40;
      const barHeight = (value / maxValue) * (canvasHeight - verticalPadding * 2);
      const animatedHeight = (this.animationProgress / 100) * barHeight; // 依据动画进度调整高度

      ctx.fillRect(x, canvasHeight - animatedHeight - (verticalPadding - 25), barWidth, animatedHeight); // 更新绘制位置
    });
  }



  // 折线图绘制方法
  private drawLineChart(ctx: CanvasRenderingContext2D, data: number[], color: string,
    canvasWidth: number, canvasHeight: number, maxValue: number): void {

    const totalPoints = data.length
    const margin = 20

    const availableWidth_bar = canvasWidth - 40; // 留出左右边距
    const barWidth = availableWidth_bar / (totalPoints * 1.5) // 按比例计算

    const availableWidth = canvasWidth - margin * 2-barWidth*1.5
    const pointSpacing = availableWidth / (totalPoints - 1)

    const verticalPadding = 40

    // const totalBars = data.length;
    // const availableWidth = canvasWidth - 40; // 留出左右边距

    // const spacing = barWidth / 2; // 间距为柱宽一半

    // 第一步：绘制连线路径
    ctx.beginPath()
    ctx.strokeStyle = color
    ctx.lineWidth = 6
    ctx.lineJoin = 'round'


    data.forEach((value, i) => {

      const x = margin + barWidth/2 + i * pointSpacing
      const height=(value / maxValue) * (canvasHeight - verticalPadding * 2)
      const y = canvasHeight - (verticalPadding-25) - height+5


      if (i === 0) {
        ctx.moveTo(x, y)
      } else {
        ctx.lineTo(x, y)
      }
    })
    ctx.stroke() // 先完成路径绘制

    // 第二步：单独绘制数据点
    data.forEach((value, i) => {
      const x = margin + barWidth/2 + i * pointSpacing
      const height=(value / maxValue) * (canvasHeight - verticalPadding * 2)
      const y = canvasHeight - (verticalPadding-25) - height+5
      // 外层圆环
      ctx.beginPath()
      ctx.arc(x, y, 6, 0, Math.PI * 2)
      ctx.fillStyle = color
      ctx.fill()

      // 内层白点
      ctx.beginPath()
      ctx.arc(x, y, 4, 0, Math.PI * 2)
      ctx.fillStyle = '#FFFFFF'
      ctx.fill()
    })
  }


  // 通用绘制方法
  private drawChart(type: string) {
    let ctx = this.context_canvas_bar;
    if (type === 'line') ctx = this.context_canvas_line;

    const canvasWidth = ctx.width;
    const canvasHeight = ctx.height - 30;
    const maxValue = Math.max(...this.step_data_set.data);

    ctx.clearRect(0, 0, canvasWidth, canvasHeight);
    this.drawMonthLabel(ctx, this.step_info_week, this.step_data_set.color, canvasWidth);

    if (type === 'bar') {
      this.drawBarChart(ctx, this.step_data_set.data, this.step_data_set.color, canvasWidth, canvasHeight, maxValue);
    } else {
      this.drawLineChart(ctx, this.step_data_set.data, this.step_data_set.color, canvasWidth, canvasHeight, maxValue);
    }

    this.drawDataLabels(ctx, this.step_data_set.data, canvasWidth, canvasHeight, this.step_data_set.type, this.step_data_set.color);
    this.drawDateLabels(ctx, this.step_info_week, this.step_data_set.color, canvasWidth, canvasHeight);
  }






  private formatDisplayDate(dateStr: string): string {
    const date = new Date(dateStr);
    const month = this.monthAbbreviations[date.getMonth()];
    return `${month} ${date.getDate()}, ${date.getFullYear()}`;
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
    const maxValue = Math.max(...this.step_data_set.data);
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