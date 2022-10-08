// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;
import "../../smart-contract-wallet/base/ModuleManager.sol";

contract SessionKeyModule {
    string public constant NAME = "Session Key Module";
    string public constant VERSION = "0.1.0";

    struct TokenApproval {
        bool enable;
        uint256 amount;
    }

    // PermissionParam struct to be used as parameter in createSession method
    struct PermissionParam {
        address whitelistDestination;
        bytes[] whitelistMethods;
        uint256 tokenAmount;
    }

    // SessionParam struct to be used as parameter in createSession method
    struct SessionParam {
        uint256 startTimestamp;
        uint256 endTimestamp;
        bool enable;
    }

    struct PermissionStorage {
        address[] whitelistDestinations;
        mapping(address => bytes[]) whitelistMethods;
        mapping(address => TokenApproval) tokenApprovals;
    }

    struct Session {
        address smartAccount;
        address sessionKey;
        uint256 startTimestamp;
        uint256 endTimestamp;
        bool enable;
        PermissionStorage permission;
    }

    mapping(address => Session) internal sessionMap;

    function createSession(
        address sessionKey,
        PermissionParam[] calldata permissions,
        SessionParam calldata sessionParam
    ) external {
        require(
            !sessionMap[sessionKey].enable,
            "Session for key is already enabled"
        );
        Session storage _session = sessionMap[sessionKey];
        _session.enable = true;
        _session.startTimestamp = sessionParam.startTimestamp;
        _session.endTimestamp = sessionParam.endTimestamp;
        _session.sessionKey = sessionKey;
        _session.smartAccount = msg.sender;

        address[] memory whitelistAddresses = new address[](permissions.length);
        for (uint256 index = 0; index < permissions.length; index++) {
            PermissionParam memory permission = permissions[index];
            whitelistAddresses[index] = permission.whitelistDestination;
            _session.permission.whitelistMethods[
                permission.whitelistDestination
            ] = permission.whitelistMethods;
            if (permission.tokenAmount > 0) {
                _session.permission.tokenApprovals[
                    permission.whitelistDestination
                ] = TokenApproval({
                    enable: true,
                    amount: permission.tokenAmount
                });
            }
        }
        _session.permission.whitelistDestinations = whitelistAddresses;
    }

    function getSessionInfo(address sessionKey)
        public
        view
        returns (SessionParam memory sessionInfo)
    {
        Session storage session = sessionMap[sessionKey];
        sessionInfo = SessionParam({
            startTimestamp: session.startTimestamp,
            endTimestamp: session.endTimestamp,
            enable: session.enable
        });
    }

    function getWhitelistDestinations(address sessionKey)
        public
        view
        returns (address[] memory)
    {
        Session storage session = sessionMap[sessionKey];
        return session.permission.whitelistDestinations;
    }

    function getWhitelistMethods(
        address sessionKey,
        address whitelistDestination
    ) public view returns (bytes[] memory) {
        Session storage session = sessionMap[sessionKey];
        return session.permission.whitelistMethods[whitelistDestination];
    }

    function getTokenPermissions(address sessionKey, address token)
        public
        view
        returns (TokenApproval memory tokenApproval)
    {
        Session storage session = sessionMap[sessionKey];
        return session.permission.tokenApprovals[token];
    }

    function executeTransaction(
        ModuleManager smartAccount,
        address payable _to,
        uint96 _amount,
        bytes memory _data
    ) external {}
}

// SPDX-License-Identifier: LGPL-3.0-only
pragma solidity ^0.8.0;

import "../common/Enum.sol";
import "../common/SelfAuthorized.sol";
import "./Executor.sol";

