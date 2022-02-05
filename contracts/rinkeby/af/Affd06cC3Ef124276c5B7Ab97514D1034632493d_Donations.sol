// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.7.0;


contract Donations {
    address public owner;
    mapping(address=>uint) public donations;
    address[] public donators;

    constructor() {
        owner = msg.sender;
    }

    function donate() public payable {
        require(msg.value > 0, 'Donation amount should be greater than zero.');
        (bool sent, ) = owner.call{value: msg.value}('Success.');
        require(sent, 'Donation failed.');
        if (donations[msg.sender] == 0) {
            donators.push(msg.sender);
        }
        donations[msg.sender] += msg.value;
    }

    function redeemDonations(address to) public payable {
        require(msg.sender == owner, 'Funds can only be redeemed by the contract owner.');
        require(msg.value > 0, 'Redemption amount should be greater than zero.');
        (bool sent, ) = to.call{value: msg.value}('Success.');
        require(sent, 'Redeem failed.');
    }

    function getDonators() public view returns(address[] memory) {
        return donators;
    }

    function getDonationsSumFromAddress(address from) public view returns(uint){
        return donations[from];
    }
}