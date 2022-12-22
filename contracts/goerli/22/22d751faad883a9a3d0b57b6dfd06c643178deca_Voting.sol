/**
 *Submitted for verification at Etherscan.io on 2022-12-22
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.6.0;
pragma experimental ABIEncoderV2;




contract Voting {
    //-------------------------------------------------------------------------
    //存储每个投票人的信息
    struct voter {
        //投票人持有的投票通证数量
        uint ticket;
        //投票人账户地址
        address voterAddress;
        //为每个候选人消耗的选票数量
        uint[] tokensUsedPerCandidate;
    }
    //投票人信息
    mapping(address => voter) private voterInfo;
    //-------------------------------------------------------------------------

    //每个候选人获得的投票
    mapping(bytes => uint) private votesReceived;
    //候选人名单
    bytes[] public candidateList;

    //发行的投票通证总量
    uint public totalTickets;
    //投票通证剩余数量
    uint public remainTickets;

    //投票成功事件
    event voteSucc(address, bytes, uint);

    constructor(
        uint tokens, //总票数
        bytes[] memory candidateNames, //投票候选人
        address[] memory voters //投票者地址
    ) public {
        for (uint i = 0; i < voters.length; i++) {
            voterInfo[voters[i]].voterAddress = voters[i];
            voterInfo[voters[i]].ticket = 1;
        }
        candidateList = candidateNames;
        totalTickets = tokens;
        remainTickets = tokens;
    }

    //获取候选人获得的票数
    function totalVotesFor(bytes memory candidate) public view returns (uint) {
        return votesReceived[candidate];
    }

    //为候选人投票，并使用一定数量的通证表示其支持力度
    function voteForCandidate(bytes memory candidate) public {
        //判断被投票候选人是否存在
        uint index = indexOfCandidate(candidate);
        require(index != uint(-1));
        require(voterInfo[msg.sender].ticket == 1);

        //初始化 tokensUsedPerCandidate
        if (voterInfo[msg.sender].tokensUsedPerCandidate.length == 0) {
            for (uint i = 0; i < candidateList.length; i++) {
                voterInfo[msg.sender].tokensUsedPerCandidate.push(0);
            }
        }

        //验证投票人是否已经投票
        uint availableTokens = voterInfo[msg.sender].ticket;
        require(availableTokens >= 1);
        votesReceived[candidate] += 1;
        voterInfo[msg.sender].tokensUsedPerCandidate[index] += 1;
        voterInfo[msg.sender].ticket = 0;

        emit voteSucc(msg.sender, candidate, votesReceived[candidate]);
    }

    //获取候选人的下标
    function indexOfCandidate(bytes memory candidate) public view returns (uint) {
        for (uint i = 0; i < candidateList.length; i++) {
            if (keccak256(candidateList[i]) == keccak256(candidate)) {
                return i;
            }
        }
        return uint(-1);
    }

    //投票者详情
    function voterDetails(address user) public view returns (uint, uint[] memory) {
        return (voterInfo[user].ticket, voterInfo[user].tokensUsedPerCandidate);
    }

    //获取所有竞选者
    function allCandidates() public view returns (bytes[] memory) {
        return candidateList;
    }

    //test
    function voteFor(bytes memory user, uint tokenNumber) public {
        uint index = indexOfCandidate(user);
        require(index != uint(-1));
        votesReceived[user] += tokenNumber;
    }
}

//参与者（Johb,Bob),["0x4a6f686e","0x426f62"]
//允许参与投票的账户地址["0x2287f964399790c3f577274ef53Dd7db9DCfc7e5","0xFd0DCa61806Acb1F534ab985cA7c7A69a37A49c5"]