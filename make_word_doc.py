"""Generates CallTimer_Software_Description.docx (run: python make_word_doc.py)."""
import os

import docx
from docx.enum.section import WD_SECTION
from docx.enum.table import WD_TABLE_ALIGNMENT, WD_CELL_VERTICAL_ALIGNMENT
from docx.enum.text import WD_ALIGN_PARAGRAPH, WD_BREAK
from docx.oxml import OxmlElement, parse_xml
from docx.oxml.ns import nsdecls, qn
from docx.shared import Cm, Pt, RGBColor

VERSION = "1.1"
BUILD = "2"
DATE = "23/09/2026"
REPO = "https://github.com/nghia-AOF/CallTimer"
RELEASES = REPO + "/releases"

NAVY = RGBColor(0x0A, 0x36, 0x9D)
BLUE = RGBColor(0x00, 0x66, 0xCC)
GREY = RGBColor(0x5F, 0x63, 0x68)
TEXT = RGBColor(0x22, 0x22, 0x22)
WHITE = RGBColor(0xFF, 0xFF, 0xFF)
FONT = "Calibri"
MONO = "Consolas"


# ---------------------------------------------------------------- XML helpers

def shade(cell, fill_hex):
    cell._tc.get_or_add_tcPr().append(parse_xml(f'<w:shd {nsdecls("w")} w:val="clear" w:color="auto" w:fill="{fill_hex}"/>'))


def cell_margins(cell, top=90, bottom=90, left=140, right=140):
    tcPr = cell._tc.get_or_add_tcPr()
    mar = OxmlElement("w:tcMar")
    for side, val in (("top", top), ("bottom", bottom), ("left", left), ("right", right)):
        node = OxmlElement(f"w:{side}")
        node.set(qn("w:w"), str(val))
        node.set(qn("w:type"), "dxa")
        mar.append(node)
    tcPr.append(mar)


def table_borders(table, color="D0D7E2", size=4, inside=True):
    tblPr = table._tbl.tblPr
    borders = OxmlElement("w:tblBorders")
    edges = ["top", "left", "bottom", "right"] + (["insideH", "insideV"] if inside else [])
    for edge in edges:
        el = OxmlElement(f"w:{edge}")
        el.set(qn("w:val"), "single")
        el.set(qn("w:sz"), str(size))
        el.set(qn("w:color"), color)
        borders.append(el)
    tblPr.append(borders)


def left_bar(cell, color_hex, size=24):
    tcPr = cell._tc.get_or_add_tcPr()
    borders = OxmlElement("w:tcBorders")
    for edge in ("top", "bottom", "right"):
        el = OxmlElement(f"w:{edge}")
        el.set(qn("w:val"), "nil")
        borders.append(el)
    el = OxmlElement("w:left")
    el.set(qn("w:val"), "single")
    el.set(qn("w:sz"), str(size))
    el.set(qn("w:color"), color_hex)
    borders.append(el)
    tcPr.append(borders)


def cant_split(row):
    el = OxmlElement("w:cantSplit")
    el.set(qn("w:val"), "true")
    row._tr.get_or_add_trPr().append(el)


def repeat_header(row):
    trPr = row._tr.get_or_add_trPr()
    el = OxmlElement("w:tblHeader")
    el.set(qn("w:val"), "true")
    trPr.append(el)


def add_field(paragraph, instr):
    run = paragraph.add_run()
    for kind, text in (("begin", None), (None, instr), ("separate", None), ("end", None)):
        if kind:
            el = OxmlElement("w:fldChar")
            el.set(qn("w:fldCharType"), kind)
        else:
            el = OxmlElement("w:instrText")
            el.set(qn("xml:space"), "preserve")
            el.text = text
        run._r.append(el)
    return run


def set_font(style, name=FONT, size=None, color=None, bold=None):
    style.font.name = name
    style.element.rPr.rFonts.set(qn("w:eastAsia"), name)
    if size:
        style.font.size = Pt(size)
    if color is not None:
        style.font.color.rgb = color
    if bold is not None:
        style.font.bold = bold


