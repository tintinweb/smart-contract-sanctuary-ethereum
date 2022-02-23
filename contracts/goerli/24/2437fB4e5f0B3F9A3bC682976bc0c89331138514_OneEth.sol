// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity ^0.8.0;

contract OneEth {
    /// @notice the winner
    address public winner;

    /// @notice joined players
    mapping(address => bool) public joined;

    /// @notice Event emitted when some address wins.
    event Win(address indexed winner);

    /// @notice Event emitted when some address joins the competition.
    event Joined(address indexed who);

    constructor() payable {}

    function join() external {
        require(winner == address(0), "game is over");
        require(!joined[msg.sender], "already joined");

        joined[msg.sender] = true;

        emit Joined(msg.sender);
    }

    function fight() external {
        require(winner == address(0), "game is over");
        require(joined[msg.sender], "not joined");

        winner = msg.sender;
        payable(msg.sender).transfer(address(this).balance);

        emit Win(msg.sender);
    }
}