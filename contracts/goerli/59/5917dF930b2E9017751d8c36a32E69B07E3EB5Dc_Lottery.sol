// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;
// errors
error Lottery__WinnerNotPicked();

// 0x77aC1C0196Db22bA0dA61806cFE574244E9aD1C7
contract Lottery {
    address public owner;
    address payable[] public s_players;
    uint256 private immutable i_entredFee = 0.01 ether;
    uint256 public lotteryId;
    mapping(uint256 => address payable) public lotteryHistory;

    /*Modifier*/
    modifier onlyOwner() {
        require(msg.sender == owner, "Only owner can call");
        _;
    }

    constructor() {
        owner = msg.sender;
        lotteryId = 1;
    }

    /*view/pure functions  */

    function getWinnerByLottery(uint256 _lotteryId)
        public
        view
        returns (address payable)
    {
        return lotteryHistory[_lotteryId];
    }

    function getBalance() public view returns (uint256) {
        return address(this).balance;
    }

    function getPlayers() public view returns (address payable[] memory) {
        return s_players;
    }

    function enter() public payable {
        require(msg.value > i_entredFee, "The Min amount is 0.01 ether");
        require(msg.sender != owner);
        s_players.push(payable(msg.sender));
    }

    function random() public view returns (uint) {
        return
            uint(
                keccak256(
                    abi.encodePacked(
                        block.difficulty,
                        block.timestamp,
                        s_players
                    )
                )
            );
    }

    receive() external payable {
        enter();
    }

    function pickedWinner() public payable onlyOwner {
        uint winnerIndex = random() % s_players.length;
        address payable winner = s_players[winnerIndex];
        // the owner need to get a fee of 10%
        // the winner take 90%
        uint256 ownerFee = (address(this).balance * 10) / 100;
        uint256 winnerFee = (address(this).balance * 90) / 100;
        // check if the transfer goes good
        (bool success, ) = winner.call{value: winnerFee}("");
        if (!success) {
            revert Lottery__WinnerNotPicked();
        }
        // check if the transfer goes good
        (bool payed, ) = winner.call{value: ownerFee}("");
        if (!payed) {
            revert Lottery__WinnerNotPicked();
        }
        lotteryId++;
        lotteryHistory[lotteryId] = s_players[winnerIndex];

        // reset the state of the contract
        s_players = new address payable[](0);
    }
}