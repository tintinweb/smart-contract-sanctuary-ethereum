pragma solidity ^0.8.9;

contract WordFlip {
    uint[] public deck;

    function initializeDeck() public {
        // Initialize deck with 52 cards
        for (uint i = 0; i < 52; i++) {
            deck.push(i);
        }
        shuffle();
    }

    function wordFlip(string memory input) public pure returns (string memory) {
        bytes memory inputBytes = bytes(input);
        uint length = inputBytes.length;
        bytes memory result = new bytes(length);
        for (uint i = 0; i < length; i++) {
            result[i] = inputBytes[length - 1 - i];
        }
        return string(result);
    }

    function generateSeed() public view returns (bytes32) {
        // Get the block hash of the current block
        bytes32 blockHash = blockhash(block.number - 1);
        return blockHash;
    }

    function shuffle() public {
        // Get the block hash of the current block
        bytes32 blockHash = blockhash(block.number - 1);
        uint seed = uint(blockHash);

        // Fisher-Yates shuffle algorithm
        for (uint i = 51; i > 0; i--) {
            uint j = uint(seed % (i + 1));
            seed = seed / (i + 1);
            uint temp = deck[i];
            deck[i] = deck[j];
            deck[j] = temp;
        }}

        function getDeck() public returns (uint[] memory) {
            shuffle();
            return deck;
    }
}