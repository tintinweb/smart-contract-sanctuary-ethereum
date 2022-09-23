/**
 *Submitted for verification at Etherscan.io on 2022-09-23
*/

// SPDX-License-Identifier: GPL-3.0
// 20220922
pragma solidity 0.8.0;

contract Voting {
    uint pizzaLike = 0;
    uint pizzaDislike = 0;
    uint hamLike = 0;
    uint hamDislike = 0;

    /////////////////////
    /* WRITE Functions */
    /////////////////////
    function pLike() public returns(uint){
        pizzaLike = pizzaLike + 1;
        return pizzaLike;
    }

    function pDislike() public returns(uint){
        pizzaDislike = pizzaDislike + 1;
        return pizzaDislike;
    }

    function hLike() public returns(uint){
        hamLike = hamLike + 1;
        return hamLike;
    }

    function hDislike() public returns(uint){
        hamDislike = hamDislike + 1;
        return hamDislike;
    }

    ////////////////////
    /* READ Functions */
    ////////////////////
    function getPLike() public view returns(uint){
        return pizzaLike;
    }

    function getPDislike() public view returns(uint){
        return pizzaDislike;
    }

    function getHLike() public view returns(uint){
        return hamLike;
    }

    function getHDislike() public view returns(uint){
        return hamDislike;
    }
}