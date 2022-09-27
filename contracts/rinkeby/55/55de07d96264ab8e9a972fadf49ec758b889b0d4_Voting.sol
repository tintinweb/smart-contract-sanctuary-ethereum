/**
 *Submitted for verification at Etherscan.io on 2022-09-27
*/

// SPDX-License-Identifier: UNLICENSED
pragma solidity >=0.7.0 < 0.9.0;

contract Voting{
    address public owner ;
    struct ElectionDetails{
        string electionName;
        uint256 startDate;
        uint256 timeStamp;
        uint256 endDate;
        string electionDescription;
        CandidateDetails candidateDetails;
    }
    string [] public candidates;
    string [] public elections;
    struct CandidateDetails{
        string candidateName;
        string candidateDesc;
        //uint votes;
        //uint voted;
        //uint authorized;
    }
    // add election id 
    // use cassandra db
    // decentralized password service


    modifier OwnerOnly(){
        require(msg.sender == owner);
        _;
    }

    mapping (string=>ElectionDetails) public eDetails;
    mapping (string=>CandidateDetails) public cDetails;
    //mapping(string => bool) userExists;

    function setElectionDetails(string memory ename,uint256 sdate,uint256 ts,uint256 edate,string memory cname,string memory cdesc) public {
        eDetails[ename].electionName=ename;
        eDetails[ename].startDate=sdate;
        eDetails[ename].timeStamp=ts;
        eDetails[ename].endDate=edate;
        cDetails[cname].candidateName=cname;
        cDetails[cname].candidateDesc=cdesc;
        candidates.push(cname);
        elections.push(ename);
    }

    function getCandidateDetails(string memory cname) public view returns(string memory,string memory){
        return(cDetails[cname].candidateName,cDetails[cname].candidateDesc);
    }

    
    //function authorizeVoter() public {}

    //function Vote(string memory cname) public {} 
    
}