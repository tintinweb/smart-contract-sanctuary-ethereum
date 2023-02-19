//SPDX-License-Identifier: MIT
pragma solidity ^0.8.15;

/**

 ///////////////////////////////////////////////////////////////////////////
 //                                                                       //
 //     ✓ ✓ ✓ ✓ ✓ ✓ ✓ ✓ ✓ ✓ ✓ ✓ ✓ ✓ ✓ ✓ ✓ ✓ ✓ ✓ ✓ ✓ ✓ ✓ ✓ ✓ ✓ ✓ ✓ ✓ ✓ ✓   //
 //     ✓ ✓ ✓ ✓ ✓ ✓ ✓ ✓ ✓ ✓ ✓ ✓ ✓ ✓ ✓ ✓ ✓ ✓ ✓ ✓ ✓ ✓ ✓ ✓ ✓ ✓ ✓ ✓ ✓ ✓ ✓ ✓   //
 //     ✓ ✓ ✓ ✓ ✓ ✓ ✓ ✓ ✓ ✓ ✓ ✓ ✓ ✓ ✓ ✓ ✓ ✓ ✓ ✓ ✓ ✓ ✓ ✓ ✓ ✓ ✓ ✓ ✓ ✓ ✓ ✓   //
 //     ✓ ✓ ✓ ✓ ✓ ✓ ✓ ✓ ✓ ✓ ✓ ✓ ✓ ✓ ✓ ✓ ✓ ✓ ✓ ✓ ✓ ✓ ✓ ✓ ✓ ✓ ✓ ✓ ✓ ✓ ✓ ✓   //
 //     ✓ ✓ ✓ ✓ ✓ ✓ ✓ ✓ ✓ ✓ ✓ ✓ ✓ ✓ ✓ ✓ ✓ ✓ ✓ ✓ ✓ ✓ ✓ ✓ ✓ ✓ ✓ ✓ ✓ ✓ ✓ ✓   //
 //     ✓ ✓ ✓ ✓ ✓ ✓ ✓ ✓ ✓ ✓ ✓ ✓ ✓ ✓ ✓ ✓ ✓ ✓ ✓ ✓ ✓ ✓ ✓ ✓ ✓ ✓ ✓ ✓ ✓ ✓ ✓ ✓   //
 //     ✓ ✓ ✓ ✓ ✓ ✓ ✓ ✓ ✓ ✓ ✓ ✓ ✓ ✓ ✓ ✓ ✓ ✓ ✓ ✓ ✓ ✓ ✓ ✓ ✓ ✓ ✓ ✓ ✓ ✓ ✓ ✓   //
 //     ✓ ✓ ✓ ✓ ✓ ✓ ✓ ✓ ✓ ✓ ✓ ✓ ✓ ✓ ✓ ✓ ✓ ✓ ✓ ✓ ✓ ✓ ✓ ✓ ✓ ✓ ✓ ✓ ✓ ✓ ✓ ✓   //
 //                                                                       //
 ///////////////////////////////////////////////////////////////////////////

@title  Params
@author ng. Inspired by VisualizeValue
@notice Different paramemters used for Checks Banners creation
*/
library Params {
    /// @dev number of columns on the canvas
    uint8 constant columns = 32;

    /// @dev number of rows on the canvas
    uint8 constant rows = 8;

    /// @dev number of unique color for Checks
    uint8 constant numberOfColors = 72;

    /// @dev Hex opacity values representing 100% 90% 80% 70% 60% 50% 40% 30%
    function OPACITY() public pure returns (string[8] memory) {
        return ["FF", "E6", "CC", "B3", "99", "80", "66", "4D"];
    }

    /// @dev Hex opacity values representing 100% 90% 80% 70% 60% 50% 40% 30% in reverse order
    function REVERSE_OPACITY() public pure returns (string[8] memory) {
        return ["4D", "66", "80", "99", "B3", "CC", "E6", "FF"];
    }

    /// @dev Hex opacity values representing 100% 90% 80% 70% 60% 50% 40% 30% in reverse order
    function DEVISORS() public pure returns (uint8[5] memory) {
        return [1, 2, 3, 4, 5];
    }

    /// @dev The different color band sizes used for the art.
    function COLOR_BANDS() public pure returns (uint8[7] memory) {
        return [72, 54, 36, 18, 9, 4, 1];
    }

    /// @dev Theese are sorted in a gradient.
    function COLORS() public pure returns (string[72] memory) {
        return [
            "E84AA9",
            "F2399D",
            "DB2F96",
            "E73E85",
            "FA5B67",
            "FF7F8E",
            "EC7368",
            "FF8079",
            "FF9193",
            "E8424E",
            "D5332F",
            "C23532",
            "DE3237",
            "F2281C",
            "D41515",
            "DA3321",
            "EA3A2D",
            "EB4429",
            "EA5B33",
            "EB5A2A",
            "ED7C30",
            "EF8C37",
            "F18930",
            "F09837",
            "EF9933",
            "F2A43A",
            "F2A840",
            "F2A93C",
            "FFB340",
            "F2B341",
            "FAD064",
            "F7CA57",
            "F6CB45",
            "F4C44A",
            "FCDE5B",
            "F9DA4D",
            "F9DA4A",
            "F9DB49",
            "FAE272",
            "FAE663",
            "FBEA5B",
            "E2F24A",
            "B5F13B",
            "94E337",
            "63C23C",
            "86E48E",
            "5FCD8C",
            "77E39F",
            "83F1AE",
            "9DEFBF",
            "5FC9BF",
            "77D3DE",
            "6AD1DE",
            "5ABAD3",
            "4291A8",
            "45B2D3",
            "81D1EC",
            "A7DDF9",
            "9AD9FB",
            "60B1F4",
            "4576D0",
            "2480BD",
            "3263D0",
            "3D43B3",
            "2E4985",
            "25438C",
            "322F92",
            "4A2387",
            "371471",
            "3B088C",
            "6C31D7",
            "9741DA"
        ];
    }
}