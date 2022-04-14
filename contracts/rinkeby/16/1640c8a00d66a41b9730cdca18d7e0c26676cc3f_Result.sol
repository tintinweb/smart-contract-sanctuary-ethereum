/**
 *Submitted for verification at Etherscan.io on 2022-04-14
*/

// SPDX-License-Identifier: UNLICENSED

pragma solidity ^0.8.0;

contract Result {

    string[] public row;

    function getRow() public view returns (string[] memory) {
        return row;
    }

    function pushToRow(string memory newValue) public {
        row.push(newValue);
    }

    function editRow(uint256 index, string memory newValue) public returns (string memory) {
        row[index]= newValue;
        return row[index];
    }

}