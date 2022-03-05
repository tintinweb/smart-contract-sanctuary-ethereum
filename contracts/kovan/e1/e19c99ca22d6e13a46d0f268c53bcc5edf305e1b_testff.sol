/**
 *Submitted for verification at Etherscan.io on 2022-03-04
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract testff{

       //合同表
    mapping(address=>contListPar) public contList;
    struct contListPar{
        address userAddr;//用户地址 0xb9f82796603aFed59508C255Fd7e9Db28369E34c
        address collaAddr;//抵押物地址 0x7049eeddddc2682c3f1fc2250784b5b20235ba75
        address USDAddr;//抵押出的币种地址
        uint collaAmount;//抵押物总数量
        uint USDAmount;//剩余抵押出的数量
        uint overdraft;//清算后欠款
        uint inteTime;//利息计时起始时间，每一次更新都会重置
        uint inteConf;//已确认的利息，每一次更新时累加
        contUpdateListPar[] contUpdateList;//合同更新
        uint contState;//合同状态，默认0，0正常，1：偿还完成，2：清算完成，3：清算完成并欠款
        address[] path;
        uint ctime;
    }
    struct contUpdateListPar{
        uint updateType;//更新类型，默认0，0：新开合同，1：追加，2：归还，3：抵押物提走，4：清算
        uint collaAmount;//抵押物数量
        address USDAmount;//抵押出的数量
        uint collaRate;//抵押率
        uint interestConfirm;//结算利息
        uint ctime;
    }

    function test(address addr)public {
        contList[addr].userAddr = addr;
        contList[addr].collaAddr = addr;
        contList[addr].USDAddr = addr;

    }

    function setPath(address addr,address[] memory path)public {
        contList[addr].path = path;
    }

    function getPath(address addr)public view returns(address[] memory){
        return contList[addr].path;
    }

    function test1(address addr) public view returns(contListPar memory){
        return contList[addr];
    }

   function test2(address addr) public view returns(address){
        return contList[addr].userAddr;
    }

   function test3(address addr) public view returns(address){
        return contList[addr].collaAddr;
    }

}