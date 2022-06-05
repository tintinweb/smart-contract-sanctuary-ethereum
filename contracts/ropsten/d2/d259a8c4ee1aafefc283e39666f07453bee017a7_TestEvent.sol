/**
 *Submitted for verification at Etherscan.io on 2022-06-05
*/

//SPDX-License-Identifier: MIT

pragma solidity >=0.8.0 <0.9.0;

contract TestEvent {
    event Test(string);

    function test(string memory _param) public{
        emit Test(_param);
    }
}