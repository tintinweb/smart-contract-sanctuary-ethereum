/**
 *Submitted for verification at Etherscan.io on 2022-03-04
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;


interface IERC20 {
    function totalSupply() external view returns (uint256);
    function balanceOf(address account) external view returns (uint256);
    function decimals() external view returns (uint8);
    function transfer(address recipient, uint256 amount) external returns (bool);
    function allowance(address owner, address spender) external view returns (uint256);
    function approve(address spender, uint256 amount) external returns (bool);
    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);
    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed owner, address indexed spender, uint256 value);
}

contract testff{

       //合同表
    mapping(address=>contListPar) public contList;
    struct contListPar{
        address userAddr;//用户地址
        // address collaAddr;//抵押物地址
        // address USDAddr;//抵押出的币种地址
        // uint collaAmount;//抵押物总数量
        // uint USDAmount;//剩余抵押出的数量
        // uint overdraft;//清算后欠款
        // uint inteTime;//利息计时起始时间，每一次更新都会重置
        // uint inteConf;//已确认的利息，每一次更新时累加
        contUpdateListPar[] contUpdateList;//合同更新
        // uint contState;//合同状态，默认0，0正常，1：偿还完成，2：清算完成，3：清算完成并欠款
        // uint ctime;
    }
    struct contUpdateListPar{
        uint updateType;//更新类型，默认0，0：新开合同，1：追加，2：归还，3：抵押物提走，4：清算
        uint collaAmount;//抵押物数量
        address USDAmount;//抵押出的数量
        uint collaRate;//抵押率
        // // uint interestConfirm;//结算利息
        // uint ctime;
    }

    

    function test2(address addr) public view returns(contUpdateListPar[] memory){
        return contList[addr].contUpdateList;
    }

    function test3()public {
        address addr = 0x2791Bca1f2de4661ED88A30C99A7a9449Aa84174;
        // address addr1 = 0x1C2B50eCa56b2e76675CCA2486030DaCca803326;
        // address addr2 = 0x1b02dA8Cb0d097eB8D57A175b88c7D8b47997506;
        address addr3 = 0x061105807D9E2D2b4CaF4C543E7d41716874687c;

        contUpdateListPar memory m;
        m.updateType = 1;
        m.collaAmount = 2;
        m.USDAmount = addr3;
        m.collaRate = 4;
        contList[addr].contUpdateList.push(m);
        contList[addr].contUpdateList.push(m);
        contList[addr].contUpdateList.push(m);
        // contList[addr].contUpdateList[0].collaAmount = 2;
        // contList[addr].contUpdateList[0].USDAmount = 3;

        // contList[addr].contUpdateList[1].updateType = 4;
        // contList[addr].contUpdateList[1].collaAmount = 5;
        // contList[addr].contUpdateList[1].USDAmount = 6;

        // contList[addr].contUpdateList[2].updateType = 7;
        // contList[addr].contUpdateList[2].collaAmount = 9;
        // contList[addr].contUpdateList[2].USDAmount = 310;

    }

}