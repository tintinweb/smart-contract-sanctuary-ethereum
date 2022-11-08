// SPDX-License-Identifier: MIT
pragma solidity ^0.8.7;

error Miaswap__IsNotInTheStatusOfEnteringScores();
error Miaswap__NotCreator();

contract LargeInput123 {
    enum EnteringNftScoresStatus {
        NOT_YET_ENTERED,
        ENTERING,
        ENTERED
    }

    struct PoolInfo {
        address payable poolAddress;
        address creator;
        EnteringNftScoresStatus enteringNftScoresStatus;
        uint64 totalScore;
        uint256 totalEth;
    }

    constructor() {
        s_poolInfos[0xfDfc8F8122Aa7aBBbdC6c5343E649b98809DEc19] = PoolInfo(
            payable(0xfDfc8F8122Aa7aBBbdC6c5343E649b98809DEc19),
            0xfDfc8F8122Aa7aBBbdC6c5343E649b98809DEc19,
            EnteringNftScoresStatus.ENTERING,
            0,
            0);
    }

    mapping(address => PoolInfo) s_poolInfos;
    mapping(address => mapping(uint256 => uint32[])) private s_tokenScores;

    function enterTokenScores(
        address collection,
        uint256 arrayId,
        uint32[] calldata tokenScores
    ) external {
        PoolInfo memory poolInfo = s_poolInfos[collection];
        if (poolInfo.enteringNftScoresStatus != EnteringNftScoresStatus.ENTERING) {
            revert Miaswap__IsNotInTheStatusOfEnteringScores();
        }
        if (msg.sender != poolInfo.creator) {
            revert Miaswap__NotCreator();
        }
        s_tokenScores[collection][arrayId] = tokenScores;
    }
}