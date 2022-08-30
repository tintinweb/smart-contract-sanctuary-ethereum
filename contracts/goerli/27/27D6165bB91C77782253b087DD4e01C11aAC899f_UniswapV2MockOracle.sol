// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.4;

import "../interfaces/IUniswapV2Oracle.sol";

contract UniswapV2MockOracle is IUniswapV2Oracle {
    uint256 price;

    constructor(uint256 _price) {
        price = _price;
    }

    function consultAndUpdateIfNecessary(address, uint256)
        external
        override
        returns (uint256)
    {
        return price;
    }

     function consultUpdated(address token, uint256 amountIn)
        external
        view
        override
        returns (uint256 amountOut)
    {
        require(token != address(0));
        return amountIn * price / 1e18;
    }

    function setPrice(uint256 _price) external {
        price = _price;
    }
}

// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.4;

interface IUniswapV2Oracle {
    function consultAndUpdateIfNecessary(address token, uint256 amountIn)
        external
        returns (uint256);
    
    function consultUpdated(address token, uint256 amountIn)
        external
        returns (uint256);
}