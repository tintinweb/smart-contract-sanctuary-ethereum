/**
 *Submitted for verification at Etherscan.io on 2022-05-28
*/

/** 
 *  SourceUnit: /Users/chenyanlong/Work/staking-contracts/contracts/LightClient.sol
*/
            
////// SPDX-License-Identifier-FLATTEN-SUPPRESS-WARNING: GPL-3.0-only

pragma solidity ^0.8.0;

library DataTypes {
    uint256 constant CELR_DECIMAL = 1e18;
    uint256 constant MAX_INT = 2**256 - 1;
    uint256 constant COMMISSION_RATE_BASE = 10000; // 1 commissionRate means 0.01%
    uint256 constant MAX_UNDELEGATION_ENTRIES = 10;
    uint256 constant SLASH_FACTOR_DECIMAL = 1e6;

    enum ValidatorStatus {
        Null,
        Unbonded,
        Unbonding,
        Bonded
    }

    enum ParamName {
        ProposalDeposit,
        VotingPeriod,
        UnbondingPeriod,
        MaxBondedValidators,
        MinValidatorTokens,
        MinSelfDelegation,
        AdvanceNoticePeriod,
        ValidatorBondInterval,
        MaxSlashFactor
    }

    struct Undelegation {
        uint256 shares;
        uint256 creationBlock;
    }

    struct Undelegations {
        mapping(uint256 => Undelegation) queue;
        uint32 head;
        uint32 tail;
    }

    struct Delegator {
        uint256 shares;
        Undelegations undelegations;
    }

    struct Validator {
        ValidatorStatus status;
        address signer;
        uint256 tokens; // sum of all tokens delegated to this validator
        uint256 shares; // sum of all delegation shares
        uint256 undelegationTokens; // tokens being undelegated
        uint256 undelegationShares; // shares of tokens being undelegated
        mapping(address => Delegator) delegators;
        uint256 minSelfDelegation;
        uint64 bondBlock; // cannot become bonded before this block
        uint64 unbondBlock; // cannot become unbonded before this block
        uint64 commissionRate; // equal to real commission rate * COMMISSION_RATE_BASE
        address[] delAddrs;
    }

    // used for external view output
    struct ValidatorTokens {
        address valAddr;
        uint256 tokens;
    }

    // used for external view output
    struct ValidatorInfo {
        address valAddr;
        ValidatorStatus status;
        address signer;
        uint256 tokens;
        uint256 shares;
        uint256 minSelfDelegation;
        uint64 commissionRate;
    }

    // used for external view output
    struct DelegatorInfo {
        address valAddr;
        uint256 tokens;
        uint256 shares;
        Undelegation[] undelegations;
        uint256 undelegationTokens;
        uint256 withdrawableUndelegationTokens;
    }
}




/** 
 *  SourceUnit: /Users/chenyanlong/Work/staking-contracts/contracts/LightClient.sol
*/
            
////// SPDX-License-Identifier-FLATTEN-SUPPRESS-WARNING: MIT
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




/** 
 *  SourceUnit: /Users/chenyanlong/Work/staking-contracts/contracts/LightClient.sol
*/
            
////// SPDX-License-Identifier-FLATTEN-SUPPRESS-WARNING: MIT
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




/** 
 *  SourceUnit: /Users/chenyanlong/Work/staking-contracts/contracts/LightClient.sol
*/
            
////// SPDX-License-Identifier-FLATTEN-SUPPRESS-WARNING: GPL-3.0-only

/**
 * @title RLPEncode
 * @dev A simple RLP encoding library.
 * @author Bakaoh
 */
pragma solidity ^0.8.0;

