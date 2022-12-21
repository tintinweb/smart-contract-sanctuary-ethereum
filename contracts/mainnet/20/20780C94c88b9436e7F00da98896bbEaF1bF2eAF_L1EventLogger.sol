// SPDX-License-Identifier: MIT
pragma solidity ^0.8.12;

import "./interface/IL1EventLogger.sol";
import "./interface/IL1EventLoggerEvents.sol";
import "../shared/EventLogger.sol";

contract L1EventLogger is EventLogger, IL1EventLogger, IL1EventLoggerEvents {
    function emitClaimEtherForMultipleNftsMessageSent(
        bytes32 canonicalNftsHash_,
        bytes32 tokenIdsHash_,
        address beneficiary_
    ) external {
        emit ClaimEtherForMultipleNftsMessageSent(
            msg.sender,
            canonicalNftsHash_,
            tokenIdsHash_,
            beneficiary_
        );
    }

    function emitClaimEtherMessageSent(
        address canonicalNft_,
        uint256 tokenId_,
        address beneficiary_
    ) external {
        emit ClaimEtherMessageSent(
            msg.sender,
            canonicalNft_,
            tokenId_,
            beneficiary_
        );
    }

    function emitMarkReplicasAsAuthenticMessageSent(
        address canonicalNft_,
        uint256 tokenId_
    ) external {
        emit MarkReplicasAsAuthenticMessageSent(
            msg.sender,
            canonicalNft_,
            tokenId_
        );
    }

    function emitMarkReplicasAsAuthenticMultipleMessageSent(
        bytes32 canonicalNftsHash_,
        bytes32 tokenIdsHash_
    ) external {
        emit MarkReplicasAsAuthenticMultipleMessageSent(
            msg.sender,
            canonicalNftsHash_,
            tokenIdsHash_
        );
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.12;

import "../../shared/interface/IEventLogger.sol";

interface IL1EventLogger is IEventLogger {
    function emitClaimEtherForMultipleNftsMessageSent(
        bytes32 canonicalNftsHash_,
        bytes32 tokenIdsHash_,
        address beneficiary_
    ) external;

    function emitClaimEtherMessageSent(
        address canonicalNft_,
        uint256 tokenId_,
        address beneficiary_
    ) external;

    function emitMarkReplicasAsAuthenticMessageSent(
        address canonicalNft_,
        uint256 tokenId_
    ) external;

    function emitMarkReplicasAsAuthenticMultipleMessageSent(
        bytes32 canonicalNftsHash_,
        bytes32 tokenIdsHash_
    ) external;
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.12;

import "../../shared/interface/IEventLoggerEvents.sol";

interface IL1EventLoggerEvents is IEventLoggerEvents {
    event ClaimEtherForMultipleNftsMessageSent(
        address indexed l1TokenClaimBridge,
        bytes32 canonicalNftsHash,
        bytes32 tokenIdsHash,
        address indexed beneficiary
    );

    event ClaimEtherMessageSent(
        address indexed l1TokenClaimBridge,
        address indexed canonicalNft,
        uint256 tokenId,
        address indexed beneficiary
    );

    event MarkReplicasAsAuthenticMessageSent(
        address indexed l1TokenClaimBridge,
        address indexed canonicalNft,
        uint256 tokenId
    );

    event MarkReplicasAsAuthenticMultipleMessageSent(
        address indexed l1TokenClaimBridge,
        bytes32 canonicalNftsHash,
        bytes32 tokenIdsHash
    );
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.12;

import "./interface/IEventLogger.sol";
import "./interface/IEventLoggerEvents.sol";

abstract contract EventLogger is IEventLogger, IEventLoggerEvents {
    function emitReplicaDeployed(address replica_) external {
        emit ReplicaDeployed(msg.sender, replica_);
    }

    function emitReplicaRegistered(
        address canonicalNftContract_,
        uint256 canonicalTokenId_,
        address replica_
    ) external {
        emit ReplicaRegistered(
            msg.sender,
            canonicalNftContract_,
            canonicalTokenId_,
            replica_
        );
    }

    function emitReplicaTransferred(
        uint256 canonicalTokenId_,
        uint256 replicaTokenId_
    ) external {
        emit ReplicaTransferred(msg.sender, canonicalTokenId_, replicaTokenId_);
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.12;

interface IEventLogger {
    function emitReplicaDeployed(address replica_) external;

    function emitReplicaTransferred(
        uint256 canonicalTokenId_,
        uint256 replicaTokenId_
    ) external;

    function emitReplicaRegistered(
        address canonicalNftContract_,
        uint256 canonicalTokenId_,
        address replica_
    ) external;
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.12;

//**
//* As convention, we put the indexed address of the caller as the first parameter of each event.
//* This is so that we can verify that the (indirect) emitter of the event is a verified part
//* of the protocol.
//**
interface IEventLoggerEvents {
    event ReplicaDeployed(
        address indexed replicaFactory,
        address indexed replica
    );

    event ReplicaRegistered(
        address indexed replicaRegistry,
        address indexed canonicalNftContract,
        uint256 canonicalTokenId,
        address indexed replica
    );

    event ReplicaTransferred(
        address indexed replica,
        uint256 canonicalTokenId,
        uint256 replicaTokenId
    );
}