# ---------------------------------------------------------------- content helpers

def rich(paragraph, text, size=None, color=None):
    """Adds text; segments wrapped in `backticks` are code, in **stars** are bold."""
    for i, chunk in enumerate(text.split("`")):
        if i % 2 == 1:
            r = paragraph.add_run(chunk)
            r.font.name = MONO
            r.font.size = Pt(9.5)
            r.font.color.rgb = RGBColor(0xB0, 0x2A, 0x5B)
            continue
        for j, part in enumerate(chunk.split("**")):
            if not part:
                continue
            r = paragraph.add_run(part)
            r.bold = j % 2 == 1
            if size:
                r.font.size = Pt(size)
            if color is not None:
                r.font.color.rgb = color
    return paragraph


class Doc:
    def __init__(self):
        self.d = docx.Document()
        self._setup()

    def _setup(self):
        sec = self.d.sections[0]
        sec.page_height, sec.page_width = Cm(29.7), Cm(21.0)
        sec.top_margin = sec.bottom_margin = Cm(2.2)
        sec.left_margin = sec.right_margin = Cm(2.3)

        styles = self.d.styles
        set_font(styles["Normal"], size=11, color=TEXT)
        styles["Normal"].paragraph_format.space_after = Pt(4)
        styles["Normal"].paragraph_format.line_spacing = 1.15
        for name, size, color, before in (("Heading 1", 16, NAVY, 20), ("Heading 2", 13, BLUE, 12)):
            st = styles[name]
            set_font(st, size=size, color=color, bold=True)
            st.font.italic = False
            st.paragraph_format.space_before = Pt(before)
            st.paragraph_format.space_after = Pt(6)
            st.paragraph_format.keep_with_next = True
        for name in ("List Bullet", "List Number"):
            set_font(styles[name], size=11, color=TEXT)
            styles[name].paragraph_format.space_after = Pt(3)

    # -- building blocks
    def h1(self, text):
        p = self.d.add_heading(text, level=1)
        # thin rule under chapter headings
        pPr = p._p.get_or_add_pPr()
        bdr = OxmlElement("w:pBdr")
        bottom = OxmlElement("w:bottom")
        for k, v in (("val", "single"), ("sz", "6"), ("space", "4"), ("color", "C9D6EE")):
            bottom.set(qn(f"w:{k}"), v)
        bdr.append(bottom)
        pPr.append(bdr)
        return p

    def h2(self, text):
        return self.d.add_heading(text, level=2)

    def para(self, text, **kw):
        return rich(self.d.add_paragraph(), text, **kw)

    def bullets(self, items):
        for it in items:
            rich(self.d.add_paragraph(style="List Bullet"), it)

    def steps(self, items):
        # Numbered with manual prefixes so every list restarts at 1.
        for i, it in enumerate(items, 1):
            p = self.d.add_paragraph()
            p.paragraph_format.left_indent = Cm(0.9)
            p.paragraph_format.first_line_indent = Cm(-0.6)
            p.paragraph_format.space_after = Pt(3)
            r = p.add_run(f"{i}.  ")
            r.bold = True
            r.font.color.rgb = BLUE
            rich(p, it)

    def spacer(self, pts=6):
        p = self.d.add_paragraph()
        p.paragraph_format.space_after = Pt(0)
        p.paragraph_format.space_before = Pt(0)
        r = p.add_run()
        r.font.size = Pt(pts)

    def callout(self, title, lines, bar="F2A900", fill="FFF8E1"):
        t = self.d.add_table(rows=1, cols=1)
        t.alignment = WD_TABLE_ALIGNMENT.CENTER
        c = t.rows[0].cells[0]
        c.width = Cm(16.4)
        shade(c, fill)
        left_bar(c, bar)
        cell_margins(c, 120, 120, 220, 180)
        p = c.paragraphs[0]
        r = p.add_run(title)
        r.bold = True
        r.font.color.rgb = RGBColor.from_string(bar)
        for line in lines:
            q = c.add_paragraph()
            q.paragraph_format.space_after = Pt(2)
            rich(q, "•  " + line, size=10.5)
        self.spacer()

    def table(self, headers, rows, widths, first_col_code=False, first_col_fills=None):
        t = self.d.add_table(rows=1, cols=len(widths))
        t.alignment = WD_TABLE_ALIGNMENT.CENTER
        t.autofit = False
        table_borders(t)
        hdr = t.rows[0]
        repeat_header(hdr)
        for k, cell in enumerate(hdr.cells):
            cell.width = widths[k]
            shade(cell, "0A369D")
            cell_margins(cell)
            r = cell.paragraphs[0].add_run(headers[k])
            r.bold = True
            r.font.color.rgb = WHITE
        for i, values in enumerate(rows):
            row = t.add_row()
            cant_split(row)
            cells = row.cells
            for k, cell in enumerate(cells):
                cell.width = widths[k]
                cell.vertical_alignment = WD_CELL_VERTICAL_ALIGNMENT.CENTER
                cell_margins(cell)
                fill = "F4F7FB" if i % 2 else "FFFFFF"
                if k == 0 and first_col_fills:
                    fill = first_col_fills[i]
                shade(cell, fill)
                p = cell.paragraphs[0]
                p.paragraph_format.space_after = Pt(0)
                if k == 0 and first_col_code:
                    # break long paths after "/" instead of mid-word
                    parts = values[k].split("/")
                    for n, part in enumerate(parts):
                        r = p.add_run(part + ("/" if n < len(parts) - 1 else ""))
                        r.font.name = MONO
                        r.font.size = Pt(9)
                        r.bold = True
                        r.font.color.rgb = NAVY
                        if n < len(parts) - 1 and len(values[k]) > 30:
                            r.add_break()
                    continue
                    r.bold = True
                    r.font.color.rgb = NAVY
                elif k == 0:
                    r = p.add_run(values[k])
                    r.bold = True
                    r.font.color.rgb = WHITE if first_col_fills else NAVY
                else:
                    rich(p, values[k], size=10.5)
        # Keep the header (and short tables entirely) together with the following rows.
        keep_rows = t.rows[:-1] if len(t.rows) <= 5 else t.rows[:1]
        for row in keep_rows:
            for cell in row.cells:
                for par in cell.paragraphs:
                    par.paragraph_format.keep_with_next = True
        self.spacer()
        return t

    def key_values(self, rows, widths=(Cm(4.4), Cm(12.0))):
        t = self.d.add_table(rows=0, cols=2)
        t.alignment = WD_TABLE_ALIGNMENT.CENTER
        t.autofit = False
        table_borders(t, inside=True)
        for label, value in rows:
            c0, c1 = t.add_row().cells
            c0.width, c1.width = widths
            shade(c0, "EEF3FB")
            shade(c1, "FFFFFF")
            cell_margins(c0)
            cell_margins(c1)
            r = c0.paragraphs[0].add_run(label)
            r.bold = True
            r.font.color.rgb = NAVY
            rich(c1.paragraphs[0], value, size=10.5)
            for c in (c0, c1):
                c.paragraphs[0].paragraph_format.space_after = Pt(0)
        self.spacer()

    # -- page furniture
    def cover(self):
        d = self.d
        for _ in range(5):
            d.add_paragraph()
        band = d.add_table(rows=1, cols=1)
        band.alignment = WD_TABLE_ALIGNMENT.CENTER
        c = band.rows[0].cells[0]
        c.width = Cm(16.4)
        shade(c, "0A369D")
        cell_margins(c, 500, 500, 400, 400)
        p = c.paragraphs[0]
        p.alignment = WD_ALIGN_PARAGRAPH.CENTER
        r = p.add_run("TÀI LIỆU MÔ TẢ PHẦN MỀM")
        r.font.size = Pt(12)
        r.font.color.rgb = RGBColor(0xBF, 0xD2, 0xF5)
        r.bold = True
        p = c.add_paragraph()
        p.alignment = WD_ALIGN_PARAGRAPH.CENTER
        r = p.add_run("CallTimer iOS")
        r.font.size = Pt(36)
        r.bold = True
        r.font.color.rgb = WHITE
        p = c.add_paragraph()
        p.alignment = WD_ALIGN_PARAGRAPH.CENTER
        r = p.add_run("Nhắc nhở thời lượng cuộc gọi theo từng SIM\nĐếm ngược trên Dynamic Island & Màn hình khóa")
        r.font.size = Pt(13)
        r.font.color.rgb = WHITE

        d.add_paragraph()
        p = d.add_paragraph()
        p.alignment = WD_ALIGN_PARAGRAPH.CENTER
        r = p.add_run(f"Phiên bản {VERSION} (build {BUILD})   •   Cập nhật {DATE}")
        r.font.size = Pt(12)
        r.bold = True
        r.font.color.rgb = NAVY
        p = d.add_paragraph()
        p.alignment = WD_ALIGN_PARAGRAPH.CENTER
        r = p.add_run(REPO)
        r.font.size = Pt(10.5)
        r.font.color.rgb = GREY

        # Table of contents on its own page (Word fills it in; press F9 to refresh)
        d.add_paragraph().add_run().add_break(WD_BREAK.PAGE)
        p = d.add_paragraph()
        r = p.add_run("MỤC LỤC")
        r.bold = True
        r.font.size = Pt(16)
        r.font.color.rgb = NAVY
        add_field(d.add_paragraph(), 'TOC \\o "1-2" \\h \\z \\u')
        p = d.add_paragraph()
        rich(p, "(Nếu mục lục trống: nhấp chuột phải vào đây → Update Field, hoặc nhấn F9.)", size=9, color=GREY)
        d.add_paragraph().add_run().add_break(WD_BREAK.PAGE)

    def header_footer(self):
        sec = self.d.sections[0]
        sec.different_first_page_header_footer = True
        hp = sec.header.paragraphs[0]
        hp.alignment = WD_ALIGN_PARAGRAPH.RIGHT
        rich(hp, f"CallTimer iOS  •  Tài liệu mô tả phần mềm  •  v{VERSION}", size=9, color=GREY)
        fp = sec.footer.paragraphs[0]
        fp.alignment = WD_ALIGN_PARAGRAPH.CENTER
        r = fp.add_run("Trang ")
        r.font.size = Pt(9)
        r.font.color.rgb = GREY
        run = add_field(fp, "PAGE")
        run.font.size = Pt(9)

    def save(self, path):
        self.d.save(path)


