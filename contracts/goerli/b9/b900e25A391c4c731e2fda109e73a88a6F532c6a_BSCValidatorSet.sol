// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (access/Ownable.sol)

pragma solidity ^0.8.0;

import "../utils/Context.sol";

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

// SPDX-License-Identifier: MIT
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

// SPDX-License-Identifier: Apache-2.0
pragma solidity 0.8.18;

import "./Initializable.sol";
import "./System.sol";
import "./interfaces/IApplication.sol";
import "./interfaces/IBSCValidatorSet.sol";
import "./lib/CmnPkg.sol";
import "./lib/Memory.sol";
import "./lib/RLPDecode.sol";

contract BSCValidatorSet is Initializable, IApplication, IBSCValidatorSet {
    using RLPDecode for *;

    uint8 public constant VALIDATORS_UPDATE_MESSAGE_TYPE = 0;

    uint256 public constant EXPIRE_TIME_SECOND_GAP = 1000;
    uint256 public constant MAX_NUM_OF_VALIDATORS = 41;

    uint32 public constant ERROR_UNKNOWN_PACKAGE_TYPE = 101;
    uint32 public constant ERROR_FAIL_CHECK_VALIDATORS = 102;
    uint32 public constant ERROR_LEN_OF_VAL_MISMATCH = 103;

    uint256 public constant INIT_NUM_OF_CABINETS = 21;
    uint256 public constant EPOCH = 200;

    /*********************** state of the contract **************************/
    Validator[] public currentValidatorSet;
    uint256 public expireTimeSecondGap;

    System private system;

    // key is the `consensusAddress` of `Validator`,
    // value is the 1-based index of the element in `currentValidatorSet`.
    mapping(address => uint256) public currentValidatorSetMap;

    struct Validator {
        address consensusAddress;
        address payable feeAddress;
        address BBCFeeAddress;
        uint64 votingPower;
        // only in state
        bool jailed;
        uint256 incoming;
    }

    /*********************** cross chain package **************************/
    struct IbcValidatorSetPackage {
        uint8 packageType;
        Validator[] validatorSet;
    }

    /*********************** events **************************/
    event ValidatorSetUpdated();
    event UnexpectedPackage(uint8 channelId, bytes msgBytes);
    event FailedWithReasonStr(string message);

    /*********************** init **************************/
    function init(address _system, bytes memory _initValidatorSetBytes) external onlyUninitialized {
        (IbcValidatorSetPackage memory validatorSetPkg, bool valid) = decodeValidatorSetSynPackage(
            _initValidatorSetBytes
        );
        require(valid, "failed to parse init validatorSet");
        for (uint256 i; i < validatorSetPkg.validatorSet.length; ++i) {
            currentValidatorSet.push(validatorSetPkg.validatorSet[i]);
            currentValidatorSetMap[validatorSetPkg.validatorSet[i].consensusAddress] = i + 1;
        }
        expireTimeSecondGap = EXPIRE_TIME_SECOND_GAP;

        system = System(_system);

        _initialized = true;
    }

    /*********************** Cross Chain App Implement **************************/
    function handleSynPackage(uint8, bytes calldata msgBytes)
        external
        override
        onlyInitialized
        returns (bytes memory responsePayload)
    {
        require(msg.sender == System(system).crossChain(), "not cross chain contract");

        (IbcValidatorSetPackage memory validatorSetPackage, bool ok) = decodeValidatorSetSynPackage(msgBytes);
        if (!ok) {
            return CmnPkg.encodeCommonAckPackage(system.ERROR_FAIL_DECODE());
        }
        uint32 resCode;
        if (validatorSetPackage.packageType == VALIDATORS_UPDATE_MESSAGE_TYPE) {
            resCode = updateValidatorSet(validatorSetPackage.validatorSet);
        } else {
            resCode = ERROR_UNKNOWN_PACKAGE_TYPE;
        }
        if (resCode == system.CODE_OK()) {
            return new bytes(0);
        } else {
            return CmnPkg.encodeCommonAckPackage(resCode);
        }
    }

    function handleAckPackage(uint8 channelId, bytes calldata msgBytes) external override {
        require(msg.sender == system.crossChain(), "not cross chain contract");

        // should not happen
        emit UnexpectedPackage(channelId, msgBytes);
    }

    function handleFailAckPackage(uint8 channelId, bytes calldata msgBytes) external override {
        require(msg.sender == system.crossChain(), "not cross chain contract");

        // should not happen
        emit UnexpectedPackage(channelId, msgBytes);
    }

    function updateValidatorSet(Validator[] memory validatorSet) internal returns (uint32) {
        {
            // do verify.
            (bool valid, string memory errMsg) = checkValidatorSet(validatorSet);
            if (!valid) {
                emit FailedWithReasonStr(errMsg);
                return ERROR_FAIL_CHECK_VALIDATORS;
            }
        }

        // update validator set state
        doUpdateState(validatorSet);

        emit ValidatorSetUpdated();
        return system.CODE_OK();
    }

    /*********************** Internal Functions **************************/

    function checkValidatorSet(Validator[] memory validatorSet) private pure returns (bool, string memory) {
        if (validatorSet.length > MAX_NUM_OF_VALIDATORS) {
            return (false, "the number of validators exceed the limit");
        }
        for (uint256 i; i < validatorSet.length; ++i) {
            for (uint256 j = 0; j < i; j++) {
                if (validatorSet[i].consensusAddress == validatorSet[j].consensusAddress) {
                    return (false, "duplicate consensus address of validatorSet");
                }
            }
        }
        return (true, "");
    }

    function doUpdateState(Validator[] memory validatorSet) private {
        uint256 n = currentValidatorSet.length;
        uint256 m = validatorSet.length;

        for (uint256 i; i < n; ++i) {
            bool stale = true;
            Validator memory oldValidator = currentValidatorSet[i];
            for (uint256 j = 0; j < m; j++) {
                if (oldValidator.consensusAddress == validatorSet[j].consensusAddress) {
                    stale = false;
                    break;
                }
            }
            if (stale) {
                delete currentValidatorSetMap[oldValidator.consensusAddress];
            }
        }

        if (n > m) {
            for (uint256 i = m; i < n; ++i) {
                currentValidatorSet.pop();
            }
        }
        uint256 k = n < m ? n : m;
        for (uint256 i; i < k; ++i) {
            if (!isSameValidator(validatorSet[i], currentValidatorSet[i])) {
                currentValidatorSetMap[validatorSet[i].consensusAddress] = i + 1;
                currentValidatorSet[i] = validatorSet[i];
            }
        }
    }

    function isSameValidator(Validator memory v1, Validator memory v2) private pure returns (bool) {
        return
            v1.consensusAddress == v2.consensusAddress &&
            v1.feeAddress == v2.feeAddress &&
            v1.BBCFeeAddress == v2.BBCFeeAddress &&
            v1.votingPower == v2.votingPower;
    }

    //rlp encode & decode function
    function decodeValidatorSetSynPackage(bytes memory msgBytes)
        internal
        pure
        returns (IbcValidatorSetPackage memory, bool)
    {
        IbcValidatorSetPackage memory validatorSetPkg;

        RLPDecode.Iterator memory iter = msgBytes.toRLPItem().iterator();
        bool success = false;
        uint256 idx = 0;
        while (iter.hasNext()) {
            if (idx == 0) {
                validatorSetPkg.packageType = uint8(iter.next().toUint());
            } else if (idx == 1) {
                RLPDecode.RLPItem[] memory items = iter.next().toList();
                validatorSetPkg.validatorSet = new Validator[](items.length);
                for (uint256 j; j < items.length; ++j) {
                    (Validator memory val, bool ok) = decodeValidator(items[j]);
                    if (!ok) {
                        return (validatorSetPkg, false);
                    }
                    validatorSetPkg.validatorSet[j] = val;
                }
                success = true;
            } else {
                break;
            }
            idx++;
        }
        return (validatorSetPkg, success);
    }

    function decodeValidator(RLPDecode.RLPItem memory itemValidator) internal pure returns (Validator memory, bool) {
        Validator memory validator;
        RLPDecode.Iterator memory iter = itemValidator.iterator();
        bool success = false;
        uint256 idx = 0;
        while (iter.hasNext()) {
            if (idx == 0) {
                validator.consensusAddress = iter.next().toAddress();
            } else if (idx == 1) {
                validator.feeAddress = payable(iter.next().toAddress());
            } else if (idx == 2) {
                validator.BBCFeeAddress = iter.next().toAddress();
            } else if (idx == 3) {
                validator.votingPower = uint64(iter.next().toUint());
                success = true;
            } else {
                break;
            }
            idx++;
        }
        return (validator, success);
    }

    function isCurrentValidator(address valAddress) external view returns (bool) {
        return currentValidatorSetMap[valAddress] != 0;
    }
}

