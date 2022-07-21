// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import '@openzeppelin/contracts/access/Ownable.sol';
import '@openzeppelin/contracts/interfaces/IERC20.sol';
import './interfaces/IParrotRewards.sol';

contract ParrotRewards is IParrotRewards, Ownable {
  struct Reward {
    uint256 totalExcluded; // excluded reward
    uint256 totalRealised;
    uint256 lastClaim; // used for boosting logic
  }

  struct Share {
    uint256 amount; // used to keep track of rewards owed to users and will change if user is/is not excluded
    uint256 amountActual; // number of user's tokens in the contract, will only change when tokens change hands
    uint256 lockedTime;
    bool isExcluded;
  }

  uint256 public timeLock = 30 days;
  address public shareholderToken;
  uint256 public totalLockedUsers;
  uint256 public totalSharesDeposited; // will be all tokens locked, regardless of reward exclusion status
  uint256 public totalSharesForRewards; // will be all tokens eligible to receive rewards (i.e. checks exclusion)

  // amount of shares a user has
  mapping(address => Share) shares;
  // reward information per user
  mapping(address => Reward) public rewards;

  uint256 public totalRewards;
  uint256 public totalDistributed;
  uint256 public rewardsPerShare;

  uint256 private constant ACC_FACTOR = 10**36;

  event ClaimReward(address wallet);
  event DistributeReward(address indexed wallet, address payable receiver);
  event DepositRewards(address indexed wallet, uint256 amountETH);

  modifier onlyOrOwnerToken() {
    require(
      msg.sender == owner() || msg.sender == shareholderToken,
      'must be owner or token contract'
    );
    _;
  }

  constructor(address _shareholderToken) {
    shareholderToken = _shareholderToken;
  }

  function lock(uint256 _amount) external {
    address shareholder = msg.sender;
    IERC20 tokenContract = IERC20(shareholderToken);
    _amount = _amount == 0 ? tokenContract.balanceOf(shareholder) : _amount;
    tokenContract.transferFrom(shareholder, address(this), _amount);
    _addShares(shareholder, _amount);
  }

  function unlock(uint256 _amount) external {
    address shareholder = msg.sender;
    require(
      shares[shareholder].isExcluded ||
        block.timestamp >= shares[shareholder].lockedTime + timeLock,
      'must wait the time lock before unstaking'
    );
    _amount = _amount == 0 ? shares[shareholder].amountActual : _amount;
    require(_amount > 0, 'need tokens to unlock');
    require(
      _amount <= shares[shareholder].amountActual,
      'cannot unlock more than you have locked'
    );
    IERC20(shareholderToken).transferFrom(address(this), shareholder, _amount);
    _removeShares(shareholder, _amount);
  }

  function _addShares(address shareholder, uint256 amount) private {
    _distributeReward(shareholder);

    uint256 sharesBefore = shares[shareholder].amount;
    totalSharesDeposited += amount;
    totalSharesForRewards += shares[shareholder].isExcluded ? 0 : amount;
    shares[shareholder].amount += shares[shareholder].isExcluded ? 0 : amount;
    shares[shareholder].amountActual += amount;
    shares[shareholder].lockedTime = block.timestamp;
    if (sharesBefore == 0 && shares[shareholder].amount > 0) {
      totalLockedUsers++;
    }
    rewards[shareholder].totalExcluded = getCumulativeRewards(
      shares[shareholder].amountActual
    );
  }

  function _removeShares(address shareholder, uint256 amount) private {
    amount = amount == 0 ? shares[shareholder].amount : amount;
    require(
      shares[shareholder].amountActual > 0 &&
        amount <= shares[shareholder].amountActual,
      'you can only unlock if you have some lockd'
    );
    _distributeReward(shareholder);

    totalSharesDeposited -= amount;
    totalSharesForRewards -= shares[shareholder].isExcluded ? 0 : amount;
    shares[shareholder].amount -= shares[shareholder].isExcluded ? 0 : amount;
    shares[shareholder].amountActual -= amount;
    rewards[shareholder].totalExcluded = getCumulativeRewards(
      shares[shareholder].amountActual
    );
  }

  function depositRewards() external payable override {
    require(msg.value > 0, 'value must be greater than 0');
    require(
      totalSharesForRewards > 0,
      'must be shares deposited to be rewarded rewards'
    );

    uint256 amount = msg.value;
    totalRewards += amount;
    rewardsPerShare += (ACC_FACTOR * amount) / totalSharesForRewards;
    emit DepositRewards(msg.sender, msg.value);
  }

  function _distributeReward(address shareholder) internal {
    if (shares[shareholder].amount == 0) {
      return;
    }

    uint256 amount = getUnpaid(shareholder);

    rewards[shareholder].totalRealised += amount;
    rewards[shareholder].totalExcluded = getCumulativeRewards(
      shares[shareholder].amountActual
    );
    rewards[shareholder].lastClaim = block.timestamp;

    if (amount > 0) {
      address payable receiver = payable(shareholder);
      totalDistributed += amount;
      uint256 balanceBefore = address(this).balance;
      receiver.call{ value: amount }('');
      require(address(this).balance >= balanceBefore - amount);
      emit DistributeReward(shareholder, receiver);
    }
  }

  function claimReward() external override {
    _distributeReward(msg.sender);
    emit ClaimReward(msg.sender);
  }

  // returns the unpaid rewards
  function getUnpaid(address shareholder) public view returns (uint256) {
    if (shares[shareholder].amount == 0) {
      return 0;
    }

    uint256 earnedRewards = getCumulativeRewards(
      shares[shareholder].amountActual
    );
    uint256 rewardsExcluded = rewards[shareholder].totalExcluded;
    if (earnedRewards <= rewardsExcluded) {
      return 0;
    }

    return earnedRewards - rewardsExcluded;
  }

  function getCumulativeRewards(uint256 share) internal view returns (uint256) {
    return (share * rewardsPerShare) / ACC_FACTOR;
  }

  function getRewardsShares(address user)
    external
    view
    override
    returns (uint256)
  {
    return shares[user].amount;
  }

  function getLockedShares(address user)
    external
    view
    override
    returns (uint256)
  {
    return shares[user].amountActual;
  }

  function setIsRewardsExcluded(address shareholder, bool isExcluded)
    external
    onlyOwner
  {
    require(
      shares[shareholder].isExcluded != isExcluded,
      'can only change exclusion status from what it is not already'
    );
    shares[shareholder].isExcluded = isExcluded;

    // distribute any outstanding rewards for the excluded user and
    // adjust the total rewards shares for the next reward deposit
    // to be accurately calculated
    if (isExcluded) {
      _distributeReward(shareholder);
      totalSharesForRewards -= shares[shareholder].amountActual;
      totalLockedUsers--;
    } else {
      totalSharesForRewards += shares[shareholder].amountActual;
      totalLockedUsers++;
    }
    shares[shareholder].amount = isExcluded
      ? 0
      : shares[shareholder].amountActual;
  }

  function setTimeLock(uint256 numSec) external onlyOwner {
    require(numSec <= 365 days, 'must be less than a year');
    timeLock = numSec;
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
// OpenZeppelin Contracts v4.4.1 (interfaces/IERC20.sol)

pragma solidity ^0.8.0;

import "../token/ERC20/IERC20.sol";

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

interface IParrotRewards {
  function claimReward() external;

  function depositRewards() external payable;

  function getRewardsShares(address wallet) external view returns (uint256);

  function getLockedShares(address wallet) external view returns (uint256);

  function setIsRewardsExcluded(address shareholder, bool isExcluded) external;

  function lock(uint256 amount) external;

  function unlock(uint256 amount) external;
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