// SPDX-License-Identifier: MIT OR Apache-2.0
pragma solidity 0.8.17;

import {ProposedOwnable} from "../../shared/ProposedOwnable.sol";
import {IConnector} from "../interfaces/IConnector.sol";

/**
 * @title Connector
 * @author Connext Labs, Inc.
 * @notice This contract has the messaging interface functions used by all connectors.
 *
 * @dev This contract stores information about mirror connectors, but can be used as a
 * base for contracts that do not have a mirror (i.e. the connector handling messaging on
 * mainnet). In this case, the `mirrorConnector` and `MIRROR_DOMAIN`
 * will be empty
 *
 * @dev If ownership is renounced, this contract will be unable to update its `mirrorConnector`
 * or `mirrorGas`
 */
abstract contract Connector is ProposedOwnable, IConnector {
  // ========== Custom Errors ===========

  error Connector__processMessage_notUsed();

  // ============ Events ============

  event NewConnector(
    uint32 indexed domain,
    uint32 indexed mirrorDomain,
    address amb,
    address rootManager,
    address mirrorConnector
  );

  event MirrorConnectorUpdated(address previous, address current);

  // ============ Public Storage ============

  /**
   * @notice The domain of this Messaging (i.e. Connector) contract.
   */
  uint32 public immutable DOMAIN;

  /**
   * @notice Address of the AMB on this domain.
   */
  address public immutable AMB;

  /**
   * @notice RootManager contract address.
   */
  address public immutable ROOT_MANAGER;

  /**
   * @notice The domain of the corresponding messaging (i.e. Connector) contract.
   */
  uint32 public immutable MIRROR_DOMAIN;

  /**
   * @notice Connector on L2 for L1 connectors, and vice versa.
   */
  address public mirrorConnector;

  // ============ Modifiers ============

  /**
   * @notice Errors if the msg.sender is not the registered AMB
   */
  modifier onlyAMB() {
    require(msg.sender == AMB, "!AMB");
    _;
  }

  /**
   * @notice Errors if the msg.sender is not the registered ROOT_MANAGER
   */
  modifier onlyRootManager() {
    // NOTE: RootManager will be zero address for spoke connectors.
    // Only root manager can dispatch a message to spokes/L2s via the hub connector.
    require(msg.sender == ROOT_MANAGER, "!rootManager");
    _;
  }

  // ============ Constructor ============

  /**
   * @notice Creates a new HubConnector instance
   * @dev The connectors are deployed such that there is one on each side of an AMB (i.e.
   * for optimism, there is one connector on optimism and one connector on mainnet)
   * @param _domain The domain this connector lives on
   * @param _mirrorDomain The spoke domain
   * @param _amb The address of the amb on the domain this connector lives on
   * @param _rootManager The address of the RootManager on mainnet
   * @param _mirrorConnector The address of the spoke connector
   */
  constructor(
    uint32 _domain,
    uint32 _mirrorDomain,
    address _amb,
    address _rootManager,
    address _mirrorConnector
  ) ProposedOwnable() {
    // set the owner
    _setOwner(msg.sender);

    // sanity checks on values
    require(_domain != 0, "empty domain");
    require(_rootManager != address(0), "empty rootManager");
    // see note at top of contract on why the mirror values are not sanity checked

    // set immutables
    DOMAIN = _domain;
    AMB = _amb;
    ROOT_MANAGER = _rootManager;
    MIRROR_DOMAIN = _mirrorDomain;
    // set mutables if defined
    if (_mirrorConnector != address(0)) {
      _setMirrorConnector(_mirrorConnector);
    }

    emit NewConnector(_domain, _mirrorDomain, _amb, _rootManager, _mirrorConnector);
  }

  // ============ Receivable ============
  /**
   * @notice Connectors may need to receive native asset to handle fees when sending a
   * message
   */
  receive() external payable {}

  // ============ Admin Functions ============

  /**
   * @notice Sets the address of the l2Connector for this domain
   */
  function setMirrorConnector(address _mirrorConnector) public onlyOwner {
    _setMirrorConnector(_mirrorConnector);
  }

  // ============ Public Functions ============

  /**
   * @notice Processes a message received by an AMB
   * @dev This is called by AMBs to process messages originating from mirror connector
   */
  function processMessage(bytes memory _data) external onlyAMB {
    _processMessage(_data);
    emit MessageProcessed(_data, msg.sender);
  }

  /**
   * @notice Checks the cross domain sender for a given address
   */
  function verifySender(address _expected) external returns (bool) {
    return _verifySender(_expected);
  }

  // ============ Virtual Functions ============

  /**
   * @notice This function is used by the Connext contract on the l2 domain to send a message to the
   * l1 domain (i.e. called by Connext on optimism to send a message to mainnet with roots)
   * @param _data The contents of the message
   * @param _encodedData Data used to send the message; specific to connector
   */
  function _sendMessage(bytes memory _data, bytes memory _encodedData) internal virtual;

  /**
   * @notice This function is used by the AMBs to handle incoming messages. Should store the latest
   * root generated on the l2 domain.
   */
  function _processMessage(bytes memory _data) internal virtual;

  /**
   * @notice Verify that the msg.sender is the correct AMB contract, and that the message's origin sender
   * is the expected address.
   * @dev Should be overridden by the implementing Connector contract.
   */
  function _verifySender(address _expected) internal virtual returns (bool);

  // ============ Private Functions ============

  function _setMirrorConnector(address _mirrorConnector) internal virtual {
    emit MirrorConnectorUpdated(mirrorConnector, _mirrorConnector);
    mirrorConnector = _mirrorConnector;
  }
}

// SPDX-License-Identifier: MIT OR Apache-2.0
pragma solidity 0.8.17;

import {Connector} from "./Connector.sol";

