/**
 *Submitted for verification at Etherscan.io on 2022-06-03
*/

// SPDX-License-Identifier: MIT
pragma solidity 0.8.7;

contract Lottery {
    address public manager;
    address payable[] public participants;
    address public winnerParticipant;
    uint256 public participantLenght = 0;

    constructor() {
        manager = msg.sender;
    }

    modifier costs(uint256 _amount) {
        require(msg.value == 2 ether, "Not Enough Ether!");
        _;
    }

    function buyLottery() public payable costs(2 ether) {
        participants.push(payable(msg.sender));
        participantLenght++;
    }

    modifier onlyOwner() {
        require(msg.sender == manager, "Access Denied!");
        _;
    }

    function getBalance() public view onlyOwner returns (uint256) {
        return address(this).balance;
    }

    function random() public view returns (uint256) {
        //random generator algorithm
        return
            uint256(
                keccak256(
                    abi.encodePacked(
                        block.difficulty,
                        block.timestamp,
                        participants.length
                    )
                )
            );
    }

    modifier minParticipants(uint256 _minMem) {
        require(
            participants.length >= _minMem,
            "Not Much participants participated!"
        );
        _;
    }

    function selectWinner() public onlyOwner minParticipants(3) {
        uint256 randomVal = random();
        address payable winner;
        uint256 index = randomVal % participants.length;
        winner = participants[index];
        winner.transfer(getBalance());
        winnerParticipant = winner;
        participantLenght = 0;
        participants = new address payable[](0);
    }
}