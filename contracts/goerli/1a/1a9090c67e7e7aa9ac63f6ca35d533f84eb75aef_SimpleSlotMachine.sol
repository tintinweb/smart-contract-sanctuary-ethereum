pragma solidity 0.8.13;

contract SimpleSlotMachine {

    mapping(address => uint256) public playerBetList;

    enum GameOutcome { LOSS, WIN }

    event GameOutcomeEvent(address indexed bettor, GameOutcome gameOutcome, uint256 payoutAmount );

    uint16 public constant NUMBER_OF_SLOTS = 3;
    uint16 public constant RNG_MOD_NUM = NUMBER_OF_SLOTS * NUMBER_OF_SLOTS * NUMBER_OF_SLOTS;

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
        return uint16(uint256(keccak256(abi.encode(block.timestamp))) % RNG_MOD_NUM) + 1; // 1 ~ 100 (Only for testing.)
    }


    function genRandomSlots() public view returns (uint16, uint16, uint16) {
        uint16 initialRandNum = random();
        uint16 firstRandomNum = initialRandNum % NUMBER_OF_SLOTS; // returns first digit

        uint16 randNumWithoutFirstDigit = (initialRandNum - firstRandomNum)/NUMBER_OF_SLOTS;
        uint16 secondRandomNum = randNumWithoutFirstDigit % NUMBER_OF_SLOTS; // returns 2nd digit
        uint16 thirdRandomNum =  (randNumWithoutFirstDigit - secondRandomNum)/NUMBER_OF_SLOTS; // returns third digit

        return (firstRandomNum, secondRandomNum, thirdRandomNum);
    }

    /// @notice This function is there so the contract can the initial ETH
    //  that goes into the pool
    receive() external payable {}

}