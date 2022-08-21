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
import "Ownable.sol";

library Math {

    function max(uint a, uint b) internal pure returns (uint) {
        return a > b ? a : b;
    }

    function min(uint a, uint b) internal pure returns (uint) {
        return a < b ? a : b;
    }

    function add(uint a, uint b) internal pure returns (uint) {
        return a + b;
    }

    function sub(uint a, uint b) internal pure returns (uint) {
        return a - b;
    }

}


contract Vote is Context, Ownable{

    using Math for uint256;

    struct Candidates {

        string name;
        uint votes;

    }

    Candidates[] private candidates;
    //mapping(string => int) public votes;
    //mapping(string => uint) private index;
    mapping(address => uint) private voters;
    uint private count;
    bool public voteStatus;
    event VoteStart();
    event VoteEnd();
    event Winner(Candidates);

    constructor () Ownable(msgSender()) {}

    function NumberOfCandidates() public view returns (uint) {
        return count;
    }

    function startVote() public onlyOwner {
        require(voteStatus == false, "Vote has already begun");
        voteStatus = true;
        emit VoteStart();
    }

    function endVote() public onlyOwner {
        require(voteStatus == true, "Vote hasn't begun");
        uint winner = 0;
        for (uint i = 1; i < candidates.length; ++i) {
            if (candidates[i].votes > candidates[winner].votes) {
                winner = i;
            }
        }
        emit VoteEnd();
        emit Winner(candidates[winner]);
    }

    function checkCandidates() public view returns (Candidates[] memory) {
        return candidates;
    }

    function addCandidates(string calldata _name) public onlyOwner {
        require(voteStatus == false, "Vote has begun");
        candidates.push(Candidates(_name, 0));
        count = count.add(1);
    }

    function delCandidates(uint index) public onlyOwner {
        require(voteStatus == false, "Vote has begun");
        delete candidates[index];
        count = count.sub(1);

    }

    function vote(uint index) public {
        require(voteStatus == true, "No vote in session");
        //require(voters[msgSender()] == 0, "You have already voted");
        voters[msgSender()] = voters[msgSender()].add(1);
        candidates[index].votes = candidates[index].votes.add(1);
    }

}