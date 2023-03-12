// SPDX-License-Identifier: GPL-3.0

pragma solidity >=0.8.2 <0.9.0;

contract Counter {

    uint256 number = 0;
    address owner;
    function add(uint256 num) public {
        number = number + num;
    }
    function getNum() public view returns (uint256){
        return number;
    }
}