/**
 *Submitted for verification at Etherscan.io on 2022-11-21
*/

//SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;


contract DemoA {
    event changingNumberLog(address changer, uint beforeChange,uint afterChange);
    uint public number;
    function set(uint _num) external {
       emit changingNumberLog(msg.sender,number,_num);
       number = _num;
    }
}