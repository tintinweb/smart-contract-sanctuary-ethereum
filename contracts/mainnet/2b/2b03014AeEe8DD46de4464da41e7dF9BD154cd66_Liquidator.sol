// SPDX-License-Identifier: MIT
pragma solidity 0.8.15;

import "./vendor/@uniswap/v3-core/contracts/interfaces/callback/IUniswapV3FlashCallback.sol";
import "./vendor/@uniswap/v3-periphery/contracts/base/PeripheryPayments.sol";
import "./vendor/@uniswap/v3-periphery/contracts/base/PeripheryImmutableState.sol";
import "./vendor/@uniswap/v3-periphery/contracts/libraries/PoolAddress.sol";
import "./vendor/@uniswap/v3-periphery/contracts/libraries/CallbackValidation.sol";
import "./vendor/@uniswap/v3-periphery/contracts/libraries/TransferHelper.sol";
import "./vendor/@uniswap/v3-periphery/contracts/interfaces/ISwapRouter.sol";

import "../CometInterface.sol";
import "../ERC20.sol";

/**
 * @title Compound's Example Liquidator Contract
 * @notice An example of liquidation bot, a starting point for further improvements
 * @author Compound
 */
contract Liquidator is IUniswapV3FlashCallback, PeripheryImmutableState, PeripheryPayments {
    /** Events **/
    event Absorb(address indexed initiator, address[] accounts);
    event Pay(address indexed token, address indexed payer, address indexed recipient, uint256 value);
    event Swap(address indexed tokenIn, address indexed tokenOut, uint24 fee, uint256 amountIn);

    /** Structs needed for Uniswap flash swap **/
    struct FlashParams {
        address[] accounts;
        address pairToken;
        uint24 poolFee;
    }

    struct FlashCallbackData {
        uint256 amount;
        address recipient;
        PoolAddress.PoolKey poolKey;
        address[] assets;
        uint256[] baseAmounts;
    }

    struct UniswapPoolConfig {
        bool isLowLiquidity;
        uint24 fee;
    }

    /** Liquidator configuration constants **/

    /// @notice The scale for asset price calculations
    uint256 public constant QUOTE_PRICE_SCALE = 1e18;

    /// @notice Uniswap standard pool fee, used if custom fee is not specified for the pool
    uint24 public constant DEFAULT_POOL_FEE = 500;

    /// @notice Address to send liquidation proceeds to
    address public immutable recipient;

    /// @notice Uniswap router used for token exchange
    ISwapRouter public immutable swapRouter;

    /// @notice Compound Comet protocol
    CometInterface public immutable comet;

    /// @notice Minimum available amount for liquidation in USDC (base token)
    uint256 public immutable liquidationThreshold;

    /// @notice The address of WETH asset
    address public immutable weth;

    /// @notice The Uniswap asset pool configurations
    mapping(address => UniswapPoolConfig) public poolConfigs;

    /**
     * @notice Construct a new liquidator instance
     * @param _recipient The address to send all proceeds to
     * @param _swapRouter The Uniswap V3 Swap router address
     * @param _comet The Compound V3 Comet instance address
     * @param _factory The Uniswap V3 pools factory instance address
     * @param _WETH9 The WETH address
     * @param _liquidationThreshold The min size of asset liquidations measured in base token
     * @param _assets The list of assets for pool configs
     * @param _lowLiquidityPools The list of boolean indicators if pool is low liquidity and requires ETH swap
     * @param _poolFees The list of given poolFees for assets
     **/
    constructor(
        address _recipient,
        ISwapRouter _swapRouter,
        CometInterface _comet,
        address _factory,
        address _WETH9,
        uint256 _liquidationThreshold,
        address[] memory _assets,
        bool[] memory _lowLiquidityPools,
        uint24[] memory _poolFees
    ) PeripheryImmutableState(_factory, _WETH9) {
        require(_assets.length == _lowLiquidityPools.length, "Wrong data");
        require(_assets.length == _poolFees.length, "Wrong data");

        recipient = _recipient;
        swapRouter = _swapRouter;
        comet = _comet;
        weth = _WETH9;
        liquidationThreshold = _liquidationThreshold;

        // Set pool configs for all given assets
        for (uint8 i = 0; i < _assets.length; i++) {
            address asset = _assets[i];
            bool lowLiquidity = _lowLiquidityPools[i];
            uint24 poolFee = _poolFees[i];
            poolConfigs[asset] = UniswapPoolConfig({isLowLiquidity: lowLiquidity, fee: poolFee});
        }
    }

    /**
     * @dev Returns Uniswap pool config for given asset
     */
    function getPoolConfigForAsset(address asset) internal view returns(UniswapPoolConfig memory) {
        UniswapPoolConfig memory config = poolConfigs[asset];
        // If asset is not found, proceed with default pool config
        if (config.fee == 0) {
            return UniswapPoolConfig({
                fee: DEFAULT_POOL_FEE,
                isLowLiquidity: false
            });
        }
        return config;
    }

    /**
     * @dev Swaps the given asset to USDC (base token) using Uniswap pools
     */
    function swapCollateral(address asset) internal returns (uint256) {
        uint256 swapAmount = ERC20(asset).balanceOf(address(this));
        // Safety check, make sure residue balance in protocol is ignored
        if (swapAmount == 0) return 0;

        UniswapPoolConfig memory poolConfig = getPoolConfigForAsset(asset);
        uint24 poolFee = poolConfig.fee;
        address swapToken = asset;

        address baseToken = comet.baseToken();

        TransferHelper.safeApprove(asset, address(swapRouter), swapAmount);
        // For low liquidity asset, swap it to ETH first
        if (poolConfig.isLowLiquidity) {
            swapAmount = swapRouter.exactInputSingle(
                ISwapRouter.ExactInputSingleParams({
                    tokenIn: asset,
                    tokenOut: weth,
                    fee: poolFee,
                    recipient: address(this),
                    deadline: block.timestamp,
                    amountIn: swapAmount,
                    amountOutMinimum: 0,
                    sqrtPriceLimitX96: 0
                })
            );
            emit Swap(asset, weth, poolFee, swapAmount);
            swapToken = weth;
            poolFee = getPoolConfigForAsset(weth).fee;

            TransferHelper.safeApprove(weth, address(swapRouter), swapAmount);
        }

        // Swap asset or received ETH to base asset
        uint256 amountOut = swapRouter.exactInputSingle(
            ISwapRouter.ExactInputSingleParams({
                tokenIn: swapToken,
                tokenOut: baseToken,
                fee: poolFee,
                recipient: address(this),
                deadline: block.timestamp,
                amountIn: swapAmount,
                amountOutMinimum: 0,
                sqrtPriceLimitX96: 0
            })
        );
        emit Swap(swapToken, baseToken, poolFee, swapAmount);

        return amountOut;
    }

    /**
     * @notice Uniswap flashloan callback
     * @param fee0 The fee for borrowing token0 from pool
     * @param fee1 The fee for borrowing token1 from pool
     * @param data The encoded data passed from loan initiation function
     */
    function uniswapV3FlashCallback(
        uint256 fee0,
        uint256 fee1,
        bytes calldata data
    ) external override {
        // Verify uniswap callback, recommended security measure
        FlashCallbackData memory decoded = abi.decode(data, (FlashCallbackData));
        CallbackValidation.verifyCallback(factory, decoded.poolKey);

        address[] memory assets = decoded.assets;

        // Allow Comet protocol to withdraw USDC (base token) for collateral purchase
        TransferHelper.safeApprove(comet.baseToken(), address(comet), decoded.amount);

        uint256 totalAmountOut = 0;
        for (uint i = 0; i < assets.length; i++) {
            address asset = assets[i];
            uint256 baseAmount = decoded.baseAmounts[i];

            if (baseAmount == 0) continue;

            comet.buyCollateral(asset, 0, baseAmount, address(this));
            uint256 amountOut = swapCollateral(asset);
            totalAmountOut += amountOut;
        }

        // We borrow only 1 asset, so one of fees will be 0
        uint256 fee = fee0 + fee1;
        // Payback flashloan to Uniswap pool and profit to the caller
        payback(decoded.amount, fee, comet.baseToken(), totalAmountOut);
    }

    /**
     * @dev Returns loan to Uniswap pool and sends USDC (base token) profit to caller
     * @param amount The loan amount that need to be repaid
     * @param fee The fee for taking the loan
     * @param token The base token which was borrowed for successful liquidation
     * @param amountOut The total amount of base token received after liquidation
     */
    function payback(
        uint256 amount,
        uint256 fee,
        address token,
        uint256 amountOut
    ) internal {
        uint256 amountOwed = amount + fee;
        TransferHelper.safeApprove(token, address(this), amountOwed);

        // Repay the loan
        if (amountOwed > 0) {
            pay(token, address(this), msg.sender, amountOwed);
            emit Pay(token, address(this), msg.sender, amountOwed);
        }

        // If profitable, pay profits to the caller
        if (amountOut > amountOwed) {
            uint256 profit = amountOut - amountOwed;
            TransferHelper.safeApprove(token, address(this), profit);
            pay(token, address(this), recipient, profit);
            emit Pay(token, address(this), recipient, profit);
        }
    }

    /**
     * @dev Calculates the total amount of base asset needed to buy all the discounted collateral from the protocol
     */
    function calculateTotalBaseAmount() internal view returns (uint256, uint256[] memory, address[] memory) {
        uint256 totalBaseAmount = 0;
        uint8 numAssets = comet.numAssets();
        uint256[] memory assetBaseAmounts = new uint256[](numAssets);
        address[] memory cometAssets = new address[](numAssets);
        for (uint8 i = 0; i < numAssets; i++) {
            address asset = comet.getAssetInfo(i).asset;
            cometAssets[i] = asset;
            uint256 collateralBalance = comet.collateralBalanceOf(address(comet), asset);

            if (collateralBalance == 0) continue;

            // Find the price in asset needed to base QUOTE_PRICE_SCALE of USDC (base token) of collateral
            uint256 quotePrice = comet.quoteCollateral(asset, QUOTE_PRICE_SCALE * comet.baseScale());
            uint256 assetBaseAmount = comet.baseScale() * QUOTE_PRICE_SCALE * collateralBalance / quotePrice;

            // Liquidate only positions with adequate size, no need to collect residue from protocol
            if (assetBaseAmount < liquidationThreshold) continue;

            assetBaseAmounts[i] = assetBaseAmount;
            totalBaseAmount += assetBaseAmount;
        }

        return (totalBaseAmount, assetBaseAmounts, cometAssets);
    }

    /**
     * @notice Calls the pools flash function with data needed in `uniswapV3FlashCallback`
     * @param params The parameters necessary for flash and the callback, passed in as FlashParams
     */
    function initFlash(FlashParams memory params) external {
        // Absorb Comet underwater accounts
        comet.absorb(address(this), params.accounts);
        emit Absorb(msg.sender, params.accounts);

        (uint256 totalBaseAmount, uint256[] memory assetBaseAmounts, address[] memory cometAssets) = calculateTotalBaseAmount();

        address poolToken0 = params.pairToken;
        address poolToken1 = comet.baseToken();
        bool reversedPair = poolToken0 > poolToken1;
        // Use Uniswap approach to determining order of tokens https://github.com/Uniswap/v3-periphery/blob/main/contracts/libraries/PoolAddress.sol#L20-L27
        if (reversedPair) (poolToken0, poolToken1) = (poolToken1, poolToken0);

        // Find the desired Uniswap pool to borrow base token from, for ex DAI-USDC
        PoolAddress.PoolKey memory poolKey =
            PoolAddress.PoolKey({token0: poolToken0, token1: poolToken1, fee: params.poolFee});
        IUniswapV3Pool pool = IUniswapV3Pool(PoolAddress.computeAddress(factory, poolKey));

        // recipient of borrowed amounts
        // amount of token0 requested to borrow, 0 for non reversed pair
        // amount of token1 requested to borrow, 0 for reversed pair
        // need amount in callback to pay back pool
        // need assets addresses to buy collateral from protocol
        // need baseAmounts to buy collateral from protocol
        // recipient of flash should be THIS contract
        pool.flash(
            address(this),
            reversedPair ? totalBaseAmount : 0,
            reversedPair ? 0 : totalBaseAmount,
            abi.encode(
                FlashCallbackData({
                    amount: totalBaseAmount,
                    recipient: msg.sender,
                    poolKey: poolKey,
                    assets: cometAssets,
                    baseAmounts: assetBaseAmounts
                })
            )
        );
    }
}

// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity >=0.5.0;

/// @title Callback for IUniswapV3PoolActions#flash
/// @notice Any contract that calls IUniswapV3PoolActions#flash must implement this interface
interface IUniswapV3FlashCallback {
    /// @notice Called to `msg.sender` after transferring to the recipient from IUniswapV3Pool#flash.
    /// @dev In the implementation you must repay the pool the tokens sent by flash plus the computed fee amounts.
    /// The caller of this method must be checked to be a UniswapV3Pool deployed by the canonical UniswapV3Factory.
    /// @param fee0 The fee amount in token0 due to the pool by the end of the flash
    /// @param fee1 The fee amount in token1 due to the pool by the end of the flash
    /// @param data Any data passed through by the caller via the IUniswapV3PoolActions#flash call
    function uniswapV3FlashCallback(
        uint256 fee0,
        uint256 fee1,
        bytes calldata data
    ) external;
}

// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity >=0.7.5;

import '../../../../@openzeppelin/contracts/token/ERC20/IERC20.sol';

import '../interfaces/IPeripheryPayments.sol';
import '../interfaces/external/IWETH9.sol';

import '../libraries/TransferHelper.sol';

import './PeripheryImmutableState.sol';

abstract contract PeripheryPayments is IPeripheryPayments, PeripheryImmutableState {
    receive() external payable {
        require(msg.sender == WETH9, 'Not WETH9');
    }

    /// @inheritdoc IPeripheryPayments
    function unwrapWETH9(uint256 amountMinimum, address recipient) public payable override {
        uint256 balanceWETH9 = IWETH9(WETH9).balanceOf(address(this));
        require(balanceWETH9 >= amountMinimum, 'Insufficient WETH9');

        if (balanceWETH9 > 0) {
            IWETH9(WETH9).withdraw(balanceWETH9);
            TransferHelper.safeTransferETH(recipient, balanceWETH9);
        }
    }

    /// @inheritdoc IPeripheryPayments
    function sweepToken(
        address token,
        uint256 amountMinimum,
        address recipient
    ) public payable override {
        uint256 balanceToken = IERC20(token).balanceOf(address(this));
        require(balanceToken >= amountMinimum, 'Insufficient token');

        if (balanceToken > 0) {
            TransferHelper.safeTransfer(token, recipient, balanceToken);
        }
    }

    /// @inheritdoc IPeripheryPayments
    function refundETH() external payable override {
        if (address(this).balance > 0) TransferHelper.safeTransferETH(msg.sender, address(this).balance);
    }

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

// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity 0.8.15;

import '../interfaces/IPeripheryImmutableState.sol';

/// @title Immutable state
/// @notice Immutable state used by periphery contracts
abstract contract PeripheryImmutableState is IPeripheryImmutableState {
    /// @inheritdoc IPeripheryImmutableState
    address public immutable override factory;
    /// @inheritdoc IPeripheryImmutableState
    address public immutable override WETH9;

    constructor(address _factory, address _WETH9) {
        factory = _factory;
        WETH9 = _WETH9;
    }
}

// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity >=0.5.0;

/// @title Provides functions for deriving a pool address from the factory, tokens, and the fee
library PoolAddress {
    bytes32 internal constant POOL_INIT_CODE_HASH = 0xe34f199b19b2b4f47f68442619d555527d244f78a3297ea89325f843f87b8b54;

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
    function computeAddress(address factory, PoolKey memory key) internal pure returns (address pool) {
        require(key.token0 < key.token1);
        pool = address(
            uint160(
                uint256(
                    keccak256(
                        abi.encodePacked(
                            hex'ff',
                            factory,
                            keccak256(abi.encode(key.token0, key.token1, key.fee)),
                            POOL_INIT_CODE_HASH
                        )
                    )
                )
            )
        );
    }
}

// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity 0.8.15;

import '../../../v3-core/contracts/interfaces/IUniswapV3Pool.sol';
import './PoolAddress.sol';

/// @notice Provides validation for callbacks from Uniswap V3 Pools
library CallbackValidation {
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
        return verifyCallback(factory, PoolAddress.getPoolKey(tokenA, tokenB, fee));
    }

    /// @notice Returns the address of a valid Uniswap V3 Pool
    /// @param factory The contract address of the Uniswap V3 factory
    /// @param poolKey The identifying key of the V3 pool
    /// @return pool The V3 pool contract address
    function verifyCallback(address factory, PoolAddress.PoolKey memory poolKey)
        internal
        view
        returns (IUniswapV3Pool pool)
    {
        pool = IUniswapV3Pool(PoolAddress.computeAddress(factory, poolKey));
        require(msg.sender == address(pool));
    }
}

// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity >=0.6.0;

import '../../../../@openzeppelin/contracts/token/ERC20/IERC20.sol';

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
        (bool success, bytes memory data) =
            token.call(abi.encodeWithSelector(IERC20.transferFrom.selector, from, to, value));
        require(success && (data.length == 0 || abi.decode(data, (bool))), 'STF');
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
        (bool success, bytes memory data) = token.call(abi.encodeWithSelector(IERC20.transfer.selector, to, value));
        require(success && (data.length == 0 || abi.decode(data, (bool))), 'ST');
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
        (bool success, bytes memory data) = token.call(abi.encodeWithSelector(IERC20.approve.selector, to, value));
        require(success && (data.length == 0 || abi.decode(data, (bool))), 'SA');
    }

    /// @notice Transfers ETH to the recipient address
    /// @dev Fails with `STE`
    /// @param to The destination of the transfer
    /// @param value The value to be transferred
    function safeTransferETH(address to, uint256 value) internal {
        (bool success, ) = to.call{value: value}(new bytes(0));
        require(success, 'STE');
    }
}

// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity >=0.7.5;
pragma abicoder v2;

import '../../../v3-core/contracts/interfaces/callback/IUniswapV3SwapCallback.sol';

/// @title Router token swapping functionality
/// @notice Functions for swapping tokens via Uniswap V3
interface ISwapRouter is IUniswapV3SwapCallback {
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

// SPDX-License-Identifier: BUSL-1.1
pragma solidity 0.8.15;

import "./CometMainInterface.sol";
import "./CometExtInterface.sol";

/**
 * @title Compound's Comet Interface
 * @notice An efficient monolithic money market protocol
 * @author Compound
 */
abstract contract CometInterface is CometMainInterface, CometExtInterface {}

// SPDX-License-Identifier: BUSL-1.1
pragma solidity 0.8.15;

/**
 * @title ERC 20 Token Standard Interface
 *  https://eips.ethereum.org/EIPS/eip-20
 */
interface ERC20 {
    function name() external view returns (string memory);
    function symbol() external view returns (string memory);
    function decimals() external view returns (uint8);

