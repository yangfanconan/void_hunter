<div align="center">

# 🎮 Void Hunter: Endless Journey

**A 2D Pixel-Art Roguelike Shooter Game**

[![Godot Engine](https://img.shields.io/badge/Godot-4.3-blue.svg)](https://godotengine.org/)
[![License](https://img.shields.io/badge/License-MIT-green.svg)](LICENSE)
[![Platform](https://img.shields.io/badge/Platform-WebGL%20%7C%20Android-orange.svg)](#)

[English](#english) | [中文](#中文)

<img src="docs/images/gameplay_preview.png" alt="Gameplay Preview" width="600"/>

</div>

---

<a name="english"></a>
## 📖 English

### 🎯 Overview

**Void Hunter: Endless Journey** is a 2D pixel-art roguelike shooter where you control a character fighting through procedurally generated levels, collecting skills and items to become stronger, and surviving endless waves of enemies.

### ✨ Features

#### 🗺️ Procedural Level Generation
- **5 Unique Themes**: Forest, Desert, Cave, Ruins, Void
- **Perlin Noise Terrain**: Every playthrough is different
- **Dynamic Elements**: Destructible objects, hidden passages, environmental traps

#### ⚔️ Skill Combination System
- **12 Base Skills**: Attack, Defense, Control, Support categories
- **6 Combo Skills**: Combine elements for powerful effects
  - 🔥 Fire + ❄️ Ice = **Frost Fire** (Slow + DoT)
  - ⚡ Lightning + 🌑 Shadow = **Shadow Lightning** (Pierce + Chain)
  - 🛡️ Shield + 🔄 Reflect = **Mirror Shield**
- **3 Skill Levels**: Upgrade skills by collecting gems

#### 🎒 Item Collection System
- **20 Unique Items**: Weapons, Armor, Accessories, Consumables
- **4 Rarity Tiers**: Common (White) → Rare (Blue) → Epic (Purple) → Legendary (Orange)
- **Backpack System**: Manage, equip, and view your collection

#### 👥 Character Unlock System
- **8 Playable Characters**: Each with unique abilities
- **Challenge-Based Unlocks**: Complete objectives to unlock new characters
- **Permanent Progression**: Characters level up even after death

### 🎮 Controls

| Action | PC | Mobile |
|--------|----|----|
| Move | WASD / Arrow Keys | Left Joystick |
| Attack | Left Click / Space | Right Joystick |
| Dash | Shift | Dash Button |
| Skills 1-4 | 1 / 2 / 3 / 4 | Skill Buttons |
| Items 1-3 | Z / X / C | Item Buttons |
| Pause | ESC | Pause Button |

### 🚀 Quick Start

```bash
# Clone the repository
git clone https://github.com/yangfanconan/void_hunter.git

# Open with Godot 4.3
# File -> Open Project -> Select the cloned folder
```

### 📦 Build

```bash
# WebGL Build
./scripts/build_webgl.sh release

# Android Build
./scripts/build_android.sh release

# Build All Platforms
./scripts/build_all.sh --all --release
```

### 📁 Project Structure

```
void_hunter/
├── src/
│   ├── autoload/       # Global singletons
│   ├── player/         # Player controller
│   ├── enemies/        # Enemy AI system
│   ├── skills/         # Skill system (12 skills)
│   ├── items/          # Item system (20 items)
│   ├── characters/     # Character system (8 characters)
│   ├── levels/         # Procedural generation
│   ├── platform/       # Cross-platform adapters
│   └── utils/          # Performance tools
├── scenes/             # Godot scene files
├── export/             # Export templates
├── scripts/            # Build scripts
└── docs/               # Documentation
```

### 📚 Documentation

- [Game Design Document](docs/gdd.md)
- [Architecture](docs/architecture.md)
- [API Reference](docs/api_reference.md)
- [Development Guide](docs/development_guide.md)
- [Build Guide](docs/BUILD_GUIDE.md)

### 🛠️ Tech Stack

- **Engine**: Godot 4.3 LTS
- **Language**: GDScript
- **Platforms**: WebGL, Android
- **Performance Target**: 60 FPS (Web), 30+ FPS (Mobile)

### 🤝 Contributing

Contributions are welcome! Please feel free to submit issues and pull requests.

### 📄 License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.

---

<a name="中文"></a>
## 📖 中文

### 🎯 游戏简介

**虚空猎手：无尽征途** 是一款2D像素风肉鸽射击游戏。你将操控角色在程序化生成的关卡中战斗，收集技能与道具不断强化自己，挑战无尽波次的敌人。

### ✨ 游戏特色

#### 🗺️ 程序化关卡生成
- **5种独特主题**：森林、荒漠、洞穴、遗迹、虚空
- **Perlin噪声地形**：每次游玩都不同
- **动态元素**：可破坏物体、隐藏通道、环境陷阱

#### ⚔️ 技能组合系统
- **12种基础技能**：攻击、防御、控制、辅助四大类
- **6种组合技能**：元素组合产生强大效果
  - 🔥 火焰 + ❄️ 冰霜 = **冰霜火焰**（减速+持续伤害）
  - ⚡ 闪电 + 🌑 暗影 = **暗影闪电**（穿透+连锁）
  - 🛡️ 护盾 + 🔄 反射 = **镜像护盾**
- **3级技能等级**：收集宝石升级技能

#### 🎒 道具收集系统
- **20种独特道具**：武器、防具、饰品、消耗品
- **4级稀有度**：普通(白) → 稀有(蓝) → 史诗(紫) → 传说(橙)
- **背包系统**：管理、装备和查看你的收藏

#### 👥 角色解锁系统
- **8个可玩角色**：每个都有独特能力
- **挑战解锁**：完成目标解锁新角色
- **永久成长**：即使死亡角色也会升级

### 🎮 操作说明

| 操作 | PC端 | 移动端 |
|------|------|--------|
| 移动 | WASD / 方向键 | 左侧摇杆 |
| 攻击 | 鼠标左键 / 空格 | 右侧摇杆 |
| 冲刺 | Shift | 冲刺按钮 |
| 技能1-4 | 1 / 2 / 3 / 4 | 技能按钮 |
| 道具1-3 | Z / X / C | 道具按钮 |
| 暂停 | ESC | 暂停按钮 |

### 🚀 快速开始

```bash
# 克隆仓库
git clone https://github.com/yangfanconan/void_hunter.git

# 使用 Godot 4.3 打开
# 文件 -> 打开项目 -> 选择克隆的文件夹
```

### 📦 构建

```bash
# WebGL版本
./scripts/build_webgl.sh release

# Android版本
./scripts/build_android.sh release

# 构建所有平台
./scripts/build_all.sh --all --release
```

### 📁 项目结构

```
void_hunter/
├── src/
│   ├── autoload/       # 全局单例
│   ├── player/         # 玩家控制器
│   ├── enemies/        # 敌人AI系统
│   ├── skills/         # 技能系统 (12种技能)
│   ├── items/          # 道具系统 (20种道具)
│   ├── characters/     # 角色系统 (8个角色)
│   ├── levels/         # 程序化生成
│   ├── platform/       # 跨平台适配
│   └── utils/          # 性能工具
├── scenes/             # Godot场景文件
├── export/             # 导出模板
├── scripts/            # 构建脚本
└── docs/               # 文档
```

### 📚 文档

- [游戏设计文档](docs/gdd.md)
- [系统架构](docs/architecture.md)
- [API参考](docs/api_reference.md)
- [开发指南](docs/development_guide.md)
- [构建指南](docs/BUILD_GUIDE.md)

### 🛠️ 技术栈

- **引擎**: Godot 4.3 LTS
- **语言**: GDScript
- **平台**: WebGL, Android
- **性能目标**: 60 FPS (网页), 30+ FPS (移动端)

### 🤝 贡献

欢迎贡献代码！请随时提交Issue和Pull Request。

### 📄 许可证

本项目采用 MIT 许可证 - 详情请查看 [LICENSE](LICENSE) 文件。

---

<div align="center">

### 🌟 Star History

如果这个项目对你有帮助，请给一个 ⭐ Star！

Made with ❤️ by [yangfanconan](https://github.com/yangfanconan)

</div>
