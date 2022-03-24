pragma solidity >=0.6.0 <0.8.0;
pragma abicoder v2;

import '@openzeppelin/contracts/access/Ownable.sol';
import '@openzeppelin/contracts/math/SafeMath.sol';
import '@openzeppelin/contracts/token/ERC20/SafeERC20.sol';
import './Errors.sol';

import './interfaces/IStaking.sol';
import './interfaces/IStakingFactory.sol';
import '@openzeppelin/contracts/proxy/Clones.sol';

contract StakingFactory is Ownable, IStakingFactory {
    using SafeERC20 for IERC20;
    using SafeMath for uint256;

    struct Pool {
        uint256 tvl;
        uint8 weight;
        bool isPool;
        bool ufoPool;
    }

    /**
     * @notice Weight is scaled by 100
     */
    uint8 public immutable WEIGHT_SCALE = 100;

    /**
     * @notice event when pool is created
     * @param poolIndex Index of the pool
     * @param pool address of the pool
     */
    event CreatePool(uint256 indexed poolIndex, address indexed pool);

    /**
     * @notice event when tvl is updated
     * @param pool address of the pool
     */
    event UpdateTvl(address indexed pool, uint256 tvl);

    /**
     * @notice pool params
     */
    mapping(address => Pool) public pools;

    /**
     * @notice pool number to pool address
     */
    mapping(uint256 => address) public poolNumberToPoolAddress;

    /**
     * @notice total number of pools
     */
    uint256 public totalPools;

    /**
     * @notice total ufo token rewards allocation for locked pools
     */
    uint256 public ufoRewardsForUfoPools;

    /**
     * @notice total ufo token rewards allocation for unlocked pools
     */
    uint256 public ufoRewardsForLpPools;

    /**
     * @notice total ufo token claimed from the ufo pools
     */
    uint256 public claimedUfoRewardsForUfoPools;

    /**
     * @notice total ufo token rewards claimed from the lp pools
     */
    uint256 public claimedUfoRewardsForLpPools;

    /**
     * @notice address of the reward token
     */
    address public immutable rewardToken;

    /**
     * @notice address of implementation staking implementation contract
     */
    address public stakingImplementation;

    /**
     * @notice Constructor
     * @param _stakingImplementation address of implementation address of staking contract
     * @param _admin Address of the admin
     * @param _ufoRewardsForUfoPoolsPools Ufo Rewards to be distributed for the locked pools
     * @param _ufoRewardsForLpPoolsPools Ufo Rewards to be distributed for the unlocked pools
     * @param _rewardToken Address of the reward token,
     * @param _ufoToken Address of the ufo token
     * @param _lpToken Address of the lp token
     */
    constructor(
        address _stakingImplementation,
        address _admin,
        uint256 _ufoRewardsForUfoPoolsPools,
        uint256 _ufoRewardsForLpPoolsPools,
        address _rewardToken,
        address _ufoToken,
        address _lpToken
    ) {
        Ownable.transferOwnership(_admin);
        stakingImplementation = _stakingImplementation;
        ufoRewardsForUfoPools = _ufoRewardsForUfoPoolsPools;
        ufoRewardsForLpPools = _ufoRewardsForLpPoolsPools;

        rewardToken = _rewardToken;
        totalPools = 54;

        uint256 totalBlocksPerYear = uint256(360 days).mul(86400).mul(10).div(131); // for mainnet
        // uint256 totalBlocksPerYear = 1200; // for local
        // uint256 totalBlocksPerYear = 120000; // for goerli

        uint256 blocksPerEpoch = totalBlocksPerYear.div(totalPools);
        for (uint256 index = 0; index < totalPools; index += 2) {
            // for ease even pools are ufo pool, odd pools are lp pools
            uint256 lockInBlocks = blocksPerEpoch.mul(index).div(2).add(1);
            _createUfoAndLpPools(index, index + 1, _lpToken, _ufoToken, _admin, lockInBlocks, 100 + uint8(index * 2));
        }
    }

    function _createUfoAndLpPools(
        uint256 ufoPoolIndex,
        uint256 lpPoolIndex,
        address _lpToken,
        address _ufoToken,
        address _admin,
        uint256 lockInBlocks,
        uint8 weight
    ) internal {
        _createPool(ufoPoolIndex, _ufoToken, lockInBlocks, _admin, 612002322, weight);
        _createPool(lpPoolIndex, _lpToken, lockInBlocks, _admin, 10e26, weight);
    }

    /**
     * @notice internal function to calculate number of blocks per day
     * @param noOfdays Number of days
     */
    function approxNumberOfBlockPerDays(uint256 noOfdays) public pure returns (uint256) {
        return noOfdays.mul(1 days).mul(86400).mul(10).div(131);
    }

    /**
     * @notice internal function called in the constructor
     * @param poolIndex Index number of the pool
     * @param _stakingToken Address of the token to be staked
     * @param lockinBlocks Number of blocks the deposit is locked
     * @param _plasmaPerBlockPerToken Number of plasma tokens to be release per staking token per block
     * @param _poolWeight Reward weight of the pool. Higher weight, higher rewards
     */
    function _createPool(
        uint256 poolIndex,
        address _stakingToken,
        uint256 lockinBlocks,
        address _admin,
        uint256 _plasmaPerBlockPerToken,
        uint8 _poolWeight
    ) internal {
        require(_poolWeight != 0, Errors.SHOULD_BE_NON_ZERO);
        require(lockinBlocks != 0, Errors.SHOULD_BE_NON_ZERO);

        address _pool = Clones.clone(stakingImplementation);
        IStaking(_pool).initialize(_stakingToken, lockinBlocks, _admin, _plasmaPerBlockPerToken);
        pools[_pool] = Pool(0, _poolWeight, true, poolIndex % 2 == 0);
        poolNumberToPoolAddress[poolIndex] = _pool;
        emit CreatePool(poolIndex, _pool);
    }

    /**
     * @notice Update the TVL. Only a pool can call
     * @param tvl New TVL of the pool
     */
    function updateTVL(uint256 tvl) external override onlyPool {
        pools[msg.sender].tvl = tvl;
        emit UpdateTvl(msg.sender, tvl);
    }

    /**
     * @notice Send ufo token rewards user. Only a pool can call
     * @param user Address of the user to send reward to
     * @param amount Amount of tokens to send
     */
    function flushReward(address user, uint256 amount) external override onlyPool {
        if (pools[msg.sender].ufoPool) {
            claimedUfoRewardsForUfoPools = claimedUfoRewardsForUfoPools.add(amount);
        } else {
            claimedUfoRewardsForLpPools = claimedUfoRewardsForLpPools.add(amount);
        }
        IERC20(rewardToken).safeTransfer(user, amount);
    }

    /**
     * @notice Get Total Weight of TVL locked in all contracts
     */
    function getTotalTVLWeight() public view override returns (uint256 ufoPoolWeight, uint256 lpPoolWeight) {
        for (uint256 index = 0; index < totalPools; index++) {
            if (index % 2 == 0) {
                ufoPoolWeight = ufoPoolWeight.add(_getPoolWeight(index));
            } else {
                lpPoolWeight = lpPoolWeight.add(_getPoolWeight(index));
            }
        }
    }

    /**
     * @notice Internal function to calculate the weight of pool
     */
    function _getPoolWeight(uint256 poolIndex) internal view returns (uint256) {
        Pool storage pool = pools[poolNumberToPoolAddress[poolIndex]];
        return pool.tvl.mul(pool.weight).div(WEIGHT_SCALE);
    }

    /**
     * @notice Calculate the number of UFO reward tokens a pool is entitiled to at given point in time.
     * @param pool Address of the pool
     */
    function getPoolShare(address pool) public view override returns (uint256 amount) {
        Pool storage _pool = pools[pool];
        if (!_pool.isPool) {
            return 0;
        }
        (uint256 ufoPoolWeight, uint256 lpPoolWeight) = getTotalTVLWeight();

        uint256 totalTvlWeight = _pool.ufoPool ? ufoPoolWeight : lpPoolWeight;
        if (totalTvlWeight == 0) {
            // to avoid division overflow when tvl is 0
            return 0;
        }
        uint256 totalReward = _pool.ufoPool ? ufoRewardsForUfoPools : ufoRewardsForLpPools;

        uint256 claimedRewards = _pool.ufoPool ? claimedUfoRewardsForUfoPools : claimedUfoRewardsForLpPools;
        amount = (totalReward.sub(claimedRewards)).mul(_pool.tvl.mul(_pool.weight).div(WEIGHT_SCALE)).div(totalTvlWeight);
    }

    /**
     * @notice Fetch Pool APR. Will return 0 if address is not a valid pool (or) the tvl in pool is zero
     * @param pool Address of the pool to fetch APR
     */
    function getPoolApr(address pool) public view returns (uint256) {
        uint256 share = getPoolShare(pool);
        Pool storage _pool = pools[pool];
        if (_pool.tvl == 0) {
            return 0;
        }
        return share.mul(10**18).div(_pool.tvl);
    }

    /**
     * @notice Change Ufo Rewards to be distributed for UFO pools
     * @param amount New Amount
     */
    function changeUfoRewardsForUfoPools(uint256 amount) external onlyOwner {
        require(amount > claimedUfoRewardsForLpPools, Errors.SHOULD_BE_MORE_THAN_CLAIMED);
        ufoRewardsForUfoPools = amount;
    }

    /**
     * @notice Change Ufo Rewards to be distributed for LP pools
     * @param amount New Amount
     */
    function changeUfoRewardsForLpPools(uint256 amount) external onlyOwner {
        require(amount > claimedUfoRewardsForLpPools, Errors.SHOULD_BE_MORE_THAN_CLAIMED);
        ufoRewardsForLpPools = amount;
    }

    /**
     * @notice Withdraw UFO tokens available in case of any emergency
     * @param recipient Address to receive the emergency deposit
     */
    function emergencyWithdrawRewardBalance(address recipient) external onlyOwner {
        uint256 rewardBalance = IERC20(rewardToken).balanceOf(address(this));
        IERC20(rewardToken).safeTransfer(recipient, rewardBalance);
    }

    /**
     * @notice claim plasma from multiple pools
     * @param poolIndexes Pool Indexed to claim from
     * @param depositNumbers Deposit Numbers to claim
     */
    function claimPlasmaFromPools(uint256[] calldata poolIndexes, uint256[][] calldata depositNumbers) external {
        require(poolIndexes.length == depositNumbers.length, Errors.ARITY_MISMATCH);
        for (uint256 index = 0; index < poolIndexes.length; index++) {
            claimPlasmaFromPool(poolIndexes[index], depositNumbers[index]);
        }
    }

    /**
     * @notice claim plasma from multiple pools
     * @param poolIndex Pool Index
     * @param depositNumbers Deposit Numbers to claim
     */
    function claimPlasmaFromPool(uint256 poolIndex, uint256[] calldata depositNumbers) public defence {
        address pool = poolNumberToPoolAddress[poolIndex];
        require(pool != address(0), Errors.SHOULD_BE_NON_ZERO);
        IStaking(pool).claimPlasmaFromFactory(depositNumbers, msg.sender);
    }

    /**
     * @notice ensures that sender is a registered pool
     */
    modifier onlyPool() {
        require(pools[msg.sender].isPool, Errors.ONLY_POOLS_CAN_CALL);
        _;
    }

    /**
     * @notice Modifier to prevent contract interaction
     */
    modifier defence() {
        require((msg.sender == tx.origin), Errors.DEFENCE);
        _;
    }
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.0 <0.8.0;

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
    constructor () internal {
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

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.0 <0.8.0;

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
     * @dev Returns the addition of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function tryAdd(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        uint256 c = a + b;
        if (c < a) return (false, 0);
        return (true, c);
    }

    /**
     * @dev Returns the substraction of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function trySub(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        if (b > a) return (false, 0);
        return (true, a - b);
    }

    /**
     * @dev Returns the multiplication of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function tryMul(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        // Gas optimization: this is cheaper than requiring 'a' not being zero, but the
        // benefit is lost if 'b' is also tested.
        // See: https://github.com/OpenZeppelin/openzeppelin-contracts/pull/522
        if (a == 0) return (true, 0);
        uint256 c = a * b;
        if (c / a != b) return (false, 0);
        return (true, c);
    }

    /**
     * @dev Returns the division of two unsigned integers, with a division by zero flag.
     *
     * _Available since v3.4._
     */
    function tryDiv(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        if (b == 0) return (false, 0);
        return (true, a / b);
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers, with a division by zero flag.
     *
     * _Available since v3.4._
     */
    function tryMod(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        if (b == 0) return (false, 0);
        return (true, a % b);
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
     *
     * - Subtraction cannot overflow.
     */
    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b <= a, "SafeMath: subtraction overflow");
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
        if (a == 0) return 0;
        uint256 c = a * b;
        require(c / a == b, "SafeMath: multiplication overflow");
        return c;
    }

    /**
     * @dev Returns the integer division of two unsigned integers, reverting on
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
    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b > 0, "SafeMath: division by zero");
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
        require(b > 0, "SafeMath: modulo by zero");
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
        require(b <= a, errorMessage);
        return a - b;
    }

    /**
     * @dev Returns the integer division of two unsigned integers, reverting with custom message on
     * division by zero. The result is rounded towards zero.
     *
     * CAUTION: This function is deprecated because it requires allocating memory for the error
     * message unnecessarily. For custom revert reasons use {tryDiv}.
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
        require(b > 0, errorMessage);
        return a / b;
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
        require(b > 0, errorMessage);
        return a % b;
    }
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.0 <0.8.0;

import "./IERC20.sol";
import "../../math/SafeMath.sol";
import "../../utils/Address.sol";

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
    using SafeMath for uint256;
    using Address for address;

    function safeTransfer(IERC20 token, address to, uint256 value) internal {
        _callOptionalReturn(token, abi.encodeWithSelector(token.transfer.selector, to, value));
    }

    function safeTransferFrom(IERC20 token, address from, address to, uint256 value) internal {
        _callOptionalReturn(token, abi.encodeWithSelector(token.transferFrom.selector, from, to, value));
    }

    /**
     * @dev Deprecated. This function has issues similar to the ones found in
     * {IERC20-approve}, and its usage is discouraged.
     *
     * Whenever possible, use {safeIncreaseAllowance} and
     * {safeDecreaseAllowance} instead.
     */
    function safeApprove(IERC20 token, address spender, uint256 value) internal {
        // safeApprove should only be called when setting an initial allowance,
        // or when resetting it to zero. To increase and decrease it, use
        // 'safeIncreaseAllowance' and 'safeDecreaseAllowance'
        // solhint-disable-next-line max-line-length
        require((value == 0) || (token.allowance(address(this), spender) == 0),
            "SafeERC20: approve from non-zero to non-zero allowance"
        );
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, value));
    }

    function safeIncreaseAllowance(IERC20 token, address spender, uint256 value) internal {
        uint256 newAllowance = token.allowance(address(this), spender).add(value);
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
    }

    function safeDecreaseAllowance(IERC20 token, address spender, uint256 value) internal {
        uint256 newAllowance = token.allowance(address(this), spender).sub(value, "SafeERC20: decreased allowance below zero");
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
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
        if (returndata.length > 0) { // Return data is optional
            // solhint-disable-next-line max-line-length
            require(abi.decode(returndata, (bool)), "SafeERC20: ERC20 operation did not succeed");
        }
    }
}

