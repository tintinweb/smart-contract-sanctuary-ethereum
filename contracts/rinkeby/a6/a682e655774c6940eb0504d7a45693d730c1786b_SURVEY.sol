/**
 *Submitted for verification at Etherscan.io on 2022-09-23
*/

// SPDX-License-Identifier: GPL-3.0
// 20220922
pragma solidity 0.8.0;

/*
여러분은 설문조사기관에 근무하고 있습니다. 
피자를 좋아하는 사람, 싫어하는 사람, 햄버거를 좋아하는 사람, 싫어하는 사람의 숫자를 구해야합니다. 
각각의 음식을 좋아하는 사람과 싫어하는 사람의 숫자를 구하고 기록하는 컨트랙트를 구현하세요.
*/

contract SURVEY {

    uint pizzaLiker;
    uint pizzaHater;
    uint burgerLiker;
    uint burgerHater;

    function likePizza() public returns(uint) {
        pizzaLiker = pizzaLiker + 1;
        return pizzaLiker;
    }

    function likeBurger() public returns(uint) {
        burgerLiker = burgerLiker + 1;
        return burgerLiker;
    }

    function hatePizza() public returns(uint) {
        pizzaHater = pizzaHater + 1;
        return pizzaHater;
    }

    function hateBurger() public returns(uint) {
        burgerHater = burgerHater + 1;
        return burgerHater;
    }

}