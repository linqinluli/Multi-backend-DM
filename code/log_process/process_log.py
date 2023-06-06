#%%
import csv
file_path = 'thp_off_kvmio.log'
flag = 0
with open(file_path, encoding='utf-8') as file_obj:
    lines = file_obj.readlines()
data = []
for i in range(len(lines)):
    pf = 0
    stime = 0
    utime = 0
    wtime = 0
    dataline = []
    is_data = 0
    # if 'Maximum resident set size (kbytes)' in lines[i]:
    if 'Maximum resident set size (kbytes):' in lines[i]:
        maxrss = float(lines[i].split()[5])
    if lines[i] == 'Size   LDA    Align.  Average  Maximal\n':
        flag = 1
        linelist = lines[i+1].split()
        GFloops = float(linelist[4])
    if 'total images/sec' in lines[i]:
        flag = 2
        imgsec = float(lines[i].split()[2])
      
    if lines[i] == 'Major Page Faults,System Time,User Time,Wall Time\n':
        is_data = 1
        linelist = lines[i+1].split(",")
        pf = int(linelist[0])
        stime = float(linelist[1])
        utime = float(linelist[2])
        wtime = float(linelist[3])
    if is_data == 1:
        if flag == 1:
            imgsec = 0
        if flag == 2:
            GFloops= 0
        dataline = ["kvmio","off","8",pf, stime, utime, wtime, GFloops, imgsec, maxrss]
        with open("test.csv","a",newline='') as csvfile: 
            writer = csv.writer(csvfile)
            writer.writerow(dataline)
        flag = 0
        print(pf, stime, utime, wtime, GFloops, imgsec, maxrss)


# %%
import csv

#python2可以用file替代open
with open("test.csv","w") as csvfile: 
    writer = csv.writer(csvfile)

    #先写入columns_name
    writer.writerow(["index","a_name","b_name"])
    #写入多行用writerows
    writer.writerows([[0,1,3],[1,2,3],[2,3,4]])