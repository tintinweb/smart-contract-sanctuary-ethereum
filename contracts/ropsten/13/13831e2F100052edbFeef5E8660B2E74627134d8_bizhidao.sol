/**
 *Submitted for verification at Etherscan.io on 2022-05-15
*/

// SPDX-License-Identifier:MIT

//money_VP

pragma solidity ^0.8.10;


contract bizhidao{
    address public owner;                          //管理 地址

    constructor(){
        owner = msg.sender;               

    }
    modifier quanxian(){                                 //函数修改器 判断 管理地址
        require(msg.sender == owner,"not owner");
        _;
    }
    modifier quanxian2(){                                 //函数修改器 判断 管理地址
        require(msg.sender == owner,"no mortgage, no trust, so not public VP_money");
        _;
    }
    function owner2(address _owner2)external quanxian{     //更改 新 管理地址
        require(_owner2 != address(0),"invalid address");
        owner = _owner2;
    }

}