// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

error Raffle__NotEnoughETH();
error Raffle__NotAllowed();
error Raffle__TransferFailed();
error Raffle__NotOpen();

contract Raffle {
    enum RaffleState {
        OPEN,
        CALCULATING
    }
    uint256 private s_min_price_fee;
    address payable[] private s_players;
    address private immutable i_owner;
    address private s_recent_winner;
    RaffleState private s_raffleState;
    modifier onlyOwner() {
        if (msg.sender != i_owner) {
            revert Raffle__NotAllowed();
        }
        _;
    }
    modifier enoughFunds() {
        if (address(this).balance == 0) {
            revert Raffle__NotEnoughETH();
        }
        _;
    }
    event RaffleEntered(address indexed player);
    event WinnerPicked(address indexed winner);

    constructor(uint256 price_fee) {
        i_owner = msg.sender;
        s_min_price_fee = price_fee;
        s_raffleState = RaffleState.OPEN;
    }

    function enterRaffle() public payable {
        if (msg.value < s_min_price_fee) {
            revert Raffle__NotEnoughETH();
        }
        if (s_raffleState != RaffleState.OPEN) {
            revert Raffle__NotOpen();
        }
        s_players.push(payable(msg.sender));
        emit RaffleEntered(msg.sender);
    }

    function setRaffleToCalculating() external {
        s_raffleState = RaffleState.CALCULATING;
    }

    function setRaffleToOpen() external {
        s_raffleState = RaffleState.OPEN;
    }

    function pickRandomWinner(uint256 randomNumber) external enoughFunds {
        uint256 winnerIndex = randomNumber % s_players.length;
        s_recent_winner = s_players[winnerIndex];
        s_raffleState = RaffleState.OPEN;
        s_players = new address payable[](0);
        (bool success, ) = payable(s_recent_winner).call{
            value: address(this).balance
        }("");
        if (!success) {
            revert Raffle__TransferFailed();
        }
        emit WinnerPicked(s_recent_winner);
    }

    function setMinPriceFee(uint256 price_fee) public onlyOwner {
        s_min_price_fee = price_fee;
    }

    function isRaffleOpen() external view returns (bool) {
        return s_raffleState == RaffleState.OPEN;
    }

    function isRaffleCalculating() external view returns (bool) {
        return s_raffleState == RaffleState.CALCULATING;
    }

    function getMinPriceFee() public view returns (uint256) {
        return s_min_price_fee;
    }

    function getPlayerListLength() public view returns (uint256) {
        return s_players.length;
    }

    function getOwner() public view returns (address) {
        return i_owner;
    }

    function getPlayer(uint256 index) public view returns (address) {
        return s_players[index];
    }

    function getRecentWinner() public view returns (address) {
        return s_recent_winner;
    }

    function getRaffleState() public view returns (RaffleState) {
        return s_raffleState;
    }
}