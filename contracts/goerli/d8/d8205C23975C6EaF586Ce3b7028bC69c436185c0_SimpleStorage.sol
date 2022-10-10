/**
 *Submitted for verification at Etherscan.io on 2022-10-10
*/

// SPDX-License-Identifier: MIT
// 如果不设 License 会报出警告
pragma solidity 0.8.7;

// 0.8.12   ^0.8.7   >=0.8.7 <0.9.0

// EVM, Ethereum Virtual Machine
// Avalanche, Fantom, Polygon
// class
contract SimpleStorage {
    // 基础类型：boolean, uint, int, address, bites
    // bool hasFavoriteNumber = true;
    // uint8 favoriteNumber = 12;
    // uint256 badNumber = 123456789;  // default uint256, min uint8 max uint256, 指定长度是好的习惯
    // string inputText = 'Five';
    // int aInt = -5;
    // address myAddress = 0x1A6C391E7D4DCA2eb1a13C8b9C8E84045c438b44;
    // bytes32 aBytes = "cat"; // 0x12312qdasd, max bytes32

    // 默认私有变量，不可见。若想对外可见 uint256 public favoriteNumber;
    uint256 favoriteNumber; // favoriteNumber default is 0 等同于 uint256 favoriteNumber = 0;
    // People person = People({favoriteNumber: 5, name: 'kaier'});

    // mapping 键值对一一对应，使用 string 去取 uint256
    mapping(string => uint256) public nameToFavoriteNumber;

    // 创建一种新数据结构，输出将为有序带 index 的数据
    struct People {
        uint256 favoriteNumber;
        string name;
    }

    // Array 用法
    uint256[] public favoriteNumberList;
    People[] public people; // no limit
    People[3] threePeople; // just 3 people

    // functions
    // public  对内对外可见
    // private 只对合约内部可见
    // external 只对合约外部可见
    // internal 本合约或者继承它的合约可读取
    function store(uint256 _favoriteNumber) public virtual {
        favoriteNumber = _favoriteNumber;
        // 函数内的计算越多，所耗费的gas 越多
    }

    // 作用域

    // 带关键字 view， pure 的function 不进行交易不耗费 gas。不改变状态。
    // 只有用合约函数调用的时候才会耗费gas ，如在 store 方法调用了，retreive() 就会消耗gas，因为读取了区块链信息
    // 带 public 的变量，相当于一个返回 uint256 的view 函数，如：uint256 public favoriteNumber;
    function retrieve() public view returns (uint256) {
        return favoriteNumber;
    }

    function add() public pure returns (uint256) {
        return (1 + 3);
    }

    // calldata, memory, storage
    function addPerson(string memory _name, uint256 _favoriteNumber) public {
        people.push(People(_favoriteNumber, _name));
        // 等价于
        // People memory newPerson = People({favoriteNumber: _favoriteNumber, name: _name});
        // people.push(newPerson);

        // 注意关键字 memory，表示_name 只是函数作用域内可用，且 _name 参数可被修改。
        // calldata 亦只是函数作用域内可用，但在函数内将不可改变。
        // storage 在函数外部也可使用
        // uint256 类型只能活在函数内，因此不需要使用 memory
        // 这些类型 array, struct or mapping 需要使用 memory
        // string is Array of bites

        // mapping 使我们可以方便拿到某姓名的 number
        nameToFavoriteNumber[_name] = _favoriteNumber;
    }
}