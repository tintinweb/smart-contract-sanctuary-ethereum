// SPDX-License-Identifier: MIT
pragma solidity 0.8.10;

import "../core/BridgeCore.sol";

contract TestEmit is BridgeCore {
    event TestEvent(bytes32 indexed id, address indexed who, string what, uint256 when);

    function testTestEvent(bytes32 id, string calldata what) public {
        address who = address(this);
        emit TestEvent(id, who, what, block.timestamp);
    }

    function testOracleRequest(bytes32 requestId, bytes memory selector) public {
        address bridge = address(this);
        uint256 chain = 0xCAFEBABE;
        emit OracleRequest("setRequest", bridge, requestId, selector, bridge, bridge, chain);
    }

    function testReceiveRequest(bytes32 requestId, bytes32 bridgeFrom) public {
        address bridge = address(this);
        emit ReceiveRequest(requestId, bridge, bridgeFrom);
    }
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.10;

abstract contract BridgeCore {
    mapping(address => uint256) internal nonces;
    mapping(bytes32 => mapping(bytes32 => mapping(bytes32 => bool))) internal contractBind;

    event OracleRequest(
        string requestType,
        address bridge,
        bytes32 requestId,
        bytes selector,
        address receiveSide,
        address oppositeBridge,
        uint256 chainId
    );

    event OracleRequestSolana(
        string requestType,
        bytes32 bridge,
        bytes32 requestId,
        bytes selector,
        bytes32 oppositeBridge,
        uint256 chainId
    );

    event ReceiveRequest(bytes32 reqId, address receiveSide, bytes32 bridgeFrom);

    /**
     * @dev Mandatory for all participants who wants to use their own contracts.
     * 1. Contract A (chain A) should be binded with Contract B (chain B) only once! It's not allowed to switch Contract A (chain A) to Contract C (chain B).
     * to prevent malicious behaviour.
     * 2. Contract A (chain A) could be binded with several contracts where every contract from another chain.
     * For ex: Contract A (chain A) --> Contract B (chain B) + Contract A (chain A) --> Contract B' (chain B') ... etc
     * @param from padded sender's address
     * @param oppositeBridge padded opposite bridge address
     * @param to padded recipient address
     */
    function addContractBind(
        bytes32 from,
        bytes32 oppositeBridge,
        bytes32 to
    ) external virtual {
        require(to != "", "Bridge: invalid 'to' address");
        require(from != "", "Bridge: invalid 'from' address");
        contractBind[from][oppositeBridge][to] = true;
    }

    /**
     * @dev Get the nonce of the current sender.
     * @param from sender's address
     */
    function getNonce(address from) public view returns (uint256) {
        return nonces[from];
    }

    /**
     * @dev Verifies and updates the sender's nonce.
     * @param from sender's address
     * @param nonce provided sender's nonce
     */
    function verifyAndUpdateNonce(address from, uint256 nonce) internal {
        require(nonces[from]++ == nonce, "Bridge: nonce mismatch");
    }
}