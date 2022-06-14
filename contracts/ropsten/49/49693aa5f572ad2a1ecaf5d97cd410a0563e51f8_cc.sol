/**
 *Submitted for verification at Etherscan.io on 2022-06-14
*/

// SPDX-License-Identifier: BUSL-1.1 

// transfer

pragma solidity ^0.8.10;
contract cc{

  mapping(address=>uint)yue;
  mapping(address=>uint)zhiyayue;
  address  shoubidizhi;


 //msg.value.(余额映射[msg.sender]+=msg.value;)value就是remix上输入值的东西.address(this).balance 是合约总余额。

  function cunru() public payable { //收币函数 
    yue[msg.sender] += msg.value ;
  //  zhiyayue[msg.sender] += msg.value / 2;

   // payable(address(this)).transfer(token_wei);
        
  }

  function quchu(uint token) public{
    require(token <= yue[msg.sender],"yuebuzu");
    payable(msg.sender).transfer(token);     //收币者(地址) . transfer( 数量 )；
    yue[msg.sender] -= token;

  }



 function Yue(address zhanghao)external view returns(uint thi,uint _yue,uint _zhiyayue){
    return(address(this).balance,yue[zhanghao],zhiyayue[zhanghao]) ;
  }
  function zidongYue()external view returns(uint thi,uint _yue,uint _zhiyayue){
    return(address(this).balance,yue[msg.sender],zhiyayue[msg.sender]) ;
  }
}