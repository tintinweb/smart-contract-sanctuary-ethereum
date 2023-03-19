// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity ^0.8.0;

import "./IGridStructs.sol";
import "./IGridParameters.sol";

/// @title The interface for Gridex grid
interface IGrid {
    ///==================================== Grid States  ====================================

    /// @notice The first token in the grid, after sorting by address
    function token0() external view returns (address);

    /// @notice The second token in the grid, after sorting by address
    function token1() external view returns (address);

    /// @notice The step size in initialized boundaries for a grid created with a given fee
    function resolution() external view returns (int24);

    /// @notice The fee paid to the grid denominated in hundredths of a bip, i.e. 1e-6
    function takerFee() external view returns (int24);

    /// @notice The 0th slot of the grid holds a lot of values that can be gas-efficiently accessed
    /// externally as a single method
    /// @return priceX96 The current price of the grid, as a Q64.96
    /// @return boundary The current boundary of the grid
    /// @return blockTimestamp The time the oracle was last updated
    /// @return unlocked Whether the grid is unlocked or not
    function slot0() external view returns (uint160 priceX96, int24 boundary, uint32 blockTimestamp, bool unlocked);

    /// @notice Returns the boundary information of token0
    /// @param boundary The boundary of the grid
    /// @return bundle0Id The unique identifier of bundle0
    /// @return bundle1Id The unique identifier of bundle1
    /// @return makerAmountRemaining The remaining amount of token0 that can be swapped out,
    /// which is the sum of bundle0 and bundle1
    function boundaries0(
        int24 boundary
    ) external view returns (uint64 bundle0Id, uint64 bundle1Id, uint128 makerAmountRemaining);

    /// @notice Returns the boundary information of token1
    /// @param boundary The boundary of the grid
    /// @return bundle0Id The unique identifier of bundle0
    /// @return bundle1Id The unique identifier of bundle1
    /// @return makerAmountRemaining The remaining amount of token1 that can be swapped out,
    /// which is the sum of bundle0 and bundle1
    function boundaries1(
        int24 boundary
    ) external view returns (uint64 bundle0Id, uint64 bundle1Id, uint128 makerAmountRemaining);

    /// @notice Returns 256 packed boundary initialized boolean values for token0
    function boundaryBitmaps0(int16 wordPos) external view returns (uint256 word);

    /// @notice Returns 256 packed boundary initialized boolean values for token1
    function boundaryBitmaps1(int16 wordPos) external view returns (uint256 word);

    /// @notice Returns the amount owed for token0 and token1
    /// @param owner The address of owner
    /// @return token0 The amount of token0 owed
    /// @return token1 The amount of token1 owed
    function tokensOweds(address owner) external view returns (uint128 token0, uint128 token1);

    /// @notice Returns the information of a given bundle
    /// @param bundleId The unique identifier of the bundle
    /// @return boundaryLower The lower boundary of the bundle
    /// @return zero When zero is true, it represents token0, otherwise it represents token1
    /// @return makerAmountTotal The total amount of token0 or token1 that the maker added
    /// @return makerAmountRemaining The remaining amount of token0 or token1 that can be swapped out from the makers
    /// @return takerAmountRemaining The remaining amount of token0 or token1 that have been swapped in from the takers
    /// @return takerFeeAmountRemaining The remaining amount of fees that takers have paid in
    function bundles(
        uint64 bundleId
    )
        external
        view
        returns (
            int24 boundaryLower,
            bool zero,
            uint128 makerAmountTotal,
            uint128 makerAmountRemaining,
            uint128 takerAmountRemaining,
            uint128 takerFeeAmountRemaining
        );

    /// @notice Returns the information of a given order
    /// @param orderId The unique identifier of the order
    /// @return bundleId The unique identifier of the bundle -- represents which bundle this order belongs to
    /// @return owner The address of the owner of the order
    /// @return amount The amount of token0 or token1 to add
    function orders(uint256 orderId) external view returns (uint64 bundleId, address owner, uint128 amount);

    ///==================================== Grid Actions ====================================

    /// @notice Initializes the grid with the given parameters
    /// @dev The caller of this method receives a callback in the form of
    /// IGridPlaceMakerOrderCallback#gridexPlaceMakerOrderCallback.
    /// When initializing the grid, token0 and token1's liquidity must be added simultaneously.
    /// @param parameters The parameters used to initialize the grid
    /// @param data Any data to be passed through to the callback
    /// @return orderIds0 The unique identifiers of the orders for token0
    /// @return orderIds1 The unique identifiers of the orders for token1
    function initialize(
        IGridParameters.InitializeParameters memory parameters,
        bytes calldata data
    ) external returns (uint256[] memory orderIds0, uint256[] memory orderIds1);

    /// @notice Swaps token0 for token1, or vice versa
    /// @dev The caller of this method receives a callback in the form of IGridSwapCallback#gridexSwapCallback
    /// @param recipient The address to receive the output of the swap
    /// @param zeroForOne The swap direction, true for token0 to token1 and false otherwise
    /// @param amountSpecified The amount of the swap, configured as an exactInput (positive)
    /// or an exactOutput (negative)
    /// @param priceLimitX96 Swap price limit: if zeroForOne, the price will not be less than this value after swap,
    /// if oneForZero, it will not be greater than this value after swap, as a Q64.96
    /// @param data Any data to be passed through to the callback
    /// @return amount0 The balance change of the grid's token0. When negative, it will reduce the balance
    /// by the exact amount. When positive, it will increase by at least this amount
    /// @return amount1 The balance change of the grid's token1. When negative, it will reduce the balance
    /// by the exact amount. When positive, it will increase by at least this amount.
    function swap(
        address recipient,
        bool zeroForOne,
        int256 amountSpecified,
        uint160 priceLimitX96,
        bytes calldata data
    ) external returns (int256 amount0, int256 amount1);

