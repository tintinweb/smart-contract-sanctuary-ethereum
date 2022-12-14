// SPDX-License-Identifier: GPL-3.0

pragma solidity 0.8.10;

import "IGamingProxy.sol";
import "AccessManager.sol";

contract GamingProxy is IGamingProxy, AccessManager {
    mapping(address => mapping(bytes4 => bool)) public whitelistedFunctions;
    mapping(address => mapping(bytes4 => bool)) public oasisClaimFunctions;
    mapping(address => bytes4[]) public functionsForContract;

    address[] public _gamingContracts;

    bool public killed;

    constructor(IRoleRegistry _roleRegistry) {
        setRoleRegistry(_roleRegistry);
    }

    function postCallHook(
        address gameContract,
        bytes calldata data_,
        bytes calldata returnData
    ) external override {
        // This allows to do some post-processing which would be game specific...
    }

    function whitelistFunction(
        address gameContract,
        bytes4 selector,
        bool claimFunction
    ) external override onlyRole(Roles.FUNCTION_WHITELISTER) {
        _whitelistFunction(gameContract, selector, claimFunction);
    }

    function batchWhitelistFunction(
        address[] memory gameContracts,
        bytes4[] memory selectors,
        bool[] memory claimFunction
    ) external override onlyRole(Roles.FUNCTION_WHITELISTER) {
        uint256 length = gameContracts.length;
        require(
            length == selectors.length,
            "Must supply a game contract for each selector!"
        );
        for (uint32 i = 0; i < length; i++) {
            _whitelistFunction(
                gameContracts[i],
                selectors[i],
                claimFunction[i]
            );
        }
    }

    function removeFunctionsFromWhitelist(address gameContract, bytes4 selector)
        external
        override
        onlyRole(Roles.FUNCTION_WHITELISTER)
    {
        uint256 length = functionsForContract[gameContract].length;
        for (uint32 i = 0; i < length; i++) {
            if (functionsForContract[gameContract][i] == selector) {
                functionsForContract[gameContract][i] = functionsForContract[
                    gameContract
                ][length - 1];
                functionsForContract[gameContract].pop();
            }
        }
        length = _gamingContracts.length;
        for (uint32 i = 0; i < length; i++) {
            if (_gamingContracts[i] == gameContract) {
                if (functionsForContract[gameContract].length == 0) {
                    _gamingContracts[i] = _gamingContracts[length - 1];
                    _gamingContracts.pop();
                }
            }
        }
        whitelistedFunctions[gameContract][selector] = false;
    }

    function kill()
        external
        override
        onlyRoles2(Roles.FUNCTION_WHITELISTER, Roles.PROXY_REGISTRY)
    {
        require(!killed, "Already killed");
        killed = true;
    }

    function validateCall(address gameContract, bytes calldata data_)
        external
        view
        override
        returns (bytes memory)
    {
        require(!killed, "Proxy is no longer active!");
        require(
            isFunctionsWhitelisted(gameContract, bytes4(data_[:4])),
            "Function not whitelisted!"
        );
        // This could be changed to modify the data if needed for some games
        return data_;
    }

    function validateOasisClaimCall(address gameContract, bytes calldata data_)
        external
        view
        override
        returns (bytes memory)
    {
        require(!killed, "Proxy is no longer active!");
        require(
            isClaimFunction(gameContract, bytes4(data_[:4])),
            "Function is not a claim function!"
        );
        // This could be changed to modify the data if needed for some games
        return data_;
    }

    function getFunctionsForContract(address gameContract)
        external
        view
        override
        returns (bytes4[] memory)
    {
        return functionsForContract[gameContract];
    }

    function gamingContracts()
        external
        view
        override
        returns (address[] memory)
    {
        return _gamingContracts;
    }

    function isFunctionsWhitelisted(address gameContract, bytes4 selector)
        public
        view
        override
        returns (bool)
    {
        return whitelistedFunctions[gameContract][selector];
    }

    function isClaimFunction(address gameContract, bytes4 selector)
        public
        view
        override
        returns (bool)
    {
        return oasisClaimFunctions[gameContract][selector];
    }

    function _whitelistFunction(
        address gameContract,
        bytes4 selector,
        bool claimFunction
    ) internal {
        whitelistedFunctions[gameContract][selector] = true;
        if (claimFunction) {
            oasisClaimFunctions[gameContract][selector] = true;
        }
        if (!_functionListedForContract(gameContract, selector)) {
            functionsForContract[gameContract].push(selector);
        }
        if (!_gamingContractListed(gameContract)) {
            _gamingContracts.push(gameContract);
        }
    }

    function _gamingContractListed(address gamingContract)
        internal
        view
        returns (bool)
    {
        uint256 length = _gamingContracts.length;
        for (uint32 i = 0; i < length; i++) {
            if (_gamingContracts[i] == gamingContract) {
                return true;
            }
        }
        return false;
    }

    function _functionListedForContract(address gamingContract, bytes4 selector)
        internal
        view
        returns (bool)
    {
        uint256 length = functionsForContract[gamingContract].length;
        for (uint32 i = 0; i < length; i++) {
            if (functionsForContract[gamingContract][i] == selector) {
                return true;
            }
        }
        return false;
    }
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