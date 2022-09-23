/**
 *Submitted for verification at Etherscan.io on 2022-09-23
*/

// SPDX-License-Identifier: GPL-3.0
// 20220922
pragma solidity 0.8.0;

contract Research {
    uint hambergerHater = 0;
    uint hambergerLover = 0;
    uint pizzaHater = 0;
    uint pizzaLover = 0;
    
    function hateHamberger() public {
        hambergerHater++;
    }

    function loveHamberger() public {
        hambergerLover++;
    }

    function hatePizza() public {
        pizzaHater++;
    }

    function lovePizza() public {
        pizzaLover++;
    }


}