    /// @notice Places a maker order on the grid
    /// @dev The caller of this method receives a callback in the form of
    /// IGridPlaceMakerOrderCallback#gridexPlaceMakerOrderCallback
    /// @param parameters The parameters used to place the maker order
    /// @param data Any data to be passed through to the callback
    /// @return orderId The unique identifier of the order
    function placeMakerOrder(
        IGridParameters.PlaceOrderParameters memory parameters,
        bytes calldata data
    ) external returns (uint256 orderId);

    /// @notice Places maker orders on the grid
    /// @dev The caller of this method receives a callback in the form of
    /// IGridPlaceMakerOrderCallback#gridexPlaceMakerOrderCallback
    /// @param parameters The parameters used to place the maker orders
    /// @param data Any data to be passed through to the callback
    /// @return orderIds The unique identifiers of the orders
    function placeMakerOrderInBatch(
        IGridParameters.PlaceOrderInBatchParameters memory parameters,
        bytes calldata data
    ) external returns (uint256[] memory orderIds);

    /// @notice Settles a maker order
    /// @param orderId The unique identifier of the order
    /// @return amount0 The amount of token0 that the maker received
    /// @return amount1 The amount of token1 that the maker received
    function settleMakerOrder(uint256 orderId) external returns (uint128 amount0, uint128 amount1);

    /// @notice Settle maker order and collect
    /// @param recipient The address to receive the output of the settlement
    /// @param orderId The unique identifier of the order
    /// @param unwrapWETH9 Whether to unwrap WETH9 to ETH
    /// @return amount0 The amount of token0 that the maker received
    /// @return amount1 The amount of token1 that the maker received
    function settleMakerOrderAndCollect(
        address recipient,
        uint256 orderId,
        bool unwrapWETH9
    ) external returns (uint128 amount0, uint128 amount1);

    /// @notice Settles maker orders and collects in a batch
    /// @param recipient The address to receive the output of the settlement
    /// @param orderIds The unique identifiers of the orders
    /// @param unwrapWETH9 Whether to unwrap WETH9 to ETH
    /// @return amount0Total The total amount of token0 that the maker received
    /// @return amount1Total The total amount of token1 that the maker received
    function settleMakerOrderAndCollectInBatch(
        address recipient,
        uint256[] memory orderIds,
        bool unwrapWETH9
    ) external returns (uint128 amount0Total, uint128 amount1Total);

    /// @notice For flash swaps. The caller borrows assets and returns them in the callback of the function,
    /// in addition to a fee
    /// @dev The caller of this function receives a callback in the form of IGridFlashCallback#gridexFlashCallback
    /// @param recipient The address which will receive the token0 and token1
    /// @param amount0 The amount of token0 to receive
    /// @param amount1 The amount of token1 to receive
    /// @param data Any data to be passed through to the callback
    function flash(address recipient, uint256 amount0, uint256 amount1, bytes calldata data) external;

    /// @notice Collects tokens owed
    /// @param recipient The address to receive the collected fees
    /// @param amount0Requested The maximum amount of token0 to send.
    /// Set to 0 if fees should only be collected in token1.
    /// @param amount1Requested The maximum amount of token1 to send.
    /// Set to 0 if fees should only be collected in token0.
    /// @return amount0 The amount of fees collected in token0
    /// @return amount1 The amount of fees collected in token1
    function collect(
        address recipient,
        uint128 amount0Requested,
        uint128 amount1Requested
    ) external returns (uint128 amount0, uint128 amount1);
}

// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity ^0.8.0;

import "./IGridStructs.sol";

/// @title Events emitted by the grid contract
interface IGridEvents {
    /// @notice Emitted exactly once by a grid when #initialize is first called on the grid
    /// @param priceX96 The initial price of the grid, as a Q64.96
    /// @param boundary The initial boundary of the grid
    event Initialize(uint160 priceX96, int24 boundary);

    /// @notice Emitted when the maker places an order to add liquidity for token0 or token1
    /// @param orderId The unique identifier of the order
    /// @param recipient The address that received the order
    /// @param bundleId The unique identifier of the bundle -- represents which bundle this order belongs to
    /// @param zero When zero is true, it represents token0, otherwise it represents token1
    /// @param boundaryLower The lower boundary of the order
    /// @param amount The amount of token0 or token1 to add
    event PlaceMakerOrder(
        uint256 indexed orderId,
        address indexed recipient,
        uint64 indexed bundleId,
        bool zero,
        int24 boundaryLower,
        uint128 amount
    );

    /// @notice Emitted when settling a single range order
    /// @param orderId The unique identifier of the order
    /// @param makerAmountOut The amount of token0 or token1 that the maker has removed
    /// @param takerAmountOut The amount of token0 or token1 that the taker has submitted
    /// @param takerFeeAmountOut The amount of token0 or token1 fees that the taker has paid
    event SettleMakerOrder(
        uint256 indexed orderId,
        uint128 makerAmountOut,
        uint128 takerAmountOut,
        uint128 takerFeeAmountOut
    );

    /// @notice Emitted when a maker settles an order
    /// @dev When either of the bundle's total maker amount or the remaining maker amount becomes 0,
    /// the bundle is closed
    /// @param bundleId The unique identifier of the bundle
    /// @param makerAmountTotal The change in the total maker amount in the bundle
    /// @param makerAmountRemaining The change in the remaining maker amount in the bundle
    event ChangeBundleForSettleOrder(uint64 indexed bundleId, int256 makerAmountTotal, int256 makerAmountRemaining);

    /// @notice Emitted when a taker is swapping
    /// @dev When the bundle's remaining maker amount becomes 0, the bundle is closed
    /// @param bundleId The unique identifier of the bundle
    /// @param makerAmountRemaining The change in the remaining maker amount in the bundle
    /// @param amountIn The change in the remaining taker amount in the bundle
    /// @param takerFeeAmountIn The change in the remaining taker fee amount in the bundle
    event ChangeBundleForSwap(
        uint64 indexed bundleId,
        int256 makerAmountRemaining,
        uint256 amountIn,
        uint128 takerFeeAmountIn
    );

