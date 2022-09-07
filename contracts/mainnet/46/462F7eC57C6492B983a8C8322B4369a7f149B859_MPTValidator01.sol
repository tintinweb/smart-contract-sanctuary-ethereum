// SPDX-License-Identifier: BUSL-1.1

pragma solidity 0.7.6;
pragma abicoder v2;

import "./utility/LayerZeroPacket.sol";
import "./utility/UltraLightNodeEVMDecoder.sol";
import "../interfaces/IValidationLibraryHelperV2.sol";
import "../interfaces/ILayerZeroValidationLibrary.sol";

interface IStargate {
    // Stargate objects for abi encoding / decoding
    struct SwapObj {
        uint amount;
        uint eqFee;
        uint eqReward;
        uint lpFee;
        uint protocolFee;
        uint lkbRemove;
    }

    struct CreditObj {
        uint credits;
        uint idealBalance;
    }
}

contract MPTValidator01 is ILayerZeroValidationLibrary, IValidationLibraryHelperV2 {
    using RLPDecode for RLPDecode.RLPItem;
    using RLPDecode for RLPDecode.Iterator;

    uint8 public proofType = 1;
    uint8 public utilsVersion = 4;
    bytes32 public constant PACKET_SIGNATURE = 0xe9bded5f24a4168e4f3bf44e00298c993b22376aad8c58c7dda9718a54cbea82;

    address public immutable stargateBridgeAddress;
    address public immutable stargateTokenAddress;

    constructor(address _stargateBridgeAddress, address _stargateTokenAddress) {
        stargateBridgeAddress = _stargateBridgeAddress;
        stargateTokenAddress = _stargateTokenAddress;
    }

    function validateProof(bytes32 _receiptsRoot, bytes calldata _transactionProof, uint _remoteAddressSize) external view override returns (LayerZeroPacket.Packet memory packet) {
        require(_remoteAddressSize > 0, "ProofLib: invalid address size");
        (bytes[] memory proof, uint[] memory receiptSlotIndex, uint logIndex) = abi.decode(_transactionProof, (bytes[], uint[], uint));

        ULNLog memory log = _getVerifiedLog(_receiptsRoot, receiptSlotIndex, logIndex, proof);
        require(log.topicZeroSig == PACKET_SIGNATURE, "ProofLib: packet not recognized"); //data

        packet = LayerZeroPacket.getPacketV2(log.data, _remoteAddressSize, log.contractAddress);

        if (packet.dstAddress == stargateBridgeAddress) packet.payload = _secureStgPayload(packet.payload);

        if (packet.dstAddress == stargateTokenAddress) packet.payload = _secureStgTokenPayload(packet.payload);

        return packet;
    }

    function _secureStgTokenPayload(bytes memory _payload) internal pure returns (bytes memory) {
        (bytes memory toAddressBytes, uint qty) = abi.decode(_payload, (bytes, uint));

        address toAddress = address(0);
        if (toAddressBytes.length > 0) {
            assembly {
                toAddress := mload(add(toAddressBytes, 20))
            }
        }

        if (toAddress == address(0)) {
            address deadAddress = address(0x000000000000000000000000000000000000dEaD);
            bytes memory newToAddressBytes = abi.encodePacked(deadAddress);
            return abi.encode(newToAddressBytes, qty);
        }

        // default to return the original payload
        return _payload;
    }

    function _secureStgPayload(bytes memory _payload) internal view returns (bytes memory) {
        // functionType is uint8 even though the encoding will take up the side of uint256
        uint8 functionType;
        assembly {
            functionType := mload(add(_payload, 32))
        }

        // TYPE_SWAP_REMOTE == 1 && only if the payload has a payload
        // only swapRemote inside of stargate can call sgReceive on an user supplied to address
        // thus we do not care about the other type functions even if the toAddress is overly long.
        if (functionType == 1) {
            // decode the _payload with its types
            (, uint srcPoolId, uint dstPoolId, uint dstGasForCall, IStargate.CreditObj memory c, IStargate.SwapObj memory s, bytes memory toAddressBytes, bytes memory contractCallPayload) = abi.decode(_payload, (uint8, uint, uint, uint, IStargate.CreditObj, IStargate.SwapObj, bytes, bytes));

            // if contractCallPayload.length > 0 need to check if the to address is a contract or not
            if (contractCallPayload.length > 0) {
                // otherwise, need to check if the payload can be delivered to the toAddress
                address toAddress = address(0);
                if (toAddressBytes.length > 0) {
                    assembly {
                        toAddress := mload(add(toAddressBytes, 20))
                    }
                }

                // check if the toAddress is a contract. We are not concerned about addresses that pretend to be wallets. because worst case we just delete their payload if being malicious
                // we can guarantee that if a size > 0, then the contract is definitely a contract address in this context
                uint size;
                assembly {
                    size := extcodesize(toAddress)
                }

                if (size == 0) {
                    // size == 0 indicates its not a contract, payload wont be delivered
                    // secure the _payload to make sure funds can be delivered to the toAddress
                    bytes memory newToAddressBytes = abi.encodePacked(toAddress);
                    bytes memory securePayload = abi.encode(functionType, srcPoolId, dstPoolId, dstGasForCall, c, s, newToAddressBytes, bytes(""));
                    return securePayload;
                }
            }
        }

        // default to return the original payload
        return _payload;
    }

    function secureStgTokenPayload(bytes memory _payload) external pure returns (bytes memory) {
        return _secureStgTokenPayload(_payload);
    }

    function secureStgPayload(bytes memory _payload) external view returns (bytes memory) {
        return _secureStgPayload(_payload);
    }

    function _getVerifiedLog(bytes32 hashRoot, uint[] memory paths, uint logIndex, bytes[] memory proof) internal pure returns (ULNLog memory) {
        require(paths.length == proof.length, "ProofLib: invalid proof size");
        require(proof.length > 0, "ProofLib: proof size must > 0");
        RLPDecode.RLPItem memory item;
        bytes memory proofBytes;

        for (uint i = 0; i < proof.length; i++) {
            proofBytes = proof[i];
            require(hashRoot == keccak256(proofBytes), "ProofLib: invalid hashlink");
            item = RLPDecode.toRlpItem(proofBytes).safeGetItemByIndex(paths[i]);
            if (i < proof.length - 1) hashRoot = bytes32(item.toUint());
        }

        // burning status + gasUsed + logBloom
        RLPDecode.RLPItem memory logItem = item.typeOffset().safeGetItemByIndex(3);
        RLPDecode.Iterator memory it = logItem.safeGetItemByIndex(logIndex).iterator();
        ULNLog memory log;
        log.contractAddress = bytes32(it.next().toUint());
        log.topicZeroSig = bytes32(it.next().safeGetItemByIndex(0).toUint());
        log.data = it.next().toBytes();

        return log;
    }

    function getUtilsVersion() external view override returns (uint8) {
        return utilsVersion;
    }

    function getProofType() external view override returns (uint8) {
        return proofType;
    }

    function getVerifyLog(bytes32 hashRoot, uint[] memory receiptSlotIndex, uint logIndex, bytes[] memory proof) external pure override returns (ULNLog memory) {
        return _getVerifiedLog(hashRoot, receiptSlotIndex, logIndex, proof);
    }

    function getPacket(bytes memory data, uint sizeOfSrcAddress, bytes32 ulnAddress) external pure override returns (LayerZeroPacket.Packet memory) {
        return LayerZeroPacket.getPacketV2(data, sizeOfSrcAddress, ulnAddress);
    }
}

