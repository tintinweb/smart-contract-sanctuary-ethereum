// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

abstract contract Multicall {
    function multicall(bytes[] calldata data)
        public
        payable
        returns (bytes[] memory results)
    {
        results = new bytes[](data.length);
        for (uint256 i = 0; i < data.length; i++) {
            (bool success, bytes memory result) = address(this).delegatecall(
                data[i]
            );

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

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./abstracts/Multicall.sol";
import "./base/AipPayments.sol";
import "./access/Ownable.sol";
import "./interfaces/IAipPoolDeployer.sol";
import "./interfaces/IERC20.sol";
import "./interfaces/IAipPool.sol";
import "./interfaces/IAipFactory.sol";
import "./interfaces/callback/IAipSubcribeCallback.sol";
import "./interfaces/callback/IAipExtendCallback.sol";
import "./libraries/CallbackValidation.sol";
import "./libraries/PoolAddress.sol";

contract AipPlanManager is
    Multicall,
    AipPayments,
    IAipSubcribeCallback,
    IAipExtendCallback
{
    address public immutable factory;
    uint256 private _nextId = 1;
    struct Plan {
        address investor;
        address token0;
        address token1;
        uint24 frequencyD;
        uint256 index;
        uint256 tickAmount;
        uint256 createdTime;
    }
    struct PlanTime {
        uint256 startTick;
        uint256 startedTime;
        uint256 endTick;
        uint256 endedTime;
    }
    mapping(uint256 => Plan) private _plans;

    mapping(address => uint256[]) public investorPlans;

    constructor(address _factory, address _WETH9) AipPayments(_WETH9) {
        factory = _factory;
    }

    struct SubcribeCallbackData {
        PoolAddress.PoolInfo poolInfo;
        address payer;
    }

    function aipSubcribeCallback(uint256 amount, bytes calldata data)
        external
        override
    {
        SubcribeCallbackData memory decoded = abi.decode(
            data,
            (SubcribeCallbackData)
        );
        CallbackValidation.verifyCallback(factory, decoded.poolInfo);
        pay(decoded.poolInfo.token0, decoded.payer, msg.sender, amount);
    }

    struct ExtendCallbackData {
        PoolAddress.PoolInfo poolInfo;
        address payer;
    }

    function aipExtendCallback(uint256 amount, bytes calldata data)
        external
        override
    {
        ExtendCallbackData memory decoded = abi.decode(
            data,
            (ExtendCallbackData)
        );
        CallbackValidation.verifyCallback(factory, decoded.poolInfo);
        pay(decoded.poolInfo.token0, decoded.payer, msg.sender, amount);
    }

    function plansOf(address addr) public view returns (uint256[] memory) {
        return investorPlans[addr];
    }

    function getPlan(uint256 planIndex)
        public
        view
        returns (Plan memory plan, PlanTime memory time)
    {
        plan = _plans[planIndex];
        PoolAddress.PoolInfo memory poolInfo = PoolAddress.PoolInfo({
            token0: plan.token0,
            token1: plan.token1,
            frequencyD: plan.frequencyD
        });
        IAipPool pool = IAipPool(PoolAddress.computeAddress(factory, poolInfo));
        (time.startTick, time.startedTime, time.endTick, time.endedTime) = pool
            .getPlanTime(planIndex);
    }

    function createPoolIfNecessary(PoolAddress.PoolInfo calldata poolInfo)
        external
        payable
        returns (address pool)
    {
        pool = IAipFactory(factory).getPool(
            poolInfo.token0,
            poolInfo.token1,
            poolInfo.frequencyD
        );
        if (pool == address(0)) {
            pool = IAipFactory(factory).createPool(
                poolInfo.token0,
                poolInfo.token1,
                poolInfo.frequencyD
            );
        }
    }

    struct SubcribeParams {
        address token0;
        address token1;
        uint24 frequencyD;
        uint256 tickAmount;
        uint256 periods;
    }

    function subcribe(SubcribeParams calldata params)
        external
        payable
        returns (uint256 id, IAipPool pool)
    {
        PoolAddress.PoolInfo memory poolInfo = PoolAddress.PoolInfo({
            token0: params.token0,
            token1: params.token1,
            frequencyD: params.frequencyD
        });
        pool = IAipPool(PoolAddress.computeAddress(factory, poolInfo));
        uint256 index = pool.subcribe(
            msg.sender,
            params.tickAmount,
            params.periods,
            abi.encode(
                SubcribeCallbackData({poolInfo: poolInfo, payer: msg.sender})
            )
        );
        id = _nextId++;
        _plans[id] = Plan({
            investor: msg.sender,
            token0: params.token0,
            token1: params.token1,
            frequencyD: params.frequencyD,
            index: index,
            tickAmount: params.tickAmount,
            createdTime: block.timestamp
        });
        investorPlans[msg.sender].push(id);
    }

    function extend(uint256 id, uint256 periods)
        external
        payable
        returns (IAipPool pool)
    {
        Plan memory plan = _plans[id];
        require(plan.index > 0, "Invalid plan");
        PoolAddress.PoolInfo memory poolInfo = PoolAddress.PoolInfo({
            token0: plan.token0,
            token1: plan.token1,
            frequencyD: plan.frequencyD
        });
        pool = IAipPool(PoolAddress.computeAddress(factory, poolInfo));
        pool.extend(
            msg.sender,
            plan.index,
            periods,
            abi.encode(
                ExtendCallbackData({poolInfo: poolInfo, payer: msg.sender})
            )
        );
    }

    function unsubcribe(uint256 id) external returns (IAipPool pool) {
        Plan memory plan = _plans[id];
        require(plan.index > 0, "Invalid plan");
        PoolAddress.PoolInfo memory poolInfo = PoolAddress.PoolInfo({
            token0: plan.token0,
            token1: plan.token1,
            frequencyD: plan.frequencyD
        });
        pool = IAipPool(PoolAddress.computeAddress(factory, poolInfo));
        pool.unsubcribe(msg.sender, plan.index);
    }

    function claim(uint256 id) external returns (IAipPool pool) {
        Plan memory plan = _plans[id];
        require(plan.index > 0, "Invalid plan");
        PoolAddress.PoolInfo memory poolInfo = PoolAddress.PoolInfo({
            token0: plan.token0,
            token1: plan.token1,
            frequencyD: plan.frequencyD
        });
        pool = IAipPool(PoolAddress.computeAddress(factory, poolInfo));
        pool.claim(msg.sender, plan.index);
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "../interfaces/IWETH9.sol";
import "../interfaces/IERC20.sol";
import "../libraries/TransferHelper.sol";

abstract contract AipPayments {
    address public immutable WETH9;

    constructor(address _WETH9) {
        WETH9 = _WETH9;
    }

    receive() external payable {
        require(msg.sender == WETH9, "Not WETH9");
    }

    // function unwrapWETH9(uint256 amountMinimum, address recipient)
    //     public
    //     payable
    // {
    //     uint256 balanceWETH9 = IWETH9(WETH9).balanceOf(address(this));
    //     require(balanceWETH9 >= amountMinimum, "Insufficient WETH9");

    //     if (balanceWETH9 > 0) {
    //         IWETH9(WETH9).withdraw(balanceWETH9);
    //         TransferHelper.safeTransferETH(recipient, balanceWETH9);
    //     }
    // }

    // function sweepToken(
    //     address token,
    //     uint256 amountMinimum,
    //     address recipient
    // ) public payable {
    //     uint256 balanceToken = IERC20(token).balanceOf(address(this));
    //     require(balanceToken >= amountMinimum, "Insufficient token");

    //     if (balanceToken > 0) {
    //         TransferHelper.safeTransfer(token, recipient, balanceToken);
    //     }
    // }

    // function refundETH() external payable {
    //     if (address(this).balance > 0)
    //         TransferHelper.safeTransferETH(msg.sender, address(this).balance);
    // }

    /// @param token The token to pay
    /// @param payer The entity that must pay
    /// @param recipient The entity that will receive payment
    /// @param value The amount to pay
    function pay(
        address token,
        address payer,
        address recipient,
        uint256 value
    ) internal {
        if (token == WETH9 && address(this).balance >= value) {
            // pay with WETH9
            IWETH9(WETH9).deposit{value: value}(); // wrap only what is needed to pay
            IWETH9(WETH9).transfer(recipient, value);
        } else if (payer == address(this)) {
            // pay with tokens already in the contract (for the exact input multihop case)
            TransferHelper.safeTransfer(token, recipient, value);
        } else {
            // pull payment
            TransferHelper.safeTransferFrom(token, payer, recipient, value);
        }
    }
}

// SPDX-License-Identifier: MIT
pragma solidity >=0.8.0;

abstract contract Ownable {
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

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

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface IAipPoolDeployer {
    function parameters()
        external
        view
        returns (
            address factory,
            address swapManager,
            address WETH9,
            address token0,
            address token1,
            uint24 frequencyD
        );
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
    function getPlanTime(uint256 planIndex)
        external
        view
        returns (
            uint256 startTick,
            uint256 startedTime,
            uint256 endTick,
            uint256 endedTime
        );

    function subcribe(
        address investor,
        uint256 tickAmount0,
        uint256 totalAmount0,
        bytes calldata data
    ) external returns (uint256 index);

    function extend(
        address requester,
        uint256 planIndex,
        uint256 extendedAmount0,
        bytes calldata data
    ) external;

    function unsubcribe(address requester, uint256 planIndex)
        external
        returns (uint256 received0, uint256 received1);

    function claim(address requester, uint256 planIndex)
        external
        returns (uint256 received1);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "../libraries/PoolAddress.sol";

interface IAipFactory {
    function owner() external view returns (address);

    function getPoolInfo(address addr)
        external
        view
        returns (
            address,
            address,
            uint24
        );

    function getPool(
        address token0,
        address token1,
        uint24 frequencyD
    ) external view returns (address pool);

    function validatePool(address addr) external view;

    function createPool(
        address token0,
        address token1,
        uint24 frequencyD
    ) external returns (address pool);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface IAipSubcribeCallback {
    function aipSubcribeCallback(uint256 amount, bytes calldata data) external;
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface IAipExtendCallback {
    function aipExtendCallback(uint256 amount, bytes calldata data) external;
}

// SPDX-License-Identifier: MIT
pragma solidity >=0.8.0;

import "../interfaces/IAipPool.sol";
import "./PoolAddress.sol";

library CallbackValidation {
    function verifyCallback(
        address factory,
        address token0,
        address token1,
        uint24 frequencyD
    ) internal view returns (IAipPool pool) {
        return
            verifyCallback(
                factory,
                PoolAddress.getPoolInfo(token0, token1, frequencyD)
            );
    }

    function verifyCallback(
        address factory,
        PoolAddress.PoolInfo memory poolInfo
    ) internal view returns (IAipPool pool) {
        pool = IAipPool(PoolAddress.computeAddress(factory, poolInfo));
        require(msg.sender == address(pool));
    }
}

// SPDX-License-Identifier: MIT
pragma solidity >=0.8.0;

library PoolAddress {
    bytes32 internal constant POOL_INIT_CODE_HASH =
        0x4c9701b854b1081ea7ec1b649f4640e37938b8758259e53e4bef5629ab771f49;

    struct PoolInfo {
        address token0;
        address token1;
        uint24 frequencyD;
    }

    function getPoolInfo(
        address token0,
        address token1,
        uint24 frequencyD
    ) internal pure returns (PoolInfo memory) {
        return
            PoolInfo({token0: token0, token1: token1, frequencyD: frequencyD});
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
                                    poolInfo.frequencyD
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

import "./IERC20.sol";

interface IWETH9 is IERC20 {
    function deposit() external payable;

    function withdraw(uint256) external;
}

// SPDX-License-Identifier: MIT
pragma solidity >=0.8.0;

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

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./security/ReentrancyGuard.sol";
import "./interfaces/IAipPoolDeployer.sol";
import "./interfaces/IERC20.sol";
import "./interfaces/IAipPool.sol";
import "./interfaces/IAipFactory.sol";
import "./interfaces/IAipSwapManager.sol";
import "./interfaces/callback/IAipSubcribeCallback.sol";
import "./interfaces/callback/IAipExtendCallback.sol";
import "./libraries/TransferHelper.sol";

// import "./libraries/EnumerableMap.sol";

// import "hardhat/console.sol";

contract AipPool is IAipPool, ReentrancyGuard {
    // using EnumerableMap for EnumerableMap.UintToUintMap;

    address public immutable factory;
    address public immutable swapManager;
    address public immutable WETH9;
    address public immutable token0;
    address public immutable token1;
    uint24 public immutable frequencyD;
    uint24 public constant PROCESSING_GAS = 300000;
    uint24 public constant PROTOCOL_FEE = 1000; // 1/x
    uint256 public constant MIN_TICK_AMOUNT = 10 * 1e18;

    struct PlanInfo {
        uint256 index;
        address investor;
        uint256 tickAmount0;
        uint256 claimedAmount1;
        uint256 startTick;
        uint256 endTick;
    }
    uint256 private _nextPlanIndex = 1;
    uint256 private _nextTickIndex = 1;
    mapping(uint256 => uint256) private _tickVolumes0;
    mapping(uint256 => uint256) private _tickVolumes1;
    mapping(uint256 => uint256) private _tickPrices;
    mapping(uint256 => uint256) private _tickTimes;
    mapping(uint256 => PlanInfo) public plans;
    // mapping(address => uint256) private _balances;

    struct ProtocolFees {
        uint256 token0;
        uint256 token1;
    }
    ProtocolFees public protocolFees;

    constructor() {
        (
            factory,
            swapManager,
            WETH9,
            token0,
            token1,
            frequencyD
        ) = IAipPoolDeployer(msg.sender).parameters();
    }

    modifier onlyFactoryOwner() {
        require(msg.sender == IAipFactory(factory).owner());
        _;
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

    function reserve(bool zeroForOne)
        public
        view
        virtual
        returns (uint256 reserve0, uint256 reserve1)
    {
        (reserve0, reserve1) = IAipSwapManager(swapManager).reserve(
            token0,
            token1,
            zeroForOne
        );
    }

    function getPlanTime(uint256 planIndex)
        external
        view
        override
        returns (
            uint256 startTick,
            uint256 startedTime,
            uint256 endTick,
            uint256 endedTime
        )
    {
        PlanInfo memory plan = plans[planIndex];
        startTick = plan.startTick;
        endTick = plan.endTick;
        startedTime = _tickTimes[startTick];
        uint256 currentTickTime = _tickTimes[_nextTickIndex - 1];
        uint256 period = frequencyD * 24 * 3600;
        if (endTick > _nextTickIndex - 1) {
            endedTime =
                currentTickTime +
                period *
                (endTick - _nextTickIndex + 1);
        } else {
            endedTime = _tickTimes[endTick];
        }
    }

    function tickVolumes(uint256 tick)
        external
        view
        virtual
        returns (uint256 amount0, uint256 amount1)
    {
        require(tick <= _nextTickIndex, "Invalid tick");
        amount0 = _tickVolumes0[tick];
        amount1 = _tickVolumes1[tick];
    }

    function subcribe(
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
        plan.claimedAmount1 = 0;
        plan.startTick = _nextTickIndex;
        plan.endTick = _nextTickIndex + ticks - 1;
        mapping(uint256 => uint256) storage tickVolumes0 = _tickVolumes0;
        for (uint256 i = plan.startTick; i <= plan.endTick; i++) {
            tickVolumes0[i] += tickAmount0;
        }
        uint256 balance0Before = balance0();
        IAipSubcribeCallback(msg.sender).aipSubcribeCallback(
            ticks * tickAmount0,
            data
        );
        require(balance0Before + ticks * tickAmount0 <= balance0(), "S");
        emit Subcribe(
            plan.index,
            plan.investor,
            plan.tickAmount0,
            plan.startTick,
            plan.endTick
        );
    }

    function _getPlanAmount(
        uint256 tickAmount0,
        uint256 startTick,
        uint256 endTick
    ) private view returns (uint256 amount0, uint256 amount1) {
        uint256 currentEndTick = _nextTickIndex - 1 > endTick
            ? endTick
            : _nextTickIndex - 1;
        mapping(uint256 => uint256) storage tickVolumes1 = _tickVolumes1;
        mapping(uint256 => uint256) storage tickVolumes0 = _tickVolumes0;
        for (uint256 i = startTick; i <= currentEndTick; i++) {
            amount0 += tickAmount0;
            amount1 += (tickVolumes1[i] * tickAmount0) / tickVolumes0[i];
        }
    }

    function extend(
        address requester,
        uint256 planIndex,
        uint256 ticks,
        bytes calldata data
    ) external override nonReentrant {
        PlanInfo storage plan = plans[planIndex];
        require(plan.investor == requester, "Only owner");
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
        emit Extend(plan.investor, planIndex, oldEndTick, plan.endTick);
    }

    function claim(address requester, uint256 planIndex)
        external
        override
        nonReentrant
        returns (uint256 received1)
    {
        PlanInfo storage plan = plans[planIndex];
        require(plan.investor == requester, "Only owner");
        (, uint256 amount1) = _getPlanAmount(
            plan.tickAmount0,
            plan.startTick,
            plan.endTick
        );
        received1 = amount1 - plan.claimedAmount1;
        plan.claimedAmount1 += received1;
        require(received1 > 0, "Nothing to claim");
        uint256 balance1Before = balance1();
        TransferHelper.safeTransfer(token1, plan.investor, received1);
        require(balance1Before - received1 <= balance1(), "T1");
    }

    function unsubcribe(address requester, uint256 planIndex)
        external
        override
        nonReentrant
        returns (uint256 received0, uint256 received1)
    {
        PlanInfo storage plan = plans[planIndex];
        require(plan.investor == requester, "Only owner");
        require(plan.endTick >= _nextTickIndex, "Finished");
        uint256 oldEndTick = plan.endTick;
        plan.endTick = _nextTickIndex - 1;

        received0 = plan.tickAmount0 * (oldEndTick - plan.endTick);

        (, uint256 amount1) = _getPlanAmount(
            plan.tickAmount0,
            plan.startTick,
            plan.endTick
        );

        received1 = amount1 - plan.claimedAmount1;

        mapping(uint256 => uint256) storage tickVolumes0 = _tickVolumes0;
        for (uint256 i = plan.endTick; i <= oldEndTick; i++) {
            tickVolumes0[i] -= plan.tickAmount0;
        }

        uint256 balance0Before = balance0();
        uint256 balance1Before = balance1();

        TransferHelper.safeTransfer(token0, plan.investor, received0);
        if (received1 > 0) {
            TransferHelper.safeTransfer(token1, plan.investor, received1);
            require(balance1Before - received1 <= balance1(), "T1");
        }
        require(balance0Before - received0 <= balance0(), "T0");
    }

    function trigger() external nonReentrant returns (uint256 swapAmount0) {
        uint256 tickIndex = _nextTickIndex++;
        swapAmount0 = _tickVolumes0[tickIndex];
        require(swapAmount0 > 0, "Tick volume equal 0");
        mapping(uint256 => uint256) storage tickTmps = _tickTimes;
        if (tickIndex > 1) {
            require(
                tickTmps[tickIndex - 1] + frequencyD * 24 * 3600 <=
                    block.timestamp,
                "Not yet"
            );
        }
        tickTmps[tickIndex] = block.timestamp;

        uint256 gasFee = tx.gasprice * PROCESSING_GAS;
        (uint256 _reserve0, uint256 _reserveWeth9) = IAipSwapManager(
            swapManager
        ).reserve(token0, WETH9, false);
        uint256 triggerFee0 = (gasFee * _reserve0) / _reserveWeth9;

        uint256 protocolFee0 = swapAmount0 / PROTOCOL_FEE;

        uint256 totalSwap = swapAmount0 - protocolFee0 - triggerFee0;

        TransferHelper.safeApprove(token0, swapManager, swapAmount0);

        uint256 balance0Before = balance0();
        uint256 balance1Before = balance1();
        (, int256 amount1) = IAipSwapManager(swapManager).swap(
            token0,
            token1,
            address(this),
            true,
            totalSwap
        );
        uint256 swapAmount1 = amount1 > 0
            ? uint256(amount1)
            : uint256(-amount1);
        _tickVolumes1[tickIndex] += swapAmount1;
        protocolFees.token0 += protocolFee0;
        TransferHelper.safeTransfer(token0, msg.sender, triggerFee0);
        require(balance0Before - swapAmount0 <= balance0(), "T0");
        require(balance1Before + swapAmount1 <= balance1(), "T1");
        emit Trigger(
            tickIndex,
            totalSwap,
            triggerFee0,
            protocolFee0,
            swapAmount1
        );
    }

    function collectProtocol(
        address recipient,
        uint256 amount0Requested,
        uint256 amount1Requested
    )
        external
        nonReentrant
        onlyFactoryOwner
        returns (uint256 amount0, uint256 amount1)
    {
        amount0 = amount0Requested > protocolFees.token0
            ? protocolFees.token0
            : amount0Requested;
        amount1 = amount1Requested > protocolFees.token1
            ? protocolFees.token1
            : amount1Requested;

        if (amount0 > 0) {
            if (amount0 == protocolFees.token0) amount0--; // ensure that the slot is not cleared, for gas savings
            protocolFees.token0 -= amount0;
            TransferHelper.safeTransfer(token0, recipient, amount0);
        }
        if (amount1 > 0) {
            if (amount1 == protocolFees.token1) amount1--; // ensure that the slot is not cleared, for gas savings
            protocolFees.token1 -= amount1;
            TransferHelper.safeTransfer(token1, recipient, amount1);
        }

        emit CollectProtocol(msg.sender, recipient, amount0, amount1);
    }

    event Trigger(
        uint256 tickIndex,
        uint256 amount0,
        uint256 triggerFee0,
        uint256 protocolFee0,
        uint256 amount1
    );

    event Subcribe(
        uint256 planIndex,
        address investor,
        uint256 tickAmount,
        uint256 startTick,
        uint256 endTick
    );

    event Extend(
        address investor,
        uint256 planIndex,
        uint256 oldEndTick,
        uint256 newEndTick
    );

    event Unsubcribe(
        address investor,
        uint256 planIndex,
        uint256 received0,
        uint256 received1
    );

    event CollectProtocol(
        address requester,
        address receiver,
        uint256 amount0,
        uint256 amount1
    );
}

// SPDX-License-Identifier: MIT
pragma solidity >=0.8.0;

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
pragma solidity ^0.8.0;

interface IAipSwapManager {
    function reserve(
        address token0,
        address token1,
        bool zeroForOne
    ) external view returns (uint256 reserve0, uint256 reserve1);

    function swap(
        address token0,
        address token1,
        address recipient,
        bool zeroForOne,
        uint256 amount
    ) external returns (int256 amount0, int256 amount1);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@uniswap/v3-core/contracts/interfaces/IUniswapV3Factory.sol";
import "@uniswap/v3-core/contracts/interfaces/IUniswapV3Pool.sol";

import "../base/AipPayments.sol";
import "../libraries/UniswapPoolAddress.sol";

// import "hardhat/console.sol";

contract MockLiquidityManager is AipPayments {
    address public immutable factory;

    struct MintCallbackData {
        UniswapPoolAddress.PoolKey poolKey;
        address payer;
    }

    function uniswapV3MintCallback(
        uint256 amount0Owed,
        uint256 amount1Owed,
        bytes calldata data
    ) external {
        MintCallbackData memory decoded = abi.decode(data, (MintCallbackData));
        if (amount0Owed > 0)
            pay(decoded.poolKey.token0, decoded.payer, msg.sender, amount0Owed);
        if (amount1Owed > 0)
            pay(decoded.poolKey.token1, decoded.payer, msg.sender, amount1Owed);
    }

    constructor(address _factory, address _WETH9) AipPayments(_WETH9) {
        factory = _factory;
    }

    function createAndInitializePoolIfNecessary(
        address token0,
        address token1,
        uint24 fee,
        uint160 sqrtPriceX96
    ) external payable returns (address pool) {
        if (token0 > token1) {
            (token0, token1) = (token1, token0);
        }
        pool = IUniswapV3Factory(factory).getPool(token0, token1, fee);

        if (pool == address(0)) {
            pool = IUniswapV3Factory(factory).createPool(token0, token1, fee);
            IUniswapV3Pool(pool).initialize(sqrtPriceX96);
        } else {
            (uint160 sqrtPriceX96Existing, , , , , , ) = IUniswapV3Pool(pool)
                .slot0();
            if (sqrtPriceX96Existing == 0) {
                IUniswapV3Pool(pool).initialize(sqrtPriceX96);
            }
        }
    }

    struct AddLiquidityParams {
        address token0;
        address token1;
        uint24 fee;
        address recipient;
        int24 tickLower;
        int24 tickUpper;
        uint128 liquidity;
    }

    function addLiquidity(AddLiquidityParams memory params)
        external
        payable
        returns (
            uint128 liquidity,
            uint256 amount0,
            uint256 amount1,
            IUniswapV3Pool pool
        )
    {
        UniswapPoolAddress.PoolKey memory poolKey = UniswapPoolAddress
            .getPoolKey(params.token0, params.token1, params.fee);

        pool = IUniswapV3Pool(
            UniswapPoolAddress.computeAddress(factory, poolKey)
        );

        liquidity = params.liquidity * 1e18;

        (amount0, amount1) = pool.mint(
            params.recipient,
            params.tickLower,
            params.tickUpper,
            params.liquidity * 1e18,
            abi.encode(MintCallbackData({poolKey: poolKey, payer: msg.sender}))
        );
    }
}

// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity >=0.5.0;

/// @title The interface for the Uniswap V3 Factory
/// @notice The Uniswap V3 Factory facilitates creation of Uniswap V3 pools and control over the protocol fees
interface IUniswapV3Factory {
    /// @notice Emitted when the owner of the factory is changed
    /// @param oldOwner The owner before the owner was changed
    /// @param newOwner The owner after the owner was changed
    event OwnerChanged(address indexed oldOwner, address indexed newOwner);

    /// @notice Emitted when a pool is created
    /// @param token0 The first token of the pool by address sort order
    /// @param token1 The second token of the pool by address sort order
    /// @param fee The fee collected upon every swap in the pool, denominated in hundredths of a bip
    /// @param tickSpacing The minimum number of ticks between initialized ticks
    /// @param pool The address of the created pool
    event PoolCreated(
        address indexed token0,
        address indexed token1,
        uint24 indexed fee,
        int24 tickSpacing,
        address pool
    );

    /// @notice Emitted when a new fee amount is enabled for pool creation via the factory
    /// @param fee The enabled fee, denominated in hundredths of a bip
    /// @param tickSpacing The minimum number of ticks between initialized ticks for pools created with the given fee
    event FeeAmountEnabled(uint24 indexed fee, int24 indexed tickSpacing);

    /// @notice Returns the current owner of the factory
    /// @dev Can be changed by the current owner via setOwner
    /// @return The address of the factory owner
    function owner() external view returns (address);

    /// @notice Returns the tick spacing for a given fee amount, if enabled, or 0 if not enabled
    /// @dev A fee amount can never be removed, so this value should be hard coded or cached in the calling context
    /// @param fee The enabled fee, denominated in hundredths of a bip. Returns 0 in case of unenabled fee
    /// @return The tick spacing
    function feeAmountTickSpacing(uint24 fee) external view returns (int24);

    /// @notice Returns the pool address for a given pair of tokens and a fee, or address 0 if it does not exist
    /// @dev tokenA and tokenB may be passed in either token0/token1 or token1/token0 order
    /// @param tokenA The contract address of either token0 or token1
    /// @param tokenB The contract address of the other token
    /// @param fee The fee collected upon every swap in the pool, denominated in hundredths of a bip
    /// @return pool The pool address
    function getPool(
        address tokenA,
        address tokenB,
        uint24 fee
    ) external view returns (address pool);

    /// @notice Creates a pool for the given two tokens and fee
    /// @param tokenA One of the two tokens in the desired pool
    /// @param tokenB The other of the two tokens in the desired pool
    /// @param fee The desired fee for the pool
    /// @dev tokenA and tokenB may be passed in either order: token0/token1 or token1/token0. tickSpacing is retrieved
    /// from the fee. The call will revert if the pool already exists, the fee is invalid, or the token arguments
    /// are invalid.
    /// @return pool The address of the newly created pool
    function createPool(
        address tokenA,
        address tokenB,
        uint24 fee
    ) external returns (address pool);

    /// @notice Updates the owner of the factory
    /// @dev Must be called by the current owner
    /// @param _owner The new owner of the factory
    function setOwner(address _owner) external;

    /// @notice Enables a fee amount with the given tickSpacing
    /// @dev Fee amounts may never be removed once enabled
    /// @param fee The fee amount to enable, denominated in hundredths of a bip (i.e. 1e-6)
    /// @param tickSpacing The spacing between ticks to be enforced for all pools created with the given fee amount
    function enableFeeAmount(uint24 fee, int24 tickSpacing) external;
}

// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity >=0.5.0;

import './pool/IUniswapV3PoolImmutables.sol';
import './pool/IUniswapV3PoolState.sol';
import './pool/IUniswapV3PoolDerivedState.sol';
import './pool/IUniswapV3PoolActions.sol';
import './pool/IUniswapV3PoolOwnerActions.sol';
import './pool/IUniswapV3PoolEvents.sol';

/// @title The interface for a Uniswap V3 Pool
/// @notice A Uniswap pool facilitates swapping and automated market making between any two assets that strictly conform
/// to the ERC20 specification
/// @dev The pool interface is broken up into many smaller pieces
interface IUniswapV3Pool is
    IUniswapV3PoolImmutables,
    IUniswapV3PoolState,
    IUniswapV3PoolDerivedState,
    IUniswapV3PoolActions,
    IUniswapV3PoolOwnerActions,
    IUniswapV3PoolEvents
{

}

// SPDX-License-Identifier: MIT
pragma solidity >=0.8.0;

/// @title Provides functions for deriving a pool address from the factory, tokens, and the fee
library UniswapPoolAddress {
    bytes32 internal constant POOL_INIT_CODE_HASH =
        0xe34f199b19b2b4f47f68442619d555527d244f78a3297ea89325f843f87b8b54;

    /// @notice The identifying key of the pool
    struct PoolKey {
        address token0;
        address token1;
        uint24 fee;
    }

    /// @notice Returns PoolKey: the ordered tokens with the matched fee levels
    /// @param tokenA The first token of a pool, unsorted
    /// @param tokenB The second token of a pool, unsorted
    /// @param fee The fee level of the pool
    /// @return Poolkey The pool details with ordered token0 and token1 assignments
    function getPoolKey(
        address tokenA,
        address tokenB,
        uint24 fee
    ) internal pure returns (PoolKey memory) {
        if (tokenA > tokenB) (tokenA, tokenB) = (tokenB, tokenA);
        return PoolKey({token0: tokenA, token1: tokenB, fee: fee});
    }

    /// @notice Deterministically computes the pool address given the factory and PoolKey
    /// @param factory The Uniswap V3 factory contract address
    /// @param key The PoolKey
    /// @return pool The contract address of the V3 pool
    function computeAddress(address factory, PoolKey memory key)
        internal
        pure
        returns (address pool)
    {
        require(key.token0 < key.token1);
        pool = address(
            uint160(
                uint256(
                    keccak256(
                        abi.encodePacked(
                            hex"ff",
                            factory,
                            keccak256(
                                abi.encode(key.token0, key.token1, key.fee)
                            ),
                            POOL_INIT_CODE_HASH
                        )
                    )
                )
            )
        );
    }
}

// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity >=0.5.0;

/// @title Pool state that never changes
/// @notice These parameters are fixed for a pool forever, i.e., the methods will always return the same values
interface IUniswapV3PoolImmutables {
    /// @notice The contract that deployed the pool, which must adhere to the IUniswapV3Factory interface
    /// @return The contract address
    function factory() external view returns (address);

    /// @notice The first of the two tokens of the pool, sorted by address
    /// @return The token contract address
    function token0() external view returns (address);

    /// @notice The second of the two tokens of the pool, sorted by address
    /// @return The token contract address
    function token1() external view returns (address);

    /// @notice The pool's fee in hundredths of a bip, i.e. 1e-6
    /// @return The fee
    function fee() external view returns (uint24);

    /// @notice The pool tick spacing
    /// @dev Ticks can only be used at multiples of this value, minimum of 1 and always positive
    /// e.g.: a tickSpacing of 3 means ticks can be initialized every 3rd tick, i.e., ..., -6, -3, 0, 3, 6, ...
    /// This value is an int24 to avoid casting even though it is always positive.
    /// @return The tick spacing
    function tickSpacing() external view returns (int24);

    /// @notice The maximum amount of position liquidity that can use any tick in the range
    /// @dev This parameter is enforced per tick to prevent liquidity from overflowing a uint128 at any point, and
    /// also prevents out-of-range liquidity from being used to prevent adding in-range liquidity to a pool
    /// @return The max amount of liquidity per tick
    function maxLiquidityPerTick() external view returns (uint128);
}

// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity >=0.5.0;

/// @title Pool state that can change
/// @notice These methods compose the pool's state, and can change with any frequency including multiple times
/// per transaction
interface IUniswapV3PoolState {
    /// @notice The 0th storage slot in the pool stores many values, and is exposed as a single method to save gas
    /// when accessed externally.
    /// @return sqrtPriceX96 The current price of the pool as a sqrt(token1/token0) Q64.96 value
    /// tick The current tick of the pool, i.e. according to the last tick transition that was run.
    /// This value may not always be equal to SqrtTickMath.getTickAtSqrtRatio(sqrtPriceX96) if the price is on a tick
    /// boundary.
    /// observationIndex The index of the last oracle observation that was written,
    /// observationCardinality The current maximum number of observations stored in the pool,
    /// observationCardinalityNext The next maximum number of observations, to be updated when the observation.
    /// feeProtocol The protocol fee for both tokens of the pool.
    /// Encoded as two 4 bit values, where the protocol fee of token1 is shifted 4 bits and the protocol fee of token0
    /// is the lower 4 bits. Used as the denominator of a fraction of the swap fee, e.g. 4 means 1/4th of the swap fee.
    /// unlocked Whether the pool is currently locked to reentrancy
    function slot0()
        external
        view
        returns (
            uint160 sqrtPriceX96,
            int24 tick,
            uint16 observationIndex,
            uint16 observationCardinality,
            uint16 observationCardinalityNext,
            uint8 feeProtocol,
            bool unlocked
        );

    /// @notice The fee growth as a Q128.128 fees of token0 collected per unit of liquidity for the entire life of the pool
    /// @dev This value can overflow the uint256
    function feeGrowthGlobal0X128() external view returns (uint256);

    /// @notice The fee growth as a Q128.128 fees of token1 collected per unit of liquidity for the entire life of the pool
    /// @dev This value can overflow the uint256
    function feeGrowthGlobal1X128() external view returns (uint256);

    /// @notice The amounts of token0 and token1 that are owed to the protocol
    /// @dev Protocol fees will never exceed uint128 max in either token
    function protocolFees() external view returns (uint128 token0, uint128 token1);

    /// @notice The currently in range liquidity available to the pool
    /// @dev This value has no relationship to the total liquidity across all ticks
    function liquidity() external view returns (uint128);

    /// @notice Look up information about a specific tick in the pool
    /// @param tick The tick to look up
    /// @return liquidityGross the total amount of position liquidity that uses the pool either as tick lower or
    /// tick upper,
    /// liquidityNet how much liquidity changes when the pool price crosses the tick,
    /// feeGrowthOutside0X128 the fee growth on the other side of the tick from the current tick in token0,
    /// feeGrowthOutside1X128 the fee growth on the other side of the tick from the current tick in token1,
    /// tickCumulativeOutside the cumulative tick value on the other side of the tick from the current tick
    /// secondsPerLiquidityOutsideX128 the seconds spent per liquidity on the other side of the tick from the current tick,
    /// secondsOutside the seconds spent on the other side of the tick from the current tick,
    /// initialized Set to true if the tick is initialized, i.e. liquidityGross is greater than 0, otherwise equal to false.
    /// Outside values can only be used if the tick is initialized, i.e. if liquidityGross is greater than 0.
    /// In addition, these values are only relative and must be used only in comparison to previous snapshots for
    /// a specific position.
    function ticks(int24 tick)
        external
        view
        returns (
            uint128 liquidityGross,
            int128 liquidityNet,
            uint256 feeGrowthOutside0X128,
            uint256 feeGrowthOutside1X128,
            int56 tickCumulativeOutside,
            uint160 secondsPerLiquidityOutsideX128,
            uint32 secondsOutside,
            bool initialized
        );

    /// @notice Returns 256 packed tick initialized boolean values. See TickBitmap for more information
    function tickBitmap(int16 wordPosition) external view returns (uint256);

    /// @notice Returns the information about a position by the position's key
    /// @param key The position's key is a hash of a preimage composed by the owner, tickLower and tickUpper
    /// @return _liquidity The amount of liquidity in the position,
    /// Returns feeGrowthInside0LastX128 fee growth of token0 inside the tick range as of the last mint/burn/poke,
    /// Returns feeGrowthInside1LastX128 fee growth of token1 inside the tick range as of the last mint/burn/poke,
    /// Returns tokensOwed0 the computed amount of token0 owed to the position as of the last mint/burn/poke,
    /// Returns tokensOwed1 the computed amount of token1 owed to the position as of the last mint/burn/poke
    function positions(bytes32 key)
        external
        view
        returns (
            uint128 _liquidity,
            uint256 feeGrowthInside0LastX128,
            uint256 feeGrowthInside1LastX128,
            uint128 tokensOwed0,
            uint128 tokensOwed1
        );

    /// @notice Returns data about a specific observation index
    /// @param index The element of the observations array to fetch
    /// @dev You most likely want to use #observe() instead of this method to get an observation as of some amount of time
    /// ago, rather than at a specific index in the array.
    /// @return blockTimestamp The timestamp of the observation,
    /// Returns tickCumulative the tick multiplied by seconds elapsed for the life of the pool as of the observation timestamp,
    /// Returns secondsPerLiquidityCumulativeX128 the seconds per in range liquidity for the life of the pool as of the observation timestamp,
    /// Returns initialized whether the observation has been initialized and the values are safe to use
    function observations(uint256 index)
        external
        view
        returns (
            uint32 blockTimestamp,
            int56 tickCumulative,
            uint160 secondsPerLiquidityCumulativeX128,
            bool initialized
        );
}

// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity >=0.5.0;

/// @title Pool state that is not stored
/// @notice Contains view functions to provide information about the pool that is computed rather than stored on the
/// blockchain. The functions here may have variable gas costs.
interface IUniswapV3PoolDerivedState {
    /// @notice Returns the cumulative tick and liquidity as of each timestamp `secondsAgo` from the current block timestamp
    /// @dev To get a time weighted average tick or liquidity-in-range, you must call this with two values, one representing
    /// the beginning of the period and another for the end of the period. E.g., to get the last hour time-weighted average tick,
    /// you must call it with secondsAgos = [3600, 0].
    /// @dev The time weighted average tick represents the geometric time weighted average price of the pool, in
    /// log base sqrt(1.0001) of token1 / token0. The TickMath library can be used to go from a tick value to a ratio.
    /// @param secondsAgos From how long ago each cumulative tick and liquidity value should be returned
    /// @return tickCumulatives Cumulative tick values as of each `secondsAgos` from the current block timestamp
    /// @return secondsPerLiquidityCumulativeX128s Cumulative seconds per liquidity-in-range value as of each `secondsAgos` from the current block
    /// timestamp
    function observe(uint32[] calldata secondsAgos)
        external
        view
        returns (int56[] memory tickCumulatives, uint160[] memory secondsPerLiquidityCumulativeX128s);

    /// @notice Returns a snapshot of the tick cumulative, seconds per liquidity and seconds inside a tick range
    /// @dev Snapshots must only be compared to other snapshots, taken over a period for which a position existed.
    /// I.e., snapshots cannot be compared if a position is not held for the entire period between when the first
    /// snapshot is taken and the second snapshot is taken.
    /// @param tickLower The lower tick of the range
    /// @param tickUpper The upper tick of the range
    /// @return tickCumulativeInside The snapshot of the tick accumulator for the range
    /// @return secondsPerLiquidityInsideX128 The snapshot of seconds per liquidity for the range
    /// @return secondsInside The snapshot of seconds per liquidity for the range
    function snapshotCumulativesInside(int24 tickLower, int24 tickUpper)
        external
        view
        returns (
            int56 tickCumulativeInside,
            uint160 secondsPerLiquidityInsideX128,
            uint32 secondsInside
        );
}

// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity >=0.5.0;

/// @title Permissionless pool actions
/// @notice Contains pool methods that can be called by anyone
interface IUniswapV3PoolActions {
    /// @notice Sets the initial price for the pool
    /// @dev Price is represented as a sqrt(amountToken1/amountToken0) Q64.96 value
    /// @param sqrtPriceX96 the initial sqrt price of the pool as a Q64.96
    function initialize(uint160 sqrtPriceX96) external;

    /// @notice Adds liquidity for the given recipient/tickLower/tickUpper position
    /// @dev The caller of this method receives a callback in the form of IUniswapV3MintCallback#uniswapV3MintCallback
    /// in which they must pay any token0 or token1 owed for the liquidity. The amount of token0/token1 due depends
    /// on tickLower, tickUpper, the amount of liquidity, and the current price.
    /// @param recipient The address for which the liquidity will be created
    /// @param tickLower The lower tick of the position in which to add liquidity
    /// @param tickUpper The upper tick of the position in which to add liquidity
    /// @param amount The amount of liquidity to mint
    /// @param data Any data that should be passed through to the callback
    /// @return amount0 The amount of token0 that was paid to mint the given amount of liquidity. Matches the value in the callback
    /// @return amount1 The amount of token1 that was paid to mint the given amount of liquidity. Matches the value in the callback
    function mint(
        address recipient,
        int24 tickLower,
        int24 tickUpper,
        uint128 amount,
        bytes calldata data
    ) external returns (uint256 amount0, uint256 amount1);

    /// @notice Collects tokens owed to a position
    /// @dev Does not recompute fees earned, which must be done either via mint or burn of any amount of liquidity.
    /// Collect must be called by the position owner. To withdraw only token0 or only token1, amount0Requested or
    /// amount1Requested may be set to zero. To withdraw all tokens owed, caller may pass any value greater than the
    /// actual tokens owed, e.g. type(uint128).max. Tokens owed may be from accumulated swap fees or burned liquidity.
    /// @param recipient The address which should receive the fees collected
    /// @param tickLower The lower tick of the position for which to collect fees
    /// @param tickUpper The upper tick of the position for which to collect fees
    /// @param amount0Requested How much token0 should be withdrawn from the fees owed
    /// @param amount1Requested How much token1 should be withdrawn from the fees owed
    /// @return amount0 The amount of fees collected in token0
    /// @return amount1 The amount of fees collected in token1
    function collect(
        address recipient,
        int24 tickLower,
        int24 tickUpper,
        uint128 amount0Requested,
        uint128 amount1Requested
    ) external returns (uint128 amount0, uint128 amount1);

    /// @notice Burn liquidity from the sender and account tokens owed for the liquidity to the position
    /// @dev Can be used to trigger a recalculation of fees owed to a position by calling with an amount of 0
    /// @dev Fees must be collected separately via a call to #collect
    /// @param tickLower The lower tick of the position for which to burn liquidity
    /// @param tickUpper The upper tick of the position for which to burn liquidity
    /// @param amount How much liquidity to burn
    /// @return amount0 The amount of token0 sent to the recipient
    /// @return amount1 The amount of token1 sent to the recipient
    function burn(
        int24 tickLower,
        int24 tickUpper,
        uint128 amount
    ) external returns (uint256 amount0, uint256 amount1);

    /// @notice Swap token0 for token1, or token1 for token0
    /// @dev The caller of this method receives a callback in the form of IUniswapV3SwapCallback#uniswapV3SwapCallback
    /// @param recipient The address to receive the output of the swap
    /// @param zeroForOne The direction of the swap, true for token0 to token1, false for token1 to token0
    /// @param amountSpecified The amount of the swap, which implicitly configures the swap as exact input (positive), or exact output (negative)
    /// @param sqrtPriceLimitX96 The Q64.96 sqrt price limit. If zero for one, the price cannot be less than this
    /// value after the swap. If one for zero, the price cannot be greater than this value after the swap
    /// @param data Any data to be passed through to the callback
    /// @return amount0 The delta of the balance of token0 of the pool, exact when negative, minimum when positive
    /// @return amount1 The delta of the balance of token1 of the pool, exact when negative, minimum when positive
    function swap(
        address recipient,
        bool zeroForOne,
        int256 amountSpecified,
        uint160 sqrtPriceLimitX96,
        bytes calldata data
    ) external returns (int256 amount0, int256 amount1);

    /// @notice Receive token0 and/or token1 and pay it back, plus a fee, in the callback
    /// @dev The caller of this method receives a callback in the form of IUniswapV3FlashCallback#uniswapV3FlashCallback
    /// @dev Can be used to donate underlying tokens pro-rata to currently in-range liquidity providers by calling
    /// with 0 amount{0,1} and sending the donation amount(s) from the callback
    /// @param recipient The address which will receive the token0 and token1 amounts
    /// @param amount0 The amount of token0 to send
    /// @param amount1 The amount of token1 to send
    /// @param data Any data to be passed through to the callback
    function flash(
        address recipient,
        uint256 amount0,
        uint256 amount1,
        bytes calldata data
    ) external;

    /// @notice Increase the maximum number of price and liquidity observations that this pool will store
    /// @dev This method is no-op if the pool already has an observationCardinalityNext greater than or equal to
    /// the input observationCardinalityNext.
    /// @param observationCardinalityNext The desired minimum number of observations for the pool to store
    function increaseObservationCardinalityNext(uint16 observationCardinalityNext) external;
}

// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity >=0.5.0;

/// @title Permissioned pool actions
/// @notice Contains pool methods that may only be called by the factory owner
interface IUniswapV3PoolOwnerActions {
    /// @notice Set the denominator of the protocol's % share of the fees
    /// @param feeProtocol0 new protocol fee for token0 of the pool
    /// @param feeProtocol1 new protocol fee for token1 of the pool
    function setFeeProtocol(uint8 feeProtocol0, uint8 feeProtocol1) external;

    /// @notice Collect the protocol fee accrued to the pool
    /// @param recipient The address to which collected protocol fees should be sent
    /// @param amount0Requested The maximum amount of token0 to send, can be 0 to collect fees in only token1
    /// @param amount1Requested The maximum amount of token1 to send, can be 0 to collect fees in only token0
    /// @return amount0 The protocol fee collected in token0
    /// @return amount1 The protocol fee collected in token1
    function collectProtocol(
        address recipient,
        uint128 amount0Requested,
        uint128 amount1Requested
    ) external returns (uint128 amount0, uint128 amount1);
}

// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity >=0.5.0;

/// @title Events emitted by a pool
/// @notice Contains all events emitted by the pool
interface IUniswapV3PoolEvents {
    /// @notice Emitted exactly once by a pool when #initialize is first called on the pool
    /// @dev Mint/Burn/Swap cannot be emitted by the pool before Initialize
    /// @param sqrtPriceX96 The initial sqrt price of the pool, as a Q64.96
    /// @param tick The initial tick of the pool, i.e. log base 1.0001 of the starting price of the pool
    event Initialize(uint160 sqrtPriceX96, int24 tick);

    /// @notice Emitted when liquidity is minted for a given position
    /// @param sender The address that minted the liquidity
    /// @param owner The owner of the position and recipient of any minted liquidity
    /// @param tickLower The lower tick of the position
    /// @param tickUpper The upper tick of the position
    /// @param amount The amount of liquidity minted to the position range
    /// @param amount0 How much token0 was required for the minted liquidity
    /// @param amount1 How much token1 was required for the minted liquidity
    event Mint(
        address sender,
        address indexed owner,
        int24 indexed tickLower,
        int24 indexed tickUpper,
        uint128 amount,
        uint256 amount0,
        uint256 amount1
    );

    /// @notice Emitted when fees are collected by the owner of a position
    /// @dev Collect events may be emitted with zero amount0 and amount1 when the caller chooses not to collect fees
    /// @param owner The owner of the position for which fees are collected
    /// @param tickLower The lower tick of the position
    /// @param tickUpper The upper tick of the position
    /// @param amount0 The amount of token0 fees collected
    /// @param amount1 The amount of token1 fees collected
    event Collect(
        address indexed owner,
        address recipient,
        int24 indexed tickLower,
        int24 indexed tickUpper,
        uint128 amount0,
        uint128 amount1
    );

    /// @notice Emitted when a position's liquidity is removed
    /// @dev Does not withdraw any fees earned by the liquidity position, which must be withdrawn via #collect
    /// @param owner The owner of the position for which liquidity is removed
    /// @param tickLower The lower tick of the position
    /// @param tickUpper The upper tick of the position
    /// @param amount The amount of liquidity to remove
    /// @param amount0 The amount of token0 withdrawn
    /// @param amount1 The amount of token1 withdrawn
    event Burn(
        address indexed owner,
        int24 indexed tickLower,
        int24 indexed tickUpper,
        uint128 amount,
        uint256 amount0,
        uint256 amount1
    );

    /// @notice Emitted by the pool for any swaps between token0 and token1
    /// @param sender The address that initiated the swap call, and that received the callback
    /// @param recipient The address that received the output of the swap
    /// @param amount0 The delta of the token0 balance of the pool
    /// @param amount1 The delta of the token1 balance of the pool
    /// @param sqrtPriceX96 The sqrt(price) of the pool after the swap, as a Q64.96
    /// @param liquidity The liquidity of the pool after the swap
    /// @param tick The log base 1.0001 of price of the pool after the swap
    event Swap(
        address indexed sender,
        address indexed recipient,
        int256 amount0,
        int256 amount1,
        uint160 sqrtPriceX96,
        uint128 liquidity,
        int24 tick
    );

    /// @notice Emitted by the pool for any flashes of token0/token1
    /// @param sender The address that initiated the swap call, and that received the callback
    /// @param recipient The address that received the tokens from flash
    /// @param amount0 The amount of token0 that was flashed
    /// @param amount1 The amount of token1 that was flashed
    /// @param paid0 The amount of token0 paid for the flash, which can exceed the amount0 plus the fee
    /// @param paid1 The amount of token1 paid for the flash, which can exceed the amount1 plus the fee
    event Flash(
        address indexed sender,
        address indexed recipient,
        uint256 amount0,
        uint256 amount1,
        uint256 paid0,
        uint256 paid1
    );

    /// @notice Emitted by the pool for increases to the number of observations that can be stored
    /// @dev observationCardinalityNext is not the observation cardinality until an observation is written at the index
    /// just before a mint/swap/burn.
    /// @param observationCardinalityNextOld The previous value of the next observation cardinality
    /// @param observationCardinalityNextNew The updated value of the next observation cardinality
    event IncreaseObservationCardinalityNext(
        uint16 observationCardinalityNextOld,
        uint16 observationCardinalityNextNew
    );

    /// @notice Emitted when the protocol fee is changed by the pool
    /// @param feeProtocol0Old The previous value of the token0 protocol fee
    /// @param feeProtocol1Old The previous value of the token1 protocol fee
    /// @param feeProtocol0New The updated value of the token0 protocol fee
    /// @param feeProtocol1New The updated value of the token1 protocol fee
    event SetFeeProtocol(uint8 feeProtocol0Old, uint8 feeProtocol1Old, uint8 feeProtocol0New, uint8 feeProtocol1New);

    /// @notice Emitted when the collected protocol fees are withdrawn by the factory owner
    /// @param sender The address that collects the protocol fees
    /// @param recipient The address that receives the collected protocol fees
    /// @param amount0 The amount of token0 protocol fees that is withdrawn
    /// @param amount0 The amount of token1 protocol fees that is withdrawn
    event CollectProtocol(address indexed sender, address indexed recipient, uint128 amount0, uint128 amount1);
}

// SPDX-License-Identifier: MIT
pragma solidity >=0.8.0;

import "@uniswap/v3-core/contracts/interfaces/IUniswapV3Pool.sol";
import "./UniswapPoolAddress.sol";

/// @notice Provides validation for callbacks from Uniswap V3 Pools
library UniswapCallbackValidation {
    /// @notice Returns the address of a valid Uniswap V3 Pool
    /// @param factory The contract address of the Uniswap V3 factory
    /// @param tokenA The contract address of either token0 or token1
    /// @param tokenB The contract address of the other token
    /// @param fee The fee collected upon every swap in the pool, denominated in hundredths of a bip
    /// @return pool The V3 pool contract address
    function verifyCallback(
        address factory,
        address tokenA,
        address tokenB,
        uint24 fee
    ) internal view returns (IUniswapV3Pool pool) {
        return
            verifyCallback(
                factory,
                UniswapPoolAddress.getPoolKey(tokenA, tokenB, fee)
            );
    }

    /// @notice Returns the address of a valid Uniswap V3 Pool
    /// @param factory The contract address of the Uniswap V3 factory
    /// @param poolKey The identifying key of the V3 pool
    /// @return pool The V3 pool contract address
    function verifyCallback(
        address factory,
        UniswapPoolAddress.PoolKey memory poolKey
    ) internal view returns (IUniswapV3Pool pool) {
        pool = IUniswapV3Pool(
            UniswapPoolAddress.computeAddress(factory, poolKey)
        );
        require(msg.sender == address(pool));
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@uniswap/v3-core/contracts/interfaces/IUniswapV3Pool.sol";
import "@uniswap/v3-core/contracts/interfaces/callback/IUniswapV3SwapCallback.sol";

import "../interfaces/IERC20.sol";

contract TestUniswapV3SwapPay is IUniswapV3SwapCallback {
    function swap(
        address pool,
        address recipient,
        bool zeroForOne,
        uint160 sqrtPriceX96,
        int256 amountSpecified,
        uint256 pay0,
        uint256 pay1
    ) external {
        IUniswapV3Pool(pool).swap(
            recipient,
            zeroForOne,
            amountSpecified,
            sqrtPriceX96,
            abi.encode(msg.sender, pay0, pay1)
        );
    }

    function uniswapV3SwapCallback(
        int256,
        int256,
        bytes calldata data
    ) external override {
        (address sender, uint256 pay0, uint256 pay1) = abi.decode(
            data,
            (address, uint256, uint256)
        );

        if (pay0 > 0) {
            IERC20(IUniswapV3Pool(msg.sender).token0()).transferFrom(
                sender,
                msg.sender,
                uint256(pay0)
            );
        } else if (pay1 > 0) {
            IERC20(IUniswapV3Pool(msg.sender).token1()).transferFrom(
                sender,
                msg.sender,
                uint256(pay1)
            );
        }
    }
}

// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity >=0.5.0;

/// @title Callback for IUniswapV3PoolActions#swap
/// @notice Any contract that calls IUniswapV3PoolActions#swap must implement this interface
interface IUniswapV3SwapCallback {
    /// @notice Called to `msg.sender` after executing a swap via IUniswapV3Pool#swap.
    /// @dev In the implementation you must pay the pool tokens owed for the swap.
    /// The caller of this method must be checked to be a UniswapV3Pool deployed by the canonical UniswapV3Factory.
    /// amount0Delta and amount1Delta can both be 0 if no tokens were swapped.
    /// @param amount0Delta The amount of token0 that was sent (negative) or must be received (positive) by the pool by
    /// the end of the swap. If positive, the callback must send that amount of token0 to the pool.
    /// @param amount1Delta The amount of token1 that was sent (negative) or must be received (positive) by the pool by
    /// the end of the swap. If positive, the callback must send that amount of token1 to the pool.
    /// @param data Any data passed through by the caller via the IUniswapV3PoolActions#swap call
    function uniswapV3SwapCallback(
        int256 amount0Delta,
        int256 amount1Delta,
        bytes calldata data
    ) external;
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@uniswap/v3-core/contracts/interfaces/IUniswapV3Pool.sol";
import "@uniswap/v3-core/contracts/interfaces/pool/IUniswapV3PoolActions.sol";

import "./base/AipPayments.sol";
import "./libraries/UniswapPoolAddress.sol";
import "./libraries/UniswapCallbackValidation.sol";
import "./interfaces/IAipSwapManager.sol";
import "./interfaces/IERC20.sol";

// import "./libraries/Simulation.sol";

// import "hardhat/console.sol";

contract AipUniswapManager is IAipSwapManager, AipPayments {
    address public immutable swapFactory;
    uint16[3] private _FEES = [500, 3000, 10000];
    uint160 private constant _MIN_SQRT_RATIO = 4295128739;
    uint160 private constant _MAX_SQRT_RATIO =
        1461446703485210103287273052203988822378723970342;

    constructor(address _swapFactory, address _WETH9) AipPayments(_WETH9) {
        swapFactory = _swapFactory;
    }

    // modifier checkDeadline(uint256 deadline) {
    //     require(block.timestamp <= deadline, "Transaction too old");
    //     _;
    // }

    function _isContract(address addr) private view returns (bool) {
        uint256 size;
        assembly {
            size := extcodesize(addr)
        }
        return size > 0;
    }

    function _bestReservePool(
        address token0,
        address token1,
        bool zeroForOne
    )
        private
        view
        returns (
            address pool,
            uint256 reserve0,
            uint256 reserve1
        )
    {
        uint256 point;
        for (uint256 i = 0; i < 3; i++) {
            uint24 _fee = uint24(_FEES[i]);
            address poolAddress = UniswapPoolAddress.computeAddress(
                swapFactory,
                UniswapPoolAddress.getPoolKey(token0, token1, _fee)
            );

            if (_isContract(poolAddress)) {
                IUniswapV3Pool _pool = IUniswapV3Pool(poolAddress);
                uint256 _point;
                uint128 _L = _pool.liquidity();
                (uint160 _sqrtPriceX96, , , , , , ) = _pool.slot0();
                uint256 _reserve0 = (_L * 1e18) /
                    ((_sqrtPriceX96 * 1e18) >> 96);
                uint256 _reserve1 = (_L * ((_sqrtPriceX96 * 1e18) >> 96)) /
                    1e18;
                if (zeroForOne) {
                    // y = L * sqrtP
                    _point = (_reserve1 * 100000) / (100000 - _fee);
                } else {
                    // x = L / sqrtP
                    _point = (_reserve0 * (100000 - _fee)) / 100000;
                }
                if (_point > point) {
                    point = _point;
                    reserve0 = _reserve0;
                    reserve1 = _reserve1;
                    pool = poolAddress;
                }
            }
        }
    }

    function reserve(
        address token0,
        address token1,
        bool zeroForOne
    ) external view override returns (uint256 reserve0, uint256 reserve1) {
        if (token0 > token1) {
            (token0, token1) = (token1, token0);
            zeroForOne = !zeroForOne;
        }
        (, reserve0, reserve1) = _bestReservePool(token0, token1, zeroForOne);

        if (token0 > token1) {
            (reserve0, reserve1) = (reserve1, reserve0);
        }
    }

    function swap(
        address token0,
        address token1,
        address recipient,
        bool zeroForOne,
        uint256 amount
    ) external override returns (int256 amount0, int256 amount1) {
        if (token0 > token1) {
            (token0, token1) = (token1, token0);
            zeroForOne = !zeroForOne;
        }

        (address pool, , ) = _bestReservePool(token0, token1, zeroForOne);

        (amount0, amount1) = IUniswapV3Pool(pool).swap(
            recipient,
            zeroForOne,
            int256(amount),
            zeroForOne ? _MIN_SQRT_RATIO + 1 : _MAX_SQRT_RATIO - 1,
            abi.encode(
                msg.sender,
                zeroForOne ? amount : 0,
                zeroForOne ? 0 : amount
            )
        );

        if (token0 > token1) {
            (amount0, amount1) = (amount1, amount0);
        }
        // console.logInt(amount0);
        // console.logInt(amount1);
    }

    function uniswapV3SwapCallback(
        int256,
        int256,
        bytes calldata data
    ) external {
        (address sender, uint256 pay0, uint256 pay1) = abi.decode(
            data,
            (address, uint256, uint256)
        );
        address token0 = IUniswapV3Pool(msg.sender).token0();
        address token1 = IUniswapV3Pool(msg.sender).token1();
        uint24 fee = IUniswapV3Pool(msg.sender).fee();

        UniswapCallbackValidation.verifyCallback(
            swapFactory,
            token0,
            token1,
            fee
        );
        if (pay0 > 0) {
            pay(token0, sender, msg.sender, uint256(pay0));
        } else if (pay1 > 0) {
            pay(token1, sender, msg.sender, uint256(pay1));
        }
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./interfaces/IAipFactory.sol";
import "./base/AipPoolDeployer.sol";
import "./access/Ownable.sol";
import "./security/NoDelegateCall.sol";
import "./libraries/PoolAddress.sol";

contract AipFactory is IAipFactory, AipPoolDeployer, NoDelegateCall {
    address public override owner;
    address public immutable swapManager;
    address public immutable DAI;
    address public immutable USDC;
    address public immutable USDT;
    address public immutable WETH9;

    uint24 public constant denominator = 1000;

    mapping(address => mapping(address => mapping(uint24 => address)))
        public
        override getPool;
    mapping(address => PoolAddress.PoolInfo) public override getPoolInfo;

    constructor(
        address _swapManager,
        address _DAI,
        address _USDC,
        address _USDT,
        address _WETH9
    ) {
        owner = msg.sender;
        swapManager = _swapManager;
        DAI = _DAI;
        USDC = _USDC;
        USDT = _USDT;
        WETH9 = _WETH9;
        emit OwnerChanged(address(0), msg.sender);
    }

    function validatePool(address addr) external view override {
        PoolAddress.PoolInfo memory poolInfo = getPoolInfo[addr];
        require(
            poolInfo.token0 != address(0) && poolInfo.token1 != address(0),
            "Invalid pool address"
        );
    }

    function _isStableCoin(address token) private view returns (bool) {
        return token == DAI || token == USDC || token == USDT;
    }

    function createPool(
        address token0,
        address token1,
        uint24 frequencyD
    ) external override noDelegateCall returns (address pool) {
        require(
            token0 != token1 && token0 != address(0) && token1 != address(0)
        );
        require(frequencyD > 0 && frequencyD <= 30, "Invalid date");
        require(_isStableCoin(token0), "Only DAI, USDC, USDT accepted");
        require(getPool[token0][token1][frequencyD] == address(0));
        pool = deploy(
            address(this),
            swapManager,
            WETH9,
            token0,
            token1,
            frequencyD
        );
        getPool[token0][token1][frequencyD] = pool;
        getPoolInfo[pool] = PoolAddress.PoolInfo({
            token0: token0,
            token1: token1,
            frequencyD: frequencyD
        });
        emit PoolCreated(token0, token1, frequencyD, pool);
    }

    function setOwner(address _owner) external {
        require(msg.sender == owner);
        emit OwnerChanged(owner, _owner);
        owner = _owner;
    }

    event OwnerChanged(address indexed oldOwner, address indexed newOwner);
    event PoolCreated(
        address token0,
        address token1,
        uint24 frequencyD,
        address pool
    );
    // address pool
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
        address WETH9;
        address token0;
        address token1;
        uint24 frequencyD;
    }

    Parameters public override parameters;

    function deploy(
        address factory,
        address swapManager,
        address WETH9,
        address token0,
        address token1,
        uint24 frequencyD
    ) internal returns (address pool) {
        parameters = Parameters({
            factory: factory,
            swapManager: swapManager,
            WETH9: WETH9,
            token0: token0,
            token1: token1,
            frequencyD: frequencyD
        });
        pool = address(
            new AipPool{
                salt: keccak256(abi.encode(token0, token1, frequencyD))
            }()
        );
        delete parameters;
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

//SPDX-License-Identifier: MIT
pragma solidity >=0.8.0;

import "./Ownable.sol";

contract Runnable is Ownable {
    modifier whenRunning() {
        require(_isRunning, "Paused");
        _;
    }

    modifier whenNotRunning() {
        require(!_isRunning, "Running");
        _;
    }

    bool public _isRunning;

    constructor() {
        _isRunning = true;
    }

    function toggleRunning() external onlyOwner {
        _isRunning = !_isRunning;
    }
}

// SPDX-License-Identifier: MIT
pragma solidity >=0.8.0;

import "./Ownable.sol";

abstract contract Operator is Ownable {
    mapping(address => bool) private _operators;

    constructor() {
        _setOperator(msg.sender, true);
    }

    modifier onlyOperator() {
        require(_operators[msg.sender], "Forbidden");
        _;
    }

    function _setOperator(address operatorAddress, bool value) private {
        _operators[operatorAddress] = value;
        emit OperatorSetted(operatorAddress, value);
    }

    function setOperator(address operatorAddress, bool value)
        external
        onlyOwner
    {
        _setOperator(operatorAddress, value);
    }

    function isOperator(address operatorAddress) external view returns (bool) {
        return _operators[operatorAddress];
    }

    event OperatorSetted(address operatorAddress, bool value);
}