library RLPEncode {
    /*
     * Internal functions
     */

    /**
     * @dev RLP encodes a byte string.
     * @param self The byte string to encode.
     * @return The RLP encoded string in bytes.
     */
    function encodeBytes(bytes memory self) internal pure returns (bytes memory) {
        bytes memory encoded;
        if (self.length == 1 && uint8(self[0]) <= 128) {
            encoded = self;
        } else {
            encoded = bytes.concat(encodeLength(self.length, 128), self);
        }
        return encoded;
    }

    /**
     * @dev RLP encodes a list of RLP encoded byte byte strings.
     * @param self The list of RLP encoded byte strings.
     * @return The RLP encoded list of items in bytes.
     */
    function encodeList(bytes[] memory self) internal pure returns (bytes memory) {
        bytes memory list = flatten(self);
        return bytes.concat(encodeLength(list.length, 192), list);
    }

    /**
     * @dev RLP encodes a string.
     * @param self The string to encode.
     * @return The RLP encoded string in bytes.
     */
    function encodeString(string memory self) internal pure returns (bytes memory) {
        return encodeBytes(bytes(self));
    }

    /**
     * @dev RLP encodes an address.
     * @param self The address to encode.
     * @return The RLP encoded address in bytes.
     */
    function encodeAddress(address self) internal pure returns (bytes memory) {
        bytes memory inputBytes;
        assembly {
            let m := mload(0x40)
            mstore(add(m, 20), xor(0x140000000000000000000000000000000000000000, self))
            mstore(0x40, add(m, 52))
            inputBytes := m
        }
        return encodeBytes(inputBytes);
    }

    /**
     * @dev RLP encodes a uint.
     * @param self The uint to encode.
     * @return The RLP encoded uint in bytes.
     */
    function encodeUint(uint256 self) internal pure returns (bytes memory) {
        return encodeBytes(toBinary(self));
    }

    /**
     * @dev RLP encodes an int.
     * @param self The int to encode.
     * @return The RLP encoded int in bytes.
     */
    function encodeInt(int256 self) internal pure returns (bytes memory) {
        return encodeUint(uint256(self));
    }

    /**
     * @dev RLP encodes a bool.
     * @param self The bool to encode.
     * @return The RLP encoded bool in bytes.
     */
    function encodeBool(bool self) internal pure returns (bytes memory) {
        bytes memory encoded = new bytes(1);
        encoded[0] = (self ? bytes1(0x01) : bytes1(0x80));
        return encoded;
    }

    /*
     * Private functions
     */

    /**
     * @dev Encode the first byte, followed by the `len` in binary form if `length` is more than 55.
     * @param len The length of the string or the payload.
     * @param offset 128 if item is string, 192 if item is list.
     * @return RLP encoded bytes.
     */
    function encodeLength(uint256 len, uint256 offset) private pure returns (bytes memory) {
        bytes memory encoded;
        if (len < 56) {
            encoded = new bytes(1);
            encoded[0] = bytes32(len + offset)[31];
        } else {
            uint256 lenLen;
            uint256 i = 1;
            while (len / i != 0) {
                lenLen++;
                i *= 256;
            }

            encoded = new bytes(lenLen + 1);
            encoded[0] = bytes32(lenLen + offset + 55)[31];
            for (i = 1; i <= lenLen; i++) {
                encoded[i] = bytes32((len / (256**(lenLen - i))) % 256)[31];
            }
        }
        return encoded;
    }

    /**
     * @dev Encode integer in big endian binary form with no leading zeroes.
     * @notice TODO: This should be optimized with assembly to save gas costs.
     * @param _x The integer to encode.
     * @return RLP encoded bytes.
     */
    function toBinary(uint256 _x) private pure returns (bytes memory) {
        bytes memory b = new bytes(32);
        assembly {
            mstore(add(b, 32), _x)
        }
        uint256 i;
        for (i = 0; i < 32; i++) {
            if (b[i] != 0) {
                break;
            }
        }
        bytes memory res = new bytes(32 - i);
        for (uint256 j = 0; j < res.length; j++) {
            res[j] = b[i++];
        }
        return res;
    }

    /**
     * @dev Copies a piece of memory to another location.
     * @notice From: https://github.com/Arachnid/solidity-stringutils/blob/master/src/strings.sol.
     * @param _dest Destination location.
     * @param _src Source location.
     * @param _len Length of memory to copy.
     */
    function memcpy(
        uint256 _dest,
        uint256 _src,
        uint256 _len
    ) private pure {
        uint256 dest = _dest;
        uint256 src = _src;
        uint256 len = _len;

        for (; len >= 32; len -= 32) {
            assembly {
                mstore(dest, mload(src))
            }
            dest += 32;
            src += 32;
        }

        uint256 mask = 256**(32 - len) - 1;
        assembly {
            let srcpart := and(mload(src), not(mask))
            let destpart := and(mload(dest), mask)
            mstore(dest, or(destpart, srcpart))
        }
    }

    /**
     * @dev Flattens a list of byte strings into one byte string.
     * @notice From: https://github.com/sammayo/solidity-rlp-encoder/blob/master/RLPEncode.sol.
     * @param _list List of byte strings to flatten.
     * @return The flattened byte string.
     */
    function flatten(bytes[] memory _list) private pure returns (bytes memory) {
        if (_list.length == 0) {
            return new bytes(0);
        }

        uint256 len;
        uint256 i;
        for (i = 0; i < _list.length; i++) {
            len += _list[i].length;
        }

        bytes memory flattened = new bytes(len);
        uint256 flattenedPtr;
        assembly {
            flattenedPtr := add(flattened, 0x20)
        }

        for (i = 0; i < _list.length; i++) {
            bytes memory item = _list[i];

            uint256 listPtr;
            assembly {
                listPtr := add(item, 0x20)
            }

            memcpy(flattenedPtr, listPtr, item.length);
            flattenedPtr += _list[i].length;
        }

        return flattened;
    }
}




