// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./interfaces/IFraxFerry.sol";
import "./interfaces/ISourceAMB.sol";

// On Goerli

// off-chain, when we see a Depart event on the target Ferry, then call
// sendTrustlessBatchHash(start,end,batchNo) on source chain Ferry

contract PermissionlessCrewmemberDispatch {
    IFraxFerry fraxFerry;
    uint16 targetChainId;
    ISourceAMB succinct;
    uint256 GAS_LIMIT = 64_080;

    event TrustlessBatchHashSent(
        uint256 indexed start,
        uint256 indexed end,
        uint256 indexed batchNo,
        bytes32 hash,
        address crewMember
    );

    constructor(
        address _fraxFerry,
        uint16 _targetChainId,
        address _succinct
    ) {
        fraxFerry = IFraxFerry(_fraxFerry);
        targetChainId = _targetChainId;
        succinct = ISourceAMB(_succinct);
    }

    /**
     * @notice gets the batch transaction hash for the given params
     * and relays it to the crewmember on the target chain
     * @param start start param from target chain Depart
     * @param end end param from target chain Depart
     * @param batchNo batchNo param from target chain Depart
     * @param crewMember address of crewmember on target chain
     */
    function sendTrustlessBatchHash(
        uint256 start,
        uint256 end,
        uint256 batchNo,
        address crewMember
    ) external {
        bytes32 hash = fraxFerry.getTransactionsHash(start, end);

        bytes memory msgData = abi.encode(start, end, batchNo, hash);

        succinct.send(crewMember, targetChainId, GAS_LIMIT, msgData);

        emit TrustlessBatchHashSent(start, end, batchNo, hash, crewMember);
    }
}

// On target chains (Arbitrum, etc.)

contract PermissionlessCrewmember {
    address dispatcher;
    address succinctReceiver;
    IFraxFerry fraxFerry;

    event BatchHashVerified(uint256 batchNo, bytes32 hash);

    enum BatchStatus {
        NONE,
        VERIFIED,
        DISPUTED
    }
    mapping(bytes32 => BatchStatus) public batchStatuses;

    constructor(
        address _dispatcher,
        address _succinctReceiver,
        address _fraxFerry
    ) {
        dispatcher = _dispatcher;
        succinctReceiver = _succinctReceiver;
        fraxFerry = IFraxFerry(_fraxFerry);
    }

    function receiveSuccinct(address srcAddress, bytes calldata callData)
        external
    {
        require(srcAddress == dispatcher);
        require(msg.sender == succinctReceiver);
        (
            uint256 start,
            uint256 end,
            uint256 batchNo,
            bytes32 trustlessHash
        ) = abi.decode(callData, (uint256, uint256, uint256, bytes32));
        require(fraxFerry.batches(batchNo).start == start);
        require(fraxFerry.batches(batchNo).end == end);
        bytes32 claimedHash = fraxFerry.batches(batchNo).hash;
        if (claimedHash != trustlessHash) {
            batchStatuses[claimedHash] = BatchStatus.DISPUTED;
            fraxFerry.disputeBatch(batchNo, claimedHash);
        } else {
            batchStatuses[claimedHash] = BatchStatus.VERIFIED;
            emit BatchHashVerified(batchNo, trustlessHash);
        }
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface IFraxFerry {
    struct Batch {
        uint64 start;
        uint64 end;
        uint64 departureTime;
        uint64 status;
        bytes32 hash;
    }

    function batches(uint256) external view returns (Batch memory);

    function getTransactionsHash(uint256 start, uint256 end)
        external
        view
        returns (bytes32);

    function disputeBatch(uint256 batchNo, bytes32 hash) external;
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface ISourceAMB {
    function send(
        address recipient,
        uint16 recipientChainId,
        uint256 gasLimit,
        bytes calldata data
    ) external returns (bytes32);
}