// SPDX-License-Identifier: Apache-2.0
pragma solidity 0.8.18;

abstract contract Initializable {
    bool internal _initialized;

    modifier onlyUninitialized() {
        require(!_initialized, "already initialized");
        _;
    }

    modifier onlyInitialized() {
        require(_initialized, "not initialized");
        _;
    }
}

// SPDX-License-Identifier: Apache-2.0
pragma solidity ^0.8.0;

interface IApplication {
    /**
     * @dev Handle syn package
     */
    function handleSynPackage(uint8 channelId, bytes calldata msgBytes) external returns (bytes memory responsePayload);

    /**
     * @dev Handle ack package
     */
    function handleAckPackage(uint8 channelId, bytes calldata msgBytes) external;

    /**
     * @dev Handle fail ack package
     */
    function handleFailAckPackage(uint8 channelId, bytes calldata msgBytes) external;
}

// SPDX-License-Identifier: Apache-2.0
pragma solidity ^0.8.0;

interface IBSCValidatorSet {
    function isCurrentValidator(address valAddress) external view returns (bool);
}

// SPDX-License-Identifier: Apache-2.0
pragma solidity 0.8.18;

import "./RLPEncode.sol";
import "./RLPDecode.sol";

library CmnPkg {
    using RLPEncode for *;
    using RLPDecode for *;

    struct CommonAckPackage {
        uint32 code;
    }

    function encodeCommonAckPackage(uint32 code) internal pure returns (bytes memory) {
        bytes[] memory elements = new bytes[](1);
        elements[0] = uint256(code).encodeUint();
        return elements.encodeList();
    }

    function decodeCommonAckPackage(bytes memory msgBytes) internal pure returns (CommonAckPackage memory, bool) {
        CommonAckPackage memory ackPkg;
        RLPDecode.Iterator memory iter = msgBytes.toRLPItem().iterator();

        bool success = false;
        uint256 idx = 0;
        while (iter.hasNext()) {
            if (idx == 0) {
                ackPkg.code = uint32(iter.next().toUint());
                success = true;
            } else {
                break;
            }
            idx++;
        }
        return (ackPkg, success);
    }
}

