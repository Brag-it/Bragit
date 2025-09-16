import UIKit

public class CenteredCodeTextField: UITextField {
  public var fixedCharacterCount: Int = 6 {
    didSet {
      setNeedsLayout()
      setNeedsDisplay()
    }
  }

  public var horizontalPadding: CGFloat = 0 {
    didSet {
      setNeedsLayout()
      setNeedsDisplay()
    }
  }

  private func centeredFixedWidthRect(in bounds: CGRect) -> CGRect {
    let baseRect = super.textRect(forBounds: bounds)

    let fontToUse = font ?? UIFont.systemFont(ofSize: 17)
    let zeroString = String(repeating: "0", count: fixedCharacterCount)
    let attributes: [NSAttributedString.Key: Any] = [.font: fontToUse]
    let size = zeroString.size(withAttributes: attributes)

    let totalWidth = size.width + horizontalPadding * 2
    let originX = bounds.midX - totalWidth / 2

    return CGRect(x: originX, y: baseRect.origin.y, width: totalWidth, height: baseRect.height)
  }

  public override func textRect(forBounds bounds: CGRect) -> CGRect {
    return centeredFixedWidthRect(in: bounds)
  }

  public override func editingRect(forBounds bounds: CGRect) -> CGRect {
    return centeredFixedWidthRect(in: bounds)
  }

  public override func placeholderRect(forBounds bounds: CGRect) -> CGRect {
    return centeredFixedWidthRect(in: bounds)
  }

  public override func layoutSubviews() {
    super.layoutSubviews()
    textAlignment = .left
  }
}
