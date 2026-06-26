# =========================================================================
# GAME LẬT THẺ 4x4 TRÊN RARS (RISC-V) - ĐẾM GIỜ 90S & MENU ĐIỀU KHIỂN
# =========================================================================

# --- HẰNG SỐ ÁNH XẠ BỘ NHỚ (MEMORY-MAPPED I/O CONSTANTS) ---
.eqv DISPLAY_BASE 0x10008000  # Địa chỉ cơ sở của bộ đệm khung hình (Bitmap Display)
.eqv KBD_CTRL     0xffff0000  # Địa chỉ thanh ghi điều khiển bàn phím (Keyboard Control)
.eqv KBD_DATA     0xffff0004  # Địa chỉ thanh ghi dữ liệu bàn phím (Keyboard Data)

.data
# Mảng lưu giá trị của 16 thẻ (8 cặp màu từ 0 đến 7)
cards:       .byte 0, 0, 1, 1, 2, 2, 3, 3, 4, 4, 5, 5, 6, 6, 7, 7

# Trạng thái của từng thẻ: 0 = Úp, 1 = Đã mở (khớp), 2 = Đang tạm lật
states:      .byte 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0

# Bảng mã màu RGB cho 8 cặp hình ảnh/thẻ
colors:      .word 0xFF0000, 0x00FF00, 0x0000FF, 0xFFFF00, 0xFF00FF, 0x00FFFF, 0xFF8000, 0x800080
color_back:  .word 0x222222  # Màu nền màn hình (Xám tối)
color_down:  .word 0x4A6984  # Màu khi thẻ đang úp
color_cur:   .word 0xFFFFFF  # Màu viền con trỏ chọn (Trắng)

# Các biến trạng thái trò chơi
cursor_x:    .word 0         # Vị trí X của con trỏ (0 -> 3)
cursor_y:    .word 0         # Vị trí Y của con trỏ (0 -> 3)
flipped_cnt: .word 0         # Số lượng thẻ đang lật tạm thời trong lượt (0, 1, hoặc 2)
first_idx:   .word -1        # Chỉ số của thẻ lật đầu tiên
matches:     .word 0         # Số cặp đã hoàn thành (nếu đạt 8 thì thắng)

# Biến thời gian
start_time:  .word 0         # Lưu thời điểm bắt đầu chơi (ms)

# --- Các chuỗi thông báo xuất ra tab Run I/O ---
intro_msg:   .asciz "\n======================================================\n   BAT DAU TRO CHOI! Ban co toi da 90 giay.\n   Hay click vao o Keyboard Simulator de di chuyen va lat the!\n======================================================\n\n"
win_msg:     .asciz "\n>>> CHUC MUNG! BAN DA CHIEN THANG TRONG THOI GIAN QUY DINH! <<<\n"
lose_msg:    .asciz "\n>>> HET GIO (90S)! BAN DA THUA CUOC. <<<\n"

# --- Chuỗi giao diện Menu chính ---
menu_msg:    .asciz "\n================= MENU CHINH =================\n1. Bat dau choi game (Play)\n2. Xem huong dan choi (Rules)\n3. Thoat chuong trinh (Exit)\nNhap lua chon cua ban (1-3): "
invalid_msg: .asciz "-> Lua chon khong hop le! Vui long chi nhap so 1, 2 hoac 3.\n"
rules_msg:   .asciz "\n================ HUONG DAN CHOI ================\n- Di chuyen con tro chon bang cac phim: W (Len), S (Xuong), A (Trai), D (Phai).\n- Nhan phim SPACE (Khoang trang) de lat o dang chon.\n- Luat choi: Tim ra tat ca 8 cap o cung mau trong vong 90 giay.\n- Tro choi cho phep choi lai nhieu lan thong qua Menu.\n================================================\n"
exit_msg:    .asciz "\nChuong trinh ket thuc. Cam on ban da trai nghiem!\n"

.text
.globl main
main:
    # Xóa màn hình Bitmap về màu nền tối trước khi hiển thị Menu
    jal  clear_display       # Gọi hàm clear_display để vẽ nền xám tối lên Bitmap Display

show_menu:
    # 1. Hiển thị Menu chính ra tab Run I/O
    la   a0, menu_msg        # Nạp địa chỉ của chuỗi menu_msg vào a0
    jal  print_string        # Gọi hàm in chuỗi ra Console

    # 2. Đọc lựa chọn đầu vào của người dùng (Xác thực tính hợp lệ)
    li   a7, 5               # Thiết lập a7 = 5 (Syscall 5: Đọc số nguyên từ bàn phím)
    ecall                    # Gọi hệ thống, kết quả lưu vào thanh ghi a0

    li   t0, 1               # t0 = 1
    beq  a0, t0, play_option # Nếu lựa chọn bằng 1, nhảy tới nhãn play_option
    li   t0, 2               # t0 = 2
    beq  a0, t0, rules_option # Nếu lựa chọn bằng 2, nhảy tới nhãn rules_option
    li   t0, 3               # t0 = 3
    beq  a0, t0, exit_option # Nếu lựa chọn bằng 3, nhảy tới nhãn exit_option

    # Trường hợp nhập sai giá trị ngoài khoảng [1, 3]
    la   a0, invalid_msg     # Nạp địa chỉ chuỗi thông báo lỗi nhập sai
    jal  print_string        # In thông báo lỗi ra Console
    j    show_menu           # Nhảy quay lại show_menu để bắt nhập lại

