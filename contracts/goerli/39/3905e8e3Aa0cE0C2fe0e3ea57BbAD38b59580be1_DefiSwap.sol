/**
 *Submitted for verification at Etherscan.io on 2022-09-16
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

// 完成一个 Swap 合约, 调用 Uniswap 的 Router 合约接口实现
contract DefiSwap {
    // 已经部署在 区块链上的 Router 地址: https://rinkeby.etherscan.io/address/0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D
    address private constant UNISWAP_V2_ROUTER =
        0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D;

    // 已经部署在 区块链上的 WETH 地址:
    address private constant WETH = 0xc778417E063141139Fce010982780140Aa0cD5Ab;

    // 交易 Token A -> Token B
    function swap(
        address _tokenIn,
        address _tokenOut,
        uint256 _amountIn,
        uint256 _amountOutMin,
        address _to
    ) external {
        IERC20(_tokenIn).approve(address(this), _amountIn);

        // 1. 将 Token A 转入 此合约
        IERC20(_tokenIn).transferFrom(msg.sender, address(this), _amountIn);
        // 2. 授权 Token A 给 uniswap 的 router , 让其可以交换使用这部分Token A
        IERC20(_tokenIn).approve(UNISWAP_V2_ROUTER, _amountIn);

        // 3. 交易路径设置:  最简单的路径 是  A -> WETH -> B
        address[] memory path;
        if (_tokenIn == WETH || _tokenOut == WETH) {
            // 如果其中一个Token 是 WETH 那么, 只需要两段路由
            path = new address[](2);
            path[0] = _tokenIn;
            path[1] = _tokenOut;
        } else {
            // 否则, 就是三段路由, 通过WETH转换
            path = new address[](3);
            path[0] = _tokenIn;
            path[1] = WETH;
            path[2] = _tokenOut;
        }

        // 具体交易, 走 Uniswap Router 路由
        IUniswapV2Router(UNISWAP_V2_ROUTER).swapExactTokensForTokens(
            _amountIn,
            _amountOutMin, // 最小数量, 一般无要求 我们设置为 0 或 1
            path,
            _to,
            block.timestamp
        );
    }
}

// Router 接口
interface IUniswapV2Router {
    // 主要交易函数
    function swapExactTokensForTokens(
        uint256 amountIn,
        uint256 amountOutMin,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external returns (uint256[] memory amounts);
}

// ERC20 接口
interface IERC20 {
    function totalSupply() external view returns (uint256);

    function balanceOf(address account) external view returns (uint256);

    function transfer(address recipient, uint256 amount)
        external
        returns (bool);

    function allowance(address owner, address spender)
        external
        view
        returns (uint256);

    // 授权 Token
    function approve(address spender, uint256 amount) external returns (bool);

    // 转移 Token
    function transferFrom(
        address sender,
        address recipient,
        uint256 amount
    ) external returns (bool);
}