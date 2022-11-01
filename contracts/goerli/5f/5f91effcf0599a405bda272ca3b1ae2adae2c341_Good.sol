/**
 *Submitted for verification at Etherscan.io on 2022-11-01
*/

// SPDX-License-Identifier: MIT
//Address: 0x5f91effcf0599a405bda272ca3b1ae2adae2c341
pragma solidity ^0.8.7;

contract Good {
    address public helper;
    address public owner;
    uint public num;
    constructor( address _helper) {
        helper = _helper;
        owner = msg.sender;
    }
    function setNum(uint _num) public {
        helper.delegatecall(abi.encodeWithSignature("setNum(uint256)", _num));
        }
    function getowner() public view returns(address) {
        return owner;
    }
}