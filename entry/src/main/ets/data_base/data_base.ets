import { relationalStore } from "@kit.ArkData";
import { common } from "@kit.AbilityKit";
import {Context} from "@ohos.arkui.UIContext"
import { BusinessError } from "@kit.BasicServicesKit";
import { StepClass } from "../entity/step_class";
import { SleepClass } from "../entity/sleep_class";
import { WaterClass } from "../entity/water_class";
import { TargetClass } from "../entity/target_class";


export class DataService {

  // 关系型数据库存储实例，用于执行数据库操作
  // 初始状态为undefined，在initialize()方法中完成初始化
  private store: relationalStore.RdbStore | undefined = undefined;

  // 应用上下文对象，用于获取应用运行环境信息
  // 通过构造函数注入，主要用于数据库的创建和路径获取
  private context: Context

  /**
   * 构造函数，初始化数据服务实例
   * @param context 应用上下文对象，从Ability或UI组件传递
   * 该上下文将用于数据库的创建和操作
   */
  constructor(context: Context) {
    this.context = context // 注入上下文依赖
  }

  /**
   * 数据库初始化方法
   * @description 初始化数据库并创建所有需要的表
   */
  async initialize(){
    try{
      console.info(`初始化数据库`)
      // 创建关系型数据库存储
      await this.creat_rdb_store()
      // 创建步数数据表
      await this.creat_step_table()
      // 创建睡眠数据表
      await this.creat_sleep_table()
      // 创建饮水数据表
      await this.creat_water_table()
      // 创建目标设置表
      await this.create_target_table()

    }catch (err) {
      // 错误处理
      console.error(`Database init failed: ${err.message}`);
    }
  }

  /**
   * 删除目标表（开发调试用）
   * @description 用于开发过程中清理数据库结构
   * @warning 实际生产环境不应使用此方法
   */
  async deleteTargetTable(): Promise<void> {
    console.info('[目标表] 开始删除表');

    if (!this.store) {
      console.error('[目标表] 数据库未初始化');
      return;
    }

    try {
      // 使用 DROP TABLE 语句彻底删除表
      await this.store.executeSql("DROP TABLE IF EXISTS target_table");
      console.info('[目标表] 表删除成功');
    } catch (err) {
      // 错误处理
      console.error(`[目标表] 删除失败: ${(err as BusinessError).message}`);
      throw new Error(`目标表删除失败: ${(err as BusinessError).message}`);
    }
  }

  /**
   * 创建关系型数据库存储
   * @description 初始化RDB存储实例
   */
  async creat_rdb_store() : Promise<void>{
    try {
      console.info(`[test]  开始创建数据库`);

      // 数据库配置
      const STORE_CONFIG: relationalStore.StoreConfig = {
        name: "RdbTest.db",  // 数据库名称
        securityLevel: relationalStore.SecurityLevel.S3  // 安全等级S3
      };

      console.info(`[test]开始创建数据库1`);

      // 检查上下文有效性
      if (!this.context) {
        throw new Error("[test]数据 context is undefined");
      }

      // 创建/获取数据库实例
      this.store = await relationalStore.getRdbStore(this.context, STORE_CONFIG);
      console.info(`[test]数据   创建数据库成功`);
      // 输出调试信息
      console.info(`[DEBUG] 数据库路径：${this.context.databaseDir}`);

    } catch (e) {
      // 错误处理
      console.error("创建数据库失败:", e);
      // throw e; // 将错误抛出，让 initialize() 的 catch 捕获
    }
  }

