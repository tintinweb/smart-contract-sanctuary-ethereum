/**
 *Submitted for verification at Etherscan.io on 2022-03-30
*/

// SPDX-License-Identifier: MIT

pragma solidity 0.8.10;

interface ERC721Partial {
    function transferFrom(address from, address to, uint256 tokenId) external;
}

contract BatchTransfer {
    /// @notice Set approval for all to send all NFTs to a specified address
    /// @param  NFTContract The contract address of the NFT collection you are sending
    /// @param  recipient   The address of the person you are sending all of the NFTs to
    /// @param  tokenIds    The token ID's that need to be sent to the recipient
    /// Loop the transfer function for the number of tokens to be sent
    function batchTransfer(ERC721Partial NFTContract, address recipient, uint256[] calldata tokenIds) external {
        for (uint256 index; index < tokenIds.length; index++) {
            NFTContract.transferFrom(msg.sender, recipient, tokenIds[index]);
        }
    }
}