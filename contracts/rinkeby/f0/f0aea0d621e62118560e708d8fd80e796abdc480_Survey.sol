/**
 *Submitted for verification at Etherscan.io on 2022-09-23
*/

// SPDX-License-Identifier: GPL-3.0
pragma solidity 0.8.0;

contract Survey {
    uint likePizza = 0;
    uint hatePizza = 0;
    uint likeBuger = 0;
    uint hateBuger = 0;

    function getLikePizza() public view returns(uint){
        return likePizza;
    }
    function getHatePizza() public view returns(uint){
        return hatePizza;
    }
    function getLikeBugger() public view returns(uint){
        return likeBuger;
    }
    function getHateBugger() public view returns(uint){
        return hateBuger;
    }

    function setLikePizza() public {
        likePizza++;
    }
    function setHatePizza() public {
        hatePizza++;
    }
    function setLikeBuger() public {
        likeBuger++;
    }
    function setHateBuger() public {
        hateBuger++;
    }
}