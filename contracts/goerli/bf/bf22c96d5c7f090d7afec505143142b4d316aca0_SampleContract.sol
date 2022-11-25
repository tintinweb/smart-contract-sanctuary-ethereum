/**
 *Submitted for verification at Etherscan.io on 2022-11-25
*/

//SPDX-License-Identifier: MIT

pragma solidity 0.8.15;

contract SampleContract {
    string public myString = "Stews World";

    function updateString(string memory _newString) public {
        myString = _newString;
    }
}