// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import 'sgn-v2-contracts/contracts/message/interfaces/IMessageReceiverApp.sol';
import './interfaces/IIFRetrievableStakeWeight.sol';
import './interfaces/IIFBridgableStakeWeight.sol';

contract IFAllocationMasterAdapter is
    IIFRetrievableStakeWeight,
    IIFBridgableStakeWeight
{
    // Celer Multichain Integration
    address public immutable messageBus;

    // Whitelisted Caller
    address public immutable srcAddress;
    uint24 public immutable srcChainId;

    // user checkpoint mapping -- (track, user address, timestamp) => UserStakeWeight
    mapping(uint24 => mapping(address => mapping(uint80 => uint192)))
        public userStakeWeights;

    // user checkpoint mapping -- (track, timestamp) => TotalStakeWeight
    mapping(uint24 => mapping(uint80 => uint192)) public totalStakeWeight;

    // MODIFIERS
    modifier onlyMessageBus() {
        require(msg.sender == messageBus, 'caller is not message bus');
        _;
    }

    // CONSTRUCTOR
    constructor(
        address _messageBus,
        address _srcAddress,
        uint24 _srcChainId
    ) {
        messageBus = _messageBus;
        srcAddress = _srcAddress;
        srcChainId = _srcChainId;
    }

    function getTotalStakeWeight(uint24 trackId, uint80 timestamp)
        external
        view
        returns (uint192)
    {
        return totalStakeWeight[trackId][timestamp];
    }

    function getUserStakeWeight(
        uint24 trackId,
        address user,
        uint80 timestamp
    ) public view returns (uint192) {
        return userStakeWeights[trackId][user][timestamp];
    }

    // Bridge functionalities

    /**
     * execute the bridged message sent by messageBus
     * @notice Called by MessageBus (MessageBusReceiver)
     * @param _sender The address of the source app contract
     * @param _srcChainId The source chain ID where the transfer is originated from
     * @param _message Arbitrary message bytes originated from and encoded by the source app contract
     * @param _executor Address who called the MessageBus execution function
     */
    function executeMessage(
        address _sender,
        uint64 _srcChainId,
        bytes calldata _message,
        address _executor
    ) external onlyMessageBus returns (IMessageReceiverApp.ExecutionStatus) {
        // sender has to be source master address
        require(_sender == srcAddress, 'sender != srcAddress');

        // srcChainId has to be the same as source chain id
        require(_srcChainId == srcChainId, 'srcChainId != _srcChainId');

        // decode the message
        MessageRequest memory message = abi.decode(
            (_message),
            (MessageRequest)
        );

        if (message.bridgeType == BridgeType.UserWeight) {
            for (uint256 i = 0; i < message.users.length; i++) {
                userStakeWeights[message.trackId][message.users[i]][
                    message.timestamp
                ] = message.weights[i];
            }
        } else {
            totalStakeWeight[message.trackId][message.timestamp] = message
                .weights[0];
        }

        return IMessageReceiverApp.ExecutionStatus.Success;
    }
}

// SPDX-License-Identifier: GPL-3.0-only

pragma solidity >=0.8.0;

interface IMessageReceiverApp {
    enum ExecutionStatus {
        Fail, // execution failed, finalized
        Success, // execution succeeded, finalized
        Retry // execution rejected, can retry later
    }

    /**
     * @notice Called by MessageBus (MessageBusReceiver) if the process is originated from MessageBus (MessageBusSender)'s
     *         sendMessageWithTransfer it is only called when the tokens are checked to be arrived at this contract's address.
     * @param _sender The address of the source app contract
     * @param _token The address of the token that comes out of the bridge
     * @param _amount The amount of tokens received at this contract through the cross-chain bridge.
     *        the contract that implements this contract can safely assume that the tokens will arrive before this
     *        function is called.
     * @param _srcChainId The source chain ID where the transfer is originated from
     * @param _message Arbitrary message bytes originated from and encoded by the source app contract
     * @param _executor Address who called the MessageBus execution function
     */
    function executeMessageWithTransfer(
        address _sender,
        address _token,
        uint256 _amount,
        uint64 _srcChainId,
        bytes calldata _message,
        address _executor
    ) external payable returns (ExecutionStatus);

    /**
     * @notice Only called by MessageBus (MessageBusReceiver) if
     *         1. executeMessageWithTransfer reverts, or
     *         2. executeMessageWithTransfer returns ExecutionStatus.Fail
     * @param _sender The address of the source app contract
     * @param _token The address of the token that comes out of the bridge
     * @param _amount The amount of tokens received at this contract through the cross-chain bridge.
     *        the contract that implements this contract can safely assume that the tokens will arrive before this
     *        function is called.
     * @param _srcChainId The source chain ID where the transfer is originated from
     * @param _message Arbitrary message bytes originated from and encoded by the source app contract
     * @param _executor Address who called the MessageBus execution function
     */
    function executeMessageWithTransferFallback(
        address _sender,
        address _token,
        uint256 _amount,
        uint64 _srcChainId,
        bytes calldata _message,
        address _executor
    ) external payable returns (ExecutionStatus);

    /**
     * @notice Called by MessageBus (MessageBusReceiver) to process refund of the original transfer from this contract
     * @param _token The token address of the original transfer
     * @param _amount The amount of the original transfer
     * @param _message The same message associated with the original transfer
     * @param _executor Address who called the MessageBus execution function
     */
    function executeMessageWithTransferRefund(
        address _token,
        uint256 _amount,
        bytes calldata _message,
        address _executor
    ) external payable returns (ExecutionStatus);

    /**
     * @notice Called by MessageBus (MessageBusReceiver)
     * @param _sender The address of the source app contract
     * @param _srcChainId The source chain ID where the transfer is originated from
     * @param _message Arbitrary message bytes originated from and encoded by the source app contract
     * @param _executor Address who called the MessageBus execution function
     */
    function executeMessage(
        address _sender,
        uint64 _srcChainId,
        bytes calldata _message,
        address _executor
    ) external payable returns (ExecutionStatus);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

interface IIFRetrievableStakeWeight {
    function getTotalStakeWeight(uint24 trackId, uint80 timestamp)
        external
        view
        returns (uint192);

    function getUserStakeWeight(
        uint24 trackId,
        address user,
        uint80 timestamp
    ) external view returns (uint192);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

interface IIFBridgableStakeWeight {
    enum BridgeType {
        UserWeight,
        TotalWeight
    }

    struct MessageRequest {
        // user address
        address[] users;
        // timestamp value
        uint80 timestamp;
        // bridge type
        BridgeType bridgeType;
        // track number
        uint24 trackId;
        // amount of weight at timestamp
        uint192[] weights;
    }
}