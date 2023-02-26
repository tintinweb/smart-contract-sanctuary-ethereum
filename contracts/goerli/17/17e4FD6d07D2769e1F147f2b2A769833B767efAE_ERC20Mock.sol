// SPDX-License-Identifier: MIT

pragma solidity 0.8.11;

contract ERC20Mock {
    event ApprovalForAll(address indexed account, address indexed operator, bool approved);

    function test() external {
        emit ApprovalForAll(address(0), address(this), true);
    }
}