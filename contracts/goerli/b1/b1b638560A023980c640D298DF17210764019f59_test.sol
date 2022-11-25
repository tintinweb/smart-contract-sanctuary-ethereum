/**
 *Submitted for verification at Etherscan.io on 2022-11-25
*/

// SPDX-License-Identifier: GPL-3.0

pragma solidity >=0.7.0 <0.9.0;

contract test {
    int y;
    function counter() public {
        y++;
    }
    function getY() public view returns(int) {
        return y;
    }
}