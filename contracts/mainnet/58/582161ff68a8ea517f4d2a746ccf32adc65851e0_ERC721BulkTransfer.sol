/**
 *Submitted for verification at Etherscan.io on 2022-02-24
*/

// Sources flattened with hardhat v2.8.4 https://hardhat.org

// File @openzeppelin/contracts/utils/introspection/[email protected]

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


// File @openzeppelin/contracts/token/ERC721/[email protected]

// OpenZeppelin Contracts v4.4.1 (token/ERC721/IERC721.sol)

pragma solidity ^0.8.0;

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
     * @dev Safely transfers `tokenId` token from `from` to `to`, checking first that contract recipients
     * are aware of the ERC721 protocol to prevent tokens from being forever locked.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `tokenId` token must exist and be owned by `from`.
     * - If the caller is not `from`, it must be have been allowed to move this token by either {approve} or {setApprovalForAll}.
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
     * WARNING: Usage of this method is discouraged, use {safeTransferFrom} whenever possible.
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
     * @dev Returns the account approved for `tokenId` token.
     *
     * Requirements:
     *
     * - `tokenId` must exist.
     */
    function getApproved(uint256 tokenId) external view returns (address operator);

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
     * @dev Returns if the `operator` is allowed to manage all of the assets of `owner`.
     *
     * See {setApprovalForAll}
     */
    function isApprovedForAll(address owner, address operator) external view returns (bool);

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
}


// File contracts/IERC721BulkTransfer.sol

pragma solidity 0.8.9;

/// @title ERC721 bulk transfer interface
/// @author https://github.com/gnkz
interface IERC721BulkTransfer {
    struct ToRecipient {
        address recipient;
        uint256 tokenId;
    }

    struct FromCollection {
        address collection;
        uint256 tokenId;
    }

    struct FromCollectionToRecipient {
        address collection;
        address recipient;
        uint256 tokenId;
    }

    /// @notice Transfer multiple tokens from a single ERC721 collection to a single recipient
    /// @param collection The address of the ERC721 contract
    /// @param recipient The recipient of the tokens
    /// @param tokenIds The array of token ids to be transferred
    function transfer(
        address collection,
        address recipient,
        uint256[] calldata tokenIds
    ) external;

    /// @notice Transfer multiple tokens from a single ERC721 collection to multiple recipients
    /// @param collection The address of the ERC721 contract
    /// @param recipientsData An array of { address recipient, uint256 tokenId }
    function transfer(address collection, ToRecipient[] calldata recipientsData)
        external;

    /// @notice Transfer multiple tokens from multiple ERC721 collections to a single recipient
    /// @param collectionsData An array of { address collection, uint256 tokenId }
    /// @param recipient The recipient of the tokens
    function transfer(
        FromCollection[] calldata collectionsData,
        address recipient
    ) external;

    /// @notice Transfer multiple tokens from multiple ERC721 collections to multiple recipients
    /// @param transferData An array of { address collection, address recipient, uint256 tokenId }
    function transfer(FromCollectionToRecipient[] calldata transferData)
        external;
}


// File contracts/ERC721BulkTransfer.sol

pragma solidity 0.8.9;


/// @title ERC721 tokens bulk transfer
/// @author https://github.com/gnkz
/// @notice This smart contract allows to transfer multiple ERC721 tokens at once
/// @dev The contract needs approvals for the tokens that are going to be transferred
contract ERC721BulkTransfer is IERC721BulkTransfer {
    /// @inheritdoc     IERC721BulkTransfer
    function transfer(
        address collection,
        address recipient,
        uint256[] calldata tokenIds
    ) external {
        require(tokenIds.length > 0, "Invalid token ids amount");

        for (uint256 i = 0; i < tokenIds.length; i++) {
            uint256 tokenId = tokenIds[i];
            IERC721(collection).transferFrom(msg.sender, recipient, tokenId);
        }
    }

    /// @inheritdoc     IERC721BulkTransfer
    function transfer(address collection, ToRecipient[] calldata recipientsData)
        external
    {
        require(recipientsData.length > 0, "Empty recipients data");

        for (uint256 i = 0; i < recipientsData.length; i++) {
            uint256 tokenId = recipientsData[i].tokenId;
            address recipient = recipientsData[i].recipient;

            IERC721(collection).transferFrom(msg.sender, recipient, tokenId);
        }
    }

    /// @inheritdoc     IERC721BulkTransfer
    function transfer(
        FromCollection[] calldata collectionsData,
        address recipient
    ) external {
        require(collectionsData.length > 0, "Empty collections data");

        for (uint256 i = 0; i < collectionsData.length; i++) {
            uint256 tokenId = collectionsData[i].tokenId;
            address collection = collectionsData[i].collection;

            IERC721(collection).transferFrom(msg.sender, recipient, tokenId);
        }
    }

    /// @inheritdoc     IERC721BulkTransfer
    function transfer(FromCollectionToRecipient[] calldata transferData)
        external
    {
        require(transferData.length > 0, "Empty transfer data");

        for (uint256 i = 0; i < transferData.length; i++) {
            uint256 tokenId = transferData[i].tokenId;
            address collection = transferData[i].collection;
            address recipient = transferData[i].recipient;

            IERC721(collection).transferFrom(msg.sender, recipient, tokenId);
        }
    }
}