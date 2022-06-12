/**
 *Submitted for verification at Etherscan.io on 2022-06-12
*/

// SPDX-License-Identifier: GPL-3.0

pragma solidity >=0.7.0 <0.9.0;

/** 
 * @title 投票
 */
contract Ballot {
   
    // 投票人
    struct Voter {
        uint weight; // 计票的权重
        bool voted;  // 如果为true，则代表此人已投票
        address delegate; // 被委托人
        uint vote;   // 投票的选项
    }

    // 选项
    struct Proposal {
        string name;   // 选项名
        uint voteCount; // 得票数
    }

    // 投票发起人
    address public chairperson;

    // 这里声明了一个状态变量，为每一个可能的地址存储一个投票人'Voter'
    mapping(address => Voter) public voters;
    address[] public votersAddressList;

    // 选项'Proposal'数组
    Proposal[] public proposals;

    // 通过选项名'proposalNames'数组，创建新投票
    constructor(string[] memory proposalNames){
        // 将合约创建者设置为投票主席
        chairperson = msg.sender;
        // 主席投票权重为1
        voters[chairperson].weight = 1;
        votersAddressList.push(chairperson);

        for (uint i = 0; i < proposalNames.length; i++) {
            // 循环遍历选项名'proposalNames'数组，添加到选项'Proposal'数组
            proposals.push(Proposal({
                name: proposalNames[i],
                voteCount: 0
            }));
        }
    }
    
    // 授权投票人 `voter` 投票权，只有主席可以调用
    function giveRightToVote(address voter) public {
        // 需要当前调用人是发起人
        require(
            msg.sender == chairperson,
            "Only chairperson can give right to vote."
        );
        // 需要该投票人未投票过
        require(
            !voters[voter].voted,
            "The voter already voted."
        );
        // 需要该投票人投票权重为0
        require(voters[voter].weight == 0);
        voters[voter].weight = 1;
        votersAddressList.push(voter);
    }

    // 委托投票权给到'to'
    function delegate(address to) public {
        Voter storage sender = voters[msg.sender];
        // 未投票过才能委托
        require(!sender.voted, "You already voted.");
        // 不能委托给自己
        require(to != msg.sender, "Self-delegation is disallowed.");

        // 委托可以传递，只要to也设置了委托
        while (voters[to].delegate != address(0)) {
            to = voters[to].delegate;

            // 发现循环委托
            require(to != msg.sender, "Found loop in delegation.");
        }
        sender.voted = true;
        sender.delegate = to;
        // 被委托者
        Voter storage delegate_ = voters[to];
        if (delegate_.voted) {
            // 被委托者如果已经有投票过，则直接增加得票数
            proposals[delegate_.vote].voteCount += sender.weight;
        } else {
            // 被委托者还没有投标，则增加投票权重
            delegate_.weight += sender.weight;
        }
    }

    // 将你的票（包括委托给你的票），投票给选项proposals[proposal].name
    function vote(uint proposal) public {
        Voter storage sender = voters[msg.sender];
        require(sender.weight != 0, "Has no right to vote");
        require(!sender.voted, "Already voted.");
        sender.voted = true;
        sender.vote = proposal;

        proposals[proposal].voteCount += sender.weight;
    }

    // 获取选项列表
    function getProposalNameList() public view
            returns (string[] memory)
    {
        string[] memory proposalNameList = new string[](proposals.length);
        for (uint i = 0; i < proposals.length; i++) {
            proposalNameList[i] = proposals[i].name;
        }
        return proposalNameList;
    }

    // 获取投票用户地址列表
    function getAddressList() public view
            returns (address[] memory)
    {
        return votersAddressList;
    }

    // 统计胜出的选项
    function winningProposal() public view
            returns (uint winningProposal_)
    {
        uint winningVoteCount = 0;
        for (uint p = 0; p < proposals.length; p++) {
            if (proposals[p].voteCount > winningVoteCount) {
                winningVoteCount = proposals[p].voteCount;
                winningProposal_ = p;
            }
        }
    }

    // 调用 winningProposal() 函数以获取选项数组中获胜者的索引，并以此返回获胜者的名称
    function winnerName() public view
            returns (string memory winnerName_)
    {
        winnerName_ = proposals[winningProposal()].name;
    }
}