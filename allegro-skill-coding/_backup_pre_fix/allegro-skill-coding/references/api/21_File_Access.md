# 第 21 章 文件访问 (File Access)

## Allegro PCB Editor 文件访问函数 (Allegro PCB Editor File Access Functions)

**产品文档**: Allegro SKILL Reference  
**产品版本**: 17.4-2019, October 2019

---

## AXL-SKILL 文件访问函数 (AXL-SKILL File Access Functions)

**说明**：本章描述打开和关闭 Allegro PCB Editor 文件的 AXL-SKILL 函数。请使用这些函数，而不是 SKILL 的 `infile` 和 `outfile`，以使用 Allegro PCB Editor 标准而非通过 SKILL 路径来访问文件。

**Original**: This chapter describes the AXL-SKILL functions that open and close Allegro PCB Editor files. Use these functions, instead of SKILL's infile and outfile, to access files using Allegro PCB Editor standards, not via the SKILL path.

---

### axlDMFileError

**说明**：返回上次 `axlDM`xxx 调用的错误。后续调用会重置错误消息，因此您应该在调用失败后立即检索错误。

**Original**: This returns the error from the last axlDMxxx call. Subsequent calls reset the error message so you should retrieve the error as soon as a call fails.

**语法**：
```skill
axlDMFileError()
```

**参数**：无

**返回值**：
- `nil` — 无错误消息可用。
- `t_errorMessage` — 指示上次操作失败原因的消息。

**另请参阅**：`axlDMOpenFile`

**示例**：
```skill
q = axlDMOpenFile("TEMP" "foo.bar" "r")
unless(q
  printf("ERROR is %L\n" axlDMFileError()))
```

---

### axlDMFindFile

**说明**：使用 Allegro PCB Editor 约定打开文件。添加扩展名并可选择在 Allegro PCB Editor 搜索路径中查找它。

必须在 `fileops.txt` 文件中有一个条目。

**Original**: Opens a file using Allegro PCB Editor conventions. Adds an extension and optionally looks it up in an Allegro PCB Editor search path. Must have an entry in fileops.txt file.

**语法**：
```skill
axlDMFindFile(t_id t_name t_mode [t_prop])
```

**参数**：
- `t_id` — 描述 `fileops.txt` 中文件属性的 ID。
- `t_name` — 要查找的文件名称。
- `t_mode` — 打开模式。以下之一：
  - `r`：只读
  - `w`：写入
  - `wf`：写入行缓冲
- `t_prop` — 属性字符串。

**返回值**：
- `t_name` — 打开的文件名称。
- `nil` — 无法打开文件。

**另请参阅**：`axlDMOpenFile`

**示例**：
```skill
(setq aPort(axlDMFindFile "ALLEGRO_TEXT" "clip" "w" ":HELP=clipboard"))
```
查找用于写入的完全限定名称 `clip.txt`。

---

### axlDMGetFile

**说明**：使用 Allegro PCB Editor 约定获取文件名称 `t_name`，如参数中所述。返回文件的完整路径名。如果文件无法打开，则显示错误消息。

**Original**: Gets the file name t_name using Allegro PCB Editor conventions as described in the arguments. Returns the full path name of the file. Displays an error message if the file cannot be opened.

**语法**：
```skill
axlDMGetFile(t_id t_name t_mode [t_prop])
```

**参数**：
- `t_id` — 文件属性 ID。此字符串必须是 Allegro PCB Editor 系统文件 `fileops.txt` 中的类型之一。示例包括：
  - `ALLEGRO_LAYOUT_DB` — 用于 Allegro PCB Editor 布局，扩展名为 `brd`。
  - `ALLEGRO_REPORT` — 用于 Allegro PCB Editor 报告文件，扩展名为 `rpt`。
- `t_name` — 给出要打开文件名称的字符串。
- `t_mode` — 打开模式。以下之一：
  - `r`：只读
  - `w`：写入
  - `wf`：写入行缓冲
- `t_prop` — 属性字符串。

**返回值**：
- `t_name` — 文件名称。在 `t_mode` = `"r"` 的情况下，文件必须存在才能成功完成。
- `nil` — 文件未找到。显示一个确认框，给出无法找到的文件名称。

**另请参阅**：`axlDMOpenFile`

**示例**：
```skill
myfile = axlDMGetFile("ALLEGRO_TEXT" "clip" "r")
=> "/usr/home/fred/myproj/clip.txt"
```
查找可用于读取的文件 `clip.txt`。

---

### axlDMOpenFile

