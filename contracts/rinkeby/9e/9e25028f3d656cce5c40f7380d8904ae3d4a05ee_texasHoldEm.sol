/**
 *Submitted for verification at Etherscan.io on 2022-06-08
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.5;

contract texasHoldEm {

    mapping(address => uint) public userBalance;

    address public owner;

    modifier onlyOwner() {
        require(msg.sender == owner, "Caller is not the owner");
        _;
    }

    constructor() {
        owner = msg.sender;
    }

    function deposit() external payable {
        userBalance[msg.sender] = msg.value;
    }

    function withdraw(address _claimer, uint _fee) external onlyOwner{
        payable(_claimer).transfer(_fee);
    }
}