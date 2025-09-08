import Foundation

/**
 * Utility functions for handling monitor resolution strings
 * 
 * This utility provides shared functions for normalizing resolution strings
 * across the MacAppPositioner application to ensure consistent handling
 * of both user-friendly formats ("3440x1440") and system-generated formats ("3440.0x1440.0").
 */

class ResolutionUtils {
    
    /**
     * Normalize resolution strings to handle both user-friendly and system formats
     * 
     * Converts various resolution formats to a consistent comparable format:
     * - "3440x1440" -> "3440x1440" (unchanged)
     * - "3440.0x1440.0" -> "3440x1440" (removes .0 suffixes)
     * - "3440 x 1440" -> "3440x1440" (removes spaces)
     * 
     * @param resolution: The resolution string to normalize
     * @returns: Normalized resolution string in "widthxheight" format
     */
    static func normalizeResolution(_ resolution: String) -> String {
        // Remove .0 suffixes and spaces to normalize to simple "widthxheight" format
        let cleaned = resolution
            .replacingOccurrences(of: ".0", with: "")
            .replacingOccurrences(of: " ", with: "")
        return cleaned
    }
    
    /**
     * Check if two resolution strings are equivalent after normalization
     * 
     * @param resolution1: First resolution string
     * @param resolution2: Second resolution string
     * @returns: True if the resolutions are equivalent after normalization
     */
    static func areResolutionsEquivalent(_ resolution1: String, _ resolution2: String) -> Bool {
        return normalizeResolution(resolution1) == normalizeResolution(resolution2)
    }
}