# --- CHI TIẾT CÁC NHÃN ĐIỀU HƯỚNG CHỨC NĂNG ---
rules_option:
    # Hiển thị hướng dẫn rồi quay lại Menu
    jal  show_rules          # Gọi chương trình con in nội dung hướng dẫn
    j    show_menu           # Quay lại hiển thị Menu chính

exit_option:
    # Thoát chương trình
    la   a0, exit_msg        # Nạp địa chỉ chuỗi thông báo thoát
    jal  print_string        # In thông báo thoát ra Console
    li   a7, 10              # Thiết lập a7 = 10 (Syscall 10: Thoát chương trình)
    ecall                    # Gọi hệ thống để kết thúc chương trình

play_option:
    # 3. Reset toàn bộ trạng thái game về ban đầu (Phục vụ chơi lại nhiều lần)
    jal  reset_game_state    # Gọi hàm xóa trạng thái các biến và úp lại các thẻ

    # Hiển thị thông báo bắt đầu
    la   a0, intro_msg       # Nạp địa chỉ chuỗi giới thiệu trò chơi
    jal  print_string        # In thông điệp ra Console

    # Trộn thẻ ngẫu nhiên
    jal  shuffle_cards       # Gọi hàm xáo trộn vị trí ngẫu nhiên của 16 thẻ

    # Ghi lại thời điểm bắt đầu trò chơi (milliseconds)
    li   a7, 30              # Thiết lập a7 = 30 (Syscall 30: Lấy thời gian hệ thống)
    ecall                    # Gọi hệ thống, kết quả trả về ở a0
    la   t0, start_time      # Nạp địa chỉ biến start_time vào t0
    sw   a0, 0(t0)           # Lưu mốc thời gian bắt đầu (a0) vào biến start_time

    # Vẽ màn hình ban đầu
    jal  draw_screen         # Gọi hàm dựng hình vẽ giao diện ban đầu lên Bitmap

game_loop:
    # 4. Kiểm tra giới hạn thời gian (Time Limit Check: 90s)
    li   a7, 30              # Thiết lập a7 = 30 (Syscall 30: Lấy thời gian hiện tại)
    ecall                    # Gọi hệ thống, kết quả hiện tại lưu ở a0
    la   t0, start_time      # Nạp địa chỉ biến start_time
    lw   t1, 0(t0)           # t1 = mốc thời gian bắt đầu
    sub  t2, a0, t1          # t2 = thời gian đã trôi qua (a0 - t1)
    li   t3, 90000           # Thiết lập t3 = 90.000 ms (90 giây)
    bge  t2, t3, lose_state  # Nếu thời gian đã trôi qua >= 90s, nhảy tới lose_state

    # 5. Đọc phím bấm từ MMIO Keyboard (Không chặn / Non-blocking)
    li   t0, KBD_CTRL        # t0 = địa chỉ thanh ghi điều khiển bàn phím (KBD_CTRL)
    lw   t1, 0(t0)           # Đọc giá trị thanh ghi KBD_CTRL vào t1
    andi t1, t1, 1           # Tách bit cuối cùng (Ready bit) để kiểm tra trạng thái nhấn
    beq  t1, zero, game_loop # Nếu Ready bit = 0 (chưa nhấn phím), lặp lại kiểm tra thời gian

    # Nếu có phím, thực hiện đọc dữ liệu phím từ MMIO
    li   t0, KBD_DATA        # t0 = địa chỉ thanh ghi dữ liệu bàn phím (KBD_DATA)
    lw   s0, 0(t0)           # Đọc mã ký tự ASCII từ KBD_DATA lưu vào s0

    # Xử lý lọc phím hợp lệ và điều hướng hành động tương ứng
    li   t0, 119             # t0 = 119 (mã ASCII của phím 'w')
    beq  s0, t0, move_up     # Nếu phím bấm là 'w', nhảy tới move_up
    li   t0, 115             # t0 = 115 (mã ASCII của phím 's')
    beq  s0, t0, move_down   # Nếu phím bấm là 's', nhảy tới move_down
    li   t0, 97              # t0 = 97 (mã ASCII của phím 'a')
    beq  s0, t0, move_left   # Nếu phím bấm là 'a', nhảy tới move_left
    li   t0, 100             # t0 = 100 (mã ASCII của phím 'd')
    beq  s0, t0, move_right  # Nếu phím bấm là 'd', nhảy tới move_right
    li   t0, 32              # t0 = 32 (mã ASCII của phím 'Space')
    beq  s0, t0, action_flip # Nếu phím bấm là 'Space', nhảy tới action_flip
    j    game_loop           # Phím không hợp lệ sẽ bị bỏ qua, tiếp tục vòng lặp

