#!/bin/bash

# 检查是否正确提供了两个参数
if [ "$#" -ne 2 ]; then
    echo "Usage: $0 <dot_file_path> <function_name>"
    exit 1
fi

# 获取参数值
dot_file_path="$1"
function_name="$2"


# 提取函数callgraph
python3 function_callgraph_extractor.py "$dot_file_path" "$function_name"

if [ $? -ne 0 ]; then
    echo "Error occurred while running the Python script."
    exit 1
fi


# 使用dot命令生成SVG文件
dot -Tsvg "${function_name}_callgraph.dot" -o "${function_name}_callgraph.svg"

# 检查转换是否成功
if [ $? -eq 0 ]; then
    echo "SVG file has been generated successfully."
else
    echo "Error occurred while generating SVG file."
    exit 1
fi
