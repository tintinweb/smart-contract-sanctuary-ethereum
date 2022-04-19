/**
 *Submitted for verification at Etherscan.io on 2022-04-19
*/

// SPDX-License-Identifier: MIT


pragma solidity 0.8.4;

contract MyContract {

string public hello;

    constructor()
    {
        hello = "Hola yesi te amo";
    }
    function setHello(string memory _hello) public{
        hello = _hello;
    }
}