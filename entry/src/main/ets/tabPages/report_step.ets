import { DataService } from '../data_base/data_base';
import { ChartDateClass } from '../entity/chart_date_class';
import { StepClass } from '../entity/step_class';
import { AppStorageV2 } from '@kit.ArkUI';

@Entry
@Component
struct Report_step {
  // 使用@State装饰器声明组件状态变量，用于响应式更新UI
  @State currentIndex: number = 0
  @State loadingProgress: number = 0
  @State message: string = 'Hello World'
  @State isLoading: boolean = true
  @State animationProgress: number = 0 // 控制柱状图和折线图的动画进度

  // 创建抗锯齿渲染设置对象，用于Canvas初始化
  private settings: RenderingContextSettings = new RenderingContextSettings(true)
  // 创建两个Canvas上下文对象，分别用于绘制柱状图和折线图
  private context_canvas_bar: CanvasRenderingContext2D = new CanvasRenderingContext2D(this.settings)
  private context_canvas_line: CanvasRenderingContext2D = new CanvasRenderingContext2D(this.settings)

  // 月份缩写数组，用于图表X轴显示
  private monthAbbreviations: string[] = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec']

  // 初始化步数图表数据集，包含标题、颜色和默认数据（初始全为100）
  @State step_data_set: ChartDateClass =
    new ChartDateClass('step', '步数周报', '#4CAF50', [100, 100, 100, 100, 100, 100, 100])

  // 获取当前应用上下文并连接数据服务（使用AppStorageV2进行依赖注入）
  context: Context = getContext(this) as Context
  data_service: DataService = AppStorageV2.connect(DataService, "data_service", () => new DataService(this.context))!

  // 存储当前日期字符串（格式：YYYY-MM-DD）
  @State today: string = new Date().toISOString().split('T')[0]

  // 从持久化存储中获取当日步数数据（通过@StorageLink装饰器双向绑定）
  @StorageLink('step_info') step_info: StepClass = new StepClass()

  // 存储本周每日步数数据的数组
  @State step_info_week: StepClass[] = []

  /**
   * 组件即将显示时的生命周期钩子
   * 负责初始化数据加载和动画启动
   */
  async aboutToAppear(): Promise<void> {
    this.isLoading = true // 开启加载状态

    // 1. 加载当日步数数据
    console.info(`[step] 开始获取当天数据`)
    this.step_info = await this.data_service.step_query_data(this.today)

    // 如果当天没有数据则插入默认数据
    if (this.step_info.date === 'default') {
      console.info(`[step] 原来没有数据，插入默认数据`)
      await this.data_service.step_insert_data(this.today)
      this.step_info = await this.data_service.step_query_data(this.today)
    }

    // 2. 加载本周步数数据
    console.info(`[step] 开始获取周数据`)
    this.step_info_week = await this.data_service.step_query_data_week(this.today)
    console.info(`[step] step_info_week_length=${this.step_info_week.length}`)

    // 遍历本周数据，对空数据进行补全
    for (let i = 0; i < this.step_info_week.length; i++) {
      if (this.step_info_week[i].date === 'default') {
        console.info(`[step] 原来没有数据，插入默认数据`)
        await this.data_service.step_insert_data(this.step_info_week[i].date)
        this.step_info_week[i] = await this.data_service.step_query_data(this.step_info_week[i].date)
        console.info(`[step] this.step_info_week=${this.step_info_week[i].date}`)
      }
    }
    console.info(`[step] 获取周数据完毕`)

    // 3. 将周数据转换为图表数据格式
    for(let i=0;i<this.step_info_week.length;i++){
      this.step_data_set.data[i] = this.step_info_week[i].step
    }
    // 打印调试日志
    for(let i=0;i<this.step_info_week.length;i++){
      console.info(`[step] this.step_info_week[${i}]=${this.step_info_week[i].step}`)
    }

    this.isLoading = false // 关闭加载状态

    // 4. 启动图表动画
    this.startAnimation()
  }

  // 被注释的测试数据插入代码
  // 用于快速生成测试数据，实际使用时需删除注释
  /*
  let s:StepClass = new StepClass(this.today,4297,3.29,116)
  this.data_service.step_update_data(this.today,s)

  const date = new Date(this.today);
  date.setDate(date.getDate() - 1);
  let formattedDate = date.toISOString().split('T')[0];
  s=new StepClass(formattedDate,11340,8.19,306)
  this.data_service.step_update_data(formattedDate,s)

  */

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

