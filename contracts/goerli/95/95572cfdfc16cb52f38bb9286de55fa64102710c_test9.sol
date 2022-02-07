/**
 *Submitted for verification at Etherscan.io on 2022-02-07
*/

// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.4.25;
contract  test9 {
 
    address public addr0 = 0x710AFEF4052C2820059d13Eb7DDC14700931cFE1;
    address public addr1 = 0x3E045227A02FC566A0a4431e20dBBd49441f6BA1;
 
    //1. 匿名函数：没有函数名，没有参数，没有返回值的函数，就是匿名函数
    //2. 当调用一个不存在的方法时，合约会默认的去调用匿名函数
    //3. 匿名函数一般用来给合约转账，因为费用低
    function () public  payable {
 
    }
 
    function getBalance() public view returns(uint256) {
        return addr1.balance;
    }
 
    function getContractBalance() public view returns(uint256) {
        return address(this).balance;
    }
 
    //由合约向addr1 转账10以太币
    function transfer() public {
        //1. 转账的时候单位是wei
        //2. 1 ether = 10 ^18 wei （10的18次方）
        //3. 向谁转钱，就用谁调用tranfer函数
        //4. 花费的是合约的钱
        //5. 如果金额不足，transfer函数会抛出异常
        addr1.transfer(10 **18);
    }
 
    //send与tranfer使用方式一致，但是如果转账金额不足不会抛出异常，而是会返回false
    function sendTest() public {
        addr1.send(10 **18);
    }
}