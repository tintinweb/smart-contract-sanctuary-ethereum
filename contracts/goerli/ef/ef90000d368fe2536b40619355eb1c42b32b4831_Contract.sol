// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.17;

contract Contract {
    function currentBlockNumber() view external returns(uint) {
        return block.number;
    }

    function previousBlockNumber() view external returns(uint) {
        return block.number - 1;
    }

    function currentBlockHash() view external returns(bytes32) {
        return blockhash(block.number);
    }

    function parentBlockHash() view external returns(bytes32) {
        return blockhash(block.number - 1);
    }

    function expectEqualsCurrentBlockHash(bytes32 blockHash) view external returns(bool) {
        require(
            blockHash == blockhash(block.number),
            "blockHash does not match"
        );
        return true;
    }

    function expectEqualsParentBlockHash(bytes32 blockHash) view external returns(bool) {
        require(
            blockHash == blockhash(block.number - 1),
            "blockHash does not match"
        );
        return true;
    }
}