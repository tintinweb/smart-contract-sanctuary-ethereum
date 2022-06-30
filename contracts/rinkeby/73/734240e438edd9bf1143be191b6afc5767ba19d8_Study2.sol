/**
 *Submitted for verification at Etherscan.io on 2022-06-30
*/

// 创建不同的募资活动，用来募集以太坊
// 记录相应活动下的募资总体信息(参与人数，募集的以太坊数量)，以及记录参与的用户地址以及投入的数量
// 业务逻辑（用户参与、添加新的活动、活动后进行资金提取）
// SPDX-License-Identifier: MIT
pragma solidity 0.8.11;

contract asstes {
    //创建一个活动结构体
    // struct actively{
    //     address paybale addr; //收款账号
    //     uint256 userTotal; //参与人数
    //     uint256 total; //目标募资的以太坊
    //     uint256 count; //已经募资的以太坊
    // }
    struct actively {
        address payable addr;
        uint256 userTotal;
        uint256 total;
        uint256 count;
    }
    //创建一个用户的结构体

    // struct user{
    //     address addr; //用户地址
    //     uint256 amount; //投入的以太坊数量
    // }
    struct user {
        address addr;
        uint256 amount;
    }

    uint256 public startNumber; //记录活动的数量及开始的id
    //活动id  --> 活动结构体
    mapping(uint256 => actively) activelyList; //所有活动
    //活动id  --> 参与活动的用户用户信息
    mapping(uint256 => user[]) activelyUserList; //活动参与的全部用户资料

    mapping(uint256 => mapping(address => bool)) isActiveted; //判断当前活动下的当前用户是否参与
}

contract Study2 is asstes {
    address immutable owner; //immutable在合约的构造函数中确定

    constructor() {
        owner = msg.sender;
    }

    //判断用户是否重复参加的修饰器
    modifier judgeUserActived(uint activeId) {
        require(isActiveted[activeId][msg.sender] == false);
        _;
    }

    //判断是否是owner
    modifier isOWner() {
        require(msg.sender == owner);
        _;
    }

    //创建募资活动
    //addre 收款地址
    //total 募资的总量
    //return 返回当前活动的Id
    function createActive(address payable _address, uint _total)
        external
        isOWner
        returns (uint256 activeId)
    {
        uint256 startId = startNumber++;
        actively storage activeStr = activelyList[startId];
        activeStr.addr = _address;
        activeStr.total = _total;
        activelyList[startId] = activeStr;
        return startId;
    }

    //用户参与
    function bid(uint256 activeId) external payable judgeUserActived(activeId) {
        actively storage c = activelyList[activeId];
        c.userTotal += msg.value;
        c.count += 1;
        activelyUserList[activeId].push(
            user({addr: msg.sender, amount: msg.value})
        );
        isActiveted[activeId][msg.sender] = true;
    }

    //取款
    function withdraw(uint256 activeId) external returns (bool reached) {
        actively storage c = activelyList[activeId];
        if (c.count < c.total) {
            return false;
        }
        uint amount = c.count;

        c.total = 0;

        c.addr.transfer(amount);
        return true;
    }
}