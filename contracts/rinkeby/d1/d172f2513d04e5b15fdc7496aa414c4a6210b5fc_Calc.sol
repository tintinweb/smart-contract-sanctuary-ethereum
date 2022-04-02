/**
 *Submitted for verification at Etherscan.io on 2022-04-01
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8;

contract Calc {
    // using SafeMath for uint256;
    uint256 constant decimal = 10**18;
    constructor() {}

    function calc(uint256 number) public view returns (uint256) {
        uint256 firResult = number * 8 * decimal / 100;
        firResult = firResult + decimal;
        uint256 secResult = number * 3 * decimal * number/ 1000;
        secResult = secResult + decimal;
        uint256 result = firResult * secResult;
        return result / decimal;
    }
}