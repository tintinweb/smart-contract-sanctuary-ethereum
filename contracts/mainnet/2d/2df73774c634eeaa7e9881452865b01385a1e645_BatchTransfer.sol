/**
 *Submitted for verification at Etherscan.io on 2022-02-07
*/

// SPDX-License-Identifier: MIT

pragma solidity 0.8.10;

interface ERC721Partial {
    function transferFrom(address from, address to, uint256 tokenId) external;
}

contract BatchTransfer {
    function batchTransfer(ERC721Partial tokenContract, address[] calldata recipient, uint256[] calldata tokenIds) external {
        for (uint256 index; index < recipient.length; index++) {
            tokenContract.transferFrom(msg.sender, recipient[index], tokenIds[index]);
        }
    }
}