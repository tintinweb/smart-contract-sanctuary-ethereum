// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (token/ERC1155/IERC1155.sol)

pragma solidity ^0.8.0;

import "../../utils/introspection/IERC165.sol";

/**
 * @dev Required interface of an ERC1155 compliant contract, as defined in the
 * https://eips.ethereum.org/EIPS/eip-1155[EIP].
 *
 * _Available since v3.1._
 */
interface IERC1155 is IERC165 {
    /**
     * @dev Emitted when `value` tokens of token type `id` are transferred from `from` to `to` by `operator`.
     */
    event TransferSingle(address indexed operator, address indexed from, address indexed to, uint256 id, uint256 value);

    /**
     * @dev Equivalent to multiple {TransferSingle} events, where `operator`, `from` and `to` are the same for all
     * transfers.
     */
    event TransferBatch(
        address indexed operator,
        address indexed from,
        address indexed to,
        uint256[] ids,
        uint256[] values
    );

    /**
     * @dev Emitted when `account` grants or revokes permission to `operator` to transfer their tokens, according to
     * `approved`.
     */
    event ApprovalForAll(address indexed account, address indexed operator, bool approved);

    /**
     * @dev Emitted when the URI for token type `id` changes to `value`, if it is a non-programmatic URI.
     *
     * If an {URI} event was emitted for `id`, the standard
     * https://eips.ethereum.org/EIPS/eip-1155#metadata-extensions[guarantees] that `value` will equal the value
     * returned by {IERC1155MetadataURI-uri}.
     */
    event URI(string value, uint256 indexed id);

    /**
     * @dev Returns the amount of tokens of token type `id` owned by `account`.
     *
     * Requirements:
     *
     * - `account` cannot be the zero address.
     */
    function balanceOf(address account, uint256 id) external view returns (uint256);

    /**
     * @dev xref:ROOT:erc1155.adoc#batch-operations[Batched] version of {balanceOf}.
     *
     * Requirements:
     *
     * - `accounts` and `ids` must have the same length.
     */
    function balanceOfBatch(address[] calldata accounts, uint256[] calldata ids)
        external
        view
        returns (uint256[] memory);

    /**
     * @dev Grants or revokes permission to `operator` to transfer the caller's tokens, according to `approved`,
     *
     * Emits an {ApprovalForAll} event.
     *
     * Requirements:
     *
     * - `operator` cannot be the caller.
     */
    function setApprovalForAll(address operator, bool approved) external;

    /**
     * @dev Returns true if `operator` is approved to transfer ``account``'s tokens.
     *
     * See {setApprovalForAll}.
     */
    function isApprovedForAll(address account, address operator) external view returns (bool);

    /**
     * @dev Transfers `amount` tokens of token type `id` from `from` to `to`.
     *
     * Emits a {TransferSingle} event.
     *
     * Requirements:
     *
     * - `to` cannot be the zero address.
     * - If the caller is not `from`, it must have been approved to spend ``from``'s tokens via {setApprovalForAll}.
     * - `from` must have a balance of tokens of type `id` of at least `amount`.
     * - If `to` refers to a smart contract, it must implement {IERC1155Receiver-onERC1155Received} and return the
     * acceptance magic value.
     */
    function safeTransferFrom(
        address from,
        address to,
        uint256 id,
        uint256 amount,
        bytes calldata data
    ) external;

