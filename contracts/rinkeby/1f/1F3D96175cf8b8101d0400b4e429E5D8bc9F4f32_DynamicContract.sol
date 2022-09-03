// // //SPDX-License-Identifier: MIT
// // pragma solidity ^0.8.9;

// // import "@chainlink/contracts/src/v0.8/VRFConsumerBaseV2.sol";
// // import "@chainlink/contracts/src/v0.8/interfaces/VRFCoordinatorV2Interface.sol";
// // import "@chainlink/contracts/src/v0.8/interfaces/KeeperCompatibleInterface.sol";

// // error Raffle__NotEnoughETHEntered();
// // error Raffle__TransferFailed();
// // error Raffle__NotOpen();
// // error Raffle__UpkeepNotNeeded(uint256 currentBalance, uint256 numPlayers, uint256 raffleState);

// // contract Raffle is VRFConsumerBaseV2, KeeperCompatibleInterface {
// //     enum RaffleState {
// //         OPEN,
// //         CALCULATING
// //     }
// //     uint256 private immutable i_entranceFee;
// //     address payable[] private s_players;
// //     VRFCoordinatorV2Interface private immutable i_vrfCoordinator;
// //     bytes32 private immutable i_gasLane;
// //     uint64 private immutable i_subscriptionId;
// //     uint32 private immutable i_callbackGasLimit;

// //     address private s_recentWinner;
// //     RaffleState private s_raffleState;
// //     uint256 private s_lastTimeStamp;
// //     uint256 private immutable i_interval;

// //     uint16 private constant REQUEST_CONFIRMATIONS = 3;
// //     uint32 private constant NUM_WORDS = 1;

// //     event RaffleEnter(address indexed player);
// //     event RequestedRaffleWinner(uint256 indexed requestId);
// //     event WinnerPicked(address indexed winner);

// //     constructor(
// //         address vrfCoordinatorV2,
// //         uint256 entranceFee,
// //         bytes32 gasLane,
// //         uint64 subscriptionId,
// //         uint32 callbackGasLimit,
// //         uint256 interval
// //     ) VRFConsumerBaseV2(vrfCoordinatorV2) {
// //         i_entranceFee = entranceFee;
// //         i_vrfCoordinator = VRFCoordinatorV2Interface(vrfCoordinatorV2);
// //         i_gasLane = gasLane;
// //         i_subscriptionId = subscriptionId;
// //         i_callbackGasLimit = callbackGasLimit;
// //         s_raffleState = RaffleState.OPEN;
// //         s_lastTimeStamp = block.timestamp;
// //         i_interval = interval;
// //     }

// //     function enterRaffle() public payable {
// //         //require msg.value > i_entranceFee
// //         if (msg.value < i_entranceFee) {
// //             revert Raffle__NotEnoughETHEntered();
// //         }
// //         s_players.push(payable(msg.sender));

// //         emit RaffleEnter(msg.sender);
// //     }

// //     function checkUpkeep(
// //         bytes calldata /*checkData*/
// //     )
// //         public
// //         override
// //         returns (
// //             bool upkeepNeeded,
// //             bytes memory /*performData*/
// //         )
// //     {
// //         bool isOpen = (RaffleState.OPEN == s_raffleState);
// //         bool timePassed = ((block.timestamp - s_lastTimeStamp) > i_interval);
// //         bool hasPlayers = (s_players.length > 0);
// //         bool hasBalance = address(this).balance > 0;
// //         upkeepNeeded = (isOpen && timePassed && hasPlayers && hasBalance);
// //     }

