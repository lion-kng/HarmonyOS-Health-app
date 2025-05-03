


export class SleepClass{
  date:string
  sleep:number
  wake:number
  deep:number
  light:number
  rem:number

  constructor(date: string = "default", sleep: number = 0,wake:number=0,deep:number=0,light:number=0,rem:number=0) {
    this.date = date
    this.sleep = sleep
    this.wake=wake
    this.deep=deep
    this.light=light
    this.rem=rem
 }
}