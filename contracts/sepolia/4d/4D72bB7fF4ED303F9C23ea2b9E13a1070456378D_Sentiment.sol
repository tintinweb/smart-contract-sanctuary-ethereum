// SPDX-License-Identifier: MIT
pragma solidity ^0.8.7;

import {Functions, FunctionsClient} from "./dev/functions/FunctionsClient.sol";
import {ConfirmedOwner} from "@chainlink/contracts/src/v0.8/ConfirmedOwner.sol";
import {AutomationCompatibleInterface} from "@chainlink/contracts/src/v0.8/AutomationCompatible.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "./Verifier.sol";
import "./MerkleTree.sol";

struct Proof {
    uint256[2] a;
    uint256[2][2] b;
    uint256[2] c;
}

error Sentiment__RandomWordsNotUpdated(string message);
error Sentiment__CommitmentAlreadyUsed(string message);
error Sentiment__InvalidProof(string message);
error Sentiment__NullifierAlreadyUsed(string message);
error Sentiment__RootNotKnown(string message);
error Sentiment__TimeInterval(string message);
error Sentiment__NotSelected(string message);

interface IVerifier {
    function verifyProof(
        uint[2] memory a,
        uint[2][2] memory b,
        uint[2] memory c,
        uint[2] memory input
    ) external returns (bool r);
}

