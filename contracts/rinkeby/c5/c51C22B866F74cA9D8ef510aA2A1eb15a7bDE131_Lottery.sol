// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

error Lottery_TransferFailed();
error Lottery_NotOpen();

// Inheritance
contract Lottery {
    uint private immutable i_entranceFee; // private is because it will save the gas fee for us
    address public immutable i_owner;
    address payable[] private s_players;

    // event ContractName_FunctionName();
    event LotteryEnter(address indexed player);
    event LotteryWinnerPicked(address indexed winner);

    enum LotteryState {
        OPEN,
        CALCULATING
    }
    // unit256 0 = OPEN, 1 = CALCULATING

    LotteryState private s_lotteryState;

    constructor(uint entranceFee) {
        i_entranceFee = entranceFee;
        i_owner = msg.sender;
        // lotteryState = LotteryState(0); // Or, we can do like below
        s_lotteryState = LotteryState.OPEN;
    }

    function enter() public payable {
        require(msg.value >= i_entranceFee, "not enough eth entrance");
        if (s_lotteryState != LotteryState.OPEN) {
            revert Lottery_NotOpen();
        }
        s_players.push(payable(msg.sender));
        emit LotteryEnter(msg.sender);
    }

    function pickRandomWinner() public {
        require(msg.sender == i_owner, "only owner can call this function");
        address winner = s_players[0];
        s_lotteryState = LotteryState.OPEN; // reset the lottery State
        s_players = new address payable[](0); // reset the players
        (bool success, ) = winner.call{value: address(this).balance}("");
        if (!success) {
            revert Lottery_TransferFailed();
        }

        emit LotteryWinnerPicked(winner);
    }

    function getEntraceFee() public view returns (uint) {
        return i_entranceFee;
    }

    function getPlayer(uint index) public view returns (address) {
        return s_players[index];
    }

    function getLotteryState() public view returns (LotteryState) {
        return s_lotteryState;
    }

    function getNumberOfPlayers() public view returns (uint) {
        return s_players.length;
    }
}