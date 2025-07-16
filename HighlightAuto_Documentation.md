# Highlightr 增强功能：自动语言检测与高亮

## 概述 / Overview

本文档介绍了 Highlightr 库中新增的 `highlightAuto` 方法，该方法不仅能够对代码进行语法高亮，还能返回详细的语言检测信息。

This document describes the newly added `highlightAuto` method in the Highlightr library, which not only provides syntax highlighting but also returns detailed language detection information.

## 新增功能 / New Features

### 1. HighlightResult 结构体 / HighlightResult Structure

```swift
public struct HighlightResult {
    /// 检测到的语言名称 / The detected language name
    public let language: String
    
    /// 检测相关性评分 (0-1) / The relevance score for the detected language (0-1)
    public let relevance: Double
    
    /// 高亮后的富文本 / The highlighted attributed string
    public let attributedString: NSAttributedString
    
    /// 原始代码 / The original code
    public let originalCode: String
}
```

### 2. highlightAuto 方法 / highlightAuto Method

```swift
open func highlightAuto(_ code: String, fastRender: Bool = true) -> HighlightResult?
```

## 使用方法 / Usage

### 基本用法 / Basic Usage

```swift
import Highlightr

// 创建 Highlightr 实例
guard let highlightr = Highlightr() else { return }

// 要高亮的代码
let code = """
function fibonacci(n) {
    if (n <= 1) return n;
    return fibonacci(n - 1) + fibonacci(n - 2);
}
"""

// 使用 highlightAuto 方法
if let result = highlightr.highlightAuto(code) {
    print("检测到的语言: \(result.language)")
    print("相关性评分: \(result.relevance)")
    // 使用高亮后的 NSAttributedString
    textView.attributedText = result.attributedString
}
```

### 高级用法 / Advanced Usage

```swift
// 批量处理多个代码片段
let codeSnippets = [
    "console.log('Hello, World!');",
    "print('Hello, World!')",
    "println!(\"Hello, World!\");"
]

for snippet in codeSnippets {
    if let result = highlightr.highlightAuto(snippet) {
        print("代码: \(snippet)")
        print("语言: \(result.language) (置信度: \(result.relevance))")
        print("---")
    }
}
```

## 方法参数 / Method Parameters

### highlightAuto 方法参数 / highlightAuto Method Parameters

| 参数 / Parameter | 类型 / Type | 默认值 / Default | 说明 / Description |
|------------------|-------------|------------------|-------------------|
| `code` | `String` | 必需 / Required | 要进行高亮的代码字符串 / Code string to highlight |
| `fastRender` | `Bool` | `true` | 是否使用快速渲染模式 / Whether to use fast rendering mode |

## 返回值详解 / Return Value Details

### HighlightResult 属性 / HighlightResult Properties

| 属性 / Property | 类型 / Type | 说明 / Description |
|-----------------|-------------|-------------------|
| `language` | `String` | 检测到的编程语言名称（如 "javascript", "python", "swift"） / Detected programming language name |
| `relevance` | `Double` | 语言检测的相关性评分，范围 0.0-1.0，值越高表示检测越准确 / Relevance score for language detection, range 0.0-1.0 |
| `attributedString` | `NSAttributedString` | 经过语法高亮处理的富文本 / Syntax-highlighted attributed string |
| `originalCode` | `String` | 原始输入的代码字符串 / Original input code string |

## 支持的语言 / Supported Languages

此方法支持 highlight.js 支持的所有语言，包括但不限于：
This method supports all languages supported by highlight.js, including but not limited to:

- JavaScript
- Python
- Swift
- Java
- C/C++
- C#
- Go
- Rust
- TypeScript
- PHP
- Ruby
- Kotlin
- Scala
- HTML
- CSS
- SQL
- JSON
- XML
- Markdown
- Shell/Bash
- 以及更多... / And many more...

## 性能特性 / Performance Features

### 快速渲染模式 / Fast Rendering Mode

- **启用** (`fastRender: true`)：使用自定义 HTML 解析器，性能更佳
- **禁用** (`fastRender: false`)：使用系统 NSAttributedString HTML 解析器，兼容性更好

### 内存管理 / Memory Management

- 所有返回的对象都是不可变的，确保线程安全
- 自动处理 JavaScript 上下文的内存管理
- 支持 ARC（自动引用计数）

## 错误处理 / Error Handling

方法在以下情况下会返回 `nil`：
The method returns `nil` in the following cases:

1. JavaScript 执行环境出错 / JavaScript execution environment error
2. 输入代码为空或无效 / Input code is empty or invalid
3. HTML 到 NSAttributedString 转换失败 / HTML to NSAttributedString conversion failed

```swift
// 推荐的错误处理方式
if let result = highlightr.highlightAuto(code) {
    // 成功处理
    processHighlightResult(result)
} else {
    // 错误处理
    print("代码高亮失败")
    // 可以使用原始代码作为后备方案
    textView.text = code
}
```

## 最佳实践 / Best Practices

### 1. 性能优化 / Performance Optimization

```swift
// 对于长代码，考虑在后台线程处理
DispatchQueue.global(qos: .userInitiated).async {
    if let result = highlightr.highlightAuto(longCode) {
        DispatchQueue.main.async {
            textView.attributedText = result.attributedString
        }
    }
}
```

### 2. 语言检测准确性 / Language Detection Accuracy

```swift
// 检查相关性评分来判断检测准确性
if let result = highlightr.highlightAuto(code) {
    if result.relevance > 0.5 {
        print("高置信度检测：\(result.language)")
    } else {
        print("低置信度检测：\(result.language)，可能不准确")
    }
}
```

### 3. 缓存策略 / Caching Strategy

```swift
// 对于重复的代码片段，考虑缓存结果
private var highlightCache: [String: HighlightResult] = [:]

func highlightWithCache(_ code: String) -> HighlightResult? {
    if let cached = highlightCache[code] {
        return cached
    }
    
    if let result = highlightr.highlightAuto(code) {
        highlightCache[code] = result
        return result
    }
    
    return nil
}
```

## 示例应用 / Example Applications

### 1. 代码编辑器 / Code Editor

```swift
class CodeEditorViewController: UIViewController {
    @IBOutlet weak var textView: UITextView!
    private let highlightr = Highlightr()
    
    func highlightCurrentCode() {
        guard let code = textView.text else { return }
        
        if let result = highlightr?.highlightAuto(code) {
            textView.attributedText = result.attributedString
            updateLanguageIndicator(result.language)
        }
    }
    
    private func updateLanguageIndicator(_ language: String) {
        // 更新语言指示器
        title = "编辑器 - \(language.capitalized)"
    }
}
```

### 2. 代码片段查看器 / Code Snippet Viewer

```swift
class CodeSnippetCell: UITableViewCell {
    @IBOutlet weak var codeTextView: UITextView!
    @IBOutlet weak var languageLabel: UILabel!
    @IBOutlet weak var confidenceLabel: UILabel!
    
    func configure(with code: String, highlightr: Highlightr) {
        if let result = highlightr.highlightAuto(code) {
            codeTextView.attributedText = result.attributedString
            languageLabel.text = result.language.capitalized
            confidenceLabel.text = String(format: "%.1f%%", result.relevance * 100)
        }
    }
}
```

## 与原有方法的比较 / Comparison with Original Methods

| 特性 / Feature | `highlight()` | `highlightAuto()` |
|----------------|---------------|-------------------|
| 语言检测 / Language Detection | ❌ | ✅ |
| 相关性评分 / Relevance Score | ❌ | ✅ |
| 原始代码保留 / Original Code Retention | ❌ | ✅ |
| 指定语言高亮 / Specific Language Highlighting | ✅ | ❌ |
| 返回类型 / Return Type | `NSAttributedString?` | `HighlightResult?` |

## 版本兼容性 / Version Compatibility

- iOS 9.0+
- macOS 10.11+
- tvOS 9.0+
- watchOS 2.0+
- Swift 5.0+

## 更新日志 / Change Log

### 版本 1.0.0 (2025-07-16)
- ✅ 添加 `HighlightResult` 结构体
- ✅ 添加 `highlightAuto` 方法
- ✅ 支持语言检测和相关性评分
- ✅ 完整的中英文文档
- ✅ 全面的测试用例

---

## 技术支持 / Technical Support

如果您在使用过程中遇到任何问题，请：
If you encounter any issues while using this feature, please:

1. 检查代码是否符合预期格式 / Check if the code is in the expected format
2. 验证 Highlightr 实例是否正确初始化 / Verify that the Highlightr instance is properly initialized
3. 查看控制台输出的错误信息 / Check console output for error messages
4. 参考本文档的最佳实践部分 / Refer to the best practices section of this document

---

*文档最后更新时间：2025年07月16日 18:02*
*Document last updated: July 16, 2025 18:02* 