move_up:
    la   t0, cursor_y        # t0 = địa chỉ biến cursor_y (tọa độ Y)
    lw   t1, 0(t0)           # Đọc tọa độ Y hiện tại vào t1
    addi t1, t1, -1          # Trừ đi 1 để di chuyển con trỏ đi lên
    andi t1, t1, 3           # Giới hạn xoay vòng từ 0-3 (nếu vượt quá 0 sẽ vòng lên 3)
    sw   t1, 0(t0)           # Cập nhật tọa độ Y mới vào bộ nhớ
    j    update_and_loop     # Nhảy đến update_and_loop để vẽ lại màn hình

move_down:
    la   t0, cursor_y        # t0 = địa chỉ biến cursor_y (tọa độ Y)
    lw   t1, 0(t0)           # Đọc tọa độ Y hiện tại vào t1
    addi t1, t1, 1           # Cộng thêm 1 để di chuyển con trỏ đi xuống
    andi t1, t1, 3           # Giới hạn xoay vòng từ 0-3 (nếu vượt quá 3 sẽ vòng về 0)
    sw   t1, 0(t0)           # Cập nhật tọa độ Y mới vào bộ nhớ
    j    update_and_loop     # Nhảy đến update_and_loop để vẽ lại màn hình

move_left:
    la   t0, cursor_x        # t0 = địa chỉ biến cursor_x (tọa độ X)
    lw   t1, 0(t0)           # Đọc tọa độ X hiện tại vào t1
    addi t1, t1, -1          # Trừ đi 1 để di chuyển con trỏ sang trái
    andi t1, t1, 3           # Giới hạn xoay vòng từ 0-3 (nếu vượt quá 0 sẽ vòng sang 3)
    sw   t1, 0(t0)           # Cập nhật tọa độ X mới vào bộ nhớ
    j    update_and_loop     # Nhảy đến update_and_loop để vẽ lại màn hình

move_right:
    la   t0, cursor_x        # t0 = địa chỉ biến cursor_x (tọa độ X)
    lw   t1, 0(t0)           # Đọc tọa độ X hiện tại vào t1
    addi t1, t1, 1           # Cộng thêm 1 để di chuyển con trỏ sang phải
    andi t1, t1, 3           # Giới hạn xoay vòng từ 0-3 (nếu vượt quá 3 sẽ vòng về 0)
    sw   t1, 0(t0)           # Cập nhật tọa độ X mới vào bộ nhớ
    j    update_and_loop     # Nhảy đến update_and_loop để vẽ lại màn hình

action_flip:
    # Tính toán chỉ số mảng 1D từ tọa độ con trỏ (row * 4 + col)
    la   t0, cursor_x        # t0 = địa chỉ biến cursor_x
    lw   t1, 0(t0)           # t1 = giá trị cột (col)
    la   t2, cursor_y        # t2 = địa chỉ biến cursor_y
    lw   t3, 0(t2)           # t3 = giá trị hàng (row)
    slli t4, t3, 2           # t4 = row * 4 (phép dịch trái 2 bit tương đương nhân 4)
    add  s1, t4, t1          # s1 = idx (row * 4 + col) để truy cập mảng 1 chiều từ 0-15

    # Kiểm tra trạng thái thẻ tại vị trí này
    la   t0, states          # t0 = địa chỉ mảng states
    add  t0, t0, s1          # t0 = địa chỉ của states[idx]
    lb   t1, 0(t0)           # t1 = trạng thái thẻ tại states[idx]
    bne  t1, zero, game_loop # Nếu trạng thái khác 0 (đã lật hoặc đã khớp), bỏ qua hành động lật

    # Xử lý lật thẻ dựa trên biến flipped_cnt
    la   t2, flipped_cnt     # t2 = địa chỉ biến flipped_cnt
    lw   t3, 0(t2)           # t3 = số lượng thẻ đang tạm lật trong lượt hiện tại (0, 1 hoặc 2)

    bne  t3, zero, handle_second_card # Nếu số thẻ đã lật != 0, nhảy tới xử lý thẻ thứ hai

    # --- Trường hợp đây là thẻ lật đầu tiên trong lượt ---
    li   t4, 2               # t4 = 2 (trạng thái tạm lật)
    sb   t4, 0(t0)           # Đặt states[idx] = 2
    la   t5, first_idx       # t5 = địa chỉ biến first_idx
    sw   s1, 0(t5)           # Lưu chỉ số thẻ lật đầu tiên (s1) vào biến first_idx
    li   t3, 1               # t3 = 1
    sw   t3, 0(t2)           # Cập nhật số thẻ đã lật flipped_cnt = 1
    j    update_and_loop     # Cập nhật màn hình để hiển thị màu thẻ vừa lật