/**
 * @title HubConnector
 * @author Connext Labs, Inc.
 * @notice This contract implements the messaging functions needed on the hub-side of a given AMB.
 * The HubConnector has a limited set of functionality compared to the SpokeConnector, namely that
 * it contains no logic to store or prove messages.
 *
 * @dev This contract should be deployed on the hub-side of an AMB (i.e. on L1), and contracts
 * which extend this should implement the virtual functions defined in the BaseConnector class
 */
abstract contract HubConnector is Connector {
  /**
   * @notice Creates a new HubConnector instance
   * @dev The connectors are deployed such that there is one on each side of an AMB (i.e.
   * for optimism, there is one connector on optimism and one connector on mainnet)
   * @param _domain The domain this connector lives on
   * @param _mirrorDomain The spoke domain
   * @param _amb The address of the amb on the domain this connector lives on
   * @param _rootManager The address of the RootManager on mainnet
   * @param _mirrorConnector The address of the spoke connector
   */
  constructor(
    uint32 _domain,
    uint32 _mirrorDomain,
    address _amb,
    address _rootManager,
    address _mirrorConnector
  ) Connector(_domain, _mirrorDomain, _amb, _rootManager, _mirrorConnector) {}

  // ============ Public fns ============
  /**
   * @notice Sends a message over the amb
   * @dev This is called by the root manager *only* on mainnet to propagate the aggregate root
   */
  function sendMessage(bytes memory _data, bytes memory _encodedData) external payable onlyRootManager {
    _sendMessage(_data, _encodedData);
    emit MessageSent(_data, _encodedData, msg.sender);
  }
}

// SPDX-License-Identifier: MIT OR Apache-2.0
pragma solidity 0.8.17;

import {IRootManager} from "../../interfaces/IRootManager.sol";

import {FxBaseRootTunnel} from "./tunnel/FxBaseRootTunnel.sol";

import {HubConnector} from "../HubConnector.sol";

contract PolygonHubConnector is HubConnector, FxBaseRootTunnel {
  // ============ Constructor ============
  constructor(
    uint32 _domain,
    uint32 _mirrorDomain,
    address _amb,
    address _rootManager,
    address _mirrorConnector,
    address _checkPointManager
  )
    HubConnector(_domain, _mirrorDomain, _amb, _rootManager, _mirrorConnector)
    FxBaseRootTunnel(_checkPointManager, _amb)
  {}

  // ============ Private fns ============

  function _verifySender(address _expected) internal view override returns (bool) {
    // NOTE: always return false on polygon
    return false;
  }

  function _sendMessage(bytes memory _data, bytes memory _encodedData) internal override {
    // Should not include specialized calldata
    require(_encodedData.length == 0, "!data length");
    _sendMessageToChild(_data);
  }

  function _processMessageFromChild(bytes memory message) internal override {
    // NOTE: crosschain sender is not directly exposed by the child message

    // do not need any additional sender or origin checks here since the proof contains inclusion proofs of the snapshots

    // get the data (should be the aggregate root)
    require(message.length == 32, "!length");
    // update the root on the root manager
    IRootManager(ROOT_MANAGER).aggregate(MIRROR_DOMAIN, bytes32(message));

    emit MessageProcessed(message, msg.sender);
  }

  function _processMessage(bytes memory _data) internal override {
    // Does nothing, all messages should go through the `_processMessageFromChild` path
    revert Connector__processMessage_notUsed();
  }

  function _setMirrorConnector(address _mirrorConnector) internal override {
    super._setMirrorConnector(_mirrorConnector);

    setFxChildTunnel(_mirrorConnector);
  }
}

// SPDX-License-Identifier: MIT
// https://github.com/fx-portal/contracts/blob/main/contracts/lib/ExitPayloadReader.sol
pragma solidity 0.8.17;

import {RLPReader} from "./RLPReader.sol";

