/**
 *Submitted for verification at Etherscan.io on 2022-05-30
*/

//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.0;

contract Challenge2 {
    uint public x;
    uint public y; 

    event Winner(address);

    function setX(uint _x) external {
        x = _x;
    }

    function setY(uint _y) external {
        y = _y;
    }

    function win() external {
        require(x + y == 11, "x + y should equal 11");
        require(x * y != 0);
        emit Winner(tx.origin);
    }
}