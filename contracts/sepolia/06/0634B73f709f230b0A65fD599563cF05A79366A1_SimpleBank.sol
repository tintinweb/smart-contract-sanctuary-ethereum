/**
 *Submitted for verification at Etherscan.io on 2023-05-28
*/

// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.18;

contract SimpleBank {
    mapping(address => uint256) private balances;
    address public owner;

    event LogDepositMade(address accountAddress, uint256 amount);

    constructor() {
        owner = msg.sender;
    }

    function deposit() public payable returns (uint256) {
        require((balances[msg.sender] + msg.value) >= balances[msg.sender]);
        balances[msg.sender] += msg.value;
        emit LogDepositMade(msg.sender, msg.value); // fire event
        return balances[msg.sender];
    }

    function withdraw(uint256 withdrawAmount)
        public
        payable
        returns (uint256 remainingBal)
    {
        require(withdrawAmount <= balances[msg.sender], "Insufficient funds");
        balances[msg.sender] -= withdrawAmount;
        payable(msg.sender).transfer(withdrawAmount);
        return balances[msg.sender];
    }

    function balance() public view returns (uint256) {
        return balances[msg.sender];
    }
}