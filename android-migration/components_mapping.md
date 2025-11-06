# 组件/页面映射

- CommonTitleView → 直接复用（如 ArkUI X API 差异，改用自定义 SafeArea 逻辑）。
- ExerciseTimePage / ActivityCountPage / ChartPage → 复用布局思想：
  - 标题（沉浸）
  - 控制区+柱状图（白色卡片）
  - 目标进度（白色卡片）
  - 汇总信息（白色卡片）
- 图表：`@mcui/mccharts` 如不支持 ArkUI X/Android，则改用 WebView/ECharts 或原生图表库（MPAndroidChart）。
- 数据与服务：
  - preferencesUtil → SharedPreferences 封装
  - CloudDBService → AGC CloudDB(Android) 或 Room 适配
  - 登录 → HMS Account(Android)
