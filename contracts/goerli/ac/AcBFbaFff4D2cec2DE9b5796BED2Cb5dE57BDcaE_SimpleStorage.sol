// SPDX-License-Identifier: MIT

pragma solidity ^0.8.8; // 最新版本 0.8.15

contract SimpleStorage {
    // 最基础4种数据类型 boolean, uint, int, address
    bool a = true; // true or false
    uint b = 124; //  无符号正整数
    uint8 bc = 124; //  分配空间 uint8 / 16 / 32 / 256
    int c = -134; // 正数或者负数
    int256 cc = 134; // 分配空间

    // 其他数据类型
    string e = "five"; // string 是一种 bytes 但是只能存储文本，可以自动转化 bytes

    // 更底层数据类型 bytes
    bytes32 f = "abdc"; // 通常0x开头，后有一些随机的数字和字母 bytes2 bytes3 bytes22 bytes32

    uint256 public g; // 默认值为null，在solidity中为 0，加了public可以外部看到

    address public owner;

    constructor() {
        owner = msg.sender;
    }

    function readOwner() public view returns (address) {
        return owner;
    }

    function store(uint256 _g) public virtual {
        g = _g;
    }

    // public private external internal
    // public 内外部均可见，任何与合约有交互的人，会创建 storage / state 的 getter 函数
    // private 内部可见，这个合约是唯一一个调用函数的合约
    // external 只对合约外部可见，合约外的账户可以调用这个函数
    // internal 只有这个合约或者继承它的合约可以读取

    // 每次试图改变区块链状态的时候，都会发送交易，计算量变大，消耗gas量也会增多，越多的操作消耗越多的gas

    // scope，函数内，有定义域，和 js 一样，contract可以类比 js 的 class

    // 2个关键字，标识函数调用不需要消耗 gas，只有更改状态才会支付gas，发交易
    // 1. view 只会读取合约状态，函数中不能修改任何状态
    function retrieve() public view returns (uint256) {
        return g;
    }

    // 2. pure 不能修改任何状态，也不允许读取区块链数据
    function add() public pure returns (uint256) {
        return (1 + 1);
    }

    // 但是如果 store 函数调用 retrieve 或 add，会消耗gas

    // Arrays & Structs

    People[] public people;

    People public person = People({favoriteNumber: 2, name: "Patrick"});

    People public person2 = People({favoriteNumber: 3, name: "Patrick3"});

    struct People {
        uint256 favoriteNumber;
        string name;
    }

    // basic solidity mappings
    mapping(string => uint256) public nameToDavoriteNumber;

    function addPerson(string memory _name, uint256 _favorateNumber) public {
        // people.push(People(_favorateNumber, _name));
        People memory newPerson = People({
            favoriteNumber: _favorateNumber,
            name: _name
        });
        people.push(newPerson);
        nameToDavoriteNumber[_name] = _favorateNumber; // mapping
    }

    // Errors & Warnings yellow or red

    // Memory Storage Calldata(intro)

    // EVM can access and store information in six places
    // 1. Stack 2. Memory 3. Storage 4. Calldata 5. Code 6. Logs
    // 全局变量一般存储在 storage 中， memory 声明的变量，函数用完就抛弃了，但两个都可以更改
    // calldata 声明的，不可更改
    // data location can only be  array struct and mapping types, 说明 uint只能去 memory 所以无需声明，为什么 string 需要声明，是因为 string 是 array of bytes
}