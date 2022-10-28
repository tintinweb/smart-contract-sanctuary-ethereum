// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {Ownable} from "@openzeppelin/contracts/access/Ownable.sol";

/**
 *   __                                          .__       .__       .___
 *  |  | _______    ____   ____ _____     ___.__.|__| ____ |  |    __| _/
 *  |  |/ /\__  \  /    \ /    \\__  \   <   |  ||  |/ __ \|  |   / __ | 
 *  |    <  / __ \|   |  \   |  \/ __ \_  \___  ||  \  ___/|  |__/ /_/ | 
 *  |__|_ \(____  /___|  /___|  (____  /  / ____||__|\___  >____/\____ | 
 *       \/     \/     \/     \/     \/   \/             \/           \/ 
 * 
 *  @title KNN Yield
 *  @author KANNA Team
 *  @dev distributes a reward within a given duration to its holders.
    rates are weighted according to its {subscription} amount over the total {poolSize}.
 *  @custom:github  https://github.com/kanna-coin
 *  @custom:site https://kannacoin.io
 *  @custom:discord https://discord.gg/V5KDU8DKCh
 */
contract KannaYield is Ownable {
    event RewardAdded(address indexed user, uint256 reward);
    event Collect(address indexed user, address indexed returnAccount, uint256 fee);
    event Subscription(address indexed user, uint256 subscriptionAmount, uint256 fee, uint256 finalAmount);
    event Withdraw(address indexed user, uint256 amount);
    event Reward(address indexed user, uint256 reward);
    event Fee(address indexed user, uint256 amount, uint256 fee, uint256 finalAmount);

    IERC20 public immutable knnToken;
    address public immutable feeRecipient;

    uint256 public constant FEE_BASIS_POINT = 10_000;
    uint256 public constant reducedFee = 10;

    uint256 public knnYieldPool;
    uint256 public knnYieldTotalFee;
    uint256 public poolStartDate;
    uint256 public endDate;
    uint256 public rewardRate;
    uint256 public lastUpdateTime;
    uint256 public rewardPerTokenStored;

    uint256[5] public tier = [1 days, 7 days, 30 days, 60 days, 90 days];

    mapping(address => uint256) public holderRewardPerTokenPaid;
    mapping(address => uint256) public earned;
    mapping(address => uint256) public rawBalances;
    mapping(address => uint256) public started;
    mapping(uint256 => uint256) public fees;

    uint256 public subscriptionFee = 2_0;

    constructor(address _knnToken, address _feeRecipient) {
        knnToken = IERC20(_knnToken);
        feeRecipient = _feeRecipient;
        fees[tier[0]] = 3000;
        fees[tier[1]] = 500;
        fees[tier[2]] = 250;
        fees[tier[3]] = 150;
        fees[tier[4]] = 100;
    }

    /**
     * @dev Retrieves user fee from a given duration
     */
    function feeOf(uint256 subscriptionDuration) private view returns (uint256) {
        if (block.timestamp >= endDate) return reducedFee;

        for (uint256 i = 0; i < tier.length; i++) {
            if (subscriptionDuration < tier[i]) {
                return fees[tier[i]];
            }
        }

        return reducedFee;
    }

    /**
     * @dev Transfer collected fees
     */
    function collectFees() external onlyOwner returns (uint256) {
        uint256 paid = knnYieldTotalFee;
        knnYieldTotalFee = 0;

        knnToken.transfer(feeRecipient, paid);

        emit Collect(msg.sender, feeRecipient, paid);

        return paid;
    }

    /**
     * @dev Retrieves user balance on pool
     */
    function balanceOf(address holder) external view returns (uint256) {
        return rawBalances[holder];
    }

    /**
     * @dev Retrieves the last timestamp when the current reward was calculated.
     */
    function lastPaymentEvent() public view returns (uint256) {
        return block.timestamp < endDate ? block.timestamp : endDate;
    }

    /**
     * @dev Retrieves the current reward per token coeficient
     */
    function rewardPerToken() public view returns (uint256) {
        if (knnYieldPool == 0) {
            return rewardPerTokenStored;
        }

        return rewardPerTokenStored + (((lastPaymentEvent() - lastUpdateTime) * rewardRate * 1e18) / knnYieldPool);
    }

    /**
     * @dev Retrieve the current available reward for a given address
     */
    function calculateReward(address holder) public view returns (uint256) {
        return ((rawBalances[holder] * (rewardPerToken() - holderRewardPerTokenPaid[holder])) / 1e18) + earned[holder];
    }

    /**
     * @dev Allow user to deposit an amount and start receiving rewards.
     */
    function subscribe(uint256 subscriptionAmount) external updateReward(msg.sender) {
        require(endDate > block.timestamp, "No reward available");
        require(subscriptionAmount > 0, "Cannot subscribe 0 KNN");
        require(knnToken.balanceOf(msg.sender) >= subscriptionAmount, "Insufficient balance");

        knnToken.transferFrom(msg.sender, address(this), subscriptionAmount);

        knnYieldPool += subscriptionAmount;

        uint256 subscriptionDate = started[msg.sender];

        if (subscriptionDate == 0 || subscriptionDate < poolStartDate || subscriptionAmount > rawBalances[msg.sender]) {
            started[msg.sender] = block.timestamp;
        }

        rawBalances[msg.sender] += subscriptionAmount;

        emit Subscription(msg.sender, subscriptionAmount, subscriptionFee, subscriptionAmount);
    }

    /**
     * @dev Allow user withdraw funds with a penalty of reseting
     * the {started} to current block timestamp.
     */
    function withdraw(uint256 amount) public updateReward(msg.sender) {
        require(amount > 0, "Invalid amount");
        require(rawBalances[msg.sender] >= amount, "Insufficient balance");

        knnYieldPool -= amount;
        rawBalances[msg.sender] -= amount;

        _transferFee(msg.sender, rawBalances[msg.sender]);

        started[msg.sender] = block.timestamp;

        emit Withdraw(msg.sender, amount);
    }

    /**
     * @dev Return funds to the user
     */
    function exit() external updateReward(msg.sender) {
        uint256 balance = rawBalances[msg.sender];
        uint256 reward = earned[msg.sender];

        if (balance > 0) {
            rawBalances[msg.sender] = 0;
            knnYieldPool -= balance;
        }

        if (reward > 0) {
            earned[msg.sender] = 0;
            balance += reward;
        }

        if (balance == 0) {
            return;
        }

        _transferFee(msg.sender, balance);

        emit Reward(msg.sender, reward);
    }

    /**
     * @dev Transfer funds to user with a duration-based fee.
     */
    function _transferFee(address to, uint256 amount) private returns (uint256) {
        require(started[msg.sender] > 0, "Not in pool");
        uint256 duration = block.timestamp - started[msg.sender];

        uint256 userFee = feeOf(duration) + subscriptionFee;

        uint256 finalAmount = amount - ((amount * userFee) / FEE_BASIS_POINT);
        knnYieldTotalFee += amount - finalAmount;

        knnToken.transfer(to, finalAmount);
        emit Fee(to, amount, userFee, finalAmount);

        return userFee;
    }

    /**
     * @dev Adds a `reward` to be distributed over a `duration`
     */
    function addReward(uint256 reward, uint256 rewardsDuration) external onlyOwner updateReward(address(0)) {
        require(block.timestamp + rewardsDuration >= endDate, "Cannot reduce current yield contract duration");
        if (block.timestamp >= endDate) {
            rewardRate = reward / rewardsDuration;

            poolStartDate = block.timestamp;
        } else {
            uint256 remaining = endDate - block.timestamp;
            uint256 leftover = remaining * rewardRate;
            rewardRate = (reward + leftover) / rewardsDuration;
        }

        uint256 balance = knnToken.balanceOf(address(this));
        require(rewardRate <= balance / rewardsDuration, "Insufficient balance");

        lastUpdateTime = block.timestamp;
        endDate = block.timestamp + rewardsDuration;

        emit RewardAdded(msg.sender, reward);
    }

    /**
     * @dev Update current user reward
     */
    modifier updateReward(address holder) {
        rewardPerTokenStored = rewardPerToken();
        lastUpdateTime = lastPaymentEvent();
        if (holder != address(0)) {
            uint256 init = started[msg.sender];

            if (init < poolStartDate && rawBalances[msg.sender] > 0) {
                started[msg.sender] = poolStartDate;
            }

            earned[holder] = calculateReward(holder);
            holderRewardPerTokenPaid[holder] = rewardPerTokenStored;
        }
        _;
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