// SPDX-License-Identifier: MIT

pragma solidity 0.8.11;

contract ERC20Mock {
    event Transfer(address indexed addressFrom, address indexed addressTo, uint256 someValue);

    function test() external {
        emit Transfer(address(0), address(this), 54321);
    }
}