// SPDX-License-Identifier: GPL-3.0

pragma solidity 0.8.10;
import "IProxyRegistry.sol";
import "IGamingProxy.sol";
import "AccessManager.sol";

contract ProxyRegistry is IProxyRegistry, AccessManager {
    mapping(address => address) public proxies;

    constructor(IRoleRegistry _roleRegistry) {
        setRoleRegistry(_roleRegistry);
    }

    function setProxyForGameContract(
        address gameContract,
        address proxyContract
    ) external override onlyRole(Roles.PROXY_SETTER) {
        require(proxies[gameContract] == address(0), "Proxy already set!");
        proxies[gameContract] = proxyContract;
    }

    function updateProxyForGameContract(
        address gameContract,
        address proxyContract
    ) external override onlyRole(Roles.PROXY_SETTER) {
        removeProxyForGameContract(gameContract);
        proxies[gameContract] = proxyContract;
    }

    function getProxyForGameContract(address gameContract)
        external
        view
        override
        returns (address)
    {
        return proxies[gameContract];
    }

    function isWhitelistedGameContract(address gameContract)
        external
        view
        override
        returns (bool)
    {
        return proxies[gameContract] != address(0);
    }

    function removeProxyForGameContract(address gameContract)
        public
        override
        onlyRole(Roles.PROXY_SETTER)
    {
        require(proxies[gameContract] != address(0), "Proxy already set!");
        IGamingProxy(proxies[gameContract]).kill();
        proxies[gameContract] = address(0);
    }
}

// SPDX-License-Identifier: GPL-3.0

pragma solidity 0.8.10;

// Registry of all currently used proxy contracts
interface IProxyRegistry {
    function setProxyForGameContract(
        address gameContract,
        address proxyContract
    ) external;

    function updateProxyForGameContract(
        address gameContract,
        address proxyContract
    ) external;

    function removeProxyForGameContract(address gameContract) external;

    function getProxyForGameContract(address gameContract)
        external
        view
        returns (address);

    // Function to check if the gameContract is whitelisted
    function isWhitelistedGameContract(address gameContract)
        external
        view
        returns (bool);
}

// SPDX-License-Identifier: GPL-3.0

pragma solidity 0.8.10;

// This will need to implement the delegation method
interface IGamingProxy {
    // Main point of entry for calling the gaming contracts (this will delegatecall to gaming contract)
    function postCallHook(
        address gameContract,
        bytes calldata data_,
        bytes calldata returnData
    ) external;

    function whitelistFunction(
        address gameContract,
        bytes4 selector,
        bool claimFunction
    ) external;

    function batchWhitelistFunction(
        address[] memory gameContracts,
        bytes4[] memory selectors,
        bool[] memory claimFunction
    ) external;

    function removeFunctionsFromWhitelist(address gameContract, bytes4 selector)
        external;

    function kill() external;

    function validateCall(address gameContract, bytes calldata data_)
        external
        view
        returns (bytes memory);

    function validateOasisClaimCall(address gameContract, bytes calldata data_)
        external
        view
        returns (bytes memory);

    function isFunctionsWhitelisted(address gameContract, bytes4 selector)
        external
        view
        returns (bool);

    function isClaimFunction(address gameContract, bytes4 selector)
        external
        view
        returns (bool);

    function gamingContracts() external view returns (address[] memory);

    function getFunctionsForContract(address gameContract)
        external
        view
        returns (bytes4[] memory);
}

// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity 0.8.10;

import "RoleLibrary.sol";

import "IRoleRegistry.sol";

/**
 * @notice Provides modifiers for authorization
 */
contract AccessManager {
    IRoleRegistry internal roleRegistry;
    bool public isInitialised = false;

    modifier onlyRole(bytes32 role) {
        require(roleRegistry.hasRole(role, msg.sender), "Unauthorized access");
        _;
    }

    modifier onlyGovernance() {
        require(
            roleRegistry.hasRole(Roles.ADMIN, msg.sender),
            "Unauthorized access"
        );
        _;
    }

    modifier onlyRoles2(bytes32 role1, bytes32 role2) {
        require(
            roleRegistry.hasRole(role1, msg.sender) ||
                roleRegistry.hasRole(role2, msg.sender),
            "Unauthorized access"
        );
        _;
    }

    function setRoleRegistry(IRoleRegistry _roleRegistry) public {
        require(!isInitialised, "RoleRegistry already initialised");
        roleRegistry = _roleRegistry;
        isInitialised = true;
    }
}

// SPDX-License-Identifier: GPL-3.0-or-later

pragma solidity 0.8.10;

library Roles {
    bytes32 internal constant ADMIN = "admin";
    bytes32 internal constant REWARD_CLAIMER = "reward_claimer";
    bytes32 internal constant MISSION_TERMINATOR = "mission_terminator";
    bytes32 internal constant FUNCTION_WHITELISTER = "function_whitelister";
    bytes32 internal constant PROXY_SETTER = "proxy_setter";
    bytes32 internal constant OWNER_WHITELISTER = "owner_whitelister";
    bytes32 internal constant REWARD_DISTRIBUTOR = "reward_distributor";
    bytes32 internal constant GAMECOLLECTION_SETTER = "gamecollection_setter";
    bytes32 internal constant PROXY_REGISTRY = "proxy_registry";
}

// SPDX-License-Identifier: GPL-3.0

pragma solidity 0.8.10;

interface IRoleRegistry {
    function grantRole(bytes32 role, address account) external;

    function revokeRole(bytes32 _role, address account) external;

    function hasRole(bytes32 _role, address account)
        external
        view
        returns (bool);
}