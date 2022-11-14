/**
 *Submitted for verification at Etherscan.io on 2022-11-13
*/

// SPDX-License-Identifier: MIT
pragma solidity 0.8.0;

// statuses: open to bid, pending validation, and fulfilled
// For open to bid: new job requests should automatically get this status
// For open to bid -> pending validation, the user/owner of the job request will trigger this transition after they "accept" a bid
// For pending validation -> fulfilled, the automation contract will trigger this transition after validating a node operators submittion

enum JobRequestState {
    OpenBid,
    PendingValidation,
    Validated
}

// https://docs.chain.link/docs/jobs/

struct Datasource {
    string url; // url to get data
    string name;
    string auth;
    string dataFormat;
    string description;
}

struct OperatorSubmission {
    string jobRequestId;
    string jobRequestName;
    Datasource datasource;
    string dataResponse; // serialized json object
}

struct OperatorBid {
    uint256 id;
    address nodeOperator;
    uint256 dataFeedFee;
    OperatorSubmission submission;
    uint jobRequestId;
}

struct JobRequestData {
    uint256 id;
    address requestor; // address of person requesting data feed
    Datasource requestedDataSource;
    JobRequestState currentState;
}

interface JobRequestInterface {
    // Data store functions ///////////////////

    // See example pagination here: https://programtheblockchain.com/posts/2018/04/20/storage-patterns-pagination/
    function getJobRequests(uint256 cursor, uint256 pageSize)
        external
        view
        returns (JobRequestData[] memory, uint256 new_cursor);

    function getJobRequestById(uint256 jobRequestId)
        external
        view
        returns (JobRequestData memory);

    function getBidsOnJobRequest(uint jobRequestId) external view returns (OperatorBid[] memory);

    function createJobRequest(Datasource calldata dataSource)
        external
        returns (bool);

    // Require caller to be requestor in OperatorRequestData
    function acceptBid(uint256 jobRequestId, uint256 operatorBidId) external;

    function submitBid(uint256 jobRequestId, OperatorSubmission memory operatorSubmission, uint dataFee)
        external;

    // Validation functions ///////////////////

    // Method that `performUpkeep` method in the automation contract will call
    function validatePendingBids() external returns (bool);
}

