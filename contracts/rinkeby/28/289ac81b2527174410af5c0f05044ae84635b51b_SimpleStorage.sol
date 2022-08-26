/**
 *Submitted for verification at Etherscan.io on 2022-08-26
*/

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.7;

contract SimpleStorage {

    uint public myNumber;

    constructor(uint _initNumber){
        myNumber = _initNumber;
    }

    function setNumber(uint _newNumber) public {
        myNumber = incrementNumber(_newNumber);
    }

    function incrementNumber(uint number) private pure returns(uint) {
        return number + 1;
    }

}