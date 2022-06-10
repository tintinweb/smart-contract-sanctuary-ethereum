/**
 *Submitted for verification at Etherscan.io on 2022-06-10
*/

// SPDX-License-Identifier: MIT

// File: contracts/EnvoyStaking.sol

/**
 *Submitted for verification at Etherscan.io on 2022-02-21
*/

// File: StakingProject/IERC20.sol
// OpenZeppelin Contracts (last updated v4.5.0) (token/ERC20/IERC20.sol)
pragma solidity >=0.7.0 <0.9.0;
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
// File: @openzeppelin/contracts/utils/Context.sol
// OpenZeppelin Contracts v4.4.1 (utils/Context.sol)
 
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
// File: @openzeppelin/contracts/security/Pausable.sol
// OpenZeppelin Contracts v4.4.1 (security/Pausable.sol)
 
/**
 * @dev Contract module which allows children to implement an emergency stop
 * mechanism that can be triggered by an authorized account.
 *
 * This module is used through inheritance. It will make available the
 * modifiers `whenNotPaused` and `whenPaused`, which can be applied to
 * the functions of your contract. Note that they will not be pausable by
 * simply including this module, only once the modifiers are put in place.
 */
abstract contract Pausable is Context {
    /**
     * @dev Emitted when the pause is triggered by `account`.
     */
    event Paused(address account);
    /**
     * @dev Emitted when the pause is lifted by `account`.
     */
    event Unpaused(address account);
    bool private _paused;
    /**
     * @dev Initializes the contract in unpaused state.
     */
    constructor() {
        _paused = false;
    }
    /**
     * @dev Returns true if the contract is paused, and false otherwise.
     */
    function paused() public view virtual returns (bool) {
        return _paused;
    }
    /**
     * @dev Modifier to make a function callable only when the contract is not paused.
     *
     * Requirements:
     *
     * - The contract must not be paused.
     */
    modifier whenNotPaused() {
        require(!paused(), "Pausable: paused");
        _;
    }
    /**
     * @dev Modifier to make a function callable only when the contract is paused.
     *
     * Requirements:
     *
     * - The contract must be paused.
     */
    modifier whenPaused() {
        require(paused(), "Pausable: not paused");
        _;
    }
    /**
     * @dev Triggers stopped state.
     *
     * Requirements:
     *
     * - The contract must not be paused.
     */
    function _pause() internal virtual whenNotPaused {
        _paused = true;
        emit Paused(_msgSender());
    }
    /**
     * @dev Returns to normal state.
     *
     * Requirements:
     *
     * - The contract must be paused.
     */
    function _unpause() internal virtual whenPaused {
        _paused = false;
        emit Unpaused(_msgSender());
    }
}
// File: @openzeppelin/contracts/security/ReentrancyGuard.sol
// OpenZeppelin Contracts v4.4.1 (security/ReentrancyGuard.sol)
 
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
// File: StakingProject/safeMath.sol
 