// SPDX-License-Identifier: Apache-2.0
pragma solidity 0.8.18;

library Memory {
    // Size of a word, in bytes.
    uint256 internal constant WORD_SIZE = 32;
    // Size of the header of a 'bytes' array.
    uint256 internal constant BYTES_HEADER_SIZE = 32;
    // Address of the free memory pointer.
    uint256 internal constant FREE_MEM_PTR = 0x40;

    // Compares the 'len' bytes starting at address 'addr' in memory with the 'len'
    // bytes starting at 'addr2'.
    // Returns 'true' if the bytes are the same, otherwise 'false'.
    function equals(
        uint256 addr,
        uint256 addr2,
        uint256 len
    ) internal pure returns (bool equal) {
        assembly {
            equal := eq(keccak256(addr, len), keccak256(addr2, len))
        }
    }

    // Compares the 'len' bytes starting at address 'addr' in memory with the bytes stored in
    // 'bts'. It is allowed to set 'len' to a lower value then 'bts.length', in which case only
    // the first 'len' bytes will be compared.
    // Requires that 'bts.length >= len'
    function equals(
        uint256 addr,
        uint256 len,
        bytes memory bts
    ) internal pure returns (bool equal) {
        require(bts.length >= len);
        uint256 addr2;
        assembly {
            addr2 := add(
                bts,
                /*BYTES_HEADER_SIZE*/
                32
            )
        }
        return equals(addr, addr2, len);
    }

    function compareStrings(string memory a, string memory b) internal pure returns (bool) {
        return (keccak256(abi.encodePacked((a))) == keccak256(abi.encodePacked((b))));
    }

    // Copy 'len' bytes from memory address 'src', to address 'dest'.
    // This function does not check the or destination, it only copies
    // the bytes.
    function copy(
        uint256 src,
        uint256 dest,
        uint256 len
    ) internal pure {
        // Copy word-length chunks while possible
        for (; len >= WORD_SIZE; len -= WORD_SIZE) {
            assembly {
                mstore(dest, mload(src))
            }
            dest += WORD_SIZE;
            src += WORD_SIZE;
        }

        // Copy remaining bytes
        uint256 mask = 256**(WORD_SIZE - len) - 1;
        assembly {
            let srcpart := and(mload(src), not(mask))
            let destpart := and(mload(dest), mask)
            mstore(dest, or(destpart, srcpart))
        }
    }

    // Returns a memory pointer to the provided bytes array.
    function ptr(bytes memory bts) internal pure returns (uint256 addr) {
        assembly {
            addr := bts
        }
    }

    // Returns a memory pointer to the data portion of the provided bytes array.
    function dataPtr(bytes memory bts) internal pure returns (uint256 addr) {
        assembly {
            addr := add(
                bts,
                /*BYTES_HEADER_SIZE*/
                32
            )
        }
    }

    // This function does the same as 'dataPtr(bytes memory)', but will also return the
    // length of the provided bytes array.
    function fromBytes(bytes memory bts) internal pure returns (uint256 addr, uint256 len) {
        len = bts.length;
        assembly {
            addr := add(
                bts,
                /*BYTES_HEADER_SIZE*/
                32
            )
        }
    }

    // Creates a 'bytes memory' variable from the memory address 'addr', with the
    // length 'len'. The function will allocate new memory for the bytes array, and
    // the 'len bytes starting at 'addr' will be copied into that new memory.
    function toBytes(uint256 addr, uint256 len) internal pure returns (bytes memory bts) {
        bts = new bytes(len);
        uint256 btsptr;
        assembly {
            btsptr := add(
                bts,
                /*BYTES_HEADER_SIZE*/
                32
            )
        }
        copy(addr, btsptr, len);
    }

    // Get the word stored at memory address 'addr' as a 'uint'.
    function toUint(uint256 addr) internal pure returns (uint256 n) {
        assembly {
            n := mload(addr)
        }
    }

    // Get the word stored at memory address 'addr' as a 'bytes32'.
    function toBytes32(uint256 addr) internal pure returns (bytes32 bts) {
        assembly {
            bts := mload(addr)
        }
    }
}

