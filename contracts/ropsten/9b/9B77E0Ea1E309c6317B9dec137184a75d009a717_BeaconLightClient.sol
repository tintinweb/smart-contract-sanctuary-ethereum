// SPDX-License-Identifier: MIT
// Etherum beacon light client.
// Current arthitecture diverges from spec's proposed updated splitting them into:
// - Finalized header updates: To import a recent finalized header signed by a known sync committee by `import_finalized_header`.
// - Sync period updates: To advance to the next committee by `import_next_sync_committee`.
//
// To stay synced to the current sync period it needs:
// - Get finalized_header_update and sync_period_update at least once per period.
//
// To get light-client best finalized update at period N:
// - Fetch best finalized block's sync_aggregate_header in period N
// - Fetch parent_block/attested_block by sync_aggregate_header's parent_root
// - Fetch finalized_checkpoint_root and finalized_checkpoint_root_witness in attested_block
// - Fetch finalized_header by finalized_checkpoint_root
//
// - sync_aggregate -> parent_block/attested_block -> finalized_checkpoint -> finalized_header
//
// To get light-client sync period update at period N:
// - Fetch the finalized_header in light-client
// - Fetch the finalized_block by finalized_header.slot
// - Fetch next_sync_committee and next_sync_committee_witness in finalized_block
//
// - finalized_header -> next_sync_committee
//
// ```
//                       Finalized               Block   Sync
//                       Checkpoint              Header  Aggreate
// ----------------------|-----------------------|-------|---------> time
//                        <---------------------   <----
//                         finalizes               signs
// ```
//
// To initialize, it needs:
// - BLS verify contract
// - Trust finalized_header
// - current_sync_committee of the trust finalized_header
// - genesis_validators_root of genesis state
//
// When to trigger a committee update sync:
//
//  period 0         period 1         period 2
// -|----------------|----------------|----------------|-> time
//              | now
//               - active current_sync_committee
//               - known next_sync_committee, signed by current_sync_committee
//
//
// next_sync_committee can be imported at any time of the period, not strictly at the period borders.
// - No need to query for period 0 next_sync_committee until the end of period 0
// - After the import next_sync_committee of period 0, populate period 1's committee

pragma solidity 0.8.9;

import "../../utils/Bitfield.sol";
import "../../spec/BeaconChain.sol";

interface IBLS {
    function fast_aggregate_verify(
        bytes[] calldata pubkeys,
        bytes calldata message,
        bytes calldata signature
    ) external pure returns (bool);
}

