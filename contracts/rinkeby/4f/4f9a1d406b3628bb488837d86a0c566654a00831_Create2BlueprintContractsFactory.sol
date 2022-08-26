//SPDX-License-Identifier: Business Source License 1.1

pragma solidity ^0.8.9;

import "./proxy/BeaconProxy.sol";
import "./proxy/UpgradeableBeacon.sol";
import "../interfaces/ISystemContext.sol";
import "../interfaces/ICollectionRegistry.sol";
import "./Create2ContractsFactory.sol";
import "../interfaces/factory/ICreate2BlueprintContractsFactory.sol";

/**
 * @dev This contract enables creation of smart contracts following the Upgradable Proxy pattern
 */
contract Create2BlueprintContractsFactory is
    Create2ContractsFactory,
    ICreate2BlueprintContractsFactory
{
    mapping(string => uint16) public latestBlueprintVersion;

    mapping(string => mapping(uint16 => address)) public blueprints; //name => version => blueprint address

    mapping(string => UpgradeableBeacon) public beacons; //name -> beacon

    mapping(string => bool) public blueprintNative;
    ISystemContext public systemContext;

    string internal constant WRONG_BLUEPRINT_NAME = "Check blueprint name";
    string internal constant WRONG_BLUEPRINT_VERSION =
        "Check blueprint version or addr";

    constructor(ISystemContext systemContext_) {
        systemContext = systemContext_;
    }

    modifier onlyRole(bytes32 role_) {
        systemContext.omniteAccessControl().checkRole(role_, msg.sender);
        _;
    }

    modifier onlyBridgeRole() {
        systemContext.omniteAccessControl().checkRole(
            systemContext.omniteAccessControl().BRIDGE_ROLE(),
            msg.sender
        );
        _;
    }

    /**
     * @dev Registers a new blueprint and its name
     * @param blueprintAddress - address of the blueprint contract
     * @param blueprintName - human readable name of a blueprint.
     */
    function registerNewBlueprint(
        address blueprintAddress,
        string memory blueprintName,
        bool isNative
    )
        external
        virtual
        override
        onlyRole(systemContext.omniteAccessControl().CONTROL_LIST_ADMIN_ROLE())
    {
        require(!blueprintExists(blueprintName), WRONG_BLUEPRINT_NAME);
        UpgradeableBeacon beacon = new UpgradeableBeacon(blueprintAddress);
        blueprints[blueprintName][1] = blueprintAddress;
        latestBlueprintVersion[blueprintName] = 1;
        blueprintNative[blueprintName] = isNative;
        beacons[blueprintName] = beacon;

        emit NewBlueprintRegistered(blueprintAddress, blueprintName);
    }

    /**
     * @dev Registers a new version of a blueprint
     * @param blueprintAddress - address of the blueprint contract
     * @param blueprintName - human readable name of a blueprint.
     * @param version - next iterative version.
     * @param forceUpdate - if true, implementation should be updated in the next block
     */
    function registerNewBlueprintVersion(
        address blueprintAddress,
        string memory blueprintName,
        uint16 version,
        bool forceUpdate
    )
        external
        virtual
        override
        onlyRole(systemContext.omniteAccessControl().CONTROL_LIST_ADMIN_ROLE())
    {
        require(blueprintExists(blueprintName), WRONG_BLUEPRINT_NAME);
        require(
            blueprints[blueprintName][version - 1] != address(0),
            WRONG_BLUEPRINT_VERSION
        );
        require(
            blueprints[blueprintName][version - 1] != blueprintAddress,
            WRONG_BLUEPRINT_VERSION
        );
        require(
            version == latestBlueprintVersion[blueprintName] + 1,
            WRONG_BLUEPRINT_VERSION
        );
        latestBlueprintVersion[blueprintName] = version;
        blueprints[blueprintName][version] = blueprintAddress;

        beacons[blueprintName].upgradeTo(blueprintAddress, forceUpdate);

        emit NewBlueprintVersionRegistered(
            blueprintAddress,
            blueprintName,
            version
        );
    }

    /**
     * @dev Removes latest blueprint version
     */
    function deregisterLatestBlueprint(string memory name, bool forceUpdate)
        external
        virtual
        override
        onlyRole(systemContext.omniteAccessControl().CONTROL_LIST_ADMIN_ROLE())
    {
        require(blueprintExists(name), WRONG_BLUEPRINT_NAME);
        if (latestBlueprintVersion[name] > 1) {
            delete blueprints[name][latestBlueprintVersion[name]];
            latestBlueprintVersion[name]--;
            beacons[name].upgradeTo(
                blueprints[name][latestBlueprintVersion[name]],
                forceUpdate
            );
        } else {
            delete blueprints[name][1];
            delete latestBlueprintVersion[name];
            delete blueprintNative[name];
            beacons[name].deregister();
        }
    }

    function blueprintExists(string memory name)
        public
        view
        virtual
        override
        returns (bool)
    {
        return
            latestBlueprintVersion[name] != 0 &&
            blueprints[name][1] != address(0);
    }

    /**
     * @dev Deploys proxy smart contract using given params.
     * @param blueprintName - name of a blueprint to be used for proxy.
     * @param initParams - abi packed params for contract initialization.
     */
    function _deployProxy(
        string memory blueprintName,
        bytes memory initParams,
        bytes32 salt
    ) internal returns (address) {
        address newContract = deployCreate2WithParams(
            type(BeaconProxy).creationCode,
            abi.encode(address(beacons[blueprintName]), new bytes(0)),
            salt
        );
        // solhint-disable-next-line avoid-low-level-calls
        (bool success, ) = newContract.call(initParams);
        require(success, "Initialize failed");

        return newContract;
    }

    function getBeaconProxyCreationCode()
        public
        pure
        virtual
        override
        returns (bytes memory)
    {
        return type(BeaconProxy).creationCode;
    }

    /**
     * @dev Creates native contract instance for whitelisted byteCode.
     * @param blueprintName -name of the blueprint.
     * @param initParams - encoded constructor params.
     * @param collectionId - unique collection identifier.
     * @param name - human readable collection name.
     * @param owner - owner of the collection.
     */
    function createTokenInstanceByName(
        string memory blueprintName,
        bytes memory initParams,
        bytes32 collectionId,
        string calldata name,
        address owner
    ) external virtual override onlyBridgeRole returns (address) {
        require(
            blueprints[blueprintName][latestBlueprintVersion[blueprintName]] !=
                address(0),
            WRONG_BLUEPRINT_NAME
        );

        address newContract = _deployProxy(
            blueprintName,
            initParams,
            collectionId
        );
        emit NewProxyDeployed(blueprintName, newContract);

        if (blueprintNative[blueprintName]) {
            systemContext.omniteAccessControl().grantNativeTokenRole(
                newContract
            );
        } else {
            systemContext.omniteAccessControl().grantNonNativeTokenRole(
                newContract
            );
        }

        _registerToken(newContract, blueprintName, collectionId, name, owner);
        return newContract;
    }

    /**
     * @dev Creates contract instance for whitelisted byteCode.
     * @param blueprintName -name of the blueprint.
     * @param initParams - encoded constructor params.
     * @param salt - salt for create2
     */
    function createSimpleContractInstanceByName(
        string memory blueprintName,
        bytes memory initParams,
        bytes32 salt
    ) external virtual override onlyBridgeRole returns (address) {
        require(
            blueprints[blueprintName][latestBlueprintVersion[blueprintName]] !=
                address(0),
            WRONG_BLUEPRINT_NAME
        );

        address newContract = _deployProxy(blueprintName, initParams, salt);
        emit NewProxyDeployed(blueprintName, newContract);
        return newContract;
    }

    function registerOriginalContract(
        bytes32 collectionId,
        address originalAddress
    ) external virtual override onlyBridgeRole {
        ICollectionRegistry registry = ICollectionRegistry(
            systemContext.getContractAddress("COLLECTIONS_REGISTRY")
        );
        registry.registerOriginalAddress(collectionId, originalAddress);
    }

    function _registerToken(
        address newContract,
        string memory blueprintName,
        bytes32 collectionId,
        string calldata name,
        address owner
    ) internal {
        ICollectionRegistry registry = ICollectionRegistry(
            systemContext.getContractAddress("COLLECTIONS_REGISTRY")
        );
        registry.registerCollection(
            collectionId,
            name,
            owner,
            newContract,
            blueprintName,
            latestBlueprintVersion[blueprintName]
        );
    }

    function getLatestBlueprint(string calldata blueprintName_)
        public
        view
        virtual
        override
        returns (address)
    {
        return
            blueprints[blueprintName_][latestBlueprintVersion[blueprintName_]];
    }
}

//SPDX-License-Identifier: Business Source License 1.1

pragma solidity ^0.8.9;

import "./ERC1967UpgradeSimplified.sol";
import "./Proxy.sol";
import "./UpgradeableBeacon.sol";

/**
 * @dev This contract implements a proxy that gets the implementation address for each call from a {UpgradeableBeacon}.
 *
 * The beacon address is stored in storage slot `uint256(keccak256('eip1967.proxy.beacon')) - 1`, so that it doesn't
 * conflict with the storage layout of the implementation behind the proxy.
 *
 * _Available since v3.4._
 */
