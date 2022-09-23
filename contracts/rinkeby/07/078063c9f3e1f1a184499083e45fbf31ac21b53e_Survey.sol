/**
 *Submitted for verification at Etherscan.io on 2022-09-23
*/

// SPDX-License-Identifier: GPL-3.0
// 20220923
pragma solidity 0.8.0;

contract Survey {
    // read, write test
    /*
        여러분은 설문조사기관에 근무하고 있습니다. 
        피자를 좋아하는 사람, 싫어하는 사람, 햄버거를 좋아하는 사람, 싫어하는 사람의 숫자를 구해야합니다. 
        각각의 음식을 좋아하는 사람과 싫어하는 사람의 숫자를 구하고 기록하는 컨트랙트를 구현하세요.
    */
    uint pizzaLike = 0;
    uint pizzaHate = 0;
    uint hamburgerLike = 0;
    uint hamburgerHate = 0;

    // 숫자 기록하기
    function setLikePizza() public returns (uint) {
        pizzaLike++;
        return pizzaLike;
    }

    function setHatePizza() public returns (uint) {
        pizzaHate++;
        return pizzaHate;
    }

    function setLikeHamburger() public returns (uint) {
        hamburgerLike++;
        return hamburgerLike;
    }

    function setHateHamburger() public returns (uint) {
        hamburgerHate++;
        return hamburgerHate;
    }

    // 결과 보기
    function getLikePizza() public view returns (uint) {
        return pizzaLike;
    }

    function getHatePizza() public view returns (uint) {
        return pizzaHate;
    }

    function getLikeHamburger() public view returns (uint) {
        return hamburgerLike;
    }

    function getHateHamburger() public view returns (uint) {
        return hamburgerHate;
    }

}