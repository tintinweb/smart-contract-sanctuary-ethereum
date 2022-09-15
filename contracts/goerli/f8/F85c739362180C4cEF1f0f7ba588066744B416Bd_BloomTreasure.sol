// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

contract BloomTreasure {
    uint256 private balance;
    address[] private owners;
    uint256 private percentage;
    mapping(address => uint256) private payersFees;

    constructor(address[] memory _owners) {
        //Set an array of owners that can withdraw the balance
        owners = _owners;
    }

    function calculateFee(uint256 amount) public view returns (uint256) {
        return (amount * percentage) / 100;
    }

    function fundTreasure(address sender) public payable {
        payersFees[sender] += msg.value;
        balance += msg.value;
    }

    function getPublicBalance() public view returns (uint256) {
        return balance;
    }

    function retrieveBalance() public {
        bool isOwner = false;
        for (uint256 i = 0; i < owners.length; i++) {
            if (owners[i] == msg.sender) {
                isOwner = true;
            }
        }
        require(isOwner, "You are not an owner");
        payable(msg.sender).transfer(balance);
    }
}