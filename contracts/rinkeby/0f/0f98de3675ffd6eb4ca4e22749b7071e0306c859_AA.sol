/**
 *Submitted for verification at Etherscan.io on 2022-09-23
*/

// SPDX-License-Identifier: GPL-3.0
pragma solidity 0.8.0;

contract AA {
    uint likePiza=0;
    uint unLikePize=0;
    uint likeHam=0;
    uint unLikeHam=0;

    function pizaHate() public returns(uint) {
        unLikePize+=1;
        return unLikePize;
    }

    function pizaLike() public returns(uint) {
        likePiza+=1;
        return likePiza;
    }

    function hamHate() public returns(uint) {
        unLikeHam+=1;
        return unLikeHam;
    }

    function hamLike() public returns(uint) {
        likeHam+=1;
        return likeHam;
    }

    function showPizaHate() public view returns(uint) {
        return unLikePize;
    }

    function showPizaLike() public view returns(uint) {
        return likePiza;
    }

    function showHamHate() public view returns(uint) {
        return unLikeHam;
    }

    function showHamLike() public view returns(uint) {
        return likeHam;
    }


}