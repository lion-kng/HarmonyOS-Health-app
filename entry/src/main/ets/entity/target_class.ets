



export class  TargetClass{
  step_target:number
  distance_target:number
  calorie_target:number
  sleep_target:number
  deep_target:number
  light_target:number
  rem_target:number
  water_target:number
  water_interval:number

  constructor(step: number = 0, dist: number = 0, cal: number = 0, sleep: number = 0,
    deep: number = 0, light: number = 0, rem: number = 0, water: number = 0,interval:number=10)
  {
    this.step_target = step
    this.distance_target = dist
    this.calorie_target = cal
    this.sleep_target = sleep
    this.deep_target = deep
    this.light_target = light
    this.rem_target = rem
    this.water_target = water
    this.water_interval = interval
  }
}