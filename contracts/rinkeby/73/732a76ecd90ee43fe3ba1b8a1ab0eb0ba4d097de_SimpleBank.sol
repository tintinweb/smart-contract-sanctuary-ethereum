/**
 *Submitted for verification at Etherscan.io on 2022-05-12
*/

// File: HW08.sol


pragma solidity ^0.8.10;

contract SimpleBank {
    mapping(address => uint) private balances;

    function withdraw(uint amount) external payable {
        require(amount <= balances[msg.sender], "");
        (bool sent, ) = payable(msg.sender).call{value: amount}("");
        require(sent, "Send failed.");
        balances[msg.sender] -= amount;
    }

    function deposit() external payable {
        balances[msg.sender] += msg.value;
    }

    function getBalance() public view returns (uint) {
        return balances[msg.sender];
    }
}