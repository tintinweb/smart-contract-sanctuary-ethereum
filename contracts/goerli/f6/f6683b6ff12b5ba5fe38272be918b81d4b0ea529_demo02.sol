/**
 *Submitted for verification at Etherscan.io on 2022-08-19
*/

// SPDX-License-Identifier: None
pragma solidity ^0.4.24;

contract  demo02 {

    address public addr1 = 0xb81aC761CA4B637f9604F290A878421f21D72bE0;
    

    //地址address类型本质上是一个160位的数字
      //1. 匿名函数一般用来给合约转账，因为费用低
    //2. 这个匿名函数是由发起合约方对合约地址账户转账
    function () public  payable {
        
    }
    
    
    function getBalance() public view returns(uint256) {
        return addr1.balance;
    }
    
    
    function getContractBalance() public view returns(uint256) {
        //this代表当前合约本身
        //balance方法，获取当前合约的余额
        return address(this).balance;
    }
        //由合约向addr1 转账10以太币
    function transfer() public {
        //1 ether = 10 ^18 wei （10的18次方）
      
        addr1.transfer(0.01 * 10 **18);
    }
    
}