// SPDX-License-Identifier: BUSL-1.1

pragma solidity 0.7.6;

import "./Buffer.sol";
import "@openzeppelin/contracts/math/SafeMath.sol";

library LayerZeroPacket {
    using Buffer for Buffer.buffer;
    using SafeMath for uint;

    struct Packet {
        uint16 srcChainId;
        uint16 dstChainId;
        uint64 nonce;
        address dstAddress;
        bytes srcAddress;
        bytes32 ulnAddress;
        bytes payload;
    }

    function getPacket(
        bytes memory data,
        uint16 srcChain,
        uint sizeOfSrcAddress,
        bytes32 ulnAddress
    ) internal pure returns (LayerZeroPacket.Packet memory) {
        uint16 dstChainId;
        address dstAddress;
        uint size;
        uint64 nonce;

        // The log consists of the destination chain id and then a bytes payload
        //      0--------------------------------------------31
        // 0   |  total bytes size
        // 32  |  destination chain id
        // 64  |  bytes offset
        // 96  |  bytes array size
        // 128 |  payload
        assembly {
            dstChainId := mload(add(data, 32))
            size := mload(add(data, 96)) /// size of the byte array
            nonce := mload(add(data, 104)) // offset to convert to uint64  128  is index -24
            dstAddress := mload(add(data, sub(add(128, sizeOfSrcAddress), 4))) // offset to convert to address 12 -8
        }

        Buffer.buffer memory srcAddressBuffer;
        srcAddressBuffer.init(sizeOfSrcAddress);
        srcAddressBuffer.writeRawBytes(0, data, 136, sizeOfSrcAddress); // 128 + 8

        uint payloadSize = size.sub(28).sub(sizeOfSrcAddress);
        Buffer.buffer memory payloadBuffer;
        payloadBuffer.init(payloadSize);
        payloadBuffer.writeRawBytes(0, data, sizeOfSrcAddress.add(156), payloadSize); // 148 + 8
        return LayerZeroPacket.Packet(srcChain, dstChainId, nonce, dstAddress, srcAddressBuffer.buf, ulnAddress, payloadBuffer.buf);
    }

    function getPacketV2(
        bytes memory data,
        uint sizeOfSrcAddress,
        bytes32 ulnAddress
    ) internal pure returns (LayerZeroPacket.Packet memory) {
        // packet def: abi.encodePacked(nonce, srcChain, srcAddress, dstChain, dstAddress, payload);
        // data def: abi.encode(packet) = offset(32) + length(32) + packet
        //              if from EVM
        // 0 - 31       0 - 31          |  total bytes size
        // 32 - 63      32 - 63         |  location
        // 64 - 95      64 - 95         |  size of the packet
        // 96 - 103     96 - 103        |  nonce
        // 104 - 105    104 - 105       |  srcChainId
        // 106 - P      106 - 125       |  srcAddress, where P = 106 + sizeOfSrcAddress - 1,
        // P+1 - P+2    126 - 127       |  dstChainId
        // P+3 - P+22   128 - 147       |  dstAddress
        // P+23 - END   148 - END       |  payload

        // decode the packet
        uint256 realSize;
        uint64 nonce;
        uint16 srcChain;
        uint16 dstChain;
        address dstAddress;
        assembly {
            realSize := mload(add(data, 64))
            nonce := mload(add(data, 72)) // 104 - 32
            srcChain := mload(add(data, 74)) // 106 - 32
            dstChain := mload(add(data, add(76, sizeOfSrcAddress))) // P + 3 - 32 = 105 + size + 3 - 32 = 76 + size
            dstAddress := mload(add(data, add(96, sizeOfSrcAddress))) // P + 23 - 32 = 105 + size + 23 - 32 = 96 + size
        }

        require(srcChain != 0, "LayerZeroPacket: invalid packet");

        Buffer.buffer memory srcAddressBuffer;
        srcAddressBuffer.init(sizeOfSrcAddress);
        srcAddressBuffer.writeRawBytes(0, data, 106, sizeOfSrcAddress);

        uint nonPayloadSize = sizeOfSrcAddress.add(32);// 2 + 2 + 8 + 20, 32 + 20 = 52 if sizeOfSrcAddress == 20
        uint payloadSize = realSize.sub(nonPayloadSize);
        Buffer.buffer memory payloadBuffer;
        payloadBuffer.init(payloadSize);
        payloadBuffer.writeRawBytes(0, data, nonPayloadSize.add(96), payloadSize);

        return LayerZeroPacket.Packet(srcChain, dstChain, nonce, dstAddress, srcAddressBuffer.buf, ulnAddress, payloadBuffer.buf);
    }

    function getPacketV3(
        bytes memory data,
        uint sizeOfSrcAddress,
        bytes32 ulnAddress
    ) internal pure returns (LayerZeroPacket.Packet memory) {
        // data def: abi.encodePacked(nonce, srcChain, srcAddress, dstChain, dstAddress, payload);
        //              if from EVM
        // 0 - 31       0 - 31          |  total bytes size
        // 32 - 39      32 - 39         |  nonce
        // 40 - 41      40 - 41         |  srcChainId
        // 42 - P       42 - 61         |  srcAddress, where P = 41 + sizeOfSrcAddress,
        // P+1 - P+2    62 - 63         |  dstChainId
        // P+3 - P+22   64 - 83         |  dstAddress
        // P+23 - END   84 - END        |  payload

        // decode the packet
        uint256 realSize = data.length;
        uint nonPayloadSize = sizeOfSrcAddress.add(32);// 2 + 2 + 8 + 20, 32 + 20 = 52 if sizeOfSrcAddress == 20
        require(realSize >= nonPayloadSize, "LayerZeroPacket: invalid packet");
        uint payloadSize = realSize - nonPayloadSize;

        uint64 nonce;
        uint16 srcChain;
        uint16 dstChain;
        address dstAddress;
        assembly {
            nonce := mload(add(data, 8)) // 40 - 32
            srcChain := mload(add(data, 10)) // 42 - 32
            dstChain := mload(add(data, add(12, sizeOfSrcAddress))) // P + 3 - 32 = 41 + size + 3 - 32 = 12 + size
            dstAddress := mload(add(data, add(32, sizeOfSrcAddress))) // P + 23 - 32 = 41 + size + 23 - 32 = 32 + size
        }

        require(srcChain != 0, "LayerZeroPacket: invalid packet");

        Buffer.buffer memory srcAddressBuffer;
        srcAddressBuffer.init(sizeOfSrcAddress);
        srcAddressBuffer.writeRawBytes(0, data, 42, sizeOfSrcAddress);

        Buffer.buffer memory payloadBuffer;
        if (payloadSize > 0) {
            payloadBuffer.init(payloadSize);
            payloadBuffer.writeRawBytes(0, data, nonPayloadSize.add(32), payloadSize);
        }

        return LayerZeroPacket.Packet(srcChain, dstChain, nonce, dstAddress, srcAddressBuffer.buf, ulnAddress, payloadBuffer.buf);
    }
}

