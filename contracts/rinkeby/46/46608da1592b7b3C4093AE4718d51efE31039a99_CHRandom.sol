// SPDX-License-Identifier: MIT
pragma solidity ^0.8.16;
contract CHRandom {
    uint256 private randomCallCount;

    mapping(uint256 => Tx) txs;

    struct Tx {
        uint256[] data;
        uint256 timestamp;
    }

    function multiRand(uint256 _id, uint256 _count) external {
        uint256[] memory List = new uint256[](_count);
        
        for (uint256 i = 0; i < _count; i++) {
            randomCallCount++;
            List[i] = rand();
        }

        txs[_id]=Tx({
            data: List,
            timestamp: block.timestamp
        });
    }

    function rand() public view returns (uint256) {
        uint256 seed = uint256(keccak256(abi.encodePacked(
            block.timestamp + block.difficulty + randomCallCount +
            ((uint256(keccak256(abi.encodePacked(block.coinbase)))) / block.timestamp) +
            (block.gaslimit + randomCallCount) +
            ((uint256(keccak256(abi.encodePacked(msg.sender)))) / block.timestamp) +
            block.number
        )));
        return (seed - ((seed / 90) * 90)) + 10;
    }

    function getTxById(uint256 _id) public view returns (Tx memory) {
        Tx storage currentItem = txs[_id];
        return currentItem;
    }

}