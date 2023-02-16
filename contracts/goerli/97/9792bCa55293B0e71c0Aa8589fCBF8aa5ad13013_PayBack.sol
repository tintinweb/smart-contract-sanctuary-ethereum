/**
 *Submitted for verification at Etherscan.io on 2023-02-16
*/

// SPDX-License-Identifier: MIT

pragma solidity >=0.8.2 <0.9.0;

contract PayBack {

    mapping( uint256 => uint256 ) public x;

    function set(uint256 _x, uint256 _y) external {
        x[_x] = _y;
    }

}