/**
 *Submitted for verification at Etherscan.io on 2022-09-23
*/

// SPDX-License-Identifier: GPL-3.0
pragma solidity >=0.7.0 <0.9.0;

contract LikeVote {
    uint pizzaLikeCount=0;
    uint pizzaDislikeCount=0;
    uint hambergerLikeCount=0;
    uint hambergerDislikeCount=0;
    
    function getPizza() public view returns (uint,uint) {
        return (pizzaLikeCount,pizzaDislikeCount);
    }

    function getHamberger() public view returns (uint,uint){
        return (hambergerLikeCount,hambergerDislikeCount);
    }


    function likePizza() public {
        pizzaLikeCount++;
    }


    function disLikePizza() public {
        pizzaDislikeCount++;
    }
    
     function likeHamberger() public {
        hambergerLikeCount++;
    }


    function disLikeHamberger() public {
        hambergerDislikeCount++;
    }   

}