    /**
      * @notice Get the total number of tokens in circulation
      * @return The supply of tokens
      */
    function totalSupply() external view returns (uint256);

    /**
     * @notice Gets the balance of the specified address
     * @param owner The address from which the balance will be retrieved
     * @return The balance
     */
    function balanceOf(address owner) external view returns (uint256);

    /**
      * @notice Transfer `amount` tokens from `msg.sender` to `dst`
      * @param dst The address of the destination account
      * @param amount The number of tokens to transfer
      * @return Whether or not the transfer succeeded
      */
    function transfer(address dst, uint256 amount) external returns (bool);

    /**
      * @notice Transfer `amount` tokens from `src` to `dst`
      * @param src The address of the source account
      * @param dst The address of the destination account
      * @param amount The number of tokens to transfer
      * @return Whether or not the transfer succeeded
      */
    function transferFrom(address src, address dst, uint256 amount) external returns (bool);

    /**
      * @notice Approve `spender` to transfer up to `amount` from `src`
      * @dev This will overwrite the approval amount for `spender`
      *  and is subject to issues noted [here](https://eips.ethereum.org/EIPS/eip-20#approve)
      * @param spender The address of the account which may transfer tokens
      * @param amount The number of tokens that are approved (-1 means infinite)
      * @return Whether or not the approval succeeded
      */
    function approve(address spender, uint256 amount) external returns (bool);

    /**
      * @notice Get the current allowance from `owner` for `spender`
      * @param owner The address of the account which owns the tokens to be spent
      * @param spender The address of the account which may transfer tokens
      * @return The number of tokens allowed to be spent (-1 means infinite)
      */
    function allowance(address owner, address spender) external view returns (uint256);

