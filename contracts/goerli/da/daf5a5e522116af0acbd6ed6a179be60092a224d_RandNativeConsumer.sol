/**
 *Submitted for verification at Etherscan.io on 2022-10-30
*/

// Sources flattened with hardhat v2.9.9 https://hardhat.org

// File contracts/libraries/Converter.sol

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

library Converter {
    function toUint256(bytes memory _bytes)
        internal
        pure
        returns (uint256 value)
    {
        assembly {
            value := mload(add(_bytes, 0x20))
        }
    }
}


// File contracts/libraries/Signature.sol

pragma solidity ^0.8.0;

library Signature {
    function getEthSignedMessageHash(bytes32 _messageHash)
        internal
        pure
        returns (bytes32)
    {
        return
            keccak256(
                abi.encodePacked(
                    "\x19Ethereum Signed Message:\n32",
                    _messageHash
                )
            );
    }

    function verify(
        address _signer,
        bytes32 _messageHash,
        bytes memory signature
    ) internal pure returns (bool) {
        bytes32 ethSignedMessageHash = getEthSignedMessageHash(_messageHash);

        return recoverSigner(ethSignedMessageHash, signature) == _signer;
    }

    function recoverSigner(
        bytes32 _ethSignedMessageHash,
        bytes memory _signature
    ) internal pure returns (address) {
        (bytes32 r, bytes32 s, uint8 v) = splitSignature(_signature);

        return ecrecover(_ethSignedMessageHash, v, r, s);
    }

    function splitSignature(bytes memory sig)
        internal
        pure
        returns (
            bytes32 r,
            bytes32 s,
            uint8 v
        )
    {
        require(sig.length == 65, "invalid signature length");

        assembly {
            r := mload(add(sig, 32))
            s := mload(add(sig, 64))
            v := byte(0, mload(add(sig, 96)))
        }
    }
}


// File contracts/abstracts/RandConsumer.sol


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


// File contracts/randnative/RandNativeConsumer.sol

// An example of a consumer contract that relies on a subscription for funding.
pragma solidity ^0.8.0;



contract RandNativeConsumer is RandConsumer {
    uint64 public target = type(uint64).max / 50;
    mapping(uint256 => uint256) public randomResults;
    mapping(uint256 => address) public requestInitializers;

    event RandomInitialized(
        uint256 indexed requestId,
        address indexed requester
    );

    function _requestRandom(uint256 requestId) internal override {
        requestInitializers[requestId] = msg.sender;

        emit RandomInitialized(requestId, msg.sender);
    }

    function fullfillRandomness(
        uint256 _requestId,
        uint256 _randInput,
        bytes memory _signature
    ) external {
        require(
            requestInitializers[_requestId] != address(0),
            "Random have not initialized"
        );
        require(randomResults[_requestId] == 0, "Already fullfilled");

        bytes32 messageHash = getMessageHash(_requestId, _randInput);

        require(
            Signature.verify(msg.sender, messageHash, _signature),
            "Invalid signature"
        );

        uint64 sigValue = uint64(Converter.toUint256(_signature));
        require(sigValue < target, "Invalid random input");

        uint256 random = uint256(
            keccak256(
                abi.encode(
                    _randInput,
                    randomResults[_requestId - 1],
                    requestInitializers[_requestId],
                    tx.gasprice,
                    block.number,
                    block.timestamp,
                    block.difficulty,
                    blockhash(block.number - 1),
                    address(this)
                )
            )
        );

        randomResults[_requestId] = random;

        _fullfillRandomness(_requestId, random);
    }

    function getMessageHash(uint256 _requestId, uint256 _randInput)
        public
        view
        returns (bytes32)
    {
        uint256 prevRandom = randomResults[_requestId - 1];
        return
            keccak256(
                abi.encodePacked(
                    prevRandom,
                    requestInitializers[_requestId],
                    _randInput
                )
            );
    }

    function convertSignatures(bytes[] memory _signatures)
        external
        pure
        returns (uint64[] memory)
    {
        uint64[] memory results = new uint64[](_signatures.length);
        for (uint256 i = 0; i < _signatures.length; i++) {
            results[i] = uint64(Converter.toUint256(_signatures[i]));
        }
        return results;
    }
}