/**
 *Submitted for verification at Etherscan.io on 2022-09-23
*/

// SPDX-License-Identifier: GPL-3.0
//20220922
pragma solidity 0.8.0;

contract SURVEY {
    uint pizzaLike;
    uint pizzaDislike;
    uint burgerLike;
    uint burgerDislike;

    function pizLike() public {
        pizzaLike = pizzaLike+1;
    }

    function pizDislike() public {
        pizzaDislike = pizzaDislike+1;
    }

    function burgLike() public {
        burgerLike = burgerLike+1;
    }

    function burgDislike() public {
        burgerDislike = burgerDislike+1;
    }

    function getResult() public view returns(uint, uint, uint, uint){
        return(pizzaLike, pizzaDislike, burgerLike, burgerDislike);
    }
}