// SPDX-License-Identifier: Apache-2.0
pragma solidity 0.8.18;

library RLPDecode {
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

    function next(Iterator memory self) internal pure returns (RLPItem memory) {
        require(hasNext(self));

        uint256 ptr = self.nextPtr;
        uint256 itemLength = _itemLength(ptr);
        self.nextPtr = ptr + itemLength;

        return RLPItem(itemLength, ptr);
    }

    function hasNext(Iterator memory self) internal pure returns (bool) {
        RLPItem memory item = self.item;
        return self.nextPtr < item.memPtr + item.len;
    }

    function toRLPItem(bytes memory self) internal pure returns (RLPItem memory) {
        uint256 memPtr;
        assembly {
            memPtr := add(self, 0x20)
        }

        return RLPItem(self.length, memPtr);
    }

    function iterator(RLPItem memory self) internal pure returns (Iterator memory) {
        require(isList(self));

        uint256 ptr = self.memPtr + _payloadOffset(self.memPtr);
        return Iterator(self, ptr);
    }

    function rlpLen(RLPItem memory item) internal pure returns (uint256) {
        return item.len;
    }

    function payloadLen(RLPItem memory item) internal pure returns (uint256) {
        return item.len - _payloadOffset(item.memPtr);
    }

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
        require(item.len >= offset, "length is less than offset");
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

    function _itemLength(uint256 memPtr) private pure returns (uint256) {
        uint256 itemLen;
        uint256 byte0;
        assembly {
            byte0 := byte(0, mload(memPtr))
        }

        if (byte0 < STRING_SHORT_START) itemLen = 1;
        else if (byte0 < STRING_LONG_START) itemLen = byte0 - STRING_SHORT_START + 1;
        else if (byte0 < LIST_SHORT_START) {
            uint256 dataLen;
            assembly {
                let byteLen := sub(byte0, 0xb7) // # of bytes the actual length is
                memPtr := add(memPtr, 1) // skip over the first byte

                /* 32 byte word size */
                dataLen := div(mload(memPtr), exp(256, sub(32, byteLen))) // right shifting to get the len
                itemLen := add(dataLen, add(byteLen, 1))
            }
            require(itemLen >= dataLen, "addition overflow");
        } else if (byte0 < LIST_LONG_START) {
            itemLen = byte0 - LIST_SHORT_START + 1;
        } else {
            uint256 dataLen;
            assembly {
                let byteLen := sub(byte0, 0xf7)
                memPtr := add(memPtr, 1)

                dataLen := div(mload(memPtr), exp(256, sub(32, byteLen))) // right shifting to the correct length
                itemLen := add(dataLen, add(byteLen, 1))
            }
            require(itemLen >= dataLen, "addition overflow");
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

        // left over bytes. Mask is used to remove unwanted bytes from the word
        uint256 mask = 256**(WORD_SIZE - len) - 1;
        assembly {
            let srcpart := and(mload(src), not(mask)) // zero out src
            let destpart := and(mload(dest), mask) // retrieve the bytes
            mstore(dest, or(destpart, srcpart))
        }
    }
}

// SPDX-License-Identifier: Apache-2.0
pragma solidity 0.8.18;

library RLPEncode {
    uint8 constant STRING_OFFSET = 0x80;
    uint8 constant LIST_OFFSET = 0xc0;

    /**
     * @notice Encode string item
     * @param self The string (ie. byte array) item to encode
     * @return The RLP encoded string in bytes
     */
    function encodeBytes(bytes memory self) internal pure returns (bytes memory) {
        if (self.length == 1 && self[0] <= 0x7f) {
            return self;
        }
        return mergeBytes(encodeLength(self.length, STRING_OFFSET), self);
    }

    /**
     * @notice Encode address
     * @param self The address to encode
     * @return The RLP encoded address in bytes
     */
    function encodeAddress(address self) internal pure returns (bytes memory) {
        bytes memory b;
        assembly {
            let m := mload(0x40)
            mstore(add(m, 20), xor(0x140000000000000000000000000000000000000000, self))
            mstore(0x40, add(m, 52))
            b := m
        }
        return encodeBytes(b);
    }

    /**
     * @notice Encode uint
     * @param self The uint to encode
     * @return The RLP encoded uint in bytes
     */
    function encodeUint(uint256 self) internal pure returns (bytes memory) {
        return encodeBytes(toBinary(self));
    }

    /**
     * @notice Encode int
     * @param self The int to encode
     * @return The RLP encoded int in bytes
     */
    function encodeInt(int256 self) internal pure returns (bytes memory) {
        return encodeUint(uint256(self));
    }

    /**
     * @notice Encode bool
     * @param self The bool to encode
     * @return The RLP encoded bool in bytes
     */
    function encodeBool(bool self) internal pure returns (bytes memory) {
        bytes memory rs = new bytes(1);
        if (self) {
            rs[0] = bytes1(uint8(1));
        }
        return rs;
    }

    /**
     * @notice Encode list of items
     * @param self The list of items to encode, each item in list must be already encoded
     * @return The RLP encoded list of items in bytes
     */
    function encodeList(bytes[] memory self) internal pure returns (bytes memory) {
        if (self.length == 0) {
            return new bytes(0);
        }
        bytes memory payload = self[0];
        for (uint256 i = 1; i < self.length; i++) {
            payload = mergeBytes(payload, self[i]);
        }
        return mergeBytes(encodeLength(payload.length, LIST_OFFSET), payload);
    }

    /**
     * @notice Concat two bytes arrays
     * @param _preBytes The first bytes array
     * @param _postBytes The second bytes array
     * @return The merged bytes array
     */
    function mergeBytes(bytes memory _preBytes, bytes memory _postBytes) internal pure returns (bytes memory) {
        bytes memory tempBytes;

        assembly {
            // Get a location of some free memory and store it in tempBytes as
            // Solidity does for memory variables.
            tempBytes := mload(0x40)

            // Store the length of the first bytes array at the beginning of
            // the memory for tempBytes.
            let length := mload(_preBytes)
            mstore(tempBytes, length)

            // Maintain a memory counter for the current write location in the
            // temp bytes array by adding the 32 bytes for the array length to
            // the starting location.
            let mc := add(tempBytes, 0x20)
            // Stop copying when the memory counter reaches the length of the
            // first bytes array.
            let end := add(mc, length)

            for {
                // Initialize a copy counter to the start of the _preBytes data,
                // 32 bytes into its memory.
                let cc := add(_preBytes, 0x20)
            } lt(mc, end) {
                // Increase both counters by 32 bytes each iteration.
                mc := add(mc, 0x20)
                cc := add(cc, 0x20)
            } {
                // Write the _preBytes data into the tempBytes memory 32 bytes
                // at a time.
                mstore(mc, mload(cc))
            }

            // Add the length of _postBytes to the current length of tempBytes
            // and store it as the new length in the first 32 bytes of the
            // tempBytes memory.
            length := mload(_postBytes)
            mstore(tempBytes, add(length, mload(tempBytes)))

            // Move the memory counter back from a multiple of 0x20 to the
            // actual end of the _preBytes data.
            mc := end
            // Stop copying when the memory counter reaches the new combined
            // length of the arrays.
            end := add(mc, length)

            for {
                let cc := add(_postBytes, 0x20)
            } lt(mc, end) {
                mc := add(mc, 0x20)
                cc := add(cc, 0x20)
            } {
                mstore(mc, mload(cc))
            }

            // Update the free-memory pointer by padding our last write location
            // to 32 bytes: add 31 bytes to the end of tempBytes to move to the
            // next 32 byte block, then round down to the nearest multiple of
            // 32. If the sum of the length of the two arrays is zero then add
            // one before rounding down to leave a blank 32 bytes (the length block with 0).
            mstore(
                0x40,
                and(
                    add(add(end, iszero(add(length, mload(_preBytes)))), 31),
                    not(31) // Round down to the nearest 32 bytes.
                )
            )
        }

        return tempBytes;
    }

    /**
     * @notice Encode the first byte, followed by the `length` in binary form if `length` is more than 55.
     * @param length The length of the string or the payload
     * @param offset `STRING_OFFSET` if item is string, `LIST_OFFSET` if item is list
     * @return RLP encoded bytes
     */
    function encodeLength(uint256 length, uint256 offset) internal pure returns (bytes memory) {
        require(length < 256**8, "input too long");
        bytes memory rs = new bytes(1);
        if (length <= 55) {
            rs[0] = bytes1(uint8(length + offset));
            return rs;
        }
        bytes memory bl = toBinary(length);
        rs[0] = bytes1(uint8(bl.length + offset + 55));
        return mergeBytes(rs, bl);
    }

    /**
     * @notice Encode integer in big endian binary form with no leading zeroes
     * @param x The integer to encode
     * @return RLP encoded bytes
     */
    function toBinary(uint256 x) internal pure returns (bytes memory) {
        bytes memory b = new bytes(32);
        assembly {
            mstore(add(b, 32), x)
        }
        uint256 i;
        if (x & 0xffffffffffffffffffffffffffffffffffffffffffffffff0000000000000000 == 0) {
            i = 24;
        } else if (x & 0xffffffffffffffffffffffffffffffff00000000000000000000000000000000 == 0) {
            i = 16;
        } else {
            i = 0;
        }
        for (; i < 32; i++) {
            if (b[i] != 0) {
                break;
            }
        }
        uint256 length = 32 - i;
        bytes memory rs = new bytes(length);
        assembly {
            mstore(add(rs, length), x)
            mstore(rs, length)
        }
        return rs;
    }
}

// SPDX-License-Identifier: Apache-2.0
pragma solidity 0.8.18;

import "@openzeppelin/contracts/access/Ownable.sol";
import "./Initializable.sol";

contract System is Ownable, Initializable {
    uint32 public constant CODE_OK = 0;
    uint32 public constant ERROR_FAIL_DECODE = 100;

    uint8 public constant STAKING_CHANNEL_ID = 0x08;

    address public bscValidatorSet;
    address public tmLightClient;
    address public crossChain;

    uint16 public bscChainID;
    address public relayer;

    function init(
        uint16 _bscChainID,
        address _relayer,
        address _bscValidatorSet,
        address _tmLightClient,
        address _crossChain
    ) external onlyUninitialized onlyOwner {
        bscChainID = _bscChainID;
        relayer = _relayer;
        bscValidatorSet = _bscValidatorSet;
        tmLightClient = _tmLightClient;
        crossChain = _crossChain;

        _initialized = true;
    }

    function setRelayer(address _relayer) external onlyOwner {
        relayer = _relayer;
    }
}