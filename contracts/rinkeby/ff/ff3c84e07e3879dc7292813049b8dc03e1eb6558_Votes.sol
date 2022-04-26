/**
 *Submitted for verification at Etherscan.io on 2022-04-26
*/

pragma solidity ^0.4.0;

contract Votes {
    address owner;
    
    address public electionWinnerAddress;
    uint public winnerVotes;
    string public electionWinner;
    
    Citizen[] public voters;
    Candidate[] public candidates;

    struct Citizen {
        string name;
        address citizenAddress;
        address vote;
        bool didVote;
    }
    
    struct Candidate {
        string name;
        address candidateAddress;
        uint votes;
    }

    constructor () {
        owner = msg.sender;
    }

    modifier onlyOwner() {
        if(owner == msg.sender) {
            _;
        } else {
            revert();
        }
    }

    modifier onlyCitizen() {
        bool isCitizen = false;
        for(uint i = 0; i < voters.length; i++) {
            if(msg.sender == voters[i].citizenAddress) {
                isCitizen = true;
            }
        }
        if(isCitizen == true) {
            _;
        } else {
            revert();
        }
    }
    
    
    function Vote(address _candidateAddress) onlyCitizen {
        uint amountOfVotes = 0;
        for(uint i = 0; i < voters.length; i++) {
            if(voters[i].citizenAddress == msg.sender && voters[i].didVote == false) {
                voters[i].vote = _candidateAddress;
                voters[i].didVote = true;
                amountOfVotes += 1;
                for(uint j = 0; j < candidates.length; j++) {
                    if(candidates[j].candidateAddress == _candidateAddress) {
                        candidates[j].votes += 1;
                    }
                }
            } else {
                if(voters[i].didVote) {
                    amountOfVotes += 1;
                }
            }
        }
        if(amountOfVotes == voters.length) {
            electionEnded();
        }
    }
    
    function electionEnded() onlyOwner {
        for(uint i = 0; i < candidates.length; i++) {
            if(candidates[i].votes > winnerVotes) {
                electionWinnerAddress = candidates[i].candidateAddress;
                winnerVotes = candidates[i].votes;
                electionWinner = candidates[i].name;
            }
        }
    }
    
    function addCandidate(address _address, string _name) onlyCitizen {
        candidates.push(Candidate({
				name: _name,
				candidateAddress: _address,
				votes: 0
			}));
    }
    
    function addCitizen(address _citizenAddress, string _name) onlyOwner {
        voters.push(Citizen({
				name: _name,
				citizenAddress: _citizenAddress,
				vote: msg.sender,
				didVote: false
			}));
    }
    
    
    
}