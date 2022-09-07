// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.7;

import "./IFreeJobs.sol";

/*
  ____              _ _     _                  _                      _  __       
 |  _ \  ___  _ __ ( ) |_  | |_ _ __ _   _ ___| |_    __   _____ _ __(_)/ _|_   _ 
 | | | |/ _ \| '_ \|/| __| | __| '__| | | / __| __|   \ \ / / _ \ '__| | |_| | | |
 | |_| | (_) | | | | | |_  | |_| |  | |_| \__ \ |_ _   \ V /  __/ |  | |  _| |_| |
 |____/ \___/|_| |_|  \__|  \__|_|   \__,_|___/\__( )   \_/ \___|_|  |_|_|  \__, |
                                                  |/                        |___/ 
*/

contract FreeJobs is IFreeJobs {

    mapping(address => uint) public stakes;
    mapping(address => uint) public stakesCommitted;
    mapping(uint => Job) public jobs;
    mapping(uint => bool) public jobIds;
    uint public lastJobId;

    constructor() {
        lastJobId = 0;
    }

    function stake() public override payable {
        stakes[msg.sender] += msg.value;
    }

    function unstake(uint amount) public override checkStake checkStakeCommitted(amount) {
        stakes[msg.sender] -= amount;
        payable(msg.sender).transfer(amount);
    }

    function createJob(string memory title, string memory descripcion, string memory deliveryDetails, uint salary, uint oracleStakeMinimum, uint oracleSalary) public override checkStake checkStakeCommitted(salary + oracleSalary) returns(uint) {
        Job memory job = Job(++lastJobId, title, descripcion, deliveryDetails, JobStatus.AVAILABLE, OracleVerdict.NOT_VALUED, salary, oracleStakeMinimum, oracleSalary, msg.sender, address(0), address(0));
        jobs[lastJobId] = job;
        jobIds[lastJobId] = true;
        stakesCommitted[msg.sender] += job.salary + job.oracleSalary;
        emit CreateJob(job);
        return lastJobId;
    }

    function deleteJob(uint id) public override checkStake checkJob(id) checkEmployer(id) checkJobAvailableStatus(id) {
        require(jobs[id].employee == address(0), "The job already has an employee");
        require(jobs[id].oracle == address(0), "The job already has an oracle");
        jobs[id].status = JobStatus.FINALIZED;
        emit DeleteJob(id);
    }

    function joinJobLikeEmployee(uint id) public override checkStake checkJob(id) checkJobAvailableStatus(id) checkStakeCommitted(jobs[id].oracleSalary)  {
        require(jobs[id].employee == address(0), "The job already has an employee");
        jobs[id].employee = msg.sender;
        stakesCommitted[msg.sender] += jobs[id].oracleSalary;
        if (jobs[id].oracle != address(0)) jobs[id].status = JobStatus.IN_PROGRESS;
        emit JoinJobLikeEmployee(id, msg.sender);
    }
// TODO No se puede ser dos roles en el mismo trabajo
// TODO getStake y gestStakeCommited
// TODO notify cambios en estados
    function joinJobLikeOracle(uint id) public override checkStake checkJob(id) checkJobAvailableStatus(id) checkStakeCommitted(jobs[id].oracleStakeMinimum) {
        require(jobs[id].oracle == address(0), "The job already has an oracle");
        jobs[id].oracle = msg.sender;
        stakesCommitted[msg.sender] += jobs[id].oracleStakeMinimum;
        if (jobs[id].employee != address(0)) jobs[id].status = JobStatus.IN_PROGRESS;
        emit JoinJobLikeOracle(id, msg.sender);
    }

    function notifyEndOfWork(uint id) public override checkStake checkJob(id) checkEmployee(id) checkJobInProgressStatus(id) {
        jobs[id].status = JobStatus.IN_REVIEW;
        emit EndOfWork(id);
    }

    function notifyEndOfReview(uint id, OracleVerdict verdict) public override checkStake checkJob(id) checkOracle(id) checkJobInReviewStatus(id) {
        require(verdict != OracleVerdict.NOT_VALUED, "Invalid verdict");
        jobs[id].status = JobStatus.FINALIZED;
        jobs[id].verdict = verdict;

        address employer = jobs[id].employer;
        address employee = jobs[id].employee;
        address oracle = jobs[id].oracle;
        uint salary = jobs[id].salary;
        uint oracleSalary = jobs[id].oracleSalary;

        stakesCommitted[employer] -= salary + oracleSalary;
        stakesCommitted[employee] -= oracleSalary;
        stakesCommitted[oracle] -= jobs[id].oracleStakeMinimum;

        if (verdict == OracleVerdict.REFUSED) {
            stakes[employee] -= oracleSalary;
        } else if (verdict == OracleVerdict.ACCEPTED) {
            stakes[employer] -= salary + oracleSalary;
            stakes[employee] += salary;
        }
        stakes[msg.sender] += jobs[id].oracleSalary;

        emit EndOfReview(id, verdict);
    }

    modifier checkStake() {
        require(stakes[msg.sender] > 0, "Stake amount is 0");
        _;
    }

    modifier checkStakeCommitted(uint quantity) {
        require(stakes[msg.sender] - stakesCommitted[msg.sender] >= quantity, "Invalid amount to unstake");
        _;
    }

    modifier checkJob(uint id) {
        require(jobIds[id], "Invalid job id");
        _;
    }

    modifier checkEmployer(uint id) {
        require(jobs[id].employer == msg.sender, "Unauthorized");
        _;
    }

    modifier checkEmployee(uint id) {
        require(jobs[id].employee == msg.sender, "Unauthorized");
        _;
    }

    modifier checkOracle(uint id) {
        require(jobs[id].oracle == msg.sender, "Unauthorized");
        _;
    }

    modifier checkJobAvailableStatus(uint id) {
        require(jobs[id].status == JobStatus.AVAILABLE, "Job is not available");
        _;
    }

    modifier checkJobInProgressStatus(uint id) {
        require(jobs[id].status == JobStatus.IN_PROGRESS, "Job is not in progress");
        _;
    }

    modifier checkJobInReviewStatus(uint id) {
        require(jobs[id].status == JobStatus.IN_REVIEW, "Job is not in review");
        _;
    }
}