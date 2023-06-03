// SPDX-License-Identifier: MIT
pragma solidity ^0.8.18;

/// @title Lighthouse for handling freelance jobs on Ethereum Blockchain
contract Lighthouse {
    /// @notice Represents various possible states of a job
    enum Status {
        openToHire,
        inProgress,
        submitted,
        destroyed,
        finished
    }

    /// @dev Holds job-related data
    struct Job {
        uint deadline;
        uint duration;
        string infoURI;
        uint bounty;
        Status status;
        address payable owner;
        address payable worker;
        Application[] applications;
    }

    /// @dev Holds application-related data
    struct Application {
        uint amountStaked;
        address applicant;
        string IPFSURI;
    }

    mapping(uint => Job) public jobs;
    uint public jobCount;

    event JobCreated(uint indexed jobID, uint bounty, address indexed owner);
    event ApplicationConfirmed(uint indexed jobID, address indexed worker);
    event JobSubmitted(uint indexed jobID, address indexed worker);
    event JobFinalized(uint indexed jobID, address indexed worker);
    event JobDestroyed(
        uint indexed jobID,
        uint amountBurnt,
        address indexed owner
    );

    /// @notice Creates a new job
    /// @param _duration The deadline by which the job needs to be completed
    /// @param _infoURI The info URI (IPFS hash) containing the project details
    function create_new_Job(
        uint _duration,
        string memory _infoURI
    ) public payable {
        require(msg.value > 0, "Job bounty must be greater than zero.");
        require(bytes(_infoURI).length > 0, "Job info URI cannot be empty.");

        uint newJobID = jobCount;
        jobCount++;

        Job storage newJob = jobs[newJobID];
        newJob.duration = _duration;
        newJob.infoURI = _infoURI;
        newJob.bounty = msg.value;
        newJob.status = Status.openToHire;
        newJob.owner = payable(msg.sender);

        emit JobCreated(newJobID, msg.value, msg.sender);
    }

    /// @notice Confirms a specific job application
    /// @param _jobID The ID of the job for which the application is confirmed
    /// @param _applicationIndex The index of the target application within the list of applications for the job
    function confirm_job(uint _jobID, uint _applicationIndex) public {
        require(_jobID < jobCount, "Job does not exist.");
        Job storage selectedJob = jobs[_jobID];
        require(
            selectedJob.status == Status.openToHire,
            "Job must be open to hire in order to confirm an application."
        );
        require(
            msg.sender == selectedJob.owner,
            "Only the owner of the job can confirm an application."
        );
        require(
            _applicationIndex < selectedJob.applications.length,
            "Invalid application index."
        );
        require(
            selectedJob.worker == address(0),
            "Job has already been assigned to a worker."
        );

        Application storage selectedApplication = selectedJob.applications[
            _applicationIndex
        ];
        require(
            selectedApplication.amountStaked > 0,
            "Selected application must have a stake."
        );

        uint[] memory returnedStakes = new uint[](
            selectedJob.applications.length - 1
        );
        uint returnedStakesIndex = 0;

        for (uint i = 0; i < selectedJob.applications.length; i++) {
            if (i != _applicationIndex) {
                Application storage currentApplication = selectedJob
                    .applications[i];
                uint amountStaked = currentApplication.amountStaked;
                currentApplication.amountStaked = 0;
                returnedStakes[returnedStakesIndex] = amountStaked;
                returnedStakesIndex++;
            }
        }

        selectedJob.worker = payable(selectedApplication.applicant);
        selectedJob.status = Status.inProgress;
        selectedJob.deadline = block.timestamp + selectedJob.duration;

        emit ApplicationConfirmed(_jobID, selectedJob.worker);

        for (uint i = 0; i < returnedStakes.length; i++) {
            if (returnedStakes[i] > 0) {
                payable(selectedJob.applications[i].applicant).transfer(
                    returnedStakes[i]
                );
            }
        }
    }

    /// @notice Allows a candidate to apply for an open job
    /// @param _jobID The ID of the job they wish to apply for
    /// @param _IPFSData The IPFS hash containing the applicant's proposal details
    function apply_for_job(
        uint _jobID,
        string memory _IPFSData
    ) public payable {
        require(_jobID < jobCount, "Job does not exist.");
        Job storage selectedJob = jobs[_jobID];
        require(
            selectedJob.status == Status.openToHire,
            "Job must be open to hire in order to apply."
        );
        require(
            bytes(_IPFSData).length > 0,
            "Applicant's proposal details cannot be empty."
        );
        require(
            msg.sender != selectedJob.owner,
            "Owner cannot apply for their own job."
        );
        require(
            msg.value == selectedJob.bounty / 10,
            "Applicant must stake 10% of the job bounty."
        );

        Application memory newApplication = Application({
            amountStaked: msg.value,
            applicant: msg.sender,
            IPFSURI: _IPFSData
        });
        selectedJob.applications.push(newApplication);
    }

    /// @notice Rescinds an application from a candidate, returning their staked bounty
    /// @param _jobID The ID of the job they wish to rescind their application for
    function rescind_application(uint _jobID) public {
        require(_jobID < jobCount, "Job does not exist.");
        Job storage selectedJob = jobs[_jobID];
        require(
            selectedJob.status == Status.openToHire,
            "Job must be open to hire in order to rescind an application."
        );

        for (uint i = 0; i < selectedJob.applications.length; i++) {
            if (selectedJob.applications[i].applicant == msg.sender) {
                uint amountStaked = selectedJob.applications[i].amountStaked;
                selectedJob.applications[i] = selectedJob.applications[
                    selectedJob.applications.length - 1
                ];
                selectedJob.applications.pop();
                if (amountStaked > 0) {
                    payable(msg.sender).transfer(amountStaked);
                }
                break;
            }
        }
    }

    /// @notice Allows the hired worker to submit completed work for a job
    /// @param _jobID The ID of the job for which the work is being submitted
    function submit_work(uint _jobID) public {
        require(_jobID < jobCount, "Job does not exist.");
        Job storage selectedJob = jobs[_jobID];
        require(
            selectedJob.status == Status.inProgress,
            "Job must be in progress in order to submit work."
        );
        require(
            msg.sender == selectedJob.worker,
            "Only the worker for the job can submit work."
        );

        selectedJob.status = Status.submitted;
        emit JobSubmitted(_jobID, selectedJob.worker);
    }

    /// @notice Allows the job owner to finalize a submitted job and release the payment
    /// @param _jobID The ID of the job to be finalized
    function finalize_job(uint _jobID) public {
        require(_jobID < jobCount, "Job does not exist.");
        Job storage selectedJob = jobs[_jobID];
        require(
            msg.sender == selectedJob.owner,
            "Only the owner of the job can finalize a job."
        );
        require(
            selectedJob.status == Status.submitted,
            "Job must be submitted in order to be finalized."
        );

        uint applicationStake = getApplicationStake(
            selectedJob.applications,
            selectedJob.worker
        );
        uint payment = selectedJob.bounty + applicationStake;
        selectedJob.status = Status.finished;
        emit JobFinalized(_jobID, selectedJob.worker);
        payable(selectedJob.worker).transfer(payment);
    }

    /// @notice Allows the owner of a job to destroy it (Job must be open to hire)
    /// @param _jobID The ID of the job to be destroyed
    function destroy_job(uint _jobID) public {
        require(_jobID < jobCount, "Job does not exist.");
        Job storage selectedJob = jobs[_jobID];
        require(
            msg.sender == selectedJob.owner,
            "Only the owner of the job can destroy a job."
        );
        require(
            selectedJob.status == Status.submitted ||
                (block.timestamp > selectedJob.deadline &&
                    selectedJob.deadline > 0),
            "Job must be open to hire, submitted, or expired to be destroyed."
        );

        uint amountToBurn = selectedJob.bounty / 10;
        uint applicationStake = getApplicationStake(
            selectedJob.applications,
            selectedJob.worker
        );
        payable(address(0)).transfer(amountToBurn + applicationStake);
        selectedJob.owner.transfer(selectedJob.bounty - amountToBurn);

        selectedJob.status = Status.destroyed;
        emit JobDestroyed(_jobID, amountToBurn + applicationStake, address(0));
    }

    /// @notice Returns info on all jobs in the contract
    /// @return jobIDs Array of job IDs
    /// @return deadlines Array of job deadlines
    /// @return infoURIs Array of job info URIs
    /// @return durations Array of job durations
    /// @return bounties Array of job bounties
    /// @return statuses Array of job statuses
    function see_all_jobs_info()
        public
        view
        returns (
            uint[] memory jobIDs,
            uint[] memory deadlines,
            string[] memory infoURIs,
            uint[] memory durations,
            uint[] memory bounties,
            Status[] memory statuses
        )
    {
        jobIDs = new uint[](jobCount);
        deadlines = new uint[](jobCount);
        durations = new uint[](jobCount);
        infoURIs = new string[](jobCount);
        bounties = new uint[](jobCount);
        statuses = new Status[](jobCount);

        for (uint i = 0; i < jobCount; i++) {
            Job storage currentJob = jobs[i];
            jobIDs[i] = i;
            deadlines[i] = currentJob.deadline;
            infoURIs[i] = currentJob.infoURI;
            durations[i] = currentJob.duration;
            bounties[i] = currentJob.bounty;
            statuses[i] = currentJob.status;
        }
    }

    /// @notice Retrieves applications for a specific job
    /// @param _jobID The ID of the target job
    /// @return An array containing all applications received for the specified job
    function see_applications_for_job(
        uint _jobID
    ) public view returns (Application[] memory) {
        require(_jobID < jobCount, "Job does not exist.");
        Job storage selectedJob = jobs[_jobID];
        require(
            selectedJob.status == Status.openToHire,
            "Job must be open to hire in order to see applications."
        );

        return selectedJob.applications;
    }

    /// @notice Looks up the stake associated with a particular applicant
    /// @param _applications Array of applications to search through
    /// @param _applicant Address of the applicant whose stake must be retrieved
    /// @return applicationStake The applicant's staked amount
    function getApplicationStake(
        Application[] storage _applications,
        address _applicant
    ) internal view returns (uint applicationStake) {
        for (uint i = 0; i < _applications.length; i++) {
            if (_applications[i].applicant == _applicant) {
                applicationStake += _applications[i].amountStaked;
                break;
            }
        }
    }
}