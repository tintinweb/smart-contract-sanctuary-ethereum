// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./ERC20.sol";
import "./IERC20.sol";

contract XLP is ERC20 {
    ERC20 private tokenA;
    ERC20 private tokenB;
    uint256 private k;
    uint256 private _initialMint;

    uint256 private constant DEFAULT_MINT_AMOUNT = 10**8;
    uint256 private constant PRECISION = 1e12;

    constructor(ERC20 _A, ERC20 _B) ERC20("XLP", "XLP") {
        tokenA = _A;
        tokenB = _B;
        _initialMint = DEFAULT_MINT_AMOUNT * 10**decimals();
    }

    function addLiquidity(uint256 amountA, uint256 amountB) public {
        uint256 _totalSupply = totalSupply();
        uint256 xlpMintAmount = _initialMint;
        uint256 balanceOfA = tokenA.balanceOf(address(this));
        uint256 balanceOfB = tokenB.balanceOf(address(this));
        // keep pool with same ratio A and B
        require(
            amountA * balanceOfB == balanceOfA * amountB,
            "addLiquidity: insufficient amount"
        );

        // calculate amount allow to add. Asume A is a mark.
        // A pool is existed if both balance A and B are not zero.
        if (balanceOfA == 0) {
            k = amountA * amountB;
            tokenA.transferFrom(msg.sender, address(this), amountA);
            tokenB.transferFrom(msg.sender, address(this), amountB);
        } else {
            uint256 allowAmountB = (amountA * balanceOfB) / balanceOfA;
            k = (balanceOfA + amountA) * (allowAmountB + balanceOfB);
            xlpMintAmount = (_totalSupply * amountA) / balanceOfA;
            tokenA.transferFrom(msg.sender, address(this), amountA);
            tokenB.transferFrom(msg.sender, address(this), allowAmountB);
        }
        // mint XLP
        _mint(msg.sender, xlpMintAmount);
        emit AddLiquidity(msg.sender, amountA, amountB);
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
            "removeLiquidity: exceed pool amount"
        );
        uint256 balanceOfA = tokenA.balanceOf(address(this));
        uint256 balanceOfB = tokenB.balanceOf(address(this));
        uint256 allowRemoveAmountA = (balanceOfA * amountXLP) / _totalSupply;
        uint256 allowRemoveAmountB = (balanceOfB * amountXLP) / _totalSupply;
        require(
            allowRemoveAmountA >= minAmountA &&
                allowRemoveAmountB >= minAmountB,
            "removeLiquidity: insufficient output amount"
        );
        k =
            (balanceOfA - allowRemoveAmountA) *
            (balanceOfB - allowRemoveAmountB);
        // transfer A, B token to sender
        tokenA.transfer(msg.sender, allowRemoveAmountA);
        tokenB.transfer(msg.sender, allowRemoveAmountB);
        // burn XLP
        _burn(msg.sender, amountXLP);
        emit RemoveLiquidity(msg.sender, amountXLP);
    }

    // asume tokenA is dep in pool and will get tokenB.
    // amountIn: amount token user want to swap
    // minAmountOut: minimum amount swapped token user received
    function swap(
        address tokenIn,
        address tokenOut,
        uint256 amountIn,
        uint256 minAmountOut
    ) public {
        bool addressCondition = (tokenIn == address(tokenA) &&
            tokenOut == address(tokenB)) ||
            (tokenIn == address(tokenB) && tokenOut == address(tokenA));
        require(addressCondition, "swap: not A or B token");
        uint256 balanceOfIn = IERC20(tokenIn).balanceOf(address(this));
        uint256 balanceOfOut = IERC20(tokenOut).balanceOf(address(this));
        uint256 amountOut = k / (balanceOfIn + amountIn); // new amount of tokenOut in pool
        require(
            balanceOfOut - amountOut >= minAmountOut,
            "swap: insufficient output amount"
        );
        // transfer token
        IERC20(tokenIn).transferFrom(msg.sender, address(this), amountIn);
        IERC20(tokenOut).transfer(msg.sender, balanceOfOut - amountOut);
        emit Swap(msg.sender, tokenIn, tokenOut, amountIn, balanceOfOut - amountOut);
    }

    // calculate amount out when swap
    function viewAmountOut(
        address tokenIn,
        address tokenOut,
        uint256 amountIn
    ) public view returns (uint256) {
        bool addressCondition = (tokenIn == address(tokenA) &&
            tokenOut == address(tokenB)) ||
            (tokenIn == address(tokenB) && tokenOut == address(tokenA));
        require(addressCondition, "view swap: not A or B token");
        uint256 balanceOfIn = IERC20(tokenIn).balanceOf(address(this));
        uint256 amountOut = k / (balanceOfIn + amountIn);
        return amountOut;
    }

    event AddLiquidity(address indexed from, uint256 amountA, uint256 amountB);
    event RemoveLiquidity(address indexed from, uint256 amountXLP);
    event Swap(
        address indexed from,
        address tokenA,
        address tokenB,
        uint256 amountIn,
        uint256 amountOut
    );
}