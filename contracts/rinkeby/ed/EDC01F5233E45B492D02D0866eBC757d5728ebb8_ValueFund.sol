/**
 *Submitted for verification at Etherscan.io on 2022-05-18
*/

// SPDX-License-Identifier: NONE

pragma solidity 0.6.6;



// File: ValueFund.sol

contract ValueFund {
    mapping(address => uint256) balances;
    address payable public owner;
    uint256 public creationTime = now;

    constructor() public {
        owner = msg.sender;
    }

    modifier onlyOwner() {
        require(msg.sender == owner);
        _;
    }

    function store() public payable {
        balances[msg.sender] += msg.value;
    }

    function withdraw() public onlyOwner {}
}