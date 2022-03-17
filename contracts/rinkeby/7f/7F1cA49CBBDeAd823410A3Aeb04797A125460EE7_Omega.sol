/**
 *Submitted for verification at Etherscan.io on 2022-03-17
*/

//SPDX-License-Identifier: UNLICENSED
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
 
contract Pausable is Ownable {
   event Pause();
   event Unpause();
 
   bool public paused = false;
 
 
   /**
   * @dev Modifier to make a function callable only when the contract is not paused.
   */
   modifier whenNotPaused() {
       require(!paused);
       _;
   }
 
   /**
   * @dev Modifier to make a function callable only when the contract is paused.
   */
   modifier whenPaused() {
       require(paused);
       _;
   }
 
   /**
   * @dev called by the owner to pause, triggers stopped state
   */
   function pause() onlyOwner whenNotPaused public {
       paused = true;
       emit Pause();
   }
 
   /**
   * @dev called by the owner to unpause, returns to normal state
   */
   function unpause() onlyOwner whenPaused public {
       paused = false;
       emit Unpause();
   }
}
 

// TODO: Pool counter to be added
 
contract Omega is Ownable, Pausable {      
    using SafeMath for uint256;
    string public name = "Omega Pools";
    IERC20 private usdtToken;
    IERC20 private omegaToken;
    address[] private stakers;
    
    mapping(address=>uint256) private stakingStartTime; // to manage the time when the user started the staking
    mapping(address=>uint256) private withdrawTime; // to manage the time when the user started the staking
    mapping(address => uint) private investmentPool;     // to manage the staking of usdtToken and distibue the profit as usdtToken B
    mapping(address => bool) private hasStaked;
    mapping(address => bool) public isStaking;
    mapping(address =>uint256) public redeemedAt;
    mapping(address =>uint256) public restakingAt;
    mapping(address =>uint256) private stakedOmega;
    mapping(address =>uint256) public userTerms;
    mapping(address =>uint256) private userRates;

    uint256 private totalPools;
    
    uint256 private totalInvestmentPoolBalance;

    enum terms { one, three, six} //Months 0,1,2    
    
    uint256 private oneMonth = 300;
    uint256 private threeMonth = 600;
    uint256 private sixMonth = 900;

    uint256 private omegaPercent = 10;
 
    // mapping(address => mapping(address => uint256)) userAmount;
 
    constructor(IERC20 _token, IERC20 _omegaToken) {
        usdtToken = _token;
        omegaToken = _omegaToken;
    }
 
    /* Stakes Tokens (Deposit): An investor will deposit the usdtToken into the smart contracts
    to starting earning rewards.
        
    Core Thing: Transfer the usdtToken from the investor's wallet to this smart contract. */
    function staketoken(uint _amount, terms time) public whenNotPaused {       
        require(_amount > 0, "staking balance cannot be 0");
        require(usdtToken.balanceOf(msg.sender) > _amount);
        require(!hasStaked[msg.sender], "already diposited"); 
        uint256 omegaAmount = _amount.mul(omegaPercent).div(100);
        require(omegaToken.balanceOf(msg.sender) > omegaAmount);
          
        usdtToken.transferFrom(msg.sender, address(this), _amount);
        // Take 10% Omega
        omegaToken.transferFrom(msg.sender, address(this), omegaAmount);
        // UPDATES
        if(time == terms.one){
            userTerms[msg.sender] = oneMonth;  
            userRates[msg.sender] = 2;         
        }
        if(time == terms.three){
            userTerms[msg.sender] = threeMonth;  
            userRates[msg.sender] = 3;                  
        }
        if(time == terms.six){
            userTerms[msg.sender] = sixMonth; 
            userRates[msg.sender] = 5;                  
        }
        stakers.push(msg.sender);
        stakingStartTime[msg.sender] = block.timestamp;
        investmentPool[msg.sender] = _amount;
        totalInvestmentPoolBalance += _amount;
        stakedOmega[msg.sender] = omegaAmount;
        totalPools++;
        isStaking[msg.sender] = true;
        hasStaked[msg.sender] = true;
    }
 
    function calculateReward(uint256 stakeBalance) internal virtual returns(uint256){
        uint256 reward = stakeBalance.mul(userRates[msg.sender]).div(100);
        return reward;
    }

    function redeemInterest() public whenNotPaused {
        require(isStaking[msg.sender], "User have no staked tokens to get the reward");
        uint balance = investmentPool[msg.sender];
        require(balance > 0, "staking balance cannot be 0");
        require(block.timestamp - restakingAt[msg.sender] >= userTerms[msg.sender], "Amount has been used for restaking");
        uint256 startTime = stakingStartTime[msg.sender];
        require(block.timestamp - startTime >= userTerms[msg.sender], "No Interest to redeem");
        uint256 reward = calculateReward(balance);
        require(usdtToken.balanceOf(address(this)) > reward, "Not Enough tokens in the smart contract");
        usdtToken.transfer(msg.sender, reward);
        redeemedAt[msg.sender] = block.timestamp;
    }

    function restake() public whenNotPaused {
        require(isStaking[msg.sender], "User have no staked tokens to get the reward");
        uint balance = investmentPool[msg.sender];
        require(balance > 0, "staking balance cannot be 0");
        uint256 startTime = stakingStartTime[msg.sender];
        require(block.timestamp - startTime >=  userTerms[msg.sender], "cannot restake before terms");
        uint256 restakingAmount = calculateReward(balance);
        investmentPool[msg.sender] += restakingAmount;
        totalInvestmentPoolBalance += restakingAmount;   
        restakingAt[msg.sender] = block.timestamp;
    }

    function withdraw() public whenNotPaused {
        require(isStaking[msg.sender], "User have no staked tokens to get the reward");
        uint balance = investmentPool[msg.sender];
        require(balance > 0, "staking balance cannot be 0");
        uint256 startTime = stakingStartTime[msg.sender];
        uint256 reward = calculateReward(balance);
        if(block.timestamp - startTime >= userTerms[msg.sender]){
            if((block.timestamp - redeemedAt[msg.sender] >= userTerms[msg.sender]) && (block.timestamp - restakingAt[msg.sender] >= userTerms[msg.sender])){
                uint256 totalAmount = reward.add(balance).add(stakedOmega[msg.sender]);
                require(usdtToken.balanceOf(address(this)) > totalAmount, "Not Enough tokens in the smart contract");
                usdtToken.transfer(msg.sender, totalAmount);
            }else{
                uint256 totalAmount = balance.add(stakedOmega[msg.sender]);
                require(usdtToken.balanceOf(address(this)) > totalAmount, "Not Enough tokens in the smart contract");
                usdtToken.transfer(msg.sender, totalAmount);
            }
        }else{
            require(usdtToken.balanceOf(address(this))> balance, "Not enough balance in the Pool");
            usdtToken.transfer(msg.sender, balance);
        }
        // UPDATES
        isStaking[msg.sender] = false;
        investmentPool[msg.sender] = 0;
        withdrawTime[msg.sender] = block.timestamp;
    }

    function setOmegaToken(IERC20 _token) external onlyOwner whenNotPaused {
        omegaToken = _token;
    }
 
    /**
        * @dev withdraw all bnb from the smart contract
    */ 
  
    function withdrawBNBFromContract(uint256 _amount, address payable _reciever) external onlyOwner returns(bool){
        _reciever.transfer(_amount);
        return true;
    }
  
    function withdrawTokenFromContract(address tokenAddress, uint256 amount, address receiver) external onlyOwner {
        require(IERC20(tokenAddress).balanceOf(address(this))>= amount, "Insufficient amount to transfer");
        IERC20(tokenAddress).transfer(receiver,amount);
    }
 
}