/**
 *Submitted for verification at Etherscan.io on 2022-05-15
*/

// SPDX-License-Identifier: GPL-3.0

pragma solidity >=0.7.0 <0.8.0;

contract write{

    string name;

    function Escribir(string calldata _name) public {
            name = _name;

    }
   function Leer() public view returns(string memory){
            return name;

    }

}