// SPDX-License-Identifier: MIT
pragma solidity ^0.8.10;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "./libraries/SafeCast.sol";
import "./interfaces/INonfungiblePositionManager.sol";
import "./interfaces/INonfungiblePositionManagerStruct.sol";
import "./interfaces/IPancakeV3Pool.sol";
import "./interfaces/IMasterChefV2.sol";
import "./interfaces/ILMPool.sol";
import "./interfaces/ILMPoolDeployer.sol";
import "./interfaces/IFarmBooster.sol";
import "./interfaces/IWETH.sol";
import "./utils/Multicall.sol";
import "./Enumerable.sol";

contract MasterChefV3 is INonfungiblePositionManagerStruct, Multicall, Ownable, ReentrancyGuard, Enumerable {
    using SafeERC20 for IERC20;
    using SafeCast for uint256;
    struct PoolInfo {
        uint256 allocPoint;
        // V3 pool address
        IPancakeV3Pool v3Pool;
        // V3 pool token0 address
        address token0;
        // V3 pool token1 address
        address token1;
        // V3 pool fee
        uint24 fee;
        // total liquidity staking in the pool
        uint256 totalLiquidity;
        // total boost liquidity staking in the pool
        uint256 totalBoostLiquidity;
    }

    struct UserPositionInfo {
        uint128 liquidity;
        uint128 boostLiquidity;
        int24 tickLower;
        int24 tickUpper;
        uint256 rewardGrowthInside;
        uint256 reward;
        address user;
        uint256 pid;
        uint256 boostMultiplier;
    }

    uint256 public poolLength;
    /// @notice Info of each MCV3 pool.
    mapping(uint256 => PoolInfo) public poolInfo;

    /// @notice userPositionInfos[tokenId] => UserPositionInfo
    /// @dev TokenId is unique, and we can query the pid by tokenId.
    mapping(uint256 => UserPositionInfo) public userPositionInfos;

    /// @notice v3PoolPid[token0][token1][fee] => pid
    mapping(address => mapping(address => mapping(uint24 => uint256))) v3PoolPid;
    /// @notice v3PoolAddressPid[v3PoolAddress] => pid
    mapping(address => uint256) public v3PoolAddressPid;

    /// @notice Address of CAKE contract.
    IERC20 public immutable CAKE;

    /// @notice Address of WETH contract.
    address public immutable WETH;

    /// @notice Address of Receiver contract.
    address public receiver;

    INonfungiblePositionManager public immutable nonfungiblePositionManager;

    /// @notice Address of liquidity mining pool deployer contract.
    ILMPoolDeployer public LMPoolDeployer;

    /// @notice Address of farm booster contract.
    IFarmBooster public FARM_BOOSTER;

    /// @notice Only use for emergency situations.
    bool public emergency;

    /// @notice Total allocation points. Must be the sum of all pools' allocation points.
    uint256 public totalAllocPoint;

    uint256 public latestPeriodNumber;
    uint256 public latestPeriodStartTime;
    uint256 public latestPeriodEndTime;
    uint256 public latestPeriodCakePerSecond;

    /// @notice Address of the operator.
    address public operatorAddress;
    /// @notice Default period duration.
    uint256 public PERIOD_DURATION = 1 days;
    uint256 public constant MAX_DURATION = 30 days;
    uint256 public constant MIN_DURATION = 1 days;
    uint256 public constant PRECISION = 1e12;
    /// @notice Basic boost factor, none boosted user's boost factor
    uint256 public constant BOOST_PRECISION = 100 * 1e10;
    /// @notice Hard limit for maxmium boost factor, it must greater than BOOST_PRECISION
    uint256 public constant MAX_BOOST_PRECISION = 200 * 1e10;
    uint256 constant Q128 = 0x100000000000000000000000000000000;
    uint256 constant MAX_U256 = type(uint256).max;

    /// @notice Record the cake amount belong to MasterChefV3.
    uint256 public cakeAmountBelongToMC;

    error ZeroAddress();
    error NotOwnerOrOperator();
    error NoBalance();
    error NotPancakeNFT();
    error InvalidNFT();
    error NotOwner();
    error NoLiquidity();
    error InvalidPeriodDuration();
    error NoLMPool();
    error InvalidPid();
    error DuplicatedPool(uint256 pid);
    error NotEmpty();
    error WrongReceiver();
    error InconsistentAmount();
    error InsufficientAmount();

    event AddPool(uint256 indexed pid, uint256 allocPoint, IPancakeV3Pool indexed v3Pool, ILMPool indexed lmPool);
    event SetPool(uint256 indexed pid, uint256 allocPoint);
    event Deposit(
        address indexed from,
        uint256 indexed pid,
        uint256 indexed tokenId,
        uint256 liquidity,
        int24 tickLower,
        int24 tickUpper
    );
    event Withdraw(address indexed from, address to, uint256 indexed pid, uint256 indexed tokenId);
    event UpdateLiquidity(
        address indexed from,
        uint256 indexed pid,
        uint256 indexed tokenId,
        int128 liquidity,
        int24 tickLower,
        int24 tickUpper
    );
    event NewOperatorAddress(address operator);
    event NewLMPoolDeployerAddress(address deployer);
    event NewReceiver(address receiver);
    event NewPeriodDuration(uint256 periodDuration);
    event Harvest(address indexed sender, address to, uint256 indexed pid, uint256 indexed tokenId, uint256 reward);
    event NewUpkeepPeriod(
        uint256 indexed periodNumber,
        uint256 startTime,
        uint256 endTime,
        uint256 cakePerSecond,
        uint256 cakeAmount
    );
    event UpdateUpkeepPeriod(
        uint256 indexed periodNumber,
        uint256 oldEndTime,
        uint256 newEndTime,
        uint256 remainingCake
    );
    event UpdateFarmBoostContract(address indexed farmBoostContract);
    event SetEmergency(bool emergency);

    modifier onlyOwnerOrOperator() {
        if (msg.sender != operatorAddress && msg.sender != owner()) revert NotOwnerOrOperator();
        _;
    }

    modifier onlyValidPid(uint256 _pid) {
        if (_pid == 0 || _pid > poolLength) revert InvalidPid();
        _;
    }

    modifier onlyReceiver() {
        require(receiver == msg.sender, "Not receiver");
        _;
    }

    /**
     * @dev Throws if caller is not the boost contract.
     */
    modifier onlyBoostContract() {
        require(address(FARM_BOOSTER) == msg.sender, "Not farm boost contract");
        _;
    }

    /// @param _CAKE The CAKE token contract address.
    /// @param _nonfungiblePositionManager the NFT position manager contract address.
    constructor(IERC20 _CAKE, INonfungiblePositionManager _nonfungiblePositionManager, address _WETH) {
        CAKE = _CAKE;
        nonfungiblePositionManager = _nonfungiblePositionManager;
        WETH = _WETH;
    }

    /// @notice Returns the cake per second , period end time.
    /// @param _pid The pool pid.
    /// @return cakePerSecond Cake reward per second.
    /// @return endTime Period end time.
    function getLatestPeriodInfoByPid(uint256 _pid) public view returns (uint256 cakePerSecond, uint256 endTime) {
        if (totalAllocPoint > 0) {
            cakePerSecond = (latestPeriodCakePerSecond * poolInfo[_pid].allocPoint) / totalAllocPoint;
        }
        endTime = latestPeriodEndTime;
    }

    /// @notice Returns the cake per second , period end time. This is for liquidity mining pool.
    /// @param _v3Pool Address of the V3 pool.
    /// @return cakePerSecond Cake reward per second.
    /// @return endTime Period end time.
    function getLatestPeriodInfo(address _v3Pool) public view returns (uint256 cakePerSecond, uint256 endTime) {
        if (totalAllocPoint > 0) {
            cakePerSecond =
                (latestPeriodCakePerSecond * poolInfo[v3PoolAddressPid[_v3Pool]].allocPoint) /
                totalAllocPoint;
        }
        endTime = latestPeriodEndTime;
    }

    /// @notice View function for checking pending CAKE rewards.
    /// @dev The pending cake amount is based on the last state in LMPool. The actual amount will happen whenever liquidity changes or harvest.
    /// @param _tokenId Token Id of NFT.
    /// @return reward Pending reward.
    function pendingCake(uint256 _tokenId) external view returns (uint256 reward) {
        UserPositionInfo memory positionInfo = userPositionInfos[_tokenId];
        if (positionInfo.pid != 0) {
            PoolInfo memory pool = poolInfo[positionInfo.pid];
            ILMPool LMPool = ILMPool(pool.v3Pool.lmPool());
            if (address(LMPool) != address(0)) {
                uint256 rewardGrowthInside = LMPool.getRewardGrowthInside(
                    positionInfo.tickLower,
                    positionInfo.tickUpper
                );
                if (
                    rewardGrowthInside > positionInfo.rewardGrowthInside &&
                    MAX_U256 / (rewardGrowthInside - positionInfo.rewardGrowthInside) > positionInfo.boostLiquidity
                )
                    reward =
                        ((rewardGrowthInside - positionInfo.rewardGrowthInside) * positionInfo.boostLiquidity) /
                        Q128;
            }
            reward += positionInfo.reward;
        }
    }

    /// @notice For emergency use only.
    function setEmergency(bool _emergency) external onlyOwner {
        emergency = _emergency;
        emit SetEmergency(emergency);
    }

    function setReceiver(address _receiver) external onlyOwner {
        if (_receiver == address(0)) revert ZeroAddress();
        if (CAKE.allowance(_receiver, address(this)) != type(uint256).max) revert();
        receiver = _receiver;
        emit NewReceiver(_receiver);
    }

    function setLMPoolDeployer(ILMPoolDeployer _LMPoolDeployer) external onlyOwner {
        if (address(_LMPoolDeployer) == address(0)) revert ZeroAddress();
        LMPoolDeployer = _LMPoolDeployer;
        emit NewLMPoolDeployerAddress(address(_LMPoolDeployer));
    }

    /// @notice Add a new pool. Can only be called by the owner.
    /// @notice One v3 pool can only create one pool.
    /// @param _allocPoint Number of allocation points for the new pool.
    /// @param _v3Pool Address of the V3 pool.
    /// @param _withUpdate Whether call "massUpdatePools" operation.
    function add(uint256 _allocPoint, IPancakeV3Pool _v3Pool, bool _withUpdate) external onlyOwner {
        if (_withUpdate) massUpdatePools();

        // ILMPool lmPool = LMPoolDeployer.deploy(_v3Pool);

        totalAllocPoint += _allocPoint;
        address token0 = _v3Pool.token0();
        address token1 = _v3Pool.token1();
        uint24 fee = _v3Pool.fee();
        if (v3PoolPid[token0][token1][fee] != 0) revert DuplicatedPool(v3PoolPid[token0][token1][fee]);
        if (IERC20(token0).allowance(address(this), address(nonfungiblePositionManager)) == 0)
            IERC20(token0).safeApprove(address(nonfungiblePositionManager), type(uint256).max);
        if (IERC20(token1).allowance(address(this), address(nonfungiblePositionManager)) == 0)
            IERC20(token1).safeApprove(address(nonfungiblePositionManager), type(uint256).max);
        unchecked {
            poolLength++;
        }
        poolInfo[poolLength] = PoolInfo({
            allocPoint: _allocPoint,
            v3Pool: _v3Pool,
            token0: token0,
            token1: token1,
            fee: fee,
            totalLiquidity: 0,
            totalBoostLiquidity: 0
        });

        v3PoolPid[token0][token1][fee] = poolLength;
        v3PoolAddressPid[address(_v3Pool)] = poolLength;
        // emit AddPool(poolLength, _allocPoint, _v3Pool, lmPool);
    }

    /// @notice Update the given pool's CAKE allocation point. Can only be called by the owner.
    /// @param _pid The id of the pool. See `poolInfo`.
    /// @param _allocPoint New number of allocation points for the pool.
    /// @param _withUpdate Whether call "massUpdatePools" operation.
    function set(uint256 _pid, uint256 _allocPoint, bool _withUpdate) external onlyOwner onlyValidPid(_pid) {
        uint32 currentTime = uint32(block.timestamp);
        PoolInfo storage pool = poolInfo[_pid];
        ILMPool LMPool = ILMPool(pool.v3Pool.lmPool());
        if (address(LMPool) != address(0)) {
            LMPool.accumulateReward(currentTime);
        }

        if (_withUpdate) massUpdatePools();
        totalAllocPoint = totalAllocPoint - pool.allocPoint + _allocPoint;
        pool.allocPoint = _allocPoint;
        emit SetPool(_pid, _allocPoint);
    }

    struct DepositCache {
        address token0;
        address token1;
        uint24 fee;
        int24 tickLower;
        int24 tickUpper;
        uint128 liquidity;
    }

    /// @notice Upon receiving a ERC721
    function onERC721Received(
        address,
        address _from,
        uint256 _tokenId,
        bytes calldata
    ) external nonReentrant returns (bytes4) {
        if (msg.sender != address(nonfungiblePositionManager)) revert NotPancakeNFT();
        DepositCache memory cache;
        (
            ,
            ,
            cache.token0,
            cache.token1,
            cache.fee,
            cache.tickLower,
            cache.tickUpper,
            cache.liquidity,
            ,
            ,
            ,

        ) = nonfungiblePositionManager.positions(_tokenId);
        if (cache.liquidity == 0) revert NoLiquidity();
        uint256 pid = v3PoolPid[cache.token0][cache.token1][cache.fee];
        if (pid == 0) revert InvalidNFT();
        PoolInfo memory pool = poolInfo[pid];
        ILMPool LMPool = ILMPool(pool.v3Pool.lmPool());
        if (address(LMPool) == address(0)) revert NoLMPool();

        UserPositionInfo storage positionInfo = userPositionInfos[_tokenId];

        positionInfo.tickLower = cache.tickLower;
        positionInfo.tickUpper = cache.tickUpper;
        positionInfo.user = _from;
        positionInfo.pid = pid;
        // Need to update LMPool.
        LMPool.accumulateReward(uint32(block.timestamp));
        updateLiquidityOperation(positionInfo, _tokenId, 0);

        positionInfo.rewardGrowthInside = LMPool.getRewardGrowthInside(cache.tickLower, cache.tickUpper);

        // Update Enumerable
        addToken(_from, _tokenId);
        emit Deposit(_from, pid, _tokenId, cache.liquidity, cache.tickLower, cache.tickUpper);

        return this.onERC721Received.selector;
    }

    /// @notice harvest cake from pool.
    /// @param _tokenId Token Id of NFT.
    /// @param _to Address to.
    /// @return reward Cake reward.
    function harvest(uint256 _tokenId, address _to) external nonReentrant returns (uint256 reward) {
        UserPositionInfo storage positionInfo = userPositionInfos[_tokenId];
        if (positionInfo.user != msg.sender) revert NotOwner();
        if (positionInfo.liquidity == 0 && positionInfo.reward == 0) revert NoLiquidity();
        reward = harvestOperation(positionInfo, _tokenId, _to);
    }

    function harvestOperation(
        UserPositionInfo storage positionInfo,
        uint256 _tokenId,
        address _to
    ) internal returns (uint256 reward) {
        PoolInfo memory pool = poolInfo[positionInfo.pid];
        ILMPool LMPool = ILMPool(pool.v3Pool.lmPool());
        if (address(LMPool) != address(0) && !emergency) {
            // Update rewardGrowthInside
            LMPool.accumulateReward(uint32(block.timestamp));
            uint256 rewardGrowthInside = LMPool.getRewardGrowthInside(positionInfo.tickLower, positionInfo.tickUpper);
            // Check overflow
            if (
                rewardGrowthInside > positionInfo.rewardGrowthInside &&
                MAX_U256 / (rewardGrowthInside - positionInfo.rewardGrowthInside) > positionInfo.boostLiquidity
            ) reward = ((rewardGrowthInside - positionInfo.rewardGrowthInside) * positionInfo.boostLiquidity) / Q128;
            positionInfo.rewardGrowthInside = rewardGrowthInside;
        }
        reward += positionInfo.reward;

        if (reward > 0) {
            if (_to != address(0)) {
                positionInfo.reward = 0;
                _safeTransfer(_to, reward);
                emit Harvest(msg.sender, _to, positionInfo.pid, _tokenId, reward);
            } else {
                positionInfo.reward = reward;
            }
        }
    }

    /// @notice Withdraw LP tokens from pool.
    /// @param _tokenId Token Id of NFT to deposit.
    /// @param _to Address to which NFT token to withdraw.
    /// @return reward Cake reward.
    function withdraw(uint256 _tokenId, address _to) external nonReentrant returns (uint256 reward) {
        if (_to == address(this) || _to == address(0)) revert WrongReceiver();
        UserPositionInfo storage positionInfo = userPositionInfos[_tokenId];
        if (positionInfo.user != msg.sender) revert NotOwner();
        reward = harvestOperation(positionInfo, _tokenId, _to);
        uint256 pid = positionInfo.pid;
        PoolInfo storage pool = poolInfo[pid];
        ILMPool LMPool = ILMPool(pool.v3Pool.lmPool());
        if (address(LMPool) != address(0) && !emergency) {
            // Remove all liquidity from liquidity mining pool.
            int128 liquidityDelta = -int128(positionInfo.boostLiquidity);
            LMPool.updatePosition(positionInfo.tickLower, positionInfo.tickUpper, liquidityDelta);
            emit UpdateLiquidity(
                msg.sender,
                pid,
                _tokenId,
                liquidityDelta,
                positionInfo.tickLower,
                positionInfo.tickUpper
            );
        }
        pool.totalLiquidity -= positionInfo.liquidity;
        pool.totalBoostLiquidity -= positionInfo.boostLiquidity;

        delete userPositionInfos[_tokenId];
        // Update Enumerable
        removeToken(msg.sender, _tokenId);
        // Remove boosted token id in farm booster.
        if (address(FARM_BOOSTER) != address(0)) FARM_BOOSTER.removeBoostMultiplier(msg.sender, _tokenId, pid);
        nonfungiblePositionManager.safeTransferFrom(address(this), _to, _tokenId);
        emit Withdraw(msg.sender, _to, pid, _tokenId);
    }

    /// @notice Update liquidity for the NFT position.
    /// @param _tokenId Token Id of NFT to update.
    function updateLiquidity(uint256 _tokenId) external nonReentrant {
        UserPositionInfo storage positionInfo = userPositionInfos[_tokenId];
        if (positionInfo.pid == 0) revert InvalidNFT();
        harvestOperation(positionInfo, _tokenId, address(0));
        updateLiquidityOperation(positionInfo, _tokenId, 0);
    }

    /// @notice Update farm boost multiplier for the NFT position.
    /// @param _tokenId Token Id of NFT to update.
    /// @param _newMultiplier New boost multiplier.
    function updateBoostMultiplier(uint256 _tokenId, uint256 _newMultiplier) external onlyBoostContract {
        UserPositionInfo storage positionInfo = userPositionInfos[_tokenId];
        if (positionInfo.pid == 0) revert InvalidNFT();
        harvestOperation(positionInfo, _tokenId, address(0));
        updateLiquidityOperation(positionInfo, _tokenId, _newMultiplier);
    }

    function updateLiquidityOperation(
        UserPositionInfo storage positionInfo,
        uint256 _tokenId,
        uint256 _newMultiplier
    ) internal {
        (, , , , , int24 tickLower, int24 tickUpper, uint128 liquidity, , , , ) = nonfungiblePositionManager.positions(
            _tokenId
        );
        PoolInfo storage pool = poolInfo[positionInfo.pid];
        if (positionInfo.liquidity != liquidity) {
            pool.totalLiquidity = pool.totalLiquidity - positionInfo.liquidity + liquidity;
            positionInfo.liquidity = liquidity;
        }
        uint256 boostMultiplier = BOOST_PRECISION;
        if (address(FARM_BOOSTER) != address(0) && _newMultiplier == 0) {
            // Get the latest boostMultiplier and update boostMultiplier in farm booster.
            boostMultiplier = FARM_BOOSTER.updatePositionBoostMultiplier(_tokenId);
        } else if (_newMultiplier != 0) {
            // Update boostMultiplier from farm booster call.
            boostMultiplier = _newMultiplier;
        }

        if (boostMultiplier < BOOST_PRECISION) {
            boostMultiplier = BOOST_PRECISION;
        } else if (boostMultiplier > MAX_BOOST_PRECISION) {
            boostMultiplier = MAX_BOOST_PRECISION;
        }

        positionInfo.boostMultiplier = boostMultiplier;
        uint128 boostLiquidity = ((uint256(liquidity) * boostMultiplier) / BOOST_PRECISION).toUint128();
        int128 liquidityDelta = int128(boostLiquidity) - int128(positionInfo.boostLiquidity);
        if (liquidityDelta != 0) {
            pool.totalBoostLiquidity = pool.totalBoostLiquidity - positionInfo.boostLiquidity + boostLiquidity;
            positionInfo.boostLiquidity = boostLiquidity;
            ILMPool LMPool = ILMPool(pool.v3Pool.lmPool());
            if (address(LMPool) == address(0)) revert NoLMPool();
            LMPool.updatePosition(tickLower, tickUpper, liquidityDelta);
            emit UpdateLiquidity(msg.sender, positionInfo.pid, _tokenId, liquidityDelta, tickLower, tickUpper);
        }
    }

    /// @notice Increases the amount of liquidity in a position, with tokens paid by the `msg.sender`
    /// @param params tokenId The ID of the token for which liquidity is being increased,
    /// amount0Desired The desired amount of token0 to be spent,
    /// amount1Desired The desired amount of token1 to be spent,
    /// amount0Min The minimum amount of token0 to spend, which serves as a slippage check,
    /// amount1Min The minimum amount of token1 to spend, which serves as a slippage check,
    /// deadline The time by which the transaction must be included to effect the change
    /// @return liquidity The new liquidity amount as a result of the increase
    /// @return amount0 The amount of token0 to acheive resulting liquidity
    /// @return amount1 The amount of token1 to acheive resulting liquidity
    function increaseLiquidity(
        IncreaseLiquidityParams memory params
    ) external payable nonReentrant returns (uint128 liquidity, uint256 amount0, uint256 amount1) {
        UserPositionInfo storage positionInfo = userPositionInfos[params.tokenId];
        if (positionInfo.pid == 0) revert InvalidNFT();
        PoolInfo memory pool = poolInfo[positionInfo.pid];
        pay(pool.token0, params.amount0Desired);
        pay(pool.token1, params.amount1Desired);
        if (pool.token0 != WETH && pool.token1 != WETH && msg.value > 0) revert();
        (liquidity, amount0, amount1) = nonfungiblePositionManager.increaseLiquidity{value: msg.value}(params);
        uint256 token0Left = params.amount0Desired - amount0;
        uint256 token1Left = params.amount1Desired - amount1;
        if (token0Left > 0) {
            refund(pool.token0, token0Left);
        }
        if (token1Left > 0) {
            refund(pool.token1, token1Left);
        }
        harvestOperation(positionInfo, params.tokenId, address(0));
        updateLiquidityOperation(positionInfo, params.tokenId, 0);
    }

    /// @notice Pay.
    /// @param _token The token to pay
    /// @param _amount The amount to pay
    function pay(address _token, uint256 _amount) internal {
        if (_token == WETH && msg.value > 0) {
            if (msg.value != _amount) revert InconsistentAmount();
        } else {
            IERC20(_token).safeTransferFrom(msg.sender, address(this), _amount);
        }
    }

    /// @notice Refund.
    /// @param _token The token to refund
    /// @param _amount The amount to refund
    function refund(address _token, uint256 _amount) internal {
        if (_token == WETH && msg.value > 0) {
            nonfungiblePositionManager.refundETH();
            safeTransferETH(msg.sender, address(this).balance);
        } else {
            IERC20(_token).safeTransfer(msg.sender, _amount);
        }
    }

    /// @notice Decreases the amount of liquidity in a position and accounts it to the position
    /// @param params tokenId The ID of the token for which liquidity is being decreased,
    /// amount The amount by which liquidity will be decreased,
    /// amount0Min The minimum amount of token0 that should be accounted for the burned liquidity,
    /// amount1Min The minimum amount of token1 that should be accounted for the burned liquidity,
    /// deadline The time by which the transaction must be included to effect the change
    /// @return amount0 The amount of token0 accounted to the position's tokens owed
    /// @return amount1 The amount of token1 accounted to the position's tokens owed
    function decreaseLiquidity(
        DecreaseLiquidityParams memory params
    ) external nonReentrant returns (uint256 amount0, uint256 amount1) {
        UserPositionInfo storage positionInfo = userPositionInfos[params.tokenId];
        if (positionInfo.user != msg.sender) revert NotOwner();
        (amount0, amount1) = nonfungiblePositionManager.decreaseLiquidity(params);
        harvestOperation(positionInfo, params.tokenId, address(0));
        updateLiquidityOperation(positionInfo, params.tokenId, 0);
    }

    /// @notice Collects up to a maximum amount of fees owed to a specific position to the recipient
    /// @param params tokenId The ID of the NFT for which tokens are being collected,
    /// recipient The account that should receive the tokens,
    /// @dev Warning!!! Please make sure to use multicall to call unwrapWETH9 or sweepToken when set recipient address(0), or you will lose your funds.
    /// amount0Max The maximum amount of token0 to collect,
    /// amount1Max The maximum amount of token1 to collect
    /// @return amount0 The amount of fees collected in token0
    /// @return amount1 The amount of fees collected in token1
    function collect(CollectParams memory params) external nonReentrant returns (uint256 amount0, uint256 amount1) {
        UserPositionInfo memory positionInfo = userPositionInfos[params.tokenId];
        if (positionInfo.user != msg.sender) revert NotOwner();
        if (params.recipient == address(0)) params.recipient = address(this);
        (amount0, amount1) = nonfungiblePositionManager.collect(params);
    }

    /// @notice Collects up to a maximum amount of fees owed to a specific position to the recipient, then refund.
    /// @param params CollectParams.
    /// @param to Refund recipent.
    /// @return amount0 The amount of fees collected in token0
    /// @return amount1 The amount of fees collected in token1
    function collectTo(
        CollectParams memory params,
        address to
    ) external nonReentrant returns (uint256 amount0, uint256 amount1) {
        UserPositionInfo memory positionInfo = userPositionInfos[params.tokenId];
        if (positionInfo.user != msg.sender) revert NotOwner();
        if (params.recipient == address(0)) params.recipient = address(this);
        (amount0, amount1) = nonfungiblePositionManager.collect(params);
        // Need to refund token to user when recipient is zero address
        if (params.recipient == address(this)) {
            PoolInfo memory pool = poolInfo[positionInfo.pid];
            if (to == address(0)) to = msg.sender;
            transferToken(pool.token0, to);
            transferToken(pool.token1, to);
        }
    }

    /// @notice Transfer token from MasterChef V3.
    /// @param _token The token to transfer.
    /// @param _to The to address.
    function transferToken(address _token, address _to) internal {
        uint256 balance = IERC20(_token).balanceOf(address(this));
        // Need to reduce cakeAmountBelongToMC.
        if (_token == address(CAKE)) {
            unchecked {
                // In fact balance should always be greater than or equal to cakeAmountBelongToMC, but in order to avoid any unknown issue, we added this check.
                if (balance >= cakeAmountBelongToMC) {
                    balance -= cakeAmountBelongToMC;
                } else {
                    // This should never happend.
                    cakeAmountBelongToMC = balance;
                    balance = 0;
                }
            }
        }
        if (balance > 0) {
            if (_token == WETH) {
                IWETH(WETH).withdraw(balance);
                safeTransferETH(_to, balance);
            } else {
                IERC20(_token).safeTransfer(_to, balance);
            }
        }
    }

    /// @notice Unwraps the contract's WETH9 balance and sends it to recipient as ETH.
    /// @dev The amountMinimum parameter prevents malicious contracts from stealing WETH9 from users.
    /// @param amountMinimum The minimum amount of WETH9 to unwrap
    /// @param recipient The address receiving ETH
    function unwrapWETH9(uint256 amountMinimum, address recipient) external nonReentrant {
        uint256 balanceWETH = IWETH(WETH).balanceOf(address(this));
        if (balanceWETH < amountMinimum) revert InsufficientAmount();

        if (balanceWETH > 0) {
            IWETH(WETH).withdraw(balanceWETH);
            safeTransferETH(recipient, balanceWETH);
        }
    }

    /// @notice Transfers the full amount of a token held by this contract to recipient
    /// @dev The amountMinimum parameter prevents malicious contracts from stealing the token from users
    /// @param token The contract address of the token which will be transferred to `recipient`
    /// @param amountMinimum The minimum amount of token required for a transfer
    /// @param recipient The destination address of the token
    function sweepToken(address token, uint256 amountMinimum, address recipient) external nonReentrant {
        uint256 balanceToken = IERC20(token).balanceOf(address(this));
        // Need to reduce cakeAmountBelongToMC.
        if (token == address(CAKE)) {
            unchecked {
                // In fact balance should always be greater than or equal to cakeAmountBelongToMC, but in order to avoid any unknown issue, we added this check.
                if (balanceToken >= cakeAmountBelongToMC) {
                    balanceToken -= cakeAmountBelongToMC;
                } else {
                    // This should never happend.
                    cakeAmountBelongToMC = balanceToken;
                    balanceToken = 0;
                }
            }
        }
        if (balanceToken < amountMinimum) revert InsufficientAmount();

        if (balanceToken > 0) {
            IERC20(token).safeTransfer(recipient, balanceToken);
        }
    }

    /// @notice Burns a token ID, which deletes it from the NFT contract. The token must have 0 liquidity and all tokens
    /// must be collected first.
    /// @param _tokenId The ID of the token that is being burned
    function burn(uint256 _tokenId) external nonReentrant {
        UserPositionInfo memory positionInfo = userPositionInfos[_tokenId];
        if (positionInfo.user != msg.sender) revert NotOwner();
        if (positionInfo.reward > 0 || positionInfo.liquidity > 0) revert NotEmpty();
        delete userPositionInfos[_tokenId];
        // Update Enumerable
        removeToken(msg.sender, _tokenId);
        // Remove boosted token id in farm booster.
        if (address(FARM_BOOSTER) != address(0))
            FARM_BOOSTER.removeBoostMultiplier(msg.sender, _tokenId, positionInfo.pid);
        nonfungiblePositionManager.burn(_tokenId);
        emit Withdraw(msg.sender, address(0), positionInfo.pid, _tokenId);
    }

    /// @notice Upkeep period.
    /// @param _amount The amount of cake injected.
    /// @param _duration The period duration.
    /// @param _withUpdate Whether call "massUpdatePools" operation.
    function upkeep(uint256 _amount, uint256 _duration, bool _withUpdate) external onlyReceiver {
        // Transfer cake token from receiver.
        CAKE.safeTransferFrom(receiver, address(this), _amount);
        // Update cakeAmountBelongToMC
        unchecked {
            cakeAmountBelongToMC += _amount;
        }

        if (_withUpdate) massUpdatePools();

        uint256 duration = PERIOD_DURATION;
        // Only use the _duration when _duration is between MIN_DURATION and MAX_DURATION.
        if (_duration >= MIN_DURATION && _duration <= MAX_DURATION) duration = _duration;
        uint256 currentTime = block.timestamp;
        uint256 endTime = currentTime + duration;
        uint256 cakePerSecond;
        uint256 cakeAmount = _amount;
        if (latestPeriodEndTime > currentTime) {
            uint256 remainingCake = ((latestPeriodEndTime - currentTime) * latestPeriodCakePerSecond) / PRECISION;
            emit UpdateUpkeepPeriod(latestPeriodNumber, latestPeriodEndTime, currentTime, remainingCake);
            cakeAmount += remainingCake;
        }
        cakePerSecond = (cakeAmount * PRECISION) / duration;
        unchecked {
            latestPeriodNumber++;
            latestPeriodStartTime = currentTime + 1;
            latestPeriodEndTime = endTime;
            latestPeriodCakePerSecond = cakePerSecond;
        }
        emit NewUpkeepPeriod(latestPeriodNumber, currentTime + 1, endTime, cakePerSecond, cakeAmount);
    }

    /// @notice Update cake reward for all the liquidity mining pool.
    function massUpdatePools() internal {
        uint32 currentTime = uint32(block.timestamp);
        for (uint256 pid = 1; pid <= poolLength; pid++) {
            PoolInfo memory pool = poolInfo[pid];
            ILMPool LMPool = ILMPool(pool.v3Pool.lmPool());
            if (pool.allocPoint != 0 && address(LMPool) != address(0)) {
                LMPool.accumulateReward(currentTime);
            }
        }
    }

    /// @notice Update cake reward for the liquidity mining pool.
    /// @dev Avoid too many pools, and a single transaction cannot be fully executed for all pools.
    function updatePools(uint256[] calldata pids) external onlyOwnerOrOperator {
        uint32 currentTime = uint32(block.timestamp);
        for (uint256 i = 0; i < pids.length; i++) {
            PoolInfo memory pool = poolInfo[pids[i]];
            ILMPool LMPool = ILMPool(pool.v3Pool.lmPool());
            if (pool.allocPoint != 0 && address(LMPool) != address(0)) {
                LMPool.accumulateReward(currentTime);
            }
        }
    }

    /// @notice Set operator address.
    /// @dev Callable by owner
    /// @param _operatorAddress New operator address.
    function setOperator(address _operatorAddress) external onlyOwner {
        if (_operatorAddress == address(0)) revert ZeroAddress();
        operatorAddress = _operatorAddress;
        emit NewOperatorAddress(_operatorAddress);
    }

    /// @notice Set period duration.
    /// @dev Callable by owner
    /// @param _periodDuration New period duration.
    function setPeriodDuration(uint256 _periodDuration) external onlyOwner {
        if (_periodDuration < MIN_DURATION || _periodDuration > MAX_DURATION) revert InvalidPeriodDuration();
        PERIOD_DURATION = _periodDuration;
        emit NewPeriodDuration(_periodDuration);
    }

    /// @notice Update farm boost contract address.
    /// @param _newFarmBoostContract The new farm booster address.
    function updateFarmBoostContract(address _newFarmBoostContract) external onlyOwner {
        // farm booster can be zero address when need to remove farm booster
        FARM_BOOSTER = IFarmBooster(_newFarmBoostContract);
        emit UpdateFarmBoostContract(_newFarmBoostContract);
    }

    /**
     * @notice Transfer ETH in a safe way
     * @param to: address to transfer ETH to
     * @param value: ETH amount to transfer (in wei)
     */
    function safeTransferETH(address to, uint256 value) internal {
        (bool success, ) = to.call{value: value}("");
        if (!success) revert();
    }

    /// @notice Safe Transfer CAKE.
    /// @param _to The CAKE receiver address.
    /// @param _amount Transfer CAKE amounts.
    function _safeTransfer(address _to, uint256 _amount) internal {
        if (_amount > 0) {
            uint256 balance = CAKE.balanceOf(address(this));
            if (balance < _amount) {
                _amount = balance;
            }
            // Update cakeAmountBelongToMC
            unchecked {
                if (cakeAmountBelongToMC >= _amount) {
                    cakeAmountBelongToMC -= _amount;
                } else {
                    cakeAmountBelongToMC = balance - _amount;
                }
            }
            CAKE.safeTransfer(_to, _amount);
        }
    }

    receive() external payable {
        if (msg.sender != address(nonfungiblePositionManager) && msg.sender != WETH) revert();
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
// OpenZeppelin Contracts (last updated v4.8.0) (security/ReentrancyGuard.sol)

pragma solidity ^0.8.0;

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
        _nonReentrantBefore();
        _;
        _nonReentrantAfter();
    }

    function _nonReentrantBefore() private {
        // On the first call to nonReentrant, _status will be _NOT_ENTERED
        require(_status != _ENTERED, "ReentrancyGuard: reentrant call");

        // Any calls to nonReentrant after this point will fail
        _status = _ENTERED;
    }

    function _nonReentrantAfter() private {
        // By storing the original value once again, a refund is triggered (see
        // https://eips.ethereum.org/EIPS/eip-2200)
        _status = _NOT_ENTERED;
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (token/ERC20/extensions/draft-IERC20Permit.sol)

pragma solidity ^0.8.0;

/**
 * @dev Interface of the ERC20 Permit extension allowing approvals to be made via signatures, as defined in
 * https://eips.ethereum.org/EIPS/eip-2612[EIP-2612].
 *
 * Adds the {permit} method, which can be used to change an account's ERC20 allowance (see {IERC20-allowance}) by
 * presenting a message signed by the account. By not relying on {IERC20-approve}, the token holder account doesn't
 * need to send a transaction, and thus is not required to hold Ether at all.
 */
interface IERC20Permit {
    /**
     * @dev Sets `value` as the allowance of `spender` over ``owner``'s tokens,
     * given ``owner``'s signed approval.
     *
     * IMPORTANT: The same issues {IERC20-approve} has related to transaction
     * ordering also apply here.
     *
     * Emits an {Approval} event.
     *
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     * - `deadline` must be a timestamp in the future.
     * - `v`, `r` and `s` must be a valid `secp256k1` signature from `owner`
     * over the EIP712-formatted function arguments.
     * - the signature must use ``owner``'s current nonce (see {nonces}).
     *
     * For more information on the signature format, see the
     * https://eips.ethereum.org/EIPS/eip-2612#specification[relevant EIP
     * section].
     */
    function permit(
        address owner,
        address spender,
        uint256 value,
        uint256 deadline,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) external;

    /**
     * @dev Returns the current nonce for `owner`. This value must be
     * included whenever a signature is generated for {permit}.
     *
     * Every successful call to {permit} increases ``owner``'s nonce by one. This
     * prevents a signature from being used multiple times.
     */
    function nonces(address owner) external view returns (uint256);

    /**
     * @dev Returns the domain separator used in the encoding of the signature for {permit}, as defined by {EIP712}.
     */
    // solhint-disable-next-line func-name-mixedcase
    function DOMAIN_SEPARATOR() external view returns (bytes32);
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
// OpenZeppelin Contracts (last updated v4.8.0) (token/ERC20/utils/SafeERC20.sol)

pragma solidity ^0.8.0;

import "../IERC20.sol";
import "../extensions/draft-IERC20Permit.sol";
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

    function safePermit(
        IERC20Permit token,
        address owner,
        address spender,
        uint256 value,
        uint256 deadline,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) internal {
        uint256 nonceBefore = token.nonces(owner);
        token.permit(owner, spender, value, deadline, v, r, s);
        uint256 nonceAfter = token.nonces(owner);
        require(nonceAfter == nonceBefore + 1, "SafeERC20: permit did not succeed");
    }

    /**
     * @dev Imitates a Solidity high-level call (i.e. a regular function call to a contract), relaxing the requirement
     * on the return value: the return value is optional (but if data is returned, it must not be false).
     * @param token The token targeted by the call.
     * @param data The call data (encoded using abi.encode or one of its variants).
     */
    function _callOptionalReturn(IERC20 token, bytes memory data) private {
        // We need to perform a low level call here, to bypass Solidity's return data size checking mechanism, since
        // we're implementing it ourselves. We use {Address-functionCall} to perform this call, which verifies that
        // the target address contains contract code and also asserts for success in the low-level call.

        bytes memory returndata = address(token).functionCall(data, "SafeERC20: low-level call failed");
        if (returndata.length > 0) {
            // Return data is optional
            require(abi.decode(returndata, (bool)), "SafeERC20: ERC20 operation did not succeed");
        }
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.8.0) (token/ERC721/IERC721.sol)

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

    /**
     * @dev Safely transfers `tokenId` token from `from` to `to`, checking first that contract recipients
     * are aware of the ERC721 protocol to prevent tokens from being forever locked.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `tokenId` token must exist and be owned by `from`.
     * - If the caller is not `from`, it must have been allowed to move this token by either {approve} or {setApprovalForAll}.
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
     * WARNING: Note that the caller is responsible to confirm that the recipient is capable of receiving ERC721
     * or else they may be permanently lost. Usage of {safeTransferFrom} prevents loss, though the caller must
     * understand this adds an external call which potentially creates a reentrancy vulnerability.
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
     * @dev Returns the account approved for `tokenId` token.
     *
     * Requirements:
     *
     * - `tokenId` must exist.
     */
    function getApproved(uint256 tokenId) external view returns (address operator);

    /**
     * @dev Returns if the `operator` is allowed to manage all of the assets of `owner`.
     *
     * See {setApprovalForAll}
     */
    function isApprovedForAll(address owner, address operator) external view returns (bool);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.8.0) (utils/Address.sol)

pragma solidity ^0.8.1;

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
     *
     * [IMPORTANT]
     * ====
     * You shouldn't rely on `isContract` to protect against flash loan attacks!
     *
     * Preventing calls from contracts is highly discouraged. It breaks composability, breaks support for smart wallets
     * like Gnosis Safe, and does not provide security since it can be circumvented by calling from a contract
     * constructor.
     * ====
     */
    function isContract(address account) internal view returns (bool) {
        // This method relies on extcodesize/address.code.length, which returns 0
        // for contracts in construction, since the code is only stored at the end
        // of the constructor execution.

        return account.code.length > 0;
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
        return functionCallWithValue(target, data, 0, "Address: low-level call failed");
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
        (bool success, bytes memory returndata) = target.call{value: value}(data);
        return verifyCallResultFromTarget(target, success, returndata, errorMessage);
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
        (bool success, bytes memory returndata) = target.staticcall(data);
        return verifyCallResultFromTarget(target, success, returndata, errorMessage);
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
        (bool success, bytes memory returndata) = target.delegatecall(data);
        return verifyCallResultFromTarget(target, success, returndata, errorMessage);
    }

    /**
     * @dev Tool to verify that a low level call to smart-contract was successful, and revert (either by bubbling
     * the revert reason or using the provided one) in case of unsuccessful call or if target was not a contract.
     *
     * _Available since v4.8._
     */
    function verifyCallResultFromTarget(
        address target,
        bool success,
        bytes memory returndata,
        string memory errorMessage
    ) internal view returns (bytes memory) {
        if (success) {
            if (returndata.length == 0) {
                // only check isContract if the call was successful and the return data is empty
                // otherwise we already know that it was a contract
                require(isContract(target), "Address: call to non-contract");
            }
            return returndata;
        } else {
            _revert(returndata, errorMessage);
        }
    }

    /**
     * @dev Tool to verify that a low level call was successful, and revert if it wasn't, either by bubbling the
     * revert reason or using the provided one.
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
            _revert(returndata, errorMessage);
        }
    }

    function _revert(bytes memory returndata, string memory errorMessage) private pure {
        // Look for revert reason and bubble it up if present
        if (returndata.length > 0) {
            // The easiest way to bubble the revert reason is using memory via assembly
            /// @solidity memory-safe-assembly
            assembly {
                let returndata_size := mload(returndata)
                revert(add(32, returndata), returndata_size)
            }
        } else {
            revert(errorMessage);
        }
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

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/introspection/IERC165.sol)

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

// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity ^0.8.10;

/**
 * @notice This codes were copied from https://github.com/OpenZeppelin/openzeppelin-contracts/blob/master/contracts/token/ERC721/extensions/ERC721Enumerable.sol, and did some changes.
 * @dev This implements an optional extension of defined in the EIP that adds
 * enumerability of all the token ids in the contract as well as all token ids owned by each
 * account.
 */

abstract contract Enumerable {
    // Mapping owner address to token count
    mapping(address => uint256) private _balances;

    // Mapping from owner to list of owned token IDs
    mapping(address => mapping(uint256 => uint256)) private _ownedTokens;

    // Mapping from token ID to index of the owner tokens list
    mapping(uint256 => uint256) private _ownedTokensIndex;

    function tokenOfOwnerByIndex(address owner, uint256 index) public view returns (uint256) {
        require(index < _balances[owner], "Enumerable: owner index out of bounds");
        return _ownedTokens[owner][index];
    }

    function balanceOf(address owner) public view returns (uint256) {
        require(owner != address(0), "Enumerable: address zero is not a valid owner");
        return _balances[owner];
    }

    function addToken(address from, uint256 tokenId) internal {
        _addTokenToOwnerEnumeration(from, tokenId);
        unchecked {
            _balances[from] += 1;
        }
    }

    function removeToken(address from, uint256 tokenId) internal {
        _removeTokenFromOwnerEnumeration(from, tokenId);
        unchecked {
            _balances[from] -= 1;
        }
    }

    /**
     * @dev Private function to add a token to this extension's ownership-tracking data structures.
     * @param to address representing the new owner of the given token ID
     * @param tokenId uint256 ID of the token to be added to the tokens list of the given address
     */
    function _addTokenToOwnerEnumeration(address to, uint256 tokenId) private {
        uint256 length = _balances[to];
        _ownedTokens[to][length] = tokenId;
        _ownedTokensIndex[tokenId] = length;
    }

    /**
     * @dev Private function to remove a token from this extension's ownership-tracking data structures. Note that
     * while the token is not assigned a new owner, the `_ownedTokensIndex` mapping is _not_ updated: this allows for
     * gas optimizations e.g. when performing a transfer operation (avoiding double writes).
     * This has O(1) time complexity, but alters the order of the _ownedTokens array.
     * @param from address representing the previous owner of the given token ID
     * @param tokenId uint256 ID of the token to be removed from the tokens list of the given address
     */
    function _removeTokenFromOwnerEnumeration(address from, uint256 tokenId) private {
        // To prevent a gap in from's tokens array, we store the last token in the index of the token to delete, and
        // then delete the last slot (swap and pop).

        uint256 lastTokenIndex = _balances[from] - 1;
        uint256 tokenIndex = _ownedTokensIndex[tokenId];
        require(tokenId == _ownedTokens[from][tokenIndex], "Invalid tokenId");
        // When the token to delete is the last token, the swap operation is unnecessary
        if (tokenIndex != lastTokenIndex) {
            uint256 lastTokenId = _ownedTokens[from][lastTokenIndex];

            _ownedTokens[from][tokenIndex] = lastTokenId; // Move the last token to the slot of the to-delete token
            _ownedTokensIndex[lastTokenId] = tokenIndex; // Update the moved token's index
        }

        // This also deletes the contents at the last position of the array
        delete _ownedTokensIndex[tokenId];
        delete _ownedTokens[from][lastTokenIndex];
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.10;

interface IFarmBooster {
    function getUserMultiplier(uint256 _tokenId) external view returns (uint256);

    function whiteList(uint256 _pid) external view returns (bool);

    function updatePositionBoostMultiplier(uint256 _tokenId) external returns (uint256 _multiplier);

    function removeBoostMultiplier(address _user, uint256 _tokenId, uint256 _pid) external;
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.10;

interface ILMPool {
    function updatePosition(int24 tickLower, int24 tickUpper, int128 liquidityDelta) external;

    function getRewardGrowthInside(
        int24 tickLower,
        int24 tickUpper
    ) external view returns (uint256 rewardGrowthInsideX128);

    function accumulateReward(uint32 currTimestamp) external;
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.10;

import "./IPancakeV3Pool.sol";
import "./ILMPool.sol";

interface ILMPoolDeployer {
    function deploy(IPancakeV3Pool pool) external returns (ILMPool lmPool);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.10;

interface IMasterChefV2 {
    function deposit(uint256 _pid, uint256 _amount) external;

    function withdraw(uint256 _pid, uint256 _amount) external;

    function pendingCake(uint256 _pid, address _user) external view returns (uint256);

    function userInfo(uint256 _pid, address _user) external view returns (uint256, uint256, uint256);

    function emergencyWithdraw(uint256 _pid) external;

    function updateBoostMultiplier(address _user, uint256 _pid, uint256 _newBoostMulti) external;
}

// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity ^0.8.10;
import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import "./INonfungiblePositionManagerStruct.sol";

interface INonfungiblePositionManager is INonfungiblePositionManagerStruct, IERC721 {
    /// @notice Returns the position information associated with a given token ID.
    /// @dev Throws if the token ID is not valid.
    /// @param tokenId The ID of the token that represents the position
    /// @return nonce The nonce for permits
    /// @return operator The address that is approved for spending
    /// @return token0 The address of the token0 for a specific pool
    /// @return token1 The address of the token1 for a specific pool
    /// @return fee The fee associated with the pool
    /// @return tickLower The lower end of the tick range for the position
    /// @return tickUpper The higher end of the tick range for the position
    /// @return liquidity The liquidity of the position
    /// @return feeGrowthInside0LastX128 The fee growth of token0 as of the last action on the individual position
    /// @return feeGrowthInside1LastX128 The fee growth of token1 as of the last action on the individual position
    /// @return tokensOwed0 The uncollected amount of token0 owed to the position as of the last computation
    /// @return tokensOwed1 The uncollected amount of token1 owed to the position as of the last computation
    function positions(
        uint256 tokenId
    )
        external
        view
        returns (
            uint96 nonce,
            address operator,
            address token0,
            address token1,
            uint24 fee,
            int24 tickLower,
            int24 tickUpper,
            uint128 liquidity,
            uint256 feeGrowthInside0LastX128,
            uint256 feeGrowthInside1LastX128,
            uint128 tokensOwed0,
            uint128 tokensOwed1
        );

    /// @notice Increases the amount of liquidity in a position, with tokens paid by the `msg.sender`
    /// @param params tokenId The ID of the token for which liquidity is being increased,
    /// amount0Desired The desired amount of token0 to be spent,
    /// amount1Desired The desired amount of token1 to be spent,
    /// amount0Min The minimum amount of token0 to spend, which serves as a slippage check,
    /// amount1Min The minimum amount of token1 to spend, which serves as a slippage check,
    /// deadline The time by which the transaction must be included to effect the change
    /// @return liquidity The new liquidity amount as a result of the increase
    /// @return amount0 The amount of token0 to acheive resulting liquidity
    /// @return amount1 The amount of token1 to acheive resulting liquidity
    function increaseLiquidity(
        IncreaseLiquidityParams calldata params
    ) external payable returns (uint128 liquidity, uint256 amount0, uint256 amount1);

    /// @notice Decreases the amount of liquidity in a position and accounts it to the position
    /// @param params tokenId The ID of the token for which liquidity is being decreased,
    /// amount The amount by which liquidity will be decreased,
    /// amount0Min The minimum amount of token0 that should be accounted for the burned liquidity,
    /// amount1Min The minimum amount of token1 that should be accounted for the burned liquidity,
    /// deadline The time by which the transaction must be included to effect the change
    /// @return amount0 The amount of token0 accounted to the position's tokens owed
    /// @return amount1 The amount of token1 accounted to the position's tokens owed
    function decreaseLiquidity(
        DecreaseLiquidityParams calldata params
    ) external payable returns (uint256 amount0, uint256 amount1);

    /// @notice Collects up to a maximum amount of fees owed to a specific position to the recipient
    /// @param params tokenId The ID of the NFT for which tokens are being collected,
    /// recipient The account that should receive the tokens,
    /// amount0Max The maximum amount of token0 to collect,
    /// amount1Max The maximum amount of token1 to collect
    /// @return amount0 The amount of fees collected in token0
    /// @return amount1 The amount of fees collected in token1
    function collect(CollectParams calldata params) external payable returns (uint256 amount0, uint256 amount1);

    /// @notice Burns a token ID, which deletes it from the NFT contract. The token must have 0 liquidity and all tokens
    /// must be collected first.
    /// @param tokenId The ID of the token that is being burned
    function burn(uint256 tokenId) external payable;

    function refundETH() external payable;
}

// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity ^0.8.10;

interface INonfungiblePositionManagerStruct {
    struct IncreaseLiquidityParams {
        uint256 tokenId;
        uint256 amount0Desired;
        uint256 amount1Desired;
        uint256 amount0Min;
        uint256 amount1Min;
        uint256 deadline;
    }

    struct DecreaseLiquidityParams {
        uint256 tokenId;
        uint128 liquidity;
        uint256 amount0Min;
        uint256 amount1Min;
        uint256 deadline;
    }

    struct CollectParams {
        uint256 tokenId;
        address recipient;
        uint128 amount0Max;
        uint128 amount1Max;
    }
}

// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity ^0.8.10;

interface IPancakeV3Pool {
    function factory() external view returns (address);

    function token0() external view returns (address);

    function token1() external view returns (address);

    function fee() external view returns (uint24);

    function lmPool() external view returns (address);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.10;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

/// @title Interface for WETH9
interface IWETH is IERC20 {
    /// @notice Deposit ether to get wrapped ether
    function deposit() external payable;

    /// @notice Withdraw wrapped ether to get ether
    function withdraw(uint256) external;
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.10;

/**
 * @dev Wrappers over Solidity's uintXX/intXX casting operators with added overflow
 * checks.
 *
 * Downcasting from uint256/int256 in Solidity does not revert on overflow. This can
 * easily result in undesired exploitation or bugs, since developers usually
 * assume that overflows raise errors. `SafeCast` restores this intuition by
 * reverting the transaction when such an operation overflows.
 *
 * Using this library instead of the unchecked operations eliminates an entire
 * class of bugs, so it's recommended to use it always.
 *
 * Can be combined with {SafeMath} and {SignedSafeMath} to extend it to smaller types, by performing
 * all math on `uint256` and `int256` and then downcasting.
 */
library SafeCast {
    /**
     * @dev Returns the downcasted uint128 from uint256, reverting on
     * overflow (when the input is greater than largest uint128).
     *
     * Counterpart to Solidity's `uint128` operator.
     *
     * Requirements:
     *
     * - input must fit into 128 bits
     */
    function toUint128(uint256 value) internal pure returns (uint128) {
        require(value < 2 ** 128, "SafeCast: value doesn't fit in 128 bits");
        return uint128(value);
    }
}

// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity ^0.8.10;

/// @title Multicall
/// @notice Enables calling multiple methods in a single call to the contract
contract Multicall {
    function multicall(bytes[] calldata data) public payable returns (bytes[] memory results) {
        results = new bytes[](data.length);
        for (uint256 i = 0; i < data.length; i++) {
            (bool success, bytes memory result) = address(this).delegatecall(data[i]);

            if (!success) {
                // Next 5 lines from https://ethereum.stackexchange.com/a/83577
                if (result.length < 68) revert();
                assembly {
                    result := add(result, 0x04)
                }
                revert(abi.decode(result, (string)));
            }

            results[i] = result;
        }
    }
}