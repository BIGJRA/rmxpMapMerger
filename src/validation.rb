def validate_nums_list(string)
    !!(string =~ /^\d{1,3}(,\d{1,3})*$/)
end
