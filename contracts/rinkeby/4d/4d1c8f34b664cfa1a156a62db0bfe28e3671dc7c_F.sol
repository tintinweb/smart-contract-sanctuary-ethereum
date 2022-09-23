/**
 *Submitted for verification at Etherscan.io on 2022-09-23
*/

// SPDX-License-Identifier: GPL-3.0
// 20220923
pragma solidity 0.8.0;

contract F {
    // 피자를 좋아하는 사람, 싫어하는 사람, 햄버거를 좋아하는 사람, 싫어하는 사람의 숫자를 구해야합니다.
    uint pizzaL = 0;
    uint pizzaH = 0;
    uint hamburgerL = 0;
    uint hamburgerH = 0;

    // 각각의 음식을 좋아하는 사람과 싫어하는 사람의 숫자를 구하고 기록하는 컨트랙트를 구현하세요.
    function lovePizza() public returns(uint){
        pizzaL += 1;
        return pizzaL;
    }

    function hatePizza() public returns(uint){
        pizzaH += 1;
        return pizzaH;
    }

    function loveHamburger() public returns(uint){
        hamburgerL += 1;
        return hamburgerL;
    }

    function hateHamburger() public returns(uint){
        hamburgerH += 1;
        return hamburgerH;
    }

    function pizzaL_pizzaH_hamburgerL_hamburgerH() public view returns(uint, uint, uint, uint) {
        return (pizzaL, pizzaH, hamburgerL, hamburgerH);
    }
}