handle_second_card:
    li   t5, 1               # t5 = 1
    bne  t3, t5, game_loop   # Chỉ xử lý lật thẻ thứ hai nếu số thẻ đã lật trước đó bằng 1

    # Đặt thẻ thứ 2 thành trạng thái lật tạm thời
    li   t4, 2               # t4 = 2 (trạng thái tạm lật)
    sb   t4, 0(t0)           # Đặt states[idx_thứ_hai] = 2
    
    # Vẽ lại màn hình ngay để hiển thị cả 2 thẻ vừa lật
    jal  draw_screen         # Gọi vẽ lại màn hình để hiển thị màu cả 2 thẻ đang mở

    # Lấy thông tin thẻ thứ nhất
    la   t5, first_idx       # t5 = địa chỉ biến first_idx
    lw   s2, 0(t5)           # s2 = chỉ số (index) của thẻ thứ nhất

    # So sánh giá trị (màu sắc) của 2 thẻ
    la   t0, cards           # t0 = địa chỉ cơ sở của mảng cards (màu gốc các thẻ)
    add  t1, t0, s1          # t1 = địa chỉ của cards[thẻ_thứ_hai]
    lb   t2, 0(t1)           # t2 = giá trị màu của thẻ thứ hai
    add  t3, t0, s2          # t3 = địa chỉ của cards[thẻ_thứ_nhất]
    lb   t4, 0(t3)           # t4 = giá trị màu của thẻ thứ nhất

    beq  t2, t4, cards_match # Nếu màu thẻ thứ nhất = thẻ thứ hai, nhảy tới cards_match

    # --- Trường hợp 2 thẻ KHÔNG KHỚP màu ---
    li   a0, 800             # a0 = 800 ms
    li   a7, 32              # Thiết lập a7 = 32 (Syscall 32: Sleep trì hoãn)
    ecall                    # Hệ thống tạm ngừng trong 800ms để người chơi nhìn kịp

    # Đặt cả 2 thẻ quay lại trạng thái úp (0)
    la   t0, states          # t0 = địa chỉ mảng states
    add  t1, t0, s1          # t1 = địa chỉ states[thẻ_thứ_hai]
    sb   zero, 0(t1)         # states[thẻ_thứ_hai] = 0 (úp)
    add  t2, t0, s2          # t2 = địa chỉ states[thẻ_thứ_nhất]
    sb   zero, 0(t2)         # states[thẻ_thứ_nhất] = 0 (úp)
    j    reset_turn          # Khởi động lại lượt chơi mới

cards_match:
    # --- Trường hợp 2 thẻ KHỚP màu ---
    la   t0, states          # t0 = địa chỉ mảng states
    add  t1, t0, s1          # t1 = địa chỉ states[thẻ_thứ_hai]
    li   t3, 1               # t3 = 1 (trạng thái đã khớp vĩnh viễn)
    sb   t3, 0(t1)           # states[thẻ_thứ_hai] = 1
    add  t2, t0, s2          # t2 = địa chỉ states[thẻ_thứ_nhất]
    sb   t3, 0(t2)           # states[thẻ_thứ_nhất] = 1

    # Tăng số lượng cặp đã khớp thành công
    la   t4, matches         # t4 = địa chỉ biến matches
    lw   t5, 0(t4)           # t5 = số cặp đã khớp hiện tại
    addi t5, t5, 1           # Tăng thêm 1 cặp khớp thành công
    sw   t5, 0(t4)           # Lưu số cặp khớp mới vào biến matches

reset_turn:
    # Reset lượt chơi hiện tại
    la   t2, flipped_cnt     # t2 = địa chỉ biến flipped_cnt
    sw   zero, 0(t2)         # Reset số thẻ đang lật trong lượt về 0
    la   t5, first_idx       # t5 = địa chỉ biến first_idx
    li   t6, -1              # t6 = -1
    sw   t6, 0(t5)           # Reset index của thẻ thứ nhất về mặc định -1
    j    update_and_loop     # Cập nhật lại giao diện màn hình

update_and_loop:
    # Vẽ lại màn hình game
    jal  draw_screen         # Gọi hàm render lại giao diện game trên Bitmap

    # Kiểm tra điều kiện thắng cuộc
    la   t0, matches         # t0 = địa chỉ biến matches
    lw   t1, 0(t0)           # t1 = số lượng cặp đã khớp thành công
    li   t2, 8               # t2 = 8 (ngưỡng chiến thắng)
    beq  t1, t2, win_state   # Nếu đã ghép thành công cả 8 cặp, nhảy tới win_state
    j    game_loop           # Ngược lại, quay về vòng lặp chính game_loop


# =========================================================================
# CÁC CHƯƠNG TRÌNH CON HỖ TRỢ (SUBROUTINES)
# =========================================================================

