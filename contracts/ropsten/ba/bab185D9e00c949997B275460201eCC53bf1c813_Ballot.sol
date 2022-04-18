pragma solidity >=0.8.0 <0.9.0;

contract Ballot {

    struct proposal{
        string proposalString;
        address creator;
        uint256 forVotes;
        uint256 againstVotes;
        bool hasEnded;
    }
    mapping(uint256 => mapping(address=>bool)) public voted;    
    

    uint256 proposalCount = 0;
    uint256 totalVoters = 0;
    
    mapping(uint256=>proposal) public proposalRegister;
    mapping(address=>uint) public voterRegister;

    address[] votersArr;

    function register() public {
        
        if(voterRegister[msg.sender] == 0){
            votersArr.push(msg.sender);
            voterRegister[msg.sender] = totalVoters;
            totalVoters++;
        }
        
        return ;
    }

    function addProposal(string memory _proposalString) public{
        proposal memory p;
        p.proposalString = _proposalString;
        p.againstVotes = 0;
        p.forVotes = 0;
        p.creator = msg.sender;
        p.hasEnded = false;
        proposalRegister[proposalCount] = p;
        proposalCount++;
    }

    function voting(bool _choice, uint256 _proposalId) public{
        if(_proposalId >= proposalCount){
            return;
        }
        if(proposalRegister[_proposalId].hasEnded){
            return;
        }
        if(voterRegister[msg.sender]==0 || voted[_proposalId][msg.sender]){
            return;
        }
        if(_choice){
            proposalRegister[_proposalId].forVotes++;
        }
        else{
            proposalRegister[_proposalId].againstVotes++;
        }
        voted[_proposalId][msg.sender] = true;
        return;
    }

    function endVoting(uint256 _proposalId) public{
        if(proposalRegister[_proposalId].creator == msg.sender){
            proposalRegister[_proposalId].hasEnded = true;
        }
        return;
    }

    function getVoterCount() public view returns(uint ){
        return totalVoters;
    }

    function getProposalCount() public view returns(uint){
        return proposalCount;
    }

    function getVoterRegister() public view returns(address[] memory)
    {
        return votersArr;
    }

    function getProposalRegister() public view returns(proposal[] memory){
        proposal[] memory ret = new proposal[](proposalCount);
        for (uint i = 0; i < proposalCount; i++) {
            ret[i] = proposalRegister[i];
        }
        return ret;
    }


}