// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./interfaces/IAipFactory.sol";
import "./base/AipPoolDeployer.sol";
import "./access/Ownable.sol";
import "./security/NoDelegateCall.sol";
import "./libraries/PoolAddress.sol";

contract AipFactory is IAipFactory, AipPoolDeployer, NoDelegateCall {
    address public override owner;
    address public override swapManager;
    address public override planManager;
    address public override DAI;
    address public override USDC;
    address public override USDT;
    address public override WETH9;
    bool public override enabled;

    mapping(address => PoolAddress.PoolInfo) public override getPoolInfo;
    mapping(address => mapping(address => mapping(uint8 => address)))
        public
        override getPool;

    constructor() {
        owner = msg.sender;
        emit OwnerChanged(address(0), msg.sender);
    }

    function createPool(
        address token0,
        address token1,
        uint8 frequency
    ) external override noDelegateCall returns (address pool) {
        require(enabled, "Not enabled");
        require(
            token0 != token1 && token0 != address(0) && token1 != address(0)
        );
        require(frequency > 0 && frequency <= 30, "Invalid date");
        require(
            token0 == DAI || token0 == USDC || token0 == USDT,
            "Only DAI, USDC, USDT accepted"
        );
        require(getPool[token0][token1][frequency] == address(0));
        pool = deploy(
            address(this),
            swapManager,
            planManager,
            WETH9,
            token0,
            token1,
            frequency
        );
        getPool[token0][token1][frequency] = pool;
        getPoolInfo[pool] = PoolAddress.PoolInfo({
            token0: token0,
            token1: token1,
            frequency: frequency
        });
        emit PoolCreated(token0, token1, frequency, pool);
    }

    function enable(
        address _swapManager,
        address _planManager,
        address _DAI,
        address _USDC,
        address _USDT,
        address _WETH9
    ) external override {
        require(!enabled, "Enabled");
        require(msg.sender == owner, "Not owner");
        require(
            _swapManager != address(0) &&
                _planManager != address(0) &&
                _DAI != address(0) &&
                _USDC != address(0) &&
                _USDT != address(0) &&
                _WETH9 != address(0)
        );
        enabled = true;
        swapManager = _swapManager;
        planManager = _planManager;
        DAI = _DAI;
        USDC = _USDC;
        USDT = _USDT;
        WETH9 = _WETH9;
        emit Enabled(swapManager, planManager, DAI, USDC, USDT, WETH9);
    }

    function setOwner(address _owner) external override {
        require(msg.sender == owner);
        emit OwnerChanged(owner, _owner);
        owner = _owner;
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "../libraries/PoolAddress.sol";

interface IAipFactory {
    event OwnerChanged(address indexed oldOwner, address indexed newOwner);
    event PoolCreated(
        address token0,
        address token1,
        uint8 frequency,
        address pool
    );

    event Enabled(
        address swapManager,
        address planManager,
        address DAI,
        address USDC,
        address USDT,
        address WETH9
    );

    function owner() external view returns (address);

    function swapManager() external view returns (address);

    function planManager() external view returns (address);

    function DAI() external view returns (address);

    function USDC() external view returns (address);

    function USDT() external view returns (address);

    function WETH9() external view returns (address);

    function enabled() external view returns (bool);

    function getPoolInfo(address addr)
        external
        view
        returns (
            address,
            address,
            uint8
        );

    function getPool(
        address token0,
        address token1,
        uint8 frequency
    ) external view returns (address pool);

    function createPool(
        address token0,
        address token1,
        uint8 frequency
    ) external returns (address pool);

    function enable(
        address _swapManager,
        address _planManager,
        address _DAI,
        address _USDC,
        address _USDT,
        address _WETH9
    ) external;

    function setOwner(address _owner) external;
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "../AipPool.sol";
import "../interfaces/IAipPoolDeployer.sol";

contract AipPoolDeployer is IAipPoolDeployer {
    // 0: Token X, token for protection
    // 1: Token Y, protected token
    struct Parameters {
        address factory;
        address swapManager;
        address planManager;
        address WETH9;
        address token0;
        address token1;
        uint8 frequency;
    }

    Parameters public override parameters;

    function deploy(
        address factory,
        address swapManager,
        address planManager,
        address WETH9,
        address token0,
        address token1,
        uint8 frequency
    ) internal returns (address pool) {
        parameters = Parameters({
            factory: factory,
            swapManager: swapManager,
            planManager: planManager,
            WETH9: WETH9,
            token0: token0,
            token1: token1,
            frequency: frequency
        });
        pool = address(
            new AipPool{
                salt: keccak256(abi.encode(token0, token1, frequency))
            }()
        );
        delete parameters;
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

abstract contract Ownable {
    address private _owner;

    event OwnershipTransferred(
        address indexed previousOwner,
        address indexed newOwner
    );

    /**
     * @dev Initializes the contract setting the deployer as the initial owner.
     */
    constructor() {
        _setOwner(msg.sender);
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
        require(owner() == msg.sender, "Ownable: caller is not the owner");
        _;
    }

    function _setOwner(address newOwner) private {
        address oldOwner = _owner;
        _owner = newOwner;
        emit OwnershipTransferred(oldOwner, newOwner);
    }
}

// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.0;

/// @title Prevents delegatecall to a contract
/// @notice Base contract that provides a modifier for preventing delegatecall to methods in a child contract
abstract contract NoDelegateCall {
    /// @dev The original address of this contract
    address private immutable original;

    constructor() {
        // Immutables are computed in the init code of the contract, and then inlined into the deployed bytecode.
        // In other words, this variable won't change when it's checked at runtime.
        original = address(this);
    }

    /// @dev Private method is used instead of inlining into modifier because modifiers are copied into each method,
    ///     and the use of immutable means the address bytes are copied in every place the modifier is used.
    function checkNotDelegateCall() private view {
        require(address(this) == original);
    }

    /// @notice Prevents delegatecall into the modified method
    modifier noDelegateCall() {
        checkNotDelegateCall();
        _;
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

library PoolAddress {
    bytes32 internal constant POOL_INIT_CODE_HASH =
        0xe37f35a5329b2a8d91efbb4a77ebfaecb4628f792e5e734ca2a25624bc55a551;

    struct PoolInfo {
        address token0;
        address token1;
        uint8 frequency;
    }

    function getPoolInfo(
        address token0,
        address token1,
        uint8 frequency
    ) internal pure returns (PoolInfo memory) {
        return PoolInfo({token0: token0, token1: token1, frequency: frequency});
    }

    function computeAddress(address factory, PoolInfo memory poolInfo)
        internal
        pure
        returns (address pool)
    {
        pool = address(
            uint160(
                uint256(
                    keccak256(
                        abi.encodePacked(
                            hex"ff",
                            factory,
                            keccak256(
                                abi.encode(
                                    poolInfo.token0,
                                    poolInfo.token1,
                                    poolInfo.frequency
                                )
                            ),
                            POOL_INIT_CODE_HASH
                        )
                    )
                )
            )
        );
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./security/ReentrancyGuard.sol";
import "./interfaces/IAipPoolDeployer.sol";
import "./interfaces/IERC20.sol";
import "./interfaces/IAipPool.sol";
import "./interfaces/IAipFactory.sol";
import "./interfaces/IAipSwapManager.sol";
import "./interfaces/IERC721Access.sol";

import "./interfaces/callback/IAipSubscribeCallback.sol";
import "./interfaces/callback/IAipExtendCallback.sol";
import "./interfaces/callback/IAipBurnCallback.sol";
import "./libraries/TransferHelper.sol";

contract AipPool is IAipPool, ReentrancyGuard {
    address public immutable override factory;
    address public immutable override swapManager;
    address public immutable override planManager;
    address public immutable override WETH9;
    address public override rewardToken;
    address public override rewardOperator;
    address public immutable override token0;
    address public immutable override token1;
    uint8 public immutable override frequency;
    uint16 public override swapFee = 3000;
    uint16 public override swapWETH9Fee = 3000;
    uint16 private constant PROTOCOL_FEE = 1000;
    uint8 private constant TIME_UNIT = 60;
    uint24 private constant PROCESSING_GAS = 400000;
    uint64 private constant MIN_TICK_AMOUNT = 10 * 1e18;

    uint256 private _nextPlanIndex = 1;
    uint256 private _nextTickIndex = 1;
    uint256 public override protocolFee;
    uint256 public override totalPaymentAmount0;
    mapping(uint256 => uint256) private _tickVolumes0;
    mapping(uint256 => uint256) private _tickVolumes1;
    mapping(uint256 => uint256) private _tickFees0;
    mapping(uint256 => uint256) private _tickTimes;
    mapping(uint256 => uint256) private _tickRewards;
    mapping(uint256 => PlanInfo) public override plans;

    constructor() {
        (
            factory,
            swapManager,
            planManager,
            WETH9,
            token0,
            token1,
            frequency
        ) = IAipPoolDeployer(msg.sender).parameters();
    }

    modifier isNotLocked(uint256 planIndex) {
        IERC721Access manager = IERC721Access(planManager);
        uint256 tokenId = manager.getTokenId(
            token0,
            token1,
            frequency,
            planIndex
        );
        require(!manager.isLocked(tokenId), "Locked");
        _;
    }

    modifier onlyFactoryOwner() {
        require(msg.sender == IAipFactory(factory).owner());
        _;
    }

    modifier onlyRewardOperator() {
        require(msg.sender == rewardOperator);
        _;
    }

    function _getCurrentEndTick(uint256 endTick)
        private
        view
        returns (uint256)
    {
        return _nextTickIndex - 1 > endTick ? endTick : _nextTickIndex - 1;
    }

    function _getPlanAmount(
        uint256 tickAmount0,
        uint256 startTick,
        uint256 endTick
    ) private view returns (uint256 amount0, uint256 amount1) {
        uint256 currentEndTick = _getCurrentEndTick(endTick);
        mapping(uint256 => uint256) storage tickVolumes1 = _tickVolumes1;
        mapping(uint256 => uint256) storage tickVolumes0 = _tickVolumes0;
        for (uint256 i = startTick; i <= currentEndTick; i++) {
            amount0 += tickAmount0;
            amount1 += (tickVolumes1[i] * tickAmount0) / tickVolumes0[i];
        }
    }

    function balance0() private view returns (uint256) {
        (bool success, bytes memory data) = token0.staticcall(
            abi.encodeWithSelector(IERC20.balanceOf.selector, address(this))
        );
        require(success && data.length >= 32);
        return abi.decode(data, (uint256));
    }

    function balance1() private view returns (uint256) {
        (bool success, bytes memory data) = token1.staticcall(
            abi.encodeWithSelector(IERC20.balanceOf.selector, address(this))
        );
        require(success && data.length >= 32);
        return abi.decode(data, (uint256));
    }

    function balanceReward() private view returns (uint256) {
        (bool success, bytes memory data) = rewardToken.staticcall(
            abi.encodeWithSelector(IERC20.balanceOf.selector, address(this))
        );
        require(success && data.length >= 32);
        return abi.decode(data, (uint256));
    }

    function price() public view override returns (uint256) {
        return IAipSwapManager(swapManager).poolPrice(token0, token1, swapFee);
    }

    function lastTrigger()
        public
        view
        override
        returns (uint256 tick, uint256 time)
    {
        tick = _nextTickIndex - 1;
        time = _tickTimes[_nextTickIndex - 1];
    }

    function nextTickVolume()
        external
        view
        override
        returns (uint256 index, uint256 amount0)
    {
        index = _nextTickIndex;
        amount0 = _tickVolumes0[index];
    }

    function tickInfo(uint256 tick)
        external
        view
        override
        returns (
            uint256 amount0,
            uint256 amount1,
            uint256 fee0,
            uint256 time,
            uint256 reward
        )
    {
        amount0 = _tickVolumes0[tick];
        amount1 = _tickVolumes1[tick];
        fee0 = _tickFees0[tick];
        time = _tickTimes[tick];
        reward = _tickRewards[tick];
    }

    function getPlanStatistics(uint256 planIndex)
        external
        view
        override
        returns (
            uint256 swapAmount1,
            uint256 withdrawnAmount1,
            uint256 ticks,
            uint256 remainingTicks,
            uint256 startedTime,
            uint256 endedTime,
            uint256 lastTriggerTime
        )
    {
        PlanInfo memory plan = plans[planIndex];
        uint256 lastTriggerTick;
        (lastTriggerTick, lastTriggerTime) = lastTrigger();
        if (plan.endTick >= plan.startTick) {
            startedTime = _tickTimes[plan.startTick];
            (, swapAmount1) = _getPlanAmount(
                plan.tickAmount0,
                plan.startTick,
                plan.endTick
            );
            withdrawnAmount1 = plan.withdrawnAmount1;
            uint256 period = frequency * TIME_UNIT;
            if (plan.endTick > lastTriggerTick) {
                if (lastTriggerTime > 0) {
                    endedTime =
                        lastTriggerTime +
                        period *
                        (plan.endTick - lastTriggerTick);
                }
                remainingTicks = plan.endTick - lastTriggerTick;
            } else {
                endedTime = _tickTimes[plan.endTick];
            }
        }
        ticks = plan.endTick + 1 - plan.startTick;
    }

    function subscribe(
        address investor,
        uint256 tickAmount0,
        uint256 ticks,
        bytes calldata data
    ) external override nonReentrant returns (uint256 planIndex) {
        require(tickAmount0 >= MIN_TICK_AMOUNT, "Invalid tick amount");
        require(ticks > 0, "Invalid periods");
        planIndex = _nextPlanIndex++;
        PlanInfo storage plan = plans[planIndex];
        plan.index = planIndex;
        plan.investor = investor;
        plan.tickAmount0 = tickAmount0;
        plan.withdrawnAmount1 = 0;
        plan.startTick = _nextTickIndex;
        plan.endTick = _nextTickIndex + ticks - 1;
        mapping(uint256 => uint256) storage tickVolumes0 = _tickVolumes0;
        for (uint256 i = plan.startTick; i <= plan.endTick; i++) {
            tickVolumes0[i] += tickAmount0;
        }
        uint256 balance0Before = balance0();
        IAipSubscribeCallback(msg.sender).aipSubscribeCallback(
            ticks * tickAmount0,
            data
        );
        require(balance0Before + ticks * tickAmount0 <= balance0(), "S");
        emit Subscribe(
            plan.index,
            plan.investor,
            plan.tickAmount0,
            plan.startTick,
            plan.endTick
        );
    }

    function extend(
        uint256 planIndex,
        uint256 ticks,
        bytes calldata data
    ) external override nonReentrant {
        PlanInfo storage plan = plans[planIndex];
        require(plan.endTick >= _nextTickIndex, "Finished");
        require(ticks > 0, "Invalid periods");
        uint256 oldEndTick = plan.endTick;
        plan.endTick = plan.endTick + ticks;
        for (uint256 i = oldEndTick + 1; i <= plan.endTick; i++) {
            _tickVolumes0[i] += plan.tickAmount0;
        }
        uint256 balance0Before = balance0();
        IAipExtendCallback(msg.sender).aipExtendCallback(
            ticks * plan.tickAmount0,
            data
        );
        require(balance0Before + ticks * plan.tickAmount0 <= balance0(), "E");
        emit Extend(planIndex, oldEndTick, plan.endTick);
    }

    function withdraw(uint256 planIndex)
        external
        override
        isNotLocked(planIndex)
        nonReentrant
        returns (uint256 received1)
    {
        PlanInfo storage plan = plans[planIndex];
        (, uint256 amount1) = _getPlanAmount(
            plan.tickAmount0,
            plan.startTick,
            plan.endTick
        );
        received1 = amount1 - plan.withdrawnAmount1;
        plan.withdrawnAmount1 += received1;
        require(received1 > 0, "Nothing to withdraw");
        uint256 balance1Before = balance1();
        TransferHelper.safeTransfer(token1, plan.investor, received1);
        require(balance1Before - received1 <= balance1(), "C1");
        emit Withdraw(planIndex, received1);
    }

    function unsubscribe(uint256 planIndex, bytes calldata data)
        external
        override
        nonReentrant
        returns (uint256 received0, uint256 received1)
    {
        address receiver = IAipBurnCallback(planManager).aipBurnCallback(data);
        require(receiver != address(0));
        PlanInfo storage plan = plans[planIndex];
        if (plan.endTick >= _nextTickIndex) {
            uint256 oldEndTick = plan.endTick;
            plan.endTick = _nextTickIndex - 1;
            received0 = plan.tickAmount0 * (oldEndTick - plan.endTick);

            mapping(uint256 => uint256) storage tickVolumes0 = _tickVolumes0;
            if (plan.endTick + 1 <= oldEndTick) {
                for (uint256 i = plan.endTick + 1; i <= oldEndTick; i++) {
                    tickVolumes0[i] -= plan.tickAmount0;
                }
            }
        }
        if (plan.endTick >= plan.startTick) {
            (, uint256 amount1) = _getPlanAmount(
                plan.tickAmount0,
                plan.startTick,
                plan.endTick
            );
            received1 = amount1 - plan.withdrawnAmount1;
            plan.withdrawnAmount1 += received1;
        }
        uint256 balance0Before = balance0();
        uint256 balance1Before = balance1();

        if (received0 > 0) {
            TransferHelper.safeTransfer(token0, receiver, received0);
            require(balance0Before - received0 <= balance0(), "U0");
        }
        if (received1 > 0) {
            TransferHelper.safeTransfer(token1, receiver, received1);
            require(balance1Before - received1 <= balance1(), "U1");
        }

        emit Unsubscribe(planIndex, received0, received1);
    }

    function trigger()
        external
        override
        nonReentrant
        returns (uint256 amount0, uint256 amount1)
    {
        uint256 tickIndex = _nextTickIndex++;
        amount0 = _tickVolumes0[tickIndex];
        require(amount0 > 0, "Tick volume equal 0");
        mapping(uint256 => uint256) storage tickTimes = _tickTimes;
        if (tickIndex > 1) {
            require(
                tickTimes[tickIndex - 1] + frequency * TIME_UNIT <=
                    block.timestamp + 5,
                "Not yet"
            );
        }
        tickTimes[tickIndex] = block.timestamp;
        uint256 gasFee = tx.gasprice * PROCESSING_GAS;
        uint256 _price = IAipSwapManager(swapManager).poolPrice(
            token0,
            WETH9,
            swapWETH9Fee
        );
        uint256 triggerFee0 = (gasFee * 1e18) / _price;
        uint256 protocolFee0 = amount0 / PROTOCOL_FEE;

        uint256 totalSwap = amount0 - protocolFee0 - triggerFee0;

        totalPaymentAmount0 += amount0;

        TransferHelper.safeApprove(token0, swapManager, totalSwap);

        uint256 balance0Before = balance0();
        uint256 balance1Before = balance1();
        (, int256 swapAmount1) = IAipSwapManager(swapManager).swap(
            token0,
            token1,
            swapFee,
            address(this),
            true,
            totalSwap
        );

        amount1 = swapAmount1 >= 0
            ? uint256(swapAmount1)
            : uint256(-swapAmount1);
        require(amount1 > 0);
        _tickVolumes1[tickIndex] += amount1;
        _tickFees0[tickIndex] += protocolFee0 + triggerFee0;
        protocolFee += protocolFee0;
        TransferHelper.safeTransfer(token0, msg.sender, triggerFee0);
        require(balance0Before - (totalSwap + triggerFee0) <= balance0(), "T0");
        require(balance1Before + amount1 <= balance1(), "T1");
        emit Trigger(tickIndex, amount0, amount1, triggerFee0, protocolFee0);
    }

    function setSwapFee(uint16 _swapFee, uint16 _swapWETH9Fee)
        external
        override
        nonReentrant
        onlyFactoryOwner
        returns (address swapPool, address swapWETH9Pool)
    {
        require(
            _swapFee == 500 || _swapFee == 3000 || _swapFee == 10000,
            "Invalid swap fee"
        );
        swapPool = IAipSwapManager(swapManager).getPool(
            token0,
            token1,
            _swapFee
        );
        swapWETH9Pool = IAipSwapManager(swapManager).getPool(
            token0,
            WETH9,
            _swapWETH9Fee
        );
        emit SwapFeeChanged(swapFee, swapWETH9Fee, _swapFee, _swapWETH9Fee);
        swapFee = _swapFee;
        swapWETH9Fee = _swapWETH9Fee;
    }

    function claimReward(uint256 planIndex)
        external
        override
        nonReentrant
        returns (
            address token,
            uint256 unclaimedAmount,
            uint256 claimedAmount
        )
    {
        PlanInfo storage plan = plans[planIndex];
        token = rewardToken;
        if (token != address(0)) {
            uint256 currentEndTick = _getCurrentEndTick(plan.endTick);
            uint256 currentStartTick = plan.claimedRewardIndex == 0
                ? plan.startTick
                : plan.claimedRewardIndex + 1;
            if (currentEndTick >= currentStartTick) {
                for (uint256 i = currentStartTick; i <= currentEndTick; i++) {
                    uint256 rewardAmount = _tickRewards[i];
                    uint256 paymentAmount0 = _tickVolumes0[i];
                    unclaimedAmount +=
                        (rewardAmount * plan.tickAmount0) /
                        paymentAmount0;
                }
            }

            claimedAmount = plan.claimedRewardAmount;

            if (unclaimedAmount > 0) {
                plan.claimedRewardAmount += unclaimedAmount;
                plan.claimedRewardIndex = _nextTickIndex - 1;
                uint256 balanceRewardBefore = balanceReward();
                TransferHelper.safeTransfer(
                    rewardToken,
                    plan.investor,
                    unclaimedAmount
                );
                require(
                    balanceRewardBefore - unclaimedAmount <= balanceReward(),
                    "CR"
                );
                emit ClaimReward(plan.index, unclaimedAmount, claimedAmount);
            }
        }
    }

    function depositReward(uint256 amount)
        external
        override
        nonReentrant
        onlyRewardOperator
    {
        _tickRewards[_nextTickIndex - 1] += amount;
        uint256 balanceRewardBefore = balanceReward();
        TransferHelper.safeTransferFrom(
            rewardToken,
            msg.sender,
            address(this),
            amount
        );
        require(balanceRewardBefore + amount <= balanceReward(), "DR");
        emit DepositReward(amount);
    }

    function initReward(address _rewardToken, address _rewardOperator)
        external
        override
        nonReentrant
        onlyFactoryOwner
    {
        require(rewardToken == address(0));
        require(_rewardToken != address(0), "Invalid token address");
        require(_rewardOperator != address(0), "Invalid operator address");
        rewardToken = _rewardToken;
        rewardOperator = _rewardOperator;
        emit InitReward(rewardToken, rewardOperator);
    }

    function changeRewardOperator(address _operator)
        external
        override
        nonReentrant
        onlyFactoryOwner
    {
        require(rewardOperator != address(0), "Operator is not exist");
        require(_operator != address(0), "Invalid address");
        emit RewardOperatorChanged(rewardOperator, _operator);
        rewardOperator = _operator;
    }

    function collectProtocol(address recipient, uint256 amountRequested)
        external
        override
        nonReentrant
        onlyFactoryOwner
        returns (uint256 amount)
    {
        amount = amountRequested > protocolFee ? protocolFee : amountRequested;

        if (amount > 0) {
            if (amount == protocolFee) amount--; // ensure that the slot is not cleared, for gas savings
            protocolFee -= amount;
            TransferHelper.safeTransfer(token0, recipient, amount);
        }

        emit CollectProtocol(msg.sender, recipient, amount);
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface IAipPoolDeployer {
    function parameters()
        external
        view
        returns (
            address factory,
            address swapManager,
            address planManager,
            address WETH9,
            address token0,
            address token1,
            uint8 frequency
        );
}

// SPDX-License-Identifier: MIT
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
    event Approval(
        address indexed owner,
        address indexed spender,
        uint256 value
    );

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
    function allowance(address owner, address spender)
        external
        view
        returns (uint256);

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
pragma solidity ^0.8.0;

interface IAipPool {
    event Trigger(
        uint256 tickIndex,
        uint256 amount0,
        uint256 amount1,
        uint256 triggerFee0,
        uint256 protocolFee0
    );

    event Subscribe(
        uint256 planIndex,
        address investor,
        uint256 tickAmount,
        uint256 startTick,
        uint256 endTick
    );

    event Extend(uint256 planIndex, uint256 oldEndTick, uint256 newEndTick);

    event Unsubscribe(uint256 planIndex, uint256 received0, uint256 received1);

    event Withdraw(uint256 planIndex, uint256 received1);

    event ClaimReward(
        uint256 planIndex,
        uint256 unclaimedAmount,
        uint256 claimedAmount
    );
    event DepositReward(uint256 amount);
    event InitReward(address token, address operator);
    event RewardOperatorChanged(
        address oldRewardOperator,
        address newRewardOperator
    );

    event SwapFeeChanged(
        uint16 oldSwapFee,
        uint16 oldSwapWETH9Fee,
        uint16 newSwapFee,
        uint16 newSwapWETH9Fee
    );
    event CollectProtocol(address requester, address receiver, uint256 amount);

    struct PlanInfo {
        uint256 index;
        address investor;
        uint256 tickAmount0;
        uint256 withdrawnAmount1;
        uint256 startTick;
        uint256 endTick;
        uint256 claimedRewardIndex;
        uint256 claimedRewardAmount;
    }

    function factory() external view returns (address);

    function swapManager() external view returns (address);

    function planManager() external view returns (address);

    function WETH9() external view returns (address);

    function rewardToken() external view returns (address);

    function rewardOperator() external view returns (address);

    function token0() external view returns (address);

    function token1() external view returns (address);

    function frequency() external view returns (uint8);

    function swapFee() external view returns (uint16);

    function swapWETH9Fee() external view returns (uint16);

    function protocolFee() external view returns (uint256);

    function totalPaymentAmount0() external view returns (uint256);

    function plans(uint256)
        external
        view
        returns (
            uint256 index,
            address investor,
            uint256 tickAmount0,
            uint256 withdrawnAmount1,
            uint256 startTick,
            uint256 endTick,
            uint256 claimedRewardIndex,
            uint256 claimedRewardAmount
        );

    function price() external view returns (uint256);

    function lastTrigger() external view returns (uint256 tick, uint256 time);

    function nextTickVolume()
        external
        view
        returns (uint256 index, uint256 amount0);

    function tickInfo(uint256 tick)
        external
        view
        returns (
            uint256 amount0,
            uint256 amount1,
            uint256 fee0,
            uint256 time,
            uint256 reward
        );

    function getPlanStatistics(uint256 planIndex)
        external
        view
        returns (
            uint256 swapAmount1,
            uint256 withdrawnAmount1,
            uint256 ticks,
            uint256 remainingTicks,
            uint256 startedTime,
            uint256 endedTime,
            uint256 lastTriggerTime
        );

    function subscribe(
        address investor,
        uint256 tickAmount0,
        uint256 totalAmount0,
        bytes calldata data
    ) external returns (uint256 index);

    function withdraw(uint256 planIndex) external returns (uint256 received1);

    function extend(
        uint256 planIndex,
        uint256 extendedAmount0,
        bytes calldata data
    ) external;

    function unsubscribe(uint256 planIndex, bytes calldata data)
        external
        returns (uint256 received0, uint256 received1);

    function trigger() external returns (uint256 amount0, uint256 amount1);

    function setSwapFee(uint16 _swapFee, uint16 _swapWETH9Fee)
        external
        returns (address swapPool, address swapWETH9Pool);

    function claimReward(uint256 planIndex)
        external
        returns (
            address token,
            uint256 unclaimedAmount,
            uint256 claimedAmount
        );

    function depositReward(uint256 amount) external;

    function initReward(address _rewardToken, address _rewardOperator) external;

    function changeRewardOperator(address _operator) external;

    function collectProtocol(address recipient, uint256 amountRequested)
        external
        returns (uint256 amount);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface IAipSwapManager {
    function bestLiquidityPool(address token0, address token1)
        external
        view
        returns (address pool, uint256 price);

    function getPool(
        address token0,
        address token1,
        uint24 fee
    ) external view returns (address pool);

    function poolPrice(
        address token0,
        address token1,
        uint24 fee
    ) external view returns (uint256 price);

    function swap(
        address token0,
        address token1,
        uint24 fee,
        address recipient,
        bool zeroForOne,
        uint256 amount
    ) external returns (int256 amount0, int256 amount1);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface IERC721Access {
    function getTokenId(
        address token0,
        address token1,
        uint8 frequency,
        uint256 planIndex
    ) external view returns (uint256);

    function isLocked(uint256 tokenId) external view returns (bool);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface IAipSubscribeCallback {
    function aipSubscribeCallback(uint256 amount, bytes calldata data) external;
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface IAipExtendCallback {
    function aipExtendCallback(uint256 amount, bytes calldata data) external;
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface IAipBurnCallback {
    function aipBurnCallback(bytes calldata data) external returns (address);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "../interfaces/IERC20.sol";

library TransferHelper {
    /// @notice Transfers tokens from the targeted address to the given destination
    /// @notice Errors with 'STF' if transfer fails
    /// @param token The contract address of the token to be transferred
    /// @param from The originating address from which the tokens will be transferred
    /// @param to The destination address of the transfer
    /// @param value The amount to be transferred
    function safeTransferFrom(
        address token,
        address from,
        address to,
        uint256 value
    ) internal {
        (bool success, bytes memory data) = token.call(
            abi.encodeWithSelector(
                IERC20.transferFrom.selector,
                from,
                to,
                value
            )
        );
        require(
            success && (data.length == 0 || abi.decode(data, (bool))),
            "STF"
        );
    }

    /// @notice Transfers tokens from msg.sender to a recipient
    /// @dev Errors with ST if transfer fails
    /// @param token The contract address of the token which will be transferred
    /// @param to The recipient of the transfer
    /// @param value The value of the transfer
    function safeTransfer(
        address token,
        address to,
        uint256 value
    ) internal {
        (bool success, bytes memory data) = token.call(
            abi.encodeWithSelector(IERC20.transfer.selector, to, value)
        );
        require(
            success && (data.length == 0 || abi.decode(data, (bool))),
            "ST"
        );
    }

    /// @notice Approves the stipulated contract to spend the given allowance in the given token
    /// @dev Errors with 'SA' if transfer fails
    /// @param token The contract address of the token to be approved
    /// @param to The target of the approval
    /// @param value The amount of the given token the target will be allowed to spend
    function safeApprove(
        address token,
        address to,
        uint256 value
    ) internal {
        (bool success, bytes memory data) = token.call(
            abi.encodeWithSelector(IERC20.approve.selector, to, value)
        );
        require(
            success && (data.length == 0 || abi.decode(data, (bool))),
            "SA"
        );
    }

    /// @notice Transfers ETH to the recipient address
    /// @dev Fails with `STE`
    /// @param to The destination of the transfer
    /// @param value The value to be transferred
    function safeTransferETH(address to, uint256 value) internal {
        (bool success, ) = to.call{value: value}(new bytes(0));
        require(success, "STE");
    }
}