/**
 *Submitted for verification at Etherscan.io on 2022-05-12
*/

// File: contracts/simplebank.sol


pragma solidity ^0.8.10;

contract SimpleBank {
    mapping( address => uint ) private balances;

    modifier canWithdraw(uint amount){
        require(amount <= balances[msg.sender], "Not enough balance");
        _;
    }

    function withdraw(uint amount) external payable canWithdraw(amount){
        (bool sent, ) = payable(msg.sender).call{value: amount}("");
        require(sent, "Sent failed.");
        balances[msg.sender] -= amount;
    }

    function deposit() external payable {
        balances[msg.sender] += msg.value;
    }

    function getBalance() public view returns (uint) {
        return balances[msg.sender];
    }
}