library ExitPayloadReader {
  using RLPReader for bytes;
  using RLPReader for RLPReader.RLPItem;

  uint8 constant WORD_SIZE = 32;

  struct ExitPayload {
    RLPReader.RLPItem[] data;
  }

  struct Receipt {
    RLPReader.RLPItem[] data;
    bytes raw;
    uint256 logIndex;
  }

  struct Log {
    RLPReader.RLPItem data;
    RLPReader.RLPItem[] list;
  }

  struct LogTopics {
    RLPReader.RLPItem[] data;
  }

  // copy paste of private copy() from RLPReader to avoid changing of existing contracts
  function copy(
    uint256 src,
    uint256 dest,
    uint256 len
  ) private pure {
    if (len == 0) return;

    // copy as many word sizes as possible
    for (; len >= WORD_SIZE; len -= WORD_SIZE) {
      assembly {
        mstore(dest, mload(src))
      }

      src += WORD_SIZE;
      dest += WORD_SIZE;
    }

    if (len == 0) return;

    // left over bytes. Mask is used to remove unwanted bytes from the word
    uint256 mask = 256**(WORD_SIZE - len) - 1;
    assembly {
      let srcpart := and(mload(src), not(mask)) // zero out src
      let destpart := and(mload(dest), mask) // retrieve the bytes
      mstore(dest, or(destpart, srcpart))
    }
  }

  function toExitPayload(bytes memory data) internal pure returns (ExitPayload memory) {
    RLPReader.RLPItem[] memory payloadData = data.toRlpItem().toList();

    return ExitPayload(payloadData);
  }

  function getHeaderNumber(ExitPayload memory payload) internal pure returns (uint256) {
    return payload.data[0].toUint();
  }

  function getBlockProof(ExitPayload memory payload) internal pure returns (bytes memory) {
    return payload.data[1].toBytes();
  }

  function getBlockNumber(ExitPayload memory payload) internal pure returns (uint256) {
    return payload.data[2].toUint();
  }

  function getBlockTime(ExitPayload memory payload) internal pure returns (uint256) {
    return payload.data[3].toUint();
  }

  function getTxRoot(ExitPayload memory payload) internal pure returns (bytes32) {
    return bytes32(payload.data[4].toUint());
  }

  function getReceiptRoot(ExitPayload memory payload) internal pure returns (bytes32) {
    return bytes32(payload.data[5].toUint());
  }

  function getReceipt(ExitPayload memory payload) internal pure returns (Receipt memory receipt) {
    receipt.raw = payload.data[6].toBytes();
    RLPReader.RLPItem memory receiptItem = receipt.raw.toRlpItem();

    if (receiptItem.isList()) {
      // legacy tx
      receipt.data = receiptItem.toList();
    } else {
      // pop first byte before parsting receipt
      bytes memory typedBytes = receipt.raw;
      bytes memory result = new bytes(typedBytes.length - 1);
      uint256 srcPtr;
      uint256 destPtr;
      assembly {
        srcPtr := add(33, typedBytes)
        destPtr := add(0x20, result)
      }

      copy(srcPtr, destPtr, result.length);
      receipt.data = result.toRlpItem().toList();
    }

    receipt.logIndex = getReceiptLogIndex(payload);
    return receipt;
  }

  function getReceiptProof(ExitPayload memory payload) internal pure returns (bytes memory) {
    return payload.data[7].toBytes();
  }

  function getBranchMaskAsBytes(ExitPayload memory payload) internal pure returns (bytes memory) {
    return payload.data[8].toBytes();
  }

  function getBranchMaskAsUint(ExitPayload memory payload) internal pure returns (uint256) {
    return payload.data[8].toUint();
  }

  function getReceiptLogIndex(ExitPayload memory payload) internal pure returns (uint256) {
    return payload.data[9].toUint();
  }

  // Receipt methods
  function toBytes(Receipt memory receipt) internal pure returns (bytes memory) {
    return receipt.raw;
  }

  function getLog(Receipt memory receipt) internal pure returns (Log memory) {
    RLPReader.RLPItem memory logData = receipt.data[3].toList()[receipt.logIndex];
    return Log(logData, logData.toList());
  }

  // Log methods
  function getEmitter(Log memory log) internal pure returns (address) {
    return RLPReader.toAddress(log.list[0]);
  }

  function getTopics(Log memory log) internal pure returns (LogTopics memory) {
    return LogTopics(log.list[1].toList());
  }

  function getData(Log memory log) internal pure returns (bytes memory) {
    return log.list[2].toBytes();
  }

  function toRlpBytes(Log memory log) internal pure returns (bytes memory) {
    return log.data.toRlpBytes();
  }

  // LogTopics methods
  function getField(LogTopics memory topics, uint256 index) internal pure returns (RLPReader.RLPItem memory) {
    return topics.data[index];
  }
}

// SPDX-License-Identifier: MIT
// https://github.com/fx-portal/contracts/blob/main/contracts/lib/Merkle.sol
pragma solidity 0.8.17;

library Merkle {
  function checkMembership(
    bytes32 leaf,
    uint256 index,
    bytes32 rootHash,
    bytes memory proof
  ) internal pure returns (bool) {
    require(proof.length % 32 == 0, "Invalid proof length");
    uint256 proofHeight = proof.length / 32;
    // Proof of size n means, height of the tree is n+1.
    // In a tree of height n+1, max #leafs possible is 2 ^ n
    require(index < 2**proofHeight, "Leaf index is too big");

    bytes32 proofElement;
    bytes32 computedHash = leaf;
    for (uint256 i = 32; i <= proof.length; i += 32) {
      assembly {
        proofElement := mload(add(proof, i))
      }

      if (index % 2 == 0) {
        computedHash = keccak256(abi.encodePacked(computedHash, proofElement));
      } else {
        computedHash = keccak256(abi.encodePacked(proofElement, computedHash));
      }

      index = index / 2;
    }
    return computedHash == rootHash;
  }
}

// SPDX-License-Identifier: MIT
// https://github.com/fx-portal/contracts/blob/main/contracts/lib/MerklePatriciaProof.sol
pragma solidity 0.8.17;

import {RLPReader} from "./RLPReader.sol";

