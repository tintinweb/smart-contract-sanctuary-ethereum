/**
 *Submitted for verification at Etherscan.io on 2022-04-01
*/

// SPDX-License-Identifier: MIT
pragma solidity 0.8.3;

contract BigData {
    bytes public mybigdata;

    function submitBigData(bytes calldata _mybigdata) public {
        mybigdata = _mybigdata;
    }
}