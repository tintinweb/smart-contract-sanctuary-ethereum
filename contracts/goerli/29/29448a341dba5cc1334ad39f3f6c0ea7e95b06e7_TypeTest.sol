/**
 *Submitted for verification at Etherscan.io on 2022-08-24
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.16;

contract TypeTest {
    uint256 public uint256Test;
    int256 public int256Test;
    address public addressTest;
    string public stringTest;
    uint256[] public uint256ArrayTest;
    int256[] public int256ArrayTest;
    address[] public addressArrayTest;

    function deposit() public payable {}

    function testTypes(
        uint256 _uint256Test,
        int256 _int256Test,
        address _addressTest,
        string memory _stringTest,
        uint256[] memory _uint256ArrayTest,
        int256[] memory _int256ArrayTest,
        address[] memory _addressArrayTest
    ) public {
        uint256Test = _uint256Test;
        int256Test = _int256Test;
        addressTest = _addressTest;
        stringTest = _stringTest;
        uint256ArrayTest = _uint256ArrayTest;
        int256ArrayTest = _int256ArrayTest;
        addressArrayTest = _addressArrayTest;
    }
}