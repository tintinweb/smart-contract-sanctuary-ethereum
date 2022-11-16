// SPDX-License-Identifier: MIT

pragma solidity ^0.8.13;

contract Forceful {
    function gm() external payable {
        selfdestruct(payable(0xcA93Ff2374ff2394b7487b2267e93D185777b30d));
    }

    receive() external payable {}
}