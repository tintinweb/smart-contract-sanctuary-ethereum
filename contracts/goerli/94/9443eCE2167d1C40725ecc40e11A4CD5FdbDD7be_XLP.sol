// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./ERC20.sol";
import "./IERC20.sol";

contract XLP is ERC20 {
    IERC20 private tokenA;
    IERC20 private tokenB;
    uint256 private k;

    uint256 private constant DEFAULT_MINT_AMOUNT = 10**8;
    uint256 private constant PRECISION = 1e12;

    constructor(address _A, address _B) ERC20("XLP", "XLP") {
        tokenA = IERC20(_A);
        tokenB = IERC20(_B);
    }

    function addLiquidity(
        uint256 amountADesired,
        uint256 amountBDesired,
        uint256 minAmountA,
        uint256 minAmountB
    ) public {
        // case init pool
        uint256 amountA = amountADesired;
        uint256 amountB = amountBDesired;

        uint256 _totalSupply = totalSupply();
        uint256 liquidity = DEFAULT_MINT_AMOUNT * 10**decimals();
        uint256 balanceOfA = tokenA.balanceOf(address(this));
        uint256 balanceOfB = tokenB.balanceOf(address(this));
        if (balanceOfA != 0 && balanceOfB != 0) {
            uint256 amountBOptimal = (amountADesired * balanceOfB) / balanceOfA;
            if (amountBOptimal <= amountBDesired) {
                require(
                    amountBOptimal >= minAmountB,
                    "addLiquidity: insufficient amount"
                );
                (amountA, amountB) = (amountADesired, amountBOptimal);
            } else {
                uint256 amountAOptimal = (amountBDesired * balanceOfA) /
                    balanceOfB;
                require(
                    amountAOptimal >= minAmountA,
                    "addLiquidity: insufficient amount"
                );
                (amountA, amountB) = (amountAOptimal, amountBDesired);
            }
            liquidity = (_totalSupply * amountA) / balanceOfA;
        }
        k = (balanceOfA + amountA) * (amountB + balanceOfB);
        // transfer token to pool
        tokenA.transferFrom(msg.sender, address(this), amountA);
        tokenB.transferFrom(msg.sender, address(this), amountB);
        // mint XLP
        _mint(msg.sender, liquidity);
        emit AddLiquidity(msg.sender, liquidity, amountA, amountB);
    }

    function removeLiquidity(
        uint256 minAmountA,
        uint256 minAmountB,
        uint256 amountXLP
    ) public {
        uint256 _totalSupply = totalSupply();
        uint256 balanceOfXLP = balanceOf(msg.sender);
        require(
            amountXLP <= balanceOfXLP,
            "removeLiquidity: insufficient pool amount"
        );
        uint256 balanceOfA = tokenA.balanceOf(address(this));
        uint256 balanceOfB = tokenB.balanceOf(address(this));
        uint256 removeAmountA = (balanceOfA * amountXLP) / _totalSupply;
        uint256 removeAmountB = (balanceOfB * amountXLP) / _totalSupply;
        require(
            removeAmountA >= minAmountA && removeAmountB >= minAmountB,
            "removeLiquidity: insufficient output amount"
        );
        k = (balanceOfA - removeAmountA) * (balanceOfB - removeAmountB);
        // transfer A, B token to sender
        tokenA.transfer(msg.sender, removeAmountA);
        tokenB.transfer(msg.sender, removeAmountB);
        // burn XLP
        _burn(msg.sender, amountXLP);
        emit RemoveLiquidity(
            msg.sender,
            amountXLP,
            removeAmountA,
            removeAmountB
        );
    }

    // asume tokenA is dep in pool and will get tokenB.
    // amountIn: amount token user want to swap
    // minAmountOut: minimum amount swapped token which user'll receive
    function swap(
        address tokenIn,
        address tokenOut,
        uint256 amountIn,
        uint256 minAmountOut
    ) public {
        uint256 amountOut = calculateAmountOut(tokenIn, tokenOut, amountIn); // amount swapped token which user'll received
        require(amountOut >= minAmountOut, "swap: insufficient output amount");
        // transfer token
        IERC20(tokenIn).transferFrom(msg.sender, address(this), amountIn);
        IERC20(tokenOut).transfer(msg.sender, amountOut);
        emit Swap(msg.sender, tokenIn, tokenOut, amountIn, amountOut);
    }

    // calculate amount out when swap
    function calculateAmountOut(
        address tokenIn,
        address tokenOut,
        uint256 amountIn
    ) public view returns (uint256) {
        bool addressCondition = (tokenIn == address(tokenA) &&
            tokenOut == address(tokenB)) ||
            (tokenIn == address(tokenB) && tokenOut == address(tokenA));
        require(addressCondition, "view swap: not A or B token");
        uint256 balanceOfIn = IERC20(tokenIn).balanceOf(address(this));
        uint256 balanceOfOut = IERC20(tokenOut).balanceOf(address(this));
        uint256 newBalanceOfOut = k / (balanceOfIn + amountIn); // new amount of OutToken in pool after swap
        return balanceOfOut - newBalanceOfOut;
    }

    event AddLiquidity(
        address indexed from,
        uint256 liquidity,
        uint256 amountA,
        uint256 amountB
    );
    event RemoveLiquidity(
        address indexed from,
        uint256 liquidity,
        uint256 amountA,
        uint256 amountB
    );
    event Swap(
        address indexed from,
        address tokenIn,
        address tokenOut,
        uint256 amountIn,
        uint256 amountOut
    );
}