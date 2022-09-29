// SPDX-License-Identifier: MIT

pragma solidity ^0.8.4;

contract Lottery {
    address payable public admin;
    address payable[] public players;
    uint256 private fee = 0.1 ether;

    mapping(address => uint256) bettingNumber;

    enum LOTTERY_STATE {
        OPEN,
        CLOSED,
        SELECTING_WINNER
    }
    LOTTERY_STATE private lottery_state;

    constructor() {
        admin = payable(msg.sender);
        lottery_state = LOTTERY_STATE.CLOSED;
    }

    function getFee() public view returns (uint256) {
        return fee;
    }

    function setFee(uint256 _fee) public onlyAdmin {
        fee = _fee * (1e17);
    }

    function getBalance() public view returns (uint256) {
        return address(this).balance;
    }

    function getPlayers() public view returns (address payable[] memory) {
        return players;
    }

    function startNewBid() public onlyAdmin isClosed {
        // re set variables
        lottery_state = LOTTERY_STATE.OPEN;
        players = new address payable[](0);
    }

    function play(uint256 _bettingNumber) public payable isOpen {
        require(_bettingNumber < 100, "Betting number from 00 -> 99");
        require(msg.sender != admin, "Admin can not be a player");
        require(
            players.length <= 100,
            "Only 100 player can play at the same time"
        );
        require(msg.value >= fee, "Not enough balance");
        players.push(payable(msg.sender));
        bettingNumber[msg.sender] = _bettingNumber;
    }

    function getRandomNumber() public view returns (uint256) {
        return
            uint256(keccak256(abi.encodePacked(block.timestamp, msg.sender))) %
            100;
    }

    // Admin get 10% total reward
    function getReward() public view returns (uint256) {
        return (address(this).balance / 100) * 90;
    }

    function stopAndChooseWinner() public onlyAdmin {
        lottery_state = LOTTERY_STATE.CLOSED;
        uint256 randomNumber = getRandomNumber();
        uint256 reward = getReward();
        uint256 index = 0;
        address payable[] memory winner;

        // Loop for find winner
        for (uint256 i = 0; i < players.length; i++) {
            if (bettingNumber[players[i]] == randomNumber) {
                winner[index] = players[i];
                index++;
            }
        }

        // Check case how many winner
        if (winner.length == 0) {
            admin.transfer(reward);
        } else if (winner.length > 1) {
            winner[0].transfer(reward);
        } else {
            uint256 shareReward = reward / winner.length;
            for (uint256 i = 0; i < index; i++) {
                winner[index].transfer(shareReward);
            }
        }
    }

    modifier onlyAdmin() {
        require(msg.sender == admin, "Only admin can call this function");
        _;
    }

    modifier isOpen() {
        require(lottery_state == LOTTERY_STATE.OPEN, "Bet is not open");
        _;
    }

    modifier isClosed() {
        require(lottery_state == LOTTERY_STATE.CLOSED, "Bet is not closed yet");
        _;
    }

    modifier isSelectingWinner() {
        require(
            lottery_state == LOTTERY_STATE.SELECTING_WINNER,
            "Bet isn't selecting winner yet"
        );
        _;
    }
}