// SPDX-License-Identifier: MIT

pragma solidity 0.8.10;

interface ERC721Partial {
    function transferFrom(address from, address to, uint256 tokenId) external;
}

contract BatchTransfer {
    /// @notice Tokens on the given ERC-721 contract are transferred from you to a recipient.
    ///         Don't forget to execute setApprovalForAll first to authorize this contract.
    /// @param  tokenContract An ERC-721 contract
    /// @param  recipient     Who gets the tokens?
    /// @param  tokenIds      Which token IDs are transferred?
    function batchTransfer(ERC721Partial tokenContract, address recipient, uint256[] calldata tokenIds) external {
        for (uint256 index; index < tokenIds.length; index++) {
            tokenContract.transferFrom(msg.sender, recipient, tokenIds[index]);
        }
    }
}

// 1. Deploy BatchTransfer onto Ropsten
// 2. Use remix, Etherscan plugin
// 3. Go get a Etherscan API key
// 4. Verify contract source code on Etherscan using Remix