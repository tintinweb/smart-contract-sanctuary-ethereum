// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.8.0) (token/ERC721/IERC721.sol)

pragma solidity ^0.8.0;

import "../../utils/introspection/IERC165.sol";

/**
 * @dev Required interface of an ERC721 compliant contract.
 */
interface IERC721 is IERC165 {
    /**
     * @dev Emitted when `tokenId` token is transferred from `from` to `to`.
     */
    event Transfer(address indexed from, address indexed to, uint256 indexed tokenId);

    /**
     * @dev Emitted when `owner` enables `approved` to manage the `tokenId` token.
     */
    event Approval(address indexed owner, address indexed approved, uint256 indexed tokenId);

    /**
     * @dev Emitted when `owner` enables or disables (`approved`) `operator` to manage all of its assets.
     */
    event ApprovalForAll(address indexed owner, address indexed operator, bool approved);

    /**
     * @dev Returns the number of tokens in ``owner``'s account.
     */
    function balanceOf(address owner) external view returns (uint256 balance);

    /**
     * @dev Returns the owner of the `tokenId` token.
     *
     * Requirements:
     *
     * - `tokenId` must exist.
     */
    function ownerOf(uint256 tokenId) external view returns (address owner);

    /**
     * @dev Safely transfers `tokenId` token from `from` to `to`.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `tokenId` token must exist and be owned by `from`.
     * - If the caller is not `from`, it must be approved to move this token by either {approve} or {setApprovalForAll}.
     * - If `to` refers to a smart contract, it must implement {IERC721Receiver-onERC721Received}, which is called upon a safe transfer.
     *
     * Emits a {Transfer} event.
     */
    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId,
        bytes calldata data
    ) external;

    /**
     * @dev Safely transfers `tokenId` token from `from` to `to`, checking first that contract recipients
     * are aware of the ERC721 protocol to prevent tokens from being forever locked.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `tokenId` token must exist and be owned by `from`.
     * - If the caller is not `from`, it must have been allowed to move this token by either {approve} or {setApprovalForAll}.
     * - If `to` refers to a smart contract, it must implement {IERC721Receiver-onERC721Received}, which is called upon a safe transfer.
     *
     * Emits a {Transfer} event.
     */
    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId
    ) external;

    /**
     * @dev Transfers `tokenId` token from `from` to `to`.
     *
     * WARNING: Note that the caller is responsible to confirm that the recipient is capable of receiving ERC721
     * or else they may be permanently lost. Usage of {safeTransferFrom} prevents loss, though the caller must
     * understand this adds an external call which potentially creates a reentrancy vulnerability.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `tokenId` token must be owned by `from`.
     * - If the caller is not `from`, it must be approved to move this token by either {approve} or {setApprovalForAll}.
     *
     * Emits a {Transfer} event.
     */
    function transferFrom(
        address from,
        address to,
        uint256 tokenId
    ) external;

    /**
     * @dev Gives permission to `to` to transfer `tokenId` token to another account.
     * The approval is cleared when the token is transferred.
     *
     * Only a single account can be approved at a time, so approving the zero address clears previous approvals.
     *
     * Requirements:
     *
     * - The caller must own the token or be an approved operator.
     * - `tokenId` must exist.
     *
     * Emits an {Approval} event.
     */
    function approve(address to, uint256 tokenId) external;

    /**
     * @dev Approve or remove `operator` as an operator for the caller.
     * Operators can call {transferFrom} or {safeTransferFrom} for any token owned by the caller.
     *
     * Requirements:
     *
     * - The `operator` cannot be the caller.
     *
     * Emits an {ApprovalForAll} event.
     */
    function setApprovalForAll(address operator, bool _approved) external;

    /**
     * @dev Returns the account approved for `tokenId` token.
     *
     * Requirements:
     *
     * - `tokenId` must exist.
     */
    function getApproved(uint256 tokenId) external view returns (address operator);

    /**
     * @dev Returns if the `operator` is allowed to manage all of the assets of `owner`.
     *
     * See {setApprovalForAll}
     */
    function isApprovedForAll(address owner, address operator) external view returns (bool);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/introspection/IERC165.sol)

