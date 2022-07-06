// SPDX-License-Identifier: UNLICENSED

pragma solidity ^0.8.0;


contract WavePortal {

    uint private totalWaves;

    /* The owner of the contract */
    address private owner;

    /* To let the owner paused the contract */
    bool private isPaused;

    event NewWave(address indexed from, uint256 timestamp, string message);

    struct Wave {
        address waver; // The address of the user who waved.
        string message; // The message the user sent.
        uint256 timestamp; // The timestamp when the user waved.
    }

    Wave[] waves;

    constructor() payable {
        owner = msg.sender;
        isPaused = true;
    }

    function changeIsPausedState() public {
        require(msg.sender == owner, "Only owner of the contract can change the status");
        if (isPaused){
            isPaused = false;
        } else {
            isPaused = true;
        }
    } 

    function setNewOwner(address _owner) public {
        require(msg.sender == owner, "Only actual owner can set a new owner");
        owner = _owner;
    }

    function wave(string memory _message) public {
        require(isPaused == false, "You can only wave if the contract is not paused");
        totalWaves += 1;
        waves.push(Wave(msg.sender, _message, block.timestamp));
        emit NewWave(msg.sender, block.timestamp, _message);

        uint256 prizeAmount = 0.0001 ether;
        require(
            prizeAmount <= address(this).balance,
            "Trying to withdraw more money than the contract has."
        );
        (bool success, ) = (msg.sender).call{value: prizeAmount}("");
        require(success, "Failed to withdraw money from contract.");
    } 

    function getAllWaves() public view returns (Wave[] memory) {
        return waves;
    }

    function getTotalWaves() public view returns (uint256) {
        return totalWaves;
    }

    function getIsPaused() public view returns (bool) {
        return isPaused;
    }

    function getActualOwner() public view returns (address) {
        return owner;
    }
}