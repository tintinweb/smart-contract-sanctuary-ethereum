/**
 *Submitted for verification at Etherscan.io on 2022-07-08
*/

// SPDX-License-Identifier: MIT

pragma solidity 0.8.9;

contract Test {
    uint256 counter;

    function doSth() external returns (uint256) {
        counter++;
        return counter;
    }

}