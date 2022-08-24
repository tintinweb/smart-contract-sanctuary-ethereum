// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

contract SolidityRoulette {
    address constant BURN_ADDRESS = address(0);

    event Win(address indexed winner, uint amountWagered);
    event Lose(address indexed loser, uint amountWagered);

    function roulette() public payable {
        require(msg.value > 0, "stake something coward");
        if (random() == 1) {
            emit Win(msg.sender, msg.value);
            payable(msg.sender).transfer(msg.value);
        }
        else
        {
            emit Lose(msg.sender, msg.value);
            payable(BURN_ADDRESS).transfer(msg.value);
        }
    }

    function random() public view returns(uint){
        return uint(keccak256(abi.encodePacked(block.timestamp, block.difficulty, msg.sender))) % 2;
    }
}