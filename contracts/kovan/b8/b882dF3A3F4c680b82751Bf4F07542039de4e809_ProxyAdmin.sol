// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

/**
 * @title iL1ChugSplashDeployer
 */
interface iL1ChugSplashDeployer {
    function isUpgrading() external view returns (bool);
}

/**
 * @title L1ChugSplashProxy
 * @dev Basic ChugSplash proxy contract for L1. Very close to being a normal proxy but has added
 * functions `setCode` and `setStorage` for changing the code or storage of the contract. Nifty!
 *
 * Note for future developers: do NOT make anything in this contract 'public' unless you know what
 * you're doing. Anything public can potentially have a function signature that conflicts with a
 * signature attached to the implementation contract. Public functions SHOULD always have the
 * 'proxyCallIfNotOwner' modifier unless there's some *really* good reason not to have that
 * modifier. And there almost certainly is not a good reason to not have that modifier. Beware!
 */
contract L1ChugSplashProxy {
    /*************
     * Constants *
     *************/

    // "Magic" prefix. When prepended to some arbitrary bytecode and used to create a contract, the
    // appended bytecode will be deployed as given.
    bytes13 internal constant DEPLOY_CODE_PREFIX = 0x600D380380600D6000396000f3;

    // bytes32(uint256(keccak256('eip1967.proxy.implementation')) - 1)
    bytes32 internal constant IMPLEMENTATION_KEY =
        0x360894a13ba1a3210667c828492db98dca3e2076cc3735a920a3ca505d382bbc;

    // bytes32(uint256(keccak256('eip1967.proxy.admin')) - 1)
    bytes32 internal constant OWNER_KEY =
        0xb53127684a568b3173ae13b9f8a6016e243e63b6e8ee1178d6a717850b5d6103;

    /***************
     * Constructor *
     ***************/

    /**
     * @param _owner Address of the initial contract owner.
     */
    constructor(address _owner) {
        _setOwner(_owner);
    }

    /**********************
     * Function Modifiers *
     **********************/

    /**
     * Blocks a function from being called when the parent signals that the system should be paused
     * via an isUpgrading function.
     */
    modifier onlyWhenNotPaused() {
        address owner = _getOwner();

        // We do a low-level call because there's no guarantee that the owner actually *is* an
        // L1ChugSplashDeployer contract and Solidity will throw errors if we do a normal call and
        // it turns out that it isn't the right type of contract.
        (bool success, bytes memory returndata) = owner.staticcall(
            abi.encodeWithSelector(iL1ChugSplashDeployer.isUpgrading.selector)
        );

        // If the call was unsuccessful then we assume that there's no "isUpgrading" method and we
        // can just continue as normal. We also expect that the return value is exactly 32 bytes
        // long. If this isn't the case then we can safely ignore the result.
        if (success && returndata.length == 32) {
            // Although the expected value is a *boolean*, it's safer to decode as a uint256 in the
            // case that the isUpgrading function returned something other than 0 or 1. But we only
            // really care about the case where this value is 0 (= false).
            uint256 ret = abi.decode(returndata, (uint256));
            require(ret == 0, "L1ChugSplashProxy: system is currently being upgraded");
        }

        _;
    }

    /**
     * Makes a proxy call instead of triggering the given function when the caller is either the
     * owner or the zero address. Caller can only ever be the zero address if this function is
     * being called off-chain via eth_call, which is totally fine and can be convenient for
     * client-side tooling. Avoids situations where the proxy and implementation share a sighash
     * and the proxy function ends up being called instead of the implementation one.
     *
     * Note: msg.sender == address(0) can ONLY be triggered off-chain via eth_call. If there's a
     * way for someone to send a transaction with msg.sender == address(0) in any real context then
     * we have much bigger problems. Primary reason to include this additional allowed sender is
     * because the owner address can be changed dynamically and we do not want clients to have to
     * keep track of the current owner in order to make an eth_call that doesn't trigger the
     * proxied contract.
     */
    // slither-disable-next-line incorrect-modifier
    modifier proxyCallIfNotOwner() {
        if (msg.sender == _getOwner() || msg.sender == address(0)) {
            _;
        } else {
            // This WILL halt the call frame on completion.
            _doProxyCall();
        }
    }

    /*********************
     * Fallback Function *
     *********************/

    // slither-disable-next-line locked-ether
    fallback() external payable {
        // Proxy call by default.
        _doProxyCall();
    }

    /********************
     * Public Functions *
     ********************/

    /**
     * Sets the code that should be running behind this proxy. Note that this scheme is a bit
     * different from the standard proxy scheme where one would typically deploy the code
     * separately and then set the implementation address. We're doing it this way because it gives
     * us a lot more freedom on the client side. Can only be triggered by the contract owner.
     * @param _code New contract code to run inside this contract.
     */
    // slither-disable-next-line external-function
    function setCode(bytes memory _code) public proxyCallIfNotOwner {
        // Get the code hash of the current implementation.
        address implementation = _getImplementation();

        // If the code hash matches the new implementation then we return early.
        if (keccak256(_code) == _getAccountCodeHash(implementation)) {
            return;
        }

        // Create the deploycode by appending the magic prefix.
        bytes memory deploycode = abi.encodePacked(DEPLOY_CODE_PREFIX, _code);

        // Deploy the code and set the new implementation address.
        address newImplementation;
        assembly {
            newImplementation := create(0x0, add(deploycode, 0x20), mload(deploycode))
        }

        // Check that the code was actually deployed correctly. I'm not sure if you can ever
        // actually fail this check. Should only happen if the contract creation from above runs
        // out of gas but this parent execution thread does NOT run out of gas. Seems like we
        // should be doing this check anyway though.
        require(
            _getAccountCodeHash(newImplementation) == keccak256(_code),
            "L1ChugSplashProxy: code was not correctly deployed."
        );

        _setImplementation(newImplementation);
    }

    /**
     * Modifies some storage slot within the proxy contract. Gives us a lot of power to perform
     * upgrades in a more transparent way. Only callable by the owner.
     * @param _key Storage key to modify.
     * @param _value New value for the storage key.
     */
    // slither-disable-next-line external-function
    function setStorage(bytes32 _key, bytes32 _value) public proxyCallIfNotOwner {
        assembly {
            sstore(_key, _value)
        }
    }

    /**
     * Changes the owner of the proxy contract. Only callable by the owner.
     * @param _owner New owner of the proxy contract.
     */
    // slither-disable-next-line external-function
    function setOwner(address _owner) public proxyCallIfNotOwner {
        _setOwner(_owner);
    }

    /**
     * Queries the owner of the proxy contract. Can only be called by the owner OR by making an
     * eth_call and setting the "from" address to address(0).
     * @return Owner address.
     */
    // slither-disable-next-line external-function
    function getOwner() public proxyCallIfNotOwner returns (address) {
        return _getOwner();
    }

    /**
     * Queries the implementation address. Can only be called by the owner OR by making an
     * eth_call and setting the "from" address to address(0).
     * @return Implementation address.
     */
    // slither-disable-next-line external-function
    function getImplementation() public proxyCallIfNotOwner returns (address) {
        return _getImplementation();
    }

    /**********************
     * Internal Functions *
     **********************/

    /**
     * Sets the implementation address.
     * @param _implementation New implementation address.
     */
    function _setImplementation(address _implementation) internal {
        assembly {
            sstore(IMPLEMENTATION_KEY, _implementation)
        }
    }

    /**
     * Queries the implementation address.
     * @return Implementation address.
     */
    function _getImplementation() internal view returns (address) {
        address implementation;
        assembly {
            implementation := sload(IMPLEMENTATION_KEY)
        }
        return implementation;
    }

    /**
     * Changes the owner of the proxy contract.
     * @param _owner New owner of the proxy contract.
     */
    function _setOwner(address _owner) internal {
        assembly {
            sstore(OWNER_KEY, _owner)
        }
    }

    /**
     * Queries the owner of the proxy contract.
     * @return Owner address.
     */
    function _getOwner() internal view returns (address) {
        address owner;
        assembly {
            owner := sload(OWNER_KEY)
        }
        return owner;
    }

    /**
     * Gets the code hash for a given account.
     * @param _account Address of the account to get a code hash for.
     * @return Code hash for the account.
     */
    function _getAccountCodeHash(address _account) internal view returns (bytes32) {
        bytes32 codeHash;
        assembly {
            codeHash := extcodehash(_account)
        }
        return codeHash;
    }

    /**
     * Performs the proxy call via a delegatecall.
     */
    function _doProxyCall() internal onlyWhenNotPaused {
        address implementation = _getImplementation();

        require(implementation != address(0), "L1ChugSplashProxy: implementation is not set yet");

        assembly {
            // Copy calldata into memory at 0x0....calldatasize.
            calldatacopy(0x0, 0x0, calldatasize())

            // Perform the delegatecall, make sure to pass all available gas.
            let success := delegatecall(gas(), implementation, 0x0, calldatasize(), 0x0, 0x0)

            // Copy returndata into memory at 0x0....returndatasize. Note that this *will*
            // overwrite the calldata that we just copied into memory but that doesn't really
            // matter because we'll be returning in a second anyway.
            returndatacopy(0x0, 0x0, returndatasize())

            // Success == 0 means a revert. We'll revert too and pass the data up.
            if iszero(success) {
                revert(0x0, returndatasize())
            }

            // Otherwise we'll just return and pass the data up.
            return(0x0, returndatasize())
        }
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

/* External Imports */
import { Ownable } from "@openzeppelin/contracts/access/Ownable.sol";

/**
 * @title Lib_AddressManager
 */
contract Lib_AddressManager is Ownable {
    /**********
     * Events *
     **********/

    event AddressSet(string indexed _name, address _newAddress, address _oldAddress);

    /*************
     * Variables *
     *************/

    mapping(bytes32 => address) private addresses;

    /********************
     * Public Functions *
     ********************/

    /**
     * Changes the address associated with a particular name.
     * @param _name String name to associate an address with.
     * @param _address Address to associate with the name.
     */
    function setAddress(string memory _name, address _address) external onlyOwner {
        bytes32 nameHash = _getNameHash(_name);
        address oldAddress = addresses[nameHash];
        addresses[nameHash] = _address;

        emit AddressSet(_name, _address, oldAddress);
    }

    /**
     * Retrieves the address associated with a given name.
     * @param _name Name to retrieve an address for.
     * @return Address associated with the given name.
     */
    function getAddress(string memory _name) external view returns (address) {
        return addresses[_getNameHash(_name)];
    }

    /**********************
     * Internal Functions *
     **********************/

    /**
     * Computes the hash of a name.
     * @param _name Name to compute a hash for.
     * @return Hash of the given name.
     */
    function _getNameHash(string memory _name) internal pure returns (bytes32) {
        return keccak256(abi.encodePacked(_name));
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

/**
 * @title Proxy
 * @notice Proxy is a transparent proxy that passes through the call
 *         if the caller is the owner or if the caller is `address(0)`,
 *         meaning that the call originated from an offchain simulation.
 */
contract Proxy {
    /**
     * @notice An event that is emitted each time the implementation is changed.
     *         This event is part of the EIP 1967 spec.
     *
     * @param implementation The address of the implementation contract
     */
    event Upgraded(address indexed implementation);

    /**
     * @notice An event that is emitted each time the owner is upgraded.
     *         This event is part of the EIP 1967 spec.
     *
     * @param previousAdmin The previous owner of the contract
     * @param newAdmin      The new owner of the contract
     */
    event AdminChanged(address previousAdmin, address newAdmin);

    /**
     * @notice The storage slot that holds the address of the implementation.
     *         bytes32(uint256(keccak256('eip1967.proxy.implementation')) - 1)
     */
    bytes32 internal constant IMPLEMENTATION_KEY =
        0x360894a13ba1a3210667c828492db98dca3e2076cc3735a920a3ca505d382bbc;

    /**
     * @notice The storage slot that holds the address of the owner.
     *         bytes32(uint256(keccak256('eip1967.proxy.admin')) - 1)
     */
    bytes32 internal constant OWNER_KEY =
        0xb53127684a568b3173ae13b9f8a6016e243e63b6e8ee1178d6a717850b5d6103;

    /**
     * @notice set the initial owner during contract deployment. The
     *         owner is stored at the eip1967 owner storage slot so that
     *         storage collision with the implementation is not possible.
     *
     * @param _admin Address of the initial contract owner. The owner has
     *               the ability to access the transparent proxy interface.
     */
    constructor(address _admin) {
        _changeAdmin(_admin);
    }

    // slither-disable-next-line locked-ether
    fallback() external payable {
        // Proxy call by default.
        _doProxyCall();
    }

    /**
     * @notice A modifier that reverts if not called by the owner
     *         or by `address(0)` to allow `eth_call` to interact
     *         with the proxy without needing to use low level storage
     *         inspection. It is assumed that nobody controls the private
     *         key for `address(0)`.
     */
    modifier proxyCallIfNotAdmin() {
        if (msg.sender == _getAdmin() || msg.sender == address(0)) {
            _;
        } else {
            // This WILL halt the call frame on completion.
            _doProxyCall();
        }
    }

    /**
     * @notice Set the implementation contract address. The code at this
     *         address will execute when this contract is called.
     *
     * @param _implementation The address of the implementation contract
     */
    function upgradeTo(address _implementation) external proxyCallIfNotAdmin {
        _setImplementation(_implementation);
    }

    /**
     * @notice Set the implementation and call a function in a single
     *         transaction. This is useful to ensure atomic `initialize()`
     *         based upgrades.
     *
     * @param _implementation The address of the implementation contract
     * @param _data           The calldata to delegatecall the new
     *                        implementation with
     */
    function upgradeToAndCall(address _implementation, bytes calldata _data)
        external
        payable
        proxyCallIfNotAdmin
        returns (bytes memory)
    {
        _setImplementation(_implementation);
        (bool success, bytes memory returndata) = _implementation.delegatecall(_data);
        require(success);
        return returndata;
    }

    /**
     * @notice Changes the owner of the proxy contract. Only callable by the owner.
     *
     * @param _admin New owner of the proxy contract.
     */
    function changeAdmin(address _admin) external proxyCallIfNotAdmin {
        _changeAdmin(_admin);
    }

    /**
     * @notice Gets the owner of the proxy contract.
     *
     * @return Owner address.
     */
    function admin() external proxyCallIfNotAdmin returns (address) {
        return _getAdmin();
    }

    /**
     * @notice Queries the implementation address.
     *
     * @return Implementation address.
     */
    function implementation() external proxyCallIfNotAdmin returns (address) {
        return _getImplementation();
    }

    /**
     * @notice Sets the implementation address.
     *
     * @param _implementation New implementation address.
     */
    function _setImplementation(address _implementation) internal {
        assembly {
            sstore(IMPLEMENTATION_KEY, _implementation)
        }
        emit Upgraded(_implementation);
    }

    /**
     * @notice Queries the implementation address.
     *
     * @return implementation address.
     */
    function _getImplementation() internal view returns (address) {
        address implementation;
        assembly {
            implementation := sload(IMPLEMENTATION_KEY)
        }
        return implementation;
    }

    /**
     * @notice Changes the owner of the proxy contract.
     *
     * @param _admin New owner of the proxy contract.
     */
    function _changeAdmin(address _admin) internal {
        address previous = _getAdmin();
        assembly {
            sstore(OWNER_KEY, _admin)
        }
        emit AdminChanged(previous, _admin);
    }

    /**
     * @notice Queries the owner of the proxy contract.
     *
     * @return owner address.
     */
    function _getAdmin() internal view returns (address) {
        address owner;
        assembly {
            owner := sload(OWNER_KEY)
        }
        return owner;
    }

    /**
     * @notice Performs the proxy call via a delegatecall.
     */
    function _doProxyCall() internal {
        address implementation = _getImplementation();

        require(implementation != address(0), "Proxy: implementation not initialized");

        assembly {
            // Copy calldata into memory at 0x0....calldatasize.
            calldatacopy(0x0, 0x0, calldatasize())

            // Perform the delegatecall, make sure to pass all available gas.
            let success := delegatecall(gas(), implementation, 0x0, calldatasize(), 0x0, 0x0)

            // Copy returndata into memory at 0x0....returndatasize. Note that this *will*
            // overwrite the calldata that we just copied into memory but that doesn't really
            // matter because we'll be returning in a second anyway.
            returndatacopy(0x0, 0x0, returndatasize())

            // Success == 0 means a revert. We'll revert too and pass the data up.
            if iszero(success) {
                revert(0x0, returndatasize())
            }

            // Otherwise we'll just return and pass the data up.
            return(0x0, returndatasize())
        }
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import { Proxy } from "./Proxy.sol";
import { Owned } from "@rari-capital/solmate/src/auth/Owned.sol";
import { Lib_AddressManager } from "../legacy/Lib_AddressManager.sol";
import { L1ChugSplashProxy } from "../legacy/L1ChugSplashProxy.sol";

/**
 * @title ProxyAdmin
 * @dev This is an auxiliary contract meant to be assigned as the admin of a Proxy, based on
 *      the OpenZeppelin implementation. It has backwards compatibility logic to work with the
 *      various types of proxies that have been deployed by Optimism.
 */
contract ProxyAdmin is Owned {
    /**
     * @notice The proxy types that the ProxyAdmin can manage.
     *
     * @custom:value OpenZeppelin     Represents the OpenZeppelin style transparent proxy
     *                                interface, this is the standard.
     * @custom:value Chugsplash       Represents the Chugsplash proxy interface,
     *                                this is legacy.
     * @custom:value ResolvedDelegate Represents the ResolvedDelegate proxy
     *                                interface, this is legacy.
     */
    enum ProxyType {
        OpenZeppelin,
        Chugsplash,
        ResolvedDelegate
    }

    /**
     * @custom:legacy
     * @notice         A mapping of proxy types, used for backwards compatibility.
     */
    mapping(address => ProxyType) public proxyType;

    /**
     * @custom:legacy
     * @notice A reverse mapping of addresses to names held in the AddressManager. This must be
     *         manually kept up to date with changes in the AddressManager for this contract
     *         to be able to work as an admin for the Lib_ResolvedDelegateProxy type.
     */
    mapping(address => string) public implementationName;

    /**
     * @custom:legacy
     * @notice The address of the address manager, this is required to manage the
     *         Lib_ResolvedDelegateProxy type.
     */
    Lib_AddressManager public addressManager;

    /**
     * @custom:legacy
     * @notice A legacy upgrading indicator used by the old Chugsplash Proxy.
     */
    bool internal upgrading = false;

    /**
     * @notice Set the owner of the ProxyAdmin via constructor argument.
     */
    constructor(address owner) Owned(owner) {}

    /**
     * @notice
     *
     * @param _address   The address of the proxy.
     * @param _type The type of the proxy.
     */
    function setProxyType(address _address, ProxyType _type) external onlyOwner {
        proxyType[_address] = _type;
    }

    /**
     * @notice Set the proxy type in the mapping. This needs to be kept up to date by the owner of
     *         the contract.
     *
     * @param _address The address to be named.
     * @param _name    The name of the address.
     */
    function setImplementationName(address _address, string memory _name) external onlyOwner {
        implementationName[_address] = _name;
    }

    /**
     * @notice Set the address of the address manager. This is required to manage the legacy
     *         `Lib_ResolvedDelegateProxy`.
     *
     * @param _address The address of the address manager.
     */
    function setAddressManager(address _address) external onlyOwner {
        addressManager = Lib_AddressManager(_address);
    }

    /**
     * @custom:legacy
     * @notice Set an address in the address manager. This is required because only the owner of
     *         the AddressManager can set the addresses in it.
     *
     * @param _name    The name of the address to set in the address manager.
     * @param _address The address to set in the address manager.
     */
    function setAddress(string memory _name, address _address) external onlyOwner {
        addressManager.setAddress(_name, _address);
    }

    /**
     * @custom:legacy
     * @notice Legacy function used by the old Chugsplash proxy to determine if an upgrade is
     *         happening.
     *
     * @return Whether or not there is an upgrade going on
     */
    function isUpgrading() external view returns (bool) {
        return upgrading;
    }

    /**
     * @custom:legacy
     * @notice Set the upgrading status for the Chugsplash proxy type.
     *
     * @param _upgrading Whether or not the system is upgrading.
     */
    function setUpgrading(bool _upgrading) external onlyOwner {
        upgrading = _upgrading;
    }

    /**
     * @dev Returns the current implementation of `proxy`.
     *      This contract must be the admin of `proxy`.
     *
     * @param proxy The Proxy to return the implementation of.
     * @return The address of the implementation.
     */
    function getProxyImplementation(Proxy proxy) external view returns (address) {
        ProxyType proxyType = proxyType[address(proxy)];

        // We need to manually run the static call since the getter cannot be flagged as view
        address target;
        bytes memory data;
        if (proxyType == ProxyType.OpenZeppelin) {
            target = address(proxy);
            data = abi.encodeWithSelector(Proxy.implementation.selector);
        } else if (proxyType == ProxyType.Chugsplash) {
            target = address(proxy);
            data = abi.encodeWithSelector(L1ChugSplashProxy.getImplementation.selector);
        } else if (proxyType == ProxyType.ResolvedDelegate) {
            target = address(addressManager);
            data = abi.encodeWithSelector(
                Lib_AddressManager.getAddress.selector,
                implementationName[address(proxy)]
            );
        } else {
            revert("ProxyAdmin: unknown proxy type");
        }

        (bool success, bytes memory returndata) = target.staticcall(data);
        require(success);
        return abi.decode(returndata, (address));
    }

    /**
     * @dev Returns the current admin of `proxy`.
     *      This contract must be the admin of `proxy`.
     *
     * @param proxy The Proxy to return the admin of.
     * @return The address of the admin.
     */
    function getProxyAdmin(Proxy proxy) external view returns (address) {
        ProxyType proxyType = proxyType[address(proxy)];

        // We need to manually run the static call since the getter cannot be flagged as view
        address target;
        bytes memory data;
        if (proxyType == ProxyType.OpenZeppelin) {
            target = address(proxy);
            data = abi.encodeWithSelector(Proxy.admin.selector);
        } else if (proxyType == ProxyType.Chugsplash) {
            target = address(proxy);
            data = abi.encodeWithSelector(L1ChugSplashProxy.getOwner.selector);
        } else if (proxyType == ProxyType.ResolvedDelegate) {
            target = address(addressManager);
            data = abi.encodeWithSignature("owner()");
        } else {
            revert("ProxyAdmin: unknown proxy type");
        }

        (bool success, bytes memory returndata) = target.staticcall(data);
        require(success);
        return abi.decode(returndata, (address));
    }

    /**
     * @dev Changes the admin of `proxy` to `newAdmin`. This contract must be the current admin
     *      of `proxy`.
     *
     * @param proxy    The proxy that will have its admin updated.
     * @param newAdmin The address of the admin to update to.
     */
    function changeProxyAdmin(Proxy proxy, address newAdmin) external onlyOwner {
        ProxyType proxyType = proxyType[address(proxy)];

        if (proxyType == ProxyType.OpenZeppelin) {
            proxy.changeAdmin(newAdmin);
        } else if (proxyType == ProxyType.Chugsplash) {
            L1ChugSplashProxy(payable(proxy)).setOwner(newAdmin);
        } else if (proxyType == ProxyType.ResolvedDelegate) {
            Lib_AddressManager(addressManager).transferOwnership(newAdmin);
        }
    }

    /**
     * @dev Upgrades `proxy` to `implementation`. This contract must be the admin of `proxy`.
     *
     * @param proxy          The address of the proxy.
     * @param implementation The address of the implementation.
     */
    function upgrade(Proxy proxy, address implementation) public onlyOwner {
        ProxyType proxyType = proxyType[address(proxy)];

        if (proxyType == ProxyType.OpenZeppelin) {
            proxy.upgradeTo(implementation);
        } else if (proxyType == ProxyType.Chugsplash) {
            L1ChugSplashProxy(payable(proxy)).setStorage(
                0x360894a13ba1a3210667c828492db98dca3e2076cc3735a920a3ca505d382bbc,
                bytes32(uint256(uint160(implementation)))
            );
        } else if (proxyType == ProxyType.ResolvedDelegate) {
            string memory name = implementationName[address(proxy)];
            Lib_AddressManager(addressManager).setAddress(name, implementation);
        }
    }

    /**
     * @dev Upgrades `proxy` to `implementation` and calls a function on the new implementation.
     *      This contract must be the admin of `proxy`.
     *
     * @param proxy           The proxy to call.
     * @param implementation  The implementation to upgrade the proxy to.
     * @param data            The calldata to pass to the implementation.
     */
    function upgradeAndCall(
        Proxy proxy,
        address implementation,
        bytes memory data
    ) external payable onlyOwner {
        ProxyType proxyType = proxyType[address(proxy)];

        if (proxyType == ProxyType.OpenZeppelin) {
            proxy.upgradeToAndCall{ value: msg.value }(implementation, data);
        } else {
            upgrade(proxy, implementation);
            (bool success, ) = address(proxy).call{ value: msg.value }(data);
            require(success);
        }
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (access/Ownable.sol)

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
     * @dev Returns the address of the current owner.
     */
    function owner() public view virtual returns (address) {
        return _owner;
    }

    /**
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        require(owner() == _msgSender(), "Ownable: caller is not the owner");
        _;
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

// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity >=0.8.0;

/// @notice Simple single owner authorization mixin.
/// @author Solmate (https://github.com/Rari-Capital/solmate/blob/main/src/auth/Owned.sol)
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