//SPDX-License-Identifier: MIT

pragma solidity >=0.6.0 <0.8.0;

library Errors {
    string public constant ONLY_WHEN_DEPOSITED = '1';
    string public constant ONLY_DEPOSITOR = '2';
    string public constant VESTED_TIME_NOT_REACHED = '3';
    string public constant ONLY_AFTER_END_BLOCK = '4';
    string public constant ONLY_BEFORE_STAKING_ENDS = '5';
    string public constant ONLY_FACTORY_CAN_CALL = '6';
    string public constant DEFENCE = '7';
    string public constant ONLY_WHEN_WITHDRAWN = '8';
    string public constant SHOULD_BE_NON_ZERO = '9';
    string public constant SHOULD_BE_MORE_THAN_CLAIMED = 'A';
    string public constant ONLY_POOLS_CAN_CALL = 'B';
    string public constant LOCK_IN_BLOCK_LESS_THAN_MIN = 'C';
    string public constant EXCEEDS_MAX_ITERATION = 'D';
    string public constant SHOULD_BE_ZERO = 'E';
    string public constant ARITY_MISMATCH = 'F';
}

pragma solidity >=0.6.0 <0.8.0;

interface IStaking {
    function initialize(
        address _stakingToken,
        uint256 _lockinBlocks,
        address _operator,
        uint256 _plasmaPerBlockPerToken
    ) external;

