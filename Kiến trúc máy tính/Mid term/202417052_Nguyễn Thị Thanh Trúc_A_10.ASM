.data

msg1: .asciz "Nhap N: "                 #Chuỗi thông báo nhập số

msg2: .asciz "So dao nguoc la: "    #Chuỗi in kết quả 

.text

main:

 # In câu dẫn:

    li a7, 4         # mã dịch vụ a7 = 4  in chuỗi ra màn hình

    la a0, msg1  # a0 = địa chỉ của chuỗi msg1

    ecall             # gọi hệ điều hành in chuỗi msg1: “Nhap N: ”

 # Nhập số N

    li a7, 5           # mã dịch vụ a7 = 5  nhập số nguyên

    ecall              # gọi hệ điều hành: nhập N từ bàn phím, lưu vào thanh ghi a0 hay a0 = N

    li t0, 0    # t0 = reverse = 0  khởi tạo số đảo: sau mỗi vòng lặp t0 = t0 * 10 + n%10 

    li t2, 10  # t2 =10   dùng để chia 10 và nhân 10



reverse_loop:

    beq a0, zero, print_result   # nếu a0 = N = 0 thì dừng  nhảy tới nhãn print_resul

    # nếu a0 = N != 0 thực hiện tiếp câu lệnh bên dưới:

    rem t1, a0, t2    # t1 = a0 % 10  lấy chữ số cuối cùng

    div a0, a0, t2    # N = N / 10  bỏ chữ số cuối cùng



    mul t0, t0, t2    # t0 = t0 * 10 

    add t0, t0, t1    # t0 = t0 + t1 = t0 + (N % 10)

#  t0 = reverse = t0 * 10 + (N % 10)  cập nhật số đảo



    j reverse_loop # quay lại đầu vòng lặp



print_result:

  # In thông báo

    li a7, 4            # mã dịch vụ a7 = 4  in chuỗi ra màn hình

    la a0, msg2     # a0 = địa chỉ của chuỗi msg2

    ecall                # gọi hệ điều hành in chuỗi msg2: “So dao nguoc la: ”



  # In số đảo

    mv a0, t0       # move t0  a0: a0 = giá trị đảo để in ra màn hình

    li a7, 1           # mã dịch vụ a7 = 1  in số nguyên ra màn hình

    ecall              # in số đảo



  # Kết thúc

    li a7, 10  # mã dịch vụ a7 = 10 + ecall  kết thúc chương trình!

    ecall



