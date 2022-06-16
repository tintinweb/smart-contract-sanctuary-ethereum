// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract HelloWorld {
    function hello() external pure returns (string memory){
        return "hello! :)";
    }

    function world() external pure returns (string memory){
        return "world! :)";
    }
}