// SPDX-License-Identifier: Apache-2.0

pragma solidity ^0.8.0;

// ==================== Internal Imports ====================

import { IExchangeAdapter } from "../../../interfaces/IExchangeAdapter.sol";

/**
 * @title UniswapV2ExchangeAdapter
 *
 * @dev Uniswap V2 Router02 Exchange adapter which encodes trade data
 */
contract UniswapV2ExchangeAdapter is IExchangeAdapter {
    // ==================== Variables ====================

    address public immutable _router; // Address of Uniswap V2 Router02

    // ==================== Constructor function ====================

    constructor(address router) {
        _router = router;
    }

    // ==================== External functions ====================

    /**
     * @dev Return calldata for Uniswap V2 Router02
     *
     * @param srcToken           Address of source token to be sold
     * @param destToken          Address of destination token to buy
     * @param to                 Address that assets should be transferred to
     * @param srcQuantity        Amount of source token to sell
     * @param minDestQuantity    Min amount of destination token to buy
     * @param data               Bytes containing trade path data
     *
     * @return target            Target contract address
     * @return value             Call value
     * @return callData          Trade calldata
     */
    function getTradeCalldata(
        address srcToken,
        address destToken,
        address to,
        uint256 srcQuantity,
        uint256 minDestQuantity,
        bytes memory data
    )
        external
        view
        returns (
            address target,
            uint256 value,
            bytes memory callData
        )
    {
        require(srcToken != address(0), "UbEA0a");
        require(destToken != address(0), "UbEA0b");
        require(to != address(0), "UbEA0c");

        address[] memory path;

        if (data.length == 0) {
            path = new address[](2);
            path[0] = srcToken;
            path[1] = destToken;
        } else {
            path = abi.decode(data, (address[]));
            require(path.length >= 2, "UbEA0d");
        }

        value = 0;
        target = _router;

        // encodeWithSignature(uint amountIn, uint amountOutMin, address[] calldata path, address to, uint deadline)
        callData = abi.encodeWithSignature(
            "swapExactTokensForTokens(uint256,uint256,address[],address,uint256)",
            srcQuantity, // amountIn
            minDestQuantity, // amountOutMin
            path, // path
            to, // to
            block.timestamp // deadline
        );
    }

    /**
     * @dev Returns the Uniswap router address to approve source tokens for trading.
     */
    function getSpender() external view returns (address) {
        return _router;
    }
}

// SPDX-License-Identifier: Apache-2.0

pragma solidity ^0.8.0;

/**
 * @title IExchangeAdapter
 */
interface IExchangeAdapter {
    // ==================== External functions ====================

    function getSpender() external view returns (address);

    /**
     * @param srcToken           Address of source token to be sold
     * @param destToken          Address of destination token to buy
     * @param destAddress        Address that assets should be transferred to
     * @param srcQuantity        Amount of source token to sell
     * @param minDestQuantity    Min amount of destination token to buy
     * @param data               Arbitrary bytes containing trade call data
     *
     * @return target            Target contract address
     * @return value             Call value
     * @return callData          Trade calldata
     */
    function getTradeCalldata(
        address srcToken,
        address destToken,
        address destAddress,
        uint256 srcQuantity,
        uint256 minDestQuantity,
        bytes memory data
    )
        external
        view
        returns (
            address target,
            uint256 value,
            bytes memory callData
        );
}