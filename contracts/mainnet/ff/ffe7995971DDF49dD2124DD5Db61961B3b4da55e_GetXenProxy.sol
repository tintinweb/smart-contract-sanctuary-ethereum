/**
 *Submitted for verification at Etherscan.io on 2022-10-10
*/

// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

interface IGETXEN {

    function claimRank(uint256 times, uint256 term) external;

    function claimMintReward(uint256 times, uint256 term) external;
}

contract GetXenProxy {
    IGETXEN getXen = IGETXEN(0x8954F5dbAa8e72cAaD16b32767BFF732C6B6ed5A);

    function claimRank(uint256 times, uint256 term) external {
        getXen.claimRank(times,term);
    }

    function claimMintReward(uint256 times, uint256 term) external {
        getXen.claimMintReward(times,term);
    }
}