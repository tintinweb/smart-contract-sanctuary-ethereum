//SPDX-License-Identifier: MIT
pragma solidity 0.8.14;

contract Ownable {

    address private owner;
    
    // event for EVM logging
    event OwnerSet(address indexed oldOwner, address indexed newOwner);
    
    // modifier to check if caller is owner
    modifier onlyOwner() {
        // If the first argument of 'require' evaluates to 'false', execution terminates and all
        // changes to the state and to Ether balances are reverted.
        // This used to consume all gas in old EVM versions, but not anymore.
        // It is often a good idea to use 'require' to check if functions are called correctly.
        // As a second argument, you can also provide an explanation about what went wrong.
        require(msg.sender == owner, "Caller is not owner");
        _;
    }
    
    /**
     * @dev Set contract deployer as owner
     */
    constructor() {
        owner = msg.sender; // 'msg.sender' is sender of current call, contract deployer for a constructor
        emit OwnerSet(address(0), owner);
    }

    /**
     * @dev Change owner
     * @param newOwner address of new owner
     */
    function changeOwner(address newOwner) public onlyOwner {
        emit OwnerSet(owner, newOwner);
        owner = newOwner;
    }

    /**
     * @dev Return owner address 
     * @return address of owner
     */
    function getOwner() external view returns (address) {
        return owner;
    }
}

abstract contract VRFConsumerBaseV2 {
  error OnlyCoordinatorCanFulfill(address have, address want);
  address private immutable vrfCoordinator;

  /**
   * @param _vrfCoordinator address of VRFCoordinator contract
   */
  constructor(address _vrfCoordinator) {
    vrfCoordinator = _vrfCoordinator;
  }

  /**
   * @notice fulfillRandomness handles the VRF response. Your contract must
   * @notice implement it. See "SECURITY CONSIDERATIONS" above for important
   * @notice principles to keep in mind when implementing your fulfillRandomness
   * @notice method.
   *
   * @dev VRFConsumerBaseV2 expects its subcontracts to have a method with this
   * @dev signature, and will call it once it has verified the proof
   * @dev associated with the randomness. (It is triggered via a call to
   * @dev rawFulfillRandomness, below.)
   *
   * @param requestId The Id initially returned by requestRandomness
   * @param randomWords the VRF output expanded to the requested number of words
   */
  function fulfillRandomWords(uint256 requestId, uint256[] memory randomWords) internal virtual;

  // rawFulfillRandomness is called by VRFCoordinator when it receives a valid VRF
  // proof. rawFulfillRandomness then calls fulfillRandomness, after validating
  // the origin of the call
  function rawFulfillRandomWords(uint256 requestId, uint256[] memory randomWords) external {
    if (msg.sender != vrfCoordinator) {
      revert OnlyCoordinatorCanFulfill(msg.sender, vrfCoordinator);
    }
    fulfillRandomWords(requestId, randomWords);
  }
}

interface VRFCoordinatorV2Interface {
  /**
   * @notice Get configuration relevant for making requests
   * @return minimumRequestConfirmations global min for request confirmations
   * @return maxGasLimit global max for request gas limit
   * @return s_provingKeyHashes list of registered key hashes
   */
  function getRequestConfig()
    external
    view
    returns (
      uint16,
      uint32,
      bytes32[] memory
    );

  /**
   * @notice Request a set of random words.
   * @param keyHash - Corresponds to a particular oracle job which uses
   * that key for generating the VRF proof. Different keyHash's have different gas price
   * ceilings, so you can select a specific one to bound your maximum per request cost.
   * @param subId  - The ID of the VRF subscription. Must be funded
   * with the minimum subscription balance required for the selected keyHash.
   * @param minimumRequestConfirmations - How many blocks you'd like the
   * oracle to wait before responding to the request. See SECURITY CONSIDERATIONS
   * for why you may want to request more. The acceptable range is
   * [minimumRequestBlockConfirmations, 200].
   * @param callbackGasLimit - How much gas you'd like to receive in your
   * fulfillRandomWords callback. Note that gasleft() inside fulfillRandomWords
   * may be slightly less than this amount because of gas used calling the function
   * (argument decoding etc.), so you may need to request slightly more than you expect
   * to have inside fulfillRandomWords. The acceptable range is
   * [0, maxGasLimit]
   * @param numWords - The number of uint256 random values you'd like to receive
   * in your fulfillRandomWords callback. Note these numbers are expanded in a
   * secure way by the VRFCoordinator from a single random value supplied by the oracle.
   * @return requestId - A unique identifier of the request. Can be used to game
   * a request to a response in fulfillRandomWords.
   */
  function requestRandomWords(
    bytes32 keyHash,
    uint64 subId,
    uint16 minimumRequestConfirmations,
    uint32 callbackGasLimit,
    uint32 numWords
  ) external returns (uint256 requestId);