      // 第二部分：图表展示区域（使用Swiper实现双图表切换）
      Swiper() {
        // 柱状图页面
        Canvas(this.context_canvas_bar)
          .width('100%')           // 宽度占满容器
          .height(420)             // 固定高度420px
          .backgroundColor(Color.White)  // 白色背景
          .borderRadius(10)        // 圆角边框
          .onReady(() => {         // Canvas初始化完成后触发
            this.drawChart('bar')  // 调用绘制方法，指定绘制柱状图
          })

        // 折线图页面
        Canvas(this.context_canvas_line)
          .width('100%')
          .height(420)
          .backgroundColor(Color.White)
          .borderRadius(10)
          .onReady(() => {         // Canvas初始化完成后触发
            this.drawChart('line') // 调用绘制方法，指定绘制折线图
          })
      }
      .autoPlay(false)             // 禁用自动轮播
      .indicatorStyle({            // 自定义指示器样式
        color: '#dbdbdb',          // 未选中时的指示器颜色
        selectedColor: '#4CAF50',  // 选中时的指示器颜色
        size: 8                    // 指示器大小
      })
      .index(this.currentIndex)    // 当前页码绑定到currentIndex状态
      .onChange((index: number) => {  // 页面切换时更新当前索引
        this.currentIndex = index
      })
      .margin({bottom:20})         // 底部留白20px

      // 第三部分：数据详情展示区域
      Column(){
        // 使用ForEach循环渲染每日数据（slice().reverse()实现倒序显示）
        ForEach(this.step_info_week.slice().reverse(), (item: StepClass, index: number) => {
          Row(){
            // 数据项左侧图标
            Image($r('app.media.step'))
              .width('25%')                // 占25%宽度
              .margin({ right: 0, left: 0 }) // 清除左右边距
              .fillColor(Color.Orange)     // 图标填充色为橙色

            // 数据详情区域
            Stack(){
              Row() {
                // 步数列
                Column() {
                  Text('步数')
                    .fontSize(14)            // 小字体
                    .fontColor('#666')       // 灰色文字
                  Text(`${item.step.toLocaleString()}`) // 格式化数字显示
                    .fontSize(20)            // 大字体
                    .fontColor('#4CAF50')    // 主色调绿色
                    .fontWeight(FontWeight.Bold) // 加粗显示
                }
                .layoutWeight(1)             // 布局权重1，平分空间

                // 距离列
                Column() {
                  Text('距离')
                    .fontSize(14)
                    .fontColor('#666')
                  Text(`${item.distance >= 1 ?
                    item.distance.toFixed(1) + 'km' :     // 大于1km显示km
                    (item.distance * 1000).toFixed(0) + 'm'}`) // 小于1km显示米
                    .fontSize(20)
                    .fontColor('#2196F3')    // 蓝色文字
                    .fontWeight(FontWeight.Bold)
                }
                .layoutWeight(1)             // 布局权重1，平分空间

                // 卡路里列
                Column() {
                  Text('卡路里')
                    .fontSize(14)
                    .fontColor('#666')
                  Text(`${item.calorie}kcal`) // 直接显示卡路里数值
                    .fontSize(20)
                    .fontColor('#FF9800')    // 橙色文字
                    .fontWeight(FontWeight.Bold)
                }
                .margin({right:8})           // 右侧留白
                .layoutWeight(1)             // 布局权重1，平分空间
              }//row
              .width('100%')                 // 占满父容器宽度

              // 日期显示
              Text(this.formatDisplayDate(item.date)) // 格式化日期显示
                .fontSize(14)
                .fontColor('#999')           // 浅灰色文字
                .position({ x: '65%', y: '5%' }) // 相对定位在右上区域
            }//stack
            .height('100%')                  // 占满父容器高度
            .width('75%')                   // 占75%宽度
          }//row
          .width('100%')                     // 占满容器宽度
          .height(100)                       // 固定高度
          // .padding(10)                    // 内边距（注释掉备用）
          // .backgroundColor(Color.Pink)   // 背景色（注释掉备用）

          // 添加分割线（最后一个元素不显示）
          if(index!=6) Divider()
        })//ForEach
      }//column
      .backgroundColor(Color.White)        // 整体白色背景
      .borderRadius(15)                    // 圆角边框


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






