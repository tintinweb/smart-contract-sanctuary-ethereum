/**
 *Submitted for verification at Etherscan.io on 2022-07-13
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.7;

contract BallotHeng{
    ///投票人
    struct Voter{
        uint weight; //投票权重
        bool voted; //是否已经投过票 true为已投票
        address delegate; //代理投票地址
        uint vote; //投票的提案索引
    }

    ///提案
    struct Proposal{
        bytes32 name; //提案名称
        uint voteCount; //提案所得票数
    }

    //主席
    address public chairperson;
    //地址投票人映射关系
    mapping (address => Voter) public voters;
    //提案数组集合
    Proposal[] public proposals;
    
    //构造函数传入提案名称集合
    constructor(string[] memory proposalNames){
        chairperson = msg.sender;
        voters[chairperson].weight = 1;

        for(uint i = 0; i < proposalNames.length; i++){
            proposals.push(Proposal({name: stringToBytes32(proposalNames[i]), voteCount: 0}));
        }
    }

    function stringToBytes32(string memory source) public pure returns (bytes32 result) {
        bytes memory tempEmptyStringTest = bytes(source);
        if (tempEmptyStringTest.length == 0) {
        return 0x0;
        }

        assembly {
            result := mload(add(source, 32))
        }
    }

    //给予投票权利
    function giveRightToVote(address voter) external view {
        require(msg.sender == chairperson, "Only chairperson arrow give right to vote");
        require(voter != address(0), "invalid address");
        require(!voters[voter].voted, "The voter already voted.");
        require(voters[voter].weight == 0);
        voters[voter].weight == 1;
    }

    //委托代理
    function delegate(address to) external {
        require(to != address(0));  //防止委托给0地址
        require(msg.sender != to, "You can't delegate yourself");
        Voter storage sender = voters[msg.sender];
        require(!sender.voted, "You are already voted.");
        require(sender.weight != 0, "You have no right to vote");
        while(voters[to].delegate != address(0)){
            //A委托了B，B委托了C时需要循环交给最后一个委托人
            to = voters[to].delegate;
            //当A委托了B，B的委托人为A时会出现死循环所以to 的委托人不能为 msg.sender
            require(to != msg.sender, "Found loop in delegation.");
        }

        Voter storage delegate_ = voters[to];

        require(delegate_.weight >= 1);
        
        if(delegate_.voted){
            //如果受委托人已经投过票，将票数直接加到他投票的提按中
            proposals[delegate_.vote].voteCount += sender.weight;
        }else{
            delegate_.weight += sender.weight;
        }

    }

    //投票
    function vote(uint proposalsIndex) external {
        Voter storage voter = voters[msg.sender];
        require(!voter.voted, "You already voted.");
        require(voter.weight > 0, "You don't get a vote");
        voter.voted = true;
        voter.vote = proposalsIndex;
        proposals[proposalsIndex].voteCount += voter.weight;
    }

    //获取投票获胜提案索引
    function winnerProposalIndex() public view returns (uint proposalsIndex) {
        uint maxCount;
        for(uint i = 0; i < proposals.length; i++) {
            if( proposals[i].voteCount > maxCount){
                maxCount = proposals[i].voteCount;
                proposalsIndex = i;
            }  
        }
    }

    //获取投票获胜提案名称
    function winnerProposalName() external view returns (bytes32 winnerName_) {
        winnerName_ =  proposals[winnerProposalIndex()].name;
    }
}