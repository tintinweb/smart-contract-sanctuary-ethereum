// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.9;

import "./interface/IAMB.sol";

/**
 * @title Counter
 * A simple counter contract that can be incremented by sending a cross-chain message.
 */
contract Counter {
    /**********************
     * Contract Variables *
     **********************/

    address public immutable AMB;
    address public immutable sendingCounter;
    address public immutable receivingCounter;
    uint256 public counter;

    /**********************
     * Contract Events    *
     **********************/
    event SentIncrementMessage(address target, bytes message);
    event Incremented(uint256 counter);

    /**********************
     * Constructor        *
     **********************/

    constructor(
        address _AMB,
        address _sendingCounter,
        address _receivingCounter
    ) {
        AMB = _AMB;
        sendingCounter = _sendingCounter;
        receivingCounter = _receivingCounter;
    }

    /**********************
     * Contract Functions  *
     **********************/

    /**
     * @notice Increments counter and sends cross-chain message to relay.
     */
    function send() public {
        bytes memory message = abi.encodeWithSignature(
            "increment(address)",
            address(this)
        );
        IAMB(AMB).send(receivingCounter, message);

        emit SentIncrementMessage(receivingCounter, message);
    }

    /**
     * @notice Increments counter.
     */
    function increment(address sender) public {
        require(sender == sendingCounter, "ONLY_SENDING_COUNTER");
        counter++;

        emit Incremented(counter);
    }
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.9;

interface IAMB {
    /**********************
     * Contract Events     *
     **********************/
    event MessageEnqueued(bytes encodedMessage);
    event SuccessRelayMessage(bytes32 messageId);
    event FailedRelayMessage(bytes32 messageId);

    /**********************
     * Contract Functions  *
     **********************/

    /**
     * @param _target Target contract address.
     * @param _message Message to be sent.
     */
    function send(address _target, bytes memory _message) external;

    /**
     * @param _target Target contract address.
     * @param _message Message to be sent.
     * @param _sender Sender of the message.
     * @param _nonce Nonce of the message.
     */
    function receiveMessage(
        address _target,
        bytes memory _message,
        address _sender,
        uint256 _nonce
    ) external;
}