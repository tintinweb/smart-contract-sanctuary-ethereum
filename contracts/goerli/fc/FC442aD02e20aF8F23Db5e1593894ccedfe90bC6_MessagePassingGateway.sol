// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./interfaces/ICCMPGateway.sol";
import "./interfaces/ICCMPRouterAdaptor.sol";

import "./adaptors/WormholeAdaptor.sol";
import "./structures/CrossChainMessage.sol";

contract MessagePassingGateway is ICCMPGateway {

    mapping(string => address) adaptors;
    mapping(uint256 => CCMPMessage) messages;
    mapping(address => uint32) nonces;

    uint256[] messageIDs;

    event MessageSent(uint256 chainID, string adaptor, bytes message, address sender);
    event MessageReceived(uint256 chainID, string adaptor, bytes messagePayload, address sender);

    function sendMessage(uint256 chainID, string calldata adaptor, bytes calldata message) external override returns (bool sent) {
        uint32 nonce = nonces[msg.sender] + 1;

        CCMPMessage memory _message = _deserializeMessage(message);

        ICCMPRouterAdaptor(adaptors[adaptor]).routePayload(messageIDs.length, _message.payload.data, nonce);
        
        messages[messageIDs.length] = _message;
        messageIDs.push(messageIDs.length);

        emit MessageSent(chainID, adaptor, message, msg.sender);
        return true;
    }

    function receiveMessage(bytes calldata messagePayload, string calldata adaptor) external override returns (bool received) {
        bytes memory receivedPayload = ICCMPRouterAdaptor(adaptors[adaptor]).receivePayload(messagePayload);

        // TODO: fix ALL params
        emit MessageReceived(1, adaptor, receivedPayload, msg.sender);
        
        return received;
    }

    function executeMessage(uint256 messageID, uint256 payloadID, bytes memory data) external override {

    }

    // TODO have a modifier for these two
    function setRouterAdaptor(string calldata name, address adaptor) external override {
        adaptors[name] = adaptor;
    }
    
    function getRouterAdaptor(string calldata name) view external override returns (address adaptor) {
        return adaptors[name];
    }

    function _deserializeMessage(bytes calldata rawMessage) pure private returns(CCMPMessage memory parsedMessage) {
        parsedMessage = abi.decode(rawMessage, (CCMPMessage));
        // TODO: perform deep deserilization on `parsedMessage.payload`
    }

    // function _serializeMessage(CCMPMessage memory parsedMessage) pure private returns(bytes memory rawMessage) {
    //     rawMessage = abi.encode(parsedMessage, (CCMPMessage));
    // }

}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface ICCMPGateway {

    function sendMessage(
        uint256 chainID,
        string calldata adaptor,
        bytes calldata message
    ) external returns (bool sent);

    function receiveMessage(
        bytes calldata messagePayload,
        string calldata adaptor
    ) external returns (bool received);

    function executeMessage(uint256 messageID, uint256 payloadID, bytes memory data) external;

    // function transferTokens(
    //     uint256 chainID,
    //     string calldata adaptor,
    //     bytes calldata message,
    //     address tokenAddress,
    //     uint256 amount
    // ) external;

    // function receiveTokens(
    //     uint256 fromChainID,
    //     string calldata adaptor,
    //     bytes calldata message,
    //     uint256 tokenGasPrice
    // ) external;

    function setRouterAdaptor(string calldata name, address adaptor) external;

    function getRouterAdaptor(string calldata name) view external returns (address adaptor);

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

    function routePayload(uint256 messageID, bytes calldata payload, uint32 nonce) external override /** returns(uint64 sequenceID) */ {
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

enum CCMPOperation { ContractCall, TokenTransfer }

struct ContractCallData {
    address contractAddress;
    bytes params;
}

struct TokenTransferData {
    address tokenAddress;
    address receiver;
    uint256 amount;
}

struct CCMPMessagePayload {
    CCMPOperation operation;
    uint256 chainID;
    bytes data;
}

struct CCMPMessage {
    address sender;
    uint256 chainID;
    uint256 nonce;
    string routerAdaptor;
    CCMPMessagePayload payload; // TODO: make it work for many messages
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