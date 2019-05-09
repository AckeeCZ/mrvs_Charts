//
//  XAxisRenderer.swift
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


extension Date {
    public func toLocalTime() -> Date {
        let timezone = TimeZone.current
        let seconds = TimeInterval(timezone.secondsFromGMT(for: self))
        return Date(timeInterval: seconds, since: self)
    }
}

@objc(ChartXAxisRenderer)
open class XAxisRenderer: AxisRendererBase
{

    public class constant {
        static let HOURS_DIVIDERS = [12, 6, 4, 3, 2, 1]
        static let MINUTES_DIVIDERS = [30, 20, 15, 10, 5, 3, 2, 1]
        static let SECONDS_DIVIDERS = [30, 20, 15, 10, 5, 3, 2, 1]
    }

    public var daysComponent = DateComponents()
    public var hoursComponent = DateComponents()
    public var minutesComponent = DateComponents()
    public var secondsComponent = DateComponents()


    @objc public init(viewPortHandler: ViewPortHandler, xAxis: XAxis?, transformer: Transformer?)
    {
        super.init(viewPortHandler: viewPortHandler, transformer: transformer, axis: xAxis)
    }
    
    open override func computeAxis(min: Double, max: Double, inverted: Bool)
    {
        var min = min, max = max

        if let transformer = self.transformer
        {
            // calculate the starting and entry point of the y-labels (depending on
            // zoom / contentrect bounds)
            if viewPortHandler.contentWidth > 10 && !viewPortHandler.isFullyZoomedOutX
            {
                let p1 = transformer.valueForTouchPoint(CGPoint(x: viewPortHandler.contentLeft, y: viewPortHandler.contentTop))
                let p2 = transformer.valueForTouchPoint(CGPoint(x: viewPortHandler.contentRight, y: viewPortHandler.contentTop))

                if inverted
                {
                    min = Double(p2.x)
                    max = Double(p1.x)
                }
                else
                {
                    min = Double(p1.x)
                    max = Double(p2.x)
                }
            }
        }

        computeAxisValues(min: min, max: max)
    }

