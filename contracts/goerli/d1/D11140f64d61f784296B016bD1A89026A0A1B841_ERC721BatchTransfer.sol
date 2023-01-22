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

// SPDX-License-Identifier: UNLICENSED
pragma solidity >=0.8.4;

import "@openzeppelin/contracts/token/ERC721/IERC721.sol";

/// @title ERC721 Batch Transfer
/// @author Aleph Retamal (https://github.com/alephao)
/// @notice Transfer ERC721 tokens in batches to a single wallet or multiple wallets.
/// @notice To use any of the methods in this contract the user has to approve this contract
///         to control their tokens using either `setApproveForAll` or `approve` functions from
//          the ERC721 contract.
contract ERC721BatchTransfer {
    /// @dev 0x5f6f132c
    error InvalidArguments();
    /// @dev 0x4c084f14
    error NotOwnerOfToken();
    /// @dev 0x48f5c3ed
    error InvalidCaller();

    event BatchTransferToSingle(
        address indexed contractAddress,
        address indexed to,
        uint256 amount
    );

    event BatchTransferToMultiple(
        address indexed contractAddress,
        uint256 amount
    );

    // solhint-disable-next-line no-empty-blocks
    constructor() {}

    modifier noZero() {
        if (msg.sender == address(0)) revert InvalidCaller();
        _;
    }

    /// @notice Transfer multiple tokens to the same wallet using the ERC721.transferFrom method
    /// @notice If you don't know what that means, use the `safeBatchTransferToSingleWallet` method instead
    /// @param erc721Contract the address of the nft contract
    /// @param to the address that will receive the nfts
    /// @param tokenIds the list of tokens that will be transferred
    function batchTransferToSingleWallet(
        IERC721 erc721Contract,
        address to,
        uint256[] calldata tokenIds
    ) external noZero {
        uint256 length = tokenIds.length;
        for (uint256 i; i < length; ) {
            uint256 tokenId = tokenIds[i];
            address owner = erc721Contract.ownerOf(tokenId);
            if (msg.sender != owner) {
                revert NotOwnerOfToken();
            }
            erc721Contract.transferFrom(owner, to, tokenId);
            unchecked {
                ++i;
            }
        }
        emit BatchTransferToSingle(address(erc721Contract), to, length);
    }

    /// @notice transfer multiple tokens to the same wallet using the `ERC721.safeTransferFrom` method
    /// @param erc721Contract the address of the nft contract
    /// @param to the address that will receive the nfts
    /// @param tokenIds the list of tokens that will be transferred
    function safeBatchTransferToSingleWallet(
        IERC721 erc721Contract,
        address to,
        uint256[] calldata tokenIds
    ) external noZero {
        uint256 length = tokenIds.length;
        for (uint256 i; i < length; ) {
            uint256 tokenId = tokenIds[i];
            address owner = erc721Contract.ownerOf(tokenId);
            if (msg.sender != owner) {
                revert NotOwnerOfToken();
            }
            erc721Contract.safeTransferFrom(owner, to, tokenId);
            unchecked {
                ++i;
            }
        }
        emit BatchTransferToSingle(address(erc721Contract), to, length);
    }

    /// @notice Transfer multiple tokens to multiple wallets using the ERC721.transferFrom method
    /// @notice If you don't know what that means, use the `safeBatchTransferToMultipleWallets` method instead
    /// @notice The tokens in `tokenIds` will be transferred to the addresses in the same position in `tos`
    /// @notice E.g.: if tos = [0x..1, 0x..2, 0x..3] and tokenIds = [1, 2, 3], then:
    ///         0x..1 will receive token 1;
    ///         0x..2 will receive token 2;
    //          0x..3 will receive token 3;
    /// @param erc721Contract the address of the nft contract
    /// @param tos the list of addresses that will receive the nfts
    /// @param tokenIds the list of tokens that will be transferred
    function batchTransferToMultipleWallets(
        IERC721 erc721Contract,
        address[] calldata tos,
        uint256[] calldata tokenIds
    ) external noZero {
        uint256 length = tokenIds.length;
        if (tos.length != length) revert InvalidArguments();

        for (uint256 i; i < length; ) {
            uint256 tokenId = tokenIds[i];
            address owner = erc721Contract.ownerOf(tokenId);
            address to = tos[i];
            if (msg.sender != owner) {
                revert NotOwnerOfToken();
            }
            erc721Contract.transferFrom(owner, to, tokenId);
            unchecked {
                ++i;
            }
        }

        emit BatchTransferToMultiple(address(erc721Contract), length);
    }

    /// @notice Transfer multiple tokens to multiple wallets using the ERC721.safeTransferFrom method
    /// @notice The tokens in `tokenIds` will be transferred to the addresses in the same position in `tos`
    /// @notice E.g.: if tos = [0x..1, 0x..2, 0x..3] and tokenIds = [1, 2, 3], then:
    ///         0x..1 will receive token 1;
    ///         0x..2 will receive token 2;
    //          0x..3 will receive token 3;
    /// @param erc721Contract the address of the nft contract
    /// @param tos the list of addresses that will receive the nfts
    /// @param tokenIds the list of tokens that will be transferred
    function safeBatchTransferToMultipleWallets(
        IERC721 erc721Contract,
        address[] calldata tos,
        uint256[] calldata tokenIds
    ) external noZero {
        uint256 length = tokenIds.length;
        if (tos.length != length) revert InvalidArguments();

        for (uint256 i; i < length; ) {
            uint256 tokenId = tokenIds[i];
            address owner = erc721Contract.ownerOf(tokenId);
            address to = tos[i];
            if (msg.sender != owner) {
                revert NotOwnerOfToken();
            }
            erc721Contract.safeTransferFrom(owner, to, tokenId);
            unchecked {
                ++i;
            }
        }

        emit BatchTransferToMultiple(address(erc721Contract), length);
    }
}