// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

contract Game {
    error NotHighestScore(address player);
    event HighestScoreUpdated(
        address indexed player,
        uint8 highestLevel,
        uint256 highestPoints
    );
    event EthersClaimed(address indexed player);
    event HighestScoreReset();

    address public owner;
    uint256 private entryFees = 0.0003 ether;

    constructor() {
        owner = msg.sender;
    }

    struct highestStats {
        address player;
        uint8 highestLevel;
        uint256 highestPoints;
    }

    highestStats private HighestStats = highestStats(owner, 1, 0);

    modifier onlyOwner() {
        require(
            msg.sender == owner,
            "You need to be the owner of the contract"
        );
        _;
    }

    function enterGame() public payable returns (bool) {
        require(
            msg.value >= entryFees,
            "You need to send enough ethers to join the game"
        );
        return true;
    }

    function getHighestStats() public view returns (address, uint8, uint256) {
        return (
            HighestStats.player,
            HighestStats.highestLevel,
            HighestStats.highestPoints
        );
    }

    function getEntryFees() public view returns (uint256) {
        return entryFees;
    }

    function setHighestStats(
        uint8 _highestLevel,
        uint256 _highestPoints
    ) public {
        require(
            _highestLevel > HighestStats.highestLevel &&
                _highestPoints > HighestStats.highestPoints,
            "You don't have highest score"
        );
        address _player = msg.sender;
        HighestStats.player = _player;
        HighestStats.highestLevel = _highestLevel;
        HighestStats.highestPoints = _highestPoints;
        emit HighestScoreUpdated(_player, _highestLevel, _highestPoints);
    }

    function claimEthers() public {
        address payable _player = payable(msg.sender);
        if (_player == HighestStats.player) {
            (bool success, ) = _player.call{value: address(this).balance}("");
            require(success, "Cannot Claim Ethers");
            HighestStats.player = address(0);
            HighestStats.highestLevel = 1;
            HighestStats.highestPoints = 0;
            emit EthersClaimed(_player);
            emit HighestScoreReset();
        } else {
            revert NotHighestScore(_player);
        }
    }

    function setEnterFee(uint256 _entryFees) public onlyOwner {
        entryFees = _entryFees;
    }

    receive() external payable {}

    fallback() external payable {}
}