pragma solidity 0.8.13;

contract SimpleSlotMachine {

    mapping(address => uint256) public playerBetList;

    enum GameOutcome { LOSS, WIN }

    event GameOutcomeEvent(address indexed bettor, GameOutcome gameOutcome, uint256 payoutAmount );


    constructor() {

    }


    function placeSlotsBet() public payable returns (bool) { // need to add non-reentrancy guard
        uint256 betAmount = msg.value;

        require(betAmount > 0);

        (
            uint16 firstSlotNum,
            uint16 secondSlotNum,
            uint16 thirdSlotNum
        ) = genRandomSlots();

        uint8 payoutMultiplier = 0;
        uint256 payoutAmount = 0;
        if (
            (firstSlotNum == secondSlotNum) && (secondSlotNum == thirdSlotNum)
        ) {
            payoutMultiplier = 3;
            payoutAmount = payoutMultiplier * betAmount;
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
        return uint16(uint256(keccak256(abi.encode(block.timestamp))) % 1000) + 1; // 1 ~ 100 (Only for testing.)
    }


    function genRandomSlots() public view returns (uint16, uint16, uint16) {
        uint16 initialRandNum = random();
        uint16 firstRandomNum = initialRandNum % 10; // returns first digit

        uint16 randNumWithoutFirstDigit = (initialRandNum - firstRandomNum)/10;
        uint16 secondRandomNum = randNumWithoutFirstDigit % 10; // returns 2nd digit
        uint16 thirdRandomNum =  (randNumWithoutFirstDigit - secondRandomNum)/10;

        return (firstRandomNum, secondRandomNum, thirdRandomNum);
    }

    /// @notice This function is there so the contract can the initial ETH
    //  that goes into the pool
    receive() external payable {}

    // function start() public payable {
    //     uint256 userBalance = msg.value;

    //     require(userBalance > 0);

    //     uint256 randomValue = random();

    //     playerList[msg.sender] = randomValue;

    //     contractBalance = address(this).balance;

    //     if (randomValue > 50) {
    //         uint256 winBalance = userBalance * 2;

    //         if (contractBalance < winBalance) {
    //             winBalance = contractBalance;
    //         }

    //         msg.sender.transfer(winBalance);

    //         contractBalance = address(this).balance;
    //     }
    // }


}


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