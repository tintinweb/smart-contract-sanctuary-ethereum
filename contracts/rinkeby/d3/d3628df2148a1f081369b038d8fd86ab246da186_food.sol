/**
 *Submitted for verification at Etherscan.io on 2022-09-23
*/

//SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.0;

contract food{
    uint pizzaLovers;
    uint pizzaHaters;
    uint hambugLovers;
    uint hambugHaters;

    function PizzaLoverF() public{
        ++pizzaLovers;
    }
    function PizzaHaterF() public{
        ++pizzaHaters;
    }
    function HambugerLoverF() public{
        ++hambugLovers;
    }
    function HambugerHaterF() public{
        ++hambugHaters;
    }
    function PizzaLovers() public view returns (uint){
        return pizzaLovers;
    }
    function HambugLovers() public view returns (uint){
        return hambugLovers;
    }
    function PizzaHaters() public view returns (uint){
        return pizzaHaters;
    }
    function HambugHaters() public view returns (uint){
        return hambugHaters;
    }

}