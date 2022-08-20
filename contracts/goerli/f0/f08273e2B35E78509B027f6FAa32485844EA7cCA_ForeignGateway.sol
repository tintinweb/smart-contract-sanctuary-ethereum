// SPDX-License-Identifier: MIT

pragma solidity ^0.8;

import "./IArbitrator.sol";

/**
 * @title IArbitrable
 * Arbitrable interface. Note that this interface follows the ERC-792 standard.
 * When developing arbitrable contracts, we need to:
 * - Define the action taken when a ruling is received by the contract.
 * - Allow dispute creation. For this a function must call arbitrator.createDispute{value: _fee}(_choices,_extraData);
 */
interface IArbitrable {
    /**
     * @dev To be raised when a ruling is given.
     * @param _arbitrator The arbitrator giving the ruling.
     * @param _disputeID ID of the dispute in the Arbitrator contract.
     * @param _ruling The ruling which was given.
     */
    event Ruling(IArbitrator indexed _arbitrator, uint256 indexed _disputeID, uint256 _ruling);

    /**
     * @dev Give a ruling for a dispute. Must be called by the arbitrator.
     * The purpose of this function is to ensure that the address calling it has the right to rule on the contract.
     * @param _disputeID ID of the dispute in the Arbitrator contract.
     * @param _ruling Ruling given by the arbitrator. Note that 0 is reserved for "Not able/wanting to make a decision".
     */
    function rule(uint256 _disputeID, uint256 _ruling) external;
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8;

import "./IArbitrable.sol";

/**
 * @title Arbitrator
 * Arbitrator interface that implements the new arbitration standard.
 * Unlike the ERC-792 this standard doesn't have anything related to appeals, so each arbitrator can implement an appeal system that suits it the most.
 * When developing arbitrator contracts we need to:
 * - Define the functions for dispute creation (createDispute). Don't forget to store the arbitrated contract and the disputeID (which should be unique, may nbDisputes).
 * - Define the functions for cost display (arbitrationCost).
 * - Allow giving rulings. For this a function must call arbitrable.rule(disputeID, ruling).
 */
interface IArbitrator {
    /**
     * @dev To be emitted when a dispute is created.
     * @param _disputeID ID of the dispute.
     * @param _arbitrable The contract which created the dispute.
     */
    event DisputeCreation(uint256 indexed _disputeID, IArbitrable indexed _arbitrable);

    /**
     * @dev Create a dispute. Must be called by the arbitrable contract.
     * Must pay at least arbitrationCost(_extraData).
     * @param _choices Amount of choices the arbitrator can make in this dispute.
     * @param _extraData Can be used to give additional info on the dispute to be created.
     * @return disputeID ID of the dispute created.
     */
    function createDispute(uint256 _choices, bytes calldata _extraData) external payable returns (uint256 disputeID);

    /**
     * @dev Compute the cost of arbitration. It is recommended not to increase it often, as it can be highly time and gas consuming for the arbitrated contracts to cope with fee augmentation.
     * @param _extraData Can be used to give additional info on the dispute to be created.
     * @return cost Required cost of arbitration.
     */
    function arbitrationCost(bytes calldata _extraData) external view returns (uint256 cost);
}

// SPDX-License-Identifier: MIT

/**
 *  @authors: [@jaybuidl, @shotaronowhere, @hrishibhat]
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
     * @param _epoch The epoch for which the the claim was made.
     * @param _batchMerkleRoot The timestamp of the claim creation.
     */
    event ClaimReceived(uint256 indexed _epoch, bytes32 indexed _batchMerkleRoot);

    /**
     * @dev This event indicates that `sendSafeFallback()` should be called on the sending side.
     * @param _epoch The epoch associated with the challenged claim.
     */
    event ClaimChallenged(uint256 indexed _epoch);

    /**
     * @dev This events indicates that optimistic verification has succeeded. The messages are ready to be relayed.
     * @param _epoch The epoch associated with the batch.
     * @param _success The success of the optimistic verification.
     */
    event BatchVerified(uint256 indexed _epoch, bool _success);

