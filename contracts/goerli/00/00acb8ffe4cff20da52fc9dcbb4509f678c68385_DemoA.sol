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

contract DemoB  {
    DemoA demoA;
    constructor(address _demoa){
        demoA = DemoA(_demoa);
    }
    function use(uint _num) external {
        demoA.set(_num);
    }
}