  /**
   * 进度加载指示器组件
   * 包含带动画的环形进度条和百分比显示
   */
  @Builder
  ProgressLoading() {
    Column() {
      Stack() {
        // 背景圆环（灰色）
        Circle()
          .width(80)
          .height(80)
          .fill(Color.Transparent) // 透明填充
          .stroke('#EEE') // 灰色描边
          .strokeWidth(8) // 描边宽度

        // 动态进度圆环（蓝色）
        Shape() {
          // 使用路径绘制半圆弧
          Path()
            .width(80)
            .height(80)
            .commands(`M-40 0 A40 40 0 1 1 40 0`) // 从左侧开始绘制半圆
        }
        .stroke(Color.Blue) // 蓝色描边
        .fill(Color.Transparent) // 无填充
        .strokeWidth(8) // 描边宽度
        .strokeLineCap(LineCapStyle.Round) // 圆形线端
        // 旋转动画实现进度效果
        .rotate({
          angle: this.loadingProgress * 3.6 - 90, // 将百分比转换为角度（360°对应100%）
          centerX: '50%', // 旋转中心X
          centerY: '50%'  // 旋转中心Y
        })
      }

      // 进度百分比文本
      Text(`${Math.floor(this.loadingProgress)}%`)
        .fontSize(20) // 文字大小
        .margin({ top: 16 }) // 顶部边距
    }
    .onAppear(() => {
      // 组件出现时启动动画
      animateTo({ duration: 1000 }, () =>
      this.loadingProgress = 100 // 1秒内动画到100%
      )
    })
  }

  /**
   * 绘制数据标签（柱状图顶部的数值显示）
   * @param ctx Canvas上下文
   * @param data 数据数组
   * @param canvasWidth 画布宽度
   * @param canvasHeight 画布高度
   * @param type 图表类型（未使用）
   * @param color 文字颜色（未使用）
   */
  private drawDataLabels(
    ctx: CanvasRenderingContext2D,
    data: number[],
    canvasWidth: number,
    canvasHeight: number,
    type: string,
    color: string
  ): void {
    // 计算柱状图布局参数
    const totalBars = data.length;
    const margin = 20;
    const availableWidth = canvasWidth - margin * 2;
    const barWidth = availableWidth / (totalBars * 1.5); // 计算柱宽
    const spacing = barWidth / 2; // 柱间距

    // 动态字体大小计算（放大3倍，范围48-72px）
    const baseSize = canvasWidth / 20;
    const fontSize = Math.max(48, Math.min(72, baseSize * 3));
    ctx.font = `bold ${fontSize}px \"HarmonyOS Sans\"`; // 字体设置
    ctx.textBaseline = 'bottom'; // 文字基线对齐底部
    ctx.textAlign = 'center'; // 水平居中

    const maxValue = Math.max(...data); // 获取最大值用于比例计算

    data.forEach((value, i) => {
      // 计算柱高和文字位置
      const verticalPadding = 40;
      const barHeight = (value / maxValue) * (canvasHeight - verticalPadding * 2);
      const x = margin + i * (barWidth + spacing) + barWidth / 2; // X轴位置
      const labelBottomY = canvasHeight - margin + 15 - barHeight; // 基础Y坐标
      const labelTopY = labelBottomY - fontSize/4; // 向上偏移
      const y = Math.max(margin, labelTopY); // 确保不超出顶部边距

      const text = `${value}`; // 显示数值

      // 动态透明度：高值显示更明显
      ctx.fillStyle = `rgba(38,150,105,${value/maxValue > 0.6 ? 1 : 0.3})`;

      // 添加文字阴影
      ctx.shadowColor = 'rgba(200,200,200,0.4)';
      ctx.shadowBlur = 2;

      // 添加描边提升对比度
      ctx.lineWidth = 3;
      ctx.strokeStyle = 'rgba(0, 0, 0, 0.7)';
      ctx.strokeText(text, x, y); // 先绘制描边

      // 填充文字
      ctx.fillText(text, x, y);
    });
  }