    /**
     * @dev This event indicates that the batch has been received via the Safe Bridge.
     * @param _epoch The epoch associated with the batch.
     * @param _isBridgerHonest Whether the bridger made an honest claim.
     * @param _isChallengerHonest Whether the bridger made an honest challenge.
     */
    event BatchSafeVerified(uint256 indexed _epoch, bool _isBridgerHonest, bool _isChallengerHonest);

    /**
     * @dev This event indicates that the claim deposit has been withdrawn.
     * @param _epoch The epoch associated with the batch.
     * @param _bridger The recipient of the claim deposit.
     */
    event ClaimDepositWithdrawn(uint256 indexed _epoch, address indexed _bridger);

    /**
     * @dev This event indicates that the challenge deposit has been withdrawn.
     * @param _epoch The epoch associated with the batch.
     * @param _challenger The recipient of the challenge deposit.
     */
    event ChallengeDepositWithdrawn(uint256 indexed _epoch, address indexed _challenger);

    /**
     * @dev This event indicates that a message has been relayed for the batch in this `_epoch`.
     * @param _epoch The epoch associated with the batch.
     * @param _nonce The nonce of the message that was relayed.
     */
    event MessageRelayed(uint256 indexed _epoch, uint256 indexed _nonce);

    // ************************************* //
    // *        Function Modifiers         * //
    // ************************************* //

    /**
     * @dev Submit a claim about the `_batchMerkleRoot` for the latests completed Fast bridge epoch and submit a deposit. The `_batchMerkleRoot` should match the one on the sending side otherwise the sender will lose his deposit.
     * @param _epoch The epoch of the claim to claim.
     * @param _batchMerkleRoot The hash claimed for the ticket.
     */
    function claim(uint256 _epoch, bytes32 _batchMerkleRoot) external payable;

    /**
     * @dev Submit a challenge for the claim of the current epoch's Fast Bridge batch merkleroot state and submit a deposit. The `batchMerkleRoot` in the claim already made for the last finalized epoch should be different from the one on the sending side, otherwise the sender will lose his deposit.
     * @param _epoch The epoch of the claim to challenge.
     */
    function challenge(uint256 _epoch) external payable;

    /**
     * @dev Resolves the optimistic claim for '_epoch'.
     * @param _epoch The epoch of the optimistic claim.
     */
    function verifyBatch(uint256 _epoch) external;

    /**
     * @dev Verifies merkle proof for the given message and associated nonce for the most recent possible epoch and relays the message.
     * @param _epoch The epoch in which the message was batched by the bridge.
     * @param _proof The merkle proof to prove the membership of the message and nonce in the merkle tree for the epoch.
     * @param _message The data on the cross-domain chain for the message.
     */
    function verifyAndRelayMessage(
        uint256 _epoch,
        bytes32[] calldata _proof,
        bytes calldata _message
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
     * @param _epoch The epoch of the claim to request the challenge period.
     * @return start The start time of the challenge period.
     * @return end The end time of the challenge period.
     */
    function claimChallengePeriod(uint256 _epoch) external view returns (uint256 start, uint256 end);

    /**
     * @dev Returns the epoch period.
     */
    function epochPeriod() external view returns (uint256 epochPeriod);

    /**
     * @dev Returns the challenge period.
     */
    function challengePeriod() external view returns (uint256 challengePeriod);
}

// SPDX-License-Identifier: MIT

/**
 *  @authors: [@jaybuidl, @shotaronowhere]
 *  @reviewers: []
 *  @auditors: []
 *  @bounties: []
 *  @deployments: []
 */

pragma solidity ^0.8.0;

import "../../bridge/interfaces/IFastBridgeReceiver.sol";

interface IReceiverGateway {
    function fastBridgeReceiver() external view returns (IFastBridgeReceiver);

    function senderChainID() external view returns (uint256);

