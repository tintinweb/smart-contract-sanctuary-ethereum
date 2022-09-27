// SPDX-License-Identifier: MIT
pragma solidity ^0.8.7;

/* Imports */
import "@chainlink/contracts/src/v0.8/VRFConsumerBaseV2.sol";
import "@chainlink/contracts/src/v0.8/interfaces/VRFCoordinatorV2Interface.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@chainlink/contracts/src/v0.8/interfaces/KeeperCompatibleInterface.sol";

/* Custom Errors */
error Slot__UpkeepNotNeeded();
error Slot__WithdrawFailed();
error Slot__PlayerNoBalance();
error Slot__PlayerNotEnoughBalance(uint256 reqWithdraw, uint256 playerBalance);
error Slot__PlayerWithdrawFailed();
error Slot__NotEnoughEthEntered(address playerAddress, uint256 ethPassed, uint256 entranceFee);
error Slot__MachineEmpty(uint256 contractBalance, uint256 payout);
error Slot__NeedMoreSpins();

contract Slot is VRFConsumerBaseV2, Ownable, KeeperCompatibleInterface {
    /* State Variables */

    uint8 private constant NUM_REELS = 5;
    uint8 private constant LAST_REEL_IDX = 4;
    uint8 private constant NUM_STOPS = 12;
    uint8 private constant SPINS_PER_BUY = 10;
    uint8 private constant NUM_WORDS_PER_BUY = 50; // NUM_REELS * SPINS_PER_BUY
    uint8 private constant REQUEST_CONFIRMATIONS = 3; // 3 is minimum for mainnet per docs.chain.link/docs/vrf-contracts
    uint8 private constant LUCKY_STOP_DIGIT = 4;
    uint8 private constant STOPS_TO_WIN = 2;

    bytes32 private immutable i_gasLane;
    uint64 private immutable i_subscriptionId;
    uint32 private immutable i_callbackGasLimit;
    uint16 private immutable i_startingStoredWords; // must be 16 because we pass to VRF
    uint16 private immutable i_startingStoredNumbers;
    uint16 private immutable i_refreshStoredNumbers;

    uint8 private constant DIGITS_PER_WORD = 76;
    uint8 private constant NUMBERS_PER_WORD = 38; // VRF gives you a random number with at least 76 digits. From this we can extract 38 unique numbers.
    uint8[] private s_words;
    bool private s_vrfRequesting = false;
    uint16 private s_lastNumUsedIdx;

    mapping(address => uint8[]) private s_playerWinsArray;
    mapping(address => uint8[]) private s_playerStopsOneArray;
    mapping(address => uint8[]) private s_playerStopsTwoArray;
    mapping(address => uint8[]) private s_playerSpins;
    VRFCoordinatorV2Interface private immutable i_vrfCoordinator;

    // win types:
    // 0: none
    // 1: 2x
    // 2: 3x
    // 3: 4x
    // 4: 5x
    // 5: 2x2
    // 6: 2x3
    // 7: lucky 2x
    // 8: lucky 3x
    // 9: lucky 4x
    // 10: lucky 5x
    // 11: lucky 2x2x
    // 12: lucky 3x other 2x
    // 13: lucky 2x other 3x

    // this is for goerli
    // uint256 private constant PAYOUTS_WEI_1 = 129032258064516;
    // uint256 private constant PAYOUTS_WEI_2 = 322580645161290;
    // uint256 private constant PAYOUTS_WEI_3 = 1290322580645160;
    // uint256 private constant PAYOUTS_WEI_4 = 12903225806451600;
    // uint256 private constant PAYOUTS_WEI_5 = 387096774193548;
    // uint256 private constant PAYOUTS_WEI_6 = 1290322580645160;
    // uint256 private constant PAYOUTS_WEI_7 = 258064516129032;
    // uint256 private constant PAYOUTS_WEI_8 = 1290322580645160;
    // uint256 private constant PAYOUTS_WEI_9 = 3870967741935480;
    // uint256 private constant PAYOUTS_WEI_10 = 64516129032258100;
    // uint256 private constant PAYOUTS_WEI_11 = 967741935483871;
    // uint256 private constant PAYOUTS_WEI_12 = 3225806451612900;
    // uint256 private constant PAYOUTS_WEI_13 = 2580645161290320;
    // uint256 private constant BUY_SPINS_WEI = 645161290322581; // spins per buy * entrance fee wei
    // uint256 private constant ENTRANCE_FEE_WEI = 64516129032258;
    // uint256 private constant PAYOUT_CUSHION = 64516129032258100; // using 1 5x doge (lucky_payout * 10 ** 3). this should really be equal to the max payout * 10 since someone could theoretically hit 10 5x doeges in a row...

    // this is for avax
    uint256 private constant PAYOUTS_WEI_1 = 17191977077363900;
    uint256 private constant PAYOUTS_WEI_2 = 51575931232091700;
    uint256 private constant PAYOUTS_WEI_3 = 214899713467049000;
    uint256 private constant PAYOUTS_WEI_4 = 1289398280802290000;
    uint256 private constant PAYOUTS_WEI_5 = 51575931232091700;
    uint256 private constant PAYOUTS_WEI_6 = 214899713467049000;
    uint256 private constant PAYOUTS_WEI_7 = 34383954154727800;
    uint256 private constant PAYOUTS_WEI_8 = 171919770773639000;
    uint256 private constant PAYOUTS_WEI_9 = 386819484240688000;
    uint256 private constant PAYOUTS_WEI_10 = 8595988538681950000;
    uint256 private constant PAYOUTS_WEI_11 = 128939828080229000;
    uint256 private constant PAYOUTS_WEI_12 = 300859598853868000;
    uint256 private constant PAYOUTS_WEI_13 = 343839541547278000;
    uint256 private constant BUY_SPINS_WEI = 85959885386819500;
    uint256 private constant ENTRANCE_FEE_WEI = 8595988538681950;
    uint256 private constant PAYOUT_CUSHION = 8595988538681950000;

    uint256 private s_totalOwed;

    mapping(address => uint256) private s_playerBalance; // this is total balance from current and prior sessions. e.g., if someone won 3 times but refreshed the page and bought

    /* Events */
    event RequestedMoreSpins(uint256 requestId);
    event RandomWordsReceived();

    /* Functions */
    constructor(
        address vrfCoordinatorV2,
        bytes32 gasLane,
        uint64 subscriptionId,
        uint32 callbackGasLimit,
        uint16 startingStoredWords,
        uint16 refreshStoredWords
    ) payable VRFConsumerBaseV2(vrfCoordinatorV2) {
        i_vrfCoordinator = VRFCoordinatorV2Interface(vrfCoordinatorV2);
        i_gasLane = gasLane;
        i_subscriptionId = subscriptionId;
        i_callbackGasLimit = callbackGasLimit;
        i_startingStoredWords = startingStoredWords;

        unchecked {
            i_refreshStoredNumbers = refreshStoredWords;
            i_startingStoredNumbers = startingStoredWords * uint16(NUMBERS_PER_WORD);
        }
    }

    // chainlink keepers & vrf
    function checkUpkeep(
        bytes memory /*checkData*/
    )
        public
        override
        returns (
            bool upkeepNeeded,
            bytes memory /*performData*/
        )
    {
        bool needsWords;
        unchecked {
            needsWords = s_lastNumUsedIdx + 1 <= i_refreshStoredNumbers;
        }
        bool hasBalance = address(this).balance > 0;
        upkeepNeeded = (needsWords && hasBalance && !s_vrfRequesting);
    }

    function performUpkeep(
        bytes calldata /* performData */
    ) public override {
        (bool upkeepNeeded, ) = checkUpkeep("");
        if (!upkeepNeeded) {
            revert Slot__UpkeepNotNeeded();
        }
        uint256 requestId = i_vrfCoordinator.requestRandomWords(
            i_gasLane,
            i_subscriptionId,
            REQUEST_CONFIRMATIONS,
            i_callbackGasLimit,
            i_startingStoredWords
        );
        s_vrfRequesting = true;
        emit RequestedMoreSpins(requestId);
    }

    function fulfillRandomWords(uint256, uint256[] memory randomWords) internal override {
        uint8 digitIdx;
        uint8 randNumber;
        uint16 currentIdx;
        uint16 rwLength = uint16(randomWords.length);
        uint8[] memory numbers = new uint8[](i_startingStoredNumbers);
        for (uint16 i; i < rwLength; ) {
            for (uint16 j; j < NUMBERS_PER_WORD; ) {
                unchecked {
                    currentIdx = j + NUMBERS_PER_WORD * i;
                    digitIdx = uint8(DIGITS_PER_WORD - ((currentIdx * 2) % (NUMBERS_PER_WORD * 2)));
                    randNumber =
                        uint8((randomWords[i] % 10**(digitIdx + 1)) / (10**(digitIdx + 1 - 2))) %
                        NUM_STOPS;
                }
                numbers[currentIdx] = randNumber;
                unchecked {
                    ++j; // https://dev.to/jamiescript/gas-saving-techniques-in-solidity-324c#incrementing
                }
            }
            unchecked {
                ++i;
            }
        }
        s_words = numbers;
        unchecked {
            s_lastNumUsedIdx = i_startingStoredNumbers - 1;
        }
        s_vrfRequesting = false;
        emit RandomWordsReceived();
    }

    function buySpins() public payable {
        // check for reverts
        if (msg.value < BUY_SPINS_WEI) {
            revert Slot__NotEnoughEthEntered(msg.sender, msg.value, ENTRANCE_FEE_WEI);
        }
        if (address(this).balance < PAYOUT_CUSHION) {
            revert Slot__MachineEmpty(address(this).balance, PAYOUT_CUSHION);
        }
        if (s_lastNumUsedIdx < NUM_WORDS_PER_BUY) {
            revert Slot__NeedMoreSpins();
        }

        uint8 number;
        uint8[] memory playerWins = new uint8[](SPINS_PER_BUY);
        uint8[] memory playerStopsOne = new uint8[](SPINS_PER_BUY);
        uint8[] memory playerStopsTwo = new uint8[](SPINS_PER_BUY);
        uint8[] memory playerSpins = new uint8[](NUM_REELS * SPINS_PER_BUY);
        uint256 playerPayout;

        for (uint8 i; i < SPINS_PER_BUY; ) {
            uint8 spinStreakStopTemp = 99;
            uint8 spinStreakStopOne = 99;
            uint8 spinStreakStopTwo = 99;
            uint8 spinStreakTemp = 0;
            uint8 spinStreakOne = 0;
            uint8 spinStreakTwo = 0;
            uint16 currentIdx;
            for (uint8 j; j < NUM_REELS; ) {
                unchecked {
                    currentIdx = s_lastNumUsedIdx - i * NUM_REELS - j;
                }
                number = s_words[currentIdx];
                unchecked {
                    currentIdx = i * NUM_REELS + j;
                }
                playerSpins[currentIdx] = number;
                if (number == spinStreakStopTemp) {
                    unchecked {
                        ++spinStreakTemp;
                    }
                } else {
                    if (spinStreakTemp >= 2) {
                        if (spinStreakOne == 0) {
                            spinStreakOne = spinStreakTemp;
                            spinStreakStopOne = spinStreakStopTemp;
                        } else if (spinStreakTwo == 0) {
                            spinStreakTwo = spinStreakTemp;
                            spinStreakStopTwo = spinStreakStopTemp;
                        }
                    }
                    spinStreakTemp = 1;
                    spinStreakStopTemp = number;
                }
                if (j == LAST_REEL_IDX) {
                    // logic for adding to spinStreakOne or Two at very end of iteration
                    if (spinStreakTemp >= 2) {
                        if (spinStreakOne == 0) {
                            spinStreakOne = spinStreakTemp;
                            spinStreakStopOne = spinStreakStopTemp;
                        } else if (spinStreakTwo == 0) {
                            spinStreakTwo = spinStreakTemp;
                            spinStreakStopTwo = spinStreakStopTemp;
                        }
                    }
                }
                unchecked {
                    ++j;
                }
            }

            if (spinStreakOne == 0) {
                playerWins[i] = 0;
            } else if (spinStreakTwo == 0) {
                if (spinStreakStopOne == LUCKY_STOP_DIGIT) {
                    if (spinStreakOne == 2) {
                        playerWins[i] = 7;
                        unchecked {
                            playerPayout += PAYOUTS_WEI_7;
                        }
                    } else if (spinStreakOne == 3) {
                        playerWins[i] = 8;
                        unchecked {
                            playerPayout += PAYOUTS_WEI_8;
                        }
                    } else if (spinStreakOne == 4) {
                        playerWins[i] = 9;
                        unchecked {
                            playerPayout += PAYOUTS_WEI_9;
                        }
                    } else if (spinStreakOne == 5) {
                        playerWins[i] = 10;
                        unchecked {
                            playerPayout += PAYOUTS_WEI_10;
                        }
                    }
                } else {
                    if (spinStreakOne == 2) {
                        playerWins[i] = 1;
                        unchecked {
                            playerPayout += PAYOUTS_WEI_1;
                        }
                    } else if (spinStreakOne == 3) {
                        playerWins[i] = 2;
                        unchecked {
                            playerPayout += PAYOUTS_WEI_2;
                        }
                    } else if (spinStreakOne == 4) {
                        playerWins[i] = 3;
                        unchecked {
                            playerPayout += PAYOUTS_WEI_3;
                        }
                    } else if (spinStreakOne == 5) {
                        playerWins[i] = 4;
                        unchecked {
                            playerPayout += PAYOUTS_WEI_4;
                        }
                    }
                }
            } else {
                // this means there's both a spin streak one and a spin streak two. so can be 2x2 or 2x3
                if (
                    // 3x2 doge
                    (spinStreakStopOne == LUCKY_STOP_DIGIT && spinStreakOne == 3) ||
                    (spinStreakStopTwo == LUCKY_STOP_DIGIT && spinStreakTwo == 3)
                ) {
                    playerWins[i] = 12;
                    unchecked {
                        playerPayout += PAYOUTS_WEI_12;
                    }
                } else if (
                    // 2 doge x 3 other
                    (spinStreakStopOne == LUCKY_STOP_DIGIT && spinStreakTwo == 3) ||
                    (spinStreakStopTwo == LUCKY_STOP_DIGIT && spinStreakOne == 3)
                ) {
                    playerWins[i] = 13;
                    unchecked {
                        playerPayout += PAYOUTS_WEI_13;
                    }
                } else if (
                    // 3x2 no doge
                    spinStreakStopOne != LUCKY_STOP_DIGIT &&
                    spinStreakStopTwo != LUCKY_STOP_DIGIT &&
                    (spinStreakOne == 3 || spinStreakTwo == 3)
                ) {
                    playerWins[i] = 6;
                    unchecked {
                        playerPayout += PAYOUTS_WEI_6;
                    }
                } else if (
                    spinStreakStopOne == LUCKY_STOP_DIGIT || spinStreakStopTwo == LUCKY_STOP_DIGIT
                ) {
                    playerWins[i] = 11;
                    unchecked {
                        playerPayout += PAYOUTS_WEI_11;
                    }
                } else {
                    playerWins[i] = 5;
                    unchecked {
                        playerPayout += PAYOUTS_WEI_5;
                    }
                }
            }
            playerStopsOne[i] = spinStreakStopOne;
            playerStopsTwo[i] = spinStreakStopTwo;
            unchecked {
                ++i;
            }
        }

        unchecked {
            s_lastNumUsedIdx -= NUM_WORDS_PER_BUY;
        }

        s_playerWinsArray[msg.sender] = playerWins;
        s_playerStopsOneArray[msg.sender] = playerStopsOne;
        s_playerStopsTwoArray[msg.sender] = playerStopsTwo;
        s_playerSpins[msg.sender] = playerSpins;
        unchecked {
            s_playerBalance[msg.sender] += playerPayout;
            s_totalOwed += playerPayout;
        }
    }

    function withdraw() public onlyOwner {
        (bool success, ) = payable(msg.sender).call{value: address(this).balance - s_totalOwed}(""); // cant withdraw more than amount owed
        if (!success) {
            revert Slot__WithdrawFailed();
        }
    }

    function withdrawUpTo(uint256 reqWithdraw) public onlyOwner {
        (bool success, ) = payable(msg.sender).call{value: reqWithdraw - s_totalOwed}(""); // cant withdraw more than amount owed
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
            s_totalOwed -= reqWithdraw;
        }
    }

    /* Getter Functions */
    function getRemainingWords() public view returns (uint16) {
        return s_lastNumUsedIdx + 1;
    }

    function getEntranceFee() public pure returns (uint256) {
        return ENTRANCE_FEE_WEI;
    }

    function getBuySpinsPrice() public pure returns (uint256) {
        return BUY_SPINS_WEI;
    }

    function getSpinsPerBuy() public pure returns (uint8) {
        return SPINS_PER_BUY;
    }

    function getStopsToWin() public pure returns (uint8) {
        return STOPS_TO_WIN;
    }

    function getNumReels() public pure returns (uint8) {
        return NUM_REELS;
    }

    function getNumStops() public pure returns (uint8) {
        return NUM_STOPS;
    }

    function getPayoutOne() public pure returns (uint256) {
        return PAYOUTS_WEI_1;
    }

    function getPayoutTwo() public pure returns (uint256) {
        return PAYOUTS_WEI_2;
    }

    function getPayoutThree() public pure returns (uint256) {
        return PAYOUTS_WEI_3;
    }

    function getPayoutFour() public pure returns (uint256) {
        return PAYOUTS_WEI_4;
    }

    function getPayoutFive() public pure returns (uint256) {
        return PAYOUTS_WEI_5;
    }

    function getPayoutSix() public pure returns (uint256) {
        return PAYOUTS_WEI_6;
    }

    function getPayoutSeven() public pure returns (uint256) {
        return PAYOUTS_WEI_7;
    }

    function getPayoutEight() public pure returns (uint256) {
        return PAYOUTS_WEI_8;
    }

    function getPayoutNine() public pure returns (uint256) {
        return PAYOUTS_WEI_9;
    }

    function getPayoutTen() public pure returns (uint256) {
        return PAYOUTS_WEI_10;
    }

    function getPayoutEleven() public pure returns (uint256) {
        return PAYOUTS_WEI_11;
    }

    function getPayoutTwelve() public pure returns (uint256) {
        return PAYOUTS_WEI_12;
    }

    function getPayoutThirteen() public pure returns (uint256) {
        return PAYOUTS_WEI_13;
    }

    function getVrfRequestStatus() public view returns (bool) {
        return s_vrfRequesting;
    }

    function getPlayerBalance() public view returns (uint256) {
        return s_playerBalance[msg.sender];
    }

    function getPlayerSpinsRemaining() public view returns (uint256) {
        return uint16(s_playerSpins[msg.sender].length / NUM_REELS);
    }

    function getPlayerSpinsFull() public view returns (uint8[] memory) {
        return s_playerSpins[msg.sender];
    }

    function getPlayerWinsArr() public view returns (uint8[] memory) {
        return s_playerWinsArray[msg.sender];
    }

    function getPlayerStopsOneArr() public view returns (uint8[] memory) {
        return s_playerStopsOneArray[msg.sender];
    }

    function getPlayerStopsTwoArr() public view returns (uint8[] memory) {
        return s_playerStopsTwoArray[msg.sender];
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
pragma solidity ^0.8.0;

interface KeeperCompatibleInterface {
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