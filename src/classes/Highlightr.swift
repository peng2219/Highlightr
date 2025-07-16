//
//  Highlightr.swift
//  Pods
//
//  Created by Illanes, J.P. on 4/10/16.
//
//

import Foundation
import JavaScriptCore

#if os(OSX)
    import AppKit
#endif

/// 语言检测和高亮结果的结构体
/// Contains the result of automatic language detection and highlighting
public struct HighlightResult {
    /// 检测到的语言名称
    /// The detected language name
    public let language: String
    
    /// 检测相关性评分 (0-1)
    /// The relevance score for the detected language (0-1)
    public let relevance: Double
    
    /// 高亮后的富文本
    /// The highlighted attributed string
    public let attributedString: NSAttributedString
    
    /// 原始代码
    /// The original code
    public let originalCode: String
    
    /// 初始化方法
    /// Initializer
    /// - Parameters:
    ///   - language: 检测到的语言名称
    ///   - relevance: 检测相关性评分
    ///   - attributedString: 高亮后的富文本
    ///   - originalCode: 原始代码
    public init(language: String, relevance: Double, attributedString: NSAttributedString, originalCode: String) {
        self.language = language
        self.relevance = relevance
        self.attributedString = attributedString
        self.originalCode = originalCode
    }
}

/// Utility class for generating a highlighted NSAttributedString from a String.
open class Highlightr
{
    /// Returns the current Theme.
    open var theme : Theme!
    {
        didSet
        {
            themeChanged?(theme)
        }
    }
    
    /// This block will be called every time the theme changes.
    open var themeChanged : ((Theme) -> Void)?

    /// Defaults to `false` - when `true`, forces highlighting to finish even if illegal syntax is detected.
    open var ignoreIllegals = false

    private let hljs: JSValue

    private let bundle : Bundle
    private let htmlStart = "<"
    private let spanStart = "span class=\""
    private let spanStartClose = "\">"
    private let spanEnd = "/span>"
    private let htmlEscape = try! NSRegularExpression(pattern: "&#?[a-zA-Z0-9]+?;", options: .caseInsensitive)
    
    /**
     Default init method.

     - parameter highlightPath: The path to `highlight.min.js`. Defaults to `Highlightr.framework/highlight.min.js`

     - returns: Highlightr instance.
     */
    public init?(highlightPath: String? = nil)
    {
        guard let jsContext = JSContext() else { return nil }
        let window = JSValue(newObjectIn: jsContext)

        #if SWIFT_PACKAGE
        let bundle = Bundle.module
        #else
        let bundle = Bundle(for: Highlightr.self)
        #endif
        self.bundle = bundle
        guard let hgPath = highlightPath ?? bundle.path(forResource: "highlight.min", ofType: "js") else
        {
            return nil
        }
        
        guard let hgJs = try? String.init(contentsOfFile: hgPath) else { return nil }
        let value = jsContext.evaluateScript(hgJs)
        guard let hljs = jsContext.objectForKeyedSubscript("hljs") else { return nil }

        self.hljs = hljs
        
        guard setTheme(to: "pojoaque") else
        {
            return nil
        }
        
    }
    
    /**
     Set the theme to use for highlighting.
     
     - parameter to: Theme name
     
     - returns: true if it was possible to set the given theme, false otherwise
     */
    @discardableResult
    open func setTheme(to name: String) -> Bool
    {
        guard let defTheme = bundle.path(forResource: name+".min", ofType: "css") else
        {
            return false
        }
        guard let themeString = try? String.init(contentsOfFile: defTheme) else { return false }
        theme =  Theme(themeString: themeString)

        
        return true
    }
    
    /**
     Takes a String and returns a NSAttributedString with the given language highlighted.
     
     - parameter code:           Code to highlight.
     - parameter languageName:   Language name or alias. Set to `nil` to use auto detection.
     - parameter fastRender:     Defaults to true - When *true* will use the custom made html parser rather than Apple's solution.
     
     - returns: NSAttributedString with the detected code highlighted.
     */
    open func highlight(_ code: String, as languageName: String? = nil, fastRender: Bool = true) -> NSAttributedString?
    {
        let ret: JSValue?
        if let languageName = languageName
        {
            let result: JSValue = hljs.invokeMethod("highlight", withArguments: [languageName, code, ignoreIllegals])
			 if result.isUndefined {
				// If highlighting failed, use highlightAuto
				ret = hljs.invokeMethod("highlightAuto", withArguments: [code])
			} else {
				ret = result
			}
        }else
        {
            // language auto detection
            ret = hljs.invokeMethod("highlightAuto", withArguments: [code])
        }

        guard let res = ret?.objectForKeyedSubscript("value"), var string = res.toString() else
        {
            return nil
        }
        
        var returnString : NSAttributedString?
        if(fastRender)
        {
            returnString = processHTMLString(string)
        }else
        {
            string = "<style>"+theme.lightTheme+"</style><pre><code class=\"hljs\">"+string+"</code></pre>"
            let opt: [NSAttributedString.DocumentReadingOptionKey : Any] = [
             .documentType: NSAttributedString.DocumentType.html,
             .characterEncoding: String.Encoding.utf8.rawValue
             ]
            
            guard let data = string.data(using: String.Encoding.utf8) else { return nil }
            safeMainSync
            {
                returnString = try? NSMutableAttributedString(data:data, options: opt, documentAttributes:nil)
            }
        }
        
        return returnString
    }
    