    function senderGateway() external view returns (address);
}

// SPDX-License-Identifier: MIT

/**
 *  @authors: [@jaybuidl, @shotaronowhere, @shalzz]
 *  @reviewers: []
 *  @auditors: []
 *  @bounties: []
 *  @deployments: []
 */

pragma solidity ^0.8.0;

import "../arbitration/IArbitrable.sol";
import "./interfaces/IForeignGateway.sol";

/**
 * Foreign Gateway
 * Counterpart of `HomeGateway`
 */
contract ForeignGateway is IForeignGateway {
    // ************************************* //
    // *         Enums / Structs           * //
    // ************************************* //

    struct DisputeData {
        uint248 id;
        bool ruled;
        address arbitrable;
        uint256 paid;
        address relayer;
    }

    // ************************************* //
    // *              Events               * //
    // ************************************* //

    event OutgoingDispute(
        bytes32 disputeHash,
        bytes32 blockhash,
        uint256 localDisputeID,
        uint256 _choices,
        bytes _extraData,
        address arbitrable
    );

    // ************************************* //
    // *             Storage               * //
    // ************************************* //

    uint256 public constant MIN_JURORS = 3; // The global default minimum number of jurors in a dispute.
    uint256 public immutable override senderChainID;
    address public immutable override senderGateway;
    uint256 internal localDisputeID = 1; // The disputeID must start from 1 as the KlerosV1 proxy governor depends on this implementation. We now also depend on localDisputeID not ever being zero.
    uint256[] internal feeForJuror; // feeForJuror[subcourtID]
    address public governor;
    IFastBridgeReceiver public fastBridgeReceiver;
    IFastBridgeReceiver public depreciatedFastbridge;
    uint256 public depreciatedFastBridgeExpiration;
    mapping(bytes32 => DisputeData) public disputeHashtoDisputeData;

    // ************************************* //
    // *        Function Modifiers         * //
    // ************************************* //

    modifier onlyFromFastBridge() {
        require(
            address(fastBridgeReceiver) == msg.sender ||
                ((block.timestamp < depreciatedFastBridgeExpiration) && address(depreciatedFastbridge) == msg.sender),
            "Access not allowed: Fast Bridge only."
        );
        _;
    }

    modifier onlyByGovernor() {
        require(governor == msg.sender, "Access not allowed: Governor only.");
        _;
    }

    constructor(
        address _governor,
        IFastBridgeReceiver _fastBridgeReceiver,
        uint256[] memory _feeForJuror,
        address _senderGateway,
        uint256 _senderChainID
    ) {
        governor = _governor;
        fastBridgeReceiver = _fastBridgeReceiver;
        feeForJuror = _feeForJuror;
        senderGateway = _senderGateway;
        senderChainID = _senderChainID;
    }

    // ************************************* //
    // *           Governance              * //
    // ************************************* //

    /**
     * @dev Changes the fastBridge, useful to increase the claim deposit.
     * @param _fastBridgeReceiver The address of the new fastBridge.
     * @param _gracePeriod The duration to accept messages from the deprecated bridge (if at all).
     */
    function changeFastbridge(IFastBridgeReceiver _fastBridgeReceiver, uint256 _gracePeriod) external onlyByGovernor {
        // grace period to relay remaining messages in the relay / bridging process
        depreciatedFastBridgeExpiration = block.timestamp + _fastBridgeReceiver.epochPeriod() + _gracePeriod; // 2 weeks
        depreciatedFastbridge = fastBridgeReceiver;
        fastBridgeReceiver = _fastBridgeReceiver;
    }

    /**
     * @dev Changes the `feeForJuror` property value of a specified subcourt.
     * @param _subcourtID The ID of the subcourt.
     * @param _feeForJuror The new value for the `feeForJuror` property value.
     */
    function changeSubcourtJurorFee(uint96 _subcourtID, uint256 _feeForJuror) external onlyByGovernor {
        feeForJuror[_subcourtID] = _feeForJuror;
    }

    /**
     * @dev Creates the `feeForJuror` property value for a new subcourt.
     * @param _feeForJuror The new value for the `feeForJuror` property value.
     */
    function createSubcourtJurorFee(uint256 _feeForJuror) external onlyByGovernor {
        feeForJuror.push(_feeForJuror);
    }

    // ************************************* //
    // *         State Modifiers           * //
    // ************************************* //

    function createDispute(uint256 _choices, bytes calldata _extraData)
        external
        payable
        override
        returns (uint256 disputeID)
    {
        require(msg.value >= arbitrationCost(_extraData), "Not paid enough for arbitration");

        disputeID = localDisputeID++;
        uint256 chainID;
        assembly {
            chainID := chainid()
        }
        bytes32 disputeHash = keccak256(
            abi.encodePacked(
                chainID,
                blockhash(block.number - 1),
                "createDispute",
                disputeID,
                _choices,
                _extraData,
                msg.sender
            )
        );

        disputeHashtoDisputeData[disputeHash] = DisputeData({
            id: uint248(disputeID),
            arbitrable: msg.sender,
            paid: msg.value,
            relayer: address(0),
            ruled: false
        });

        emit OutgoingDispute(disputeHash, blockhash(block.number - 1), disputeID, _choices, _extraData, msg.sender);
        emit DisputeCreation(disputeID, IArbitrable(msg.sender));
    }

    function arbitrationCost(bytes calldata _extraData) public view override returns (uint256 cost) {
        (uint96 subcourtID, uint256 minJurors) = extraDataToSubcourtIDMinJurors(_extraData);

        cost = feeForJuror[subcourtID] * minJurors;
    }

    /**
     * Relay the rule call from the home gateway to the arbitrable.
     */
    function relayRule(
        address _messageSender,
        bytes32 _disputeHash,
        uint256 _ruling,
        address _relayer
    ) external override onlyFromFastBridge {
        require(_messageSender == senderGateway, "Only the homegateway is allowed.");
        DisputeData storage dispute = disputeHashtoDisputeData[_disputeHash];

        require(dispute.id != 0, "Dispute does not exist");
        require(!dispute.ruled, "Cannot rule twice");

        dispute.ruled = true;
        dispute.relayer = _relayer;

        IArbitrable arbitrable = IArbitrable(dispute.arbitrable);
        arbitrable.rule(dispute.id, _ruling);
    }

    function withdrawFees(bytes32 _disputeHash) external override {
        DisputeData storage dispute = disputeHashtoDisputeData[_disputeHash];
        require(dispute.id != 0, "Dispute does not exist");
        require(dispute.ruled, "Not ruled yet");

        uint256 amount = dispute.paid;
        dispute.paid = 0;
        payable(dispute.relayer).transfer(amount);
    }

    // ************************************* //
    // *           Public Views            * //
    // ************************************* //

    function disputeHashToForeignID(bytes32 _disputeHash) external view override returns (uint256) {
        return disputeHashtoDisputeData[_disputeHash].id;
    }

    // ************************ //
    // *       Internal       * //
    // ************************ //

    function extraDataToSubcourtIDMinJurors(bytes memory _extraData)
        internal
        view
        returns (uint96 subcourtID, uint256 minJurors)
    {
        // Note that here we ignore DisputeKitID
        if (_extraData.length >= 64) {
            assembly {
                // solium-disable-line security/no-inline-assembly
                subcourtID := mload(add(_extraData, 0x20))
                minJurors := mload(add(_extraData, 0x40))
            }
            if (subcourtID >= feeForJuror.length) subcourtID = 0;
            if (minJurors == 0) minJurors = MIN_JURORS;
        } else {
            subcourtID = 0;
            minJurors = MIN_JURORS;
        }
    }
}

// SPDX-License-Identifier: MIT

/**
 *  @authors: [@jaybuidl, @shotaronowhere, @shalzz]
 *  @reviewers: []
 *  @auditors: []
 *  @bounties: []
 *  @deployments: []
 */

pragma solidity ^0.8.0;

import "../../arbitration/IArbitrator.sol";
import "../../bridge/interfaces/IReceiverGateway.sol";

interface IForeignGateway is IArbitrator, IReceiverGateway {
    /**
     * Relay the rule call from the home gateway to the arbitrable.
     */
    function relayRule(
        address _messageSender,
        bytes32 _disputeHash,
        uint256 _ruling,
        address _forwarder
    ) external;

    function withdrawFees(bytes32 _disputeHash) external;

    // For cross-chain Evidence standard
    function disputeHashToForeignID(bytes32 _disputeHash) external view returns (uint256);
}