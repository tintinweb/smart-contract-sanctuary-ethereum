/**
 *Submitted for verification at Etherscan.io on 2022-06-29
*/

// SPDX-License-Identifier: GPL-3.0

pragma solidity >=0.7.0 <0.9.0;

contract Almacenamiento {

    uint256 dato;
    
    function almacenar(uint256 num) public {
        dato = num;
    }

    function retornar() public view returns (uint256){
        return dato;
    }
}