// SPDX-License-Identifier: BUSL-1.1

pragma solidity ^0.7.0;
pragma abicoder v2;

import "./RLPDecode.sol";

library UltraLightNodeEVMDecoder {
    using RLPDecode for RLPDecode.RLPItem;
    using RLPDecode for RLPDecode.Iterator;

    struct Log {
        address contractAddress;
        bytes32 topicZero;
        bytes data;
    }

    function getReceiptLog(bytes memory data, uint logIndex) internal pure returns (Log memory) {
        RLPDecode.Iterator memory it = RLPDecode.toRlpItem(data).iterator();
        uint idx;
        while (it.hasNext()) {
            if (idx == 3) {
                return toReceiptLog(it.next().getItemByIndex(logIndex).toRlpBytes());
            } else it.next();
            idx++;
        }
        revert("no log index in receipt");
    }

    function toReceiptLog(bytes memory data) internal pure returns (Log memory) {
        RLPDecode.Iterator memory it = RLPDecode.toRlpItem(data).iterator();
        Log memory log;

        uint idx;
        while (it.hasNext()) {
            if (idx == 0) {
                log.contractAddress = it.next().toAddress();
            } else if (idx == 1) {
                RLPDecode.RLPItem memory item = it.next().getItemByIndex(0);
                log.topicZero = bytes32(item.toUint());
            } else if (idx == 2) log.data = it.next().toBytes();
            else it.next();
            idx++;
        }
        return log;
    }
}

