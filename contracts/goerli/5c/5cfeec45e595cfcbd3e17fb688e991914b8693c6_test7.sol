/**
 *Submitted for verification at Etherscan.io on 2022-02-07
*/

// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.4.25;
contract  test7 {
    address public addr1 = 0x710AFEF4052C2820059d13Eb7DDC14700931cFE1;
    //地址address类型本质上是一个160位的数字
    //可以进行加减，需要强制转换
    function add() public view returns(uint160) {
        return uint160(addr1) + 10;
    }
 
    //1. 匿名函数：没有函数名，没有参数，没有返回值的函数，就是匿名函数
    //2. 当调用一个不存在的方法时，合约会默认的去调用匿名函数
    //3. 匿名函数一般用来给合约转账，因为费用低
    function () public  payable {
 
    }
		//获取addr1的余额
    function getBalance() public view returns(uint256) {
        return addr1.balance;
    }
 
    function getContractBalance() public view returns(uint256) {
        //this代表当前合约本身
        //balance方法，获取当前合约的余额
        return address(this).balance;
    }
}