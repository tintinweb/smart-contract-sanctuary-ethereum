// SPDX-License-Identifier: MIT
// 上方是分享协议
pragma solidity 0.8.9;

contract SimpleStorage {
    uint256 public favoriteNumber;
    struct People {
        uint256 favoriteNumber;
        string name;
    }
    People public people = People({name: "leading", favoriteNumber: 10});

    People[] public peopleList;

    function storePeopleList(string memory _name, uint256 _number) public {
        peopleList.push(People(_number, _name));
        peopleDic[_name] = _number; //字典映射调解
    }

    function store(uint256 _favoriteNumber) public {
        favoriteNumber = _favoriteNumber;
        favoriteNumber++;
    }

    //字典映射
    mapping(string => uint256) public peopleDic;

    function retrieve() public view returns (uint256) {
        return favoriteNumber;
    }
}