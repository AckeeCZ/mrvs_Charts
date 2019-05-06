//
//  MervisYAxisRenderer.swift
//  Charts
//
//  Created by Rostislav Babáček on 18/04/2019.
//

import Foundation
import CoreGraphics

/**
 * Custom renderer for [MervisYAxis] that may contain analog and digital data sets.
 */

@objc(ChartMervisYAxisRenderer)
public class MervisYAxisRenderer: YAxisRenderer {

    public init(transformer: Transformer?, viewPortHandler: ViewPortHandler, yAxis: YAxis?) {
        super.init(viewPortHandler: viewPortHandler, yAxis: yAxis, transformer: transformer)
    }

    public override func computeAxisValues(min: Double, max: Double)
    {
        if let yAxis = axis as? MervisYAxis {
            super.computeAxisValues(min: Double(yAxis.axisMinAnalog), max: max)

            yAxis.digitalEntries.forEach { arg in
                let (value, string) = arg
                yAxis.entries.append(Double(value))
            }
        }
    }
}
