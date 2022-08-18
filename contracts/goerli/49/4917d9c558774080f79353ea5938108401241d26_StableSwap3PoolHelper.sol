// SPDX-License-Identifier: Apache-2.0
pragma solidity ^0.8.0;
import {RLPReader} from "./RLPReader.sol";
import {StateProofVerifier} from "./StateProofVerifier.sol";

contract StableSwap3PoolHelper {
    using RLPReader for bytes;
    using RLPReader for RLPReader.RLPItem;
    event LogStep(uint256);

    uint256 internal constant N_COINS = 3;

    /// @dev keccak256(abi.encodePacked(uint256(1)))
    bytes32 public constant BALANCES_0_POS =
        0xb10e2d527612073b26eecdfd717e6a320cf44b4afac2b0732d9fcbe2b7fa0cf6;
    bytes32 public constant BALANCES_1_POS =
        0xb10e2d527612073b26eecdfd717e6a320cf44b4afac2b0732d9fcbe2b7fa0cf7;
    bytes32 public constant BALANCES_2_POS =
        0xb10e2d527612073b26eecdfd717e6a320cf44b4afac2b0732d9fcbe2b7fa0cf8;
    bytes32 public constant INITIAL_A_POS = bytes32(uint256(6));
    bytes32 public constant FUTURE_A_POS = bytes32(uint256(7));
    bytes32 public constant INITIAL_A_TIME_POS = bytes32(uint256(8));
    bytes32 public constant FUTURE_A_TIME_POS = bytes32(uint256(9));

    bytes32 public constant BALANCES_0_POS_HASH =
        keccak256(abi.encodePacked(BALANCES_0_POS));
    bytes32 public constant BALANCES_1_POS_HASH =
        keccak256(abi.encodePacked(BALANCES_1_POS));
    bytes32 public constant BALANCES_2_POS_HASH =
        keccak256(abi.encodePacked(BALANCES_2_POS));
    bytes32 public constant INITIAL_A_POS_HASH =
        keccak256(abi.encodePacked(INITIAL_A_POS));
    bytes32 public constant FUTURE_A_POS_HASH =
        keccak256(abi.encodePacked(FUTURE_A_POS));
    bytes32 public constant INITIAL_A_TIME_POS_HASH =
        keccak256(abi.encodePacked(INITIAL_A_TIME_POS));
    bytes32 public constant FUTURE_A_TIME_POS_HASH =
        keccak256(abi.encodePacked(FUTURE_A_TIME_POS));

    struct PoolStorage {
        uint256[N_COINS] balances;
        uint256 initialA;
        uint256 futureA;
        uint256 initialATime;
        uint256 futureATime;
    }

    function get_virtual_price(
        PoolStorage memory poolStorage,
        uint256 tokenSupply,
        uint256 blockTimestamp
    ) public pure returns (uint256) {
        uint256 d = _get_D(
            _xp(poolStorage.balances),
            _A(
                blockTimestamp,
                poolStorage.futureATime,
                poolStorage.futureA,
                poolStorage.initialA,
                poolStorage.initialATime
            )
        );
        return (d * 1e18) / tokenSupply;
    }

    function verifyAccount(
        bytes32 poolAddressHash,
        bytes32 headerRoot,
        bytes memory proofRlpBytes
    )public returns (PoolStorage memory poolStorage) {

        RLPReader.RLPItem[] memory proofs = proofRlpBytes.toRlpItem().toList();
        emit LogStep(proofs.length);

        StateProofVerifier.Account memory curve3PoolAccount = StateProofVerifier
            .extractAccountFromProof(
                poolAddressHash,
                headerRoot,
                proofs[0].toList()
            );

        StateProofVerifier.SlotValue memory daiBalance = StateProofVerifier
            .extractSlotValueFromProof(
                BALANCES_0_POS_HASH,
                curve3PoolAccount.storageRoot,
                proofs[3].toList()[0].toList()
            );

        if (!daiBalance.exists) {
            revert("daiBalance");
        }

        emit LogStep(daiBalance.value);
    }

    function verifyAndExtractStorage(
        bytes32 poolAddressHash,
        bytes32 headerRoot,
        RLPReader.RLPItem memory accountProof,
        RLPReader.RLPItem[] memory proofs
    ) public pure returns (PoolStorage memory poolStorage) {
        StateProofVerifier.Account memory curve3PoolAccount = StateProofVerifier
            .extractAccountFromProof(
                poolAddressHash,
                headerRoot,
                accountProof.toList()
            );

        if (!curve3PoolAccount.exists) {
            // revert
            revert("curve3PoolAccount");
        }

        StateProofVerifier.SlotValue memory daiBalance = StateProofVerifier
            .extractSlotValueFromProof(
                BALANCES_0_POS_HASH,
                curve3PoolAccount.storageRoot,
                proofs[0].toList()
            );

        if (!daiBalance.exists) {
            revert("daiBalance");
        }
        poolStorage.balances[0] = daiBalance.value;

        StateProofVerifier.SlotValue memory usdcBalance = StateProofVerifier
            .extractSlotValueFromProof(
                BALANCES_1_POS_HASH,
                curve3PoolAccount.storageRoot,
                proofs[1].toList()
            );

        if (!usdcBalance.exists) {
            revert("usdcBalance");
        }
        poolStorage.balances[1] = usdcBalance.value;

        StateProofVerifier.SlotValue memory usdtBalance = StateProofVerifier
            .extractSlotValueFromProof(
                BALANCES_2_POS_HASH,
                curve3PoolAccount.storageRoot,
                proofs[2].toList()
            );

        if (!usdtBalance.exists) {
            revert("usdtBalance");
        }
        poolStorage.balances[2] = usdtBalance.value;

        StateProofVerifier.SlotValue memory initialA = StateProofVerifier
            .extractSlotValueFromProof(
                INITIAL_A_POS_HASH,
                curve3PoolAccount.storageRoot,
                proofs[3].toList()
            );

        if (!initialA.exists) {
            revert("initialA");
        }
        poolStorage.initialA = initialA.value;

        StateProofVerifier.SlotValue memory futureA = StateProofVerifier
            .extractSlotValueFromProof(
                FUTURE_A_POS_HASH,
                curve3PoolAccount.storageRoot,
                proofs[4].toList()
            );

        if (!futureA.exists) {
            revert("futureA");
        }
        poolStorage.futureA = futureA.value;

        StateProofVerifier.SlotValue memory initialATime = StateProofVerifier
            .extractSlotValueFromProof(
                INITIAL_A_TIME_POS_HASH,
                curve3PoolAccount.storageRoot,
                proofs[5].toList()
            );

        if (!initialATime.exists) {
            revert("initialATime");
        }
        poolStorage.initialATime = initialATime.value;

        StateProofVerifier.SlotValue memory futureATime = StateProofVerifier
            .extractSlotValueFromProof(
                FUTURE_A_TIME_POS_HASH,
                curve3PoolAccount.storageRoot,
                proofs[6].toList()
            );

        if (!futureATime.exists) {
            revert("futureATime");
        }
        poolStorage.futureATime = futureATime.value;
    }

    function _A(
        uint256 blockTimeStamp,
        uint256 futureATime,
        uint256 futureA,
        uint256 initialA,
        uint256 initialATime
    ) private pure returns (uint256) {
        uint256 t1 = futureATime;
        uint256 a1 = futureA;
        if (blockTimeStamp < t1) {
            uint256 t0 = initialATime;
            uint256 a0 = initialA;
            // Expressions in uint256 cannot have negative numbers, thus "if"
            if (a1 > a0) {
                return a0 + ((a1 - a0) * (blockTimeStamp - t0)) / (t1 - t0);
            } else {
                return a0 - ((a0 - a1) * (blockTimeStamp - t0)) / (t1 - t0);
            }
        } else {
            // when t1 == 0 or blockTimeStamp >= t1
            return a1;
        }
    }

    function _xp(uint256[3] memory balances)
        private
        pure
        returns (uint256[3] memory)
    {
        uint256[N_COINS] memory result = [
            uint256(1000000000000000000),
            uint256(1000000000000000000000000000000),
            uint256(1000000000000000000000000000000)
        ];
        for (uint256 i = 0; i < N_COINS; ++i) {
            result[i] = (result[i] * balances[i]) / 1e18;
        }
        return result;
    }

    function _get_D(uint256[N_COINS] memory xp, uint256 amp)
        private
        pure
        returns (uint256)
    {
        uint256 s = 0;
        for (uint256 x = 0; x < xp.length; ++x) s += xp[x];

        if (s == 0) return 0;

        uint256 prevD = 0;
        uint256 d = s;
        uint256 ann = amp * N_COINS;
        for (uint256 i = 0; i < 255; ++i) {
            uint256 d_p = d;
            for (uint256 x = 0; x < xp.length; ++x)
                d_p = (d_p * d) / (xp[x] * N_COINS);
            prevD = d;
            d =
                ((ann * s + d_p * N_COINS) * d) /
                ((ann - 1) * d + (N_COINS + 1) * d_p);
            if (d > prevD) {
                if (d - prevD <= 1) break;
            } else {
                if (prevD - d <= 1) break;
            }
        }
        return d;
    }
}

