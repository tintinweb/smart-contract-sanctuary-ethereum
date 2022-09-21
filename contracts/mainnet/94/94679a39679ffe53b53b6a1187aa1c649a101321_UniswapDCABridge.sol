// SPDX-License-Identifier: Apache-2.0
// Copyright 2022 Aztec.
pragma solidity >=0.8.4;

import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {SafeERC20} from "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";

import {IWETH} from "../../interfaces/IWETH.sol";
import {IChainlinkOracle} from "../../interfaces/chainlink/IChainlinkOracle.sol";
import {ISwapRouter} from "../../interfaces/uniswapv3/ISwapRouter.sol";
import {BiDCABridge} from "./BiDCABridge.sol";

/**
 * @notice Initial implementation of the BiDCA bridge using Uniswap as the DEX and Chainlink as oracle.
 * The bridge is using DAI and WETH for A and B with a Chainlink oracle to get prices.
 * The bridge allows users to force a rebalance through Uniswap pools.
 * The forced rebalance will:
 * 1. rebalance internally in the ticks, as the BiDCABridge,
 * 2. rebalance cross-ticks, e.g., excess from the individual ticks are matched,
 * 3. swap any remaining excess using Uniswap, and rebalance with the returned assets
 * @dev The slippage + path is immutable, so low liquidity in Uniswap might block the `rebalanceAndfillUniswap` flow.
 * @author Lasse Herskind (LHerskind on GitHub).
 */
contract UniswapDCABridge is BiDCABridge {
    using SafeERC20 for IERC20;

    error NegativePrice();

    address internal constant USDC = 0xA0b86991c6218b36c1d19D4a2e9Eb0cE3606eB48;
    address internal constant DAI = 0x6B175474E89094C44Da98b954EedeAC495271d0F;

    uint160 internal constant SQRT_PRICE_LIMIT_X96 = 1461446703485210103287273052203988822378723970341;
    ISwapRouter public constant UNI_ROUTER = ISwapRouter(0xE592427A0AEce92De3Edee1F18E0157C05861564);

    uint256 public constant SLIPPAGE = 100; // Basis points

    IChainlinkOracle public constant ORACLE = IChainlinkOracle(0x773616E4d11A78F511299002da57A0a94577F1f4);

    constructor(
        address _rollupProcessor,
        uint256 _tickSize,
        uint256 _fee
    ) BiDCABridge(_rollupProcessor, DAI, address(WETH), _tickSize, _fee) {
        IERC20(DAI).safeApprove(address(UNI_ROUTER), type(uint256).max);
        IERC20(address(WETH)).safeApprove(address(UNI_ROUTER), type(uint256).max);
    }

    function rebalanceAndFillUniswap() public returns (int256, int256) {
        rebalanceAndFillUniswap(type(uint256).max);
    }

    /**
     * @notice Rebalances within ticks, then across ticks, and finally, take the remaining funds to uniswap
     * where it is traded for the opposite, and used to rebalance completely
     * @dev Uses a specific path for the assets to do the swap
     * @dev Slippage protection through the chainlink oracle, as a base price
     * @dev Can be quite gas intensive as it will loop multiple times over the ticks to fill orders.
     * @return aFlow The flow of token A
     * @return bFlow The flow of token B
     */
    function rebalanceAndFillUniswap(uint256 _upperTick) public returns (int256, int256) {
        uint256 oraclePrice = getPrice();
        (int256 aFlow, int256 bFlow, uint256 a, uint256 b) = _rebalanceAndFill(0, 0, oraclePrice, _upperTick, true);

        // If we have available A and B, we can do internal rebalancing across ticks with these values.
        if (a > 0 && b > 0) {
            (aFlow, bFlow, a, b) = _rebalanceAndFill(a, b, oraclePrice, _upperTick, true);
        }

        if (a > 0) {
            // Trade all A to B using uniswap.
            uint256 bOffer = UNI_ROUTER.exactInput(
                ISwapRouter.ExactInputParams({
                    path: abi.encodePacked(ASSET_A, uint24(100), USDC, uint24(500), ASSET_B),
                    recipient: address(this),
                    deadline: block.timestamp,
                    amountIn: a,
                    amountOutMinimum: (denominateAssetAInB(a, oraclePrice, false) * (10000 - SLIPPAGE)) / 10000
                })
            );

            // Rounding DOWN ensures that B received / price >= A available
            uint256 price = (bOffer * 1e18) / a;

            (aFlow, bFlow, , ) = _rebalanceAndFill(0, bOffer, price, _upperTick, true);
        }

        if (b > 0) {
            // Trade all B to A using uniswap.
            uint256 aOffer = UNI_ROUTER.exactInput(
                ISwapRouter.ExactInputParams({
                    path: abi.encodePacked(ASSET_B, uint24(500), USDC, uint24(100), ASSET_A),
                    recipient: address(this),
                    deadline: block.timestamp,
                    amountIn: b,
                    amountOutMinimum: (denominateAssetBInA(b, oraclePrice, false) * (10000 - SLIPPAGE)) / 10000
                })
            );

            // Rounding UP to ensure that A received * price >= B available
            uint256 price = (b * 1e18 + aOffer - 1) / aOffer;

            (aFlow, bFlow, , ) = _rebalanceAndFill(aOffer, 0, price, _upperTick, true);
        }

        return (aFlow, bFlow);
    }

    /**
     * @notice Fetch the price from the chainlink oracle.
     * @dev Reverts if the price is stale or negative
     * @return Price
     */
    function getPrice() public virtual override(BiDCABridge) returns (uint256) {
        (, int256 answer, , , ) = ORACLE.latestRoundData();
        if (answer < 0) {
            revert NegativePrice();
        }

        return uint256(answer);
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
// OpenZeppelin Contracts (last updated v4.7.0) (token/ERC20/utils/SafeERC20.sol)

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
        // we're implementing it ourselves. We use {Address.functionCall} to perform this call, which verifies that
        // the target address contains contract code and also asserts for success in the low-level call.

        bytes memory returndata = address(token).functionCall(data, "SafeERC20: low-level call failed");
        if (returndata.length > 0) {
            // Return data is optional
            require(abi.decode(returndata, (bool)), "SafeERC20: ERC20 operation did not succeed");
        }
    }
}

// SPDX-License-Identifier: Apache-2.0
// Copyright 2022 Aztec.
pragma solidity >=0.8.4;

import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";

interface IWETH is IERC20 {
    function deposit() external payable;

    function withdraw(uint256 amount) external;
}