contract BeaconLightClient is BeaconChain, Bitfield {
    // address(0x0800)
    address private immutable BLS_PRECOMPILE;

    bytes32 public immutable GENESIS_VALIDATORS_ROOT;

    // A bellatrix beacon state has 25 fields, with a depth of 5.
    // | field                               | gindex | depth |
    // | ----------------------------------- | ------ | ----- |
    // | next_sync_committee                 | 55     | 5     |
    // | finalized_checkpoint_root           | 105    | 6     |
    uint64 constant private NEXT_SYNC_COMMITTEE_INDEX = 55;
    uint64 constant private NEXT_SYNC_COMMITTEE_DEPTH = 5;

    uint64 constant private FINALIZED_CHECKPOINT_ROOT_INDEX = 105;
    uint64 constant private FINALIZED_CHECKPOINT_ROOT_DEPTH = 6;

    uint64 constant private EPOCHS_PER_SYNC_COMMITTEE_PERIOD = 256;
    uint64 constant private SLOTS_PER_EPOCH = 32;

    bytes4 constant private DOMAIN_SYNC_COMMITTEE = 0x07000000;

    struct SyncAggregate {
        bytes32[2] sync_committee_bits;
        bytes sync_committee_signature;
    }

    struct FinalizedHeaderUpdate {
        // The beacon block header that is attested to by the sync committee
        BeaconBlockHeader attested_header;

        // Next sync committee corresponding to the finalized header
        SyncCommittee next_sync_committee;
        bytes32[] next_sync_committee_branch;

        // Previous sync committee
        SyncCommittee prev_sync_committee;

        // The finalized beacon block header attested to by Merkle branch
        BeaconBlockHeader finalized_header;
        bytes32[] finality_branch;

        // Sync committee aggregate signature
        SyncAggregate sync_aggregate;

        // Fork version for the aggregate signature
        bytes4 fork_version;

        // Slot at which the aggregate signature was created (untrusted)
        uint64 signature_slot;
    }

    // Beacon block header that is finalized
    BeaconBlockHeader public finalized_header;

    bytes32 public prev_sync_committee_hash;

    constructor(
        address _bls,
        SyncCommittee memory _signature_sync_committee,
        BeaconBlockHeader memory _finalized_header,
        bytes32 _genesis_validators_root
    )
    {
        BLS_PRECOMPILE = _bls;
        finalized_header = _finalized_header;
        prev_sync_committee_hash = hash_tree_root(_signature_sync_committee);
        GENESIS_VALIDATORS_ROOT = _genesis_validators_root;
    }

    function state_root() public view returns (bytes32) {
        return finalized_header.state_root;
    }

    function light_client_update(FinalizedHeaderUpdate calldata update) external {
        require(is_supermajority(update.sync_aggregate.sync_committee_bits), "!supermajor");

        require(prev_sync_committee_hash == hash_tree_root(update.prev_sync_committee), "!sync_committee");

        require(
            verify_signed_header(
            update.sync_aggregate,
            update.prev_sync_committee,
            update.fork_version,
            update.attested_header),
            "!sign");

        require(
            verify_finalized_header(
            update.finalized_header,
            update.finality_branch,
            update.attested_header.state_root),
            "!finalized_header"
        );

        uint64 finalized_period = compute_sync_committee_period(finalized_header.slot);
        uint64 signature_period = compute_sync_committee_period(update.signature_slot);

        require(
            signature_period == finalized_period ||
            signature_period == finalized_period + 1,
            "!signature_period");

        require(
            verify_next_sync_committee(
            update.next_sync_committee,
            update.next_sync_committee_branch,
            update.attested_header.state_root),
            "!next_sync_committee"
        );

        prev_sync_committee_hash = hash_tree_root(update.next_sync_committee);
        finalized_header = update.finalized_header;
    }

    function verify_signed_header(
        SyncAggregate calldata sync_aggregate,
        SyncCommittee calldata sync_committee,
        bytes4 fork_version,
        BeaconBlockHeader calldata header
    ) internal view returns (bool) {
        // Verify sync committee aggregate signature
        uint participants = sum(sync_aggregate.sync_committee_bits);
        bytes[] memory participant_pubkeys = new bytes[](participants);
        uint64 n = 0;
        for (uint64 i = 0; i < SYNC_COMMITTEE_SIZE; ++i) {
            uint index = i >> 8;
            uint sindex = i / 8 % 32;
            uint offset = i % 8;
            if (uint8(sync_aggregate.sync_committee_bits[index][sindex]) >> offset & 1 == 1) {
                participant_pubkeys[n++] = sync_committee.pubkeys[i];
            }
        }

        bytes32 domain = compute_domain(DOMAIN_SYNC_COMMITTEE, fork_version, GENESIS_VALIDATORS_ROOT);
        bytes32 signing_root = compute_signing_root(header, domain);
        bytes memory message = abi.encodePacked(signing_root);
        bytes memory signature = sync_aggregate.sync_committee_signature;
        require(signature.length == BLSSIGNATURE_LENGTH, "!signature");
        return fast_aggregate_verify(participant_pubkeys, message, signature);
    }

    function verify_finalized_header(
        BeaconBlockHeader calldata header,
        bytes32[] calldata finality_branch,
        bytes32 attested_header_root
    ) internal pure returns (bool) {
        require(finality_branch.length == FINALIZED_CHECKPOINT_ROOT_DEPTH, "!finality_branch");
        bytes32 header_root = hash_tree_root(header);
        return is_valid_merkle_branch(
            header_root,
            finality_branch,
            FINALIZED_CHECKPOINT_ROOT_DEPTH,
            FINALIZED_CHECKPOINT_ROOT_INDEX,
            attested_header_root
        );
    }

    function verify_next_sync_committee(
        SyncCommittee calldata next_sync_committee,
        bytes32[] calldata next_sync_committee_branch,
        bytes32 header_state_root
    ) internal pure returns (bool) {
        require(next_sync_committee_branch.length == NEXT_SYNC_COMMITTEE_DEPTH, "!next_sync_committee_branch");
        bytes32 next_sync_committee_root = hash_tree_root(next_sync_committee);
        return is_valid_merkle_branch(
            next_sync_committee_root,
            next_sync_committee_branch,
            NEXT_SYNC_COMMITTEE_DEPTH,
            NEXT_SYNC_COMMITTEE_INDEX,
            header_state_root
        );
    }

    function is_supermajority(bytes32[2] calldata sync_committee_bits) internal pure returns (bool) {
        return sum(sync_committee_bits) * 3 >= SYNC_COMMITTEE_SIZE * 2;
    }

    function fast_aggregate_verify(bytes[] memory pubkeys, bytes memory message, bytes memory signature) internal view returns (bool valid) {
        bytes memory input = abi.encodeWithSelector(
            IBLS.fast_aggregate_verify.selector,
            pubkeys,
            message,
            signature
        );
        (bool ok, bytes memory out) = BLS_PRECOMPILE.staticcall(input);
        if (ok) {
            if (out.length == 32) {
                valid = abi.decode(out, (bool));
            }
        } else {
            if (out.length > 0) {
                assembly {
                    let returndata_size := mload(out)
                    revert(add(32, out), returndata_size)
                }
            } else {
                revert("!verify");
            }
        }
    }

    function compute_sync_committee_period(uint64 slot) internal pure returns (uint64) {
        return slot / SLOTS_PER_EPOCH / EPOCHS_PER_SYNC_COMMITTEE_PERIOD;
    }

    function sum(bytes32[2] memory x) internal pure returns (uint256) {
        return countSetBits(uint(x[0])) + countSetBits(uint(x[1]));
    }
}

