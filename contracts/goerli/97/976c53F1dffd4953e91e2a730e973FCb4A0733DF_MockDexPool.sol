// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

interface IBridgeV2 {

    enum State { Active, Inactive }

    struct SendParams {
        /// @param requestId unique request ID
        bytes32 requestId;
        /// @param data call data
        bytes data;
        /// @param to receiver contract address
        address to;
        /// @param chainIdTo destination chain ID
        uint256 chainIdTo;
    }

    struct ReceiveParams {
        /// @param blockHeader block header serialization
        bytes blockHeader;
        /// @param merkleProof OracleRequest transaction payload and its Merkle audit path
        bytes merkleProof;
        /// @param votersPubKey aggregated public key of the old epoch participants, who voted for the block
        bytes votersPubKey;
        /// @param votersSignature aggregated signature of the old epoch participants, who voted for the block
        bytes votersSignature;
        /// @param votersMask bitmask of epoch participants, who voted, among all participants
        uint256 votersMask;
    }

    function sendV2(
        SendParams calldata params,
        address sender,
        uint256 nonce
    ) external returns (bool);

    function receiveV2(ReceiveParams[] calldata params) external returns (bool);

    function nonces(address from) external view returns (uint256);
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

interface IGatekeeper {

    function transmitValidatedOracleData(
        bytes calldata data,
        address destinationContract,
        address sender,
        uint256 chainIdFrom,
        bytes32 txId
    ) external;

    function calculateCost(
        address payToken,
        uint256 dataLength,
        uint256 chainIdTo,
        address sender
    ) external returns (uint256 amountToPay);

