/**
 *Submitted for verification at Etherscan.io on 2022-09-05
*/

// SPDX-License-Identifier: NONE
pragma solidity ^0.8.9;


contract SampleContract {
    string public text;

    function setText(string calldata _input) public {
        text = _input;
    }

}