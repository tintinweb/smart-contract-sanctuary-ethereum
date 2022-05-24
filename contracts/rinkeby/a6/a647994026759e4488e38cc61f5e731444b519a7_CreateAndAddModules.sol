// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.6;
import "../base/Module.sol";


/// @title Create and Add Modules - Allows to create and add multiple module in one transaction.
/// @author Stefan George - <[email protected]>
/// @author Richard Meissner - <[email protected]>
contract CreateAndAddModules {

    /// @dev Function required to compile contract. Gnosis Safe function is called instead.
    /// @param module Not used.
    function enableModule(
        // solhint-disable-next-line no-unused-vars
        Module module
    )
        public
    {
        revert();
    }

    /// @dev Allows to create and add multiple module in one transaction.
    /// @param proxyFactory Module proxy factory contract.
    /// @param data Modules constructor payload. This is the data for each proxy factory call concatinated.
    ///        (e.g. <byte_array_len_1><byte_array_data_1><byte_array_len_2><byte_array_data_2>)
    function createAndAddModules(
        address proxyFactory,
        bytes memory data
    )
        public
    {
        uint256 length = data.length;
        Module module;
        uint256 i = 0;
        while (i < length) {
            /* solhint-disable no-inline-assembly */
            assembly {
                let createBytesLength := mload(add(0x20, add(data, i)))
                let createBytes := add(0x40, add(data, i))

                let output := mload(0x40)
                // solhint-disable-next-line max-line-length
                if eq(delegatecall(gas(), proxyFactory, createBytes, createBytesLength, output, 0x20), 0) { revert(0, 0) }
                module := and(mload(output), 0xffffffffffffffffffffffffffffffffffffffff)

                // Data is always padded to 32 bytes
                i := add(i, add(0x20, mul(div(add(createBytesLength, 0x1f), 0x20), 0x20)))
            }
            /* solhint-disable no-inline-assembly */

            this.enableModule(module);
        }
    }
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.6;
import "../common/MasterCopy.sol";
import "./ModuleManager.sol";


/// @title Module - Base class for modules.
/// @author Stefan George - <[email protected]>
/// @author Richard Meissner - <[email protected]>
contract Module is MasterCopy {

    ModuleManager public manager;
    
    function requireAuthorizedByManager()
        public
        view
    {
        require(msg.sender == address(manager), "Method can only be called from manager");
    
    }
    
    function setManager()
        internal
    {
        // manager can only be 0 at initalization of contract.
        // Check ensures that setup function can only be called once.
        require(address(manager) == address(0), "Manager has already been set");
        manager = ModuleManager(msg.sender);
    }
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.6;
import "./SelfAuthorized.sol";


/// @title MasterCopy - Base for master copy contracts (should always be first super contract)
///         This contract is tightly coupled to our proxy contract (see `proxies/GnosisSafeProxy.sol`)
/// @author Richard Meissner - <[email protected]>
contract MasterCopy is SelfAuthorized {

    // masterCopy always needs to be first declared variable,
    // to ensure that it is at the same location as in the Proxy contract.
    // It should also always be ensured that the address is stored alone (uses a full word)
    address private masterCopy;

    event ChangedMasterCopy(
        address masterCopy
    );

    /// @dev Allows to upgrade the contract. This can only be done via a Safe transaction.
    /// @param _masterCopy New contract address.
    function changeMasterCopy(
        address _masterCopy
    )
        public
    {
        requireAuthorized();
        // Master copy address cannot be null.
        require(_masterCopy != address(0), "Invalid master copy address provided");
        masterCopy = _masterCopy;
        emit ChangedMasterCopy(_masterCopy);
    }
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.6;
import "../common/Enum.sol";
import "../common/SelfAuthorized.sol";
import "./Executor.sol";
import "./Module.sol";

/// @title Module Manager - A contract that manages modules that can execute transactions via this contract
/// @author Stefan George - <[email protected]>
/// @author Richard Meissner - <[email protected]>
contract ModuleManager is SelfAuthorized, Executor {

    address internal constant SENTINEL_MODULES = address(0x1);
    mapping (address => address) internal modules;

    event EnabledModule(
        Module indexed module
    );

    event DisabledModule(
        Module indexed module
    );

    event ExecutionFromModuleSuccess(
        address indexed module
    );

    event ExecutionFromModuleFailure(
        address indexed module
    );

    /// @dev Allows to add a module to the list of allowed modules.
    ///      This can only be done via a Safe transaction.
    /// @param module Module to be added to the allowed modules.
    function enableModule(
        Module module
    )
        public
        
    {
        requireAuthorized();

        // Module address cannot be null or sentinel.
        require(
            address(module) != address(0) && address(module) != SENTINEL_MODULES,
            "Invalid module address provided"
        );
        // Module cannot be added twice.
        require(modules[address(module)] == address(0), "Module has already been added");
        modules[address(module)] = modules[SENTINEL_MODULES];
        modules[SENTINEL_MODULES] = address(module);
        emit EnabledModule(module);
    }

    /// @dev Allows to remove a module from the list of allowed modules.
    ///      This can only be done via a Safe transaction.
    /// @param prevModule Module that pointed to the module to be removed in the linked list
    /// @param module Module to be removed.
    function disableModule(
        Module prevModule,
        Module module
    )
        public
    {
        requireAuthorized();
        // Validate module address and check that it corresponds to module index.
        require(
            address(module) != address(0) && address(module) != SENTINEL_MODULES,
            "Invalid module address provided"
        );
        require(modules[address(prevModule)] == address(module), "Invalid prevModule, module pair provided");
        modules[address(prevModule)] = modules[address(module)];
        modules[address(module)] = address(0);
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
    )
        public
        returns (bool success)
    {
        // Only enabled modules are allowed.
        require(
            msg.sender != SENTINEL_MODULES && modules[msg.sender] != address(0),
            "Method can only be called from an enabled module"
        );
        // Execute transaction without further confirmations.
        success = execute(to, value, data, operation, gasleft());
        if (success) {
            if (value > 0) {
                emit EthTransferred("", to, value); // safe tx hash will not appeared.
            }
            emit ExecutionFromModuleSuccess(msg.sender);
        } else {
            emit ExecutionFromModuleFailure(msg.sender);
        }
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
    )
        public
        returns (bool success, bytes memory returnData)
    {
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
    function isModuleEnabled(
        Module module
    )
        public
        view
        returns (bool)
    {
        return SENTINEL_MODULES != address(module) && modules[address(module)] != address(0);
    }

    /// @dev Returns array of first 10 modules.
    function getModules()
        public
        view
        returns (address[] memory)
    {
        (address[] memory array,) = getModulesPaginated(SENTINEL_MODULES, 10);
        return array;
    }

    /// @dev Returns array of modules.
    /// @param start Start of the page.
    /// @param pageSize Maximum number of modules that should be returned.
    function getModulesPaginated(
        address start,
        uint256 pageSize
    )
        public
        view
        returns (address[] memory array, address next)
    {
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

    function setupModules(
        address to,
        bytes memory data
    )
        internal
    {
        require(modules[SENTINEL_MODULES] == address(0), "Modules have already been initialized");
        modules[SENTINEL_MODULES] = SENTINEL_MODULES;
        if (to != address(0)) {
            // Setup has to complete successfully or transaction fails.
            require(executeDelegateCall(to, data, gasleft()), "Could not finish initialization");
        }
    }
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.6;


/// @title SelfAuthorized - authorizes current contract to perform actions
/// @author Richard Meissner - <[email protected]>
contract SelfAuthorized {

    /// @dev checks whether the sender is authorized
    ///      will revert if not
    /// @notice has to be done as function instead of a modifier to reduce the bytecode
    function requireAuthorized()
        public
        view
    {
        require(msg.sender == address(this), "Method can only be called from manager");
    }
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.6;


/// @title Enum - Collection of enums
/// @author Richard Meissner - <[email protected]>
contract Enum {
    enum Operation {
        Call,
        DelegateCall
    }

    enum Role {
        NoRole,
        Challenger,
        Initiator,
        Approver
    }
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.6;
import "../common/Enum.sol";


/// @title Executor - A contract that can execute transactions
/// @author Richard Meissner - <[email protected]>
contract Executor {

    // Event for Eth value transaction
    // This event is additionally emitted with ExecutionSuccess when value transaction succeeded.
    event EthTransferred(
        bytes32 indexed txHash,
        address indexed to,
        uint256 value
    );

    function execute(
        address to,
        uint256 value,
        bytes memory data,
        Enum.Operation operation,
        uint256 txGas
    )
        internal
        returns (bool success)
    {
        if (operation == Enum.Operation.Call)
            success = executeCall(to, value, data, txGas);
        else if (operation == Enum.Operation.DelegateCall)
            success = executeDelegateCall(to, data, txGas);
        else
            success = false;
    }

    function executeCall(
        address to,
        uint256 value,
        bytes memory data,
        uint256 txGas
    )
        internal
        returns (bool success)
    {
        // solhint-disable-next-line no-inline-assembly
        assembly {
            success := call(txGas, to, value, add(data, 0x20), mload(data), 0, 0)
        }
    }

    function executeDelegateCall(
        address to,
        bytes memory data,
        uint256 txGas
    )
        internal
        returns (bool success)
    {
        // solhint-disable-next-line no-inline-assembly
        assembly {
            success := delegatecall(txGas, to, add(data, 0x20), mload(data), 0, 0)
        }
    }
}