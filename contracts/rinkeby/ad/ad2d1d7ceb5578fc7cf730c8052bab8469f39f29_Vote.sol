// SPDX-License-Identifier: MIT

pragma solidity 0.8.7;



/* 第二周作業: vote contract
   基本功能:
    設置:
        加入候選人----------------V
        刪除候選人----------------X
        開始投票的功能------------V
        結束投票的功能------------V
        管理員-------------------V
        查看目前票數--------------V
        A :  30
        B :  59
    額外功能:
        白名單, 其他玩法.. etc。
*/

import "Context.sol";

contract Vote is Context{

    address public owner;
    string[] public candidates;
    mapping(string => int) public votes;
    mapping(string => uint) private index;
    mapping(address => uint) private voters;
    uint private count;
    string public winner;
    bool public voteStatus;
    event VoteStart();
    event VoteEnd();
    event Winner(string);

    constructor() {
        owner = msgSender();
    }

    modifier onlyOwner {
        require(msgSender() == owner, "Error");
        _;
    }

    function NumberOfCandidates() public view returns (uint) {
        return candidates.length;
    }

    function startVote() public onlyOwner {
        require(voteStatus == false, "Vote has already begun");
        voteStatus = true;
        emit VoteStart();
    }

    function endVote() public onlyOwner {
        require(voteStatus == true, "Vote hasn't begun");
        winner = candidates[0];
        for (uint i = 1; i < candidates.length; ++i) {
            if (votes[candidates[i]] > votes[winner]) {
                winner = candidates[i];
            }
        }
        emit VoteEnd();
        emit Winner(winner);
    }

    function addCandidates(string memory name) public onlyOwner {
        require(voteStatus == false, "Vote has begun");
        candidates.push(name);
        index[name] = count++;
    }

    function delCandidates(string memory name) public onlyOwner {
        require(voteStatus == false, "Vote has begun");
        delete candidates[index[name]];

    }

    function vote(string memory name) public {
        require(voteStatus == true, "No vote in session");
        require(voters[msgSender()] == 0, "You have already voted");
        voters[msgSender()] += 1;
        votes[name] += 1;
    }

}