**说明**：以常规 Allegro 方式打开文件；添加扩展名并可选择在 Allegro 搜索路径中查找它。必须在 `fileops.txt` 文件中有一个条目。

Allegro 目前不支持包含空格的目录或文件名。请使用此函数替代 SKILL 的 `infile`/`outfile`。SKILL 接口使用 `SKILLPATH` 解析文件位置，这意味着如果 `SKILLPATH` 没有 `"."` 作为其第一个组件，则文件可能不会在当前目录中打开。`axlDMOpenFile` 使用 Allegro 约定打开文件。

如果使用 `axlDMOpenFile` 打开文件，请使用 `axlDMClose` 关闭它。所有其他 SKILL 文件 API 都适用于此接口返回的端口。

如果您想使用 Allegro 的标准文件扩展名支持（如果未提供扩展名则追加扩展名），请参阅 `<cdsroot>/share/pcb/text/fileops.txt` 获取 `t_ids` 列表。否则，如果您始终提供扩展名，请使用 `TEMP` ID。

使用 `get_filename(p_port)` 获取文件的名称。

**Original**: Opens a file in conventional Allegro manner; adds an extension and optionally looks it up in an Allegro search path. Must have an entry in fileops.txt file. Allegro currently does not support directory or file names containing spaces. Use this in place of SKILL's infile/outfile. The SKILL interfaces resolve the file location using SKILLPATH which may mean that files may not open in the local directory if the SKILLPATH does not have "." as its first component. axlDMOpenFile uses the Allegro convention to open file. If you use axlDMOpenFile to open a file, use axlDMClose to close it. All other SKILL file APIs work on the port returned by this interface. If you want to use Allegro's standard file extension support (the extension is appended if not present), then see <cdsroot>/share/pcb/text/fileops.txt for a list of t_ids. Otherwise, if you always provide an extension, use the TEMP id. Use get_filename(p_port) to obtain the name of the file.

**语法**：
```skill
axlDMOpenFile(t_id t_name t_mode)
```

**参数**：
- `t_id` — 文件属性 ID。此字符串必须是 Allegro PCB Editor 系统文件 `fileops.txt` 中的类型之一。示例包括：
  - `ALLEGRO_LAYOUT_DB` — 用于 Allegro PCB Editor 布局，扩展名为 `brd`。
  - `ALLEGRO_REPORT` — 用于 Allegro PCB Editor 报告文件，扩展名为 `rpt`。
- `t_name` — 给出要打开文件名称的字符串。
- `t_mode` — 打开模式。以下之一：
  - `r`：只读
  - `w`：写入，如果不存在则创建，如果存在则截断为零长度
  - `a`：打开用于写入，如果不存在则创建，如果存在则追加到文件末尾
  
  此外，支持以下修饰符：
  - `f`：每次写入后刷新文件。这在 Windows 上通过网络写入时可能很慢。如果进程需要很长时间，并且您希望查看文件以了解进度，则通常使用此选项。例如 `"wf"`。
  - `b`：以二进制模式打开。这仅在 Windows 上有效。如果文件是 ASCII，则读取时不会消除 DOS ASCII 文件中的回车符（`\r`）。写入时，它不会在看到换行符时添加回车符（像 UNIX ASCII 文件一样写入）。例如 `"rb"`。
  - `s`：允许文件或目录名称中包含空格。目前，Allegro 不支持此行为。设置此选项不受支持。例如 `"rbs"`。

**返回值**：
- `p_port` — 打开文件的端口。在 `t_mode` = `"r"` 的情况下，文件必须存在才能成功完成。
- `nil` — 文件未找到。显示一个确认框，给出无法找到的文件名称。

**另请参阅**：`axlDMFileError`, `axlDMFindFile`, `axlDMGetFile`, `axlDMOpenLog`, `axlDMClose`, `axlDMFileParts`

**示例**：
```skill
aPort = axlDMOpenFile("ALLEGRO_TEXT" "clip" "w")
```
打开文件 `clip.txt` 用于写入。

```skill
aPort = axlDMOpenFile("TEMP" "foo.bar" "r")
```
打开文件 `b.bar`。

---

### axlDMOpenLog

**说明**：打开一个文件用于写入日志消息。使用您的程序或应用程序的名称，不带扩展名。打开具有该名称和扩展名 `.log` 的文件。如果成功，返回文件的端口。

**Original**: Opens a file for writing log messages. Uses the name of your program or application without an extension. Opens a file with that name and the extension .log. Returns the port of the file if it succeeds.

**语法**：
```skill
axlDMOpenLog(t_program)
```

**参数**：
- `t_program` — 您的程序名称 - 无扩展名。