  /**
   * @notice Create a VRF subscription.
   * @return subId - A unique subscription id.
   * @dev You can manage the consumer set dynamically with addConsumer/removeConsumer.
   * @dev Note to fund the subscription, use transferAndCall. For example
   * @dev  LINKTOKEN.transferAndCall(
   * @dev    address(COORDINATOR),
   * @dev    amount,
   * @dev    abi.encode(subId));
   */
  function createSubscription() external returns (uint64 subId);

  /**
   * @notice Get a VRF subscription.
   * @param subId - ID of the subscription
   * @return balance - LINK balance of the subscription in juels.
   * @return reqCount - number of requests for this subscription, determines fee tier.
   * @return owner - owner of the subscription.
   * @return consumers - list of consumer address which are able to use this subscription.
   */
  function getSubscription(uint64 subId)
    external
    view
    returns (
      uint96 balance,
      uint64 reqCount,
      address owner,
      address[] memory consumers
    );

  /**
   * @notice Request subscription owner transfer.
   * @param subId - ID of the subscription
   * @param newOwner - proposed new owner of the subscription
   */
  function requestSubscriptionOwnerTransfer(uint64 subId, address newOwner) external;

  /**
   * @notice Request subscription owner transfer.
   * @param subId - ID of the subscription
   * @dev will revert if original owner of subId has
   * not requested that msg.sender become the new owner.
   */
  function acceptSubscriptionOwnerTransfer(uint64 subId) external;

  /**
   * @notice Add a consumer to a VRF subscription.
   * @param subId - ID of the subscription
   * @param consumer - New consumer which can use the subscription
   */
  function addConsumer(uint64 subId, address consumer) external;

  /**
   * @notice Remove a consumer from a VRF subscription.
   * @param subId - ID of the subscription
   * @param consumer - Consumer to remove from the subscription
   */
  function removeConsumer(uint64 subId, address consumer) external;

  /**
   * @notice Cancel a subscription
   * @param subId - ID of the subscription
   * @param to - Where to send the remaining LINK to
   */
  function cancelSubscription(uint64 subId, address to) external;
}

interface IGameScoreOracle {
    struct GameScore {
        uint256 id; // a unique id for this game determined by the outside world data set
        uint8 homeQ1LastDigit; // last digit of the home teams score at the end of q2
        uint8 homeQ2LastDigit; // last digit of the home team's cumulative score at the end of q1
        uint8 homeQ3LastDigit; 
        uint8 homeFLastDigit; // last digit of the home team's cumulative score at the end of the final period including OT
        uint8 awayQ1LastDigit; 
        uint8 awayQ2LastDigit; 
        uint8 awayQ3LastDigit; 
        uint8 awayFLastDigit;
        uint8 qComplete; // the number of the last period that has been completed including OT. expect 100 for the game to be considered final.
        bool requestInProgress; // true if there is a pending oracle request
    }

    function fetchGameScores(uint256 gameId) external pure returns (
        uint8, uint8, uint8, uint8, uint8, uint8, uint8, uint8, uint8, bool
    );

    function requestValues(uint256 gameId) external;
}

