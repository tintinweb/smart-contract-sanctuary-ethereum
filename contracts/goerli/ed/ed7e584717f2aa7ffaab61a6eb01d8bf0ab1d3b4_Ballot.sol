/**
 *Submitted for verification at Etherscan.io on 2022-11-02
*/

pragma solidity >= 0.7.0<0.9.0;

//start the contract with the contract type

contract Ballot {


    // this would be the proposal for voting that the people can create

    struct Proposal {

        string name; //name of each proposal
        uint voteCount; //number of accumulated votes

    }

    Proposal[] public proposals;

    uint256 public votePerAddressLimit = 1;

    bool public onlyAllowedVoters = true;

    address[] public allowedVotersAddresses;

    address[] public votersWhoAlreadyVoteAddresses;

    address public chairPerson; //address of the one deploying the contract

    //memory allows proposalName to be defined as a temporary data in Solidity during runtime only

    constructor(){

        chairPerson = msg.sender;

        //will add the propasl names to the smart contract ones it is deployed
        
        proposals.push(Proposal({
                name: "petro",
                voteCount: 0
            }));

        proposals.push(Proposal({
                name: "rodolfo",
                voteCount: 0
            }));

    }


    //function for voting

    function vote(uint proposal) external{

        require(isAllowedToVote(msg.sender),   "user is not allowed to vote");

        require(!alreadyVote(msg.sender),   "user already vote");

        proposals[proposal].voteCount = proposals[proposal].voteCount++;
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

    function petroVotes() public view returns (uint cant) {

        cant = proposals[0].voteCount;

    }

    function rodolfoVotes() public view returns (uint cant) {

        cant = proposals[1].voteCount;

    }

    function whitelistUsers(address[] calldata _users)public 
    {
        require(msg.sender == chairPerson);
        delete allowedVotersAddresses;
        allowedVotersAddresses = _users;
    }

    function isAllowedToVote(address _user) public view returns (bool){

        for(uint256 i = 0; i<allowedVotersAddresses.length; i++){
            if(allowedVotersAddresses[i] == _user){
                return true;
            }
        }

        return false;

    }

    function alreadyVote(address _user) public view returns (bool){

        for(uint256 i = 0; i<votersWhoAlreadyVoteAddresses.length; i++){
            if(votersWhoAlreadyVoteAddresses[i] == _user){
                return true;
            }
        }

        return false;

    }
}
/**
["348976394860239572jfdka", "348976394860239572jfdka","348976394860239572jfdka"]
**/