//SPDX-License-Identifier: GPL-2.0
// VxlMasterFarmer
pragma solidity 0.8.10;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";


contract VxlMasterFarmer is Ownable {
 

    // Info of each user.
    struct UserInfo {
        uint256 amount;     // How many LP tokens the user has provided.
        uint256 rewardDebt; // Reward debt. See explanation below.
        uint256 rewardDebtAtBlock; // the last block user stake
       
        //
        // We do some fancy math here. Basically, any point in time, the amount of VXLs
        // entitled to a user but is pending to be distributed is:
        //
        //  pending reward = (user.amount * pool.accVxlPerShare) - user.rewardDebt
        //
        // Whenever a user deposits or withdraws LP tokens to a pool. Here's what happens:
        //   1. The pool's `accVxlPerShare` (and `lastRewardBlock`) gets updated.
        //   2. User receives the pending reward sent to his/her address.
        //   3. User's `amount` gets updated.
        //   4. User's `rewardDebt` gets updated.
    }

    // Info of each pool.
    struct PoolInfo {
        uint256 poolId;
        IERC20 lpToken;           // Address of LP token contract.
        IERC20  rewardToken;
        uint256 rewardSupply;
        uint256 allocPoint;       // How many allocation points assigned to this pool. VXLs to distribute per block.
        uint256 lastRewardBlock;  // Last block number that VXLs distribution occurs.
        uint256 accVxlPerShare;   // Accumulated VXLs per share, times 1e12. See below.
        PoolMeta poolMeta;
        TokenMeta token1;
        TokenMeta token2;
        bool isPaused;
    }

    event PoolCreated(
        uint256 poolId,
        IERC20 lpToken,           // Address of LP token contract.
        IERC20  rewardToken,
        uint256 rewardSupply,
        uint256 allocPoint,       // How many allocation points assigned to this pool. VXLs to distribute per block.
        uint256 lastRewardBlock,  // Last block number that VXLs distribution occurs
        PoolMeta poolMeta,
        TokenMeta token1,
        TokenMeta token2,
        uint256 accVxlPerShare,
        bool isPaused
  );

    struct PoolMeta {
        string tokenSymbol;
        string tokenName;
        string logoUri;
        string protocol;
        string addLiquidityLink;
        string removeLiquidityLink;
        string description;
    }

    struct TokenMeta {
         address ercToken;
         string tokenSymbol;
         string tokenName;
         string logoUri;
    }
 
    // VXL tokens created per block.
    uint256 public REWARD_PER_BLOCK;
    // Bonus muliplier for early VXL makers.
    uint256[] public REWARD_MULTIPLIER = [128, 128, 64, 32, 16, 8, 4, 2, 1];
    uint256[] public HALVING_AT_BLOCK; // init in constructor function
    uint256 public FINISH_BONUS_AT_BLOCK;
    // The block number when VXL mining starts.
    uint256 public START_BLOCK;

    // Info of each pool.
    PoolInfo[] public poolInfo;
    mapping(address => uint256) public poolId1; // poolId1 count from 1, subtraction 1 before using with poolInfo
    // Info of each user that stakes LP tokens. pid => user address => info
    mapping (uint256 => mapping (address => UserInfo)) public userInfo;
    // Total allocation poitns. Must be the sum of all allocation points in all pools.
    uint256 public totalAllocPoint = 0;

    event Deposit(address indexed user, uint256 indexed pid, uint256 amount);
    event Withdraw(address indexed user, uint256 indexed pid, uint256 amount);
    event EmergencyWithdraw(address indexed user, uint256 indexed pid, uint256 amount);
    event SendVxlReward(address indexed user, uint256 indexed pid, uint256 amount, uint256 lockAmount);

    constructor(
        uint256 _rewardPerBlock,
        uint256 _startBlock,
        uint256 _halvingAfterBlock
    )  {
    
        REWARD_PER_BLOCK = _rewardPerBlock;
        START_BLOCK = _startBlock;
        for (uint256 i = 0; i < REWARD_MULTIPLIER.length - 1; i++) {
            uint256 halvingAtBlock = SafeMath.add(SafeMath.mul(_halvingAfterBlock,i + 1),_startBlock);
            HALVING_AT_BLOCK.push(halvingAtBlock);
        }
        FINISH_BONUS_AT_BLOCK = SafeMath.add(SafeMath.mul(_halvingAfterBlock,REWARD_MULTIPLIER.length - 1),_startBlock);
        
        HALVING_AT_BLOCK.push(uint256(0));
    }

    function poolLength() external view returns (uint256) {
        return poolInfo.length;
    }


    function getAllPools() public view returns (PoolInfo[] memory) {
        
            return poolInfo;
    }

    /***
    * @dev Pauses or unpauses.
    * @param _poolId Whether should pause or unpause.
    */
    function pausePool(uint256 _poolId) external onlyOwner {

            poolInfo[_poolId].isPaused= poolInfo[_poolId].isPaused ? false : true;
    
    }


   /***
   * @dev Updates rewards.
   * @param _rewardSupply Rewards Supply in integer.
   */
  function updateRewardSupply(uint256 _poolId,uint256 _rewardSupply) external onlyOwner {

   require(IERC20(poolInfo[_poolId].rewardToken).transferFrom(msg.sender, address(this), _rewardSupply), "Reward Supply Transfer failed");
   poolInfo[_poolId].rewardSupply=poolInfo[_poolId].rewardSupply+_rewardSupply;
   poolInfo[_poolId].isPaused=false;

  }

    // Add a new lp to the pool. Can only be called by the owner.
    function add(uint256 _allocPoint, IERC20 _lpToken, IERC20 _rewardToken,uint256 _rewardSupply, PoolMeta memory _poolMeta, TokenMeta memory _token1, TokenMeta memory _token2, bool _withUpdate) public onlyOwner {
        require(poolId1[address(_lpToken)] == 0, "VxlMasterFarmer::add: lp is already in pool");
        require(IERC20(_rewardToken).transferFrom(msg.sender, address(this), _rewardSupply), "Reward Supply Transfer failed");
        if (_withUpdate) {
            massUpdatePools();
        }
         
        uint256 lastRewardBlock = block.number > START_BLOCK ? block.number : START_BLOCK;
        totalAllocPoint = SafeMath.add(totalAllocPoint,_allocPoint);
        poolId1[address(_lpToken)] = poolInfo.length + 1;
        poolInfo.push(PoolInfo({
            poolId:poolInfo.length,
            lpToken: _lpToken,
            allocPoint: _allocPoint,
            lastRewardBlock: lastRewardBlock,
            rewardToken:_rewardToken,
            rewardSupply:_rewardSupply,
            poolMeta:_poolMeta,
            token1:_token1,
            token2:_token2,
            accVxlPerShare: 0,
            isPaused:false
        }));

        emit PoolCreated(
        poolInfo.length,
        _lpToken,
        _rewardToken,
        _rewardSupply,
        _allocPoint,
        lastRewardBlock,
        _poolMeta,
        _token1,
        _token2,
            0,
        false);
  
    }

    // Update the given pool's VXL allocation point. Can only be called by the owner.
    function set(uint256 _pid, uint256 _allocPoint, bool _withUpdate) public onlyOwner {
        if (_withUpdate) {
            massUpdatePools();
        }
        totalAllocPoint = SafeMath.add(_allocPoint,SafeMath.sub(totalAllocPoint,poolInfo[_pid].allocPoint));
        poolInfo[_pid].allocPoint = _allocPoint;
    }



    // Update reward variables for all pools. Be careful of gas spending!
    function massUpdatePools() public {
        uint256 length = poolInfo.length;
        for (uint256 pid = 0; pid < length; ++pid) {
            updatePool(pid);
        }
    }

    // Update reward variables of the given pool to be up-to-date.
    function updatePool(uint256 _pid) public {
        PoolInfo storage pool = poolInfo[_pid];
        if (block.number <= pool.lastRewardBlock) {
            return;
        }
        uint256 lpSupply = pool.lpToken.balanceOf(address(this));
        if (lpSupply == 0) {
            pool.lastRewardBlock = block.number;
            return;
        }

        uint256 vxlForFarmer;
        (vxlForFarmer) = getPoolReward(pool.lastRewardBlock, block.number, pool.allocPoint);
        
        pool.accVxlPerShare = SafeMath.add(pool.accVxlPerShare,SafeMath.div(SafeMath.mul(vxlForFarmer,1e12),lpSupply));
        
        pool.lastRewardBlock = block.number;
    }

    // |--------------------------------------|
    // [20, 30, 40, 50, 60, 70, 80, 99999999]
    // Return reward multiplier over the given _from to _to block.
    function getMultiplier(uint256 _from, uint256 _to) public view returns (uint256) {
        uint256 result = 0;
        if (_from < START_BLOCK) return 0;

        for (uint256 i = 0; i < HALVING_AT_BLOCK.length; i++) {
            uint256 endBlock = HALVING_AT_BLOCK[i];

            if (_to <= endBlock) {
                uint256 m = SafeMath.mul(SafeMath.sub(_to,_from),REWARD_MULTIPLIER[i]);
                
               
                return SafeMath.add(result,m);
            }

            if (_from < endBlock) {
                uint256 m = SafeMath.mul(SafeMath.sub(endBlock,_from),REWARD_MULTIPLIER[i]);
              
                _from = endBlock;
                result = SafeMath.add(result,m);
            }
        }

        return result;
    }

    function getPoolReward(uint256 _from, uint256 _to, uint256 _allocPoint) public view returns (uint256 forFarmer) {
        uint256 multiplier = getMultiplier(_from, _to);
        uint256 amount = SafeMath.div(SafeMath.mul(SafeMath.mul(multiplier,REWARD_PER_BLOCK),_allocPoint),totalAllocPoint);

        forFarmer = amount;
    }

    // View function to see pending VXLs on frontend.
    function pendingReward(uint256 _pid, address _user) external view returns (uint256) {
        PoolInfo storage pool = poolInfo[_pid];
        UserInfo storage user = userInfo[_pid][_user];
        uint256 accVxlPerShare = pool.accVxlPerShare;
        uint256 lpSupply = pool.lpToken.balanceOf(address(this));
        if (block.number > pool.lastRewardBlock && lpSupply > 0) {
            uint256 vxlForFarmer;
            (vxlForFarmer) = getPoolReward(pool.lastRewardBlock, block.number, pool.allocPoint);
            accVxlPerShare = SafeMath.add(accVxlPerShare,SafeMath.div(SafeMath.mul(vxlForFarmer,1e12),lpSupply));
            
           

        }
        return SafeMath.sub(SafeMath.div(SafeMath.mul(user.amount,accVxlPerShare),1e12),user.rewardDebt);
  
    }

    function claimReward(uint256 _pid) public {
        updatePool(_pid);
        _harvest(_pid);
    }

    // harvest reward if it come from bonus time
    function _harvest(uint256 _pid) internal {
        
        PoolInfo storage pool = poolInfo[_pid];
        UserInfo storage user = userInfo[_pid][msg.sender];

        if (user.amount > 0) {
            uint256 pending   = SafeMath.sub(SafeMath.div(SafeMath.mul(user.amount,pool.accVxlPerShare),1e12),user.rewardDebt);
        
            uint256 masterBal = IERC20(pool.rewardToken).balanceOf(address(this));

            if (pending > masterBal) {
                pending = masterBal;
            }
            
            if(pending > 0) {
                
                // transfer pending rewards
                IERC20(pool.rewardToken).transfer(msg.sender, pending);

                poolInfo[_pid].rewardSupply=poolInfo[_pid].rewardSupply-pending;

                if(poolInfo[_pid].rewardSupply<1000000000000000000)
                 poolInfo[_pid].isPaused=true;

                user.rewardDebtAtBlock = block.number;
                emit SendVxlReward(msg.sender, _pid, pending, 0);
            }

            user.rewardDebt = SafeMath.div(SafeMath.mul(user.amount,pool.accVxlPerShare),1e12);
            
        }
    }

    // Deposit LP tokens to VxlMasterFarmer for Rewards allocation.
    function deposit(uint256 _pid, uint256 _amount) public {

        require(poolInfo[_pid].isPaused == false, "Pool is Paused");
        require(_amount > 0, "VxlMasterFarmer::deposit: amount must be greater than 0");

        PoolInfo storage pool = poolInfo[_pid];
        UserInfo storage user = userInfo[_pid][msg.sender];
        updatePool(_pid);
        _harvest(_pid);
    
        IERC20(pool.lpToken).transferFrom(address(msg.sender), address(this), _amount);

        if (user.amount == 0) {
            user.rewardDebtAtBlock = block.number;
        }
        user.amount =  SafeMath.add(user.amount,_amount);
        user.rewardDebt = SafeMath.div(SafeMath.mul(user.amount,pool.accVxlPerShare),1e12);
       
        emit Deposit(msg.sender, _pid, _amount);
    }

    // Withdraw LP tokens from VxlMasterFarmer.
    function withdraw(uint256 _pid, uint256 _amount) public {
        require(poolInfo[_pid].isPaused == false, "Pool is Paused");
        PoolInfo storage pool = poolInfo[_pid];
        UserInfo storage user = userInfo[_pid][msg.sender];
        require(user.amount >= _amount, "VxlMasterFarmer::withdraw: not good");

        updatePool(_pid);
        _harvest(_pid);
        
        if(_amount > 0) {
            user.amount = SafeMath.sub(user.amount,_amount);
        IERC20(pool.lpToken).transfer(address(msg.sender), _amount);
        }
        user.rewardDebt = SafeMath.div(SafeMath.mul(user.amount,pool.accVxlPerShare),1e12);

        emit Withdraw(msg.sender, _pid, _amount);
    }

    // Withdraw without caring about rewards. EMERGENCY ONLY.
    function emergencyWithdraw(uint256 _pid) public {
        PoolInfo storage pool = poolInfo[_pid];
        UserInfo storage user = userInfo[_pid][msg.sender];
   
        IERC20(pool.lpToken).transfer(address(msg.sender), user.amount);

        emit EmergencyWithdraw(msg.sender, _pid, user.amount);
        user.amount = 0;
        user.rewardDebt = 0;
    }

    function getNewRewardPerBlock(uint256 pid1) public view returns (uint256) {
        uint256 multiplier = getMultiplier(block.number -1, block.number);
        if (pid1 == 0) {
            return SafeMath.mul(multiplier,REWARD_PER_BLOCK);
        }
        else {
            return SafeMath.div(SafeMath.mul(SafeMath.mul(multiplier,REWARD_PER_BLOCK),poolInfo[pid1 - 1].allocPoint),totalAllocPoint);
          
        }
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.6.0) (utils/math/SafeMath.sol)

pragma solidity ^0.8.0;

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