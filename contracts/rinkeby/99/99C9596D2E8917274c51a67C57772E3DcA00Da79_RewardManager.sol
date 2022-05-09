// SPDX-License-Identifier: MIT
pragma solidity 0.8.9;

import "Ownable.sol";
import "ReentrancyGuard.sol";
import "IProtocolToken.sol";

contract RewardManager is Ownable, ReentrancyGuard {
    // user balance
    struct Balance {
        uint256 total; // user total amount: locked + unlocked
        uint256 unlocked; // only unlocked amount
    }

    // lock info
    struct Lock {
        uint256 amount; // lock amount
        uint256 unlockTime; // time to unlock
    }

    uint256 internal constant lockLength = 13;

    // pause for security reason
    bool public paused;

    // token to reward
    address public immutable rewardToken;

    // treasury: penalty amount will go here
    address public immutable rewardReserve;

    // 1 week time
    uint256 public constant oneWeek = 86400;

    // lock duration: 12 weeks
    uint256 public lockDuration = oneWeek * 12;

    // start time: thursday 12:00 first week...
    uint256 public immutable startTime;

    // penalty rate applied when user withdraw sooner
    uint256 public penaltyRate;

    // store total amount
    uint256 public totalSupply;

    // store locked amount
    uint256 public lockedSupply;

    // user -> balance
    mapping(address => Balance) public balances;

    // user -> lock
    // when claiming from Staking, amount will be locked for 12 weeks
    mapping(address => Lock[lockLength]) public locks;

    // only minter can mint token
    mapping(address => bool) public minter;

    // events
    event Withdraw(address indexed user, uint256 amount, uint256 penalty);
    event PauseContract(uint256 indexed timestamp);
    event UnpauseContract(uint256 indexed timestamp);
    event MinterAdded(address indexed minter);
    event MinterRemoved(address indexed minter);
    event PenaltyRateSet(uint256 indexed penaltyRate);
    event LockDurationSet(uint256 indexed duration);

    /**
     * @dev Throws if called when contract is paused.
     */
    modifier pausable() {
        require(!paused, "PAUSED");
        _;
    }

    /**
     * @dev constructor
     * @param _rewardToken Token to reward
     * @param _rewardReserve Address of rewardReserve contract, penalty amount will go here
     * @param _penaltyRate Penalty rate when user withdraw sooner
     */
    constructor(
        address _rewardToken,
        address _rewardReserve,
        uint256 _penaltyRate
    ) {
        require(_rewardToken != address(0), "ADDRESS_ZERO");
        require(_rewardReserve != address(0), "ADDRESS_ZERO");

        rewardToken = _rewardToken;
        rewardReserve = _rewardReserve;
        _setPenaltyRate(_penaltyRate);
        startTime = ((block.timestamp / oneWeek) * oneWeek);
    }

    /**
     * @dev Pause functions
     */
    function pause() external onlyOwner {
        paused = true;
        emit PauseContract(block.timestamp);
    }

    /**
     * @dev Unpause functions
     */
    function unpause() external onlyOwner {
        paused = false;
        emit UnpauseContract(block.timestamp);
    }

    function addMinter(address _minter) external onlyOwner {
        minter[_minter] = true;
        emit MinterAdded(_minter);
    }

    function removeMinter(address _minter) external onlyOwner {
        delete minter[_minter];
        emit MinterRemoved(_minter);
    }

    /**
     * @dev External function update penalty rate
     * @param _penaltyRate New penalty rate, must < 51%
     */
    function setPenaltyRate(uint256 _penaltyRate) external onlyOwner {
        _setPenaltyRate(_penaltyRate);
    }

    /**
     * @dev internal function update penalty rate
     * @param _penaltyRate New penalty rate, must < 51%
     */
    function _setPenaltyRate(uint256 _penaltyRate) internal {
        require(_penaltyRate < 51, "INVALID_RATE");
        penaltyRate = _penaltyRate;
        emit PenaltyRateSet(_penaltyRate);
    }

    /**
     * @dev update lock duration
     * @param _durationInSeconds New lock duration, must <= 12 weeks
     */
    function setLockDuration(uint256 _durationInSeconds) external onlyOwner {
        require(_durationInSeconds < oneWeek * 12 + 1, "INVALID_DURATION");

        // duration must be a multiple of one week
        require(_durationInSeconds % oneWeek == 0, "INVALID_DURATION");

        lockDuration = _durationInSeconds;
        emit LockDurationSet(_durationInSeconds);
    }

    /**
     * @dev mint tokens to this contract. called by Staking contract
     * @param user Beneficial user
     * @param amount Amount to mint
     * @param withPenalty Is this amount subject to penalty
     */
    function mint(
        address user,
        uint256 amount,
        bool withPenalty
    ) external pausable returns (bool) {
        require(minter[msg.sender], "UNAUTHORIZED");
        if (amount == 0) return false;

        Balance storage bal = balances[user];
        if (withPenalty) {
            uint256 currentWeek = ((block.timestamp / oneWeek) * oneWeek);
            uint256 _unlockTime = currentWeek + lockDuration;
            uint256 totalDuration = (currentWeek - startTime) / oneWeek;
            uint256 arrayPlace = totalDuration % 12;
            Lock storage loc = locks[user][arrayPlace];
            if (loc.unlockTime < _unlockTime) {
                // unlock some locked tokens
                bal.unlocked = bal.unlocked + loc.amount;

                // add the new locked tokens to lockedSupply and
                // subtract those unlocked tokens above from lockedSupply
                lockedSupply = lockedSupply + amount - loc.amount;

                loc.amount = amount;
                loc.unlockTime = _unlockTime;
            } else {
                loc.amount = loc.amount + amount;
                lockedSupply = lockedSupply + amount;
            }
        } else {
            bal.unlocked = bal.unlocked + amount;
        }
        bal.total = bal.total + amount;
        totalSupply = totalSupply + amount;

        bool success = IProtocolToken(rewardToken).mintTo(address(this), amount);
        require(success, "MINT_FAILED");

        return true;
    }

    /**
     * @dev withdraw unlocked amount to sender (amount that pass the lock duration)
     */
    function withdrawUnlocked() external pausable nonReentrant {
        Balance storage bal = balances[msg.sender];
        require(bal.total > 0, "NO_REWARDS");

        Lock[lockLength] storage loc = locks[msg.sender];
        uint256 amount;
        for (uint256 i; i < lockLength; i++) {
            if (loc[i].unlockTime <= block.timestamp && loc[i].unlockTime != 0) {
                amount = amount + loc[i].amount;
                delete loc[i];
            }
        }

        if (amount > 0) {
            lockedSupply = lockedSupply - amount;
        }
        amount = amount + bal.unlocked;

        require(amount > 0, "ZERO_UNLOCKED");

        delete bal.unlocked;
        bal.total = bal.total - amount;
        totalSupply = totalSupply - amount;

        bool success = IProtocolToken(rewardToken).transfer(msg.sender, amount);
        require(success, "TRANSFER_FAILED");

        emit Withdraw(msg.sender, amount, 0);
    }

    /**
     * @dev withdraw all amount: locked amount + unlocked amount.
     * unlocked amount: can withdraw all without penalty
     * locked amount: can withdraw with penalty rate applied
     * penalizedAmount will be sent to rewardReserve
     */
    function withdrawAll() external pausable nonReentrant {
        Balance storage bal = balances[msg.sender];
        require(bal.total > 0, "NO_REWARDS");
        uint256 penalizedAmount;
        uint256 locked;
        uint256 claimableAmount = bal.unlocked;
        Lock[lockLength] storage loc = locks[msg.sender];
        for (uint256 i; i < lockLength; i++) {
            if (loc[i].amount == 0) continue;
            if (loc[i].unlockTime <= block.timestamp) {
                claimableAmount = claimableAmount + loc[i].amount;
                locked = locked + loc[i].amount;
                delete loc[i];
            }
            if (loc[i].unlockTime > block.timestamp) {
                uint256 penalty = (loc[i].amount * penaltyRate) / 100;
                claimableAmount = claimableAmount + (loc[i].amount - penalty);
                penalizedAmount = penalizedAmount + penalty;
                locked = locked + loc[i].amount;
                delete loc[i];
            }
        }
        totalSupply = totalSupply - bal.total;
        lockedSupply = lockedSupply - locked;
        delete bal.total;
        delete bal.unlocked;

        bool success = IProtocolToken(rewardToken).transfer(rewardReserve, penalizedAmount);
        require(success, "TRANSFER_FAILED");

        success = IProtocolToken(rewardToken).transfer(msg.sender, claimableAmount);
        require(success, "TRANSFER_FAILED");

        emit Withdraw(msg.sender, claimableAmount, penalizedAmount);
    }

    /**
     * @dev return total balance of a user
     * @param user User address
     */
    function totalBalance(address user) external view returns (uint256 amount) {
        return balances[user].total;
    }

    /**
     * @dev return unlocked amount of a user
     * @param user User address
     */
    function unlockedBalance(address user) external view returns (uint256 amount) {
        Balance memory bal = balances[user];
        amount = bal.unlocked;
        Lock[lockLength] memory loc = locks[user];
        for (uint256 i; i < lockLength; i++) {
            if (loc[i].unlockTime <= block.timestamp) {
                amount = amount + loc[i].amount;
            }
        }
    }

    /**
     * @dev return locked amount of a user
     * @param user User address
     */
    function lockedBalance(address user) external view returns (uint256 amount) {
        Lock[lockLength] memory loc = locks[user];
        for (uint256 i; i < lockLength; i++) {
            if (loc[i].unlockTime > block.timestamp) {
                amount = amount + loc[i].amount;
            }
        }
    }

    /**
     * @dev return withdraw-able amount of a user:
     * unlocked amount + (locked amount - penalizedAmount)
     * @param user User address
     */
    function withdrawableBalance(address user) external view returns (uint256 totalAmount, uint256 penalizedAmount) {
        Balance memory bal = balances[user];
        totalAmount = bal.unlocked;
        Lock[lockLength] memory loc = locks[user];
        for (uint256 i; i < lockLength; i++) {
            if (loc[i].amount == 0) continue;
            if (loc[i].unlockTime <= block.timestamp) {
                totalAmount = totalAmount + loc[i].amount;
            }
            if (loc[i].unlockTime > block.timestamp) {
                uint256 penalty = (loc[i].amount * penaltyRate) / 100;
                totalAmount = totalAmount + (loc[i].amount - penalty);
                penalizedAmount = penalizedAmount + penalty;
            }
        }
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (access/Ownable.sol)

pragma solidity ^0.8.0;

import "Context.sol";

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

pragma solidity ^0.8.9;

interface IProtocolToken {
    function mint(uint256 _amount) external returns (bool);

    function mintTo(address _recipient, uint256 _amount) external returns (bool);

    function burn(uint256 _amount) external returns (bool);

    function addAdmin(address _admin) external;

    function removeAdmin(address _admin) external;

    function setSupplyIncreaseRate(uint256 _rate) external;

    function setMaxSupply(uint224 _maxTokenSupply) external;

    function transfer(address recipient, uint256 amount) external returns (bool);

    function transferFrom(
        address sender,
        address recipient,
        uint256 amount
    ) external returns (bool);
}