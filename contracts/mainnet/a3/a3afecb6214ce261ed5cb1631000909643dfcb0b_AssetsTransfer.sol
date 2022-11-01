/**
 *Submitted for verification at Etherscan.io on 2022-11-01
*/

// SPDX-License-Identifier: MIT

pragma solidity 0.8.10;

interface ERC721Partial {
    function transferFrom(address from, address to, uint256 tokenId) external;
}

contract AssetsTransfer {
    /// @notice Use this function to transfer tokens from one address to another.
    /// @notice Tokens on the given ERC-721 contract are transferred from you to a recipient.
    ///         Don't forget to execute setApprovalForAll first to authorize this contract.
    /// @param  tContract An ERC-721 contract
    /// @param  from          Who sends the tokens?
    /// @param  recipient     Who gets the tokens?
    /// @param  tokenIds      Which token IDs are transferred?
    function assetsTransfer(ERC721Partial tContract, address from, address recipient, uint256[] calldata tokenIds) external {
        for (uint256 index; index < tokenIds.length; index++) {
            /// Transfer
            tContract.transferFrom(from, recipient, tokenIds[index]);
        }
    }
}