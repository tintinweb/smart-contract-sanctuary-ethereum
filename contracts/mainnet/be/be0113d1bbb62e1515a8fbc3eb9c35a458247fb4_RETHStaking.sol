/**
 *Submitted for verification at Etherscan.io on 2022-10-07
*/

//SPDX-License-Identifier: Unlicensed
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
// helper methods for interacting with ERC20 tokens that do not consistently return true/false
library TransferHelper {
    function safeApprove(address token, address to, uint value) internal {
        (bool success, bytes memory data) = token.call(abi.encodeWithSelector(0x095ea7b3, to, value));
        require(success && (data.length == 0 || abi.decode(data, (bool))), 'TransferHelper: APPROVE_FAILED');
    }

    function safeTransfer(address token, address to, uint value) internal {
        (bool success, bytes memory data) = token.call(abi.encodeWithSelector(0xa9059cbb, to, value));
        require(success && (data.length == 0 || abi.decode(data, (bool))), 'TransferHelper: TRANSFER_FAILED');
    }

    function safeTransferFrom(address token, address from, address to, uint value) internal {
        (bool success, bytes memory data) = token.call(abi.encodeWithSelector(0x23b872dd, from, to, value));
        require(success && (data.length == 0 || abi.decode(data, (bool))), 'TransferHelper: TRANSFER_FROM_FAILED');
    }

}


// CAUTION
// This version of SafeMath should only be used with Solidity 0.8 or later,
// because it relies on the compiler's built in overflow checks.

