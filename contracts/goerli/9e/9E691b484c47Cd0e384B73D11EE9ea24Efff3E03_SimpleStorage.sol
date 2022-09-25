// SPDX-License-Identifier: MIT
pragma solidity ^0.8.7;

contract SimpleStorage 
{
    // 默认值为 0，默认可见性为 internal，如果设置为 public，相当于创建了一个 getter 函数
    uint256 public favoriteNumber;
    // 数组可以指定大小，未指定时为动态大小
    People[] public people;

    // 对象中的变量都会被自动编号（从 0 开始）
    struct People
    {
        string name;
        uint256 favoriteNumber;
    }

    mapping(string => uint256) public nameToFavoriteNumber;

    function store(uint256 _favoriteNumber) public virtual
    {
        favoriteNumber = _favoriteNumber;
    }

    // view 关键字表示这个函数是只读函数，并不对合约中的内容作修改，不会生成 transaction，不消耗 gas
    function retrieve() public view returns (uint256)
    {
        return favoriteNumber;
    }

    // pure 关键字表示这个函数既不会读取也不会修改合约中的内容，不会生成 transaction，不消耗 gas
    // 对于 pure 和 view 函数仅在一种情况下会消耗 gas，如果另外一个函数涉及修改合约中的内容，并且
    // 调用了 view 或 pure 函数，那么 view 或 pure 函数将消耗 gas
    function add() public pure returns (uint256)
    {
        return 1 + 1;
    }

    // 引用类型变量修饰符: storage, memory, calldata，三者分别表示不同的数据存储区域，默认为 storage
    // * storage: 存储所有的状态变量，存储位置在 blockchain 当中，数据可以可以被修改，生命周期被限制在 contrast 当中
    // * memory: 临时存储函数作用域内的变量，变量仅在函数作用域内可以被读取或修改，生命周期被限制在函数当中
    // * calldata: 临时存储函数的参数，其中的数据不可被修改，生命周期被限制在函数当中
    // 
    // 官方文档:
    // Values of reference type can be modified through multiple different names.
    // Contrast this with value types where you get an independent copy whenever 
    // a variable of value type is used. Because of that, reference types have to 
    // be handled more carefully than value types. Currently, reference types comprise 
    // structs, arrays and mappings. If you use a reference type, you always have to 
    // explicitly provide the data area where the type is stored: memory (whose lifetime
    // is limited to an external function call), storage (the location where the state 
    // variables are stored, where the lifetime is limited to the lifetime of a contract)
    // or calldata (special data location that contains the function arguments).
    //
    // An assignment or type conversion that changes the data location will always 
    // incur an automatic copy operation, while assignments inside the same data 
    // location only copy in some cases for storage types.
    //
    // 参考:
    // https://docs.soliditylang.org/en/v0.8.13/types.html#data-location-and-assignment-behaviour
    // https://docs.soliditylang.org/en/v0.8.13/types.html#reference-types
    // https://docs.soliditylang.org/en/v0.8.13/internals/layout_in_storage.html
    // https://twitter.com/Web3Oscar/status/1514509414501343234
    // https://twitter.com/PatrickAlphaC/status/1514257121302429696
    function addPerson(string memory _name, uint256 _favoriteNumber) public 
    {
        // 等价于 People memory newPerson = People({name: _name, favoriteNumber: _favoriteNumber})
        people.push(People(_name, _favoriteNumber));
        nameToFavoriteNumber[_name] = _favoriteNumber;
    } 
}

// 使用 solc 编译 SimpleStorage.sol 的两种方法: 
// 1. 直接在命令行输入 yarn solcjs --bin --abi --include-path node_moduls/ --base-path . -o . SimpleStorage.sol 
// 2. 在 package.json 中添加 "scripts": { "compile": "yarn solcjs --bin --abi --include-path node_moduls/ --base-path . -o . SimpleStorage.sol" }
//    然后直接在命令行中输入 yarn complile 即可编译 SimpleStorage.sol