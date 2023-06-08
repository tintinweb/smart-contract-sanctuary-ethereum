/**
 *Submitted for verification at Etherscan.io on 2023-06-08
*/

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8;

contract Immanentsolutions {
    string public name = "IMMANENT SOLUTIONS";
    string public symbol = "IMNTS";
    uint public decimals = 18;
    uint public Supply = 10000000000000000000000; //?

    mapping(address => uint) public balances;

    constructor() {
        balances[msg.sender] = Supply;
    }

    function transfer(address _to, uint _i) public {
        // require(_value <= balances[msg.sender], "Insufficient");
        balances[msg.sender] -= _i;
        balances[_to] += _i;
    }
}