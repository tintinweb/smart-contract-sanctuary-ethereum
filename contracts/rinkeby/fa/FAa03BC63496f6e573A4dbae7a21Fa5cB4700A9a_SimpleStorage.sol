// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

contract SimpleStorage {
    uint256 favoriteNumber;

    mapping(string => uint256) public nameToFavoriteNumber;

    //new一个结构体 等于 调用一个方法，后边会有（）
    // People public person = People({favoriteNumber:2,name:"java"});

    //结构体
    struct People {
        uint256 favoriteNumber;
        string name;
    }

    People[] public people;

    // uint256[] public favoriteNumberList;

    //存储喜欢数字
    //virtual  需要被重写
    function store(uint256 _favoriteNumber) public virtual {
        favoriteNumber = _favoriteNumber;
    }

    //检索查看喜欢的数字
    //view只是读取链上数据 不会改变结果，不会有手续费
    //跟view相似的pure
    //pure也不允许对状态进行任何修改，所以我们无法更新我们最喜欢的数字，
    //并pure还不允许从区块链读取，所以我们也看不到最喜欢的号码
    //pure可以用在一些不改变链上数据，并有一些复杂的数学运算方法上面
    function retrieve() public view returns (uint256) {
        return favoriteNumber;
    }

    //小写people是数组，大写People是结构体
    //调用数据 ：calldate 意味着变量，只是暂时存在交易期间（如：只存在调用下边addPerson中）
    // 内存 ：memmory     意味着变量，只是暂时存在交易期间（如：只存在调用下边addPerson中）

    function addPerson(string memory _name, uint256 _favoriteNumber) public {
        people.push(People(_favoriteNumber, _name));
        nameToFavoriteNumber[_name] = _favoriteNumber;
    }
}