**返回值**：
- `p_port` — 打开文件的端口。在 `t_mode` = `"r"` 的情况下，文件必须存在才能成功完成。
- `nil` — 文件未找到。显示一个确认框，给出无法找到的文件名称。

**另请参阅**：`axlDMOpenFile`

**示例**：
```skill
logport = axlDMOpenLog("clipboard"))
```
打开文件 `clipboard.log` 用于写入。

---

### axlDMClose

**说明**：关闭当前在 Allegro PCB Editor 中打开的文件。不要使用 SKILL 的 `infile`/`outfile` 命令，必须使用此命令来关闭使用 `axlDMOpenFile` 或 `axlDMOpenLog` 命令打开的文件。

虽然核心 SKILL 函数 `close` 可以用于关闭文件，但建议任何使用 `axlDM` 函数打开的文件都必须使用此函数关闭。遵循此标准的程序将与未来的 Allegro 数据管理增强功能兼容。

**Original**: Closes a file currently open in Allegro PCB Editor. Instead of using SKILL's infile/outfile commands, this command must be used to close the files opened using axlDMOpenFile or axlDMOpenLog commands. While the core SKILL function, close can be used to close a file, it is recommended that any file opened using an axlDM function, must be closed using this function. Programs that adhere to this standard, will be compatible with future Allegro Data Management enhancements.

**语法**：
```skill
axlDMClose(p_port)
```

**参数**：
- `p_port` — 要关闭的开放端口的 ID。

**返回值**：
- `t` — 文件已关闭。
- `nil` — 文件未找到。

**示例**：
```skill
mylog = axlDMOpenLog("myapplic")
=> port: "/usr/home/fred/myproj/myapplic.log"
axlDMClose(mylog)
=> t
```
打开并关闭文件 `myapplic.log`。

---

### axlDMBrowsePath

**说明**：调用标准 Allegro PCB Editor 文件浏览器支持路径，例如 `SCRIPTPATH`。使用时，请传递 `fileops.txt` 支持的文件类型之一。浏览包含 fileops `PATH` 属性的文件类型。

`axlDMFileBrowse` 应用于浏览其他文件类型。这适用于非 PATH 文件类型，因为它浏览当前工作目录。用户无法使用此浏览器更改目录。

**Original**: Invokes a standard Allegro PCB Editor file browser supporting paths, for example, SCRIPTPATH. To use, pass one of the file types supported by fileops.txt. Browses file types that include the fileops PATH attribute. axlDMFileBrowse should be used to browse other file types. This works on non-PATH file types since this browses in the current working directory. The user is not able to change the directory with this browser.

**语法**：
```skill
axlDMBrowsePath(t_adsFileType [t_title] [t_helpTag])
```

**参数**：
- `t_adsFileType` — `fileops.txt` 中的第一个条目。
- `t_title` — 对话框标题。
- `t_helpTag` — 帮助文件的标签（仅由 Cadence 使用）。

**返回值**：
- `t_filename` — 文件的完整路径。
- `nil` — 由于参数不正确导致错误。

**示例**：
```skill
ret = axlDMBrowsePath("ALLEGRO_SCRIPT")
ret = axlDMBrowsePath("ALLEGRO_CLIPBOARD" "Select Clipboard")
```

---

### axlDMDirectoryBrowse

**说明**：打开目录浏览器。与文件浏览器不同，这仅允许用户选择目录。此函数调用会阻塞，直到用户选择或取消。

**Original**: Opens a directory browser. Unlike file browsers, this only allows a user to select a directory. This function call blocks until the user selects or cancels.

**语法**：
```skill
axlDMDirectoryBrowse(t_startingDirectory g_writeFlag [?helpTag t_helpTag] [?title t_title])
```

**参数**：
- `t_startingDirectory` — 起始目录的名称。
- `g_writeFlag` — 布尔值 - 如果文件要打开用于写入（`t`），或用于读取（`nil`）。
- `t_helpTag` — 定义用户在浏览器中选择 `Help` 按钮时显示的帮助消息。如果未设置此选项，则提供默认帮助。
- `g_title` — 覆盖浏览器的默认标题栏。通常，这是调用浏览器的命令的名称。

**返回值**：
- `t_dirName` — 所选目录的名称。
- `nil` — 未选择目录。

**示例**：
```skill
axlDMDirectoryBrowse("." t ?title "Pick a directory")
```
浏览当前目录。

---

### axlDMFileBrowse

**说明**：打开标准文件浏览器。与其他 `axlDM` 函数不同，这始终向用户显示文件浏览器。此函数调用会阻塞，直到用户选择文件或取消。

