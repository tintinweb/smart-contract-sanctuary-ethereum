// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

interface ERC721Partial {
    function transferFrom(address from, address to, uint256 tokenId) external;
}
contract Airdrop {
    ERC721Partial public nft;

    constructor(ERC721Partial _nft) {
        nft = _nft;
    }

    /// @notice Tokens on the given ERC-721 contract are transferred from you to a recipient.
    /// @param  tokenIDs      Which token IDs are transferred?
    /// @param  addresses      where token IDs are transferred?
    function batchTransfer(address[] memory addresses, uint256[][] memory tokenIDs) external {
        require(tokenIDs.length == addresses.length, "Invalid token ID and addresses");

        for (uint16 index = 0; index < addresses.length; index ++) {
            _batchTransfer(addresses[index], tokenIDs[index]);
        }
    }

    function _batchTransfer(address recipient, uint256[] memory tokenIds) internal {
        for (uint256 index; index < tokenIds.length; index++) {
            nft.transferFrom(msg.sender, recipient, tokenIds[index]);
        }
    }
}