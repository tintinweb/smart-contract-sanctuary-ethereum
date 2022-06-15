/**
 *Submitted for verification at Etherscan.io on 2022-06-15
*/

//SPDX-license-Identifier: MIT
pragma solidity ^0.8.14;

contract Kollab_Splitter_Factory {

    address payable _owner;

    string[] testArray;

    // Map to store each splitter with 
    mapping(uint => Kollab_Splitter) public _splitters;

    function addArray(string[] memory _arrayIn) external {

        testArray = _arrayIn;

    }

    function getArray() external view returns (string[] memory) {
        return testArray;
    }

}

contract Kollab_Splitter {

    mapping(uint => address) public _payees;
}