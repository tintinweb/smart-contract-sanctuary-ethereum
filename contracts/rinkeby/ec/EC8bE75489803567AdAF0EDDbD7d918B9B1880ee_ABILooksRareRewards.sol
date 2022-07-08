// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

contract ABILooksRareRewards {
    function generateAbi(
        uint8[] memory treeids,
        uint256[] memory amounts, 
        bytes32[][] memory merkleProofs 
    ) external pure returns (bytes memory) {
        return
            abi.encodeWithSignature(
                "claim(uint8[],uint256[],bytes32[][])",
                treeids,
                amounts,
                merkleProofs
            );
    }
}