//SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

interface ILottery {
    //-------------------------------------------------------------------------
    // STATE MODIFYING FUNCTIONS
    //-------------------------------------------------------------------------
    function numbersDrawn(
        uint256 _lotteryId,
        uint256 _requestId,
        uint256 _randomNumber
    ) external;
}

//SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

import "./ILottery.sol";

contract MockRandomNumberGenerator {
    uint256 private constant ROLL_IN_PROGRESS = 9999;

    // Your subscription ID.
    uint64 s_subscriptionId;

    address s_owner;

    mapping(uint256 => uint256) private requestRandom;
    mapping(uint256 => uint256) public round_result;
    uint256 internal round_size;

    event TicketRolled(uint256 indexed requestId);
    event TicketResulted(uint256 indexed requestId, uint256 indexed result);

    uint256 public randomResult;
    uint256 public currentLotteryId;

    address public lottery;

    modifier onlyLottery() {
        require(msg.sender == lottery, "Only Lottery can call function");
        _;
    }

    constructor(uint64 subscriptionId, address _lottery) {
        lottery = _lottery;
        s_owner = msg.sender;
        s_subscriptionId = subscriptionId;
    }

    /**
     * Requests randomness from a user-provided seed
     */
    function requestRandomNumber(
        uint256 lotteryId_,
        uint256 _round_size
    ) public returns (uint256 requestId) {
        round_size = _round_size;
        requestId = uint256(keccak256(abi.encodePacked(block.timestamp)));
        fulfillRandomWords(requestId, requestId);
    }

    function fulfillRandomWords(
        uint256 requestId,
        uint256 randomWords
    ) internal {
        uint256 randomValue = randomWords % round_size;
        round_result[requestId] = randomValue;
        emit TicketResulted(requestId, randomValue);
    }

    function getRandomResult(uint256 requestId) public view returns (uint256) {
        require(
            round_result[requestId] != ROLL_IN_PROGRESS,
            "Draw In Progress."
        );

        return round_result[requestId];
    }
}