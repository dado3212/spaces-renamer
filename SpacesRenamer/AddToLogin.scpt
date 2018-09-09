on run args_list
    tell application "System Events" to make login item at end with properties {path:item 1 of args_list, hidden:false}
end run
