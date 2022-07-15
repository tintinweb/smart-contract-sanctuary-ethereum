/**
 *Submitted for verification at Etherscan.io on 2022-07-14
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.15;

contract Left {

    // function getPrice(uint256 value, uint256 t, uint256 halfLife) public pure returns (uint256) {
    //     value >>= (t / halfLife);
    //     t %= halfLife;
    //     uint256 price = value - value * t / halfLife / 2;
    //     return price;
    // }

    // function total() public pure returns (uint256) {
    //     uint256 sum = 0;
    //     uint256 val = 1;
    //     for (uint256 i = 0; val > 0; i++) {
    //         val = getPrice(1e5, i, 60);
    //         sum += val;
    //     }
    //     return sum;
    // }
    address[] public arr;
    mapping(address => uint256) public stuff;

    function createArray(uint256 num) public {
        arr.push(address(0));
        for (uint256 i = 0; i < num; i++) {
            arr.push(address(0x8b1A1aF63bb9b3730f62c56bDa272BCC69dF4CC7));
        }
    }

    function equ() public {
        uint256 payment = address(this).balance / arr.length;
        for (uint256 i = 0; i < arr.length; i++) {
            stuff[arr[0]] = payment;
        }
    }

    function plus(uint256 plu) public {
        for (uint256 i = 0; i < arr.length; i++) {
            stuff[arr[0]] += plu;
        }
    }

    function minus(uint256 minu) public {
        for (uint256 i = 0; i < arr.length; i++) {
            stuff[arr[0]] -= minu;
        }
    }

    receive() external payable {}

}