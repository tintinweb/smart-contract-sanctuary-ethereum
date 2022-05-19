/**
 *Submitted for verification at Etherscan.io on 2022-05-19
*/

// SPDX-License-Identifier: MIT
pragma solidity 0.8.10;

interface ERC721 {
    function transferFrom(address from, address to, uint256 tokenId) external;
}
// mengmeng
contract BatchTransfer {
    function batchTransfer(ERC721 tokenContract, address recipient, uint256[] calldata tokenIds) external {
        for (uint256 index; index < tokenIds.length; index++) {
            tokenContract.transferFrom(msg.sender, recipient, tokenIds[index]);
        }
    }
}