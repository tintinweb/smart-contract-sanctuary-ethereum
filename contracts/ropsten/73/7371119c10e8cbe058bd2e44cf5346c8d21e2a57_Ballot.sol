/**
 *Submitted for verification at Etherscan.io on 2022-04-07
*/

// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.13;


contract Ballot {
    // 合约创建人
    address immutable owner = msg.sender;
    // 最大提案数量
    uint8 immutable maxProposal;
    /*
     constant 常量 编译时确定 
     immutable 不可修改变量  编译时或创建时确定 不可修改
    */
    uint8 constant maxParticipants = 10;

    // 提案数组
    Proposal[] public proposals;

    // 统计地址的投票数信息
    mapping(address=>uint) voteCounter;

    // 定义投票事件
    event voteEvent(address _address, uint8 proposalIndex, bytes2 proposalName);

    struct Proposal {
        bytes2 name;
        uint voteCount;
    }

    constructor(uint _maxProposal, bytes2[] memory proposalNames) {
        // 验证输入的数字是否超过了uint8的取值范围
        require(_maxProposal < type(uint8).max, "out of max count");
        maxProposal = uint8(_maxProposal);

        // 创建提案对象 添加到提案列表中
        for(uint i=0; i<proposalNames.length; i++) {
            /*
                创建结构体的语法是
                Struct({
                    key : value
                })
            */
            proposals.push(Proposal({
                name : proposalNames[i],
                voteCount : 0
            }));
        }
    }


    /*
        投票
    */
    function vote(uint8 proposalIndex) public returns(bool) {
        require(proposalIndex < proposals.length, "none proposal");
        voteCounter[msg.sender] += 1;
        proposals[proposalIndex].voteCount += 1;
        emit voteEvent(msg.sender, proposalIndex, proposals[proposalIndex].name);
        return true;
    }

    /*
        获取提案的投票统计
        不写view调用时会消耗gas
        
    */
    function countVote(uint8 proposalIndex) public view returns(uint) {
        require(proposalIndex < proposals.length, "none proposal");
        return proposals[proposalIndex].voteCount;
    }

    /*
        统计地址的投票数量
    */
    function countAddVote(address _address) public view returns(uint) {
        return voteCounter[_address];
    }
}