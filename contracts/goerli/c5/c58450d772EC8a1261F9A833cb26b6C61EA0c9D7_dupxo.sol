/**
 *Submitted for verification at Etherscan.io on 2023-03-13
*/

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.13;

contract dupxo {

    string latestEvent = "0";

    event Event1(string _msg, address _adr);
    event Event2(string _msg, address _adr);
    event Event3(string _msg, address _adr);
    event Event4(string _msg, address _adr);
    event Event5(string _msg, address _adr);

    function f1() public {
        latestEvent = "1";
        emit Event1("1", msg.sender);
    }
    
    function f2() public {
        latestEvent = "2";
        emit Event2("2", msg.sender);
    }

    function f3() public {
        latestEvent = "3";
        emit Event3("3", msg.sender);
    }
    
    function f4() public {
        latestEvent = "4";
        emit Event4("4", msg.sender);
    }
    
    function f5() public {
        latestEvent = "5";
        emit Event5("5", msg.sender);
    }
}