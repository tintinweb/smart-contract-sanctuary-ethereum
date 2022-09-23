/**
 *Submitted for verification at Etherscan.io on 2022-09-23
*/

// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.0;

contract Test0923 {

     uint pizzaLikeNumber ;
     uint pizzaHateNumber ;
     uint HamberLikeNumber ;
     uint HamberHateNumber ;

    function likePizza() public  {
         pizzaLikeNumber = pizzaLikeNumber + 1;
    }
    function hatePizza() public {
        pizzaHateNumber = pizzaHateNumber + 1;
    }
    function getPizzaHateN()public view returns (uint){
        return pizzaHateNumber;
    }
    function getPizzaLikeN()public view returns (uint){
        return pizzaLikeNumber;
    }
    
    function likeHamber() public  {
         HamberLikeNumber = HamberLikeNumber + 1;
    }
    function hateHamber() public {
        HamberHateNumber = HamberHateNumber + 1;
    }
    function getHamberHateN()public view returns (uint){
        return HamberHateNumber;
    }
    function getHamberLikeN()public view returns (uint){
        return HamberLikeNumber;
    }
}