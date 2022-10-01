/**
 *Submitted for verification at Etherscan.io on 2022-10-01
*/

//SPDX-License-Identifier:NOLICENSE
pragma solidity 0.8.14;

contract Test1 {
    function fun1() external {
        require(msg.sender.code.length > 0,"Test1 :: fun1");
    }
}

interface ITest1 {
    function fun1() external;
}

contract Test2 {
    constructor(address con) {
        ITest1(con).fun1();
    }
}