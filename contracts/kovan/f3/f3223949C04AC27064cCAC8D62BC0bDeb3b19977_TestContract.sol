// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract TestContract {
    mapping(address => string) data;

    event Recorded(address indexed sender, string data);

    constructor() {
    }

    function readData(address _address) external view returns(string memory) {
        return data[_address];
    }

    function readData() external view returns(string memory) {
        return this.readData(msg.sender);
    }

    function writeData(string memory _data) external {
        data[msg.sender] = _data;
        emit Recorded(msg.sender, _data);
    }
}