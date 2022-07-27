//SPDX-License-Identifier: Unlicense
pragma solidity >=0.8.4 <0.9.0;

import '@openzeppelin/contracts/access/Ownable.sol';
import '@openzeppelin/contracts/token/ERC20/IERC20.sol';
import './IERC20Bank.sol';

contract ERC20Bank is IERC20Bank, Ownable {
  IERC20 public erc20Token;
  mapping(address => uint256) public userToTokensStaked;
  uint256 public totalTokensStaked;
  uint256 public rewardPool1;
  uint256 public rewardPool2;
  uint256 public rewardPool3;
  uint256 public initialRewardPool;
  uint256 public timePeriod;
  uint256 public initTime;
  uint256 public bankId;


  event BankInitialized(
    address indexed _bankOwner,
    uint256 _bankId,
    IERC20 indexed _erc20Token,
    uint256 _initialRewardPool,
    uint256 _timePeriod,
    uint256 _initTime
  );
  event TokensStaked(address indexed _user, uint256 indexed _bankId, IERC20 indexed _erc20Token, uint256 _amount);
  event TokensWithdrawn(address indexed _user, uint256 indexed _bankId, IERC20 indexed _erc20Token, uint256 _userStake, uint256 _userRewards);
  event RewardWithdrawn(address indexed _bankOwner, uint256 _bankId, IERC20 indexed _erc20Token, uint256 _rewardPool);

  constructor(
    IERC20 _erc20Token,
    uint256 _initialRewardPool,
    uint256 _timePeriod
  ) {
    _initializeBank(msg.sender, _erc20Token, _initialRewardPool, _timePeriod);
  }

  function stakeTokens(uint256 _amount) external override {
    //solhint-disable-next-line
    require(block.timestamp < initTime + timePeriod, 'Cannot deposit during lock or withdrawal periods');
    userToTokensStaked[msg.sender] += _amount;
    totalTokensStaked += _amount;
    emit TokensStaked(msg.sender, bankId, erc20Token, _amount);
    erc20Token.transferFrom(msg.sender, address(this), _amount);
  }

  function withdrawTokens() external override {
    //solhint-disable-next-line
    require(block.timestamp >= initTime + timePeriod * 2, 'Cannot withdraw during deposit or lock period');
    uint256 userStake = userToTokensStaked[msg.sender];
    (uint256 userReward1, uint256 userReward2, uint256 userReward3) = _getUserRewardsPerPool(msg.sender);
    uint256 userRewards = userReward1 + userReward2 + userReward3;
    rewardPool1 -= userReward1; 
    rewardPool2 -= userReward2;
    rewardPool3 -= userReward3;
    totalTokensStaked -= userStake;
    delete userToTokensStaked[msg.sender];
    emit TokensWithdrawn(msg.sender, bankId, erc20Token, userStake, userRewards);
    erc20Token.transfer(msg.sender, userStake + userRewards);
  }

  function withdrawReward() external onlyOwner {
    //solhint-disable-next-line
    require(block.timestamp >= initTime + timePeriod * 4, 'Cannot withdraw until last period');
    require(totalTokensStaked == 0, 'Users still have tokens staked');
    uint256 rewardPool = rewardPool1 + rewardPool2 + rewardPool3;
    delete rewardPool1;
    delete rewardPool2;
    delete rewardPool3;
    emit RewardWithdrawn(msg.sender, bankId, erc20Token, rewardPool);
    erc20Token.transfer(msg.sender, rewardPool);
  }

  function resetBank(
    IERC20 _erc20Token,
    uint256 _initialRewardPool,
    uint256 _timePeriod
  ) external onlyOwner {
    require(block.timestamp >= initTime + timePeriod * 4, 'Cannot reset until last period');
    require(totalTokensStaked == 0, 'Users still have tokens staked');
    require(rewardPool3 == 0, 'Reward pools are not empty');
    bankId++;
    _initializeBank(msg.sender, _erc20Token, _initialRewardPool, _timePeriod);
  }

  function getRewardPool() external view override returns (uint256) {
    uint256 rewardPool = rewardPool1 + rewardPool2 + rewardPool3;
    return rewardPool;
  }

  function getUserRewards(address _user) external view override returns (uint256) {
    (uint256 userReward1, uint256 userReward2, uint256 userReward3) = _getUserRewardsPerPool(_user);
    uint256 userRewards = userReward1 + userReward2 + userReward3;
    return userRewards;
  }

  function _initializeBank(
    address _bankOwner,
    IERC20 _erc20Token,
    uint256 _initialRewardPool,
    uint256 _timePeriod
  ) private {
    erc20Token = _erc20Token;
    rewardPool1 = (_initialRewardPool * 20) / 100;
    rewardPool2 = (_initialRewardPool * 30) / 100;
    rewardPool3 = (_initialRewardPool * 50) / 100;
    initialRewardPool = _initialRewardPool;
    timePeriod = _timePeriod;
    initTime = block.timestamp;
    emit BankInitialized(_bankOwner, bankId, _erc20Token, _initialRewardPool, _timePeriod, block.timestamp);
    uint256 rewardPool = rewardPool1 + rewardPool2 + rewardPool3;
    erc20Token.transferFrom(_bankOwner, address(this), rewardPool);
  }

  function _getUserRewardsPerPool(address _user)
    private
    view
    returns (
      uint256,
      uint256,
      uint256
    )
  {
    uint256 userReward1;
    uint256 userReward2;
    uint256 userReward3;
    if (userToTokensStaked[_user] != 0) {
      uint256 poolPercentage = (userToTokensStaked[_user] * 100) / totalTokensStaked;
      if (block.timestamp >= initTime + timePeriod * 2) {
        userReward1 = (rewardPool1 * poolPercentage) / 100;
        if (block.timestamp >= initTime + timePeriod * 3) {
          userReward2 = (rewardPool2 * poolPercentage) / 100;
          if (block.timestamp >= initTime + timePeriod * 4) {
            userReward3 = (rewardPool3 * poolPercentage) / 100;
          }
        }
      }
    }
    return (userReward1, userReward2, userReward3);
  }
}

// SPDX-License-Identifier: MIT

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
        _setOwner(_msgSender());
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
        _setOwner(address(0));
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        _setOwner(newOwner);
    }

    function _setOwner(address newOwner) private {
        address oldOwner = _owner;
        _owner = newOwner;
        emit OwnershipTransferred(oldOwner, newOwner);
    }
}

// SPDX-License-Identifier: MIT

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
     * @dev Moves `amount` tokens from the caller's account to `recipient`.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transfer(address recipient, uint256 amount) external returns (bool);

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
     * @dev Moves `amount` tokens from `sender` to `recipient` using the
     * allowance mechanism. `amount` is then deducted from the caller's
     * allowance.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transferFrom(
        address sender,
        address recipient,
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

//SPDX-License-Identifier: Unlicense
pragma solidity >=0.8.4 <0.9.0;

interface IERC20Bank {
  function stakeTokens(uint256 _amount) external;

  function withdrawTokens() external;

  function getRewardPool() external view returns (uint256);

  function getUserRewards(address _user) external view returns (uint256);
}

// SPDX-License-Identifier: MIT

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