# --- Chương trình con hiển thị nội dung Hướng dẫn chơi ---
show_rules:
    addi sp, sp, -16         # Khởi tạo không gian stack (16 bytes)
    sw   ra, 12(sp)          # Lưu trữ thanh ghi liên kết ra vào stack để tránh ghi đè
    la   a0, rules_msg       # Nạp địa chỉ chuỗi hướng dẫn vào a0
    jal  print_string        # Gọi chương trình con in chuỗi ra Console
    lw   ra, 12(sp)          # Khôi phục giá trị thanh ghi ra từ stack
    addi sp, sp, 16          # Giải phóng không gian stack
    ret                      # Trở về nơi gọi hàm

# --- Chương trình con dọn dẹp và khôi phục trạng thái ban đầu ---
reset_game_state:
    # 1. Reset mảng trạng thái thẻ (states) 16 phần tử về 0 (úp thẻ)
    la   t0, states          # t0 = địa chỉ cơ sở của mảng states
    li   t1, 0               # t1 = chỉ số chạy i (khởi tạo bằng 0)
    li   t2, 16              # t2 = kích thước tối đa của mảng (16 bytes)
reset_states_loop:
    bge  t1, t2, reset_states_done # Nếu chỉ số i >= kích thước 16, thoát vòng lặp
    add  t3, t0, t1          # t3 = địa chỉ phần tử hiện tại: states + i
    sb   zero, 0(t3)         # Ghi đè giá trị 0 (kiểu byte) vào states[i] để úp thẻ
    addi t1, t1, 1           # Tăng chỉ số i lên 1 (i = i + 1)
    j    reset_states_loop   # Nhảy quay lại để tiếp tục vòng lặp
reset_states_done:

    # 2. Đặt lại các biến trạng thái trò chơi về mặc định
    la   t0, cursor_x        # t0 = địa chỉ biến cursor_x
    sw   zero, 0(t0)         # Đặt cursor_x = 0 (về cột đầu tiên)
    la   t0, cursor_y        # t0 = địa chỉ biến cursor_y
    sw   zero, 0(t0)         # Đặt cursor_y = 0 (về hàng đầu tiên)
    la   t0, flipped_cnt     # t0 = địa chỉ biến flipped_cnt
    sw   zero, 0(t0)         # Đặt flipped_cnt = 0 (chưa lật thẻ nào trong lượt mới)
    la   t0, first_idx       # t0 = địa chỉ biến first_idx
    li   t1, -1              # t1 = -1
    sw   t1, 0(t0)           # Đặt first_idx = -1 (chưa chọn thẻ 1)
    la   t0, matches         # t0 = địa chỉ biến matches
    sw   zero, 0(t0)         # Đặt matches = 0 (chưa ghép được cặp nào)
    ret                      # Trở về nơi gọi hàm

# --- Chương trình con xóa màn hình Bitmap (Clear screen) ---
clear_display:
    addi sp, sp, -16         # Khởi tạo không gian stack (16 bytes)
    sw   ra, 12(sp)          # Lưu thanh ghi liên kết ra
    li   a0, 0               # Thiết lập tham số x_start = 0
    li   a1, 0               # Thiết lập tham số y_start = 0
    li   a2, 64              # Thiết lập tham số chiều rộng w = 64 đơn vị
    li   a3, 64              # Thiết lập tham số chiều cao h = 64 đơn vị
    la   t0, color_back      # Nạp địa chỉ của mã màu nền
    lw   a4, 0(t0)           # a4 = giá trị màu nền (Xám tối)
    jal  draw_rect           # Gọi hàm vẽ đè hình chữ nhật bao phủ toàn màn hình
    lw   ra, 12(sp)          # Khôi phục thanh ghi ra từ stack
    addi sp, sp, 16          # Giải phóng không gian stack
    ret                      # Trở về nơi gọi hàm

# --- Hàm in một chuỗi ký tự ra Console ---
print_string:
    li   a7, 4               # Thiết lập a7 = 4 (Syscall 4: Print String)
    ecall                    # Gọi hệ thống để in chuỗi có địa chỉ lưu ở a0
    ret                      # Trở về nơi gọi hàm

# --- Hàm trộn các thẻ ngẫu nhiên (Shuffle cards) ---
shuffle_cards:
    addi sp, sp, -16         # Khởi tạo không gian stack
    sw   ra, 12(sp)          # Lưu thanh ghi liên kết ra
    sw   s0, 8(sp)           # Lưu thanh ghi s0
    sw   s1, 4(sp)           # Lưu thanh ghi s1

    li   s0, 15              # s0 = i (Khởi tạo bắt đầu từ 15 và lùi về 1)
