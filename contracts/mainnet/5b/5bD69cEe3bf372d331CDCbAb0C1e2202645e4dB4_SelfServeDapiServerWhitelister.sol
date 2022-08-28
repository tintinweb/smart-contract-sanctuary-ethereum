// SPDX-License-Identifier: MIT
pragma solidity 0.8.14;

import "@api3/airnode-protocol-v1/contracts/dapis/DapiReader.sol";
import "./interfaces/ISelfServeDapiServerWhitelister.sol";
import "@api3/airnode-protocol-v1/contracts/dapis/interfaces/IDapiServer.sol";
import "@api3/airnode-protocol-v1/contracts/whitelist/interfaces/IWhitelistWithManager.sol";

contract SelfServeDapiServerWhitelister is
    DapiReader,
    ISelfServeDapiServerWhitelister
{
    constructor(address _dapiServer) DapiReader(_dapiServer) {}

    function allowToReadDataFeedWithIdFor30Days(
        bytes32 dataFeedId,
        address reader
    ) public override {
        (uint64 expirationTimestamp, ) = IDapiServer(dapiServer)
            .dataFeedIdToReaderToWhitelistStatus(dataFeedId, reader);
        uint64 targetedExpirationTimestamp = uint64(block.timestamp + 30 days);
        if (targetedExpirationTimestamp > expirationTimestamp) {
            IWhitelistWithManager(dapiServer).extendWhitelistExpiration(
                dataFeedId,
                reader,
                targetedExpirationTimestamp
            );
        }
    }

    function allowToReadDataFeedWithDapiNameFor30Days(
        bytes32 dapiName,
        address reader
    ) external override {
        allowToReadDataFeedWithIdFor30Days(
            keccak256(abi.encodePacked(dapiName)),
            reader
        );
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./interfaces/IDapiReader.sol";

/// @title Contract to be inherited by contracts that will read from a
/// DapiServer contract
contract DapiReader is IDapiReader {
    /// @notice DapiServer contract address
    address public override dapiServer;

    /// @param _dapiServer DapiServer contract address
    constructor(address _dapiServer) {
        setDapiServer(_dapiServer);
    }

    /// @notice Called internally to update the DapiServer contract address
    /// @dev Inheriting contracts are highly recommended to expose this
    /// functionality to be able to migrate between DapiServer contracts.
    /// Otherwise, when the DapiServer goes out of service for any reason,
    /// the dependent contract will go defunct.
    /// Since this is a critical action, it needs to be protected behind
    /// mechanisms such as decentralized governance, timelocks, etc.
    /// @param _dapiServer DapiServer contract address
    function setDapiServer(address _dapiServer) internal {
        require(_dapiServer != address(0), "dAPI server address zero");
        dapiServer = _dapiServer;
    }
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.14;

import "@api3/airnode-protocol-v1/contracts/dapis/interfaces/IDapiReader.sol";

interface ISelfServeDapiServerWhitelister is IDapiReader {
    function allowToReadDataFeedWithIdFor30Days(bytes32 dataFeedId, address reader)
        external;

    function allowToReadDataFeedWithDapiNameFor30Days(bytes32 dapiName, address reader)
        external;
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "../../protocol/interfaces/IAirnodeRequester.sol";

interface IDapiServer is IAirnodeRequester {
    event SetRrpBeaconUpdatePermissionStatus(
        address indexed sponsor,
        address indexed rrpBeaconUpdateRequester,
        bool status
    );

    event RequestedRrpBeaconUpdate(
        bytes32 indexed beaconId,
        address indexed sponsor,
        address indexed requester,
        bytes32 requestId,
        address airnode,
        bytes32 templateId
    );

    event RequestedRrpBeaconUpdateRelayed(
        bytes32 indexed beaconId,
        address indexed sponsor,
        address indexed requester,
        bytes32 requestId,
        address airnode,
        address relayer,
        bytes32 templateId
    );

    event UpdatedBeaconWithRrp(
        bytes32 indexed beaconId,
        bytes32 requestId,
        int256 value,
        uint256 timestamp
    );

    event RegisteredBeaconUpdateSubscription(
        bytes32 indexed subscriptionId,
        address airnode,
        bytes32 templateId,
        bytes parameters,
        bytes conditions,
        address relayer,
        address sponsor,
        address requester,
        bytes4 fulfillFunctionId
    );

    event UpdatedBeaconWithPsp(
        bytes32 indexed beaconId,
        bytes32 subscriptionId,
        int224 value,
        uint32 timestamp
    );

    event UpdatedBeaconWithSignedData(
        bytes32 indexed beaconId,
        int256 value,
        uint256 timestamp
    );

    event UpdatedBeaconSetWithBeacons(
        bytes32 indexed beaconSetId,
        int224 value,
        uint32 timestamp
    );

    event UpdatedBeaconSetWithSignedData(
        bytes32 indexed dapiId,
        int224 value,
        uint32 timestamp
    );

    event AddedUnlimitedReader(address indexed unlimitedReader);

    event SetDapiName(
        bytes32 indexed dapiName,
        bytes32 dataFeedId,
        address indexed sender
    );

    function setRrpBeaconUpdatePermissionStatus(
        address rrpBeaconUpdateRequester,
        bool status
    ) external;

    function requestRrpBeaconUpdate(
        address airnode,
        bytes32 templateId,
        address sponsor
    ) external returns (bytes32 requestId);

    function requestRrpBeaconUpdateRelayed(
        address airnode,
        bytes32 templateId,
        address relayer,
        address sponsor
    ) external returns (bytes32 requestId);

    function fulfillRrpBeaconUpdate(
        bytes32 requestId,
        uint256 timestamp,
        bytes calldata data
    ) external;

    function registerBeaconUpdateSubscription(
        address airnode,
        bytes32 templateId,
        bytes memory conditions,
        address relayer,
        address sponsor
    ) external returns (bytes32 subscriptionId);

    function conditionPspBeaconUpdate(
        bytes32 subscriptionId,
        bytes calldata data,
        bytes calldata conditionParameters
    ) external view returns (bool);

    function fulfillPspBeaconUpdate(
        bytes32 subscriptionId,
        address airnode,
        address relayer,
        address sponsor,
        uint256 timestamp,
        bytes calldata data,
        bytes calldata signature
    ) external;

    function updateBeaconWithSignedData(
        address airnode,
        bytes32 beaconId,
        uint256 timestamp,
        bytes calldata data,
        bytes calldata signature
    ) external;

    function updateBeaconSetWithBeacons(bytes32[] memory beaconIds)
        external
        returns (bytes32 beaconSetId);

    function updateBeaconSetWithBeaconsAndReturnCondition(
        bytes32[] memory beaconIds,
        uint256 updateThresholdInPercentage
    ) external returns (bool);

    function conditionPspBeaconSetUpdate(
        bytes32 subscriptionId,
        bytes calldata data,
        bytes calldata conditionParameters
    ) external returns (bool);

    function fulfillPspBeaconSetUpdate(
        bytes32 subscriptionId,
        address airnode,
        address relayer,
        address sponsor,
        uint256 timestamp,
        bytes calldata data,
        bytes calldata signature
    ) external;

    function updateBeaconSetWithSignedData(
        address[] memory airnodes,
        bytes32[] memory templateIds,
        uint256[] memory timestamps,
        bytes[] memory data,
        bytes[] memory signatures
    ) external returns (bytes32 beaconSetId);

    function addUnlimitedReader(address unlimitedReader) external;

    function setDapiName(bytes32 dapiName, bytes32 dataFeedId) external;

    function dapiNameToDataFeedId(bytes32 dapiName)
        external
        view
        returns (bytes32);

    function readDataFeedWithId(bytes32 dataFeedId)
        external
        view
        returns (int224 value, uint32 timestamp);

    function readDataFeedValueWithId(bytes32 dataFeedId)
        external
        view
        returns (int224 value);

    function readDataFeedWithDapiName(bytes32 dapiName)
        external
        view
        returns (int224 value, uint32 timestamp);

    function readDataFeedValueWithDapiName(bytes32 dapiName)
        external
        view
        returns (int224 value);

    function readerCanReadDataFeed(bytes32 dataFeedId, address reader)
        external
        view
        returns (bool);

    function dataFeedIdToReaderToWhitelistStatus(
        bytes32 dataFeedId,
        address reader
    )
        external
        view
        returns (uint64 expirationTimestamp, uint192 indefiniteWhitelistCount);

    function dataFeedIdToReaderToSetterToIndefiniteWhitelistStatus(
        bytes32 dataFeedId,
        address reader,
        address setter
    ) external view returns (bool indefiniteWhitelistStatus);

    function deriveBeaconId(address airnode, bytes32 templateId)
        external
        pure
        returns (bytes32 beaconId);

    function deriveBeaconSetId(bytes32[] memory beaconIds)
        external
        pure
        returns (bytes32 beaconSetId);

    // solhint-disable-next-line func-name-mixedcase
    function DAPI_NAME_SETTER_ROLE_DESCRIPTION()
        external
        view
        returns (string memory);

    // solhint-disable-next-line func-name-mixedcase
    function HUNDRED_PERCENT() external view returns (uint256);

    function dapiNameSetterRole() external view returns (bytes32);

    function sponsorToRrpBeaconUpdateRequesterToPermissionStatus(
        address sponsor,
        address updateRequester
    ) external view returns (bool);

    function subscriptionIdToBeaconId(bytes32 subscriptionId)
        external
        view
        returns (bytes32);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./IWhitelistRolesWithManager.sol";

interface IWhitelistWithManager is IWhitelistRolesWithManager {
    event ExtendedWhitelistExpiration(
        bytes32 indexed serviceId,
        address indexed user,
        address indexed sender,
        uint256 expiration
    );

    event SetWhitelistExpiration(
        bytes32 indexed serviceId,
        address indexed user,
        address indexed sender,
        uint256 expiration
    );

    event SetIndefiniteWhitelistStatus(
        bytes32 indexed serviceId,
        address indexed user,
        address indexed sender,
        bool status,
        uint192 indefiniteWhitelistCount
    );

    event RevokedIndefiniteWhitelistStatus(
        bytes32 indexed serviceId,
        address indexed user,
        address indexed setter,
        address sender,
        uint192 indefiniteWhitelistCount
    );

    function extendWhitelistExpiration(
        bytes32 serviceId,
        address user,
        uint64 expirationTimestamp
    ) external;

    function setWhitelistExpiration(
        bytes32 serviceId,
        address user,
        uint64 expirationTimestamp
    ) external;

    function setIndefiniteWhitelistStatus(
        bytes32 serviceId,
        address user,
        bool status
    ) external;

    function revokeIndefiniteWhitelistStatus(
        bytes32 serviceId,
        address user,
        address setter
    ) external;
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface IDapiReader {
    function dapiServer() external view returns (address);
}

/// @dev We use the part of the interface that will persist between
/// DapiServer versions
interface IBaseDapiServer {
    function readDataFeedWithId(bytes32 dataFeedId)
        external
        view
        returns (int224 value, uint32 timestamp);

    function readDataFeedWithDapiName(bytes32 dapiName)
        external
        view
        returns (int224 value, uint32 timestamp);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface IAirnodeRequester {
    function airnodeProtocol() external view returns (address);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./IWhitelistRoles.sol";
import "../../access-control-registry/interfaces/IAccessControlRegistryAdminnedWithManager.sol";

interface IWhitelistRolesWithManager is
    IWhitelistRoles,
    IAccessControlRegistryAdminnedWithManager
{
    function whitelistExpirationExtenderRole() external view returns (bytes32);

    function whitelistExpirationSetterRole() external view returns (bytes32);

    function indefiniteWhitelisterRole() external view returns (bytes32);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface IWhitelistRoles {
    // solhint-disable-next-line func-name-mixedcase
    function WHITELIST_EXPIRATION_EXTENDER_ROLE_DESCRIPTION()
        external
        view
        returns (string memory);

    // solhint-disable-next-line func-name-mixedcase
    function WHITELIST_EXPIRATION_SETTER_ROLE_DESCRIPTION()
        external
        view
        returns (string memory);

    // solhint-disable-next-line func-name-mixedcase
    function INDEFINITE_WHITELISTER_ROLE_DESCRIPTION()
        external
        view
        returns (string memory);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./IAccessControlRegistryAdminned.sol";

interface IAccessControlRegistryAdminnedWithManager is
    IAccessControlRegistryAdminned
{
    function manager() external view returns (address);

    function adminRole() external view returns (bytes32);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./IAccessControlRegistryUser.sol";

interface IAccessControlRegistryAdminned is IAccessControlRegistryUser {
    function adminRoleDescription() external view returns (string memory);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface IAccessControlRegistryUser {
    function accessControlRegistry() external view returns (address);
}