


export class ChartDateClass {
  type: string
  title: string
  color: string
  data: number[]
  constructor(type: string, title: string, color: string, data: number[]) {
    this.type = type
    this.title = title
    this.color = color
    this.data = data
  }
}