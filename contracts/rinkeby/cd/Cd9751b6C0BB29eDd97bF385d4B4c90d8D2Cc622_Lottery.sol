// SPDX-License-Identifier: MIT
pragma solidity ^0.8.6;

import "./Randomizer.sol";

contract Lottery {
    uint256 private constant OWNER_WIN_RATE = 2;

    address private immutable i_owner;

    address[] public players;
    mapping(address => uint256) public playerAmounts;

    constructor() {
        i_owner = msg.sender;
    }

    function deposit() public payable {
        address player = msg.sender;
        uint256 amount = msg.value;

        require(player != i_owner, "Owner can't deposit!");
        require(amount > 0, "Invalid amount!");

        players.push(player);
        playerAmounts[player] += amount;
    }

    function pickWinner() public payable {
        require(msg.sender == i_owner, "Only owner can finish the game!");

        uint256 playersCount = players.length;

        // Another require for timing
        require(msg.value == 0, "Can't pay while finishing the game!");
        require(
            playersCount >= 2,
            "Can't finish game with less than 2 players!"
        );

        uint256 fullContractBalance = address(this).balance;
        uint256 ownerWinBalance = (fullContractBalance * OWNER_WIN_RATE) / 100;
        uint256 playerWinBalance = fullContractBalance - ownerWinBalance;

        require(
            playerWinBalance > 0 && ownerWinBalance > 0,
            "Invalid win balances!"
        );

        uint winnerIndex = new Randomizer().getRandomUInt(playersCount);
        address winner = players[winnerIndex];

        players = new address[](0);

        (bool isOwnerPaid, ) = payable(i_owner).call{value: ownerWinBalance}(
            ""
        );
        (bool isWinnerPaid, ) = payable(winner).call{value: playerWinBalance}(
            ""
        );

        require(isOwnerPaid && isWinnerPaid, "Can't pay winner or owner!");

        emit GotPaid(winner, playerWinBalance);
        emit GotPaid(i_owner, ownerWinBalance);
    }

    event GotPaid(address player, uint256 amount);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.6;

contract Randomizer {
    constructor() {}

    function getRandomUInt(uint max) public view returns (uint) {
        uint randomHash = uint(
            keccak256(abi.encodePacked(block.difficulty, block.timestamp))
        );
        return randomHash % max;
    }
}