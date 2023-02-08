/**
 *Submitted for verification at Etherscan.io on 2023-02-08
*/

// SPDX-License-Identifier: GPL-3.0

pragma solidity >=0.8.2 <0.9.0;
contract HelloWeb3 {

    // 声明一个名为value的状态变量
    string  value;
    
    // 合约构造函数，每当将合约部署到网络时都会调用它。
    // 此函数具有public函数修饰符，以确保它对公共接口可用。
    // 在这个函数中，我们将公共变量value的值设置为“myValue”。

    constructor() payable{
        value = "myValue";
    }

   function getBalance() public view returns(uint) {
        return address(this).balance;
    }

     // 本函数读取值状态变量的值。可见性设置为public，以便外部帐户可以访问它。
    // 它还包含view修饰符并指定一个字符串返回值。
    function get() public view returns(string memory ) {
        return value;
    }

   // 本函数设置值状态变量的值。可见性设置为public，以便外部帐户可以访问它。
    function set(string memory _value) public {
        value = _value;
    }
    
}