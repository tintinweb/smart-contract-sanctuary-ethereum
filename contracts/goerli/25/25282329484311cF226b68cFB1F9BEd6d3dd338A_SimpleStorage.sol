// SPDX-License-Identifier: MIT
pragma solidity 0.8.17; // solidity version

contract SimpleStorage {
    // 基础类型: boolean, unit, int, string, address, bytes
    // 对象类型: struct, array[]
    // 存储关键次：calldata memory storage

    /*
     * array, struct or mapping, string
     * 存在内存中：calldata memory（临时的），calldata变量无法修改，memory可以修改
     * 永久存在：storage（默认全局变量就是：storage）
     */

    // 基础类型 exmpale
    // bool hasFavoriteNumber = true;
    // uint256 hasFavoriteUnit = 123;
    // int256 hasFavoriteInt = 123;
    // string hasFavoriteString = "Five";
    // address myAddress = 0x9791A44A5934E6f2e2C982C8A46EF63468cdc8e1;
    // bytes32 hasFavoriteBytes = "cat";

    // unit256 default 0
    uint256 favoriteNumber;
    // People[3]
    People[] public peoples;

    mapping(string => uint256) public nameToFavoriteNumber;

    // 结构体
    struct People {
        uint256 favoriteNumber;
        string name;
    }

    function store(uint256 _favoriteNumber) public {
        favoriteNumber = _favoriteNumber;
    }

    // view pure function not need gas
    function retrieve() public view returns (uint256) {
        return favoriteNumber;
    }

    // add a person
    function addPerson(uint256 _favoriteNumber, string memory _name) public {
        // People memory newPerson = People({favoriteNumber: _favoriteNumber, name: _name});
        // peoples.push(newPerson);
        peoples.push(People(_favoriteNumber, _name));
        nameToFavoriteNumber[_name] = _favoriteNumber;
    }
}