// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract OpRewards {
    event PrintToken(address);

    function claimRewards(address[] calldata xTokens) public {
        for (uint256 i = 0; i < xTokens.length; i++) {
            emit PrintToken(xTokens[i]);
        }
    }
}