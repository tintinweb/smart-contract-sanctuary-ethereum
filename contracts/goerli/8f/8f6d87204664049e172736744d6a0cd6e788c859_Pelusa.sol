// SPDX-License-Identifier: MIT
pragma solidity ^0.8.7;

interface IGame {
    function getBallPossesion() external view returns (address);
}

// "el baile de la gambeta"
// https://www.youtube.com/watch?v=qzxn85zX2aE
// @author https://twitter.com/eugenioclrc
contract Pelusa {
    address public immutable owner;
    address internal player;
    uint256 public goals = 1;

    constructor() {
        owner = address(
            uint160(
                uint256(
                    keccak256(
                        abi.encodePacked(msg.sender, blockhash(block.number))
                    )
                )
            )
        );
    }

    function passTheBall() external {
        require(msg.sender.code.length == 0, "Only EOA players");
        require(uint256(uint160(msg.sender)) % 100 == 10, "not allowed");

        player = msg.sender;
    }

    function isGoal() public view returns (bool) {
        // expect ball in owners posession
        return IGame(player).getBallPossesion() == owner;
    }

    function shoot() external {
        require(isGoal(), "missed");
        /// @dev use "the hand of god" trick
        (bool success, bytes memory data) = player.delegatecall(
            abi.encodeWithSignature("handOfGod()")
        );
        require(success, "missed");
        require(uint256(bytes32(data)) == 22_06_1986);
    }
}