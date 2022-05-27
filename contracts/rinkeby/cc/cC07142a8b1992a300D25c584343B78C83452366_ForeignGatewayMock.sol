// SPDX-License-Identifier: MIT

/**
 *  @authors: [@jaybuidl, @shalzz, @hrishibhat, @shotaronowhere]
 *  @reviewers: []
 *  @auditors: []
 *  @bounties: []
 *  @deployments: []
 */

pragma solidity ^0.8.0;

interface IFastBridgeReceiver {
    // ************************************* //
    // *              Events               * //
    // ************************************* //

    /**
     * @dev The Fast Bridge participants watch for these events to decide if a challenge should be submitted.
     * @param _epoch The epoch in  the the claim was made.
     * @param _batchMerkleRoot The timestamp of the claim creation.
     */
    event ClaimReceived(uint256 _epoch, bytes32 indexed _batchMerkleRoot);

    /**
     * @dev The Fast Bridge participants watch for these events to call `sendSafeFallback()` on the sending side.
     * @param _epoch The epoch associated with the challenged claim.
     */
    event ClaimChallenged(uint256 _epoch);

    // ************************************* //
    // *        Function Modifiers         * //
    // ************************************* //

    /**
     * @dev Submit a claim about the `_batchMerkleRoot` for the latests completed Fast bridge epoch and submit a deposit. The `_batchMerkleRoot` should match the one on the sending side otherwise the sender will lose his deposit.
     * @param _batchMerkleRoot The hash claimed for the ticket.
     */
    function claim(bytes32 _batchMerkleRoot) external payable;

    /**
     * @dev Submit a challenge for the claim of the current epoch's Fast Bridge batch merkleroot state and submit a deposit. The `batchMerkleRoot` in the claim already made for the last finalized epoch should be different from the one on the sending side, otherwise the sender will lose his deposit.
     */
    function challenge() external payable;

    /**
     * @dev Verifies merkle proof for the given message and associated nonce for the most recent possible epoch and relays the message.
     * @param _epoch The epoch in which the message was batched by the bridge.
     * @param _proof The merkle proof to prove the membership of the message and nonce in the merkle tree for the epoch.
     * @param _message The data on the cross-domain chain for the message.
     * @param _nonce The nonce (index in the merkle tree) to avoid replay.
     */
    function verifyAndRelayMessage(
        uint256 _epoch,
        bytes32[] calldata _proof,
        bytes calldata _message,
        uint256 _nonce
    ) external;

    /**
     * @dev Sends the deposit back to the Bridger if their claim is not successfully challenged. Includes a portion of the Challenger's deposit if unsuccessfully challenged.
     * @param _epoch The epoch associated with the claim deposit to withraw.
     */
    function withdrawClaimDeposit(uint256 _epoch) external;

    /**
     * @dev Sends the deposit back to the Challenger if his challenge is successful. Includes a portion of the Bridger's deposit.
     * @param _epoch The epoch associated with the challenge deposit to withraw.
     */
    function withdrawChallengeDeposit(uint256 _epoch) external;

    // ************************************* //
    // *           Public Views            * //
    // ************************************* //

    /**
     * @dev Returns the `start` and `end` time of challenge period for this `epoch`.
     * @return start The start time of the challenge period.
     * @return end The end time of the challenge period.
     */
    function challengePeriod() external view returns (uint256 start, uint256 end);

    /**
     * @dev Returns the epoch period.
     */
    function epochPeriod() external view returns (uint256 epoch);
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "../../bridge/interfaces/IFastBridgeReceiver.sol";

interface IForeignGatewayBase {
    /**
     * Receive the message from the home gateway.
     */
    function receiveMessage(address _messageSender) external;

    function fastBridgeReceiver() external view returns (address);

    function homeChainID() external view returns (uint256);

    function homeGateway() external view returns (address);
}

// SPDX-License-Identifier: MIT

/**
 *  @authors: [@shotaronowhere]
 *  @reviewers: []
 *  @auditors: []
 *  @bounties: []
 *  @deployments: []
 */

pragma solidity ^0.8.0;

import "../interfaces/IForeignGatewayBase.sol";

/**
 * Foreign Gateway Mock
 * Counterpart of `HomeGatewayMock`
 */
contract ForeignGatewayMock is IForeignGatewayBase {

    address public immutable fastBridgeReceiver;
    address public immutable override homeGateway;
    uint256 public immutable override homeChainID;

    uint256 public messageCount;
    uint256 public data;

    constructor(
        address _fastBridgeReceiver,
        address _homeGateway,
        uint256 _homeChainID
    ) {
        fastBridgeReceiver = _fastBridgeReceiver;
        homeGateway = _homeGateway;
        homeChainID = _homeChainID;
    }

    modifier onlyFromFastBridge() {
        require(address(fastBridgeReceiver) == msg.sender, "Fast Bridge only.");
        _;
    }

    /**
     * Receive the message from the home gateway.
     */
    function receiveMessage(address _messageSender) external onlyFromFastBridge(){
        require(_messageSender == homeGateway, "Only the homegateway is allowed.");
        _receiveMessage();
    }

    /**
     * Receive the message from the home gateway.
     */
    function receiveMessage(address _messageSender, uint256 _data) external onlyFromFastBridge(){
        require(_messageSender == homeGateway, "Only the homegateway is allowed.");
        _receiveMessage(_data);
    }

    function _receiveMessage() internal {
        messageCount++;
    }

    function _receiveMessage(uint256 _data) internal {
        messageCount++;
        data = _data;
    }
}