// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "../interfaces/ICCMPRouterAdaptor.sol";

import "./wormhole/interfaces/IWormhole.sol";

contract WormholeAdaptor is ICCMPRouterAdaptor {

    IWormhole public _wormhole;
    uint8 constant CONSISTENCY_LEVEL = 1;

    event PayloadEnroute(uint64 sequenceID, uint256 messageID);

    constructor(address deployedWormholeContract) {
        _wormhole = IWormhole(deployedWormholeContract);
    }

    function routePayload(uint256 messageID, bytes calldata payload, uint32 nonce) external override /** TODO: returns(uint64 sequenceID) */ {
        uint64 sequenceID = _wormhole.publishMessage(nonce, payload, CONSISTENCY_LEVEL);
        // update nonce
        emit PayloadEnroute(sequenceID, messageID);
    }

    function receivePayload(bytes calldata encodedMessage) external override view returns(bytes memory) {
        (IWormhole.VM memory vm, bool valid, string memory reason) = _wormhole.parseAndVerifyVM(encodedMessage);
        require(valid, reason);

        return vm.payload;
    }

    function performCallback(uint256 messageID, uint256 payloadID, bool success, bytes memory data) external override {

    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface ICCMPRouterAdaptor {
    function routePayload(
        uint256 messageID,
        bytes calldata payload,
        uint32 nonce
    ) external;

    function receivePayload(bytes calldata encodedMessage) external returns(bytes memory);

    function performCallback(uint256 messageID, uint256 payloadID, bool success, bytes memory data) external;
}

// contracts/Messages.sol
// SPDX-License-Identifier: Apache 2

pragma solidity ^0.8.0;

import "../Structs.sol";

interface IWormhole is Structs {
    event LogMessagePublished(address indexed sender, uint64 sequence, uint32 nonce, bytes payload, uint8 consistencyLevel);

    function publishMessage(
        uint32 nonce,
        bytes memory payload,
        uint8 consistencyLevel
    ) external payable returns (uint64 sequence);

    function parseAndVerifyVM(bytes calldata encodedVM) external view returns (Structs.VM memory vm, bool valid, string memory reason);

    function verifyVM(Structs.VM memory vm) external view returns (bool valid, string memory reason);

    function verifySignatures(bytes32 hash, Structs.Signature[] memory signatures, Structs.GuardianSet memory guardianSet) external pure returns (bool valid, string memory reason) ;

    function parseVM(bytes memory encodedVM) external pure returns (Structs.VM memory vm);

    function getGuardianSet(uint32 index) external view returns (Structs.GuardianSet memory) ;

    function getCurrentGuardianSetIndex() external view returns (uint32) ;

    function getGuardianSetExpiry() external view returns (uint32) ;

    function governanceActionIsConsumed(bytes32 hash) external view returns (bool) ;

    function isInitialized(address impl) external view returns (bool) ;

    function chainId() external view returns (uint16) ;

    function governanceChainId() external view returns (uint16);

    function governanceContract() external view returns (bytes32);

    function messageFee() external view returns (uint256) ;
}

// contracts/Structs.sol
// SPDX-License-Identifier: Apache 2

pragma solidity ^0.8.0;

interface Structs {
	struct Provider {
		uint16 chainId;
		uint16 governanceChainId;
		bytes32 governanceContract;
	}

	struct GuardianSet {
		address[] keys;
		uint32 expirationTime;
	}

	struct Signature {
		bytes32 r;
		bytes32 s;
		uint8 v;
		uint8 guardianIndex;
	}

	struct VM {
		uint8 version;
		uint32 timestamp;
		uint32 nonce;
		uint16 emitterChainId;
		bytes32 emitterAddress;
		uint64 sequence;
		uint8 consistencyLevel;
		bytes payload;

		uint32 guardianSetIndex;
		Signature[] signatures;

		bytes32 hash;
	}
}