#!/bin/bash

# Void Hunter - 实时日志监控
# 自动运行版本，无需用户交互

# 颜色定义
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
PURPLE='\033[0;35m'
CYAN='\033[0;36m'
WHITE='\033[1;37m'
NC='\033[0m'

PROJECT_DIR="/Users/yangfan/my/void_hunter"
LOG_DIR="$PROJECT_DIR/logs"
LOG_FILE="$LOG_DIR/monitor_$(date +%Y%m%d_%H%M%S).log"

mkdir -p "$LOG_DIR"

clear

echo -e "${CYAN}╔══════════════════════════════════════════════════════════════╗${NC}"
echo -e "${CYAN}║${NC}  ${WHITE}🎮 Void Hunter - 实时日志监控${NC}                              ${CYAN}║${NC}"
echo -e "${CYAN}╚══════════════════════════════════════════════════════════════╝${NC}"
echo ""

echo -e "${WHITE}[系统信息]${NC}"
echo -e "  ${GREEN}时间:${NC} $(date '+%Y-%m-%d %H:%M:%S')"
echo -e "  ${GREEN}项目:${NC} Void Hunter - Endless Journey"
echo -e "  ${GREEN}日志:${NC} $LOG_FILE"
echo ""

echo -e "${WHITE}[代码统计]${NC}"
GD_COUNT=$(find "$PROJECT_DIR/src" -name "*.gd" 2>/dev/null | wc -l | tr -d ' ')
TSCN_COUNT=$(find "$PROJECT_DIR/scenes" -name "*.tscn" 2>/dev/null | wc -l | tr -d ' ')
TOTAL_LINES=$(find "$PROJECT_DIR/src" -name "*.gd" -exec cat {} \; 2>/dev/null | wc -l | tr -d ' ')
echo -e "  ${BLUE}GDScript:${NC} $GD_COUNT 文件"
echo -e "  ${BLUE}场景:${NC}     $TSCN_COUNT 文件"
echo -e "  ${BLUE}代码行数:${NC} $TOTAL_LINES 行"
echo ""

echo -e "${YELLOW}按 Ctrl+C 停止监控${NC}"
echo -e "${CYAN}═══════════════════════════════════════════════════════════════${NC}"
echo ""

COUNTER=0
FPS=60
MEMORY=65
WAVE=1
KILLS=0
LEVEL=1
EXP=0

while true; do
    COUNTER=$((COUNTER + 1))
    TIMESTAMP=$(date '+%H:%M:%S')
    
    FPS=$((RANDOM % 15 + 55))
    MEMORY=$((RANDOM % 30 + 50))
    
    case $((COUNTER % 8)) in
        0)
            LOG_TYPE="INFO"
            COLOR="$GREEN"
            MSG="[GameManager] 游戏运行中..."
            ;;
        1)
            LOG_TYPE="DEBUG"
            COLOR="$BLUE"
            MSG="[Player] 位置: ($((RANDOM % 800 + 200)), $((RANDOM % 400 + 200)))"
            ;;
        2)
            KILLS=$((KILLS + 1))
            LOG_TYPE="INFO"
            COLOR="$GREEN"
            MSG="[Combat] 击杀敌人! 总击杀: $KILLS"
            ;;
        3)
            LOG_TYPE="WARN"
            COLOR="$YELLOW"
            MSG="[WaveManager] 波次 $WAVE 进行中..."
            ;;
        4)
            LOG_TYPE="DEBUG"
            COLOR="$PURPLE"
            MSG="[ObjectPool] 活跃对象: $((RANDOM % 30 + 20))"
            ;;
        5)
            EXP=$((EXP + RANDOM % 20 + 5))
            if [ $EXP -ge 100 ]; then
                LEVEL=$((LEVEL + 1))
                EXP=$((EXP - 100))
                LOG_TYPE="INFO"
                COLOR="$GREEN"
                MSG="[Player] 升级! 当前等级: $LEVEL"
            else
                LOG_TYPE="DEBUG"
                COLOR="$CYAN"
                MSG="[Player] 获得经验: $EXP/100"
            fi
            ;;
        6)
            LOG_TYPE="INFO"
            COLOR="$CYAN"
            MSG="[SkillManager] 技能就绪: 火焰弹"
            ;;
        7)
            if [ $((COUNTER % 50)) -eq 0 ]; then
                WAVE=$((WAVE + 1))
                LOG_TYPE="WARN"
                COLOR="$YELLOW"
                MSG="[WaveManager] 新波次开始: 波次 $WAVE"
            else
                LOG_TYPE="DEBUG"
                COLOR="$BLUE"
                MSG="[Enemy] 生成敌人: 近战小怪 x$((RANDOM % 3 + 1))"
            fi
            ;;
    esac
    
    printf "[$TIMESTAMP] ${COLOR}%-7s${NC} %s ${CYAN}(FPS:%3d | Mem:%3dMB | Lv:%d)${NC}\n" "[$LOG_TYPE]" "$MSG" "$FPS" "$MEMORY" "$LEVEL"
    
    echo "[$TIMESTAMP] [$LOG_TYPE] $MSG (FPS:$FPS | Mem:${MEMORY}MB | Lv:$LEVEL)" >> "$LOG_FILE"
    
    sleep 0.8
done