    event Transfer(address indexed from, address indexed to, uint256 amount);
    event Approval(address indexed owner, address indexed spender, uint256 amount);
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

// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity >=0.7.5;

/// @title Periphery Payments
/// @notice Functions to ease deposits and withdrawals of ETH
interface IPeripheryPayments {
    /// @notice Unwraps the contract's WETH9 balance and sends it to recipient as ETH.
    /// @dev The amountMinimum parameter prevents malicious contracts from stealing WETH9 from users.
    /// @param amountMinimum The minimum amount of WETH9 to unwrap
    /// @param recipient The address receiving ETH
    function unwrapWETH9(uint256 amountMinimum, address recipient) external payable;

    /// @notice Refunds any ETH balance held by this contract to the `msg.sender`
    /// @dev Useful for bundling with mint or increase liquidity that uses ether, or exact output swaps
    /// that use ether for the input amount
    function refundETH() external payable;

    /// @notice Transfers the full amount of a token held by this contract to recipient
    /// @dev The amountMinimum parameter prevents malicious contracts from stealing the token from users
    /// @param token The contract address of the token which will be transferred to `recipient`
    /// @param amountMinimum The minimum amount of token required for a transfer
    /// @param recipient The destination address of the token
    function sweepToken(
        address token,
        uint256 amountMinimum,
        address recipient
    ) external payable;
}

// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity 0.8.15;

import '../../../../../@openzeppelin/contracts/token/ERC20/IERC20.sol';

/// @title Interface for WETH9
interface IWETH9 is IERC20 {
    /// @notice Deposit ether to get wrapped ether
    function deposit() external payable;

    /// @notice Withdraw wrapped ether to get ether
    function withdraw(uint256) external;
}

// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity >=0.5.0;

/// @title Immutable state
/// @notice Functions that return immutable state of the router
interface IPeripheryImmutableState {
    /// @return Returns the address of the Uniswap V3 factory
    function factory() external view returns (address);

