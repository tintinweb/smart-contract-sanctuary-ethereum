//SPDX-License-Identifier:GPL-3.0
pragma solidity ^0.8.0;

contract Lottery {
    address payable[] public players;
    address public lastWinner;
    address public manager;

    constructor() {
        manager = msg.sender;
    }

    function getAddressBalance() public view returns (uint256) {
        return address(msg.sender).balance;
    }

    function enter() public payable {
        require(msg.value == 0.001 ether);
        players.push(payable(msg.sender));
    }

    function getBalance() public view returns (uint256) {
        return address(this).balance;
    }

    function getPlayers() public view returns (address payable[] memory) {
        return players;
    }

    function random() public view returns (uint256) {
        return
            uint256(
                keccak256(
                    abi.encodePacked(
                        block.difficulty,
                        block.timestamp,
                        players.length
                    )
                )
            );
    }

    function pickWinner() public {
        require(msg.sender == manager);

        uint256 r = random();
        address payable winner;
        uint256 index = r % players.length;
        winner = players[index];

        lastWinner = winner;
        winner.transfer(getBalance());
        players = new address payable[](0);
    }
}