    open override func computeAxisValues(min: Double, max: Double)
    {
        guard let xAxis = self.axis as? XAxis else { return }
        /*
         Custom values compute. Aimed to show reasonable time intervals with round values.
         */
        let minSeconds = min
        let maxSeconds = max
        var entries = [Double]()
        let labelCount = xAxis.labelCount
        let minInstant = Date(timeIntervalSinceNow: minSeconds)
        let maxInstant = Date(timeIntervalSinceNow: maxSeconds)

        let calendar = Calendar.current
        let daysBetweenDays = calendar.dateComponents([.day], from: minInstant, to: maxInstant).day ?? 1
        let daysInInterval = daysBetweenDays + 1 // plus today
        let hoursInInterval = calendar.dateComponents([.hour], from: minInstant, to: maxInstant).hour ?? 1
        let minutesInInterval = calendar.dateComponents([.minute], from: minInstant, to: maxInstant).minute ?? 1
        let secondsInInterval = calendar.dateComponents([.second], from: minInstant, to: maxInstant).second ?? 1
        let zone = calendar.timeZone

        if daysInInterval >= labelCount {
            // define static granularity as factor of days count in a month to prevent labels jumping when scrolling through days
            let daysGranularity = daysInInterval / labelCount
            let daysGranulatiryInSeconds = Double(daysGranularity * 86400)

            let date = Date(timeIntervalSince1970: minSeconds)
            let startOfDayInSeconds = calendar.startOfDay(for: date).timeIntervalSince1970

            let dayOfYear = calendar.ordinality(of: .day, in: .year, for: date) ?? 1
            let plusDays = Int(ceil(Double(dayOfYear) / Double(daysGranularity))) * daysGranularity - dayOfYear

            var dayToShow = startOfDayInSeconds + Double(plusDays * 86400)

            while dayToShow < maxSeconds {
                entries.append(dayToShow)
                dayToShow = dayToShow + daysGranulatiryInSeconds
            }
        } else if hoursInInterval >= labelCount {
            // define static granularity as factor of hours count in a day to prevent labels jumping when scrolling through hours
            let hoursGranularity = constant.HOURS_DIVIDERS.first { hoursInInterval / labelCount >= $0 } ?? 1
            let hoursGranularityInSeconds = Double(hoursGranularity * 3600)

            let date = Date(timeIntervalSince1970: minSeconds)
            let hour = calendar.component(.hour, from: date)
            let zeroDate = calendar.date(bySettingHour: hour, minute: 0, second: 0, of: date)!
            let zeroDateInSeconds = zeroDate.timeIntervalSince1970

            let plusHours = Int(ceil(Double(hour) / Double(hoursGranularity))) * hoursGranularity - hour

            var hourToShow = zeroDateInSeconds + Double(plusHours)

            while hourToShow < maxSeconds {
                entries.append(hourToShow)
                hourToShow = hourToShow + hoursGranularityInSeconds
            }
        } else if minutesInInterval >= labelCount {
            // define static granularity as factor of minutes count in an hour to prevent labels jumping when scrolling through hours
            let minutesGranularity = constant.MINUTES_DIVIDERS.first { minutesInInterval / labelCount >= $0 } ?? 1
            let minutesGranularityInSeconds = Double(minutesGranularity * 60)

            let date = Date(timeIntervalSince1970: minSeconds)
            let hour = calendar.component(.hour, from: date)
            let minute = calendar.component(.minute, from: date)
            let zeroDate = calendar.date(bySettingHour: hour, minute: minute, second: 0, of: date)!
            let zeroDateInSeconds = zeroDate.timeIntervalSince1970

            let plusMinutes = Int(ceil(Double(minute) / Double(minutesGranularity))) * minutesGranularity - minute

            var minuteToShow = zeroDateInSeconds + Double(plusMinutes)

            while minuteToShow < maxSeconds {
                entries.append(minuteToShow)
                minuteToShow = minuteToShow + minutesGranularityInSeconds
            }
        } else {
            // define static granularity as factor of seconds count in a minute to prevent labels jumping when scrolling through hours
            let secondsGranularity = constant.SECONDS_DIVIDERS.first { secondsInInterval / labelCount >= $0 } ?? 1

            let date = Date(timeIntervalSince1970: minSeconds)
            let second = calendar.component(.second, from: date)

            let plusSeconds = Int(ceil(Double(second) / Double(secondsGranularity))) * secondsGranularity - second

            secondsComponent.second = plusSeconds

            var secondToShow = calendar.date(byAdding: secondsComponent, to: date)!

            var secondToShow = second + Double(plusSeconds)

            while secondToShow < maxInstant {
                entries.append(secondToShow.timeIntervalSince1970)
                secondsComponent.second = secondsGranularity
                secondToShow = calendar.date(byAdding: secondsComponent, to: secondToShow)!
            }
        }

        xAxis.entries = entries

        computeSize()
    }
    
    @objc open func computeSize()
    {
        guard let
            xAxis = self.axis as? XAxis
            else { return }
        
        let longest = xAxis.getLongestLabel()
        
        let labelSize = longest.size(withAttributes: [NSAttributedString.Key.font: xAxis.labelFont])
        
        let labelWidth = labelSize.width
        let labelHeight = labelSize.height
        
        let labelRotatedSize = labelSize.rotatedBy(degrees: xAxis.labelRotationAngle)
        
        xAxis.labelWidth = labelWidth
        xAxis.labelHeight = labelHeight
        xAxis.labelRotatedWidth = labelRotatedSize.width
        xAxis.labelRotatedHeight = labelRotatedSize.height
    }

    public func computeRegions(min: Double, max: Double) {
        var regions = [Region]()

        let minDate = Date(timeIntervalSince1970: min)
        let maxDate = Date(timeIntervalSince1970: max)

        let calendar = Calendar.current

        // Replace the hour (time) of both dates with 00:00
        let date1 = calendar.startOfDay(for: minDate)
        let date2 = calendar.startOfDay(for: maxDate)
        let daysBetweenDays = calendar.dateComponents([.day], from: date1, to: date2).day ?? 1
        let numberOfDays = daysBetweenDays + 1 // plus today

        var today = date1
        var weekendDays = [Date]()

        for i in 1...numberOfDays {
            if calendar.isDateInWeekend(today) {
                weekendDays.append(today)
            }

            let tomorrow = calendar.date(byAdding: .day, value: 1, to: today)!
            today = tomorrow
        }

        weekendDays.forEach { date in
            let start = calendar.startOfDay(for: date)

            var components = DateComponents()
            components.day = 1
            components.second = -1
            let end = calendar.date(byAdding: components, to: start)!

            let region = Region(start: start.timeIntervalSince1970, end: end.timeIntervalSince1970)
            regions.append(region)
        }

        guard let xAxis = self.axis as? XAxis else { return }

        xAxis.regions = regions
    }