    function claimPlasmaFromFactory(uint256[] calldata depositNumbers, address depositor) external;
}

pragma solidity >=0.6.0 <0.8.0;

interface IStakingFactory {
    function updateTVL(uint256 tvl) external;

    function flushReward(address user, uint256 amount) external;

    function getTotalTVLWeight() external view returns (uint256 lockedPoolTvlWeight, uint256 unlockedPoolTvlWeight);

    function getPoolShare(address pool) external view returns (uint256 amount);
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.0 <0.8.0;

/**
 * @dev https://eips.ethereum.org/EIPS/eip-1167[EIP 1167] is a standard for
 * deploying minimal proxy contracts, also known as "clones".
 *
 * > To simply and cheaply clone contract functionality in an immutable way, this standard specifies
 * > a minimal bytecode implementation that delegates all calls to a known, fixed address.
 *
 * The library includes functions to deploy a proxy using either `create` (traditional deployment) or `create2`
 * (salted deterministic deployment). It also includes functions to predict the addresses of clones deployed using the
 * deterministic method.
 *
 * _Available since v3.4._
 */
library Clones {
    /**
     * @dev Deploys and returns the address of a clone that mimics the behaviour of `master`.
     *
     * This function uses the create opcode, which should never revert.
     */
    function clone(address master) internal returns (address instance) {
        // solhint-disable-next-line no-inline-assembly
        assembly {
            let ptr := mload(0x40)
            mstore(ptr, 0x3d602d80600a3d3981f3363d3d373d3d3d363d73000000000000000000000000)
            mstore(add(ptr, 0x14), shl(0x60, master))
            mstore(add(ptr, 0x28), 0x5af43d82803e903d91602b57fd5bf30000000000000000000000000000000000)
            instance := create(0, ptr, 0x37)
        }
        require(instance != address(0), "ERC1167: create failed");
    }

    /**
     * @dev Deploys and returns the address of a clone that mimics the behaviour of `master`.
     *
     * This function uses the create2 opcode and a `salt` to deterministically deploy
     * the clone. Using the same `master` and `salt` multiple time will revert, since
     * the clones cannot be deployed twice at the same address.
     */
    function cloneDeterministic(address master, bytes32 salt) internal returns (address instance) {
        // solhint-disable-next-line no-inline-assembly
        assembly {
            let ptr := mload(0x40)
            mstore(ptr, 0x3d602d80600a3d3981f3363d3d373d3d3d363d73000000000000000000000000)
            mstore(add(ptr, 0x14), shl(0x60, master))
            mstore(add(ptr, 0x28), 0x5af43d82803e903d91602b57fd5bf30000000000000000000000000000000000)
            instance := create2(0, ptr, 0x37, salt)
        }
        require(instance != address(0), "ERC1167: create2 failed");
    }

    /**
     * @dev Computes the address of a clone deployed using {Clones-cloneDeterministic}.
     */
    function predictDeterministicAddress(address master, bytes32 salt, address deployer) internal pure returns (address predicted) {
        // solhint-disable-next-line no-inline-assembly
        assembly {
            let ptr := mload(0x40)
            mstore(ptr, 0x3d602d80600a3d3981f3363d3d373d3d3d363d73000000000000000000000000)
            mstore(add(ptr, 0x14), shl(0x60, master))
            mstore(add(ptr, 0x28), 0x5af43d82803e903d91602b57fd5bf3ff00000000000000000000000000000000)
            mstore(add(ptr, 0x38), shl(0x60, deployer))
            mstore(add(ptr, 0x4c), salt)
            mstore(add(ptr, 0x6c), keccak256(ptr, 0x37))
            predicted := keccak256(add(ptr, 0x37), 0x55)
        }
    }

    /**
     * @dev Computes the address of a clone deployed using {Clones-cloneDeterministic}.
     */
    function predictDeterministicAddress(address master, bytes32 salt) internal view returns (address predicted) {
        return predictDeterministicAddress(master, salt, address(this));
    }
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.0 <0.8.0;

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
abstract contract Context {
    function _msgSender() internal view virtual returns (address payable) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes memory) {
        this; // silence state mutability warning without generating bytecode - see https://github.com/ethereum/solidity/issues/2691
        return msg.data;
    }
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.0 <0.8.0;

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

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.2 <0.8.0;

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
        // solhint-disable-next-line no-inline-assembly
        assembly { size := extcodesize(account) }
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

        // solhint-disable-next-line avoid-low-level-calls, avoid-call-value
        (bool success, ) = recipient.call{ value: amount }("");
        require(success, "Address: unable to send value, recipient may have reverted");
    }

