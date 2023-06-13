// SPDX-License-Identifier: GPL-3.0
pragma solidity >=0.8.2 <0.9.0;

contract userSave {
    uint userCount = 0;

    struct data {
        uint256 number;
        uint id;
        string name;
    }

    mapping(uint => data) public Data;

    constructor() {
        userCount = userCount + 1;
        Data[userCount] = data(200, userCount, "Sanjay");
    }

    function store(uint256 num, string memory name) public {
        userCount = userCount + 1;
        Data[userCount] = data(200, userCount, "Sanjay");
    }

    function retrieve(
        uint id
    ) public view returns (uint, string memory, uint256) {
        return (Data[1].id, Data[1].name, Data[1].number);
    }
}