# ---------------------------------------------------------------- document

def generate_doc():
    doc = Doc()
    doc.header_footer()
    doc.cover()

    # 1
    doc.h1("1. Tổng quan phần mềm")
    doc.key_values([
        ("Tên phần mềm", "CallTimer iOS (Call Duration Reminder & Dynamic Island Tracker)"),
        ("Phiên bản", f"{VERSION} (build {BUILD}) – cập nhật {DATE}"),
        ("Mục đích", "Đặt mốc thời gian gọi tối đa riêng cho **từng SIM/eSIM** (2 SIM trở lên), đếm ngược trực quan và cảnh báo chuông/rung trước khi vượt mốc để tránh phát sinh cước."),
        ("Nền tảng", "iOS 17.0+ trên iPhone. Dynamic Island có trên iPhone 14 Pro trở lên (tối ưu cho iPhone 15 Pro Max); máy khác vẫn có đếm ngược trên Màn hình khóa."),
        ("Phân phối", "Không qua App Store: GitHub Actions biên dịch `CallTimer.ipa`, cài trực tiếp lên iPhone bằng Sideloadly từ Windows."),
        ("Mã nguồn", REPO),
        ("Tải bản cài đặt", RELEASES),
        ("Thư mục local", "D:\\AI Agent - SelfStudies\\Time for Call on Iphone"),
    ])

    doc.h2("Luồng hoạt động chính")
    doc.steps([
        "Người dùng chọn thẻ SIM sẽ dùng để gọi và bấm **Gọi & đếm ngược** (hoặc **Bắt đầu đếm**).",
        "App lên lịch sẵn các thông báo cảnh báo, bật Live Activity rồi mở ứng dụng Điện thoại.",
        "iOS tự hiển thị đếm ngược trên Dynamic Island / Màn hình khóa trong suốt cuộc gọi.",
        "Khi còn N giây: **cảnh báo vàng**. Khi chạm mốc: **cảnh báo đỏ** – người dùng dập máy.",
    ])

    # 2
    doc.h1("2. Tính năng")

    doc.h2("2.1. Mốc thời gian riêng cho từng SIM / eSIM")
    doc.bullets([
        "Mỗi SIM là một thẻ có **tên tự đặt** và mốc tối đa **0–180 phút, 0–59 giây** (ví dụ “eSIM 1 (Công việc)” 9:30; “eSIM 2 (Cá nhân)” 14:30).",
        "Nút **Thêm SIM / eSIM** – không giới hạn số SIM; đổi tên hoặc xóa tùy ý (luôn giữ tối thiểu 1 SIM). Mỗi SIM có màu nhận diện riêng.",
        "Cấu hình lưu tự động bằng `UserDefaults` ngay khi thay đổi; tự chuyển dữ liệu từ phiên bản 1.0.",
        "Thời điểm cảnh báo trước mốc chỉnh được **10–120 giây** (mặc định 30 giây).",
    ])

    doc.h2("2.2. Đếm ngược trên Dynamic Island & Màn hình khóa")
    doc.bullets([
        "Dùng `ActivityKit` / Live Activities qua Widget Extension riêng (`CallTimerWidgetExtension`) – điều kiện bắt buộc của iOS.",
        "Bộ đếm do iOS tự vẽ từ thời điểm kết thúc (`Text(timerInterval:)`) nên **vẫn chạy chính xác khi app ở nền** trong lúc gọi.",
        "Màu đổi theo trạng thái nhờ cơ chế `staleDate`, kể cả khi app không mở.",
    ])
    doc.table(("Chế độ hiển thị", "Nội dung"), [
        ("Compact", "Icon đồng hồ bên trái, thời gian còn lại MM:SS bên phải."),
        ("Expanded (nhấn giữ)", "Tên SIM, nhãn trạng thái, bộ đếm cỡ lớn, thanh tiến trình, mốc tối đa và số giây cảnh báo."),
        ("Minimal", "Icon đồng hồ khi có nhiều Live Activity cùng lúc."),
        ("Màn hình khóa", "Banner với tên SIM, trạng thái, bộ đếm và thanh tiến trình."),
    ], (Cm(4.4), Cm(12.0)))

    doc.h2("2.3. Hệ thống cảnh báo chuông + rung")
    doc.table(("Trạng thái", "Khi nào", "Cách cảnh báo"), [
        ("ĐANG GỌI", "Từ lúc bắt đầu", "Đếm ngược màu xanh lá trên Dynamic Island, màu SIM trong app."),
        ("SẮP HẾT GIỜ", "Còn N giây (mặc định 30)", "Thông báo cục bộ có âm thanh; nếu app đang mở: rung Haptics nhẹ + chuông ngắn."),
        ("HẾT GIỜ", "Chạm mốc tối đa", "3 thông báo liên tiếp cách nhau 4 giây; nếu app đang mở: rung + chuông báo thức lặp 8 lần."),
    ], (Cm(3.4), Cm(4.2), Cm(8.8)), first_col_fills=["2E9E4F", "E0A800", "D93025"])
    doc.bullets([
        "Thông báo được lên lịch bằng `UNUserNotificationCenter` ngay khi bắt đầu nên vẫn kêu khi **tắt màn hình** hoặc app **chạy ngầm**.",
        "Bấm **Dừng đếm ngược** sẽ hủy ngay mọi thông báo đã lên lịch và Live Activity.",
    ])

    doc.h2("2.4. Gọi nhanh")
    doc.bullets([
        "Nhập số rồi bấm **Gọi & đếm ngược**: app bắt đầu đếm, bật Live Activity rồi mở ứng dụng Điện thoại qua `tel:`.",
        "Để trống ô số: nút đổi thành **Bắt đầu đếm** – dùng khi tự gọi từ ứng dụng Điện thoại (và tự chọn SIM ở đó).",
    ])

    doc.h2("2.5. Khôi phục phiên đếm")
    doc.bullets([
        "Phiên đang đếm được lưu lại: nếu app bị tắt khi đang gọi, mở lại sẽ tiếp tục đúng thời gian còn lại.",
        "Mở lại app sau khi đã hết giờ: hiển thị “HẾT GIỜ” nhưng không phát lại chuông; phiên cũ hơn 10 phút tự được dọn.",
    ])

    doc.h2("2.6. Giao diện")
    doc.bullets([
        "Phong cách thẻ (card) hiện đại, tự thích ứng chế độ Sáng/Tối.",
        "Thẻ đếm ngược đổi màu và nhãn theo trạng thái, có thanh tiến trình và nút **Dừng đếm ngược / Đóng**.",
        "Tự nhắc bật “Hoạt động trực tiếp” nếu Live Activities đang tắt.",
        "Icon Retina 1024×1024 trên Màn hình chính và Thư viện ứng dụng.",
    ])

    # 3
    doc.h1("3. Kiến trúc mã nguồn")
    doc.para("Dự án gồm **2 target**: ứng dụng `CallTimer` và `CallTimerWidgetExtension` (được nhúng trong app). "
             "File dự án Xcode được sinh tự động từ `project.yml` bằng XcodeGen.")
    doc.table(("Tệp tin / Thư mục", "Vai trò"), [
        ("CallTimer/CallTimerApp.swift", "Điểm khởi chạy; xin quyền thông báo, đồng bộ lại bộ đếm khi app quay lại."),
        ("CallTimer/ContentView.swift", "Giao diện SwiftUI: thẻ đếm ngược, ô nhập số, danh sách thẻ SIM, thêm/xóa SIM, cài đặt cảnh báo."),
        ("CallTimer/TimerManager.swift", "Danh sách SIM & lưu cấu hình, đếm ngược theo thời điểm kết thúc, lưu/khôi phục phiên, điều khiển Live Activity, quay số."),
        ("CallTimer/NotificationManager.swift", "Lên lịch/hủy thông báo cảnh báo vàng & đỏ; rung Haptics và chuông trong app."),
        ("CallTimer/Info.plist", "Bật Live Activities, Background Audio, màn hình dọc."),
        ("CallTimer/Assets.xcassets/", "Icon ứng dụng 1024×1024."),
        ("CallTimerWidget/CallTimerWidgetLiveActivity.swift", "Giao diện Live Activity: Dynamic Island (Compact / Expanded / Minimal) và Màn hình khóa."),
        ("CallTimerWidget/Info.plist", "Khai báo WidgetKit extension."),
        ("Shared/CallTimerAttributes.swift", "Cấu trúc dữ liệu Live Activity dùng chung cho app và widget."),
        ("project.yml", "Cấu hình XcodeGen sinh CallTimerApp.xcodeproj."),
        (".github/workflows/build_ios.yml", "GitHub Actions: build trên macOS, đóng gói CallTimer.ipa, đăng lên Artifacts & Releases."),
        ("BUILD_GUIDE.md / README.md", "Hướng dẫn cài đặt chi tiết và giới thiệu dự án."),
    ], (Cm(6.4), Cm(10.0)), first_col_code=True)

    # 4
    doc.h1("4. Biên dịch & cài đặt lên iPhone từ Windows")

    doc.h2("Bước 1 – Lấy file CallTimer.ipa")
    doc.steps([
        "Mỗi lần đẩy mã nguồn lên nhánh `main`, GitHub Actions tự biên dịch trên máy chủ macOS (3–6 phút).",
        f"Tải `CallTimer.ipa` tại {RELEASES} (bản **build-N** mới nhất).",
    ])

    doc.h2("Bước 2 – Chuẩn bị máy tính")
    doc.steps([
        "Cài **iTunes bản tải từ apple.com** (không dùng bản Microsoft Store) để có driver nhận iPhone.",
        "Cài **Sideloadly** (https://sideloadly.io).",
        "Cắm iPhone bằng cáp, bấm **Tin cậy** trên iPhone.",
    ])

    doc.h2("Bước 3 – Cài đặt bằng Sideloadly")
    doc.steps([
        "Trên iPhone: **Cài đặt → Quyền riêng tư & Bảo mật → Chế độ nhà phát triển** → Bật (máy khởi động lại).",
        "Trong Sideloadly: kéo thả `CallTimer.ipa`, chọn iPhone, nhập Apple ID (nên dùng Apple ID phụ), bấm **Start**.",
        "Trên iPhone: **Cài đặt → Cài đặt chung → Quản lý VPN & Thiết bị** → chọn Apple ID → **Tin cậy**.",
        "Mở CallTimer, cho phép **Thông báo**; kiểm tra **Cài đặt → CallTimer → Hoạt động trực tiếp** đang bật.",
    ])

    doc.h2("Bước 4 – Sử dụng hằng ngày")
    doc.steps([
        "Đặt tên và mốc thời gian cho từng SIM (chỉ cần làm một lần).",
        "Nhập số rồi bấm **Gọi & đếm ngược** trên đúng thẻ SIM; hoặc tự gọi từ ứng dụng Điện thoại rồi bấm **Bắt đầu đếm**.",
        "Theo dõi Dynamic Island / Màn hình khóa; dập máy khi có cảnh báo.",
        "Sau cuộc gọi, mở app bấm **Dừng đếm ngược / Đóng**.",
    ])

    # 5
    doc.h1("5. Giới hạn & lưu ý")
    doc.callout("Apple ID miễn phí", [
        "Ứng dụng hết hạn sau **7 ngày** – cắm máy và bấm Start lại trong Sideloadly (dữ liệu giữ nguyên) hoặc bật Auto-refresh.",
        "Tối đa 3 ứng dụng tự ký cùng lúc. Tài khoản Apple Developer trả phí: dùng được 1 năm.",
    ])
    doc.callout("Giới hạn của iOS", [
        "Ứng dụng bên thứ ba **không thể chọn SIM** để gọi: qua `tel:`, iPhone dùng đường dây mặc định hoặc đường dây đã dùng gần nhất với số đó. Muốn chắc chắn đúng SIM, hãy tự gọi từ ứng dụng Điện thoại rồi bấm **Bắt đầu đếm**.",
        "App không tự phát hiện lúc cuộc gọi kết nối/kết thúc: bộ đếm bắt đầu khi bấm nút và dừng khi người dùng bấm Dừng.",
        "Khi đang nghe máy, iOS thường chỉ phát tiếng “bíp” nhỏ trong loa thoại; chuông/rung lặp lại chỉ chạy khi app đang mở.",
        "Chế độ Tập trung / Không làm phiền có thể chặn thông báo – hãy cho phép CallTimer.",
    ], bar="D93025", fill="FDECEA")

    # 6
    doc.h1("6. Lịch sử phiên bản")
    doc.table(("Phiên bản", "Nội dung thay đổi"), [
        ("1.0 – 22/09/2026", "Phiên bản đầu: cấu hình eSIM 1 & eSIM 2, đếm ngược, thông báo cảnh báo, gọi nhanh."),
        ("1.1 – 23/09/2026", "Thêm Widget Extension để Live Activity hiển thị trên Dynamic Island & Màn hình khóa; đếm ngược chạy nền chính xác; "
                             "hỗ trợ nhiều SIM (thêm / đổi tên / xóa), chọn giây 0–59, chỉnh thời điểm cảnh báo; cảnh báo đỏ lặp lại; "
                             "khôi phục phiên; build tự động bằng XcodeGen + GitHub Actions, bản cài đăng trên Releases."),
    ], (Cm(3.8), Cm(12.6)))

    out = os.path.join(os.path.dirname(os.path.abspath(__file__)), "CallTimer_Software_Description.docx")
    doc.save(out)
    print(f"File Word successfully created at: {out}")


if __name__ == "__main__":
    generate_doc()
