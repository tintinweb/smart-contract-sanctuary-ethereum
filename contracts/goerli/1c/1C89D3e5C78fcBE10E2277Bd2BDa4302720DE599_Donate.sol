// SPDX-License-Identifier: MIT
pragma solidity 0.8.9;

contract Donate {
    address owner;
    uint256 totalDonations;

    struct Donation {
        address donor;
        uint256 amount;
    }

    Donation[] donations;

    constructor() {
        owner = msg.sender;
    }

    receive() external payable {
        donations.push(Donation(msg.sender, msg.value));
        totalDonations += msg.value;
    }

    function getDonors() external view returns (Donation[] memory) {
        return donations;
    }

    function getTotalDonations() external view returns (uint256) {
        return totalDonations;
    }
}