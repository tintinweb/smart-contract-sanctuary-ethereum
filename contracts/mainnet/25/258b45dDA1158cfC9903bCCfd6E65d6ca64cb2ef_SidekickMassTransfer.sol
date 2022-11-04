// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.17;

// Barebone mass transfer contract to save gas when retrieving ERC721s from wallets.
// This contract must be approved as spender with setApprovalForAll, or via the approve function.
//
// Made for getsidekick.xyz
// Author: @sec0ndstate


interface IERC721 {
    function transferFrom(address from, address to, uint256 tokenId) external;

}

contract SidekickMassTransfer {

    /// @dev Mass transfer ERC721 from msg.sender to receiver
    /// @param token The address of the ERC721 contract
    /// @param receiver The address to transfer the tokens to
    /// @param tokenIds array of tokenIds to transfer
    function massRetrieveERC721(IERC721 token, address receiver, uint256[] calldata tokenIds) external {
        unchecked {
            for (uint256 i = 0; i < tokenIds.length; ++i) {
                token.transferFrom(msg.sender, receiver, tokenIds[i]);
            }
        }
    }
}