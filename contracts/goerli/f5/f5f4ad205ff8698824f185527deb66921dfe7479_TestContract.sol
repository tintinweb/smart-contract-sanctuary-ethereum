/**
 *Submitted for verification at Etherscan.io on 2022-02-24
*/

//SPDX-License-Identifier: MIT

pragma solidity 0.8.4;

contract TestContract {
    string public hello;

    constructor()
    {
        hello = "Hola mundo";
    
    }

    function setHello(string memory _hello) public {
        hello = _hello;
    }
}