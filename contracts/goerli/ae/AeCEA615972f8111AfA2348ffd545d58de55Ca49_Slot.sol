// SPDX-License-Identifier: MIT
pragma solidity ^0.8.7;

/* Imports */
import "@chainlink/contracts/src/v0.8/VRFConsumerBaseV2.sol";
import "@chainlink/contracts/src/v0.8/interfaces/VRFCoordinatorV2Interface.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@chainlink/contracts/src/v0.8/interfaces/KeeperCompatibleInterface.sol";
// import "hardhat/console.sol";
// import "@openzeppelin/contracts/utils/Strings.sol";

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
    struct SpinStreakData {
        uint8 spinStreak; // e.g. if you spun 1 3 3 5 2, you would've had streaks of: [[1], [3, 3], [5], [2]] = [1,2,1,1]
        uint8 spinStreakTemp;
        uint8 spinStreakStop; // stops would've been [1, 3, 5, 2] for streaks [1,2,1,1]
        uint8 spinStreakStopTemp;
        uint8 luckySpinStreak;
        uint8 luckySpinStreakTemp;
    }

    struct SpinStreakDataNew {
        uint8 spinStreakOne;
        uint8 spinStreakTwo;
        uint8 spinStreakTemp;
        uint8 spinStreakStopOne;
        uint8 spinStreakStopTwo;
        uint8 spinStreakStopTemp;
    }

    /* State Variables */

    VRFCoordinatorV2Interface private immutable i_vrfCoordinator;
    bytes32 private immutable i_gasLane;
    uint64 private immutable i_subscriptionId;
    uint32 private immutable i_callbackGasLimit;
    uint16 private immutable i_startingStoredWords; // must be 16 because we pass to VRF
    uint16 private immutable i_startingStoredNumbers;
    uint16 private immutable i_refreshStoredSpinsLength;
    uint16 private immutable i_startingStoredSpinsLength;

    uint8 private constant NUM_REELS = 5;
    uint8 private constant NUM_STOPS = 12;
    uint8 private constant SPINS_PER_BUY = 10;
    uint8 private constant NUM_WORDS_PER_BUY = 50; // NUM_REELS * SPINS_PER_BUY
    uint8 private constant REQUEST_CONFIRMATIONS = 3; // 3 is minimum for mainnet per docs.chain.link/docs/vrf-contracts
    uint8 private constant LUCKY_STOP_DIGIT = 4;
    uint8 private constant STOPS_TO_WIN = 2;

    uint256 private constant PAYOUT_WEI = 129032258064516;
    uint256 private constant LUCKY_PAYOUT_WEI = 258064516129032;

    // win types:
    // 0: none
    // 1: 2x
    // 2: 3x
    // 3: 4x
    // 4: 5x
    // 5: 2x2
    // 6: 2x3
    // 7: doge 2x
    // 8: doge 3x
    // 9: doge 4x
    // 10: doge 5x
    // 11: doge 2x2x
    // 12: doge 3x other 2x
    // 13: doge 2x other 3x

    uint256 private constant PAYOUTS_WEI_1 = 129032258064516;
    uint256 private constant PAYOUTS_WEI_2 = 322580645161290;
    uint256 private constant PAYOUTS_WEI_3 = 1290322580645160;
    uint256 private constant PAYOUTS_WEI_4 = 12903225806451600;
    uint256 private constant PAYOUTS_WEI_5 = 387096774193548;
    uint256 private constant PAYOUTS_WEI_6 = 1290322580645160;
    uint256 private constant PAYOUTS_WEI_7 = 258064516129032;
    uint256 private constant PAYOUTS_WEI_8 = 1290322580645160;
    uint256 private constant PAYOUTS_WEI_9 = 3870967741935480;
    uint256 private constant PAYOUTS_WEI_10 = 64516129032258100;
    uint256 private constant PAYOUTS_WEI_11 = 967741935483871;
    uint256 private constant PAYOUTS_WEI_12 = 3225806451612900;
    uint256 private constant PAYOUTS_WEI_13 = 2580645161290320;

    // uint256[] private constant PAYOUTS_WEI = [
    //     0, // 0
    //     129032258064516, // 1
    //     322580645161290, // 2
    //     1290322580645160, // 3
    //     12903225806451600, // 4
    //     387096774193548, // 5
    //     1290322580645160, // 6
    //     258064516129032, // 7
    //     1096774193548390, // 8
    //     3870967741935480, // 9
    //     64516129032258100, // 10
    //     967741935483871, // 11
    //     3225806451612900, // 12
    //     2580645161290320 // 13
    // ];

    uint256 private constant BUY_SPINS_WEI = 645161290322581; // spins per buy * entrance fee wei
    uint256 private constant ENTRANCE_FEE_WEI = 64516129032258;
    uint256 private constant PAYOUT_CUSHION = 64516129032258100; // using 1 5x doge (lucky_payout * 10 ** 3). this should really be equal to the max payout * 10 since someone could theoretically hit 10 5x doeges in a row...
    uint8 private constant DIGITS_PER_WORD = 76;
    uint8 private constant NUMBERS_PER_WORD = 38; // VRF gives you a random number with at least 76 digits. From this we can extract 38 unique numbers.

    uint8[] private s_winTypes;
    uint8[] private s_winStopsOne;
    uint8[] private s_winStopsTwo;
    // uint256[] private s_payouts;
    uint8[] private s_words;
    uint256 private s_totalOwed = 0;
    bool private s_vrfRequesting = false;
    uint256 private s_lastRequestId;
    uint256[] private s_payoutsWei;

    mapping(address => uint256) private s_playerBalance; // this is total balance from current and prior sessions. e.g., if someone won 3 times but refreshed the page and bought
    mapping(address => uint8[]) private s_playerWinsArray;
    mapping(address => uint8[]) private s_playerStopsOneArray;
    mapping(address => uint8[]) private s_playerStopsTwoArray;
    mapping(address => uint8[]) private s_playerSpins;

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
            i_refreshStoredSpinsLength =
                (refreshStoredWords * uint16(NUMBERS_PER_WORD)) /
                uint16(NUM_REELS);
            i_startingStoredSpinsLength =
                (startingStoredWords * uint16(NUMBERS_PER_WORD)) /
                uint16(NUM_REELS);
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
        bool needsWords = s_winTypes.length <= i_refreshStoredSpinsLength;
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
        s_lastRequestId = requestId;
        s_vrfRequesting = true;
        emit RequestedMoreSpins(requestId);
    }

    function fulfillRandomWords(uint256, uint256[] memory randomWords) internal override {
        uint16 startingStoredSpinsLength = i_startingStoredSpinsLength;
        uint8[] memory winTypes = new uint8[](startingStoredSpinsLength);
        uint8[] memory winStopsOne = new uint8[](startingStoredSpinsLength);
        uint8[] memory winStopsTwo = new uint8[](startingStoredSpinsLength);
        // uint256[] memory payouts = new uint256[](startingStoredSpinsLength);
        uint8[] memory numbers = new uint8[](i_startingStoredNumbers);
        uint16 digitIdx;
        for (uint16 i = 0; i < startingStoredSpinsLength; ) {
            // uint16 randomWordsIdx;
            uint16 randomNumberIdx;
            uint8 randNumber;
            // uint8[] memory spinNumbers = new uint8[](NUM_REELS);
            SpinStreakDataNew memory spinStreak = SpinStreakDataNew(0, 0, 0, 99, 99, 99);
            for (uint16 j = 0; j < NUM_REELS; ) {
                // first step is to convert the 2 digit number we pulled from the random word into a number 0-11, and add to the numbesr array
                unchecked {
                    randomNumberIdx = (i * NUM_REELS + j);
                    // randomWordsIdx = randomNumberIdx / NUMBERS_PER_WORD;

                    digitIdx = DIGITS_PER_WORD - ((randomNumberIdx * 2) % (NUMBERS_PER_WORD * 2));
                    randNumber = uint8(
                        ((randomWords[randomNumberIdx / NUMBERS_PER_WORD] % (10**(digitIdx + 1))) /
                            // ((randomWords[randomWordsIdx] % (10**(digitIdx + 1))) /
                            (10**(digitIdx + 1 - 2))) % NUM_STOPS
                    );
                }

                numbers[randomNumberIdx] = randNumber;
                // spinNumbers[j] = randNumber;
                // evaluate reel
                // spinStreak = [spinStreakOne, spinStreakTwo, spinStreakTemp, spinStreakStopOne, spinStreakStopTwo, spinStreakStopTemp]

                // start by simply checking if the random number matches the most recent spin streak stop. It is initialized to 99 so it will not on first spin.
                if (randNumber == spinStreak.spinStreakStopTemp) {
                    unchecked {
                        spinStreak.spinStreakTemp += 1;
                    }
                } else {
                    // check to make sure we don't need to solidify a prior spin streak, then reset the temp counters
                    if (spinStreak.spinStreakTemp >= 2) {
                        if (spinStreak.spinStreakOne == 0) {
                            spinStreak.spinStreakOne = spinStreak.spinStreakTemp;
                            spinStreak.spinStreakStopOne = spinStreak.spinStreakStopTemp;
                        } else if (spinStreak.spinStreakTwo == 0) {
                            spinStreak.spinStreakTwo = spinStreak.spinStreakTemp;
                            spinStreak.spinStreakStopTwo = spinStreak.spinStreakStopTemp;
                        }
                    }
                    spinStreak.spinStreakTemp = 1;
                    spinStreak.spinStreakStopTemp = randNumber;
                }

                if (j == NUM_REELS - 1) {
                    // logic for adding to spinStreakOne or Two at very end of iteration
                    if (spinStreak.spinStreakTemp >= 2) {
                        if (spinStreak.spinStreakOne == 0) {
                            spinStreak.spinStreakOne = spinStreak.spinStreakTemp;
                            spinStreak.spinStreakStopOne = spinStreak.spinStreakStopTemp;
                        } else if (spinStreak.spinStreakTwo == 0) {
                            spinStreak.spinStreakTwo = spinStreak.spinStreakTemp;
                            spinStreak.spinStreakStopTwo = spinStreak.spinStreakStopTemp;
                        }
                    }
                }

                unchecked {
                    j += 1;
                }
            }
            // check for winners
            // win types:
            // 0: none
            // 1: 2x
            // 2: 3x
            // 3: 4x
            // 4: 5x
            // 5: 2x2
            // 6: 2x3
            // 7: doge 2x
            // 8: doge 3x
            // 9: doge 4x
            // 10: doge 5x
            // 11: doge 2x2x
            // 12: doge 3x other 2x
            // 13: doge 2x other 3x

            if (spinStreak.spinStreakOne == 0) {
                winTypes[i] = 0;
                winStopsOne[i] = 99;
                winStopsTwo[i] = 99;
                // payouts[i] = 0;
            } else if (spinStreak.spinStreakTwo == 0) {
                if (spinStreak.spinStreakStopOne == LUCKY_STOP_DIGIT) {
                    winStopsOne[i] = LUCKY_STOP_DIGIT;
                    winStopsTwo[i] = 99;
                    if (spinStreak.spinStreakOne == 2) {
                        winTypes[i] = 7;
                        // payouts[i] = PAYOUTS_WEI_7;
                    } else if (spinStreak.spinStreakOne == 3) {
                        winTypes[i] = 8;
                        // payouts[i] = PAYOUTS_WEI_8;
                    } else if (spinStreak.spinStreakOne == 4) {
                        winTypes[i] = 9;
                        // payouts[i] = PAYOUTS_WEI_9;
                    } else if (spinStreak.spinStreakOne == 5) {
                        winTypes[i] = 10;
                        // payouts[i] = PAYOUTS_WEI_10;
                    }
                } else {
                    winStopsOne[i] = spinStreak.spinStreakStopOne;
                    winStopsTwo[i] = 99;
                    if (spinStreak.spinStreakOne == 2) {
                        winTypes[i] = 1;
                        // payouts[i] = PAYOUTS_WEI_1;
                    } else if (spinStreak.spinStreakOne == 3) {
                        winTypes[i] = 2;
                        // payouts[i] = PAYOUTS_WEI_2;
                    } else if (spinStreak.spinStreakOne == 4) {
                        winTypes[i] = 3;
                        // payouts[i] = PAYOUTS_WEI_3;
                    } else if (spinStreak.spinStreakOne == 5) {
                        winTypes[i] = 4;
                        // payouts[i] = PAYOUTS_WEI_4;
                    }
                }
            } else {
                // this means there's both a spin streak one and a spin streak two. so can be 2x2 or 2x3
                winStopsOne[i] = spinStreak.spinStreakStopOne;
                winStopsTwo[i] = spinStreak.spinStreakStopTwo;
                if (
                    // 3x2 doge
                    (spinStreak.spinStreakStopOne == LUCKY_STOP_DIGIT &&
                        spinStreak.spinStreakOne == 3) ||
                    (spinStreak.spinStreakStopTwo == LUCKY_STOP_DIGIT &&
                        spinStreak.spinStreakTwo == 3)
                ) {
                    winTypes[i] = 12;
                    // payouts[i] = PAYOUTS_WEI_12;
                } else if (
                    // 2 doge x 3 other
                    (spinStreak.spinStreakStopOne == LUCKY_STOP_DIGIT &&
                        spinStreak.spinStreakTwo == 3) ||
                    (spinStreak.spinStreakStopTwo == LUCKY_STOP_DIGIT &&
                        spinStreak.spinStreakOne == 3)
                ) {
                    winTypes[i] = 13;
                    // payouts[i] = PAYOUTS_WEI_13;
                } else if (
                    // 3x2 no doge
                    spinStreak.spinStreakStopOne != LUCKY_STOP_DIGIT &&
                    spinStreak.spinStreakStopTwo != LUCKY_STOP_DIGIT &&
                    (spinStreak.spinStreakOne == 3 || spinStreak.spinStreakTwo == 3)
                ) {
                    winTypes[i] = 6;
                    // payouts[i] = PAYOUTS_WEI_6;
                } else if (
                    spinStreak.spinStreakStopOne == LUCKY_STOP_DIGIT ||
                    spinStreak.spinStreakStopTwo == LUCKY_STOP_DIGIT
                ) {
                    winTypes[i] = 11;
                    // payouts[i] = PAYOUTS_WEI_11;
                } else {
                    winTypes[i] = 5;
                    // payouts[i] = PAYOUTS_WEI_5;
                }
            }
            unchecked {
                i += 1;
            }
        }
        s_winTypes = winTypes;
        s_winStopsOne = winStopsOne;
        s_winStopsTwo = winStopsTwo;
        // s_payouts = payouts;
        s_words = numbers;

        // console.log("WINTYPE LENGTH:", winTypes.length);

        s_vrfRequesting = false;
        emit RandomWordsReceived();
    }

    // function fulfillRandomWordsOld(
    //     uint256, /*requestId passed by the external vrf operator*/
    //     uint256[] memory randomWords // the array of randomWords sent
    // ) internal override {
    //     uint16 startingStoredSpinsLength = i_startingStoredSpinsLength;
    //     uint8[] memory winTypes = new uint8[](startingStoredSpinsLength);
    //     uint8[] memory winStops = new uint8[](startingStoredSpinsLength);
    //     uint256[] memory payouts = new uint256[](startingStoredSpinsLength);
    //     uint8[] memory numbers = new uint8[](i_startingStoredNumbers);
    //     uint16 digitIdx;
    //     for (uint16 i = 0; i < startingStoredSpinsLength; ) {
    //         uint16 randomWordsIdx;
    //         uint16 randomNumberIdx;
    //         uint8 randNumber;
    //         SpinStreakData memory spinStreak = SpinStreakData(0, 0, 99, 99, 0, 0);
    //         for (uint16 j = 0; j < NUM_REELS; ) {
    //             // first step is to convert the 2 digit number we pulled from the random word into a number 0-11, and add to the numbesr array
    //             unchecked {
    //                 randomNumberIdx = (i * NUM_REELS + j);
    //                 randomWordsIdx = randomNumberIdx / NUMBERS_PER_WORD;

    //                 digitIdx = DIGITS_PER_WORD - ((randomNumberIdx * 2) % (NUMBERS_PER_WORD * 2));
    //                 randNumber = uint8(
    //                     ((randomWords[randomWordsIdx] % (10**(digitIdx + 1))) /
    //                         (10**(digitIdx + 1 - 2))) % NUM_STOPS
    //                 );
    //             }

    //             numbers[randomNumberIdx] = randNumber;

    //             // evaluate reel
    //             if (randNumber == LUCKY_STOP_DIGIT) {
    //                 unchecked {
    //                     spinStreak.luckySpinStreakTemp += 1;
    //                 }
    //                 if (spinStreak.luckySpinStreakTemp > spinStreak.luckySpinStreak) {
    //                     spinStreak.luckySpinStreak = spinStreak.luckySpinStreakTemp;
    //                 }
    //             } else {
    //                 spinStreak.luckySpinStreakTemp = 0;
    //                 if (randNumber == spinStreak.spinStreakStopTemp) {
    //                     unchecked {
    //                         spinStreak.spinStreakTemp += 1;
    //                     }
    //                     if (spinStreak.spinStreakTemp > spinStreak.spinStreak) {
    //                         spinStreak.spinStreak = spinStreak.spinStreakTemp;
    //                         spinStreak.spinStreakStop = spinStreak.spinStreakStopTemp;
    //                     }
    //                 } else {
    //                     spinStreak.spinStreakTemp = 1;
    //                     spinStreak.spinStreakStopTemp = randNumber;
    //                 }
    //             }
    //             unchecked {
    //                 j += 1;
    //             }
    //         }

    //         // check for winners
    //         if (spinStreak.luckySpinStreak > 1) {
    //             winTypes[i] = spinStreak.luckySpinStreak;
    //             winStops[i] = LUCKY_STOP_DIGIT;
    //             payouts[i] = LUCKY_PAYOUT_WEI * 10**(spinStreak.luckySpinStreak - 2);
    //         } else if (spinStreak.spinStreak > 1) {
    //             winTypes[i] = 1;
    //             winStops[i] = spinStreak.spinStreakStop;
    //             payouts[i] = PAYOUT_WEI;
    //         } else {
    //             winTypes[i] = 0;
    //             winStops[i] = 99;
    //             payouts[i] = 0;
    //         }
    //         unchecked {
    //             i += 1;
    //         }
    //     }
    //     s_winTypes = winTypes;
    //     s_winStopsOne = winStops;
    //     s_payouts = payouts;
    //     s_words = numbers;

    //     // console.log("WINTYPE LENGTH:", winTypes.length);

    //     s_vrfRequesting = false;
    //     emit RandomWordsReceived();
    // }

    function buySpins() public payable {
        // check for reverts
        if (msg.value < BUY_SPINS_WEI) {
            revert Slot__NotEnoughEthEntered(msg.sender, msg.value, ENTRANCE_FEE_WEI);
        }
        if (address(this).balance < PAYOUT_CUSHION) {
            revert Slot__MachineEmpty(address(this).balance, PAYOUT_WEI);
        }
        if (s_words.length < 50) {
            revert Slot__NeedMoreSpins();
        }

        uint8[] memory playerWins = new uint8[](SPINS_PER_BUY);
        uint8[] memory playerStopsOne = new uint8[](SPINS_PER_BUY);
        uint8[] memory playerStopsTwo = new uint8[](SPINS_PER_BUY);
        uint256 playerSinglePayout = 0;
        uint256 playerPayout = 0;
        uint8[] memory playerSpins = new uint8[](uint16(NUM_REELS * SPINS_PER_BUY));

        uint16 startingSpinsIdx = uint16(s_winTypes.length) - 1;
        uint16 startingWordsIdx = uint16(s_words.length) - 1;

        uint16 spinIdx;
        uint16 wordIdx;
        uint16 playerWordsIdx;
        uint8[] memory winTypes = s_winTypes;

        for (uint16 i = 0; i < SPINS_PER_BUY; ) {
            if (winTypes[spinIdx] == 1) {
                playerSinglePayout = PAYOUTS_WEI_1;
            } else if (winTypes[spinIdx] == 2) {
                playerSinglePayout = PAYOUTS_WEI_2;
            } else if (winTypes[spinIdx] == 3) {
                playerSinglePayout = PAYOUTS_WEI_3;
            } else if (winTypes[spinIdx] == 4) {
                playerSinglePayout = PAYOUTS_WEI_4;
            } else if (winTypes[spinIdx] == 5) {
                playerSinglePayout = PAYOUTS_WEI_5;
            } else if (winTypes[spinIdx] == 6) {
                playerSinglePayout = PAYOUTS_WEI_6;
            } else if (winTypes[spinIdx] == 7) {
                playerSinglePayout = PAYOUTS_WEI_7;
            } else if (winTypes[spinIdx] == 8) {
                playerSinglePayout = PAYOUTS_WEI_8;
            } else if (winTypes[spinIdx] == 9) {
                playerSinglePayout = PAYOUTS_WEI_9;
            } else if (winTypes[spinIdx] == 10) {
                playerSinglePayout = PAYOUTS_WEI_10;
            } else if (winTypes[spinIdx] == 11) {
                playerSinglePayout = PAYOUTS_WEI_11;
            } else if (winTypes[spinIdx] == 12) {
                playerSinglePayout = PAYOUTS_WEI_12;
            } else if (winTypes[spinIdx] == 13) {
                playerSinglePayout = PAYOUTS_WEI_13;
            } else {
                playerSinglePayout = 0;
            }
            unchecked {
                spinIdx = startingSpinsIdx - i;
                playerPayout += playerSinglePayout;
            }

            // console.log("Spin Idx (player spin idx is just i):", spinIdx);

            playerWins[i] = s_winTypes[spinIdx];
            playerStopsOne[i] = s_winStopsOne[spinIdx];
            playerStopsTwo[i] = s_winStopsTwo[spinIdx];

            for (uint16 j = 0; j < NUM_REELS; ) {
                unchecked {
                    wordIdx = startingWordsIdx - i * NUM_REELS - j;
                    playerWordsIdx = i * NUM_REELS + j;
                }

                // console.log("Word Idx and Player Words Idx", wordIdx, playerWordsIdx);

                playerSpins[playerWordsIdx] = s_words[wordIdx];
                s_words.pop();

                unchecked {
                    j += 1;
                }
            }
            s_winTypes.pop();
            s_winStopsOne.pop();
            s_winStopsTwo.pop();
            // s_payouts.pop();

            unchecked {
                i += 1;
            }
        }

        s_playerWinsArray[msg.sender] = playerWins;
        s_playerStopsOneArray[msg.sender] = playerStopsOne;
        s_playerStopsTwoArray[msg.sender] = playerStopsTwo;
        s_playerSpins[msg.sender] = playerSpins;
        s_playerBalance[msg.sender] += playerPayout;
    }

    // function buySpinsOld() public payable {
    //     // check for reverts
    //     if (msg.value < BUY_SPINS_WEI) {
    //         revert Slot__NotEnoughEthEntered(msg.sender, msg.value, BUY_SPINS_WEI);
    //     }
    //     if (address(this).balance < PAYOUT_CUSHION) {
    //         revert Slot__MachineEmpty(address(this).balance, PAYOUT_WEI);
    //     }
    //     if (s_words.length < 50) {
    //         revert Slot__NeedMoreSpins();
    //     }

    //     uint8[] memory playerWins = new uint8[](SPINS_PER_BUY);
    //     uint8[] memory playerStops = new uint8[](SPINS_PER_BUY);
    //     uint256 playerPayout = 0;
    //     uint8[] memory playerSpins = new uint8[](uint16(NUM_REELS * SPINS_PER_BUY));

    //     uint16 startingSpinsIdx = uint16(s_payouts.length) - 1;
    //     uint16 startingWordsIdx = uint16(s_words.length) - 1;

    //     // console.log("SPINS LENGTH:", startingSpinsIdx);
    //     // console.log("WORDS LENGTH:", startingWordsIdx);

    //     uint16 spinIdx;
    //     uint16 wordIdx;
    //     uint16 playerWordsIdx;

    //     for (uint16 i = 0; i < SPINS_PER_BUY; ) {
    //         unchecked {
    //             spinIdx = startingSpinsIdx - i;
    //             playerPayout += s_payouts[spinIdx];
    //         }

    //         // console.log("Spin Idx (player spin idx is just i):", spinIdx);

    //         playerWins[i] = s_winTypes[spinIdx];
    //         playerStops[i] = s_winStopsOne[spinIdx];

    //         for (uint16 j = 0; j < NUM_REELS; ) {
    //             unchecked {
    //                 wordIdx = startingWordsIdx - i * NUM_REELS - j;
    //                 playerWordsIdx = i * NUM_REELS + j;
    //             }

    //             // console.log("Word Idx and Player Words Idx", wordIdx, playerWordsIdx);

    //             playerSpins[playerWordsIdx] = s_words[wordIdx];
    //             s_words.pop();

    //             unchecked {
    //                 j += 1;
    //             }
    //         }
    //         s_winTypes.pop();
    //         s_winStopsOne.pop();
    //         s_payouts.pop();

    //         unchecked {
    //             i += 1;
    //         }
    //     }

    //     s_playerWinsArray[msg.sender] = playerWins;
    //     s_playerStopsOneArray[msg.sender] = playerStops;
    //     s_playerSpins[msg.sender] = playerSpins;
    //     s_playerBalance[msg.sender] += playerPayout;
    // }

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

    /* Getter Functions */
    function getRemainingWords() public view returns (uint16) {
        return uint16(s_words.length);
        // return s_storedRandomWords.length - s_storedWordsIdx;
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

    function getPayout() public pure returns (uint256) {
        return PAYOUT_WEI;
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

    // function getLuckyPayout() public pure returns (uint256) {
    //     return LUCKY_PAYOUT_WEI;
    // }

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