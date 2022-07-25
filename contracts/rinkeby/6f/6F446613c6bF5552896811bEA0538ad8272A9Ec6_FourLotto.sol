//SPDX-License-Identifier: MIT

/* pragma statement */
pragma solidity ^0.8.7;

/* import statements */
import "@chainlink/contracts/src/v0.8/VRFConsumerBaseV2.sol";
import "@chainlink/contracts/src/v0.8/interfaces/VRFCoordinatorV2Interface.sol";
import "@chainlink/contracts/src/v0.8/interfaces/KeeperCompatibleInterface.sol";
import "@openzeppelin/contracts/utils/Strings.sol";

/* custom errors */
error FourLotto__OnlyOwnerCanCallThisFunction();
error FourLotto__NoFunctionCalled();
error FourLotto__UnknownFunctionCalled();
error FourLotto__FourLottoNotOpen();
error FourLotto__InvalidBet(string invalidBet);
error FourLotto__NumberAlreadyTaken(string currentNumber);
error FourLotto__SendMoreToFundBet(uint256 ethAmountRequired);
error FourLotto__PlayerHasAlreadyEntered(string betPlacedByPlayer);
error FourLotto__UpkeepNotNeeded(
    uint256 FourLottoState,
    uint256 numPlayers,
    uint256 currentBalance
);
error FourLotto__ReentrancyDetected();
error FourLotto__PaymentToFirstPlaceWinnerFailed(address payable addressOfFirstPlaceWinner);
error FourLotto__PaymentToSecondPlaceWinnerFailed(address payable addressOfSecondPlaceWinner);
error FourLotto__PaymentToThirdPlaceWinnerFailed(address payable addressOfThirdPlaceWinner);
error FourLotto__PaymentToConsolationWinnerFailed(address payable addressOfConsolationWinner);
error FourLotto__TaxToOwnerFailed();
error FourLotto__WithdrawToOwnerFailed();
error FourLotto__DistributionToCurrentPlayersFailed(address payable addressOfCurrentPlayer);
error FourLotto__NoPotAndThereforeNoNeedToCloseFourLotto();
error FourLotto__FourLottoAlreadyOperating();
error FourLotto__UnableToRemoveHistory(uint256 drawNumber);
error FourLotto__DrawDidNotOccur(uint256 drawNumber);

/** @title FourLotto lottery smart contract
 *  @author Aesthetyx
 *  @notice This contract is for creating an untamperable decentralised smart contract lottery inspired by the 4D lottery in Singapore
 *  @dev This implements Chainlink VRF v2 to obtain random numbers that will be used to determine the winning number, and Chainlink Keepers to automatically draw a winning number periodically

 */

