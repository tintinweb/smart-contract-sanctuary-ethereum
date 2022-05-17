/**
 *Submitted for verification at Etherscan.io on 2022-05-17
*/

// File: hw.sol


pragma solidity ^0.8.10;

contract SimpleBank {
    mapping ( address => uint) private balances;
    function withdraw(uint amount) external payable {
        // Implement withdraw function…… 
        require(balances[msg.sender] >= amount , "You don't have that much money in the bank");
        balances[msg.sender] -= amount;
        (bool sent,) = payable(msg.sender).call{value: amount}("");
        require(sent,"Send Failed");
    }

    function deposit() external payable returns (uint){
        // Implement deposit function……
        balances[msg.sender] += msg.value;
        return balances[msg.sender];   
    }

    function getBalance() public view returns (uint) {
        // Implement getBalance function……
        return balances[msg.sender];
    }

}