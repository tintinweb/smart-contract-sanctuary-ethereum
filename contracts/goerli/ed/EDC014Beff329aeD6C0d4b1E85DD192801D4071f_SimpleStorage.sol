/**
 *Submitted for verification at Etherscan.io on 2023-02-24
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.7;

contract SimpleStorage {
    // 这里其实是一个 storage 变量
    uint256 favoriteNumber;
    // 指定数组长度
    uint256[3] public favoriteNumbersList;
    // 不指定数组长度，这里是动态数组
    // public 生成的 getter 函数，通过输入索引来查询数组中对应索引的值
    People[] public people;

    mapping(string => uint256) public nameToFavoriteNumber;

    struct People {
        uint256 favoriteNumber;
        string name;
    }

    // 向数组中添加元素
    // memory、calldata、storage 指定数据存储位置，仅适用于 array、struct、mapping 类型
    // 其他类型不需要指定！！而 string 底层其  实是 bytes 属于 array
    // 由于这里是函数的入参，变量的存储位置不能指定为 storage
    function addPerson(string memory _name, uint256 _favoriteNumber) public {
        // 这里编译会报错，因为 calldata 类型的临时变量是不允许被修改的，
        // 如果函数签名中声明的 _name 为 memory 类型的临时变量，则这里不会报错
        // 因为 memory 类型的临时变量允许被修改
        // _name = "cat";
        people.push(People(_favoriteNumber, _name));
        // People memory newPerson = People({favoriteNumber: _favoriteNumber, name: _name});
        // people.push(newPerson);
        nameToFavoriteNumber[_name] = _favoriteNumber;
    }

    // 这里声明 virtual 是为了表明该函数可以被重写 override
    function store(uint256 _favoriteNumber) public virtual {
        favoriteNumber = _favoriteNumber;
    }

    function retrieve() public view returns (uint256) {
        return favoriteNumber;
    }
}