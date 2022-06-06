/**
 *Submitted for verification at Etherscan.io on 2022-06-06
*/

// SPDX-License-Identifier: Unlicense

pragma solidity ^0.8.0;

interface IBEP20 {
  /**
   * @dev Returns the amount of tokens in existence.
   */
  function totalSupply() external view returns (uint256);

  /**
   * @dev Returns the token decimals.
   */
  function decimals() external view returns (uint256);

  /**
   * @dev Returns the token symbol.
   */
  function symbol() external view returns (string memory);

  /**
  * @dev Returns the token name.
  */
  function name() external view returns (string memory);

  /**
   * @dev Returns the bep token owner.
   */
  function getOwner() external view returns (address);

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
  function allowance(address _owner, address spender) external view returns (uint256);

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
  function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);

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

/*
 * @dev Provides information about the current execution context, including the
 * sender of the transaction and its data. While these are generally available
 * via msg.sender and msg.data, they should not be accessed in such a direct
 * manner, since when dealing with GSN meta-transactions the account sending and
 * paying for execution may not be the actual sender (as far as an application
 * is concerned).
 *
 * This contract is only required for intermediate, library-like contracts.
 */
contract Context {
  // Empty internal constructor, to prevent people from mistakenly deploying
  // an instance of this contract, which should be used via inheritance.
  constructor () { }

  function _msgSender() internal view returns (address payable) {
    return payable(msg.sender);
  }

  function _msgData() internal view returns (bytes memory) {
    this; // silence state mutability warning without generating bytecode - see https://github.com/ethereum/solidity/issues/2691
    return msg.data;
  }
}

/**
 * @dev Wrappers over Solidity's arithmetic operations with added overflow
 * checks.
 *
 * Arithmetic operations in Solidity wrap on overflow. This can easily result
 * in bugs, because programmers usually assume that an overflow raises an
 * error, which is the standard behavior in high level programming languages.
 * `SafeMath` restores this intuition by reverting the transaction when an
 * operation overflows.
 *
 * Using this library instead of the unchecked operations eliminates an entire
 * class of bugs, so it's recommended to use it always.
 */
library SafeMath {
  /**
   * @dev Returns the addition of two unsigned integers, reverting on
   * overflow.
   *
   * Counterpart to Solidity's `+` operator.
   *
   * Requirements:
   * - Addition cannot overflow.
   */
  function add(uint256 a, uint256 b) internal pure returns (uint256) {
    uint256 c = a + b;
    require(c >= a, "SafeMath: addition overflow");

    return c;
  }

  /**
   * @dev Returns the subtraction of two unsigned integers, reverting on
   * overflow (when the result is negative).
   *
   * Counterpart to Solidity's `-` operator.
   *
   * Requirements:
   * - Subtraction cannot overflow.
   */
  function sub(uint256 a, uint256 b) internal pure returns (uint256) {
    return sub(a, b, "SafeMath: subtraction overflow");
  }

  /**
   * @dev Returns the subtraction of two unsigned integers, reverting with custom message on
   * overflow (when the result is negative).
   *
   * Counterpart to Solidity's `-` operator.
   *
   * Requirements:
   * - Subtraction cannot overflow.
   */
  function sub(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
    require(b <= a, errorMessage);
    uint256 c = a - b;

    return c;
  }

  /**
   * @dev Returns the multiplication of two unsigned integers, reverting on
   * overflow.
   *
   * Counterpart to Solidity's `*` operator.
   *
   * Requirements:
   * - Multiplication cannot overflow.
   */
  function mul(uint256 a, uint256 b) internal pure returns (uint256) {
    // Gas optimization: this is cheaper than requiring 'a' not being zero, but the
    // benefit is lost if 'b' is also tested.
    // See: https://github.com/OpenZeppelin/openzeppelin-contracts/pull/522
    if (a == 0) {
      return 0;
    }

    uint256 c = a * b;
    require(c / a == b, "SafeMath: multiplication overflow");

    return c;
  }

  /**
   * @dev Returns the integer division of two unsigned integers. Reverts on
   * division by zero. The result is rounded towards zero.
   *
   * Counterpart to Solidity's `/` operator. Note: this function uses a
   * `revert` opcode (which leaves remaining gas untouched) while Solidity
   * uses an invalid opcode to revert (consuming all remaining gas).
   *
   * Requirements:
   * - The divisor cannot be zero.
   */
  function div(uint256 a, uint256 b) internal pure returns (uint256) {
    return div(a, b, "SafeMath: division by zero");
  }

  /**
   * @dev Returns the integer division of two unsigned integers. Reverts with custom message on
   * division by zero. The result is rounded towards zero.
   *
   * Counterpart to Solidity's `/` operator. Note: this function uses a
   * `revert` opcode (which leaves remaining gas untouched) while Solidity
   * uses an invalid opcode to revert (consuming all remaining gas).
   *
   * Requirements:
   * - The divisor cannot be zero.
   */
  function div(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
    // Solidity only automatically asserts when dividing by 0
    require(b > 0, errorMessage);
    uint256 c = a / b;
    // assert(a == b * c + a % b); // There is no case in which this doesn't hold

    return c;
  }

  /**
   * @dev Returns the remainder of dividing two unsigned integers. (unsigned integer modulo),
   * Reverts when dividing by zero.
   *
   * Counterpart to Solidity's `%` operator. This function uses a `revert`
   * opcode (which leaves remaining gas untouched) while Solidity uses an
   * invalid opcode to revert (consuming all remaining gas).
   *
   * Requirements:
   * - The divisor cannot be zero.
   */
  function mod(uint256 a, uint256 b) internal pure returns (uint256) {
    return mod(a, b, "SafeMath: modulo by zero");
  }

  /**
   * @dev Returns the remainder of dividing two unsigned integers. (unsigned integer modulo),
   * Reverts with custom message when dividing by zero.
   *
   * Counterpart to Solidity's `%` operator. This function uses a `revert`
   * opcode (which leaves remaining gas untouched) while Solidity uses an
   * invalid opcode to revert (consuming all remaining gas).
   *
   * Requirements:
   * - The divisor cannot be zero.
   */
  function mod(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
    require(b != 0, errorMessage);
    return a % b;
  }
}

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
contract Ownable is Context {
  address private _owner;

  event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

  /**
   * @dev Initializes the contract setting the deployer as the initial owner.
   */
  constructor () {
    address msgSender = _msgSender();
    _owner = msgSender;
    emit OwnershipTransferred(address(0), msgSender);
  }

  /**
   * @dev Returns the address of the current owner.
   */
  function owner() public view returns (address) {
    return _owner;
  }

  /**
   * @dev Throws if called by any account other than the owner.
   */
  modifier onlyOwner() {
    require(_owner == _msgSender(), "Ownable: caller is not the owner");
    _;
  }

  /**
   * @dev Leaves the contract without owner. It will not be possible to call
   * `onlyOwner` functions anymore. Can only be called by the current owner.
   *
   * NOTE: Renouncing ownership will leave the contract without an owner,
   * thereby removing any functionality that is only available to the owner.
   */
  function renounceOwnership() public onlyOwner {
    emit OwnershipTransferred(_owner, address(0));
    _owner = address(0);
  }

  /**
   * @dev Transfers ownership of the contract to a new account (`newOwner`).
   * Can only be called by the current owner.
   */
  function transferOwnership(address newOwner) public onlyOwner {
    _transferOwnership(newOwner);
  }

  /**
   * @dev Transfers ownership of the contract to a new account (`newOwner`).
   */
  function _transferOwnership(address newOwner) internal {
    require(newOwner != address(0), "Ownable: new owner is the zero address");
    emit OwnershipTransferred(_owner, newOwner);
    _owner = newOwner;
  }
}


