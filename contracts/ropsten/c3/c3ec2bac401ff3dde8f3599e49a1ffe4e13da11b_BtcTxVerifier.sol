// SPDX-License-Identifier: Unlicense
pragma solidity >=0.8.0;

import "./interfaces/IBtcMirror.sol";
import "./interfaces/IBtcTxVerifier.sol";
import "./BtcProofUtils.sol";

//
//                                        #
//                                       # #
//                                      # # #
//                                     # # # #
//                                    # # # # #
//                                   # # # # # #
//                                  # # # # # # #
//                                 # # # # # # # #
//                                # # # # # # # # #
//                               # # # # # # # # # #
//                              # # # # # # # # # # #
//                                   # # # # # #
//                               +        #        +
//                                ++++         ++++
//                                  ++++++ ++++++
//                                    +++++++++
//                                      +++++
//                                        +
//
// BtcVerifier implements a Merkle proof that a Bitcoin payment succeeded. It
// uses BtcMirror as a source of truth for which Bitcoin block hashes are in the
// canonical chain.
contract BtcTxVerifier is IBtcTxVerifier {
    IBtcMirror immutable mirror;

    constructor(IBtcMirror _mirror) {
        mirror = _mirror;
    }

    function verifyPayment(
        uint256 minConfirmations,
        uint256 blockNum,
        BtcTxProof calldata inclusionProof,
        uint256 txOutIx,
        bytes20 destScriptHash,
        uint256 amountSats
    ) external view returns (bool) {
        {
            uint256 mirrorHeight = mirror.getLatestBlockHeight();

            require(
                mirrorHeight >= blockNum,
                "Bitcoin Mirror doesn't have that block yet"
            );

            require(
                mirrorHeight + 1 >= minConfirmations + blockNum,
                "Not enough Bitcoin block confirmations"
            );
        }

        bytes32 blockHash = mirror.getBlockHash(blockNum);

        require(
            BtcProofUtils.validatePayment(
                blockHash,
                inclusionProof,
                txOutIx,
                destScriptHash,
                amountSats
            ),
            "Invalid transaction proof"
        );

        return true;
    }
}

// SPDX-License-Identifier: MIT
pragma solidity >=0.8.0;

/** @notice Provides Bitcoin block hashes. */
interface IBtcMirror {
    /** @notice Returns the Bitcoin block hash at a specific height. */
    function getBlockHash(uint256 number) external view returns (bytes32);

    /** @notice Returns the height of the latest block (tip of the chain). */
    function getLatestBlockHeight() external view returns (uint256);

    /** @notice Returns the timestamp of the lastest block, as Unix seconds. */
    function getLatestBlockTime() external view returns (uint256);

    /** @notice Submits a new Bitcoin chain segment. */
    function submit(uint256 blockHeight, bytes calldata blockHeaders) external;
}

// SPDX-License-Identifier: MIT
pragma solidity >=0.8.0;

import "./BtcTxProof.sol";

/** @notice Verifies Bitcoin transaction proofs. */
interface IBtcTxVerifier {
    /**
     * @notice Verifies that the a transaction cleared, paying a given amount to
     *         a given address. Specifically, verifies a proof that the tx was
     *         in block N, and that block N has at least M confirmations.
     */
    function verifyPayment(
        uint256 minConfirmations,
        uint256 blockNum,
        BtcTxProof calldata inclusionProof,
        uint256 txOutIx,
        bytes20 destScriptHash,
        uint256 amountSats
    ) external view returns (bool);
}

// SPDX-License-Identifier: Unlicense
pragma solidity >=0.8.0;

import "./Endian.sol";
import "./interfaces/BtcTxProof.sol";

/**
 * @dev A parsed (but NOT fully validated) Bitcoin transaction.
 */
struct BitcoinTx {
    /**
     * @dev Whether we successfully parsed this Bitcoin TX, valid version etc.
     *      Does NOT check signatures or whether inputs are unspent.
     */
    bool validFormat;
    /**
     * @dev Version. Must be 1 or 2.
     */
    uint32 version;
    /**
     * @dev Each input spends a previous UTXO.
     */
    BitcoinTxIn[] inputs;
    /**
     * @dev Each output creates a new UTXO.
     */
    BitcoinTxOut[] outputs;
    /**
     * @dev Locktime. Either 0 for no lock, blocks if <500k, or seconds.
     */
    uint32 locktime;
}

