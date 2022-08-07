/**
 *Submitted for verification at Etherscan.io on 2022-08-07
*/

// SPDX-License-Identifier:MIT
pragma solidity ^0.8.8;

contract SimpleStorage {
    uint256 public favoriteNumber;

    People public person = People({favoriteNumber: 2, name: "suansuan"});

    mapping(string => uint256) public nameToFavoriteNumber;

    struct People {
        uint256 favoriteNumber;
        string name;
    }
    // 类比golang, []像slice,动态增长，[3]是数组，固定大小
    People[] public people;

    function store(uint256 _favoriteNumber) public {
        favoriteNumber = _favoriteNumber;
    }

    function retrieve() public view returns (uint256) {
        return favoriteNumber;
    }

    // TypeError: Data location must be "memory" or "calldata" for parameter in function, but none was given.
    // Data location can only be specified for array, struct or mapping types,
    // <- string 底层是bytes[]， 即array实现，而 struct map array 必须是 上面3者修饰
    // memory ： 只存在于内存中的数据，在这里，它的作用域只在于这个函数
    function addPerson(string memory _name, uint256 _favoriteNumber) public {
        // People memory newPerson = People({favoriteNumber:_favoriteNumber, name:_name});
        //  People memory newPerson = People(_favoriteNumber, _name);
        // people.push(newPerson);
        people.push(People(_favoriteNumber, _name));

        // 操作map
        nameToFavoriteNumber[_name] = _favoriteNumber;
    }
}