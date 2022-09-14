/**
 *Submitted for verification at Etherscan.io on 2022-09-14
*/

// SPDX-License-Identifier: MIT
pragma solidity >=0.8.7;
// import "hardhat/console.sol";

//一个投票的合约
contract Ballot{
    struct Voter{
        uint8 weight;//投票的权重
        bool voted; //是否已经投票
        address delegate;//投票委托人
        uint8 vote;//提案对象索引
    }
    //提案对象
    struct Proposal{
        string name;
        uint voteCount;//累计票数
    }

    //主席
    address public chairperson;

    mapping(address=>Voter)public voters;

    //提案对象数组
    Proposal[] public proposals;

    constructor(string[] memory proposalNames){
        chairperson = msg.sender;
        
        voters[chairperson].weight = 1;

        //循环创建提案对象
        for (uint i = 0; i < proposalNames.length; i++) {
            proposals.push(Proposal({
                name: proposalNames[i],
                voteCount: 0
            }));
        }
    }
    //主席赋予投票权
    //外部函数
    function giveRightToVote(address voter) external{
        require(msg.sender == chairperson,"Only chairperson can give right to vote.");
        require(!voters[voter].voted,"The voter already voted");
        require(voters[voter].weight == 0);
        voters[voter].weight = 1;
    }
    //投票委托
    function delegate(address to) external {
        //使用storage类似与指针引用
        //使用memory类似与复制一个副本，修改操作不会在voters上生效
        Voter storage sender = voters[msg.sender];
        require(sender.weight != 0,"You have no right to vote.");
        require(!sender.voted,"You already voted.");
        require(to != msg.sender,"Self-delegation is disallowed.");

        //委托可能存在循环的情况，
        while(voters[to].delegate != address(0)){
            to = voters[to].delegate;
            //阻止循环委托
            require(to != msg.sender,"Found loop in delegation");
        }

        Voter storage delegater = voters[to];
        require(delegater.weight >= 1);

        //已经投完票了
        sender.voted = true;
        sender.delegate = to;

        if(delegater.voted){
            //如果委托者，已经投票，则修改提案的获票数量
            proposals[delegater.vote].voteCount += sender.weight;
        }else{
            //没有投票的话，增加投票权重
            delegater.weight += sender.weight;
        }
    }

    //投票
    function vote(uint8 proposal) external{
        Voter storage sender = voters[msg.sender];
        require(!sender.voted,"You already voted");
        require(sender.weight != 0,"You have no right to vote.");
        sender.voted = true;
        sender.vote = proposal;
        proposals[proposal].voteCount += sender.weight;
    }

    //获取获胜的对象
    function winningProposal() public view returns (Proposal[] memory)
    {
        Proposal[] memory win = new Proposal[](proposals.length);
        uint8 winOrder = 0;
        uint winningVoteCount = 0;
        for(uint i=0;i < proposals.length;i++){
            if(proposals[i].voteCount > winningVoteCount){
                winningVoteCount = proposals[i].voteCount;
            }
        }

        for(uint m=0; m < proposals.length; m++){
            if(winningVoteCount == proposals[m].voteCount){
                // push can't use
                // win.push(proposals[m]);
                // next line can use
                win[winOrder] = proposals[m];
                winOrder++;
            }
        }
        return win;
    }
    //["way1","way2"]
    //获取获胜的最多票数
    function winningProposalCount() public view returns (uint count_)
    {
        uint winningVoteCount = 0;
        for(uint i=0;i < proposals.length;i++){
            if(proposals[i].voteCount > winningVoteCount){
                winningVoteCount = proposals[i].voteCount;
                count_ = proposals[i].voteCount;
            }
        }
    }
}