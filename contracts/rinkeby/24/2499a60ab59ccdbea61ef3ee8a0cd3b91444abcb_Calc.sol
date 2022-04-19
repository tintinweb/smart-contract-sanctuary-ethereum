/**
 *Submitted for verification at Etherscan.io on 2022-04-19
*/

// SPDX-License-Identifier: MIT
// solhint-disable-next-line
pragma solidity >=0.4.22 <0.8.0;
contract Calc {
    uint private result;

    function add(uint a, uint b) public returns (uint c) {
    result = a + b;
    c = result;
    }
    function min(uint a, uint b) public returns (uint) {
    result =a - b;
    return result;
    }
    function mul(uint a, uint b) public returns (uint) {
        result = a * b;
        return result;
    }
    function div(uint a, uint b) public returns (uint) {
        result = a / b;
        return result;
    }
    function getResult()public view returns (uint) {
        return result;
    }
}