/**
 *Submitted for verification at Etherscan.io on 2022-06-01
*/

// SPDX-License-Identifier: BUSL-1.1 
pragma solidity ^0.8.10;


contract ceshi{
    address public owner;                          //管理 地址 真正部署时直接 赋值
    string a;
    uint24 b;
    uint16 c;
    uint256 d;

    constructor(){                                //真正部署时 直接赋值，不用构造函数
        owner = msg.sender;               

    }
    
    function owner2(address _owner2)external  returns(string memory tishi){     //更改 新 管理地址
        require(msg.sender == owner,"not owner");
        require(_owner2 != address(0),"invalid address");
        owner = _owner2;
        return("chenggong");
    }
}