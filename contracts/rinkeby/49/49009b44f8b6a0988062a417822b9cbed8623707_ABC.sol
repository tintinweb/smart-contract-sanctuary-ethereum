/**
 *Submitted for verification at Etherscan.io on 2022-09-23
*/

// SPDX-License-Identifier: GPL-3.0
// 20220923
pragma solidity 0.8.0;


contract ABC {

    uint hamburgerlike=0;
    uint hamburgerhate=0;
    uint pizzalike=0;
    uint pizzahate = 0;


    function Hlike() public returns(uint) {
        hamburgerlike=hamburgerlike+1 ;
        return hamburgerlike;
    } 

    function Hhate() public returns(uint) {
        hamburgerhate=hamburgerhate+1;
        return hamburgerhate;
    } 
    function Plike() public returns(uint) {
        pizzalike=pizzalike+1;
        return pizzalike;
    } 

    function Phate() public returns(uint) {
        pizzahate=pizzahate+1;
        return pizzahate;
    } 
    
}