contract Sentiment is
    FunctionsClient,
    ConfirmedOwner,
    AutomationCompatibleInterface,
    MerkleTree,
    ReentrancyGuard
{
    using Functions for Functions.Request;

    // Chainlink automation
    bytes public requestCBOR;
    uint64 public subscriptionId;
    uint32 public fulfillGasLimit;
    uint256 public constant updateInterval = 1 weeks;
    uint256 public lastUpkeepTimeStamp;
    uint256 public upkeepCounter;
    uint256 public responseCounter;

    // Chainlink functions variables
    bytes32 public latestRequestId;
    bytes public latestResponse;
    bytes public latestError;
    event OCRResponse(bytes32 indexed requestId, bytes result, bytes err);

    // Contract Variables
    IVerifier public verifier;
    mapping(bytes32 => bool) public nullifiers;
    mapping(bytes32 => bool) public commitments;
    mapping(string => string[]) public messages;
    mapping(string => bool) public nameExists;
    mapping(address => mapping(string => bool)) public isSelected;
    mapping(string => address[]) public selectedAddressesForName;
    string[] public names;
    event Inserted(bytes32 commitment, uint32 insertedIndex);
    event messagePosted(string message, bytes32 nullifierHash);
    event messagesCleared();

    // bool DONE_GENERATING_REQUESTS = false;
    // while count < names.length: fulfillrequest()
    constructor(
        address oracle,
        IVerifier _verifier,
        uint32 _merkleTreeHeight,
        address _hasher,
        uint64 _subscriptionId,
        uint32 _fulfillGasLimit
    )
        FunctionsClient(oracle)
        ConfirmedOwner(msg.sender)
        MerkleTree(_merkleTreeHeight, _hasher)
    {
        names = new string[](0);
        verifier = _verifier;
        subscriptionId = _subscriptionId;
        fulfillGasLimit = _fulfillGasLimit;
        lastUpkeepTimeStamp = block.timestamp;
    }

    modifier selectedAddress(address walletAddress, string memory name) {
        isSelected[walletAddress][name] = true; // UNCOMMENT FOR TESTING
        if (!isSelected[walletAddress][name])
            revert Sentiment__NotSelected("Address not selected");
        _;
    }

    /**
    @dev Calls insert function on merkle tree and emits Inserted event
  */
    function insertIntoTree(
        bytes32 _commitment,
        string calldata _name
    ) external nonReentrant selectedAddress(msg.sender, _name) {
        if (commitments[_commitment])
            revert Sentiment__CommitmentAlreadyUsed("Commitment already used");

        uint32 insertedIndex = _insert(_commitment);
        commitments[_commitment] = true;
        emit Inserted(_commitment, insertedIndex);
    }

    /**
    @dev Posts a message to the merkle tree, emits messagePosted event,
    and verifies the proof
  */
    function postMessageWithProof(
        string memory name,
        string memory _message,
        bytes32 _nullifierHash,
        bytes32 _root,
        Proof memory _proof
    ) external nonReentrant {
        if (nullifiers[_nullifierHash])
            revert Sentiment__NullifierAlreadyUsed("Nullifier already used");

        if (!isKnownRoot(_root))
            revert Sentiment__RootNotKnown("Root not known");

        uint[2] memory publicInputs = [uint(_root), uint(_nullifierHash)];
        if (!verifier.verifyProof(_proof.a, _proof.b, _proof.c, publicInputs))
            revert Sentiment__InvalidProof("Invalid proof");

        nullifiers[_nullifierHash] = true;
        messages[name].push(_message);
        emit messagePosted(_message, _nullifierHash);
    }

    /**
     * @notice Generates a new Functions.Request. This pure function allows the request CBOR to be generated off-chain, saving gas.
     *
     * @param source JavaScript source code
     * @param secrets Encrypted secrets payload
     * @param args List of arguments accessible from within the source code
     */
    function generateRequest(
        string calldata source,
        bytes calldata secrets,
        string[] calldata args
    ) public pure returns (bytes memory) {
        Functions.Request memory req;
        req.initializeRequest(
            Functions.Location.Inline,
            Functions.CodeLanguage.JavaScript,
            source
        );
        if (secrets.length > 0) {
            req.addRemoteSecrets(secrets);
        }
        if (args.length > 0) req.addArgs(args);

        return req.encodeCBOR();
    }

    /**
     * @notice Used by Automation to check if performUpkeep should be called.
     *
     * Returns a tuple where the first element is a boolean which determines if upkeep is needed and the
     * second element contains custom bytes data which is passed to performUpkeep when it is called by Automation.
     */
    function checkUpkeep(
        bytes memory
    ) public view override returns (bool upkeepNeeded, bytes memory) {
        upkeepNeeded = (block.timestamp - lastUpkeepTimeStamp) > updateInterval;
    }

    /**
     * @notice Called by Automation to trigger a Functions request
     */
    function performUpkeep(bytes calldata) external override {
        (bool upkeepNeeded, ) = checkUpkeep("");
        if (!upkeepNeeded)
            revert Sentiment__TimeInterval("Time interval not met");
        lastUpkeepTimeStamp = block.timestamp;
        upkeepCounter = upkeepCounter + 1;

        bytes32 requestId = s_oracle.sendRequest(
            subscriptionId,
            requestCBOR,
            fulfillGasLimit
        );
        // clearMessages();

        // s_pendingRequests[requestId] = s_oracle.getRegistry();
        // emit RequestSent(requestId);
        // latestRequestId = requestId;
    }

    function fulfillRequest(
        bytes32 requestId,
        bytes memory response,
        bytes memory err
    ) internal override {
        latestResponse = response;
        latestError = err;
        emit OCRResponse(requestId, response, err);
        // for (uint i = 0; i < response.length; i++) {
        //     address wallet = abi.decode(response, (address));
        //     selectedAddresses[wallet] = true;
        //     selectedAddressesArray.push(wallet);
        // }
    }

    /**
    @dev Returns the list of messages
  */
    function getMessages(
        string calldata name
    ) external view returns (string[] memory) {
        return messages[name];
    }

    function getSelectedAddresses(
        string calldata name
    ) external view returns (address[] memory) {
        return selectedAddressesForName[name];
    }

    /**
    @dev Deletes the list of messages and emits messagesCleared event
  */
    function clearMessages() internal {
        uint length = names.length;
        // delete the addresses and messages
        for (uint i = 0; i < length; i++) {
            string memory name = names[i];
            delete selectedAddressesForName[name];
            delete messages[name];
            selectedAddressesForName[name] = new address[](0);
            messages[name] = new string[](0);
        }
        resetTree();
        emit messagesCleared();
    }

    function addName(string memory _name) public {
        names.push(_name);
        nameExists[_name] = true;
    }

    /**
    @dev Checks if a nullifier has been used
  */
    function isNullifierUsed(bytes32 _nullifier) public view returns (bool) {
        return nullifiers[_nullifier];
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract AutomationBase {
  error OnlySimulatedBackend();

  /**
   * @notice method that allows it to be simulated via eth_call by checking that
   * the sender is the zero address.
   */
  function preventExecution() internal view {
    if (tx.origin != address(0)) {
      revert OnlySimulatedBackend();
    }
  }

  /**
   * @notice modifier that allows it to be simulated via eth_call by checking
   * that the sender is the zero address.
   */
  modifier cannotExecute() {
    preventExecution();
    _;
  }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./AutomationBase.sol";
import "./interfaces/AutomationCompatibleInterface.sol";

abstract contract AutomationCompatible is AutomationBase, AutomationCompatibleInterface {}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./ConfirmedOwnerWithProposal.sol";

/**
 * @title The ConfirmedOwner contract
 * @notice A contract with helpers for basic contract ownership.
 */
contract ConfirmedOwner is ConfirmedOwnerWithProposal {
  constructor(address newOwner) ConfirmedOwnerWithProposal(newOwner, address(0)) {}
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./interfaces/OwnableInterface.sol";

/**
 * @title The ConfirmedOwner contract
 * @notice A contract with helpers for basic contract ownership.
 */
contract ConfirmedOwnerWithProposal is OwnableInterface {
  address private s_owner;
  address private s_pendingOwner;

  event OwnershipTransferRequested(address indexed from, address indexed to);
  event OwnershipTransferred(address indexed from, address indexed to);

  constructor(address newOwner, address pendingOwner) {
    require(newOwner != address(0), "Cannot set owner to zero");

    s_owner = newOwner;
    if (pendingOwner != address(0)) {
      _transferOwnership(pendingOwner);
    }
  }

  /**
   * @notice Allows an owner to begin transferring ownership to a new address,
   * pending.
   */
  function transferOwnership(address to) public override onlyOwner {
    _transferOwnership(to);
  }

  /**
   * @notice Allows an ownership transfer to be completed by the recipient.
   */
  function acceptOwnership() external override {
    require(msg.sender == s_pendingOwner, "Must be proposed owner");

    address oldOwner = s_owner;
    s_owner = msg.sender;
    s_pendingOwner = address(0);

    emit OwnershipTransferred(oldOwner, msg.sender);
  }

  /**
   * @notice Get the current owner
   */
  function owner() public view override returns (address) {
    return s_owner;
  }

  /**
   * @notice validate, transfer ownership, and emit relevant events
   */
  function _transferOwnership(address to) private {
    require(to != msg.sender, "Cannot transfer to self");

    s_pendingOwner = to;

    emit OwnershipTransferRequested(s_owner, to);
  }

  /**
   * @notice validate access
   */
  function _validateOwnership() internal view {
    require(msg.sender == s_owner, "Only callable by owner");
  }

  /**
   * @notice Reverts if called by anyone other than the contract owner.
   */
  modifier onlyOwner() {
    _validateOwnership();
    _;
  }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface AutomationCompatibleInterface {
  /**
   * @notice method that is simulated by the keepers to see if any work actually
   * needs to be performed. This method does does not actually need to be
   * executable, and since it is only ever simulated it can consume lots of gas.
   * @dev To ensure that it is never called, you may want to add the
   * cannotExecute modifier from KeeperBase to your implementation of this
   * method.
   * @param checkData specified in the upkeep registration so it is always the
   * same for a registered upkeep. This can easily be broken down into specific
   * arguments using `abi.decode`, so multiple upkeeps can be registered on the
   * same contract and easily differentiated by the contract.
   * @return upkeepNeeded boolean to indicate whether the keeper should call
   * performUpkeep or not.
   * @return performData bytes that the keeper should call performUpkeep with, if
   * upkeep is needed. If you would like to encode data to decode later, try
   * `abi.encode`.
   */
  function checkUpkeep(bytes calldata checkData) external returns (bool upkeepNeeded, bytes memory performData);

  /**
   * @notice method that is actually executed by the keepers, via the registry.
   * The data returned by the checkUpkeep simulation will be passed into
   * this method to actually be executed.
   * @dev The input to this method should not be trusted, and the caller of the
   * method should not even be restricted to any single registry. Anyone should
   * be able call it, and the input should be validated, there is no guarantee
   * that the data passed in is the performData returned from checkUpkeep. This
   * could happen due to malicious keepers, racing keepers, or simply a state
   * change while the performUpkeep transaction is waiting for confirmation.
   * Always validate the data passed in.
   * @param performData is the data which was passed back from the checkData
   * simulation. If it is encoded, it can easily be decoded into other types by
   * calling `abi.decode`. This data should not be trusted, and should be
   * validated against the contract's current state.
   */
  function performUpkeep(bytes calldata performData) external;
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface OwnableInterface {
  function owner() external returns (address);

  function transferOwnership(address recipient) external;

  function acceptOwnership() external;
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

/**
 * @dev A library for working with mutable byte buffers in Solidity.
 *
 * Byte buffers are mutable and expandable, and provide a variety of primitives
 * for writing to them. At any time you can fetch a bytes object containing the
 * current contents of the buffer. The bytes object should not be stored between
 * operations, as it may change due to resizing of the buffer.
 */
library BufferChainlink {
  /**
   * @dev Represents a mutable buffer. Buffers have a current value (buf) and
   *      a capacity. The capacity may be longer than the current value, in
   *      which case it can be extended without the need to allocate more memory.
   */
  struct buffer {
    bytes buf;
    uint256 capacity;
  }

  /**
   * @dev Initializes a buffer with an initial capacity.
   * @param buf The buffer to initialize.
   * @param capacity The number of bytes of space to allocate the buffer.
   * @return The buffer, for chaining.
   */
  function init(buffer memory buf, uint256 capacity) internal pure returns (buffer memory) {
    if (capacity % 32 != 0) {
      capacity += 32 - (capacity % 32);
    }
    // Allocate space for the buffer data
    buf.capacity = capacity;
    assembly {
      let ptr := mload(0x40)
      mstore(buf, ptr)
      mstore(ptr, 0)
      mstore(0x40, add(32, add(ptr, capacity)))
    }
    return buf;
  }

  /**
   * @dev Initializes a new buffer from an existing bytes object.
   *      Changes to the buffer may mutate the original value.
   * @param b The bytes object to initialize the buffer with.
   * @return A new buffer.
   */
  function fromBytes(bytes memory b) internal pure returns (buffer memory) {
    buffer memory buf;
    buf.buf = b;
    buf.capacity = b.length;
    return buf;
  }

  function resize(buffer memory buf, uint256 capacity) private pure {
    bytes memory oldbuf = buf.buf;
    init(buf, capacity);
    append(buf, oldbuf);
  }

  function max(uint256 a, uint256 b) private pure returns (uint256) {
    if (a > b) {
      return a;
    }
    return b;
  }

  /**
   * @dev Sets buffer length to 0.
   * @param buf The buffer to truncate.
   * @return The original buffer, for chaining..
   */
  function truncate(buffer memory buf) internal pure returns (buffer memory) {
    assembly {
      let bufptr := mload(buf)
      mstore(bufptr, 0)
    }
    return buf;
  }

  /**
   * @dev Writes a byte string to a buffer. Resizes if doing so would exceed
   *      the capacity of the buffer.
   * @param buf The buffer to append to.
   * @param off The start offset to write to.
   * @param data The data to append.
   * @param len The number of bytes to copy.
   * @return The original buffer, for chaining.
   */
  function write(
    buffer memory buf,
    uint256 off,
    bytes memory data,
    uint256 len
  ) internal pure returns (buffer memory) {
    require(len <= data.length);

    if (off + len > buf.capacity) {
      resize(buf, max(buf.capacity, len + off) * 2);
    }

    uint256 dest;
    uint256 src;
    assembly {
      // Memory address of the buffer data
      let bufptr := mload(buf)
      // Length of existing buffer data
      let buflen := mload(bufptr)
      // Start address = buffer address + offset + sizeof(buffer length)
      dest := add(add(bufptr, 32), off)
      // Update buffer length if we're extending it
      if gt(add(len, off), buflen) {
        mstore(bufptr, add(len, off))
      }
      src := add(data, 32)
    }

    // Copy word-length chunks while possible
    for (; len >= 32; len -= 32) {
      assembly {
        mstore(dest, mload(src))
      }
      dest += 32;
      src += 32;
    }

    // Copy remaining bytes
    unchecked {
      uint256 mask = (256**(32 - len)) - 1;
      assembly {
        let srcpart := and(mload(src), not(mask))
        let destpart := and(mload(dest), mask)
        mstore(dest, or(destpart, srcpart))
      }
    }

    return buf;
  }

  /**
   * @dev Appends a byte string to a buffer. Resizes if doing so would exceed
   *      the capacity of the buffer.
   * @param buf The buffer to append to.
   * @param data The data to append.
   * @param len The number of bytes to copy.
   * @return The original buffer, for chaining.
   */
  function append(
    buffer memory buf,
    bytes memory data,
    uint256 len
  ) internal pure returns (buffer memory) {
    return write(buf, buf.buf.length, data, len);
  }

  /**
   * @dev Appends a byte string to a buffer. Resizes if doing so would exceed
   *      the capacity of the buffer.
   * @param buf The buffer to append to.
   * @param data The data to append.
   * @return The original buffer, for chaining.
   */
  function append(buffer memory buf, bytes memory data) internal pure returns (buffer memory) {
    return write(buf, buf.buf.length, data, data.length);
  }

  /**
   * @dev Writes a byte to the buffer. Resizes if doing so would exceed the
   *      capacity of the buffer.
   * @param buf The buffer to append to.
   * @param off The offset to write the byte at.
   * @param data The data to append.
   * @return The original buffer, for chaining.
   */
  function writeUint8(
    buffer memory buf,
    uint256 off,
    uint8 data
  ) internal pure returns (buffer memory) {
    if (off >= buf.capacity) {
      resize(buf, buf.capacity * 2);
    }

    assembly {
      // Memory address of the buffer data
      let bufptr := mload(buf)
      // Length of existing buffer data
      let buflen := mload(bufptr)
      // Address = buffer address + sizeof(buffer length) + off
      let dest := add(add(bufptr, off), 32)
      mstore8(dest, data)
      // Update buffer length if we extended it
      if eq(off, buflen) {
        mstore(bufptr, add(buflen, 1))
      }
    }
    return buf;
  }

  /**
   * @dev Appends a byte to the buffer. Resizes if doing so would exceed the
   *      capacity of the buffer.
   * @param buf The buffer to append to.
   * @param data The data to append.
   * @return The original buffer, for chaining.
   */
  function appendUint8(buffer memory buf, uint8 data) internal pure returns (buffer memory) {
    return writeUint8(buf, buf.buf.length, data);
  }

  /**
   * @dev Writes up to 32 bytes to the buffer. Resizes if doing so would
   *      exceed the capacity of the buffer.
   * @param buf The buffer to append to.
   * @param off The offset to write at.
   * @param data The data to append.
   * @param len The number of bytes to write (left-aligned).
   * @return The original buffer, for chaining.
   */
  function write(
    buffer memory buf,
    uint256 off,
    bytes32 data,
    uint256 len
  ) private pure returns (buffer memory) {
    if (len + off > buf.capacity) {
      resize(buf, (len + off) * 2);
    }

    unchecked {
      uint256 mask = (256**len) - 1;
      // Right-align data
      data = data >> (8 * (32 - len));
      assembly {
        // Memory address of the buffer data
        let bufptr := mload(buf)
        // Address = buffer address + sizeof(buffer length) + off + len
        let dest := add(add(bufptr, off), len)
        mstore(dest, or(and(mload(dest), not(mask)), data))
        // Update buffer length if we extended it
        if gt(add(off, len), mload(bufptr)) {
          mstore(bufptr, add(off, len))
        }
      }
    }
    return buf;
  }

  /**
   * @dev Writes a bytes20 to the buffer. Resizes if doing so would exceed the
   *      capacity of the buffer.
   * @param buf The buffer to append to.
   * @param off The offset to write at.
   * @param data The data to append.
   * @return The original buffer, for chaining.
   */
  function writeBytes20(
    buffer memory buf,
    uint256 off,
    bytes20 data
  ) internal pure returns (buffer memory) {
    return write(buf, off, bytes32(data), 20);
  }

  /**
   * @dev Appends a bytes20 to the buffer. Resizes if doing so would exceed
   *      the capacity of the buffer.
   * @param buf The buffer to append to.
   * @param data The data to append.
   * @return The original buffer, for chhaining.
   */
  function appendBytes20(buffer memory buf, bytes20 data) internal pure returns (buffer memory) {
    return write(buf, buf.buf.length, bytes32(data), 20);
  }

  /**
   * @dev Appends a bytes32 to the buffer. Resizes if doing so would exceed
   *      the capacity of the buffer.
   * @param buf The buffer to append to.
   * @param data The data to append.
   * @return The original buffer, for chaining.
   */
  function appendBytes32(buffer memory buf, bytes32 data) internal pure returns (buffer memory) {
    return write(buf, buf.buf.length, data, 32);
  }

  /**
   * @dev Writes an integer to the buffer. Resizes if doing so would exceed
   *      the capacity of the buffer.
   * @param buf The buffer to append to.
   * @param off The offset to write at.
   * @param data The data to append.
   * @param len The number of bytes to write (right-aligned).
   * @return The original buffer, for chaining.
   */
  function writeInt(
    buffer memory buf,
    uint256 off,
    uint256 data,
    uint256 len
  ) private pure returns (buffer memory) {
    if (len + off > buf.capacity) {
      resize(buf, (len + off) * 2);
    }

    uint256 mask = (256**len) - 1;
    assembly {
      // Memory address of the buffer data
      let bufptr := mload(buf)
      // Address = buffer address + off + sizeof(buffer length) + len
      let dest := add(add(bufptr, off), len)
      mstore(dest, or(and(mload(dest), not(mask)), data))
      // Update buffer length if we extended it
      if gt(add(off, len), mload(bufptr)) {
        mstore(bufptr, add(off, len))
      }
    }
    return buf;
  }

  /**
   * @dev Appends a byte to the end of the buffer. Resizes if doing so would
   * exceed the capacity of the buffer.
   * @param buf The buffer to append to.
   * @param data The data to append.
   * @return The original buffer.
   */
  function appendInt(
    buffer memory buf,
    uint256 data,
    uint256 len
  ) internal pure returns (buffer memory) {
    return writeInt(buf, buf.buf.length, data, len);
  }
}

// SPDX-License-Identifier: MIT
pragma solidity >=0.4.19;

import {BufferChainlink} from "./BufferChainlink.sol";

library CBORChainlink {
  using BufferChainlink for BufferChainlink.buffer;

  uint8 private constant MAJOR_TYPE_INT = 0;
  uint8 private constant MAJOR_TYPE_NEGATIVE_INT = 1;
  uint8 private constant MAJOR_TYPE_BYTES = 2;
  uint8 private constant MAJOR_TYPE_STRING = 3;
  uint8 private constant MAJOR_TYPE_ARRAY = 4;
  uint8 private constant MAJOR_TYPE_MAP = 5;
  uint8 private constant MAJOR_TYPE_TAG = 6;
  uint8 private constant MAJOR_TYPE_CONTENT_FREE = 7;

  uint8 private constant TAG_TYPE_BIGNUM = 2;
  uint8 private constant TAG_TYPE_NEGATIVE_BIGNUM = 3;

  function encodeFixedNumeric(BufferChainlink.buffer memory buf, uint8 major, uint64 value) private pure {
    if(value <= 23) {
      buf.appendUint8(uint8((major << 5) | value));
    } else if (value <= 0xFF) {
      buf.appendUint8(uint8((major << 5) | 24));
      buf.appendInt(value, 1);
    } else if (value <= 0xFFFF) {
      buf.appendUint8(uint8((major << 5) | 25));
      buf.appendInt(value, 2);
    } else if (value <= 0xFFFFFFFF) {
      buf.appendUint8(uint8((major << 5) | 26));
      buf.appendInt(value, 4);
    } else {
      buf.appendUint8(uint8((major << 5) | 27));
      buf.appendInt(value, 8);
    }
  }

  function encodeIndefiniteLengthType(BufferChainlink.buffer memory buf, uint8 major) private pure {
    buf.appendUint8(uint8((major << 5) | 31));
  }

  function encodeUInt(BufferChainlink.buffer memory buf, uint value) internal pure {
    if(value > 0xFFFFFFFFFFFFFFFF) {
      encodeBigNum(buf, value);
    } else {
      encodeFixedNumeric(buf, MAJOR_TYPE_INT, uint64(value));
    }
  }

  function encodeInt(BufferChainlink.buffer memory buf, int value) internal pure {
    if(value < -0x10000000000000000) {
      encodeSignedBigNum(buf, value);
    } else if(value > 0xFFFFFFFFFFFFFFFF) {
      encodeBigNum(buf, uint(value));
    } else if(value >= 0) {
      encodeFixedNumeric(buf, MAJOR_TYPE_INT, uint64(uint256(value)));
    } else {
      encodeFixedNumeric(buf, MAJOR_TYPE_NEGATIVE_INT, uint64(uint256(-1 - value)));
    }
  }

  function encodeBytes(BufferChainlink.buffer memory buf, bytes memory value) internal pure {
    encodeFixedNumeric(buf, MAJOR_TYPE_BYTES, uint64(value.length));
    buf.append(value);
  }

  function encodeBigNum(BufferChainlink.buffer memory buf, uint value) internal pure {
    buf.appendUint8(uint8((MAJOR_TYPE_TAG << 5) | TAG_TYPE_BIGNUM));
    encodeBytes(buf, abi.encode(value));
  }

  function encodeSignedBigNum(BufferChainlink.buffer memory buf, int input) internal pure {
    buf.appendUint8(uint8((MAJOR_TYPE_TAG << 5) | TAG_TYPE_NEGATIVE_BIGNUM));
    encodeBytes(buf, abi.encode(uint256(-1 - input)));
  }

  function encodeString(BufferChainlink.buffer memory buf, string memory value) internal pure {
    encodeFixedNumeric(buf, MAJOR_TYPE_STRING, uint64(bytes(value).length));
    buf.append(bytes(value));
  }

  function startArray(BufferChainlink.buffer memory buf) internal pure {
    encodeIndefiniteLengthType(buf, MAJOR_TYPE_ARRAY);
  }

  function startMap(BufferChainlink.buffer memory buf) internal pure {
    encodeIndefiniteLengthType(buf, MAJOR_TYPE_MAP);
  }

  function endSequence(BufferChainlink.buffer memory buf) internal pure {
    encodeIndefiniteLengthType(buf, MAJOR_TYPE_CONTENT_FREE);
  }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.9.0) (security/ReentrancyGuard.sol)

pragma solidity ^0.8.0;

/**
 * @dev Contract module that helps prevent reentrant calls to a function.
 *
 * Inheriting from `ReentrancyGuard` will make the {nonReentrant} modifier
 * available, which can be applied to functions to make sure there are no nested
 * (reentrant) calls to them.
 *
 * Note that because there is a single `nonReentrant` guard, functions marked as
 * `nonReentrant` may not call one another. This can be worked around by making
 * those functions `private`, and then adding `external` `nonReentrant` entry
 * points to them.
 *
 * TIP: If you would like to learn more about reentrancy and alternative ways
 * to protect against it, check out our blog post
 * https://blog.openzeppelin.com/reentrancy-after-istanbul/[Reentrancy After Istanbul].
 */
abstract contract ReentrancyGuard {
    // Booleans are more expensive than uint256 or any type that takes up a full
    // word because each write operation emits an extra SLOAD to first read the
    // slot's contents, replace the bits taken up by the boolean, and then write
    // back. This is the compiler's defense against contract upgrades and
    // pointer aliasing, and it cannot be disabled.

    // The values being non-zero value makes deployment a bit more expensive,
    // but in exchange the refund on every call to nonReentrant will be lower in
    // amount. Since refunds are capped to a percentage of the total
    // transaction's gas, it is best to keep them low in cases like this one, to
    // increase the likelihood of the full refund coming into effect.
    uint256 private constant _NOT_ENTERED = 1;
    uint256 private constant _ENTERED = 2;

    uint256 private _status;

    constructor() {
        _status = _NOT_ENTERED;
    }

    /**
     * @dev Prevents a contract from calling itself, directly or indirectly.
     * Calling a `nonReentrant` function from another `nonReentrant`
     * function is not supported. It is possible to prevent this from happening
     * by making the `nonReentrant` function external, and making it call a
     * `private` function that does the actual work.
     */
    modifier nonReentrant() {
        _nonReentrantBefore();
        _;
        _nonReentrantAfter();
    }

    function _nonReentrantBefore() private {
        // On the first call to nonReentrant, _status will be _NOT_ENTERED
        require(_status != _ENTERED, "ReentrancyGuard: reentrant call");

        // Any calls to nonReentrant after this point will fail
        _status = _ENTERED;
    }

    function _nonReentrantAfter() private {
        // By storing the original value once again, a refund is triggered (see
        // https://eips.ethereum.org/EIPS/eip-2200)
        _status = _NOT_ENTERED;
    }

    /**
     * @dev Returns true if the reentrancy guard is currently set to "entered", which indicates there is a
     * `nonReentrant` function in the call stack.
     */
    function _reentrancyGuardEntered() internal view returns (bool) {
        return _status == _ENTERED;
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.6;

import {CBORChainlink} from "@chainlink/contracts/src/v0.8/vendor/CBORChainlink.sol";
import {BufferChainlink} from "@chainlink/contracts/src/v0.8/vendor/BufferChainlink.sol";

/**
 * @title Library for Chainlink Functions
 */
library Functions {
  uint256 internal constant DEFAULT_BUFFER_SIZE = 256;

  using CBORChainlink for BufferChainlink.buffer;

  enum Location {
    Inline,
    Remote
  }

  enum CodeLanguage {
    JavaScript
    // In future version we may add other languages
  }

  struct Request {
    Location codeLocation;
    Location secretsLocation;
    CodeLanguage language;
    string source; // Source code for Location.Inline or url for Location.Remote
    bytes secrets; // Encrypted secrets blob for Location.Inline or url for Location.Remote
    string[] args;
  }

  error EmptySource();
  error EmptyUrl();
  error EmptySecrets();
  error EmptyArgs();

  /**
   * @notice Encodes a Request to CBOR encoded bytes
   * @param self The request to encode
   * @return CBOR encoded bytes
   */
  function encodeCBOR(Request memory self) internal pure returns (bytes memory) {
    BufferChainlink.buffer memory buf;
    BufferChainlink.init(buf, DEFAULT_BUFFER_SIZE);

    buf.encodeString("codeLocation");
    buf.encodeUInt(uint256(self.codeLocation));

    buf.encodeString("language");
    buf.encodeUInt(uint256(self.language));

    buf.encodeString("source");
    buf.encodeString(self.source);

    if (self.args.length > 0) {
      buf.encodeString("args");
      buf.startArray();
      for (uint256 i = 0; i < self.args.length; i++) {
        buf.encodeString(self.args[i]);
      }
      buf.endSequence();
    }

    if (self.secrets.length > 0) {
      buf.encodeString("secretsLocation");
      buf.encodeUInt(uint256(self.secretsLocation));
      buf.encodeString("secrets");
      buf.encodeBytes(self.secrets);
    }

    return buf.buf;
  }

  /**
   * @notice Initializes a Chainlink Functions Request
   * @dev Sets the codeLocation and code on the request
   * @param self The uninitialized request
   * @param location The user provided source code location
   * @param language The programming language of the user code
   * @param source The user provided source code or a url
   */
  function initializeRequest(
    Request memory self,
    Location location,
    CodeLanguage language,
    string memory source
  ) internal pure {
    if (bytes(source).length == 0) revert EmptySource();

    self.codeLocation = location;
    self.language = language;
    self.source = source;
  }

  /**
   * @notice Initializes a Chainlink Functions Request
   * @dev Simplified version of initializeRequest for PoC
   * @param self The uninitialized request
   * @param javaScriptSource The user provided JS code (must not be empty)
   */
  function initializeRequestForInlineJavaScript(Request memory self, string memory javaScriptSource) internal pure {
    initializeRequest(self, Location.Inline, CodeLanguage.JavaScript, javaScriptSource);
  }

  /**
   * @notice Adds Inline user encrypted secrets to a Request
   * @param self The initialized request
   * @param secrets The user encrypted secrets (must not be empty)
   */
  function addInlineSecrets(Request memory self, bytes memory secrets) internal pure {
    if (secrets.length == 0) revert EmptySecrets();

    self.secretsLocation = Location.Inline;
    self.secrets = secrets;
  }

  /**
   * @notice Adds Remote user encrypted secrets to a Request
   * @param self The initialized request
   * @param encryptedSecretsURLs Encrypted comma-separated string of URLs pointing to off-chain secrets
   */
  function addRemoteSecrets(Request memory self, bytes memory encryptedSecretsURLs) internal pure {
    if (encryptedSecretsURLs.length == 0) revert EmptySecrets();

    self.secretsLocation = Location.Remote;
    self.secrets = encryptedSecretsURLs;
  }

  /**
   * @notice Adds args for the user run function
   * @param self The initialized request
   * @param args The array of args (must not be empty)
   */
  function addArgs(Request memory self, string[] memory args) internal pure {
    if (args.length == 0) revert EmptyArgs();

    self.args = args;
  }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.6;

import "./Functions.sol";
import "../interfaces/FunctionsClientInterface.sol";
import "../interfaces/FunctionsOracleInterface.sol";

/**
 * @title The Chainlink Functions client contract
 * @notice Contract writers can inherit this contract in order to create Chainlink Functions requests
 */
abstract contract FunctionsClient is FunctionsClientInterface {
  FunctionsOracleInterface internal s_oracle;
  mapping(bytes32 => address) internal s_pendingRequests;

  event RequestSent(bytes32 indexed id);
  event RequestFulfilled(bytes32 indexed id);

  error SenderIsNotRegistry();
  error RequestIsAlreadyPending();
  error RequestIsNotPending();

  constructor(address oracle) {
    setOracle(oracle);
  }

  /**
   * @inheritdoc FunctionsClientInterface
   */
  function getDONPublicKey() external view override returns (bytes memory) {
    return s_oracle.getDONPublicKey();
  }

  /**
   * @notice Estimate the total cost that will be charged to a subscription to make a request: gas re-imbursement, plus DON fee, plus Registry fee
   * @param req The initialized Functions.Request
   * @param subscriptionId The subscription ID
   * @param gasLimit gas limit for the fulfillment callback
   * @return billedCost Cost in Juels (1e18) of LINK
   */
  function estimateCost(
    Functions.Request memory req,
    uint64 subscriptionId,
    uint32 gasLimit,
    uint256 gasPrice
  ) public view returns (uint96) {
    return s_oracle.estimateCost(subscriptionId, Functions.encodeCBOR(req), gasLimit, gasPrice);
  }

  /**
   * @notice Sends a Chainlink Functions request to the stored oracle address
   * @param req The initialized Functions.Request
   * @param subscriptionId The subscription ID
   * @param gasLimit gas limit for the fulfillment callback
   * @return requestId The generated request ID
   */
  function sendRequest(
    Functions.Request memory req,
    uint64 subscriptionId,
    uint32 gasLimit
  ) internal returns (bytes32) {
    bytes32 requestId = s_oracle.sendRequest(subscriptionId, Functions.encodeCBOR(req), gasLimit);
    s_pendingRequests[requestId] = s_oracle.getRegistry();
    emit RequestSent(requestId);
    return requestId;
  }

  /**
   * @notice User defined function to handle a response
   * @param requestId The request ID, returned by sendRequest()
   * @param response Aggregated response from the user code
   * @param err Aggregated error from the user code or from the execution pipeline
   * Either response or error parameter will be set, but never both
   */
  function fulfillRequest(
    bytes32 requestId,
    bytes memory response,
    bytes memory err
  ) internal virtual;

  /**
   * @inheritdoc FunctionsClientInterface
   */
  function handleOracleFulfillment(
    bytes32 requestId,
    bytes memory response,
    bytes memory err
  ) external override recordChainlinkFulfillment(requestId) {
    fulfillRequest(requestId, response, err);
  }

  /**
   * @notice Sets the stored Oracle address
   * @param oracle The address of Functions Oracle contract
   */
  function setOracle(address oracle) internal {
    s_oracle = FunctionsOracleInterface(oracle);
  }

  /**
   * @notice Gets the stored address of the oracle contract
   * @return The address of the oracle contract
   */
  function getChainlinkOracleAddress() internal view returns (address) {
    return address(s_oracle);
  }

  /**
   * @notice Allows for a request which was created on another contract to be fulfilled
   * on this contract
   * @param oracleAddress The address of the oracle contract that will fulfill the request
   * @param requestId The request ID used for the response
   */
  function addExternalRequest(address oracleAddress, bytes32 requestId) internal notPendingRequest(requestId) {
    s_pendingRequests[requestId] = oracleAddress;
  }

  /**
   * @dev Reverts if the sender is not the oracle that serviced the request.
   * Emits RequestFulfilled event.
   * @param requestId The request ID for fulfillment
   */
  modifier recordChainlinkFulfillment(bytes32 requestId) {
    if (msg.sender != s_pendingRequests[requestId]) {
      revert SenderIsNotRegistry();
    }
    delete s_pendingRequests[requestId];
    emit RequestFulfilled(requestId);
    _;
  }

  /**
   * @dev Reverts if the request is already pending
   * @param requestId The request ID for fulfillment
   */
  modifier notPendingRequest(bytes32 requestId) {
    if (s_pendingRequests[requestId] != address(0)) {
      revert RequestIsAlreadyPending();
    }
    _;
  }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.6;

/**
 * @title Chainlink Functions billing subscription registry interface.
 */
interface FunctionsBillingRegistryInterface {
  struct RequestBilling {
    // a unique subscription ID allocated by billing system,
    uint64 subscriptionId;
    // the client contract that initiated the request to the DON
    // to use the subscription it must be added as a consumer on the subscription
    address client;
    // customer specified gas limit for the fulfillment callback
    uint32 gasLimit;
    // the expected gas price used to execute the transaction
    uint256 gasPrice;
  }

  /**
   * @notice Get configuration relevant for making requests
   * @return uint32 global max for request gas limit
   * @return address[] list of registered DONs
   */
  function getRequestConfig() external view returns (uint32, address[] memory);

  /**
   * @notice Determine the charged fee that will be paid to the Registry owner
   * @param data Encoded Chainlink Functions request data, use FunctionsClient API to encode a request
   * @param billing The request's billing configuration
   * @return fee Cost in Juels (1e18) of LINK
   */
  function getRequiredFee(bytes calldata data, FunctionsBillingRegistryInterface.RequestBilling memory billing)
    external
    view
    returns (uint96);

  /**
   * @notice Estimate the total cost to make a request: gas re-imbursement, plus DON fee, plus Registry fee
   * @param gasLimit Encoded Chainlink Functions request data, use FunctionsClient API to encode a request
   * @param gasPrice The request's billing configuration
   * @param donFee Fee charged by the DON that is paid to Oracle Node
   * @param registryFee Fee charged by the DON that is paid to Oracle Node
   * @return costEstimate Cost in Juels (1e18) of LINK
   */
  function estimateCost(
    uint32 gasLimit,
    uint256 gasPrice,
    uint96 donFee,
    uint96 registryFee
  ) external view returns (uint96);

  /**
   * @notice Initiate the billing process for an Functions request
   * @param data Encoded Chainlink Functions request data, use FunctionsClient API to encode a request
   * @param billing Billing configuration for the request
   * @return requestId - A unique identifier of the request. Can be used to match a request to a response in fulfillRequest.
   * @dev Only callable by a node that has been approved on the Registry
   */
  function startBilling(bytes calldata data, RequestBilling calldata billing) external returns (bytes32);

  /**
   * @notice Finalize billing process for an Functions request by sending a callback to the Client contract and then charging the subscription
   * @param requestId identifier for the request that was generated by the Registry in the beginBilling commitment
   * @param response response data from DON consensus
   * @param err error from DON consensus
   * @param transmitter the Oracle who sent the report
   * @param signers the Oracles who had a part in generating the report
   * @param signerCount the number of signers on the report
   * @param reportValidationGas the amount of gas used for the report validation. Cost is split by all fulfillments on the report.
   * @param initialGas the initial amount of gas that should be used as a baseline to charge the single fulfillment for execution cost
   * @return success whether the callback was successsful
   * @dev Only callable by a node that has been approved on the Registry
   * @dev simulated offchain to determine if sufficient balance is present to fulfill the request
   */
  function fulfillAndBill(
    bytes32 requestId,
    bytes calldata response,
    bytes calldata err,
    address transmitter,
    address[31] memory signers, // 31 comes from OCR2Abstract.sol's maxNumOracles constant
    uint8 signerCount,
    uint256 reportValidationGas,
    uint256 initialGas
  ) external returns (bool success);

  /**
   * @notice Gets subscription owner.
   * @param subscriptionId - ID of the subscription
   * @return owner - owner of the subscription.
   */
  function getSubscriptionOwner(uint64 subscriptionId) external view returns (address owner);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.6;

/**
 * @title Chainlink Functions client interface.
 */
interface FunctionsClientInterface {
  /**
   * @notice Returns the DON's secp256k1 public key used to encrypt secrets
   * @dev All Oracles nodes have the corresponding private key
   * needed to decrypt the secrets encrypted with the public key
   * @return publicKey DON's public key
   */
  function getDONPublicKey() external view returns (bytes memory);

  /**
   * @notice Chainlink Functions response handler called by the designated transmitter node in an OCR round.
   * @param requestId The requestId returned by FunctionsClient.sendRequest().
   * @param response Aggregated response from the user code.
   * @param err Aggregated error either from the user code or from the execution pipeline.
   * Either response or error parameter will be set, but never both.
   */
  function handleOracleFulfillment(
    bytes32 requestId,
    bytes memory response,
    bytes memory err
  ) external;
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.6;

import "./FunctionsBillingRegistryInterface.sol";

/**
 * @title Chainlink Functions oracle interface.
 */
interface FunctionsOracleInterface {
  /**
   * @notice Gets the stored billing registry address
   * @return registryAddress The address of Chainlink Functions billing registry contract
   */
  function getRegistry() external view returns (address);

  /**
   * @notice Sets the stored billing registry address
   * @param registryAddress The new address of Chainlink Functions billing registry contract
   */
  function setRegistry(address registryAddress) external;

  /**
   * @notice Returns the DON's secp256k1 public key that is used to encrypt secrets
   * @dev All nodes on the DON have the corresponding private key
   * needed to decrypt the secrets encrypted with the public key
   * @return publicKey the DON's public key
   */
  function getDONPublicKey() external view returns (bytes memory);

  /**
   * @notice Sets DON's secp256k1 public key used to encrypt secrets
   * @dev Used to rotate the key
   * @param donPublicKey The new public key
   */
  function setDONPublicKey(bytes calldata donPublicKey) external;

  /**
   * @notice Sets a per-node secp256k1 public key used to encrypt secrets for that node
   * @dev Callable only by contract owner and DON members
   * @param node node's address
   * @param publicKey node's public key
   */
  function setNodePublicKey(address node, bytes calldata publicKey) external;

  /**
   * @notice Deletes node's public key
   * @dev Callable only by contract owner or the node itself
   * @param node node's address
   */
  function deleteNodePublicKey(address node) external;

  /**
   * @notice Return two arrays of equal size containing DON members' addresses and their corresponding
   * public keys (or empty byte arrays if per-node key is not defined)
   */
  function getAllNodePublicKeys() external view returns (address[] memory, bytes[] memory);

  /**
   * @notice Determine the fee charged by the DON that will be split between signing Node Operators for servicing the request
   * @param data Encoded Chainlink Functions request data, use FunctionsClient API to encode a request
   * @param billing The request's billing configuration
   * @return fee Cost in Juels (1e18) of LINK
   */
  function getRequiredFee(bytes calldata data, FunctionsBillingRegistryInterface.RequestBilling calldata billing)
    external
    view
    returns (uint96);

  /**
   * @notice Estimate the total cost that will be charged to a subscription to make a request: gas re-imbursement, plus DON fee, plus Registry fee
   * @param subscriptionId A unique subscription ID allocated by billing system,
   * a client can make requests from different contracts referencing the same subscription
   * @param data Encoded Chainlink Functions request data, use FunctionsClient API to encode a request
   * @param gasLimit Gas limit for the fulfillment callback
   * @return billedCost Cost in Juels (1e18) of LINK
   */
  function estimateCost(
    uint64 subscriptionId,
    bytes calldata data,
    uint32 gasLimit,
    uint256 gasPrice
  ) external view returns (uint96);

  /**
   * @notice Sends a request (encoded as data) using the provided subscriptionId
   * @param subscriptionId A unique subscription ID allocated by billing system,
   * a client can make requests from different contracts referencing the same subscription
   * @param data Encoded Chainlink Functions request data, use FunctionsClient API to encode a request
   * @param gasLimit Gas limit for the fulfillment callback
   * @return requestId A unique request identifier (unique per DON)
   */
  function sendRequest(
    uint64 subscriptionId,
    bytes calldata data,
    uint32 gasLimit
  ) external returns (bytes32);
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.7;

error MerkleTree__TreeLevelsOutOfRange(string message);
error MerkleTree__IsFull(string message);

interface IHasher {
    function poseidon(
        bytes32[2] calldata leftRight
    ) external pure returns (bytes32);
}

contract MerkleTree {
    uint256 public constant FIELD_SIZE =
        21888242871839275222246405745257275088548364400416034343698204186575808495617;
    uint256 public constant ZERO_VALUE =
        21663839004416932945382355908790599225266501822907911457504978515578255421292; // = keccak256("tornado") % FIELD_SIZE

    IHasher public hasher;

    uint32 public immutable levels;

    // the following variables are made public for easier testing and debugging and
    // are not supposed to be accessed in regular code
    bytes32[] public filledSubtrees;
    bytes32[] public zeros;
    uint32 public currentRootIndex = 0;
    uint32 public nextIndex = 0;
    uint32 public constant ROOT_HISTORY_SIZE = 100;
    bytes32[ROOT_HISTORY_SIZE] public roots;

    constructor(uint32 _treeLevels, address _hasher) {
        if (_treeLevels < 0 || _treeLevels > 32)
            revert MerkleTree__TreeLevelsOutOfRange(
                "Tree levels should be between 0 and 32"
            );

        hasher = IHasher(_hasher);
        levels = _treeLevels;

        bytes32 currentZero = bytes32(ZERO_VALUE);
        zeros.push(currentZero);
        filledSubtrees.push(currentZero);

        for (uint32 i = 1; i < _treeLevels; i++) {
            currentZero = hashLeftRight(currentZero, currentZero);
            zeros.push(currentZero);
            filledSubtrees.push(currentZero);
        }

        roots[0] = hashLeftRight(currentZero, currentZero);
    }

    /**
    @dev Hash 2 tree leaves, returns Poseidon(_left, _right)
  */
    function hashLeftRight(
        bytes32 _left,
        bytes32 _right
    ) public view returns (bytes32) {
        require(
            uint256(_left) < FIELD_SIZE,
            "_left should be inside the field"
        );
        require(
            uint256(_right) < FIELD_SIZE,
            "_right should be inside the field"
        );
        bytes32[2] memory leftright = [_left, _right];
        return hasher.poseidon(leftright);
    }

    function _insert(bytes32 _leaf) internal returns (uint32 index) {
        uint32 currentIndex = nextIndex;
        if (currentIndex >= 2 ** levels)
            revert MerkleTree__IsFull(
                "Merkle tree is full. No more leafs can be added"
            );
        nextIndex += 1;
        bytes32 currentLevelHash = _leaf;
        bytes32 left;
        bytes32 right;

        for (uint32 i = 0; i < levels; i++) {
            if (currentIndex % 2 == 0) {
                left = currentLevelHash;
                right = zeros[i];

                filledSubtrees[i] = currentLevelHash;
            } else {
                left = filledSubtrees[i];
                right = currentLevelHash;
            }

            currentLevelHash = hashLeftRight(left, right);

            currentIndex /= 2;
        }

        currentRootIndex = (currentRootIndex + 1) % ROOT_HISTORY_SIZE;
        roots[currentRootIndex] = currentLevelHash;
        return nextIndex - 1;
    }

    /**
    @dev Whether the root is present in the root history
  */
    function isKnownRoot(bytes32 _root) public view returns (bool) {
        if (_root == 0) return false;

        uint32 i = currentRootIndex;
        do {
            if (_root == roots[i]) return true;
            if (i == 0) i = ROOT_HISTORY_SIZE;
            i--;
        } while (i != currentRootIndex);
        return false;
    }

    /**
    @dev Returns the last root
  */
    function getLastRoot() public view returns (bytes32) {
        return roots[currentRootIndex];
    }

    function resetTree() internal {
        delete filledSubtrees;
        delete zeros;
        filledSubtrees = new bytes32[](0);
        zeros = new bytes32[](0);
        nextIndex = 0;
        currentRootIndex = 0;

        bytes32 currentZero = bytes32(ZERO_VALUE);
        zeros.push(currentZero);
        filledSubtrees.push(currentZero);

        for (uint32 i = 1; i < levels; i++) {
            currentZero = hashLeftRight(currentZero, currentZero);
            zeros.push(currentZero);
            filledSubtrees.push(currentZero);
        }

        roots[0] = hashLeftRight(currentZero, currentZero);
    }
}

//
// Copyright 2017 Christian Reitwiessner
// Permission is hereby granted, free of charge, to any person obtaining a copy of this software and associated documentation files (the "Software"), to deal in the Software without restriction, including without limitation the rights to use, copy, modify, merge, publish, distribute, sublicense, and/or sell copies of the Software, and to permit persons to whom the Software is furnished to do so, subject to the following conditions:
// The above copyright notice and this permission notice shall be included in all copies or substantial portions of the Software.
// THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.
//
// 2019 OKIMS
//      ported to solidity 0.6
//      fixed linter warnings
//      added requiere error messages
//
//
// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.7;

library Pairing {
    struct G1Point {
        uint X;
        uint Y;
    }
    // Encoding of field elements is: X[0] * z + X[1]
    struct G2Point {
        uint[2] X;
        uint[2] Y;
    }

    /// @return the generator of G1
    function P1() internal pure returns (G1Point memory) {
        return G1Point(1, 2);
    }

    /// @return the generator of G2
    function P2() internal pure returns (G2Point memory) {
        // Original code point
        return
            G2Point(
                [
                    11559732032986387107991004021392285783925812861821192530917403151452391805634,
                    10857046999023057135944570762232829481370756359578518086990519993285655852781
                ],
                [
                    4082367875863433681332203403145435568316851327593401208105741076214120093531,
                    8495653923123431417604973247489272438418190587263600148770280649306958101930
                ]
            );

        /*
        // Changed by Jordi point
        return G2Point(
            [10857046999023057135944570762232829481370756359578518086990519993285655852781,
             11559732032986387107991004021392285783925812861821192530917403151452391805634],
            [8495653923123431417604973247489272438418190587263600148770280649306958101930,
             4082367875863433681332203403145435568316851327593401208105741076214120093531]
        );
*/
    }

    /// @return r the negation of p, i.e. p.addition(p.negate()) should be zero.
    function negate(G1Point memory p) internal pure returns (G1Point memory r) {
        // The prime q in the base field F_q for G1
        uint q = 21888242871839275222246405745257275088696311157297823662689037894645226208583;
        if (p.X == 0 && p.Y == 0) return G1Point(0, 0);
        return G1Point(p.X, q - (p.Y % q));
    }

    /// @return r the sum of two points of G1
    function addition(
        G1Point memory p1,
        G1Point memory p2
    ) internal view returns (G1Point memory r) {
        uint[4] memory input;
        input[0] = p1.X;
        input[1] = p1.Y;
        input[2] = p2.X;
        input[3] = p2.Y;
        bool success;
        // solium-disable-next-line security/no-inline-assembly
        assembly {
            success := staticcall(sub(gas(), 2000), 6, input, 0xc0, r, 0x60)
            // Use "invalid" to make gas estimation work
            switch success
            case 0 {
                invalid()
            }
        }
        require(success, "pairing-add-failed");
    }

    /// @return r the product of a point on G1 and a scalar, i.e.
    /// p == p.scalar_mul(1) and p.addition(p) == p.scalar_mul(2) for all points p.
    function scalar_mul(
        G1Point memory p,
        uint s
    ) internal view returns (G1Point memory r) {
        uint[3] memory input;
        input[0] = p.X;
        input[1] = p.Y;
        input[2] = s;
        bool success;
        // solium-disable-next-line security/no-inline-assembly
        assembly {
            success := staticcall(sub(gas(), 2000), 7, input, 0x80, r, 0x60)
            // Use "invalid" to make gas estimation work
            switch success
            case 0 {
                invalid()
            }
        }
        require(success, "pairing-mul-failed");
    }

    /// @return the result of computing the pairing check
    /// e(p1[0], p2[0]) *  .... * e(p1[n], p2[n]) == 1
    /// For example pairing([P1(), P1().negate()], [P2(), P2()]) should
    /// return true.
    function pairing(
        G1Point[] memory p1,
        G2Point[] memory p2
    ) internal view returns (bool) {
        require(p1.length == p2.length, "pairing-lengths-failed");
        uint elements = p1.length;
        uint inputSize = elements * 6;
        uint[] memory input = new uint[](inputSize);
        for (uint i = 0; i < elements; i++) {
            input[i * 6 + 0] = p1[i].X;
            input[i * 6 + 1] = p1[i].Y;
            input[i * 6 + 2] = p2[i].X[0];
            input[i * 6 + 3] = p2[i].X[1];
            input[i * 6 + 4] = p2[i].Y[0];
            input[i * 6 + 5] = p2[i].Y[1];
        }
        uint[1] memory out;
        bool success;
        // solium-disable-next-line security/no-inline-assembly
        assembly {
            success := staticcall(
                sub(gas(), 2000),
                8,
                add(input, 0x20),
                mul(inputSize, 0x20),
                out,
                0x20
            )
            // Use "invalid" to make gas estimation work
            switch success
            case 0 {
                invalid()
            }
        }
        require(success, "pairing-opcode-failed");
        return out[0] != 0;
    }

    /// Convenience method for a pairing check for two pairs.
    function pairingProd2(
        G1Point memory a1,
        G2Point memory a2,
        G1Point memory b1,
        G2Point memory b2
    ) internal view returns (bool) {
        G1Point[] memory p1 = new G1Point[](2);
        G2Point[] memory p2 = new G2Point[](2);
        p1[0] = a1;
        p1[1] = b1;
        p2[0] = a2;
        p2[1] = b2;
        return pairing(p1, p2);
    }

    /// Convenience method for a pairing check for three pairs.
    function pairingProd3(
        G1Point memory a1,
        G2Point memory a2,
        G1Point memory b1,
        G2Point memory b2,
        G1Point memory c1,
        G2Point memory c2
    ) internal view returns (bool) {
        G1Point[] memory p1 = new G1Point[](3);
        G2Point[] memory p2 = new G2Point[](3);
        p1[0] = a1;
        p1[1] = b1;
        p1[2] = c1;
        p2[0] = a2;
        p2[1] = b2;
        p2[2] = c2;
        return pairing(p1, p2);
    }

    /// Convenience method for a pairing check for four pairs.
    function pairingProd4(
        G1Point memory a1,
        G2Point memory a2,
        G1Point memory b1,
        G2Point memory b2,
        G1Point memory c1,
        G2Point memory c2,
        G1Point memory d1,
        G2Point memory d2
    ) internal view returns (bool) {
        G1Point[] memory p1 = new G1Point[](4);
        G2Point[] memory p2 = new G2Point[](4);
        p1[0] = a1;
        p1[1] = b1;
        p1[2] = c1;
        p1[3] = d1;
        p2[0] = a2;
        p2[1] = b2;
        p2[2] = c2;
        p2[3] = d2;
        return pairing(p1, p2);
    }
}

contract Verifier {
    using Pairing for *;
    struct VerifyingKey {
        Pairing.G1Point alfa1;
        Pairing.G2Point beta2;
        Pairing.G2Point gamma2;
        Pairing.G2Point delta2;
        Pairing.G1Point[] IC;
    }
    struct Proof {
        Pairing.G1Point A;
        Pairing.G2Point B;
        Pairing.G1Point C;
    }

    function verifyingKey() internal pure returns (VerifyingKey memory vk) {
        vk.alfa1 = Pairing.G1Point(
            4009494404370398297067222494712236721958518394215003075388025256563243139803,
            4818543142271928938976941325993243075778888525297449289641370638713808601212
        );

        vk.beta2 = Pairing.G2Point(
            [
                4537933700841740728568247047639244721437238926210948971725091319937242304458,
                129162666175770374978429072141007181805865468150160549247195018008268905400
            ],
            [
                11873723590604791260554095537305487542055940476310007772390680107346769092189,
                16810872041255688515676140118951968234502993392366586693532652642436275809466
            ]
        );
        vk.gamma2 = Pairing.G2Point(
            [
                11559732032986387107991004021392285783925812861821192530917403151452391805634,
                10857046999023057135944570762232829481370756359578518086990519993285655852781
            ],
            [
                4082367875863433681332203403145435568316851327593401208105741076214120093531,
                8495653923123431417604973247489272438418190587263600148770280649306958101930
            ]
        );
        vk.delta2 = Pairing.G2Point(
            [
                5475690129572049838671236161908810048384867403247075020869684419481059524209,
                7754175668420258959431468876283078037711268403359725210972841522298086600897
            ],
            [
                3685058820905683767260995226876147994568063975533289623950095960586369253751,
                5754728737500863836638540629716001839855926432014896593699408307505200620460
            ]
        );
        vk.IC = new Pairing.G1Point[](3);

        vk.IC[0] = Pairing.G1Point(
            9332902102857888538114204444641841224336652533107963532088404476597448743682,
            1381286411143553492110621000994444803894443680122444312347568560168882133467
        );

        vk.IC[1] = Pairing.G1Point(
            18971023251637705239656334831514442122814085652142520775126326941660676101533,
            15585843325019406472119613740053100330212908971100913312745025072116666099164
        );

        vk.IC[2] = Pairing.G1Point(
            21429824392427840143580565704007638094831275506668024269605431754148248383542,
            10625691344376709308838338965215265449795813892170403848748943942883228925516
        );
    }

    function verify(
        uint[] memory input,
        Proof memory proof
    ) internal view returns (uint) {
        uint256 snark_scalar_field = 21888242871839275222246405745257275088548364400416034343698204186575808495617;
        VerifyingKey memory vk = verifyingKey();
        require(input.length + 1 == vk.IC.length, "verifier-bad-input");
        // Compute the linear combination vk_x
        Pairing.G1Point memory vk_x = Pairing.G1Point(0, 0);
        for (uint i = 0; i < input.length; i++) {
            require(
                input[i] < snark_scalar_field,
                "verifier-gte-snark-scalar-field"
            );
            vk_x = Pairing.addition(
                vk_x,
                Pairing.scalar_mul(vk.IC[i + 1], input[i])
            );
        }
        vk_x = Pairing.addition(vk_x, vk.IC[0]);
        if (
            !Pairing.pairingProd4(
                Pairing.negate(proof.A),
                proof.B,
                vk.alfa1,
                vk.beta2,
                vk_x,
                vk.gamma2,
                proof.C,
                vk.delta2
            )
        ) return 1;
        return 0;
    }

    /// @return r  bool true if proof is valid
    function verifyProof(
        uint[2] memory a,
        uint[2][2] memory b,
        uint[2] memory c,
        uint[2] memory input
    ) public view returns (bool r) {
        Proof memory proof;
        proof.A = Pairing.G1Point(a[0], a[1]);
        proof.B = Pairing.G2Point([b[0][0], b[0][1]], [b[1][0], b[1][1]]);
        proof.C = Pairing.G1Point(c[0], c[1]);
        uint[] memory inputValues = new uint[](input.length);
        for (uint i = 0; i < input.length; i++) {
            inputValues[i] = input[i];
        }
        if (verify(inputValues, proof) == 0) {
            return true;
        } else {
            return false;
        }
    }
}