  /**
   * 升级步数表结构（开发调试用）
   * @description 添加distance和calorie字段到步数表
   * @warning 实际应用应通过版本控制进行表升级
   */
  async upgradeStepTable():Promise<void>{
    if (!this.store) {
      throw new Error("[test]数据库未创建，无法建表");
    }
    try {
      // 添加distance列（REAL类型，浮点数）
      await this.store.executeSql("ALTER TABLE step_table ADD COLUMN distance REAL DEFAULT 0.0");

      // 添加calorie列（INTEGER类型，整数）
      await this.store.executeSql("ALTER TABLE step_table ADD COLUMN calorie INTEGER DEFAULT 0");

    } catch (err) {
      // 错误处理
      console.error("表结构升级失败:", err);
    }
  }
  /**
   * 创建目标设置表
   * @description 存储用户健康目标数据
   */
  async create_target_table(): Promise<void> {
    // 检查数据库连接有效性
    if (!this.store) {
      throw new Error("[test]数据库未创建，无法建表");
    }

    // 建表SQL语句
    const createTableSql = `
  CREATE TABLE IF NOT EXISTS target_table (
    id INTEGER PRIMARY KEY AUTOINCREMENT,  // 主键
    step_target INTEGER DEFAULT 0,         // 步数目标（单位：步）
    distance_target REAL DEFAULT 0.0,      // 距离目标（单位：千米）
    calorie_target INTEGER DEFAULT 0,       // 卡路里目标（单位：千卡）
    sleep_target INTEGER DEFAULT 0,         // 总睡眠目标（单位：分钟）
    deep_target INTEGER DEFAULT 0,          // 深度睡眠目标（单位：分钟）
    light_target INTEGER DEFAULT 0,         // 浅度睡眠目标（单位：分钟）
    rem_target INTEGER DEFAULT 0,           // REM睡眠目标（单位：分钟）
    water_target INTEGER DEFAULT 0,         // 饮水目标（单位：毫升）
    water_interval INTEGER DEFAULT 10       // 杯子容量
  )`;

    try {
      // 执行建表操作
      await this.store.executeSql(createTableSql);
      console.log('Target table created successfully');
    } catch (err) {
      // 错误处理
      console.error(`Failed to create table, error: ${err}`);
      throw new Error('Database creation failed');
    }
  }

  /**
   * 创建步数数据表
   * @description 存储每日步数相关数据
   */
  async creat_step_table(): Promise<void> {
    // 检查数据库连接有效性
    if (!this.store) {
      throw new Error("[test]数据库未创建，无法建表");
    }

    // 建表SQL语句
    const sql_creat = `CREATE TABLE IF NOT EXISTS step_table (
    id INTEGER PRIMARY KEY AUTOINCREMENT,  // 主键
    date TEXT NOT NULL UNIQUE,            // 日期标识（格式：YYYY-MM-DD）
    step INTEGER DEFAULT 0,               // 步数（单位：步）
    distance REAL DEFAULT 0.0,            // 距离（单位：千米）
    calorie INTEGER DEFAULT 0             // 卡路里（单位：千卡）
  )`;

    try {
      // 执行建表操作
      await this.store.executeSql(sql_creat);
      console.info('[test]数据   Create table successfully.');
    } catch (err) {
      // 错误处理
      console.error(`[test]数据   creat table failed: ${err.message}`);
      //throw err;  // 当前未抛出错误
    }
  }

  /**
   * 创建睡眠数据表
   * @description 存储每日睡眠详细数据
   */
  async creat_sleep_table(): Promise<void> {
    // 检查数据库连接有效性
    if (!this.store) {
      throw new Error("数据库未创建，无法建表");
    }

    // 建表SQL语句
    const sql_creat = `CREATE TABLE IF NOT EXISTS sleep_table (
    id INTEGER PRIMARY KEY AUTOINCREMENT,  // 主键
    date TEXT NOT NULL UNIQUE,            // 日期标识（格式：YYYY-MM-DD）
    sleep INTEGER DEFAULT 0,              // 睡眠总时长（单位：分钟）
    wake INTEGER DEFAULT 0,               // 清醒次数
    deep INTEGER DEFAULT 0,               // 深度睡眠时长（单位：分钟）
    light INTEGER DEFAULT 0,              // 浅度睡眠时长（单位：分钟）
    rem INTEGER DEFAULT 0                 // REM睡眠时长（单位：分钟）
  )`;

    try {
      // 执行建表操作
      await this.store.executeSql(sql_creat);
      console.info('数据   Create table successfully.');
    } catch (err) {
      // 错误处理
      console.error(`数据   creat table failed: ${err.message}`);
      //throw err;  // 当前未抛出错误
    }
  }

  /**
   * 创建饮水数据表
   * @description 存储每日饮水记录
   */
  async creat_water_table(): Promise<void> {
    // 检查数据库连接有效性
    if (!this.store) {
      throw new Error("数据库未创建，无法建表");
    }

    // 建表SQL语句
    const sql_creat = `CREATE TABLE IF NOT EXISTS water_table (
    id INTEGER PRIMARY KEY AUTOINCREMENT,  // 主键
    date TEXT NOT NULL UNIQUE,            // 日期标识（格式：YYYY-MM-DD）
    water INTEGER DEFAULT 0               // 当日饮水量（单位：毫升）
  )`;

    try {
      // 执行建表操作
      await this.store.executeSql(sql_creat);
      console.info('数据   Create table successfully.');
    } catch (err) {
      // 错误处理
      console.error(`数据   creat table failed: ${err.message}`);
      //throw err;  // 当前未抛出错误
    }
  }

