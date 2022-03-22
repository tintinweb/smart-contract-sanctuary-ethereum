// SPDX-License-Identifier: MIT
pragma solidity 0.8.11;

contract Donation {
    mapping(address => uint256) public donationSum;
    address[] private donators;
    address public owner;

    constructor() {
        owner = msg.sender;
    }

    function acceptDonation() external payable {
        address donator = msg.sender;
        uint256 value = msg.value;
        require(value != 0, "value is 0");

        if (donationSum[donator] == 0) {
            donators.push(donator);
        }

        donationSum[donator] += value;
    }

    function getDonators() external view returns (address[] memory) {
        return donators;
    }

    function withdrawDonation(address payable to, uint256 value) external {
        require(msg.sender == owner, "Permission denied");
        to.transfer(value);
    }
}