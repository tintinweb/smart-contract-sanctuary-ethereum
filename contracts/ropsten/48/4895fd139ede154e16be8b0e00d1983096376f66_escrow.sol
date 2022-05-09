/**
 *Submitted for verification at Etherscan.io on 2022-05-09
*/

// SPDX-License-Identifier: UNLICENSED

pragma solidity <0.9.0;

contract escrow {
    address agent;

    mapping (address => uint) deposits;

    modifier onlyAgent {
        require(msg.sender == agent);
        _;
    }

    function deposit(address _address) public payable {
       uint amount = msg.value;
       deposits[_address] += amount;
    }
}