//SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

/**

 /////////////////////////////////
 //                             //
 //                             //
 //                             //
 //       ✓ ✓ ✓ ✓ ✓ ✓ ✓ ✓       //
 //       ✓ ✓ ✓ ✓ ✓ ✓ ✓ ✓       //
 //       ✓ ✓ ✓ ✓ ✓ ✓ ✓ ✓       //
 //       ✓ ✓ ✓ ✓ ✓ ✓ ✓ ✓       //
 //       ✓ ✓ ✓ ✓ ✓ ✓ ✓ ✓       //
 //       ✓ ✓ ✓ ✓ ✓ ✓ ✓ ✓       //
 //       ✓ ✓ ✓ ✓ ✓ ✓ ✓ ✓       //
 //       ✓ ✓ ✓ ✓ ✓ ✓ ✓ ✓       //
 //       ✓ ✓ ✓ ✓ ✓ ✓ ✓ ✓       //
 //       ✓ ✓ ✓ ✓ ✓ ✓ ✓ ✓       //
 //                             //
 //                             //
 //                             //
 /////////////////////////////////

@title  EightyColors
@author VisualizeValue
@notice The eighty colors of Checks.
*/
library EightyColors {

    /// @dev Theese are sorted in a gradient.
    function COLORS() public pure returns (string[80] memory) {
        return [
            'E84AA9',
            'F2399D',
            'DB2F96',
            'E73E85',
            'FF7F8E',
            'FA5B67',
            'E8424E',
            'D5332F',
            'C23532',
            'F2281C',
            'D41515',
            '9D262F',
            'DE3237',
            'DA3321',
            'EA3A2D',
            'EB4429',
            'EC7368',
            'FF8079',
            'FF9193',
            'EA5B33',
            'EB5A2A',
            'ED7C30',
            'EF9933',
            'EF8C37',
            'F18930',
            'F09837',
            'F9A45C',
            'F2A43A',
            'F2A840',
            'F2A93C',
            'FFB340',
            'F2B341',
            'FAD064',
            'F7CA57',
            'F6CB45',
            'FFAB00',
            'F4C44A',
            'FCDE5B',
            'F9DA4D',
            'F9DA4A',
            'FAE272',
            'F9DB49',
            'FAE663',
            'FBEA5B',
            'E2F24A',
            'B5F13B',
            '94E337',
            '63C23C',
            '86E48E',
            '77E39F',
            '83F1AE',
            '5FCD8C',
            '9DEFBF',
            '2E9D9A',
            '3EB8A1',
            '5FC9BF',
            '77D3DE',
            '6AD1DE',
            '5ABAD3',
            '4291A8',
            '45B2D3',
            '81D1EC',
            '33758D',
            'A7DDF9',
            '9AD9FB',
            '2480BD',
            '60B1F4',
            'A4C8EE',
            '4576D0',
            '2E4985',
            '3263D0',
            '25438C',
            '525EAA',
            '3D43B3',
            '322F92',
            '4A2387',
            '371471',
            '3B088C',
            '9741DA',
            '6C31D7'
        ];
    }

}