/** 
 *  SourceUnit: /Users/chenyanlong/Work/staking-contracts/contracts/LightClient.sol
*/
            
////// SPDX-License-Identifier-FLATTEN-SUPPRESS-WARNING: Apache-2.0

/*
 * @author Hamdi Allam [email protected]
 * Please reach out with any questions or concerns
 */
pragma solidity ^0.8.0;

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
     * @param the RLP item.
     */
    function rlpLen(RLPItem memory item) internal pure returns (uint256) {
        return item.len;
    }

    /*
     * @param the RLP item.
     * @return (memPtr, len) pair: location of the item's payload in memory.
     */
    function payloadLocation(RLPItem memory item) internal pure returns (uint256, uint256) {
        uint256 offset = _payloadOffset(item.memPtr);
        uint256 memPtr = item.memPtr + offset;
        uint256 len = item.len - offset; // data length
        return (memPtr, len);
    }

    /*
     * @param the RLP item.
     */
    function payloadLen(RLPItem memory item) internal pure returns (uint256) {
        (, uint256 len) = payloadLocation(item);
        return len;
    }

    /*
     * @param the RLP item containing the encoded list.
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

    // any non-zero byte except "0x80" is considered true
    function toBoolean(RLPItem memory item) internal pure returns (bool) {
        require(item.len == 1);
        uint256 result;
        uint256 memPtr = item.memPtr;
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
        require(item.len == 21);

        return address(uint160(toUint(item)));
    }

    function toUint(RLPItem memory item) internal pure returns (uint256) {
        require(item.len > 0 && item.len <= 33);

        (uint256 memPtr, uint256 len) = payloadLocation(item);

        uint256 result;
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

        (uint256 memPtr, uint256 len) = payloadLocation(item);
        bytes memory result = new bytes(len);

        uint256 destPtr;
        assembly {
            destPtr := add(0x20, result)
        }

        copy(memPtr, destPtr, len);
        return result;
    }

    function toAddressArray(RLPItem memory item) internal pure returns (address[] memory addrs) {
        require(isList(item), "item should be List");

        RLPItem[] memory list = toList(item);
        addrs = new address[](list.length);
        for (uint256 i = 0; i < list.length; i++) {
            addrs[i] = toAddress(list[i]);
        }
    }

    function toUintArray(RLPItem memory item) internal pure returns (uint256[] memory array) {
        require(isList(item), "item should be List");

        RLPItem[] memory list = toList(item);
        array = new uint256[](list.length);
        for (uint256 i = 0; i < list.length; i++) {
            array[i] = toUint(list[i]);
        }
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

        if (len > 0) {
            // left over bytes. Mask is used to remove unwanted bytes from the word
            uint256 mask = 256**(WORD_SIZE - len) - 1;
            assembly {
                let srcpart := and(mload(src), not(mask)) // zero out src
                let destpart := and(mload(dest), mask) // retrieve the bytes
                mstore(dest, or(destpart, srcpart))
            }
        }
    }
}




/** 
 *  SourceUnit: /Users/chenyanlong/Work/staking-contracts/contracts/LightClient.sol
*/
            