contract TomiStake is Context, Ownable {
    using SafeMath for uint256;

    IBEP20 token;
    uint256 tiers;
    uint256 public lockPeriod1 = 30 seconds;
    uint256 public lockPeriod2 = 90 seconds; 
    uint256 public lockPeriod3 = 180 seconds;
    uint256 public lockPeriod4 = 365 seconds;

    uint256 public apyTier1 = 1;
    uint256 public apyTier2 = 2; 
    uint256 public apyTier3 = 3;
    uint256 public apyTier4 = 4;
    uint256 public apyTier5 = 5;

    struct User {
        uint256 tier;
        uint256 lockPeriod;
        uint256 amount;
        uint256 depositTime;
        uint256 lastClaimTime;
    }

    mapping(address => User) public deposit;
    uint256 public totalStaked;
    bool public apyEnabled = false;
    address private rewardingTokenWallet;
    uint256 private earlyUstakeFee;
    uint256 timeUntilExpiry = block.timestamp + 3650 days; //ten years

    event Stake(address indexed staker, uint256 _amount, uint256 _lockPeriod, uint256 _tier);
    event Unstake(address indexed unstaker, uint256 unstakeTime);
    event Withdraw(address indexed withdrawer);
    event WithdrawToken(address indexed withdrawer, uint256 amount);
    event Claim(address staker, uint256 reward);


    constructor (IBEP20 _token, uint256 _earlyUstakeFee) {
        token = _token;
        earlyUstakeFee = _earlyUstakeFee;
        rewardingTokenWallet = _msgSender();
    }

    function flipApyEnabled() public onlyOwner {
        apyEnabled = !apyEnabled;
    }

    function setApyTier1(uint256 _apy) public onlyOwner {
        apyTier1 = _apy;
    }

    function setApyTier2(uint256 _apy) public onlyOwner {
        apyTier2 = _apy;
    }

    function setApyTier3(uint256 _apy) public onlyOwner {
        apyTier3 = _apy;
    }

    function setApyTier4(uint256 _apy) public onlyOwner {
        apyTier4 = _apy;
    }

    function setApyTier5(uint256 _apy) public onlyOwner {
        apyTier5 = _apy;
    }

    function setEarlyUnstakeFee(uint256 _fee) public onlyOwner {
        earlyUstakeFee = _fee;
    }

    function setLLockPeriod1(uint256 _days) public onlyOwner {
        lockPeriod1 = _days;
    }
    
    function setLLockPeriod2(uint256 _days) public onlyOwner {
        lockPeriod2 = _days;
    }

    function setLLockPeriod3(uint256 _days) public onlyOwner {
        lockPeriod3 = _days;
    }

    function setLLockPeriod4(uint256 _days) public onlyOwner {
        lockPeriod4 = _days;
    }

    function setRewardingWallet(address _address) public onlyOwner {
        rewardingTokenWallet = _address;
    }

    function stakeTokens(uint256 _amount, uint256 _lockPeriod, uint256 _tier) public {

        require(token.balanceOf(_msgSender())>=_amount, "you do not have sufficient balance");
        require(token.allowance(_msgSender(), address(this))>=_amount, "Tokens not approved");
        require(_tier>0 && _tier<6, "select correct tier");
        User memory wUser = deposit[_msgSender()];
        require(wUser.amount == 0, "Already Staked");
        
        if(_lockPeriod == 1){
        deposit[_msgSender()] = User(_tier, block.timestamp + lockPeriod1, _amount, block.timestamp, block.timestamp);
        }
        else if(_lockPeriod == 2){
        deposit[_msgSender()] = User(_tier, block.timestamp + lockPeriod2, _amount, block.timestamp, block.timestamp);
        }
        else if(_lockPeriod == 3){
        deposit[_msgSender()] = User(_tier, block.timestamp + lockPeriod3, _amount, block.timestamp, block.timestamp);
        }
        else if(_lockPeriod == 4){
        deposit[_msgSender()] = User(_tier, block.timestamp + lockPeriod4, _amount, block.timestamp, block.timestamp);
        }

        token.transferFrom(_msgSender(),address(this),_amount);
        totalStaked+=_amount;

        emit Stake(_msgSender(), _amount, _lockPeriod, _tier);
    }

    function UnstakeTokens() public {
        User memory wUser = deposit[_msgSender()];

        require(wUser.amount > 0, "deposit first");
        require(block.timestamp > wUser.lockPeriod, "Token locked");

        token.transfer(_msgSender(),wUser.amount);

        deposit[_msgSender()] = User(0, 0 , 0, 0, 0);
        totalStaked-=wUser.amount;

        if(apyEnabled){
                _claim();
        }

        emit Unstake(_msgSender(), block.timestamp);
    }

    function EarlyUnstakeTokens() public {
        User memory wUser = deposit[_msgSender()];

        require(wUser.amount > 0, "deposit first");
        require(block.timestamp < wUser.lockPeriod, "Try Standar Unstake");
        
        uint256 _fee = wUser.amount.mul(earlyUstakeFee).div(100);

        token.transfer(_msgSender(), wUser.amount.sub(_fee));
        token.transfer(rewardingTokenWallet, _fee);

        deposit[_msgSender()] = User(0, 0 , 0, block.timestamp, block.timestamp);
        totalStaked-=wUser.amount;
        
        emit Unstake(_msgSender(), block.timestamp);
    }

    function _claim() internal {
        User storage info = deposit[_msgSender()];
        uint256 reward = 0;

        if(block.timestamp + 1 seconds > info.lastClaimTime){
                uint256 timeStaked = (block.timestamp) - (info.lastClaimTime);
                timeStaked = timeStaked / 1 seconds;

                if(info.tier == 1){
                    reward = apyTier1 * timeStaked;
                } else if(info.tier == 2){
                    reward = apyTier2 * timeStaked;
                } else if(info.tier == 3){
                    reward = apyTier3 * timeStaked;
                } else if(info.tier == 4){
                    reward = apyTier4 * timeStaked;
                } else if(info.tier == 5){
                    reward = apyTier5 * timeStaked;
                }
        }
        
        if( reward > 0 && reward <= pendingRewards() ){
            token.transferFrom(rewardingTokenWallet , _msgSender() , reward);
        } else{
            require(false, "Pending Rewards Not Allocated");
        }
        
        info.lastClaimTime = block.timestamp;
        emit Claim(_msgSender() , reward);
    }

    function claim() public {
        User memory info = deposit[_msgSender()];
        require(info.amount > 0, "Not Staked");
        require(apyEnabled, "No reward");
        _claim();
    }

    function pendingRewards() public view returns (uint256){
      return token.allowance(rewardingTokenWallet , address(this));
    }

    function withdrawAnyTokens(address _token, address recipient, uint256 amount) public onlyOwner{
        IBEP20 anyToken = IBEP20(_token);
        anyToken.transfer(recipient, amount);
        emit WithdrawToken(recipient, amount);
    }

    function withdrawFunds() public onlyOwner{
       _msgSender().transfer(address(this).balance);
       emit Withdraw(_msgSender());
    }

    receive() external payable{}
}