/**
 *Submitted for verification at Etherscan.io on 2022-09-19
*/

// SPDX-License-Identifier: NONE
// This code is copyright protected.
// All rights reserved © coinbird 2022

pragma solidity 0.8.17;

// https://coinbird.io - BIRD!
// https://twitter.com/coinbirdtoken
// https://github.com/coinbirdtoken
// https://t.me/coinbirdtoken
// https://github.com/coinbirdtoken/Cryptocurrency

contract BIRD_CONNECTOR {
    mapping(address => uint256) private _balances;

    function balanceOf(address account) public view returns (uint256) {
        return _balances[account];
    }
}

contract BIRD_VOTE {
    mapping(address => uint) private Vote; // To check what the address voted for in this round
    mapping(address => uint) private Voted; // To check whether the address voted in this round

    address[] private Voters; // A list of all the wallets that voted in this round
    
    uint private _votingRound = 1; // The current voting round
    
    uint private _outcomes; // The possible voting outcomes of this round in uint
    string[] private _explanations; // The possible voting outcomes of this round in text

    uint[] private _uResults; // Results of previews voting - uint
    string[] private _sResults; // Results of previews voting - text

    string private _previewsWinner;

    bool public _votingOpen; // If _open == true there is a voting currently taking place

    BIRD_CONNECTOR access;

    constructor() {
        access = BIRD_CONNECTOR(0x8792005de5D05bAD050C68D64e526Ce2062DFEFd);
    }

    // Below function returns what each vote is for (explanation)

    function readExplanations() public view returns (string[] memory) {
        return _explanations;
    }

    // Below function returns the current voting power of the voter address

    function readPower(address voter) public view returns (uint) {
        return access.balanceOf(voter);
    }

    // Below function returns the vote of the msg.sender for the current voting round

    function readMyVote() public view returns (string memory){
        require(Voted[msg.sender] == _votingRound, "No vote yet placed.");
        return _explanations[Vote[msg.sender]];
    }

    // Below function returns the number of wallets that voted for this round

    function readNumberOfVotes() public view returns (uint) {
        return Voters.length;
    }

    // Winner of last vote in string

    function readWinnerOfLastVote() public view returns (string memory) {
        return _previewsWinner;
    }

    // Voting process

    // Initiate a new voting round

    function newVotingRound(uint outcomes, string[] memory explanations) public {
        require(msg.sender == 0xfc34af4b28B003efF79d698e0f87af64e7724285, "forbidden"); // only the coinbird can initiate a new voting
        require(explanations.length == outcomes, "invalid");
        require(outcomes >= 2, "redundant");

        _explanations = explanations;
        _outcomes = outcomes;
        _votingOpen = true;
    }

    // Vote or change your vote

    function vote(uint outcome) public {
        require(access.balanceOf(msg.sender) > 0, "You don't own any BIRD!"); // You must own BIRD to vote
        require(_votingOpen == true, "No voting is currently taking place.");
        require(outcome < _outcomes, "Invalid.");
        
        Vote[msg.sender] = outcome;
        
        if (Voted[msg.sender] != _votingRound) {
            Voters.push(msg.sender);
            Voted[msg.sender] = _votingRound;
        }
    }

    // Close the currently active voting round and count the vote & voting power

    function closeAndCount() public {
        require(_votingOpen == true, "No voting is currently taking place.");
        require(msg.sender == 0xfc34af4b28B003efF79d698e0f87af64e7724285, "forbidden"); // only the coinbird can terminate a voting round

        uint j = Voters.length;
        uint dummy = 0;
        uint winner;

        _uResults = new uint[](_outcomes);

        for (uint i = 0; i < j ; i++) {
            uint x = Vote[Voters[i]];
            _uResults[x] += access.balanceOf(Voters[i]);
        }

        for (uint i = 0 ; i < _outcomes ; i++) {
            if(dummy < _uResults[i]) {
                dummy = _uResults[i]; // tie case handle
                winner = i;
            }
        }

        _previewsWinner = _explanations[winner];
        Voters = new address[](0);
        _explanations = new string[](0);
        _votingOpen = false;
        _votingRound += 1;
    }
}