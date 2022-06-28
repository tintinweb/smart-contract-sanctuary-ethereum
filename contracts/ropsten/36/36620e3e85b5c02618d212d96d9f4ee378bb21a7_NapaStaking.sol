/**
 *Submitted for verification at Etherscan.io on 2022-06-28
*/

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

// File: contracts\IERC20.sol


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


contract NapaStaking is Ownable{

    IERC20 immutable private token;
    uint256 public totalStaked;
    // mapping(uint=>uint) public packages;
  
   uint[4] packages;
   mapping(uint=>bool)plan;
   address public treasuryWallet;

   // user structer
    struct User {
        uint256 plan;
        uint256 amount;
        uint startTime;
        uint endTime;
    }
    // total deposited
    mapping(address => User) public deposit;

    //Events
    event Stake(address indexed staker, uint256 _amount, uint256 _lockPeriod );
    event Unstake(address indexed unstaker, uint256 unstakeTime);
    event Claim(address staker, uint256 reward);
    event Withdraw(address indexed withdrawer);
    event WithdrawToken(address indexed withdrawer, uint256 amount);


    constructor(address token_, address _rewardWallet)  {
        require(token_ != address(0x0));
        token = IERC20(token_);
        packages[0]=30;
        packages[1]=60;
        packages[2]=90;
        packages[3]=120;
        plan[30]=true;
        plan[60]=true;
        plan[90]=true;
        plan[120]=true;
        treasuryWallet = address(_rewardWallet);

    }
    // function getBalance() public view returns(uint){
    //     return token.totalSupply();
    // }
    function  updateTreasuryWallet(address _treasuryWallet) public{
         treasuryWallet = _treasuryWallet;       
    }

    function stakeTokens(uint256 _amount, uint256 _plan) public {
        require(token.balanceOf(_msgSender())>=_amount, "you do not have sufficient balance");
        require(token.allowance(_msgSender(), address(this))>=_amount, "Tokens not approved");

        require(plan[_plan], "select correct tier");
        User memory wUser = deposit[_msgSender()];
        require(wUser.amount == 0, "Already Staked");
        
        deposit[_msgSender()] = User(_plan, _amount,block.timestamp,block.timestamp+(_plan));

        token.transferFrom(_msgSender(),address(this),_amount);
        totalStaked+=_amount;
        emit Stake(_msgSender(), _amount,_plan);
    }

    function UnstakeTokens() public {
        User memory wUser = deposit[_msgSender()];

        require(wUser.amount > 0, "deposit first");
        require(block.timestamp > wUser.endTime, "Token locked");
        uint reward=_claim();

        uint rewardCheck=token.balanceOf(treasuryWallet);
        require(rewardCheck>reward,"not suffiecint rewards available");
        token.transferFrom(treasuryWallet,_msgSender(),reward);
        token.transfer(_msgSender(),wUser.amount);

        deposit[_msgSender()] = User(0, 0 , 0, 0);
        totalStaked-=wUser.amount;

        emit Unstake(_msgSender(), block.timestamp);
    }
    
    function _claim()  internal  returns (uint) {
        User storage info = deposit[_msgSender()];
        require(info.amount > 0, "Not Staked");
         uint _reward=0;

         if(block.timestamp + 1  > info.startTime){
                // uint256 timeStaked = (block.timestamp) - (info.startTime+ 1 days);
                uint256 timeStaked = (block.timestamp) - (info.startTime+ 1 );
                // timeStaked = timeStaked / 1 days;
                timeStaked = timeStaked;
                _reward= timeStaked*10**15;
                if(info.plan == 30){
                    _reward += (10* info.amount/100);
                } else if(info.plan == 60){
                     _reward+= 1279* info.amount/10000;
                } else if(info.plan == 90){
                    _reward += 1729* info.amount/10000;
                } else if(info.plan== 120){
                     _reward += 2218 * info.amount/10000;
                }
            }
     
        emit Claim(_msgSender() , _reward); 
        return _reward;
       }


    function checkReward()  public  view  returns (uint) {
        User storage info = deposit[_msgSender()];
        require(info.amount > 0, "Not Staked");
         uint _reward=0;
         if(block.timestamp + 1  > info.startTime){
                uint256 timeStaked = (block.timestamp) - (info.startTime+1);
                // timeStaked = timeStaked / 1 days;
                timeStaked = timeStaked ;
                _reward= timeStaked*10**15;
                if(info.plan == 30){
                    _reward += (10* info.amount/100);
                } else if(info.plan == 60){
                     _reward+= 1279* info.amount/10000;
                } else if(info.plan == 90){
                    _reward += 1729* info.amount/10000;
                } else if(info.plan== 120){
                     _reward += 2218 * info.amount/10000;
                }
               
       
            }
        
        
        return _reward;
    }

    function withdrawAnyTokens(address _token, address recipient, uint256 amount) public onlyOwner{
        IERC20 anyToken = IERC20(_token);
        require(token != anyToken, "can't withdraw staking token");
        anyToken.transfer(recipient, amount);
        emit WithdrawToken(recipient, amount);
    }

    function withdrawFunds() public onlyOwner{
       payable(_msgSender()).transfer(address(this).balance);
       emit Withdraw(_msgSender());
    }
}