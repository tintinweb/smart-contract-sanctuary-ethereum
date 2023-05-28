/**
 *Submitted for verification at Etherscan.io on 2023-05-28
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

contract JobContracts {
    struct Job {
        address employer;
        address employee;
        uint256 deposit;
        bool signed;
        bool employerAgree;
        bool employeeAgree;
        bool employerDisagree;
        bool employeeDisagree;
        bool completed;
        bool abandoned;
    }


    mapping(string => Job) public jobs;

    function createJob(string memory cid) public payable returns(string memory) {
        Job storage job = jobs[cid];
        job.employer = msg.sender;
        job.employee = 0x9f098c9B129bc195e10605Ef03a8141bFdEf8D74;
        job.deposit = msg.value;
        return cid;
    }

    function signJob(string memory cid) public {
        Job storage job = jobs[cid];
        require(msg.sender == job.employee, "Only the employee can sign the job");
        require(!job.signed, "Job already signed");
        job.signed = true;
    }

    function depositFunds(string memory cid) public payable {
        Job storage job = jobs[cid];
        require(!job.completed && !job.abandoned, "This job doesn't exist");
        job.deposit += msg.value;
    }

    function completeJob(string memory cid) public {
        Job storage job = jobs[cid];
        require(msg.sender == job.employer || msg.sender == job.employee, "Only the employer can complete the job");
        require(job.signed, "Job must be signed before it can be completed");
        if (msg.sender == job.employer){
            job.employerAgree = true;

        } else {
            job.employeeAgree = true;
        }
        if(job.employerAgree && job.employeeAgree){
        job.completed = true;
        job.employerAgree = true;
        payable(job.employee).transfer(job.deposit);
        job.deposit = 0;
        }
    }

    function abandonJob(string memory cid) public {
        Job storage job = jobs[cid];
        require(msg.sender == job.employer || msg.sender == job.employee, "Only the employer can complete the job");
        require(job.signed, "Job must be signed before it can be completed");
        if (msg.sender == job.employer){
            job.employerDisagree = true;
        } else {
            job.employeeDisagree = true;
        }
        if(job.employerDisagree && job.employeeDisagree){
        job.abandoned = true;
        payable(job.employer).transfer(job.deposit);
        job.deposit = 0;
        }
    }
}