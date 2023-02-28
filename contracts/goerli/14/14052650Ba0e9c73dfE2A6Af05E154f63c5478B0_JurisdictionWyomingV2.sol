// SPDX-License-Identifier: MIT
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

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/utils/Strings.sol";
import "../OtoCoJurisdictionV2.sol";

contract JurisdictionWyomingV2 is OtoCoJurisdictionV2 {

    // Libraries
    using Strings for uint256;

    constructor (
        uint256 renewPrice,
        uint256 deployPrice,
        string memory name,
        string memory defaultBadge,
        string memory goldBadge
    ) OtoCoJurisdictionV2(renewPrice, deployPrice, name, defaultBadge, goldBadge, false) {}


    /**
     * @dev See {OtoCoJurisdiction-getSeriesNameFormatted}.
     */
    function getSeriesNameFormatted (
        uint256 count,
        string calldata nameToFormat
    ) public pure override returns(string memory){
        return string(abi.encodePacked(nameToFormat, ' - Series ', uint256(count+1).toString()));
    }

}

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

abstract contract OtoCoJurisdictionV2 {

    string private name;
    string private defaultBadge;
    string private goldBadge;
    uint256 private renewCost;
    uint256 private deployCost;
    bool private standalone;

    constructor (
        uint256 _renewCost,
        uint256 _deployCost,
        string memory _name,
        string memory _defaultBadge,
        string memory _goldBadge,
        bool _standalone
    ) {
        renewCost = _renewCost;
        deployCost = _deployCost;
        name = _name;
        defaultBadge = _defaultBadge;
        goldBadge = _goldBadge;

        assembly {
            // we avoid initializing default values
            if iszero(iszero(_standalone)) {
                sstore(standalone.slot, _standalone)
            }
        }
    }

    /**
     * Get formatted name according to the jurisdiction requirement.
     * To use when create new series, before series creation.
     * Returns the string name formatted accordingly.
     *
     * @param count current number of series deployed at the jurisdiction.
     * @return nameToFormat name of the series to format accordingly.
     */
    function getSeriesNameFormatted(uint256 count, string calldata nameToFormat) public pure virtual returns(string memory);
    
    /**
     * Return the name of the jurisdiction.
     * 
     * @return name the name of the jurisdiction.
     */
    function getJurisdictionName() external view returns(string memory) {
        return name;
    }

    /**
     * Return the NFT URI link of the jurisdiction.
     * 
     * @return defaultBadge the badge URI.
     */
    function getJurisdictionBadge() external view returns(string memory) {
        return defaultBadge;
    }

    /**
     * Return the Gold NFT URI link of the jurisdiction.
     * 
     * @return goldBadge the gold badge URI.
     */
    function getJurisdictionGoldBadge() external view returns(string memory) {
        return goldBadge;
    }


    /**
     * Return the renewal price in USD.
     * 
     * @return renewCost the cost to renew a entity of this jurisdiction for 1 year.
     */
    function getJurisdictionRenewalPrice() external view returns(uint256) {
        return renewCost;
    }

    /**
     * Return the renewal price in USD.
     * 
     * @return deployCost the cost to renew a entity of this jurisdiction for 1 year.
     */
    function getJurisdictionDeployPrice() external view returns(uint256) {
        return deployCost;
    }

    function isStandalone() external view returns(bool) {
        return standalone;
    }
}