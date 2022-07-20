pragma solidity ^0.8.9;

import "./IUniswapV2Router02.sol";
// import "openzeppelin-solidity/contracts/token/ERC20/IERC20.sol";

contract SendToken {
    // IERC20 _token;

    // address TokenOut = 0x2f3A40A3db8a7e3D09B0adfEfbCe4f6F81927557;

    // constructor() {
    //     _token = IERC20(TokenOut);
    // }

    // function SendEther(address receiver) external payable returns (bool) {
    //     address(this).call{value: msg.value}("");
    //     (bool success, ) = receiver.call{value: msg.value}("");
    //     return success;
    // }

    // function getBalance() public view returns (uint) {
    //     return address(this).balance;
    // }

    // modifier checkAllowance(uint amount) {
    //     require(_token.allowance(msg.sender, address(this)) >= amount, "Error");
    //     _;
    // }

    // function depositTokens(uint _amount)
    //     external
    //     checkAllowance(_amount)
    //     returns (bool)
    // {
    //     bool success = _token.transferFrom(msg.sender, address(this), _amount);
    //     return success;
    // }

    // function sendTokens(address to, uint amount) external returns (bool) {
    //     bool success = _token.transfer(to, amount);
    //     return success;
    // }

    IUniswapV2Router02 uni =
        IUniswapV2Router02(0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D);

    // function swapExactETHforTokens(  uint256 amountOut,address receiver) external payable {
    //     address[] memory path = new address[](2);
    //     path[0] = uni.WETH();
    //     path[1] = TokenOut;

    //     uni.swapExactETHForTokens{value: msg.value}(
    //             amountOut,
    //             path,
    //             receiver,
    //             block.timestamp + 25
    //     );

    // }

    function swapExactETHforTokenss(
        address TokenOut,
        uint256 amountOut,
        address receiver,
        uint deadline
    ) external payable {
        address[] memory path = new address[](2);
        path[0] = uni.WETH();
        path[1] = TokenOut;

        uni.swapExactETHForTokens{value: msg.value}(
            amountOut,
            path,
            receiver,
            deadline
        );
    }

    // function swapExactETHforTokens(uint256 amountOut, address receiver)
    //     external
    //     payable
    // {
    //     address[] memory path = new address[](2);
    //     path[0] = uni.WETH();
    //     path[1] = tokenAddress;

    //     uni.swapExactETHForTokens{value: msg.value}(
    //         amountOut,
    //         path,
    //         receiver,
    //         block.timestamp + 25
    //     );
    // }
}

pragma solidity ^0.8.9;


import './IUniswapV2Router01.sol';

interface IUniswapV2Router02 is IUniswapV2Router01 {
    function removeLiquidityETHSupportingFeeOnTransferTokens(
        address token,
        uint liquidity,
        uint amountTokenMin,
        uint amountETHMin,
        address to,
        uint deadline
    ) external returns (uint amountETH);
    function removeLiquidityETHWithPermitSupportingFeeOnTransferTokens(
        address token,
        uint liquidity,
        uint amountTokenMin,
        uint amountETHMin,
        address to,
        uint deadline,
        bool approveMax, uint8 v, bytes32 r, bytes32 s
    ) external returns (uint amountETH);

    function swapExactTokensForTokensSupportingFeeOnTransferTokens(
        uint amountIn,
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    ) external;
    function swapExactETHForTokensSupportingFeeOnTransferTokens(
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    ) external payable;
    function swapExactTokensForETHSupportingFeeOnTransferTokens(
        uint amountIn,
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    ) external;
}

pragma solidity ^0.8.9;

interface IUniswapV2Router01 {
    function factory() external pure returns (address);
    function WETH() external pure returns (address);

    function addLiquidity(
        address tokenA,
        address tokenB,
        uint amountADesired,
        uint amountBDesired,
        uint amountAMin,
        uint amountBMin,
        address to,
        uint deadline
    ) external returns (uint amountA, uint amountB, uint liquidity);
    function addLiquidityETH(
        address token,
        uint amountTokenDesired,
        uint amountTokenMin,
        uint amountETHMin,
        address to,
        uint deadline
    ) external payable returns (uint amountToken, uint amountETH, uint liquidity);
    function removeLiquidity(
        address tokenA,
        address tokenB,
        uint liquidity,
        uint amountAMin,
        uint amountBMin,
        address to,
        uint deadline
    ) external returns (uint amountA, uint amountB);
    function removeLiquidityETH(
        address token,
        uint liquidity,
        uint amountTokenMin,
        uint amountETHMin,
        address to,
        uint deadline
    ) external returns (uint amountToken, uint amountETH);
    function removeLiquidityWithPermit(
        address tokenA,
        address tokenB,
        uint liquidity,
        uint amountAMin,
        uint amountBMin,
        address to,
        uint deadline,
        bool approveMax, uint8 v, bytes32 r, bytes32 s
    ) external returns (uint amountA, uint amountB);
    function removeLiquidityETHWithPermit(
        address token,
        uint liquidity,
        uint amountTokenMin,
        uint amountETHMin,
        address to,
        uint deadline,
        bool approveMax, uint8 v, bytes32 r, bytes32 s
    ) external returns (uint amountToken, uint amountETH);
    function swapExactTokensForTokens(
        uint amountIn,
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    ) external returns (uint[] memory amounts);
    function swapTokensForExactTokens(
        uint amountOut,
        uint amountInMax,
        address[] calldata path,
        address to,
        uint deadline
    ) external returns (uint[] memory amounts);
    function swapExactETHForTokens(uint amountOutMin, address[] calldata path, address to, uint deadline)
        external
        payable
        returns (uint[] memory amounts);
    function swapTokensForExactETH(uint amountOut, uint amountInMax, address[] calldata path, address to, uint deadline)
        external
        returns (uint[] memory amounts);
    function swapExactTokensForETH(uint amountIn, uint amountOutMin, address[] calldata path, address to, uint deadline)
        external
        returns (uint[] memory amounts);
    function swapETHForExactTokens(uint amountOut, address[] calldata path, address to, uint deadline)
        external
        payable
        returns (uint[] memory amounts);

    function quote(uint amountA, uint reserveA, uint reserveB) external pure returns (uint amountB);
    function getAmountOut(uint amountIn, uint reserveIn, uint reserveOut) external pure returns (uint amountOut);
    function getAmountIn(uint amountOut, uint reserveIn, uint reserveOut) external pure returns (uint amountIn);
    function getAmountsOut(uint amountIn, address[] calldata path) external view returns (uint[] memory amounts);
    function getAmountsIn(uint amountOut, address[] calldata path) external view returns (uint[] memory amounts);
}