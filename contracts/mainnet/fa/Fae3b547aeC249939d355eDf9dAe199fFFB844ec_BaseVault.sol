// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;
import "./Owned.sol";

/**
 * @title ModuleRegistry
 * @notice Registry of authorised modules.
 * Modules must be registered before they can be authorised on a vault.
 */
contract ModuleRegistry is Owned {

    mapping (address => Info) internal modules;

    event ModuleRegistered(address indexed module, string name);
    event ModuleDeRegistered(address module);

    struct Info {
        bool exists;
        string name;
    }

    /**
     * @notice Registers a module.
     * @param _module The module.
     * @param _name The unique name of the module.
     */
    function registerModule(
        address _module,
        string calldata _name
    )
        external
        onlyOwner
    {
        require(_module != address(0), "MR: Invalid module");
        require(!modules[_module].exists, "MR: module already exists");
        modules[_module] = Info({exists: true, name: _name});
        emit ModuleRegistered(_module, _name);
    }

    /**
     * @notice Deregisters a module.
     * @param _module The module.
     */
    function deregisterModule(address _module) external onlyOwner {
        require(modules[_module].exists, "MR: module does not exist");
        delete modules[_module];
        emit ModuleDeRegistered(_module);
    }

    /**
     * @notice Gets the name of a module from its address.
     * @param _module The module address.
     * @return the name.
     */
    function moduleInfo(address _module) external view returns (string memory) {
        return modules[_module].name;
    }

    /**
     * @notice Checks if a module is registered.
     * @param _module The module address.
     * @return true if the module is registered.
     */
    function isRegisteredModule(
        address _module
    )
        external
        view
        returns(bool)
     {
        return modules[_module].exists;
    }

    /**
     * @notice Checks if a list of modules are registered.
     * @param _modules The list of modules address.
     * @return true if all the modules are registered.
     */
    function isRegisteredModule(address[] calldata _modules) external view returns (bool) {
        for (uint i = 0; i < _modules.length; i++) {
            if (!modules[_modules[i]].exists) {
                return false;
            }
        }
        return true;
    }
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

/**
 * @title Owned
 * @notice Basic contract to define an owner.
 */
contract Owned {

    // The owner
    address public owner;

    event OwnerChanged(address indexed _newOwner);

    /**
     * @notice Throws if the sender is not the owner.
     */
    modifier onlyOwner {
        require(msg.sender == owner, "O: Must be owner");
        _;
    }

    constructor() {
        owner = msg.sender;
    }

    /**
     * @notice Lets the owner transfer ownership of the contract to a new owner.
     * @param _newOwner The new owner.
     */
    function changeOwner(address _newOwner) external onlyOwner {
        require(_newOwner != address(0), "O: Address must not be null");
        owner = _newOwner;
        emit OwnerChanged(_newOwner);
    }
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

/**
 * @title IModule
 * @notice Interface for a Module.
 */
interface IModule {

    /**	
     * @notice Adds a module to a vault. Cannot execute when vault is locked (or under recovery)	
     * @param _vault The target vault.	
     * @param _module The modules to authorise.	
     */	
    function addModule(address _vault, address _module, bytes memory _initData) external;

    /**
     * @notice Inits a Module for a vault by e.g. setting some vault specific parameters in storage.
     * @param _vault The target vault.
     * @param _timeDelay - time in seconds to be expired before executing a queued request.
     */
    function init(address _vault, bytes memory _timeDelay) external;


    /**
     * @notice Returns whether the module implements a callback for a given static call method.
     * @param _methodId The method id.
     */
    function supportsStaticCall(bytes4 _methodId) external view returns (bool _isSupported);
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

import "../modules/common/IModule.sol";
import "./IVault.sol";
import {ModuleRegistry} from "../infrastructure/ModuleRegistry.sol";

/**
 * @title BaseVault
 * @notice Simple modular vault that authorises modules to call its invoke() method.
 */
contract BaseVault is IVault {

    // Zero address
    address constant internal ZERO_ADDRESS = address(0);
    // The owner
    address public owner;
    // The authorised modules
    mapping (address => bool) public authorised;
    // module executing static calls
    address public staticCallExecutor;
    // The number of modules
    uint256 public modules;

    event AuthorisedModule(address indexed module, bool value);
    event Invoked(address indexed module, address indexed target, uint256 indexed value, bytes data);
    event Received(uint256 indexed value, address indexed sender, bytes data);
    event StaticCallEnabled(address indexed module);

    /**
     * @notice Throws if the sender is not an authorised module.
     */
    modifier moduleOnly {
        require(authorised[msg.sender], "BV: sender not authorized");
        _;
    }

    constructor() {
        owner = msg.sender;
    }

    /**
     * @notice Inits the vault by setting the owner and authorising a list of modules.
     * @param _owner The owner.
     * @param _initData bytes32 initilization data specific to the module.
     * @param _modules The modules to authorise.
     */
    function init(address _owner, address[] calldata _modules, bytes[] calldata _initData) external {
        uint256 len = _modules.length;
        require(owner == ZERO_ADDRESS, "BV: vault already initialised");
        require(len > 0, "BV: empty modules");
        require(_initData.length == len, "BV: inconsistent lengths");
        owner = _owner;
        modules = len;
        for (uint256 i = 0; i < len; i++) {
            require(_modules[i] != ZERO_ADDRESS, "BV: Invalid address");
            require(!authorised[_modules[i]], "BV: Invalid module");
            authorised[_modules[i]] = true;
            IModule(_modules[i]).init(address(this), _initData[i]);
            emit AuthorisedModule(_modules[i], true);
        }
    }

    /**
     * @inheritdoc IVault
     */
    function authoriseModule(
        address _module,
        bool _value,
        bytes memory _initData
    ) 
        external
        moduleOnly
    {
        if (authorised[_module] != _value) {
            emit AuthorisedModule(_module, _value);
            if (_value) {
                modules += 1;
                authorised[_module] = true;
                IModule(_module).init(address(this), _initData);
            } else {
                modules -= 1;
                require(modules > 0, "BV: cannot remove last module");
                delete authorised[_module];
            }
        }
    }

    /**
    * @inheritdoc IVault
    */
    function enabled(bytes4 _sig) public view returns (address) {
        address executor = staticCallExecutor;
        if(executor != ZERO_ADDRESS && IModule(executor).supportsStaticCall(_sig)) {
            return executor;
        }
        return ZERO_ADDRESS;
    }

    /**
    * @inheritdoc IVault
    */
    function enableStaticCall(address _module) external moduleOnly {
        if(staticCallExecutor != _module) {
            require(authorised[_module], "BV: unauthorized executor");
            staticCallExecutor = _module;
            emit StaticCallEnabled(_module);
        }
    }

    /**
     * @inheritdoc IVault
     */
    function setOwner(address _newOwner) external moduleOnly {
        require(_newOwner != ZERO_ADDRESS, "BV: address cannot be null");
        owner = _newOwner;
    }

    /**
     * @notice Performs a generic transaction.
     * @param _target The address for the transaction.
     * @param _value The value of the transaction.
     * @param _data The data of the transaction.
     * @return _result The bytes result after call.
     */
    function invoke(
        address _target,
        uint256 _value,
        bytes calldata _data
    ) 
        external 
        moduleOnly 
        returns(bytes memory _result) 
    {
        bool success;
        require(_target.balance >= _value, "BV: Insufficient balance");
        emit Invoked(msg.sender, _target, _value, _data);
        (success, _result) = _target.call{value: _value}(_data);
        if (!success) {
            // solhint-disable-next-line no-inline-assembly
            assembly {
                returndatacopy(0, 0, returndatasize())
                revert(0, returndatasize())
            }
        }
    }

    /**
     * @notice This method delegates the static call to a target contract if the data corresponds
     * to an enabled module, or logs the call otherwise.
     */
    fallback() external payable {
        address module = enabled(msg.sig);
        if (module == ZERO_ADDRESS) {
            emit Received(msg.value, msg.sender, msg.data);
        } else {
            require(authorised[module], "BV: unauthorised module");

            // solhint-disable-next-line no-inline-assembly
            assembly {
                calldatacopy(0, 0, calldatasize())
                let result := staticcall(gas(), module, 0, calldatasize(), 0, 0)
                returndatacopy(0, 0, returndatasize())
                switch result
                case 0 {revert(0, returndatasize())}
                default {return (0, returndatasize())}
            }
        }
    }

    receive() external payable {
        emit Received(msg.value, msg.sender, "");
    }
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

/**
 * @title IVault
 * @notice Interface for the BaseVault
 */
interface IVault {

    /**
     * @notice Enables/Disables a module.
     * @param _module The target module.
     * @param _value Set to `true` to authorise the module.
     */
    function authoriseModule(address _module, bool _value, bytes memory _initData) external;

    /**
     * @notice Enables a static method by specifying the target module to which the call must be delegated.
     * @param _module The target module.
     */
    function enableStaticCall(address _module) external;


    /**
     * @notice Inits the vault by setting the owner and authorising a list of modules.
     * @param _owner The owner.
     * @param _initData bytes32 initilization data specific to the module.
     * @param _modules The modules to authorise.
     */
    function init(address _owner, address[] calldata _modules, bytes[] calldata _initData) external;

    /**
     * @notice Sets a new owner for the vault.
     * @param _newOwner The new owner.
     */
    function setOwner(address _newOwner) external;

    /**
     * @notice Returns the vault owner.
     * @return The vault owner address.
     */
    function owner() external view returns (address);

    /**
     * @notice Returns the number of authorised modules.
     * @return The number of authorised modules.
     */
    function modules() external view returns (uint256);

    /**
     * @notice Checks if a module is authorised on the vault.
     * @param _module The module address to check.
     * @return `true` if the module is authorised, otherwise `false`.
     */
    function authorised(address _module) external view returns (bool);

    /**
     * @notice Returns the module responsible, if static call is enabled for `_sig`, otherwise return zero address.
     * @param _sig The signature of the static call.
     * @return the module doing the redirection or zero address
     */
    function enabled(bytes4 _sig) external view returns (address);
}