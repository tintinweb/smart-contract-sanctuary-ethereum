/**
 *Submitted for verification at Etherscan.io on 2023-01-09
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

enum Status {
    None,
    Vouching,
    PendingRegistration,
    PendingRemoval
}

struct Submission {
    Status status;
    bool registered;
    uint64 submissionTime;
}

contract TestPOH {
    event SubmissionUpdated(
        address indexed submissionID,
        Status status,
        bool registered,
        uint64 submissionTime);

    mapping (address => Submission) submissions;
    address[] public submissionsList;

    uint64 public submissionDuration;

    constructor(uint64 _submissionDuration) {
        submissionDuration = _submissionDuration;
    }

    function updateSubmission(
        address _submissionID,
        Status _status,
        bool _registered,
        uint64 _submissionTime) external {
        require(_submissionTime > 0, "Submission time must be greater than 0");
        if (submissions[_submissionID].submissionTime == 0) {
            submissionsList.push(_submissionID);
        }
        submissions[_submissionID] = Submission( _status, _registered, _submissionTime);
        emit SubmissionUpdated(_submissionID, _status, _registered, _submissionTime);
    }

    function numSubmissions() external view returns (uint) {
        return submissionsList.length;
    }

    function getSubmissionInfo(address _submissionID)
        external
        view
        returns (
            Status status,
            uint64 submissionTime,
            uint64 index,
            bool registered,
            bool hasVouched,
            uint numberOfRequests
        )
    {
        Submission storage submission = submissions[_submissionID];
        return (
            submission.status,
            submission.submissionTime,
            0,
            submission.registered,
            false,
            0
        );
    }
}