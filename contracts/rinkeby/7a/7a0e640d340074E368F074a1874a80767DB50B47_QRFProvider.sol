/**
 *Submitted for verification at Etherscan.io on 2022-08-29
*/

// SPDX-License-Identifier: MIT
// File: https://github.com/smartcontractkit/chainlink/blob/v1.2.0/contracts/src/v0.8/interfaces/KeeperCompatibleInterface.sol


pragma solidity ^0.8.0;

interface KeeperCompatibleInterface {
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

// File: https://github.com/smartcontractkit/chainlink/blob/v1.2.0/contracts/src/v0.8/vendor/ENSResolver.sol


pragma solidity ^0.8.0;

abstract contract ENSResolver {
  function addr(bytes32 node) public view virtual returns (address);
}

// File: https://github.com/smartcontractkit/chainlink/blob/v1.2.0/contracts/src/v0.8/interfaces/PointerInterface.sol


pragma solidity ^0.8.0;

interface PointerInterface {
  function getAddress() external view returns (address);
}

// File: https://github.com/smartcontractkit/chainlink/blob/v1.2.0/contracts/src/v0.8/interfaces/OracleInterface.sol


pragma solidity ^0.8.0;

interface OracleInterface {
  function fulfillOracleRequest(
    bytes32 requestId,
    uint256 payment,
    address callbackAddress,
    bytes4 callbackFunctionId,
    uint256 expiration,
    bytes32 data
  ) external returns (bool);

  function isAuthorizedSender(address node) external view returns (bool);

  function withdraw(address recipient, uint256 amount) external;

  function withdrawable() external view returns (uint256);
}

// File: https://github.com/smartcontractkit/chainlink/blob/v1.2.0/contracts/src/v0.8/interfaces/ChainlinkRequestInterface.sol


pragma solidity ^0.8.0;

interface ChainlinkRequestInterface {
  function oracleRequest(
    address sender,
    uint256 requestPrice,
    bytes32 serviceAgreementID,
    address callbackAddress,
    bytes4 callbackFunctionId,
    uint256 nonce,
    uint256 dataVersion,
    bytes calldata data
  ) external;

  function cancelOracleRequest(
    bytes32 requestId,
    uint256 payment,
    bytes4 callbackFunctionId,
    uint256 expiration
  ) external;
}

// File: https://github.com/smartcontractkit/chainlink/blob/v1.2.0/contracts/src/v0.8/interfaces/OperatorInterface.sol


pragma solidity ^0.8.0;



interface OperatorInterface is OracleInterface, ChainlinkRequestInterface {
  function operatorRequest(
    address sender,
    uint256 payment,
    bytes32 specId,
    bytes4 callbackFunctionId,
    uint256 nonce,
    uint256 dataVersion,
    bytes calldata data
  ) external;

  function fulfillOracleRequest2(
    bytes32 requestId,
    uint256 payment,
    address callbackAddress,
    bytes4 callbackFunctionId,
    uint256 expiration,
    bytes calldata data
  ) external returns (bool);

  function ownerTransferAndCall(
    address to,
    uint256 value,
    bytes calldata data
  ) external returns (bool success);

  function distributeFunds(address payable[] calldata receivers, uint256[] calldata amounts) external payable;

  function getAuthorizedSenders() external returns (address[] memory);

  function setAuthorizedSenders(address[] calldata senders) external;

  function getForwarder() external returns (address);
}

// File: https://github.com/smartcontractkit/chainlink/blob/v1.2.0/contracts/src/v0.8/interfaces/LinkTokenInterface.sol


pragma solidity ^0.8.0;

interface LinkTokenInterface {
  function allowance(address owner, address spender) external view returns (uint256 remaining);

  function approve(address spender, uint256 value) external returns (bool success);

  function balanceOf(address owner) external view returns (uint256 balance);

  function decimals() external view returns (uint8 decimalPlaces);

  function decreaseApproval(address spender, uint256 addedValue) external returns (bool success);

  function increaseApproval(address spender, uint256 subtractedValue) external;

  function name() external view returns (string memory tokenName);

  function symbol() external view returns (string memory tokenSymbol);

  function totalSupply() external view returns (uint256 totalTokensIssued);

  function transfer(address to, uint256 value) external returns (bool success);

  function transferAndCall(
    address to,
    uint256 value,
    bytes calldata data
  ) external returns (bool success);

  function transferFrom(
    address from,
    address to,
    uint256 value
  ) external returns (bool success);
}

// File: https://github.com/smartcontractkit/chainlink/blob/v1.2.0/contracts/src/v0.8/interfaces/ENSInterface.sol


pragma solidity ^0.8.0;

interface ENSInterface {
  // Logged when the owner of a node assigns a new owner to a subnode.
  event NewOwner(bytes32 indexed node, bytes32 indexed label, address owner);

  // Logged when the owner of a node transfers ownership to a new account.
  event Transfer(bytes32 indexed node, address owner);

  // Logged when the resolver for a node changes.
  event NewResolver(bytes32 indexed node, address resolver);

  // Logged when the TTL of a node changes
  event NewTTL(bytes32 indexed node, uint64 ttl);

  function setSubnodeOwner(
    bytes32 node,
    bytes32 label,
    address owner
  ) external;

  function setResolver(bytes32 node, address resolver) external;

  function setOwner(bytes32 node, address owner) external;

  function setTTL(bytes32 node, uint64 ttl) external;

  function owner(bytes32 node) external view returns (address);

  function resolver(bytes32 node) external view returns (address);

