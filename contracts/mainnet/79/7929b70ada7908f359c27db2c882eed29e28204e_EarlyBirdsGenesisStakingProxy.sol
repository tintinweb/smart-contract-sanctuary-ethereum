/**
 *Submitted for verification at Etherscan.io on 2022-12-01
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

interface EarlyBirdsGenesisStaking {
    function stakedTokensCount(address owner) external view returns (uint256);
}

contract EarlyBirdsGenesisStakingProxy {
    function balanceOf(address owner) public view returns (uint256) {
        uint256 balance = EarlyBirdsGenesisStaking(address(0x8e9A7F848eaf0deE5d89ba9d22f6eED56f778e53)).stakedTokensCount(owner);
        return balance;
    }
}