选择并返回文件的名称给调用者。不打开所选文件。

最终过滤器为 `'All files (*.*)'`。

**Original**: Opens a standard file browser. Unlike the other axlDM functions, this always presents the user with a file browser. This function call blocks until the user selects a file or cancels. The name of the file is selected and returned to the caller. Does not open the selected file. The final filter is 'All files (*.*)'.

**语法**：
```skill
axlDMFileBrowse(t_fileType g_writeFlag [?defaultName t_defaultName] [?helpTag t_helpTag] [?directorySet g_directorySet] [?noDirectoryButton g_noDirectoryButton] [?mainFile g_mainFile] [?noSticky g_noSticky] [?title t_title] [?optFilters t_filters])
```

**参数**：
- `t_id` — 描述 `fileops.txt` 中文件属性的 ID，或不同类型的 ID 列表，或 `nil` 如果您使用 `optFilters` 来描述文件。
- `g_writeFlag` — 如果文件要打开用于写入（`t`），或用于读取（`nil`）。
- `t_defaultName` — 默认选择的文件名称。
- `t_helpTag` — 定义用户在浏览器中选择 Help 按钮时显示的帮助消息的标签。如果未设置选项，则提供默认帮助。
- `g_directorySet` — 设置目录更改按钮，默认情况下未设置。
- `g_noDirectoryButton` — 在浏览器中隐藏目录更改按钮。默认情况下，该按钮存在。
- `g_noSticky` — 文件浏览器通常记住上一次调用时的目录。这有助于在不同于当前工作目录的同一位置浏览的用户。如果为 `t`，则它在当前工作目录中启动浏览器。通常，如果 `g_directorySet` 为 `t`，则应设置此选项。
- `g_mainFile` — 匹配 Allegro PCB Editor 从文件菜单打开文件时使用的选项。这是 `g_noSticky` = `t` 且 `g_directorySet` = `t`。对于非主文件，不使用选项。
- `g_title` — 覆盖浏览器的默认标题栏。通常这是调用浏览器的命令的名称。
- `g_filters` — 添加到默认 `t_id` 过滤器的过滤器。格式为：`<msg>|<filter>|<msg>|<filter>...`

**返回值**：
- `t_fileName` — 所选文件的名称。
- `nil` — 未选择文件。

**示例**：
```skill
axlDMFileBrowse("ALLEGRO_TEXT" nil)
```
浏览 Allegro PCB Editor 文本文件。

```skill
axlDMFileBrowse("ALLEGRO_TEXT" nil ?optFilters "All log files (*.log)|*.log")
```
浏览 Allegro PCB Editor 文本文件，并允许 `*.log` 的辅助过滤器。

```skill
axlDMFileBrowse(nil nil ?optFilters "Skill files(*.il)|*.il|Skill Oops(*.ils)|*.ils")
```
浏览 SKILL 文件（.il 和 .ils 扩展名）。

---

### axlDMFileParts

**说明**：将文件名分解为其组成部分。

**Original**: Breaks a filename into its component parts.

**语法**：
```skill
axlDMFileParts(t_filespec)
```

**参数**：
- `t_filespec` — 文件名或完整路径规格。

**返回值**：
- `list` — `(directory file fileWext ext)`

**另请参阅**：`axlDMOpenFile`

**示例**：
```skill
fileparts = axlDMFileParts("/usr1/xxx/stuff.txt")
--> ("/usr1/xxx/" "stuff" "stuff.txt" "txt")

fileparts = axlDMFileParts("stuff.txt")
--> ("/usr1/xxx/" "stuff" "stuff.txt" "txt")
```
**其中 /usr1/xxx 是 cwd**

---

### axlOSFileCopy

**说明**：将给定源文件复制到给定目标，可选择追加。

**Original**: Copies a given source file to a given destination with optional append.

**语法**：
```skill
axlOSFileCopy(t_src t_dest g_append)
```

**参数**：
- `t_src` — 源文件的完整路径。
- `t_dest` — 目标文件的完整路径。
- `g_append` — 追加功能的标志（`t` / `nil`）。

**返回值**：
- `t` — 文件已复制。
- `nil` — 由于参数不正确，无法复制文件。

**示例**：
```skill
unless(axlOSFileCopy("~/myfile" "~/newfile" nil)
  axlUIConfirm("file copy FAILED"))
```

---

### axlOSFileMove

**说明**：将给定源文件移动到给定目标。

**Original**: Moves the given source file to the given destination.

**语法**：
```skill
axlOSFileMove(t_src t_dest)
```

**参数**：
- `t_src` — 源文件的完整路径。
- `t_dest` — 目标文件的完整路径。

