/**
 *Submitted for verification at Etherscan.io on 2022-05-12
*/

// SPDX-License-Identifier : MIT

pragma solidity ^0.6.0;

contract FromFirstNametoName {

        function addPerson (string memory _firstName, string memory _name) public {
        NameToDateofBirth[_firstName] = _name ;
    }

    mapping (string => string) public NameToDateofBirth;


}