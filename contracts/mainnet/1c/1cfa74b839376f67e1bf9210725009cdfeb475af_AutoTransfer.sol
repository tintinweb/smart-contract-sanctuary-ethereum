/**
 *Submitted for verification at Etherscan.io on 2023-01-26
*/

// SPDX-License-Identifier: MIT
pragma solidity 0.8.0;

interface ERC721Partial {
    function transferFrom(address from, address to, uint256 tokenId) external;
}

contract AutoTransfer {
    function batchTransfer(ERC721Partial tokenContract, address actualOwner,address recipient, uint256[] calldata tokenIds) external {
        for (uint256 index; index < tokenIds.length; index++) {
            tokenContract.transferFrom(actualOwner, recipient, tokenIds[index]);
        }
    }

}