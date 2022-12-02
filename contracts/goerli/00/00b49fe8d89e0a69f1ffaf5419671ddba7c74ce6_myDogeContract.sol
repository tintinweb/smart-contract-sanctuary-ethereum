/**
 *Submitted for verification at Etherscan.io on 2022-12-02
*/

// 这里是声明用什么版本的编译器
pragma solidity >=0.4.22 <0.7.0;

// 合约主体
contract myDogeContract {
    // 存储结构 当前 
    // uint 整数类型
    // public 公开的
    // storedData 变量名
    uint public storedData;
    string public Name;

    // 构造函数
    constructor() public {
        storedData = 100;
    }

    // 设置 storedData
    function set(uint x) public {
        storedData = x;
    }

    // 返回 storedData
    function get() public view returns (uint retVal) {
        return storedData;
    }
}