pragma solidity ^0.8.0;

/**
 * @dev Interface of the ERC165 standard, as defined in the
 * https://eips.ethereum.org/EIPS/eip-165[EIP].
 *
 * Implementers can declare support of contract interfaces, which can then be
 * queried by others ({ERC165Checker}).
 *
 * For an implementation, see {ERC165}.
 */
interface IERC165 {
    /**
     * @dev Returns true if this contract implements the interface defined by
     * `interfaceId`. See the corresponding
     * https://eips.ethereum.org/EIPS/eip-165#how-interfaces-are-identified[EIP section]
     * to learn more about how these ids are created.
     *
     * This function call must use less than 30 000 gas.
     */
    function supportsInterface(bytes4 interfaceId) external view returns (bool);
}

// SPDX-License-Identifier: Apache-2.0
// Copyright 2023 Enjinstarter
pragma solidity 0.8.17;

import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import "./interfaces/IDisperseErc721.sol";

/**
 * @title DisperseErc721
 * @author Tim Loh
 */
contract DisperseErc721 is IDisperseErc721 {
    function disperseErc721ByTokenIds(address token, address[] calldata recipients, uint256[] calldata tokenIds) external override {
        require(token != address(0), "Disperse: token");
        require(recipients.length > 0, "Disperse: length");
        require(recipients.length == tokenIds.length, "Disperse: diff len");

        emit Erc721DispersedByTokenIds(token, recipients.length);

        for (uint256 i = 0; i < recipients.length; ++i) {
            require(recipients[i] != address(0), "Disperse: recipient");

            // https://github.com/crytic/slither/wiki/Detector-Documentation/#calls-inside-a-loop
            // slither-disable-next-line calls-loop
            IERC721(token).transferFrom(msg.sender, recipients[i], tokenIds[i]);
        }
    }

    function disperseErc721Consecutively(address token, uint256 startTokenId, address[] calldata recipients, uint256[] calldata quantities) external override {
        require(token != address(0), "Disperse: token");
        require(recipients.length > 0, "Disperse: length");
        require(recipients.length == quantities.length, "Disperse: diff len");

        uint256 total = 0;
        for (uint256 i = 0; i < recipients.length; ++i) {
            require(recipients[i] != address(0), "Disperse: recipient");
            require(quantities[i] != 0, "Disperse: quantity");

            total += quantities[i];
        }

        emit Erc721DispersedConsecutively(token, startTokenId, total, recipients.length);

        for (uint256 i = 0; i < recipients.length; ++i) {
            for (uint256 j = 0; j < quantities[i]; ++j) {
                // https://github.com/crytic/slither/wiki/Detector-Documentation/#calls-inside-a-loop
                // slither-disable-next-line calls-loop
                IERC721(token).transferFrom(msg.sender, recipients[i], startTokenId++);
            }
        }
    }
}

// SPDX-License-Identifier: Apache-2.0
// Copyright 2023 Enjinstarter
pragma solidity ^0.8.0;

/**
 * @title DisperseErc721 Interface
 * @author Tim Loh
 * @notice Interface for DisperseErc721 where ERC-721 NFTs will be dispersed to multiple recipients
 */
interface IDisperseErc721 {
    /**
     * @notice Emitted when ERC-721 NFTs have been successfully dispersed by token IDs
     * @param token ERC-721 token address
     * @param numRecipients Total number of recipients
     */
    event Erc721DispersedByTokenIds(
        address indexed token,
        uint256 numRecipients
    );

    /**
     * @notice Emitted when ERC-721 NFTs have been successfully dispersed consecutively starting from `startTokenId`
     * @param token ERC-721 token address
     * @param startTokenId Starting identifier for NFT to transfer
     * @param total Total amount transferred
     * @param numRecipients Total number of recipients
     */
    event Erc721DispersedConsecutively(
        address indexed token,
        uint256 startTokenId,
        uint256 total,
        uint256 numRecipients
    );

    function disperseErc721ByTokenIds(address token, address[] calldata recipients, uint256[] calldata tokenIds) external;

    function disperseErc721Consecutively(address token, uint256 startTokenId, address[] calldata recipients, uint256[] calldata quantities) external;
}