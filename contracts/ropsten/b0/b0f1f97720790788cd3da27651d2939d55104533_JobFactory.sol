/**
 *Submitted for verification at Etherscan.io on 2022-04-26
*/

// SPDX-License-Identifier: UNLICENSED

pragma solidity 0.8.4;

// File @openzeppelin/contracts/token/ERC20/[email protected]

// OpenZeppelin Contracts (last updated v4.5.0) (token/ERC20/IERC20.sol)    

/**
 * @dev Interface of the ERC20 standard as defined in the EIP.
 */
interface IERC20 {
    /**
     * @dev Returns the amount of tokens in existence.
     */
    function totalSupply() external view returns (uint256);

    /**
     * @dev Returns the amount of tokens owned by `account`.
     */
    function balanceOf(address account) external view returns (uint256);    

    /**
     * @dev Moves `amount` tokens from the caller's account to `to`.        
     *
     * Returns a boolean value indicating whether the operation succeeded.  
     *
     * Emits a {Transfer} event.
     */
    function transfer(address to, uint256 amount) external returns (bool);  

    /**
     * @dev Returns the remaining number of tokens that `spender` will be   
     * allowed to spend on behalf of `owner` through {transferFrom}. This is
     * zero by default.
     *
     * This value changes when {approve} or {transferFrom} are called.      
     */
    function allowance(address owner, address spender) external view returns (uint256);

    /**
     * @dev Sets `amount` as the allowance of `spender` over the caller's tokens.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * IMPORTANT: Beware that changing an allowance with this method brings the risk
     * that someone may use both the old and the new allowance by unfortunate
     * transaction ordering. One possible solution to mitigate this race
     * condition is to first reduce the spender's allowance to 0 and set the
     * desired value afterwards:
     * https://github.com/ethereum/EIPs/issues/20#issuecomment-263524729
     *
     * Emits an {Approval} event.
     */
    function approve(address spender, uint256 amount) external returns (bool);

    /**
     * @dev Moves `amount` tokens from `from` to `to` using the
     * allowance mechanism. `amount` is then deducted from the caller's
     * allowance.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transferFrom(
        address from,
        address to,
        uint256 amount
    ) external returns (bool);

    /**
     * @dev Emitted when `value` tokens are moved from one account (`from`) to
     * another (`to`).
     *
     * Note that `value` may be zero.
     */
    event Transfer(address indexed from, address indexed to, uint256 value);

    /**
     * @dev Emitted when the allowance of a `spender` for an `owner` is set by
     * a call to {approve}. `value` is the new allowance.
     */
    event Approval(address indexed owner, address indexed spender, uint256 value);
}

// File contracts/VickreyAuction.sol