// SPDX-License-Identifier: Apache-2.0

pragma solidity 0.8.9;

import "./Bits.sol";

contract Bitfield {
    using Bits for uint256;

    /// @dev Constants used to efficiently calculate the hamming weight of a bitfield. See
    /// https://en.wikipedia.org/wiki/Hamming_weight#Efficient_implementation for an explanation of those constants.
    uint256 internal constant M1 =
        0x5555555555555555555555555555555555555555555555555555555555555555;
    uint256 internal constant M2 =
        0x3333333333333333333333333333333333333333333333333333333333333333;
    uint256 internal constant M4 =
        0x0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f;
    uint256 internal constant M8 =
        0x00ff00ff00ff00ff00ff00ff00ff00ff00ff00ff00ff00ff00ff00ff00ff00ff;
    uint256 internal constant M16 =
        0x0000ffff0000ffff0000ffff0000ffff0000ffff0000ffff0000ffff0000ffff;
    uint256 internal constant M32 =
        0x00000000ffffffff00000000ffffffff00000000ffffffff00000000ffffffff;
    uint256 internal constant M64 =
        0x0000000000000000ffffffffffffffff0000000000000000ffffffffffffffff;
    uint256 internal constant M128 =
        0x00000000000000000000000000000000ffffffffffffffffffffffffffffffff;

    uint256[20] internal BIG_PRIME = [
        1000003,1000033,1000037,1000039,1000081,1000099,1000117,1000121,1000133,1000151,
        1000159,1000171,1000183,1000187,1000193,1000199,1000211,1000213,1000231,1000249
    ];

    /// @notice Draws a random number, derives an index in the bitfield, and sets the bit if it is in the `prior` and not
    /// yet set. Repeats that `n` times.
    function randomNBitsWithPriorCheck(
        uint256 seed,
        uint256 prior,
        uint256 n,
        uint256 length
    ) internal view returns (uint256 bitfield) {
        require(
            n <= countSetBits(prior),
            "invalid n"
        );
        require(
            length <= 256 && n <= length,
            "invalid length"
        );

        uint256 prime = BIG_PRIME[seed%20];
        uint256 begin = seed % 256;
        uint256 found = 0;

        for (uint256 i = 0; found < n; ++i) {
            uint8 index = uint8((prime * (begin + i)) % length);

            // require randomly seclected bit to be set in prior
            if ((prior >> index) & 1 == 1) {
                bitfield = set(bitfield, index);
                found++;
            }
        }

        return bitfield;
    }

    function createBitfield(uint8[] memory bitsToSet)
        internal
        pure
        returns (uint256 bitfield)
    {
        uint256 length = bitsToSet.length;
        for (uint256 i = 0; i < length; ++i) {
            bitfield = set(bitfield, bitsToSet[i]);
        }

        return bitfield;
    }

    /// @notice Calculates the number of set bits by using the hamming weight of the bitfield.
    /// The alogrithm below is implemented after https://en.wikipedia.org/wiki/Hamming_weight#Efficient_implementation.
    /// Further improvements are possible, see the article above.
    function countSetBits(uint256 x) internal pure returns (uint256) {
        x = (x & M1) + ((x >> 1) & M1); //put count of each  2 bits into those  2 bits
        x = (x & M2) + ((x >> 2) & M2); //put count of each  4 bits into those  4 bits
        x = (x & M4) + ((x >> 4) & M4); //put count of each  8 bits into those  8 bits
        x = (x & M8) + ((x >> 8) & M8); //put count of each 16 bits into those 16 bits
        x = (x & M16) + ((x >> 16) & M16); //put count of each 32 bits into those 32 bits
        x = (x & M32) + ((x >> 32) & M32); //put count of each 64 bits into those 64 bits
        x = (x & M64) + ((x >> 64) & M64); //put count of each 128 bits into those 128 bits
        x = (x & M128) + ((x >> 128) & M128); //put count of each 256 bits into those 256 bits
        return x;
    }

    function isSet(uint256 self, uint8 index)
        internal
        pure
        returns (bool)
    {
        return self.bit(index) == 1;
    }

    function set(uint256 self, uint8 index) internal pure returns (uint256) {
        return self.setBit(index);
    }

    function clear(uint256 self, uint8 index) internal pure returns (uint256) {
        return self.clearBit(index);
    }
}

