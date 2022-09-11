/**
 *Submitted for verification at Etherscan.io on 2022-09-10
*/

//SPDX-License-Identifier: UNLICENSED

pragma solidity ^0.8.0;

contract HelloWorld
{

    function sayhello() public pure returns (string memory)
    {
        return "Hello Paco";
    }

    function saybye() public pure returns (string memory)
    {
        return "Adios Paco";
    }

    function getname(string memory firstname, string memory lastname) external pure returns (string memory)
    {
        return string.concat("Hola, ",firstname," ",lastname);

    }

}