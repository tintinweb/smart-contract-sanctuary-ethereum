/**
 *Submitted for verification at Etherscan.io on 2022-06-01
*/

// SPDX-License-Identifier: MIT
pragma solidity >=0.7.0 <0.9.0;

contract Ballot {
    //提案创建完成
    event ProposalCreated(Proposal proposal);

    //提案状态
    enum ProposalState {
        created, //进行中
        approved, //已通过
        provisioned, //已执行
        rejected //未通过
    }

    //提案
    struct Proposal {
        uint id; //ID
        bytes name; //提案名
        bytes content; //提案内容
        address chairPerson; //发起人
        ProposalState state; //状态
        bytes[] options; //投票选项
        uint timeStamp; //提案创建时间
    }

    // uint 提案ID
    // bytes 选项
    // address[] 该选项下所有投票者
    mapping(uint => mapping(bytes => address[])) private proposalsVoters;

    //所有提案，类型为动态大小的 Proposal 数组
    Proposal[] private proposals;

    //创建提案
    function createProposal(
        bytes memory proposalName,
        bytes memory proposalContent,
        bytes[] memory options
    ) public {
        Proposal memory proposal = Proposal({
            id: proposals.length,
            name: proposalName,
            content: proposalContent,
            chairPerson: msg.sender,
            state: ProposalState.created,
            options: options,
            timeStamp: getNowTime()
        });
        proposals.push(proposal);
        emit ProposalCreated(proposal);
    }

    //投票
    function vote(uint proposalID, bytes[] memory options) public {
        checkProposalState();
        //禁止给自己投票
        Proposal storage proposal = proposals[proposalID];
        require(
            msg.sender != proposal.chairPerson,
            "You can't vote on your own proposal"
        );
        //查看是否投过票
        bool voted = false;
        for (uint index = 0; index < options.length; index++) {
            bytes memory option = options[index];
            address[] memory voters = proposalsVoters[proposalID][option];
            for (uint vIndex = 0; vIndex < voters.length; vIndex++) {
                address voterAddress = voters[vIndex];
                if (voterAddress == msg.sender) {
                    //已投过
                    voted = true;
                    break;
                }
            }
        }
        require(!voted, "Already voted");
        //开始投票

        for (uint index = 0; index < options.length; index++) {
            bytes memory option = options[index];
            address[] storage voters = proposalsVoters[proposalID][option];
            if (voters.length > 0) {
                voters.push(msg.sender);
            } else {
                proposalsVoters[proposalID][option] = [(msg.sender)];
            }
        }
    }

    //所有提案列表
    function allProposal() public view returns (Proposal[] memory) {
        return proposals;
    }

    //获取某个提案某个选项所有投票
    function proposalVoters(uint proposalID, bytes memory option)
        public view
        returns (address[] memory)
    {
        return proposalsVoters[proposalID][option];
    }

    //检查提案状态
    function checkProposalState() public {
        for (uint index = 0; index < proposals.length; index++) {
            Proposal storage proposal = proposals[index];
            if (proposal.state == ProposalState.created) {
                //检查状态
                uint interval = block.timestamp - proposal.timeStamp;
                if (interval > 60) {
                    //检查投票结果
                    proposal.state = ProposalState.provisioned;
                }
            }
        }
    }

    function getNowTime() private view returns (uint) {
        return block.timestamp;
    }
}