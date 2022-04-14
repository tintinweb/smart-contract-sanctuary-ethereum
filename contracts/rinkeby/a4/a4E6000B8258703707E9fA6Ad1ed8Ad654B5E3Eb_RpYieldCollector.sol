// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Context.sol";
import "@openzeppelin/contracts/utils/math/Math.sol";
import "@openzeppelin/contracts/interfaces/IERC20.sol";

import './IRaid.sol';

/**
 * @title Raid Party pending rewards batch collection
 * @author xanewok.eth
 * @dev
 *
 * Batch claiming can be optionally:
 * - (`taxed` prefix) taxed by an external entity such as guilds and/or
 * - (`To` suffix) collected into a single address to save on gas.
 *
 * Because $CFTI is an ERC-20 token, we still need to approve this contract
 * from each account where we will draw the funds from for spending in order to
 * move the funds - however, since this contract will be (probably) fully
 * authorized to manage the funds, we need to be extra careful where those funds
 * will be withdrawn.
 *
 * To address this issue, we introduce a concept of *operators* (poor man's
 * ERC-777 operators) which are authorized accounts that can act (and withdraw
 * tokens, among others) on behalf of the token *owner* accounts via this contract.
 *
 */
contract RpYieldCollector is Context, Ownable {
    uint256 public _collectedFee;
    IERC20 public immutable _confetti;
    IRaid public immutable _raid;
    uint16 public constant BP_PRECISION = 1e4;
    uint16 public _feeBasisPoints = 50; // 0.5%

    // For each account, a mapping of its operators.
    mapping(address => mapping(address => bool)) private _operators;

    constructor(address confetti, address raid) {
        _confetti = IERC20(confetti);
        _raid = IRaid(raid);
    }

    function setFee(uint16 amount) public onlyOwner {
        require(amount <= 100, "Fee is never going to be more than 1%");
        _feeBasisPoints = amount;
    }

    function withdrawFee() public onlyOwner {
        _confetti.transfer(msg.sender, _collectedFee);
        _collectedFee = 0;
    }

    /// @notice Claims RP pending rewards for each wallet in a single transaction
    function claimMultipleRewards(address[] calldata wallets) public {
        // NOTE: It's safe to simply collect pending rewards for given wallets,
        // - worst case we simply pay for their gas fees lol
        for (uint256 i = 0; i < wallets.length; i++) {
            _raid.claimRewards(wallets[i]);
        }
    }

    /// @notice Claims RP pending rewards for each wallet in a single transaction
    function taxedClaimMultipleRewards(
        address[] calldata wallets,
        uint16 taxBasisPoints,
        address taxRecipient
    ) public authorized(wallets) {
        require(
            taxBasisPoints + _feeBasisPoints <= BP_PRECISION,
            "Can't collect over 100%"
        );
        require(taxRecipient != address(0x0), "Tax recipient can't be zero");

        // Firstly, claim all the pending rewards for the wallets
        uint256 claimedRewards = getPendingRewards(wallets);
        claimMultipleRewards(wallets);

        // Secondly, collect the tax and the service fee from the rewards.
        // To save on gas, we try to minimize the amount of token transfers.
        uint256 tax = (claimedRewards * taxBasisPoints) / BP_PRECISION;
        amortizedCollectFrom(wallets, taxRecipient, tax);
        // To save on gas, fees are accumulated and pulled when needed.
        uint256 fee = (claimedRewards * _feeBasisPoints) / BP_PRECISION;
        amortizedCollectFrom(wallets, address(this), fee);
        _collectedFee += fee;
    }

    /// @dev You should read `isApproved` first to make sure each wallet has ERC20 approval
    function claimMultipleRewardsTo(
        address[] calldata wallets,
        address recipient
    ) public authorized(wallets) returns (uint256) {
        // TODO:
        uint256 totalClaimedRewards = 0;
        for (uint256 i = 0; i < wallets.length; i++) {
            uint256 pendingRewards = _raid.getPendingRewards(wallets[i]);
            totalClaimedRewards += pendingRewards;

            _raid.claimRewards(wallets[i]);
            _confetti.transferFrom(wallets[i], address(this), pendingRewards);
        }

        uint256 fee = (totalClaimedRewards * _feeBasisPoints) / BP_PRECISION;
        _confetti.transfer(recipient, totalClaimedRewards - fee);
        _collectedFee += fee;

        return totalClaimedRewards - fee;
    }

    /// @notice Claims rewards from the wallets to a single wallet, while also
    /// collecting a tax. Tax is in basis points, i.e. value of 100 means the
    /// tax is 1%, value of 10 means 0.1% etc.
    function taxedClaimMultipleRewardsTo(
        address[] calldata wallets,
        address recipient,
        uint16 taxBasisPoints,
        address taxRecipient
    ) public authorized(wallets) {
        require(
            taxBasisPoints + _feeBasisPoints <= BP_PRECISION,
            "Can't collect over 100%"
        );
        require(taxRecipient != address(0x0), "Tax recipient can't be zero");

        uint256 claimedRewards = 0;
        for (uint256 i = 0; i < wallets.length; i++) {
            uint256 pendingRewards = _raid.getPendingRewards(wallets[i]);
            claimedRewards += pendingRewards;

            _raid.claimRewards(wallets[i]);
            _confetti.transferFrom(wallets[i], address(this), pendingRewards);
        }

        uint256 tax = (claimedRewards * taxBasisPoints) / BP_PRECISION;
        uint256 fee = (claimedRewards * _feeBasisPoints) / BP_PRECISION;
        if (tax > 0) {
            _confetti.transfer(taxRecipient, tax);
        }
        _collectedFee += fee;

        // Finally, send the claimed reward to the recipient
        _confetti.transfer(recipient, claimedRewards - tax - fee);
    }

    /// @notice Bundles all of the tokens at the `recipient` address, optionally
    /// claiming any pending rewards.
    function bundleTokens(
        address[] calldata wallets,
        address recipient,
        bool alsoClaim
    ) public authorized(wallets) {
        if (alsoClaim) {
            uint256 claimedRewards = getPendingRewards(wallets);
            claimMultipleRewards(wallets);

            uint256 fee = (claimedRewards * _feeBasisPoints) / BP_PRECISION;
            amortizedCollectFrom(wallets, address(this), fee);
            _collectedFee += fee;
        }

        for (uint256 i = 0; i < wallets.length; i++) {
            if (wallets[i] != recipient) {
                uint256 amount = _confetti.balanceOf(wallets[i]);
                _confetti.transferFrom(wallets[i], recipient, amount);
            }
        }
    }

    // To minimize the amount of ERC-20 token transfers (which are costly), we
    // use a greedy algorithm of sending as much as we can until we transfer
    // a total, specified amount.
    // NOTE: The caller must ensure that wallets are safe to transfer from by the
    // transaction sender.
    function amortizedCollectFrom(
        address[] calldata wallets,
        address recipient,
        uint256 amount
    ) private {
        uint256 collected = 0;
        for (uint256 i = 0; i < wallets.length && collected < amount; i++) {
            uint256 collectedNow = Math.min(
                _confetti.balanceOf(wallets[i]),
                amount - collected
            );

            _confetti.transferFrom(wallets[i], recipient, collectedNow);
            collected += collectedNow;
        }
    }

    /// @notice Returns whether given wallets authorized this contract to move at least
    /// their current pending rewards
    function isApproved(address[] calldata wallets)
        external
        view
        returns (bool)
    {
        for (uint256 i = 0; i < wallets.length; i++) {
            uint256 pendingRewards = _raid.getPendingRewards(wallets[i]);
            if (
                _confetti.allowance(wallets[i], address(this)) < pendingRewards
            ) {
                return false;
            }
        }
        return true;
    }

    /// @notice Convenient function that returns total pending rewards for given wallets
    function getPendingRewards(address[] calldata wallets)
        public
        view
        returns (uint256)
    {
        uint256 sum = 0;
        for (uint256 i = 0; i < wallets.length; i++) {
            sum += _raid.getPendingRewards(wallets[i]);
        }
        return sum;
    }

    // Ensure that the transaction sender is authorized to move the funds
    // from these wallets
    modifier authorized(address[] calldata wallets) {
        require(
            isOperatorForWallets(_msgSender(), wallets),
            "Not authorized to manage wallets"
        );
        _;
    }

    /// @notice Returns whether the transaction sender can manage given wallets
    function isOperatorForWallets(address operator, address[] calldata wallets)
        public
        view
        returns (bool)
    {
        for (uint256 i = 0; i < wallets.length; i++) {
            if (!isOperatorFor(operator, wallets[i])) {
                return false;
            }
        }
        return true;
    }

    // ERC-777-inspired operators.
    function isOperatorFor(address operator, address tokenHolder)
        public
        view
        returns (bool)
    {
        return operator == tokenHolder || _operators[tokenHolder][operator];
    }

    /// @notice Authorize a given address to move funds in the name of the
    /// transaction sender.
    function authorizeOperator(address operator) public {
        require(_msgSender() != operator, "authorizing self as operator");

        _operators[_msgSender()][operator] = true;

        emit AuthorizedOperator(operator, _msgSender());
    }

    /// @notice Revoke a given address to move funds in the name of the
    /// transaction sender.
    function revokeOperator(address operator) public {
        require(operator != _msgSender(), "revoking self as operator");

        delete _operators[_msgSender()][operator];

        emit RevokedOperator(operator, _msgSender());
    }

    event AuthorizedOperator(
        address indexed operator,
        address indexed tokenHolder
    );
    event RevokedOperator(
        address indexed operator,
        address indexed tokenHolder
    );
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface IRaid {
    function claimRewards(address user) external;

    function getPendingRewards(address user) external view returns (uint256);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.5.0) (utils/math/Math.sol)

pragma solidity ^0.8.0;

/**
 * @dev Standard math utilities missing in the Solidity language.
 */
library Math {
    /**
     * @dev Returns the largest of two numbers.
     */
    function max(uint256 a, uint256 b) internal pure returns (uint256) {
        return a >= b ? a : b;
    }

    /**
     * @dev Returns the smallest of two numbers.
     */
    function min(uint256 a, uint256 b) internal pure returns (uint256) {
        return a < b ? a : b;
    }

    /**
     * @dev Returns the average of two numbers. The result is rounded towards
     * zero.
     */
    function average(uint256 a, uint256 b) internal pure returns (uint256) {
        // (a + b) / 2 can overflow.
        return (a & b) + (a ^ b) / 2;
    }

    /**
     * @dev Returns the ceiling of the division of two numbers.
     *
     * This differs from standard division with `/` in that it rounds up instead
     * of rounding down.
     */
    function ceilDiv(uint256 a, uint256 b) internal pure returns (uint256) {
        // (a + b - 1) / b can overflow on addition, so we distribute.
        return a / b + (a % b == 0 ? 0 : 1);
    }
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
// OpenZeppelin Contracts (last updated v4.5.0) (token/ERC20/IERC20.sol)

pragma solidity ^0.8.0;

/**
 * @dev Interface of the ERC20 standard as defined in the EIP.
 */
interface IERC20 {
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
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (interfaces/IERC20.sol)

pragma solidity ^0.8.0;

import "../token/ERC20/IERC20.sol";

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (access/Ownable.sol)

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
     * @dev Returns the address of the current owner.
     */
    function owner() public view virtual returns (address) {
        return _owner;
    }

    /**
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        require(owner() == _msgSender(), "Ownable: caller is not the owner");
        _;
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