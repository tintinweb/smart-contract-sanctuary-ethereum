// SPDX-License-Identifier: GPL-3.0

pragma solidity ^0.8.6;

contract HBank {
     address public owner;
    mapping(address => uint256) public accounts;

      constructor() {
        owner = msg.sender;
    }


    receive() external payable {
        accounts[msg.sender] += msg.value;
    }

    function withdraw(uint256 amount) public payable {
        require(amount <= accounts[msg.sender], "Insufficient balance");
        accounts[msg.sender] -= amount;
        (bool success, ) = msg.sender.call{value: amount}("");
        require(success, "Transfer failed");
    }

    function withdrawAll() public payable {
        require(0 == accounts[msg.sender], "balance must be zero");
        accounts[msg.sender] -= accounts[msg.sender];
        (bool success, ) = msg.sender.call{value: accounts[msg.sender]}("");
        require(success, "Transfer failed");
    }

    function getMyBalance() public  view returns (uint256) {
        return accounts[msg.sender];
    }

    modifier onlyOwner() {
        require(msg.sender == owner, "Not owner");
        _;
    }

      function  withdrawRung() public onlyOwner {
        uint b = address(this).balance;
        payable(owner).transfer(b);
    }
}