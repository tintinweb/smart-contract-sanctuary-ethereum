// SPDX-License-Identifier: MIT
pragma solidity ^0.8.2;

import "../../interfaces/utils/IERC173.sol";
import "../../libraries/utils/RideLibOwnership.sol";

contract RideOwnership is IERC173 {
    function owner() external view override returns (address) {
        return RideLibOwnership._getOwner();
    }

    function transferOwnership(address _newOwner) external override {
        RideLibOwnership._requireIsOwner();
        RideLibOwnership._setOwner(_newOwner);
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.2;

/// @title ERC-173 Contract Ownership Standard
///  Note: the ERC-165 identifier for this interface is 0x7f5828d0
/* is ERC165 */
interface IERC173 {
    /// @dev This emits when ownership of a contract changes.
    event OwnershipTransferred(
        address indexed previousOwner,
        address indexed newOwner
    );

    /// @notice Get the address of the owner
    /// @return _owner The address of the owner.
    function owner() external view returns (address);

    /// @notice Set the address of the new owner of the contract
    /// @dev Set _newOwner to address(0) to renounce any ownership.
    /// @param _newOwner The address of the new owner of the contract
    function transferOwnership(address _newOwner) external;
}

//SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.2;

library RideLibOwnership {
    bytes32 constant STORAGE_POSITION_OWNERSHIP = keccak256("ds.ownership");

    struct StorageOwnership {
        address owner;
    }

    function _storageOwnership()
        internal
        pure
        returns (StorageOwnership storage s)
    {
        bytes32 position = STORAGE_POSITION_OWNERSHIP;
        assembly {
            s.slot := position
        }
    }

    function _requireIsOwner() internal view {
        require(msg.sender == _storageOwnership().owner, "not contract owner");
    }

    event OwnershipTransferred(
        address indexed previousOwner,
        address indexed newOwner
    );

    function _setOwner(address _newOwner) internal {
        StorageOwnership storage s1 = _storageOwnership();
        address previousOwner = s1.owner;
        s1.owner = _newOwner;
        emit OwnershipTransferred(previousOwner, _newOwner);
    }

    function _getOwner() internal view returns (address) {
        return _storageOwnership().owner;
    }
}