// SPDX-License-Identifier: BUSL-1.1

pragma solidity >=0.7.0;
pragma abicoder v2;

import "../proof/utility/LayerZeroPacket.sol";

interface IValidationLibraryHelperV2 {
    struct ULNLog {
        bytes32 contractAddress;
        bytes32 topicZeroSig;
        bytes data;
    }

    function getVerifyLog(bytes32 hashRoot, uint[] calldata receiptSlotIndex, uint logIndex, bytes[] calldata proof) external pure returns (ULNLog memory);

    function getPacket(bytes calldata data, uint sizeOfSrcAddress, bytes32 ulnAddress) external pure returns (LayerZeroPacket.Packet memory);

    function getUtilsVersion() external view returns (uint8);

    function getProofType() external view returns (uint8);
}

// SPDX-License-Identifier: BUSL-1.1

pragma solidity >=0.7.0;
pragma abicoder v2;

import "../proof/utility/LayerZeroPacket.sol";

interface ILayerZeroValidationLibrary {
    function validateProof(bytes32 blockData, bytes calldata _data, uint _remoteAddressSize) external returns (LayerZeroPacket.Packet memory packet);
}

// SPDX-License-Identifier: BUSL-1.1

// https://github.com/ensdomains/buffer

pragma solidity ^0.7.0;

