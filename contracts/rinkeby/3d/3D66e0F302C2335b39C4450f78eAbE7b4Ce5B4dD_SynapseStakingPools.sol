// SPDX-License-Identifier: MIT

pragma solidity 0.8.10;

import { RewardsDistribution } from "./abstract/RewardsDistribution.sol";
import { IERC20 } from "./interfaces/IERC20.sol";
import { SafeERC20 } from "./libraries/SafeERC20.sol";
import { ReentrancyGuard } from "./external/openzeppelin/ReentrancyGuard.sol";
import { EIP712 } from "./abstract/draft-EIP712.sol";
import { ECDSA } from "./libraries/ECDSA.sol";

/**
 * @title Synapse Staking Pools staking contract
 *
 * @author Sebastian Bauer
 *
 * @notice New Synapse staking contract allows stake ERC-20 token and get rewards in the same token. User choose
 * and join to one of previously created by the owner Staking Tiers. Each Staking Tier has defined by the owner
 * Staking Pools. Staking Tier can be of type Multi Level or Periodic.
 *
 * Multi Level Tier allows users to join to one of the Staking Pools in Tier and stake his tokens. User can join
 * to the first Staking Pool in Tier (without any restrictions) or to the one of the higher Staking Pools (with
 * lock time restriction or without if user join using 'addPromoStake' signed by signer defined in contract). In this
 * type of Tier the user can advance to the next Staking Pools (using 'compound'), collect his rewards earned
 * in the current Staking Pool (using 'collectReward'). At the end if user want to withdraw his tokens, it can
 * be performed using 'requestUnstake' and next 'unstake' or 'unstakeWithFee' functions.
 *
 * Periodic Tier is different from the Multi Level Tier. Every time when user join as new staker, lock time
 * restriction is calculated and assigned to user stake. Additionally, user cannot collect his rewards. All earned
 * rewards are paid out when user unstake his tokens (along with the staked tokens).
 */

 // solhint-disable-next-line max-states-count
