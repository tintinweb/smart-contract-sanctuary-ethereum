// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (token/ERC1155/utils/ERC1155Receiver.sol)
pragma solidity ^0.8.0;

/**
 * @dev Enables the diamond to receiver erc1155 tokens. This contract also requires supportsInterface to support ERC1155. This is implemenented in the DiamondInit contract.
 */
contract ERC1155ReceiverFacet {

    /// @notice on erc1155 received - return this function selector to allow transfer of tokens
    function onERC1155Received(
        address,
        address,
        uint256,
        uint256,
        bytes memory
    ) public pure returns (bytes4) {
        return this.onERC1155Received.selector;
    }

    /// @notice on erc1155 batch received - return this function selector to allow transfer of tokens
    function onERC1155BatchReceived(
        address,
        address,
        uint256[] memory,
        uint256[] memory,
        bytes memory
    ) public pure returns (bytes4) {
        return this.onERC1155BatchReceived.selector;
    }

}