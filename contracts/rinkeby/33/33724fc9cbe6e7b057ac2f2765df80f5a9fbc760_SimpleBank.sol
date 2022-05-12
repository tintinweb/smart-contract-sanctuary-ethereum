/**
 *Submitted for verification at Etherscan.io on 2022-05-12
*/

// File: SimpleBank_v2.sol


pragma solidity ^0.8.10;

contract SimpleBank {
    mapping(address => uint) private balances;

    function withdraw(uint amount) external payable {
        require(balances[msg.sender] >= amount, "Insufficient funds.");

        (bool sent, ) = payable(msg.sender).call{value: amount}("");

        require(sent, "Could not withdraw!");
        balances[msg.sender] -= amount;
    }

    function deposit() external payable {
        balances[msg.sender] += msg.value;
    }

    function getBalance() public view returns (uint) {
        return balances[msg.sender];
    }

}