contract FourLotto is VRFConsumerBaseV2, KeeperCompatibleInterface {
    /* type declarations */
    enum FourLottoState {
        OPEN,
        CALCULATING,
        PAYING,
        PAUSING,
        PAUSED
    }

    /* state variables */
    // chainlink VRF Variables
    VRFCoordinatorV2Interface private immutable i_vrfCoordinator;
    uint64 private immutable i_subscriptionId;
    bytes32 private immutable i_gasLane;
    uint32 private immutable i_callbackGasLimit;
    uint16 private constant REQUEST_CONFIRMATIONS = 5;
    uint32 private constant NUM_WORDS = 41;

    // FourLotto operation variables
    address payable private immutable i_owner;
    uint256 private immutable i_interval;
    uint256 private s_lastTimeStamp;
    uint256 private immutable i_betFee;
    uint256 private s_drawNumber = 1;
    FourLottoState private s_fourLottoState;

    // player and bet management variables
    mapping(uint256 => address payable[]) s_players;
    mapping(uint256 => string[]) s_bets;
    struct Details {
        bool isValid;
        string bet;
        address payable playerAddress;
    }
    mapping(bytes32 => Details) s_betDetails;
    mapping(bytes32 => Details) s_playerDetails;

    // winning number variables
    string[] private s_recentWinningNumbers;
    address payable[] private s_recentFirstPlaceWinner;
    address payable[] private s_recentSecondPlaceWinners;
    address payable[] private s_recentThirdPlaceWinners;
    address payable[] private s_recentConsolationWinners;
    uint256[][] private s_winningNumbersOrderArray = [
        [1, 2, 3, 4],
        [1, 2, 4, 3],
        [1, 3, 2, 4],
        [1, 3, 4, 2],
        [1, 4, 2, 3],
        [1, 4, 3, 2],
        [2, 1, 3, 4],
        [2, 1, 4, 3],
        [2, 3, 1, 4],
        [2, 3, 4, 1],
        [2, 4, 1, 3],
        [2, 4, 3, 1],
        [3, 1, 2, 4],
        [3, 1, 4, 2],
        [3, 2, 1, 4],
        [3, 2, 4, 1],
        [3, 4, 1, 2],
        [3, 4, 2, 1],
        [4, 1, 2, 3],
        [4, 1, 3, 2],
        [4, 2, 1, 3],
        [4, 2, 3, 1],
        [4, 3, 1, 2],
        [4, 3, 2, 1]
    ];

    /* events */
    event FourLottoEntered(string indexed playerBet, address indexed player);
    event WinningNumberRequested(uint256 indexed requestId);
    event DrawCompleted(string[] indexed recentWinningNumbers);

    modifier onlyOwner() {
        if (msg.sender != i_owner) revert FourLotto__OnlyOwnerCanCallThisFunction();
        _;
    }

    /* functions */
    // constructor
    constructor(
        address payable ownerAddress,
        address vrfCoordinatorV2,
        uint64 subscriptionId,
        bytes32 gasLane, // keyHash
        uint256 interval,
        uint256 betFee,
        uint32 callbackGasLimit
    ) VRFConsumerBaseV2(vrfCoordinatorV2) {
        i_owner = ownerAddress;
        i_vrfCoordinator = VRFCoordinatorV2Interface(vrfCoordinatorV2);
        i_gasLane = gasLane;
        i_interval = interval;
        i_subscriptionId = subscriptionId;
        i_betFee = betFee;
        s_fourLottoState = FourLottoState.OPEN;
        s_lastTimeStamp = block.timestamp;
        i_callbackGasLimit = callbackGasLimit;
    }

    // receive function
    receive() external payable {
        revert FourLotto__NoFunctionCalled();
    }

    // fallback function
    fallback() external payable {
        revert FourLotto__UnknownFunctionCalled();
    }

    // public functions
    function enterFourLotto(string memory _playerBet) public payable {
        // consider if there is a need for an additional enum to prevent a scenario where players bet on the same numbers at the same instant

        // revert if FourLotto lottery is calculating or closed
        if (s_fourLottoState != FourLottoState.OPEN) {
            revert FourLotto__FourLottoNotOpen();
        }
        // revert if non four digit number is entered by player
        if (bytes(_playerBet).length != 4) {
            revert FourLotto__InvalidBet(_playerBet);
        }
        // revert if number has already been bet on by another player or if player has already placed a bet for current draw
        if (getCurrentBetDetails(_playerBet).isValid == true) {
            revert FourLotto__NumberAlreadyTaken(_playerBet);
        }
        // revert if player has already placed a bet for current draw
        if (getCurrentPlayerDetails(msg.sender).isValid == true) {
            revert FourLotto__PlayerHasAlreadyEntered(getCurrentPlayerDetails(msg.sender).bet);
        }
        // revert if insufficient ETH is transferred to fund bet
        if (msg.value < i_betFee) {
            revert FourLotto__SendMoreToFundBet(i_betFee);
        }
        // store player and bet in list of players and bets
        uint256 drawNumber = s_drawNumber;
        s_players[drawNumber].push(payable(msg.sender));
        s_bets[drawNumber].push(_playerBet);

        // store player and bet in mappings
        bytes32 betMappingKey = keccak256(abi.encode(drawNumber, _playerBet));
        s_betDetails[betMappingKey] = Details(true, _playerBet, payable(msg.sender));
        bytes32 playerMappingKey = keccak256(abi.encode(drawNumber, msg.sender));
        s_playerDetails[playerMappingKey] = Details(true, _playerBet, payable(msg.sender));

        // emit FourLottoEntered event
        emit FourLottoEntered(_playerBet, msg.sender);
    }

    /**
     * @dev This is the function that the Chainlink Keeper nodes calls.
     * they look for `upkeepNeeded` to return true.
     * the following should be true for upkeepNeeded to return true:
     * 1. The time interval has passed between FourLotto draws.
     * 2. FourLotto is open.
     * 3. The contract has ETH balance (and has players).
     * 4. Implicity, your subscription is funded with LINK.
     */
    function checkUpkeep(
        bytes memory /* checkData */
    )
        public
        view
        override
        returns (
            bool upkeepNeeded,
            bytes memory /* performData */
        )
    {
        bool isOpen = (s_fourLottoState == FourLottoState.OPEN);
        bool timePassed = ((block.timestamp - s_lastTimeStamp) > i_interval);
        bool hasPlayers = s_players[s_drawNumber].length > 0;
        upkeepNeeded = (isOpen && timePassed && hasPlayers);
    }

    /**
     * @dev Once `checkUpkeep` is returning `true`, this function is called and it kicks off a Chainlink VRF call to get a random winner.
     */
    function performUpkeep(
        bytes calldata /* performData */
    ) external override {
        (bool upkeepNeeded, ) = checkUpkeep("");
        if (!upkeepNeeded) {
            revert FourLotto__UpkeepNotNeeded(
                uint256(s_fourLottoState),
                s_players[s_drawNumber].length,
                address(this).balance
            );
        }
        s_fourLottoState = FourLottoState.CALCULATING;
        uint256 requestId = i_vrfCoordinator.requestRandomWords(
            i_gasLane,
            i_subscriptionId,
            REQUEST_CONFIRMATIONS,
            i_callbackGasLimit,
            NUM_WORDS
        );
        emit WinningNumberRequested(requestId); // here for the purpose of conducting unit tests
    }

    /**
     * @dev This is the function that Chainlink VRF node calls to send the money to the random winner.
     */
    function fulfillRandomWords(
        uint256, /* requestId */
        uint256[] memory randomWords
    ) internal override {
        // block of code to prevent re-entrancy
        if (s_fourLottoState != FourLottoState.CALCULATING) {
            revert FourLotto__ReentrancyDetected();
        }
        s_fourLottoState = FourLottoState.PAYING;
        // reset previous winning numbers
        s_recentWinningNumbers = new string[](0);
        // determine winning numbers
        uint256[] memory orderOfWinningNumber = s_winningNumbersOrderArray[(randomWords[0] % 24)];
        for (uint256 i = 0; i < 10; i++) {
            string memory winningNumber = string(
                abi.encodePacked(
                    Strings.toString(randomWords[(orderOfWinningNumber[0] + (i * 4))] % 10),
                    Strings.toString(randomWords[(orderOfWinningNumber[1] + (i * 4))] % 10),
                    Strings.toString(randomWords[(orderOfWinningNumber[2] + (i * 4))] % 10),
                    Strings.toString(randomWords[(orderOfWinningNumber[3] + (i * 4))] % 10)
                )
            );
            // save winning numbers into array
            s_recentWinningNumbers.push(winningNumber);
        }

        // identify and pay winnings to winners, and transfer tax to owner
        string[] memory recentWinningNumbers = s_recentWinningNumbers;
        uint256 currentPot;
        // limit total available winnings to 100ETH to prevent gaming the lottery
        if (address(this).balance > 1e20) {
            currentPot = 1e20;
        } else {
            currentPot = address(this).balance;
        }
        uint256 drawNumber = s_drawNumber;
        address payable owner = i_owner;
        // first place (1 winner) - 40% before tax
        //reset s_recentFirstPlaceWinner
        s_recentFirstPlaceWinner = new address payable[](0);
        if (
            s_betDetails[keccak256(abi.encode(drawNumber, recentWinningNumbers[0]))].isValid == true
        ) {
            // save address of first place winner into s_recentFirstPlaceWinner
            s_recentFirstPlaceWinner.push(
                s_betDetails[keccak256(abi.encode(drawNumber, recentWinningNumbers[0]))]
                    .playerAddress
            );
            // pay first place winner
            (bool playerCallSuccess, ) = s_recentFirstPlaceWinner[0].call{
                value: ((currentPot * 40 * 95) / 100) / 100
            }("");
            if (!playerCallSuccess) {
                revert FourLotto__PaymentToFirstPlaceWinnerFailed(s_recentFirstPlaceWinner[0]);
            }
            // pay tax to owner
            (bool ownerCallSuccess, ) = owner.call{value: ((currentPot * 40 * 5) / 100) / 100}("");
            if (!ownerCallSuccess) {
                revert FourLotto__TaxToOwnerFailed();
            }
        }

        // second place (2 winners) - 30% before tax
        // reset s_recentSecondPlaceWinners
        s_recentSecondPlaceWinners = new address payable[](0);
        for (uint256 i = 1; i < 3; i++) {
            if (
                s_betDetails[keccak256(abi.encode(drawNumber, recentWinningNumbers[i]))].isValid ==
                true
            ) {
                s_recentSecondPlaceWinners.push(
                    s_betDetails[keccak256(abi.encode(drawNumber, recentWinningNumbers[i]))]
                        .playerAddress
                );
            }
        }
        address payable[] memory recentSecondPlaceWinners = s_recentSecondPlaceWinners;
        // pay second place winners
        if (recentSecondPlaceWinners.length > 0) {
            for (uint256 i = 0; i < recentSecondPlaceWinners.length; i++) {
                (bool playerCallSuccess, ) = recentSecondPlaceWinners[i].call{
                    value: ((currentPot * 30 * 95) / 100) / 100 / recentSecondPlaceWinners.length
                }("");
                if (!playerCallSuccess) {
                    revert FourLotto__PaymentToSecondPlaceWinnerFailed(recentSecondPlaceWinners[i]);
                }
            }
            // pay tax to owner
            (bool ownerCallSuccess, ) = owner.call{value: ((currentPot * 30 * 5) / 100) / 100}("");
            if (!ownerCallSuccess) {
                revert FourLotto__TaxToOwnerFailed();
            }
        }

        // third place (3 winners) - 20% before tax
        // reset s_recentThirdPlaceWinners
        s_recentThirdPlaceWinners = new address payable[](0);
        for (uint256 i = 3; i < 6; i++) {
            if (
                s_betDetails[keccak256(abi.encode(drawNumber, recentWinningNumbers[i]))].isValid ==
                true
            ) {
                s_recentThirdPlaceWinners.push(
                    s_betDetails[keccak256(abi.encode(drawNumber, recentWinningNumbers[i]))]
                        .playerAddress
                );
            }
        }
        address payable[] memory recentThirdPlaceWinners = s_recentThirdPlaceWinners;
        // pay third place winners
        if (recentThirdPlaceWinners.length > 0) {
            for (uint256 i = 0; i < recentThirdPlaceWinners.length; i++) {
                (bool playerCallSuccess, ) = recentThirdPlaceWinners[i].call{
                    value: ((currentPot * 20 * 95) / 100) / 100 / recentThirdPlaceWinners.length
                }("");
                if (!playerCallSuccess) {
                    revert FourLotto__PaymentToThirdPlaceWinnerFailed(recentThirdPlaceWinners[i]);
                }
            }
            // pay tax to owner
            (bool ownerCallSuccess, ) = owner.call{value: ((currentPot * 20 * 5) / 100) / 100}("");
            if (!ownerCallSuccess) {
                revert FourLotto__TaxToOwnerFailed();
            }
        }

        // consolation (4 winners) - 10% before tax
        // reset s_recentConsolationWinners
        s_recentConsolationWinners = new address payable[](0);
        for (uint256 i = 6; i < 10; i++) {
            if (
                s_betDetails[keccak256(abi.encode(drawNumber, recentWinningNumbers[i]))].isValid ==
                true
            ) {
                s_recentConsolationWinners.push(
                    s_betDetails[keccak256(abi.encode(drawNumber, recentWinningNumbers[i]))]
                        .playerAddress
                );
            }
        }
        address payable[] memory recentConsolationWinners = s_recentConsolationWinners;
        // pay consolation winners
        if (recentConsolationWinners.length > 0) {
            for (uint256 i = 0; i < recentConsolationWinners.length; i++) {
                (bool playerCallSuccess, ) = recentConsolationWinners[i].call{
                    value: ((currentPot * 10 * 95) / 100) / 100 / recentConsolationWinners.length
                }("");
                if (!playerCallSuccess) {
                    revert FourLotto__PaymentToThirdPlaceWinnerFailed(recentConsolationWinners[i]);
                }
            }
            // pay tax to owner
            (bool ownerCallSuccess, ) = owner.call{value: ((currentPot * 10 * 5) / 100) / 100}("");
            if (!ownerCallSuccess) {
                revert FourLotto__TaxToOwnerFailed();
            }
        }
        // +1 to s_drawNumber to "reset" all mappings
        s_drawNumber++;
        // set time of last draw to current time
        s_lastTimeStamp = block.timestamp;
        // set FourLotto back to open so players can once again join FourLotto
        s_fourLottoState = FourLottoState.OPEN;
        // emit DrawCompleted event
        emit DrawCompleted(recentWinningNumbers);
    }

    function pauseFourLotto() public onlyOwner {
        // block of code to prevent re-entrancy
        if (s_fourLottoState != FourLottoState.OPEN) {
            revert FourLotto__FourLottoNotOpen();
        }
        s_fourLottoState = FourLottoState.PAUSING;

        if (address(this).balance > 0) {
            address payable[] memory players = s_players[s_drawNumber];
            uint256 betFee = i_betFee;
            // refund all current players for bets placed
            for (uint256 i = 0; i < players.length; i++) {
                (bool playerCallSuccess, ) = players[i].call{value: betFee}("");
                if (!playerCallSuccess) {
                    revert FourLotto__DistributionToCurrentPlayersFailed(players[i]);
                }
            }
            // remainder extracted to owner
            (bool ownerCallSuccess, ) = i_owner.call{value: address(this).balance}("");
            if (!ownerCallSuccess) {
                revert FourLotto__WithdrawToOwnerFailed();
            }
            // +1 to s_drawNumber to "reset" all mappings
            s_drawNumber++;
            // set time of closure to current time
            s_lastTimeStamp = block.timestamp;
            // set FourLotto to paused so that players can no longer enter
            s_fourLottoState = FourLottoState.PAUSED;
        } else {
            revert FourLotto__NoPotAndThereforeNoNeedToCloseFourLotto();
        }
    }

    function resumeFourLotto() public onlyOwner {
        if (s_fourLottoState == FourLottoState.PAUSED) {
            s_fourLottoState = FourLottoState.OPEN;
        } else {
            revert FourLotto__FourLottoAlreadyOperating();
        }
        s_lastTimeStamp = block.timestamp;
    }

    // gas cost of removeHistoryOfAPastDraw is too high, but left here while figuring out how to lower gas cost
    // function removeHistoryOfAPastDraw(uint256 _drawNumber) public onlyOwner {
    //     if (_drawNumber >= s_drawNumber) {
    //         revert FourLotto__UnableToRemoveHistory(_drawNumber);
    //     }
    //     if (_drawNumber < 1) {
    //         revert FourLotto__DrawDidNotOccur(_drawNumber);
    //     }
    //     string[] memory bets = s_bets[_drawNumber];
    //     address payable[] memory players = s_players[_drawNumber];
    //     delete s_bets[_drawNumber];
    //     delete s_players[_drawNumber];
    //     for (uint256 i = 0; i < bets.length; i++) {
    //         delete s_betDetails[keccak256(abi.encode(_drawNumber, bets[i]))];
    //         delete s_playerDetails[keccak256(abi.encode(_drawNumber, players[i]))];
    //     }
    // }

    // view / pure functions
    // chainlink VRF variables
    function getVRFCoordinator() public view returns (VRFCoordinatorV2Interface) {
        return i_vrfCoordinator;
    }

    // KIV, unhide for the time being
    function getSubscriptionId() public view returns (uint64) {
        return i_subscriptionId;
    }

    function getGasLane() public view returns (bytes32) {
        return i_gasLane;
    }

    function getCallbackGasLimit() public view returns (uint32) {
        return i_callbackGasLimit;
    }

    function getRequestConfirmations() public pure returns (uint16) {
        return REQUEST_CONFIRMATIONS;
    }

    function getNumWords() public pure returns (uint32) {
        return NUM_WORDS;
    }

    // FourLotto operation variables
    function getOwner() public view returns (address) {
        return i_owner;
    }

    function getInterval() public view returns (uint256) {
        return i_interval;
    }

    function getLastTimeStamp() public view returns (uint256) {
        return s_lastTimeStamp;
    }

    function getBetFee() public view returns (uint256) {
        return i_betFee;
    }

    function getCurrentDrawNumber() public view returns (uint256) {
        return s_drawNumber;
    }

    function getFourLottoState() public view returns (FourLottoState) {
        return s_fourLottoState;
    }

    // pot size and lottery balance
    function getFourLottoBalance() public view returns (uint256) {
        return address(this).balance;
    }

    function getCurrentPot() public view returns (uint256) {
        uint256 currentPot;
        if (address(this).balance > 1e20) {
            currentPot = 1e20;
        } else (currentPot = address(this).balance);
        return currentPot;
    }

    function getPotentialFirstPlaceWinnings() public view returns (uint256) {
        uint256 currentPot = getCurrentPot();
        uint256 potentialFirstPlaceWinnings = (currentPot * 40 * 95) / 100 / 100;
        return potentialFirstPlaceWinnings;
    }

    function getPotentialSecondPlaceWinnings() public view returns (uint256) {
        uint256 currentPot = getCurrentPot();
        uint256 potentialSecondPlaceWinnings = (currentPot * 30 * 95) / 100 / 100;
        return potentialSecondPlaceWinnings;
    }

    function getPotentialThirdPlaceWinnings() public view returns (uint256) {
        uint256 currentPot = getCurrentPot();
        uint256 potentialThirdPlaceWinnings = (currentPot * 20 * 95) / 100 / 100;
        return potentialThirdPlaceWinnings;
    }

    function getPotentialConsolationWinnings() public view returns (uint256) {
        uint256 currentPot = getCurrentPot();
        uint256 potentialConsolationeWinnings = (currentPot * 10 * 95) / 100 / 100;
        return potentialConsolationeWinnings;
    }

    // player and bet management variables
    // KIV, unhide for the time being
    function getCurrentPlayers() public view returns (address payable[] memory) {
        return s_players[s_drawNumber];
    }

    function getNumberOfCurrentPlayers() public view returns (uint256) {
        return s_players[s_drawNumber].length;
    }

    // KIV, hidden for the time being
    // function getPastPlayers(uint256 _drawNumber) public view returns (address payable[] memory) {
    //     return s_players[_drawNumber];
    // }

    // KIV, unhide for the time being
    function getCurrentBets() public view returns (string[] memory) {
        return s_bets[s_drawNumber];
    }

    function getNumberOfCurrentBets() public view returns (uint256) {
        return s_bets[s_drawNumber].length;
    }

    // KIV, hidden for the time being
    // function getPastBets(uint256 _drawNumber) public view returns (string[] memory) {
    //     return s_bets[_drawNumber];
    // }

    function getCurrentPlayerDetails(address _playerAddress) public view returns (Details memory) {
        bytes32 key = keccak256(abi.encode(s_drawNumber, _playerAddress));
        return s_playerDetails[key];
    }

    // KIV, hidden for the time being
    // function getPastPlayerDetails(uint256 _drawNumber, address _playerAddress)
    //     public
    //     view
    //     returns (Details memory)
    // {
    //     bytes32 key = keccak256(abi.encode(_drawNumber, _playerAddress));
    //     return s_playerDetails[key];
    // }

    function getCurrentBetDetails(string memory _bet) public view returns (Details memory) {
        bytes32 key = keccak256(abi.encode(s_drawNumber, _bet));
        return s_betDetails[key];
    }

    // KIV, hidden for the time being
    // function getPastBetDetails(uint256 _drawNumber, string memory _bet)
    //     public
    //     view
    //     returns (Details memory)
    // {
    //     bytes32 key = keccak256(abi.encode(_drawNumber, _bet));
    //     return s_betDetails[key];
    // }

    // winning number variables
    function getRecentWinningNumbers() public view returns (string[] memory) {
        return s_recentWinningNumbers;
    }

    function getRecentFirstPlaceWinner() public view returns (address payable[] memory) {
        return s_recentFirstPlaceWinner;
    }

    function getRecentSecondPlaceWinners() public view returns (address payable[] memory) {
        return s_recentSecondPlaceWinners;
    }

    function getRecentThirdPlaceWinners() public view returns (address payable[] memory) {
        return s_recentThirdPlaceWinners;
    }

    function getRecentConsolationWinners() public view returns (address payable[] memory) {
        return s_recentConsolationWinners;
    }

    function getWinningNumbersOrderArray() public view returns (uint256[][] memory) {
        return s_winningNumbersOrderArray;
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
// OpenZeppelin Contracts (last updated v4.7.0) (utils/Strings.sol)

pragma solidity ^0.8.0;

/**
 * @dev String operations.
 */
library Strings {
    bytes16 private constant _HEX_SYMBOLS = "0123456789abcdef";
    uint8 private constant _ADDRESS_LENGTH = 20;

    /**
     * @dev Converts a `uint256` to its ASCII `string` decimal representation.
     */
    function toString(uint256 value) internal pure returns (string memory) {
        // Inspired by OraclizeAPI's implementation - MIT licence
        // https://github.com/oraclize/ethereum-api/blob/b42146b063c7d6ee1358846c198246239e9360e8/oraclizeAPI_0.4.25.sol

        if (value == 0) {
            return "0";
        }
        uint256 temp = value;
        uint256 digits;
        while (temp != 0) {
            digits++;
            temp /= 10;
        }
        bytes memory buffer = new bytes(digits);
        while (value != 0) {
            digits -= 1;
            buffer[digits] = bytes1(uint8(48 + uint256(value % 10)));
            value /= 10;
        }
        return string(buffer);
    }

    /**
     * @dev Converts a `uint256` to its ASCII `string` hexadecimal representation.
     */
    function toHexString(uint256 value) internal pure returns (string memory) {
        if (value == 0) {
            return "0x00";
        }
        uint256 temp = value;
        uint256 length = 0;
        while (temp != 0) {
            length++;
            temp >>= 8;
        }
        return toHexString(value, length);
    }

    /**
     * @dev Converts a `uint256` to its ASCII `string` hexadecimal representation with fixed length.
     */
    function toHexString(uint256 value, uint256 length) internal pure returns (string memory) {
        bytes memory buffer = new bytes(2 * length + 2);
        buffer[0] = "0";
        buffer[1] = "x";
        for (uint256 i = 2 * length + 1; i > 1; --i) {
            buffer[i] = _HEX_SYMBOLS[value & 0xf];
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