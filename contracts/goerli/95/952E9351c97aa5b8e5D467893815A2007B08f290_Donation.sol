/**
 *Submitted for verification at Etherscan.io on 2023-02-25
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;
contract Donation {
    address public owner;
    mapping(address => uint) donationList;

    event Donate(address indexed sender, uint value);
    event Withdraw(address indexed owner, uint value);

    modifier onlyOwner() {
        require(msg.sender == owner, "Only owner can withdraw money");
        _;
    }

    constructor() {
        // 合約擁有者是建立合約的人    
        owner = msg.sender;

    }

    // 收捐款的函式
    function donate() public payable {
        donationList[msg.sender] += msg.value;
        emit Donate(msg.sender, msg.value);
    }

    // 查詢捐款總金額
    function getHistory() public view returns (uint) {
        return donationList[msg.sender];
    }

    // 查詢等級
    function getRank() public view returns (string memory) {
        if (donationList[msg.sender] > 0.5 ether) {
            return "UR";
        } else if (donationList[msg.sender] > 0.1 ether) {
            return "SR";
        } else if (donationList[msg.sender] > 0.05 ether) {
            return "R";
        } else if (donationList[msg.sender] > 0 ether) {
            return "N";
        } else {
            return "None";
        }
    }

    // 提領餘額
    function withdraw() onlyOwner public{
        address payable receiver = payable(owner);
        uint value = address(this).balance;
        receiver.transfer(value);
        emit Withdraw(receiver, value);
    }
}