library MerklePatriciaProof {
  /*
   * @dev Verifies a merkle patricia proof.
   * @param value The terminating value in the trie.
   * @param encodedPath The path in the trie leading to value.
   * @param rlpParentNodes The rlp encoded stack of nodes.
   * @param root The root hash of the trie.
   * @return The boolean validity of the proof.
   */
  function verify(
    bytes memory value,
    bytes memory encodedPath,
    bytes memory rlpParentNodes,
    bytes32 root
  ) internal pure returns (bool) {
    RLPReader.RLPItem memory item = RLPReader.toRlpItem(rlpParentNodes);
    RLPReader.RLPItem[] memory parentNodes = RLPReader.toList(item);

    bytes memory currentNode;
    RLPReader.RLPItem[] memory currentNodeList;

    bytes32 nodeKey = root;
    uint256 pathPtr = 0;

    bytes memory path = _getNibbleArray(encodedPath);
    if (path.length == 0) {
      return false;
    }

    for (uint256 i = 0; i < parentNodes.length; i++) {
      if (pathPtr > path.length) {
        return false;
      }

      currentNode = RLPReader.toRlpBytes(parentNodes[i]);
      if (nodeKey != keccak256(currentNode)) {
        return false;
      }
      currentNodeList = RLPReader.toList(parentNodes[i]);

      if (currentNodeList.length == 17) {
        if (pathPtr == path.length) {
          if (keccak256(RLPReader.toBytes(currentNodeList[16])) == keccak256(value)) {
            return true;
          } else {
            return false;
          }
        }

        uint8 nextPathNibble = uint8(path[pathPtr]);
        if (nextPathNibble > 16) {
          return false;
        }
        nodeKey = bytes32(RLPReader.toUintStrict(currentNodeList[nextPathNibble]));
        pathPtr += 1;
      } else if (currentNodeList.length == 2) {
        uint256 traversed = _nibblesToTraverse(RLPReader.toBytes(currentNodeList[0]), path, pathPtr);
        if (pathPtr + traversed == path.length) {
          //leaf node
          if (keccak256(RLPReader.toBytes(currentNodeList[1])) == keccak256(value)) {
            return true;
          } else {
            return false;
          }
        }

        //extension node
        if (traversed == 0) {
          return false;
        }

        pathPtr += traversed;
        nodeKey = bytes32(RLPReader.toUintStrict(currentNodeList[1]));
      } else {
        return false;
      }
    }
  }

  function _nibblesToTraverse(
    bytes memory encodedPartialPath,
    bytes memory path,
    uint256 pathPtr
  ) private pure returns (uint256) {
    uint256 len = 0;
    // encodedPartialPath has elements that are each two hex characters (1 byte), but partialPath
    // and slicedPath have elements that are each one hex character (1 nibble)
    bytes memory partialPath = _getNibbleArray(encodedPartialPath);
    bytes memory slicedPath = new bytes(partialPath.length);

    // pathPtr counts nibbles in path
    // partialPath.length is a number of nibbles
    for (uint256 i = pathPtr; i < pathPtr + partialPath.length; i++) {
      bytes1 pathNibble = path[i];
      slicedPath[i - pathPtr] = pathNibble;
    }

    if (keccak256(partialPath) == keccak256(slicedPath)) {
      len = partialPath.length;
    } else {
      len = 0;
    }
    return len;
  }

  // bytes b must be hp encoded
  function _getNibbleArray(bytes memory b) internal pure returns (bytes memory) {
    bytes memory nibbles = "";
    if (b.length > 0) {
      uint8 offset;
      uint8 hpNibble = uint8(_getNthNibbleOfBytes(0, b));
      if (hpNibble == 1 || hpNibble == 3) {
        nibbles = new bytes(b.length * 2 - 1);
        bytes1 oddNibble = _getNthNibbleOfBytes(1, b);
        nibbles[0] = oddNibble;
        offset = 1;
      } else {
        nibbles = new bytes(b.length * 2 - 2);
        offset = 0;
      }

      for (uint256 i = offset; i < nibbles.length; i++) {
        nibbles[i] = _getNthNibbleOfBytes(i - offset + 2, b);
      }
    }
    return nibbles;
  }

  function _getNthNibbleOfBytes(uint256 n, bytes memory str) private pure returns (bytes1) {
    return bytes1(n % 2 == 0 ? uint8(str[n / 2]) / 0x10 : uint8(str[n / 2]) % 0x10);
  }
}

// SPDX-License-Identifier: MIT
// https://github.com/fx-portal/contracts/blob/main/contracts/lib/RLPReader.sol
pragma solidity 0.8.17;

