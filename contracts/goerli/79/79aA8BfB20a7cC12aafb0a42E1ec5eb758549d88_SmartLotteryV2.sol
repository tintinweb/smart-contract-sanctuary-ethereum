// SPDX-License-Identifier: MIT

pragma solidity ^0.8.17;

import "@chainlink/contracts/src/v0.8/interfaces/VRFCoordinatorV2Interface.sol";
import "@chainlink/contracts/src/v0.8/VRFConsumerBaseV2.sol";
import "@chainlink/contracts/src/v0.8/interfaces/KeeperCompatibleInterface.sol";
import "@chainlink/contracts/src/v0.8/interfaces/AggregatorV3Interface.sol";
import "@openzeppelin/contracts/utils/Strings.sol";

error SmartLotteryV2__PrizeDistributionNotOneHundredPercent();
error SmartLotteryV2__LotteryNotOpen();
error SmartLotteryV2__TooManyTickets();
error SmartLotteryV2__NotEnoughFunds();
error SmartLotteryV2__UpkeepNotNeeded(
    uint256 currentBalance,
    uint256 numPlayers,
    uint256 lotteryState
);
error SmartLotteryV2__NonExistingLottery();
error SmartLotteryV2__ExternalCallFailed();
error SmartLotteryV2__NoPendingRewards();

/**
 * @title SmartLotteryV2
 * @author jrmunchkin
 * @notice This contract creates a ticket lottery which will picked a random winning ticket once the lottery end.
 * The player must buy tickets to play the lottery, he also must pay fee everytime buying a ticket.
 * The lottery works like so :
 * - The pot is divided into 4 pools. The size of each pool is based on a percentage set in the constructor.
 * - Everytime the user buy a ticket he get 4 random numbers. Maximum buying ticket : 10 per user per lottery.
 * - If the user has a ticket with the first number matching the winning ticket he win the smallest pool.
 * - If the user has a ticket with the two first number matching the winning ticket he win the second pool.
 * - If the user has a ticket with the third first number matching the winning ticket he win the third pool.
 * - If the user has a ticket with the fourth number matching the winning ticket he win the biggest pool.
 * - Each pool is also divided by the number of user who win it.
 * @dev The constructor takes an interval (time of duration of the lottery), an usd entrance fee (entrance fee in dollars)
 * and a prize distribution corresponding on the percentage of each pools.
 * This contract implements Chainlink Keeper to trigger when the lottery must end.
 * This contract implements Chainlink VRF to pick a random winning ticket when the lottery ends.
 * This contract also implements the Chainlink price feed to know the ticket fee value in ETH.
 */