    /**
     * @dev xref:ROOT:erc1155.adoc#batch-operations[Batched] version of {safeTransferFrom}.
     *
     * Emits a {TransferBatch} event.
     *
     * Requirements:
     *
     * - `ids` and `amounts` must have the same length.
     * - If `to` refers to a smart contract, it must implement {IERC1155Receiver-onERC1155BatchReceived} and return the
     * acceptance magic value.
     */
    function safeBatchTransferFrom(
        address from,
        address to,
        uint256[] calldata ids,
        uint256[] calldata amounts,
        bytes calldata data
    ) external;
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

import "@openzeppelin/contracts/token/ERC1155/IERC1155.sol";
import "./interfaces/IDisperseErc1155.sol";

/**
 * @title DisperseErc1155
 * @author Tim Loh
 */
contract DisperseErc1155 is IDisperseErc1155 {
    function disperseErc1155ByTokenTypeIds(address token, address[] calldata recipients, uint256[][] calldata tokenTypeIds, uint256[][] calldata values) external override {
        require(token != address(0), "Disperse: token");
        require(recipients.length > 0, "Disperse: length");
        require(recipients.length == tokenTypeIds.length, "Disperse: diff type len");
        require(recipients.length == values.length, "Disperse: diff value len");

        emit Erc1155DispersedByTokenTypeIds(token, recipients.length);

        for (uint256 i = 0; i < recipients.length; ++i) {
            require(recipients[i] != address(0), "Disperse: recipient");
            require(tokenTypeIds[i].length > 0, "Disperse: token type len");

            // https://github.com/crytic/slither/wiki/Detector-Documentation/#calls-inside-a-loop
            // slither-disable-next-line calls-loop
            IERC1155(token).safeBatchTransferFrom(msg.sender, recipients[i], tokenTypeIds[i], values[i], "");
        }
    }

    function disperseErc1155Consecutively(address token, uint256 startTokenTypeId, address[] calldata recipients, uint256[] calldata quantities) external override {
        require(token != address(0), "Disperse: token");
        require(recipients.length > 0, "Disperse: length");
        require(recipients.length == quantities.length, "Disperse: diff len");

        uint256[][] memory tokenTypeIds = new uint256[][](recipients.length);
        uint256[][] memory values = new uint256[][](recipients.length);

        uint currentTokenTypeId = startTokenTypeId;
        uint256 total = 0;
        for (uint256 i = 0; i < recipients.length; ++i) {
            require(recipients[i] != address(0), "Disperse: recipient");
            require(quantities[i] != 0, "Disperse: value");

            tokenTypeIds[i] = new uint256[](quantities[i]);
            values[i] = new uint256[](quantities[i]);

            for (uint256 j = 0; j < quantities[i]; j++) {
                tokenTypeIds[i][j] = currentTokenTypeId++;
                values[i][j] = 1;
            }

            total += quantities[i];
        }

        emit Erc1155DispersedConsecutively(token, startTokenTypeId, total, recipients.length);

        for (uint256 i = 0; i < recipients.length; ++i) {
            // https://github.com/crytic/slither/wiki/Detector-Documentation/#calls-inside-a-loop
            // slither-disable-next-line calls-loop
            IERC1155(token).safeBatchTransferFrom(msg.sender, recipients[i], tokenTypeIds[i], values[i], "");
        }
    }
}

// SPDX-License-Identifier: Apache-2.0
// Copyright 2023 Enjinstarter
pragma solidity ^0.8.0;

/**
 * @title DisperseErc1155 Interface
 * @author Tim Loh
 * @notice Interface for DisperseErc1155 where ERC-1155 NFTs will be dispersed to multiple recipients
 */
interface IDisperseErc1155 {
    /**
     * @notice Emitted when ERC-1155 NFTs have been successfully dispersed by token type IDs
     * @param token ERC-1155 token address
     * @param numRecipients Total number of recipients
     */
    event Erc1155DispersedByTokenTypeIds(
        address indexed token,
        uint256 numRecipients
    );

    /**
     * @notice Emitted when ERC-1155 NFTs have been successfully dispersed consecutively starting from `startTokenTypeId`
     * @param token ERC-1155 token address
     * @param startTokenTypeId Starting token type identifier for NFT to transfer
     * @param total Total amount transferred
     * @param numRecipients Total number of recipients
     */
    event Erc1155DispersedConsecutively(
        address indexed token,
        uint256 startTokenTypeId,
        uint256 total,
        uint256 numRecipients
    );

    function disperseErc1155ByTokenTypeIds(address token, address[] calldata recipients, uint256[][] calldata tokenTypeIds, uint256[][] calldata values) external;

    function disperseErc1155Consecutively(address token, uint256 startTokenTypeId, address[] calldata recipients, uint256[] calldata values) external;
}