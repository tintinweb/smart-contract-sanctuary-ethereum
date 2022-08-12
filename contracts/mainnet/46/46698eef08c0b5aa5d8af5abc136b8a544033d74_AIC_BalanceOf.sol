/**
 *Submitted for verification at Etherscan.io on 2022-08-12
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.7;

interface IAIC_GENESIS {
    function balanceOf(address from) external view returns (uint256);
}

interface IAIC_STAKING {
    function tokensStakedBy(address from) external view returns (bool[] memory);
}

contract AIC_BalanceOf {
    IAIC_GENESIS public gensisContract =
        IAIC_GENESIS(0xB78f1A96F6359Ef871f594Acb26900e02bFc8D00);
    IAIC_STAKING public stakingContract =
        IAIC_STAKING(0x1FdBAaF5A73c308A3D66F620201983A28b49d7f6);

    constructor() {}

    function balanceOf(address _owner) external view returns (uint256) {
        uint256 totalBalance = gensisContract.balanceOf(_owner);
        bool[] memory tokensExist = stakingContract.tokensStakedBy(_owner);
        for (uint256 index = 0; index < tokensExist.length; index++) {
            if (tokensExist[index]) {
                totalBalance++;
            }
        }
        return totalBalance;
    }
}