library SafeMath {
 
    function tryAdd(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            uint256 c = a + b;
            if (c < a) return (false, 0);
            return (true, c);
        }
    }
 
    function trySub(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            if (b > a) return (false, 0);
            return (true, a - b);
        }
    }
 
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
 
    function tryDiv(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            if (b == 0) return (false, 0);
            return (true, a / b);
        }
    }
 
    function tryMod(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            if (b == 0) return (false, 0);
            return (true, a % b);
        }
    }
 
    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        return a + b;
    }
 
    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        return a - b;
    }
 
    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        return a * b;
    }
 
    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        return a / b;
    }
 
    function mod(uint256 a, uint256 b) internal pure returns (uint256) {
        return a % b;
    }
 
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
 
    function mod(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        unchecked {
            require(b > 0, errorMessage);
            return a % b;
        }
    }
}
// File: StakingProject/StakeInvo.sol
 
 contract StakingContract is ReentrancyGuard, Pausable{
   
    using SafeMath for uint256;
 
    /* ========== STATE VARIABLES ========== */
    IERC20 public rewardsToken;
    IERC20 public stakingToken;
   
         

    uint256 public minStake;
  
    mapping(address => uint256) public rewards;
    uint256 private _totalSupply;
    mapping(address => uint256) private _balances;
    address public owner;
    uint256 public AllUserStakes;
    uint256 public AllStakedTokens;
    uint256 public AllrewardTokens;
    /* ========== EVENTS ========== */
   
   

     /* ==========struct ========== */
struct Stake {
        uint256 stakeTime;
        uint256 withdrawTime;
        uint256 amount;
        uint256 bonus;
        uint256 plan;
        bool withdrawan;
        bool rewardGet;
        uint256 allTime;
    
    }
        
    struct User {

        uint256 userTotalStaked;
        uint256 remainingStake;
        uint256 stakeCount;
        uint256 totalRewardTokens;

        mapping(uint256 => Stake) stakerecord;
    }

    mapping(address => User) public users;


    uint256[3] public durations = [1 minutes, 2 minutes, 3 minutes];
 
    /* ========== CONSTRUCTOR ========== */
    constructor( 
        address _rewardsToken,
        address _stakingToken
    )  {
        rewardsToken = IERC20(_rewardsToken);
        stakingToken = IERC20(_stakingToken); 
        minStake = 1e18;
        owner = msg.sender;
    }

/*===========Events================-*/
event UnStakeBeforeTimeCompletion(uint256 withdraTokenwAmount , address sender , address reciever );
event UnstakeOnTimeCompletion(uint256 withdrawTokenAmount , uint256 rewardTokenAmount , address sender , address reciever);
event StakeRecord(
    uint256 stakeAmount , 
    uint256 stakingPlan ,
    uint256 withDrawTime ,
    uint256 rewardCalculations,
    address stakerAddress
    );

/* ========== FUNCTIONS ========== */
// User can stake tokens this function to stake the contract 

function staking(uint256 amount, uint256 plan)  external nonReentrant whenNotPaused {

        require(plan >= 0 && plan < 3, "put valid plan details");
        require(amount > minStake,"cant deposit need to stake more than minimum amount");
        require(msg.sender != address(0), "User address canot be zero.");
        require(owner != address(0), "Owner address canot be zero.");

        User storage user = users[msg.sender];
        user.stakeCount++;
        AllUserStakes++;
        stakingToken.transferFrom(msg.sender, owner, amount);
        user.userTotalStaked += amount;
        user.remainingStake+=amount;
        user.stakerecord[user.stakeCount].plan = plan;
        user.stakerecord[user.stakeCount].stakeTime = block.timestamp;
        user.stakerecord[user.stakeCount].amount = amount;
        user.stakerecord[user.stakeCount].withdrawTime = block.timestamp.add(durations[plan]);
        user.stakerecord[user.stakeCount].bonus = rewardCalculate(plan);
    
        _totalSupply = _totalSupply.add(amount);
        _balances[msg.sender] = _balances[msg.sender].add(amount);

emit StakeRecord(
    user.stakerecord[user.stakeCount].amount ,
    user.stakerecord[user.stakeCount].plan , 
    user.stakerecord[user.stakeCount].withdrawTime,
    user.stakerecord[user.stakeCount].bonus ,
    msg.sender) ;

}

function unstakeBeforeTime(uint256 count) public nonReentrant {
    
    User storage user = users[msg.sender];
    user.stakerecord[count].allTime = user.stakerecord[count].stakeTime + block.timestamp;
    
    require(user.stakeCount>=count,"Invalide Stakeindex");
    require(msg.sender != address(0), "User address canot be zero.");
    require(owner != address(0), "Owner address canot be zero.");       
    require(rewardsToken.balanceOf(owner) >= user.stakerecord[count].amount,"owner doesnt have enough balance");
    require(!user.stakerecord[count].withdrawan," withdraw completed ");

    stakingToken.transferFrom(owner,msg.sender,user.stakerecord[count].amount);
    user.remainingStake-=user.stakerecord[user.stakeCount].amount;
    user.stakerecord[count].withdrawan = true;

    _balances[msg.sender] = _balances[msg.sender].sub(user.stakerecord[count].amount);
   

    emit UnStakeBeforeTimeCompletion(user.stakerecord[count].amount , owner , msg.sender);

}




function unstakeUponTime(uint256 count) public {
    
        User storage user = users[msg.sender];
    
        require(user.stakeCount >= count, "Invalid Stake index");
        require(!user.stakerecord[count].withdrawan," withdraw completed ");
        require(msg.sender != address(0), "User address canot be zero.");
        require(owner != address(0), "Owner address canot be zero.");
        
        require(block.timestamp >= user.stakerecord[count].withdrawTime,"You can not withdraw amount before time");
        
        stakingToken.transferFrom(owner,msg.sender,user.stakerecord[count].amount);
        rewardsToken.transferFrom(owner,msg.sender,user.stakerecord[count].bonus);

        user.remainingStake-=user.stakerecord[user.stakeCount].amount;
        user.stakerecord[count].withdrawan = true;
        user.totalRewardTokens += user.stakerecord[count].bonus;

    // New Added Variables---------------------------    
        AllrewardTokens += user.stakerecord[count].bonus;
  
    emit UnstakeOnTimeCompletion(user.stakerecord[count].amount , user.stakerecord[count].bonus , owner , msg.sender );


    }

// function getReward(uint256 count)public nonReentrant {
               
//         User storage user = users[msg.sender];
//         require(user.stakeCount >= count, "Invalid Stake index");
//         require(user.stakerecord[count].bonus>0,"there's no reward");
//         require(!user.stakerecord[count].rewardGet," reward already distributed ");

//         require(block.timestamp >= user.stakerecord[count].withdrawTime,"no reward");
//         rewardsToken.transferFrom(owner,msg.sender,user.stakerecord[count].bonus);

//         rewardsToken.transferFrom(owner,msg.sender,user.stakerecord[count].bonus);
//         user.totalRewardTokens += user.stakerecord[count].bonus;
//         user.stakerecord[count].rewardGet = true;
      
// }


function rewardCalculate(uint256 plan) public pure returns(uint256){
        if (plan == 0){
            return 1000000000000000000 ;
        }else if (plan == 1){
            return 5000000000000000000;
        }else{
            return 10000000000000000000;
        }
   }


    
 
}