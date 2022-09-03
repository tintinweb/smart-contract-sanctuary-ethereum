// SPDX-License-Identifier: MIT
pragma solidity >= 0.8.4;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

struct depositRecord {
    uint256 amount;
    uint256 depositedAt;
}

struct LockedStaking {
    uint32 period;
    uint32 interestRate;
}

struct LockedStakingRecord {
    uint256 amount;
    uint256 createdAt;
    LockedStaking lockedStaking;
}

contract AdvanceBank is Ownable {
    uint256 public minimumDepositAmount = 100;
    mapping(address => depositRecord[]) private depositRecords;
    IERC20 public stakingToken;
    IERC20 public rewardToken;
    uint32 public depositRates = 10;
    LockedStaking[] public lockedStakings;
    mapping(address => LockedStakingRecord[]) private lockedStakingRecords;

    event EarnDepositInterest(address indexed from, uint256 amount);
    event EarnLockStakingInterest(address indexed from, uint32 period, uint32 interest, uint256 amount, uint256 createdAt);

    constructor(address _stakingToken, address _rewardToken) Ownable() {
        stakingToken = IERC20(_stakingToken);
        rewardToken = IERC20(_rewardToken);
        lockedStakings.push(LockedStaking({
            period: 30 seconds,
            interestRate: 20
        }));
        lockedStakings.push(LockedStaking({
            period: 60 seconds,
            interestRate: 30
        }));
    }

    function deposit(uint256 _amount) external checkDepositAmount(_amount) {
        depositRecords[msg.sender].push(depositRecord({
            amount: _amount,
            depositedAt: block.timestamp
        }));
        stakingToken.transferFrom(msg.sender, address(this), _amount);
        emit EarnDepositInterest(msg.sender, _amount);
    }

    function lockToken(uint256 _index, uint256 _amount) external checkDepositAmount(_amount) {
        LockedStakingRecord memory lockedStakingRecord = LockedStakingRecord({
            lockedStaking: lockedStakings[_index],
            amount: _amount,
            createdAt: block.timestamp
        });
        lockedStakingRecords[msg.sender].push(lockedStakingRecord);
        stakingToken.transferFrom(msg.sender, address(this), _amount);
        emit EarnLockStakingInterest(
            msg.sender,
            lockedStakings[_index].period,
            lockedStakings[_index].interestRate,
            _amount,
            lockedStakingRecord.createdAt
        );
    }

    function withdraw(uint256 _index) external {
        uint256 interest = depositInterestTrialCalculation(depositRecords[msg.sender][_index].depositedAt, block.timestamp, depositRecords[msg.sender][_index].amount);
        uint256 depositAmount = depositRecords[msg.sender][_index].amount;
        uint256 lastIndex = depositRecords[msg.sender].length - 1;

        if (_index != lastIndex) {
            depositRecords[msg.sender][_index] = depositRecords[msg.sender][lastIndex];
        } else {
            depositRecords[msg.sender].pop();
        }
        stakingToken.transfer(msg.sender, depositAmount);
        rewardToken.transfer(msg.sender, interest);
    }

    function unlockToken(uint256 _index) external {
        uint32 period = lockedStakingRecords[msg.sender][_index].lockedStaking.period;
        uint256 createdAt = lockedStakingRecords[msg.sender][_index].createdAt;
        require((block.timestamp - createdAt) > period, "Lock time does not reach");
        uint256 interest = lockedStakingInterestTrialCalculation(
            period,
            lockedStakingRecords[msg.sender][_index].lockedStaking.interestRate,
            lockedStakingRecords[msg.sender][_index].amount
        );
        uint256 lockedAmount = lockedStakingRecords[msg.sender][_index].amount;
        uint256 lastIndex = lockedStakingRecords[msg.sender].length - 1;

        if (_index != lastIndex) {
            lockedStakingRecords[msg.sender][_index] = lockedStakingRecords[msg.sender][lastIndex];
        } else {
            lockedStakingRecords[msg.sender].pop();
        }
        stakingToken.transfer(msg.sender, lockedAmount);
        rewardToken.transfer(msg.sender, interest);
    }

    function setDepositRates(uint32 _depositRates) external onlyOwner {
        depositRates = _depositRates;
    }

    function setLockedStakings(LockedStaking[] calldata _lockedStakings) external onlyOwner {
        delete lockedStakings;

        for (uint256 i = 0; i < _lockedStakings.length; i++) {
            lockedStakings.push(_lockedStakings[i]);
        }
    }

    function setMinimumDepositAmount(uint256 _minimumDepositAmount) external onlyOwner {
        minimumDepositAmount = _minimumDepositAmount;
    }

    function getDepositRecords(address _from) external view returns(depositRecord[] memory) {
        require(msg.sender == _from, "You are not owner!");

        return depositRecords[_from];
    }

    function getLockedStakingRecords(address _from) external view returns(LockedStakingRecord[] memory) {
        require(msg.sender == _from, "You are not owner!");

        return lockedStakingRecords[_from];
    }

    function depositInterestTrialCalculation(uint256 _startAt, uint256 _endAt, uint256 _amount) public view returns(uint256) {
        uint256 interest = (_endAt - _startAt) * _amount * depositRates / 100 / (365 seconds);

        return interest;
    }

    function lockedStakingInterestTrialCalculation(uint32 _period, uint32 _interestRate, uint256 _amount) public pure returns(uint256) {
        uint256 interest = _period * _interestRate * _amount / 100 / (365 seconds);

        return interest;
    }

    modifier checkDepositAmount(uint256 _amount) {
        require(_amount >= minimumDepositAmount
            && (_amount % minimumDepositAmount) == 0,
            "You deposit amount is wrong!"
        );
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