shuffle_loop:
    ble  s0, zero, shuffle_done # Nếu chỉ số i <= 0, hoàn tất quá trình trộn thẻ
    # Tạo số ngẫu nhiên j trong đoạn [0, i] bằng syscall 42
    addi a1, s0, 1           # Cận trên (không bao gồm): i + 1
    li   a0, 0               # Định danh máy phát ngẫu nhiên số 0
    li   a7, 42              # Thiết lập a7 = 42 (Syscall 42: Sinh số ngẫu nhiên có giới hạn)
    ecall                    # Gọi hệ thống, kết quả ngẫu nhiên lưu tại a0 (chính là chỉ số j)
    mv   s1, a0              # s1 = j

    # Tráo đổi giá trị cards[i] và cards[j]
    la   t0, cards           # t0 = địa chỉ cơ sở của mảng cards
    add  t1, t0, s0          # t1 = địa chỉ của cards[i]
    add  t2, t0, s1          # t2 = địa chỉ của cards[j]
    lb   t3, 0(t1)           # t3 = giá trị byte tại cards[i]
    lb   t4, 0(t2)           # t4 = giá trị byte tại cards[j]
    sb   t4, 0(t1)           # Ghi giá trị cũ của cards[j] vào cards[i]
    sb   t3, 0(t2)           # Ghi giá trị cũ của cards[i] vào cards[j]

    addi s0, s0, -1          # i = i - 1 (lùi về phần tử trước)
    j    shuffle_loop        # Tiếp tục vòng lặp trộn thẻ

shuffle_done:
    lw   s1, 4(sp)           # Khôi phục thanh ghi s1 từ stack
    lw   s0, 8(sp)           # Khôi phục thanh ghi s0 từ stack
    lw   ra, 12(sp)          # Khôi phục thanh ghi liên kết ra
    addi sp, sp, 16          # Giải phóng không gian stack
    ret                      # Trở về nơi gọi hàm

# --- Hàm vẽ toàn bộ màn hình game ---
draw_screen:
    addi sp, sp, -32         # Tạo không gian stack (32 bytes)
    sw   ra, 28(sp)          # Lưu thanh ghi liên kết ra
    sw   s0, 24(sp)          # Lưu s0 (dùng cho vòng lặp dòng)
    sw   s1, 20(sp)          # Lưu s1 (dùng cho vòng lặp cột)
    sw   s2, 16(sp)          # Lưu s2 (dùng chứa tọa độ hiển thị x_start)
    sw   s3, 12(sp)          # Lưu s3 (dùng chứa tọa độ hiển thị y_start)
    sw   s4, 8(sp)           # Lưu s4 (dùng làm chỉ số thẻ hiện tại)

    # 1. Vẽ đè nền màu xám tối lên toàn bộ màn hình để làm sạch khung hình cũ
    li   a0, 0               # x = 0
    li   a1, 0               # y = 0
    li   a2, 64              # w = 64
    li   a3, 64              # h = 64
    la   t0, color_back      # Nạp địa chỉ màu nền xám tối
    lw   a4, 0(t0)           # Nạp mã màu nền vào a4
    jal  draw_rect           # Gọi hàm vẽ hình nền đặc

    # 2. Vẽ 16 thẻ ô vuông theo dạng lưới 4x4
    li   s0, 0               # s0 = row (0 -> 3)
draw_row:
    li   s1, 0               # s1 = col (0 -> 3)
draw_col:
    # Tính toán tọa độ hiển thị trên màn hình:
    # x_start = 3 + col * 15
    # y_start = 3 + row * 15
    li   t0, 15              # t0 = 15
    mul  s2, s1, t0          # s2 = col * 15
    addi s2, s2, 3           # s2 = x_start (col * 15 + 3)
    mul  s3, s0, t0          # s3 = row * 15
    addi s3, s3, 3           # s3 = y_start (row * 15 + 3)

    # Xác định màu sắc của thẻ hiện tại dựa trên trạng thái
    slli t1, s0, 2           # t1 = row * 4
    add  s4, t1, s1          # s4 = idx (row * 4 + col)

    la   t0, states          # t0 = địa chỉ mảng states
    add  t1, t0, s4          # t1 = địa chỉ states[idx]
    lb   t2, 0(t1)           # t2 = trạng thái hiện tại (0, 1 hoặc 2)

    beq  t2, zero, draw_card_down # Nếu trạng thái = 0 (úp), nhảy tới draw_card_down

    # Nếu thẻ đang mở hoặc tạm lật thì vẽ theo màu của thẻ đó
    la   t0, cards           # t0 = địa chỉ mảng cards
    add  t1, t0, s4          # t1 = địa chỉ cards[idx]
    lb   t3, 0(t1)           # t3 = chỉ số màu của thẻ (0 -> 7)
    slli t3, t3, 2           # t3 = chỉ số màu * 4 (để tính địa chỉ từ kiểu word)
    la   t4, colors          # t4 = địa chỉ bảng màu colors
    add  t4, t4, t3          # t4 = địa chỉ của mã màu colors[chỉ_số]
    lw   a4, 0(t4)           # a4 = mã màu RGB tương ứng
    j    do_draw             # Tiến hành vẽ thẻ mở màu

draw_card_down:
    la   t0, color_down      # Nạp địa chỉ màu thẻ úp
    lw   a4, 0(t0)           # a4 = màu xanh xám của thẻ úp