    /// @notice Emitted by the grid for any swaps between token0 and token1
    /// @param sender The address that initiated the swap call, and that received the callback
    /// @param recipient The address that received the output of the swap
    /// @param amount0 The delta of the token0 balance of the grid
    /// @param amount1 The delta of the token1 balance of the grid
    /// @param priceX96 The price of the grid after the swap, as a Q64.96
    /// @param boundary The log base 1.0001 of the price of the grid after the swap
    event Swap(
        address indexed sender,
        address indexed recipient,
        int256 amount0,
        int256 amount1,
        uint160 priceX96,
        int24 boundary
    );

    /// @notice Emitted by the grid for any flashes of token0/token1
    /// @param sender The address that initiated the flash call, and that received the callback
    /// @param recipient The address that received the tokens from the flash
    /// @param amount0 The amount of token0 that was flashed
    /// @param amount1 The amount of token1 that was flashed
    /// @param paid0 The amount of token0 paid for the flash, which can exceed the amount0 plus the fee
    /// @param paid1 The amount of token1 paid for the flash, which can exceed the amount1 plus the fee
    event Flash(
        address indexed sender,
        address indexed recipient,
        uint256 amount0,
        uint256 amount1,
        uint128 paid0,
        uint128 paid1
    );

    /// @notice Emitted when the collected owed fees are withdrawn by the sender
    /// @param sender The address that collects the fees
    /// @param recipient The address that receives the fees
    /// @param amount0 The amount of token0 fees that is withdrawn
    /// @param amount1 The amount of token1 fees that is withdrawn
    event Collect(address indexed sender, address indexed recipient, uint128 amount0, uint128 amount1);
}

// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity ^0.8.0;

interface IGridParameters {
    /// @dev Parameters for initializing the grid
    struct InitializeParameters {
        /// @dev The initial price of the grid, as a Q64.96.
        /// Price is represented as an amountToken1/amountToken0 Q64.96 value.
        uint160 priceX96;
        /// @dev The address to receive orders
        address recipient;
        /// @dev Represents the order parameters for token0
        BoundaryLowerWithAmountParameters[] orders0;
        /// @dev Represents the order parameters for token1
        BoundaryLowerWithAmountParameters[] orders1;
    }

    /// @dev Parameters for placing an order
    struct PlaceOrderParameters {
        /// @dev The address to receive the order
        address recipient;
        /// @dev When zero is true, it represents token0, otherwise it represents token1
        bool zero;
        /// @dev The lower boundary of the order
        int24 boundaryLower;
        /// @dev The amount of token0 or token1 to add
        uint128 amount;
    }

    struct PlaceOrderInBatchParameters {
        /// @dev The address to receive the order
        address recipient;
        /// @dev When zero is true, it represents token0, otherwise it represents token1
        bool zero;
        BoundaryLowerWithAmountParameters[] orders;
    }

    struct BoundaryLowerWithAmountParameters {
        /// @dev The lower boundary of the order
        int24 boundaryLower;
        /// @dev The amount of token0 or token1 to add
        uint128 amount;
    }

    /// @dev Status during swap
    struct SwapState {
        /// @dev When true, token0 is swapped for token1, otherwise token1 is swapped for token0
        bool zeroForOne;
        /// @dev The remaining amount of the swap, which implicitly configures
        /// the swap as exact input (positive), or exact output (negative)
        int256 amountSpecifiedRemaining;
        /// @dev The calculated amount to be inputted
        uint256 amountInputCalculated;
        /// @dev The calculated amount of fee to be inputted
        uint256 feeAmountInputCalculated;
        /// @dev The calculated amount to be outputted
        uint256 amountOutputCalculated;
        /// @dev The price of the grid, as a Q64.96
        uint160 priceX96;
        uint160 priceLimitX96;
        /// @dev The boundary of the grid
        int24 boundary;
        /// @dev The lower boundary of the grid
        int24 boundaryLower;
        uint160 initializedBoundaryLowerPriceX96;
        uint160 initializedBoundaryUpperPriceX96;
        /// @dev Whether the swap has been completed
        bool stopSwap;
    }

    struct SwapForBoundaryState {
        /// @dev The price indicated by the lower boundary, as a Q64.96
        uint160 boundaryLowerPriceX96;
        /// @dev The price indicated by the upper boundary, as a Q64.96
        uint160 boundaryUpperPriceX96;
        /// @dev The price indicated by the lower or upper boundary, as a Q64.96.
        /// When using token0 to exchange token1, it is equal to boundaryLowerPriceX96,
        /// otherwise it is equal to boundaryUpperPriceX96
        uint160 boundaryPriceX96;
        /// @dev The price of the grid, as a Q64.96
        uint160 priceX96;
    }

    struct UpdateBundleForTakerParameters {
        /// @dev The amount to be swapped in to bundle0
        uint256 amountInUsed;
        /// @dev The remaining amount to be swapped in to bundle1
        uint256 amountInRemaining;
        /// @dev The amount to be swapped out to bundle0
        uint128 amountOutUsed;
        /// @dev The remaining amount to be swapped out to bundle1
        uint128 amountOutRemaining;
        /// @dev The amount to be paid to bundle0
        uint128 takerFeeForMakerAmountUsed;
        /// @dev The amount to be paid to bundle1
        uint128 takerFeeForMakerAmountRemaining;
    }
}

// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity ^0.8.0;

interface IGridStructs {
    struct Bundle {
        int24 boundaryLower;
        bool zero;
        uint128 makerAmountTotal;
        uint128 makerAmountRemaining;
        uint128 takerAmountRemaining;
        uint128 takerFeeAmountRemaining;
    }

    struct Boundary {
        uint64 bundle0Id;
        uint64 bundle1Id;
        uint128 makerAmountRemaining;
    }

    struct Order {
        uint64 bundleId;
        address owner;
        uint128 amount;
    }

    struct TokensOwed {
        uint128 token0;
        uint128 token1;
    }

