/**
 *Submitted for verification at Etherscan.io on 2022-06-01
*/

// SPDX-License-Identifier: MIT
pragma solidity >=0.7.0 <0.9.0;

contract Ballot {
    //提案状态
    enum ProposalState {
        created,
        approved,
        provisioned,
        rejected,
        deleted
    }

    //提案选项
    struct ProposalOption {
        bytes32 name; //选项名
    }

    //提案
    struct Proposal {
        uint256 id; //ID
        bytes32 name; //提案名
        bytes content; //提案内容
        uint256 voteCount; //已获得票数
        address chairPerson; //发起人
        ProposalState state; //状态
        uint8 maxChooseCount; //最大选择数量
    }

    // uint256 提案ID
    // bytes32 选项
    // address[] 该选项下所有投票者
    mapping(uint256 => mapping(bytes32 => address[])) public proposalsVoters;

    //所有提案，类型为动态大小的 Proposal 数组
    Proposal[] public proposals;

    //创建提案
    function createProposal(
        bytes32 proposalName,
        bytes memory proposalContent,
        bytes32[] memory options,
        uint8 maxChooseCount
    ) public {
        for (uint256 index = 0; index < options.length; index++) {}
        Proposal memory proposal = Proposal({
            id: proposals.length,
            name: proposalName,
            content: proposalContent,
            voteCount: 0,
            chairPerson: msg.sender,
            state: ProposalState.created,
            maxChooseCount: maxChooseCount
        });
        proposals.push(proposal);
    }

    //投票
    function vote(uint256 proposalID, bytes32[] memory options) public {
        //禁止给自己投票
        Proposal storage proposal = proposals[proposalID];
        require(
            msg.sender != proposal.chairPerson,
            "You can't vote on your own proposal"
        );
        //查看是否投过票
        bool voted = false;
        for (uint256 index = 0; index < options.length; index++) {
            bytes32 option = options[index];
            address[] storage voters = proposalsVoters[proposalID][option];
            for (uint256 vIndex = 0; vIndex < voters.length; vIndex++) {
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

        for (uint256 index = 0; index < options.length; index++) {
            bytes32 option = options[index];
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
}