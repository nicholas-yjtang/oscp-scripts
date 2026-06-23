prerule = function()
    return true
end

action = function()
    local success, exit_type, code = os.execute("{cmd}")

    if success then
        return "System task executed successfully"
    else
        return "Failed to run shell task."
    end
end