// //     function performUpkeep(
// //         bytes calldata /*performData*/
// //     ) external override {
// //         (bool upkeepNeeded, ) = checkUpkeep("");
// //         if (!upkeepNeeded) {
// //             revert Raffle__UpkeepNotNeeded(
// //                 address(this).balance,
// //                 s_players.length,
// //                 uint256(s_raffleState)
// //             );
// //         }
// //         s_raffleState = RaffleState.CALCULATING;
// //         uint256 requestId = i_vrfCoordinator.requestRandomWords(
// //             i_gasLane,
// //             i_subscriptionId,
// //             REQUEST_CONFIRMATIONS,
// //             i_callbackGasLimit,
// //             NUM_WORDS
// //         );
// //         emit RequestedRaffleWinner(requestId);
// //     }

// //     function fulfillRandomWords(
// //         uint256, /*requestId*/
// //         uint256[] memory randomWords
// //     ) internal override {
// //         uint256 indexOfWinner = randomWords[0] % s_players.length;
// //         address payable recentWinner = s_players[indexOfWinner];
// //         s_recentWinner = recentWinner;
// //         s_raffleState = RaffleState.OPEN;
// //         s_players = new address payable[](0);
// //         (bool success, ) = recentWinner.call{value: address(this).balance}("");
// //         if (!success) {
// //             revert Raffle__TransferFailed();
// //         }
// //         if (s_raffleState != RaffleState.OPEN) {
// //             revert Raffle__NotOpen();
// //         }
// //         emit WinnerPicked(recentWinner);
// //     }

// //     function getEntranceFee() public view returns (uint256) {
// //         return i_entranceFee;
// //     }

// //     function getPlayer(uint256 index) public view returns (address) {
// //         return s_players[index];
// //     }

// //     function getRecentWinner() public view returns (address) {
// //         return s_recentWinner;
// //     }
// // }
// // // Enter the lottery (paying)

// // // Pick a random winner

// // // Winner to be selected every X minutes => completly automated

// pragma solidity ^0.8.7;

// import "@chainlink/contracts/src/v0.8/interfaces/VRFCoordinatorV2Interface.sol";
// import "@chainlink/contracts/src/v0.8/VRFConsumerBaseV2.sol";
// import "@chainlink/contracts/src/v0.8/interfaces/KeeperCompatibleInterface.sol";
// import "hardhat/console.sol";

// error Raffle__UpkeepNotNeeded(uint256 currentBalance, uint256 numPlayers, uint256 raffleState);
// error Raffle__TransferFailed();
// error Raffle__SendMoreToEnterRaffle();
// error Raffle__RaffleNotOpen();

// /**@title A sample Raffle Contract
//  * @author Patrick Collins
//  * @notice This contract is for creating a sample raffle contract
//  * @dev This implements the Chainlink VRF Version 2
//  */
// contract Raffle is VRFConsumerBaseV2, KeeperCompatibleInterface {
//     /* Type declarations */
//     enum RaffleState {
//         OPEN,
//         CALCULATING
//     }
//     /* State variables */
//     // Chainlink VRF Variables
//     VRFCoordinatorV2Interface private immutable i_vrfCoordinator;
//     uint64 private immutable i_subscriptionId;
//     bytes32 private immutable i_gasLane;
//     uint32 private immutable i_callbackGasLimit;
//     uint16 private constant REQUEST_CONFIRMATIONS = 3;
//     uint32 private constant NUM_WORDS = 1;

//     // Lottery Variables
//     uint256 private immutable i_interval;
//     uint256 private immutable i_entranceFee;
//     uint256 private s_lastTimeStamp;
//     address private s_recentWinner;
//     address payable[] private s_players;
//     RaffleState private s_raffleState;

//     /* Events */
//     event RequestedRaffleWinner(uint256 indexed requestId);
//     event RaffleEnter(address indexed player);
//     event WinnerPicked(address indexed player);

//     /* Functions */
//     constructor(
//         address vrfCoordinatorV2,
//         uint64 subscriptionId,
//         bytes32 gasLane, // keyHash
//         uint256 interval,
//         uint256 entranceFee,
//         uint32 callbackGasLimit
//     ) VRFConsumerBaseV2(vrfCoordinatorV2) {
//         i_vrfCoordinator = VRFCoordinatorV2Interface(vrfCoordinatorV2);
//         i_gasLane = gasLane;
//         i_interval = interval;
//         i_subscriptionId = subscriptionId;
//         i_entranceFee = entranceFee;
//         s_raffleState = RaffleState.OPEN;
//         s_lastTimeStamp = block.timestamp;
//         i_callbackGasLimit = callbackGasLimit;
//     }