contract SmartLotteryV2 is VRFConsumerBaseV2, KeeperCompatibleInterface {
    enum LotteryState {
        OPEN,
        DRAW_WINNING_TICKET
    }

    VRFCoordinatorV2Interface private immutable i_vrfCoordinator;
    AggregatorV3Interface private immutable i_ethUsdPriceFeed;
    uint64 private immutable i_subscriptionId;
    bytes32 private immutable i_gasLane;
    uint32 private immutable i_callbackGasLimit;
    uint256 private immutable i_usdTicketFee;
    uint256 private immutable i_interval;
    uint16 private constant REQUEST_CONFIRMATIONS = 3;
    uint32 private constant NUM_WORDS = 4;
    uint256 private constant MAX_BUYING_TICKET = 10;
    LotteryState private s_lotteryState;
    uint256 private s_lotteryNumber;
    uint256 private s_randNonce;
    address[] private s_players;
    uint256 private s_startTimestamp;
    uint256[NUM_WORDS] private s_prizeDistribution;

    mapping(uint256 => uint256) private s_lotteryBalance;
    mapping(uint256 => mapping(string => uint256))
        private s_numberOfCombination;
    mapping(uint256 => mapping(address => uint256[NUM_WORDS][]))
        private s_playerTickets;
    mapping(uint256 => uint256[NUM_WORDS]) private s_winningTicket;

    event StartLottery(uint256 indexed lotteryNumber, uint256 startTime);
    event EnterLottery(uint256 indexed lotteryNumber, address indexed player);
    event EmitTicket(
        uint256 indexed lotteryNumber,
        address indexed player,
        uint256[NUM_WORDS] ticket
    );
    event RequestLotteryWinningTicket(
        uint256 indexed lotteryNumber,
        uint256 indexed requestId
    );
    event WinningTicketLotteryPicked(
        uint256 indexed lotteryNumber,
        uint256[NUM_WORDS] ticket
    );
    event WinningTicketPlayer(
        uint256 indexed lotteryNumber,
        address indexed player,
        uint256[NUM_WORDS] ticket,
        uint256 nbMatching
    );
    event ClaimLotteryRewards(
        uint256 indexed lotteryNumber,
        address indexed winner,
        uint256 amount
    );

    /**
     * @notice contructor
     * @param _vrfCoordinatorV2 VRF Coordinator contract address
     * @param _subscriptionId Subscription Id of Chainlink VRF
     * @param _gasLane Gas lane of Chainlink VRF
     * @param _callbackGasLimit Callback gas limit of Chainlink VRF
     * @param _ethUsdPriceFeed Price feed address ETH to USD
     * @param _usdTicketFee Ticket fee value in dollars
     * @param _interval Duration of the lottery
     * @param _prizeDistribution Array of prize distribution of each pool (the smallest first, total must be 100%)
     */
    constructor(
        address _vrfCoordinatorV2,
        uint64 _subscriptionId,
        bytes32 _gasLane,
        uint32 _callbackGasLimit,
        address _ethUsdPriceFeed,
        uint256 _usdTicketFee,
        uint256 _interval,
        uint256[NUM_WORDS] memory _prizeDistribution
    ) VRFConsumerBaseV2(_vrfCoordinatorV2) {
        uint256 prizeDistributionTotal = 0;
        for (
            uint256 prizeDistributionIndex = 0;
            prizeDistributionIndex < _prizeDistribution.length;
            prizeDistributionIndex++
        ) {
            prizeDistributionTotal =
                prizeDistributionTotal +
                uint256(_prizeDistribution[prizeDistributionIndex]);
        }
        if (prizeDistributionTotal != 100)
            revert SmartLotteryV2__PrizeDistributionNotOneHundredPercent();
        i_vrfCoordinator = VRFCoordinatorV2Interface(_vrfCoordinatorV2);
        i_subscriptionId = _subscriptionId;
        i_gasLane = _gasLane;
        i_callbackGasLimit = _callbackGasLimit;
        i_ethUsdPriceFeed = AggregatorV3Interface(_ethUsdPriceFeed);
        i_usdTicketFee = _usdTicketFee * (10 ** 18);
        i_interval = _interval;
        s_lotteryNumber = 1;
        s_randNonce = 0;
        s_prizeDistribution = _prizeDistribution;
        s_lotteryState = LotteryState.OPEN;
    }

    /**
     * @notice Allow user to buy tickets to enter the lottery by paying ticket fee
     * @param _numberOfTickets The number of ticket the user want to buy
     * @dev When the first player enter the lottery the duration start
     * emit an event EnterLottery when player enter the lottery
     * emit an event EmitTicket for each ticket the player buys
     * emit an event StartLottery the lottery duration start
     */
    function buyTickets(uint256 _numberOfTickets) external payable {
        if (s_lotteryState != LotteryState.OPEN)
            revert SmartLotteryV2__LotteryNotOpen();
        if (
            s_playerTickets[s_lotteryNumber][msg.sender].length +
                _numberOfTickets >
            MAX_BUYING_TICKET
        ) revert SmartLotteryV2__TooManyTickets();
        if (msg.value < getTicketFee() * _numberOfTickets)
            revert SmartLotteryV2__NotEnoughFunds();
        if (!isPlayerAlreadyInLottery(msg.sender)) s_players.push(msg.sender);
        if (s_players.length == 1) {
            s_startTimestamp = block.timestamp;
            emit StartLottery(s_lotteryNumber, s_startTimestamp);
        }
        for (
            uint256 ticketIndex = 0;
            ticketIndex < _numberOfTickets;
            ticketIndex++
        ) {
            uint256[NUM_WORDS] memory ticket = [
                getRandomNumber(),
                getRandomNumber(),
                getRandomNumber(),
                getRandomNumber()
            ];
            s_playerTickets[s_lotteryNumber][msg.sender].push(ticket);
            setNumberOfCombinations(s_lotteryNumber, ticket);
            emit EmitTicket(s_lotteryNumber, msg.sender, ticket);
        }
        s_lotteryBalance[s_lotteryNumber] += msg.value;
        emit EnterLottery(s_lotteryNumber, msg.sender);
    }

    /**
     * @notice Chainlink checkUpkeep which will check if lottery must end
     * @return upkeepNeeded boolean to know if Chainlink must perform upkeep
     * @dev Lottery end when all this assertions are true :
     * The lottery is open
     * The lottery have at least one player
     * The lottery have some balance
     * The lottery duration is over
     */
    function checkUpkeep(
        bytes memory /* _checkData */
    )
        public
        view
        override
        returns (bool upkeepNeeded, bytes memory /* performData */)
    {
        bool isOpen = s_lotteryState == LotteryState.OPEN;
        bool timePassed = ((block.timestamp - s_startTimestamp) > i_interval);
        bool hasPlayers = s_players.length > 0;
        bool hasBalance = s_lotteryBalance[s_lotteryNumber] > 0;
        upkeepNeeded = isOpen && timePassed && hasPlayers && hasBalance;
        return (upkeepNeeded, "0x0");
    }

    /**
     * @notice Chainlink performUpkeep which will end the lottery
     * @dev This function is call if upkeepNeeded of checkUpkeep is true
     * Call Chainlink VRF to request a random winning ticket
     * emit an event RequestLotteryWinningTicket when request winning ticket is called
     */
    function performUpkeep(
        bytes calldata /* _performData */
    ) external override {
        (bool upkeepNeeded, ) = checkUpkeep("");
        if (!upkeepNeeded) {
            revert SmartLotteryV2__UpkeepNotNeeded(
                s_lotteryBalance[s_lotteryNumber],
                s_players.length,
                uint256(s_lotteryState)
            );
        }
        s_lotteryState = LotteryState.DRAW_WINNING_TICKET;
        uint256 requestId = i_vrfCoordinator.requestRandomWords(
            i_gasLane,
            i_subscriptionId,
            REQUEST_CONFIRMATIONS,
            i_callbackGasLimit,
            NUM_WORDS
        );
        emit RequestLotteryWinningTicket(s_lotteryNumber, requestId);
    }

    /**
     * @notice Picked a random winning ticket and restart lottery
     * @dev Call by the Chainlink VRF after requesting a random winning ticket
     * emit an event WinningTicketLotteryPicked when random winning ticket has been picked
     */
    function fulfillRandomWords(
        uint256 /*_requestId*/,
        uint256[] memory _randomWords
    ) internal override {
        uint256[NUM_WORDS] memory winningTicket = [
            _randomWords[0] % 10,
            _randomWords[1] % 10,
            _randomWords[2] % 10,
            _randomWords[3] % 10
        ];
        s_winningTicket[s_lotteryNumber] = winningTicket;
        postponeLotteryBalance();
        s_players = new address[](0);
        s_lotteryState = LotteryState.OPEN;
        s_lotteryNumber++;
        emit WinningTicketLotteryPicked(s_lotteryNumber - 1, winningTicket);
    }

    /**
     * @notice Allow user to claim his lottery rewards for a specific lottery
     * @param _lotteryNumber The number of the lottery
     * emit an event WinningTicketPlayer for each winning ticket of the user
     * emit an event ClaimLotteryRewards when user claimed his rewards
     */
    function claimRewards(uint256 _lotteryNumber) external {
        if (_lotteryNumber < 1 || _lotteryNumber >= s_lotteryNumber)
            revert SmartLotteryV2__NonExistingLottery();
        uint256 totalRewards = 0;

        uint256[NUM_WORDS] memory winningTicket = s_winningTicket[
            _lotteryNumber
        ];
        for (
            uint256 ticketIndex = 0;
            ticketIndex < s_playerTickets[_lotteryNumber][msg.sender].length;
            ticketIndex++
        ) {
            uint256[NUM_WORDS] memory ticket = s_playerTickets[_lotteryNumber][
                msg.sender
            ][ticketIndex];
            uint256 nbMatching = getNumberOfMatching(ticket, winningTicket);
            uint256 nbCombination = getNumberOfCombinations(
                _lotteryNumber,
                nbMatching,
                ticket
            );
            totalRewards =
                totalRewards +
                getPrizeForMatching(_lotteryNumber, nbMatching, nbCombination);
            delete s_playerTickets[_lotteryNumber][msg.sender][ticketIndex];
            emit WinningTicketPlayer(
                _lotteryNumber,
                msg.sender,
                ticket,
                nbMatching
            );
        }
        if (totalRewards <= 0) revert SmartLotteryV2__NoPendingRewards();
        (bool success, ) = msg.sender.call{value: totalRewards}("");
        if (!success) revert SmartLotteryV2__ExternalCallFailed();
        emit ClaimLotteryRewards(_lotteryNumber, msg.sender, totalRewards);
    }

    /**
     * @notice Set the combinations for a specific ticket
     * @param _lotteryNumber The lottery number
     * @param _ticket The ticket
     * @dev This function aim to set how many times a combination appear on the same lottery
     * The purpose is to calulate at the end between how many user the pool need to be shared
     */
    function setNumberOfCombinations(
        uint256 _lotteryNumber,
        uint256[NUM_WORDS] memory _ticket
    ) internal {
        string memory combination = "";
        for (
            uint256 numberIndex = 0;
            numberIndex < _ticket.length;
            numberIndex++
        ) {
            combination = string(
                abi.encodePacked(
                    combination,
                    Strings.toString(uint256(_ticket[numberIndex]))
                )
            );
            s_numberOfCombination[_lotteryNumber][combination]++;
        }
    }

    /**
     * @notice Return a random number between 0 and 9
     * @return randomNumber Random number
     * @dev It's not a secure method to pick random number but as it's just to assign a ticket this method is chosen
     */
    function getRandomNumber() internal returns (uint256) {
        s_randNonce++;
        return
            uint256(
                keccak256(
                    abi.encodePacked(block.timestamp, msg.sender, s_randNonce)
                )
            ) % 10;
    }

    /**
     * @notice Postpone the lottery pools which don't have any winners to the next lottery
     */
    function postponeLotteryBalance() internal {
        for (uint256 numberIndex = 1; numberIndex <= NUM_WORDS; numberIndex++) {
            uint256 numberOfCombination = getNumberOfCombinations(
                s_lotteryNumber,
                numberIndex,
                s_winningTicket[s_lotteryNumber]
            );
            if (numberOfCombination == 0) {
                uint256 poolDistribution = s_prizeDistribution[numberIndex - 1];
                uint256 prize = (s_lotteryBalance[s_lotteryNumber] *
                    poolDistribution) / 100;
                s_lotteryBalance[s_lotteryNumber + 1] =
                    s_lotteryBalance[s_lotteryNumber + 1] +
                    prize;
            }
        }
    }

    /**
     * @notice Return the number of matching number between a ticket and a winning ticket
     * @param _ticket The ticket to compare
     * @param _winningTicket The winning ticket
     * @return nbMatching The number of matching numbers
     */
    function getNumberOfMatching(
        uint256[NUM_WORDS] memory _ticket,
        uint256[NUM_WORDS] memory _winningTicket
    ) internal pure returns (uint256) {
        uint256 nbMatching = 0;
        for (
            uint256 numberIndex = 0;
            numberIndex < _ticket.length;
            numberIndex++
        ) {
            if (_ticket[numberIndex] != _winningTicket[numberIndex]) break;
            nbMatching++;
        }
        return nbMatching;
    }

    /**
     * @notice Get the number of combinations for a specific ticket ans its number of matching numbers
     * @param _lotteryNumber The lottery number
     * @param _nbMatching The number of matching numbers
     * @param _ticket The ticket
     * @return numberOfCombination The number of combination
     */
    function getNumberOfCombinations(
        uint256 _lotteryNumber,
        uint256 _nbMatching,
        uint256[NUM_WORDS] memory _ticket
    ) internal view returns (uint256) {
        string memory combination = "";
        for (
            uint256 numberIndex = 0;
            numberIndex < _nbMatching;
            numberIndex++
        ) {
            combination = string(
                abi.encodePacked(
                    combination,
                    Strings.toString(uint256(_ticket[numberIndex]))
                )
            );
        }
        return s_numberOfCombination[_lotteryNumber][combination];
    }

    /**
     * @notice Return the amount a user will get from the number of matching numbers and the number of combinations
     * @param _lotteryNumber The lottery number
     * @param _nbMatching The number of matching numbers
     * @param _nbCombination The number of combination
     * @return prize The prize the user will get
     */
    function getPrizeForMatching(
        uint256 _lotteryNumber,
        uint256 _nbMatching,
        uint256 _nbCombination
    ) internal view returns (uint256) {
        uint256 prize = 0;
        if (_nbMatching == 0) return 0;
        uint256 poolDistribution = s_prizeDistribution[_nbMatching - 1];
        prize = (s_lotteryBalance[_lotteryNumber] * poolDistribution) / 100;
        return prize / _nbCombination;
    }

    /**
     * @notice Check if the user already play the lottery
     * @param _user address of the user
     * @return isPlaying true if already play, false ether
     */
    function isPlayerAlreadyInLottery(
        address _user
    ) internal view returns (bool) {
        for (
            uint256 playersIndex = 0;
            playersIndex < s_players.length;
            playersIndex++
        ) {
            if (s_players[playersIndex] == _user) return true;
        }
        return false;
    }

    /**
     * @notice Get ticket fee to buy a ticket for the lottery
     * @return ticketFee Ticket fee in ETH
     * @dev Implements Chainlink price feed
     */
    function getTicketFee() public view returns (uint256) {
        (, int256 price, , , ) = i_ethUsdPriceFeed.latestRoundData();
        uint256 adjustedPrice = uint256(price) * 10 ** 10;
        return (i_usdTicketFee * 10 ** 18) / adjustedPrice;
    }

    /**
     * @notice Get ticket fee in dollars to participate to the lottery
     * @return usdTicketFee Ticket fee in dollars
     */
    function getUsdTicketFee() external view returns (uint256) {
        return i_usdTicketFee;
    }

    /**
     * @notice Get duration of the lottery
     * @return interval Duration of the lottery
     */
    function getInterval() external view returns (uint256) {
        return i_interval;
    }

    /**
     * @notice Get the prize distribution of the lottery
     * @return prizeDistribution Prize distribution of the lottery
     */
    function getPrizeDistribution()
        external
        view
        returns (uint256[NUM_WORDS] memory)
    {
        return s_prizeDistribution;
    }

    /**
     * @notice Get actual lottery number
     * @return lotteryNumber Actual lottery number
     */
    function getActualLotteryNumber() external view returns (uint256) {
        return s_lotteryNumber;
    }

    /**
     * @notice Get the state of the lottery
     * @return lotteryState Lottery state
     */
    function getLotteryState() external view returns (LotteryState) {
        return s_lotteryState;
    }

    /**
     * @notice Get player address with index
     * @param _index Index of player
     * @return player Player address
     */
    function getPlayer(uint256 _index) external view returns (address) {
        return s_players[_index];
    }

    /**
     * @notice Get the number of players of the lottery
     * @return numPlayers Number of players
     */
    function getNumberOfPlayers() external view returns (uint256) {
        return s_players.length;
    }

    /**
     * @notice Get a specific ticket for the player on the lottery
     * @param _user user address
     * @param _index Index of ticket
     * @return ticket The player ticket
     */
    function getPlayerTicket(
        address _user,
        uint256 _index
    ) external view returns (uint256[NUM_WORDS] memory) {
        return s_playerTickets[s_lotteryNumber][_user][_index];
    }

    /**
     * @notice Get the number of ticket a player own in the lottery
     * @return numTicketPlayer Number of tickets for the player
     */
    function getNumberOfTicketsByPlayer(
        address _user
    ) external view returns (uint256) {
        return s_playerTickets[s_lotteryNumber][_user].length;
    }

    /**
     * @notice Get the number of time a combination appear
     * @return numCombination Number of combination
     */
    function getNumberOfCombination(
        string memory _combination
    ) external view returns (uint256) {
        return s_numberOfCombination[s_lotteryNumber][_combination];
    }

    /**
     * @notice Get the timestamp when the lottery start
     * @return startTimestamp Start timestamp
     */
    function getStartTimestamp() external view returns (uint256) {
        return s_startTimestamp;
    }

    /**
     * @notice Get the value of rewards of the actual lottery
     * @return lotteryBalance Lottery Balance
     */
    function getActualLotteryBalance() external view returns (uint256) {
        return s_lotteryBalance[s_lotteryNumber];
    }

    /**
     * @notice Get the value of rewards of a specific lottery
     * @param _lotteryNumber The number of the lottery
     * @return lotteryBalance Lottery Balance
     */
    function getLotteryBalance(
        uint256 _lotteryNumber
    ) external view returns (uint256) {
        return s_lotteryBalance[_lotteryNumber];
    }

    /**
     * @notice Get the winning ticket of a specific lottery
     * @param _lotteryNumber The number of the lottery
     * @return winningTicket Lottery winning ticket
     */
    function getWinningTicket(
        uint256 _lotteryNumber
    ) external view returns (uint256[NUM_WORDS] memory) {
        return s_winningTicket[_lotteryNumber];
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

/** ****************************************************************************
 * @notice Interface for contracts using VRF randomness
 * *****************************************************************************
 * @dev PURPOSE
 *
 * @dev Reggie the Random Oracle (not his real job) wants to provide randomness
 * @dev to Vera the verifier in such a way that Vera can be sure he's not
 * @dev making his output up to suit himself. Reggie provides Vera a public key
 * @dev to which he knows the secret key. Each time Vera provides a seed to
 * @dev Reggie, he gives back a value which is computed completely
 * @dev deterministically from the seed and the secret key.
 *
 * @dev Reggie provides a proof by which Vera can verify that the output was
 * @dev correctly computed once Reggie tells it to her, but without that proof,
 * @dev the output is indistinguishable to her from a uniform random sample
 * @dev from the output space.
 *
 * @dev The purpose of this contract is to make it easy for unrelated contracts
 * @dev to talk to Vera the verifier about the work Reggie is doing, to provide
 * @dev simple access to a verifiable source of randomness. It ensures 2 things:
 * @dev 1. The fulfillment came from the VRFCoordinator
 * @dev 2. The consumer contract implements fulfillRandomWords.
 * *****************************************************************************
 * @dev USAGE
 *
 * @dev Calling contracts must inherit from VRFConsumerBase, and can
 * @dev initialize VRFConsumerBase's attributes in their constructor as
 * @dev shown:
 *
 * @dev   contract VRFConsumer {
 * @dev     constructor(<other arguments>, address _vrfCoordinator, address _link)
 * @dev       VRFConsumerBase(_vrfCoordinator) public {
 * @dev         <initialization with other arguments goes here>
 * @dev       }
 * @dev   }
 *
 * @dev The oracle will have given you an ID for the VRF keypair they have
 * @dev committed to (let's call it keyHash). Create subscription, fund it
 * @dev and your consumer contract as a consumer of it (see VRFCoordinatorInterface
 * @dev subscription management functions).
 * @dev Call requestRandomWords(keyHash, subId, minimumRequestConfirmations,
 * @dev callbackGasLimit, numWords),
 * @dev see (VRFCoordinatorInterface for a description of the arguments).
 *
 * @dev Once the VRFCoordinator has received and validated the oracle's response
 * @dev to your request, it will call your contract's fulfillRandomWords method.
 *
 * @dev The randomness argument to fulfillRandomWords is a set of random words
 * @dev generated from your requestId and the blockHash of the request.
 *
 * @dev If your contract could have concurrent requests open, you can use the
 * @dev requestId returned from requestRandomWords to track which response is associated
 * @dev with which randomness request.
 * @dev See "SECURITY CONSIDERATIONS" for principles to keep in mind,
 * @dev if your contract could have multiple requests in flight simultaneously.
 *
 * @dev Colliding `requestId`s are cryptographically impossible as long as seeds
 * @dev differ.
 *
 * *****************************************************************************
 * @dev SECURITY CONSIDERATIONS
 *
 * @dev A method with the ability to call your fulfillRandomness method directly
 * @dev could spoof a VRF response with any random value, so it's critical that
 * @dev it cannot be directly called by anything other than this base contract
 * @dev (specifically, by the VRFConsumerBase.rawFulfillRandomness method).
 *
 * @dev For your users to trust that your contract's random behavior is free
 * @dev from malicious interference, it's best if you can write it so that all
 * @dev behaviors implied by a VRF response are executed *during* your
 * @dev fulfillRandomness method. If your contract must store the response (or
 * @dev anything derived from it) and use it later, you must ensure that any
 * @dev user-significant behavior which depends on that stored value cannot be
 * @dev manipulated by a subsequent VRF request.
 *
 * @dev Similarly, both miners and the VRF oracle itself have some influence
 * @dev over the order in which VRF responses appear on the blockchain, so if
 * @dev your contract could have multiple VRF requests in flight simultaneously,
 * @dev you must ensure that the order in which the VRF responses arrive cannot
 * @dev be used to manipulate your contract's user-significant behavior.
 *
 * @dev Since the block hash of the block which contains the requestRandomness
 * @dev call is mixed into the input to the VRF *last*, a sufficiently powerful
 * @dev miner could, in principle, fork the blockchain to evict the block
 * @dev containing the request, forcing the request to be included in a
 * @dev different block with a different hash, and therefore a different input
 * @dev to the VRF. However, such an attack would incur a substantial economic
 * @dev cost. This cost scales with the number of blocks the VRF oracle waits
 * @dev until it calls responds to a request. It is for this reason that
 * @dev that you can signal to an oracle you'd like them to wait longer before
 * @dev responding to the request (however this is not enforced in the contract
 * @dev and so remains effective only in the case of unmodified oracle software).
 */
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

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

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

  /*
   * @notice Check to see if there exists a request commitment consumers
   * for all consumers and keyhashes for a given sub.
   * @param subId - ID of the subscription
   * @return true if there exists at least one unfulfilled request for the subscription, false
   * otherwise.
   */
  function pendingRequestExists(uint64 subId) external view returns (bool);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.8.0) (utils/Strings.sol)

pragma solidity ^0.8.0;

import "./math/Math.sol";

/**
 * @dev String operations.
 */
library Strings {
    bytes16 private constant _SYMBOLS = "0123456789abcdef";
    uint8 private constant _ADDRESS_LENGTH = 20;

    /**
     * @dev Converts a `uint256` to its ASCII `string` decimal representation.
     */
    function toString(uint256 value) internal pure returns (string memory) {
        unchecked {
            uint256 length = Math.log10(value) + 1;
            string memory buffer = new string(length);
            uint256 ptr;
            /// @solidity memory-safe-assembly
            assembly {
                ptr := add(buffer, add(32, length))
            }
            while (true) {
                ptr--;
                /// @solidity memory-safe-assembly
                assembly {
                    mstore8(ptr, byte(mod(value, 10), _SYMBOLS))
                }
                value /= 10;
                if (value == 0) break;
            }
            return buffer;
        }
    }

    /**
     * @dev Converts a `uint256` to its ASCII `string` hexadecimal representation.
     */
    function toHexString(uint256 value) internal pure returns (string memory) {
        unchecked {
            return toHexString(value, Math.log256(value) + 1);
        }
    }

    /**
     * @dev Converts a `uint256` to its ASCII `string` hexadecimal representation with fixed length.
     */
    function toHexString(uint256 value, uint256 length) internal pure returns (string memory) {
        bytes memory buffer = new bytes(2 * length + 2);
        buffer[0] = "0";
        buffer[1] = "x";
        for (uint256 i = 2 * length + 1; i > 1; --i) {
            buffer[i] = _SYMBOLS[value & 0xf];
            value >>= 4;
        }
        require(value == 0, "Strings: hex length insufficient");
        return string(buffer);
    }

    /**
     * @dev Converts an `address` with fixed length of 20 bytes to its not checksummed ASCII `string` hexadecimal representation.
     */
    function toHexString(address addr) internal pure returns (string memory) {
        return toHexString(uint256(uint160(addr)), _ADDRESS_LENGTH);
    }
}

// SPDX-License-Identifier: MIT
/**
 * @notice This is a deprecated interface. Please use AutomationCompatibleInterface directly.
 */
pragma solidity ^0.8.0;
import {AutomationCompatibleInterface as KeeperCompatibleInterface} from "./AutomationCompatibleInterface.sol";

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface AggregatorV3Interface {
  function decimals() external view returns (uint8);

  function description() external view returns (string memory);

  function version() external view returns (uint256);

  function getRoundData(uint80 _roundId)
    external
    view
    returns (
      uint80 roundId,
      int256 answer,
      uint256 startedAt,
      uint256 updatedAt,
      uint80 answeredInRound
    );

  function latestRoundData()
    external
    view
    returns (
      uint80 roundId,
      int256 answer,
      uint256 startedAt,
      uint256 updatedAt,
      uint80 answeredInRound
    );
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.8.0) (utils/math/Math.sol)

pragma solidity ^0.8.0;

/**
 * @dev Standard math utilities missing in the Solidity language.
 */
library Math {
    enum Rounding {
        Down, // Toward negative infinity
        Up, // Toward infinity
        Zero // Toward zero
    }

    /**
     * @dev Returns the largest of two numbers.
     */
    function max(uint256 a, uint256 b) internal pure returns (uint256) {
        return a > b ? a : b;
    }

    /**
     * @dev Returns the smallest of two numbers.
     */
    function min(uint256 a, uint256 b) internal pure returns (uint256) {
        return a < b ? a : b;
    }

    /**
     * @dev Returns the average of two numbers. The result is rounded towards
     * zero.
     */
    function average(uint256 a, uint256 b) internal pure returns (uint256) {
        // (a + b) / 2 can overflow.
        return (a & b) + (a ^ b) / 2;
    }

    /**
     * @dev Returns the ceiling of the division of two numbers.
     *
     * This differs from standard division with `/` in that it rounds up instead
     * of rounding down.
     */
    function ceilDiv(uint256 a, uint256 b) internal pure returns (uint256) {
        // (a + b - 1) / b can overflow on addition, so we distribute.
        return a == 0 ? 0 : (a - 1) / b + 1;
    }

    /**
     * @notice Calculates floor(x * y / denominator) with full precision. Throws if result overflows a uint256 or denominator == 0
     * @dev Original credit to Remco Bloemen under MIT license (https://xn--2-umb.com/21/muldiv)
     * with further edits by Uniswap Labs also under MIT license.
     */
    function mulDiv(
        uint256 x,
        uint256 y,
        uint256 denominator
    ) internal pure returns (uint256 result) {
        unchecked {
            // 512-bit multiply [prod1 prod0] = x * y. Compute the product mod 2^256 and mod 2^256 - 1, then use
            // use the Chinese Remainder Theorem to reconstruct the 512 bit result. The result is stored in two 256
            // variables such that product = prod1 * 2^256 + prod0.
            uint256 prod0; // Least significant 256 bits of the product
            uint256 prod1; // Most significant 256 bits of the product
            assembly {
                let mm := mulmod(x, y, not(0))
                prod0 := mul(x, y)
                prod1 := sub(sub(mm, prod0), lt(mm, prod0))
            }

            // Handle non-overflow cases, 256 by 256 division.
            if (prod1 == 0) {
                return prod0 / denominator;
            }

            // Make sure the result is less than 2^256. Also prevents denominator == 0.
            require(denominator > prod1);

            ///////////////////////////////////////////////
            // 512 by 256 division.
            ///////////////////////////////////////////////

            // Make division exact by subtracting the remainder from [prod1 prod0].
            uint256 remainder;
            assembly {
                // Compute remainder using mulmod.
                remainder := mulmod(x, y, denominator)

                // Subtract 256 bit number from 512 bit number.
                prod1 := sub(prod1, gt(remainder, prod0))
                prod0 := sub(prod0, remainder)
            }

            // Factor powers of two out of denominator and compute largest power of two divisor of denominator. Always >= 1.
            // See https://cs.stackexchange.com/q/138556/92363.

            // Does not overflow because the denominator cannot be zero at this stage in the function.
            uint256 twos = denominator & (~denominator + 1);
            assembly {
                // Divide denominator by twos.
                denominator := div(denominator, twos)

                // Divide [prod1 prod0] by twos.
                prod0 := div(prod0, twos)

                // Flip twos such that it is 2^256 / twos. If twos is zero, then it becomes one.
                twos := add(div(sub(0, twos), twos), 1)
            }

            // Shift in bits from prod1 into prod0.
            prod0 |= prod1 * twos;

            // Invert denominator mod 2^256. Now that denominator is an odd number, it has an inverse modulo 2^256 such
            // that denominator * inv = 1 mod 2^256. Compute the inverse by starting with a seed that is correct for
            // four bits. That is, denominator * inv = 1 mod 2^4.
            uint256 inverse = (3 * denominator) ^ 2;

            // Use the Newton-Raphson iteration to improve the precision. Thanks to Hensel's lifting lemma, this also works
            // in modular arithmetic, doubling the correct bits in each step.
            inverse *= 2 - denominator * inverse; // inverse mod 2^8
            inverse *= 2 - denominator * inverse; // inverse mod 2^16
            inverse *= 2 - denominator * inverse; // inverse mod 2^32
            inverse *= 2 - denominator * inverse; // inverse mod 2^64
            inverse *= 2 - denominator * inverse; // inverse mod 2^128
            inverse *= 2 - denominator * inverse; // inverse mod 2^256

            // Because the division is now exact we can divide by multiplying with the modular inverse of denominator.
            // This will give us the correct result modulo 2^256. Since the preconditions guarantee that the outcome is
            // less than 2^256, this is the final result. We don't need to compute the high bits of the result and prod1
            // is no longer required.
            result = prod0 * inverse;
            return result;
        }
    }

    /**
     * @notice Calculates x * y / denominator with full precision, following the selected rounding direction.
     */
    function mulDiv(
        uint256 x,
        uint256 y,
        uint256 denominator,
        Rounding rounding
    ) internal pure returns (uint256) {
        uint256 result = mulDiv(x, y, denominator);
        if (rounding == Rounding.Up && mulmod(x, y, denominator) > 0) {
            result += 1;
        }
        return result;
    }

    /**
     * @dev Returns the square root of a number. If the number is not a perfect square, the value is rounded down.
     *
     * Inspired by Henry S. Warren, Jr.'s "Hacker's Delight" (Chapter 11).
     */
    function sqrt(uint256 a) internal pure returns (uint256) {
        if (a == 0) {
            return 0;
        }

        // For our first guess, we get the biggest power of 2 which is smaller than the square root of the target.
        //
        // We know that the "msb" (most significant bit) of our target number `a` is a power of 2 such that we have
        // `msb(a) <= a < 2*msb(a)`. This value can be written `msb(a)=2**k` with `k=log2(a)`.
        //
        // This can be rewritten `2**log2(a) <= a < 2**(log2(a) + 1)`
        // → `sqrt(2**k) <= sqrt(a) < sqrt(2**(k+1))`
        // → `2**(k/2) <= sqrt(a) < 2**((k+1)/2) <= 2**(k/2 + 1)`
        //
        // Consequently, `2**(log2(a) / 2)` is a good first approximation of `sqrt(a)` with at least 1 correct bit.
        uint256 result = 1 << (log2(a) >> 1);

        // At this point `result` is an estimation with one bit of precision. We know the true value is a uint128,
        // since it is the square root of a uint256. Newton's method converges quadratically (precision doubles at
        // every iteration). We thus need at most 7 iteration to turn our partial result with one bit of precision
        // into the expected uint128 result.
        unchecked {
            result = (result + a / result) >> 1;
            result = (result + a / result) >> 1;
            result = (result + a / result) >> 1;
            result = (result + a / result) >> 1;
            result = (result + a / result) >> 1;
            result = (result + a / result) >> 1;
            result = (result + a / result) >> 1;
            return min(result, a / result);
        }
    }

    /**
     * @notice Calculates sqrt(a), following the selected rounding direction.
     */
    function sqrt(uint256 a, Rounding rounding) internal pure returns (uint256) {
        unchecked {
            uint256 result = sqrt(a);
            return result + (rounding == Rounding.Up && result * result < a ? 1 : 0);
        }
    }

    /**
     * @dev Return the log in base 2, rounded down, of a positive value.
     * Returns 0 if given 0.
     */
    function log2(uint256 value) internal pure returns (uint256) {
        uint256 result = 0;
        unchecked {
            if (value >> 128 > 0) {
                value >>= 128;
                result += 128;
            }
            if (value >> 64 > 0) {
                value >>= 64;
                result += 64;
            }
            if (value >> 32 > 0) {
                value >>= 32;
                result += 32;
            }
            if (value >> 16 > 0) {
                value >>= 16;
                result += 16;
            }
            if (value >> 8 > 0) {
                value >>= 8;
                result += 8;
            }
            if (value >> 4 > 0) {
                value >>= 4;
                result += 4;
            }
            if (value >> 2 > 0) {
                value >>= 2;
                result += 2;
            }
            if (value >> 1 > 0) {
                result += 1;
            }
        }
        return result;
    }

    /**
     * @dev Return the log in base 2, following the selected rounding direction, of a positive value.
     * Returns 0 if given 0.
     */
    function log2(uint256 value, Rounding rounding) internal pure returns (uint256) {
        unchecked {
            uint256 result = log2(value);
            return result + (rounding == Rounding.Up && 1 << result < value ? 1 : 0);
        }
    }

    /**
     * @dev Return the log in base 10, rounded down, of a positive value.
     * Returns 0 if given 0.
     */
    function log10(uint256 value) internal pure returns (uint256) {
        uint256 result = 0;
        unchecked {
            if (value >= 10**64) {
                value /= 10**64;
                result += 64;
            }
            if (value >= 10**32) {
                value /= 10**32;
                result += 32;
            }
            if (value >= 10**16) {
                value /= 10**16;
                result += 16;
            }
            if (value >= 10**8) {
                value /= 10**8;
                result += 8;
            }
            if (value >= 10**4) {
                value /= 10**4;
                result += 4;
            }
            if (value >= 10**2) {
                value /= 10**2;
                result += 2;
            }
            if (value >= 10**1) {
                result += 1;
            }
        }
        return result;
    }

    /**
     * @dev Return the log in base 10, following the selected rounding direction, of a positive value.
     * Returns 0 if given 0.
     */
    function log10(uint256 value, Rounding rounding) internal pure returns (uint256) {
        unchecked {
            uint256 result = log10(value);
            return result + (rounding == Rounding.Up && 10**result < value ? 1 : 0);
        }
    }

    /**
     * @dev Return the log in base 256, rounded down, of a positive value.
     * Returns 0 if given 0.
     *
     * Adding one to the result gives the number of pairs of hex symbols needed to represent `value` as a hex string.
     */
    function log256(uint256 value) internal pure returns (uint256) {
        uint256 result = 0;
        unchecked {
            if (value >> 128 > 0) {
                value >>= 128;
                result += 16;
            }
            if (value >> 64 > 0) {
                value >>= 64;
                result += 8;
            }
            if (value >> 32 > 0) {
                value >>= 32;
                result += 4;
            }
            if (value >> 16 > 0) {
                value >>= 16;
                result += 2;
            }
            if (value >> 8 > 0) {
                result += 1;
            }
        }
        return result;
    }

    /**
     * @dev Return the log in base 10, following the selected rounding direction, of a positive value.
     * Returns 0 if given 0.
     */
    function log256(uint256 value, Rounding rounding) internal pure returns (uint256) {
        unchecked {
            uint256 result = log256(value);
            return result + (rounding == Rounding.Up && 1 << (result * 8) < value ? 1 : 0);
        }
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface AutomationCompatibleInterface {
  /**
   * @notice method that is simulated by the keepers to see if any work actually
   * needs to be performed. This method does does not actually need to be
   * executable, and since it is only ever simulated it can consume lots of gas.
   * @dev To ensure that it is never called, you may want to add the
   * cannotExecute modifier from KeeperBase to your implementation of this
   * method.
   * @param checkData specified in the upkeep registration so it is always the
   * same for a registered upkeep. This can easily be broken down into specific
   * arguments using `abi.decode`, so multiple upkeeps can be registered on the
   * same contract and easily differentiated by the contract.
   * @return upkeepNeeded boolean to indicate whether the keeper should call
   * performUpkeep or not.
   * @return performData bytes that the keeper should call performUpkeep with, if
   * upkeep is needed. If you would like to encode data to decode later, try
   * `abi.encode`.
   */
  function checkUpkeep(bytes calldata checkData) external returns (bool upkeepNeeded, bytes memory performData);

  /**
   * @notice method that is actually executed by the keepers, via the registry.
   * The data returned by the checkUpkeep simulation will be passed into
   * this method to actually be executed.
   * @dev The input to this method should not be trusted, and the caller of the
   * method should not even be restricted to any single registry. Anyone should
   * be able call it, and the input should be validated, there is no guarantee
   * that the data passed in is the performData returned from checkUpkeep. This
   * could happen due to malicious keepers, racing keepers, or simply a state
   * change while the performUpkeep transaction is waiting for confirmation.
   * Always validate the data passed in.
   * @param performData is the data which was passed back from the checkData
   * simulation. If it is encoded, it can easily be decoded into other types by
   * calling `abi.decode`. This data should not be trusted, and should be
   * validated against the contract's current state.
   */
  function performUpkeep(bytes calldata performData) external;
}