  /**
   * 插入目标设置数据
   * @description 初始化目标表数据（仅当表为空时）
   * @note 该方法仅在首次运行时插入默认数据
   */
  async target_insert_data(): Promise<void> {
    console.info('[target] 开始插入');

    // 检查数据库连接有效性
    if (!this.store) {
      console.error('[target] 数据库未初始化');
      return;
    }

    try {
      // 创建ID=1的查询条件（目标表仅存储一组配置）
      const predicates = new relationalStore.RdbPredicates("target_table");
      predicates.equalTo("id", 1);

      // 查询现有数据
      const resultSet = await this.store.query(predicates, ["id"]);

      // 如果没有数据则插入默认值
      if (resultSet.rowCount === 0) {
        const valueBucket: relationalStore.ValuesBucket = {
          step_target: 0,         // 默认步数目标
          distance_target: 0.0,    // 默认距离目标
          calorie_target: 0,       // 默认卡路里目标
          sleep_target: 0,         // 默认总睡眠目标
          deep_target: 0,          // 默认深度睡眠目标
          light_target: 0,         // 默认浅度睡眠目标
          rem_target: 0,           // 默认REM睡眠目标
          water_target: 0,         // 默认饮水目标
          water_interval: 100      // 默认饮水间隔
        };

        await this.store.insert("target_table", valueBucket);
        console.info('[target] 插入数据：' + JSON.stringify(valueBucket))
      } else {
        console.info('[target] 已有数据，跳过插入');
      }
    } catch (err) {
      // 错误处理
      console.error(`[target] 操作失败: ${(err as BusinessError).message}`);
      throw new Error(`[target]  目标数据插入失败: ${(err as BusinessError).message}`);
    }
  }

  /**
   * 插入步数默认数据
   * @description 当指定日期无数据时插入默认记录
   * @param today - 需要插入的日期（ISO格式）
   */
  async step_insert_data(today: string): Promise<void> {
    console.info(`[步数数据] 开始插入 ${today}`);

    // 检查数据库连接
    if (!this.store) {
      console.error('[步数数据] 数据库未初始化');
      return;
    }

    try {
      // 构建日期查询条件
      const predicates = new relationalStore.RdbPredicates("step_table");
      predicates.equalTo("date", today);  // 按日期查询

      // 执行查询
      const resultSet = await this.store.query(predicates, ["id"]);

      // 如果没有当天数据则插入
      if (resultSet.rowCount === 0) {
        const valueBucket: relationalStore.ValuesBucket = {
          "date": today,  // 当前日期
          "step": 0,      // 初始步数
          "distance":0.0, // 初始距离
          "calorie":0     // 初始卡路里
        };

        await this.store.insert("step_table", valueBucket);
        console.info(`[步数数据] 初始化记录成功: ${JSON.stringify(valueBucket)}`);
      }
    } catch (err) {
      // 错误处理
      console.error(`[步数数据] 插入失败: ${(err as BusinessError).message}`);
      throw new Error(`数据插入失败: ${(err as BusinessError).message}`);
    }
  }

  /**
   * 插入睡眠默认数据
   * @description 当指定日期无数据时插入默认记录
   * @param today - 需要插入的日期（ISO格式）
   */
  async sleep_insert_data(today: string): Promise<void> {
    console.info(`[睡眠数据] 开始插入 ${today}`);

    // 检查数据库连接
    if (!this.store) {
      console.error('[睡眠数据] 数据库未初始化');
      return;
    }

    try {
      // 构建日期查询条件
      const predicates = new relationalStore.RdbPredicates("sleep_table");
      predicates.equalTo("date", today);  // 按日期查询

      // 执行查询
      const resultSet = await this.store.query(predicates, ["id"]);

      // 如果没有当天数据则插入
      if (resultSet.rowCount === 0) {
        const valueBucket: relationalStore.ValuesBucket = {
          "date": today,   // 当前日期
          "sleep": 0,      // 总睡眠时长
          "wake": 0,       // 清醒次数
          "deep": 0,       // 深度睡眠时长
          "light": 0,      // 浅度睡眠时长
          "rem": 0        // REM睡眠时长
        };

        await this.store.insert("sleep_table", valueBucket);
        console.info(`[睡眠数据] 初始化记录成功: ${JSON.stringify(valueBucket)}`);
      }
    } catch (err) {
      // 错误处理
      console.error(`[睡眠数据] 插入失败: ${(err as BusinessError).message}`);
      throw new Error(`睡眠数据插入失败: ${(err as BusinessError).message}`);
    }
  }

