/**
 *Submitted for verification at Etherscan.io on 2022-12-22
*/

pragma solidity ^0.5.0;

contract SimpleContract {
    // 余额映射
    mapping (address => uint) public balances;

    // 转账方法
    function transferFrom(address from, address to, uint value) public {
        // 检查from地址的余额是否足够
        require(balances[from] >= value, "Insufficient balance");
        // 减少from地址的余额
        balances[from] -= value;
        // 增加to地址的余额
        balances[to] += value;
    }
}