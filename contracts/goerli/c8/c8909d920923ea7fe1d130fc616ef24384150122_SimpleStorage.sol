/**
 *Submitted for verification at Etherscan.io on 2022-10-23
*/

// SPDX-License-Identifier:MIT

// 声明编译器版本
//  ^
//

pragma solidity 0.8.7;

contract SimpleStorage {
    //基本数据类型
    // bollean, uint, int, address, bytes, string

    // bool isAlive = true;

    // 可见度 public  -> 创建了一个call function
    // 默认不可见 internal
    // exteranl
    // internal

    uint256 favoriteNumber; // 256bit

    // string name ="liujingze";
    // bytes1 number="1";  //1byte =8bit

    function store(uint256 _number) public virtual {
        favoriteNumber = _number; //执行的语句越多gas费越贵
    }

    // view 查看区块链状态 pure

    function retrieve() public view returns (uint256) {
        return favoriteNumber;
    }

    struct people {
        string name;
        uint256 age;
    }

    people[] public pepole_arry; //数组

    // 字典 把一个字符对应一个256的数字
    //[name:number]
    mapping(string => uint256) public nameToFavoriteNumber;

    // calldata only 暂时的
    // stroage
    // memory

    function addPeople(string memory _name, uint256 _age) public {
        nameToFavoriteNumber[_name] = _age;

        people memory person = people({name: _name, age: _age});

        pepole_arry.push(person);
    }
}