  /**
   * 插入饮水默认数据
   * @description 当指定日期无数据时插入默认记录
   * @param today - 需要插入的日期（ISO格式）
   */
  async water_insert_data(today: string): Promise<void> {
    console.info(`[饮水数据] 开始插入 ${today}`);

    // 检查数据库连接
    if (!this.store) {
      console.error('[饮水数据] 数据库未初始化');
      return;
    }

    try {
      // 构建日期查询条件
      const predicates = new relationalStore.RdbPredicates("water_table");
      predicates.equalTo("date", today);  // 按日期查询

      // 执行查询
      const resultSet = await this.store.query(predicates, ["id"]);

      // 如果没有当天数据则插入
      if (resultSet.rowCount === 0) {
        const valueBucket: relationalStore.ValuesBucket = {
          "date": today,   // 当前日期
          "water": 0      // 初始饮水量
        };

        await this.store.insert("water_table", valueBucket);
        console.info(`[饮水数据] 初始化记录成功: ${JSON.stringify(valueBucket)}`);
      }
    } catch (err) {
      // 错误处理
      console.error(`[饮水数据] 插入失败: ${(err as BusinessError).message}`);
      throw new Error(`饮水数据插入失败: ${(err as BusinessError).message}`);
    }
  }


  /**
   * 查询目标设置数据
   * @description 查询全局健康目标数据（仅一条记录）
   * @returns TargetClass - 目标数据对象
   */
  async target_query_data(): Promise<TargetClass> {
    const targetInfo = new TargetClass();  // 初始化默认数据对象

    // 检查数据库连接有效性
    if (!this.store) {
      console.error('[目标数据] 数据库未初始化');
      return targetInfo;
    }

    try {
      // 构建查询条件（ID=1）
      const predicates = new relationalStore.RdbPredicates("target_table");
      predicates.equalTo("id", 1);

      // 执行全字段查询
      const resultSet = await this.store.query(predicates, ["*"]);

      // 处理查询结果
      switch (resultSet.rowCount) {
        case 0:  // 无数据情况
          console.warn('[target] 未找到记录，返回默认值');
          await this.target_insert_data()  // 自动插入默认数据（当前未等待插入结果）
          break;

        case 1:  // 正常情况
          resultSet.goToFirstRow();  // 移动到第一行
          // 读取各字段数据
          targetInfo.step_target = resultSet.getLong(resultSet.getColumnIndex("step_target"));
          targetInfo.distance_target = resultSet.getDouble(resultSet.getColumnIndex("distance_target"));
          targetInfo.calorie_target = resultSet.getLong(resultSet.getColumnIndex("calorie_target"));
          targetInfo.sleep_target = resultSet.getLong(resultSet.getColumnIndex("sleep_target"));
          targetInfo.deep_target = resultSet.getLong(resultSet.getColumnIndex("deep_target"));
          targetInfo.light_target = resultSet.getLong(resultSet.getColumnIndex("light_target"));
          targetInfo.rem_target = resultSet.getLong(resultSet.getColumnIndex("rem_target"));
          targetInfo.water_target = resultSet.getLong(resultSet.getColumnIndex("water_target"));
          targetInfo.water_interval = resultSet.getLong(resultSet.getColumnIndex("water_interval"));
          console.info(`[target] 查询数据成功：${JSON.stringify(targetInfo)}`)
          break;

        default:  // 异常情况
          console.error(`[target] 查询中 发现异常记录数: ${resultSet.rowCount} 返回默认值`);
        // 当前未实现多记录处理逻辑
          break;
      }
    } catch (err) {
      // 错误处理
      console.error(`[target] 查询失败: ${(err as BusinessError).message}`);
    }

    return targetInfo;
  }

