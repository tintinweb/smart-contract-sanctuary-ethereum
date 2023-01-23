/**
 *Submitted for verification at Etherscan.io on 2023-01-23
*/

// File: contracts/testdoang.sol



pragma solidity ^0.8.0;

contract DataStorage {
    uint data;

    function setData(uint _data) public {
        data = _data;
    }

    function getData() public view returns (uint) {
        return data;
    }
}