// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (access/Ownable.sol)

pragma solidity ^0.8.0;

import "../utils/Context.sol";

/**
 * @dev Contract module which provides a basic access control mechanism, where
 * there is an account (an owner) that can be granted exclusive access to
 * specific functions.
 *
 * By default, the owner account will be the one that deploys the contract. This
 * can later be changed with {transferOwnership}.
 *
 * This module is used through inheritance. It will make available the modifier
 * `onlyOwner`, which can be applied to your functions to restrict their use to
 * the owner.
 */
abstract contract Ownable is Context {
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    /**
     * @dev Initializes the contract setting the deployer as the initial owner.
     */
    constructor() {
        _transferOwnership(_msgSender());
    }

    /**
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        _checkOwner();
        _;
    }

    /**
     * @dev Returns the address of the current owner.
     */
    function owner() public view virtual returns (address) {
        return _owner;
    }

    /**
     * @dev Throws if the sender is not the owner.
     */
    function _checkOwner() internal view virtual {
        require(owner() == _msgSender(), "Ownable: caller is not the owner");
    }

    /**
     * @dev Leaves the contract without owner. It will not be possible to call
     * `onlyOwner` functions anymore. Can only be called by the current owner.
     *
     * NOTE: Renouncing ownership will leave the contract without an owner,
     * thereby removing any functionality that is only available to the owner.
     */
    function renounceOwnership() public virtual onlyOwner {
        _transferOwnership(address(0));
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        _transferOwnership(newOwner);
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Internal function without access restriction.
     */
    function _transferOwnership(address newOwner) internal virtual {
        address oldOwner = _owner;
        _owner = newOwner;
        emit OwnershipTransferred(oldOwner, newOwner);
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.8.0) (security/ReentrancyGuard.sol)

pragma solidity ^0.8.0;

/**
 * @dev Contract module that helps prevent reentrant calls to a function.
 *
 * Inheriting from `ReentrancyGuard` will make the {nonReentrant} modifier
 * available, which can be applied to functions to make sure there are no nested
 * (reentrant) calls to them.
 *
 * Note that because there is a single `nonReentrant` guard, functions marked as
 * `nonReentrant` may not call one another. This can be worked around by making
 * those functions `private`, and then adding `external` `nonReentrant` entry
 * points to them.
 *
 * TIP: If you would like to learn more about reentrancy and alternative ways
 * to protect against it, check out our blog post
 * https://blog.openzeppelin.com/reentrancy-after-istanbul/[Reentrancy After Istanbul].
 */
abstract contract ReentrancyGuard {
    // Booleans are more expensive than uint256 or any type that takes up a full
    // word because each write operation emits an extra SLOAD to first read the
    // slot's contents, replace the bits taken up by the boolean, and then write
    // back. This is the compiler's defense against contract upgrades and
    // pointer aliasing, and it cannot be disabled.

    // The values being non-zero value makes deployment a bit more expensive,
    // but in exchange the refund on every call to nonReentrant will be lower in
    // amount. Since refunds are capped to a percentage of the total
    // transaction's gas, it is best to keep them low in cases like this one, to
    // increase the likelihood of the full refund coming into effect.
    uint256 private constant _NOT_ENTERED = 1;
    uint256 private constant _ENTERED = 2;

    uint256 private _status;

    constructor() {
        _status = _NOT_ENTERED;
    }

    /**
     * @dev Prevents a contract from calling itself, directly or indirectly.
     * Calling a `nonReentrant` function from another `nonReentrant`
     * function is not supported. It is possible to prevent this from happening
     * by making the `nonReentrant` function external, and making it call a
     * `private` function that does the actual work.
     */
    modifier nonReentrant() {
        _nonReentrantBefore();
        _;
        _nonReentrantAfter();
    }

    function _nonReentrantBefore() private {
        // On the first call to nonReentrant, _status will be _NOT_ENTERED
        require(_status != _ENTERED, "ReentrancyGuard: reentrant call");

        // Any calls to nonReentrant after this point will fail
        _status = _ENTERED;
    }

    function _nonReentrantAfter() private {
        // By storing the original value once again, a refund is triggered (see
        // https://eips.ethereum.org/EIPS/eip-2200)
        _status = _NOT_ENTERED;
    }
}

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
// OpenZeppelin Contracts (last updated v4.5.0) (token/ERC1155/IERC1155Receiver.sol)

pragma solidity ^0.8.0;

import "../../utils/introspection/IERC165.sol";

/**
 * @dev _Available since v3.1._
 */
interface IERC1155Receiver is IERC165 {
    /**
     * @dev Handles the receipt of a single ERC1155 token type. This function is
     * called at the end of a `safeTransferFrom` after the balance has been updated.
     *
     * NOTE: To accept the transfer, this must return
     * `bytes4(keccak256("onERC1155Received(address,address,uint256,uint256,bytes)"))`
     * (i.e. 0xf23a6e61, or its own function selector).
     *
     * @param operator The address which initiated the transfer (i.e. msg.sender)
     * @param from The address which previously owned the token
     * @param id The ID of the token being transferred
     * @param value The amount of tokens being transferred
     * @param data Additional data with no specified format
     * @return `bytes4(keccak256("onERC1155Received(address,address,uint256,uint256,bytes)"))` if transfer is allowed
     */
    function onERC1155Received(
        address operator,
        address from,
        uint256 id,
        uint256 value,
        bytes calldata data
    ) external returns (bytes4);

    /**
     * @dev Handles the receipt of a multiple ERC1155 token types. This function
     * is called at the end of a `safeBatchTransferFrom` after the balances have
     * been updated.
     *
     * NOTE: To accept the transfer(s), this must return
     * `bytes4(keccak256("onERC1155BatchReceived(address,address,uint256[],uint256[],bytes)"))`
     * (i.e. 0xbc197c81, or its own function selector).
     *
     * @param operator The address which initiated the batch transfer (i.e. msg.sender)
     * @param from The address which previously owned the token
     * @param ids An array containing ids of each token being transferred (order and length must match values array)
     * @param values An array containing amounts of each token being transferred (order and length must match ids array)
     * @param data Additional data with no specified format
     * @return `bytes4(keccak256("onERC1155BatchReceived(address,address,uint256[],uint256[],bytes)"))` if transfer is allowed
     */
    function onERC1155BatchReceived(
        address operator,
        address from,
        uint256[] calldata ids,
        uint256[] calldata values,
        bytes calldata data
    ) external returns (bytes4);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.5.0) (token/ERC1155/utils/ERC1155Holder.sol)

pragma solidity ^0.8.0;

import "./ERC1155Receiver.sol";

/**
 * Simple implementation of `ERC1155Receiver` that will allow a contract to hold ERC1155 tokens.
 *
 * IMPORTANT: When inheriting this contract, you must include a way to use the received tokens, otherwise they will be
 * stuck.
 *
 * @dev _Available since v3.1._
 */
contract ERC1155Holder is ERC1155Receiver {
    function onERC1155Received(
        address,
        address,
        uint256,
        uint256,
        bytes memory
    ) public virtual override returns (bytes4) {
        return this.onERC1155Received.selector;
    }

    function onERC1155BatchReceived(
        address,
        address,
        uint256[] memory,
        uint256[] memory,
        bytes memory
    ) public virtual override returns (bytes4) {
        return this.onERC1155BatchReceived.selector;
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (token/ERC1155/utils/ERC1155Receiver.sol)

pragma solidity ^0.8.0;

import "../IERC1155Receiver.sol";
import "../../../utils/introspection/ERC165.sol";

/**
 * @dev _Available since v3.1._
 */
abstract contract ERC1155Receiver is ERC165, IERC1155Receiver {
    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId) public view virtual override(ERC165, IERC165) returns (bool) {
        return interfaceId == type(IERC1155Receiver).interfaceId || super.supportsInterface(interfaceId);
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.6.0) (token/ERC20/IERC20.sol)

pragma solidity ^0.8.0;

/**
 * @dev Interface of the ERC20 standard as defined in the EIP.
 */
interface IERC20 {
    /**
     * @dev Emitted when `value` tokens are moved from one account (`from`) to
     * another (`to`).
     *
     * Note that `value` may be zero.
     */
    event Transfer(address indexed from, address indexed to, uint256 value);

    /**
     * @dev Emitted when the allowance of a `spender` for an `owner` is set by
     * a call to {approve}. `value` is the new allowance.
     */
    event Approval(address indexed owner, address indexed spender, uint256 value);

    /**
     * @dev Returns the amount of tokens in existence.
     */
    function totalSupply() external view returns (uint256);

    /**
     * @dev Returns the amount of tokens owned by `account`.
     */
    function balanceOf(address account) external view returns (uint256);

    /**
     * @dev Moves `amount` tokens from the caller's account to `to`.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transfer(address to, uint256 amount) external returns (bool);

    /**
     * @dev Returns the remaining number of tokens that `spender` will be
     * allowed to spend on behalf of `owner` through {transferFrom}. This is
     * zero by default.
     *
     * This value changes when {approve} or {transferFrom} are called.
     */
    function allowance(address owner, address spender) external view returns (uint256);

    /**
     * @dev Sets `amount` as the allowance of `spender` over the caller's tokens.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * IMPORTANT: Beware that changing an allowance with this method brings the risk
     * that someone may use both the old and the new allowance by unfortunate
     * transaction ordering. One possible solution to mitigate this race
     * condition is to first reduce the spender's allowance to 0 and set the
     * desired value afterwards:
     * https://github.com/ethereum/EIPs/issues/20#issuecomment-263524729
     *
     * Emits an {Approval} event.
     */
    function approve(address spender, uint256 amount) external returns (bool);

    /**
     * @dev Moves `amount` tokens from `from` to `to` using the
     * allowance mechanism. `amount` is then deducted from the caller's
     * allowance.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transferFrom(
        address from,
        address to,
        uint256 amount
    ) external returns (bool);
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

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/Context.sol)

pragma solidity ^0.8.0;

/**
 * @dev Provides information about the current execution context, including the
 * sender of the transaction and its data. While these are generally available
 * via msg.sender and msg.data, they should not be accessed in such a direct
 * manner, since when dealing with meta-transactions the account sending and
 * paying for execution may not be the actual sender (as far as an application
 * is concerned).
 *
 * This contract is only required for intermediate, library-like contracts.
 */
abstract contract Context {
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes calldata) {
        return msg.data;
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/introspection/ERC165.sol)

pragma solidity ^0.8.0;

import "./IERC165.sol";

/**
 * @dev Implementation of the {IERC165} interface.
 *
 * Contracts that want to implement ERC165 should inherit from this contract and override {supportsInterface} to check
 * for the additional interface id that will be supported. For example:
 *
 * ```solidity
 * function supportsInterface(bytes4 interfaceId) public view virtual override returns (bool) {
 *     return interfaceId == type(MyInterface).interfaceId || super.supportsInterface(interfaceId);
 * }
 * ```
 *
 * Alternatively, {ERC165Storage} provides an easier to use but more expensive implementation.
 */
abstract contract ERC165 is IERC165 {
    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId) public view virtual override returns (bool) {
        return interfaceId == type(IERC165).interfaceId;
    }
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
pragma solidity ^0.8.11;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC1155/IERC1155.sol";
import "@openzeppelin/contracts/token/ERC1155/utils/ERC1155Holder.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";

contract ARBOBCTFaucet is ERC1155Holder, Ownable, ReentrancyGuard {
    // Address of the Artifacts (ERC1155) Contract
    IERC1155 public artifactsContract;
    // The fee to access the FanFaucet (FAF)
    uint256 public ethPrice;
    // The array of token ids that are in the inventory
    uint256[] public tokenIdsInventory;
    // The iteration of the FanFaucet campaign, allowing for reuse while restricting free withdrawals to numOfFreeRequestsAllowed
    uint256 public campaignId;
    // Number of free requests without FAF per wallet
    uint256 public numOfFreeRequestsAllowed;
    // Number of total requests allowed from the FanFaucet with and without FAF
    uint256 public numOfTotalRequestsAllowed;
    // List of whitelisted ERC token addresses for FanFaucet collabs
    address[] public whitelistedTokenAddressList;
    // Indicates if the FanFaucet is online or offlne
    bool public isOnline = false;

    // Map of whitelisted ERC token address and their details
    struct WhitelistToken {
        string standard;
        uint256[] tokenIdsArray;
        uint256[] amountsArray; // in decimal units as defined by the contract
        bool active;
    }

    mapping(address => WhitelistToken) public whitelistedTokens;

    // Map of wallet addresses and total FanFaucet requests per campaignId
    mapping(address => mapping(uint256 => uint256)) public withdrawn;

    // Events
    event FanFaucetWithdraw(address userAddress, uint256 tokenId);

    // Errors
    // Already used allotted free requests
    error AlreadyWithdrawnFree();
    // Already used allotted total requests
    error TooManyWithdrawn(uint256 withdrawnAmount);
    // FanFaucet is offline
    error FaucetOffline();
    // Nothing to claim
    error ContractBalanceEmpty();
    // Incorrect FanFaucet Access Fee
    error WrongEthAmountSent(uint256 ethAmount);
    // External seed not provided
    error EmptySeed();
    // Unsupported standard
    error WrongStandard();
    // Details on the collab tokens doesn't exist
    error TokenStructDoesNotExist();
    // Not whitelisted
    error NotEnoughWhitelistedTokens();

    // Constructoooor
    constructor(address _artifactsContract, uint256 _campaignId) {
        artifactsContract = IERC1155(_artifactsContract);
        campaignId = _campaignId;
    }

    function fanFaucetClaim(string calldata _randomSeed) external payable nonReentrant {
        if (isOnline == false) revert FaucetOffline();
        if (bytes(_randomSeed).length == 0) revert EmptySeed();
        // Check if the caller has already withdrawn more than the total allowed amount
        if (withdrawn[msg.sender][campaignId] >= numOfTotalRequestsAllowed)
            revert TooManyWithdrawn(withdrawn[msg.sender][campaignId]);
        // Check if we need to collect payment, by checking if total withdrawn is >= numOfFreeRequestsAllowed
        if (withdrawn[msg.sender][campaignId] >= numOfFreeRequestsAllowed && msg.value != ethPrice)
            revert WrongEthAmountSent(msg.value);
        // Check if tokens are required to access the Faucet
        if (whitelistedTokenAddressList.length > 0) {
            bool accessGranted = false;

            if (whitelistedTokenAddressList.length == 1) {
                accessGranted = checkWhitelistedTokens(0);
            } else {
                for (uint256 i = 0; i < whitelistedTokenAddressList.length; i++) {
                    accessGranted = checkWhitelistedTokens(i);
                    if (accessGranted) break;
                }
            }
            if (!accessGranted) revert NotEnoughWhitelistedTokens();
        }

        // Generate a random number using keccak256
        uint256 randomNumber = uint256(
            keccak256(
                abi.encodePacked(
                    block.timestamp,
                    block.difficulty,
                    msg.sender,
                    _randomSeed,
                    withdrawn[msg.sender][campaignId]
                )
            )
        );

        // Generate a random number within the range of the token ids array length
        uint256 randomIndex = randomNumber % (tokenIdsInventory.length);

        uint256 availableTokenId = findTokenWithBalance(randomIndex);

        // Withdraw 1 ERC1155 token from the contract
        withdrawn[msg.sender][campaignId] = withdrawn[msg.sender][campaignId] + 1;
        artifactsContract.safeTransferFrom(address(this), msg.sender, availableTokenId, 1, "");
        emit FanFaucetWithdraw(msg.sender, availableTokenId);
    }

    function checkWhitelistedTokens(uint256 _index) private view returns (bool access) {
        address tokenAddress = whitelistedTokenAddressList[_index];
        WhitelistToken memory tokenStruct = whitelistedTokens[tokenAddress];

        if (keccak256(abi.encodePacked(tokenStruct.standard)) == keccak256(abi.encodePacked("erc20"))) {
            if (IERC20(tokenAddress).balanceOf(msg.sender) >= tokenStruct.amountsArray[0]) return true;
        }

        if (keccak256(abi.encodePacked(tokenStruct.standard)) == keccak256(abi.encodePacked("erc721"))) {
            for (uint256 i = 0; i < tokenStruct.tokenIdsArray.length; i++) {
                if (IERC721(tokenAddress).ownerOf(tokenStruct.tokenIdsArray[i]) == msg.sender) return true;
            }
        }

        if (keccak256(abi.encodePacked(tokenStruct.standard)) == keccak256(abi.encodePacked("erc1155"))) {
            for (uint256 i = 0; i < tokenStruct.tokenIdsArray.length; i++) {
                if (
                    IERC1155(tokenAddress).balanceOf(msg.sender, tokenStruct.tokenIdsArray[i]) >=
                    tokenStruct.amountsArray[i]
                ) return true;
            }
        }

        return false;
    }

    function findTokenWithBalance(uint256 _randomIndex) private view returns (uint256 availableTokenId) {
        if (artifactsContract.balanceOf(address(this), tokenIdsInventory[_randomIndex]) > 0) {
            return tokenIdsInventory[_randomIndex];
        }

        uint256 newIndex = _randomIndex + 1;

        for (uint256 i = 0; i < tokenIdsInventory.length; i++) {
            if (newIndex > tokenIdsInventory.length) {
                newIndex = 0;
            }

            if (newIndex == _randomIndex) revert ContractBalanceEmpty();

            if (artifactsContract.balanceOf(address(this), tokenIdsInventory[newIndex]) > 0) {
                return tokenIdsInventory[newIndex];
            }

            newIndex = newIndex + 1;
        }
    }

    // External views
    function getTokenIdsInventory() external view returns (uint256[] memory) {
        return tokenIdsInventory;
    }

    function getTotalClaims(address _userAddress, uint256 _campaignId) external view returns (uint256) {
        return withdrawn[_userAddress][_campaignId];
    }

    function getWhitelistedTokenAddressList() external view returns (address[] memory) {
        return whitelistedTokenAddressList;
    }

    function getWhitelistedTokenDetails(address _contractAddress) external view returns (WhitelistToken memory) {
        return whitelistedTokens[_contractAddress];
    }

    // Owner controls
    function enableFaucet() external onlyOwner {
        isOnline = true;
    }

    function disableFaucet() external onlyOwner {
        isOnline = false;
    }

    function setTokenIdsInventory(uint256[] calldata _tokenIds) external onlyOwner {
        tokenIdsInventory = _tokenIds;
    }

    function setNumOfTotalRequestsAllowed(uint256 _totalAllowed) external onlyOwner {
        numOfTotalRequestsAllowed = _totalAllowed;
    }

    function setNumOfFreeRequestsAllowed(uint256 _freeAllowed) external onlyOwner {
        numOfFreeRequestsAllowed = _freeAllowed;
    }

    // Start a new campaign and fresh wallet claim record
    function setCampaignId(uint256 _campaignId) external onlyOwner {
        campaignId = _campaignId;
    }

    // FanFaucetAccessFee in wei
    function setFanFaucetAccessFee(uint256 _ethPrice) external onlyOwner {
        ethPrice = _ethPrice;
    }

    // Set WhitelistToken struct for every whitelist contract before adding to this array
    // This ensures the address list will always have corresponding structs in storage and one can be removed easily
    function setWhitelistedTokenAddressList(address[] calldata _whitelistedTokenAddressList) external onlyOwner {
        for (uint256 i = 0; i < _whitelistedTokenAddressList.length; i++) {
            address tokenAddress = _whitelistedTokenAddressList[i];
            WhitelistToken memory tokenStruct = whitelistedTokens[tokenAddress];

            if (!tokenStruct.active) revert TokenStructDoesNotExist();
        }

        whitelistedTokenAddressList = _whitelistedTokenAddressList;
    }

    function setWhitelistedTokenDetails(
        string calldata _tokenStandard,
        address _contractAddress,
        uint256[] calldata _tokenIds,
        uint256[] calldata _amounts
    ) external onlyOwner {
        if (
            keccak256(abi.encodePacked(_tokenStandard)) == keccak256(abi.encodePacked("erc20")) ||
            keccak256(abi.encodePacked(_tokenStandard)) == keccak256(abi.encodePacked("erc721")) ||
            keccak256(abi.encodePacked(_tokenStandard)) == keccak256(abi.encodePacked("erc1155"))
        ) {
            whitelistedTokens[_contractAddress].standard = _tokenStandard;
            whitelistedTokens[_contractAddress].tokenIdsArray = _tokenIds;
            whitelistedTokens[_contractAddress].amountsArray = _amounts;
            whitelistedTokens[_contractAddress].active = true;
        } else {
            revert WrongStandard();
        }
    }

    function removeWhitelistedToken(address[] calldata _contractAddresses) external onlyOwner {
        for (uint256 i = 0; i < _contractAddresses.length; i++) {
            delete whitelistedTokens[_contractAddresses[i]];
        }
    }

    function withdrawAll() external onlyOwner {
        uint256[] memory amountsArray = new uint256[](tokenIdsInventory.length);

        // Loop through all of the ERC-1155s owned by the contract
        for (uint256 i = 0; i < tokenIdsInventory.length; i++) {
            uint256 balance = artifactsContract.balanceOf(address(this), tokenIdsInventory[i]);
            amountsArray[i] = balance;
        }

        artifactsContract.safeBatchTransferFrom(address(this), owner(), tokenIdsInventory, amountsArray, "");
    }

    function withdrawSingleId(uint256 _tokenId) external onlyOwner {
        uint256 balance = artifactsContract.balanceOf(address(this), _tokenId);
        artifactsContract.safeTransferFrom(address(this), owner(), _tokenId, balance, "");
    }

    function withdrawEth() external onlyOwner {
        address payable to = payable(owner());
        to.transfer(address(this).balance);
    }

}