/**
 *Submitted for verification at Etherscan.io on 2022-09-15
*/

//SPDX-License-Identifier: MIT

pragma solidity ^0.8.15;

contract repo{

    function my_func() public view returns(uint) {
    if (1 == 0) {
       return 0;
    }
    return this.my_func();
    }
}