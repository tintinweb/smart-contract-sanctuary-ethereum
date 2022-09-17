// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.17;

contract nameBank {
    // State Variables - Name Array, NewName
    string[] NameBankArray = ['John', 'Lisa'];
    string public newName;

    function addName(string memory _newName) public returns(string[] memory) {
        newName = _newName; // set local var = to state var
        NameBankArray.push(newName); // add new name input to array

        return(NameBankArray); // return the array

    }

    function getNames() public view returns(string[] memory) {
        return(NameBankArray); // returns new name and name bank
    }
}