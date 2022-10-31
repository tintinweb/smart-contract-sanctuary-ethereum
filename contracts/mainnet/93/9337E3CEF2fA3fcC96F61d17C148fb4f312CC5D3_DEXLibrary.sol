// SPDX-License-Identifier: MIT
pragma solidity >=0.8.0;

import "./../../core/interfaces/IERC20Pair.sol";
import "./../../core/library/SafeMath.sol";

//import "./../../core/ERC20Pair.sol";

library DEXLibrary {
    using SafeMath for uint256;

    // returns sorted token addresses, used to handle return values from pairs sorted in this order
    function sortTokens(address tokenA, address tokenB)
        internal
        pure
        returns (address token0, address token1)
    {
        require(tokenA != tokenB, "DEXLibrary: IDENTICAL_ADDRESSES");
        (token0, token1) = tokenA < tokenB
            ? (tokenA, tokenB)
            : (tokenB, tokenA);
        require(token0 != address(0), "DEXLibrary: ZERO_ADDRESS");
    }

    /* function hashCode() public pure returns (bytes32){
         bytes memory bytecode = type(ERC20Pair).creationCode;
         return keccak256(abi.encodePacked(bytecode));
     }*/
    // calculates the CREATE2 address for a pair without making any external calls
    function pairFor(
        address factory,
        address tokenA,
        address tokenB,
        uint32 poolFee
    ) public pure returns (address pair) {
        (address token0, address token1) = sortTokens(tokenA, tokenB);
        pair = address(
            uint160(
                uint256(
                    keccak256(
                        abi.encodePacked(
                            hex"ff",
                            factory,
                            keccak256(
                                abi.encodePacked(token0, token1, poolFee)
                            ),
                            hex"4865ea389995915db67b44b39fd00c73c081158e770991b408389498fb8dc480"
                        )
                    )
                )
            )
        );
    }

    // fetches and sorts the reserves for a pair
    function getReserves(
        address factory,
        address tokenA,
        address tokenB,
        uint32 poolFee
    ) internal view returns (uint256 reserveA, uint256 reserveB) {
        (address token0, ) = sortTokens(tokenA, tokenB);
        (uint256 reserve0, uint256 reserve1, ) = IERC20Pair(
            pairFor(factory, tokenA, tokenB, poolFee)
        ).getReserves();
        (reserveA, reserveB) = tokenA == token0
            ? (reserve0, reserve1)
            : (reserve1, reserve0);
    }

    // given some amount of an asset and pair reserves, returns an equivalent amount of the other asset
    function quote(
        uint256 amountA,
        uint256 reserveA,
        uint256 reserveB
    ) internal pure returns (uint256 amountB) {
        require(amountA > 0, "DEXLibrary: INSUFFICIENT_AMOUNT");
        require(
            reserveA > 0 && reserveB > 0,
            "DEXLibrary: INSUFFICIENT_LIQUIDITY"
        );
        amountB = amountA.mul(reserveB) / reserveA;
    }

    // given an input amount of an asset and pair reserves, returns the maximum output amount of the other asset
    function getAmountOut(
        uint256 amountIn,
        uint256 reserveIn,
        uint256 reserveOut,
        uint32 fee
    ) internal pure returns (uint256 amountOut) {
        require(amountIn > 0, "DEXLibrary: INSUFFICIENT_INPUT_AMOUNT");
        require(
            reserveIn > 0 && reserveOut > 0,
            "DEXLibrary: INSUFFICIENT_LIQUIDITY"
        );
        uint256 amountInWithFee = amountIn.mul(10**5 - fee);
        uint256 numerator = amountInWithFee.mul(reserveOut);
        uint256 denominator = reserveIn.mul(10**5).add(amountInWithFee);
        amountOut = numerator / denominator;
    }

    // given an output amount of an asset and pair reserves, returns a required input amount of the other asset
    function getAmountIn(
        uint256 amountOut,
        uint256 reserveIn,
        uint256 reserveOut,
        uint32 fee
    ) internal pure returns (uint256 amountIn) {
        require(amountOut > 0, "DEXLibrary: INSUFFICIENT_OUTPUT_AMOUNT");
        require(
            reserveIn > 0 && reserveOut > 0,
            "DEXLibrary: INSUFFICIENT_LIQUIDITY"
        );
        uint256 numerator = reserveIn.mul(amountOut).mul(10**5);
        uint256 denominator = reserveOut.sub(amountOut).mul(10**5 - fee);
        amountIn = (numerator / denominator).add(1);
    }

    // performs chained getAmountOut calculations on any number of pairs
    function getAmountsOut(
        address factory,
        uint256 amountIn,
        address[] memory path,
        uint32[] calldata feePath
    ) internal view returns (uint256[] memory amounts) {
        require(path.length >= 2, "DEXLibrary: INVALID_PATH");
        amounts = new uint256[](path.length);
        amounts[0] = amountIn;
        for (uint256 i; i < path.length - 1; i++) {
            (uint256 reserveIn, uint256 reserveOut) = getReserves(
                factory,
                path[i],
                path[i + 1],
                feePath[i]
            );
            amounts[i + 1] = getAmountOut(
                amounts[i],
                reserveIn,
                reserveOut,
                feePath[i]
            );
        }
    }

    // performs chained getAmountIn calculations on any number of pairs
    function getAmountsIn(
        address factory,
        uint256 amountOut,
        address[] memory path,
        uint32[] calldata feePath
    ) external view returns (uint256[] memory amounts) {
        require(path.length >= 2, "DEXLibrary: INVALID_PATH");
        amounts = new uint256[](path.length);
        amounts[amounts.length - 1] = amountOut;
        for (uint256 i = path.length - 1; i > 0; i--) {
            (uint256 reserveIn, uint256 reserveOut) = getReserves(
                factory,
                path[i - 1],
                path[i],
                feePath[i - 1]
            );
            amounts[i - 1] = getAmountIn(
                amounts[i],
                reserveIn,
                reserveOut,
                feePath[i - 1]
            );
        }
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./IERC20PairToken.sol";

interface IERC20Pair is IERC20PairToken {
    function swap(
        uint256 amountOfAsset1,
        uint256 amountOfAsset2,
        address to,
        bytes calldata data
    ) external;

    function getReserves()
        external
        view
        returns (
            uint112 _reserve0,
            uint112 _reserve1,
            uint32 _blockTimestampLast
        );

    function mint(address to) external returns (uint256 liquidity);

    function burn(address to)
        external
        returns (uint256 amount1, uint256 amount2);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

library SafeMath {
    function add(uint256 x, uint256 y) internal pure returns (uint256 z) {
        require((z = x + y) >= x, "ds-math-add-overflow");
    }

    function sub(uint256 x, uint256 y) internal pure returns (uint256 z) {
        require((z = x - y) <= x, "ds-math-sub-underflow");
    }

    function mul(uint256 x, uint256 y) internal pure returns (uint256 z) {
        require(y == 0 || (z = x * y) / y == x, "ds-math-mul-overflow");
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface IERC20PairToken {
    function transferFrom(
        address from,
        address to,
        uint256 value
    ) external returns (bool);
}