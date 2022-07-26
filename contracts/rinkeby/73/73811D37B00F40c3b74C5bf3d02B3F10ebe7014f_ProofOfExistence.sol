// SPDX-License-Identifier: MIT
pragma solidity 0.8.15;
import "./Counters.sol";

contract ProofOfExistence {
    using Counters for Counters.Counter;
    Counters.Counter private counter;
    mapping(uint256 => bytes32) private idToBytes;

    function addBytes(bytes32 proof) public {
        idToBytes[counter.current()] = proof;
        counter.increment();
    }

    function getBytes(uint256 id) public view returns(bytes32) {
        return idToBytes[id];
    }
}