  /**
   * 查询步数数据
   * @description 根据日期查询步数记录
   * @param today - 查询日期（ISO格式）
   * @returns StepClass - 步数数据对象
   */
  async step_query_data(today: string): Promise<StepClass> {
    console.info(`[步数数据] 开始查询 ${today}`);
    const stepInfo = new StepClass();  // 初始化默认数据

    // 检查数据库连接
    if (!this.store) {
      console.error('[步数数据] 数据库未初始化');
      return stepInfo;
    }

    try {
      // 构建日期查询条件
      const predicates = new relationalStore.RdbPredicates("step_table");
      predicates.equalTo("date", today);  // 按日期查询

      // 执行全字段查询
      const resultSet = await this.store.query(predicates, ["*"]);

      if (resultSet.rowCount === 1) {  // 正常情况
        resultSet.goToFirstRow();  // 移动到第一行

        // 填充数据对象
        stepInfo.date = resultSet.getString(resultSet.getColumnIndex("date")) || today;
        stepInfo.step = resultSet.getLong(resultSet.getColumnIndex("step"));
        stepInfo.distance = resultSet.getDouble(resultSet.getColumnIndex("distance"))
        stepInfo.calorie = resultSet.getLong(resultSet.getColumnIndex("calorie"));

      } else {  // 异常情况处理
        console.warn(`[步数数据] 异常记录数: ${resultSet.rowCount}`);
        // await this.step_insert_data(today);  // 自动修复缺失数据
      }
    } catch (err) {
      // 错误处理
      console.error(`[步数数据] 查询失败: ${(err as BusinessError).message}`);
    }

    console.info(`[步数数据] 查询结果: ${JSON.stringify(stepInfo)}`);
    return stepInfo;
  }

  /**
   * 查询睡眠数据
   * @description 根据日期查询睡眠记录
   * @param today - 查询日期（ISO格式）
   * @returns SleepClass - 睡眠数据对象
   */
  async sleep_query_data(today: string): Promise<SleepClass> {
    console.info(`[睡眠数据] 开始查询 ${today}`);
    const sleepInfo = new SleepClass();  // 初始化默认数据

    // 检查数据库连接
    if (!this.store) return sleepInfo;  // 数据库未初始化返回空对象

    try {
      // 构建日期查询条件
      const predicates = new relationalStore.RdbPredicates("sleep_table");
      predicates.equalTo("date", today);  // 按日期查询

      // 执行全字段查询
      const resultSet = await this.store.query(predicates, ["*"]);

      if (resultSet.rowCount === 1) {
        resultSet.goToFirstRow();  // 移动到第一行

        // 填充数据对象
        sleepInfo.date = resultSet.getString(resultSet.getColumnIndex("date")) || today;
        sleepInfo.sleep = resultSet.getLong(resultSet.getColumnIndex("sleep"));
        sleepInfo.wake = resultSet.getLong(resultSet.getColumnIndex("wake"));
        sleepInfo.deep = resultSet.getLong(resultSet.getColumnIndex("deep"));
        sleepInfo.light = resultSet.getLong(resultSet.getColumnIndex("light"));
        sleepInfo.rem = resultSet.getLong(resultSet.getColumnIndex("rem"));
      } else {
        console.warn(`[睡眠数据] 异常记录数: ${resultSet.rowCount}`);
      }
    } catch (err) {
      // 错误处理
      console.error(`[睡眠数据] 查询失败: ${err.message}`);
    }

    return sleepInfo;
  }

  /**
   * 查询饮水数据
   * @description 根据日期查询饮水记录
   * @param today - 查询日期（ISO格式）
   * @returns WaterClass - 饮水数据对象
   */
  async water_query_data(today: string): Promise<WaterClass> {
    console.info(`[饮水数据] 开始查询 ${today}`);
    const waterInfo = new WaterClass();  // 初始化默认数据

    // 检查数据库连接
    if (!this.store) return waterInfo;  // 数据库未初始化返回空对象

    try {
      // 构建日期查询条件
      const predicates = new relationalStore.RdbPredicates("water_table");
      predicates.equalTo("date", today);  // 按日期查询

      // 执行全字段查询
      const resultSet = await this.store.query(predicates, ["*"]);

      if (resultSet.rowCount === 1) {
        resultSet.goToFirstRow();  // 移动到第一行

        // 填充数据对象
        waterInfo.date = resultSet.getString(resultSet.getColumnIndex("date")) || today;
        waterInfo.water = resultSet.getLong(resultSet.getColumnIndex("water"));
      } else {
        console.warn(`[饮水数据] 异常记录数: ${resultSet.rowCount}`);
      }
    } catch (err) {
      // 错误处理
      console.error(`[饮水数据] 查询失败: ${err.message}`);
    }

    return waterInfo;
  }

