// SPDX-License-Identifier: MIT

// NOTE: The assembly in this file relies on the specifics of the 0.8.0 spec.
// Validate all changes before upgrading.
pragma solidity ^0.8.0;

import "./ISpanningDelegate.sol";

/**
 * @dev This library adds interpretation of our `SpanningAddress` as follows:
 *
 * 31    27        19                   0
 * |-----+---------+--------------------|
 *
 * +The bottom 0-19 bytes are the local address
 * +Bytes 20-27 are left empty for future expansion
 * +Bytes 28 - 31 are the domain ID
 * +Byte 20 - the number of blocks the protocol
 *            will wait before settling the transaction
 */
library SpanningAddress {
    /**
     * @dev Helper function to pack a Spanning Address.
     *
     * @param legacyAddress - Legacy (local) address to pack
     * @param domain - Domain identifier to pack
     * @return bytes32 - Generated Spanning Address
     */
    function create(address legacyAddress, bytes4 domain)
        public
        pure
        returns (bytes32)
    {
        bytes32 packedSpanningAddress = 0x0;
        assembly {
            // `address` is left extension and `bytes` is right extension
            packedSpanningAddress := add(legacyAddress, domain)
        }
        return packedSpanningAddress;
    }

    /**
     * @dev Sentinel value for an invalid Spanning Address.
     *
     * @return bytes32 - An invalid Spanning Address
     */
    function invalidAddress() public pure returns (bytes32) {
        return create(address(0), bytes4(0));
    }

    function valid(bytes32 addr) public pure returns (bool) {
        return addr != invalidAddress();
    }

    /**
     * @dev Extracts legacy (local) address.
     *
     * @param input - Spanning Address to unpack
     *
     * @return address - Unpacked legacy (local) address
     */
    function getAddress(bytes32 input) public pure returns (address) {
        address unpackedLegacyAddress = address(0);
        assembly {
            // `address` asm will extend from top
            unpackedLegacyAddress := input
        }
        return unpackedLegacyAddress;
    }

    /**
     * @dev Extracts domain identifier.
     *
     * @param input - Spanning Address to unpack
     *
     * @return bytes4 - Unpacked domain identifier
     */
    function getDomain(bytes32 input) public pure returns (bytes4) {
        bytes4 unpackedDomain = 0x0;
        assembly {
            // `bytes` asm will extend from the bottom
            unpackedDomain := input
        }
        return unpackedDomain;
    }

    /**
     * @dev Determines if two Spanning Addresses are equal.
     *
     * Note: This function only considers LegacyAddress and Domain for equality
     * Note: Thus, `equals()` can return true even if `first != second`
     *
     * @param first - the first Spanning Address
     * @param second - the second Spanning Address
     *
     * @return bool - true if the two Spanning Addresses are equal
     */
    function equals(bytes32 first, bytes32 second) public pure returns (bool) {
        // TODO(ENG-137): This may be faster if we use bitwise ops. Profile it.
        return (getDomain(first) == getDomain(second) &&
            getAddress(first) == getAddress(second));
    }

    /**
     * @dev Packs data into an existing Spanning Address
     *
     * This can be used to add routing parameters into a
     * Spanning Addresses buffer space.
     *
     * Example to specify a message waits `numFinalityBlocks`
     * before settling:
     * newSpanningAddress = packAddressData(prevSpanningAddress,
     *                                      numFinalityBlocks,
     *                                      20)
     *
     * @param existingAddress - the Spanning Address to modify
     * @param payload - the data to pack
     * @param index - the byte location to put the payload into
     */
    function packAddressData(
        bytes32 existingAddress,
        uint8 payload,
        uint8 index
    ) public pure returns (bytes32) {
        require(index > 19 && index < 28,
                "Trying to overwrite address data");
        bytes32 encodedAddress = 0x0;
        bytes32 dataMask = 0x0;
        uint8 payloadIndex = index * 8;
        assembly {
            // `payload` is right extension
            dataMask := shl(payloadIndex, payload)
            encodedAddress := add(existingAddress, dataMask)
        }
        return encodedAddress;
    }
}