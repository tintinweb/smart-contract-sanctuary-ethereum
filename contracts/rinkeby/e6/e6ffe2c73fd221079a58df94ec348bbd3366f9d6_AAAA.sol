/**
 *Submitted for verification at Etherscan.io on 2022-09-23
*/

/**
 *Submitted for verification at Etherscan.io on 2022-09-23
*/

// SPDX-License-Identifier: GPL-3.0

pragma solidity 0.8.0;

/*
여러분은 설문조사기관에 근무하고 있습니다. 
피자를 좋아하는 사람, 싫어하는 사람, 햄버거를 좋아하는 사람, 싫어하는 사람의 숫자를 구해야합니다. 
각각의 음식을 좋아하는 사람과 싫어하는 사람의 숫자를 구하고 기록하는 컨트랙트를 구현하세요.
*/
contract AAAA {
    uint hamGood;
    uint hamBad;
    uint pizGood;
    uint pizBad;

    function likeHam() public{
        hamGood = hamGood +1; // ++hamGood, hamGood+=1 로도 대체가능,  
    }

    function unlikeHam() public{
        hamBad = hamBad+1;
    }

    function likePiz() public {
        pizGood = pizGood+1;
    }

    function unlikePiz() public {
        pizBad = pizBad+1;
    }
    
    function getLikeUnlike() public view returns(uint, uint, uint, uint) {
        return(hamGood, hamBad, pizGood, pizBad);
    }
}