/// @title Module Manager - A contract that manages modules that can execute transactions via this contract
contract ModuleManager is SelfAuthorized, Executor {    
    // Events
    event EnabledModule(address module);
    event DisabledModule(address module);
    event ExecutionFromModuleSuccess(address indexed module);
    event ExecutionFromModuleFailure(address indexed module);

    address internal constant SENTINEL_MODULES = address(0x1);

    mapping(address => address) internal modules;

    function setupModules(address to, bytes memory data) internal {
        require(modules[SENTINEL_MODULES] == address(0), "BSA100");
        modules[SENTINEL_MODULES] = SENTINEL_MODULES;
        if (to != address(0))
            // Setup has to complete successfully or transaction fails.
            require(execute(to, 0, data, Enum.Operation.DelegateCall, gasleft()), "BSA000");
    }

    /// @dev Allows to add a module to the whitelist.
    ///      This can only be done via a Safe transaction.
    /// @notice Enables the module `module` for the Safe.
    /// @param module Module to be whitelisted.
    function enableModule(address module) public authorized {
        // Module address cannot be null or sentinel.
        require(module != address(0) && module != SENTINEL_MODULES, "BSA101");
        // Module cannot be added twice.
        require(modules[module] == address(0), "BSA102");
        modules[module] = modules[SENTINEL_MODULES];
        modules[SENTINEL_MODULES] = module;
        emit EnabledModule(module);
    }

    /// @dev Allows to remove a module from the whitelist.
    ///      This can only be done via a Safe transaction.
    /// @notice Disables the module `module` for the Safe.
    /// @param prevModule Module that pointed to the module to be removed in the linked list
    /// @param module Module to be removed.
    function disableModule(address prevModule, address module) public authorized {
        // Validate module address and check that it corresponds to module index.
        require(module != address(0) && module != SENTINEL_MODULES, "BSA101");
        require(modules[prevModule] == module, "BSA103");
        modules[prevModule] = modules[module];
        modules[module] = address(0);
        emit DisabledModule(module);
    }

    /// @dev Allows a Module to execute a Safe transaction without any further confirmations.
    /// @param to Destination address of module transaction.
    /// @param value Ether value of module transaction.
    /// @param data Data payload of module transaction.
    /// @param operation Operation type of module transaction.
    function execTransactionFromModule(
        address to,
        uint256 value,
        bytes memory data,
        Enum.Operation operation
    ) public virtual returns (bool success) {
        // Only whitelisted modules are allowed.
        require(msg.sender != SENTINEL_MODULES && modules[msg.sender] != address(0), "BSA104");
        // Execute transaction without further confirmations.
        success = execute(to, value, data, operation, gasleft());
        if (success) emit ExecutionFromModuleSuccess(msg.sender);
        else emit ExecutionFromModuleFailure(msg.sender);
    }

    /// @dev Allows a Module to execute a Safe transaction without any further confirmations and return data
    /// @param to Destination address of module transaction.
    /// @param value Ether value of module transaction.
    /// @param data Data payload of module transaction.
    /// @param operation Operation type of module transaction.
    function execTransactionFromModuleReturnData(
        address to,
        uint256 value,
        bytes memory data,
        Enum.Operation operation
    ) public returns (bool success, bytes memory returnData) {
        success = execTransactionFromModule(to, value, data, operation);
        // solhint-disable-next-line no-inline-assembly
        assembly {
            // Load free memory location
            let ptr := mload(0x40)
            // We allocate memory for the return data by setting the free memory location to
            // current free memory location + data size + 32 bytes for data size value
            mstore(0x40, add(ptr, add(returndatasize(), 0x20)))
            // Store the size
            mstore(ptr, returndatasize())
            // Store the data
            returndatacopy(add(ptr, 0x20), 0, returndatasize())
            // Point the return data to the correct memory location
            returnData := ptr
        }
    }

    /// @dev Returns if an module is enabled
    /// @return True if the module is enabled
    function isModuleEnabled(address module) public view returns (bool) {
        return SENTINEL_MODULES != module && modules[module] != address(0);
    }

    /// @dev Returns array of modules. Useful for a widget
    /// @param start Start of the page.
    /// @param pageSize Maximum number of modules that should be returned.
    /// @return array Array of modules.
    /// @return next Start of the next page.
    function getModulesPaginated(address start, uint256 pageSize) external view returns (address[] memory array, address next) {
        // Init array with max page size
        array = new address[](pageSize);

        // Populate return array
        uint256 moduleCount = 0;
        address currentModule = modules[start];
        while (currentModule != address(0x0) && currentModule != SENTINEL_MODULES && moduleCount < pageSize) {
            array[moduleCount] = currentModule;
            currentModule = modules[currentModule];
            moduleCount++;
        }
        next = currentModule;
        // Set correct size of returned array
        // solhint-disable-next-line no-inline-assembly
        assembly {
            mstore(array, moduleCount)
        }
    }
}

// SPDX-License-Identifier: LGPL-3.0-only
pragma solidity ^0.8.0;

/// @title Enum - Collection of enums
contract Enum {
    enum Operation {Call, DelegateCall}
}

// SPDX-License-Identifier: LGPL-3.0-only
pragma solidity ^0.8.0;

import "../common/Enum.sol";

/// @title Executor - A contract that can execute transactions
contract Executor {
    // Could add a flag fromEntryPoint for AA txn
    event ExecutionFailure(address to, uint256 value, bytes data, Enum.Operation operation, uint256 txGas);
    event ExecutionSuccess(address to, uint256 value, bytes data, Enum.Operation operation, uint256 txGas);

    // Could add a flag fromEntryPoint for AA txn
    function execute(
        address to,
        uint256 value,
        bytes memory data,
        Enum.Operation operation,
        uint256 txGas
    ) internal returns (bool success) {
        if (operation == Enum.Operation.DelegateCall) {
            // solhint-disable-next-line no-inline-assembly
            assembly {
                success := delegatecall(txGas, to, add(data, 0x20), mload(data), 0, 0)
            }
        } else {
            // solhint-disable-next-line no-inline-assembly
            assembly {
                success := call(txGas, to, value, add(data, 0x20), mload(data), 0, 0)
            }
        }
        // Emit events here..
        if (success) emit ExecutionSuccess(to, value, data, operation, txGas);
        else emit ExecutionFailure(to, value, data, operation, txGas);
    }
    
}

// SPDX-License-Identifier: LGPL-3.0-only
pragma solidity ^0.8.0;

/// @title SelfAuthorized - authorizes current contract to perform actions
contract SelfAuthorized {
    function requireSelfCall() private view {
        require(msg.sender == address(this), "BSA031");
    }

    modifier authorized() {
        // This is a function call as it minimized the bytecode size
        requireSelfCall();
        _;
    }
}