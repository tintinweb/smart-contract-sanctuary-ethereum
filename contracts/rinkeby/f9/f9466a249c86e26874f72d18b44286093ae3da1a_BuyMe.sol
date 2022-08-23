// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;
import "./Buyable.sol";

contract BuyMe is Buyable {
    string[] public data;
    constructor() {}

    function write(string memory _data) external onlyOwner {
        data.push(_data);
    }

    function erase(uint256 index) external onlyOwner {
        data[index] = "";
    }

    function changeData(uint256 index, string memory _newData) external onlyOwner {
        data[index] = _newData;
    }
}