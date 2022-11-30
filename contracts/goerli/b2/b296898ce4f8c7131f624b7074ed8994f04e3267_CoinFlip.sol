pragma solidity 0.8.13;

contract CoinFlip {

    mapping(address => uint256) public playerBetList;

    enum GameOutcome { LOSS, WIN }

    event GameOutcomeEvent(address indexed bettor, GameOutcome gameOutcome, uint256 payoutAmount );

    uint16 public constant NUMBER_OF_OUTCOMES = 2;
    uint16 public constant RNG_MOD_NUM = NUMBER_OF_OUTCOMES;

    constructor() {

    }


    function placeBet() public payable returns (bool) { // need to add non-reentrancy guard
        uint256 betAmount = msg.value;

        require(betAmount > 0);

        uint16 coinFlipVal = getCoinFlipVal();

        uint256 payoutAmount = 0;
        if (coinFlipVal == 1) {
            payoutAmount = 2 * betAmount;

            emit GameOutcomeEvent(
                msg.sender,
                GameOutcome.WIN,
                payoutAmount
            );
        } else {
            emit GameOutcomeEvent(
                msg.sender,
                GameOutcome.LOSS,
                0
            );
        }



        payable(msg.sender).transfer(payoutAmount);

        return true;
    }


    function random() public view returns (uint16) {
        return uint16(uint256(keccak256(abi.encode(block.timestamp))) % RNG_MOD_NUM); // 1 ~ 100 (Only for testing.)
    }


    function getCoinFlipVal() public view returns (uint16) {
        uint16 initialRandNum = random();
        uint16 flipOutcome = initialRandNum % NUMBER_OF_OUTCOMES; // 0 for tails, 1 for heads

        return (flipOutcome);
    }

    /// @notice This function is there so the contract can the initial ETH
    //  that goes into the pool
    receive() external payable {}

}





// contract CoinFlip {

//     mapping(address => uint256) public playerBetList;

//     enum GameOutcome { LOSS, WIN }

//     event GameOutcomeEvent(address indexed bettor, GameOutcome gameOutcome, uint256 payoutAmount );


//     constructor() {

//     }



//     function placeBet() public payable returns (bool) { // need to add non-reentrancy guard
//         uint256 betAmount = msg.value;

//         require(betAmount > 0);

//         uint256 randomValue = random();
//         uint256 contractBalance = address(this).balance;
//         // playerBetList[msg.sender] = betAmount;

//         // below triggered if user wins bet
//         if (randomValue > 50) {
//             uint256 winAmount = betAmount * 2;

//             if (contractBalance < winAmount) {
//                 winAmount = contractBalance;
//             }

//             payable(msg.sender).transfer(winAmount);

//             contractBalance = address(this).balance;
//             emit GameOutcomeEvent(
//                 msg.sender,
//                 GameOutcome.WIN,
//                 winAmount
//             );
//         } else {
//             emit GameOutcomeEvent(
//                 msg.sender,
//                 GameOutcome.LOSS,
//                 0
//             );
//         }

//         return true;

//     }

//     function random() public view returns (uint8) {
//         return uint8(uint256(keccak256(abi.encode(block.timestamp))) % 100) + 1; // 1 ~ 100 (Only for testing.)
//     }


//     /// @notice This function is there so the contract can the initial ETH
//     //  that goes into the pool
//     receive() external payable {}


// }


// contract SlotMachine {
//     mapping(address => uint256) public playerList;

//     uint256 public contractBalance;

//     function SlotMachine() public {}

//     function() public payable {
//         start();
//     }

//     function start() public payable {
//         uint256 userBalance = msg.value;

//         require(userBalance > 0);

//         uint256 randomValue = random();

//         playerList[msg.sender] = randomValue;

//         contractBalance = address(this).balance;

//         if (randomValue > 50) {
//             uint256 winBalance = userBalance * 2;

//             if (contractBalance < winBalance) {
//                 winBalance = contractBalance;
//             }

//             msg.sender.transfer(winBalance);

//             contractBalance = address(this).balance;
//         }
//     }

//     function random() view returns (uint8) {
//         return uint8(uint256(keccak256(block.timestamp)) % 100) + 1; // 1 ~ 100 (Only for testing.)
//     }
// }