    function sendData(
        bytes calldata data,
        address destinationContract,
        uint256 chainIdTo,
        address receiveSide,
        address oppositeBridgeV2,
        address payToken
    ) external payable;
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

library RequestIdLib {
    /**
     * @dev Prepares a request ID with the given arguments.
     * @param oppositeBridge padded opposite bridge address
     * @param chainIdTo opposite chain ID
     * @param chainIdFrom current chain ID
     * @param receiveSide padded receive contract address
     * @param from padded sender's address
     * @param nonce current nonce
     */
    function prepareRqId(
        bytes32 oppositeBridge,
        uint256 chainIdTo,
        uint256 chainIdFrom,
        bytes32 receiveSide,
        bytes32 from,
        uint256 nonce
    ) internal pure returns (bytes32) {
        return keccak256(abi.encodePacked(from, nonce, chainIdTo, chainIdFrom, receiveSide, oppositeBridge));
    }

    function prepareRequestId(
        bytes32 to,
        uint256 chainIdTo,
        bytes32 from,
        uint256 chainIdFrom,
        uint256 nonce
    ) internal pure returns (bytes32) {
        return keccak256(abi.encodePacked(from, nonce, chainIdTo, chainIdFrom, to));
    }
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

import "../contracts/interfaces/IBridgeV2.sol";
import "../contracts/interfaces/IGateKeeper.sol";
import "../contracts/utils/RequestIdLib.sol";

/**
 * @notice This is for test purpose.
 *
 * @dev Short life cycle
 * @dev POOL_1#sendRequestTest --> {logic bridge} --> POOL_2#setPendingRequestsDone
 */
contract MockDexPool {
    uint256 public testData = 0;
    address public bridge;
    address public gateKeeper;
    mapping(bytes32 => uint256) public requests;
    bytes32[] public doubleRequestIds;
    uint256 public totalRequests = 0;


    event RequestSent(bytes32 reqId);
    event RequestReceived(uint256 data);
    event RequestReceivedV2(bytes32 reqId, uint256 data);
    event TestEvent(bytes testData_, address receiveSide, address oppositeBridge, uint256 chainId);

    constructor(address bridge_, address gatekeeper_) {
        bridge = bridge_;
        gateKeeper = gatekeeper_;
    }

    function sendTest2(
        bytes memory testData_,
        address receiveSide_,
        address oppositeBridge_,
        uint256 chainId_
    ) external {
        emit TestEvent(testData_, receiveSide_, oppositeBridge_, chainId_);
    }

    /**
     * @notice send request like second part of pool
     *
     * @dev LIFE CYCLE
     * @dev ${this pool} -> POOL_2
     * @dev ${this func} ->  bridge#transmitRequest -> node -> adpater#receiveRequest -> mockDexPool_2#receiveRequestTest -> bridge#transmitResponse(reqId) -> node -> adpater#receiveResponse -> mockDexPool_1#setPendingRequestsDone
     *
     */
    function sendRequestTestV2(
        uint256 testData_,
        address receiveSide,
        address oppositeBridge,
        uint256 chainId
    ) external {
        require(receiveSide != address(0), "MockDexPool: zero address");

        uint256 nonce = IBridgeV2(bridge).nonces(msg.sender);
        bytes32 requestId = RequestIdLib.prepareRqId(
            bytes32(uint256(uint160(oppositeBridge))),
            chainId,
            block.chainid,
            bytes32(uint256(uint160(receiveSide))),
            bytes32(uint256(uint160(msg.sender))),
            nonce
        );
        bytes memory output = abi.encodeWithSelector(
            bytes4(keccak256(bytes("receiveRequestTest(uint256,bytes32)"))),
            testData_,
            requestId
        );

        IBridgeV2.SendParams memory sendParams = IBridgeV2.SendParams(
            requestId,
            output,
            receiveSide,
            chainId
        );

        IBridgeV2(bridge).sendV2(sendParams, msg.sender, nonce);

        emit RequestSent(requestId);
    }

    function sendViaGatekeeper(
        uint256 testData_,
        uint256 chainId,
        address receiveSide,
        address oppositeBridge,
        address payToken
    ) external {
        require(receiveSide != address(0), "MockDexPool: zero address");

        uint256 nonce = IBridgeV2(bridge).nonces(msg.sender);
        bytes32 requestId = RequestIdLib.prepareRqId(
            bytes32(uint256(uint160(oppositeBridge))),
            chainId,
            block.chainid,
            bytes32(uint256(uint160(receiveSide))),
            bytes32(uint256(uint160(msg.sender))),
            nonce
        );
        bytes memory output = abi.encodeWithSelector(
            bytes4(keccak256(bytes("receiveRequestTest(uint256,bytes32)"))),
            testData_,
            requestId
        );

        IGatekeeper(gateKeeper).sendData(
            output,
            receiveSide,
            chainId,
            receiveSide,
            oppositeBridge,
            payToken
        );
    }

    function sendRequestTestV2Unsafe(
        uint256 testData_,
        address receiveSide,
        address oppositeBridge,
        uint256 chainId,
        bytes32 requestId,
        uint256 nonce
    ) external {
        require(receiveSide != address(0), "MockDexPool: zero address");

        bytes memory output = abi.encodeWithSelector(
            bytes4(keccak256(bytes("receiveRequestTest(uint256,bytes32)"))),
            testData_,
            requestId
        );

        IBridgeV2.SendParams memory sendParams = IBridgeV2.SendParams(
            requestId,
            output,
            receiveSide,
            chainId
        );

        IBridgeV2(bridge).sendV2(sendParams, msg.sender, nonce);

        emit RequestSent(requestId);
    }

    /**
     * @notice receive request on the second part of pool
     *
     * @dev LIFE CYCLE
     * @dev POOL_1 -> ${this pool}
     * @dev mockDexPool_1#sendRequestTest -> bridge#transmitRequest -> node -> adpater#receiveRequest -> ${this func} -> bridge#transmitResponse(reqId) -> node -> adpater#receiveResponse -> mockDexPool_1#setPendingRequestsDone
     */
    function receiveRequestTest(uint256 newData, bytes32 reqId) public {
        require(msg.sender == bridge, "MockDexPool: only certain bridge");

        if (requests[reqId] != 0) {
            doubleRequestIds.push(reqId);
        }
        requests[reqId]++;
        totalRequests++;

        testData = newData;
        emit RequestReceived(newData);
        emit RequestReceivedV2(reqId, newData);
    }

    function sigHash(string memory data) public pure returns (bytes8) {
        return bytes8(sha256(bytes(data)));
    }

    function doubles() public view returns (bytes32[] memory) {
        return doubleRequestIds;
    }

    function doubleRequestError() public view returns (uint256) {
        return doubleRequestIds.length;
    }

    function clearStats() public {
        delete doubleRequestIds;
        totalRequests = 0;
    }

    function calcRequestId(
        address secondPartPool,
        address oppBridge,
        uint256 chainId
    ) external view returns (bytes32, uint256) {
        uint256 nonce = IBridgeV2(bridge).nonces(msg.sender);
        bytes32 reqId = RequestIdLib.prepareRqId(
            bytes32(uint256(uint160(oppBridge))),
            chainId,
            block.chainid,
            bytes32(uint256(uint160(secondPartPool))),
            bytes32(uint256(uint160(msg.sender))),
            nonce
        );
        return (reqId, nonce);
    }
}