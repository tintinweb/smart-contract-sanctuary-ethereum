/**
 *Submitted for verification at Etherscan.io on 2023-05-31
*/

// SPDX-License-Identifier: UNLICENSED

pragma solidity ^0.8.0;

contract Fiverr {

    struct Job {
        address payable seller;
        address payable buyer;
        uint256 price;
        uint256 deliveryTime;
        uint256 revisions;
        uint256 submittedRevisions;
        bool jobAccepted;
        bool jobStarted;
        bool jobCompleted;
        uint256 reportCount;
    }

    struct Report {
        address reporter;
        uint256 voteCount;
        mapping(address => bool) votes;
    }

    address[] public mods;
    Job[] public jobs;
    Report[] public reports;
    mapping(address => uint256[]) public jobsBySeller;

    event JobCreated(uint256 jobId);
    event JobAccepted(uint256 jobId);
    event JobCompleted(uint256 jobId);
    event ReportCreated(uint256 reportId);
    event ModAdded(address mod);

    constructor() {
        mods.push(0x5B38Da6a701c568545dCfcB03FcB875f56beddC4);
        mods.push(0xAb8483F64d9C6d1EcF9b849Ae677dD3315835cb2);
        mods.push(0x4B20993Bc481177ec7E8f571ceCaE8A9e22C02db);
    }

    function createJob(uint256 _price, uint256 _deliveryTime, uint256 _revisions) public {
        require(_revisions >= 1, "At least one revision is required");
        jobs.push(Job({
            seller: payable(msg.sender),
            buyer: payable(address(0)), // buyer is initially set to the zero address
            price: _price,
            deliveryTime: _deliveryTime,
            revisions: _revisions,
            submittedRevisions: 0,
            jobAccepted: false,
            jobStarted: false,
            jobCompleted: false,
            reportCount: 0
        }));
        jobsBySeller[msg.sender].push(jobs.length - 1);

        emit JobCreated(jobs.length - 1); // emit the event
    }

    function submitRevision(uint256 _jobId) public {
        Job storage job = jobs[_jobId];
        require(msg.sender == job.buyer, "Only buyer can submit a revision");
        require(job.jobStarted, "Job hasn't started yet");
        require(job.submittedRevisions < job.revisions, "No more revisions are allowed");
        job.submittedRevisions += 1;
    }


    function acceptJob(uint256 _jobId) public payable {
        Job storage job = jobs[_jobId];
        require(job.buyer == address(0), "Job has already been accepted");
        require(msg.value == job.price, "You need to pay the exact price of the job");
        job.buyer = payable(msg.sender); // set the buyer to the sender of this transaction
        job.jobAccepted = true;
        job.jobStarted = true;

        emit JobAccepted(_jobId);
    }

    function completeJob(uint256 _jobId) public {
        Job storage job = jobs[_jobId];
        require(msg.sender == job.buyer, "Only the buyer can complete the job");
        require(job.jobAccepted, "Job hasn't been accepted yet");
        job.jobCompleted = true;
        job.seller.transfer(job.price); // transfer the payment to the seller

        emit JobCompleted(_jobId);
    }

function createReport(uint256 _jobId) public {
    Job storage job = jobs[_jobId];
    require(msg.sender == job.seller || msg.sender == job.buyer, "Only involved parties can report");

    reports.push();
    Report storage newReport = reports[reports.length - 1];
    newReport.reporter = msg.sender;
    newReport.voteCount = 0;

    job.reportCount += 1;

    emit ReportCreated(reports.length - 1);
}


function vote(uint256 _reportId, bool isScam) public {
    Report storage report = reports[_reportId];
    bool isMod = false;
    for(uint i = 0; i < mods.length; i++) {
        if(msg.sender == mods[i]) {
            isMod = true;
            break;
        }
    }
    require(isMod, "Only mods can vote");
    require(!report.votes[msg.sender], "Mod has already voted");

    if(isScam) {
        report.voteCount += 1;
    }
    report.votes[msg.sender] = true;

    if(report.voteCount > mods.length / 2) {
        // Majority of mods voted for scam. Refund the reporter.
        address payable reporter = payable(report.reporter);
        reporter.transfer(jobs[_reportId].price);
    }
    }

    function addMod(address _newMod) public {
        bool isMod = false;
        for(uint i = 0; i < mods.length; i++) {
            if(msg.sender == mods[i]) {
                isMod = true;
                break;
            }
        }
        require(isMod, "Only mods can add new mods");

        mods.push(_newMod);

        emit ModAdded(_newMod);
    }
    }