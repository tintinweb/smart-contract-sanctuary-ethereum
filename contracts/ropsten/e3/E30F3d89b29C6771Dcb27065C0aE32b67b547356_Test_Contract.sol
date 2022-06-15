/**
 *Submitted for verification at Etherscan.io on 2022-06-15
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.14;

contract Test_Contract {

    string[] testArray;

    function addArray(string memory _arrayIn) public {

        testArray.push(_arrayIn);

    }

    function getArray() public view returns(string[] memory) {
        return testArray;
    }

}