/**
 *Submitted for verification at Etherscan.io on 2023-02-11
*/

//SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;


contract Staking {

    uint256 public totalStaked; // Total amount of ethers staked in smart contract
    mapping(address => uint256) public stakes; // How much one user stores amount of ethers
    mapping(address => address) public referBy; // User ko kis ny reffer keya
    mapping(address => uint256) public directReferralCount; // Maximum 2 ho skta haa
    mapping(address => address[2]) public directReferrals; // referralAddress ky 0 aur 1 index ma kon sa addresses save ha
    uint256 public constant referralRewardPercentage = 10; // User jo amount stake kry ga us ka 10% reward reffer ko jae ga.


    function stake(address referralAddress, uint256 amount) public payable {              // Stake amount of ethers using referralAddress
        require(
            msg.value == amount,
            "The amount staked must match the value sent."
        );

        referBy[msg.sender] = referralAddress;

        // Check if the direct referral has already reached its maximum of two direct referrals
        uint256 referralCount = directReferralCount[referralAddress];
        if (referralCount >= 2) {
            // If the direct referral has reached its maximum, the reward goes to the first referral
            referralAddress = directReferrals[0x5B38Da6a701c568545dCfcB03FcB875f56beddC4][0];
        }
         else {
            // If the direct referral has not reached its maximum, increase the referral count
            directReferralCount[referralAddress]++;
            directReferrals[referralAddress][referralCount] = msg.sender;             // msg.sender referralAddress ka child ban jae ga
        }

        uint256 referralReward = (amount * referralRewardPercentage) / 100;            // 100 * 10 / 100 = 10 reffer reward
        payable(referralAddress).transfer(referralReward);

        stakes[msg.sender] += amount;
        totalStaked += amount;

    }

    function unstake(uint256 amount) public {
        require(totalStaked >= amount, "You cannot unstake more than what you have staked.");
        stakes[msg.sender] -= amount;
        totalStaked -= amount;
        payable(msg.sender).transfer(amount);
    }
}