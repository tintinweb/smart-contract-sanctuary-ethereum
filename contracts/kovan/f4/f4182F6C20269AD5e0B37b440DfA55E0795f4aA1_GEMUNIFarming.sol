// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "./utils/PermissionGroupUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/security/ReentrancyGuardUpgradeable.sol";
import "@openzeppelin/contracts/token/ERC20/extensions/IERC20Metadata.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import "./interfaces/IGEMUNIFarming.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "./interfaces/IGEMUNIVesting.sol";

contract GEMUNIFarming is PermissionGroupUpgradeable, ReentrancyGuardUpgradeable, IGEMUNIFarming {
    using SafeMath for uint256;
    using SafeERC20 for IERC20;

    PoolInfoToken[] public poolInfoTokens;
    mapping(uint256 => mapping(address => UserInfo)) public userInfo;

    address public vestingContract;

    function _initialize () external initializer {
        __ReentrancyGuard_init();
        __operatable_init();
    }

    function setVestingContract(address _vestingContract) public onlyOwner {
        require(_vestingContract != address(0), "Farm: invalid address");
        vestingContract = _vestingContract;
    }

    modifier notEnded(uint256 _pid) {
        PoolInfoToken storage pool = poolInfoTokens[_pid];
        uint256 endTime = pool.timePoolInfo.endTime;
        require(block.timestamp <= endTime, "Farm: Pool ended");
        _;
    }
    
    modifier validPool(uint pid) {
        uint maxLengthPool = poolInfoTokens.length - 1;
        require(pid <= maxLengthPool, "Farm: invalid pid");
        _;
    }

    modifier activePool(uint pid) {
        PoolInfoToken memory pool = poolInfoTokens[pid];
        require(pool.isActive, "Farm: deactive pool");
        _;
    }

    function poolLength() external view override returns (uint256) {
        return poolInfoTokens.length;
    }

    function setIsEarlyClaimAllowed(uint pid, bool _isEarlyClaimAllowed) external validPool(pid) activePool(pid) onlyOwner {
        PoolInfoToken storage pool = poolInfoTokens[pid];
        pool.isEarlyClaimAllowed = _isEarlyClaimAllowed;
        emit SetIsEarlyClaimAllowed(pid, _isEarlyClaimAllowed);
    }

    // Add a new pool. Can only be called by the owner.
    function addPoolToken(
        address stakedToken,
        address rewardToken,
        uint256 stakingPeriod,
        uint256 rewardBalance,
        uint256 startTime,
        uint256 endTime,
        bool isEarlyClaimAllowed,
        bool _withUpdate
    ) external override onlyOperator {
        {
            bool foundToken = false;
            for (uint256 i = 0; i < poolInfoTokens.length; i++) {
                PoolInfoToken memory pool = poolInfoTokens[i];
                if (address(pool.stakedToken) == stakedToken &&
                    address(pool.rewardToken) == rewardToken && 
                    pool.timePoolInfo.stakingPeriod == stakingPeriod && 
                    block.timestamp < pool.timePoolInfo.endTime &&
                    pool.isActive
                    ) {
                    foundToken = true;
                    break;
                }
            }
            require(!foundToken, "Farm: Token exists");
        }

        require(stakedToken != address(0), "Farm: Token is address(0)");
        require(rewardToken != address(0), "Farm: Token is address(0)");
        require(startTime < endTime, "Farm: Require startTime < endTime");
        if (_withUpdate) {
            massUpdatePools();
        }
        uint256 lastRewardTime = block.timestamp > startTime
            ? block.timestamp
            : startTime;
        uint256 rewardPerSecond = rewardBalance.div(endTime.sub(startTime));

        IERC20(rewardToken).safeTransferFrom(msg.sender, address(this), rewardBalance);
        uint256 decimalsRewardToken = uint256(IERC20Metadata(rewardToken).decimals());
        poolInfoTokens.push(
            PoolInfoToken({
                stakedToken: IERC20(stakedToken),
                rewardToken: IERC20(rewardToken),
                timePoolInfo: TimePoolInfo({
                    startTime: startTime == 0 ? block.timestamp : startTime,
                    endTime: endTime,
                    stakingPeriod: stakingPeriod,
                    lastRewardTime: lastRewardTime
                }),
                rewardPerSecond: rewardPerSecond,
                PRECISION_FACTOR: 10 ** (30 - decimalsRewardToken),
                accTokenShare: 0,
                rewardBalance: rewardBalance,
                totalStaked: 0,
                isEarlyClaimAllowed: isEarlyClaimAllowed,
                claimedRewards: 0,
                isActive: true
            })
        );
        uint256 pid = poolInfoTokens.length - 1;
        emit CreatedPoolToken(pid, stakedToken, rewardToken, stakingPeriod, isEarlyClaimAllowed, rewardBalance);
    }

    function lockPoolToken(uint pid) external override onlyOperator validPool(pid) activePool(pid) {
        PoolInfoToken storage pool = poolInfoTokens[pid];
        require(pool.isActive, "Farm: already locked");
        
        pool.isActive = false;

        emit LockPoolToken(pid);
    }


    function getMultiplier(uint256 _from, uint256 _to, uint256 _pid)
        public
        view
        returns (uint256)
    {
        if (_from >= _to) return 0;
        uint256 start = _from;
        uint256 end = _to;
        
        PoolInfoToken memory pool = poolInfoTokens[_pid];
        uint256 startTime = pool.timePoolInfo.startTime;
        uint256 endTime = pool.timePoolInfo.endTime;
        if (start > endTime) return 0;
        if (end < startTime ) return 0;
        
        if (start < startTime) start = startTime;
        if (end > endTime) end = endTime;
        return end - start;
    }

    // View function to see pending reward on frontend.
    function pendingReward(uint256 _pid, address _user)
        external
        view
        validPool(_pid)
        returns (uint256)
    {
        PoolInfoToken memory pool = poolInfoTokens[_pid];
        UserInfo memory user = userInfo[_pid][_user];
        uint256 accTokenShare = pool.accTokenShare;
        uint256 totalStaked = pool.totalStaked;
        uint256 lastRewardTime = pool.timePoolInfo.lastRewardTime;
        if (block.timestamp > lastRewardTime && totalStaked != 0) {
            uint256 multiplier = getMultiplier(
                lastRewardTime,
                block.timestamp,
                _pid
            );
            uint256 reward = multiplier.mul(pool.rewardPerSecond);
            accTokenShare = accTokenShare.add(
                reward.mul(pool.PRECISION_FACTOR).div(totalStaked)
            );
        }
        return user.amount.mul(accTokenShare).div(pool.PRECISION_FACTOR).sub(user.reward).add(user.currentRewardStored);
    }

    // Update reward vairables for all pools. Be careful of gas spending!
    function massUpdatePools() public {
        uint256 length = poolInfoTokens.length;
        for (uint256 pid = 0; pid < length; ++pid) {
            PoolInfoToken memory pool = poolInfoTokens[pid];
            if(pool.isActive){
                updatePool(pid);
            }
        }
    }

    function updatePool(uint256 _pid) validPool(_pid) public {
        PoolInfoToken storage pool = poolInfoTokens[_pid];
        uint256 lastRewardTime = pool.timePoolInfo.lastRewardTime;
        if (block.timestamp <= lastRewardTime) {
            return;
        }
        uint256 totalStaked = pool.totalStaked;
        if (totalStaked == 0) {
            pool.timePoolInfo.lastRewardTime = block.timestamp;
            return;
        }
        uint256 multiplier = getMultiplier(lastRewardTime, block.timestamp, _pid);
        uint256 reward = multiplier.mul(pool.rewardPerSecond);

        pool.accTokenShare = pool.accTokenShare.add(
            reward.mul(pool.PRECISION_FACTOR).div(totalStaked)
        );
        pool.timePoolInfo.lastRewardTime = block.timestamp;
    }

    function increaseReward(uint256 _pid, uint256 _amount) external override notEnded(_pid) activePool(_pid) validPool(_pid) {
        updatePool(_pid);
        PoolInfoToken storage pool = poolInfoTokens[_pid];
        pool.rewardToken.safeTransferFrom(msg.sender, address(this), _amount);

        uint256 startTime = pool.timePoolInfo.lastRewardTime;
        uint256 endTime = pool.timePoolInfo.endTime;
        
        pool.rewardBalance = pool.rewardBalance.add(_amount);
        pool.rewardPerSecond = pool.rewardPerSecond.add(
            _amount.div(endTime.sub(startTime))
        );
        emit IncreaseReward(_pid, _amount);
    }

    function depositToken(uint256 _pid, uint256 _amount) external override notEnded(_pid) validPool(_pid) activePool(_pid) {
        PoolInfoToken storage pool = poolInfoTokens[_pid];
        UserInfo storage user = userInfo[_pid][msg.sender];
        require(block.timestamp >= pool.timePoolInfo.startTime && block.timestamp <= pool.timePoolInfo.endTime, "Farm: not start yet or already finished");
        require(_amount > 0, "Farm: invalid amount");
        
        updatePool(_pid);
        if (user.amount > 0) {
            uint256 pending = user
                .amount
                .mul(pool.accTokenShare)
                .div(pool.PRECISION_FACTOR)
                .sub(user.reward);
            user.currentRewardStored = user.currentRewardStored.add(pending);
        }
        pool.stakedToken.safeTransferFrom(
            address(msg.sender),
            address(this),
            _amount
        );
        pool.totalStaked = pool.totalStaked.add(_amount);
        user.amount = user.amount.add(_amount);
        user.reward = user.amount.mul(pool.accTokenShare).div(pool.PRECISION_FACTOR);
        user.stakeTime = block.timestamp;
        emit Deposit(_pid, msg.sender, _amount);
    }

    function withdrawToken(uint256 _pid, uint256 _amount) external override validPool(_pid) {
        PoolInfoToken storage pool = poolInfoTokens[_pid];
        UserInfo storage user = userInfo[_pid][msg.sender];
        require(_amount > 0 && user.amount >= _amount, "Farm: not good");
        uint256 startTime = pool.timePoolInfo.startTime;
        uint256 stakeTime = user.stakeTime < startTime ? startTime : user.stakeTime;
        require(stakeTime + pool.timePoolInfo.stakingPeriod <= block.timestamp, "Farm: token is locked");
        updatePool(_pid);
        uint256 pending = user.amount.mul(pool.accTokenShare).div(pool.PRECISION_FACTOR).sub(
            user.reward
        );
        user.currentRewardStored = user.currentRewardStored.add(pending);
        user.amount = user.amount.sub(_amount);
        user.reward = user.amount.mul(pool.accTokenShare).div(pool.PRECISION_FACTOR);
        pool.totalStaked = pool.totalStaked.sub(_amount);
        if(user.currentRewardStored > 0) {
            claimReward(_pid);
        }

        pool.stakedToken.safeTransfer(msg.sender, _amount);
        
        emit Withdraw(_pid, msg.sender, _amount);
    }

    function claimReward(uint256 _pid) internal {
        PoolInfoToken storage pool = poolInfoTokens[_pid];
        UserInfo storage user = userInfo[_pid][msg.sender];
        updatePool(_pid);
        uint256 pending = user.amount.mul(pool.accTokenShare).div(pool.PRECISION_FACTOR).sub(user.reward);
        user.reward = user.amount.mul(pool.accTokenShare).div(pool.PRECISION_FACTOR);
        uint256 currentReward = user.currentRewardStored.add(pending);
        user.currentRewardStored = 0;

        if(pool.rewardToken.allowance(address(this), vestingContract) < currentReward) {
            pool.rewardToken.approve(vestingContract, type(uint).max);
        }
        IGEMUNIVesting(vestingContract).lock(address(this), _pid, address(pool.rewardToken), msg.sender, currentReward);

        user.rewardClaimed = user.rewardClaimed.add(currentReward);
        pool.claimedRewards = pool.claimedRewards.add(currentReward);
        emit ClaimRewards(_pid, msg.sender, currentReward);
    }


    function getUserInfo(uint256 _pid, address _user)
        external
        view
        validPool(_pid)
        returns (
            uint256 amount, // How many tokens the user has provided.
            uint256 reward, // Reward debt. See explanation below.
            uint256 currentRewardStored
        )
    {
        UserInfo storage user = userInfo[_pid][_user];
        return (
            user.amount,
            user.reward,
            user.currentRewardStored
        );
    }

    // Batch reward withdraw by owner
    // May be affect the user's reward
    function emergencyRewardWithdraw(uint256 _pid, uint256 _amount, address _admin) external override validPool(_pid) onlyOwner {
        PoolInfoToken storage pool = poolInfoTokens[_pid];
        uint currentBalance = pool.rewardBalance - pool.claimedRewards;
        require(_amount > 0 && _amount <= currentBalance, "Farm: invalid amount");
        require(_admin != address(0), "Farm: invalid address");
        uint256 startTime = pool.timePoolInfo.startTime;
        uint256 endTime = pool.timePoolInfo.endTime;
        
        pool.rewardBalance = pool.rewardBalance.sub(_amount);
        pool.rewardPerSecond = pool.rewardBalance.div(endTime.sub(startTime));

        pool.rewardToken.safeTransfer(_admin, _amount);

        emit EmergencyRewardWithdraw(_pid, msg.sender, _amount);
    }

    // Withdraw without caring about rewards.
    function emergencyWithdraw(uint256 pid) external override validPool(pid) {
        PoolInfoToken storage pool = poolInfoTokens[pid];
        UserInfo memory user = userInfo[pid][msg.sender];
        require(user.amount > 0, "Farm: not found info");
        updatePool(pid);
        pool.stakedToken.safeTransfer(address(msg.sender), user.amount);
        pool.totalStaked = pool.totalStaked.sub(user.amount);

        emit EmergencyWithdraw(pid, msg.sender, user.amount);
        delete userInfo[pid][msg.sender];
    }


}

//SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";

abstract contract PermissionGroupUpgradeable is OwnableUpgradeable {

    mapping(address => bool) public operators;
    event AddOperator(address newOperator);
    event RemoveOperator(address operator);

    function __operatable_init() internal initializer {
        __Ownable_init();
        operators[owner()] = true;
    }

    modifier onlyOperator {
        require(operators[msg.sender], "Operatable: caller is not the operator");
        _;
    }

    function addOperator(address operator) external onlyOwner {
        operators[operator] = true;
        emit AddOperator(operator);
    }

    function removeOperator(address operator) external onlyOwner {
        operators[operator] = false;
        emit RemoveOperator(operator);
    }
}

pragma solidity ^0.8.0;

interface IGEMUNIVesting {
    function unlock(address locker, uint pid) external;

    function lock(
        address locker,
        uint pid,
        address _token,
        address _addr,
        uint256 _amount
    ) external;
}

pragma solidity ^0.8.0;
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721.sol";

interface IGEMUNIFarming {
    struct TimePoolInfo {
        uint startTime; // The block time when pool start.
        uint endTime;   // The block time when pool end.
        uint lastRewardTime;    // The block time of the last pool update
        uint stakingPeriod; // The interval time after deposit that user can withdraw token
    }

    struct UserInfo {
        uint amount; // How many staked tokens the user has provided
        uint stakeTime; // Time when user deposited.
        uint reward; // Reward debt
        uint rewardClaimed; // Reward claimed
        uint currentRewardStored;
    }

