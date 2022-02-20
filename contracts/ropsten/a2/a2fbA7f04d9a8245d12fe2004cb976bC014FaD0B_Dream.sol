/**
 *Submitted for verification at Etherscan.io on 2022-02-20
*/

//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.4;
// https://github.com/ConsenSys/Tokens

contract Dream {

    // 币的名称如 BitDao
    string public name = "Dream Token";
    // 交易所看到的名称 如 BIT
    string public symbol = "DREAM";

    // 固定发行量，保存在一个无符号整型里
    uint256 public totalSupply = 100000000;


    // 地址类型变量用于存储以太坊账户
    address public owner;

    //映射是键/值映射。在这里，我们存储每个帐户余额。
    mapping(address => uint256) balances;

    /*
    * 合约构造函数
    *
     */
    constructor() {
         // The totalSupply is assigned to transaction sender, which is the account
        // that is deploying the contract.
        balances[msg.sender] = totalSupply;
        owner = msg.sender;
    }

        /**
     * 代币转账.
     *
     * The `external` modifier makes a function *only* callable from outside
     * the contract.
     */
    function transfer(address to, uint256 amount) external {
        // Check if the transaction sender has enough tokens.
        // If `require`'s first argument evaluates to `false` then the
        // transaction will revert.
        require(balances[msg.sender] >= amount, "Not enough tokens");

        // Transfer the amount.
        balances[msg.sender] -= amount;
        balances[to] += amount;
    }

    /**
     * 返回账号的代币余额，只读函数。
     *
     * The `view` modifier indicates that it doesn't modify the contract's
     * state, which allows us to call it without executing a transaction.
     */
    function balanceOf(address account) external view returns (uint256) {
        return balances[account];
    }

}