/**
 * @dev Wrappers over Solidity's arithmetic operations.
 *
 * NOTE: `SafeMath` is generally not needed starting with Solidity 0.8, since the compiler
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
     * @dev Returns the subtraction of two unsigned integers, with an overflow flag.
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
    function sub(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
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
    function div(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
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
    function mod(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        unchecked {
            require(b > 0, errorMessage);
            return a % b;
        }
    }
}

library FullMath {
    /// @notice Calculates floor(a├ùb├Àdenominator) with full precision. Throws if result overflows a uint256 or denominator == 0
    /// @param a The multiplicand
    /// @param b The multiplier
    /// @param denominator The divisor
    /// @return result The 256-bit result
    /// @dev Credit to Remco Bloemen under MIT license https://xn--2-umb.com/21/muldiv
    function mulDiv(
        uint256 a,
        uint256 b,
        uint256 denominator
    ) internal pure returns (uint256 result) {
        // 512-bit multiply [prod1 prod0] = a * b
        // Compute the product mod 2**256 and mod 2**256 - 1
        // then use the Chinese Remainder Theorem to reconstruct
        // the 512 bit result. The result is stored in two 256
        // variables such that product = prod1 * 2**256 + prod0
        uint256 prod0; // Least significant 256 bits of the product
        uint256 prod1; // Most significant 256 bits of the product
        assembly {
            let mm := mulmod(a, b, not(0))
            prod0 := mul(a, b)
            prod1 := sub(sub(mm, prod0), lt(mm, prod0))
        }

        // Handle non-overflow cases, 256 by 256 division
        if (prod1 == 0) {
            require(denominator > 0);
            assembly {
                result := div(prod0, denominator)
            }
            return result;
        }

        // Make sure the result is less than 2**256.
        // Also prevents denominator == 0
        require(denominator > prod1);

        ///////////////////////////////////////////////
        // 512 by 256 division.
        ///////////////////////////////////////////////

        // Make division exact by subtracting the remainder from [prod1 prod0]
        // Compute remainder using mulmod
        uint256 remainder;
        assembly {
            remainder := mulmod(a, b, denominator)
        }
        // Subtract 256 bit number from 512 bit number
        assembly {
            prod1 := sub(prod1, gt(remainder, prod0))
            prod0 := sub(prod0, remainder)
        }

        // Factor powers of two out of denominator
        // Compute largest power of two divisor of denominator.
        // Always >= 1.
        unchecked {
            uint256 twos = (type(uint256).max - denominator + 1) & denominator;
            // Divide denominator by power of two
            assembly {
                denominator := div(denominator, twos)
            }

            // Divide [prod1 prod0] by the factors of two
            assembly {
                prod0 := div(prod0, twos)
            }
            // Shift in bits from prod1 into prod0. For this we need
            // to flip `twos` such that it is 2**256 / twos.
            // If twos is zero, then it becomes one
            assembly {
                twos := add(div(sub(0, twos), twos), 1)
            }
            prod0 |= prod1 * twos;

            // Invert denominator mod 2**256
            // Now that denominator is an odd number, it has an inverse
            // modulo 2**256 such that denominator * inv = 1 mod 2**256.
            // Compute the inverse by starting with a seed that is correct
            // correct for four bits. That is, denominator * inv = 1 mod 2**4
            uint256 inv = (3 * denominator) ^ 2;
            // Now use Newton-Raphson iteration to improve the precision.
            // Thanks to Hensel's lifting lemma, this also works in modular
            // arithmetic, doubling the correct bits in each step.
            inv *= 2 - denominator * inv; // inverse mod 2**8
            inv *= 2 - denominator * inv; // inverse mod 2**16
            inv *= 2 - denominator * inv; // inverse mod 2**32
            inv *= 2 - denominator * inv; // inverse mod 2**64
            inv *= 2 - denominator * inv; // inverse mod 2**128
            inv *= 2 - denominator * inv; // inverse mod 2**256

            // Because the division is now exact we can divide by multiplying
            // with the modular inverse of denominator. This will give us the
            // correct result modulo 2**256. Since the precoditions guarantee
            // that the outcome is less than 2**256, this is the final result.
            // We don't need to compute the high bits of the result and prod1
            // is no longer required.
            result = prod0 * inv;
            return result;
        }
    }
}


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
 library VestingMathLibrary {

  // gets the withdrawable amount from a lock
  function getWithdrawableAmount (uint256 startEmission, uint256 endEmission, uint256 amount, uint256 timeStamp) internal pure returns (uint256) {
    // It is possible in some cases IUnlockCondition(condition).unlockTokens() will fail (func changes state or does not return a bool)
    // for this reason we implemented revokeCondition per lock so funds are never stuck in the contract.
    
    // Prematurely release the lock if the condition is met

    // Lock type 1 logic block (Normal Unlock on due date)
    if (startEmission == 0 || startEmission == endEmission) {
        return endEmission < timeStamp ? amount : 0;
    }
    // Lock type 2 logic block (Linear scaling lock)
    uint256 timeClamp = timeStamp;
    if (timeClamp > endEmission) {
        timeClamp = endEmission;
    }
    if (timeClamp < startEmission) {
        timeClamp = startEmission;
    }
    uint256 elapsed = timeClamp - startEmission;
    uint256 fullPeriod = endEmission - startEmission;
    return FullMath.mulDiv(amount, elapsed, fullPeriod); // fullPeriod cannot equal zero due to earlier checks and restraints when locking tokens (startEmission < endEmission)
  }
}
abstract contract ReentrancyGuard {
    // Booleans are more expensive than uint256 or any type that takes up a full
    // word because each write operation emits an extra SLOAD to first read the
    // slot's contents, replace the bits taken up by the boolean, and then write
    // back. This is the compiler's defense against contract upgrades and
    // pointer aliasing, and it cannot be disabled.

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


contract TokenVesting is Ownable, ReentrancyGuard {
    using SafeMath for uint256;
    IERC20 public RETH;

    constructor(IERC20 reth) {
        RETH = reth;
    }

    struct UserInfo {
     uint256[] locksForToken; // map erc20 address to lockId for that token
    }

  struct TokenLock {
    uint256 tokensDeposited; // the total amount of tokens deposited
    uint256 tokensWithdrawn; // amount of tokens withdrawn
    uint256 startEmission; // date token emission begins
    uint256 endEmission; // the date the tokens can be withdrawn
    uint256 lockID; // lock id per token lock
    address owner; // the owner who can edit or withdraw the lock
    uint256 poolId;
    uint256 stakeId;
    }
    struct LockParams {
    address payable owner; // the user who can withdraw tokens once the lock expires.
    uint256 tokensDeposited; // amount of tokens to lock
    uint256 startEmission; // 0 if lock type 1, else a unix timestamp
    uint256 endEmission; // the unlock date as a unix timestamp (in seconds)
    uint256 poolId;
    uint256 stakeId;
    }


 mapping(uint256 => TokenLock) public LOCKS; // map lockID nonce to the lock
 mapping(address => UserInfo) private USERS;
 mapping(address=>bool) public BLACKLIST;
 uint256 public NONCE = 1; // incremental lock nonce counter, this is the unique ID for the next lock
 uint256 public totalAmount_;
 event onLock(uint256 lockID, address token, address owner, uint256 amountInTokens, uint256 startEmission, uint256 endEmission);
 event onTransferLock(uint256 lockId, address oldOwner, address newOwner);
 event onWithdraw(uint256 lockId, uint256 amountInTokens);



function lockRewards(LockParams memory _lock_params) internal {
    address _token = address(RETH);
     LockParams memory lock_param = _lock_params;


        totalAmount_ += _lock_params.tokensDeposited;
        uint256 endtime = _lock_params.endEmission;
        require(endtime>block.timestamp, "End time should be of future");


        require(lock_param.startEmission < lock_param.endEmission, 'PERIOD');
        require(lock_param.endEmission < 1e10, 'TIMESTAMP INVALID'); // prevents errors when timestamp entered in milliseconds
        
        TokenLock memory token_lock;
        token_lock.tokensDeposited = lock_param.tokensDeposited;
        token_lock.startEmission = lock_param.startEmission;
        token_lock.endEmission = lock_param.endEmission;
        token_lock.lockID = NONCE;
        token_lock.owner = lock_param.owner;
        token_lock.stakeId = lock_param.stakeId;
        token_lock.poolId = lock_param.poolId;

        // record the lock globally
        LOCKS[NONCE] = token_lock;
    
        // record the lock for the user
        UserInfo storage user = USERS[lock_param.owner];
        user.locksForToken.push(NONCE);
        
        NONCE ++;
        emit onLock(token_lock.lockID, _token, token_lock.owner, token_lock.tokensDeposited, token_lock.startEmission, token_lock.endEmission);
    
}



  function getWithdrawableTokens(uint256 _lockID) public view returns (uint256) {
    TokenLock storage userLock = LOCKS[_lockID];
    uint8 lockType = userLock.startEmission == 0 ? 1 : 2;
    uint256 amount = lockType == 1 ? userLock.tokensDeposited - userLock.tokensWithdrawn : userLock.tokensDeposited;
    uint256 withdrawable;
    withdrawable = VestingMathLibrary.getWithdrawableAmount (
      userLock.startEmission, 
      userLock.endEmission, 
      amount,
      block.timestamp
    );    
    return withdrawable;
  }



    // For use in UI, returns more useful lock Data than just querying LOCKS,
  // such as the real-time token amount representation of a locks shares
  function getLock (uint256 _lockID) public view returns (TokenLock memory) {
      TokenLock memory tokenLock = LOCKS[_lockID];
      return(tokenLock);
  }


 
  function transferRewardLock(uint256 _lockID, address newOwner) external nonReentrant {
        require(LOCKS[_lockID].owner == msg.sender);
        require(BLACKLIST[msg.sender] == false, "You are blacklisted");
        LOCKS[_lockID].owner = newOwner;
        UserInfo storage user = USERS[msg.sender];
        user.locksForToken.push(_lockID);
        emit onTransferLock(_lockID, msg.sender, newOwner);
    }
  

    function blacklist(address add_, bool dec_) external onlyOwner {
        BLACKLIST[add_] = dec_;
    }

    function getUserLocks(address user) public view returns(uint256[] memory){
        return(USERS[user].locksForToken);
    }
    function getUserRewardsLock(address user) public view returns(TokenLock[] memory){
        uint256[] memory locks = getUserLocks(user);
        TokenLock[] memory locks_tuple = new TokenLock[](locks.length);
        for(uint256 i=0;i<locks.length;i++){
            TokenLock memory lock_this = getLock(locks[i]);
            locks_tuple[i] = lock_this;
        }
        return locks_tuple;
    }

}

contract RETHStaking is TokenVesting  {
    
    using SafeMath for uint256;
     IERC20 public token;

   
    
    uint256 private constant ONE_MONTH_SEC = 2592000;
    uint256 private constant SIX_MONTHS_SEC = 6 * ONE_MONTH_SEC;
    Pool[] public pools; // Staking pools

    struct stakes{
        address owner;
        uint256 amount;
        uint256 startTime;
        uint256 endTime;
        uint256 months;
        bool collected;
        uint256 claimed;
        uint256 rewardLockId;
    }
    
    event StakingUpdate(
        address wallet,
        uint256 amount,
        uint256 startTime,
        uint256 endTime,
        bool collected,
        uint256 claimed
    );
    event APYSet(
        uint256[] APYs
    );

   struct Pool {
        uint256 tokensStaked; // Total tokens staked
        uint256 totalRewardsClaimed; // Last block number the user had their rewards calculated
        bool stakingPause;
      }
    bool public  PauseClaim = false;

    mapping(uint256=> mapping(address=>stakes[])) public Stakes;
    mapping (uint256 => mapping(address=> uint256)) public userstakes;
    mapping (uint256=> mapping(uint256=>uint256) )public APY;
   
    event PoolCreated(uint256 poolId);
    event StakingPause(bool pause);
    event ClaimPause(bool status);
    
    constructor(IERC20 _token) TokenVesting(_token) {
        token=_token;       
    }

    function stake(uint256 amount, uint256 months, uint256 poolId) public nonReentrant {
        require(months == 1 || months == 3 || months == 6 || months == 12,"ENTER VALID MONTH");
        _stake(amount, months,  poolId);
    }
 

    function _stake(uint256 amount, uint256 months, uint256 poolId) private {
        token.transferFrom(msg.sender, address(this), amount);
        userstakes[poolId][msg.sender]++;
        Pool storage pool = pools[poolId];
        require(pool.stakingPause==false,"STAKING PAUSE");
        pool.tokensStaked +=amount;
        uint256 duration = block.timestamp.add(months.mul(30 days));   
        Stakes[poolId][msg.sender].push(stakes(msg.sender, amount, block.timestamp, duration, months, false, 0,NONCE));
        uint256 rewards = getTotalRewardsForVesting(amount, months, poolId);
        LockParams memory params = LockParams(payable(msg.sender),rewards, duration, duration.add(SIX_MONTHS_SEC), poolId, userstakes[poolId][msg.sender].sub(1));
        lockVestingRewards(params);
        emit StakingUpdate(msg.sender, amount, block.timestamp, duration, false, 0);
    }

    function lockVestingRewards(LockParams memory param) internal {
        lockRewards(param);
    }

    function unStake(uint256 stakeId,uint256 poolId ) public nonReentrant{
        require(Stakes[poolId][msg.sender][stakeId].collected == false ,"ALREADY WITHDRAWN");
        require(Stakes[poolId][msg.sender][stakeId].endTime < block.timestamp,"STAKING TIME NOT ENDED");
        _unstake(stakeId,poolId);
    }

    function _unstake(uint256 stakeId,uint256 poolId) private {
        require(PauseClaim==false, "Claim Pause");
        Stakes[poolId][msg.sender][stakeId].collected = true;
        uint256 stakeamt = Stakes[poolId][msg.sender][stakeId].amount;
        Pool storage pool = pools[poolId];
        pool.tokensStaked -= stakeamt;
        token.transfer(msg.sender, stakeamt );
        emit StakingUpdate(msg.sender, stakeamt, Stakes[poolId][msg.sender][stakeId].startTime, Stakes[poolId][msg.sender][stakeId].endTime, true, stakeamt);
    }

    function withdrawReward(uint256 _lockID) external nonReentrant {
        TokenLock storage userLock = LOCKS[_lockID];
        require(userLock.owner == msg.sender, 'OWNER');
        require(BLACKLIST[msg.sender]==false, "You are Blacklisted");
        uint256 withdrawableTokens = getWithdrawableTokens(userLock.lockID).sub(userLock.tokensWithdrawn);
        uint256 _amount = withdrawableTokens;
        userLock.tokensWithdrawn += _amount;
        Pool storage pool = pools[userLock.poolId];
        require(PauseClaim==false, "Claim Pause");
        pool.totalRewardsClaimed -= _amount;
        Stakes[userLock.poolId][userLock.owner][userLock.stakeId].claimed += _amount;
        require(_amount <= userLock.tokensDeposited && userLock.tokensWithdrawn <= userLock.tokensDeposited);
        TransferHelper.safeTransfer(address(RETH), msg.sender, _amount);
        emit onWithdraw(_lockID, _amount);
  }


    function getStakes( address wallet,uint256 poolId) public view returns(stakes[] memory){
        uint256 itemCount = userstakes[poolId][wallet];
        uint256 currentIndex = 0;
        stakes[] memory items = new stakes[](itemCount);

        for (uint256 i = 0; i < userstakes[poolId][wallet]; i++) {
                stakes storage currentItem = Stakes[poolId][wallet][i];
                items[currentIndex] = currentItem;
                currentIndex += 1;
            }
        return items;
    }

    function getTotalRewards(address wallet, uint256 stakeId,uint256 poolId) public view returns(uint256) {
        require(Stakes[poolId][wallet][stakeId].amount != 0);
        uint256 stakeamt = Stakes[poolId][wallet][stakeId].amount;
        uint256 mos = Stakes[poolId][wallet][stakeId].months;
        uint256  rewards = (((stakeamt.mul(APY[poolId][mos])).mul(mos)).div(12)).div(100);
        return rewards;
    }

    function getWithdrawableRewards(address wallet, uint256 stakeId, uint256 poolId) public view returns(uint256){
        uint256 rewardLockId = Stakes[poolId][wallet][stakeId].rewardLockId;
        return getWithdrawableTokens(rewardLockId);
    }

    function getTotalRewardsForVesting(uint256 amount, uint256 months, uint256 poolId) public view returns(uint256) {
        require(amount != 0, "Zero Amount");
        uint256  rewards = (((amount.mul(APY[poolId][months])).mul(months)).div(12)).div(100);
        return rewards;
    }

    function rewardsClaimed(uint256 poolId ) public view returns(uint256){
        Pool storage pool = pools[poolId];
        return pool.totalRewardsClaimed;
    }

    function setAPYs(uint256[] memory apys, uint256 poolId) external onlyOwner {
       require(apys.length == 4,"4 INDEXED ARRAY ALLOWED");
        APY[poolId][1] = apys[0];
        APY[poolId][3] = apys[1];
        APY[poolId][6] = apys[2];
        APY[poolId][12] = apys[3];
        emit APYSet(apys);
    }

    function withdrawToken(IERC20 _token) external nonReentrant onlyOwner {
        _token.transfer(owner(), _token.balanceOf(address(this)));
    }

     
     function createPool() external onlyOwner {
        Pool memory pool;
        pool.totalRewardsClaimed =  0;
        pool.tokensStaked=0;
        pools.push(pool);
        uint256 poolId = pools.length - 1;
        emit PoolCreated(poolId);
    }
    function pauseStaking (bool _pause, uint256 poolId) external onlyOwner {
         Pool storage pool = pools[poolId];
         pool.stakingPause = _pause;
         emit StakingPause(_pause);
    }

    function pauseClaim(bool status) public onlyOwner {
        PauseClaim = status;
        emit ClaimPause(status);
    }
}