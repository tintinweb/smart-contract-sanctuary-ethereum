//SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

/**
 * @title Tracelabs Bank smart contract task.
 */

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";


contract Bank is Ownable, ReentrancyGuard {
    error TransferFailed();

    //ERC20 staking and reward token
    IERC20 public s_token;

    //block timestamp during contract depolyment (t₀)
    uint256 public s_deployedAt;

    //time periods (T)
    uint256 public s_epoch;

    //staking rewards deposited by contract owner
    uint256 public s_rewards;

    //Total value locked in protocol
    uint256 public s_totalDeposits;

    //user deposits
    mapping(address => uint256) public s_deposits;

    //reward pool distribution (R1, R2, R3)
    mapping(uint8 => uint256) public rewardPool;

    /***********************/
    /* Modifiers Functions */
    /***********************/

    // From moment T to t₀+T
    modifier depositPeriod() {
        require(
            block.timestamp < s_deployedAt + s_epoch,
            "Deposit period expired"
        );
        _;
    }

    modifier moreThanZero(uint256 amount) {
        require(amount > 0, "Amount must be greater than zero");
        _;
    }

    // period => t₀ to T || > 2T
    modifier withdrawalPeriod() {
        bool locked = true;
        if (
            block.timestamp < s_deployedAt + s_epoch ||
            block.timestamp > s_deployedAt + (2 * s_epoch)
        ) {
            locked = false;
        }
        require(!locked, "Withdrawal unavailable");
        _;
    }

    /*************/
    /*   Events  */
    /*************/

    event Deposit(address indexed sender, uint256 amount);
    event Withdrawal(address indexed sender, uint256 stake, uint256 interest);

    constructor(address token, uint256 epoch) {
        s_deployedAt = block.timestamp;
        s_epoch = epoch;
        s_token = IERC20(token);
    }

    /**
     * @notice Rewards added by the bank (contract owner)
     * @param rewards -> amount of token to be added as rewards
     */

    function depositReward(uint256 rewards) external onlyOwner depositPeriod {
        bool success = s_token.transferFrom(msg.sender, address(this), rewards);

        if (!success) {
            revert TransferFailed();
        }

        s_rewards += rewards;

        //R1 = 20% of R
        rewardPool[1] = (20 * rewards) / 100;

        //R2 = 30% of R
        rewardPool[2] = (30 * rewards) / 100;

        //R3 = 50% of R,
        rewardPool[3] = (50 * rewards) / 100;
    }

    /**
     * @notice Users deposit thier tokens
     * @param amount -> amount to be staked
     */

    function deposit(uint256 amount)
        external
        depositPeriod
        moreThanZero(amount)
    {
        bool success = s_token.transferFrom(msg.sender, address(this), amount);

        if (!success) {
            revert TransferFailed();
        }
        s_deposits[msg.sender] += amount;
        s_totalDeposits += amount;

        emit Deposit(msg.sender, amount);
    }

    /**
     * @notice User withdraw thier stakes and rewards
     */

    function withdraw() external withdrawalPeriod nonReentrant {
        require(s_deposits[msg.sender] > 0, "No deposits found");
        uint256 userDeposit = s_deposits[msg.sender];
        uint256 R1_yield = 0;
        uint256 R2_yield = 0;
        uint256 R3_yield = 0;
        uint256 T = (block.timestamp - s_deployedAt) / s_epoch;

        //period t₀+2T to t₀+3T
        if (T == 2) {
            R1_yield = (userDeposit * rewardPool[1] * 1e18) / s_totalDeposits;
        }

        //period t₀+3T to t₀+4T
        if (T == 3) {
            R1_yield = (userDeposit * rewardPool[1] * 1e18) / s_totalDeposits;
            R2_yield = (userDeposit * rewardPool[2] * 1e18) / s_totalDeposits;
        }
        //period 4T & above
        if (T >= 4) {
            R1_yield = (userDeposit * rewardPool[1] * 1e18) / s_totalDeposits;
            R2_yield = (userDeposit * rewardPool[2] * 1e18) / s_totalDeposits;
            R3_yield = (userDeposit * rewardPool[3] * 1e18) / s_totalDeposits;
        }

        uint256 userReward = R1_yield + R2_yield + R3_yield;

        rewardPool[1] -= R1_yield / 1e18;
        rewardPool[2] -= R2_yield / 1e18;
        rewardPool[3] -= R3_yield / 1e18;

        s_rewards -= userReward / 1e18;

        s_totalDeposits -= userDeposit;

        s_deposits[msg.sender] = 0;

        bool success = s_token.transfer(
            msg.sender,
            (userDeposit + (userReward / 1e18))
        );

        if (!success) {
            revert TransferFailed();
        }

        emit Withdrawal(msg.sender, userDeposit, userReward);
    }

    /**
     * @notice Remaining rewards withdrawn by the bank (contract owner)
     */

    function withdrawReward() external onlyOwner {
        require(
            block.timestamp > (s_deployedAt + (s_epoch * 4)),
            "Can't withdraw rewards yet"
        );
        require(s_totalDeposits == 0, "Users funds still in pool");
        require(s_rewards > 0, "Rewards pool empty");
        uint256 remainingRewards = rewardPool[1] +
            rewardPool[2] +
            rewardPool[3];

        rewardPool[1] = 0;
        rewardPool[2] = 0;
        rewardPool[3] = 0;
        s_rewards = 0;
        s_token.transfer(owner(), remainingRewards);
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