contract Boxes is Ownable, VRFConsumerBaseV2 {

    struct Box {
        uint256 id; // the id of the box for its contest (which determines its position on the grid)
        uint256 contestId; // the contest that this box belongs to
        address owner; // the owner who claimed this box
    }

    struct Contest {
        uint256 id; // a unique id for this contest based on the contestId counter
        uint gameId; // the id that maps to the real-world contest
        address creator; // the user who created the contest
        uint[] rows; // the row scores
        uint[] cols; // the col scores
        uint256 boxCost; // the amount of ETH needed to claim a box
        bool boxesCanBeClaimed; // whether or not boxes can be claimed by users (this is false once boxes have values)
        bool rewardsCanBeClaimed; // this prevents people from claiming rewards
        bool q1Paid; // track if user claimed their q1 reward
        bool q2Paid; // track if user claimed their q2 reward
        bool q3Paid; // track if user claimed their q3 reward
        bool finalPaid; // track if user claimed their final reward
        uint256 totalRewards; // track the total amount of buy-ins collected for the contest
        uint256 boxesClaimed; // amount of boxes claimed by users in this contest
        uint[] randomValues; // random numbers used to assign values to rows and cols
        bool randomValuesSet; // used to know whether or not chainlink has provided this contest with random values
    }

    struct GameScore {
        uint256 id; // a unique id for this game determined by the outside world data set
        uint8 homeQ1LastDigit; // last digit of the home teams score at the end of q2
        uint8 homeQ2LastDigit; // last digit of the home team's cumulative score at the end of q1
        uint8 homeQ3LastDigit; 
        uint8 homeFLastDigit; // last digit of the home team's cumulative score at the end of the final period including OT
        uint8 awayQ1LastDigit; 
        uint8 awayQ2LastDigit; 
        uint8 awayQ3LastDigit; 
        uint8 awayFLastDigit;
        uint8 qComplete; // the number of the last period that has been completed including OT. expect 100 for the game to be considered final.
        bool requestInProgress; // true if there is a pending oracle request
    }

    // the oracle where we get our game scores
    IGameScoreOracle public gameScoreOracle;

    // a time delay that prevents data from being freshed until the time delay is reached on a per-game basis
    // gameId => timestamp
    mapping (uint256 => uint256) public timeUntilNextFetchAllowed;
    uint256 public MINUTES_TO_DELAY_FETCH = 10 minutes;

    // contest counter
    uint256 public contestIdCounter = 0;

    // a list of all contests created
    // contestId => Contest
    mapping (uint256 => Contest) public contests;

    // a list of all contests created by the user
    // user address => contestIds
    mapping (address => uint256[]) public contestsByUser;

    // a list of contests where the user owns a box
    // address => contestIds true means they own a box
    mapping (address => uint256[]) public contestsWithUser;

    // a list of all the boxes for a contest
    // contest => (box id => box)
    mapping (uint256 => mapping (uint256 => Box)) boxes; // the boxes in the contest

    // a list of all boxes owned by the user
    // user address => array of Boxes
    mapping (address => Box[]) public boxesByUser;

    // the number of boxes on a grid
    uint256 private constant NUM_BOXES_IN_CONTEST = 100;

    // Treasury Address
    address public treasury;

    // Operations wallet
    address public operationsWallet;

    // default row and columns
    uint[] defaultScores = [0, 1, 2, 3, 4, 5, 6, 7, 8, 9];
    
    // payouts
    uint256 public q1Payout = 150; // q1 wins 15% of the pot
    uint256 public q2Payout = 300; // q2 wins 30% of the pot
    uint256 public q3Payout = 150; // q3 wins 15% of the pot
    uint256 public finalPayout = 380; // final wins 38% of the pot
    // treasury fee is set at 1%
    uint256 public treasuryFee = 10;
    // operating cost is set at 1%
    uint256 public operationsFee = 10;
    uint256 public percentDenominator = 1000;

    // modifier to check if caller is the game creator
    modifier onlyContestCreator(uint256 contestId) {
        Contest memory contest = contests[contestId];
        require(msg.sender == contest.creator, "Caller is not contest creator");
        _;
    }

    ////////////////////////////////////
    ///////////    EVENTS    ///////////
    ////////////////////////////////////
    event ContestCreated(uint256 contestId); // someone made a new contest
    event RandomValuesReceived(uint256 contestId); // chainlink provided random values for assinging rows and cols
    event ScoresAssigned(uint256 contestId); // rows and cols were assigned values via the random values from chainlink
    event ScoresRequested(uint256 contestId); // someone requested random numbers for their rows and cols

    ////////////////////////////////////////////////
    ///////////   CHAINLINK VARIABLES    ///////////
    ////////////////////////////////////////////////

    // VRF Coordinator
    VRFCoordinatorV2Interface COORDINATOR;

    // Your subscription ID.
    uint64 s_subscriptionId;

    // VRF coordinator
    address private immutable vrfCoordinator;

    // The gas lane to use, which specifies the maximum gas price to bump to.
    bytes32 private immutable keyHash;

    // Gas For VRF Trigger
    uint32 public vrfGas = 200_000;

    // the request for randomly assigning scores to rows and cols
    // vrf request => contestId
    mapping (uint256 => uint256) private vrfScoreAssignments;

    constructor(
        uint64 subscriptionId, 
        address vrfCoordinator_,
        bytes32 keyHash_,
        address treasury_,
        address operationsWallet_
    ) VRFConsumerBaseV2(vrfCoordinator_) {
        // setup chainlink
        keyHash = keyHash_;
        vrfCoordinator = vrfCoordinator_;
        COORDINATOR = VRFCoordinatorV2Interface(vrfCoordinator_);
        s_subscriptionId = subscriptionId;

        // treasury
        treasury = treasury_;

        // operationsWallet
        operationsWallet = operationsWallet_;
    }

    ////////////////////////////////////////////////
    ///////////     OWNER FUNCTIONS      ///////////
    ////////////////////////////////////////////////
    /**
        Sets the oracle used to fetch game data
     */
    function setGameScoreOracle(address gameScoreOracle_) external onlyOwner {
        gameScoreOracle = IGameScoreOracle(gameScoreOracle_);
    }

    /**
        Sets Gas Limits for VRF Callback
     */
    function setGasLimits(uint32 vrfGas_) external onlyOwner {
        vrfGas = vrfGas_;
    }

    /**
        Sets Subscription ID for VRF Callback
     */
    function setSubscriptionId(uint64 subscriptionId_) external onlyOwner {
       s_subscriptionId = subscriptionId_;
    }

    /**
        Sets The Address Of The Treasury
        @param treasury_ treasury address - cannot be 0
     */
    function setTreasury(address treasury_) external onlyOwner {
        require(
            treasury_ != address(0),
            'Zero Address'
        );
        treasury = treasury_;
    }

    /**
        Sets The Address Of The Operations Wallet
        @param operationsWallet_ operations wallet address - cannot be 0
     */
    function setOperationsWallet(address operationsWallet_) external onlyOwner {
        require(
            operationsWallet_ != address(0),
            'Zero Address'
        );
        operationsWallet = operationsWallet_;
    }

    /**
        Sets the time delay before data can be fetched for a specific game again
     */
    function setFetchDataTimeDelay(uint256 minutes_) external onlyOwner {
        MINUTES_TO_DELAY_FETCH = minutes_ * 60;
    }

    ////////////////////////////////////////////////
    ////////  CONTEST CREATOR FUNCTIONS  ///////////
    ////////////////////////////////////////////////
    /**
        Request randomness to assign numbers to rows and cols
        The contest creator can call this before all boxes are claimed
        however _fetchRandomValues will be called automatically by the 
        user who claims the last box. Calling this prevents future boxes
        from being claimed.
     */
    function fetchRandomValues(uint256 _contestId) external onlyContestCreator(_contestId) {
        _fetchRandomValues(_contestId);
    }

    ////////////////////////////////////////////////
    ///////////    PUBLIC FUNCTIONS      ///////////
    ////////////////////////////////////////////////

    /**
        Create a new contest
     */
    function createContest(uint256 gameId, uint256 boxCost) external {
        // require that the contest has a game id and box cost
        require(gameId > 0, "Game ID not set");
        require(boxCost > 0, "Box cost not set");
        // create the contest struct
        Contest memory contest = Contest(
            contestIdCounter, // the id of the contest
            gameId, // the game that this contest is tied to
            msg.sender, // sender is the creator
            defaultScores, // default rows
            defaultScores, // default cols
            boxCost, // the cost to claim each box
            true, // boxes can be claimed
            false, // rewards cannot be claimed yet
            false, // no q1 payout
            false, // no q2 payout
            false, // no q3 payout
            false, // no rewards claimed
            0, // total amount collected for the contest
            0, // no boxes have been claimed yet
            new uint [](2), // holds random values to be used when assigning values to rows and cols
            false // chainlink has not yet given us random values for row and col values
        );
        // save this to the list of contests
        contests[contestIdCounter] = contest;
        // add this to the list of contests created by the user
        contestsByUser[msg.sender].push(contestIdCounter);
        // emit event
        emit ContestCreated(contestIdCounter);
        // increment for the next contest that gets created
        ++contestIdCounter;
    }

    /**
        Claim boxes
     */
    function claimBoxes(uint256 contestId, uint256[] memory boxIds) external payable {
        // fetch the contest
        Contest memory contest = contests[contestId];
        // check to make sure that the contest still allows for boxes to be claimed
        require(contest.boxesCanBeClaimed == true, "Boxes cannot be claimed");
        // determine cost based on number of boxes to claim
        uint256 numBoxesToClaim = boxIds.length;
        uint256 totalCost = contest.boxCost * numBoxesToClaim;
        // check to make sure that they sent enough ETH to buy the boxes
        require(totalCost <= msg.value, "Insufficient payment");
        // claim the boxes
        for (uint i = 0; i < numBoxesToClaim;) {
            // boxes that are claimed must exist within the 10x10 grid
            require(i < NUM_BOXES_IN_CONTEST, "Box is outside of the grid");
            // the box that the user wants to claim
            uint256 targetBoxId = boxIds[i];
            Box memory targetBox = boxes[contestId][targetBoxId];
            // check to make sure the box they are trying to claim isnt already claimed
            require (targetBox.owner == address(0), "Box already claimed");
            // claim the box
            Box memory claimedBox = Box(targetBoxId, contestId, msg.sender);
            boxes[contestId][targetBoxId] = claimedBox;
            // store this as a box that the user owns
            boxesByUser[msg.sender].push(claimedBox);
            // iterate through the loop
            unchecked{ ++i; }
        }
        // increase the number of boxes claimed in this game
        contest.boxesClaimed += numBoxesToClaim;
        // increase the total amount in the contest by the total amount purchased by this user
        contest.totalRewards += totalCost;
        // set the contest changes in state
        contests[contestId] = contest;
        // add this as a contest where the user owns a box if not already set
        contestsWithUser[msg.sender].push(contestId);
        // if this is the final box claimed, assign the scores of rows and cols randomly
        if (contest.boxesClaimed == NUM_BOXES_IN_CONTEST) {
            _fetchRandomValues(contestId);
        }

        // refund any excess ETH that was sent
        if (msg.value > totalCost) {
            _sendEth(msg.sender, msg.value - totalCost);
        }
    }

    function randomlyAssignRowAndColValues (uint256 contestId) external {
        // fetch the contest
        Contest memory contest = contests[contestId];
        // make sure there are random values for this contest that can be used
        require(contest.randomValuesSet == true, "Random values not yet available");
        // make sure someone did not already assign values for this contest
        require(contest.rewardsCanBeClaimed == false, "Random values already assigned");
        // randomly assign scores to the rows and cols
        contest.rows = _shuffleScores(contest.randomValues[0]);
        contest.cols = _shuffleScores(contest.randomValues[1]);
        // this flag allows for boxes to be claimed and prevents future box value assignments
        contest.rewardsCanBeClaimed = true;
        // save the contest
        contests[contestId] = contest;
        // emit the event
        emit ScoresAssigned(contest.id);
    } 

    /**
        Claim reward
     */
    function claimReward(uint256 contestId, uint256 boxId) external {
        // fetch the contest
        Contest memory contest = contests[contestId];
        // check to make sure that the contest rewards are able to be claimed
        require(contest.rewardsCanBeClaimed == true, "Rewards cannot be claimed until boxes have random scores");
        // check to make sure that the user actually owns a box in this game
        require(_userOwnsBoxInContest(msg.sender, contestId), "You must own a box to claim rewards");
        // get the scores assigned to the boxes
        (uint rowScore, uint colScore) = _fetchBoxScores(contest, boxId);
        // fetch the game scores
        GameScore memory gameScores = _fetchGameScores(contest.gameId);
        // calculate the total reward
        uint256 userReward;
        // check q1
        if (!contest.q1Paid && gameScores.qComplete > 1 && gameScores.awayQ1LastDigit == rowScore && gameScores.homeQ1LastDigit == colScore) {
            userReward += contest.totalRewards * q1Payout / percentDenominator;
            contest.q1Paid = true;
        }
        // check q2
        if (!contest.q2Paid && gameScores.qComplete > 2 && gameScores.awayQ2LastDigit == rowScore && gameScores.homeQ2LastDigit == colScore) {
            userReward += contest.totalRewards * q2Payout / percentDenominator;
            contest.q2Paid = true;
        }
        // check q3
        if (!contest.q3Paid && gameScores.qComplete > 3 && gameScores.awayQ3LastDigit == rowScore && gameScores.homeQ3LastDigit == colScore) {
            userReward += contest.totalRewards * q3Payout / percentDenominator;
            contest.q3Paid = true;
        }
        // check final
        if (!contest.finalPaid && gameScores.qComplete > 99 && gameScores.awayFLastDigit == rowScore && gameScores.homeFLastDigit == colScore) {
            userReward += contest.totalRewards * finalPayout / percentDenominator;
            contest.finalPaid = true;
            // send the treasury and operating fee when the final score is paid out
            _sendTreasuryFee(contest.totalRewards);
            _sendOperationsFee(contest.totalRewards);
        }
        // set the contest
        contests[contestId] = contest;
        // send the reward to the box owner
        if (userReward > 0) {
            _sendReward(boxes[contestId][boxId].owner, userReward);
        }
    }

    /**
        Get fresh real-world game data from our oracle for a specific game ID
     */
    function fetchGameData (uint256 _gameId) external {
        // require that the data for this game has not been fetched recently (as determined by MINUTES_TO_DELAY_FETCH)
        require(block.timestamp >= timeUntilNextFetchAllowed[_gameId], "Time delay not met");
        // set the new delay threshold
        timeUntilNextFetchAllowed[_gameId] = block.timestamp + MINUTES_TO_DELAY_FETCH;
        // fetch the game data from the oracle
        gameScoreOracle.requestValues(_gameId);
    }

    ////////////////////////////////////////////////
    ///////////   INTERNAL FUNCTIONS     ///////////
    ////////////////////////////////////////////////
    /**
        Reach out to chainlink to request random values for a contests rows and cols
     */
    function _fetchRandomValues (uint256 _contestId) internal {
        // fetch the contest
        Contest memory contest = contests[_contestId];
        // do not allow for another chainlink request if one has already been made
        require(contest.randomValuesSet == false, "Random values already fetched");
        // fetch 2 random numbers from chainlink
        // one for rows, and one for cols
        uint256 requestId = COORDINATOR.requestRandomWords(
            keyHash,
            s_subscriptionId,
            20, // number of block confirmations before returning random value
            vrfGas, // callback gas limit is dependent num of random values & gas used in callback
            2 // the number of random results to return
        );
        // store this request to be looked up later when the randomness is fulfilled
        vrfScoreAssignments[requestId] = _contestId;
        // update the contest so that boxes cannot be claimed anymore
        // we update this here instead of the fulfill so that nobody can front run
        // claiming box after the randomness of the rows and cols were determined
        contest.boxesCanBeClaimed = false;
        contests[_contestId] = contest;
        // emit event that the boxes were requested to be assigned scores
        emit ScoresRequested(_contestId);
    }

    /**
        Returns the scores of a real-world game from the game scores oracle
     */
    function _fetchGameScores (uint256 _gameId) internal view returns (GameScore memory) {
        (uint8 homeQ1LastDigit, uint8 homeQ2LastDigit, uint8 homeQ3LastDigit, uint8 homeFLastDigit, 
            uint8 awayQ1LastDigit, uint8 awayQ2LastDigit, uint8 awayQ3LastDigit, uint8 awayFLastDigit, 
            uint8 qComplete, bool requestInProgress
        ) = gameScoreOracle.fetchGameScores(_gameId);

        return GameScore(
            _gameId,
            homeQ1LastDigit,
            homeQ2LastDigit,
            homeQ3LastDigit,
            homeFLastDigit,
            awayQ1LastDigit,
            awayQ2LastDigit,
            awayQ3LastDigit,
            awayFLastDigit,
            qComplete,
            requestInProgress
        );
    }

    /**
        Returns true if the user owns a box in the given contest
     */
    function _userOwnsBoxInContest (address user, uint256 contestId) internal view returns (bool) {
        // default to return false
        bool userOwnsBoxInGame = false;
        // store length of array in memory for gas efficiency
        uint256 length = contestsWithUser[user].length;
        // find if this contest is one where the user owns a box
        for (uint i=0; i < length; i++) {
            if (contestId == contestsWithUser[user][i]) {
                userOwnsBoxInGame = true;
                break;
            }
        }
        return userOwnsBoxInGame;
    }

    /**
        Send ETH to the treasury account based on the treasury fee amount
     */
    function _sendTreasuryFee (uint256 totalRewards) internal {
        _sendEth(treasury, totalRewards * treasuryFee / percentDenominator);
    }

    /**
        Send ETH to the operations wallet based on the operating fee amount
     */
    function _sendOperationsFee (uint256 totalRewards) internal {
        _sendEth(operationsWallet, totalRewards * operationsFee / percentDenominator);
    }

    /**
        Send ETH to the treasury account based on the treasury fee amount
     */
    function _sendReward(address winner, uint256 amount) internal {
        // if nobody claimed this box, send half of the reward to the treasury and the other half to the user who executed this
        // otherwise send the total winnings to the winner
        if (winner == address(0)) {
            _sendEth(treasury, amount / 2);
            _sendEth(msg.sender, amount / 2);
        } else {
            _sendEth(winner, amount);
        }
    }

    /**
        Given an address and amount, send the amount in ETH to the address
     */
    function _sendEth (address to, uint256 amount) internal {
        (bool sent,) = payable(to).call{ value: amount }("");
        require(sent, "Failed to send ETH");
    }

    /**
        Given a contestId and boxId, return the assigned scores for the box's row and col position
     */
    function _fetchBoxScores(
        Contest memory contest, uint256 boxId
    ) internal pure returns(uint256 rowScore, uint256 colScore) {
        // get the row and col positions of the box
        uint colPosition = boxId % 10; // box 45 becomes 5.
        uint rowPosition = (boxId - colPosition) * 100 / 1000; // 92 - 2 = 90. 90 * 100 = 9000. 9000 / 1000 = 9th row
        // get the scores of the box
        // .cols and .rows look like they are in the wrong place but they are correct
        rowScore = contest.cols[rowPosition];
        colScore = contest.rows[colPosition];
        return (rowScore, colScore);
    }

    /**
        Chainlink's callback to provide us with randomness
     */
    function fulfillRandomWords(
        uint256 requestId, /* requestId */
        uint256[] memory randomWords
    ) internal override {
        // the contest id that made this request
        uint256 contestId = vrfScoreAssignments[requestId];
        // fetch the contest object from the id
        Contest memory contest = contests[contestId];
        // set the random values of the contest
        contest.randomValues = randomWords;
        // flag that chainlink has provided this contest with random values
        contest.randomValuesSet = true;
        // save the contest
        contests[contestId] = contest;
        // emit an event
        emit RandomValuesReceived(contest.id);
    }

    /**
        Randomly shuffle array of scores
     */
    function _shuffleScores(
        uint256 randomNumber
    ) internal view returns(uint[] memory shuffledScores) {
        // set shuffled scores to the default
        shuffledScores = defaultScores;
        // randomly shuffle the array of scores
        for (uint i = 0; i < 10;) {
            uint256 n = i + uint256(keccak256(abi.encodePacked(randomNumber))) % (10 - i);
            uint256 temp = shuffledScores[n];
            shuffledScores[n] = shuffledScores[i];
            shuffledScores[i] = temp;
            unchecked{ ++i; }
        }
        // return the shuffled array
        return shuffledScores;
    }

    ////////////////////////////////////////////////
    ///////////      READ FUNCTIONS      ///////////
    ////////////////////////////////////////////////
    /**
        Read all contests created by the user
     */
    function fetchAllContestsByUser(address user) external view returns (uint[] memory) {
        return contestsByUser[user];
    }

    /**
        Read all contests with owned boxes by user
     */
    function fetchAllContestsWithUser(address user) external view returns (uint[] memory) {
        return contestsWithUser[user];
    }

    /**
        Read all boxes by the contest
     */
    function fetchAllBoxesByContest(uint256 contestId) external view returns (Box[] memory) {
        Box[] memory contestBoxes = new Box[](NUM_BOXES_IN_CONTEST);
        // fetch the boxes
        for (uint i = 0; i < NUM_BOXES_IN_CONTEST;) {
            Box storage box = boxes[contestId][i];
            contestBoxes[i] = box;
            unchecked{ ++i; }
        }
        return contestBoxes;
    }

    /**
        Read all boxes claimed by the user
     */
    function fetchAllBoxesByUser(address user) external view returns (Box[] memory) {
        return boxesByUser[user];
    }

    /**
        Read the scores of the rows of a contest
     */
    function fetchContestRows(uint256 contestId) external view returns (uint[] memory) {
        // fetch the contest object from the id
        Contest memory contest = contests[contestId];
        return (contest.rows);
    }

    /**
        Read the scores of the cols of a contest
     */
    function fetchContestCols(uint256 contestId) external view returns (uint[] memory) {
        // fetch the contest object from the id
        Contest memory contest = contests[contestId];
        return (contest.cols);
    }
}