    /**
     * @dev Performs a Solidity function call using a low level `call`. A
     * plain`call` is an unsafe replacement for a function call: use this
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
    function functionCall(address target, bytes memory data, string memory errorMessage) internal returns (bytes memory) {
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
    function functionCallWithValue(address target, bytes memory data, uint256 value) internal returns (bytes memory) {
        return functionCallWithValue(target, data, value, "Address: low-level call with value failed");
    }

    /**
     * @dev Same as {xref-Address-functionCallWithValue-address-bytes-uint256-}[`functionCallWithValue`], but
     * with `errorMessage` as a fallback revert reason when `target` reverts.
     *
     * _Available since v3.1._
     */
    function functionCallWithValue(address target, bytes memory data, uint256 value, string memory errorMessage) internal returns (bytes memory) {
        require(address(this).balance >= value, "Address: insufficient balance for call");
        require(isContract(target), "Address: call to non-contract");

        // solhint-disable-next-line avoid-low-level-calls
        (bool success, bytes memory returndata) = target.call{ value: value }(data);
        return _verifyCallResult(success, returndata, errorMessage);
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
    function functionStaticCall(address target, bytes memory data, string memory errorMessage) internal view returns (bytes memory) {
        require(isContract(target), "Address: static call to non-contract");

        // solhint-disable-next-line avoid-low-level-calls
        (bool success, bytes memory returndata) = target.staticcall(data);
        return _verifyCallResult(success, returndata, errorMessage);
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
    function functionDelegateCall(address target, bytes memory data, string memory errorMessage) internal returns (bytes memory) {
        require(isContract(target), "Address: delegate call to non-contract");

        // solhint-disable-next-line avoid-low-level-calls
        (bool success, bytes memory returndata) = target.delegatecall(data);
        return _verifyCallResult(success, returndata, errorMessage);
    }

    function _verifyCallResult(bool success, bytes memory returndata, string memory errorMessage) private pure returns(bytes memory) {
        if (success) {
            return returndata;
        } else {
            // Look for revert reason and bubble it up if present
            if (returndata.length > 0) {
                // The easiest way to bubble the revert reason is using memory via assembly

                // solhint-disable-next-line no-inline-assembly
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