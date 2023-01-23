// SPDX-License-Identifier: GPL-3.0

pragma solidity 0.8.16;

import "./ECDSA.sol";
import "./IOperator.sol";
import "./IProxy.sol";

contract PaymentChannel {

    using ECDSA for bytes32;

    address payable public provider;
    IOperator private operator;
    IProxy private proxy;
    // Resource price per second in wei
    uint256 public resourcePrice;
    struct Session {
        uint256 start;
        uint256 end;
    }
    // Time added to the ending channel time to protect provider agains a consumer making a claim to short the channel after it ends up
    uint256 public constant GRACE_PERIOD = 300;

    // Sessions per channel. Channel identifier => map(real address => consumer session)
    mapping(address => mapping(address => Session)) public sessions;
    // Relation between ephemeral address and real address from consumer. Real address => ephemeral address
    mapping(address => address) public ephemeralMapping;
    // Wei amount deposited by consumers per channel. Real address => map(channel identifier => amount)
    mapping(address => mapping(address => uint256)) public totalAmount;

    event ChannelOpened(
        address indexed consumer,
        address indexed channelId,
        uint256 indexed expiration,
        address ephemeralConsumerAddress
    );
    event ChannelClosed(address indexed consumer, address indexed channelId);

    constructor(uint256 _resourcePrice, address proxyAddress) payable {
        proxy = IProxy(address(proxyAddress));
        provider = payable(msg.sender);
        resourcePrice = _resourcePrice;
        operator = IOperator(proxy.getOperator());
    }

    // Used by the consumer to pay for resources for a given duration. The payment is provided as value parameter.
    function openChannel(
        address channelId,
        uint256 forDuration, // in days, converted to seconds = forDuration * 24 * 60 * 60
        address ephemeralConsumerAddress) external payable returns (bool) {
        require(
            msg.value >= resourcePrice * forDuration,
            "The consumer has to pay at least for resource price"
        );
        require(
            sessions[channelId][tx.origin].start == 0,
            "The consumer requires not to have an active session for given channel"
        );

        // Sets session start time
        sessions[channelId][tx.origin].start = block.timestamp;
        // Sets session end time
        sessions[channelId][tx.origin].end = block.timestamp + forDuration;
        // Saves relation between ephemeral and real addresses
        ephemeralMapping[channelId] = ephemeralConsumerAddress;
        // Saves amount deposited by the consumer per channel
        totalAmount[tx.origin][channelId] = msg.value;
        // Emits event to notify BE
        emit ChannelOpened(tx.origin,
                           channelId,
                           block.timestamp + forDuration,
                           ephemeralConsumerAddress);
        return true;
    }

    // Used by the BE to close a channel using a signature sent by the consumer.
    function closeChannel(
        address channelId,
        uint256 amount,
        address consumerAddress,
        bytes memory signature
    ) external {
        require(msg.sender == provider, "Only provider can close the channel");
        // Recovers the ephemeral address that created the signature.
        address ephemeralConsumerAddress = _getSignerFromSignature(amount, channelId, signature);
        require(
            ephemeralConsumerAddress == ephemeralMapping[channelId],
            "The ephemeral wallet that signed the payment transaction has to match the one that opened the channel"
        );
        require(
            sessions[channelId][consumerAddress].start > 0,
            "Only opened channels can be closed"
        );
        uint256 channelBalance = totalAmount[consumerAddress][channelId];
        uint256 checkedAmount = (amount >= channelBalance) ? channelBalance : amount;

        uint256 feeAmount = computeFeeAmount(checkedAmount, operator.getBaseFee(provider));
        uint256 amountToProvider = checkedAmount - feeAmount;
        uint256 amountToConsumer = channelBalance - checkedAmount;
        // Cancels consumer session and resets amount deposited by the consumer for the channel closed
        // It is done before transferring ether to avoid a reentrancy attack from a malicious smart contract
        _resetSession(channelId, consumerAddress);
        // Emits event to notify BE
        emit ChannelClosed(ephemeralConsumerAddress, channelId);
        // Transfers the amount based on the agreed fee
        if (feeAmount > 0)  _transfer(payable(address(proxy)), feeAmount);
        // Transfers the amount specified in the message to the resource provider.
        if (amountToProvider > 0) _transfer(payable(provider), amountToProvider);
        // Transfers the remaining amount deposited by the consumer in the contract to the consumer.
        if (amountToConsumer > 0) _transfer(payable(consumerAddress), amountToConsumer);
    }

    function claimTimeout(address channelId) external {
        require(sessions[channelId][msg.sender].end > 0, "Channel not opened");
        require(block.timestamp >= sessions[channelId][msg.sender].end + GRACE_PERIOD, "Ending period not finished yet");
        // Cancels consumer session
        uint256 consumerBalance = totalAmount[msg.sender][channelId];
        _resetSession(channelId, msg.sender);
        // Transfers the amount locked in the contract to the consumer
        _transfer(payable(msg.sender), consumerBalance);
    }

    function computeFeeAmount(uint256 amount, uint256 feeBPS)
        public
        pure
        returns (uint256)
    {
        uint256 feeAmount = (amount * feeBPS) / 10000;
        return (feeAmount <= amount) ? feeAmount : amount;
    }

    function _transfer(address payable _to, uint256 amount) private {
        (bool success, ) = _to.call{value: amount}("");
        require(success, "Unable to send value, recipient may have reverted");
    }

    function _resetSession(address channelId_, address consumerAddress_) private {
        sessions[channelId_][consumerAddress_].start = 0;
        sessions[channelId_][consumerAddress_].end = 0;
        totalAmount[consumerAddress_][channelId_] = 0;
    }

    function _getSignerFromSignature(
        uint256 _amount,
        address _channelId,
        bytes memory signature
    ) private view returns (address) {
        bytes32 ethSignedMessageHash = keccak256(abi.encodePacked(address(this), _amount, _channelId)).toEthSignedMessageHash();
        return ethSignedMessageHash.recover(signature);
    }

}