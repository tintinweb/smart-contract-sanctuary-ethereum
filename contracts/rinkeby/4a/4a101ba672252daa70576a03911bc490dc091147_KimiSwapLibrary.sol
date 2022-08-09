/**
 *Submitted for verification at Etherscan.io on 2022-08-09
*/

// File: interfaces/IKimiSwapFactory.sol

//SPDX-License-Identifier: MIT
pragma solidity >=0.8.10;

interface IKimiSwapFactory {
    function pairs(address, address) external pure returns (address);

    function createPair(address, address) external returns (address);
}

// File: interfaces/IKimiSwapPair.sol

pragma solidity >=0.8.10;

interface IKimiSwapPair {
    function initialize(address, address) external;

    function getReserves()
        external
        returns (
            uint112,
            uint112,
            uint32
        );

    function mint(address) external returns (uint256);

    function burn(address) external returns (uint256, uint256);

    function transferFrom(
        address,
        address,
        uint256
    ) external returns (bool);

    function swap(
        uint256,
        uint256,
        address
    ) external;
}

// File: contracts/KimiSwapLibrary.sol

pragma solidity >=0.8.10;

library KimiSwapLibrary {

    function getReserves(
        address factoryAddress,
        address tokenA,
        address tokenB
    ) public returns (uint256 reserveA, uint256 reserveB) {
        (address token0, address token1) = sortTokens(tokenA, tokenB); //we sort token addresses–this is important to avoid duplicates
        (uint256 reserve0, uint256 reserve1, ) = IKimiSwapPair(
            pairFor(factoryAddress, token0, token1)
        ).getReserves();
        (reserveA, reserveB) = tokenA == token0
            ? (reserve0, reserve1)
            : (reserve1, reserve0);
    }

    function quote(
        uint256 amountIn,
        uint256 reserveIn,
        uint256 reserveOut
    ) public pure returns (uint256 amountOut) {
        require(amountIn > 0, "KimiSwapLibrary: INSUFFICIENT_AMOUNT");
        require(
            reserveIn > 0 && reserveOut > 0,
            "KimiSwapLibrary: INSUFFICIENT_LIQUIDITY"
        );

        return (amountIn * reserveOut) / reserveIn;
    }

    //used to find pair address by factory and token addresses.
    function pairFor(
        address factoryAddress,
        address tokenA,
        address tokenB
    ) internal pure returns (address pairAddress) {
        (address token0, address token1) = sortTokens(tokenA, tokenB);
         pairAddress = address(
            uint160(
                uint256(
                    keccak256(
                        abi.encodePacked(
                            hex"ff",
                            factoryAddress,
                            keccak256(abi.encodePacked(token0, token1)),
                            hex"b00f428c4309c404933609c4ef6d23d1ae75f95ed6ab25d63a6158e7a2acd1ab" //init code hash
                        )
                    )
                )
            )
        );
    }

    function sortTokens(address tokenA, address tokenB)
        internal
        pure
        returns (address token0, address token1)
    {
        return tokenA < tokenB ? (tokenA, tokenB) : (tokenB, tokenA);
    }

    function getAmountOut(
        uint256 amountIn,
        uint256 reserveIn,
        uint256 reserveOut
    ) public pure returns (uint256) {
        require(amountIn > 0, "KimiSwapLibrary: INSUFFICIENT_AMOUNT");
        require(
            reserveIn > 0 && reserveOut > 0,
            "KimiSwapLibrary: INSUFFICIENT_LIQUIDITY"
        );

        uint256 amountInWithFee = amountIn * 997;
        uint256 numerator = amountInWithFee * reserveOut;
        uint256 denominator = (reserveIn * 1000) + amountInWithFee;

        return numerator / denominator;
    }

    function getAmountsOut(
        address factory,
        uint256 amountIn,
        address[] memory path
    ) public returns (uint256[] memory) {
        require(path.length >= 2, "KimiSwapLibrary: INVALID_PATH");
        uint256[] memory amounts = new uint256[](path.length);
        amounts[0] = amountIn;

        for (uint256 i = 0; i < path.length - 1; i++) {
            (uint256 reserve0, uint256 reserve1) = getReserves(
                factory,
                path[i],
                path[i + 1]
            );
            amounts[i + 1] = getAmountOut(amounts[i], reserve0, reserve1);
        }

        return amounts;
    }

    function getAmountIn(
        uint256 amountOut,
        uint256 reserveIn,
        uint256 reserveOut
    ) public pure returns (uint256) {
        require(amountOut > 0, "KimiSwapLibrary: INSUFFICIENT_AMOUNT");
        require(
            reserveIn > 0 && reserveOut > 0,
            "KimiSwapLibrary: INSUFFICIENT_LIQUIDITY"
        );

        uint256 numerator = reserveIn * amountOut * 1000;
        uint256 denominator = (reserveOut - amountOut) * 997;

        return (numerator / denominator) + 1;
    }

    function getAmountsIn(
        address factory,
        uint256 amountOut,
        address[] memory path
    ) public returns (uint256[] memory) {
        require(path.length >= 2, "KimiSwapLibrary: INVALID_PATH");
        uint256[] memory amounts = new uint256[](path.length);
        amounts[amounts.length - 1] = amountOut;

        for (uint256 i = path.length - 1; i > 0; i--) {
            (uint256 reserve0, uint256 reserve1) = getReserves(
                factory,
                path[i - 1],
                path[i]
            );
            amounts[i - 1] = getAmountIn(amounts[i], reserve0, reserve1);
        }

        return amounts;
    }
}