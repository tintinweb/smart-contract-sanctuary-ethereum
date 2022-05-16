/**
 *Submitted for verification at Etherscan.io on 2022-05-16
*/

// SPDX-License-Identifier: GPL-3.0
pragma solidity >=0.7.0 <0.9.0;

/// @title 委托投票
contract Ballot {     // 这里声明了一个新的复合类型用于稍后的变量

    struct Voter {      // 它用来表示一个选民
        uint weight; // 计票的权重
        bool voted;  // 若为真，代表该人已投票
        address delegate; // 被委托人
        uint vote;   // 投票提案的索引，表示第几号提案，而不是vote的票数。得票数是proposal.votecount。
    }

    struct Proposal {     // 提案的类型
        bytes32 name;   // 简称（最长32个字节）
        uint voteCount; // 得票数
    }

    address public chairperson;
    mapping(address => Voter) public voters;     // 这声明了一个状态变量，为每个可能的地址存储一个 `Voter`。
    Proposal[] public proposals;     // 一个 `Proposal` 结构类型的动态数组。proposals表示一类变量，该变量是由结构为struct的proposal组成的数组。

    constructor(bytes32[] memory proposalNames) {     /// 为 `proposalNames` 中的每个提案，创建一个新的（投票）表决
        chairperson = msg.sender;
        voters[chairperson].weight = 1;         //对于提供的每个提案名称，        //创建一个新的 Proposal 对象并把它添加到数组的末尾。
        for (uint i = 0; i < proposalNames.length; i++) {              // `Proposal({...})` 创建一个临时 Proposal 对象，
            proposals.push(Proposal({             // `proposals.push(...)` 将其添加到 `proposals` 的末尾
                name: proposalNames[i],
                voteCount: 0
            }));
        }
    }

    function giveRightToVote(address voter) public {     // 授权 `voter` 对这个（投票）表决进行投票      // 只有 `chairperson` 可以调用该函数。
        require(msg.sender == chairperson, "Only chairperson can give right to vote.");
         // 若 `require` 的第一个参数的计算结果为 `false`，则终止执行，撤销所有对状态和以太币余额的改动。
        require(!voters[voter].voted, "The voter already voted.");
         // 使用 require 来检查函数是否被正确地调用，是一个好习惯。你也可以在 require 的第二个参数中提供一个对错误情况的解释。
        require(voters[voter].weight == 0);
//检查三个方面。1，调用地址必须是合约发起地址，2，这个地址没有vote过。3，这个地址的投票权重是0.
        voters[voter].weight = 1;
    }





    function delegate(address to) public {      /// 把你的投票委托到投票者 `to`。
        Voter storage sender = voters[msg.sender];         
        
        // 传引用。临时创建一个变量sender，是voter类型的。
        //voters是一个mapping，所以voters[msg.sender]对应的是voters的键值，也就是一个类型为struct的一个voter的值。
        //所以上面的语句就是给sender赋值。让类型为voter类型的struct变量sender等于另外一个struct变量，其值为发送消息的钱包地址所对应的值。

        require(!sender.voted, "You already voted.");
        require(to != msg.sender, "Self-delegation is disallowed.");


        // 委托是可以传递的，只要被委托者 `to` 也设置了委托。一般来说，这种循环委托是危险的。因为，如果传递的链条太长，
        // 则可能需消耗的gas要多于区块中剩余的（大于区块设置的gasLimit），这种情况下，委托不会被执行。而在另一些情况下，如果形成闭环，则会让合约完全卡住。
        //这个while循环在这有什么意义？address（0）又是代表什么？意义是排除闭环委托。
        while (voters[to].delegate != address(0)) {      
            to = voters[to].delegate;  //这一句的意义是什么？没看懂。
            require(to != msg.sender, "Found loop in delegation.");             // 不允许闭环委托
        }

        sender.voted = true;     // `sender` 是一个引用, 相当于对 `voters[msg.sender].voted` 进行修改
        sender.delegate = to;
        Voter storage delegate_ = voters[to];
        if (delegate_.voted) {
            proposals[delegate_.vote].voteCount += sender.weight;             // 若被委托者已经投过票了，直接增加得票数
        } else {
            delegate_.weight += sender.weight;   // 若被委托者还没投票，增加委托者的权重
        }
    }

    function vote(uint proposal) public {       /// 把你的票(包括委托给你的票)，投给提案 `proposals[proposal].name`.
        Voter storage sender = voters[msg.sender];
        require(!sender.voted, "Already voted.");
        sender.voted = true;
        sender.vote = proposal;
        proposals[proposal].voteCount += sender.weight;          // 如果 `proposal` 超过了数组的范围，则会自动抛出异常，并恢复所有的改动
    }

    function winningProposal() public view returns (uint winningProposal_) {      /// @dev 结合之前所有的投票，计算出最终胜出的提案
        uint winningVoteCount = 0;
        for (uint p = 0; p < proposals.length; p++) {   //遍历proposals里的每一个提案。
            if (proposals[p].voteCount > winningVoteCount) {   //如果某一个提案proposals[p]的得票数大于目前的最大得票数
                winningVoteCount = proposals[p].voteCount;    //那最大得票数等于当前提案的得票数
                winningProposal_ = p;         //当前提案的编号p作为胜利提案的编号。
            }
        }
    }

    function winnerName() public view returns (bytes32 winnerName_) {  // 调用winningProposal() 函数以获取提案数组中获胜者的索引，并以此返回获胜者的名称
        winnerName_ = proposals[winningProposal()].name;
    }
}