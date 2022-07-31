/**
 *Submitted for verification at Etherscan.io on 2022-07-31
*/

//SPDX-License-Identifier: GPL-3.0

pragma solidity 0.8.9;

contract FirstContract {
    uint public counter1 = 0;
    int public counter2 = 0;

    function addCounter() public {
        counter1++;
        counter2--;
    }

}