/**
 * @dev A library for working with mutable byte buffers in Solidity.
 *
 * Byte buffers are mutable and expandable, and provide a variety of primitives
 * for writing to them. At any time you can fetch a bytes object containing the
 * current contents of the buffer. The bytes object should not be stored between
 * operations, as it may change due to resizing of the buffer.
 */
library Buffer {
    /**
     * @dev Represents a mutable buffer. Buffers have a current value (buf) and
     *      a capacity. The capacity may be longer than the current value, in
     *      which case it can be extended without the need to allocate more memory.
     */
    struct buffer {
        bytes buf;
        uint capacity;
    }

    /**
     * @dev Initializes a buffer with an initial capacity.a co
     * @param buf The buffer to initialize.
     * @param capacity The number of bytes of space to allocate the buffer.
     * @return The buffer, for chaining.
     */
    function init(buffer memory buf, uint capacity) internal pure returns (buffer memory) {
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
     * @dev Writes a byte string to a buffer. Resizes if doing so would exceed
     *      the capacity of the buffer.
     * @param buf The buffer to append to.
     * @param off The start offset to write to.
     * @param rawData The data to append.
     * @param len The number of bytes to copy.
     * @return The original buffer, for chaining.
     */
    function writeRawBytes(
        buffer memory buf,
        uint off,
        bytes memory rawData,
        uint offData,
        uint len
    ) internal pure returns (buffer memory) {
        if (off + len > buf.capacity) {
            resize(buf, max(buf.capacity, len + off) * 2);
        }

        uint dest;
        uint src;
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
            src := add(rawData, offData)
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
        uint mask = 256**(32 - len) - 1;
        assembly {
            let srcpart := and(mload(src), not(mask))
            let destpart := and(mload(dest), mask)
            mstore(dest, or(destpart, srcpart))
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
    function write(buffer memory buf, uint off, bytes memory data, uint len) internal pure returns (buffer memory) {
        require(len <= data.length);

        if (off + len > buf.capacity) {
            resize(buf, max(buf.capacity, len + off) * 2);
        }

        uint dest;
        uint src;
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
        uint mask = 256**(32 - len) - 1;
        assembly {
            let srcpart := and(mload(src), not(mask))
            let destpart := and(mload(dest), mask)
            mstore(dest, or(destpart, srcpart))
        }

        return buf;
    }

    function append(buffer memory buf, bytes memory data) internal pure returns (buffer memory) {
        return write(buf, buf.buf.length, data, data.length);
    }

    function resize(buffer memory buf, uint capacity) private pure {
        bytes memory oldbuf = buf.buf;
        init(buf, capacity);
        append(buf, oldbuf);
    }

    function max(uint a, uint b) private pure returns (uint) {
        if (a > b) {
            return a;
        }
        return b;
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.7.0;

/**
 * @dev Wrappers over Solidity's arithmetic operations with added overflow
 * checks.
 *
 * Arithmetic operations in Solidity wrap on overflow. This can easily result
 * in bugs, because programmers usually assume that an overflow raises an
 * error, which is the standard behavior in high level programming languages.
 * `SafeMath` restores this intuition by reverting the transaction when an
 * operation overflows.
 *
 * Using this library instead of the unchecked operations eliminates an entire
 * class of bugs, so it's recommended to use it always.
 */
library SafeMath {
    /**
     * @dev Returns the addition of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function tryAdd(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        uint256 c = a + b;
        if (c < a) return (false, 0);
        return (true, c);
    }

    /**
     * @dev Returns the substraction of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function trySub(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        if (b > a) return (false, 0);
        return (true, a - b);
    }

    /**
     * @dev Returns the multiplication of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function tryMul(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        // Gas optimization: this is cheaper than requiring 'a' not being zero, but the
        // benefit is lost if 'b' is also tested.
        // See: https://github.com/OpenZeppelin/openzeppelin-contracts/pull/522
        if (a == 0) return (true, 0);
        uint256 c = a * b;
        if (c / a != b) return (false, 0);
        return (true, c);
    }

    /**
     * @dev Returns the division of two unsigned integers, with a division by zero flag.
     *
     * _Available since v3.4._
     */
    function tryDiv(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        if (b == 0) return (false, 0);
        return (true, a / b);
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers, with a division by zero flag.
     *
     * _Available since v3.4._
     */
    function tryMod(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        if (b == 0) return (false, 0);
        return (true, a % b);
    }

    /**
     * @dev Returns the addition of two unsigned integers, reverting on
     * overflow.
     *
     * Counterpart to Solidity's `+` operator.
     *
     * Requirements:
     *
     * - Addition cannot overflow.
     */
    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;
        require(c >= a, "SafeMath: addition overflow");
        return c;
    }

    /**
     * @dev Returns the subtraction of two unsigned integers, reverting on
     * overflow (when the result is negative).
     *
     * Counterpart to Solidity's `-` operator.
     *
     * Requirements:
     *
     * - Subtraction cannot overflow.
     */
    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b <= a, "SafeMath: subtraction overflow");
        return a - b;
    }

    /**
     * @dev Returns the multiplication of two unsigned integers, reverting on
     * overflow.
     *
     * Counterpart to Solidity's `*` operator.
     *
     * Requirements:
     *
     * - Multiplication cannot overflow.
     */
    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        if (a == 0) return 0;
        uint256 c = a * b;
        require(c / a == b, "SafeMath: multiplication overflow");
        return c;
    }

    /**
     * @dev Returns the integer division of two unsigned integers, reverting on
     * division by zero. The result is rounded towards zero.
     *
     * Counterpart to Solidity's `/` operator. Note: this function uses a
     * `revert` opcode (which leaves remaining gas untouched) while Solidity
     * uses an invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b > 0, "SafeMath: division by zero");
        return a / b;
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers. (unsigned integer modulo),
     * reverting when dividing by zero.
     *
     * Counterpart to Solidity's `%` operator. This function uses a `revert`
     * opcode (which leaves remaining gas untouched) while Solidity uses an
     * invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function mod(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b > 0, "SafeMath: modulo by zero");
        return a % b;
    }

    /**
     * @dev Returns the subtraction of two unsigned integers, reverting with custom message on
     * overflow (when the result is negative).
     *
     * CAUTION: This function is deprecated because it requires allocating memory for the error
     * message unnecessarily. For custom revert reasons use {trySub}.
     *
     * Counterpart to Solidity's `-` operator.
     *
     * Requirements:
     *
     * - Subtraction cannot overflow.
     */
    function sub(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b <= a, errorMessage);
        return a - b;
    }

    /**
     * @dev Returns the integer division of two unsigned integers, reverting with custom message on
     * division by zero. The result is rounded towards zero.
     *
     * CAUTION: This function is deprecated because it requires allocating memory for the error
     * message unnecessarily. For custom revert reasons use {tryDiv}.
     *
     * Counterpart to Solidity's `/` operator. Note: this function uses a
     * `revert` opcode (which leaves remaining gas untouched) while Solidity
     * uses an invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function div(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b > 0, errorMessage);
        return a / b;
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers. (unsigned integer modulo),
     * reverting with custom message when dividing by zero.
     *
     * CAUTION: This function is deprecated because it requires allocating memory for the error
     * message unnecessarily. For custom revert reasons use {tryMod}.
     *
     * Counterpart to Solidity's `%` operator. This function uses a `revert`
     * opcode (which leaves remaining gas untouched) while Solidity uses an
     * invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function mod(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b > 0, errorMessage);
        return a % b;
    }
}

// SPDX-License-Identifier: BUSL-1.1

// https://github.com/hamdiallam/solidity-rlp

pragma solidity ^0.7.0;

library RLPDecode {
    uint8 constant STRING_SHORT_START = 0x80;
    uint8 constant STRING_LONG_START = 0xb8;
    uint8 constant LIST_SHORT_START = 0xc0;
    uint8 constant LIST_LONG_START = 0xf8;
    uint8 constant WORD_SIZE = 32;

    struct RLPItem {
        uint len;
        uint memPtr;
    }

    struct Iterator {
        RLPItem item; // Item that's being iterated over.
        uint nextPtr; // Position of the next item in the list.
    }

    /*
     * @dev Returns the next element in the iteration. Reverts if it has not next element.
     * @param self The iterator.
     * @return The next element in the iteration.
     */
    function next(Iterator memory self) internal pure returns (RLPItem memory) {
        require(hasNext(self), "RLPDecoder iterator has no next");

        uint ptr = self.nextPtr;
        uint itemLength = _itemLength(ptr);
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
        uint memPtr;
        assembly {
            memPtr := add(item, 0x20)
        }
        // offset the pointer if the first byte

        uint8 byte0;
        assembly {
            byte0 := byte(0, mload(memPtr))
        }
        uint len = item.length;
        if (len > 0 && byte0 < LIST_SHORT_START) {
            assembly {
                memPtr := add(memPtr, 0x01)
            }
            len -= 1;
        }
        return RLPItem(len, memPtr);
    }

    /*
     * @dev Create an iterator. Reverts if item is not a list.
     * @param self The RLP item.
     * @return An 'Iterator' over the item.
     */
    function iterator(RLPItem memory self) internal pure returns (Iterator memory) {
        require(isList(self), "RLPDecoder iterator is not list");

        uint ptr = self.memPtr + _payloadOffset(self.memPtr);
        return Iterator(self, ptr);
    }

    /*
     * @param item RLP encoded bytes
     */
    function rlpLen(RLPItem memory item) internal pure returns (uint) {
        return item.len;
    }

    /*
     * @param item RLP encoded bytes
     */
    function payloadLen(RLPItem memory item) internal pure returns (uint) {
        uint offset = _payloadOffset(item.memPtr);
        require(item.len >= offset, "RLPDecoder: invalid uint RLP item offset size");
        return item.len - offset;
    }

    /*
     * @param item RLP encoded list in bytes
     */
    function toList(RLPItem memory item) internal pure returns (RLPItem[] memory) {
        require(isList(item), "RLPDecoder iterator is not a list");

        uint items = numItems(item);
        RLPItem[] memory result = new RLPItem[](items);

        uint memPtr = item.memPtr + _payloadOffset(item.memPtr);
        uint dataLen;
        for (uint i = 0; i < items; i++) {
            dataLen = _itemLength(memPtr);
            result[i] = RLPItem(dataLen, memPtr);
            memPtr = memPtr + dataLen;
        }

        return result;
    }

    /*
     * @param get the RLP item by index. save gas.
     */
    function getItemByIndex(RLPItem memory item, uint idx) internal pure returns (RLPItem memory) {
        require(isList(item), "RLPDecoder iterator is not a list");

        uint memPtr = item.memPtr + _payloadOffset(item.memPtr);
        uint dataLen;
        for (uint i = 0; i < idx; i++) {
            dataLen = _itemLength(memPtr);
            memPtr = memPtr + dataLen;
        }
        dataLen = _itemLength(memPtr);
        return RLPItem(dataLen, memPtr);
    }


    /*
     * @param get the RLP item by index. save gas.
     */
    function safeGetItemByIndex(RLPItem memory item, uint idx) internal pure returns (RLPItem memory) {
        require(isList(item), "RLPDecoder iterator is not a list");
        require(idx < numItems(item), "RLP item out of bounds");
        uint endPtr = item.memPtr + item.len;

        uint memPtr = item.memPtr + _payloadOffset(item.memPtr);
        uint dataLen;
        for (uint i = 0; i < idx; i++) {
            dataLen = _itemLength(memPtr);
            memPtr = memPtr + dataLen;
        }
        dataLen = _itemLength(memPtr);

        require(memPtr + dataLen <= endPtr, "RLP item overflow");
        return RLPItem(dataLen, memPtr);
    }

    /*
     * @param offset the receipt bytes item
     */
    function typeOffset(RLPItem memory item) internal pure returns (RLPItem memory) {
        uint offset = _payloadOffset(item.memPtr);
        uint8 byte0;
        uint memPtr = item.memPtr;
        uint len = item.len;
        assembly {
            memPtr := add(memPtr, offset)
            byte0 := byte(0, mload(memPtr))
        }
        if (len >0 && byte0 < LIST_SHORT_START) {
            assembly {
                memPtr := add(memPtr, 0x01)
            }
            len -= 1;
        }
        return RLPItem(len, memPtr);
    }

    // @return indicator whether encoded payload is a list. negate this function call for isData.
    function isList(RLPItem memory item) internal pure returns (bool) {
        if (item.len == 0) return false;

        uint8 byte0;
        uint memPtr = item.memPtr;
        assembly {
            byte0 := byte(0, mload(memPtr))
        }

        if (byte0 < LIST_SHORT_START) return false;
        return true;
    }

    /** RLPItem conversions into data types **/

    // @returns raw rlp encoding in bytes
    function toRlpBytes(RLPItem memory item) internal pure returns (bytes memory) {
        bytes memory result = new bytes(item.len);
        if (result.length == 0) return result;

        uint ptr;
        assembly {
            ptr := add(0x20, result)
        }

        copy(item.memPtr, ptr, item.len);
        return result;
    }

    // any non-zero byte except "0x80" is considered true
    function toBoolean(RLPItem memory item) internal pure returns (bool) {
        require(item.len == 1, "RLPDecoder toBoolean invalid length");
        uint result;
        uint memPtr = item.memPtr;
        assembly {
            result := byte(0, mload(memPtr))
        }

        // SEE Github Issue #5.
        // Summary: Most commonly used RLP libraries (i.e Geth) will encode
        // "0" as "0x80" instead of as "0". We handle this edge case explicitly
        // here.
        if (result == 0 || result == STRING_SHORT_START) {
            return false;
        } else {
            return true;
        }
    }

    function toAddress(RLPItem memory item) internal pure returns (address) {
        // 1 byte for the length prefix
        require(item.len == 21, "RLPDecoder toAddress invalid length");

        return address(toUint(item));
    }

    function toUint(RLPItem memory item) internal pure returns (uint) {
        require(item.len > 0 && item.len <= 33, "RLPDecoder toUint invalid length");

        uint offset = _payloadOffset(item.memPtr);
        require(item.len >= offset, "RLPDecoder: invalid RLP item offset size");
        uint len = item.len - offset;

        uint result;
        uint memPtr = item.memPtr + offset;
        assembly {
            result := mload(memPtr)

            // shift to the correct location if necessary
            if lt(len, 32) {
                result := div(result, exp(256, sub(32, len)))
            }
        }

        return result;
    }

    // enforces 32 byte length
    function toUintStrict(RLPItem memory item) internal pure returns (uint) {
        // one byte prefix
        require(item.len == 33, "RLPDecoder toUintStrict invalid length");

        uint result;
        uint memPtr = item.memPtr + 1;
        assembly {
            result := mload(memPtr)
        }

        return result;
    }

    function toBytes(RLPItem memory item) internal pure returns (bytes memory) {
        require(item.len > 0, "RLPDecoder toBytes invalid length");

        uint offset = _payloadOffset(item.memPtr);
        require(item.len >= offset, "RLPDecoder: invalid RLP item offset size");
        uint len = item.len - offset; // data length
        bytes memory result = new bytes(len);

        uint destPtr;
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
    function numItems(RLPItem memory item) internal pure returns (uint) {
        if (item.len == 0) return 0;

        uint count = 0;
        uint currPtr = item.memPtr + _payloadOffset(item.memPtr);
        uint endPtr = item.memPtr + item.len;
        while (currPtr < endPtr) {
            currPtr = currPtr + _itemLength(currPtr); // skip over an item
            count++;
        }

        return count;
    }

    // @return entire rlp item byte length
    function _itemLength(uint memPtr) private pure returns (uint) {
        uint itemLen;
        uint byte0;
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
    function _payloadOffset(uint memPtr) private pure returns (uint) {
        uint byte0;
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
        uint src,
        uint dest,
        uint len
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

        // left over bytes. Mask is used to remove unwanted bytes from the word
        uint mask = 256**(WORD_SIZE - len) - 1;
        assembly {
            let srcpart := and(mload(src), not(mask)) // zero out src
            let destpart := and(mload(dest), mask) // retrieve the bytes
            mstore(dest, or(destpart, srcpart))
        }
    }
}