/**
 *Submitted for verification at Etherscan.io on 2022-05-21
*/

// Sources flattened with hardhat v2.9.1 https://hardhat.org

// File contracts/facets/ClaimNFTFacet.sol

// SPDX-License-Identifier: MIT
pragma solidity 0.8.14;

contract ClaimNFTFacet {
    event ClaimNFT(address indexed from, uint16 tokenId);
    event ClaimAllNFT(address indexed from);

    /** 
    @notice Claim a specific staked NFT of the sender
    @param tokenId The tokenId of the claimed NFT.
     */
    function claimNFT(uint256 tokenId) external payable {
        require(msg.value >= 0.0015 ether, "Not enough eth for transaction");
        emit ClaimNFT(msg.sender, uint16(tokenId));
    }

    /// @notice Claim all staked NFTs of the sender.
    function claimAllNFT() external payable {
        require(msg.value >= 0.0015 ether, "Not enough eth for transaction");
        emit ClaimAllNFT(msg.sender);
    }
}