  function ttl(bytes32 node) external view returns (uint64);
}

// File: https://github.com/smartcontractkit/chainlink/blob/v1.2.0/contracts/src/v0.8/vendor/BufferChainlink.sol


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

// File: https://github.com/smartcontractkit/chainlink/blob/v1.2.0/contracts/src/v0.8/vendor/CBORChainlink.sol


pragma solidity >=0.4.19;


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

// File: https://github.com/smartcontractkit/chainlink/blob/v1.2.0/contracts/src/v0.8/Chainlink.sol


pragma solidity ^0.8.0;



/**
 * @title Library for common Chainlink functions
 * @dev Uses imported CBOR library for encoding to buffer
 */
library Chainlink {
  uint256 internal constant defaultBufferSize = 256; // solhint-disable-line const-name-snakecase

  using CBORChainlink for BufferChainlink.buffer;

  struct Request {
    bytes32 id;
    address callbackAddress;
    bytes4 callbackFunctionId;
    uint256 nonce;
    BufferChainlink.buffer buf;
  }

  /**
   * @notice Initializes a Chainlink request
   * @dev Sets the ID, callback address, and callback function signature on the request
   * @param self The uninitialized request
   * @param jobId The Job Specification ID
   * @param callbackAddr The callback address
   * @param callbackFunc The callback function signature
   * @return The initialized request
   */
  function initialize(
    Request memory self,
    bytes32 jobId,
    address callbackAddr,
    bytes4 callbackFunc
  ) internal pure returns (Chainlink.Request memory) {
    BufferChainlink.init(self.buf, defaultBufferSize);
    self.id = jobId;
    self.callbackAddress = callbackAddr;
    self.callbackFunctionId = callbackFunc;
    return self;
  }

  /**
   * @notice Sets the data for the buffer without encoding CBOR on-chain
   * @dev CBOR can be closed with curly-brackets {} or they can be left off
   * @param self The initialized request
   * @param data The CBOR data
   */
  function setBuffer(Request memory self, bytes memory data) internal pure {
    BufferChainlink.init(self.buf, data.length);
    BufferChainlink.append(self.buf, data);
  }

  /**
   * @notice Adds a string value to the request with a given key name
   * @param self The initialized request
   * @param key The name of the key
   * @param value The string value to add
   */
  function add(
    Request memory self,
    string memory key,
    string memory value
  ) internal pure {
    self.buf.encodeString(key);
    self.buf.encodeString(value);
  }

  /**
   * @notice Adds a bytes value to the request with a given key name
   * @param self The initialized request
   * @param key The name of the key
   * @param value The bytes value to add
   */
  function addBytes(
    Request memory self,
    string memory key,
    bytes memory value
  ) internal pure {
    self.buf.encodeString(key);
    self.buf.encodeBytes(value);
  }

  /**
   * @notice Adds a int256 value to the request with a given key name
   * @param self The initialized request
   * @param key The name of the key
   * @param value The int256 value to add
   */
  function addInt(
    Request memory self,
    string memory key,
    int256 value
  ) internal pure {
    self.buf.encodeString(key);
    self.buf.encodeInt(value);
  }

  /**
   * @notice Adds a uint256 value to the request with a given key name
   * @param self The initialized request
   * @param key The name of the key
   * @param value The uint256 value to add
   */
  function addUint(
    Request memory self,
    string memory key,
    uint256 value
  ) internal pure {
    self.buf.encodeString(key);
    self.buf.encodeUInt(value);
  }

  /**
   * @notice Adds an array of strings to the request with a given key name
   * @param self The initialized request
   * @param key The name of the key
   * @param values The array of string values to add
   */
  function addStringArray(
    Request memory self,
    string memory key,
    string[] memory values
  ) internal pure {
    self.buf.encodeString(key);
    self.buf.startArray();
    for (uint256 i = 0; i < values.length; i++) {
      self.buf.encodeString(values[i]);
    }
    self.buf.endSequence();
  }
}

// File: https://github.com/smartcontractkit/chainlink/blob/v1.2.0/contracts/src/v0.8/ChainlinkClient.sol


pragma solidity ^0.8.0;








/**
 * @title The ChainlinkClient contract
 * @notice Contract writers can inherit this contract in order to create requests for the
 * Chainlink network
 */
abstract contract ChainlinkClient {
  using Chainlink for Chainlink.Request;

  uint256 internal constant LINK_DIVISIBILITY = 10**18;
  uint256 private constant AMOUNT_OVERRIDE = 0;
  address private constant SENDER_OVERRIDE = address(0);
  uint256 private constant ORACLE_ARGS_VERSION = 1;
  uint256 private constant OPERATOR_ARGS_VERSION = 2;
  bytes32 private constant ENS_TOKEN_SUBNAME = keccak256("link");
  bytes32 private constant ENS_ORACLE_SUBNAME = keccak256("oracle");
  address private constant LINK_TOKEN_POINTER = 0xC89bD4E1632D3A43CB03AAAd5262cbe4038Bc571;

  ENSInterface private s_ens;
  bytes32 private s_ensNode;
  LinkTokenInterface private s_link;
  OperatorInterface private s_oracle;
  uint256 private s_requestCount = 1;
  mapping(bytes32 => address) private s_pendingRequests;

  event ChainlinkRequested(bytes32 indexed id);
  event ChainlinkFulfilled(bytes32 indexed id);
  event ChainlinkCancelled(bytes32 indexed id);

  /**
   * @notice Creates a request that can hold additional parameters
   * @param specId The Job Specification ID that the request will be created for
   * @param callbackAddr address to operate the callback on
   * @param callbackFunctionSignature function signature to use for the callback
   * @return A Chainlink Request struct in memory
   */
  function buildChainlinkRequest(
    bytes32 specId,
    address callbackAddr,
    bytes4 callbackFunctionSignature
  ) internal pure returns (Chainlink.Request memory) {
    Chainlink.Request memory req;
    return req.initialize(specId, callbackAddr, callbackFunctionSignature);
  }

  /**
   * @notice Creates a request that can hold additional parameters
   * @param specId The Job Specification ID that the request will be created for
   * @param callbackFunctionSignature function signature to use for the callback
   * @return A Chainlink Request struct in memory
   */
  function buildOperatorRequest(bytes32 specId, bytes4 callbackFunctionSignature)
    internal
    view
    returns (Chainlink.Request memory)
  {
    Chainlink.Request memory req;
    return req.initialize(specId, address(this), callbackFunctionSignature);
  }

  /**
   * @notice Creates a Chainlink request to the stored oracle address
   * @dev Calls `chainlinkRequestTo` with the stored oracle address
   * @param req The initialized Chainlink Request
   * @param payment The amount of LINK to send for the request
   * @return requestId The request ID
   */
  function sendChainlinkRequest(Chainlink.Request memory req, uint256 payment) internal returns (bytes32) {
    return sendChainlinkRequestTo(address(s_oracle), req, payment);
  }

  /**
   * @notice Creates a Chainlink request to the specified oracle address
   * @dev Generates and stores a request ID, increments the local nonce, and uses `transferAndCall` to
   * send LINK which creates a request on the target oracle contract.
   * Emits ChainlinkRequested event.
   * @param oracleAddress The address of the oracle for the request
   * @param req The initialized Chainlink Request
   * @param payment The amount of LINK to send for the request
   * @return requestId The request ID
   */
  function sendChainlinkRequestTo(
    address oracleAddress,
    Chainlink.Request memory req,
    uint256 payment
  ) internal returns (bytes32 requestId) {
    uint256 nonce = s_requestCount;
    s_requestCount = nonce + 1;
    bytes memory encodedRequest = abi.encodeWithSelector(
      ChainlinkRequestInterface.oracleRequest.selector,
      SENDER_OVERRIDE, // Sender value - overridden by onTokenTransfer by the requesting contract's address
      AMOUNT_OVERRIDE, // Amount value - overridden by onTokenTransfer by the actual amount of LINK sent
      req.id,
      address(this),
      req.callbackFunctionId,
      nonce,
      ORACLE_ARGS_VERSION,
      req.buf.buf
    );
    return _rawRequest(oracleAddress, nonce, payment, encodedRequest);
  }

  /**
   * @notice Creates a Chainlink request to the stored oracle address
   * @dev This function supports multi-word response
   * @dev Calls `sendOperatorRequestTo` with the stored oracle address
   * @param req The initialized Chainlink Request
   * @param payment The amount of LINK to send for the request
   * @return requestId The request ID
   */
  function sendOperatorRequest(Chainlink.Request memory req, uint256 payment) internal returns (bytes32) {
    return sendOperatorRequestTo(address(s_oracle), req, payment);
  }

  /**
   * @notice Creates a Chainlink request to the specified oracle address
   * @dev This function supports multi-word response
   * @dev Generates and stores a request ID, increments the local nonce, and uses `transferAndCall` to
   * send LINK which creates a request on the target oracle contract.
   * Emits ChainlinkRequested event.
   * @param oracleAddress The address of the oracle for the request
   * @param req The initialized Chainlink Request
   * @param payment The amount of LINK to send for the request
   * @return requestId The request ID
   */
  function sendOperatorRequestTo(
    address oracleAddress,
    Chainlink.Request memory req,
    uint256 payment
  ) internal returns (bytes32 requestId) {
    uint256 nonce = s_requestCount;
    s_requestCount = nonce + 1;
    bytes memory encodedRequest = abi.encodeWithSelector(
      OperatorInterface.operatorRequest.selector,
      SENDER_OVERRIDE, // Sender value - overridden by onTokenTransfer by the requesting contract's address
      AMOUNT_OVERRIDE, // Amount value - overridden by onTokenTransfer by the actual amount of LINK sent
      req.id,
      req.callbackFunctionId,
      nonce,
      OPERATOR_ARGS_VERSION,
      req.buf.buf
    );
    return _rawRequest(oracleAddress, nonce, payment, encodedRequest);
  }

  /**
   * @notice Make a request to an oracle
   * @param oracleAddress The address of the oracle for the request
   * @param nonce used to generate the request ID
   * @param payment The amount of LINK to send for the request
   * @param encodedRequest data encoded for request type specific format
   * @return requestId The request ID
   */
  function _rawRequest(
    address oracleAddress,
    uint256 nonce,
    uint256 payment,
    bytes memory encodedRequest
  ) private returns (bytes32 requestId) {
    requestId = keccak256(abi.encodePacked(this, nonce));
    s_pendingRequests[requestId] = oracleAddress;
    emit ChainlinkRequested(requestId);
    require(s_link.transferAndCall(oracleAddress, payment, encodedRequest), "unable to transferAndCall to oracle");
  }

  /**
   * @notice Allows a request to be cancelled if it has not been fulfilled
   * @dev Requires keeping track of the expiration value emitted from the oracle contract.
   * Deletes the request from the `pendingRequests` mapping.
   * Emits ChainlinkCancelled event.
   * @param requestId The request ID
   * @param payment The amount of LINK sent for the request
   * @param callbackFunc The callback function specified for the request
   * @param expiration The time of the expiration for the request
   */
  function cancelChainlinkRequest(
    bytes32 requestId,
    uint256 payment,
    bytes4 callbackFunc,
    uint256 expiration
  ) internal {
    OperatorInterface requested = OperatorInterface(s_pendingRequests[requestId]);
    delete s_pendingRequests[requestId];
    emit ChainlinkCancelled(requestId);
    requested.cancelOracleRequest(requestId, payment, callbackFunc, expiration);
  }

  /**
   * @notice the next request count to be used in generating a nonce
   * @dev starts at 1 in order to ensure consistent gas cost
   * @return returns the next request count to be used in a nonce
   */
  function getNextRequestCount() internal view returns (uint256) {
    return s_requestCount;
  }

  /**
   * @notice Sets the stored oracle address
   * @param oracleAddress The address of the oracle contract
   */
  function setChainlinkOracle(address oracleAddress) internal {
    s_oracle = OperatorInterface(oracleAddress);
  }

  /**
   * @notice Sets the LINK token address
   * @param linkAddress The address of the LINK token contract
   */
  function setChainlinkToken(address linkAddress) internal {
    s_link = LinkTokenInterface(linkAddress);
  }

  /**
   * @notice Sets the Chainlink token address for the public
   * network as given by the Pointer contract
   */
  function setPublicChainlinkToken() internal {
    setChainlinkToken(PointerInterface(LINK_TOKEN_POINTER).getAddress());
  }

  /**
   * @notice Retrieves the stored address of the LINK token
   * @return The address of the LINK token
   */
  function chainlinkTokenAddress() internal view returns (address) {
    return address(s_link);
  }

  /**
   * @notice Retrieves the stored address of the oracle contract
   * @return The address of the oracle contract
   */
  function chainlinkOracleAddress() internal view returns (address) {
    return address(s_oracle);
  }

  /**
   * @notice Allows for a request which was created on another contract to be fulfilled
   * on this contract
   * @param oracleAddress The address of the oracle contract that will fulfill the request
   * @param requestId The request ID used for the response
   */
  function addChainlinkExternalRequest(address oracleAddress, bytes32 requestId) internal notPendingRequest(requestId) {
    s_pendingRequests[requestId] = oracleAddress;
  }

  /**
   * @notice Sets the stored oracle and LINK token contracts with the addresses resolved by ENS
   * @dev Accounts for subnodes having different resolvers
   * @param ensAddress The address of the ENS contract
   * @param node The ENS node hash
   */
  function useChainlinkWithENS(address ensAddress, bytes32 node) internal {
    s_ens = ENSInterface(ensAddress);
    s_ensNode = node;
    bytes32 linkSubnode = keccak256(abi.encodePacked(s_ensNode, ENS_TOKEN_SUBNAME));
    ENSResolver resolver = ENSResolver(s_ens.resolver(linkSubnode));
    setChainlinkToken(resolver.addr(linkSubnode));
    updateChainlinkOracleWithENS();
  }

  /**
   * @notice Sets the stored oracle contract with the address resolved by ENS
   * @dev This may be called on its own as long as `useChainlinkWithENS` has been called previously
   */
  function updateChainlinkOracleWithENS() internal {
    bytes32 oracleSubnode = keccak256(abi.encodePacked(s_ensNode, ENS_ORACLE_SUBNAME));
    ENSResolver resolver = ENSResolver(s_ens.resolver(oracleSubnode));
    setChainlinkOracle(resolver.addr(oracleSubnode));
  }

  /**
   * @notice Ensures that the fulfillment is valid for this contract
   * @dev Use if the contract developer prefers methods instead of modifiers for validation
   * @param requestId The request ID for fulfillment
   */
  function validateChainlinkCallback(bytes32 requestId)
    internal
    recordChainlinkFulfillment(requestId)
  // solhint-disable-next-line no-empty-blocks
  {

  }

  /**
   * @dev Reverts if the sender is not the oracle of the request.
   * Emits ChainlinkFulfilled event.
   * @param requestId The request ID for fulfillment
   */
  modifier recordChainlinkFulfillment(bytes32 requestId) {
    require(msg.sender == s_pendingRequests[requestId], "Source must be the oracle of the request");
    delete s_pendingRequests[requestId];
    emit ChainlinkFulfilled(requestId);
    _;
  }

  /**
   * @dev Reverts if the request is already pending
   * @param requestId The request ID for fulfillment
   */
  modifier notPendingRequest(bytes32 requestId) {
    require(s_pendingRequests[requestId] == address(0), "Request is already pending");
    _;
  }
}

// File: https://github.com/OpenZeppelin/openzeppelin-contracts/blob/v4.5.0/contracts/utils/Strings.sol


// OpenZeppelin Contracts v4.4.1 (utils/Strings.sol)

pragma solidity ^0.8.0;

/**
 * @dev String operations.
 */
library Strings {
    bytes16 private constant _HEX_SYMBOLS = "0123456789abcdef";

    /**
     * @dev Converts a `uint256` to its ASCII `string` decimal representation.
     */
    function toString(uint256 value) internal pure returns (string memory) {
        // Inspired by OraclizeAPI's implementation - MIT licence
        // https://github.com/oraclize/ethereum-api/blob/b42146b063c7d6ee1358846c198246239e9360e8/oraclizeAPI_0.4.25.sol

        if (value == 0) {
            return "0";
        }
        uint256 temp = value;
        uint256 digits;
        while (temp != 0) {
            digits++;
            temp /= 10;
        }
        bytes memory buffer = new bytes(digits);
        while (value != 0) {
            digits -= 1;
            buffer[digits] = bytes1(uint8(48 + uint256(value % 10)));
            value /= 10;
        }
        return string(buffer);
    }

    /**
     * @dev Converts a `uint256` to its ASCII `string` hexadecimal representation.
     */
    function toHexString(uint256 value) internal pure returns (string memory) {
        if (value == 0) {
            return "0x00";
        }
        uint256 temp = value;
        uint256 length = 0;
        while (temp != 0) {
            length++;
            temp >>= 8;
        }
        return toHexString(value, length);
    }

    /**
     * @dev Converts a `uint256` to its ASCII `string` hexadecimal representation with fixed length.
     */
    function toHexString(uint256 value, uint256 length) internal pure returns (string memory) {
        bytes memory buffer = new bytes(2 * length + 2);
        buffer[0] = "0";
        buffer[1] = "x";
        for (uint256 i = 2 * length + 1; i > 1; --i) {
            buffer[i] = _HEX_SYMBOLS[value & 0xf];
            value >>= 4;
        }
        require(value == 0, "Strings: hex length insufficient");
        return string(buffer);
    }
}

// File: https://github.com/OpenZeppelin/openzeppelin-contracts/blob/v4.5.0/contracts/utils/Context.sol


// OpenZeppelin Contracts v4.4.1 (utils/Context.sol)

pragma solidity ^0.8.0;

/**
 * @dev Provides information about the current execution context, including the
 * sender of the transaction and its data. While these are generally available
 * via msg.sender and msg.data, they should not be accessed in such a direct
 * manner, since when dealing with meta-transactions the account sending and
 * paying for execution may not be the actual sender (as far as an application
 * is concerned).
 *
 * This contract is only required for intermediate, library-like contracts.
 */
abstract contract Context {
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes calldata) {
        return msg.data;
    }
}

