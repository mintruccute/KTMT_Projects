.data

thongbao: .asciz "Nhap xau: "   # Chuỗi thông báo nhập xâu

yes_msg:   .asciz "La xau doi xung!\n" # Chuỗi thông báo khi xâu là đối xứng

no_msg:    .asciz "Khong phai xau doi xung!\n" # Chuỗi thông báo khi xâu không đối xứng

buffer:    .space 100 

# cấp phát 100 byte để lưu chuỗi nhập (tối đa 99 ký tự thực + 1 byte cho ‘\0’)



.text

main:

    # In thông báo nhập xâu 

    li a7, 4                  # mã dịch vụ a7 = 4  in chuỗi ra màn hình

    la a0, thongbao    # a0 chứa địa chỉ chuỗi thongbao

    ecall                     # thực hiện in thông báo “Nhap xau: “





    # Đọc chuỗi vào buffer

    li a7, 8              # mã dịch vụ a7 = 8  đọc chuỗi từ bàn phím

    la a0, buffer      # a0 chứa địa chỉ vùng nhớ lưu chuỗi

    li a1, 100          # a1 = kích thước tối đa được nhập (tối đa 99 ký tự + 1 chỗ cho ký tự null)

    ecall                 # thực hiện nhập chuỗi vào buffer



# BƯỚC XÓA KÝ TỰ '\n' DO PHÍM ENTER

    mv t5, a0              # t5 trỏ vào đầu chuỗi để xử lý

remove_newline:

    lb t2, 0(t5)           # đọc 1 byte ký tự tại vị trí t5

    beq t2, zero, done_remove  # nếu gặp '\0' thì dừng xóa  nhảy tới nhãn done_remove  

    li t3, 10              # t3 = 10 (mã ASCII của '\n')

    beq t2, t3, set_null   # nếu ký tự là '\n' thì nhảy tới nhãn set_null để thực hiện thay thế

   # nếu kí tự khác ‘\n’ thì thực hiện tiếp câu lệnh bên dưới:

    addi t5, t5, 1        # tăng con trỏ sang ký tự tiếp theo

    j remove_newline # lặp lại quá trình



set_null:

    sb zero, 0(t5)         # ghi '\0' đè lên '\n'



done_remove:



# BƯỚC TÌM ĐỘ DÀI CHUỖI (KHÔNG TÍNH '\0')



    mv t5, a0           # t5 lại trỏ về đầu chuỗi để tính độ dài    

    li t4, 0                # t4 = length = 0



find_length:

    lb t2, 0(t5)           # đọc từng ký tự

    beq t2, zero, done_length  # nếu gặp '\0' thì dừng đếm  nhảy tới nhãn done_length

    addi t4, t4, 1         # tăng độ dài lên 1  length++

    addi t5, t5, 1         # sang ký tự tiếp theo

    j find_length  # lặp lại quá trình



done_length:



 # BƯỚC KIỂM TRA ĐỐI XỨNG (2 CON TRỎ)



    mv t0, a0              # t0 = left pointer (đầu chuỗi)

    add t1, a0, t4         # t1 = a0 + length  trỏ tới ký tự null sau ký tự cuối cùng

    addi t1, t1, -1        # lùi 1 byte  trỏ về ký tự cuối  right pointer (cuối chuỗi)









check_loop:

    bge t0, t1, is_palindrome  

# nếu left >= right  là xâu đối xứng  chuyển tới nhãn is_palindrome  

# nếu không thì thực hiện tiếp câu lệnh bên dưới!



    lb t2, 0(t0)           # lấy  ký tự bên trái (*left)

    lb t3, 0(t1)           # lấy ký tự bên phải (*right)



    bne t2, t3, not_palindrome 

# nếu t2 != t3  không đối xứng  chuyển tới nhãn not_palindrome

# nếu t2 == t3  thu hẹp phạm vi và xét tiếp!!!

    addi t0, t0, 1        # left++

    addi t1, t1, -1      # right--

    j check_loop       # tiếp tục vòng lặp check_loop



is_palindrome:

    li a7, 4                 # mã dịch vụ a7 = 4  in chuỗi ra màn hình

    la a0, yes_msg    # a0 chứa địa chỉ chuỗi yes_msg

    ecall                    # in thông báo “La xau doi xung!\n” ra màn hình

    j end_program    # nhảy tới nhãn end_program



not_palindrome:

    li a7, 4                 # mã dịch vụ a7 = 4  in chuỗi ra màn hình

    la a0, no_msg      # a0 chứa địa chỉ chuỗi no_msg

    ecall                     # in thông báo “Khong phai xau doi xung!\n” ra màn hình



end_program:

    li a7, 10               # mã dịch vụ a7 = 10 + ecall  kết thúc chương trình!

    ecall

