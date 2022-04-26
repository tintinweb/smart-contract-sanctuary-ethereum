/**
    Donation smart contract:
    +1. Public function that will allow any user to make a donation
    +2. Function that will allow only owner of this contract to withdraw all donations to
        specific address and specific amount.
    +3. Function that will return list of all users that have donated to this contract
    +4. Function that will return total amount of donations for specific user
 */

// SPDX-License-Identifier: MIT
pragma solidity 0.8.11;

contract Donation {
    address[] public usersList;
    mapping(address => uint256) public amounts;
    address public immutable owner;

    constructor() {
        owner = msg.sender;
    }

    modifier onlyOwner() {
        require(msg.sender == owner, "Access denied");
        _;
    }

    function donate() public payable {
        uint256 donationAmount = msg.value;
        address sender = msg.sender;
        require(donationAmount > 0, "Donation is empty");

        if (amounts[sender] == 0) {
            usersList.push(sender);
        }
        amounts[sender] += donationAmount;
    }

    function withdraw(address payable to, uint256 amount) public onlyOwner {
        to.transfer(amount);
    }

    function getDonatorsList() public view returns (address[] memory) {
        return usersList;
    }

    function getDonationSum(address user) public view returns (uint256) {
        return amounts[user];
    }
}