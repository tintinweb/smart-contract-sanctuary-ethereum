/**
 *Submitted for verification at Etherscan.io on 2022-12-26
*/

// SPDX-License-Identifier: MIT

pragma solidity 0.8.16;

contract Greeting {
    string public x;

    uint256 public y;

    event SetGreeting(string x);
    event SetY(uint256 y);

    function setGreeting(string memory _x) public {
        x = _x;

        emit SetGreeting(_x);
    }

    function setY(uint256 _y) public {
        y = _y;

        emit SetY(_y);
    }
}