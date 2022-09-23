/**
 *Submitted for verification at Etherscan.io on 2022-09-23
*/

// SPDX-License-Identifier: GPL-3.0
// 20220922
pragma solidity 0.8.0;

contract vote {
    uint pizza;
    uint pizzaN;
    uint hamberger;
    uint hambergerN;
    
    function readVote() public view returns (uint, uint, uint, uint){
        return (pizza, pizzaN, hamberger, hambergerN);
    }

    function pizzaLike() public returns(uint,uint) {
        pizza = pizza + 1;
        return (pizza, pizzaN);
    }
    function pizzaDislike() public returns(uint,uint) {
        pizzaN = pizzaN + 1;
        return (pizza, pizzaN);
    }
    function hanbergerlike() public returns(uint,uint) {
        hamberger = hamberger+ 1;
        return (hamberger,hambergerN);
    }
    function hambergerDislike() public returns(uint,uint) {
        hambergerN = hambergerN + 1;
        return (hamberger,hambergerN);
    }

}