  /**
   * 更新目标设置数据
   * @description 更新全局健康目标配置
   * @param targetInfo - 包含新目标值的对象
   */
  async target_update_data(targetInfo: TargetClass): Promise<void> {
    console.info('[target] 开始更新');

    // 检查数据库连接有效性
    if (!this.store) {
      console.error('[target] 数据库未初始化');
      return;
    }

    try {
      console.info('[target] 数据库存在开始更新');

      // 构建更新数据集（包含最小值校验）
      const valueBucket: relationalStore.ValuesBucket = {
        step_target: Math.max(0, targetInfo.step_target),     // 确保非负
        distance_target: Math.max(0, targetInfo.distance_target), // 距离校验
        calorie_target: Math.max(0, targetInfo.calorie_target), // 卡路里校验
        sleep_target: Math.max(0, targetInfo.sleep_target),     // 睡眠总时长校验
        deep_target: Math.max(0, targetInfo.deep_target),       // 深度睡眠校验
        light_target: Math.max(0, targetInfo.light_target),     // 浅度睡眠校验
        rem_target: Math.max(0, targetInfo.rem_target),         // REM睡眠校验
        water_target: Math.max(0, targetInfo.water_target),     // 饮水目标校验
        water_interval: Math.max(10, targetInfo.water_interval) // 饮水间隔最小值10ml
      };

      // 构建更新条件（ID=1）
      const predicates = new relationalStore.RdbPredicates("target_table");
      predicates.equalTo("id", 1);

      // 执行更新操作
      const affectedRows = await this.store.update(valueBucket, predicates);
      console.info(`[target] 更新完成，影响行数: ${affectedRows}`);

      // 处理更新结果
      if (affectedRows === 0) {
        console.warn('[target] 未找到记录   更新失败');
        // 可选：自动插入默认数据
        // await this.insert_target_data();
        // await this.store.update(valueBucket, predicates);
      } else if (affectedRows > 1) {
        console.error(`[target] 异常更新行数: ${affectedRows}`);
      }

      console.info(`[target] 更新成功，影响行数: ${affectedRows}`);
    } catch (err) {
      // 错误处理
      console.error(`[目标数据] 更新失败: ${(err as BusinessError).message}`);
      throw new Error(`目标数据更新失败: ${(err as BusinessError).message}`);
    }
  }

  /**
   * 更新步数数据
   * @description 根据日期更新步数记录
   * @param today - 日期（ISO格式）
   * @param step_info - 步数数据对象
   */
  async step_update_data(today: string, step_info:StepClass): Promise<void> {
    console.info(`[步数数据] 开始更新 ${today} => ${step_info.step}`);

    // 检查数据库连接
    if (!this.store) {
      console.error('[步数数据] 数据库未初始化');
      return;
    }

    try {
      // 数据校验（非负处理）
      const validatedStep = Math.max(0, step_info.step);

      // 构建查询条件（按日期更新）
      const predicates = new relationalStore.RdbPredicates("step_table");
      predicates.equalTo("date", today);

      // 构建更新数据集
      const valueBucket: relationalStore.ValuesBucket = {
        "step": validatedStep,
        "distance": step_info.distance,
        "calorie": step_info.calorie
      };

      // 执行更新
      const affectedRows = await this.store?.update(valueBucket, predicates);

      // 处理更新结果
      if (affectedRows === 0) {
        console.warn(`[步数数据] 未找到匹配记录，自动创建`);
        await this.step_insert_data(today);  // 自动修复：插入默认数据
        await this.store.update(valueBucket, predicates);  // 重新尝试更新
      }

      console.info(`[步数数据] 更新成功，影响行数: ${affectedRows}`);

      // 数据验证
      const verifyResult = await this.step_query_data(today);
      if (verifyResult.step !== validatedStep) {
        throw new Error(`数据验证失败，期望值: ${validatedStep}，实际值: ${verifyResult.step}`);
      }
      console.info(`[步数数据]数据验证成功`)
    } catch (err) {
      // 错误处理
      console.error(`[步数数据] 更新失败: ${(err as BusinessError).message}`);
      // throw err; // 当前未抛出错误
    }
  }