library RLPReader {
  uint8 constant STRING_SHORT_START = 0x80;
  uint8 constant STRING_LONG_START = 0xb8;
  uint8 constant LIST_SHORT_START = 0xc0;
  uint8 constant LIST_LONG_START = 0xf8;
  uint8 constant WORD_SIZE = 32;

  struct RLPItem {
    uint256 len;
    uint256 memPtr;
  }

  struct Iterator {
    RLPItem item; // Item that's being iterated over.
    uint256 nextPtr; // Position of the next item in the list.
  }

  /*
   * @dev Returns the next element in the iteration. Reverts if it has not next element.
   * @param self The iterator.
   * @return The next element in the iteration.
   */
  function next(Iterator memory self) internal pure returns (RLPItem memory) {
    require(hasNext(self));

    uint256 ptr = self.nextPtr;
    uint256 itemLength = _itemLength(ptr);
    self.nextPtr = ptr + itemLength;

    return RLPItem(itemLength, ptr);
  }

  /*
   * @dev Returns true if the iteration has more elements.
   * @param self The iterator.
   * @return true if the iteration has more elements.
   */
  function hasNext(Iterator memory self) internal pure returns (bool) {
    RLPItem memory item = self.item;
    return self.nextPtr < item.memPtr + item.len;
  }

  /*
   * @param item RLP encoded bytes
   */
  function toRlpItem(bytes memory item) internal pure returns (RLPItem memory) {
    uint256 memPtr;
    assembly {
      memPtr := add(item, 0x20)
    }

    return RLPItem(item.length, memPtr);
  }

  /*
   * @dev Create an iterator. Reverts if item is not a list.
   * @param self The RLP item.
   * @return An 'Iterator' over the item.
   */
  function iterator(RLPItem memory self) internal pure returns (Iterator memory) {
    require(isList(self));

    uint256 ptr = self.memPtr + _payloadOffset(self.memPtr);
    return Iterator(self, ptr);
  }

  /*
   * @param item RLP encoded bytes
   */
  function rlpLen(RLPItem memory item) internal pure returns (uint256) {
    return item.len;
  }

  /*
   * @param item RLP encoded bytes
   */
  function payloadLen(RLPItem memory item) internal pure returns (uint256) {
    return item.len - _payloadOffset(item.memPtr);
  }

  /*
   * @param item RLP encoded list in bytes
   */
  function toList(RLPItem memory item) internal pure returns (RLPItem[] memory) {
    require(isList(item));

    uint256 items = numItems(item);
    RLPItem[] memory result = new RLPItem[](items);

    uint256 memPtr = item.memPtr + _payloadOffset(item.memPtr);
    uint256 dataLen;
    for (uint256 i = 0; i < items; i++) {
      dataLen = _itemLength(memPtr);
      result[i] = RLPItem(dataLen, memPtr);
      memPtr = memPtr + dataLen;
    }

    return result;
  }

  // @return indicator whether encoded payload is a list. negate this function call for isData.
  function isList(RLPItem memory item) internal pure returns (bool) {
    if (item.len == 0) return false;

    uint8 byte0;
    uint256 memPtr = item.memPtr;
    assembly {
      byte0 := byte(0, mload(memPtr))
    }

    if (byte0 < LIST_SHORT_START) return false;
    return true;
  }

  /*
   * @dev A cheaper version of keccak256(toRlpBytes(item)) that avoids copying memory.
   * @return keccak256 hash of RLP encoded bytes.
   */
  function rlpBytesKeccak256(RLPItem memory item) internal pure returns (bytes32) {
    uint256 ptr = item.memPtr;
    uint256 len = item.len;
    bytes32 result;
    assembly {
      result := keccak256(ptr, len)
    }
    return result;
  }

  function payloadLocation(RLPItem memory item) internal pure returns (uint256, uint256) {
    uint256 offset = _payloadOffset(item.memPtr);
    uint256 memPtr = item.memPtr + offset;
    uint256 len = item.len - offset; // data length
    return (memPtr, len);
  }

  /*
   * @dev A cheaper version of keccak256(toBytes(item)) that avoids copying memory.
   * @return keccak256 hash of the item payload.
   */
  function payloadKeccak256(RLPItem memory item) internal pure returns (bytes32) {
    (uint256 memPtr, uint256 len) = payloadLocation(item);
    bytes32 result;
    assembly {
      result := keccak256(memPtr, len)
    }
    return result;
  }

  /** RLPItem conversions into data types **/

  // @returns raw rlp encoding in bytes
  function toRlpBytes(RLPItem memory item) internal pure returns (bytes memory) {
    bytes memory result = new bytes(item.len);
    if (result.length == 0) return result;

    uint256 ptr;
    assembly {
      ptr := add(0x20, result)
    }

    copy(item.memPtr, ptr, item.len);
    return result;
  }

  // any non-zero byte is considered true
  function toBoolean(RLPItem memory item) internal pure returns (bool) {
    require(item.len == 1);
    uint256 result;
    uint256 memPtr = item.memPtr;
    assembly {
      result := byte(0, mload(memPtr))
    }

    return result == 0 ? false : true;
  }

  function toAddress(RLPItem memory item) internal pure returns (address) {
    // 1 byte for the length prefix
    require(item.len == 21);

    return address(uint160(toUint(item)));
  }

  function toUint(RLPItem memory item) internal pure returns (uint256) {
    require(item.len > 0 && item.len <= 33);

    uint256 offset = _payloadOffset(item.memPtr);
    uint256 len = item.len - offset;

    uint256 result;
    uint256 memPtr = item.memPtr + offset;
    assembly {
      result := mload(memPtr)

      // shfit to the correct location if neccesary
      if lt(len, 32) {
        result := div(result, exp(256, sub(32, len)))
      }
    }

    return result;
  }

  // enforces 32 byte length
  function toUintStrict(RLPItem memory item) internal pure returns (uint256) {
    // one byte prefix
    require(item.len == 33);

    uint256 result;
    uint256 memPtr = item.memPtr + 1;
    assembly {
      result := mload(memPtr)
    }

    return result;
  }

  function toBytes(RLPItem memory item) internal pure returns (bytes memory) {
    require(item.len > 0);

    uint256 offset = _payloadOffset(item.memPtr);
    uint256 len = item.len - offset; // data length
    bytes memory result = new bytes(len);

    uint256 destPtr;
    assembly {
      destPtr := add(0x20, result)
    }

    copy(item.memPtr + offset, destPtr, len);
    return result;
  }

  /*
   * Private Helpers
   */

  // @return number of payload items inside an encoded list.
  function numItems(RLPItem memory item) private pure returns (uint256) {
    if (item.len == 0) return 0;

    uint256 count = 0;
    uint256 currPtr = item.memPtr + _payloadOffset(item.memPtr);
    uint256 endPtr = item.memPtr + item.len;
    while (currPtr < endPtr) {
      currPtr = currPtr + _itemLength(currPtr); // skip over an item
      count++;
    }

    return count;
  }

  // @return entire rlp item byte length
  function _itemLength(uint256 memPtr) private pure returns (uint256) {
    uint256 itemLen;
    uint256 byte0;
    assembly {
      byte0 := byte(0, mload(memPtr))
    }

    if (byte0 < STRING_SHORT_START) itemLen = 1;
    else if (byte0 < STRING_LONG_START) itemLen = byte0 - STRING_SHORT_START + 1;
    else if (byte0 < LIST_SHORT_START) {
      assembly {
        let byteLen := sub(byte0, 0xb7) // # of bytes the actual length is
        memPtr := add(memPtr, 1) // skip over the first byte
        /* 32 byte word size */
        let dataLen := div(mload(memPtr), exp(256, sub(32, byteLen))) // right shifting to get the len
        itemLen := add(dataLen, add(byteLen, 1))
      }
    } else if (byte0 < LIST_LONG_START) {
      itemLen = byte0 - LIST_SHORT_START + 1;
    } else {
      assembly {
        let byteLen := sub(byte0, 0xf7)
        memPtr := add(memPtr, 1)

        let dataLen := div(mload(memPtr), exp(256, sub(32, byteLen))) // right shifting to the correct length
        itemLen := add(dataLen, add(byteLen, 1))
      }
    }

    return itemLen;
  }

  // @return number of bytes until the data
  function _payloadOffset(uint256 memPtr) private pure returns (uint256) {
    uint256 byte0;
    assembly {
      byte0 := byte(0, mload(memPtr))
    }

    if (byte0 < STRING_SHORT_START) return 0;
    else if (byte0 < STRING_LONG_START || (byte0 >= LIST_SHORT_START && byte0 < LIST_LONG_START)) return 1;
    else if (byte0 < LIST_SHORT_START)
      // being explicit
      return byte0 - (STRING_LONG_START - 1) + 1;
    else return byte0 - (LIST_LONG_START - 1) + 1;
  }

  /*
   * @param src Pointer to source
   * @param dest Pointer to destination
   * @param len Amount of memory to copy from the source
   */
  function copy(
    uint256 src,
    uint256 dest,
    uint256 len
  ) private pure {
    if (len == 0) return;

    // copy as many word sizes as possible
    for (; len >= WORD_SIZE; len -= WORD_SIZE) {
      assembly {
        mstore(dest, mload(src))
      }

      src += WORD_SIZE;
      dest += WORD_SIZE;
    }

    if (len == 0) return;

    // left over bytes. Mask is used to remove unwanted bytes from the word
    uint256 mask = 256**(WORD_SIZE - len) - 1;

    assembly {
      let srcpart := and(mload(src), not(mask)) // zero out src
      let destpart := and(mload(dest), mask) // retrieve the bytes
      mstore(dest, or(destpart, srcpart))
    }
  }
}

