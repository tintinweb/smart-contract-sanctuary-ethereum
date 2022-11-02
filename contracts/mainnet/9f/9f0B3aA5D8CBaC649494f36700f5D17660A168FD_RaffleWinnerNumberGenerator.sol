// SPDX-License-Identifier: MIT
pragma solidity >=0.8;

import "./RaffleOperator.sol";
import "./VRFConsumerBaseV2.sol";

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
     * @return requestId - A unique identifier of the request. Can be used to match
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
    function requestSubscriptionOwnerTransfer(uint64 subId, address newOwner)
        external;

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

    /*
     * @notice Check to see if there exists a request commitment consumers
     * for all consumers and keyhashes for a given sub.
     * @param subId - ID of the subscription
     * @return true if there exists at least one unfulfilled request for the subscription, false
     * otherwise.
     */
    function pendingRequestExists(uint64 subId) external view returns (bool);
}

contract RaffleWinnerNumberGenerator is VRFConsumerBaseV2 {
    mapping(uint256 => address) private rafflesHistory;
    mapping(address => uint256) public rafflesResults;
    mapping(address => uint256[]) private rafflesPlayerNumbers;
    uint256 public constant RAFFLE_IN_PROGRESS = 3200000;
    uint64 s_subscriptionId;

    VRFCoordinatorV2Interface COORDINATOR;
    error Unauthorized();

    address s_owner;
    uint32 numWords = 1;
    uint16 requestConfirmations = 3;
    uint32 callbackGasLimit = 40000;
    uint32 limitOfRequestedNumber;
    address vrfCoordinator = 0x271682DEB8C4E0901D1a1550aD2e64D568E69909;
    bytes32 s_keyHash =
        0xff8dedfbfa60af186cf3c830acbc32c05aae823045ae5ea7da1e45fbfaba4f92;

    event RaffleLaunched(
        uint256 indexed requestId,
        address indexed raffleOperatorAddress
    );
    event RaffleLanded(
        uint256 indexed requestId,
        address indexed raffleOperatorAddress,
        uint256 indexed result
    );

    modifier onlyOwner() {
        require(msg.sender == s_owner, "You are not the owner");
        _;
    }

    modifier onlyIfRaffleRunning(address _raffleOperator) {
        bool isRaffleRunning = RaffleOperator(_raffleOperator).running();
        require(isRaffleRunning == true, "Raffle was finished");
        _;
    }

    constructor(address raffleManager, uint64 subscriptionId)
        VRFConsumerBaseV2(vrfCoordinator)
    {
        COORDINATOR = VRFCoordinatorV2Interface(vrfCoordinator);
        s_owner = raffleManager;
        s_subscriptionId = subscriptionId;
    }

    function getPlayerNumbers(address _raffleOperator)
        external
        view
        returns (uint256[] memory _currentRafflePlayerNumbers)
    {
        return rafflesPlayerNumbers[_raffleOperator];
    }

    function getRaffleWinnerNumber(address _raffleOperator)
        public
        view
        onlyOwner
        returns (uint256 _raffleWinnerNumber)
    {
        require(rafflesResults[_raffleOperator] != 0, "Raffle not subscribed");

        if (rafflesResults[_raffleOperator] == RAFFLE_IN_PROGRESS) {
            return RAFFLE_IN_PROGRESS;
        }

        return rafflesResults[_raffleOperator];
    }

    function setNewRafflePlayingSpot(
        address _raffleOperator,
        uint256 _playerNumber
    ) public returns (bool _success) {
        if (msg.sender != _raffleOperator) revert Unauthorized();

        rafflesPlayerNumbers[_raffleOperator].push(_playerNumber);
        return true;
    }

    function restartRaffle(address _raffleOperator)
        public
        onlyOwner
        returns (bool _raffleRestarted)
    {
        require(
            rafflesResults[_raffleOperator] != RAFFLE_IN_PROGRESS,
            "Raffle in progress"
        );
        rafflesResults[_raffleOperator] = 0;
        return true;
    }

    function launchRaffle(address _raffleOperator)
        public
        onlyOwner
        onlyIfRaffleRunning(_raffleOperator)
        returns (uint256 requestId)
    {
        require(rafflesResults[_raffleOperator] == 0, "Already drawn");
        // Will revert if subscription is not set and funded.

        RaffleOperator(_raffleOperator).setDateOfTheLaunch();
        requestId = COORDINATOR.requestRandomWords(
            s_keyHash,
            s_subscriptionId,
            requestConfirmations,
            callbackGasLimit,
            numWords
        );

        limitOfRequestedNumber = uint32(
            rafflesPlayerNumbers[_raffleOperator].length
        );
        rafflesHistory[requestId] = _raffleOperator;
        rafflesResults[_raffleOperator] = RAFFLE_IN_PROGRESS;

        emit RaffleLaunched(requestId, _raffleOperator);
    }

    function fulfillRandomWords(
        uint256 requestId,
        uint256[] memory randomNumbers
    ) internal override {
        uint256 positionOfWinnerNumber = (randomNumbers[0] %
            limitOfRequestedNumber) + 1;
        uint256 winnerNumber = rafflesPlayerNumbers[rafflesHistory[requestId]][
            positionOfWinnerNumber - 1
        ]; // Because zero counts
        rafflesResults[rafflesHistory[requestId]] = winnerNumber;
    }
}