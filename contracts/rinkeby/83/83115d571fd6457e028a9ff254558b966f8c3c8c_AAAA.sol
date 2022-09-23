/**
 *Submitted for verification at Etherscan.io on 2022-09-23
*/

// SPDX-License-Identifier: GPL-3.0
// 20220923
pragma solidity 0.8.0;

/*
여러분은 설문조사기관에 근무하고 있습니다.
 피자를 좋아하는 사람, 싫어하는 사람, 햄버거를 좋아하는 사람,
  싫어하는 사람의 숫자를 구해야합니다. 
  각각의 음식을 좋아하는 사람과 싫어하는 사람의 숫자를 구하고 
  기록하는 컨트랙트를 구현하세요.
*/

contract AAAA {
    uint HamGood;
    uint HamBad;
    uint pizGood;
    uint PizBad;

    function LikeHam() public {
        HamGood = HamGood + 1; // ++HamGood, HamGood+=1
    }

    function UnLikeHam() public {
        HamBad = HamBad + 1; // ++HamBad, HamBad+=1
    }
    
    function Likepiz() public {
        pizGood = pizGood + 1; // ++pizGood, pizGood+=1
    }
    
    function UnLikepiz() public {
        PizBad = PizBad + 1; // ++PizBad, PizBad+=1
    }

    function getLikeUnLike() public view returns(uint, uint, uint, uint){
        return(HamGood, HamBad, pizGood, pizGood);
    }
    
}