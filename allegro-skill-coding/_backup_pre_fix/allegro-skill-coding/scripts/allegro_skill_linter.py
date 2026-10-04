#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""
Allegro SKILL 静态规范检查器

基于 /sandbox/workspace/outputs/Allegro_SKILL_Coding_Standard.md 中定义的规范，
对目标 .il 文件进行自动化合规性检查。

用法:
    python allegro_skill_linter.py <path_to.il>
"""

import sys
import re
import os


class SkillLinter:
    MAX_LINE_LENGTH = 100

    def __init__(self, file_path):
        self.file_path = file_path
        self.issues = []
        self.content = ""
        self.lines = []
        self.has_chinese = False

    def load(self):
        if not os.path.exists(self.file_path):
            self._add_issue("FILE", 0, f"文件不存在: {self.file_path}", "error")
            return False

        # 自动检测编码：先尝试 UTF-8，失败则回退到 GBK
        content_bytes = open(self.file_path, "rb").read()
        for enc in ("utf-8", "gbk"):
            try:
                self.content = content_bytes.decode(enc)
                self.encoding = enc
                break
            except UnicodeDecodeError:
                continue
        else:
            self.content = content_bytes.decode("utf-8", errors="ignore")
            self.encoding = "utf-8 (ignore)"

        self.lines = self.content.splitlines()
        self.has_chinese = bool(re.search(r"[\u4e00-\u9fff]", self.content))
        return True

    def _add_issue(self, category, line_no, message, level="warning"):
        self.issues.append({
            "category": category,
            "line": line_no,
            "message": message,
            "level": level,
        })

    def check_file_header(self):
        """检查文件头注释是否包含关键字段。"""
        header_lines = []
        for line in self.lines:
            stripped = line.strip()
            if stripped.startswith(";"):
                header_lines.append(stripped)
            elif stripped == "":
                continue
            else:
                break

        header_text = "\n".join(header_lines)
        required_fields = [
            ("文件名", "文件名"),
            ("作者", "作者"),
            ("创建日期", "创建日期"),
            ("版本", "版本"),
            ("功能描述", "功能描述"),
        ]

        missing = []
        for label, _ in required_fields:
            if label not in header_text:
                missing.append(label)

        if missing:
            self._add_issue(
                "HEADER", 1,
                f"文件头注释缺少必要字段: {', '.join(missing)}",
                "error" if len(missing) >= 3 else "warning"
            )
        else:
            self._add_issue(
                "HEADER", 1,
                "文件头注释完整",
                "info"
            )

    def check_indentation(self):
        """检查是否使用 Tab 缩进。"""
        tab_found = False
        for i, line in enumerate(self.lines, start=1):
            if "\t" in line:
                self._add_issue("INDENT", i, "发现 Tab 缩进，请使用 4 个空格", "error")
                tab_found = True
        if not tab_found:
            self._add_issue("INDENT", 0, "未发现 Tab 缩进", "info")

    def check_line_length(self):
        """检查行长度是否超过 100。"""
        long_lines = []
        for i, line in enumerate(self.lines, start=1):
            if len(line) > self.MAX_LINE_LENGTH:
                long_lines.append(i)
        if long_lines:
            self._add_issue(
                "LINE_LENGTH", long_lines[0],
                f"以下行超过 {self.MAX_LINE_LENGTH} 字符: {long_lines}",
                "warning"
            )
        else:
            self._add_issue("LINE_LENGTH", 0, f"所有行长度均不超过 {self.MAX_LINE_LENGTH}", "info")

    def check_function_comments(self):
        """检查公共/私有函数前是否有函数注释。"""
        procedure_pattern = re.compile(r"^\s*\(procedure\(\s*([A-Za-z_][A-Za-z0-9_]*)")
        missing_comments = []
        for i, line in enumerate(self.lines, start=1):
            match = procedure_pattern.search(line)
            if match:
                func_name = match.group(1)
                # 检查前 10 行内是否有函数注释块
                start = max(0, i - 10)
                context = "\n".join(self.lines[start:i])
                if "函数名" not in context and "功能" not in context:
                    missing_comments.append((i, func_name))
        if missing_comments:
            for line_no, func_name in missing_comments:
                self._add_issue(
                    "FUNC_COMMENT", line_no,
                    f"函数 {func_name} 前缺少函数注释（函数名/功能/参数/返回值）",
                    "warning"
                )
        else:
            self._add_issue("FUNC_COMMENT", 0, "所有函数均包含函数注释", "info")

    def check_global_var_initialization(self):
        """检查全局变量是否通过 boundp 初始化。"""
        # 匹配全局变量赋值，如 g_demoVersion = "1.0"
        assign_pattern = re.compile(r"\b(g_[A-Za-z_][A-Za-z0-9_]*)\s*=\s*")
        # 匹配 unless(boundp('g_...)
        boundp_lines = set()
        for i, line in enumerate(self.lines, start=1):
            if "boundp" in line and "g_" in line:
                boundp_lines.add(i)

        violations = []
        for i, line in enumerate(self.lines, start=1):
            match = assign_pattern.search(line)
            if match and "boundp" not in line:
                var_name = match.group(1)
                # 检查同一行或前 3 行是否包含 boundp 初始化
                context_start = max(0, i - 3)
                context = "\n".join(self.lines[context_start:i])
                if f"boundp('{var_name})" not in context:
                    violations.append((i, var_name))

        if violations:
            for line_no, var_name in violations[:5]:  # 最多显示 5 条
                self._add_issue(
                    "GLOBAL_VAR", line_no,
                    f"全局变量 {var_name} 未使用 boundp 初始化，可能导致重复加载覆盖",
                    "warning"
                )
        else:
            self._add_issue("GLOBAL_VAR", 0, "全局变量初始化规范", "info")

    def check_transaction_protection(self):
        """检查数据库修改是否包含事务 start/commit/rollback。"""
        has_start = "axlDBTransactionStart" in self.content
        has_commit = "axlDBTransactionCommit" in self.content
        has_rollback = "axlDBTransactionRollback" in self.content
        # ASTB 项目明文例外：core/trans.il 的 ASTB_DBTransactionMark
        # 有意不使用 axlDBTransaction*（errset 保护 + 保留原生撤销历史），
        # 使用该封装即视为合规的事务保护
        has_astb_mark = "ASTB_DBTransactionMark" in self.content

        if has_start and has_commit and has_rollback:
            self._add_issue("TRANSACTION", 0, "发现数据库事务保护（Start/Commit/Rollback）", "info")
        elif has_astb_mark:
            self._add_issue("TRANSACTION", 0, "发现 ASTB_DBTransactionMark 保护（项目合规例外）", "info")
        elif has_start:
            self._add_issue(
                "TRANSACTION", 0,
                "存在事务开始，但缺少 Commit 或 Rollback，需成对出现",
                "error"
            )
        elif has_commit or has_rollback:
            self._add_issue(
                "TRANSACTION", 0,
                "存在 Commit/Rollback 但缺少 TransactionStart，配对不完整",
                "error"
            )
        else:
            self._add_issue(
                "TRANSACTION", 0,
                "未发现数据库事务保护，建议使用 axlDBTransaction* 或 ASTB_DBTransactionMark",
                "warning"
            )

    def check_select_set_clear(self):
        """检查选择集操作前是否清空。"""
        if "axlGetSelSet" in self.content and "axlClearSelSet" in self.content:
            self._add_issue("SELECT_SET", 0, "选择集操作包含清空逻辑", "info")
        elif "axlGetSelSet" in self.content:
            self._add_issue(
                "SELECT_SET", 0,
                "使用 axlGetSelSet 但未发现 axlClearSelSet，可能累积旧选择",
                "warning"
            )
        else:
            self._add_issue("SELECT_SET", 0, "未使用选择集 API", "info")

    def check_encoding(self):
        """检查含中文注释的文件编码建议。"""
        if self.has_chinese:
            if getattr(self, "encoding", "").lower().startswith("gbk"):
                self._add_issue(
                    "ENCODING", 0,
                    "文件包含中文注释且已使用 GBK 编码保存",
                    "info"
                )
            else:
                self._add_issue(
                    "ENCODING", 0,
                    "文件包含中文注释，建议使用 GBK 编码保存以避免 Allegro 加载乱码",
                    "warning"
                )
        else:
            self._add_issue("ENCODING", 0, "文件无中文注释，UTF-8 编码即可", "info")

    def check_bare_set(self):
        """检查是否使用了裸 set（全局变量创建）。"""
        # 简单规则：set( 可能创建全局变量，建议用 let / prog 局部绑定
        bare_set = re.compile(r"\(\s*set\s*\(")
        violations = []
        for i, line in enumerate(self.lines, start=1):
            if bare_set.search(line):
                violations.append(i)
        if violations:
            for line_no in violations[:3]:
                self._add_issue(
                    "BARE_SET", line_no,
                    "发现裸 set 调用，建议优先使用 let / prog 局部绑定",
                    "warning"
                )
        else:
            self._add_issue("BARE_SET", 0, "未发现裸 set 调用", "info")

    def check_ok_to_proceed(self):
        """检查数据库操作前是否检查环境状态。"""
        if "axlOKToProceed" in self.content:
            self._add_issue("ENV_CHECK", 0, "发现 axlOKToProceed 环境检查", "info")
        elif "axlDBCreate" in self.content or "axlDeleteObject" in self.content:
            self._add_issue(
                "ENV_CHECK", 0,
                "存在数据库创建/删除操作，建议调用 axlOKToProceed 检查环境",
                "warning"
            )
        else:
            self._add_issue("ENV_CHECK", 0, "无数据库修改操作", "info")

    def run_all(self):
        if not self.load():
            return
        self.check_file_header()
        self.check_indentation()
        self.check_line_length()
        self.check_function_comments()
        self.check_global_var_initialization()
        self.check_transaction_protection()
        self.check_select_set_clear()
        self.check_encoding()
        self.check_bare_set()
        self.check_ok_to_proceed()

    def report(self):
        """输出检查报告。"""
        print(f"\n{'='*70}")
        print(f"Allegro SKILL 静态规范检查报告")
        print(f"目标文件: {self.file_path}")
        print(f"检测编码: {self.encoding}")
        print(f"总行数: {len(self.lines)}")
        print(f"{'='*70}\n")

        info = [i for i in self.issues if i["level"] == "info"]
        warnings = [i for i in self.issues if i["level"] == "warning"]
        errors = [i for i in self.issues if i["level"] == "error"]

        # 按行号排序
        all_issues = sorted(self.issues, key=lambda x: (x["level"] != "error", x["level"] != "warning", x["line"]))

        for issue in all_issues:
            line_str = f"第 {issue['line']:4d} 行" if issue["line"] > 0 else "      全局"
            print(f"[{issue['level'].upper():7}] {line_str} [{issue['category']:12}] {issue['message']}")

        print(f"\n{'='*70}")
        print(f"汇总: 信息 {len(info)} 条, 警告 {len(warnings)} 条, 错误 {len(errors)} 条")
        if errors:
            print("结论: 存在错误，请先修复后再提交。")
        elif warnings:
            print("结论: 存在警告，建议按规范优化。")
        else:
            print("结论: 检查通过，符合规范基本要求。")
        print(f"{'='*70}\n")

        return len(errors) == 0


def main():
    if len(sys.argv) < 2:
        print(f"用法: python {sys.argv[0]} <path_to.il>")
        sys.exit(1)

    target = sys.argv[1]
    linter = SkillLinter(target)
    linter.run_all()
    passed = linter.report()
    sys.exit(0 if passed else 1)


if __name__ == "__main__":
    main()
