# ---- stream_data_generation.py ---
# generating a growing data file

import time

if __name__=="__main__":
    line_number = 1
    while True:
        file_stream = open("stream_data.txt", "a")
        contents = '-- This is Line: '+str(line_number)+' -- \n'
        file_stream.write(contents)
        file_stream.close()
        time.sleep(2)
        line_number = line_number +1
        print(line_number)
        if line_number == 3600: 
            break
        continue

