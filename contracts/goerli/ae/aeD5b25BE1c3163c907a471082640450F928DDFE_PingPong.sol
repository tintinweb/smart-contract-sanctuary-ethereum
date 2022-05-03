// SPDX-License-Identifier: MIT

pragma solidity 0.8.13;

import "../interfaces/ISynMessagingReceiver.sol";
import "../interfaces/IMessageBus.sol";

contract PingPong is ISynMessagingReceiver {
    // MessageBus is responsible for sending messages to receiving apps and sending messages across chains
    IMessageBus public messageBus;
    // whether to ping and pong back and forth
    bool public pingsEnabled;
    // event emitted everytime it is pinged, counting number of pings
    event Ping(uint256 pings);
    // total pings in a loops
    uint256 public maxPings;
    uint256 public numPings;

    constructor(address _messageBus) {
        pingsEnabled = true;
        messageBus = IMessageBus(_messageBus);
        maxPings = 5;
    }

    function disable() external {
        pingsEnabled = false;
    }

    function ping(uint256 _dstChainId, address _dstPingPongAddr, uint256 pings) public {
        require(address(this).balance > 0, "the balance of this contract needs to be able to pay for native gas");
        require(pingsEnabled, "pingsEnabled is false. messages stopped");
        require(maxPings > pings, "maxPings has been reached, no more looping");

        emit Ping(pings);

        bytes memory message = abi.encode(pings);

        // this will have to be changed soon (WIP, options disabled)
        uint256 fee = messageBus.estimateFee(_dstChainId, bytes(""));
        require(address(this).balance >= fee, "not enough gas for fees");

        messageBus.sendMessage{value: fee}(
            bytes32(uint256(uint160(_dstPingPongAddr))), _dstChainId, message, bytes("")
        );
    }

    /**
     * @notice Called by MessageBus (MessageBusReceiver)
     * @param _srcAddress The bytes32 address of the source app contract
     * @param _srcChainId The source chain ID where the transfer is originated from
     * @param _message Arbitrary message bytes originated from and encoded by the source app contract
     * @param _executor Address who called the MessageBus execution function
     */
    function executeMessage(
        bytes32 _srcAddress,
        uint256 _srcChainId,
        bytes calldata _message,
        address _executor
    ) external returns (ISynMessagingReceiver.MsgExecutionStatus) {
        require(msg.sender == address(messageBus));
        // In production the srcAddress should be a verified sender

        address fromAddress = address(uint160(uint256(_srcAddress)));

        uint256 pings = abi.decode(_message, (uint256));

        // recursively call ping again upon pong
        ++pings;
        numPings = pings;

        ping(_srcChainId, fromAddress, pings);
        // return ISynMessagingReceiver.MsgExecutionStatus.Success;
    }

    // allow this contract to receive ether
    fallback() external payable {}

    receive() external payable {}
}

// SPDX-License-Identifier: MIT

pragma solidity 0.8.13;

interface IMessageBus {
    
    /**
     * @notice Sends a message to a receiving contract address on another chain. 
     * Sender must make sure that the message is unique and not a duplicate message.
     * @param _receiver The bytes32 address of the destination contract to be called
     * @param _dstChainId The destination chain ID - typically, standard EVM chain ID, but differs on nonEVM chains
     * @param _message The arbitrary payload to pass to the destination chain receiver
     * @param _options Versioned struct used to instruct relayer on how to proceed with gas limits
     */
    function sendMessage(
        bytes32 _receiver,
        uint256 _dstChainId,
        bytes calldata _message,
        bytes calldata _options
    ) external payable;

    /**
     * @notice Relayer executes messages through an authenticated method to the destination receiver
     based on the originating transaction on source chain
     * @param _srcChainId Originating chain ID - typically a standard EVM chain ID, but may refer to a Synapse-specific chain ID on nonEVM chains
     * @param _srcAddress Originating bytes address of the message sender on the srcChain
     * @param _dstAddress Destination address that the arbitrary message will be passed to
     * @param _gasLimit Gas limit to be passed alongside the message, depending on the fee paid on srcChain
     * @param _message Arbitrary message payload to pass to the destination chain receiver
     */
    function executeMessage(
        uint256 _srcChainId,
        bytes calldata _srcAddress,
        address _dstAddress,
        uint256 _gasLimit,
        uint256 _nonce,
        bytes calldata _message
    ) external;


    /**
     * @notice Returns srcGasToken fee to charge in wei for the cross-chain message based on the gas limit
     * @param _options Versioned struct used to instruct relayer on how to proceed with gas limits. Contains data on gas limit to submit tx with.
     */
    function estimateFee(uint256 _dstChainId, bytes calldata _options)
        external
        returns (uint256);

    /**
     * @notice Withdraws message fee in the form of native gas token.
     * @param _account The address receiving the fee.
     */
    function withdrawFee(
        address _account
    ) external;



}

// SPDX-License-Identifier: MIT

pragma solidity >=0.8.0;

interface ISynMessagingReceiver {

    // Maps chain ID to the bytes32 trusted addresses allowed to be source senders
    // mapping(uint256 => bytes32) internal trustedRemoteLookup;


    /** 
     * @notice MsgExecutionStatus state
     * @return Success execution succeeded, finalized
     * @return Fail // execution failed, finalized
     * @return Retry // execution failed or rejected, set to be retryable
    */ 
    enum MsgExecutionStatus {
        Success, 
        Fail
    }

     /**
     * @notice Called by MessageBus 
     * @dev MUST be permissioned to trusted source apps via trustedRemote
     * @param _srcAddress The bytes32 address of the source app contract
     * @param _srcChainId The source chain ID where the transfer is originated from
     * @param _message Arbitrary message bytes originated from and encoded by the source app contract
     * @param _executor Address who called the MessageBus execution function
     */
    function executeMessage(
        bytes32 _srcAddress,
        uint256 _srcChainId,
        bytes calldata _message,
        address _executor
    ) external returns (MsgExecutionStatus);
}