// SPDX-License-Identifier: Apache-2.0

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
        unchecked {
            require(hasNext(self));

            uint256 ptr = self.nextPtr;
            uint256 itemLength = _itemLength(ptr);
            self.nextPtr = ptr + itemLength;
            return RLPItem(itemLength, ptr);
        }
    }

    /*
     * @dev Returns true if the iteration has more elements.
     * @param self The iterator.
     * @return true if the iteration has more elements.
     */
    function hasNext(Iterator memory self) internal pure returns (bool) {
        unchecked {
            RLPItem memory item = self.item;
            return self.nextPtr < item.memPtr + item.len;
        }
    }

    /*
     * @param item RLP encoded bytes
     */
    function toRlpItem(bytes memory item)
        internal
        pure
        returns (RLPItem memory)
    {
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
    function iterator(RLPItem memory self)
        internal
        pure
        returns (Iterator memory)
    {
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
    function toList(RLPItem memory item)
        internal
        pure
        returns (RLPItem[] memory)
    {
        require(isList(item));
        unchecked {
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
    }

    // @return indicator whether encoded payload is a list. negate this function call for isData.
    function isList(RLPItem memory item) internal pure returns (bool) {
        unchecked {
            if (item.len == 0) return false;

            uint8 byte0;
            uint256 memPtr = item.memPtr;
            assembly {
                byte0 := byte(0, mload(memPtr))
            }

            if (byte0 < LIST_SHORT_START) return false;
            return true;
        }
    }

    /*
     * @dev A cheaper version of keccak256(toRlpBytes(item)) that avoids copying memory.
     * @return keccak256 hash of RLP encoded bytes.
     */
    function rlpBytesKeccak256(RLPItem memory item)
        internal
        pure
        returns (bytes32)
    {
        unchecked {
            uint256 ptr = item.memPtr;
            uint256 len = item.len;
            bytes32 result;
            assembly {
                result := keccak256(ptr, len)
            }
            return result;
        }
    }

    /*
     * @dev A cheaper version of keccak256(toBytes(item)) that avoids copying memory.
     * @return keccak256 hash of the unerlying data.
     */
    function dataKeccak256(RLPItem memory item)
        internal
        pure
        returns (bytes32)
    {
        unchecked {
            uint256 offset = _payloadOffset(item.memPtr);
            uint256 ptr = item.memPtr + offset;
            uint256 len = item.len - offset;
            bytes32 result;
            assembly {
                result := keccak256(ptr, len)
            }
            return result;
        }
    }

    /** RLPItem conversions into data types **/

    // @returns raw rlp encoding in bytes
    function toRlpBytes(RLPItem memory item)
        internal
        pure
        returns (bytes memory)
    {
        unchecked {
            bytes memory result = new bytes(item.len);
            if (result.length == 0) return result;

            uint256 ptr;
            assembly {
                ptr := add(0x20, result)
            }

            copy(item.memPtr, ptr, item.len);
            return result;
        }
    }

    // any non-zero byte except "0x80" is considered true
    function toBoolean(RLPItem memory item) internal pure returns (bool) {
        require(item.len == 1);
        unchecked {
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
    }

    function toAddress(RLPItem memory item) internal pure returns (address) {
        // 1 byte for the length prefix
        unchecked {
            require(item.len == 21);

            return address(uint160(toUint(item)));
        }
    }

    function toUint(RLPItem memory item) internal pure returns (uint256) {
        require(item.len > 0 && item.len <= 33);

        unchecked {
            uint256 offset = _payloadOffset(item.memPtr);
            uint256 len = item.len - offset;

            uint256 result;
            uint256 memPtr = item.memPtr + offset;
            assembly {
                result := mload(memPtr)

                // shift to the correct location if necessary
                if lt(len, 32) {
                    result := div(result, exp(256, sub(32, len)))
                }
            }

            return result;
        }
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

        unchecked {
            if (byte0 < STRING_SHORT_START) itemLen = 1;
            else if (byte0 < STRING_LONG_START)
                itemLen = byte0 - STRING_SHORT_START + 1;
            else if (byte0 < LIST_SHORT_START) {
                assembly {
                    let byteLen := sub(byte0, 0xb7) // # of bytes the actual length is
                    memPtr := add(memPtr, 1) // skip over the first byte

                    /* 32 byte word size */
                    let dataLen := div(
                        mload(memPtr),
                        exp(256, sub(32, byteLen))
                    ) // right shifting to get the len
                    itemLen := add(dataLen, add(byteLen, 1))
                }
            } else if (byte0 < LIST_LONG_START) {
                itemLen = byte0 - LIST_SHORT_START + 1;
            } else {
                assembly {
                    let byteLen := sub(byte0, 0xf7)
                    memPtr := add(memPtr, 1)

                    let dataLen := div(
                        mload(memPtr),
                        exp(256, sub(32, byteLen))
                    ) // right shifting to the correct length
                    itemLen := add(dataLen, add(byteLen, 1))
                }
            }
        }

        return itemLen;
    }

    // @return number of bytes until the data
    function _payloadOffset(uint256 memPtr) private pure returns (uint256) {
        unchecked {
            uint256 byte0;
            assembly {
                byte0 := byte(0, mload(memPtr))
            }

            if (byte0 < STRING_SHORT_START) return 0;
            else if (
                byte0 < STRING_LONG_START ||
                (byte0 >= LIST_SHORT_START && byte0 < LIST_LONG_START)
            ) return 1;
            else if (byte0 < LIST_SHORT_START)
                // being explicit
                return byte0 - (STRING_LONG_START - 1) + 1;
            else return byte0 - (LIST_LONG_START - 1) + 1;
        }
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
        unchecked {
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
}

// SPDX-License-Identifier: Apache-2.0
pragma solidity ^0.8.0;

import {RLPReader} from "./RLPReader.sol";
import {MerklePatriciaProofVerifier} from "./MerklePatriciaProofVerifier.sol";

library StateProofVerifier {
    using RLPReader for RLPReader.RLPItem;
    using RLPReader for bytes;

    uint256 constant HEADER_STATE_ROOT_INDEX = 3;
    uint256 constant HEADER_NUMBER_INDEX = 8;
    uint256 constant HEADER_TIMESTAMP_INDEX = 11;

    struct BlockHeader {
        bytes32 hash;
        bytes32 stateRootHash;
        uint256 number;
        uint256 timestamp;
    }

    struct Account {
        bool exists;
        uint256 nonce;
        uint256 balance;
        bytes32 storageRoot;
        bytes32 codeHash;
    }

    struct SlotValue {
        bool exists;
        uint256 value;
    }

    function verifyStateProof(
        bytes32 _addressHash, // keccak256(abi.encodePacked(address))
        bytes32[] memory _slotHashes, // keccak256(abi.encodePacked(uint256(slotIndex)))
        bytes memory _blockHeaderRlpBytes, // RLP([parentHash, sha3Uncles, miner, ...])
        bytes memory _proofRlpBytes // RLP([accountProof, [slotProofs...]])
    )
        internal
        pure
        returns (
            BlockHeader memory blockHeader,
            Account memory account,
            SlotValue[] memory slots
        )
    {
        blockHeader = parseBlockHeader(_blockHeaderRlpBytes);

        RLPReader.RLPItem[] memory proofs = _proofRlpBytes.toRlpItem().toList();
        require(proofs.length == 2);

        account = extractAccountFromProof(
            _addressHash,
            blockHeader.stateRootHash,
            proofs[0].toList()
        );

        slots = new SlotValue[](_slotHashes.length);

        if (!account.exists || _slotHashes.length == 0) {
            return (blockHeader, account, slots);
        }

        RLPReader.RLPItem[] memory slotProofs = proofs[1].toList();
        require(slotProofs.length == _slotHashes.length);

        for (uint256 i = 0; i < _slotHashes.length; ++i) {
            RLPReader.RLPItem[] memory slotProof = slotProofs[i].toList();
            slots[i] = extractSlotValueFromProof(
                _slotHashes[i],
                account.storageRoot,
                slotProof
            );
        }

        return (blockHeader, account, slots);
    }

    function verifyBlockHeader(bytes memory _headerRlpBytes)
        internal
        view
        returns (BlockHeader memory)
    {
        BlockHeader memory header = parseBlockHeader(_headerRlpBytes);
        // ensure that the block is actually in the blockchain
        require(header.hash == blockhash(header.number), "blockhash mismatch");
        return header;
    }

    function parseBlockHeader(bytes memory _headerRlpBytes)
        internal
        pure
        returns (BlockHeader memory)
    {
        BlockHeader memory result;
        RLPReader.RLPItem[] memory headerFields = _headerRlpBytes
            .toRlpItem()
            .toList();

        result.stateRootHash = bytes32(
            headerFields[HEADER_STATE_ROOT_INDEX].toUint()
        );
        result.number = headerFields[HEADER_NUMBER_INDEX].toUint();
        result.timestamp = headerFields[HEADER_TIMESTAMP_INDEX].toUint();
        result.hash = keccak256(_headerRlpBytes);

        return result;
    }

    function extractAccountFromProof(
        bytes32 _addressHash, // keccak256(abi.encodePacked(address))
        bytes32 _stateRootHash,
        RLPReader.RLPItem[] memory _proof
    ) internal pure returns (Account memory) {
        bytes memory acctRlpBytes = MerklePatriciaProofVerifier
            .extractProofValue(
                _stateRootHash,
                abi.encodePacked(_addressHash),
                _proof
            );

        Account memory account;

        if (acctRlpBytes.length == 0) {
            return account;
        }

        RLPReader.RLPItem[] memory acctFields = acctRlpBytes
            .toRlpItem()
            .toList();
        require(acctFields.length == 4);

        account.exists = true;
        account.nonce = acctFields[0].toUint();
        account.balance = acctFields[1].toUint();
        account.storageRoot = bytes32(acctFields[2].toUint());
        account.codeHash = bytes32(acctFields[3].toUint());

        return account;
    }

    function extractSlotValueFromProof(
        bytes32 _slotHash,
        bytes32 _storageRootHash,
        RLPReader.RLPItem[] memory _proof
    ) internal pure returns (SlotValue memory) {
        bytes memory valueRlpBytes = MerklePatriciaProofVerifier
            .extractProofValue(
                _storageRootHash,
                abi.encodePacked(_slotHash),
                _proof
            );

        SlotValue memory value;

        if (valueRlpBytes.length != 0) {
            value.exists = true;
            value.value = valueRlpBytes.toRlpItem().toUint();
        }

        return value;
    }
}

// SPDX-License-Identifier: MIT

/**
 * Copied from https://github.com/lorenzb/proveth/blob/c74b20e/onchain/ProvethVerifier.sol
 * with minor styling corrections.
 */
pragma solidity ^0.8.0;

import {RLPReader} from "./RLPReader.sol";

library MerklePatriciaProofVerifier {
    using RLPReader for RLPReader.RLPItem;
    using RLPReader for bytes;

    /// @dev Validates a Merkle-Patricia-Trie proof.
    ///      If the proof proves the inclusion of some key-value pair in the
    ///      trie, the value is returned. Otherwise, i.e. if the proof proves
    ///      the exclusion of a key from the trie, an empty byte array is
    ///      returned.
    /// @param rootHash is the Keccak-256 hash of the root node of the MPT.
    /// @param path is the key of the node whose inclusion/exclusion we are
    ///        proving.
    /// @param stack is the stack of MPT nodes (starting with the root) that
    ///        need to be traversed during verification.
    /// @return value whose inclusion is proved or an empty byte array for
    ///         a proof of exclusion
    function extractProofValue(
        bytes32 rootHash,
        bytes memory path,
        RLPReader.RLPItem[] memory stack
    ) internal pure returns (bytes memory value) {
        bytes memory mptKey = _decodeNibbles(path, 0);
        uint256 mptKeyOffset = 0;

        bytes32 nodeHashHash;
        RLPReader.RLPItem[] memory node;

        RLPReader.RLPItem memory rlpValue;

        if (stack.length == 0) {
            // Root hash of empty Merkle-Patricia-Trie
            require(
                rootHash ==
                    0x56e81f171bcc55a6ff8345e692c0f86e5b48e01b996cadc001622fb5e363b421
            );
            return new bytes(0);
        }

        // Traverse stack of nodes starting at root.
        for (uint256 i = 0; i < stack.length; i++) {
            // We use the fact that an rlp encoded list consists of some
            // encoding of its length plus the concatenation of its
            // *rlp-encoded* items.

            // The root node is hashed with Keccak-256 ...
            if (i == 0 && rootHash != stack[i].rlpBytesKeccak256()) {
                revert();
            }
            // ... whereas all other nodes are hashed with the MPT
            // hash function.
            if (i != 0 && nodeHashHash != _mptHashHash(stack[i])) {
                revert();
            }
            // We verified that stack[i] has the correct hash, so we
            // may safely decode it.
            node = stack[i].toList();

            if (node.length == 2) {
                // Extension or Leaf node

                bool isLeaf;
                bytes memory nodeKey;
                (isLeaf, nodeKey) = _merklePatriciaCompactDecode(
                    node[0].toBytes()
                );

                uint256 prefixLength = _sharedPrefixLength(
                    mptKeyOffset,
                    mptKey,
                    nodeKey
                );
                mptKeyOffset += prefixLength;

                if (prefixLength < nodeKey.length) {
                    // Proof claims divergent extension or leaf. (Only
                    // relevant for proofs of exclusion.)
                    // An Extension/Leaf node is divergent iff it "skips" over
                    // the point at which a Branch node should have been had the
                    // excluded key been included in the trie.
                    // Example: Imagine a proof of exclusion for path [1, 4],
                    // where the current node is a Leaf node with
                    // path [1, 3, 3, 7]. For [1, 4] to be included, there
                    // should have been a Branch node at [1] with a child
                    // at 3 and a child at 4.

                    // Sanity check
                    if (i < stack.length - 1) {
                        // divergent node must come last in proof
                        revert();
                    }

                    return new bytes(0);
                }

                if (isLeaf) {
                    // Sanity check
                    if (i < stack.length - 1) {
                        // leaf node must come last in proof
                        revert();
                    }

                    if (mptKeyOffset < mptKey.length) {
                        return new bytes(0);
                    }

                    rlpValue = node[1];
                    return rlpValue.toBytes();
                } else {
                    // extension
                    // Sanity check
                    if (i == stack.length - 1) {
                        // shouldn't be at last level
                        revert();
                    }

                    if (!node[1].isList()) {
                        // rlp(child) was at least 32 bytes. node[1] contains
                        // Keccak256(rlp(child)).
                        nodeHashHash = node[1].dataKeccak256();
                    } else {
                        // rlp(child) was less than 32 bytes. node[1] contains
                        // rlp(child).
                        nodeHashHash = node[1].rlpBytesKeccak256();
                    }
                }
            } else if (node.length == 17) {
                // Branch node

                if (mptKeyOffset != mptKey.length) {
                    // we haven't consumed the entire path, so we need to look at a child
                    uint8 nibble = uint8(mptKey[mptKeyOffset]);
                    mptKeyOffset += 1;
                    if (nibble >= 16) {
                        // each element of the path has to be a nibble
                        revert();
                    }

                    if (_isEmptyBytesequence(node[nibble])) {
                        // Sanity
                        if (i != stack.length - 1) {
                            // leaf node should be at last level
                            revert();
                        }

                        return new bytes(0);
                    } else if (!node[nibble].isList()) {
                        nodeHashHash = node[nibble].dataKeccak256();
                    } else {
                        nodeHashHash = node[nibble].rlpBytesKeccak256();
                    }
                } else {
                    // we have consumed the entire mptKey, so we need to look at what's contained in this node.

                    // Sanity
                    if (i != stack.length - 1) {
                        // should be at last level
                        revert();
                    }

                    return node[16].toBytes();
                }
            }
        }
    }

    /// @dev Computes the hash of the Merkle-Patricia-Trie hash of the RLP item.
    ///      Merkle-Patricia-Tries use a weird "hash function" that outputs
    ///      *variable-length* hashes: If the item is shorter than 32 bytes,
    ///      the MPT hash is the item. Otherwise, the MPT hash is the
    ///      Keccak-256 hash of the item.
    ///      The easiest way to compare variable-length byte sequences is
    ///      to compare their Keccak-256 hashes.
    /// @param item The RLP item to be hashed.
    /// @return Keccak-256(MPT-hash(item))
    function _mptHashHash(RLPReader.RLPItem memory item)
        private
        pure
        returns (bytes32)
    {
        if (item.len < 32) {
            return item.rlpBytesKeccak256();
        } else {
            return keccak256(abi.encodePacked(item.rlpBytesKeccak256()));
        }
    }

    function _isEmptyBytesequence(RLPReader.RLPItem memory item)
        private
        pure
        returns (bool)
    {
        if (item.len != 1) {
            return false;
        }
        uint8 b;
        uint256 memPtr = item.memPtr;
        assembly {
            b := byte(0, mload(memPtr))
        }
        return b == 0x80; /* empty byte string */
    }

    function _merklePatriciaCompactDecode(bytes memory compact)
        private
        pure
        returns (bool isLeaf, bytes memory nibbles)
    {
        require(compact.length > 0);
        uint256 first_nibble = (uint8(compact[0]) >> 4) & 0xF;
        uint256 skipNibbles;
        if (first_nibble == 0) {
            skipNibbles = 2;
            isLeaf = false;
        } else if (first_nibble == 1) {
            skipNibbles = 1;
            isLeaf = false;
        } else if (first_nibble == 2) {
            skipNibbles = 2;
            isLeaf = true;
        } else if (first_nibble == 3) {
            skipNibbles = 1;
            isLeaf = true;
        } else {
            // Not supposed to happen!
            revert();
        }
        return (isLeaf, _decodeNibbles(compact, skipNibbles));
    }

    function _decodeNibbles(bytes memory compact, uint256 skipNibbles)
        private
        pure
        returns (bytes memory nibbles)
    {
        require(compact.length > 0);

        uint256 length = compact.length * 2;
        require(skipNibbles <= length);
        length -= skipNibbles;

        nibbles = new bytes(length);
        uint256 nibblesLength = 0;

        for (uint256 i = skipNibbles; i < skipNibbles + length; i += 1) {
            if (i % 2 == 0) {
                nibbles[nibblesLength] = bytes1(
                    (uint8(compact[i / 2]) >> 4) & 0xF
                );
            } else {
                nibbles[nibblesLength] = bytes1(
                    (uint8(compact[i / 2]) >> 0) & 0xF
                );
            }
            nibblesLength += 1;
        }

        assert(nibblesLength == nibbles.length);
    }

    function _sharedPrefixLength(
        uint256 xsOffset,
        bytes memory xs,
        bytes memory ys
    ) private pure returns (uint256) {
        uint256 i;
        for (i = 0; i + xsOffset < xs.length && i < ys.length; i++) {
            if (xs[i + xsOffset] != ys[i]) {
                return i;
            }
        }
        return i;
    }
}