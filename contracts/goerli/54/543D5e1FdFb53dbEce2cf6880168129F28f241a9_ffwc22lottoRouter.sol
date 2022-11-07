/**
 *Submitted for verification at Etherscan.io on 2022-11-07
*/

// File: @chainlink/contracts/src/v0.8/vendor/ENSResolver.sol


pragma solidity ^0.8.0;

abstract contract ENSResolver_Chainlink {
  function addr(bytes32 node) public view virtual returns (address);
}

// File: @chainlink/contracts/src/v0.8/interfaces/PointerInterface.sol


pragma solidity ^0.8.0;

interface PointerInterface {
  function getAddress() external view returns (address);
}

// File: @chainlink/contracts/src/v0.8/interfaces/OracleInterface.sol


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

// File: @chainlink/contracts/src/v0.8/interfaces/ChainlinkRequestInterface.sol


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

// File: @chainlink/contracts/src/v0.8/interfaces/OperatorInterface.sol


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

// File: @chainlink/contracts/src/v0.8/interfaces/LinkTokenInterface.sol


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

// File: @chainlink/contracts/src/v0.8/interfaces/ENSInterface.sol


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

// File: @chainlink/contracts/src/v0.8/vendor/BufferChainlink.sol


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

// File: @chainlink/contracts/src/v0.8/vendor/CBORChainlink.sol


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

// File: @chainlink/contracts/src/v0.8/Chainlink.sol


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

