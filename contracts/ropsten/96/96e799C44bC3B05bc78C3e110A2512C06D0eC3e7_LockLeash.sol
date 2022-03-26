//SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

interface ISaleContract {
    function winningsBidsOf(address user) external view returns (uint256);
}

contract LockLeash is Ownable {
    uint256 public immutable AMOUNT_MIN;
    uint256 public immutable AMOUNT_MAX;
    uint256 public immutable DAYS_MIN;
    uint256 public immutable DAYS_MAX;

    IERC20 public immutable LEASH;
    IERC20 public immutable BONE;

    ISaleContract public saleContract;

    bool public isLockEnabled;

    uint256 public totalWeight;
    uint256 public totalBoneRewards;

    struct Lock {
        uint256 amount;
        uint256 startTime;
        uint256 numDays;
        address ogUser;
    }

    mapping(address => Lock) private _lockOf;

    constructor(
        address _leash,
        address _bone,
        uint256 amountMin,
        uint256 amountMax,
        uint256 daysMin,
        uint256 daysMax
    ) {
        LEASH = IERC20(_leash);
        BONE = IERC20(_bone);
        AMOUNT_MIN = amountMin;
        AMOUNT_MAX = amountMax;
        DAYS_MIN = daysMin;
        DAYS_MAX = daysMax;
    }

    function lockInfoOf(address user)
        public
        view
        returns (
            uint256 amount,
            uint256 startTime,
            uint256 numDays,
            address ogUser
        )
    {
        return (
            _lockOf[user].amount,
            _lockOf[user].startTime,
            _lockOf[user].numDays,
            _lockOf[user].ogUser
        );
    }

    function weightOf(address user) public view returns (uint256) {
        return _lockOf[user].amount * _lockOf[user].numDays;
    }

    function extraLeashNeeded(address user, uint256 targetWeight)
        external
        view
        returns (uint256)
    {
        uint256 currentWeight = weightOf(user);

        if (currentWeight >= targetWeight) {
            return 0;
        }

        return (targetWeight - currentWeight) / _lockOf[user].numDays;
    }

    function extraDaysNeeded(address user, uint256 targetWeight)
        external
        view
        returns (uint256)
    {
        uint256 currentWeight = weightOf(user);

        if (currentWeight >= targetWeight) {
            return 0;
        }

        return (targetWeight - currentWeight) / _lockOf[user].amount;
    }

    function isWinner(address user) public view returns (bool) {
        return saleContract.winningsBidsOf(user) > 0;
    }

    function setSaleContract(address sale) external onlyOwner {
        saleContract = ISaleContract(sale);
    }

    function addBoneRewards(uint256 rewardAmount) external onlyOwner {
        totalBoneRewards += rewardAmount;
        BONE.transferFrom(msg.sender, address(this), rewardAmount);
    }

    function toggleLockEnabled() external onlyOwner {
        isLockEnabled = !isLockEnabled;
    }

    function lock(uint256 amount, uint256 numDaysToAdd) external {
        require(isLockEnabled, "Locking not enabled");

        Lock storage s = _lockOf[msg.sender];

        uint256 oldWeight = s.amount * s.numDays;

        s.amount += amount;
        require(
            AMOUNT_MIN <= s.amount && s.amount <= AMOUNT_MAX,
            "LEASH amount outside of limits"
        );

        if (s.numDays == 0) {
            // no existing lock
            s.startTime = block.timestamp;
            s.ogUser = msg.sender;
        }

        if (numDaysToAdd > 0) {
            s.numDays += numDaysToAdd;
        }

        uint256 numDays = s.numDays;

        require(
            DAYS_MIN <= numDays && numDays <= DAYS_MAX,
            "Days outside of limits"
        );

        totalWeight += s.amount * s.numDays - oldWeight;
        LEASH.transferFrom(msg.sender, address(this), amount);
    }

    function unlock() external {
        Lock storage s = _lockOf[msg.sender];

        uint256 amount = s.amount;
        uint256 startTime = s.startTime;
        uint256 numDays = s.numDays;

        require(amount > 0, "No LEASH locked");
        if(isWinner(s.ogUser)) {
            require(startTime + numDays * 1 days <= block.timestamp, "Not unlocked yet");
        } else {
            require(startTime + numDays * 1 days / 2 <= block.timestamp, "Not unlocked yet");
        }

        delete _lockOf[msg.sender];

        LEASH.transfer(msg.sender, amount);
        BONE.transfer(msg.sender, totalBoneRewards * amount * numDays / totalWeight);
    }

    function transferLock(address newOwner) external {
        require(_lockOf[msg.sender].numDays != 0, "Lock does not exist");
        require(
            _lockOf[newOwner].numDays == 0,
            "New owner already has a lock"
        );
        _lockOf[newOwner] = _lockOf[msg.sender];
        delete _lockOf[msg.sender];
    }
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