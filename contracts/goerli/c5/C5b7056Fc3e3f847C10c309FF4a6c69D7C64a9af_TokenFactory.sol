/**
 * @title TokenFactory
 * @author Team 3301 <[email protected]>
 * @dev Token factory to be used by operators to deploy arbitrary Sygnum Equity Token.
 */

pragma solidity 0.8.8;

import "@sygnum/solidity-base-contracts/contracts/helpers/Initializable.sol";
import "@sygnum/solidity-base-contracts/contracts/role/base/Operatorable.sol";

import "./ProxyDeployer.sol";
import "./TokenDeployer.sol";
import "./Details.sol";

contract TokenFactory is Initializable, Operatorable {
    address public whitelist;
    address public proxyAdmin;
    address public implementation;
    address public traderOperators;
    address public blockerOperators;

    error TokenFactoryEmptyBaseOperatorsAddress();
    error TokenFactoryEmptyTraderOperatorsAddress();
    error TokenFactoryEmptyBlockerOperatorsAddress();
    error TokenFactoryEmptyWhitelistAddress();
    error TokenFactoryEmptyImplementationAddress();
    error TokenFactoryEmptyProxyAdminAddress();
    error TokenFactoryCallerNotProxyAdmin();

    event UpdatedWhitelist(address indexed whitelist);
    event UpdatedTraderOperators(address indexed traderOperators);
    event UpdatedBlockerOperators(address indexed blockerOperators);
    event UpdatedProxyAdmin(address indexed proxyAdmin);
    event UpdatedImplementation(address indexed implementation);
    event NewTokenDeployed(address indexed issuer, address token, address proxy);

    /**
     * @dev Initialization instead of constructor, called once. Sets BaseOperators contract through pausable contract
     * resulting in use of Operatorable contract within this contract.
     * @param _baseOperators BaseOperators contract address.
     * @param _traderOperators TraderOperators contract address.
     * @param _blockerOperators BlockerOperators contract address.
     * @param _whitelist Whitelist contract address.
     */
    function initialize(
        address _baseOperators,
        address _traderOperators,
        address _blockerOperators,
        address _whitelist,
        address _implementation,
        address _proxyAdmin
    ) public virtual initializer {
        if (_baseOperators == address(0)) revert TokenFactoryEmptyBaseOperatorsAddress();
        if (_traderOperators == address(0)) revert TokenFactoryEmptyTraderOperatorsAddress();
        if (_blockerOperators == address(0)) revert TokenFactoryEmptyBlockerOperatorsAddress();
        if (_whitelist == address(0)) revert TokenFactoryEmptyWhitelistAddress();
        if (_implementation == address(0)) revert TokenFactoryEmptyImplementationAddress();
        if (_proxyAdmin == address(0)) revert TokenFactoryEmptyProxyAdminAddress();

        traderOperators = _traderOperators;
        blockerOperators = _blockerOperators;
        whitelist = _whitelist;
        proxyAdmin = _proxyAdmin;
        implementation = _implementation;

        super.initialize(_baseOperators);
    }

    /**
     * @dev allows operator, system or relay to launch a new token with a new name, symbol, decimals, category, and issuer.
     * Defaults to using whitelist stored in this contract. If _whitelist is address(0), else it will use
     * _whitelist as the param to pass into the new token's constructor upon deployment
     * @param _details token details as defined by the TokenDetails struct
     * @param _whitelist address
     */
    function newToken(Details.TokenDetails memory _details, address _whitelist)
        public
        virtual
        onlyOperatorOrSystemOrRelay
        returns (address, address)
    {
        address whitelistAddress;
        _whitelist == address(0) ? whitelistAddress = whitelist : whitelistAddress = _whitelist;
        address baseOperators = getOperatorsContract();

        address proxy = ProxyDeployer.deployTokenProxy(implementation, proxyAdmin, "");

        TokenDeployer.initializeToken(
            proxy,
            baseOperators,
            whitelistAddress,
            traderOperators,
            blockerOperators,
            _details
        );

        emit NewTokenDeployed(_details.issuer, implementation, proxy);
        return (implementation, proxy);
    }

    /**
     * @dev updates the whitelist to be used for future generated tokens
     * @param _whitelist address
     */
    function updateWhitelist(address _whitelist) public virtual onlyOperator {
        if (_whitelist == address(0)) revert TokenFactoryEmptyWhitelistAddress();
        whitelist = _whitelist;
        emit UpdatedWhitelist(whitelist);
    }

    /**
     * @dev updates the traderOperators contract address to be used for future generated tokens
     * @param _traderOperators address
     */
    function updateTraderOperators(address _traderOperators) public virtual onlyOperator {
        if (_traderOperators == address(0)) revert TokenFactoryEmptyTraderOperatorsAddress();
        traderOperators = _traderOperators;
        emit UpdatedTraderOperators(_traderOperators);
    }

    /**
     * @dev updates the blockerOperators contract address to be used for future generated tokens
     * @param _blockerOperators address
     */
    function updateBlockerOperators(address _blockerOperators) public virtual onlyOperator {
        if (_blockerOperators == address(0)) revert TokenFactoryEmptyBlockerOperatorsAddress();
        blockerOperators = _blockerOperators;
        emit UpdatedBlockerOperators(_blockerOperators);
    }

    /**
     * @dev update the implementation address used when deploying proxy contracts
     * @param _implementation address
     */
    function updateImplementation(address _implementation) public virtual onlyOperator {
        if (_implementation == address(0)) revert TokenFactoryEmptyImplementationAddress();
        implementation = _implementation;
        emit UpdatedImplementation(implementation);
    }

    /**
     * @dev update the proxy admin address used when deploying proxy contracts
     * @param _proxyAdmin address
     */
    function updateProxyAdmin(address _proxyAdmin) public virtual {
        if (_proxyAdmin == address(0)) revert TokenFactoryEmptyProxyAdminAddress();
        if (msg.sender != proxyAdmin) revert TokenFactoryCallerNotProxyAdmin();
        proxyAdmin = _proxyAdmin;
        emit UpdatedProxyAdmin(proxyAdmin);
    }
}

// SPDX-License-Identifier: UNLICENSED

/**
 * @title Initializable
 *
 * @dev Helper contract to support initializer functions. To use it, replace
 * the constructor with a function that has the `initializer` modifier.
 * WARNING: Unlike constructors, initializer functions must be manually
 * invoked. This applies both to deploying an Initializable contract, as well
 * as extending an Initializable contract via inheritance.
 * WARNING: When used with inheritance, manual care must be taken to not invoke
 * a parent initializer twice, or ensure that all initializers are idempotent,
 * because this is not dealt with automatically as with constructors.
 */

pragma solidity ^0.8.0;

contract Initializable {
    /**
     * @dev Indicates that the contract has been initialized.
     */
    bool private initialized;

    /**
     * @dev Indicates that the contract is in the process of being initialized.
     */
    bool private initializing;

    /**
     * @dev Error: "Initializable: Contract instance has already been initialized"
     */
    error InitializableContractAlreadyInitialized();

    /**
     * @dev Modifier to use in the initializer function of a contract.
     */
    modifier initializer() {
        if (!initializing && !isConstructor() && initialized) revert InitializableContractAlreadyInitialized();

        bool isTopLevelCall = !initializing;
        if (isTopLevelCall) {
            initializing = true;
            initialized = true;
        }

        _;

        if (isTopLevelCall) {
            initializing = false;
        }
    }

    /// @dev Returns true if and only if the function is running in the constructor
    function isConstructor() private view returns (bool) {
        // extcodesize checks the size of the code stored in an address, and
        // address returns the current address. Since the code is still not
        // deployed when running a constructor, any checks on its code size will
        // yield zero, making it an effective way to detect if a contract is
        // under construction or not.
        address self = address(this);
        uint256 cs;
        // solhint-disable-next-line no-inline-assembly
        assembly {
            cs := extcodesize(self)
        }
        return cs == 0;
    }

    function isInitialized() public view virtual returns (bool) {
        return initialized;
    }

    // Reserved storage space to allow for layout changes in the future.
    uint256[50] private ______gap;
}

/**
 * @title Operatorable
 * @author Team 3301 <[email protected]>
 * @dev Operatorable contract stores the BaseOperators contract address, and modifiers for
 *       contracts.
 */

pragma solidity 0.8.8;

import "../interface/IBaseOperators.sol";
import "../../helpers/Initializable.sol";

contract Operatorable is Initializable {
    IBaseOperators internal operatorsInst;
    address private operatorsPending;

    /**
     * @dev Error: "Operatorable: caller does not have the operator role"
     */
    error OperatorableCallerNotOperator();

    /**
     * @dev Error: "Operatorable: caller does not have the admin role"
     */
    error OperatorableCallerNotAdmin();

    /**
     * @dev Error: "Operatorable: caller does not have the system role"
     */
    error OperatorableCallerNotSystem();

    /**
     * @dev Error: "Operatorable: caller does not have the multisig role"
     */
    error OperatorableCallerNotMultisig();

    /**
     * @dev Error: "Operatorable: caller does not have the admin or system role"
     */
    error OperatorableCallerNotAdminOrSystem();

    /**
     * @dev Error: "Operatorable: caller does not have the operator role nor system"
     */
    error OperatorableCallerNotOperatorOrSystem();

    /**
     * @dev Error: "Operatorable: caller does not have the relay role"
     */
    error OperatorableCallerNotRelay();

    /**
     * @dev Error: "Operatorable: caller does not have the operator role nor relay"
     */
    error OperatorableCallerNotOperatorOrRelay();

    /**
     * @dev Error: "Operatorable: caller does not have the admin role nor relay"
     */
    error OperatorableCallerNotAdminOrRelay();

    /**
     * @dev Error: "Operatorable: caller does not have the operator role nor system nor relay"
     */
    error OperatorableCallerNotOperatorOrSystemOrRelay();

    /**
     * @dev Error: "OperatorableCallerNotOperator() nor admin nor relay"
     */
    error OperatorableCallerNotOperatorOrAdminOrRelay();

    /**
     * @dev Error: "Operatorable: address of new operators contract can not be zero"
     */
    error OperatorableNewOperatorsZeroAddress();

    /**
     * @dev Error: "Operatorable: should be called from new operators contract"
     */
    error OperatorableCallerNotOperatorsContract(address _caller);

    event OperatorsContractChanged(address indexed caller, address indexed operatorsAddress);
    event OperatorsContractPending(address indexed caller, address indexed operatorsAddress);

    /**
     * @dev Reverts if sender does not have operator role associated.
     */
    modifier onlyOperator() {
        if (!isOperator(msg.sender)) revert OperatorableCallerNotOperator();
        _;
    }

    /**
     * @dev Reverts if sender does not have admin role associated.
     */
    modifier onlyAdmin() {
        if (!isAdmin(msg.sender)) revert OperatorableCallerNotAdmin();
        _;
    }

    /**
     * @dev Reverts if sender does not have system role associated.
     */
    modifier onlySystem() {
        if (!isSystem(msg.sender)) revert OperatorableCallerNotSystem();
        _;
    }

    /**
     * @dev Reverts if sender does not have multisig privileges.
     */
    modifier onlyMultisig() {
        if (!isMultisig(msg.sender)) revert OperatorableCallerNotMultisig();
        _;
    }

    /**
     * @dev Reverts if sender does not have admin or system role associated.
     */
    modifier onlyAdminOrSystem() {
        if (!isAdminOrSystem(msg.sender)) revert OperatorableCallerNotAdminOrSystem();
        _;
    }

    /**
     * @dev Reverts if sender does not have operator or system role associated.
     */
    modifier onlyOperatorOrSystem() {
        if (!isOperatorOrSystem(msg.sender)) revert OperatorableCallerNotOperatorOrSystem();
        _;
    }

    /**
     * @dev Reverts if sender does not have the relay role associated.
     */
    modifier onlyRelay() {
        if (!isRelay(msg.sender)) revert OperatorableCallerNotRelay();
        _;
    }

    /**
     * @dev Reverts if sender does not have relay or operator role associated.
     */
    modifier onlyOperatorOrRelay() {
        if (!isOperator(msg.sender) && !isRelay(msg.sender)) revert OperatorableCallerNotOperatorOrRelay();
        _;
    }

    /**
     * @dev Reverts if sender does not have relay or admin role associated.
     */
    modifier onlyAdminOrRelay() {
        if (!isAdmin(msg.sender) && !isRelay(msg.sender)) revert OperatorableCallerNotAdminOrRelay();
        _;
    }

    /**
     * @dev Reverts if sender does not have the operator, or system, or relay role associated.
     */
    modifier onlyOperatorOrSystemOrRelay() {
        if (!isOperator(msg.sender) && !isSystem(msg.sender) && !isRelay(msg.sender))
            revert OperatorableCallerNotOperatorOrSystemOrRelay();
        _;
    }

    /**
     * @dev Reverts if sender does not have the operator, or admin, or relay role associated.
     */
    modifier onlyOperatorOrAdminOrRelay() {
        if (!isOperator(msg.sender) && !isAdmin(msg.sender) && !isRelay(msg.sender))
            revert OperatorableCallerNotOperatorOrAdminOrRelay();
        _;
    }

    /**
     * @dev Initialization instead of constructor, called once. The setOperatorsContract function can be called only by Admin role with
     *       confirmation through the operators contract.
     * @param _baseOperators BaseOperators contract address.
     */
    function initialize(address _baseOperators) public virtual initializer {
        _setOperatorsContract(_baseOperators);
    }

    /**
     * @dev Set the new the address of Operators contract, should be confirmed from operators contract by calling confirmFor(addr)
     *       where addr is the address of current contract instance. This is done to prevent the case when the new contract address is
     *       broken and control of the contract can be lost in such case
     * @param _baseOperators BaseOperators contract address.
     */
    function setOperatorsContract(address _baseOperators) public onlyAdmin {
        if (_baseOperators == address(0)) revert OperatorableNewOperatorsZeroAddress();

        operatorsPending = _baseOperators;
        emit OperatorsContractPending(msg.sender, _baseOperators);
    }

    /**
     * @dev The function should be called from new operators contract by admin to ensure that operatorsPending address
     *       is the real contract address.
     */
    function confirmOperatorsContract() public {
        if (operatorsPending == address(0)) revert OperatorableNewOperatorsZeroAddress();

        if (msg.sender != operatorsPending) revert OperatorableCallerNotOperatorsContract(msg.sender);

        _setOperatorsContract(operatorsPending);
    }

    /**
     * @return The address of the BaseOperators contract.
     */
    function getOperatorsContract() public view returns (address) {
        return address(operatorsInst);
    }

    /**
     * @return The pending address of the BaseOperators contract.
     */
    function getOperatorsPending() public view returns (address) {
        return operatorsPending;
    }

    /**
     * @return If '_account' has operator privileges.
     */
    function isOperator(address _account) public view returns (bool) {
        return operatorsInst.isOperator(_account);
    }

    /**
     * @return If '_account' has admin privileges.
     */
    function isAdmin(address _account) public view returns (bool) {
        return operatorsInst.isAdmin(_account);
    }

    /**
     * @return If '_account' has system privileges.
     */
    function isSystem(address _account) public view returns (bool) {
        return operatorsInst.isSystem(_account);
    }

    /**
     * @return If '_account' has relay privileges.
     */
    function isRelay(address _account) public view returns (bool) {
        return operatorsInst.isRelay(_account);
    }

    /**
     * @return If '_contract' has multisig privileges.
     */
    function isMultisig(address _contract) public view returns (bool) {
        return operatorsInst.isMultisig(_contract);
    }

    /**
     * @return If '_account' has admin or system privileges.
     */
    function isAdminOrSystem(address _account) public view returns (bool) {
        return (operatorsInst.isAdmin(_account) || operatorsInst.isSystem(_account));
    }

    /**
     * @return If '_account' has operator or system privileges.
     */
    function isOperatorOrSystem(address _account) public view returns (bool) {
        return (operatorsInst.isOperator(_account) || operatorsInst.isSystem(_account));
    }

    /** INTERNAL FUNCTIONS */
    function _setOperatorsContract(address _baseOperators) internal {
        if (_baseOperators == address(0)) revert OperatorableNewOperatorsZeroAddress();

        operatorsInst = IBaseOperators(_baseOperators);
        emit OperatorsContractChanged(msg.sender, _baseOperators);
    }
}