pragma solidity 0.8.4;
contract VickreyAuction {

    /**
    * @notice Used to notify the end of an auction
   */
    event AuctionEnded(
        address indexed endUser,
        uint auctionId,
        address winner,
        uint secondHighestBid
    );
  /**
   * @notice Used to notify that a bid was placed
   */
    event BidPlaced(
        address indexed endUser,
        uint indexed auctionId,
        address indexed bidder
    );
  /**
   * @notice Used to notify that a worker node was paid for a job
   */
    event PaidOut(
        address indexed endUser,
        uint indexed auctionId,
        uint amount
    );

    enum AuctionStatus {
        isActive,
        isEndedButNotPaid,
        isEndedAndPaid
    }

    struct Bid {
        bytes32 blindedBid;
        address jobPoster;
        uint auctionId;
        uint deposit;
    }

    struct Auction {
        uint minimumPayout;
        uint reward;
        uint biddingDeadline;
        uint revealDeadline;
        uint bidsPlaced;
        uint highestBid;
        uint secondHighestBid;
        address highestBidder;
        AuctionStatus auctionStatus;
    }

    //mapping of data scientist / job poster to auction
    mapping(address => Auction[]) public auctions;

    //mapping of bid hash to bid
    mapping(bytes32 => Bid) private bids;

    //mapping of account to num of stale bids
    mapping(address => uint) private staleBids;

    //instance of Morphware token
    IERC20 public token;

    error TooEarly(uint time);
    error TooLate(uint time);
    error AuctionEndAlreadyCalled();
    error DoesNotMatchBlindedBid();

    //modifier to prevent bids before provided time
    modifier onlyBefore(uint _time) {
        if (block.timestamp >= _time) revert TooLate(_time);
        _;
    }

    //modifier to prevent bids after provided time
    modifier onlyAfter(uint _time) {
        if (block.timestamp <= _time) revert TooEarly(_time);
        _;
    }

  /**
   * @notice Constructor
   * @param _token IERC20 Morphware token
   */
    constructor(
        IERC20 _token
    ) {
        token = _token;
    }



  /**
   * @notice Starts auction
   * @dev This function is only ever called from the JobFactory contract
   * @param _minimumPayout uint minimum payout
   * @param _biddingDeadline uint biddin deadline
   * @param _revealDeadline uint reveal deadline
   * @param _reward uint reward
   * @param _endUser address data scientist/job poster
   */
    function start(
        uint _minimumPayout,
        uint _biddingDeadline,
        uint _revealDeadline,
        uint _reward,
        address _endUser
    )
        public
    {
        // NEED TO FIGURE OUT WHICH CONTRACT WILL HAVE CUSTODY OF DATA SCIENTIST'S FUNDS
        uint allowedAmount = token.allowance(_endUser,address(this));
        require(allowedAmount >= _reward,'allowedAmount must be greater than or equal to _reward');
        token.transferFrom(_endUser,address(this),_reward);

        auctions[_endUser].push(Auction({
            minimumPayout: _minimumPayout,
            reward: _reward,
            biddingDeadline: _biddingDeadline,
            revealDeadline: _revealDeadline,
            bidsPlaced: 0,
            highestBid: 0,
            secondHighestBid: 0,
            highestBidder: _endUser,
            auctionStatus: AuctionStatus.isActive
        }));
    }

  /**
   * @notice Bid on auction
   * @dev This function is only ever called by a worker node
   * @param _endUser address data scientist/job poster
   * @param _auctionId uint auction ID
   * @param _blindedBid bytes32 blinded bid
   * @param _amount uint bid amount
   */
    function bid(
        address _endUser,
        uint _auctionId,
        bytes32 _blindedBid,
        uint _amount
    )
        public
        onlyBefore(auctions[_endUser][_auctionId].biddingDeadline)
    {
        require(_amount < auctions[_endUser][_auctionId].reward,'_amount must be less than reward');        
        require(_amount > auctions[_endUser][_auctionId].minimumPayout,'_amount must be greater than minimumPayout');
        uint allowedAmount = token.allowance(msg.sender,address(this));
        require(allowedAmount >= _amount,'allowedAmount must be greater than or equal to _amount');
        // TODO  1.5 Re-factor `transferFrom` to eliminate gas costs?
        // NEED TO FIGURE OUT WHETHER WE WANT TO USE INTERNAL ACCOUNTING AND LET USERS WITHDRAW OR
        // IF WE WANT TO JUST USE TRANSFERFROM
        token.transferFrom(msg.sender,address(this),_amount);
        bids[keccak256(abi.encodePacked(_endUser,_auctionId,msg.sender))] = Bid({
            blindedBid: _blindedBid,
            deposit: _amount,
            jobPoster: _endUser,
            auctionId: _auctionId
        });
        emit BidPlaced(
            _endUser,
            _auctionId,
            msg.sender);
    }

  /**
   * @notice Reveals bids
   * @param _endUser address data scientist/job poster
   * @param _auctionId uint auction ID
   * @param _amount uint bid amount
   * @param _fake bool whether a bid is fake or not
   * @param _secret bytes32 bid secret
   */
    function reveal(
        address _endUser,
        uint _auctionId,
        uint _amount,
        bool _fake,
        bytes32 _secret
    )
        public
        onlyAfter(auctions[_endUser][_auctionId].biddingDeadline)
        onlyBefore(auctions[_endUser][_auctionId].revealDeadline)
    {
        Bid storage bidToCheck = bids[keccak256(abi.encodePacked(_endUser,_auctionId,msg.sender))];
        //If the trying to reveal a valid sealed bid
        if (bidToCheck.jobPoster == _endUser && bidToCheck.auctionId == _auctionId) {
            uint refund;
            //If the bid arguments don't match the bid you are trying to reveal
            if (bidToCheck.blindedBid != keccak256(abi.encodePacked(_amount, _fake, _secret))) {
                revert DoesNotMatchBlindedBid();
            }
            refund += bidToCheck.deposit;
            //If it was a real bid and bid value matches what you said it was
            //TODO bidToCheck.deposit should be equal to _amount. Why is it >=?
            if (!_fake && bidToCheck.deposit >= _amount) {
                //Place bid of the now revealed bid
                if (placeBid(_endUser, _auctionId, msg.sender, _amount)) {
                    refund -= _amount;
                }
            }
            bidToCheck.blindedBid = bytes32(0);
            // TODO 1 Replace the `transfer` invocation with a safer alternative
            if (refund > 0) token.transfer(msg.sender,refund);
        }
    }

  /**
   * @notice Withdraw funds for stale bids
   */
    function withdraw() public {
        uint amount = staleBids[msg.sender];
        if (amount > 0) {
            staleBids[msg.sender] = 0;
            // TODO 1 Replace the `transfer` invocation with a safer alternative
            token.transfer(msg.sender,amount);
        }
    }

  /**
   * @notice Ends an auction
   * @param _endUser address data scientist/job poster
   * @param _auctionId uint auction ID
   */
    function auctionEnd(
        address _endUser,
        uint _auctionId
    )
        public
        onlyAfter(auctions[_endUser][_auctionId].revealDeadline)
    {
        if (auctions[_endUser][_auctionId].auctionStatus != AuctionStatus.isActive) revert AuctionEndAlreadyCalled();
        emit AuctionEnded(
            _endUser,
            _auctionId,
            auctions[_endUser][_auctionId].highestBidder,
            auctions[_endUser][_auctionId].secondHighestBid);
        auctions[_endUser][_auctionId].auctionStatus = AuctionStatus.isEndedButNotPaid;
    }

    /// @dev This should be called by `_endUser`
  /**
   * @notice Pays out auction winner
   * @dev This function is only ever called by a data scientist/job poster
   * @param _endUser address data scientist/job poster
   * @param _auctionId uint auction ID
   */
    function payout(
        address _endUser,
        uint _auctionId
    )
        public
    {
        require(auctions[_endUser][_auctionId].auctionStatus != AuctionStatus.isActive, 'VickreyAuction has not ended');
        require(auctions[_endUser][_auctionId].auctionStatus != AuctionStatus.isEndedAndPaid, 'VickreyAuction has been paid-out');
        if (auctions[_endUser][_auctionId].bidsPlaced == 0) {
            token.transfer(_endUser, auctions[_endUser][_auctionId].reward);
        } else {
            uint workerPay = auctions[_endUser][_auctionId].secondHighestBid + auctions[_endUser][_auctionId].highestBid;
            uint refund = auctions[_endUser][_auctionId].reward - auctions[_endUser][_auctionId].secondHighestBid;

            token.transfer(auctions[_endUser][_auctionId].highestBidder, workerPay);
            token.transfer(_endUser, refund);

            emit PaidOut(
                _endUser,
                _auctionId,
                workerPay);
        }
        auctions[_endUser][_auctionId].auctionStatus = AuctionStatus.isEndedAndPaid;
    }

  /**
   * @notice Helper function to place bid
   * @dev This function is only ever called by the reveal function
   * @param _endUser address data scientist/job poster
   * @param _auctionId uint auction ID
   * @param _bidder address bidder
   * @param _amount uint bid amount
   */
    function placeBid(
        address _endUser,
        uint _auctionId,
        address _bidder,
        uint _amount
    )
        internal
        returns (bool success)
    {
        // If there is already another higher bidder, don't place the bid
        if (_amount <= auctions[_endUser][_auctionId].highestBid) {
            return false;
        }

        //If there is already another non-poster highest bidder, and you are the new highest bidder
        if (auctions[_endUser][_auctionId].highestBidder != address(0)) {
            //Get the highest bidders address
            address hb = auctions[_endUser][_auctionId].highestBidder;
            //TODO why is this +=
            staleBids[hb] += auctions[_endUser][_auctionId].highestBid;
        }
        auctions[_endUser][_auctionId].secondHighestBid = auctions[_endUser][_auctionId].highestBid;        
        auctions[_endUser][_auctionId].highestBid = _amount;
        auctions[_endUser][_auctionId].highestBidder = _bidder;
        auctions[_endUser][_auctionId].bidsPlaced += 1;
        return true;
    }
}


