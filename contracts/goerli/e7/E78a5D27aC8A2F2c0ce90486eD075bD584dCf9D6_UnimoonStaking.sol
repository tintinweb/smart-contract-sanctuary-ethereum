//SPDX-License-Identifier: MIT
pragma solidity 0.8.13;

import "@openzeppelin/contracts/access/Ownable.sol";
import "./pancake-swap/libraries/TransferHelper.sol";

contract UnimoonStaking is Ownable {
    uint256 internal constant WEIGHT_MULTIPLIER = 1e6;
    uint256 internal constant MIN_STAKE_PERIOD = 3 minutes;
    uint256 internal constant MAX_STAKE_PERIOD = 10 minutes;
    uint256 internal constant REWARD_PER_WEIGHT_MULTIPLIER = 1e32;
    uint256 internal constant DENOMINATOR = 100;

    address public immutable REWARD_TOKEN;

    address public treasury;
    PoolInfo[2] public poolInfo;
    GeneralInfo public generalInfo;

    mapping(uint256 => mapping(address => UserStat)) public userStat;
    mapping(uint256 => mapping(address => Data[])) public userInfo;

    struct GeneralInfo {
        uint256 totalAllocPoint;
        uint256 totalWeight;
    }

    struct PoolInfo {
        address token;
        uint256 allocPoint;
        uint256 accPerShare;
        uint256 totalWeight;
        uint256 totalStaked;
    }

    struct Data {
        uint256 value;
        uint64 lockedFrom;
        uint64 lockedUntil;
        uint256 weight;
        uint256 lastAccValue;
        uint256 pendingYield;
    }

    struct UserStat {
        uint256 totalStaked;
        uint256 totalClaimed;
    }

    event Deposit(address indexed user, uint256 indexed pid, uint256 amount);
    event Withdraw(address indexed user, uint256 indexed pid, uint256 amount);
    event ClaimRewards(
        address indexed user,
        uint256 indexed pid,
        uint256 amount
    );
    event PoolUpdated(uint8 pid, address token, uint256 allocPoint);

    // tokens: 0 - unimoon, 1 - lp, 2 - usdc
    constructor(
        address[3] memory tokens,
        uint256[2] memory points,
        address owner
    ) {
        require(
            tokens[0] != address(0) &&
                tokens[1] != address(0) &&
                tokens[2] != address(0) &&
                owner != address(0),
            "UnimoonStaking: address 0x00..."
        );
        require(
            points[0] > 0 && points[1] > 0,
            "UnimoonStaking: zero allocation"
        );
        REWARD_TOKEN = tokens[2];
        poolInfo[0].token = tokens[0];
        poolInfo[0].allocPoint = points[0];
        poolInfo[1].token = tokens[1];
        poolInfo[1].allocPoint = points[1];
        generalInfo.totalAllocPoint = points[0] + points[1];

        if (owner != _msgSender()) _transferOwnership(owner);
    }

    modifier poolExist(uint256 _pid) {
        require(_pid < poolInfo.length, "UnimoonStaking: wrong pool ID");
        _;
    }

    /** @dev View function to see weight amount according to the staked value and lock duration
     * @param value staked value
     * @param duration lock duration
     * @return weight
     */
    function valueToWeight(uint256 value, uint256 duration)
        public
        pure
        returns (uint256)
    {
        return
            value *
            ((duration * WEIGHT_MULTIPLIER) /
                MAX_STAKE_PERIOD +
                WEIGHT_MULTIPLIER);
    }

    /** @dev View function to see all user's stakes at the current pool
     * @param user address
     * @param pid pool ID
     * @return all user's stakes info at the current pool
     */
    function getUserStakes(address user, uint256 pid)
        external
        view
        returns (Data[] memory)
    {
        return userInfo[pid][user];
    }

    /** @dev View function to get user’s pending rewards in current pool
     * @param user user address
     * @param pid pool id
     * @param stakeId index in array of deposits
     * @return earned rewards
     */
    function pendingRewardPerDeposit(
        address user,
        uint8 pid,
        uint256 stakeId
    ) public view returns (uint256) {
        if (stakeId >= userInfo[pid][user].length) return 0;
        else
            return
                userInfo[pid][user][stakeId].pendingYield +
                (((poolInfo[pid].accPerShare -
                    userInfo[pid][user][stakeId].lastAccValue) *
                    userInfo[pid][user][stakeId].weight) /
                    REWARD_PER_WEIGHT_MULTIPLIER);
    }

    /** @dev View function to get deniminators (necessary to treasury contract)
     * @return total allocation point value
     * @return total weight of both pools
     */
    function getAllocAndWeight() external view returns (uint256, uint256) {
        return (generalInfo.totalAllocPoint, generalInfo.totalWeight);
    }

    /** @dev View function to get (totalEarned, totalClaimed, totalPending) values for both pools
     * @param user address
     * @return total earned value
     * @return total claimed value
     * @return total pending value
     */
    function getRewardTotalStat(address user)
        external
        view
        returns (
            uint256,
            uint256,
            uint256
        )
    {
        uint256 totalPending;
        uint256 i;
        for (i; i < userInfo[0][user].length; i++) {
            totalPending += pendingRewardPerDeposit(user, 0, i);
        }
        for (i = 0; i < userInfo[1][user].length; i++) {
            totalPending += pendingRewardPerDeposit(user, 1, i);
        }
        return (
            totalPending +
                userStat[0][user].totalClaimed +
                userStat[1][user].totalClaimed,
            userStat[0][user].totalClaimed + userStat[1][user].totalClaimed,
            totalPending
        );
    }

    /** @dev Function to change treasury contract address
     * @notice available for owner only
     * @param _treasury new treasury contract address
     */
    function setTreasury(address _treasury) external onlyOwner {
        require(_treasury != address(0), "UnimoonStaking: address 0x0...");
        treasury = _treasury;
    }

    /** @dev Function to change pool weight (its possible to close pool by setting 0 allocation)
     * @notice available for owner only
     * @param _pid pool ID
     * @param _allocPoint new pool wight
     */
    function setAllocPoint(uint8 _pid, uint256 _allocPoint)
        external
        onlyOwner
        poolExist(_pid)
    {
        uint256 prevAllocPoint = poolInfo[_pid].allocPoint;
        poolInfo[_pid].allocPoint = _allocPoint;
        generalInfo.totalAllocPoint =
            generalInfo.totalAllocPoint -
            prevAllocPoint +
            _allocPoint;

        emit PoolUpdated(_pid, poolInfo[_pid].token, _allocPoint);
    }

    /** @dev Function to increase reward accumulators
     * @notice available for treasury only
     * @param amount reward amount to distribute
     */
    function increaseRewardPool(uint256 amount) external {
        require(_msgSender() == treasury, "UnimoonStaking: wrong sender");
        require(amount > 0, "UnimoonStaking: zero amount");
        require(
            generalInfo.totalAllocPoint > 0 && generalInfo.totalWeight > 0,
            "UnimoonStaking: zero denominator"
        );

        // to avoid division by zero
        if (poolInfo[0].totalWeight > 0 && poolInfo[1].totalWeight > 0) {
            poolInfo[0].accPerShare +=
                (((amount * poolInfo[0].allocPoint) /
                    generalInfo.totalAllocPoint) *
                    REWARD_PER_WEIGHT_MULTIPLIER) /
                poolInfo[0].totalWeight;
            poolInfo[1].accPerShare +=
                (((amount * poolInfo[1].allocPoint) /
                    generalInfo.totalAllocPoint) *
                    REWARD_PER_WEIGHT_MULTIPLIER) /
                poolInfo[1].totalWeight;
        } else if (poolInfo[0].totalWeight > 0) {
            poolInfo[0].accPerShare +=
                (amount * REWARD_PER_WEIGHT_MULTIPLIER) /
                poolInfo[0].totalWeight;
        } else {
            poolInfo[1].accPerShare +=
                (amount * REWARD_PER_WEIGHT_MULTIPLIER) /
                poolInfo[1].totalWeight;
        }
    }

    /** @dev Function to stake
     * @param pid pool id
     * @param amount to stake
     * @param duration lock duration
     */
    function deposit(
        uint8 pid,
        uint256 amount,
        uint32 duration
    ) external poolExist(pid) {
        require(amount > 0, "UnimoonStaking: zero amount");
        require(
            duration >= MIN_STAKE_PERIOD && duration <= MAX_STAKE_PERIOD,
            "UnimoonStaking: wrong duration"
        );

        PoolInfo storage pool = poolInfo[pid];

        uint256 stakeWeight = valueToWeight(amount, duration);

        userInfo[pid][_msgSender()].push(
            Data({
                value: amount,
                lockedFrom: uint64(block.timestamp),
                lockedUntil: uint64(block.timestamp + duration),
                weight: stakeWeight,
                lastAccValue: pool.accPerShare,
                pendingYield: 0
            })
        );
        userStat[pid][_msgSender()].totalStaked += amount;
        pool.totalWeight += stakeWeight;
        generalInfo.totalWeight += stakeWeight;
        pool.totalStaked += amount;

        TransferHelper.safeTransferFrom(
            pool.token,
            _msgSender(),
            address(this),
            amount
        );

        emit Deposit(_msgSender(), pid, amount);
    }

    /** @dev Function to unstake
     * @param pid pool id
     * @param stakeId an index of user's deposit in array of all user stakes
     * @param amount to unstake
     */
    function unstake(
        uint8 pid,
        uint256 stakeId,
        uint256 amount
    ) external poolExist(pid) {
        PoolInfo storage pool = poolInfo[pid];
        require(
            userInfo[pid][_msgSender()].length > stakeId,
            "UnimoonStaking: wrong stakeId"
        );
        Data storage stake = userInfo[pid][_msgSender()][stakeId];
        require(
            stake.lockedUntil <= block.timestamp,
            "UnimoonStaking: too early"
        );
        require(
            stake.value >= amount && amount > 0,
            "UnimoonStaking: wrong amount"
        );

        _updateUserReward(stake, pool);

        uint256 difference = stake.weight -
            valueToWeight(
                stake.value - amount,
                stake.lockedUntil - stake.lockedFrom
            );
        if (stake.value == amount) {
            _claimRewards(pid, stakeId);
            _removeUserStake(_msgSender(), pid, stakeId);
        } else {
            stake.value -= amount;
            stake.weight -= difference;
        }
        userStat[pid][_msgSender()].totalStaked -= amount;
        pool.totalWeight -= difference;
        generalInfo.totalWeight -= difference;
        pool.totalStaked -= amount;

        TransferHelper.safeTransfer(pool.token, _msgSender(), amount);

        emit Withdraw(_msgSender(), pid, amount);
    }

    /** @dev Function to claim earned rewards
     * @param pid pool ID
     */
    function claimRewards(uint8 pid, uint256 stakeId) external poolExist(pid) {
        _claimRewards(pid, stakeId);
    }

    function _updateUserReward(Data storage _stake, PoolInfo storage _pool)
        internal
    {
        _stake.pendingYield +=
            (_stake.weight * (_pool.accPerShare - _stake.lastAccValue)) /
            REWARD_PER_WEIGHT_MULTIPLIER;
        _stake.lastAccValue = _pool.accPerShare;
    }

    function _removeUserStake(
        address _user,
        uint256 _pid,
        uint256 _id
    ) internal {
        uint256 len = userInfo[_pid][_user].length;
        if (_id < len - 1) {
            Data memory _lastStake = userInfo[_pid][_user][len - 1];
            userInfo[_pid][_user][_id] = _lastStake;
        }
        userInfo[_pid][_user].pop();
    }

    function _claimRewards(uint8 _pid, uint256 _stakeId) internal {
        require(
            userInfo[_pid][_msgSender()].length > _stakeId,
            "UnimoonStaking: wrong stake id"
        );
        Data storage stake = userInfo[_pid][_msgSender()][_stakeId];
        PoolInfo storage pool = poolInfo[_pid];
        _updateUserReward(stake, pool);

        uint256 pendingYieldToClaim = stake.pendingYield;
        if (pendingYieldToClaim == 0) return;
        stake.pendingYield = 0;

        userStat[_pid][_msgSender()].totalClaimed += pendingYieldToClaim;

        TransferHelper.safeTransfer(
            REWARD_TOKEN,
            _msgSender(),
            pendingYieldToClaim
        );

        emit ClaimRewards(_msgSender(), _pid, pendingYieldToClaim);
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

// helper methods for interacting with ERC20 tokens and sending ETH that do not consistently return true/false
library TransferHelper {
    function safeApprove(
        address token,
        address to,
        uint256 value
    ) internal {
        // bytes4(keccak256(bytes('approve(address,uint256)')));
        (bool success, bytes memory data) =
            token.call(abi.encodeWithSelector(0x095ea7b3, to, value));
        require(
            success && (data.length == 0 || abi.decode(data, (bool))),
            "TransferHelper::safeApprove: approve failed"
        );
    }

    function safeTransfer(
        address token,
        address to,
        uint256 value
    ) internal {
        // bytes4(keccak256(bytes('transfer(address,uint256)')));
        (bool success, bytes memory data) =
            token.call(abi.encodeWithSelector(0xa9059cbb, to, value));
        require(
            success && (data.length == 0 || abi.decode(data, (bool))),
            "TransferHelper::safeTransfer: transfer failed"
        );
    }

    function safeTransferFrom(
        address token,
        address from,
        address to,
        uint256 value
    ) internal {
        // bytes4(keccak256(bytes('transferFrom(address,address,uint256)')));
        (bool success, bytes memory data) =
            token.call(abi.encodeWithSelector(0x23b872dd, from, to, value));
        require(
            success && (data.length == 0 || abi.decode(data, (bool))),
            "TransferHelper::transferFrom: transferFrom failed"
        );
    }

    function safeTransferETH(address to, uint256 value) internal {
        (bool success, ) = to.call{value: value}(new bytes(0));
        require(
            success,
            "TransferHelper::safeTransferETH: ETH transfer failed"
        );
    }
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