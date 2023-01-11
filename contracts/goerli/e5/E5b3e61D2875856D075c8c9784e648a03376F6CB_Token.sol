// Solidity 文件 第一行代码都会是 pragma
// Solidity 编译器将使用它来验证对应的版本
pragma solidity ^0.7.0;

//import "hardhat/console.sol";

// 这是智能合约的主要组成部分
contract Token {
    // 一些字符串类型变量来标识代币
    // `public` 修饰符使变量在合约外部可读
    string public name = "My Hardhat Token";
    string public symbol = "MHT";

    // 存储在无符号整型变量中的固定数量代币
    uint256 public totalSupply = 1000000;

    // 地址类型变量用于存储以太坊账户
    address public owner;

    // `mapping` 是一个键/值映射。我们在这里存储每个帐户余额
    mapping(address => uint256) balances;

    /**
     * 合约初始化
     *
     * `constructor` 只在合约创建时执行
     */
    constructor() {
        // totalSupply 被分配给交易发送方，即部署合约的帐户
        balances[msg.sender] = totalSupply;
        owner = msg.sender;
    }

    /**
     * 传递代币的函数
     *
     * `external` 修饰符使函数只能从合约外部调用
     */
    function transfer(address to, uint256 amount) external {
        // 检查交易发送方是否有足够的代币
        // 如果 `require` 的第一个参数计算结果为 `false``,则整个交易会恢复
        require(balances[msg.sender] >= amount, "Not enough tokens");

        // 转移金额
        balances[msg.sender] -= amount;
        balances[to] += amount;
    }

    /**
     * 读取给定帐户的代币余额
     *
     * `view` 修饰符表示它不修改合约的状态，这允许我们在不执行交易的情况下调用它
     */
    function balanceOf(address account) external view returns (uint256) {
        return balances[account];
    }
}