/**
 *Submitted for verification at Etherscan.io on 2022-02-12
*/

// SPDX-License-Identifier: MIT

pragma solidity >= 0.7.0 < 0.8.0;

contract EscribirEnBlockchain{
    string value;

    function Escribir(string calldata _value) public{
        value = _value;
    }

    function Leer() public view returns(string memory){
        return value;
    }


}