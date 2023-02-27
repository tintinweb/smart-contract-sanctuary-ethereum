// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import "./interfaces/IERC721PoolFactory.sol";
import "./interfaces/IERC721Pool.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721.sol";

contract PoolSwap {
    IERC721PoolFactory POOL_FACTORY = IERC721PoolFactory(0xb67dc4B5A296C3068E8eEc16f02CdaE4c9A255e5);

    error ArrayLengthMismatch();
    error NoTokensSent();
    error PoolDoesNotExist();

    function swapTokens(address collectionAddress, uint256[] calldata tokensToSend, uint256[] calldata tokensToReceive) external {
        address poolAddress = POOL_FACTORY.getPool(collectionAddress);

        if(tokensToSend.length != tokensToReceive.length) { revert ArrayLengthMismatch(); }
        if(tokensToSend.length == 0) { revert NoTokensSent(); }
        if(poolAddress == address(0)) { revert PoolDoesNotExist(); }

        IERC721 nftContract = IERC721(collectionAddress);
        IERC721Pool nftPool = IERC721Pool(poolAddress);

        if(!nftContract.isApprovedForAll(address(this), poolAddress)) {
            nftContract.setApprovalForAll(poolAddress, true);
        }

        for(uint256 i = 0;i < tokensToReceive.length;) {
            nftContract.transferFrom(msg.sender, address(this), tokensToSend[i]);
            unchecked {
                ++i;
            }
        }

        nftPool.deposit(tokensToSend);
        nftPool.withdraw(tokensToReceive);

        for(uint256 i = 0;i < tokensToReceive.length;) {
            nftContract.transferFrom(address(this), msg.sender, tokensToReceive[i]);
            unchecked {
                ++i;
            }
        }
    }
}

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

// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity >=0.8.4;

/// @title IERC721Pool
/// @author Hifi
interface IERC721Pool {
    /// CUSTOM ERRORS ///

    error ERC721Pool__InsufficientIn();
    error ERC721Pool__InvalidTo();

    /// EVENTS ///

    /// @notice Emitted when NFTs are deposited and an equal amount of pool tokens are minted.
    /// @param ids The asset token IDs sent from the user's account to the pool.
    /// @param caller The caller of the function equal to msg.sender
    event Deposit(uint256[] ids, address caller);

    /// @notice Emitted when NFTs are withdrawn from the pool in exchange for an equal amount of pool tokens.
    /// @param ids The asset token IDs released from the pool.
    /// @param caller The caller of the function equal to msg.sender
    event Withdraw(uint256[] ids, address caller);

    /// CONSTANT FUNCTIONS ///

    /// @notice Returns the asset token ID held at index.
    /// @param index The index to check.
    function holdingAt(uint256 index) external view returns (uint256);

    /// @notice Returns the total number of asset token IDs held.
    function holdingsLength() external view returns (uint256);

    /// NON-CONSTANT FUNCTIONS ///

    /// @notice Deposit NFTs in exchange for an equivalent amount of pool tokens.
    ///
    /// @dev Emits a {Deposit} event.
    ///
    /// @dev Requirements:
    ///
    /// - The length of `ids` must be greater than zero.
    /// - The length of `ids` scaled to 18 decimals.
    /// - The address `to` must not be the zero address.
    ///
    /// @param ids The asset token IDs sent from the user's account to the pool.
    function deposit(uint256[] calldata ids) external;

    /// @notice Withdraw specified NFTs in exchange for an equivalent amount of pool tokens.
    ///
    /// @dev Emits a {Withdraw} event.
    ///
    /// @dev Requirements:
    ///
    /// - The length of `ids` must be greater than zero.
    /// - The length of `ids` scaled to 18 decimals.
    /// - The address `to` must not be the zero address.
    ///
    /// @param ids The asset token IDs to be released from the pool.
    function withdraw(uint256[] calldata ids) external;

    /// @notice Withdraw specified NFTs in exchange for an equivalent amount of pool tokens.
    ///
    /// @dev Emits a {Withdraw} event.
    ///
    /// @dev Requirements:
    /// - The `signature` must be a valid signed approval given by the caller to the ERC721Pool to spend pool tokens
    ///   equal to the length of the ids array for the given `deadline` and the caller's current nonce.
    /// - The length of `ids` must be greater than zero.
    /// - The length of `ids` scaled to 18 decimals.
    /// - The address `to` must not be the zero address.
    ///
    /// @param ids The asset token IDs to be released from the pool.
    /// @param deadline The deadline beyond which the signature is not valid anymore.
    /// @param signature The packed signature for ERC721Pool.
    function withdrawWithSignature(
        uint256[] calldata ids,
        uint256 deadline,
        bytes memory signature
    ) external;
}

// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity >=0.8.4;

/// @title IERC721PoolFactory
/// @author Hifi
interface IERC721PoolFactory {
    /// CUSTOM ERRORS ///

    error ERC721PoolFactory__DoesNotImplementIERC721Metadata();
    error ERC721PoolFactory__PoolAlreadyExists();

    /// EVENTS ///

    /// @notice Emitted when a new pool is created.
    /// @param name The ERC-20 name of the pool.
    /// @param symbol The ERC-20 symbol of the pool.
    /// @param asset The underlying ERC-721 asset contract address.
    /// @param pool The created pool contract address.
    event CreatePool(string name, string symbol, address indexed asset, address indexed pool);

    /// CONSTANT FUNCTIONS ///

    /// @notice Returns the pool of the given asset token.
    /// @param asset The underlying ERC-721 asset contract address.
    function getPool(address asset) external view returns (address pool);

    /// @notice Returns the list of all pools.
    function allPools(uint256) external view returns (address pool);

    /// @notice Returns the length of the pools list.
    function allPoolsLength() external view returns (uint256);

    /// NON-CONSTANT FUNCTIONS ///

    /// @notice Create a new pool.
    ///
    /// @dev Emits a {CreatePool} event.
    ///
    /// @dev Requirements:
    /// - Can only create one pool per asset.
    ///
    /// @param asset The underlying ERC-721 asset contract address.
    function createPool(address asset) external;
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