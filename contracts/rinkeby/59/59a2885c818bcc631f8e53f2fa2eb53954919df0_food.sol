/**
 *Submitted for verification at Etherscan.io on 2022-09-23
*/

// SPDX-License-Identifier: GPL-3.0
pragma solidity 0.8.0;

/*
여러분은 설문조사기관에 근무하고 있습니다. 피자를 좋아하는 사람, 싫어하는 사람, 햄버거를 좋아하는 사람, 싫어하는 사람의 숫자를 구해야합니다. 
각각의 음식을 좋아하는 사람과 싫어하는 사람의 숫자를 구하고 기록하는 컨트랙트를 구현하세요.
*/

contract food {
    uint a;
    uint b;
    uint c;
    uint d;

    function like_pizza() public returns(uint) {
        a = a + 1;
        return a;
    }

    function hate_pizza() public returns(uint) {
        b = b + 1;
        return a;
    }

    function like_burger() public returns(uint) {
        c = c + 1;
    }

    function hate_burger() public returns(uint) {
        d = d + 1;
    }

    function like_pizza_write()  public view returns(uint) {
        return a;
    }

    function hate_pizza_write()  public view returns(uint) {
        return b;
    }

    function like_burger_write()  public view returns(uint) {
        return c;
    }

    function hate_burger_write()  public view returns(uint) {
        return d;
    }

}