    struct PoolInfoToken {
        IERC20 stakedToken; // The staked token
        IERC20 rewardToken; // The reward token
        TimePoolInfo timePoolInfo;
        uint rewardPerSecond;
        uint PRECISION_FACTOR; // The precision factor
        uint accTokenShare;
        uint rewardBalance;
        uint totalStaked;
        uint claimedRewards; // The claimed rewards
        bool isEarlyClaimAllowed;
        bool isActive;
    }

    //******EVENTS********//
    event CreatedPoolToken(
        uint256 indexed pid,
        address stakedToken,
        address rewardToken,
        uint256 stakePeriod,
        bool isEarlyClaimAllowed,
        uint256 rewardSupply
    );
    event LockPoolToken(uint256 indexed pid);
    event EmergencyRewardWithdraw(uint256 indexed pid, address indexed user, uint256 amount);
    event IncreaseReward(uint256 pid, uint256 _amount);
    event Deposit(uint256 pid, address indexed user, uint256 amount);
    event Withdraw(uint256 indexed pid, address indexed user, uint256 amount);

    event EmergencyWithdraw(uint256 indexed pid, address indexed user, uint256 amount);

    event ClaimRewards(uint256 pid, address indexed user, uint256 amount);

    event SetStartTime(uint256 indexed pid, uint256 startTime);
    event SetStakingPeriod(uint256 indexed pid, uint256 times);
    event SetIsEarlyClaimAllowed(uint256 pid, bool _isEarlyClaimAllowed);

