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

/**
 * @title Contract ownership standard interface (event only)
 * @dev see https://eips.ethereum.org/EIPS/eip-173
 */
interface IERC173Events {
    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.15;

import "@openzeppelin/contracts/utils/Context.sol";

import "./OwnableStorage.sol";
import "./IERC173Events.sol";

abstract contract OwnableInternal is IERC173Events, Context {
    using OwnableStorage for OwnableStorage.Layout;

    modifier onlyOwner() {
        require(_msgSender() == _owner(), "Ownable: sender must be owner");
        _;
    }

    function _owner() internal view virtual returns (address) {
        return OwnableStorage.layout().owner;
    }

    function _transferOwnership(address account) internal virtual {
        OwnableStorage.layout().setOwner(account);
        emit OwnershipTransferred(_msgSender(), account);
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.15;

library OwnableStorage {
    struct Layout {
        address owner;
    }

    bytes32 internal constant STORAGE_SLOT = keccak256("openzeppelin.contracts.storage.Ownable");

    function layout() internal pure returns (Layout storage l) {
        bytes32 slot = STORAGE_SLOT;
        assembly {
            l.slot := slot
        }
    }

    function setOwner(Layout storage l, address owner) internal {
        l.owner = owner;
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.15;

import "./ILicenseInternal.sol";

interface ILicenseAdmin {
    function setLicenseVersion(ILicenseInternal.LicenseVersion licenseVersion) external;

    function lockLicenseVersion() external;

    function licenseVersionLocked() external view returns (bool);
}

// SPDX-License-Identifier: AGPL-3.0

pragma solidity ^0.8.15;

interface ILicenseInternal {
    enum LicenseVersion {
        CBE_CC0,
        CBE_ECR,
        CBE_NECR,
        CBE_NECR_HS,
        CBE_PR,
        CBE_PR_HS,
        CUSTOM,
        UNLICENSED
    }

    error ErrLicenseLocked();

    event CustomLicenseSet(string customLicenseURI, string customLicenseName);
    event LicenseVersionSet(LicenseVersion licenseVersion);
    event LicenseLocked();
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.15;

import "@openzeppelin/contracts/utils/Strings.sol";

import "./LicenseStorage.sol";
import "./ILicenseInternal.sol";

/**
 * @title Functionality to expose license name and URI for the assets of the contract.
 */
abstract contract LicenseInternal is ILicenseInternal {
    using Strings for uint256;
    using LicenseStorage for LicenseStorage.Layout;

    string internal constant A16Z_BASE_LICENSE_URI = "ar://_D9kN1WrNWbCq55BSAGRbTB4bS3v8QAPTYmBThSbX3A/";

    function _licenseVersion() internal view virtual returns (ILicenseInternal.LicenseVersion) {
        return LicenseStorage.layout().licenseVersion;
    }

    function _getLicenseURI() internal view virtual returns (string memory) {
        LicenseStorage.Layout storage l = LicenseStorage.layout();

        if (l.licenseVersion == LicenseVersion.CUSTOM) {
            return l.customLicenseURI;
        }
        if (l.licenseVersion == LicenseVersion.UNLICENSED) {
            return "";
        }

        return string.concat(A16Z_BASE_LICENSE_URI, uint256(l.licenseVersion).toString());
    }

    function _getLicenseName() internal view virtual returns (string memory) {
        LicenseStorage.Layout storage l = LicenseStorage.layout();

        if (l.licenseVersion == LicenseVersion.CUSTOM) {
            return l.customLicenseName;
        }

        if (l.licenseVersion == LicenseVersion.UNLICENSED) {
            return "";
        }

        if (LicenseVersion.CBE_CC0 == l.licenseVersion) return "CBE_CC0";
        if (LicenseVersion.CBE_ECR == l.licenseVersion) return "CBE_ECR";
        if (LicenseVersion.CBE_NECR == l.licenseVersion) return "CBE_NECR";
        if (LicenseVersion.CBE_NECR_HS == l.licenseVersion) return "CBE_NECR_HS";
        if (LicenseVersion.CBE_PR == l.licenseVersion) return "CBE_PR";
        else return "CBE_PR_HS";
    }

    function _setCustomLicense(string calldata _customLicenseName, string calldata _customLicenseURI) internal virtual {
        LicenseStorage.Layout storage l = LicenseStorage.layout();

        if (l.licenseVersionLocked) {
            revert ErrLicenseLocked();
        }

        l.licenseVersion = LicenseVersion.CUSTOM;
        l.customLicenseName = _customLicenseName;
        l.customLicenseURI = _customLicenseURI;

        emit CustomLicenseSet(_customLicenseName, _customLicenseURI);
    }

    function _setLicenseVersion(LicenseVersion _newVersion) internal virtual {
        LicenseStorage.Layout storage l = LicenseStorage.layout();

        if (l.licenseVersionLocked) {
            revert ErrLicenseLocked();
        }

        l.licenseVersion = _newVersion;

        emit LicenseVersionSet(_newVersion);
    }

    function _lockLicenseVersion() internal virtual {
        LicenseStorage.layout().licenseVersionLocked = true;

        emit LicenseLocked();
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.15;

import "../../access/ownable/OwnableInternal.sol";

import "./LicenseStorage.sol";
import "./LicenseInternal.sol";
import "./ILicenseAdmin.sol";

/**
 * @title License - Admin - Ownable
 * @notice Allow contract owner to manage license version, name and URI.
 *
 * @custom:type eip-2535-facet
 * @custom:category Legal
 * @custom:peer-dependencies ILicense ICantBeEvil
 * @custom:provides-interfaces ILicenseAdmin
 */
contract LicenseOwnable is ILicenseAdmin, OwnableInternal, LicenseInternal {
    using LicenseStorage for LicenseStorage.Layout;

    function setLicenseVersion(LicenseVersion licenseVersion) external override onlyOwner {
        _setLicenseVersion(licenseVersion);
    }

    function lockLicenseVersion() external override onlyOwner {
        _lockLicenseVersion();
    }

    function licenseVersionLocked() external view override returns (bool) {
        return LicenseStorage.layout().licenseVersionLocked;
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.15;

import "./ILicenseInternal.sol";

library LicenseStorage {
    struct Layout {
        ILicenseInternal.LicenseVersion licenseVersion;
        string customLicenseURI;
        string customLicenseName;
        bool licenseVersionLocked;
    }

    bytes32 internal constant STORAGE_SLOT = keccak256("v2.flair.contracts.storage.License");

    function layout() internal pure returns (Layout storage l) {
        bytes32 slot = STORAGE_SLOT;
        assembly {
            l.slot := slot
        }
    }
}