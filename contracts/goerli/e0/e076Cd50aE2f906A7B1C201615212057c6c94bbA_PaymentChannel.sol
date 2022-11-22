// SPDX-License-Identifier: GPL-3.0

pragma solidity 0.8.10;

import "./IOperator.sol";
import "./IProxy.sol";

contract PaymentChannel {
    address payable public provider;
    IOperator private operator;
    IProxy private proxy;
    // Resource price per second in wei
    uint256 public resourcePrice;
    struct session {
        uint256 start;
        uint256 end;
    }
    // Time added to the ending channel time to protect provider agains a consumer making a claim to short the channel after it ends up
    uint256 public constant GRACE_PERIOD = 300;

    // Sessions per channel. Channel identifier => map(real address => consumer session)
    mapping(address => mapping(address => session)) public sessions;
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
        // Splits signature.
        (uint8 v, bytes32 r, bytes32 s) = splitSignature(signature);
        // Recreates the hashed message built in the FE
        bytes32 hashedMessage =
            prefixed(
                keccak256(abi.encodePacked(this, amount, channelId))
            );
        // Recovers the ephemeral address that created the signature.
        address ephemeralConsumerAddress = ecrecover(hashedMessage, v, r, s);
        require(
            ephemeralConsumerAddress == ephemeralMapping[channelId],
            "The ephemeral wallet that signed the payment transaction has to match the one that opened the channel"
        );
        require(
            sessions[channelId][consumerAddress].start > 0,
            "Only opened channels can be closed"
        );
        uint256 channelBalance = totalAmount[consumerAddress][channelId];
        uint256 amountChecked = (amount >= channelBalance) ? channelBalance : amount;
        
        uint256 feeAmount = computeFeeAmount(amountChecked, operator.getBaseFee(provider));
        uint256 amountToProvider = amountChecked - feeAmount;
        uint256 remainingAmount = channelBalance - amountChecked;
        // Transfers the amount based on the agreed fee
        if (feeAmount > 0)  _transfer(payable(address(proxy)), feeAmount);
        // Transfers the amount specified in the message to the resource provider.
        if (amountToProvider > 0) _transfer(payable(provider), amountToProvider);
        // Transfers the remaining amount deposited by the consumer in the contract to the consumer.
        if (remainingAmount > 0) _transfer(payable(consumerAddress), remainingAmount);
        // Cancels consumer session and resets amount deposited by the consumer for the channel closed.
        resetSession(channelId, consumerAddress);
        // Emits event to notify BE
        emit ChannelClosed(ephemeralConsumerAddress, channelId);
    }

    function resetSession(address channelId_, address consumerAddress_) internal {
        sessions[channelId_][consumerAddress_].start = 0;
        sessions[channelId_][consumerAddress_].end = 0;
        totalAmount[consumerAddress_][channelId_] = 0;
    }

    function claimTimeout(address channelId) external {
        require(sessions[channelId][msg.sender].end > 0, "Channel not opened");
        require(block.timestamp >= sessions[channelId][msg.sender].end + GRACE_PERIOD, "Ending period not finished yet");
        // Transfers the amount locked in the contract to the consumer
        _transfer(payable(msg.sender), totalAmount[msg.sender][channelId]);
        // Cancels consumer session.
        resetSession(channelId, msg.sender);
    }

    // client can extend the payment. New expiration in epoch time (seconds)
    function extend(address channelId, uint256 newExpiration) external {
        require(sessions[channelId][msg.sender].end > 0, "Channel not opened");
        require(newExpiration > sessions[channelId][msg.sender].end, "Invalid new expiration");
        sessions[channelId][msg.sender].end = newExpiration;
    }

    function splitSignature(bytes memory signature)
        internal
        pure
        returns (
            uint8 v,
            bytes32 r,
            bytes32 s
        )
    {
        require(signature.length == 65);
        assembly {
            r := mload(add(signature, 32))
            s := mload(add(signature, 64))
            v := byte(0, mload(add(signature, 96)))
        }
        return (v, r, s);
    }

    // Builds a prefixed hash to mimic the behavior of eth_sign.
    function prefixed(bytes32 hash) internal pure returns (bytes32) {
        return
            keccak256(
                abi.encodePacked("\x19Ethereum Signed Message:\n32", hash)
            );
    }

    function computeFeeAmount(uint256 amount, uint256 feeBPS)
        public
        pure
        returns (uint256)
    {
        uint256 feeAmount = (amount * feeBPS) / 10000;
        return (feeAmount <= amount) ? feeAmount : amount;
    }

    function _transfer(address payable _to, uint256 amount) internal {
        (bool success, ) = _to.call{value: amount}("");
        require(success, "Unable to send value, recipient may have reverted");
    }
}

// SPDX-License-Identifier: GPL-3.0

pragma solidity 0.8.10;

interface IOperator {
  event UpdateFee(FeeType indexed feeType, uint256 oldValue, uint256 newValue);
  event RegisterProvider(address indexed provider);
  event UnRegisterProvider(address indexed provider);

  enum FeeType {
    MaxFeeBPS,
    BaseFeeBPS,
    ManagementFee
  }

  function setMaxFee(uint256 feeBPS) external;
  function setBaseFee(uint256 baseFeeBPS) external;
  function registerAsProvider() external;
  function unRegisterAsProvider() external;
  function isRegisteredProvider(address addr) external view returns (bool);
  function setSpecialConditionFee(address provider, uint256 specialFee) external;
  function getBaseFee(address provider) external view returns (uint256);
  function getManagementFee() external view returns (uint256);
}

// SPDX-License-Identifier: GPL-3.0

pragma solidity 0.8.10;

interface IProxy {
  event ResourceRegistered(address indexed resource, string indexed resourceId);
  event ResourceModified(
      string indexed resourceId,
      address currentAddress,
      address newAddress
  );
  event ResourceEnabled(string indexed resourceContractAddress);
  event ResourceDisabled(string indexed resourceContractAddress);
  event ResourceDeleted(string indexed resourceId);
  event Withdraw(uint256 amount);
  event UpdateOperator(address indexed newOperatorAddress);

  function getOperator() external view returns (address);
  function isRegisteredProvider(address addr) external view returns (bool);
  function updateOperator(address newOperatorAddress) external;
  function registerResource(string memory resourceId, address contractAddress) external payable;
  function enable(string memory resourceId) external;
  function disable(string memory resourceId) external;
  function modifyResource(string memory resourceId, address newResourceContractAddress) external;
  function deleteResource(string memory resourceId) external;
  function withdraw(uint256 amount) external;
}