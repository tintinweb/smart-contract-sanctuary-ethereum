//SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.2;

import "../../interfaces/core/IRideSettings.sol";
import "../../libraries/core/RideLibSettings.sol";

contract RideSettings is IRideSettings {
    function setAdministrationAddress(address _administration)
        external
        override
    {
        RideLibSettings._setAdministrationAddress(_administration);
    }

    function getAdministrationAddress()
        external
        view
        override
        returns (address)
    {
        return RideLibSettings._storageSettings().administration;
    }
}

//SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.2;

interface IRideSettings {
    function setAdministrationAddress(address _administration) external;

    function getAdministrationAddress() external view returns (address);
}

//SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.2;

import "../../libraries/utils/RideLibOwnership.sol";

library RideLibSettings {
    bytes32 constant STORAGE_POSITION_SETTINGS = keccak256("ds.settings");

    struct StorageSettings {
        address administration;
    }

    function _storageSettings()
        internal
        pure
        returns (StorageSettings storage s)
    {
        bytes32 position = STORAGE_POSITION_SETTINGS;
        assembly {
            s.slot := position
        }
    }

    function _setAdministrationAddress(address _administration) internal {
        RideLibOwnership._requireIsOwner();
        _storageSettings().administration = _administration;
    }
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