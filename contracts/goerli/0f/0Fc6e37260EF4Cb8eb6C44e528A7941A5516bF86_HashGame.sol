// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.9;

// Uncomment this line to use console.log
// import "hardhat/console.sol";

contract HashGame {
    struct Insurance {
        uint256 purchasedDateTime;
        uint256 expiryDateTime;
    }

    struct GameRound {
        uint256 round;
        bool hasPlayed;
        bool isWon;
        uint256 stakeValue;
    }

    event NewGameRound(uint256 roundCount, bool hasPlayed, bool isWon, uint256 stakeValue);
    event RoundCompleted(uint256 roundCount, bool hasPlayed, bool isWon, uint256 stakeValue);

    uint256 constant insuredDuration = 1 days;
    uint256 constant insurancePrice = 0.01 ether;
    uint256 constant maxGameRound = 9;
    uint256 constant nextGameMultiplier = 2;

    mapping(address => Insurance) public userToInsuranceMap;
    mapping(address => GameRound[]) public userToGameMap;

    function buyInsurance(address addr) public payable {
        require(msg.value == insurancePrice, "Insufficient ether");
        require(isEligibleToBuyNewInsurance(addr), "You are not eligible to buy insurance");

        delete userToInsuranceMap[addr];
        userToInsuranceMap[addr] = Insurance(block.timestamp, block.timestamp + insuredDuration);
    }

    function hasValidInsurance(address addr)
        public
        view
        returns (
            bool isInsured,
            uint256 purchasedTime,
            uint256 expiryTime
        )
    {
        bool isEligible = isEligibleToBuyNewInsurance(addr);

        // console.log('bool: %o', isEligible);

        if (isEligible == true) {
            return (false, 0, 0);
        }

        Insurance storage userInsurance = userToInsuranceMap[addr];
        return (!isEligible, userInsurance.purchasedDateTime, userInsurance.expiryDateTime);
    }

    function isEligibleToBuyNewInsurance(address addr) public view returns (bool) {
        Insurance storage userInsurance = userToInsuranceMap[addr];
        // console.log('expiryDateTime: %o', userInsurance.expiryDateTime);
        // console.log('purchasedDateTime: %o', userInsurance.purchasedDateTime);
        // console.log('block.timestamp: %o', block.timestamp);
        return
            (userInsurance.expiryDateTime == 0 && userInsurance.purchasedDateTime == 0) ||
            (block.timestamp >= userInsurance.expiryDateTime);
    }

    function playGame(address addr) public {
        (bool isUserInsured, , ) = hasValidInsurance(addr);
        require(isUserInsured, "User does not have valid insurance");
        require(!hasPlayedMaxGameRound(addr), "User has played maximum rounds of game");

        // console.logBytes1(getCharAt("123456789", 8));

        uint256 playedRound = userToGameMap[addr].length;
        uint256 lastStakedValue = 0;

        if (playedRound > 0 && userToGameMap[addr][playedRound - 1].hasPlayed == false) {
            GameRound memory lastCreatedRound = userToGameMap[addr][playedRound - 1];
            emit NewGameRound(
                lastCreatedRound.round,
                lastCreatedRound.hasPlayed,
                lastCreatedRound.isWon,
                lastCreatedRound.stakeValue
            );
            return;
        }

        if (playedRound > 0 && userToGameMap[addr][playedRound - 1].isWon == true) {
            revert("You have already won a round");
        }

        if (playedRound > 0) {
            lastStakedValue = userToGameMap[addr][playedRound - 1].stakeValue;
        }

        uint256 currentStakeValue = lastStakedValue > 0 ? lastStakedValue * nextGameMultiplier : 1;
        GameRound memory newRound = GameRound(playedRound + 1, false, false, currentStakeValue);

        userToGameMap[addr].push(newRound);
        emit NewGameRound(newRound.round, newRound.hasPlayed, newRound.isWon, newRound.stakeValue);
    }

    function currentGameRound(address addr) public view returns (uint256 round, uint256 stakeValue) {
        (bool isUserInsured, , ) = hasValidInsurance(addr);
        require(isUserInsured, "User does not have valid insurance");
        require(!hasPlayedMaxGameRound(addr), "User has played maximum rounds of game");

        uint256 playedRound = userToGameMap[addr].length;
        uint256 lastStakedValue = 0;

        if (playedRound > 0 && userToGameMap[addr][playedRound - 1].hasPlayed == false) {
            GameRound memory lastCreatedRound = userToGameMap[addr][playedRound - 1];
            return (lastCreatedRound.round, lastCreatedRound.stakeValue);
        }

        if (
            playedRound > 0 &&
            userToGameMap[addr][playedRound - 1].hasPlayed == true &&
            userToGameMap[addr][playedRound - 1].isWon == false
        ) {
            GameRound memory lastCreatedRound = userToGameMap[addr][playedRound - 1];
            lastStakedValue = userToGameMap[addr][playedRound - 1].stakeValue;
            uint256 currentStakeValue = lastStakedValue > 0 ? lastStakedValue * nextGameMultiplier : 1;

            return (lastCreatedRound.round + 1, currentStakeValue);
        }

        if (
            playedRound > 0 &&
            userToGameMap[addr][playedRound - 1].hasPlayed == true &&
            userToGameMap[addr][playedRound - 1].isWon == true
        ) {
            return (0, 0);
        }

        if (playedRound == 0) {
            return (1, 1);
        }
    }

    function submitGameResult(string memory hash, address addr) public {
        require(bytes(hash).length > 0, "Hash cannot be empty");
        require(userToGameMap[addr].length > 0, "User has not started any game");

        uint256 playedRound = userToGameMap[addr].length;
        bool isHashWinnable = isWinningHash(hash);

        userToGameMap[addr][playedRound - 1].hasPlayed = true;
        userToGameMap[addr][playedRound - 1].isWon = isHashWinnable;

        emit RoundCompleted(playedRound, true, isHashWinnable, userToGameMap[addr][playedRound - 1].stakeValue);
    }

    function isWinningHash(string memory hash) public pure returns (bool) {
        require(bytes(hash).length > 0, "Hash cannot be empty");

        uint256 strLength = bytes(hash).length;
        bytes1 lastChar = getCharAt(hash, strLength);
        bytes1 lastSecondChar = getCharAt(hash, strLength - 1);

        return (isNumber(lastChar) && isAlphabet(lastSecondChar)) || (isNumber(lastSecondChar) && isAlphabet(lastChar));
    }

    function isNumber(bytes1 char) private pure returns (bool) {
        return char >= 0x30 && char <= 0x39;
    }

    function isAlphabet(bytes1 char) private pure returns (bool) {
        return (char >= 0x41 && char <= 0x5A) || (char >= 0x61 && char <= 0x7A);
    }

    function substring(
        string memory str,
        uint256 startIndex,
        uint256 endIndex
    ) private pure returns (string memory) {
        bytes memory strBytes = bytes(str);
        bytes memory result = new bytes(endIndex - startIndex);
        for (uint256 i = startIndex; i < endIndex; i++) {
            result[i - startIndex] = strBytes[i];
        }
        return string(result);
    }

    function getCharAt(string memory str, uint256 position) private pure returns (bytes1) {
        return bytes(substring(str, position - 1, position))[0];
    }

    function hasPlayedMaxGameRound(address addr) public view returns (bool hasPlayedMax) {
        (bool userHasValidInsurance, , ) = hasValidInsurance(addr);
        bool userHasPlayedMaxRound = userToGameMap[addr].length == maxGameRound;

        return userHasValidInsurance && userHasPlayedMaxRound;
    }

    function getMsgSender() public view returns (address sender, address origin) {
        return (msg.sender, tx.origin);
    }
}