struct BitcoinTxIn {
    /** @dev Previous transaction. */
    uint256 prevTxID;
    /** @dev Specific output from that transaction. */
    uint32 prevTxIndex;
    /** @dev Mostly useless for tx v1, BIP68 Relative Lock Time for tx v2. */
    uint32 seqNo;
    /** @dev Input script length */
    uint32 scriptLen;
    /** @dev Input script, spending a previous UTXO. Over 32 bytes unsupported. */
    bytes32 script;
}

struct BitcoinTxOut {
    /** @dev TXO value, in satoshis */
    uint64 valueSats;
    /** @dev Output script length */
    uint32 scriptLen;
    /** @dev Output script. Over 32 bytes unsupported.  */
    bytes32 script;
}

//
//                                        #
//                                       # #
//                                      # # #
//                                     # # # #
//                                    # # # # #
//                                   # # # # # #
//                                  # # # # # # #
//                                 # # # # # # # #
//                                # # # # # # # # #
//                               # # # # # # # # # #
//                              # # # # # # # # # # #
//                                   # # # # # #
//                               +        #        +
//                                ++++         ++++
//                                  ++++++ ++++++
//                                    +++++++++
//                                      +++++
//                                        +
//
// BtcProofUtils provides functions to prove things about Bitcoin transactions.
// Verifies Merkle inclusion proofs, tx IDs, and payment details.
library BtcProofUtils {
    /**
     * @dev Validates that a given payment appears under a given block hash.
     *
     * This verifies a whole chain:
     * 1. Raw transaction really does pay X satoshis to Y script hash.
     * 2. Raw tx hashes to a transaction ID.
     * 3. Transaction ID appears under transaction root (Merkle proof).
     * 4. Transaction root is part of the block header.
     * 5. Block header hashes to a given block hash.
     *
     * Always returns true or reverts with a descriptive reason.
     */
    function validatePayment(
        bytes32 blockHash,
        BtcTxProof calldata txProof,
        uint256 txOutIx,
        bytes20 destScriptHash,
        uint256 satoshisExpected
    ) internal pure returns (bool) {
        // 5. Block header to block hash
        require(
            getBlockHash(txProof.blockHeader) == blockHash,
            "Block hash mismatch"
        );

        // 4. and 3. Transaction ID included in block
        bytes32 blockTxRoot = getBlockTxMerkleRoot(txProof.blockHeader);
        bytes32 txRoot = getTxMerkleRoot(
            txProof.txId,
            txProof.txIndex,
            txProof.txMerkleProof
        );
        require(blockTxRoot == txRoot, "Tx merkle root mismatch");

        // 2. Raw transaction to TxID
        require(getTxID(txProof.rawTx) == txProof.txId, "Tx ID mismatch");

        // 1. Finally, validate raw transaction pays stated recipient.
        BitcoinTx memory parsedTx = parseBitcoinTx(txProof.rawTx);
        BitcoinTxOut memory txo = parsedTx.outputs[txOutIx];
        bytes20 actualScriptHash = getP2SH(txo.scriptLen, txo.script);
        require(destScriptHash == actualScriptHash, "Script hash mismatch");
        require(txo.valueSats >= satoshisExpected, "Underpayment");

        // We've verified that blockHash contains a P2SH transaction
        // that sends at least satoshisExpected to the given hash.
        //
        // This function does NOT verify that blockHash is in the canonical
        // chain. Do that separately using BtcMirror.
        return true;
    }

    /**
     * @dev Get a block hash given a block header.
     */
    function getBlockHash(bytes calldata blockHeader)
        public
        pure
        returns (bytes32)
    {
        require(blockHeader.length == 80);
        bytes32 ret = sha256(abi.encodePacked(sha256(blockHeader)));
        return bytes32(Endian.reverse256(uint256(ret)));
    }

    /**
     * @dev Get the transactions root given a block header.
     */
    function getBlockTxMerkleRoot(bytes calldata blockHeader)
        public
        pure
        returns (bytes32)
    {
        require(blockHeader.length == 80);
        return bytes32(blockHeader[36:68]);
    }

    /**
     * @dev Recomputes the transactions root given a merkle proof.
     *
     * TODO: pre-reverse txId and proof to save gas
     */
    function getTxMerkleRoot(
        bytes32 txId,
        uint256 txIndex,
        bytes calldata siblings
    ) public pure returns (bytes32) {
        bytes32 ret = bytes32(Endian.reverse256(uint256(txId)));
        uint256 len = siblings.length / 32;
        for (uint256 i = 0; i < len; i++) {
            bytes32 s = bytes32(
                Endian.reverse256(
                    uint256(bytes32(siblings[i * 32:(i + 1) * 32]))
                )
            );
            if (txIndex & 1 == 0) {
                ret = doubleSha(abi.encodePacked(ret, s));
            } else {
                ret = doubleSha(abi.encodePacked(s, ret));
            }
            txIndex = txIndex >> 1;
        }
        return ret;
    }

    /**
     * @dev Computes the ubiquitious Bitcoin SHA256(SHA256(x))
     */
    function doubleSha(bytes memory buf) internal pure returns (bytes32) {
        return sha256(abi.encodePacked(sha256(buf)));
    }

    /**
     * @dev Recomputes the transaction ID for a raw transaction.
     */
    function getTxID(bytes calldata rawTransaction)
        public
        pure
        returns (bytes32)
    {
        bytes32 ret = doubleSha(rawTransaction);
        return bytes32(Endian.reverse256(uint256(ret)));
    }

    /**
     * @dev Parses a HASH-SERIALIZED Bitcoin transaction.
     *      This means no flags and no witnesses for segwit txs.
     */
    function parseBitcoinTx(bytes calldata rawTx)
        public
        pure
        returns (BitcoinTx memory ret)
    {
        ret.version = Endian.reverse32(uint32(bytes4(rawTx[0:4])));
        if (ret.version < 1 || ret.version > 2) {
            return ret; // invalid version
        }

        // Read transaction inputs
        uint256 offset = 4;
        uint256 nInputs;
        (nInputs, offset) = readVarInt(rawTx, offset);
        ret.inputs = new BitcoinTxIn[](nInputs);
        for (uint256 i = 0; i < nInputs; i++) {
            BitcoinTxIn memory txIn;
            txIn.prevTxID = Endian.reverse256(
                uint256(bytes32(rawTx[offset:offset + 32]))
            );
            offset += 32;
            txIn.prevTxIndex = Endian.reverse32(
                uint32(bytes4(rawTx[offset:offset + 4]))
            );
            offset += 4;
            uint256 nInScriptBytes;
            (nInScriptBytes, offset) = readVarInt(rawTx, offset);
            require(nInScriptBytes <= 32, "Scripts over 32 bytes unsupported");
            txIn.scriptLen = uint32(nInScriptBytes);
            txIn.script = bytes32(rawTx[offset:offset + nInScriptBytes]);
            offset += nInScriptBytes;
            txIn.seqNo = Endian.reverse32(
                uint32(bytes4(rawTx[offset:offset + 4]))
            );
            offset += 4;
            ret.inputs[i] = txIn;
        }

        // Read transaction outputs
        uint256 nOutputs;
        (nOutputs, offset) = readVarInt(rawTx, offset);
        ret.outputs = new BitcoinTxOut[](nOutputs);
        for (uint256 i = 0; i < nOutputs; i++) {
            BitcoinTxOut memory txOut;
            txOut.valueSats = Endian.reverse64(
                uint64(bytes8(rawTx[offset:offset + 8]))
            );
            offset += 8;
            uint256 nOutScriptBytes;
            (nOutScriptBytes, offset) = readVarInt(rawTx, offset);
            require(nOutScriptBytes <= 32, "Scripts over 32 bytes unsupported");
            txOut.scriptLen = uint32(nOutScriptBytes);
            txOut.script = bytes32(rawTx[offset:offset + nOutScriptBytes]);
            offset += nOutScriptBytes;
            ret.outputs[i] = txOut;
        }

        // Finally, read locktime, the last four bytes in the tx.
        ret.locktime = Endian.reverse32(
            uint32(bytes4(rawTx[offset:offset + 4]))
        );
        offset += 4;
        if (offset != rawTx.length) {
            return ret; // Extra data at end of transaction.
        }

        // Parsing complete, sanity checks passed, return success.
        ret.validFormat = true;
        return ret;
    }

    function readVarInt(bytes calldata buf, uint256 offset)
        public
        pure
        returns (uint256 val, uint256 newOffset)
    {
        uint8 pivot = uint8(buf[offset]);
        if (pivot < 0xfd) {
            val = pivot;
            newOffset = offset + 1;
        } else if (pivot == 0xfd) {
            val = Endian.reverse16(uint16(bytes2(buf[offset + 1:offset + 3])));
            newOffset = offset + 3;
        } else if (pivot == 0xfe) {
            val = Endian.reverse32(uint32(bytes4(buf[offset + 1:offset + 5])));
            newOffset = offset + 5;
        } else {
            // pivot == 0xff
            val = Endian.reverse64(uint64(bytes8(buf[offset + 1:offset + 9])));
            newOffset = offset + 9;
        }
    }

    /**
     * @dev Verifies a standard P2PKH payment = to an address starting with 1.
     */
    // function getPaymentP2PKH(
    //     bytes20 recipientPubKeyHash,
    //     BitcoinTxOut calldata txOut
    // ) internal pure returns (uint256) {
    //     if (txOut.script.length != 23) {
    //         return 0;
    //     }
    //     return 0;
    //     // TODO: if (bytes2(txOut.script[0:2]) != hex"a914") return txOut.valueSats;
    // }

    /**
     * @dev Verifies that `script` is a standard P2SH (pay to script hash) tx.
     * @return hash The recipient script hash, or 0 if verification failed.
     */
    function getP2SH(uint256 scriptLen, bytes32 script)
        internal
        pure
        returns (bytes20)
    {
        if (scriptLen != 23) {
            return 0;
        }
        if (script[0] != 0xa9 || script[1] != 0x14 || script[22] != 0x87) {
            return 0;
        }
        uint256 sHash = (uint256(script) >> 80) &
            0x00ffffffffffffffffffffffffffffffffffffffff;
        return bytes20(uint160(sHash));
    }
}

