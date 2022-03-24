/**
 *Submitted for verification at Etherscan.io on 2022-03-23
*/

// File: Test1.sol

//SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;
contract test{
    uint a;
    function setvalue(uint _a) external {
        a = _a;
    }

    function value() public view returns (uint) {
        return a;
    }
}