pragma solidity ^0.8.0;

interface ILightClient {
    struct Epoch {
        address[] curEpochVals;
        uint256[] curVotingPowers;
    }

    function initEpoch(
        address[] memory epochSigners,
        uint256[] memory epochVotingPowers,
        uint256 height,
        bytes32 headHash
    ) external;

    function submitHead(
        bytes memory _epochHeaderBytes,
        bytes memory commitBytes,
        bool lookByIndex
    ) external;

    /* LightClient */
    function getCurrentEpoch()
        external
        view
        returns (
            uint256,
            address[] memory,
            uint256[] memory
        );

    function curEpochIdx() external view returns (uint256);

    function curEpochHeight() external view returns (uint256 height);

    function getNextEpochHeight() external view returns (uint256 height);

    function setEpochPeriod(uint256 _epochPeriod) external;

    function epochPeriod() external view returns (uint256 height);

    function getStaking() external view returns (address);

    function proposedValidators() external view returns (address[] memory, uint256[] memory);
}




/** 
 *  SourceUnit: /Users/chenyanlong/Work/staking-contracts/contracts/LightClient.sol
*/
            
pragma solidity ^0.8.0;

interface IStaking {
    function proposedValidators() external view returns (address[] memory, uint256[] memory);
}




/** 
 *  SourceUnit: /Users/chenyanlong/Work/staking-contracts/contracts/LightClient.sol
*/
            
////// SPDX-License-Identifier-FLATTEN-SUPPRESS-WARNING: MIT
// OpenZeppelin Contracts v4.4.1 (access/Ownable.sol)

pragma solidity ^0.8.0;

////import "../utils/Context.sol";

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




/** 
 *  SourceUnit: /Users/chenyanlong/Work/staking-contracts/contracts/LightClient.sol
*/
            
////// SPDX-License-Identifier-FLATTEN-SUPPRESS-WARNING: GPL-3.0-only
pragma solidity ^0.8.0;

////import "./RLPReader.sol";
////import "./RLPEncode.sol";
////import "@openzeppelin/contracts/utils/Strings.sol";

