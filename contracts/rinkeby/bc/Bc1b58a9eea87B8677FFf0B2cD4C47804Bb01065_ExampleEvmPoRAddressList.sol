// SPDX-License-Identifier: MIT
pragma solidity 0.8.13;

import "../interfaces/IPoRAddressList.sol";

contract ExampleEvmPoRAddressList is IPoRAddressList {
    address[] private addresses;

    constructor(address[] memory _addresses) {
        addresses = _addresses;
    }

    function getPoRAddressListLength()
        external
        view
        override
        returns (uint256)
    {
        return addresses.length;
    }

    function getPoRAddressList(uint256 startIndex, uint256 endIndex)
        external
        view
        override
        returns (string[] memory)
    {
        endIndex = endIndex > addresses.length - 1
            ? addresses.length - 1
            : endIndex;
        string[] memory stringAddresses = new string[](
            endIndex - startIndex + 1
        );
        uint256 currIdx = startIndex;
        uint256 strAddrIdx = 0;
        while (currIdx <= endIndex) {
            stringAddresses[strAddrIdx] = toString(
                abi.encodePacked(addresses[currIdx])
            );
            strAddrIdx++;
            currIdx++;
        }
        return stringAddresses;
    }

    function toString(bytes memory data) private pure returns (string memory) {
        bytes memory alphabet = "0123456789abcdef";

        bytes memory str = new bytes(2 + data.length * 2);
        str[0] = "0";
        str[1] = "x";
        for (uint256 i = 0; i < data.length; i++) {
            str[2 + i * 2] = alphabet[uint256(uint8(data[i] >> 4))];
            str[3 + i * 2] = alphabet[uint256(uint8(data[i] & 0x0f))];
        }
        return string(str);
    }
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.13;

/**
 * @title Chainlink Proof-of-Reserve address list interface.
 * @notice This interface enables Chainlink nodes to get the list addresses to be used in a PoR feed. A single
 * contract that implements this interface can only store an address list for a single PoR feed.
 * @dev All functions in this interface are expected to be called off-chain, so gas usage is not a big concern.
 * This makes it possible to store addresses in optimized data types and convert them to human-readable strings
 * in `getPoRAddressList()`.
 */
interface IPoRAddressList {
    /// @notice Get total number of addresses in the list.
    function getPoRAddressListLength() external view returns (uint256);

    /**
     * @notice Get a batch of human-readable addresses from the address list.
     * @dev Due to limitations of gas usage in off-chain calls, we need to support fetching the addresses in batches.
     * EVM addresses need to be converted to human-readable strings. The address strings need to be in the same format
     * that would be used when querying the balance of that address.
     * @param startIndex The index of the first address in the batch.
     * @param endIndex The index of the last address in the batch. If `endIndex > getPoRAddressListLength()-1`,
     * endIndex need to default to `getPoRAddressListLength()-1`. If `endIndex < startIndex`, the result would be an
     * empty array.
     * @return Array of addresses as strings.
     */
    function getPoRAddressList(uint256 startIndex, uint256 endIndex)
        external
        view
        returns (string[] memory);
}