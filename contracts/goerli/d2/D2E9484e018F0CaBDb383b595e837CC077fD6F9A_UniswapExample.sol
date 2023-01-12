// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

import "./Interfaces.sol";

contract NewCounter {
    address private counter;

    constructor(address _counter) {
        counter = _counter;
    }

    function incrementCounter(uint256 x, uint256 y) external {
        ICounter(counter).increaseCount(x, y);
    }

    function getCount() external view returns (uint256) {
        return ICounter(counter).count();
    }
}

contract UniswapExample {
    address private immutable factory;
    address private immutable dai;
    address private immutable weth;

    constructor(address _factory, address _dai, address _weth) {
        factory = _factory;
        dai = _dai;
        weth = _weth;
    }

    function getTokenReserves() external view returns (address, uint256, uint256) {
        address pair = UniswapV2Factory(factory).getPair(dai, weth);
        (uint256 reserve0, uint256 reserve1, ) = UniswapV2Pair(pair).getReserves();
        return (pair, reserve0, reserve1);
    }
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

/**
 * Interface:
 * - Can be compiled, but cannot be deploy because the functions has no implementation
 * - The name of the parameters doesn't need to match the ones in the target contract
 * - Cannot have any function implementation
 * - Can inherit from another interfaces
 * - All declared functions must be external
 * - Cannot declare a constructor
 * - Cannot declare state variables
 */
interface ICounter {
    function count() external view returns (uint256);

    function increaseCount(uint256 step, uint256 value) external;
}

interface UniswapV2Factory {
    function getPair(address tokenA, address tokenB) external view returns (address pair);
}

interface UniswapV2Pair {
    function getReserves()
        external
        view
        returns (uint112 reserve0, uint112 reserve1, uint32 blockTimeStamp);
}