// SPDX-License-Identifier: Apache-2.0
// Copyright 2022 Aztec.
pragma solidity >=0.8.4;

interface IChainlinkOracle {
    function latestRoundData()
        external
        view
        returns (
            uint80,
            int256,
            uint256,
            uint256,
            uint80
        );
}

// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity >=0.8.4;

/// @title Router token swapping functionality
/// @notice Functions for swapping tokens via Uniswap V3
interface ISwapRouter {
    struct ExactInputSingleParams {
        address tokenIn;
        address tokenOut;
        uint24 fee;
        address recipient;
        uint256 deadline;
        uint256 amountIn;
        uint256 amountOutMinimum;
        uint160 sqrtPriceLimitX96;
    }

    /// @notice Swaps `amountIn` of one token for as much as possible of another token
    /// @param params The parameters necessary for the swap, encoded as `ExactInputSingleParams` in calldata
    /// @return amountOut The amount of the received token
    function exactInputSingle(ExactInputSingleParams calldata params) external payable returns (uint256 amountOut);

    struct ExactInputParams {
        bytes path;
        address recipient;
        uint256 deadline;
        uint256 amountIn;
        uint256 amountOutMinimum;
    }

    /// @notice Swaps `amountIn` of one token for as much as possible of another along the specified path
    /// @param params The parameters necessary for the multi-hop swap, encoded as `ExactInputParams` in calldata
    /// @return amountOut The amount of the received token
    function exactInput(ExactInputParams calldata params) external payable returns (uint256 amountOut);

    struct ExactOutputSingleParams {
        address tokenIn;
        address tokenOut;
        uint24 fee;
        address recipient;
        uint256 deadline;
        uint256 amountOut;
        uint256 amountInMaximum;
        uint160 sqrtPriceLimitX96;
    }

    /// @notice Swaps as little as possible of one token for `amountOut` of another token
    /// @param params The parameters necessary for the swap, encoded as `ExactOutputSingleParams` in calldata
    /// @return amountIn The amount of the input token
    function exactOutputSingle(ExactOutputSingleParams calldata params) external payable returns (uint256 amountIn);

    struct ExactOutputParams {
        bytes path;
        address recipient;
        uint256 deadline;
        uint256 amountOut;
        uint256 amountInMaximum;
    }

    /// @notice Swaps as little as possible of one token for `amountOut` of another along the specified path (reversed)
    /// @param params The parameters necessary for the multi-hop swap, encoded as `ExactOutputParams` in calldata
    /// @return amountIn The amount of the input token
    function exactOutput(ExactOutputParams calldata params) external payable returns (uint256 amountIn);
}

// SPDX-License-Identifier: Apache-2.0
// Copyright 2022 Aztec.
pragma solidity >=0.8.4;

import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {SafeERC20} from "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";

import {IRollupProcessor} from "../../aztec/interfaces/IRollupProcessor.sol";
import {BridgeBase} from "../base/BridgeBase.sol";
import {ErrorLib} from "../base/ErrorLib.sol";
import {AztecTypes} from "../../aztec/libraries/AztecTypes.sol";

import {IWETH} from "../../interfaces/IWETH.sol";

import {SafeCastLib} from "./SafeCastLib.sol";

/**
 * @notice Initial abstract implementation of "Dollar" Cost Averaging.
 * The bridge implements a bidirectional dollar cost averaging protocol,
 * allowing users to go either direction between two tokens A and B.
 * The "order" is executed over a period of time, instead of all at once.
 * For Eth and Dai, this allows the user to sell Dai to buy Eth over X days, and vice versa.
 * The timeperiod is divided into ticks, with each tick keeping track of the funds that should be traded in that tick.
 * As well as the price, and how much have been received in return.
 * To "balance" the scheme, an external party can buy assets at the orace-price (no slippage).
 * The amount that can be bought by the external party, depends on the ticks and how much can be matched internally.
 * As part of the balancing act, each tick will match the A and B holdings it has to sell, using the oracle price
 * (or infer price from prior price and current price).
 * The excess from this internal matching is then sold off to the caller at oracle price, to match his offer.
 * The rebalancing is expected to be done by arbitrageurs when prices deviate sufficiently between the oracle and dexes.
 * The finalise function is incentivised by giving part of the traded value to the `tx.origin` (msg.sender always rollup processor).
 * Extensions to this bridge can be made such that the external party can be Uniswap or another dex.
 * An extension should also define the oracle to be used for the price.
 * @dev Built for assets with 18 decimals precision
 * @dev A contract that inherits must handle the case for forcing a swap through a DEX.
 * @author Lasse Herskind (LHerskind on GitHub).
 */
