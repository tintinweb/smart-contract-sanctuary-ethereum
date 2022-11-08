/**
 *Submitted for verification at Etherscan.io on 2022-11-08
*/

//SPDX-License-Identifier: MIT

pragma solidity 0.8.14;

contract MyContract {

    uint public myUint = 123;

    function setMyUint(uint newUint) public {
        myUint = newUint;
    }

}