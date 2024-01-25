function count_items
    # Count the number of occurrences of each unique argument.
    set --local prefix redfish:count_items:
    redfish del (redfish keys $prefix\*)

    for item in $argv
        redfish incr $prefix$item
        or return
    end

    set --local keys (redfish keys $prefix\*)
    or return

    set --local exit_status 0
    for key in $keys
        if not set --local count (redfish get $key)
            # We can't use `or return` here
            # because the pipeline will eat the non-zero status
            # when we return from the function.
            # We also can't examine the contents of `$pipestatus`
            # after an `or return`, since the function will stop executing.
            # Therefore, we'll track the status manually.
            set exit_status 1
            break
        end

        echo $count (string replace $prefix '' $key)
    end | sort -n -r

    redfish del (redfish keys $prefix\*)

    return $exit_status
end
