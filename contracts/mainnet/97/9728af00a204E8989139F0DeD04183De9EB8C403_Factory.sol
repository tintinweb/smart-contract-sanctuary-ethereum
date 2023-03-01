// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

import {Proxy} from "./vault/Proxy.sol";
import {BaseVault} from "./vault/BaseVault.sol";

contract Factory {

    // Kresus deployer of every vault contracts.
    address deployer;

    // deployed instance of the base vault.
    address baseVaultImpl;

    // Emitted for every new deployment of a proxy vault contract.
    event NewVaultDeployed(address payable newProxy, address owner);

    /**
     * @param _deployer - address of the deployer of new vaults.
     * @param _baseVaultImpl - deployed instance of the implementation base vault.
     */
    constructor(address _deployer, address _baseVaultImpl) {
        deployer = _deployer;
        baseVaultImpl = _baseVaultImpl;
    }

    /**
     * Function to be executed by Kresus deployer to deploy a new instance of {Proxy}.
     * @param _owner - address of the owner of base vault contract.
     * @param _modules - Modules to be authorized to make changes to the state of vault contract.
     */
    function deployVault(
        address _owner,
        bytes32[] calldata _initData,
        address[] calldata _modules
    ) external {
        require(msg.sender == deployer, "F: Caller not allowed to deploy");
        address payable newProxy = payable(new Proxy(baseVaultImpl));
        BaseVault(newProxy).init(_owner, _initData, _modules);
        emit NewVaultDeployed(newProxy, _owner);
    }

    /**
     * Function to be executed by kresus deployer to change the deployer address.
     * @param _newDeployer address of the new kresus deployer.
     */
    function changeDeployer(address _newDeployer) external {
        require(msg.sender == deployer, "F: Caller not allowed to change deployer");
        deployer = _newDeployer;
    }

    /**
     * Function to get current deployer of kresus vaults.
     */
    function getDeployer() external view returns(address) {
        return deployer;
    }

    /**
     * Function to get current base vault implementation contract address.
     */
    function getBaseVaultImpl() external view returns(address) {
        return baseVaultImpl;
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
    function addModule(address _vault, address _module, bytes32 _initData) external;

    /**
     * @notice Inits a Module for a vault by e.g. setting some vault specific parameters in storage.
     * @param _vault The target vault.
     * @param _timeDelay - time in seconds to be expired before executing a queued request.
     */
    function init(address _vault, bytes32 _timeDelay) external;


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

/**
 * @title BaseVault
 * @notice Simple modular wallet that authorises modules to call its invoke() method.
 */
contract BaseVault is IVault {

    // The owner
    address public override owner;
    // The authorised modules
    mapping (address => bool) public override authorised;
    // module executing static calls
    address public staticCallExecutor;
    // The number of modules
    uint256 public override modules;

    event AuthorisedModule(address indexed module, bool value);
    event Invoked(address indexed module, address indexed target, uint indexed value, bytes data);
    event Received(uint indexed value, address indexed sender, bytes data);
    event OwnerChanged(address owner);

    /**
     * @notice Throws if the sender is not an authorised module.
     */
    modifier moduleOnly {
        require(authorised[msg.sender], "BW: sender not authorized");
        _;
    }

    /**
     * @notice Inits the wallet by setting the owner and authorising a list of modules.
     * @param _owner The owner.
     * @param _initData bytes32 initilization data specific to the module.
     * @param _modules The modules to authorise.
     */
    function init(address _owner, bytes32[] calldata _initData, address[] calldata _modules) external {
        uint256 len = _modules.length;
        require(owner == address(0) && modules == 0, "BW: wallet already initialised");
        require(len > 0, "BW: empty modules");
        require(_initData.length == len, "BW: inconsistent lengths");
        owner = _owner;
        modules = len;
        for (uint256 i = 0; i < len; i++) {
            require(authorised[_modules[i]] == false, "BW: module is already added");
            authorised[_modules[i]] = true;
            IModule(_modules[i]).init(address(this), _initData[i]);
            emit AuthorisedModule(_modules[i], true);
        }
        if (address(this).balance > 0) {
            emit Received(address(this).balance, address(0), "");
        }
    }

    /**
     * @inheritdoc IVault
     */
    function authoriseModule(address _module, bool _value, bytes32 _initData) external override moduleOnly {
        if (authorised[_module] != _value) {
            emit AuthorisedModule(_module, _value);
            if (_value == true) {
                modules += 1;
                authorised[_module] = true;
                IModule(_module).init(address(this), _initData);
            } else {
                modules -= 1;
                require(modules > 0, "BW: cannot remove last module");
                delete authorised[_module];
            }
        }
    }

    /**
    * @inheritdoc IVault
    */
    function enabled(bytes4 _sig) public view override returns (address) {
        address executor = staticCallExecutor;
        if(executor != address(0) && IModule(executor).supportsStaticCall(_sig)) {
            return executor;
        }
        return address(0);
    }

    /**
    * @inheritdoc IVault
    */
    function enableStaticCall(address _module, bytes4 /* _method */) external override moduleOnly {
        if(staticCallExecutor != _module) {
            require(authorised[_module], "BW: unauthorized executor");
            staticCallExecutor = _module;
        }
    }

    /**
     * @inheritdoc IVault
     */
    function setOwner(address _newOwner) external override moduleOnly {
        require(_newOwner != address(0), "BW: address cannot be null");
        owner = _newOwner;
        emit OwnerChanged(_newOwner);
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
        uint _value,
        bytes calldata _data
    ) 
        external 
        moduleOnly 
        returns(bytes memory _result) 
    {
        bool success;
        (success, _result) = _target.call{value: _value}(_data);
        if (!success) {
            // solhint-disable-next-line no-inline-assembly
            assembly {
                returndatacopy(0, 0, returndatasize())
                revert(0, returndatasize())
            }
        }
        emit Invoked(msg.sender, _target, _value, _data);
    }

    /**
     * @notice This method delegates the static call to a target contract if the data corresponds
     * to an enabled module, or logs the call otherwise.
     */
    fallback() external payable {
        address module = enabled(msg.sig);
        if (module == address(0)) {
            emit Received(msg.value, msg.sender, msg.data);
        } else {
            require(authorised[module], "BW: unauthorised module");

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

    receive() external payable {}
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

/**
 * @title IVault
 * @notice Interface for the BaseVault
 */
interface IVault {
    /**
     * @notice Returns the vault owner.
     * @return The vault owner address.
     */
    function owner() external view returns (address);

    /**
     * @notice Returns the number of authorised modules.
     * @return The number of authorised modules.
     */
    function modules() external view returns (uint);

    /**
     * @notice Sets a new owner for the vault.
     * @param _newOwner The new owner.
     */
    function setOwner(address _newOwner) external;

    /**
     * @notice Checks if a module is authorised on the vault.
     * @param _module The module address to check.
     * @return `true` if the module is authorised, otherwise `false`.
     */
    function authorised(address _module) external view returns (bool);

    /**
     * @notice Returns the module responsible for a static call redirection.
     * @param _sig The signature of the static call.
     * @return the module doing the redirection
     */
    function enabled(bytes4 _sig) external view returns (address);

    /**
     * @notice Enables/Disables a module.
     * @param _module The target module.
     * @param _value Set to `true` to authorise the module.
     */
    function authoriseModule(address _module, bool _value, bytes32 _initData) external;

    /**
    * @notice Enables a static method by specifying the target module to which the call must be delegated.
    * @param _module The target module.
    * @param _method The static method signature.
    */
    function enableStaticCall(address _module, bytes4 _method) external;
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

/**
 * @title Proxy
 * @notice Basic proxy that delegates all calls to a fixed implementing contract.
 * The implementing contract cannot be upgraded.
 */
contract Proxy {

    address immutable public implementation;

    event Received(uint256 indexed value, address indexed sender, bytes data);

    /**
     * @param _implementation deployed instance of base vault.
     */
    constructor(address _implementation) {
        implementation = _implementation;
    }

    fallback() external payable {
        address target = implementation;
        // solhint-disable-next-line no-inline-assembly
        assembly {
            calldatacopy(0, 0, calldatasize())
            let result := delegatecall(gas(), target, 0, calldatasize(), 0, 0)
            returndatacopy(0, 0, returndatasize())
            switch result
            case 0 {revert(0, returndatasize())}
            default {return (0, returndatasize())}
        }
    }

    receive() external payable {
        emit Received(msg.value, msg.sender, "");
    }
}