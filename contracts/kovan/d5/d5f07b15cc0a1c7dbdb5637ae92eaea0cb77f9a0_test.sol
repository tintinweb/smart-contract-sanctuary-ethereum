/**
 *Submitted for verification at Etherscan.io on 2022-02-18
*/

// SPDX-License-Identifier: Apache-2.0.
pragma solidity ^0.8.12;

contract test{
    address public governance;
    uint256 public testVar;
    uint256[] public testArr;
    constructor() {
        governance = msg.sender;
    }

    function test4(uint256 fa) public {
        for (uint256 i = 1; i <= fa; i++) {
            testArr[i]=fa;
            fa --;
        }
    }

    function test5(uint256 faa) public view returns (uint256){
        return testArr[faa];
    }
}