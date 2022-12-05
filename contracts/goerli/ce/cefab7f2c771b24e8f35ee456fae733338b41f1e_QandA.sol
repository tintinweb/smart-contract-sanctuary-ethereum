/**
 *Submitted for verification at Etherscan.io on 2022-12-05
*/

// SPDX-License-Identifier: GPL-3.0
// 20220928
pragma solidity 0.8.0;

contract QandA {
    enum Status {ask, cancel, answering, done}

    struct Board {
        uint number;
        string title;
        address asker;
        string answer;
        Status status;
    }
    struct Respondent {
        string name;
        string content;
    }

    mapping(string => Board) boards;

    function ask(string memory _title) public payable {
        require(msg.value == 200000000000000000);
        
    } 




}