#!/bin/bash

# 检查是否正确提供了两个参数
if [ "$#" -ne 2 ]; then
    echo "Usage: $0 <dot_file_path> <function_name>"
    exit 1
fi

# 获取参数值
dot_file_path="$1"
function_name="$2"
output_dot_file="${function_name}.dot"
output_svg_file="${function_name}.svg"


trim() {
    echo "$1" | awk '{$1=$1};1'
}

# 函数用于递归地搜索所有关联的行
search_edges() {
    local target_node="$1" # 目标节点
    local found_lines

    echo "    $(trim $target_node)"

    # 查找指向目标节点的所有行
    # echo ".*-> $(trim $target_node).*"
    found_lines=$(grep ".*-> $(trim $target_node).*" $dot_file_path)
    echo "$found_lines"

    # 如果找到了匹配项，则打印它们并递归地搜索每个匹配项的源节点
    if [[ -n $found_lines ]]; then
        # echo "Edges pointing to '$target_node':"
        # echo "$found_lines"
        while IFS= read -r line; do
            # 提取 '->' 前面的节点
            prev_node=$(echo "$line" | awk -F '->' '{print $1}')
            # 移除可能的尾随空格
            prev_node=$(echo "$prev_node" | sed 's/ *$//')
            search_edges "$prev_node"
        done <<< "$found_lines"
    fi
}


build_function_do_graph() {
    echo "digraph G {
    rankdir=LR;
    node [fillcolor=\"#FFFFCC\", shape=box, style=filled];" > ${output_dot_file}

    # 开始搜索，从 'function_name' 节点开始
    search_edges $function_name >> ${output_dot_file}

    echo "}" >> ${output_dot_file}

    # 删除重复的边定义
    awk 'BEGIN {FS="->"; OFS="->"} !seen[$1,$2]++' ${output_dot_file} > file_no_dups.dot
    cat file_no_dups.dot > ${output_dot_file}

    # 删除重复的节点定义
    awk '!seen[$0]++' ${output_dot_file} > file_no_dups.dot
    cat file_no_dups.dot > ${output_dot_file}

    # 使用awk替换$function_name节点的定义
    awk 'BEGIN {FS=" "; OFS=" "} 
        ($0 ~ /'$function_name'$/) {$0 = ""$function_name"[fillcolor=pink, style=filled]"} 
        {print}' ${output_dot_file} > file_modified.dot

    cat file_modified.dot > ${output_dot_file}

    rm -r file_modified.dot
    rm -f file_no_dups.dot
}

build_function_do_graph

dot -Tsvg "${output_dot_file}" -o "${output_svg_file}"
