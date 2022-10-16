/**
 *Submitted for verification at Etherscan.io on 2022-10-16
*/

/// SPDX-License-Identifier: MIT
pragma solidity ^0.8.7;
contract test2{
    // 整型
    int public _int = -1; // 整数，包括负数
    uint public _uint = 1; // 正整数
    uint256 public _number = 20220330; // 256位正整数
    // 整数运算
    uint256 public _number1 = _number + 1; // +，-，*，/
    uint256 public _number2 = 2**2; // 指数
    uint256 public _number3 = 7 % 2; // 取余数
    bool public _numberbool = _number2 > _number3; // 比大小
    // 地址
    address public _address = 0x4D2162832574Fc27eDb2e5c623615beD34E17727;
    address payable public _address1 = payable(_address); // payable address，可以转账、查余额
    // 地址类型的成员
    uint256 public balance = _address1.balance; // balance of address
    
}