    public func renderRegions(context: CGContext) {
        guard let xAxis = self.axis as? XAxis else { return }

                xAxis.regions.forEach { region in
                    var positionStart = CGPoint(x: region.start, y: 0.0)
                    var positionEnd = CGPoint(x: region.end, y: 0.0)
                    transformer?.pointValueToPixel(&positionStart)
                    transformer?.pointValueToPixel(&positionEnd)

                    // Create Rectangle
                    let rect = CGRect(x: positionStart.x, y: 0, width: positionEnd.x-positionStart.x, height: viewPortHandler.contentHeight+50)
                    context.addRect(rect)
                    context.setFillColor(region.weekendColor)
                    context.drawPath(using: .fill)
                }
    }
    
    open override func renderAxisLabels(context: CGContext)
    {
        guard let xAxis = self.axis as? XAxis else { return }
        
        if !xAxis.isEnabled || !xAxis.isDrawLabelsEnabled
        {
            return
        }
        
        let yOffset = xAxis.yOffset
        
        if xAxis.labelPosition == .top
        {
            drawLabels(context: context, pos: viewPortHandler.contentTop - yOffset, anchor: CGPoint(x: 0.5, y: 1.0))
        }
        else if xAxis.labelPosition == .topInside
        {
            drawLabels(context: context, pos: viewPortHandler.contentTop + yOffset + xAxis.labelRotatedHeight, anchor: CGPoint(x: 0.5, y: 1.0))
        }
        else if xAxis.labelPosition == .bottom
        {
            drawLabels(context: context, pos: viewPortHandler.contentBottom + yOffset, anchor: CGPoint(x: 0.5, y: 0.0))
        }
        else if xAxis.labelPosition == .bottomInside
        {
            drawLabels(context: context, pos: viewPortHandler.contentBottom - yOffset - xAxis.labelRotatedHeight, anchor: CGPoint(x: 0.5, y: 0.0))
        }
        else
        { // BOTH SIDED
            drawLabels(context: context, pos: viewPortHandler.contentTop - yOffset, anchor: CGPoint(x: 0.5, y: 1.0))
            drawLabels(context: context, pos: viewPortHandler.contentBottom + yOffset, anchor: CGPoint(x: 0.5, y: 0.0))
        }
    }
    
    private var _axisLineSegmentsBuffer = [CGPoint](repeating: CGPoint(), count: 2)
    
    open override func renderAxisLine(context: CGContext)
    {
        guard let xAxis = self.axis as? XAxis else { return }
        
        if !xAxis.isEnabled || !xAxis.isDrawAxisLineEnabled
        {
            return
        }
        
        context.saveGState()
        
        context.setStrokeColor(xAxis.axisLineColor.cgColor)
        context.setLineWidth(xAxis.axisLineWidth)
        if xAxis.axisLineDashLengths != nil
        {
            context.setLineDash(phase: xAxis.axisLineDashPhase, lengths: xAxis.axisLineDashLengths)
        }
        else
        {
            context.setLineDash(phase: 0.0, lengths: [])
        }
        
        if xAxis.labelPosition == .top
            || xAxis.labelPosition == .topInside
            || xAxis.labelPosition == .bothSided
        {
            _axisLineSegmentsBuffer[0].x = viewPortHandler.contentLeft
            _axisLineSegmentsBuffer[0].y = viewPortHandler.contentTop
            _axisLineSegmentsBuffer[1].x = viewPortHandler.contentRight
            _axisLineSegmentsBuffer[1].y = viewPortHandler.contentTop
            context.strokeLineSegments(between: _axisLineSegmentsBuffer)
        }
        
        if xAxis.labelPosition == .bottom
            || xAxis.labelPosition == .bottomInside
            || xAxis.labelPosition == .bothSided
        {
            _axisLineSegmentsBuffer[0].x = viewPortHandler.contentLeft
            _axisLineSegmentsBuffer[0].y = viewPortHandler.contentBottom
            _axisLineSegmentsBuffer[1].x = viewPortHandler.contentRight
            _axisLineSegmentsBuffer[1].y = viewPortHandler.contentBottom
            context.strokeLineSegments(between: _axisLineSegmentsBuffer)
        }
        
        context.restoreGState()
    }
    
