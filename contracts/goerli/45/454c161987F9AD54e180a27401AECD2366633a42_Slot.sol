// SPDX-License-Identifier: MIT

pragma solidity ^0.8.7;

/* Imports */
import "@chainlink/contracts/src/v0.8/VRFConsumerBaseV2.sol";
import "@chainlink/contracts/src/v0.8/interfaces/VRFCoordinatorV2Interface.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

/* Custom Errors */
error Slot__HaveEnoughSpins(uint256 randomWordsStoredLength, uint32 refreshStoredWords);
error Slot__WithdrawFailed();
error Slot__NotEnoughEthEntered(address playerAddress, uint256 ethPassed, uint256 entranceFee);
error Slot__MachineEmpty(uint256 contractBalance, uint256 payout);
error Slot__NeedMoreSpins();
error Slot__TransferFailed(address playerAddress);
error Slot__PlayerNoBalance();
error Slot__PlayerNotEnoughBalance(uint256 reqWithdraw, uint256 playerBalance);
error Slot__PlayerWithdrawFailed();

contract Slot is VRFConsumerBaseV2, Ownable {
    /* Types */
    /* State Variables */

    // constants
    uint16 private constant REQUEST_CONFIRMATIONS = 3; // 3 is minimum for mainnet per docs.chain.link/docs/vrf-contracts
    uint16 private constant SPINS_PER_BUY = 10;
    uint16 private constant STOPS_TO_WIN = 2;
    uint16 private constant NUM_STOPS = 12;
    uint16 private constant NUM_REELS = 5;

    //storage

    // -- used for vrf
    VRFCoordinatorV2Interface private immutable i_vrfCoordinator;
    bytes32 private immutable i_gasLane;
    uint64 private immutable i_subscriptionId;
    uint32 private immutable i_callbackGasLimit;
    bool private s_vrfRequesting = false;
    uint256 private s_lastRequestId;

    // -- used in spin logic
    // uint16 private immutable i_stopsToWin;
    // uint16 private s_numReels;
    // uint16 private immutable i_numStops;
    uint256 private immutable i_entranceFeeWei;
    uint256 private immutable i_payoutWei;
    uint256 private immutable i_luckyPayoutWei;
    uint256 private immutable i_luckyStopDigit;
    uint32 private immutable i_startingStoredWords;
    uint32 private immutable i_refreshStoredWords;

    // -- used to store players/spins
    uint256[] private s_storedRandomWords;
    // address private s_lastPlayer;
    // address private s_lastWinner;
    uint256 private s_lastStop;
    uint256 private s_winnerCount = 0;
    uint256[] private s_lastSpin = new uint256[](NUM_REELS);
    // uint256[] private s_lastWinningSpin;
    mapping(address => uint256[]) private s_playerSpinsFull;
    mapping(address => bool[]) private s_playerWinsArray;
    mapping(address => bool[]) private s_playerLuckyWinsArray;
    mapping(address => uint256[]) private s_playerWinningStopsArray;
    mapping(address => uint256) private s_playerBalance; // this is total balance from current and prior sessions. e.g., if someone won 3 times but refreshed the page and bought
    mapping(address => uint256) private s_playerBalanceCurrentSession; // this is total balance from most recent
    // mapping(address => uint256) private s_playerWins;
    uint256 private s_totalOwed = 0;

    /* Events */
    event RequestedMoreSpins(uint256 requestId);
    event RandomWordsReceived();
    event SpinFinished(
        address playerAddress,
        bool isWinner,
        uint256[] lastSpin,
        uint256 streakStop
    );

    /* Functions */
    constructor(
        address vrfCoordinatorV2,
        bytes32 gasLane,
        uint64 subscriptionId,
        uint32 callbackGasLimit,
        // uint16 stopsToWin,
        // uint16 numReels,
        // uint16 numStops,
        uint256 entranceFeeWei,
        uint256 payoutWei,
        uint32 startingStoredWords,
        uint32 refreshStoredWords,
        uint256 luckyPayoutWei,
        uint256 luckyStopDigit
    ) payable VRFConsumerBaseV2(vrfCoordinatorV2) {
        i_vrfCoordinator = VRFCoordinatorV2Interface(vrfCoordinatorV2);
        i_gasLane = gasLane;
        i_subscriptionId = subscriptionId;
        i_callbackGasLimit = callbackGasLimit;
        // i_stopsToWin = stopsToWin;
        // s_numReels = numReels;
        // i_numStops = numStops;
        i_entranceFeeWei = entranceFeeWei;
        i_payoutWei = payoutWei;
        i_startingStoredWords = startingStoredWords;
        i_refreshStoredWords = refreshStoredWords;
        i_luckyPayoutWei = luckyPayoutWei;
        i_luckyStopDigit = luckyStopDigit;
        // requestMoreSpins(); need to call this after deployment now. was throwing a gas estimation error. can just implement this in deploy script so not an issue
    }

    function withdraw() public onlyOwner {
        (bool success, ) = payable(msg.sender).call{value: address(this).balance - s_totalOwed}(""); // cant withdraw more than amount owed
        if (!success) {
            revert Slot__WithdrawFailed();
        }
    }

    function playerWithdraw(uint256 reqWithdraw) public payable {
        address payable playerAddress = payable(msg.sender);
        uint256 playerBalance = s_playerBalance[msg.sender];
        if (playerBalance <= 0) {
            revert Slot__PlayerNoBalance();
        }
        if (reqWithdraw > playerBalance) {
            revert Slot__PlayerNotEnoughBalance(reqWithdraw, playerBalance);
        }
        (bool success, ) = playerAddress.call{value: reqWithdraw}("");
        if (!success) {
            revert Slot__PlayerWithdrawFailed();
        } else {
            s_playerBalance[msg.sender] = s_playerBalance[msg.sender] - reqWithdraw;
        }
    }

    function buySpins() public payable {
        // check for reverts
        if (msg.value < i_entranceFeeWei * SPINS_PER_BUY) {
            revert Slot__NotEnoughEthEntered(payable(msg.sender), msg.value, i_entranceFeeWei);
        }
        if (address(this).balance < i_payoutWei * SPINS_PER_BUY) {
            revert Slot__MachineEmpty(address(this).balance, i_payoutWei);
        }
        if (s_storedRandomWords.length == 0) {
            revert Slot__NeedMoreSpins();
        }
        // initialize arrays/vars for random numbers and streak.
        uint256[] memory slotDigits = new uint256[](NUM_REELS * SPINS_PER_BUY);
        bool[] memory playerWins = new bool[](SPINS_PER_BUY);
        bool[] memory playerLuckyWins = new bool[](SPINS_PER_BUY);
        uint256[] memory playerWinningStops = new uint256[](SPINS_PER_BUY);
        // "spin" the slot machine
        for (uint16 i = 0; i < (NUM_REELS * SPINS_PER_BUY); i++) {
            // gets n random words (number of slot reels) from the previously saved VRF random words and removes them from the array.
            slotDigits[i] = s_storedRandomWords[s_storedRandomWords.length - 1] % NUM_STOPS;
            s_storedRandomWords.pop();
        }

        s_playerSpinsFull[msg.sender] = slotDigits;

        for (uint16 e = 0; e < SPINS_PER_BUY; e++) {
            uint256 spinStreak = 0; // e.g. if you spun 1 3 3 5 2, you would've had streaks of: [[1], [3, 3], [5], [2]] = [1,2,1,1]
            uint256 spinStreakStop; // stops would've been [1, 3, 5, 2] for streaks [1,2,1,1]

            // check for streaks.
            for (uint16 i = 0; i < NUM_REELS; i++) {
                if (spinStreak >= STOPS_TO_WIN) {
                    break; // winner if the spin streak array reaches the length of spins to win
                }
                if (spinStreak == 0) {
                    // starting a new streak
                    spinStreak++;
                    spinStreakStop = slotDigits[i + (e * NUM_REELS)]; // so e.g. if this is the 3rd spin per buy (2nd element), we've already gone through 10 stops. so 0th element of this should be the 10th element of the array
                } else {
                    if (spinStreakStop == slotDigits[i + (e * NUM_REELS)]) {
                        spinStreak++;
                    } else {
                        spinStreak = 1;
                        spinStreakStop = slotDigits[i + (e * NUM_REELS)];
                    }
                }
            }

            // check for a lucky streak
            uint256 spinStreakLucky = 0; // e.g. if you spun 1 3 3 5 2, you would've had streaks of: [[1], [3, 3], [5], [2]] = [1,2,1,1]
            uint256 spinStreakStopLucky = i_luckyStopDigit; // stops would've been [1, 3, 5, 2] for streaks [1,2,1,1]
            if (spinStreakStop != spinStreakStopLucky) {
                for (uint16 i = 0; i < NUM_REELS; i++) {
                    if (spinStreakLucky >= STOPS_TO_WIN) {
                        break; // winner if the spin streak array reaches the length of spins to win
                    }
                    if (slotDigits[i + (e * NUM_REELS)] == spinStreakStopLucky) {
                        spinStreakLucky++;
                    } else {
                        spinStreakLucky = 0;
                    }
                }
            } else {
                spinStreakLucky = spinStreak;
            }

            // check for winner
            bool isWinner = false;
            bool isLuckyWinner = false;
            if (spinStreakLucky >= STOPS_TO_WIN) {
                isLuckyWinner = true;
                spinStreakStop = spinStreakStopLucky;
                s_playerBalance[msg.sender] += i_luckyPayoutWei;
                // s_playerWins[msg.sender] += 1;
                s_winnerCount = s_winnerCount + 1;
            } else if (spinStreak >= STOPS_TO_WIN) {
                isWinner = true;
                s_playerBalance[msg.sender] += i_payoutWei;
                // s_playerWins[msg.sender] += 1;
                s_winnerCount = s_winnerCount + 1;
            }

            playerWins[e] = isWinner;
            playerLuckyWins[e] = isLuckyWinner;
            playerWinningStops[e] = spinStreakStop;
        }
        s_playerWinningStopsArray[msg.sender] = playerWinningStops;
        s_playerWinsArray[msg.sender] = playerWins;
        s_playerLuckyWinsArray[msg.sender] = playerLuckyWins;

        // check for needing more spins
        if ((s_storedRandomWords.length <= i_refreshStoredWords) && (!s_vrfRequesting)) {
            requestMoreSpins();
        }
    }

    function requestMoreSpins() public returns (uint256 requestId) {
        uint256 randomWordsStored = s_storedRandomWords.length;
        if (randomWordsStored > i_refreshStoredWords) {
            revert Slot__HaveEnoughSpins(randomWordsStored, i_refreshStoredWords);
        }
        requestId = i_vrfCoordinator.requestRandomWords(
            i_gasLane,
            i_subscriptionId,
            REQUEST_CONFIRMATIONS,
            i_callbackGasLimit,
            i_startingStoredWords
        );
        s_lastRequestId = requestId;
        s_vrfRequesting = true;
        emit RequestedMoreSpins(requestId);
    }

    function fulfillRandomWords(
        uint256, /*requestId passed by the external vrf operator*/
        uint256[] memory randomWords // the array of randomWords sent
    ) internal override {
        s_storedRandomWords = randomWords;
        s_vrfRequesting = false;
        emit RandomWordsReceived();
    }

    function spin() public payable {
        // address payable playerAddress = payable(msg.sender);
        // uint256 ethPassed = msg.value;

        // check for reverts
        if (msg.value < i_entranceFeeWei) {
            revert Slot__NotEnoughEthEntered(payable(msg.sender), msg.value, i_entranceFeeWei);
        }
        if (address(this).balance < i_payoutWei) {
            revert Slot__MachineEmpty(address(this).balance, i_payoutWei);
        }
        if (s_storedRandomWords.length == 0) {
            revert Slot__NeedMoreSpins();
        }

        // initialize arrays/vars for random numbers and streak.
        uint256[] memory slotDigits = new uint256[](NUM_REELS);
        uint256 spinStreak = 0; // e.g. if you spun 1 3 3 5 2, you would've had streaks of: [[1], [3, 3], [5], [2]] = [1,2,1,1]
        uint256 spinStreakStop; // stops would've been [1, 3, 5, 2] for streaks [1,2,1,1]

        // "spin" the slot machine
        for (uint16 i = 0; i < NUM_REELS; i++) {
            // gets n random words (number of slot reels) from the previously saved VRF random words and removes them from the array.
            slotDigits[i] = s_storedRandomWords[s_storedRandomWords.length - 1] % NUM_STOPS;
            s_storedRandomWords.pop();
        }

        // check for streaks.
        for (uint16 i = 0; i < NUM_REELS; i++) {
            if (spinStreak >= STOPS_TO_WIN) {
                break; // winner if the spin streak array reaches the length of spins to win
            }
            if (spinStreak == 0) {
                // starting a new streak
                spinStreak++;
                spinStreakStop = slotDigits[i];
            } else {
                if (spinStreakStop == slotDigits[i]) {
                    spinStreak++;
                } else {
                    spinStreak = 1;
                    spinStreakStop = slotDigits[i];
                }
            }
        }

        // check for winner
        bool isWinner = false;
        if (spinStreak >= STOPS_TO_WIN) {
            (bool success, ) = payable(msg.sender).call{value: i_payoutWei}("");
            if (!success) {
                revert Slot__TransferFailed(payable(msg.sender));
            }
            isWinner = true;
            // s_lastWinner = playerAddress;
            // s_lastWinningSpin = slotDigits;
            s_winnerCount = s_winnerCount + 1;
        }

        s_lastSpin = slotDigits;
        s_lastStop = spinStreakStop;
        // s_lastPlayer = playerAddress;
        emit SpinFinished(payable(msg.sender), isWinner, slotDigits, spinStreakStop);

        // check for needing more spins
        if ((s_storedRandomWords.length <= i_refreshStoredWords) && (!s_vrfRequesting)) {
            requestMoreSpins();
        }
    }

    /* Getter Functions */

    function getStopsToWin() public pure returns (uint16) {
        return STOPS_TO_WIN;
    }

    function getNumReels() public pure returns (uint16) {
        return NUM_REELS;
    }

    function getNumStops() public pure returns (uint16) {
        return NUM_STOPS;
    }

    function getEntranceFee() public view returns (uint256) {
        return i_entranceFeeWei;
    }

    function getPayout() public view returns (uint256) {
        return i_payoutWei;
    }

    function getLuckyPayout() public view returns (uint256) {
        return i_luckyPayoutWei;
    }

    function getRemainingWords() public view returns (uint256) {
        return s_storedRandomWords.length;
    }

    // function getLastPlayer() public view returns (address) {
    //     return s_lastPlayer;
    // }

    // function getLastWinner() public view returns (address) {
    //     return s_lastWinner;
    // }

    function getLastStop() public view returns (uint256) {
        return s_lastStop;
    }

    function getWinnerCount() public view returns (uint256) {
        return s_winnerCount;
    }

    function getLastSpin() public view returns (uint256[] memory) {
        return s_lastSpin;
    }

    // function getLastWinningSpin() public view returns (uint256[] memory) {
    //     return s_lastWinningSpin;
    // }

    function getVrfRequestStatus() public view returns (bool) {
        return s_vrfRequesting;
    }

    function getLastRequestId() public view returns (uint256) {
        return s_lastRequestId;
    }

    function getPlayerBalance() public view returns (uint256) {
        return s_playerBalance[msg.sender];
    }

    function getPlayerSpinsRemaining() public view returns (uint256) {
        return s_playerSpinsFull[msg.sender].length / NUM_REELS;
    }

    function getPlayerSpinsFull() public view returns (uint256[] memory) {
        return s_playerSpinsFull[msg.sender];
    }

    function getSpinsPerBuy() public pure returns (uint16) {
        return SPINS_PER_BUY;
    }

    // function getPlayerWins() public view returns (uint256) {
    //     return s_playerWins[msg.sender];
    // }

    function getPlayerWinsArr() public view returns (bool[] memory) {
        return s_playerWinsArray[msg.sender];
    }

    function getPlayerLuckyWinsArr() public view returns (bool[] memory) {
        return s_playerLuckyWinsArray[msg.sender];
    }

    function getPlayerWinningStopsArr() public view returns (uint256[] memory) {
        return s_playerWinningStopsArray[msg.sender];
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
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (access/Ownable.sol)

pragma solidity ^0.8.0;

import "../utils/Context.sol";

/**
 * @dev Contract module which provides a basic access control mechanism, where
 * there is an account (an owner) that can be granted exclusive access to
 * specific functions.
 *
 * By default, the owner account will be the one that deploys the contract. This
 * can later be changed with {transferOwnership}.
 *
 * This module is used through inheritance. It will make available the modifier
 * `onlyOwner`, which can be applied to your functions to restrict their use to
 * the owner.
 */
abstract contract Ownable is Context {
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    /**
     * @dev Initializes the contract setting the deployer as the initial owner.
     */
    constructor() {
        _transferOwnership(_msgSender());
    }

    /**
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        _checkOwner();
        _;
    }

    /**
     * @dev Returns the address of the current owner.
     */
    function owner() public view virtual returns (address) {
        return _owner;
    }

    /**
     * @dev Throws if the sender is not the owner.
     */
    function _checkOwner() internal view virtual {
        require(owner() == _msgSender(), "Ownable: caller is not the owner");
    }

    /**
     * @dev Leaves the contract without owner. It will not be possible to call
     * `onlyOwner` functions anymore. Can only be called by the current owner.
     *
     * NOTE: Renouncing ownership will leave the contract without an owner,
     * thereby removing any functionality that is only available to the owner.
     */
    function renounceOwnership() public virtual onlyOwner {
        _transferOwnership(address(0));
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        _transferOwnership(newOwner);
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Internal function without access restriction.
     */
    function _transferOwnership(address newOwner) internal virtual {
        address oldOwner = _owner;
        _owner = newOwner;
        emit OwnershipTransferred(oldOwner, newOwner);
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/Context.sol)

pragma solidity ^0.8.0;

/**
 * @dev Provides information about the current execution context, including the
 * sender of the transaction and its data. While these are generally available
 * via msg.sender and msg.data, they should not be accessed in such a direct
 * manner, since when dealing with meta-transactions the account sending and
 * paying for execution may not be the actual sender (as far as an application
 * is concerned).
 *
 * This contract is only required for intermediate, library-like contracts.
 */
abstract contract Context {
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes calldata) {
        return msg.data;
    }
}