  /**
   * 更新睡眠数据
   * @description 根据日期更新睡眠记录
   * @param today - 日期（ISO格式）
   * @param sleep_info - 睡眠数据对象
   */
  async sleep_update_data(today: string, sleep_info:  SleepClass): Promise<void> {
    console.info(`[睡眠数据] 开始更新 ${today}`);

    // 检查数据库连接
    if (!this.store) {
      console.error('[睡眠数据] 数据库未初始化');
      return;
    }

    try {
      // 数据校验（非负处理）
      const validatedData = new SleepClass();
      validatedData.date = today;
      validatedData.sleep = Math.max(0, sleep_info.sleep);
      validatedData.wake = Math.max(0, sleep_info.wake);
      validatedData.deep = Math.max(0, sleep_info.deep);
      validatedData.light = Math.max(0, sleep_info.light);
      validatedData.rem = Math.max(0, sleep_info.rem);

      // 构建查询条件
      const predicates = new relationalStore.RdbPredicates("sleep_table");
      predicates.equalTo("date", today);

      // 构建更新数据集
      const valueBucket: relationalStore.ValuesBucket = {
        "sleep": validatedData.sleep,
        "wake": validatedData.wake,
        "deep": validatedData.deep,
        "light": validatedData.light,
        "rem": validatedData.rem
      };

      // 执行更新
      const affectedRows = await this.store.update(valueBucket, predicates);

      // 处理更新结果
      if (affectedRows === 0) {
        console.warn(`[睡眠数据] 未找到匹配记录，自动创建`);
        await this.sleep_insert_data(today);  // 自动插入默认数据
        await this.store.update(valueBucket, predicates);  // 重新尝试更新
      }

      console.info(`[睡眠数据] 更新成功，影响行数: ${affectedRows}`);

      // 数据验证
      const verifyResult = await this.sleep_query_data(today);
      if (verifyResult.sleep !== validatedData.sleep ||
        verifyResult.wake !== validatedData.wake ||
        verifyResult.deep !== validatedData.deep ||
        verifyResult.light !== validatedData.light ||
        verifyResult.rem !== validatedData.rem) {
        throw new Error(`数据验证失败，请检查更新结果`);
      }
      console.info(`[睡眠数据] 数据验证成功 ${JSON.stringify(verifyResult)}`);
    } catch (err) {
      // 错误处理
      console.error(`[睡眠数据] 更新失败: ${(err as BusinessError).message}`);
      // throw err; // 当前未抛出错误
    }
  }

  /**
   * 更新饮水数据
   * @description 根据日期更新饮水记录
   * @param today - 日期（ISO格式）
   * @param water_info - 饮水数据对象
   */
  async water_update_data(today: string, water_info: WaterClass): Promise<void> {
    console.info(`[饮水数据] 开始更新 ${today}`);

    // 检查数据库连接
    if (!this.store) {
      console.error('[饮水数据] 数据库未初始化');
      return;
    }

    try {
      // 数据校验（非负处理）
      const validatedWater = Math.max(0, water_info.water);

      // 构建查询条件
      const predicates = new relationalStore.RdbPredicates("water_table");
      predicates.equalTo("date", today);

      // 构建更新数据集
      const valueBucket: relationalStore.ValuesBucket = {
        "water": validatedWater
      };

      // 执行更新
      const affectedRows = await this.store.update(valueBucket, predicates);

      // 处理更新结果
      if (affectedRows === 0) {
        console.warn(`[饮水数据] 未找到匹配记录，自动创建`);
        await this.water_insert_data(today);  // 自动插入默认数据
        await this.store.update(valueBucket, predicates);  // 重新尝试更新
      }

      console.info(`[饮水数据] 更新成功，影响行数: ${affectedRows}`);

      // 数据验证
      const verifyResult = await this.water_query_data(today);
      if (verifyResult.water !== validatedWater) {
        throw new Error(`数据验证失败，期望值: ${validatedWater}，实际值: ${verifyResult.water}`);
      }
      console.info(`[饮水数据] 数据验证成功`);

    } catch (err) {
      // 错误处理
      console.error(`[饮水数据] 更新失败: ${(err as BusinessError).message}`);
      // throw err; // 当前未抛出错误
    }
  }




