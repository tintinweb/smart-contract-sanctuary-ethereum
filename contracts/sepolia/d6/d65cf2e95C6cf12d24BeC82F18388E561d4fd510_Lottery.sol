// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.12;

// Uncomment this line to use console.log
// import "hardhat/console.sol";

// seanih - verify new contract with correct constructor argument
interface RandomNumber {
    function requestRandomWords() external view returns (uint256);

    function s_requests(
        uint256
    ) external view returns (uint256, bool, uint256[] memory);

    function lastRequestId() external view returns (uint);
}

contract Lottery {
    address public manager;
    address payable[] public players;
    uint public latestRandomNumber;
    uint[] public allRandomNumbers;
    mapping(address => uint) public entriesPerPlayer;

    RandomNumber public randomNumberContract;

    constructor(address _randomNumberContractAddress) {
        randomNumberContract = RandomNumber(_randomNumberContractAddress);

        manager = msg.sender;
    }

    modifier onlyManager() {
        require(
            msg.sender == manager,
            "only the manager can call this function"
        );
        _;
    }

    function checkContractBalance() public view onlyManager returns (uint) {
        return address(this).balance;
    }

    function buyLotteryTicket() external payable returns (bool success) {
        require(msg.sender != manager, "the manager can't participate");
        require(msg.value == 0.1 ether, "entry must be exactly 0.1 ether");

        if (entriesPerPlayer[msg.sender] == 0) {
            entriesPerPlayer[msg.sender] == 1;

            players.push(payable(msg.sender));
        } else {
            entriesPerPlayer[msg.sender] == entriesPerPlayer[msg.sender]++;
        }

        return success = true;
    }

    function checkNewRandomNum() public onlyManager returns (uint) {
        uint requestID = randomNumberContract.lastRequestId();
        (, , uint[] memory randomNums) = randomNumberContract.s_requests(
            requestID
        );

        uint randomSum = randomNums[0] + randomNums[1];

        require(
            latestRandomNumber != randomSum,
            "no new random numbers have been generated"
        );

        allRandomNumbers.push(randomSum);

        latestRandomNumber = randomSum;

        return randomSum;
    }

    function pickWinner() external payable onlyManager returns (string memory) {
        require(players.length >= 3, "not enough participants");

        uint randomNumber = 3;

        (bool success, ) = players[randomNumber].call{
            value: address(this).balance
        }("");
        require(success, "Ether transfer failed.");

        string memory winner = string(abi.encodePacked(players[randomNumber]));

        for (uint i = 0; i < players.length; i++) {
            entriesPerPlayer[players[i]] = 0;
        }

        delete players;

        return string.concat(winner, " is the winner of the lottery!");
    }
}