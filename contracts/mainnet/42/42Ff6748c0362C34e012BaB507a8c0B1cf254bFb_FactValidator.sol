// SPDX-License-Identifier: GPL-3.0

import { Fact, FactSignature } from "relic-sdk/packages/contracts/lib/Facts.sol";
import { FactSigs } from "relic-sdk/packages/contracts/lib/FactSigs.sol";

pragma solidity ^0.8.19;

interface Validator {
  function validate(Fact memory fact, bytes32 expectedSlot, uint256 expectedBlock, address account)
    external
    pure
    returns (bool);
}

/// FactValidator abstracts proof validation functionality
contract FactValidator is Validator {
  function validate(Fact memory fact, bytes32 expectedSlot, uint256 expectedBlock, address account)
    external
    pure
    returns (bool)
  {
    FactSignature expectedSig = FactSigs.storageSlotFactSig(expectedSlot, expectedBlock);
    if (keccak256(abi.encodePacked(fact.sig)) != keccak256(abi.encodePacked(expectedSig))) {
      return false;
    }

    if (fact.account != account) {
      return false;
    }

    return true;
  }
}

/// SPDX-License-Identifier: MIT

pragma solidity >=0.8.0;

import "./Facts.sol";

/**
 * @title FactSigs
 * @author Theori, Inc.
 * @notice Helper functions for computing fact signatures
 */
library FactSigs {
    /**
     * @notice Produce the fact signature data for birth certificates
     */
    function birthCertificateFactSigData() internal pure returns (bytes memory) {
        return abi.encode("BirthCertificate");
    }

    /**
     * @notice Produce the fact signature for a birth certificate fact
     */
    function birthCertificateFactSig() internal pure returns (FactSignature) {
        return Facts.toFactSignature(Facts.NO_FEE, birthCertificateFactSigData());
    }

    /**
     * @notice Produce the fact signature data for an account's storage root
     * @param blockNum the block number to look at
     * @param storageRoot the storageRoot for the account
     */
    function accountStorageFactSigData(uint256 blockNum, bytes32 storageRoot)
        internal
        pure
        returns (bytes memory)
    {
        return abi.encode("AccountStorage", blockNum, storageRoot);
    }

    /**
     * @notice Produce a fact signature for an accoun't storage root
     * @param blockNum the block number to look at
     * @param storageRoot the storageRoot for the account
     */
    function accountStorageFactSig(uint256 blockNum, bytes32 storageRoot)
        internal
        pure
        returns (FactSignature)
    {
        return
            Facts.toFactSignature(Facts.NO_FEE, accountStorageFactSigData(blockNum, storageRoot));
    }

    /**
     * @notice Produce the fact signature data for a storage slot
     * @param slot the account's slot
     * @param blockNum the block number to look at
     */
    function storageSlotFactSigData(bytes32 slot, uint256 blockNum)
        internal
        pure
        returns (bytes memory)
    {
        return abi.encode("StorageSlot", slot, blockNum);
    }

    /**
     * @notice Produce a fact signature for a storage slot
     * @param slot the account's slot
     * @param blockNum the block number to look at
     */
    function storageSlotFactSig(bytes32 slot, uint256 blockNum)
        internal
        pure
        returns (FactSignature)
    {
        return Facts.toFactSignature(Facts.NO_FEE, storageSlotFactSigData(slot, blockNum));
    }

    /**
     * @notice Produce the fact signature data for a log
     * @param blockNum the block number to look at
     * @param txIdx the transaction index in the block
     * @param logIdx the log index in the transaction
     */
    function logFactSigData(
        uint256 blockNum,
        uint256 txIdx,
        uint256 logIdx
    ) internal pure returns (bytes memory) {
        return abi.encode("Log", blockNum, txIdx, logIdx);
    }

    /**
     * @notice Produce a fact signature for a log
     * @param blockNum the block number to look at
     * @param txIdx the transaction index in the block
     * @param logIdx the log index in the transaction
     */
    function logFactSig(
        uint256 blockNum,
        uint256 txIdx,
        uint256 logIdx
    ) internal pure returns (FactSignature) {
        return Facts.toFactSignature(Facts.NO_FEE, logFactSigData(blockNum, txIdx, logIdx));
    }

    /**
     * @notice Produce the fact signature data for a block header
     * @param blockNum the block number
     */
    function blockHeaderSigData(uint256 blockNum) internal pure returns (bytes memory) {
        return abi.encode("BlockHeader", blockNum);
    }

    /**
     * @notice Produce the fact signature data for a block header
     * @param blockNum the block number
     */
    function blockHeaderSig(uint256 blockNum) internal pure returns (FactSignature) {
        return Facts.toFactSignature(Facts.NO_FEE, blockHeaderSigData(blockNum));
    }

    /**
     * @notice Produce the fact signature data for an event fact
     * @param eventId The event in question
     */
    function eventFactSigData(uint64 eventId) internal pure returns (bytes memory) {
        return abi.encode("EventAttendance", "EventID", eventId);
    }

    /**
     * @notice Produce a fact signature for a given event
     * @param eventId The event in question
     */
    function eventFactSig(uint64 eventId) internal pure returns (FactSignature) {
        return Facts.toFactSignature(Facts.NO_FEE, eventFactSigData(eventId));
    }
}

/// SPDX-License-Identifier: MIT

pragma solidity >=0.8.0;

type FactSignature is bytes32;

struct Fact {
    address account;
    FactSignature sig;
    bytes data;
}

/**
 * @title Facts
 * @author Theori, Inc.
 * @notice Helper functions for fact classes (part of fact signature that determines fee).
 */
library Facts {
    uint8 internal constant NO_FEE = 0;

    /**
     * @notice construct a fact signature from a fact class and some unique data
     * @param cls the fact class (determines the fee)
     * @param data the unique data for the signature
     */
    function toFactSignature(uint8 cls, bytes memory data) internal pure returns (FactSignature) {
        return FactSignature.wrap(bytes32((uint256(keccak256(data)) << 8) | cls));
    }

    /**
     * @notice extracts the fact class from a fact signature
     * @param factSig the input fact signature
     */
    function toFactClass(FactSignature factSig) internal pure returns (uint8) {
        return uint8(uint256(FactSignature.unwrap(factSig)));
    }
}