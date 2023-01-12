// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

import "./Interfaces.sol";

contract NewCounter {
    address private counter;

    constructor(address _counter) {
        counter = _counter;
    }

    function incrementCounter() external {
        ICounter(counter).increaseCount();
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

    function getTokenReserves() external view returns (uint256, uint256) {
        address pair = UniswapV2Factory(factory).getPair(dai, weth);
        (uint256 reserve0, uint256 reserve1, ) = UniswapV2Pair(pair).getReserves();
        return (reserve0, reserve1);
    }
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

interface ICounter {
    function count() external view returns (uint256);

    function increaseCount() external;
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