contract SynapseStakingPools is ReentrancyGuard, RewardsDistribution, EIP712 {
    using SafeERC20 for IERC20;

    /// @notice Stake and reward token address
    address public token;
    /// @notice Fee collector address
    address public feeCollector;
    /// @notice Minimum value needed to stake
    uint256 public minimumToStake;
    /// @notice Total amount of rewards added to the contract
    uint256 public rewardsAdded;
    /// @notice Total amount of staked tokens in the entire contract
    uint256 public totalStaked;

    /// @dev Id of last added stake
    uint256 private stakeNonce;
    /// @dev Signer address used in 'addPromoStake'
    address private signer;

    /// @notice Typehash used in signing transaction in ;addPromoStake'
    // keccak256("addPromoStake(uint256 stakingTierId,uint256 stakingPoolId,uint256 amount,uint256 deadline,bytes32 salt)");
    bytes32 public constant ADDPROMOSTAKE_TYPEHASH = 0xc59986c292ca0222a72034e3cddb0f4d82e1d24803fd5d0f2c5c01ef43574d95;

    /// @dev Constant value used to calculate reward rate
    uint256 private constant YEAR = 365 days;
    /// @notice Maximum possible unstake fee value
    uint256 public constant MAXIMUM_MULTI_LEVEL_UNSTAKE_FEE = 9999;

    /// @notice Staking Tier stake types
    /// @dev MultiLevel = 0, Periodic = 1
    enum StakeType {
        MultiLevel,
        Periodic
    }

    /// @dev Staking Pool struct
    struct StakingPool {
        /// @dev Id of the Staking Tier too which Staking Pool belongs
        uint256 stakingTierId;
        /// @notice APR - Annual Percentage Rate
        uint256 apr;
        /// @notice Total amount of staked tokens in given Staking Pool
        uint256 totalTokensStaked;
        /// @notice Period after which the user can compound his stake and move to the next Staking Pool
        uint256 compoundPossiblePeriod;
        /// @notice Period after which the user can unstake his tokens without fee (after request unstake)
        uint256 unstakePeriod;
        /// @notice Amount of fee charged when user withdraw tokens too early (before the unstake period expires)
        uint256 unstakeFee;
        /// @notice Period after which user can unstake his tokens (only applies for Periodic Tier)
        uint256 periodicLockTime;
    }

    /// @dev Stake struct. This object is created every time, when user add his tokens to the contract
    struct Stake {
        /// @dev Id of the Staking Tier to which Stake belongs
        uint256 stakingTierId;
        /// @dev Id of the Staking Pool to which Stake belongs
        uint256 stakingPoolId;
        /// @dev Stake type - same as the type of Staking Tier
        StakeType stakeType;
        /// @notice Timestamp of Stake start time
        uint256 startTime;
        /// @notice Amount of staked tokens in the given Stake
        uint256 stakedTokens;
        /// @notice Timestamp after which user can compound his Stake to the next Staking Pool
        uint256 compoundPossibleAt;
        /// @notice Timestamp to which user cannot unstake his tokens (only applies to Periodic StakeType)
        uint256 lockTime;
        /// @notice Period (after request unstake) after which user can unstake his tokens without any fee
        uint256 unstakePeriod;
        /// @notice Amount of the fee which user pay in case of too early unstaked tokens
        uint256 unstakeFee;
        /// @dev Flag that shows whether is during unstake process (request unstake)
        bool isWithdrawing;
        /// @notice Timestamp of performed request unstake
        uint256 requestUnstakeTime;
        /// @notice Timestamp after which user can withdraw his tokens without any fee ('requestUnstakeTime' + 'unstakePeriod')
        uint256 withdrawalPossibleAt;
        /// @notice Amount of reward per second
        uint256 rewardRate;
        /// @dev Flag that shows if Stake exists
        bool exists;
    }

    /// @notice Staking Tiers. True - exists, False - not exists
    mapping(uint256 => bool) public stakingTiers;

    /// @notice Staking Tiers lock. If true, no one can join to the given Staking Tier to any Staking Pool
    mapping(uint256 => bool) public stakingTiersLock;

    /**
     * @notice Staking Tiers reward end time. After this time rewards are no longer earned
     * @dev Used to calculations only if greater than zero
     */
    mapping(uint256 => uint256) public stakingTiersRewardEndTime;

    /// @notice Staking Tiers stake type
    mapping(uint256 => StakeType) public stakingTiersStakeType;

    /// @notice Staking Pools for each Staking Tier
    mapping(uint256 => StakingPool[]) public stakingPoolsToTier;

    /**
     * @dev Staking Pool mapping used to verification if Staking Pool exists in given Staking Tier.
     * Staking Tier Id => Staking Pool Id => bool
     */
    mapping(uint256 => mapping(uint256 => bool)) public isStakingPoolExistsInTier;

    /// @notice User Stakes. Address => Stake Id => Stake
    mapping(address => mapping(uint256 => Stake)) public userStake;

    /// @notice All user Stakes ids
    mapping(address => uint256[]) public userStakeIds;

    /// @dev Hashes used during performing 'addPromoStake'
    mapping(bytes32 => bool) public usedHashes;

    /**
     * @dev Emitted when new Staking Tier is added
     * @param stakingTierId Staking Tier Id
     */
    event StakingTierAdded(uint256 stakingTierId);

    /**
     * @dev Emitted when new Staking Pool is added
     * @param stakingTierId Staking Tier Id for which Staking Pool belongs
     * @param stakingPoolId Staking Pool Id
     */
    event StakingPoolAdded(uint256 stakingTierId, uint256 stakingPoolId);

    /**
     * @dev Emitted when user add new stake to the contract
     * @param user Staker address
     * @param stakeId Stake Id
     * @param stakingTierId Staking Tier Id for which Stake belongs
     * @param stakingPoolId Staking Pool Id for which Stake belongs
     * @param startTime Timestamp when stake has been added to the contract
     * @param rewardRate Calculated reward per one second for given Stake
     * @param tokensAmount Amount of tokens added to the contract
     */
    event StakeAdded(
        address indexed user,
        uint256 indexed stakeId,
        uint256 stakingTierId,
        uint256 stakingPoolId,
        uint256 startTime,
        uint256 rewardRate,
        uint256 tokensAmount
    );

    /**
     * @dev Emitted when user collect reward being on the first Staking Pool in Tier
     * @param user Staker address
     * @param stakeId Stake Id
     * @param startTime New start time for stake - timestamp when rewards has been collected
     */
    event StakeStartTimeRenewed(address indexed user, uint256 indexed stakeId, uint256 startTime);

    /**
     * @dev Emitted when user performed request unstake
     * @param user Staker address
     * @param stakeId Stake Id
     */
    event UnstakeRequested(address indexed user, uint256 indexed stakeId);

    /**
     * @dev Emitted when user unstake his tokens from the contract
     * @param user Staker address
     * @param stakeId Stake Id
     * @param amount Total amount of unstaked tokens
     */
    event StakeRemoved(address indexed user, uint256 stakeId, uint256 amount);

    /**
     * @dev Emitted every time, when Stake is moved to any other Staking Pool - compound
     * or collect reward being on higher Staking Pools
     *
     * @param user Staker address
     * @param stakeId Stake Id
     * @param oldStakingPoolId Staking Pool Id from which Stake is moved
     * @param newStakingPoolId Staking Pool Id to which Stake is moved
     * @param startTime New Stake start time - timestamp when Stake was moved to other Staking Pool
     * @param rewardRate New calculated reward rate per second
     * @param tokensAmount Total amount of tokens moved to other Staking Pool
     */
    event StakeMovedToOtherStakingPool(
        address indexed user,
        uint256 indexed stakeId,
        uint256 oldStakingPoolId,
        uint256 newStakingPoolId,
        uint256 startTime,
        uint256 rewardRate,
        uint256 tokensAmount
    );

    /**
     * @dev Emitted when user collect rewards earned on the any of his Stakes
     * @param user Staker address
     * @param reward Amount of the collected rewards
     */
    event RewardsCollected(address indexed user, uint256 reward);

    /**
     * @dev Emitted when user compound any of his Stakes
     * @param user Staker address
     * @param amount Amount of tokens compounded
     */
    event Compounded(address indexed user, uint256 amount);

    /**
     * @dev Emitted when rewards has been added to the contract
     * @param amount Total amount of tokens added to the contract
     */
    event RewardsAdded(uint256 amount);

    // solhint-disable-next-line no-empty-blocks
    constructor() EIP712("SynapseStakingPools", "1") {}

    /**
     * @dev Validates if stake for given user and stake id exists
     * @param user Staker address
     * @param stakeId Stake Id
     */
    modifier hasStake(address user, uint256 stakeId) {
        require(userStake[user][stakeId].exists, "Stake doesn't exist");
        _;
    }

    /**
     * @dev Validates if user can unstake his tokens for given Stake without any fee
     * @param stakeId Stake Id
     */
    modifier _canUnstakeWithoutFee(uint256 stakeId) {
        require(block.timestamp >= userStake[msg.sender][stakeId].withdrawalPossibleAt, "Cannot unstake without fee");
        _;
    }

    /**
     * @dev Validates if Staking Tier exists
     * @param stakingTierId Staking Tier Id
     */
    modifier doesStakingTierExist(uint256 stakingTierId) {
        require(_doesStakingTierExist(stakingTierId), "Staking Tier doesn't exist");
        _;
    }

    /**
     * @dev Validates if Staking Tier doesn't exist
     * @param stakingTierId Staking Tier Id
     */
    modifier doesStakingTierNotExist(uint256 stakingTierId) {
        require(!_doesStakingTierExist(stakingTierId), "Staking Tier exists");
        _;
    }

    /**
     * @dev Validates if user can join to Staking Tier (Staking Tier lock verification)
     * @param stakingTierId Staking Tier Id
     */
    modifier canJoinToStakingTier(uint256 stakingTierId) {
        require(!stakingTiersLock[stakingTierId], "Staking Tier is locked");
        _;
    }

    /**
     * @dev Validates if Staking Pool exists
     * @param stakingTierId Staking Tier Id
     * @param stakingPoolId Staking Pool Id
     */
    modifier doesStakingPoolExist(uint256 stakingTierId, uint256 stakingPoolId) {
        require(isStakingPoolExistsInTier[stakingTierId][stakingPoolId], "Staking Pool doesn't exist");
        _;
    }

    /**
     * @dev Validates if given value is equal or greather than minimum possible value to stake
     * @param amount Amount of tokens
     */
    modifier validateMinimumToStakeValue(uint256 amount) {
        require(amount >= minimumToStake, "Too low amount");
        _;
    }

    /**
     * @dev Validates if given unstakeFee value is equal or lower than maximum possible value
     * @param unstakeFee Unstake fee value
     */
    modifier validateMultiLevelUnstakeFee(uint256 unstakeFee) {
        require(unstakeFee <= MAXIMUM_MULTI_LEVEL_UNSTAKE_FEE, "Too large 'unstakeFee' value");
        _;
    }

    /**
     * @dev Validates if Staking Tier for given stakingTierId is the type of the given stakeType
     * @param stakingTierId Staking Tier Id
     * @param stakeType Stake type to compare
     */
    modifier validateStakeType(uint256 stakingTierId, StakeType stakeType) {
        require(stakingTiersStakeType[stakingTierId] == stakeType, "Invalid Stake Type");
        _;
    }

    /**
     * @dev Validates if given fee collector is not zero address
     * @param _feeCollector Fee collector address
     */
    modifier validateFeeCollector(address _feeCollector) {
        require(_feeCollector != address(0), "_feeCollector cannot be address(0)");
        _;
    }

    /**
     * @dev Validates if given signer is not zero address
     * @param _signer Signer address
     */
    modifier validateSigner(address _signer) {
        require(_signer != address(0), "_signer cannot be address(0)");
        _;
    }

    /**
     * @notice One-time initialization contract function
     *
     * @dev Validations :
     * - All of parameters value in this function cannot be zero address
     * - Only contract owner can perform this function
     *
     * @param _token Address of the staking and rewards token
     * @param _feeCollector Address for which fee will be send
     * @param _signer Address of the signer which will be using to sign messages in 'addPromoStake'
     */
    function init(
        address _token,
        address _feeCollector,
        address _signer
    )
        external
        onlyOwner
        validateFeeCollector(_feeCollector)
        validateSigner(_signer)
    {
        require(_token != address(0), "_token cannot be address(0)");
        require(token == address(0), "init already done");

        token = _token;
        feeCollector = _feeCollector;
        signer = _signer;

        // To avoid the same reward rate for the same two staked tokens, minimum staked
        // tokens value cannot be lower than 1 token
        minimumToStake = 1 * 10 ** 18;
    }

    /**
     * @notice Allows to update signer address
     *
     * @dev Validations :
     * - Only contract owner can perform this function
     * - Signer cannot be zero address
     *
     * @param _signer New signer address
     */
    function updateSigner(address _signer) external onlyOwner validateSigner(_signer) {
        signer = _signer;
    }

    /**
     * @notice Allows to update fee collector address
     *
     * @dev Validations :
     * - Only contract owner can perform this function
     * - Fee collector cannot be zero address
     *
     * @param _feeCollector New fee collector address
     */
    function updateFeeCollector(address _feeCollector) external onlyOwner validateFeeCollector(_feeCollector) {
        feeCollector = _feeCollector;
    }

    /**
     * @notice Allows to update minimum to stake value
     *
     * @dev Validations :
     * - Only contract owner can perform this function
     * - Minimum to stake value cannot be lower than 1 token
     *
     * @param val New 'minimumToStake' value
     */
    function updateMinimumToStake(uint256 val) external onlyOwner {
        require(val >= 1 * 10 ** 18, "Too low value");

        minimumToStake = val;
    }

    /**
     * @notice Adds a new Staking Tier to the contract.
     *
     * @dev Validations :
     * - Only contract owner can perform this function
     * - Staking Tier with id given in 'stakingTierId' cannot exists
     * - 'stakeType' value cannot be out of range. It can be only 0 or 1.
     *
     * Emits a 'StakingTierAdded' event.
     *
     * @param stakingTierId Staking Tier Id
     * @param stakeType Stake type
     */
    function addStakingTier(
        uint256 stakingTierId,
        uint256 stakeType
    )
        external
        onlyOwner
        doesStakingTierNotExist(stakingTierId)
    {
        require(stakeType <= 1, "stakeType out of range");

        stakingTiers[stakingTierId] = true;
        stakingTiersStakeType[stakingTierId] = StakeType(stakeType);

        emit StakingTierAdded(stakingTierId);
    }

    /**
     * @notice Updates Staking Tier lock.
     * If value is set to 'true', then users cannot add his tokens
     * to stake in Staking Tier.
     *
     * @dev Validations :
     * - Only contract owner can perform this function
     * - Staking Tier with id given in 'stakingTierId' must exists
     *
     * @param stakingTierId Staking Tier Id
     * @param lockValue New lock value. True - locked, False - unlocked
     */
    function updateStakingTierLock(
        uint256 stakingTierId,
        bool lockValue
    )
        external
        onlyOwner
        doesStakingTierExist(stakingTierId)
    {
        stakingTiersLock[stakingTierId] = lockValue;
    }

    /**
     * @notice Updates Staking Tier reward end time.
     *
     * @dev Validations :
     * - Only contract owner can perform this function
     * - Staking Tier with id given in 'stakingTierId' must exists
     * - 'rewardEndTime' must be future timestamp
     *
     * @param stakingTierId Staking Tier Id
     * @param rewardEndTime New reward end time
     */
    function updateStakingTierEndTime(
        uint256 stakingTierId,
        uint256 rewardEndTime
    )
        external
        onlyOwner
        doesStakingTierExist(stakingTierId)
    {
        require(rewardEndTime >= block.timestamp, "End time cannot be from past");

        stakingTiersRewardEndTime[stakingTierId] = rewardEndTime;
    }

    /**
     * @notice Adds new Staking Pool to Staking Tier with Multi Level stake type. New Staking Pool
     * is added like a last in the Staking Tier. It means that Staking Pools must be added in the
     * order they are supposed to be in the Staking Tier.
     *
     * @dev Validations :
     * - Only contract owner can perform this function
     * - Staking Tier with id given in 'stakingTierId' must exists
     * - Staking Tier must be Multi Level
     * - Unstake fee must be lower than 100% (10_000)
     *
     * Emits a 'StakingPoolAdded' event.
     *
     * Staking Pool Id is assign automatically and value is equal array length for which
     * Staking Pool belongs.
     *
     * @param _stakingTierId Staking Tier Id
     * @param _apr APR - Annual Percentage Rate (100 is 1%)
     * @param _compoundPossiblePeriod Period after user can compound and move his stake to the next Staking Pool
     * @param _unstakePeriod Period after which the user can unstake his tokens without fee (after request unstake)
     * @param _unstakeFee Amount of fee charged when user withdraw tokens too early (before the unstake period
     * expires) - 100 is 1%
     */
    function addMultiLevelStakingPool(
        uint256 _stakingTierId,
        uint256 _apr,
        uint256 _compoundPossiblePeriod,
        uint256 _unstakePeriod,
        uint256 _unstakeFee
    )
        external
        onlyOwner
        doesStakingTierExist(_stakingTierId)
        validateStakeType(_stakingTierId, StakeType.MultiLevel)
        validateMultiLevelUnstakeFee(_unstakeFee)
    {
        StakingPool memory stakingPool;
        stakingPool.stakingTierId = _stakingTierId;
        stakingPool.apr = _apr;
        stakingPool.compoundPossiblePeriod = _compoundPossiblePeriod;
        stakingPool.unstakePeriod = _unstakePeriod;
        stakingPool.unstakeFee = _unstakeFee;

        stakingPoolsToTier[_stakingTierId].push(stakingPool);

        // Setting flag in mapping which allows to verify if Staking Pool exists.
        isStakingPoolExistsInTier[_stakingTierId][stakingPoolsToTier[_stakingTierId].length] = true;

        emit StakingPoolAdded(_stakingTierId, stakingPoolsToTier[_stakingTierId].length);
    }

    /**
     * @notice Adds new Staking Pool to Staking Tier with Multi Level stake type. New Staking Pool
     * is added like a last in the Staking Tier. It means that Staking Pools must be added in the
     * order they are supposed to be in the Staking Tier.
     *
     * @dev Validations :
     * - Only contract owner can perform this function
     * - Staking Tier with id given in 'stakingTierId' must exists
     * - Staking Tier must be Periodic
     *
     * Emits a 'StakingPoolAdded' event.
     *
     * Staking Pool Id is assign automatically and value is equal array length for which
     * Staking Pool belongs.
     *
     * @param _stakingTierId Staking Tier Id
     * @param _apr APR - Annual Percentage Rate (100 is 1%)
     * @param _periodicLockTime Period after which user can unstake his tokens (only applies for Periodic Tier)
     */
    function addPeriodicStakingPool(
        uint256 _stakingTierId,
        uint256 _apr,
        uint256 _periodicLockTime
    )
        external
        onlyOwner
        doesStakingTierExist(_stakingTierId)
        validateStakeType(_stakingTierId, StakeType.Periodic)
    {
        StakingPool memory stakingPool;
        stakingPool.stakingTierId = _stakingTierId;
        stakingPool.apr = _apr;
        stakingPool.periodicLockTime = _periodicLockTime;

        stakingPoolsToTier[_stakingTierId].push(stakingPool);

        // Setting flag in mapping which allows to verify if Staking Pool exists.
        isStakingPoolExistsInTier[_stakingTierId][stakingPoolsToTier[_stakingTierId].length] = true;

        emit StakingPoolAdded(_stakingTierId, stakingPoolsToTier[_stakingTierId].length);
    }

    /**
     * @notice Updates APR in the given Staking Pool.
     *
     * Note that APR update in the Staking Pool doesn't recalculate reward rate for all Stakes in
     * the given Staking Pool.
     *
     * @dev Validations :
     * - Only contract owner can perform this function
     * - Staking Tier with id given in 'stakingTierId' must exists
     * - Staking Pool with id given in 'stakingPoolId' must exists
     *
     * @param stakingTierId Staking Tier Id
     * @param stakingPoolId Staking Pool Id
     * @param _apr APR - Annual Percentage Rate (100 is 1%)
     */
    function updateStakingPoolApr(
        uint256 stakingTierId,
        uint256 stakingPoolId,
        uint256 _apr
    )
        external
        onlyOwner
        doesStakingPoolExist(stakingTierId, stakingPoolId)
    {
        StakingPool storage stakingPool = stakingPoolsToTier[stakingTierId][stakingPoolId - 1];
        stakingPool.apr = _apr;
    }

    /**
     * @notice Updates compound possible period in the given Staking Pool.
     *
     * Note that compound possible period update in the Staking Pool doesn't change 'compoundPossibleAt' time in
     * Stakes in the given Staking Pool
     *
     * @dev Validations :
     * - Only contract owner can perform this function
     * - Staking Tier with id given in 'stakingTierId' must exists
     * - Staking Pool with id given in 'stakingPoolId' must exists
     * - Staking Tier must be Multi Level
     *
     * @param stakingTierId Staking Tier Id
     * @param stakingPoolId Staking Pool Id
     * @param _compoundPossiblePeriod Period after which the user can compound his stake and move to the next Staking Pool
     */
    function updateStakingPoolCompoundPossiblePeriod(
        uint256 stakingTierId,
        uint256 stakingPoolId,
        uint256 _compoundPossiblePeriod
    )
        external
        onlyOwner
        doesStakingPoolExist(stakingTierId, stakingPoolId)
        validateStakeType(stakingTierId, StakeType.MultiLevel)
    {
        StakingPool storage stakingPool = stakingPoolsToTier[stakingTierId][stakingPoolId - 1];
        stakingPool.compoundPossiblePeriod = _compoundPossiblePeriod;
    }

    /**
     * @notice Updates unstake period in the given Staking Pool.
     *
     * Note that unstake period update in the Staking Pool doesn't change 'unstakePeriod' in
     * Stakes in the given Staking Pool.
     *
     * @dev Validations :
     * - Only contract owner can perform this function
     * - Staking Tier with id given in 'stakingTierId' must exists
     * - Staking Pool with id given in 'stakingPoolId' must exists
     * - Staking Tier must be Multi Level
     *
     * @param stakingTierId Staking Tier Id
     * @param stakingPoolId Staking Pool Id
     * @param _unstakePeriod Period after which the user can unstake his tokens without fee (after request unstake)
     */
    function updateStakingPoolUnstakePeriod(
        uint256 stakingTierId,
        uint256 stakingPoolId,
        uint256 _unstakePeriod
    )
        external
        onlyOwner
        doesStakingPoolExist(stakingTierId, stakingPoolId)
        validateStakeType(stakingTierId, StakeType.MultiLevel)
    {
        StakingPool storage stakingPool = stakingPoolsToTier[stakingTierId][stakingPoolId - 1];
        stakingPool.unstakePeriod = _unstakePeriod;
    }

    /**
     * @notice Updates unstake fee in the given Staking Pool.
     *
     * Note that unstake fee update in the Staking Pool doesn't change 'unstakeFee' in
     * Stakes in the given Staking Pool.
     *
     * @dev Validations :
     * - Only contract owner can perform this function
     * - Staking Tier with id given in 'stakingTierId' must exists
     * - Staking Pool with id given in 'stakingPoolId' must exists
     * - Staking Tier must be Multi Level
     * - Unstake fee must be lower than 100% (10_000)
     *
     * @param stakingTierId Staking Tier Id
     * @param stakingPoolId Staking Pool Id
     * @param _unstakeFee Amount of the fee which user pay in case of too early unstaked tokens. 100 is 1%
     */
    function updateStakingPoolUnstakeFee(
        uint256 stakingTierId,
        uint256 stakingPoolId,
        uint256 _unstakeFee
    )
        external
        onlyOwner
        doesStakingPoolExist(stakingTierId, stakingPoolId)
        validateStakeType(stakingTierId, StakeType.MultiLevel)
        validateMultiLevelUnstakeFee(_unstakeFee)
    {
        StakingPool storage stakingPool = stakingPoolsToTier[stakingTierId][stakingPoolId - 1];
        stakingPool.unstakeFee = _unstakeFee;
    }

    /**
     * @notice Allows user to add his tokens to staking contract.
     *
     * Note that user must first perform 'approve' function which allows to add his tokens to this
     * staking contract.
     *
     * @dev Validations :
     * - Function is protected against Re-Entrancy Attacks
     * - Staking Tier with id given in 'stakingTierId' must exists
     * - Staking Pool with id given in 'stakingPoolId' must exists
     * - Joining to the given Staking Tier cannot be locked
     * - Amount of tokens which user want to add to staking contract must be greater than minimum possible value
     * - User must have amount of tokens which he wants to stake on his wallet
     *
     * Emits a 'StakeAdded' event.
     *
     * @param stakingTierId Staking Tier Id
     * @param stakingPoolId Staking Pool Id
     * @param amount Amount of tokens which user wants to stake in the staking contract
     */
    function addStake(
        uint256 stakingTierId,
        uint256 stakingPoolId,
        uint256 amount
    )
        external
        nonReentrant
        doesStakingPoolExist(stakingTierId, stakingPoolId)
        canJoinToStakingTier(stakingTierId)
        validateMinimumToStakeValue(amount)
    {
        amount = transferFrom(msg.sender, amount);
        _addStake(stakingTierId, stakingPoolId, amount, false);
    }

    /**
     * @notice Allows user to add his tokens to staking contract with transaction signed by the signer.
     * Stake added using this function doesn't have any lock time for compound or request unstake actions.
     * This special conditions apply only Multi Level Staking Tier - Stake added in Periodic Staking Tier
     * always have calculated lock time.
     *
     * Note that user must first perform 'approve' function which allows to add his tokens to this
     * staking contract.
     *
     * Note that transaction must be signed by the contract signer. This function uses EIP-712 signing
     * transacations.
     *
     * @dev Validations :
     * - Function is protected against Re-Entrancy Attacks
     * - Staking Tier with id given in 'stakingTierId' must exists
     * - Staking Pool with id given in 'stakingPoolId' must exists
     * - Joining to the given Staking Tier cannot be locked
     * - Amount of tokens which user want to add to staking contract must be greater than minimum possible value
     * - Deadline time cannot be from the past
     * - Hash which is calculated in function cannot be used before
     * - Signature sended in transaction must be correct (EIP-712)
     * - User must have amount of tokens which he wants to stake on his wallet
     *
     * Emits a 'StakeAdded' event.
     *
     * @param stakingTierId Staking Tier Id
     * @param stakingPoolId Staking Pool Id
     * @param amount Amount of tokens which user wants to stake in the staking contract
     * @param deadline Maximum possible perform time signed by the user
     * @param salt EIP-712 secure parameter
     * @param signature EIP-712 signature
     */
    function addPromoStake(
        uint256 stakingTierId,
        uint256 stakingPoolId,
        uint256 amount,
        uint256 deadline,
        bytes32 salt,
        bytes memory signature
    )
        external
        nonReentrant
        doesStakingPoolExist(stakingTierId, stakingPoolId)
        canJoinToStakingTier(stakingTierId)
        validateMinimumToStakeValue(amount)
    {
        require(deadline >= block.timestamp, "Expired deadline");

        bytes32 structHash = keccak256(abi.encode(ADDPROMOSTAKE_TYPEHASH, stakingTierId, stakingPoolId, amount, deadline, salt));
        bytes32 hash = _hashTypedDataV4(structHash);
        address msgSigner = ECDSA.recover(hash, signature);

        require(!usedHashes[hash], "Hash already used");
        usedHashes[hash] = true;

        require(msgSigner == signer, "Invalid signature");

        amount = transferFrom(msg.sender, amount);

        _addStake(stakingTierId, stakingPoolId, amount, true);
    }

    /**
     * @notice Allows to request unstake for the given Stake.
     *
     * @dev Validations :
     * - Stake for given id must exists
     * - Stake cannot be already during withdraw process
     * - Stake cannot be locked
     *
     * Emits an 'UnstakeRequested' event.
     *
     * @param stakeId Stake Id for which user want to request unstake
     */
    function requestUnstake(
        uint256 stakeId
    ) external hasStake(msg.sender, stakeId) {
        Stake storage stake = userStake[msg.sender][stakeId];
        require(!stake.isWithdrawing, "Cannot during withdrawing");

        if (stake.lockTime > 0) {
            require(stake.lockTime <= block.timestamp, "Cannot request unstake before end of lock time");
        }

        stake.isWithdrawing = true;
        stake.requestUnstakeTime = block.timestamp;
        stake.withdrawalPossibleAt = block.timestamp + stake.unstakePeriod;

        StakingPool storage stakingPool = stakingPoolsToTier[stake.stakingTierId][stake.stakingPoolId - 1];
        stakingPool.totalTokensStaked -= stake.stakedTokens;

        totalStaked -= stake.stakedTokens;

        emit UnstakeRequested(msg.sender, stakeId);
    }

    /**
     * @notice Allows to unstake tokens without any fee.
     *
     * @dev Validations :
     * - Function is protected against Re-Entrancy Attacks
     * - Stake for given id must exists
     * - 'withdrawaPossibleAt' must be greater than actual block.timestamp
     * - For the given Stake unstake process must be started (request unstake)
     *
     * Emits a 'StakeRemoved' event.
     *
     * @param stakeId Stake Id for which user want to unstake tokens
     */
    function unstake(
        uint256 stakeId
    )
        external
        nonReentrant
        hasStake(msg.sender, stakeId)
        _canUnstakeWithoutFee(stakeId)
    {
        _unstake(stakeId, false);
    }

    /**
     * @notice Allows to unstake tokens with fee.
     *
     * @dev Validations :
     * - Function is protected against Re-Entrancy Attacks
     * - Stake for given id must exists
     * - For the given Stake unstake process must be started (request unstake)
     *
     * Emits a 'StakeRemoved' event.
     *
     * @param stakeId Stake Id for which user want to unstake tokens
     */
    function unstakeWithFee(
        uint256 stakeId
    )
        external
        nonReentrant
        hasStake(msg.sender, stakeId)
    {
        _unstake(stakeId, true);
    }

    /**
     * @notice Allows to collect rewards earned for the given Stake.
     *
     * Note that collect rewards is possible only for Multi Level Stake.
     *
     * @dev Validations :
     * - Function is protected against Re-Entrancy Attacks
     * - Stake for given id must exists
     * - Stake must be Multi Level
     * - For the given Stake unstake process cannot be started (request unstake)
     * - Cannot collect rewards when Stake is in the Staking Pool with zero APR (zero reward rate)
     *
     * Emits a 'RewardsCollected' and 'StakeMovedToOtherStakingPool' event when Stake is in the Staking Pool higher
     * than first in Staking Tier or 'StakeStartTimeRenewed' when Stake is in the first Staking Pool in the Staking
     * Tier.
     *
     * @param stakeId Stake Id for which user want to unstake tokens
     */
    function collectReward(
        uint256 stakeId
    )
        external
        nonReentrant
        hasStake(msg.sender, stakeId)
    {
        Stake storage stake = userStake[msg.sender][stakeId];
        require(stake.stakeType == StakeType.MultiLevel, "Cannot for Periodic Stake");
        require(!stake.isWithdrawing, "Cannot during withdrawing");
        require(stake.rewardRate != 0, "Cannot for stake from zero APR Pool");

        if (stake.lockTime > 0) {
            require(stake.lockTime <= block.timestamp, "Cannot before end of lock time");

            // Clear lock time when it's from the past
            stake.lockTime = 0;
        }

        uint256 rewards = calculateRewards(
            stake.stakingTierId,
            stake.startTime,
            stake.rewardRate,
            block.timestamp
        );

        // Rewards calculation when Stake is in the higher than first Staking Pool in Staking Tier
        if (stake.stakingPoolId > 1) {
            uint256 oldStakingPoolId = stake.stakingPoolId;

            moveStakeToGivenStakingPool(stake, stake.stakingTierId, 1, stake.stakedTokens);

            emit StakeMovedToOtherStakingPool(
                msg.sender,
                stakeId,
                oldStakingPoolId,
                1,
                block.timestamp,
                stake.rewardRate,
                stake.stakedTokens
            );
        // Rewards calculation when Stake is in the first Staking Pool in Staking Tier
        } else {
            StakingPool storage stakingPool = stakingPoolsToTier[stake.stakingTierId][0];

            stake.startTime = block.timestamp;
            stake.compoundPossibleAt = block.timestamp + stakingPool.compoundPossiblePeriod;

            emit StakeStartTimeRenewed(msg.sender, stakeId, block.timestamp);
        }

        if (rewards > 0) {
            transfer(msg.sender, rewards);
        }

        emit RewardsCollected(msg.sender, rewards);
    }

    /**
     * @notice Allows to compound Stake and move it to the next Staking Pool in Staking Tier.
     *
     * @dev Validations :
     * - Stake for given id must exists
     * - For the given Stake unstake process cannot be started (request unstake)
     * - Stake 'compoundPossibleAt' time must be from the past
     * - Next Staking Pool must exists
     *
     * Emits a 'StakeMovedToOtherStakingPool' and 'Compounded' events.
     *
     * @param stakeId Stake Id for which user want to unstake tokens
     */
    function compound(uint256 stakeId) external hasStake(msg.sender, stakeId) {
        Stake storage stake = userStake[msg.sender][stakeId];
        require(!stake.isWithdrawing, "Cannot during withdrawing");
        require(block.timestamp >= stake.compoundPossibleAt, "Compound possible after 'compoundPossibleAt' time");

        uint256 rewards = calculateRewards(
            stake.stakingTierId,
            stake.startTime,
            stake.rewardRate,
            block.timestamp
        );

        uint256 totalTokens = stake.stakedTokens + rewards;

        moveStakeToGivenStakingPool(stake, stake.stakingTierId, stake.stakingPoolId + 1, totalTokens);

        // Only calculated rewards are added to 'totalStaked'
        totalStaked += rewards;

        // Stake data is updated in the 'moveStakeToGivenStakingPool'. Therefore in order to pass the
        // correct old Staking Pool Id, the current Staking Pool Id from the Stake must be taken and
        // then it must by reduced by 1
        emit StakeMovedToOtherStakingPool(
            msg.sender,
            stakeId,
            stake.stakingPoolId - 1,
            stake.stakingPoolId,
            block.timestamp,
            stake.rewardRate,
            totalTokens
        );
        emit Compounded(msg.sender, totalTokens);
    }

    /**
     * @notice Allows to add rewards to the contract
     *
     * @dev Validations :
     * - Only reward distributor can perform can perform this function
     * - Amount of transfered tokens must be the same like amount passed to the function in 'amount'
     *
     * Emits a 'RewardsAdded' event
     *
     * @param amount Amount of reward tokens to transfer to the contract
     */
    function addRewards(uint256 amount) external onlyRewardsDistributor {
        require(transferFrom(msg.sender, amount) == amount, "Exclude reward distributor from fee");

        rewardsAdded += amount;
        emit RewardsAdded(amount);
    }

    /**
     * @dev Returns contract domain separator used in EIP-712 signing transactions
     *
     * @return Domain separator in 'bytes32' format
     */
    // solhint-disable-next-line func-name-mixedcase
    function DOMAIN_SEPARATOR() external view returns (bytes32) {
        return _domainSeparatorV4();
    }

    /**
     * @notice Allows to get array of ids for all user Stakes
     *
     * @return Array of ids
     */
    function getUserStakeIds(address user) external view returns (uint256[] memory) {
        return userStakeIds[user];
    }

    /**
     * @notice Allows to get all user Stakes with ids
     *
     * @return Two arrays are returned. First array contains all user Stake ids. Second array returns
     * all user Stakes. Values in both arrays are sorted, therefore each value in the first array
     * corresponds to the value in the second array at the same index.
     */
    function getAllStakesForUser(address user) external view returns (uint256[] memory, Stake[] memory) {
        uint256[] memory stakeIds = userStakeIds[user];

        Stake[] memory userStakes = new Stake[](stakeIds.length);

        for (uint256 i; i < stakeIds.length; i++) {
            userStakes[i] = userStake[user][stakeIds[i]];
        }

        return (stakeIds, userStakes);
    }

    /**
     * @notice Allows to get calculated amount of earned tokens for the given Stake.
     *
     * @return Returns earned tokens in 'uint256' format
     */
    function earned(
        address user,
        uint256 stakeId
    ) external hasStake(user, stakeId) view returns (uint256) {
        uint256 toTime = userStake[user][stakeId].isWithdrawing ? userStake[user][stakeId].requestUnstakeTime : block.timestamp;

        return calculateRewards(
            userStake[user][stakeId].stakingTierId,
            userStake[user][stakeId].startTime,
            userStake[user][stakeId].rewardRate,
            toTime);
    }

    /**
     * @dev Internal function to add stake. This function is used in 'addStake' and 'addPromoStake'.
     *
     * @param _stakingTierId Staking Tier Id
     * @param _stakingPoolId Staking Pool Id
     * @param _amount Amount of tokens which are added
     * @param isPromo Flag for promo stakes (used in 'addPromoStake')
     */
    function _addStake(
        uint256 _stakingTierId,
        uint256 _stakingPoolId,
        uint256 _amount,
        bool isPromo
    ) private {
        StakeType stakeType = stakingTiersStakeType[_stakingTierId];
        StakingPool storage stakingPool = stakingPoolsToTier[_stakingTierId][_stakingPoolId - 1];

        // Increase stake nonce using prefix operator
        uint256 stakeId = ++stakeNonce;

        Stake storage stake = userStake[msg.sender][stakeId];
        stake.stakingTierId = _stakingTierId;
        stake.stakingPoolId = _stakingPoolId;
        stake.stakeType = stakeType;
        stake.startTime = block.timestamp;
        stake.stakedTokens = _amount;
        stake.rewardRate = calculateRewardRate(_amount, stakingPool.apr);
        stake.exists = true;

        // For Multi Level Staking Tier
        if (stakeType == StakeType.MultiLevel) {
            stake.unstakePeriod = stakingPool.unstakePeriod;
            stake.unstakeFee = stakingPool.unstakeFee;

            if (_stakingPoolId != 1) {
                // For stake added as promo stake lock time isn't calculated
                uint256 calculatedLockTime = !isPromo ? calculateLockTime(_stakingTierId, _stakingPoolId) : 0;

                // For stake added as promo stake next compound is calculated exactly in the same way like for the first
                // Staking Pool in Staking Tier - without any additional lock time
                stake.compoundPossibleAt = !isPromo ? calculatedLockTime : block.timestamp + stakingPool.compoundPossiblePeriod;
                stake.lockTime = calculatedLockTime;
            } else {
                stake.compoundPossibleAt = block.timestamp + stakingPool.compoundPossiblePeriod;
            }
        // For Periodic Staking Tier
        } else {
            stake.lockTime = block.timestamp + stakingPool.periodicLockTime;
        }

        userStakeIds[msg.sender].push(stakeId);

        stakingPool.totalTokensStaked += _amount;
        totalStaked += _amount;

        emit StakeAdded(
            msg.sender,
            stakeId,
            _stakingTierId,
            _stakingPoolId,
            block.timestamp,
            stake.rewardRate,
            _amount
        );
    }

    /**
     * @dev Internal function to moving Stake between Pools. This functions is used
     * in 'collectReward' and 'compound' functions.
     *
     * @param stake Stake
     * @param stakingTierId Staking Tier Id
     * @param newStakingPoolId Id of the new Staking Pool to which Stake is moved
     * @param tokensAmount Amount of tokens which are move to the next Staking Pool
     */
    function moveStakeToGivenStakingPool(
        Stake storage stake,
        uint256 stakingTierId,
        uint256 newStakingPoolId,
        uint256 tokensAmount
    ) private doesStakingPoolExist(stakingTierId, newStakingPoolId) {
        StakingPool storage newStakingPool = stakingPoolsToTier[stakingTierId][newStakingPoolId - 1];

        StakingPool storage oldStakingPool = stakingPoolsToTier[stake.stakingTierId][stake.stakingPoolId - 1];
        oldStakingPool.totalTokensStaked -= stake.stakedTokens;

        stake.stakingPoolId = newStakingPoolId;
        stake.startTime = block.timestamp;
        stake.stakedTokens = tokensAmount;

        stake.rewardRate = calculateRewardRate(tokensAmount, newStakingPool.apr);

        // Setting specific data for Multi Level Stake
        if (stake.stakeType == StakeType.MultiLevel) {
            stake.compoundPossibleAt = block.timestamp + newStakingPool.compoundPossiblePeriod;

            if (newStakingPool.unstakePeriod > stake.unstakePeriod) {
                stake.unstakePeriod = newStakingPool.unstakePeriod;
            }

            if (newStakingPool.unstakeFee > stake.unstakeFee) {
                stake.unstakeFee = newStakingPool.unstakeFee;
            }
        // Setting specific data for Periodic Stake
        } else {
            stake.lockTime = block.timestamp + newStakingPool.periodicLockTime;
        }

        newStakingPool.totalTokensStaked += tokensAmount;
    }

    /**
     * @dev Internal function to unstake tokens. This function is used in 'unstake' and
     * 'unstakeWithFee' functions.
     *
     * @param stakeId Stake Id
     * @param withFee Fee control flag
     */
    function _unstake(
        uint256 stakeId,
        bool withFee
    ) private {
        Stake memory stake = userStake[msg.sender][stakeId];
        require(stake.isWithdrawing, "Request unstake first");

        uint256 totalTokens = stake.stakedTokens + calculateRewards(
            stake.stakingTierId,
            stake.startTime,
            stake.rewardRate,
            stake.requestUnstakeTime
        );

        uint256 tokens = withFee ? minusFee(totalTokens, stake.unstakeFee) : totalTokens;
        uint256 fee = withFee ? (totalTokens - tokens) : 0;

        delete userStake[msg.sender][stakeId];
        deleteFromUserStakeIds(msg.sender, stakeId);

        if (fee > 0) {
            transfer(feeCollector, fee);
        }

        transfer(msg.sender, tokens);

        emit StakeRemoved(msg.sender, stakeId, tokens);
    }

    /**
     * @dev Internal contract function used in modifiers to verify if Staking Tier exists.
     *
     * @param stakingTierId Staking Tier Id
     *
     * @return Returns bool value : True - exists, False - doesn't exist
     */
    function _doesStakingTierExist(uint256 stakingTierId) private view returns (bool) {
        return stakingTiers[stakingTierId];
    }

    /**
     * @dev Internal function that calculates rewards Stake.
     *
     * @param stakingTierId Staking Tier Id
     * @param startTime Stake start timestamp
     * @param rewardRate Stake reward rate
     * @param toTime Timestamp to which rewards must be calculated
     *
     * @return Returns calculated rewards
     */
    function calculateRewards(
        uint256 stakingTierId,
        uint256 startTime,
        uint256 rewardRate,
        uint256 toTime
    ) private view returns (uint256) {
        // If reward rate equal zero - avoid calculations
        if (rewardRate == 0) {
            return 0;
        }

        uint256 stakingTierRewardEndTime = stakingTiersRewardEndTime[stakingTierId];

        if (stakingTierRewardEndTime > 0) {
            toTime = mathMin(stakingTierRewardEndTime, toTime);
        }

        return toTime > startTime ? rewardRate * (toTime - startTime) : 0;
    }

    /**
     * @dev Internal function to calculate lock time. This functions is used in 'addStake' function.
     * It allows to sum and calculate 'compoundPossiblePeriod' for all Staking Pools in Tier below given
     * Staking Pool (including this Staking Pool for which the stake will be added).
     *
     * @param stakingTierId Staking Tier Id
     * @param stakingPoolId Staking Pool Id
     *
     * @return Returns calculated lock time
     */
    function calculateLockTime(uint256 stakingTierId, uint256 stakingPoolId) private view returns (uint256) {
        uint256 lockTime = block.timestamp;

        for(uint256 i; i < stakingPoolId; i++) {
            lockTime += stakingPoolsToTier[stakingTierId][i].compoundPossiblePeriod;
        }

        return lockTime;
    }

    /**
     * @dev Internal function that allows to remove Stake id from 'userStakeIds' state variable. This
     * function search array for the given user. When 'stakeId' value is found, last value from the array is
     * moved to the index where 'stakeId' was found and array length is decrease by 1.
     *
     * @param user User for which stake is deleted
     * @param stakeId Stake Id which will be deleted
     */
    function deleteFromUserStakeIds(address user, uint256 stakeId) private {
        uint256 arrLength = userStakeIds[user].length;

        if (arrLength > 1) {
            for (uint256 i; i < arrLength; i++) {
                if (userStakeIds[user][i] == stakeId) {
                    userStakeIds[user][i] = userStakeIds[user][arrLength - 1];
                    userStakeIds[user].pop();
                    break;
                }
            }
        } else {
            userStakeIds[user].pop();
        }
    }

    /**
     * @dev Internal function to calculate lower value from two given values
     */
    function mathMin(uint256 x, uint256 y) private pure returns (uint256) {
        return x > y ? y : x;
    }

    /**
     * @dev Internal function that allows to calculate amount of tokens after subtracting the fee
     *
     * @param val Tokens amount
     * @param unstakeFee Fee value
     *
     * @return Returns calculated tokens after subtracting the fee
     */
    function minusFee(uint256 val, uint256 unstakeFee) private pure returns (uint256) {
        return val - ((val * unstakeFee) / 10000);
    }

    /**
     * @dev Internal function that verifies APR and calculate reward rate for the given tokens amount
     * and APR, or set zero value if APR is equal zero.
     *
     * @param tokensAmount Tokens amount for which reward rate should be calculated
     * @param apr APR - Annual Percentage Rate
     *
     * @return Returns calculcated reward rate
     */
    function calculateRewardRate(uint256 tokensAmount, uint256 apr) private pure returns (uint256) {
        return apr > 0 ? tokensAmount * apr / YEAR / 10000 : 0;
    }

    /**
     * @dev Internal function that uses ERC-20 'transferFrom' function. This function is used during
     * 'addStake', 'addPromoStake' and 'addRewards' to transfer tokens to the staking contract from user or from
     * reward distributor.
     *
     * @param from Address from which tokens will be transfered
     * @param amount Amount of transfered tokens
     *
     * @return Returns amount of transfered tokens
     */
    function transferFrom(
        address from,
        uint256 amount
    ) private returns (uint256) {
        return IERC20(token).safeTransferFromDeluxe(from, amount);
    }

    /**
     * @dev Internal function to transfer tokens from staking contract to users. This function is used in
     * 'collectReward', 'unstake' and 'unstakeWithFee' functions.
     *
     * @param to Address to which tokens will be send
     * @param amount Amount of tokens which will be send
     */
    function transfer(
        address to,
        uint256 amount
    ) private {
        IERC20(token).safeTransfer(to, amount);
    }
}

