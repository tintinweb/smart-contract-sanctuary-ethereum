/**
 *Submitted for verification at Etherscan.io on 2022-04-21
*/

// SPDX-License-Identifier: MIT

// File: contracts/interfaces/IXRooStaking.sol



pragma solidity ^0.8.9;

interface IXRooStaking {
    struct UserData {
        uint256 stake;
        uint256 liquidity;
        uint256 lastTimestamp;
        int256 RTRewardModifier;
        int256 NFTXRewardModifier;
        uint256 NFTXRewardWithdrawn;
    }

    function users(address user) external view returns (UserData memory);
}
// File: contracts/xRooStakingTokenWrapper.sol



pragma solidity ^0.8.9;


contract xRooStakingTokenWrapper {
    IXRooStaking immutable xRooStaking = IXRooStaking(0x58C1ff9bBA25f14Cf23EA3c5B408dA234a456D04);

    function balanceOf(address account) external view returns (uint256) {
        return xRooStaking.users(account).stake;
    }
}