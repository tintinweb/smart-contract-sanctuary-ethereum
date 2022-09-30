/**
 *Submitted for verification at Etherscan.io on 2022-09-30
*/

// SPDX-License-Identifier: UNLICENSED
pragma solidity >=0.7.0 < 0.9.0;

contract MultipleElections{
    address public owner ;
    struct ElectionDetails{
        string electionId;
        string electionName;
        // uint256 startDate;
        // uint256 timeStamp;
        // uint256 endDate;
        // string electionDescription;
        string[] members;
        CandidateDetails candidateDetails;
    }
    struct CandidateDetails{
        uint candidateId;
        string candidateName;
        string candidateDesc;
    }
    
    modifier OwnerOnly(){
        require(msg.sender == owner);
        _;
    }
    mapping (string=>ElectionDetails) public eDetails;
    mapping (uint=>CandidateDetails) cDetails;
    //uint256 public candidateCount;


    function addElectionDetails(string memory _electionName,string memory _electionId,uint[] memory _candidateId,string[] memory _candidateName) public {
      

        eDetails[_electionName].electionName=_electionName;
        eDetails[_electionName].electionId=_electionId;

        // eDetails[_electionName].startDate=_startDate;
        // eDetails[_electionName].timeStamp=_timeStamp;
        // eDetails[_electionName].endDate=_endDate;
        // eDetails[_electionName].electionDescription=_electionDescription;
        for(uint i=0;i<_candidateId.length;i++){
            cDetails[_candidateId[i]].candidateId=(_candidateId[i]);
            cDetails[_candidateId[i]].candidateName=(_candidateName[i]);
            // cDetails[_candidateId[i]].candidateDesc=(_candidateDesc[i]);
            //memberCount++;
            // eDetails[_electionName].members++;
        }
        
    }
 
    function get(string memory _name) public view returns(ElectionDetails memory){
        return eDetails[_name];
    }

    function getMember(string memory elecname) public view returns (string[] memory){
      string[] memory name = eDetails[elecname].members;
      return (name);
  }
    
    //election ids add
    //vote function
    //get function to show candidate details 
    
}