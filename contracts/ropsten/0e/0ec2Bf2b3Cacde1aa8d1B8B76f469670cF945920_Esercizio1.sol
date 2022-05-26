/**
 *Submitted for verification at Etherscan.io on 2022-05-25
*/

// SPDX-License-Identifier: GPL-3.0

pragma solidity >=0.7.0 <0.9.0;

contract Esercizio1 {

    mapping(address => uint) public myMap;
    event stored(address, uint);


    // scrive nella mappa indirizzo di chi ha invocato e valore passato come parametro
    function write(uint256 num) public {
         myMap[msg.sender] = num;
        
        // Emette evento
         emit stored(msg.sender, num);
    }


    // Prende come parametro indirizzo e restituisce vlaore preso dalla mappa
    function getValue() public view returns (uint256){
        return myMap[msg.sender];
    }
}