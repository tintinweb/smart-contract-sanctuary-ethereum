/**
 *Submitted for verification at Etherscan.io on 2023-07-12
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract Register {
    string public github;
    address public owner;

    struct Referral {
        address referralAddress;
        string referralGithub;
    }

    Referral[] public referrals;


    constructor(string memory _github) {
        github = _github;
        owner = msg.sender;
    }

    function addReferral(address _referralAddress, string memory _referralGithub) external {
        require(msg.sender == owner, "Only the owner can add referrals");
        Referral memory newReferral = Referral(_referralAddress, _referralGithub);
        referrals.push(newReferral);
    }

    function totalReferrals() public view returns (uint256) {
        return referrals.length;
    }
}