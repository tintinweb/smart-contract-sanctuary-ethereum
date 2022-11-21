pragma solidity 0.8.14;
pragma experimental ABIEncoderV2;

contract SourceAMB {
    mapping(uint256 => bytes32) public messages;
    uint256 public nonce;

    event SentMessage(uint256 indexed nonce, bytes32 indexed msgHash, bytes message);
    event ShortSentMessage(uint256 indexed nonce, bytes32 indexed msgHash);

    constructor() {
        nonce = 1; // We initialize with 1 to get accurate gas numbers during testing
        // since changing a slot from 0 is different the changing it from any other number.
    } 

    function send(address recipient, uint16 recipientChainId, uint256 gasLimit, bytes calldata data)
        external
        returns (bytes32)
    {
        bytes memory message =
            abi.encode(nonce, msg.sender, recipient, recipientChainId, gasLimit, data);
        bytes32 messageRoot = keccak256(message);
        messages[nonce] = messageRoot;
        emit SentMessage(nonce++, messageRoot, message);
        return messageRoot;
    }
    
    function sendViaLog(address recipient, uint16 recipientChainId, uint256 gasLimit, bytes calldata data)
        external
        returns (bytes32)
    {
        // Heavily gas optimized
        bytes memory message =
            abi.encode(nonce, msg.sender, recipient, recipientChainId, gasLimit, data);
        bytes32 messageRoot = keccak256(message);
        emit SentMessage(nonce++, messageRoot, message);
        return messageRoot;
    }
}

pragma solidity 0.8.14;
pragma experimental ABIEncoderV2;

import "../../src/amb/SourceAMB.sol";

contract Counter {
    // We put together the sending the recieving counters instead of
    // separating them out for ease of use.

    uint256 public nonce;
    SourceAMB sourceAMB;
    mapping(uint16 => address) public otherSideCounterMap;
    address otherSideCounter;
    uint16 chainId;
    address targetAMB;

    event Incremented(
        uint256 indexed nonce, uint16 indexed chainId
    );


    constructor(SourceAMB _sourceAMB, address _counter, address _targetAMB) {
        // Only relevant for controlling counter
        sourceAMB = _sourceAMB;
        // This is only relevant for the recieving counter
        otherSideCounter = _counter;
        targetAMB = _targetAMB;
        nonce = 1;
    }

    // Controlling counter functions

    // Relevant for controlling counter
    function setSourceAMB(SourceAMB _sourceAMB) external {
        sourceAMB = _sourceAMB;
    }

    // Relevant for controlling counter
    function setOtherSideCounterMap(uint16 chainId, address counter) external {
        otherSideCounterMap[chainId] = counter;
    }

    function increment(uint16 chainId) external {
        nonce++;
        require(otherSideCounterMap[chainId] != address(0), "Counter: otherSideCounter not set");
        sourceAMB.send(otherSideCounterMap[chainId], chainId, 100000, abi.encode(nonce));
        emit Incremented(nonce, chainId);
    }

    function incrementViaLog(uint16 chainId) external {
        nonce++;
        require(otherSideCounterMap[chainId] != address(0), "Counter: otherSideCounter not set");
        sourceAMB.sendViaLog(otherSideCounterMap[chainId], chainId, 100000, abi.encode(nonce));
        emit Incremented(nonce, chainId);
    }

    // Recieving counter functions

    // Relevant for recieving counter
    function setTargetAMB(address _targetAMB) external {
        targetAMB = _targetAMB;
    }

    function setOtherSideCounter(address _counter) external {
        otherSideCounter = _counter;
    }

    function receiveSuccinct(address sender, bytes memory data) external {
        require(msg.sender == targetAMB);
        require(sender == otherSideCounter);
        (uint256 _nonce) = abi.decode(data, (uint256));
        nonce = _nonce;
        emit Incremented(nonce, uint16(block.chainid));
    }
}