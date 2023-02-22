// SPDX-License-Identifier: UNLICENSE

pragma solidity >=0.7.3;

/**
 * @title Blockchain Casino
 * @dev takes in a bet, runs some basic randomness generator and output the result
 */

contract Casino {
    event NewBet(
        string gamblerName,
        string betIsEven,
        bool winning,
        string generatedNumber
    );

    mapping(address => bytes) public bets;

    function makeBet(string memory _bet, string memory _name) external {
        bytes memory generatedRandomNumber = generateRandomness();
        string memory randomNumberAsString = string(generatedRandomNumber);
        bool gamblerIsWinning;
        if (keccak256(generatedRandomNumber) == keccak256(bytes(_bet))) {
            gamblerIsWinning = true;
        } else {
            gamblerIsWinning = false;
        }

        emit NewBet(_name, _bet, gamblerIsWinning, randomNumberAsString);
    }

    function generateRandomness() public view returns (bytes memory) {
        // Get the current block hash
        bytes32 blockHash = blockhash(block.number - 1);

        // Combine the block hash with the contract address
        bytes32 combinedHash = keccak256(
            abi.encodePacked(blockHash, address(this))
        );

        // Convert the combined hash to a uint256 value
        uint256 randomValue = uint256(combinedHash);

        bytes memory result;
        // Return the random value
        if (randomValue % 2 == 0) {
            result = bytes("even");
        } else {
            result = bytes("odd");
        }
        return result;
    }
}