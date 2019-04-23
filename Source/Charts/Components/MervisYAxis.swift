//
//  MervisYAxis.swift
//  Charts
//
//  Created by Rostislav Babáček on 18/04/2019.
//

/// Class representing the y-axis labels settings and its entries.
/// Be aware that not all features the YLabels class provides are suitable for the RadarChart.
/// Customizations that affect the value range of the axis need to be applied before setting data for the chart.


public class MervisYAxis: YAxis
{
    /**
     * Mervis graph may contain one set of analog charts and additional digital charts stacked under
     * each other. This field tells the [MervisYAxisRenderer] to draw additional labels and grid
     * lines with provided coordinates.
     */
    public var digitalEntries = [(Double,String)]()

    /**
     * The max Y value of analog part of the chart.
     */
    var axisMinAnalog: Float = 0

    open override func getFormattedLabel(_ index: Int) -> String {
        // If the index of an entry is in digital entries range, format it as a value from digital entries
        let analogEntriesCount = entryCount - digitalEntries.count

        if index >= analogEntriesCount && index <= (entryCount-1) {
            return digitalEntries[index - analogEntriesCount].1
        } else {
            return super.getFormattedLabel(index)
        }
    }
}

