/**
 *Submitted for verification at Etherscan.io on 2022-09-21
*/

pragma solidity >= 0.7.0<0.9.0;

//start the contract with the contract type

contract Ballot {


    // this would be the proposal for voting that the people can create

    struct Proposal {

        string name; //name of each proposal
        uint voteCount; //number of accumulated votes

    }

    struct Voter{

        bool voted;
        uint vote;
        uint weight;

    } 

    Proposal[] public proposals;

    //mapping allow us to create a store value with keys and indexes

    mapping(address => Voter) public voters; //voters get address as a key and voter for value

    address public chairPerson; //address of the one deploying the contract

    //memory allows proposalName to be defined as a temporary data in Solidity during runtime only

    constructor(){

        chairPerson = msg.sender;

        //add 1 to the weight of chairperson
        voters[chairPerson].weight = 1;

        //will add the propasl names to the smart contract ones it is deployed

        
        proposals.push(Proposal({
                name: "biden",
                voteCount: 0
            }));

        proposals.push(Proposal({
                name: "trump",
                voteCount: 0
            }));

    }


    //function for voting

    function vote(uint proposal) external{

        Voter storage sender = voters[msg.sender];

        require(sender.weight != 0,'has no right to vote');

        require(!sender.voted ,'You Have Already voted');

        sender.voted = true;

        sender.vote = proposal;

        proposals[proposal].voteCount = proposals[proposal].voteCount + sender.weight;
    }

    //function for authenticate voter

    function giveRightToVote(address voter) external {

        require(msg.sender == chairPerson,
            'Only the chair person can give access to vote');

        //we require that the person hasnt vote yet
        require(!voters[voter].voted,
                'This person has already voted');

        require(voters[voter].weight==0,
                'This person has already voted');
        
        voters[voter].weight =1;

    }

    //functions for show results

    //function that shows the winning proposal by integer

    function winningProposal() public view returns (uint winningProposal_) {

        uint winningVoteCount = 0;

        for(uint i = 0 ; i < proposals.length ; i++){

            if(proposals[i].voteCount > winningVoteCount ){

                winningVoteCount = proposals[i].voteCount;

                winningProposal_ = i;

            }

        }

    }

    //function that shows the winning proposal by name

    function winningName() public view returns (string memory) {

        return proposals[winningProposal()].name;

    }


    //functions to get the total of votes of each candidate

    function bidenVotes() public view returns (uint cant) {

        cant = proposals[0].voteCount;

    }

    function trumpVotes() public view returns (uint cant) {

        cant = proposals[1].voteCount;

    }
}