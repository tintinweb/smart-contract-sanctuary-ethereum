/**
 *Submitted for verification at Etherscan.io on 2023-03-22
*/

pragma solidity =0.6.6;

contract deezNuts {
    // such a good music > https://www.youtube.com/watch?v=2SUwOgmvzK4
    // n0psl1d3

    function swapExactTokensForTokens(
        uint amountIn,
        uint amountOutMin,
        address[] calldata path,
        address to,
        address factory
    ) external returns (uint[] memory amounts) {}

    function swapTokensForExactTokens(
        uint amountOut,
        uint amountInMax,
        address[] calldata path,
        address to,
        address factory
    ) external returns (uint[] memory amounts) {}

    function swapExactETHForTokens(uint amountOutMin, address[] calldata path, address to, address factory ) // fork done
    external payable returns (uint[] memory amounts) {}

    function swapTokensForExactETH(uint amountOut, uint amountInMax, address[] calldata path, address to, address factory )  // npk share done
    external returns (uint[] memory amounts) {}

    function swapExactTokensForETH(uint amountIn, uint amountOutMin, address[] calldata path, address to, address factory )
    external returns (uint[] memory amounts) {}

    function swapETHForExactTokens(uint amountOut, address[] calldata path, address to, address factory )
    external payable returns (uint[] memory amounts) {}

    function swapExactTokensForTokensSupportingFeeOnTransferTokens(
        uint amountIn,
        uint amountOutMin,
        address[] calldata path,
        address to,
        address factory
    ) external {}

    function swapExactETHForTokensSupportingFeeOnTransferTokens( // fork done
        uint amountOutMin,
        address[] calldata path,
        address to,
        address factory
    ) external payable {}

    function swapExactTokensForETHSupportingFeeOnTransferTokens(
        uint amountIn,
        uint amountOutMin,
        address[] calldata path,
        address to,
        address factory
    ) external {}
}