ArkUI X(Android) 子工程骨架

使用方式（建议在 DevEco Studio 新建 ArkUI X Android 工程后，将本目录的 ets 源码拷入对应目录）：
- 复制 `src/main/ets/tools/UiConstants.ts`
- 复制 `src/main/ets/view/CommonTitleView.ets`
- 复制 `src/main/ets/view/BarChartView.ets`
- 复制 `src/main/ets/tools/HuaweiAuth.ts`
- 复制 `src/main/ets/tools/PreferencesUtil.ts`
- 复制 `src/main/ets/pages/Index.ets`
- 复制 `src/main/ets/pages/ExerciseTimePage.ets`
- 复制 `src/main/ets/pages/ActivityCountPage.ets`
- 复制 `src/main/ets/pages/ChartPage.ets`
- 复制 `src/main/ets/pages/LoginPage.ets`
- 复制 `src/main/ets/pages/SettingPage.ets`
- 复制 `src/main/ets/pages/XYPage.ets`
- 复制 `src/main/ets/pages/YSPage.ets`
- 在资源目录放入 `base/media/back_btn_dark.png`、`right_btn.png`、`week_report_reward.png`、`icon.png`（图标资源）

已完成：
- ✅ 通用标题组件（沉浸式）
- ✅ 图表组件（BarChartView，基于 WebView+ECharts）
- ✅ 数据模型与接口（SportModel、DataCallback）
- ✅ 数据管理器（AppDataManager，当前使用假数据，后续可切换为 Room/AGC）
- ✅ 日期工具类（DateUtils）
- ✅ 工具类（Utils、MainCardManager）
- ✅ 主页面组件（MainTopView、MainCardView、SubFragment）
- ✅ 主页面（MainTabs - 健康/运动/我的三个Tab）
- ✅ 锻炼时长统计页（已接入数据层）
- ✅ 活动次数统计页（已接入数据层）
- ✅ 热量统计页（已接入数据层，支持周/月/年视图）
- ✅ 登录服务适配（HuaweiAuth，占位实现，需 Native 桥接）
- ✅ 本地存储适配（PreferencesUtil，占位实现，需 Native 桥接）
- ✅ Native 桥接封装（NativeBridge.ts）
- ✅ 启动页（Index）
- ✅ 登录页面（LoginPage）
- ✅ 设置页面（SettingPage）
- ✅ 用户协议页面（XYPage）
- ✅ 隐私协议页面（YSPage）
- ✅ 用户资料页面（UserProfilePage）
- ✅ 目标管理页面（TargetManagementPage）
- ✅ 步数趋势页面（StepTrendPage）
- ✅ 运动记录页面（SportRecordPage）
- ✅ 距离趋势页面（DistanceTrendPage）
- ✅ 体重趋势页面（WeightTrendPage）
- ✅ 编辑主卡片页面（EditMainCardPage）
- ✅ 运动记录页面（ExerciseRecordPage）
- ✅ 身体数据页面（BodyDataPage）
- ✅ 主页面组件（MainTopView、MainCardView、SubFragment）
- ✅ 主页面（MainTabs - 健康/运动/我的三个Tab）
- ✅ 工具类（Utils、MainCardManager）
- ✅ 数据模型（SportModel、PerStepModel、BodyRecordModel、MainCardItemModel）
- ✅ 日期工具类（DateUtils - 包含所有必要方法）

待完成：
- 真实数据源接入（Room 或 AGC CloudDB Android）
- Native 桥接实现（HMS Account Kit + SharedPreferences）
- 其余辅助页面迁移（如需要）

注意事项：
- 图表组件使用 Web 组件加载 ECharts，如 ArkUI X 不支持 Web 组件，需改用原生图表库（如 MPAndroidChart）或通过 Native 桥接
- 当前数据管理器使用假数据（mockSportData），后续需要替换为真实的数据库查询（Room 或 AGC CloudDB）
- 所有页面已接入数据层，可以正常显示图表和统计数据
- 登录功能当前为占位实现，需要通过 Native 桥接调用 HMS Account Kit（参考 `NATIVE_BRIDGE_GUIDE.md`）
- 本地存储当前为占位实现，需要通过 Native 桥接调用 SharedPreferences（参考 `NATIVE_BRIDGE_GUIDE.md`）

## 文档

- **[最终迁移状态](FINAL_MIGRATION_STATUS.md)** - 完整的迁移状态和完成度（推荐先看）⭐
- [项目状态](PROJECT_STATUS.md) - 当前迁移进度和完成度
- [构建与运行指南](BUILD_GUIDE.md) - 详细的构建、运行和打包步骤
- [Native 桥接指南](NATIVE_BRIDGE_GUIDE.md) - HMS Account Kit 和 SharedPreferences 桥接实现
- [迁移总结](MIGRATION_SUMMARY.md) - 完整的迁移进度和技术栈对比

