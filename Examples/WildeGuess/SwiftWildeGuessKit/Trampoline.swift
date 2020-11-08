/* This file provided by Facebook is for non-commercial testing and evaluation
 * purposes only.  Facebook reserves all rights not expressly granted.
 *
 * THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
 * IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
 * FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL
 * FACEBOOK BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN
 * ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN
 * CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.
 */

import Foundation
import UIKit
import CKSwift
import CKTextSwift
import ComponentKit

#if swift(>=5.3)
@ComponentBuilder public func SwiftQuoteComponent(from quote: Quote) -> Component {
  SwiftInteractiveWrapperQuoteView(quote: quote, context: QuoteContext.shared)
}

@objc public class Trampoline : NSObject {
   @objc public class func component(text: String, author: String, style: Int) -> Component {
    SwiftQuoteComponent(from: Quote(text: text, author: author, style: Quote.Style(value: style)))
   }
}

#else
@objc public class Trampoline : NSObject {
   @objc public class func component(text: String, author: String, style: Int) -> Component {
    return FlexboxComponent(
        view: ViewConfiguration(viewClass: UISwitch.self, attributes: { () -> [ComponentViewAttributeSwiftBridge] in
            return [
                ComponentViewAttributeSwiftBridge(
                    identifier: "isOn",
                    applicator: { (view) in
                        guard let uiswitch = view as? UISwitch else {
                            return
                        }
                        uiswitch.isOn = true
                })
            ]
        }),
        size: ComponentSize(width: 100, height: 50))
   }
}

#endif