contract BeaconProxy is Proxy, ERC1967UpgradeSimplified {
    /**
     * @dev Initializes the proxy with `beacon`.
     *
     * If `data` is nonempty, it's used as data in a delegate call to the implementation returned by the beacon. This
     * will typically be an encoded function call, and allows initializating the storage of the proxy like a Solidity
     * constructor.
     *
     * Requirements:
     *
     * - `beacon` must be a contract with the interface {UpgradeableBeacon}.
     */
    constructor(address beacon, bytes memory data) payable {
        require(
            _BEACON_SLOT ==
                bytes32(uint256(keccak256("eip1967.proxy.beacon")) - 1),
            "BeaconProxy: _BEACON_SLOT err"
        );
        _upgradeBeaconToAndCall(beacon, data, false);
    }

    /**
     * @dev Returns the current beacon address.
     */
    function _beacon() internal view virtual returns (address) {
        return _getBeacon();
    }

    /**
     * @dev Returns the current implementation address of the associated beacon.
     */
    function _implementation()
        internal
        view
        virtual
        override
        returns (address)
    {
        return UpgradeableBeacon(_getBeacon()).implementation();
    }

    function _beforeFallback() internal virtual override {
        UpgradeableBeacon(_getBeacon()).switchImplementationIfReady();
    }
}

//SPDX-License-Identifier: Business Source License 1.1
pragma solidity ^0.8.9;

import "@openzeppelin/contracts/proxy/beacon/IBeacon.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Address.sol";

/**
 * @dev This contract is used in conjunction with one or more instances of {BeaconProxy} to determine their
 * implementation contract, which is where they will delegate all function calls.
 *
 * An owner is able to change the implementation the beacon points to, thus upgrading the proxies that use this beacon.
 */
contract UpgradeableBeacon is Ownable, IBeacon {
    address private _implementation;
    address private _implementationCandidate;

    uint256 internal immutable _implementationSwitchWindow;
    uint256 internal immutable _implementationSwitchDelay;
    uint256 internal _nextSwitch;

    /**
     * @dev Emitted when the implementation returned by the beacon is changed.
     */
    event Upgraded(address indexed implementation);

    /**
     * @dev Emitted when new implementation candidate is registered.
     */
    event NewCandidate(address indexed implementation);

    /**
     * @dev Sets the address of the initial implementation, and the deployer account as the owner who can upgrade the
     * beacon.
     */
    constructor(address implementation_) {
        _setImplementation(implementation_);

        _implementationSwitchWindow = 60 * 60 * 24; // switch implementation once per day
        _implementationSwitchDelay = 0; // just after midnight UTC
    }

    function _switchIfRequired() internal {
        // solhint-disable not-rely-on-time
        if (
            _implementationCandidate != address(0) &&
            block.timestamp >= _nextSwitch
        ) {
            _implementation = _implementationCandidate;
            _implementationCandidate = address(0);
            _nextSwitch = 0;
        }
    }

    /**
     * @dev Returns (and update if required) the current implementation address.
     */
    function implementation() public view virtual override returns (address) {
        return _implementation;
    }

    function switchImplementationIfReady() public virtual {
        _switchIfRequired();
    }

    /**
     * @dev Upgrades the beacon to a new implementation.
     *
     * Emits an {Upgraded} event.
     *
     * Requirements:
     *
     * - msg.sender must be the owner of the contract.
     * - `newImplementation` must be a contract.
     */
    function upgradeTo(address newImplementation, bool forceUpdate)
        public
        virtual
        onlyOwner
    {
        _setCandidate(newImplementation);
        if (forceUpdate) {
            _nextSwitch = block.timestamp + 1;
        } else {
            uint256 window = ((block.timestamp + _implementationSwitchDelay) /
                _implementationSwitchWindow) + 1;
            _nextSwitch = window * _implementationSwitchWindow;
        }
        emit NewCandidate(newImplementation);
    }

    /**
     * @dev Changes implementation of a blueprint to zero address
     *
     * Emits an {Upgraded} event.
     *
     * Requirements:
     *
     * - msg.sender must be the owner of the contract.
     */
    function deregister() public virtual onlyOwner {
        _implementation = address(0);
        emit Upgraded(address(0));
    }

    /**
     * @dev Sets the implementation contract address for this beacon
     *
     * Requirements:
     *
     * - `newImplementation` must be a contract.
     */
    function _setImplementation(address newImplementation) private {
        // solhint-disable-next-line reason-string
        require(
            Address.isContract(newImplementation),
            "UpgradeableBeacon: implementation is not a contract"
        );
        _implementation = newImplementation;
    }

    /**
     * @dev Sets the implementation contract address for this beacon
     *
     * Requirements:
     *
     * - `newImplementation` must be a contract.
     */
    function _setCandidate(address newImplementationCandidate) private {
        // solhint-disable-next-line reason-string
        require(
            Address.isContract(newImplementationCandidate),
            "UpgradeableBeacon: implementation is not a contract"
        );
        _implementationCandidate = newImplementationCandidate;
    }
}

//SPDX-License-Identifier: Business Source License 1.1

pragma solidity ^0.8.9;

import "../acl/OmniteAccessControl.sol";

interface ISystemContext {
    event ContractRegistered(string indexed name, address addr);
    event ContractUpdated(
        string indexed name,
        address lastAddr,
        address newAddr
    );
    event ContractRemoved(string indexed name);

    error ContractAlreadyRegistered(string name, address addr);
    error ContractNotRegistered(string name);

    function getContractAddress(string calldata _contractName)
        external
        view
        returns (address);

    function registerContract(string calldata _contractName, address _addr)
        external;

    function overrideContract(string calldata _contractName, address _addr)
        external;

    function removeContract(string calldata _contractName) external;

    function contractRegistered(string calldata _contractName)
        external
        returns (bool);

    function setAccessControlList(OmniteAccessControl accessControlList_)
        external;

    function contractUriBase() external view returns (string memory);

    function chainId() external view returns (uint16);

    function chainName() external view returns (string memory);

    function omniteAccessControl() external view returns (OmniteAccessControl);

    function multisigWallet() external view returns (address);
}

//SPDX-License-Identifier: Business Source License 1.1

pragma solidity ^0.8.9;

interface ICollectionRegistry {
    struct Record {
        address owner;
        address addr;
        string userName;
        string contractName;
        uint16 contractVersion;
    }

    struct RecordWithId {
        address addr;
        string name;
        bytes32 id;
    }

    // Logged when new record is created.
    event NewCollection(
        bytes32 indexed collectionId,
        string name,
        address owner,
        address addr,
        string contractName,
        uint16 contractVersion
    );

    // Logged when the owner of a node transfers ownership to a new account.
    event TransferOwnership(bytes32 indexed collectionId, address owner);

    // Logged when the resolver for a node changes.
    event NewAddress(bytes32 indexed collectionId, address addr);

    function registerCollection(
        bytes32 collectionId_,
        string calldata name_,
        address owner_,
        address collectionAddress_,
        string calldata contractName_,
        uint16 contractVersion_
    ) external;

    function registerOriginalAddress(
        bytes32 collectionId_,
        address originalAddress_
    ) external;

    function setOwner(bytes32 collectionId_, address owner_) external;

    function ownerOf(bytes32 collectionId_) external view returns (address);

    function addressOf(bytes32 collectionId_) external view returns (address);

    function recordExists(bytes32 collectionId_) external view returns (bool);

    function collections(address addr) external view returns (bytes32);

    function externalToCollection(address addr) external view returns (bytes32);
}

//SPDX-License-Identifier: Business Source License 1.1

pragma solidity ^0.8.9;

import "../interfaces/factory/ICreate2ContractsFactory.sol";

contract Create2ContractsFactory is ICreate2ContractsFactory {
    /**
     * @dev Deploys any contract using create2 asm opcode creating the same address for same bytecode
     * @param bytecode - bytecode packed with params to deploy
     * @param constructorParams - ctor params encoded with abi.encode
     * @param salt - salt required by create2
     */
    function deployCreate2WithParams(
        bytes memory bytecode,
        bytes memory constructorParams,
        bytes32 salt
    ) public virtual override returns (address) {
        address newContract = deployCreate2(
            abi.encodePacked(bytecode, constructorParams),
            salt
        );

        emit NewContractDeployed(
            newContract,
            bytecode,
            constructorParams,
            salt
        );

        return newContract;
    }

    /**
     * @dev Deploys any contract using create2 asm opcode creating the same address for same bytecode
     * @param bytecode - bytecode packed with params to deploy
     * @param salt - salt required by create2
     */
    function deployCreate2(bytes memory bytecode, bytes32 salt)
        public
        virtual
        override
        returns (address)
    {
        address newContract = _deployCreate2(bytecode, salt);
        emit NewContractDeployed(newContract, bytecode, "", salt);
        return newContract;
    }

    function _deployCreate2(bytes memory bytecode, bytes32 salt)
        public
        virtual
        returns (address)
    {
        address newContract;
        // solhint-disable-next-line no-inline-assembly
        assembly {
            newContract := create2(0, add(bytecode, 32), mload(bytecode), salt)
        }
        require(_isContract(newContract), "Deploy failed");

        return newContract;
    }

    /**
     * @dev Returns True if provided address is a contract
     * @param account Prospective contract address
     * @return True if there is a contract behind the provided address
     */
    function _isContract(address account) internal view returns (bool) {
        uint256 size;
        // solhint-disable-next-line no-inline-assembly
        assembly {
            size := extcodesize(account)
        }
        return size > 0;
    }
}