    function addPoolToken(
        address stakedToken,
        address rewardToken,
        uint256 stakingPeriod,
        uint256 rewardBalance,
        uint256 startTime,
        uint256 endTime,
        bool isEarlyClaimAllowed,
        bool _withUpdate
    ) external;

    function lockPoolToken(uint pid) external;

    function poolLength() external view returns (uint256);

    function emergencyRewardWithdraw(uint256 pid, uint256 _amount, address user) external;

    function increaseReward(uint256 pid, uint256 _amount) external;

    function depositToken(uint256 pid, uint256 _amount) external;

    function withdrawToken(uint256 pid, uint256 _amount) external;

    function emergencyWithdraw(uint256 pid) external;

}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

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

pragma solidity ^0.8.0;

/**
 * @dev Interface of the ERC165 standard, as defined in the
 * https://eips.ethereum.org/EIPS/eip-165[EIP].
 *
 * Implementers can declare support of contract interfaces, which can then be
 * queried by others ({ERC165Checker}).
 *
 * For an implementation, see {ERC165}.
 */
interface IERC165 {
    /**
     * @dev Returns true if this contract implements the interface defined by
     * `interfaceId`. See the corresponding
     * https://eips.ethereum.org/EIPS/eip-165#how-interfaces-are-identified[EIP section]
     * to learn more about how these ids are created.
     *
     * This function call must use less than 30 000 gas.
     */
    function supportsInterface(bytes4 interfaceId) external view returns (bool);
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/**
 * @dev Collection of functions related to the address type
 */
library Address {
    /**
     * @dev Returns true if `account` is a contract.
     *
     * [IMPORTANT]
     * ====
     * It is unsafe to assume that an address for which this function returns
     * false is an externally-owned account (EOA) and not a contract.
     *
     * Among others, `isContract` will return false for the following
     * types of addresses:
     *
     *  - an externally-owned account
     *  - a contract in construction
     *  - an address where a contract will be created
     *  - an address where a contract lived, but was destroyed
     * ====
     */
    function isContract(address account) internal view returns (bool) {
        // This method relies on extcodesize, which returns 0 for contracts in
        // construction, since the code is only stored at the end of the
        // constructor execution.

        uint256 size;
        assembly {
            size := extcodesize(account)
        }
        return size > 0;
    }

    /**
     * @dev Replacement for Solidity's `transfer`: sends `amount` wei to
     * `recipient`, forwarding all available gas and reverting on errors.
     *
     * https://eips.ethereum.org/EIPS/eip-1884[EIP1884] increases the gas cost
     * of certain opcodes, possibly making contracts go over the 2300 gas limit
     * imposed by `transfer`, making them unable to receive funds via
     * `transfer`. {sendValue} removes this limitation.
     *
     * https://diligence.consensys.net/posts/2019/09/stop-using-soliditys-transfer-now/[Learn more].
     *
     * IMPORTANT: because control is transferred to `recipient`, care must be
     * taken to not create reentrancy vulnerabilities. Consider using
     * {ReentrancyGuard} or the
     * https://solidity.readthedocs.io/en/v0.5.11/security-considerations.html#use-the-checks-effects-interactions-pattern[checks-effects-interactions pattern].
     */
    function sendValue(address payable recipient, uint256 amount) internal {
        require(address(this).balance >= amount, "Address: insufficient balance");

        (bool success, ) = recipient.call{value: amount}("");
        require(success, "Address: unable to send value, recipient may have reverted");
    }

    /**
     * @dev Performs a Solidity function call using a low level `call`. A
     * plain `call` is an unsafe replacement for a function call: use this
     * function instead.
     *
     * If `target` reverts with a revert reason, it is bubbled up by this
     * function (like regular Solidity function calls).
     *
     * Returns the raw returned data. To convert to the expected return value,
     * use https://solidity.readthedocs.io/en/latest/units-and-global-variables.html?highlight=abi.decode#abi-encoding-and-decoding-functions[`abi.decode`].
     *
     * Requirements:
     *
     * - `target` must be a contract.
     * - calling `target` with `data` must not revert.
     *
     * _Available since v3.1._
     */
    function functionCall(address target, bytes memory data) internal returns (bytes memory) {
        return functionCall(target, data, "Address: low-level call failed");
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`], but with
     * `errorMessage` as a fallback revert reason when `target` reverts.
     *
     * _Available since v3.1._
     */
    function functionCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal returns (bytes memory) {
        return functionCallWithValue(target, data, 0, errorMessage);
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
     * but also transferring `value` wei to `target`.
     *
     * Requirements:
     *
     * - the calling contract must have an ETH balance of at least `value`.
     * - the called Solidity function must be `payable`.
     *
     * _Available since v3.1._
     */
    function functionCallWithValue(
        address target,
        bytes memory data,
        uint256 value
    ) internal returns (bytes memory) {
        return functionCallWithValue(target, data, value, "Address: low-level call with value failed");
    }

    /**
     * @dev Same as {xref-Address-functionCallWithValue-address-bytes-uint256-}[`functionCallWithValue`], but
     * with `errorMessage` as a fallback revert reason when `target` reverts.
     *
     * _Available since v3.1._
     */
    function functionCallWithValue(
        address target,
        bytes memory data,
        uint256 value,
        string memory errorMessage
    ) internal returns (bytes memory) {
        require(address(this).balance >= value, "Address: insufficient balance for call");
        require(isContract(target), "Address: call to non-contract");

        (bool success, bytes memory returndata) = target.call{value: value}(data);
        return verifyCallResult(success, returndata, errorMessage);
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
     * but performing a static call.
     *
     * _Available since v3.3._
     */
    function functionStaticCall(address target, bytes memory data) internal view returns (bytes memory) {
        return functionStaticCall(target, data, "Address: low-level static call failed");
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-string-}[`functionCall`],
     * but performing a static call.
     *
     * _Available since v3.3._
     */
    function functionStaticCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal view returns (bytes memory) {
        require(isContract(target), "Address: static call to non-contract");

        (bool success, bytes memory returndata) = target.staticcall(data);
        return verifyCallResult(success, returndata, errorMessage);
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
     * but performing a delegate call.
     *
     * _Available since v3.4._
     */
    function functionDelegateCall(address target, bytes memory data) internal returns (bytes memory) {
        return functionDelegateCall(target, data, "Address: low-level delegate call failed");
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-string-}[`functionCall`],
     * but performing a delegate call.
     *
     * _Available since v3.4._
     */
    function functionDelegateCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal returns (bytes memory) {
        require(isContract(target), "Address: delegate call to non-contract");

        (bool success, bytes memory returndata) = target.delegatecall(data);
        return verifyCallResult(success, returndata, errorMessage);
    }

    /**
     * @dev Tool to verifies that a low level call was successful, and revert if it wasn't, either by bubbling the
     * revert reason using the provided one.
     *
     * _Available since v4.3._
     */
    function verifyCallResult(
        bool success,
        bytes memory returndata,
        string memory errorMessage
    ) internal pure returns (bytes memory) {
        if (success) {
            return returndata;
        } else {
            // Look for revert reason and bubble it up if present
            if (returndata.length > 0) {
                // The easiest way to bubble the revert reason is using memory via assembly

                assembly {
                    let returndata_size := mload(returndata)
                    revert(add(32, returndata), returndata_size)
                }
            } else {
                revert(errorMessage);
            }
        }
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "../../utils/introspection/IERC165.sol";

/**
 * @dev Required interface of an ERC721 compliant contract.
 */
interface IERC721 is IERC165 {
    /**
     * @dev Emitted when `tokenId` token is transferred from `from` to `to`.
     */
    event Transfer(address indexed from, address indexed to, uint256 indexed tokenId);

    /**
     * @dev Emitted when `owner` enables `approved` to manage the `tokenId` token.
     */
    event Approval(address indexed owner, address indexed approved, uint256 indexed tokenId);

    /**
     * @dev Emitted when `owner` enables or disables (`approved`) `operator` to manage all of its assets.
     */
    event ApprovalForAll(address indexed owner, address indexed operator, bool approved);

    /**
     * @dev Returns the number of tokens in ``owner``'s account.
     */
    function balanceOf(address owner) external view returns (uint256 balance);

    /**
     * @dev Returns the owner of the `tokenId` token.
     *
     * Requirements:
     *
     * - `tokenId` must exist.
     */
    function ownerOf(uint256 tokenId) external view returns (address owner);

    /**
     * @dev Safely transfers `tokenId` token from `from` to `to`, checking first that contract recipients
     * are aware of the ERC721 protocol to prevent tokens from being forever locked.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `tokenId` token must exist and be owned by `from`.
     * - If the caller is not `from`, it must be have been allowed to move this token by either {approve} or {setApprovalForAll}.
     * - If `to` refers to a smart contract, it must implement {IERC721Receiver-onERC721Received}, which is called upon a safe transfer.
     *
     * Emits a {Transfer} event.
     */
    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId
    ) external;

    /**
     * @dev Transfers `tokenId` token from `from` to `to`.
     *
     * WARNING: Usage of this method is discouraged, use {safeTransferFrom} whenever possible.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `tokenId` token must be owned by `from`.
     * - If the caller is not `from`, it must be approved to move this token by either {approve} or {setApprovalForAll}.
     *
     * Emits a {Transfer} event.
     */
    function transferFrom(
        address from,
        address to,
        uint256 tokenId
    ) external;

    /**
     * @dev Gives permission to `to` to transfer `tokenId` token to another account.
     * The approval is cleared when the token is transferred.
     *
     * Only a single account can be approved at a time, so approving the zero address clears previous approvals.
     *
     * Requirements:
     *
     * - The caller must own the token or be an approved operator.
     * - `tokenId` must exist.
     *
     * Emits an {Approval} event.
     */
    function approve(address to, uint256 tokenId) external;

    /**
     * @dev Returns the account approved for `tokenId` token.
     *
     * Requirements:
     *
     * - `tokenId` must exist.
     */
    function getApproved(uint256 tokenId) external view returns (address operator);

    /**
     * @dev Approve or remove `operator` as an operator for the caller.
     * Operators can call {transferFrom} or {safeTransferFrom} for any token owned by the caller.
     *
     * Requirements:
     *
     * - The `operator` cannot be the caller.
     *
     * Emits an {ApprovalForAll} event.
     */
    function setApprovalForAll(address operator, bool _approved) external;

    /**
     * @dev Returns if the `operator` is allowed to manage all of the assets of `owner`.
     *
     * See {setApprovalForAll}
     */
    function isApprovedForAll(address owner, address operator) external view returns (bool);

    /**
     * @dev Safely transfers `tokenId` token from `from` to `to`.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `tokenId` token must exist and be owned by `from`.
     * - If the caller is not `from`, it must be approved to move this token by either {approve} or {setApprovalForAll}.
     * - If `to` refers to a smart contract, it must implement {IERC721Receiver-onERC721Received}, which is called upon a safe transfer.
     *
     * Emits a {Transfer} event.
     */
    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId,
        bytes calldata data
    ) external;
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "../IERC20.sol";
import "../../../utils/Address.sol";

/**
 * @title SafeERC20
 * @dev Wrappers around ERC20 operations that throw on failure (when the token
 * contract returns false). Tokens that return no value (and instead revert or
 * throw on failure) are also supported, non-reverting calls are assumed to be
 * successful.
 * To use this library you can add a `using SafeERC20 for IERC20;` statement to your contract,
 * which allows you to call the safe operations as `token.safeTransfer(...)`, etc.
 */
library SafeERC20 {
    using Address for address;

    function safeTransfer(
        IERC20 token,
        address to,
        uint256 value
    ) internal {
        _callOptionalReturn(token, abi.encodeWithSelector(token.transfer.selector, to, value));
    }

    function safeTransferFrom(
        IERC20 token,
        address from,
        address to,
        uint256 value
    ) internal {
        _callOptionalReturn(token, abi.encodeWithSelector(token.transferFrom.selector, from, to, value));
    }

    /**
     * @dev Deprecated. This function has issues similar to the ones found in
     * {IERC20-approve}, and its usage is discouraged.
     *
     * Whenever possible, use {safeIncreaseAllowance} and
     * {safeDecreaseAllowance} instead.
     */
    function safeApprove(
        IERC20 token,
        address spender,
        uint256 value
    ) internal {
        // safeApprove should only be called when setting an initial allowance,
        // or when resetting it to zero. To increase and decrease it, use
        // 'safeIncreaseAllowance' and 'safeDecreaseAllowance'
        require(
            (value == 0) || (token.allowance(address(this), spender) == 0),
            "SafeERC20: approve from non-zero to non-zero allowance"
        );
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, value));
    }

    function safeIncreaseAllowance(
        IERC20 token,
        address spender,
        uint256 value
    ) internal {
        uint256 newAllowance = token.allowance(address(this), spender) + value;
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
    }

    function safeDecreaseAllowance(
        IERC20 token,
        address spender,
        uint256 value
    ) internal {
        unchecked {
            uint256 oldAllowance = token.allowance(address(this), spender);
            require(oldAllowance >= value, "SafeERC20: decreased allowance below zero");
            uint256 newAllowance = oldAllowance - value;
            _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
        }
    }

    /**
     * @dev Imitates a Solidity high-level call (i.e. a regular function call to a contract), relaxing the requirement
     * on the return value: the return value is optional (but if data is returned, it must not be false).
     * @param token The token targeted by the call.
     * @param data The call data (encoded using abi.encode or one of its variants).
     */
    function _callOptionalReturn(IERC20 token, bytes memory data) private {
        // We need to perform a low level call here, to bypass Solidity's return data size checking mechanism, since
        // we're implementing it ourselves. We use {Address.functionCall} to perform this call, which verifies that
        // the target address contains contract code and also asserts for success in the low-level call.

        bytes memory returndata = address(token).functionCall(data, "SafeERC20: low-level call failed");
        if (returndata.length > 0) {
            // Return data is optional
            require(abi.decode(returndata, (bool)), "SafeERC20: ERC20 operation did not succeed");
        }
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "../IERC20.sol";

/**
 * @dev Interface for the optional metadata functions from the ERC20 standard.
 *
 * _Available since v4.1._
 */
interface IERC20Metadata is IERC20 {
    /**
     * @dev Returns the name of the token.
     */
    function name() external view returns (string memory);

    /**
     * @dev Returns the symbol of the token.
     */
    function symbol() external view returns (string memory);

    /**
     * @dev Returns the decimals places of the token.
     */
    function decimals() external view returns (uint8);
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

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.0 (utils/Context.sol)

pragma solidity ^0.8.0;
import "../proxy/utils/Initializable.sol";

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
abstract contract ContextUpgradeable is Initializable {
    function __Context_init() internal initializer {
        __Context_init_unchained();
    }

    function __Context_init_unchained() internal initializer {
    }
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes calldata) {
        return msg.data;
    }
    uint256[50] private __gap;
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.0 (security/ReentrancyGuard.sol)

pragma solidity ^0.8.0;
import "../proxy/utils/Initializable.sol";

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
abstract contract ReentrancyGuardUpgradeable is Initializable {
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

    function __ReentrancyGuard_init() internal initializer {
        __ReentrancyGuard_init_unchained();
    }

    function __ReentrancyGuard_init_unchained() internal initializer {
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
    uint256[49] private __gap;
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.0 (proxy/utils/Initializable.sol)

pragma solidity ^0.8.0;

/**
 * @dev This is a base contract to aid in writing upgradeable contracts, or any kind of contract that will be deployed
 * behind a proxy. Since a proxied contract can't have a constructor, it's common to move constructor logic to an
 * external initializer function, usually called `initialize`. It then becomes necessary to protect this initializer
 * function so it can only be called once. The {initializer} modifier provided by this contract will have this effect.
 *
 * TIP: To avoid leaving the proxy in an uninitialized state, the initializer function should be called as early as
 * possible by providing the encoded function call as the `_data` argument to {ERC1967Proxy-constructor}.
 *
 * CAUTION: When used with inheritance, manual care must be taken to not invoke a parent initializer twice, or to ensure
 * that all initializers are idempotent. This is not verified automatically as constructors are by Solidity.
 *
 * [CAUTION]
 * ====
 * Avoid leaving a contract uninitialized.
 *
 * An uninitialized contract can be taken over by an attacker. This applies to both a proxy and its implementation
 * contract, which may impact the proxy. To initialize the implementation contract, you can either invoke the
 * initializer manually, or you can include a constructor to automatically mark it as initialized when it is deployed:
 *
 * [.hljs-theme-light.nopadding]
 * ```
 * /// @custom:oz-upgrades-unsafe-allow constructor
 * constructor() initializer {}
 * ```
 * ====
 */
abstract contract Initializable {
    /**
     * @dev Indicates that the contract has been initialized.
     */
    bool private _initialized;

    /**
     * @dev Indicates that the contract is in the process of being initialized.
     */
    bool private _initializing;

    /**
     * @dev Modifier to protect an initializer function from being invoked twice.
     */
    modifier initializer() {
        require(_initializing || !_initialized, "Initializable: contract is already initialized");

        bool isTopLevelCall = !_initializing;
        if (isTopLevelCall) {
            _initializing = true;
            _initialized = true;
        }

        _;

        if (isTopLevelCall) {
            _initializing = false;
        }
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.0 (access/Ownable.sol)

pragma solidity ^0.8.0;

import "../utils/ContextUpgradeable.sol";
import "../proxy/utils/Initializable.sol";

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
abstract contract OwnableUpgradeable is Initializable, ContextUpgradeable {
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    /**
     * @dev Initializes the contract setting the deployer as the initial owner.
     */
    function __Ownable_init() internal initializer {
        __Context_init_unchained();
        __Ownable_init_unchained();
    }

    function __Ownable_init_unchained() internal initializer {
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
    uint256[49] private __gap;
}