// File: https://github.com/OpenZeppelin/openzeppelin-contracts/blob/v4.5.0/contracts/access/Ownable.sol


// OpenZeppelin Contracts v4.4.1 (access/Ownable.sol)

pragma solidity ^0.8.0;


/**
 * @dev Contract module which provides a basic access control mechanism, where
 * there is an account (an owner) that can be granted exclusive access to
 * specific functions.
 *
 * By default, the owner account will be the one that deploys the contract. This
 * can later be changed with {transferOwnership}.
 *
 * This module is used through inheritance. It will make available the modifier
 * `onlyOwner`, which can be applied to your functions to restrict their use to
 * the owner.
 */
abstract contract Ownable is Context {
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    /**
     * @dev Initializes the contract setting the deployer as the initial owner.
     */
    constructor() {
        _transferOwnership(_msgSender());
    }

    /**
     * @dev Returns the address of the current owner.
     */
    function owner() public view virtual returns (address) {
        return _owner;
    }

    /**
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        require(owner() == _msgSender(), "Ownable: caller is not the owner");
        _;
    }

    /**
     * @dev Leaves the contract without owner. It will not be possible to call
     * `onlyOwner` functions anymore. Can only be called by the current owner.
     *
     * NOTE: Renouncing ownership will leave the contract without an owner,
     * thereby removing any functionality that is only available to the owner.
     */
    function renounceOwnership() public virtual onlyOwner {
        _transferOwnership(address(0));
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        _transferOwnership(newOwner);
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Internal function without access restriction.
     */
    function _transferOwnership(address newOwner) internal virtual {
        address oldOwner = _owner;
        _owner = newOwner;
        emit OwnershipTransferred(oldOwner, newOwner);
    }
}

// File: https://github.com/OpenZeppelin/openzeppelin-contracts/blob/v4.5.0/contracts/token/ERC20/IERC20.sol


// OpenZeppelin Contracts (last updated v4.5.0) (token/ERC20/IERC20.sol)

pragma solidity ^0.8.0;

/**
 * @dev Interface of the ERC20 standard as defined in the EIP.
 */
interface IERC20 {
    /**
     * @dev Returns the amount of tokens in existence.
     */
    function totalSupply() external view returns (uint256);

    /**
     * @dev Returns the amount of tokens owned by `account`.
     */
    function balanceOf(address account) external view returns (uint256);

    /**
     * @dev Moves `amount` tokens from the caller's account to `to`.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transfer(address to, uint256 amount) external returns (bool);

    /**
     * @dev Returns the remaining number of tokens that `spender` will be
     * allowed to spend on behalf of `owner` through {transferFrom}. This is
     * zero by default.
     *
     * This value changes when {approve} or {transferFrom} are called.
     */
    function allowance(address owner, address spender) external view returns (uint256);

    /**
     * @dev Sets `amount` as the allowance of `spender` over the caller's tokens.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * IMPORTANT: Beware that changing an allowance with this method brings the risk
     * that someone may use both the old and the new allowance by unfortunate
     * transaction ordering. One possible solution to mitigate this race
     * condition is to first reduce the spender's allowance to 0 and set the
     * desired value afterwards:
     * https://github.com/ethereum/EIPs/issues/20#issuecomment-263524729
     *
     * Emits an {Approval} event.
     */
    function approve(address spender, uint256 amount) external returns (bool);

    /**
     * @dev Moves `amount` tokens from `from` to `to` using the
     * allowance mechanism. `amount` is then deducted from the caller's
     * allowance.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transferFrom(
        address from,
        address to,
        uint256 amount
    ) external returns (bool);

    /**
     * @dev Emitted when `value` tokens are moved from one account (`from`) to
     * another (`to`).
     *
     * Note that `value` may be zero.
     */
    event Transfer(address indexed from, address indexed to, uint256 value);

    /**
     * @dev Emitted when the allowance of a `spender` for an `owner` is set by
     * a call to {approve}. `value` is the new allowance.
     */
    event Approval(address indexed owner, address indexed spender, uint256 value);
}

// File: quantum-random/QRFProvider.sol


pragma solidity ^0.8.0;

/*   
 *                                                                                   
 *   
 *                                                                                   
 *         #,                                                                        
 *           #&&&&&&%/                                                               
 *     ,&       &&&&&&&&&&&&&&#                                                      
 *      %&&(      #&&&&&&&&&&&&&&&&&&&&#,                                            
 *       &&&&&       &&&&&&&&&&&&&&&&&&&&&&&&&&&%/                                   
 *        &&&&&&(      #&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&(.                         
 *        %&&&&&&&&       %&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&#,                
 *         &&&&&&&&&&/       *&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&*       
 *         ,&&&&&&&&&&&/         ,%&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&%/        
 *          %&&&&&&&&&&&&              ,&&&&&&&&&&&&&&&&&&&&&&&&&&%,                 
 *           &&&&&&&&&&&&&&     @.                                          #&&&&    
 *            &&&&&&&&&&&&&&     @@@@@@#                          ,#&&&&&&&&&&(      
 *            %&&&&&&&&&&&&&&     @@@@@@@@@@@@@@@&         /&&&&&&&&&&&&&&&&         
 *             &&&&&&&&&&&&&&&     @@@@@@@@@@@*       ,&&&&&&&&&&&&&&&&&&(           
 *             ,&&&&&&&&&&&&&&&    [email protected]@@@@@@#       %&&&&&&&&&&&&&&&&&&&              
 *              %&&&&&&&&&&&&&&,    @@@@@       &&&&&&&&&&&&&&&&&&&&(                
 *               &&&&&&&&&&&&&&%    ,@@      (&&&&&&&&&&&&&&&&&&&&                   
 *                &&&&&&&&&&&&&&     .     %&&&&&&&&&&&&&&&&&&&(                     
 *                #&&&&&&&&&&&&&         #&&&&&&&&&&&&&&&&&&&                        
 *                 &&&&&&&&&&&&&        &&&&&&&&&&&&&&&&&&(                          
 *                 .&&&&&&&&&&&&      (&&&&&&&&&&&&&&&&&                             
 *                  %&&&&&&&&&&#     %&&&&&&&&&&&&&&&#                               
 *                   &&&&&&&&&&     #&&&&&&&&&&&&&&                                  
 *                    &&&&&&&&(    *&&&&&&&&&&&&#                                    
 *                    #&&&&&&&     &&&&&&&&&&&                                       
 *                     &&&&&&     %&&&&&&&&#                                         
 *                     .&&&&(    ,&&&&&&&                                            
 *                      #&&&     &&&&&#                                              
 *                       &&.    %&&&                                                 
 *                        #    *&%                                                   
 *                              .
 *   
 */






/**
 *
 * This contract address
 *   - Mumbai:  0x6db09363B6e30D59Dc90aE57A4A56519fD3569d2
 *
 */

/**
 * Request testnet LINK and ETH here: https://faucets.chain.link/
 * Find information on LINK Token Contracts and get the latest ETH and LINK faucets here: https://docs.chain.link/docs/link-token-contracts/
 */

contract QRFProvider is ChainlinkClient, Ownable, KeeperCompatibleInterface{
    using Chainlink for Chainlink.Request;
    
    LinkTokenInterface private _linkTokenInterface;

    uint public _QRFFee;


    /**
    * Use an interval in seconds and a timestamp to slow execution of Upkeep
    */
    uint public _keeper_interval;   // in seconds  -> initialized in constructor
    uint public _keeper_lastTimeStamp;


    //    RINKEBY:
    address public constant LINK_TOKEN_ADDRESS = 0x01BE23585060835E02B77ef475b0Cc51aA1e0709;
    address public _oracle = 0xa2c9C4a1429C6FbFb942770f9ef384d846E8492F;
    bytes32 public _jobId_RunJob = "ef586a00fca4403893aabe9d2ace8ef9";   // "Run Job QRNG (Get > String)"
    bytes32 public _jobId_GetJob = "536e98b5912c441a9eca01e9d1b6a3aa";   // "Get Job QRNG (Get > String,String,Uint256)"
    //uint256 private _oracleFee = 10 ** 16; // 0.01 LINK
    uint256 private _oracleFee = 0.1 * 10 ** 18; // 0.1 LINK
    
    uint public _gasLimit = 50000000;


    /**
     * @dev Mapping to store all the Oracle requests
     */
    struct OracleRequest {
        bytes32 requestId;
        string reqType;
        address callerAddress;
        string executeJob_callerCallback;
        string jobResult_callerCallback;
        uint lengthBits;
        uint requestTimestamp;   // in seconds
        uint responseTimestamp;  // in seconds
        uint processingTime;     // in seconds
        string jobId;
        address fulfillCaller;
        }

    /**
     * @dev Mapping to store all the QCentroid Platform Jobs
     */
    struct QJob {
        string jobId;
        bytes32 initialRequestId;
        address callerAddress;
        uint lengthBits;
        uint requestTimestamp;   // in seconds
        uint responseTimestamp;  // in seconds
        uint processingTime;     // in seconds
        string status;
        uint256 qrandom;
        }

    mapping(bytes32 => OracleRequest) public _oRequests;
    mapping(uint => bytes32) public _oRequestIds;

    mapping(bytes32 => QJob) public _qJobs;
    mapping(uint => bytes32) public _qJobsIds;

    bytes32[] public _qJobs_pending;

    uint public _oReqsIdx;
    uint public _qJobsIdx;

    uint256 public _qrandomLast;

    /**
     *
     *  Info:   https://docs.chain.link/docs/decentralized-oracles-ethereum-mainnet/
     *
     *
     * Network: Kovan
     * Oracle: 0xc57B33452b4F7BB189bB5AfaE9cc4aBa1f7a4FD8 (Chainlink Devrel Node)
     * Job ID:  HttpGet JsonParse EthBytes32	        7401f318127148a894c00c292e486ff
     * Job ID:  HttpGet JsonParse Multiply(optional) EthUint256   d5270d1c311941d0b08bead21fea7747
     * Job ID:  HttpGet JsonParse Multiply(optional) EthInt256	83ba9ddc927946198fbd0bf1bd8a8c25
     * Kovan LINK address: 0xa36085F69e2889c224210F603D836748e7dC0088
     * Fee: 0.1 LINK
     */


    /**
     *
     *   Market:   https://market.link/jobs/4002bb77-a1c0-4dcc-8480-9130fa7bb26f
     *
     *
     * Network: Polygon Mumbai Testnet
     *
     *       Oracle: 0x0bDDCD124709aCBf9BB3F824EbC61C87019888bb
     *       Job ID: Get>Uint256     2bb15c3f9cfc4336b95012872ff05092   (Mumbai Testnet - Matrixed.link)  
     *
     *       Oracle: 0xc8D925525CA8759812d0c299B90247917d4d4b7C
     *       Job ID: Get>Uint256     bbf0badad29d49dc887504bacfbb905b   (LinkRiver)  --> Funciona con la url en HTTP (no HTTPS)
     * 
     * LINK address: 0x326C977E6efc84E512bB9C30f76E30c160eD06FB
     * oracleFee: 0.01 LINK
     */
     
    constructor() {
        setChainlinkToken(LINK_TOKEN_ADDRESS);

        _linkTokenInterface = LinkTokenInterface(LINK_TOKEN_ADDRESS);

        //_QRFFee = 1 * 10 ** 18;  // 1 MATIC
        _QRFFee = 0.0001 * 10 ** 18;  // 0.0001 ETH = 0,16 EUR

        _oReqsIdx = 0;
        _qJobsIdx = 0;

        // ChainLink Keepers
        _keeper_interval = 30;   //  in seconds
        _keeper_lastTimeStamp = block.timestamp;
    }

    function setInteval(uint newInterval) public onlyOwner {
        _keeper_interval = newInterval;
    }

    function setGasLimit(uint gasLimit) public onlyOwner {

        _gasLimit = gasLimit;
    }


    function setOracle(address oracle, string memory jobIdRunJob, string memory jobIdGetJob, uint fee) public onlyOwner {

        _oracle = oracle;
        _jobId_RunJob = bytes32(bytes(jobIdRunJob));
        _jobId_GetJob = bytes32(bytes(jobIdGetJob));
        _oracleFee = fee;

    }
    

    function setQRFee(uint fee) public onlyOwner {

       _QRFFee = fee;
    }

    function getRequestfromIdx(uint idx) public view returns(OracleRequest memory){
        bytes32 reqId = _oRequestIds[idx];

        return _oRequests[reqId];
    }

    /**
     * Create a Chainlink request to retrieve API response, find the target
     * data, then multiply by 1000000000000000000 (to remove decimal places from data).
     *
     * lengthBits:  Length in bits of the desired random number (in multiples of 32):     min: 32 bits     max: 256 bits
     *
     * callback:    The name of your callback function  (ie "foo"). The function must be like:  public foo(uint256)
     */
    function executeQRNGJob(uint lengthBits, string memory executeJob_callback_name, string memory jobResult_callback_name) public payable returns (bytes32 requestId) 
    {
        require(msg.value >= _QRFFee, "Not enough wei provided.");

        Chainlink.Request memory request = buildChainlinkRequest(_jobId_RunJob, address(this), this.fulfill_executeQRNGJob.selector);

        uint samples = lengthBits/32;

        if( samples > 8 ) samples = 8;
        if( samples < 1 ) samples = 1;
        

        request.addUint("samples", samples);
        request.addUint("lengthBits", lengthBits);

        //request.addInt("times", (10**18));   // Multiply -> Not used in this case

        // Sends the request
        requestId = sendChainlinkRequestTo(_oracle, request, _oracleFee);

        // Fill the mapping
        _oRequests[requestId].requestId = requestId;
        _oRequests[requestId].reqType = "EXEC_JOB";
        _oRequests[requestId].requestTimestamp = block.timestamp;
        _oRequests[requestId].callerAddress = msg.sender;  // The end user (consumer)
        _oRequests[requestId].executeJob_callerCallback = executeJob_callback_name;
        _oRequests[requestId].jobResult_callerCallback = jobResult_callback_name;
        _oRequests[requestId].lengthBits = lengthBits;
    
        _oRequestIds[_oReqsIdx] = requestId;
        _oReqsIdx++;

        return requestId;
    }
    
    //
    // This method to get the response is not "payable". The user only pays for the first request to run the job at the QCentroid Platform.
    // ChainLink Keeper will be calling this method
    //
    function getQRNGJobResponse(string memory jobId) public returns (bytes32 requestId)
    {
        // First, check if it was already responded:
        if( keccak256(abi.encodePacked(_qJobs[bytes32(bytes(jobId))].status)) == keccak256(abi.encodePacked("SUCCESS")) )
        {
            // Do nothing => Do not perform a request to the Oracle
            return 0;
        }
        else if( keccak256(abi.encodePacked(_qJobs[bytes32(bytes(jobId))].status)) == keccak256(abi.encodePacked("ERROR")) )
        {
            // Do nothing => Do not perform a request to the Oracle
            return 0;
        }

        // Else, the status is "PENDING", so let's check if it has finished now

        Chainlink.Request memory request = buildChainlinkRequest(_jobId_GetJob, address(this), this.fulfill_getQRNGJobResponse.selector);
        
        request.add("q_job_id", jobId);

        // Sends the request
        requestId = sendChainlinkRequestTo(_oracle, request, _oracleFee);

        // Fill the mapping with the new request
        _oRequests[requestId].requestId = requestId;
        _oRequests[requestId].reqType = "GET_JOB_STATUS";
        _oRequests[requestId].jobId = jobId;
        _oRequests[requestId].requestTimestamp = block.timestamp;
        _oRequests[requestId].callerAddress = msg.sender;  // presumably, the ChainLink keeper
    
        _oRequestIds[_oReqsIdx] = requestId;
        _oReqsIdx++;

        return requestId;
    }

    /**
     * Receive the response in the form of a string
     */ 
    function fulfill_executeQRNGJob(bytes32 _requestId, string memory jobId) public recordChainlinkFulfillment(_requestId)
    {
        bool success;
        bytes memory data;
        bytes32 jobId_idx = bytes32(bytes(jobId));

        _oRequests[_requestId].jobId = jobId;
        _oRequests[_requestId].fulfillCaller = msg.sender;
        _oRequests[_requestId].responseTimestamp = block.timestamp;
        _oRequests[_requestId].processingTime = _oRequests[_requestId].responseTimestamp - _oRequests[_requestId].requestTimestamp;

        // Store the new Job created with this request
        _qJobs[jobId_idx].jobId = jobId;
        _qJobs[jobId_idx].initialRequestId = _requestId;
        _qJobs[jobId_idx].callerAddress = _oRequests[_requestId].callerAddress;
        _qJobs[jobId_idx].lengthBits = _oRequests[_requestId].lengthBits;
        _qJobs[jobId_idx].requestTimestamp = block.timestamp;   // in seconds
        _qJobs[jobId_idx].status = "PENDING";

        _qJobsIds[_qJobsIdx] = jobId_idx;
        _qJobsIdx++;

        // Add the job to the list of pending jobs
        pending_job_add(jobId_idx);

        // Call the caller callback
        if( !isEmptyString(_oRequests[_requestId].executeJob_callerCallback) )
            (success, data) = callContractMethod_String(_oRequests[_requestId].callerAddress, _oRequests[_requestId].executeJob_callerCallback, jobId, _gasLimit);
    }


    /**
     * Receive the response in the form of a string
     */ 
    function fulfill_getQRNGJobResponse(bytes32 _requestId, string memory jobId, string memory status, uint256 result) public recordChainlinkFulfillment(_requestId)
    {
        bool success;
        bytes memory data;
        bytes32 initialRequestId;
        // Get the Job ID fromhe request object
        bytes32 jobId_idx = bytes32(bytes(jobId));
            
        
        // Fill the oracle request information
        _oRequests[_requestId].fulfillCaller = msg.sender;
        _oRequests[_requestId].responseTimestamp = block.timestamp;
        _oRequests[_requestId].processingTime = _oRequests[_requestId].responseTimestamp - _oRequests[_requestId].requestTimestamp;

        if( keccak256(abi.encodePacked(status)) == keccak256(abi.encodePacked("PENDING")) )
        {
            // nothing to do with the info returned

            return;  // Don't call the user's callback
        }
        else if( keccak256(abi.encodePacked(status)) == keccak256(abi.encodePacked("SUCCESS")) )
        {
            // Fill the QJob information
            _qJobs[jobId_idx].responseTimestamp = block.timestamp;  // in seconds
            _qJobs[jobId_idx].processingTime = _qJobs[jobId_idx].responseTimestamp - _qJobs[jobId_idx].requestTimestamp;     // in seconds
            _qJobs[jobId_idx].status = status;
            _qJobs[jobId_idx].qrandom = result;

            // Remove this job from the list of pending jobs
            pending_job_remove(jobId_idx);

            
        }
        else if( keccak256(abi.encodePacked(status)) == keccak256(abi.encodePacked("ERROR")) )
        {
            // Remove this job from the list of pending jobs
            pending_job_remove(jobId_idx);


            // TO DO: manage ERROR status

        }
        else
        {
            // no more possible statuses

            return;  // Don't call the user's callback
        }

        initialRequestId = _qJobs[jobId_idx].initialRequestId; // Used below to call the correct callback

        // Call the caller callback  --> Only if the status was SUCCESS or ERROR
        if( !isEmptyString(_oRequests[initialRequestId].jobResult_callerCallback) )
            (success, data) = callContractMethod_String_Uint256(_oRequests[initialRequestId].callerAddress, _oRequests[initialRequestId].jobResult_callerCallback, jobId, result, _gasLimit);  
    }


    //
    //  KeeperCompatibleInterface functions
    //

    function checkUpkeep(bytes calldata checkData) view external override returns (bool upkeepNeeded, bytes memory performData) {
        
        // Logic to slow execution of Upkeep: are there pending jobs? and by time
        upkeepNeeded = ( pending_job_length() > 0 ) && ( (block.timestamp - _keeper_lastTimeStamp) > _keeper_interval );

        // We don't use the checkData in this example. The checkData is defined when the Upkeep was registered.
        performData = checkData;
    }

    function performUpkeep(bytes calldata performData) external override {
        
        if ((block.timestamp - _keeper_lastTimeStamp) > _keeper_interval ) {
            //address[] memory wallets = abi.decode(performData, (address[]));

            _keeper_lastTimeStamp = block.timestamp;
            // We don't use the performData in this case. The performData is generated by the Keeper's call to your checkUpkeep function
            performData;

            // Do our logic:
            //
            // - For each pending job -> call the getQRNGJobResponse(string jobId) function
            //

            for( uint i=0; i<_qJobs_pending.length; i++ )
            {
                string memory jobId = string(abi.encodePacked(_qJobs_pending[i]));

                getQRNGJobResponse(jobId);
            }


            //readFromKlimaDaoAndMintChild();
        }
    }


    //
    // Auxiliary function to call another contract's method with only one string param
    //
    function callContractMethod_String(address contractAddress, string memory methodName, string memory paramValue, uint gasLimit)
    public returns (bool success, bytes memory data) {

        (success, data) = contractAddress.call{gas: gasLimit}(
            abi.encodeWithSignature( string(abi.encodePacked(methodName, "(string)")), paramValue )
            );

        return (success, data);
    }
    

    function pending_job_remove(bytes32 jobId) internal {
        for( uint i=0; i<_qJobs_pending.length; i++ )
        {
            if( _qJobs_pending[i] == jobId)
            {
                delete(_qJobs_pending[i]);
                return;
            }
        }
    }

    function pending_job_add(bytes32 jobId) internal{
        _qJobs_pending.push(jobId);
    }

    function pending_job_length() internal view returns (uint){
        return _qJobs_pending.length;
    }


    //
    // Auxiliary function to call another contract's method with two params: one string and one uint
    //
    function callContractMethod_String_Uint256(address contractAddress, string memory methodName, string memory paramValue1, uint256 paramValue2, uint gasLimit)
    public returns (bool success, bytes memory data) {

        (success, data) = contractAddress.call{gas: gasLimit}(
            abi.encodeWithSignature( string(abi.encodePacked(methodName, "(string,uint256)")), paramValue1, paramValue2 )  // Caution!! no spaces between types
            );

        return (success, data);
    }

    function isEmptyString(string memory str) public pure returns(bool) {
        bytes memory emptyStringTest = bytes(str); // Uses memory
        
        if (emptyStringTest.length == 0)
            return true;
        
        return false;
    }

    function getBalance() public view onlyOwner returns(uint){
        return address(this).balance;
    }

    function withdraw(uint amount) external onlyOwner {

        if( amount == 0)
            payable(owner()).transfer(address(this).balance);
        else if( amount < address(this).balance )
            payable(owner()).transfer(amount);
        else
            payable(owner()).transfer(address(this).balance);
    }

    function getLinkBalance() public view onlyOwner returns(uint){
        return IERC20(LINK_TOKEN_ADDRESS).balanceOf(address(this));
    }

    function withdrawLink(uint amount) external onlyOwner {

        if( amount == 0)
            _linkTokenInterface.transfer(owner(), getLinkBalance());
        else if( amount < getLinkBalance() )
            _linkTokenInterface.transfer(owner(), amount);
        else
            _linkTokenInterface.transfer(owner(), getLinkBalance());
    }
}