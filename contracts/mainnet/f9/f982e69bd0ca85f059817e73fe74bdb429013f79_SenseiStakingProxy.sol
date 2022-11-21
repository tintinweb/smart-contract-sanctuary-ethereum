/**
 *Submitted for verification at Etherscan.io on 2022-11-21
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

interface SenseiStaking {
    function stakedTokens(address _user) external view returns (uint256[] memory);
}

contract SenseiStakingProxy {
    function balanceOf(address owner) public view returns (uint256) {
        uint256[] memory tokenIds = SenseiStaking(address(0x65b651B947e654f4Fc42AFc634a263F464eFF97c)).stakedTokens(owner);
        uint256 balance = tokenIds.length;
        return balance;
    }
}