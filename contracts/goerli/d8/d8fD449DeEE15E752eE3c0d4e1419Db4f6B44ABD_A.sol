/**
 *Submitted for verification at Etherscan.io on 2022-12-05
*/

// SPDX-License-Identifier: GPL-3.0
pragma solidity 0.8.0;
//20221129

contract A {
    enum Status{available, lended, recovery, missed} // reserved는 제외

    struct QuestionBoard {
        uint number;
        string title;
        string question;
        string Respondent;
        string CurrentStatus;
        address questioner;
        address Answer;
    }
    mapping(string => QuestionBoard) QuestionBoards;


}