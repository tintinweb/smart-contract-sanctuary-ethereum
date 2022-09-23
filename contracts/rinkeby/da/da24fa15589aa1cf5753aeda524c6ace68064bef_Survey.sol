/**
 *Submitted for verification at Etherscan.io on 2022-09-23
*/

pragma solidity 0.8.0;

contract Survey {

    uint likeHam;
    uint hateHam;
    uint likePizza;
    uint hatePizza;

    function ham1Like() public {
        likeHam = likeHam + 1;
    }

    function ham2Hate() public {
        hateHam = hateHam + 1;
    }

    function pizza1Like() public {
        likePizza = likePizza+1;
    }

    function pizza2Hate() public {
        hatePizza = hatePizza+1;
    }

    function result() public view returns(uint,uint,uint,uint) {
        return (likeHam,hateHam,likePizza,hatePizza);
    }
}