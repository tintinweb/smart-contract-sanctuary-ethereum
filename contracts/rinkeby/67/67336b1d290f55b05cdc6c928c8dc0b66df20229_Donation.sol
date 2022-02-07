//SPDX-License-Identifier: Unlicense

pragma solidity ^0.8.0;

contract Donation {
    address owner;
    address thisContactAddress;
    address[] donators;
    mapping(address => uint) allDonations;

    constructor() {
        owner = msg.sender;
        thisContactAddress = address(this);
    }

    modifier ownerOnly() {
        require(msg.sender == owner, "only owner can do this");
        _;
    }

    receive() external payable {
        if(allDonations[msg.sender] == 0) {
            donators.push(msg.sender);
        }
        allDonations[msg.sender] += msg.value;
    }

    function withdraw(address payable to, uint amount) external ownerOnly {
        require(amount <= thisContactAddress.balance, "insufficient funds");
        to.transfer(amount);
    }

    function getDonators() external view returns(address[] memory) {
        return donators;
    }

    function getDonation(address donator) external view returns(uint) {
        return allDonations[donator];
    }
}