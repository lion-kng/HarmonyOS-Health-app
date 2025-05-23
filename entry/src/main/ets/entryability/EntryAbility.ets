// 导入依赖模块
import {
  abilityAccessCtrl,
  AbilityConstant,
  ConfigurationConstant,
  Permissions,
  UIAbility,
  Want
} from '@kit.AbilityKit';  // 基础能力套件

import { hilog } from '@kit.PerformanceAnalysisKit';  // 日志工具
import { AppStorageV2, window } from '@kit.ArkUI';  // 状态管理与窗口管理
import { DataService } from '../data_base/data_base';  // 数据库服务
import { notificationManager } from '@kit.NotificationKit';  // 通知管理
import { BusinessError } from '@kit.BasicServicesKit';  // 错误类型
import { sensor } from '@kit.SensorServiceKit';  // 传感器服务
import { StepClass } from '../entity/step_class';  // 步数数据模型

// 定义日志域标识
const DOMAIN = 0x0000;

// 应用入口能力类
export default class EntryAbility extends UIAbility {
  // 类成员变量
  data_service?: DataService;  // 数据服务实例（可选）
  today: string = new Date().toISOString().split('T')[0];  // 当前日期（ISO格式）
  step_info: StepClass = new StepClass();  // 步数信息对象
  private updateTimer: number | null = null; // 定时器句柄（用于数据更新）

  /**
   * 请求传感器权限
   * @description 处理步数传感器权限请求
   */
  async requestSensorPermission(): Promise<void> {
    try {
      // 创建权限管理器实例
      const atManager = abilityAccessCtrl.createAtManager();

      // 需要申请的权限列表
      const permissions: Array<Permissions> = ['ohos.permission.ACTIVITY_MOTION'];

      // 发起权限请求
      const result = await atManager.requestPermissionsFromUser(this.context, permissions);

      // 处理权限请求结果
      if (result.authResults[permissions[0]] === 0) {
        hilog.info(DOMAIN, 'testTag', '权限申请成功');
        this.initSensor(); // 初始化传感器
      } else {
        hilog.error(DOMAIN, 'testTag', '用户拒绝了权限申请');
        this.initSensor();  // 即使权限被拒绝也尝试初始化传感器
      }
    } catch (err) {
      // 错误处理
      const e: BusinessError = err as BusinessError;
      hilog.error(DOMAIN, 'testTag', `权限申请失败 code:${e.code}, message:${e.message}`);
    }
  }

  /**
   * 初始化传感器
   * @description 配置步数传感器监听
   */
  private initSensor() {
    try {
      // 注册传感器监听器
      sensor.on(sensor.SensorId.PEDOMETER, async (data: sensor.PedometerResponse) => {
        console.info('Succeeded in invoking on. Step count: ' + data.steps);

        // 从AppStorage获取当前步数数据
        this.step_info = AppStorage.get('step_info')!;

        // 更新步数
        this.step_info.step = data.steps

      }, { interval: 10000000000000000 });  // 设置传感器采样间隔

      // 创建定时器（核心修改）
      this.updateTimer = setInterval(async () => {
        try {
          // 定时更新步数数据
          await this.data_service?.step_update_data(this.today, this.step_info);
          // 同步到AppStorage
          AppStorage.set('step_info', this.step_info);
          hilog.info(DOMAIN, 'testTag', '定时数据更新成功');
        } catch (e) {
          // 错误处理
          hilog.error(DOMAIN, 'testTag', `更新失败: ${JSON.stringify(e)}`);
        }
      }, 10000); // 10秒间隔更新
    } catch (error) {
      // 传感器注册错误处理
      let e: BusinessError = error as BusinessError;
      console.error(`Failed to invoke on. Code: ${e.code}, message: ${e.message}`);
    }
  }

  // 应用生命周期方法：创建
  onCreate(want: Want, launchParam: AbilityConstant.LaunchParam): void {
    // 设置颜色模式（未指定）
    this.context.getApplicationContext().setColorMode(ConfigurationConstant.ColorMode.COLOR_MODE_NOT_SET);
    hilog.info(DOMAIN, 'testTag', '%{public}s', 'Ability onCreate');
  }

  // 应用生命周期方法：销毁
  onDestroy(): void {
    // 移除传感器监听
    sensor.off(sensor.SensorId.PEDOMETER);
    hilog.info(DOMAIN, 'testTag', '%{public}s', 'Ability onDestroy');
  }

  /**
   * 窗口创建回调
   * @description 初始化应用核心功能
   */
  async onWindowStageCreate(windowStage: window.WindowStage): Promise<void> {
    // Main window is created, set main page for this ability
    hilog.info(DOMAIN, 'testTag', '%{public}s', 'Ability onWindowStageCreate');

    // 连接数据库服务
    this.data_service = AppStorageV2.connect(DataService, "data_service", () => new DataService(this.context))!;
    // 初始化数据库
    await this.data_service?.initialize();

    // 查询当日步数数据
    this.step_info = await this.data_service.step_query_data(this.today);
    // 存储到AppStorage供其他组件访问
    AppStorage.setOrCreate('step_info', this.step_info);

    // 请求传感器权限
    await this.requestSensorPermission();

    // 加载主页面
    windowStage.loadContent('pages/Main', (err) => {
      if (err.code) {
        hilog.error(DOMAIN, 'testTag', 'Failed to load the content. Cause: %{public}s', JSON.stringify(err));
        return;
      }
      hilog.info(DOMAIN, 'testTag', 'Succeeded in loading the content.');

      // 请求通知权限
      notificationManager.requestEnableNotification(this.context).then(() => {
        hilog.info(0x0000, 'testTag', `[ANS] requestEnableNotification success`);
      }).catch((err: BusinessError) => {
        hilog.error(0x0000, 'testTag', `[ANS] requestEnableNotification failed, code is ${err.code}, message is ${err.message}`);
      });

    });
  }

  // 窗口销毁回调
  onWindowStageDestroy(): void {
    // 主窗口销毁时释放资源
    hilog.info(DOMAIN, 'testTag', '%{public}s', 'Ability onWindowStageDestroy');
  }

  // 应用进入前台回调
  onForeground(): void {
    // 应用转为前台状态
    hilog.info(DOMAIN, 'testTag', '%{public}s', 'Ability onForeground');
  }

  // 应用进入后台回调
  onBackground(): void {
    // 应用转为后台状态
    hilog.info(DOMAIN, 'testTag', '%{public}s', 'Ability onBackground');
  }
}