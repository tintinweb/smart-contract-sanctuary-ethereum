/**
 *Submitted for verification at Etherscan.io on 2022-04-28
*/

//SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.11;

contract Sample {
        struct Point {
                uint256 min;
                uint256 max;
        }
        function test() external pure returns(Point[] memory) {
                Point[] memory values = new Point[](2);
                values[0] = Point(50, 100);
                values[1] = Point(70, 100);
                return values;
        }
}