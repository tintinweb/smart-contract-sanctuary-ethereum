// SPDX-License-Identifier: MIT
pragma solidity 0.8.10;

import "../interfaces/IERC721OldReceiver.sol";

contract ERC721OldHolder is IERC721OldReceiver {
    /**
     * @dev See {IERC721OldReceiver-onERC721Received}.
     *
     * Always returns `IERC721OldReceiver.onERC721Received.selector`.
     */
    function onERC721Received(
        address,
        uint256,
        bytes memory
    ) public virtual override returns (bytes4) {
        return this.onERC721Received.selector;
    }
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.10;

/**
 * @title ERC721 token receiver interface
 * @dev Interface for any contract that wants to support old safeTransfers
 * from ERC721 asset contracts.
 */
interface IERC721OldReceiver {
    /**
     * @dev Whenever an old implementation of {IERC721} `tokenId` token is transferred to this contract via {IERC721-safeTransferFrom}
     * by `operator` from `from`, this function is called.
     *
     * It must return its Solidity selector to confirm the token transfer.
     * If any other value is returned or the interface is not implemented by the recipient, the transfer will be reverted.
     *
     * The selector can be obtained in Solidity with `IERC721OldReceiver.onERC721Received.selector`.
     */
    function onERC721Received(
        address from,
        uint256 tokenId,
        bytes calldata data
    ) external returns (bytes4);
}