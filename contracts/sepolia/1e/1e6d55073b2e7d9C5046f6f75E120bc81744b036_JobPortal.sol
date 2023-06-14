/**
 *Submitted for verification at Etherscan.io on 2023-06-14
*/

// SPDX-License-Identifier: GPL-3.0

pragma solidity >=0.8.2 <0.9.0;

contract JobPortal {

    address admin;
    uint count;
    uint JobCount;

    struct Applicant{
        uint applicantId;
        string name;
        string currentLocation;
        string applicationType;
        string highestQualification;
        uint currentSalary;
        uint expectedSalary;
        bool isReg;
        bool hasapplied;
        uint applied_to;
       // uint appliedJobId;
        bool selected;
        uint JobIdSelected;
        uint rating;
    
    }

    struct Ids{
        address applicantAddr;
        uint applicantId;

    }

    struct JobDescription{
        uint jobId;
        string nameOfCompany;
        string JobRole;
        string JobType;
        string requiredQualification;
        uint experienceRequired;
        bool isVaccant;
    }


    mapping (uint => Applicant) public applicants;
    mapping (address => Ids ) public applicantIds;
    mapping (uint => JobDescription ) public jds;

    event applicantAdded( address _applicantAddr, uint _applicantId);
    event JobAdded ( uint _jobId);
    event AppliedforJob( uint _applicantId, uint _jobId);
    event Jobgranted( address _applicantAddr, uint _applicantid, uint jobId) ;
    event RatedApplicant( uint _applicantId, uint _Rate);

    constructor() {
        admin = msg.sender;

    }
    
// 1Add a new applicant  
//Admin uses this function to add a new applicant. 
    function addApplicant(string memory _name, string memory _currentLocation, string memory _highestQualification, string memory _applicationType, uint _currentSalary,uint _expectedSalary, address _applicantAddr ) public onlyAdmin {
        require(applicants[applicantIds[_applicantAddr].applicantId].isReg == false , "already registered");
        count++;
        //Applicant memory applicant = applicants[count];
        applicants[count].name = _name;
        applicants[count].applicantId = count;
        applicants[count].currentLocation = _currentLocation;
        applicants[count].currentSalary = _currentSalary;
        applicants[count].highestQualification = _highestQualification;
        applicants[count].expectedSalary = _expectedSalary;
        applicants[count].applicationType = _applicationType;
        applicants[count].isReg = true;
        applicantIds[_applicantAddr].applicantAddr = _applicantAddr;
        applicantIds[_applicantAddr].applicantId = count;
 
        emit applicantAdded( _applicantAddr,  count); 
    
    }

//2 Get applicant details 
// This function helps to fetch the applicant details from the blockchain.  
    function viewApplicantDetails(uint _appId) public view returns(uint , string memory, string memory, string memory,string memory){
        Applicant memory applicant = applicants[_appId];
        return(applicant.applicantId,applicant.name,applicant.applicationType,applicant.currentLocation,applicant.highestQualification);
    }

//3 Get applicant type 
// This function helps to fetch the application type based on the application id from the blockchain. 
function getApplicantType(uint _appId) public view returns(string memory){
    Applicant memory applicant = applicants[_appId];
    return(applicant.applicationType);

}

//4 Add a new Job to the portal 
// This function helps to add a new job to the portal.

function addNewJob(string memory _JobRole, string memory _nameOfCompany, string memory _JobType,string memory _requiredQualification, uint _experienceRequired ) public {
    
    JobCount++;
    jds[JobCount].jobId = JobCount;
    jds[JobCount].nameOfCompany = _nameOfCompany;
    jds[JobCount].JobRole = _JobRole;
    jds[JobCount].JobType = _JobType;
    jds[JobCount].requiredQualification = _requiredQualification;
    jds[JobCount].experienceRequired = _experienceRequired;
    jds[JobCount].isVaccant = true;

      emit JobAdded ( JobCount);

}

//5 Get job details 
//This function fetches job data from the blockchain. 
function getJobDetails(uint _jId) public view returns(
       uint,
        string memory,
        string memory,
       string memory,
       string memory,
        uint
        ){
    JobDescription memory jd = jds[_jId];
    return( jd.jobId, jd.nameOfCompany, jd.JobRole, jd.JobType, jd.requiredQualification, jd.experienceRequired );
     

    
}

//6 Applicants apply for a job 
// With the help of this function, applications can apply for existing jobs. 
function applyforJob(uint _jobId) public {

        JobDescription memory jd = jds[_jobId];
        Ids memory ids = applicantIds[msg.sender];
    //Applicant memory userProfile = applicants[ids.applicantId];
         applicants[ids.applicantId].hasapplied = true;
        applicants[ids.applicantId].applied_to =  jd.jobId;
        emit AppliedforJob( ids.applicantId,   _jobId);
}



function grantJob(address _applicantAddr,uint _jobId) public onlyAdmin {
    Ids memory idss = applicantIds[_applicantAddr];
    applicants[idss.applicantId].selected = true;
    applicants[idss.applicantId].JobIdSelected = _jobId;
    emit Jobgranted( _applicantAddr, idss.applicantId, _jobId);

}

//7 Provide a rating to an applicant 
// This function provides the rating to the applicant. 
function ratingApplicant(address _applicantAddr, uint _rating) public onlyAdmin{
    Ids memory ids = applicantIds[_applicantAddr];
    applicants[ids.applicantId].rating = _rating;
    emit RatedApplicant( ids.applicantId,  _rating);
 
}

//8 Fetch applicant rating 
// This function fetches applicant ratings from the blockchain. 
function fetchRatingOfApplicant(address _applicantAddr) public view returns(uint){
    Ids memory ids = applicantIds[_applicantAddr];
    Applicant memory user = applicants[ids.applicantId];
    return(user.rating);
}


 //Modifier OnlyAdmin
    modifier onlyAdmin {
        require(admin== msg.sender, "Only Admin can add new Applicants");
        _;
    }

}