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

open class MervisYAxisRenderer: YAxisRenderer {
//    let yAxis: MervisYAxis?

    public init(viewPortHandler: ViewPortHandler, yAxis: MervisYAxis?, transformer: Transformer?)
    {
//        self.yAxis = yAxis
        super.init(viewPortHandler: viewPortHandler, yAxis: yAxis, transformer: transformer)
    }

    open override func computeAxisValues(min: Double, max: Double)
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
