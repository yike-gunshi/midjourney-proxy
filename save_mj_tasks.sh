#!/bin/bash

# 创建保存任务信息的目录和文件
mkdir -p tasks
TASKS_FILE="tasks/mj_tasks.txt"
touch "$TASKS_FILE"

# 提交任务函数
submit_task() {
    local prompt="$1"
    echo "正在提交任务: $prompt"
    
    # 提交任务并获取任务ID
    response=$(curl -s -X POST "http://localhost:8080/mj/submit/imagine" \
        -H "Content-Type: application/json" \
        -d "{\"prompt\": \"$prompt\", \"base64\": null, \"notifyHook\": null}")
    
    task_id=$(echo $response | grep -o '"result":"[^"]*"' | cut -d'"' -f4)
    echo "任务ID: $task_id"
    
    # 等待任务完成并获取URL
    for i in {1..30}; do
        task_info=$(curl -s "http://localhost:8080/mj/task/$task_id/fetch")
        status=$(echo $task_info | grep -o '"status":"[^"]*"' | cut -d'"' -f4)
        progress=$(echo $task_info | grep -o '"progress":"[^"]*"' | cut -d'"' -f4)
        echo "进度: $progress"
        
        if [ "$status" = "SUCCESS" ]; then
            image_url=$(echo $task_info | grep -o '"imageUrl":"[^"]*"' | cut -d'"' -f4)
            timestamp=$(date '+%Y-%m-%d %H:%M:%S')
            echo "[$timestamp] Task ID: $task_id" >> "$TASKS_FILE"
            echo "Prompt: $prompt" >> "$TASKS_FILE"
            echo "Image URL: $image_url" >> "$TASKS_FILE"
            echo "----------------------------------------" >> "$TASKS_FILE"
            echo "任务完成！"
            echo "图片URL已保存到: $TASKS_FILE"
            return 0
        elif [ "$status" = "FAILURE" ]; then
            echo "任务失败"
            return 1
        fi
        
        sleep 2
    done
    
    echo "等待超时"
    return 1
}

# 主程序
echo "MidJourney任务保存工具"
echo "任务信息将保存在: $TASKS_FILE"

# 如果提供了命令行参数，使用它作为prompt
if [ $# -gt 0 ]; then
    submit_task "$*"
else
    # 否则提示用户输入
    echo "请输入提示词 (prompt):"
    read -r prompt
    submit_task "$prompt"
fi