// SPDX-License-Identifier: MIT

pragma solidity 0.8.9;

import "./MerkleProof.sol";

contract BeaconChain is MerkleProof {
    uint64 constant internal SYNC_COMMITTEE_SIZE = 512;
    uint64 constant internal BLSPUBLICKEY_LENGTH = 48;
    uint64 constant internal BLSSIGNATURE_LENGTH = 96;

    struct ForkData {
        bytes4 current_version;
        bytes32 genesis_validators_root;
    }

    struct SigningData {
        bytes32 object_root;
        bytes32 domain;
    }

    struct SyncCommittee {
        bytes[SYNC_COMMITTEE_SIZE] pubkeys;
        bytes aggregate_pubkey;
    }

    struct BeaconBlockHeader {
        uint64 slot;
        uint64 proposer_index;
        bytes32 parent_root;
        bytes32 state_root;
        bytes32 body_root;
    }

    // Return the signing root for the corresponding signing data.
    function compute_signing_root(BeaconBlockHeader memory beacon_header, bytes32 domain) internal pure returns (bytes32){
        return hash_tree_root(SigningData({
                object_root: hash_tree_root(beacon_header),
                domain: domain
            })
        );
    }

    // Return the 32-byte fork data root for the ``current_version`` and ``genesis_validators_root``.
    // This is used primarily in signature domains to avoid collisions across forks/chains.
    function compute_fork_data_root(bytes4 current_version, bytes32 genesis_validators_root) internal pure returns (bytes32){
        return hash_tree_root(ForkData({
                current_version: current_version,
                genesis_validators_root: genesis_validators_root
            })
        );
    }

    //  Return the domain for the ``domain_type`` and ``fork_version``.
    function compute_domain(bytes4 domain_type, bytes4 fork_version, bytes32 genesis_validators_root) internal pure returns (bytes32){
        bytes32 fork_data_root = compute_fork_data_root(fork_version, genesis_validators_root);
        return bytes32(domain_type) | fork_data_root >> 32;
    }

    function hash_tree_root(ForkData memory fork_data) internal pure returns (bytes32) {
        return hash_node(bytes32(fork_data.current_version), fork_data.genesis_validators_root);
    }

    function hash_tree_root(SigningData memory signing_data) internal pure returns (bytes32) {
        return hash_node(signing_data.object_root, signing_data.domain);
    }

    function hash_tree_root(SyncCommittee memory sync_committee) internal pure returns (bytes32) {
        bytes32[] memory pubkeys_leaves = new bytes32[](SYNC_COMMITTEE_SIZE);
        for (uint i = 0; i < SYNC_COMMITTEE_SIZE; ++i) {
            bytes memory key = sync_committee.pubkeys[i];
            require(key.length == BLSPUBLICKEY_LENGTH, "!key");
            pubkeys_leaves[i] = hash(abi.encodePacked(key, bytes16(0)));
        }
        bytes32 pubkeys_root = merkle_root(pubkeys_leaves);

        require(sync_committee.aggregate_pubkey.length == BLSPUBLICKEY_LENGTH, "!agg_key");
        bytes32 aggregate_pubkey_root = hash(abi.encodePacked(sync_committee.aggregate_pubkey, bytes16(0)));

        return hash_node(pubkeys_root, aggregate_pubkey_root);
    }

    function hash_tree_root(BeaconBlockHeader memory beacon_header) internal pure returns (bytes32) {
        bytes32[] memory leaves = new bytes32[](5);
        leaves[0] = bytes32(to_little_endian_64(beacon_header.slot));
        leaves[1] = bytes32(to_little_endian_64(beacon_header.proposer_index));
        leaves[2] = beacon_header.parent_root;
        leaves[3] = beacon_header.state_root;
        leaves[4] = beacon_header.body_root;
        return merkle_root(leaves);
    }

    function merkle_root(bytes32[] memory leaves) internal pure returns (bytes32) {
        uint len = leaves.length;
        if (len == 0) return bytes32(0);
        else if (len == 1) return hash(abi.encodePacked(leaves[0]));
        else if (len == 2) return hash_node(leaves[0], leaves[1]);
        uint bottom_length = get_power_of_two_ceil(len);
        bytes32[] memory o = new bytes32[](bottom_length * 2);
        for (uint i = 0; i < len; ++i) {
            o[bottom_length + i] = leaves[i];
        }
        for (uint i = bottom_length - 1; i > 0; --i) {
            o[i] = hash_node(o[i * 2], o[i * 2 + 1]);
        }
        return o[1];
    }

    //  Get the power of 2 for given input, or the closest higher power of 2 if the input is not a power of 2.
    function get_power_of_two_ceil(uint256 x) internal pure returns (uint256) {
        if (x <= 1) return 1;
        else if (x == 2) return 2;
        else return 2 * get_power_of_two_ceil((x + 1) >> 1);
    }

    function to_little_endian_64(uint64 value) internal pure returns (bytes8 r) {
        return bytes8(reverse64(value));
    }

    function reverse64(uint64 input) internal pure returns (uint64 v) {
        v = input;

        // swap bytes
        v = ((v & 0xFF00FF00FF00FF00) >> 8) |
            ((v & 0x00FF00FF00FF00FF) << 8);

        // swap 2-byte long pairs
        v = ((v & 0xFFFF0000FFFF0000) >> 16) |
            ((v & 0x0000FFFF0000FFFF) << 16);

        // swap 4-byte long pairs
        v = (v >> 32) | (v << 32);
    }
}

