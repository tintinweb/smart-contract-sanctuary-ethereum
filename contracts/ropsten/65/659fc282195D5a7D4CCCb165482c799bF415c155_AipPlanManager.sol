// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./abstracts/Multicall.sol";
import "./base/AipPayments.sol";
import "./access/Ownable.sol";
import "./interfaces/IAipPoolDeployer.sol";
import "./interfaces/IERC20.sol";
import "./interfaces/IAipPool.sol";
import "./interfaces/IAipFactory.sol";
import "./interfaces/callback/IAipSubscribeCallback.sol";
import "./interfaces/callback/IAipExtendCallback.sol";
import "./libraries/CallbackValidation.sol";
import "./libraries/PoolAddress.sol";

contract AipPlanManager is
    Multicall,
    AipPayments,
    IAipSubscribeCallback,
    IAipExtendCallback
{
    address public immutable factory;
    uint256 private _nextId = 1;
    struct Plan {
        address investor;
        address token0;
        address token1;
        uint24 frequency;
        uint256 index;
        uint256 tickAmount;
        uint256 createdTime;
    }
    struct PlanStatistics {
        uint256 swapAmount0;
        uint256 swapAmount1;
        uint256 claimedAmount1;
        uint256 ticks;
        uint256 remainingTicks;
        uint256 startedTime;
        uint256 endedTime;
        uint256 lastTriggerTime;
    }
    mapping(uint256 => Plan) private _plans;

    mapping(address => uint256[]) public investorPlans;

    constructor(address _factory, address _WETH9) AipPayments(_WETH9) {
        factory = _factory;
    }

    struct SubscribeCallbackData {
        PoolAddress.PoolInfo poolInfo;
        address payer;
    }

    function aipSubscribeCallback(uint256 amount, bytes calldata data)
        external
        override
    {
        SubscribeCallbackData memory decoded = abi.decode(
            data,
            (SubscribeCallbackData)
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
        returns (Plan memory plan, PlanStatistics memory statistics)
    {
        plan = _plans[planIndex];
        PoolAddress.PoolInfo memory poolInfo = PoolAddress.PoolInfo({
            token0: plan.token0,
            token1: plan.token1,
            frequency: plan.frequency
        });
        IAipPool pool = IAipPool(PoolAddress.computeAddress(factory, poolInfo));
        (
            statistics.swapAmount1,
            statistics.claimedAmount1,
            statistics.ticks,
            statistics.remainingTicks,
            statistics.startedTime,
            statistics.endedTime,
            statistics.lastTriggerTime
        ) = pool.getPlanStatistics(plan.index);
    }

    function createPoolIfNecessary(PoolAddress.PoolInfo calldata poolInfo)
        external
        payable
        returns (address pool)
    {
        pool = IAipFactory(factory).getPool(
            poolInfo.token0,
            poolInfo.token1,
            poolInfo.frequency
        );
        if (pool == address(0)) {
            pool = IAipFactory(factory).createPool(
                poolInfo.token0,
                poolInfo.token1,
                poolInfo.frequency
            );
        }
    }

    struct SubscribeParams {
        address token0;
        address token1;
        uint24 frequency;
        uint256 tickAmount;
        uint256 periods;
    }

    function subscribe(SubscribeParams calldata params)
        external
        payable
        returns (uint256 id, IAipPool pool)
    {
        PoolAddress.PoolInfo memory poolInfo = PoolAddress.PoolInfo({
            token0: params.token0,
            token1: params.token1,
            frequency: params.frequency
        });
        pool = IAipPool(PoolAddress.computeAddress(factory, poolInfo));
        uint256 index = pool.subscribe(
            msg.sender,
            params.tickAmount,
            params.periods,
            abi.encode(
                SubscribeCallbackData({poolInfo: poolInfo, payer: msg.sender})
            )
        );
        id = _nextId++;
        _plans[id] = Plan({
            investor: msg.sender,
            token0: params.token0,
            token1: params.token1,
            frequency: params.frequency,
            index: index,
            tickAmount: params.tickAmount,
            createdTime: block.timestamp
        });
        investorPlans[msg.sender].push(id);
    }

    function extend(uint256 id, uint256 periods) external payable {
        Plan memory plan = _plans[id];
        require(plan.index > 0, "Invalid plan");
        PoolAddress.PoolInfo memory poolInfo = PoolAddress.PoolInfo({
            token0: plan.token0,
            token1: plan.token1,
            frequency: plan.frequency
        });
        IAipPool pool = IAipPool(PoolAddress.computeAddress(factory, poolInfo));
        pool.extend(
            msg.sender,
            plan.index,
            periods,
            abi.encode(
                ExtendCallbackData({poolInfo: poolInfo, payer: msg.sender})
            )
        );
    }

    function unsubscribe(uint256 id)
        external
        returns (uint256 received0, uint256 received1)
    {
        Plan memory plan = _plans[id];
        require(plan.index > 0, "Invalid plan");
        PoolAddress.PoolInfo memory poolInfo = PoolAddress.PoolInfo({
            token0: plan.token0,
            token1: plan.token1,
            frequency: plan.frequency
        });
        IAipPool pool = IAipPool(PoolAddress.computeAddress(factory, poolInfo));
        return pool.unsubscribe(msg.sender, plan.index);
    }

    function claim(uint256 id) external returns (uint256 received1) {
        Plan memory plan = _plans[id];
        require(plan.index > 0, "Invalid plan");
        PoolAddress.PoolInfo memory poolInfo = PoolAddress.PoolInfo({
            token0: plan.token0,
            token1: plan.token1,
            frequency: plan.frequency
        });
        IAipPool pool = IAipPool(PoolAddress.computeAddress(factory, poolInfo));
        return pool.claim(msg.sender, plan.index);
    }

    function claimReward(uint256 id)
        external
        returns (
            address token,
            uint256 unclaimedAmount,
            uint256 claimedAmount
        )
    {
        Plan memory plan = _plans[id];
        require(plan.index > 0, "Invalid plan");
        PoolAddress.PoolInfo memory poolInfo = PoolAddress.PoolInfo({
            token0: plan.token0,
            token1: plan.token1,
            frequency: plan.frequency
        });
        IAipPool pool = IAipPool(PoolAddress.computeAddress(factory, poolInfo));
        return pool.claimReward(msg.sender, plan.index);
    }
}

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
            uint24 frequency
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

    event Claim(uint256 planIndex, uint256 received1);

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
        uint24 oldSwapFee,
        uint24 oldSwapWETH9Fee,
        uint24 newSwapFee,
        uint24 newSwapWETH9Fee
    );
    event CollectProtocol(address requester, address receiver, uint256 amount);

    struct PlanInfo {
        uint256 index;
        address investor;
        uint256 tickAmount0;
        uint256 claimedAmount1;
        uint256 startTick;
        uint256 endTick;
        uint256 claimedRewardIndex;
        uint256 claimedRewardAmount;
    }

    struct RewardCycleInfo {
        uint256 tickIndexStart;
        uint256 tickIndexEnd;
        uint256 rewardAmount;
        uint256 paymentAmount0;
    }

    function factory() external view returns (address);

    function swapManager() external view returns (address);

    function WETH9() external view returns (address);

    function rewardToken() external view returns (address);

    function rewardOperator() external view returns (address);

    function token0() external view returns (address);

    function token1() external view returns (address);

    function frequency() external view returns (uint24);

    function swapFee() external view returns (uint24);

    function swapWETH9Fee() external view returns (uint24);

    function protocolFee() external view returns (uint256);

    function totalPaymentAmount0() external view returns (uint256);

    function plans(uint256)
        external
        view
        returns (
            uint256 index,
            address investor,
            uint256 tickAmount0,
            uint256 claimedAmount1,
            uint256 startTick,
            uint256 endTick,
            uint256 claimedRewardIndex,
            uint256 claimedRewardAmount
        );

    function rewardCycles(uint256)
        external
        view
        returns (
            uint256 tickIndexStart,
            uint256 tickIndexEnd,
            uint256 rewardAmount,
            uint256 paymentAmount0
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
            uint256 time
        );

    function lastRewardCycle()
        external
        view
        returns (uint256 index, RewardCycleInfo memory rewardCycle);

    function getPlanStatistics(uint256 planIndex)
        external
        view
        returns (
            uint256 swapAmount1,
            uint256 claimedAmount1,
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

    function claim(address requester, uint256 planIndex)
        external
        returns (uint256 received1);

    function extend(
        address requester,
        uint256 planIndex,
        uint256 extendedAmount0,
        bytes calldata data
    ) external;

    function unsubscribe(address requester, uint256 planIndex)
        external
        returns (uint256 received0, uint256 received1);

    function trigger() external returns (uint256 amount0, uint256 amount1);

    function setSwapFee(uint24 _swapFee, uint24 _swapWETH9Fee)
        external
        returns (address swapPool, address swapWETH9Pool);

    function claimReward(address requester, uint256 planIndex)
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

import "../libraries/PoolAddress.sol";

interface IAipFactory {
    event OwnerChanged(address indexed oldOwner, address indexed newOwner);
    event PoolCreated(
        address token0,
        address token1,
        uint24 frequency,
        address pool
    );

    function owner() external view returns (address);

    function swapManager() external view returns (address);

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
            uint24
        );

    function getPool(
        address token0,
        address token1,
        uint24 frequency
    ) external view returns (address pool);

    function createPool(
        address token0,
        address token1,
        uint24 frequency
    ) external returns (address pool);

    function enable(
        address _swapManager,
        address _DAI,
        address _USDC,
        address _USDT,
        address _WETH9
    ) external;

    function setOwner(address _owner) external;
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
pragma solidity >=0.8.0;

import "../interfaces/IAipPool.sol";
import "./PoolAddress.sol";

library CallbackValidation {
    function verifyCallback(
        address factory,
        address token0,
        address token1,
        uint24 frequency
    ) internal view returns (IAipPool pool) {
        return
            verifyCallback(
                factory,
                PoolAddress.getPoolInfo(token0, token1, frequency)
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
        0x7d80ebeaf6fe3aed55114e3281b45f01da17069f52f1c4e945df659abbc5364f;

    struct PoolInfo {
        address token0;
        address token1;
        uint24 frequency;
    }

    function getPoolInfo(
        address token0,
        address token1,
        uint24 frequency
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