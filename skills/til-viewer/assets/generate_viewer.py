#!/usr/bin/env python3
"""TIL Viewer HTML 생성 스크립트 (Toss Design)"""
import json
import os
import sys
from datetime import datetime, timedelta
from glob import glob


def main():
    if len(sys.argv) < 3:
        print("Usage: python3 generate_viewer.py <TIL_PATH> <ASSETS_PATH> [--recent <days>]")
        sys.exit(1)

    TIL_PATH = sys.argv[1]
    ASSETS_PATH = sys.argv[2]

    # --recent 옵션 파싱
    recent_days = None
    if "--recent" in sys.argv:
        idx = sys.argv.index("--recent")
        if idx + 1 < len(sys.argv):
            try:
                recent_days = int(sys.argv[idx + 1])
            except ValueError:
                pass

    cutoff_time = None
    if recent_days:
        cutoff_time = datetime.now() - timedelta(days=recent_days)
        print(f"필터: 최근 {recent_days}일 이내 생성된 문서만 표시")

    # 1. 파일 스캔 및 메타데이터 추출
    categories = {}
    total_lines = 0
    skipped_files = 0

    for md_file in sorted(glob(f"{TIL_PATH}/**/*.md", recursive=True)):
        rel_path = os.path.relpath(md_file, TIL_PATH)
        if rel_path.startswith("skills/"):
            continue
        parts = rel_path.split("/")
        if len(parts) < 2:
            continue

        # 날짜 필터링 (파일 생성 시간 기준)
        if cutoff_time:
            file_stat = os.stat(md_file)
            try:
                file_time = datetime.fromtimestamp(file_stat.st_birthtime)
            except AttributeError:
                file_time = datetime.fromtimestamp(file_stat.st_mtime)
            if file_time < cutoff_time:
                skipped_files += 1
                continue

        category = parts[0]
        filename = parts[-1]

        with open(md_file, "r", encoding="utf-8") as f:
            content = f.read()

        title = filename.replace(".md", "")
        for line in content.split("\n"):
            if line.startswith("# "):
                title = line[2:].strip()
                break

        lines = content.count("\n") + 1
        total_lines += lines

        if category not in categories:
            categories[category] = {"files": []}

        # 파일 생성일 가져오기
        file_stat = os.stat(md_file)
        try:
            created_ts = file_stat.st_birthtime
        except AttributeError:
            created_ts = file_stat.st_mtime
        created_at = datetime.fromtimestamp(created_ts).strftime("%Y-%m-%d")

        categories[category]["files"].append({
            "filename": filename,
            "title": title,
            "path": rel_path,
            "content": content,
            "size": len(content.encode("utf-8")),
            "lines": lines,
            "createdAt": created_at
        })

    # 2. JSON 데이터 생성
    til_data = {
        "categories": categories,
        "metadata": {
            "totalFiles": sum(len(cat["files"]) for cat in categories.values()),
            "totalCategories": len(categories),
            "totalLines": total_lines,
            "generatedAt": datetime.now().isoformat()
        }
    }
    json_str = json.dumps(til_data, ensure_ascii=False)
    json_str = json_str.replace("</script>", "<\\/script>")

    # viewer.js/css 인라인 (file:// 프로토콜 캐시 문제 방지)
    viewer_js_path = os.path.join(ASSETS_PATH, "js", "viewer.js")
    with open(viewer_js_path, "r", encoding="utf-8") as f:
        viewer_js = f.read()
    viewer_js = viewer_js.replace("</script>", "<\\/script>")

    viewer_css_path = os.path.join(ASSETS_PATH, "css", "viewer.css")
    with open(viewer_css_path, "r", encoding="utf-8") as f:
        viewer_css = f.read()

    # 3. HTML 생성
    html_content = f"""<!DOCTYPE html>
<html lang="ko">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>TIL Viewer</title>
    <style>{viewer_css}</style>
    <link rel="stylesheet" href="lib/highlight/github.min.css" id="hljs-light">
    <link rel="stylesheet" href="lib/highlight/github-dark.min.css" id="hljs-dark" disabled>
</head>
<body>
    <div class="header">
        <button class="menu-toggle" id="menu-toggle">&#9776;</button>
        <h1>TIL Viewer</h1>
        <span class="header-stats" id="header-stats"></span>
        <div class="search-container">
            <input type="text" id="search-input" placeholder="Search... (Ctrl+K)" autocomplete="off" />
        </div>
        <button class="theme-toggle" id="theme-toggle" onclick="toggleTheme()">Dark</button>
    </div>

    <div class="progress-bar">
        <div class="progress-fill" id="progress-fill"></div>
    </div>

    <div class="overlay" id="overlay"></div>

    <div class="container">
        <nav class="sidebar" id="sidebar">
            <div class="special-links">
                <a href="algorithm-practice.html" class="special-link">Algorithm Practice</a>
            </div>
            <div class="filter-buttons">
                <button class="filter-btn active" data-filter="all">전체</button>
                <button class="filter-btn" data-filter="7">7일</button>
                <button class="filter-btn" data-filter="30">30일</button>
                <button class="filter-btn" data-filter="90">90일</button>
            </div>
            <div id="file-list"></div>
        </nav>

        <div class="content-wrapper">
            <main class="content-area" id="content-area">
                <div class="content-inner" id="content">
                    <div class="loading">사이드바에서 파일을 선택하세요</div>
                </div>
            </main>
            <aside class="toc-panel" id="toc-panel">
                <h4>목차</h4>
                <div id="toc-list"></div>
            </aside>
        </div>
    </div>

    <div class="quick-actions" id="quick-actions">
        <button class="quick-btn" id="pdf-download-btn" onclick="downloadPDF()" title="PDF 다운로드 (P)" style="display:none">📥</button>
        <button class="quick-btn" onclick="showShortcuts()" title="단축키 (?)">?</button>
        <button class="quick-btn" onclick="scrollToTop()" title="맨 위로">&#8593;</button>
    </div>

    <div class="shortcuts-modal" id="shortcuts-modal">
        <h3>키보드 단축키</h3>
        <div class="shortcut-item"><span>이전 문서</span><span class="shortcut-key">&#8592;</span></div>
        <div class="shortcut-item"><span>다음 문서</span><span class="shortcut-key">&#8594;</span></div>
        <div class="shortcut-item"><span>검색</span><span class="shortcut-key">Ctrl+K</span></div>
        <div class="shortcut-item"><span>테마 전환</span><span class="shortcut-key">T</span></div>
        <div class="shortcut-item"><span>맨 위로</span><span class="shortcut-key">Home</span></div>
        <div class="shortcut-item"><span>PDF 다운로드</span><span class="shortcut-key">P</span></div>
        <div class="shortcut-item"><span>닫기</span><span class="shortcut-key">Esc</span></div>
    </div>

    <script src="lib/marked.min.js"></script>
    <script src="lib/fuse.min.js"></script>
    <script src="lib/highlight/highlight.min.js"></script>
    <script>const TIL_DATA = {json_str};</script>
    <script>{viewer_js}</script>
</body>
</html>"""

    # HTML을 assets 폴더에 생성
    output_path = os.path.join(ASSETS_PATH, "til-viewer.html")
    with open(output_path, "w", encoding="utf-8") as f:
        f.write(html_content)

    total_files = til_data["metadata"]["totalFiles"]
    print(f"카테고리: {len(categories)}개")
    print(f"파일: {total_files}개")
    print(f"총 라인: {total_lines}줄")
    if recent_days:
        print(f"제외된 파일: {skipped_files}개 (기간 외)")
    print(f"파일 위치: {output_path}")


if __name__ == "__main__":
    main()
