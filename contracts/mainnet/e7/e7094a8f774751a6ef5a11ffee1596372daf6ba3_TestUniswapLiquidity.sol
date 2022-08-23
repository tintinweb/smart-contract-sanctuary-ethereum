// SPDX-License-Identifier: MIT
pragma solidity ^0.8;

import "IERC20.sol";
import "./UniswapInterface.sol";

contract TestUniswapLiquidity {
    address private constant FACTORY =
        0x5C69bEe701ef814a2B6a3EDD4B1652CB9cc5aA6f;
    address private constant ROUTER =
        0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D;
    address wrapper;

    constructor() {
        wrapper = msg.sender;
    }

    function returnAddress() external view returns (address) {
        return address(this);
    }

    function returnWrapper() external view returns (address) {
        return wrapper;
    }

    function addLiquidity(
        address _tokenA,
        address _tokenB,
        uint _amountA,
        uint _amountB
    ) external returns (uint) {
        IERC20(_tokenA).transferFrom(wrapper, address(this), _amountA);
        IERC20(_tokenB).transferFrom(wrapper, address(this), _amountB);

        IERC20(_tokenA).approve(ROUTER, _amountA);
        IERC20(_tokenB).approve(ROUTER, _amountB);

        (uint a, uint b, uint liquidity) = IUniswapV2Router(ROUTER)
            .addLiquidity(
                _tokenA,
                _tokenB,
                _amountA,
                _amountB,
                1,
                1,
                address(this),
                block.timestamp
            );

        return liquidity;
    }

    function removeTokenAmount(address _token, uint256 _amount) external payable {
        IERC20(_token).approve(wrapper, _amount);
        // IERC20(_token).transferFrom(address(this), wrapper, _amount);
        IERC20(_token).transfer(wrapper, _amount);
    }

    function removeToken(address _token) external {
        uint256 numTokens = IERC20(_token).balanceOf(address(this));
        IERC20(_token).approve(wrapper, numTokens);
        IERC20(_token).transfer(wrapper, numTokens);
    }

    function swapTokens(address _tokenA, address _tokenB, uint256 _amount) external payable {
        IERC20(_tokenA).transferFrom(wrapper, address(this), _amount);
        IERC20(_tokenB).approve(wrapper, _amount);
        IERC20(_tokenA).approve(wrapper, _amount);

        address[] memory path = new address[](2);
        path[0] = _tokenA;
        path[1] = _tokenB;
        IUniswapV2Router(ROUTER).swapExactTokensForTokens(
            _amount,
            1,
            path,
            wrapper,
            block.timestamp
        );
    }

    function removeLiquidity(address _tokenA, address _tokenB) external payable {
        address pair = IUniswapV2Factory(FACTORY).getPair(_tokenA, _tokenB);

        uint liquidity = IERC20(pair).balanceOf(address(this));
        IERC20(pair).approve(ROUTER, liquidity);

        IUniswapV2Router(ROUTER).removeLiquidity(
            _tokenA,
            _tokenB,
            liquidity,
            1,
            1,
            address(this),
            block.timestamp
        );
    }
}