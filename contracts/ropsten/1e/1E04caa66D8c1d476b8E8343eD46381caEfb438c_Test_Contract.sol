/**
 *Submitted for verification at Etherscan.io on 2022-06-15
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.14;

contract Test_Contract {

    string[] testArray;

    function addArray(string memory _arrayIn) external {

        testArray.push(_arrayIn);

    }

    function getArray() external view returns(string[] memory) {
        return testArray;
    }

}