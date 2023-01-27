// SPDX-License-Identifier: agpl-3.0
pragma solidity >=0.8.0;

import {SafeMath} from "../dependencies/openzeppelin/contracts/SafeMath.sol";
import {IERC20} from "../dependencies/openzeppelin/contracts/IERC20.sol";
import {IERC20Detailed} from "../dependencies/openzeppelin/contracts/IERC20Detailed.sol";
import {SafeERC20} from "../dependencies/openzeppelin/contracts/SafeERC20.sol";
import {Ownable} from "../dependencies/openzeppelin/contracts/Ownable.sol";
import {ILendingPoolAddressesProvider} from "../interfaces/ILendingPoolAddressesProvider.sol";
import {DataTypes} from "../protocol/libraries/types/DataTypes.sol";
import {IPriceOracleGetter} from "../interfaces/IPriceOracleGetter.sol";
import {IERC20WithPermit} from "../interfaces/IERC20WithPermit.sol";
import {FlashLoanReceiverBase} from "../flashloan/base/FlashLoanReceiverBase.sol";

/**
 * @title BaseParaSwapAdapter
 * @notice Utility functions for adapters using ParaSwap
 * @author Jason Raymond Bell
 */
abstract contract BaseParaSwapAdapter is FlashLoanReceiverBase, Ownable {
    using SafeMath for uint256;
    using SafeERC20 for IERC20;
    using SafeERC20 for IERC20Detailed;
    using SafeERC20 for IERC20WithPermit;

    struct PermitSignature {
        uint256 amount;
        uint256 deadline;
        uint8 v;
        bytes32 r;
        bytes32 s;
    }

    // Max slippage percent allowed
    uint256 public constant MAX_SLIPPAGE_PERCENT = 3000; // 30%

    IPriceOracleGetter public immutable ORACLE;

    event Swapped(
        address indexed fromAsset,
        address indexed toAsset,
        uint256 fromAmount,
        uint256 receivedAmount
    );

    constructor(ILendingPoolAddressesProvider addressesProvider)
        FlashLoanReceiverBase(addressesProvider)
    {
        ORACLE = IPriceOracleGetter(addressesProvider.getPriceOracle()); //TODO: this should consider Curve?
    }

    /**
     * @dev Get the price of the asset from the oracle denominated in eth
     * @param asset address
     * @return eth price for the asset
     */
    function _getPrice(address asset) internal view returns (uint256) {
        return ORACLE.getAssetPrice(asset);
    }

    /**
     * @dev Get the decimals of an asset
     * @return number of decimals of the asset
     */
    function _getDecimals(IERC20Detailed asset) internal view returns (uint8) {
        uint8 decimals = asset.decimals();
        // Ensure 10**decimals won't overflow a uint256
        require(decimals <= 77, "TOO_MANY_DECIMALS_ON_TOKEN");
        return decimals;
    }

    /**
     * @dev Get the aToken associated to the asset
     * @return address of the aToken
     */
    function _getReserveData(address asset, uint64 trancheId)
        internal
        view
        returns (DataTypes.ReserveData memory)
    {
        return LENDING_POOL.getReserveData(asset, trancheId);
    }

    /**
     * @dev Pull the ATokens from the user
     * @param reserve address of the asset
     * @param reserveAToken address of the aToken of the reserve
     * @param user address
     * @param amount of tokens to be transferred to the contract
     * @param permitSignature struct containing the permit signature
     */
    function _pullATokenAndWithdraw(
        address reserve,
        uint64 trancheId,
        IERC20WithPermit reserveAToken,
        address user,
        uint256 amount,
        PermitSignature memory permitSignature
    ) internal {
        // If deadline is set to zero, assume there is no signature for permit
        if (permitSignature.deadline != 0) {
            reserveAToken.permit(
                user,
                address(this),
                permitSignature.amount,
                permitSignature.deadline,
                permitSignature.v,
                permitSignature.r,
                permitSignature.s
            );
        }

        // transfer from user to adapter
        reserveAToken.safeTransferFrom(user, address(this), amount);

        // withdraw reserve
        require(
            LENDING_POOL.withdraw(reserve, trancheId, amount, address(this)) ==
                amount,
            "UNEXPECTED_AMOUNT_WITHDRAWN"
        );
    }

    /**
     * @dev Emergency rescue for token stucked on this contract, as failsafe mechanism
     * - Funds should never remain in this contract more time than during transactions
     * - Only callable by the owner
     */
    function rescueTokens(IERC20 token) external onlyOwner {
        token.safeTransfer(owner(), token.balanceOf(address(this)));
    }
}

// SPDX-License-Identifier: agpl-3.0
pragma solidity >=0.8.0;

import {BaseParaSwapAdapter} from "./BaseParaSwapAdapter.sol";
import {PercentageMath} from "../protocol/libraries/math/PercentageMath.sol";
import {IParaSwapAugustus} from "../interfaces/IParaSwapAugustus.sol";
import {
    IParaSwapAugustusRegistry
} from "../interfaces/IParaSwapAugustusRegistry.sol";
import {
    ILendingPoolAddressesProvider
} from "../interfaces/ILendingPoolAddressesProvider.sol";
import {
    IERC20Detailed
} from "../dependencies/openzeppelin/contracts/IERC20Detailed.sol";

/**
 * @title BaseParaSwapSellAdapter
 * @notice Implements the logic for selling tokens on ParaSwap
 * @author Jason Raymond Bell
 */
abstract contract BaseParaSwapSellAdapter is BaseParaSwapAdapter {
    using PercentageMath for uint256;

    IParaSwapAugustusRegistry public immutable AUGUSTUS_REGISTRY;

    constructor(
        ILendingPoolAddressesProvider addressesProvider,
        IParaSwapAugustusRegistry augustusRegistry
    ) BaseParaSwapAdapter(addressesProvider) {
        // Do something on Augustus registry to check the right contract was passed
        require(!augustusRegistry.isValidAugustus(address(0)));
        AUGUSTUS_REGISTRY = augustusRegistry;
    }

    /**
     * @dev Swaps a token for another using ParaSwap
     * @param fromAmountOffset Offset of fromAmount in Augustus calldata if it should be overwritten, otherwise 0
     * @param swapCalldata Calldata for ParaSwap's AugustusSwapper contract
     * @param augustus Address of ParaSwap's AugustusSwapper contract
     * @param assetToSwapFrom Address of the asset to be swapped from
     * @param assetToSwapTo Address of the asset to be swapped to
     * @param amountToSwap Amount to be swapped
     * @param minAmountToReceive Minimum amount to be received from the swap
     * @return amountReceived The amount received from the swap
     */
    function _sellOnParaSwap(
        uint256 fromAmountOffset,
        bytes memory swapCalldata,
        IParaSwapAugustus augustus,
        IERC20Detailed assetToSwapFrom,
        IERC20Detailed assetToSwapTo,
        uint256 amountToSwap,
        uint256 minAmountToReceive
    ) internal returns (uint256 amountReceived) {
        require(
            AUGUSTUS_REGISTRY.isValidAugustus(address(augustus)),
            "INVALID_AUGUSTUS"
        );

        {
            uint256 fromAssetDecimals = _getDecimals(assetToSwapFrom);
            uint256 toAssetDecimals = _getDecimals(assetToSwapTo);

            uint256 fromAssetPrice = _getPrice(address(assetToSwapFrom));
            uint256 toAssetPrice = _getPrice(address(assetToSwapTo));

            // .mul(fromAssetPrice.mul(10**toAssetDecimals))
            // .div(toAssetPrice.mul(10**fromAssetDecimals))
            // .percentMul(PercentageMath.PERCENTAGE_FACTOR - MAX_SLIPPAGE_PERCENT);
            uint256 expectedMinAmountOut =
                ((amountToSwap * (fromAssetPrice * (10**toAssetDecimals))) /
                    (toAssetPrice * (10**toAssetDecimals))) *
                    (PercentageMath.PERCENTAGE_FACTOR - MAX_SLIPPAGE_PERCENT);

            require(
                expectedMinAmountOut <= minAmountToReceive,
                "MIN_AMOUNT_EXCEEDS_MAX_SLIPPAGE"
            );
        }

        uint256 balanceBeforeAssetFrom =
            assetToSwapFrom.balanceOf(address(this));
        require(
            balanceBeforeAssetFrom >= amountToSwap,
            "INSUFFICIENT_BALANCE_BEFORE_SWAP"
        );
        uint256 balanceBeforeAssetTo = assetToSwapTo.balanceOf(address(this));

        address tokenTransferProxy = augustus.getTokenTransferProxy();
        assetToSwapFrom.approve(tokenTransferProxy, 0);
        assetToSwapFrom.approve(tokenTransferProxy, amountToSwap);

        if (fromAmountOffset != 0) {
            // Ensure 256 bit (32 bytes) fromAmount value is within bounds of the
            // calldata, not overlapping with the first 4 bytes (function selector).
            require(
                fromAmountOffset >= 4 &&
                    fromAmountOffset <= swapCalldata.length - 32,
                "FROM_AMOUNT_OFFSET_OUT_OF_RANGE"
            );
            // Overwrite the fromAmount with the correct amount for the swap.
            // In memory, swapCalldata consists of a 256 bit length field, followed by
            // the actual bytes data, that is why 32 is added to the byte offset.
            assembly {
                mstore(
                    add(swapCalldata, add(fromAmountOffset, 32)),
                    amountToSwap
                )
            }
        }
        (bool success, ) = address(augustus).call(swapCalldata);
        if (!success) {
            // Copy revert reason from call
            assembly {
                returndatacopy(0, 0, returndatasize())
                revert(0, returndatasize())
            }
        }
        require(
            assetToSwapFrom.balanceOf(address(this)) ==
                balanceBeforeAssetFrom - amountToSwap,
            "WRONG_BALANCE_AFTER_SWAP"
        );
        amountReceived =
            assetToSwapTo.balanceOf(address(this)) -
            balanceBeforeAssetTo;
        require(
            amountReceived >= minAmountToReceive,
            "INSUFFICIENT_AMOUNT_RECEIVED"
        );

        emit Swapped(
            address(assetToSwapFrom),
            address(assetToSwapTo),
            amountToSwap,
            amountReceived
        );
    }
}

// SPDX-License-Identifier: agpl-3.0
pragma solidity >=0.8.0;

import {PercentageMath} from "../protocol/libraries/math/PercentageMath.sol";
import {SafeMath} from "../dependencies/openzeppelin/contracts/SafeMath.sol";
import {IERC20} from "../dependencies/openzeppelin/contracts/IERC20.sol";
import {IERC20Detailed} from "../dependencies/openzeppelin/contracts/IERC20Detailed.sol";
import {SafeERC20} from "../dependencies/openzeppelin/contracts/SafeERC20.sol";
import {Ownable} from "../dependencies/openzeppelin/contracts/Ownable.sol";
import {ILendingPoolAddressesProvider} from "../interfaces/ILendingPoolAddressesProvider.sol";
import {DataTypes} from "../protocol/libraries/types/DataTypes.sol";
import {IUniswapV2Router02} from "../interfaces/IUniswapV2Router02.sol";
import {IPriceOracleGetter} from "../interfaces/IPriceOracleGetter.sol";
import {IERC20WithPermit} from "../interfaces/IERC20WithPermit.sol";
import {FlashLoanReceiverBase} from "../flashloan/base/FlashLoanReceiverBase.sol";
import {IBaseUniswapAdapter} from "./interfaces/IBaseUniswapAdapter.sol";

/**
 * @title BaseUniswapAdapter
 * @notice Implements the logic for performing assets swaps in Uniswap V2
 * @author Aave
 **/
abstract contract BaseUniswapAdapter is
    FlashLoanReceiverBase,
    IBaseUniswapAdapter,
    Ownable
{
    using SafeMath for uint256;
    using PercentageMath for uint256;
    using SafeERC20 for IERC20;

    // Max slippage percent allowed
    uint256 public constant override MAX_SLIPPAGE_PERCENT = 3000; // 30%
    // FLash Loan fee set in lending pool
    uint256 public constant override FLASHLOAN_PREMIUM_TOTAL = 9;
    // USD oracle asset address
    address public constant override USD_ADDRESS =
        0x10F7Fc1F91Ba351f9C629c5947AD69bD03C05b96;

    address public immutable override WETH_ADDRESS;
    IPriceOracleGetter public immutable override ORACLE;
    IUniswapV2Router02 public immutable override UNISWAP_ROUTER;

    constructor(
        ILendingPoolAddressesProvider addressesProvider,
        IUniswapV2Router02 uniswapRouter,
        address wethAddress
    ) FlashLoanReceiverBase(addressesProvider) {
        ORACLE = IPriceOracleGetter(addressesProvider.getPriceOracle());
        UNISWAP_ROUTER = uniswapRouter;
        WETH_ADDRESS = wethAddress;
    }

    /**
     * @dev Given an input asset amount, returns the maximum output amount of the other asset and the prices
     * @param amountIn Amount of reserveIn
     * @param reserveIn Address of the asset to be swap from
     * @param reserveOut Address of the asset to be swap to
     * @return uint256 Amount out of the reserveOut
     * @return uint256 The price of out amount denominated in the reserveIn currency (18 decimals)
     * @return uint256 In amount of reserveIn value denominated in USD (8 decimals)
     * @return uint256 Out amount of reserveOut value denominated in USD (8 decimals)
     */
    function getAmountsOut(
        uint256 amountIn,
        address reserveIn,
        address reserveOut
    )
        external
        view
        override
        returns (
            uint256,
            uint256,
            uint256,
            uint256,
            address[] memory
        )
    {
        AmountCalc memory results = _getAmountsOutData(
            reserveIn,
            reserveOut,
            amountIn
        );

        return (
            results.calculatedAmount,
            results.relativePrice,
            results.amountInUsd,
            results.amountOutUsd,
            results.path
        );
    }

    /**
     * @dev Returns the minimum input asset amount required to buy the given output asset amount and the prices
     * @param amountOut Amount of reserveOut
     * @param reserveIn Address of the asset to be swap from
     * @param reserveOut Address of the asset to be swap to
     * @return uint256 Amount in of the reserveIn
     * @return uint256 The price of in amount denominated in the reserveOut currency (18 decimals)
     * @return uint256 In amount of reserveIn value denominated in USD (8 decimals)
     * @return uint256 Out amount of reserveOut value denominated in USD (8 decimals)
     */
    function getAmountsIn(
        uint256 amountOut,
        address reserveIn,
        address reserveOut
    )
        external
        view
        override
        returns (
            uint256,
            uint256,
            uint256,
            uint256,
            address[] memory
        )
    {
        AmountCalc memory results = _getAmountsInData(
            reserveIn,
            reserveOut,
            amountOut
        );

        return (
            results.calculatedAmount,
            results.relativePrice,
            results.amountInUsd,
            results.amountOutUsd,
            results.path
        );
    }

    /**
     * @dev Swaps an exact `amountToSwap` of an asset to another
     * @param assetToSwapFrom Origin asset
     * @param assetToSwapTo Destination asset
     * @param amountToSwap Exact amount of `assetToSwapFrom` to be swapped
     * @param minAmountOut the min amount of `assetToSwapTo` to be received from the swap
     * @return the amount received from the swap
     */
    function _swapExactTokensForTokens(
        address assetToSwapFrom,
        address assetToSwapTo,
        uint256 amountToSwap,
        uint256 minAmountOut,
        bool useEthPath
    ) internal returns (uint256) {
        uint256 fromAssetDecimals = _getDecimals(assetToSwapFrom);
        uint256 toAssetDecimals = _getDecimals(assetToSwapTo);

        uint256 fromAssetPrice = _getPrice(assetToSwapFrom);
        uint256 toAssetPrice = _getPrice(assetToSwapTo);

        uint256 expectedMinAmountOut = amountToSwap
            .mul(fromAssetPrice.mul(10**toAssetDecimals))
            .div(toAssetPrice.mul(10**fromAssetDecimals))
            .percentMul(
                PercentageMath.PERCENTAGE_FACTOR.sub(MAX_SLIPPAGE_PERCENT)
            );

        require(
            expectedMinAmountOut < minAmountOut,
            "minAmountOut exceed max slippage"
        );

        // Approves the transfer for the swap. Approves for 0 first to comply with tokens that implement the anti frontrunning approval fix.
        IERC20(assetToSwapFrom).approve(address(UNISWAP_ROUTER), 0);
        IERC20(assetToSwapFrom).approve(address(UNISWAP_ROUTER), amountToSwap);

        address[] memory path;
        if (useEthPath) {
            path = new address[](3);
            path[0] = assetToSwapFrom;
            path[1] = WETH_ADDRESS;
            path[2] = assetToSwapTo;
        } else {
            path = new address[](2);
            path[0] = assetToSwapFrom;
            path[1] = assetToSwapTo;
        }
        uint256[] memory amounts = UNISWAP_ROUTER.swapExactTokensForTokens(
            amountToSwap,
            minAmountOut,
            path,
            address(this),
            block.timestamp
        );

        emit Swapped(
            assetToSwapFrom,
            assetToSwapTo,
            amounts[0],
            amounts[amounts.length - 1]
        );

        return amounts[amounts.length - 1];
    }

    /**
     * @dev Receive an exact amount `amountToReceive` of `assetToSwapTo` tokens for as few `assetToSwapFrom` tokens as
     * possible.
     * @param assetToSwapFrom Origin asset
     * @param assetToSwapTo Destination asset
     * @param maxAmountToSwap Max amount of `assetToSwapFrom` allowed to be swapped
     * @param amountToReceive Exact amount of `assetToSwapTo` to receive
     * @return the amount swapped
     */
    function _swapTokensForExactTokens(
        address assetToSwapFrom,
        address assetToSwapTo,
        uint256 maxAmountToSwap,
        uint256 amountToReceive,
        bool useEthPath
    ) internal returns (uint256) {
        uint256 fromAssetDecimals = _getDecimals(assetToSwapFrom);
        uint256 toAssetDecimals = _getDecimals(assetToSwapTo);

        uint256 fromAssetPrice = _getPrice(assetToSwapFrom);
        uint256 toAssetPrice = _getPrice(assetToSwapTo);

        uint256 expectedMaxAmountToSwap = amountToReceive
            .mul(toAssetPrice.mul(10**fromAssetDecimals))
            .div(fromAssetPrice.mul(10**toAssetDecimals))
            .percentMul(
                PercentageMath.PERCENTAGE_FACTOR.add(MAX_SLIPPAGE_PERCENT)
            );

        require(
            maxAmountToSwap < expectedMaxAmountToSwap,
            "maxAmountToSwap exceed max slippage"
        );

        // Approves the transfer for the swap. Approves for 0 first to comply with tokens that implement the anti frontrunning approval fix.
        IERC20(assetToSwapFrom).approve(address(UNISWAP_ROUTER), 0);
        IERC20(assetToSwapFrom).approve(
            address(UNISWAP_ROUTER),
            maxAmountToSwap
        );

        address[] memory path;
        if (useEthPath) {
            path = new address[](3);
            path[0] = assetToSwapFrom;
            path[1] = WETH_ADDRESS;
            path[2] = assetToSwapTo;
        } else {
            path = new address[](2);
            path[0] = assetToSwapFrom;
            path[1] = assetToSwapTo;
        }

        uint256[] memory amounts = UNISWAP_ROUTER.swapTokensForExactTokens(
            amountToReceive,
            maxAmountToSwap,
            path,
            address(this),
            block.timestamp
        );

        emit Swapped(
            assetToSwapFrom,
            assetToSwapTo,
            amounts[0],
            amounts[amounts.length - 1]
        );

        return amounts[0];
    }

    /**
     * @dev Get the price of the asset from the oracle denominated in eth
     * @param asset address
     * @return eth price for the asset
     */
    function _getPrice(address asset) internal view returns (uint256) {
        return ORACLE.getAssetPrice(asset);
    }

    /**
     * @dev Get the decimals of an asset
     * @return number of decimals of the asset
     */
    function _getDecimals(address asset) internal view returns (uint256) {
        return IERC20Detailed(asset).decimals();
    }

    /**
     * @dev Get the aToken associated to the asset
     * @return address of the aToken
     */
    function _getReserveData(address asset, uint64 trancheId)
        internal
        view
        returns (DataTypes.ReserveData memory)
    {
        return LENDING_POOL.getReserveData(asset, trancheId);
    }

    /**
     * @dev Pull the ATokens from the user
     * @param reserve address of the asset
     * @param reserveAToken address of the aToken of the reserve
     * @param user address
     * @param amount of tokens to be transferred to the contract
     * @param permitSignature struct containing the permit signature
     */
    function _pullAToken(
        address reserve,
        uint64 trancheId,
        address reserveAToken,
        address user,
        uint256 amount,
        PermitSignature memory permitSignature
    ) internal {
        if (_usePermit(permitSignature)) {
            IERC20WithPermit(reserveAToken).permit(
                user,
                address(this),
                permitSignature.amount,
                permitSignature.deadline,
                permitSignature.v,
                permitSignature.r,
                permitSignature.s
            );
        }

        // transfer from user to adapter
        IERC20(reserveAToken).safeTransferFrom(user, address(this), amount);

        // withdraw reserve
        LENDING_POOL.withdraw(reserve, trancheId, amount, address(this));
    }

    /**
     * @dev Tells if the permit method should be called by inspecting if there is a valid signature.
     * If signature params are set to 0, then permit won't be called.
     * @param signature struct containing the permit signature
     * @return whether or not permit should be called
     */
    function _usePermit(PermitSignature memory signature)
        internal
        pure
        returns (bool)
    {
        return
            !(uint256(signature.deadline) == uint256(signature.v) &&
                uint256(signature.deadline) == 0);
    }

    /**
     * @dev Calculates the value denominated in USD
     * @param reserve Address of the reserve
     * @param amount Amount of the reserve
     * @param decimals Decimals of the reserve
     * @return whether or not permit should be called
     */
    function _calcUsdValue(
        address reserve,
        uint256 amount,
        uint256 decimals
    ) internal view returns (uint256) {
        uint256 ethUsdPrice = _getPrice(USD_ADDRESS);
        uint256 reservePrice = _getPrice(reserve);

        return
            amount.mul(reservePrice).div(10**decimals).mul(ethUsdPrice).div(
                10**18
            );
    }

    /**
     * @dev Given an input asset amount, returns the maximum output amount of the other asset
     * @param reserveIn Address of the asset to be swap from
     * @param reserveOut Address of the asset to be swap to
     * @param amountIn Amount of reserveIn
     * @return Struct containing the following information:
     *   uint256 Amount out of the reserveOut
     *   uint256 The price of out amount denominated in the reserveIn currency (18 decimals)
     *   uint256 In amount of reserveIn value denominated in USD (8 decimals)
     *   uint256 Out amount of reserveOut value denominated in USD (8 decimals)
     */
    function _getAmountsOutData(
        address reserveIn,
        address reserveOut,
        uint256 amountIn
    ) internal view returns (AmountCalc memory) {
        // Subtract flash loan fee
        uint256 finalAmountIn = amountIn.sub(
            amountIn.mul(FLASHLOAN_PREMIUM_TOTAL).div(10000)
        );

        if (reserveIn == reserveOut) {
            uint256 reserveDecimals = _getDecimals(reserveIn);
            address[] memory path = new address[](1);
            path[0] = reserveIn;

            return
                AmountCalc(
                    finalAmountIn,
                    finalAmountIn.mul(10**18).div(amountIn),
                    _calcUsdValue(reserveIn, amountIn, reserveDecimals),
                    _calcUsdValue(reserveIn, finalAmountIn, reserveDecimals),
                    path
                );
        }

        address[] memory simplePath = new address[](2);
        simplePath[0] = reserveIn;
        simplePath[1] = reserveOut;

        uint256[] memory amountsWithoutWeth;
        uint256[] memory amountsWithWeth;

        address[] memory pathWithWeth = new address[](3);
        if (reserveIn != WETH_ADDRESS && reserveOut != WETH_ADDRESS) {
            pathWithWeth[0] = reserveIn;
            pathWithWeth[1] = WETH_ADDRESS;
            pathWithWeth[2] = reserveOut;

            try
                UNISWAP_ROUTER.getAmountsOut(finalAmountIn, pathWithWeth)
            returns (uint256[] memory resultsWithWeth) {
                amountsWithWeth = resultsWithWeth;
            } catch {
                amountsWithWeth = new uint256[](3);
            }
        } else {
            amountsWithWeth = new uint256[](3);
        }

        uint256 bestAmountOut;
        try UNISWAP_ROUTER.getAmountsOut(finalAmountIn, simplePath) returns (
            uint256[] memory resultAmounts
        ) {
            amountsWithoutWeth = resultAmounts;

            bestAmountOut = (amountsWithWeth[2] > amountsWithoutWeth[1])
                ? amountsWithWeth[2]
                : amountsWithoutWeth[1];
        } catch {
            amountsWithoutWeth = new uint256[](2);
            bestAmountOut = amountsWithWeth[2];
        }

        uint256 reserveInDecimals = _getDecimals(reserveIn);
        uint256 reserveOutDecimals = _getDecimals(reserveOut);

        uint256 outPerInPrice = finalAmountIn
            .mul(10**18)
            .mul(10**reserveOutDecimals)
            .div(bestAmountOut.mul(10**reserveInDecimals));

        return
            AmountCalc(
                bestAmountOut,
                outPerInPrice,
                _calcUsdValue(reserveIn, amountIn, reserveInDecimals),
                _calcUsdValue(reserveOut, bestAmountOut, reserveOutDecimals),
                (bestAmountOut == 0)
                    ? new address[](2)
                    : (bestAmountOut == amountsWithoutWeth[1])
                    ? simplePath
                    : pathWithWeth
            );
    }

    /**
     * @dev Returns the minimum input asset amount required to buy the given output asset amount
     * @param reserveIn Address of the asset to be swap from
     * @param reserveOut Address of the asset to be swap to
     * @param amountOut Amount of reserveOut
     * @return Struct containing the following information:
     *   uint256 Amount in of the reserveIn
     *   uint256 The price of in amount denominated in the reserveOut currency (18 decimals)
     *   uint256 In amount of reserveIn value denominated in USD (8 decimals)
     *   uint256 Out amount of reserveOut value denominated in USD (8 decimals)
     */
    function _getAmountsInData(
        address reserveIn,
        address reserveOut,
        uint256 amountOut
    ) internal view returns (AmountCalc memory) {
        if (reserveIn == reserveOut) {
            // Add flash loan fee
            uint256 amountIn = amountOut.add(
                amountOut.mul(FLASHLOAN_PREMIUM_TOTAL).div(10000)
            );
            uint256 reserveDecimals = _getDecimals(reserveIn);
            address[] memory path = new address[](1);
            path[0] = reserveIn;

            return
                AmountCalc(
                    amountIn,
                    amountOut.mul(10**18).div(amountIn),
                    _calcUsdValue(reserveIn, amountIn, reserveDecimals),
                    _calcUsdValue(reserveIn, amountOut, reserveDecimals),
                    path
                );
        }

        (
            uint256[] memory amounts,
            address[] memory path
        ) = _getAmountsInAndPath(reserveIn, reserveOut, amountOut);

        // Add flash loan fee
        uint256 finalAmountIn = amounts[0].add(
            amounts[0].mul(FLASHLOAN_PREMIUM_TOTAL).div(10000)
        );

        uint256 reserveInDecimals = _getDecimals(reserveIn);
        uint256 reserveOutDecimals = _getDecimals(reserveOut);

        uint256 inPerOutPrice = amountOut
            .mul(10**18)
            .mul(10**reserveInDecimals)
            .div(finalAmountIn.mul(10**reserveOutDecimals));

        return
            AmountCalc(
                finalAmountIn,
                inPerOutPrice,
                _calcUsdValue(reserveIn, finalAmountIn, reserveInDecimals),
                _calcUsdValue(reserveOut, amountOut, reserveOutDecimals),
                path
            );
    }

    /**
     * @dev Calculates the input asset amount required to buy the given output asset amount
     * @param reserveIn Address of the asset to be swap from
     * @param reserveOut Address of the asset to be swap to
     * @param amountOut Amount of reserveOut
     * @return uint256[] amounts Array containing the amountIn and amountOut for a swap
     */
    function _getAmountsInAndPath(
        address reserveIn,
        address reserveOut,
        uint256 amountOut
    ) internal view returns (uint256[] memory, address[] memory) {
        address[] memory simplePath = new address[](2);
        simplePath[0] = reserveIn;
        simplePath[1] = reserveOut;

        uint256[] memory amountsWithoutWeth;
        uint256[] memory amountsWithWeth;
        address[] memory pathWithWeth = new address[](3);

        if (reserveIn != WETH_ADDRESS && reserveOut != WETH_ADDRESS) {
            pathWithWeth[0] = reserveIn;
            pathWithWeth[1] = WETH_ADDRESS;
            pathWithWeth[2] = reserveOut;

            try UNISWAP_ROUTER.getAmountsIn(amountOut, pathWithWeth) returns (
                uint256[] memory resultsWithWeth
            ) {
                amountsWithWeth = resultsWithWeth;
            } catch {
                amountsWithWeth = new uint256[](3);
            }
        } else {
            amountsWithWeth = new uint256[](3);
        }

        try UNISWAP_ROUTER.getAmountsIn(amountOut, simplePath) returns (
            uint256[] memory resultAmounts
        ) {
            amountsWithoutWeth = resultAmounts;

            return
                (amountsWithWeth[0] < amountsWithoutWeth[0] &&
                    amountsWithWeth[0] != 0)
                    ? (amountsWithWeth, pathWithWeth)
                    : (amountsWithoutWeth, simplePath);
        } catch {
            return (amountsWithWeth, pathWithWeth);
        }
    }

    /**
     * @dev Calculates the input asset amount required to buy the given output asset amount
     * @param reserveIn Address of the asset to be swap from
     * @param reserveOut Address of the asset to be swap to
     * @param amountOut Amount of reserveOut
     * @return uint256[] amounts Array containing the amountIn and amountOut for a swap
     */
    function _getAmountsIn(
        address reserveIn,
        address reserveOut,
        uint256 amountOut,
        bool useEthPath
    ) internal view returns (uint256[] memory) {
        address[] memory path;

        if (useEthPath) {
            path = new address[](3);
            path[0] = reserveIn;
            path[1] = WETH_ADDRESS;
            path[2] = reserveOut;
        } else {
            path = new address[](2);
            path[0] = reserveIn;
            path[1] = reserveOut;
        }

        return UNISWAP_ROUTER.getAmountsIn(amountOut, path);
    }

    /**
     * @dev Emergency rescue for token stucked on this contract, as failsafe mechanism
     * - Funds should never remain in this contract more time than during transactions
     * - Only callable by the owner
     **/
    function rescueTokens(IERC20 token) external onlyOwner {
        token.transfer(owner(), token.balanceOf(address(this)));
    }
}

// SPDX-License-Identifier: agpl-3.0
pragma solidity >=0.8.0;

import {BaseUniswapAdapter} from "./BaseUniswapAdapter.sol";
import {ILendingPoolAddressesProvider} from "../interfaces/ILendingPoolAddressesProvider.sol";
import {IUniswapV2Router02} from "../interfaces/IUniswapV2Router02.sol";
import {IERC20} from "../dependencies/openzeppelin/contracts/IERC20.sol";
import {DataTypes} from "../protocol/libraries/types/DataTypes.sol";
import {IPriceOracleGetter} from "../interfaces/IPriceOracleGetter.sol";
import {IAToken} from "../interfaces/IAToken.sol";
import {ReserveConfiguration} from "../protocol/libraries/configuration/ReserveConfiguration.sol";
import {SafeMath} from "../dependencies/openzeppelin/contracts/SafeMath.sol";

/**
 * @title UniswapLiquiditySwapAdapter
 * @notice Uniswap V2 Adapter to swap liquidity.
 * @author Aave
 **/
contract FlashLiquidationAdapter is BaseUniswapAdapter {
    using ReserveConfiguration for DataTypes.ReserveConfigurationMap;
    using SafeMath for uint256;
    uint256 internal constant LIQUIDATION_CLOSE_FACTOR_PERCENT = 5000;

    struct LiquidationParams {
        address collateralAsset;
        address borrowedAsset;
        uint64 trancheId;
        address user;
        uint256 debtToCover;
        bool useEthPath;
    }

    struct LiquidationCallLocalVars {
        uint256 initFlashBorrowedBalance;
        uint256 diffFlashBorrowedBalance;
        uint256 initCollateralBalance;
        uint256 diffCollateralBalance;
        uint256 flashLoanDebt;
        uint256 soldAmount;
        uint256 remainingTokens;
        uint256 borrowedAssetLeftovers;
    }

    constructor(
        ILendingPoolAddressesProvider addressesProvider,
        IUniswapV2Router02 uniswapRouter,
        address wethAddress
    ) BaseUniswapAdapter(addressesProvider, uniswapRouter, wethAddress) {}

    /**
     * @dev Liquidate a non-healthy position collateral-wise, with a Health Factor below 1, using Flash Loan and Uniswap to repay flash loan premium.
     * - The caller (liquidator) with a flash loan covers `debtToCover` amount of debt of the user getting liquidated, and receives
     *   a proportionally amount of the `collateralAsset` plus a bonus to cover market risk minus the flash loan premium.
     * @param assets Address of asset to be swapped
     * @param amounts Amount of the asset to be swapped
     * @param premiums Fee of the flash loan
     * @param initiator Address of the caller
     * @param params Additional variadic field to include extra params. Expected parameters:
     *   address collateralAsset The collateral asset to release and will be exchanged to pay the flash loan premium
     *   address borrowedAsset The asset that must be covered
     *   address user The user address with a Health Factor below 1
     *   uint256 debtToCover The amount of debt to cover
     *   bool useEthPath Use WETH as connector path between the collateralAsset and borrowedAsset at Uniswap
     */
    function executeOperation(
        address[] calldata assets,
        uint256[] calldata amounts,
        uint256[] calldata premiums,
        address initiator,
        bytes calldata params
    ) external override returns (bool) {
        require(
            msg.sender == address(LENDING_POOL),
            "CALLER_MUST_BE_LENDING_POOL"
        );

        LiquidationParams memory decodedParams = _decodeParams(params);

        require(
            assets.length == 1 && assets[0] == decodedParams.borrowedAsset,
            "INCONSISTENT_PARAMS"
        );

        _liquidateAndSwap(decodedParams, amounts[0], premiums[0], initiator);

        return true;
    }

    /**
     * @dev
     * @param decodedParams Contains info like The collateral asset to release and will be exchanged to pay the flash loan premium
     * @param flashBorrowedAmount Amount of asset requested at the flash loan to liquidate the user position
     * @param premium Fee of the requested flash loan
     * @param initiator Address of the caller
     */
    function _liquidateAndSwap(
        LiquidationParams memory decodedParams,
        uint256 flashBorrowedAmount,
        uint256 premium,
        address initiator
    ) internal {
        LiquidationCallLocalVars memory vars;
        vars.initCollateralBalance = IERC20(decodedParams.collateralAsset)
            .balanceOf(address(this));
        if (decodedParams.collateralAsset != decodedParams.borrowedAsset) {
            vars.initFlashBorrowedBalance = IERC20(decodedParams.borrowedAsset)
                .balanceOf(address(this));

            // Track leftover balance to rescue funds in case of external transfers into this contract
            vars.borrowedAssetLeftovers = vars.initFlashBorrowedBalance.sub(
                flashBorrowedAmount
            );
        }
        vars.flashLoanDebt = flashBorrowedAmount.add(premium);

        // Approve LendingPool to use debt token for liquidation
        IERC20(decodedParams.borrowedAsset).approve(
            address(LENDING_POOL),
            decodedParams.debtToCover
        );

        // Liquidate the user position and release the underlying collateral
        LENDING_POOL.liquidationCall(
            decodedParams.collateralAsset,
            decodedParams.borrowedAsset,
            decodedParams.trancheId,
            decodedParams.user,
            decodedParams.debtToCover,
            false
        );

        // Discover the liquidated tokens
        uint256 collateralBalanceAfter = IERC20(decodedParams.collateralAsset)
            .balanceOf(address(this));

        // Track only collateral released, not current asset balance of the contract
        vars.diffCollateralBalance = collateralBalanceAfter.sub(
            vars.initCollateralBalance
        );

        if (decodedParams.collateralAsset != decodedParams.borrowedAsset) {
            // Discover flash loan balance after the liquidation
            uint256 flashBorrowedAssetAfter = IERC20(
                decodedParams.borrowedAsset
            ).balanceOf(address(this));

            // Use only flash loan borrowed assets, not current asset balance of the contract
            vars.diffFlashBorrowedBalance = flashBorrowedAssetAfter.sub(
                vars.borrowedAssetLeftovers
            );

            // Swap released collateral into the debt asset, to repay the flash loan
            vars.soldAmount = _swapTokensForExactTokens(
                decodedParams.collateralAsset,
                decodedParams.borrowedAsset,
                vars.diffCollateralBalance,
                vars.flashLoanDebt.sub(vars.diffFlashBorrowedBalance),
                decodedParams.useEthPath
            );
            vars.remainingTokens = vars.diffCollateralBalance.sub(
                vars.soldAmount
            );
        } else {
            vars.remainingTokens = vars.diffCollateralBalance.sub(premium);
        }

        // Allow repay of flash loan
        IERC20(decodedParams.borrowedAsset).approve(
            address(LENDING_POOL),
            vars.flashLoanDebt
        );

        // Transfer remaining tokens to initiator
        if (vars.remainingTokens > 0) {
            IERC20(decodedParams.collateralAsset).transfer(
                initiator,
                vars.remainingTokens
            );
        }
    }

    /**
     * @dev Decodes the information encoded in the flash loan params
     * @param params Additional variadic field to include extra params. Expected parameters:
     *   address collateralAsset The collateral asset to claim
     *   address borrowedAsset The asset that must be covered and will be exchanged to pay the flash loan premium
     *   address user The user address with a Health Factor below 1
     *   uint256 debtToCover The amount of debt to cover
     *   bool useEthPath Use WETH as connector path between the collateralAsset and borrowedAsset at Uniswap
     * @return LiquidationParams struct containing decoded params
     */
    function _decodeParams(bytes memory params)
        internal
        pure
        returns (LiquidationParams memory)
    {
        (
            address collateralAsset,
            address borrowedAsset,
            uint64 trancheId,
            address user,
            uint256 debtToCover,
            bool useEthPath
        ) = abi.decode(
                params,
                (address, address, uint64, address, uint256, bool)
            );

        return
            LiquidationParams(
                collateralAsset,
                borrowedAsset,
                trancheId,
                user,
                debtToCover,
                useEthPath
            );
    }
}

// SPDX-License-Identifier: agpl-3.0
pragma solidity >=0.8.0;

import {IPriceOracleGetter} from "../../interfaces/IPriceOracleGetter.sol";
import {IUniswapV2Router02} from "../../interfaces/IUniswapV2Router02.sol";

interface IBaseUniswapAdapter {
    event Swapped(
        address fromAsset,
        address toAsset,
        uint256 fromAmount,
        uint256 receivedAmount
    );

    struct PermitSignature {
        uint256 amount;
        uint256 deadline;
        uint8 v;
        bytes32 r;
        bytes32 s;
    }

    struct AmountCalc {
        uint256 calculatedAmount;
        uint256 relativePrice;
        uint256 amountInUsd;
        uint256 amountOutUsd;
        address[] path;
    }

    function WETH_ADDRESS() external returns (address);

    function MAX_SLIPPAGE_PERCENT() external returns (uint256);

    function FLASHLOAN_PREMIUM_TOTAL() external returns (uint256);

    function USD_ADDRESS() external returns (address);

    function ORACLE() external returns (IPriceOracleGetter);

    function UNISWAP_ROUTER() external returns (IUniswapV2Router02);

    /**
     * @dev Given an input asset amount, returns the maximum output amount of the other asset and the prices
     * @param amountIn Amount of reserveIn
     * @param reserveIn Address of the asset to be swap from
     * @param reserveOut Address of the asset to be swap to
     * @return uint256 Amount out of the reserveOut
     * @return uint256 The price of out amount denominated in the reserveIn currency (18 decimals)
     * @return uint256 In amount of reserveIn value denominated in USD (8 decimals)
     * @return uint256 Out amount of reserveOut value denominated in USD (8 decimals)
     * @return address[] The exchange path
     */
    function getAmountsOut(
        uint256 amountIn,
        address reserveIn,
        address reserveOut
    )
        external
        view
        returns (
            uint256,
            uint256,
            uint256,
            uint256,
            address[] memory
        );

    /**
     * @dev Returns the minimum input asset amount required to buy the given output asset amount and the prices
     * @param amountOut Amount of reserveOut
     * @param reserveIn Address of the asset to be swap from
     * @param reserveOut Address of the asset to be swap to
     * @return uint256 Amount in of the reserveIn
     * @return uint256 The price of in amount denominated in the reserveOut currency (18 decimals)
     * @return uint256 In amount of reserveIn value denominated in USD (8 decimals)
     * @return uint256 Out amount of reserveOut value denominated in USD (8 decimals)
     * @return address[] The exchange path
     */
    function getAmountsIn(
        uint256 amountOut,
        address reserveIn,
        address reserveOut
    )
        external
        view
        returns (
            uint256,
            uint256,
            uint256,
            uint256,
            address[] memory
        );
}

// SPDX-License-Identifier: agpl-3.0
pragma solidity >=0.8.0;

import {BaseParaSwapSellAdapter} from "./BaseParaSwapSellAdapter.sol";
import {ILendingPoolAddressesProvider} from "../interfaces/ILendingPoolAddressesProvider.sol";
import {IParaSwapAugustusRegistry} from "../interfaces/IParaSwapAugustusRegistry.sol";
import {IERC20Detailed} from "../dependencies/openzeppelin/contracts/IERC20Detailed.sol";
import {IERC20WithPermit} from "../interfaces/IERC20WithPermit.sol";
import {IParaSwapAugustus} from "../interfaces/IParaSwapAugustus.sol";
import {ReentrancyGuard} from "../dependencies/openzeppelin/contracts/ReentrancyGuard.sol";
import {SafeMath} from "../dependencies/openzeppelin/contracts/SafeMath.sol";

import {DataTypes} from "../protocol/libraries/types/DataTypes.sol";

/**
 * @title ParaSwapLiquiditySwapAdapter
 * @notice Adapter to swap liquidity using ParaSwap.
 * @author Jason Raymond Bell
 */
contract ParaSwapLiquiditySwapAdapter is
    BaseParaSwapSellAdapter,
    ReentrancyGuard
{
    using SafeMath for uint256;

    constructor(
        ILendingPoolAddressesProvider addressesProvider,
        IParaSwapAugustusRegistry augustusRegistry
    ) BaseParaSwapSellAdapter(addressesProvider, augustusRegistry) {
        // This is only required to initialize BaseParaSwapSellAdapter
    }

    struct executeOperationVars {
        IERC20Detailed assetToSwapTo;
        uint64 assetToSwapToTranche;
        uint256 minAmountToReceive;
        uint256 swapAllBalanceOffset;
        bytes swapCalldata;
        IParaSwapAugustus augustus;
        PermitSignature permitParams;
    }

    function _decodeParams(bytes memory params)
        internal
        pure
        returns (executeOperationVars memory)
    {
        (
            IERC20Detailed assetToSwapTo,
            uint64 assetToSwapToTranche,
            uint256 minAmountToReceive,
            uint256 swapAllBalanceOffset,
            bytes memory swapCalldata,
            IParaSwapAugustus augustus,
            PermitSignature memory permitParams
        ) = abi.decode(
                params,
                (
                    IERC20Detailed,
                    uint64,
                    uint256,
                    uint256,
                    bytes,
                    IParaSwapAugustus,
                    PermitSignature
                )
            );

        return
            executeOperationVars(
                assetToSwapTo,
                assetToSwapToTranche,
                minAmountToReceive,
                swapAllBalanceOffset,
                swapCalldata,
                augustus,
                permitParams
            );
    }

    /**
     * @dev Swaps the received reserve amount from the flash loan into the asset specified in the params.
     * The received funds from the swap are then deposited into the protocol on behalf of the user.
     * The user should give this contract allowance to pull the ATokens in order to withdraw the underlying asset and repay the flash loan.
     * @param assets Address of the underlying asset to be swapped from
     * @param amounts Amount of the flash loan i.e. maximum amount to swap
     * @param premiums Fee of the flash loan
     * @param initiator Account that initiated the flash loan
     * @param params Additional variadic field to include extra params. Expected parameters:
     *   address assetToSwapTo Address of the underlying asset to be swapped to and deposited
     *   uint256 minAmountToReceive Min amount to be received from the swap
     *   uint256 swapAllBalanceOffset Set to offset of fromAmount in Augustus calldata if wanting to swap all balance, otherwise 0
     *   bytes swapCalldata Calldata for ParaSwap's AugustusSwapper contract
     *   address augustus Address of ParaSwap's AugustusSwapper contract
     *   PermitSignature permitParams Struct containing the permit signatures, set to all zeroes if not used
     */
    function executeOperation(
        address[] calldata assets,
        uint256[] calldata amounts,
        uint256[] calldata premiums,
        address initiator,
        bytes calldata params
    ) external override nonReentrant returns (bool) {
        require(
            msg.sender == address(LENDING_POOL),
            "CALLER_MUST_BE_LENDING_POOL"
        );
        require(
            assets.length == 1 && amounts.length == 1 && premiums.length == 1,
            "FLASHLOAN_MULTIPLE_ASSETS_NOT_SUPPORTED"
        );

        // executeOperationVars memory vars = _decodeParams(params);

        _swapLiquidity(
            _decodeParams(params),
            amounts[0],
            premiums[0],
            initiator,
            assets[0]
        );

        return true;
    }

    /**
     * @dev Swaps an amount of an asset to another and deposits the new asset amount on behalf of the user without using a flash loan.
     * This method can be used when the temporary transfer of the collateral asset to this contract does not affect the user position.
     * The user should give this contract allowance to pull the ATokens in order to withdraw the underlying asset and perform the swap.
     * @param assetToSwapFrom Address of the underlying asset to be swapped from
     * @param assetToSwapTo Address of the underlying asset to be swapped to and deposited
     * @param amountToSwap Amount to be swapped, or maximum amount when swapping all balance
     * @param minAmountToReceive Minimum amount to be received from the swap
     * @param swapAllBalanceOffset Set to offset of fromAmount in Augustus calldata if wanting to swap all balance, otherwise 0
     * @param swapCalldata Calldata for ParaSwap's AugustusSwapper contract
     * @param augustus Address of ParaSwap's AugustusSwapper contract
     * @param permitParams Struct containing the permit signatures, set to all zeroes if not used
     */
    function swapAndDeposit(
        DataTypes.TrancheAddress memory assetToSwapFrom,
        DataTypes.TrancheAddress memory assetToSwapTo,
        uint256 amountToSwap,
        uint256 minAmountToReceive,
        uint256 swapAllBalanceOffset,
        bytes calldata swapCalldata,
        IParaSwapAugustus augustus,
        PermitSignature calldata permitParams
    ) external nonReentrant {
        IERC20WithPermit aToken = IERC20WithPermit(
            _getReserveData(
                address(assetToSwapFrom.asset),
                assetToSwapFrom.trancheId
            ).aTokenAddress
        );

        if (swapAllBalanceOffset != 0) {
            uint256 balance = aToken.balanceOf(msg.sender);
            require(balance <= amountToSwap, "INSUFFICIENT_AMOUNT_TO_SWAP");
            amountToSwap = balance;
        }

        _pullATokenAndWithdraw(
            address(assetToSwapFrom.asset),
            assetToSwapFrom.trancheId,
            aToken,
            msg.sender,
            amountToSwap,
            permitParams
        );

        uint256 amountReceived = _sellOnParaSwap(
            swapAllBalanceOffset,
            swapCalldata,
            augustus,
            IERC20Detailed(assetToSwapFrom.asset),
            IERC20Detailed(assetToSwapTo.asset),
            amountToSwap,
            minAmountToReceive
        );

        IERC20Detailed(assetToSwapTo.asset).approve(address(LENDING_POOL), 0);
        IERC20Detailed(assetToSwapTo.asset).approve(
            address(LENDING_POOL),
            amountReceived
        );
        LENDING_POOL.deposit(
            address(assetToSwapTo.asset),
            assetToSwapTo.trancheId,
            amountReceived,
            msg.sender,
            0
        );
    }

    /**
     * @dev Swaps an amount of an asset to another and deposits the funds on behalf of the initiator.
     * @param vars vars data
     * @param flashLoanAmount Amount of the flash loan i.e. maximum amount to swap
     * @param premium Fee of the flash loan
     * @param initiator Account that initiated the flash loan
     */
    function _swapLiquidity(
        executeOperationVars memory vars,
        uint256 flashLoanAmount,
        uint256 premium,
        address initiator,
        address assetToSwapFrom
    ) internal {
        IERC20WithPermit aToken = IERC20WithPermit(
            _getReserveData(address(assetToSwapFrom), vars.assetToSwapToTranche)
                .aTokenAddress
        );
        uint256 amountToSwap = flashLoanAmount;

        uint256 balance = aToken.balanceOf(initiator);
        if (vars.swapAllBalanceOffset != 0) {
            uint256 balanceToSwap = balance.sub(premium);
            require(
                balanceToSwap <= amountToSwap,
                "INSUFFICIENT_AMOUNT_TO_SWAP"
            );
            amountToSwap = balanceToSwap;
        } else {
            require(
                balance >= amountToSwap.add(premium),
                "INSUFFICIENT_ATOKEN_BALANCE"
            );
        }

        uint256 amountReceived = _sellOnParaSwap(
            vars.swapAllBalanceOffset,
            vars.swapCalldata,
            vars.augustus,
            IERC20Detailed(assetToSwapFrom),
            vars.assetToSwapTo,
            amountToSwap,
            vars.minAmountToReceive
        );

        vars.assetToSwapTo.approve(address(LENDING_POOL), 0);
        vars.assetToSwapTo.approve(address(LENDING_POOL), amountReceived);
        LENDING_POOL.deposit(
            address(vars.assetToSwapTo),
            vars.assetToSwapToTranche,
            amountReceived,
            initiator,
            0
        );

        _pullATokenAndWithdraw(
            address(assetToSwapFrom),
            vars.assetToSwapToTranche, //must be the same tranche
            aToken,
            initiator,
            amountToSwap.add(premium),
            vars.permitParams
        );

        // Repay flash loan
        IERC20Detailed(assetToSwapFrom).approve(address(LENDING_POOL), 0);
        IERC20Detailed(assetToSwapFrom).approve(
            address(LENDING_POOL),
            flashLoanAmount.add(premium)
        );
    }
}

// SPDX-License-Identifier: agpl-3.0
pragma solidity >=0.8.0;

import {BaseUniswapAdapter} from "./BaseUniswapAdapter.sol";
import {ILendingPoolAddressesProvider} from "../interfaces/ILendingPoolAddressesProvider.sol";
import {IUniswapV2Router02} from "../interfaces/IUniswapV2Router02.sol";
import {IERC20} from "../dependencies/openzeppelin/contracts/IERC20.sol";
import {SafeMath} from "../dependencies/openzeppelin/contracts/SafeMath.sol";
import {DataTypes} from "../protocol/libraries/types/DataTypes.sol";

/**
 * @title UniswapLiquiditySwapAdapter
 * @notice Uniswap V2 Adapter to swap liquidity.
 * @author Aave
 **/
contract UniswapLiquiditySwapAdapter is BaseUniswapAdapter {
    using SafeMath for uint256;

    struct PermitParams {
        uint256[] amount;
        uint256[] deadline;
        uint8[] v;
        bytes32[] r;
        bytes32[] s;
    }

    struct SwapParams {
        address[] assetToSwapToList;
        uint64[] assetToSwapToListTranche;
        uint256[] minAmountsToReceive;
        bool[] swapAllBalance;
        PermitParams permitParams;
        bool[] useEthPath;
    }

    constructor(
        ILendingPoolAddressesProvider addressesProvider,
        IUniswapV2Router02 uniswapRouter,
        address wethAddress
    ) BaseUniswapAdapter(addressesProvider, uniswapRouter, wethAddress) {}

    /**
     * @dev Swaps the received reserve amount from the flash loan into the asset specified in the params.
     * The received funds from the swap are then deposited into the protocol on behalf of the user.
     * The user should give this contract allowance to pull the ATokens in order to withdraw the underlying asset and
     * repay the flash loan.
     * @param assets Address of asset to be swapped
     * @param amounts Amount of the asset to be swapped
     * @param premiums Fee of the flash loan
     * @param initiator Address of the user
     * @param params Additional variadic field to include extra params. Expected parameters:
     *   address[] assetToSwapToList List of the addresses of the reserve to be swapped to and deposited
     *   uint256[] minAmountsToReceive List of min amounts to be received from the swap
     *   bool[] swapAllBalance Flag indicating if all the user balance should be swapped
     *   uint256[] permitAmount List of amounts for the permit signature
     *   uint256[] deadline List of deadlines for the permit signature
     *   uint8[] v List of v param for the permit signature
     *   bytes32[] r List of r param for the permit signature
     *   bytes32[] s List of s param for the permit signature
     */
    function executeOperation(
        address[] calldata assets,
        uint256[] calldata amounts,
        uint256[] calldata premiums,
        address initiator,
        bytes calldata params
    ) external override returns (bool) {
        require(
            msg.sender == address(LENDING_POOL),
            "CALLER_MUST_BE_LENDING_POOL"
        );

        SwapParams memory decodedParams = _decodeParams(params);

        require(
            assets.length == decodedParams.assetToSwapToList.length &&
                assets.length ==
                decodedParams.assetToSwapToListTranche.length &&
                assets.length == decodedParams.minAmountsToReceive.length &&
                assets.length == decodedParams.swapAllBalance.length &&
                assets.length == decodedParams.permitParams.amount.length &&
                assets.length == decodedParams.permitParams.deadline.length &&
                assets.length == decodedParams.permitParams.v.length &&
                assets.length == decodedParams.permitParams.r.length &&
                assets.length == decodedParams.permitParams.s.length &&
                assets.length == decodedParams.useEthPath.length,
            "INCONSISTENT_PARAMS"
        );

        for (uint256 i = 0; i < assets.length; i++) {
            _swapLiquidity(
                assets[i],
                decodedParams.assetToSwapToListTranche[i],
                decodedParams.assetToSwapToList[i],
                decodedParams.assetToSwapToListTranche[i],
                amounts[i],
                premiums[i],
                initiator,
                decodedParams.minAmountsToReceive[i],
                decodedParams.swapAllBalance[i],
                PermitSignature(
                    decodedParams.permitParams.amount[i],
                    decodedParams.permitParams.deadline[i],
                    decodedParams.permitParams.v[i],
                    decodedParams.permitParams.r[i],
                    decodedParams.permitParams.s[i]
                ),
                decodedParams.useEthPath[i]
            );
        }

        return true;
    }

    struct SwapAndDepositLocalVars {
        uint256 i;
        uint256 aTokenInitiatorBalance;
        uint256 amountToSwap;
        uint256 receivedAmount;
        address aToken;
    }

    /**
     * @dev Swaps an amount of an asset to another and deposits the new asset amount on behalf of the user without using
     * a flash loan. This method can be used when the temporary transfer of the collateral asset to this contract
     * does not affect the user position.
     * The user should give this contract allowance to pull the ATokens in order to withdraw the underlying asset and
     * perform the swap.
     * @param assetToSwapFromList List of addresses of the underlying asset to be swap from
     * @param assetToSwapToList List of addresses of the underlying asset to be swap to and deposited
     * @param amountToSwapList List of amounts to be swapped. If the amount exceeds the balance, the total balance is used for the swap
     * @param minAmountsToReceive List of min amounts to be received from the swap
     * @param permitParams List of struct containing the permit signatures
     *   uint256 permitAmount Amount for the permit signature
     *   uint256 deadline Deadline for the permit signature
     *   uint8 v param for the permit signature
     *   bytes32 r param for the permit signature
     *   bytes32 s param for the permit signature
     * @param useEthPath true if the swap needs to occur using ETH in the routing, false otherwise
     */
    function swapAndDeposit(
        DataTypes.TrancheAddress[] calldata assetToSwapFromList,
        DataTypes.TrancheAddress[] calldata assetToSwapToList,
        uint256[] calldata amountToSwapList,
        uint256[] calldata minAmountsToReceive,
        PermitSignature[] calldata permitParams,
        bool[] calldata useEthPath
    ) external {
        require(
            assetToSwapFromList.length == assetToSwapToList.length &&
                assetToSwapFromList.length == amountToSwapList.length &&
                assetToSwapFromList.length == minAmountsToReceive.length &&
                assetToSwapFromList.length == permitParams.length,
            "INCONSISTENT_PARAMS"
        );

        SwapAndDepositLocalVars memory vars;

        for (vars.i = 0; vars.i < assetToSwapFromList.length; vars.i++) {
            vars.aToken = _getReserveData(
                assetToSwapFromList[vars.i].asset,
                assetToSwapFromList[vars.i].trancheId
            ).aTokenAddress;

            vars.aTokenInitiatorBalance = IERC20(vars.aToken).balanceOf(
                msg.sender
            );
            vars.amountToSwap = amountToSwapList[vars.i] >
                vars.aTokenInitiatorBalance
                ? vars.aTokenInitiatorBalance
                : amountToSwapList[vars.i];

            _pullAToken(
                assetToSwapFromList[vars.i].asset,
                assetToSwapFromList[vars.i].trancheId,
                vars.aToken,
                msg.sender,
                vars.amountToSwap,
                permitParams[vars.i]
            );

            vars.receivedAmount = _swapExactTokensForTokens(
                assetToSwapFromList[vars.i].asset,
                assetToSwapToList[vars.i].asset,
                vars.amountToSwap,
                minAmountsToReceive[vars.i],
                useEthPath[vars.i]
            );

            // Deposit new reserve
            IERC20(assetToSwapToList[vars.i].asset).approve(
                address(LENDING_POOL),
                0
            );
            IERC20(assetToSwapToList[vars.i].asset).approve(
                address(LENDING_POOL),
                vars.receivedAmount
            );
            LENDING_POOL.deposit(
                assetToSwapToList[vars.i].asset,
                assetToSwapToList[vars.i].trancheId,
                vars.receivedAmount,
                msg.sender,
                0
            );
        }
    }

    /**
     * @dev Swaps an `amountToSwap` of an asset to another and deposits the funds on behalf of the initiator.
     * @param assetFrom Address of the underlying asset to be swap from
     * @param assetTo Address of the underlying asset to be swap to and deposited
     * @param amount Amount from flash loan
     * @param premium Premium of the flash loan
     * @param minAmountToReceive Min amount to be received from the swap
     * @param swapAllBalance Flag indicating if all the user balance should be swapped
     * @param permitSignature List of struct containing the permit signature
     * @param useEthPath true if the swap needs to occur using ETH in the routing, false otherwise
     */

    struct SwapLiquidityLocalVars {
        address aToken;
        uint256 aTokenInitiatorBalance;
        uint256 amountToSwap;
        uint256 receivedAmount;
        uint256 flashLoanDebt;
        uint256 amountToPull;
    }

    function _swapLiquidity(
        address assetFrom,
        uint64 assetFromTranche,
        address assetTo,
        uint64 assetToTranche,
        uint256 amount,
        uint256 premium,
        address initiator,
        uint256 minAmountToReceive,
        bool swapAllBalance,
        PermitSignature memory permitSignature,
        bool useEthPath
    ) internal {
        SwapLiquidityLocalVars memory vars;

        vars.aToken = _getReserveData(assetFrom, assetFromTranche)
            .aTokenAddress;

        vars.aTokenInitiatorBalance = IERC20(vars.aToken).balanceOf(initiator);
        vars.amountToSwap = swapAllBalance &&
            vars.aTokenInitiatorBalance.sub(premium) <= amount
            ? vars.aTokenInitiatorBalance.sub(premium)
            : amount;

        vars.receivedAmount = _swapExactTokensForTokens(
            assetFrom,
            assetTo,
            vars.amountToSwap,
            minAmountToReceive,
            useEthPath
        );

        // Deposit new reserve
        IERC20(assetTo).approve(address(LENDING_POOL), 0);
        IERC20(assetTo).approve(address(LENDING_POOL), vars.receivedAmount);
        LENDING_POOL.deposit(
            assetTo,
            assetToTranche,
            vars.receivedAmount,
            initiator,
            0
        );

        vars.flashLoanDebt = amount.add(premium);
        vars.amountToPull = vars.amountToSwap.add(premium);

        _pullAToken(
            assetFrom,
            assetFromTranche,
            vars.aToken,
            initiator,
            vars.amountToPull,
            permitSignature
        );

        // Repay flash loan
        IERC20(assetFrom).approve(address(LENDING_POOL), 0);
        IERC20(assetFrom).approve(address(LENDING_POOL), vars.flashLoanDebt);
    }

    /**
     * @dev Decodes the information encoded in the flash loan params
     * @param params Additional variadic field to include extra params. Expected parameters:
     *   address[] assetToSwapToList List of the addresses of the reserve to be swapped to and deposited
     *   uint256[] minAmountsToReceive List of min amounts to be received from the swap
     *   bool[] swapAllBalance Flag indicating if all the user balance should be swapped
     *   uint256[] permitAmount List of amounts for the permit signature
     *   uint256[] deadline List of deadlines for the permit signature
     *   uint8[] v List of v param for the permit signature
     *   bytes32[] r List of r param for the permit signature
     *   bytes32[] s List of s param for the permit signature
     *   bool[] useEthPath true if the swap needs to occur using ETH in the routing, false otherwise
     * @return SwapParams struct containing decoded params
     */
    function _decodeParams(bytes memory params)
        internal
        pure
        returns (SwapParams memory)
    {
        (
            address[] memory assetToSwapToList,
            uint64[] memory assetToSwapToListTranche,
            uint256[] memory minAmountsToReceive,
            bool[] memory swapAllBalance,
            uint256[] memory permitAmount,
            uint256[] memory deadline,
            uint8[] memory v,
            bytes32[] memory r,
            bytes32[] memory s,
            bool[] memory useEthPath
        ) = abi.decode(
                params,
                (
                    address[],
                    uint64[],
                    uint256[],
                    bool[],
                    uint256[],
                    uint256[],
                    uint8[],
                    bytes32[],
                    bytes32[],
                    bool[]
                )
            );

        return
            SwapParams(
                assetToSwapToList,
                assetToSwapToListTranche,
                minAmountsToReceive,
                swapAllBalance,
                PermitParams(permitAmount, deadline, v, r, s),
                useEthPath
            );
    }
}

// SPDX-License-Identifier: agpl-3.0
pragma solidity >=0.8.0;

import {BaseUniswapAdapter} from "./BaseUniswapAdapter.sol";
import {ILendingPoolAddressesProvider} from "../interfaces/ILendingPoolAddressesProvider.sol";
import {IUniswapV2Router02} from "../interfaces/IUniswapV2Router02.sol";
import {IERC20} from "../dependencies/openzeppelin/contracts/IERC20.sol";
import {DataTypes} from "../protocol/libraries/types/DataTypes.sol";
import {SafeMath} from "../dependencies/openzeppelin/contracts/SafeMath.sol";

/**
 * @title UniswapRepayAdapter
 * @notice Uniswap V2 Adapter to perform a repay of a debt with collateral.
 * @author Aave
 **/
contract UniswapRepayAdapter is BaseUniswapAdapter {
    using SafeMath for uint256;

    struct RepayParams {
        DataTypes.TrancheAddress collateralAsset;
        uint256 collateralAmount;
        uint256 rateMode;
        PermitSignature permitSignature;
        bool useEthPath;
    }

    constructor(
        ILendingPoolAddressesProvider addressesProvider,
        IUniswapV2Router02 uniswapRouter,
        address wethAddress
    ) BaseUniswapAdapter(addressesProvider, uniswapRouter, wethAddress) {}

    /**
     * @dev Uses the received funds from the flash loan to repay a debt on the protocol on behalf of the user. Then pulls
     * the collateral from the user and swaps it to the debt asset to repay the flash loan.
     * The user should give this contract allowance to pull the ATokens in order to withdraw the underlying asset, swap it
     * and repay the flash loan.
     * Supports only one asset on the flash loan.
     * @param assets Address of debt asset
     * @param amounts Amount of the debt to be repaid
     * @param premiums Fee of the flash loan
     * @param initiator Address of the user
     * @param params Additional variadic field to include extra params. Expected parameters:
     *   address collateralAsset Address of the reserve to be swapped
     *   uint256 collateralAmount Amount of reserve to be swapped
     *   uint256 permitAmount Amount for the permit signature
     *   uint256 deadline Deadline for the permit signature
     *   uint8 v V param for the permit signature
     *   bytes32 r R param for the permit signature
     *   bytes32 s S param for the permit signature
     */
    function executeOperation(
        address[] calldata assets,
        uint256[] calldata amounts,
        uint256[] calldata premiums,
        address initiator,
        bytes calldata params
    ) external override returns (bool) {
        require(
            msg.sender == address(LENDING_POOL),
            "CALLER_MUST_BE_LENDING_POOL"
        );

        RepayParams memory decodedParams = _decodeParams(params);

        //check logic
        _swapAndRepay(
            decodedParams.collateralAsset,
            assets[0],
            amounts[0],
            decodedParams.collateralAmount,
            initiator,
            premiums[0],
            decodedParams.permitSignature,
            decodedParams.useEthPath
        );

        return true;
    }

    /**
   * @dev Swaps the user collateral for the debt asset and then repay the debt on the protocol on behalf of the user
   * without using flash loans. This method can be used when the temporary transfer of the collateral asset to this
   * contract does not affect the user position.
   * The user should give this contract allowance to pull the ATokens in order to withdraw the underlying asset
   * @param collateralAsset Address of asset to be swapped
   * @param debtAsset Address of debt asset
   * @param collateralAmount Amount of the collateral to be swapped
   * @param debtRepayAmount Amount of the debt to be repaid
   * @param permitSignature struct containing the permit signature
   * @param useEthPath 'true' to use path that swaps to Weth, 'false' to directly swap from collateral to debt asset
   */
    function swapAndRepay(
        DataTypes.TrancheAddress calldata collateralAsset,
        DataTypes.TrancheAddress calldata debtAsset,
        uint256 collateralAmount,
        uint256 debtRepayAmount,
        PermitSignature calldata permitSignature,
        bool useEthPath
    ) external {
        DataTypes.ReserveData memory collateralReserveData = _getReserveData(
            collateralAsset.asset,
            collateralAsset.trancheId
        );
        DataTypes.ReserveData memory debtReserveData = _getReserveData(
            debtAsset.asset,
            collateralAsset.trancheId
        );

        address debtToken = debtReserveData.variableDebtTokenAddress;

        uint256 currentDebt = IERC20(debtToken).balanceOf(msg.sender);
        uint256 amountToRepay = debtRepayAmount <= currentDebt
            ? debtRepayAmount
            : currentDebt;

        if (collateralAsset.asset != debtAsset.asset) {
            uint256 maxCollateralToSwap = collateralAmount;
            if (amountToRepay < debtRepayAmount) {
                maxCollateralToSwap = maxCollateralToSwap
                    .mul(amountToRepay)
                    .div(debtRepayAmount);
            }

            // Get exact collateral needed for the swap to avoid leftovers
            uint256[] memory amounts = _getAmountsIn(
                collateralAsset.asset,
                debtAsset.asset,
                amountToRepay,
                useEthPath
            );
            require(amounts[0] <= maxCollateralToSwap, "slippage too high");

            // Pull aTokens from user
            _pullAToken(
                collateralAsset.asset,
                collateralAsset.trancheId,
                collateralReserveData.aTokenAddress,
                msg.sender,
                amounts[0],
                permitSignature
            );

            // Swap collateral for debt asset
            _swapTokensForExactTokens(
                collateralAsset.asset,
                debtAsset.asset,
                amounts[0],
                amountToRepay,
                useEthPath
            );
        } else {
            // Pull aTokens from user
            _pullAToken(
                collateralAsset.asset,
                collateralAsset.trancheId,
                collateralReserveData.aTokenAddress,
                msg.sender,
                amountToRepay,
                permitSignature
            );
        }

        // Repay debt. Approves 0 first to comply with tokens that implement the anti frontrunning approval fix
        IERC20(debtAsset.asset).approve(address(LENDING_POOL), 0);
        IERC20(debtAsset.asset).approve(address(LENDING_POOL), amountToRepay);
        LENDING_POOL.repay(
            debtAsset.asset,
            debtAsset.trancheId,
            amountToRepay,
            msg.sender
        );
    }

    /**
     * @dev Perform the repay of the debt, pulls the initiator collateral and swaps to repay the flash loan
     *
     * @param collateralAsset Address of token to be swapped
     * @param debtAsset Address of debt token to be received from the swap
     * @param amount Amount of the debt to be repaid
     * @param collateralAmount Amount of the reserve to be swapped
     * @param initiator Address of the user
     * @param premium Fee of the flash loan
     * @param permitSignature struct containing the permit signature
     * @param useEthPath 'true' to use path that swaps to Weth, 'false' to directly swap from collateral to debt asset
     */
    function _swapAndRepay(
        DataTypes.TrancheAddress memory collateralAsset,
        address debtAsset,
        uint256 amount,
        uint256 collateralAmount,
        address initiator,
        uint256 premium,
        PermitSignature memory permitSignature,
        bool useEthPath
    ) internal {
        DataTypes.ReserveData memory collateralReserveData = _getReserveData(
            collateralAsset.asset,
            collateralAsset.trancheId
        );

        // Repay debt. Approves for 0 first to comply with tokens that implement the anti frontrunning approval fix.
        IERC20(debtAsset).approve(address(LENDING_POOL), 0);
        IERC20(debtAsset).approve(address(LENDING_POOL), amount);
        uint256 repaidAmount = IERC20(debtAsset).balanceOf(address(this));
        LENDING_POOL.repay(
            debtAsset,
            collateralAsset.trancheId, //debt and collateral trancheId are the same
            amount,
            initiator
        );
        repaidAmount = repaidAmount.sub(
            IERC20(debtAsset).balanceOf(address(this))
        );

        if (collateralAsset.asset != debtAsset) {
            uint256 maxCollateralToSwap = collateralAmount;
            if (repaidAmount < amount) {
                maxCollateralToSwap = maxCollateralToSwap.mul(repaidAmount).div(
                        amount
                    );
            }

            uint256 neededForFlashLoanDebt = repaidAmount.add(premium);
            uint256[] memory amounts = _getAmountsIn(
                collateralAsset.asset,
                debtAsset,
                neededForFlashLoanDebt,
                useEthPath
            );
            require(amounts[0] <= maxCollateralToSwap, "slippage too high");

            // Pull aTokens from user
            _pullAToken(
                collateralAsset.asset,
                collateralAsset.trancheId,
                collateralReserveData.aTokenAddress,
                initiator,
                amounts[0],
                permitSignature
            );

            // Swap collateral asset to the debt asset
            _swapTokensForExactTokens(
                collateralAsset.asset,
                debtAsset,
                amounts[0],
                neededForFlashLoanDebt,
                useEthPath
            );
        } else {
            // Pull aTokens from user
            _pullAToken(
                collateralAsset.asset,
                collateralAsset.trancheId,
                collateralReserveData.aTokenAddress,
                initiator,
                repaidAmount.add(premium),
                permitSignature
            );
        }

        // Repay flashloan. Approves for 0 first to comply with tokens that implement the anti frontrunning approval fix.
        IERC20(debtAsset).approve(address(LENDING_POOL), 0);
        IERC20(debtAsset).approve(address(LENDING_POOL), amount.add(premium));
    }

    /**
     * @dev Decodes debt information encoded in the flash loan params
     * @param params Additional variadic field to include extra params. Expected parameters:
     *   address collateralAsset Address of the reserve to be swapped
     *   uint256 collateralAmount Amount of reserve to be swapped
     *   uint256 rateMode Rate modes of the debt to be repaid
     *   uint256 permitAmount Amount for the permit signature
     *   uint256 deadline Deadline for the permit signature
     *   uint8 v V param for the permit signature
     *   bytes32 r R param for the permit signature
     *   bytes32 s S param for the permit signature
     *   bool useEthPath use WETH path route
     * @return RepayParams struct containing decoded params
     */
    function _decodeParams(bytes memory params)
        internal
        pure
        returns (RepayParams memory)
    {
        (
            address collateralAsset,
            uint64 collateralTranche,
            uint256 collateralAmount,
            uint256 rateMode,           // TODO: Figure out where this is called and remove this param
            uint256 permitAmount,
            uint256 deadline,
            uint8 v,
            bytes32 r,
            bytes32 s,
            bool useEthPath
        ) = abi.decode(
                params,
                (
                    address,
                    uint64,
                    uint256,
                    uint256,
                    uint256,
                    uint256,
                    uint8,
                    bytes32,
                    bytes32,
                    bool
                )
            );
        return
            RepayParams(
                DataTypes.TrancheAddress(collateralTranche, collateralAsset),
                collateralAmount,
                rateMode,
                PermitSignature(permitAmount, deadline, v, r, s),
                useEthPath
            );
    }
}

import { QueryAssetHelpers } from "../libs/QueryAssetHelpers.sol";
import { ILendingPoolAddressesProvider } from "../../interfaces/ILendingPoolAddressesProvider.sol";
import { AssetMappings } from "../../protocol/lendingpool/AssetMappings.sol";
import { IERC20Detailed } from "../../dependencies/openzeppelin/contracts/IERC20Detailed.sol";

import { IPriceOracleGetter } from "../../interfaces/IPriceOracleGetter.sol";

contract GetAllAssetPrices {

    struct AssetPrice {
        address oracle;
        uint256 priceETH;
        uint256 priceUSD;
    }

	constructor(address providerAddr, address[] memory assets)
    {
        AssetPrice[] memory allAssetPrices = new AssetPrice[](assets.length);

        AssetMappings a = AssetMappings(ILendingPoolAddressesProvider(providerAddr).getAssetMappings());

        for (uint64 i = 0; i < assets.length; i++) {
            allAssetPrices[i].oracle = ILendingPoolAddressesProvider(providerAddr)
                .getPriceOracle();
            allAssetPrices[i].priceETH = IPriceOracleGetter(allAssetPrices[i].oracle).getAssetPrice(assets[i]);

            allAssetPrices[i].priceUSD = QueryAssetHelpers.convertAmountToUsd(
                allAssetPrices[i].oracle,
                assets[i],
                1,
                0);
        }

	    bytes memory returnData = abi.encode(allAssetPrices);
		assembly {
			return(add(0x20, returnData), mload(returnData))
		}
	}

	function getType() public view returns(AssetPrice[] memory){}

}

import { QueryAssetHelpers } from "../libs/QueryAssetHelpers.sol";
import { ILendingPool } from "../../interfaces/ILendingPool.sol";
import { ILendingPoolAddressesProvider } from "../../interfaces/ILendingPoolAddressesProvider.sol";

//import "hardhat/console.sol";
// NOTE: this function starts to fail if we have a large number of markets
contract GetAllTrancheAssetsData {

	constructor(address providerAddr, uint64 tranche)
    {
        address lendingPool = ILendingPoolAddressesProvider(providerAddr).getLendingPool();

        // TODO: find deterministic upper bound. temporary solution: 35 assets per tranche

        address[] memory assets = ILendingPool(lendingPool).getReservesList(tranche);
        QueryAssetHelpers.AssetData[] memory allAssetsData = new QueryAssetHelpers.AssetData[](assets.length);
        for (uint64 i = 0; i < assets.length; i++) {
            allAssetsData[i] = QueryAssetHelpers.getAssetData(
                assets[i], tranche, providerAddr);
        }

	    bytes memory returnData = abi.encode(allAssetsData);
		assembly {
			return(add(0x20, returnData), mload(returnData))
		}
	}

	function getType() public view returns(QueryAssetHelpers.AssetData[] memory){}

}

import { QueryAssetHelpers } from "../libs/QueryAssetHelpers.sol";

//import "hardhat/console.sol";

contract GetTrancheAssetData {
	constructor(
        address providerAddr,
        address asset,
        uint64 tranche)
    {
        QueryAssetHelpers.AssetData memory assetData = QueryAssetHelpers.getAssetData(
            asset, tranche, providerAddr);

	    bytes memory returnData = abi.encode(assetData);
		assembly {
			return(add(0x20, returnData), mload(returnData))
		}
	}
	function getType() public view returns(QueryAssetHelpers.AssetData memory){}

}

import { DataTypes } from "../../protocol/libraries/types/DataTypes.sol";
import { ReserveConfiguration } from "../../protocol/libraries/configuration/ReserveConfiguration.sol";
import { WadRayMath } from "../../protocol/libraries/math/WadRayMath.sol";
import { SafeMath } from "../../protocol/libraries/math/MathUtils.sol";
import { ILendingPool } from "../../interfaces/ILendingPool.sol";
import { ILendingPoolAddressesProvider } from "../../interfaces/ILendingPoolAddressesProvider.sol";
import { AssetMappings } from "../../protocol/lendingpool/AssetMappings.sol";
import { IERC20 } from "../../dependencies/openzeppelin/contracts/IERC20.sol";
import { IAToken } from "../../interfaces/IAToken.sol";
import { IBaseStrategy } from "../../interfaces/IBaseStrategy.sol";
import { IPriceOracleGetter } from "../../interfaces/IPriceOracleGetter.sol";
import { IChainlinkAggregator } from "../../interfaces/IChainlinkAggregator.sol";

library QueryAssetHelpers {

    using ReserveConfiguration for DataTypes.ReserveConfigurationMap;
    using WadRayMath for uint256;
    using SafeMath for uint256;

    struct AssetData {
        uint64 tranche;
        address asset;
        uint256 decimals;
        uint256 ltv;
        uint256 liquidationThreshold;
        uint256 liquidationBonus;
        bool canBeCollateral;
        bool canBeBorrowed;
        address oracle;
        uint256 totalSupplied;
        uint256 utilization;
        uint256 totalBorrowed;
        address strategyAddress;
        uint256 adminFee;
        uint256 platformFee;
        uint128 supplyApy;
        uint128 borrowApy;
        uint256 totalReserves;
        uint256 totalReservesNative;
        uint256 currentPriceETH;
        uint256 supplyCap;
    }

    function getAssetData(
        address asset,
        uint64 tranche,
        address providerAddr
    )
        internal
        view
        returns (AssetData memory assetData)
    {
        ILendingPool lendingPool = ILendingPool(
            ILendingPoolAddressesProvider(providerAddr).getLendingPool()
        );

        AssetMappings a = AssetMappings(ILendingPoolAddressesProvider(providerAddr).getAssetMappings());


        DataTypes.ReserveData memory reserve = lendingPool.getReserveData(asset, tranche);
        assetData.tranche = tranche;
        assetData.asset = asset;
        (
            assetData.ltv,
            assetData.liquidationThreshold,
            assetData.liquidationBonus,
            assetData.decimals,
            //borrowFactor (not used yet)
        ) = a.getParams(asset);
        assetData.canBeCollateral = reserve.configuration.getCollateralEnabled();//assetData.liquidationThreshold != 0;
        assetData.canBeBorrowed = reserve.configuration.getBorrowingEnabled();
        assetData.oracle = ILendingPoolAddressesProvider(providerAddr).getPriceOracle();
        assetData.totalSupplied = convertAmountToUsd(assetData.oracle, assetData.asset, IAToken(reserve.aTokenAddress).totalSupply(), assetData.decimals);
        assetData.totalBorrowed = convertAmountToUsd(assetData.oracle, assetData.asset, IAToken(reserve.variableDebtTokenAddress).totalSupply(), assetData.decimals);
        assetData.strategyAddress = IAToken(reserve.aTokenAddress).getStrategy();

        assetData.totalReserves = convertAmountToUsd(assetData.oracle, assetData.asset, IERC20(asset).balanceOf(reserve.aTokenAddress), assetData.decimals);
        assetData.totalReservesNative = IERC20(asset).balanceOf(reserve.aTokenAddress);
        
        if (assetData.strategyAddress != address(0)) {
            // if strategy exists, add the funds the strategy holds
            // and the funds the strategy has boosted
            assetData.totalReserves = assetData.totalReserves.add(
                IBaseStrategy(assetData.strategyAddress).balanceOf()
            );
        }

        assetData.utilization = assetData.totalBorrowed == 0
            ? 0
            : assetData.totalBorrowed.rayDiv(assetData.totalReserves.add(assetData.totalBorrowed));

        assetData.adminFee = reserve.configuration.getReserveFactor();
        assetData.platformFee = a.getVMEXReserveFactor(asset);
        assetData.supplyApy = reserve.currentLiquidityRate;
        assetData.borrowApy = reserve.currentVariableBorrowRate;
        assetData.currentPriceETH = IPriceOracleGetter(assetData.oracle).getAssetPrice(assetData.asset);
        assetData.supplyCap = a.getSupplyCap(assetData.asset);

    }

    function convertAmountToUsd(
        address oracle,
        address underlying,
        uint256 amount,
        uint256 decimals
    ) view internal returns(uint256) {
        //has number of decimals equal to decimals of orig token
        uint256 assetPrice = IPriceOracleGetter(oracle).getAssetPrice(underlying);
        //amount is from atoken, which has same amount of tokens as underlying
        //ethAmount thus has 18 decimals

        //this has the same number of tokens as assetPrice. All ETH pairs have 18 decimals
        uint256 ethAmount = (amount * assetPrice) / (10**(decimals));
        uint256 ethUSD = uint256(IChainlinkAggregator(0x5f4eC3Df9cbd43714FE2740f5E3616155c5b8419).latestAnswer());

        //ethUSD/usdDecimals (unitless factor for conversion). So this is in units of chainlink aggregator. If ETH pair, it's 18
        return (ethAmount * ethUSD) / (10**IChainlinkAggregator(0x5f4eC3Df9cbd43714FE2740f5E3616155c5b8419).decimals()) ;
    }

    function convertEthToNative(
        address oracle,
        address underlying,
        uint256 ethAmount,
        uint256 decimals
    ) view internal returns(uint256) {
        //has number of decimals equal to decimals of orig token
        uint256 assetPrice = IPriceOracleGetter(oracle).getAssetPrice(underlying);
        //amount is from atoken, which has same amount of tokens as underlying
        //ethAmount thus has 18 decimals
        //18 decimals in ethAmount, assetPRice has 18 decimals, so returned is number of decimals of native
        return  (ethAmount * (10**(decimals))) / assetPrice;
    }

    function convertEthToUsd(
        uint256 amount
    ) view internal returns(uint256) {
        uint256 ethUSD = uint256(IChainlinkAggregator(0x5f4eC3Df9cbd43714FE2740f5E3616155c5b8419).latestAnswer());

        //units of amount is returned too
        return (amount * ethUSD) / (10**IChainlinkAggregator(0x5f4eC3Df9cbd43714FE2740f5E3616155c5b8419).decimals()) ;
    }
}

import { LendingPoolConfigurator } from "../../protocol/lendingpool/LendingPoolConfigurator.sol";
import { DataTypes } from "../../protocol/libraries/types/DataTypes.sol";
import { ReserveConfiguration } from "../../protocol/libraries/configuration/ReserveConfiguration.sol";
import { WadRayMath } from "../../protocol/libraries/math/WadRayMath.sol";
import { SafeMath } from "../../protocol/libraries/math/MathUtils.sol";
import { ILendingPool } from "../../interfaces/ILendingPool.sol";
import { LendingPool } from "../../protocol/lendingpool/LendingPool.sol";
import { ILendingPoolAddressesProvider } from "../../interfaces/ILendingPoolAddressesProvider.sol";
import { IAToken } from "../../interfaces/IAToken.sol";
import { IERC20 } from "../../dependencies/openzeppelin/contracts/IERC20.sol";
import { IERC20Detailed } from "../../dependencies/openzeppelin/contracts/IERC20Detailed.sol";
import { IBaseStrategy } from "../../interfaces/IBaseStrategy.sol";
import { IChainlinkAggregator } from "../../interfaces/IChainlinkAggregator.sol";
import { IPriceOracleGetter } from "../../interfaces/IPriceOracleGetter.sol";
import { QueryAssetHelpers } from "./QueryAssetHelpers.sol";

library QueryTrancheHelpers {

    using ReserveConfiguration for DataTypes.ReserveConfigurationMap;
    using WadRayMath for uint256;
    using SafeMath for uint256;

    struct TrancheData {
        uint64 id;
        string name;
        address[] assets;
        uint256 tvl;
        uint256 totalSupplied;
        uint256 totalBorrowed;
        uint256 availableLiquidity;
        bool upgradeable;   // TODO
        uint256 utilization;
        address admin;
        bool whitelist;     // TODO
        string grade;       // TODO
    }

    function getSingleTrancheData(
        uint64 tranche,
        address addressesProvider
    )
        internal
        view
        returns (TrancheData memory trancheData)
    {
        address lendingPool = ILendingPoolAddressesProvider(addressesProvider).getLendingPool();
        address configurator = ILendingPoolAddressesProvider(addressesProvider).getLendingPoolConfigurator();

        (trancheData.assets,
            trancheData.tvl,
            trancheData.totalSupplied,
            trancheData.totalBorrowed,
            trancheData.availableLiquidity,
            trancheData.utilization) = getAssetsSummaryData(tranche, addressesProvider);

        trancheData.id = tranche;
        trancheData.admin = ILendingPoolAddressesProvider(addressesProvider).getTrancheAdmin(tranche);
        trancheData.name = "ERROR: NAME STORED IN SUBGRAPH";
        trancheData.whitelist = LendingPool(lendingPool).isUsingWhitelist(tranche);
    }

    function getAssetsSummaryData(uint64 tranche, address addressesProvider)
        internal
        view
        returns (
            address[] memory assets,
            uint256 tvl,
            uint256 totalSupplied,
            uint256 totalBorrowed,
            uint256 availableLiquidity,
            uint256 utilization
        )
    {
        assets = ILendingPool(
            ILendingPoolAddressesProvider(addressesProvider).getLendingPool()
        ).getReservesList(tranche);

        for (uint8 i = 0; i < assets.length; i++) {

            QueryAssetHelpers.AssetData memory assetData =
                QueryAssetHelpers.getAssetData(assets[i], tranche, addressesProvider);

            tvl += assetData.totalReserves;

            totalSupplied += assetData.totalSupplied;
            totalBorrowed += assetData.totalBorrowed;
        }

        availableLiquidity = tvl;
        utilization = totalBorrowed == 0
                ? 0
                : totalBorrowed.rayDiv(availableLiquidity.add(totalBorrowed));
    }
}

import { AaveProtocolDataProvider } from "../../misc/AaveProtocolDataProvider.sol";
import { ILendingPool } from "../../interfaces/ILendingPool.sol";
import { ILendingPoolAddressesProvider } from "../../interfaces/ILendingPoolAddressesProvider.sol";
import { IERC20 } from "../../dependencies/openzeppelin/contracts/IERC20.sol";
import { IERC20Detailed } from "../../dependencies/openzeppelin/contracts/IERC20Detailed.sol";
import { IAToken } from "../../interfaces/IAToken.sol";
import { DataTypes } from "../../protocol/libraries/types/DataTypes.sol";
import { UserConfiguration } from "../../protocol/libraries/configuration/UserConfiguration.sol";
import { ReserveConfiguration } from "../../protocol/libraries/configuration/ReserveConfiguration.sol";
import { AssetMappings } from "../../protocol/lendingpool/AssetMappings.sol";
import { QueryAssetHelpers } from "./QueryAssetHelpers.sol";
import { IPriceOracleGetter } from "../../interfaces/IPriceOracleGetter.sol";
import {PercentageMath} from "../../protocol/libraries/math/PercentageMath.sol";

//import "hardhat/console.sol";
library QueryUserHelpers {
    using ReserveConfiguration for DataTypes.ReserveConfigurationMap;
    using UserConfiguration for DataTypes.UserConfigurationMap;
    using PercentageMath for uint256;

    struct SuppliedAssetData {
        address asset;
        uint64 tranche;
        uint256 amount; //in USD
        uint256 amountNative;
        bool isCollateral;
        uint128 apy;
        // uint256 supplyCap;
    }

    struct BorrowedAssetData {
        address asset;
        uint64 tranche;
        uint256 amount; //in USD
        uint256 amountNative;
        uint128 apy;
    }

    struct AvailableBorrowData {
        address asset;
        uint256 amountUSD;
        uint256 amountNative;
    }

    struct UserSummaryData {
        uint256 totalCollateralETH;
        uint256 totalDebtETH;
        uint256 availableBorrowsETH;
        SuppliedAssetData[] suppliedAssetData;
        BorrowedAssetData[] borrowedAssetData;
        // currentLiquidationThreshold, ltv, healthFactor metrics don't make sense
        // for aggregating data across all tranches
    }

    struct UserTrancheData {
        uint256 totalCollateralETH;
        uint256 totalDebtETH;
        uint256 availableBorrowsETH;
        uint256 currentLiquidationThreshold;
        uint256 ltv;
        uint256 healthFactor;
        uint256 avgBorrowFactor;
        SuppliedAssetData[] suppliedAssetData;
        BorrowedAssetData[] borrowedAssetData;
        AvailableBorrowData[] assetBorrowingPower;
    }

    function getUserTrancheData(
        address user,
        uint64 tranche,
        address addressesProvider)
    internal view returns (UserTrancheData memory userData)
    {
        ILendingPool lendingPool = ILendingPool(
            ILendingPoolAddressesProvider(addressesProvider).getLendingPool());

        (userData.totalCollateralETH,
            userData.totalDebtETH,
            ,
            userData.currentLiquidationThreshold,
            userData.ltv,
            userData.healthFactor,
            userData.avgBorrowFactor
            ) = lendingPool.getUserAccountData(user, tranche, false); //for displaying on FE, this should be false, since liquidations are based on this being false
        
        //this may need to be true for opening new borrows. But that isn't displayed, it is factored into availableBorrowsETH
        (,
            ,
            userData.availableBorrowsETH,
            ,
            ,
            ,
            ) = lendingPool.getUserAccountData(user, tranche, true);

        

        (userData.suppliedAssetData,
            userData.borrowedAssetData,
            userData.assetBorrowingPower) = getUserAssetData(user, tranche, addressesProvider, userData.availableBorrowsETH);
    }

    struct getUserAssetDataVars {
        uint256 s_idx;
        uint256 b_idx;
        DataTypes.ReserveData reserve;
        uint256 currentATokenBalance;
        uint256 currentVariableDebt;
        DataTypes.UserConfigurationMap userConfig;
        SuppliedAssetData[] tempSuppliedAssetData;
        BorrowedAssetData[] tempBorrowedAssetData;
        address[] allAssets;
    }

    function getUserAssetData(
        address user,
        uint64 tranche,
        address addressesProvider,
        uint256 availableBorrowsETH
    ) internal view returns (SuppliedAssetData[] memory s, BorrowedAssetData[] memory b, AvailableBorrowData[] memory c)
    {
        getUserAssetDataVars memory vars;
        ILendingPool lendingPool = ILendingPool(
            ILendingPoolAddressesProvider(addressesProvider).getLendingPool());
        
        

        vars.allAssets = lendingPool.getReservesList(tranche);
        vars.tempSuppliedAssetData = new SuppliedAssetData[](vars.allAssets.length);
        vars.tempBorrowedAssetData = new BorrowedAssetData[](vars.allAssets.length);
        c = new AvailableBorrowData[](vars.allAssets.length);
        vars.s_idx = 0;
        vars.b_idx = 0;

        vars.userConfig = lendingPool.getUserConfiguration(user, tranche);

        for (uint8 i = 0; i < vars.allAssets.length; i++) {
            vars.reserve = lendingPool.getReserveData(vars.allAssets[i], tranche);

            vars.currentATokenBalance = IERC20(vars.reserve.aTokenAddress).balanceOf(user);
            vars.currentVariableDebt = IERC20(vars.reserve.variableDebtTokenAddress).balanceOf(user);

            AssetMappings a = AssetMappings(ILendingPoolAddressesProvider(addressesProvider).getAssetMappings());
            address assetOracle = ILendingPoolAddressesProvider(addressesProvider)
                .getPriceOracle();

            if (vars.currentATokenBalance > 0) {
                // asset is being supplied
                vars.tempSuppliedAssetData[vars.s_idx++] = SuppliedAssetData ({
                    asset: vars.allAssets[i],
                    tranche: tranche,
                    amount: QueryAssetHelpers.convertAmountToUsd(
                        assetOracle,
                        vars.allAssets[i],
                        vars.currentATokenBalance,
                        a.getDecimals(vars.allAssets[i])),
                    amountNative: vars.currentATokenBalance,
                    isCollateral: vars.userConfig.isUsingAsCollateral(vars.reserve.id),
                    apy: vars.reserve.currentLiquidityRate
                    // supplyCap: a.getSupplyCap(vars.allAssets[i])
                });
            }

            if (vars.currentVariableDebt > 0) {
                vars.tempBorrowedAssetData[vars.b_idx++] = BorrowedAssetData ({
                    asset: vars.allAssets[i],
                    tranche: tranche,
                    amount: QueryAssetHelpers.convertAmountToUsd(
                        assetOracle,
                        vars.allAssets[i],
                        vars.currentVariableDebt,
                        a.getDecimals(vars.allAssets[i])),
                    amountNative: vars.currentVariableDebt,
                    apy: vars.reserve.currentVariableBorrowRate
                });
            }

            c[i] = AvailableBorrowData({
                asset: vars.allAssets[i],
                amountUSD: QueryAssetHelpers.convertEthToUsd(
                        availableBorrowsETH.percentDiv(a.getBorrowFactor(vars.allAssets[i])) //18 decimals, so returned is also 18
                    ),
                amountNative: QueryAssetHelpers.convertEthToNative(
                        assetOracle,
                        vars.allAssets[i],
                        availableBorrowsETH.percentDiv(a.getBorrowFactor(vars.allAssets[i])),
                        a.getDecimals(vars.allAssets[i])
                    )
            });
        }

        // return correctly sized arrays
        s = new SuppliedAssetData[](vars.s_idx);
        b = new BorrowedAssetData[](vars.b_idx);
        for (uint8 i = 0; i < vars.s_idx; i++) {
            s[i] = vars.tempSuppliedAssetData[i];
        }
        for (uint8 i = 0; i < vars.b_idx; i++) {
            b[i] = vars.tempBorrowedAssetData[i];
        }
    }

    struct WalletData {
        address asset;
        uint256 amount;
        uint256 amountNative;
        // uint256 currentPrice;
    }


    function getUserWalletData(
        address user,
        address addressesProvider)
    internal view returns (WalletData[] memory)
    {
        AssetMappings a = AssetMappings(ILendingPoolAddressesProvider(addressesProvider).getAssetMappings());

        address[] memory approvedTokens = a.getAllApprovedTokens();

        WalletData[] memory data = new WalletData[](approvedTokens.length);

        

        for (uint8 i = 0; i < approvedTokens.length; i++) {
            address assetOracle = ILendingPoolAddressesProvider(addressesProvider)
                .getPriceOracle();
            
            data[i] = WalletData ({
                asset: approvedTokens[i],
                amount: QueryAssetHelpers.convertAmountToUsd(
                    assetOracle,
                    approvedTokens[i],
                    IERC20(approvedTokens[i]).balanceOf(user),
                    IERC20Detailed(approvedTokens[i]).decimals()
                ),
                amountNative: IERC20(approvedTokens[i]).balanceOf(user)
                // currentPrice: IPriceOracleGetter(assetOracle).getAssetPrice(approvedTokens[i])
            });
            
        }

        return data;
    }

    function concatenateArrays(
        SuppliedAssetData[] memory arr1,
        SuppliedAssetData[] memory arr2)
    internal pure returns(SuppliedAssetData[] memory)
    {
        SuppliedAssetData[] memory returnArr =
            new SuppliedAssetData[](arr1.length + arr2.length);

        uint i = 0;
        for (; i < arr1.length; i++) {
            returnArr[i] = arr1[i];
        }

        uint j=0;
        while (j < arr2.length) {
            returnArr[i++] = arr2[j++];
        }

        return returnArr;
    }
    function concatenateArrays(
        BorrowedAssetData[] memory arr1,
        BorrowedAssetData[] memory arr2)
    internal pure returns(BorrowedAssetData[] memory)
    {
        BorrowedAssetData[] memory returnArr =
            new BorrowedAssetData[](arr1.length + arr2.length);

        uint i = 0;
        for (; i < arr1.length; i++) {
            returnArr[i] = arr1[i];
        }

        uint j=0;
        while (j < arr2.length) {
            returnArr[i++] = arr2[j++];
        }

        return returnArr;
    }
}

import { QueryTrancheHelpers } from "../libs/QueryTrancheHelpers.sol";
import { ILendingPoolAddressesProvider } from "../../interfaces/ILendingPoolAddressesProvider.sol";
import { LendingPoolConfigurator } from "../../protocol/lendingpool/LendingPoolConfigurator.sol";

//import "hardhat/console.sol";

contract GetAllTrancheData {

	constructor(address addressesProvider)
    {
        address configurator = ILendingPoolAddressesProvider(addressesProvider).getLendingPoolConfigurator();

        uint64 totalTranches = LendingPoolConfigurator(configurator).totalTranches();
        QueryTrancheHelpers.TrancheData[] memory allTrancheData = new QueryTrancheHelpers.TrancheData[](totalTranches);
        for(uint64 i = 0; i < totalTranches; i++) {
            allTrancheData[i] = QueryTrancheHelpers.getSingleTrancheData(i, addressesProvider);
        }
        bytes memory returnData = abi.encode(allTrancheData);

		assembly {
			return(add(0x20, returnData), mload(returnData))
		}
	}

	function getType() public view returns(QueryTrancheHelpers.TrancheData[] memory){}
}

import { QueryTrancheHelpers } from "../libs/QueryTrancheHelpers.sol";

//import "hardhat/console.sol";

contract GetTrancheData {
	constructor(
        address providerAddr,
        uint64 tranche)
    {

        QueryTrancheHelpers.TrancheData memory trancheData = QueryTrancheHelpers
            .getSingleTrancheData(
                tranche,
                providerAddr
            );
        bytes memory returnData = abi.encode(trancheData);

		assembly {
			return(add(0x20, returnData), mload(returnData))
		}
	}

	function getType() public view returns(QueryTrancheHelpers.TrancheData memory){}
}

import { QueryUserHelpers } from "../libs/QueryUserHelpers.sol";
import { LendingPoolConfigurator } from "../../protocol/lendingpool/LendingPoolConfigurator.sol";
import { ILendingPoolAddressesProvider } from "../../interfaces/ILendingPoolAddressesProvider.sol";

//import "hardhat/console.sol";

contract GetUserSummaryData {

	constructor(
        address providerAddr,
        address user)
    {
        QueryUserHelpers.UserSummaryData memory userSummaryData;
        uint64 totalTranches = LendingPoolConfigurator(
            ILendingPoolAddressesProvider(providerAddr).getLendingPoolConfigurator()
        ).totalTranches();

        for (uint64 i = 0; i < totalTranches; i++) {
            QueryUserHelpers.UserTrancheData memory userTrancheData =
                QueryUserHelpers.getUserTrancheData(user, i, providerAddr);
            userSummaryData.totalCollateralETH += userTrancheData.totalCollateralETH;
            userSummaryData.totalDebtETH += userTrancheData.totalDebtETH;
            userSummaryData.availableBorrowsETH += userTrancheData.availableBorrowsETH;
            userSummaryData.suppliedAssetData = QueryUserHelpers.concatenateArrays(
                userSummaryData.suppliedAssetData, userTrancheData.suppliedAssetData);
            userSummaryData.borrowedAssetData = QueryUserHelpers.concatenateArrays(
                userSummaryData.borrowedAssetData, userTrancheData.borrowedAssetData);
        }
	    bytes memory returnData = abi.encode(userSummaryData);
		assembly {
			return(add(0x20, returnData), mload(returnData))
		}
	}
	function getType() public view returns(QueryUserHelpers.UserSummaryData memory){}
}

import { QueryUserHelpers } from "../libs/QueryUserHelpers.sol";

//import "hardhat/console.sol";

contract GetUserTrancheData {
	constructor(
        address addressesProvider,
        address user,
        uint64 tranche)
    {
        QueryUserHelpers.UserTrancheData memory userData =
            QueryUserHelpers.getUserTrancheData(user, tranche, addressesProvider);
	    bytes memory returnData = abi.encode(userData);
		assembly {
			return(add(0x20, returnData), mload(returnData))
		}
	}
	function getType() public view returns(QueryUserHelpers.UserTrancheData memory){}
}

import { QueryUserHelpers } from "../libs/QueryUserHelpers.sol";

//import "hardhat/console.sol";

contract GetUserWalletData {
	constructor(
        address addressesProvider,
        address user)
    {
        QueryUserHelpers.WalletData[] memory userData =
            QueryUserHelpers.getUserWalletData(user, addressesProvider);

	    bytes memory returnData = abi.encode(userData);
		
		assembly {
			return(add(0x20, returnData), mload(returnData))
		}
	}
	function getType() public view returns(QueryUserHelpers.WalletData[] memory){}
}

// SPDX-License-Identifier: agpl-3.0
pragma solidity >=0.8.0;

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
        // According to EIP-1052, 0x0 is the value returned for not-yet created accounts
        // and 0xc5d2460186f7233c927e7db2dcc703c0e500b653ca82273b7bfad8045d85a470 is returned
        // for accounts without code, i.e. `keccak256('')`
        // bytes32 codehash;
        // bytes32 accountHash =
        //     0xc5d2460186f7233c927e7db2dcc703c0e500b653ca82273b7bfad8045d85a470;
        // // solhint-disable-next-line no-inline-assembly
        // assembly {
        //     codehash := extcodehash(account)
        // }
        // return (codehash != accountHash && codehash != 0x0);
        return account.code.length > 0; //updated
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
        require(
            address(this).balance >= amount,
            "Address: insufficient balance"
        );

        // solhint-disable-next-line avoid-low-level-calls, avoid-call-value
        (bool success, ) = recipient.call{value: amount}("");
        require(
            success,
            "Address: unable to send value, recipient may have reverted"
        );
    }
}

// SPDX-License-Identifier: MIT
pragma solidity >=0.8.0;

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
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes memory) {
        this; // silence state mutability warning without generating bytecode - see https://github.com/ethereum/solidity/issues/2691
        return msg.data;
    }
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.8.0;

import "./Context.sol";
import "./IERC20.sol";
import "./SafeMath.sol";
import "./Address.sol";

/**
 * @dev Implementation of the {IERC20} interface.
 *
 * This implementation is agnostic to the way tokens are created. This means
 * that a supply mechanism has to be added in a derived contract using {_mint}.
 * For a generic mechanism see {ERC20PresetMinterPauser}.
 *
 * TIP: For a detailed writeup see our guide
 * https://forum.zeppelin.solutions/t/how-to-implement-erc20-supply-mechanisms/226[How
 * to implement supply mechanisms].
 *
 * We have followed general OpenZeppelin guidelines: functions revert instead
 * of returning `false` on failure. This behavior is nonetheless conventional
 * and does not conflict with the expectations of ERC20 applications.
 *
 * Additionally, an {Approval} event is emitted on calls to {transferFrom}.
 * This allows applications to reconstruct the allowance for all accounts just
 * by listening to said events. Other implementations of the EIP may not emit
 * these events, as it isn't required by the specification.
 *
 * Finally, the non-standard {decreaseAllowance} and {increaseAllowance}
 * functions have been added to mitigate the well-known issues around setting
 * allowances. See {IERC20-approve}.
 */
contract ERC20 is Context, IERC20 {
    using SafeMath for uint256;
    using Address for address;

    mapping(address => uint256) private _balances;

    mapping(address => mapping(address => uint256)) private _allowances;

    uint256 private _totalSupply;

    string private _name;
    string private _symbol;
    uint8 private _decimals;

    /**
     * @dev Sets the values for {name} and {symbol}, initializes {decimals} with
     * a default value of 18.
     *
     * To select a different value for {decimals}, use {_setupDecimals}.
     *
     * All three of these values are immutable: they can only be set once during
     * construction.
     */
    constructor(string memory name, string memory symbol) public {
        _name = name;
        _symbol = symbol;
        _decimals = 18;
    }

    /**
     * @dev Returns the name of the token.
     */
    function name() public view returns (string memory) {
        return _name;
    }

    /**
     * @dev Returns the symbol of the token, usually a shorter version of the
     * name.
     */
    function symbol() public view returns (string memory) {
        return _symbol;
    }

    /**
     * @dev Returns the number of decimals used to get its user representation.
     * For example, if `decimals` equals `2`, a balance of `505` tokens should
     * be displayed to a user as `5,05` (`505 / 10 ** 2`).
     *
     * Tokens usually opt for a value of 18, imitating the relationship between
     * Ether and Wei. This is the value {ERC20} uses, unless {_setupDecimals} is
     * called.
     *
     * NOTE: This information is only used for _display_ purposes: it in
     * no way affects any of the arithmetic of the contract, including
     * {IERC20-balanceOf} and {IERC20-transfer}.
     */
    function decimals() public view returns (uint8) {
        return _decimals;
    }

    /**
     * @dev See {IERC20-totalSupply}.
     */
    function totalSupply() public view override returns (uint256) {
        return _totalSupply;
    }

    /**
     * @dev See {IERC20-balanceOf}.
     */
    function balanceOf(address account) public view override returns (uint256) {
        return _balances[account];
    }

    /**
     * @dev See {IERC20-transfer}.
     *
     * Requirements:
     *
     * - `recipient` cannot be the zero address.
     * - the caller must have a balance of at least `amount`.
     */
    function transfer(address recipient, uint256 amount)
        public
        virtual
        override
        returns (bool)
    {
        _transfer(_msgSender(), recipient, amount);
        return true;
    }

    /**
     * @dev See {IERC20-allowance}.
     */
    function allowance(address owner, address spender)
        public
        view
        virtual
        override
        returns (uint256)
    {
        return _allowances[owner][spender];
    }

    /**
     * @dev See {IERC20-approve}.
     *
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     */
    function approve(address spender, uint256 amount)
        public
        virtual
        override
        returns (bool)
    {
        _approve(_msgSender(), spender, amount);
        return true;
    }

    /**
     * @dev See {IERC20-transferFrom}.
     *
     * Emits an {Approval} event indicating the updated allowance. This is not
     * required by the EIP. See the note at the beginning of {ERC20};
     *
     * Requirements:
     * - `sender` and `recipient` cannot be the zero address.
     * - `sender` must have a balance of at least `amount`.
     * - the caller must have allowance for ``sender``'s tokens of at least
     * `amount`.
     */
    function transferFrom(
        address sender,
        address recipient,
        uint256 amount
    ) public virtual override returns (bool) {
        _transfer(sender, recipient, amount);
        _approve(
            sender,
            _msgSender(),
            _allowances[sender][_msgSender()].sub(
                amount,
                "ERC20: transfer amount exceeds allowance"
            )
        );
        return true;
    }

    /**
     * @dev Atomically increases the allowance granted to `spender` by the caller.
     *
     * This is an alternative to {approve} that can be used as a mitigation for
     * problems described in {IERC20-approve}.
     *
     * Emits an {Approval} event indicating the updated allowance.
     *
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     */
    function increaseAllowance(address spender, uint256 addedValue)
        public
        virtual
        returns (bool)
    {
        _approve(
            _msgSender(),
            spender,
            _allowances[_msgSender()][spender].add(addedValue)
        );
        return true;
    }

    /**
     * @dev Atomically decreases the allowance granted to `spender` by the caller.
     *
     * This is an alternative to {approve} that can be used as a mitigation for
     * problems described in {IERC20-approve}.
     *
     * Emits an {Approval} event indicating the updated allowance.
     *
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     * - `spender` must have allowance for the caller of at least
     * `subtractedValue`.
     */
    function decreaseAllowance(address spender, uint256 subtractedValue)
        public
        virtual
        returns (bool)
    {
        _approve(
            _msgSender(),
            spender,
            _allowances[_msgSender()][spender].sub(
                subtractedValue,
                "ERC20: decreased allowance below zero"
            )
        );
        return true;
    }

    /**
     * @dev Moves tokens `amount` from `sender` to `recipient`.
     *
     * This is internal function is equivalent to {transfer}, and can be used to
     * e.g. implement automatic token fees, slashing mechanisms, etc.
     *
     * Emits a {Transfer} event.
     *
     * Requirements:
     *
     * - `sender` cannot be the zero address.
     * - `recipient` cannot be the zero address.
     * - `sender` must have a balance of at least `amount`.
     */
    function _transfer(
        address sender,
        address recipient,
        uint256 amount
    ) internal virtual {
        require(sender != address(0), "ERC20: transfer from the zero address");
        require(recipient != address(0), "ERC20: transfer to the zero address");

        _beforeTokenTransfer(sender, recipient, amount);

        _balances[sender] = _balances[sender].sub(
            amount,
            "ERC20: transfer amount exceeds balance"
        );
        _balances[recipient] = _balances[recipient].add(amount);
        emit Transfer(sender, recipient, amount);
    }

    /** @dev Creates `amount` tokens and assigns them to `account`, increasing
     * the total supply.
     *
     * Emits a {Transfer} event with `from` set to the zero address.
     *
     * Requirements
     *
     * - `to` cannot be the zero address.
     */
    function _mint(address account, uint256 amount) internal virtual {
        require(account != address(0), "ERC20: mint to the zero address");

        _beforeTokenTransfer(address(0), account, amount);

        _totalSupply = _totalSupply.add(amount);
        _balances[account] = _balances[account].add(amount);
        emit Transfer(address(0), account, amount);
    }

    /**
     * @dev Destroys `amount` tokens from `account`, reducing the
     * total supply.
     *
     * Emits a {Transfer} event with `to` set to the zero address.
     *
     * Requirements
     *
     * - `account` cannot be the zero address.
     * - `account` must have at least `amount` tokens.
     */
    function _burn(address account, uint256 amount) internal virtual {
        require(account != address(0), "ERC20: burn from the zero address");

        _beforeTokenTransfer(account, address(0), amount);

        _balances[account] = _balances[account].sub(
            amount,
            "ERC20: burn amount exceeds balance"
        );
        _totalSupply = _totalSupply.sub(amount);
        emit Transfer(account, address(0), amount);
    }

    /**
     * @dev Sets `amount` as the allowance of `spender` over the `owner`s tokens.
     *
     * This is internal function is equivalent to `approve`, and can be used to
     * e.g. set automatic allowances for certain subsystems, etc.
     *
     * Emits an {Approval} event.
     *
     * Requirements:
     *
     * - `owner` cannot be the zero address.
     * - `spender` cannot be the zero address.
     */
    function _approve(
        address owner,
        address spender,
        uint256 amount
    ) internal virtual {
        require(owner != address(0), "ERC20: approve from the zero address");
        require(spender != address(0), "ERC20: approve to the zero address");

        _allowances[owner][spender] = amount;
        emit Approval(owner, spender, amount);
    }

    /**
     * @dev Sets {decimals} to a value other than the default one of 18.
     *
     * WARNING: This function should only be called from the constructor. Most
     * applications that interact with token contracts will not expect
     * {decimals} to ever change, and may work incorrectly if it does.
     */
    function _setupDecimals(uint8 decimals_) internal {
        _decimals = decimals_;
    }

    /**
     * @dev Hook that is called before any transfer of tokens. This includes
     * minting and burning.
     *
     * Calling conditions:
     *
     * - when `from` and `to` are both non-zero, `amount` of ``from``'s tokens
     * will be to transferred to `to`.
     * - when `from` is zero, `amount` tokens will be minted for `to`.
     * - when `to` is zero, `amount` of ``from``'s tokens will be burned.
     * - `from` and `to` are never both zero.
     *
     * To learn more about hooks, head to xref:ROOT:extending-contracts.adoc#using-hooks[Using Hooks].
     */
    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 amount
    ) internal virtual {}
}

// SPDX-License-Identifier: agpl-3.0
pragma solidity >=0.8.0;

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
    function transfer(address recipient, uint256 amount)
        external
        returns (bool);

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
    event Approval(
        address indexed owner,
        address indexed spender,
        uint256 value
    );
}

// SPDX-License-Identifier: agpl-3.0
pragma solidity >=0.8.0;

import {IERC20} from "./IERC20.sol";

interface IERC20Detailed is IERC20 {
    function name() external view returns (string memory);

    function symbol() external view returns (string memory);

    function decimals() external view returns (uint8);
}

// SPDX-License-Identifier: MIT
pragma solidity >=0.8.0;

import "./Context.sol";

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
contract Ownable is Context {
    address private _owner;

    event OwnershipTransferred(
        address indexed previousOwner,
        address indexed newOwner
    );

    /**
     * @dev Initializes the contract setting the deployer as the initial owner.
     */
    constructor() {
        address msgSender = _msgSender();
        _owner = msgSender;
        emit OwnershipTransferred(address(0), msgSender);
    }

    /**
     * @dev Returns the address of the current owner.
     */
    function owner() public view returns (address) {
        return _owner;
    }

    /**
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        require(_owner == _msgSender(), "Ownable: caller is not the owner");
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
        require(
            newOwner != address(0),
            "Ownable: new owner is the zero address"
        );
        emit OwnershipTransferred(_owner, newOwner);
        _owner = newOwner;
    }
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

    constructor() internal {
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

pragma solidity >=0.8.0;

import {IERC20} from "./IERC20.sol";
import {SafeMath} from "./SafeMath.sol";
import {Address} from "./Address.sol";

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

    function safeTransfer(
        IERC20 token,
        address to,
        uint256 value
    ) internal {
        callOptionalReturn(
            token,
            abi.encodeWithSelector(token.transfer.selector, to, value)
        );
    }

    function safeTransferFrom(
        IERC20 token,
        address from,
        address to,
        uint256 value
    ) internal {
        callOptionalReturn(
            token,
            abi.encodeWithSelector(token.transferFrom.selector, from, to, value)
        );
    }

    function safeApprove(
        IERC20 token,
        address spender,
        uint256 value
    ) internal {
        require(
            (value == 0) || (token.allowance(address(this), spender) == 0),
            "SafeERC20: approve from non-zero to non-zero allowance"
        );
        callOptionalReturn(
            token,
            abi.encodeWithSelector(token.approve.selector, spender, value)
        );
    }

    function callOptionalReturn(IERC20 token, bytes memory data) private {
        require(address(token).isContract(), "SafeERC20: call to non-contract");

        // solhint-disable-next-line avoid-low-level-calls
        (bool success, bytes memory returndata) = address(token).call(data);
        require(success, "SafeERC20: low-level call failed");

        if (returndata.length > 0) {
            // Return data is optional
            // solhint-disable-next-line max-line-length
            require(
                abi.decode(returndata, (bool)),
                "SafeERC20: ERC20 operation did not succeed"
            );
        }
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.6.0) (utils/math/SafeMath.sol)

pragma solidity ^0.8.0;

// CAUTION
// This version of SafeMath should only be used with Solidity 0.8 or later,
// because it relies on the compiler's built in overflow checks.

/**
 * @dev Wrappers over Solidity's arithmetic operations.
 *
 * NOTE: `SafeMath` is generally not needed starting with Solidity 0.8, since the compiler
 * now has built in overflow checking.
 */
library SafeMath {
    /**
     * @dev Returns the addition of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function tryAdd(uint256 a, uint256 b)
        internal
        pure
        returns (bool, uint256)
    {
        unchecked {
            uint256 c = a + b;
            if (c < a) return (false, 0);
            return (true, c);
        }
    }

    /**
     * @dev Returns the subtraction of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function trySub(uint256 a, uint256 b)
        internal
        pure
        returns (bool, uint256)
    {
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
    function tryMul(uint256 a, uint256 b)
        internal
        pure
        returns (bool, uint256)
    {
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
    function tryDiv(uint256 a, uint256 b)
        internal
        pure
        returns (bool, uint256)
    {
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
    function tryMod(uint256 a, uint256 b)
        internal
        pure
        returns (bool, uint256)
    {
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
// OpenZeppelin Contracts (last updated v4.7.0) (utils/Strings.sol)

pragma solidity ^0.8.0;

/**
 * @dev String operations.
 */
library Strings {
    bytes16 private constant _HEX_SYMBOLS = "0123456789abcdef";
    uint8 private constant _ADDRESS_LENGTH = 20;

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
    function toHexString(uint256 value, uint256 length)
        internal
        pure
        returns (string memory)
    {
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

    /**
     * @dev Converts an `address` with fixed length of 20 bytes to its not checksummed ASCII `string` hexadecimal representation.
     */
    function toHexString(address addr) internal pure returns (string memory) {
        return toHexString(uint256(uint160(addr)), _ADDRESS_LENGTH);
    }
}

// SPDX-License-Identifier: agpl-3.0
pragma solidity >=0.8.0;

import "./Proxy.sol";
import "../contracts/Address.sol";

/**
 * @title BaseUpgradeabilityProxy
 * @dev This contract implements a proxy that allows to change the
 * implementation address to which it will delegate.
 * Such a change is called an implementation upgrade.
 */
contract BaseUpgradeabilityProxy is Proxy {
    /**
     * @dev Emitted when the implementation is upgraded.
     * @param implementation Address of the new implementation.
     */
    event Upgraded(address indexed implementation);

    /**
     * @dev Storage slot with the address of the current implementation.
     * This is the keccak-256 hash of "eip1967.proxy.implementation" subtracted by 1, and is
     * validated in the constructor.
     */
    bytes32 internal constant IMPLEMENTATION_SLOT =
        0x360894a13ba1a3210667c828492db98dca3e2076cc3735a920a3ca505d382bbc;

    /**
     * @dev Returns the current implementation.
     * @return impl Address of the current implementation
     */
    function _implementation() internal view override returns (address impl) {
        bytes32 slot = IMPLEMENTATION_SLOT;
        //solium-disable-next-line
        assembly {
            impl := sload(slot)
        }
    }

    /**
     * @dev Upgrades the proxy to a new implementation.
     * @param newImplementation Address of the new implementation.
     */
    function _upgradeTo(address newImplementation) internal {
        _setImplementation(newImplementation);
        emit Upgraded(newImplementation);
    }

    /**
     * @dev Sets the implementation address of the proxy.
     * @param newImplementation Address of the new implementation.
     */
    function _setImplementation(address newImplementation) internal {
        require(
            Address.isContract(newImplementation),
            "Cannot set a proxy implementation to a non-contract address"
        );

        bytes32 slot = IMPLEMENTATION_SLOT;

        //solium-disable-next-line
        assembly {
            sstore(slot, newImplementation)
        }
    }
}

// SPDX-License-Identifier: agpl-3.0
pragma solidity >=0.8.0;

/**
 * @title Initializable
 *
 * @dev Helper contract to support initializer functions. To use it, replace
 * the constructor with a function that has the `initializer` modifier.
 * WARNING: Unlike constructors, initializer functions must be manually
 * invoked. This applies both to deploying an Initializable contract, as well
 * as extending an Initializable contract via inheritance.
 * WARNING: When used with inheritance, manual care must be taken to not invoke
 * a parent initializer twice, or ensure that all initializers are idempotent,
 * because this is not dealt with automatically as with constructors.
 */
contract Initializable {
    /**
     * @dev Indicates that the contract has been initialized.
     */
    bool private initialized;

    /**
     * @dev Indicates that the contract is in the process of being initialized.
     */
    bool private initializing;

    /**
     * @dev Modifier to use in the initializer function of a contract.
     */
    modifier initializer() {
        require(
            initializing || isConstructor() || !initialized,
            "Contract instance has already been initialized"
        );

        bool isTopLevelCall = !initializing;
        if (isTopLevelCall) {
            initializing = true;
            initialized = true;
        }

        _;

        if (isTopLevelCall) {
            initializing = false;
        }
    }

    /// @dev Returns true if and only if the function is running in the constructor
    function isConstructor() private view returns (bool) {
        // extcodesize checks the size of the code stored in an address, and
        // address returns the current address. Since the code is still not
        // deployed when running a constructor, any checks on its code size will
        // yield zero, making it an effective way to detect if a contract is
        // under construction or not.
        uint256 cs;
        //solium-disable-next-line
        assembly {
            cs := extcodesize(address())
        }
        return cs == 0;
    }

    // Reserved storage space to allow for layout changes in the future.
    uint256[50] private ______gap;
}

// SPDX-License-Identifier: agpl-3.0
pragma solidity >=0.8.0;

import "./BaseUpgradeabilityProxy.sol";

/**
 * @title InitializableUpgradeabilityProxy
 * @dev Extends BaseUpgradeabilityProxy with an initializer for initializing
 * implementation and init data.
 */
contract InitializableUpgradeabilityProxy is BaseUpgradeabilityProxy {
    /**
     * @dev Contract initializer.
     * @param _logic Address of the initial implementation.
     * @param _data Data to send as msg.data to the implementation to initialize the proxied contract.
     * It should include the signature and the parameters of the function to be called, as described in
     * https://solidity.readthedocs.io/en/v0.4.24/abi-spec.html#function-selector-and-argument-encoding.
     * This parameter is optional, if no data is given the initialization call to proxied contract will be skipped.
     */
    function initialize(address _logic, bytes memory _data) public payable {
        require(_implementation() == address(0));
        assert(
            IMPLEMENTATION_SLOT ==
                bytes32(uint256(keccak256("eip1967.proxy.implementation")) - 1)
        );
        _setImplementation(_logic);
        if (_data.length > 0) {
            (bool success, ) = _logic.delegatecall(_data);
            require(success);
        }
    }
}

// SPDX-License-Identifier: agpl-3.0
pragma solidity >=0.8.0;

/**
 * @title Proxy
 * @dev Implements delegation of calls to other contracts, with proper
 * forwarding of return values and bubbling of failures.
 * It defines a fallback function that delegates all calls to the address
 * returned by the abstract _implementation() internal function.
 */
abstract contract Proxy {
    /**
     * @dev Fallback function.
     * Implemented entirely in `_fallback`.
     */
    fallback() external payable {
        _fallback();
    }

    /**
     * @return The Address of the implementation.
     */
    function _implementation() internal view virtual returns (address);

    /**
     * @dev Delegates execution to an implementation contract.
     * This is a low level function that doesn't return to its internal call site.
     * It will return to the external caller whatever the implementation returns.
     * @param implementation Address to delegate.
     */
    function _delegate(address implementation) internal {
        //solium-disable-next-line
        assembly {
            // Copy msg.data. We take full control of memory in this inline assembly
            // block because it will not return to Solidity code. We overwrite the
            // Solidity scratch pad at memory position 0.
            calldatacopy(0, 0, calldatasize())

            // Call the implementation.
            // out and outsize are 0 because we don't know the size yet.
            let result := delegatecall(
                gas(),
                implementation,
                0,
                calldatasize(),
                0,
                0
            )

            // Copy the returned data.
            returndatacopy(0, 0, returndatasize())

            switch result
                // delegatecall returns 0 on error.
                case 0 {
                    revert(0, returndatasize())
                }
                default {
                    return(0, returndatasize())
                }
        }
    }

    /**
     * @dev Function that is run as the first thing in the fallback function.
     * Can be redefined in derived contracts to add functionality.
     * Redefinitions must call super._willFallback().
     */
    function _willFallback() internal virtual {}

    /**
     * @dev fallback implementation.
     * Extracted to enable manual triggering.
     */
    function _fallback() internal {
        _willFallback();
        _delegate(_implementation());
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (utils/Address.sol)

pragma solidity ^0.8.0;

/**
 * @dev Collection of functions related to the address type
 */
library AddressUpgradeable {
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
     * https://consensys.net/diligence/blog/2019/09/stop-using-soliditys-transfer-now/[Learn more].
     *
     * IMPORTANT: because control is transferred to `recipient`, care must be
     * taken to not create reentrancy vulnerabilities. Consider using
     * {ReentrancyGuard} or the
     * https://solidity.readthedocs.io/en/v0.5.11/security-considerations.html#use-the-checks-effects-interactions-pattern[checks-effects-interactions pattern].
     */
    function sendValue(address payable recipient, uint256 amount) internal {
        require(
            address(this).balance >= amount,
            "Address: insufficient balance"
        );

        (bool success, ) = recipient.call{value: amount}("");
        require(
            success,
            "Address: unable to send value, recipient may have reverted"
        );
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
    function functionCall(address target, bytes memory data)
        internal
        returns (bytes memory)
    {
        return
            functionCallWithValue(
                target,
                data,
                0,
                "Address: low-level call failed"
            );
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
        return
            functionCallWithValue(
                target,
                data,
                value,
                "Address: low-level call with value failed"
            );
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
        require(
            address(this).balance >= value,
            "Address: insufficient balance for call"
        );
        (bool success, bytes memory returndata) = target.call{value: value}(
            data
        );
        return
            verifyCallResultFromTarget(
                target,
                success,
                returndata,
                errorMessage
            );
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
     * but performing a static call.
     *
     * _Available since v3.3._
     */
    function functionStaticCall(address target, bytes memory data)
        internal
        view
        returns (bytes memory)
    {
        return
            functionStaticCall(
                target,
                data,
                "Address: low-level static call failed"
            );
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
        return
            verifyCallResultFromTarget(
                target,
                success,
                returndata,
                errorMessage
            );
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

    function _revert(bytes memory returndata, string memory errorMessage)
        private
        pure
    {
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
import "./Initializable.sol";

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
    function __Context_init() internal onlyInitializing {}

    function __Context_init_unchained() internal onlyInitializing {}

    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes calldata) {
        return msg.data;
    }

    /**
     * @dev This empty reserved space is put in place to allow future versions to add new
     * variables without shifting down storage in the inheritance chain.
     * See https://docs.openzeppelin.com/contracts/4.x/upgradeable#storage_gaps
     */
    uint256[50] private __gap;
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (proxy/utils/Initializable.sol)

pragma solidity ^0.8.0;

import "./AddressUpgradeable.sol";

abstract contract Initializable {
    uint8 private _initialized;

    /**
     * @dev Indicates that the contract is in the process of being initialized.
     */
    bool private _initializing;

    /**
     * @dev Triggered when the contract has been initialized or reinitialized.
     */
    event Initialized(uint8 version);

    /**
     * @dev A modifier that defines a protected initializer function that can be invoked at most once. In its scope,
     * `onlyInitializing` functions can be used to initialize parent contracts.
     *
     * Similar to `reinitializer(1)`, except that functions marked with `initializer` can be nested in the context of a
     * constructor.
     *
     * Emits an {Initialized} event.
     */
    modifier initializer() {
        bool isTopLevelCall = !_initializing;
        require(
            (isTopLevelCall && _initialized < 1) ||
                (!AddressUpgradeable.isContract(address(this)) &&
                    _initialized == 1),
            "Initializable: contract is already initialized"
        );
        _initialized = 1;
        if (isTopLevelCall) {
            _initializing = true;
        }
        _;
        if (isTopLevelCall) {
            _initializing = false;
            emit Initialized(1);
        }
    }

    /**
     * @dev A modifier that defines a protected reinitializer function that can be invoked at most once, and only if the
     * contract hasn't been initialized to a greater version before. In its scope, `onlyInitializing` functions can be
     * used to initialize parent contracts.
     *
     * A reinitializer may be used after the original initialization step. This is essential to configure modules that
     * are added through upgrades and that require initialization.
     *
     * When `version` is 1, this modifier is similar to `initializer`, except that functions marked with `reinitializer`
     * cannot be nested. If one is invoked in the context of another, execution will revert.
     *
     * Note that versions can jump in increments greater than 1; this implies that if multiple reinitializers coexist in
     * a contract, executing them in the right order is up to the developer or operator.
     *
     * WARNING: setting the version to 255 will prevent any future reinitialization.
     *
     * Emits an {Initialized} event.
     */
    modifier reinitializer(uint8 version) {
        require(
            !_initializing && _initialized < version,
            "Initializable: contract is already initialized"
        );
        _initialized = version;
        _initializing = true;
        _;
        _initializing = false;
        emit Initialized(version);
    }

    /**
     * @dev Modifier to protect an initialization function so that it can only be invoked by functions with the
     * {initializer} and {reinitializer} modifiers, directly or indirectly.
     */
    modifier onlyInitializing() {
        require(_initializing, "Initializable: contract is not initializing");
        _;
    }

    /**
     * @dev Locks the contract, preventing any future reinitialization. This cannot be part of an initializer call.
     * Calling this in the constructor of a contract will prevent that contract from being initialized or reinitialized
     * to any version. It is recommended to use this to lock implementation contracts that are designed to be called
     * through proxies.
     *
     * Emits an {Initialized} event the first time it is successfully executed.
     */
    function _disableInitializers() internal virtual {
        require(!_initializing, "Initializable: contract is initializing");
        if (_initialized < type(uint8).max) {
            _initialized = type(uint8).max;
            emit Initialized(type(uint8).max);
        }
    }

    /**
     * @dev Internal function that returns the initialized version. Returns `_initialized`
     */
    function _getInitializedVersion() internal view returns (uint8) {
        return _initialized;
    }

    /**
     * @dev Internal function that returns the initialized version. Returns `_initializing`
     */
    function _isInitializing() internal view returns (bool) {
        return _initializing;
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (security/Pausable.sol)

pragma solidity ^0.8.0;

import "./ContextUpgradeable.sol";
import "./Initializable.sol";

/**
 * @dev Contract module which allows children to implement an emergency stop
 * mechanism that can be triggered by an authorized account.
 *
 * This module is used through inheritance. It will make available the
 * modifiers `whenNotPaused` and `whenPaused`, which can be applied to
 * the functions of your contract. Note that they will not be pausable by
 * simply including this module, only once the modifiers are put in place.
 */
abstract contract PausableUpgradeable is Initializable, ContextUpgradeable {
    /**
     * @dev Emitted when the pause is triggered by `account`.
     */
    event Paused(address account);

    /**
     * @dev Emitted when the pause is lifted by `account`.
     */
    event Unpaused(address account);

    bool private _paused;

    /**
     * @dev Initializes the contract in unpaused state.
     */
    function __Pausable_init() internal onlyInitializing {
        __Pausable_init_unchained();
    }

    function __Pausable_init_unchained() internal onlyInitializing {
        _paused = false;
    }

    /**
     * @dev Modifier to make a function callable only when the contract is not paused.
     *
     * Requirements:
     *
     * - The contract must not be paused.
     */
    modifier whenNotPaused() {
        _requireNotPaused();
        _;
    }

    /**
     * @dev Modifier to make a function callable only when the contract is paused.
     *
     * Requirements:
     *
     * - The contract must be paused.
     */
    modifier whenPaused() {
        _requirePaused();
        _;
    }

    /**
     * @dev Returns true if the contract is paused, and false otherwise.
     */
    function paused() public view virtual returns (bool) {
        return _paused;
    }

    /**
     * @dev Throws if the contract is paused.
     */
    function _requireNotPaused() internal view virtual {
        require(!paused(), "Pausable: paused");
    }

    /**
     * @dev Throws if the contract is not paused.
     */
    function _requirePaused() internal view virtual {
        require(paused(), "Pausable: not paused");
    }

    /**
     * @dev Triggers stopped state.
     *
     * Requirements:
     *
     * - The contract must not be paused.
     */
    function _pause() internal virtual whenNotPaused {
        _paused = true;
        emit Paused(_msgSender());
    }

    /**
     * @dev Returns to normal state.
     *
     * Requirements:
     *
     * - The contract must be paused.
     */
    function _unpause() internal virtual whenPaused {
        _paused = false;
        emit Unpaused(_msgSender());
    }

    /**
     * @dev This empty reserved space is put in place to allow future versions to add new
     * variables without shifting down storage in the inheritance chain.
     * See https://docs.openzeppelin.com/contracts/4.x/upgradeable#storage_gaps
     */
    uint256[49] private __gap;
}

// SPDX-License-Identifier: agpl-3.0
pragma solidity >=0.8.0;

import {SafeMath} from "../../dependencies/openzeppelin/contracts/SafeMath.sol";
import {IERC20} from "../../dependencies/openzeppelin/contracts/IERC20.sol";
import {
    SafeERC20
} from "../../dependencies/openzeppelin/contracts/SafeERC20.sol";
import {IFlashLoanReceiver} from "../interfaces/IFlashLoanReceiver.sol";
import {
    ILendingPoolAddressesProvider
} from "../../interfaces/ILendingPoolAddressesProvider.sol";
import {ILendingPool} from "../../interfaces/ILendingPool.sol";

abstract contract FlashLoanReceiverBase is IFlashLoanReceiver {
    using SafeERC20 for IERC20;
    using SafeMath for uint256;

    ILendingPoolAddressesProvider public immutable override ADDRESSES_PROVIDER;
    ILendingPool public immutable override LENDING_POOL;

    constructor(ILendingPoolAddressesProvider provider) {
        ADDRESSES_PROVIDER = provider;
        LENDING_POOL = ILendingPool(provider.getLendingPool());
    }
}

// SPDX-License-Identifier: agpl-3.0
pragma solidity >=0.8.0;

import {ILendingPoolAddressesProvider} from "../../interfaces/ILendingPoolAddressesProvider.sol";
import {ILendingPool} from "../../interfaces/ILendingPool.sol";
import {DataTypes} from "../../protocol/libraries/types/DataTypes.sol";

/**
 * @title IFlashLoanReceiver interface
 * @notice Interface for the Aave fee IFlashLoanReceiver.
 * @author Aave
 * @dev implement this interface to develop a flashloan-compatible flashLoanReceiver contract
 **/
interface IFlashLoanReceiver {
    function executeOperation(
        address[] calldata assets,
        uint256[] calldata amounts,
        uint256[] calldata premiums,
        address initiator,
        bytes calldata params
    ) external returns (bool);

    function ADDRESSES_PROVIDER()
        external
        view
        returns (ILendingPoolAddressesProvider);

    function LENDING_POOL() external view returns (ILendingPool);
}

// SPDX-License-Identifier: agpl-3.0
pragma solidity >=0.8.0;

interface IAaveIncentivesController {
    event RewardsAccrued(address indexed user, uint256 amount);

    event RewardsClaimed(
        address indexed user,
        address indexed to,
        uint256 amount
    );

    event RewardsClaimed(
        address indexed user,
        address indexed to,
        address indexed claimer,
        uint256 amount
    );

    event ClaimerSet(address indexed user, address indexed claimer);

    /*
     * @dev Returns the configuration of the distribution for a certain asset
     * @param asset The address of the reference asset of the distribution
     * @return The asset index, the emission per second and the last updated timestamp
     **/
    function getAssetData(address asset)
        external
        view
        returns (
            uint256,
            uint256,
            uint256
        );

    /*
     * LEGACY **************************
     * @dev Returns the configuration of the distribution for a certain asset
     * @param asset The address of the reference asset of the distribution
     * @return The asset index, the emission per second and the last updated timestamp
     **/
    function assets(address asset)
        external
        view
        returns (
            uint128,
            uint128,
            uint256
        );

    /**
     * @dev Whitelists an address to claim the rewards on behalf of another address
     * @param user The address of the user
     * @param claimer The address of the claimer
     */
    function setClaimer(address user, address claimer) external;

    /**
     * @dev Returns the whitelisted claimer for a certain address (0x0 if not set)
     * @param user The address of the user
     * @return The claimer address
     */
    function getClaimer(address user) external view returns (address);

    /**
     * @dev Configure assets for a certain rewards emission
     * @param assets The assets to incentivize
     * @param emissionsPerSecond The emission for each asset
     */
    function configureAssets(
        address[] calldata assets,
        uint256[] calldata emissionsPerSecond
    ) external;

    /**
     * @dev Called by the corresponding asset on any update that affects the rewards distribution
     * @param asset The address of the user
     * @param userBalance The balance of the user of the asset in the lending pool
     * @param totalSupply The total supply of the asset in the lending pool
     **/
    function handleAction(
        address asset,
        uint256 userBalance,
        uint256 totalSupply
    ) external;

    /**
     * @dev Returns the total of rewards of an user, already accrued + not yet accrued
     * @param user The address of the user
     * @return The rewards
     **/
    function getRewardsBalance(address[] calldata assets, address user)
        external
        view
        returns (uint256);

    /**
     * @dev Claims reward for an user, on all the assets of the lending pool, accumulating the pending rewards
     * @param amount Amount of rewards to claim
     * @param to Address that will be receiving the rewards
     * @return Rewards claimed
     **/
    function claimRewards(
        address[] calldata assets,
        uint256 amount,
        address to
    ) external returns (uint256);

    /**
     * @dev Claims reward for an user on behalf, on all the assets of the lending pool, accumulating the pending rewards. The caller must
     * be whitelisted via "allowClaimOnBehalf" function by the RewardsAdmin role manager
     * @param amount Amount of rewards to claim
     * @param user Address to check and claim rewards
     * @param to Address that will be receiving the rewards
     * @return Rewards claimed
     **/
    function claimRewardsOnBehalf(
        address[] calldata assets,
        uint256 amount,
        address user,
        address to
    ) external returns (uint256);

    /**
     * @dev returns the unclaimed rewards of the user
     * @param user the address of the user
     * @return the unclaimed user rewards
     */
    function getUserUnclaimedRewards(address user)
        external
        view
        returns (uint256);

    /**
     * @dev returns the unclaimed rewards of the user
     * @param user the address of the user
     * @param asset The asset to incentivize
     * @return the user index for the asset
     */
    function getUserAssetData(address user, address asset)
        external
        view
        returns (uint256);

    /**
     * @dev for backward compatibility with previous implementation of the Incentives controller
     */
    function REWARD_TOKEN() external view returns (address);

    /**
     * @dev for backward compatibility with previous implementation of the Incentives controller
     */
    function PRECISION() external view returns (uint8);

    /**
     * @dev Gets the distribution end timestamp of the emissions
     */
    function DISTRIBUTION_END() external view returns (uint256);
}

// SPDX-License-Identifier: agpl-3.0
pragma solidity >=0.8.0;

import {IERC20} from "../dependencies/openzeppelin/contracts/IERC20.sol";
import {IScaledBalanceToken} from "./IScaledBalanceToken.sol";
import {IInitializableAToken} from "./IInitializableAToken.sol";
import {IAaveIncentivesController} from "./IAaveIncentivesController.sol";
import {DataTypes} from "../protocol/libraries/types/DataTypes.sol";

interface IAToken is IERC20, IScaledBalanceToken, IInitializableAToken {
    /**
     * @dev Emitted after the mint action
     * @param from The address performing the mint
     * @param value The amount being
     * @param index The new liquidity index of the reserve
     **/
    event Mint(address indexed from, uint256 value, uint256 index);

    /**
     * @dev Mints `amount` aTokens to `user`
     * @param user The address receiving the minted tokens
     * @param amount The amount of tokens getting minted
     * @param index The new liquidity index of the reserve
     * @return `true` if the the previous balance of the user was 0
     */
    function mint(
        address user,
        uint256 amount,
        uint256 index
    ) external returns (bool);

    function setTreasury(address newTreasury) external;

    function setVMEXTreasury(address newTreasury) external;

    /**
     * @dev Emitted after aTokens are burned
     * @param from The owner of the aTokens, getting them burned
     * @param target The address that will receive the underlying
     * @param value The amount being burned
     * @param index The new liquidity index of the reserve
     **/
    event Burn(
        address indexed from,
        address indexed target,
        uint256 value,
        uint256 index
    );

    event TreasuryChanged(address indexed newAddress);

    event VMEXTreasuryChanged(address indexed newAddress);

    /**
     * @dev Emitted during the transfer action
     * @param from The user whose tokens are being transferred
     * @param to The recipient
     * @param value The amount being transferred
     * @param index The new liquidity index of the reserve
     **/
    event BalanceTransfer(
        address indexed from,
        address indexed to,
        uint256 value,
        uint256 index
    );

    /**
     * @dev Burns aTokens from `user` and sends the equivalent amount of underlying to `receiverOfUnderlying`
     * @param user The owner of the aTokens, getting them burned
     * @param receiverOfUnderlying The address that will receive the underlying
     * @param amount The amount being burned
     * @param index The new liquidity index of the reserve
     **/
    function burn(
        address user,
        address receiverOfUnderlying,
        uint256 amount,
        uint256 index
    ) external;

    /**
     * @dev Mints aTokens to the reserve treasury
     * @param amount The amount of tokens getting minted
     * @param index The new liquidity index of the reserve
     */
    function mintToTreasury(uint256 amount, uint256 index) external;

    /**
     * @dev Mints aTokens to the vmex treasury
     * @param amount The amount of tokens getting minted
     * @param index The new liquidity index of the reserve
     */
    function mintToVMEXTreasury(uint256 amount, uint256 index) external;

    /**
     * @dev Transfers aTokens in the event of a borrow being liquidated, in case the liquidators reclaims the aToken
     * @param from The address getting liquidated, current owner of the aTokens
     * @param to The recipient
     * @param value The amount of tokens getting transferred
     **/
    function transferOnLiquidation(
        address from,
        address to,
        uint256 value
    ) external;

    /**
     * @dev Transfers the underlying asset to `target`. Used by the LendingPool to transfer
     * assets in borrow(), withdraw() and flashLoan()
     * @param user The recipient of the underlying
     * @param amount The amount getting transferred
     * @return The amount transferred
     **/
    function transferUnderlyingTo(address user, uint256 amount)
        external
        returns (uint256);

    /**
     * @dev Invoked to execute actions on the aToken side after a repayment.
     * @param user The user executing the repayment
     * @param amount The amount getting repaid
     **/
    function handleRepayment(address user, uint256 amount) external;

    /**
     * @dev Returns the address of the incentives controller contract
     **/
    function getIncentivesController()
        external
        view
        returns (IAaveIncentivesController);

    /**
     * @dev Returns the address of the underlying asset of this aToken (E.g. WETH for aWETH)
     **/
    function UNDERLYING_ASSET_ADDRESS() external view returns (address);

    function setAndApproveStrategy(address strategy) external;

    function withdrawFromStrategy(uint256 amount) external;

    function getStrategy() external view returns (address);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface IBaseStrategy {
    struct TokenAmount {
        address token;
        uint256 amount;
    }

    struct TendData {
        uint256 crvTended;
        uint256 cvxTended;
        uint256 cvxCrvTended;
        uint256 extraRewardsTended;
    }

    event Tend (
        TendData t
    );

    event InterestRateUpdated (
        uint256 scaledAmount,
        uint256 timeDifference,
        uint256 p,
        uint256 seconds_per_year,
        uint256 r
    );

    event SetWithdrawalMaxDeviationThreshold(uint256 newMaxDeviationThreshold);

    event StrategyPullFromLendingPool(address lendingPool, uint256 amount);

    function baseStrategyVersion() external pure returns (string memory);

    function balanceOf() external view returns (uint256);

    function setWithdrawalMaxDeviationThreshold(uint256 _threshold) external;

    function pull() external returns (uint256);

    function withdrawAll() external;

    function withdraw(uint256 _amount) external;

    function emitNonProtectedToken(address _token) external;

    function withdrawOther(address _asset) external;

    function pause() external;

    function unpause() external;

    function harvest() external returns (TokenAmount[] memory harvested);

    function tend(uint256 minOut) external returns (uint256);

    function getName() external returns (string memory);

    function balanceOfRewards() external returns (TokenAmount[] memory rewards);

    function calculateAverageRate() external view returns (uint256 r);
}

// SPDX-License-Identifier: agpl-3.0
pragma solidity >=0.8.0;

interface IChainlinkAggregator {
    function decimals() external view returns (uint8);

    function latestAnswer() external view returns (int256);

    function latestTimestamp() external view returns (uint256);

    function latestRound() external view returns (uint256);

    function getAnswer(uint256 roundId) external view returns (int256);

    function getTimestamp(uint256 roundId) external view returns (uint256);

    event AnswerUpdated(
        int256 indexed current,
        uint256 indexed roundId,
        uint256 timestamp
    );
    event NewRound(uint256 indexed roundId, address indexed startedBy);
}

// SPDX-License-Identifier: agpl-3.0
pragma solidity >=0.8.0;

interface ICreditDelegationToken {
    event BorrowAllowanceDelegated(
        address indexed fromUser,
        address indexed toUser,
        address asset,
        uint256 amount
    );

    /**
     * @dev delegates borrowing power to a user on the specific debt token
     * @param delegatee the address receiving the delegated borrowing power
     * @param amount the maximum amount being delegated. Delegation will still
     * respect the liquidation constraints (even if delegated, a delegatee cannot
     * force a delegator HF to go below 1)
     **/
    function approveDelegation(address delegatee, uint256 amount) external;

    /**
     * @dev returns the borrow allowance of the user
     * @param fromUser The user to giving allowance
     * @param toUser The user to give allowance to
     * @return the current allowance of toUser
     **/
    function borrowAllowance(address fromUser, address toUser)
        external
        view
        returns (uint256);
}

// SPDX-License-Identifier: agpl-3.0
pragma solidity >=0.8.0;

/**
 * @title IDelegationToken
 * @dev Implements an interface for tokens with delegation COMP/UNI compatible
 * @author Aave
 **/
interface IDelegationToken {
    function delegate(address delegatee) external;
}

// SPDX-License-Identifier: agpl-3.0
pragma solidity >=0.8.0;

import {IERC20} from "../dependencies/openzeppelin/contracts/IERC20.sol";

interface IERC20WithPermit is IERC20 {
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

// SPDX-License-Identifier: agpl-3.0
pragma solidity >=0.8.0;

import {ILendingPool} from "./ILendingPool.sol";
import {IAaveIncentivesController} from "./IAaveIncentivesController.sol";

/**
 * @title IInitializableAToken
 * @notice Interface for the initialize function on AToken
 * @author Aave
 **/
interface IInitializableAToken {
    /**
     * @dev Emitted when an aToken is initialized
     * @param underlyingAsset The address of the underlying asset
     * @param trancheId The tranche of the underlying asset
     * @param pool The address of the associated lending pool
     * @param treasury The address of the treasury
     * @param incentivesController The address of the incentives controller for this aToken
     * @param aTokenDecimals the decimals of the underlying
     * @param aTokenName the name of the aToken
     * @param aTokenSymbol the symbol of the aToken
     **/
    event Initialized(
        address indexed underlyingAsset,
        uint64 indexed trancheId,
        address indexed pool,
        address treasury,
        address incentivesController,
        uint8 aTokenDecimals,
        string aTokenName,
        string aTokenSymbol
    );

    struct InitializeTreasuryVars {
        address lendingPoolConfigurator;
        address treasury;
        address VMEXTreasury;
        address underlyingAsset;
        uint64 trancheId;
    }

    /**
     * @dev Initializes the aToken
     * @param pool The address of the lending pool where this aToken will be used
     * @param vars Stores treasury vars to fix stack too deep
     * @param incentivesController The smart contract managing potential incentives distribution
     * @param aTokenDecimals The decimals of the aToken, same as the underlying asset's
     * @param aTokenName The name of the aToken
     * @param aTokenSymbol The symbol of the aToken
     */
    function initialize(
        ILendingPool pool,
        InitializeTreasuryVars memory vars,
        IAaveIncentivesController incentivesController,
        uint8 aTokenDecimals,
        string calldata aTokenName,
        string calldata aTokenSymbol
    ) external;
}

// SPDX-License-Identifier: agpl-3.0
pragma solidity >=0.8.0;

import {ILendingPool} from "./ILendingPool.sol";
import {IAaveIncentivesController} from "./IAaveIncentivesController.sol";

/**
 * @title IInitializableDebtToken
 * @notice Interface for the initialize function common between debt tokens
 * @author Aave
 **/
interface IInitializableDebtToken {
    /**
     * @dev Emitted when a debt token is initialized
     * @param underlyingAsset The address of the underlying asset
     * @param trancheId The tranche of the underlying asset
     * @param pool The address of the associated lending pool
     * @param incentivesController The address of the incentives controller for this aToken
     * @param debtTokenDecimals the decimals of the debt token
     * @param debtTokenName the name of the debt token
     * @param debtTokenSymbol the symbol of the debt token
     **/
    event Initialized(
        address indexed underlyingAsset,
        uint64 indexed trancheId,
        address indexed pool,
        address incentivesController,
        uint8 debtTokenDecimals,
        string debtTokenName,
        string debtTokenSymbol
    );

    /**
     * @dev Initializes the debt token.
     * @param pool The address of the lending pool where this aToken will be used
     * @param underlyingAsset The address of the underlying asset of this aToken (E.g. WETH for aWETH)
     * @param incentivesController The smart contract managing potential incentives distribution
     * @param debtTokenDecimals The decimals of the debtToken, same as the underlying asset's
     * @param debtTokenName The name of the token
     * @param debtTokenSymbol The symbol of the token
     */
    function initialize(
        ILendingPool pool,
        address underlyingAsset,
        uint64 trancheId,
        IAaveIncentivesController incentivesController,
        uint8 debtTokenDecimals,
        string memory debtTokenName,
        string memory debtTokenSymbol
    ) external;
}

// SPDX-License-Identifier: agpl-3.0
pragma solidity >=0.8.0;

import {ILendingPoolAddressesProvider} from "./ILendingPoolAddressesProvider.sol";
import {DataTypes} from "../protocol/libraries/types/DataTypes.sol";

interface ILendingPool {
    /**
     * @dev Emitted on deposit()
     * @param reserve The address of the underlying asset of the reserve
     * @param user The address initiating the deposit
     * @param onBehalfOf The beneficiary of the deposit, receiving the aTokens
     * @param amount The amount deposited
     * @param referral The referral code used
     **/
    event Deposit(
        address indexed reserve,
        uint64 trancheId,
        address user,
        address indexed onBehalfOf,
        uint256 amount,
        uint16 indexed referral
    );

    /**
     * @dev Emitted on withdraw()
     * @param reserve The address of the underlyng asset being withdrawn
     * @param user The address initiating the withdrawal, owner of aTokens
     * @param to Address that will receive the underlying
     * @param amount The amount to be withdrawn
     **/
    event Withdraw(
        address indexed reserve,
        uint64 trancheId,
        address indexed user,
        address indexed to,
        uint256 amount
    );

    /**
     * @dev Emitted on borrow() when debt needs to be opened
     * @param reserve The address of the underlying asset being borrowed
     * @param user The address of the user initiating the borrow(), receiving the funds on borrow() or just
     * initiator of the transaction on flashLoan()
     * @param onBehalfOf The address that will be getting the debt
     * @param amount The amount borrowed out
     * @param referral The referral code used
     **/
    event Borrow(
        address indexed reserve,
        uint64 trancheId,
        address user,
        address indexed onBehalfOf,
        uint256 amount,
        uint256 borrowRate,
        uint16 indexed referral
    );

    /**
     * @dev Emitted on repay()
     * @param reserve The address of the underlying asset of the reserve
     * @param user The beneficiary of the repayment, getting his debt reduced
     * @param repayer The address of the user initiating the repay(), providing the funds
     * @param amount The amount repaid
     **/
    event Repay(
        address indexed reserve,
        uint64 trancheId,
        address indexed user,
        address indexed repayer,
        uint256 amount
    );

    /**
     * @dev Emitted on setUserUseReserveAsCollateral()
     * @param reserve The address of the underlying asset of the reserve
     * @param trancheId The trancheId of the reserve
     * @param user The address of the user enabling the usage as collateral
     **/
    event ReserveUsedAsCollateralEnabled(
        address indexed reserve,
        uint64 trancheId,
        address indexed user
    );

    /**
     * @dev Emitted on setUserUseReserveAsCollateral()
     * @param reserve The address of the underlying asset of the reserve
     * @param trancheId The trancheId of the reserve
     * @param user The address of the user enabling the usage as collateral
     **/
    event ReserveUsedAsCollateralDisabled(
        address indexed reserve,
        uint64 trancheId,
        address indexed user
    );

    /**
     * @dev Emitted when the pause is triggered.
     */
    event Paused(uint64 indexed trancheId);

    /**
     * @dev Emitted when the pause is lifted.
     */
    event Unpaused(uint64 indexed trancheId);

    /**
     * @dev Emitted when the pause is triggered.
     */
    event EverythingPaused();

    /**
     * @dev Emitted when the pause is lifted.
     */
    event EverythingUnpaused();

    /**
     * @dev Emitted when a borrower is liquidated. This event is emitted by the LendingPool via
     * LendingPoolCollateral manager using a DELEGATECALL
     * This allows to have the events in the generated ABI for LendingPool.
     * @param collateralAsset The address of the underlying asset used as collateral, to receive as result of the liquidation
     * @param debtAsset The address of the underlying borrowed asset to be repaid with the liquidation
     * @param trancheId The trancheId of the liquidation
     * @param user The address of the borrower getting liquidated
     * @param debtToCover The debt amount of borrowed `asset` the liquidator wants to cover
     * @param liquidatedCollateralAmount The amount of collateral received by the liiquidator
     * @param liquidator The address of the liquidator
     * @param receiveAToken `true` if the liquidators wants to receive the collateral aTokens, `false` if he wants
     * to receive the underlying collateral asset directly
     **/
    event LiquidationCall(
        address indexed collateralAsset,
        address indexed debtAsset,
        uint64 trancheId,
        address indexed user,
        uint256 debtToCover,
        uint256 liquidatedCollateralAmount,
        address liquidator,
        bool receiveAToken
    );

    /**
     * @dev Emitted when the state of a reserve is updated. NOTE: This event is actually declared
     * in the ReserveLogic library and emitted in the updateInterestRates() function. Since the function is internal,
     * the event will actually be fired by the LendingPool contract. The event is therefore replicated here so it
     * gets added to the LendingPool ABI
     * @param reserve The address of the underlying asset of the reserve
     * @param trancheId The trancheId of the reserve
     * @param liquidityRate The new liquidity rate
     * @param stableBorrowRate The new stable borrow rate
     * @param variableBorrowRate The new variable borrow rate
     * @param liquidityIndex The new liquidity index
     * @param variableBorrowIndex The new variable borrow index
     **/
    event ReserveDataUpdated(
        address indexed reserve,
        uint64 indexed trancheId,
        uint256 liquidityRate,
        uint256 stableBorrowRate,
        uint256 variableBorrowRate,
        uint256 liquidityIndex,
        uint256 variableBorrowIndex
    );

    function addWhitelistedDepositBorrow(address user) external;

    /**
     * @dev Deposits an `amount` of underlying asset into the reserve, receiving in return overlying aTokens.
     * - E.g. User deposits 100 USDC and gets in return 100 aUSDC
     * @param asset The address of the underlying asset to deposit
     * @param amount The amount to be deposited
     * @param onBehalfOf The address that will receive the aTokens, same as msg.sender if the user
     *   wants to receive them on his own wallet, or a different address if the beneficiary of aTokens
     *   is a different wallet
     * @param referralCode Code used to register the integrator originating the operation, for potential rewards.
     *   0 if the action is executed directly by the user, without any middle-man
     **/
    function deposit(
        address asset,
        uint64 trancheId,
        uint256 amount,
        address onBehalfOf,
        uint16 referralCode
    ) external;

    /**
     * @dev Withdraws an `amount` of underlying asset from the reserve, burning the equivalent aTokens owned
     * E.g. User has 100 aUSDC, calls withdraw() and receives 100 USDC, burning the 100 aUSDC
     * @param asset The address of the underlying asset to withdraw
     * @param amount The underlying amount to be withdrawn
     *   - Send the value type(uint256).max in order to withdraw the whole aToken balance
     * @param to Address that will receive the underlying, same as msg.sender if the user
     *   wants to receive it on his own wallet, or a different address if the beneficiary is a
     *   different wallet
     * @return The final amount withdrawn
     **/
    function withdraw(
        address asset,
        uint64 trancheId,
        uint256 amount,
        address to
    ) external returns (uint256);

    /**
     * @dev Allows users to borrow a specific `amount` of the reserve underlying asset, provided that the borrower
     * already deposited enough collateral, or he was given enough allowance by a credit delegator on the
     * corresponding debt token (StableDebtToken or VariableDebtToken)
     * - E.g. User borrows 100 USDC passing as `onBehalfOf` his own address, receiving the 100 USDC in his wallet
     *   and 100 stable/variable debt tokens, depending on the `interestRateMode`
     * @param asset The address of the underlying asset to borrow
     * @param trancheId The trancheId of the underlying asset to borrow
     * @param amount The amount to be borrowed
     * @param referralCode Code used to register the integrator originating the operation, for potential rewards.
     *   0 if the action is executed directly by the user, without any middle-man
     * @param onBehalfOf Address of the user who will receive the debt. Should be the address of the borrower itself
     * calling the function if he wants to borrow against his own collateral, or the address of the credit delegator
     * if he has been given credit delegation allowance
     **/
    function borrow(
        address asset,
        uint64 trancheId,
        uint256 amount,
        uint16 referralCode,
        address onBehalfOf
    ) external;

    /**
     * @notice Repays a borrowed `amount` on a specific reserve, burning the equivalent debt tokens owned
     * - E.g. User repays 100 USDC, burning 100 variable/stable debt tokens of the `onBehalfOf` address
     * @param asset The address of the borrowed underlying asset previously borrowed
     * @param trancheId The trancheId of the borrowed underlying asset previously borrowed
     * @param amount The amount to repay
     * - Send the value type(uint256).max in order to repay the whole debt for `asset` on the specific `debtMode`
     * @param onBehalfOf Address of the user who will get his debt reduced/removed. Should be the address of the
     * user calling the function if he wants to reduce/remove his own debt, or the address of any other
     * other borrower whose debt should be removed
     * @return The final amount repaid
     **/
    function repay(
        address asset,
        uint64 trancheId,
        uint256 amount,
        address onBehalfOf
    ) external returns (uint256);


    /**
     * @dev Allows depositors to enable/disable a specific deposited asset as collateral
     * @param asset The address of the underlying asset deposited
     * @param useAsCollateral `true` if the user wants to use the deposit as collateral, `false` otherwise
     **/
    function setUserUseReserveAsCollateral(
        address asset,
        uint64 trancheId,
        bool useAsCollateral
    ) external;

    /**
     * @dev Function to liquidate a non-healthy position collateral-wise, with Health Factor below 1
     * - The caller (liquidator) covers `debtToCover` amount of debt of the user getting liquidated, and receives
     *   a proportionally amount of the `collateralAsset` plus a bonus to cover market risk
     * @param collateralAsset The address of the underlying asset used as collateral, to receive as result of the liquidation
     * @param debtAsset The address of the underlying borrowed asset to be repaid with the liquidation
     * @param user The address of the borrower getting liquidated
     * @param debtToCover The debt amount of borrowed `asset` the liquidator wants to cover
     * @param receiveAToken `true` if the liquidators wants to receive the collateral aTokens, `false` if he wants
     * to receive the underlying collateral asset directly
     **/
    function liquidationCall(
        address collateralAsset,
        address debtAsset,
        uint64 trancheId,
        address user,
        uint256 debtToCover,
        bool receiveAToken
    ) external;

    /**
     * @dev Allows smartcontracts to access the liquidity of the pool within one transaction,
     * as long as the amount taken plus a fee is returned.
     * IMPORTANT There are security concerns for developers of flashloan receiver contracts that must be kept into consideration.
     * For further details please visit https://developers.aave.com
     * @param receiverAddress The address of the contract receiving the funds, implementing the IFlashLoanReceiver interface
     * @param assets The addresses of the assets being flash-borrowed
     * @param amounts The amounts amounts being flash-borrowed
     * @param modes Types of the debt to open if the flash loan is not returned:
     *   0 -> Don't open any debt, just revert if funds can't be transferred from the receiver
     *   1 -> Open debt at stable rate for the value of the amount flash-borrowed to the `onBehalfOf` address
     *   2 -> Open debt at variable rate for the value of the amount flash-borrowed to the `onBehalfOf` address
     * @param onBehalfOf The address  that will receive the debt in the case of using on `modes` 1 or 2
     * @param params Variadic packed params to pass to the receiver as extra information
     * @param referralCode Code used to register the integrator originating the operation, for potential rewards.
     *   0 if the action is executed directly by the user, without any middle-man
     **/
    // function flashLoan(
    //     address receiverAddress,
    //     address[] calldata assets,
    //     uint64 trancheId,
    //     uint256[] calldata amounts,
    //     uint256[] calldata modes,
    //     address onBehalfOf,
    //     bytes calldata params,
    //     uint16 referralCode
    // ) external;

    /**
     * @dev Returns the user account data across all the reserves
     * @param user The address of the user
     * @return totalCollateralETH the total collateral in ETH of the user
     * @return totalDebtETH the total debt in ETH of the user
     * @return availableBorrowsETH the borrowing power left of the user
     * @return currentLiquidationThreshold the liquidation threshold of the user
     * @return ltv the loan to value of the user
     * @return healthFactor the current health factor of the user
     **/
    function getUserAccountData(address user, uint64 trancheId, bool useTwap)
        external
        view
        returns (
            uint256 totalCollateralETH,
            uint256 totalDebtETH,
            uint256 availableBorrowsETH,
            uint256 currentLiquidationThreshold,
            uint256 ltv,
            uint256 healthFactor,
            uint256 avgBorrowFactor
        );

    function initReserve(
        address underlyingAsset,
        uint64 trancheId,
        address interestRateStrategyAddress,
        address aTokenAddress,
        address variableDebtAddress
    ) external;

    function setReserveInterestRateStrategyAddress(
        address reserve,
        uint64 trancheId,
        address rateStrategyAddress
    ) external;

    function setConfiguration(
        address reserve,
        uint64 trancheId,
        uint256 configuration
    ) external;

    /**
     * @dev Returns the configuration of the reserve
     * @param asset The address of the underlying asset of the reserve
     * @return The configuration of the reserve
     **/
    function getConfiguration(address asset, uint64 trancheId)
        external
        view
        returns (DataTypes.ReserveConfigurationMap memory);

    /**
     * @dev Returns the configuration of the user across all the reserves
     * @param user The user address
     * @return The configuration of the user
     **/
    function getUserConfiguration(address user, uint64 trancheId)
        external
        view
        returns (DataTypes.UserConfigurationMap memory);

    /**
     * @dev Returns the normalized income normalized income of the reserve
     * @param asset The address of the underlying asset of the reserve
     * @return The reserve's normalized income
     */
    function getReserveNormalizedIncome(address asset, uint64 trancheId)
        external
        view
        returns (uint256);

    /**
     * @dev Returns the normalized variable debt per unit of asset
     * @param asset The address of the underlying asset of the reserve
     * @return The reserve normalized variable debt
     */
    function getReserveNormalizedVariableDebt(address asset, uint64 trancheId)
        external
        view
        returns (uint256);

    /**
     * @dev Returns the state and configuration of the reserve
     * @param asset The address of the underlying asset of the reserve
     * @return The state of the reserve
     **/
    function getReserveData(address asset, uint64 trancheId)
        external
        view
        returns (DataTypes.ReserveData memory);

    function finalizeTransfer(
        address asset,
        uint64 trancheId,
        address from,
        address to,
        uint256 amount,
        uint256 balanceFromAfter,
        uint256 balanceToBefore
    ) external;

    function getReservesList(uint64 trancheId)
        external
        view
        returns (address[] memory);

    // function getReservesList(uint64 trancheId) external view returns (address[] memory);


    function getAddressesProvider()
        external
        view
        returns (ILendingPoolAddressesProvider);

    function setPauseEverything(bool val) external;

    function setPause(bool val, uint64 trancheId) external;

    function paused(uint64 trancheId) external view returns (bool);

    function setAndApproveStrategy(
        address asset,
        uint64 trancheId,
        address strategy
    ) external;

    function withdrawFromStrategy(
        address asset,
        uint64 trancheId,
        uint256 amount
    ) external;

    function setReserveDataLI(address asset, uint64 trancheId, uint128 newLiquidityIndex)
        external;

    function setWhitelist(uint64 trancheId, bool isWhitelisted) external;
    function addToWhitelist(uint64 trancheId, address user, bool isWhitelisted) external;
    function addToBlacklist(uint64 trancheId, address user, bool isBlacklisted) external;
}

// SPDX-License-Identifier: agpl-3.0
pragma solidity >=0.8.0;

import {DataTypes} from "../protocol/libraries/types/DataTypes.sol";

/**
 * @title LendingPoolAddressesProvider contract
 * @dev Main registry of addresses part of or connected to the protocol, including permissioned roles
 * - Acting also as factory of proxies and admin of those, so with right to change its implementations
 * - Owned by the Aave Governance
 * @author Aave
 **/
interface ILendingPoolAddressesProvider {
    event MarketIdSet(string newMarketId);
    event LendingPoolUpdated(address indexed newAddress);

    // event ATokensAndRatesHelperUpdated(address indexed newAddress);
    event ConfigurationAdminUpdated(
        address indexed newAddress,
        uint64 indexed trancheId
    );
    event EmergencyAdminUpdated(address indexed newAddress);
    event LendingPoolConfiguratorUpdated(address indexed newAddress);
    event LendingPoolCollateralManagerUpdated(address indexed newAddress);
    event PriceOracleUpdated(address indexed newAddress);
    event CurvePriceOracleUpdated(address indexed newAddress);
    event CurvePriceOracleWrapperUpdated(address indexed newAddress);
    event CurveAddressProviderUpdated(address indexed newAddress);
    event LendingRateOracleUpdated(address indexed newAddress);
    event ProxyCreated(bytes32 id, address indexed newAddress);
    event AddressSet(bytes32 id, address indexed newAddress, bool hasProxy);


    event VMEXTreasuryUpdated(address indexed newAddress);
    event AssetMappingsUpdated(address indexed newAddress);


    event ATokenUpdated(address indexed newAddress);
    event StableDebtUpdated(address indexed newAddress);
    event VariableDebtUpdated(address indexed newAddress);

    function getVMEXTreasury() external view returns(address);

    function setVMEXTreasury(address add) external;

    function getMarketId() external view returns (string memory);

    function setMarketId(string calldata marketId) external;

    function setAddress(bytes32 id, address newAddress) external;

    function setAddressAsProxy(bytes32 id, address impl) external;

    function getAddress(bytes32 id) external view returns (address);

    function getLendingPool() external view returns (address);

    function setLendingPoolImpl(address pool) external;

    // function getATokenAndRatesHelper() external view returns (address);

    // function setATokenAndRatesHelper(address newAdd) external;

    function getLendingPoolConfigurator() external view returns (address);

    function setLendingPoolConfiguratorImpl(address configurator) external;

    function getLendingPoolCollateralManager() external view returns (address);

    function setLendingPoolCollateralManager(address manager) external;

    //********************************************************** */

    function getGlobalAdmin() external view returns (address);

    function setGlobalAdmin(address admin) external;

    function getTrancheAdmin(uint64 trancheId) external view returns (address);

    function setTrancheAdmin(address admin, uint64 trancheId) external;

    function addTrancheAdmin(address admin, uint64 trancheId) external;

    function getEmergencyAdmin()
        external
        view
        returns (address);

    function setEmergencyAdmin(address admin) external;

    function getAddressTranche(bytes32 id, uint64 trancheId)
        external
        view
        returns (address);

    function isWhitelistedAddress(address ad) external view returns (bool);

    //********************************************************** */
    function getPriceOracle()
        external
        view
        returns (address);

    function setPriceOracle(address priceOracle) external;

    function getAToken() external view returns (address);
    function setATokenImpl(address pool) external;

    function getVariableDebtToken() external view returns (address);
    function setVariableDebtToken(address pool) external;

    function getAssetMappings() external view returns (address);
    function setAssetMappingsImpl(address pool) external;
}

// SPDX-License-Identifier: agpl-3.0
pragma solidity >=0.8.0;

/**
 * @title ILendingPoolCollateralManager
 * @author Aave
 * @notice Defines the actions involving management of collateral in the protocol.
 **/
interface ILendingPoolCollateralManager {
    /**
     * @dev Emitted when a borrower is liquidated. This event is emitted by the LendingPool via
     * LendingPoolCollateral manager using a DELEGATECALL
     * This allows to have the events in the generated ABI for LendingPool.
     * @param collateralAsset The address of the underlying asset used as collateral, to receive as result of the liquidation
     * @param debtAsset The address of the underlying borrowed asset to be repaid with the liquidation
     * @param trancheId The trancheId of the liquidation
     * @param user The address of the borrower getting liquidated
     * @param debtToCover The debt amount of borrowed `asset` the liquidator wants to cover
     * @param liquidatedCollateralAmount The amount of collateral received by the liiquidator
     * @param liquidator The address of the liquidator
     * @param receiveAToken `true` if the liquidators wants to receive the collateral aTokens, `false` if he wants
     * to receive the underlying collateral asset directly
     **/
    event LiquidationCall(
        address indexed collateralAsset,
        address indexed debtAsset,
        uint64 trancheId,
        address indexed user,
        uint256 debtToCover,
        uint256 liquidatedCollateralAmount,
        address liquidator,
        bool receiveAToken
    );

    /**
     * @dev Emitted on setUserUseReserveAsCollateral()
     * @param reserve The address of the underlying asset of the reserve
     * @param trancheId The trancheId of the reserve
     * @param user The address of the user enabling the usage as collateral
     **/
    event ReserveUsedAsCollateralDisabled(
        address indexed reserve,
        uint64 trancheId,
        address indexed user
    );

    /**
     * @dev Emitted on setUserUseReserveAsCollateral()
     * @param reserve The address of the underlying asset of the reserve
     * @param trancheId The trancheId of the reserve
     * @param user The address of the user enabling the usage as collateral
     **/
    event ReserveUsedAsCollateralEnabled(
        address indexed reserve,
        uint64 trancheId,
        address indexed user
    );

    /**
     * @dev Users can invoke this function to liquidate an undercollateralized position.
     * @param collateral The address of the collateral to liquidated
     * @param principal The address of the principal reserve
     * @param user The address of the borrower
     * @param debtToCover The amount of principal that the liquidator wants to repay
     * @param receiveAToken true if the liquidators wants to receive the aTokens, false if
     * he wants to receive the underlying asset directly
     **/
    function liquidationCall(
        address collateral,
        address principal,
        uint64 trancheId,
        address user,
        uint256 debtToCover,
        bool receiveAToken
    ) external returns (uint256, string memory);
}

// SPDX-License-Identifier: agpl-3.0
pragma solidity >=0.8.0;

interface ILendingPoolConfigurator {
    struct UpdateATokenInput {
        address asset;
        uint64 trancheId;
        address treasury;
        address incentivesController;
        string name;
        string symbol;
        address implementation;
    }

    struct UpdateDebtTokenInput {
        address asset;
        uint64 trancheId;
        address incentivesController;
        string name;
        string symbol;
        address implementation;
    }

    struct UpdateStrategyInput {
        uint64 trancheId;
        address asset;
        address implementation;
        address strategyAddress;
    }


    /**
     * @dev Emitted when a reserve factor is updated
     * @param asset The address of the underlying asset of the reserve
     * @param trancheId The trancheId of the reserve
     * @param factor The new reserve factor
     **/
    event ReserveFactorChanged(address indexed asset, uint64 indexed trancheId, uint256 factor);

    event AddedWhitelistedDepositBorrow(address indexed user);

    event UpdatedTreasuryAddress(address asset, uint64 trancheId, address newAddress);
    event UpdatedVMEXTreasuryAddress(address asset, uint64 trancheId, address newAddress);

    event UserSetWhitelistEnabled(uint64 indexed trancheId, bool isWhitelisted);

    event UserChangedWhitelist(uint64 indexed trancheId, address indexed user, bool isWhitelisted);
    event UserChangedBlacklist(uint64 indexed trancheId, address indexed user, bool isBlacklisted);

    /**
     * @dev Emitted when a reserve is frozen
     * @param asset The address of the underlying asset of the reserve
     * @param trancheId The trancheId of the reserve
     **/
    event ReserveFrozen(address indexed asset, uint64 indexed trancheId);

    /**
     * @dev Emitted when a reserve is unfrozen
     * @param asset The address of the underlying asset of the reserve
     * @param trancheId The trancheId of the reserve
     **/
    event ReserveUnfrozen(address indexed asset, uint64 indexed trancheId);

    /**
     * @dev Emitted when a tranche is initialized.
     * @param trancheId The trancheId
     * @param trancheName The name of the tranche
     **/
    event TrancheInitialized(uint256 indexed trancheId, string trancheName, address admin);

    /**
     * @dev Emitted when a reserve is initialized.
     * @param asset The address of the underlying asset of the reserve
     * @param trancheId The trancheId of the reserve
     * @param aToken The address of the associated aToken contract
     * @param variableDebtToken The address of the associated variable rate debt token
     * @param interestRateStrategyAddress The address of the interest rate strategy for the reserve
     * @param borrowingEnabled Whether or not borrowing is enabled on the reserve
     * @param collateralEnabled Whether or not usage as collateral is enabled on the reserve
     * @param reserveFactor The reserve factor of the reserve
     **/
    event ReserveInitialized(
        address indexed asset,
        uint64 indexed trancheId,
        address indexed aToken,
        address variableDebtToken,
        address interestRateStrategyAddress,
        bool borrowingEnabled,
        bool collateralEnabled,
        uint256 reserveFactor
    );

    /**
     * @dev Emitted when borrowing is enabled on a reserve
     * @param asset The address of the underlying asset of the reserve
     * @param trancheId The trancheId of the reserve
     **/
    event BorrowingSetOnReserve(
        address indexed asset,
        uint64 indexed trancheId,
        bool borrowingEnabled
    );

    /**
     * @dev Emitted when collateral is enabled on a reserve
     * @param asset The address of the underlying asset of the reserve
     * @param trancheId The trancheId of the reserve
     **/
    event CollateralSetOnReserve(address indexed asset, uint64 indexed trancheId, bool collateralEnabled);

    /**
     * @dev Emitted when a reserve is activated
     * @param asset The address of the underlying asset of the reserve
     * @param trancheId The trancheId of the reserve
     **/
    event ReserveActivated(address indexed asset, uint64 indexed trancheId);

    /**
     * @dev Emitted when a reserve is deactivated
     * @param asset The address of the underlying asset of the reserve
     * @param trancheId The trancheId of the reserve
     **/
    event ReserveDeactivated(address indexed asset, uint64 indexed trancheId);

    /**
     * @dev Emitted when the reserve decimals are updated
     * @param asset The address of the underlying asset of the reserve
     * @param trancheId The trancheId of the reserve
     * @param decimals The new decimals
     **/
    event ReserveDecimalsChanged(address indexed asset, uint64 indexed trancheId, uint256 decimals);

    /**
     * @dev Emitted when a reserve interest strategy contract is updated
     * @param asset The address of the underlying asset of the reserve
     * @param trancheId The trancheId of the reserve
     * @param strategy The new address of the interest strategy contract
     **/
    event ReserveInterestRateStrategyChanged(
        address indexed asset,
        uint64 indexed trancheId,
        address strategy
    );

    event AssetDataChanged(address indexed asset, uint64 indexed trancheId, uint8 _assetType);

    /**
     * @dev Emitted when an aToken implementation is upgraded
     * @param asset The address of the underlying asset of the reserve
     * @param proxy The aToken proxy address
     * @param implementation The new aToken implementation
     **/
    event ATokenUpgraded(
        address indexed asset,
        uint64 trancheId,
        address indexed proxy,
        address indexed implementation
    );

    event StrategyUpgraded(
        address indexed asset,
        uint64 trancheId,
        address indexed proxy,
        address indexed implementation
    );


    /**
     * @dev Emitted when the implementation of a variable debt token is upgraded
     * @param asset The address of the underlying asset of the reserve
     * @param proxy The variable debt token proxy address
     * @param implementation The new aToken implementation
     **/
    event VariableDebtTokenUpgraded(
        address indexed asset,
        uint64 trancheId,
        address indexed proxy,
        address indexed implementation
    );

    /**
     * @dev Emitted when a strategy is associated with an asset/tranche
     * @param asset The address of the underlying asset of the reserve
     * @param trancheId The tranche
     * @param strategy The address of the strategy
     **/
    event StrategyAdded(address indexed asset, uint64 indexed trancheId, address strategy);

    /**
     * @dev Emitted when successful withdraw from strategy to lending pool
     * @param asset The address of the underlying asset of the reserve
     * @param trancheId The tranche
     * @param amount The amount withdrawn from strategy
     **/
    event WithdrawFromStrategy(address indexed asset, uint64 indexed trancheId, uint256 amount);
}

// SPDX-License-Identifier: agpl-3.0
pragma solidity >=0.8.0;

interface IParaSwapAugustus {
    function getTokenTransferProxy() external view returns (address);
}

// SPDX-License-Identifier: agpl-3.0
pragma solidity >=0.8.0;

interface IParaSwapAugustusRegistry {
    function isValidAugustus(address augustus) external view returns (bool);
}

// SPDX-License-Identifier: agpl-3.0
pragma solidity >=0.8.0;

/**
 * @title IPriceOracleGetter interface
 * @notice Interface for the Aave price oracle.
 **/
//import "hardhat/console.sol";
abstract contract IPriceOracleGetter {

    uint256 constant PRICE_TTL = 1 days;

    struct TimePrice {
        uint256 timestamp;
        uint256 cumulatedPrice;
        uint256 currentPrice;
    }

    /**
     * @dev Prefix sum circular array, used to find the average price in an interval.
     * asset => array of time prices (ie index of array => price)
     * CumulatedPrice is weighted on time:
     * cumulatedPrice = cumulatedPrice + timeDifference * currentPrice
     **/
    mapping(address=>mapping(uint16=>TimePrice)) public cumulatedPrices;

    /**
     * @dev Index of most recent addition to cumulatedPrices
     **/
    mapping(address =>uint16) public recent;

    /**
     * @dev Index of the least recent addition to cumulatedPrices
     **/
    mapping(address =>uint16) public last;

    /**
     * @dev Size of circular array for an asset
     **/
    mapping(address =>uint16) public numPrices;

    constructor(){
        //loop through all assets, set timestamp to current block's timestamp
        //or have a genesis timestamp, this genesis timestamp updates every time
    }

    /**
     * @dev returns the asset price in ETH
     * @param asset the address of the asset
     * @return the ETH price of the asset
     **/
    function getAssetPrice(address asset) external virtual view returns (uint256);

    function updateTWAP(address asset) external virtual;

    function getAssetTWAPPrice(address asset) external view virtual returns (uint256);

    function _updateState(address asset, uint256 currentPrice) internal {
        if(numPrices[asset]!=0){
            uint16 prev = recent[asset];
            //if this index is past 24 hours ago, don't use, just set cumulatedPrice to zero? Doing so is actually the same as keeping the below calculation cause the last pointer is set as this pointer
            if(recent[asset]==type(uint16).max)
                recent[asset] =0;
            else
                recent[asset]+=1;//handle going back around in circle

            //this is a right ended Riemann sum. In times of rising prices, it overestimates the average, and when prices are lowering, it underestimates
            //can use trapezoid rule instead by taking the average between the current price and the previous price
            //same as midpoint rule since discrete time sampling
            uint256 averageInterpolatedPrice = (cumulatedPrices[asset][prev].currentPrice + currentPrice)/2;
            cumulatedPrices[asset][recent[asset]].cumulatedPrice = cumulatedPrices[asset][prev].cumulatedPrice +
                (block.timestamp-cumulatedPrices[asset][prev].timestamp) * averageInterpolatedPrice;
        }
        else{
            cumulatedPrices[asset][recent[asset]].cumulatedPrice = 0;
        }

        cumulatedPrices[asset][recent[asset]].currentPrice = currentPrice;
        cumulatedPrices[asset][recent[asset]].timestamp = block.timestamp;
        numPrices[asset]+=1;

        //get rid of outdated prices. Average O(1)
        //only get rid of them if there are stuff to get rid of
        while(numPrices[asset]>0 && (block.timestamp - cumulatedPrices[asset][last[asset]].timestamp) > PRICE_TTL){
            if(last[asset]==type(uint16).max){
                last[asset] = 0;
            }
            else{
                last[asset] +=1;
            }
            numPrices[asset]-=1;
        }
    }

    function _getAssetTWAPPrice(address asset, uint256 currentPrice) internal view returns (uint256){
        if(cumulatedPrices[asset][recent[asset]].currentPrice == 0){ //this check shouldn't be needed since state update happens before this is called
            //this is only called in the very beginning before recent[asset] is populated
            return currentPrice;
        }
        uint256 averageInterpolatedPrice = (cumulatedPrices[asset][recent[asset]].currentPrice + currentPrice)/2;
        uint16 tmpLast = last[asset];
        uint16 tmpNumPrices = numPrices[asset];
        //get rid of outdated prices. Average O(1)
        while(tmpNumPrices>0 && (block.timestamp - cumulatedPrices[asset][tmpLast].timestamp) > PRICE_TTL){
            if(tmpLast==type(uint16).max){
                tmpLast = 0;
            }
            else{
                tmpLast +=1;
            }
            tmpNumPrices-=1;
        }

        //if there hasn't been an update in a long time, then this may be the average over a big interval and not reflect what the price has been hovering around for the last couple days
        //better to be conservative still and return the average.
        if(tmpNumPrices==0)//if 0, that means that not enough data to calculate, only one update in the last 24 hours.
            return averageInterpolatedPrice;

        //Worst case, if not updated long enough, or all updates are close to current price, average will be current price.
        //If a lot of updates happened a day ago, calling this now will interpolate the current price as the price
        //through that entire time so it will weigh current price more than prevoius prices
        if(block.timestamp - cumulatedPrices[asset][tmpLast].timestamp == 0){
            //to avoid divide by zero error. This happens when we update state and immediately try to read twap price, and it is the first price in a 24 hour span
            return averageInterpolatedPrice;
        }
        //no state update, but temporarily calculate what the cumulatedPrice would be if there was an update. Note that prev is recent[asset]
        uint256 tmpCumulatedPrices = cumulatedPrices[asset][recent[asset]].cumulatedPrice + (block.timestamp-cumulatedPrices[asset][recent[asset]].timestamp) * averageInterpolatedPrice;
        return (tmpCumulatedPrices - cumulatedPrices[asset][tmpLast].cumulatedPrice)/(block.timestamp - cumulatedPrices[asset][tmpLast].timestamp);
    }

}

// SPDX-License-Identifier: agpl-3.0
pragma solidity >=0.8.0;
import {DataTypes} from "../protocol/libraries/types/DataTypes.sol";

/**
 * @title IReserveInterestRateStrategyInterface interface
 * @dev Interface for the calculation of the interest rates
 * @author Aave
 */
interface IReserveInterestRateStrategy {
    function baseVariableBorrowRate() external view returns (uint256);

    function getMaxVariableBorrowRate() external view returns (uint256);

    function calculateInterestRates(
        DataTypes.calculateInterestRatesVars memory calvars
    )
        external
        view
        returns (
            uint256 liquidityRate,
            uint256 variableBorrowRate
        );
}

// SPDX-License-Identifier: agpl-3.0
pragma solidity >=0.8.0;

interface IScaledBalanceToken {
    /**
     * @dev Returns the scaled balance of the user. The scaled balance is the sum of all the
     * updated stored balance divided by the reserve's liquidity index at the moment of the update
     * @param user The user whose balance is calculated
     * @return The scaled balance of the user
     **/
    function scaledBalanceOf(address user) external view returns (uint256);

    /**
     * @dev Returns the scaled balance of the user and the scaled total supply.
     * @param user The address of the user
     * @return The scaled balance of the user
     * @return The scaled balance and the scaled total supply
     **/
    function getScaledUserBalanceAndSupply(address user)
        external
        view
        returns (uint256, uint256);

    /**
     * @dev Returns the scaled total supply of the variable debt token. Represents sum(debt/index)
     * @return The scaled total supply
     **/
    function scaledTotalSupply() external view returns (uint256);
}

// SPDX-License-Identifier: agpl-3.0
pragma solidity >=0.8.0;

import {IInitializableDebtToken} from "./IInitializableDebtToken.sol";
import {IAaveIncentivesController} from "./IAaveIncentivesController.sol";

/**
 * @title IStableDebtToken
 * @notice Defines the interface for the stable debt token
 * @dev It does not inherit from IERC20 to save in code size
 * @author Aave
 **/

interface IStableDebtToken is IInitializableDebtToken {
    /**
     * @dev Emitted when new stable debt is minted
     * @param user The address of the user who triggered the minting
     * @param onBehalfOf The recipient of stable debt tokens
     * @param amount The amount minted
     * @param currentBalance The current balance of the user
     * @param balanceIncrease The increase in balance since the last action of the user
     * @param newRate The rate of the debt after the minting
     * @param avgStableRate The new average stable rate after the minting
     * @param newTotalSupply The new total supply of the stable debt token after the action
     **/
    event Mint(
        address indexed user,
        address indexed onBehalfOf,
        uint256 amount,
        uint256 currentBalance,
        uint256 balanceIncrease,
        uint256 newRate,
        uint256 avgStableRate,
        uint256 newTotalSupply
    );

    /**
     * @dev Emitted when new stable debt is burned
     * @param user The address of the user
     * @param amount The amount being burned
     * @param currentBalance The current balance of the user
     * @param balanceIncrease The the increase in balance since the last action of the user
     * @param avgStableRate The new average stable rate after the burning
     * @param newTotalSupply The new total supply of the stable debt token after the action
     **/
    event Burn(
        address indexed user,
        uint256 amount,
        uint256 currentBalance,
        uint256 balanceIncrease,
        uint256 avgStableRate,
        uint256 newTotalSupply
    );

    /**
     * @dev Mints debt token to the `onBehalfOf` address.
     * - The resulting rate is the weighted average between the rate of the new debt
     * and the rate of the previous debt
     * @param user The address receiving the borrowed underlying, being the delegatee in case
     * of credit delegate, or same as `onBehalfOf` otherwise
     * @param onBehalfOf The address receiving the debt tokens
     * @param amount The amount of debt tokens to mint
     * @param rate The rate of the debt being minted
     **/
    function mint(
        address user,
        address onBehalfOf,
        uint256 amount,
        uint256 rate
    ) external returns (bool);

    /**
     * @dev Burns debt of `user`
     * - The resulting rate is the weighted average between the rate of the new debt
     * and the rate of the previous debt
     * @param user The address of the user getting his debt burned
     * @param amount The amount of debt tokens getting burned
     **/
    function burn(address user, uint256 amount) external;

    /**
     * @dev Returns the average rate of all the stable rate loans.
     * @return The average stable rate
     **/
    function getAverageStableRate() external view returns (uint256);

    /**
     * @dev Returns the stable rate of the user debt
     * @return The stable rate of the user
     **/
    function getUserStableRate(address user) external view returns (uint256);

    /**
     * @dev Returns the timestamp of the last update of the user
     * @return The timestamp
     **/
    function getUserLastUpdated(address user) external view returns (uint40);

    /**
     * @dev Returns the principal, the total supply and the average stable rate
     **/
    function getSupplyData()
        external
        view
        returns (
            uint256,
            uint256,
            uint256,
            uint40
        );

    /**
     * @dev Returns the timestamp of the last update of the total supply
     * @return The timestamp
     **/
    function getTotalSupplyLastUpdated() external view returns (uint40);

    /**
     * @dev Returns the total supply and the average stable rate
     **/
    function getTotalSupplyAndAvgRate()
        external
        view
        returns (uint256, uint256);

    /**
     * @dev Returns the principal debt balance of the user
     * @return The debt balance of the user since the last burn/mint action
     **/
    function principalBalanceOf(address user) external view returns (uint256);

    /**
     * @dev Returns the address of the incentives controller contract
     **/
    function getIncentivesController()
        external
        view
        returns (IAaveIncentivesController);
}

// SPDX-License-Identifier: agpl-3.0
pragma solidity >=0.8.0;

interface IUniswapV2Router02 {
    function swapExactTokensForTokens(
        uint256 amountIn,
        uint256 amountOutMin,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external returns (uint256[] memory amounts);

    function swapTokensForExactTokens(
        uint256 amountOut,
        uint256 amountInMax,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external returns (uint256[] memory amounts);

    function getAmountsOut(uint256 amountIn, address[] calldata path)
        external
        view
        returns (uint256[] memory amounts);

    function getAmountsIn(uint256 amountOut, address[] calldata path)
        external
        view
        returns (uint256[] memory amounts);
}

// SPDX-License-Identifier: agpl-3.0
pragma solidity >=0.8.0;

import {IScaledBalanceToken} from "./IScaledBalanceToken.sol";
import {IInitializableDebtToken} from "./IInitializableDebtToken.sol";
import {IAaveIncentivesController} from "./IAaveIncentivesController.sol";

/**
 * @title IVariableDebtToken
 * @author Aave
 * @notice Defines the basic interface for a variable debt token.
 **/
interface IVariableDebtToken is IScaledBalanceToken, IInitializableDebtToken {
    /**
     * @dev Emitted after the mint action
     * @param from The address performing the mint
     * @param onBehalfOf The address of the user on which behalf minting has been performed
     * @param value The amount to be minted
     * @param index The last index of the reserve
     **/
    event Mint(
        address indexed from,
        address indexed onBehalfOf,
        uint256 value,
        uint256 index
    );

    /**
     * @dev Mints debt token to the `onBehalfOf` address
     * @param user The address receiving the borrowed underlying, being the delegatee in case
     * of credit delegate, or same as `onBehalfOf` otherwise
     * @param onBehalfOf The address receiving the debt tokens
     * @param amount The amount of debt being minted
     * @param index The variable debt index of the reserve
     * @return `true` if the the previous balance of the user is 0
     **/
    function mint(
        address user,
        address onBehalfOf,
        uint256 amount,
        uint256 index
    ) external returns (bool);

    /**
     * @dev Emitted when variable debt is burnt
     * @param user The user which debt has been burned
     * @param amount The amount of debt being burned
     * @param index The index of the user
     **/
    event Burn(address indexed user, uint256 amount, uint256 index);

    /**
     * @dev Burns user variable debt
     * @param user The user which debt is burnt
     * @param index The variable debt index of the reserve
     **/
    function burn(
        address user,
        uint256 amount,
        uint256 index
    ) external;

    /**
     * @dev Returns the address of the incentives controller contract
     **/
    function getIncentivesController()
        external
        view
        returns (IAaveIncentivesController);

}

// SPDX-License-Identifier: agpl-3.0
pragma solidity >=0.8.0;

import {IERC20Detailed} from "../dependencies/openzeppelin/contracts/IERC20Detailed.sol";
import {ILendingPoolAddressesProvider} from "../interfaces/ILendingPoolAddressesProvider.sol";
import {ILendingPool} from "../interfaces/ILendingPool.sol";
import {IStableDebtToken} from "../interfaces/IStableDebtToken.sol";
import {IVariableDebtToken} from "../interfaces/IVariableDebtToken.sol";
import {ReserveConfiguration} from "../protocol/libraries/configuration/ReserveConfiguration.sol";
import {UserConfiguration} from "../protocol/libraries/configuration/UserConfiguration.sol";
import {DataTypes} from "../protocol/libraries/types/DataTypes.sol";
import {IERC20} from "../dependencies/openzeppelin/contracts/IERC20.sol";
import {SafeMath} from "../dependencies/openzeppelin/contracts/SafeMath.sol";
import {AssetMappings} from "../protocol/lendingpool/AssetMappings.sol";

contract AaveProtocolDataProvider {
    using SafeMath for uint256;
    using ReserveConfiguration for DataTypes.ReserveConfigurationMap;
    using UserConfiguration for DataTypes.UserConfigurationMap;

    address constant MKR = 0x9f8F72aA9304c8B593d555F12eF6589cC3A579A2;
    address constant ETH = 0xEeeeeEeeeEeEeeEeEeEeeEEEeeeeEeeeeeeeEEeE;

    struct TokenData {
        string symbol;
        address tokenAddress;
    }

    ILendingPoolAddressesProvider public immutable ADDRESSES_PROVIDER;

    constructor(ILendingPoolAddressesProvider addressesProvider) public {
        ADDRESSES_PROVIDER = addressesProvider;
    }

    function getAllReservesTokens(uint64 trancheId)
        external
        view
        returns (TokenData[] memory)
    {
        ILendingPool pool = ILendingPool(ADDRESSES_PROVIDER.getLendingPool());
        address[] memory reserves = pool.getReservesList(trancheId);
        TokenData[] memory reservesTokens = new TokenData[](reserves.length);
        for (uint256 i = 0; i < reserves.length; i++) {
            if (reserves[i] == MKR) {
                reservesTokens[i] = TokenData({
                    symbol: "MKR",
                    tokenAddress: reserves[i]
                });
                continue;
            }
            if (reserves[i] == ETH) {
                reservesTokens[i] = TokenData({
                    symbol: "ETH",
                    tokenAddress: reserves[i]
                });
                continue;
            }
            reservesTokens[i] = TokenData({
                symbol: IERC20Detailed(reserves[i]).symbol(),
                tokenAddress: reserves[i]
            });
        }
        return reservesTokens;
    }

    function getAllATokens(uint64 trancheId)
        external
        view
        returns (TokenData[] memory)
    {
        ILendingPool pool = ILendingPool(ADDRESSES_PROVIDER.getLendingPool());
        address[] memory reserves = pool.getReservesList(trancheId);
        TokenData[] memory aTokens = new TokenData[](reserves.length);
        for (uint256 i = 0; i < reserves.length; i++) {
            // uint64 trancheId = uint8(i % DataTypes.NUM_TRANCHES);
            DataTypes.ReserveData memory reserveData = pool.getReserveData(
                reserves[i],
                trancheId
            );

            assert(reserveData.trancheId == trancheId);

            aTokens[i] = TokenData({
                symbol: IERC20Detailed(reserveData.aTokenAddress).symbol(),
                tokenAddress: reserveData.aTokenAddress
            });
        }
        return aTokens;
    }

    struct CalculateUserAccountDataVars {
        uint64 currentTranche;
        uint256 reserveUnitPrice;
        uint256 tokenUnit;
        uint256 compoundedLiquidityBalance;
        uint256 compoundedBorrowBalance;
        uint256 decimals;
        uint256 ltv;
        uint256 liquidationThreshold;
        uint256 i;
        uint256 healthFactor;
        uint256 totalCollateralInETH;
        uint256 totalDebtInETH;
        uint256 avgLtv;
        uint256 avgLiquidationThreshold;
        uint256 reservesLength;
        bool healthFactorBelowThreshold;
        address currentReserveAddress;
        bool usageAsCollateralEnabled;
        bool userUsesReserveAsCollateral;
        uint256 liquidityBalanceETH;
    }

    struct getReserveConfigurationDataReturn {
            uint256 decimals;
            uint256 ltv;
            uint256 liquidationThreshold;
            uint256 liquidationBonus;
            uint256 reserveFactor;
            uint256 VMEXReserveFactor;
            uint256 supplyCap;
            uint256 borrowCap;
            uint256 borrowFactor;
            bool usageAsCollateralEnabled;
            bool borrowingEnabled;
            bool stableBorrowRateEnabled;
            bool isActive;
            bool isFrozen;
    }

    function getReserveConfigurationData(address asset, uint64 trancheId)
        external
        view
        returns (
            getReserveConfigurationDataReturn memory ret
        )
    {
        AssetMappings a = AssetMappings(ADDRESSES_PROVIDER.getAssetMappings());
        DataTypes.ReserveConfigurationMap memory configuration = ILendingPool(
            ADDRESSES_PROVIDER.getLendingPool()
        ).getConfiguration(asset, trancheId);

        (
            ret.ltv,
            ret.liquidationThreshold,
            ret.liquidationBonus,
            ret.decimals,
            ret.borrowFactor
        ) = a.getParams(asset);
        ret.supplyCap = a.getSupplyCap(asset);
        ret.borrowCap = a.getBorrowCap(asset);

        ret.reserveFactor = configuration.getReserveFactor();
        ret.VMEXReserveFactor = AssetMappings(ADDRESSES_PROVIDER.getAssetMappings()).getVMEXReserveFactor(asset);

        (
            ret.isActive,
            ret.isFrozen,
            ret.borrowingEnabled,
            ret.stableBorrowRateEnabled
        ) = configuration.getFlagsMemory();

        ret.usageAsCollateralEnabled =  configuration.getCollateralEnabled();//liquidationThreshold > 0;
    }

    function getReserveData(address asset, uint64 trancheId)
        external
        view
        returns (
            uint256 availableLiquidity,
            uint256 totalSupplied,
            uint256 totalVariableDebt,
            uint256 liquidityRate,
            uint256 variableBorrowRate,
            uint256 liquidityIndex,
            uint256 variableBorrowIndex,
            uint40 lastUpdateTimestamp
        )
    {
        DataTypes.ReserveData memory reserve = ILendingPool(
            ADDRESSES_PROVIDER.getLendingPool()
        ).getReserveData(asset, trancheId);

        return (
            IERC20Detailed(asset).balanceOf(reserve.aTokenAddress),
            IERC20Detailed(reserve.aTokenAddress).totalSupply(),
            IERC20Detailed(reserve.variableDebtTokenAddress).totalSupply(),
            reserve.currentLiquidityRate,
            reserve.currentVariableBorrowRate,
            reserve.liquidityIndex,
            reserve.variableBorrowIndex,
            reserve.lastUpdateTimestamp
        );
    }

    function getUserReserveData(
        address asset,
        uint64 trancheId,
        address user
    )
        external
        view
        returns (
            uint256 currentATokenBalance,
            uint256 currentVariableDebt,
            uint256 scaledVariableDebt,
            uint256 liquidityRate,
            bool usageAsCollateralEnabled
        )
    {
        DataTypes.ReserveData memory reserve = ILendingPool(
            ADDRESSES_PROVIDER.getLendingPool()
        ).getReserveData(asset, trancheId);

        DataTypes.UserConfigurationMap memory userConfig = ILendingPool(
            ADDRESSES_PROVIDER.getLendingPool()
        ).getUserConfiguration(user, trancheId);

        currentATokenBalance = IERC20Detailed(reserve.aTokenAddress).balanceOf(
            user
        );
        currentVariableDebt = IERC20Detailed(reserve.variableDebtTokenAddress)
            .balanceOf(user);
        scaledVariableDebt = IVariableDebtToken(
            reserve.variableDebtTokenAddress
        ).scaledBalanceOf(user);
        liquidityRate = reserve.currentLiquidityRate;
        usageAsCollateralEnabled = userConfig.isUsingAsCollateral(reserve.id);
    }

    function getReserveTokensAddresses(address asset, uint64 trancheId)
        external
        view
        returns (
            address aTokenAddress,
            address variableDebtTokenAddress
        )
    {
        DataTypes.ReserveData memory reserve = ILendingPool(
            ADDRESSES_PROVIDER.getLendingPool()
        ).getReserveData(asset, trancheId);

        return (
            reserve.aTokenAddress,
            reserve.variableDebtTokenAddress
        );
    }
}

// SPDX-License-Identifier: agpl-3.0
pragma solidity >=0.8.0;

interface IWETH {
    function deposit() external payable;

    function withdraw(uint256) external;

    function approve(address guy, uint256 wad) external returns (bool);

    function transferFrom(
        address src,
        address dst,
        uint256 wad
    ) external returns (bool);
}

// SPDX-License-Identifier: agpl-3.0
pragma solidity >=0.8.0;

interface IWETHGateway {
    function depositETH(
        address lendingPool,
        uint64 trancheId,
        address onBehalfOf,
        uint16 referralCode
    ) external payable;

    function withdrawETH(
        address lendingPool,
        uint64 trancheId,
        uint256 amount,
        address onBehalfOf
    ) external;

    function repayETH(
        address lendingPool,
        uint64 trancheId,
        uint256 amount,
        address onBehalfOf
    ) external payable;

    function borrowETH(
        address lendingPool,
        uint64 trancheId,
        uint256 amount,
        uint16 referralCode
    ) external;
}

// SPDX-License-Identifier: agpl-3.0
pragma solidity >=0.8.0;

import {Address} from "../dependencies/openzeppelin/contracts/Address.sol";
import {IERC20} from "../dependencies/openzeppelin/contracts/IERC20.sol";

import {ILendingPoolAddressesProvider} from "../interfaces/ILendingPoolAddressesProvider.sol";
import {ILendingPool} from "../interfaces/ILendingPool.sol";
import {SafeERC20} from "../dependencies/openzeppelin/contracts/SafeERC20.sol";
import {ReserveConfiguration} from "../protocol/libraries/configuration/ReserveConfiguration.sol";
import {DataTypes} from "../protocol/libraries/types/DataTypes.sol";

/**
 * @title WalletBalanceProvider contract
 * @author Aave, influenced by https://github.com/wbobeirne/eth-balance-checker/blob/master/contracts/BalanceChecker.sol
 * @notice Implements a logic of getting multiple tokens balance for one user address
 * @dev NOTE: THIS CONTRACT IS NOT USED WITHIN THE AAVE PROTOCOL. It's an accessory contract used to reduce the number of calls
 * towards the blockchain from the Aave backend.
 **/
contract WalletBalanceProvider {
    using Address for address payable;
    using Address for address;
    using SafeERC20 for IERC20;
    using ReserveConfiguration for DataTypes.ReserveConfigurationMap;

    address constant MOCK_ETH_ADDRESS =
        0xEeeeeEeeeEeEeeEeEeEeeEEEeeeeEeeeeeeeEEeE;

    /**
    @dev Fallback function, don't accept any ETH
    **/
    receive() external payable {
        //only contracts can send ETH to the core
        require(msg.sender.isContract(), "22");
    }

    /**
    @dev Check the token balance of a wallet in a token contract

    Returns the balance of the token for user. Avoids possible errors:
      - return 0 on non-contract address
    **/
    function balanceOf(address user, address token)
        public
        view
        returns (uint256)
    {
        if (token == MOCK_ETH_ADDRESS) {
            return user.balance; // ETH balance
            // check if token is actually a contract
        } else if (token.isContract()) {
            return IERC20(token).balanceOf(user);
        }
        revert("INVALID_TOKEN");
    }

    /**
     * @notice Fetches, for a list of _users and _tokens (ETH included with mock address), the balances
     * @param users The list of users
     * @param tokens The list of tokens
     * @return And array with the concatenation of, for each user, his/her balances
     **/
    function batchBalanceOf(address[] calldata users, address[] calldata tokens)
        external
        view
        returns (uint256[] memory)
    {
        uint256[] memory balances = new uint256[](users.length * tokens.length);

        for (uint256 i = 0; i < users.length; i++) {
            for (uint256 j = 0; j < tokens.length; j++) {
                balances[i * tokens.length + j] = balanceOf(
                    users[i],
                    tokens[j]
                );
            }
        }

        return balances;
    }

    /**
    @dev provides balances of user wallet for all reserves available on the pool
    */
    function getUserWalletBalances(
        address provider,
        address user,
        uint64 trancheId
    ) external view returns (address[] memory, uint256[] memory) {
        ILendingPool pool = ILendingPool(
            ILendingPoolAddressesProvider(provider).getLendingPool()
        );

        address[] memory reserves = pool.getReservesList(trancheId);
        address[] memory reservesWithEth = new address[](reserves.length + 1);
        for (uint256 i = 0; i < reserves.length; i++) {
            reservesWithEth[i] = reserves[i];
        }
        reservesWithEth[reserves.length] = MOCK_ETH_ADDRESS;

        uint256[] memory balances = new uint256[](reservesWithEth.length);

        for (uint256 j = 0; j < reserves.length; j++) {
            // uint64 trancheId = uint8(j % DataTypes.NUM_TRANCHES);
            DataTypes.ReserveConfigurationMap memory configuration = pool
                .getConfiguration(reservesWithEth[j], trancheId);

            (bool isActive, , , ) = configuration.getFlagsMemory();

            if (!isActive) {
                balances[j] = 0;
                continue;
            }
            balances[j] = balanceOf(user, reservesWithEth[j]);
        }
        balances[reserves.length] = balanceOf(user, MOCK_ETH_ADDRESS);

        return (reservesWithEth, balances);
    }
}

// SPDX-License-Identifier: agpl-3.0
pragma solidity >=0.8.0;

import {Ownable} from "../dependencies/openzeppelin/contracts/Ownable.sol";
import {IERC20} from "../dependencies/openzeppelin/contracts/IERC20.sol";
import {IWETH} from "./interfaces/IWETH.sol";
import {IWETHGateway} from "./interfaces/IWETHGateway.sol";
import {ILendingPool} from "../interfaces/ILendingPool.sol";
import {IAToken} from "../interfaces/IAToken.sol";
import {ReserveConfiguration} from "../protocol/libraries/configuration/ReserveConfiguration.sol";
import {UserConfiguration} from "../protocol/libraries/configuration/UserConfiguration.sol";
import {Helpers} from "../protocol/libraries/helpers/Helpers.sol";
import {DataTypes} from "../protocol/libraries/types/DataTypes.sol";

contract WETHGateway is IWETHGateway, Ownable {
    using ReserveConfiguration for DataTypes.ReserveConfigurationMap;
    using UserConfiguration for DataTypes.UserConfigurationMap;

    IWETH internal immutable WETH;

    /**
     * @dev Sets the WETH address and the LendingPoolAddressesProvider address. Infinite approves lending pool.
     * @param weth Address of the Wrapped Ether contract
     **/
    constructor(address weth) public {
        WETH = IWETH(weth);
    }

    function authorizeLendingPool(address lendingPool) external onlyOwner {
        WETH.approve(lendingPool, type(uint256).max);
    }

    /**
     * @dev deposits WETH into the reserve, using native ETH. A corresponding amount of the overlying asset (aTokens)
     * is minted.
     * @param lendingPool address of the targeted underlying lending pool
     * @param onBehalfOf address of the user who will receive the aTokens representing the deposit
     * @param referralCode integrators are assigned a referral code and can potentially receive rewards.
     **/
    function depositETH(
        address lendingPool,
        uint64 trancheId,
        address onBehalfOf,
        uint16 referralCode
    ) external payable override {
        WETH.deposit{value: msg.value}();
        ILendingPool(lendingPool).deposit(
            address(WETH),
            trancheId,
            msg.value,
            onBehalfOf,
            referralCode
        );
    }

    /**
     * @dev withdraws the WETH _reserves of msg.sender.
     * @param lendingPool address of the targeted underlying lending pool
     * @param amount amount of aWETH to withdraw and receive native ETH
     * @param to address of the user who will receive native ETH
     */
    function withdrawETH(
        address lendingPool,
        uint64 trancheId,
        uint256 amount,
        address to
    ) external override {
        IAToken aWETH = IAToken(
            ILendingPool(lendingPool)
                .getReserveData(address(WETH), trancheId)
                .aTokenAddress
        );
        uint256 userBalance = aWETH.balanceOf(msg.sender);
        uint256 amountToWithdraw = amount;

        // if amount is equal to type(uint256).max, the user wants to redeem everything
        if (amount == type(uint256).max) {
            amountToWithdraw = userBalance;
        }
        aWETH.transferFrom(msg.sender, address(this), amountToWithdraw);
        ILendingPool(lendingPool).withdraw(
            address(WETH),
            trancheId,
            amountToWithdraw,
            address(this)
        );
        WETH.withdraw(amountToWithdraw);
        _safeTransferETH(to, amountToWithdraw);
    }

    /**
     * @dev repays a borrow on the WETH reserve, for the specified amount (or for the whole amount, if type(uint256).max is specified).
     * @param lendingPool address of the targeted underlying lending pool
     * @param trancheId trancheId to repay ETH to
     * @param amount the amount to repay, or type(uint256).max if the user wants to repay everything
     * @param onBehalfOf the address for which msg.sender is repaying
     */
    function repayETH(
        address lendingPool,
        uint64 trancheId,
        uint256 amount,
        address onBehalfOf
    ) external payable override {
        uint256 variableDebt = Helpers
            .getUserCurrentDebtMemory(
                onBehalfOf,
                ILendingPool(lendingPool).getReserveData(
                    address(WETH),
                    trancheId
                )
            );

        uint256 paybackAmount = variableDebt;

        if (amount < paybackAmount) {
            paybackAmount = amount;
        }
        require(
            msg.value >= paybackAmount,
            "msg.value is less than repayment amount"
        );
        WETH.deposit{value: paybackAmount}();
        ILendingPool(lendingPool).repay(
            address(WETH),
            trancheId,
            msg.value,
            onBehalfOf
        );

        // refund remaining dust eth
        if (msg.value > paybackAmount)
            _safeTransferETH(msg.sender, msg.value - paybackAmount);
    }

    /**
     * @dev borrow WETH, unwraps to ETH and send both the ETH and DebtTokens to msg.sender, via `approveDelegation` and onBehalf argument in `LendingPool.borrow`.
     * @param lendingPool address of the targeted underlying lending pool
     * @param trancheId trancheId of the targeted underlying lending pool
     * @param amount the amount of ETH to borrow
     * @param referralCode integrators are assigned a referral code and can potentially receive rewards
     */
    function borrowETH(
        address lendingPool,
        uint64 trancheId,
        uint256 amount,
        uint16 referralCode
    ) external override {
        ILendingPool(lendingPool).borrow(
            address(WETH),
            trancheId,
            amount,
            referralCode,
            msg.sender
        );
        WETH.withdraw(amount);
        _safeTransferETH(msg.sender, amount);
    }

    /**
     * @dev transfer ETH to an address, revert if it fails.
     * @param to recipient of the transfer
     * @param value the amount to send
     */
    function _safeTransferETH(address to, uint256 value) internal {
        (bool success, ) = to.call{value: value}(new bytes(0));
        require(success, "ETH_TRANSFER_FAILED");
    }

    /**
     * @dev transfer ERC20 from the utility contract, for ERC20 recovery in case of stuck tokens due
     * direct transfers to the contract address.
     * @param token token to transfer
     * @param to recipient of the transfer
     * @param amount amount to send
     */
    function emergencyTokenTransfer(
        address token,
        address to,
        uint256 amount
    ) external onlyOwner {
        IERC20(token).transfer(to, amount);
    }

    /**
     * @dev transfer native Ether from the utility contract, for native Ether recovery in case of stuck Ether
     * due selfdestructs or transfer ether to pre-computated contract address before deployment.
     * @param to recipient of the transfer
     * @param amount amount to send
     */
    function emergencyEtherTransfer(address to, uint256 amount)
        external
        onlyOwner
    {
        _safeTransferETH(to, amount);
    }

    /**
     * @dev Get WETH address used by WETHGateway
     */
    function getWETHAddress() external view returns (address) {
        return address(WETH);
    }

    /**
     * @dev Only WETH contract is allowed to transfer ETH here. Prevent other addresses to send Ether to this contract.
     */
    receive() external payable {
        require(msg.sender == address(WETH), "Receive not allowed");
    }

    /**
     * @dev Revert fallback calls
     */
    fallback() external payable {
        revert("Fallback not allowed");
    }
}

// SPDX-License-Identifier: agpl-3.0
pragma solidity >=0.8.0;

import {SafeMath} from "../../dependencies/openzeppelin/contracts/SafeMath.sol";
import {IERC20} from "../../dependencies/openzeppelin/contracts/IERC20.sol";

import {FlashLoanReceiverBase} from "../../flashloan/base/FlashLoanReceiverBase.sol";
import {MintableERC20} from "../tokens/MintableERC20.sol";
import {SafeERC20} from "../../dependencies/openzeppelin/contracts/SafeERC20.sol";
import {ILendingPoolAddressesProvider} from "../../interfaces/ILendingPoolAddressesProvider.sol";
import {DataTypes} from "../../protocol/libraries/types/DataTypes.sol";

contract MockFlashLoanReceiver is FlashLoanReceiverBase {
    using SafeERC20 for IERC20;
    using SafeMath for uint256;

    ILendingPoolAddressesProvider internal _provider;

    event ExecutedWithFail(
        address[] _assets,
        uint256[] _amounts,
        uint256[] _premiums
    );
    event ExecutedWithSuccess(
        address[] _assets,
        uint256[] _amounts,
        uint256[] _premiums
    );

    bool _failExecution;
    uint256 _amountToApprove;
    bool _simulateEOA;

    constructor(ILendingPoolAddressesProvider provider)
        public
        FlashLoanReceiverBase(provider)
    {}

    function setFailExecutionTransfer(bool fail) public {
        _failExecution = fail;
    }

    function setAmountToApprove(uint256 amountToApprove) public {
        _amountToApprove = amountToApprove;
    }

    function setSimulateEOA(bool flag) public {
        _simulateEOA = flag;
    }

    function amountToApprove() public view returns (uint256) {
        return _amountToApprove;
    }

    function simulateEOA() public view returns (bool) {
        return _simulateEOA;
    }

    // function _getAddresses(DataTypes.TrancheAddress[] memory assets)
    //     private
    //     pure
    //     returns (address[] memory)
    // {
    //     uint256 len = assets.length;
    //     address[] memory ret = new address[](len);
    //     for (uint256 i = 0; i < len; i++) {
    //         ret[i] = assets[i].asset;
    //     }
    //     return ret;
    // }

    //TODO: TRANCHES NEED TO BE USED HERE
    function executeOperation(
        address[] memory assets,
        uint256[] memory amounts,
        uint256[] memory premiums,
        address initiator,
        bytes memory params
    ) public override returns (bool) {
        params;
        initiator;

        if (_failExecution) {
            emit ExecutedWithFail((assets), amounts, premiums);
            return !_simulateEOA;
        }

        for (uint256 i = 0; i < assets.length; i++) {
            //mint to this contract the specific amount
            MintableERC20 token = MintableERC20(assets[i]);

            //check the contract has the specified balance
            require(
                amounts[i] <= IERC20(assets[i]).balanceOf(address(this)),
                "Invalid balance for the contract"
            );

            uint256 amountToReturn = (_amountToApprove != 0)
                ? _amountToApprove
                : amounts[i].add(premiums[i]);
            //execution does not fail - mint tokens and return them to the _destination

            token.mint(premiums[i]);

            IERC20(assets[i]).approve(address(LENDING_POOL), amountToReturn);
        }

        emit ExecutedWithSuccess((assets), amounts, premiums);

        return true;
    }
}

// SPDX-License-Identifier: agpl-3.0
pragma solidity >=0.8.0;

import {ERC20} from "../../dependencies/openzeppelin/contracts/ERC20.sol";

/**
 * @title ERC20Mintable
 * @dev ERC20 minting logic
 */
contract MintableERC20 is ERC20 {
    constructor(
        string memory name,
        string memory symbol,
        uint8 decimals
    ) public ERC20(name, symbol) {
        _setupDecimals(decimals);
    }

    /**
     * @dev Function to mint tokens
     * @param value The amount of tokens to mint.
     * @return A boolean that indicates if the operation was successful.
     */
    function mint(uint256 value) public returns (bool) {
        _mint(_msgSender(), value);
        return true;
    }
}

// SPDX-License-Identifier: agpl-3.0
pragma solidity >=0.8.0;

import {AToken} from "../../protocol/tokenization/AToken.sol";
import {ILendingPool} from "../../interfaces/ILendingPool.sol";
import {
    IAaveIncentivesController
} from "../../interfaces/IAaveIncentivesController.sol";

contract MockAToken is AToken {
    function getRevision() internal pure override returns (uint256) {
        return 0x2;
    }
}

// SPDX-License-Identifier: agpl-3.0
pragma solidity >=0.8.0;

import {StableDebtToken} from "../../protocol/tokenization/StableDebtToken.sol";

contract MockStableDebtToken is StableDebtToken {
    function getRevision() internal pure override returns (uint256) {
        return 0x2;
    }
}

// SPDX-License-Identifier: agpl-3.0
pragma solidity >=0.8.0;

import {CrvLpStrategy} from "../../protocol/strategies/strats/CrvLpStrategy.sol";
import {ILendingPool} from "../../interfaces/ILendingPool.sol";
import {
    IAaveIncentivesController
} from "../../interfaces/IAaveIncentivesController.sol";

contract MockStrategy is CrvLpStrategy {
    function baseStrategyVersion()
        external
        pure
        override
        returns (string memory)
    {
        return "2.0";
    }
}

// SPDX-License-Identifier: agpl-3.0
pragma solidity >=0.8.0;

import {
    VariableDebtToken
} from "../../protocol/tokenization/VariableDebtToken.sol";

contract MockVariableDebtToken is VariableDebtToken {
    function getRevision() internal pure override returns (uint256) {
        return 0x2;
    }
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity >=0.8.0; 

import {ICurvePool} from "./interfaces/ICurvePoolV1.sol"; 
import {ICurveOracle} from "./interfaces/ICurveOracle.sol"; 
import {vMath} from "./libs/vMath.sol"; 

//used for all curveV1 amd V2 tokens, no need to redeploy
library CurveOracle {
	
	//where total supply is the total supply of the LP token in the pools calculated using the virtual price
	function get_price_v1(address curve_pool, uint256[] memory prices) internal view returns(uint256) {
		uint256 virtual_price = ICurvePool(curve_pool).get_virtual_price(); 
		
		uint256 lp_price = calculate_v1_token_price(
			virtual_price,
			prices
		);	
		
		return lp_price; 	
		
	}

	//where virtual price is the price of the pool in USD
	//returns lp_value = virtual price x min(prices); 
	function calculate_v1_token_price(
		uint256 virtual_price,
		uint256[] memory prices
	) public pure returns(uint256) {

		uint256 min = vMath.min(prices); 
		return (virtual_price * min) / 1e18; 
	}

	function get_price_v2(address curve_pool, uint256[] memory prices) internal view returns(uint256) {
		uint256 virtual_price = ICurvePool(curve_pool).get_virtual_price(); 

		uint256 lp_price = calculate_v2_token_price(
			uint8(prices.length),
			virtual_price,
			prices
		);	
		
		return lp_price; 	
		
	}
	
	//returns n_token * vp * (p1 * p2 * p3) ^1/n	
	//n should only ever be 2 or 3 for v2 pools
	//returns the lp_price scaled by 1e36, so scale down by 1e36
	function calculate_v2_token_price(
		uint8 n,
		uint256 virtual_price,
		uint256[] memory prices	
	) internal pure returns(uint256) {
		uint256 product = vMath.product(prices); 
		uint256 geo_mean = vMath.geometric_mean(n, product); 
		return (n * virtual_price * geo_mean) / 1e18; 
	}

}

pragma solidity >=0.8.0;

interface ICurveOracle {
    function get_price(address curve_pool, uint256[] memory prices)
        external
        view
        returns (uint256);
}

pragma solidity >=0.8.0; 


interface ICurvePool {

	function get_virtual_price() external view returns(uint256); 
	function coins(uint256 n) external view returns(address); 

}

// SPDX-License-Identifier: UNLICENSED
pragma solidity >=0.8.0; 


interface IYearnToken {
	
	function totalAssets() external view returns(uint256); 
	function totalSupply() external view returns(uint256); 
	function pricePerShare() external view returns(uint256);
	function token() external view returns(address);
	function decimals() external view returns(uint256);
}

// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity >=0.8.0;

/// @notice Arithmetic library with operations for fixed-point numbers.
/// @author Solmate (https://github.com/Rari-Capital/solmate/blob/main/src/utils/FixedPointMathLib.sol)
/// @author Inspired by USM (https://github.com/usmfum/USM/blob/master/contracts/WadMath.sol)
library FixedPointMathLib {
    /*//////////////////////////////////////////////////////////////
                    SIMPLIFIED FIXED POINT OPERATIONS
    //////////////////////////////////////////////////////////////*/

    uint256 internal constant WAD = 1e18; // The scalar of ETH and most ERC20s.

    function mulWadDown(uint256 x, uint256 y) internal pure returns (uint256) {
        return mulDivDown(x, y, WAD); // Equivalent to (x * y) / WAD rounded down.
    }

    function mulWadUp(uint256 x, uint256 y) internal pure returns (uint256) {
        return mulDivUp(x, y, WAD); // Equivalent to (x * y) / WAD rounded up.
    }

    function divWadDown(uint256 x, uint256 y) internal pure returns (uint256) {
        return mulDivDown(x, WAD, y); // Equivalent to (x * WAD) / y rounded down.
    }

    function divWadUp(uint256 x, uint256 y) internal pure returns (uint256) {
        return mulDivUp(x, WAD, y); // Equivalent to (x * WAD) / y rounded up.
    }

    /*//////////////////////////////////////////////////////////////
                    LOW LEVEL FIXED POINT OPERATIONS
    //////////////////////////////////////////////////////////////*/

    function mulDivDown(
        uint256 x,
        uint256 y,
        uint256 denominator
    ) internal pure returns (uint256 z) {
        assembly {
            // Store x * y in z for now.
            z := mul(x, y)

            // Equivalent to require(denominator != 0 && (x == 0 || (x * y) / x == y))
            if iszero(
                and(
                    iszero(iszero(denominator)),
                    or(iszero(x), eq(div(z, x), y))
                )
            ) {
                revert(0, 0)
            }

            // Divide z by the denominator.
            z := div(z, denominator)
        }
    }

    function mulDivUp(
        uint256 x,
        uint256 y,
        uint256 denominator
    ) internal pure returns (uint256 z) {
        assembly {
            // Store x * y in z for now.
            z := mul(x, y)

            // Equivalent to require(denominator != 0 && (x == 0 || (x * y) / x == y))
            if iszero(
                and(
                    iszero(iszero(denominator)),
                    or(iszero(x), eq(div(z, x), y))
                )
            ) {
                revert(0, 0)
            }

            // First, divide z - 1 by the denominator and add 1.
            // We allow z - 1 to underflow if z is 0, because we multiply the
            // end result by 0 if z is zero, ensuring we return 0 if z is zero.
            z := mul(iszero(iszero(z)), add(div(sub(z, 1), denominator), 1))
        }
    }

    function rpow(
        uint256 x,
        uint256 n,
        uint256 scalar
    ) internal pure returns (uint256 z) {
        assembly {
            switch x
            case 0 {
                switch n
                case 0 {
                    // 0 ** 0 = 1
                    z := scalar
                }
                default {
                    // 0 ** n = 0
                    z := 0
                }
            }
            default {
                switch mod(n, 2)
                case 0 {
                    // If n is even, store scalar in z for now.
                    z := scalar
                }
                default {
                    // If n is odd, store x in z for now.
                    z := x
                }

                // Shifting right by 1 is like dividing by 2.
                let half := shr(1, scalar)

                for {
                    // Shift n right by 1 before looping to halve it.
                    n := shr(1, n)
                } n {
                    // Shift n right by 1 each iteration to halve it.
                    n := shr(1, n)
                } {
                    // Revert immediately if x ** 2 would overflow.
                    // Equivalent to iszero(eq(div(xx, x), x)) here.
                    if shr(128, x) {
                        revert(0, 0)
                    }

                    // Store x squared.
                    let xx := mul(x, x)

                    // Round to the nearest number.
                    let xxRound := add(xx, half)

                    // Revert if xx + half overflowed.
                    if lt(xxRound, xx) {
                        revert(0, 0)
                    }

                    // Set x to scaled xxRound.
                    x := div(xxRound, scalar)

                    // If n is even:
                    if mod(n, 2) {
                        // Compute z * x.
                        let zx := mul(z, x)

                        // If z * x overflowed:
                        if iszero(eq(div(zx, x), z)) {
                            // Revert if x is non-zero.
                            if iszero(iszero(x)) {
                                revert(0, 0)
                            }
                        }

                        // Round to the nearest number.
                        let zxRound := add(zx, half)

                        // Revert if zx + half overflowed.
                        if lt(zxRound, zx) {
                            revert(0, 0)
                        }

                        // Return properly scaled zxRound.
                        z := div(zxRound, scalar)
                    }
                }
            }
        }
    }

    /*//////////////////////////////////////////////////////////////
                        GENERAL NUMBER UTILITIES
    //////////////////////////////////////////////////////////////*/

    function sqrt(uint256 x) internal pure returns (uint256 z) {
        assembly {
            // Start off with z at 1.
            z := 1

            // Used below to help find a nearby power of 2.
            let y := x

            // Find the lowest power of 2 that is at least sqrt(x).
            if iszero(lt(y, 0x100000000000000000000000000000000)) {
                y := shr(128, y) // Like dividing by 2 ** 128.
                z := shl(64, z) // Like multiplying by 2 ** 64.
            }
            if iszero(lt(y, 0x10000000000000000)) {
                y := shr(64, y) // Like dividing by 2 ** 64.
                z := shl(32, z) // Like multiplying by 2 ** 32.
            }
            if iszero(lt(y, 0x100000000)) {
                y := shr(32, y) // Like dividing by 2 ** 32.
                z := shl(16, z) // Like multiplying by 2 ** 16.
            }
            if iszero(lt(y, 0x10000)) {
                y := shr(16, y) // Like dividing by 2 ** 16.
                z := shl(8, z) // Like multiplying by 2 ** 8.
            }
            if iszero(lt(y, 0x100)) {
                y := shr(8, y) // Like dividing by 2 ** 8.
                z := shl(4, z) // Like multiplying by 2 ** 4.
            }
            if iszero(lt(y, 0x10)) {
                y := shr(4, y) // Like dividing by 2 ** 4.
                z := shl(2, z) // Like multiplying by 2 ** 2.
            }
            if iszero(lt(y, 0x8)) {
                // Equivalent to 2 ** z.
                z := shl(1, z)
            }

            // Shifting right by 1 is like dividing by 2.
            z := shr(1, add(z, div(x, z)))
            z := shr(1, add(z, div(x, z)))
            z := shr(1, add(z, div(x, z)))
            z := shr(1, add(z, div(x, z)))
            z := shr(1, add(z, div(x, z)))
            z := shr(1, add(z, div(x, z)))
            z := shr(1, add(z, div(x, z)))

            // Compute a rounded down version of z.
            let zRoundDown := div(x, z)

            // If zRoundDown is smaller, use it.
            if lt(zRoundDown, z) {
                z := zRoundDown
            }
        }
    }
}

// SPDX-License-Identifier: SEE LICENSE IN LICENSE
pragma solidity >=0.8.0;

import "./Uint.sol";

library IntegralMath {
    /**
     * @dev Compute the largest integer smaller than or equal to the binary logarithm of `n`
     */
    function floorLog2(uint256 n) internal pure returns (uint8) {
        unchecked {
            uint8 res = 0;

            if (n < 256) {
                // at most 8 iterations
                while (n > 1) {
                    n >>= 1;
                    res += 1;
                }
            } else {
                // exactly 8 iterations
                for (uint8 s = 128; s > 0; s >>= 1) {
                    if (n >= 1 << s) {
                        n >>= s;
                        res |= s;
                    }
                }
            }

            return res;
        }
    }

    /**
     * @dev Compute the largest integer smaller than or equal to the square root of `n`
     */
    function floorSqrt(uint256 n) internal pure returns (uint256) {
        unchecked {
            if (n > 0) {
                uint256 x = n / 2 + 1;
                uint256 y = (x + n / x) / 2;
                while (x > y) {
                    x = y;
                    y = (x + n / x) / 2;
                }
                return x;
            }
            return 0;
        }
    }

    /**
     * @dev Compute the smallest integer larger than or equal to the square root of `n`
     */
    function ceilSqrt(uint256 n) internal pure returns (uint256) {
        unchecked {
            uint256 x = floorSqrt(n);
            return x**2 == n ? x : x + 1;
        }
    }

    /**
     * @dev Compute the largest integer smaller than or equal to the cubic root of `n`
     */
    function floorCbrt(uint256 n) internal pure returns (uint256) {
        unchecked {
            uint256 x = 0;
            for (uint256 y = 1 << 255; y > 0; y >>= 3) {
                x <<= 1;
                uint256 z = 3 * x * (x + 1) + 1;
                if (n / y >= z) {
                    n -= y * z;
                    x += 1;
                }
            }
            return x;
        }
    }

    /**
     * @dev Compute the smallest integer larger than or equal to the cubic root of `n`
     */
    function ceilCbrt(uint256 n) internal pure returns (uint256) {
        unchecked {
            uint256 x = floorCbrt(n);
            return x**3 == n ? x : x + 1;
        }
    }

    /**
     * @dev Compute the nearest integer to the quotient of `n` and `d` (or `n / d`)
     */
    function roundDiv(uint256 n, uint256 d) internal pure returns (uint256) {
        unchecked {
            return n / d + (n % d) / (d - d / 2);
        }
    }

    /**
     * @dev Compute the largest integer smaller than or equal to `x * y / z`
     */
    function mulDivF(
        uint256 x,
        uint256 y,
        uint256 z
    ) internal pure returns (uint256) {
        unchecked {
            (uint256 xyh, uint256 xyl) = mul512(x, y);
            if (xyh == 0) {
                // `x * y < 2 ^ 256`
                return xyl / z;
            }
            if (xyh < z) {
                // `x * y / z < 2 ^ 256`
                uint256 m = mulMod(x, y, z); // `m = x * y % z`
                (uint256 nh, uint256 nl) = sub512(xyh, xyl, m); // `n = x * y - m` hence `n / z = floor(x * y / z)`
                if (nh == 0) {
                    // `n < 2 ^ 256`
                    return nl / z;
                }
                uint256 p = unsafeSub(0, z) & z; // `p` is the largest power of 2 which `z` is divisible by
                uint256 q = div512(nh, nl, p); // `n` is divisible by `p` because `n` is divisible by `z` and `z` is divisible by `p`
                uint256 r = inv256(z / p); // `z / p = 1 mod 2` hence `inverse(z / p) = 1 mod 2 ^ 256`
                return unsafeMul(q, r); // `q * r = (n / p) * inverse(z / p) = n / z`
            }
            revert(); // `x * y / z >= 2 ^ 256`
        }
    }

    /**
     * @dev Compute the smallest integer larger than or equal to `x * y / z`
     */
    function mulDivC(
        uint256 x,
        uint256 y,
        uint256 z
    ) internal pure returns (uint256) {
        unchecked {
            uint256 w = mulDivF(x, y, z);
            if (mulMod(x, y, z) > 0) return safeAdd(w, 1);
            return w;
        }
    }

    /**
     * @dev Compute the value of `x * y`
     */
    function mul512(uint256 x, uint256 y)
        private
        pure
        returns (uint256, uint256)
    {
        unchecked {
            uint256 p = mulModMax(x, y);
            uint256 q = unsafeMul(x, y);
            if (p >= q) return (p - q, q);
            return (unsafeSub(p, q) - 1, q);
        }
    }

    /**
     * @dev Compute the value of `2 ^ 256 * xh + xl - y`, where `2 ^ 256 * xh + xl >= y`
     */
    function sub512(
        uint256 xh,
        uint256 xl,
        uint256 y
    ) private pure returns (uint256, uint256) {
        unchecked {
            if (xl >= y) return (xh, xl - y);
            return (xh - 1, unsafeSub(xl, y));
        }
    }

    /**
     * @dev Compute the value of `(2 ^ 256 * xh + xl) / pow2n`, where `xl` is divisible by `pow2n`
     */
    function div512(
        uint256 xh,
        uint256 xl,
        uint256 pow2n
    ) private pure returns (uint256) {
        unchecked {
            uint256 pow2nInv = unsafeAdd(unsafeSub(0, pow2n) / pow2n, 1); // `1 << (256 - n)`
            return unsafeMul(xh, pow2nInv) | (xl / pow2n); // `(xh << (256 - n)) | (xl >> n)`
        }
    }

    /**
     * @dev Compute the inverse of `d` modulo `2 ^ 256`, where `d` is congruent to `1` modulo `2`
     */
    function inv256(uint256 d) private pure returns (uint256) {
        unchecked {
            // approximate the root of `f(x) = 1 / x - d` using the newton–raphson convergence method
            uint256 x = 1;
            for (uint256 i = 0; i < 8; ++i)
                x = unsafeMul(x, unsafeSub(2, unsafeMul(x, d))); // `x = x * (2 - x * d) mod 2 ^ 256`
            return x;
        }
    }
}

// SPDX-License-Identifier: SEE LICENSE IN LICENSE
pragma solidity >=0.8.0;

uint256 constant MAX_VAL = type(uint256).max;

// reverts on overflow
function safeAdd(uint256 x, uint256 y) pure returns (uint256) {
    return x + y;
}

// does not revert on overflow
function unsafeAdd(uint256 x, uint256 y) pure returns (uint256) {
    unchecked {
        return x + y;
    }
}

// does not revert on overflow
function unsafeSub(uint256 x, uint256 y) pure returns (uint256) {
    unchecked {
        return x - y;
    }
}

// does not revert on overflow
function unsafeMul(uint256 x, uint256 y) pure returns (uint256) {
    unchecked {
        return x * y;
    }
}

// does not overflow
function mulModMax(uint256 x, uint256 y) pure returns (uint256) {
    unchecked {
        return mulmod(x, y, MAX_VAL);
    }
}

// does not overflow
function mulMod(
    uint256 x,
    uint256 y,
    uint256 z
) pure returns (uint256) {
    unchecked {
        return mulmod(x, y, z);
    }
}

pragma solidity >=0.8.0; 

import {FixedPointMathLib} from "./FixedPointMathLib.sol"; 
import {IntegralMath} from "./IntegralMath.sol"; 

library vMath {

    uint256 internal constant WAD = 1e18; // The scalar of ETH and most ERC20s.
	
	function min(uint256[] memory array) internal pure returns(uint256) {
		uint256 min = array[0]; 
		for (uint8 i = 1; i < array.length; i++) {
			if (min > array[i]) {
				min = array[i]; 
			}	
		}
		return min; 
	}

	function product(uint256[] memory nums) internal pure returns(uint256) {
		uint256 product = nums[0]; 
		for (uint256 i = 1; i < nums.length; i++) {
			product *= nums[i]; 
		}
		return product; 
	}
	
	//limited to curve pools only, either 2 or 3 assets (mostly 2) 
	function geometric_mean(uint8 n, uint256 product) internal pure returns(uint256) {
		if (n == 2) {
			return FixedPointMathLib.sqrt(product); 
		} else { //n == 3
			return IntegralMath.floorCbrt(product); 
		}
	}

}

// SPDX-License-Identifier: agpl-3.0
pragma solidity >=0.8.0;

import {Ownable} from "../dependencies/openzeppelin/contracts/Ownable.sol";
import {IERC20} from "../dependencies/openzeppelin/contracts/IERC20.sol";
import {ILendingPoolAddressesProvider} from "../interfaces/ILendingPoolAddressesProvider.sol";
import {ICurveFi} from "../protocol/strategies/deps/curve/ICurveFi.sol";
import {IPriceOracleGetter} from "../interfaces/IPriceOracleGetter.sol";
import {IChainlinkAggregator} from "../interfaces/IChainlinkAggregator.sol";
import {SafeERC20} from "../dependencies/openzeppelin/contracts/SafeERC20.sol";
import {Initializable} from "../dependencies/openzeppelin/upgradeability/Initializable.sol";
import {AssetMappings} from "../protocol/lendingpool/AssetMappings.sol";
import {DataTypes} from "../protocol/libraries/types/DataTypes.sol";
import {CurveOracle} from "./CurveOracle.sol";
import {IYearnToken} from "./interfaces/IYearnToken.sol";
import {Address} from "../dependencies/openzeppelin/contracts/Address.sol";
import {Errors} from "../protocol/libraries/helpers/Errors.sol";
/// @title VMEXOracle
/// @author VMEX, with inspiration from Aave
/// @notice Proxy smart contract to get the price of an asset from a price source, with Chainlink Aggregator
///         smart contracts as primary option
/// - If the returned price by a Chainlink aggregator is <= 0, the call is forwarded to a fallbackOracle
/// - Owned by the VMEX governance system, allowed to add sources for assets, replace them
///   and change the fallbackOracle
contract VMEXOracle is Initializable, IPriceOracleGetter, Ownable {
    using SafeERC20 for IERC20;

    event BaseCurrencySet(
        address indexed baseCurrency,
        uint256 baseCurrencyUnit
    );
    event AssetSourceUpdated(address indexed asset, address indexed source);
    event FallbackOracleUpdated(address indexed fallbackOracle);


    ILendingPoolAddressesProvider internal addressProvider;
    AssetMappings internal assetMappings;
    mapping(address => IChainlinkAggregator) private assetsSources;
    IPriceOracleGetter private _fallbackOracle;
    address public BASE_CURRENCY; //removed immutable keyword since
    uint256 public BASE_CURRENCY_UNIT;
    address public constant THREE_POOL = 0x6c3F90f043a72FA612cbac8115EE7e52BDe6E490;
    address public constant ethNative = 0xEeeeeEeeeEeEeeEeEeEeeEEEeeeeEeeeeeeeEEeE;
    address public constant WETH = 0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2;

    modifier onlyGlobalAdmin() {
        //global admin will be able to have access to other tranches, also can set portion of reserve taken as fee for VMEX admin
        _onlyGlobalAdmin();
        _;
    }

    function _onlyGlobalAdmin() internal view {
        //this contract handles the updates to the configuration
        require(
            addressProvider.getGlobalAdmin() == msg.sender,
            Errors.CALLER_NOT_GLOBAL_ADMIN
        );
    }

    function initialize (
        ILendingPoolAddressesProvider provider
    ) public initializer {
        addressProvider = provider;
        assetMappings = AssetMappings(addressProvider.getAssetMappings());
    }

    function setBaseCurrency(
        address baseCurrency,
        uint256 baseCurrencyUnit
    ) external onlyGlobalAdmin {
        BASE_CURRENCY = baseCurrency;
        BASE_CURRENCY_UNIT = baseCurrencyUnit;
    }

    /// @notice External function called by the Aave governance to set or replace sources of assets
    /// @param assets The addresses of the assets
    /// @param sources The address of the source of each asset
    function setAssetSources(
        address[] calldata assets,
        address[] calldata sources
    ) external onlyGlobalAdmin {
        _setAssetsSources(assets, sources);
    }

    /// @notice Sets the fallbackOracle
    /// - Callable only by the Aave governance
    /// @param fallbackOracle The address of the fallbackOracle
    function setFallbackOracle(address fallbackOracle) external onlyGlobalAdmin {
        _setFallbackOracle(fallbackOracle);
    }

    /// @notice Internal function to set the sources for each asset
    /// @param assets The addresses of the assets
    /// @param sources The address of the source of each asset
    function _setAssetsSources(
        address[] memory assets,
        address[] memory sources
    ) internal {
        require(assets.length == sources.length, "INCONSISTENT_PARAMS_LENGTH");
        for (uint256 i = 0; i < assets.length; i++) {
            assetsSources[assets[i]] = IChainlinkAggregator(sources[i]);
            emit AssetSourceUpdated(assets[i], sources[i]);
        }
    }

    /// @notice Internal function to set the fallbackOracle
    /// @param fallbackOracle The address of the fallbackOracle
    function _setFallbackOracle(address fallbackOracle) internal {
        _fallbackOracle = IPriceOracleGetter(fallbackOracle);
        emit FallbackOracleUpdated(fallbackOracle);
    }

    /// @notice Gets an asset price by address
    /// @param asset The asset address
    function getAssetPrice(address asset)
        public
        view
        override
        returns (uint256)
    {
        if (asset == BASE_CURRENCY) {
            return BASE_CURRENCY_UNIT;
        }

        DataTypes.ReserveAssetType tmp = assetMappings.getAssetType(asset);

        if(tmp==DataTypes.ReserveAssetType.AAVE){
            return getAaveAssetPrice(asset);
        }
        else if(tmp==DataTypes.ReserveAssetType.CURVE || tmp==DataTypes.ReserveAssetType.CURVEV2){
            return getCurveAssetPrice(asset, tmp);
        }
        else if(tmp==DataTypes.ReserveAssetType.YEARN){
            return getYearnPrice(asset);
        }
        require(false, "error determining oracle address");
        return 0;
    }


    function getAaveAssetPrice(address asset) internal view returns (uint256){
        IChainlinkAggregator source = assetsSources[asset];
        if (address(source) == address(0)) {
            return _fallbackOracle.getAssetPrice(asset);
        } else {
            int256 price = IChainlinkAggregator(source).latestAnswer();
            if (price > 0) {
                return uint256(price);
            } else {
                return _fallbackOracle.getAssetPrice(asset);
            }
        }
    }

    function getCurveAssetPrice(
        address asset,
        DataTypes.ReserveAssetType assetType
    ) internal view returns (uint256 price) {
        DataTypes.CurveMetadata memory c = assetMappings.getCurveMetadata(asset);

        if (c._curvePool == address(0) || !Address.isContract(c._curvePool)) {
            return _fallbackOracle.getAssetPrice(asset);
        }

        uint256[] memory prices = new uint256[](c._poolSize);

        for (uint256 i = 0; i < c._poolSize; i++) {
            address underlying = ICurveFi(c._curvePool).coins(i);
            if(underlying == ethNative){
                underlying = WETH;
            }
            if (underlying == THREE_POOL) {
                //this is the only underlying in our supported assets that is a curve token instead of aave token
                prices[i] = getCurveAssetPrice(underlying, assetType); //recursion!!
            } else {
                prices[i] = getAaveAssetPrice(underlying);
            }
            require(prices[i] > 0, "underlying oracle encountered an error");
        }

        if(assetType==DataTypes.ReserveAssetType.CURVE){
            price = CurveOracle.get_price_v1(c._curvePool, prices);
        }
        else if(assetType==DataTypes.ReserveAssetType.CURVEV2){
            price = CurveOracle.get_price_v2(c._curvePool, prices);
        }
        //TODO: incorporate backup oracles here?
        // require(price > 0, "Curve oracle encountered an error");
        if(price == 0){
            return _fallbackOracle.getAssetPrice(asset);
        }
        return price;
    }

    function getYearnPrice(address asset) internal view returns (uint256){
        IYearnToken yearnVault = IYearnToken(asset);
        uint256 underlyingPrice = getAssetPrice(yearnVault.token());
        uint256 price = yearnVault.pricePerShare()*underlyingPrice / 10**yearnVault.decimals();
        if(price == 0){
            return _fallbackOracle.getAssetPrice(asset);
        }
        return price;
    }

    //updateTWAP (average O(1))
    //recent +=1 and cover case where it goes over
    //cumulatedPrices[asset][recent] =
    //If block.timestamp - cumulatedPrices[asset][last].timestamp > 24 hours,
    //  then keep increasing last until you find until find cumulatedPrices[asset][last].timestamp < 24 hours (most likely close to O(1))
    function updateTWAP(address asset) public override{
        require(numPrices[asset]<type(uint16).max, "Overflow updateTWAP");
        uint256 currentPrice = getAssetPrice(asset);
        _updateState(asset,currentPrice);
    }

    //getAssetTWAPPrice
    //first call updateTWAP
    //return (cumulatedPrices[asset][recent].cumulatedPrice - cumulatedPrices[asset][last].cumulatedPrice)/(cumulatedPrices[asset][recent].timestamp - cumulatedPrices[asset][last].timestamp)
    function getAssetTWAPPrice(address asset) external view override returns (uint256){
        return _getAssetTWAPPrice(asset, getAssetPrice(asset));
    }

    /// @notice Gets a list of prices from a list of assets addresses
    /// @param assets The list of assets addresses
    function getAssetsPrices(address[] calldata assets)
        external
        view
        returns (uint256[] memory)
    {
        uint256[] memory prices = new uint256[](assets.length);
        for (uint256 i = 0; i < assets.length; i++) {
            prices[i] = getAssetPrice(assets[i]);
        }
        return prices;
    }

    /// @notice Gets the address of the source for an asset address
    /// @param asset The address of the asset
    /// @return address The address of the source
    function getSourceOfAsset(address asset) external view returns (address) {
        return address(assetsSources[asset]);
    }

    /// @notice Gets the address of the fallback oracle
    /// @return address The addres of the fallback oracle
    function getFallbackOracle() external view returns (address) {
        return address(_fallbackOracle);
    }
}

// SPDX-License-Identifier: agpl-3.0
pragma solidity >=0.8.0;

import {Ownable} from "../../dependencies/openzeppelin/contracts/Ownable.sol";

// Prettier ignore to prevent buidler flatter bug
// prettier-ignore
import {InitializableImmutableAdminUpgradeabilityProxy} from '../libraries/aave-upgradeability/InitializableImmutableAdminUpgradeabilityProxy.sol';

import {ILendingPoolAddressesProvider} from "../../interfaces/ILendingPoolAddressesProvider.sol";
import {DataTypes} from "../libraries/types/DataTypes.sol";

/**
 * @title LendingPoolAddressesProvider contract
 * @dev Main registry of addresses part of or connected to the protocol, including permissioned roles
 * - Acting also as factory of proxies and admin of those, so with right to change its implementations
 * - Owned by the Vmex Governance
 * @author Vmex
 **/
contract LendingPoolAddressesProvider is
    Ownable,
    ILendingPoolAddressesProvider
{
    string private _marketId;

    // List of addresses that are not specific to a tranche
    mapping(bytes32 => address) private _addresses;

    // List of addresses that are specific to a tranche:
    // _addressesTranche[TRANCHE_ADMIN][0] is the admin address for tranche 0
    mapping(bytes32 => mapping(uint64 => address)) private _addressesTranche;

    // Whitelisted addresses that are allowed to create permissionless tranches
    mapping(address => bool) whitelistedAddresses;

    // Whether or not permissionless tranches are enabled for all users
    bool permissionlessTranches;

    bytes32 private constant GLOBAL_ADMIN = "GLOBAL_ADMIN";
    bytes32 private constant LENDING_POOL = "LENDING_POOL";
    bytes32 private constant ATOKEN = "ATOKEN";
    bytes32 private constant YEARN_VTOKEN = "YEARN_VTOKEN";
    bytes32 private constant STABLE_DEBT = "STABLE_DEBT";
    bytes32 private constant VARIABLE_DEBT = "VARIABLE_DEBT";
    bytes32 private constant LENDING_POOL_CONFIGURATOR =
        "LENDING_POOL_CONFIGURATOR";
    bytes32 private constant TRANCHE_ADMIN = "TRANCHE_ADMIN";
    bytes32 private constant EMERGENCY_ADMIN = "EMERGENCY_ADMIN";
    bytes32 private constant LENDING_POOL_COLLATERAL_MANAGER =
        "COLLATERAL_MANAGER";
    bytes32 private constant VMEX_PRICE_ORACLE = "VMEX_PRICE_ORACLE";
    bytes32 private constant LENDING_RATE_ORACLE = "LENDING_RATE_ORACLE";

    bytes32 private constant CURVE_ADDRESS_PROVIDER = "CURVE_ADDRESS_PROVIDER";
    bytes32 private constant ASSET_MAPPINGS = "ASSET_MAPPINGS";
    bytes32 private constant VMEX_TREASURY_ADDRESS = "VMEX_TREASURY_ADDRESS";

    constructor(string memory marketId) {
        _setMarketId(marketId);
        permissionlessTranches = false;
        _setVMEXTreasury(0xF2539a767D6a618A86E0E45D6d7DB3dE6282dE49);
    }

    function getVMEXTreasury() external view override returns(address){
        return getAddress(VMEX_TREASURY_ADDRESS);
    }

    function setVMEXTreasury(address add) external override onlyOwner {
        _setVMEXTreasury(add);
    }

    function _setVMEXTreasury(address add) internal {
        _addresses[VMEX_TREASURY_ADDRESS] = add;
        emit VMEXTreasuryUpdated(add);
    }

    /**
     * @dev Sets whether permissionless tranches are enabled or disabled for all users.
     * @param val True if permissionless tranches are enabled, false otherwise
     **/
    function setPermissionlessTranches(bool val) external onlyOwner {
        permissionlessTranches = val;
    }

    /**
     * @dev Add a user to create permissionless tranches.
     * @param ad The user's address
     * @param val Whether or not to enable this user to create permissionless tranches
     **/
    function addWhitelistedAddress(address ad, bool val) external onlyOwner {
        whitelistedAddresses[ad] = val;
    }

    /**
     * @dev Checks whether an address is allowed to create permissionless tranches.
     * @param ad The user's address
     **/
    function isWhitelistedAddress(address ad)
        external
        view
        override
        returns (bool)
    {
        return permissionlessTranches || whitelistedAddresses[ad];
    }

    /**
     * @dev Returns the id of the Vmex market to which this contracts points to
     * @return The market id
     **/
    function getMarketId() external view override returns (string memory) {
        return _marketId;
    }

    /**
     * @dev Allows to set the market which this LendingPoolAddressesProvider represents
     * @param marketId The market id
     */
    function setMarketId(string memory marketId) external override onlyOwner {
        _setMarketId(marketId);
    }

    /**
     * @dev General function to update the implementation of a proxy registered with
     * certain `id`. If there is no proxy registered, it will instantiate one and
     * set as implementation the `implementationAddress`
     * IMPORTANT Use this function carefully, only for ids that don't have an explicit
     * setter function, in order to avoid unexpected consequences
     * @param id The id
     * @param implementationAddress The address of the new implementation
     */
    function setAddressAsProxy(bytes32 id, address implementationAddress)
        external
        override
        onlyOwner
    {
        _updateImpl(id, implementationAddress);
        emit AddressSet(id, implementationAddress, true);
    }

    /**
     * @dev Sets an address for an id replacing the address saved in the addresses map
     * IMPORTANT Use this function carefully, as it will do a hard replacement
     * @param id The id
     * @param newAddress The address to set
     */
    function setAddress(bytes32 id, address newAddress)
        external
        override
        onlyOwner
    {
        _addresses[id] = newAddress;
        emit AddressSet(id, newAddress, false);
    }

    /**
     * @dev Returns an address by id
     * @return The address
     */
    function getAddress(bytes32 id) public view override returns (address) {
        return _addresses[id];
    }

    /**
     * @dev Returns an address in a tranche by id and trancheId
     * @return The address
     */
    function getAddressTranche(bytes32 id, uint64 trancheId)
        public
        view
        override
        returns (address)
    {
        return _addressesTranche[id][trancheId];
    }

    /**
     * @dev Returns the address of the LendingPool proxy
     * @return The LendingPool proxy address
     **/
    function getLendingPool() external view override returns (address) {
        return getAddress(LENDING_POOL);
    }

    /**
     * @dev Updates the implementation of the LendingPool, or creates the proxy
     * setting the new `pool` implementation on the first time calling it
     * @param pool The new LendingPool implementation
     **/
    function setLendingPoolImpl(address pool) external override onlyOwner {
        _updateImpl(LENDING_POOL, pool);
        emit LendingPoolUpdated(pool);
    }

    /**
     * @dev Returns the address of the LendingPool proxy
     * @return The aToken proxy address
     **/
    function getAToken() external view override returns (address) {
        return getAddress(ATOKEN);
    }

    /**
     * @dev Updates the implementation of the LendingPool, or creates the proxy
     * setting the new `pool` implementation on the first time calling it
     * @param aToken The new aToken implementation
     **/
    function setATokenImpl(address aToken) external override onlyOwner {
        _addresses[ATOKEN] = aToken; 
        emit ATokenUpdated(aToken);
    }

    /**
     * @dev Returns the address of the LendingPool proxy
     * @return The aToken proxy address
     **/
    function getVariableDebtToken() external view override returns (address) {
        return getAddress(VARIABLE_DEBT);
    }

    /**
     * @dev Updates the implementation of the LendingPool, or creates the proxy
     * setting the new `pool` implementation on the first time calling it
     * @param aToken The new aToken implementation
     **/
    function setVariableDebtToken(address aToken) external override onlyOwner {
        // don't use _updateImpl since this just stores the address, the upgrade is done in LendingPoolConfigurator
        _addresses[VARIABLE_DEBT] = aToken;
        emit VariableDebtUpdated(aToken);
    }

    /**
     * @dev Returns the address of the LendingPoolConfigurator proxy
     * @return The LendingPoolConfigurator proxy address
     **/
    function getLendingPoolConfigurator()
        external
        view
        override
        returns (address)
    {
        return getAddress(LENDING_POOL_CONFIGURATOR);
    }

    /**
     * @dev Updates the implementation of the LendingPoolConfigurator, or creates the proxy
     * setting the new `configurator` implementation on the first time calling it
     * @param newAddress The new LendingPoolConfigurator implementation
     **/
    function setLendingPoolConfiguratorImpl(address newAddress)
        external
        override
        onlyOwner
    {
        _updateImpl(LENDING_POOL_CONFIGURATOR, newAddress);
        emit LendingPoolConfiguratorUpdated(newAddress);
    }

    /**
     * @dev Returns the address of the LendingPoolCollateralManager. Since the manager is used
     * through delegateCall within the LendingPool contract, the proxy contract pattern does not work properly hence
     * the addresses are changed directly
     * @return The address of the LendingPoolCollateralManager
     **/

    function getLendingPoolCollateralManager()
        external
        view
        override
        returns (address)
    {
        return getAddress(LENDING_POOL_COLLATERAL_MANAGER);
    }

    /**
     * @dev Updates the address of the LendingPoolCollateralManager
     * @param manager The new LendingPoolCollateralManager address
     **/
    function setLendingPoolCollateralManager(address manager)
        external
        override
        onlyOwner
    {
        _addresses[LENDING_POOL_COLLATERAL_MANAGER] = manager;
        emit LendingPoolCollateralManagerUpdated(manager);
    }

    /**
     * @dev The functions below are getters/setters of addresses that are outside the context
     * of the protocol hence the upgradable proxy pattern is not used
     **/

    /**
     * @dev Gets the global admin, the admin to entire market
     * @return The address of the global admin
     **/
    function getGlobalAdmin() external view override returns (address) {
        return getAddress(GLOBAL_ADMIN);
    }

    /**
     * @dev Sets the global admin, the admin to entire market
     * IMPORTANT Use this function carefully, as it will do a hard replacement
     * @param admin The address of the new admin
     **/
    function setGlobalAdmin(address admin) external override onlyOwner {
        _addresses[GLOBAL_ADMIN] = admin;
    }

    /**
     * @dev Gets the tranche admin, the admin to a single tranche
     * @param trancheId The id of the tranche
     * @return The address of the tranche admin
     **/
    function getTrancheAdmin(uint64 trancheId)
        external
        view
        override
        returns (address)
    {
        return getAddressTranche(TRANCHE_ADMIN, trancheId);
    }

    /**
     * @dev Manually sets the tranche admin without checking if the tranche has been taken
     * @param admin The address of the new admin
     * @param trancheId The id of the tranche
     **/
    function setTrancheAdmin(address admin, uint64 trancheId) external override {
        require(
            _msgSender() == owner() ||
                _msgSender() == getAddressTranche(TRANCHE_ADMIN, trancheId),
            "Sender is not VMEX admin or the original admin of the tranche"
        );
        _addressesTranche[TRANCHE_ADMIN][trancheId] = admin;
        emit ConfigurationAdminUpdated(admin, trancheId);
    }

    /**
     * @dev Adds the tranche admin to registry, checking if the tranche has been taken
     * @param admin The address of the new admin
     * @param trancheId The id of the tranche
     **/
    function addTrancheAdmin(address admin, uint64 trancheId) external override {
        // anyone can add their own tranche, but you just have to choose a trancheId that hasn't been used yet
        require(
            _msgSender() == getAddress(LENDING_POOL_CONFIGURATOR) ||
                _msgSender() == owner(),
            "Caller must be lending pool configurator that is creating a new tranche"
        );
        require(
            _addressesTranche[TRANCHE_ADMIN][trancheId] == address(0),
            "Pool admin trancheId input is already in use"
        );
        _addressesTranche[TRANCHE_ADMIN][trancheId] = admin;
        emit ConfigurationAdminUpdated(admin, trancheId);
    }

    /**
     * @dev Gets the emergency admin for the market
     * @return The emergency admin address
     **/
    function getEmergencyAdmin() external view override returns (address) {
        return getAddress(EMERGENCY_ADMIN);
    }

    /**
     * @dev Sets the emergency admin for the market
     * @param emergencyAdmin The address of the new admin
     **/
    function setEmergencyAdmin(address emergencyAdmin) external override onlyOwner {
        _addresses[EMERGENCY_ADMIN] = emergencyAdmin;
        emit EmergencyAdminUpdated(emergencyAdmin);
    }

    /**
     * @dev Get the vmex price oracle
     * @return The address of the vmex price oracle
     **/
    function getPriceOracle()
        external
        view
        override
        returns (address)
    {
        return getAddress(VMEX_PRICE_ORACLE);
    }

    /**
     * @dev Set the vmex price oracle
     * @param priceOracle The address of the new vmex price oracle
     **/
    function setPriceOracle(address priceOracle)
        external
        override
        onlyOwner
    {
        _updateImpl(VMEX_PRICE_ORACLE, priceOracle);
        emit PriceOracleUpdated(priceOracle);
    }

    /**
     * @dev Internal function to update the implementation of a specific proxied component of the protocol
     * - If there is no proxy registered in the given `id`, it creates the proxy setting `newAdress`
     *   as implementation and calls the initialize() function on the proxy
     * - If there is already a proxy registered, it just updates the implementation to `newAddress` and
     *   calls the initialize() function via upgradeToAndCall() in the proxy
     * @param id The id of the proxy to be updated
     * @param newAddress The address of the new implementation
     **/
    function _updateImpl(bytes32 id, address newAddress) internal {
        address payable proxyAddress = payable(_addresses[id]);

        InitializableImmutableAdminUpgradeabilityProxy proxy =
            InitializableImmutableAdminUpgradeabilityProxy(proxyAddress);
        bytes memory params =
            abi.encodeWithSignature("initialize(address)", address(this));

        if (proxyAddress == address(0)) {
            proxy = new InitializableImmutableAdminUpgradeabilityProxy(
                address(this)
            );
            proxy.initialize(newAddress, params);
            _addresses[id] = address(proxy);
            emit ProxyCreated(id, address(proxy));
        } else {
            proxy.upgradeToAndCall(newAddress, params);
        }
    }

    function _setMarketId(string memory marketId) internal {
        _marketId = marketId;
        emit MarketIdSet(marketId);
    }

    /**
     * @dev Set the asset mappings
     * @return The address of the asset mappings
     **/
    function getAssetMappings() external view override returns (address){
        return getAddress(ASSET_MAPPINGS);
    }

    /**
     * @dev Set the asset mappings
     * @param assetMappings The address of the new asset mappings
     **/
    function setAssetMappingsImpl(address assetMappings) external override onlyOwner{
        _updateImpl(ASSET_MAPPINGS, assetMappings);
        emit AssetMappingsUpdated(assetMappings);
    }
}

// SPDX-License-Identifier: agpl-3.0
pragma solidity >=0.8.0;

import {ILendingPoolAddressesProvider} from "../../interfaces/ILendingPoolAddressesProvider.sol";

import {DataTypes} from "../libraries/types/DataTypes.sol";
import {Errors} from "../libraries/helpers/Errors.sol";
import {PercentageMath} from "../libraries/math/PercentageMath.sol";
import {VersionedInitializable} from "../libraries/aave-upgradeability/VersionedInitializable.sol";

contract AssetMappings is VersionedInitializable{
    using PercentageMath for uint256;


    ILendingPoolAddressesProvider internal addressesProvider;
    mapping(uint256 => address) public approvedAssets;
    uint256 public numApprovedAssets;

    mapping(address => DataTypes.AssetData) internal assetMappings;
    // mapping(address => DataTypes.AssetDataConfiguration) internal assetConfigurationMappings;
    mapping(address => mapping(uint8=>address)) internal interestRateStrategyAddress;
    mapping(address => uint8) public numInterestRateStrategyAddress;
    mapping(address => mapping(uint8=>address)) internal curveStrategyAddress;
    mapping(address => uint8) public numCurveStrategyAddress;
    mapping(address => DataTypes.CurveMetadata) internal curveMetadata;

    event AssetDataSet(
        address indexed asset,
        uint8 underlyingAssetDecimals,
        string underlyingAssetName,
        uint256 supplyCap,
        uint256 borrowCap,
        uint256 baseLTV,
        uint256 liquidationThreshold,
        uint256 liquidationBonus,
        uint256 borrowFactor,
        bool borrowingEnabled,
        uint256 VMEXReserveFactor
    );

    event ConfiguredReserves(
        address indexed asset,
        uint256 baseLTV,
        uint256 liquidationThreshold,
        uint256 liquidationBonus,
        uint256 supplyCap,
        uint256 borrowCap,
        uint256 borrowFactor
    );

    event AddedInterestRateStrategyAddress(
        address indexed asset,
        uint256 index,
        address strategyAddress
    );

    event AddedCurveStrategyAddress(
        address indexed asset,
        uint256 index,
        address curveStrategyAddress
    );

    event VMEXReserveFactorChanged(address indexed asset, uint256 factor);


    modifier onlyGlobalAdmin() {
        //global admin will be able to have access to other tranches, also can set portion of reserve taken as fee for VMEX admin
        require(
            addressesProvider.getGlobalAdmin() == msg.sender,
            Errors.CALLER_NOT_GLOBAL_ADMIN
        );
        _;
    }

    function getRevision() internal pure override returns (uint256) {
        return 0x1;
    }

    function initialize(ILendingPoolAddressesProvider provider)
        public
        initializer
    {
        addressesProvider = ILendingPoolAddressesProvider(provider);
        numApprovedAssets=0;
        // curveMetadata[0xc4AD29ba4B3c580e6D59105FFf484999997675Ff] = DataTypes.CurveMetadata( //tricrypto2
        //     38,
        //     3,
        //     0xD51a44d3FaE010294C616388b506AcdA1bfAAE46
        // );
        // curveMetadata[0x6c3F90f043a72FA612cbac8115EE7e52BDe6E490] = DataTypes.CurveMetadata( //threepool
        //     9,
        //     3,
        //     0xbEbc44782C7dB0a1A60Cb6fe97d0b483032FF1C7
        // );
        // curveMetadata[0x06325440D014e39736583c165C2963BA99fAf14E] = DataTypes.CurveMetadata( //steth
        //     25,
        //     2,
        //     0xDC24316b9AE028F1497c275EB9192a3Ea0f67022
        // );
        // curveMetadata[0x3175Df0976dFA876431C2E9eE6Bc45b65d3473CC] = DataTypes.CurveMetadata( //fraxusdc
        //     100,
        //     2,
        //     0xDcEF968d416a41Cdac0ED8702fAC8128A64241A2
        // );
        // curveMetadata[0xd632f22692FaC7611d2AA1C0D552930D43CAEd3B] = DataTypes.CurveMetadata( //frax3crv
        //     32,
        //     2,
        //     0xd632f22692FaC7611d2AA1C0D552930D43CAEd3B
        // );
    }

    function getVMEXReserveFactor(
        address asset
    ) public view returns(uint256) {
        return assetMappings[asset].VMEXReserveFactor;
    }

    /**
     * @dev Updates the vmex reserve factor of a reserve
     * @param asset The address of the reserve you want to set
     * @param reserveFactor The new reserve factor of the reserve
     **/
    function setVMEXReserveFactor(
        address asset,
        uint256 reserveFactor //the value here should only occupy 16 bits
    ) public onlyGlobalAdmin {
        assetMappings[asset].VMEXReserveFactor = reserveFactor;

        emit VMEXReserveFactorChanged(asset, reserveFactor);
    }

    function validateCollateralParams(uint256 baseLTV, uint256 liquidationThreshold, uint256 liquidationBonus) internal pure {
        require(baseLTV <= liquidationThreshold, Errors.LPC_INVALID_CONFIGURATION);

        if (liquidationThreshold != 0) {
            //liquidation bonus must be bigger than 100.00%, otherwise the liquidator would receive less
            //collateral than needed to cover the debt
            require(
                liquidationBonus > PercentageMath.PERCENTAGE_FACTOR,
                Errors.LPC_INVALID_CONFIGURATION
            );

            //if threshold * bonus is less than PERCENTAGE_FACTOR, it's guaranteed that at the moment
            //a loan is taken there is enough collateral available to cover the liquidation bonus

            //ex: if liquidation threshold is 50%, that means during liquidation we should have half of the collateral not used to back up loan. If user wants to liquidate and gets 200% liquidation bonus, then they would need
            //2 times the amount of debt asset they are covering, meaning that they need twice the value of the ccollateral asset. Since liquidation threshold is 50%, this is possible

            //with borrow factors, the liquidation threshold is always less than or equal to what it should be, so this still stands
            require(
                liquidationThreshold.percentMul(liquidationBonus) <=
                    PercentageMath.PERCENTAGE_FACTOR,
                Errors.LPC_INVALID_CONFIGURATION
            );
        }
    }

    //by setting it, you automatically also approve it for the protocol
    function setAssetMapping(address[] calldata underlying, DataTypes.AssetData[] memory input, address[] calldata defaultInterestRateStrategyAddress) external onlyGlobalAdmin {
        require(underlying.length==input.length);


        for(uint256 i = 0;i<input.length;i++){
            //validation of the parameters: the LTV can
            //only be lower or equal than the liquidation threshold
            //(otherwise a loan against the asset would cause instantaneous liquidation)
            {
                input[i].baseLTV = input[i].baseLTV.convertToPercent();
                input[i].liquidationThreshold = input[i].liquidationThreshold.convertToPercent();
                input[i].liquidationBonus = input[i].liquidationBonus.convertToPercent();
                input[i].borrowFactor = input[i].borrowFactor.convertToPercent();
                input[i].VMEXReserveFactor = input[i].VMEXReserveFactor.convertToPercent();
            }
            validateCollateralParams(input[i].baseLTV, input[i].liquidationThreshold, input[i].liquidationBonus);

            assetMappings[underlying[i]] = input[i];
            //originally, aave used 4 decimals for percentages. VMEX is increasing the number, but the input still only has 4 decimals


            interestRateStrategyAddress[underlying[i]][0] = defaultInterestRateStrategyAddress[i];
            approvedAssets[numApprovedAssets++] = underlying[i];
            emit AssetDataSet(
                underlying[i],
                input[i].underlyingAssetDecimals,
                input[i].underlyingAssetName,
                input[i].supplyCap,
                input[i].borrowCap,
                input[i].baseLTV,
                input[i].liquidationThreshold,
                input[i].liquidationBonus,
                input[i].borrowFactor,
                input[i].borrowingEnabled,
                input[i].VMEXReserveFactor
            );
        }
    }

    function configureReserveAsCollateral(
        address asset,
        uint256 baseLTV,
        uint256 liquidationThreshold,
        uint256 liquidationBonus,
        uint256 supplyCap,
        uint256 borrowCap,
        uint256 borrowFactor
    ) external onlyGlobalAdmin {
        baseLTV = baseLTV.convertToPercent();
        liquidationThreshold = liquidationThreshold.convertToPercent();
        liquidationBonus = liquidationBonus.convertToPercent();
        borrowFactor = borrowFactor.convertToPercent();
        validateCollateralParams(baseLTV, liquidationThreshold, liquidationBonus);
        //originally, aave used 4 decimals for percentages. VMEX is increasing the number, but the input still only has 4 decimals

        assetMappings[asset].baseLTV = baseLTV;
        assetMappings[asset].liquidationThreshold = liquidationThreshold;
        assetMappings[asset].liquidationBonus = liquidationBonus;
        assetMappings[asset].supplyCap = supplyCap;
        assetMappings[asset].borrowCap = borrowCap;
        assetMappings[asset].borrowFactor = borrowFactor;
        emit ConfiguredReserves(asset, baseLTV, liquidationThreshold, liquidationBonus, supplyCap, borrowCap, borrowFactor);
    }

    function removeAsset(address underlying) external onlyGlobalAdmin{
        for(uint256 i = 0;i<numApprovedAssets;i++){
            if(approvedAssets[i]==underlying){
                for(uint256 j = i;j<numApprovedAssets-1;j++){
                    approvedAssets[j] = approvedAssets[j+1];
                }
                break;
            }
        }
        numApprovedAssets--;
        assetMappings[underlying].isAllowed = false;
    }

    //setAssetMapping

    function getAllApprovedTokens() view external returns(address[] memory tokens){
        tokens = new address[](
            numApprovedAssets
        );

        for (uint256 i = 0; i < numApprovedAssets; i++) {
            tokens[i] = approvedAssets[i];
        }
    }

    function getAssetMapping(address underlying) view external returns(DataTypes.AssetData memory){
        require(assetMappings[underlying].isAllowed, "Asset is not allowed in asset mappings"); //not existing
        return assetMappings[underlying];
    }

    function getAssetBorrowable(address asset) view external returns (bool){
        return assetMappings[asset].borrowingEnabled;
    }

    function getAssetCollateralizable(address asset) view external returns (bool){
        return assetMappings[asset].liquidationThreshold != 0;
    }

    function getInterestRateStrategyAddress(address underlying, uint8 choice) view external returns(address){
        require(assetMappings[underlying].isAllowed, "Asset is not allowed in asset mappings"); //not existing
        require(interestRateStrategyAddress[underlying][choice]!=address(0), "No interest rate strategy is associated");
        return interestRateStrategyAddress[underlying][choice];
    }

    function getAssetType(address asset) view external returns(DataTypes.ReserveAssetType){
        return DataTypes.ReserveAssetType(assetMappings[asset].assetType);
    }

    function getSupplyCap(address asset) view external returns(uint256){
        return assetMappings[asset].supplyCap;
    }

    function getBorrowCap(address asset) view external returns(uint256){
        return assetMappings[asset].borrowCap;
    }

    function getBorrowFactor(address asset) view external returns(uint256){
        return assetMappings[asset].borrowFactor;
    }


    function addInterestRateStrategyAddress(address underlying, address strategy) external onlyGlobalAdmin {
        while(interestRateStrategyAddress[underlying][numInterestRateStrategyAddress[underlying]]!=address(0)){
            numInterestRateStrategyAddress[underlying]++;
        }
        interestRateStrategyAddress[underlying][numInterestRateStrategyAddress[underlying]] = strategy;
        emit AddedInterestRateStrategyAddress(
            underlying,
            numInterestRateStrategyAddress[underlying],
            strategy
        );
    }

    function addCurveStrategyAddress(address underlying, address strategy) external onlyGlobalAdmin {
        while(curveStrategyAddress[underlying][numCurveStrategyAddress[underlying]]!=address(0)){
            numCurveStrategyAddress[underlying]++;
        }
        curveStrategyAddress[underlying][numCurveStrategyAddress[underlying]] = strategy;
        emit AddedCurveStrategyAddress(
            underlying,
            numInterestRateStrategyAddress[underlying],
            strategy
        );
    }

    function getCurveStrategyAddress(address underlying, uint8 index) external view returns (address) {
        require(assetMappings[underlying].isAllowed, "Asset is not allowed in asset mappings"); //not existing
        require(curveStrategyAddress[underlying][index]!=address(0), "No strategy is associated");
        return curveStrategyAddress[underlying][index];
    }

    function setCurveMetadata(address[] calldata underlying, DataTypes.CurveMetadata[] calldata vars) external onlyGlobalAdmin {
        require(underlying.length == vars.length, "Lists not same length");
        for(uint i = 0;i<underlying.length;i++){
            curveMetadata[underlying[i]] = vars[i];
        }
    }

    function getCurveMetadata(address underlying) external view returns (DataTypes.CurveMetadata memory) {
        // require(curveMetadata[underlying]._curvePool!=address(0), "Curve doesn't have metadata");
        return curveMetadata[underlying];
    }


    /**
     * @dev Gets the configuration paramters of the reserve
     * @param underlying Address of underlying token you want params for
     **/
    function getParams(address underlying)
        external view
        returns (
            uint256 baseLTV,
            uint256 liquidationThreshold,
            uint256 liquidationBonus,
            uint256 underlyingAssetDecimals,
            uint256 borrowFactor
        )
    {
        return (
            assetMappings[underlying].baseLTV,
            assetMappings[underlying].liquidationThreshold,
            assetMappings[underlying].liquidationBonus,
            assetMappings[underlying].underlyingAssetDecimals,
            assetMappings[underlying].borrowFactor
        );
    }

    function getDecimals(address underlying) external view
        returns (
            uint256
        ){

        return assetMappings[underlying].underlyingAssetDecimals;
    }
    //TODO: add governance functions to add or edit config
}

// SPDX-License-Identifier: agpl-3.0
pragma solidity >=0.8.0;

import {SafeMath} from "../../dependencies/openzeppelin/contracts/SafeMath.sol";
import {IReserveInterestRateStrategy} from "../../interfaces/IReserveInterestRateStrategy.sol";
import {WadRayMath} from "../libraries/math/WadRayMath.sol";
import {PercentageMath} from "../libraries/math/PercentageMath.sol";
import {IAToken} from "../../interfaces/IAToken.sol";
import {ILendingPoolAddressesProvider} from "../../interfaces/ILendingPoolAddressesProvider.sol";
import {IERC20} from "../../dependencies/openzeppelin/contracts/IERC20.sol";
import {DataTypes} from "../libraries/types/DataTypes.sol";

import {IBaseStrategy} from "../../interfaces/IBaseStrategy.sol";

/**
 * @title DefaultReserveInterestRateStrategy contract
 * @notice Implements the calculation of the interest rates depending on the reserve state
 * @dev The model of interest rate is based on 2 slopes, one before the `OPTIMAL_UTILIZATION_RATE`
 * point of utilization and another from that one to 100%
 * - An instance of this same contract, can't be used across different Aave markets, due to the caching
 *   of the LendingPoolAddressesProvider
 * @author Aave
 **/
contract DefaultReserveInterestRateStrategy is IReserveInterestRateStrategy {
    using WadRayMath for uint256;
    using SafeMath for uint256;
    using PercentageMath for uint256;

    /**
     * @dev this constant represents the utilization rate at which the pool aims to obtain most competitive borrow rates.
     * Expressed in ray
     **/
    uint256 public immutable OPTIMAL_UTILIZATION_RATE;

    /**
     * @dev This constant represents the excess utilization rate above the optimal. It's always equal to
     * 1-optimal utilization rate. Added as a constant here for gas optimizations.
     * Expressed in ray
     **/

    uint256 public immutable EXCESS_UTILIZATION_RATE;

    ILendingPoolAddressesProvider public immutable addressesProvider;

    // Base variable borrow rate when Utilization rate = 0. Expressed in ray
    uint256 internal immutable _baseVariableBorrowRate;

    // Slope of the variable interest curve when utilization rate > 0 and <= OPTIMAL_UTILIZATION_RATE. Expressed in ray
    uint256 internal immutable _variableRateSlope1;

    // Slope of the variable interest curve when utilization rate > OPTIMAL_UTILIZATION_RATE. Expressed in ray
    uint256 internal immutable _variableRateSlope2;

    // Slope of the stable interest curve when utilization rate > 0 and <= OPTIMAL_UTILIZATION_RATE. Expressed in ray
    uint256 internal immutable _stableRateSlope1;

    // Slope of the stable interest curve when utilization rate > OPTIMAL_UTILIZATION_RATE. Expressed in ray
    uint256 internal immutable _stableRateSlope2;

    constructor(
        ILendingPoolAddressesProvider provider,
        uint256 optimalUtilizationRate,
        uint256 baseVariableBorrowRate,
        uint256 variableRateSlope1,
        uint256 variableRateSlope2,
        uint256 stableRateSlope1,
        uint256 stableRateSlope2
    ) public {
        OPTIMAL_UTILIZATION_RATE = optimalUtilizationRate;
        EXCESS_UTILIZATION_RATE = WadRayMath.ray().sub(optimalUtilizationRate);
        addressesProvider = provider;
        _baseVariableBorrowRate = baseVariableBorrowRate;
        _variableRateSlope1 = variableRateSlope1;
        _variableRateSlope2 = variableRateSlope2;
        _stableRateSlope1 = stableRateSlope1;
        _stableRateSlope2 = stableRateSlope2;
    }

    function variableRateSlope1() external view returns (uint256) {
        return _variableRateSlope1;
    }

    function variableRateSlope2() external view returns (uint256) {
        return _variableRateSlope2;
    }

    function stableRateSlope1() external view returns (uint256) {
        return _stableRateSlope1;
    }

    function stableRateSlope2() external view returns (uint256) {
        return _stableRateSlope2;
    }

    function baseVariableBorrowRate() external view override returns (uint256) {
        return _baseVariableBorrowRate;
    }

    function getMaxVariableBorrowRate()
        external
        view
        override
        returns (uint256)
    {
        return
            _baseVariableBorrowRate.add(_variableRateSlope1).add(
                _variableRateSlope2
            );
    }

    /**
     * @dev Calculates the interest rates depending on the reserve's state and configurations
     * @param calvars: reserves The address of the reserve  * liquidityAdded The liquidity added during the operation. liquidityTaken The liquidity taken during the operation reserveFactor The reserve portion of the interest that goes to the treasury of the market
     * @return The liquidity rate, the stable borrow rate and the variable borrow rate
     **/
    function calculateInterestRates(
        DataTypes.calculateInterestRatesVars memory calvars
    )
        external
        view
        override
        returns (
            uint256,
            uint256
        )
    {
        // this value is zero when strategy withdraws from atoken
        uint256 availableLiquidity = IERC20(calvars.reserve).balanceOf(
            calvars.aToken
        );

        // computes availablility held in stratgies, avoid stack too deep
        {
            address strategyAddress = IAToken(calvars.aToken).getStrategy();

            if (strategyAddress != address(0)) {
                // if strategy exists, add the funds the strategy holds
                // and the funds the strategy has boosted
                availableLiquidity = availableLiquidity.add(
                    IBaseStrategy(strategyAddress).balanceOf()
                );
            }
        }

        availableLiquidity = availableLiquidity
            .add(calvars.liquidityAdded)
            .sub(calvars.liquidityTaken);

        CalcInterestRatesLocalVars memory vars;
        vars.totalDebt = calvars.totalVariableDebt;
        vars.currentVariableBorrowRate = 0;
        vars.currentLiquidityRate = 0;
        vars.utilizationRate = vars.totalDebt == 0
            ? 0
            : vars.totalDebt.rayDiv(availableLiquidity.add(vars.totalDebt));


        if (vars.utilizationRate > OPTIMAL_UTILIZATION_RATE) {
            uint256 excessUtilizationRateRatio = vars
                .utilizationRate
                .sub(OPTIMAL_UTILIZATION_RATE)
                .rayDiv(EXCESS_UTILIZATION_RATE);

            vars.currentVariableBorrowRate = _baseVariableBorrowRate
                .add(_variableRateSlope1)
                .add(_variableRateSlope2.rayMul(excessUtilizationRateRatio));
        } else {
            vars.currentVariableBorrowRate = _baseVariableBorrowRate.add(
                vars.utilizationRate.rayMul(_variableRateSlope1).rayDiv(
                    OPTIMAL_UTILIZATION_RATE
                )
            );
        }

        vars.currentLiquidityRate = vars.currentVariableBorrowRate
            .rayMul(vars.utilizationRate) // % return per asset borrowed * amount borrowed = total expected return in pool
            .percentMul(PercentageMath.PERCENTAGE_FACTOR.sub(calvars.reserveFactor)) //this is percentage of pool being borrowed.
                .percentMul(
                    PercentageMath.PERCENTAGE_FACTOR.sub(
                        calvars.globalVMEXReserveFactor
                    ) //global VMEX treasury interest rate
                );

        //borrow interest rate * (1-reserve factor) *(1- global VMEX reserve factor) = deposit interest rate
        //this means borrow interest rate *(1- global VMEX reserve factor) * reserve factor is the interest rate of the pool admin treasury
        //borrow interest rate *(1- reserve factor) * global VMEX reserve factor is the interest rate of the VMEX treasury
        //if this last part wasn't here, once everyone repays and all deposits are withdrawn, there should be zero left in pool. Now, reserveFactor*borrow interest rate*liquidity is left in pool

        return (
            vars.currentLiquidityRate,
            vars.currentVariableBorrowRate
        );
    }

    struct CalcInterestRatesLocalVars {
        uint256 totalDebt;
        uint256 currentVariableBorrowRate;
        uint256 currentLiquidityRate;
        uint256 utilizationRate;
    }
}

// SPDX-License-Identifier: agpl-3.0
pragma solidity >=0.8.0;

import {SafeMath} from "../../dependencies/openzeppelin/contracts/SafeMath.sol";
import {IERC20} from "../../dependencies/openzeppelin/contracts/IERC20.sol";
import {SafeERC20} from "../../dependencies/openzeppelin/contracts/SafeERC20.sol";
import {Address} from "../../dependencies/openzeppelin/contracts/Address.sol";
import {ILendingPoolAddressesProvider} from "../../interfaces/ILendingPoolAddressesProvider.sol";
import {IAToken} from "../../interfaces/IAToken.sol";
import {IVariableDebtToken} from "../../interfaces/IVariableDebtToken.sol";
import {IFlashLoanReceiver} from "../../flashloan/interfaces/IFlashLoanReceiver.sol";
import {IPriceOracleGetter} from "../../interfaces/IPriceOracleGetter.sol";
import {IStableDebtToken} from "../../interfaces/IStableDebtToken.sol";
import {ILendingPool} from "../../interfaces/ILendingPool.sol";
import {VersionedInitializable} from "../libraries/aave-upgradeability/VersionedInitializable.sol";
import {Helpers} from "../libraries/helpers/Helpers.sol";
import {Errors} from "../libraries/helpers/Errors.sol";
import {WadRayMath} from "../libraries/math/WadRayMath.sol";
import {PercentageMath} from "../libraries/math/PercentageMath.sol";
import {ReserveLogic} from "../libraries/logic/ReserveLogic.sol";
import {GenericLogic} from "../libraries/logic/GenericLogic.sol";
import {ValidationLogic} from "../libraries/logic/ValidationLogic.sol";
import {ReserveConfiguration} from "../libraries/configuration/ReserveConfiguration.sol";
import {UserConfiguration} from "../libraries/configuration/UserConfiguration.sol";
import {DataTypes} from "../libraries/types/DataTypes.sol";
import {LendingPoolStorage} from "./LendingPoolStorage.sol";
import {AssetMappings} from "./AssetMappings.sol";
import {DepositWithdrawLogic} from "../libraries/logic/DepositWithdrawLogic.sol";
// import "hardhat/console.sol";
/**
 * @title LendingPool contract
 * @dev Main point of interaction with an Aave protocol's market
 * - Users can:
 *   # Deposit
 *   # Withdraw
 *   # Borrow
 *   # Repay
 *   # Swap their loans between variable and stable rate
 *   # Enable/disable their deposits as collateral rebalance stable rate borrow positions
 *   # Liquidate positions
 *   # Execute Flash Loans
 * - To be covered by a proxy contract, owned by the LendingPoolAddressesProvider of the specific market
 * - All admin functions are callable by the LendingPoolConfigurator contract defined also in the
 *   LendingPoolAddressesProvider
 * @author Aave
 **/
contract LendingPool is
    VersionedInitializable,
    ILendingPool,
    LendingPoolStorage
{
    using SafeMath for uint256;
    using WadRayMath for uint256;
    using PercentageMath for uint256;
    using SafeERC20 for IERC20;
    using ReserveLogic for *;
    using UserConfiguration for *;
    using ReserveConfiguration for *;
    using DepositWithdrawLogic for DataTypes.ReserveData;

    uint256 public constant LENDINGPOOL_REVISION = 0x2;

    modifier whenNotPaused(uint64 trancheId) {
        _whenNotPaused(trancheId);
        _;
    }
    function _whenNotPaused(uint64 trancheId) internal view {
        require(!_paused[trancheId], Errors.LP_IS_PAUSED);
    }

    modifier onlyLendingPoolConfigurator() {
        _onlyLendingPoolConfigurator();
        _;
    }

    function _onlyLendingPoolConfigurator() internal view {
        require(
            _addressesProvider.getLendingPoolConfigurator() == msg.sender,
            Errors.LP_CALLER_NOT_LENDING_POOL_CONFIGURATOR
        );
    }

    function addWhitelistedDepositBorrow(address user)
        external
        override
        onlyLendingPoolConfigurator
    {
        isWhitelistedDepositBorrow[user] = true;
    }

    /**
     * Function instead of modifier to avoid stack too deep
     */
    function checkWhitelistBlacklist(uint64 trancheId, address user) internal view {
        if(isUsingWhitelist[trancheId]){
            require(whitelist[trancheId][msg.sender], "Tranche requires whitelist");
        }
        require(blacklist[trancheId][msg.sender]==false, "You are blacklisted from this tranche");
    }

    function getRevision() internal pure override returns (uint256) {
        return LENDINGPOOL_REVISION;
    }

    /**
     * @dev Function is invoked by the proxy contract when the LendingPool contract is added to the
     * LendingPoolAddressesProvider of the market.
     * - Caching the address of the LendingPoolAddressesProvider in order to reduce gas consumption
     *   on subsequent operations
     * @param provider The address of the LendingPoolAddressesProvider
     **/
    function initialize(ILendingPoolAddressesProvider provider)
        public
        initializer
    {
        _addressesProvider = provider;
        _maxNumberOfReserves = 128; //this might actually be fine since this is max number of reserves per trancheId?
        _assetMappings =  AssetMappings(_addressesProvider.getAssetMappings());
    }

    /**
     * @dev Deposits an `amount` of underlying asset into the reserve, receiving in return overlying aTokens.
     * If the reserve has collateral enabled, the user's deposit should by default be marked as collateral.
     * - E.g. User deposits 100 USDC and gets in return 100 aUSDC
     * @param asset The address of the underlying asset to deposit
     * @param trancheId The trancheId of the underlying asset to deposit
     * @param amount The amount to be deposited
     * @param onBehalfOf The address that will receive the aTokens, same as msg.sender if the user
     *   wants to receive them on his own wallet, or a different address if the beneficiary of aTokens
     *   is a different wallet
     * @param referralCode Code used to register the integrator originating the operation, for potential rewards.
     *   0 if the action is executed directly by the user, without any middle-man
     **/
    function deposit(
        address asset,
        uint64 trancheId,
        uint256 amount,
        address onBehalfOf,
        uint16 referralCode
    )
        external
        override
        whenNotPaused(trancheId)
    {
        checkWhitelistBlacklist(trancheId, onBehalfOf);
        checkWhitelistBlacklist(trancheId, msg.sender);

        if (isWhitelistedDepositBorrow[onBehalfOf] == false) {
            // check that the user is allowed to deposit and borrow in the same block
            require(
                _usersConfig[onBehalfOf][trancheId].lastUserBorrow != block.number,
                "User is not whitelisted to borrow and deposit in same block"
            );
        }
        DataTypes.DepositVars memory vars = DataTypes.DepositVars(
                asset,
                trancheId,
                address(_addressesProvider),
                _assetMappings,
                amount,
                onBehalfOf,
                referralCode
            );

        uint256 actualAmount = _reserves[asset][trancheId]._deposit(
            vars,
            _usersConfig[onBehalfOf][trancheId].configuration
        );

        _usersConfig[onBehalfOf][trancheId].lastUserDeposit = uint128(block.number);

        emit Deposit(
            vars.asset,
            vars.trancheId,
            msg.sender,
            vars.onBehalfOf,
            actualAmount,
            vars.referralCode
        );
    }

    /**
     * @dev Withdraws an `amount` of underlying asset from the reserve, burning the equivalent aTokens owned
     * E.g. User has 100 aUSDC, calls withdraw() and receives 100 USDC, burning the 100 aUSDC
     * @param asset The address of the underlying asset to withdraw
     * @param trancheId The trancheId of the underlying asset to withdraw
     * @param amount The underlying amount to be withdrawn
     *   - Send the value type(uint256).max in order to withdraw the whole aToken balance
     * @param to Address that will receive the underlying, same as msg.sender if the user
     *   wants to receive it on his own wallet, or a different address if the beneficiary is a
     *   different wallet
     * @return The final amount withdrawn
     **/
    function withdraw(
        address asset,
        uint64 trancheId,
        uint256 amount,
        address to
    )
        public
        override
        whenNotPaused(trancheId)
        returns (uint256)
    {
        checkWhitelistBlacklist(trancheId, msg.sender);
        uint256 actualAmount = DepositWithdrawLogic._withdraw(
                _reserves,
                _usersConfig[msg.sender][trancheId].configuration,
                _reservesList[trancheId],
                DataTypes.WithdrawParams(
                    _reservesCount[trancheId],
                    asset,
                    trancheId,
                    amount,
                    to
                ),
                _addressesProvider,
                _assetMappings
            );

        emit Withdraw(asset, trancheId, msg.sender, to, actualAmount);
        return actualAmount;
    }

    /**
     * @dev Allows users to borrow a specific `amount` of the reserve underlying asset, provided that the borrower
     * already deposited enough collateral, or he was given enough allowance by a credit delegator on the
     * corresponding debt token (StableDebtToken or VariableDebtToken)
     * - E.g. User borrows 100 USDC passing as `onBehalfOf` his own address, receiving the 100 USDC in his wallet
     *   and 100 stable/variable debt tokens, depending on the `interestRateMode`
     * @param asset The address of the underlying asset to borrow
     * @param trancheId The trancheId of the underlying asset to borrow
     * @param amount The amount to be borrowed
     * @param referralCode Code used to register the integrator originating the operation, for potential rewards.
     *   0 if the action is executed directly by the user, without any middle-man
     * @param onBehalfOf Address of the user who will receive the debt. Should be the address of the borrower itself
     * calling the function if he wants to borrow against his own collateral, or the address of the credit delegator
     * if he has been given credit delegation allowance
     **/
    function borrow(
        address asset,
        uint64 trancheId,
        uint256 amount,
        uint16 referralCode,
        address onBehalfOf
    )
        public
        override
        whenNotPaused(trancheId)
    {
        checkWhitelistBlacklist(trancheId, msg.sender);
        if(onBehalfOf != msg.sender){
            checkWhitelistBlacklist(trancheId, onBehalfOf);
        }

        if (isWhitelistedDepositBorrow[onBehalfOf] == false) {
            require(
                _usersConfig[onBehalfOf][trancheId].lastUserDeposit != block.number,
                "User is not whitelisted to borrow and deposit in same block"
            );
        }
        DataTypes.ReserveData storage reserve = _reserves[asset][trancheId];

        DataTypes.ExecuteBorrowParams memory vars = DataTypes.ExecuteBorrowParams(
                amount,
                _reservesCount[trancheId],
                IPriceOracleGetter( //if we change the address of the oracle to give the price in usd, it should still work
                    _addressesProvider.getPriceOracle(
                    )
                ).getAssetPrice(asset),
                trancheId,
                referralCode,
                asset,
                msg.sender,
                onBehalfOf,
                reserve.aTokenAddress,
                true,
                _assetMappings
            );


        DataTypes.UserConfigurationMap storage userConfig = _usersConfig[
            onBehalfOf
        ][trancheId].configuration;


        uint256 actualAmount = DepositWithdrawLogic._borrowHelper(
            _reserves,
            _reservesList[trancheId],
            userConfig,
            _addressesProvider,
            vars
        );

        _usersConfig[onBehalfOf][trancheId].lastUserBorrow = uint128(block.number);

        emit Borrow(
            vars.asset,
            trancheId,
            vars.user,
            vars.onBehalfOf,
            actualAmount,
            reserve.currentVariableBorrowRate,
            vars.referralCode
        );
    }

    /**
     * @notice Repays a borrowed `amount` on a specific reserve, burning the equivalent debt tokens owned
     * - E.g. User repays 100 USDC, burning 100 variable/stable debt tokens of the `onBehalfOf` address
     * @param asset The address of the borrowed underlying asset previously borrowed
     * @param trancheId The trancheId of the borrowed underlying asset previously borrowed
     * @param amount The amount to repay
     * - Send the value type(uint256).max in order to repay the whole debt for `asset` on the specific `debtMode`
     * @param onBehalfOf Address of the user who will get his debt reduced/removed. Should be the address of the
     * user calling the function if he wants to reduce/remove his own debt, or the address of any other
     * other borrower whose debt should be removed
     * @return The final amount repaid
     **/
    function repay(
        address asset,
        uint64 trancheId,
        uint256 amount,
        address onBehalfOf
    ) external override whenNotPaused(trancheId) returns (uint256) {
        // require(!_paused[trancheId], Errors.LP_IS_PAUSED);
        DataTypes.ReserveData storage reserve = _reserves[asset][trancheId];

        uint256 variableDebt = Helpers.getUserCurrentDebt(
            onBehalfOf,
            reserve
        );

        ValidationLogic.validateRepay(
            reserve,
            amount,
            onBehalfOf,
            variableDebt
        );

        uint256 paybackAmount = variableDebt;

        if (amount < paybackAmount) {
            paybackAmount = amount;
        }

        reserve.updateState(_assetMappings.getVMEXReserveFactor(asset));

        IVariableDebtToken(reserve.variableDebtTokenAddress).burn(
            onBehalfOf,
            paybackAmount,
            reserve.variableBorrowIndex
        );

        reserve.updateInterestRates(asset, reserve.aTokenAddress, paybackAmount, 0, _assetMappings.getVMEXReserveFactor(asset));

        if (variableDebt.sub(paybackAmount) == 0) {
            _usersConfig[onBehalfOf][trancheId].configuration.setBorrowing(reserve.id, false);
        }

        IERC20(asset).safeTransferFrom(msg.sender, reserve.aTokenAddress, paybackAmount);

        // IAToken(aToken).handleRepayment(msg.sender, paybackAmount); //no-op

        emit Repay(asset, trancheId, onBehalfOf, msg.sender, paybackAmount);

        return paybackAmount;
    }

    /**
     * @dev Allows depositors to enable/disable a specific deposited asset as collateral
     * @param asset The address of the underlying asset deposited
     * @param useAsCollateral `true` if the user wants to use the deposit as collateral, `false` otherwise
     **/
    function setUserUseReserveAsCollateral(
        address asset,
        uint64 trancheId,
        bool useAsCollateral
    ) external override whenNotPaused(trancheId) {
        // require(
        //     assetDatas[asset].isLendable,
        //     "nonlendable assets must be set as collateral"
        // ); // TODO: not sure if something like this is needed
        DataTypes.ReserveData storage reserve = _reserves[asset][trancheId];

        ValidationLogic.validateSetUseReserveAsCollateral(
            reserve,
            asset,
            useAsCollateral,
            _reserves,
            _usersConfig[msg.sender][trancheId].configuration,
            _reservesList[trancheId],
            _reservesCount[trancheId],
            _addressesProvider,
            _assetMappings
        );

        _usersConfig[msg.sender][trancheId].configuration.setUsingAsCollateral(
            reserve.id,
            useAsCollateral
        );

        if (useAsCollateral) {
            emit ReserveUsedAsCollateralEnabled(asset, trancheId, msg.sender);
        } else {
            emit ReserveUsedAsCollateralDisabled(asset, trancheId, msg.sender);
        }
    }

    /**
     * @dev Function to liquidate a non-healthy position collateral-wise, with Health Factor below 1
     * - The caller (liquidator) covers `debtToCover` amount of debt of the user getting liquidated, and receives
     *   a proportionally amount of the `collateralAsset` plus a bonus to cover market risk
     * @param collateralAsset The address of the underlying asset used as collateral, to receive as result of the liquidation
     * @param debtAsset The address of the underlying borrowed asset to be repaid with the liquidation
     * @param trancheId The trancheId of the tranche this liquidation is occurring in
     * @param user The address of the borrower getting liquidated
     * @param debtToCover The debt amount of borrowed `asset` the liquidator wants to cover
     * @param receiveAToken `true` if the liquidators wants to receive the collateral aTokens, `false` if he wants
     * to receive the underlying collateral asset directly
     **/
    function liquidationCall(
        address collateralAsset,
        address debtAsset,
        uint64 trancheId,
        address user,
        uint256 debtToCover,
        bool receiveAToken
    )
        external
        override
        whenNotPaused(trancheId)
    {
        checkWhitelistBlacklist(trancheId, msg.sender);
        address collateralManager = _addressesProvider
            .getLendingPoolCollateralManager();

        //solium-disable-next-line
        (bool success, bytes memory result) = collateralManager.delegatecall(
            abi.encodeWithSignature(
                "liquidationCall(address,address,uint64,address,uint256,bool)",
                collateralAsset,
                debtAsset,
                trancheId,
                user,
                debtToCover,
                receiveAToken
            )
        );

        require(success, Errors.LP_LIQUIDATION_CALL_FAILED);

        (uint256 returnCode, string memory returnMessage) = abi.decode(
            result,
            (uint256, string)
        );

        require(returnCode == 0, string(abi.encodePacked(returnMessage)));
    }

    /**
     * @dev Returns the state and configuration of the reserve
     * @param asset The address of the underlying asset of the reserve
     * @param trancheId The trancheId of the reserve
     * @return The state of the reserve
     **/
    function getReserveData(address asset, uint64 trancheId)
        external
        view
        override
        returns (DataTypes.ReserveData memory)
    {
        return _reserves[asset][trancheId];
    }

    /**
     * @dev Sets the liquidity index calculated from strategy
     * @param asset The address of the underlying asset of the reserve
     * @param trancheId The trancheId of the reserve
     * @param newLiquidityIndex The new liquidity index of the reserve
     **/
    function setReserveDataLI(address asset, uint64 trancheId, uint128 newLiquidityIndex)
        external
        override
    {
        //onlyStrategy modifier
        DataTypes.ReserveData storage reserve = _reserves[asset][trancheId];
        require(msg.sender == IAToken(reserve.aTokenAddress).getStrategy(), "Caller must be strategy that is attached to the reserve" );
        reserve.liquidityIndex = newLiquidityIndex;
    }

    /**
     * @dev Returns the user account data across all the reserves in a specific trancheId
     * @param user The address of the user
     * @param trancheId The trancheId
     * @param useTwap 'true' if calculations should use TWAP, 'false' otherwise
     * @return totalCollateralETH the total collateral in ETH of the user
     * @return totalDebtETH the total debt in ETH of the user
     * @return availableBorrowsETH the borrowing power left of the user
     * @return currentLiquidationThreshold the liquidation threshold of the user
     * @return ltv the loan to value of the user
     * @return healthFactor the current health factor of the user
     **/
    function getUserAccountData(address user, uint64 trancheId, bool useTwap)
        public
        view
        override
        returns (
            uint256 totalCollateralETH,
            uint256 totalDebtETH,
            uint256 availableBorrowsETH,
            uint256 currentLiquidationThreshold,
            uint256 ltv,
            uint256 healthFactor,
            uint256 avgBorrowFactor
        )
    {
        (
            totalCollateralETH,
            totalDebtETH,
            ltv,
            currentLiquidationThreshold,
            healthFactor,
            avgBorrowFactor
        ) = GenericLogic.calculateUserAccountData(
            DataTypes.AcctTranche(user, trancheId),
            _reserves,
            _usersConfig[user][trancheId].configuration,
            _reservesList[trancheId],
            _reservesCount[trancheId],
            _addressesProvider,
            _assetMappings,
            useTwap
        );

        availableBorrowsETH = GenericLogic.calculateAvailableBorrowsETH(
            totalCollateralETH,
            totalDebtETH,
            ltv,
            avgBorrowFactor
        );

        //Then, to know how much of an asset you can borrow,
        //amount you are trying to borrow = x
        //debt value = x * borrow factor = availableBorrowsEth
        //just do availableBorrowsETH / asset borrow factor (and then convert to native amount)
    }

    /**
     * @dev Returns the configuration of the reserve
     * @param asset The address of the underlying asset of the reserve
     * @param trancheId The trancheId of the reserve
     * @return The configuration of the reserve
     **/
    function getConfiguration(address asset, uint64 trancheId)
        external
        view
        override
        returns (DataTypes.ReserveConfigurationMap memory)
    {
        return _reserves[asset][trancheId].configuration;
    }

    /**
     * @dev Returns the configuration of the user across all the reserves
     * @param user The user address
     * @param trancheId The trancheId of all the reserves
     * @return The configuration of the user
     **/
    function getUserConfiguration(address user, uint64 trancheId)
        external
        view
        override
        returns (DataTypes.UserConfigurationMap memory)
    {
        return _usersConfig[user][trancheId].configuration;
    }

    /**
     * @dev Returns the normalized income per unit of asset
     * @param asset The address of the underlying asset of the reserve
     * @param trancheId The trancheId of the reserve
     * @return The reserve's normalized income
     */
    function getReserveNormalizedIncome(address asset, uint64 trancheId)
        external
        view
        virtual
        override
        returns (uint256)
    {
        return _reserves[asset][trancheId].getNormalizedIncome();
    }

    /**
     * @dev Returns the normalized variable debt per unit of asset
     * @param asset The address of the underlying asset of the reserve
     * @param trancheId The trancheId of the reserve
     * @return The reserve normalized variable debt
     */
    function getReserveNormalizedVariableDebt(address asset, uint64 trancheId)
        external
        view
        override
        returns (uint256)
    {
        return _reserves[asset][trancheId].getNormalizedDebt();
    }

    /**
     * @dev Returns if the LendingPool tranche is paused
     * @param trancheId The trancheId
     */
    function paused(uint64 trancheId) external view override returns (bool) {
        return _paused[trancheId];
    }

    /**
     * @dev Returns the list of the initialized reserves.
     * @param trancheId The trancheId of the reserves to look at
     **/
    function getReservesList(uint64 trancheId)
        external
        view
        override
        returns (address[] memory)
    {
        address[] memory _activeReserves = new address[](
            _reservesCount[trancheId]
        );

        for (uint256 i = 0; i < _reservesCount[trancheId]; i++) {
            _activeReserves[i] = _reservesList[trancheId][i];
        }
        return _activeReserves;
    }

    /**
     * @dev Returns the list of the initialized reserves
     **/
    // function getReservesList(uint64 trancheId)
    //     external
    //     view
    //     override
    //     returns (address[] memory)
    // {
    //     address[] memory _activeReserves = new address[](_reservesCount[trancheId]);

    //     for (uint256 i = 0; i < _reservesCount[trancheId]; i++) {
    //         _activeReserves[i] = _reservesList[trancheId][i];
    //     }
    //     return _activeReserves;
    // }

    /**
     * @dev Returns the cached LendingPoolAddressesProvider connected to this contract
     **/
    function getAddressesProvider()
        external
        view
        override
        returns (ILendingPoolAddressesProvider)
    {
        return _addressesProvider;
    }

    /**
     * @dev Returns the maximum number of reserves supported to be listed in this LendingPool
     */
    // function MAX_NUMBER_RESERVES() public view returns (uint256) {
    //     return _maxNumberOfReserves;
    // }

    /**
     * @dev Validates and finalizes an aToken transfer
     * - Only callable by the overlying aToken of the `asset`
     * @param asset The address of the underlying asset of the aToken
     * @param from The user from which the aTokens are transferred
     * @param to The user receiving the aTokens
     * @param amount The amount being transferred/withdrawn
     * @param balanceFromBefore The aToken balance of the `from` user before the transfer
     * @param balanceToBefore The aToken balance of the `to` user before the transfer
     */
    function finalizeTransfer(
        address asset,
        uint64 trancheId,
        address from,
        address to,
        uint256 amount,
        uint256 balanceFromBefore,
        uint256 balanceToBefore
    ) external override whenNotPaused(trancheId) {
        require(
            msg.sender == _reserves[asset][trancheId].aTokenAddress,
            Errors.LP_CALLER_MUST_BE_AN_ATOKEN
        );

        ValidationLogic.validateTransfer(
            from,
            trancheId,
            _reserves,
            _usersConfig[from][trancheId].configuration,
            _reservesList[trancheId],
            _reservesCount[trancheId],
            _addressesProvider,
            _assetMappings
        );

        uint256 reserveId = _reserves[asset][trancheId].id;

        if (from != to) {
            if (balanceFromBefore.sub(amount) == 0) {
                DataTypes.UserConfigurationMap
                    storage fromConfig = _usersConfig[from][trancheId].configuration;
                fromConfig.setUsingAsCollateral(reserveId, false);
                emit ReserveUsedAsCollateralDisabled(asset, trancheId, from);
            }

            if (balanceToBefore == 0 && amount != 0) {
                DataTypes.UserConfigurationMap storage toConfig = _usersConfig[
                    to
                ][trancheId].configuration;
                toConfig.setUsingAsCollateral(reserveId, true);
                emit ReserveUsedAsCollateralEnabled(asset, trancheId, to);
            }
        }
    }

    /**
     * @dev Initializes a reserve, activating it, assigning an aToken and debt tokens and an
     * interest rate strategy
     * - Only callable by the LendingPoolConfigurator contract
     * @param underlyingAsset The address of the underlying asset (like USDC)
     * @param trancheId The tranche id
     * @param interestRateStrategyAddress The address of the interest rate strategy
     * @param aTokenAddress The address of the aToken that will be assigned to the reserve
     * @param variableDebtAddress The address of the VariableDebtToken that will be assigned to the reserve
     **/
    function initReserve(
        address underlyingAsset,
        uint64 trancheId,
        address interestRateStrategyAddress,
        address aTokenAddress,
        address variableDebtAddress
    ) external override onlyLendingPoolConfigurator {
        require(
            Address.isContract(underlyingAsset),
            Errors.LP_NOT_CONTRACT
        );
        //considering requiring _reservesCount[trancheId] = 0, but you can add another asset to an existing tranche too.
        _reserves[underlyingAsset][trancheId].init(
            aTokenAddress,
            variableDebtAddress,
            interestRateStrategyAddress,
            trancheId
        );

        // TODO: update for tranches
        _addReserveToList(underlyingAsset, trancheId);
    }

    // function setAssetData(address asset, uint8 _assetType)
    //     external
    //     override
    //     onlyLendingPoolConfigurator
    // {
    //     //TODO: edit permissions. Right now is onlyLendingPoolConfigurator
    //     assetDatas[asset] = DataTypes.ReserveAssetType(_assetType);
    // }

    /**
     * @dev Updates the address of the interest rate strategy contract
     * - Only callable by the LendingPoolConfigurator contract
     * @param asset The address of the underlying asset of the reserve
     * @param rateStrategyAddress The address of the interest rate strategy contract
     **/
    function setReserveInterestRateStrategyAddress(
        address asset,
        uint64 trancheId,
        address rateStrategyAddress
    ) external override onlyLendingPoolConfigurator {
        _reserves[asset][trancheId]
            .interestRateStrategyAddress = rateStrategyAddress;
    }

    /**
     * @dev Sets the configuration bitmap of the reserve as a whole
     * - Only callable by the LendingPoolConfigurator contract
     * @param asset The address of the underlying asset of the reserve
     * @param configuration The new configuration bitmap
     **/
    function setConfiguration(
        address asset,
        uint64 trancheId,
        uint256 configuration
    ) external override onlyLendingPoolConfigurator {
        _reserves[asset][trancheId].configuration.data = configuration;
    }

    /**
     * @dev Set the _pause state of the entire lending pool
     * - Only callable by the LendingPoolConfigurator contract
     * @param val `true` to pause the reserve, `false` to un-pause it
     */
    function setPauseEverything(bool val)
        external
        override
        onlyLendingPoolConfigurator
    {
        _everythingPaused = val;
        if (_everythingPaused) {
            emit EverythingPaused();
        } else {
            emit EverythingUnpaused();
        }
    }

    /**
     * @dev Set the _pause state of a tranche
     * - Only callable by the LendingPoolConfigurator contract
     * @param val `true` to pause the reserve, `false` to un-pause it
     */
    function setPause(bool val, uint64 trancheId)
        external
        override
        onlyLendingPoolConfigurator     // TODO: change to onlyTrancheAdmin
    {
        _paused[trancheId] = val;
        if (_paused[trancheId]) {
            emit Paused(trancheId);
        } else {
            emit Unpaused(trancheId);
        }
    }

    function _addReserveToList(address asset, uint64 trancheId) internal {
        uint256 reservesCount = _reservesCount[trancheId];

        require(
            reservesCount < _maxNumberOfReserves,
            Errors.LP_NO_MORE_RESERVES_ALLOWED
        );

        bool reserveAlreadyAdded = _reserves[asset][trancheId].id != 0 || //all reserves start at zero, so if it is not zero then it was already added
            _reservesList[trancheId][0] == asset; //this is since the first asset that was added will have id = 0, so we need to make sure that that asset wasn't already added

        if (!reserveAlreadyAdded) {
            _reserves[asset][trancheId].id = uint8(reservesCount);
            _reservesList[trancheId][reservesCount] = asset;

            _reservesCount[trancheId] = reservesCount + 1;
        }
    }



    function setAndApproveStrategy(
        address asset,
        uint64 trancheId,
        address strategy
    ) external override onlyLendingPoolConfigurator {
        IAToken(_reserves[asset][trancheId].aTokenAddress)
            .setAndApproveStrategy(strategy);
    }

    function withdrawFromStrategy(
        address asset,
        uint64 trancheId,
        uint256 amount
    ) external override onlyLendingPoolConfigurator {
        IAToken(_reserves[asset][trancheId].aTokenAddress).withdrawFromStrategy(
                amount
            );
    }

    function setWhitelist(uint64 trancheId, bool isWhitelisted) external override onlyLendingPoolConfigurator{
        isUsingWhitelist[trancheId] = isWhitelisted;

    }

    function addToWhitelist(uint64 trancheId, address user, bool isWhitelisted) external override onlyLendingPoolConfigurator {
        // using this function enables the whitelist
        if(!isUsingWhitelist[trancheId]) {
            isUsingWhitelist[trancheId] = true;
        }

        whitelist[trancheId][user] = isWhitelisted;
    }

    function addToBlacklist(uint64 trancheId, address user, bool isBlacklisted) external override onlyLendingPoolConfigurator {
        blacklist[trancheId][user] = isBlacklisted;
    }
}

// SPDX-License-Identifier: agpl-3.0
pragma solidity >=0.8.0;

import {SafeMath} from "../../dependencies/openzeppelin/contracts//SafeMath.sol";
import {IERC20} from "../../dependencies/openzeppelin/contracts//IERC20.sol";
import {IAToken} from "../../interfaces/IAToken.sol";
import {IStableDebtToken} from "../../interfaces/IStableDebtToken.sol";
import {IVariableDebtToken} from "../../interfaces/IVariableDebtToken.sol";
import {IPriceOracleGetter} from "../../interfaces/IPriceOracleGetter.sol";
import {ILendingPoolCollateralManager} from "../../interfaces/ILendingPoolCollateralManager.sol";
import {VersionedInitializable} from "../libraries/aave-upgradeability/VersionedInitializable.sol";
import {GenericLogic} from "../libraries/logic/GenericLogic.sol";
// import {Helpers} from "../libraries/helpers/Helpers.sol";
import {WadRayMath} from "../libraries/math/WadRayMath.sol";
import {PercentageMath} from "../libraries/math/PercentageMath.sol";
import {SafeERC20} from "../../dependencies/openzeppelin/contracts/SafeERC20.sol";
import {Errors} from "../libraries/helpers/Errors.sol";
import {Helpers} from "../libraries/helpers/Helpers.sol";
import {ValidationLogic} from "../libraries/logic/ValidationLogic.sol";
import {ReserveLogic} from "../libraries/logic/ReserveLogic.sol";
import {DataTypes} from "../libraries/types/DataTypes.sol";
import {UserConfiguration} from "../libraries/configuration/UserConfiguration.sol";
import {ReserveConfiguration} from "../libraries/configuration/ReserveConfiguration.sol";
import {LendingPoolStorage} from "./LendingPoolStorage.sol";

import {IBaseStrategy} from "../../interfaces/IBaseStrategy.sol";

import {AssetMappings} from "./AssetMappings.sol";
//import "hardhat/console.sol";

/**
 * @title LendingPoolCollateralManager contract
 * @author Aave
 * @dev Implements actions involving management of collateral in the protocol, the main one being the liquidations
 * IMPORTANT This contract will run always via DELEGATECALL, through the LendingPool, so the chain of inheritance
 * is the same as the LendingPool, to have compatible storage layouts
 **/
contract LendingPoolCollateralManager is
    ILendingPoolCollateralManager,
    VersionedInitializable,
    LendingPoolStorage
{
    using SafeERC20 for IERC20;
    using SafeMath for uint256;
    using WadRayMath for uint256;
    using PercentageMath for uint256;
    using ReserveLogic for *;
    using UserConfiguration for *;
    using ReserveConfiguration for *;
    using GenericLogic for *;

    uint256 internal constant PERCENTAGEMATH_NUM_DECIMALS = 18;

    uint256 internal constant LIQUIDATION_CLOSE_FACTOR_PERCENT = 5000*10**(PERCENTAGEMATH_NUM_DECIMALS-4);

    struct LiquidationCallLocalVars {
        uint256 userCollateralBalance;
        uint256 userVariableDebt;
        uint256 maxLiquidatableDebt;
        uint256 actualDebtToLiquidate;
        uint256 liquidationRatio;
        uint256 maxAmountCollateralToLiquidate;
        uint256 maxCollateralToLiquidate;
        uint256 debtAmountNeeded;
        uint256 healthFactor;
        uint256 liquidatorPreviousATokenBalance;
        IAToken collateralAtoken;
        bool isCollateralEnabled;
        DataTypes.InterestRateMode borrowRateMode;
        uint256 errorCode;
        string errorMsg;
        AssetMappings _assetMappings;
        address debtAsset;
        address collateralAsset;
    }

    /**
     * @dev As thIS contract extends the VersionedInitializable contract to match the state
     * of the LendingPool contract, the getRevision() function is needed, but the value is not
     * important, as the initialize() function will never be called here
     */
    function getRevision() internal pure override returns (uint256) {
        return 0;
    }

    /**
     * @dev Function to liquidate a position if its Health Factor drops below 1
     * - The caller (liquidator) covers `debtToCover` amount of debt of the user getting liquidated, and receives
     *   a proportionally amount of the `collateralAsset` plus a bonus to cover market risk
     * @param collateralAsset The address of the underlying asset used as collateral, to receive as result of the liquidation
     * @param debtAsset The address of the underlying borrowed asset to be repaid with the liquidation
     * @param user The address of the borrower getting liquidated
     * @param debtToCover The debt amount of borrowed `asset` the liquidator wants to cover
     * @param receiveAToken `true` if the liquidators wants to receive the collateral aTokens, `false` if he wants
     * to receive the underlying collateral asset directly
     **/
    function liquidationCall(
        address collateralAsset,
        address debtAsset,
        uint64 trancheId,
        // uint8 debtAssetTranche, //this would actually be the same trancheId as the collateral (you can only borrow from the same trancheId that your collateral is in)
        address user,
        uint256 debtToCover,
        bool receiveAToken
    ) external override returns (uint256, string memory) {
        DataTypes.UserConfigurationMap storage userConfig = _usersConfig[user][
            trancheId
        ].configuration;

        LiquidationCallLocalVars memory vars;
        vars._assetMappings = _assetMappings;
        vars.debtAsset = debtAsset;
        vars.collateralAsset = collateralAsset;


        //health factor is based on lowest collateral value between twap and chainlink
        (, , , , vars.healthFactor,) = GenericLogic.calculateUserAccountData(
            DataTypes.AcctTranche(user, trancheId),
            _reserves,
            userConfig,
            _reservesList[trancheId],
            _reservesCount[trancheId],
            _addressesProvider,
            vars._assetMappings,
            false //liquidations don't want to use twap
        );

        DataTypes.ReserveData storage collateralReserve = _reserves[
            vars.collateralAsset
        ][trancheId];
        DataTypes.ReserveData storage debtReserve = _reserves[vars.debtAsset][
            trancheId
        ];

        vars.userVariableDebt = Helpers.getUserCurrentDebt(
            user,
            debtReserve
        );

        (vars.errorCode, vars.errorMsg) = ValidationLogic
            .validateLiquidationCall(
                collateralReserve,
                debtReserve,
                userConfig,
                vars.healthFactor,
                vars.userVariableDebt
            );

        if (
            Errors.CollateralManagerErrors(vars.errorCode) !=
            Errors.CollateralManagerErrors.NO_ERROR
        ) {
            return (vars.errorCode, vars.errorMsg);
        }

        vars.collateralAtoken = IAToken(collateralReserve.aTokenAddress);

        vars.userCollateralBalance = vars.collateralAtoken.balanceOf(user);

        //user's total debt * 50% (you can only liquidate half of user's debt)
        vars.maxLiquidatableDebt = vars.userVariableDebt
            .percentMul(LIQUIDATION_CLOSE_FACTOR_PERCENT);

        vars.actualDebtToLiquidate = debtToCover > vars.maxLiquidatableDebt
            ? vars.maxLiquidatableDebt
            : debtToCover;

        (
            vars.maxCollateralToLiquidate, //considers exchange rate between debt token and collateral
            vars.debtAmountNeeded
        ) = _calculateAvailableCollateralToLiquidate(
            vars.collateralAsset,
            vars.debtAsset,
            vars.actualDebtToLiquidate,
            vars.userCollateralBalance
        );

        // If debtAmountNeeded < actualDebtToLiquidate, there isn't enough
        // collateral to cover the actual amount that is being liquidated, hence we liquidate
        // a smaller amount

        if (vars.debtAmountNeeded < vars.actualDebtToLiquidate) {
            vars.actualDebtToLiquidate = vars.debtAmountNeeded;
        }

        // If the liquidator reclaims the underlying asset, we make sure there is enough available liquidity in the
        // collateral reserve
        if (!receiveAToken) {
            uint256 currentAvailableCollateral = IERC20(vars.collateralAsset)
                .balanceOf(address(vars.collateralAtoken));

            // there is a strategy associated with the collateral token, add the balance of strategy
            // to available collateral
            if (IAToken(vars.collateralAtoken).getStrategy() != address(0)) {
                currentAvailableCollateral = currentAvailableCollateral.add(
                    IBaseStrategy(IAToken(vars.collateralAtoken).getStrategy())
                        .balanceOf()
                );
            }
            if (currentAvailableCollateral < vars.maxCollateralToLiquidate) {
                return (
                    uint256(
                        Errors.CollateralManagerErrors.NOT_ENOUGH_LIQUIDITY
                    ),
                    Errors.LPCM_NOT_ENOUGH_LIQUIDITY_TO_LIQUIDATE
                );
            }
        }

        debtReserve.updateState(vars._assetMappings.getVMEXReserveFactor(vars.debtAsset));

        if (vars.userVariableDebt >= vars.actualDebtToLiquidate) {
            IVariableDebtToken(debtReserve.variableDebtTokenAddress).burn(
                user,
                vars.actualDebtToLiquidate,
                debtReserve.variableBorrowIndex
            );
        } else {
            // If the user doesn't have variable debt, no need to try to burn variable debt tokens
            if (vars.userVariableDebt > 0) {
                IVariableDebtToken(debtReserve.variableDebtTokenAddress).burn(
                    user,
                    vars.userVariableDebt,
                    debtReserve.variableBorrowIndex
                );
            }
        }
        debtReserve.updateInterestRates(
            vars.debtAsset,
            debtReserve.aTokenAddress,
            vars.actualDebtToLiquidate,
            0,
            vars._assetMappings.getVMEXReserveFactor(vars.debtAsset)
        );

        if (receiveAToken) {
            vars.liquidatorPreviousATokenBalance = IERC20(vars.collateralAtoken)
                .balanceOf(msg.sender);
            vars.collateralAtoken.transferOnLiquidation(
                user,
                msg.sender,
                vars.maxCollateralToLiquidate
            );

            if (vars.liquidatorPreviousATokenBalance == 0) {
                DataTypes.UserConfigurationMap
                    storage liquidatorConfig = _usersConfig[msg.sender][
                        trancheId
                    ].configuration;
                liquidatorConfig.setUsingAsCollateral(
                    collateralReserve.id,
                    true
                );
                emit ReserveUsedAsCollateralEnabled(
                    vars.collateralAsset,
                    trancheId,
                    msg.sender
                );
            }
        } else {
            collateralReserve.updateState(vars._assetMappings.getVMEXReserveFactor(collateralAsset));
            collateralReserve.updateInterestRates(
                vars.collateralAsset,
                address(vars.collateralAtoken),
                0,
                vars.maxCollateralToLiquidate,
                vars._assetMappings.getVMEXReserveFactor(vars.collateralAsset)
            );
            // Burn the equivalent amount of aToken, sending the underlying to the liquidator
            vars.collateralAtoken.burn(
                user,
                msg.sender,
                vars.maxCollateralToLiquidate,
                collateralReserve.liquidityIndex
            );
        }

        // If the collateral being liquidated is equal to the user balance,
        // we set the currency as not being used as collateral anymore
        if (vars.maxCollateralToLiquidate == vars.userCollateralBalance) {
            userConfig.setUsingAsCollateral(collateralReserve.id, false);
            emit ReserveUsedAsCollateralDisabled(vars.collateralAsset, trancheId, user);
        }

        // Transfers the debt asset being repaid to the aToken, where the liquidity is kept
        IERC20(vars.debtAsset).safeTransferFrom(
            msg.sender,
            debtReserve.aTokenAddress,
            vars.actualDebtToLiquidate
        );

        emit LiquidationCall(
            vars.collateralAsset,
            vars.debtAsset,
            trancheId,
            user,
            vars.actualDebtToLiquidate,
            vars.maxCollateralToLiquidate,
            msg.sender,
            receiveAToken
        );

        return (
            uint256(Errors.CollateralManagerErrors.NO_ERROR),
            Errors.LPCM_NO_ERRORS
        );
    }

    struct AvailableCollateralToLiquidateLocalVars {
        uint256 userCompoundedBorrowBalance;
        uint256 liquidationBonus;
        uint256 collateralPrice;
        uint256 debtAssetPrice;
        uint256 maxAmountCollateralToLiquidate;
        uint256 debtAssetDecimals;
        uint256 collateralDecimals;
    }

    /**
     * @dev Calculates how much of a specific collateral can be liquidated, given
     * a certain amount of debt asset.
     * - This function needs to be called after all the checks to validate the liquidation have been performed,
     *   otherwise it might fail.
     * @param collateralAsset The address of the underlying asset used as collateral, to receive as result of the liquidation
     * @param debtAsset The address of the underlying borrowed asset to be repaid with the liquidation
     * @param debtToCover The debt amount of borrowed `asset` the liquidator wants to cover
     * @param userCollateralBalance The collateral balance for the specific `collateralAsset` of the user being liquidated
     * @return collateralAmount: The maximum amount that is possible to liquidate given all the liquidation constraints
     *                           (user balance, close factor)
     *         debtAmountNeeded: The amount to repay with the liquidation
     **/
    function _calculateAvailableCollateralToLiquidate(
        address collateralAsset,
        address debtAsset,
        uint256 debtToCover,
        uint256 userCollateralBalance
    ) internal view returns (uint256, uint256) {
        uint256 collateralAmount = 0;
        uint256 debtAmountNeeded = 0;

        AvailableCollateralToLiquidateLocalVars memory vars;
        {
            address oracleAddress = _addressesProvider.getPriceOracle(); //using just chainlink current price oracle, not using 24 hour twap

            IPriceOracleGetter oracle = IPriceOracleGetter(oracleAddress);
            vars.collateralPrice = oracle.getAssetPrice(collateralAsset);

            oracleAddress = _addressesProvider.getPriceOracle(
            );

            oracle = IPriceOracleGetter(oracleAddress);
            vars.debtAssetPrice = oracle.getAssetPrice(debtAsset);
        }
        (
            ,
            ,
            vars.liquidationBonus,
            vars.collateralDecimals,

        ) = _assetMappings.getParams(collateralAsset);
        vars.debtAssetDecimals = _assetMappings.getDecimals(debtAsset);

        // This is the maximum possible amount of the selected collateral that can be liquidated, given the
        // max amount of liquidatable debt
        vars.maxAmountCollateralToLiquidate = vars
            .debtAssetPrice
            .mul(debtToCover)
            .mul(10**vars.collateralDecimals)
            .percentMul(vars.liquidationBonus)
            .div(vars.collateralPrice.mul(10**vars.debtAssetDecimals));

        if (vars.maxAmountCollateralToLiquidate > userCollateralBalance) {
            collateralAmount = userCollateralBalance;
            debtAmountNeeded = vars
                .collateralPrice
                .mul(collateralAmount)
                .mul(10**vars.debtAssetDecimals)
                .div(vars.debtAssetPrice.mul(10**vars.collateralDecimals))
                .percentDiv(vars.liquidationBonus);
        } else {
            collateralAmount = vars.maxAmountCollateralToLiquidate;
            debtAmountNeeded = debtToCover;
        }
        return (collateralAmount, debtAmountNeeded);
    }
}

// SPDX-License-Identifier: agpl-3.0
pragma solidity >=0.8.0;

import {SafeMath} from "../../dependencies/openzeppelin/contracts/SafeMath.sol";
import {VersionedInitializable} from "../libraries/aave-upgradeability/VersionedInitializable.sol";
import {InitializableImmutableAdminUpgradeabilityProxy} from "../libraries/aave-upgradeability/InitializableImmutableAdminUpgradeabilityProxy.sol";
import {ReserveConfiguration} from "../libraries/configuration/ReserveConfiguration.sol";
import {ILendingPoolAddressesProvider} from "../../interfaces/ILendingPoolAddressesProvider.sol";
import {ILendingPool} from "../../interfaces/ILendingPool.sol";
import {IERC20Detailed} from "../../dependencies/openzeppelin/contracts/IERC20Detailed.sol";
import {Errors} from "../libraries/helpers/Errors.sol";
import {PercentageMath} from "../libraries/math/PercentageMath.sol";
import {DataTypes} from "../libraries/types/DataTypes.sol";
import {IInitializableDebtToken} from "../../interfaces/IInitializableDebtToken.sol";
import {IInitializableAToken} from "../../interfaces/IInitializableAToken.sol";
import {IAaveIncentivesController} from "../../interfaces/IAaveIncentivesController.sol";
import {ILendingPoolConfigurator} from "../../interfaces/ILendingPoolConfigurator.sol";
import {IAToken} from "../../interfaces/IAToken.sol";
import {DeployATokens} from "../libraries/helpers/DeployATokens.sol";
import {AssetMappings} from "./AssetMappings.sol";
import {IStrategy} from "../strategies/strats/IStrategy.sol";

import "../../dependencies/openzeppelin/contracts/utils/Strings.sol";
// import "hardhat/console.sol";
/**
 * @title LendingPoolConfigurator contract
 * @author Aave
 * @dev Implements the configuration methods for the Aave protocol
 **/

contract LendingPoolConfigurator is
    VersionedInitializable,
    ILendingPoolConfigurator
{
    using SafeMath for uint256;
    using PercentageMath for uint256;
    using ReserveConfiguration for DataTypes.ReserveConfigurationMap;

    ILendingPoolAddressesProvider internal addressesProvider;
    AssetMappings internal assetMappings;
    ILendingPool internal pool;
    uint64 public totalTranches;

    modifier onlyEmergencyAdmin {
        require(
            addressesProvider.getEmergencyAdmin() == msg.sender,
            Errors.LPC_CALLER_NOT_EMERGENCY_ADMIN
        );
        _;
    }

    modifier onlyGlobalAdmin() {
        //global admin will be able to have access to other tranches, also can set portion of reserve taken as fee for VMEX admin
        _onlyGlobalAdmin();
        _;
    }

    function _onlyGlobalAdmin() internal view {
        //this contract handles the updates to the configuration
        require(
            addressesProvider.getGlobalAdmin() == msg.sender,
            Errors.CALLER_NOT_GLOBAL_ADMIN
        );
    }

    modifier onlyTrancheAdmin(uint64 trancheId) {
        _onlyTrancheAdmin(trancheId);
        _;
    }

    function _onlyTrancheAdmin(uint64 trancheId) internal view {
        //this contract handles the updates to the configuration
        require(
            addressesProvider.getTrancheAdmin(trancheId) == msg.sender ||
                addressesProvider.getGlobalAdmin() == msg.sender,
            Errors.CALLER_NOT_TRANCHE_ADMIN
        );
    }

    modifier whitelistedAddress() {
        require(
            addressesProvider.isWhitelistedAddress(msg.sender),
            "Sender is not whitelisted to add new tranche"
        );
        _;
    }

    uint256 internal constant CONFIGURATOR_REVISION = 0x1;

    function getRevision() internal pure override returns (uint256) {
        return CONFIGURATOR_REVISION;
    }

    function initialize(address provider) public initializer {
        addressesProvider = ILendingPoolAddressesProvider(provider);
        pool = ILendingPool(addressesProvider.getLendingPool());
        assetMappings = AssetMappings(addressesProvider.getAssetMappings());
    }

    /* ************************************************************************* */
    /* This next section contains functions available to any whitelisted address */
    /* ************************************************************************* */

    /**
     * @dev Claims the next available tranche id. Goes from 0 up to max(uint64). Claiming tranche id is first step
     * to create a tranche (permissionless or vmec-managed), doesn't require any checks besides that trancheId is unique
     * @param name The string name of the tranche
     * @param admin The address of the admin to this tranche id
     * @return trancheId The tranche id that the admin now manages
     **/
    function claimTrancheId(
        string calldata name,
        address admin
    ) external whitelistedAddress returns (uint256 trancheId) {
        //whitelist only
        uint64 givenTranche = totalTranches;
        addressesProvider.addTrancheAdmin(admin, givenTranche);
        totalTranches += 1;
        emit TrancheInitialized(givenTranche, name, admin);
        return givenTranche;
    }
    /* ******************************************************************************** */
    /* This next section contains functions only accessible to Tranche Admins and above */
    /* ******************************************************************************** */

    /**
     * @dev Initializes reserves in batch. Can be called directly by those who created tranches
     * and want to add new reserves to their tranche
     * @param input The specifications of the reserves to initialize
     * @param trancheId The trancheId that the msg.sender should be the admin of
     **/
    function batchInitReserve(
        DataTypes.InitReserveInput[] calldata input,
        uint64 trancheId
    ) external onlyTrancheAdmin(trancheId) {
        ILendingPool cachedPool = pool;
        for (uint256 i = 0; i < input.length; i++) {
            _initReserve(
                cachedPool,
                DataTypes.InitReserveInputInternal(
                    input[i],
                    trancheId,
                    addressesProvider.getAToken(),
                    addressesProvider.getVariableDebtToken(),
                    assetMappings.getAssetMapping(input[i].underlyingAsset)
                ) //by putting assetmappings in the addresses provider, we have flexibility to upgrade it in the future
            );
        }
    }

    function _initReserve(
        ILendingPool pool,
        DataTypes.InitReserveInputInternal memory internalInput
    ) internal {
        (
            address aTokenProxyAddress,
            address variableDebtTokenProxyAddress
        ) = DeployATokens.deployATokens(
                DeployATokens.DeployATokensVars(
                    pool,
                    addressesProvider,
                    internalInput
                )
            );

        pool.initReserve(
            internalInput.input.underlyingAsset,
            internalInput.trancheId,
            assetMappings.getInterestRateStrategyAddress(internalInput.input.underlyingAsset,internalInput.input.interestRateChoice),
            aTokenProxyAddress,
            variableDebtTokenProxyAddress
        );

        DataTypes.ReserveConfigurationMap memory currentConfig = pool
            .getConfiguration(
                internalInput.input.underlyingAsset,
                internalInput.trancheId
            );
        if (internalInput.assetdata.liquidationThreshold != 0) { //asset mappings does not force disable borrow
            //user's choice matters
            currentConfig.setCollateralEnabled(internalInput.input.canBeCollateral);
        }
        else{
            currentConfig.setCollateralEnabled(false);
        }

        if (internalInput.assetdata.borrowingEnabled) {
            //user's choice matters
            currentConfig.setBorrowingEnabled(internalInput.input.canBorrow);
        }
        else {
            //force to be disabled
            currentConfig.setBorrowingEnabled(false);
        }

        currentConfig.setReserveFactor(internalInput.input.reserveFactor.convertToPercent()); //accounts for new number of decimals

        currentConfig.setActive(true);
        currentConfig.setFrozen(false);

        pool.setConfiguration(
            internalInput.input.underlyingAsset,
            internalInput.trancheId,
            currentConfig.data
        );

        emit ReserveInitialized(
            internalInput.input.underlyingAsset,
            internalInput.trancheId,
            aTokenProxyAddress,
            variableDebtTokenProxyAddress,
            assetMappings.getInterestRateStrategyAddress(internalInput.input.underlyingAsset,internalInput.input.interestRateChoice),
            currentConfig.getBorrowingEnabled(),
            currentConfig.getCollateralEnabled(),
            currentConfig.getReserveFactor()
        );
    }

    /**
     * @dev Updates the treasury address of the atoken
     * @param newAddress The new address (NO VALIDATIONS ARE DONE)
     * @param asset The underlying asset of the atoken to modify
     * @param trancheId The tranche id of the atoken
     **/
    function updateTreasuryAddress(
        address newAddress,
        address asset,
        uint64 trancheId
    ) external onlyTrancheAdmin(trancheId) {
        ILendingPool cachedPool = pool;
        IAToken(cachedPool.getReserveData(asset, trancheId).aTokenAddress)
            .setTreasury(newAddress);
        //emit
        emit UpdatedTreasuryAddress(asset, trancheId, newAddress);
    }


    /**
     * @dev Enables borrowing on a reserve
     * @param asset The address of the underlying asset of the reserve
     **/
    function setBorrowingOnReserve(
        address asset,
        uint64 trancheId,
        bool borrowingEnabled
    ) public onlyTrancheAdmin(trancheId) {
        require(!borrowingEnabled || assetMappings.getAssetBorrowable(asset), "Asset is not approved to be set as borrowable");
        DataTypes.ReserveConfigurationMap memory currentConfig = pool
            .getConfiguration(asset, trancheId);

        currentConfig.setBorrowingEnabled(borrowingEnabled);
        // currentConfig.setStableRateBorrowingEnabled(stableBorrowRateEnabled);

        pool.setConfiguration(asset, trancheId, currentConfig.data);

        emit BorrowingSetOnReserve(asset, trancheId, borrowingEnabled);
    }

    function setCollateralEnabledOnReserve(address asset, uint64 trancheId, bool collateralEnabled)
        external
        onlyTrancheAdmin(trancheId)
    {
        require(!collateralEnabled || assetMappings.getAssetCollateralizable(asset), "Asset is not approved to be set as collateral");
        DataTypes.ReserveConfigurationMap memory currentConfig = pool
            .getConfiguration(asset, trancheId);

        currentConfig.setCollateralEnabled(collateralEnabled);

        pool.setConfiguration(asset, trancheId, currentConfig.data);
        emit CollateralSetOnReserve(asset, trancheId, collateralEnabled);
    }

    /**
     * @dev Updates the reserve factor of a reserve
     * @param asset The address of the underlying asset of the reserve
     * @param reserveFactor The new reserve factor of the reserve, given with 2 decimals (ie 12.55)
     **/
    function setReserveFactor(
        address asset,
        uint64 trancheId,
        uint256 reserveFactor
    ) public onlyTrancheAdmin(trancheId) {
        DataTypes.ReserveConfigurationMap memory currentConfig = ILendingPool(
            pool
        ).getConfiguration(asset, trancheId);

        reserveFactor = reserveFactor.convertToPercent();

        currentConfig.setReserveFactor(reserveFactor);

        ILendingPool(pool).setConfiguration(
            asset,
            trancheId,
            currentConfig.data
        );

        emit ReserveFactorChanged(asset, trancheId, reserveFactor);
    }

    /**
     * @dev Freezes a reserve. A frozen reserve doesn't allow any new deposit, borrow or rate swap
     *  but allows repayments, liquidations, rate rebalances and withdrawals
     * @param asset The address of the underlying asset of the reserve
     **/
    function freezeReserve(address asset, uint64 trancheId)
        external
        onlyTrancheAdmin(trancheId)
    {
        DataTypes.ReserveConfigurationMap memory currentConfig = ILendingPool(
            pool
        ).getConfiguration(asset, trancheId);

        currentConfig.setFrozen(true);

        ILendingPool(pool).setConfiguration(
            asset,
            trancheId,
            currentConfig.data
        );

        emit ReserveFrozen(asset, trancheId);
    }

    /**
     * @dev Unfreezes a reserve
     * @param asset The address of the underlying asset of the reserve
     **/
    function unfreezeReserve(address asset, uint64 trancheId)
        external
        onlyTrancheAdmin(trancheId)
    {
        DataTypes.ReserveConfigurationMap memory currentConfig = ILendingPool(
            pool
        ).getConfiguration(asset, trancheId);

        currentConfig.setFrozen(false);

        ILendingPool(pool).setConfiguration(
            asset,
            trancheId,
            currentConfig.data
        );

        emit ReserveUnfrozen(asset, trancheId);
    }

    /**
     * @dev Adds a strategy to a reserve
     * @param asset The address of the underlying asset of the reserve
     * @param trancheId The tranche id of the reserve
     * @param strategyId The id of the strategy to attach
     **/
    function addStrategy(
        address asset,
        uint64 trancheId,
        uint8 strategyId
    ) external onlyTrancheAdmin(trancheId) {
        address strategy =assetMappings.getCurveStrategyAddress(asset,strategyId);
        address proxy = DeployATokens._initTokenWithProxy(
            strategy,
            abi.encodeWithSelector(
                IStrategy.initialize.selector,
                address(addressesProvider),
                asset,
                trancheId
            )
        );

        pool.setAndApproveStrategy(asset,trancheId,proxy);
        // console.log("Proxy address: ", proxy);
        emit StrategyAdded(asset, trancheId, strategy);
    }

    function setTrancheWhitelist(uint64 trancheId, bool isWhitelisted) external onlyTrancheAdmin(trancheId){
        pool.setWhitelist(trancheId,isWhitelisted);
        emit UserSetWhitelistEnabled(trancheId, isWhitelisted);
    }

    function setWhitelist(uint64 trancheId, address[] calldata user, bool[] calldata isWhitelisted) external onlyTrancheAdmin(trancheId) {
        require(user.length == isWhitelisted.length, "whitelist lengths not equal");
        for(uint i = 0;i<user.length;i++){
            pool.addToWhitelist(trancheId, user[i], isWhitelisted[i]);
            emit UserChangedWhitelist(trancheId, user[i], isWhitelisted[i]);
        }
    }

    function setBlacklist(uint64 trancheId, address[] calldata user, bool[] calldata isBlacklisted) external onlyTrancheAdmin(trancheId) {
        require(user.length == isBlacklisted.length, "Blacklisted lengths not equal");
        for(uint i = 0;i<user.length;i++){
            pool.addToBlacklist(trancheId, user[i], isBlacklisted[i]);
            emit UserChangedBlacklist(trancheId, user[i], isBlacklisted[i]);
        }
    }

    /**
     * @dev Sets the interest rate strategy of a reserve
     * @param asset The address of the underlying asset of the reserve
     * @param rateStrategyAddressId The new address of the interest strategy contract
     **/
    function setReserveInterestRateStrategyAddress(
        address asset,
        uint64 trancheId,
        uint8 rateStrategyAddressId
    ) external onlyTrancheAdmin(trancheId) {
        address rateStrategyAddress =assetMappings.getInterestRateStrategyAddress(asset,rateStrategyAddressId);

        pool.setReserveInterestRateStrategyAddress(
            asset,
            trancheId,
            rateStrategyAddress
        );
        emit ReserveInterestRateStrategyChanged(asset, trancheId, rateStrategyAddress);
    }

    /* ********************************************************************* */
    /* This next section contains functions only accessible to Global Admins */
    /* ********************************************************************* */


    /**
     * @dev Updates the strategy associated with a reserve. Note that this
     * only updates one strategy for an asset of a specific tranche.
     * Alternatively, we could publish a new strategy with a new strategyId, and users
     * can choose to use that strategy by setting strategyId in initialization.
     * Only global admins have access to update the implementation of strategies because
     * of the danger involved with giving tranche admins access to the strategies.
     **/
    function updateStrategy(UpdateStrategyInput calldata input)
        external
        onlyGlobalAdmin
    {
        // cannot do the below call because aTokens proxy admin is this contract, and by transparent proxy pattern, to use delegatecall you must call from account that is not admin
        // also cannot do delegatecall because we need the context of the atoken
        // address strategyAddress = IAToken(reserveData.aTokenAddress).getStrategy();
        require(input.strategyAddress!=address(0), "Upgrading reserve that doesn't have a strategy");
        bytes memory encodedCall;
        //  = abi.encodeWithSelector(
        //     IStrategy.initialize.selector, //selects that we want to call the initialize function
        //     address(addressesProvider),
        //     input.asset,
        //     input.trancheId
        // );

        _upgradeTokenImplementation(
            input.strategyAddress,//address of proxy
            input.implementation,
            encodedCall
        );

        emit StrategyUpgraded(
            input.asset,
            input.trancheId,
            input.strategyAddress,
            input.implementation
        );
    }

    /**
     * @dev Allows a user to deposit and borrow in the same block
     * @param user The address of allowed user
     **/
    function addWhitelistedDepositBorrow(address user)
        external
        onlyGlobalAdmin
    {
        ILendingPool cachedPool = pool;
        cachedPool.addWhitelistedDepositBorrow(user);
        emit AddedWhitelistedDepositBorrow(user);
    }

    /**
     * @dev Updates the treasury address of the atoken
     * @param newAddress The new address (NO VALIDATIONS ARE DONE)
     * @param asset The underlying asset of the atoken to modify
     * @param trancheId The tranche id of the atoken
     **/
    function updateVMEXTreasuryAddress(
        address newAddress,
        address asset,
        uint64 trancheId
    ) external onlyGlobalAdmin {
        ILendingPool cachedPool = pool;
        IAToken(cachedPool.getReserveData(asset, trancheId).aTokenAddress)
            .setVMEXTreasury(newAddress);
        emit UpdatedVMEXTreasuryAddress(asset, trancheId, newAddress);
    }

    struct UpdateATokenVars {
        address defaultVMEXTreasury;
        uint256 decimals;
        ILendingPool cachedPool;
        DataTypes.ReserveData reserveData;
        UpdateATokenInput input;
    }

    /**
     * @dev Updates the aToken implementation for the reserve. Note that this only updates
     * the implementation for a specific aToken in a specific tranche.
     * @param input address asset - The underlying asset
     *      uint64 trancheId - The tranche id
     *      address treasury - The new treasury address
     *      address incentivesController - The new incentives controller
     *      string name - The new name of the atoken
     *      string symbol - The new symbol of the atoken
     *      address implementation - The new address of atoken implementation
     **/
    function updateAToken(UpdateATokenInput calldata input)
        external
        onlyGlobalAdmin
    {
        UpdateATokenVars memory vars;
        {
            vars.input  = input;
            vars.cachedPool = pool;
            vars.defaultVMEXTreasury = addressesProvider.getVMEXTreasury();

            vars.reserveData = vars.cachedPool.getReserveData(
                vars.input.asset,
                vars.input.trancheId
            );

            (, , , vars.decimals, ) = assetMappings.getParams(vars.input.asset);
        }

        bytes memory encodedCall = abi.encodeWithSelector(
            IInitializableAToken.initialize.selector, //selects that we want to call the initialize function
            vars.cachedPool,
            address(this),
            vars.input.treasury,
            vars.defaultVMEXTreasury,
            vars.input.asset,
            vars.input.trancheId,
            vars.input.incentivesController,
            vars.decimals,
            vars.input.name,
            vars.input.symbol
        );

        _upgradeTokenImplementation(
            vars.reserveData.aTokenAddress,
            vars.input.implementation,
            encodedCall
        );

        emit ATokenUpgraded(
            vars.input.asset,
            vars.input.trancheId,
            vars.reserveData.aTokenAddress,
            vars.input.implementation
        );
    }

    /**
     * @dev Updates the variable debt token implementation for the asset
     * @param input address asset - The underlying asset
     *      uint64 trancheId - The tranche id
     *      address incentivesController - The new incentives controller address
     *      string name - The new name of the variable debt token
     *      string symbol - The new symbol of the variable debt token
     *      address implementation - The address of the variable debt token implementation
     **/
    function updateVariableDebtToken(
        UpdateDebtTokenInput calldata input
    ) external onlyGlobalAdmin {
        ILendingPool cachedPool = pool;

        DataTypes.ReserveData memory reserveData = cachedPool.getReserveData(
            input.asset,
            input.trancheId
        );

        (, , , uint256 decimals, ) = assetMappings.getParams(input.asset);

        bytes memory encodedCall = abi.encodeWithSelector(
            IInitializableDebtToken.initialize.selector,
            cachedPool,
            input.asset,
            input.trancheId,
            input.incentivesController,
            decimals,
            input.name,
            input.symbol
        );

        _upgradeTokenImplementation(
            reserveData.variableDebtTokenAddress,
            input.implementation,
            encodedCall
        );

        emit VariableDebtTokenUpgraded(
            input.asset,
            input.trancheId,
            reserveData.variableDebtTokenAddress,
            input.implementation
        );
    }

    /**
     * @dev Activates a reserve
     * @param asset The address of the underlying asset of the reserve
     **/
    function activateReserve(address asset, uint64 trancheId)
        external
        onlyGlobalAdmin
    {
        DataTypes.ReserveConfigurationMap memory currentConfig = pool
            .getConfiguration(asset, trancheId);

        currentConfig.setActive(true);

        pool.setConfiguration(asset, trancheId, currentConfig.data);

        emit ReserveActivated(asset, trancheId);
    }

    /**
     * @dev Deactivates a reserve
     * @param asset The address of the underlying asset of the reserve
     **/
    function deactivateReserve(address asset, uint64 trancheId)
        external
        onlyGlobalAdmin
    {
        _checkNoLiquidity(asset, trancheId);

        DataTypes.ReserveConfigurationMap memory currentConfig = pool
            .getConfiguration(asset, trancheId);

        currentConfig.setActive(false);

        pool.setConfiguration(asset, trancheId, currentConfig.data);

        emit ReserveDeactivated(asset, trancheId);
    }

    /**
     * @dev pauses or unpauses all the actions of the protocol, including aToken transfers
     * @param val true if protocol needs to be paused, false otherwise
     **/
    function setPoolPause(bool val, uint64 trancheId)
        external
        onlyEmergencyAdmin
    {
        pool.setPause(val, trancheId);
    }

    function _upgradeTokenImplementation(
        address proxyAddress, //current address of the token
        address implementation,
        bytes memory initParams
    ) internal {
        InitializableImmutableAdminUpgradeabilityProxy proxy = InitializableImmutableAdminUpgradeabilityProxy(
                payable(proxyAddress)
            );
        proxy.upgradeToAndCall(implementation, initParams);
    }

    function _checkNoLiquidity(address asset, uint64 trancheId) internal view {
        DataTypes.ReserveData memory reserveData = pool.getReserveData(
            asset,
            trancheId
        );

        uint256 availableLiquidity = IERC20Detailed(asset).balanceOf(
            reserveData.aTokenAddress
        );

        require(
            availableLiquidity == 0 && reserveData.currentLiquidityRate == 0,
            Errors.LPC_RESERVE_LIQUIDITY_NOT_0
        );
    }
}

// SPDX-License-Identifier: agpl-3.0
pragma solidity >=0.8.0;

import {UserConfiguration} from "../libraries/configuration/UserConfiguration.sol";
import {ReserveConfiguration} from "../libraries/configuration/ReserveConfiguration.sol";
import {ReserveLogic} from "../libraries/logic/ReserveLogic.sol";
import {ILendingPoolAddressesProvider} from "../../interfaces/ILendingPoolAddressesProvider.sol";
import {DataTypes} from "../libraries/types/DataTypes.sol";
import {AssetMappings} from "./AssetMappings.sol";

contract LendingPoolStorage {
    using ReserveLogic for DataTypes.ReserveData;
    using ReserveConfiguration for DataTypes.ReserveConfigurationMap;
    using UserConfiguration for DataTypes.UserConfigurationMap;

    ILendingPoolAddressesProvider internal _addressesProvider;
    AssetMappings internal _assetMappings;

    // asset address to trancheId number to reserve data
    mapping(address => mapping(uint64 => DataTypes.ReserveData))
        internal _reserves;
    mapping(address => mapping(uint64 => DataTypes.UserData))
        internal _usersConfig; //user address to trancheId to user configuration

    // mapping(address => DataTypes.ReserveAssetType) internal assetDatas;

    // the list of the available reserves, structured as a mapping for gas savings reasons
    mapping(uint64 => mapping(uint256 => address)) internal _reservesList; //trancheId id -> array of available reserves
    mapping(uint64 => uint256) internal _reservesCount; //trancheId id -> number of reserves per that trancheId

    mapping(uint64 => bool) internal _paused; //trancheId -> paused
    bool internal _everythingPaused; //true if all tranches in the lendingpool is paused

    uint256 internal _maxNumberOfReserves;

    mapping(address => bool) isWhitelistedDepositBorrow;

    mapping(uint64 => bool) public isUsingWhitelist;
    mapping(uint64 => mapping(address=>bool)) whitelist; //tranche to user address to boolean on whether user is whitelisted
    mapping(uint64 => mapping(address=>bool)) blacklist;
}

// SPDX-License-Identifier: agpl-3.0
pragma solidity >=0.8.0;

import "../../../dependencies/openzeppelin/upgradeability/BaseUpgradeabilityProxy.sol";
// import "hardhat/console.sol";
/**
 * @title BaseImmutableAdminUpgradeabilityProxy
 * @author Aave, inspired by the OpenZeppelin upgradeability proxy pattern
 * @dev This contract combines an upgradeability proxy with an authorization
 * mechanism for administrative tasks. The admin role is stored in an immutable, which
 * helps saving transactions costs
 * All external functions in this contract must be guarded by the
 * `ifAdmin` modifier. See ethereum/solidity#3864 for a Solidity
 * feature proposal that would enable this to be done automatically.
 */
contract BaseImmutableAdminUpgradeabilityProxy is BaseUpgradeabilityProxy {
    address immutable ADMIN;

    constructor(address admin) public {
        ADMIN = admin;
    }

    modifier ifAdmin() {
        if (msg.sender == ADMIN) {
            _;
        } else {
            _fallback();
        }
    }

    /**
     * @return The address of the proxy admin.
     */
    function admin() external ifAdmin returns (address) {
        return ADMIN;
    }

    /**
     * @return The address of the implementation.
     */
    function implementation() external ifAdmin returns (address) {
        return _implementation();
    }

    /**
     * @dev Upgrade the backing implementation of the proxy.
     * Only the admin can call this function.
     * @param newImplementation Address of the new implementation.
     */
    function upgradeTo(address newImplementation) external ifAdmin {
        _upgradeTo(newImplementation);
    }

    /**
     * @dev Upgrade the backing implementation of the proxy and call a function
     * on the new implementation.
     * This is useful to initialize the proxied contract.
     * @param newImplementation Address of the new implementation.
     * @param data Data to send as msg.data in the low level call.
     * It should include the signature and the parameters of the function to be called, as described in
     * https://solidity.readthedocs.io/en/v0.4.24/abi-spec.html#function-selector-and-argument-encoding.
     */
    function upgradeToAndCall(address newImplementation, bytes calldata data)
        external
        payable
        ifAdmin
    {
        _upgradeTo(newImplementation);
        if (data.length > 0) {
            (bool success, bytes memory result) = newImplementation.delegatecall(data);
            // console.log("Result of delegate call: ",string(abi.encodePacked(result)));
            require(success, "upgradeToAndCall failed");
        }
        
    }

    /**
     * @dev Only fall back when the sender is not the admin.
     */
    function _willFallback() internal virtual override {
        require(
            msg.sender != ADMIN,
            "Cannot call fallback function from the proxy admin"
        );
        super._willFallback();
    }
}

// SPDX-License-Identifier: agpl-3.0
pragma solidity >=0.8.0;

import "./BaseImmutableAdminUpgradeabilityProxy.sol";
import "../../../dependencies/openzeppelin/upgradeability/InitializableUpgradeabilityProxy.sol";

/**
 * @title InitializableAdminUpgradeabilityProxy
 * @dev Extends BaseAdminUpgradeabilityProxy with an initializer function
 */
contract InitializableImmutableAdminUpgradeabilityProxy is
    BaseImmutableAdminUpgradeabilityProxy,
    InitializableUpgradeabilityProxy
{
    constructor(address admin)
        public
        BaseImmutableAdminUpgradeabilityProxy(admin)
    {}

    /**
     * @dev Only fall back when the sender is not the admin.
     */
    function _willFallback()
        internal
        override(BaseImmutableAdminUpgradeabilityProxy, Proxy)
    {
        BaseImmutableAdminUpgradeabilityProxy._willFallback();
    }
}

// SPDX-License-Identifier: agpl-3.0
pragma solidity >=0.8.0;

/**
 * @title VersionedInitializable
 *
 * @dev Helper contract to implement initializer functions. To use it, replace
 * the constructor with a function that has the `initializer` modifier.
 * WARNING: Unlike constructors, initializer functions must be manually
 * invoked. This applies both to deploying an Initializable contract, as well
 * as extending an Initializable contract via inheritance.
 * WARNING: When used with inheritance, manual care must be taken to not invoke
 * a parent initializer twice, or ensure that all initializers are idempotent,
 * because this is not dealt with automatically as with constructors.
 *
 * @author Aave, inspired by the OpenZeppelin Initializable contract
 */
abstract contract VersionedInitializable {
    /**
     * @dev Indicates that the contract has been initialized.
     */
    uint256 private lastInitializedRevision = 0;

    /**
     * @dev Indicates that the contract is in the process of being initialized.
     */
    bool private initializing;

    /**
     * @dev Modifier to use in the initializer function of a contract.
     */
    modifier initializer() {
        uint256 revision = getRevision();
        require(
            initializing ||
                isConstructor() ||
                revision > lastInitializedRevision,
            "Contract instance has already been initialized"
        );

        bool isTopLevelCall = !initializing;
        if (isTopLevelCall) {
            initializing = true;
            lastInitializedRevision = revision;
        }

        _;

        if (isTopLevelCall) {
            initializing = false;
        }
    }

    /**
     * @dev returns the revision number of the contract
     * Needs to be defined in the inherited class as a constant.
     **/
    function getRevision() internal pure virtual returns (uint256);

    /**
     * @dev Returns true if and only if the function is running in the constructor
     **/
    function isConstructor() private view returns (bool) {
        // extcodesize checks the size of the code stored in an address, and
        // address returns the current address. Since the code is still not
        // deployed when running a constructor, any checks on its code size will
        // yield zero, making it an effective way to detect if a contract is
        // under construction or not.
        uint256 cs;
        //solium-disable-next-line
        assembly {
            cs := extcodesize(address())
        }
        return cs == 0;
    }

    // Reserved storage space to allow for layout changes in the future.
    uint256[50] private ______gap;
}

// SPDX-License-Identifier: agpl-3.0
pragma solidity >=0.8.0;

import {Errors} from "../helpers/Errors.sol";
import {DataTypes} from "../types/DataTypes.sol";
import {PercentageMath} from "../math/PercentageMath.sol";

/**
 * @title ReserveConfiguration library
 * @author Aave
 * @notice Implements the bitmap logic to handle the reserve configuration
 */
library ReserveConfiguration {
    uint256 constant ACTIVE_MASK =                0xFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFE; // prettier-ignore
    uint256 constant FROZEN_MASK =                0xFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFD; // prettier-ignore
    uint256 constant BORROWING_MASK =             0xFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFB; // prettier-ignore
    uint256 constant STABLE_BORROWING_MASK =      0xFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF7; // prettier-ignore
    uint256 constant COLLATERAL_ENABLED_MASK =    0xFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFEF; // prettier-ignore
    uint256 constant RESERVE_FACTOR_MASK =        0xFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF0000000000000000FF; // prettier-ignore

    /// @dev For the ACTIVE_MASK, the start bit is 0, hence no bitshifting is needed
    uint256 constant IS_FROZEN_START_BIT_POSITION = 1;
    uint256 constant BORROWING_ENABLED_START_BIT_POSITION = 2;
    uint256 constant STABLE_BORROWING_ENABLED_START_BIT_POSITION = 3;
    uint256 constant COLLATERAL_ENABLED_START_BIT_POSITION = 4;
    uint256 constant RESERVE_FACTOR_START_BIT_POSITION = 8;

    uint256 constant MAX_VALID_RESERVE_FACTOR = 2**64-1; //64 bits

    /**
     * @dev Sets the active state of the reserve
     * @param self The reserve configuration
     * @param active The active state
     **/
    function setActive(
        DataTypes.ReserveConfigurationMap memory self,
        bool active
    ) internal pure {
        self.data =
            (self.data & ACTIVE_MASK) |
            (uint256(active ? 1 : 0));
    }

    /**
     * @dev Gets the active state of the reserve
     * @param self The reserve configuration
     * @return The active state
     **/
    function getActive(DataTypes.ReserveConfigurationMap memory self)
        internal
        pure
        returns (bool)
    {
        return (self.data & ~ACTIVE_MASK) != 0;
    }

    /**
     * @dev Sets the frozen state of the reserve
     * @param self The reserve configuration
     * @param frozen The frozen state
     **/
    function setFrozen(
        DataTypes.ReserveConfigurationMap memory self,
        bool frozen
    ) internal pure {
        self.data =
            (self.data & FROZEN_MASK) |
            (uint256(frozen ? 1 : 0) << IS_FROZEN_START_BIT_POSITION);
    }

    /**
     * @dev Gets the frozen state of the reserve
     * @param self The reserve configuration
     * @return The frozen state
     **/
    function getFrozen(DataTypes.ReserveConfigurationMap memory self)
        internal
        pure
        returns (bool)
    {
        return (self.data & ~FROZEN_MASK) != 0;
    }

    /**
     * @dev Enables or disables borrowing on the reserve
     * @param self The reserve configuration
     * @param enabled True if the borrowing needs to be enabled, false otherwise
     **/
    function setBorrowingEnabled(
        DataTypes.ReserveConfigurationMap memory self,
        bool enabled
    ) internal pure {
        self.data =
            (self.data & BORROWING_MASK) |
            (uint256(enabled ? 1 : 0) << BORROWING_ENABLED_START_BIT_POSITION);
    }

    /**
     * @dev Gets the borrowing state of the reserve
     * @param self The reserve configuration
     * @return The borrowing state
     **/
    function getBorrowingEnabled(DataTypes.ReserveConfigurationMap memory self)
        internal
        pure
        returns (bool)
    {
        return (self.data & ~BORROWING_MASK) != 0;
    }

    /**
     * @dev Enables or disables stable rate borrowing on the reserve
     * @param self The reserve configuration
     * @param enabled True if the stable rate borrowing needs to be enabled, false otherwise
     **/
    function setStableRateBorrowingEnabled(
        DataTypes.ReserveConfigurationMap memory self,
        bool enabled
    ) internal pure {
        self.data =
            (self.data & STABLE_BORROWING_MASK) |
            (uint256(enabled ? 1 : 0) <<
                STABLE_BORROWING_ENABLED_START_BIT_POSITION);
    }

    /**
     * @dev Gets the stable rate borrowing state of the reserve
     * @param self The reserve configuration
     * @return The stable rate borrowing state
     **/
    function getStableRateBorrowingEnabled(
        DataTypes.ReserveConfigurationMap memory self
    ) internal pure returns (bool) {
        return (self.data & ~STABLE_BORROWING_MASK) != 0;
    }

    /**
     * @dev Sets the reserve factor of the reserve
     * @param self The reserve configuration
     * @param reserveFactor The reserve factor
     **/
    function setReserveFactor(
        DataTypes.ReserveConfigurationMap memory self,
        uint256 reserveFactor
    ) internal pure {
        require(
            reserveFactor <= MAX_VALID_RESERVE_FACTOR,
            Errors.RC_INVALID_RESERVE_FACTOR
        );

        self.data =
            (self.data & RESERVE_FACTOR_MASK) |
            (reserveFactor << RESERVE_FACTOR_START_BIT_POSITION);
    }

    /**
     * @dev Gets the reserve factor of the reserve
     * @param self The reserve configuration
     * @return The reserve factor
     **/
    function getReserveFactor(DataTypes.ReserveConfigurationMap memory self)
        internal
        pure
        returns (uint256)
    {
        return
            (self.data & ~RESERVE_FACTOR_MASK) >>
            RESERVE_FACTOR_START_BIT_POSITION;
    }
    /**
     * @dev Sets the active state of the reserve
     * @param self The reserve configuration
     * @param active The active state
     **/
    function setCollateralEnabled(
        DataTypes.ReserveConfigurationMap memory self,
        bool active
    ) internal pure {
        self.data =
            (self.data & COLLATERAL_ENABLED_MASK) |
            (uint256(active ? 1 : 0) << COLLATERAL_ENABLED_START_BIT_POSITION);
    }

    /**
     * @dev Gets the active state of the reserve
     * @param self The reserve configuration
     * @return The active state
     **/
    function getCollateralEnabled(DataTypes.ReserveConfigurationMap memory self)
        internal
        pure
        returns (bool)
    {
        return (self.data & ~COLLATERAL_ENABLED_MASK) != 0;
    }

    /**
     * @dev Gets the configuration flags of the reserve
     * @param self The reserve configuration
     * @return The state flags representing active, frozen, borrowing enabled, stableRateBorrowing enabled
     **/
    function getFlags(DataTypes.ReserveConfigurationMap memory self)
        internal
        pure
        returns (
            bool,
            bool,
            bool,
            bool
        )
    {
        uint256 dataLocal = self.data;

        return (
            (dataLocal & ~ACTIVE_MASK) != 0,
            (dataLocal & ~FROZEN_MASK) != 0,
            (dataLocal & ~BORROWING_MASK) != 0,
            (dataLocal & ~STABLE_BORROWING_MASK) != 0
        );
    }

    // NOTE: commented to clarify we won't be using these values, use asset mappings (if you want reserve factor, call it directly)

    // /**
    //  * @dev Gets the configuration paramters of the reserve
    //  * @param self The reserve configuration
    //  * @return The state params representing ltv, liquidation threshold, liquidation bonus, the reserve decimals
    //  **/
    // function getParams(DataTypes.ReserveConfigurationMap memory self)
    //     internal
    //     pure
    //     returns (
    //         uint256,
    //         uint256,
    //         uint256,
    //         uint256,
    //         uint256
    //     )
    // {
    //     uint256 dataLocal = self.data;

    //     return (
    //         dataLocal & ~LTV_MASK,
    //         (dataLocal & ~LIQUIDATION_THRESHOLD_MASK) >>
    //             LIQUIDATION_THRESHOLD_START_BIT_POSITION,
    //         (dataLocal & ~LIQUIDATION_BONUS_MASK) >>
    //             LIQUIDATION_BONUS_START_BIT_POSITION,
    //         (dataLocal & ~DECIMALS_MASK) >> RESERVE_DECIMALS_START_BIT_POSITION,
    //         (dataLocal & ~RESERVE_FACTOR_MASK) >>
    //             RESERVE_FACTOR_START_BIT_POSITION
    //     );
    // }

    // /**
    //  * @dev Gets the configuration paramters of the reserve from a memory object
    //  * @param self The reserve configuration
    //  * @return The state params representing ltv, liquidation threshold, liquidation bonus, the reserve decimals
    //  **/
    // function getParamsMemory(DataTypes.ReserveConfigurationMap memory self)
    //     internal
    //     pure
    //     returns (
    //         uint256,
    //         uint256,
    //         uint256,
    //         uint256,
    //         uint256
    //     )
    // {
    //     return (
    //         self.data & ~LTV_MASK,
    //         (self.data & ~LIQUIDATION_THRESHOLD_MASK) >>
    //             LIQUIDATION_THRESHOLD_START_BIT_POSITION,
    //         (self.data & ~LIQUIDATION_BONUS_MASK) >>
    //             LIQUIDATION_BONUS_START_BIT_POSITION,
    //         (self.data & ~DECIMALS_MASK) >> RESERVE_DECIMALS_START_BIT_POSITION,
    //         (self.data & ~RESERVE_FACTOR_MASK) >>
    //             RESERVE_FACTOR_START_BIT_POSITION
    //     );
    // }

    /**
     * @dev Gets the configuration flags of the reserve from a memory object
     * @param self The reserve configuration
     * @return The state flags representing active, frozen, borrowing enabled, stableRateBorrowing enabled
     **/
    function getFlagsMemory(DataTypes.ReserveConfigurationMap memory self)
        internal
        pure
        returns (
            bool,
            bool,
            bool,
            bool
        )
    {
        return (
            (self.data & ~ACTIVE_MASK) != 0,
            (self.data & ~FROZEN_MASK) != 0,
            (self.data & ~BORROWING_MASK) != 0,
            (self.data & ~STABLE_BORROWING_MASK) != 0
        );
    }
}

// SPDX-License-Identifier: agpl-3.0
pragma solidity >=0.8.0;

import {Errors} from "../helpers/Errors.sol";
import {DataTypes} from "../types/DataTypes.sol";

/**
 * @title UserConfiguration library
 * @author Aave
 * @notice Implements the bitmap logic to handle the user configuration
 */
library UserConfiguration {
    uint256 internal constant BORROWING_MASK =
        0x5555555555555555555555555555555555555555555555555555555555555555;

    /**
     * @dev Sets if the user is borrowing the reserve identified by reserveIndex
     * @param self The configuration object
     * @param reserveIndex The index of the reserve in the bitmap
     * @param borrowing True if the user is borrowing the reserve, false otherwise
     **/
    function setBorrowing(
        DataTypes.UserConfigurationMap storage self,
        uint256 reserveIndex,
        bool borrowing
    ) internal {
        require(reserveIndex < 128, Errors.UL_INVALID_INDEX);
        self.data =
            (self.data & ~(1 << (reserveIndex * 2))) |
            (uint256(borrowing ? 1 : 0) << (reserveIndex * 2));
    }

    /**
     * @dev Sets if the user is using as collateral the reserve identified by reserveIndex
     * @param self The configuration object
     * @param reserveIndex The index of the reserve in the bitmap
     * @param usingAsCollateral True if the user is usin the reserve as collateral, false otherwise
     **/
    function setUsingAsCollateral(
        DataTypes.UserConfigurationMap storage self,
        uint256 reserveIndex,
        bool usingAsCollateral
    ) internal {
        require(reserveIndex < 128, Errors.UL_INVALID_INDEX);
        self.data =
            (self.data & ~(1 << (reserveIndex * 2 + 1))) |
            (uint256(usingAsCollateral ? 1 : 0) << (reserveIndex * 2 + 1));
    }

    /**
     * @dev Used to validate if a user has been using the reserve for borrowing or as collateral
     * @param self The configuration object
     * @param reserveIndex The index of the reserve in the bitmap
     * @return True if the user has been using a reserve for borrowing or as collateral, false otherwise
     **/
    function isUsingAsCollateralOrBorrowing(
        DataTypes.UserConfigurationMap memory self,
        uint256 reserveIndex
    ) internal pure returns (bool) {
        require(reserveIndex < 128, Errors.UL_INVALID_INDEX);
        return (self.data >> (reserveIndex * 2)) & 3 != 0;
    }

    /**
     * @dev Used to validate if a user has been using the reserve for borrowing
     * @param self The configuration object
     * @param reserveIndex The index of the reserve in the bitmap
     * @return True if the user has been using a reserve for borrowing, false otherwise
     **/
    function isBorrowing(
        DataTypes.UserConfigurationMap memory self,
        uint256 reserveIndex
    ) internal pure returns (bool) {
        require(reserveIndex < 128, Errors.UL_INVALID_INDEX);
        return (self.data >> (reserveIndex * 2)) & 1 != 0;
    }

    /**
     * @dev Used to validate if a user has been using the reserve as collateral
     * @param self The configuration object
     * @param reserveIndex The index of the reserve in the bitmap
     * @return True if the user has been using a reserve as collateral, false otherwise
     **/
    function isUsingAsCollateral(
        DataTypes.UserConfigurationMap memory self,
        uint256 reserveIndex
    ) internal pure returns (bool) {
        require(reserveIndex < 128, Errors.UL_INVALID_INDEX);
        return (self.data >> (reserveIndex * 2 + 1)) & 1 != 0;
    }

    /**
     * @dev Used to validate if a user has been borrowing from any reserve
     * @param self The configuration object
     * @return True if the user has been borrowing any reserve, false otherwise
     **/
    function isBorrowingAny(DataTypes.UserConfigurationMap memory self)
        internal
        pure
        returns (bool)
    {
        return self.data & BORROWING_MASK != 0;
    }

    /**
     * @dev Used to validate if a user has not been using any reserve
     * @param self The configuration object
     * @return True if the user has been borrowing any reserve, false otherwise
     **/
    function isEmpty(DataTypes.UserConfigurationMap memory self)
        internal
        pure
        returns (bool)
    {
        return self.data == 0;
    }
}

// SPDX-License-Identifier: agpl-3.0
pragma solidity >=0.8.0;
import {ILendingPool} from "../../../interfaces/ILendingPool.sol";
import {DataTypes} from "../types/DataTypes.sol";
import {InitializableImmutableAdminUpgradeabilityProxy} from "../../libraries/aave-upgradeability/InitializableImmutableAdminUpgradeabilityProxy.sol";
import {IInitializableAToken} from "../../../interfaces/IInitializableAToken.sol";
import {IAaveIncentivesController} from "../../../interfaces/IAaveIncentivesController.sol";
import {IInitializableDebtToken} from "../../../interfaces/IInitializableDebtToken.sol";
import {ILendingPoolAddressesProvider} from "../../../interfaces/ILendingPoolAddressesProvider.sol";
import "../../../dependencies/openzeppelin/contracts/utils/Strings.sol";
// import "hardhat/console.sol";
library DeployATokens {
    struct DeployATokensVars {
        ILendingPool pool;
        ILendingPoolAddressesProvider addressProvider;
        DataTypes.InitReserveInputInternal internalInput;
    }

    /**
     * @dev Deploys and initializes the aToken and variableDebtToken for a reserve through a proxy
     * @return aTokenProxyAddress The deployed aToken proxy
     * @return variableDebtTokenProxyAddress The deployed variable dep proxy
     **/
    function deployATokens(DeployATokensVars memory vars)
        public
        returns (
            address aTokenProxyAddress,
            address variableDebtTokenProxyAddress
        )
    {
        aTokenProxyAddress = _initTokenWithProxy(
            vars.internalInput.aTokenImpl,
            getAbiEncodedAToken(vars)
        );


        variableDebtTokenProxyAddress = _initTokenWithProxy(
            vars.internalInput.variableDebtTokenImpl,
            abi.encodeWithSelector(
                IInitializableDebtToken.initialize.selector,
                vars.pool,
                vars.internalInput.input.underlyingAsset,
                vars.internalInput.trancheId,
                IAaveIncentivesController(
                    vars.internalInput.input.incentivesController
                ),
                vars.internalInput.assetdata.underlyingAssetDecimals,
                string(
                    abi.encodePacked(
                        vars.internalInput.assetdata.variableDebtTokenName,
                        Strings.toString(vars.internalInput.trancheId)
                    )
                ),
                string(
                    abi.encodePacked(
                        vars.internalInput.assetdata.variableDebtTokenSymbol,
                        Strings.toString(vars.internalInput.trancheId)
                    )
                )
            )
        );
    }

    function getAbiEncodedAToken(DeployATokensVars memory vars)
        public
        view
        returns (bytes memory)
    {
        return
            abi.encodeWithSelector(
                IInitializableAToken.initialize.selector,
                vars.pool,
                address(this), //lendingPoolConfigurator address
                vars.internalInput.input.treasury,
                vars.addressProvider.getVMEXTreasury(),
                vars.internalInput.input.underlyingAsset,
                vars.internalInput.trancheId,
                IAaveIncentivesController(
                    vars.internalInput.input.incentivesController
                ),
                vars.internalInput.assetdata.underlyingAssetDecimals,
                string(
                    abi.encodePacked(
                        vars.internalInput.assetdata.aTokenName,
                        Strings.toString(vars.internalInput.trancheId)
                    )
                ),
                string(
                    abi.encodePacked(
                        vars.internalInput.assetdata.aTokenSymbol,
                        Strings.toString(vars.internalInput.trancheId)
                    )
                )
            );
    }


    function _initTokenWithProxy(
        address implementation,
        bytes memory initParams
    ) public returns (address) {
        InitializableImmutableAdminUpgradeabilityProxy proxy = new InitializableImmutableAdminUpgradeabilityProxy(
                address(this)
            );

        proxy.initialize(implementation, initParams);

        return address(proxy);
    }
}

// SPDX-License-Identifier: agpl-3.0
pragma solidity >=0.8.0;

/**
 * @title Errors library
 * @author Aave
 * @notice Defines the error messages emitted by the different contracts of the Aave protocol
 * @dev Error messages prefix glossary:
 *  - VL = ValidationLogic
 *  - MATH = Math libraries
 *  - CT = Common errors between tokens (AToken, VariableDebtToken and StableDebtToken)
 *  - AT = AToken
 *  - SDT = StableDebtToken
 *  - VDT = VariableDebtToken
 *  - LP = LendingPool
 *  - LPAPR = LendingPoolAddressesProviderRegistry
 *  - LPC = LendingPoolConfiguration
 *  - RL = ReserveLogic
 *  - LPCM = LendingPoolCollateralManager
 *  - P = Pausable
 */
library Errors {
    //common errors
    string public constant CALLER_NOT_TRANCHE_ADMIN = "33"; // 'The caller must be the tranche admin'
    string public constant CALLER_NOT_GLOBAL_ADMIN = "84"; // 'The caller must be the global admin'
    string public constant BORROW_ALLOWANCE_NOT_ENOUGH = "59"; // User borrows on behalf, but allowance are too small

    //contract specific errors
    string public constant VL_INVALID_AMOUNT = "1"; // 'Amount must be greater than 0'
    string public constant VL_NO_ACTIVE_RESERVE = "2"; // 'Action requires an active reserve' also if try to deposit in tranche that doesn't exist
    string public constant VL_RESERVE_FROZEN = "3"; // 'Action cannot be performed because the reserve is frozen'
    string public constant VL_CURRENT_AVAILABLE_LIQUIDITY_NOT_ENOUGH = "4"; // 'The current liquidity is not enough'
    string public constant VL_NOT_ENOUGH_AVAILABLE_USER_BALANCE = "5"; // 'User cannot withdraw more than the available balance'
    string public constant VL_TRANSFER_NOT_ALLOWED = "6"; // 'Transfer cannot be allowed.'
    string public constant VL_BORROWING_NOT_ENABLED = "7"; // 'Borrowing is not enabled'
    string public constant VL_INVALID_INTEREST_RATE_MODE_SELECTED = "8"; // 'Invalid interest rate mode selected'
    string public constant VL_COLLATERAL_BALANCE_IS_0 = "9"; // 'The collateral balance is 0'
    string public constant VL_HEALTH_FACTOR_LOWER_THAN_LIQUIDATION_THRESHOLD =
        "10"; // 'Health factor is lesser than the liquidation threshold'
    string public constant VL_COLLATERAL_CANNOT_COVER_NEW_BORROW = "11"; // 'There is not enough collateral to cover a new borrow'
    string public constant VL_STABLE_BORROWING_NOT_ENABLED = "12"; // stable borrowing not enabled
    string public constant VL_COLLATERAL_SAME_AS_BORROWING_CURRENCY = "13"; // collateral is (mostly) the same currency that is being borrowed
    string public constant VL_AMOUNT_BIGGER_THAN_MAX_LOAN_SIZE_STABLE = "14"; // 'The requested amount is greater than the max loan size in stable rate mode
    string public constant VL_NO_DEBT_OF_SELECTED_TYPE = "15"; // 'for repayment of stable debt, the user needs to have stable debt, otherwise, he needs to have variable debt'
    string public constant VL_NO_EXPLICIT_AMOUNT_TO_REPAY_ON_BEHALF = "16"; // 'To repay on behalf of an user an explicit amount to repay is needed'
    string public constant VL_NO_STABLE_RATE_LOAN_IN_RESERVE = "17"; // 'User does not have a stable rate loan in progress on this reserve'
    string public constant VL_NO_VARIABLE_RATE_LOAN_IN_RESERVE = "18"; // 'User does not have a variable rate loan in progress on this reserve'
    string public constant VL_UNDERLYING_BALANCE_NOT_GREATER_THAN_0 = "19"; // 'The underlying balance needs to be greater than 0'
    string public constant VL_DEPOSIT_ALREADY_IN_USE = "20"; // 'User deposit is already being used as collateral'
    string public constant LP_NOT_ENOUGH_STABLE_BORROW_BALANCE = "21"; // 'User does not have any stable rate loan for this reserve'
    string public constant LP_INTEREST_RATE_REBALANCE_CONDITIONS_NOT_MET = "22"; // 'Interest rate rebalance conditions were not met'
    string public constant LP_LIQUIDATION_CALL_FAILED = "23"; // 'Liquidation call failed'
    string public constant LP_NOT_ENOUGH_LIQUIDITY_TO_BORROW = "24"; // 'There is not enough liquidity available to borrow'
    string public constant LP_REQUESTED_AMOUNT_TOO_SMALL = "25"; // 'The requested amount is too small for a FlashLoan.'
    string public constant LP_INCONSISTENT_PROTOCOL_ACTUAL_BALANCE = "26"; // 'The actual balance of the protocol is inconsistent'
    string public constant LP_CALLER_NOT_LENDING_POOL_CONFIGURATOR = "27"; // 'The caller of the function is not the lending pool configurator'
    string public constant LP_INCONSISTENT_FLASHLOAN_PARAMS = "28";
    string public constant CT_CALLER_MUST_BE_LENDING_POOL = "29"; // 'The caller of this function must be a lending pool'
    string public constant CT_CANNOT_GIVE_ALLOWANCE_TO_HIMSELF = "30"; // 'User cannot give allowance to himself'
    string public constant CT_TRANSFER_AMOUNT_NOT_GT_0 = "31"; // 'Transferred amount needs to be greater than zero'
    string public constant RL_RESERVE_ALREADY_INITIALIZED = "32"; // 'Reserve has already been initialized'
    string public constant LPC_RESERVE_LIQUIDITY_NOT_0 = "34"; // 'The liquidity of the reserve needs to be 0'
    string public constant LPC_INVALID_ATOKEN_POOL_ADDRESS = "35"; // 'The liquidity of the reserve needs to be 0'
    string public constant LPC_INVALID_STABLE_DEBT_TOKEN_POOL_ADDRESS = "36"; // 'The liquidity of the reserve needs to be 0'
    string public constant LPC_INVALID_VARIABLE_DEBT_TOKEN_POOL_ADDRESS = "37"; // 'The liquidity of the reserve needs to be 0'
    string public constant LPC_INVALID_STABLE_DEBT_TOKEN_UNDERLYING_ADDRESS =
        "38"; // 'The liquidity of the reserve needs to be 0'
    string public constant LPC_INVALID_VARIABLE_DEBT_TOKEN_UNDERLYING_ADDRESS =
        "39"; // 'The liquidity of the reserve needs to be 0'
    string public constant LPC_INVALID_ADDRESSES_PROVIDER_ID = "40"; // 'The liquidity of the reserve needs to be 0'
    string public constant LPC_INVALID_CONFIGURATION = "75"; // 'Invalid risk parameters for the reserve'
    string public constant LPC_CALLER_NOT_EMERGENCY_ADMIN = "76"; // 'The caller must be the emergency admin'
    string public constant LPAPR_PROVIDER_NOT_REGISTERED = "41"; // 'Provider is not registered'
    string public constant LPCM_HEALTH_FACTOR_NOT_BELOW_THRESHOLD = "42"; // 'Health factor is not below the threshold'
    string public constant LPCM_COLLATERAL_CANNOT_BE_LIQUIDATED = "43"; // 'The collateral chosen cannot be liquidated'
    string public constant LPCM_SPECIFIED_CURRENCY_NOT_BORROWED_BY_USER = "44"; // 'User did not borrow the specified currency'
    string public constant LPCM_NOT_ENOUGH_LIQUIDITY_TO_LIQUIDATE = "45"; // "There isn't enough liquidity available to liquidate"
    string public constant LPCM_NO_ERRORS = "46"; // 'No errors'
    string public constant LP_INVALID_FLASHLOAN_MODE = "47"; //Invalid flashloan mode selected
    string public constant MATH_MULTIPLICATION_OVERFLOW = "48";
    string public constant MATH_ADDITION_OVERFLOW = "49";
    string public constant MATH_DIVISION_BY_ZERO = "50";
    string public constant RL_LIQUIDITY_INDEX_OVERFLOW = "51"; //  Liquidity index overflows uint128
    string public constant RL_VARIABLE_BORROW_INDEX_OVERFLOW = "52"; //  Variable borrow index overflows uint128
    string public constant RL_LIQUIDITY_RATE_OVERFLOW = "53"; //  Liquidity rate overflows uint128
    string public constant RL_VARIABLE_BORROW_RATE_OVERFLOW = "54"; //  Variable borrow rate overflows uint128
    string public constant RL_STABLE_BORROW_RATE_OVERFLOW = "55"; //  Stable borrow rate overflows uint128
    string public constant CT_INVALID_MINT_AMOUNT = "56"; //invalid amount to mint
    string public constant LP_FAILED_REPAY_WITH_COLLATERAL = "57";
    string public constant CT_INVALID_BURN_AMOUNT = "58"; //invalid amount to burn
    string public constant LP_FAILED_COLLATERAL_SWAP = "60";
    string public constant LP_INVALID_EQUAL_ASSETS_TO_SWAP = "61";
    string public constant LP_REENTRANCY_NOT_ALLOWED = "62";
    string public constant LP_CALLER_MUST_BE_AN_ATOKEN = "63";
    string public constant LP_IS_PAUSED = "64"; // 'Pool is paused'
    string public constant LP_NO_MORE_RESERVES_ALLOWED = "65";
    string public constant LP_INVALID_FLASH_LOAN_EXECUTOR_RETURN = "66";
    string public constant RC_INVALID_LTV = "67";
    string public constant RC_INVALID_LIQ_THRESHOLD = "68";
    string public constant RC_INVALID_LIQ_BONUS = "69";
    string public constant RC_INVALID_DECIMALS = "70";
    string public constant RC_INVALID_RESERVE_FACTOR = "71";
    string public constant LPAPR_INVALID_ADDRESSES_PROVIDER_ID = "72";
    string public constant VL_INCONSISTENT_FLASHLOAN_PARAMS = "73";
    string public constant LP_INCONSISTENT_PARAMS_LENGTH = "74";
    string public constant UL_INVALID_INDEX = "77";
    string public constant LP_NOT_CONTRACT = "78";
    string public constant SDT_STABLE_DEBT_OVERFLOW = "79";
    string public constant SDT_BURN_EXCEEDS_BALANCE = "80";
    string public constant CT_CALLER_MUST_BE_STRATEGIST = "81";
    string public constant SUPPLY_CAP_EXCEEDED = "82";
    string public constant BORROW_CAP_EXCEEDED = "83";

    enum CollateralManagerErrors {
        NO_ERROR,
        NO_COLLATERAL_AVAILABLE,
        COLLATERAL_CANNOT_BE_LIQUIDATED,
        CURRRENCY_NOT_BORROWED,
        HEALTH_FACTOR_ABOVE_THRESHOLD,
        NOT_ENOUGH_LIQUIDITY,
        NO_ACTIVE_RESERVE,
        HEALTH_FACTOR_LOWER_THAN_LIQUIDATION_THRESHOLD,
        INVALID_EQUAL_ASSETS_TO_SWAP,
        FROZEN_RESERVE
    }
}

// SPDX-License-Identifier: agpl-3.0
pragma solidity >=0.8.0;

import {IERC20} from "../../../dependencies/openzeppelin/contracts/IERC20.sol";
import {DataTypes} from "../types/DataTypes.sol";

/**
 * @title Helpers library
 * @author Aave
 */
library Helpers {
    /**
     * @dev Fetches the user current variable debt balance
     * @param user The user address
     * @param reserve The reserve data object
     * @return The variable debt balance
     **/
    function getUserCurrentDebt(
        address user,
        DataTypes.ReserveData storage reserve
    ) internal view returns (uint256) {
        return IERC20(reserve.variableDebtTokenAddress).balanceOf(user);
    }

    function getUserCurrentDebtMemory(
        address user,
        DataTypes.ReserveData memory reserve
    ) internal view returns (uint256) {
        return IERC20(reserve.variableDebtTokenAddress).balanceOf(user);
    }
}

// SPDX-License-Identifier: agpl-3.0
pragma solidity >=0.8.0;

import {SafeMath} from "../../../dependencies/openzeppelin/contracts/SafeMath.sol";
import {IERC20} from "../../../dependencies/openzeppelin/contracts/IERC20.sol";
import {WadRayMath} from "../math/WadRayMath.sol";
import {PercentageMath} from "../math/PercentageMath.sol";
import {SafeERC20} from "../../../dependencies/openzeppelin/contracts/SafeERC20.sol";
import {ReserveConfiguration} from "../configuration/ReserveConfiguration.sol";
import {UserConfiguration} from "../configuration/UserConfiguration.sol";
import {Errors} from "../helpers/Errors.sol";
import {IReserveInterestRateStrategy} from "../../../interfaces/IReserveInterestRateStrategy.sol";
import {DataTypes} from "../types/DataTypes.sol";
import {ReserveLogic} from "./ReserveLogic.sol";
import {ValidationLogic} from "./ValidationLogic.sol";
import {IAToken} from "../../../interfaces/IAToken.sol";
import {IPriceOracleGetter} from "../../../interfaces/IPriceOracleGetter.sol";
import {IStableDebtToken} from "../../../interfaces/IStableDebtToken.sol";
import {IVariableDebtToken} from "../../../interfaces/IVariableDebtToken.sol";
import {IFlashLoanReceiver} from "../../../flashloan/interfaces/IFlashLoanReceiver.sol";
import {ILendingPoolAddressesProvider} from "../../../interfaces/ILendingPoolAddressesProvider.sol";
import {GenericLogic} from "./GenericLogic.sol";
import {AssetMappings} from "../../lendingpool/AssetMappings.sol";
/**
 * @title DepositWithdrawLogic library
 * @author VMEX
 * @notice Implements functions to deposit and withdraw
 */
library DepositWithdrawLogic {
    using SafeMath for uint256;
    using WadRayMath for uint256;
    using PercentageMath for uint256;
    using SafeERC20 for IERC20;
    using ReserveLogic for *;
    using UserConfiguration for *;
    using ReserveConfiguration for *;

    /**
     * @dev Emitted on setUserUseReserveAsCollateral()
     * @param reserve The address of the underlying asset of the reserve
     * @param trancheId The trancheId of the reserve
     * @param user The address of the user enabling the usage as collateral
     **/
    event ReserveUsedAsCollateralEnabled(
        address indexed reserve,
        uint64 trancheId,
        address indexed user
    );

    function _deposit(
        DataTypes.ReserveData storage self,
        DataTypes.DepositVars memory vars,
        DataTypes.UserConfigurationMap storage user
    ) external returns(uint256){
        if (vars.amount == type(uint256).max) {
            vars.amount = IAToken(vars.asset).balanceOf(msg.sender); //amount to deposit is the user's balance
        }
        ValidationLogic.validateDeposit(vars.asset, self, vars.amount, vars._assetMappings);

        address aToken = self.aTokenAddress;

        //these will simply not be used for collateral vault, and even if it is, it won't change anything, so this will just save gas
        self.updateState(vars._assetMappings.getVMEXReserveFactor(vars.asset));
        self.updateInterestRates(vars.asset, aToken, vars.amount, 0, vars._assetMappings.getVMEXReserveFactor(vars.asset));
        IPriceOracleGetter(
            ILendingPoolAddressesProvider(vars._addressesProvider).getPriceOracle()
        ).updateTWAP(vars.asset);

        IERC20(vars.asset).safeTransferFrom(msg.sender, aToken, vars.amount); //msg.sender should still be the user, not the contract

        bool isFirstDeposit = IAToken(aToken).mint(
            vars.onBehalfOf,
            vars.amount,
            self.liquidityIndex
        ); //this also considers if it is a first deposit into a trancheId, not just a specific asset

        if (isFirstDeposit) {
            // if collateral is enabled, by default the user's deposit is marked as collateral
            user.setUsingAsCollateral(self.id, self.configuration.getCollateralEnabled());
        }
        return vars.amount;
    }

    /**
     * @dev Emitted on setUserUseReserveAsCollateral()
     * @param reserve The address of the underlying asset of the reserve
     * @param trancheId The trancheId of the reserve
     * @param user The address of the user enabling the usage as collateral
     **/
    event ReserveUsedAsCollateralDisabled(
        address indexed reserve,
        uint64 trancheId,
        address indexed user
    );

    function _withdraw(
        mapping(address => mapping(uint64 => DataTypes.ReserveData))
            storage _reserves,
        DataTypes.UserConfigurationMap storage user,
        mapping(uint256 => address) storage _reservesList,
        DataTypes.WithdrawParams memory vars,
        ILendingPoolAddressesProvider _addressesProvider,
        AssetMappings _assetMappings
    ) external returns (uint256) {
        DataTypes.ReserveData storage reserve = _reserves[vars.asset][vars.trancheId];
        address aToken = reserve.aTokenAddress;

        uint256 userBalance = IAToken(aToken).balanceOf(msg.sender);
        //balanceOf actually multiplies the atokens that the user has by the liquidity index.
        //User A deposits 1000 DAI at the liquidity index of 1.1. He is actually minted 1000/1.1 = 909 scaled aTokens. But when he checks his balance, he finds 909 *1.1 = 1000
        //User B deposits another amount into the same pool. The liquidity index is now 1.2. User A now checks 909*1.2 = 1090.9, so he gets "interest" despite his scaled aTokens remaining the same
        //liquidityIndex is not 1 to 1 with pool amount. So there are additional funds left in pool in above case.

        if (vars.amount == type(uint256).max) {
            vars.amount = userBalance; //amount to withdraw
        }

        ValidationLogic.validateWithdraw(
            vars.asset,
            vars.trancheId,
            vars.amount,
            userBalance,
            _reserves,
            user,
            _reservesList,
            vars._reservesCount,
            _addressesProvider,
            _assetMappings
        );

        reserve.updateState(_assetMappings.getVMEXReserveFactor(vars.asset));
        reserve.updateInterestRates(vars.asset, aToken, 0, vars.amount, _assetMappings.getVMEXReserveFactor(vars.asset));

        IPriceOracleGetter(
            ILendingPoolAddressesProvider(_addressesProvider).getPriceOracle()
        ).updateTWAP(vars.asset);

        if (vars.amount == userBalance) {
            user.setUsingAsCollateral(reserve.id, false);
            emit ReserveUsedAsCollateralDisabled(vars.asset, vars.trancheId, msg.sender);
        }

        IAToken(aToken).burn(
            msg.sender,
            vars.to,
            vars.amount,
            reserve.liquidityIndex
        );

        return vars.amount;
    }

    function _borrowHelper(
        mapping(address => mapping(uint64 => DataTypes.ReserveData))
            storage _reserves,
        mapping(uint256 => address) storage _reservesList,
        DataTypes.UserConfigurationMap storage userConfig, //config of onBehalfOf user
        ILendingPoolAddressesProvider _addressesProvider,
        DataTypes.ExecuteBorrowParams memory vars
    ) external returns(uint256){
        IPriceOracleGetter(
            ILendingPoolAddressesProvider(_addressesProvider).getPriceOracle()
        ).updateTWAP(vars.asset);

        DataTypes.ReserveData storage reserve = _reserves[vars.asset][vars.trancheId];

        if(vars.amount == type(uint256).max){
            uint256 totalAmount = IERC20(vars.asset).balanceOf(reserve.aTokenAddress);
            (
                uint256 userCollateralBalanceETH,
                uint256 userBorrowBalanceETH,
                uint256 currentLtv,
                ,
                ,
                uint256 avgBorrowFactor
            ) = GenericLogic.calculateUserAccountData(
                DataTypes.AcctTranche(vars.user, vars.trancheId),
                _reserves,
                userConfig,
                _reservesList,
                vars._reservesCount,
                _addressesProvider,
                vars._assetMappings,
                true
            );
            vars.amount = (
                userCollateralBalanceETH.percentMul(currentLtv) //risk adjusted collateral
                .sub(userBorrowBalanceETH.percentMul(avgBorrowFactor)) //risk adjusted debt
            ) // amount available to use for borrow
            .percentDiv(vars._assetMappings.getBorrowFactor(vars.asset)) //adjust for this asset's borrow factor, in ETH
            .mul(10**vars._assetMappings.getDecimals(vars.asset))
            .div(vars.assetPrice); //converted to native token

            if(vars.amount>totalAmount){
                vars.amount=totalAmount;
            }
        }

        uint256 amountInETH = vars.assetPrice.mul(vars.amount).div(
                10**vars._assetMappings.getDecimals(vars.asset)
            ); //lp token decimals are 18, like ETH

        ValidationLogic.validateBorrow(
            vars,
            reserve,
            amountInETH,
            _reserves,
            userConfig,
            _reservesList,
            vars._reservesCount,
            _addressesProvider
        );

        reserve.updateState(vars._assetMappings.getVMEXReserveFactor(vars.asset));

        bool isFirstBorrowing = IVariableDebtToken(
                reserve.variableDebtTokenAddress
            ).mint(
                    vars.user, //msg.sender is the delegatee
                    vars.onBehalfOf, //onBehalfOf is the one with collateral, takes the debt tokens on behalf of the msg.sender
                    vars.amount,
                    reserve.variableBorrowIndex
                );

        if (isFirstBorrowing) {
            userConfig.setBorrowing(reserve.id, true);
        }

        reserve.updateInterestRates(
            vars.asset,
            vars.aTokenAddress,
            0,
            vars.releaseUnderlying ? vars.amount : 0,
            vars._assetMappings.getVMEXReserveFactor(vars.asset)
        );

        if (vars.releaseUnderlying) {
            IAToken(vars.aTokenAddress).transferUnderlyingTo(
                vars.user,
                vars.amount
            );
        }

        return vars.amount;
    }
}

// SPDX-License-Identifier: agpl-3.0
pragma solidity >=0.8.0;

import {SafeMath} from "../../../dependencies/openzeppelin/contracts/SafeMath.sol";
import {IERC20} from "../../../dependencies/openzeppelin/contracts/IERC20.sol";
import {ReserveLogic} from "./ReserveLogic.sol";
import {ReserveConfiguration} from "../configuration/ReserveConfiguration.sol";
import {UserConfiguration} from "../configuration/UserConfiguration.sol";
import {WadRayMath} from "../math/WadRayMath.sol";
import {PercentageMath} from "../math/PercentageMath.sol";
import {IPriceOracleGetter} from "../../../interfaces/IPriceOracleGetter.sol";
import {DataTypes} from "../types/DataTypes.sol";
import {Errors} from "../helpers/Errors.sol";
import {ILendingPoolAddressesProvider} from "../../../interfaces/ILendingPoolAddressesProvider.sol";
import {AssetMappings} from "../../lendingpool/AssetMappings.sol";
import {IAToken} from "../../../interfaces/IAToken.sol";
/**
 * @title GenericLogic library
 * @author Aave
 * @title Implements protocol-level logic to calculate and validate the state of a user
 */
library GenericLogic {
    using ReserveLogic for DataTypes.ReserveData;
    using SafeMath for uint256;
    using WadRayMath for uint256;
    using PercentageMath for uint256;
    using ReserveConfiguration for DataTypes.ReserveConfigurationMap;
    using UserConfiguration for DataTypes.UserConfigurationMap;

    uint256 public constant HEALTH_FACTOR_LIQUIDATION_THRESHOLD = 1 ether;

    struct balanceDecreaseAllowedLocalVars {
        uint256 decimals;
        uint256 liquidationThreshold;
        uint256 totalCollateralInETH;
        uint256 totalDebtInETH;
        uint256 avgLiquidationThreshold;
        uint256 avgBorrowFactor;
        uint256 amountToDecreaseInETH;
        uint256 collateralBalanceAfterDecrease;
        uint256 liquidationThresholdAfterDecrease;
        uint256 healthFactorAfterDecrease;
        uint256 currentPrice;
        bool reserveUsageAsCollateralEnabled;

    }

    //  * @param asset The address of the underlying asset of the reserve
    //  * @param user The address of the user
    //  * @param amount The amount to decrease
    struct BalanceDecreaseAllowedParameters {
        address asset;
        uint64 trancheId;
        address user;
        uint256 amount;
        ILendingPoolAddressesProvider addressesProvider;
        AssetMappings assetMappings;
    }

    /**
     * @dev Checks if a specific balance decrease is allowed
     * (i.e. doesn't bring the user borrow position health factor under HEALTH_FACTOR_LIQUIDATION_THRESHOLD)
     * @param reservesData The data of all the reserves
     * @param userConfig The user configuration
     * @param reserves The list of all the active reserves
     * @return true if the decrease of the balance is allowed
     **/
    function balanceDecreaseAllowed(
        BalanceDecreaseAllowedParameters calldata params,
        mapping(address => mapping(uint64 => DataTypes.ReserveData))
            storage reservesData,
        DataTypes.UserConfigurationMap calldata userConfig,
        mapping(uint256 => address) storage reserves,
        uint256 reservesCount
    ) external view returns (bool) {
        if (
            !userConfig.isBorrowingAny() ||
            !userConfig.isUsingAsCollateral(
                reservesData[params.asset][params.trancheId].id
            )
        ) {
            return true;
        }

        balanceDecreaseAllowedLocalVars memory vars;

        (, vars.liquidationThreshold, , vars.decimals, ) = params.assetMappings.getParams(params.asset);


        if (reservesData[params.asset][params.trancheId].configuration.getCollateralEnabled()==false){
            return true;
        }



        (
            vars.totalCollateralInETH,
            vars.totalDebtInETH,
            ,
            vars.avgLiquidationThreshold,
            ,
            vars.avgBorrowFactor
        ) = calculateUserAccountData(
            DataTypes.AcctTranche(params.user, params.trancheId),
            reservesData,
            userConfig,
            reserves,
            reservesCount,
            params.addressesProvider,
            params.assetMappings,
            true //this function is only used in the context of withdrawing or setting as not collateral, so it should be true
        );

        if (vars.totalDebtInETH == 0) {
            return true;
        }

        //using current price instead of 24 hour average
        vars.currentPrice= IPriceOracleGetter(
            params.addressesProvider.getPriceOracle(
            )
        ).getAssetPrice(params.asset);

        vars.amountToDecreaseInETH  = vars.currentPrice.mul(params.amount).div(10**vars.decimals);

        vars.collateralBalanceAfterDecrease = vars.totalCollateralInETH.sub(
            vars.amountToDecreaseInETH
        );

        //if there is a borrow, there can't be 0 collateral
        if (vars.collateralBalanceAfterDecrease == 0) {
            return false;
        }



        vars.liquidationThresholdAfterDecrease = vars
            .totalCollateralInETH
            .mul(vars.avgLiquidationThreshold)
            .sub(vars.amountToDecreaseInETH.mul(vars.liquidationThreshold))
            .div(vars.collateralBalanceAfterDecrease);


        vars.healthFactorAfterDecrease = calculateHealthFactorFromBalances(
            vars.collateralBalanceAfterDecrease,
            vars.totalDebtInETH,
            vars.liquidationThresholdAfterDecrease,
            vars.avgBorrowFactor
        );
        return
            vars.healthFactorAfterDecrease >=
            GenericLogic.HEALTH_FACTOR_LIQUIDATION_THRESHOLD;
    }

    struct CalculateUserAccountDataVars {
        uint64 currentTranche;
        uint64 trancheId;
        uint256 reserveUnitPrice;
        uint256 tokenUnit;
        uint256 compoundedLiquidityBalance;
        uint256 compoundedBorrowBalance;
        uint256 decimals;
        uint256 ltv;
        uint256 borrowFactor;
        uint256 liquidationThreshold;
        uint256 i;
        uint256 healthFactor;
        uint256 totalCollateralInETH;
        uint256 totalDebtInETH;
        uint256 avgLtv;
        uint256 avgLiquidationThreshold;
        uint256 thisDebtInEth;
        uint256 avgBorrowFactor;
        uint256 reservesLength;
        uint256 liquidityBalanceETH;
        uint256 reserveTwapUnitPrice;
        uint256 liquidityBalanceETHTWAP;
        address currentReserveAddress;
        address oracle;
        address user;
        bool healthFactorBelowThreshold;
        bool usageAsCollateralEnabled;
        bool userUsesReserveAsCollateral;
        bool useTwap;
    }

    /**
     * @dev Calculates the user data across the reserves.
     * this includes the total liquidity/collateral/borrow balances in ETH,
     * the average Loan To Value, the average Liquidation Ratio, and the Health factor.
     * @param actTranche The address of the user and trancheId
     * @param reservesData Data of all the reserves
     * @param userConfig The configuration of the user
     * @param reserves The list of the available reserves
     * @param addressesProvider The addresses provider address
     * @param assetMappings The addresses provider address
     * @return The total collateral and total debt of the user in ETH, the avg ltv, liquidation threshold and the HF
     **/
    function calculateUserAccountData(
        DataTypes.AcctTranche memory actTranche,
        mapping(address => mapping(uint64 => DataTypes.ReserveData))
            storage reservesData,
        DataTypes.UserConfigurationMap memory userConfig,
        mapping(uint256 => address) storage reserves,
        uint256 reservesCount,
        ILendingPoolAddressesProvider addressesProvider,
        AssetMappings assetMappings,
        bool useTwap
    )
        internal
        view
        returns (
            uint256,
            uint256,
            uint256,
            uint256,
            uint256,
            uint256
        )
    {
        CalculateUserAccountDataVars memory vars;
        vars.user = actTranche.user;
        vars.trancheId = actTranche.trancheId;
        vars.useTwap = useTwap;

        if (userConfig.isEmpty()) {
            return (0, 0, 0, 0, type(uint256).max, 0);
        }

        for (vars.i = 0; vars.i < reservesCount; vars.i++) {
            if (!userConfig.isUsingAsCollateralOrBorrowing(vars.i)) {
                continue;
            }

            vars.currentReserveAddress = reserves[vars.i];
            DataTypes.ReserveData storage currentReserve = reservesData[
                vars.currentReserveAddress
            ][vars.trancheId];

            vars.oracle = addressesProvider.getPriceOracle();

            (
                vars.ltv,
                vars.liquidationThreshold,
                ,
                vars.decimals,
                vars.borrowFactor
            ) = assetMappings.getParams(vars.currentReserveAddress);

            vars.tokenUnit = 10**vars.decimals;
            vars.reserveUnitPrice = IPriceOracleGetter(vars.oracle)
                .getAssetPrice(vars.currentReserveAddress);

            vars.reserveTwapUnitPrice = IPriceOracleGetter(vars.oracle)
                .getAssetTWAPPrice(vars.currentReserveAddress);

            if (
                currentReserve.configuration.getCollateralEnabled() &&
                userConfig.isUsingAsCollateral(vars.i)
            ) {
                vars.compoundedLiquidityBalance = IERC20(
                    currentReserve.aTokenAddress
                ).balanceOf(vars.user);

                vars.liquidityBalanceETH = vars
                    .reserveUnitPrice
                    .mul(vars.compoundedLiquidityBalance)
                    .div(vars.tokenUnit);

                if(vars.useTwap){
                    vars.liquidityBalanceETHTWAP = vars
                        .reserveTwapUnitPrice
                        .mul(vars.compoundedLiquidityBalance)
                        .div(vars.tokenUnit);

                    //this means the borrow must satisfy both current price and twap price
                    if(vars.liquidityBalanceETHTWAP < vars.liquidityBalanceETH){
                        vars.liquidityBalanceETH = vars.liquidityBalanceETHTWAP;
                    }
                }

                vars.totalCollateralInETH = vars.totalCollateralInETH.add(
                    vars.liquidityBalanceETH
                );

                vars.avgLtv = vars.avgLtv.add(
                    vars.liquidityBalanceETH.mul(vars.ltv)
                );
                vars.avgLiquidationThreshold = vars.avgLiquidationThreshold.add(
                    vars.liquidityBalanceETH.mul(vars.liquidationThreshold)
                );
            }

            if (userConfig.isBorrowing(vars.i)) {
                vars.compoundedBorrowBalance =
                    IERC20(currentReserve.variableDebtTokenAddress).balanceOf(vars.user);

                if(!useTwap || vars.reserveTwapUnitPrice<vars.reserveUnitPrice){
                    //if not using twap or if twap has lower price than regular, then use the regular price
                    vars.thisDebtInEth = vars.reserveUnitPrice.mul(vars.compoundedBorrowBalance).div(
                            vars.tokenUnit
                        );
                }
                else{
                    vars.thisDebtInEth = vars.reserveTwapUnitPrice.mul(vars.compoundedBorrowBalance).div(
                            vars.tokenUnit
                        );
                }

                vars.totalDebtInETH = vars.totalDebtInETH.add(
                    vars.thisDebtInEth
                );

                if(vars.borrowFactor != 0){
                    vars.avgBorrowFactor = vars.avgBorrowFactor.add(
                        vars.thisDebtInEth.mul(vars.borrowFactor)
                    );
                }
            }
        }

        vars.avgLtv = vars.totalCollateralInETH > 0
            ? vars.avgLtv.div(vars.totalCollateralInETH)
            : 0; //weighted average of all ltv's across all supplied assets
        vars.avgLiquidationThreshold = vars.totalCollateralInETH > 0
            ? vars.avgLiquidationThreshold.div(vars.totalCollateralInETH)
            : 0;
        vars.avgBorrowFactor = vars.totalDebtInETH > 0
            ? vars.avgBorrowFactor.div(vars.totalDebtInETH)
            : 0;

        vars.healthFactor = calculateHealthFactorFromBalances(
            vars.totalCollateralInETH,
            vars.totalDebtInETH,
            vars.avgLiquidationThreshold,
            vars.avgBorrowFactor
        );
        return (
            vars.totalCollateralInETH,
            vars.totalDebtInETH,
            vars.avgLtv,
            vars.avgLiquidationThreshold,
            vars.healthFactor,
            vars.avgBorrowFactor
        );
    }

    /**
     * @dev Calculates the health factor from the corresponding balances
     * @param totalCollateralInETH The total collateral in ETH
     * @param totalDebtInETH The total debt in ETH
     * @param liquidationThreshold The avg liquidation threshold
     * @param borrowFactor The borrow factor
     * @return The health factor calculated from the balances provided
     **/
    function calculateHealthFactorFromBalances(
        uint256 totalCollateralInETH,
        uint256 totalDebtInETH,
        uint256 liquidationThreshold,
        uint256 borrowFactor
    ) internal pure returns (uint256) {
        if (totalDebtInETH == 0) return type(uint256).max;

        return
            (totalCollateralInETH.percentMul(liquidationThreshold)).wadDiv(
                totalDebtInETH.percentMul(borrowFactor)
            );
    }

    /**
     * @dev Calculates the equivalent amount in ETH that an user can borrow, depending on the available collateral and the
     * average Loan To Value
     * @param totalCollateralInETH The total collateral in ETH
     * @param totalDebtInETH The total borrow balance
     * @param ltv The average loan to value
     * @return the amount available to borrow in ETH for the user
     **/

    function calculateAvailableBorrowsETH(
        uint256 totalCollateralInETH,
        uint256 totalDebtInETH,
        uint256 ltv,
        uint256 avgBorrowFactor
    ) internal pure returns (uint256) {
        uint256 availableBorrowsETH = totalCollateralInETH.percentMul(ltv);

        if (availableBorrowsETH < totalDebtInETH.percentMul(avgBorrowFactor)) {
            return 0;
        }

        availableBorrowsETH = availableBorrowsETH.sub(totalDebtInETH.percentMul(avgBorrowFactor));
        return availableBorrowsETH;
    }
}

// SPDX-License-Identifier: agpl-3.0
pragma solidity >=0.8.0;

import {SafeMath} from "../../../dependencies/openzeppelin/contracts/SafeMath.sol";
import {IERC20} from "../../../dependencies/openzeppelin/contracts/IERC20.sol";
import {SafeERC20} from "../../../dependencies/openzeppelin/contracts/SafeERC20.sol";
import {IAToken} from "../../../interfaces/IAToken.sol";
import {IStableDebtToken} from "../../../interfaces/IStableDebtToken.sol";
import {IVariableDebtToken} from "../../../interfaces/IVariableDebtToken.sol";
import {IReserveInterestRateStrategy} from "../../../interfaces/IReserveInterestRateStrategy.sol";
import {ReserveConfiguration} from "../configuration/ReserveConfiguration.sol";
import {MathUtils} from "../math/MathUtils.sol";
import {WadRayMath} from "../math/WadRayMath.sol";
import {PercentageMath} from "../math/PercentageMath.sol";
import {Errors} from "../helpers/Errors.sol";
import {DataTypes} from "../types/DataTypes.sol";

import {IBaseStrategy} from "../../../interfaces/IBaseStrategy.sol";
// import "hardhat/console.sol";
/**
 * @title ReserveLogic library
 * @author Aave
 * @notice Implements the logic to update the reserves state
 */
library ReserveLogic {
    using SafeMath for uint256;
    using WadRayMath for uint256;
    using PercentageMath for uint256;
    using SafeERC20 for IERC20;

    /**
     * @dev Emitted when the state of a reserve is updated
     * @param reserve The address of the underlying asset of the reserve
     * @param trancheId The trancheId of the reserve
     * @param liquidityRate The new liquidity rate
     * @param variableBorrowRate The new variable borrow rate
     * @param liquidityIndex The new liquidity index
     * @param variableBorrowIndex The new variable borrow index
     **/
    event ReserveDataUpdated(
        address indexed reserve,
        uint64 indexed trancheId,
        uint256 liquidityRate,
        uint256 variableBorrowRate,
        uint256 liquidityIndex,
        uint256 variableBorrowIndex
    );

    using ReserveLogic for DataTypes.ReserveData;
    using ReserveConfiguration for DataTypes.ReserveConfigurationMap;

    /**
     * @dev Returns the ongoing normalized income for the reserve
     * A value of 1e27 means there is no income. As time passes, the income is accrued
     * A value of 2*1e27 means for each unit of asset one unit of income has been accrued
     * @param reserve The reserve object
     * @return the normalized income. expressed in ray
     **/
    function getNormalizedIncome(DataTypes.ReserveData storage reserve)
        internal
        view
        returns (uint256)
    {
        uint40 timestamp = reserve.lastUpdateTimestamp;
        // console.log("getNormalizedIncome liquidity index: ", reserve.liquidityIndex);

        //solium-disable-next-line
        if (timestamp == uint40(block.timestamp) || IAToken(reserve.aTokenAddress).getStrategy() != address(0)) { //if it has a strategy, it just the liquidityIndex
            //if the index was updated in the same block, no need to perform any calculation
            // console.log("Just returning liquidity index: ");
            return reserve.liquidityIndex;
        }
        // console.log("current timestamp: ", block.timestamp);
        // console.log("last update timestamp: ", timestamp);
        // console.log("reserve.currentLiquidityRate: ", reserve.currentLiquidityRate);

        uint256 cumulated = MathUtils
            .calculateLinearInterest(reserve.currentLiquidityRate, timestamp)
            .rayMul(reserve.liquidityIndex);

        return cumulated;
    }

    /**
     * @dev Returns the ongoing normalized variable debt for the reserve
     * A value of 1e27 means there is no debt. As time passes, the income is accrued
     * A value of 2*1e27 means that for each unit of debt, one unit worth of interest has been accumulated
     * @param reserve The reserve object
     * @return The normalized variable debt. expressed in ray
     **/
    function getNormalizedDebt(DataTypes.ReserveData storage reserve)
        internal
        view
        returns (uint256)
    {
        uint40 timestamp = reserve.lastUpdateTimestamp;

        //solium-disable-next-line
        if (timestamp == uint40(block.timestamp)) {
            //if the index was updated in the same block, no need to perform any calculation
            return reserve.variableBorrowIndex;
        }

        uint256 cumulated = MathUtils
            .calculateCompoundedInterest(
                reserve.currentVariableBorrowRate,
                timestamp
            )
            .rayMul(reserve.variableBorrowIndex);

        return cumulated;
    }

    /**
     * @dev Updates the liquidity cumulative index and the variable borrow index.
     * @param reserve the reserve object
     * @param vmexReserveFactor the global vmex reserve factor, used to mint to vmex treasury
     **/
    function updateState(DataTypes.ReserveData storage reserve, uint256 vmexReserveFactor) internal {
        address strategist = IAToken(reserve.aTokenAddress).getStrategy();
        if (strategist==address(0)) { //no strategist, so keep original method of calculating
            uint256 scaledVariableDebt = IVariableDebtToken(
                reserve.variableDebtTokenAddress
            ).scaledTotalSupply();
            uint256 previousVariableBorrowIndex = reserve.variableBorrowIndex;
            uint256 previousLiquidityIndex = reserve.liquidityIndex;
            uint40 lastUpdatedTimestamp = reserve.lastUpdateTimestamp;

            (uint256 newLiquidityIndex, uint256 newVariableBorrowIndex) = _updateIndexes(
                reserve,
                scaledVariableDebt, //for curve, this will always be zero, but the currentLiquidityRate gets updated with the tends. Don't need to pass in strategist address since currentLiquidityRate gets updated elsewhere
                previousLiquidityIndex,
                previousVariableBorrowIndex,
                lastUpdatedTimestamp
            );
            //no strategist, so keep original method of minting to treasury. For strategies, minting to treasury will be handled during tend()
            _mintToTreasury(
                reserve,
                scaledVariableDebt,
                previousVariableBorrowIndex,
                newLiquidityIndex,
                newVariableBorrowIndex,
                lastUpdatedTimestamp,
                vmexReserveFactor
            );
        } else {
            revert("NOT IMPLEMENTED");      // TODO: Update state for strategies
        }
    }

    /**
     * @dev Accumulates a predefined amount of asset to the reserve as a fixed, instantaneous income. Used for example to accumulate
     * the flashloan fee to the reserve, and spread it between all the depositors
     * @param reserve The reserve object
     * @param totalLiquidity The total liquidity available in the reserve
     * @param amount The amount to accomulate
     **/
    function cumulateToLiquidityIndex(
        DataTypes.ReserveData storage reserve,
        uint256 totalLiquidity,
        uint256 amount
    ) internal {
        uint256 amountToLiquidityRatio = amount.wadToRay().rayDiv(
            totalLiquidity.wadToRay()
        );

        uint256 result = amountToLiquidityRatio.add(WadRayMath.ray());

        result = result.rayMul(reserve.liquidityIndex);
        require(
            result <= type(uint128).max,
            Errors.RL_LIQUIDITY_INDEX_OVERFLOW
        );

        reserve.liquidityIndex = uint128(result);
    }

    /**
     * @dev Initializes a reserve
     * @param reserve The reserve object
     * @param aTokenAddress The address of the overlying atoken contract
     **/
    function init(
        DataTypes.ReserveData storage reserve,
        address aTokenAddress,
        address variableDebtTokenAddress,
        address interestRateStrategyAddress,
        uint64 trancheId
    ) external {
        require(
            reserve.aTokenAddress == address(0),
            Errors.RL_RESERVE_ALREADY_INITIALIZED
        );
        {
            reserve.liquidityIndex = uint128(WadRayMath.ray());
            reserve.variableBorrowIndex = uint128(WadRayMath.ray());
            reserve.aTokenAddress = aTokenAddress;
            reserve.variableDebtTokenAddress = variableDebtTokenAddress;
        }
        {
            reserve.interestRateStrategyAddress = interestRateStrategyAddress;
            //TODO: users choose from governance approved set of strategies
            reserve.trancheId = trancheId;
        }
    }

    struct UpdateInterestRatesLocalVars {
        uint256 availableLiquidity;
        uint256 newLiquidityRate;
        uint256 newVariableRate;
        uint256 totalVariableDebt;
    }

    /**
     * @dev Updates the reserve current variable borrow rate and the current liquidity rate
     * @param reserve The address of the reserve to be updated
     * @param liquidityAdded The amount of liquidity added to the protocol (deposit or repay) in the previous action
     * @param liquidityTaken The amount of liquidity taken from the protocol (redeem or borrow)
     * @param vmexReserveFactor The vmex reserve factor
     **/
    function updateInterestRates(
        DataTypes.ReserveData storage reserve,
        address reserveAddress,
        address aTokenAddress,
        uint256 liquidityAdded,
        uint256 liquidityTaken,
        uint256 vmexReserveFactor
    ) internal {
        if (IAToken(reserve.aTokenAddress).getStrategy() == address(0)) {
            UpdateInterestRatesLocalVars memory vars;

            //calculates the total variable debt locally using the scaled total supply instead
            //of totalSupply(), as it's noticeably cheaper. Also, the index has been
            //updated by the previous updateState() call
            vars.totalVariableDebt = IVariableDebtToken(
                reserve.variableDebtTokenAddress
            ).scaledTotalSupply().rayMul(reserve.variableBorrowIndex);

            DataTypes.calculateInterestRatesVars memory calvars =
                DataTypes.calculateInterestRatesVars(
                        reserveAddress,
                        aTokenAddress,
                        liquidityAdded,
                        liquidityTaken,
                        vars.totalVariableDebt,
                        reserve.configuration.getReserveFactor(),
                        vmexReserveFactor
                    );
            (
                vars.newLiquidityRate,
                vars.newVariableRate
            ) = IReserveInterestRateStrategy(
                reserve.interestRateStrategyAddress
            ).calculateInterestRates(calvars);

            require(
                vars.newLiquidityRate <= type(uint128).max,
                Errors.RL_LIQUIDITY_RATE_OVERFLOW
            );
            require(
                vars.newVariableRate <= type(uint128).max,
                Errors.RL_VARIABLE_BORROW_RATE_OVERFLOW
            );

            reserve.currentLiquidityRate = uint128(vars.newLiquidityRate);
            reserve.currentVariableBorrowRate = uint128(vars.newVariableRate);

            emit ReserveDataUpdated(
                reserveAddress,
                reserve.trancheId,
                vars.newLiquidityRate,
                vars.newVariableRate,
                reserve.liquidityIndex,
                reserve.variableBorrowIndex
            );
        } else {
            revert("NOT IMPLEMENTED");      // TODO: Update interest rates for strategies
        }
    }


    struct MintToTreasuryLocalVars {
        uint256 currentVariableDebt;
        uint256 previousVariableDebt;
        uint256 totalDebtAccrued;
        uint256 amountToMint;
        uint256 amountToMintVMEX;
        uint256 reserveFactor;
        uint256 globalVMEXReserveFactor;
    }

    /**
     * @dev Mints part of the repaid interest to the reserve treasury as a function of the reserveFactor for the
     * specific asset.
     * @param reserve The reserve reserve to be updated
     * @param scaledVariableDebt The current scaled total variable debt
     * @param previousVariableBorrowIndex The variable borrow index before the last accumulation of the interest
     * @param newLiquidityIndex The new liquidity index
     * @param newVariableBorrowIndex The variable borrow index after the last accumulation of the interest
     * @param timestamp The timestamp before the last accumulation of the interest
     * @param vmexReserveFactor The global vmex reserve factor
     **/
    function _mintToTreasury(
        DataTypes.ReserveData storage reserve,
        uint256 scaledVariableDebt,
        uint256 previousVariableBorrowIndex,
        uint256 newLiquidityIndex,
        uint256 newVariableBorrowIndex,
        uint40 timestamp,
        uint256 vmexReserveFactor
    ) internal {
        MintToTreasuryLocalVars memory vars;
        vars.reserveFactor = reserve.configuration.getReserveFactor();
        vars.globalVMEXReserveFactor = vmexReserveFactor;

        if (vars.reserveFactor == 0 && vars.globalVMEXReserveFactor == 0) {
            return;
        }

        //calculate the last principal variable debt
        vars.previousVariableDebt = scaledVariableDebt.rayMul(
            previousVariableBorrowIndex
        );

        //calculate the new total supply after accumulation of the index
        vars.currentVariableDebt = scaledVariableDebt.rayMul(
            newVariableBorrowIndex
        );

        //debt accrued is the sum of the current debt minus the sum of the debt at the last update
        //note that repay did not have to occur for this to be higher.
        vars.totalDebtAccrued = vars
            .currentVariableDebt
            .sub(vars.previousVariableDebt);

        vars.amountToMint = vars
            .totalDebtAccrued
            .percentMul(vars.reserveFactor); //permissionless pool owners will always get their reserveFactor * debt

        if (vars.amountToMint != 0) {
            IAToken(reserve.aTokenAddress).mintToTreasury(
                vars.amountToMint,
                newLiquidityIndex
            );
        }

        vars.amountToMintVMEX = vars
            .totalDebtAccrued
            .percentMul(
                PercentageMath.PERCENTAGE_FACTOR.sub(vars.reserveFactor)
            )
            .percentMul(
                vars.globalVMEXReserveFactor //for global VMEX reserve
            ); //we will get (1-reserveFactor) * vmexReserveFactor * debt
        //P = total earned
        //x = reserveFactor
        //y = VMEX reserve factor
        //user gets P*(1-x)*(1-y)
        //pool owner gets P*x
        //VMEX gets P*(1-x)*y
        //total distribution: P * (1-x-y+xy + x + y-xy) = P

        if (vars.amountToMintVMEX != 0) {
            IAToken(reserve.aTokenAddress).mintToVMEXTreasury(
                vars.amountToMintVMEX,
                newLiquidityIndex
            );
        }
    }

    /**
     * @dev Updates the reserve indexes and the timestamp of the update
     * @param reserve The reserve reserve to be updated
     * @param scaledVariableDebt The scaled variable debt
     * @param liquidityIndex The last stored liquidity index
     * @param variableBorrowIndex The last stored variable borrow index
     **/
    function _updateIndexes(
        DataTypes.ReserveData storage reserve,
        uint256 scaledVariableDebt,
        uint256 liquidityIndex,
        uint256 variableBorrowIndex,
        uint40 timestamp
    ) internal returns (uint256, uint256) {
        uint256 currentLiquidityRate = reserve.currentLiquidityRate;

        uint256 newLiquidityIndex = liquidityIndex;
        uint256 newVariableBorrowIndex = variableBorrowIndex;

        //only cumulating if there is any income being produced
        if (currentLiquidityRate > 0) {
            //consider strategies cumulatedLiquidityInterest can be calculated via ppfs approach
            uint256 cumulatedLiquidityInterest = MathUtils
                .calculateLinearInterest(currentLiquidityRate, timestamp); //if currentLiquidityRate is 1% APR, and the time difference between current block and last update was half a year then this function will return 0.5% + 100%
            newLiquidityIndex = cumulatedLiquidityInterest.rayMul(
                liquidityIndex
            ); //now this will calculate the true interest earned on the previous balance (liquidityIndex), 1.005 * liquidityIndex = new liquidityIndex. liquidityIndex will always increase regardless of borrows and withdraws
            //note if x is original liquidity index, and you deposit 100, your scaled aToken balance is 100/x. Then, you wait a year at 1 % interest rate, so this newLiquidityIndex will be 1.01 * x, so your balance is 100/x * x *1.01 = 101 as expected
            require(
                newLiquidityIndex <= type(uint128).max,
                Errors.RL_LIQUIDITY_INDEX_OVERFLOW
            );

            reserve.liquidityIndex = uint128(newLiquidityIndex);

            //check that there is actual variable debt before accumulating
            if (scaledVariableDebt != 0) {
                uint256 cumulatedVariableBorrowInterest = MathUtils
                    .calculateCompoundedInterest(
                        reserve.currentVariableBorrowRate,
                        timestamp
                    );
                newVariableBorrowIndex = cumulatedVariableBorrowInterest.rayMul(
                        variableBorrowIndex
                    );
                require(
                    newVariableBorrowIndex <= type(uint128).max,
                    Errors.RL_VARIABLE_BORROW_INDEX_OVERFLOW
                );
                reserve.variableBorrowIndex = uint128(newVariableBorrowIndex);
            }
        }

        //solium-disable-next-line
        reserve.lastUpdateTimestamp = uint40(block.timestamp);
        return (newLiquidityIndex, newVariableBorrowIndex);
    }
}

// SPDX-License-Identifier: agpl-3.0
pragma solidity >=0.8.0;

import {SafeMath} from "../../../dependencies/openzeppelin/contracts/SafeMath.sol";
import {IERC20} from "../../../dependencies/openzeppelin/contracts/IERC20.sol";
import {ReserveLogic} from "./ReserveLogic.sol";
import {GenericLogic} from "./GenericLogic.sol";
import {WadRayMath} from "../math/WadRayMath.sol";
import {PercentageMath} from "../math/PercentageMath.sol";
import {SafeERC20} from "../../../dependencies/openzeppelin/contracts/SafeERC20.sol";
import {ReserveConfiguration} from "../configuration/ReserveConfiguration.sol";
import {UserConfiguration} from "../configuration/UserConfiguration.sol";
import {Errors} from "../helpers/Errors.sol";
import {IReserveInterestRateStrategy} from "../../../interfaces/IReserveInterestRateStrategy.sol";
import {DataTypes} from "../types/DataTypes.sol";
import {ILendingPoolAddressesProvider} from "../../../interfaces/ILendingPoolAddressesProvider.sol";
import {AssetMappings} from "../../lendingpool/AssetMappings.sol";
import {IAToken} from "../../../interfaces/IAToken.sol";
import {IVariableDebtToken} from "../../../interfaces/IVariableDebtToken.sol";

/**
 * @title ReserveLogic library
 * @author Aave
 * @notice Implements functions to validate the different actions of the protocol
 */
library ValidationLogic {
    using ReserveLogic for DataTypes.ReserveData;
    using SafeMath for uint256;
    using WadRayMath for uint256;
    using PercentageMath for uint256;
    using SafeERC20 for IERC20;
    using ReserveConfiguration for DataTypes.ReserveConfigurationMap;
    using UserConfiguration for DataTypes.UserConfigurationMap;

    uint256 public constant REBALANCE_UP_LIQUIDITY_RATE_THRESHOLD = 4000;
    uint256 public constant REBALANCE_UP_USAGE_RATIO_THRESHOLD = 0.95 * 1e27; //usage ratio of 95%

    /**
     * @dev Validates a deposit action
     * @param reserve The reserve object on which the user is depositing
     * @param amount The amount to be deposited
     */
    function validateDeposit(
        address asset,
        DataTypes.ReserveData storage reserve,
        uint256 amount,
        AssetMappings _assetMappings
    ) external view {
        (bool isActive, bool isFrozen, , ) = reserve.configuration.getFlags();

        require(amount != 0, Errors.VL_INVALID_AMOUNT);
        require(isActive, Errors.VL_NO_ACTIVE_RESERVE);
        require(!isFrozen, Errors.VL_RESERVE_FROZEN);

        uint256 supplyCap = _assetMappings.getSupplyCap(asset);
        require(
            supplyCap == 0 ||
                (IAToken(reserve.aTokenAddress).totalSupply() + amount) <=
                supplyCap * (10**_assetMappings.getDecimals(asset)),
            Errors.SUPPLY_CAP_EXCEEDED
        );
    }

    /**
     * @dev Validates a withdraw action
     * @param reserveAddress The address of the reserve
     * @param amount The amount to be withdrawn
     * @param userBalance The balance of the user
     * @param reservesData The reserves state
     * @param userConfig The user configuration
     * @param reserves The addresses of the reserves
     * @param reservesCount The number of reserves
     * @param _addressesProvider The price oracle
     */
    function validateWithdraw(
        address reserveAddress,
        uint64 trancheId,
        uint256 amount,
        uint256 userBalance,
        mapping(address => mapping(uint64 => DataTypes.ReserveData))
            storage reservesData,
        DataTypes.UserConfigurationMap storage userConfig,
        mapping(uint256 => address) storage reserves,
        uint256 reservesCount,
        ILendingPoolAddressesProvider _addressesProvider,
        AssetMappings _assetMappings
    ) external view {
        require(amount != 0, Errors.VL_INVALID_AMOUNT);
        require(
            amount <= userBalance,
            Errors.VL_NOT_ENOUGH_AVAILABLE_USER_BALANCE
        );

        (bool isActive, , , ) = reservesData[reserveAddress][trancheId]
            .configuration
            .getFlags();
        require(isActive, Errors.VL_NO_ACTIVE_RESERVE);

        require(
            GenericLogic.balanceDecreaseAllowed(
                GenericLogic.BalanceDecreaseAllowedParameters(
                    reserveAddress,
                    trancheId,
                    msg.sender,
                    amount,
                    _addressesProvider,
                    _assetMappings
                ),
                reservesData,
                userConfig,
                reserves,
                reservesCount
            ),
            Errors.VL_TRANSFER_NOT_ALLOWED
        );
    }

    struct ValidateBorrowLocalVars {
        uint256 currentLtv;
        uint256 currentLiquidationThreshold;
        uint256 amountOfCollateralNeededETH;
        uint256 userCollateralBalanceETH;
        uint256 userBorrowBalanceETH;
        uint256 availableLiquidity;
        uint256 healthFactor;
        uint256 borrowCap;
        uint256 avgBorrowFactor;

        bool isActive;
        bool isFrozen;
        bool borrowingEnabled;
    }

    function validateBorrow(
        DataTypes.ExecuteBorrowParams memory exvars,
        DataTypes.ReserveData storage reserve,
        uint256 amountInETH,
        mapping(address => mapping(uint64 => DataTypes.ReserveData))
            storage reservesData,
        DataTypes.UserConfigurationMap storage userConfig,
        mapping(uint256 => address) storage reserves,
        uint256 reservesCount,
        ILendingPoolAddressesProvider _addressesProvider
    ) external view {
        ValidateBorrowLocalVars memory vars;

        (
            vars.isActive,
            vars.isFrozen,
            vars.borrowingEnabled,
        ) = reserve.configuration.getFlags();

        require(vars.isActive, Errors.VL_NO_ACTIVE_RESERVE);
        require(!vars.isFrozen, Errors.VL_RESERVE_FROZEN);
        require(exvars.amount != 0, Errors.VL_INVALID_AMOUNT);

        require(vars.borrowingEnabled, Errors.VL_BORROWING_NOT_ENABLED);

        vars.borrowCap = exvars._assetMappings.getBorrowCap(exvars.asset);

        if (vars.borrowCap != 0) {
            unchecked {
                require(
                    IERC20(reserve.variableDebtTokenAddress).totalSupply() + exvars.amount <=
                        vars.borrowCap * 10**exvars._assetMappings.getDecimals(exvars.asset),
                    Errors.BORROW_CAP_EXCEEDED
                );
            }
        }

        (
            vars.userCollateralBalanceETH,
            vars.userBorrowBalanceETH,
            vars.currentLtv,
            vars.currentLiquidationThreshold,
            vars.healthFactor,
            vars.avgBorrowFactor
        ) = GenericLogic.calculateUserAccountData(
            DataTypes.AcctTranche(exvars.user, exvars.trancheId),
            reservesData,
            userConfig,
            reserves,
            reservesCount,
            _addressesProvider,
            exvars._assetMappings,
            true //borrows need to use twap
        );

        //(uint256(14), uint256(14), uint256(14), uint256(14), uint256(14));

        require(
            vars.userCollateralBalanceETH > 0,
            Errors.VL_COLLATERAL_BALANCE_IS_0
        );

        require(
            vars.healthFactor >
                GenericLogic.HEALTH_FACTOR_LIQUIDATION_THRESHOLD,
            Errors.VL_HEALTH_FACTOR_LOWER_THAN_LIQUIDATION_THRESHOLD
        );

        //add the current already borrowed amount to the amount requested to calculate the total collateral needed.
        //risk adjusted debt
        vars.amountOfCollateralNeededETH = vars
            .userBorrowBalanceETH
            .percentMul(vars.avgBorrowFactor)
            .add(amountInETH.percentMul(exvars._assetMappings.getBorrowFactor(exvars.asset))) //this amount that we are borrowing also has a borrow factor that increases the actual debt
            .percentDiv(vars.currentLtv); //LTV is calculated in percentage

        require(
            vars.amountOfCollateralNeededETH <= vars.userCollateralBalanceETH,
            Errors.VL_COLLATERAL_CANNOT_COVER_NEW_BORROW
        );
    }

    /**
     * @dev Validates a repay action
     * @param reserve The reserve state from which the user is repaying
     * @param amountSent The amount sent for the repayment. Can be an actual value or type(uint256).max
     * @param onBehalfOf The address of the user msg.sender is repaying for
     * @param variableDebt The borrow balance of the user
     */
    function validateRepay(
        DataTypes.ReserveData storage reserve,
        uint256 amountSent,
        address onBehalfOf,
        uint256 variableDebt
    ) external view {
        bool isActive = reserve.configuration.getActive();

        require(isActive, Errors.VL_NO_ACTIVE_RESERVE);

        require(amountSent > 0, Errors.VL_INVALID_AMOUNT);

        require(variableDebt > 0, Errors.VL_NO_DEBT_OF_SELECTED_TYPE);

        require(
            amountSent != type(uint256).max || msg.sender == onBehalfOf,
            Errors.VL_NO_EXPLICIT_AMOUNT_TO_REPAY_ON_BEHALF
        );
    }

    /**
     * @dev Validates the action of setting an asset as collateral
     * @param reserve The state of the reserve that the user is enabling or disabling as collateral
     * @param reserveAddress The address of the reserve
     * @param reservesData The data of all the reserves
     * @param userConfig The state of the user for the specific reserve
     * @param reserves The addresses of all the active reserves
     * @param _addressesProvider The price oracle
     */
    function validateSetUseReserveAsCollateral(
        DataTypes.ReserveData storage reserve,
        address reserveAddress,
        bool useAsCollateral,
        mapping(address => mapping(uint64 => DataTypes.ReserveData))
            storage reservesData,
        DataTypes.UserConfigurationMap storage userConfig,
        mapping(uint256 => address) storage reserves,
        uint256 reservesCount,
        ILendingPoolAddressesProvider _addressesProvider,
        AssetMappings _assetMappings
    ) external view {
        uint256 underlyingBalance = IERC20(reserve.aTokenAddress).balanceOf(
            msg.sender
        );

        require(
            underlyingBalance > 0,
            Errors.VL_UNDERLYING_BALANCE_NOT_GREATER_THAN_0
        );

        require(
            useAsCollateral ||
                GenericLogic.balanceDecreaseAllowed(
                    GenericLogic.BalanceDecreaseAllowedParameters(
                        reserveAddress,
                        reserve.trancheId,
                        msg.sender,
                        underlyingBalance,
                        _addressesProvider,
                        _assetMappings
                    ),
                    reservesData,
                    userConfig,
                    reserves,
                    reservesCount
                ),
            Errors.VL_DEPOSIT_ALREADY_IN_USE
        );
    }

    /**
     * @dev Validates a flashloan action
     * @param assets The assets being flashborrowed
     * @param amounts The amounts for each asset being borrowed
     **/
    function validateFlashloan(
        address[] memory assets,
        uint256[] memory amounts
    ) internal pure {
        require(
            assets.length == amounts.length,
            Errors.VL_INCONSISTENT_FLASHLOAN_PARAMS
        );
    }

    /**
     * @dev Validates the liquidation action
     * @param collateralReserve The reserve data of the collateral
     * @param principalReserve The reserve data of the principal
     * @param userConfig The user configuration
     * @param userHealthFactor The user's health factor
     * @param userVariableDebt Total variable debt balance of the user
     **/
    function validateLiquidationCall(
        DataTypes.ReserveData storage collateralReserve,
        DataTypes.ReserveData storage principalReserve,
        DataTypes.UserConfigurationMap storage userConfig,
        uint256 userHealthFactor,
        uint256 userVariableDebt
    ) internal view returns (uint256, string memory) {
        if (
            !collateralReserve.configuration.getActive() ||
            !principalReserve.configuration.getActive()
        ) {
            return (
                uint256(Errors.CollateralManagerErrors.NO_ACTIVE_RESERVE),
                Errors.VL_NO_ACTIVE_RESERVE
            );
        }

        if (
            userHealthFactor >= GenericLogic.HEALTH_FACTOR_LIQUIDATION_THRESHOLD
        ) {
            return (
                uint256(
                    Errors.CollateralManagerErrors.HEALTH_FACTOR_ABOVE_THRESHOLD
                ),
                Errors.LPCM_HEALTH_FACTOR_NOT_BELOW_THRESHOLD
            );
        }

        bool isCollateralEnabled = collateralReserve
            .configuration
            .getCollateralEnabled() &&
            userConfig.isUsingAsCollateral(collateralReserve.id);

        //if collateral isn't enabled as collateral by user, it cannot be liquidated
        if (!isCollateralEnabled) {
            return (
                uint256(
                    Errors
                        .CollateralManagerErrors
                        .COLLATERAL_CANNOT_BE_LIQUIDATED
                ),
                Errors.LPCM_COLLATERAL_CANNOT_BE_LIQUIDATED
            );
        }

        if (userVariableDebt == 0) {
            return (
                uint256(Errors.CollateralManagerErrors.CURRRENCY_NOT_BORROWED),
                Errors.LPCM_SPECIFIED_CURRENCY_NOT_BORROWED_BY_USER
            );
        }

        return (
            uint256(Errors.CollateralManagerErrors.NO_ERROR),
            Errors.LPCM_NO_ERRORS
        );
    }

    /**
     * @dev Validates an aToken transfer
     * @param from The user from which the aTokens are being transferred
     * @param reservesData The state of all the reserves
     * @param userConfig The state of the user for the specific reserve
     * @param reserves The addresses of all the active reserves
     * @param _addressesProvider The price oracle
     */
    function validateTransfer(
        address from,
        uint64 trancheId,
        mapping(address => mapping(uint64 => DataTypes.ReserveData))
            storage reservesData,
        DataTypes.UserConfigurationMap storage userConfig,
        mapping(uint256 => address) storage reserves,
        uint256 reservesCount,
        ILendingPoolAddressesProvider _addressesProvider,
        AssetMappings _assetMappings
    ) internal view {
        (, , , , uint256 healthFactor,) = GenericLogic.calculateUserAccountData(
            DataTypes.AcctTranche(from, trancheId),
            reservesData,
            userConfig,
            reserves,
            reservesCount,
            _addressesProvider,
            _assetMappings,
            true //same logic as withdraws
        );
        // uint256 healthFactor = 1;
        require(
            healthFactor >= GenericLogic.HEALTH_FACTOR_LIQUIDATION_THRESHOLD,
            Errors.VL_TRANSFER_NOT_ALLOWED
        );
    }
}

// SPDX-License-Identifier: agpl-3.0
pragma solidity >=0.8.0;

import {
    SafeMath
} from "../../../dependencies/openzeppelin/contracts/SafeMath.sol";
import {WadRayMath} from "./WadRayMath.sol";

library MathUtils {
    using SafeMath for uint256;
    using WadRayMath for uint256;

    /// @dev Ignoring leap years
    uint256 internal constant SECONDS_PER_YEAR = 365 days;

    /**
     * @dev Function to calculate the interest accumulated using a linear interest rate formula
     * @param rate The interest rate, in ray
     * @param lastUpdateTimestamp The timestamp of the last update of the interest
     * @return The interest rate linearly accumulated during the timeDelta, in ray
     **/

    function calculateLinearInterest(uint256 rate, uint40 lastUpdateTimestamp)
        internal
        view
        returns (uint256)
    {
        //solium-disable-next-line
        uint256 timeDifference =
            block.timestamp.sub(uint256(lastUpdateTimestamp));

        return
            (rate.mul(timeDifference) / SECONDS_PER_YEAR).add(WadRayMath.ray());
    }

    /**
     * @dev Function to calculate the interest using a compounded interest rate formula
     * To avoid expensive exponentiation, the calculation is performed using a binomial approximation:
     *
     *  (1+x)^n = 1+n*x+[n/2*(n-1)]*x^2+[n/6*(n-1)*(n-2)*x^3...
     *
     * The approximation slightly underpays liquidity providers and undercharges borrowers, with the advantage of great gas cost reductions
     * The whitepaper contains reference to the approximation and a table showing the margin of error per different time periods
     *
     * @param rate The interest rate, in ray
     * @param lastUpdateTimestamp The timestamp of the last update of the interest
     * @return The interest rate compounded during the timeDelta, in ray
     **/
    function calculateCompoundedInterest(
        uint256 rate,
        uint40 lastUpdateTimestamp,
        uint256 currentTimestamp
    ) internal pure returns (uint256) {
        //solium-disable-next-line
        uint256 exp = currentTimestamp.sub(uint256(lastUpdateTimestamp));

        if (exp == 0) {
            return WadRayMath.ray();
        }

        uint256 expMinusOne = exp - 1;

        uint256 expMinusTwo = exp > 2 ? exp - 2 : 0;

        uint256 ratePerSecond = rate / SECONDS_PER_YEAR;

        uint256 basePowerTwo = ratePerSecond.rayMul(ratePerSecond);
        uint256 basePowerThree = basePowerTwo.rayMul(ratePerSecond);

        uint256 secondTerm = exp.mul(expMinusOne).mul(basePowerTwo) / 2;
        uint256 thirdTerm =
            exp.mul(expMinusOne).mul(expMinusTwo).mul(basePowerThree) / 6;

        return
            WadRayMath.ray().add(ratePerSecond.mul(exp)).add(secondTerm).add(
                thirdTerm
            );
    }

    /**
     * @dev Calculates the compounded interest between the timestamp of the last update and the current block timestamp
     * @param rate The interest rate (in ray)
     * @param lastUpdateTimestamp The timestamp from which the interest accumulation needs to be calculated
     **/
    function calculateCompoundedInterest(
        uint256 rate,
        uint40 lastUpdateTimestamp
    ) internal view returns (uint256) {
        return
            calculateCompoundedInterest(
                rate,
                lastUpdateTimestamp,
                block.timestamp
            );
    }
}

// SPDX-License-Identifier: agpl-3.0
pragma solidity >=0.8.0;

import {Errors} from "../helpers/Errors.sol";

/**
 * @title PercentageMath library
 * @author Vmex
 * @notice Provides functions to perform percentage calculations
 * @dev Percentages are defined by default with 16 decimals of precision. The precision is indicated by PERCENTAGE_FACTOR
 * @dev Operations are rounded half up
 **/

library PercentageMath {
    uint256 constant NUM_DECIMALS = 18;
    uint256 constant PERCENTAGE_FACTOR = 10**NUM_DECIMALS; //percentage plus 16 decimals
    uint256 constant HALF_PERCENT = PERCENTAGE_FACTOR / 2;

    function convertToPercent(uint256 value)
        internal
        pure
        returns (uint256)
    {
        return value*10**(NUM_DECIMALS-4);
    }

    /**
     * @dev Executes a percentage multiplication
     * @param value The value of which the percentage needs to be calculated
     * @param percentage The percentage of the value to be calculated
     * @return The percentage of value
     **/
    function percentMul(uint256 value, uint256 percentage)
        internal
        pure
        returns (uint256)
    {
        if (value == 0 || percentage == 0) {
            return 0;
        }

        require(
            value <= (type(uint256).max - HALF_PERCENT) / percentage,
            Errors.MATH_MULTIPLICATION_OVERFLOW
        );

        return (value * percentage + HALF_PERCENT) / PERCENTAGE_FACTOR;
    }

    /**
     * @dev Executes a percentage division
     * @param value The value of which the percentage needs to be calculated
     * @param percentage The percentage of the value to be calculated
     * @return The value divided the percentage
     **/
    function percentDiv(uint256 value, uint256 percentage)
        internal
        pure
        returns (uint256)
    {
        require(percentage != 0, Errors.MATH_DIVISION_BY_ZERO);
        uint256 halfPercentage = percentage / 2;

        require(
            value <= (type(uint256).max - halfPercentage) / PERCENTAGE_FACTOR,
            Errors.MATH_MULTIPLICATION_OVERFLOW
        );

        return (value * PERCENTAGE_FACTOR + halfPercentage) / percentage;
    }
}

// SPDX-License-Identifier: agpl-3.0
pragma solidity >=0.8.0;

import {Errors} from "../helpers/Errors.sol";

/**
 * @title WadRayMath library
 * @author Aave
 * @dev Provides mul and div function for wads (decimal numbers with 18 digits precision) and rays (decimals with 27 digits)
 **/

library WadRayMath {
    uint256 internal constant WAD = 1e18;
    uint256 internal constant halfWAD = WAD / 2;

    uint256 internal constant RAY = 1e27;
    uint256 internal constant halfRAY = RAY / 2;

    uint256 internal constant WAD_RAY_RATIO = 1e9;

    /**
     * @return One ray, 1e27
     **/
    function ray() internal pure returns (uint256) {
        return RAY;
    }

    /**
     * @return One wad, 1e18
     **/

    function wad() internal pure returns (uint256) {
        return WAD;
    }

    /**
     * @return Half ray, 1e27/2
     **/
    function halfRay() internal pure returns (uint256) {
        return halfRAY;
    }

    /**
     * @return Half ray, 1e18/2
     **/
    function halfWad() internal pure returns (uint256) {
        return halfWAD;
    }

    /**
     * @dev Multiplies two wad, rounding half up to the nearest wad
     * @param a Wad
     * @param b Wad
     * @return The result of a*b, in wad
     **/
    function wadMul(uint256 a, uint256 b) internal pure returns (uint256) {
        if (a == 0 || b == 0) {
            return 0;
        }

        require(
            a <= (type(uint256).max - halfWAD) / b,
            Errors.MATH_MULTIPLICATION_OVERFLOW
        );

        return (a * b + halfWAD) / WAD;
    }

    /**
     * @dev Divides two wad, rounding half up to the nearest wad
     * @param a Wad
     * @param b Wad
     * @return The result of a/b, in wad
     **/
    function wadDiv(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b != 0, Errors.MATH_DIVISION_BY_ZERO);
        uint256 halfB = b / 2;

        require(
            a <= (type(uint256).max - halfB) / WAD,
            Errors.MATH_MULTIPLICATION_OVERFLOW
        );

        return (a * WAD + halfB) / b;
    }

    /**
     * @dev Multiplies two ray, rounding half up to the nearest ray
     * @param a Ray
     * @param b Ray
     * @return The result of a*b, in ray
     **/
    function rayMul(uint256 a, uint256 b) internal pure returns (uint256) {
        if (a == 0 || b == 0) {
            return 0;
        }

        require(
            a <= (type(uint256).max - halfRAY) / b,
            Errors.MATH_MULTIPLICATION_OVERFLOW
        );

        return (a * b + halfRAY) / RAY;
    }

    /**
     * @dev Divides two ray, rounding half up to the nearest ray
     * @param a Ray
     * @param b Ray
     * @return The result of a/b, in ray
     **/
    function rayDiv(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b != 0, Errors.MATH_DIVISION_BY_ZERO);
        uint256 halfB = b / 2;

        require(
            a <= (type(uint256).max - halfB) / RAY,
            Errors.MATH_MULTIPLICATION_OVERFLOW
        );

        return (a * RAY + halfB) / b;
    }

    /**
     * @dev Casts ray down to wad
     * @param a Ray
     * @return a casted to wad, rounded half up to the nearest wad
     **/
    function rayToWad(uint256 a) internal pure returns (uint256) {
        uint256 halfRatio = WAD_RAY_RATIO / 2;
        uint256 result = halfRatio + a;
        require(result >= halfRatio, Errors.MATH_ADDITION_OVERFLOW);

        return result / WAD_RAY_RATIO;
    }

    /**
     * @dev Converts wad up to ray
     * @param a Wad
     * @return a converted in ray
     **/
    function wadToRay(uint256 a) internal pure returns (uint256) {
        uint256 result = a * WAD_RAY_RATIO;
        require(
            result / WAD_RAY_RATIO == a,
            Errors.MATH_MULTIPLICATION_OVERFLOW
        );
        return result;
    }
}

// SPDX-License-Identifier: agpl-3.0
pragma solidity >=0.8.0;

import {AssetMappings} from "../../lendingpool/AssetMappings.sol";

library DataTypes {
    struct CurveMetadata {
        uint256 _pid;
        uint8 _poolSize;
        address _curvePool;
    }
    // refer to the whitepaper, section 1.1 basic concepts for a formal description of these properties.
    struct AssetData {
        uint8 underlyingAssetDecimals;
        uint8 assetType;
        string underlyingAssetName;
        string aTokenName;
        string aTokenSymbol;
        string variableDebtTokenName;
        string variableDebtTokenSymbol;
        uint256 VMEXReserveFactor;

        //below are the things that we will change more often
        uint256 supplyCap;
        uint256 borrowCap;
        uint256 baseLTV; // % of value of collateral that can be used to borrow. "Collateral factor."
        uint256 liquidationThreshold; //if this is zero, then disabled as collateral
        uint256 liquidationBonus;
        uint256 borrowFactor; // borrowFactor * baseLTV * value = truly how much you can borrow of an asset
        bool borrowingEnabled;
        bool isAllowed; //default to false, unless set
        //mapping(uint8=>address) interestRateStrategyAddress;//user must choose from this set list (index 0 is default)
        //the only difference between the different strategies is the value of the slopes and optimal utilization
    }

    struct InitReserveInput {
        // address aTokenImpl; //individual tranche users should not have control over this
        // address stableDebtTokenImpl;
        // address variableDebtTokenImpl;

        //choose asset, the other properties come with asset
        address underlyingAsset;

        //these can be chosen by user to be any address
        address treasury;
        address incentivesController;

        uint8 interestRateChoice; //0 for default, others are undefined until set
        uint256 reserveFactor;
        bool canBorrow;
        bool canBeCollateral; //even if we allow an asset to be collateral, pool admin can choose to force the asset to not be used as collateral in their tranche
    }

    struct InitReserveInputInternal {
        InitReserveInput input;
        uint64 trancheId;
        address aTokenImpl;
        address variableDebtTokenImpl;
        AssetData assetdata;
    }

    enum ReserveAssetType {
        AAVE,
        CURVE,
        CURVEV2,
        YEARN
    } //update with other possible types of the underlying asset
    //AAVE is the original assets in the aave protocol
    //CURVE is the new LP tokens we are providing support for
    struct TrancheAddress {
        uint64 trancheId;
        address asset;
    }
    struct ReserveData {
        //stores the reserve configuration
        ReserveConfigurationMap configuration; //a lot of this is per asset rather than per reserve. But it's fine to keep since pretty gas efficient
        //these are for sure per reserve
        //the liquidity index. Expressed in ray
        uint128 liquidityIndex; //not used for nonlendable assets
        //variable borrow index. Expressed in ray
        uint128 variableBorrowIndex; //not used for nonlendable assets
        //the current supply rate. Expressed in ray
        uint128 currentLiquidityRate; //deposit APR is defined as liquidityRate / RAY //not used for nonlendable assets
        //the current variable borrow rate. Expressed in ray
        uint128 currentVariableBorrowRate; //not used for nonlendable assets
        //the current stable borrow rate. Expressed in ray
        uint40 lastUpdateTimestamp;
        //tokens addresses
        address aTokenAddress;
        address variableDebtTokenAddress; //not used for nonlendable assets
        //the id of the reserve. Represents the position in the list of the active reserves
        uint8 id;
        //maybe consider
        uint64 trancheId;
        address interestRateStrategyAddress;
    }

    // uint8 constant NUM_TRANCHES = 3;

    struct ReserveConfigurationMap {
        //new mappings to account for larger reserve factors
        //bit 0: Reserve is active
        //bit 1: reserve is frozen
        //bit 2: borrowing is enabled
        //bit 3: stable rate borrowing enabled
        //bit 4: collateral is enabled
        //bit 5-7: reserved
        //bit 8-71: reserve factor (64 bit)
        uint256 data;
    }

    struct UserData {
        UserConfigurationMap configuration;
        uint128 lastUserBorrow;
        uint128 lastUserDeposit;
    }

    struct UserConfigurationMap {
        uint256 data;
    }

    enum InterestRateMode {
        NONE,
        STABLE,
        VARIABLE
    }

    struct AcctTranche {
        address user;
        uint64 trancheId;
    }

    struct DepositVars {
        address asset;
        uint64 trancheId;
        address _addressesProvider;
        AssetMappings _assetMappings;
        uint256 amount;
        address onBehalfOf;
        uint16 referralCode;
    }

    struct ExecuteBorrowParams {
        uint256 amount;
        uint256 _reservesCount;
        uint256 assetPrice;
        uint64 trancheId; //trancheId the user wants to borrow out of
        uint16 referralCode;
        address asset;
        address user;
        address onBehalfOf;
        address aTokenAddress;
        bool releaseUnderlying;
        AssetMappings _assetMappings;

    }

    struct WithdrawParams {
        uint256 _reservesCount;
        address asset;
        uint64 trancheId;
        uint256 amount;
        address to;
    }

    struct calculateInterestRatesVars {
        address reserve;
        address aToken;
        uint256 liquidityAdded;
        uint256 liquidityTaken;
        uint256 totalVariableDebt;
        uint256 reserveFactor;
        uint256 globalVMEXReserveFactor;
    }
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity >=0.8.0;

import {IERC20} from "../../dependencies/openzeppelin/contracts/IERC20.sol";
import {SafeERC20} from "../../dependencies/openzeppelin/contracts/SafeERC20.sol";
import {PausableUpgradeable} from "../../dependencies/openzeppelin/upgradeability2/PausableUpgradeable.sol";

import {IBaseStrategy} from "../../interfaces/IBaseStrategy.sol";
import {ILendingPoolAddressesProvider} from "../../interfaces/ILendingPoolAddressesProvider.sol";
import {ILendingPool} from "../../interfaces/ILendingPool.sol";
import {IAToken} from "../../interfaces/IAToken.sol";

import {vStrategyHelper} from "./deps/vStrategyHelper.sol";
import {PercentageMath} from "../libraries/math/PercentageMath.sol";
import {WadRayMath} from "../libraries/math/WadRayMath.sol";
import {ReserveConfiguration} from "../libraries/configuration/ReserveConfiguration.sol";
import {DataTypes} from "../libraries/types/DataTypes.sol";
import {AssetMappings} from "../lendingpool/AssetMappings.sol";

import "hardhat/console.sol";

/*
    ===== Badger Base Strategy =====
    Common base class for all Sett strategies
    Changelog
    V1.1
    - Verify amount unrolled from strategy positions on withdraw() is within a threshold relative to the requested amount as a sanity check
    - Add version number which is displayed with baseStrategyVersion(). If a strategy does not implement this function, it can be assumed to be 1.0
    V1.2
    - Remove idle underlying handling from base withdraw() function. This should be handled as the strategy sees fit in _withdrawSome()
    V1.5
    - No controller as middleman. The Strategy directly interacts with the lendingPool
    - withdrawToLendingPool would withdraw all the funds from the strategy and move it into lendingPool
    - strategy would take the actors from the lendingPool it is connected to
        - SettAccessControl removed
    - fees calculation for autocompounding rewards moved to lendingPool
    - autoCompoundRatio param added to keep a track in which ratio harvested rewards are being autocompounded
*/

//using camelCase this time even if it kills me inside
abstract contract BaseStrategy is PausableUpgradeable, IBaseStrategy {
    using PercentageMath for uint256;
    using ReserveConfiguration for DataTypes.ReserveConfigurationMap;

    uint256 public constant MAX_BPS = 10_000; // MAX_BPS in terms of BPS = 100%
    uint256 public constant LEFTOVER = 1000; //amount to be kept in the strategy contract for quick withdrawals
    uint256 public constant EFFICIENCY = 2;

    ILendingPoolAddressesProvider public addressProvider; // lending pool address provider
    address public lendingPool; // address of the lending pool
    address public treasury;

    address public underlying; // Token used for pulls //CHANGED from want to underlying to make clear that is the underlying token of the lending pool
    uint64 public tranche; // tranche of lending pool the strategy is attached to
    address public vToken; // address of the vToken the strategy is attached to
    uint256 public withdrawalMaxDeviationThreshold; // max allowed slippage when withdrawing

    uint256 internal constant SECONDS_PER_YEAR = 365 days;

    /// @notice percentage of rewards converted to underlying
    /// @dev converting of rewards to underlying during harvest should take place in this ratio
    /// @dev change this ratio if rewards are converted in a different percentage
    /// value ranges from 0 to 10_000
    /// 0: keeping 100% harvest in reward tokens
    /// 10_000: converting all rewards tokens to underlying token
    uint256 public autoCompoundRatio; // NOTE: I believe this is unused

    // NOTE: You have to set autoCompoundRatio in the initializer of your strategy

    mapping(address => uint256) public extraRewardsTended; //can be multiple additional rewards, depending on pool I believe

    uint256 public lastHarvestTime;

    mapping(uint8 => uint256) public averageR; //store the last 7 days of rates of return. First value is index, which points to the uint256 value that has the averageR
    uint8 internal index;
    uint8 internal lengthOfMovingAverage;

    /// @notice Initializes BaseStrategy. Can only be called once.
    ///         Make sure to call it from the initializer of the derived strategy.
    function __BaseStrategy_init(
        address _addressProvider,
        address _underlying,
        uint64 _tranche
    ) public onlyInitializing whenNotPaused {
        require(_addressProvider != address(0), "Address 0");
        __Pausable_init();

        addressProvider = ILendingPoolAddressesProvider(_addressProvider);
        lendingPool = addressProvider.getLendingPool();
        underlying = _underlying; //the CRV LP token used in the strategy
        tranche = _tranche;
        vToken = ILendingPool(lendingPool)
            .getReserveData(underlying, tranche)
            .aTokenAddress;
        require(vToken != address(0), "vToken address can not be zero");

        withdrawalMaxDeviationThreshold = 50; // BPS
        // NOTE: See above
        autoCompoundRatio = 10_000;

        // give the reserve's vtoken full access to underlying
        // vStrategyHelper.tokenAllowAll(underlying, vToken);

        index = 0; //placed in init so can be upgraded
        lengthOfMovingAverage = 7; //7 days moving average
    }

    // ===== Modifiers =====

    function governance() public view returns (address) {
        return addressProvider.getTrancheAdmin(tranche);
    }

    /// @notice Checks whether a call is from governance.
    /// @dev For functions that only the governance should be able to call
    ///      Most of the time setting setters, or to rescue/sweep funds
    function _onlyGovernance() internal view {
        require(msg.sender == governance(), "onlyGovernance");
    }

    /// @notice Checks whether a call is from strategy user (the lending pool) or governance.
    /// @dev For functions that only known benign entities should call
    function _onlyAuthorizedActors() internal view {
        require(
            msg.sender == vToken || msg.sender == governance() || addressProvider.getGlobalAdmin()==msg.sender,
            "onlyAuthorizedActors"
        );
    }

    /// @notice Checks whether a call is from the lendingPool.
    /// @dev For functions that only the lendingPool should use
    function _onlyVault() internal view {
        require(msg.sender == vToken || addressProvider.getGlobalAdmin()==msg.sender, "onlyVault");
    }

    /// @notice Checks whether a call is from guardian or governance.
    /// @dev Modifier used exclusively for pausing
    function _onlyAuthorizedPausers() internal view {
        require(msg.sender == governance() || addressProvider.getGlobalAdmin()==msg.sender, "onlyPausers");
    }

    /// ===== View Functions =====
    /// @notice Used to track the deployed version of BaseStrategy.
    /// @return Current version of the contract.
    function baseStrategyVersion()
        external
        pure
        virtual
        override
        returns (string memory)
    {
        return "1.0";
    }

    /// @notice Gives the balance of underlying held idle in the Strategy.
    /// @dev Public because used internally for accounting
    /// @return Balance of underlying held idle in the strategy.
    function balanceOfWant() public view returns (uint256) {
        return IERC20(underlying).balanceOf(address(this));
    }

    /// @notice Gives the total balance of underlying managed by the strategy.
    ///         This includes all underlying pulled to active strategy positions as well as any idle underlying in the strategy.
    /// @return Total balance of underlying managed by the strategy.
    function balanceOf() external view override returns (uint256) {
        return balanceOfWant() + balanceOfPool();
    }

    /// @notice Tells whether the strategy is supposed to be tended.
    /// @dev This is usually a constant. The harvest keeper would only call `tend` if this is true.
    /// @return Boolean indicating whether strategy is supposed to be tended or not.
    function isTendable() external pure returns (bool) {
        return _isTendable();
    }

    function _isTendable() internal pure virtual returns (bool);

    /// @notice Checks whether a token is a protected token.
    ///         Protected tokens are managed by the strategy and can't be transferred/sweeped.
    /// @return Boolean indicating whether the token is a protected token.
    function isProtectedToken(address token) public view returns (bool) {
        require(token != address(0), "Address 0");

        address[] memory protectedTokens = getProtectedTokens();
        for (uint256 i = 0; i < protectedTokens.length; i++) {
            if (token == protectedTokens[i]) {
                return true;
            }
        }
        return false;
    }

    /// ===== Permissioned Actions: Governance =====

    /// @notice Sets the max withdrawal deviation (percentage loss) that is acceptable to the strategy.
    ///         This can only be called by governance.
    /// @dev This is used as a slippage check against the actual funds withdrawn from strategy positions.
    ///      See `withdraw`.
    function setWithdrawalMaxDeviationThreshold(uint256 _threshold)
        external
        override
    {
        _onlyGovernance();
        require(_threshold <= MAX_BPS, "_threshold should be <= MAX_BPS");
        withdrawalMaxDeviationThreshold = _threshold;
        emit SetWithdrawalMaxDeviationThreshold(_threshold);
    }

    /// @notice Deposits any idle underlying in the strategy into positions.
    ///         This can be called by either the lendingPool, keeper or governance.
    ///         Note that pulls don't work when the strategy is paused.
    /// @dev Is basically the same as tend, except without custom code for it
    function pull() external override whenNotPaused returns (uint256) {
        _onlyAuthorizedActors();
        uint256 pullFromPool = IERC20(underlying).balanceOf(address(vToken));
        if (pullFromPool > 0) {
            // do not keep 10% in pool for now
            // uint256 amountKeptInPool = checkForMaxDepositAmount(pullFromPool);

            IERC20(underlying).transferFrom(
                address(vToken),
                address(this),
                pullFromPool
            );
            emit StrategyPullFromLendingPool(lendingPool, pullFromPool);
        }
        uint256 _amount = IERC20(underlying).balanceOf(address(this));
        if (_amount > 0) {
            _pull(_amount);
        }

        return pullFromPool;
    }

    function checkForMaxDepositAmount(uint256 newDeposits)
        internal
        view
        returns (uint256)
    {
        //get new total amount that will be in the strategy
        uint256 amountInStrategy = balanceOfPool();
        uint256 currentHeld = IERC20(underlying).balanceOf(address(this));
        uint256 newTotal = amountInStrategy + newDeposits;

        //this is how much needs to remain in this contract to achieve 10% held
        uint256 newPercentage = (newTotal * LEFTOVER) / 1e4;

        //get the amount needed to be kept to create a constant 10% withdrawal buffer
        uint256 dif = newPercentage - currentHeld;
        return dif;
    }

    //using the tend data, we can get the current rate of return since the last harvest, or r value;
    //		i = underlying gained
    //		p = principal
    //this can be used to find the APY by using the (1 + r/n)^n - 1 formula
    //NOTE: i already includes deductions from fees and swaps, no need to calc that in
    //NOTE: divide the result by 1e18, then multiply by 100 for a percentage
    function interestRate(uint256 i, uint256 p, uint256 timeDifference) internal returns (uint256 r) {
        uint256 scaledAmount = i.percentMul(
            PercentageMath.PERCENTAGE_FACTOR - AssetMappings(addressProvider.getAssetMappings()).getVMEXReserveFactor(underlying)
        );

        r = (scaledAmount * WadRayMath.ray() * SECONDS_PER_YEAR) / (p  * timeDifference) ; //*365 if we tend every day.
        //WadRayMath.ray() is 1e27. This is the same units as currentLiquidityRate
        // if we know the timestamp difference between this and last update, can extrapolate using that

        //global index to keep track of which is the oldest element in the array
        //every day, we increment the global index by 1 and replace the indexed value with the new r value
        //order does not matter in this context, but we do need to know which of the values is the oldest
        averageR[index] = r;
        index++;

        //once we hit the length of the array, we reset the global index to 0 to restart the process
        if (index >= lengthOfMovingAverage) {
            index = 0;
        }

        emit InterestRateUpdated(scaledAmount,timeDifference, p,SECONDS_PER_YEAR, r);

        return r;
    }
    //this will only be used for purpose of frontend
    function calculateAverageRate() external view override returns (uint256 r) {
        uint256 ret = 0;
        for (uint8 i = 0; i < lengthOfMovingAverage; i++) {
            ret += averageR[i];
        }
        ret /= lengthOfMovingAverage;
        return ret;
    }

    function getLatestRate() external view returns (uint256 r) {
        if(index == 0)
            return averageR[lengthOfMovingAverage-1];
        return averageR[index-1];
    }

    // ===== Permissioned Actions: Vault =====

    /// @notice Withdraw all funds from the strategy to the lendingPool, unrolling all positions.
    ///         This can only be called by the lendingPool.
    /// @dev This can be called even when paused, and strategist can trigger this via the lendingPool.
    ///      The idea is that this can allow recovery of funds back to the strategy faster.
    ///      The risk is that if _withdrawAll causes a loss, this can be triggered.
    ///      However the loss could only be triggered once (just like if governance called)
    ///      as pausing the strats would prevent earning again.
    function withdrawAll() external override {
        _onlyVault();

        _withdrawAll();

        uint256 balance = IERC20(underlying).balanceOf(address(this));
        _transferToLendingPool(balance);
    }

    /// @notice Withdraw partial funds from the strategy to the lendingPool, unrolling from strategy positions as necessary.
    ///         This can only be called by the lendingPool.
    ///         Note that withdraws don't work when the strategy is paused.
    /// @dev If the strategy fails to recover sufficient funds (defined by `withdrawalMaxDeviationThreshold`),
    ///      the withdrawal would fail so that this unexpected behavior can be investigated.
    /// @param _amount Amount of funds required to be withdrawn.
    function withdraw(uint256 _amount) external override whenNotPaused {
        _onlyVault();
        require(_amount != 0, "Amount 0");

        // Withdraw from strategy positions, typically taking from any idle underlying first.
        uint256 _beforeWithdraw = IERC20(underlying).balanceOf(address(this));
        if (_beforeWithdraw < _amount) {
            _withdrawSome(_amount - _beforeWithdraw);
        }
        uint256 _postWithdraw = IERC20(underlying).balanceOf(address(this));

        // Sanity check: Ensure we were able to retrieve sufficient underlying from strategy positions
        // If we end up with less than the amount requested, make sure it does not deviate beyond a maximum threshold
        if (_postWithdraw < _amount) {
            uint256 diff = _diff(_amount, _postWithdraw);

            // Require that difference between expected and actual values is less than the deviation threshold percentage
            require(
                diff <= (_amount * withdrawalMaxDeviationThreshold) / MAX_BPS,
                "withdraw-exceed-max-deviation-threshold"
            );
        }

        // Return the amount actually withdrawn if less than amount requested
        uint256 _toWithdraw = vStrategyHelper.min(_postWithdraw, _amount);

        // Transfer remaining to Vault to handle withdrawal
        _transferToLendingPool(_toWithdraw);
    }

    // Discussion: https://discord.com/channels/785315893960900629/837083557557305375
    /// @notice Sends balance of any extra token earned by the strategy (from airdrops, donations etc.) to the lendingPool.
    ///         The `_token` should be different from any tokens managed by the strategy.
    ///         This can only be called by the lendingPool.
    /// @dev This is a counterpart to `_processExtraToken`.
    ///      This is for tokens that the strategy didn't expect to receive. Instead of sweeping, we can directly
    ///      emit them via the badgerTree. This saves time while offering security guarantees.
    ///      No address(0) check because _onlyNotProtectedTokens does it.
    ///      This is not a rug vector as it can't use protected tokens.
    /// @param _token Address of the token to be emitted.
    function emitNonProtectedToken(address _token) external override {
        _onlyVault();
        _onlyNotProtectedTokens(_token);
        // TODO: transfer extra rewards to who?
        revert("Extra rewards not implemented");
        // IERC20(_token).transfer(lendingPool, IERC20(_token).balanceOf(address(this)));
        //ILendingPool(lendingPool).reportAdditionalToken(_token); //vault specific code, gives bonus tokens to users
    }

    /// @notice Withdraw the balance of a non-protected token to the lendingPool.
    ///         This can only be called by the lendingPool.
    /// @dev Should only be used in an emergency to sweep any asset.
    ///      This is the version that sends the assets to governance.
    ///      No address(0) check because _onlyNotProtectedTokens does it.
    /// @param _asset Address of the token to be withdrawn.
    function withdrawOther(address _asset) external override {
        _onlyVault();
        _onlyNotProtectedTokens(_asset);
        revert("Extra rewards not implemented");
        // IERC20(_asset).transfer(, IERC20(_asset).balanceOf(address(this)));
    }

    /// ===== Permissioned Actions: Authorized Contract Pausers =====

    /// @notice Pauses the strategy.
    ///         This can be called by either guardian or governance.
    /// @dev Check the `onlyWhenPaused` modifier for functionality that is blocked when pausing
    function pause() external override {
        _onlyAuthorizedPausers();
        _pause();
    }

    /// @notice Unpauses the strategy.
    ///         This can only be called by governance (usually a multisig behind a timelock).
    function unpause() external override {
        _onlyGovernance();
        _unpause();
    }

    /// ===== Internal Helper Functions =====

    /// @notice Transfers `_amount` of underlying to the lendingPool.
    /// @dev Strategy should have idle funds >= `_amount`.
    /// @param _amount Amount of underlying to be transferred to the lendingPool.
    function _transferToLendingPool(uint256 _amount) internal {
        if (_amount > 0) {
            IERC20(underlying).transfer(vToken, _amount);
        }
    }

    /// @notice Report an harvest to the lendingPool.
    /// @param _harvestedAmount Amount of underlying token autocompounded during harvest.
    function _reportToLendingPool(uint256 _harvestedAmount) internal {
        //ILendingPool(lendingPool).reportHarvest(_harvestedAmount);
    }

    /// @notice Sends balance of an additional token (eg. reward token) earned by the strategy to the lendingPool.
    ///         This should usually be called exclusively on protectedTokens.
    ///         Calls `Vault.reportAdditionalToken` to process fees and forward amount to badgerTree to be emitted.
    /// @dev This is how you emit tokens in V1.5
    ///      After calling this function, the tokens are gone, sent to fee receivers and badgerTree
    ///      This is a rug vector as it allows to move funds to the tree
    ///      For this reason, it is recommended to verify the tree is the badgerTree from the registry
    ///      and also check for this to be used exclusively on harvest, exclusively on protectedTokens.
    /// @param _token Address of the token to be emitted.
    /// @param _amount Amount of token to transfer to lendingPool.
    function _processExtraToken(address _token, uint256 _amount) internal {
        require(
            _token != underlying,
            "Not underlying, use _reportToLendingPool"
        );
        require(_token != address(0), "Address 0");
        require(_amount != 0, "Amount 0");

        IERC20(_token).transfer(lendingPool, _amount);
        //ILendingPool(lendingPool).reportAdditionalToken(_token); //vault specific code (?)
    }

    /// @notice Utility function to diff two numbers, expects higher value in first position
    function _diff(uint256 a, uint256 b) internal pure returns (uint256) {
        require(a >= b, "a should be >= b");
        return a - b;
    }

    // ===== Abstract Functions: To be implemented by specific Strategies =====

    /// @dev Internal pull logic to be implemented by a derived strategy.
    /// @param _underlying Amount of underlying token to be pulled into the strategy.
    function _pull(uint256 _underlying) internal virtual;

    /// @notice Checks if a token is not used in yield process.
    /// @param _asset Address of token.
    function _onlyNotProtectedTokens(address _asset) internal view {
        require(!isProtectedToken(_asset), "_onlyNotProtectedTokens");
    }

    /// @notice Gives the list of protected tokens used in the yield process.
    /// @return Array of protected tokens.
    function getProtectedTokens()
        public
        view
        virtual
        returns (address[] memory);

    /// @dev Internal logic for strategy migration. Should exit positions as efficiently as possible.
    function _withdrawAll() internal virtual;

    /// @dev Internal logic for partial withdrawals. Should exit positions as efficiently as possible.
    ///      Should ideally use idle underlying in the strategy before attempting to exit strategy positions.
    /// @param _amount Amount of underlying token to be withdrawn from the strategy.
    /// @return Withdrawn amount from the strategy.
    function _withdrawSome(uint256 _amount) internal virtual returns (uint256);

    /// @notice Realize returns from strategy positions.
    ///         This can only be called by keeper or governance.
    ///         Note that harvests don't work when the strategy is paused.
    /// @dev Returns can be reinvested into positions, or distributed in another fashion.
    /// @return harvested An array of `TokenAmount` containing the address and amount harvested for each token.
    function harvest()
        external
        override
        whenNotPaused
        returns (TokenAmount[] memory harvested)
    {
        _onlyAuthorizedActors();
        return _harvest();
    }

    /// @dev Virtual function that should be overridden with the logic for harvest.
    ///      Should report any underlying or non-underlying gains to the lendingPool.
    ///      Also see `harvest`.
    function _harvest()
        internal
        virtual
        returns (TokenAmount[] memory harvested);

    /// @notice Tend strategy positions as needed to maximize returns.
    ///         This can only be called by keeper or governance.
    ///         Note that tend doesn't work when the strategy is paused.
    /// @dev Is only called by the keeper when `isTendable` is true.
    /// @return amountTended An array of `TokenAmount` containing the address and amount tended for each token.
    function tend(uint256 minOut) external override whenNotPaused returns (uint256 amountTended) {
        _onlyAuthorizedActors();
        return _tend(minOut);
    }

    // function tend() external override whenNotPaused returns (uint256 crvTended,
    //     uint256 cvxTended,
    //     uint256 cvxCrvTended,
    //     uint256 extraRewardsTended) {
    //     //_onlyAuthorizedActors();
    //     TendData memory t = _tend();
    //     crvTended = t.crvTended;
    //     cvxTended = t.cvxTended;
    //     cvxCrvTended = t.cvxCrvTended;
    //     extraRewardsTended = t.extraRewardsTended;
    // }

    /// @dev Virtual function that should be overridden with the logic for tending.
    ///      Also see `tend`.
    function _tend(uint256 minOut) internal virtual returns (uint256 amountTended);

    /// @notice Fetches the name of the strategy.
    /// @dev Should be user-friendly and easy to read.
    /// @return Name of the strategy.
    function getName() external pure virtual override returns (string memory);

    /// @notice Gives the balance of underlying held in strategy positions.
    /// @return Balance of underlying held in strategy positions.
    function balanceOfPool() public view virtual returns (uint256);

    /// @notice Gives the total amount of pending rewards accrued for each token.
    /// @dev Should take into account all reward tokens.
    /// @return rewards An array of `TokenAmount` containing the address and amount of each reward token.
    function balanceOfRewards()
        external
        view
        virtual
        override
        returns (TokenAmount[] memory rewards);


    /// @notice Mints to treasury aTokens fees and updates liquidity index when tending
    function _updateState(uint256 amount) internal {
        uint256 scaledAmount = amount.percentMul(
            AssetMappings(addressProvider.getAssetMappings()).getVMEXReserveFactor(underlying)
        );


        uint256 userAmount = amount - scaledAmount;
        uint128 prevLiquidityIndex = ILendingPool(lendingPool).getReserveData(underlying, tranche).liquidityIndex;
        uint128 newLiquidityIndex = uint128( (userAmount*WadRayMath.ray())/IAToken(vToken).scaledTotalSupply() ) + prevLiquidityIndex;
        ILendingPool(lendingPool).setReserveDataLI(underlying, tranche, newLiquidityIndex);

        //this needs to be done last to be updated with most recent liquidity index
        IAToken(vToken).mintToVMEXTreasury(
            scaledAmount,
            newLiquidityIndex
        );
    }

    uint256[49] private __gap;
}

//  SPDX-License-Identifier: MIT

pragma solidity >=0.8.0;

interface CrvDepositor {
    //deposit crv for cvxCrv
    //can locking immediately or defer locking to someone else by paying a fee.
    //while users can choose to lock or defer, this is mostly in place so that
    //the cvx reward contract isnt costly to claim rewards
    function deposit(uint256 _amount, bool _lock) external;
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

interface IBaseRewardsPool {
    //balance
    function balanceOf(address _account) external view returns (uint256);

    //withdraw to a convex tokenized deposit
    function withdraw(uint256 _amount, bool _claim) external returns (bool);

    //withdraw directly to curve LP token
    function withdrawAndUnwrap(uint256 _amount, bool _claim)
        external
        returns (bool);

    function withdrawAllAndUnwrap(bool claim) external;

    //claim rewards
    function getReward() external returns (bool);

    //stake a convex tokenized deposit
    function stake(uint256 _amount) external returns (bool);

    //stake a convex tokenized deposit for another address(transfering ownership)
    function stakeFor(address _account, uint256 _amount)
        external
        returns (bool);

    function getReward(address _account, bool _claimExtras)
        external
        returns (bool);

    function rewards(address _account) external view returns (uint256);

    function earned(address _account) external view returns (uint256);

    function stakingToken() external view returns (address);

    function periodFinish() external view returns (uint256);

    function extraRewards(uint256) external view returns (address);

    function extraRewardsLength() external view returns (uint256);
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity >=0.6.0;

interface IBooster {
    struct PoolInfo {
        address lptoken;
        address token;
        address gauge;
        address crvRewards;
        address stash;
        bool shutdown;
    }

    function poolLength() external view returns (uint256);

    function poolInfo(uint256 n) external view returns (PoolInfo memory);

    function deposit(
        uint256 _pid,
        uint256 _amount,
        bool _stake
    ) external returns (bool);
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

interface ICvxRewardsPool {
    //balance
    function balanceOf(address _account) external view returns (uint256);

    //withdraw to a convex tokenized deposit
    function withdraw(uint256 _amount, bool _claim) external;

    //withdraw directly to curve LP token
    function withdrawAndUnwrap(uint256 _amount, bool _claim)
        external
        returns (bool);

    //claim rewards
    function getReward(bool _stake) external;

    //stake a convex tokenized deposit
    function stake(uint256 _amount) external;

    //stake a convex tokenized deposit for another address(transfering ownership)
    function stakeFor(address _account, uint256 _amount)
        external
        returns (bool);

    function rewards(address _account) external view returns (uint256);

    function earned(address _account) external view returns (uint256);
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

interface IVirtualBalanceRewardPool {
    //balance
    function balanceOf(address _account) external view returns (uint256);

    function earned(address _account) external view returns (uint256);

    function periodFinish() external view returns (uint256);

    function rewardToken() external view returns (address);
}

pragma solidity >=0.8.0;


interface ICurveAddressProvider {
	function get_registry() external returns (address); 
	
	function get_address(uint256 _id) external returns (address); 
}

//  SPDX-License-Identifier: MIT

pragma solidity >=0.6.0;

interface ICurveExchange {
    function exchange(
        int128 i,
        int128 j,
        uint256 dx,
        uint256 min_dy
    ) external;

    function get_dy(
        int128,
        int128 j,
        uint256 dx
    ) external view returns (uint256);

    function calc_token_amount(uint256[2] calldata amounts, bool deposit)
        external
        view
        returns (uint256 amount);

    function add_liquidity(uint256[2] calldata amounts, uint256 min_mint_amount)
        external;

    function remove_liquidity(uint256 _amount, uint256[2] calldata min_amounts)
        external;

    function remove_liquidity_imbalance(
        uint256[2] calldata amounts,
        uint256 max_burn_amount
    ) external;

    function remove_liquidity_one_coin(
        uint256 _token_amounts,
        int128 i,
        uint256 min_amount
    ) external;
}

interface ICurveRegistryAddressProvider {
    function get_address(uint256 id) external returns (address);
}

interface ICurveRegistryExchange {
    function get_best_rate(
        address from,
        address to,
        uint256 amount
    ) external view returns (address, uint256);

    function exchange(
        address pool,
        address from,
        address to,
        uint256 amount,
        uint256 expected,
        address receiver
    ) external payable returns (uint256);

    function get_pool_from_lp_token(
        address lp_token
    ) external view returns (address);
}

// SPDX-License-Identifier: MIT
pragma solidity >=0.8.0;

interface ICurveFi {
    function get_virtual_price() external view returns (uint256 out);

    function add_liquidity(
        // renbtc/tbtc pool
        uint256[2] calldata amounts,
        uint256 min_mint_amount
    ) external payable;

    function add_liquidity(
        // sBTC pool
        uint256[3] calldata amounts,
        uint256 min_mint_amount
    ) external payable;

    function add_liquidity(
        // bUSD pool
        uint256[4] calldata amounts,
        uint256 min_mint_amount
    ) external payable;

    function get_dy(
        int128 i,
        int128 j,
        uint256 dx
    ) external returns (uint256 out);

    function get_dy_underlying(
        int128 i,
        int128 j,
        uint256 dx
    ) external returns (uint256 out);

    function exchange(
        int128 i,
        int128 j,
        uint256 dx,
        uint256 min_dy
    ) external;

    function exchange(
        int128 i,
        int128 j,
        uint256 dx,
        uint256 min_dy,
        uint256 deadline
    ) external;

    function exchange_underlying(
        int128 i,
        int128 j,
        uint256 dx,
        uint256 min_dy
    ) external;

    function exchange_underlying(
        int128 i,
        int128 j,
        uint256 dx,
        uint256 min_dy,
        uint256 deadline
    ) external;

    function remove_liquidity(
        uint256 _amount,
        uint256 deadline,
        uint256[2] calldata min_amounts
    ) external;

    function remove_liquidity_imbalance(
        uint256[2] calldata amounts,
        uint256 deadline
    ) external;

    function remove_liquidity_imbalance(
        uint256[3] calldata amounts,
        uint256 max_burn_amount
    ) external;

    function remove_liquidity(uint256 _amount, uint256[3] calldata amounts)
        external;

    function remove_liquidity_imbalance(
        uint256[4] calldata amounts,
        uint256 max_burn_amount
    ) external;

    function remove_liquidity(uint256 _amount, uint256[4] calldata amounts)
        external;

    function remove_liquidity_one_coin(
        uint256 _token_amount,
        int128 i,
        uint256 _min_amount
    ) external;

    function commit_new_parameters(
        int128 amplification,
        int128 new_fee,
        int128 new_admin_fee
    ) external;

    function apply_new_parameters() external;

    function revert_new_parameters() external;

    function commit_transfer_ownership(address _owner) external;

    function apply_transfer_ownership() external;

    function revert_transfer_ownership() external;

    function withdraw_admin_fees() external;

    function coins(uint256 arg0) external view returns (address out);

    function underlying_coins(int128 arg0) external returns (address out);

    function balances(uint256 arg0) external view returns (uint256 out);

    function A() external returns (int128 out);

    function fee() external returns (int128 out);

    function admin_fee() external returns (int128 out);

    function owner() external returns (address out);

    function admin_actions_deadline() external returns (uint256 out);

    function transfer_ownership_deadline() external returns (uint256 out);

    function future_A() external returns (int128 out);

    function future_fee() external returns (int128 out);

    function future_admin_fee() external returns (int128 out);

    function future_owner() external returns (address out);

    function calc_withdraw_one_coin(uint256 _token_amount, int128 _i)
        external
        view
        returns (uint256 out);
}

pragma solidity >=0.6.2;

interface IUniswapV2Router01 {
    function factory() external pure returns (address);

    function WETH() external pure returns (address);

    function addLiquidity(
        address tokenA,
        address tokenB,
        uint256 amountADesired,
        uint256 amountBDesired,
        uint256 amountAMin,
        uint256 amountBMin,
        address to,
        uint256 deadline
    )
        external
        returns (
            uint256 amountA,
            uint256 amountB,
            uint256 liquidity
        );

    function addLiquidityETH(
        address token,
        uint256 amountTokenDesired,
        uint256 amountTokenMin,
        uint256 amountETHMin,
        address to,
        uint256 deadline
    )
        external
        payable
        returns (
            uint256 amountToken,
            uint256 amountETH,
            uint256 liquidity
        );

    function removeLiquidity(
        address tokenA,
        address tokenB,
        uint256 liquidity,
        uint256 amountAMin,
        uint256 amountBMin,
        address to,
        uint256 deadline
    ) external returns (uint256 amountA, uint256 amountB);

    function removeLiquidityETH(
        address token,
        uint256 liquidity,
        uint256 amountTokenMin,
        uint256 amountETHMin,
        address to,
        uint256 deadline
    ) external returns (uint256 amountToken, uint256 amountETH);

    function removeLiquidityWithPermit(
        address tokenA,
        address tokenB,
        uint256 liquidity,
        uint256 amountAMin,
        uint256 amountBMin,
        address to,
        uint256 deadline,
        bool approveMax,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) external returns (uint256 amountA, uint256 amountB);

    function removeLiquidityETHWithPermit(
        address token,
        uint256 liquidity,
        uint256 amountTokenMin,
        uint256 amountETHMin,
        address to,
        uint256 deadline,
        bool approveMax,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) external returns (uint256 amountToken, uint256 amountETH);

    function swapExactTokensForTokens(
        uint256 amountIn,
        uint256 amountOutMin,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external returns (uint256[] memory amounts);

    function swapTokensForExactTokens(
        uint256 amountOut,
        uint256 amountInMax,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external returns (uint256[] memory amounts);

    function swapExactETHForTokens(
        uint256 amountOutMin,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external payable returns (uint256[] memory amounts);

    function swapTokensForExactETH(
        uint256 amountOut,
        uint256 amountInMax,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external returns (uint256[] memory amounts);

    function swapExactTokensForETH(
        uint256 amountIn,
        uint256 amountOutMin,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external returns (uint256[] memory amounts);

    function swapETHForExactTokens(
        uint256 amountOut,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external payable returns (uint256[] memory amounts);

    function quote(
        uint256 amountA,
        uint256 reserveA,
        uint256 reserveB
    ) external pure returns (uint256 amountB);

    function getAmountOut(
        uint256 amountIn,
        uint256 reserveIn,
        uint256 reserveOut
    ) external pure returns (uint256 amountOut);

    function getAmountIn(
        uint256 amountOut,
        uint256 reserveIn,
        uint256 reserveOut
    ) external pure returns (uint256 amountIn);

    function getAmountsOut(uint256 amountIn, address[] calldata path)
        external
        view
        returns (uint256[] memory amounts);

    function getAmountsIn(uint256 amountOut, address[] calldata path)
        external
        view
        returns (uint256[] memory amounts);
}

pragma solidity >=0.6.2;

import "./IUniswapV2Router01.sol";

interface IUniswapV2Router02 is IUniswapV2Router01 {
    function removeLiquidityETHSupportingFeeOnTransferTokens(
        address token,
        uint256 liquidity,
        uint256 amountTokenMin,
        uint256 amountETHMin,
        address to,
        uint256 deadline
    ) external returns (uint256 amountETH);

    function removeLiquidityETHWithPermitSupportingFeeOnTransferTokens(
        address token,
        uint256 liquidity,
        uint256 amountTokenMin,
        uint256 amountETHMin,
        address to,
        uint256 deadline,
        bool approveMax,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) external returns (uint256 amountETH);

    function swapExactTokensForTokensSupportingFeeOnTransferTokens(
        uint256 amountIn,
        uint256 amountOutMin,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external;

    function swapExactETHForTokensSupportingFeeOnTransferTokens(
        uint256 amountOutMin,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external payable;

    function swapExactTokensForETHSupportingFeeOnTransferTokens(
        uint256 amountIn,
        uint256 amountOutMin,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external;
}

pragma solidity >=0.5.0;

interface IWETH {
    function deposit() external payable;

    function transfer(address to, uint256 value) external returns (bool);

    function withdraw(uint256) external;
}

pragma solidity >=0.8.0;

import {IERC20} from "../../../dependencies/openzeppelin/contracts/IERC20.sol";
import {IWETH} from "../../../../contracts/misc/interfaces/IWETH.sol";
import {SafeERC20} from "../../../dependencies/openzeppelin/contracts/SafeERC20.sol";
import {IBaseRewardsPool} from "./convex/IBaseRewardsPool.sol";
import {IVirtualBalanceRewardPool} from "./convex/IVirtualBalanceRewardPool.sol";
import {IUniswapV2Router02} from "./sushi/IUniswapV2Router02.sol";
import {IBaseStrategy} from "../../../interfaces/IBaseStrategy.sol";
import {ICurveAddressProvider} from "../deps/curve/ICurveAddressProvider.sol"; 
import {ICurveRegistryExchange} from "../deps/curve/ICurveExchange.sol"; 
import {ICurveFi} from "./curve/ICurveFi.sol";
import {ILendingPoolAddressesProvider} from "../../../interfaces/ILendingPoolAddressesProvider.sol";
import {IPriceOracleGetter} from "../../../interfaces/IPriceOracleGetter.sol";
import {AssetMappings} from "../../lendingpool/AssetMappings.sol";

import "hardhat/console.sol";

library vStrategyHelper {
    using SafeERC20 for IERC20;

    address internal constant WETH = 0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2;
    address internal constant ethNative = 0xEeeeeEeeeEeEeeEeEeEeeEEEeeeeEeeeeeeeEEeE;

    IERC20 internal constant crvToken =
        IERC20(0xD533a949740bb3306d119CC777fa900bA034cd52);
    IERC20 internal constant cvxToken =
        IERC20(0x4e3FBD56CD56c3e72c1403e103b45Db9da5B9D2B);
	ICurveAddressProvider internal constant curveAddressProvider = 
		ICurveAddressProvider(0x0000000022D53366457F9d5E68Ec105046FC4383); 
    IUniswapV2Router02 internal constant sushiRouter = 
		IUniswapV2Router02(0xd9e1cE17f2641f24aE83637ab66a2cca9C378B9F);

    ICurveFi internal constant ThreeCrvRegistryExchange = ICurveFi(0xbEbc44782C7dB0a1A60Cb6fe97d0b483032FF1C7);
    address internal constant ThreeCrv = 0x6c3F90f043a72FA612cbac8115EE7e52BDe6E490;


    function computeSwapPath(address tokenIn, address tokenOut, uint256 amount)
        internal 
        returns (uint256 amountOut)
    {
        require(amount>0, "Trying to swap no tokens");
		//check if tokenIn is one of the tokens we want stable swaps for 
		(address curveSwapPool, uint256 amountExpected, address curveRegistryExchange) = swapCurve(tokenIn, tokenOut, amount); 
		
		if (curveSwapPool != address(0)) {
            //must approve the curve pools. This function checks if already max, and if not, then makes it max
            tokenAllowAll(
                address(tokenIn),
                curveRegistryExchange
            );
			try ICurveRegistryExchange(curveRegistryExchange).exchange(
				curveSwapPool,
				tokenIn,
				tokenOut,
				amount,
				amountExpected,
				address(this) //this may cause some weird behavior calling the swaps now, make sure the stategy is receiving funds
                //msg.sender gives these funds to the user who is calling tend
			) returns (uint256 amountOut) {
				console.log("amount returned from CURVE", amountOut); 	
				return amountOut; 
			} catch Error(string memory reason) {
				console.log("Curve swap could not be completed", reason); 
			} catch(bytes memory reason) {
				console.log("Curve unknown error", string(reason)); 	
			}
		} else {
			amountOut = swapSushi(tokenIn, tokenOut, amount); 	
			console.log("amount returned from SUSHI:", amountOut); 
			return amountOut; 
		}

    }

	function swapSushi(
		address tokenIn, 
		address tokenOut,
		uint256 amount) 
		internal returns(uint256) {

		address[] memory path; 	

        uint256 tokenOutIdx;
        if (tokenIn == WETH || tokenOut == WETH) {
            path = new address[](2);
            path[0] = tokenIn;
            path[1] = tokenOut;
            tokenOutIdx = 1;
        } else {
            path = new address[](3);
            path[0] = tokenIn;
            path[1] = WETH;
            path[2] = tokenOut;
            tokenOutIdx = 2;
        }

        tokenAllowAll(
            address(tokenIn),
            address(sushiRouter)
        );
			
        try sushiRouter.swapExactTokensForTokens(
			amount,
            0,//tendData.crvTended/EFFICIENCY, //min amount out (0 works fine)
			path,
            address(this),
            block.timestamp
		) returns (uint256[] memory amounts) {
			// console.log("amount returned from SUSHI", amounts[0]); 
			return amounts[tokenOutIdx]; 
		} catch Error(string memory reason) {
			console.log("swap could not be completed on SUSHI", reason); 
		} catch (bytes memory reason) {
			console.log("unknwon error sushi swap", string(reason)); 
		}
	}

	//uses curve to swap for the indexed token we want
	function swapCurve(
		address tokenIn, 
		address tokenOut, 
		uint256 amount
	) internal returns (address swapPool, uint256 amountExpected, address curveRegistryExchange) {
		//use curve address provider to get registry (in case they migrate contracts ever)
		curveRegistryExchange = curveAddressProvider.get_address(2); //the registry exchange contract will always be the second index, but the address itself can change (per curve docs) 
		//use curve registry interface to get pool for the coins we want to swap
		(swapPool, amountExpected) = ICurveRegistryExchange(curveRegistryExchange).get_best_rate(tokenIn, tokenOut, amount); 

		return (swapPool, amountExpected, curveRegistryExchange); 
	}

    //ensure that the order being passed in here is the same as the order in the coins[] array
    //needed for highest returned amount of LP tokens, the lower the amount in the pool, the more lp returned
    //NOTE: only applicable for curveV2 pools where assets are not the same
    function checkForHighestPayingToken(
        ICurveFi curvePool,
        uint256 poolSize,
        ILendingPoolAddressesProvider addressProvider
    ) public view returns (address highestPayingToken, uint256 index) {
        address[] memory poolTokens = new address[](poolSize);
        uint256[] memory amountsInPool = new uint256[](poolSize);
        AssetMappings a = AssetMappings(addressProvider.getAssetMappings());
        for (uint8 i = 0; i < poolSize; i++) {
            poolTokens[i] = curvePool.coins(i);
            if(poolTokens[i]==ethNative){
                poolTokens[i] = WETH; 
            }
            IPriceOracleGetter oracle = IPriceOracleGetter(addressProvider.getPriceOracle(
            ));

            amountsInPool[i] = curvePool.balances(i)*oracle.getAssetPrice(poolTokens[i])/(10**a.getDecimals(poolTokens[i]));
        }
        (, index) = min(amountsInPool); //doesn't consider decimals or asset price
        highestPayingToken = poolTokens[index];

        return (highestPayingToken, index);
    }

    function getLiquidityAmountsArray(
        uint256 n,
        uint256 amountToken,
        uint256 index
    ) public pure returns (uint256[] memory amounts) {
        //create array based on size of pool
        amounts = new uint256[](n);

        //only populate the index we are going to use, the rest should already be 0 I think
        amounts[index] = amountToken;
        return amounts;
    }

    //in case someone tries to break it by depositing eth like a pleb
    function getLiquidityAmountsArrayIncludingEth(
        uint256 index,
        uint256 amountEth,
        uint256 amountToken
    ) public pure returns (uint256[2] memory _amounts) {
        //check if eth and wanted are the same token and account for extraneous eth deposits
        if (index == 0) {
            _amounts[0] = amountEth;
            _amounts[1] = 0;
        } else {
            _amounts[0] = amountEth;
            _amounts[1] = amountToken;
        }

        return _amounts;
    }

    function getFixedArraySizeTwo(uint256[] memory array)
        public
        pure
        returns (uint256[2] memory)
    {
        uint256[2] memory pArray;

        //point this new fixed array to the dynamic one gotten from getLiquidityAmountsArray()
        // 0x20 needs to be added to an array because the first slot contains the
        // array length
        assembly {
            pArray := add(array, 0x20)
        }

        return pArray;
    }

    function getFixedArraySizeThree(uint256[] memory array)
        public
        pure
        returns (uint256[3] memory)
    {
        uint256[3] memory pArray;

        assembly {
            pArray := add(array, 0x20)
        }

        return pArray;
    }

    function getFixedArraySizeFour(uint256[] memory array)
        public
        pure
        returns (uint256[4] memory)
    {
        uint256[4] memory pArray;

        assembly {
            pArray := add(array, 0x20)
        }

        return pArray;
    }

    function tokenAllowAll(address asset, address allowee) public {
        IERC20 token = IERC20(asset);

        if (token.allowance(address(this), allowee) == 0) {
            token.safeApprove(allowee, type(uint256).max);
        } else if (token.allowance(address(this), allowee) != type(uint256).max) {
            token.safeApprove(allowee, 0);
            token.safeApprove(allowee, type(uint256).max);
        }
    }

    //generic function to get the address of (n) return tokens
    function getExtraRewardsTokens(IBaseRewardsPool baseRewardsPool)
        public
        view
        returns (address[] memory extraRewardsTokens)
    {
        uint256 extraLength = baseRewardsPool.extraRewardsLength();
        address[] memory rewardsContracts = new address[](extraLength);
        extraRewardsTokens = new address[](extraLength);

        for (uint8 i = 0; i < extraLength; i++) {
            rewardsContracts[i] = baseRewardsPool.extraRewards(i);
            extraRewardsTokens[i] = IVirtualBalanceRewardPool(
                rewardsContracts[i]
            ).rewardToken();
        }

        return extraRewardsTokens;
    }

    struct tendVars {
        uint256 EFFICIENCY;
        uint256 highestPayingIdx;
        uint8 i;
        bool targetIsCurveToken;
        address wantedDepositToken;
        
    }

    event TendError(bytes message);

    function tend(
        IBaseRewardsPool baseRewardsPool,
        ICurveFi curvePool,
        uint256 poolSize,
        address[] storage extraTokens,
        mapping(address => uint256) storage extraRewardsTended,
        ILendingPoolAddressesProvider addressProvider,
        uint256 EFFICIENCY
    )
        public
        returns (
            IBaseStrategy.TendData memory tendData,
            uint256 depositAmountWanted,
            uint256 index
        )
    {
        // 1. Harvest gains from positions

        // uint256 balanceBefore = baseRewardsPool.balanceOf(address(this));

        // Harvest CRV, CVX, and extra rewards tokens from staking positions
        // Note: Always claim extras
        tendVars memory vars;
        {
            vars.EFFICIENCY=EFFICIENCY; //unused for now
        }
        baseRewardsPool.getReward(address(this), true);

        //TODO: implement generic function to track extraRewardsToken balances to return them with tendData
        // Track harvested coins, before conversion
        tendData.crvTended = crvToken.balanceOf(address(this));
        tendData.cvxTended = cvxToken.balanceOf(address(this));

        //first we swap for the current lowest amount in the pool
        (
            vars.wantedDepositToken,
            vars.highestPayingIdx
        ) = checkForHighestPayingToken(curvePool, poolSize, addressProvider);
        vars.targetIsCurveToken = false;
        
        console.log("wantedDepositToken: ", vars.wantedDepositToken);

        if(vars.wantedDepositToken==ThreeCrv){ //edge case of trying to get 3crv, which cannot be traded for
            //either change this to frax, or optimize by swapping into usdc or something and getting 3crv
            // vars.wantedDepositToken = 0x853d955aCEf822Db058eb8505911ED77F175b99e; 
            // vars.highestPayingIdx = 0;
            vars.targetIsCurveToken = true;
            //3crv hardcoded            
            (
                vars.wantedDepositToken,
                vars.highestPayingIdx
            ) = checkForHighestPayingToken(ThreeCrvRegistryExchange, 3, addressProvider);
            console.log("changed wantedDepositToken: ", vars.wantedDepositToken);
        }

        
		//computeSwapPath will now swap the tokens and return the amount received
        for (vars.i = 0; vars.i < extraTokens.length; vars.i++) {
            extraRewardsTended[extraTokens[vars.i]] = IERC20(extraTokens[vars.i])
                .balanceOf(address(this));

             computeSwapPath(
                extraTokens[vars.i],
                vars.wantedDepositToken,
				extraRewardsTended[extraTokens[vars.i]]
            );
		}

        computeSwapPath(
            address(crvToken),
            vars.wantedDepositToken,
			tendData.crvTended
        );

        computeSwapPath(
            address(cvxToken),
            vars.wantedDepositToken,
			tendData.cvxTended
        );

        // if(wantedDepositToken == ethNative){ //should all be WETH now, convert WETH to ETH
        //     IWETH(WETH).withdraw(IERC20(WETH).balanceOf(address(this)));
        // }

        //get the lowest balance coin in the pool for max lp tokens on deposit
        depositAmountWanted = IERC20(vars.wantedDepositToken).balanceOf(
            address(this)
        );
		console.log("depositAmountWanted: ", depositAmountWanted); 

        index = vars.highestPayingIdx;

        if(vars.targetIsCurveToken){
            for (uint8 i = 0; i < 3; i++) {
                // approval for the strategy to deposit tokens into LP
                tokenAllowAll(
                    ThreeCrvRegistryExchange.coins(i),
                    address(ThreeCrvRegistryExchange)
                );
            }
            addLiquidityToCurve(3, depositAmountWanted, index, ThreeCrvRegistryExchange);
            depositAmountWanted = IERC20(ThreeCrv).balanceOf(
                address(this)
            );
            index = 1;
        }
    }

    function addLiquidityToCurve(uint256 poolSize, uint256 depositAmountWanted, uint256 index, ICurveFi curvePool) public{
       require(depositAmountWanted>0, "Strategy tend error: Not enough rewards to tend efficiently");
       //returns a dynamic array filled with the amounts in the index we need for curve
       
        uint256[] memory amounts = getLiquidityAmountsArray(
            poolSize,
            depositAmountWanted,
            index
        );

        //return a fixed size array based on input within one function rather this disgusting mess
        if (poolSize == 2) {
            curvePool.add_liquidity(
                getFixedArraySizeTwo(amounts),
                0
            );
        } else if (poolSize == 3) {
            curvePool.add_liquidity(
                getFixedArraySizeThree(amounts),
                0
            );
        } else {
            curvePool.add_liquidity(
                getFixedArraySizeFour(amounts),
                0
            );
        }
    }

    function min(uint256[] memory array)
        internal
        pure
        returns (uint256, uint256)
    {
        uint256 min = array[0];
        uint256 index;
        for (uint8 i = 1; i < array.length; i++) {
            if (min > array[i]) {
                min = array[i];
                index = i;
            }
        }
        return (min, index);
    }

    /**
     * @dev Returns the smallest of two numbers.
     */
    function min(uint256 a, uint256 b) internal pure returns (uint256) {
        return a < b ? a : b;
    }
}

// SPDX-License-Identifier: MIT
pragma solidity >=0.8.0;

import {BaseStrategy} from "../BaseStrategy.sol";
import {IBooster} from "../deps/convex/IBooster.sol";
import {IBaseRewardsPool} from "../deps/convex/IBaseRewardsPool.sol";
import {IVirtualBalanceRewardPool} from "../deps/convex/IVirtualBalanceRewardPool.sol";
import {IWETH} from "../deps/tokens/IWETH.sol";
import {vStrategyHelper} from "../deps/vStrategyHelper.sol";
import {ICurveFi} from "../deps/curve/ICurveFi.sol";
import {IUniswapV2Router02} from "../deps/sushi/IUniswapV2Router02.sol";
import {IERC20} from "../../../dependencies/openzeppelin/contracts/IERC20.sol";
import {IStrategy} from "./IStrategy.sol";

import {ILendingPoolAddressesProvider} from "../../../interfaces/ILendingPoolAddressesProvider.sol";
import {AssetMappings} from "../../../protocol/lendingpool/AssetMappings.sol";
import {DataTypes} from "../../../protocol/libraries/types/DataTypes.sol";

import "hardhat/console.sol";
//need modifiers for permissioned actors after built into lending pool
contract CrvLpEthStrategy is BaseStrategy, IStrategy {
    //NOTE: underlying and lendingPool are inherited from BaseStrategy.sol

    //Tokens included in strategy
    //LP/deposit token
    //CRV - rewards
    //CVX - rewards

    IERC20 public constant crvToken =
        IERC20(0xD533a949740bb3306d119CC777fa900bA034cd52);
    IERC20 public constant cvxToken =
        IERC20(0x4e3FBD56CD56c3e72c1403e103b45Db9da5B9D2B);
    address public constant ethNative =
        0xEeeeeEeeeEeEeeEeEeEeeEEEeeeeEeeeeeeeEEeE;

    // baseRewards gives us CRV rewards, and the generation of CRV generates CVX rewards
    IBooster public constant booster =
        IBooster(0xF403C135812408BFbE8713b5A23a04b3D48AAE31);
    IBaseRewardsPool public baseRewardsPool;

    //Curve Registry
    ICurveFi public curvePool; //needed for curve pool functionality
    address[] public extraTokens;

    //Sushi
    IUniswapV2Router02 internal constant sushiRouter =
        IUniswapV2Router02(0xd9e1cE17f2641f24aE83637ab66a2cca9C378B9F);

    uint256 public pid;
    uint8 public poolSize;

    //no constructor so we can link contract to vault after deploy, instead we use an init function
    //add modifiers as needed
    //TODO finish this up with base strategy init
    function initialize(
        address _addressProvider,
        address _underlying,
        uint64 _tranche
        // uint256 _pid,
        // uint8 _poolSize,
        // address _curvePool
    ) public override initializer{
        __BaseStrategy_init(_addressProvider, _underlying, _tranche);
        DataTypes.CurveMetadata memory vars = AssetMappings(ILendingPoolAddressesProvider(_addressProvider).getAssetMappings()).getCurveMetadata(_underlying);

        pid = vars._pid;
        poolSize = vars._poolSize;

        IBooster.PoolInfo memory poolInfo = booster.poolInfo(pid);
        baseRewardsPool = IBaseRewardsPool(poolInfo.crvRewards);

        curvePool = ICurveFi(vars._curvePool);

        //on eth pools, curve uses the 0xeeee address, and approvals will fail since it's ether and not a token
        for (uint8 i = 0; i < poolSize; i++) {
            if (curvePool.coins(i) == ethNative) {
                vStrategyHelper.tokenAllowAll(
                    vStrategyHelper.WETH,
                    address(sushiRouter)
                );
            } else {
                vStrategyHelper.tokenAllowAll(
                    curvePool.coins(i),
                    address(sushiRouter)
                );
            }
        }

        // approvals for boosting lp token
        vStrategyHelper.tokenAllowAll(underlying, address(booster));

        // approvals for swapping rewards back to lp
        vStrategyHelper.tokenAllowAll(address(crvToken), address(sushiRouter));
        vStrategyHelper.tokenAllowAll(address(cvxToken), address(sushiRouter));

        //approvals for n rewards tokens
        extraTokens = vStrategyHelper.getExtraRewardsTokens(baseRewardsPool);
        for (uint8 i = 0; i < extraTokens.length; i++) {
            vStrategyHelper.tokenAllowAll(extraTokens[i], address(sushiRouter));
        }
    }

    function earned() external view returns (uint256){
        return baseRewardsPool.earned(address(this));
    }

    function getName() external pure override returns (string memory) {
        return "VMEX (LP Token Name Goes Here) Strategy";
    }

    // these tokens are involved with the strategy
    function getProtectedTokens()
        public
        view
        override
        returns (address[] memory)
    {
        address[] memory protectedTokens = new address[](1);
        protectedTokens[0] = underlying;
        // protectedTokens[1] = address(crvToken);
        // protectedTokens[2] = address(cvxToken);
        return protectedTokens;
    }

    //these are called by vault contracts or in our case the lending pools themselves
    function _pull(uint256 amount) internal override {
        //send to Convex Booster here
        booster.deposit(pid, amount, true); //true for yes, we want to stake
    }

    //keeping in just in case something happens and we need to remove all funds and/or migrate the strategy
    //can withdraw directly from the rewards contract itself and avoid paying extra gas for using booster?
    function _withdrawAll() internal override {
        baseRewardsPool.withdrawAllAndUnwrap(true);
        // Note: All want is automatically withdrawn outside this "inner hook" in base strategy function
    }

    function _withdrawSome(uint256 amount) internal override returns (uint256) {
        baseRewardsPool.withdrawAndUnwrap(amount, true);
        return amount;
    }

    function _isTendable() internal pure override returns (bool) {
        return true; // Change to true if the strategy should be tended
    }

    // farm and dump strategy will never stake CVX and cvxCRV, so no need to
    // distribute those rewards thru harvesting
    function _harvest()
        internal
        override
        returns (TokenAmount[] memory harvested)
    {
        revert("harvest not implemented");
    }

    // By farm and dump strategy, tend() will swap all rewards back into base LP token,
    // then deposit the LP back into the booster.
    function _tend(uint256 minOut) internal override returns (uint256) {
        //check to see if rewards have stopped streaming
        // other rewards might be gotten?
        // require(
        //     baseRewardsPool.earned(address(this)) != 0,
        //     "rewards not streaming"
        // );
        uint256 balanceBefore = balanceOfPool();

        (
            TendData memory tendData,
            uint256 depositAmountWanted,

        ) = vStrategyHelper.tend(
                baseRewardsPool,
                curvePool,
                poolSize,
                extraTokens,
                extraRewardsTended,
                addressProvider,
                EFFICIENCY
            );
        // if(depositAmountWanted==0){
        //     return 0;
        // }
        //decide if we want to revert or return 0
        require(depositAmountWanted>0, "Strategy tend error: Not enough rewards to tend efficiently");

        //now we need to unwrap any weth we might have after swap
        //using weth so we don't have to implement a seperate uni call for swapping directly to eth
        if (IERC20(vStrategyHelper.WETH).balanceOf(address(this)) > 0) {
            IWETH(vStrategyHelper.WETH).withdraw(
                IERC20(vStrategyHelper.WETH).balanceOf(address(this))
            );
        }
        uint256 ethBalance = address(this).balance;

        //returns a dynamic array filled with the amounts in the index we need for curve
        uint256[2] memory amounts = vStrategyHelper
            .getLiquidityAmountsArrayIncludingEth(
                index,
                ethBalance,
                depositAmountWanted
            );
        console.log("amounts[0]: ",amounts[0]);
        console.log("amounts[1]: ",amounts[1]);
        //in eth pools, eth seems to always be index 0
        curvePool.add_liquidity{value: ethBalance}(amounts, 0);

        //update pool balance
        _pull(IERC20(underlying).balanceOf(address(this)));
        uint256 balanceAfter = balanceOfPool();

        uint256 timeDifference =
            block.timestamp - (uint256(lastHarvestTime));
        lastHarvestTime = block.timestamp;
        uint256 amountEarned = (balanceAfter - balanceBefore);
        require(amountEarned>=minOut, "Strategy error: insufficient output");
        //update globals, inherited from BaseStrategy.sol
        interestRate(amountEarned, balanceBefore, timeDifference);
        

        //mint to treasury and update LI
        _updateState(amountEarned);

        return amountEarned;
    }

    /// @dev Return the balance (in underlying) that the strategy has invested somewhere
    function balanceOfPool() public view override returns (uint256) {
        // Change this to return the amount of underlying invested in another protocol
        return baseRewardsPool.balanceOf(address(this));
    }

    /// @dev Return the balance of rewards that the strategy has accrued
    /// @notice Used for offChain APY and Harvest Health monitoring
    function balanceOfRewards()
        external
        view
        override
        returns (TokenAmount[] memory rewards)
    {
        //unused since we doing all off chain calculations
    }

    // include so our contract plays nicely with ether
    receive() external payable {}
}

// SPDX-License-Identifier: MIT
pragma solidity >=0.8.0;

import {BaseStrategy} from "../BaseStrategy.sol";
import {IBooster} from "../deps/convex/IBooster.sol";
import {IBaseRewardsPool} from "../deps/convex/IBaseRewardsPool.sol";
import {IVirtualBalanceRewardPool} from "../deps/convex/IVirtualBalanceRewardPool.sol";
import {IERC20} from "../../../dependencies/openzeppelin/contracts/IERC20.sol";
import {vStrategyHelper} from "../deps/vStrategyHelper.sol";
import {ICurveFi} from "../deps/curve/ICurveFi.sol";
import {IUniswapV2Router02} from "../deps/sushi/IUniswapV2Router02.sol";
import {ILendingPoolAddressesProvider} from "../../../interfaces/ILendingPoolAddressesProvider.sol";
import {AssetMappings} from "../../../protocol/lendingpool/AssetMappings.sol";
import {DataTypes} from "../../../protocol/libraries/types/DataTypes.sol";
import {IStrategy} from "./IStrategy.sol";
import "hardhat/console.sol";

//need modifiers for permissioned actors after built into lending pool
contract CrvLpStrategy is BaseStrategy, IStrategy {
    //NOTE: underlying and lendingPool are inherited from BaseStrategy.sol

    //Tokens included in strategy
    //LP/deposit token
    //CRV - rewards
    //CVX - rewards

    // baseRewards gives us CRV rewards, and the generation of CRV generates CVX rewards
    IBooster public constant booster =
        IBooster(0xF403C135812408BFbE8713b5A23a04b3D48AAE31);
    IBaseRewardsPool public baseRewardsPool;

    //Curve Registry
    ICurveFi public curvePool; //needed for curve pool functionality
    address[] public extraTokens;

    //Sushi
    IUniswapV2Router02 internal constant sushiRouter = IUniswapV2Router02(0xd9e1cE17f2641f24aE83637ab66a2cca9C378B9F);

    uint256 public pid;
    uint8 public poolSize;

    //no constructor so we can link contract to vault after deploy, instead we use an init function
    //add modifiers as needed
    function initialize(
        address _addressProvider,
        address _underlying,
        uint64 _tranche
    ) public override initializer {
        console.log("Inside initialize for CrvLpStrategy");
        __BaseStrategy_init(_addressProvider, _underlying, _tranche);
        console.log("After base strat init");

        DataTypes.CurveMetadata memory vars = AssetMappings(ILendingPoolAddressesProvider(_addressProvider).getAssetMappings()).getCurveMetadata(_underlying);

        pid = vars._pid;
        poolSize = vars._poolSize;

        IBooster.PoolInfo memory poolInfo = booster.poolInfo(pid);
        baseRewardsPool = IBaseRewardsPool(poolInfo.crvRewards);

        curvePool = ICurveFi(vars._curvePool);

        //on eth pools, curve uses the 0xeeee address, and approvals will fail since it's ether and not a token
        for (uint8 i = 0; i < poolSize; i++) {
            // approval for the strategy to deposit tokens into LP
            vStrategyHelper.tokenAllowAll(
                curvePool.coins(i),
                address(curvePool)
            );
        }

        // approvals for boosting lp token
        vStrategyHelper.tokenAllowAll(underlying, address(booster));

        // approvals for swapping rewards back to lp
        vStrategyHelper.tokenAllowAll(
            address(vStrategyHelper.crvToken),
            address(sushiRouter)
        );
        vStrategyHelper.tokenAllowAll(
            address(vStrategyHelper.cvxToken),
            address(sushiRouter)
        );

        //approvals for n rewards tokens
        extraTokens = vStrategyHelper.getExtraRewardsTokens(baseRewardsPool);
        for (uint8 i = 0; i < extraTokens.length; i++) {
            vStrategyHelper.tokenAllowAll(extraTokens[i], address(sushiRouter));
        }
    }

    function earned() external view returns (uint256){
        return baseRewardsPool.earned(address(this));
    }


    function getName() external pure override returns (string memory) {
        return "VMEX (LP Token Name Goes Here) Strategy";
    }

    // these tokens are involved with the strategy
    function getProtectedTokens()
        public
        view
        override
        returns (address[] memory)
    {
        address[] memory protectedTokens = new address[](1);
        protectedTokens[0] = underlying;
        // protectedTokens[1] = address(vStrategyHelper.crvToken);
        // protectedTokens[2] = address(vStrategyHelper.cvxToken);
        return protectedTokens;
    }

    //these are called by vault contracts or in our case the lending pools themselves
    function _pull(uint256 amount) internal override {
        //send to Convex Booster here
        booster.deposit(pid, amount, true); //true for yes, we want to stake
    }

    //keeping in just in case something happens and we need to remove all funds and/or migrate the strategy
    //can withdraw directly from the rewards contract itself and avoid paying extra gas for using booster?
    function _withdrawAll() internal override {
//        console.log("trying to withdraw all");
        baseRewardsPool.withdrawAllAndUnwrap(true);
        // Note: All want is automatically withdrawn outside this "inner hook" in base strategy function
    }

    function _withdrawSome(uint256 amount) internal override returns (uint256) {
        // tries to withdraw as much as possible
        uint256 amountBoosted = balanceOfPool();
        if (amountBoosted <= amount) {
            _withdrawAll();
            return amountBoosted;
        }

//        console.log("amount boosted is", amountBoosted);
//        console.log("trying to withdraw", amount);
//        console.log("amount earned is", baseRewardsPool.earned(address(this)));
        uint256 periodFinish = baseRewardsPool.periodFinish();
//        console.log("period finish is: ", periodFinish);
//        console.log("current timestamp is: ", block.timestamp);
        baseRewardsPool.withdrawAndUnwrap(amount, false);
        return amount;
    }

    function _isTendable() internal pure override returns (bool) {
        return true; // Change to true if the strategy should be tended
    }

    // farm and dump strategy will never stake CVX and cvxCRV, so no need to
    // distribute those rewards thru harvesting
    function _harvest()
        internal
        override
        returns (TokenAmount[] memory harvested)
    {
        revert("harvest not implemented");
    }

    // By farm and dump strategy, tend() will swap all rewards back into base LP token,
    // then deposit the LP back into the booster.
    function _tend(uint256 minOut) internal override returns (uint256 amountTended) {
        uint256 balanceBefore = balanceOfPool();

        (
            TendData memory tendData,
            uint256 depositAmountWanted,
            uint256 index
        ) = vStrategyHelper.tend(
                baseRewardsPool,
                curvePool, 
                poolSize,
                extraTokens,
                extraRewardsTended,
                addressProvider,
                EFFICIENCY
            );

        vStrategyHelper.addLiquidityToCurve(poolSize, depositAmountWanted, index, curvePool);
        

        // deposit all LP tokens into booster
        _pull(IERC20(underlying).balanceOf(address(this)));
        uint256 balanceAfter = balanceOfPool();

        uint256 timeDifference =
            block.timestamp - (uint256(lastHarvestTime));
        lastHarvestTime = block.timestamp;
        uint256 amountEarned = (balanceAfter - balanceBefore);
        require(amountEarned>=minOut, "Strategy error: insufficient output");

        //update globals, inherited from BaseStrategy.sol
        interestRate(amountEarned, balanceBefore, timeDifference);
        

        //mint to treasury and update LI
        _updateState(amountEarned);
        emit Tend(tendData);

        return amountEarned;
    }

    /// @dev Return the balance (in underlying) that the strategy has invested somewhere
    function balanceOfPool() public view override returns (uint256) {
        // Change this to return the amount of underlying invested in another protocol
        return baseRewardsPool.balanceOf(address(this));
    }

    /// @dev Return the balance of rewards that the strategy has accrued
    /// @notice Used for offChain APY and Harvest Health monitoring
    function balanceOfRewards()
        external
        view
        override
        returns (TokenAmount[] memory rewards)
    {
        //unused since we doing all off chain calculations
    }
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity >=0.8.0;

import "../BaseStrategy.sol";
import "../deps/convex/CrvDepositor.sol";
import "../deps/convex/IBaseRewardsPool.sol";
import "../deps/convex/ICvxRewardsPool.sol";
import {vStrategyHelper} from "../deps/vStrategyHelper.sol";
import {IERC20} from "../../../dependencies/openzeppelin/contracts/IERC20.sol";
import {IUniswapV2Router02} from "../deps/sushi/IUniswapV2Router02.sol";
import {IStrategy} from "./IStrategy.sol";

//need modifiers for permissioned actors
contract CvxStrategy is BaseStrategy, IStrategy {
    //NOTE: underlying and lendingPool are inherited from BaseStrategy.sol

    // ===== Tokens =====
    IERC20 public constant crvToken =
        IERC20(0xD533a949740bb3306d119CC777fa900bA034cd52);
    IERC20 public constant cvxToken =
        IERC20(0x4e3FBD56CD56c3e72c1403e103b45Db9da5B9D2B);
    IERC20 internal constant cvxCrvToken =
        IERC20(0x62B9c7356A2Dc64a1969e19C23e4f579F9810Aa7);

    // ===== Convex Registry =====
    ICvxRewardsPool public constant cvxRewardsPool =
        ICvxRewardsPool(0xCF50b810E57Ac33B91dCF525C6ddd9881B139332);

    //Sushi
    IUniswapV2Router02 internal constant sushiRouter =
        IUniswapV2Router02(0xd9e1cE17f2641f24aE83637ab66a2cca9C378B9F);

    //no constructor so we can link contract to vault after deploy, instead we use an init function
    //add modifiers as needed
    function initialize(
        address _addressProvider, 
        address asset, //unused, but to satisfy requirements
        uint64 _tranche
    ) public override initializer{ 
        __BaseStrategy_init(_addressProvider, address(cvxToken), _tranche);

        // Approvals
        vStrategyHelper.tokenAllowAll(
            address(cvxCrvToken),
            address(sushiRouter)
        );
        vStrategyHelper.tokenAllowAll(
            address(cvxToken),
            address(cvxRewardsPool)
        );
        vStrategyHelper.tokenAllowAll(
            address(crvToken),
            address(sushiRouter)
        );
    }

    function earned() external view returns (uint256){
        return cvxRewardsPool.earned(address(this));
    }

    //do we need this? would assist with devs interfacing with these contracts
    function getName() external pure override returns (string memory) {
        return "VMEX CVX Strategy";
    }

    //this is local only? comes from badger/yearn
    function getProtectedTokens()
        public
        view
        override
        returns (address[] memory)
    {
        address[] memory protectedTokens = new address[](1);
        protectedTokens[0] = underlying;
        return protectedTokens;
    }

    //these are called by vault contracts or in our case the lending pools themselves
    function _pull(uint256 amount) internal override {
        cvxRewardsPool.stake(cvxToken.balanceOf(address(this)));
    }

    //keeping in just in case something happens and we need to remove all funds and/or migrate the strategy
    //can withdraw directly from the rewards contract itself and avoid paying extra gas for using booster?
    function _withdrawAll() internal override {
        cvxRewardsPool.withdraw(balanceOfPool(), false);
        // Note: All want is automatically withdrawn outside this "inner hook" in base strategy function
    }

    function _withdrawSome(uint256 amount) internal override returns (uint256) {
        cvxRewardsPool.withdraw(amount, true);
        return amount;
    }

    /// @dev Does this function require `tend` to be called?
    function _isTendable() internal pure override returns (bool) {
        return true; // Change to true if the strategy should be tended
    }

    function _harvest()
        internal
        override
        returns (TokenAmount[] memory harvested)
    {
        revert("harvest not implemented");
    }

    // By farm and dump strategy, tend() will swap all rewards back into CRV token,
    // then deposit the CRV into the reward pool.
    function _tend(uint256 minOut) internal override returns (uint256) {
        uint256 balanceBefore = balanceOfPool();
        TendData memory tendData;

        // 1. Harvest gains from positions

        // Harvest cvxCRV tokens from staking positions
        cvxRewardsPool.getReward(false);

        

        // Track harvested coins, before conversion
        tendData.cvxCrvTended = cvxCrvToken.balanceOf(address(this));
        require(tendData.cvxCrvTended>0,"CVX rewards are not streaming");

        // address[] memory path = new address[](4);
        // path[0] = address(cvxCrvToken);
        // path[1] = address(crvToken);
        // path[2] = 0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2; // WETH
        // path[3] = address(cvxToken);

        uint256 out1 = vStrategyHelper.computeSwapPath(address(cvxCrvToken), address(crvToken), tendData.cvxCrvTended);

        uint256 out2 = vStrategyHelper.computeSwapPath(address(crvToken), address(cvxToken), out1); //direct sushiswap

        // swap cvxCRV for CVX
        // try sushiRouter.swapExactTokensForTokens(
        //     tendData.cvxCrvTended,
        //     0,//tendData.cvxCrvTended/EFFICIENCY,
        //     path,
        //     address(this),
        //     block.timestamp
        // ) returns (uint256[] memory amounts){
        //     console.log("swapped cvx");
        //     for(uint i = 0;i<amounts.length;i++){
        //         console.log("amounts[i]: ",amounts[i]);
        //     }
        //     // 
        // } catch Error(string memory reason){
        //     console.log("Cvx Swap Error: ",reason);
        //     revert("Strategy tend error: Not enough rewards to tend efficiently");
        // }

        // TODO: potentially call pull() so we pull from lending pools
        // deposit all swapped CVX back into the

        _pull(cvxToken.balanceOf(address(this)));

        uint256 balanceAfter = balanceOfPool();


        uint256 timeDifference =
            block.timestamp - (uint256(lastHarvestTime));
        lastHarvestTime = block.timestamp;
        //update globals, inherited from BaseStrategy.sol
        uint256 amountEarned = (balanceAfter - balanceBefore);
        require(amountEarned>=minOut, "Strategy error: insufficient output");
        interestRate(amountEarned, balanceBefore, timeDifference);
        

        //mint to treasury and update LI
        _updateState(amountEarned);

        return amountEarned;
    }

    /// @dev Return the balance (in underlying) that the strategy has invested somewhere
    function balanceOfPool() public view override returns (uint256) {
        // Change this to return the amount of underlying invested in another protocol
        return cvxRewardsPool.balanceOf(address(this));
    }

    /// @dev Return the balance of rewards that the strategy has accrued
    /// @notice Used for offChain APY and Harvest Health monitoring
    function balanceOfRewards()
        external
        view
        override
        returns (TokenAmount[] memory rewards)
    {
        // Rewards are 0
        rewards = new TokenAmount[](1);
        rewards[0] = TokenAmount(underlying, 0);
        return rewards;
    }
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity >=0.8.0;

interface IStrategy {
    function initialize(
        address _addressProvider,
        address _underlying,
        uint64 _tranche) external;
}

// SPDX-License-Identifier: agpl-3.0
pragma solidity >=0.8.0;

import {IERC20} from "../../dependencies/openzeppelin/contracts/IERC20.sol";
import {SafeERC20} from "../../dependencies/openzeppelin/contracts/SafeERC20.sol";
import {ILendingPool} from "../../interfaces/ILendingPool.sol";
import {IAToken} from "../../interfaces/IAToken.sol";
import {WadRayMath} from "../libraries/math/WadRayMath.sol";
import {Errors} from "../libraries/helpers/Errors.sol";
import {VersionedInitializable} from "../libraries/aave-upgradeability/VersionedInitializable.sol";
import {IncentivizedERC20} from "./IncentivizedERC20.sol";
import {IAaveIncentivesController} from "../../interfaces/IAaveIncentivesController.sol";
import {IBaseStrategy} from "../../interfaces/IBaseStrategy.sol";
import {SafeMath} from "../../dependencies/openzeppelin/contracts/SafeMath.sol";
import {IYearnToken} from "../../oracles/interfaces/IYearnToken.sol";
import {ReserveConfiguration} from "../libraries/configuration/ReserveConfiguration.sol";
import {PercentageMath} from "../libraries/math/PercentageMath.sol";
import {DataTypes} from "../libraries/types/DataTypes.sol";
import "hardhat/console.sol";

/**
 * @title Aave ERC20 AToken
 * @dev Implementation of the interest bearing token for the Aave protocol
 * @author Aave
 */
contract AToken is
    VersionedInitializable,
    IncentivizedERC20("ATOKEN_IMPL", "ATOKEN_IMPL", 0),
    IAToken
{
    using WadRayMath for uint256;
    using SafeERC20 for IERC20;
    using SafeMath for uint256;
    using ReserveConfiguration for *;
    using PercentageMath for uint256;

    bytes public constant EIP712_REVISION = bytes("1");
    bytes32 internal constant EIP712_DOMAIN =
        keccak256(
            "EIP712Domain(string name,string version,uint256 chainId,address verifyingContract)"
        );
    bytes32 public constant PERMIT_TYPEHASH =
        keccak256(
            "Permit(address owner,address spender,uint256 value,uint256 nonce,uint256 deadline)"
        );

    uint256 public constant ATOKEN_REVISION = 0x1;

    // totalSupply / targetSupplyQuotient = targetSupply
    uint256 public constant targetSupplyQuotient = 10;
    // totalSupply / minSupplyQuotient = minSupply
    uint256 public constant minSupplyQuotient = 20;

    /// @dev owner => next valid nonce to submit with permit()
    mapping(address => uint256) public _nonces;

    bytes32 public DOMAIN_SEPARATOR;

    ILendingPool internal _pool;
    address internal _lendingPoolConfigurator;
    address internal _treasury;
    address internal _VMEXTreasury;
    address internal _underlyingAsset; //yearn address
    uint64 internal _tranche;
    address internal _strategy;
    IAaveIncentivesController internal _incentivesController;

    modifier onlyLendingPool() {
        require(
            _msgSender() == address(_pool),
            Errors.CT_CALLER_MUST_BE_LENDING_POOL
        );
        _;
    }

    modifier onlyLendingPoolOrStrategy() {
        require(
            _msgSender() == address(_pool) || _msgSender() == _strategy,
            Errors.CT_CALLER_MUST_BE_LENDING_POOL
        );
        _;
    }

    modifier onlyLendingPoolConfigurator() {
        require(
            _msgSender() == _lendingPoolConfigurator,
            Errors.LP_CALLER_NOT_LENDING_POOL_CONFIGURATOR
        );
        _;
    }

    function getRevision() internal pure virtual override returns (uint256) {
        return ATOKEN_REVISION;
    }

    /**
     * @dev Initializes the aToken
     * @param pool The address of the lending pool where this aToken will be used
     * @param vars Stores treasury vars to fix stack too deep
     * @param incentivesController The smart contract managing potential incentives distribution
     * @param aTokenDecimals The decimals of the aToken, same as the underlying asset's
     * @param aTokenName The name of the aToken
     * @param aTokenSymbol The symbol of the aToken
     */
    function initialize(
        ILendingPool pool,
        InitializeTreasuryVars memory vars,
        IAaveIncentivesController incentivesController,
        uint8 aTokenDecimals,
        string calldata aTokenName,
        string calldata aTokenSymbol
    ) external override initializer {
        uint256 chainId;

        //solium-disable-next-line
        assembly {
            chainId := chainid()
        }

        DOMAIN_SEPARATOR = keccak256(
            abi.encode(
                EIP712_DOMAIN,
                keccak256(bytes(aTokenName)),
                keccak256(EIP712_REVISION),
                chainId,
                address(this)
            )
        );

        _setName(aTokenName);
        _setSymbol(aTokenSymbol);
        _setDecimals(aTokenDecimals);

        _pool = pool;
        _lendingPoolConfigurator = vars.lendingPoolConfigurator;
        _treasury = vars.treasury;
        _VMEXTreasury = vars.VMEXTreasury;
        _underlyingAsset = vars.underlyingAsset;
        _incentivesController = incentivesController;
        _tranche = vars.trancheId;

        emit Initialized(
            vars.underlyingAsset,
            vars.trancheId,
            address(pool),
            vars.treasury,
            address(incentivesController),
            aTokenDecimals,
            aTokenName,
            aTokenSymbol
        );
    }

    function setTreasury(address newTreasury)
        external
        override
        onlyLendingPoolConfigurator
    {
        _treasury = newTreasury;
        emit TreasuryChanged(newTreasury);
    }

    function setVMEXTreasury(address newTreasury)
        external
        override
        onlyLendingPoolConfigurator
    {
        _VMEXTreasury = newTreasury;
        emit VMEXTreasuryChanged(newTreasury);
    }

    /**
     * @dev Burns aTokens from `user` and sends the equivalent amount of underlying to `receiverOfUnderlying`
     * - Only callable by the LendingPool, as extra state updates there need to be managed
     * @param user The owner of the aTokens, getting them burned
     * @param receiverOfUnderlying The address that will receive the underlying
     * @param amount The amount being burned
     * @param index The new liquidity index of the reserve
     **/
    function burn(
        address user,
        address receiverOfUnderlying,
        uint256 amount,
        uint256 index
    ) external override onlyLendingPool {
        uint256 amountScaled = amount.rayDiv(index);
        require(amountScaled != 0, Errors.CT_INVALID_BURN_AMOUNT);
        _burn(user, amountScaled); // Burn the entire amount of atokens that the user has, not just the amount they receive

        if (_strategy != address(0x0)) { //if it's yearn, it can't have a strategy
            // withdraw from strategy
            IBaseStrategy(_strategy).withdraw(amount);
        }



        IERC20(_underlyingAsset).safeTransfer(receiverOfUnderlying, amount);

        emit Transfer(user, address(0), amount); // note: this is amount user receives, not amount user requests
        emit Burn(user, receiverOfUnderlying, amount, index);
    }

    /**
     * @dev Mints `amount` aTokens to `user`
     * - Only callable by the LendingPool, as extra state updates there need to be managed
     * @param user The address receiving the minted tokens
     * @param amount The amount of tokens being deposited
     * @param index The new liquidity index of the reserve
     * @return `true` if the the previous balance of the user was 0
     */
    function mint(
        address user,
        uint256 amount,
        uint256 index
    ) external override onlyLendingPool returns (bool) {
        uint256 previousBalance = super.balanceOf(user);
        uint256 amountScaled = amount.rayDiv(index);
        require(amountScaled != 0, Errors.CT_INVALID_MINT_AMOUNT);
        _mint(user, amountScaled);

        emit Transfer(address(0), user, amount);
        emit Mint(user, amount, index);

        return previousBalance == 0;
    }

    /**
     * @dev Mints aTokens to the reserve treasury
     * - Only callable by the LendingPool
     * @param amount The amount of tokens getting minted
     * @param index The new liquidity index of the reserve
     */
    function mintToTreasury(uint256 amount, uint256 index)
        public
        override
        onlyLendingPool
    {
        if (amount == 0) {
            return;
        }

        address treasury = _treasury;

        // Compared to the normal mint, we don't check for rounding errors.
        // The amount to mint can easily be very small since it is a fraction of the interest ccrued.
        // In that case, the treasury will experience a (very small) loss, but it
        // wont cause potentially valid transactions to fail.
        _mint(treasury, amount.rayDiv(index));

        emit Transfer(address(0), treasury, amount);
        emit Mint(treasury, amount, index);
    }

    /**
     * @dev Mints aTokens to the reserve treasury
     * - Only callable by the LendingPool
     * @param amount The amount of tokens getting minted
     * @param index The new liquidity index of the reserve
     */
    function mintToVMEXTreasury(uint256 amount, uint256 index)
        public
        override
        onlyLendingPoolOrStrategy
    {
        if (amount == 0) {
            return;
        }

        address treasury = _VMEXTreasury;

        // Compared to the normal mint, we don't check for rounding errors.
        // The amount to mint can easily be very small since it is a fraction of the interest ccrued.
        // In that case, the treasury will experience a (very small) loss, but it
        // wont cause potentially valid transactions to fail.
        _mint(treasury, amount.rayDiv(index));

        emit Transfer(address(0), treasury, amount);
        emit Mint(treasury, amount, index);
    }

    /**
     * @dev Transfers aTokens in the event of a borrow being liquidated, in case the liquidators reclaims the aToken
     * - Only callable by the LendingPool
     * @param from The address getting liquidated, current owner of the aTokens
     * @param to The recipient
     * @param value The amount of tokens getting transferred
     **/
    function transferOnLiquidation(
        address from,
        address to,
        uint256 value
    ) external override onlyLendingPool {
        // Being a normal transfer, the Transfer() and BalanceTransfer() are emitted
        // so no need to emit a specific event here
        _transfer(from, to, value, false);

        emit Transfer(from, to, value);
    }

    /**
     * @dev Calculates the balance of the user: principal balance + interest generated by the principal
     * @param user The user whose balance is calculated
     * @return The balance of the user
     **/
    function balanceOf(address user)
        public
        view
        override(IncentivizedERC20, IERC20)
        returns (uint256)
    {
        // console.log("super.balanceOf(user): ",super.balanceOf(user));
        // console.log("_pool.getReserveNormalizedIncome(_underlyingAsset, _tranche): ",_pool.getReserveNormalizedIncome(_underlyingAsset, _tranche));
        return
            super.balanceOf(user).rayMul(
                _pool.getReserveNormalizedIncome(_underlyingAsset, _tranche)
            );
    }

    /**
     * @dev Returns the scaled balance of the user. The scaled balance is the sum of all the
     * updated stored balance divided by the reserve's liquidity index at the moment of the update
     * @param user The user whose balance is calculated
     * @return The scaled balance of the user
     **/
    function scaledBalanceOf(address user)
        external
        view
        override
        returns (uint256)
    {
        return super.balanceOf(user);
    }

    /**
     * @dev Returns the scaled balance of the user and the scaled total supply.
     * @param user The address of the user
     * @return The scaled balance of the user
     * @return The scaled balance and the scaled total supply
     **/
    function getScaledUserBalanceAndSupply(address user)
        external
        view
        override
        returns (uint256, uint256)
    {
        return (super.balanceOf(user), super.totalSupply());
    }

    /**
     * @dev calculates the total supply of the specific aToken
     * since the balance of every single user increases over time, the total supply
     * does that too.
     * @return the current total supply
     **/
    function totalSupply()
        public
        view
        override(IncentivizedERC20, IERC20)
        returns (uint256)
    {
        uint256 currentSupplyScaled = super.totalSupply();

        if (currentSupplyScaled == 0) {
            return 0;
        }

        return
            currentSupplyScaled.rayMul(
                _pool.getReserveNormalizedIncome(_underlyingAsset, _tranche)
            );
    }

    /**
     * @dev Returns the scaled total supply of the variable debt token. Represents sum(debt/index)
     * @return the scaled total supply
     **/
    function scaledTotalSupply()
        public
        view
        virtual
        override
        returns (uint256)
    {
        return super.totalSupply();
    }

    /**
     * @dev Returns the address of the Aave treasury, receiving the fees on this aToken
     **/
    function RESERVE_TREASURY_ADDRESS() public view returns (address) {
        return _treasury;
    }

    /**
     * @dev Returns the address of the underlying asset of this aToken (E.g. WETH for aWETH)
     **/
    function UNDERLYING_ASSET_ADDRESS() public view override returns (address) {
        return _underlyingAsset;
    }

    /**
     * @dev Returns the address of the lending pool where this aToken is used
     **/
    function POOL() public view returns (ILendingPool) {
        return _pool;
    }

    /**
     * @dev For internal usage in the logic of the parent contract IncentivizedERC20
     **/
    function _getIncentivesController()
        internal
        view
        override
        returns (IAaveIncentivesController)
    {
        return _incentivesController;
    }

    /**
     * @dev Returns the address of the incentives controller contract
     **/
    function getIncentivesController()
        external
        view
        override
        returns (IAaveIncentivesController)
    {
        return _getIncentivesController();
    }

    /**
     * @dev Transfers the underlying asset to `target`. Used by the LendingPool to transfer
     * assets in borrow(), withdraw() and flashLoan()
     * @param target The recipient of the aTokens
     * @param amount The amount getting transferred
     * @return The amount transferred
     **/
    function transferUnderlyingTo(address target, uint256 amount)
        external
        override
        onlyLendingPool
        returns (uint256)
    {
        IERC20(_underlyingAsset).safeTransfer(target, amount);
        return amount;
    }

    /**
     * @dev Invoked to execute actions on the aToken side after a repayment.
     * @param user The user executing the repayment
     * @param amount The amount getting repaid
     **/
    function handleRepayment(address user, uint256 amount)
        external
        override
        onlyLendingPool
    {}

    /**
     * @dev implements the permit function as for
     * https://github.com/ethereum/EIPs/blob/8a34d644aacf0f9f8f00815307fd7dd5da07655f/EIPS/eip-2612.md
     * @param owner The owner of the funds
     * @param spender The spender
     * @param value The amount
     * @param deadline The deadline timestamp, type(uint256).max for max deadline
     * @param v Signature param
     * @param s Signature param
     * @param r Signature param
     */
    function permit(
        address owner,
        address spender,
        uint256 value,
        uint256 deadline,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) external {
        require(owner != address(0), "INVALID_OWNER");
        //solium-disable-next-line
        require(block.timestamp <= deadline, "INVALID_EXPIRATION");
        uint256 currentValidNonce = _nonces[owner];
        bytes32 digest = keccak256(
            abi.encodePacked(
                "\x19\x01",
                DOMAIN_SEPARATOR,
                keccak256(
                    abi.encode(
                        PERMIT_TYPEHASH,
                        owner,
                        spender,
                        value,
                        currentValidNonce,
                        deadline
                    )
                )
            )
        );
        require(owner == ecrecover(digest, v, r, s), "INVALID_SIGNATURE");
        _nonces[owner] = currentValidNonce.add(1);
        _approve(owner, spender, value);
    }

    /**
     * @dev Transfers the aTokens between two users. Validates the transfer
     * (ie checks for valid HF after the transfer) if required
     * @param from The source address
     * @param to The destination address
     * @param amount The amount getting transferred
     * @param validate `true` if the transfer needs to be validated
     **/
    function _transfer(
        address from,
        address to,
        uint256 amount,
        bool validate
    ) internal {
        address underlyingAsset = _underlyingAsset;
        ILendingPool pool = _pool;

        uint256 index = pool.getReserveNormalizedIncome(
            underlyingAsset,
            _tranche
        );

        uint256 fromBalanceBefore = super.balanceOf(from).rayMul(index);
        uint256 toBalanceBefore = super.balanceOf(to).rayMul(index);

        super._transfer(from, to, amount.rayDiv(index));

        if (validate) {
            pool.finalizeTransfer(
                underlyingAsset,
                _tranche,
                from,
                to,
                amount,
                fromBalanceBefore,
                toBalanceBefore
            );
        }

        emit BalanceTransfer(from, to, amount, index);
    }

    /**
     * @dev Overrides the parent _transfer to force validated transfer() and transferFrom()
     * @param from The source address
     * @param to The destination address
     * @param amount The amount getting transferred
     **/
    function _transfer(
        address from,
        address to,
        uint256 amount
    ) internal override {
        _transfer(from, to, amount, true);
    }

    function setAndApproveStrategy(address strategy)
        external
        override
        onlyLendingPool
    {
        _strategy = strategy;

        IERC20 token = IERC20(_underlyingAsset);

        if (token.allowance(address(this), strategy) != type(uint256).max) {
            token.safeApprove(strategy, type(uint256).max);
        }
    }

    /**
     * @dev Manually pull funds from strategy by strategist
     * @param amount The amount withdrawn from strategy
     **/
    function withdrawFromStrategy(uint256 amount)
        external
        override
        onlyLendingPool
    {
        IBaseStrategy(_strategy).withdraw(amount);
    }

    function getStrategy() external view override returns (address) {
        return _strategy;
    }
}

// SPDX-License-Identifier: agpl-3.0
pragma solidity >=0.8.0;

import {ILendingPool} from "../../../interfaces/ILendingPool.sol";
import {
    ICreditDelegationToken
} from "../../../interfaces/ICreditDelegationToken.sol";
import {
    VersionedInitializable
} from "../../libraries/aave-upgradeability/VersionedInitializable.sol";
import {IncentivizedERC20} from "../IncentivizedERC20.sol";
import {Errors} from "../../libraries/helpers/Errors.sol";
import {
    SafeMath
} from "../../../dependencies/openzeppelin/contracts/SafeMath.sol";

/**
 * @title DebtTokenBase
 * @notice Base contract for different types of debt tokens, like StableDebtToken or VariableDebtToken
 * @author Aave
 */

abstract contract DebtTokenBase is
    IncentivizedERC20("DEBTTOKEN_IMPL", "DEBTTOKEN_IMPL", 0),
    VersionedInitializable,
    ICreditDelegationToken
{
    using SafeMath for uint256;
    mapping(address => mapping(address => uint256)) internal _borrowAllowances;

    /**
     * @dev Only lending pool can call functions marked by this modifier
     **/
    modifier onlyLendingPool {
        require(
            _msgSender() == address(_getLendingPool()),
            Errors.CT_CALLER_MUST_BE_LENDING_POOL
        );
        _;
    }

    /**
     * @dev delegates borrowing power to a user on the specific debt token
     * @param delegatee the address receiving the delegated borrowing power
     * @param amount the maximum amount being delegated. Delegation will still
     * respect the liquidation constraints (even if delegated, a delegatee cannot
     * force a delegator HF to go below 1)
     **/
    function approveDelegation(address delegatee, uint256 amount)
        external
        override
    {
        _borrowAllowances[_msgSender()][delegatee] = amount;
        emit BorrowAllowanceDelegated(
            _msgSender(),
            delegatee,
            _getUnderlyingAssetAddress(),
            amount
        );
    }

    /**
     * @dev returns the borrow allowance of the user
     * @param fromUser The user to giving allowance
     * @param toUser The user to give allowance to
     * @return the current allowance of toUser
     **/
    function borrowAllowance(address fromUser, address toUser)
        external
        view
        override
        returns (uint256)
    {
        return _borrowAllowances[fromUser][toUser];
    }

    /**
     * @dev Being non transferrable, the debt token does not implement any of the
     * standard ERC20 functions for transfer and allowance.
     **/
    function transfer(address recipient, uint256 amount)
        public
        virtual
        override
        returns (bool)
    {
        recipient;
        amount;
        revert("TRANSFER_NOT_SUPPORTED");
    }

    function allowance(address owner, address spender)
        public
        view
        virtual
        override
        returns (uint256)
    {
        owner;
        spender;
        revert("ALLOWANCE_NOT_SUPPORTED");
    }

    function approve(address spender, uint256 amount)
        public
        virtual
        override
        returns (bool)
    {
        spender;
        amount;
        revert("APPROVAL_NOT_SUPPORTED");
    }

    function transferFrom(
        address sender,
        address recipient,
        uint256 amount
    ) public virtual override returns (bool) {
        sender;
        recipient;
        amount;
        revert("TRANSFER_NOT_SUPPORTED");
    }

    function increaseAllowance(address spender, uint256 addedValue)
        public
        virtual
        override
        returns (bool)
    {
        spender;
        addedValue;
        revert("ALLOWANCE_NOT_SUPPORTED");
    }

    function decreaseAllowance(address spender, uint256 subtractedValue)
        public
        virtual
        override
        returns (bool)
    {
        spender;
        subtractedValue;
        revert("ALLOWANCE_NOT_SUPPORTED");
    }

    function _decreaseBorrowAllowance(
        address delegator,
        address delegatee,
        uint256 amount
    ) internal {
        uint256 newAllowance =
            _borrowAllowances[delegator][delegatee].sub(
                amount,
                Errors.BORROW_ALLOWANCE_NOT_ENOUGH
            );

        _borrowAllowances[delegator][delegatee] = newAllowance;

        emit BorrowAllowanceDelegated(
            delegator,
            delegatee,
            _getUnderlyingAssetAddress(),
            newAllowance
        );
    }

    function _getUnderlyingAssetAddress()
        internal
        view
        virtual
        returns (address);

    function _getLendingPool() internal view virtual returns (ILendingPool);
}

// SPDX-License-Identifier: agpl-3.0
pragma solidity >=0.8.0;

import {ILendingPool} from "../../interfaces/ILendingPool.sol";
import {IDelegationToken} from "../../interfaces/IDelegationToken.sol";
import {Errors} from "../libraries/helpers/Errors.sol";
import {AToken} from "./AToken.sol";

/**
 * @title Aave AToken enabled to delegate voting power of the underlying asset to a different address
 * @dev The underlying asset needs to be compatible with the COMP delegation interface
 * @author Aave
 */
contract DelegationAwareAToken is AToken {
    modifier onlyGlobalAdmin() {
        require(
            _msgSender() ==
                ILendingPool(_pool).getAddressesProvider().getGlobalAdmin(),
            Errors.CALLER_NOT_GLOBAL_ADMIN
        );
        _;
    }

    /**
     * @dev Delegates voting power of the underlying asset to a `delegatee` address
     * @param delegatee The address that will receive the delegation
     **/
    function delegateUnderlyingTo(address delegatee) external onlyGlobalAdmin {
        IDelegationToken(_underlyingAsset).delegate(delegatee);
    }
}

// SPDX-License-Identifier: agpl-3.0
pragma solidity >=0.8.0;

import {Context} from "../../dependencies/openzeppelin/contracts/Context.sol";
import {IERC20} from "../../dependencies/openzeppelin/contracts/IERC20.sol";
import {
    IERC20Detailed
} from "../../dependencies/openzeppelin/contracts/IERC20Detailed.sol";
import {SafeMath} from "../../dependencies/openzeppelin/contracts/SafeMath.sol";
import {
    IAaveIncentivesController
} from "../../interfaces/IAaveIncentivesController.sol";

/**
 * @title ERC20
 * @notice Basic ERC20 implementation
 * @author Aave, inspired by the Openzeppelin ERC20 implementation
 **/
abstract contract IncentivizedERC20 is Context, IERC20, IERC20Detailed {
    using SafeMath for uint256;

    mapping(address => uint256) internal _balances;

    mapping(address => mapping(address => uint256)) private _allowances;
    uint256 internal _totalSupply;
    string private _name;
    string private _symbol;
    uint8 private _decimals;

    constructor(
        string memory name,
        string memory symbol,
        uint8 decimals
    ) {
        _name = name;
        _symbol = symbol;
        _decimals = decimals;
    }

    /**
     * @return The name of the token
     **/
    function name() public view override returns (string memory) {
        return _name;
    }

    /**
     * @return The symbol of the token
     **/
    function symbol() public view override returns (string memory) {
        return _symbol;
    }

    /**
     * @return The decimals of the token
     **/
    function decimals() public view override returns (uint8) {
        return _decimals;
    }

    /**
     * @return The total supply of the token
     **/
    function totalSupply() public view virtual override returns (uint256) {
        return _totalSupply;
    }

    /**
     * @return The balance of the token
     **/
    function balanceOf(address account)
        public
        view
        virtual
        override
        returns (uint256)
    {
        return _balances[account];
    }

    /**
     * @return Abstract function implemented by the child aToken/debtToken.
     * Done this way in order to not break compatibility with previous versions of aTokens/debtTokens
     **/
    function _getIncentivesController()
        internal
        view
        virtual
        returns (IAaveIncentivesController);

    /**
     * @dev Executes a transfer of tokens from _msgSender() to recipient
     * @param recipient The recipient of the tokens
     * @param amount The amount of tokens being transferred
     * @return `true` if the transfer succeeds, `false` otherwise
     **/
    function transfer(address recipient, uint256 amount)
        public
        virtual
        override
        returns (bool)
    {
        _transfer(_msgSender(), recipient, amount);
        emit Transfer(_msgSender(), recipient, amount);
        return true;
    }

    /**
     * @dev Returns the allowance of spender on the tokens owned by owner
     * @param owner The owner of the tokens
     * @param spender The user allowed to spend the owner's tokens
     * @return The amount of owner's tokens spender is allowed to spend
     **/
    function allowance(address owner, address spender)
        public
        view
        virtual
        override
        returns (uint256)
    {
        return _allowances[owner][spender];
    }

    /**
     * @dev Allows `spender` to spend the tokens owned by _msgSender()
     * @param spender The user allowed to spend _msgSender() tokens
     * @return `true`
     **/
    function approve(address spender, uint256 amount)
        public
        virtual
        override
        returns (bool)
    {
        _approve(_msgSender(), spender, amount);
        return true;
    }

    /**
     * @dev Executes a transfer of token from sender to recipient, if _msgSender() is allowed to do so
     * @param sender The owner of the tokens
     * @param recipient The recipient of the tokens
     * @param amount The amount of tokens being transferred
     * @return `true` if the transfer succeeds, `false` otherwise
     **/
    function transferFrom(
        address sender,
        address recipient,
        uint256 amount
    ) public virtual override returns (bool) {
        _transfer(sender, recipient, amount);
        _approve(
            sender,
            _msgSender(),
            _allowances[sender][_msgSender()].sub(
                amount,
                "ERC20: transfer amount exceeds allowance"
            )
        );
        emit Transfer(sender, recipient, amount);
        return true;
    }

    /**
     * @dev Increases the allowance of spender to spend _msgSender() tokens
     * @param spender The user allowed to spend on behalf of _msgSender()
     * @param addedValue The amount being added to the allowance
     * @return `true`
     **/
    function increaseAllowance(address spender, uint256 addedValue)
        public
        virtual
        returns (bool)
    {
        _approve(
            _msgSender(),
            spender,
            _allowances[_msgSender()][spender].add(addedValue)
        );
        return true;
    }

    /**
     * @dev Decreases the allowance of spender to spend _msgSender() tokens
     * @param spender The user allowed to spend on behalf of _msgSender()
     * @param subtractedValue The amount being subtracted to the allowance
     * @return `true`
     **/
    function decreaseAllowance(address spender, uint256 subtractedValue)
        public
        virtual
        returns (bool)
    {
        _approve(
            _msgSender(),
            spender,
            _allowances[_msgSender()][spender].sub(
                subtractedValue,
                "ERC20: decreased allowance below zero"
            )
        );
        return true;
    }

    function _transfer(
        address sender,
        address recipient,
        uint256 amount
    ) internal virtual {
        require(sender != address(0), "ERC20: transfer from the zero address");
        require(recipient != address(0), "ERC20: transfer to the zero address");

        _beforeTokenTransfer(sender, recipient, amount);

        uint256 oldSenderBalance = _balances[sender];
        _balances[sender] = oldSenderBalance.sub(
            amount,
            "ERC20: transfer amount exceeds balance"
        );
        uint256 oldRecipientBalance = _balances[recipient];
        _balances[recipient] = _balances[recipient].add(amount);

        if (address(_getIncentivesController()) != address(0)) {
            uint256 currentTotalSupply = _totalSupply;
            _getIncentivesController().handleAction(
                sender,
                currentTotalSupply,
                oldSenderBalance
            );
            if (sender != recipient) {
                _getIncentivesController().handleAction(
                    recipient,
                    currentTotalSupply,
                    oldRecipientBalance
                );
            }
        }
    }

    function _mint(address account, uint256 amount) internal virtual {
        require(account != address(0), "ERC20: mint to the zero address");

        _beforeTokenTransfer(address(0), account, amount);

        uint256 oldTotalSupply = _totalSupply;
        _totalSupply = oldTotalSupply.add(amount);

        uint256 oldAccountBalance = _balances[account];
        _balances[account] = oldAccountBalance.add(amount);

        if (address(_getIncentivesController()) != address(0)) {
            _getIncentivesController().handleAction(
                account,
                oldTotalSupply,
                oldAccountBalance
            );
        }
    }

    function _burn(address account, uint256 amount) internal virtual {
        require(account != address(0), "ERC20: burn from the zero address");

        _beforeTokenTransfer(account, address(0), amount);

        uint256 oldTotalSupply = _totalSupply;
        _totalSupply = oldTotalSupply.sub(amount);

        uint256 oldAccountBalance = _balances[account];
        _balances[account] = oldAccountBalance.sub(
            amount,
            "ERC20: burn amount exceeds balance"
        );

        if (address(_getIncentivesController()) != address(0)) {
            _getIncentivesController().handleAction(
                account,
                oldTotalSupply,
                oldAccountBalance
            );
        }
    }

    function _approve(
        address owner,
        address spender,
        uint256 amount
    ) internal virtual {
        require(owner != address(0), "ERC20: approve from the zero address");
        require(spender != address(0), "ERC20: approve to the zero address");

        _allowances[owner][spender] = amount;
        emit Approval(owner, spender, amount);
    }

    function _setName(string memory newName) internal {
        _name = newName;
    }

    function _setSymbol(string memory newSymbol) internal {
        _symbol = newSymbol;
    }

    function _setDecimals(uint8 newDecimals) internal {
        _decimals = newDecimals;
    }

    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 amount
    ) internal virtual {}
}

// SPDX-License-Identifier: agpl-3.0
pragma solidity >=0.8.0;

import {DebtTokenBase} from "./base/DebtTokenBase.sol";
import {MathUtils} from "../libraries/math/MathUtils.sol";
import {WadRayMath} from "../libraries/math/WadRayMath.sol";
import {IStableDebtToken} from "../../interfaces/IStableDebtToken.sol";
import {ILendingPool} from "../../interfaces/ILendingPool.sol";
import {IAaveIncentivesController} from "../../interfaces/IAaveIncentivesController.sol";
import {Errors} from "../libraries/helpers/Errors.sol";
import {SafeMath} from "../../dependencies/openzeppelin/contracts/SafeMath.sol";

/**
 * @title StableDebtToken
 * @notice Implements a stable debt token to track the borrowing positions of users
 * at stable rate mode
 * @author Aave
 **/
contract StableDebtToken is IStableDebtToken, DebtTokenBase {
    using WadRayMath for uint256;
    using SafeMath for uint256;

    uint256 public constant DEBT_TOKEN_REVISION = 0x1;

    uint256 internal _avgStableRate;
    mapping(address => uint40) internal _timestamps;
    mapping(address => uint256) internal _usersStableRate;
    uint40 internal _totalSupplyTimestamp;

    ILendingPool internal _pool;
    address internal _underlyingAsset;
    IAaveIncentivesController internal _incentivesController;

    /**
     * @dev Initializes the debt token.
     * @param pool The address of the lending pool where this aToken will be used
     * @param underlyingAsset The address of the underlying asset of this aToken (E.g. WETH for aWETH)
     * @param incentivesController The smart contract managing potential incentives distribution
     * @param debtTokenDecimals The decimals of the debtToken, same as the underlying asset's
     * @param debtTokenName The name of the token
     * @param debtTokenSymbol The symbol of the token
     */
    function initialize(
        ILendingPool pool,
        address underlyingAsset,
        uint64 trancheId,
        IAaveIncentivesController incentivesController,
        uint8 debtTokenDecimals,
        string memory debtTokenName,
        string memory debtTokenSymbol
    ) public override initializer {
        _setName(debtTokenName);
        _setSymbol(debtTokenSymbol);
        _setDecimals(debtTokenDecimals);

        _pool = pool;
        _underlyingAsset = underlyingAsset;
        _incentivesController = incentivesController;

        emit Initialized(
            underlyingAsset,
            trancheId,
            address(pool),
            address(incentivesController),
            debtTokenDecimals,
            debtTokenName,
            debtTokenSymbol
        );
    }

    /**
     * @dev Gets the revision of the stable debt token implementation
     * @return The debt token implementation revision
     **/
    function getRevision() internal pure virtual override returns (uint256) {
        return DEBT_TOKEN_REVISION;
    }

    /**
     * @dev Returns the average stable rate across all the stable rate debt
     * @return the average stable rate
     **/
    function getAverageStableRate()
        external
        view
        virtual
        override
        returns (uint256)
    {
        return _avgStableRate;
    }

    /**
     * @dev Returns the timestamp of the last user action
     * @return The last update timestamp
     **/
    function getUserLastUpdated(address user)
        external
        view
        virtual
        override
        returns (uint40)
    {
        return _timestamps[user];
    }

    /**
     * @dev Returns the stable rate of the user
     * @param user The address of the user
     * @return The stable rate of user
     **/
    function getUserStableRate(address user)
        external
        view
        virtual
        override
        returns (uint256)
    {
        return _usersStableRate[user];
    }

    /**
     * @dev Calculates the current user debt balance
     * @return The accumulated debt of the user
     **/
    function balanceOf(address account)
        public
        view
        virtual
        override
        returns (uint256)
    {
        uint256 accountBalance = super.balanceOf(account);
        uint256 stableRate = _usersStableRate[account];
        if (accountBalance == 0) {
            return 0;
        }
        uint256 cumulatedInterest = MathUtils.calculateCompoundedInterest(
            stableRate,
            _timestamps[account]
        );
        return accountBalance.rayMul(cumulatedInterest);
    }

    struct MintLocalVars {
        uint256 previousSupply;
        uint256 nextSupply;
        uint256 amountInRay;
        uint256 newStableRate;
        uint256 currentAvgStableRate;
    }

    /**
     * @dev Mints debt token to the `onBehalfOf` address.
     * -  Only callable by the LendingPool
     * - The resulting rate is the weighted average between the rate of the new debt
     * and the rate of the previous debt
     * @param user The address receiving the borrowed underlying, being the delegatee in case
     * of credit delegate, or same as `onBehalfOf` otherwise
     * @param onBehalfOf The address receiving the debt tokens
     * @param amount The amount of debt tokens to mint
     * @param rate The rate of the debt being minted
     **/
    function mint(
        address user,
        address onBehalfOf,
        uint256 amount,
        uint256 rate
    ) external override onlyLendingPool returns (bool) {
        MintLocalVars memory vars;

        if (user != onBehalfOf) {
            _decreaseBorrowAllowance(onBehalfOf, user, amount);
        }

        (
            ,
            uint256 currentBalance,
            uint256 balanceIncrease
        ) = _calculateBalanceIncrease(onBehalfOf);

        vars.previousSupply = totalSupply();
        vars.currentAvgStableRate = _avgStableRate;
        vars.nextSupply = _totalSupply = vars.previousSupply.add(amount);

        vars.amountInRay = amount.wadToRay();

        vars.newStableRate = _usersStableRate[onBehalfOf]
            .rayMul(currentBalance.wadToRay())
            .add(vars.amountInRay.rayMul(rate))
            .rayDiv(currentBalance.add(amount).wadToRay());

        require(
            vars.newStableRate <= type(uint128).max,
            Errors.SDT_STABLE_DEBT_OVERFLOW
        );
        _usersStableRate[onBehalfOf] = vars.newStableRate;

        //solium-disable-next-line
        _totalSupplyTimestamp = _timestamps[onBehalfOf] = uint40(
            block.timestamp
        );

        // Calculates the updated average stable rate
        vars.currentAvgStableRate = _avgStableRate = vars
            .currentAvgStableRate
            .rayMul(vars.previousSupply.wadToRay())
            .add(rate.rayMul(vars.amountInRay))
            .rayDiv(vars.nextSupply.wadToRay());

        _mint(onBehalfOf, amount.add(balanceIncrease), vars.previousSupply);

        emit Transfer(address(0), onBehalfOf, amount);

        emit Mint(
            user,
            onBehalfOf,
            amount,
            currentBalance,
            balanceIncrease,
            vars.newStableRate,
            vars.currentAvgStableRate,
            vars.nextSupply
        );

        return currentBalance == 0;
    }

    /**
     * @dev Burns debt of `user`
     * @param user The address of the user getting his debt burned
     * @param amount The amount of debt tokens getting burned
     **/
    function burn(address user, uint256 amount)
        external
        override
        onlyLendingPool
    {
        (
            ,
            uint256 currentBalance,
            uint256 balanceIncrease
        ) = _calculateBalanceIncrease(user);

        uint256 previousSupply = totalSupply();
        uint256 newAvgStableRate = 0;
        uint256 nextSupply = 0;
        uint256 userStableRate = _usersStableRate[user];

        // Since the total supply and each single user debt accrue separately,
        // there might be accumulation errors so that the last borrower repaying
        // mght actually try to repay more than the available debt supply.
        // In this case we simply set the total supply and the avg stable rate to 0
        if (previousSupply <= amount) {
            _avgStableRate = 0;
            _totalSupply = 0;
        } else {
            nextSupply = _totalSupply = previousSupply.sub(amount);
            uint256 firstTerm = _avgStableRate.rayMul(
                previousSupply.wadToRay()
            );
            uint256 secondTerm = userStableRate.rayMul(amount.wadToRay());

            // For the same reason described above, when the last user is repaying it might
            // happen that user rate * user balance > avg rate * total supply. In that case,
            // we simply set the avg rate to 0
            if (secondTerm >= firstTerm) {
                newAvgStableRate = _avgStableRate = _totalSupply = 0;
            } else {
                newAvgStableRate = _avgStableRate = firstTerm
                    .sub(secondTerm)
                    .rayDiv(nextSupply.wadToRay());
            }
        }

        if (amount == currentBalance) {
            _usersStableRate[user] = 0;
            _timestamps[user] = 0;
        } else {
            //solium-disable-next-line
            _timestamps[user] = uint40(block.timestamp);
        }
        //solium-disable-next-line
        _totalSupplyTimestamp = uint40(block.timestamp);

        if (balanceIncrease > amount) {
            uint256 amountToMint = balanceIncrease.sub(amount);
            _mint(user, amountToMint, previousSupply);
            emit Mint(
                user,
                user,
                amountToMint,
                currentBalance,
                balanceIncrease,
                userStableRate,
                newAvgStableRate,
                nextSupply
            );
        } else {
            uint256 amountToBurn = amount.sub(balanceIncrease);
            _burn(user, amountToBurn, previousSupply);
            emit Burn(
                user,
                amountToBurn,
                currentBalance,
                balanceIncrease,
                newAvgStableRate,
                nextSupply
            );
        }

        emit Transfer(user, address(0), amount);
    }

    /**
     * @dev Calculates the increase in balance since the last user interaction
     * @param user The address of the user for which the interest is being accumulated
     * @return The previous principal balance, the new principal balance and the balance increase
     **/
    function _calculateBalanceIncrease(address user)
        internal
        view
        returns (
            uint256,
            uint256,
            uint256
        )
    {
        uint256 previousPrincipalBalance = super.balanceOf(user);

        if (previousPrincipalBalance == 0) {
            return (0, 0, 0);
        }

        // Calculation of the accrued interest since the last accumulation
        uint256 balanceIncrease = balanceOf(user).sub(previousPrincipalBalance);

        return (
            previousPrincipalBalance,
            previousPrincipalBalance.add(balanceIncrease),
            balanceIncrease
        );
    }

    /**
     * @dev Returns the principal and total supply, the average borrow rate and the last supply update timestamp
     **/
    function getSupplyData()
        public
        view
        override
        returns (
            uint256,
            uint256,
            uint256,
            uint40
        )
    {
        uint256 avgRate = _avgStableRate;
        return (
            super.totalSupply(),
            _calcTotalSupply(avgRate),
            avgRate,
            _totalSupplyTimestamp
        );
    }

    /**
     * @dev Returns the the total supply and the average stable rate
     **/
    function getTotalSupplyAndAvgRate()
        public
        view
        override
        returns (uint256, uint256)
    {
        uint256 avgRate = _avgStableRate;
        return (_calcTotalSupply(avgRate), avgRate);
    }

    /**
     * @dev Returns the total supply
     **/
    function totalSupply() public view override returns (uint256) {
        return _calcTotalSupply(_avgStableRate);
    }

    /**
     * @dev Returns the timestamp at which the total supply was updated
     **/
    function getTotalSupplyLastUpdated() public view override returns (uint40) {
        return _totalSupplyTimestamp;
    }

    /**
     * @dev Returns the principal debt balance of the user from
     * @param user The user's address
     * @return The debt balance of the user since the last burn/mint action
     **/
    function principalBalanceOf(address user)
        external
        view
        virtual
        override
        returns (uint256)
    {
        return super.balanceOf(user);
    }

    /**
     * @dev Returns the address of the underlying asset of this aToken (E.g. WETH for aWETH)
     **/
    function UNDERLYING_ASSET_ADDRESS() public view returns (address) {
        return _underlyingAsset;
    }

    /**
     * @dev Returns the address of the lending pool where this aToken is used
     **/
    function POOL() public view returns (ILendingPool) {
        return _pool;
    }

    /**
     * @dev Returns the address of the incentives controller contract
     **/
    function getIncentivesController()
        external
        view
        override
        returns (IAaveIncentivesController)
    {
        return _getIncentivesController();
    }

    /**
     * @dev For internal usage in the logic of the parent contracts
     **/
    function _getIncentivesController()
        internal
        view
        override
        returns (IAaveIncentivesController)
    {
        return _incentivesController;
    }

    /**
     * @dev For internal usage in the logic of the parent contracts
     **/
    function _getUnderlyingAssetAddress()
        internal
        view
        override
        returns (address)
    {
        return _underlyingAsset;
    }

    /**
     * @dev For internal usage in the logic of the parent contracts
     **/
    function _getLendingPool() internal view override returns (ILendingPool) {
        return _pool;
    }

    /**
     * @dev Calculates the total supply
     * @param avgRate The average rate at which the total supply increases
     * @return The debt balance of the user since the last burn/mint action
     **/
    function _calcTotalSupply(uint256 avgRate)
        internal
        view
        virtual
        returns (uint256)
    {
        uint256 principalSupply = super.totalSupply();

        if (principalSupply == 0) {
            return 0;
        }

        uint256 cumulatedInterest = MathUtils.calculateCompoundedInterest(
            avgRate,
            _totalSupplyTimestamp
        );

        return principalSupply.rayMul(cumulatedInterest);
    }

    /**
     * @dev Mints stable debt tokens to an user
     * @param account The account receiving the debt tokens
     * @param amount The amount being minted
     * @param oldTotalSupply the total supply before the minting event
     **/
    function _mint(
        address account,
        uint256 amount,
        uint256 oldTotalSupply
    ) internal {
        uint256 oldAccountBalance = _balances[account];
        _balances[account] = oldAccountBalance.add(amount);

        if (address(_incentivesController) != address(0)) {
            _incentivesController.handleAction(
                account,
                oldTotalSupply,
                oldAccountBalance
            );
        }
    }

    /**
     * @dev Burns stable debt tokens of an user
     * @param account The user getting his debt burned
     * @param amount The amount being burned
     * @param oldTotalSupply The total supply before the burning event
     **/
    function _burn(
        address account,
        uint256 amount,
        uint256 oldTotalSupply
    ) internal {
        uint256 oldAccountBalance = _balances[account];
        _balances[account] = oldAccountBalance.sub(
            amount,
            Errors.SDT_BURN_EXCEEDS_BALANCE
        );

        if (address(_incentivesController) != address(0)) {
            _incentivesController.handleAction(
                account,
                oldTotalSupply,
                oldAccountBalance
            );
        }
    }
}

// SPDX-License-Identifier: agpl-3.0
pragma solidity >=0.8.0;

import {IVariableDebtToken} from "../../interfaces/IVariableDebtToken.sol";
import {WadRayMath} from "../libraries/math/WadRayMath.sol";
import {Errors} from "../libraries/helpers/Errors.sol";
import {DebtTokenBase} from "./base/DebtTokenBase.sol";
import {ILendingPool} from "../../interfaces/ILendingPool.sol";
import {IAaveIncentivesController} from "../../interfaces/IAaveIncentivesController.sol";

/**
 * @title VariableDebtToken
 * @notice Implements a variable debt token to track the borrowing positions of users
 * at variable rate mode
 * @author Aave
 **/
contract VariableDebtToken is DebtTokenBase, IVariableDebtToken {
    using WadRayMath for uint256;

    uint256 public constant DEBT_TOKEN_REVISION = 0x1;

    ILendingPool internal _pool;
    address internal _underlyingAsset;
    uint64 _tranche;
    IAaveIncentivesController internal _incentivesController;

    /**
     * @dev Initializes the debt token.
     * @param pool The address of the lending pool where this aToken will be used
     * @param underlyingAsset The address of the underlying asset of this aToken (E.g. WETH for aWETH)
     * @param incentivesController The smart contract managing potential incentives distribution
     * @param debtTokenDecimals The decimals of the debtToken, same as the underlying asset's
     * @param debtTokenName The name of the token
     * @param debtTokenSymbol The symbol of the token
     */
    function initialize(
        ILendingPool pool,
        address underlyingAsset,
        uint64 trancheId,
        IAaveIncentivesController incentivesController,
        uint8 debtTokenDecimals,
        string memory debtTokenName,
        string memory debtTokenSymbol
    ) public override initializer {
        _setName(debtTokenName);
        _setSymbol(debtTokenSymbol);
        _setDecimals(debtTokenDecimals);

        _pool = pool;
        _underlyingAsset = underlyingAsset;
        _tranche = trancheId;
        _incentivesController = incentivesController;

        emit Initialized(
            underlyingAsset,
            trancheId,
            address(pool),
            address(incentivesController),
            debtTokenDecimals,
            debtTokenName,
            debtTokenSymbol
        );
    }

    /**
     * @dev Gets the revision of the stable debt token implementation
     * @return The debt token implementation revision
     **/
    function getRevision() internal pure virtual override returns (uint256) {
        return DEBT_TOKEN_REVISION;
    }

    /**
     * @dev Calculates the accumulated debt balance of the user
     * @return The debt balance of the user
     **/
    function balanceOf(address user)
        public
        view
        virtual
        override
        returns (uint256)
    {
        uint256 scaledBalance = super.balanceOf(user);

        if (scaledBalance == 0) {
            return 0;
        }

        return
            scaledBalance.rayMul(
                _pool.getReserveNormalizedVariableDebt(
                    _underlyingAsset,
                    _tranche
                )
            );
    }

    /**
     * @dev Mints debt token to the `onBehalfOf` address
     * -  Only callable by the LendingPool
     * @param user The address receiving the borrowed underlying, being the delegatee in case
     * of credit delegate, or same as `onBehalfOf` otherwise
     * @param onBehalfOf The address receiving the debt tokens
     * @param amount The amount of debt being minted
     * @param index The variable debt index of the reserve
     * @return `true` if the the previous balance of the user is 0
     **/
    function mint(
        address user,
        address onBehalfOf,
        uint256 amount,
        uint256 index
    ) external override onlyLendingPool returns (bool) {
        if (user != onBehalfOf) {
            _decreaseBorrowAllowance(onBehalfOf, user, amount);
        }

        uint256 previousBalance = super.balanceOf(onBehalfOf);
        uint256 amountScaled = amount.rayDiv(index);
        require(amountScaled != 0, Errors.CT_INVALID_MINT_AMOUNT);

        _mint(onBehalfOf, amountScaled);

        emit Transfer(address(0), onBehalfOf, amount);
        emit Mint(user, onBehalfOf, amount, index);

        return previousBalance == 0;
    }

    /**
     * @dev Burns user variable debt
     * - Only callable by the LendingPool
     * @param user The user whose debt is getting burned
     * @param amount The amount getting burned
     * @param index The variable debt index of the reserve
     **/
    function burn(
        address user,
        uint256 amount,
        uint256 index
    ) external override onlyLendingPool {
        uint256 amountScaled = amount.rayDiv(index);
        require(amountScaled != 0, Errors.CT_INVALID_BURN_AMOUNT);

        _burn(user, amountScaled);

        emit Transfer(user, address(0), amount);
        emit Burn(user, amount, index);
    }

    /**
     * @dev Returns the principal debt balance of the user from
     * @return The debt balance of the user since the last burn/mint action
     **/
    function scaledBalanceOf(address user)
        public
        view
        virtual
        override
        returns (uint256)
    {
        return super.balanceOf(user);
    }

    /**
     * @dev Returns the total supply of the variable debt token. Represents the total debt accrued by the users
     * @return The total supply
     **/
    function totalSupply() public view virtual override returns (uint256) {
        return
            super.totalSupply().rayMul(
                _pool.getReserveNormalizedVariableDebt(
                    _underlyingAsset,
                    _tranche
                )
            );
    }

    /**
     * @dev Returns the scaled total supply of the variable debt token. Represents sum(debt/index)
     * @return the scaled total supply
     **/
    function scaledTotalSupply()
        public
        view
        virtual
        override
        returns (uint256)
    {
        return super.totalSupply();
    }

    /**
     * @dev Returns the principal balance of the user and principal total supply.
     * @param user The address of the user
     * @return The principal balance of the user
     * @return The principal total supply
     **/
    function getScaledUserBalanceAndSupply(address user)
        external
        view
        override
        returns (uint256, uint256)
    {
        return (super.balanceOf(user), super.totalSupply());
    }

    /**
     * @dev Returns the address of the underlying asset of this aToken (E.g. WETH for aWETH)
     **/
    function UNDERLYING_ASSET_ADDRESS() public view returns (address) {
        return _underlyingAsset;
    }

    /**
     * @dev Returns the address of the incentives controller contract
     **/
    function getIncentivesController()
        external
        view
        override
        returns (IAaveIncentivesController)
    {
        return _getIncentivesController();
    }

    /**
     * @dev Returns the address of the lending pool where this aToken is used
     **/
    function POOL() public view returns (ILendingPool) {
        return _pool;
    }

    function _getIncentivesController()
        internal
        view
        override
        returns (IAaveIncentivesController)
    {
        return _incentivesController;
    }

    function _getUnderlyingAssetAddress()
        internal
        view
        override
        returns (address)
    {
        return _underlyingAsset;
    }

    function _getLendingPool() internal view override returns (ILendingPool) {
        return _pool;
    }
}

// SPDX-License-Identifier: MIT
pragma solidity >= 0.4.22 <0.9.0;

library console {
	address constant CONSOLE_ADDRESS = address(0x000000000000000000636F6e736F6c652e6c6f67);

	function _sendLogPayload(bytes memory payload) private view {
		uint256 payloadLength = payload.length;
		address consoleAddress = CONSOLE_ADDRESS;
		assembly {
			let payloadStart := add(payload, 32)
			let r := staticcall(gas(), consoleAddress, payloadStart, payloadLength, 0, 0)
		}
	}

	function log() internal view {
		_sendLogPayload(abi.encodeWithSignature("log()"));
	}

	function logInt(int256 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(int256)", p0));
	}

	function logUint(uint256 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint256)", p0));
	}

	function logString(string memory p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string)", p0));
	}

	function logBool(bool p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool)", p0));
	}

	function logAddress(address p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address)", p0));
	}

	function logBytes(bytes memory p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes)", p0));
	}

	function logBytes1(bytes1 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes1)", p0));
	}

	function logBytes2(bytes2 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes2)", p0));
	}

	function logBytes3(bytes3 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes3)", p0));
	}

	function logBytes4(bytes4 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes4)", p0));
	}

	function logBytes5(bytes5 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes5)", p0));
	}

	function logBytes6(bytes6 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes6)", p0));
	}

	function logBytes7(bytes7 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes7)", p0));
	}

	function logBytes8(bytes8 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes8)", p0));
	}

	function logBytes9(bytes9 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes9)", p0));
	}

	function logBytes10(bytes10 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes10)", p0));
	}

	function logBytes11(bytes11 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes11)", p0));
	}

	function logBytes12(bytes12 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes12)", p0));
	}

	function logBytes13(bytes13 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes13)", p0));
	}

	function logBytes14(bytes14 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes14)", p0));
	}

	function logBytes15(bytes15 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes15)", p0));
	}

	function logBytes16(bytes16 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes16)", p0));
	}

	function logBytes17(bytes17 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes17)", p0));
	}

	function logBytes18(bytes18 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes18)", p0));
	}

	function logBytes19(bytes19 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes19)", p0));
	}

	function logBytes20(bytes20 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes20)", p0));
	}

	function logBytes21(bytes21 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes21)", p0));
	}

	function logBytes22(bytes22 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes22)", p0));
	}

	function logBytes23(bytes23 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes23)", p0));
	}

	function logBytes24(bytes24 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes24)", p0));
	}

	function logBytes25(bytes25 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes25)", p0));
	}

	function logBytes26(bytes26 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes26)", p0));
	}

	function logBytes27(bytes27 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes27)", p0));
	}

	function logBytes28(bytes28 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes28)", p0));
	}

	function logBytes29(bytes29 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes29)", p0));
	}

	function logBytes30(bytes30 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes30)", p0));
	}

	function logBytes31(bytes31 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes31)", p0));
	}

	function logBytes32(bytes32 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes32)", p0));
	}

	function log(uint256 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint256)", p0));
	}

	function log(string memory p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string)", p0));
	}

	function log(bool p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool)", p0));
	}

	function log(address p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address)", p0));
	}

	function log(uint256 p0, uint256 p1) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint256,uint256)", p0, p1));
	}

	function log(uint256 p0, string memory p1) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint256,string)", p0, p1));
	}

	function log(uint256 p0, bool p1) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint256,bool)", p0, p1));
	}

	function log(uint256 p0, address p1) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint256,address)", p0, p1));
	}

	function log(string memory p0, uint256 p1) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,uint256)", p0, p1));
	}

	function log(string memory p0, string memory p1) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,string)", p0, p1));
	}

	function log(string memory p0, bool p1) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,bool)", p0, p1));
	}

	function log(string memory p0, address p1) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,address)", p0, p1));
	}

	function log(bool p0, uint256 p1) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,uint256)", p0, p1));
	}

	function log(bool p0, string memory p1) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,string)", p0, p1));
	}

	function log(bool p0, bool p1) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,bool)", p0, p1));
	}

	function log(bool p0, address p1) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,address)", p0, p1));
	}

	function log(address p0, uint256 p1) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,uint256)", p0, p1));
	}

	function log(address p0, string memory p1) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,string)", p0, p1));
	}

	function log(address p0, bool p1) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,bool)", p0, p1));
	}

	function log(address p0, address p1) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,address)", p0, p1));
	}

	function log(uint256 p0, uint256 p1, uint256 p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint256,uint256,uint256)", p0, p1, p2));
	}

	function log(uint256 p0, uint256 p1, string memory p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint256,uint256,string)", p0, p1, p2));
	}

	function log(uint256 p0, uint256 p1, bool p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint256,uint256,bool)", p0, p1, p2));
	}

	function log(uint256 p0, uint256 p1, address p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint256,uint256,address)", p0, p1, p2));
	}

	function log(uint256 p0, string memory p1, uint256 p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint256,string,uint256)", p0, p1, p2));
	}

	function log(uint256 p0, string memory p1, string memory p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint256,string,string)", p0, p1, p2));
	}

	function log(uint256 p0, string memory p1, bool p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint256,string,bool)", p0, p1, p2));
	}

	function log(uint256 p0, string memory p1, address p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint256,string,address)", p0, p1, p2));
	}

	function log(uint256 p0, bool p1, uint256 p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint256,bool,uint256)", p0, p1, p2));
	}

	function log(uint256 p0, bool p1, string memory p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint256,bool,string)", p0, p1, p2));
	}

	function log(uint256 p0, bool p1, bool p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint256,bool,bool)", p0, p1, p2));
	}

	function log(uint256 p0, bool p1, address p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint256,bool,address)", p0, p1, p2));
	}

	function log(uint256 p0, address p1, uint256 p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint256,address,uint256)", p0, p1, p2));
	}

	function log(uint256 p0, address p1, string memory p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint256,address,string)", p0, p1, p2));
	}

	function log(uint256 p0, address p1, bool p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint256,address,bool)", p0, p1, p2));
	}

	function log(uint256 p0, address p1, address p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint256,address,address)", p0, p1, p2));
	}

	function log(string memory p0, uint256 p1, uint256 p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,uint256,uint256)", p0, p1, p2));
	}

	function log(string memory p0, uint256 p1, string memory p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,uint256,string)", p0, p1, p2));
	}

	function log(string memory p0, uint256 p1, bool p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,uint256,bool)", p0, p1, p2));
	}

	function log(string memory p0, uint256 p1, address p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,uint256,address)", p0, p1, p2));
	}

	function log(string memory p0, string memory p1, uint256 p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,string,uint256)", p0, p1, p2));
	}

	function log(string memory p0, string memory p1, string memory p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,string,string)", p0, p1, p2));
	}

	function log(string memory p0, string memory p1, bool p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,string,bool)", p0, p1, p2));
	}

	function log(string memory p0, string memory p1, address p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,string,address)", p0, p1, p2));
	}

	function log(string memory p0, bool p1, uint256 p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,bool,uint256)", p0, p1, p2));
	}

	function log(string memory p0, bool p1, string memory p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,bool,string)", p0, p1, p2));
	}

	function log(string memory p0, bool p1, bool p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,bool,bool)", p0, p1, p2));
	}

	function log(string memory p0, bool p1, address p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,bool,address)", p0, p1, p2));
	}

	function log(string memory p0, address p1, uint256 p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,address,uint256)", p0, p1, p2));
	}

	function log(string memory p0, address p1, string memory p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,address,string)", p0, p1, p2));
	}

	function log(string memory p0, address p1, bool p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,address,bool)", p0, p1, p2));
	}

	function log(string memory p0, address p1, address p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,address,address)", p0, p1, p2));
	}

	function log(bool p0, uint256 p1, uint256 p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,uint256,uint256)", p0, p1, p2));
	}

	function log(bool p0, uint256 p1, string memory p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,uint256,string)", p0, p1, p2));
	}

	function log(bool p0, uint256 p1, bool p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,uint256,bool)", p0, p1, p2));
	}

	function log(bool p0, uint256 p1, address p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,uint256,address)", p0, p1, p2));
	}

	function log(bool p0, string memory p1, uint256 p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,string,uint256)", p0, p1, p2));
	}

	function log(bool p0, string memory p1, string memory p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,string,string)", p0, p1, p2));
	}

	function log(bool p0, string memory p1, bool p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,string,bool)", p0, p1, p2));
	}

	function log(bool p0, string memory p1, address p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,string,address)", p0, p1, p2));
	}

	function log(bool p0, bool p1, uint256 p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,bool,uint256)", p0, p1, p2));
	}

	function log(bool p0, bool p1, string memory p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,bool,string)", p0, p1, p2));
	}

	function log(bool p0, bool p1, bool p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,bool,bool)", p0, p1, p2));
	}

	function log(bool p0, bool p1, address p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,bool,address)", p0, p1, p2));
	}

	function log(bool p0, address p1, uint256 p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,address,uint256)", p0, p1, p2));
	}

	function log(bool p0, address p1, string memory p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,address,string)", p0, p1, p2));
	}

	function log(bool p0, address p1, bool p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,address,bool)", p0, p1, p2));
	}

	function log(bool p0, address p1, address p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,address,address)", p0, p1, p2));
	}

	function log(address p0, uint256 p1, uint256 p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,uint256,uint256)", p0, p1, p2));
	}

	function log(address p0, uint256 p1, string memory p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,uint256,string)", p0, p1, p2));
	}

	function log(address p0, uint256 p1, bool p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,uint256,bool)", p0, p1, p2));
	}

	function log(address p0, uint256 p1, address p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,uint256,address)", p0, p1, p2));
	}

	function log(address p0, string memory p1, uint256 p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,string,uint256)", p0, p1, p2));
	}

	function log(address p0, string memory p1, string memory p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,string,string)", p0, p1, p2));
	}

	function log(address p0, string memory p1, bool p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,string,bool)", p0, p1, p2));
	}

	function log(address p0, string memory p1, address p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,string,address)", p0, p1, p2));
	}

	function log(address p0, bool p1, uint256 p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,bool,uint256)", p0, p1, p2));
	}

	function log(address p0, bool p1, string memory p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,bool,string)", p0, p1, p2));
	}

	function log(address p0, bool p1, bool p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,bool,bool)", p0, p1, p2));
	}

	function log(address p0, bool p1, address p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,bool,address)", p0, p1, p2));
	}

	function log(address p0, address p1, uint256 p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,address,uint256)", p0, p1, p2));
	}

	function log(address p0, address p1, string memory p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,address,string)", p0, p1, p2));
	}

	function log(address p0, address p1, bool p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,address,bool)", p0, p1, p2));
	}

	function log(address p0, address p1, address p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,address,address)", p0, p1, p2));
	}

	function log(uint256 p0, uint256 p1, uint256 p2, uint256 p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint256,uint256,uint256,uint256)", p0, p1, p2, p3));
	}

	function log(uint256 p0, uint256 p1, uint256 p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint256,uint256,uint256,string)", p0, p1, p2, p3));
	}

	function log(uint256 p0, uint256 p1, uint256 p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint256,uint256,uint256,bool)", p0, p1, p2, p3));
	}

	function log(uint256 p0, uint256 p1, uint256 p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint256,uint256,uint256,address)", p0, p1, p2, p3));
	}

	function log(uint256 p0, uint256 p1, string memory p2, uint256 p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint256,uint256,string,uint256)", p0, p1, p2, p3));
	}

	function log(uint256 p0, uint256 p1, string memory p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint256,uint256,string,string)", p0, p1, p2, p3));
	}

	function log(uint256 p0, uint256 p1, string memory p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint256,uint256,string,bool)", p0, p1, p2, p3));
	}

	function log(uint256 p0, uint256 p1, string memory p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint256,uint256,string,address)", p0, p1, p2, p3));
	}

	function log(uint256 p0, uint256 p1, bool p2, uint256 p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint256,uint256,bool,uint256)", p0, p1, p2, p3));
	}

	function log(uint256 p0, uint256 p1, bool p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint256,uint256,bool,string)", p0, p1, p2, p3));
	}

	function log(uint256 p0, uint256 p1, bool p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint256,uint256,bool,bool)", p0, p1, p2, p3));
	}

	function log(uint256 p0, uint256 p1, bool p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint256,uint256,bool,address)", p0, p1, p2, p3));
	}

	function log(uint256 p0, uint256 p1, address p2, uint256 p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint256,uint256,address,uint256)", p0, p1, p2, p3));
	}

	function log(uint256 p0, uint256 p1, address p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint256,uint256,address,string)", p0, p1, p2, p3));
	}

	function log(uint256 p0, uint256 p1, address p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint256,uint256,address,bool)", p0, p1, p2, p3));
	}

	function log(uint256 p0, uint256 p1, address p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint256,uint256,address,address)", p0, p1, p2, p3));
	}

	function log(uint256 p0, string memory p1, uint256 p2, uint256 p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint256,string,uint256,uint256)", p0, p1, p2, p3));
	}

	function log(uint256 p0, string memory p1, uint256 p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint256,string,uint256,string)", p0, p1, p2, p3));
	}

	function log(uint256 p0, string memory p1, uint256 p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint256,string,uint256,bool)", p0, p1, p2, p3));
	}

	function log(uint256 p0, string memory p1, uint256 p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint256,string,uint256,address)", p0, p1, p2, p3));
	}

	function log(uint256 p0, string memory p1, string memory p2, uint256 p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint256,string,string,uint256)", p0, p1, p2, p3));
	}

	function log(uint256 p0, string memory p1, string memory p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint256,string,string,string)", p0, p1, p2, p3));
	}

	function log(uint256 p0, string memory p1, string memory p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint256,string,string,bool)", p0, p1, p2, p3));
	}

	function log(uint256 p0, string memory p1, string memory p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint256,string,string,address)", p0, p1, p2, p3));
	}

	function log(uint256 p0, string memory p1, bool p2, uint256 p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint256,string,bool,uint256)", p0, p1, p2, p3));
	}

	function log(uint256 p0, string memory p1, bool p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint256,string,bool,string)", p0, p1, p2, p3));
	}

	function log(uint256 p0, string memory p1, bool p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint256,string,bool,bool)", p0, p1, p2, p3));
	}

	function log(uint256 p0, string memory p1, bool p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint256,string,bool,address)", p0, p1, p2, p3));
	}

	function log(uint256 p0, string memory p1, address p2, uint256 p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint256,string,address,uint256)", p0, p1, p2, p3));
	}

	function log(uint256 p0, string memory p1, address p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint256,string,address,string)", p0, p1, p2, p3));
	}

	function log(uint256 p0, string memory p1, address p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint256,string,address,bool)", p0, p1, p2, p3));
	}

	function log(uint256 p0, string memory p1, address p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint256,string,address,address)", p0, p1, p2, p3));
	}

	function log(uint256 p0, bool p1, uint256 p2, uint256 p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint256,bool,uint256,uint256)", p0, p1, p2, p3));
	}

	function log(uint256 p0, bool p1, uint256 p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint256,bool,uint256,string)", p0, p1, p2, p3));
	}

	function log(uint256 p0, bool p1, uint256 p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint256,bool,uint256,bool)", p0, p1, p2, p3));
	}

	function log(uint256 p0, bool p1, uint256 p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint256,bool,uint256,address)", p0, p1, p2, p3));
	}

	function log(uint256 p0, bool p1, string memory p2, uint256 p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint256,bool,string,uint256)", p0, p1, p2, p3));
	}

	function log(uint256 p0, bool p1, string memory p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint256,bool,string,string)", p0, p1, p2, p3));
	}

	function log(uint256 p0, bool p1, string memory p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint256,bool,string,bool)", p0, p1, p2, p3));
	}

	function log(uint256 p0, bool p1, string memory p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint256,bool,string,address)", p0, p1, p2, p3));
	}

	function log(uint256 p0, bool p1, bool p2, uint256 p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint256,bool,bool,uint256)", p0, p1, p2, p3));
	}

	function log(uint256 p0, bool p1, bool p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint256,bool,bool,string)", p0, p1, p2, p3));
	}

	function log(uint256 p0, bool p1, bool p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint256,bool,bool,bool)", p0, p1, p2, p3));
	}

	function log(uint256 p0, bool p1, bool p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint256,bool,bool,address)", p0, p1, p2, p3));
	}

	function log(uint256 p0, bool p1, address p2, uint256 p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint256,bool,address,uint256)", p0, p1, p2, p3));
	}

	function log(uint256 p0, bool p1, address p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint256,bool,address,string)", p0, p1, p2, p3));
	}

	function log(uint256 p0, bool p1, address p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint256,bool,address,bool)", p0, p1, p2, p3));
	}

	function log(uint256 p0, bool p1, address p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint256,bool,address,address)", p0, p1, p2, p3));
	}

	function log(uint256 p0, address p1, uint256 p2, uint256 p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint256,address,uint256,uint256)", p0, p1, p2, p3));
	}

	function log(uint256 p0, address p1, uint256 p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint256,address,uint256,string)", p0, p1, p2, p3));
	}

	function log(uint256 p0, address p1, uint256 p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint256,address,uint256,bool)", p0, p1, p2, p3));
	}

	function log(uint256 p0, address p1, uint256 p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint256,address,uint256,address)", p0, p1, p2, p3));
	}

	function log(uint256 p0, address p1, string memory p2, uint256 p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint256,address,string,uint256)", p0, p1, p2, p3));
	}

	function log(uint256 p0, address p1, string memory p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint256,address,string,string)", p0, p1, p2, p3));
	}

	function log(uint256 p0, address p1, string memory p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint256,address,string,bool)", p0, p1, p2, p3));
	}

	function log(uint256 p0, address p1, string memory p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint256,address,string,address)", p0, p1, p2, p3));
	}

	function log(uint256 p0, address p1, bool p2, uint256 p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint256,address,bool,uint256)", p0, p1, p2, p3));
	}

	function log(uint256 p0, address p1, bool p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint256,address,bool,string)", p0, p1, p2, p3));
	}

	function log(uint256 p0, address p1, bool p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint256,address,bool,bool)", p0, p1, p2, p3));
	}

	function log(uint256 p0, address p1, bool p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint256,address,bool,address)", p0, p1, p2, p3));
	}

	function log(uint256 p0, address p1, address p2, uint256 p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint256,address,address,uint256)", p0, p1, p2, p3));
	}

	function log(uint256 p0, address p1, address p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint256,address,address,string)", p0, p1, p2, p3));
	}

	function log(uint256 p0, address p1, address p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint256,address,address,bool)", p0, p1, p2, p3));
	}

	function log(uint256 p0, address p1, address p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint256,address,address,address)", p0, p1, p2, p3));
	}

	function log(string memory p0, uint256 p1, uint256 p2, uint256 p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,uint256,uint256,uint256)", p0, p1, p2, p3));
	}

	function log(string memory p0, uint256 p1, uint256 p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,uint256,uint256,string)", p0, p1, p2, p3));
	}

	function log(string memory p0, uint256 p1, uint256 p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,uint256,uint256,bool)", p0, p1, p2, p3));
	}

	function log(string memory p0, uint256 p1, uint256 p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,uint256,uint256,address)", p0, p1, p2, p3));
	}

	function log(string memory p0, uint256 p1, string memory p2, uint256 p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,uint256,string,uint256)", p0, p1, p2, p3));
	}

	function log(string memory p0, uint256 p1, string memory p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,uint256,string,string)", p0, p1, p2, p3));
	}

	function log(string memory p0, uint256 p1, string memory p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,uint256,string,bool)", p0, p1, p2, p3));
	}

	function log(string memory p0, uint256 p1, string memory p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,uint256,string,address)", p0, p1, p2, p3));
	}

	function log(string memory p0, uint256 p1, bool p2, uint256 p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,uint256,bool,uint256)", p0, p1, p2, p3));
	}

	function log(string memory p0, uint256 p1, bool p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,uint256,bool,string)", p0, p1, p2, p3));
	}

	function log(string memory p0, uint256 p1, bool p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,uint256,bool,bool)", p0, p1, p2, p3));
	}

	function log(string memory p0, uint256 p1, bool p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,uint256,bool,address)", p0, p1, p2, p3));
	}

	function log(string memory p0, uint256 p1, address p2, uint256 p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,uint256,address,uint256)", p0, p1, p2, p3));
	}

	function log(string memory p0, uint256 p1, address p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,uint256,address,string)", p0, p1, p2, p3));
	}

	function log(string memory p0, uint256 p1, address p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,uint256,address,bool)", p0, p1, p2, p3));
	}

	function log(string memory p0, uint256 p1, address p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,uint256,address,address)", p0, p1, p2, p3));
	}

	function log(string memory p0, string memory p1, uint256 p2, uint256 p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,string,uint256,uint256)", p0, p1, p2, p3));
	}

	function log(string memory p0, string memory p1, uint256 p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,string,uint256,string)", p0, p1, p2, p3));
	}

	function log(string memory p0, string memory p1, uint256 p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,string,uint256,bool)", p0, p1, p2, p3));
	}

	function log(string memory p0, string memory p1, uint256 p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,string,uint256,address)", p0, p1, p2, p3));
	}

	function log(string memory p0, string memory p1, string memory p2, uint256 p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,string,string,uint256)", p0, p1, p2, p3));
	}

	function log(string memory p0, string memory p1, string memory p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,string,string,string)", p0, p1, p2, p3));
	}

	function log(string memory p0, string memory p1, string memory p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,string,string,bool)", p0, p1, p2, p3));
	}

	function log(string memory p0, string memory p1, string memory p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,string,string,address)", p0, p1, p2, p3));
	}

	function log(string memory p0, string memory p1, bool p2, uint256 p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,string,bool,uint256)", p0, p1, p2, p3));
	}

	function log(string memory p0, string memory p1, bool p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,string,bool,string)", p0, p1, p2, p3));
	}

	function log(string memory p0, string memory p1, bool p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,string,bool,bool)", p0, p1, p2, p3));
	}

	function log(string memory p0, string memory p1, bool p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,string,bool,address)", p0, p1, p2, p3));
	}

	function log(string memory p0, string memory p1, address p2, uint256 p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,string,address,uint256)", p0, p1, p2, p3));
	}

	function log(string memory p0, string memory p1, address p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,string,address,string)", p0, p1, p2, p3));
	}

	function log(string memory p0, string memory p1, address p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,string,address,bool)", p0, p1, p2, p3));
	}

	function log(string memory p0, string memory p1, address p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,string,address,address)", p0, p1, p2, p3));
	}

	function log(string memory p0, bool p1, uint256 p2, uint256 p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,bool,uint256,uint256)", p0, p1, p2, p3));
	}

	function log(string memory p0, bool p1, uint256 p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,bool,uint256,string)", p0, p1, p2, p3));
	}

	function log(string memory p0, bool p1, uint256 p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,bool,uint256,bool)", p0, p1, p2, p3));
	}

	function log(string memory p0, bool p1, uint256 p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,bool,uint256,address)", p0, p1, p2, p3));
	}

	function log(string memory p0, bool p1, string memory p2, uint256 p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,bool,string,uint256)", p0, p1, p2, p3));
	}

	function log(string memory p0, bool p1, string memory p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,bool,string,string)", p0, p1, p2, p3));
	}

	function log(string memory p0, bool p1, string memory p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,bool,string,bool)", p0, p1, p2, p3));
	}

	function log(string memory p0, bool p1, string memory p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,bool,string,address)", p0, p1, p2, p3));
	}

	function log(string memory p0, bool p1, bool p2, uint256 p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,bool,bool,uint256)", p0, p1, p2, p3));
	}

	function log(string memory p0, bool p1, bool p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,bool,bool,string)", p0, p1, p2, p3));
	}

	function log(string memory p0, bool p1, bool p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,bool,bool,bool)", p0, p1, p2, p3));
	}

	function log(string memory p0, bool p1, bool p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,bool,bool,address)", p0, p1, p2, p3));
	}

	function log(string memory p0, bool p1, address p2, uint256 p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,bool,address,uint256)", p0, p1, p2, p3));
	}

	function log(string memory p0, bool p1, address p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,bool,address,string)", p0, p1, p2, p3));
	}

	function log(string memory p0, bool p1, address p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,bool,address,bool)", p0, p1, p2, p3));
	}

	function log(string memory p0, bool p1, address p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,bool,address,address)", p0, p1, p2, p3));
	}

	function log(string memory p0, address p1, uint256 p2, uint256 p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,address,uint256,uint256)", p0, p1, p2, p3));
	}

	function log(string memory p0, address p1, uint256 p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,address,uint256,string)", p0, p1, p2, p3));
	}

	function log(string memory p0, address p1, uint256 p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,address,uint256,bool)", p0, p1, p2, p3));
	}

	function log(string memory p0, address p1, uint256 p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,address,uint256,address)", p0, p1, p2, p3));
	}

	function log(string memory p0, address p1, string memory p2, uint256 p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,address,string,uint256)", p0, p1, p2, p3));
	}

	function log(string memory p0, address p1, string memory p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,address,string,string)", p0, p1, p2, p3));
	}

	function log(string memory p0, address p1, string memory p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,address,string,bool)", p0, p1, p2, p3));
	}

	function log(string memory p0, address p1, string memory p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,address,string,address)", p0, p1, p2, p3));
	}

	function log(string memory p0, address p1, bool p2, uint256 p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,address,bool,uint256)", p0, p1, p2, p3));
	}

	function log(string memory p0, address p1, bool p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,address,bool,string)", p0, p1, p2, p3));
	}

	function log(string memory p0, address p1, bool p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,address,bool,bool)", p0, p1, p2, p3));
	}

	function log(string memory p0, address p1, bool p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,address,bool,address)", p0, p1, p2, p3));
	}

	function log(string memory p0, address p1, address p2, uint256 p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,address,address,uint256)", p0, p1, p2, p3));
	}

	function log(string memory p0, address p1, address p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,address,address,string)", p0, p1, p2, p3));
	}

	function log(string memory p0, address p1, address p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,address,address,bool)", p0, p1, p2, p3));
	}

	function log(string memory p0, address p1, address p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,address,address,address)", p0, p1, p2, p3));
	}

	function log(bool p0, uint256 p1, uint256 p2, uint256 p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,uint256,uint256,uint256)", p0, p1, p2, p3));
	}

	function log(bool p0, uint256 p1, uint256 p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,uint256,uint256,string)", p0, p1, p2, p3));
	}

	function log(bool p0, uint256 p1, uint256 p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,uint256,uint256,bool)", p0, p1, p2, p3));
	}

	function log(bool p0, uint256 p1, uint256 p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,uint256,uint256,address)", p0, p1, p2, p3));
	}

	function log(bool p0, uint256 p1, string memory p2, uint256 p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,uint256,string,uint256)", p0, p1, p2, p3));
	}

	function log(bool p0, uint256 p1, string memory p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,uint256,string,string)", p0, p1, p2, p3));
	}

	function log(bool p0, uint256 p1, string memory p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,uint256,string,bool)", p0, p1, p2, p3));
	}

	function log(bool p0, uint256 p1, string memory p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,uint256,string,address)", p0, p1, p2, p3));
	}

	function log(bool p0, uint256 p1, bool p2, uint256 p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,uint256,bool,uint256)", p0, p1, p2, p3));
	}

	function log(bool p0, uint256 p1, bool p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,uint256,bool,string)", p0, p1, p2, p3));
	}

	function log(bool p0, uint256 p1, bool p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,uint256,bool,bool)", p0, p1, p2, p3));
	}

	function log(bool p0, uint256 p1, bool p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,uint256,bool,address)", p0, p1, p2, p3));
	}

	function log(bool p0, uint256 p1, address p2, uint256 p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,uint256,address,uint256)", p0, p1, p2, p3));
	}

	function log(bool p0, uint256 p1, address p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,uint256,address,string)", p0, p1, p2, p3));
	}

	function log(bool p0, uint256 p1, address p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,uint256,address,bool)", p0, p1, p2, p3));
	}

	function log(bool p0, uint256 p1, address p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,uint256,address,address)", p0, p1, p2, p3));
	}

	function log(bool p0, string memory p1, uint256 p2, uint256 p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,string,uint256,uint256)", p0, p1, p2, p3));
	}

	function log(bool p0, string memory p1, uint256 p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,string,uint256,string)", p0, p1, p2, p3));
	}

	function log(bool p0, string memory p1, uint256 p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,string,uint256,bool)", p0, p1, p2, p3));
	}

	function log(bool p0, string memory p1, uint256 p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,string,uint256,address)", p0, p1, p2, p3));
	}

	function log(bool p0, string memory p1, string memory p2, uint256 p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,string,string,uint256)", p0, p1, p2, p3));
	}

	function log(bool p0, string memory p1, string memory p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,string,string,string)", p0, p1, p2, p3));
	}

	function log(bool p0, string memory p1, string memory p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,string,string,bool)", p0, p1, p2, p3));
	}

	function log(bool p0, string memory p1, string memory p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,string,string,address)", p0, p1, p2, p3));
	}

	function log(bool p0, string memory p1, bool p2, uint256 p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,string,bool,uint256)", p0, p1, p2, p3));
	}

	function log(bool p0, string memory p1, bool p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,string,bool,string)", p0, p1, p2, p3));
	}

	function log(bool p0, string memory p1, bool p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,string,bool,bool)", p0, p1, p2, p3));
	}

	function log(bool p0, string memory p1, bool p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,string,bool,address)", p0, p1, p2, p3));
	}

	function log(bool p0, string memory p1, address p2, uint256 p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,string,address,uint256)", p0, p1, p2, p3));
	}

	function log(bool p0, string memory p1, address p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,string,address,string)", p0, p1, p2, p3));
	}

	function log(bool p0, string memory p1, address p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,string,address,bool)", p0, p1, p2, p3));
	}

	function log(bool p0, string memory p1, address p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,string,address,address)", p0, p1, p2, p3));
	}

	function log(bool p0, bool p1, uint256 p2, uint256 p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,bool,uint256,uint256)", p0, p1, p2, p3));
	}

	function log(bool p0, bool p1, uint256 p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,bool,uint256,string)", p0, p1, p2, p3));
	}

	function log(bool p0, bool p1, uint256 p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,bool,uint256,bool)", p0, p1, p2, p3));
	}

	function log(bool p0, bool p1, uint256 p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,bool,uint256,address)", p0, p1, p2, p3));
	}

	function log(bool p0, bool p1, string memory p2, uint256 p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,bool,string,uint256)", p0, p1, p2, p3));
	}

	function log(bool p0, bool p1, string memory p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,bool,string,string)", p0, p1, p2, p3));
	}

	function log(bool p0, bool p1, string memory p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,bool,string,bool)", p0, p1, p2, p3));
	}

	function log(bool p0, bool p1, string memory p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,bool,string,address)", p0, p1, p2, p3));
	}

	function log(bool p0, bool p1, bool p2, uint256 p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,bool,bool,uint256)", p0, p1, p2, p3));
	}

	function log(bool p0, bool p1, bool p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,bool,bool,string)", p0, p1, p2, p3));
	}

	function log(bool p0, bool p1, bool p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,bool,bool,bool)", p0, p1, p2, p3));
	}

	function log(bool p0, bool p1, bool p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,bool,bool,address)", p0, p1, p2, p3));
	}

	function log(bool p0, bool p1, address p2, uint256 p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,bool,address,uint256)", p0, p1, p2, p3));
	}

	function log(bool p0, bool p1, address p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,bool,address,string)", p0, p1, p2, p3));
	}

	function log(bool p0, bool p1, address p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,bool,address,bool)", p0, p1, p2, p3));
	}

	function log(bool p0, bool p1, address p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,bool,address,address)", p0, p1, p2, p3));
	}

	function log(bool p0, address p1, uint256 p2, uint256 p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,address,uint256,uint256)", p0, p1, p2, p3));
	}

	function log(bool p0, address p1, uint256 p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,address,uint256,string)", p0, p1, p2, p3));
	}

	function log(bool p0, address p1, uint256 p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,address,uint256,bool)", p0, p1, p2, p3));
	}

	function log(bool p0, address p1, uint256 p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,address,uint256,address)", p0, p1, p2, p3));
	}

	function log(bool p0, address p1, string memory p2, uint256 p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,address,string,uint256)", p0, p1, p2, p3));
	}

	function log(bool p0, address p1, string memory p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,address,string,string)", p0, p1, p2, p3));
	}

	function log(bool p0, address p1, string memory p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,address,string,bool)", p0, p1, p2, p3));
	}

	function log(bool p0, address p1, string memory p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,address,string,address)", p0, p1, p2, p3));
	}

	function log(bool p0, address p1, bool p2, uint256 p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,address,bool,uint256)", p0, p1, p2, p3));
	}

	function log(bool p0, address p1, bool p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,address,bool,string)", p0, p1, p2, p3));
	}

	function log(bool p0, address p1, bool p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,address,bool,bool)", p0, p1, p2, p3));
	}

	function log(bool p0, address p1, bool p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,address,bool,address)", p0, p1, p2, p3));
	}

	function log(bool p0, address p1, address p2, uint256 p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,address,address,uint256)", p0, p1, p2, p3));
	}

	function log(bool p0, address p1, address p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,address,address,string)", p0, p1, p2, p3));
	}

	function log(bool p0, address p1, address p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,address,address,bool)", p0, p1, p2, p3));
	}

	function log(bool p0, address p1, address p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,address,address,address)", p0, p1, p2, p3));
	}

	function log(address p0, uint256 p1, uint256 p2, uint256 p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,uint256,uint256,uint256)", p0, p1, p2, p3));
	}

	function log(address p0, uint256 p1, uint256 p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,uint256,uint256,string)", p0, p1, p2, p3));
	}

	function log(address p0, uint256 p1, uint256 p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,uint256,uint256,bool)", p0, p1, p2, p3));
	}

	function log(address p0, uint256 p1, uint256 p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,uint256,uint256,address)", p0, p1, p2, p3));
	}

	function log(address p0, uint256 p1, string memory p2, uint256 p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,uint256,string,uint256)", p0, p1, p2, p3));
	}

	function log(address p0, uint256 p1, string memory p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,uint256,string,string)", p0, p1, p2, p3));
	}

	function log(address p0, uint256 p1, string memory p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,uint256,string,bool)", p0, p1, p2, p3));
	}

	function log(address p0, uint256 p1, string memory p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,uint256,string,address)", p0, p1, p2, p3));
	}

	function log(address p0, uint256 p1, bool p2, uint256 p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,uint256,bool,uint256)", p0, p1, p2, p3));
	}

	function log(address p0, uint256 p1, bool p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,uint256,bool,string)", p0, p1, p2, p3));
	}

	function log(address p0, uint256 p1, bool p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,uint256,bool,bool)", p0, p1, p2, p3));
	}

	function log(address p0, uint256 p1, bool p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,uint256,bool,address)", p0, p1, p2, p3));
	}

	function log(address p0, uint256 p1, address p2, uint256 p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,uint256,address,uint256)", p0, p1, p2, p3));
	}

	function log(address p0, uint256 p1, address p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,uint256,address,string)", p0, p1, p2, p3));
	}

	function log(address p0, uint256 p1, address p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,uint256,address,bool)", p0, p1, p2, p3));
	}

	function log(address p0, uint256 p1, address p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,uint256,address,address)", p0, p1, p2, p3));
	}

	function log(address p0, string memory p1, uint256 p2, uint256 p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,string,uint256,uint256)", p0, p1, p2, p3));
	}

	function log(address p0, string memory p1, uint256 p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,string,uint256,string)", p0, p1, p2, p3));
	}

	function log(address p0, string memory p1, uint256 p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,string,uint256,bool)", p0, p1, p2, p3));
	}

	function log(address p0, string memory p1, uint256 p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,string,uint256,address)", p0, p1, p2, p3));
	}

	function log(address p0, string memory p1, string memory p2, uint256 p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,string,string,uint256)", p0, p1, p2, p3));
	}

	function log(address p0, string memory p1, string memory p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,string,string,string)", p0, p1, p2, p3));
	}

	function log(address p0, string memory p1, string memory p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,string,string,bool)", p0, p1, p2, p3));
	}

	function log(address p0, string memory p1, string memory p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,string,string,address)", p0, p1, p2, p3));
	}

	function log(address p0, string memory p1, bool p2, uint256 p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,string,bool,uint256)", p0, p1, p2, p3));
	}

	function log(address p0, string memory p1, bool p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,string,bool,string)", p0, p1, p2, p3));
	}

	function log(address p0, string memory p1, bool p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,string,bool,bool)", p0, p1, p2, p3));
	}

	function log(address p0, string memory p1, bool p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,string,bool,address)", p0, p1, p2, p3));
	}

	function log(address p0, string memory p1, address p2, uint256 p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,string,address,uint256)", p0, p1, p2, p3));
	}

	function log(address p0, string memory p1, address p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,string,address,string)", p0, p1, p2, p3));
	}

	function log(address p0, string memory p1, address p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,string,address,bool)", p0, p1, p2, p3));
	}

	function log(address p0, string memory p1, address p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,string,address,address)", p0, p1, p2, p3));
	}

	function log(address p0, bool p1, uint256 p2, uint256 p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,bool,uint256,uint256)", p0, p1, p2, p3));
	}

	function log(address p0, bool p1, uint256 p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,bool,uint256,string)", p0, p1, p2, p3));
	}

	function log(address p0, bool p1, uint256 p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,bool,uint256,bool)", p0, p1, p2, p3));
	}

	function log(address p0, bool p1, uint256 p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,bool,uint256,address)", p0, p1, p2, p3));
	}

	function log(address p0, bool p1, string memory p2, uint256 p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,bool,string,uint256)", p0, p1, p2, p3));
	}

	function log(address p0, bool p1, string memory p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,bool,string,string)", p0, p1, p2, p3));
	}

	function log(address p0, bool p1, string memory p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,bool,string,bool)", p0, p1, p2, p3));
	}

	function log(address p0, bool p1, string memory p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,bool,string,address)", p0, p1, p2, p3));
	}

	function log(address p0, bool p1, bool p2, uint256 p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,bool,bool,uint256)", p0, p1, p2, p3));
	}

	function log(address p0, bool p1, bool p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,bool,bool,string)", p0, p1, p2, p3));
	}

	function log(address p0, bool p1, bool p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,bool,bool,bool)", p0, p1, p2, p3));
	}

	function log(address p0, bool p1, bool p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,bool,bool,address)", p0, p1, p2, p3));
	}

	function log(address p0, bool p1, address p2, uint256 p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,bool,address,uint256)", p0, p1, p2, p3));
	}

	function log(address p0, bool p1, address p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,bool,address,string)", p0, p1, p2, p3));
	}

	function log(address p0, bool p1, address p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,bool,address,bool)", p0, p1, p2, p3));
	}

	function log(address p0, bool p1, address p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,bool,address,address)", p0, p1, p2, p3));
	}

	function log(address p0, address p1, uint256 p2, uint256 p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,address,uint256,uint256)", p0, p1, p2, p3));
	}

	function log(address p0, address p1, uint256 p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,address,uint256,string)", p0, p1, p2, p3));
	}

	function log(address p0, address p1, uint256 p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,address,uint256,bool)", p0, p1, p2, p3));
	}

	function log(address p0, address p1, uint256 p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,address,uint256,address)", p0, p1, p2, p3));
	}

	function log(address p0, address p1, string memory p2, uint256 p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,address,string,uint256)", p0, p1, p2, p3));
	}

	function log(address p0, address p1, string memory p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,address,string,string)", p0, p1, p2, p3));
	}

	function log(address p0, address p1, string memory p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,address,string,bool)", p0, p1, p2, p3));
	}

	function log(address p0, address p1, string memory p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,address,string,address)", p0, p1, p2, p3));
	}

	function log(address p0, address p1, bool p2, uint256 p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,address,bool,uint256)", p0, p1, p2, p3));
	}

	function log(address p0, address p1, bool p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,address,bool,string)", p0, p1, p2, p3));
	}

	function log(address p0, address p1, bool p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,address,bool,bool)", p0, p1, p2, p3));
	}

	function log(address p0, address p1, bool p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,address,bool,address)", p0, p1, p2, p3));
	}

	function log(address p0, address p1, address p2, uint256 p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,address,address,uint256)", p0, p1, p2, p3));
	}

	function log(address p0, address p1, address p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,address,address,string)", p0, p1, p2, p3));
	}

	function log(address p0, address p1, address p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,address,address,bool)", p0, p1, p2, p3));
	}

	function log(address p0, address p1, address p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,address,address,address)", p0, p1, p2, p3));
	}

}