    /// @return Returns the address of WETH9
    function WETH9() external view returns (address);
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

// SPDX-License-Identifier: BUSL-1.1
pragma solidity 0.8.15;

import "./CometCore.sol";

/**
 * @title Compound's Comet Main Interface (without Ext)
 * @notice An efficient monolithic money market protocol
 * @author Compound
 */
abstract contract CometMainInterface is CometCore {
    event Supply(address indexed from, address indexed dst, uint amount);
    event Transfer(address indexed from, address indexed to, uint amount);
    event Withdraw(address indexed src, address indexed to, uint amount);

    event SupplyCollateral(address indexed from, address indexed dst, address indexed asset, uint amount);
    event TransferCollateral(address indexed from, address indexed to, address indexed asset, uint amount);
    event WithdrawCollateral(address indexed src, address indexed to, address indexed asset, uint amount);

    /// @notice Event emitted when a borrow position is absorbed by the protocol
    event AbsorbDebt(address indexed absorber, address indexed borrower, uint basePaidOut, uint usdValue);

    /// @notice Event emitted when a user's collateral is absorbed by the protocol
    event AbsorbCollateral(address indexed absorber, address indexed borrower, address indexed asset, uint collateralAbsorbed, uint usdValue);

    /// @notice Event emitted when a collateral asset is purchased from the protocol
    event BuyCollateral(address indexed buyer, address indexed asset, uint baseAmount, uint collateralAmount);

    /// @notice Event emitted when an action is paused/unpaused
    event PauseAction(bool supplyPaused, bool transferPaused, bool withdrawPaused, bool absorbPaused, bool buyPaused);

    /// @notice Event emitted when reserves are withdrawn by the governor
    event WithdrawReserves(address indexed to, uint amount);

    function supply(address asset, uint amount) virtual external;
    function supplyTo(address dst, address asset, uint amount) virtual external;
    function supplyFrom(address from, address dst, address asset, uint amount) virtual external;

    function transfer(address dst, uint amount) virtual external returns (bool);
    function transferFrom(address src, address dst, uint amount) virtual external returns (bool);

    function transferAsset(address dst, address asset, uint amount) virtual external;
    function transferAssetFrom(address src, address dst, address asset, uint amount) virtual external;

    function withdraw(address asset, uint amount) virtual external;
    function withdrawTo(address to, address asset, uint amount) virtual external;
    function withdrawFrom(address src, address to, address asset, uint amount) virtual external;

    function approveThis(address manager, address asset, uint amount) virtual external;
    function withdrawReserves(address to, uint amount) virtual external;

    function absorb(address absorber, address[] calldata accounts) virtual external;
    function buyCollateral(address asset, uint minAmount, uint baseAmount, address recipient) virtual external;
    function quoteCollateral(address asset, uint baseAmount) virtual public view returns (uint);

    function getAssetInfo(uint8 i) virtual public view returns (AssetInfo memory);
    function getAssetInfoByAddress(address asset) virtual public view returns (AssetInfo memory);
    function getReserves() virtual public view returns (int);
    function getPrice(address priceFeed) virtual public view returns (uint);

    function isBorrowCollateralized(address account) virtual public view returns (bool);
    function isLiquidatable(address account) virtual public view returns (bool);

    function totalSupply() virtual external view returns (uint256);
    function totalBorrow() virtual external view returns (uint256);
    function balanceOf(address owner) virtual public view returns (uint256);
    function borrowBalanceOf(address account) virtual public view returns (uint256);

    function pause(bool supplyPaused, bool transferPaused, bool withdrawPaused, bool absorbPaused, bool buyPaused) virtual external;
    function isSupplyPaused() virtual public view returns (bool);
    function isTransferPaused() virtual public view returns (bool);
    function isWithdrawPaused() virtual public view returns (bool);
    function isAbsorbPaused() virtual public view returns (bool);
    function isBuyPaused() virtual public view returns (bool);

    function accrueAccount(address account) virtual external;
    function getSupplyRate(uint utilization) virtual public view returns (uint64);
    function getBorrowRate(uint utilization) virtual public view returns (uint64);
    function getUtilization() virtual public view returns (uint);

    function governor() virtual external view returns (address);
    function pauseGuardian() virtual external view returns (address);
    function baseToken() virtual external view returns (address);
    function baseTokenPriceFeed() virtual external view returns (address);
    function extensionDelegate() virtual external view returns (address);

    /// @dev uint64
    function supplyKink() virtual external view returns (uint);
    /// @dev uint64
    function supplyPerSecondInterestRateSlopeLow() virtual external view returns (uint);
    /// @dev uint64
    function supplyPerSecondInterestRateSlopeHigh() virtual external view returns (uint);
    /// @dev uint64
    function supplyPerSecondInterestRateBase() virtual external view returns (uint);
    /// @dev uint64
    function borrowKink() virtual external view returns (uint);
    /// @dev uint64
    function borrowPerSecondInterestRateSlopeLow() virtual external view returns (uint);
    /// @dev uint64
    function borrowPerSecondInterestRateSlopeHigh() virtual external view returns (uint);
    /// @dev uint64
    function borrowPerSecondInterestRateBase() virtual external view returns (uint);
    /// @dev uint64
    function storeFrontPriceFactor() virtual external view returns (uint);

    /// @dev uint64
    function baseScale() virtual external view returns (uint);
    /// @dev uint64
    function trackingIndexScale() virtual external view returns (uint);

    /// @dev uint64
    function baseTrackingSupplySpeed() virtual external view returns (uint);
    /// @dev uint64
    function baseTrackingBorrowSpeed() virtual external view returns (uint);
    /// @dev uint104
    function baseMinForRewards() virtual external view returns (uint);
    /// @dev uint104
    function baseBorrowMin() virtual external view returns (uint);
    /// @dev uint104
    function targetReserves() virtual external view returns (uint);

    function numAssets() virtual external view returns (uint8);
    function decimals() virtual external view returns (uint8);

    function initializeStorage() virtual external;
}

// SPDX-License-Identifier: BUSL-1.1
pragma solidity 0.8.15;

import "./CometCore.sol";

/**
 * @title Compound's Comet Ext Interface
 * @notice An efficient monolithic money market protocol
 * @author Compound
 */
abstract contract CometExtInterface is CometCore {
    function allow(address manager, bool isAllowed) virtual external;
    function allowBySig(address owner, address manager, bool isAllowed, uint256 nonce, uint256 expiry, uint8 v, bytes32 r, bytes32 s) virtual external;

    function collateralBalanceOf(address account, address asset) virtual external view returns (uint128);
    function baseTrackingAccrued(address account) virtual external view returns (uint64);

    function baseAccrualScale() virtual external view returns (uint64);
    function baseIndexScale() virtual external view returns (uint64);
    function factorScale() virtual external view returns (uint64);
    function priceScale() virtual external view returns (uint64);

    function maxAssets() virtual external view returns (uint8);

    function totalsBasic() virtual external view returns (TotalsBasic memory);

    function version() virtual external view returns (string memory);

    /**
      * ===== ERC20 interfaces =====
      * Does not include the following functions/events, which are defined in `CometMainInterface` instead:
      * - function decimals() virtual external view returns (uint8)
      * - function totalSupply() virtual external view returns (uint256)
      * - function transfer(address dst, uint amount) virtual external returns (bool)
      * - function transferFrom(address src, address dst, uint amount) virtual external returns (bool)
      * - function balanceOf(address owner) virtual external view returns (uint256)
      * - event Transfer(address indexed from, address indexed to, uint256 amount)
      */
    function name() virtual external view returns (string memory);
    function symbol() virtual external view returns (string memory);

    /**
      * @notice Approve `spender` to transfer up to `amount` from `src`
      * @dev This will overwrite the approval amount for `spender`
      *  and is subject to issues noted [here](https://eips.ethereum.org/EIPS/eip-20#approve)
      * @param spender The address of the account which may transfer tokens
      * @param amount The number of tokens that are approved (-1 means infinite)
      * @return Whether or not the approval succeeded
      */
    function approve(address spender, uint256 amount) virtual external returns (bool);

    /**
      * @notice Get the current allowance from `owner` for `spender`
      * @param owner The address of the account which owns the tokens to be spent
      * @param spender The address of the account which may transfer tokens
      * @return The number of tokens allowed to be spent (-1 means infinite)
      */
    function allowance(address owner, address spender) virtual external view returns (uint256);

    event Approval(address indexed owner, address indexed spender, uint256 amount);
}

// SPDX-License-Identifier: BUSL-1.1
pragma solidity 0.8.15;

import "./CometConfiguration.sol";
import "./CometStorage.sol";
import "./CometMath.sol";
import "./vendor/@chainlink/contracts/src/v0.8/interfaces/AggregatorV3Interface.sol";

abstract contract CometCore is CometConfiguration, CometStorage, CometMath {
    struct AssetInfo {
        uint8 offset;
        address asset;
        address priceFeed;
        uint64 scale;
        uint64 borrowCollateralFactor;
        uint64 liquidateCollateralFactor;
        uint64 liquidationFactor;
        uint128 supplyCap;
    }

    /** Internal constants **/

    /// @dev The max number of assets this contract is hardcoded to support
    ///  Do not change this variable without updating all the fields throughout the contract,
    //    including the size of UserBasic.assetsIn and corresponding integer conversions.
    uint8 internal constant MAX_ASSETS = 15;

    /// @dev The max number of decimals base token can have
    ///  Note this cannot just be increased arbitrarily.
    uint8 internal constant MAX_BASE_DECIMALS = 18;

    /// @dev The max value for a collateral factor (1)
    uint64 internal constant MAX_COLLATERAL_FACTOR = FACTOR_SCALE;

    /// @dev Offsets for specific actions in the pause flag bit array
    uint8 internal constant PAUSE_SUPPLY_OFFSET = 0;
    uint8 internal constant PAUSE_TRANSFER_OFFSET = 1;
    uint8 internal constant PAUSE_WITHDRAW_OFFSET = 2;
    uint8 internal constant PAUSE_ABSORB_OFFSET = 3;
    uint8 internal constant PAUSE_BUY_OFFSET = 4;

    /// @dev The decimals required for a price feed
    uint8 internal constant PRICE_FEED_DECIMALS = 8;

    /// @dev 365 days * 24 hours * 60 minutes * 60 seconds
    uint64 internal constant SECONDS_PER_YEAR = 31_536_000;

    /// @dev The scale for base tracking accrual
    uint64 internal constant BASE_ACCRUAL_SCALE = 1e6;

    /// @dev The scale for base index (depends on time/rate scales, not base token)
    uint64 internal constant BASE_INDEX_SCALE = 1e15;

    /// @dev The scale for prices (in USD)
    uint64 internal constant PRICE_SCALE = uint64(10 ** PRICE_FEED_DECIMALS);

    /// @dev The scale for factors
    uint64 internal constant FACTOR_SCALE = 1e18;

    /**
     * @notice Determine if the manager has permission to act on behalf of the owner
     * @param owner The owner account
     * @param manager The manager account
     * @return Whether or not the manager has permission
     */
    function hasPermission(address owner, address manager) public view returns (bool) {
        return owner == manager || isAllowed[owner][manager];
    }

    /**
     * @dev The positive present supply balance if positive or the negative borrow balance if negative
     */
    function presentValue(int104 principalValue_) internal view returns (int256) {
        if (principalValue_ >= 0) {
            return signed256(presentValueSupply(baseSupplyIndex, uint104(principalValue_)));
        } else {
            return -signed256(presentValueBorrow(baseBorrowIndex, uint104(-principalValue_)));
        }
    }

    /**
     * @dev The principal amount projected forward by the supply index
     */
    function presentValueSupply(uint64 baseSupplyIndex_, uint104 principalValue_) internal pure returns (uint256) {
        return uint256(principalValue_) * baseSupplyIndex_ / BASE_INDEX_SCALE;
    }

    /**
     * @dev The principal amount projected forward by the borrow index
     */
    function presentValueBorrow(uint64 baseBorrowIndex_, uint104 principalValue_) internal pure returns (uint256) {
        return uint256(principalValue_) * baseBorrowIndex_ / BASE_INDEX_SCALE;
    }

    /**
     * @dev The positive principal if positive or the negative principal if negative
     */
    function principalValue(int256 presentValue_) internal view returns (int104) {
        if (presentValue_ >= 0) {
            return signed104(principalValueSupply(baseSupplyIndex, uint256(presentValue_)));
        } else {
            return -signed104(principalValueBorrow(baseBorrowIndex, uint256(-presentValue_)));
        }
    }

    /**
     * @dev The present value projected backward by the supply index (rounded down)
     *  Note: This will overflow (revert) at 2^104/1e18=~20 trillion principal for assets with 18 decimals.
     */
    function principalValueSupply(uint64 baseSupplyIndex_, uint256 presentValue_) internal pure returns (uint104) {
        return safe104((presentValue_ * BASE_INDEX_SCALE) / baseSupplyIndex_);
    }

    /**
     * @dev The present value projected backward by the borrow index (rounded up)
     *  Note: This will overflow (revert) at 2^104/1e18=~20 trillion principal for assets with 18 decimals.
     */
    function principalValueBorrow(uint64 baseBorrowIndex_, uint256 presentValue_) internal pure returns (uint104) {
        return safe104((presentValue_ * BASE_INDEX_SCALE + baseBorrowIndex_ - 1) / baseBorrowIndex_);
    }
}

// SPDX-License-Identifier: BUSL-1.1
pragma solidity 0.8.15;

/**
 * @title Compound's Comet Configuration Interface
 * @author Compound
 */
contract CometConfiguration {
    struct ExtConfiguration {
        bytes32 name32;
        bytes32 symbol32;
    }

    struct Configuration {
        address governor;
        address pauseGuardian;
        address baseToken;
        address baseTokenPriceFeed;
        address extensionDelegate;

        uint64 supplyKink;
        uint64 supplyPerYearInterestRateSlopeLow;
        uint64 supplyPerYearInterestRateSlopeHigh;
        uint64 supplyPerYearInterestRateBase;
        uint64 borrowKink;
        uint64 borrowPerYearInterestRateSlopeLow;
        uint64 borrowPerYearInterestRateSlopeHigh;
        uint64 borrowPerYearInterestRateBase;
        uint64 storeFrontPriceFactor;
        uint64 trackingIndexScale;
        uint64 baseTrackingSupplySpeed;
        uint64 baseTrackingBorrowSpeed;
        uint104 baseMinForRewards;
        uint104 baseBorrowMin;
        uint104 targetReserves;

        AssetConfig[] assetConfigs;
    }

    struct AssetConfig {
        address asset;
        address priceFeed;
        uint8 decimals;
        uint64 borrowCollateralFactor;
        uint64 liquidateCollateralFactor;
        uint64 liquidationFactor;
        uint128 supplyCap;
    }
}

// SPDX-License-Identifier: BUSL-1.1
pragma solidity 0.8.15;

/**
 * @title Compound's Comet Storage Interface
 * @dev Versions can enforce append-only storage slots via inheritance.
 * @author Compound
 */
contract CometStorage {
    // 512 bits total = 2 slots
    struct TotalsBasic {
        // 1st slot
        uint64 baseSupplyIndex;
        uint64 baseBorrowIndex;
        uint64 trackingSupplyIndex;
        uint64 trackingBorrowIndex;
        // 2nd slot
        uint104 totalSupplyBase;
        uint104 totalBorrowBase;
        uint40 lastAccrualTime;
        uint8 pauseFlags;
    }

    struct TotalsCollateral {
        uint128 totalSupplyAsset;
        uint128 _reserved;
    }

    struct UserBasic {
        int104 principal;
        uint64 baseTrackingIndex;
        uint64 baseTrackingAccrued;
        uint16 assetsIn;
        uint8 _reserved;
    }

    struct UserCollateral {
        uint128 balance;
        uint128 _reserved;
    }

    struct LiquidatorPoints {
        uint32 numAbsorbs;
        uint64 numAbsorbed;
        uint128 approxSpend;
        uint32 _reserved;
    }

    /// @dev Aggregate variables tracked for the entire market
    uint64 internal baseSupplyIndex;
    uint64 internal baseBorrowIndex;
    uint64 internal trackingSupplyIndex;
    uint64 internal trackingBorrowIndex;
    uint104 internal totalSupplyBase;
    uint104 internal totalBorrowBase;
    uint40 internal lastAccrualTime;
    uint8 internal pauseFlags;

    /// @notice Aggregate variables tracked for each collateral asset
    mapping(address => TotalsCollateral) public totalsCollateral;

    /// @notice Mapping of users to accounts which may be permitted to manage the user account
    mapping(address => mapping(address => bool)) public isAllowed;

    /// @notice The next expected nonce for an address, for validating authorizations via signature
    mapping(address => uint) public userNonce;

    /// @notice Mapping of users to base principal and other basic data
    mapping(address => UserBasic) public userBasic;

    /// @notice Mapping of users to collateral data per collateral asset
    mapping(address => mapping(address => UserCollateral)) public userCollateral;

    /// @notice Mapping of magic liquidator points
    mapping(address => LiquidatorPoints) public liquidatorPoints;
}

// SPDX-License-Identifier: BUSL-1.1
pragma solidity 0.8.15;

/**
 * @title Compound's Comet Math Contract
 * @dev Pure math functions
 * @author Compound
 */
contract CometMath {
    /** Custom errors **/

    error InvalidUInt64();
    error InvalidUInt104();
    error InvalidUInt128();
    error InvalidInt104();
    error InvalidInt256();
    error NegativeNumber();

    function safe64(uint n) internal pure returns (uint64) {
        if (n > type(uint64).max) revert InvalidUInt64();
        return uint64(n);
    }

    function safe104(uint n) internal pure returns (uint104) {
        if (n > type(uint104).max) revert InvalidUInt104();
        return uint104(n);
    }

    function safe128(uint n) internal pure returns (uint128) {
        if (n > type(uint128).max) revert InvalidUInt128();
        return uint128(n);
    }

    function signed104(uint104 n) internal pure returns (int104) {
        if (n > uint104(type(int104).max)) revert InvalidInt104();
        return int104(n);
    }

    function signed256(uint256 n) internal pure returns (int256) {
        if (n > uint256(type(int256).max)) revert InvalidInt256();
        return int256(n);
    }

    function unsigned104(int104 n) internal pure returns (uint104) {
        if (n < 0) revert NegativeNumber();
        return uint104(n);
    }

    function unsigned256(int256 n) internal pure returns (uint256) {
        if (n < 0) revert NegativeNumber();
        return uint256(n);
    }

    function toUInt8(bool x) internal pure returns (uint8) {
        return x ? 1 : 0;
    }

    function toBool(uint8 x) internal pure returns (bool) {
        return x != 0;
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface AggregatorV3Interface {
  function decimals() external view returns (uint8);

  function description() external view returns (string memory);

  function version() external view returns (uint256);

  // getRoundData and latestRoundData should both raise "No data present"
  // if they do not have data to report, instead of returning unset values
  // which could be misinterpreted as actual reported values.
  function getRoundData(uint80 _roundId)
    external
    view
    returns (
      uint80 roundId,
      int256 answer,
      uint256 startedAt,
      uint256 updatedAt,
      uint80 answeredInRound
    );

  function latestRoundData()
    external
    view
    returns (
      uint80 roundId,
      int256 answer,
      uint256 startedAt,
      uint256 updatedAt,
      uint80 answeredInRound
    );
}