// SPDX-License-Identifier: MIT

pragma solidity 0.8.10;

import { Ownable } from "../helpers/Ownable.sol";

abstract contract RewardsDistributionData {
    address public rewardsDistributor;
}

abstract contract RewardsDistribution is Ownable, RewardsDistributionData {
    event RewardsDistributorChanged(address indexed previousDistributor, address indexed newDistributor);

    /**
     * @dev `rewardsDistributor` defaults to msg.sender on construction.
     */
    constructor() {
        rewardsDistributor = msg.sender;
        emit RewardsDistributorChanged(address(0), msg.sender);
    }

    /**
     * @dev Throws if called by any account other than the Reward Distributor.
     */
    modifier onlyRewardsDistributor() {
        require(msg.sender == rewardsDistributor, "caller is not reward distributor");
        _;
    }

    /**
     * @dev Change the rewardsDistributor - only called by owner
     * @param newRewardsDistributor Address of the new distributor
     */
    function setRewardsDistribution(address newRewardsDistributor) external onlyOwner {
        require(newRewardsDistributor != address(0), "zero address");

        address oldRewardDistributor = rewardsDistributor;
        rewardsDistributor = newRewardsDistributor;

        emit RewardsDistributorChanged(oldRewardDistributor, newRewardsDistributor);
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/cryptography/draft-EIP712.sol)

pragma solidity ^0.8.0;

import "../libraries/ECDSA.sol";

/**
 * @dev https://eips.ethereum.org/EIPS/eip-712[EIP 712] is a standard for hashing and signing of typed structured data.
 *
 * The encoding specified in the EIP is very generic, and such a generic implementation in Solidity is not feasible,
 * thus this contract does not implement the encoding itself. Protocols need to implement the type-specific encoding
 * they need in their contracts using a combination of `abi.encode` and `keccak256`.
 *
 * This contract implements the EIP 712 domain separator ({_domainSeparatorV4}) that is used as part of the encoding
 * scheme, and the final step of the encoding to obtain the message digest that is then signed via ECDSA
 * ({_hashTypedDataV4}).
 *
 * The implementation of the domain separator was designed to be as efficient as possible while still properly updating
 * the chain id to protect against replay attacks on an eventual fork of the chain.
 *
 * NOTE: This contract implements the version of the encoding known as "v4", as implemented by the JSON RPC method
 * https://docs.metamask.io/guide/signing-data.html[`eth_signTypedDataV4` in MetaMask].
 *
 * _Available since v3.4._
 */
abstract contract EIP712 {
    /* solhint-disable var-name-mixedcase */
    // Cache the domain separator as an immutable value, but also store the chain id that it corresponds to, in order to
    // invalidate the cached domain separator if the chain id changes.
    bytes32 private immutable _CACHED_DOMAIN_SEPARATOR;
    uint256 private immutable _CACHED_CHAIN_ID;
    address private immutable _CACHED_THIS;

    bytes32 private immutable _HASHED_NAME;
    bytes32 private immutable _HASHED_VERSION;
    bytes32 private immutable _TYPE_HASH;

    /* solhint-enable var-name-mixedcase */

    /**
     * @dev Initializes the domain separator and parameter caches.
     *
     * The meaning of `name` and `version` is specified in
     * https://eips.ethereum.org/EIPS/eip-712#definition-of-domainseparator[EIP 712]:
     *
     * - `name`: the user readable name of the signing domain, i.e. the name of the DApp or the protocol.
     * - `version`: the current major version of the signing domain.
     *
     * NOTE: These parameters cannot be changed except through a xref:learn::upgrading-smart-contracts.adoc[smart
     * contract upgrade].
     */
    constructor(string memory name, string memory version) {
        bytes32 hashedName = keccak256(bytes(name));
        bytes32 hashedVersion = keccak256(bytes(version));
        bytes32 typeHash = keccak256(
            "EIP712Domain(string name,string version,uint256 chainId,address verifyingContract)"
        );
        _HASHED_NAME = hashedName;
        _HASHED_VERSION = hashedVersion;
        _CACHED_CHAIN_ID = block.chainid;
        _CACHED_DOMAIN_SEPARATOR = _buildDomainSeparator(typeHash, hashedName, hashedVersion);
        _CACHED_THIS = address(this);
        _TYPE_HASH = typeHash;
    }

    /**
     * @dev Returns the domain separator for the current chain.
     */
    function _domainSeparatorV4() internal view returns (bytes32) {
        if (address(this) == _CACHED_THIS && block.chainid == _CACHED_CHAIN_ID) {
            return _CACHED_DOMAIN_SEPARATOR;
        } else {
            return _buildDomainSeparator(_TYPE_HASH, _HASHED_NAME, _HASHED_VERSION);
        }
    }

    function _buildDomainSeparator(
        bytes32 typeHash,
        bytes32 nameHash,
        bytes32 versionHash
    ) private view returns (bytes32) {
        return keccak256(abi.encode(typeHash, nameHash, versionHash, block.chainid, address(this)));
    }

    /**
     * @dev Given an already https://eips.ethereum.org/EIPS/eip-712#definition-of-hashstruct[hashed struct], this
     * function returns the hash of the fully encoded EIP712 message for this domain.
     *
     * This hash can be used together with {ECDSA-recover} to obtain the signer of a message. For example:
     *
     * ```solidity
     * bytes32 digest = _hashTypedDataV4(keccak256(abi.encode(
     *     keccak256("Mail(address to,string contents)"),
     *     mailTo,
     *     keccak256(bytes(mailContents))
     * )));
     * address signer = ECDSA.recover(digest, signature);
     * ```
     */
    function _hashTypedDataV4(bytes32 structHash) internal view virtual returns (bytes32) {
        return ECDSA.toTypedDataHash(_domainSeparatorV4(), structHash);
    }
}

// SPDX-License-Identifier: MIT

pragma solidity 0.8.10;

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
     * by making the `nonReentrant` function external, and make it call a
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

// SPDX-License-Identifier: MIT

pragma solidity 0.8.10;

contract OwnableData {
    address public owner;
    address public pendingOwner;
}

contract Ownable is OwnableData {
    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    /**
     * @dev `owner` defaults to msg.sender on construction.
     */
    constructor() {
        _setOwner(msg.sender);
    }

    /**
     * @dev Transfers ownership to `newOwner`. Either directly or claimable by the new pending owner.
     *      Can only be invoked by the current `owner`.
     * @param _newOwner Address of the new owner.
     * @param _direct True if `_newOwner` should be set immediately. False if `_newOwner` needs to use `claimOwnership`.
     * @param _renounce Allows the `_newOwner` to be `address(0)` if `_direct` and `_renounce` is True. Has no effect otherwise
     */
    function transferOwnership(
        address _newOwner,
        bool _direct,
        bool _renounce
    ) external onlyOwner {
        if (_direct) {
            require(_newOwner != address(0) || _renounce, "zero address");

            emit OwnershipTransferred(owner, _newOwner);
            owner = _newOwner;
            pendingOwner = address(0);
        } else {
            pendingOwner = _newOwner;
        }
    }

    /**
     * @dev Needs to be called by `pendingOwner` to claim ownership.
     */
    function claimOwnership() external {
        address _pendingOwner = pendingOwner;
        require(msg.sender == _pendingOwner, "caller != pending owner");

        emit OwnershipTransferred(owner, _pendingOwner);
        owner = _pendingOwner;
        pendingOwner = address(0);
    }

    /**
     * @dev Throws if called by any account other than the Owner.
     */
    modifier onlyOwner() {
        require(msg.sender == owner, "caller is not the owner");
        _;
    }

    function _setOwner(address newOwner) internal {
        address oldOwner = owner;
        owner = newOwner;
        emit OwnershipTransferred(oldOwner, newOwner);
    }
}

// SPDX-License-Identifier: MIT

pragma solidity 0.8.10;

interface IERC20 {
    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed owner, address indexed spender, uint256 value);

    function totalSupply() external view returns (uint256);

    function decimals() external view returns (uint8);

    function balanceOf(address account) external view returns (uint256);

    function allowance(address owner, address spender) external view returns (uint256);

    function approve(address spender, uint256 amount) external returns (bool);

    function transfer(address to, uint256 value) external returns (bool);

    function transferFrom(
        address from,
        address to,
        uint256 value
    ) external returns (bool);

    function burn(uint256 amount) external returns (bool);

    function burnFrom(address account, uint256 amount) external returns (bool);

    // EIP 2612
    // solhint-disable-next-line func-name-mixedcase
    function DOMAIN_SEPARATOR() external view returns (bytes32);

    function nonces(address owner) external view returns (uint256);

    function permit(
        address owner,
        address spender,
        uint256 value,
        uint256 deadline,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) external;
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "./Strings.sol";

/**
 * @dev Elliptic Curve Digital Signature Algorithm (ECDSA) operations.
 *
 * These functions can be used to verify that a message was signed by the holder
 * of the private keys of a given address.
 */
library ECDSA {
    enum RecoverError {
        NoError,
        InvalidSignature,
        InvalidSignatureLength,
        InvalidSignatureS,
        InvalidSignatureV
    }

    function _throwError(RecoverError error) private pure {
        if (error == RecoverError.NoError) {
            return; // no error: do nothing
        } else if (error == RecoverError.InvalidSignature) {
            revert("ECDSA: invalid signature");
        } else if (error == RecoverError.InvalidSignatureLength) {
            revert("ECDSA: invalid signature length");
        } else if (error == RecoverError.InvalidSignatureS) {
            revert("ECDSA: invalid signature 's' value");
        } else if (error == RecoverError.InvalidSignatureV) {
            revert("ECDSA: invalid signature 'v' value");
        }
    }

    /**
     * @dev Returns the address that signed a hashed message (`hash`) with
     * `signature` or error string. This address can then be used for verification purposes.
     *
     * The `ecrecover` EVM opcode allows for malleable (non-unique) signatures:
     * this function rejects them by requiring the `s` value to be in the lower
     * half order, and the `v` value to be either 27 or 28.
     *
     * IMPORTANT: `hash` _must_ be the result of a hash operation for the
     * verification to be secure: it is possible to craft signatures that
     * recover to arbitrary addresses for non-hashed data. A safe way to ensure
     * this is by receiving a hash of the original message (which may otherwise
     * be too long), and then calling {toEthSignedMessageHash} on it.
     *
     * Documentation for signature generation:
     * - with https://web3js.readthedocs.io/en/v1.3.4/web3-eth-accounts.html#sign[Web3.js]
     * - with https://docs.ethers.io/v5/api/signer/#Signer-signMessage[ethers]
     *
     * _Available since v4.3._
     */
    function tryRecover(bytes32 hash, bytes memory signature) internal pure returns (address, RecoverError) {
        // Check the signature length
        // - case 65: r,s,v signature (standard)
        // - case 64: r,vs signature (cf https://eips.ethereum.org/EIPS/eip-2098) _Available since v4.1._
        if (signature.length == 65) {
            bytes32 r;
            bytes32 s;
            uint8 v;
            // ecrecover takes the signature parameters, and the only way to get them
            // currently is to use assembly.
            assembly {
                r := mload(add(signature, 0x20))
                s := mload(add(signature, 0x40))
                v := byte(0, mload(add(signature, 0x60)))
            }
            return tryRecover(hash, v, r, s);
        } else if (signature.length == 64) {
            bytes32 r;
            bytes32 vs;
            // ecrecover takes the signature parameters, and the only way to get them
            // currently is to use assembly.
            assembly {
                r := mload(add(signature, 0x20))
                vs := mload(add(signature, 0x40))
            }
            return tryRecover(hash, r, vs);
        } else {
            return (address(0), RecoverError.InvalidSignatureLength);
        }
    }

    /**
     * @dev Returns the address that signed a hashed message (`hash`) with
     * `signature`. This address can then be used for verification purposes.
     *
     * The `ecrecover` EVM opcode allows for malleable (non-unique) signatures:
     * this function rejects them by requiring the `s` value to be in the lower
     * half order, and the `v` value to be either 27 or 28.
     *
     * IMPORTANT: `hash` _must_ be the result of a hash operation for the
     * verification to be secure: it is possible to craft signatures that
     * recover to arbitrary addresses for non-hashed data. A safe way to ensure
     * this is by receiving a hash of the original message (which may otherwise
     * be too long), and then calling {toEthSignedMessageHash} on it.
     */
    function recover(bytes32 hash, bytes memory signature) internal pure returns (address) {
        (address recovered, RecoverError error) = tryRecover(hash, signature);
        _throwError(error);
        return recovered;
    }

    /**
     * @dev Overload of {ECDSA-tryRecover} that receives the `r` and `vs` short-signature fields separately.
     *
     * See https://eips.ethereum.org/EIPS/eip-2098[EIP-2098 short signatures]
     *
     * _Available since v4.3._
     */
    function tryRecover(
        bytes32 hash,
        bytes32 r,
        bytes32 vs
    ) internal pure returns (address, RecoverError) {
        bytes32 s = vs & bytes32(0x7fffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff);
        uint8 v = uint8((uint256(vs) >> 255) + 27);
        return tryRecover(hash, v, r, s);
    }

    /**
     * @dev Overload of {ECDSA-recover} that receives the `r and `vs` short-signature fields separately.
     *
     * _Available since v4.2._
     */
    function recover(
        bytes32 hash,
        bytes32 r,
        bytes32 vs
    ) internal pure returns (address) {
        (address recovered, RecoverError error) = tryRecover(hash, r, vs);
        _throwError(error);
        return recovered;
    }

    /**
     * @dev Overload of {ECDSA-tryRecover} that receives the `v`,
     * `r` and `s` signature fields separately.
     *
     * _Available since v4.3._
     */
    function tryRecover(
        bytes32 hash,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) internal pure returns (address, RecoverError) {
        // EIP-2 still allows signature malleability for ecrecover(). Remove this possibility and make the signature
        // unique. Appendix F in the Ethereum Yellow paper (https://ethereum.github.io/yellowpaper/paper.pdf), defines
        // the valid range for s in (301): 0 < s < secp256k1n ÷ 2 + 1, and for v in (302): v ∈ {27, 28}. Most
        // signatures from current libraries generate a unique signature with an s-value in the lower half order.
        //
        // If your library generates malleable signatures, such as s-values in the upper range, calculate a new s-value
        // with 0xFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFEBAAEDCE6AF48A03BBFD25E8CD0364141 - s1 and flip v from 27 to 28 or
        // vice versa. If your library also generates signatures with 0/1 for v instead 27/28, add 27 to v to accept
        // these malleable signatures as well.
        if (uint256(s) > 0x7FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF5D576E7357A4501DDFE92F46681B20A0) {
            return (address(0), RecoverError.InvalidSignatureS);
        }
        if (v != 27 && v != 28) {
            return (address(0), RecoverError.InvalidSignatureV);
        }

        // If the signature is valid (and not malleable), return the signer address
        address signer = ecrecover(hash, v, r, s);
        if (signer == address(0)) {
            return (address(0), RecoverError.InvalidSignature);
        }

        return (signer, RecoverError.NoError);
    }

    /**
     * @dev Overload of {ECDSA-recover} that receives the `v`,
     * `r` and `s` signature fields separately.
     */
    function recover(
        bytes32 hash,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) internal pure returns (address) {
        (address recovered, RecoverError error) = tryRecover(hash, v, r, s);
        _throwError(error);
        return recovered;
    }

    /**
     * @dev Returns an Ethereum Signed Message, created from a `hash`. This
     * produces hash corresponding to the one signed with the
     * https://eth.wiki/json-rpc/API#eth_sign[`eth_sign`]
     * JSON-RPC method as part of EIP-191.
     *
     * See {recover}.
     */
    function toEthSignedMessageHash(bytes32 hash) internal pure returns (bytes32) {
        // 32 is the length in bytes of hash,
        // enforced by the type signature above
        return keccak256(abi.encodePacked("\x19Ethereum Signed Message:\n32", hash));
    }

    /**
     * @dev Returns an Ethereum Signed Message, created from `s`. This
     * produces hash corresponding to the one signed with the
     * https://eth.wiki/json-rpc/API#eth_sign[`eth_sign`]
     * JSON-RPC method as part of EIP-191.
     *
     * See {recover}.
     */
    function toEthSignedMessageHash(bytes memory s) internal pure returns (bytes32) {
        return keccak256(abi.encodePacked("\x19Ethereum Signed Message:\n", Strings.toString(s.length), s));
    }

    /**
     * @dev Returns an Ethereum Signed Typed Data, created from a
     * `domainSeparator` and a `structHash`. This produces hash corresponding
     * to the one signed with the
     * https://eips.ethereum.org/EIPS/eip-712[`eth_signTypedData`]
     * JSON-RPC method as part of EIP-712.
     *
     * See {recover}.
     */
    function toTypedDataHash(bytes32 domainSeparator, bytes32 structHash) internal pure returns (bytes32) {
        return keccak256(abi.encodePacked("\x19\x01", domainSeparator, structHash));
    }
}

// SPDX-License-Identifier: MIT

pragma solidity 0.8.10;

import { IERC20 } from "../interfaces/IERC20.sol";

library SafeERC20 {
    function safeSymbol(IERC20 token) internal view returns (string memory) {
        (bool success, bytes memory data) = address(token).staticcall(abi.encodeWithSelector(0x95d89b41));
        return success && data.length > 0 ? abi.decode(data, (string)) : "???";
    }

    function safeName(IERC20 token) internal view returns (string memory) {
        (bool success, bytes memory data) = address(token).staticcall(abi.encodeWithSelector(0x06fdde03));
        return success && data.length > 0 ? abi.decode(data, (string)) : "???";
    }

    function safeDecimals(IERC20 token) internal view returns (uint8) {
        (bool success, bytes memory data) = address(token).staticcall(abi.encodeWithSelector(0x313ce567));
        return success && data.length == 32 ? abi.decode(data, (uint8)) : 18;
    }

    function safeTransfer(
        IERC20 token,
        address to,
        uint256 amount
    ) internal {
        // solhint-disable-next-line avoid-low-level-calls
        (bool success, bytes memory data) = address(token).call(abi.encodeWithSelector(0xa9059cbb, to, amount));
        require(success && (data.length == 0 || abi.decode(data, (bool))), "SafeERC20: Transfer failed");
    }

    function safeTransferFrom(
        IERC20 token,
        address from,
        uint256 amount
    ) internal {
        // solhint-disable-next-line avoid-low-level-calls
        (bool success, bytes memory data) = address(token).call(abi.encodeWithSelector(0x23b872dd, from, address(this), amount));
        require(success && (data.length == 0 || abi.decode(data, (bool))), "SafeERC20: TransferFrom failed");
    }

    function safeTransferFromDeluxe(
        IERC20 token,
        address from,
        uint256 amount
    ) internal returns (uint256) {
        uint256 preBalance = token.balanceOf(address(this));
        safeTransferFrom(token, from, amount);
        uint256 postBalance = token.balanceOf(address(this));
        return postBalance - preBalance;
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/**
 * @dev String operations.
 */
library Strings {
    bytes16 private constant _HEX_SYMBOLS = "0123456789abcdef";

    /**
     * @dev Converts a `uint256` to its ASCII `string` decimal representation.
     */
    function toString(uint256 value) internal pure returns (string memory) {
        // Inspired by OraclizeAPI's implementation - MIT licence
        // https://github.com/oraclize/ethereum-api/blob/b42146b063c7d6ee1358846c198246239e9360e8/oraclizeAPI_0.4.25.sol

        if (value == 0) {
            return "0";
        }
        uint256 temp = value;
        uint256 digits;
        while (temp != 0) {
            digits++;
            temp /= 10;
        }
        bytes memory buffer = new bytes(digits);
        while (value != 0) {
            digits -= 1;
            buffer[digits] = bytes1(uint8(48 + uint256(value % 10)));
            value /= 10;
        }
        return string(buffer);
    }

    /**
     * @dev Converts a `uint256` to its ASCII `string` hexadecimal representation.
     */
    function toHexString(uint256 value) internal pure returns (string memory) {
        if (value == 0) {
            return "0x00";
        }
        uint256 temp = value;
        uint256 length = 0;
        while (temp != 0) {
            length++;
            temp >>= 8;
        }
        return toHexString(value, length);
    }

    /**
     * @dev Converts a `uint256` to its ASCII `string` hexadecimal representation with fixed length.
     */
    function toHexString(uint256 value, uint256 length) internal pure returns (string memory) {
        bytes memory buffer = new bytes(2 * length + 2);
        buffer[0] = "0";
        buffer[1] = "x";
        for (uint256 i = 2 * length + 1; i > 1; --i) {
            buffer[i] = _HEX_SYMBOLS[value & 0xf];
            value >>= 4;
        }
        require(value == 0, "Strings: hex length insufficient");
        return string(buffer);
    }
}