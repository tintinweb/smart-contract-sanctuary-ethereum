/**
 *Submitted for verification at Etherscan.io on 2022-08-19
*/

// SPDX-License-Identifier: None
pragma solidity >=0.7.0 <0.9.0;

contract  demo02 {
    function getTestMaxMax(uint256 value)public{
        address payable ms = msg.sender;
        //单位默认为wei
        ms.transfer(value);
    }
 
 
    //钱包地址转账到合约地址
    function transferToken()public payable {
 
    }
 
    //将合约地址的ETH转账到钱包地址
    function transferTo(uint256 wad)public returns(bool){
        msg.sender.transfer(wad);
        return true;
    }
 
    //查询合约地址ETH的余额
    function getEthAmount()public view returns(uint256){
        return address(this).balance;
    }
}