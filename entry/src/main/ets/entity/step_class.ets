

export class StepClass{
  date:string
  step:number
  distance:number
  calorie:number

  constructor(date: string = "default", step: number = 0, distance: number = 0, calorie: number = 0) {
    this.date = date
    this.step = step
    this.distance = distance
    this.calorie = calorie
  }
}