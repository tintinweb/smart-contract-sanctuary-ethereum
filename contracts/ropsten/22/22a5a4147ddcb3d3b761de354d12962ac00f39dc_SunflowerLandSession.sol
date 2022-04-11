/**
 *Submitted for verification at Etherscan.io on 2022-04-10
*/

// contracts/MyContract.sol
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract SunflowerLandSession {


    constructor() public {
    }

    function syncSignature(
        bytes32 sessionId,
        uint farmId,
        uint deadline,
        uint256[] memory mintIds,
        uint256[] memory mintAmounts,
        uint256[] memory burnIds,
        uint256[] memory burnAmounts,
        int256 tokens
    ) public view returns(bytes32 success) {
        /**
         * Distinct order and abi.encode to avoid hash collisions
         */
        return keccak256(abi.encode(sessionId, tokens, farmId, mintIds, mintAmounts, msg.sender, burnIds, burnAmounts, deadline));
    }
    

}