// File: @chainlink/contracts/src/v0.8/ChainlinkClient.sol


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
    ENSResolver_Chainlink resolver = ENSResolver_Chainlink(s_ens.resolver(linkSubnode));
    setChainlinkToken(resolver.addr(linkSubnode));
    updateChainlinkOracleWithENS();
  }

  /**
   * @notice Sets the stored oracle contract with the address resolved by ENS
   * @dev This may be called on its own as long as `useChainlinkWithENS` has been called previously
   */
  function updateChainlinkOracleWithENS() internal {
    bytes32 oracleSubnode = keccak256(abi.encodePacked(s_ensNode, ENS_ORACLE_SUBNAME));
    ENSResolver_Chainlink resolver = ENSResolver_Chainlink(s_ens.resolver(oracleSubnode));
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

// File: @openzeppelin/contracts/utils/Context.sol


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

// File: @openzeppelin/contracts/token/ERC20/IERC20.sol


// OpenZeppelin Contracts (last updated v4.6.0) (token/ERC20/IERC20.sol)

pragma solidity ^0.8.0;

/**
 * @dev Interface of the ERC20 standard as defined in the EIP.
 */
interface IERC20 {
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
}

// File: @openzeppelin/contracts/token/ERC20/extensions/IERC20Metadata.sol


// OpenZeppelin Contracts v4.4.1 (token/ERC20/extensions/IERC20Metadata.sol)

pragma solidity ^0.8.0;


/**
 * @dev Interface for the optional metadata functions from the ERC20 standard.
 *
 * _Available since v4.1._
 */
interface IERC20Metadata is IERC20 {
    /**
     * @dev Returns the name of the token.
     */
    function name() external view returns (string memory);

    /**
     * @dev Returns the symbol of the token.
     */
    function symbol() external view returns (string memory);

    /**
     * @dev Returns the decimals places of the token.
     */
    function decimals() external view returns (uint8);
}

// File: @openzeppelin/contracts/token/ERC20/ERC20.sol


// OpenZeppelin Contracts (last updated v4.7.0) (token/ERC20/ERC20.sol)

pragma solidity ^0.8.0;




/**
 * @dev Implementation of the {IERC20} interface.
 *
 * This implementation is agnostic to the way tokens are created. This means
 * that a supply mechanism has to be added in a derived contract using {_mint}.
 * For a generic mechanism see {ERC20PresetMinterPauser}.
 *
 * TIP: For a detailed writeup see our guide
 * https://forum.zeppelin.solutions/t/how-to-implement-erc20-supply-mechanisms/226[How
 * to implement supply mechanisms].
 *
 * We have followed general OpenZeppelin Contracts guidelines: functions revert
 * instead returning `false` on failure. This behavior is nonetheless
 * conventional and does not conflict with the expectations of ERC20
 * applications.
 *
 * Additionally, an {Approval} event is emitted on calls to {transferFrom}.
 * This allows applications to reconstruct the allowance for all accounts just
 * by listening to said events. Other implementations of the EIP may not emit
 * these events, as it isn't required by the specification.
 *
 * Finally, the non-standard {decreaseAllowance} and {increaseAllowance}
 * functions have been added to mitigate the well-known issues around setting
 * allowances. See {IERC20-approve}.
 */
contract ERC20 is Context, IERC20, IERC20Metadata {
    mapping(address => uint256) private _balances;

    mapping(address => mapping(address => uint256)) private _allowances;

    uint256 private _totalSupply;

    string private _name;
    string private _symbol;

    /**
     * @dev Sets the values for {name} and {symbol}.
     *
     * The default value of {decimals} is 18. To select a different value for
     * {decimals} you should overload it.
     *
     * All two of these values are immutable: they can only be set once during
     * construction.
     */
    constructor(string memory name_, string memory symbol_) {
        _name = name_;
        _symbol = symbol_;
    }

    /**
     * @dev Returns the name of the token.
     */
    function name() public view virtual override returns (string memory) {
        return _name;
    }

    /**
     * @dev Returns the symbol of the token, usually a shorter version of the
     * name.
     */
    function symbol() public view virtual override returns (string memory) {
        return _symbol;
    }

    /**
     * @dev Returns the number of decimals used to get its user representation.
     * For example, if `decimals` equals `2`, a balance of `505` tokens should
     * be displayed to a user as `5.05` (`505 / 10 ** 2`).
     *
     * Tokens usually opt for a value of 18, imitating the relationship between
     * Ether and Wei. This is the value {ERC20} uses, unless this function is
     * overridden;
     *
     * NOTE: This information is only used for _display_ purposes: it in
     * no way affects any of the arithmetic of the contract, including
     * {IERC20-balanceOf} and {IERC20-transfer}.
     */
    function decimals() public view virtual override returns (uint8) {
        return 18;
    }

    /**
     * @dev See {IERC20-totalSupply}.
     */
    function totalSupply() public view virtual override returns (uint256) {
        return _totalSupply;
    }

    /**
     * @dev See {IERC20-balanceOf}.
     */
    function balanceOf(address account) public view virtual override returns (uint256) {
        return _balances[account];
    }

    /**
     * @dev See {IERC20-transfer}.
     *
     * Requirements:
     *
     * - `to` cannot be the zero address.
     * - the caller must have a balance of at least `amount`.
     */
    function transfer(address to, uint256 amount) public virtual override returns (bool) {
        address owner = _msgSender();
        _transfer(owner, to, amount);
        return true;
    }

    /**
     * @dev See {IERC20-allowance}.
     */
    function allowance(address owner, address spender) public view virtual override returns (uint256) {
        return _allowances[owner][spender];
    }

    /**
     * @dev See {IERC20-approve}.
     *
     * NOTE: If `amount` is the maximum `uint256`, the allowance is not updated on
     * `transferFrom`. This is semantically equivalent to an infinite approval.
     *
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     */
    function approve(address spender, uint256 amount) public virtual override returns (bool) {
        address owner = _msgSender();
        _approve(owner, spender, amount);
        return true;
    }

    /**
     * @dev See {IERC20-transferFrom}.
     *
     * Emits an {Approval} event indicating the updated allowance. This is not
     * required by the EIP. See the note at the beginning of {ERC20}.
     *
     * NOTE: Does not update the allowance if the current allowance
     * is the maximum `uint256`.
     *
     * Requirements:
     *
     * - `from` and `to` cannot be the zero address.
     * - `from` must have a balance of at least `amount`.
     * - the caller must have allowance for ``from``'s tokens of at least
     * `amount`.
     */
    function transferFrom(
        address from,
        address to,
        uint256 amount
    ) public virtual override returns (bool) {
        address spender = _msgSender();
        _spendAllowance(from, spender, amount);
        _transfer(from, to, amount);
        return true;
    }

    /**
     * @dev Atomically increases the allowance granted to `spender` by the caller.
     *
     * This is an alternative to {approve} that can be used as a mitigation for
     * problems described in {IERC20-approve}.
     *
     * Emits an {Approval} event indicating the updated allowance.
     *
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     */
    function increaseAllowance(address spender, uint256 addedValue) public virtual returns (bool) {
        address owner = _msgSender();
        _approve(owner, spender, allowance(owner, spender) + addedValue);
        return true;
    }

    /**
     * @dev Atomically decreases the allowance granted to `spender` by the caller.
     *
     * This is an alternative to {approve} that can be used as a mitigation for
     * problems described in {IERC20-approve}.
     *
     * Emits an {Approval} event indicating the updated allowance.
     *
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     * - `spender` must have allowance for the caller of at least
     * `subtractedValue`.
     */
    function decreaseAllowance(address spender, uint256 subtractedValue) public virtual returns (bool) {
        address owner = _msgSender();
        uint256 currentAllowance = allowance(owner, spender);
        require(currentAllowance >= subtractedValue, "ERC20: decreased allowance below zero");
        unchecked {
            _approve(owner, spender, currentAllowance - subtractedValue);
        }

        return true;
    }

    /**
     * @dev Moves `amount` of tokens from `from` to `to`.
     *
     * This internal function is equivalent to {transfer}, and can be used to
     * e.g. implement automatic token fees, slashing mechanisms, etc.
     *
     * Emits a {Transfer} event.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `from` must have a balance of at least `amount`.
     */
    function _transfer(
        address from,
        address to,
        uint256 amount
    ) internal virtual {
        require(from != address(0), "ERC20: transfer from the zero address");
        require(to != address(0), "ERC20: transfer to the zero address");

        _beforeTokenTransfer(from, to, amount);

        uint256 fromBalance = _balances[from];
        require(fromBalance >= amount, "ERC20: transfer amount exceeds balance");
        unchecked {
            _balances[from] = fromBalance - amount;
        }
        _balances[to] += amount;

        emit Transfer(from, to, amount);

        _afterTokenTransfer(from, to, amount);
    }

    /** @dev Creates `amount` tokens and assigns them to `account`, increasing
     * the total supply.
     *
     * Emits a {Transfer} event with `from` set to the zero address.
     *
     * Requirements:
     *
     * - `account` cannot be the zero address.
     */
    function _mint(address account, uint256 amount) internal virtual {
        require(account != address(0), "ERC20: mint to the zero address");

        _beforeTokenTransfer(address(0), account, amount);

        _totalSupply += amount;
        _balances[account] += amount;
        emit Transfer(address(0), account, amount);

        _afterTokenTransfer(address(0), account, amount);
    }

    /**
     * @dev Destroys `amount` tokens from `account`, reducing the
     * total supply.
     *
     * Emits a {Transfer} event with `to` set to the zero address.
     *
     * Requirements:
     *
     * - `account` cannot be the zero address.
     * - `account` must have at least `amount` tokens.
     */
    function _burn(address account, uint256 amount) internal virtual {
        require(account != address(0), "ERC20: burn from the zero address");

        _beforeTokenTransfer(account, address(0), amount);

        uint256 accountBalance = _balances[account];
        require(accountBalance >= amount, "ERC20: burn amount exceeds balance");
        unchecked {
            _balances[account] = accountBalance - amount;
        }
        _totalSupply -= amount;

        emit Transfer(account, address(0), amount);

        _afterTokenTransfer(account, address(0), amount);
    }

    /**
     * @dev Sets `amount` as the allowance of `spender` over the `owner` s tokens.
     *
     * This internal function is equivalent to `approve`, and can be used to
     * e.g. set automatic allowances for certain subsystems, etc.
     *
     * Emits an {Approval} event.
     *
     * Requirements:
     *
     * - `owner` cannot be the zero address.
     * - `spender` cannot be the zero address.
     */
    function _approve(
        address owner,
        address spender,
        uint256 amount
    ) internal virtual {
        require(owner != address(0), "ERC20: approve from the zero address");
        require(spender != address(0), "ERC20: approve to the zero address");

        _allowances[owner][spender] = amount;
        emit Approval(owner, spender, amount);
    }

    /**
     * @dev Updates `owner` s allowance for `spender` based on spent `amount`.
     *
     * Does not update the allowance amount in case of infinite allowance.
     * Revert if not enough allowance is available.
     *
     * Might emit an {Approval} event.
     */
    function _spendAllowance(
        address owner,
        address spender,
        uint256 amount
    ) internal virtual {
        uint256 currentAllowance = allowance(owner, spender);
        if (currentAllowance != type(uint256).max) {
            require(currentAllowance >= amount, "ERC20: insufficient allowance");
            unchecked {
                _approve(owner, spender, currentAllowance - amount);
            }
        }
    }

    /**
     * @dev Hook that is called before any transfer of tokens. This includes
     * minting and burning.
     *
     * Calling conditions:
     *
     * - when `from` and `to` are both non-zero, `amount` of ``from``'s tokens
     * will be transferred to `to`.
     * - when `from` is zero, `amount` tokens will be minted for `to`.
     * - when `to` is zero, `amount` of ``from``'s tokens will be burned.
     * - `from` and `to` are never both zero.
     *
     * To learn more about hooks, head to xref:ROOT:extending-contracts.adoc#using-hooks[Using Hooks].
     */
    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 amount
    ) internal virtual {}

    /**
     * @dev Hook that is called after any transfer of tokens. This includes
     * minting and burning.
     *
     * Calling conditions:
     *
     * - when `from` and `to` are both non-zero, `amount` of ``from``'s tokens
     * has been transferred to `to`.
     * - when `from` is zero, `amount` tokens have been minted for `to`.
     * - when `to` is zero, `amount` of ``from``'s tokens have been burned.
     * - `from` and `to` are never both zero.
     *
     * To learn more about hooks, head to xref:ROOT:extending-contracts.adoc#using-hooks[Using Hooks].
     */
    function _afterTokenTransfer(
        address from,
        address to,
        uint256 amount
    ) internal virtual {}
}

