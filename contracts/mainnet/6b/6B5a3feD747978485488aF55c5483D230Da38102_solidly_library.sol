// SPDX-License-Identifier: BUSL-1.1
pragma solidity 0.8.11;

/**
 * @title Solidly+ Implementation
 * @author Solidly+
 * @notice Governable implementation that relies on governance slot to be set by the proxy
 */
contract SolidlyImplementation {
    bytes32 constant GOVERNANCE_SLOT =
        0xb53127684a568b3173ae13b9f8a6016e243e63b6e8ee1178d6a717850b5d6103; // keccak256('eip1967.proxy.admin')
    bytes32 constant INITIALIZED_SLOT =
        0x834ce84547018237034401a09067277cdcbe7bbf7d7d30f6b382b0a102b7b4a3; // keccak256('eip1967.proxy.initialized')

    /**
     * @notice Reverts if msg.sender is not governance
     */
    modifier onlyGovernance() {
        require(msg.sender == governanceAddress(), "Only governance");
        _;
    }

    /**
     * @notice Reverts if contract is already initialized
     * @dev U4sed by implementations to ensure initialize() is only called once
     */
    modifier notInitialized() {
        bool initialized;
        assembly {
            initialized := sload(INITIALIZED_SLOT)
            if eq(initialized, 1) {
                revert(0, 0)
            }
        }
        _;
    }

    /**
     * @notice Fetch current governance address
     * @return _governanceAddress Returns current governance address
     */
    function governanceAddress()
        public
        view
        virtual
        returns (address _governanceAddress)
    {
        assembly {
            _governanceAddress := sload(GOVERNANCE_SLOT)
        }
    }
}

// SPDX-License-Identifier: BUSL-1.1

pragma solidity 0.8.11;

import "./ProxyPattern/SolidlyImplementation.sol";

interface solidly_pair {
    function metadata()
        external
        view
        returns (
            uint256 dec0,
            uint256 dec1,
            uint256 r0,
            uint256 r1,
            bool st,
            address t0,
            address t1,
            uint256 feeRatio
        );
}

interface solidly_router {
    function pairFor(
        address tokenA,
        address tokenB,
        bool stable
    ) external view returns (address pair);
}

/**
 * @dev
 *      Changes:
 *      -   _getAmountOut() does not revert if the trade would revert due to
 *          the reserve being exactly 1. Returns 0 instead.
 */
