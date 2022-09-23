/**
 *Submitted for verification at Etherscan.io on 2022-09-23
*/

pragma solidity 0.8.0;

contract Survey {

    uint likeHam;
    uint hateHam;
    uint likePizza;
    uint hatePizza;

    function ham1Like() public returns(uint) {
        likeHam = likeHam + 1;
        return likeHam;
    }

    function ham2Hate() public returns(uint) {
        hateHam = hateHam + 1;
        return hateHam;
    }

    function pizza1Like() public returns(uint) {
        likePizza = likePizza+1;
        return likePizza;
    }

    function pizza2Hate() public returns(uint) {
        hatePizza = hatePizza+1;
        return hatePizza;
    }

    function result() public view returns(uint,uint,uint,uint) {
        return (likeHam,hateHam,likePizza,hatePizza);
    }
}