library BlockDecoder {
    using RLPReader for RLPReader.RLPItem;
    using RLPReader for RLPReader.Iterator;
    using RLPReader for bytes;
    using Strings for uint256;

    struct HeadCore {
        // bytes32 HeadHash;
        bytes32 Root;
        bytes32 TxHash;
        bytes32 ReceiptHash;
    }

    struct Header {
        bytes Bloom; //[256]byte
        HashData hashData;
        BaseData baseData;
        ValidatorData validatorData;
        Commit commit;
    }

    struct HashData {
        bytes32 ParentHash;
        bytes32 UncleHash;
        address Coinbase;
        bytes32 Root;
        bytes32 TxHash;
        bytes32 ReceiptHash;
    }

    struct BaseData {
        uint256 Difficulty;
        uint256 Number;
        uint64 GasLimit;
        uint64 GasUsed;
        uint64 Time;
        bytes Extra;
        bytes32 MixDigest;
        bytes8 Nonce;
        uint256 BaseFee;
    }

    struct ValidatorData {
        uint64 TimeMs;
        address[] NextValidators;
        uint256[] NextValidatorPowers;
        bytes32 LastCommitHash;
    }

    struct Commit {
        uint64 Height;
        uint32 Round;
        bytes32 BlockID;
        CommitSig[] Signatures;
    }

    struct CommitSig {
        uint8 BlockIDFlag;
        address ValidatorAddress;
        uint64 TimestampMs;
        bytes Signature; //[R || S || V]
    }

    struct voteForSign {
        SignedMsgType Type;
        uint64 Height;
        uint32 Round;
        bytes32 BlockID;
        uint64 TimestampMs;
        string ChainID;
    }

    uint8 constant BLOCK_FLAG_COMMIT = 2;

    enum SignedMsgType {
        UnknownType,
        // Votes
        PrevoteType,
        PrecommitType,
        // Proposals
        ProposalType
    }

    enum HeaderProperty {
        ParentHash,
        UncleHash,
        Coinbase,
        Root,
        TxHash,
        ReceiptHash,
        Bloom, //[256]byte
        Difficulty,
        Number,
        GasLimit,
        GasUsed,
        Time,
        Extra,
        MixDigest,
        Nonce,
        BaseFee,
        TimeMs,
        NextValidators,
        NextValidatorPowers,
        LastCommitHash,
        Commit
    }

    function verifyHeader(
        bytes memory headerRlpBytes,
        bytes memory commitRlpBytes,
        address[] memory validators,
        uint256[] memory votePowers,
        bool lookUpByIndex
    )
        internal
        pure
        returns (
            uint256,
            bytes32,
            HeadCore memory
        )
    {
        // ToDo:verify header base data
        bytes32 hash = msgHash(headerRlpBytes);
        (uint256 height, HeadCore memory core) = decodeHeadCore(headerRlpBytes);

        Commit memory commit = decodeCommit(commitRlpBytes.toRlpItem());
        require(commit.BlockID == hash, "incorrect BlockID");
        require(commit.Height == height, "incorrect Height");

        // verify all signatures
        require(
            verifyAllSignature(commit, validators, votePowers, lookUpByIndex, false, votingPowerNeed(votePowers), 3334),
            "failed to verify all signatures"
        );

        return (height, hash, core);
    }

    function votingPowerNeed(uint256[] memory votePowers) internal pure returns (uint256 power) {
        for (uint256 i = 0; i < votePowers.length; i++) {
            power += votePowers[i];
        }
        power = (power * 2) / 3;
    }

    function verifyAllSignature(
        Commit memory commit,
        address[] memory validators,
        uint256[] memory votePowers,
        bool lookUpByIndex,
        bool countAllSignatures,
        uint256 votingPowerNeeded,
        uint256 chainId
    ) internal pure returns (bool) {
        require(votePowers.length == validators.length, "incorrect length");
        uint256 talliedVotingPower;
        uint256 idx;
        for (uint256 i = 0; i < commit.Signatures.length; i++) {
            address vaddr = commit.Signatures[i].ValidatorAddress;

            if (lookUpByIndex) {
                require(vaddr == validators[i], "validator no exist");
                idx = i;
            } else {
                bool exist;
                (exist, idx) = _validatorIndex(vaddr, validators);
                if (!exist) {
                    continue;
                }
            }

            bytes memory signMsg = voteSignBytes(commit, chainId, i);

            if (verifySignature(vaddr, signMsg, commit.Signatures[i].Signature)) {
                // valid signature
                talliedVotingPower += votePowers[idx];
            }

            if (!countAllSignatures && talliedVotingPower > votingPowerNeeded) {
                return true;
            }
        }

        if (talliedVotingPower <= votingPowerNeeded) {
            return false;
        }
        return true;
    }

    function _validatorIndex(address val, address[] memory vals) internal pure returns (bool exist, uint256 index) {
        for (index = 0; index < vals.length; index++) {
            if (val == vals[index]) {
                exist = true;
                break;
            }
        }

        return (exist, index);
    }

    function verifySignature(
        address addr,
        bytes memory signMsg,
        bytes memory sig
    ) internal pure returns (bool) {
        bytes32 hash = msgHash(signMsg);
        (uint8 v, bytes32 r, bytes32 s) = getVRS(sig);
        address recAddr = ecrecover(hash, v, r, s);
        return (recAddr == addr);
    }

    function recoverSignature(bytes memory signMsg, bytes memory sig) internal pure returns (address) {
        bytes32 hash = msgHash(signMsg);
        (uint8 v, bytes32 r, bytes32 s) = getVRS(sig);
        address recAddr = ecrecover(hash, v, r, s);
        return recAddr;
    }

    function getVRS(bytes memory sig)
        internal
        pure
        returns (
            uint8 v,
            bytes32 r,
            bytes32 s
        )
    {
        require(sig.length == 65, "wrong sig length");
        assembly {
            v := mload(add(sig, 0x41))
            r := mload(add(sig, 0x20))
            s := mload(add(sig, 0x40))
        }
        if (v == 0 || v == 1) {
            v += 27;
        }
        return (v, r, s);
    }

    /*
    rlp decode and encode 
    */
    function decodeHeader(bytes memory blockRlpBytes) internal pure returns (Header memory header) {
        // TODO:decode bloom

        RLPReader.RLPItem[] memory list = decodeToHeaderList(blockRlpBytes);
        header.hashData = decodeHashData(list);
        header.baseData = decodeBaseData(list);
        header.validatorData = decodeValidatorData(list);
        if (list.length == 21) {
            header.commit = decodeCommit(list[uint8(HeaderProperty.Commit)]);
        }
    }

    function decodeToHeaderList(bytes memory headerRLPBytes) internal pure returns (RLPReader.RLPItem[] memory) {
        return headerRLPBytes.toRlpItem().toList();
    }

    function decodeHeaderHeight(bytes memory headerRLPBytes) internal pure returns (uint256 height) {
        RLPReader.RLPItem memory header = decodeToHeaderList(headerRLPBytes)[uint8(HeaderProperty.Number)];
        height = header.toUint();
        return height;
    }

    function decodeHeadCore(bytes memory headerRLPBytes) internal pure returns (uint256 height, HeadCore memory core) {
        RLPReader.RLPItem[] memory list = decodeToHeaderList(headerRLPBytes);
        height = list[uint8(HeaderProperty.Number)].toUint();
        core.Root = bytes32(list[uint8(HeaderProperty.Root)].toUint());
        core.TxHash = bytes32(list[uint8(HeaderProperty.TxHash)].toUint());
        core.ReceiptHash = bytes32(list[uint8(HeaderProperty.ReceiptHash)].toUint());

        return (height, core);
    }

    function decodeTxHash(bytes memory headerRLPBytes) internal pure returns (bytes32 hash) {
        RLPReader.RLPItem memory header = headerRLPBytes.toRlpItem().toList()[uint8(HeaderProperty.TxHash)];
        hash = bytes32(header.toUint());
        return hash;
    }

    function decodeReceiptHash(bytes memory headerRLPBytes) internal pure returns (bytes32 hash) {
        RLPReader.RLPItem memory header = headerRLPBytes.toRlpItem().toList()[uint8(HeaderProperty.ReceiptHash)];
        hash = bytes32(header.toUint());
        return hash;
    }

    function decodeHashData(RLPReader.RLPItem[] memory list) internal pure returns (HashData memory Hashs) {
        Hashs.ParentHash = bytes32(list[uint8(HeaderProperty.ParentHash)].toUint());
        Hashs.UncleHash = bytes32(list[uint8(HeaderProperty.UncleHash)].toUint());
        Hashs.Coinbase = list[uint8(HeaderProperty.Coinbase)].toAddress();

        Hashs.Root = bytes32(list[uint8(HeaderProperty.Root)].toUint());
        Hashs.TxHash = bytes32(list[uint8(HeaderProperty.TxHash)].toUint());
        Hashs.ReceiptHash = bytes32(list[uint8(HeaderProperty.ReceiptHash)].toUint());
    }

    function decodeBaseData(RLPReader.RLPItem[] memory list) internal pure returns (BaseData memory Bases) {
        Bases.Difficulty = list[uint8(HeaderProperty.Difficulty)].toUint();
        Bases.Number = list[uint8(HeaderProperty.Number)].toUint();
        Bases.GasLimit = uint64(list[uint8(HeaderProperty.GasLimit)].toUint());

        Bases.GasUsed = uint64(list[uint8(HeaderProperty.GasUsed)].toUint());
        Bases.Time = uint64(list[uint8(HeaderProperty.Time)].toUint());
        Bases.Extra = list[uint8(HeaderProperty.Extra)].toBytes();

        Bases.MixDigest = bytes32(list[uint8(HeaderProperty.MixDigest)].toUint());
        Bases.Nonce = bytes8(uint64(list[uint8(HeaderProperty.Nonce)].toUint()));
        Bases.BaseFee = list[uint8(HeaderProperty.BaseFee)].toUint();
    }

    function decodeValidatorData(RLPReader.RLPItem[] memory list) internal pure returns (ValidatorData memory VData) {
        VData.TimeMs = uint64(list[uint8(HeaderProperty.TimeMs)].toUint());
        VData.NextValidators = _decodeNextValidators(list[uint8(HeaderProperty.NextValidators)]);
        VData.NextValidatorPowers = _decodeNextValidatorPowers(list[uint8(HeaderProperty.NextValidatorPowers)]);

        VData.LastCommitHash = bytes32(list[uint8(HeaderProperty.LastCommitHash)].toUint());
    }

    function decodeCommit(RLPReader.RLPItem memory commitItem) internal pure returns (Commit memory commit) {
        require(commitItem.isList(), "no list");
        RLPReader.RLPItem[] memory list = commitItem.toList();
        commit.Height = uint64(property(list, 0).toUint());
        commit.Round = uint32(property(list, 1).toUint());
        commit.BlockID = bytes32(property(list, 2).toUint());

        require(property(list, 3).isList(), "commit.Signatures should be list");
        RLPReader.RLPItem[] memory csList = property(list, 3).toList();
        commit.Signatures = new CommitSig[](csList.length);
        for (uint256 i = 0; i < csList.length; i++) {
            commit.Signatures[i] = decodeCommitSig(csList[i]);
        }
    }

    function decodeCommitSig(RLPReader.RLPItem memory csItem) internal pure returns (CommitSig memory cs) {
        require(csItem.isList(), "no list");
        RLPReader.RLPItem[] memory list = csItem.toList();
        cs.BlockIDFlag = uint8(property(list, 0).toUint());
        cs.ValidatorAddress = property(list, 1).toAddress();
        cs.TimestampMs = uint64(property(list, 2).toUint());
        cs.Signature = property(list, 3).toBytes();
    }

    function decodeNextValidators(bytes memory headerRLPBytes) internal pure returns (address[] memory) {
        RLPReader.RLPItem[] memory list = decodeToHeaderList(headerRLPBytes);
        return _decodeNextValidators(list[uint8(HeaderProperty.NextValidators)]);
    }

    function decodeNextValidatorPowers(bytes memory headerRLPBytes) internal pure returns (uint256[] memory array) {
        RLPReader.RLPItem[] memory list = decodeToHeaderList(headerRLPBytes);

        RLPReader.RLPItem memory _NextValidatorPowers = list[uint8(HeaderProperty.NextValidatorPowers)];

        array = _decodeNextValidatorPowers(_NextValidatorPowers);
    }

    function decodeRlp(bytes memory rlp) internal pure returns (bytes[] memory res) {
        RLPReader.RLPItem[] memory list = rlp.toRlpItem().toList();

        res = new bytes[](list.length);
        for (uint256 i = 0; i < list.length; i++) {
            res[i] = RLPReader.toBytes(list[i]);
        }
    }

    function voteSignBytes(
        Commit memory commit,
        uint256 chainId,
        uint256 idx
    ) internal pure returns (bytes memory) {
        voteForSign memory vfs;
        vfs.Type = SignedMsgType.PrecommitType;
        vfs.Height = commit.Height;
        vfs.Round = commit.Round;
        if (commit.Signatures[idx].BlockIDFlag == BLOCK_FLAG_COMMIT) {
            vfs.BlockID = commit.BlockID;
        }

        vfs.TimestampMs = commit.Signatures[idx].TimestampMs;
        vfs.ChainID = string(abi.encodePacked("evm_", chainId.toString()));
        return encodeToRlpBytes(vfs);
    }

    function headerHash(bytes memory blockRlpBytes) internal pure returns (bytes32) {
        // TODO
    }

    function encodeToRlpBytes(voteForSign memory vfs) internal pure returns (bytes memory) {
        bytes[] memory List = new bytes[](6);
        List[0] = RLPEncode.encodeUint(uint256(vfs.Type));
        List[1] = RLPEncode.encodeUint(uint256(vfs.Height));
        List[2] = RLPEncode.encodeUint(uint256(vfs.Round));
        List[3] = RLPEncode.encodeUint(uint256(vfs.BlockID));
        List[4] = RLPEncode.encodeUint(uint256(vfs.TimestampMs));
        List[5] = RLPEncode.encodeString(vfs.ChainID);

        return RLPEncode.encodeList(List);
    }

    function msgHash(bytes memory signMsg) internal pure returns (bytes32) {
        return signMsg.toRlpItem().rlpBytesKeccak256();
    }

    function property(RLPReader.RLPItem[] memory list, uint8 index) internal pure returns (RLPReader.RLPItem memory) {
        return list[index];
    }

    function _decodeNextValidators(RLPReader.RLPItem memory item) private pure returns (address[] memory array) {
        array = item.toAddressArray();
    }

    function _decodeNextValidatorPowers(RLPReader.RLPItem memory item) private pure returns (uint256[] memory array) {
        array = item.toUintArray();

        return array;
    }
}


