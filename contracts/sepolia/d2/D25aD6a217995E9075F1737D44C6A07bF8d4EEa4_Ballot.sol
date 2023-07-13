/**
 *Submitted for verification at Etherscan.io on 2023-07-13
*/

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.9;

//import "hardhat/console.sol";

/// 为每个（投票）表决创建一份合约，为每个选项提供简称。 然后作为合约的创造者——即主席，将给予每个独立的地址以投票权。
/// 地址后面的人可以选择自己投票，或者委托给他们信任的人来投票。
/// 在投票时间结束时，winningProposal() 将返回获得最多投票的提案。

// @author dante
// @title 委托投票
contract Ballot {

  	// 选民
  struct Voter {
			uint weight; // 计票的权重（0票 、1票）
			bool voted; // 是否投票
			address delegate; // 被委托人
			uint voteIdx; // 投票提案的索引
  }

	// 提案
	struct Proposal {
			bytes32 name;	// 提案名称（最长32个字节）
			uint voteCount; // 得票数
	}

	address public chairperson; // 合约创造者，主席

	// 状态变量，为每一个可能的地址存储一个选民Voter
	mapping (address => Voter) public voters;

	// 提案数组
	Proposal[] public proposals;

	// 初始化，根据提案名称数组，创建一个新的提案
	constructor(bytes32[] memory _proposalNames) {
			chairperson = msg.sender;
			voters[chairperson].weight = 1;
			for (uint i = 0; i < _proposalNames.length; i++) {
					// `Proposal({...})` 创建一个临时 Proposal 对象，
					// `proposals.push(...)` 将其添加到 `proposals` 的末尾
					proposals.push(Proposal({
							name: _proposalNames[i],
							voteCount: 0
					}));
			}
	}

	// 主席chairperson授权选民Voter投票权
	function giveRightToVote(address voter) public {
			// console.log("current voter is %o <> %o", msg.sender, chairperson);
			// 只有主席可以授予选民投表权利
			require(msg.sender == chairperson, "Only chairperson can give right to vote");

			// 已经投过票的选民Voter不能二次投票
			require(!voters[voter].voted, "The voter already voted");

			// 不能二次授权
			require(voters[voter].weight == 0, "The voter already have right to vote");

			voters[voter].weight = 1;
	}

	// 委托投票，把你的投票委托到投票者 to
	function delegate(address to) public {
			// 传引用
			Voter storage sender = voters[msg.sender];
			// 已投票的不允许再投票
			require(!sender.voted, "You already voted");
			// 不能自己委托自己
			require(to != msg.sender, "Self-delegation is disallowed");

			// 追踪投票者的委托关系直到找到最终的委托代表
			// 通过将 to 赋值为当前投票者的委托地址，将委托关系向下传递，继续追踪下一个委托代表的地址。这样，循环会一直迭代直到找到最终的委托代表，即委托地址为零地址。
			while (voters[to].delegate != address(0)) {
							to = voters[to].delegate;
							// 不允许闭环委托
							require(to != msg.sender, "Found loop in delegation");
					}

			// `sender` 是一个引用, 相当于对 `voters[msg.sender].voted` 进行修改
			// 委托后，委托人不允许再投票（设置已经投过票了）
			sender.voted = true;
			sender.delegate = to;
			Voter storage delegate_ = voters[to];
			if(delegate_.voted) {
					// 若被委托者已经投过票了，直接增加得票数
					proposals[delegate_.voteIdx].voteCount += sender.weight;
			} else {
					// 若被委托者还没投票，增加委托者的权重
					delegate_.weight = 1;
			}
	}

	// 对提案进行投票（你自己的票和委托给你的票）
	function vote(uint proposalIdx) public {
			Voter storage sender = voters[msg.sender];
			require(!sender.voted, "You have already voted");
			sender.voted = true;
			sender.voteIdx = proposalIdx;
			// console.log("sender.weight is %o", sender.weight);
			// 增加提案投票数
			proposals[proposalIdx].voteCount += sender.weight;	// 如果 `proposal` 超过了数组的范围，则会自动抛出异常，并恢复所有的改动
		
	} 

	// 根据投票计算出最终胜利的提案（返回提案索引）
	function winningProposal() public view returns (uint winningProposal_) {
			uint winningVoteCount = 0;
			for (uint p = 0; p < proposals.length; p++) {
					if (proposals[p].voteCount > winningVoteCount) {
							winningVoteCount = proposals[p].voteCount;
							winningProposal_ = p;
					}
			}
	}

	// 调用 winningProposal() 函数以获取提案数组中获胜者的索引，并以此返回获胜者的名称
  function winnerName() public view returns (bytes32 winnerName_) {
			winnerName_ = proposals[winningProposal()].name;
	}

	// 如果您有一个数组类型的公有状态变量，那么您只能通过生成的getter函数获取数组中的单个元素，例如：myArray(0)。
	// 这种机制的存在是为了避免在返回整个数组时产生高昂的 gas fee。
	// 您可以使用参数来指定要返回的单个元素，例如myArray(0)。如果你想在一次调用中返回整个数组，那么你需要编写一个函数
	function getProposal() public view returns (Proposal[] memory) {
			return proposals;
	}

}