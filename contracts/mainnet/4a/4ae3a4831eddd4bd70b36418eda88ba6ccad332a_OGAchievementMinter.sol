/**
 *Submitted for verification at Etherscan.io on 2022-09-27
*/

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.7;

error OGAchievementMinter__SenderIsNotContractOwner();
error OGAchievementMinter__ClaimIsPaused();

contract OGAchievementMinter {
    Achievements private immutable i_acvmt;
    address private immutable i_owner;

    bool private s_isPaused;

    constructor(address achievementContractAddress){
        i_acvmt = Achievements(achievementContractAddress);
        i_owner = msg.sender;
    }
 
    function togglePaused() external {
        if (msg.sender != i_owner){
            revert OGAchievementMinter__SenderIsNotContractOwner();
        }
        s_isPaused = !s_isPaused;
    }

    function claimAchievement() external {
        if (s_isPaused){
            revert OGAchievementMinter__ClaimIsPaused();
        }
        i_acvmt.grantAchievement(msg.sender, 0);
    }


}

interface Achievements {
    function grantAchievement(address to, uint256 tokenId) external;
}