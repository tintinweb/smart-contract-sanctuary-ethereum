/**
 *Submitted for verification at Etherscan.io on 2022-10-30
*/

// Sources flattened with hardhat v2.9.9 https://hardhat.org

// File contracts/abstracts/RandConsumer.sol

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

abstract contract RandConsumer {
    uint256 public currentRequestId;
    mapping(uint256 => uint256) public randomStore;

    event RandomRequested(uint256 indexed requestId);
    event RandomFullfilled(uint256 indexed requestId, uint256 random);

    function requestRandom() external payable {
        currentRequestId++;
        _requestRandom(currentRequestId);

        emit RandomRequested(currentRequestId);
    }

    function _fullfillRandomness(uint256 _requestId, uint256 _result) internal {
        require(randomStore[_requestId] == 0, "random has fullfilled");

        randomStore[_requestId] = _result;
        emit RandomFullfilled(currentRequestId, _result);
    }

    function _requestRandom(uint256 _currentRequestId) internal virtual;
}


// File contracts/onchain/OnchainConsumer.sol

pragma solidity ^0.8.0;

contract OnchainConsumer is RandConsumer {
    function _requestRandom(uint256 requestId)
        internal
        override
    {
        uint256 random = uint256(
            keccak256(
                abi.encode(
                    tx.gasprice,
                    block.number,
                    block.timestamp,
                    block.difficulty,
                    blockhash(block.number - 1),
                    address(this)
                )
            )
        );
        _fullfillRandomness(requestId, random);
    }
}