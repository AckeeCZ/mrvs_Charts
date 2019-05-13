//
//  ChartMarker.swift
//  Charts
//
//  Copyright 2015 Daniel Cohen Gindi & Philipp Jahoda
//  A port of MPAndroidChart for iOS
//  Licensed under Apache License 2.0
//
//  https://github.com/danielgindi/Charts
//

import Foundation
import CoreGraphics

@objc(IChartMarker)
public protocol IMarker: class
{
    /// - Returns: The desired (general) offset you wish the IMarker to have on the x-axis.
    /// By returning x: -(width / 2) you will center the IMarker horizontally.
    /// By returning y: -(height / 2) you will center the IMarker vertically.
    var offset: CGPoint { get }
    
    /// - Parameters:
    ///   - point: This is the point at which the marker wants to be drawn. You can adjust the offset conditionally based on this argument.
    /// - Returns: The offset for drawing at the specific `point`.
    ///            This allows conditional adjusting of the Marker position.
    ///            If you have no adjustments to make, return self.offset().
    func offsetForDrawing(atPoint: CGPoint) -> CGPoint
    
    /// This method enables a custom IMarker to update it's content every time the IMarker is redrawn according to the data entry it points to.
    ///
    /// - Parameters:
    ///   - entry: The Entry the IMarker belongs to. This can also be any subclass of Entry, like BarEntry or CandleEntry, simply cast it at runtime.
    ///   - highlight: The highlight object contains information about the highlighted value such as it's dataset-index, the selected range or stack-index (only stacked bar entries).
    func refreshContent(entry: ChartDataEntry, highlight: Highlight)
    
    /// Draws the IMarker on the given position on the given context
    func draw(context: CGContext, point: CGPoint)
}

enum DateFormatters {
    static let noTimeFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.locale = .current
        formatter.dateStyle = .medium
        formatter.timeStyle = .none

        return formatter
    }()

    static let noDateFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.locale = .current
        formatter.dateStyle = .none
        formatter.timeStyle = .medium

        return formatter
    }()
}

/**
 * View that can be displayed when selecting values in the chart. Displays the value on the X-axis
 * formatted with [formatter].
 */

public class TooltipMarkerView: IMarker {
    public var chart: ChartViewBase
    public var formatter: IAxisValueFormatter
    public var offset: CGPoint = CGPoint()
    public var xValue: Double = 0.0
    //    var horizontalPadding: Int


    public init(chart: ChartViewBase, formatter: IAxisValueFormatter) {
        self.chart = chart
        self.formatter = formatter
        //        self.offset =
        //        let transformer = Transformer.pointValuesToPixel(f)
        //        horizontalPadding = transformer.
    }

    func getOffset() -> CGPoint? {
        let height = chart.viewPortHandler?.chartHeight
        let offset = CGPoint(x: 0.0, y: height ?? 0.0)

        return offset
    }

    public func offsetForDrawing(atPoint: CGPoint) -> CGPoint {
        return offset
    }

    public func refreshContent(entry: ChartDataEntry, highlight: Highlight) {
        xValue = highlight.x
    }

    public func draw(context: CGContext, point: CGPoint) {

        var offset = getOffset

        let transformer = Transformer(viewPortHandler: chart.viewPortHandler)

        let text = stringForValue(xValue)
        let attributes: [NSAttributedString.Key : Any] = [
            .font: UIFont.systemFont(ofSize: 12.0),
            .foregroundColor: UIColor.black
        ]

        let atributedStrig = NSAttributedString(string: text, attributes: attributes)

        let yPos = chart.viewPortHandler.contentHeight
        let rectangleWidth = CGFloat(90.0)

        // Create Rectangle
        let rect = CGRect(x: point.x - rectangleWidth/2, y: yPos, width: rectangleWidth, height: 35)
        context.addRect(rect)
        context.setFillColor(UIColor.white.cgColor)
        context.setStrokeColor(UIColor.black.cgColor)
        context.drawPath(using: .fillStroke)

        //atributedStrig.draw(in: rect)

        text.drawVerticallyCentered(in: rect, withAttributes: attributes)
    }

    func stringForValue(_ value: Double) -> String {
        return xAxisDateNoTimeString(value) + "\n" + xAxisTimeNoDateString(value)
    }

    func xAxisDateNoTimeString(_ value: Double) -> String {
        let date = Date(timeIntervalSince1970: value)

        return DateFormatters.noTimeFormatter.string(from: date)
    }

    func xAxisTimeNoDateString(_ value: Double) -> String {
        let date = Date(timeIntervalSince1970: value)

        return DateFormatters.noDateFormatter.string(from: date)
    }
}

extension String {
    func drawVerticallyCentered(in rect: CGRect, withAttributes attributes: [NSAttributedString.Key : Any]? = nil) {
        let size = self.size(withAttributes: attributes)
        let centeredRect = CGRect(x: rect.origin.x + (rect.size.width-size.width)/2.0, y: rect.origin.y + (rect.size.height-size.height)/2.0, width: rect.size.width, height: size.height)
        self.draw(in: centeredRect, withAttributes: attributes)
    }
}
//var positionStart = CGPoint(x: region.start, y: 0.0)
//var positionEnd = CGPoint(x: region.end, y: 0.0)
//transformer?.pointValueToPixel(&positionStart)
//transformer?.pointValueToPixel(&positionEnd)
//
//// Create Rectangle
//let rect = CGRect(x: positionStart.x, y: 0, width: positionEnd.x-positionStart.x, height: viewPortHandler.contentHeight+50)
//context.addRect(rect)
//context.setFillColor(region.weekendColor)
//context.drawPath(using: .fill)
