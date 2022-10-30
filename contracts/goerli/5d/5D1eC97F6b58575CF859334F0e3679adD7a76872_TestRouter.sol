// SPDX-Licence-Identifier: MIT

pragma solidity ^0.8.0;

contract TestRouter {
    constructor() {}

    event Swap(
        address indexed sender,
        uint amount0In,
        address _tokenIn,
        address indexed to
    );

    function swap(
        uint amount0In,
        address _tokenIn,
        address to
    ) external {
        emit Swap(msg.sender, amount0In, _tokenIn, to);
    }
}