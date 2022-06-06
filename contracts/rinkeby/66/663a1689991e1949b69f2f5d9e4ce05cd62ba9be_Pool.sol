/**
 *Submitted for verification at Etherscan.io on 2022-06-05
*/

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.9;

interface IERC20 {
    event Transfer(address indexed from, address indexed to, uint256 value);

    event Approval(
        address indexed owner,
        address indexed spender,
        uint256 value
    );

    function totalSupply() external view returns (uint256);

    function balanceOf(address account) external view returns (uint256);

    function transfer(address to, uint256 amount) external returns (bool);

    function allowance(address owner, address spender)
        external
        view
        returns (uint256);

    function approve(address spender, uint256 amount) external returns (bool);

    function mint(address to, uint256 amount) external returns (bool);

    function transferFrom(
        address from,
        address to,
        uint256 amount
    ) external returns (bool);
}



pragma solidity ^0.8.9;


contract Pool {
    address public factory;
    address public tokenA;
    address public tokenB;
    address public LPToken;
    uint256 public reservesTokenA;
    uint256 public reservesTokenB;
    uint256 private k;

    constructor(
        address tokenAC,
        address tokenBC,
        address LPTokenC
    ) {
        factory = msg.sender;
        tokenA = tokenAC;
        tokenB = tokenBC;
        LPToken = LPTokenC;
    }

    function _getAmountOut(address tokenFrom, uint256 amountFrom)
        private
        view
        returns (uint256)
    {
        uint256 _amountA = tokenFrom == tokenA ? amountFrom : 0;
        uint256 _amountB = tokenFrom == tokenB ? amountFrom : 0;
        uint256 amountOut;
        if (_amountB == 0) {
            uint256 newReservesTokenA = reservesTokenA + amountFrom;
            amountOut = newReservesTokenA / k;
        }
        if (_amountA == 0) {
            uint256 newReservesTokenB = reservesTokenB + amountFrom;
            amountOut = newReservesTokenB / k;
        }

        return amountOut;
    }

    function addLiquidity(
        address tokenAL,
        address tokenBL,
        uint256 amountTokenA,
        uint256 amountTokenB
    ) public payable {
        IERC20(tokenAL).transferFrom(msg.sender, address(this), amountTokenA);
        reservesTokenA = reservesTokenA + amountTokenA;

        IERC20(tokenBL).transferFrom(msg.sender, address(this), amountTokenB);
        reservesTokenB = reservesTokenB + amountTokenB;

        k = amountTokenA * amountTokenB;

        IERC20(LPToken).mint(msg.sender, amountTokenA);
    }

    function swap(address tokenFrom, uint256 amountFrom) public payable {
        address tokenTo = tokenFrom == tokenA ? tokenB : tokenA;

        uint256 amountOut = _getAmountOut(tokenFrom, amountFrom);

        IERC20(tokenFrom).transferFrom(msg.sender, address(this), amountFrom);
        IERC20(tokenTo).transfer(msg.sender, amountOut);
    }
}