//SPDX-License-Identifier: Business Source License 1.1

pragma solidity ^0.8.9;

import "./ICreate2ContractsFactory.sol";

interface ICreate2BlueprintContractsFactory is ICreate2ContractsFactory {
    event NewBlueprintRegistered(
        address indexed blueprintAddress,
        string blueprintName
    );
    event NewBlueprintVersionRegistered(
        address indexed blueprintAddress,
        string blueprintName,
        uint16 version
    );

    event NewProxyDeployed(string indexed blueprintName, address proxyAddress);

    function registerNewBlueprint(
        address blueprintAddress,
        string memory blueprintName,
        bool isNative
    ) external;

    function registerNewBlueprintVersion(
        address blueprintAddress,
        string memory blueprintName,
        uint16 version,
        bool forceUpdate
    ) external;

    function deregisterLatestBlueprint(string memory name, bool forceUpdate)
        external;

    function blueprintExists(string memory name) external view returns (bool);

    function getBeaconProxyCreationCode() external pure returns (bytes memory);

    function createTokenInstanceByName(
        string memory blueprintName,
        bytes memory initParams,
        bytes32 collectionId,
        string calldata name,
        address owner
    ) external returns (address);

    function createSimpleContractInstanceByName(
        string memory blueprintName,
        bytes memory initParams,
        bytes32 salt
    ) external returns (address);

    function registerOriginalContract(
        bytes32 collectionId,
        address originalAddress
    ) external;

    function getLatestBlueprint(string calldata blueprintName_)
        external
        view
        returns (address);
}

//SPDX-License-Identifier: Business Source License 1.1
// OpenZeppelin Contracts (last updated v4.5.0) (proxy/ERC1967/ERC1967Upgrade.sol)

pragma solidity ^0.8.2;

import "@openzeppelin/contracts/proxy/beacon/IBeacon.sol";
import "@openzeppelin/contracts/utils/Address.sol";
import "@openzeppelin/contracts/utils/StorageSlot.sol";

/**
 * @dev This abstract contract provides getters and event emitting update functions for
 * https://eips.ethereum.org/EIPS/eip-1967[EIP1967] slots.
 *
 * _Available since v4.1._
 *
 * @custom:oz-upgrades-unsafe-allow delegatecall
 */
abstract contract ERC1967UpgradeSimplified {
    /**
     * @dev The storage slot of the UpgradeableBeacon contract which defines the implementation for this proxy.
     * This is bytes32(uint256(keccak256('eip1967.proxy.beacon')) - 1)) and is validated in the constructor.
     */
    bytes32 internal constant _BEACON_SLOT =
        0xa3f0ad74e5423aebfd80d3ef4346578335a9a72aeaee59ff6cb3582b35133d50;

    /**
     * @dev Returns the current beacon.
     */
    function _getBeacon() internal view returns (address) {
        return StorageSlot.getAddressSlot(_BEACON_SLOT).value;
    }

    /**
     * @dev Stores a new beacon in the EIP1967 beacon slot.
     */
    function _setBeacon(address newBeacon) private {
        // solhint-disable-next-line reason-string
        require(
            Address.isContract(newBeacon),
            "ERC1967: new beacon is not a contract"
        );
        // solhint-disable-next-line reason-string
        require(
            Address.isContract(IBeacon(newBeacon).implementation()),
            "ERC1967: beacon implementation is not a contract"
        );
        StorageSlot.getAddressSlot(_BEACON_SLOT).value = newBeacon;
    }

    /**
     * @dev Perform beacon upgrade with additional setup call. Note: This upgrades the address of the beacon, it does
     * not upgrade the implementation contained in the beacon (see {UpgradeableBeacon-_setImplementation} for that).
     *
     * Emits a {BeaconUpgraded} event.
     */
    function _upgradeBeaconToAndCall(
        address newBeacon,
        bytes memory data,
        bool forceCall
    ) internal {
        _setBeacon(newBeacon);
        if (data.length > 0 || forceCall) {
            Address.functionDelegateCall(
                IBeacon(newBeacon).implementation(),
                data
            );
        }
    }
}

//SPDX-License-Identifier: Business Source License 1.1
// OpenZeppelin Contracts (last updated v4.5.0) (proxy/Proxy.sol)

pragma solidity ^0.8.9;

/**
 * @dev This abstract contract provides a fallback function that delegates all calls to another contract using the EVM
 * instruction `delegatecall`. We refer to the second contract as the _implementation_ behind the proxy, and it has to
 * be specified by overriding the virtual {_implementation} function.
 *
 * Additionally, delegation to the implementation can be triggered manually through the {_fallback} function, or to a
 * different contract through the {_delegate} function.
 *
 * The success and return data of the delegated call will be returned back to the caller of the proxy.
 */
