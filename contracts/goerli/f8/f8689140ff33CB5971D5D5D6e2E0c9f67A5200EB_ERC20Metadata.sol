// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (utils/Strings.sol)

pragma solidity ^0.8.0;

/**
 * @dev String operations.
 */
library Strings {
    bytes16 private constant _HEX_SYMBOLS = "0123456789abcdef";
    uint8 private constant _ADDRESS_LENGTH = 20;

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

    /**
     * @dev Converts an `address` with fixed length of 20 bytes to its not checksummed ASCII `string` hexadecimal representation.
     */
    function toHexString(address addr) internal pure returns (string memory) {
        return toHexString(uint256(uint160(addr)), _ADDRESS_LENGTH);
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.15;

import { Metadata } from "../../../common/metadata/Metadata.sol";
import { IERC20Metadata } from "./IERC20Metadata.sol";
import { ERC20MetadataInternal } from "./ERC20MetadataInternal.sol";

/**
 * @title ERC20 - Metadata
 * @notice Provides standard read methods for name, symbol and decimals metadata for an ERC20 token.
 *
 * @custom:type eip-2535-facet
 * @custom:category Tokens
 * @custom:provides-interfaces IERC20Metadata
 */
contract ERC20Metadata is Metadata, IERC20Metadata, ERC20MetadataInternal {
    /**
     * @inheritdoc IERC20Metadata
     */
    function decimals() external view returns (uint8) {
        return _decimals();
    }

    function decimalsLocked() external view returns (bool) {
        return _decimalsLocked();
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.15;

import { ERC20MetadataStorage } from "./ERC20MetadataStorage.sol";

/**
 * @title ERC20Metadata internal functions
 */
abstract contract ERC20MetadataInternal {
    /**
     * @notice return token decimals, generally used only for display purposes
     * @return token decimals
     */
    function _decimals() internal view virtual returns (uint8) {
        return ERC20MetadataStorage.layout().decimals;
    }

    function _decimalsLocked() internal view virtual returns (bool) {
        return ERC20MetadataStorage.layout().decimalsLocked;
    }

    function _setDecimals(uint8 decimals_) internal virtual {
        require(!_decimalsLocked(), "ERC20Metadata: decimals locked");
        ERC20MetadataStorage.layout().decimals = decimals_;
        ERC20MetadataStorage.layout().decimalsLocked = true;
    }

    function _setDecimalsLocked(bool decimalsLocked_) internal virtual {
        ERC20MetadataStorage.layout().decimalsLocked = decimalsLocked_;
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.15;

library ERC20MetadataStorage {
    struct Layout {
        uint8 decimals;
        bool decimalsLocked;
    }

    bytes32 internal constant STORAGE_SLOT = keccak256("v2.flair.contracts.storage.ERC20Metadata");

    function layout() internal pure returns (Layout storage l) {
        bytes32 slot = STORAGE_SLOT;
        assembly {
            l.slot := slot
        }
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.15;

import "../../../common/metadata/IMetadata.sol";

interface IERC20Metadata is IMetadata {
    /**
     * @notice return token decimals, generally used only for display purposes
     * @return token decimals
     */
    function decimals() external view returns (uint8);
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.15;

interface IMetadata {
    function name() external view returns (string memory);

    function symbol() external view returns (string memory);
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.15;

import "@openzeppelin/contracts/utils/Strings.sol";

import "./IMetadata.sol";
import "./MetadataStorage.sol";

/**
 * @title Metadata
 * @notice Provides contract name and symbol.
 *
 * @custom:type eip-2535-facet
 * @custom:category Tokens
 * @custom:provides-interfaces IMetadata
 */
contract Metadata is IMetadata {
    function name() external view virtual override returns (string memory) {
        return MetadataStorage.layout().name;
    }

    function symbol() external view virtual override returns (string memory) {
        return MetadataStorage.layout().symbol;
    }

    function nameAndSymbolLocked() external view virtual returns (bool) {
        return MetadataStorage.layout().nameAndSymbolLocked;
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.15;

library MetadataStorage {
    bytes32 internal constant STORAGE_SLOT = keccak256("v2.flair.contracts.storage.Metadata");

    struct Layout {
        string name;
        string symbol;
        bool nameAndSymbolLocked;
    }

    function layout() internal pure returns (Layout storage l) {
        bytes32 slot = STORAGE_SLOT;
        assembly {
            l.slot := slot
        }
    }
}