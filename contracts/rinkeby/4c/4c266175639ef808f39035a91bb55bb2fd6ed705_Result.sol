/**
 *Submitted for verification at Etherscan.io on 2022-04-14
*/

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

contract Result {
    string[] public row;

    function getAllRecords() public view returns (string[] memory) {
        return row;
    }

    function addRecord(string memory data) public {
        row.push(data);
    }

    function editRecord(uint256 index, string memory data) public returns (string memory) {
        row[index] = data;
        return row[index];
    }

    function deleteRecord(uint256 _index) public returns (bool) {
        if (_index < 0 || _index >= row.length) {
            return false;
        } else if (row.length == 1) {
            row.pop();
            return true;
        } else if (_index == row.length - 1) {
            row.pop();
            return true;
        } else {
            for (uint256 i = _index; i < row.length - 1; i++) {
                row[i] = row[i + 1];
            }
            row.pop();
            return true;
        }
    }
}