  /**
   * 绘制日期标签（柱状图底部的日期显示）
   * @param ctx Canvas上下文
   * @param data 数据数组
   * @param color 文字颜色
   * @param canvasWidth 画布宽度
   * @param canvasHeight 画布高度
   */
  private drawDateLabels(
    ctx: CanvasRenderingContext2D,
    data: StepClass[],
    color: string,
    canvasWidth: number,
    canvasHeight: number
  ): void {
    ctx.save(); // 保存画布状态

    // 计算布局参数
    const totalBars = data.length;
    const margin = 20;
    const availableWidth = canvasWidth - margin * 2;
    const barWidth = Math.min(40, availableWidth / (totalBars * 1.5)); // 最大40px
    const spacing = barWidth / 2;

    // 字体大小设置（与数据标签保持一致）
    const baseSize = canvasWidth / 20;
    const fontSize = Math.max(48, Math.min(72, baseSize * 3));
    ctx.font = `${fontSize}px \"HarmonyOS Sans\"`; // 字体设置
    ctx.textBaseline = 'top'; // 文字基线对齐顶部
    ctx.textAlign = 'center'; // 水平居中
    ctx.fillStyle = Color.Black; // 黑色文字

    data.forEach((item, i) => {
      if (!item?.date) return; // 跳过无效日期

      // 计算X坐标（柱中心）
      const x = margin + i * (barWidth + spacing) + barWidth / 2;

      // 计算Y坐标（画布底部上方15px）
      const verticalPadding = 15;
      const dateY = canvasHeight - verticalPadding;

      // 提取并格式化日期（去除前导零）
      const day = item.date.split('-')[2];
      const dayPart = day.startsWith('0') ? day[1] : day;

      // 绘制日期文本
      ctx.fillText(dayPart, x, dateY);
    });

    ctx.restore(); // 恢复画布状态
  }

  /**
   * 绘制月份标签（顶部标题）
   * @param ctx - Canvas上下文
   * @param data - 步数数据数组
   * @param color - 文本颜色（未使用）
   * @param canvasWidth - 画布宽度
   */
  private drawMonthLabel(
    ctx: CanvasRenderingContext2D,
    data: StepClass[],
    color: string,
    canvasWidth: number
  ): void {
    ctx.save(); // 保存当前画布状态

    // 过滤出包含有效日期的数据项
    const validDates = data.filter(item => item?.date);
    if (validDates.length === 0) return; // 无有效日期直接返回

    // 获取最后一个有效日期
    const lastValidDate = validDates[validDates.length - 1].date;

    // 解析日期字符串获取年份和月份
    const year = lastValidDate.split('-')[0];
    const monthStr = lastValidDate.split('-')[1];
    const monthIndex = parseInt(monthStr) - 1; // 转换为0索引月份

    // 组合显示文本（月份缩写+年份）
    const displayText = `${this.monthAbbreviations[monthIndex]} ${year}`;

    // 设置文本样式
    ctx.font = 'bold 90px "HarmonyOS Sans"'; // 大字号加粗字体
    ctx.fillStyle = Color.Black; // 黑色填充
    ctx.textAlign = 'center'; // 水平居中对齐
    ctx.textBaseline = 'top'; // 垂直顶部对齐

    // 计算绘制位置（画布顶部中央）
    const x = canvasWidth / 2; // 水平居中
    const y = 0; // 顶部对齐

    // 添加文字阴影效果
    ctx.shadowColor = 'rgba(0,0,0,0.2)';
    ctx.shadowBlur = 4;
    ctx.shadowOffsetY = 2;

    // 绘制文本到画布
    ctx.fillText(displayText, x, y);

    ctx.restore(); // 恢复画布状态
  }

  /**
   * 绘制柱状图
   * @param ctx - Canvas上下文
   * @param data - 数值数据数组
   * @param color - 柱状图颜色
   * @param canvasWidth - 画布宽度
   * @param canvasHeight - 画布高度
   * @param maxValue - 数据最大值（用于比例计算）
   */
  private drawBarChart(
    ctx: CanvasRenderingContext2D,
    data: number[],
    color: string,
    canvasWidth: number,
    canvasHeight: number,
    maxValue: number
  ): void {
    const totalBars = data.length; // 总柱数
    const margin = 20; // 画布边距
    const availableWidth = canvasWidth - margin * 2; // 可用宽度
    const barWidth = availableWidth / (totalBars * 1.5); // 计算柱宽
    const spacing = barWidth / 2; // 柱间距

    data.forEach((value, i) => {
      // 计算柱形X坐标（左侧留白20px）
      const x = 20 + i * (barWidth + spacing);
      ctx.fillStyle = color; // 设置填充颜色

      // 动态计算柱高（带动画进度）
      const verticalPadding = 40;
      const barHeight = (value / maxValue) * (canvasHeight - verticalPadding * 2);
      const animatedHeight = (this.animationProgress / 100) * barHeight; // 动画高度

      // 绘制柱形
      ctx.fillRect(
        x,
        canvasHeight - animatedHeight - (verticalPadding - 25), // Y坐标计算
        barWidth,
        animatedHeight
      );
    });
  }