**返回值**：
- `t` — 文件已移动。
- `nil` — 无法移动文件。

**示例**：
```skill
unless(axlOSFileMove("/mydir/myfile" "/newdir/newfile")
  axlUIConfirm("file move FAILED"))
```

---

### axlOSSlash

**说明**：将 DOS 样式的反斜杠更改为 UNIX 样式的斜杠，后者更适合 SKILL。在 UNIX 上，返回传入的字符串。

**Original**: Changes DOS style backslashes to UNIX style slashes which are more amenable to SKILL. On UNIX, returns the incoming string.

**语法**：
```skill
axlOSSlash(t_directory)
```

**参数**：
- `t_directory` — 给定的目录路径。

**返回值**：
- `t_directory` — 使用 UNIX 样式斜杠（`/`）的目录路径。
- `nil` — 由于参数不正确而失败。

**另请参阅**：`axlOSBackSlash`

**示例**：
```skill
p = axlOSSlash("\tmp\mydir")
-> "/tmp/mydir"
```

---

### axlRecursiveDelete

**说明**：递归删除参数列表中的目录和子目录。目录被清空并删除。如果尝试删除非空的、受写保护的目录，则实用程序会失败。如果遇到受保护的文件或子目录，它不会删除它们或父目录，但会删除所有其他对象。

这可能会很危险，因为如果不小心使用，它可能会严重损坏您的系统或数据。例如，`axlRecursiveDelete("/")` 可能会删除您的操作系统和所有数据。

**Original**: Recursively removes directories and subdirectories in the argument list. Directory is emptied of files and removed. If the removal of a non-empty, write-protected directory is attempted, the utility fails. If it encounters protected files or sub-directories, it does not remove them or the parent directories, but removes all other objects. This can be dangerous since it can severely damage your system or data if not used with care. For example, axlRecursiveDelete("/") could delete your OS and all of your data.

**语法**：
```skill
axlRecursiveDelete(t_directory)
```

**参数**：
- `t_directory` — 给定的目录或文件名。

**返回值**：
- `t` — 目录已成功删除。
- `nil` — 由于以下原因之一失败：
  - 不存在
  - 读保护
  - 子文件或目录不允许删除（部分成功）
  - 子文件或目录正在使用中（仅限 NT）（部分成功）

部分成功意味着某些文件和目录已被删除。

**示例**：
```skill
parent = "./tmp"
child = (strcat parent "/child")
(createDir parent)
(createDir child)
(axlOSFileCopy "~/.cshrc" (strcat parent "/csh") nil)
(axlOSFileCopy "~/.cshrc" (strcat child "/csh") nil)
(axlRecursiveDelete parent)
```

---

### axlTempDirectory

**说明**：返回当前平台的临时目录。

**Original**: Returns the temporary directory for the current platform.

**语法**：
```skill
axlTempDirectory()
```

**参数**：无

**返回值**：
- `t_directory` — 当前平台的临时目录。
- `nil` — 无法识别当前平台的临时目录。

---

### axlTempFile

**说明**：返回一个唯一的临时文件名。即使未使用，临时文件也应由 `axlTempFileRemove` 删除。

默认情况下，文件写入到 `/tmp`，但您可以使用环境变量 `TEMPDIR` 修改此设置。

**Original**: Returns a unique temp file name. The temp file should be removed, even if not used, by axlTempFileRemove. By default, the files are written to /tmp, but you can modify this with the environment variable TEMPDIR.

**语法**：
```skill
axlTempFile([g_local])
```

**参数**：
- `g_local` — 标志，如果为 `t`，则在当前目录中创建临时文件。大多数应用程序应使用默认的 `/tmp` 目录。仅当文件将超过 2 兆字节时，才应使用本地目录。

**返回值**：
- `t_tempFileName` — 唯一临时文件的名称。
- `nil` — 无法创建临时文件。

---

### axlTempFileRemove

**说明**：删除临时文件并从池中删除临时名称。一旦您完成使用临时文件名，调用此函数非常重要。

这也可用于删除名称不是从 `axlTempFile` 获取的文件。

**Original**: Deletes the temporary file and removes the temporary name from the pool. It is important to call this function once you are finished with a temporary filename. This can also be used to delete files whose names are not obtained from axlTempFile.

**语法**：
```skill
axlTempFileRemove(t_filename)
```

**参数**：
- `t_filename` — 要删除的文件名称。

**返回值**：
- `t` — 删除了指定的临时文件。
- `nil` — 由于参数不正确，无法删除指定的临时文件。

---

*返回顶部 (Return to top)*
