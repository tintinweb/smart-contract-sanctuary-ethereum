// SPDX-License-Identifier: UNLICENSED

pragma solidity ^0.8.0;


contract WavePortal {

    /* The number total of Waves */
    uint private totalWaves;

    /* The owner of the contract */
    address private owner;

    /* To let the owner paused the contract */
    bool private isPaused;

    /* Prize that we can win */
    uint256 prizeAmount = 0.01 ether;

    /* Prize that we need to pay to wave */
    uint256 wavePrice = 0.015 ether;

    /* Fee for contract owner */
    uint256 feeForOwner = 0.0015 ether;

    event NewWave(address indexed from, uint256 timestamp, string message);

    struct Wave {
        address waver; // The address of the user who waved.
        string message; // The message the user sent.
        uint256 timestamp; // The timestamp when the user waved.
    }

    /* An array of all the last Waves */
    Wave[] waves;

    /* A mapping to save last time an account Wave at us */
    mapping(address => uint256) public lastWavedAt;

    constructor() {
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

    function wave(string memory _message) public payable {
        require(isPaused == false, "You can only wave if the contract is not paused");
        require(
            lastWavedAt[msg.sender] + 15 minutes < block.timestamp,
            "Need to wait 15m before next wave"
        );
        require(msg.value == wavePrice ,"Not pay enough");
        lastWavedAt[msg.sender] = block.timestamp;

        totalWaves += 1;
        waves.push(Wave(msg.sender, _message, block.timestamp));
        emit NewWave(msg.sender, block.timestamp, _message);

        /* a "random" number between 0 and 99 */
        uint8 decentRandom = uint8(keccak256(abi.encodePacked(block.timestamp,  block.difficulty, msg.sender, address(this)))[0])  % 100;

        if (decentRandom < 40) {
            require(
                prizeAmount <= address(this).balance,
                "Trying to withdraw more money than the contract has."
            );
            (bool success, ) = msg.sender.call{value: prizeAmount}("");
            require(success, "Failed to withdraw money from contract.");
            msg.sender.call{value: prizeAmount}("");
        } else {
            require(
                feeForOwner <= address(this).balance,
                "Trying to withdraw more money than the contract has."
            );
            (bool success, ) = owner.call{value: feeForOwner}("");
            require(success, "Failed to send Ether");
            owner.call{value: feeForOwner}("");

        }
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