  /**
   * 绘制折线图
   * @param ctx - Canvas上下文
   * @param data - 数值数据数组
   * @param color - 线条颜色
   * @param canvasWidth - 画布宽度
   * @param canvasHeight - 画布高度
   * @param maxValue - 数据最大值（用于比例计算）
   */
  private drawLineChart(
    ctx: CanvasRenderingContext2D,
    data: number[],
    color: string,
    canvasWidth: number,
    canvasHeight: number,
    maxValue: number
  ): void {
    const totalPoints = data.length; // 数据点数量
    const margin = 20; // 画布边距

    // 计算柱状图相关尺寸（用于确定点间距）
    const availableWidth_bar = canvasWidth - 40; // 水平可用宽度
    const barWidth = availableWidth_bar / (totalPoints * 1.5); // 柱宽计算

    // 计算点间距
    const availableWidth = canvasWidth - margin * 2 - barWidth * 1.5;
    const pointSpacing = availableWidth / (totalPoints - 1);

    const verticalPadding = 40; // 垂直留白

    // 开始绘制折线路径
    ctx.beginPath();
    ctx.strokeStyle = color; // 设置线条颜色
    ctx.lineWidth = 6; // 线宽
    ctx.lineJoin = 'round'; // 圆角连接

    // 绘制折线路径
    data.forEach((value, i) => {
      // 计算点坐标
      const x = margin + barWidth / 2 + i * pointSpacing;
      const height = (value / maxValue) * (canvasHeight - verticalPadding * 2);
      const y = canvasHeight - (verticalPadding - 25) - height + 5;

      if (i === 0) {
        ctx.moveTo(x, y); // 移动到第一个点
      } else {
        ctx.lineTo(x, y); // 连接后续点
      }
    });
    ctx.stroke(); // 绘制折线

    // 绘制数据点
    data.forEach((value, i) => {
      // 计算点坐标
      const x = margin + barWidth / 2 + i * pointSpacing;
      const height = (value / maxValue) * (canvasHeight - verticalPadding * 2);
      const y = canvasHeight - (verticalPadding - 25) - height + 5;

      // 绘制外层圆环
      ctx.beginPath();
      ctx.arc(x, y, 6, 0, Math.PI * 2);
      ctx.fillStyle = color;
      ctx.fill();

      // 绘制内层白点
      ctx.beginPath();
      ctx.arc(x, y, 4, 0, Math.PI * 2);
      ctx.fillStyle = '#FFFFFF';
      ctx.fill();
    });
  }

  /**
   * 通用图表绘制方法
   * @param type - 图表类型 ('bar' 或 'line')
   */
  private drawChart(type: string) {
    // 根据图表类型选择画布上下文
    let ctx = this.context_canvas_bar;
    if (type === 'line') ctx = this.context_canvas_line;

    // 获取画布尺寸（高度减去底部留白）
    const canvasWidth = ctx.width;
    const canvasHeight = ctx.height - 30;

    // 计算数据最大值
    const maxValue = Math.max(...this.step_data_set.data);

    // 清除画布内容
    ctx.clearRect(0, 0, canvasWidth, canvasHeight);

    // 绘制月份标题
    this.drawMonthLabel(ctx, this.step_info_week, this.step_data_set.color, canvasWidth);

    // 绘制主体图表
    if (type === 'bar') {
      // 绘制柱状图
      this.drawBarChart(
        ctx,
        this.step_data_set.data,
        this.step_data_set.color,
        canvasWidth,
        canvasHeight,
        maxValue
      );
    } else {
      // 绘制折线图
      this.drawLineChart(
        ctx,
        this.step_data_set.data,
        this.step_data_set.color,
        canvasWidth,
        canvasHeight,
        maxValue
      );
    }

    // 绘制数据标签
    this.drawDataLabels(
      ctx,
      this.step_data_set.data,
      canvasWidth,
      canvasHeight,
      this.step_data_set.type,
      this.step_data_set.color
    );

    // 绘制日期标签
    this.drawDateLabels(
      ctx,
      this.step_info_week,
      this.step_data_set.color,
      canvasWidth,
      canvasHeight
    );
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
    const maxValue = Math.max(...this.step_data_set.data); // 获取最大数据值
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