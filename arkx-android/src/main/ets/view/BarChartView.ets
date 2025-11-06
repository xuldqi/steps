// 基于 WebView + ECharts 的柱状图组件
// 用于替换 @mcui/mccharts 的 McBarChart

@Component
export struct BarChartView {
  // 图表数据
  @Param xAxisData: Array<string> = ['周一', '周二', '周三', '周四', '周五', '周六', '周日']
  @Param seriesData: Array<number> = [0, 0, 0, 0, 0, 0, 0]
  // 图表配置
  @Param barColor: string = '#0cc291' // 柱状图颜色
  @Param title: string = '' // 图表标题（如"分钟"、"次"、"千卡"）
  @Param titlePosition: 'left' | 'right' | 'top' | 'bottom' = 'right' // 标题位置

  private generateEChartsHTML(): string {
    const dataStr = JSON.stringify(this.seriesData)
    const labelsStr = JSON.stringify(this.xAxisData)
    const color = this.barColor
    const titleText = this.title
    const titlePos = this.titlePosition

    return `
<!DOCTYPE html>
<html>
<head>
  <meta charset="UTF-8">
  <meta name="viewport" content="width=device-width, initial-scale=1.0">
  <script src="https://cdn.jsdelivr.net/npm/echarts@5.4.3/dist/echarts.min.js"></script>
  <style>
    body { margin: 0; padding: 0; background: transparent; }
    #chart { width: 100%; height: 100%; }
  </style>
</head>
<body>
  <div id="chart"></div>
  <script>
    const chart = echarts.init(document.getElementById('chart'));
    const option = {
      title: ${titleText ? `{ show: true, text: '${titleText}', ${titlePos === 'right' ? 'right: 20, top: 30' : titlePos === 'left' ? 'left: 20, top: 30' : 'center'}, textStyle: { fontSize: 12, color: '#666' } }` : '{ show: false }'},
      grid: { left: '10%', right: '15%', top: '20%', bottom: '15%' },
      xAxis: {
        type: 'category',
        data: ${labelsStr},
        axisLine: { lineStyle: { color: '#E0E0E0' } },
        axisLabel: { fontSize: 10, color: '#666' }
      },
      yAxis: {
        type: 'value',
        axisLine: { show: false },
        axisTick: { show: false },
        axisLabel: { fontSize: 10, color: '#666' },
        splitLine: { lineStyle: { color: '#F0F0F0', type: 'dashed' } }
      },
      series: [{
        type: 'bar',
        data: ${dataStr},
        itemStyle: {
          color: '${color}',
          borderRadius: [4, 4, 0, 0]
        },
        barWidth: '60%'
      }],
      tooltip: {
        trigger: 'axis',
        backgroundColor: 'rgba(0,0,0,0.7)',
        textStyle: { color: '#FFF', fontSize: 12 },
        borderWidth: 0
      }
    };
    chart.setOption(option);
    
    // 响应窗口大小变化
    window.addEventListener('resize', () => {
      chart.resize();
    });
  </script>
</body>
</html>
    `
  }

  build() {
    Web({ src: this.generateEChartsHTML() })
      .width('100%')
      .height('100%')
      .onPageEnd(() => {
        // 页面加载完成后的回调（可选）
      })
  }
}

