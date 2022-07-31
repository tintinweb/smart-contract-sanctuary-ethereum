/**
 *Submitted for verification at Etherscan.io on 2022-07-31
*/

pragma solidity ^0.8.7;       //指定版本

contract alan_test                //合约名   
{                
     uint storedData;       // 相当于定义一个变量 数据库一个字段

    function set(uint x) public {   //  set一个值 public 就是任何人都能调用 
        storedData = x;
    }

    function get() public view returns (uint) {   //  获取 public 同样意思
        return storedData;
    }

}