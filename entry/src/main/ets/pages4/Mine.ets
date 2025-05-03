import { geoLocationManager } from "@kit.LocationKit"
import { abilityAccessCtrl, common, Permissions } from '@kit.AbilityKit' // 添加权限模块
@Component
export struct Mine {
  @State
  result: geoLocationManager.Location={} as geoLocationManager.Location

  private context: common.UIAbilityContext = getContext(this) as common.UIAbilityContext;
  // 添加权限请求方法
  async requestPermission() {
    try {
      let atManager = abilityAccessCtrl.createAtManager()
      // 请求精确位置权限（根据需求选择 APPROXIMATELY_LOCATION 或 LOCATION）
      await atManager.requestPermissionsFromUser(this.context,
        ["ohos.permission.APPROXIMATELY_LOCATION"]
      )
    } catch (err) {
      console.error(`请求权限失败: ${err.code}, ${err.message}`)
    }
  }


  build() {
    Column() {
      Text('我的')
        .fontSize(36)
        .fontColor(Color.White)

      Button('获取经纬度')
        .onClick(async () => {
          // 先请求权限再获取位置
          await this.requestPermission()
          try {
            this.result = await geoLocationManager.getCurrentLocation()
          } catch (err) {
            console.error(`获取位置失败: ${err.code}, ${err.message}`)
          }
        })
      Text("经度："+this.result.latitude)
        .fontSize(36)
        .fontColor(Color.White)
      Text("纬度："+this.result.longitude)
        .fontSize(36)
        .fontColor(Color.White)
    }
  }
}