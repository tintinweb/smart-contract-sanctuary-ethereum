/**
 *Submitted for verification at Etherscan.io on 2022-09-12
*/

pragma solidity >=0.7.0 <0.9.0;

// SPDX-License-Identifier: MIT

contract NumberGoUp {
    uint public number = 0;

    event MakeNumberGoUp(uint value);

    function getNumber() view public returns(uint){
        return number;
    }

    function makeNumberGoUp() public {
        number += 1;
        emit MakeNumberGoUp(number);
    }

}