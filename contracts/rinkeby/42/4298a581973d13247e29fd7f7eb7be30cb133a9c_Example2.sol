/**
 *Submitted for verification at Etherscan.io on 2022-02-17
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.11;


contract Example2 {

	uint counter=0;
	mapping (uint => string) stringList; //maps an integer to a string (creates an array)

    function push(string memory info) public {
        stringList[counter] = info; //saves the input string (info) into the list using the index "counter"
		counter++; //increment the counter
    }

    function get(uint nr) public view returns (string memory) {
        return stringList[nr]; //returns the string that is mapped to the index nr
    }
    function getCounter() public view returns (uint) {
        return counter; //return the number of strings
    }
}