// SPDX-License-Identifier: Apache-2.0
// Code from https://github.com/ethereum/solidity-examples
pragma solidity 0.8.9;

library Bits {
    uint256 internal constant ONE = uint256(1);
    uint256 internal constant ONES = type(uint256).max;

    // Sets the bit at the given 'index' in 'self' to '1'.
    // Returns the modified value.
    function setBit(uint256 self, uint8 index) internal pure returns (uint256) {
        return self | (ONE << index);
    }

    // Sets the bit at the given 'index' in 'self' to '0'.
    // Returns the modified value.
    function clearBit(uint256 self, uint8 index)
        internal
        pure
        returns (uint256)
    {
        return self & ~(ONE << index);
    }

    // Sets the bit at the given 'index' in 'self' to:
    //  '1' - if the bit is '0'
    //  '0' - if the bit is '1'
    // Returns the modified value.
    function toggleBit(uint256 self, uint8 index)
        internal
        pure
        returns (uint256)
    {
        return self ^ (ONE << index);
    }

    // Get the value of the bit at the given 'index' in 'self'.
    function bit(uint256 self, uint8 index) internal pure returns (uint8) {
        return uint8((self >> index) & 1);
    }

    // Check if the bit at the given 'index' in 'self' is set.
    // Returns:
    //  'true' - if the value of the bit is '1'
    //  'false' - if the value of the bit is '0'
    function bitSet(uint256 self, uint8 index) internal pure returns (bool) {
        return (self >> index) & 1 == 1;
    }

    // Checks if the bit at the given 'index' in 'self' is equal to the corresponding
    // bit in 'other'.
    // Returns:
    //  'true' - if both bits are '0' or both bits are '1'
    //  'false' - otherwise
    function bitEqual(
        uint256 self,
        uint256 other,
        uint8 index
    ) internal pure returns (bool) {
        return ((self ^ other) >> index) & 1 == 0;
    }

    // Get the bitwise NOT of the bit at the given 'index' in 'self'.
    function bitNot(uint256 self, uint8 index) internal pure returns (uint8) {
        return uint8(1 - ((self >> index) & 1));
    }

    // Computes the bitwise AND of the bit at the given 'index' in 'self', and the
    // corresponding bit in 'other', and returns the value.
    function bitAnd(
        uint256 self,
        uint256 other,
        uint8 index
    ) internal pure returns (uint8) {
        return uint8(((self & other) >> index) & 1);
    }

    // Computes the bitwise OR of the bit at the given 'index' in 'self', and the
    // corresponding bit in 'other', and returns the value.
    function bitOr(
        uint256 self,
        uint256 other,
        uint8 index
    ) internal pure returns (uint8) {
        return uint8(((self | other) >> index) & 1);
    }

    // Computes the bitwise XOR of the bit at the given 'index' in 'self', and the
    // corresponding bit in 'other', and returns the value.
    function bitXor(
        uint256 self,
        uint256 other,
        uint8 index
    ) internal pure returns (uint8) {
        return uint8(((self ^ other) >> index) & 1);
    }

    // Gets 'numBits' consecutive bits from 'self', starting from the bit at 'startIndex'.
    // Returns the bits as a 'uint'.
    // Requires that:
    //  - '0 < numBits <= 256'
    //  - 'startIndex < 256'
    //  - 'numBits + startIndex <= 256'
    function bits(
        uint256 self,
        uint8 startIndex,
        uint16 numBits
    ) internal pure returns (uint256) {
        require(0 < numBits && startIndex < 256 && startIndex + numBits <= 256);
        return (self >> startIndex) & (ONES >> (256 - numBits));
    }

    // Computes the index of the highest bit set in 'self'.
    // Returns the highest bit set as an 'uint8'.
    // Requires that 'self != 0'.
    function highestBitSet(uint256 self) internal pure returns (uint8 highest) {
        require(self != 0);
        uint256 val = self;
        for (uint8 i = 128; i >= 1; i >>= 1) {
            if (val & (((ONE << i) - 1) << i) != 0) {
                highest += i;
                val >>= i;
            }
        }
    }

    // Computes the index of the lowest bit set in 'self'.
    // Returns the lowest bit set as an 'uint8'.
    // Requires that 'self != 0'.
    function lowestBitSet(uint256 self) internal pure returns (uint8 lowest) {
        require(self != 0);
        uint256 val = self;
        for (uint8 i = 128; i >= 1; i >>= 1) {
            if (val & ((ONE << i) - 1) == 0) {
                lowest += i;
                val >>= i;
            }
        }
    }
}

// SPDX-License-Identifier: MIT

pragma solidity 0.8.9;

contract MerkleProof {
    // Check if ``leaf`` at ``index`` verifies against the Merkle ``root`` and ``branch``.
    function is_valid_merkle_branch(
        bytes32 leaf,
        bytes32[] memory branch,
        uint64 depth,
        uint64 index,
        bytes32 root
    ) internal pure returns (bool) {
        bytes32 value = leaf;
        for (uint i = 0; i < depth; ++i) {
            if ((index / (2**i)) % 2 == 1) {
                value = hash_node(branch[i], value);
            } else {
                value = hash_node(value, branch[i]);
            }
        }
        return value == root;
    }

    function hash_node(bytes32 left, bytes32 right)
        internal
        pure
        returns (bytes32)
    {
        return hash(abi.encodePacked(left, right));
    }

    function hash(bytes memory value) internal pure returns (bytes32) {
        return sha256(value);
    }
}