# 第 17 章 数据库附件 (Database Attachment)

> **来源**：`16dbatt.html`  
> **产品版本**：Allegro SKILL Reference 17.4-2019, October 2019

---

## 概述 (Overview)

**说明**：本章描述 AXL-SKILL 数据库附件函数。

**Original**: This chapter describes the AXL-SKILL Database Attachment functions.

---

### axlCreateAttachment

**说明**：使用给定的附件 ID 创建一个新的 Allegro PCB Editor 数据库附件。附件可以选填密码和修订版本号。附件数据可以指定为字符串或文件名。

**Original**: Creates a new Allegro PCB Editor database attachment with the given attachment id. The attachment may optionally be given a password and a revision number. The attachment data may be specified as a string or as a file name.

`axlDBControl('maxAttachmentSize)` 返回可附加到数据库的数据的最大大小。

**Original**: axlDBControl('maxAttachmentSize) returns the maximum size of data that can attach to the database.

不要创建或替换您不拥有的附件。这包括任何预定义的 Allegro 附件，如 DFA 或 quickviews。

**Original**: Do not create or replace attachments you do not own. This includes any predefined Allegro attachments like DFA or quickviews.

**语法**：
```skill
axlCreateAttachment(
  t_attachmentId
  t_passwd
  x_revision
  s_dataFormat
  t_data
)
```

**参数**：

- `t_attachmentId`: 要检索的附件的 ID 或名称。长度最多为 31 个字符。**Original**: Id or name of the attachment to retrieve. Can be up to 31 characters in length.

- `t_passwd`: 此附件的密码。长度最多为 31 个字符。如果不需要密码，可以为 `nil`。**Original**: Password for this attachment. Can be up to 31 characters in length. If no password is desired this may be nil.

- `x_revision`: 附件的修订版本号。如果为 `nil`，修订版本号设置为零。**Original**: Revision number of the attachment. If nil, the revision number is set to zero.

- `s_dataFormat`: 指示 `t_data` 参数的格式。允许的值：
  - `'string` — `t_data` 参数的值用作附件数据。
  - `'file` — `t_data` 引用一个被读入数据库附件的 ASCII 文件。
  - `'binary` — `t_data` 引用一个被读入数据库附件的二进制文件。将此选项用于 zip 或压缩文件。

**Original**: Indicates the format of the t_data argument. Permitted values: 'string — the value of the t_data argument is used for the attachment data. 'file — t_data references an ASCII file that is read into the database attachment. 'binary — t_data references a binary file that is read into the database attachment. Use this option with zip or compressed files.

- `t_data`: 附件数据。

**Original**: t_data

**返回值**：

- `o_attachment`: 新附件的 AXL ID，随后可以使用右箭头（`->`）运算符查询。

**Original**: AXL id for the new attachment, which can then be queried using the right arrow (->) operator.

- `nil`: 由于参数不正确，未能创建附件。

**Original**: Failed to create an attachment due to incorrect arguments.

一旦附件受密码保护，需要删除它然后重新添加才能移除或更改密码保护。

**Original**: Once an attachment is password protected it needs to be deleted, then re-added to remove or change the password protection.

**另请参阅 (See Also)**：`axlGetAttachment`

**Original**: See Also `axlGetAttachment`

**示例**：

**说明**：此示例使用附件将变量列表存储在数据库中。例如，您设计了一个表单，用户在其中输入首选项，并通过游离属性列表（disembodied property list）在 SKILL 中管理这些首选项。您希望将用户的首选项与设计一起存储。

**Original**: This uses an attachment to store in the database a list of variables. For example, you design a form where the user enters in their preferences and you manage them in SKILL via a disembodied property list. You would like to store the user's preferences with the design.

创建一个附件名称。使用下划线、公司名称和应用程序来创建一个唯一的名称。例如，`_acme_bom_rpt` 就是一个好的附件名称。

**Original**: Create an attachment name. Create a name using an underscore, company name and application to make it unique. For example, _acme_bom_rpt, would be a good attachment name.

```skill
attachName = "fxf"
; A typical disembodied property list
mylist = ncons(nil)
mylist->ccw = t
mylist->middle = nil
mylist->cx = 0.12
mylist->cy = 10.192
mylist->layer = "TOP"
```

不要将 dbid 存储在游离列表中，或者在存储为附件之前确保将其移除。

**Original**: Do not store dbid's in the disembodied list or make sure to remove them before storing as an attachment.

将列表存储在当前设计中（假设用户保存了设计）：

**Original**: Store list in current design (assuming user saves design)

```skill
dataString = sprintf(nil " '%L" mylist)
axlCreateAttachment(attachName nil 0 'string dataString)
```

下次用户运行 SKILL 代码时，按如下方式初始化列表：

**Original**: Next time user runs the SKILL code, here is how to init the list:

```skill
attach = axlGetAttachment(attachName 'string)
if( attach) then
mylist = car(errsetstring(attach->data))
else   ; no list stored in design so init to default settings
mylist = ncons(nil)
mylist->ccw = t
)
```

---

### axlDeleteAttachment

**说明**：删除给定的附件。如果附件受密码保护，必须提供正确的密码。

**Original**: Deletes the given attachment. If the attachment is password protected, the correct password must be given.

不要删除您不拥有的附件。这包括任何预定义的 Allegro 附件，如 DFA 或 quickviews。

**Original**: Do NOT delete attachments you do not own. This includes any predefined Allegro attachments like DFA or quickviews.

**语法**：
```skill
axlDeleteAttachment(
  t_attachmentId
  [t_passwd]
)
```

**参数**：

- `t_attachmentId`: 要删除的附件的 ID 或名称。

**Original**: Id or name of the attachment to delete.

- `t_passwd`: 此附件的密码。

**Original**: Password for this attachment.

**返回值**：

- `t`: 附件已成功删除。

**Original**: Attachment successfully deleted.

- `nil`: 附件未删除。

**Original**: Attachment not deleted.

**另请参阅 (See Also)**：`axlGetAttachment`

**Original**: See Also `axlGetAttachment`

---

### axlGetAllAttachmentNames

**说明**：返回当前 Allegro PCB Editor 数据库中所有数据库附件的 ID 列表。如果数据库中不存在附件，则返回 `nil`。可以使用 `axlGetAttachment()` 函数检索这些附件。

**Original**: Returns a list of the ids for all database attachments in the current Allegro PCB Editor database. If no attachments are present, then nil is returned. The attachments can retrieved using the axlGetAttachment () function.

**语法**：
```skill
axlGetAllAttachmentNames()
```

**参数**：

- 无

**返回值**：

- `l_attachment`: 附件 ID 列表。

**Original**: List of attachment ids.

- `nil`: 数据库中不存在附件。

**Original**: No attachments exist in the database.

---

### axlGetAttachment

**说明**：返回具有给定 ID 的数据库附件。如果附件存在，则返回一个包含附件信息的 **attachment record**（附件记录）。数据以 `s_dataFormat` 参数指定的格式返回。如果为 `'file` 格式，则 `data` 属性包含数据写入的临时文件名。如果为 `'string`，则 `data` 属性包含附件数据本身。如果 `s_dataFormat` 参数被省略或为 `nil`，则 `data` 属性为 `nil`。

**Original**: Returns the database attachment with the given id. If the attachment exists, an attachment record is returned containing information about the attachment. The data is in the format specified by the s_dataFormat argument. If 'file format, then the data attribute contains a temporary file name to which the data was written. If 'string, then the data attribute contains the attachment data itself. If the s_dataFormat argument is omitted or is nil, then the data attribute is nil.

附件记录具有以下属性：

**Original**: The attachment record has the following attributes:

| 名称 (Name) | 类型 (Type) | 可设置? (Set?) | 说明 (Description) |
|---|---|---|---|
| `objType` | `string` | NO | 始终为 `"attachment"`。
| `id` | `string` | NO | 附件的 ID（名称）。
| `password` | `boolean` | NO | `t`/`nil` - 指示附件是否受密码保护。
| `timeStamp` | `integer` | NO | 指示上次修改的时间（秒）。
| `revision` | `integer` | YES | 用户定义的附件数据修订版本号。
| `dataFormat` | `symbol` | YES | 指示 "data" 属性中存储的数据格式，为 `'file`、`'string` 或 `nil`（此时不显示数据）。如果使用 `'binary` 选项创建附件，则显示 `'file`。
| `data` | `string` | YES | 附件数据。根据 `dataFormat` 属性的值，可能是文件名、数据本身或 `nil`。
| `timeStamp` | `integer` | NO | 指示附件的大小。

**Original**: Name / Type / Set? / Description table with objType, id, password, timeStamp, revision, dataFormat, data attributes.

允许访问私有数据库中的附件。不要创建、更改或删除这些附件。附件访问规则如下：如果您的应用程序**没有**创建该附件，则**不要**更改它。

**Original**: Access to attachments in the private database is allowed. Do not create, change, or delete these attachments. The rule for attachments access is: If your application did NOT create the attachment do NOT change it.

**语法**：
```skill
axlGetAttachment(
  t_attachmentId
  [s_dataFormat]
)
```

**参数**：

- `t_attachmentId`: 要检索的附件的 ID 或名称。长度最多为 31 个字符。

**Original**: Id or name of the attachment to retrieve. Can be up to 31 characters in length.

- `s_dataFormat`: 附件数据在 "data" 属性中存储的格式。必须是：
  - `'string`: 将数据作为字符串返回。
  - `'file`: 将数据存储在临时文件中返回。如果您使用 `'binary` 方法创建附件，则应使用此选项。
  - `nil`: 使用附件 dataFormat 属性中描述的方法。

**Original**: Format in which the attachment data is stored in the "data" attribute. Must be: 'string: return data as a string. 'file: return data stored in a tmp file. You should use this option if you used 'binary method to create the attachment. nil: use the method describe in the attachment dataFormat attribute.

**返回值**：

- `o_attachment`: 附件结构的 AXL ID，可以使用右箭头（`->`）运算符查询。

**Original**: AXL id for the attachment structure which can be queried using the right arrow (->) operator.

- `nil`: 附件不存在。

**Original**: Attachment does not exist.

**示例**：

```skill
attachment = axlGetAttachment("attachmentOne" 'file)
⇒ attachment:attachmentOne
```

**另请参阅 (See Also)**：`axlIsAttachment`、`axlGetAllAttachmentNames`、`axlCreateAttachment`、`axlSetAttachment`、`axlDeleteAttachment`

**Original**: See Also axlIsAttachment, axlGetAllAttachmentNames, axlCreateAttachment, axlSetAttachment, axlDeleteAttachment

---

### axlIsAttachment

**说明**：确定给定对象是否为 AXL 附件。

**Original**: Determines if the given object is an AXL attachment.

**语法**：
```skill
axlIsAttachment(
  o_attachment
)
```

**参数**：

- `o_attachment`: 要检查的对象。

**Original**: Object to check.

**返回值**：

- `t`: 对象是附件。

**Original**: Object is an attachment.

- `nil`: 对象不是附件。

**Original**: Object is not an attachment.

**另请参阅 (See Also)**：`axlGetAttachment`

**Original**: See Also `axlGetAttachment`

---

### axlSetAttachment

**说明**：使用给定 AXL 附件 ID 中包含的数据修改现有的 Allegro PCB Editor 数据库附件。原始附件对象必须从 `axlCreateAttachment`、`axlGetAttachment` 或 `axlGetAllAttachments` 函数获取。可以修改附件修订版本号和附件数据。

**Original**: Modifies an existing Allegro PCB Editor database attachment with the data contained in the given AXL attachment id. Original attachment object must be obtained from the axlCreateAttachment, axlGetAttachment, or axlGetAllAttachments function. The attachment revision number and the attachment data may both be modified.

数据格式由 `dataFormat` 属性结构确定，用户可以设置该属性。如果 `"dataFormat"` 为 `'string`，则 `data` 属性的值用作新的附件数据。如果 `"dataFormat"` 为 `'file`，则 `data` 属性的值是读取附件数据的文件名。

**Original**: Format of the data is determined by the dataFormat attribute structure, which may be set by the user. If "dataFormat" is 'string, then the value of the data attribute is used for the new attachment data. If "dataFormat" is 'file, then the value of the data attribute is a file name from which the attachment data is read.

如果现有附件受密码保护，您必须提供正确的密码，否则函数将失败。

**Original**: If the existing attachment is password protected, you must provide the correct password or the function fails.

**语法**：
```skill
axlSetAttachment(
  o_attachment
  [t_password]
)
```

**参数**：

- `o_attachment`: 要修改的现有附件的 AXL ID。用户可以设置 `revision`、`dataFormat` 和 `data` 属性为新值。

**Original**: AXL id of the existing attachment to be modified. The revision, dataFormat, and data attributes may all be set to new values by the user.

- `t_password`: 给定现有附件的密码。如果与现有附件的密码不匹配，则附件更新失败。如果现有附件未受密码保护，可以省略此参数。

**Original**: Password for the given existing attachment. If this does not match the password of the existing attribute, the attachment update fails. If the existing attachment is not password protected, you may omit this.

**返回值**：

- `o_attachment`: 修改后的附件的 AXL ID。

**Original**: AXL id of the modified attachment.

- `nil`: 未能修改附件。

**Original**: Failed to modify the attachment.

一旦附件受密码保护，要移除或更改密码保护，您必须删除然后重新添加该附件。

**Original**: Once an attachment is password protected, to remove or change the password protection you must delete and then re-add the attachment.

**另请参阅 (See Also)**：`axlGetAttachment`

**Original**: See Also `axlGetAttachment`

---