// SPDX-License-Identifier: MIT
pragma solidity >=0.8.0;

/** @notice Proof that a transaction (rawTx) is in a given block. */
struct BtcTxProof {
    /** 80-byte block header. */
    bytes blockHeader;
    /** Bitcoin transaction ID, equal to SHA256(SHA256(rawTx)) */
    bytes32 txId;
    /** Index of transaction within the block. */
    uint256 txIndex;
    /** Merkle proof. Concatenated sibling hashes, 32*n bytes. */
    bytes txMerkleProof;
    /** Raw transaction, HASH-SERIALIZED, no witnesses. */
    bytes rawTx;
}

// SPDX-License-Identifier: Unlicense
pragma solidity >=0.8.0;

// Bitwise math helpers, for dealing with Bitcoin block headers.
// Bitcoin block fields are little-endian. Must flip to big-endian for EVM.
library Endian {
    function reverse256(uint256 input) internal pure returns (uint256 v) {
        v = input;

        // swap bytes
        uint256 pat1 = 0xFF00FF00FF00FF00FF00FF00FF00FF00FF00FF00FF00FF00FF00FF00FF00FF00;
        v = ((v & pat1) >> 8) | ((v & ~pat1) << 8);

        // swap 2-byte long pairs
        uint256 pat2 = 0xFFFF0000FFFF0000FFFF0000FFFF0000FFFF0000FFFF0000FFFF0000FFFF0000;
        v = ((v & pat2) >> 16) | ((v & ~pat2) << 16);

        // swap 4-byte long pairs
        uint256 pat4 = 0xFFFFFFFF00000000FFFFFFFF00000000FFFFFFFF00000000FFFFFFFF00000000;
        v = ((v & pat4) >> 32) | ((v & ~pat4) << 32);

        // swap 8-byte long pairs
        uint256 pat8 = 0xFFFFFFFFFFFFFFFF0000000000000000FFFFFFFFFFFFFFFF0000000000000000;
        v = ((v & pat8) >> 64) | ((v & ~pat8) << 64);

        // swap 16-byte long pairs
        v = (v >> 128) | (v << 128);
    }

    function reverse64(uint64 input) internal pure returns (uint64 v) {
        v = input;

        // swap bytes
        v = ((v & 0xFF00FF00FF00FF00) >> 8) | ((v & 0x00FF00FF00FF00FF) << 8);

        // swap 2-byte long pairs
        v = ((v & 0xFFFF0000FFFF0000) >> 16) | ((v & 0x0000FFFF0000FFFF) << 16);

        // swap 4-byte long pairs
        v = (v >> 32) | (v << 32);
    }

    function reverse32(uint32 input) internal pure returns (uint32 v) {
        v = input;

        // swap bytes
        v = ((v & 0xFF00FF00) >> 8) | ((v & 0x00FF00FF) << 8);

        // swap 2-byte long pairs
        v = (v >> 16) | (v << 16);
    }

    function reverse16(uint16 input) internal pure returns (uint16 v) {
        v = input;

        // swap bytes
        v = (v >> 8) | (v << 8);
    }
}