// File contracts/JobFactory.sol

/**
 * @title Morphware JobFactory
 * @notice Responsible for creating & storing jobs and sharing model/training data
 * @dev this implementation originally described the job poster <-> worker node, but now includes validator 
nodes
 */
contract JobFactory {
  /**
   * @notice Used to notify worker nodes of a new job
   */
    event JobDescriptionPosted(
        address jobPoster,
        uint16 estimatedTrainingTime,
        uint64 trainingDatasetSize,
        address auctionAddress,
        uint id,
        uint workerReward,
        uint biddingDeadline,
        uint revealDeadline,
        uint64 clientVersion
    );
  /**
   * @notice Used to share model and training data with auction winner
   */
    event UntrainedModelAndTrainingDatasetShared(
        address indexed jobPoster,
        uint64 targetErrorRate,
        address indexed workerNode,
        uint indexed id,
        string untrainedModelMagnetLink,
        string trainingDatasetMagnetLink
    );
  /**
   * @notice Used to share trained model data
   */
    event TrainedModelShared(
        address indexed jobPoster,
        uint64 trainingErrorRate,
        address indexed workerNode,
        uint indexed id,
        string trainedModelMagnetLink
    );
  /**
   * @notice Used to share testing data and trained model data for validator nodes
   */
    event TestingDatasetShared(
        address indexed jobPoster,
        uint64 targetErrorRate,
        uint indexed id,
        string trainedModelMagnetLink,
        string testingDatasetMagnetLink,
        string untrainedModelMagnetLink
    );
  /**
   * @notice Used to share that a model was validated
   */
    event JobApproved(
        address indexed jobPoster,
        address indexed workerNode,
        address indexed validatorNode,
        string trainedModelMagnetLink,
        uint id
    );

    enum Status {
        PostedJobDescription,
        SharedUntrainedModelAndTrainingDataset,
        SharedTrainedModel,
        SharedTestingDataset,
        ApprovedJob
    }

    enum AuctionStatus {
        isActive,
        isEndedButNotPaid,
        isEndedAndPaid
    }

    struct Job {
        uint auctionId;
        address workerNode;
        uint64 targetErrorRate;
        Status status;
        uint64  clientVersion;
    }

    //mapping of account to jobs
    mapping (address => Job[]) public jobs;

    //instance of Morphware token contract
    IERC20 public token;

    //instance of VickreyAuction contract
    VickreyAuction vickreyAuction;

  /**
   * @notice Constructor
   * @param _token IERC20 Morphware token
   * @param _auctionAddress address VickreyAuction contract
   */
    constructor(
        IERC20 _token,
        address _auctionAddress
    ) {
        token = _token;
        vickreyAuction = VickreyAuction(_auctionAddress);
    }

  /**
   * @notice Post job description (called by data scientist/job poster)
   * @param _estimatedTrainingTime uint16 estimated time to train model
   * @param _trainingDatasetSize uint64 size of dataset in bytes
   * @param _targetErrorRate uint64 target error rate
   * @param _minimumPayout uint minimum amount payed out to auction winner
   * @param _workerReward uint worker reward amount
   * @param _clientVersion uint64 client version
   */
    function postJobDescription(
        uint16 _estimatedTrainingTime,
        uint64 _trainingDatasetSize,
        uint64 _targetErrorRate,
        uint _minimumPayout,
        uint _workerReward,
        uint64 _clientVersion
    ) public {
        uint jobId = jobs[msg.sender].length;
        uint biddingDeadline = block.timestamp + 300;
        uint revealDeadline = block.timestamp + 600;

        vickreyAuction.start(
            _minimumPayout,
            biddingDeadline,
            revealDeadline,
            _workerReward,
            msg.sender);

        jobs[msg.sender].push(Job(
            jobId,
            address(0),
            _targetErrorRate,
            Status.PostedJobDescription,
            _clientVersion));

        emit JobDescriptionPosted(
            msg.sender,
            _estimatedTrainingTime,
            _trainingDatasetSize,
            address(vickreyAuction),
            jobId,
            _workerReward,
            biddingDeadline,
            revealDeadline,
            _clientVersion
        );
    }

  /**
   * @notice Share untrained model and training data (called by data scientist/job poster)
   * @dev The untrained model and the training dataset have been encrypted with the `workerNode` public key 
and `_jobPoster` private key
   * @param _id uint job (auction) ID
   * @param _untrainedModelMagnetLink string untrained model link
   * @param _trainingDatasetMagnetLink string training data link
   */
    function shareUntrainedModelAndTrainingDataset(
        uint _id,
        string memory _untrainedModelMagnetLink,
        string memory _trainingDatasetMagnetLink
    ) public {
        // FIXME require(vickreyAuction.ended(),'Auction has not ended');
        // Add check that auction has ended
        (,,,,,,, address workerNode, ) = vickreyAuction.auctions(msg.sender,_id);
        Job memory job = jobs[msg.sender][_id];
        require(job.status == Status.PostedJobDescription,'Job has not been posted');
        job.status = Status.SharedUntrainedModelAndTrainingDataset;
        job.workerNode = workerNode;
        jobs[msg.sender][_id] = job;
        //TODO GitHub Issue 77. Anybody can view these MagnetURI's. Possible security concern.
        emit UntrainedModelAndTrainingDatasetShared(
            msg.sender,
            job.targetErrorRate,
            workerNode,
            _id,
            _untrainedModelMagnetLink,
            _trainingDatasetMagnetLink
        );
    }


  /**
   * @notice Share trained model (called by worker node)
   * @dev The trained model has been encrypted with the `_jobPoster`s public key and `workerNode` private key
   * @param _jobPoster address data scientist's address
   * @param _id uint job ID
   * @param _trainedModelMagnetLink string trained model link
   * @param _trainingErrorRate uint64 training error rate
   */
    function shareTrainedModel(
        address _jobPoster,
        uint _id,
        string memory _trainedModelMagnetLink,
        uint64 _trainingErrorRate
    ) public {
        Job memory job = jobs[_jobPoster][_id];
        require(job.workerNode != address(0), 'Worker Node has not yet been selected');
        require(msg.sender == job.workerNode,'msg.sender must equal workerNode');
        require(job.status == Status.SharedUntrainedModelAndTrainingDataset,'Untrained model and training dataset has not been shared');
        require(job.targetErrorRate >= _trainingErrorRate,'targetErrorRate must be greater or equal to _trainingErrorRate');
        jobs[_jobPoster][_id].status = Status.SharedTrainedModel;
        emit TrainedModelShared(
            _jobPoster,
            _trainingErrorRate,
            msg.sender,
            _id,
            _trainedModelMagnetLink
        );
    }

  /**
   * @notice Share testing data (called by data scientist/job poster)
   * @notice The trained model has been encrypted with the `_jobPoster`s public key and `workerNode` private key
   * @param _id uint job ID
   * @param _trainedModelMagnetLink string trained model link
   * @param _testingDatasetMagnetLink string testing data link
   */
    function shareTestingDataset(
        uint _id,
        string memory _trainedModelMagnetLink,
        string memory _testingDatasetMagnetLink,
        string memory _untrainedModelMagnetLink
    ) public {
        Job memory job = jobs[msg.sender][_id];
        require(job.status == Status.SharedTrainedModel,'Trained model has not been shared');
        jobs[msg.sender][_id].status = Status.SharedTestingDataset;
        emit TestingDatasetShared(
            msg.sender,
            job.targetErrorRate,
            _id,
            _trainedModelMagnetLink,
            _testingDatasetMagnetLink,
            _untrainedModelMagnetLink
        );
    }

  /**
   * @notice Approve job (called by validator node)
   * @param _jobPoster address data scientist's address
   * @param _id uint job (auction) ID
   * @param _trainedModelMagnetLink string trained model link
   */
    function approveJob(
        address _jobPoster,
        uint _id,
        string memory _trainedModelMagnetLink
    ) public {
        Job memory job = jobs[_jobPoster][_id];
        require(msg.sender != job.workerNode,'msg.sender cannot equal workerNode');
        require(job.status == Status.SharedTestingDataset,'Testing dataset has not been shared');
        jobs[_jobPoster][_id].status = Status.ApprovedJob;
        // TODO Possible cruft below
        // FIXME
        // figure out if we want payout to be done here or in the daemon
        //vickreyAuction.payout(_jobPoster,_id);
        emit JobApproved(
            _jobPoster,
            job.workerNode,
            msg.sender,
            _trainedModelMagnetLink,
            _id
        );
    }
}