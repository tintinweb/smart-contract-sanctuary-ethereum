// SPDX-License-Identifier: MIT

pragma solidity >=0.6.12 <=0.8.9;
pragma experimental ABIEncoderV2;

interface IMessengerWrapper {
    function sendCrossDomainMessage(bytes memory _calldata) external;
    function verifySender(address l1BridgeCaller, bytes memory _data) external;
}

pragma solidity ^0.8.0;
pragma experimental ABIEncoderV2;

// SPDX-License-Identifier: MIT OR Apache-2.0



import {L2Log, L2Message} from "./IStorage.sol";

interface IMailbox {
    /// @dev Structure that includes all fields of the L2 transaction
    /// @dev The hash of this structure is the "canonical L2 transaction hash" and can be used as a unique identifier of a tx
    /// @param txType The tx type number, depending on which the L2 transaction can be interpreted differently
    /// @param from The sender's address. `uint256` type for possible address format changes and maintaining backward compatibility
    /// @param to The recipient's address. `uint256` type for possible address format changes and maintaining backward compatibility
    /// @param ergsLimit Ergs limit on L2 transaction. Analog to the `gasLimit` on an L1 transactions
    /// @param ergsPerPubdataByteLimit Maximum number of ergs that will cost one byte of pubdata (every piece of data that will be stored on L1 as calldata)
    /// @param maxFeePerErg The absolute maximum sender willing to pay per unit of ergs to get the transaction included in a block. Analog to the EIP-1559 `maxFeePerGas` on an L1 transactions
    /// @param maxPriorityFeePerErg The additional fee that is paid directly to the validator to incentivize them to include the transaction in a block. Analog to the EIP-1559 `maxPriorityFeePerGas` on an L1 transactions
    /// @param paymaster The address of the EIP-4337 paymaster, that will pay fees for the transaction. `uint256` type for possible address format changes and maintaining backward compatibility
    /// @param reserved The fixed-length fields for usage in a future extension of transaction formats
    /// @param data The calldata that is transmitted for the transaction call
    /// @param signature An abstract set of bytes that are used for transaction authorization
    /// @param factoryDeps The set of L2 bytecode hashes whose preimages were shown on L1
    /// @param paymasterInput The arbitrary-length data that is used as a calldata to the paymaster pre-call
    /// @param reservedDynamic The arbitrary-length field for usage in a future extension of transaction formats
    struct L2CanonicalTransaction {
        uint256 txType;
        uint256 from;
        uint256 to;
        uint256 ergsLimit;
        uint256 ergsPerPubdataByteLimit;
        uint256 maxFeePerErg;
        uint256 maxPriorityFeePerErg;
        uint256 paymaster;
        // In the future, we might want to add some
        // new fields to the struct. The `txData` struct
        // is to be passed to account and any changes to its structure
        // would mean a breaking change to these accounts. To prevent this,
        // we should keep some fields as "reserved".
        // It is also recommended that their length is fixed, since
        // it would allow easier proof integration (in case we will need
        // some special circuit for preprocessing transactions).
        uint256[6] reserved;
        bytes data;
        bytes signature;
        uint256[] factoryDeps;
        bytes paymasterInput;
        // Reserved dynamic type for the future use-case. Using it should be avoided,
        // But it is still here, just in case we want to enable some additional functionality.
        bytes reservedDynamic;
    }

    function proveL2MessageInclusion(
        uint256 _blockNumber,
        uint256 _index,
        L2Message calldata _message,
        bytes32[] calldata _proof
    ) external view returns (bool);

    function proveL2LogInclusion(
        uint256 _blockNumber,
        uint256 _index,
        L2Log memory _log,
        bytes32[] calldata _proof
    ) external view returns (bool);

    function serializeL2Transaction(
        uint256 _txId,
        uint256 _l2Value,
        address _sender,
        address _contractAddressL2,
        bytes calldata _calldata,
        uint256 _ergsLimit,
        bytes[] calldata _factoryDeps
    ) external pure returns (L2CanonicalTransaction memory);

    function requestL2Transaction(
        address _contractL2,
        uint256 _l2Value,
        bytes calldata _calldata,
        uint256 _l2GasLimit,
        uint256 _l2GasPerPubdataByteLimit,
        bytes[] calldata _factoryDeps,
        address _refundRecipient
    ) external payable returns (bytes32 canonicalTxHash);

    function l2TransactionBaseCost(
        uint256 _gasPrice,
        uint256 _ergsLimit,
        uint256 _calldataLength
    ) external view returns (uint256);

    /// @notice New priority request event. Emitted when a request is placed into the priority queue
    /// @param txId Serial number of the priority operation
    /// @param txHash keccak256 hash of encoded transaction representation
    /// @param expirationBlock Ethereum block number up to which priority request should be processed
    /// @param transaction The whole transaction structure that is requested to be executed on L2
    /// @param factoryDeps An array of bytecodes that were shown in the L1 public data. Will be marked as known bytecodes in L2
    event NewPriorityRequest(
        uint256 txId,
        bytes32 txHash,
        uint64 expirationBlock,
        L2CanonicalTransaction transaction,
        bytes[] factoryDeps
    );
}

pragma solidity ^0.8.0;