/**
 * @title ProxyDeployer
 * @author Team 3301 <[email protected]>
 * @dev Library to deploy a proxy instance for a Sygnum.
 */

pragma solidity 0.8.8;

import "../token/SygnumTokenProxy.sol";

library ProxyDeployer {
    /**
     * @dev Deploy the proxy instance and initialize it
     * @param _tokenImplementation Address of the logic contract
     * @param _proxyAdmin Address of the admin for the proxy
     * @param _data Bytecode needed for initialization
     * @return address New instance address
     */
    function deployTokenProxy(
        address _tokenImplementation,
        address _proxyAdmin,
        bytes memory _data
    ) public returns (address) {
        SygnumTokenProxy proxy = new SygnumTokenProxy(_tokenImplementation, _proxyAdmin, _data);
        return address(proxy);
    }
}

/**
 * @title TokenDeployer
 * @author Team 3301 <[email protected]>
 * @dev Library to deploy and initialize a new instance of Sygnum Equity Token.
 * This is commonly used by a TokenFactory to automatically deploy and configure
 */

pragma solidity 0.8.8;

import "../token/SygnumToken.sol";
import "../token/upgrade/prd/SygnumTokenV3.sol";
import "./Details.sol";

library TokenDeployer {
    /**
     * @dev Initialize a token contracts.
     * @param _proxy Address of the proxy
     * @param _baseOperators Address of the base operator role contract
     * @param _whitelist Address of the whitelist contract
     * @param _traderOperators Address of the trader operator role contract
     * @param _blockerOperators Address of the blocker operator role contract
     * @param _details token details as defined by the TokenDetails struct
     */
    function initializeToken(
        address _proxy,
        address _baseOperators,
        address _whitelist,
        address _traderOperators,
        address _blockerOperators,
        Details.TokenDetails memory _details
    ) public {
        SygnumTokenV3(_proxy).initializeContractsAndConstructor(
            _details.name,
            _details.symbol,
            _details.decimals,
            _details.category,
            _details.class,
            _details.issuer,
            _baseOperators,
            _whitelist,
            _traderOperators,
            _blockerOperators,
            _details.tokenURI
        );
    }
}

/**
 * @title Details
 * @author Team 3301 <[email protected]>
 * @notice Shared library for Sygnum token details struct.
 */

pragma solidity 0.8.8;

library Details {
    struct TokenDetails {
        string name;
        string symbol;
        uint8 decimals;
        bytes4 category;
        string class;
        address issuer;
        string tokenURI;
    }
}

/**
 * @title IBaseOperators
 * @notice Interface for BaseOperators contract
 */

pragma solidity ^0.8.0;

interface IBaseOperators {
    function isOperator(address _account) external view returns (bool);

    function isAdmin(address _account) external view returns (bool);

    function isSystem(address _account) external view returns (bool);

    function isRelay(address _account) external view returns (bool);

    function isMultisig(address _contract) external view returns (bool);

    function confirmFor(address _address) external;

    function addOperator(address _account) external;

    function removeOperator(address _account) external;

    function addAdmin(address _account) external;

    function removeAdmin(address _account) external;

    function addSystem(address _account) external;

    function removeSystem(address _account) external;

    function addRelay(address _account) external;

    function removeRelay(address _account) external;

    function addOperatorAndAdmin(address _account) external;

    function removeOperatorAndAdmin(address _account) external;
}

/**
 * @title SygnumTokenProxy
 * @author Team 3301 <[email protected]>
 * @dev Proxies SygnumToken calls and enables SygnumToken upgradability.
 */
pragma solidity 0.8.8;

import "@openzeppelin/contracts/proxy/transparent/TransparentUpgradeableProxy.sol";

