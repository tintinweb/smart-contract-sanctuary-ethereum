/**
 *Submitted for verification at Etherscan.io on 2023-01-05
*/

// SPDX-License-Identifier: GPL-3.0
pragma solidity >=0.7.0 <0.9.0;

/*
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
        this; // silence state mutability warning without generating bytecode - see https://github.com/ethereum/solidity/issues/2691
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
    constructor () {
        address msgSender = _msgSender();
        _owner = msgSender;
        emit OwnershipTransferred(address(0), msgSender);
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
        emit OwnershipTransferred(_owner, address(0));
        _owner = address(0);
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        emit OwnershipTransferred(_owner, newOwner);
        _owner = newOwner;
    }
}

// CAUTION
// This version of SafeMath should only be used with Solidity 0.8 or later,
// because it relies on the compiler's built in overflow checks.

/**
 * @dev Wrappers over Solidity's arithmetic operations.
 *
 * NOTE: `SafeMath` is no longer needed starting with Solidity 0.8. The compiler
 * now has built in overflow checking.
 */
library SafeMath {
    /**
     * @dev Returns the addition of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function tryAdd(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            uint256 c = a + b;
            if (c < a) return (false, 0);
            return (true, c);
        }
    }

    /**
     * @dev Returns the substraction of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function trySub(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            if (b > a) return (false, 0);
            return (true, a - b);
        }
    }

    /**
     * @dev Returns the multiplication of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function tryMul(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            // Gas optimization: this is cheaper than requiring 'a' not being zero, but the
            // benefit is lost if 'b' is also tested.
            // See: https://github.com/OpenZeppelin/openzeppelin-contracts/pull/522
            if (a == 0) return (true, 0);
            uint256 c = a * b;
            if (c / a != b) return (false, 0);
            return (true, c);
        }
    }

    /**
     * @dev Returns the division of two unsigned integers, with a division by zero flag.
     *
     * _Available since v3.4._
     */
    function tryDiv(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            if (b == 0) return (false, 0);
            return (true, a / b);
        }
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers, with a division by zero flag.
     *
     * _Available since v3.4._
     */
    function tryMod(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            if (b == 0) return (false, 0);
            return (true, a % b);
        }
    }

    /**
     * @dev Returns the addition of two unsigned integers, reverting on
     * overflow.
     *
     * Counterpart to Solidity's `+` operator.
     *
     * Requirements:
     *
     * - Addition cannot overflow.
     */
    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        return a + b;
    }

    /**
     * @dev Returns the subtraction of two unsigned integers, reverting on
     * overflow (when the result is negative).
     *
     * Counterpart to Solidity's `-` operator.
     *
     * Requirements:
     *
     * - Subtraction cannot overflow.
     */
    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        return a - b;
    }

    /**
     * @dev Returns the multiplication of two unsigned integers, reverting on
     * overflow.
     *
     * Counterpart to Solidity's `*` operator.
     *
     * Requirements:
     *
     * - Multiplication cannot overflow.
     */
    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        return a * b;
    }

    /**
     * @dev Returns the integer division of two unsigned integers, reverting on
     * division by zero. The result is rounded towards zero.
     *
     * Counterpart to Solidity's `/` operator.
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        return a / b;
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers. (unsigned integer modulo),
     * reverting when dividing by zero.
     *
     * Counterpart to Solidity's `%` operator. This function uses a `revert`
     * opcode (which leaves remaining gas untouched) while Solidity uses an
     * invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function mod(uint256 a, uint256 b) internal pure returns (uint256) {
        return a % b;
    }

    /**
     * @dev Returns the subtraction of two unsigned integers, reverting with custom message on
     * overflow (when the result is negative).
     *
     * CAUTION: This function is deprecated because it requires allocating memory for the error
     * message unnecessarily. For custom revert reasons use {trySub}.
     *
     * Counterpart to Solidity's `-` operator.
     *
     * Requirements:
     *
     * - Subtraction cannot overflow.
     */
    function sub(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        unchecked {
            require(b <= a, errorMessage);
            return a - b;
        }
    }

    /**
     * @dev Returns the integer division of two unsigned integers, reverting with custom message on
     * division by zero. The result is rounded towards zero.
     *
     * Counterpart to Solidity's `%` operator. This function uses a `revert`
     * opcode (which leaves remaining gas untouched) while Solidity uses an
     * invalid opcode to revert (consuming all remaining gas).
     *
     * Counterpart to Solidity's `/` operator. Note: this function uses a
     * `revert` opcode (which leaves remaining gas untouched) while Solidity
     * uses an invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function div(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        unchecked {
            require(b > 0, errorMessage);
            return a / b;
        }
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers. (unsigned integer modulo),
     * reverting with custom message when dividing by zero.
     *
     * CAUTION: This function is deprecated because it requires allocating memory for the error
     * message unnecessarily. For custom revert reasons use {tryMod}.
     *
     * Counterpart to Solidity's `%` operator. This function uses a `revert`
     * opcode (which leaves remaining gas untouched) while Solidity uses an
     * invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function mod(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        unchecked {
            require(b > 0, errorMessage);
            return a % b;
        }
    }
}
interface IERC20 {
    function totalSupply() external view returns (uint256);
    function balanceOf(address account) external view returns (uint256);
    function transfer(address recipient, uint256 amount) external returns (bool);
    function allowance(address owner, address spender) external view returns (uint256);
    function approve(address spender, uint256 amount) external returns (bool);
    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);
    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed owner, address indexed spender, uint256 value);
}
contract EdverseStaking is  Ownable {
using SafeMath for uint256;  
  event Stake (address indexed user,uint256 stakeAmount);
  event CapitalWithdraw (address indexed user,uint256 capitalAmount);
  event ClaimReward (address indexed user,uint256 amount);

  IERC20 public ERC20 = IERC20(0x3854392ec5236182B164c44E358da64b40e4790f);
  bool public paused = false; 

  uint public duration = 1;//43200;// in Hours ;
uint256 public totalStakeToken;
  uint256 public totalRewardWithdraw;

    struct _options {
      address user;
      uint256 token;
      uint256 withdrawReward;
     // uint256 reward;

      uint256 interestPercent;
      //uint256 interestFeePercent;
      uint256 stakeTime;
     // uint256 capitalWithdrawTime;
      uint256 interestWithdrawTime;
     // uint256 newRewardTime;
      uint256 daysLimit;
      //uint256 duration;
      bool isActive;
      bool isCapitalWithdraw;
  }

  mapping(address => _options[]) public options;
 mapping(uint256 => uint256) public DaysLimitRewardForStake;

constructor() { 
      DaysLimitRewardForStake[1] = 1000; // 1% ;
      DaysLimitRewardForStake[2] = 1800; // 1.8%;
     DaysLimitRewardForStake[3] = 3600; // 3.6%;
   }

   function getOPtions(address user) view public returns(_options[] memory){
        return options[user];
    }

     function getInterestPercent( uint256 daysLimit) public view returns(uint256 fee) {
        if(daysLimit == 0){
            fee = 0;// (token > minPercentTokenLimit * (10**18) ) ? maximumPercent : minimumPercent;  // 0.4% or 0.15 Decimal number of 0.4 * 10**3 ;
        }else{
            fee = DaysLimitRewardForStake[daysLimit];
        }
    }

    function stake(uint256 token, uint256 dayLimit) public  returns(uint256 optionId){
        require(!paused, "the contract is paused");
         require(ERC20.allowance(msg.sender,address(this)) > token, "Insufficient token allowance for transfer");
        require(dayLimit != 0 || DaysLimitRewardForStake[dayLimit] > 0, "Invalid Days limit");
        ERC20.transferFrom(msg.sender,address(this),token); 
        uint256 InterestPercent = DaysLimitRewardForStake[dayLimit];
        totalStakeToken = totalStakeToken.add(token);
        options[msg.sender].push(_options(msg.sender,token,0,InterestPercent,block.timestamp,0,dayLimit,true,false));
            optionId = options[msg.sender].length;
        emit Stake(msg.sender,token);
    }

function calculateReward(address user, uint256 optionId) public view returns(uint256 interestAmount, uint256 stakeTime) {
        require(!paused, "the contract is paused");
require(options[user][optionId].isActive,"The user is not active");
require(!(options[user][optionId].isCapitalWithdraw),"Already claimed staked amount");

 stakeTime = (options[user][optionId].interestWithdrawTime > 0) ? options[user][optionId].interestWithdrawTime : options[user][optionId].stakeTime;
 uint256 _duration =  block.timestamp.sub(stakeTime)/duration;
              // require(_duration>0,"There is no reward");
              if(_duration<0){
   interestAmount=0;
   
              }else{
interestAmount = ((options[user][optionId].token.mul(options[user][optionId].interestPercent)).div(100)).mul(_duration);

              }
}

function claimReward(uint256 optionId) public  returns(bool){
        require(!paused, "the contract is paused");
        require(options[msg.sender][optionId].isActive, "Invalid Option ID");        

        (uint256 stakeTime,uint256 rewardAmount) = calculateReward(msg.sender,optionId);       
        
        require(rewardAmount > 0, "You don't have reward amount");
        require(ERC20.balanceOf(address(this)) >= rewardAmount, "Pool Error : Insufficient token in pool for withdraw");
        ERC20.transfer(msg.sender,rewardAmount);
        
        totalRewardWithdraw = totalRewardWithdraw.add(rewardAmount);
        options[msg.sender][optionId].withdrawReward = options[msg.sender][optionId].withdrawReward.add(rewardAmount);

       options[msg.sender][optionId].interestWithdrawTime = block.timestamp;
        emit ClaimReward(msg.sender, rewardAmount);
        return true;
    }
  function withdrawCapital(uint256 optionId) public  returns(bool) {
         require(!paused, "the contract is paused");
        require(options[msg.sender][optionId].isActive, "Invalid Option ID");
        require(!options[msg.sender][optionId].isCapitalWithdraw, "Pool Error : Capital amount already withdraw");
        uint256 withdrawDay = 86400 * options[msg.sender][optionId].daysLimit; // days
        uint256 capitalAmount = options[msg.sender][optionId].token;
        require(options[msg.sender][optionId].stakeTime.add(withdrawDay) <= block.timestamp, "Pool Error : Lock time period not completed yet");
        require(ERC20.balanceOf(address(this)) >= capitalAmount, "Pool Error : Insufficient token in pool for withdraw");
        ERC20.transfer(msg.sender,capitalAmount);

        options[msg.sender][optionId].isCapitalWithdraw = true;
        //options[msg.sender][optionId].capitalWithdrawTime = block.timestamp;
        emit CapitalWithdraw(msg.sender, capitalAmount);
        return true;
      
    }


}