/** 
 *  SourceUnit: /Users/chenyanlong/Work/staking-contracts/contracts/LightClient.sol
*/

pragma solidity ^0.8.0;

////import "./lib/BlockDecoder.sol";
////import "@openzeppelin/contracts/access/Ownable.sol";
////import "./interfaces/IStaking.sol";
////import "./interfaces/ILightClient.sol";

contract LightClient is ILightClient, Ownable {
    using BlockDecoder for bytes;
    using BlockDecoder for uint256[];

    // Current validator info from side-chain's epoch header
    // Use to verify commit if the side-chain does not change validators.
    uint8 public constant TOTAL_EPOCH = 4;
    Epoch[TOTAL_EPOCH] epochs;

    uint256 public override curEpochIdx;
    uint256 public override curEpochHeight;
    uint256 public override epochPeriod;

    IStaking public staking;

    constructor(uint256 _epochPeriod, address _staking) {
        epochPeriod = _epochPeriod;
        staking = IStaking(_staking);
    }

    function _epochPosition(uint256 _epochIdx) internal pure returns (uint256) {
        return _epochIdx % TOTAL_EPOCH;
    }

    function initEpoch(
        address[] memory _epochSigners,
        uint256[] memory _epochVotingPowers,
        uint256 _height,
        bytes32
    ) public virtual override onlyOwner {
        _createEpochValidators(1, _height, _epochSigners, _epochVotingPowers);
    }

    /**
     * Create validator set for an epoch
     */
    function submitHead(
        bytes memory _epochHeaderBytes,
        bytes memory commitBytes,
        bool lookByIndex
    ) public virtual override {
        //1. verify epoch header
        uint256 position = _epochPosition(curEpochIdx);
        (uint256 height, , ) = BlockDecoder.verifyHeader(
            _epochHeaderBytes,
            commitBytes,
            epochs[position].curEpochVals,
            epochs[position].curVotingPowers,
            lookByIndex
        );

        address[] memory vals = _epochHeaderBytes.decodeNextValidators();
        uint256[] memory powers = _epochHeaderBytes.decodeNextValidatorPowers();
        require(
            vals.length > 0 && powers.length > 0,
            "both NextValidators and NextValidatorPowers should not be empty"
        );

        require(curEpochHeight + epochPeriod == height, "incorrect height");
        _createEpochValidators(curEpochIdx + 1, height, vals, powers);
    }

    /**
     * Create validator set for an epoch
     * @param _epochIdx the index of epoch to propose validators
     */
    function _createEpochValidators(
        uint256 _epochIdx,
        uint256 _epochHeight,
        address[] memory _epochSigners,
        uint256[] memory _epochVotingPowers
    ) internal {
        require(_epochIdx > curEpochIdx, "epoch too old");

        // Check if the epoch validators are from proposed.
        // This means that the 2/3+ validators have accepted the proposed validators from the contract.
        require(_epochSigners.length == _epochVotingPowers.length, "incorrect length");

        uint256 position = _epochPosition(_epochIdx);
        curEpochIdx = _epochIdx;
        curEpochHeight = _epochHeight;
        epochs[position].curEpochVals = _epochSigners;
        epochs[position].curVotingPowers = _epochVotingPowers;

        // TODO: add rewards to validators
    }

    function getCurrentEpoch()
        public
        view
        override
        returns (
            uint256,
            address[] memory,
            uint256[] memory
        )
    {
        uint256 position = _epochPosition(curEpochIdx);
        return (curEpochIdx, epochs[position].curEpochVals, epochs[position].curVotingPowers);
    }

    function setEpochPeriod(uint256 _epochPeriod) external override onlyOwner {
        epochPeriod = _epochPeriod;
    }

    function getNextEpochHeight() external view override returns (uint256 height) {
        return curEpochHeight + epochPeriod;
    }

    function getStaking() external view override returns (address) {
        return address(staking);
    }

    function proposedValidators() external view override returns (address[] memory, uint256[] memory) {
        return staking.proposedValidators();
    }
}