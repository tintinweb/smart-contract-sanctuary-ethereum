// SPDX-License-Identifier: MIT
pragma solidity >=0.8.9 <0.9.0;

interface IERC721 {
    function transferFrom(address from, address to, uint256 tokenId) external;
}

contract BatchTransfer {
    /// @notice Tokens on the given ERC-721 contract are transferred from you to a recipient.
    ///         Don't forget to execute setApprovalForAll first to authorize this contract.
    /// @param  _tokenContract An ERC-721 contract
    /// @param  _recipients    Receivers array
    /// @param  _tokenIds      Token IDs array
    function batchTransfer(IERC721 _tokenContract, address[] calldata _recipients, uint256[] calldata _tokenIds) external {
        for (uint256 i; i < _tokenIds.length; i++) {
            _tokenContract.transferFrom(msg.sender, _recipients[i], _tokenIds[i]);
        }
    }
}