abstract contract Proxy {
    /**
     * @dev Delegates the current call to `implementation`.
     *
     * This function does not return to its internal call site, it will return directly to the external caller.
     */
    function _delegate(address implementation) internal virtual {
        // solhint-disable-next-line no-inline-assembly
        assembly {
            // Copy msg.data. We take full control of memory in this inline assembly
            // block because it will not return to Solidity code. We overwrite the
            // Solidity scratch pad at memory position 0.
            calldatacopy(0, 0, calldatasize())

            // Call the implementation.
            // out and outsize are 0 because we don't know the size yet.
            let result := delegatecall(
                gas(),
                implementation,
                0,
                calldatasize(),
                0,
                0
            )

            // Copy the returned data.
            returndatacopy(0, 0, returndatasize())

            switch result
            // delegatecall returns 0 on error.
            case 0 {
                revert(0, returndatasize())
            }
            default {
                return(0, returndatasize())
            }
        }
    }

    /**
     * @dev This is a virtual function that should be overriden so it returns the address to which the fallback function
     * and {_fallback} should delegate.
     */
    function _implementation() internal view virtual returns (address);

    /**
     * @dev Delegates the current call to the address returned by `_implementation()`.
     *
     * This function does not return to its internall call site, it will return directly to the external caller.
     */
    function _fallback() internal virtual {
        _beforeFallback();
        _delegate(_implementation());
    }

    /**
     * @dev Fallback function that delegates calls to the address returned by `_implementation()`. Will run if no other
     * function in the contract matches the call data.
     */
    fallback() external payable virtual {
        _fallback();
    }

    /**
     * @dev Fallback function that delegates calls to the address returned by `_implementation()`. Will run if call data
     * is empty.
     */
    receive() external payable virtual {
        _fallback();
    }

    /**
     * @dev Hook that is called before falling back to the implementation. Can happen as part of a manual `_fallback`
     * call, or as part of the Solidity `fallback` or `receive` functions.
     *
     * If overriden should call `super._beforeFallback()`.
     */

    // solhint-disable no-empty-blocks
    function _beforeFallback() internal virtual {}
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (proxy/beacon/IBeacon.sol)

pragma solidity ^0.8.0;

/**
 * @dev This is the interface that {BeaconProxy} expects of its beacon.
 */
interface IBeacon {
    /**
     * @dev Must return an address that can be used as a delegate call target.
     *
     * {BeaconProxy} will check that this address is a contract.
     */
    function implementation() external view returns (address);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (utils/Address.sol)

pragma solidity ^0.8.1;

/**
 * @dev Collection of functions related to the address type
 */
library Address {
    /**
     * @dev Returns true if `account` is a contract.
     *
     * [IMPORTANT]
     * ====
     * It is unsafe to assume that an address for which this function returns
     * false is an externally-owned account (EOA) and not a contract.
     *
     * Among others, `isContract` will return false for the following
     * types of addresses:
     *
     *  - an externally-owned account
     *  - a contract in construction
     *  - an address where a contract will be created
     *  - an address where a contract lived, but was destroyed
     * ====
     *
     * [IMPORTANT]
     * ====
     * You shouldn't rely on `isContract` to protect against flash loan attacks!
     *
     * Preventing calls from contracts is highly discouraged. It breaks composability, breaks support for smart wallets
     * like Gnosis Safe, and does not provide security since it can be circumvented by calling from a contract
     * constructor.
     * ====
     */
    function isContract(address account) internal view returns (bool) {
        // This method relies on extcodesize/address.code.length, which returns 0
        // for contracts in construction, since the code is only stored at the end
        // of the constructor execution.

        return account.code.length > 0;
    }

    /**
     * @dev Replacement for Solidity's `transfer`: sends `amount` wei to
     * `recipient`, forwarding all available gas and reverting on errors.
     *
     * https://eips.ethereum.org/EIPS/eip-1884[EIP1884] increases the gas cost
     * of certain opcodes, possibly making contracts go over the 2300 gas limit
     * imposed by `transfer`, making them unable to receive funds via
     * `transfer`. {sendValue} removes this limitation.
     *
     * https://diligence.consensys.net/posts/2019/09/stop-using-soliditys-transfer-now/[Learn more].
     *
     * IMPORTANT: because control is transferred to `recipient`, care must be
     * taken to not create reentrancy vulnerabilities. Consider using
     * {ReentrancyGuard} or the
     * https://solidity.readthedocs.io/en/v0.5.11/security-considerations.html#use-the-checks-effects-interactions-pattern[checks-effects-interactions pattern].
     */
    function sendValue(address payable recipient, uint256 amount) internal {
        require(address(this).balance >= amount, "Address: insufficient balance");

        (bool success, ) = recipient.call{value: amount}("");
        require(success, "Address: unable to send value, recipient may have reverted");
    }

    /**
     * @dev Performs a Solidity function call using a low level `call`. A
     * plain `call` is an unsafe replacement for a function call: use this
     * function instead.
     *
     * If `target` reverts with a revert reason, it is bubbled up by this
     * function (like regular Solidity function calls).
     *
     * Returns the raw returned data. To convert to the expected return value,
     * use https://solidity.readthedocs.io/en/latest/units-and-global-variables.html?highlight=abi.decode#abi-encoding-and-decoding-functions[`abi.decode`].
     *
     * Requirements:
     *
     * - `target` must be a contract.
     * - calling `target` with `data` must not revert.
     *
     * _Available since v3.1._
     */
    function functionCall(address target, bytes memory data) internal returns (bytes memory) {
        return functionCall(target, data, "Address: low-level call failed");
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`], but with
     * `errorMessage` as a fallback revert reason when `target` reverts.
     *
     * _Available since v3.1._
     */
    function functionCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal returns (bytes memory) {
        return functionCallWithValue(target, data, 0, errorMessage);
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
     * but also transferring `value` wei to `target`.
     *
     * Requirements:
     *
     * - the calling contract must have an ETH balance of at least `value`.
     * - the called Solidity function must be `payable`.
     *
     * _Available since v3.1._
     */
    function functionCallWithValue(
        address target,
        bytes memory data,
        uint256 value
    ) internal returns (bytes memory) {
        return functionCallWithValue(target, data, value, "Address: low-level call with value failed");
    }

    /**
     * @dev Same as {xref-Address-functionCallWithValue-address-bytes-uint256-}[`functionCallWithValue`], but
     * with `errorMessage` as a fallback revert reason when `target` reverts.
     *
     * _Available since v3.1._
     */
    function functionCallWithValue(
        address target,
        bytes memory data,
        uint256 value,
        string memory errorMessage
    ) internal returns (bytes memory) {
        require(address(this).balance >= value, "Address: insufficient balance for call");
        require(isContract(target), "Address: call to non-contract");

        (bool success, bytes memory returndata) = target.call{value: value}(data);
        return verifyCallResult(success, returndata, errorMessage);
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
     * but performing a static call.
     *
     * _Available since v3.3._
     */
    function functionStaticCall(address target, bytes memory data) internal view returns (bytes memory) {
        return functionStaticCall(target, data, "Address: low-level static call failed");
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-string-}[`functionCall`],
     * but performing a static call.
     *
     * _Available since v3.3._
     */
    function functionStaticCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal view returns (bytes memory) {
        require(isContract(target), "Address: static call to non-contract");

        (bool success, bytes memory returndata) = target.staticcall(data);
        return verifyCallResult(success, returndata, errorMessage);
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
     * but performing a delegate call.
     *
     * _Available since v3.4._
     */
    function functionDelegateCall(address target, bytes memory data) internal returns (bytes memory) {
        return functionDelegateCall(target, data, "Address: low-level delegate call failed");
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-string-}[`functionCall`],
     * but performing a delegate call.
     *
     * _Available since v3.4._
     */
    function functionDelegateCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal returns (bytes memory) {
        require(isContract(target), "Address: delegate call to non-contract");

        (bool success, bytes memory returndata) = target.delegatecall(data);
        return verifyCallResult(success, returndata, errorMessage);
    }

    /**
     * @dev Tool to verifies that a low level call was successful, and revert if it wasn't, either by bubbling the
     * revert reason using the provided one.
     *
     * _Available since v4.3._
     */
    function verifyCallResult(
        bool success,
        bytes memory returndata,
        string memory errorMessage
    ) internal pure returns (bytes memory) {
        if (success) {
            return returndata;
        } else {
            // Look for revert reason and bubble it up if present
            if (returndata.length > 0) {
                // The easiest way to bubble the revert reason is using memory via assembly
                /// @solidity memory-safe-assembly
                assembly {
                    let returndata_size := mload(returndata)
                    revert(add(32, returndata), returndata_size)
                }
            } else {
                revert(errorMessage);
            }
        }
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (utils/StorageSlot.sol)

pragma solidity ^0.8.0;

/**
 * @dev Library for reading and writing primitive types to specific storage slots.
 *
 * Storage slots are often used to avoid storage conflict when dealing with upgradeable contracts.
 * This library helps with reading and writing to such slots without the need for inline assembly.
 *
 * The functions in this library return Slot structs that contain a `value` member that can be used to read or write.
 *
 * Example usage to set ERC1967 implementation slot:
 * ```
 * contract ERC1967 {
 *     bytes32 internal constant _IMPLEMENTATION_SLOT = 0x360894a13ba1a3210667c828492db98dca3e2076cc3735a920a3ca505d382bbc;
 *
 *     function _getImplementation() internal view returns (address) {
 *         return StorageSlot.getAddressSlot(_IMPLEMENTATION_SLOT).value;
 *     }
 *
 *     function _setImplementation(address newImplementation) internal {
 *         require(Address.isContract(newImplementation), "ERC1967: new implementation is not a contract");
 *         StorageSlot.getAddressSlot(_IMPLEMENTATION_SLOT).value = newImplementation;
 *     }
 * }
 * ```
 *
 * _Available since v4.1 for `address`, `bool`, `bytes32`, and `uint256`._
 */
library StorageSlot {
    struct AddressSlot {
        address value;
    }

    struct BooleanSlot {
        bool value;
    }

    struct Bytes32Slot {
        bytes32 value;
    }

    struct Uint256Slot {
        uint256 value;
    }

    /**
     * @dev Returns an `AddressSlot` with member `value` located at `slot`.
     */
    function getAddressSlot(bytes32 slot) internal pure returns (AddressSlot storage r) {
        /// @solidity memory-safe-assembly
        assembly {
            r.slot := slot
        }
    }

    /**
     * @dev Returns an `BooleanSlot` with member `value` located at `slot`.
     */
    function getBooleanSlot(bytes32 slot) internal pure returns (BooleanSlot storage r) {
        /// @solidity memory-safe-assembly
        assembly {
            r.slot := slot
        }
    }

    /**
     * @dev Returns an `Bytes32Slot` with member `value` located at `slot`.
     */
    function getBytes32Slot(bytes32 slot) internal pure returns (Bytes32Slot storage r) {
        /// @solidity memory-safe-assembly
        assembly {
            r.slot := slot
        }
    }

    /**
     * @dev Returns an `Uint256Slot` with member `value` located at `slot`.
     */
    function getUint256Slot(bytes32 slot) internal pure returns (Uint256Slot storage r) {
        /// @solidity memory-safe-assembly
        assembly {
            r.slot := slot
        }
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (access/Ownable.sol)

pragma solidity ^0.8.0;

import "../utils/Context.sol";

/**
 * @dev Contract module which provides a basic access control mechanism, where
 * there is an account (an owner) that can be granted exclusive access to
 * specific functions.
 *
 * By default, the owner account will be the one that deploys the contract. This
 * can later be changed with {transferOwnership}.
 *
 * This module is used through inheritance. It will make available the modifier
 * `onlyOwner`, which can be applied to your functions to restrict their use to
 * the owner.
 */
abstract contract Ownable is Context {
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    /**
     * @dev Initializes the contract setting the deployer as the initial owner.
     */
    constructor() {
        _transferOwnership(_msgSender());
    }

    /**
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        _checkOwner();
        _;
    }

    /**
     * @dev Returns the address of the current owner.
     */
    function owner() public view virtual returns (address) {
        return _owner;
    }

    /**
     * @dev Throws if the sender is not the owner.
     */
    function _checkOwner() internal view virtual {
        require(owner() == _msgSender(), "Ownable: caller is not the owner");
    }

    /**
     * @dev Leaves the contract without owner. It will not be possible to call
     * `onlyOwner` functions anymore. Can only be called by the current owner.
     *
     * NOTE: Renouncing ownership will leave the contract without an owner,
     * thereby removing any functionality that is only available to the owner.
     */
    function renounceOwnership() public virtual onlyOwner {
        _transferOwnership(address(0));
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        _transferOwnership(newOwner);
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Internal function without access restriction.
     */
    function _transferOwnership(address newOwner) internal virtual {
        address oldOwner = _owner;
        _owner = newOwner;
        emit OwnershipTransferred(oldOwner, newOwner);
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/Context.sol)

pragma solidity ^0.8.0;

/**
 * @dev Provides information about the current execution context, including the
 * sender of the transaction and its data. While these are generally available
 * via msg.sender and msg.data, they should not be accessed in such a direct
 * manner, since when dealing with meta-transactions the account sending and
 * paying for execution may not be the actual sender (as far as an application
 * is concerned).
 *
 * This contract is only required for intermediate, library-like contracts.
 */
abstract contract Context {
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes calldata) {
        return msg.data;
    }
}

//SPDX-License-Identifier: Business Source License 1.1

pragma solidity ^0.8.9;

import "../interfaces/accessControlList/IAccessControlBytes.sol";
import "../utils/ContextBytes.sol";
import "@openzeppelin/contracts/utils/Strings.sol";
import "@openzeppelin/contracts/utils/introspection/ERC165.sol";
import "../libraries/BytesLib.sol";

abstract contract OmniteAccessControl is
    IAccessControlBytes,
    ERC165,
    ContextBytes
{
    bytes32 public constant CONTROL_LIST_ADMIN_ROLE =
        keccak256("CONTROL_LIST_ADMIN_ROLE");
    bytes32 public constant BRIDGE_DEFAULT_ADMIN_ROLE =
        keccak256("BRIDGE_DEFAULT_ADMIN_ROLE");
    bytes32 public constant SYSTEM_CONTEXT_DEFAULT_ADMIN_ROLE =
        keccak256("SYSTEM_CONTEXT_DEFAULT_ADMIN_ROLE");
    bytes32 public constant FEE_COLLECTOR_DEFAULT_ADMIN_ROLE =
        keccak256("FEE_COLLECTOR_DEFAULT_ADMIN_ROLE");
    bytes32 public constant COLLECTION_REGISTRY_DEFAULT_ADMIN_ROLE =
        keccak256("COLLECTION_REGISTRY_DEFAULT_ADMIN_ROLE");
    bytes32 public constant TOKEN_UNLOCK_ROLE = keccak256("TOKEN_UNLOCK_ROLE");
    bytes32 public constant TOKEN_DEFAULT_ADMIN_ROLE =
        keccak256("TOKEN_DEFAULT_ADMIN_ROLE");

    bytes32 public constant SYSTEM_CONTEXT_ROLE =
        keccak256("SYSTEM_CONTEXT_ROLE");
    bytes32 public constant BRIDGE_ROLE = keccak256("BRIDGE_ROLE");
    bytes32 public constant CONTRACT_FACTORY_ROLE =
        keccak256("CONTRACT_FACTORY_ROLE");
    bytes32 public constant COLLECTION_REGISTRY_ROLE =
        keccak256("COLLECTION_REGISTRY_ROLE");
    bytes32 public constant ACCESS_CONTROL_ROLE =
        keccak256("ACCESS_CONTROL_ROLE");
    bytes32 public constant OWNER_VERIFIER_ROLE =
        keccak256("OWNER_VERIFIER_ROLE");
    bytes32 public constant OMNITE_TOKEN_ROLE = keccak256("OMNITE_TOKEN_ROLE");

    bytes32 public constant FEE_COLLECTOR_ROLE =
        keccak256("FEE_COLLECTOR_ROLE");
    bytes32 public constant NATIVE_TOKEN_ROLE = keccak256("NATIVE_TOKEN_ROLE");
    bytes32 public constant NON_NATIVE_TOKEN_ROLE =
        keccak256("NON_NATIVE_TOKEN_ROLE");

    bytes32 public constant FACETS_REGISTRY_EDITOR_ROLE =
        keccak256("FACETS_REGISTRY_EDITOR_ROLE");

    bytes32 public constant FACETS_REGISTRY_EDITOR_DEFAULT_ADMIN_ROLE =
        keccak256("FACETS_REGISTRY_EDITOR_ROLE");

    struct RoleData {
        mapping(bytes => bool) members;
        bytes32 adminRole;
    }

    mapping(bytes32 => RoleData) private _roles;

    bytes32 public constant DEFAULT_ADMIN_ROLE = 0x00;

    /**
     * @dev Modifier that checks that an account has a specific role. Reverts
     * with a standardized message including the required role.
     *
     * The format of the revert reason is given by the following regular expression:
     *
     *  /^AccessControl: account (0x[0-9a-f]{40}) is missing role (0x[0-9a-f]{64})$/
     *
     * _Available since v4.1._
     */
    modifier onlyRole(bytes32 role) {
        _checkRole(role, _msgSenderBytes());
        _;
    }

    function checkRole(bytes32 role, address account)
        external
        view
        virtual
        override
    {
        return _checkRole(role, toBytes(account));
    }

    function checkRoleBytes(bytes32 role, bytes memory account) external view {
        return _checkRole(role, account);
    }

    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId)
        public
        view
        virtual
        override
        returns (bool)
    {
        return
            interfaceId == type(IAccessControl).interfaceId ||
            super.supportsInterface(interfaceId);
    }

    /**
     * @dev Returns `true` if `account` has been granted `role`.
     */
    function hasRole(bytes32 role, address account)
        public
        view
        override
        returns (bool)
    {
        return hasRoleBytes(role, toBytes(account));
    }

    /**
     * @dev Returns `true` if `account` has been granted `role`.
     */
    function hasRoleBytes(bytes32 role, bytes memory account)
        public
        view
        virtual
        override
        returns (bool)
    {
        return _roles[role].members[account];
    }

    function toBytes(address a) public pure returns (bytes memory) {
        return abi.encodePacked(a);
    }

    /**
     * @dev Revert with a standard message if `account` is missing `role`.
     *
     * The format of the revert reason is given by the following regular expression:
     *
     *  /^AccessControl: account (0x[0-9a-f]{40}) is missing role (0x[0-9a-f]{64})$/
     */
    function _checkRole(bytes32 role, bytes memory account) internal view {
        if (!hasRoleBytes(role, account)) {
            revert(
                string(
                    abi.encodePacked(
                        "OmniteAccessControl: account ",
                        toHexString(account),
                        " is missing role ",
                        Strings.toHexString(uint256(role), 32)
                    )
                )
            );
        }
    }

    function toHexString(bytes memory account)
        internal
        pure
        returns (string memory)
    {
        if (account.length == 20) {
            // all eth based addresses
            return
                Strings.toHexString(
                    uint256(uint160(BytesLib.toAddress(account, 0)))
                );
        } else if (account.length <= 32) {
            // most of other addresses if not all of them
            return Strings.toHexString(uint256(BytesLib.toBytes32(account, 0)));
        }
        return string(account); // not supported, just return raw bytes (shouldn't happen)
    }

    /**
     * @dev Returns the admin role that controls `role`. See {grantRole} and
     * {revokeRole}.
     *
     * To change a role's admin, use {_setRoleAdmin}.
     */
    function getRoleAdmin(bytes32 role) public view override returns (bytes32) {
        return _roles[role].adminRole;
    }

    /**
     * @dev Grants `role` to `account`.
     *
     * If `account` had not been already granted `role`, emits a {RoleGranted}
     * event.
     *
     * Requirements:
     *
     * - the caller must have ``role``'s admin role.
     */
    function grantRole(bytes32 role, address account)
        public
        virtual
        override
        onlyRole(getRoleAdmin(role))
    {
        _grantRole(role, account);
    }

    /**
     * @dev Grants `role` to `account`.
     *
     * If `account` had not been already granted `role`, emits a {RoleGrantedBytes}
     * event.
     *
     * Requirements:
     *
     * - the caller must have ``role``'s admin role.
     */
    function grantRoleBytes(bytes32 role, bytes memory account)
        public
        virtual
        override
        onlyRole(getRoleAdmin(role))
    {
        _grantRoleBytes(role, account);
    }

    /**
     * @dev Revokes `role` from `account`.
     *
     * If `account` had been granted `role`, emits a {RoleRevoked} event.
     *
     * Requirements:
     *
     * - the caller must have ``role``'s admin role.
     */
    function revokeRole(bytes32 role, address account)
        public
        virtual
        override
        onlyRole(getRoleAdmin(role))
    {
        _revokeRole(role, account);
    }

    /**
     * @dev Revokes `role` from bytes `account`.
     *
     * If `account` had been granted `role`, emits a {RoleRevokedBytes} event.
     *
     * Requirements:
     *
     * - the caller must have ``role``'s admin role.
     */
    function revokeRoleBytes(bytes32 role, bytes memory account)
        public
        virtual
        override
        onlyRole(getRoleAdmin(role))
    {
        _revokeRoleBytes(role, account);
    }

    /**
     * @dev Revokes `role` from the calling account.
     *
     * Roles are often managed via {grantRole} and {revokeRole}: this function's
     * purpose is to provide a mechanism for accounts to lose their privileges
     * if they are compromised (such as when a trusted device is misplaced).
     *
     * If the calling account had been granted `role`, emits a {RoleRevoked}
     * event.
     *
     * Requirements:
     *
     * - the caller must be `account`.
     */
    function renounceRole(bytes32 role, address account)
        public
        virtual
        override
    {
        // solhint-disable-next-line reason-string
        require(
            keccak256(toBytes(account)) == keccak256(_msgSenderBytes()),
            "OmniteAccessControl: can only renounce roles for self"
        );

        _revokeRole(role, account);
    }

    /**
     * @dev Grants `role` to `account`.
     *
     * If `account` had not been already granted `role`, emits a {RoleGranted}
     * event. Note that unlike {grantRole}, this function doesn't perform any
     * checks on the calling account.
     *
     * [WARNING]
     * ====
     * This function should only be called from the constructor when setting
     * up the initial roles for the system.
     *
     * Using this function in any other way is effectively circumventing the admin
     * system imposed by {AccessControl}.
     * ====
     */
    function _setupRole(bytes32 role, address account) internal virtual {
        _grantRole(role, account);
    }

    /**
     * @dev Sets `adminRole` as ``role``'s admin role.
     *
     * Emits a {RoleAdminChanged} event.
     */
    function _setRoleAdmin(bytes32 role, bytes32 adminRole) internal virtual {
        bytes32 previousAdminRole = getRoleAdmin(role);
        _roles[role].adminRole = adminRole;
        emit RoleAdminChanged(role, previousAdminRole, adminRole);
    }

    function _grantRole(bytes32 role, address account) private {
        if (!hasRole(role, account)) {
            _roles[role].members[toBytes(account)] = true;
            emit RoleGranted(role, account, _msgSender());
        }
    }

    function _grantRoleBytes(bytes32 role, bytes memory account) private {
        if (!hasRoleBytes(role, account)) {
            _roles[role].members[account] = true;
            emit RoleGrantedBytes(role, account, _msgSender());
        }
    }

    function _revokeRole(bytes32 role, address account) private {
        if (hasRole(role, account)) {
            _roles[role].members[toBytes(account)] = false;
            emit RoleRevoked(role, account, _msgSender());
        }
    }

    function _revokeRoleBytes(bytes32 role, bytes memory account) private {
        if (hasRoleBytes(role, account)) {
            _roles[role].members[account] = false;
            emit RoleRevokedBytes(role, account, _msgSender());
        }
    }

    function bytesToAddress(bytes memory bys)
        public
        pure
        returns (address addr)
    {
        // solhint-disable-next-line no-inline-assembly
        assembly {
            addr := mload(add(bys, 20))
        }
    }

    function grantNativeTokenRole(address addr) external {
        grantRole(NATIVE_TOKEN_ROLE, addr);
    }

    function grantNonNativeTokenRole(address addr) external {
        grantRole(NON_NATIVE_TOKEN_ROLE, addr);
    }

    function setRoleAdmin(bytes32 role, bytes32 adminRole)
        external
        onlyRole(CONTROL_LIST_ADMIN_ROLE)
    {
        _setRoleAdmin(role, adminRole);
    }
}

//SPDX-License-Identifier: Business Source License 1.1

pragma solidity ^0.8.9;

import "@openzeppelin/contracts/access/IAccessControl.sol";

/**
 * @dev External interface of AccessControl declared to support ERC165 detection.
 */
interface IAccessControlBytes is IAccessControl {
    /**
     * @dev Emitted when bytes `account` is granted `role`.
     *
     * `sender` is the account that originated the contract call, an admin role
     * bearer except when using {AccessControl-_setupRole}.
     */
    event RoleGrantedBytes(
        bytes32 indexed role,
        bytes indexed account,
        address indexed sender
    );

    /**
     * @dev Emitted when bytes `account` is revoked `role`.
     *
     * `sender` is the account that originated the contract call:
     *   - if using `revokeRole`, it is the admin role bearer
     *   - if using `renounceRole`, it is the role bearer (i.e. `account`)
     */
    event RoleRevokedBytes(
        bytes32 indexed role,
        bytes indexed account,
        address indexed sender
    );

    /**
     * @dev Returns `true` if `account` has been granted `role`.
     */
    function hasRoleBytes(bytes32 role, bytes memory account)
        external
        view
        returns (bool);

    /**
     * @dev Grants `role` to `account`.
     *
     * If `account` had not been already granted `role`, emits a {RoleGrantedBytes}
     * event.
     *
     * Requirements:
     *
     * - the caller must have ``role``'s admin role.
     */
    function grantRoleBytes(bytes32 role, bytes memory account) external;

    /**
     * @dev Revokes `role` from `account`.
     *
     * If `account` had been granted `role`, emits a {RoleRevokedBytes} event.
     *
     * Requirements:
     *
     * - the caller must have ``role``'s admin role.
     */
    function revokeRoleBytes(bytes32 role, bytes memory account) external;

    function checkRole(bytes32 role, address account) external view;
}

//SPDX-License-Identifier: Business Source License 1.1

import "@openzeppelin/contracts/utils/Context.sol";

pragma solidity ^0.8.9;

/**
 * @dev Provides information about the current execution context, including the
 * sender of the transaction and its data. While these are generally available
 * via msg.sender and msg.data, they should not be accessed in such a direct
 * manner, since when dealing with meta-transactions the account sending and
 * paying for execution may not be the actual sender (as far as an application
 * is concerned).
 *
 * This contract is only required for intermediate, library-like contracts.
 */
contract ContextBytes is Context {
    function _msgSenderBytes() internal view virtual returns (bytes memory) {
        return abi.encodePacked(msg.sender);
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (utils/Strings.sol)

pragma solidity ^0.8.0;

/**
 * @dev String operations.
 */
library Strings {
    bytes16 private constant _HEX_SYMBOLS = "0123456789abcdef";
    uint8 private constant _ADDRESS_LENGTH = 20;

    /**
     * @dev Converts a `uint256` to its ASCII `string` decimal representation.
     */
    function toString(uint256 value) internal pure returns (string memory) {
        // Inspired by OraclizeAPI's implementation - MIT licence
        // https://github.com/oraclize/ethereum-api/blob/b42146b063c7d6ee1358846c198246239e9360e8/oraclizeAPI_0.4.25.sol

        if (value == 0) {
            return "0";
        }
        uint256 temp = value;
        uint256 digits;
        while (temp != 0) {
            digits++;
            temp /= 10;
        }
        bytes memory buffer = new bytes(digits);
        while (value != 0) {
            digits -= 1;
            buffer[digits] = bytes1(uint8(48 + uint256(value % 10)));
            value /= 10;
        }
        return string(buffer);
    }

    /**
     * @dev Converts a `uint256` to its ASCII `string` hexadecimal representation.
     */
    function toHexString(uint256 value) internal pure returns (string memory) {
        if (value == 0) {
            return "0x00";
        }
        uint256 temp = value;
        uint256 length = 0;
        while (temp != 0) {
            length++;
            temp >>= 8;
        }
        return toHexString(value, length);
    }

    /**
     * @dev Converts a `uint256` to its ASCII `string` hexadecimal representation with fixed length.
     */
    function toHexString(uint256 value, uint256 length) internal pure returns (string memory) {
        bytes memory buffer = new bytes(2 * length + 2);
        buffer[0] = "0";
        buffer[1] = "x";
        for (uint256 i = 2 * length + 1; i > 1; --i) {
            buffer[i] = _HEX_SYMBOLS[value & 0xf];
            value >>= 4;
        }
        require(value == 0, "Strings: hex length insufficient");
        return string(buffer);
    }

    /**
     * @dev Converts an `address` with fixed length of 20 bytes to its not checksummed ASCII `string` hexadecimal representation.
     */
    function toHexString(address addr) internal pure returns (string memory) {
        return toHexString(uint256(uint160(addr)), _ADDRESS_LENGTH);
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/introspection/ERC165.sol)

pragma solidity ^0.8.0;

import "./IERC165.sol";

/**
 * @dev Implementation of the {IERC165} interface.
 *
 * Contracts that want to implement ERC165 should inherit from this contract and override {supportsInterface} to check
 * for the additional interface id that will be supported. For example:
 *
 * ```solidity
 * function supportsInterface(bytes4 interfaceId) public view virtual override returns (bool) {
 *     return interfaceId == type(MyInterface).interfaceId || super.supportsInterface(interfaceId);
 * }
 * ```
 *
 * Alternatively, {ERC165Storage} provides an easier to use but more expensive implementation.
 */
abstract contract ERC165 is IERC165 {
    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId) public view virtual override returns (bool) {
        return interfaceId == type(IERC165).interfaceId;
    }
}

// SPDX-License-Identifier: Unlicense

pragma solidity >=0.8.0 <0.9.0;

library BytesLib {
    function concat(bytes memory _preBytes, bytes memory _postBytes)
        internal
        pure
        returns (bytes memory)
    {
        bytes memory tempBytes;
        // solhint-disable-next-line no-inline-assembly
        assembly {
            // Get a location of some free memory and store it in tempBytes as
            // Solidity does for memory variables.
            tempBytes := mload(0x40)

            // Store the length of the first bytes array at the beginning of
            // the memory for tempBytes.
            let length := mload(_preBytes)
            mstore(tempBytes, length)

            // Maintain a memory counter for the current write location in the
            // temp bytes array by adding the 32 bytes for the array length to
            // the starting location.
            let mc := add(tempBytes, 0x20)
            // Stop copying when the memory counter reaches the length of the
            // first bytes array.
            let end := add(mc, length)

            for {
                // Initialize a copy counter to the start of the _preBytes data,
                // 32 bytes into its memory.
                let cc := add(_preBytes, 0x20)
            } lt(mc, end) {
                // Increase both counters by 32 bytes each iteration.
                mc := add(mc, 0x20)
                cc := add(cc, 0x20)
            } {
                // Write the _preBytes data into the tempBytes memory 32 bytes
                // at a time.
                mstore(mc, mload(cc))
            }

            // Add the length of _postBytes to the current length of tempBytes
            // and store it as the new length in the first 32 bytes of the
            // tempBytes memory.
            length := mload(_postBytes)
            mstore(tempBytes, add(length, mload(tempBytes)))

            // Move the memory counter back from a multiple of 0x20 to the
            // actual end of the _preBytes data.
            mc := end
            // Stop copying when the memory counter reaches the new combined
            // length of the arrays.
            end := add(mc, length)

            for {
                let cc := add(_postBytes, 0x20)
            } lt(mc, end) {
                mc := add(mc, 0x20)
                cc := add(cc, 0x20)
            } {
                mstore(mc, mload(cc))
            }

            // Update the free-memory pointer by padding our last write location
            // to 32 bytes: add 31 bytes to the end of tempBytes to move to the
            // next 32 byte block, then round down to the nearest multiple of
            // 32. If the sum of the length of the two arrays is zero then add
            // one before rounding down to leave a blank 32 bytes (the length block with 0).
            mstore(
                0x40,
                and(
                    add(add(end, iszero(add(length, mload(_preBytes)))), 31),
                    not(31) // Round down to the nearest 32 bytes.
                )
            )
        }

        return tempBytes;
    }

    function concatStorage(bytes storage _preBytes, bytes memory _postBytes)
        internal
    {
        // solhint-disable-next-line no-inline-assembly
        assembly {
            // Read the first 32 bytes of _preBytes storage, which is the length
            // of the array. (We don't need to use the offset into the slot
            // because arrays use the entire slot.)
            let fslot := sload(_preBytes.slot)
            // Arrays of 31 bytes or less have an even value in their slot,
            // while longer arrays have an odd value. The actual length is
            // the slot divided by two for odd values, and the lowest order
            // byte divided by two for even values.
            // If the slot is even, bitwise and the slot with 255 and divide by
            // two to get the length. If the slot is odd, bitwise and the slot
            // with -1 and divide by two.
            let slength := div(
                and(fslot, sub(mul(0x100, iszero(and(fslot, 1))), 1)),
                2
            )
            let mlength := mload(_postBytes)
            let newlength := add(slength, mlength)
            // slength can contain both the length and contents of the array
            // if length < 32 bytes so let's prepare for that
            // v. http://solidity.readthedocs.io/en/latest/miscellaneous.html#layout-of-state-variables-in-storage
            switch add(lt(slength, 32), lt(newlength, 32))
            case 2 {
                // Since the new array still fits in the slot, we just need to
                // update the contents of the slot.
                // uint256(bytes_storage) = uint256(bytes_storage) + uint256(bytes_memory) + new_length
                sstore(
                    _preBytes.slot,
                    // all the modifications to the slot are inside this
                    // next block
                    add(
                        // we can just add to the slot contents because the
                        // bytes we want to change are the LSBs
                        fslot,
                        add(
                            mul(
                                div(
                                    // load the bytes from memory
                                    mload(add(_postBytes, 0x20)),
                                    // zero all bytes to the right
                                    exp(0x100, sub(32, mlength))
                                ),
                                // and now shift left the number of bytes to
                                // leave space for the length in the slot
                                exp(0x100, sub(32, newlength))
                            ),
                            // increase length by the double of the memory
                            // bytes length
                            mul(mlength, 2)
                        )
                    )
                )
            }
            case 1 {
                // The stored value fits in the slot, but the combined value
                // will exceed it.
                // get the keccak hash to get the contents of the array
                mstore(0x0, _preBytes.slot)
                let sc := add(keccak256(0x0, 0x20), div(slength, 32))

                // save new length
                sstore(_preBytes.slot, add(mul(newlength, 2), 1))

                // The contents of the _postBytes array start 32 bytes into
                // the structure. Our first read should obtain the `submod`
                // bytes that can fit into the unused space in the last word
                // of the stored array. To get this, we read 32 bytes starting
                // from `submod`, so the data we read overlaps with the array
                // contents by `submod` bytes. Masking the lowest-order
                // `submod` bytes allows us to add that value directly to the
                // stored value.

                let submod := sub(32, slength)
                let mc := add(_postBytes, submod)
                let end := add(_postBytes, mlength)
                let mask := sub(exp(0x100, submod), 1)

                sstore(
                    sc,
                    add(
                        and(
                            fslot,
                            0xffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff00
                        ),
                        and(mload(mc), mask)
                    )
                )

                for {
                    mc := add(mc, 0x20)
                    sc := add(sc, 1)
                } lt(mc, end) {
                    sc := add(sc, 1)
                    mc := add(mc, 0x20)
                } {
                    sstore(sc, mload(mc))
                }

                mask := exp(0x100, sub(mc, end))

                sstore(sc, mul(div(mload(mc), mask), mask))
            }
            default {
                // get the keccak hash to get the contents of the array
                mstore(0x0, _preBytes.slot)
                // Start copying to the last used word of the stored array.
                let sc := add(keccak256(0x0, 0x20), div(slength, 32))

                // save new length
                sstore(_preBytes.slot, add(mul(newlength, 2), 1))

                // Copy over the first `submod` bytes of the new data as in
                // case 1 above.
                let slengthmod := mod(slength, 32)
                let mlengthmod := mod(mlength, 32)
                let submod := sub(32, slengthmod)
                let mc := add(_postBytes, submod)
                let end := add(_postBytes, mlength)
                let mask := sub(exp(0x100, submod), 1)

                sstore(sc, add(sload(sc), and(mload(mc), mask)))

                for {
                    sc := add(sc, 1)
                    mc := add(mc, 0x20)
                } lt(mc, end) {
                    sc := add(sc, 1)
                    mc := add(mc, 0x20)
                } {
                    sstore(sc, mload(mc))
                }

                mask := exp(0x100, sub(mc, end))

                sstore(sc, mul(div(mload(mc), mask), mask))
            }
        }
    }

    function slice(
        bytes memory _bytes,
        uint256 _start,
        uint256 _length
    ) internal pure returns (bytes memory) {
        require(_length + 31 >= _length, "slice_overflow");
        require(_bytes.length >= _start + _length, "slice_outOfBounds");

        bytes memory tempBytes;
        // solhint-disable-next-line no-inline-assembly
        assembly {
            switch iszero(_length)
            case 0 {
                // Get a location of some free memory and store it in tempBytes as
                // Solidity does for memory variables.
                tempBytes := mload(0x40)

                // The first word of the slice result is potentially a partial
                // word read from the original array. To read it, we calculate
                // the length of that partial word and start copying that many
                // bytes into the array. The first word we copy will start with
                // data we don't care about, but the last `lengthmod` bytes will
                // land at the beginning of the contents of the new array. When
                // we're done copying, we overwrite the full first word with
                // the actual length of the slice.
                let lengthmod := and(_length, 31)

                // The multiplication in the next line is necessary
                // because when slicing multiples of 32 bytes (lengthmod == 0)
                // the following copy loop was copying the origin's length
                // and then ending prematurely not copying everything it should.
                let mc := add(
                    add(tempBytes, lengthmod),
                    mul(0x20, iszero(lengthmod))
                )
                let end := add(mc, _length)

                for {
                    // The multiplication in the next line has the same exact purpose
                    // as the one above.
                    let cc := add(
                        add(
                            add(_bytes, lengthmod),
                            mul(0x20, iszero(lengthmod))
                        ),
                        _start
                    )
                } lt(mc, end) {
                    mc := add(mc, 0x20)
                    cc := add(cc, 0x20)
                } {
                    mstore(mc, mload(cc))
                }

                mstore(tempBytes, _length)

                //update free-memory pointer
                //allocating the array padded to 32 bytes like the compiler does now
                mstore(0x40, and(add(mc, 31), not(31)))
            }
            //if we want a zero-length slice let's just return a zero-length array
            default {
                tempBytes := mload(0x40)
                //zero out the 32 bytes slice we are about to return
                //we need to do it because Solidity does not garbage collect
                mstore(tempBytes, 0)

                mstore(0x40, add(tempBytes, 0x20))
            }
        }

        return tempBytes;
    }

    function toAddress(bytes memory _bytes, uint256 _start)
        internal
        pure
        returns (address)
    {
        require(_bytes.length >= _start + 20, "toAddress_outOfBounds");
        address tempAddress;
        // solhint-disable-next-line no-inline-assembly
        assembly {
            tempAddress := div(
                mload(add(add(_bytes, 0x20), _start)),
                0x1000000000000000000000000
            )
        }

        return tempAddress;
    }

    function toUint8(bytes memory _bytes, uint256 _start)
        internal
        pure
        returns (uint8)
    {
        require(_bytes.length >= _start + 1, "toUint8_outOfBounds");
        uint8 tempUint;
        // solhint-disable-next-line no-inline-assembly
        assembly {
            tempUint := mload(add(add(_bytes, 0x1), _start))
        }

        return tempUint;
    }

    function toBool(bytes memory _bytes, uint256 _start)
        internal
        pure
        returns (bool)
    {
        return toUint256(_bytes, _start) != 0;
    }

    function toUint16(bytes memory _bytes, uint256 _start)
        internal
        pure
        returns (uint16)
    {
        require(_bytes.length >= _start + 2, "toUint16_outOfBounds");
        uint16 tempUint;
        // solhint-disable-next-line no-inline-assembly
        assembly {
            tempUint := mload(add(add(_bytes, 0x2), _start))
        }

        return tempUint;
    }

    function toUint32(bytes memory _bytes, uint256 _start)
        internal
        pure
        returns (uint32)
    {
        require(_bytes.length >= _start + 4, "toUint32_outOfBounds");
        uint32 tempUint;
        // solhint-disable-next-line no-inline-assembly
        assembly {
            tempUint := mload(add(add(_bytes, 0x4), _start))
        }

        return tempUint;
    }

    function toUint64(bytes memory _bytes, uint256 _start)
        internal
        pure
        returns (uint64)
    {
        require(_bytes.length >= _start + 8, "toUint64_outOfBounds");
        uint64 tempUint;
        // solhint-disable-next-line no-inline-assembly
        assembly {
            tempUint := mload(add(add(_bytes, 0x8), _start))
        }

        return tempUint;
    }

    function toUint96(bytes memory _bytes, uint256 _start)
        internal
        pure
        returns (uint96)
    {
        require(_bytes.length >= _start + 12, "toUint96_outOfBounds");
        uint96 tempUint;
        // solhint-disable-next-line no-inline-assembly
        assembly {
            tempUint := mload(add(add(_bytes, 0xc), _start))
        }

        return tempUint;
    }

    function toUint128(bytes memory _bytes, uint256 _start)
        internal
        pure
        returns (uint128)
    {
        require(_bytes.length >= _start + 16, "toUint128_outOfBounds");
        uint128 tempUint;
        // solhint-disable-next-line no-inline-assembly
        assembly {
            tempUint := mload(add(add(_bytes, 0x10), _start))
        }

        return tempUint;
    }

    function toUint256(bytes memory _bytes, uint256 _start)
        internal
        pure
        returns (uint256)
    {
        require(_bytes.length >= _start + 32, "toUint256_outOfBounds");
        uint256 tempUint;
        // solhint-disable-next-line no-inline-assembly
        assembly {
            tempUint := mload(add(add(_bytes, 0x20), _start))
        }

        return tempUint;
    }

    function toBytes32(bytes memory _bytes, uint256 _start)
        internal
        pure
        returns (bytes32)
    {
        require(_bytes.length >= _start + 32, "toBytes32_outOfBounds");
        bytes32 tempBytes32;
        // solhint-disable-next-line no-inline-assembly
        assembly {
            tempBytes32 := mload(add(add(_bytes, 0x20), _start))
        }

        return tempBytes32;
    }

    function equal(bytes memory _preBytes, bytes memory _postBytes)
        internal
        pure
        returns (bool)
    {
        bool success = true;
        // solhint-disable-next-line no-inline-assembly
        assembly {
            let length := mload(_preBytes)

            // if lengths don't match the arrays are not equal
            switch eq(length, mload(_postBytes))
            case 1 {
                // cb is a circuit breaker in the for loop since there's
                //  no said feature for inline assembly loops
                // cb = 1 - don't breaker
                // cb = 0 - break
                let cb := 1

                let mc := add(_preBytes, 0x20)
                let end := add(mc, length)

                for {
                    let cc := add(_postBytes, 0x20)
                    // the next line is the loop condition:
                    // while(uint256(mc < end) + cb == 2)
                } eq(add(lt(mc, end), cb), 2) {
                    mc := add(mc, 0x20)
                    cc := add(cc, 0x20)
                } {
                    // if any of these checks fails then arrays are not equal
                    if iszero(eq(mload(mc), mload(cc))) {
                        // unsuccess:
                        success := 0
                        cb := 0
                    }
                }
            }
            default {
                // unsuccess:
                success := 0
            }
        }

        return success;
    }

    function equalStorage(bytes storage _preBytes, bytes memory _postBytes)
        internal
        view
        returns (bool)
    {
        bool success = true;
        // solhint-disable-next-line no-inline-assembly
        assembly {
            // we know _preBytes_offset is 0
            let fslot := sload(_preBytes.slot)
            // Decode the length of the stored array like in concatStorage().
            let slength := div(
                and(fslot, sub(mul(0x100, iszero(and(fslot, 1))), 1)),
                2
            )
            let mlength := mload(_postBytes)

            // if lengths don't match the arrays are not equal
            switch eq(slength, mlength)
            case 1 {
                // slength can contain both the length and contents of the array
                // if length < 32 bytes so let's prepare for that
                // v. http://solidity.readthedocs.io/en/latest/miscellaneous.html#layout-of-state-variables-in-storage
                if iszero(iszero(slength)) {
                    switch lt(slength, 32)
                    case 1 {
                        // blank the last byte which is the length
                        fslot := mul(div(fslot, 0x100), 0x100)

                        if iszero(eq(fslot, mload(add(_postBytes, 0x20)))) {
                            // unsuccess:
                            success := 0
                        }
                    }
                    default {
                        // cb is a circuit breaker in the for loop since there's
                        //  no said feature for inline assembly loops
                        // cb = 1 - don't breaker
                        // cb = 0 - break
                        let cb := 1

                        // get the keccak hash to get the contents of the array
                        mstore(0x0, _preBytes.slot)
                        let sc := keccak256(0x0, 0x20)

                        let mc := add(_postBytes, 0x20)
                        let end := add(mc, mlength)

                        // the next line is the loop condition:
                        // while(uint256(mc < end) + cb == 2)
                        // solhint-disable-next-line no-empty-blocks
                        for {

                        } eq(add(lt(mc, end), cb), 2) {
                            sc := add(sc, 1)
                            mc := add(mc, 0x20)
                        } {
                            if iszero(eq(sload(sc), mload(mc))) {
                                // unsuccess:
                                success := 0
                                cb := 0
                            }
                        }
                    }
                }
            }
            default {
                // unsuccess:
                success := 0
            }
        }

        return success;
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (access/IAccessControl.sol)

pragma solidity ^0.8.0;

/**
 * @dev External interface of AccessControl declared to support ERC165 detection.
 */
interface IAccessControl {
    /**
     * @dev Emitted when `newAdminRole` is set as ``role``'s admin role, replacing `previousAdminRole`
     *
     * `DEFAULT_ADMIN_ROLE` is the starting admin for all roles, despite
     * {RoleAdminChanged} not being emitted signaling this.
     *
     * _Available since v3.1._
     */
    event RoleAdminChanged(bytes32 indexed role, bytes32 indexed previousAdminRole, bytes32 indexed newAdminRole);

    /**
     * @dev Emitted when `account` is granted `role`.
     *
     * `sender` is the account that originated the contract call, an admin role
     * bearer except when using {AccessControl-_setupRole}.
     */
    event RoleGranted(bytes32 indexed role, address indexed account, address indexed sender);

    /**
     * @dev Emitted when `account` is revoked `role`.
     *
     * `sender` is the account that originated the contract call:
     *   - if using `revokeRole`, it is the admin role bearer
     *   - if using `renounceRole`, it is the role bearer (i.e. `account`)
     */
    event RoleRevoked(bytes32 indexed role, address indexed account, address indexed sender);

    /**
     * @dev Returns `true` if `account` has been granted `role`.
     */
    function hasRole(bytes32 role, address account) external view returns (bool);

    /**
     * @dev Returns the admin role that controls `role`. See {grantRole} and
     * {revokeRole}.
     *
     * To change a role's admin, use {AccessControl-_setRoleAdmin}.
     */
    function getRoleAdmin(bytes32 role) external view returns (bytes32);

    /**
     * @dev Grants `role` to `account`.
     *
     * If `account` had not been already granted `role`, emits a {RoleGranted}
     * event.
     *
     * Requirements:
     *
     * - the caller must have ``role``'s admin role.
     */
    function grantRole(bytes32 role, address account) external;

    /**
     * @dev Revokes `role` from `account`.
     *
     * If `account` had been granted `role`, emits a {RoleRevoked} event.
     *
     * Requirements:
     *
     * - the caller must have ``role``'s admin role.
     */
    function revokeRole(bytes32 role, address account) external;

    /**
     * @dev Revokes `role` from the calling account.
     *
     * Roles are often managed via {grantRole} and {revokeRole}: this function's
     * purpose is to provide a mechanism for accounts to lose their privileges
     * if they are compromised (such as when a trusted device is misplaced).
     *
     * If the calling account had been granted `role`, emits a {RoleRevoked}
     * event.
     *
     * Requirements:
     *
     * - the caller must be `account`.
     */
    function renounceRole(bytes32 role, address account) external;
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/introspection/IERC165.sol)

pragma solidity ^0.8.0;

/**
 * @dev Interface of the ERC165 standard, as defined in the
 * https://eips.ethereum.org/EIPS/eip-165[EIP].
 *
 * Implementers can declare support of contract interfaces, which can then be
 * queried by others ({ERC165Checker}).
 *
 * For an implementation, see {ERC165}.
 */
interface IERC165 {
    /**
     * @dev Returns true if this contract implements the interface defined by
     * `interfaceId`. See the corresponding
     * https://eips.ethereum.org/EIPS/eip-165#how-interfaces-are-identified[EIP section]
     * to learn more about how these ids are created.
     *
     * This function call must use less than 30 000 gas.
     */
    function supportsInterface(bytes4 interfaceId) external view returns (bool);
}

//SPDX-License-Identifier: Business Source License 1.1

pragma solidity ^0.8.9;

interface ICreate2ContractsFactory {
    event NewContractDeployed(
        address indexed contractAddress,
        bytes bytecode,
        bytes constructorParams,
        bytes32 salt
    );

    function deployCreate2WithParams(
        bytes memory bytecode,
        bytes memory constructorParams,
        bytes32 salt
    ) external returns (address);

    function deployCreate2(bytes memory bytecode, bytes32 salt)
        external
        returns (address);
}