contract solidly_library is SolidlyImplementation {
    uint256 public constant feeDivider = 1e6;

    solidly_router public router;

    function initialize(solidly_router _router)
        external
        onlyGovernance
        notInitialized
    {
        router = _router;
    }

    function _f(uint256 x0, uint256 y) internal pure returns (uint256) {
        return
            (x0 * ((((y * y) / 1e18) * y) / 1e18)) /
            1e18 +
            (((((x0 * x0) / 1e18) * x0) / 1e18) * y) /
            1e18;
    }

    function _d(uint256 x0, uint256 y) internal pure returns (uint256) {
        return
            (3 * x0 * ((y * y) / 1e18)) /
            1e18 +
            ((((x0 * x0) / 1e18) * x0) / 1e18);
    }

    function _get_y(
        uint256 x0,
        uint256 xy,
        uint256 y
    ) internal pure returns (uint256) {
        for (uint256 i = 0; i < 255; i++) {
            uint256 y_prev = y;
            uint256 k = _f(x0, y);
            if (k < xy) {
                uint256 dy = ((xy - k) * 1e18) / _d(x0, y);
                y = y + dy;
            } else {
                uint256 dy = ((k - xy) * 1e18) / _d(x0, y);
                y = y - dy;
            }
            if (y > y_prev) {
                if (y - y_prev <= 1) {
                    return y;
                }
            } else {
                if (y_prev - y <= 1) {
                    return y;
                }
            }
        }
        return y;
    }

    function getTradeDiff(
        uint256 amountIn,
        address tokenIn,
        address tokenOut,
        bool stable
    ) external view returns (uint256 a, uint256 b) {
        (
            uint256 dec0,
            uint256 dec1,
            uint256 r0,
            uint256 r1,
            bool st,
            address t0,
            ,
            uint256 feeRatio
        ) = solidly_pair(router.pairFor(tokenIn, tokenOut, stable)).metadata();
        uint256 sample = tokenIn == t0 ? (r0 * dec1) / r1 : (r1 * dec0) / r0;
        a =
            (_getAmountOut(
                sample,
                tokenIn,
                r0,
                r1,
                t0,
                dec0,
                dec1,
                st,
                feeRatio
            ) * 1e18) /
            sample;
        b =
            (_getAmountOut(
                amountIn,
                tokenIn,
                r0,
                r1,
                t0,
                dec0,
                dec1,
                st,
                feeRatio
            ) * 1e18) /
            amountIn;
    }

    function getTradeDiff(
        uint256 amountIn,
        address tokenIn,
        address pair
    ) external view returns (uint256 a, uint256 b) {
        (
            uint256 dec0,
            uint256 dec1,
            uint256 r0,
            uint256 r1,
            bool st,
            address t0,
            ,
            uint256 feeRatio
        ) = solidly_pair(pair).metadata();
        uint256 sample = tokenIn == t0 ? (r0 * dec1) / r1 : (r1 * dec0) / r0;
        a =
            (_getAmountOut(
                sample,
                tokenIn,
                r0,
                r1,
                t0,
                dec0,
                dec1,
                st,
                feeRatio
            ) * 1e18) /
            sample;
        b =
            (_getAmountOut(
                amountIn,
                tokenIn,
                r0,
                r1,
                t0,
                dec0,
                dec1,
                st,
                feeRatio
            ) * 1e18) /
            amountIn;
    }

    function getSample(
        address tokenIn,
        address tokenOut,
        bool stable
    ) external view returns (uint256) {
        (
            uint256 dec0,
            uint256 dec1,
            uint256 r0,
            uint256 r1,
            bool st,
            address t0,
            ,
            uint256 feeRatio
        ) = solidly_pair(router.pairFor(tokenIn, tokenOut, stable)).metadata();
        uint256 sample = tokenIn == t0 ? (r0 * dec1) / r1 : (r1 * dec0) / r0;
        return
            (_getAmountOut(
                sample,
                tokenIn,
                r0,
                r1,
                t0,
                dec0,
                dec1,
                st,
                feeRatio
            ) * 1e18) / sample;
    }

    function getMinimumValue(
        address tokenIn,
        address tokenOut,
        bool stable
    )
        external
        view
        returns (
            uint256,
            uint256,
            uint256
        )
    {
        (
            uint256 dec0,
            uint256 dec1,
            uint256 r0,
            uint256 r1,
            ,
            address t0,
            ,

        ) = solidly_pair(router.pairFor(tokenIn, tokenOut, stable)).metadata();
        uint256 sample = tokenIn == t0 ? (r0 * dec1) / r1 : (r1 * dec0) / r0;
        return (sample, r0, r1);
    }

    function getAmountOut(
        uint256 amountIn,
        address tokenIn,
        address tokenOut,
        bool stable
    ) external view returns (uint256) {
        (
            uint256 dec0,
            uint256 dec1,
            uint256 r0,
            uint256 r1,
            bool st,
            address t0,
            ,
            uint256 feeRatio
        ) = solidly_pair(router.pairFor(tokenIn, tokenOut, stable)).metadata();
        return
            (_getAmountOut(
                amountIn,
                tokenIn,
                r0,
                r1,
                t0,
                dec0,
                dec1,
                st,
                feeRatio
            ) * 1e18) / amountIn;
    }

    function _getAmountOut(
        uint256 amountIn,
        address tokenIn,
        uint256 _reserve0,
        uint256 _reserve1,
        address token0,
        uint256 decimals0,
        uint256 decimals1,
        bool stable,
        uint256 feeRatio
    ) internal pure returns (uint256) {
        if (_reserve0 == 1 || _reserve1 == 1) {
            if (tokenIn == token0) {
                if (_reserve1 == 1) {
                    return 0;
                }
            } else {
                if (_reserve0 == 1) {
                    return 0;
                }
            }
        }

        amountIn -= (amountIn * feeRatio) / feeDivider; // remove fee from amount received
        if (stable) {
            uint256 xy = _k(_reserve0, _reserve1, stable, decimals0, decimals1);
            _reserve0 = (_reserve0 * 1e18) / decimals0;
            _reserve1 = (_reserve1 * 1e18) / decimals1;
            (uint256 reserveA, uint256 reserveB) = tokenIn == token0
                ? (_reserve0, _reserve1)
                : (_reserve1, _reserve0);
            amountIn = tokenIn == token0
                ? (amountIn * 1e18) / decimals0
                : (amountIn * 1e18) / decimals1;
            uint256 y = reserveB - _get_y(amountIn + reserveA, xy, reserveB);
            return (y * (tokenIn == token0 ? decimals1 : decimals0)) / 1e18;
        } else {
            (uint256 reserveA, uint256 reserveB) = tokenIn == token0
                ? (_reserve0, _reserve1)
                : (_reserve1, _reserve0);
            return (amountIn * reserveB) / (reserveA + amountIn);
        }
    }

    function _k(
        uint256 x,
        uint256 y,
        bool stable,
        uint256 decimals0,
        uint256 decimals1
    ) internal pure returns (uint256) {
        if (stable) {
            uint256 _x = (x * 1e18) / decimals0;
            uint256 _y = (y * 1e18) / decimals1;
            uint256 _a = (_x * _y) / 1e18;
            uint256 _b = ((_x * _x) / 1e18 + (_y * _y) / 1e18);
            return (_a * _b) / 1e18; // x3y+y3x >= k
        } else {
            return x * y; // xy >= k
        }
    }
}