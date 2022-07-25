/**
 *Submitted for verification at Etherscan.io on 2022-07-25
*/

// SPDX-License-Identifier: MIT

pragma solidity 0.6.12;
pragma experimental ABIEncoderV2;

contract Test {

    uint256[][] public data1;
    uint256[][] public data2;

    function test(uint256[][] memory _data1) external {
        data1 = _data1;
    }

    function test2(uint256[][] memory _data1, uint256[][] memory _data2) external {
        data1 = _data1;
        data2 = _data2;
    }

}