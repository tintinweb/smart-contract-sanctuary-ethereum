// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import {Core} from "./Core.sol";
import {Permissions} from "./Permissions.sol";

struct LaunchConfig {
    address metalabelAdmin;
    string metalabelMetadataUri;
    // string groupName;
    // string groupSymbol;
    // bytes32 groupMembershipRoot;
    // string groupMembershipTreeUri;
}

struct ReleaseConfig {
    uint256 metalabelId;
    string releaseMetadataUri;
    // TODO: drop info
}

/// @notice Adapter that handles launching metalabels and releases
contract Registry {
    Core public immutable core;

    // ---
    // Errors
    // ---

    /// @notice An action was attempted by a msg.sender that does not have
    /// authorization to perform it.
    error NotAuthorized();

    constructor(Core _core) {
        core = _core;
    }

    // ---
    // Core functionality
    // ---

    /// @notice Set up a new metalabel and group.
    function launchMetalabelAndSquad(address admin, string calldata metadataUri)
        external
    {
        // TODO: check if allowlisted or GA
        core.createMetalabel(admin, metadataUri);
        // TODO: launch group clone with initial info
        // TODO: set group permissions in core
    }

    /// @notice Create a new release and drop.
    function createReleaseAndDrop(
        uint256 metalabelId,
        string calldata metadataUri
    ) external {
        // TODO: check credentials
        core.createRelease(metalabelId, metadataUri);
        // TODO: create drop
    }
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import {Owned} from "solmate/src/auth/Owned.sol";

/// @notice Data stored for each metalabel.
struct MetalabelInfo {
    address admin;
}

/// @notice Data stored for each group.
// struct GroupInfo {
//     bool isAdmin;
//     bool isCore;
//     bytes8 permissions;
//     bytes8 grantablePermissions;
// }

/// @notice Expected interface for NFT collections / groups.
// interface IOwnerOf {
//     function ownerOf(uint256 tokenId) external view returns (address);
// }

/// @notice Metalabel core state contract.
contract Core is Owned {
    // ---
    // Events
    // ---

    /// @notice An adapter was registered or unregistered.
    event AdapterRegistration(address adapter, bool isRegistered);

    /// @notice A new metalabel was created.
    event MetalabelCreated(
        uint256 metalabelId,
        address admin,
        string metadataUri
    );

    /// @notice The metadata URI of a metalabel was updated.
    event MetalabelMetadataUpdated(uint256 metalabelId, string metadataUri);

    /// @notice The admin of a metalabel was updated.
    event MetalabelAdminUpdated(uint256 metalabelId, address admin);

    /// @notice The configuration for a group was updated.
    // event GroupInfoUpdated(uint256 metalabelId, address group, GroupInfo info);

    /// @notice A new release was created.
    event ReleaseCreated(
        uint256 metalabelId,
        uint48 releaseId,
        string releaseUri
    );

    /// @notice The metadata URI of a release was updated.
    event ReleaseMetadataUpdated(
        uint256 metalabelId,
        uint48 releaseId,
        string releaseUri
    );

    // ---
    // Errors
    // ---

    /// @notice A non-adapter msg.sender attempted to call a core method
    error NotAuthorized();

    // ---
    // Storage
    // ---

    /// @notice Check if a smart contract is a registered adapter
    mapping(address => bool) public isAdapter;

    /// @notice Current number of registered metalabels.
    uint256 public metalabelCount = 0;

    /// @notice Current number of releases
    uint48 public releaseCount = 0;

    /// @notice Get metalabel information.
    mapping(uint256 => MetalabelInfo) public metalabels;

    /// @notice Get the group info for a group within a metalabel.
    // mapping(uint256 => mapping(address => GroupInfo)) public groups;

    // ---
    // Modifiers
    // ---

    /// @notice Check if msg.sender is a registered adapter.
    modifier onlyAdapter() {
        if (!isAdapter[msg.sender]) {
            revert NotAuthorized();
        }
        _;
    }

    // ---
    // constructor
    // ---

    constructor() Owned(msg.sender) {}

    // ---
    // Owner functionality
    // ---

    /// @notice Add a new adapter.
    function registerAdapter(address adapter) external onlyOwner {
        isAdapter[adapter] = true;
        emit AdapterRegistration(adapter, true);
    }

    /// @notice Remove an adapter.
    function unregisterAdapter(address adapter) external onlyOwner {
        isAdapter[adapter] = false;
        emit AdapterRegistration(adapter, false);
    }

    // ---
    // Core: metalabel functionality
    // ---

    /// @notice Create a new metalabel.
    function createMetalabel(address admin, string calldata metadataUri)
        external
        onlyAdapter
        returns (uint256 metalabelId)
    {
        metalabelId = ++metalabelCount;
        metalabels[metalabelId] = MetalabelInfo({admin: admin});
        emit MetalabelCreated(metalabelId, admin, metadataUri);
    }

    /// @notice Change a metalabel's admin account.
    function setMetalabelAdmin(uint256 metalabelId, address admin)
        external
        onlyAdapter
    {
        metalabels[metalabelId].admin = admin;
        emit MetalabelAdminUpdated(metalabelId, admin);
    }

    /// @notice Change a metalabel's metadata URI.
    function setMetalabelMetadataUri(
        uint256 metalabelId,
        string calldata metadataUri
    ) external onlyAdapter {
        emit MetalabelMetadataUpdated(metalabelId, metadataUri);
    }

    // ---
    // Core: release functionality
    // ---

    /// @notice Create a new release within a metalabel.
    function createRelease(uint256 metalabelId, string calldata releaseUri)
        external
        onlyAdapter
        returns (uint48 releaseId)
    {
        releaseId = ++releaseCount;
        emit ReleaseCreated(metalabelId, releaseId, releaseUri);
    }

    // ---
    // Core: group functionality
    // ---

    /// @notice Set the group configuration for a group within a metalabel.
    // function setGroupInfo(
    //     uint256 metalabelId,
    //     address group,
    //     GroupInfo memory info
    // ) external onlyAdapter {
    //     groups[metalabelId][group] = info;
    //     emit GroupInfoUpdated(metalabelId, group, info);
    // }

    // ---
    // Core: permission views
    // ---

    // function hasPermission(
    //     uint256 metalabelId,
    //     address account,
    //     address group,
    //     uint256 credentialTokenId,
    //     bytes8 permissionMask
    // ) external view returns (bool) {
    //     // metalabel admin always has permission
    //     if (metalabels[metalabelId].admin == account) {
    //         return true;
    //     }

    //     // account must own credential
    //     if (IOwnerOf(group).ownerOf(credentialTokenId) != account) {
    //         return false;
    //     }

    //     // if group has admin flag, always true
    //     if (groups[metalabelId][group].isAdmin) {
    //         return true;
    //     }

    //     // must have all flags in mask
    //     return
    //         (groups[metalabelId][group].permissions & permissionMask) ==
    //         permissionMask;
    // }
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

library Permissions {
    bytes8 public constant CREATE_RELEASE = 0x0000000000000001;
    bytes8 public constant CREATE_GROUP = 0x0000000000000002;
    bytes8 public constant CREATE_DROP = 0x0000000000000004;
}

// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity >=0.8.0;

/// @notice Simple single owner authorization mixin.
/// @author Solmate (https://github.com/transmissions11/solmate/blob/main/src/auth/Owned.sol)
abstract contract Owned {
    /*//////////////////////////////////////////////////////////////
                                 EVENTS
    //////////////////////////////////////////////////////////////*/

    event OwnerUpdated(address indexed user, address indexed newOwner);

    /*//////////////////////////////////////////////////////////////
                            OWNERSHIP STORAGE
    //////////////////////////////////////////////////////////////*/

    address public owner;

    modifier onlyOwner() virtual {
        require(msg.sender == owner, "UNAUTHORIZED");

        _;
    }

    /*//////////////////////////////////////////////////////////////
                               CONSTRUCTOR
    //////////////////////////////////////////////////////////////*/

    constructor(address _owner) {
        owner = _owner;

        emit OwnerUpdated(address(0), _owner);
    }

    /*//////////////////////////////////////////////////////////////
                             OWNERSHIP LOGIC
    //////////////////////////////////////////////////////////////*/

    function setOwner(address newOwner) public virtual onlyOwner {
        owner = newOwner;

        emit OwnerUpdated(msg.sender, newOwner);
    }
}