    /// draws the x-labels on the specified y-position
    @objc open func drawLabels(context: CGContext, pos: CGFloat, anchor: CGPoint)
    {
        guard
            let xAxis = self.axis as? XAxis,
            let transformer = self.transformer
            else { return }
        
        let paraStyle = NSParagraphStyle.default.mutableCopy() as! NSMutableParagraphStyle
        paraStyle.alignment = .center
        
        let labelAttrs: [NSAttributedString.Key : Any] = [
            .font: xAxis.labelFont,
            .foregroundColor: xAxis.labelTextColor,
            .paragraphStyle: paraStyle
        ]
        let labelRotationAngleRadians = xAxis.labelRotationAngle.DEG2RAD
        
        let centeringEnabled = xAxis.isCenterAxisLabelsEnabled

        let valueToPixelMatrix = transformer.valueToPixelMatrix
        
        var position = CGPoint(x: 0.0, y: 0.0)
        
        var labelMaxSize = CGSize()
        
        if xAxis.isWordWrapEnabled
        {
            labelMaxSize.width = xAxis.wordWrapWidthPercent * valueToPixelMatrix.a
        }
        
        let entries = xAxis.entries
        
        for i in stride(from: 0, to: entries.count, by: 1)
        {
            if centeringEnabled
            {
                position.x = CGFloat(xAxis.centeredEntries[i])
            }
            else
            {
                position.x = CGFloat(entries[i])
            }
            
            position.y = 0.0
            position = position.applying(valueToPixelMatrix)
            
            if viewPortHandler.isInBoundsX(position.x)
            {
                let label = xAxis.valueFormatter?.stringForValue(xAxis.entries[i], axis: xAxis) ?? ""

                let labelns = label as NSString
                
                if xAxis.isAvoidFirstLastClippingEnabled
                {
                    // avoid clipping of the last
                    if i == xAxis.entryCount - 1 && xAxis.entryCount > 1
                    {
                        let width = labelns.boundingRect(with: labelMaxSize, options: .usesLineFragmentOrigin, attributes: labelAttrs, context: nil).size.width
                        
                        if width > viewPortHandler.offsetRight * 2.0
                            && position.x + width > viewPortHandler.chartWidth
                        {
                            position.x -= width / 2.0
                        }
                    }
                    else if i == 0
                    { // avoid clipping of the first
                        let width = labelns.boundingRect(with: labelMaxSize, options: .usesLineFragmentOrigin, attributes: labelAttrs, context: nil).size.width
                        position.x += width / 2.0
                    }
                }
                
                drawLabel(context: context,
                          formattedLabel: label,
                          x: position.x,
                          y: pos,
                          attributes: labelAttrs,
                          constrainedToSize: labelMaxSize,
                          anchor: anchor,
                          angleRadians: labelRotationAngleRadians)
            }
        }
    }
    
    @objc open func drawLabel(
        context: CGContext,
        formattedLabel: String,
        x: CGFloat,
        y: CGFloat,
        attributes: [NSAttributedString.Key : Any],
        constrainedToSize: CGSize,
        anchor: CGPoint,
        angleRadians: CGFloat)
    {
        ChartUtils.drawMultilineText(
            context: context,
            text: formattedLabel,
            point: CGPoint(x: x, y: y),
            attributes: attributes,
            constrainedToSize: constrainedToSize,
            anchor: anchor,
            angleRadians: angleRadians)
    }
    
    open override func renderGridLines(context: CGContext)
    {
        guard
            let xAxis = self.axis as? XAxis,
            let transformer = self.transformer
            else { return }
        
        if !xAxis.isDrawGridLinesEnabled || !xAxis.isEnabled
        {
            return
        }
        
        context.saveGState()
        defer { context.restoreGState() }
        context.clip(to: self.gridClippingRect)
        
        context.setShouldAntialias(xAxis.gridAntialiasEnabled)
        context.setStrokeColor(xAxis.gridColor.cgColor)
        context.setLineWidth(xAxis.gridLineWidth)
        context.setLineCap(xAxis.gridLineCap)
        
        if xAxis.gridLineDashLengths != nil
        {
            context.setLineDash(phase: xAxis.gridLineDashPhase, lengths: xAxis.gridLineDashLengths)
        }
        else
        {
            context.setLineDash(phase: 0.0, lengths: [])
        }
        
        let valueToPixelMatrix = transformer.valueToPixelMatrix
        
        var position = CGPoint(x: 0.0, y: 0.0)
        
        let entries = xAxis.entries
        
        for i in stride(from: 0, to: entries.count, by: 1)
        {
            position.x = CGFloat(entries[i])
            position.y = position.x
            position = position.applying(valueToPixelMatrix)
            
            drawGridLine(context: context, x: position.x, y: position.y)
        }
    }
    
