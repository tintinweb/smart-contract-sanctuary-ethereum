/**
 *Submitted for verification at Etherscan.io on 2022-06-12
*/

//SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

contract smartBank {
    uint public totalBalance = 0;

    function getTotalBalance() public view returns(uint){
        return totalBalance;
    }

    mapping(address => uint) balances;
    mapping(address => uint) depositTimestamps;

    function addBalance() public payable {
        balances[msg.sender] = msg.value;
        totalBalance = totalBalance + msg.value;
        depositTimestamps[msg.sender] = block.timestamp;
    }

    function getBalance(address userAddress) public view returns(uint){
        uint principal = balances[userAddress];
        uint timeElapsed = block.timestamp - depositTimestamps[userAddress];
        return principal + uint((principal * 7000 * timeElapsed) / (100 * 365 * 24 * 60 * 60)) + 1; // interes del 0,07% anual
    }

    function withdraw() public payable {
        address payable withdrawTo = payable(msg.sender);
        uint amountToTransfer = getBalance(msg.sender);
        withdrawTo.transfer(amountToTransfer);
        totalBalance = totalBalance - amountToTransfer;
        balances[msg.sender] = 0;
    }
    
    function addMoneyToContract() public payable {
        totalBalance = msg.value;
    }
}