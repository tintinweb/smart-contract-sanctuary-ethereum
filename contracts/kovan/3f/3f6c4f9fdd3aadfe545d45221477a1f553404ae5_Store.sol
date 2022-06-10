/**
 *Submitted for verification at Etherscan.io on 2022-06-10
*/

/*
这里只是一个简单的合约，就是一个键/值存储，只有一个外部方法来设置任何人的键/值对。 我们还在设置值后添加了要发出的事件。
*/
pragma solidity =0.8.14;

contract Store {
    event ItemSet(bytes32 key, bytes32 value);

    string public version;

    mapping(bytes32 => bytes32) public items;

    constructor(string memory _version)  {
        version = _version;
    }

    function setItem(bytes32 key, bytes32 value) external {
        items[key] = value;
        emit ItemSet(key, value);
    }
}