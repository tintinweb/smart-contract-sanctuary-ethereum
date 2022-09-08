// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (proxy/utils/Initializable.sol)

pragma solidity ^0.8.0;

import "../../utils/AddressUpgradeable.sol";

/**
 * @dev This is a base contract to aid in writing upgradeable contracts, or any kind of contract that will be deployed
 * behind a proxy. Since a proxied contract can't have a constructor, it's common to move constructor logic to an
 * external initializer function, usually called `initialize`. It then becomes necessary to protect this initializer
 * function so it can only be called once. The {initializer} modifier provided by this contract will have this effect.
 *
 * TIP: To avoid leaving the proxy in an uninitialized state, the initializer function should be called as early as
 * possible by providing the encoded function call as the `_data` argument to {ERC1967Proxy-constructor}.
 *
 * CAUTION: When used with inheritance, manual care must be taken to not invoke a parent initializer twice, or to ensure
 * that all initializers are idempotent. This is not verified automatically as constructors are by Solidity.
 *
 * [CAUTION]
 * ====
 * Avoid leaving a contract uninitialized.
 *
 * An uninitialized contract can be taken over by an attacker. This applies to both a proxy and its implementation
 * contract, which may impact the proxy. To initialize the implementation contract, you can either invoke the
 * initializer manually, or you can include a constructor to automatically mark it as initialized when it is deployed:
 *
 * [.hljs-theme-light.nopadding]
 * ```
 * /// @custom:oz-upgrades-unsafe-allow constructor
 * constructor() initializer {}
 * ```
 * ====
 */
