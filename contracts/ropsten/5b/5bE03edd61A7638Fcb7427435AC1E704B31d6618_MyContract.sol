// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.0;

contract MyContract {
    uint[] numbers;

    function readNumbers() public view returns (uint[] memory){
        return numbers;
    }

    uint[] public numbers2;


}