    /**
     使用自动语言检测进行代码高亮，返回完整的检测结果
     Highlights code using automatic language detection and returns complete detection results.
     
     - parameter code:           要高亮的代码 / Code to highlight.
     - parameter fastRender:     默认为 true - 当为 true 时将使用自定义的 HTML 解析器而不是 Apple 的解决方案 / Defaults to true - When *true* will use the custom made html parser rather than Apple's solution.
     
     - returns: HighlightResult 包含检测到的语言、相关性评分和高亮后的富文本 / HighlightResult containing detected language, relevance score and highlighted attributed string.
     */
    open func highlightAuto(_ code: String, fastRender: Bool = true) -> HighlightResult?
    {
        // 调用 JavaScript 的 hljs.highlightAuto() 方法
        // Call JavaScript hljs.highlightAuto() method
        let ret: JSValue = hljs.invokeMethod("highlightAuto", withArguments: [code])
        
        // 检查返回值是否有效
        // Check if the return value is valid
        guard !ret.isUndefined else {
            return nil
        }
        
        // 获取高亮后的 HTML 代码
        // Get the highlighted HTML code
        guard let valueObj = ret.objectForKeyedSubscript("value"), 
              var htmlString = valueObj.toString() else {
            return nil
        }
        
        // 获取检测到的语言
        // Get the detected language
        let detectedLanguage: String
        if let languageObj = ret.objectForKeyedSubscript("language"),
           let language = languageObj.toString() {
            detectedLanguage = language
        } else {
            detectedLanguage = "unknown"
        }
        
        // 获取相关性评分
        // Get the relevance score
        let relevanceScore: Double
        if let relevanceObj = ret.objectForKeyedSubscript("relevance"),
           let relevance = relevanceObj.toNumber() {
            relevanceScore = relevance.doubleValue
        } else {
            relevanceScore = 0.0
        }
        
        // 将 HTML 字符串转换为 NSAttributedString
        // Convert HTML string to NSAttributedString
        var attributedString: NSAttributedString?
        if fastRender {
            attributedString = processHTMLString(htmlString)
        } else {
            htmlString = "<style>"+theme.lightTheme+"</style><pre><code class=\"hljs\">"+htmlString+"</code></pre>"
            let opt: [NSAttributedString.DocumentReadingOptionKey : Any] = [
                .documentType: NSAttributedString.DocumentType.html,
                .characterEncoding: String.Encoding.utf8.rawValue
            ]
            
            guard let data = htmlString.data(using: String.Encoding.utf8) else { return nil }
            safeMainSync {
                attributedString = try? NSMutableAttributedString(data: data, options: opt, documentAttributes: nil)
            }
        }
        
        // 确保 attributedString 不为空
        // Ensure attributedString is not nil
        guard let finalAttributedString = attributedString else {
            return nil
        }
        
        // 返回完整的检测结果
        // Return the complete detection result
        return HighlightResult(
            language: detectedLanguage,
            relevance: relevanceScore,
            attributedString: finalAttributedString,
            originalCode: code
        )
    }
    
    /**
     Returns a list of all the available themes.
     
     - returns: Array of Strings
     */
    open func availableThemes() -> [String]
    {
        let paths = bundle.paths(forResourcesOfType: "css", inDirectory: nil) as [NSString]
        var result = [String]()
        for path in paths {
            result.append(path.lastPathComponent.replacingOccurrences(of: ".min.css", with: ""))
        }
        
        return result
    }
    
    /**
     Returns a list of all supported languages.
     
     - returns: Array of Strings
     */
    open func supportedLanguages() -> [String]
    {
        let res = hljs.invokeMethod("listLanguages", withArguments: [])
        return (res?.toArray() as? [String]) ?? []
    }
    
    /**
     Execute the provided block in the main thread synchronously.
     */
    private func safeMainSync(_ block: @escaping ()->())
    {
        if Thread.isMainThread
        {
            block()
        }else
        {
            DispatchQueue.main.sync { block() }
        }
    }
    
    private func processHTMLString(_ string: String) -> NSAttributedString?
    {
        let scanner = Scanner(string: string)
        scanner.charactersToBeSkipped = nil
        var scannedString: NSString?
        let resultString = NSMutableAttributedString(string: "")
        var propStack = ["hljs"]
        
        while !scanner.isAtEnd
        {
            var ended = false
            if scanner.scanUpTo(htmlStart, into: &scannedString)
            {
                if scanner.isAtEnd
                {
                    ended = true
                }
            }
            
            if scannedString != nil && scannedString!.length > 0 {
                let attrScannedString = theme.applyStyleToString(scannedString! as String, styleList: propStack)
                resultString.append(attrScannedString)
                if ended
                {
                    continue
                }
            }
            
            scanner.scanLocation += 1
            
            let string = scanner.string as NSString
            let nextChar = string.substring(with: NSMakeRange(scanner.scanLocation, 1))
            if(nextChar == "s")
            {
                scanner.scanLocation += (spanStart as NSString).length
                scanner.scanUpTo(spanStartClose, into:&scannedString)
                scanner.scanLocation += (spanStartClose as NSString).length
                propStack.append(scannedString! as String)
            }
            else if(nextChar == "/")
            {
                scanner.scanLocation += (spanEnd as NSString).length
                propStack.removeLast()
            }else
            {
                let attrScannedString = theme.applyStyleToString("<", styleList: propStack)
                resultString.append(attrScannedString)
                scanner.scanLocation += 1
            }
            
            scannedString = nil
        }
        
        let results = htmlEscape.matches(in: resultString.string,
                                               options: [.reportCompletion],
                                               range: NSMakeRange(0, resultString.length))
        var locOffset = 0
        for result in results
        {
            let fixedRange = NSMakeRange(result.range.location-locOffset, result.range.length)
            let entity = (resultString.string as NSString).substring(with: fixedRange)
            if let decodedEntity = HTMLUtils.decode(entity)
            {
                resultString.replaceCharacters(in: fixedRange, with: String(decodedEntity))
                locOffset += result.range.length-1;
            }
            

        }

        return resultString
    }
    
}
