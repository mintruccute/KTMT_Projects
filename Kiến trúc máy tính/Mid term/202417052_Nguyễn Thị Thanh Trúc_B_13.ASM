.data

arr:    .space 400 

# cấp phát bộ nhớ cho mảng (tối đa 100 phần tử, mỗi số nguyên chiếm 4 byte trong bộ nhớ)

msg1:   .asciz "Nhap n: "   # chuỗi thông báo nhập số phần tử n

msg2:   .asciz "Nhap: "      # chuỗi thông báo nhập n phần tử

msg3:   .asciz "So gia tri khac nhau: "     # chuỗi in kết quả



.text

main:

# nhập n

    li a7, 4                      # mã dịch vụ a7 = 4   in chuỗi

    la a0, msg1              # a0 = địa chỉ chuỗi msg1

    ecall                         # in "Nhap n: "

    li a7, 5                      # mã dịch vụ a7 = 5  nhập số nguyên

    ecall                         # đọc n từ bàn phím  lưu n vào thanh ghi a0

    mv s0, a0                 # move giá trị n từ thanh ghi a0  s0 hay s0 = n  lưu số phần tử



# nhập mảng 

    la s1, arr                   # s1 trỏ tới đầu mảng

    li t0, 0                      # t0 = i = 0



nhap:

    beq t0, s0, dem # nếu i = n chuyển sang nhãn dem  thực hiện đếm số phần tử khác nhau

   # nếu không thì thực hiện câu lệnh bên dưới:

    li a7, 4                      # mã dịch vụ a7 = 4  in chuỗi ra màn hình

    la a0, msg2              # s0 = địa chỉ chuỗi msg2

    ecall                         # in "Nhap: "



    li a7, 5                      # mã dịch vụ a7 = 5  nhập số nguyên

    ecall                         # đọc số nguyên từ bàn phím  lưu vào thanh ghi a0



    sw a0, 0(s1)             # lưu vào arr[i]

    addi s1, s1, 4               # con trỏ trỏ sang phần tử kế tiếp (mỗi int 4 byte)

    addi t0, t0, 1                # i++

    j nhap                          # lặp lại bước nhập các phần tử trong mảng



# Đếm số giá trị khác nhau 

dem:

    li s2, 0                      # khởi tạo s2 = count = 0

    li t0, 0                      # i = 0

    la s1, arr                  # s1 trỏ tới đầu mảng

loop_ngoai:

    beq t0, s0, in_kq            # nếu i == n  nhảy tới nhãn in_kq (in kết quả)

    lw t1, 0(s1)              # t1 = arr[i]

    la t3, arr                   # t3 trỏ arr[0]

    li t2, 0                      # t2 = j = 0

loop_trong:

    beq t2, t0, tang             # nếu j == i  chưa trùng  tăng count

    # nếu không thì xét tiếp câu lệnh bên dưới:

    lw t4, 0(t3)                  # t4 = arr[j]

    beq t1, t4, boqua         # nếu trùng  nhảy tới nhãn bỏ qua (không tăng count)

    # nếu chưa trùng thì tăng j xét tiếp

    addi t3, t3, 4                # trỏ sang arr[j+1]

    addi t2, t2, 1                # j++

    j loop_trong                # tiếp tục so sánh (thực hiện vòng for trong)



tang:

    addi s2, s2, 1                # count++

boqua:

    addi s1, s1, 4               # trỏ sang arr[i+1]

    addi t0, t0, 1                # i++

    j loop_ngoai                # quay lại vòng for ngoài





#  In kết quả 

in_kq:

    li a7, 4                      # mã dịch vụ a7 = 4  in chuỗi ra màn hình

    la a0, msg3              # a0 = địa chỉ chuỗi msg3

    ecall                         # in thông báo



    li a7, 1                      # mã dịch vụ a7 = 1  in số nguyên

    mv a0, s2                 # s2 = count  truyền giá trị vào thanh ghi a0

    ecall                         # in count ra màn hình



    li a7, 10                     # mã dịch vụ a7 = 10 + ecall  kết thúc chương trình

    ecall             