/// @dev The log passed from L2
/// @param l2ShardId The shard identifier, 0 - rollup, 1 - porter. All other values are not used but are reserved for the future
/// @param isService A boolean flag that is part of the log along with `key`, `value`, and `sender` address.
/// This field is required formally but does not have any special meaning.
/// @param txNumberInBlock The L2 transaction number in a block, in which the log was sent
/// @param sender The L2 address which sent the log
/// @param key The 32 bytes of information that was sent in the log
/// @param value The 32 bytes of information that was sent in the log
// Both `key` and `value` are arbitrary 32-bytes selected by the log sender
struct L2Log {
    uint8 l2ShardId;
    bool isService;
    uint16 txNumberInBlock;
    address sender;
    bytes32 key;
    bytes32 value;
}

/// @dev An arbitrary length message passed from L2
/// @notice Under the hood it is `L2Log` sent from the special system L2 contract
/// @param txNumberInBlock The L2 transaction number in a block, in which the message was sent
/// @param sender The address of the L2 account from which the message was passed
/// @param data An arbitrary length message
struct L2Message {
    uint16 txNumberInBlock;
    address sender;
    bytes data;
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.12 <=0.8.9;
pragma experimental ABIEncoderV2;

import "../interfaces/IMessengerWrapper.sol";

abstract contract MessengerWrapper is IMessengerWrapper {
    address public immutable l1BridgeAddress;

    constructor(address _l1BridgeAddress) internal {
        l1BridgeAddress = _l1BridgeAddress;
    }

    modifier onlyL1Bridge {
        require(msg.sender == l1BridgeAddress, "MW: Sender must be the L1 Bridge");
        _;
    }
}

// SPDX-License-Identifier: MIT

pragma solidity 0.8.9;
pragma experimental ABIEncoderV2;

import "../interfaces/zksync/messengers/IMailbox.sol";
import "./MessengerWrapper.sol";

/**
 * @dev A MessengerWrapper for ZKSync - https://v2-docs.zksync.io/dev/developer-guides/bridging/l1-l2.html#structure
 * @notice Deployed on layer-1
 */

contract ZkSyncMessengerWrapper is MessengerWrapper {

    IMailbox public zkSyncL1Bridge;
    address public l2BridgeAddress;
    mapping(uint32 => mapping(uint256 => bool)) public processedExits;

    uint256 public l2GasLimit;
    uint256 public l2GasPerPubdataByteLimit;

    constructor(
        address _l1BridgeAddress,
        address _l2BridgeAddress,
        IMailbox _zkSyncL1Bridge
    )
        public
        MessengerWrapper(_l1BridgeAddress)
    {
        l2BridgeAddress = _l2BridgeAddress;
        zkSyncL1Bridge = _zkSyncL1Bridge;
    }

    receive() external payable {}

    /**
     * @dev Sends a message to the l2BridgeAddress from layer-1
     * @param _calldata The data that l2BridgeAddress will be called with
     */
    function sendCrossDomainMessage(bytes memory _calldata) public override onlyL1Bridge {
        // TODO: For mainnet, verify that block.basefee is correct
        // uint256 fee = zkSyncL1Bridge.l2TransactionBaseCost(block.basefee, l2GasLimit, _calldata.length); 
        uint256 fee = 0;
        zkSyncL1Bridge.requestL2Transaction{value: fee}(
            l2BridgeAddress,
            0,
            _calldata,
            l2GasLimit,
            l2GasPerPubdataByteLimit,
            new bytes[](0),
            address(0)
        );
    }

    function verifySender(address l1BridgeCaller, bytes memory) public override {
        require(l1BridgeCaller == address(this), "L1_ZKSYNC_WPR: Caller must be this contract");
    }

    function consumeMessageFromL2(
        uint32 l2BlockNumber,
        uint256 index,
        uint16 l2TxNumberInBlock,
        bytes calldata message,
        bytes32[] calldata proof
    ) external {
        // TODO: For mainnet, this mapping index should be more unique. If zkSync undergoes a regenesis, it is possible that this value will
        // not be unique. Consider hashing all the input values here.
        require(!processedExits[l2BlockNumber][index], "L1_ZKSYNC_WRP: Already processed exit");

        L2Message memory l2Message = L2Message({
            txNumberInBlock: l2TxNumberInBlock,
            sender: l2BridgeAddress,
            data: message
        });

        bool success = zkSyncL1Bridge.proveL2MessageInclusion(l2BlockNumber, index, l2Message, proof);

        if (success) {
            // TODO: For mainnet, consider adding an event
            processedExits[l2BlockNumber][index] = true;
        }
    }

    /**
     * @dev Claim excess funds
     * @param recipient The recipient to send to
     * @param amount The amount to claim
     */
    function claimFunds(address payable recipient, uint256 amount) public {
        // TODO: For mainnet, if this function remains, make it ownable. Solidity version issues prevented it for testnet.
        require(msg.sender == 0xfEfeC7D3EB14a004029D278393e6AB8B46fb4FCa, "L1_ZKSYNC_WPR: Only owner can claim funds");
        recipient.transfer(amount);
    }

    function setL2GasLimit(uint256 _l2GasLimit) public {
        l2GasLimit = _l2GasLimit;
    }

    function setL2GasPerPubdataByteLimit(uint256 _l2GasPerPubdataByteLimit) public {
        l2GasPerPubdataByteLimit = _l2GasPerPubdataByteLimit;
    }
}