// SPDX-License-Identifier: MIT
// https://github.com/fx-portal/contracts/blob/main/contracts/tunnel/FxBaseRootTunnel.sol
pragma solidity 0.8.17;

import {RLPReader} from "../lib/RLPReader.sol";
import {MerklePatriciaProof} from "../lib/MerklePatriciaProof.sol";
import {Merkle} from "../lib/Merkle.sol";
import "../lib/ExitPayloadReader.sol";

interface IFxStateSender {
  function sendMessageToChild(address _receiver, bytes calldata _data) external;
}

contract ICheckpointManager {
  struct HeaderBlock {
    bytes32 root;
    uint256 start;
    uint256 end;
    uint256 createdAt;
    address proposer;
  }

  /**
   * @notice mapping of checkpoint header numbers to block details
   * @dev These checkpoints are submited by plasma contracts
   */
  mapping(uint256 => HeaderBlock) public headerBlocks;
}

abstract contract FxBaseRootTunnel {
  using RLPReader for RLPReader.RLPItem;
  using Merkle for bytes32;
  using ExitPayloadReader for bytes;
  using ExitPayloadReader for ExitPayloadReader.ExitPayload;
  using ExitPayloadReader for ExitPayloadReader.Log;
  using ExitPayloadReader for ExitPayloadReader.LogTopics;
  using ExitPayloadReader for ExitPayloadReader.Receipt;

  // keccak256(MessageSent(bytes))
  bytes32 public constant SEND_MESSAGE_EVENT_SIG = 0x8c5261668696ce22758910d05bab8f186d6eb247ceac2af2e82c7dc17669b036;

  // state sender contract
  IFxStateSender public fxRoot;
  // root chain manager
  ICheckpointManager public checkpointManager;
  // child tunnel contract which receives and sends messages
  address public fxChildTunnel;

  // storage to avoid duplicate exits
  mapping(bytes32 => bool) public processedExits;

  constructor(address _checkpointManager, address _fxRoot) {
    checkpointManager = ICheckpointManager(_checkpointManager);
    fxRoot = IFxStateSender(_fxRoot);
  }

  // set fxChildTunnel if not set already
  function setFxChildTunnel(address _fxChildTunnel) public virtual {
    require(fxChildTunnel == address(0x0), "FxBaseRootTunnel: CHILD_TUNNEL_ALREADY_SET");
    fxChildTunnel = _fxChildTunnel;
  }

  /**
   * @notice Send bytes message to Child Tunnel
   * @param message bytes message that will be sent to Child Tunnel
   * some message examples -
   *   abi.encode(tokenId);
   *   abi.encode(tokenId, tokenMetadata);
   *   abi.encode(messageType, messageData);
   */
  function _sendMessageToChild(bytes memory message) internal {
    fxRoot.sendMessageToChild(fxChildTunnel, message);
  }

  function _validateAndExtractMessage(bytes memory inputData) internal returns (bytes memory) {
    ExitPayloadReader.ExitPayload memory payload = inputData.toExitPayload();

    bytes memory branchMaskBytes = payload.getBranchMaskAsBytes();
    uint256 blockNumber = payload.getBlockNumber();
    // checking if exit has already been processed
    // unique exit is identified using hash of (blockNumber, branchMask, receiptLogIndex)
    bytes32 exitHash = keccak256(
      abi.encodePacked(
        blockNumber,
        // first 2 nibbles are dropped while generating nibble array
        // this allows branch masks that are valid but bypass exitHash check (changing first 2 nibbles only)
        // so converting to nibble array and then hashing it
        MerklePatriciaProof._getNibbleArray(branchMaskBytes),
        payload.getReceiptLogIndex()
      )
    );
    require(processedExits[exitHash] == false, "FxRootTunnel: EXIT_ALREADY_PROCESSED");
    processedExits[exitHash] = true;

    ExitPayloadReader.Receipt memory receipt = payload.getReceipt();
    ExitPayloadReader.Log memory log = receipt.getLog();

    // check child tunnel
    require(fxChildTunnel == log.getEmitter(), "FxRootTunnel: INVALID_FX_CHILD_TUNNEL");

    bytes32 receiptRoot = payload.getReceiptRoot();
    // verify receipt inclusion
    require(
      MerklePatriciaProof.verify(receipt.toBytes(), branchMaskBytes, payload.getReceiptProof(), receiptRoot),
      "FxRootTunnel: INVALID_RECEIPT_PROOF"
    );

    // verify checkpoint inclusion
    _checkBlockMembershipInCheckpoint(
      blockNumber,
      payload.getBlockTime(),
      payload.getTxRoot(),
      receiptRoot,
      payload.getHeaderNumber(),
      payload.getBlockProof()
    );

    ExitPayloadReader.LogTopics memory topics = log.getTopics();

    require(
      bytes32(topics.getField(0).toUint()) == SEND_MESSAGE_EVENT_SIG, // topic0 is event sig
      "FxRootTunnel: INVALID_SIGNATURE"
    );

    // received message data
    bytes memory message = abi.decode(log.getData(), (bytes)); // event decodes params again, so decoding bytes to get message
    return message;
  }

  function _checkBlockMembershipInCheckpoint(
    uint256 blockNumber,
    uint256 blockTime,
    bytes32 txRoot,
    bytes32 receiptRoot,
    uint256 headerNumber,
    bytes memory blockProof
  ) private view returns (uint256) {
    (bytes32 headerRoot, uint256 startBlock, , uint256 createdAt, ) = checkpointManager.headerBlocks(headerNumber);

    require(
      keccak256(abi.encodePacked(blockNumber, blockTime, txRoot, receiptRoot)).checkMembership(
        blockNumber - startBlock,
        headerRoot,
        blockProof
      ),
      "FxRootTunnel: INVALID_HEADER"
    );
    return createdAt;
  }

  /**
   * @notice receive message from  L2 to L1, validated by proof
   * @dev This function verifies if the transaction actually happened on child chain
   *
   * @param inputData RLP encoded data of the reference tx containing following list of fields
   *  0 - headerNumber - Checkpoint header block number containing the reference tx
   *  1 - blockProof - Proof that the block header (in the child chain) is a leaf in the submitted merkle root
   *  2 - blockNumber - Block number containing the reference tx on child chain
   *  3 - blockTime - Reference tx block time
   *  4 - txRoot - Transactions root of block
   *  5 - receiptRoot - Receipts root of block
   *  6 - receipt - Receipt of the reference transaction
   *  7 - receiptProof - Merkle proof of the reference receipt
   *  8 - branchMask - 32 bits denoting the path of receipt in merkle tree
   *  9 - receiptLogIndex - Log Index to read from the receipt
   */
  function receiveMessage(bytes memory inputData) public virtual {
    bytes memory message = _validateAndExtractMessage(inputData);
    _processMessageFromChild(message);
  }

  /**
   * @notice Process message received from Child Tunnel
   * @dev function needs to be implemented to handle message as per requirement
   * This is called by onStateReceive function.
   * Since it is called via a system call, any event will not be emitted during its execution.
   * @param message bytes message that was sent from Child Tunnel
   */
  function _processMessageFromChild(bytes memory message) internal virtual;
}

