#!/usr/bin/env python3

import pydot
import argparse

def recursive_get_callers(graph, function_name, max_depth=3, current_depth=0, seen_edges=None):
    if seen_edges is None:
        seen_edges = set()

    callers_dict = {}

    if current_depth >= max_depth:
        return callers_dict

    for edge in graph.get_edges():
        source = edge.get_source()
        destination = edge.get_destination()

        if destination == function_name:
            print(f"{current_depth} {source} -> {destination}")
            callers_dict[source] = recursive_get_callers(graph, source, max_depth, current_depth + 1, seen_edges)

    return callers_dict

def build_dot_graph(callers_tree, root_function):
    dot_graph = pydot.Dot(graph_type='digraph')
    dot_graph.set_rankdir('LR')
    dot_graph.set_node_defaults(fillcolor="#FFFFCC", shape="box", style="filled")

    root_node = pydot.Node(root_function)
    dot_graph.add_node(root_node)

    def _add_subgraph(sub_tree, parent_node):
        for caller, sub_tree in sub_tree.items():
            # Create node for the current caller
            caller_node = pydot.Node(caller)
            dot_graph.add_node(caller_node)

            # Check if the edge already exists before adding it
            existing_edges = dot_graph.get_edge_list()
            found = False
            for edge in existing_edges:
                if (edge.get_source() == parent_node.get_name() and
                        edge.get_destination() == caller_node.get_name()):
                    found = True
                    break
            
            # Only add the edge if it does not exist
            if not found:
                edge = pydot.Edge(parent_node, caller_node)
                dot_graph.add_edge(edge)

            # Recursively build subgraphs for each sub-tree
            _add_subgraph(sub_tree, caller_node)

    _add_subgraph(callers_tree, root_node)
    return dot_graph

def print_callers_tree(callers_tree, prefix=""):
    # 打印当前层级的键（即函数名）
    for key in callers_tree.keys():
        print(prefix + key)
        # 对于每个键，递归地打印其值（子树）
        if isinstance(callers_tree[key], dict):
            print_callers_tree(callers_tree[key], prefix + "  ")

def main():
    parser = argparse.ArgumentParser(description='Generate call graph for a specified function from a DOT file.')
    parser.add_argument('dot_file_path', type=str, help='Path to the input DOT file')
    parser.add_argument('function_name', type=str, help='Name of the function to generate the call graph for')
    args = parser.parse_args()

    # Check if required arguments were provided
    if not args.dot_file_path or not args.function_name:
        parser.error("Both 'dot_file_path' and 'function_name' must be specified.")
        return

    graph = pydot.graph_from_dot_file(args.dot_file_path)[0]
    max_depth = 1000  # Set the maximum recursion depth here
    callers_tree = recursive_get_callers(graph, args.function_name, max_depth, seen_edges=set())

    # 打印callers_tree
    print("Callers Tree:")
    print_callers_tree(callers_tree)

    dot_graph = build_dot_graph(callers_tree, args.function_name)
    output_dot_file = f'{args.function_name}_callgraph.dot'
    dot_graph.write_raw(output_dot_file)

if __name__ == '__main__':
    main()