//     function enterRaffle() public payable {
//         // require(msg.value >= i_entranceFee, "Not enough value sent");
//         // require(s_raffleState == RaffleState.OPEN, "Raffle is not open");
//         if (msg.value < i_entranceFee) {
//             revert Raffle__SendMoreToEnterRaffle();
//         }
//         if (s_raffleState != RaffleState.OPEN) {
//             revert Raffle__RaffleNotOpen();
//         }
//         s_players.push(payable(msg.sender));
//         // Emit an event when we update a dynamic array or mapping
//         // Named events with the function name reversed
//         emit RaffleEnter(msg.sender);
//     }

//     /**
//      * @dev This is the function that the Chainlink Keeper nodes call
//      * they look for `upkeepNeeded` to return True.
//      * the following should be true for this to return true:
//      * 1. The time interval has passed between raffle runs.
//      * 2. The lottery is open.
//      * 3. The contract has ETH.
//      * 4. Implicity, your subscription is funded with LINK.
//      */
//     function checkUpkeep(
//         bytes memory /* checkData */
//     )
//         public
//         view
//         override
//         returns (
//             bool upkeepNeeded,
//             bytes memory /* performData */
//         )
//     {
//         bool isOpen = RaffleState.OPEN == s_raffleState;
//         bool timePassed = ((block.timestamp - s_lastTimeStamp) > i_interval);
//         bool hasPlayers = s_players.length > 0;
//         bool hasBalance = address(this).balance > 0;
//         upkeepNeeded = (timePassed && isOpen && hasBalance && hasPlayers);
//         return (upkeepNeeded, "0x0"); // can we comment this out?
//     }

//     /**
//      * @dev Once `checkUpkeep` is returning `true`, this function is called
//      * and it kicks off a Chainlink VRF call to get a random winner.
//      */
//     function performUpkeep(
//         bytes calldata /* performData */
//     ) external override {
//         (bool upkeepNeeded, ) = checkUpkeep("");
//         // require(upkeepNeeded, "Upkeep not needed");
//         if (!upkeepNeeded) {
//             revert Raffle__UpkeepNotNeeded(
//                 address(this).balance,
//                 s_players.length,
//                 uint256(s_raffleState)
//             );
//         }
//         s_raffleState = RaffleState.CALCULATING;
//         uint256 requestId = i_vrfCoordinator.requestRandomWords(
//             i_gasLane,
//             i_subscriptionId,
//             REQUEST_CONFIRMATIONS,
//             i_callbackGasLimit,
//             NUM_WORDS
//         );
//         // Quiz... is this redundant?
//         emit RequestedRaffleWinner(requestId);
//     }

//     /**
//      * @dev This is the function that Chainlink VRF node
//      * calls to send the money to the random winner.
//      */
//     function fulfillRandomWords(
//         uint256, /* requestId */
//         uint256[] memory randomWords
//     ) internal override {
//         // s_players size 10
//         // randomNumber 202
//         // 202 % 10 ? what's doesn't divide evenly into 202?
//         // 20 * 10 = 200
//         // 2
//         // 202 % 10 = 2
//         uint256 indexOfWinner = randomWords[0] % s_players.length;
//         address payable recentWinner = s_players[indexOfWinner];
//         s_recentWinner = recentWinner;
//         s_players = new address payable[](0);
//         s_raffleState = RaffleState.OPEN;
//         s_lastTimeStamp = block.timestamp;
//         (bool success, ) = recentWinner.call{value: address(this).balance}("");
//         // require(success, "Transfer failed");
//         if (!success) {
//             revert Raffle__TransferFailed();
//         }
//         emit WinnerPicked(recentWinner);
//     }