// File: ffwc22lotto_router.sol

pragma solidity =0.8.7;


// import "@chainlink/contracts/src/v0.8/ConfirmedOwner.sol";

contract ffwc22lottoRouter is ChainlinkClient {
    //chainlink PART
    using Chainlink for Chainlink.Request;
    event RequestFulfilledString(bytes32 indexed requestId, string response);
    event RequestFulfilledUint256(bytes32 indexed requestId, uint256 response);
    event RequestFulfilledBytes(bytes32 indexed requestId, bytes response);

    address public _owner;
    address public _announcer;
    address public _USD;

    //for marking if the result is announced
    bool public _isAnnounced;
    uint8 private _teamLength = 32;

    //percents
    uint8 private _superChampionPrizePercent;
    uint8 private _championPrizePercent;
    uint8 private _runnerupPrizePercent;
    uint8 private _devPercent;
    uint8 private _announcerPercent;

    //start sale time
    uint256 public _startedSaleTimestamp;
    //deadline sale time
    uint32 private _closedSaleTimestamp;

    //start ticket price
    uint256 private _initTicketPrice;
    //start ticket price
    uint256 private _ticketPriceRisePerDay;

    //prize pool
    uint256 private _prizePool;

    //reward that give to all holders // normally all in prizePool - dev part
    uint256 private _rewardAmount;

    //ticket_index => ticket's number (that is sold)
    mapping(uint32 => uint32) private _ticketSoldList;
    //recent length of _ticketSoldList
    uint32 private _ticketSoldLength;

    //ticket's number => status (true = sold,false = available)
    mapping(uint32 => bool) private _isTicketSold;
    //ticket's number => status (true = claimed, false = unclaimed)
    mapping(uint32 => bool) private _isTicketClaimed;

    //holder's address => ticket_index => number
    mapping(address => mapping(uint32 => uint32)) private _ticketHoldingList;
    //recent length of _ticketHoldingList[ holder's address ]
    mapping(address => uint32) private _ticketHoldingLength;

    //to count how many holder in each nation_id
    //nation_id to #ticket
    mapping(uint8 => uint32) private _nationIdTicketHolderLength;

    mapping(string => uint8) public _nationCodeToNationId;

    //matchId of the final match
    string private _SEASONID;
    //team name in final
    string private _HOMENATIONCODE;
    bytes32 private _HOMENATIONCODEReqId;
    string private _AWAYNATIONCODE;
    bytes32 private _AWAYNATIONCODEReqId;
    //team #goal in final of sportdataapi
    uint8 private _HOMEGOAL = 255; // to check if #goal is fulfilled in case #goal is 0
    bytes32 private _HOMEGOALReqId;
    uint8 private _AWAYGOAL = 255; // to check if #goal is fulfilled in case #goal is 0
    bytes32 private _AWAYGOALReqId;
    // AWAY starting XI
    uint8 private _SCORENO1;
    bytes32 private _SCORENO1ReqId;
    uint8 private _SCORENO2;
    bytes32 private _SCORENO2ReqId;
    uint8 private _SCORENO3;
    bytes32 private _SCORENO3ReqId;
    uint8 private _SCORENO4;
    bytes32 private _SCORENO4ReqId;


    //number that won super prize
    uint16 private _superChampionCodeWC22;
    //nation_id that won the prize
    uint8 private _championNationIdWC22;
    uint8 private _runnerupNationIdWC22;
    uint32 private _lastFulFillTimestampWC22;

    //old winning prize (WC2018)
    uint16 private _superChampionCodeWC18;
    uint8 private _championNationIdWC18;
    uint8 private _runnerupNationIdWC18;
    uint32 private _lastFulFillTimestampWC18;

    //sportapi MatchId
    // string WC22FinalMatchID = "429770"; 
    string WC22SeasonID = "3072"; 
    string WC22DateFrom = "2022-12-18"; 
    // string WC18FinalMatchID = "129920"; 
    string WC18SeasonID = "1193"; 
    string WC18DateFrom = "2018-07-15"; 
    
    //chainlink jobId for HTTP GET
    bytes32 jobIdString = "7d80a6386ef543a3abb52817f6707e3b";
    bytes32 jobIdUint256 = "ca98366cc7314957b8c012c72f05aeeb";
    bytes32 jobIdBytes = "7da2702f37fd48e5b1b9a5715e3509b6";
    //chainlink fee per request = 0.1 LINK
    uint256 LINK_fee = (1 * LINK_DIVISIBILITY) / 10; // 0,1 * 10**18 (Varies by network and job)


    modifier ensure(uint32 deadline) {
        require(deadline >= block.timestamp, "TicketRouter: EXPIRED");
        _;
    }
    modifier isOwner() {
        require(msg.sender == _owner, "TicketRouter: AUTHORIZATION_FAILED");
        _;
    }

    /**
     * @notice Initialize the link token and target oracle
     *
     * Goerli Testnet details:
     * Link Token: 0x326C977E6efc84E512bB9C30f76E30c160eD06FB
     * Oracle: 0xCC79157eb46F5624204f47AB42b3906cAA40eaB7 (Chainlink DevRel)
     *
     */
    /**
     * @notice Initialize the link token and target oracle
     *
     * Binance Testnet details:
     * Link Token: 0x84b9B910527Ad5C03A9Ca831909E21e236EA7b06
     * Oracle: 0xCC79157eb46F5624204f47AB42b3906cAA40eaB7 (Chainlink DevRel)
     *
     */
    /**
     * @notice Initialize the link token and target oracle
     *
     * Mumbai Testnet details:
     * Link Token: 0x326C977E6efc84E512bB9C30f76E30c160eD06FB
     * Oracle: 0x40193c8518BB267228Fc409a613bDbD8eC5a97b3 (Chainlink DevRel)
     *
     */
    constructor() {
        _owner = msg.sender;
        //setup currency token for ticket purchasing
        _USD = 0xeD24FC36d5Ee211Ea25A80239Fb8C4Cfd80f12Ee;

        //setup Chainlick oracle for pulling result
        setChainlinkToken(0x326C977E6efc84E512bB9C30f76E30c160eD06FB);
        setChainlinkOracle(0xCC79157eb46F5624204f47AB42b3906cAA40eaB7);

        //setup ticket price
        _initTicketPrice = 2000000000000000000; //2 USD / Per ticket
        _ticketPriceRisePerDay = 1000000000000000000; // rise 1 USD / Per day

        //setup percents
        _superChampionPrizePercent = 20;
        _championPrizePercent = 60;
        _runnerupPrizePercent = 15;
        _devPercent = 4;
        _announcerPercent = 1;

        //set sale period
        _startedSaleTimestamp = block.timestamp; // deploy time
        _closedSaleTimestamp = 1671375600; // FIFA World Cup 2022 Final start

        //setup nation code to ID (Order by string as frontend)
        _nationCodeToNationId["ARG"] = 0;
        _nationCodeToNationId["AUS"] = 1;
        _nationCodeToNationId["BEL"] = 2;
        _nationCodeToNationId["BRA"] = 3;
        _nationCodeToNationId["CMR"] = 4;
        _nationCodeToNationId["CAN"] = 5;
        _nationCodeToNationId["CRC"] = 6;
        _nationCodeToNationId["CRO"] = 7;
        _nationCodeToNationId["DEN"] = 8;
        _nationCodeToNationId["ECU"] = 9;
        _nationCodeToNationId["ENG"] = 10;
        _nationCodeToNationId["FRA"] = 11;
        _nationCodeToNationId["GER"] = 12;
        _nationCodeToNationId["GHA"] = 13;
        _nationCodeToNationId["IRN"] = 14;
        _nationCodeToNationId["JPN"] = 15;
        _nationCodeToNationId["MEX"] = 16;
        _nationCodeToNationId["MAR"] = 17;
        _nationCodeToNationId["NED"] = 18;
        _nationCodeToNationId["POL"] = 19;
        _nationCodeToNationId["POR"] = 20;
        _nationCodeToNationId["QAT"] = 21;
        _nationCodeToNationId["KSA"] = 22;
        _nationCodeToNationId["SEN"] = 23;
        _nationCodeToNationId["SRB"] = 24;
        _nationCodeToNationId["KOR"] = 25;
        _nationCodeToNationId["ESP"] = 26;
        _nationCodeToNationId["SUI"] = 27;
        _nationCodeToNationId["TUN"] = 28;
        _nationCodeToNationId["USA"] = 29;
        _nationCodeToNationId["URU"] = 30;
        _nationCodeToNationId["WAL"] = 31;
    }

    function numberToNationId(uint32 number)
        private
        view
        returns (uint8 nationId)
    {
        return uint8(number % _teamLength);
    }

    function numberToTicketCode(uint32 number)
        private
        view
        returns (uint16 code)
    {
        return uint16(number / _teamLength);
    }

    function getIfOnSale() public view virtual returns (bool isOnSale) {
        return (block.timestamp < _closedSaleTimestamp);
    }

    function getPriceNow() public view virtual returns (uint256 price) {
        uint256 passedDays = (block.timestamp - _startedSaleTimestamp) / 86400;
        if(passedDays < 3){
            return _initTicketPrice;
        }
        return _initTicketPrice + (passedDays * _ticketPriceRisePerDay);
    }

    function getPriceTomorrow()
        public
        view
        virtual
        returns (uint256 price)
    {
        uint256 passedDays = 1 + ((block.timestamp - _startedSaleTimestamp) / 86400);
        if(passedDays < 3){
            return _initTicketPrice;
        }
        return _initTicketPrice + (passedDays * _ticketPriceRisePerDay);
    }

    function getSaleDeadline()
        public
        view
        virtual
        returns (uint32 saleDeadline)
    {
        return (_closedSaleTimestamp);
    }

    function getHolderLengthByNationId(uint8 nationId)
        public
        view
        virtual
        returns (uint32 holderLength)
    {
        return (_nationIdTicketHolderLength[nationId]);
    }

    function getAllTicketsByHolder(address holder)
        public
        view
        virtual
        returns (uint32[] memory number)
    {
        number = new uint32[](_ticketHoldingLength[holder]);
        for (uint32 i = 0; i < _ticketHoldingLength[holder]; i++) {
            number[i] = _ticketHoldingList[holder][i];
        }
        return (number);
    }

    function getAllSoldTickets()
        public
        view
        virtual
        returns (uint32[] memory number)
    {
        number = new uint32[](_ticketSoldLength);
        for (uint32 i = 0; i < _ticketSoldLength; i++) {
            number[i] = _ticketSoldList[i];
        }
        return (number);
    }

    function getPrizePool() public view virtual returns (uint256 prizePool) {
        return (_prizePool);
    }

    function getSharePercents()
        public
        view
        virtual
        returns (
            uint8 superChampionPrizePercent,
            uint8 championPrizePercent,
            uint8 runnerupPrizePercent,
            uint8 devPercent,
            uint8 announcerPercent
        )
    {
        return (
            _superChampionPrizePercent,
            _championPrizePercent,
            _runnerupPrizePercent,
            _devPercent,
            _announcerPercent
        );
    }

    function getAllClaimableAmountByHolder(address holder)
        public
        view
        virtual
        returns (uint256 claimable)
    {
        if (!_isAnnounced) {
            return 0;
        }
        claimable = 0;
        for (uint32 i = 0; i < _ticketHoldingLength[holder]; i++) {
            uint32 number = _ticketHoldingList[holder][i];
            //check if this ticket is claimed
            if (!_isTicketClaimed[number]) {
                claimable += getClaimableAmountByTicket(number);
            }
        }
    }

    function getClaimableAmountByTicket(uint32 number)
        public
        view
        virtual
        returns (uint256 claimable)
    {
        if (!_isAnnounced) {
            return 0;
        }
        //check if this ticket is claimed
        if (_isTicketClaimed[number]) {
            return 0;
        }
        claimable = 0;
        uint8 nationId = numberToNationId(number);
        //check if winning Super Champion Prize
        {
            uint16 ticketCode = numberToTicketCode(number);
            if (
                nationId == _championNationIdWC22 &&
                ticketCode == _superChampionCodeWC22
            ) {
                //super champion win xx% of Pool
                claimable += (_prizePool * (_superChampionPrizePercent)) / (100);
            }
        }
        //check if winning Other Prizes
        {
            uint256 wholePrize = 0;
            if (nationId == _championNationIdWC22) {
                //champion prize win yy% of Pool
                wholePrize = (_prizePool * (_championPrizePercent)) / (100);
            } else if (nationId == _runnerupNationIdWC22) {
                //runnerup prize win zz% of Pool
                wholePrize = (_prizePool * (_runnerupPrizePercent)) / (100);
            }
            //add reward ( wholePrize of the share / number of that nation's ticket holder)
            claimable += wholePrize / (getHolderLengthByNationId(nationId));
        }
        return claimable;
    }

    function buyTicket(
        uint32 number,
        uint256 ticketPrice,
        uint32 deadline
    ) external virtual ensure(deadline) returns (bool success) {
        require(
            !_isAnnounced,
            "TicketRouter: TICKETS_ARE_NOT_ON_SALE_AFTER_ANNOUNCING"
        );
        require(
            !_isTicketSold[number],
            "TicketRouter: THIS_TICKET_IS_SOLD_OUT"
        );
        //cannot buy ticket after deadline
        require(getIfOnSale(), "TicketRouter: TICKET_SALE_IS_CLOSED");
        //cannot buy ticket with price lower than getTicketPriceNow()
        require(
            ticketPrice >= getPriceNow(),
            "TicketRouter: OFFERED_TICKET_PRICE_IS_TOO_LOW"
        );

        //transfer token to this contract
        IERC20(_USD).transferFrom(msg.sender, address(this), ticketPrice);

        //add ticket to this owner
        //check how many tickets this owner has
        uint32 curLength = _ticketHoldingLength[msg.sender];
        //save ticket data for this owner
        _ticketHoldingList[msg.sender][curLength] = number;
        _ticketHoldingLength[msg.sender] = curLength + 1;

        //add this ticket to the sold ticket list
        uint32 curSoldLength = _ticketSoldLength;
        _ticketSoldList[curSoldLength] = number;
        _ticketSoldLength = curSoldLength + 1;

        //increase #holders of this nation_id
        _nationIdTicketHolderLength[numberToNationId(number)] += 1;

        //increase _prizePool
        _prizePool += ticketPrice;

        return true;
    }

    function claimTicket(uint32 number, uint32 deadline)
        external
        virtual
        ensure(deadline)
        returns (uint256 amounts)
    {
        require(
            !_isTicketClaimed[number],
            "TicketRouter: THIS_TICKET_IS_CLAIMED"
        );

        amounts = getClaimableAmountByTicket(number);
        //transfer reward to the ticket holder
        IERC20(_USD).transfer(msg.sender, amounts);
        //mark that this ticket is claimed
        _isTicketClaimed[number] = true;

        return amounts;
    }

    function claimAllTickets(uint32 deadline)
        external
        virtual
        ensure(deadline)
        returns (uint256 amounts)
    {
        amounts = 0;
        for (uint32 i = 0; i < _ticketHoldingLength[msg.sender]; i++) {
            uint32 number = _ticketHoldingList[msg.sender][i];
            //check if this ticket is claimed
            if (!_isTicketClaimed[number]) {
                amounts += getClaimableAmountByTicket(number);
                //mark that this ticket is claimed
                _isTicketClaimed[number] = true;
            }
        }
        //transfer reward to the ticket holder
        IERC20(_USD).transfer(msg.sender, amounts);

        return amounts;
    }

    function devClaimReward(uint32 deadline)
        external
        virtual
        ensure(deadline)
        isOwner
        returns (uint256 amounts)
    {
        require(
            _isAnnounced,
            "TicketRouter: DEV_CAN_CLAIM_ONLY_AFTER_ANNOUNCING"
        );
        require(_devPercent > 0, "TicketRouter: NO_REWARD_FOR_DEV");

        amounts = (_prizePool * _devPercent) / (100);

        //transfer the reward to the dev
        IERC20(_USD).transfer(_owner, amounts);

        return amounts;
    }

    function getWC22()
        public
        view
        virtual
        returns (
            uint32 lastFulFillTimestampWC22,
            uint16 superChampionCodeWC22,
            uint8 championNationIdWC22,
            uint8 runnerupNationIdWC22
        )
    {
        require( _isAnnounced, "TicketRouter: THE_RESULT_IS_NOT_ANNOUCED_YET");
        return ( _lastFulFillTimestampWC22, _superChampionCodeWC22, _championNationIdWC22, _runnerupNationIdWC22);
    }
    
    function getWC18()
        public
        view
        virtual
        returns (
            uint32 lastFulFillTimestampWC18,
            uint16 superChampionCodeWC18,
            uint8 championNationIdWC18,
            uint8 runnerupNationIdWC18
        )
    {
        return ( _lastFulFillTimestampWC18, _superChampionCodeWC18, _championNationIdWC18, _runnerupNationIdWC18 );
    }

    function getWCSCORENOs()
        public
        view
        virtual
        returns (
            uint8 SCORENO1,
            uint8 SCORENO2,
            uint8 SCORENO3,
            uint8 SCORENO4
        ){
         return (
            _SCORENO1,
            _SCORENO2,
            _SCORENO3,
            _SCORENO4
        );
    }

    function getWCRAW()
        public
        view
        virtual
        returns (
            string memory SEASONID,
            string memory HOMENATIONCODE,
            string memory AWAYNATIONCODE,
            uint8 HOMEGOAL,
            uint8 AWAYGOAL,
            uint256 SQUAREMULSCORE
        ){

        SQUAREMULSCORE = uint256 ( _SCORENO1 *_SCORENO1 * _SCORENO2 *_SCORENO2 * _SCORENO3 * _SCORENO3 * _SCORENO4 * _SCORENO4 );

        return (
            _SEASONID,
            _HOMENATIONCODE,
            _AWAYNATIONCODE,
            _HOMEGOAL,
            _AWAYGOAL,
            SQUAREMULSCORE
        );
    }

    //===================================
    //chainlink PART
    //===================================
    function reqWC22(string memory sportdataAPIKEY, uint32 deadline)
        external
        virtual
        ensure(deadline)
        returns (bool success)
    {
        require(
            block.timestamp - _closedSaleTimestamp > 86400,
            "TicketRouter : ANNOUNCING_IS_ONLY_ABLE_24HRS_AFTER_CLOSED"
        );
        require(
            !_isAnnounced,
            "TicketRouter : THE_RESULT_IS_ALREADY_ANNOUNCED"
        );

        //only reward to the first announcer
        if(_announcer == address(0)){
            _announcer = msg.sender;
            //transfer the reward to the annoucer
            uint256 annoucerReward = ( _prizePool * _announcerPercent) / 100;
            IERC20(_USD).transfer( _announcer , annoucerReward);
        }

        //chainlink => sportdataapi
        return reqSportdataWithChainLink( sportdataAPIKEY, WC22SeasonID, WC22DateFrom);
    }
    function reqWC18( string memory sportdataAPIKEY, uint32 deadline)
        external
        virtual
        ensure(deadline)
        returns (bool success)
    {
        require(
            block.timestamp < _closedSaleTimestamp ,
            "TicketRouter : DEMO_ANNOUNCING_IS_ONLY_ABLE_BEFORE_MARKET_CLOSED"
        );

        //chainlink => sportdataapi
        return reqSportdataWithChainLink( sportdataAPIKEY, WC18SeasonID, WC18DateFrom);
    }

    function reqSportdataWithChainLink(string memory APIKEY,string memory seasonID, string memory dateFrom)
        private
        returns (bool success)
    {
        string memory matchUrl = string( abi.encodePacked( "https://app.sportdataapi.com/api/v1/soccer/matches?apikey=",APIKEY,"&season_id=",seasonID,"&date_from=",dateFrom ) );        
        string memory topscorerUrl = string( abi.encodePacked( "https://app.sportdataapi.com/api/v1/soccer/topscorers?apikey=", APIKEY,"&season_id=", seasonID) );        
        
        Chainlink.Request memory req;

        //set seasonId (String)
        _SEASONID = seasonID;

        //reset 2 team nation code (String)
        _HOMENATIONCODE = "";
        _AWAYNATIONCODE = "";
        //get 2 team nation code (String)
        {
            //get HOMENATIONCODE
            req = buildChainlinkRequest(
                jobIdString,
                address(this),
                this.fulfillString.selector
            );
            req.add("get", matchUrl);
            req.add("path", "data,0,home_team,short_code");
            _HOMENATIONCODEReqId = sendChainlinkRequest(req, LINK_fee);

            //get AWAYNATIONCODE
            req = buildChainlinkRequest(
                jobIdString,
                address(this),
                this.fulfillString.selector
            );
            req.add("get", matchUrl);
            req.add("path", "data,0,away_team,short_code");
            _AWAYNATIONCODEReqId = sendChainlinkRequest(req, LINK_fee);
        }
        
        //reset 2 team #goal (Int)
        _HOMEGOAL = 255;
        _AWAYGOAL = 255;
        //get 2 team #goal (Int)
        {
            //get HOME #GOAL
            req = buildChainlinkRequest(
                jobIdUint256,
                address(this),
                this.fulfillUint256.selector
            );
            req.add("get", matchUrl);
            req.add("path", "data,0,stats,home_score");
            req.addInt("times", 1);
            _HOMEGOALReqId = sendChainlinkRequest(req, LINK_fee);

            //get AWAY #GOAL
            req = buildChainlinkRequest(
                jobIdUint256,
                address(this),
                this.fulfillUint256.selector
            );
            req.add("get", matchUrl);
            req.add("path", "data,0,stats,away_score");
            req.addInt("times", 1);
            _AWAYGOALReqId = sendChainlinkRequest(req, LINK_fee);
        }

        //reset first 4 top scorer #goal (Int)
        _SCORENO1 = 0;
        _SCORENO2 = 0;
        _SCORENO3 = 0;
        _SCORENO4 = 0;
        //get first 4 top scorer #goal (Int)
        {
            //get SCORENO1
            req = buildChainlinkRequest(
                jobIdUint256,
                address(this),
                this.fulfillUint256.selector
            );
            req.add("get", topscorerUrl);
            req.add("path", "data,0,goals,overall");
            req.addInt("times", 1);
            _SCORENO1ReqId  = sendChainlinkRequest(req, LINK_fee);

            //get SCORENO2
            req = buildChainlinkRequest(
                jobIdUint256,
                address(this),
                this.fulfillUint256.selector
            );
            req.add("get", topscorerUrl);
            req.add("path", "data,1,goals,overall");
            req.addInt("times", 1);
            _SCORENO2ReqId  = sendChainlinkRequest(req, LINK_fee);

            //get SCORENO3
            req = buildChainlinkRequest(
                jobIdUint256,
                address(this),
                this.fulfillUint256.selector
            );
            req.add("get", topscorerUrl);
            req.add("path", "data,2,goals,overall");
            req.addInt("times", 1);
           _SCORENO3ReqId  = sendChainlinkRequest(req, LINK_fee);

           //get SCORENO4
            req = buildChainlinkRequest(
                jobIdUint256,
                address(this),
                this.fulfillUint256.selector
            );
            req.add("get", topscorerUrl);
            req.add("path", "data,3,goals,overall");
            req.addInt("times", 1);
           _SCORENO4ReqId  = sendChainlinkRequest(req, LINK_fee);
        }

        return true;
    }

    function fulfillString(bytes32 requestId, string memory response)
        public
        recordChainlinkFulfillment(requestId)
    {
        emit RequestFulfilledString(requestId, response);

        if (requestId == _HOMENATIONCODEReqId) {
            _HOMENATIONCODE = response;
        } else if (requestId == _AWAYNATIONCODEReqId) {
            _AWAYNATIONCODE = response;
        }

        updateIffullyfulfill();
    }

    function fulfillUint256(bytes32 requestId, uint256 response)
        public
        recordChainlinkFulfillment(requestId)
    {
        emit RequestFulfilledUint256(requestId, response);

        if (requestId == _HOMEGOALReqId) {
            _HOMEGOAL = uint8(response);
        } else if (requestId == _AWAYGOALReqId) {
            _AWAYGOAL = uint8(response);
        } else if (requestId == _SCORENO1ReqId ) {
            _SCORENO1 = uint8(response);
        } else if (requestId == _SCORENO2ReqId ) {
            _SCORENO2 = uint8(response);
        } else if (requestId == _SCORENO3ReqId ) {
            _SCORENO3 = uint8(response);
        } else if (requestId == _SCORENO4ReqId ) {
            _SCORENO4 = uint8(response);
        }

        updateIffullyfulfill();
    }
    
    function updateIffullyfulfill() private {

        //all 4 top scorer #goal square multiplied , if there is any 0 => result = 0
        uint256 SQUAREMULSCORE = uint256 ( _SCORENO1 *_SCORENO1 * _SCORENO2 *_SCORENO2 * _SCORENO3 * _SCORENO3 * _SCORENO4 * _SCORENO4 );
        
        //UPDATE PRIZING NUMBER if data is enough to know who is the winner and the champion code
        if(
            SQUAREMULSCORE > 0 && //all SCOREs must not be 0
            (
                keccak256(abi.encodePacked(_SEASONID)) == keccak256(abi.encodePacked(WC22SeasonID)) || //SEASONID is either WC18 / WC22
                keccak256(abi.encodePacked(_SEASONID)) == keccak256(abi.encodePacked(WC18SeasonID))
            ) && 
            bytes(_HOMENATIONCODE).length != 0 &&
            bytes(_AWAYNATIONCODE).length != 0 &&
            _HOMEGOAL != 255 && //means _HOMEGOAL is fulfilled
            _AWAYGOAL != 255 &&  //means _AWAYGOAL is fulfilled
            _HOMEGOAL != _AWAYGOAL //ended match shouldn't have equal scores
        ){
            //READY TO ANNOUNCE
            bool isWC22 =  (keccak256(abi.encodePacked((_SEASONID))) == keccak256(abi.encodePacked((WC22SeasonID)))); // else WC18
            uint8 homeNationId = _nationCodeToNationId[_HOMENATIONCODE];
            uint8 awayNationId = _nationCodeToNationId[_AWAYNATIONCODE];
            uint8 championNationId;
            uint8 runnerupNationId;
            if( _HOMEGOAL > _AWAYGOAL){//home won
                championNationId = homeNationId;
                runnerupNationId = awayNationId;
            }else{//away won
                championNationId = awayNationId;
                runnerupNationId = homeNationId;
            }
            uint256 SUMSCORE = uint256 ( _SCORENO1 + _SCORENO2 + _SCORENO3 + _SCORENO4 );
            uint16 superChampionCode = uint16 ( (SQUAREMULSCORE + SUMSCORE) % 31250 );

            if(isWC22){//save data for WC22
                _championNationIdWC22 = championNationId;
                _runnerupNationIdWC22 = runnerupNationId;  
                _superChampionCodeWC22 = superChampionCode;                          
                _lastFulFillTimestampWC22 = uint32( block.timestamp );
        
                //mark that the result is announced
                _isAnnounced = true;
            }else{//save data for WC18
                _championNationIdWC18 = championNationId;
                _runnerupNationIdWC18 = runnerupNationId;
                _superChampionCodeWC18 = superChampionCode;
                _lastFulFillTimestampWC18 = uint32( block.timestamp );
            }
        }
    }
}