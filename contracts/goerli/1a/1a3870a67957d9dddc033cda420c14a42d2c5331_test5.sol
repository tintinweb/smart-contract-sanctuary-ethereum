/**
 *Submitted for verification at Etherscan.io on 2022-02-07
*/

//指定solidy编译器版本，版本标识符
pragma solidity ^0.4.25;
 
//payable
contract  test5 {
    
    string public str;
    //修饰为payable的函数才可以接收转账
    function test1(string src) public payable {
        str = src;
    }
    //不指定payable无法接收,调用，如果传入value，会报错
    function test2(string src) public {
        str = src;
    }
  
    function getbalance() public view returns(uint256) {
        //this代表当前合约本身
        //balance方法，获取当前合约的余额
        return this.balance;
    }
}