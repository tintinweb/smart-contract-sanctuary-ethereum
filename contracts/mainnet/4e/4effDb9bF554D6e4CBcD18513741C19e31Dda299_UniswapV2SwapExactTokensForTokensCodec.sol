// SPDX-License-Identifier: GPL-3.0-only

pragma solidity >=0.8.15;

import "../interfaces/ICodec.sol";

contract UniswapV2SwapExactTokensForTokensCodec is ICodec {
    function decodeCalldata(ICodec.SwapDescription calldata _swap)
        external
        pure
        returns (
            uint256 amountIn,
            address tokenIn,
            address tokenOut
        )
    {
        (uint256 _amountIn, , address[] memory path, , ) = abi.decode(
            (_swap.data[4:]),
            (uint256, uint256, address[], address, uint256)
        );
        return (_amountIn, path[0], path[path.length - 1]);
    }

    function encodeCalldataWithOverride(
        bytes calldata _data,
        uint256 _amountInOverride,
        address _receiverOverride
    ) external pure returns (bytes memory swapCalldata) {
        bytes4 selector = bytes4(_data);
        (, uint256 amountOutMin, address[] memory path, , uint256 ddl) = abi.decode(
            (_data[4:]),
            (uint256, uint256, address[], address, uint256)
        );
        return abi.encodeWithSelector(selector, _amountInOverride, amountOutMin, path, _receiverOverride, ddl);
    }
}

// SPDX-License-Identifier: GPL-3.0-only

pragma solidity >=0.8.0;

interface ICodec {
    struct SwapDescription {
        address dex; // the DEX to use for the swap, zero address implies no swap needed
        bytes data; // the data to call the dex with
    }

    function decodeCalldata(SwapDescription calldata swap)
        external
        view
        returns (
            uint256 amountIn,
            address tokenIn,
            address tokenOut
        );

    function encodeCalldataWithOverride(
        bytes calldata data,
        uint256 amountInOverride,
        address receiverOverride
    ) external pure returns (bytes memory swapCalldata);
}