// SPDX-License-Identifier: MIT OR Apache-2.0
pragma solidity 0.8.17;

import {IProposedOwnable} from "../../shared/interfaces/IProposedOwnable.sol";

/**
 * @notice This interface is what the Connext contract will send and receive messages through.
 * The messaging layer should conform to this interface, and should be interchangeable (i.e.
 * could be Nomad or a generic AMB under the hood).
 *
 * @dev This uses the nomad format to ensure nomad can be added in as it comes back online.
 *
 * Flow from transfer from polygon to optimism:
 * 1. User calls `xcall` with destination specified
 * 2. This will swap in to the bridge assets
 * 3. The swapped assets will get burned
 * 4. The Connext contract will call `dispatch` on the messaging contract to add the transfer
 *    to the root
 * 5. [At some time interval] Relayers call `send` to send the current root from polygon to
 *    mainnet. This is done on all "spoke" domains.
 * 6. [At some time interval] Relayers call `propagate` [better name] on mainnet, this generates a new merkle
 *    root from all of the AMBs
 *    - This function must be able to read root data from all AMBs and aggregate them into a single merkle
 *      tree root
 *    - Will send the mixed root from all chains back through the respective AMBs to all other chains
 * 7. AMB will call `update` to update the latest root on the messaging contract on spoke domains
 * 8. [At any point] Relayers can call `proveAndProcess` to prove inclusion of dispatched message, and call
 *    process on the `Connext` contract
 * 9. Takes minted bridge tokens and credits the LP
 *
 * AMB requirements:
 * - Access `msg.sender` both from mainnet -> spoke and vice versa
 * - Ability to read *our root* from the AMB
 *
 * AMBs:
 * - PoS bridge from polygon
 * - arbitrum bridge
 * - optimism bridge
 * - gnosis chain
 * - bsc (use multichain for messaging)
 */
interface IConnector is IProposedOwnable {
  // ============ Events ============
  /**
   * @notice Emitted whenever a message is successfully sent over an AMB
   * @param data The contents of the message
   * @param encodedData Data used to send the message; specific to connector
   * @param caller Who called the function (sent the message)
   */
  event MessageSent(bytes data, bytes encodedData, address caller);

  /**
   * @notice Emitted whenever a message is successfully received over an AMB
   * @param data The contents of the message
   * @param caller Who called the function
   */
  event MessageProcessed(bytes data, address caller);

  // ============ Public fns ============

  function processMessage(bytes memory _data) external;

  function verifySender(address _expected) external returns (bool);
}

// SPDX-License-Identifier: MIT OR Apache-2.0
pragma solidity 0.8.17;

interface IRootManager {
  /**
   * @notice This is called by relayers to generate + send the mixed root from mainnet via AMB to
   * spoke domains.
   * @dev This must read information for the root from the registered AMBs.
   */
  function propagate(
    address[] calldata _connectors,
    uint256[] calldata _fees,
    bytes[] memory _encodedData
  ) external payable;

