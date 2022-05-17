/**
 *Submitted for verification at Etherscan.io on 2022-05-17
*/

// SPDX-License-Identifier: MIT

pragma solidity 0.6.6;



// File: EasyFund.sol

contract EasyFund {
    address payable public owner;
    mapping(address => uint256) balances;

    constructor() public {
        owner = msg.sender;
    }

    modifier onlyOwner() {
        require(msg.sender == owner);
        _;
    }

    function fund() public payable {
        balances[msg.sender] += msg.value;
    }

    function withdraw() public onlyOwner {}
}