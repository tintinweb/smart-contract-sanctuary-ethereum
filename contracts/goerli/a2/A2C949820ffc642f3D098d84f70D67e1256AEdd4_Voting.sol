// SPDX-License-Identifier: MIT
    pragma solidity^0.8.0;

   import "./myDao.sol";

contract Voting is Mydao {

    struct Candidate {
        address candidateAddress;
        uint votes;
    }

    Candidate candidate;
    mapping(uint=>Candidate) candidates;
    mapping(address=>bool) memberData;
    uint voteCount;

    

    function addCandidates() internal {

        for(uint i=0;i<memberCount;i++){
            
            candidates[i]=Candidate({
                candidateAddress : memberDetails[i].memberAddress,
                votes : 0
            });
            memberData[memberDetails[i].memberAddress]=true;
        }

    }
    

    function voteAdmin(uint _id) public verifyMember {
        require(newAdmin,"No session exist");
        if(_id>=memberCount){
        revert("Invalid Id");
        }
        if(voteCount==0){
            addCandidates();
        }
        
        require(memberData[msg.sender]==true,"Already voted !");
        candidates[_id].votes+=1;
        memberData[msg.sender]=false;
        voteCount++;
    }

    function resultAdmin() public returns(address,uint){
        require(newAdmin,"No session exist");
        require(block.number-submittedProposals[submittedProposals.length-1].blockNumber>5,"Time still remaining");
        uint temp;
        uint winner;
         for(uint i=0;i<memberCount;i++) {

             if(temp<candidates[i].votes){

                 winner = i;
             }
             
         }
        _owner=candidates[winner].candidateAddress;
        admin = candidates[winner].candidateAddress;
         return (memberDetails[winner].memberAddress,candidates[winner].votes);

    }

    function viewCandidates(uint _id) public view returns(address){
        require(newAdmin,"No voting session exist");
        return candidates[_id].candidateAddress;
    }
}