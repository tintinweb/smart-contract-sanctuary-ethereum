// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (interfaces/IERC1271.sol)

pragma solidity ^0.8.0;

/**
 * @dev Interface of the ERC1271 standard signature validation method for
 * contracts as defined in https://eips.ethereum.org/EIPS/eip-1271[ERC-1271].
 *
 * _Available since v4.1._
 */
interface IERC1271 {
    /**
     * @dev Should return whether the signature provided is valid for the provided data
     * @param hash      Hash of the data to be signed
     * @param signature Signature byte array associated with _data
     */
    function isValidSignature(bytes32 hash, bytes memory signature) external view returns (bytes4 magicValue);
}

//SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import {IERC1271} from "@openzeppelin/contracts/interfaces/IERC1271.sol";
import {LibERC1271} from "../../libraries/LibERC1271.sol";

/// @author Amit Molek
/// @dev ERC1271 support
contract EIP1271Facet is IERC1271 {
    function isValidSignature(bytes32 hash, bytes memory signature)
        external
        view
        override
        returns (bytes4)
    {
        return LibERC1271._isValidSignature(hash, signature);
    }
}

//SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import {StorageApprovedHashes} from "../storage/StorageApprovedHashes.sol";

/// @author Amit Molek
library LibERC1271 {
    bytes4 internal constant MAGICVALUE = 0x1626ba7e;
    bytes4 internal constant FAILUREVALUE = 0xffffffff;

    function _isValidSignature(bytes32 hash, bytes memory)
        internal
        view
        returns (bytes4)
    {
        StorageApprovedHashes.DiamondStorage storage ds = StorageApprovedHashes
            .diamondStorage();

        return ds.approvedHashes[hash] ? MAGICVALUE : FAILUREVALUE;
    }
}

//SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

/// @author Amit Molek
/// @dev Diamond compatible storage for approved hashes
library StorageApprovedHashes {
    struct DiamondStorage {
        /// @dev Mapping of approved hashes
        mapping(bytes32 => bool) approvedHashes;
    }

    bytes32 public constant DIAMOND_STORAGE_POSITION =
        keccak256("antic.storage.ApprovedHashes");

    function diamondStorage()
        internal
        pure
        returns (DiamondStorage storage ds)
    {
        bytes32 storagePosition = DIAMOND_STORAGE_POSITION;
        assembly {
            ds.slot := storagePosition
        }
    }
}