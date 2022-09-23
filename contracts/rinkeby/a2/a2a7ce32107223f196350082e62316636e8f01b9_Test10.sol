/**
 *Submitted for verification at Etherscan.io on 2022-09-23
*/

//SPDX-License-Identifier: GPL-3.0

pragma solidity 0.8.0;

contract Test10{
    uint pizzaLikers;
    uint pizzaHaters;
    uint bugerLikers;
    uint bugerHaters;

    function ILikePizza() public returns(uint){
        return ++pizzaLikers;
    }
    function IHatePizza() public returns(uint){
        return ++pizzaHaters;
    }
    function ILikeBuger() public returns(uint){
        return ++bugerLikers;
    }
    function IHateBuger() public returns(uint){
        return ++bugerHaters;
    }
    function GetResult() public view returns(uint,uint,uint,uint){
        return (pizzaLikers,pizzaHaters,bugerLikers,bugerHaters);
    }
    
}