pragma solidity ^0.8.9;

contract WordFlip {

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
}