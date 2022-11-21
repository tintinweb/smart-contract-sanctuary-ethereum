/**
 *Submitted for verification at Etherscan.io on 2022-11-20
*/

//SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

contract Demo {
    event changingNumberLog(address changer, uint beforeChange,uint afterChange);
    uint public number;
    function set(uint _num) public {
       emit changingNumberLog(msg.sender,number,_num);
       number = _num;
    }
}