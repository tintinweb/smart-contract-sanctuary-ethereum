// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.9;
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "./Commissionable.sol";

    error FundraisingPools__InvalidPoolFundAmount(uint256 expectedAmount, uint256 payedAmount);
    error FundraisingPools__InvalidPoolId();
    error FundraisingPools__NotPoolOwner();
    // error FundraisingPools__InsufficientPoolFunds(uint256 currentAmount);
    error FundraisingPools__PoolDeadlinePassed(uint256 deadline);
    error FundraisingPools__PoolDeadlineNotPassed(uint256 deadline);
    error FundraisingPools__WithdrawFailed(uint256 poolId, address beneficiary);
    error FundraisingPools__PoolFundsWithdrawn();
    error FundraisingPools__PoolOwnerMustBeContributor();

contract FundraisingPools is Commissionable, ReentrancyGuard {
    // structures
    struct Pool {
        address creator;
        string  purpose;
        uint256 minAmount;
        uint256 minAmountPerContributor;
        uint256 deadline;
    }

    struct PoolRuntime {
        address owner;
        uint256 currentAmount;
        address[] contributors;
        mapping(address => uint256) contributorAmounts;
    }

    // events
    event PoolCreated(
        uint256 indexed poolId,
        address indexed creator,
        string purpose,
        uint256 minAmount,
        uint256 minAmountPerContributor,
        uint256 deadline,
        uint256 initialAmount
    );

    event PoolFunded(
        uint256 indexed poolId,
        address indexed contributor,
        uint256 amount
    );

    event PoolOwnerChanged(
        uint256 indexed poolId,
        address indexed oldOwner,
        address indexed newOwner
    );

    event PoolFundsWithdrawn(
        uint256 indexed poolId,
        address indexed sender,
        address indexed beneficiary,
        uint256 amount
    );

    // state variables
    uint256 private s_nextPoolId;
    mapping(uint256 => Pool) private s_pools;
    mapping(uint256 => PoolRuntime) private s_poolRuntimes;

    constructor(uint256 commissionRate, uint8 commissionRateDecimals)
        Commissionable(commissionRate, commissionRateDecimals)
    {}

    modifier poolExists(uint256 poolId) {
        if (s_pools[poolId].creator == address(0)) {
            revert FundraisingPools__InvalidPoolId();
        }
        _;
    }

    modifier poolWithdrawable(uint256 poolId, address sender) {
        Pool memory pool = getPool(poolId);
        address owner = s_poolRuntimes[poolId].owner;

        if (sender != owner) {
            revert FundraisingPools__NotPoolOwner();
        }

        if (block.timestamp < pool.deadline) {
            revert FundraisingPools__PoolDeadlineNotPassed(pool.deadline);
        }
        _;
    }

    function createPool(
        string calldata purpose,
        uint256 minAmount,
        uint256 minAmountPerContributor,
        uint256 deadline
    )
    external
    payable
    {
        if (block.timestamp > deadline) {
            revert FundraisingPools__PoolDeadlinePassed(deadline);
        }
        if (msg.value == 0 || msg.value < minAmountPerContributor) {
            revert FundraisingPools__InvalidPoolFundAmount(minAmountPerContributor, msg.value);
        }
        uint256 poolId = s_nextPoolId ++;

        s_pools[poolId] = Pool(
            msg.sender,
            purpose,
            minAmount,
            minAmountPerContributor,
            deadline
        );
        PoolRuntime storage poolRuntime = s_poolRuntimes[poolId];
        poolRuntime.owner = msg.sender;
        poolRuntime.currentAmount = msg.value;
        poolRuntime.contributors.push(msg.sender);
        poolRuntime.contributorAmounts[msg.sender] = msg.value;

        emit PoolCreated(
            poolId,
            msg.sender,
            purpose,
            minAmount,
            minAmountPerContributor,
            deadline,
            msg.value
        );
    }

    function contribute(uint256 poolId) external payable {
        Pool memory pool = getPool(poolId);

        if (pool.minAmountPerContributor > msg.value) {
            revert FundraisingPools__InvalidPoolFundAmount(pool.minAmountPerContributor, msg.value);
        }

        if (block.timestamp > pool.deadline) {
            revert FundraisingPools__PoolDeadlinePassed(pool.deadline);
        }
        PoolRuntime storage poolRuntime = s_poolRuntimes[poolId];

        if (poolRuntime.contributorAmounts[msg.sender] == 0) {
            poolRuntime.contributors.push(msg.sender);
        }
        poolRuntime.contributorAmounts[msg.sender] += msg.value;
        poolRuntime.currentAmount += msg.value;

        emit PoolFunded(poolId, msg.sender, msg.value);
    }

    function changePoolOwner(uint256 poolId, address newOwner) external poolExists(poolId) {
        PoolRuntime storage poolRuntime = s_poolRuntimes[poolId];

        if (msg.sender != poolRuntime.owner) {
            revert FundraisingPools__NotPoolOwner();
        }
        if (poolRuntime.contributorAmounts[newOwner] == 0) {
            revert FundraisingPools__PoolOwnerMustBeContributor();
        }
        poolRuntime.owner = newOwner;

        emit PoolOwnerChanged(poolId, msg.sender, newOwner);
    }

    function withdraw(uint256 poolId, address payable beneficiary) external poolWithdrawable(poolId, msg.sender) {
        uint256 withdrawAmount = subtractCommission(s_poolRuntimes[poolId].currentAmount);
        delete s_pools[poolId];
        delete s_poolRuntimes[poolId];

        (bool success, ) = beneficiary.call{value: withdrawAmount}("");

        if (success) {
            emit PoolFundsWithdrawn(poolId, msg.sender, beneficiary, withdrawAmount);
        } else {
            revert FundraisingPools__WithdrawFailed(poolId, beneficiary);
        }
    }

    function canWithdraw(uint256 poolId) external view poolWithdrawable(poolId, msg.sender) returns (bool){
        return true;
    }

    function getPool(uint256 poolId) public view poolExists(poolId) returns (Pool memory) {
        return s_pools[poolId];
    }

    function getPoolOwner(uint256 poolId) public view poolExists(poolId) returns (address) {
        return s_poolRuntimes[poolId].owner;
    }

    function getPoolCurrentAmount(uint256 poolId) external view poolExists(poolId) returns (uint256) {
        return s_poolRuntimes[poolId].currentAmount;
    }

    function getPoolContributors(uint256 poolId) external view poolExists(poolId) returns (address[] memory) {
        return s_poolRuntimes[poolId].contributors;
    }

    function getPoolContributorAmount(uint256 poolId, address contributor) external view returns (uint256) {
        return s_poolRuntimes[poolId].contributorAmounts[contributor];
    }
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.9;
import "@openzeppelin/contracts/access/Ownable.sol";

error Commissionable__InvalidCommission(uint256 commission, uint8 commissionDecimals);

contract Commissionable is Ownable {
    uint256 private s_commissionRate;
    uint8 private s_commissionRateDecimals;

    constructor(uint256 commissionRate, uint8 commissionRateDecimals) {
        setCommissionRate(commissionRate, commissionRateDecimals);
    }

    function setCommissionRate(uint256 commissionRate, uint8 commissionRateDecimals) public onlyOwner {
        if (commissionRate >= 10 ** commissionRateDecimals) {
            revert Commissionable__InvalidCommission(commissionRate, commissionRateDecimals);
        }
        s_commissionRate = commissionRate;
        s_commissionRateDecimals = commissionRateDecimals;
    }

    function getCommissionRate() public view returns (uint256, uint8) {
        return (s_commissionRate, s_commissionRateDecimals);
    }

    function getCommission(uint256 amount) public view returns (uint256)
    {
        return amount * s_commissionRate / 10 ** s_commissionRateDecimals;
    }

    function subtractCommission(uint256 amount) public view returns (uint256) {
        return amount - getCommission(amount);
    }
}

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
// OpenZeppelin Contracts v4.4.1 (security/ReentrancyGuard.sol)

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
        // On the first call to nonReentrant, _notEntered will be true
        require(_status != _ENTERED, "ReentrancyGuard: reentrant call");

        // Any calls to nonReentrant after this point will fail
        _status = _ENTERED;

        _;

        // By storing the original value once again, a refund is triggered (see
        // https://eips.ethereum.org/EIPS/eip-2200)
        _status = _NOT_ENTERED;
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (token/ERC721/IERC721.sol)

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