  /**
   * @notice Called by the connectors for various domains on the hub to aggregate their latest
   * inbound root.
   * @dev This must read information for the root from the registered AMBs
   */
  function aggregate(uint32 _domain, bytes32 _outbound) external;
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.17;

import {IProposedOwnable} from "./interfaces/IProposedOwnable.sol";

/**
 * @title ProposedOwnable
 * @notice Contract module which provides a basic access control mechanism,
 * where there is an account (an owner) that can be granted exclusive access to
 * specific functions.
 *
 * By default, the owner account will be the one that deploys the contract. This
 * can later be changed via a two step process:
 * 1. Call `proposeOwner`
 * 2. Wait out the delay period
 * 3. Call `acceptOwner`
 *
 * @dev This module is used through inheritance. It will make available the
 * modifier `onlyOwner`, which can be applied to your functions to restrict
 * their use to the owner.
 *
 * @dev The majority of this code was taken from the openzeppelin Ownable
 * contract
 *
 */
abstract contract ProposedOwnable is IProposedOwnable {
  // ========== Custom Errors ===========

  error ProposedOwnable__onlyOwner_notOwner();
  error ProposedOwnable__onlyProposed_notProposedOwner();
  error ProposedOwnable__proposeNewOwner_invalidProposal();
  error ProposedOwnable__proposeNewOwner_noOwnershipChange();
  error ProposedOwnable__renounceOwnership_noProposal();
  error ProposedOwnable__renounceOwnership_delayNotElapsed();
  error ProposedOwnable__renounceOwnership_invalidProposal();
  error ProposedOwnable__acceptProposedOwner_delayNotElapsed();

  // ============ Properties ============

  address private _owner;

  address private _proposed;
  uint256 private _proposedOwnershipTimestamp;

  uint256 private constant _delay = 7 days;

  // ======== Getters =========

  /**
   * @notice Returns the address of the current owner.
   */
  function owner() public view virtual returns (address) {
    return _owner;
  }

  /**
   * @notice Returns the address of the proposed owner.
   */
  function proposed() public view virtual returns (address) {
    return _proposed;
  }

  /**
   * @notice Returns the address of the proposed owner.
   */
  function proposedTimestamp() public view virtual returns (uint256) {
    return _proposedOwnershipTimestamp;
  }

  /**
   * @notice Returns the delay period before a new owner can be accepted.
   */
  function delay() public view virtual returns (uint256) {
    return _delay;
  }

  /**
   * @notice Throws if called by any account other than the owner.
   */
  modifier onlyOwner() {
    if (_owner != msg.sender) revert ProposedOwnable__onlyOwner_notOwner();
    _;
  }

  /**
   * @notice Throws if called by any account other than the proposed owner.
   */
  modifier onlyProposed() {
    if (_proposed != msg.sender) revert ProposedOwnable__onlyProposed_notProposedOwner();
    _;
  }

  /**
   * @notice Indicates if the ownership has been renounced() by
   * checking if current owner is address(0)
   */
  function renounced() public view returns (bool) {
    return _owner == address(0);
  }

  // ======== External =========

  /**
   * @notice Sets the timestamp for an owner to be proposed, and sets the
   * newly proposed owner as step 1 in a 2-step process
   */
  function proposeNewOwner(address newlyProposed) public virtual onlyOwner {
    // Contract as source of truth
    if (_proposed == newlyProposed && newlyProposed != address(0))
      revert ProposedOwnable__proposeNewOwner_invalidProposal();

    // Sanity check: reasonable proposal
    if (_owner == newlyProposed) revert ProposedOwnable__proposeNewOwner_noOwnershipChange();

    _setProposed(newlyProposed);
  }

  /**
   * @notice Renounces ownership of the contract after a delay
   */
  function renounceOwnership() public virtual onlyOwner {
    // Ensure there has been a proposal cycle started
    if (_proposedOwnershipTimestamp == 0) revert ProposedOwnable__renounceOwnership_noProposal();

    // Ensure delay has elapsed
    if ((block.timestamp - _proposedOwnershipTimestamp) <= _delay)
      revert ProposedOwnable__renounceOwnership_delayNotElapsed();

    // Require proposed is set to 0
    if (_proposed != address(0)) revert ProposedOwnable__renounceOwnership_invalidProposal();

    // Emit event, set new owner, reset timestamp
    _setOwner(_proposed);
  }

  /**
   * @notice Transfers ownership of the contract to a new account (`newOwner`).
   * Can only be called by the current owner.
   */
  function acceptProposedOwner() public virtual onlyProposed {
    // NOTE: no need to check if _owner == _proposed, because the _proposed
    // is 0-d out and this check is implicitly enforced by modifier

    // NOTE: no need to check if _proposedOwnershipTimestamp > 0 because
    // the only time this would happen is if the _proposed was never
    // set (will fail from modifier) or if the owner == _proposed (checked
    // above)

    // Ensure delay has elapsed
    if ((block.timestamp - _proposedOwnershipTimestamp) <= _delay)
      revert ProposedOwnable__acceptProposedOwner_delayNotElapsed();

    // Emit event, set new owner, reset timestamp
    _setOwner(_proposed);
  }

  // ======== Internal =========

  function _setOwner(address newOwner) internal {
    address oldOwner = _owner;
    _owner = newOwner;
    _proposedOwnershipTimestamp = 0;
    _proposed = address(0);
    emit OwnershipTransferred(oldOwner, newOwner);
  }

  function _setProposed(address newlyProposed) private {
    _proposedOwnershipTimestamp = block.timestamp;
    _proposed = newlyProposed;
    emit OwnershipProposed(newlyProposed);
  }
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

/**
 * @title IProposedOwnable
 * @notice Defines a minimal interface for ownership with a two step proposal and acceptance
 * process
 */
interface IProposedOwnable {
  /**
   * @dev This emits when change in ownership of a contract is proposed.
   */
  event OwnershipProposed(address indexed proposedOwner);

  /**
   * @dev This emits when ownership of a contract changes.
   */
  event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

  /**
   * @notice Get the address of the owner
   * @return owner_ The address of the owner.
   */
  function owner() external view returns (address owner_);

  /**
   * @notice Get the address of the proposed owner
   * @return proposed_ The address of the proposed.
   */
  function proposed() external view returns (address proposed_);

  /**
   * @notice Set the address of the proposed owner of the contract
   * @param newlyProposed The proposed new owner of the contract
   */
  function proposeNewOwner(address newlyProposed) external;

  /**
   * @notice Set the address of the proposed owner of the contract
   */
  function acceptProposedOwner() external;
}