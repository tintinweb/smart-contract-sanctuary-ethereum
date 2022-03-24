// SPDX-License-Identifier: Apache-2.0

pragma solidity ^0.8.0;

// ==================== Internal Imports ====================

import { IExchangeAdapter } from "../../../interfaces/IExchangeAdapter.sol";

/**
 * @title UniswapV2ExchangeAdapterV2
 *
 * @dev Uniswap Router02 exchange adapter that returns calldata for trading includes option for 2 different trade types.
 */
contract UniswapV2ExchangeAdapterV2 is IExchangeAdapter {
    // ==================== Constants ====================

    // Uniswap router function string for swapping exact tokens for a minimum of receive tokens
    // swapExactTokensForTokens(uint amountIn, uint amountOutMin, address[] calldata path, address to, uint deadline)
    string public constant SWAP_EXACT_TOKENS_FOR_TOKENS = "swapExactTokensForTokens(uint256,uint256,address[],address,uint256)";

    // Uniswap router function string for swapping tokens for an exact amount of receive tokens
    // function swapTokensForExactTokens(uint amountOut, uint amountInMax, address[] calldata path, address to, uint deadline)
    string public constant SWAP_TOKENS_FOR_EXACT_TOKENS = "swapTokensForExactTokens(uint256,uint256,address[],address,uint256)";

    // ==================== Variables ====================

    address internal immutable _router; // Address of Uniswap V2 Router02

    // ==================== Constructor function ====================

    constructor(address router) {
        _router = router;
    }

    // ==================== External functions ====================

    /**
     * @dev Return calldata for Uniswap V2 Router02. Trade paths and bool to select trade function are encoded in the arbitrary data parameter.
     *
     * Note: When selecting the swap for exact tokens function, srcQuantity is defined as the max token quantity you are willing to trade, and
     * minDestinationQuantity is the exact quantity of token you are receiving.
     *
     * @param to              Address that assets should be transferred to
     * @param srcQuantity     Fixed/Max amount of source token to sell
     * @param destQuantity    Min/Fixed amount of destination token to buy
     * @param data            Bytes containing trade path and bool to determine function string
     *
     * @return target         Target contract address
     * @return value          Call value
     * @return callData       Trade calldata
     */
    function getTradeCalldata(
        address srcToken,
        address destToken,
        address to,
        uint256 srcQuantity,
        uint256 destQuantity,
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
        require(srcToken != address(0), "UbEAb0a");
        require(destToken != address(0), "UbEAb0b");
        require(to != address(0), "UbEAb0c");

        (address[] memory path, bool shouldSwapExactTokensForTokens) = abi.decode(data, (address[], bool));
        require(path.length >= 2, "UbEAb0d");

        value = 0;
        target = _router;
        callData = shouldSwapExactTokensForTokens
            ? abi.encodeWithSignature(SWAP_EXACT_TOKENS_FOR_TOKENS, srcQuantity, destQuantity, path, to, block.timestamp)
            : abi.encodeWithSignature(SWAP_TOKENS_FOR_EXACT_TOKENS, destQuantity, srcQuantity, path, to, block.timestamp);
    }

    /**
     * @dev Generate data parameter to be passed to `getTradeCalldata`. Returns encoded trade paths and bool to select trade function.
     *
     * @param srcToken     Address of the source token to be sold
     * @param destToken    Address of the destination token to buy
     * @param fixIn        Boolean representing if input tokens amount is fixed
     *
     * @return bytes       Data parameter to be passed to `getTradeCalldata`
     */
    function generateDataParam(
        address srcToken,
        address destToken,
        bool fixIn
    ) external pure returns (bytes memory) {
        address[] memory path = new address[](2);
        path[0] = srcToken;
        path[1] = destToken;

        return abi.encode(path, fixIn);
    }

    function generateDataParam2(
        address srcToken,
        address midToken,
        address destToken,
        bool fixIn
    ) external pure returns (bytes memory) {
        address[] memory path = new address[](2);
        path[0] = srcToken;
        path[1] = midToken;
        path[2] = destToken;

        return abi.encode(path, fixIn);
    }

    /**
     * @dev Returns the Uniswap router address to approve source tokens for trading.
     */
    function getSpender() external view returns (address) {
        return _router;
    }

    /**
     * @dev Helper that returns the encoded data of trade path and boolean indicating the Uniswap function to use
     *
     * @return bytes    Encoded data used for trading on Uniswap
     */
    function getExchangeData(address[] memory path, bool shouldSwapExactTokensForTokens) external pure returns (bytes memory) {
        return abi.encode(path, shouldSwapExactTokensForTokens);
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