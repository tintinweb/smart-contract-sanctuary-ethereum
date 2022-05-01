/**
 *Submitted for verification at Etherscan.io on 2022-05-01
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract VoteBest {
    address creator;
    constructor() {
        creator = msg.sender;
    }

    /// @dev 候选人
    struct candidate {
        /// @dev 得票数
        uint8 votes;
    }

    candidate tsy = candidate(0);
    candidate zc = candidate(0);
    candidate pml = candidate(0);
    candidate wzy = candidate(0);

    /// @dev 每个地址只有一次投票权
    mapping(address => bool) voters;

    /// @dev 投票成功触发事件
    event VoteSuccessfully(address voter);

    /// @dev 检查该地址是否投过票
    modifier checkVoted() {
        require(voters[msg.sender] == false, "You have voted!");
        _;
    }

    /// @dev 投票后取消再次投票资格
    function voted() private {
        voters[msg.sender] = true;
        emit VoteSuccessfully(msg.sender);
    }


    // 投票函数
    function vote_tsy() public checkVoted {
        tsy.votes++;
        voted();
    }

    function vote_zc() public checkVoted {
        zc.votes++;
        voted();
    }

    function vote_pml() public checkVoted {
        pml.votes++;
        voted();
    }

    function vote_wzy() public checkVoted {
        wzy.votes++;
        voted();
    }

    // 展示函数
    function show_tsy() public view returns (uint8) {
        return tsy.votes;
    }

    function show_zc() public view returns (uint8) {
        return zc.votes;
    }

    function show_pml() public view returns (uint8) {
        return pml.votes;
    }

    function show_wzy() public view returns (uint8) {
        return wzy.votes;
    }
    
    // 随机挑选胜者
    function randomPick() public view returns (uint) {
        require(msg.sender == creator, "You have no right!");
        uint random = uint(keccak256(abi.encodePacked(block.difficulty)));
        return random % 4;
    }
}