contract SygnumTokenProxy is TransparentUpgradeableProxy {
    /* solhint-disable no-empty-blocks */
    constructor(
        address implementation,
        address proxyOwnerAddr,
        bytes memory data
    ) TransparentUpgradeableProxy(implementation, proxyOwnerAddr, data) {}
    /* solhint-enable no-empty-blocks */
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (proxy/transparent/TransparentUpgradeableProxy.sol)

pragma solidity ^0.8.0;

import "../ERC1967/ERC1967Proxy.sol";

/**
 * @dev This contract implements a proxy that is upgradeable by an admin.
 *
 * To avoid https://medium.com/nomic-labs-blog/malicious-backdoors-in-ethereum-proxies-62629adf3357[proxy selector
 * clashing], which can potentially be used in an attack, this contract uses the
 * https://blog.openzeppelin.com/the-transparent-proxy-pattern/[transparent proxy pattern]. This pattern implies two
 * things that go hand in hand:
 *
 * 1. If any account other than the admin calls the proxy, the call will be forwarded to the implementation, even if
 * that call matches one of the admin functions exposed by the proxy itself.
 * 2. If the admin calls the proxy, it can access the admin functions, but its calls will never be forwarded to the
 * implementation. If the admin tries to call a function on the implementation it will fail with an error that says
 * "admin cannot fallback to proxy target".
 *
 * These properties mean that the admin account can only be used for admin actions like upgrading the proxy or changing
 * the admin, so it's best if it's a dedicated account that is not used for anything else. This will avoid headaches due
 * to sudden errors when trying to call a function from the proxy implementation.
 *
 * Our recommendation is for the dedicated account to be an instance of the {ProxyAdmin} contract. If set up this way,
 * you should think of the `ProxyAdmin` instance as the real administrative interface of your proxy.
 */
contract TransparentUpgradeableProxy is ERC1967Proxy {
    /**
     * @dev Initializes an upgradeable proxy managed by `_admin`, backed by the implementation at `_logic`, and
     * optionally initialized with `_data` as explained in {ERC1967Proxy-constructor}.
     */
    constructor(
        address _logic,
        address admin_,
        bytes memory _data
    ) payable ERC1967Proxy(_logic, _data) {
        _changeAdmin(admin_);
    }

    /**
     * @dev Modifier used internally that will delegate the call to the implementation unless the sender is the admin.
     */
    modifier ifAdmin() {
        if (msg.sender == _getAdmin()) {
            _;
        } else {
            _fallback();
        }
    }

    /**
     * @dev Returns the current admin.
     *
     * NOTE: Only the admin can call this function. See {ProxyAdmin-getProxyAdmin}.
     *
     * TIP: To get this value clients can read directly from the storage slot shown below (specified by EIP1967) using the
     * https://eth.wiki/json-rpc/API#eth_getstorageat[`eth_getStorageAt`] RPC call.
     * `0xb53127684a568b3173ae13b9f8a6016e243e63b6e8ee1178d6a717850b5d6103`
     */
    function admin() external ifAdmin returns (address admin_) {
        admin_ = _getAdmin();
    }

    /**
     * @dev Returns the current implementation.
     *
     * NOTE: Only the admin can call this function. See {ProxyAdmin-getProxyImplementation}.
     *
     * TIP: To get this value clients can read directly from the storage slot shown below (specified by EIP1967) using the
     * https://eth.wiki/json-rpc/API#eth_getstorageat[`eth_getStorageAt`] RPC call.
     * `0x360894a13ba1a3210667c828492db98dca3e2076cc3735a920a3ca505d382bbc`
     */
    function implementation() external ifAdmin returns (address implementation_) {
        implementation_ = _implementation();
    }

    /**
     * @dev Changes the admin of the proxy.
     *
     * Emits an {AdminChanged} event.
     *
     * NOTE: Only the admin can call this function. See {ProxyAdmin-changeProxyAdmin}.
     */
    function changeAdmin(address newAdmin) external virtual ifAdmin {
        _changeAdmin(newAdmin);
    }

    /**
     * @dev Upgrade the implementation of the proxy.
     *
     * NOTE: Only the admin can call this function. See {ProxyAdmin-upgrade}.
     */
    function upgradeTo(address newImplementation) external ifAdmin {
        _upgradeToAndCall(newImplementation, bytes(""), false);
    }

    /**
     * @dev Upgrade the implementation of the proxy, and then call a function from the new implementation as specified
     * by `data`, which should be an encoded function call. This is useful to initialize new storage variables in the
     * proxied contract.
     *
     * NOTE: Only the admin can call this function. See {ProxyAdmin-upgradeAndCall}.
     */
    function upgradeToAndCall(address newImplementation, bytes calldata data) external payable ifAdmin {
        _upgradeToAndCall(newImplementation, data, true);
    }

    /**
     * @dev Returns the current admin.
     */
    function _admin() internal view virtual returns (address) {
        return _getAdmin();
    }

    /**
     * @dev Makes sure the admin cannot access the fallback function. See {Proxy-_beforeFallback}.
     */
    function _beforeFallback() internal virtual override {
        require(msg.sender != _getAdmin(), "TransparentUpgradeableProxy: admin cannot fallback to proxy target");
        super._beforeFallback();
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (proxy/ERC1967/ERC1967Proxy.sol)

pragma solidity ^0.8.0;

import "../Proxy.sol";
import "./ERC1967Upgrade.sol";

/**
 * @dev This contract implements an upgradeable proxy. It is upgradeable because calls are delegated to an
 * implementation address that can be changed. This address is stored in storage in the location specified by
 * https://eips.ethereum.org/EIPS/eip-1967[EIP1967], so that it doesn't conflict with the storage layout of the
 * implementation behind the proxy.
 */
contract ERC1967Proxy is Proxy, ERC1967Upgrade {
    /**
     * @dev Initializes the upgradeable proxy with an initial implementation specified by `_logic`.
     *
     * If `_data` is nonempty, it's used as data in a delegate call to `_logic`. This will typically be an encoded
     * function call, and allows initializing the storage of the proxy like a Solidity constructor.
     */
    constructor(address _logic, bytes memory _data) payable {
        _upgradeToAndCall(_logic, _data, false);
    }

    /**
     * @dev Returns the current implementation address.
     */
    function _implementation() internal view virtual override returns (address impl) {
        return ERC1967Upgrade._getImplementation();
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.6.0) (proxy/Proxy.sol)

pragma solidity ^0.8.0;

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
        assembly {
            // Copy msg.data. We take full control of memory in this inline assembly
            // block because it will not return to Solidity code. We overwrite the
            // Solidity scratch pad at memory position 0.
            calldatacopy(0, 0, calldatasize())

            // Call the implementation.
            // out and outsize are 0 because we don't know the size yet.
            let result := delegatecall(gas(), implementation, 0, calldatasize(), 0, 0)

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
     * @dev This is a virtual function that should be overridden so it returns the address to which the fallback function
     * and {_fallback} should delegate.
     */
    function _implementation() internal view virtual returns (address);

    /**
     * @dev Delegates the current call to the address returned by `_implementation()`.
     *
     * This function does not return to its internal call site, it will return directly to the external caller.
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
     * If overridden should call `super._beforeFallback()`.
     */
    function _beforeFallback() internal virtual {}
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.5.0) (proxy/ERC1967/ERC1967Upgrade.sol)

pragma solidity ^0.8.2;

import "../beacon/IBeacon.sol";
import "../../interfaces/draft-IERC1822.sol";
import "../../utils/Address.sol";
import "../../utils/StorageSlot.sol";

/**
 * @dev This abstract contract provides getters and event emitting update functions for
 * https://eips.ethereum.org/EIPS/eip-1967[EIP1967] slots.
 *
 * _Available since v4.1._
 *
 * @custom:oz-upgrades-unsafe-allow delegatecall
 */
abstract contract ERC1967Upgrade {
    // This is the keccak-256 hash of "eip1967.proxy.rollback" subtracted by 1
    bytes32 private constant _ROLLBACK_SLOT = 0x4910fdfa16fed3260ed0e7147f7cc6da11a60208b5b9406d12a635614ffd9143;

    /**
     * @dev Storage slot with the address of the current implementation.
     * This is the keccak-256 hash of "eip1967.proxy.implementation" subtracted by 1, and is
     * validated in the constructor.
     */
    bytes32 internal constant _IMPLEMENTATION_SLOT = 0x360894a13ba1a3210667c828492db98dca3e2076cc3735a920a3ca505d382bbc;

    /**
     * @dev Emitted when the implementation is upgraded.
     */
    event Upgraded(address indexed implementation);

    /**
     * @dev Returns the current implementation address.
     */
    function _getImplementation() internal view returns (address) {
        return StorageSlot.getAddressSlot(_IMPLEMENTATION_SLOT).value;
    }

    /**
     * @dev Stores a new address in the EIP1967 implementation slot.
     */
    function _setImplementation(address newImplementation) private {
        require(Address.isContract(newImplementation), "ERC1967: new implementation is not a contract");
        StorageSlot.getAddressSlot(_IMPLEMENTATION_SLOT).value = newImplementation;
    }

    /**
     * @dev Perform implementation upgrade
     *
     * Emits an {Upgraded} event.
     */
    function _upgradeTo(address newImplementation) internal {
        _setImplementation(newImplementation);
        emit Upgraded(newImplementation);
    }

    /**
     * @dev Perform implementation upgrade with additional setup call.
     *
     * Emits an {Upgraded} event.
     */
    function _upgradeToAndCall(
        address newImplementation,
        bytes memory data,
        bool forceCall
    ) internal {
        _upgradeTo(newImplementation);
        if (data.length > 0 || forceCall) {
            Address.functionDelegateCall(newImplementation, data);
        }
    }

    /**
     * @dev Perform implementation upgrade with security checks for UUPS proxies, and additional setup call.
     *
     * Emits an {Upgraded} event.
     */
    function _upgradeToAndCallUUPS(
        address newImplementation,
        bytes memory data,
        bool forceCall
    ) internal {
        // Upgrades from old implementations will perform a rollback test. This test requires the new
        // implementation to upgrade back to the old, non-ERC1822 compliant, implementation. Removing
        // this special case will break upgrade paths from old UUPS implementation to new ones.
        if (StorageSlot.getBooleanSlot(_ROLLBACK_SLOT).value) {
            _setImplementation(newImplementation);
        } else {
            try IERC1822Proxiable(newImplementation).proxiableUUID() returns (bytes32 slot) {
                require(slot == _IMPLEMENTATION_SLOT, "ERC1967Upgrade: unsupported proxiableUUID");
            } catch {
                revert("ERC1967Upgrade: new implementation is not UUPS");
            }
            _upgradeToAndCall(newImplementation, data, forceCall);
        }
    }

    /**
     * @dev Storage slot with the admin of the contract.
     * This is the keccak-256 hash of "eip1967.proxy.admin" subtracted by 1, and is
     * validated in the constructor.
     */
    bytes32 internal constant _ADMIN_SLOT = 0xb53127684a568b3173ae13b9f8a6016e243e63b6e8ee1178d6a717850b5d6103;

    /**
     * @dev Emitted when the admin account has changed.
     */
    event AdminChanged(address previousAdmin, address newAdmin);

    /**
     * @dev Returns the current admin.
     */
    function _getAdmin() internal view returns (address) {
        return StorageSlot.getAddressSlot(_ADMIN_SLOT).value;
    }

    /**
     * @dev Stores a new address in the EIP1967 admin slot.
     */
    function _setAdmin(address newAdmin) private {
        require(newAdmin != address(0), "ERC1967: new admin is the zero address");
        StorageSlot.getAddressSlot(_ADMIN_SLOT).value = newAdmin;
    }

    /**
     * @dev Changes the admin of the proxy.
     *
     * Emits an {AdminChanged} event.
     */
    function _changeAdmin(address newAdmin) internal {
        emit AdminChanged(_getAdmin(), newAdmin);
        _setAdmin(newAdmin);
    }

    /**
     * @dev The storage slot of the UpgradeableBeacon contract which defines the implementation for this proxy.
     * This is bytes32(uint256(keccak256('eip1967.proxy.beacon')) - 1)) and is validated in the constructor.
     */
    bytes32 internal constant _BEACON_SLOT = 0xa3f0ad74e5423aebfd80d3ef4346578335a9a72aeaee59ff6cb3582b35133d50;

    /**
     * @dev Emitted when the beacon is upgraded.
     */
    event BeaconUpgraded(address indexed beacon);

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
        require(Address.isContract(newBeacon), "ERC1967: new beacon is not a contract");
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
        emit BeaconUpgraded(newBeacon);
        if (data.length > 0 || forceCall) {
            Address.functionDelegateCall(IBeacon(newBeacon).implementation(), data);
        }
    }
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
// OpenZeppelin Contracts (last updated v4.5.0) (interfaces/draft-IERC1822.sol)

pragma solidity ^0.8.0;

/**
 * @dev ERC1822: Universal Upgradeable Proxy Standard (UUPS) documents a method for upgradeability through a simplified
 * proxy whose upgrades are fully controlled by the current implementation.
 */
interface IERC1822Proxiable {
    /**
     * @dev Returns the storage slot that the proxiable contract assumes is being used to store the implementation
     * address.
     *
     * IMPORTANT: A proxy pointing at a proxiable contract should not be considered proxiable itself, because this risks
     * bricking a proxy that upgrades to it, by delegating to itself until out of gas. Thus it is critical that this
     * function revert if invoked through a proxy.
     */
    function proxiableUUID() external view returns (bytes32);
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

/**
 * @title SygnumToken
 * @author Team 3301 <[email protected]>
 * @notice ERC20 token with additional features.
 */

pragma solidity 0.8.8;

import "./ERC20/ERC20SygnumDetailed.sol";
import "@sygnum/solidity-base-contracts/contracts/helpers/ERC20/ERC20Whitelist.sol";
import "@sygnum/solidity-base-contracts/contracts/helpers/ERC20/ERC20Pausable.sol";
import "@sygnum/solidity-base-contracts/contracts/helpers/ERC20/ERC20Mintable.sol";
import "@sygnum/solidity-base-contracts/contracts/helpers/ERC20/ERC20Burnable.sol";
import "@sygnum/solidity-base-contracts/contracts/helpers/ERC20/ERC20Freezable.sol";
import "@sygnum/solidity-base-contracts/contracts/helpers/ERC20/ERC20Destroyable.sol";
import "@sygnum/solidity-base-contracts/contracts/helpers/ERC20/ERC20Snapshot.sol";
import "@sygnum/solidity-base-contracts/contracts/helpers/ERC20/ERC20Tradeable.sol";
import "@sygnum/solidity-base-contracts/contracts/helpers/ERC20/ERC20Blockable.sol";

contract SygnumToken is
    ERC20Snapshot,
    ERC20SygnumDetailed,
    ERC20Pausable,
    ERC20Mintable,
    ERC20Whitelist,
    ERC20Tradeable,
    ERC20Blockable,
    ERC20Burnable,
    ERC20Freezable,
    ERC20Destroyable
{
    /**
     * @dev Error: "SygnumToken: Account must not be frozen."
     */
    error SygnumTokenAccountFrozen(address _account);

    /**
     * @dev Error: "SygnumToken: Account must not be frozen if system calling."
     */
    error SygnumTokenSystemCallAccountFrozen(address _account);

    /**
     * @dev Error: "SygnumToken: values and recipients are not equal."
     */
    error SygnumTokenUnequalArrayLengths();

    /**
     * @dev Error: "SygnumToken: batch count is greater than BATCH_LIMIT."
     */
    error SygnumTokenBatchCountExceedsLimit();

    /**
     * @dev Error: "SygnumToken: initialize() disabled"
     */
    error SygnumTokenDisabledInitialize();

    event Minted(address indexed minter, address indexed account, uint256 value);
    event Burned(address indexed burner, uint256 value);
    event BurnedFor(address indexed burner, address indexed account, uint256 value);
    event Confiscated(address indexed account, uint256 amount, address indexed receiver);

    uint16 internal constant BATCH_LIMIT = 256;

    /**
     * @dev Initializer obligatorily overriding the initializer() functions
     *     of the base contracts. For the moment, just used to disable
     *     inherited functions.
     */
    function initialize(address, address)
        public
        virtual
        override(BlockerOperatorable, TraderOperatorable, Whitelistable)
    {
        revert SygnumTokenDisabledInitialize();
    }

    /**
     * @dev Initialize contracts.
     * @param _baseOperators Base operators contract address.
     * @param _whitelist Whitelist contract address.
     * @param _traderOperators Trader operators contract address.
     * @param _blockerOperators Blocker operators contract address.
     */
    function initializeContractsAndConstructor(
        string memory _name,
        string memory _symbol,
        uint8 _decimals,
        bytes4 _category,
        string memory _class,
        address _issuer,
        address _baseOperators,
        address _whitelist,
        address _traderOperators,
        address _blockerOperators
    ) public virtual initializer {
        super.initialize(_baseOperators);
        _setWhitelistContract(_whitelist);
        _setTraderOperatorsContract(_traderOperators);
        _setBlockerOperatorsContract(_blockerOperators);
        _setDetails(_name, _symbol, _decimals, _category, _class, _issuer);
    }

    /**
     * @dev Burn.
     * @param _amount Amount of tokens to burn.
     */
    function burn(uint256 _amount) public virtual {
        if (isFrozen(msg.sender)) revert SygnumTokenAccountFrozen(msg.sender);
        _burn(msg.sender, _amount);
        emit Burned(msg.sender, _amount);
    }

    /**
     * @dev BurnFor.
     * @param _account Address to burn tokens for.
     * @param _amount Amount of tokens to burn.
     */
    function burnFor(address _account, uint256 _amount) public virtual {
        _burnFor(_account, _amount);
        emit BurnedFor(msg.sender, _account, _amount);
    }

    /**
     * @dev BurnFrom.
     * @param _account Address to burn tokens from.
     * @param _amount Amount of tokens to burn.
     */
    function burnFrom(address _account, uint256 _amount) public virtual {
        _burnFrom(_account, _amount);
        emit Burned(_account, _amount);
    }

    /**
     * @dev Mint.
     * @param _account Address to mint tokens to.
     * @param _amount Amount to mint.
     */
    function mint(address _account, uint256 _amount) public virtual {
        if (isSystem(msg.sender)) {
            if (isFrozen(_account)) revert SygnumTokenSystemCallAccountFrozen(_account);
        }
        _mint(_account, _amount);
        emit Minted(msg.sender, _account, _amount);
    }

    /**
     * @dev Confiscate.
     * @param _confiscatee Account to confiscate funds from.
     * @param _receiver Account to transfer confiscated funds to.
     * @param _amount Amount of tokens to confiscate.
     */
    function confiscate(
        address _confiscatee,
        address _receiver,
        uint256 _amount
    ) public virtual onlyOperator whenNotPaused whenWhitelisted(_receiver) whenWhitelisted(_confiscatee) {
        _confiscate(_confiscatee, _receiver, _amount);
        emit Confiscated(_confiscatee, _amount, _receiver);
    }

    /**
     * @dev Batch burn for.
     * @param _amounts Array of all values to burn.
     * @param _accounts Array of all addresses to burn from.
     */
    function batchBurnFor(address[] memory _accounts, uint256[] memory _amounts) public virtual {
        if (_accounts.length != _amounts.length) revert SygnumTokenUnequalArrayLengths();
        if (_accounts.length > BATCH_LIMIT) revert SygnumTokenBatchCountExceedsLimit();

        for (uint256 i = 0; i < _accounts.length; ++i) {
            burnFor(_accounts[i], _amounts[i]);
        }
    }

    /**
     * @dev Batch mint.
     * @param _accounts Array of all addresses to mint to.
     * @param _amounts Array of all values to mint.
     */
    function batchMint(address[] memory _accounts, uint256[] memory _amounts) public virtual {
        if (_accounts.length != _amounts.length) revert SygnumTokenUnequalArrayLengths();
        if (_accounts.length > BATCH_LIMIT) revert SygnumTokenBatchCountExceedsLimit();

        for (uint256 i = 0; i < _accounts.length; ++i) {
            mint(_accounts[i], _amounts[i]);
        }
    }

    /**
     * @dev Batch confiscate to a maximum of 256 addresses.
     * @param _confiscatees array of addresses whose funds are being confiscated
     * @param _receivers array of addresses who's receiving the funds
     * @param _values array of values of funds being confiscated
     */
    function batchConfiscate(
        address[] memory _confiscatees,
        address[] memory _receivers,
        uint256[] memory _values
    ) public virtual {
        if (_confiscatees.length != _values.length || _receivers.length != _values.length)
            revert SygnumTokenUnequalArrayLengths();
        if (_confiscatees.length > BATCH_LIMIT) revert SygnumTokenBatchCountExceedsLimit();

        for (uint256 i = 0; i < _confiscatees.length; ++i) {
            confiscate(_confiscatees[i], _receivers[i], _values[i]);
        }
    }

    // FORCE OVERRIDE FUNCTIONS

    function transferFrom(
        address from,
        address to,
        uint256 value
    ) public virtual override(ERC20, ERC20Freezable, ERC20Pausable, ERC20Snapshot, ERC20Whitelist) returns (bool) {
        return super.transferFrom(from, to, value);
    }

    function transfer(address to, uint256 value)
        public
        virtual
        override(ERC20, ERC20Freezable, ERC20Pausable, ERC20Snapshot, ERC20Whitelist)
        returns (bool)
    {
        return super.transfer(to, value);
    }

    function increaseAllowance(address spender, uint256 addedValue)
        public
        virtual
        override(ERC20, ERC20Freezable, ERC20Pausable, ERC20Whitelist)
        returns (bool)
    {
        return super.increaseAllowance(spender, addedValue);
    }

    function decreaseAllowance(address spender, uint256 subtractedValue)
        public
        virtual
        override(ERC20, ERC20Freezable, ERC20Pausable, ERC20Whitelist)
        returns (bool)
    {
        return super.decreaseAllowance(spender, subtractedValue);
    }

    function approve(address spender, uint256 value)
        public
        virtual
        override(ERC20, ERC20Freezable, ERC20Pausable, ERC20Whitelist)
        returns (bool)
    {
        return super.approve(spender, value);
    }

    function _burn(address account, uint256 value)
        internal
        virtual
        override(ERC20, ERC20Snapshot, ERC20Pausable, ERC20Whitelist)
    {
        super._burn(account, value);
    }

    /**
     * @dev Overload _burnFrom function to ensure contract has not been paused.
     * @param account address that funds will be burned from allowance.
     * @param amount amount of funds that will be burned.
     */
    function _burnFrom(address account, uint256 amount)
        internal
        virtual
        override(ERC20, ERC20Snapshot, ERC20Pausable, ERC20Whitelist, ERC20Freezable)
    {
        super._burnFrom(account, amount);
    }

    /**
     * @dev Overload _mint function to ensure contract has not been paused.
     * @param account address that funds will be minted to.
     * @param amount amount of funds that will be minted.
     */
    function _mint(address account, uint256 amount)
        internal
        virtual
        override(ERC20, ERC20Snapshot, ERC20Pausable, ERC20Whitelist, ERC20Mintable)
    {
        super._mint(account, amount);
    }

    function _burnFor(address account, uint256 amount) internal virtual override(ERC20Snapshot, ERC20Burnable) {
        super._burnFor(account, amount);
    }
}

/**
 * @title MetadataUpgrade
 * @author Team 3301 <[email protected]>
 * @dev Upgraded SygnumToken. This upgrade allows system accounts to confiscate tokens.
 */
pragma solidity 0.8.8;

import "./SygnumTokenV2.sol";

contract SygnumTokenV3 is SygnumTokenV2 {
    bool public initializedV3;

    error SygnumTokenV3AlreadyInitialized();

    // changed back to public for tests
    function initializeContractsAndConstructor(
        string memory _name,
        string memory _symbol,
        uint8 _decimals,
        bytes4 _category,
        string memory _class,
        address _issuer,
        address _baseOperators,
        address _whitelist,
        address _traderOperators,
        address _blockerOperators,
        string memory _tokenURI
    ) public virtual override {
        SygnumTokenV2.initializeContractsAndConstructor(
            _name,
            _symbol,
            _decimals,
            _category,
            _class,
            _issuer,
            _baseOperators,
            _whitelist,
            _traderOperators,
            _blockerOperators,
            _tokenURI
        );
        initializeV3();
    }

    function initializeV3() public virtual {
        if (initializedV3) revert SygnumTokenV3AlreadyInitialized();
        initializedV3 = true;
    }

    /**
     * @dev Modified _mint function allowing operators to mint while contract is paused
     * @param account address that funds will be minted to.
     * @param amount amount of funds that will be minted.
     */
    function _mint(address account, uint256 amount) internal virtual override {
        // Cannot use super. here as there is no way to selectively disable whenNotPaused,
        // we need to redefine the modifiers explicitly
        if (isOperator(msg.sender) && isWhitelisted(account)) {
            if (amount <= 0) revert ERC20MintableZeroMintAmount();
            ERC20Snapshot._mint(account, amount);
        } else {
            super._mint(account, amount);
        }
    }
}

/**
 * @title ERC20SygnumDetailed
 * @author Team 3301 <[email protected]>
 * @dev ERC20 Standard Token with additional details and role set.
 */

pragma solidity 0.8.8;

import "./ERC20Detailed.sol";
import "@sygnum/solidity-base-contracts/contracts/role/base/Operatorable.sol";

contract ERC20SygnumDetailed is ERC20Detailed, Operatorable {
    bytes4 private _category;
    string private _class;
    address private _issuer;

    event NameUpdated(address issuer, string name, address token);
    event SymbolUpdated(address issuer, string symbol, address token);
    event CategoryUpdated(address issuer, bytes4 category, address token);
    event ClassUpdated(address issuer, string class, address token);
    event IssuerUpdated(address issuer, address newIssuer, address token);

    /**
     * @dev Sets the values for `name`, `symbol`, `decimals`, `category`, `class` and `issuer`. All are
     *  mutable apart from `issuer`, which is immutable.
     * @param name string
     * @param symbol string
     * @param decimals uint8
     * @param category bytes4
     * @param class string
     * @param issuer address
     */
    function _setDetails(
        string memory name,
        string memory symbol,
        uint8 decimals,
        bytes4 category,
        string memory class,
        address issuer
    ) internal virtual {
        _name = name;
        _symbol = symbol;
        _decimals = decimals;
        _category = category;
        _class = class;
        _issuer = issuer;
    }

    /**
     * @dev Returns the category of the token.
     */
    function category() public view virtual returns (bytes4) {
        return _category;
    }

    /**
     * @dev Returns the class of the token.
     */
    function class() public view virtual returns (string memory) {
        return _class;
    }

    /**
     * @dev Returns the issuer of the token.
     */
    function issuer() public view virtual returns (address) {
        return _issuer;
    }

    /**
     * @dev Updates the name of the token, only callable by Sygnum operator.
     * @param name_ The new name.
     */
    function updateName(string memory name_) public virtual onlyOperator {
        _name = name_;
        emit NameUpdated(msg.sender, _name, address(this));
    }

    /**
     * @dev Updates the symbol of the token, only callable by Sygnum operator.
     * @param symbol_ The new symbol.
     */
    function updateSymbol(string memory symbol_) public virtual onlyOperator {
        _symbol = symbol_;
        emit SymbolUpdated(msg.sender, symbol_, address(this));
    }

    /**
     * @dev Updates the category of the token, only callable by Sygnum operator.
     * @param category_ The new cateogry.
     */
    function updateCategory(bytes4 category_) public virtual onlyOperator {
        _category = category_;
        emit CategoryUpdated(msg.sender, _category, address(this));
    }

    /**
     * @dev Updates the class of the token, only callable by Sygnum operator.
     * @param class_ The new class.
     */
    function updateClass(string memory class_) public virtual onlyOperator {
        _class = class_;
        emit ClassUpdated(msg.sender, _class, address(this));
    }

    /**
     * @dev Updates issuer ownership, only callable by Sygnum operator.
     * @param issuer_ The new issuer.
     */
    function updateIssuer(address issuer_) public virtual onlyOperator {
        _issuer = issuer_;
        emit IssuerUpdated(msg.sender, _issuer, address(this));
    }
}

// SPDX-License-Identifier: UNLICENSED

/**
 * @title ERC20Whitelist
 * @author Team 3301 <[email protected]>
 * @dev Overloading ERC20 functions to ensure that addresses attempting to particular
 * actions are whitelisted.
 */

pragma solidity ^0.8.0;

import "./ERC20Overload/ERC20.sol";
import "../instance/Whitelistable.sol";

contract ERC20Whitelist is ERC20, Whitelistable {
    /**
     * @dev Overload transfer function to validate sender and receiver are whitelisted.
     * @param to address that recieves the funds.
     * @param value amount of funds.
     */
    function transfer(address to, uint256 value)
        public
        virtual
        override
        whenWhitelisted(msg.sender)
        whenWhitelisted(to)
        returns (bool)
    {
        return super.transfer(to, value);
    }

    /**
     * @dev Overload approve function to validate sender and spender are whitelisted.
     * @param spender address that can spend the funds.
     * @param value amount of funds.
     */
    function approve(address spender, uint256 value)
        public
        virtual
        override
        whenWhitelisted(msg.sender)
        whenWhitelisted(spender)
        returns (bool)
    {
        return super.approve(spender, value);
    }

    /**
     * @dev Overload transferFrom function to validate sender, from and receiver are whitelisted.
     * @param from address that funds will be transferred from.
     * @param to address that funds will be transferred to.
     * @param value amount of funds.
     */
    function transferFrom(
        address from,
        address to,
        uint256 value
    ) public virtual override whenWhitelisted(msg.sender) whenWhitelisted(from) whenWhitelisted(to) returns (bool) {
        return super.transferFrom(from, to, value);
    }

    /**
     * @dev Overload increaseAllowance validate sender and spender are whitelisted.
     * @param spender address that will be allowed to transfer funds.
     * @param addedValue amount of funds to added to current allowance.
     */
    function increaseAllowance(address spender, uint256 addedValue)
        public
        virtual
        override
        whenWhitelisted(spender)
        whenWhitelisted(msg.sender)
        returns (bool)
    {
        return super.increaseAllowance(spender, addedValue);
    }

    /**
     * @dev Overload decreaseAllowance validate sender and spender are whitelisted.
     * @param spender address that will be allowed to transfer funds.
     * @param subtractedValue amount of funds to be deducted to current allowance.
     */
    function decreaseAllowance(address spender, uint256 subtractedValue)
        public
        virtual
        override
        whenWhitelisted(spender)
        whenWhitelisted(msg.sender)
        returns (bool)
    {
        return super.decreaseAllowance(spender, subtractedValue);
    }

    /**
     * @dev Overload _burn function to ensure that account has been whitelisted.
     * @param account address that funds will be burned from.
     * @param value amount of funds that will be burned.
     */
    function _burn(address account, uint256 value) internal virtual override whenWhitelisted(account) {
        super._burn(account, value);
    }

    /**
     * @dev Overload _burnFrom function to ensure sender and account have been whitelisted.
     * @param account address that funds will be burned from allowance.
     * @param amount amount of funds that will be burned.
     */
    function _burnFrom(address account, uint256 amount)
        internal
        virtual
        override
        whenWhitelisted(msg.sender)
        whenWhitelisted(account)
    {
        super._burnFrom(account, amount);
    }

    /**
     * @dev Overload _mint function to ensure account has been whitelisted.
     * @param account address that funds will be minted to.
     * @param amount amount of funds that will be minted.
     */
    function _mint(address account, uint256 amount) internal virtual override whenWhitelisted(account) {
        super._mint(account, amount);
    }
}

// SPDX-License-Identifier: UNLICENSED

/**
 * @title ERC20Pausable
 * @author Team 3301 <[email protected]>
 * @dev Overloading ERC20 functions to ensure that the contract has not been paused.
 */

pragma solidity ^0.8.0;

import "./ERC20Overload/ERC20.sol";
import "../Pausable.sol";

contract ERC20Pausable is ERC20, Pausable {
    /**
     * @dev Overload transfer function to ensure contract has not been paused.
     * @param to address that recieves the funds.
     * @param value amount of funds.
     */
    function transfer(address to, uint256 value) public virtual override whenNotPaused returns (bool) {
        return super.transfer(to, value);
    }

    /**
     * @dev Overload approve function to ensure contract has not been paused.
     * @param spender address that can spend the funds.
     * @param value amount of funds.
     */
    function approve(address spender, uint256 value) public virtual override whenNotPaused returns (bool) {
        return super.approve(spender, value);
    }

    /**
     * @dev Overload transferFrom function to ensure contract has not been paused.
     * @param from address that funds will be transferred from.
     * @param to address that funds will be transferred to.
     * @param value amount of funds.
     */
    function transferFrom(
        address from,
        address to,
        uint256 value
    ) public virtual override whenNotPaused returns (bool) {
        return super.transferFrom(from, to, value);
    }

    /**
     * @dev Overload increaseAllowance function to ensure contract has not been paused.
     * @param spender address that will be allowed to transfer funds.
     * @param addedValue amount of funds to added to current allowance.
     */
    function increaseAllowance(address spender, uint256 addedValue)
        public
        virtual
        override
        whenNotPaused
        returns (bool)
    {
        return super.increaseAllowance(spender, addedValue);
    }

    /**
     * @dev Overload decreaseAllowance function to ensure contract has not been paused.
     * @param spender address that will be allowed to transfer funds.
     * @param subtractedValue amount of funds to be deducted to current allowance.
     */
    function decreaseAllowance(address spender, uint256 subtractedValue)
        public
        virtual
        override
        whenNotPaused
        returns (bool)
    {
        return super.decreaseAllowance(spender, subtractedValue);
    }

    /**
     * @dev Overload _burn function to ensure contract has not been paused.
     * @param account address that funds will be burned from.
     * @param value amount of funds that will be burned.
     */
    function _burn(address account, uint256 value) internal virtual override whenNotPaused {
        super._burn(account, value);
    }

    /**
     * @dev Overload _burnFrom function to ensure contract has not been paused.
     * @param account address that funds will be burned from allowance.
     * @param amount amount of funds that will be burned.
     */
    function _burnFrom(address account, uint256 amount) internal virtual override whenNotPaused {
        super._burnFrom(account, amount);
    }

    /**
     * @dev Overload _mint function to ensure contract has not been paused.
     * @param account address that funds will be minted to.
     * @param amount amount of funds that will be minted.
     */
    function _mint(address account, uint256 amount) internal virtual override whenNotPaused {
        super._mint(account, amount);
    }
}

// SPDX-License-Identifier: UNLICENSED

/**
 * @title ERC20Mintable
 * @author Team 3301 <[email protected]>
 * @dev For blocking and unblocking particular user funds.
 */

pragma solidity ^0.8.0;

import "./ERC20Overload/ERC20.sol";
import "../../role/base/Operatorable.sol";

contract ERC20Mintable is ERC20, Operatorable {
    /**
     * @dev Error: "ERC20Mintable: amount has to be greater than 0"
     */
    error ERC20MintableZeroMintAmount();

    /**
     * @dev Overload _mint to ensure only operator or system can mint funds.
     * @param account address that will recieve new funds.
     * @param amount of funds to be minted.
     */
    function _mint(address account, uint256 amount) internal virtual override onlyOperatorOrSystem {
        if (amount <= 0) revert ERC20MintableZeroMintAmount();

        super._mint(account, amount);
    }
}

// SPDX-License-Identifier: UNLICENSED

/**
 * @title ERC20Burnable
 * @author Team 3301 <[email protected]>
 * @dev For burning funds from particular user addresses.
 */

pragma solidity ^0.8.0;

import "./ERC20Snapshot.sol";
import "../../role/base/Operatorable.sol";

contract ERC20Burnable is ERC20Snapshot, Operatorable {
    /**
     * @dev Overload ERC20 _burnFor, burning funds from a particular users address.
     * @param account address to burn funds from.
     * @param amount of funds to burn.
     */

    function _burnFor(address account, uint256 amount) internal virtual override onlyOperator {
        super._burn(account, amount);
    }
}

// SPDX-License-Identifier: UNLICENSED

/**
 * @title ERC20Freezable
 * @author Team 3301 <[email protected]>
 * @dev Overloading ERC20 functions to ensure client addresses are not frozen for particular actions.
 */

pragma solidity ^0.8.0;

import "./ERC20Overload/ERC20.sol";
import "../Freezable.sol";

contract ERC20Freezable is ERC20, Freezable {
    /**
     * @dev Overload transfer function to ensure sender and receiver have not been frozen.
     * @param to address that recieves the funds.
     * @param value amount of funds.
     */
    function transfer(address to, uint256 value)
        public
        virtual
        override
        whenNotFrozen(msg.sender)
        whenNotFrozen(to)
        returns (bool)
    {
        return super.transfer(to, value);
    }

    /**
     * @dev Overload approve function to ensure sender and receiver have not been frozen.
     * @param spender address that can spend the funds.
     * @param value amount of funds.
     */
    function approve(address spender, uint256 value)
        public
        virtual
        override
        whenNotFrozen(msg.sender)
        whenNotFrozen(spender)
        returns (bool)
    {
        return super.approve(spender, value);
    }

    /**
     * @dev Overload transferFrom function to ensure sender, approver and receiver have not been frozen.
     * @param from address that funds will be transferred from.
     * @param to address that funds will be transferred to.
     * @param value amount of funds.
     */
    function transferFrom(
        address from,
        address to,
        uint256 value
    ) public virtual override whenNotFrozen(msg.sender) whenNotFrozen(from) whenNotFrozen(to) returns (bool) {
        return super.transferFrom(from, to, value);
    }

    /**
     * @dev Overload increaseAllowance function to ensure sender and spender have not been frozen.
     * @param spender address that will be allowed to transfer funds.
     * @param addedValue amount of funds to added to current allowance.
     */
    function increaseAllowance(address spender, uint256 addedValue)
        public
        virtual
        override
        whenNotFrozen(msg.sender)
        whenNotFrozen(spender)
        returns (bool)
    {
        return super.increaseAllowance(spender, addedValue);
    }

    /**
     * @dev Overload decreaseAllowance function to ensure sender and spender have not been frozen.
     * @param spender address that will be allowed to transfer funds.
     * @param subtractedValue amount of funds to be deducted to current allowance.
     */
    function decreaseAllowance(address spender, uint256 subtractedValue)
        public
        virtual
        override
        whenNotFrozen(msg.sender)
        whenNotFrozen(spender)
        returns (bool)
    {
        return super.decreaseAllowance(spender, subtractedValue);
    }

    /**
     * @dev Overload _burnfrom function to ensure sender and user to be burned from have not been frozen.
     * @param account account that funds will be burned from.
     * @param amount amount of funds to be burned.
     */
    function _burnFrom(address account, uint256 amount)
        internal
        virtual
        override
        whenNotFrozen(msg.sender)
        whenNotFrozen(account)
    {
        super._burnFrom(account, amount);
    }
}

// SPDX-License-Identifier: UNLICENSED

/**
 * @title ERC20Destroyable
 * @author Team 3301 <[email protected]>
 * @notice Allows operator to destroy contract.
 */

pragma solidity ^0.8.0;

import "../../role/base/Operatorable.sol";

contract ERC20Destroyable is Operatorable {
    event Destroyed(address indexed caller, address indexed account, address indexed contractAddress);

    function destroy(address payable to) public onlyOperator {
        emit Destroyed(msg.sender, to, address(this));
        selfdestruct(to);
    }
}

// SPDX-License-Identifier: UNLICENSED

/**
 * @title ERC20Snapshot
 * @author Team 3301 <[email protected]>
 * @notice Records historical balances.
 */
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "./ERC20Overload/ERC20.sol";

contract ERC20Snapshot is ERC20 {
    using SafeMath for uint256;

    /**
     * @dev `Snapshot` is the structure that attaches a block number to a
     * given value. The block number attached is the one that last changed the value
     */
    struct Snapshot {
        uint256 fromBlock; // `fromBlock` is the block number at which the value was generated from
        uint256 value; // `value` is the amount of tokens at a specific block number
    }

    /**
     * @dev `_snapshotBalances` is the map that tracks the balance of each address, in this
     * contract when the balance changes the block number that the change
     * occurred is also included in the map
     */
    mapping(address => Snapshot[]) private _snapshotBalances;

    // Tracks the history of the `totalSupply` of the token
    Snapshot[] private _snapshotTotalSupply;

    /**
     * @dev Queries the balance of `_owner` at a specific `_blockNumber`
     * @param _owner The address from which the balance will be retrieved
     * @param _blockNumber The block number when the balance is queried
     * @return The balance at `_blockNumber`
     */
    function balanceOfAt(address _owner, uint256 _blockNumber) public view returns (uint256) {
        return getValueAt(_snapshotBalances[_owner], _blockNumber);
    }

    /**
     * @dev Total amount of tokens at a specific `_blockNumber`.
     * @param _blockNumber The block number when the totalSupply is queried
     * @return The total amount of tokens at `_blockNumber`
     */
    function totalSupplyAt(uint256 _blockNumber) public view returns (uint256) {
        return getValueAt(_snapshotTotalSupply, _blockNumber);
    }

    /**
     * @dev `getValueAt` retrieves the number of tokens at a given block number
     * @param checkpoints The history of values being queried
     * @param _block The block number to retrieve the value at
     * @return The number of tokens being queried
     */
    function getValueAt(Snapshot[] storage checkpoints, uint256 _block) internal view returns (uint256) {
        if (checkpoints.length == 0) return 0;

        // Shortcut for the actual value
        if (_block >= checkpoints[checkpoints.length.sub(1)].fromBlock) {
            return checkpoints[checkpoints.length.sub(1)].value;
        }

        if (_block < checkpoints[0].fromBlock) {
            return 0;
        }

        // Binary search of the value in the array
        uint256 min;
        uint256 max = checkpoints.length.sub(1);

        while (max > min) {
            uint256 mid = (max.add(min).add(1)).div(2);
            if (checkpoints[mid].fromBlock <= _block) {
                min = mid;
            } else {
                max = mid.sub(1);
            }
        }

        return checkpoints[min].value;
    }

    /**
     * @dev `updateValueAtNow` used to update the `_snapshotBalances` map and the `_snapshotTotalSupply`
     * @param checkpoints The history of data being updated
     * @param _value The new number of tokens
     */
    function updateValueAtNow(Snapshot[] storage checkpoints, uint256 _value) internal {
        if ((checkpoints.length == 0) || (checkpoints[checkpoints.length.sub(1)].fromBlock < block.number)) {
            checkpoints.push(Snapshot(block.number, _value));
        } else {
            checkpoints[checkpoints.length.sub(1)].value = _value;
        }
    }

    /**
     * @dev Internal function that transfers an amount of the token and assigns it to
     * an account. This encapsulates the modification of balances such that the
     * proper events are emitted.
     * @param to The account that will receive the created tokens.
     * @param value The amount that will be created.
     */
    function transfer(address to, uint256 value) public virtual override returns (bool result) {
        result = super.transfer(to, value);
        updateValueAtNow(_snapshotTotalSupply, totalSupply());
        updateValueAtNow(_snapshotBalances[msg.sender], balanceOf(msg.sender));
        updateValueAtNow(_snapshotBalances[to], balanceOf(to));
    }

    /**
     * @dev Internal function that transfers an amount of the token and assigns it to
     * an account. This encapsulates the modification of balances such that the
     * proper events are emitted.
     * @param from The account that funds will be taken from.
     * @param to The account that funds will be given too.
     * @param value The amount of funds to be transferred..
     */
    function transferFrom(
        address from,
        address to,
        uint256 value
    ) public virtual override returns (bool result) {
        result = super.transferFrom(from, to, value);
        updateValueAtNow(_snapshotTotalSupply, totalSupply());
        updateValueAtNow(_snapshotBalances[from], balanceOf(from));
        updateValueAtNow(_snapshotBalances[to], balanceOf(to));
    }

    /**
     * @dev Internal function that confiscates an amount of the token and assigns it to
     * an account. This encapsulates the modification of balances such that the
     * proper events are emitted.
     * @param confiscatee The account that funds will be taken from.
     * @param receiver The account that funds will be given too.
     * @param amount The amount of funds to be transferred..
     */
    function _confiscate(
        address confiscatee,
        address receiver,
        uint256 amount
    ) internal virtual {
        super._transfer(confiscatee, receiver, amount);
        updateValueAtNow(_snapshotTotalSupply, totalSupply());
        updateValueAtNow(_snapshotBalances[confiscatee], balanceOf(confiscatee));
        updateValueAtNow(_snapshotBalances[receiver], balanceOf(receiver));
    }

    /**
     * @dev Internal function that mints an amount of the token and assigns it to
     * an account. This encapsulates the modification of balances such that the
     * proper events are emitted.
     * @param account The account that will receive the created tokens.
     * @param amount The amount that will be created.
     */
    function _mint(address account, uint256 amount) internal virtual override {
        super._mint(account, amount);
        updateValueAtNow(_snapshotTotalSupply, totalSupply());
        updateValueAtNow(_snapshotBalances[account], balanceOf(account));
    }

    /**
     * @dev Internal function that burns an amount of the token of a given
     * account.
     * @param account The account whose tokens will be burnt.
     * @param amount The amount that will be burnt.
     */
    function _burn(address account, uint256 amount) internal virtual override {
        super._burn(account, amount);
        updateValueAtNow(_snapshotTotalSupply, totalSupply());
        updateValueAtNow(_snapshotBalances[account], balanceOf(account));
    }

    /**
     * @dev Internal function that burns an amount of the token of a given
     * account.
     * @param account The account whose tokens will be burnt.
     * @param amount The amount that will be burnt.
     */
    function _burnFor(address account, uint256 amount) internal virtual {
        super._burn(account, amount);
        updateValueAtNow(_snapshotTotalSupply, totalSupply());
        updateValueAtNow(_snapshotBalances[account], balanceOf(account));
    }

    /**
     * @dev Internal function that burns an amount of the token of a given
     * account, deducting from the sender's allowance for said account. Uses the
     * internal burn function.
     * @param account The account whose tokens will be burnt.
     * @param amount The amount that will be burnt.
     */
    function _burnFrom(address account, uint256 amount) internal virtual override {
        super._burnFrom(account, amount);
        updateValueAtNow(_snapshotTotalSupply, totalSupply());
        updateValueAtNow(_snapshotBalances[account], balanceOf(account));
    }
}

// SPDX-License-Identifier: UNLICENSED

/**
 * @title ERC20Tradeable
 * @author Team 3301 <[email protected]>
 * @dev Trader accounts can approve particular addresses on behalf of a user.
 */

pragma solidity ^0.8.0;

import "./ERC20Overload/ERC20.sol";
import "../../role/trader/TraderOperatorable.sol";

contract ERC20Tradeable is ERC20, TraderOperatorable {
    /**
     * @dev Trader can approve users balance to a particular address for a particular amount.
     * @param _owner address that approves the funds.
     * @param _spender address that spends the funds.
     * @param _value amount of funds.
     */
    function approveOnBehalf(
        address _owner,
        address _spender,
        uint256 _value
    ) public onlyTrader {
        super._approve(_owner, _spender, _value);
    }
}

// SPDX-License-Identifier: UNLICENSED

/**
 * @title ERC20Blockable
 * @author Team 3301 <[email protected]>
 * @dev For blocking and unblocking particular user funds.
 */

pragma solidity ^0.8.0;

import "./ERC20Overload/ERC20.sol";
import "../../role/blocker/BlockerOperatorable.sol";

contract ERC20Blockable is ERC20, BlockerOperatorable {
    using SafeMath for uint256;
    uint256 public totalBlockedBalance;

    mapping(address => uint256) public _blockedBalances;

    event Blocked(address indexed blocker, address indexed account, uint256 value);
    event UnBlocked(address indexed blocker, address indexed account, uint256 value);

    /**
     * @dev Block funds, and move funds from _balances into _blockedBalances.
     * @param _account address to block funds.
     * @param _amount of funds to block.
     */
    function block(address _account, uint256 _amount) public onlyBlockerOrOperator {
        _balances[_account] = _balances[_account].sub(_amount);
        _blockedBalances[_account] = _blockedBalances[_account].add(_amount);

        totalBlockedBalance = totalBlockedBalance.add(_amount);
        emit Blocked(msg.sender, _account, _amount);
    }

    /**
     * @dev Unblock funds, and move funds from _blockedBalances into _balances.
     * @param _account address to unblock funds.
     * @param _amount of funds to unblock.
     */
    function unblock(address _account, uint256 _amount) public onlyBlockerOrOperator {
        _balances[_account] = _balances[_account].add(_amount);
        _blockedBalances[_account] = _blockedBalances[_account].sub(_amount);

        totalBlockedBalance = totalBlockedBalance.sub(_amount);
        emit UnBlocked(msg.sender, _account, _amount);
    }

    /**
     * @dev Getter for the amount of blocked balance for a particular address.
     * @param _account address to get blocked balance.
     * @return amount of blocked balance.
     */
    function blockedBalanceOf(address _account) public view returns (uint256) {
        return _blockedBalances[_account];
    }

    /**
     * @dev Getter for the total amount of blocked funds for all users.
     * @return amount of total blocked balance.
     */
    function getTotalBlockedBalance() public view returns (uint256) {
        return totalBlockedBalance;
    }
}

/**
 * @title ERC20Detailed
 * @author OpenZeppelin-Solidity = "openzeppelin-solidity/contracts/token/ERC20/ERC20Detailed.sol", and rmeoval
 *  of IERC20 due to " contract binary not set. Can't deploy new instance.
 * This contract may be abstract, not implement an abstract parent's methods completely
 * or not invoke an inherited contract's constructor correctly"
 */

pragma solidity 0.8.8;

/**
 * @dev Optional functions from the ERC20 standard.
 */
contract ERC20Detailed {
    string internal _name;
    string internal _symbol;
    uint8 internal _decimals;

    /**
     * @dev Returns the name of the token.
     */
    function name() public view virtual returns (string memory) {
        return _name;
    }

    /**
     * @dev Returns the symbol of the token, usually a shorter version of the
     * name.
     */
    function symbol() public view virtual returns (string memory) {
        return _symbol;
    }

    /**
     * @dev Returns the number of decimals used to get its user representation.
     * For example, if `decimals` equals `2`, a balance of `505` tokens should
     * be displayed to a user as `5,05` (`505 / 10 ** 2`).
     *
     * Tokens usually opt for a value of 18, imitating the relationship between
     * Ether and Wei.
     *
     * > Note that this information is only used for _display_ purposes: it in
     * no way affects any of the arithmetic of the contract, including
     * `IERC20.balanceOf` and `IERC20.transfer`.
     */
    function decimals() public view virtual returns (uint8) {
        return _decimals;
    }
}

// SPDX-License-Identifier: UNLICENSED

pragma solidity ^0.8.0;

import "@openzeppelin/contracts/utils/Context.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";

/**
 * @dev Implementation of the {IERC20} interface.
 *
 * This implementation is agnostic to the way tokens are created. This means
 * that a supply mechanism has to be added in a derived contract using {_mint}.
 * For a generic mechanism see {ERC20Mintable}.
 *
 * TIP: For a detailed writeup see our guide
 * https://forum.zeppelin.solutions/t/how-to-implement-erc20-supply-mechanisms/226[How
 * to implement supply mechanisms].
 *
 * We have followed general OpenZeppelin guidelines: functions revert instead
 * of returning `false` on failure. This behavior is nonetheless conventional
 * and does not conflict with the expectations of ERC20 applications.
 *
 * Additionally, an {Approval} event is emitted on calls to {transferFrom}.
 * This allows applications to reconstruct the allowance for all accounts just
 * by listening to said events. Other implementations of the EIP may not emit
 * these events, as it isn't required by the specification.
 *
 * Finally, the non-standard {decreaseAllowance} and {increaseAllowance}
 * functions have been added to mitigate the well-known issues around setting
 * allowances. See {IERC20-approve}.
 */
contract ERC20 is Context, IERC20 {
    using SafeMath for uint256;

    mapping(address => uint256) internal _balances;

    mapping(address => mapping(address => uint256)) private _allowances;

    uint256 private _totalSupply;

    /**
     * @dev See {IERC20-totalSupply}.
     */
    function totalSupply() public view virtual override returns (uint256) {
        return _totalSupply;
    }

    /**
     * @dev See {IERC20-balanceOf}.
     */
    function balanceOf(address account) public view virtual override returns (uint256) {
        return _balances[account];
    }

    /**
     * @dev See {IERC20-transfer}.
     *
     * Requirements:
     *
     * - `recipient` cannot be the zero address.
     * - the caller must have a balance of at least `amount`.
     */
    function transfer(address recipient, uint256 amount) public virtual override returns (bool) {
        _transfer(_msgSender(), recipient, amount);
        return true;
    }

    /**
     * @dev See {IERC20-allowance}.
     */
    function allowance(address owner, address spender) public view virtual override returns (uint256) {
        return _allowances[owner][spender];
    }

    /**
     * @dev See {IERC20-approve}.
     *
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     */
    function approve(address spender, uint256 amount) public virtual override returns (bool) {
        _approve(_msgSender(), spender, amount);
        return true;
    }

    /**
     * @dev See {IERC20-transferFrom}.
     *
     * Emits an {Approval} event indicating the updated allowance. This is not
     * required by the EIP. See the note at the beginning of {ERC20};
     *
     * Requirements:
     * - `sender` and `recipient` cannot be the zero address.
     * - `sender` must have a balance of at least `amount`.
     * - the caller must have allowance for `sender`'s tokens of at least
     * `amount`.
     */
    function transferFrom(
        address sender,
        address recipient,
        uint256 amount
    ) public virtual override returns (bool) {
        _transfer(sender, recipient, amount);
        _approve(
            sender,
            _msgSender(),
            _allowances[sender][_msgSender()].sub(amount, "ERC20: transfer amount exceeds allowance")
        );
        return true;
    }

    /**
     * @dev Atomically increases the allowance granted to `spender` by the caller.
     *
     * This is an alternative to {approve} that can be used as a mitigation for
     * problems described in {IERC20-approve}.
     *
     * Emits an {Approval} event indicating the updated allowance.
     *
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     */
    function increaseAllowance(address spender, uint256 addedValue) public virtual returns (bool) {
        _approve(_msgSender(), spender, _allowances[_msgSender()][spender].add(addedValue));
        return true;
    }

    /**
     * @dev Atomically decreases the allowance granted to `spender` by the caller.
     *
     * This is an alternative to {approve} that can be used as a mitigation for
     * problems described in {IERC20-approve}.
     *
     * Emits an {Approval} event indicating the updated allowance.
     *
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     * - `spender` must have allowance for the caller of at least
     * `subtractedValue`.
     */
    function decreaseAllowance(address spender, uint256 subtractedValue) public virtual returns (bool) {
        _approve(
            _msgSender(),
            spender,
            _allowances[_msgSender()][spender].sub(subtractedValue, "ERC20: decreased allowance below zero")
        );
        return true;
    }

    /**
     * @dev Moves tokens `amount` from `sender` to `recipient`.
     *
     * This is internal function is equivalent to {transfer}, and can be used to
     * e.g. implement automatic token fees, slashing mechanisms, etc.
     *
     * Emits a {Transfer} event.
     *
     * Requirements:
     *
     * - `sender` cannot be the zero address.
     * - `recipient` cannot be the zero address.
     * - `sender` must have a balance of at least `amount`.
     */
    function _transfer(
        address sender,
        address recipient,
        uint256 amount
    ) internal {
        require(sender != address(0), "ERC20: transfer from the zero address");
        require(recipient != address(0), "ERC20: transfer to the zero address");

        _balances[sender] = _balances[sender].sub(amount, "ERC20: transfer amount exceeds balance");
        _balances[recipient] = _balances[recipient].add(amount);
        emit Transfer(sender, recipient, amount);
    }

    /** @dev Creates `amount` tokens and assigns them to `account`, increasing
     * the total supply.
     *
     * Emits a {Transfer} event with `from` set to the zero address.
     *
     * Requirements
     *
     * - `to` cannot be the zero address.
     */
    function _mint(address account, uint256 amount) internal virtual {
        require(account != address(0), "ERC20: mint to the zero address");

        _totalSupply = _totalSupply.add(amount);
        _balances[account] = _balances[account].add(amount);
        emit Transfer(address(0), account, amount);
    }

    /**
     * @dev Destroys `amount` tokens from `account`, reducing the
     * total supply.
     *
     * Emits a {Transfer} event with `to` set to the zero address.
     *
     * Requirements
     *
     * - `account` cannot be the zero address.
     * - `account` must have at least `amount` tokens.
     */
    function _burn(address account, uint256 amount) internal virtual {
        require(account != address(0), "ERC20: burn from the zero address");

        _balances[account] = _balances[account].sub(amount, "ERC20: burn amount exceeds balance");
        _totalSupply = _totalSupply.sub(amount);
        emit Transfer(account, address(0), amount);
    }

    /**
     * @dev Sets `amount` as the allowance of `spender` over the `owner`s tokens.
     *
     * This is internal function is equivalent to `approve`, and can be used to
     * e.g. set automatic allowances for certain subsystems, etc.
     *
     * Emits an {Approval} event.
     *
     * Requirements:
     *
     * - `owner` cannot be the zero address.
     * - `spender` cannot be the zero address.
     */
    function _approve(
        address owner,
        address spender,
        uint256 amount
    ) internal {
        require(owner != address(0), "ERC20: approve from the zero address");
        require(spender != address(0), "ERC20: approve to the zero address");

        _allowances[owner][spender] = amount;
        emit Approval(owner, spender, amount);
    }

    /**
     * @dev Destroys `amount` tokens from `account`.`amount` is then deducted
     * from the caller's allowance.
     *
     * See {_burn} and {_approve}.
     */
    function _burnFrom(address account, uint256 amount) internal virtual {
        _burn(account, amount);
        _approve(
            account,
            _msgSender(),
            _allowances[account][_msgSender()].sub(amount, "ERC20: burn amount exceeds allowance")
        );
    }
}

// SPDX-License-Identifier: UNLICENSED

/**
 * @title Whitelistable
 * @author Team 3301 <[email protected]>
 * @dev Whitelistable contract stores the Whitelist contract address, and modifiers for
 *       contracts.
 */

pragma solidity ^0.8.0;

import "../../role/base/Operatorable.sol";
import "../interface/IWhitelist.sol";
import "../Initializable.sol";

contract Whitelistable is Initializable, Operatorable {
    IWhitelist internal whitelistInst;
    address private whitelistPending;

    /**
     * @dev Error: "Whitelistable: account is not whitelisted"
     */
    error WhitelistableAccountNotWhitelisted();

    /**
     * @dev Error: "Whitelistable: address of new whitelist contract can not be zero"
     */
    error WhitelistableWhitelistContractZeroAddress();

    /**
     * @dev Error:  "Whitelistable: should be called from new whitelist contract"
     */
    error WhitelistableCallerNotWhitelistContract(address _caller);

    event WhitelistContractChanged(address indexed caller, address indexed whitelistAddress);
    event WhitelistContractPending(address indexed caller, address indexed whitelistAddress);

    /**
     * @dev Reverts if _account is not whitelisted.
     * @param _account address to determine if whitelisted.
     */
    modifier whenWhitelisted(address _account) {
        if (!isWhitelisted(_account)) revert WhitelistableAccountNotWhitelisted();
        _;
    }

    /**
     * @dev Initialization instead of constructor, called once. The setWhitelistContract function can be called only by Admin role with
     *       confirmation through the whitelist contract.
     * @param _whitelist Whitelist contract address.
     * @param _baseOperators BaseOperators contract address.
     */
    function initialize(address _baseOperators, address _whitelist) public virtual initializer {
        _setOperatorsContract(_baseOperators);
        _setWhitelistContract(_whitelist);
    }

    /**
     * @dev Set the new the address of Whitelist contract, should be confirmed from whitelist contract by calling confirmFor(addr)
     *       where addr is the address of current contract instance. This is done to prevent the case when the new contract address is
     *       broken and control of the contract can be lost in such case
     * @param _whitelist Whitelist contract address.
     */
    function setWhitelistContract(address _whitelist) public onlyAdmin {
        if (_whitelist == address(0)) revert WhitelistableWhitelistContractZeroAddress();

        whitelistPending = _whitelist;
        emit WhitelistContractPending(msg.sender, _whitelist);
    }

    /**
     * @dev The function should be called from new whitelist contract by admin to insure that whitelistPending address
     *       is the real contract address.
     */
    function confirmWhitelistContract() public {
        if (whitelistPending == address(0)) revert WhitelistableWhitelistContractZeroAddress();

        if (msg.sender != whitelistPending) revert WhitelistableCallerNotWhitelistContract(msg.sender);

        _setWhitelistContract(whitelistPending);
    }

    /**
     * @return The address of the Whitelist contract.
     */
    function getWhitelistContract() public view returns (address) {
        return address(whitelistInst);
    }

    /**
     * @return The pending address of the Whitelist contract.
     */
    function getWhitelistPending() public view returns (address) {
        return whitelistPending;
    }

    /**
     * @return If '_account' is whitelisted.
     */
    function isWhitelisted(address _account) public view returns (bool) {
        return whitelistInst.isWhitelisted(_account);
    }

    /** INTERNAL FUNCTIONS */
    function _setWhitelistContract(address _whitelist) internal {
        if (_whitelist == address(0)) revert WhitelistableWhitelistContractZeroAddress();

        whitelistInst = IWhitelist(_whitelist);
        emit WhitelistContractChanged(msg.sender, _whitelist);
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

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.6.0) (token/ERC20/IERC20.sol)

pragma solidity ^0.8.0;

/**
 * @dev Interface of the ERC20 standard as defined in the EIP.
 */
interface IERC20 {
    /**
     * @dev Emitted when `value` tokens are moved from one account (`from`) to
     * another (`to`).
     *
     * Note that `value` may be zero.
     */
    event Transfer(address indexed from, address indexed to, uint256 value);

    /**
     * @dev Emitted when the allowance of a `spender` for an `owner` is set by
     * a call to {approve}. `value` is the new allowance.
     */
    event Approval(address indexed owner, address indexed spender, uint256 value);

    /**
     * @dev Returns the amount of tokens in existence.
     */
    function totalSupply() external view returns (uint256);

    /**
     * @dev Returns the amount of tokens owned by `account`.
     */
    function balanceOf(address account) external view returns (uint256);

    /**
     * @dev Moves `amount` tokens from the caller's account to `to`.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transfer(address to, uint256 amount) external returns (bool);

    /**
     * @dev Returns the remaining number of tokens that `spender` will be
     * allowed to spend on behalf of `owner` through {transferFrom}. This is
     * zero by default.
     *
     * This value changes when {approve} or {transferFrom} are called.
     */
    function allowance(address owner, address spender) external view returns (uint256);

    /**
     * @dev Sets `amount` as the allowance of `spender` over the caller's tokens.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * IMPORTANT: Beware that changing an allowance with this method brings the risk
     * that someone may use both the old and the new allowance by unfortunate
     * transaction ordering. One possible solution to mitigate this race
     * condition is to first reduce the spender's allowance to 0 and set the
     * desired value afterwards:
     * https://github.com/ethereum/EIPs/issues/20#issuecomment-263524729
     *
     * Emits an {Approval} event.
     */
    function approve(address spender, uint256 amount) external returns (bool);

    /**
     * @dev Moves `amount` tokens from `from` to `to` using the
     * allowance mechanism. `amount` is then deducted from the caller's
     * allowance.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transferFrom(
        address from,
        address to,
        uint256 amount
    ) external returns (bool);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.6.0) (utils/math/SafeMath.sol)

pragma solidity ^0.8.0;

// CAUTION
// This version of SafeMath should only be used with Solidity 0.8 or later,
// because it relies on the compiler's built in overflow checks.

/**
 * @dev Wrappers over Solidity's arithmetic operations.
 *
 * NOTE: `SafeMath` is generally not needed starting with Solidity 0.8, since the compiler
 * now has built in overflow checking.
 */
library SafeMath {
    /**
     * @dev Returns the addition of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function tryAdd(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            uint256 c = a + b;
            if (c < a) return (false, 0);
            return (true, c);
        }
    }

    /**
     * @dev Returns the subtraction of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function trySub(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            if (b > a) return (false, 0);
            return (true, a - b);
        }
    }

    /**
     * @dev Returns the multiplication of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function tryMul(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            // Gas optimization: this is cheaper than requiring 'a' not being zero, but the
            // benefit is lost if 'b' is also tested.
            // See: https://github.com/OpenZeppelin/openzeppelin-contracts/pull/522
            if (a == 0) return (true, 0);
            uint256 c = a * b;
            if (c / a != b) return (false, 0);
            return (true, c);
        }
    }

    /**
     * @dev Returns the division of two unsigned integers, with a division by zero flag.
     *
     * _Available since v3.4._
     */
    function tryDiv(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            if (b == 0) return (false, 0);
            return (true, a / b);
        }
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers, with a division by zero flag.
     *
     * _Available since v3.4._
     */
    function tryMod(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            if (b == 0) return (false, 0);
            return (true, a % b);
        }
    }

    /**
     * @dev Returns the addition of two unsigned integers, reverting on
     * overflow.
     *
     * Counterpart to Solidity's `+` operator.
     *
     * Requirements:
     *
     * - Addition cannot overflow.
     */
    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        return a + b;
    }

    /**
     * @dev Returns the subtraction of two unsigned integers, reverting on
     * overflow (when the result is negative).
     *
     * Counterpart to Solidity's `-` operator.
     *
     * Requirements:
     *
     * - Subtraction cannot overflow.
     */
    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        return a - b;
    }

    /**
     * @dev Returns the multiplication of two unsigned integers, reverting on
     * overflow.
     *
     * Counterpart to Solidity's `*` operator.
     *
     * Requirements:
     *
     * - Multiplication cannot overflow.
     */
    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        return a * b;
    }

    /**
     * @dev Returns the integer division of two unsigned integers, reverting on
     * division by zero. The result is rounded towards zero.
     *
     * Counterpart to Solidity's `/` operator.
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        return a / b;
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers. (unsigned integer modulo),
     * reverting when dividing by zero.
     *
     * Counterpart to Solidity's `%` operator. This function uses a `revert`
     * opcode (which leaves remaining gas untouched) while Solidity uses an
     * invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function mod(uint256 a, uint256 b) internal pure returns (uint256) {
        return a % b;
    }

    /**
     * @dev Returns the subtraction of two unsigned integers, reverting with custom message on
     * overflow (when the result is negative).
     *
     * CAUTION: This function is deprecated because it requires allocating memory for the error
     * message unnecessarily. For custom revert reasons use {trySub}.
     *
     * Counterpart to Solidity's `-` operator.
     *
     * Requirements:
     *
     * - Subtraction cannot overflow.
     */
    function sub(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        unchecked {
            require(b <= a, errorMessage);
            return a - b;
        }
    }

    /**
     * @dev Returns the integer division of two unsigned integers, reverting with custom message on
     * division by zero. The result is rounded towards zero.
     *
     * Counterpart to Solidity's `/` operator. Note: this function uses a
     * `revert` opcode (which leaves remaining gas untouched) while Solidity
     * uses an invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function div(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        unchecked {
            require(b > 0, errorMessage);
            return a / b;
        }
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers. (unsigned integer modulo),
     * reverting with custom message when dividing by zero.
     *
     * CAUTION: This function is deprecated because it requires allocating memory for the error
     * message unnecessarily. For custom revert reasons use {tryMod}.
     *
     * Counterpart to Solidity's `%` operator. This function uses a `revert`
     * opcode (which leaves remaining gas untouched) while Solidity uses an
     * invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function mod(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        unchecked {
            require(b > 0, errorMessage);
            return a % b;
        }
    }
}

// SPDX-License-Identifier: UNLICENSED

pragma solidity ^0.8.0;

/**
 * @title IWhitelist
 * @notice Interface for Whitelist contract
 */
abstract contract IWhitelist {
    function isWhitelisted(address _account) external view virtual returns (bool);

    function toggleWhitelist(address _account, bool _toggled) external virtual;
}

// SPDX-License-Identifier: UNLICENSED

/**
 * @title Pausable
 * @author Team 3301 <[email protected]>
 * @dev Contract module which allows children to implement an emergency stop
 *      mechanism that can be triggered by an authorized account in the TraderOperatorable
 *      contract.
 */
pragma solidity ^0.8.0;

import "../role/trader/TraderOperatorable.sol";

abstract contract Pausable is TraderOperatorable {
    bool internal _paused;

    /**
     * @dev Error: "Pausable: paused"
     */
    error PausablePaused();

    /**
     * @dev Error: "Pausable: not paused"
     */
    error PausableNotPaused();

    event Paused(address indexed account);
    event Unpaused(address indexed account);

    // solhint-disable-next-line func-visibility
    constructor() {
        _paused = false;
    }

    /**
     * @dev Reverts if contract is paused.
     */
    modifier whenNotPaused() {
        if (_paused) revert PausablePaused();
        _;
    }

    /**
     * @dev Reverts if contract is paused.
     */
    modifier whenPaused() {
        if (!_paused) revert PausableNotPaused();
        _;
    }

    /**
     * @dev Called by operator to pause child contract. The contract
     *      must not already be paused.
     */
    function pause() public virtual onlyOperatorOrTraderOrSystem whenNotPaused {
        _paused = true;
        emit Paused(msg.sender);
    }

    /** @dev Called by operator to pause child contract. The contract
     *       must already be paused.
     */
    function unpause() public virtual onlyOperatorOrTraderOrSystem whenPaused {
        _paused = false;
        emit Unpaused(msg.sender);
    }

    /**
     * @return If child contract is already paused or not.
     */
    function isPaused() public view virtual returns (bool) {
        return _paused;
    }

    /**
     * @return If child contract is not paused.
     */
    function isNotPaused() public view virtual returns (bool) {
        return !_paused;
    }
}

/**
 * @title TraderOperatorable
 * @author Team 3301 <[email protected]>
 * @dev TraderOperatorable contract stores TraderOperators contract address, and modifiers for
 *      contracts.
 */

pragma solidity ^0.8.0;

import "../interface/ITraderOperators.sol";
import "../base/Operatorable.sol";
import "../../helpers/Initializable.sol";

contract TraderOperatorable is Operatorable {
    ITraderOperators internal traderOperatorsInst;
    address private traderOperatorsPending;

    /**
     * @dev Error: "TraderOperatorable: caller is not trader"
     */
    error TraderOperatorableCallerNotTrader();

    /**
     * @dev Error: "TraderOperatorable: caller is not trader or operator or system"
     */
    error TraderOperatorableCallerNotTraderOrOperatorOrSystem();

    /**
     * @dev Error: "TraderOperatorable: address of new traderOperators contract can not be zero"
     */
    error TraderOperatorableNewTraderOperatorsAddressZero();

    /**
     * @dev Error: "TraderOperatorable: address of pending traderOperators contract can not be zero"
     */
    error TraderOperatorablePendingTraderOperatorsAddressZero();

    /**
     * @dev Error: "TraderOperatorable: should be called from new traderOperators contract"
     */
    error TraderOperatorableCallerNotNewTraderOperator();

    event TraderOperatorsContractChanged(address indexed caller, address indexed traderOperatorsAddress);
    event TraderOperatorsContractPending(address indexed caller, address indexed traderOperatorsAddress);

    /**
     * @dev Reverts if sender does not have the trader role associated.
     */
    modifier onlyTrader() {
        if (!isTrader(msg.sender)) revert TraderOperatorableCallerNotTrader();
        _;
    }

    /**
     * @dev Reverts if sender does not have the operator or trader role associated.
     */
    modifier onlyOperatorOrTraderOrSystem() {
        if (!isOperator(msg.sender) && !isTrader(msg.sender) && !isSystem(msg.sender))
            revert TraderOperatorableCallerNotTraderOrOperatorOrSystem();
        _;
    }

    /**
     * @dev Initialization instead of constructor, called once. The setTradersOperatorsContract function can be called only by Admin role with
     * confirmation through the operators contract.
     * @param _baseOperators BaseOperators contract address.
     * @param _traderOperators TraderOperators contract address.
     */
    function initialize(address _baseOperators, address _traderOperators) public virtual initializer {
        super.initialize(_baseOperators);
        _setTraderOperatorsContract(_traderOperators);
    }

    /**
     * @dev Set the new the address of Operators contract, should be confirmed from operators contract by calling confirmFor(addr)
     * where addr is the address of current contract instance. This is done to prevent the case when the new contract address is
     * broken and control of the contract can be lost in such case
     * @param _traderOperators TradeOperators contract address.
     */
    function setTraderOperatorsContract(address _traderOperators) public onlyAdmin {
        if (_traderOperators == address(0)) revert TraderOperatorableNewTraderOperatorsAddressZero();

        traderOperatorsPending = _traderOperators;
        emit TraderOperatorsContractPending(msg.sender, _traderOperators);
    }

    /**
     * @dev The function should be called from new operators contract by admin to insure that traderOperatorsPending address
     *       is the real contract address.
     */
    function confirmTraderOperatorsContract() public {
        if (traderOperatorsPending == address(0)) revert TraderOperatorablePendingTraderOperatorsAddressZero();
        if (msg.sender != traderOperatorsPending) revert TraderOperatorableCallerNotNewTraderOperator();

        _setTraderOperatorsContract(traderOperatorsPending);
    }

    /**
     * @return The address of the TraderOperators contract.
     */
    function getTraderOperatorsContract() public view returns (address) {
        return address(traderOperatorsInst);
    }

    /**
     * @return The pending TraderOperators contract address
     */
    function getTraderOperatorsPending() public view returns (address) {
        return traderOperatorsPending;
    }

    /**
     * @return If '_account' has trader privileges.
     */
    function isTrader(address _account) public view returns (bool) {
        return traderOperatorsInst.isTrader(_account);
    }

    /** INTERNAL FUNCTIONS */
    function _setTraderOperatorsContract(address _traderOperators) internal {
        if (_traderOperators == address(0)) revert TraderOperatorableNewTraderOperatorsAddressZero();

        traderOperatorsInst = ITraderOperators(_traderOperators);
        emit TraderOperatorsContractChanged(msg.sender, _traderOperators);
    }
}

/**
 * @title ITraderOperators
 * @notice Interface for TraderOperators contract
 */

pragma solidity ^0.8.0;

abstract contract ITraderOperators {
    function isTrader(address _account) external view virtual returns (bool);

    function addTrader(address _account) external virtual;

    function removeTrader(address _account) external virtual;
}

// SPDX-License-Identifier: UNLICENSED

/**
 * @title Freezable
 * @author Team 3301 <[email protected]>
 * @dev Freezable contract to freeze functionality for particular addresses.  Freezing/unfreezing is controlled
 *       by operators in Operatorable contract which is initialized with the relevant BaseOperators address.
 */

pragma solidity ^0.8.0;

import "../role/base/Operatorable.sol";

contract Freezable is Operatorable {
    mapping(address => bool) public frozen;

    /**
     * @dev Error: "Freezable: Empty address"
     */
    error FreezableZeroAddress();

    /**
     * @dev Error: "Freezable: account is frozen"
     */
    error FreezableAccountFrozen();

    /**
     * @dev Error: "Freezable: account is not frozen"
     */
    error FreezableAccountNotFrozen();

    /**
     * @dev Error: "Freezable: batch count is greater than 256"
     */
    error FreezableBatchCountTooLarge(uint256 _batchCount);

    event FreezeToggled(address indexed account, bool frozen);

    /**
     * @dev Reverts if address is empty.
     * @param _address address to validate.
     */
    modifier onlyValidAddress(address _address) {
        if (_address == address(0)) revert FreezableZeroAddress();
        _;
    }

    /**
     * @dev Reverts if account address is frozen.
     * @param _account address to validate is not frozen.
     */
    modifier whenNotFrozen(address _account) {
        if (frozen[_account]) revert FreezableAccountFrozen();
        _;
    }

    /**
     * @dev Reverts if account address is not frozen.
     * @param _account address to validate is frozen.
     */
    modifier whenFrozen(address _account) {
        if (!frozen[_account]) revert FreezableAccountNotFrozen();
        _;
    }

    /**
     * @dev Getter to determine if address is frozen.
     * @param _account address to determine if frozen or not.
     * @return bool is frozen
     */
    function isFrozen(address _account) public view virtual returns (bool) {
        return frozen[_account];
    }

    /**
     * @dev Toggle freeze/unfreeze on _account address, with _toggled being true/false.
     * @param _account address to toggle.
     * @param _toggled freeze/unfreeze.
     */
    function toggleFreeze(address _account, bool _toggled) public virtual onlyValidAddress(_account) onlyOperator {
        frozen[_account] = _toggled;
        emit FreezeToggled(_account, _toggled);
    }

    /**
     * @dev Batch freeze/unfreeze multiple addresses, with _toggled being true/false.
     * @param _addresses address array.
     * @param _toggled freeze/unfreeze.
     */
    function batchToggleFreeze(address[] memory _addresses, bool _toggled) public virtual {
        if (_addresses.length > 256) revert FreezableBatchCountTooLarge(_addresses.length);

        for (uint256 i = 0; i < _addresses.length; ++i) {
            toggleFreeze(_addresses[i], _toggled);
        }
    }
}

/**
 * @title BlockerOperatorable
 * @author Team 3301 <[email protected]>
 * @dev BlockerOperatorable contract stores BlockerOperators contract address, and modifiers for
 *      contracts.
 */

pragma solidity ^0.8.0;

import "../interface/IBlockerOperators.sol";
import "../base/Operatorable.sol";
import "../../helpers/Initializable.sol";

contract BlockerOperatorable is Operatorable {
    IBlockerOperators internal blockerOperatorsInst;
    address private blockerOperatorsPending;

    /**
     * @dev Error: "BlockerOperatorable: caller is not blocker role"
     */
    error BlockerOperatorableCallerNotBlocker();

    /**
     * @dev Error: "BlockerOperatorable: caller is not blocker or operator role"
     */
    error BlockerOperatorableCallerNotBlockerOrOperator();

    /**
     * @dev Error: "BlockerOperatorable: address of new blockerOperators contract can not be zero."
     */
    error BlockerOperatorableNewBlockerOperatorsAddressZero();

    /**
     * @dev Error: "BlockerOperatorable: address of pending blockerOperators contract can not be zero"
     */
    error BlockerOperatorablePendingBlockerOperatorsAddressZero();

    /**
     * @dev Error: "BlockerOperatorable: should be called from new blockerOperators contract"
     */
    error BlockerOperatorableCallerNotNewBlockerOperator();

    event BlockerOperatorsContractChanged(address indexed caller, address indexed blockerOperatorAddress);
    event BlockerOperatorsContractPending(address indexed caller, address indexed blockerOperatorAddress);

    /**
     * @dev Reverts if sender does not have the blocker role associated.
     */
    modifier onlyBlocker() {
        if (!isBlocker(msg.sender)) revert BlockerOperatorableCallerNotBlocker();
        _;
    }

    /**
     * @dev Reverts if sender does not have the blocker or operator role associated.
     */
    modifier onlyBlockerOrOperator() {
        if (!isBlocker(msg.sender) && !isOperator(msg.sender)) revert BlockerOperatorableCallerNotBlockerOrOperator();
        _;
    }

    /**
     * @dev Initialization instead of constructor, called once. The setBlockerOperatorsContract function can be called only by Admin role with
     * confirmation through the operators contract.
     * @param _baseOperators BaseOperators contract address.
     * @param _blockerOperators BlockerOperators contract address.
     */
    function initialize(address _baseOperators, address _blockerOperators) public virtual initializer {
        super.initialize(_baseOperators);
        _setBlockerOperatorsContract(_blockerOperators);
    }

    /**
     * @dev Set the new the address of BlockerOperators contract, should be confirmed from BlockerOperators contract by calling confirmFor(addr)
     * where addr is the address of current contract instance. This is done to prevent the case when the new contract address is
     * broken and control of the contract can be lost in such case.
     * @param _blockerOperators BlockerOperators contract address.
     */
    function setBlockerOperatorsContract(address _blockerOperators) public onlyAdmin {
        if (_blockerOperators == address(0)) revert BlockerOperatorableNewBlockerOperatorsAddressZero();

        blockerOperatorsPending = _blockerOperators;
        emit BlockerOperatorsContractPending(msg.sender, _blockerOperators);
    }

    /**
     * @dev The function should be called from new BlockerOperators contract by admin to insure that blockerOperatorsPending address
     *       is the real contract address.
     */
    function confirmBlockerOperatorsContract() public {
        if (blockerOperatorsPending == address(0)) revert BlockerOperatorablePendingBlockerOperatorsAddressZero();
        if (msg.sender != blockerOperatorsPending) revert BlockerOperatorableCallerNotNewBlockerOperator();

        _setBlockerOperatorsContract(blockerOperatorsPending);
    }

    /**
     * @return The address of the BlockerOperators contract.
     */
    function getBlockerOperatorsContract() public view returns (address) {
        return address(blockerOperatorsInst);
    }

    /**
     * @return The pending BlockerOperators contract address
     */
    function getBlockerOperatorsPending() public view returns (address) {
        return blockerOperatorsPending;
    }

    /**
     * @return If '_account' has blocker privileges.
     */
    function isBlocker(address _account) public view returns (bool) {
        return blockerOperatorsInst.isBlocker(_account);
    }

    /** INTERNAL FUNCTIONS */
    function _setBlockerOperatorsContract(address _blockerOperators) internal {
        if (_blockerOperators == address(0)) revert BlockerOperatorableNewBlockerOperatorsAddressZero();

        blockerOperatorsInst = IBlockerOperators(_blockerOperators);
        emit BlockerOperatorsContractChanged(msg.sender, _blockerOperators);
    }
}

/**
 * @title IBlockerOperators
 * @notice Interface for BlockerOperators contract
 */

pragma solidity ^0.8.0;

abstract contract IBlockerOperators {
    function isBlocker(address _account) external view virtual returns (bool);

    function addBlocker(address _account) external virtual;

    function removeBlocker(address _account) external virtual;
}

/**
 * @title MetadataUpgrade
 * @author Team 3301 <[email protected]>
 * @dev Upgraded SygnumToken. This upgrade allows system accounts to confiscate tokens.
 */
pragma solidity 0.8.8;

import "./SygnumTokenV1.sol";

contract SygnumTokenV2 is SygnumTokenV1 {
    bool public initializedV2;

    error SygnumTokenV2AlreadyInitialized();

    // changed back to public for tests
    function initializeContractsAndConstructor(
        string memory _name,
        string memory _symbol,
        uint8 _decimals,
        bytes4 _category,
        string memory _class,
        address _issuer,
        address _baseOperators,
        address _whitelist,
        address _traderOperators,
        address _blockerOperators,
        string memory _tokenURI
    ) public virtual override {
        SygnumTokenV1.initializeContractsAndConstructor(
            _name,
            _symbol,
            _decimals,
            _category,
            _class,
            _issuer,
            _baseOperators,
            _whitelist,
            _traderOperators,
            _blockerOperators,
            _tokenURI
        );
        initializeV2();
    }

    function initializeV2() public virtual {
        if (initializedV2) revert SygnumTokenV2AlreadyInitialized();
        initializedV2 = true;
    }

    /**
     * @dev Confiscate.
     * @param _confiscatee Account to confiscate funds from.
     * @param _receiver Account to transfer confiscated funds to.
     * @param _amount Amount of tokens to confiscate.
     */
    function confiscate(
        address _confiscatee,
        address _receiver,
        uint256 _amount
    ) public virtual override onlyOperatorOrSystem {
        super._confiscate(_confiscatee, _receiver, _amount);
        emit Confiscated(_confiscatee, _amount, _receiver);
    }
}

/**
 * @title MetadataUpgrade
 * @author Team 3301 <[email protected]>
 * @dev Upgraded SygnumToken. This upgrade adds the "tokenURI" field, which can hold a link to off chain token metadata.
 */
pragma solidity 0.8.8;

import "../../SygnumToken.sol";

contract SygnumTokenV1 is SygnumToken {
    string public tokenURI;
    bool public initializedV1;

    error SygnumTokenV1AlreadyInitialized();

    event TokenUriUpdated(string newToken);

    // changed back to public for tests
    function initializeContractsAndConstructor(
        string memory _name,
        string memory _symbol,
        uint8 _decimals,
        bytes4 _category,
        string memory _class,
        address _issuer,
        address _baseOperators,
        address _whitelist,
        address _traderOperators,
        address _blockerOperators,
        string memory _tokenURI
    ) public virtual {
        SygnumToken.initializeContractsAndConstructor(
            _name,
            _symbol,
            _decimals,
            _category,
            _class,
            _issuer,
            _baseOperators,
            _whitelist,
            _traderOperators,
            _blockerOperators
        );
        initializeV1(_tokenURI);
    }

    function initializeV1(string memory _tokenURI) public virtual {
        if (initializedV1) revert SygnumTokenV1AlreadyInitialized();

        tokenURI = _tokenURI;
        initializedV1 = true;
    }

    function updateTokenURI(string memory _newToken) public virtual onlyOperator {
        tokenURI = _newToken;
        emit TokenUriUpdated(_newToken);
    }
}