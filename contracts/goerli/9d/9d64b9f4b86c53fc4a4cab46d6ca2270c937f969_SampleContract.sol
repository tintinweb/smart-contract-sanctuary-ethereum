/**
 *Submitted for verification at Etherscan.io on 2022-11-18
*/

//SPDX-License-Identifier: MIT
pragma solidity 0.8.7;

contract SampleContract {

    string public myString = "Hello World";

    function updateString(string memory _newString) public {
        myString = _newString;
    }

}