#!/usr/bin/env python3

import sys

def main():
    concord()
    
def concord():
    input_file, filter_file = get_files()
    if filter_file:         #filter_file = false if no flag specified in get_file()
        filter_arr = file_lines_to_arr(filter_file)
    else:
        filter_arr = []
    
    # [(unique word, line num)], longest unique word length, {line num: input file line}
    uw_arr, long_uw_len, line_dict = uw_line_ds(input_file, filter_arr) 
    uw_arr = sorted(uw_arr, key = get_word)
    print_results(uw_arr,long_uw_len,line_dict)

def print_results(uw_arr, long_uw_len, line_dict):
    """Formats results to command line given nessesary data structures"""
    last_uw_tup = 0
    for i in range(len(uw_arr)):
        if uw_arr[i] != last_uw_tup:
            print("%s%s%s (%s" % (uw_arr[i][0].upper()," "*(long_uw_len+2-len(uw_arr[i][0])), line_dict[uw_arr[i][1]], str(uw_arr[i][1]+1)), end = "")
        else:
            last_uw_tup = uw_arr[i]
            continue
        if i != len(uw_arr)-1 and uw_arr[i] == uw_arr[i+1]:
            print("*)")
        else:
            print(")")
        last_uw_tup = uw_arr[i]

def get_word(tup):
    """Sorting key"""
    return tup[0]

def uw_line_ds(input_file_obj,filter_arr):
    """Creates nessesary data structures."""
    uw_arr = []
    line_dict = {}
    long_uw_len = 0
    for i, line in enumerate(input_file_obj):
        if line == "\n":    #Skips line if its blank
            continue
        line_dict[i] = line.strip()     #removes new line char
        for word in line.strip().split(" "):    #breaks line into word arr
            if word.lower() not in filter_arr:
                uw_arr.append((word.lower(),i))
                if len(word)>long_uw_len:       #finds longest unique word len
                    long_uw_len = len(word)
    return uw_arr, long_uw_len, line_dict

def get_files():
    """Parces command line input into file objects."""
    flag = "-e"
    if len(sys.argv) == 2:
        input_file = open(sys.argv[1],'r')
        return input_file, False    #sets filter to false if flag not provided
    elif len(sys.argv) == 4:
        if sys.argv[1] == flag:
            filter_file = open(sys.argv[2],'r')
            input_file = open(sys.argv[3],'r')
            return input_file, filter_file
        else:
            input_file = open(sys.argv[1],'r')
            filter_file = open(sys.argv[3],'r')
            return input_file, filter_file
    else:
        print("incorrect input format")

def file_lines_to_arr(file_obj):
    """Converts lines of file object to arr."""
    arr = []
    for line in file_obj:
        arr.append(line.strip())
    return arr

if __name__ == "__main__":
    main()