//     /** Getter Functions */

//     function getRaffleState() public view returns (RaffleState) {
//         return s_raffleState;
//     }

//     function getNumWords() public pure returns (uint256) {
//         return NUM_WORDS;
//     }

//     function getRequestConfirmations() public pure returns (uint256) {
//         return REQUEST_CONFIRMATIONS;
//     }

//     function getRecentWinner() public view returns (address) {
//         return s_recentWinner;
//     }

//     function getPlayer(uint256 index) public view returns (address) {
//         return s_players[index];
//     }

//     function getLastTimeStamp() public view returns (uint256) {
//         return s_lastTimeStamp;
//     }

//     function getInterval() public view returns (uint256) {
//         return i_interval;
//     }

//     function getEntranceFee() public view returns (uint256) {
//         return i_entranceFee;
//     }

//     function getNumberOfPlayers() public view returns (uint256) {
//         return s_players.length;
//     }
// }

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;
// import "./priceConverter.sol";

enum ManufactureStage {
    PRODUCE,
    TRANSFER,
    COMPLETE,
    N_STARTED
}

error NotOwner();

contract DynamicContract {
    ManufactureStage public CONTRACT_STATE;
    address public immutable i_owner;
    address public immutable i_receiver;
    address[] public investorFund;
    mapping(address => uint256) public addressToAmountFunded;

    constructor(address receiver_address) {
        i_owner = msg.sender;
        i_receiver = receiver_address;
        CONTRACT_STATE = ManufactureStage.N_STARTED;
    }

    // function transferFromSCToReceiver() public payable
    function fundContract() public payable onlyOwner {
        investorFund.push(msg.sender);
        addressToAmountFunded[msg.sender] += msg.value;
    }

    function transferProduceCompleted() public onlyOwner {
        payable(i_receiver).transfer(address(this).balance);
    }

    modifier onlyOwner() {
        require(msg.sender == i_owner, "Sender is not owner!");
        if (msg.sender != i_owner) {
            revert NotOwner();
        }
        _;
    }

    receive() external payable {
        fundContract();
    }

    //0xdD870fA1b7C4700F2BD7f44238821C26f7392148
    fallback() external payable {
        fundContract();
    }

    // using PriceConverter for uint256;
    // uint256 public constant MINIMUM_USD = 50 * 1e18;

    // address[] public funders;

    // mapping(address=>uint256) public addressToAmountFunded;

    // address public immutable i_owner;

    // constructor(){
    //     i_owner = msg.sender;
    //     CONTRACT_STATE = ManufactureStage.PRODUCE;
    // }

    // function fund() public payable onlyOwner{
    //     funders.push(msg.sender);
    //     addressToAmountFunded[msg.sender] += msg.value;
    // }

    // function withdraw() public onlyOwner{
    //     for(uint256 funderIndex = 0; funderIndex < funders.length; funderIndex++){
    //         address funder = funders[funderIndex];
    //         addressToAmountFunded[funder] = 0;
    //     }
    //     // reset the array
    //     funders = new address[](0);
    //     //actually withdraw the funds
    //     payable(msg.sender).transfer(address(this).balance);
    //     // msg.sender.transfer(address(this).balance);
    //     bool sendSuccess = payable(msg.sender).send(address(this).balance);
    //     require(sendSuccess, "Send failed");
    //     // call
    //     (bool callSuccess, ) = payable(msg.sender).call{value: address(this).balance}("");
    //     require(callSuccess, "Call failed");

    // }

    // modifier onlyOwner{
    //     require(msg.sender == i_owner, "Sender is not owner!");
    //     if(msg.sender != i_owner){ revert NotOwner();}
    //     _;
    // }

    // receive() external payable{
    //     fund();
    // }

    // fallback() external payable{
    //     fund();
    // }
}