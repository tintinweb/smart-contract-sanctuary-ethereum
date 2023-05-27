/**
 *Submitted for verification at Etherscan.io on 2023-05-26
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

contract SimpleVote {
    struct Project {
        // project name
        string name;
        // 資金を受け取るaddress
        address payable addr;
        // 目標資金
        uint256 targetFunding;
    }
    // 構造体Projectのインスタンス
    Project project;
    // projectのオーナー
    address public owner;
    // 投票数を管理
      // 賛成票数
    uint256 public yesVotes;
      // 反対票数
    uint256 public noVotes;
    // closedしたvotingかどうかの記録
    bool public votingClosed;
    // 投票者が投票したかどうかの記録
    mapping(address => bool) hasVoted;


    // events
    event Voted(address indexed addr, bool isYes);
    event Deposited(address sender, uint256 amount);

    // initialize the vote with the project details
    constructor(string memory _projectName, address payable _projectAddr, uint _targetFunding) {
        project = Project(_projectName, _projectAddr, _targetFunding);
        owner = msg.sender;
    }

    /*
      @dev: deposit funds to the contract
    */
    // deposit funds→関数の中身は記述ないけど、payableがついている関数は、coinを受け取れるんだ。
    function deposit() public payable {
        emit Deposited(msg.sender, msg.value);
    }

    // vote
    /*
      @dev: vote on the project
      @param isYes: true if the voter is voting yes, false if the voter is voting no
    */
    function vote(bool isYes) public {
        // require that the voting is still open
        require(!votingClosed, "Voting is closed");
        // require that the voter has not voted before
        require(!hasVoted[msg.sender], "You have already voted");

        if (isYes) {
            yesVotes++;
        } else {
            noVotes++;
        }

        // mark the voter as having voted
        hasVoted[msg.sender] = true;

        emit Voted(msg.sender, isYes);
    }

    // close the voting
    function closeVoting() public {
        // only contract owner can close the voting
        require(msg.sender == owner, "Only the owner can close the voting");
        votingClosed = true;
    }

    // release the funds
    function releaseFunds() public {
        // require that the owner is calling this function
        require(msg.sender == owner, "Only the owner can release the funds");
        // require that the voting is closed
        require(votingClosed, "Voting is still open");
        // require that the yes votes are more than the no votes
        require(yesVotes > noVotes, "The vote did not pass");
        // require that the contract has enough funds
        require(address(this).balance >= project.targetFunding, "Not enough funds");

        (bool success, ) = project.addr.call{value: address(this).balance}("");
        require(success, "Failed to send funds to the winning project");
    }
}