    @objc open var gridClippingRect: CGRect
    {
        var contentRect = viewPortHandler.contentRect
        let dx = self.axis?.gridLineWidth ?? 0.0
        contentRect.origin.x -= dx / 2.0
        contentRect.size.width += dx
        return contentRect
    }
    
    @objc open func drawGridLine(context: CGContext, x: CGFloat, y: CGFloat)
    {
        if x >= viewPortHandler.offsetLeft
            && x <= viewPortHandler.chartWidth
        {
            context.beginPath()
            context.move(to: CGPoint(x: x, y: viewPortHandler.contentTop))
            context.addLine(to: CGPoint(x: x, y: viewPortHandler.contentBottom))
            context.strokePath()
        }
    }
    
    open override func renderLimitLines(context: CGContext)
    {
        guard
            let xAxis = self.axis as? XAxis,
            let transformer = self.transformer,
            !xAxis.limitLines.isEmpty
            else { return }
        
        let trans = transformer.valueToPixelMatrix
        
        var position = CGPoint(x: 0.0, y: 0.0)
        
        for l in xAxis.limitLines where l.isEnabled
        {
            context.saveGState()
            defer { context.restoreGState() }
            
            var clippingRect = viewPortHandler.contentRect
            clippingRect.origin.x -= l.lineWidth / 2.0
            clippingRect.size.width += l.lineWidth
            context.clip(to: clippingRect)
            
            position.x = CGFloat(l.limit)
            position.y = 0.0
            position = position.applying(trans)
            
            renderLimitLineLine(context: context, limitLine: l, position: position)
            renderLimitLineLabel(context: context, limitLine: l, position: position, yOffset: 2.0 + l.yOffset)
        }
    }
    
    @objc open func renderLimitLineLine(context: CGContext, limitLine: ChartLimitLine, position: CGPoint)
    {
        
        context.beginPath()
        context.move(to: CGPoint(x: position.x, y: viewPortHandler.contentTop))
        context.addLine(to: CGPoint(x: position.x, y: viewPortHandler.contentBottom))
        
        context.setStrokeColor(limitLine.lineColor.cgColor)
        context.setLineWidth(limitLine.lineWidth)
        if limitLine.lineDashLengths != nil
        {
            context.setLineDash(phase: limitLine.lineDashPhase, lengths: limitLine.lineDashLengths!)
        }
        else
        {
            context.setLineDash(phase: 0.0, lengths: [])
        }
        
        context.strokePath()
    }
    
    @objc open func renderLimitLineLabel(context: CGContext, limitLine: ChartLimitLine, position: CGPoint, yOffset: CGFloat)
    {
        
        let label = limitLine.label
        guard limitLine.drawLabelEnabled, !label.isEmpty else { return }

        let labelLineHeight = limitLine.valueFont.lineHeight

        let xOffset: CGFloat = limitLine.lineWidth + limitLine.xOffset
        let attributes: [NSAttributedString.Key : Any] = [
            .font : limitLine.valueFont,
            .foregroundColor : limitLine.valueTextColor
        ]

        let (point, align): (CGPoint, NSTextAlignment)
        switch limitLine.labelPosition {
        case .topRight:
            point = CGPoint(
                x: position.x + xOffset,
                y: viewPortHandler.contentTop + yOffset
            )
            align = .left

        case .bottomRight:
            point = CGPoint(
                x: position.x + xOffset,
                y: viewPortHandler.contentBottom - labelLineHeight - yOffset
            )
            align = .left

        case .topLeft:
            point = CGPoint(
                x: position.x - xOffset,
                y: viewPortHandler.contentTop + yOffset
            )
            align = .right

        case .bottomLeft:
            point = CGPoint(
                x: position.x - xOffset,
                y: viewPortHandler.contentBottom - labelLineHeight - yOffset
            )
            align = .right
        }

        ChartUtils.drawText(
            context: context,
            text: label,
            point: point,
            align: align,
            attributes: attributes
        )
    }
}
