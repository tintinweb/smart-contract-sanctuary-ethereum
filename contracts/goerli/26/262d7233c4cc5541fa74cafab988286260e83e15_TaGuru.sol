/**
 *Submitted for verification at Etherscan.io on 2022-12-22
*/

//SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

contract TaGuru{

    struct CvDetails{
        string name;
        address addresss;
        string email;
        string persStat;
        string keySkills;
        string hobbies;
        string refrences;
    }
    
    struct Employment{
        string position;
        string Company;
        string location;
        uint256 startDate;
        uint256 EndDate;
        string achievResp;
    }

     struct Education{
        string  school;
        uint256 startDate;
        uint256 EndDate;
        string Desc;
    }

    mapping(address => CvDetails) private candidate;
    mapping(address => Employment) private candEmp;
    mapping(address => Education) private candEdu;
    address public admin = 0x5B38Da6a701c568545dCfcB03FcB875f56beddC4;

//Create Cv by filling required details in form of array
    function submitCv(CvDetails memory cv, Employment memory emp, Education memory edu) public returns(bool){
        candidate[msg.sender].name = cv.name ;
        candidate[msg.sender].addresss = msg.sender;
        candidate[msg.sender].email = cv.email;
        candidate[msg.sender].persStat = cv.persStat;
        candidate[msg.sender].keySkills = cv.keySkills;        
        candEmp[msg.sender].position = emp.position;   //Employment Details
        candEmp[msg.sender].Company = emp.Company;
        candEmp[msg.sender].location = emp.location;
        candEmp[msg.sender].startDate= emp.startDate;
        candEmp[msg.sender].EndDate = emp.EndDate;
        candEmp[msg.sender].achievResp = emp.achievResp;
        candEdu[msg.sender].school = edu.school;       //Education Details
        candEdu[msg.sender].startDate = edu.startDate;
        candEdu[msg.sender].EndDate = edu.EndDate;
        candEdu[msg.sender].Desc = edu.Desc;
        candidate[msg.sender].hobbies = cv.hobbies;
        candidate[msg.sender].refrences = cv.refrences;
        return true;
    }

//View All Cv Data of Candidate
    function CandDetails(address _candidate) public view returns(CvDetails memory, Employment memory, Education memory){
        return(candidate[_candidate], candEmp[_candidate], candEdu[_candidate]);
    }

}