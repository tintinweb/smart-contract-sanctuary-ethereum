/**
 *Submitted for verification at Etherscan.io on 2022-07-13
*/

pragma solidity ^0.4.21;

contract GuessTheRandomNumberChallenge {
    uint8 public answer;
    uint public blockNumber;
    bytes32 public blockHash;
    uint public n;
    bytes32 public k;
    
    function GuessTheRandomNumberChallenge() public {
        // require(msg.value == 1 ether);
        blockNumber = block.number;
        blockHash = block.blockhash(block.number - 1);
        n = now;
        k = keccak256(blockHash, now);
        answer = uint8(k);
    }
}

contract Helper {
    function toUint8(bytes32 h) public pure returns (uint8) {
        return uint8(h);
    }

    function keccak(bytes32 hash, uint256 timestamp) public pure returns (uint8) {
        return uint8(keccak256(hash, timestamp));
    }

    function getBlockhash() public view returns (bytes32) {
        return block.blockhash(block.number - 1);
    }

    function getTimestamp() public view returns (uint256) {
        return now;
    }
}