// Contract to be implemented
contract JobRequest is JobRequestInterface {
    event JobRequestCreated(
        address indexed _createdBy,
        uint indexed requestId
    );
    event JobRequestUpdated(
        address indexed _createdBy,
        uint indexed requestId,
        uint indexed bidId,
        string currentState
    );

    event OperatorSubmittedBid(
        address indexed operatorAddress,
        uint indexed jobRequestId,
        uint indexed operatorBidId
    );

    event OperatorSubmissionValidated(
        int indexed operatorBidId,
        int indexed jobRequestId,
        address indexed nodeOperator
    );

    // Hashmap we are using as a database to manage job request
    mapping(uint256 => JobRequestData) public jobRequests;
    // Mapping between job request ID and bids. Had to remove from job request data because of this: https://stackoverflow.com/questions/49345903/copying-of-type-struct-memory-memory-to-storage-not-yet-supported
    mapping(uint256 => OperatorBid[]) bids;

    uint256 public numOfJobRequests;
    uint256 public numSubmittedOfBids;

    // Hashmap acting as a cache to know which bids we need to validate with automation contract
    mapping(uint256 => OperatorBid) private bidsPendingValidation;
    uint256 public numOfBidsPendingValidation;

    function createJobRequest(Datasource calldata dataSource)
        external
        override
        returns (bool)
    {
        uint newId = numOfJobRequests;

        JobRequestData memory newRequestData = JobRequestData({
            id: newId, 
            requestor: msg.sender,
            requestedDataSource: dataSource,
            currentState: JobRequestState.OpenBid
        });

        jobRequests[newId] = newRequestData;

        numOfJobRequests++;

        emit JobRequestCreated(msg.sender, newId);
        return true;
    }

    function getJobRequests(uint256 cursor, uint256 requestAmount)
        external
        view
        override
        returns (JobRequestData[] memory, uint256 new_cursor)
    {
        // Paginate through jobrequest mapping to return a slice to a caller
        // there must be jobs in order to send request
        require(requestAmount > 0, "There are currently no jobs to request.");

        // make sure request amount is less than or equal 10
        require(requestAmount <= 10, "Only can request 10 max at a time.");

        // we initilize size with job amount and we check if the size is inbounds
        // if so we want to reduce the size
        uint256 size = requestAmount;
        if (size > numOfJobRequests - cursor) {
            size = numOfJobRequests - cursor;
        }

        // we initilize an array with the size of jobs
        JobRequestData[] memory jobs = new JobRequestData[](size);

        // we iterate using until we've reached our desired size add the jobs that we plan to return in a jobs array
        for (uint256 idx = 0; idx < size; idx++) {
            jobs[idx] = jobRequests[cursor + idx];
        }

        // we return the jobs array and the new cursor size
        return (jobs, cursor + size);
    }

    function getJobRequestById(uint256 jobRequestId)
        external
        view
        override
        returns (JobRequestData memory)
    {
        return jobRequests[jobRequestId];
    }

    function getBidsOnJobRequest(uint jobRequestId) external view override returns (OperatorBid[] memory) {
        return bids[jobRequestId];
    }

    function submitBid(uint jobRequestId, OperatorSubmission memory operatorSubmission, uint dataFee)
        public
        override
    {
        // check to see if job request exists
        require(
            jobRequests[jobRequestId].id >= 0,
            "Job request id doesn't exist."
        );

        OperatorBid[] memory currentBids = bids[jobRequestId];

        // check if user already sumitted a bid on this jobRequest
        for (uint256 idx = 0; idx < currentBids.length; idx++) {
            require(
                currentBids[idx].nodeOperator != msg.sender,
                "Already submitted a bid."
            );
        }

        // updates jobRequest bids with new element
        bids[jobRequestId].push(OperatorBid({
            id: numSubmittedOfBids,
            nodeOperator: msg.sender,
            dataFeedFee: dataFee,
            submission: operatorSubmission,
            jobRequestId: jobRequestId
        }));

        emit OperatorSubmittedBid(msg.sender, jobRequestId, numSubmittedOfBids);

        numSubmittedOfBids += 1;
    }


    function acceptBid(uint256 jobRequestId, uint256 operatorBidId)
        public
        override
    {

        // check if job request id exists
        require(
            jobRequests[jobRequestId].id > 0,
            "Job request id doesn't exist."
        );

        // check if message sender created the job request
        require(
            msg.sender == jobRequests[jobRequestId].requestor,
            "Only the address that created this request can accept bids"
         );

        // check if there is atleast one bid to accept
        require(
            bids[jobRequestId].length >= 1,
            "There are no bids for this job request."
        );

        // check to see if bid is in validated state
        require(
            jobRequests[jobRequestId].currentState != JobRequestState.Validated,
            "Bid is already in validated state."
        );

        OperatorBid[] memory currentBids = bids[jobRequestId];

        // loops through number of bids to find matching operator bid id
        for (uint256 idx = 0; idx < currentBids.length; idx++) {
            if (currentBids[idx].id == operatorBidId) {
                // update bid state to Pending Validation
                jobRequests[jobRequestId].currentState = JobRequestState
                    .PendingValidation;
                
                // Add bid to pending validation so chainlink automation will trigger validation
                bidsPendingValidation[operatorBidId] = currentBids[idx];

                // increment numOfBidsPendingValidation by 1
                numOfBidsPendingValidation += 1;

                emit JobRequestUpdated( jobRequests[jobRequestId].requestor, jobRequestId, operatorBidId, "Pending Validation");
            }
        }

    }

    ////////// Validation functions //////////
    function validatePendingBids() external override returns (bool) {
        // Called by `upKeepFunction`
        //Gets up to five bids from bidsPendingValidation
        // call validateBidSubmission on them
        // decrement numOfBidsPendingValidation
        // decrement numSubmittedOfBids

        emit OperatorSubmissionValidated(1,1,msg.sender);
        return true;
    }

    // Data validation function.
    // When `validatePendingBids` is called that method will attemot to call this method at least once (the first non zero address retreived from bidsPendingValidation)
    function validateBidSubmission(uint256 jobRequestId, uint256 operatorBidId)
        private
        returns (bool)
    {
        return true;
    }
}