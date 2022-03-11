/**
 *Submitted for verification at Etherscan.io on 2022-03-11
*/

// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.0;


// import "hardhat/console.sol";

contract Project{
    string public DESCRIPTION;
    string public GUIDELINE;
    uint public NUM_OF_VALIDATORS;
    uint public VALIDATOR_FEE;
    uint public VALIDATING_FEE;

    struct Task {
        string url;
        address asker;
        uint value;
        bool isInVotingPahse;
        bool isSolved;
        uint solutionId;
    }

    struct Vote{
        address voter;
        bytes32 voteHash;
        uint value; // 0 didn't vote, 1 true, 2 false, 3 spoiled
    }

    struct Solution {
        uint taskId;
        address solver;
        string url;
        uint firstVotigIndex;
        uint numOfVotes;
    }

    Vote[] public votes;

    address[] public validatorPool;
    Task[] public tasks;
    Solution[] public solutions;

    constructor(
        string memory description,
        string memory guideline,
        uint numOfValidators,
        uint validatorFee,
        uint validatingFee) {
        DESCRIPTION = description;
        GUIDELINE = guideline;
        NUM_OF_VALIDATORS = numOfValidators;
        VALIDATOR_FEE = validatorFee;
        VALIDATING_FEE = validatingFee;
    }

    function hashVoteNonce(address addr, uint vote, uint nonce) public pure returns(bytes32){
        return keccak256(abi.encodePacked(addr, nonce, vote));
    }

    function beAValidator() public{ // TODO: make this payable
        validatorPool.push(msg.sender);
    }

    function createTask(string calldata url) public payable{
        require(msg.value > VALIDATOR_FEE, "You need to pay more than the validator fee");
        Task memory task = Task(url, msg.sender, msg.value, false, false, 0);
        tasks.push(task);
    }

    function _chooseValidators(uint solutionId) internal returns(uint, uint){
        // require(solutionId < solutions.length, "Solution does not exist");
        // Randomly select NUM_OF_VALIDATORS validators
        require(validatorPool.length > 1, "Not enough validator pool");
        // console.log("Selamm");
        uint numOfValidators = NUM_OF_VALIDATORS;
        if (numOfValidators > validatorPool.length - 1) {
            numOfValidators = validatorPool.length - 1;
        }
        uint index = 0;
        uint firstVotingIndex = votes.length;
        // console.log("First voting index = ");
        // console.log(firstVotingIndex);
        for(uint i = 0; i < numOfValidators; i++){
            // console.log(i);
            uint nonce = 0;
            while(true){
                uint randomIndex = uint(keccak256(abi.encodePacked(solutionId, i, nonce))) % validatorPool.length;
                bool flag = false;
                for(uint j = firstVotingIndex; j < firstVotingIndex + i; j++){
                    if(validatorPool[randomIndex] == votes[j].voter){
                        flag = true;
                        break;
                    }
                }
                if(validatorPool[randomIndex] != msg.sender && !flag){
                    index = randomIndex;
                    break;
                }
                nonce += 1;
            }
            votes.push(Vote(validatorPool[index], 0, 0));
        }
        return (firstVotingIndex, numOfValidators);
    }

    function solveTask(uint taskId, string calldata url) public payable{
        require(msg.value == VALIDATING_FEE, "You need to pay at least the validating fee");
        require(taskId < tasks.length, "Task does not exist");
        require(tasks[taskId].isSolved == false, "Task is already solved");
        require(tasks[taskId].isInVotingPahse == false, "Task is already in voting phase");
        // console.log("Geldiii\n");

        (uint firstVotingIndex, uint numOfVotes) = _chooseValidators(solutions.length);
        // console.log(firstVotingIndex);
        // console.log(numOfVotes);
        solutions.push(Solution(taskId, msg.sender, url, firstVotingIndex, numOfVotes));
        tasks[taskId].isInVotingPahse = true;
    }

    function isVotingHashesDone(uint solutionId) internal view returns (bool){
        require(solutionId < solutions.length, "Solution does not exist");
        for(uint i = solutions[solutionId].firstVotigIndex; i < solutions[solutionId].firstVotigIndex + solutions[solutionId].numOfVotes; i++){
            if(votes[i].voteHash == 0){
                return false;
            }
        }
        return true;
    }

    function isVotingDone(uint solutionId) internal view returns (bool){
        require(solutionId < solutions.length, "Solution does not exist");
        for(uint i = solutions[solutionId].firstVotigIndex; i < solutions[solutionId].firstVotigIndex + solutions[solutionId].numOfVotes; i++){
            if(votes[i].value == 0){
                return false;
            }
        }
        return true;
    }

    function givePositiveReward(uint solutionId) internal {
        for(uint i = solutions[solutionId].firstVotigIndex; i < solutions[solutionId].firstVotigIndex + solutions[solutionId].numOfVotes; i++){
            if(votes[i].value == 1){
                _transfer(votes[i].voter, VALIDATING_FEE/NUM_OF_VALIDATORS);
            }
        }
    }

    function giveNegativeReward(uint solutionId) internal {
        for(uint i = solutions[solutionId].firstVotigIndex; i < solutions[solutionId].firstVotigIndex + solutions[solutionId].numOfVotes; i++){
            if(votes[i].value == 2){
                _transfer(votes[i].voter, VALIDATING_FEE/NUM_OF_VALIDATORS);
            }
        }
    }

    function endVoting(uint solutionId) public {
        require(solutionId < solutions.length, "Solution does not exist");
        require(isVotingDone(solutionId), "Voting is not done");
        // require(isVotingHashesDone(solutionId), "Voting hashes are not done");

        uint totalPositiveVotes = 0;
        uint totalNegativeVotes = 0;
        for(uint i = solutions[solutionId].firstVotigIndex; i < solutions[solutionId].firstVotigIndex + solutions[solutionId].numOfVotes; i++){
            if(votes[i].value == 1){
                totalPositiveVotes++;
            } else if(votes[i].value == 2){
                totalNegativeVotes++;
            }
        }
        if(totalPositiveVotes > totalNegativeVotes){
            givePositiveReward(solutionId);
            _transfer(solutions[solutionId].solver, tasks[solutions[solutionId].taskId].value);
            tasks[solutions[solutionId].taskId].isSolved = true;
            tasks[solutions[solutionId].taskId].solutionId = solutionId;
        } else {
            giveNegativeReward(solutionId);
            tasks[solutions[solutionId].taskId].isInVotingPahse = false;
        }
    }

    function _transfer(address _to, uint _value) internal {
        payable(_to).transfer(_value);
    }

    function contractBalance() internal view returns (uint){
        return address(this).balance;
    }

    function spoilAVote(uint solutionId, uint voteId, uint voteNonce, uint vote) public{
        require(solutionId < solutions.length, "Solution does not exist");
        require(voteId > solutions[solutionId].firstVotigIndex, "Vote does not exist");
        require(voteId < solutions[solutionId].firstVotigIndex + solutions[solutionId].numOfVotes, "Vote does not exist");
        require(votes[voteId].voteHash != 0, "You can't spoil a vote that you already spoiled");
        require(!isVotingHashesDone(solutionId), "You can't spoil a vote after all votes are done");
        if(votes[voteId].voteHash == keccak256(abi.encodePacked(votes[voteId].voter, voteNonce, vote))){
            votes[voteId].value = 3;
            _transfer(msg.sender, VALIDATING_FEE);
        }
    }

    function submitVotingNonce(uint solutionId, uint voteId, uint voteNonce, uint vote) public {
        require(solutionId < solutions.length, "Solution does not exist");
        require(voteId >= solutions[solutionId].firstVotigIndex, "Vote does not exist");
        require(voteId < solutions[solutionId].firstVotigIndex + solutions[solutionId].numOfVotes, "Vote does not exist");
        require(votes[voteId].voteHash != 0, "You can't spoil a vote that you already spoiled");
        require(isVotingHashesDone(solutionId), "You can't spoil a vote after all votes are done");
        if(votes[voteId].voteHash == keccak256(abi.encodePacked(votes[voteId].voter, voteNonce, vote))){
            votes[voteId].value = vote;
        }
    }

    function voteForValidation(uint solutionId, bytes32 voteHash) public payable{
        require(solutionId < solutions.length, "Solution does not exist");
        require(msg.value == VALIDATING_FEE, "You need to pay at least the validating fee");

        for(uint i = solutions[solutionId].firstVotigIndex; i < solutions[solutionId].firstVotigIndex + solutions[solutionId].numOfVotes; i++){
            if(votes[i].voter == msg.sender){
                require(votes[i].voteHash == 0, "You can't vote twice");
                votes[i].voteHash = voteHash;
            }
        }
    }

}