pragma solidity ^0.8.0;

contract getRandomTraits {
    function getRandomMake(uint randomNumber) public view returns(uint) {
        randomNumber = uint(keccak256(abi.encodePacked(randomNumber, block.timestamp, 'randomMake')));
        uint fate = (randomNumber % 100) + 1;
        if (fate >= 1 && fate <6) {
            return 5;
        }
        else if (fate >= 6 && fate < 15) {
            return 4;
        }
        else if (fate >= 15 && fate <31) {
            return 3;
        }
        else if (fate >= 31 && fate <55) {
            return 2;
        }
        else if (fate >= 55 && fate < 101) {
            return 1;
        }
        else {
            return 0;
        }
    }

    function getRandomDocker(uint randomNumber) public view returns(uint) {
        randomNumber = uint(keccak256(abi.encodePacked(randomNumber, block.timestamp, 'randomDocker')));
        uint fate = (randomNumber % 100) + 1;
        if (fate >= 1 && fate <6) {
            return 4;
        }
        else if (fate >= 6 && fate <14) {
            return 3;
        }
        else if (fate >= 14 && fate <33) {
            return 2;
        }
        else if (fate >= 33 && fate < 101) {
            return 1;
        }
        else {
            return 0;
        }
    }
}