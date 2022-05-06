/**
 *Submitted for verification at Etherscan.io on 2022-05-06
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.7;
contract Math{
    function add(uint zahl1, uint zahl2) public view returns(uint){
        return zahl1 + zahl2;
    }
    function sub( uint zahl1, uint zahl2) public view returns(uint){
        return zahl1 - zahl2;
    }
    function div(uint zahl1, uint zahl2) public view returns(uint){
        return zahl1 / zahl2;
    }
function mult( uint zahl1, uint zahl2) public view returns(uint){
    return zahl1 * zahl2;
}

}