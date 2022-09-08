/**
 *Submitted for verification at Etherscan.io on 2022-09-08
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.7;

interface IAIC_OPERATIVES {
    function balanceOf(address from) external view returns (uint256);
}

interface IAIC_STAKING {
    function tokensStakedBy(address from) external view returns (uint256[] memory);
}

contract AIC_BalanceOf {
    IAIC_OPERATIVES public operativesContract =
        IAIC_OPERATIVES(0x0e64e8432a259C52846AcDaF4E529125E840160f);
    IAIC_STAKING public stakingContract =
        IAIC_STAKING(0x8C8D40378A9bFD2eB2F6E08F62B47524286A9A35);

    constructor() {}

    function balanceOf(address _owner) external view returns (uint256) {
        uint256 totalBalance = operativesContract.balanceOf(_owner);
        uint256[] memory tokensStaked = stakingContract.tokensStakedBy(_owner);
        totalBalance += tokensStaked.length;
        return totalBalance;
    }
}