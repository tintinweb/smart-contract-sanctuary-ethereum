/**
 *Submitted for verification at Etherscan.io on 2023-01-06
*/

// SPDX-License-Identifier: GPL-3.0

pragma solidity ^0.8.17;
contract Test {
    uint256[] public testNum;
    
    function test(uint256[][] calldata _testNum)  virtual external {
       testNum = _testNum[0];
    }
}