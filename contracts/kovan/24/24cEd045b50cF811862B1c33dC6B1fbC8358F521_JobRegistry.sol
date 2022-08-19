// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import {ITalentLayerID} from "./interfaces/ITalentLayerID.sol";

/**
 * @title JobRegistry Contract
 * @author TalentLayer Team @ ETHCC22 Hackathon
 */
contract JobRegistry {
    // =========================== Enum ==============================

    /// @notice Enum job status
    enum Status {
        Intialized,
        Confirmed,
        Finished,
        Rejected
    }

    // =========================== Struct ==============================

    /// @notice Job information struct
    /// @param status the current status of a job
    /// @param employerId the talentLayerId of the employer
    /// @param employeeId the talentLayerId of the employee
    /// @param initiatorId the talentLayerId of the user who initialized the job
    /// @param jobDataUri token Id to IPFS URI mapping
    struct Job {
        Status status;
        uint256 employerId;
        uint256 employeeId;
        uint256 initiatorId;
        string jobDataUri;
    }

    // =========================== Events ==============================

    /// @notice Emitted after a new job is created
    /// @param id The job ID (incremental)
    /// @param employerId the talentLayerId of the employer
    /// @param employeeId the talentLayerId of the employee
    /// @param initiatorId the talentLayerId of the user who initialized the job
    /// @param jobDataUri token Id to IPFS URI mapping
    event JobCreated(
        uint256 id,
        uint256 employerId,
        uint256 employeeId,
        uint256 initiatorId,
        string jobDataUri
    );

    /// @notice Emitted after a job is confirmed
    /// @param id The job ID
    /// @param employerId the talentLayerId of the employer
    /// @param employeeId the talentLayerId of the employee
    /// @param jobDataUri token Id to IPFS URI mapping
    event JobConfirmed(
        uint256 id,
        uint256 employerId,
        uint256 employeeId,
        string jobDataUri
    );

    /// @notice Emitted after a job is rejected
    /// @param id The job ID
    /// @param employerId the talentLayerId of the employer
    /// @param employeeId the talentLayerId of the employee
    /// @param jobDataUri token Id to IPFS URI mapping
    event JobRejected(
        uint256 id,
        uint256 employerId,
        uint256 employeeId,
        string jobDataUri
    );

    /// @notice Emitted after a job is finished
    /// @param id The job ID
    /// @param employerId the talentLayerId of the employer
    /// @param employeeId the talentLayerId of the employee
    /// @param jobDataUri token Id to IPFS URI mapping
    event JobFinished(
        uint256 id,
        uint256 employerId,
        uint256 employeeId,
        string jobDataUri
    );

    /// @notice incremental job Id
    uint256 private nextJobId = 1;

    /// @notice TalentLayerId address
    ITalentLayerID private tlId;

    /// @notice jobs mappings index by ID
    mapping(uint256 => Job) public jobs;

    /**
     * @param _talentLayerIdAddress TalentLayerId address
     */
    constructor(address _talentLayerIdAddress) {
        tlId = ITalentLayerID(_talentLayerIdAddress);
    }

    // =========================== View functions ==============================

    /**
     * @notice Return the whole job data information
     * @param _jobId Job identifier
     */
    function getJob(uint256 _jobId) external view returns (Job memory) {
        require(_jobId < nextJobId, "This job does'nt exist");
        return jobs[_jobId];
    }

    // =========================== User functions ==============================

    /**
     * @notice Allows an employer to initiate a new Job with an employee
     * @param _employeeId Handle for the user
     * @param _jobDataUri token Id to IPFS URI mapping
     */
    function createJobFromEmployer(
        uint256 _employeeId,
        string calldata _jobDataUri
    ) public returns (uint256) {
        uint256 senderId = tlId.walletOfOwner(msg.sender);
        return _createJob(senderId, senderId, _employeeId, _jobDataUri);
    }

    /**
     * @notice Allows an employee to initiate a new Job with an employer
     * @param _employerId Handle for the user
     * @param _jobDataUri token Id to IPFS URI mapping
     */
    function createJobFromEmployee(
        uint256 _employerId,
        string calldata _jobDataUri
    ) public returns (uint256) {
        uint256 senderId = tlId.walletOfOwner(msg.sender);
        return _createJob(senderId, _employerId, senderId, _jobDataUri);
    }

    /**
     * @notice Allows the user who didn't initiate the job to confirm it. They now consent both to be reviewed each other at the end of job.
     * @param _jobId Job identifier
     */
    function confirmJob(uint256 _jobId) public {
        Job storage job = jobs[_jobId];
        uint256 senderId = tlId.walletOfOwner(msg.sender);

        require(
            job.status == Status.Intialized,
            "Job has already been confirmed"
        );
        require(
            senderId == job.employerId || senderId == job.employeeId,
            "You're not an actor of this job"
        );
        require(
            senderId != job.initiatorId,
            "Only the user who didn't initate the job can confirm it"
        );

        job.status = Status.Confirmed;

        emit JobConfirmed(
            _jobId,
            job.employerId,
            job.employeeId,
            job.jobDataUri
        );
    }

    /**
     * @notice Allows the user who didn't initiate the job to reject it
     * @param _jobId Job identifier
     */
    function rejectJob(uint256 _jobId) public {
        Job storage job = jobs[_jobId];
        uint256 senderId = tlId.walletOfOwner(msg.sender);
        require(
            senderId == job.employerId || senderId == job.employeeId,
            "You're not an actor of this job"
        );
        require(job.status == Status.Intialized, "You can't reject this job");
        job.status = Status.Rejected;

        emit JobRejected(
            _jobId,
            job.employerId,
            job.employeeId,
            job.jobDataUri
        );
    }

    /**
     * @notice Allows any part of a job to update his state to finished
     * @param _jobId Job identifier
     */
    function finishJob(uint256 _jobId) public {
        Job storage job = jobs[_jobId];
        uint256 senderId = tlId.walletOfOwner(msg.sender);
        require(
            senderId == job.employerId || senderId == job.employeeId,
            "You're not an actor of this job"
        );
        require(job.status == Status.Confirmed, "You can't finish this job");
        job.status = Status.Finished;

        emit JobFinished(
            _jobId,
            job.employerId,
            job.employeeId,
            job.jobDataUri
        );
    }

    // =========================== Private functions ==============================

    /**
     * @notice Update handle address mapping and emit event after mint.
     * @param _senderId the talentLayerId of the msg.sender address
     * @param _employerId the talentLayerId of the employer
     * @param _employeeId the talentLayerId of the employee
     * @param _jobDataUri token Id to IPFS URI mapping
     */
    function _createJob(
        uint256 _senderId,
        uint256 _employerId,
        uint256 _employeeId,
        string calldata _jobDataUri
    ) private returns (uint256) {
        require(
            _employeeId != _employerId,
            "Employee and employer can't be the same"
        );
        require(_senderId > 0, "You sould have a TalentLayerId");
        require(
            bytes(_jobDataUri).length > 0,
            "Should provide a valid IPFS URI"
        );

        uint256 id = nextJobId;
        nextJobId++;

        jobs[id] = Job({
            status: Status.Intialized,
            employerId: _employerId,
            employeeId: _employeeId,
            initiatorId: _senderId,
            jobDataUri: _jobDataUri
        });

        emit JobCreated(id, _employerId, _employeeId, _senderId, _jobDataUri);

        return id;
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

interface ITalentLayerID {
    function numberMinted(address _user) external view returns (uint256);

    function isTokenPohRegistered(uint256 _tokenId)
        external
        view
        returns (bool);

    function walletOfOwner(address _owner) external view returns (uint256);

    function mint(string memory _handle) external;

    function mintWithPoh(string memory _handle) external;

    function activatePoh(uint256 _tokenId) external;

    function updateProfileData(uint256 _tokenId, string memory _newCid)
        external;

    function recoverAccount(
        address _oldAddress,
        uint256 _tokenId,
        uint256 _index,
        uint256 _recoveryKey,
        string calldata _handle,
        bytes32[] calldata _merkleProof
    ) external;

    function setBaseURI(string memory _newBaseURI) external;

    function updateRecoveryRoot(bytes32 _newRoot) external;

    function _afterMint(string memory _handle) external;

    function ownerOf(uint256 _tokenId) external view returns (address);

    event Mint(address indexed _user, uint256 _tokenId, string _handle);
}