    struct Slot0 {
        uint160 priceX96;
        int24 boundary;
        uint32 blockTimestamp;
        bool unlocked;
    }
}

// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity ^0.8.0;

library BoundaryMath {
    int24 public constant MIN_BOUNDARY = -527400;
    int24 public constant MAX_BOUNDARY = 443635;

    /// @dev The minimum value that can be returned from #getPriceX96AtBoundary. Equivalent to getPriceX96AtBoundary(MIN_BOUNDARY)
    uint160 internal constant MIN_RATIO = 989314;
    /// @dev The maximum value that can be returned from #getPriceX96AtBoundary. Equivalent to getPriceX96AtBoundary(MAX_BOUNDARY)
    uint160 internal constant MAX_RATIO = 1461300573427867316570072651998408279850435624081;

    /// @dev Checks if a boundary is divisible by a resolution
    /// @param boundary The boundary to check
    /// @param resolution The step size in initialized boundaries for a grid created with a given fee
    /// @return isValid Whether or not the boundary is valid
    function isValidBoundary(int24 boundary, int24 resolution) internal pure returns (bool isValid) {
        return boundary % resolution == 0;
    }

    /// @dev Checks if a boundary is within the valid range
    /// @param boundary The boundary to check
    /// @return inRange Whether or not the boundary is in range
    function isInRange(int24 boundary) internal pure returns (bool inRange) {
        return boundary >= MIN_BOUNDARY && boundary <= MAX_BOUNDARY;
    }

    /// @dev Checks if a price is within the valid range
    /// @param priceX96 The price to check, as a Q64.96
    /// @return inRange Whether or not the price is in range
    function isPriceX96InRange(uint160 priceX96) internal pure returns (bool inRange) {
        return priceX96 >= MIN_RATIO && priceX96 <= MAX_RATIO;
    }

    /// @notice Calculates the price at a given boundary
    /// @dev priceX96 = pow(1.0001, boundary) * 2**96
    /// @param boundary The boundary to calculate the price at
    /// @return priceX96 The price at the boundary, as a Q64.96
    function getPriceX96AtBoundary(int24 boundary) internal pure returns (uint160 priceX96) {
        unchecked {
            uint256 absBoundary = boundary < 0 ? uint256(-int256(boundary)) : uint24(boundary);

            uint256 ratio = absBoundary & 0x1 != 0
                ? 0xfff97272373d413259a46990580e213a
                : 0x100000000000000000000000000000000;
            if (absBoundary & 0x2 != 0) ratio = (ratio * 0xfff2e50f5f656932ef12357cf3c7fdcc) >> 128;
            if (absBoundary & 0x4 != 0) ratio = (ratio * 0xffe5caca7e10e4e61c3624eaa0941cd0) >> 128;
            if (absBoundary & 0x8 != 0) ratio = (ratio * 0xffcb9843d60f6159c9db58835c926644) >> 128;
            if (absBoundary & 0x10 != 0) ratio = (ratio * 0xff973b41fa98c081472e6896dfb254c0) >> 128;
            if (absBoundary & 0x20 != 0) ratio = (ratio * 0xff2ea16466c96a3843ec78b326b52861) >> 128;
            if (absBoundary & 0x40 != 0) ratio = (ratio * 0xfe5dee046a99a2a811c461f1969c3053) >> 128;
            if (absBoundary & 0x80 != 0) ratio = (ratio * 0xfcbe86c7900a88aedcffc83b479aa3a4) >> 128;
            if (absBoundary & 0x100 != 0) ratio = (ratio * 0xf987a7253ac413176f2b074cf7815e54) >> 128;
            if (absBoundary & 0x200 != 0) ratio = (ratio * 0xf3392b0822b70005940c7a398e4b70f3) >> 128;
            if (absBoundary & 0x400 != 0) ratio = (ratio * 0xe7159475a2c29b7443b29c7fa6e889d9) >> 128;
            if (absBoundary & 0x800 != 0) ratio = (ratio * 0xd097f3bdfd2022b8845ad8f792aa5825) >> 128;
            if (absBoundary & 0x1000 != 0) ratio = (ratio * 0xa9f746462d870fdf8a65dc1f90e061e5) >> 128;
            if (absBoundary & 0x2000 != 0) ratio = (ratio * 0x70d869a156d2a1b890bb3df62baf32f7) >> 128;
            if (absBoundary & 0x4000 != 0) ratio = (ratio * 0x31be135f97d08fd981231505542fcfa6) >> 128;
            if (absBoundary & 0x8000 != 0) ratio = (ratio * 0x9aa508b5b7a84e1c677de54f3e99bc9) >> 128;
            if (absBoundary & 0x10000 != 0) ratio = (ratio * 0x5d6af8dedb81196699c329225ee604) >> 128;
            if (absBoundary & 0x20000 != 0) ratio = (ratio * 0x2216e584f5fa1ea926041bedfe98) >> 128;
            if (absBoundary & 0x40000 != 0) ratio = (ratio * 0x48a170391f7dc42444e8fa2) >> 128;
            if (absBoundary & 0x80000 != 0) ratio = (ratio * 0x149b34ee7ac263) >> 128;

            if (boundary > 0) ratio = type(uint256).max / ratio;

            // this divides by 1<<32 and rounds up to go from a Q128.128 to a Q128.96.
            // due to out boundary input limitations, we then proceed to downcast as the
            // result will always fit within 160 bits.
            // we round up in the division so that getBoundaryAtPriceX96 of the output price is always consistent
            priceX96 = uint160((ratio + 0xffffffff) >> 32);
        }
    }

    /// @notice Calculates the boundary at a given price
    /// @param priceX96 The price to calculate the boundary at, as a Q64.96
    /// @return boundary The boundary at the price
    function getBoundaryAtPriceX96(uint160 priceX96) internal pure returns (int24 boundary) {
        unchecked {
            uint256 ratio = uint256(priceX96) << 32;

            uint256 r = ratio;
            uint256 msb = 0;

            assembly {
                let f := shl(7, gt(r, 0xFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF))
                msb := or(msb, f)
                r := shr(f, r)
            }
            assembly {
                let f := shl(6, gt(r, 0xFFFFFFFFFFFFFFFF))
                msb := or(msb, f)
                r := shr(f, r)
            }
            assembly {
                let f := shl(5, gt(r, 0xFFFFFFFF))
                msb := or(msb, f)
                r := shr(f, r)
            }
            assembly {
                let f := shl(4, gt(r, 0xFFFF))
                msb := or(msb, f)
                r := shr(f, r)
            }
            assembly {
                let f := shl(3, gt(r, 0xFF))
                msb := or(msb, f)
                r := shr(f, r)
            }
            assembly {
                let f := shl(2, gt(r, 0xF))
                msb := or(msb, f)
                r := shr(f, r)
            }
            assembly {
                let f := shl(1, gt(r, 0x3))
                msb := or(msb, f)
                r := shr(f, r)
            }
            assembly {
                let f := gt(r, 0x1)
                msb := or(msb, f)
            }

            if (msb >= 128) r = ratio >> (msb - 127);
            else r = ratio << (127 - msb);

            int256 log_2 = (int256(msb) - 128) << 64;

            assembly {
                r := shr(127, mul(r, r))
                let f := shr(128, r)
                log_2 := or(log_2, shl(63, f))
                r := shr(f, r)
            }
            assembly {
                r := shr(127, mul(r, r))
                let f := shr(128, r)
                log_2 := or(log_2, shl(62, f))
                r := shr(f, r)
            }
            assembly {
                r := shr(127, mul(r, r))
                let f := shr(128, r)
                log_2 := or(log_2, shl(61, f))
                r := shr(f, r)
            }
            assembly {
                r := shr(127, mul(r, r))
                let f := shr(128, r)
                log_2 := or(log_2, shl(60, f))
                r := shr(f, r)
            }
            assembly {
                r := shr(127, mul(r, r))
                let f := shr(128, r)
                log_2 := or(log_2, shl(59, f))
                r := shr(f, r)
            }
            assembly {
                r := shr(127, mul(r, r))
                let f := shr(128, r)
                log_2 := or(log_2, shl(58, f))
                r := shr(f, r)
            }
            assembly {
                r := shr(127, mul(r, r))
                let f := shr(128, r)
                log_2 := or(log_2, shl(57, f))
                r := shr(f, r)
            }
            assembly {
                r := shr(127, mul(r, r))
                let f := shr(128, r)
                log_2 := or(log_2, shl(56, f))
                r := shr(f, r)
            }
            assembly {
                r := shr(127, mul(r, r))
                let f := shr(128, r)
                log_2 := or(log_2, shl(55, f))
                r := shr(f, r)
            }
            assembly {
                r := shr(127, mul(r, r))
                let f := shr(128, r)
                log_2 := or(log_2, shl(54, f))
                r := shr(f, r)
            }
            assembly {
                r := shr(127, mul(r, r))
                let f := shr(128, r)
                log_2 := or(log_2, shl(53, f))
                r := shr(f, r)
            }
            assembly {
                r := shr(127, mul(r, r))
                let f := shr(128, r)
                log_2 := or(log_2, shl(52, f))
                r := shr(f, r)
            }
            assembly {
                r := shr(127, mul(r, r))
                let f := shr(128, r)
                log_2 := or(log_2, shl(51, f))
                r := shr(f, r)
            }
            assembly {
                r := shr(127, mul(r, r))
                let f := shr(128, r)
                log_2 := or(log_2, shl(50, f))
            }

            int256 log10001 = log_2 * 127869479499801913173570;
            // 128.128 number

            int24 boundaryLow = int24((log10001 - 1701496478404566090792001455681771637) >> 128);
            int24 boundaryHi = int24((log10001 + 289637967442836604689790891002483458648) >> 128);

            boundary = boundaryLow == boundaryHi ? boundaryLow : getPriceX96AtBoundary(boundaryHi) <= priceX96
                ? boundaryHi
                : boundaryLow;
        }
    }

    /// @dev Returns the lower boundary for the given boundary and resolution.
    /// The lower boundary may not be valid (if out of the boundary range)
    /// @param boundary The boundary to get the lower boundary for
    /// @param resolution The step size in initialized boundaries for a grid created with a given fee
    /// @return boundaryLower The lower boundary for the given boundary and resolution
    function getBoundaryLowerAtBoundary(int24 boundary, int24 resolution) internal pure returns (int24 boundaryLower) {
        unchecked {
            return boundary - (((boundary % resolution) + resolution) % resolution);
        }
    }

    /// @dev Rewrite the lower boundary that is not in the range to a valid value
    /// @param boundaryLower The lower boundary to rewrite
    /// @param resolution The step size in initialized boundaries for a grid created with a given fee
    /// @return validBoundaryLower The valid lower boundary
    function rewriteToValidBoundaryLower(
        int24 boundaryLower,
        int24 resolution
    ) internal pure returns (int24 validBoundaryLower) {
        unchecked {
            if (boundaryLower < MIN_BOUNDARY) return boundaryLower + resolution;
            else if (boundaryLower + resolution > MAX_BOUNDARY) return boundaryLower - resolution;
            else return boundaryLower;
        }
    }
}

// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/utils/Create2.sol";

library GridAddress {
    bytes32 internal constant GRID_BYTES_CODE_HASH = 0x884a6891a166f885bf6f0a3b330a25e41d1761a5aa091110a229d9a0e34b2c36;

    struct GridKey {
        address token0;
        address token1;
        int24 resolution;
    }

    /// @notice Constructs the grid key for the given parameters
    /// @dev tokenA and tokenB may be passed in, in the order of either token0/token1 or token1/token0
    /// @param tokenA The contract address of either token0 or token1
    /// @param tokenB The contract address of the other token
    /// @param resolution The step size in initialized boundaries for a grid created with a given fee
    /// @return key The grid key to compute the canonical address for the grid
    function gridKey(address tokenA, address tokenB, int24 resolution) internal pure returns (GridKey memory key) {
        if (tokenA > tokenB) (tokenA, tokenB) = (tokenB, tokenA);

        return GridKey(tokenA, tokenB, resolution);
    }

    /// @dev Computes the CREATE2 address for a grid with the given parameters
    /// @param gridFactory The address of the grid factory
    /// @param key The grid key to compute the canonical address for the grid
    /// @return grid The computed address
    function computeAddress(address gridFactory, GridKey memory key) internal pure returns (address grid) {
        require(key.token0 < key.token1);
        return
            Create2.computeAddress(
                keccak256(abi.encode(key.token0, key.token1, key.resolution)),
                GRID_BYTES_CODE_HASH,
                gridFactory
            );
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
// OpenZeppelin Contracts (last updated v4.8.0) (utils/Create2.sol)

pragma solidity ^0.8.0;

/**
 * @dev Helper to make usage of the `CREATE2` EVM opcode easier and safer.
 * `CREATE2` can be used to compute in advance the address where a smart
 * contract will be deployed, which allows for interesting new mechanisms known
 * as 'counterfactual interactions'.
 *
 * See the https://eips.ethereum.org/EIPS/eip-1014#motivation[EIP] for more
 * information.
 */
library Create2 {
    /**
     * @dev Deploys a contract using `CREATE2`. The address where the contract
     * will be deployed can be known in advance via {computeAddress}.
     *
     * The bytecode for a contract can be obtained from Solidity with
     * `type(contractName).creationCode`.
     *
     * Requirements:
     *
     * - `bytecode` must not be empty.
     * - `salt` must have not been used for `bytecode` already.
     * - the factory must have a balance of at least `amount`.
     * - if `amount` is non-zero, `bytecode` must have a `payable` constructor.
     */
    function deploy(
        uint256 amount,
        bytes32 salt,
        bytes memory bytecode
    ) internal returns (address addr) {
        require(address(this).balance >= amount, "Create2: insufficient balance");
        require(bytecode.length != 0, "Create2: bytecode length is zero");
        /// @solidity memory-safe-assembly
        assembly {
            addr := create2(amount, add(bytecode, 0x20), mload(bytecode), salt)
        }
        require(addr != address(0), "Create2: Failed on deploy");
    }

    /**
     * @dev Returns the address where a contract will be stored if deployed via {deploy}. Any change in the
     * `bytecodeHash` or `salt` will result in a new destination address.
     */
    function computeAddress(bytes32 salt, bytes32 bytecodeHash) internal view returns (address) {
        return computeAddress(salt, bytecodeHash, address(this));
    }

    /**
     * @dev Returns the address where a contract will be stored if deployed via {deploy} from a contract located at
     * `deployer`. If `deployer` is this contract's address, returns the same value as {computeAddress}.
     */
    function computeAddress(
        bytes32 salt,
        bytes32 bytecodeHash,
        address deployer
    ) internal pure returns (address addr) {
        /// @solidity memory-safe-assembly
        assembly {
            let ptr := mload(0x40) // Get free memory pointer

            // |                   | ↓ ptr ...  ↓ ptr + 0x0B (start) ...  ↓ ptr + 0x20 ...  ↓ ptr + 0x40 ...   |
            // |-------------------|---------------------------------------------------------------------------|
            // | bytecodeHash      |                                                        CCCCCCCCCCCCC...CC |
            // | salt              |                                      BBBBBBBBBBBBB...BB                   |
            // | deployer          | 000000...0000AAAAAAAAAAAAAAAAAAA...AA                                     |
            // | 0xFF              |            FF                                                             |
            // |-------------------|---------------------------------------------------------------------------|
            // | memory            | 000000...00FFAAAAAAAAAAAAAAAAAAA...AABBBBBBBBBBBBB...BBCCCCCCCCCCCCC...CC |
            // | keccak(start, 85) |            ↑↑↑↑↑↑↑↑↑↑↑↑↑↑↑↑↑↑↑↑↑↑↑↑↑↑↑↑↑↑↑↑↑↑↑↑↑↑↑↑↑↑↑↑↑↑↑↑↑↑↑↑↑↑↑↑↑↑↑↑↑↑ |

            mstore(add(ptr, 0x40), bytecodeHash)
            mstore(add(ptr, 0x20), salt)
            mstore(ptr, deployer) // Right-aligned with 12 preceding garbage bytes
            let start := add(ptr, 0x0b) // The hashed data starts at the final garbage byte which we will set to 0xff
            mstore8(start, 0xff)
            addr := keccak256(start, 85)
        }
    }
}

// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity ^0.8.0;

import "@gridexprotocol/core/contracts/interfaces/IGridParameters.sol";

/// @title The interface for the maker order manager
interface IMakerOrderManager {
    struct InitializeParameters {
        address tokenA;
        address tokenB;
        int24 resolution;
        uint160 priceX96;
        address recipient;
        IGridParameters.BoundaryLowerWithAmountParameters[] orders0;
        IGridParameters.BoundaryLowerWithAmountParameters[] orders1;
    }

    struct PlaceOrderParameters {
        uint256 deadline;
        address recipient;
        address tokenA;
        address tokenB;
        int24 resolution;
        bool zero;
        int24 boundaryLower;
        uint128 amount;
    }

    struct PlaceOrderInBatchParameters {
        uint256 deadline;
        address recipient;
        address tokenA;
        address tokenB;
        int24 resolution;
        bool zero;
        IGridParameters.BoundaryLowerWithAmountParameters[] orders;
    }

    struct RelativeOrderParameters {
        uint256 deadline;
        address recipient;
        address tokenA;
        address tokenB;
        int24 resolution;
        bool zero;
        uint128 amount;
        /// @dev The price delta is the price difference between the order price and the grid price, as a Q64.96.
        /// Positive values mean the order price is higher than the grid price, and negative values mean the order price is
        /// lower than the grid price.
        int160 priceDeltaX96;
        /// @dev The minimum price of the order, as a Q64.96.
        uint160 priceMinimumX96;
        /// @dev The maximum price of the order, as a Q64.96.
        uint160 priceMaximumX96;
    }

    /// @notice Returns the address of the IGridFactory
    function gridFactory() external view returns (address);

    /// @notice Initializes the grid with the given parameters
    function initialize(
        InitializeParameters calldata initializeParameters
    ) external payable;

    /// @notice Creates the grid and initializes the grid with the given parameters
    function createGridAndInitialize(
        InitializeParameters calldata initializeParameters
    ) external payable;

    /// @notice Places a maker order on the grid
    /// @return orderId The unique identifier of the order
    function placeMakerOrder(
        PlaceOrderParameters calldata parameters
    ) external payable returns (uint256 orderId);

    /// @notice Places maker orders on the grid
    /// @return orderIds The unique identifiers of the orders
    function placeMakerOrderInBatch(
        PlaceOrderInBatchParameters calldata parameters
    ) external payable returns (uint256[] memory orderIds);

    /// @notice Places a relative order
    /// @param parameters The parameters for the relative order
    /// @return orderId The unique identifier of the order
    function placeRelativeOrder(
        RelativeOrderParameters calldata parameters
    ) external payable returns (uint256 orderId);
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.18;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "./interfaces/IMakerOrderManager.sol";
import "@gridexprotocol/core/contracts/interfaces/IGrid.sol";
import "@gridexprotocol/core/contracts/interfaces/IGridEvents.sol";
import "@gridexprotocol/core/contracts/libraries/GridAddress.sol";
import "@gridexprotocol/core/contracts/libraries/BoundaryMath.sol";

error QYP_DCA__InvalidToken();
error QYP_DCA__InvalidAmount();
error QYP_DCA__InvalidFrequency();
error QYP_DCA__InvalidNumberOfOrders();
error QYP_DCA__InvalidDcaIndex();
error QYP_DCA__NoDcaPosition();

/**
 * @title Smart contract managing DCA positions from Users. Calling GridEx contract to submit orders.
 * @author 0xyanc
 */
contract QYP_DCA {
    struct Dca {
        uint256 totalAmount;
        uint128 amountPerOrder;
        uint256 frequency;
        uint256 numberOfOrders;
        uint256 creationDate;
        address tokenIn;
        uint256[] orderIds;
    }

    struct Order {
        uint256 orderId;
        int24 price;
        uint128 makerAmountTotal;
        uint128 makerAmountRemaining;
    }

    /// @dev the makerOrderManager to submit the orders to
    IMakerOrderManager public immutable makerOrderManager;

    /// @dev use 0.05% resolution where most liquidity should be
    int24 public constant RESOLUTION = 5;

    /// @dev address of the grid associated with this token pair
    address public gridAddress;
    /// @dev grid associated with this token pair
    IGrid public grid;
    /// @dev token0 of the grid pair - should be WETH
    address public immutable token0;
    /// @dev token1 of the grid pair - should be USDC
    address public immutable token1;

    /// @dev User storage, maps an DCA positions to a User.
    mapping(address => Dca[]) public usersPositions;

    uint256 public counter;

    /**
     * Fired in submitDcaPosition()
     * @param user user that submitted the DCA position
     * @param totalAmount total amount invested by the user
     * @param amountPerOrder amount to invest for each order
     * @param frequency frequency to invest the amount
     * @param numberOfOrders number of orders to be submitted in total
     */
    event DcaSubmitted(
        address indexed user,
        uint256 totalAmount,
        uint128 amountPerOrder,
        uint256 frequency,
        uint256 numberOfOrders,
        uint256 dcaIndex
    );
    /**
     * Fired in withdrawFunds()
     * @param user user that withdrew their funds
     * @param token0 address of token0 withdrawn
     * @param token1 address of token1 withdrawn
     * @param amount0 amount of token0 withdrawn
     * @param amount1 amount of token1 withdrawn
     */
    event FundsWithdrawn(
        address indexed user,
        address token0,
        address token1,
        uint256 amount0,
        uint256 amount1
    );

    /**
     * @notice Fired in submitDcaPosition() and submitScheduledOrder()
     * @param user recipient of the order
     * @param orderId id of the order
     * @param amount amount of token for the order
     */
    event OrderSubmitted(address indexed user, uint256 orderId, uint256 amount);

    constructor(
        IMakerOrderManager _makerOrderManager,
        address _token0,
        address _token1
    ) {
        makerOrderManager = _makerOrderManager;
        token0 = _token0;
        token1 = _token1;
        // compute grid address based on token pair
        gridAddress = GridAddress.computeAddress(
            makerOrderManager.gridFactory(),
            GridAddress.gridKey(token0, token1, RESOLUTION)
        );
        grid = IGrid(gridAddress);
    }

    /**
     * @notice Submit a DCA position, specifying the desired amount, frequency and number of orders.
     * @param _totalAmount total amount to be invested by the user
     * @param _amountPerOrder amount to be invested by the user for each period
     * @param _frequency frequency to invest the user's fund
     * @param _numberOfOrders total number of orders
     * @param _tokenIn token to DCA in
     */
    function submitDcaPosition(
        uint256 _totalAmount,
        uint128 _amountPerOrder,
        uint256 _frequency,
        uint256 _numberOfOrders,
        address _tokenIn
    ) external {
        if (_tokenIn != token0 && _tokenIn != token1) {
            revert QYP_DCA__InvalidToken();
        }
        if (_totalAmount == 0 || _amountPerOrder == 0) {
            revert QYP_DCA__InvalidAmount();
        }
        if (_frequency == 0) {
            revert QYP_DCA__InvalidFrequency();
        }
        if (_numberOfOrders == 0) {
            revert QYP_DCA__InvalidNumberOfOrders();
        }
        // msg.sender MUST approve the contract to spend the input token
        // transfer the specified amount of tokenIn to this contract
        SafeERC20.safeTransferFrom(
            IERC20(_tokenIn),
            msg.sender,
            address(this),
            _totalAmount
        );

        // increase the allowance for the maker order manager to spend tokenIn
        SafeERC20.safeIncreaseAllowance(
            IERC20(_tokenIn),
            address(makerOrderManager),
            _totalAmount
        );

        (, int24 boundary, , ) = grid.slot0();
        // we will place a maker order at the current lower boundary of the grid which corresponds to the best to the current price
        int24 boundaryLower = BoundaryMath.getBoundaryLowerAtBoundary(
            boundary,
            RESOLUTION
        );

        // build the parameters before placing the order
        IMakerOrderManager.PlaceOrderParameters
            memory parameters = IMakerOrderManager.PlaceOrderParameters({
                deadline: block.timestamp,
                recipient: msg.sender,
                tokenA: token0,
                tokenB: token1,
                resolution: RESOLUTION,
                zero: grid.token0() == _tokenIn,
                boundaryLower: boundaryLower,
                amount: _amountPerOrder
            });

        // call the Grid to place the order
        uint256 orderId = makerOrderManager.placeMakerOrder(parameters);

        // build the DCA position
        Dca memory position;
        position.totalAmount = _totalAmount;
        position.amountPerOrder = _amountPerOrder;
        position.frequency = _frequency;
        position.numberOfOrders = _numberOfOrders;
        usersPositions[msg.sender].push(position);
        uint256 length = usersPositions[msg.sender].length;
        usersPositions[msg.sender][length - 1].orderIds.push(orderId);

        // emit DcaSubmitted
        emit DcaSubmitted(
            msg.sender,
            _totalAmount,
            _amountPerOrder,
            _frequency,
            _numberOfOrders,
            length - 1
        );
        // emit OrderSubmitted event
        emit OrderSubmitted(msg.sender, orderId, _amountPerOrder);
    }

    /**
     * @notice Withdraw funds from the DCA contract and transfer token0 and token1 back to the user.
     *         All orders might not have been filled, it will settle (i.e. cancel) all outstanding orders.
     * @param _dcaIndex The DCA position to settle
     * @param _unwrapWeth true to unwrap WETH
     */
    function withdrawFunds(uint256 _dcaIndex, bool _unwrapWeth) external {
        if (usersPositions[msg.sender].length == 0) {
            revert QYP_DCA__NoDcaPosition();
        }
        if (_dcaIndex >= usersPositions[msg.sender].length) {
            revert QYP_DCA__InvalidDcaIndex();
        }
        uint256[] memory orderIds = usersPositions[msg.sender][_dcaIndex]
            .orderIds;
        (uint128 amount0Total, uint128 amount1Total) = grid
            .settleMakerOrderAndCollectInBatch(
                msg.sender,
                orderIds,
                _unwrapWeth
            );
        // emit FundsWithdrawn event
        emit FundsWithdrawn(
            msg.sender,
            token0,
            token1,
            amount0Total,
            amount1Total
        );
    }

    /**
     * @notice Show all orders info from a specific DCA positions of a user
     * @param _user address of the user to show positions from
     * @param _dcaIndex index of the DCA position to get orders from
     */
    function showDcaInfo(
        address _user,
        uint256 _dcaIndex
    ) external view returns (Order[] memory) {
        Order[] memory orders;
        // user has no DCA position
        if (usersPositions[_user].length == 0) return orders;
        // dca index does not exist
        if (_dcaIndex >= usersPositions[msg.sender].length) return orders;
        // loop through all the orderss of this DCA position
        uint256[] storage orderIds = usersPositions[msg.sender][_dcaIndex]
            .orderIds;

        for (uint256 i = 0; i < orderIds.length; ++i) {
            uint256 orderId = orderIds[i];
            // retrieve bundleId that the order belongs to
            (uint64 bundleId, , ) = grid.orders(orderId);
            // retrieve the price, makerAmountTotal, makerAmountRemaining from the bundle
            (
                int24 price,
                ,
                uint128 makerAmountTotal,
                uint128 makerAmountRemaining,
                ,

            ) = grid.bundles(bundleId);
            // build the Order object
            Order memory order = Order(
                orderId,
                price,
                makerAmountTotal,
                makerAmountRemaining
            );
            // add to the array to be returned
            orders[i] = order;
        }
        return orders;
    }

    /**
     * @notice Called by Gelato to submit a maker order for the recipient
     * @param _recipient user that will receive the tokens
     * @param _amountPerOrder amount of tokenIn for the order
     * @param _tokenIn token to DCA in
     * @param _dcaIndex DCA position where the scheduled order originated from
     */
    function submitScheduledOrder(
        address _recipient,
        uint128 _amountPerOrder,
        address _tokenIn,
        uint256 _dcaIndex
    ) external {
        (, int24 boundary, , ) = grid.slot0();
        // we will place a maker order at the current lower boundary of the grid which corresponds to the best to the current price
        int24 boundaryLower = BoundaryMath.getBoundaryLowerAtBoundary(
            boundary,
            RESOLUTION
        );

        // build the parameters before placing the order
        IMakerOrderManager.PlaceOrderParameters
            memory parameters = IMakerOrderManager.PlaceOrderParameters({
                deadline: block.timestamp,
                recipient: _recipient,
                tokenA: token0,
                tokenB: token1,
                resolution: RESOLUTION,
                zero: grid.token0() == _tokenIn,
                boundaryLower: boundaryLower,
                amount: _amountPerOrder
            });

        // call the Grid to place the order
        uint256 orderId = makerOrderManager.placeMakerOrder(parameters);

        // add the orderId to the array of the user's specific DCA position
        usersPositions[msg.sender][_dcaIndex].orderIds.push(orderId);

        // emit OrderSubmitted event
        emit OrderSubmitted(_recipient, orderId, _amountPerOrder);
    }

    function increment() external {
        counter++;
    }
}