import docx
from docx.shared import Inches, Pt, RGBColor
from docx.enum.text import WD_ALIGN_PARAGRAPH
from docx.enum.table import WD_TABLE_ALIGNMENT
from docx.oxml import OxmlElement, parse_xml
from docx.oxml.ns import nsdecls, qn

def create_element(name):
    return OxmlElement(name)

def set_cell_background(cell, fill_hex):
    shading_elm = parse_xml(f'<w:shd {nsdecls("w")} w:fill="{fill_hex}"/>')
    cell._tc.get_or_add_tcPr().append(shading_elm)

def set_cell_margins(cell, top=100, bottom=100, left=150, right=150):
    tcPr = cell._tc.get_or_add_tcPr()
    tcMar = OxmlElement('w:tcMar')
    for m, val in [('top', top), ('bottom', bottom), ('left', left), ('right', right)]:
        node = OxmlElement(f'w:{m}')
        node.set(qn('w:w'), str(val))
        node.set(qn('w:type'), 'dxa')
        tcMar.append(node)
    tcPr.append(tcMar)

def generate_doc():
    doc = docx.Document()
    
    # Page Margins (1 inch)
    for section in doc.sections:
        section.top_margin = Inches(1)
        section.bottom_margin = Inches(1)
        section.left_margin = Inches(1)
        section.right_margin = Inches(1)

    # Styles setup
    style_normal = doc.styles['Normal']
    font_normal = style_normal.font
    font_normal.name = 'Calibri'
    font_normal.size = Pt(11)
    font_normal.color.rgb = RGBColor(0x22, 0x22, 0x22)

    # Title
    p_title = doc.add_paragraph()
    p_title.alignment = WD_ALIGN_PARAGRAPH.CENTER
    run_title = p_title.add_run("TÀI LIỆU MÔ TẢ CHI TIẾT PHẦN MỀM\nCALLTIMER iOS")
    run_title.font.size = Pt(22)
    run_title.font.bold = True
    run_title.font.color.rgb = RGBColor(0x0A, 0x36, 0x9D)
    
    # Subtitle
    p_sub = doc.add_paragraph()
    p_sub.alignment = WD_ALIGN_PARAGRAPH.CENTER
    run_sub = p_sub.add_run("Ứng dụng Nhắc nhở Thời lượng Cuộc gọi & Đếm ngược Dynamic Island cho iPhone 15 Pro Max")
    run_sub.font.size = Pt(12)
    run_sub.font.italic = True
    run_sub.font.color.rgb = RGBColor(0x55, 0x55, 0x55)
    
    doc.add_paragraph().paragraph_format.space_after = Pt(12)

    # Helper function for headings
    def add_custom_heading(text, level=1):
        p = doc.add_paragraph()
        p.paragraph_format.space_before = Pt(14)
        p.paragraph_format.space_after = Pt(6)
        p.paragraph_format.keep_with_next = True
        run = p.add_run(text)
        run.bold = True
        if level == 1:
            run.font.size = Pt(15)
            run.font.color.rgb = RGBColor(0x0A, 0x36, 0x9D)
        elif level == 2:
            run.font.size = Pt(13)
            run.font.color.rgb = RGBColor(0x00, 0x66, 0xCC)
        return p

    # Section 1: Overview
    add_custom_heading("1. TỔNG QUAN PHẦN MỀM", level=1)
    
    # Summary Table
    table_info = doc.add_table(rows=5, cols=2)
    table_info.alignment = WD_TABLE_ALIGNMENT.CENTER
    table_info.autofit = False
    
    info_data = [
        ("Tên phần mềm", "CallTimer iOS (Call Duration Reminder & Dynamic Island Tracker)"),
        ("Nền tảng hỗ trợ", "iOS 17.0+ (Tối ưu đặc biệt cho iPhone 15 Pro Max)"),
        ("Mục đích phát triển", "Cấu hình và đếm ngược thời gian gọi tối đa cho từng eSIM (eSIM 1 & eSIM 2), cảnh báo chuông/rung trước khi chạm mốc vượt cước."),
        ("Thư mục lưu trữ local", "D:\\AI Agent - SelfStudies\\Time for Call on Iphone"),
        ("GitHub Repository", "https://github.com/nghia-AOF/CallTimer")
    ]
    
    col_widths = [Inches(2.0), Inches(4.5)]
    for i, (label, val) in enumerate(info_data):
        row = table_info.rows[i]
        cell_lbl, cell_val = row.cells[0], row.cells[1]
        
        cell_lbl.width, cell_val.width = col_widths[0], col_widths[1]
        set_cell_background(cell_lbl, "F0 F4 F8" if i % 2 == 0 else "FFFFFF")
        set_cell_background(cell_val, "F0 F4 F8" if i % 2 == 0 else "FFFFFF")
        set_cell_margins(cell_lbl, top=80, bottom=80, left=120, right=120)
        set_cell_margins(cell_val, top=80, bottom=80, left=120, right=120)
        
        p_lbl = cell_lbl.paragraphs[0]
        r_lbl = p_lbl.add_run(label)
        r_lbl.bold = True
        r_lbl.font.color.rgb = RGBColor(0x0A, 0x36, 0x9D)
        
        p_val = cell_val.paragraphs[0]
        p_val.add_run(val)

    doc.add_paragraph().paragraph_format.space_after = Pt(10)

    # Section 2: Key Features
    add_custom_heading("2. TÍNH NĂNG NỔI BẬT", level=1)

    add_custom_heading("2.1. Cấu hình thời lượng gọi riêng biệt cho eSIM 1 & eSIM 2", level=2)
    p = doc.add_paragraph()
    p.add_run("• Người dùng cài đặt số phút và số giây tối đa độc lập cho từng SIM (Ví dụ: eSIM 1 SIM Công việc đặt 9 phút 30 giây; eSIM 2 SIM Cá nhân đặt 14 phút 30 giây).\n")
    p.add_run("• Dữ liệu cấu hình tự động được lưu trữ bền vững trong hệ thống bằng ")
    r_code = p.add_run("UserDefaults")
    r_code.font.name = "Consolas"
    p.add_run(", người dùng không cần phải thiết lập lại ở các lần bật app tiếp theo.")

    add_custom_heading("2.2. Hiển thị đếm ngược thời gian thực trên Dynamic Island & Lock Screen", level=2)
    p = doc.add_paragraph()
    p.add_run("• Ứng dụng tích hợp framework ")
    r_code = p.add_run("ActivityKit & Live Activities")
    r_code.font.name = "Consolas"
    p.add_run(" chuẩn của Apple dành riêng cho iPhone 15 Pro Max.\n")
    p.add_run("• Khi bấm cuộc gọi, bộ đếm ngược thời gian thực sẽ thu nhỏ lên thanh Đảo động (Dynamic Island) ở đỉnh màn hình ở cả 2 chế độ:\n")
    p.add_run("   - Chế độ Compact: Hiển thị icon đồng hồ bên trái và thời gian còn lại (MM:SS) bên phải.\n")
    p.add_run("   - Chế độ Expanded (khi nhấn giữ): Hiển thị đầy đủ thông tin eSIM đang gọi, nhãn cảnh báo và bộ đếm cỡ lớn.\n")
    p.add_run("• Banner đếm ngược xuất hiện trực tiếp trên Màn hình khóa (Lock Screen) và Trung tâm thông báo.")

    add_custom_heading("2.3. Hệ thống Cảnh báo Thông minh (Chuông + Rung Haptics)", level=2)
    p = doc.add_paragraph()
    p.add_run("• Cảnh báo Vàng (30 giây trước mốc giới hạn): Phát rung Haptics nhẹ kèm âm thanh thông báo chuẩn bị dập máy.\n")
    p.add_run("• Cảnh báo Đỏ (Chạm mốc thời gian tối đa): Phát hệ thống rung liên tục và chuông cảnh báo lớn (AudioServicesPlaySystemSound).\n")
    p.add_run("• Cơ chế thông báo cục bộ ")
    r_code = p.add_run("UNUserNotificationCenter")
    r_code.font.name = "Consolas"
    p.add_run(" đảm bảo hoạt động chính xác 100% ngay cả khi iPhone tắt màn hình hoặc app đang chạy ngầm.")

    add_custom_heading("2.4. Khởi chạy cuộc gọi hệ thống nhanh", level=2)
    p = doc.add_paragraph()
    p.add_run("• Tích hợp ô nhập số điện thoại cần gọi và liên kết URL Scheme ")
    r_code = p.add_run("tel://")
    r_code.font.name = "Consolas"
    p.add_run(" để vừa tự động đếm ngược vừa chuyển người dùng sang ứng dụng Điện thoại mặc định của iOS.")

    add_custom_heading("2.5. Giao diện Retina iOS 17/18 & Icon Độc quyền", level=2)
    p = doc.add_paragraph()
    p.add_run("• Thiết kế phong cách Card-Style hiện đại, tự động thích ứng chế độ Sáng/Tối (Light/Dark Mode).\n")
    p.add_run("• Đi kèm bộ biểu tượng Retina 1024x1024 hiển thị đẹp mắt trên Màn hình chính và Thư viện ứng dụng.")

    # Section 3: Architecture
    add_custom_heading("3. KIẾN TRÚC MÃ NGUỒN VÀ DANH SÁCH TỆP TIN", level=1)
    
    table_files = doc.add_table(rows=1, cols=2)
    table_files.alignment = WD_TABLE_ALIGNMENT.CENTER
    table_files.autofit = False
    
    # Header Row
    hdr_cells = table_files.rows[0].cells
    hdr_cells[0].width, hdr_cells[1].width = Inches(2.2), Inches(4.3)
    set_cell_background(hdr_cells[0], "0A369D")
    set_cell_background(hdr_cells[1], "0A369D")
    set_cell_margins(hdr_cells[0], top=100, bottom=100, left=120, right=120)
    set_cell_margins(hdr_cells[1], top=100, bottom=100, left=120, right=120)
    
    p0 = hdr_cells[0].paragraphs[0]
    r0 = p0.add_run("Tệp tin / Thư mục")
    r0.bold = True
    r0.font.color.rgb = RGBColor(0xFF, 0xFF, 0xFF)
    
    p1 = hdr_cells[1].paragraphs[0]
    r1 = p1.add_run("Vai trò / Chức năng chính")
    r1.bold = True
    r1.font.color.rgb = RGBColor(0xFF, 0xFF, 0xFF)
    
    files_list = [
        ("CallTimer/ContentView.swift", "Giao diện chính SwiftUI (Form chọn phút/giây eSIM 1 & 2, Card cuộc gọi, ô nhập số)."),
        ("CallTimer/TimerManager.swift", "Logic đếm ngược thời gian thực (Combine), lưu cấu hình và điều khiển Live Activity."),
        ("CallTimer/NotificationManager.swift", "Quản lý thông báo đẩy cục bộ, chuông báo thức & hệ thống rung Haptics."),
        ("CallTimer/CallTimerAttributes.swift", "Định nghĩa cấu trúc thuộc tính ActivityAttributes cho Dynamic Island."),
        ("CallTimer/CallTimerWidgetLiveActivity.swift", "Widget render giao diện đếm ngược trên Dynamic Island & Màn hình khóa."),
        ("CallTimer/Info.plist", "Cấu hình quyền Live Activities & Background Audio."),
        ("CallTimer/Assets.xcassets/", "Thư mục icon 1024x1024 Retina trên màn hình chính."),
        ("CallTimerApp.xcodeproj/", "Dự án cấu hình Xcode 15+."),
        (".github/workflows/build_ios.yml", "Workflow tự động biên dịch file .ipa trên máy chủ macOS của GitHub Actions."),
        ("BUILD_GUIDE.md", "Tài liệu hướng dẫn cài đặt ứng dụng lên iPhone từ Windows bằng Sideloadly."),
        ("Sideloadly_Setup.exe", "Bộ cài đặt phần mềm Sideloadly trên Windows (Đã tải sẵn tại thư mục dự án).")
    ]
    
    for row_idx, (fname, fdesc) in enumerate(files_list):
        row = table_files.add_row()
        c0, c1 = row.cells[0], row.cells[1]
        c0.width, c1.width = Inches(2.2), Inches(4.3)
        
        bg_color = "F0 F4 F8" if row_idx % 2 == 1 else "FFFFFF"
        set_cell_background(c0, bg_color)
        set_cell_background(c1, bg_color)
        set_cell_margins(c0, top=70, bottom=70, left=120, right=120)
        set_cell_margins(c1, top=70, bottom=70, left=120, right=120)
        
        p_c0 = c0.paragraphs[0]
        r_fn = p_c0.add_run(fname)
        r_fn.font.name = "Consolas"
        r_fn.font.size = Pt(9.5)
        r_fn.font.bold = True
        
        p_c1 = c1.paragraphs[0]
        p_c1.add_run(fdesc)

    doc.add_paragraph().paragraph_format.space_after = Pt(10)

    # Section 4: Build & Install Guide
    add_custom_heading("4. QUY TRÌNH BIÊN DỊCH VÀ CÀI ĐẶT LÊN IPHONE TỪ WINDOWS", level=1)
    
    p_steps = doc.add_paragraph()
    p_steps.add_run("Bước 1: Đẩy mã nguồn lên GitHub\n").bold = True
    p_steps.add_run("Tải toàn bộ mã nguồn tại thư mục ")
    r_path = p_steps.add_run("D:\\AI Agent - SelfStudies\\Time for Call on Iphone")
    r_path.font.name = "Consolas"
    p_steps.add_run(" lên GitHub Repository tại địa chỉ: https://github.com/nghia-AOF/CallTimer.\n\n")
    
    p_steps.add_run("Bước 2: Máy chủ đám mây tự động tạo file CallTimer.ipa\n").bold = True
    p_steps.add_run("Kịch bản GitHub Actions (.github/workflows/build_ios.yml) sẽ tự động điều khiển máy chủ macOS của GitHub biên dịch mã nguồn Swift và tạo gói cài đặt CallTimer.ipa miễn phí cho bạn tải về.\n\n")
    
    p_steps.add_run("Bước 3: Cài đặt vào iPhone bằng Sideloadly\n").bold = True
    p_steps.add_run("1. Mở phần mềm Sideloadly (đã cài đặt qua tệp Sideloadly_Setup.exe trong thư mục dự án).\n")
    p_steps.add_run("2. Cắm iPhone 15 Pro Max vào máy tính bằng cáp C.\n")
    p_steps.add_run("3. Kéo thả file CallTimer.ipa vào Sideloadly, nhập Apple ID và bấm Start để cài đặt ứng dụng trực tiếp lên iPhone.")

    # Footer Metadata
    doc.add_paragraph().paragraph_format.space_after = Pt(20)
    p_ftr = doc.add_paragraph()
    p_ftr.alignment = WD_ALIGN_PARAGRAPH.RIGHT
    r_ftr = p_ftr.add_run("Tài liệu được xuất tự động bởi AI Agent Assistant\nNgày khởi tạo: 23/09/2026")
    r_ftr.font.size = Pt(9)
    r_ftr.font.italic = True
    r_ftr.font.color.rgb = RGBColor(0x88, 0x88, 0x88)

    output_path = r"D:\AI Agent - SelfStudies\Time for Call on Iphone\CallTimer_Software_Description.docx"
    doc.save(output_path)
    print(f"File Word successfully created at: {output_path}")

if __name__ == "__main__":
    generate_doc()