  /**
   * 查询一周的步数数据
   * @description 查询从指定日期开始的过去7天步数记录
   * @param today 当前日期（ISO格式 YYYY-MM-DD）
   * @returns 包含过去7天步数数据的StepClass数组
   * @example 返回值示例：[
   *   { date: '2023-12-01', step: 3000, ... },
   *   { date: '2023-12-02', step: 5000, ... },
   *   ...
   * ]
   */
  async step_query_data_week(today: string): Promise<StepClass[]> {
    console.info(`[步数数据] 开始查询一周数据，截止日期: ${today}`);
    const weekData: StepClass[] = [];  // 存储一周的数据

    // 检查数据库连接有效性
    if (!this.store) {
      console.error('[步数数据] 数据库未初始化');
      return [];
    }

    // 生成过去7天的日期（包含今天）
    for (let i = 6; i >= 0; i--) {
      // 创建日期对象并计算偏移
      const date = new Date(today);
      date.setDate(date.getDate() - i);  // 从6天前到今天（倒序生成）

      // 格式化为ISO日期字符串
      const formattedDate = date.toISOString().split('T')[0];

      try {
        // 查询单天数据
        const stepInfo = await this.step_query_data(formattedDate);
        weekData.push(stepInfo);  // 添加到结果数组
      } catch (err) {
        // 错误处理：记录错误并插入空数据
        console.error(`[${formattedDate}] 数据获取失败: ${err.message}`);
        weekData.push(new StepClass(formattedDate));  // 推入空数据保持列表长度
      }
    }

    // 输出调试信息
    console.info(`[步数数据] 查询一周数据完成，结果: ${JSON.stringify(weekData)}`);
    return weekData;  // 返回结果
  }

  /**
   * 查询一周的睡眠数据
   * @description 查询从指定日期开始的过去7天睡眠记录
   * @param today 截止日期（ISO格式 YYYY-MM-DD）
   * @returns 包含过去7天睡眠数据的SleepClass数组
   */
  async sleep_query_data_week(today: string): Promise<SleepClass[]> {
    console.info(`[睡眠数据] 开始查询一周数据，截止日期: ${today}`);
    const weekData: SleepClass[] = [];  // 结果存储容器

    // 检查数据库连接
    if (!this.store) {
      console.error('[睡眠数据] 数据库未初始化');
      return [];
    }

    // 生成7天日期范围
    for (let i = 6; i >= 0; i--) {
      // 日期计算逻辑
      const date = new Date(today);
      date.setDate(date.getDate() - i);  // 从6天前到今天
      const formattedDate = date.toISOString().split('T')[0];  // 格式化为YYYY-MM-DD

      try {
        // 查询单天数据
        const sleepInfo = await this.sleep_query_data(formattedDate);
        weekData.push(sleepInfo);  // 添加到结果数组
      } catch (err) {
        // 错误处理
        console.error(`[${formattedDate}] 数据获取失败: ${err.message}`);
        // 推入带日期的空数据保持完整性
        weekData.push(new SleepClass(formattedDate));
      }
    }

    // 调试输出
    console.info(`[睡眠数据] 查询一周数据完成，结果条数: ${weekData.length}`);
    return weekData;  // 返回结果
  }

  /**
   * 查询一周的饮水数据
   * @description 查询从指定日期开始的过去7天饮水记录
   * @param today 截止日期（ISO格式 YYYY-MM-DD）
   * @returns 包含过去7天饮水数据的WaterClass数组
   */
  async water_query_data_week(today: string): Promise<WaterClass[]> {
    console.info(`[饮水数据] 开始查询一周数据，截止日期: ${today}`);
    const weekData: WaterClass[] = [];  // 结果存储容器

    // 检查数据库连接
    if (!this.store) {
      console.error('[饮水数据] 数据库未初始化');
      return [];
    }

    // 生成7天日期范围
    for (let i = 6; i >= 0; i--) {
      // 日期计算（包含今天）
      const date = new Date(today);
      date.setDate(date.getDate() - i);  // 从6天前到今天
      const formattedDate = date.toISOString().split('T')[0];  // 格式化日期

      try {
        // 查询单天数据
        const waterInfo = await this.water_query_data(formattedDate);
        weekData.push(waterInfo);  // 添加到结果数组
      } catch (err) {
        // 错误处理
        console.error(`[${formattedDate}] 数据获取失败: ${(err as BusinessError).message}`);
        // 推入带日期的空数据保持长度
        weekData.push(new WaterClass(formattedDate));
      }
    }

    // 调试输出
    console.info(`[饮水数据] 查询一周数据完成，结果条数: ${weekData.length}`);
    return weekData;  // 返回结果
  }

}


