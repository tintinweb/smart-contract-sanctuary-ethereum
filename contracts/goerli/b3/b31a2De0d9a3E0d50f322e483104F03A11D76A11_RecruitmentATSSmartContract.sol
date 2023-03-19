pragma solidity ^0.8.0;

contract RecruitmentATSSmartContract {

    // Struct to represent an applicant
struct Applicant {
    string name;
    uint age;
    string resumeHash;
    address applicantAddress;
}

// Struct to represent a job
struct Job {
    string title;
    uint salary;
    string description;
    address employerAddress;
    string jobUrlId;
}

// Struct to represent a job application
struct Application {
    address applicantAddress;
    address employerAddress;
    uint jobId;
    bool accepted;
    bool rejected;
}

// Struct to represent an employer
struct Employer {
    string name;
    address ethAddress;
}

event NewApplicantAdded(address indexed applicantAddress, string name, uint age, string resumeHash);
event NewJobAdded(uint indexed jobId, string title, uint salary, string description, address indexed employerAddress, string indexed jobUrlId);
event NewJobApplication(address indexed applicantAddress, uint indexed jobId);
event JobApplicationAccepted(address indexed employerAddress, address indexed applicantAddress, uint indexed jobId);
event JobApplicationRejected(address indexed employerAddress, address indexed applicantAddress, uint indexed jobId);

// Mapping to store the list of applicants
mapping(address => Applicant) public applicants;

// Mapping to store the list of jobs
mapping(uint => Job) public jobs;

// Mapping to store the list of applications
mapping(uint => mapping(address => Application)) public applications;

// Mapping to store the list of employers
mapping(address => Employer) public employers;

// Modifier to restrict access to employer-only functions
modifier onlyEmployer() {
    require(employers[msg.sender].ethAddress != address(0), "Only employers can call this function.");
    _;
}

// Modifier to restrict access to applicant-only functions
modifier onlyApplicant() {
    require(applicants[msg.sender].age > 0, "Only applicants can call this function.");
    _;
}

// Function to add an employer
function addEmployer(string memory name, address ethAddress) public {
    // Ensure the employer does not already exist
    require(employers[ethAddress].ethAddress == address(0), "Employer already exists.");

    // Add the employer
    employers[ethAddress] = Employer(name, ethAddress);
}

// Function to add an applicant
function addApplicant(string memory name, uint age, string memory resumeHash) public {
    // Ensure the applicant does not already exist
    require(applicants[msg.sender].age == 0, "Applicant already exists.");

    // Add the applicant
    applicants[msg.sender] = Applicant(name, age, resumeHash, msg.sender);

    // Emit a NewApplicantAdded event
    emit NewApplicantAdded(msg.sender, name, age, resumeHash);
}

// Function to add a job
function postJob(string memory title, uint salary, string memory description, string memory jobUrlId) public onlyEmployer {
    // Ensure the employer exists
    require(employers[msg.sender].ethAddress != address(0), "Employer does not exist.");

    // Generate a new job ID
    uint jobId = uint(keccak256(abi.encodePacked(block.timestamp, msg.sender)));

    // Add the job
    jobs[jobId] = Job(title, salary, description, msg.sender, jobUrlId);

    // Emit a NewJobAdded event
    emit NewJobAdded(jobId, title, salary, description, msg.sender, jobUrlId);
}


// Function to apply for a job
function applyJob(uint jobId) public onlyApplicant {
    // Ensure the job exists
    require(jobs[jobId].salary > 0, "Job does not exist.");

    // Ensure the applicant has not already applied for this job
    require(applications[jobId][msg.sender].applicantAddress != msg.sender, "You have already applied for this job.");
    // Add the application
    applications[jobId][msg.sender] = Application(msg.sender, jobs[jobId].employerAddress, jobId, false, false);

    // Emit a NewJobApplication event
    emit NewJobApplication(msg.sender, jobId);
}

// Function to accept an application
function acceptApplication(uint jobId, address applicantAddress) public onlyEmployer {
    // Ensure the job exists
    require(jobs[jobId].salary > 0, "Job does not exist.");

    // Ensure the application exists
    require(applications[jobId][applicantAddress].applicantAddress == applicantAddress, "Application does not exist.");

    // Ensure the application has not already been accepted or rejected
    require(!applications[jobId][applicantAddress].accepted && !applications[jobId][applicantAddress].rejected, "Application has already been accepted or rejected.");

    // Set the application as accepted
    applications[jobId][applicantAddress].accepted = true;

    // Emit a JobApplicationAccepted event
    emit JobApplicationAccepted(jobs[jobId].employerAddress, applicantAddress, jobId);
}

// Function to reject an application
function rejectApplication(uint jobId, address applicantAddress) public onlyEmployer {
    // Ensure the job exists
    require(jobs[jobId].salary > 0, "Job does not exist.");

    // Ensure the application exists
    require(applications[jobId][applicantAddress].applicantAddress == applicantAddress, "Application does not exist.");

    // Ensure the application has not already been accepted or rejected
    require(!applications[jobId][applicantAddress].accepted && !applications[jobId][applicantAddress].rejected, "Application has already been accepted or rejected.");

    // Set the application as rejected
    applications[jobId][applicantAddress].rejected = true;

    // Ensure the application was successfully rejected
    assert(applications[jobId][applicantAddress].rejected == true);

    // Emit a JobApplicationRejected event
    emit JobApplicationRejected(jobs[jobId].employerAddress, applicantAddress, jobId);
}

// Function to get job details by ID
function getJobDetails(uint jobId) public view returns (string memory, uint, string memory, address) {
    // Ensure the job exists
    require(jobs[jobId].salary > 0, "Job does not exist.");

    // Return the job details
    return (jobs[jobId].title, jobs[jobId].salary, jobs[jobId].description, jobs[jobId].employerAddress);
}

// Function to get applicant details by address
function getApplicantDetails(address applicantAddress) public view returns (string memory, uint, string memory, address) {
    // Ensure the applicant exists
    require(applicants[applicantAddress].age > 0, "Applicant does not exist.");

    // Return the applicant details
    return (applicants[applicantAddress].name, applicants[applicantAddress].age, applicants[applicantAddress].resumeHash, applicants[applicantAddress].applicantAddress);
}

// Function to get employer details by address
function getEmployerDetails(address employerAddress) public view returns (string memory, address) {
    // Ensure the employer exists
    require(employers[employerAddress].ethAddress != address(0), "Employer does not exist.");

    // Return the employer details
    return (employers[employerAddress].name, employers[employerAddress].ethAddress);
}

// Function to get application details by job ID and applicant address
function getApplicationDetails(uint jobId, address applicantAddress) public view returns (bool accepted, bool rejected) {
// Ensure the application exists
require(applications[jobId][applicantAddress].applicantAddress == applicantAddress, "Application does not exist.");
    // Return the application details
    return (applications[jobId][applicantAddress].accepted, applications[jobId][applicantAddress].rejected);
}


// Function to get all jobs posted by an employer
function getAllJobsByEmployerAddress(address employerAddress) public view returns (Job[] memory) {
    // Initialize an empty array of jobs
    Job[] memory jobList = new Job[](100);
    uint jobCount = 0;

    // Iterate through all jobs and add to the list if posted by the employer
    for (uint i = 0; i < 100; i++) {
        if (jobs[i].salary > 0 && jobs[i].employerAddress == employerAddress) {
            jobList[jobCount] = jobs[i];
            jobCount++;
        }
    }

    // Resize the job list to the number of jobs posted by the employer
    assembly { mstore(jobList, jobCount) }

    return jobList;
}

    // Function to get all jobs applied by an applicant
    function getAllJobsByApplicantAddress(address applicantAddress) public view returns (Job[] memory) {
        // Initialize an empty array of jobs
        Job[] memory jobList = new Job[](100);
        uint jobCount = 0;

        // Iterate through all jobs and add to the list if applied by the applicant
        for (uint i = 0; i < 100; i++) {
            if (jobs[i].salary > 0 && applications[i][applicantAddress].applicantAddress == applicantAddress) {
                jobList[jobCount] = jobs[i];
                jobCount++;
            }
        }

        // Resize the job list to the number of jobs applied by the applicant
        assembly { mstore(jobList, jobCount) }

        return jobList;
    }

    // Function to get a job by its jobUrlId
    function getJobByJobUrl(string memory jobUrlId) public view returns (string memory, uint, string memory, address) {
        // Iterate through all jobs and return the one with a matching jobUrlId
        for (uint i = 0; i < 100; i++) {
            if (jobs[i].salary > 0 && keccak256(bytes(jobs[i].jobUrlId)) == keccak256(bytes(jobUrlId))) {
                return (jobs[i].title, jobs[i].salary, jobs[i].description, jobs[i].employerAddress);
            }
        }

        // If no job with the given jobUrlId is found, revert with an error message
        revert("No job found with the given jobUrlId.");
    }

}