do_draw:
    mv   a0, s2              # Tham số a0 = x_start
    mv   a1, s3              # Tham số a1 = y_start
    li   a2, 12              # Chiều rộng thẻ a2 = 12 đơn vị
    li   a3, 12              # Chiều cao thẻ a3 = 12 đơn vị
    jal  draw_rect           # Gọi hàm vẽ đè hình chữ nhật thẻ lên màn hình

    # Vẽ viền con trỏ nếu tọa độ trùng với vị trí hiện tại của người chơi
    la   t0, cursor_x        # t0 = địa chỉ con trỏ X hiện tại
    lw   t1, 0(t0)           # t1 = cursor_x
    bne  s1, t1, skip_cursor # Nếu cột hiện tại != cursor_x, bỏ qua việc vẽ viền con trỏ
    la   t0, cursor_y        # t0 = địa chỉ con trỏ Y hiện tại
    lw   t1, 0(t0)           # t1 = cursor_y
    bne  s0, t1, skip_cursor # Nếu hàng hiện tại != cursor_y, bỏ qua việc vẽ viền con trỏ

    # Vẽ viền màu trắng bao quanh thẻ đang được chọn
    mv   a0, s2              # Tham số a0 = x_start
    mv   a1, s3              # Tham số a1 = y_start
    li   a2, 12              # Chiều rộng viền a2 = 12 đơn vị
    li   a3, 12              # Chiều cao viền a3 = 12 đơn vị
    la   t0, color_cur       # Nạp địa chỉ màu viền trắng
    lw   a4, 0(t0)           # a4 = màu trắng
    jal  draw_border         # Gọi hàm vẽ khung viền rỗng

skip_cursor:
    addi s1, s1, 1           # Tăng chỉ số cột s1 lên 1 (col = col + 1)
    li   t0, 4               # t0 = 4
    blt  s1, t0, draw_col    # Nếu cột s1 < 4, tiếp tục vòng lặp cột vẽ ô kế tiếp
    addi s0, s0, 1           # Tăng chỉ số hàng s0 lên 1 (row = row + 1)
    blt  s0, t0, draw_row    # Nếu hàng s0 < 4, tiếp tục vòng lặp hàng vẽ dòng kế tiếp

    lw   s4, 8(sp)           # Khôi phục thanh ghi s4 từ stack
    lw   s3, 12(sp)          # Khôi phục thanh ghi s3 từ stack
    lw   s2, 16(sp)          # Khôi phục thanh ghi s2 từ stack
    lw   s1, 20(sp)          # Khôi phục thanh ghi s1 từ stack
    lw   s0, 24(sp)          # Khôi phục thanh ghi s0 từ stack
    lw   ra, 28(sp)          # Khôi phục thanh ghi liên kết ra
    addi sp, sp, 32          # Giải phóng không gian stack
    ret                      # Trở về nơi gọi hàm

# --- Hàm vẽ hình chữ nhật đặc (Rectangle) ---
# Tham số đầu vào: a0 = x, a1 = y, a2 = w, a3 = h, a4 = color
draw_rect:
    li   t0, DISPLAY_BASE    # t0 = Địa chỉ cơ sở Bitmap Display (0x10008000)
    mv   t1, a1              # t1 = cy (bắt đầu vẽ hàng hiện tại từ y)
    add  t2, a1, a3          # t2 = y + h (điểm dừng hàng vẽ)
outer_loop:
    bge  t1, t2, rect_done   # Nếu hàng hiện tại cy >= y + h, kết thúc vẽ hình chữ nhật
    mv   t3, a0              # t3 = cx (bắt đầu vẽ cột hiện tại từ x)
    add  t4, a0, a2          # t4 = x + w (điểm dừng cột vẽ)

    # Tính toán địa chỉ nền cho dòng hiện tại: base + (cy * 64 * 4) -> cy * 256
    slli t5, t1, 8           # t5 = cy * 256 (phép toán tương đương nhân 256 bằng dịch trái 8 bit)
    add  t5, t5, t0          # t5 = t5 + base (địa chỉ của pixel đầu dòng hiện tại)

inner_loop:
    bge  t3, t4, inner_done  # Nếu cột hiện tại cx >= x + w, kết thúc hàng vẽ hiện tại
    slli t6, t3, 2           # t6 = cx * 4 (mỗi pixel màu có dung lượng 4 bytes)
    add  t6, t5, t6          # t6 = địa chỉ tuyệt đối của pixel đích
    sw   a4, 0(t6)           # Ghi mã màu (a4) trực tiếp vào bộ đệm của pixel đích
    addi t3, t3, 1           # Tăng tọa độ cột hiện tại cx lên 1
    j    inner_loop          # Lặp tiếp vẽ pixel tiếp theo cùng dòng
inner_done:
    addi t1, t1, 1           # Di chuyển xuống dòng vẽ tiếp theo (cy = cy + 1)
    j    outer_loop          # Lặp tiếp vòng lặp hàng
rect_done:
    ret                      # Kết thúc hàm vẽ hình chữ nhật đặc, quay lại nơi gọi

