/**
 *Submitted for verification at Etherscan.io on 2022-09-23
*/

pragma solidity 0.8.0;

contract AAAA{
    uint hamGood=0;
    uint hamBad=0;
    uint pizGood=0;
    uint pizBad=0;

    function likeHam() public{
        ++hamGood;
    }
     function unlikeHam() public{
        ++hamBad;
    }
     function likepiz() public {
        ++pizGood;
    }
     function unlike() public {
        ++pizBad;
    }
     function getlikeUnlike() public view returns(uint,uint,uint,uint){
        return(hamGood,hamBad,pizGood,pizBad);
    }
}