abstract contract Initializable {
    /**
     * @dev Indicates that the contract has been initialized.
     */
    bool private _initialized;

    /**
     * @dev Indicates that the contract is in the process of being initialized.
     */
    bool private _initializing;

    /**
     * @dev Modifier to protect an initializer function from being invoked twice.
     */
    modifier initializer() {
        // If the contract is initializing we ignore whether _initialized is set in order to support multiple
        // inheritance patterns, but we only do this in the context of a constructor, because in other contexts the
        // contract may have been reentered.
        require(_initializing ? _isConstructor() : !_initialized, "Initializable: contract is already initialized");

        bool isTopLevelCall = !_initializing;
        if (isTopLevelCall) {
            _initializing = true;
            _initialized = true;
        }

        _;

        if (isTopLevelCall) {
            _initializing = false;
        }
    }

    /**
     * @dev Modifier to protect an initialization function so that it can only be invoked by functions with the
     * {initializer} modifier, directly or indirectly.
     */
    modifier onlyInitializing() {
        require(_initializing, "Initializable: contract is not initializing");
        _;
    }

    function _isConstructor() private view returns (bool) {
        return !AddressUpgradeable.isContract(address(this));
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/Address.sol)

pragma solidity ^0.8.0;

/**
 * @dev Collection of functions related to the address type
 */
library AddressUpgradeable {
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
     */
    function isContract(address account) internal view returns (bool) {
        // This method relies on extcodesize, which returns 0 for contracts in
        // construction, since the code is only stored at the end of the
        // constructor execution.

        uint256 size;
        assembly {
            size := extcodesize(account)
        }
        return size > 0;
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
pragma solidity ^0.8.12;

interface IOpsProxyFactory {
    /**
     * @notice Emitted when an OpsProxy is deployed.
     *
     * @param deployer Address which initiated the deployment
     * @param owner The address which the proxy is for.
     * @param proxy Address of deployed proxy.
     */
    event DeployProxy(
        address indexed deployer,
        address indexed owner,
        address indexed proxy
    );

    /**
     * @notice Emitted when OpsProxy implementation to be deployed is changed.
     *
     * @param oldImplementation Previous OpsProxy implementation.
     * @param newImplementation Current OpsProxy implementation.
     */
    event SetImplementation(
        address indexed oldImplementation,
        address indexed newImplementation
    );

    /**
     * @notice Emitted when OpsProxy implementation is added or removed from whitelist.
     *
     * @param implementation OpsProxy implementation.
     * @param whitelisted Added or removed from whitelist.
     */
    event UpdateWhitelistedImplementation(
        address indexed implementation,
        bool indexed whitelisted
    );

    /**
     * @notice Deploys OpsProxy for the msg.sender.
     *
     * @return proxy Address of deployed proxy.
     */
    function deploy() external returns (address payable proxy);

    /**
     * @notice Deploys OpsProxy for another address.
     *
     * @param owner Address to deploy the proxy for.
     *
     * @return proxy Address of deployed proxy.
     */
    function deployFor(address owner) external returns (address payable proxy);

    /**
     * @notice Sets the OpsProxy implementation that will be deployed by OpsProxyFactory.
     *
     * @param newImplementation New implementation to be set.
     */
    function setImplementation(address newImplementation) external;

    /**
     * @notice Add or remove OpsProxy implementation from the whitelist.
     *
     * @param implementation OpsProxy implementation.
     * @param whitelist Added or removed from whitelist.
     */
    function updateWhitelistedImplementations(
        address implementation,
        bool whitelist
    ) external;

    /**
     * @notice Determines the OpsProxy address when it is not deployed.
     *
     * @param account Address to determine the proxy address for.
     */
    function determineProxyAddress(address account)
        external
        view
        returns (address);

    /**
     * @return address Proxy address owned by account.
     * @return bool Whether if proxy is deployed
     */
    function getProxyOf(address account) external view returns (address, bool);

    /**
     * @return address Owner of deployed proxy.
     */
    function ownerOf(address proxy) external view returns (address);

    /**
     * @return bool Whether if implementation is whitelisted.
     */
    function whitelistedImplementations(address implementation)
        external
        view
        returns (bool);
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.12;

import {
    Initializable
} from "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import {EIP173OpsProxy} from "../vendor/proxy/EIP173/EIP173OpsProxy.sol";
import {Proxied} from "../vendor/proxy/EIP173/Proxied.sol";
import {IOpsProxyFactory} from "../interfaces/IOpsProxyFactory.sol";

// solhint-disable max-states-count
contract OpsProxyFactory is Initializable, Proxied, IOpsProxyFactory {
    address public immutable ops;
    address public implementation;
    mapping(address => bool) public override whitelistedImplementations;

    ///@dev track proxy of user
    mapping(address => address) internal _proxyOf;

    ///@dev track owner of proxy
    mapping(address => address) internal _ownerOf;

    modifier onlyOneProxy(address _account) {
        require(_proxyOf[_account] == address(0), "OpsProxyFactory: One proxy");
        _;
    }

    modifier notProxy(address _account) {
        require(_ownerOf[_account] == address(0), "OpsProxyFactory: No proxy");
        _;
    }

    constructor(address _ops) {
        ops = _ops;
    }

    function initialize(address _implementation) external initializer {
        implementation = _implementation;
        whitelistedImplementations[_implementation] = true;
    }

    ///@inheritdoc IOpsProxyFactory
    function deploy() external override returns (address payable proxy) {
        proxy = deployFor(msg.sender);
    }

    function setImplementation(address _newImplementation)
        external
        onlyProxyAdmin
    {
        address oldImplementation = implementation;
        require(
            oldImplementation != _newImplementation &&
                whitelistedImplementations[_newImplementation],
            "OpsProxyFactory: Invalid implementation"
        );

        implementation = _newImplementation;

        emit SetImplementation(oldImplementation, _newImplementation);
    }

    function updateWhitelistedImplementations(
        address _implementation,
        bool _whitelist
    ) external onlyProxyAdmin {
        whitelistedImplementations[_implementation] = _whitelist;

        emit UpdateWhitelistedImplementation(_implementation, _whitelist);
    }

    ///@inheritdoc IOpsProxyFactory
    function getProxyOf(address _account)
        external
        view
        override
        returns (address, bool)
    {
        address proxyAddress = _proxyOf[_account];

        if (proxyAddress != address(0)) return (proxyAddress, true);

        proxyAddress = determineProxyAddress(_account);
        return (proxyAddress, false);
    }

    ///@inheritdoc IOpsProxyFactory
    function ownerOf(address _proxy) external view override returns (address) {
        return _ownerOf[_proxy];
    }

    ///@inheritdoc IOpsProxyFactory
    function deployFor(address owner)
        public
        override
        onlyOneProxy(owner)
        notProxy(owner)
        returns (address payable proxy)
    {
        proxy = _deploy(bytes32(0), _getBytecode(owner));

        _proxyOf[owner] = proxy;
        _ownerOf[proxy] = owner;

        emit DeployProxy(msg.sender, owner, address(proxy));
    }

    ///@inheritdoc IOpsProxyFactory
    function determineProxyAddress(address _account)
        public
        view
        override
        returns (address)
    {
        address proxyAddress = _proxyOf[_account];
        if (proxyAddress != address(0)) return proxyAddress;

        bytes memory bytecode = _getBytecode(_account);

        bytes32 codeHash = keccak256(
            abi.encodePacked(
                bytes1(0xff),
                address(this),
                bytes32(0),
                keccak256(bytecode)
            )
        );

        return address(uint160(uint256(codeHash)));
    }

    function _deploy(bytes32 _salt, bytes memory _bytecode)
        internal
        returns (address payable proxy)
    {
        assembly {
            let endowment := 0
            let bytecodeStart := add(_bytecode, 0x20)
            let bytecodeLength := mload(_bytecode)
            proxy := create2(endowment, bytecodeStart, bytecodeLength, _salt)
        }
    }

    function _getBytecode(address _owner) internal view returns (bytes memory) {
        return
            abi.encodePacked(
                type(EIP173OpsProxy).creationCode,
                abi.encode(address(this), implementation, _owner, bytes(""))
            );
    }
}

// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.12;

import "./Proxy.sol";
import {IOpsProxyFactory} from "../../../interfaces/IOpsProxyFactory.sol";

interface ERC165 {
    function supportsInterface(bytes4 id) external view returns (bool);
}

/**
 * @notice Proxy implementing EIP173 for ownership management.
 * @notice This is used for OpsProxy.
 *
 * @dev 1. custom receive can be set in implementation.
 * @dev 2. transferProxyAdmin removed.
 * @dev 3. implementation can only be set to those whitelisted on OpsProxyFactory.
 */
contract EIP173OpsProxy is Proxy {
    // ////////////////////////// STATES ///////////////////////////////////////////////////////////////////////
    IOpsProxyFactory public immutable opsProxyFactory;

    // ////////////////////////// EVENTS ///////////////////////////////////////////////////////////////////////

    event ProxyAdminTransferred(
        address indexed previousAdmin,
        address indexed newAdmin
    );

    // /////////////////////// MODIFIERS //////////////////////////////////////////////////////////////////////
    modifier onlyWhitelistedImplementation(address _implementation) {
        require(
            opsProxyFactory.whitelistedImplementations(_implementation),
            "Implementation not whitelisted"
        );
        _;
    }

    // /////////////////////// FALLBACKS //////////////////////////////////////////////////////////////////////
    receive() external payable override {
        _fallback();
    }

    // /////////////////////// CONSTRUCTOR //////////////////////////////////////////////////////////////////////

    constructor(
        address _opsProxyFactory,
        address implementationAddress,
        address adminAddress,
        bytes memory data
    ) payable {
        opsProxyFactory = IOpsProxyFactory(_opsProxyFactory);
        _setImplementation(implementationAddress, data);
        _setProxyAdmin(adminAddress);
    }

    // ///////////////////// EXTERNAL ///////////////////////////////////////////////////////////////////////////

    function proxyAdmin() external view returns (address) {
        return _proxyAdmin();
    }

    function supportsInterface(bytes4 id) external view returns (bool) {
        if (id == 0x01ffc9a7 || id == 0x7f5828d0) {
            return true;
        }
        if (id == 0xFFFFFFFF) {
            return false;
        }

        ERC165 implementation;
        // solhint-disable-next-line security/no-inline-assembly
        assembly {
            implementation := sload(
                0x360894a13ba1a3210667c828492db98dca3e2076cc3735a920a3ca505d382bbc
            )
        }

        // Technically this is not standard compliant as ERC-165 require 30,000 gas which that call cannot ensure
        // because it is itself inside `supportsInterface` that might only get 30,000 gas.
        // In practise this is unlikely to be an issue.
        try implementation.supportsInterface(id) returns (bool support) {
            return support;
        } catch {
            return false;
        }
    }

    function upgradeTo(address newImplementation)
        external
        onlyProxyAdmin
        onlyWhitelistedImplementation(newImplementation)
    {
        _setImplementation(newImplementation, "");
    }

    function upgradeToAndCall(address newImplementation, bytes calldata data)
        external
        payable
        onlyProxyAdmin
        onlyWhitelistedImplementation(newImplementation)
    {
        _setImplementation(newImplementation, data);
    }

    // /////////////////////// MODIFIERS ////////////////////////////////////////////////////////////////////////

    modifier onlyProxyAdmin() {
        require(msg.sender == _proxyAdmin(), "NOT_AUTHORIZED");
        _;
    }

    // ///////////////////////// INTERNAL //////////////////////////////////////////////////////////////////////

    function _proxyAdmin() internal view returns (address adminAddress) {
        // solhint-disable-next-line security/no-inline-assembly
        assembly {
            adminAddress := sload(
                0xb53127684a568b3173ae13b9f8a6016e243e63b6e8ee1178d6a717850b5d6103
            )
        }
    }

    function _setProxyAdmin(address newAdmin) internal {
        address previousAdmin = _proxyAdmin();
        // solhint-disable-next-line security/no-inline-assembly
        assembly {
            sstore(
                0xb53127684a568b3173ae13b9f8a6016e243e63b6e8ee1178d6a717850b5d6103,
                newAdmin
            )
        }
        emit ProxyAdminTransferred(previousAdmin, newAdmin);
    }
}

// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.12;

abstract contract Proxied {
    /// @notice to be used by initialisation / postUpgrade function so that only the proxy's admin can execute them
    /// It also allows these functions to be called inside a contructor
    /// even if the contract is meant to be used without proxy
    modifier proxied() {
        address proxyAdminAddress = _proxyAdmin();
        // With hardhat-deploy proxies
        // the proxyAdminAddress is zero only for the implementation contract
        // if the implementation contract want to be used as a standalone/immutable contract
        // it simply has to execute the `proxied` function
        // This ensure the proxyAdminAddress is never zero post deployment
        // And allow you to keep the same code for both proxied contract and immutable contract
        if (proxyAdminAddress == address(0)) {
            // ensure can not be called twice when used outside of proxy : no admin
            // solhint-disable-next-line security/no-inline-assembly
            assembly {
                sstore(
                    0xb53127684a568b3173ae13b9f8a6016e243e63b6e8ee1178d6a717850b5d6103,
                    0xFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF
                )
            }
        } else {
            require(msg.sender == proxyAdminAddress);
        }
        _;
    }

    modifier onlyProxyAdmin() {
        require(msg.sender == _proxyAdmin(), "NOT_AUTHORIZED");
        _;
    }

    function _proxyAdmin() internal view returns (address adminAddress) {
        // solhint-disable-next-line security/no-inline-assembly
        assembly {
            adminAddress := sload(
                0xb53127684a568b3173ae13b9f8a6016e243e63b6e8ee1178d6a717850b5d6103
            )
        }
    }
}

// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.12;

// EIP-1967
abstract contract Proxy {
    // /////////////////////// EVENTS ///////////////////////////////////////////////////////////////////////////

    event ProxyImplementationUpdated(
        address indexed previousImplementation,
        address indexed newImplementation
    );

    // ///////////////////// EXTERNAL ///////////////////////////////////////////////////////////////////////////

    // prettier-ignore
    receive() external payable virtual {
        revert("ETHER_REJECTED"); // explicit reject by default
    }

    fallback() external payable {
        _fallback();
    }

    // ///////////////////////// INTERNAL //////////////////////////////////////////////////////////////////////

    function _fallback() internal {
        // solhint-disable-next-line security/no-inline-assembly
        assembly {
            let implementationAddress := sload(
                0x360894a13ba1a3210667c828492db98dca3e2076cc3735a920a3ca505d382bbc
            )
            calldatacopy(0x0, 0x0, calldatasize())
            let success := delegatecall(
                gas(),
                implementationAddress,
                0x0,
                calldatasize(),
                0,
                0
            )
            let retSz := returndatasize()
            returndatacopy(0, 0, retSz)
            switch success
            case 0 {
                revert(0, retSz)
            }
            default {
                return(0, retSz)
            }
        }
    }

    function _setImplementation(address newImplementation, bytes memory data)
        internal
    {
        address previousImplementation;
        // solhint-disable-next-line security/no-inline-assembly
        assembly {
            previousImplementation := sload(
                0x360894a13ba1a3210667c828492db98dca3e2076cc3735a920a3ca505d382bbc
            )
        }

        // solhint-disable-next-line security/no-inline-assembly
        assembly {
            sstore(
                0x360894a13ba1a3210667c828492db98dca3e2076cc3735a920a3ca505d382bbc,
                newImplementation
            )
        }

        emit ProxyImplementationUpdated(
            previousImplementation,
            newImplementation
        );

        if (data.length > 0) {
            (bool success, ) = newImplementation.delegatecall(data);
            if (!success) {
                assembly {
                    // This assembly ensure the revert contains the exact string data
                    let returnDataSize := returndatasize()
                    returndatacopy(0, 0, returnDataSize)
                    revert(0, returnDataSize)
                }
            }
        }
    }
}