# --- Hàm vẽ khung viền rỗng (Border) ---
# Tham số đầu vào: a0 = x, a1 = y, a2 = w, a3 = h, a4 = color
draw_border:
    addi sp, sp, -32         # Tạo không gian stack (32 bytes)
    sw   ra, 28(sp)          # Lưu thanh ghi liên kết ra
    sw   s0, 24(sp)          # Lưu s0
    sw   s1, 20(sp)          # Lưu s1
    sw   s2, 16(sp)          # Lưu s2
    sw   s3, 12(sp)          # Lưu s3

    mv   s0, a0              # s0 = x
    mv   s1, a1              # s1 = y
    mv   s2, a2              # s2 = w
    mv   s3, a3              # s3 = h

    # Vẽ dòng ngang phía trên cùng
    mv   a0, s0              # x_start
    mv   a1, s1              # y_start
    mv   a2, s2              # w
    li   a3, 1               # h = 1
    jal  draw_rect           # Gọi hàm vẽ hình chữ nhật dẹt làm nét ngang trên

    # Vẽ dòng dọc bên trái
    mv   a0, s0              # x_start
    mv   a1, s1              # y_start
    li   a2, 1               # w = 1
    mv   a3, s3              # h
    jal  draw_rect           # Gọi hàm vẽ hình chữ nhật dẹt làm nét dọc trái

    # Vẽ dòng ngang phía dưới cùng
    mv   a0, s0              # x_start
    add  a1, s1, s3          # y + h
    addi a1, a1, -1          # y_start = y + h - 1 (dòng dưới cùng)
    mv   a2, s2              # w
    li   a3, 1               # h = 1
    jal  draw_rect           # Gọi hàm vẽ hình chữ nhật dẹt làm nét ngang dưới

    # Vẽ dòng dọc bên phải
    add  a0, s0, s2          # x + w
    addi a0, a0, -1          # x_start = x + w - 1 (cột ngoài cùng bên phải)
    mv   a1, s1              # y_start
    li   a2, 1               # w = 1
    mv   a3, s3              # h
    jal  draw_rect           # Gọi hàm vẽ hình chữ nhật dẹt làm nét dọc phải

    lw   s3, 12(sp)          # Khôi phục s3 từ stack
    lw   s2, 16(sp)          # Khôi phục s2 từ stack
    lw   s1, 20(sp)          # Khôi phục s1 từ stack
    lw   s0, 24(sp)          # Khôi phục s0 từ stack
    lw   ra, 28(sp)          # Khôi phục thanh ghi ra từ stack
    addi sp, sp, 32          # Giải phóng không gian stack
    ret                      # Trở về nơi gọi hàm


# --- Trạng thái chiến thắng (Win State) ---
win_state:
    # Tô màn hình thành màu xanh lá cây đậm
    li   a0, 0               # x = 0
    li   a1, 0               # y = 0
    li   a2, 64              # w = 64
    li   a3, 64              # h = 64
    li   a4, 0x006400        # Màu RGB của Dark Green
    jal  draw_rect           # Vẽ đè màu xanh lá cây đậm lên toàn màn hình hiển thị

    # Xuất thông báo thắng ra màn hình Run I/O console
    la   a0, win_msg         # Nạp địa chỉ của chuỗi thắng cuộc
    jal  print_string        # In thông báo ra Console

    # Tạm dừng 3000ms để người chơi nhìn rõ kết quả
    li   a0, 3000            # a0 = 3000 ms
    li   a7, 32              # Thiết lập a7 = 32 (Syscall 32: Sleep)
    ecall                    # Trì hoãn 3 giây để người chơi nhìn màn hình thắng cuộc

    # Reset màn hình về màu nền và quay trở lại Menu chính
    jal  clear_display       # Gọi hàm xóa màn hình đồ họa về xám tối ban đầu
    j    show_menu           # Nhảy quay về đầu show_menu để hiển thị lại Menu chính


# --- Trạng thái thất bại khi quá giờ (Lose State) ---
lose_state:
    # Tô màn hình thành màu đỏ đậm để biểu thị thất bại
    li   a0, 0               # x = 0
    li   a1, 0               # y = 0
    li   a2, 64              # w = 64
    li   a3, 64              # h = 64
    li   a4, 0x8B0000        # Màu RGB của Dark Red
    jal  draw_rect           # Vẽ đè màu đỏ đậm lên toàn màn hình hiển thị

    # Xuất thông báo thua ra màn hình Run I/O console
    la   a0, lose_msg        # Nạp địa chỉ của chuỗi thua cuộc
    jal  print_string        # In thông báo ra Console

    # Tạm dừng 3000ms để người chơi nhìn rõ kết quả
    li   a0, 3000            # a0 = 3000 ms
    li   a7, 32              # Thiết lập a7 = 32 (Syscall 32: Sleep)
    ecall                    # Trì hoãn 3 giây để người chơi nhìn màn hình thua cuộc

    # Reset màn hình về màu nền và quay trở lại Menu chính
    jal  clear_display       # Gọi hàm xóa màn hình đồ họa về xám tối ban đầu
    j    show_menu           # Nhảy quay về đầu show_menu để hiển thị lại Menu chính