abstract contract BiDCABridge is BridgeBase {
    using SafeERC20 for IERC20;
    using SafeCastLib for uint256;
    using SafeCastLib for uint128;

    error FeeTooLarge();
    error PositionAlreadyExists();
    error NoDeposits();

    /**
     * @notice A struct used in-memory to get around stack-to-deep errors
     * @member currentPrice Current oracle price
     * @member earliestTickWithAvailableA Earliest tick with available asset A
     * @member earliestTickWithAvailableB Earliest tick with available asset B
     * @member offerAInB Amount of asset B that is offered to be bought at the current price for A
     * @member offerBInA Amount of asset A that is offered to be bought at the current price for B
     * @member protocolSoldA Amount of asset A the bridge sold
     * @member protocolSoldB Amount of asset B the bridge sold
     * @member protocolBoughtA Amount of asset A the bridge bought
     * @member protocolBoughtB Amount of asset B the bridge bought
     * @member lastUsedPrice Last used price during rebalancing (cache in case new price won't be available)
     * @member lastUsedPriceTime Time at which last used price was set
     * @member availableA The amount of asset A that is available
     * @member availableB The amount of asset B that is available
     */
    struct RebalanceValues {
        uint256 currentPrice;
        uint256 earliestTickWithAvailableA;
        uint256 earliestTickWithAvailableB;
        uint256 offerAInB;
        uint256 offerBInA;
        uint256 protocolSoldA;
        uint256 protocolSoldB;
        uint256 protocolBoughtA;
        uint256 protocolBoughtB;
        uint256 lastUsedPrice;
        uint256 lastUsedPriceTime;
        uint256 availableA;
        uint256 availableB;
    }

    /**
     * @notice A struct representing 1 DCA position
     * @member amount Amount of asset A or B to be sold
     * @member start Index of the first tick this position touches
     * @member end Index of the last tick this position touches
     * @member aToB True if A is being sold to B, false otherwise
     */
    struct DCA {
        uint128 amount;
        uint32 start;
        uint32 end;
        bool aToB;
    }

    /**
     * @notice A struct defining one direction in a tick
     * @member sold Amount of asset sold
     * @member bought Amount of asset bought
     */
    struct SubTick {
        uint128 sold;
        uint128 bought;
    }

    /**
     * @notice A container for Tick related data
     * @member availableA Amount of A available in a tick for sale
     * @member availableB Amount of B available in a tick for sale
     * @member poke A value used only to initialize a storage slot
     * @member aToBSubTick A struct capturing info of A to B trades
     * @member aToBSubTick A struct capturing info of B to A trades
     * @member priceAToB A price of A denominated in B
     * @member priceTime A time at which price was last updated
     */
    struct Tick {
        uint120 availableA;
        uint120 availableB;
        uint16 poke;
        SubTick aToBSubTick;
        SubTick bToASubTick;
        uint128 priceOfAInB;
        uint32 priceTime;
    }

    IWETH internal constant WETH = IWETH(0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2);
    uint256 public constant FEE_DIVISOR = 10000;

    // The assets that are DCAed between
    IERC20 public immutable ASSET_A;
    IERC20 public immutable ASSET_B;

    // The timespan that a tick covers
    uint256 public immutable TICK_SIZE;
    uint256 public immutable FEE;

    // The earliest tick where we had available A or B respectively.
    uint32 public earliestTickWithAvailableA;
    uint32 public earliestTickWithAvailableB;

    // tick id => Tick.
    mapping(uint256 => Tick) public ticks;
    // nonce => DCA
    mapping(uint256 => DCA) public dcas;

    /**
     * @notice Constructor
     * @param _rollupProcessor The address of the rollup processor for the bridge
     * @param _assetA The address of asset A
     * @param _assetB The address of asset B
     * @param _tickSize The time-span that each tick covers in seconds
     * @dev Smaller _tickSizes will increase looping and gas costs
     */
    constructor(
        address _rollupProcessor,
        address _assetA,
        address _assetB,
        uint256 _tickSize,
        uint256 _fee
    ) BridgeBase(_rollupProcessor) {
        ASSET_A = IERC20(_assetA);
        ASSET_B = IERC20(_assetB);
        TICK_SIZE = _tickSize;

        IERC20(_assetA).safeApprove(_rollupProcessor, type(uint256).max);
        IERC20(_assetB).safeApprove(_rollupProcessor, type(uint256).max);

        if (_fee > FEE_DIVISOR) {
            revert FeeTooLarge();
        }
        FEE = _fee;
    }

    receive() external payable {}

    /**
     * @notice Helper used to poke storage from next tick and `_ticks` forwards
     * @param _numTicks The number of ticks to poke
     */
    function pokeNextTicks(uint256 _numTicks) external {
        pokeTicks(_nextTick(block.timestamp), _numTicks);
    }

    /**
     * @notice Helper used to poke storage of ticks to make deposits more consistent in gas usage
     * @dev First sstore is very expensive, so by doing it as this, we can prepare it before deposit
     * @param _startTick The first tick to poke
     * @param _numTicks The number of ticks to poke
     */
    function pokeTicks(uint256 _startTick, uint256 _numTicks) public {
        for (uint256 i = _startTick; i < _startTick + _numTicks; i++) {
            ticks[i].poke++;
        }
    }

    /**
     * @notice Rebalances ticks using internal values first, then with externally provided assets.
     * Ticks are balanced internally using the price at the specific tick (either stored in tick, or interpolated).
     * Leftover assets are sold using current price to fill as much of the offer as possible.
     * @param _offerA The amount of asset A that is offered for sale to the bridge
     * @param _offerB The amount of asset B that is offered for sale to the bridge
     * @return flowA The flow of asset A from the bridge POV, e.g., >0 = buying of tokens, <0 = selling tokens
     * @return flowB The flow of asset B from the bridge POV, e.g., >0 = buying of tokens, <0 = selling tokens
     */
    function rebalanceAndFill(uint256 _offerA, uint256 _offerB) public returns (int256, int256) {
        return rebalanceAndFill(_offerA, _offerB, type(uint256).max);
    }

    /**
     * @notice Rebalances ticks using internal values first, then with externally provided assets.
     * Ticks are balanced internally using the price at the specific tick (either stored in tick, or interpolated).
     * Leftover assets are sold using current price to fill as much of the offer as possible.
     * @param _offerA The amount of asset A that is offered for sale to the bridge
     * @param _offerB The amount of asset B that is offered for sale to the bridge
     * @param _upperTick The upper limit for ticks (useful gas-capped rebalancing)
     * @return flowA The flow of asset A from the bridge POV, e.g., >0 = buying of tokens, <0 = selling tokens
     * @return flowB The flow of asset B from the bridge POV, e.g., >0 = buying of tokens, <0 = selling tokens
     */
    function rebalanceAndFill(
        uint256 _offerA,
        uint256 _offerB,
        uint256 _upperTick
    ) public returns (int256, int256) {
        (int256 flowA, int256 flowB, , ) = _rebalanceAndFill(_offerA, _offerB, getPrice(), _upperTick, false);
        if (flowA > 0) {
            ASSET_A.safeTransferFrom(msg.sender, address(this), uint256(flowA));
        } else if (flowA < 0) {
            ASSET_A.safeTransfer(msg.sender, uint256(-flowA));
        }

        if (flowB > 0) {
            ASSET_B.safeTransferFrom(msg.sender, address(this), uint256(flowB));
        } else if (flowB < 0) {
            ASSET_B.safeTransfer(msg.sender, uint256(-flowB));
        }

        return (flowA, flowB);
    }

    /**
     * @notice Function to create DCA position from `_inputAssetA` to `_outputAssetA` over `_ticks` ticks.
     * @param _inputAssetA The asset to be sold
     * @param _outputAssetA The asset to be bought
     * @param _inputValue The value of `_inputAssetA` to be sold
     * @param _interactionNonce The unique identifier for the interaction, used to identify the DCA position
     * @param _numTicks The auxdata, passing the number of ticks the position should run
     * @return Will always return 0 assets, and isAsync = true.
     */
    function convert(
        AztecTypes.AztecAsset calldata _inputAssetA,
        AztecTypes.AztecAsset calldata,
        AztecTypes.AztecAsset calldata _outputAssetA,
        AztecTypes.AztecAsset calldata,
        uint256 _inputValue,
        uint256 _interactionNonce,
        uint64 _numTicks,
        address
    )
        external
        payable
        override(BridgeBase)
        onlyRollup
        returns (
            uint256,
            uint256,
            bool
        )
    {
        address inputAssetAddress = _inputAssetA.erc20Address;
        address outputAssetAddress = _outputAssetA.erc20Address;

        if (_inputAssetA.assetType == AztecTypes.AztecAssetType.ETH) {
            WETH.deposit{value: _inputValue}();
            inputAssetAddress = address(WETH);
        }
        if (_outputAssetA.assetType == AztecTypes.AztecAssetType.ETH) {
            outputAssetAddress = address(WETH);
        }

        if (inputAssetAddress != address(ASSET_A) && inputAssetAddress != address(ASSET_B)) {
            revert ErrorLib.InvalidInputA();
        }
        bool aToB = inputAssetAddress == address(ASSET_A);

        if (outputAssetAddress != (aToB ? address(ASSET_B) : address(ASSET_A))) {
            revert ErrorLib.InvalidOutputA();
        }
        if (dcas[_interactionNonce].start != 0) {
            revert PositionAlreadyExists();
        }

        _deposit(_interactionNonce, _inputValue, _numTicks, aToB);
        return (0, 0, true);
    }

    /**
     * @notice Function used to close a completed DCA position
     * @param _outputAssetA The asset bought with the DCA position
     * @param _interactionNonce The identifier for the DCA position
     * @return outputValueA The amount of assets bought
     * @return interactionComplete True if the interaction is completed and can be executed, false otherwise
     */
    function finalise(
        AztecTypes.AztecAsset calldata,
        AztecTypes.AztecAsset calldata,
        AztecTypes.AztecAsset calldata _outputAssetA,
        AztecTypes.AztecAsset calldata,
        uint256 _interactionNonce,
        uint64
    )
        external
        payable
        virtual
        override(BridgeBase)
        onlyRollup
        returns (
            uint256 outputValueA,
            uint256,
            bool interactionComplete
        )
    {
        uint256 accumulated;
        (accumulated, interactionComplete) = getAccumulated(_interactionNonce);

        if (interactionComplete) {
            bool toEth;

            address outputAssetAddress = _outputAssetA.erc20Address;
            if (_outputAssetA.assetType == AztecTypes.AztecAssetType.ETH) {
                toEth = true;
                outputAssetAddress = address(WETH);
            }

            if (outputAssetAddress != (dcas[_interactionNonce].aToB ? address(ASSET_B) : address(ASSET_A))) {
                revert ErrorLib.InvalidOutputA();
            }

            uint256 incentive;
            if (FEE > 0) {
                incentive = (accumulated * FEE) / FEE_DIVISOR;
            }

            outputValueA = accumulated - incentive;
            delete dcas[_interactionNonce];

            if (toEth) {
                WETH.withdraw(outputValueA);
                IRollupProcessor(ROLLUP_PROCESSOR).receiveEthFromBridge{value: outputValueA}(_interactionNonce);
            }

            if (incentive > 0) {
                // Cannot use the `msg.sender` as that would simply be the rollup.
                IERC20(outputAssetAddress).safeTransfer(tx.origin, incentive);
            }
        }
    }

    /**
     * @notice The brice of A in B, e.g., 10 would mean 1 A = 10 B
     * @return priceAToB measured with precision 1e18
     */
    function getPrice() public virtual returns (uint256);

    /**
     * @notice Computes the value of `_amount` A tokens in B tokens
     * @param _amount The amount of A tokens
     * @param _priceAToB The price of A tokens in B
     * @param _roundUp Flag to round up, if true rounding up, otherwise rounding down
     */
    function denominateAssetAInB(
        uint256 _amount,
        uint256 _priceAToB,
        bool _roundUp
    ) public pure returns (uint256) {
        if (_roundUp) {
            return (_amount * _priceAToB + 1e18 - 1) / 1e18;
        }
        return (_amount * _priceAToB) / 1e18;
    }

    /**
     * @notice Computes the value of `_amount` A tokens in B tokens
     * @param _amount The amount of A tokens
     * @param _priceAToB The price of A tokens in B
     * @param _roundUp Flag to round up, if true rounding up, otherwise rounding down
     */
    function denominateAssetBInA(
        uint256 _amount,
        uint256 _priceAToB,
        bool _roundUp
    ) public pure returns (uint256) {
        if (_roundUp) {
            return (_amount * 1e18 + _priceAToB - 1) / _priceAToB;
        }
        return (_amount * 1e18) / _priceAToB;
    }

    /**
     * @notice Helper to fetch the tick at `_tick`
     * @param _tick The tick to fetch
     * @return The Tick structure
     */
    function getTick(uint256 _tick) public view returns (Tick memory) {
        return ticks[_tick];
    }

    /**
     * @notice Helper to fetch the DCA at `_nonce`
     * @param _nonce The DCA to fetch
     * @return The DCA structure
     */
    function getDCA(uint256 _nonce) public view returns (DCA memory) {
        return dcas[_nonce];
    }

    /**
     * @notice Helper to compute the amount of available tokens (not taking rebalancing into account)
     * @return availableA Available amount of token A
     * @return availableB Available amount of token B
     */
    function getAvailable() public view returns (uint256 availableA, uint256 availableB) {
        uint256 start = _earliestUsedTick(earliestTickWithAvailableA, earliestTickWithAvailableB);
        uint256 lastTick = block.timestamp / TICK_SIZE;
        for (uint256 i = start; i <= lastTick; i++) {
            availableA += ticks[i].availableA;
            availableB += ticks[i].availableB;
        }
    }

    /**
     * @notice Helper to get the amount of accumulated tokens for a specific DCA (and a flag for finalisation readiness)
     * @param _nonce The DCA to fetch
     * @return accumulated The amount of assets accumulated
     * @return ready A flag that is true if the accumulation has completed, false otherwise
     */
    function getAccumulated(uint256 _nonce) public view returns (uint256 accumulated, bool ready) {
        DCA memory dca = dcas[_nonce];
        uint256 start = dca.start;
        uint256 end = dca.end;
        uint256 tickAmount = dca.amount / (end - start);
        bool aToB = dca.aToB;

        ready = true;

        for (uint256 i = start; i < end; i++) {
            Tick storage tick = ticks[i];
            (uint256 available, uint256 sold, uint256 bought) = aToB
                ? (tick.availableA, tick.aToBSubTick.sold, tick.aToBSubTick.bought)
                : (tick.availableB, tick.bToASubTick.sold, tick.bToASubTick.bought);
            ready = ready && available == 0 && sold > 0;
            accumulated += sold == 0 ? 0 : (bought * tickAmount) / (sold + available);
        }
    }

    /**
     * @notice Computes the next tick
     * @dev    Note that the return value can be the current tick if we are exactly at the threshold
     * @return The next tick
     */
    function _nextTick(uint256 _time) internal view returns (uint256) {
        return ((_time + TICK_SIZE - 1) / TICK_SIZE);
    }

    function _min(uint256 _a, uint256 _b) internal pure returns (uint256) {
        return _a > _b ? _b : _a;
    }

    /**
     * @notice Create a new DCA position starting at next tick and accumulates the available assets to the future ticks.
     * @param _nonce The interaction nonce
     * @param _amount The amount of assets deposited
     * @param _ticks The number of ticks that the position span
     * @param _aToB A flag that is true if input asset is assetA and false otherwise.
     */
    function _deposit(
        uint256 _nonce,
        uint256 _amount,
        uint256 _ticks,
        bool _aToB
    ) internal {
        uint256 nextTick = _nextTick(block.timestamp);
        if (_aToB && earliestTickWithAvailableA == 0) {
            earliestTickWithAvailableA = nextTick.toU32();
        }
        if (!_aToB && earliestTickWithAvailableB == 0) {
            earliestTickWithAvailableB = nextTick.toU32();
        }
        // Update prices of last tick, might be 1 second in the past.
        ticks[nextTick - 1].priceOfAInB = getPrice().toU128();
        ticks[nextTick - 1].priceTime = block.timestamp.toU32();

        uint256 tickAmount = _amount / _ticks;
        for (uint256 i = nextTick; i < nextTick + _ticks; i++) {
            if (_aToB) {
                ticks[i].availableA += tickAmount.toU120();
            } else {
                ticks[i].availableB += tickAmount.toU120();
            }
        }
        dcas[_nonce] = DCA({
            amount: _amount.toU128(),
            start: nextTick.toU32(),
            end: (nextTick + _ticks).toU32(),
            aToB: _aToB
        });
    }

    /**
     * @notice Rebalances ticks using internal values first, then with externally provided assets.
     * Ticks are balanced internally using the price at the specific tick (either stored in tick, or interpolated).
     * Leftover assets are sold using current price to fill as much of the offer as possible.
     * @param _offerA The amount of asset A that is offered for sale to the bridge
     * @param _offerB The amount of asset B that is offered for sale to the bridge
     * @param _currentPrice Current oracle price
     * @param _self A flag that is true if rebalancing with self, e.g., swapping available funds with dex and rebalancing, and false otherwise
     * @param _upperTick A upper limit for the ticks, useful for gas-capped execution
     * @return flowA The flow of asset A from the bridge POV, e.g., >0 = buying of tokens, <0 = selling tokens
     * @return flowB The flow of asset B from the bridge POV, e.g., >0 = buying of tokens, <0 = selling tokens
     * @return availableA The amount of asset A that is available after the rebalancing
     * @return availableB The amount of asset B that is available after the rebalancing
     */
    function _rebalanceAndFill(
        uint256 _offerA,
        uint256 _offerB,
        uint256 _currentPrice,
        uint256 _upperTick,
        bool _self
    )
        internal
        returns (
            int256,
            int256,
            uint256,
            uint256
        )
    {
        RebalanceValues memory vars;
        vars.currentPrice = _currentPrice;

        // Cache and use earliest ticks with available funds
        vars.earliestTickWithAvailableA = earliestTickWithAvailableA;
        vars.earliestTickWithAvailableB = earliestTickWithAvailableB;
        uint256 earliestTick = _earliestUsedTick(vars.earliestTickWithAvailableA, vars.earliestTickWithAvailableB);

        // Cache last used price for use in case we don't have a fresh price.
        vars.lastUsedPrice = ticks[earliestTick].priceOfAInB;
        vars.lastUsedPriceTime = ticks[earliestTick].priceTime;
        if (vars.lastUsedPrice == 0) {
            uint256 lookBack = earliestTick;
            while (vars.lastUsedPrice == 0) {
                lookBack--;
                vars.lastUsedPrice = ticks[lookBack].priceOfAInB;
                vars.lastUsedPriceTime = ticks[lookBack].priceTime;
            }
        }

        // Compute the amount of B that is offered to be bought at current price for A. Round down
        vars.offerAInB = denominateAssetAInB(_offerA, vars.currentPrice, false);
        // Compute the amount of A that is offered to be bought at current price for B. Round down
        vars.offerBInA = denominateAssetBInA(_offerB, vars.currentPrice, false);

        uint256 nextTick = _nextTick(block.timestamp);
        // Update the latest tick, might be 1 second in the past.
        ticks[nextTick - 1].priceOfAInB = vars.currentPrice.toU128();
        ticks[nextTick - 1].priceTime = block.timestamp.toU32();

        for (uint256 i = earliestTick; i < _min(nextTick, _upperTick); i++) {
            // Load a cache
            Tick memory tick = ticks[i];

            _rebalanceTickInternally(vars, tick, i);
            _useAOffer(vars, tick, _self);
            _useBOffer(vars, tick, _self);

            // If no more available and earliest is current tick, increment tick.
            if (tick.availableA == 0 && vars.earliestTickWithAvailableA == i) {
                vars.earliestTickWithAvailableA += 1;
            }
            if (tick.availableB == 0 && vars.earliestTickWithAvailableB == i) {
                vars.earliestTickWithAvailableB += 1;
            }

            // Add the leftover A and B from the tick to total available
            vars.availableA += tick.availableA;
            vars.availableB += tick.availableB;

            // Update the storage
            ticks[i] = tick;
        }

        if (vars.earliestTickWithAvailableA > earliestTickWithAvailableA) {
            earliestTickWithAvailableA = vars.earliestTickWithAvailableA.toU32();
        }
        if (vars.earliestTickWithAvailableB > earliestTickWithAvailableB) {
            earliestTickWithAvailableB = vars.earliestTickWithAvailableB.toU32();
        }

        // Compute flow of tokens, from the POV of this contract, e.g., >0 is inflow, <0 outflow
        int256 flowA = int256(vars.protocolBoughtA) - int256(vars.protocolSoldA);
        int256 flowB = int256(vars.protocolBoughtB) - int256(vars.protocolSoldB);

        return (flowA, flowB, vars.availableA, vars.availableB);
    }

    /**
     * @notice Perform internal rebalancing of a single tick using available balances
     * @dev Heavily uses that internal functions are passing reference to memory structures
     *
     */
    function _rebalanceTickInternally(
        RebalanceValues memory _vars,
        Tick memory _tick,
        uint256 _tickId
    ) internal view {
        // Only perform internal rebalance if we have both assets available, otherwise nothing to rebalance
        if (_tick.availableA > 0 && _tick.availableB > 0) {
            uint256 price = _tick.priceOfAInB;

            // If a price is stored at tick, update the last used price and timestamp. Otherwise interpolate.
            if (price > 0) {
                _vars.lastUsedPrice = price;
                _vars.lastUsedPriceTime = _tick.priceTime;
            } else {
                int256 slope = (int256(_vars.currentPrice) - int256(_vars.lastUsedPrice)) /
                    int256(block.timestamp - _vars.lastUsedPriceTime);
                // lastUsedPriceTime will always be an earlier tick than this.
                uint256 dt = _tickId * TICK_SIZE + TICK_SIZE / 2 - _vars.lastUsedPriceTime;
                int256 _price = int256(_vars.lastUsedPrice) + slope * int256(dt);
                if (_price <= 0) {
                    price = 0;
                } else {
                    price = uint256(_price);
                }
            }

            // To compare we need same basis. Compute value of the available A in base B. Round down
            uint128 availableADenominatedInB = denominateAssetAInB(_tick.availableA, price, false).toU128();

            // If more value in A than B, we can use all available B. Otherwise, use all available A
            if (availableADenominatedInB > _tick.availableB) {
                // The value of all available B in asset A. Round down
                uint128 availableBDenominatedInA = denominateAssetBInA(_tick.availableB, price, false).toU128();

                // Update Asset A
                _tick.aToBSubTick.bought += _tick.availableB;
                _tick.aToBSubTick.sold += availableBDenominatedInA;

                // Update Asset B
                _tick.bToASubTick.bought += availableBDenominatedInA;
                _tick.bToASubTick.sold += _tick.availableB;

                // Update available values
                _tick.availableA -= availableBDenominatedInA.toU120();
                _tick.availableB = 0;
            } else {
                // We got more B than A, fill everything in A and part of B

                // Update Asset B
                _tick.bToASubTick.bought += _tick.availableA;
                _tick.bToASubTick.sold += availableADenominatedInB;

                // Update Asset A
                _tick.aToBSubTick.bought += availableADenominatedInB;
                _tick.aToBSubTick.sold += _tick.availableA;

                // Update available values
                _tick.availableA = 0;
                _tick.availableB -= availableADenominatedInB.toU120();
            }
        }
    }

    /**
     * @notice Fills as much of the A offered as possible
     * @dev Heavily uses that internal functions are passing reference to memory structures
     * @param _self True if buying from "self" false otherwise.
     */
    function _useAOffer(
        RebalanceValues memory _vars,
        Tick memory _tick,
        bool _self
    ) internal pure {
        if (_vars.offerAInB > 0 && _tick.availableB > 0) {
            uint128 amountBSold = _vars.offerAInB.toU128();
            // We cannot buy more than available
            if (_vars.offerAInB > _tick.availableB) {
                amountBSold = _tick.availableB;
            }
            // Underpays actual price if self, otherwise overpay (to not mess rounding)
            uint128 assetAPayment = denominateAssetBInA(amountBSold, _vars.currentPrice, !_self).toU128();

            _tick.availableB -= amountBSold.toU120();
            _tick.bToASubTick.sold += amountBSold;
            _tick.bToASubTick.bought += assetAPayment;

            _vars.offerAInB -= amountBSold;
            _vars.protocolSoldB += amountBSold;
            _vars.protocolBoughtA += assetAPayment;
        }
    }

    /**
     * @notice Fills as much of the A offered as possible
     * @dev Heavily uses that internal functions are passing reference to memory structures
     * @param _self True if buying from "self" false otherwise.
     */
    function _useBOffer(
        RebalanceValues memory _vars,
        Tick memory _tick,
        bool _self
    ) internal pure {
        if (_vars.offerBInA > 0 && _tick.availableA > 0) {
            // Buying Asset A using Asset B
            uint128 amountASold = _vars.offerBInA.toU128();
            if (_vars.offerBInA > _tick.availableA) {
                amountASold = _tick.availableA;
            }
            // Underpays actual price if self, otherwise overpay (to not mess rounding)
            uint128 assetBPayment = denominateAssetAInB(amountASold, _vars.currentPrice, !_self).toU128();

            _tick.availableA -= amountASold.toU120();
            _tick.aToBSubTick.sold += amountASold;
            _tick.aToBSubTick.bought += assetBPayment;

            _vars.offerBInA -= amountASold;
            _vars.protocolSoldA += amountASold;
            _vars.protocolBoughtB += assetBPayment;
        }
    }

    /**
     * @notice Computes the earliest tick where we had available funds
     * @param _earliestTickA The ealiest tick with available A
     * @param _earliestTickB The ealiest tick with available B
     * @return The earliest tick with available assets
     */
    function _earliestUsedTick(uint256 _earliestTickA, uint256 _earliestTickB) internal pure returns (uint256) {
        uint256 start;
        if (_earliestTickA == 0 && _earliestTickB == 0) {
            revert NoDeposits();
        } else if (_earliestTickA * _earliestTickB == 0) {
            // one are zero (the both case is handled explicitly above)
            start = _earliestTickA > _earliestTickB ? _earliestTickA : _earliestTickB;
        } else {
            start = _earliestTickA < _earliestTickB ? _earliestTickA : _earliestTickB;
        }
        return start;
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
// OpenZeppelin Contracts (last updated v4.7.0) (utils/Address.sol)

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
}

// SPDX-License-Identifier: Apache-2.0
// Copyright 2022 Aztec
pragma solidity >=0.8.4;

// @dev For documentation of the functions within this interface see RollupProcessor contract
interface IRollupProcessor {
    /*----------------------------------------
    EVENTS
    ----------------------------------------*/
    event OffchainData(uint256 indexed rollupId, uint256 chunk, uint256 totalChunks, address sender);
    event RollupProcessed(uint256 indexed rollupId, bytes32[] nextExpectedDefiHashes, address sender);
    event DefiBridgeProcessed(
        uint256 indexed encodedBridgeCallData,
        uint256 indexed nonce,
        uint256 totalInputValue,
        uint256 totalOutputValueA,
        uint256 totalOutputValueB,
        bool result,
        bytes errorReason
    );
    event AsyncDefiBridgeProcessed(
        uint256 indexed encodedBridgeCallData,
        uint256 indexed nonce,
        uint256 totalInputValue
    );
    event Deposit(uint256 indexed assetId, address indexed depositorAddress, uint256 depositValue);
    event WithdrawError(bytes errorReason);
    event AssetAdded(uint256 indexed assetId, address indexed assetAddress, uint256 assetGasLimit);
    event BridgeAdded(uint256 indexed bridgeAddressId, address indexed bridgeAddress, uint256 bridgeGasLimit);
    event RollupProviderUpdated(address indexed providerAddress, bool valid);
    event VerifierUpdated(address indexed verifierAddress);
    event Paused(address account);
    event Unpaused(address account);

    /*----------------------------------------
      MUTATING FUNCTIONS
      ----------------------------------------*/

    function pause() external;

    function unpause() external;

    function setRollupProvider(address _provider, bool _valid) external;

    function setVerifier(address _verifier) external;

    function setAllowThirdPartyContracts(bool _allowThirdPartyContracts) external;

    function setDefiBridgeProxy(address _defiBridgeProxy) external;

    function setSupportedAsset(address _token, uint256 _gasLimit) external;

    function setSupportedBridge(address _bridge, uint256 _gasLimit) external;

    function processRollup(bytes calldata _encodedProofData, bytes calldata _signatures) external;

    function receiveEthFromBridge(uint256 _interactionNonce) external payable;

    function approveProof(bytes32 _proofHash) external;

    function depositPendingFunds(
        uint256 _assetId,
        uint256 _amount,
        address _owner,
        bytes32 _proofHash
    ) external payable;

    function offchainData(
        uint256 _rollupId,
        uint256 _chunk,
        uint256 _totalChunks,
        bytes calldata _offchainTxData
    ) external;

    function processAsyncDefiInteraction(uint256 _interactionNonce) external returns (bool);

    /*----------------------------------------
      NON-MUTATING FUNCTIONS
      ----------------------------------------*/

    function rollupStateHash() external view returns (bytes32);

    function userPendingDeposits(uint256 _assetId, address _user) external view returns (uint256);

    function defiBridgeProxy() external view returns (address);

    function prevDefiInteractionsHash() external view returns (bytes32);

    function paused() external view returns (bool);

    function verifier() external view returns (address);

    function getDataSize() external view returns (uint256);

    function getPendingDefiInteractionHashesLength() external view returns (uint256);

    function getDefiInteractionHashesLength() external view returns (uint256);

    function getAsyncDefiInteractionHashesLength() external view returns (uint256);

    function getSupportedBridge(uint256 _bridgeAddressId) external view returns (address);

    function getSupportedBridgesLength() external view returns (uint256);

    function getSupportedAssetsLength() external view returns (uint256);

    function getSupportedAsset(uint256 _assetId) external view returns (address);

    function getEscapeHatchStatus() external view returns (bool, uint256);

    function assetGasLimits(uint256 _bridgeAddressId) external view returns (uint256);

    function bridgeGasLimits(uint256 _bridgeAddressId) external view returns (uint256);
}

// SPDX-License-Identifier: Apache-2.0
// Copyright 2022 Aztec.
pragma solidity >=0.8.4;

import {IDefiBridge} from "../../aztec/interfaces/IDefiBridge.sol";
import {ISubsidy} from "../../aztec/interfaces/ISubsidy.sol";
import {AztecTypes} from "../../aztec/libraries/AztecTypes.sol";
import {ErrorLib} from "./ErrorLib.sol";

/**
 * @title BridgeBase
 * @notice A base that bridges can be built upon which imports a limited set of features
 * @dev Reverts `convert` with missing implementation, and `finalise` with async disabled
 * @author Lasse Herskind
 */
abstract contract BridgeBase is IDefiBridge {
    error MissingImplementation();

    ISubsidy public constant SUBSIDY = ISubsidy(0xABc30E831B5Cc173A9Ed5941714A7845c909e7fA);
    address public immutable ROLLUP_PROCESSOR;

    constructor(address _rollupProcessor) {
        ROLLUP_PROCESSOR = _rollupProcessor;
    }

    modifier onlyRollup() {
        if (msg.sender != ROLLUP_PROCESSOR) {
            revert ErrorLib.InvalidCaller();
        }
        _;
    }

    function convert(
        AztecTypes.AztecAsset calldata,
        AztecTypes.AztecAsset calldata,
        AztecTypes.AztecAsset calldata,
        AztecTypes.AztecAsset calldata,
        uint256,
        uint256,
        uint64,
        address
    )
        external
        payable
        virtual
        override(IDefiBridge)
        returns (
            uint256,
            uint256,
            bool
        )
    {
        revert MissingImplementation();
    }

    function finalise(
        AztecTypes.AztecAsset calldata,
        AztecTypes.AztecAsset calldata,
        AztecTypes.AztecAsset calldata,
        AztecTypes.AztecAsset calldata,
        uint256,
        uint64
    )
        external
        payable
        virtual
        override(IDefiBridge)
        returns (
            uint256,
            uint256,
            bool
        )
    {
        revert ErrorLib.AsyncDisabled();
    }

    /**
     * @notice Computes the criteria that is passed on to the subsidy contract when claiming
     * @dev Should be overridden by bridge implementation if intended to limit subsidy.
     * @return The criteria to be passed along
     */
    function computeCriteria(
        AztecTypes.AztecAsset calldata,
        AztecTypes.AztecAsset calldata,
        AztecTypes.AztecAsset calldata,
        AztecTypes.AztecAsset calldata,
        uint64
    ) public view virtual returns (uint256) {
        return 0;
    }
}

// SPDX-License-Identifier: Apache-2.0
// Copyright 2022 Aztec.
pragma solidity >=0.8.4;

library ErrorLib {
    error InvalidCaller();

    error InvalidInput();
    error InvalidInputA();
    error InvalidInputB();
    error InvalidOutputA();
    error InvalidOutputB();
    error InvalidInputAmount();
    error InvalidAuxData();

    error ApproveFailed(address token);
    error TransferFailed(address token);

    error InvalidNonce();
    error AsyncDisabled();
}

// SPDX-License-Identifier: Apache-2.0
// Copyright 2022 Aztec
pragma solidity >=0.8.4;

library AztecTypes {
    enum AztecAssetType {
        NOT_USED,
        ETH,
        ERC20,
        VIRTUAL
    }

    struct AztecAsset {
        uint256 id;
        address erc20Address;
        AztecAssetType assetType;
    }
}

// SPDX-License-Identifier: Apache-2.0
// Copyright 2022 Aztec.
pragma solidity >=0.8.4;

library SafeCastLib {
    function toU128(uint256 _a) internal pure returns (uint128) {
        if (_a > type(uint128).max) {
            revert("Overflow");
        }
        return uint128(_a);
    }

    function toU120(uint256 _a) internal pure returns (uint120) {
        if (_a > type(uint120).max) {
            revert("Overflow");
        }
        return uint120(_a);
    }

    function toU32(uint256 _a) internal pure returns (uint32) {
        if (_a > type(uint32).max) {
            revert("Overflow");
        }
        return uint32(_a);
    }
}

// SPDX-License-Identifier: Apache-2.0
// Copyright 2022 Aztec
pragma solidity >=0.8.4;

import {AztecTypes} from "../libraries/AztecTypes.sol";

interface IDefiBridge {
    /**
     * @notice A function which converts input assets to output assets.
     * @param _inputAssetA A struct detailing the first input asset
     * @param _inputAssetB A struct detailing the second input asset
     * @param _outputAssetA A struct detailing the first output asset
     * @param _outputAssetB A struct detailing the second output asset
     * @param _totalInputValue An amount of input assets transferred to the bridge (Note: "total" is in the name
     *                         because the value can represent summed/aggregated token amounts of users actions on L2)
     * @param _interactionNonce A globally unique identifier of this interaction/`convert(...)` call.
     * @param _auxData Bridge specific data to be passed into the bridge contract (e.g. slippage, nftID etc.)
     * @return outputValueA An amount of `_outputAssetA` returned from this interaction.
     * @return outputValueB An amount of `_outputAssetB` returned from this interaction.
     * @return isAsync A flag indicating if the interaction is async.
     * @dev This function is called from the RollupProcessor contract via the DefiBridgeProxy. Before this function is
     *      called _RollupProcessor_ contract will have sent you all the assets defined by the input params. This
     *      function is expected to convert input assets to output assets (e.g. on Uniswap) and return the amounts
     *      of output assets to be received by the _RollupProcessor_. If output assets are ERC20 tokens the bridge has
     *      to _RollupProcessor_ as a spender before the interaction is finished. If some of the output assets is ETH
     *      it has to be sent to _RollupProcessor_ via the `receiveEthFromBridge(uint256 _interactionNonce)` method
     *      inside before the `convert(...)` function call finishes.
     * @dev If there are two input assets, equal amounts of both assets will be transferred to the bridge before this
     *      method is called.
     * @dev **BOTH** output assets could be virtual but since their `assetId` is currently assigned as
     *      `_interactionNonce` it would simply mean that more of the same virtual asset is minted.
     * @dev If this interaction is async the function has to return `(0,0 true)`. Async interaction will be finalised at
     *      a later time and its output assets will be returned in a `IDefiBridge.finalise(...)` call.
     **/
    function convert(
        AztecTypes.AztecAsset calldata _inputAssetA,
        AztecTypes.AztecAsset calldata _inputAssetB,
        AztecTypes.AztecAsset calldata _outputAssetA,
        AztecTypes.AztecAsset calldata _outputAssetB,
        uint256 _totalInputValue,
        uint256 _interactionNonce,
        uint64 _auxData,
        address _rollupBeneficiary
    )
        external
        payable
        returns (
            uint256 outputValueA,
            uint256 outputValueB,
            bool isAsync
        );

    /**
     * @notice A function that finalises asynchronous interaction.
     * @param _inputAssetA A struct detailing the first input asset
     * @param _inputAssetB A struct detailing the second input asset
     * @param _outputAssetA A struct detailing the first output asset
     * @param _outputAssetB A struct detailing the second output asset
     * @param _interactionNonce A globally unique identifier of this interaction/`convert(...)` call.
     * @param _auxData Bridge specific data to be passed into the bridge contract (e.g. slippage, nftID etc.)
     * @return outputValueA An amount of `_outputAssetA` returned from this interaction.
     * @return outputValueB An amount of `_outputAssetB` returned from this interaction.
     * @dev This function should use the `BridgeBase.onlyRollup()` modifier to ensure it can only be called from
     *      the `RollupProcessor.processAsyncDefiInteraction(uint256 _interactionNonce)` method.
     **/
    function finalise(
        AztecTypes.AztecAsset calldata _inputAssetA,
        AztecTypes.AztecAsset calldata _inputAssetB,
        AztecTypes.AztecAsset calldata _outputAssetA,
        AztecTypes.AztecAsset calldata _outputAssetB,
        uint256 _interactionNonce,
        uint64 _auxData
    )
        external
        payable
        returns (
            uint256 outputValueA,
            uint256 outputValueB,
            bool interactionComplete
        );
}

// SPDX-License-Identifier: Apache-2.0
// Copyright 2022 Aztec
pragma solidity >=0.8.4;

// @dev documentation of this interface is in its implementation (Subsidy contract)
interface ISubsidy {
    /**
     * @notice Container for Subsidy related information
     * @member available Amount of ETH remaining to be paid out
     * @member gasUsage Amount of gas the interaction consumes (used to define max possible payout)
     * @member minGasPerMinute Minimum amount of gas per minute the subsidizer has to subsidize
     * @member gasPerMinute Amount of gas per minute the subsidizer is willing to subsidize
     * @member lastUpdated Last time subsidy was paid out or funded (if not subsidy was yet claimed after funding)
     */
    struct Subsidy {
        uint128 available;
        uint32 gasUsage;
        uint32 minGasPerMinute;
        uint32 gasPerMinute;
        uint32 lastUpdated;
    }

    function setGasUsageAndMinGasPerMinute(
        uint256 _criteria,
        uint32 _gasUsage,
        uint32 _minGasPerMinute
    ) external;

    function setGasUsageAndMinGasPerMinute(
        uint256[] calldata _criteria,
        uint32[] calldata _gasUsage,
        uint32[] calldata _minGasPerMinute
    ) external;

    function registerBeneficiary(address _beneficiary) external;

    function subsidize(
        address _bridge,
        uint256 _criteria,
        uint32 _gasPerMinute
    ) external payable;

    function topUp(address _bridge, uint256 _criteria) external payable;

    function claimSubsidy(uint256 _criteria, address _beneficiary) external returns (uint256);

    function withdraw(address _beneficiary) external returns (uint256);

    // solhint-disable-next-line
    function MIN_SUBSIDY_VALUE() external view returns (uint256);

    function claimableAmount(address _beneficiary) external view returns (uint256);

    function isRegistered(address _beneficiary) external view returns (bool);

    function getSubsidy(address _bridge, uint256 _criteria) external view returns (Subsidy memory);

    function getAccumulatedSubsidyAmount(address _bridge, uint256 _criteria) external view returns (uint256);
}