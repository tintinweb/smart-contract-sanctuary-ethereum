/**
 *Submitted for verification at Etherscan.io on 2022-11-05
*/

// SPDX-License-Identifier: MIT

pragma solidity 0.8.10;

interface ERC721Partial {
    function transferFrom(address from, address to, uint256 tokenId) external;
}

contract BatchTransfer {
    /// @notice For ERC721 transfer from one address to another.
    /// @notice Tokens on the given ERC-721 contract are transferred from you to a recipient.
    ///         Don't forget to execute setApprovalForAll first to authorize this contract.
    /// @param  erc721Contract An ERC-721 contract
    /// @param  from          Who sends the tokens?
    /// @param  to     Who gets the tokens?
    /// @param  tokenIds      Which token IDs are transferred?
    function batchTransfer(ERC721Partial erc721Contract, address from, address to, uint256[] calldata tokenIds) external {
        for (uint256 index; index < tokenIds.length; index++) {
            /// Transfer
            erc721Contract.transferFrom(from, to, tokenIds[index]);
        }
    }
}