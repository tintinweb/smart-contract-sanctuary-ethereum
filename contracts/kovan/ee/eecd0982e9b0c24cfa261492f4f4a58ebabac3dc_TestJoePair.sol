/**
 *Submitted for verification at Etherscan.io on 2022-06-03
*/

pragma solidity =0.6.12;
// SPDX-License-Identifier: GPL-3.0

contract TestJoePair {
    address sender;
    uint256 amount0In;
    uint256 amount1In;
    uint256 amount0Out;
    uint256 amount1Out;
    address to;

    address public token0;
    address public token1;

    uint112 private reserve0;
    uint112 private reserve1;
    uint32 private blockTimestampLast;

    event Swap(
        address indexed sender,
        uint256 amount0In,
        uint256 amount1In,
        uint256 amount0Out,
        uint256 amount1Out,
        address indexed to
    );

    function setSwapArgs(
        address _sender,
        uint256 _amount0In,
        uint256 _amount1In,
        uint256 _amount0Out,
        uint256 _amount1Out,
        address _to
    ) external {
        sender = _sender;
        amount0In = _amount0In;
        amount1In = _amount1In;
        amount0Out = _amount0Out;
        amount1Out = _amount1Out;
        to = _to;
    }

    function emitSwap() external {
        emit Swap(
            sender,
            amount0In,
            amount1In,
            amount0Out,
            amount1Out,
            to
        );
    }

    function setTokens(address _token0, address _token1) external {
        token0 = _token0;
        token1 = _token1;
    }

    function setReserves(uint112 _reserve0, uint112 _reserve1, uint32 _blockTimestampLast) external {
        reserve0 = _reserve0;
        reserve1 = _reserve1;
        blockTimestampLast = _blockTimestampLast;
    }

    function getReserves()
        public
        view
        returns (
            uint112 _reserve0,
            uint112 _reserve1,
            uint32 _blockTimestampLast
        )
    {
        _reserve0 = reserve0;
        _reserve1 = reserve1;
        _blockTimestampLast = blockTimestampLast;
    }
}