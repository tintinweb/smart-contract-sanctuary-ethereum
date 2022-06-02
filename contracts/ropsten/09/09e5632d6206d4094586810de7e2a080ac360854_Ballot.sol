// SPDX-License-Identifier: MIT
pragma solidity >=0.7.0 <0.9.0;
import './FinishContracts.sol';

contract Ballot {
    //提案创建完成
    event ProposalCreated(Proposal proposal);
    //投票完成
    event VoteFinish(uint proposalID, bytes option, address sender);
    //提案结束
    event ProposalFinish(uint proposalID);

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

    //投票历史
    struct VoteHistory {
        address sender; //地址
        bytes option; //投票类型
    }

    //已结束合约
    FinishContracts finishContracts;

    // uint 提案ID
    // bytes 选项
    // address[] 该选项下所有投票者
    mapping(uint => mapping(bytes => address[])) private proposalsVoters;

    //所有提案，类型为动态大小的 Proposal 数组
    Proposal[] private proposals;

    //投票历史
    mapping(uint => VoteHistory[]) private voteHistoryMap;

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
        //禁止给自己投票
        Proposal storage proposal = proposals[proposalID];
        require(
            msg.sender != proposal.chairPerson,
            "You can't vote on your own proposal"
        );
        //禁止给结束的提案投票
        require(proposal.state == ProposalState.created, "The proposal is finished");
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
            voters.push(msg.sender);
            emit VoteFinish(proposalID,option,msg.sender);
        }
        //更新投票历史
        VoteHistory[] storage historyList = voteHistoryMap[proposalID];
        for (uint index = 0; index < options.length; index++) {
            bytes memory option = options[index];
            historyList.push(
                VoteHistory({sender: msg.sender, option: option})
            );
        }
    }

    //所有提案列表
    function allProposal() public view returns (Proposal[] memory) {
        return proposals;
    }

    //获取某个提案某个选项所有投票
    function getVoters(uint proposalID, bytes memory option)
        public
        view
        returns (address[] memory)
    {
        return proposalsVoters[proposalID][option];
    }

    //手动结束提案
    function finishProposal(uint proposalID) public {
        Proposal storage proposal = proposals[proposalID];
        proposal.state = ProposalState.provisioned;
        finishContracts.finish();
        emit ProposalFinish(proposalID);
    }

    // 获取某个提案下投票历史
    function proposalVoteHistory(uint proposalID)
        public
        view
        returns (VoteHistory[] memory)
    {
        return voteHistoryMap[proposalID];
    }

    //获取当前时间
    function getNowTime() private view returns (uint) {
        return block.timestamp;
    }

}