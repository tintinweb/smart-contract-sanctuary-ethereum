// SPDX-License-Identifier: Apache-2.0

pragma solidity ^0.8;

import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/UUPSUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/utils/introspection/ERC165CheckerUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import "./CedarERC721PremintFactory.sol";
import "./drop/CedarERC721DropFactory.sol";
import "./drop/CedarERC1155DropFactory.sol";
import "./paymentSplit/CedarPaymentSplitterFactory.sol";
import "./generated/deploy/BaseCedarDeployerV9.sol";

contract CedarDeployer is Initializable, UUPSUpgradeable, OwnableUpgradeable, BaseCedarDeployerV9 {
    CedarERC721PremintFactory premintFactory;
    CedarERC721DropFactory drop721Factory;
    CedarERC1155DropFactory drop1155Factory;
    CedarPaymentSplitterFactory paymentSplitterFactory;

    using ERC165CheckerUpgradeable for address;

    error IllegalVersionUpgrade(
        uint256 existingMajorVersion,
        uint256 existingMinorVersion,
        uint256 existingPatchVersion,
        uint256 newMajorVersion,
        uint256 newMinorVersion,
        uint256 newPatchVersion
    );

    error ImplementationNotVersioned(address implementation);

    function initialize(
        CedarERC721PremintFactory _premintFactory,
        CedarERC721DropFactory _drop721Factory,
        CedarERC1155DropFactory _drop1155Factory,
        CedarPaymentSplitterFactory _paymentSplitterFactory
    ) public virtual initializer {
        premintFactory = _premintFactory;
        drop721Factory = _drop721Factory;
        drop1155Factory = _drop1155Factory;
        paymentSplitterFactory = _paymentSplitterFactory;

        __Ownable_init();
    }

    function reinitialize(
        CedarERC721PremintFactory _premintFactory,
        CedarERC721DropFactory _drop721Factory,
        CedarERC1155DropFactory _drop1155Factory,
        CedarPaymentSplitterFactory _paymentSplitterFactory
    ) public virtual onlyOwner {
        premintFactory = _premintFactory;
        drop721Factory = _drop721Factory;
        drop1155Factory = _drop1155Factory;
        paymentSplitterFactory = _paymentSplitterFactory;
    }

    function _authorizeUpgrade(address newImplementation) internal view override onlyOwner {
        (uint256 major, uint256 minor, uint256 patch) = this.implementationVersion();
        if (!newImplementation.supportsInterface(type(ICedarVersionedV0).interfaceId)) {
            revert ImplementationNotVersioned(newImplementation);
        }
        (uint256 newMajor, uint256 newMinor, uint256 newPatch) = ICedarVersionedV0(newImplementation)
            .implementationVersion();
        // Do not permit a breaking change via an UUPS proxy upgrade - this requires a new proxy. Otherwise, only allow
        // minor/patch versions to increase
        if (major != newMajor || minor > newMinor || (minor == newMinor && patch > newPatch)) {
            revert IllegalVersionUpgrade(major, minor, patch, newMajor, newMinor, newPatch);
        }
    }

    function deployCedarERC721PremintV2(
        address adminAddress,
        string memory _name,
        string memory _symbol,
        uint256 _maxLimit,
        string memory _userAgreement,
        string memory baseURI_
    ) external override returns (ICedarERC721PremintV2) {
        CedarERC721Premint newContract = premintFactory.deploy(
            adminAddress,
            _name,
            _symbol,
            _maxLimit,
            _userAgreement,
            baseURI_
        );

        (uint256 major, uint256 minor, uint256 patch) = newContract.implementationVersion();
        string memory interfaceName = newContract.implementationInterfaceName();
        emit CedarInterfaceDeployed(address(newContract), major, minor, patch, interfaceName);
        return newContract;
    }

    function deployCedarERC721DropV5(
        address _defaultAdmin,
        string memory _name,
        string memory _symbol,
        string memory _contractURI,
        address[] memory _trustedForwarders,
        address _saleRecipient,
        address _royaltyRecipient,
        uint128 _royaltyBps,
        string memory _userAgreement,
        uint128 _platformFeeBps,
        address _platformFeeRecipient
    ) external override returns (ICedarERC721DropV6) {
        CedarERC721Drop newContract = drop721Factory.deploy(
            _defaultAdmin,
            _name,
            _symbol,
            _contractURI,
            _trustedForwarders,
            _saleRecipient,
            _royaltyRecipient,
            _royaltyBps,
            _userAgreement,
            _platformFeeBps,
            _platformFeeRecipient
        );

        (uint256 major, uint256 minor, uint256 patch) = newContract.implementationVersion();
        string memory interfaceName = newContract.implementationInterfaceName();
        emit CedarInterfaceDeployed(address(newContract), major, minor, patch, interfaceName);
        return newContract;
    }

    function deployCedarERC1155DropV4(
        address _defaultAdmin,
        string memory _name,
        string memory _symbol,
        string memory _contractURI,
        address[] memory _trustedForwarders,
        address _saleRecipient,
        address _royaltyRecipient,
        uint128 _royaltyBps,
        string memory _userAgreement,
        uint128 _platformFeeBps,
        address _platformFeeRecipient
    ) external override returns (ICedarERC1155DropV4) {
        CedarERC1155Drop newContract = drop1155Factory.deploy(
            _defaultAdmin,
            _name,
            _symbol,
            _contractURI,
            _trustedForwarders,
            _saleRecipient,
            _royaltyRecipient,
            _royaltyBps,
            _userAgreement,
            _platformFeeBps,
            _platformFeeRecipient
        );

        (uint256 major, uint256 minor, uint256 patch) = newContract.implementationVersion();
        string memory interfaceName = newContract.implementationInterfaceName();
        emit CedarInterfaceDeployed(address(newContract), major, minor, patch, interfaceName);
        return newContract;
    }

    function cedarERC721PremintVersion()
        external
        view
        override
        returns (
            uint256 major,
            uint256 minor,
            uint256 patch
        )
    {
        return premintFactory.implementationVersion();
    }

    function cedarERC721DropVersion()
        external
        view
        override
        returns (
            uint256 major,
            uint256 minor,
            uint256 patch
        )
    {
        return drop721Factory.implementationVersion();
    }

    function cedarERC1155DropVersion()
        external
        view
        override
        returns (
            uint256 major,
            uint256 minor,
            uint256 patch
        )
    {
        return drop1155Factory.implementationVersion();
    }

    function cedarERC721PremintFeatures() public view override returns (string[] memory features) {
        return premintFactory.implementation().supportedFeatures();
    }

    function cedarERC721DropFeatures() public view override returns (string[] memory features) {
        return drop721Factory.implementation().supportedFeatures();
    }

    function cedarERC1155DropFeatures() public view override returns (string[] memory features) {
        return drop1155Factory.implementation().supportedFeatures();
    }

    // Concrete implementation semantic version - provided for completeness but not designed to be the point of dispatch
    function minorVersion() public pure virtual override returns (uint256 minor, uint256 patch) {
        minor = 0;
        patch = 0;
    }

    function deployCedarPaymentSplitterV1(address[] memory payees, uint256[] memory shares_)
        external
        override
        returns (ICedarPaymentSplitterV1)
    {
        CedarPaymentSplitter newContract = paymentSplitterFactory.deploy(payees, shares_);
        string memory interfaceName = newContract.implementationInterfaceName();
        (uint256 major, uint256 minor, uint256 patch) = newContract.implementationVersion();
        emit CedarInterfaceDeployed(address(newContract), major, minor, patch, interfaceName);
        return newContract;
    }

    function cedarPaymentSplitterVersion()
        external
        view
        override
        returns (
            uint256 major,
            uint256 minor,
            uint256 patch
        )
    {
        return paymentSplitterFactory.implementationVersion();
    }

    function cedarPaymentSplitterFeatures() external view override returns (string[] memory features) {
        return paymentSplitterFactory.implementation().supportedFeatures();
    }
}

// SPDX-License-Identifier: Apache-2.0

pragma solidity ^0.8;

import "@openzeppelin/contracts/proxy/Clones.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "./SignatureVerifier.sol";
import "./CedarERC721Premint.sol";
import "./api/deploy/ICedarDeployer.sol";

contract CedarERC721PremintFactory is Ownable, ICedarERC721PremintFactoryEventsV0, ICedarImplementationVersionedV0 {
    CedarERC721Premint public implementation;
    address public greenlistManagerAddress;

    constructor(address _greenlistManagerAddress) {
        // Deploy the implementation contract
        greenlistManagerAddress = _greenlistManagerAddress;
        implementation = new CedarERC721Premint();
        implementation.initialize("default", "default", 0, address(0), address(0), "", "");
        (uint256 major, uint256 minor, uint256 patch) = implementation.implementationVersion();
        emit CedarImplementationDeployed(address(implementation), major, minor, patch, "CedarERC721Premint");
    }

    function deploy(
        address adminAddress,
        string memory _name,
        string memory _symbol,
        uint256 _maxLimit,
        string memory _userAgreement,
        string memory baseURI_
    ) external onlyOwner returns (CedarERC721Premint newClone) {
        newClone = CedarERC721Premint(Clones.clone(address(implementation)));
        SignatureVerifier signatureVerifier = new SignatureVerifier(_userAgreement, "_", "_");

        newClone.initialize(
            _name,
            _symbol,
            _maxLimit,
            greenlistManagerAddress,
            address(signatureVerifier),
            _userAgreement,
            baseURI_
        );
        newClone.setGreenlistStatus(false);
        newClone.setTermsStatus(true);
        newClone.transferOwnership(adminAddress);

        (uint256 major, uint256 minor, uint256 patch) = newClone.implementationVersion();
        emit CedarERC721PremintDeployment(
            address(newClone),
            major,
            minor,
            patch,
            adminAddress,
            _name,
            _symbol,
            _maxLimit,
            _userAgreement,
            baseURI_
        );
    }

    function implementationVersion()
    external override
    view
    returns (
        uint256 major,
        uint256 minor,
        uint256 patch
    ) {
        return implementation.implementationVersion();
    }

}

// SPDX-License-Identifier: Apache 2.0

pragma solidity ^0.8;

import "@openzeppelin/contracts/proxy/Clones.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "./CedarERC1155Drop.sol";
import "../api/deploy/ICedarDeployer.sol";
import "../SignatureVerifier.sol";

contract CedarERC1155DropFactory is Ownable, ICedarERC1155DropFactoryEventsV0, ICedarImplementationVersionedV0 {
    /// ===============================================
    ///  ========== State variables - public ==========
    /// ===============================================
    CedarERC1155Drop public implementation;

    /// =============================
    /// ========== Structs ==========
    /// =============================
    struct EventParams {
        address contractAddress;
        uint256 majorVersion;
        uint256 minorVersion;
        uint256 patchVersion;
    }

    constructor() {
        // Deploy the implementation contract and set implementationAddress
        implementation = new CedarERC1155Drop();

        implementation.initialize(
            _msgSender(),
            "default",
            "default",
            "",
            new address[](0),
            address(0),
            address(0),
            0,
            CedarERC1155Drop.FeaturesInput("0", address(0)),
            0,
            address(0)
        );

        (uint256 major, uint256 minor, uint256 patch) = implementation.implementationVersion();
        emit CedarImplementationDeployed(address(implementation), major, minor, patch, "ICedarERC1155DropV1");
    }

    /// ==================================
    /// ========== Public methods ========
    /// ==================================
    function deploy(
        address _defaultAdmin,
        string memory _name,
        string memory _symbol,
        string memory _contractURI,
        address[] memory _trustedForwarders,
        address _saleRecipient,
        address _royaltyRecipient,
        uint128 _royaltyBps,
        string memory _userAgreement,
        uint128 _platformFeeBps,
        address _platformFeeRecipient
    ) external onlyOwner returns (CedarERC1155Drop newClone) {
        newClone = CedarERC1155Drop(Clones.clone(address(implementation)));
        SignatureVerifier signatureVerifier = new SignatureVerifier(_userAgreement, "_", "_");
        CedarERC1155Drop.FeaturesInput memory input = CedarERC1155Drop.FeaturesInput(
            _userAgreement,
            address(signatureVerifier)
        );

        newClone.initialize(
            _defaultAdmin,
            _name,
            _symbol,
            _contractURI,
            _trustedForwarders,
            _saleRecipient,
            _royaltyRecipient,
            _royaltyBps,
            input,
            _platformFeeBps,
            _platformFeeRecipient
        );

        (uint256 major, uint256 minor, uint256 patch) = newClone.implementationVersion();

        EventParams memory params;
        params.contractAddress = address(newClone);
        params.majorVersion = major;
        params.minorVersion = minor;
        params.patchVersion = patch;

        _emitEvent(params);
    }

    /// ===========================
    /// ========== Getters ========
    /// ===========================
    function implementationVersion()
        external
        view
        override
        returns (
            uint256 major,
            uint256 minor,
            uint256 patch
        )
    {
        return implementation.implementationVersion();
    }

    /// ===================================
    /// ========== Private methods ========
    /// ===================================
    function _emitEvent(EventParams memory params) private {
        emit CedarERC1155DropV2Deployment(
            params.contractAddress,
            params.majorVersion,
            params.minorVersion,
            params.patchVersion
        );
    }
}

// SPDX-License-Identifier: Apache 2.0

pragma solidity ^0.8;

import "@openzeppelin/contracts/proxy/Clones.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "./CedarERC721Drop.sol";
import "../api/deploy/ICedarDeployer.sol";
import "../SignatureVerifier.sol";

contract CedarERC721DropFactory is Ownable, ICedarERC721DropFactoryEventsV0, ICedarImplementationVersionedV0 {
    /// ===============================================
    ///  ========== State variables - public ==========
    /// ===============================================
    CedarERC721Drop public implementation;

    /// =============================
    /// ========== Structs ==========
    /// =============================
    struct EventParams {
        address contractAddress;
        uint256 majorVersion;
        uint256 minorVersion;
        uint256 patchVersion;
    }

    constructor() {
        implementation = new CedarERC721Drop();

        implementation.initialize(
            _msgSender(),
            "default",
            "default",
            "",
            new address[](0),
            address(0),
            address(0),
            0,
            CedarERC721Drop.FeaturesInput("0", address(0)),
            0,
            address(0)
        );
        (uint256 major, uint256 minor, uint256 patch) = implementation.implementationVersion();
        emit CedarImplementationDeployed(address(implementation), major, minor, patch, "ICedarERC721DropV3");
    }

    /// ==================================
    /// ========== Public methods ========
    /// ==================================
    function deploy(
        address _defaultAdmin,
        string memory _name,
        string memory _symbol,
        string memory _contractURI,
        address[] memory _trustedForwarders,
        address _saleRecipient,
        address _royaltyRecipient,
        uint128 _royaltyBps,
        string memory _userAgreement,
        uint128 _platformFeeBps,
        address _platformFeeRecipient
    ) external onlyOwner returns (CedarERC721Drop newClone) {
        newClone = CedarERC721Drop(Clones.clone(address(implementation)));
        SignatureVerifier signatureVerifier = new SignatureVerifier(_userAgreement, "_", "_");
        CedarERC721Drop.FeaturesInput memory input = CedarERC721Drop.FeaturesInput(
            _userAgreement,
            address(signatureVerifier)
        );

        newClone.initialize(
            _defaultAdmin,
            _name,
            _symbol,
            _contractURI,
            _trustedForwarders,
            _saleRecipient,
            _royaltyRecipient,
            _royaltyBps,
            input,
            _platformFeeBps,
            _platformFeeRecipient
        );

        (uint256 major, uint256 minor, uint256 patch) = newClone.implementationVersion();

        EventParams memory params;
        params.contractAddress = address(newClone);
        params.majorVersion = major;
        params.minorVersion = minor;
        params.patchVersion = patch;

        _emitEvent(params);
    }

    /// ===========================
    /// ========== Getters ========
    /// ===========================
    function implementationVersion()
        external
        view
        override
        returns (
            uint256 major,
            uint256 minor,
            uint256 patch
        )
    {
        return implementation.implementationVersion();
    }

    /// ===================================
    /// ========== Private methods ========
    /// ===================================
    function _emitEvent(EventParams memory params) private {
        // FIXME[Silas]: this is meant to be an event specific to the drop contract it should have all params
        emit CedarERC721DropV2Deployment(
            params.contractAddress,
            params.majorVersion,
            params.minorVersion,
            params.patchVersion
        );
    }
}

// SPDX-License-Identifier: Apache 2.0

pragma solidity ^0.8;

import "@openzeppelin/contracts/proxy/Clones.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "./CedarPaymentSplitter.sol";
import "../api/deploy/ICedarDeployer.sol";

contract CedarPaymentSplitterFactory is Ownable, ICedarPaymentSplitterEventsV0, ICedarImplementationVersionedV0 {
    CedarPaymentSplitter public implementation;

    struct EventParams {
        address contractAddress;
        uint256 majorVersion;
        uint256 minorVersion;
        uint256 patchVersion;
        address[] payees;
        uint256[] shares;
    }

    constructor() {
        // Deploy the implementation contract and set implementationAddress
        implementation = new CedarPaymentSplitter();
        address[] memory recipients = new address[](1);
        recipients[0] = msg.sender;
        uint256[] memory shares = new uint256[](1);
        shares[0] = 10000;

        implementation.initialize(recipients, shares);

        (uint256 major, uint256 minor, uint256 patch) = implementation.implementationVersion();
        emit CedarImplementationDeployed(address(implementation), major, minor, patch, "CedarPaymentSplitter");
    }

    function emitEvent(EventParams memory params) private {
        emit CedarPaymentSplitterDeployment(
            params.contractAddress,
            params.majorVersion,
            params.minorVersion,
            params.patchVersion,
            params.payees,
            params.shares
        );
    }

    function deploy(address[] memory payees, uint256[] memory shares_)
        external
        onlyOwner
        returns (CedarPaymentSplitter)
    {
        // newClone = PaymentSplitter(Clones.clone(address((implementation)));
        CedarPaymentSplitter newClone = new CedarPaymentSplitter();
        newClone.initialize(payees, shares_);

        (uint256 major, uint256 minor, uint256 patch) = newClone.implementationVersion();

        EventParams memory params;
        params.contractAddress = address(newClone);
        params.majorVersion = major;
        params.minorVersion = minor;
        params.patchVersion = patch;
        params.payees = payees;
        params.shares = shares_;

        emitEvent(params);
        return newClone;
    }

    function implementationVersion()
        external
        view
        override
        returns (
            uint256 major,
            uint256 minor,
            uint256 patch
        )
    {
        return implementation.implementationVersion();
    }
}

// SPDX-License-Identifier: Apache-2.0

// Generated by impl.ts. Will be overwritten.
// Filename: './BaseCedarDeployerV9.sol'

pragma solidity ^0.8.4;

import "../../api/deploy/ICedarDeployer.sol";

/// Inherit from this base to implement introspection
abstract contract BaseCedarDeployerV9 is ICedarDeployerV9 {
    /// This needs to be public to be callable from initialize via delegatecall
    function minorVersion() virtual override public pure returns (uint256 minor, uint256 patch);

    function implementationVersion() override public pure returns (uint256 major, uint256 minor, uint256 patch) {
        (minor, patch) = minorVersion();
        major = 9;
    }

    function implementationInterfaceName() virtual override public pure returns (string memory interfaceName) {
        interfaceName = "ICedarDeployerV9";
    }

    function supportsInterface(bytes4 interfaceID) virtual override public view returns (bool) {
        return (interfaceID == type(IERC165Upgradeable).interfaceId) || ((interfaceID == type(ICedarDeployerV9).interfaceId) || ((interfaceID == type(ICedarDeployerOwnEventsV0).interfaceId) || (interfaceID == type(ICedarVersionedV1).interfaceId)));
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.5.0) (proxy/utils/Initializable.sol)

pragma solidity ^0.8.0;

import "../../utils/AddressUpgradeable.sol";

/**
 * @dev This is a base contract to aid in writing upgradeable contracts, or any kind of contract that will be deployed
 * behind a proxy. Since proxied contracts do not make use of a constructor, it's common to move constructor logic to an
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
// OpenZeppelin Contracts v4.4.1 (access/Ownable.sol)

pragma solidity ^0.8.0;

import "../utils/ContextUpgradeable.sol";
import "../proxy/utils/Initializable.sol";

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
abstract contract OwnableUpgradeable is Initializable, ContextUpgradeable {
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    /**
     * @dev Initializes the contract setting the deployer as the initial owner.
     */
    function __Ownable_init() internal onlyInitializing {
        __Ownable_init_unchained();
    }

    function __Ownable_init_unchained() internal onlyInitializing {
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

    /**
     * @dev This empty reserved space is put in place to allow future versions to add new
     * variables without shifting down storage in the inheritance chain.
     * See https://docs.openzeppelin.com/contracts/4.x/upgradeable#storage_gaps
     */
    uint256[49] private __gap;
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/introspection/ERC165Checker.sol)

pragma solidity ^0.8.0;

import "./IERC165Upgradeable.sol";

/**
 * @dev Library used to query support of an interface declared via {IERC165}.
 *
 * Note that these functions return the actual result of the query: they do not
 * `revert` if an interface is not supported. It is up to the caller to decide
 * what to do in these cases.
 */
library ERC165CheckerUpgradeable {
    // As per the EIP-165 spec, no interface should ever match 0xffffffff
    bytes4 private constant _INTERFACE_ID_INVALID = 0xffffffff;

    /**
     * @dev Returns true if `account` supports the {IERC165} interface,
     */
    function supportsERC165(address account) internal view returns (bool) {
        // Any contract that implements ERC165 must explicitly indicate support of
        // InterfaceId_ERC165 and explicitly indicate non-support of InterfaceId_Invalid
        return
            _supportsERC165Interface(account, type(IERC165Upgradeable).interfaceId) &&
            !_supportsERC165Interface(account, _INTERFACE_ID_INVALID);
    }

    /**
     * @dev Returns true if `account` supports the interface defined by
     * `interfaceId`. Support for {IERC165} itself is queried automatically.
     *
     * See {IERC165-supportsInterface}.
     */
    function supportsInterface(address account, bytes4 interfaceId) internal view returns (bool) {
        // query support of both ERC165 as per the spec and support of _interfaceId
        return supportsERC165(account) && _supportsERC165Interface(account, interfaceId);
    }

    /**
     * @dev Returns a boolean array where each value corresponds to the
     * interfaces passed in and whether they're supported or not. This allows
     * you to batch check interfaces for a contract where your expectation
     * is that some interfaces may not be supported.
     *
     * See {IERC165-supportsInterface}.
     *
     * _Available since v3.4._
     */
    function getSupportedInterfaces(address account, bytes4[] memory interfaceIds)
        internal
        view
        returns (bool[] memory)
    {
        // an array of booleans corresponding to interfaceIds and whether they're supported or not
        bool[] memory interfaceIdsSupported = new bool[](interfaceIds.length);

        // query support of ERC165 itself
        if (supportsERC165(account)) {
            // query support of each interface in interfaceIds
            for (uint256 i = 0; i < interfaceIds.length; i++) {
                interfaceIdsSupported[i] = _supportsERC165Interface(account, interfaceIds[i]);
            }
        }

        return interfaceIdsSupported;
    }

    /**
     * @dev Returns true if `account` supports all the interfaces defined in
     * `interfaceIds`. Support for {IERC165} itself is queried automatically.
     *
     * Batch-querying can lead to gas savings by skipping repeated checks for
     * {IERC165} support.
     *
     * See {IERC165-supportsInterface}.
     */
    function supportsAllInterfaces(address account, bytes4[] memory interfaceIds) internal view returns (bool) {
        // query support of ERC165 itself
        if (!supportsERC165(account)) {
            return false;
        }

        // query support of each interface in _interfaceIds
        for (uint256 i = 0; i < interfaceIds.length; i++) {
            if (!_supportsERC165Interface(account, interfaceIds[i])) {
                return false;
            }
        }

        // all interfaces supported
        return true;
    }

    /**
     * @notice Query if a contract implements an interface, does not check ERC165 support
     * @param account The address of the contract to query for support of an interface
     * @param interfaceId The interface identifier, as specified in ERC-165
     * @return true if the contract at account indicates support of the interface with
     * identifier interfaceId, false otherwise
     * @dev Assumes that account contains a contract that supports ERC165, otherwise
     * the behavior of this method is undefined. This precondition can be checked
     * with {supportsERC165}.
     * Interface identification is specified in ERC-165.
     */
    function _supportsERC165Interface(address account, bytes4 interfaceId) private view returns (bool) {
        bytes memory encodedParams = abi.encodeWithSelector(IERC165Upgradeable.supportsInterface.selector, interfaceId);
        (bool success, bytes memory result) = account.staticcall{gas: 30000}(encodedParams);
        if (result.length < 32) return false;
        return success && abi.decode(result, (bool));
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.5.0) (proxy/utils/UUPSUpgradeable.sol)

pragma solidity ^0.8.0;

import "../../interfaces/draft-IERC1822Upgradeable.sol";
import "../ERC1967/ERC1967UpgradeUpgradeable.sol";
import "./Initializable.sol";

/**
 * @dev An upgradeability mechanism designed for UUPS proxies. The functions included here can perform an upgrade of an
 * {ERC1967Proxy}, when this contract is set as the implementation behind such a proxy.
 *
 * A security mechanism ensures that an upgrade does not turn off upgradeability accidentally, although this risk is
 * reinstated if the upgrade retains upgradeability but removes the security mechanism, e.g. by replacing
 * `UUPSUpgradeable` with a custom implementation of upgrades.
 *
 * The {_authorizeUpgrade} function must be overridden to include access restriction to the upgrade mechanism.
 *
 * _Available since v4.1._
 */
abstract contract UUPSUpgradeable is Initializable, IERC1822ProxiableUpgradeable, ERC1967UpgradeUpgradeable {
    function __UUPSUpgradeable_init() internal onlyInitializing {
    }

    function __UUPSUpgradeable_init_unchained() internal onlyInitializing {
    }
    /// @custom:oz-upgrades-unsafe-allow state-variable-immutable state-variable-assignment
    address private immutable __self = address(this);

    /**
     * @dev Check that the execution is being performed through a delegatecall call and that the execution context is
     * a proxy contract with an implementation (as defined in ERC1967) pointing to self. This should only be the case
     * for UUPS and transparent proxies that are using the current contract as their implementation. Execution of a
     * function through ERC1167 minimal proxies (clones) would not normally pass this test, but is not guaranteed to
     * fail.
     */
    modifier onlyProxy() {
        require(address(this) != __self, "Function must be called through delegatecall");
        require(_getImplementation() == __self, "Function must be called through active proxy");
        _;
    }

    /**
     * @dev Check that the execution is not being performed through a delegate call. This allows a function to be
     * callable on the implementing contract but not through proxies.
     */
    modifier notDelegated() {
        require(address(this) == __self, "UUPSUpgradeable: must not be called through delegatecall");
        _;
    }

    /**
     * @dev Implementation of the ERC1822 {proxiableUUID} function. This returns the storage slot used by the
     * implementation. It is used to validate that the this implementation remains valid after an upgrade.
     *
     * IMPORTANT: A proxy pointing at a proxiable contract should not be considered proxiable itself, because this risks
     * bricking a proxy that upgrades to it, by delegating to itself until out of gas. Thus it is critical that this
     * function revert if invoked through a proxy. This is guaranteed by the `notDelegated` modifier.
     */
    function proxiableUUID() external view virtual override notDelegated returns (bytes32) {
        return _IMPLEMENTATION_SLOT;
    }

    /**
     * @dev Upgrade the implementation of the proxy to `newImplementation`.
     *
     * Calls {_authorizeUpgrade}.
     *
     * Emits an {Upgraded} event.
     */
    function upgradeTo(address newImplementation) external virtual onlyProxy {
        _authorizeUpgrade(newImplementation);
        _upgradeToAndCallUUPS(newImplementation, new bytes(0), false);
    }

    /**
     * @dev Upgrade the implementation of the proxy to `newImplementation`, and subsequently execute the function call
     * encoded in `data`.
     *
     * Calls {_authorizeUpgrade}.
     *
     * Emits an {Upgraded} event.
     */
    function upgradeToAndCall(address newImplementation, bytes memory data) external payable virtual onlyProxy {
        _authorizeUpgrade(newImplementation);
        _upgradeToAndCallUUPS(newImplementation, data, true);
    }

    /**
     * @dev Function that should revert when `msg.sender` is not authorized to upgrade the contract. Called by
     * {upgradeTo} and {upgradeToAndCall}.
     *
     * Normally, this function will use an xref:access.adoc[access control] modifier such as {Ownable-onlyOwner}.
     *
     * ```solidity
     * function _authorizeUpgrade(address) internal override onlyOwner {}
     * ```
     */
    function _authorizeUpgrade(address newImplementation) internal virtual;

    /**
     * @dev This empty reserved space is put in place to allow future versions to add new
     * variables without shifting down storage in the inheritance chain.
     * See https://docs.openzeppelin.com/contracts/4.x/upgradeable#storage_gaps
     */
    uint256[50] private __gap;
}

// SPDX-License-Identifier: Apache-2.0

pragma solidity ^0.8;

import "@openzeppelin/contracts/utils/cryptography/ECDSA.sol";
import "@openzeppelin/contracts/utils/cryptography/draft-EIP712.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
/**
 * @title Signature Verifier
 * @notice The contract used to verify offchain signatures against a message digest.
 * @author Monax Labs
 */
contract SignatureVerifier is EIP712, Ownable {
    /* ========== CONSTANTS ========== */

    bytes32 public constant MESSSAGE_HASH = keccak256("AgreeTerms(string url,string message)");

    /* ========== STATE VARIABLES ========== */

    struct AgreeTerms {
        string url;
        string message;
    }

    AgreeTerms public terms;

    /* ========== CONSTRUCTOR ========== */

    /// @dev The constructor sets the URL and message that is signed offchain by FIAT/FREE users. It is stored so that this contract can verify their signature for accepting terms.
    constructor(
        string memory _url,
        string memory _message,
        string memory _name
    ) EIP712(_name, "1.0.0") {
        require(bytes(_url).length != 0 && bytes(_message).length != 0, "Signature Verifier: invalid url and message");
        terms.url = _url;
        terms.message = _message;
    }

    /// @notice verifies a signature
    /// @dev this function takes the signers address and the signature signed with their private key. ECDSA checks whether a hash of the message was signed by the user's private key. If yes, the _to address == ECDSA's returned address
    function verifySignature(address _to, bytes memory _signature) external view returns (bool) {
        if (_signature.length == 0) return false;
        bytes32 hash = _hashMessage();
        address signer = ECDSA.recover(hash, _signature);
        return signer == _to;
    }

    /// @dev this function hashes the terms url and message
    function _hashMessage() private view returns (bytes32) {
        return
            _hashTypedDataV4(
                keccak256(abi.encode(MESSSAGE_HASH, keccak256(bytes(terms.url)), keccak256(bytes(terms.message))))
            );
    }
}

// SPDX-License-Identifier: Apache-2.0

pragma solidity ^0.8;

import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import "@openzeppelin/contracts/utils/Address.sol";
import "@openzeppelin/contracts/utils/Strings.sol";
import "@openzeppelin/contracts/utils/Multicall.sol";
import "@openzeppelin/contracts/token/common/ERC2981.sol";
import "erc721a-upgradeable/contracts/ERC721AUpgradeable.sol";
import "./Agreement.sol";
import "./Greenlist.sol";
import "./generated/impl/BaseCedarERC721PremintV2.sol";

/**
 * @title ERC721 Cedar contract
 * @notice The contract supports preminting and distribution. It supports user terms and checks the greenlist status before transfer
 * @author Monax Labs
 */
contract CedarERC721Premint is
OwnableUpgradeable,
ERC721AUpgradeable,
ERC2981,
Greenlist,
Agreement,
Multicall,
BaseCedarERC721PremintV2
{
    using Address for address;
    using Strings for uint256;

    /* ========== STATE VARIABLES ========== */

    uint256 maxLimit;
    uint256 tokenId;
    uint64 maxMintPerBatch;
    uint64 preMintMaxPerBatch;
    string public baseURI;

    event TransferOwnership(address _address);
    event TokenMinted(uint256 tokenId, uint96 tierId, address receiver);
    event BaseURI(string baseURI);
    event MaxLimit(uint256 maxLimit);
    event PreMintMaxPerBatch(uint64 preMintMaxPerBatch);
    event Received(address sender, uint256 value);

    /* ========== Initializer ========== */
    function initialize(
        string memory _name,
        string memory _symbol,
        uint256 _maxLimit,
        address _greenlistManagerAddress,
        address _signatureVerifier,
        string memory _userAgreement,
        string memory baseURI_
    ) external initializer {
        __ERC721A_init(_name, _symbol);
        __Ownable_init();
        __Agreement_init(_userAgreement, _signatureVerifier);
        __Greenlist_init(_greenlistManagerAddress);

        maxLimit = _maxLimit;
        baseURI = baseURI_;
    }

    /// @notice batch mints tokens for a specified tier and transfer to Owner
    /// @dev This function mints 200 tokens per batch up to maxLimit. It sets the tier ID for the token ID and returns an array of the token IDs.
    function mintBatch(uint256 _quantity, address _to) external override onlyOwner {
        require(
            _totalMinted() + _quantity <= maxLimit,
            "CedarERC721Premint: max limit exceeded, reverting batch call"
        );
        _mint(_to, _quantity);
        tokenId += _quantity;
    }

    function transferFromBatch(TransferRequest[] calldata transferRequests) external override onlyOwner {
        for (uint256 i; i < transferRequests.length; i++) {
            transferFrom(_msgSender(), transferRequests[i].to, transferRequests[i].tokenId);
        }
    }

    /// @dev this function sets the max limit in the collection
    function setMaxLimit(uint256 _maxLimit) external onlyOwner {
        maxLimit = _maxLimit;
        emit MaxLimit(_maxLimit);
    }

    function setRoyalties(address _receiver, uint96 _feeNumerator) external onlyOwner {
        _setDefaultRoyalty(_receiver, _feeNumerator);
    }

    function deleteRoyalties() external onlyOwner {
        _deleteDefaultRoyalty();
    }

    /**
    @dev _beforeTokenTransfer
    Hook that is called before any token transfer. This includes minting and burning.
    Hook will check transfers after mint.
    It checks whether the terms are activated, if yes check whether the caller is a contract.
    If yes, check the greenlist and if the greenlist is activated, check whether the caller is an approved caller.
    If yes, check whether the Transferee has accepted the terms.
    If terms are not activated, check the greenlist.
    */

    function _beforeTokenTransfers(
        address _from,
        address _to,
        uint256 _tokenId,
        uint256 _quantity
    ) internal virtual override(ERC721AUpgradeable) {
        super._beforeTokenTransfers(_from, _to, _tokenId, _quantity);
        if (_to != owner()) {
            address caller = getCaller();
            if (termsActivated) {
                require(
                    termsAccepted[_to],
                    string(
                        abi.encodePacked(
                            "CedarERC721Premint: Receiver address has not accepted the collection's terms of use at ",
                            userAgreement
                        )
                    )
                );
            }
            checkGreenlist(caller);
        }
    }

    /// @dev this function returns the address for the *direct* caller of this contract.
    function getCaller() internal view returns (address _caller) {
        assembly {
            _caller := caller()
        }
    }

    /// @notice upgrades the baseURI
    /// @dev this function upgrades the baseURI. All token metadata is stored in the baseURI as a JSON
    function upgradeBaseURI(string calldata baseURI_) external override onlyOwner {
        baseURI = baseURI_;
    }

    /// @dev this function returns the baseURI
    function _baseURI() internal view virtual override returns (string memory) {
        return baseURI;
    }

    /// @notice gets token URI
    /// @dev this function overrides the ERC721 tokenURI function. It returns the URI as `${baseURI}/${tokenId}`
    function tokenURI(uint256 _tokenId) public view virtual override returns (string memory) {
        require(_exists(_tokenId), "ERC721Metadata: URI query for nonexistent token");

        string memory base = _baseURI();
        return bytes(base).length > 0 ? string(abi.encodePacked(base, "/", _tokenId.toString())) : "";
    }

    /* ========== VIEWS ========== */
    // The following functions are overrides required by Solidity.

    function supportsInterface(bytes4 interfaceId)
    public
    view
    override(BaseCedarERC721PremintV2, ERC721AUpgradeable, ERC2981)
    returns (bool)
    {
        return ERC721AUpgradeable.supportsInterface(interfaceId);
    }

    // Concrete implementation semantic version - provided for completeness but not designed to be the point of dispatch
    function minorVersion() public pure override returns (uint256 minor, uint256 patch) {
        minor = 0;
        patch = 0;
    }

    function multicall(bytes[] calldata data)
    external
    override(Multicall, IMulticallableV0)
    returns (bytes[] memory results)
    {
        return Multicall(this).multicall(data);
    }

    // Agreement

    /// @notice activates the terms
    /// @dev this function activates the user terms
    function setTermsStatus(bool _status) external virtual override onlyOwner {
        _setTermsStatus(_status);
    }

    /// @notice switch on / off the greenlist
    /// @dev this function will allow only Aspen's asset proxy to transfer tokens
    function setGreenlistStatus(bool _status) external virtual onlyOwner {
        _setGreenlistStatus(_status);
    }

    /// @notice stores terms accepted from a signed message
    /// @dev this function is for acceptors that have signed a message offchain to accept the terms. The function calls the verifier contract to valid the signature before storing acceptance.
    function storeTermsAccepted(address _acceptor, bytes calldata _signature) external override virtual onlyOwner {
        _storeTermsAccepted(_acceptor, _signature);
    }
}

// SPDX-License-Identifier: Apache-2.0

pragma solidity ^0.8;

import "../impl/ICedarERC721Premint.sol";
import "../impl/ICedarERC721Drop.sol";
import "../impl/ICedarERC1155Drop.sol";
import "../impl/ICedarPaymentSplitter.sol";

// Events deployed by CedarDeployer directly (not by factories)
interface ICedarDeployerOwnEventsV0 {
    event CedarInterfaceDeployed(
        address indexed contractAddress,
        uint256 indexed majorVersion,
        uint256 indexed minorVersion,
        uint256 patchVersion,
        string interfaceName
    );
}

// Update this interface by bumping the version then updating in-place.
// Previous versions will be immortalised in manifest but do not need to be kept around to clutter
// solidity code
interface ICedarDeployerV9 is ICedarDeployerOwnEventsV0, ICedarVersionedV1 {
    function deployCedarERC721PremintV2(
        address adminAddress,
        string memory _name,
        string memory _symbol,
        uint256 _maxLimit,
        string memory _userAgreement,
        string memory baseURI_
    ) external returns (ICedarERC721PremintV2);

    function deployCedarERC1155DropV4(
        address _defaultAdmin,
        string memory _name,
        string memory _symbol,
        string memory _contractURI,
        address[] memory _trustedForwarders,
        address _saleRecipient,
        address _royaltyRecipient,
        uint128 _royaltyBps,
        string memory _userAgreement,
        uint128 _platformFeeBps,
        address _platformFeeRecipient
    ) external returns (ICedarERC1155DropV4);

    function deployCedarERC721DropV5(
        address _defaultAdmin,
        string memory _name,
        string memory _symbol,
        string memory _contractURI,
        address[] memory _trustedForwarders,
        address _saleRecipient,
        address _royaltyRecipient,
        uint128 _royaltyBps,
        string memory _userAgreement,
        uint128 _platformFeeBps,
        address _platformFeeRecipient
    ) external returns (ICedarERC721DropV6);

    function deployCedarPaymentSplitterV1(address[] memory payees, uint256[] memory shares)
        external
        returns (ICedarPaymentSplitterV1);

    /// Versions

    function cedarERC721PremintVersion()
        external
        view
        returns (
            uint256 major,
            uint256 minor,
            uint256 patch
        );

    function cedarERC721DropVersion()
        external
        view
        returns (
            uint256 major,
            uint256 minor,
            uint256 patch
        );

    function cedarERC1155DropVersion()
        external
        view
        returns (
            uint256 major,
            uint256 minor,
            uint256 patch
        );

    function cedarPaymentSplitterVersion()
        external
        view
        returns (
            uint256 major,
            uint256 minor,
            uint256 patch
        );

    /// Features

    function cedarERC721PremintFeatures() external view returns (string[] memory features);

    function cedarERC721DropFeatures() external view returns (string[] memory features);

    function cedarERC1155DropFeatures() external view returns (string[] memory features);

    function cedarPaymentSplitterFeatures() external view returns (string[] memory features);
}

interface ICedarFactoryEventsV0 {
    // Primarily for the benefit of Etherscan verification
    event CedarImplementationDeployed(
        address indexed implementationAddress,
        uint256 indexed majorVersion,
        uint256 indexed minorVersion,
        uint256 patchVersion,
        string contractName
    );
}

/// Factory specific events (emitted by factories, but included in ICedarDeployer interfaces because they can be
/// expected to be emitted on transactions that call the deploy functions

interface ICedarERC721PremintFactoryEventsV0 is ICedarFactoryEventsV0 {
    event CedarERC721PremintDeployment(
        address indexed contractAddress,
        uint256 indexed majorVersion,
        uint256 indexed minorVersion,
        uint256 patchVersion,
        address adminAddress,
        string name,
        string symbol,
        uint256 maxLimit,
        string userAgreement,
        string baseURI
    );
}

interface ICedarERC721DropFactoryEventsV0 is ICedarFactoryEventsV0 {
    event CedarERC721DropV2Deployment(
        address indexed contractAddress,
        uint256 indexed majorVersion,
        uint256 indexed minorVersion,
        uint256 patchVersion
    );
}

interface ICedarERC1155DropFactoryEventsV0 is ICedarFactoryEventsV0 {
    event CedarERC1155DropV2Deployment(
        address indexed contractAddress,
        uint256 indexed majorVersion,
        uint256 indexed minorVersion,
        uint256 patchVersion
    );
}

interface ICedarPaymentSplitterEventsV0 is ICedarFactoryEventsV0 {
    event CedarPaymentSplitterDeployment(
        address indexed contractAddress,
        uint256 indexed majorVersion,
        uint256 indexed minorVersion,
        uint256 patchVersion,
        address[] payees,
        uint256[] shares
    );
}

interface ICedarDeployerEventsV7 is
    ICedarDeployerOwnEventsV0,
    ICedarERC721PremintFactoryEventsV0,
    ICedarERC721DropFactoryEventsV0,
    ICedarERC1155DropFactoryEventsV0,
    ICedarPaymentSplitterEventsV0
{

}

/// TODO[giorgos]: To be added at a later stage...
//interface ICedarDeployerEventsV6 is ICedarDeployerEventsV4 {
//    /// @dev Unified interface for drop contract deployment through the factory contracts
//    ///     Emitted when the `deploy()` from Factory contracts is called
//    ///     Works for both ERC721 and ERC1155, therefore the name of `NFT` instead of ERC-XXX
//    event CedarNFTDropV1Deployment(
//        address indexed contractAddress,
//        uint256 indexed majorVersion,
//        uint256 indexed minorVersion,
//        uint256 patchVersion,
//        address defaultAdmin,
//        string name,
//        string symbol,
//        string contractURI,
//        address[] trustedForwarders,
//        address saleRecipient,
//        address royaltyRecipient,
//        uint128 royaltyBps,
//        uint128 platformFeeBps,
//        address platformFeeRecipient
//    );
//}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (proxy/Clones.sol)

pragma solidity ^0.8.0;

/**
 * @dev https://eips.ethereum.org/EIPS/eip-1167[EIP 1167] is a standard for
 * deploying minimal proxy contracts, also known as "clones".
 *
 * > To simply and cheaply clone contract functionality in an immutable way, this standard specifies
 * > a minimal bytecode implementation that delegates all calls to a known, fixed address.
 *
 * The library includes functions to deploy a proxy using either `create` (traditional deployment) or `create2`
 * (salted deterministic deployment). It also includes functions to predict the addresses of clones deployed using the
 * deterministic method.
 *
 * _Available since v3.4._
 */
library Clones {
    /**
     * @dev Deploys and returns the address of a clone that mimics the behaviour of `implementation`.
     *
     * This function uses the create opcode, which should never revert.
     */
    function clone(address implementation) internal returns (address instance) {
        assembly {
            let ptr := mload(0x40)
            mstore(ptr, 0x3d602d80600a3d3981f3363d3d373d3d3d363d73000000000000000000000000)
            mstore(add(ptr, 0x14), shl(0x60, implementation))
            mstore(add(ptr, 0x28), 0x5af43d82803e903d91602b57fd5bf30000000000000000000000000000000000)
            instance := create(0, ptr, 0x37)
        }
        require(instance != address(0), "ERC1167: create failed");
    }

    /**
     * @dev Deploys and returns the address of a clone that mimics the behaviour of `implementation`.
     *
     * This function uses the create2 opcode and a `salt` to deterministically deploy
     * the clone. Using the same `implementation` and `salt` multiple time will revert, since
     * the clones cannot be deployed twice at the same address.
     */
    function cloneDeterministic(address implementation, bytes32 salt) internal returns (address instance) {
        assembly {
            let ptr := mload(0x40)
            mstore(ptr, 0x3d602d80600a3d3981f3363d3d373d3d3d363d73000000000000000000000000)
            mstore(add(ptr, 0x14), shl(0x60, implementation))
            mstore(add(ptr, 0x28), 0x5af43d82803e903d91602b57fd5bf30000000000000000000000000000000000)
            instance := create2(0, ptr, 0x37, salt)
        }
        require(instance != address(0), "ERC1167: create2 failed");
    }

    /**
     * @dev Computes the address of a clone deployed using {Clones-cloneDeterministic}.
     */
    function predictDeterministicAddress(
        address implementation,
        bytes32 salt,
        address deployer
    ) internal pure returns (address predicted) {
        assembly {
            let ptr := mload(0x40)
            mstore(ptr, 0x3d602d80600a3d3981f3363d3d373d3d3d363d73000000000000000000000000)
            mstore(add(ptr, 0x14), shl(0x60, implementation))
            mstore(add(ptr, 0x28), 0x5af43d82803e903d91602b57fd5bf3ff00000000000000000000000000000000)
            mstore(add(ptr, 0x38), shl(0x60, deployer))
            mstore(add(ptr, 0x4c), salt)
            mstore(add(ptr, 0x6c), keccak256(ptr, 0x37))
            predicted := keccak256(add(ptr, 0x37), 0x55)
        }
    }

    /**
     * @dev Computes the address of a clone deployed using {Clones-cloneDeterministic}.
     */
    function predictDeterministicAddress(address implementation, bytes32 salt)
        internal
        view
        returns (address predicted)
    {
        return predictDeterministicAddress(implementation, salt, address(this));
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
// OpenZeppelin Contracts (last updated v4.5.0) (utils/cryptography/ECDSA.sol)

pragma solidity ^0.8.0;

import "../Strings.sol";

/**
 * @dev Elliptic Curve Digital Signature Algorithm (ECDSA) operations.
 *
 * These functions can be used to verify that a message was signed by the holder
 * of the private keys of a given address.
 */
library ECDSA {
    enum RecoverError {
        NoError,
        InvalidSignature,
        InvalidSignatureLength,
        InvalidSignatureS,
        InvalidSignatureV
    }

    function _throwError(RecoverError error) private pure {
        if (error == RecoverError.NoError) {
            return; // no error: do nothing
        } else if (error == RecoverError.InvalidSignature) {
            revert("ECDSA: invalid signature");
        } else if (error == RecoverError.InvalidSignatureLength) {
            revert("ECDSA: invalid signature length");
        } else if (error == RecoverError.InvalidSignatureS) {
            revert("ECDSA: invalid signature 's' value");
        } else if (error == RecoverError.InvalidSignatureV) {
            revert("ECDSA: invalid signature 'v' value");
        }
    }

    /**
     * @dev Returns the address that signed a hashed message (`hash`) with
     * `signature` or error string. This address can then be used for verification purposes.
     *
     * The `ecrecover` EVM opcode allows for malleable (non-unique) signatures:
     * this function rejects them by requiring the `s` value to be in the lower
     * half order, and the `v` value to be either 27 or 28.
     *
     * IMPORTANT: `hash` _must_ be the result of a hash operation for the
     * verification to be secure: it is possible to craft signatures that
     * recover to arbitrary addresses for non-hashed data. A safe way to ensure
     * this is by receiving a hash of the original message (which may otherwise
     * be too long), and then calling {toEthSignedMessageHash} on it.
     *
     * Documentation for signature generation:
     * - with https://web3js.readthedocs.io/en/v1.3.4/web3-eth-accounts.html#sign[Web3.js]
     * - with https://docs.ethers.io/v5/api/signer/#Signer-signMessage[ethers]
     *
     * _Available since v4.3._
     */
    function tryRecover(bytes32 hash, bytes memory signature) internal pure returns (address, RecoverError) {
        // Check the signature length
        // - case 65: r,s,v signature (standard)
        // - case 64: r,vs signature (cf https://eips.ethereum.org/EIPS/eip-2098) _Available since v4.1._
        if (signature.length == 65) {
            bytes32 r;
            bytes32 s;
            uint8 v;
            // ecrecover takes the signature parameters, and the only way to get them
            // currently is to use assembly.
            assembly {
                r := mload(add(signature, 0x20))
                s := mload(add(signature, 0x40))
                v := byte(0, mload(add(signature, 0x60)))
            }
            return tryRecover(hash, v, r, s);
        } else if (signature.length == 64) {
            bytes32 r;
            bytes32 vs;
            // ecrecover takes the signature parameters, and the only way to get them
            // currently is to use assembly.
            assembly {
                r := mload(add(signature, 0x20))
                vs := mload(add(signature, 0x40))
            }
            return tryRecover(hash, r, vs);
        } else {
            return (address(0), RecoverError.InvalidSignatureLength);
        }
    }

    /**
     * @dev Returns the address that signed a hashed message (`hash`) with
     * `signature`. This address can then be used for verification purposes.
     *
     * The `ecrecover` EVM opcode allows for malleable (non-unique) signatures:
     * this function rejects them by requiring the `s` value to be in the lower
     * half order, and the `v` value to be either 27 or 28.
     *
     * IMPORTANT: `hash` _must_ be the result of a hash operation for the
     * verification to be secure: it is possible to craft signatures that
     * recover to arbitrary addresses for non-hashed data. A safe way to ensure
     * this is by receiving a hash of the original message (which may otherwise
     * be too long), and then calling {toEthSignedMessageHash} on it.
     */
    function recover(bytes32 hash, bytes memory signature) internal pure returns (address) {
        (address recovered, RecoverError error) = tryRecover(hash, signature);
        _throwError(error);
        return recovered;
    }

    /**
     * @dev Overload of {ECDSA-tryRecover} that receives the `r` and `vs` short-signature fields separately.
     *
     * See https://eips.ethereum.org/EIPS/eip-2098[EIP-2098 short signatures]
     *
     * _Available since v4.3._
     */
    function tryRecover(
        bytes32 hash,
        bytes32 r,
        bytes32 vs
    ) internal pure returns (address, RecoverError) {
        bytes32 s = vs & bytes32(0x7fffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff);
        uint8 v = uint8((uint256(vs) >> 255) + 27);
        return tryRecover(hash, v, r, s);
    }

    /**
     * @dev Overload of {ECDSA-recover} that receives the `r and `vs` short-signature fields separately.
     *
     * _Available since v4.2._
     */
    function recover(
        bytes32 hash,
        bytes32 r,
        bytes32 vs
    ) internal pure returns (address) {
        (address recovered, RecoverError error) = tryRecover(hash, r, vs);
        _throwError(error);
        return recovered;
    }

    /**
     * @dev Overload of {ECDSA-tryRecover} that receives the `v`,
     * `r` and `s` signature fields separately.
     *
     * _Available since v4.3._
     */
    function tryRecover(
        bytes32 hash,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) internal pure returns (address, RecoverError) {
        // EIP-2 still allows signature malleability for ecrecover(). Remove this possibility and make the signature
        // unique. Appendix F in the Ethereum Yellow paper (https://ethereum.github.io/yellowpaper/paper.pdf), defines
        // the valid range for s in (301): 0 < s < secp256k1n ÷ 2 + 1, and for v in (302): v ∈ {27, 28}. Most
        // signatures from current libraries generate a unique signature with an s-value in the lower half order.
        //
        // If your library generates malleable signatures, such as s-values in the upper range, calculate a new s-value
        // with 0xFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFEBAAEDCE6AF48A03BBFD25E8CD0364141 - s1 and flip v from 27 to 28 or
        // vice versa. If your library also generates signatures with 0/1 for v instead 27/28, add 27 to v to accept
        // these malleable signatures as well.
        if (uint256(s) > 0x7FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF5D576E7357A4501DDFE92F46681B20A0) {
            return (address(0), RecoverError.InvalidSignatureS);
        }
        if (v != 27 && v != 28) {
            return (address(0), RecoverError.InvalidSignatureV);
        }

        // If the signature is valid (and not malleable), return the signer address
        address signer = ecrecover(hash, v, r, s);
        if (signer == address(0)) {
            return (address(0), RecoverError.InvalidSignature);
        }

        return (signer, RecoverError.NoError);
    }

    /**
     * @dev Overload of {ECDSA-recover} that receives the `v`,
     * `r` and `s` signature fields separately.
     */
    function recover(
        bytes32 hash,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) internal pure returns (address) {
        (address recovered, RecoverError error) = tryRecover(hash, v, r, s);
        _throwError(error);
        return recovered;
    }

    /**
     * @dev Returns an Ethereum Signed Message, created from a `hash`. This
     * produces hash corresponding to the one signed with the
     * https://eth.wiki/json-rpc/API#eth_sign[`eth_sign`]
     * JSON-RPC method as part of EIP-191.
     *
     * See {recover}.
     */
    function toEthSignedMessageHash(bytes32 hash) internal pure returns (bytes32) {
        // 32 is the length in bytes of hash,
        // enforced by the type signature above
        return keccak256(abi.encodePacked("\x19Ethereum Signed Message:\n32", hash));
    }

    /**
     * @dev Returns an Ethereum Signed Message, created from `s`. This
     * produces hash corresponding to the one signed with the
     * https://eth.wiki/json-rpc/API#eth_sign[`eth_sign`]
     * JSON-RPC method as part of EIP-191.
     *
     * See {recover}.
     */
    function toEthSignedMessageHash(bytes memory s) internal pure returns (bytes32) {
        return keccak256(abi.encodePacked("\x19Ethereum Signed Message:\n", Strings.toString(s.length), s));
    }

    /**
     * @dev Returns an Ethereum Signed Typed Data, created from a
     * `domainSeparator` and a `structHash`. This produces hash corresponding
     * to the one signed with the
     * https://eips.ethereum.org/EIPS/eip-712[`eth_signTypedData`]
     * JSON-RPC method as part of EIP-712.
     *
     * See {recover}.
     */
    function toTypedDataHash(bytes32 domainSeparator, bytes32 structHash) internal pure returns (bytes32) {
        return keccak256(abi.encodePacked("\x19\x01", domainSeparator, structHash));
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/cryptography/draft-EIP712.sol)

pragma solidity ^0.8.0;

import "./ECDSA.sol";

/**
 * @dev https://eips.ethereum.org/EIPS/eip-712[EIP 712] is a standard for hashing and signing of typed structured data.
 *
 * The encoding specified in the EIP is very generic, and such a generic implementation in Solidity is not feasible,
 * thus this contract does not implement the encoding itself. Protocols need to implement the type-specific encoding
 * they need in their contracts using a combination of `abi.encode` and `keccak256`.
 *
 * This contract implements the EIP 712 domain separator ({_domainSeparatorV4}) that is used as part of the encoding
 * scheme, and the final step of the encoding to obtain the message digest that is then signed via ECDSA
 * ({_hashTypedDataV4}).
 *
 * The implementation of the domain separator was designed to be as efficient as possible while still properly updating
 * the chain id to protect against replay attacks on an eventual fork of the chain.
 *
 * NOTE: This contract implements the version of the encoding known as "v4", as implemented by the JSON RPC method
 * https://docs.metamask.io/guide/signing-data.html[`eth_signTypedDataV4` in MetaMask].
 *
 * _Available since v3.4._
 */
abstract contract EIP712 {
    /* solhint-disable var-name-mixedcase */
    // Cache the domain separator as an immutable value, but also store the chain id that it corresponds to, in order to
    // invalidate the cached domain separator if the chain id changes.
    bytes32 private immutable _CACHED_DOMAIN_SEPARATOR;
    uint256 private immutable _CACHED_CHAIN_ID;
    address private immutable _CACHED_THIS;

    bytes32 private immutable _HASHED_NAME;
    bytes32 private immutable _HASHED_VERSION;
    bytes32 private immutable _TYPE_HASH;

    /* solhint-enable var-name-mixedcase */

    /**
     * @dev Initializes the domain separator and parameter caches.
     *
     * The meaning of `name` and `version` is specified in
     * https://eips.ethereum.org/EIPS/eip-712#definition-of-domainseparator[EIP 712]:
     *
     * - `name`: the user readable name of the signing domain, i.e. the name of the DApp or the protocol.
     * - `version`: the current major version of the signing domain.
     *
     * NOTE: These parameters cannot be changed except through a xref:learn::upgrading-smart-contracts.adoc[smart
     * contract upgrade].
     */
    constructor(string memory name, string memory version) {
        bytes32 hashedName = keccak256(bytes(name));
        bytes32 hashedVersion = keccak256(bytes(version));
        bytes32 typeHash = keccak256(
            "EIP712Domain(string name,string version,uint256 chainId,address verifyingContract)"
        );
        _HASHED_NAME = hashedName;
        _HASHED_VERSION = hashedVersion;
        _CACHED_CHAIN_ID = block.chainid;
        _CACHED_DOMAIN_SEPARATOR = _buildDomainSeparator(typeHash, hashedName, hashedVersion);
        _CACHED_THIS = address(this);
        _TYPE_HASH = typeHash;
    }

    /**
     * @dev Returns the domain separator for the current chain.
     */
    function _domainSeparatorV4() internal view returns (bytes32) {
        if (address(this) == _CACHED_THIS && block.chainid == _CACHED_CHAIN_ID) {
            return _CACHED_DOMAIN_SEPARATOR;
        } else {
            return _buildDomainSeparator(_TYPE_HASH, _HASHED_NAME, _HASHED_VERSION);
        }
    }

    function _buildDomainSeparator(
        bytes32 typeHash,
        bytes32 nameHash,
        bytes32 versionHash
    ) private view returns (bytes32) {
        return keccak256(abi.encode(typeHash, nameHash, versionHash, block.chainid, address(this)));
    }

    /**
     * @dev Given an already https://eips.ethereum.org/EIPS/eip-712#definition-of-hashstruct[hashed struct], this
     * function returns the hash of the fully encoded EIP712 message for this domain.
     *
     * This hash can be used together with {ECDSA-recover} to obtain the signer of a message. For example:
     *
     * ```solidity
     * bytes32 digest = _hashTypedDataV4(keccak256(abi.encode(
     *     keccak256("Mail(address to,string contents)"),
     *     mailTo,
     *     keccak256(bytes(mailContents))
     * )));
     * address signer = ECDSA.recover(digest, signature);
     * ```
     */
    function _hashTypedDataV4(bytes32 structHash) internal view virtual returns (bytes32) {
        return ECDSA.toTypedDataHash(_domainSeparatorV4(), structHash);
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
// OpenZeppelin Contracts v4.4.1 (utils/Strings.sol)

pragma solidity ^0.8.0;

/**
 * @dev String operations.
 */
library Strings {
    bytes16 private constant _HEX_SYMBOLS = "0123456789abcdef";

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
}

// SPDX-License-Identifier: Apache-2.0

pragma solidity ^0.8;

import "./SignatureVerifier.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "./api/agreement/ICedarAgreement.sol";

abstract contract Agreement is Initializable, ICedarAgreementV0 {
    string public override userAgreement;
    mapping(address => bool) termsAccepted;
    bool public override termsActivated;
    SignatureVerifier public verifier;

    event TermsActive(bool status);
    event AcceptTerms(string userAgreement, address user);

    function __Agreement_init(string memory _userAgreement, address _signatureVerifier) internal onlyInitializing {
        userAgreement = _userAgreement;
        verifier = SignatureVerifier(_signatureVerifier);
    }

    /// @notice activates the terms
    /// @dev this function activates the user terms
    function _setTermsStatus(bool _status) internal virtual {
        termsActivated = _status;
        emit TermsActive(_status);
    }

    /// @notice by signing this transaction, you are confirming that you have read and agreed to the terms of use at `userAgreement`
    /// @dev this function is called by token receivers to accept the terms before token transfer. The contract stores their acceptance
    function acceptTerms() override external {
        require(termsActivated, "Agreement: terms not activated");
        termsAccepted[msg.sender] = true;
        emit AcceptTerms(userAgreement, msg.sender);
    }

    /// @notice stores terms accepted from a signed message
    /// @dev this function is for acceptors that have signed a message offchain to accept the terms. The function calls the verifier contract to valid the signature before storing acceptance.
    function _storeTermsAccepted(address _acceptor, bytes calldata _signature) internal virtual {
        require(termsActivated, "Agreement: terms not activated");
        require(verifier.verifySignature(_acceptor, _signature), "Agreement: signature cannot be verified");
        termsAccepted[_acceptor] = true;
        emit AcceptTerms(userAgreement, _acceptor);
    }

    /// @notice checks whether an account signed the terms
    /// @dev this function calls the signature verifier to check whether the terms were accepted by an EOA.
    function checkSignature(address _account, bytes calldata _signature) external view returns (bool) {
        return verifier.verifySignature(_account, _signature);
    }

    /// @notice returns true / false for whether the account owner accepted terms
    /// @dev this function returns true / false for whether the account accepted the terms.
    function getAgreementStatus(address _address) external override view returns (bool sig) {
        return termsAccepted[_address];
    }
}

// SPDX-License-Identifier: Apache-2.0

pragma solidity ^0.8;

import "@openzeppelin/contracts/utils/Address.sol";

import "./GreenlistManager.sol";

contract Greenlist {
    using Address for address;
    bool greenlistStatus;

    GreenlistManager greenlistManager;

    event GreenlistStatus(bool _status);

    function __Greenlist_init(address _greenlistManagerAddress) internal {
        greenlistManager = GreenlistManager(_greenlistManagerAddress);
    }

    /// @notice switch on / off the greenlist
    /// @dev this function will allow only Aspen's asset proxy to transfer tokens
    function _setGreenlistStatus(bool _status) internal {
        greenlistStatus = _status;
        emit GreenlistStatus(_status);
    }

    /// @notice checks whether greenlist is activated
    /// @dev this function returns true / false for whether greenlist is on / off.
    function isGreenlistOn() public view returns (bool) {
        return greenlistStatus;
    }

    /// @dev this function checks whether the caller is a contract and if the operator is greenlisted
    function checkGreenlist(address _operator) internal view {
        if (Address.isContract(_operator) && isGreenlistOn()) {
            require(greenlistManager.isGreenlisted(_operator), "ERC721Cedar: operator is not greenlisted");
        }
    }
}

// SPDX-License-Identifier: Apache-2.0

// Generated by impl.ts. Will be overwritten.
// Filename: './BaseCedarERC721PremintV2.sol'

pragma solidity ^0.8.4;

import "../../api/impl/ICedarERC721Premint.sol";

/// Inherit from this base to implement introspection
abstract contract BaseCedarERC721PremintV2 is ICedarERC721PremintV2 {
    function supportedFeatures() override public pure returns (string[] memory features) {
        features = new string[](6);
        features[0] = "ICedarFeatures.sol:ICedarFeaturesV0";
        features[1] = "ICedarVersioned.sol:ICedarVersionedV1";
        features[2] = "issuance/ICedarPremint.sol:ICedarPremintV0";
        features[3] = "agreement/ICedarAgreement.sol:ICedarAgreementV0";
        features[4] = "IMulticallable.sol:IMulticallableV0";
        features[5] = "baseURI/ICedarUpgradeBaseURI.sol:ICedarUpgradeBaseURIV0";
    }

    /// This needs to be public to be callable from initialize via delegatecall
    function minorVersion() virtual override public pure returns (uint256 minor, uint256 patch);

    function implementationVersion() override public pure returns (uint256 major, uint256 minor, uint256 patch) {
        (minor, patch) = minorVersion();
        major = 2;
    }

    function implementationInterfaceName() virtual override public pure returns (string memory interfaceName) {
        interfaceName = "ICedarERC721PremintV2";
    }

    function supportsInterface(bytes4 interfaceID) virtual override public view returns (bool) {
        return (interfaceID == type(IERC165Upgradeable).interfaceId) || ((interfaceID == type(ICedarFeaturesV0).interfaceId) || ((interfaceID == type(ICedarVersionedV1).interfaceId) || ((interfaceID == type(ICedarPremintV0).interfaceId) || ((interfaceID == type(ICedarAgreementV0).interfaceId) || ((interfaceID == type(IMulticallableV0).interfaceId) || (interfaceID == type(ICedarUpgradeBaseURIV0).interfaceId))))));
    }

    function isICedarFeaturesV0() override public pure returns (bool) {
        return true;
    }
}

// SPDX-License-Identifier: MIT
// ERC721A Contracts v3.3.0
// Creator: Chiru Labs

pragma solidity ^0.8.4;

import "./IERC721AUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC721/IERC721ReceiverUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/utils/AddressUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/utils/ContextUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/utils/StringsUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/utils/introspection/ERC165Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";

/**
 * @dev Implementation of https://eips.ethereum.org/EIPS/eip-721[ERC721] Non-Fungible Token Standard, including
 * the Metadata extension. Built to optimize for lower gas during batch mints.
 *
 * Assumes serials are sequentially minted starting at _startTokenId() (defaults to 0, e.g. 0, 1, 2, 3..).
 *
 * Assumes that an owner cannot have more than 2**64 - 1 (max value of uint64) of supply.
 *
 * Assumes that the maximum token id cannot exceed 2**256 - 1 (max value of uint256).
 */
contract ERC721AUpgradeable is Initializable, ContextUpgradeable, ERC165Upgradeable, IERC721AUpgradeable {
    using AddressUpgradeable for address;
    using StringsUpgradeable for uint256;

    // The tokenId of the next token to be minted.
    uint256 internal _currentIndex;

    // The number of tokens burned.
    uint256 internal _burnCounter;

    // Token name
    string private _name;

    // Token symbol
    string private _symbol;

    // Mapping from token ID to ownership details
    // An empty struct value does not necessarily mean the token is unowned. See _ownershipOf implementation for details.
    mapping(uint256 => TokenOwnership) internal _ownerships;

    // Mapping owner address to address data
    mapping(address => AddressData) private _addressData;

    // Mapping from token ID to approved address
    mapping(uint256 => address) private _tokenApprovals;

    // Mapping from owner to operator approvals
    mapping(address => mapping(address => bool)) private _operatorApprovals;

    function __ERC721A_init(string memory name_, string memory symbol_) internal onlyInitializing {
        __ERC721A_init_unchained(name_, symbol_);
    }

    function __ERC721A_init_unchained(string memory name_, string memory symbol_) internal onlyInitializing {
        _name = name_;
        _symbol = symbol_;
        _currentIndex = _startTokenId();
    }

    /**
     * To change the starting tokenId, please override this function.
     */
    function _startTokenId() internal view virtual returns (uint256) {
        return 0;
    }

    /**
     * @dev Burned tokens are calculated here, use _totalMinted() if you want to count just minted tokens.
     */
    function totalSupply() public view override returns (uint256) {
        // Counter underflow is impossible as _burnCounter cannot be incremented
        // more than _currentIndex - _startTokenId() times
        unchecked {
            return _currentIndex - _burnCounter - _startTokenId();
        }
    }

    /**
     * Returns the total amount of tokens minted in the contract.
     */
    function _totalMinted() internal view returns (uint256) {
        // Counter underflow is impossible as _currentIndex does not decrement,
        // and it is initialized to _startTokenId()
        unchecked {
            return _currentIndex - _startTokenId();
        }
    }

    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId) public view virtual override(ERC165Upgradeable, IERC165Upgradeable) returns (bool) {
        return
            interfaceId == type(IERC721Upgradeable).interfaceId ||
            interfaceId == type(IERC721MetadataUpgradeable).interfaceId ||
            super.supportsInterface(interfaceId);
    }

    /**
     * @dev See {IERC721-balanceOf}.
     */
    function balanceOf(address owner) public view override returns (uint256) {
        if (owner == address(0)) revert BalanceQueryForZeroAddress();
        return uint256(_addressData[owner].balance);
    }

    /**
     * Returns the number of tokens minted by `owner`.
     */
    function _numberMinted(address owner) internal view returns (uint256) {
        return uint256(_addressData[owner].numberMinted);
    }

    /**
     * Returns the number of tokens burned by or on behalf of `owner`.
     */
    function _numberBurned(address owner) internal view returns (uint256) {
        return uint256(_addressData[owner].numberBurned);
    }

    /**
     * Returns the auxillary data for `owner`. (e.g. number of whitelist mint slots used).
     */
    function _getAux(address owner) internal view returns (uint64) {
        return _addressData[owner].aux;
    }

    /**
     * Sets the auxillary data for `owner`. (e.g. number of whitelist mint slots used).
     * If there are multiple variables, please pack them into a uint64.
     */
    function _setAux(address owner, uint64 aux) internal {
        _addressData[owner].aux = aux;
    }

    /**
     * Gas spent here starts off proportional to the maximum mint batch size.
     * It gradually moves to O(1) as tokens get transferred around in the collection over time.
     */
    function _ownershipOf(uint256 tokenId) internal view returns (TokenOwnership memory) {
        uint256 curr = tokenId;

        unchecked {
            if (_startTokenId() <= curr) if (curr < _currentIndex) {
                TokenOwnership memory ownership = _ownerships[curr];
                if (!ownership.burned) {
                    if (ownership.addr != address(0)) {
                        return ownership;
                    }
                    // Invariant:
                    // There will always be an ownership that has an address and is not burned
                    // before an ownership that does not have an address and is not burned.
                    // Hence, curr will not underflow.
                    while (true) {
                        curr--;
                        ownership = _ownerships[curr];
                        if (ownership.addr != address(0)) {
                            return ownership;
                        }
                    }
                }
            }
        }
        revert OwnerQueryForNonexistentToken();
    }

    /**
     * @dev See {IERC721-ownerOf}.
     */
    function ownerOf(uint256 tokenId) public view override returns (address) {
        return _ownershipOf(tokenId).addr;
    }

    /**
     * @dev See {IERC721Metadata-name}.
     */
    function name() public view virtual override returns (string memory) {
        return _name;
    }

    /**
     * @dev See {IERC721Metadata-symbol}.
     */
    function symbol() public view virtual override returns (string memory) {
        return _symbol;
    }

    /**
     * @dev See {IERC721Metadata-tokenURI}.
     */
    function tokenURI(uint256 tokenId) public view virtual override returns (string memory) {
        if (!_exists(tokenId)) revert URIQueryForNonexistentToken();

        string memory baseURI = _baseURI();
        return bytes(baseURI).length != 0 ? string(abi.encodePacked(baseURI, tokenId.toString())) : '';
    }

    /**
     * @dev Base URI for computing {tokenURI}. If set, the resulting URI for each
     * token will be the concatenation of the `baseURI` and the `tokenId`. Empty
     * by default, can be overriden in child contracts.
     */
    function _baseURI() internal view virtual returns (string memory) {
        return '';
    }

    /**
     * @dev See {IERC721-approve}.
     */
    function approve(address to, uint256 tokenId) public override {
        address owner = ERC721AUpgradeable.ownerOf(tokenId);
        if (to == owner) revert ApprovalToCurrentOwner();

        if (_msgSender() != owner) if(!isApprovedForAll(owner, _msgSender())) {
            revert ApprovalCallerNotOwnerNorApproved();
        }

        _approve(to, tokenId, owner);
    }

    /**
     * @dev See {IERC721-getApproved}.
     */
    function getApproved(uint256 tokenId) public view override returns (address) {
        if (!_exists(tokenId)) revert ApprovalQueryForNonexistentToken();

        return _tokenApprovals[tokenId];
    }

    /**
     * @dev See {IERC721-setApprovalForAll}.
     */
    function setApprovalForAll(address operator, bool approved) public virtual override {
        if (operator == _msgSender()) revert ApproveToCaller();

        _operatorApprovals[_msgSender()][operator] = approved;
        emit ApprovalForAll(_msgSender(), operator, approved);
    }

    /**
     * @dev See {IERC721-isApprovedForAll}.
     */
    function isApprovedForAll(address owner, address operator) public view virtual override returns (bool) {
        return _operatorApprovals[owner][operator];
    }

    /**
     * @dev See {IERC721-transferFrom}.
     */
    function transferFrom(
        address from,
        address to,
        uint256 tokenId
    ) public virtual override {
        _transfer(from, to, tokenId);
    }

    /**
     * @dev See {IERC721-safeTransferFrom}.
     */
    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId
    ) public virtual override {
        safeTransferFrom(from, to, tokenId, '');
    }

    /**
     * @dev See {IERC721-safeTransferFrom}.
     */
    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId,
        bytes memory _data
    ) public virtual override {
        _transfer(from, to, tokenId);
        if (to.isContract()) if(!_checkContractOnERC721Received(from, to, tokenId, _data)) {
            revert TransferToNonERC721ReceiverImplementer();
        }
    }

    /**
     * @dev Returns whether `tokenId` exists.
     *
     * Tokens can be managed by their owner or approved accounts via {approve} or {setApprovalForAll}.
     *
     * Tokens start existing when they are minted (`_mint`),
     */
    function _exists(uint256 tokenId) internal view returns (bool) {
        return _startTokenId() <= tokenId && tokenId < _currentIndex && !_ownerships[tokenId].burned;
    }

    /**
     * @dev Equivalent to `_safeMint(to, quantity, '')`.
     */
    function _safeMint(address to, uint256 quantity) internal {
        _safeMint(to, quantity, '');
    }

    /**
     * @dev Safely mints `quantity` tokens and transfers them to `to`.
     *
     * Requirements:
     *
     * - If `to` refers to a smart contract, it must implement
     *   {IERC721Receiver-onERC721Received}, which is called for each safe transfer.
     * - `quantity` must be greater than 0.
     *
     * Emits a {Transfer} event.
     */
    function _safeMint(
        address to,
        uint256 quantity,
        bytes memory _data
    ) internal {
        uint256 startTokenId = _currentIndex;
        if (to == address(0)) revert MintToZeroAddress();
        if (quantity == 0) revert MintZeroQuantity();

        _beforeTokenTransfers(address(0), to, startTokenId, quantity);

        // Overflows are incredibly unrealistic.
        // balance or numberMinted overflow if current value of either + quantity > 1.8e19 (2**64) - 1
        // updatedIndex overflows if _currentIndex + quantity > 1.2e77 (2**256) - 1
        unchecked {
            _addressData[to].balance += uint64(quantity);
            _addressData[to].numberMinted += uint64(quantity);

            _ownerships[startTokenId].addr = to;
            _ownerships[startTokenId].startTimestamp = uint64(block.timestamp);

            uint256 updatedIndex = startTokenId;
            uint256 end = updatedIndex + quantity;

            if (to.isContract()) {
                do {
                    emit Transfer(address(0), to, updatedIndex);
                    if (!_checkContractOnERC721Received(address(0), to, updatedIndex++, _data)) {
                        revert TransferToNonERC721ReceiverImplementer();
                    }
                } while (updatedIndex < end);
                // Reentrancy protection
                if (_currentIndex != startTokenId) revert();
            } else {
                do {
                    emit Transfer(address(0), to, updatedIndex++);
                } while (updatedIndex < end);
            }
            _currentIndex = updatedIndex;
        }
        _afterTokenTransfers(address(0), to, startTokenId, quantity);
    }

    /**
     * @dev Mints `quantity` tokens and transfers them to `to`.
     *
     * Requirements:
     *
     * - `to` cannot be the zero address.
     * - `quantity` must be greater than 0.
     *
     * Emits a {Transfer} event.
     */
    function _mint(address to, uint256 quantity) internal {
        uint256 startTokenId = _currentIndex;
        if (to == address(0)) revert MintToZeroAddress();
        if (quantity == 0) revert MintZeroQuantity();

        _beforeTokenTransfers(address(0), to, startTokenId, quantity);

        // Overflows are incredibly unrealistic.
        // balance or numberMinted overflow if current value of either + quantity > 1.8e19 (2**64) - 1
        // updatedIndex overflows if _currentIndex + quantity > 1.2e77 (2**256) - 1
        unchecked {
            _addressData[to].balance += uint64(quantity);
            _addressData[to].numberMinted += uint64(quantity);

            _ownerships[startTokenId].addr = to;
            _ownerships[startTokenId].startTimestamp = uint64(block.timestamp);

            uint256 updatedIndex = startTokenId;
            uint256 end = updatedIndex + quantity;

            do {
                emit Transfer(address(0), to, updatedIndex++);
            } while (updatedIndex < end);

            _currentIndex = updatedIndex;
        }
        _afterTokenTransfers(address(0), to, startTokenId, quantity);
    }

    /**
     * @dev Transfers `tokenId` from `from` to `to`.
     *
     * Requirements:
     *
     * - `to` cannot be the zero address.
     * - `tokenId` token must be owned by `from`.
     *
     * Emits a {Transfer} event.
     */
    function _transfer(
        address from,
        address to,
        uint256 tokenId
    ) private {
        TokenOwnership memory prevOwnership = _ownershipOf(tokenId);

        if (prevOwnership.addr != from) revert TransferFromIncorrectOwner();

        bool isApprovedOrOwner = (_msgSender() == from ||
            isApprovedForAll(from, _msgSender()) ||
            getApproved(tokenId) == _msgSender());

        if (!isApprovedOrOwner) revert TransferCallerNotOwnerNorApproved();
        if (to == address(0)) revert TransferToZeroAddress();

        _beforeTokenTransfers(from, to, tokenId, 1);

        // Clear approvals from the previous owner
        _approve(address(0), tokenId, from);

        // Underflow of the sender's balance is impossible because we check for
        // ownership above and the recipient's balance can't realistically overflow.
        // Counter overflow is incredibly unrealistic as tokenId would have to be 2**256.
        unchecked {
            _addressData[from].balance -= 1;
            _addressData[to].balance += 1;

            TokenOwnership storage currSlot = _ownerships[tokenId];
            currSlot.addr = to;
            currSlot.startTimestamp = uint64(block.timestamp);

            // If the ownership slot of tokenId+1 is not explicitly set, that means the transfer initiator owns it.
            // Set the slot of tokenId+1 explicitly in storage to maintain correctness for ownerOf(tokenId+1) calls.
            uint256 nextTokenId = tokenId + 1;
            TokenOwnership storage nextSlot = _ownerships[nextTokenId];
            if (nextSlot.addr == address(0)) {
                // This will suffice for checking _exists(nextTokenId),
                // as a burned slot cannot contain the zero address.
                if (nextTokenId != _currentIndex) {
                    nextSlot.addr = from;
                    nextSlot.startTimestamp = prevOwnership.startTimestamp;
                }
            }
        }

        emit Transfer(from, to, tokenId);
        _afterTokenTransfers(from, to, tokenId, 1);
    }

    /**
     * @dev Equivalent to `_burn(tokenId, false)`.
     */
    function _burn(uint256 tokenId) internal virtual {
        _burn(tokenId, false);
    }

    /**
     * @dev Destroys `tokenId`.
     * The approval is cleared when the token is burned.
     *
     * Requirements:
     *
     * - `tokenId` must exist.
     *
     * Emits a {Transfer} event.
     */
    function _burn(uint256 tokenId, bool approvalCheck) internal virtual {
        TokenOwnership memory prevOwnership = _ownershipOf(tokenId);

        address from = prevOwnership.addr;

        if (approvalCheck) {
            bool isApprovedOrOwner = (_msgSender() == from ||
                isApprovedForAll(from, _msgSender()) ||
                getApproved(tokenId) == _msgSender());

            if (!isApprovedOrOwner) revert TransferCallerNotOwnerNorApproved();
        }

        _beforeTokenTransfers(from, address(0), tokenId, 1);

        // Clear approvals from the previous owner
        _approve(address(0), tokenId, from);

        // Underflow of the sender's balance is impossible because we check for
        // ownership above and the recipient's balance can't realistically overflow.
        // Counter overflow is incredibly unrealistic as tokenId would have to be 2**256.
        unchecked {
            AddressData storage addressData = _addressData[from];
            addressData.balance -= 1;
            addressData.numberBurned += 1;

            // Keep track of who burned the token, and the timestamp of burning.
            TokenOwnership storage currSlot = _ownerships[tokenId];
            currSlot.addr = from;
            currSlot.startTimestamp = uint64(block.timestamp);
            currSlot.burned = true;

            // If the ownership slot of tokenId+1 is not explicitly set, that means the burn initiator owns it.
            // Set the slot of tokenId+1 explicitly in storage to maintain correctness for ownerOf(tokenId+1) calls.
            uint256 nextTokenId = tokenId + 1;
            TokenOwnership storage nextSlot = _ownerships[nextTokenId];
            if (nextSlot.addr == address(0)) {
                // This will suffice for checking _exists(nextTokenId),
                // as a burned slot cannot contain the zero address.
                if (nextTokenId != _currentIndex) {
                    nextSlot.addr = from;
                    nextSlot.startTimestamp = prevOwnership.startTimestamp;
                }
            }
        }

        emit Transfer(from, address(0), tokenId);
        _afterTokenTransfers(from, address(0), tokenId, 1);

        // Overflow not possible, as _burnCounter cannot be exceed _currentIndex times.
        unchecked {
            _burnCounter++;
        }
    }

    /**
     * @dev Approve `to` to operate on `tokenId`
     *
     * Emits a {Approval} event.
     */
    function _approve(
        address to,
        uint256 tokenId,
        address owner
    ) private {
        _tokenApprovals[tokenId] = to;
        emit Approval(owner, to, tokenId);
    }

    /**
     * @dev Internal function to invoke {IERC721Receiver-onERC721Received} on a target contract.
     *
     * @param from address representing the previous owner of the given token ID
     * @param to target address that will receive the tokens
     * @param tokenId uint256 ID of the token to be transferred
     * @param _data bytes optional data to send along with the call
     * @return bool whether the call correctly returned the expected magic value
     */
    function _checkContractOnERC721Received(
        address from,
        address to,
        uint256 tokenId,
        bytes memory _data
    ) private returns (bool) {
        try IERC721ReceiverUpgradeable(to).onERC721Received(_msgSender(), from, tokenId, _data) returns (bytes4 retval) {
            return retval == IERC721ReceiverUpgradeable(to).onERC721Received.selector;
        } catch (bytes memory reason) {
            if (reason.length == 0) {
                revert TransferToNonERC721ReceiverImplementer();
            } else {
                assembly {
                    revert(add(32, reason), mload(reason))
                }
            }
        }
    }

    /**
     * @dev Hook that is called before a set of serially-ordered token ids are about to be transferred. This includes minting.
     * And also called before burning one token.
     *
     * startTokenId - the first token id to be transferred
     * quantity - the amount to be transferred
     *
     * Calling conditions:
     *
     * - When `from` and `to` are both non-zero, `from`'s `tokenId` will be
     * transferred to `to`.
     * - When `from` is zero, `tokenId` will be minted for `to`.
     * - When `to` is zero, `tokenId` will be burned by `from`.
     * - `from` and `to` are never both zero.
     */
    function _beforeTokenTransfers(
        address from,
        address to,
        uint256 startTokenId,
        uint256 quantity
    ) internal virtual {}

    /**
     * @dev Hook that is called after a set of serially-ordered token ids have been transferred. This includes
     * minting.
     * And also called after one token has been burned.
     *
     * startTokenId - the first token id to be transferred
     * quantity - the amount to be transferred
     *
     * Calling conditions:
     *
     * - When `from` and `to` are both non-zero, `from`'s `tokenId` has been
     * transferred to `to`.
     * - When `from` is zero, `tokenId` has been minted for `to`.
     * - When `to` is zero, `tokenId` has been burned by `from`.
     * - `from` and `to` are never both zero.
     */
    function _afterTokenTransfers(
        address from,
        address to,
        uint256 startTokenId,
        uint256 quantity
    ) internal virtual {}

    /**
     * @dev This empty reserved space is put in place to allow future versions to add new
     * variables without shifting down storage in the inheritance chain.
     * See https://docs.openzeppelin.com/contracts/4.x/upgradeable#storage_gaps
     */
    uint256[42] private __gap;
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.5.0) (utils/Address.sol)

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
// OpenZeppelin Contracts (last updated v4.5.0) (utils/Multicall.sol)

pragma solidity ^0.8.0;

import "./Address.sol";

/**
 * @dev Provides a function to batch together multiple calls in a single external call.
 *
 * _Available since v4.1._
 */
abstract contract Multicall {
    /**
     * @dev Receives and executes a batch of function calls on this contract.
     */
    function multicall(bytes[] calldata data) external virtual returns (bytes[] memory results) {
        results = new bytes[](data.length);
        for (uint256 i = 0; i < data.length; i++) {
            results[i] = Address.functionDelegateCall(address(this), data[i]);
        }
        return results;
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.5.0) (token/common/ERC2981.sol)

pragma solidity ^0.8.0;

import "../../interfaces/IERC2981.sol";
import "../../utils/introspection/ERC165.sol";

/**
 * @dev Implementation of the NFT Royalty Standard, a standardized way to retrieve royalty payment information.
 *
 * Royalty information can be specified globally for all token ids via {_setDefaultRoyalty}, and/or individually for
 * specific token ids via {_setTokenRoyalty}. The latter takes precedence over the first.
 *
 * Royalty is specified as a fraction of sale price. {_feeDenominator} is overridable but defaults to 10000, meaning the
 * fee is specified in basis points by default.
 *
 * IMPORTANT: ERC-2981 only specifies a way to signal royalty information and does not enforce its payment. See
 * https://eips.ethereum.org/EIPS/eip-2981#optional-royalty-payments[Rationale] in the EIP. Marketplaces are expected to
 * voluntarily pay royalties together with sales, but note that this standard is not yet widely supported.
 *
 * _Available since v4.5._
 */
abstract contract ERC2981 is IERC2981, ERC165 {
    struct RoyaltyInfo {
        address receiver;
        uint96 royaltyFraction;
    }

    RoyaltyInfo private _defaultRoyaltyInfo;
    mapping(uint256 => RoyaltyInfo) private _tokenRoyaltyInfo;

    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId) public view virtual override(IERC165, ERC165) returns (bool) {
        return interfaceId == type(IERC2981).interfaceId || super.supportsInterface(interfaceId);
    }

    /**
     * @inheritdoc IERC2981
     */
    function royaltyInfo(uint256 _tokenId, uint256 _salePrice)
        external
        view
        virtual
        override
        returns (address, uint256)
    {
        RoyaltyInfo memory royalty = _tokenRoyaltyInfo[_tokenId];

        if (royalty.receiver == address(0)) {
            royalty = _defaultRoyaltyInfo;
        }

        uint256 royaltyAmount = (_salePrice * royalty.royaltyFraction) / _feeDenominator();

        return (royalty.receiver, royaltyAmount);
    }

    /**
     * @dev The denominator with which to interpret the fee set in {_setTokenRoyalty} and {_setDefaultRoyalty} as a
     * fraction of the sale price. Defaults to 10000 so fees are expressed in basis points, but may be customized by an
     * override.
     */
    function _feeDenominator() internal pure virtual returns (uint96) {
        return 10000;
    }

    /**
     * @dev Sets the royalty information that all ids in this contract will default to.
     *
     * Requirements:
     *
     * - `receiver` cannot be the zero address.
     * - `feeNumerator` cannot be greater than the fee denominator.
     */
    function _setDefaultRoyalty(address receiver, uint96 feeNumerator) internal virtual {
        require(feeNumerator <= _feeDenominator(), "ERC2981: royalty fee will exceed salePrice");
        require(receiver != address(0), "ERC2981: invalid receiver");

        _defaultRoyaltyInfo = RoyaltyInfo(receiver, feeNumerator);
    }

    /**
     * @dev Removes default royalty information.
     */
    function _deleteDefaultRoyalty() internal virtual {
        delete _defaultRoyaltyInfo;
    }

    /**
     * @dev Sets the royalty information for a specific token id, overriding the global default.
     *
     * Requirements:
     *
     * - `tokenId` must be already minted.
     * - `receiver` cannot be the zero address.
     * - `feeNumerator` cannot be greater than the fee denominator.
     */
    function _setTokenRoyalty(
        uint256 tokenId,
        address receiver,
        uint96 feeNumerator
    ) internal virtual {
        require(feeNumerator <= _feeDenominator(), "ERC2981: royalty fee will exceed salePrice");
        require(receiver != address(0), "ERC2981: Invalid parameters");

        _tokenRoyaltyInfo[tokenId] = RoyaltyInfo(receiver, feeNumerator);
    }

    /**
     * @dev Resets royalty information for the token id back to the global default.
     */
    function _resetTokenRoyalty(uint256 tokenId) internal virtual {
        delete _tokenRoyaltyInfo[tokenId];
    }
}

// SPDX-License-Identifier: Apache-2.0

pragma solidity ^0.8;

interface ICedarAgreementV0 {
    // Accept legal terms associated with transfer of this NFT
    function acceptTerms() external;

    function userAgreement() external view returns (string memory);

    function termsActivated() external view returns (bool);

    function setTermsStatus(bool _status) external;

    function getAgreementStatus(address _address) external view returns (bool sig);

    function storeTermsAccepted(address _acceptor, bytes calldata _signature) external;
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.5.0) (utils/Address.sol)

pragma solidity ^0.8.1;

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

pragma solidity ^0.8;

import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/UUPSUpgradeable.sol";

/**
 * @title Cedar Operator Manager
 * @notice The contract manages exchange operator contracts and enforces the greenlist.
 * @author Monax Labs
 */

contract GreenlistManager is OwnableUpgradeable, UUPSUpgradeable {
    /* ========== STATE VARIABLES ========== */

    address public operator;

    function initialize() public initializer {
        __Ownable_init();
        __UUPSUpgradeable_init();
    }

    event OperatorAdded(address _address);
    event OperatorDeleted(address _address);

    function _authorizeUpgrade(address newImplementation) internal override onlyOwner {}

    /// @notice add Aspen Operator address
    /// @dev this function adds Aspen's asset proxy contract address.
    function setAspenOperator(address _operator) external onlyOwner {
        operator = _operator;
        emit OperatorAdded(_operator);
    }

    /// @notice delete Aspen Operator
    /// @dev this function will delete the address if Aspen is not greenlisted.
    function deleteAspenOperator(address _address) external onlyOwner {
        delete operator;
        emit OperatorDeleted(_address);
    }

    /// @notice checks whether an operator is greenlisted
    /// @dev this function returns true / false for whether caller contract is greenlisted.
    function isGreenlisted(address _address) public view returns (bool) {
        return (operator == _address);
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/Context.sol)

pragma solidity ^0.8.0;
import "../proxy/utils/Initializable.sol";

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
abstract contract ContextUpgradeable is Initializable {
    function __Context_init() internal onlyInitializing {
    }

    function __Context_init_unchained() internal onlyInitializing {
    }
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes calldata) {
        return msg.data;
    }

    /**
     * @dev This empty reserved space is put in place to allow future versions to add new
     * variables without shifting down storage in the inheritance chain.
     * See https://docs.openzeppelin.com/contracts/4.x/upgradeable#storage_gaps
     */
    uint256[50] private __gap;
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.5.0) (interfaces/draft-IERC1822.sol)

pragma solidity ^0.8.0;

/**
 * @dev ERC1822: Universal Upgradeable Proxy Standard (UUPS) documents a method for upgradeability through a simplified
 * proxy whose upgrades are fully controlled by the current implementation.
 */
interface IERC1822ProxiableUpgradeable {
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
// OpenZeppelin Contracts (last updated v4.5.0) (proxy/ERC1967/ERC1967Upgrade.sol)

pragma solidity ^0.8.2;

import "../beacon/IBeaconUpgradeable.sol";
import "../../interfaces/draft-IERC1822Upgradeable.sol";
import "../../utils/AddressUpgradeable.sol";
import "../../utils/StorageSlotUpgradeable.sol";
import "../utils/Initializable.sol";

/**
 * @dev This abstract contract provides getters and event emitting update functions for
 * https://eips.ethereum.org/EIPS/eip-1967[EIP1967] slots.
 *
 * _Available since v4.1._
 *
 * @custom:oz-upgrades-unsafe-allow delegatecall
 */
abstract contract ERC1967UpgradeUpgradeable is Initializable {
    function __ERC1967Upgrade_init() internal onlyInitializing {
    }

    function __ERC1967Upgrade_init_unchained() internal onlyInitializing {
    }
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
        return StorageSlotUpgradeable.getAddressSlot(_IMPLEMENTATION_SLOT).value;
    }

    /**
     * @dev Stores a new address in the EIP1967 implementation slot.
     */
    function _setImplementation(address newImplementation) private {
        require(AddressUpgradeable.isContract(newImplementation), "ERC1967: new implementation is not a contract");
        StorageSlotUpgradeable.getAddressSlot(_IMPLEMENTATION_SLOT).value = newImplementation;
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
            _functionDelegateCall(newImplementation, data);
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
        if (StorageSlotUpgradeable.getBooleanSlot(_ROLLBACK_SLOT).value) {
            _setImplementation(newImplementation);
        } else {
            try IERC1822ProxiableUpgradeable(newImplementation).proxiableUUID() returns (bytes32 slot) {
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
        return StorageSlotUpgradeable.getAddressSlot(_ADMIN_SLOT).value;
    }

    /**
     * @dev Stores a new address in the EIP1967 admin slot.
     */
    function _setAdmin(address newAdmin) private {
        require(newAdmin != address(0), "ERC1967: new admin is the zero address");
        StorageSlotUpgradeable.getAddressSlot(_ADMIN_SLOT).value = newAdmin;
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
        return StorageSlotUpgradeable.getAddressSlot(_BEACON_SLOT).value;
    }

    /**
     * @dev Stores a new beacon in the EIP1967 beacon slot.
     */
    function _setBeacon(address newBeacon) private {
        require(AddressUpgradeable.isContract(newBeacon), "ERC1967: new beacon is not a contract");
        require(
            AddressUpgradeable.isContract(IBeaconUpgradeable(newBeacon).implementation()),
            "ERC1967: beacon implementation is not a contract"
        );
        StorageSlotUpgradeable.getAddressSlot(_BEACON_SLOT).value = newBeacon;
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
            _functionDelegateCall(IBeaconUpgradeable(newBeacon).implementation(), data);
        }
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-string-}[`functionCall`],
     * but performing a delegate call.
     *
     * _Available since v3.4._
     */
    function _functionDelegateCall(address target, bytes memory data) private returns (bytes memory) {
        require(AddressUpgradeable.isContract(target), "Address: delegate call to non-contract");

        // solhint-disable-next-line avoid-low-level-calls
        (bool success, bytes memory returndata) = target.delegatecall(data);
        return AddressUpgradeable.verifyCallResult(success, returndata, "Address: low-level delegate call failed");
    }

    /**
     * @dev This empty reserved space is put in place to allow future versions to add new
     * variables without shifting down storage in the inheritance chain.
     * See https://docs.openzeppelin.com/contracts/4.x/upgradeable#storage_gaps
     */
    uint256[50] private __gap;
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/StorageSlot.sol)

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
library StorageSlotUpgradeable {
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
        assembly {
            r.slot := slot
        }
    }

    /**
     * @dev Returns an `BooleanSlot` with member `value` located at `slot`.
     */
    function getBooleanSlot(bytes32 slot) internal pure returns (BooleanSlot storage r) {
        assembly {
            r.slot := slot
        }
    }

    /**
     * @dev Returns an `Bytes32Slot` with member `value` located at `slot`.
     */
    function getBytes32Slot(bytes32 slot) internal pure returns (Bytes32Slot storage r) {
        assembly {
            r.slot := slot
        }
    }

    /**
     * @dev Returns an `Uint256Slot` with member `value` located at `slot`.
     */
    function getUint256Slot(bytes32 slot) internal pure returns (Uint256Slot storage r) {
        assembly {
            r.slot := slot
        }
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (proxy/beacon/IBeacon.sol)

pragma solidity ^0.8.0;

/**
 * @dev This is the interface that {BeaconProxy} expects of its beacon.
 */
interface IBeaconUpgradeable {
    /**
     * @dev Must return an address that can be used as a delegate call target.
     *
     * {BeaconProxy} will check that this address is a contract.
     */
    function implementation() external view returns (address);
}

// SPDX-License-Identifier: Apache-2.0

pragma solidity ^0.8;

import "../ICedarFeatures.sol";
import "../IMulticallable.sol";
import "../ICedarVersioned.sol";
import "../issuance/ICedarPremint.sol";
import "../agreement/ICedarAgreement.sol";
import "../baseURI/ICedarUpgradeBaseURI.sol";

// Each CedarERC721 contract should implement a maximal version of the interfaces it supports and should itself carry
// the version major version suffix, in this case CedarERC721V0

interface ICedarERC721PremintV2 is
    ICedarFeaturesV0,
    ICedarVersionedV1,
    ICedarPremintV0,
    ICedarAgreementV0,
    IMulticallableV0,
    ICedarUpgradeBaseURIV0
{

}

// SPDX-License-Identifier: Apache-2.0

pragma solidity ^0.8;

// See https://docs.openzeppelin.com/contracts/4.x/utilities#multicall
interface IMulticallableV0 {
    function multicall(bytes[] calldata data) external returns (bytes[] memory results);
}

// SPDX-License-Identifier: Apache-2.0

pragma solidity ^0.8;

import "@openzeppelin/contracts-upgradeable/utils/introspection/IERC165Upgradeable.sol";

interface ICedarFeaturesV0 is IERC165Upgradeable {
    // Marker interface to make an ERC165 clash less likely
    function isICedarFeaturesV0() external pure returns (bool);

    // List of features that contract supports and may be passed to featureVersion
    function supportedFeatures() external pure returns (string[] memory features);
}

// SPDX-License-Identifier: Apache-2.0

pragma solidity ^0.8;

import "@openzeppelin/contracts-upgradeable/utils/introspection/IERC165Upgradeable.sol";

interface ICedarMinorVersionedV0 {
    function minorVersion() external view returns (uint256 minor, uint256 patch);
}

interface ICedarImplementationVersionedV0 {
    /// @dev Concrete implementation semantic version - provided for completeness but not designed to be the point of dispatch
    function implementationVersion()
    external
    view
    returns (
        uint256 major,
        uint256 minor,
        uint256 patch
    );
}

interface ICedarImplementationVersionedV1 is ICedarImplementationVersionedV0 {
    /// @dev returns the name of the implementation interface such as ICedarERC721DropV3
    /// allows us to reliably emit the correct events
    function implementationInterfaceName() external view returns (string memory interfaceName);
}

interface ICedarVersionedV0 is ICedarImplementationVersionedV0, ICedarMinorVersionedV0, IERC165Upgradeable {
}

// TODO[Silas]: replace all usages of ICedarVersionedV0 with this one
interface ICedarVersionedV1 is ICedarImplementationVersionedV1, ICedarMinorVersionedV0, IERC165Upgradeable {
}

// SPDX-License-Identifier: Apache-2.0

pragma solidity ^0.8;

// Admin-only interfaces for minting then transferring in batches
interface ICedarPremintV0 {
    struct TransferRequest {
        address to;
        uint256 tokenId;
    }

    function mintBatch(uint256 _quantity, address _to) external;

    function transferFromBatch(TransferRequest[] calldata transferRequests) external;
}

// SPDX-License-Identifier: Apache-2.0

pragma solidity ^0.8;

interface ICedarUpgradeBaseURIV0 {
    /**
     *  @notice Lets the owner update base URI
     */
    function upgradeBaseURI(string calldata baseURI_) external;
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
interface IERC165Upgradeable {
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

// SPDX-License-Identifier: MIT
// ERC721A Contracts v3.3.0
// Creator: Chiru Labs

pragma solidity ^0.8.4;

import "@openzeppelin/contracts-upgradeable/token/ERC721/IERC721Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC721/extensions/IERC721MetadataUpgradeable.sol";

/**
 * @dev Interface of an ERC721A compliant contract.
 */
interface IERC721AUpgradeable is IERC721Upgradeable, IERC721MetadataUpgradeable {
    /**
     * The caller must own the token or be an approved operator.
     */
    error ApprovalCallerNotOwnerNorApproved();

    /**
     * The token does not exist.
     */
    error ApprovalQueryForNonexistentToken();

    /**
     * The caller cannot approve to their own address.
     */
    error ApproveToCaller();

    /**
     * The caller cannot approve to the current owner.
     */
    error ApprovalToCurrentOwner();

    /**
     * Cannot query the balance for the zero address.
     */
    error BalanceQueryForZeroAddress();

    /**
     * Cannot mint to the zero address.
     */
    error MintToZeroAddress();

    /**
     * The quantity of tokens minted must be more than zero.
     */
    error MintZeroQuantity();

    /**
     * The token does not exist.
     */
    error OwnerQueryForNonexistentToken();

    /**
     * The caller must own the token or be an approved operator.
     */
    error TransferCallerNotOwnerNorApproved();

    /**
     * The token must be owned by `from`.
     */
    error TransferFromIncorrectOwner();

    /**
     * Cannot safely transfer to a contract that does not implement the ERC721Receiver interface.
     */
    error TransferToNonERC721ReceiverImplementer();

    /**
     * Cannot transfer to the zero address.
     */
    error TransferToZeroAddress();

    /**
     * The token does not exist.
     */
    error URIQueryForNonexistentToken();

    // Compiler will pack this into a single 256bit word.
    struct TokenOwnership {
        // The address of the owner.
        address addr;
        // Keeps track of the start time of ownership with minimal overhead for tokenomics.
        uint64 startTimestamp;
        // Whether the token has been burned.
        bool burned;
    }

    // Compiler will pack this into a single 256bit word.
    struct AddressData {
        // Realistically, 2**64-1 is more than enough.
        uint64 balance;
        // Keeps track of mint count with minimal overhead for tokenomics.
        uint64 numberMinted;
        // Keeps track of burn count with minimal overhead for tokenomics.
        uint64 numberBurned;
        // For miscellaneous variable(s) pertaining to the address
        // (e.g. number of whitelist mint slots used).
        // If there are multiple variables, please pack them into a uint64.
        uint64 aux;
    }

    /**
     * @dev Returns the total amount of tokens stored by the contract.
     * 
     * Burned tokens are calculated here, use `_totalMinted()` if you want to count just minted tokens.
     */
    function totalSupply() external view returns (uint256);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/Strings.sol)

pragma solidity ^0.8.0;

/**
 * @dev String operations.
 */
library StringsUpgradeable {
    bytes16 private constant _HEX_SYMBOLS = "0123456789abcdef";

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
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (token/ERC721/IERC721Receiver.sol)

pragma solidity ^0.8.0;

/**
 * @title ERC721 token receiver interface
 * @dev Interface for any contract that wants to support safeTransfers
 * from ERC721 asset contracts.
 */
interface IERC721ReceiverUpgradeable {
    /**
     * @dev Whenever an {IERC721} `tokenId` token is transferred to this contract via {IERC721-safeTransferFrom}
     * by `operator` from `from`, this function is called.
     *
     * It must return its Solidity selector to confirm the token transfer.
     * If any other value is returned or the interface is not implemented by the recipient, the transfer will be reverted.
     *
     * The selector can be obtained in Solidity with `IERC721.onERC721Received.selector`.
     */
    function onERC721Received(
        address operator,
        address from,
        uint256 tokenId,
        bytes calldata data
    ) external returns (bytes4);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/introspection/ERC165.sol)

pragma solidity ^0.8.0;

import "./IERC165Upgradeable.sol";
import "../../proxy/utils/Initializable.sol";

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
abstract contract ERC165Upgradeable is Initializable, IERC165Upgradeable {
    function __ERC165_init() internal onlyInitializing {
    }

    function __ERC165_init_unchained() internal onlyInitializing {
    }
    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId) public view virtual override returns (bool) {
        return interfaceId == type(IERC165Upgradeable).interfaceId;
    }

    /**
     * @dev This empty reserved space is put in place to allow future versions to add new
     * variables without shifting down storage in the inheritance chain.
     * See https://docs.openzeppelin.com/contracts/4.x/upgradeable#storage_gaps
     */
    uint256[50] private __gap;
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (token/ERC721/IERC721.sol)

pragma solidity ^0.8.0;

import "../../utils/introspection/IERC165Upgradeable.sol";

/**
 * @dev Required interface of an ERC721 compliant contract.
 */
interface IERC721Upgradeable is IERC165Upgradeable {
    /**
     * @dev Emitted when `tokenId` token is transferred from `from` to `to`.
     */
    event Transfer(address indexed from, address indexed to, uint256 indexed tokenId);

    /**
     * @dev Emitted when `owner` enables `approved` to manage the `tokenId` token.
     */
    event Approval(address indexed owner, address indexed approved, uint256 indexed tokenId);

    /**
     * @dev Emitted when `owner` enables or disables (`approved`) `operator` to manage all of its assets.
     */
    event ApprovalForAll(address indexed owner, address indexed operator, bool approved);

    /**
     * @dev Returns the number of tokens in ``owner``'s account.
     */
    function balanceOf(address owner) external view returns (uint256 balance);

    /**
     * @dev Returns the owner of the `tokenId` token.
     *
     * Requirements:
     *
     * - `tokenId` must exist.
     */
    function ownerOf(uint256 tokenId) external view returns (address owner);

    /**
     * @dev Safely transfers `tokenId` token from `from` to `to`, checking first that contract recipients
     * are aware of the ERC721 protocol to prevent tokens from being forever locked.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `tokenId` token must exist and be owned by `from`.
     * - If the caller is not `from`, it must be have been allowed to move this token by either {approve} or {setApprovalForAll}.
     * - If `to` refers to a smart contract, it must implement {IERC721Receiver-onERC721Received}, which is called upon a safe transfer.
     *
     * Emits a {Transfer} event.
     */
    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId
    ) external;

    /**
     * @dev Transfers `tokenId` token from `from` to `to`.
     *
     * WARNING: Usage of this method is discouraged, use {safeTransferFrom} whenever possible.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `tokenId` token must be owned by `from`.
     * - If the caller is not `from`, it must be approved to move this token by either {approve} or {setApprovalForAll}.
     *
     * Emits a {Transfer} event.
     */
    function transferFrom(
        address from,
        address to,
        uint256 tokenId
    ) external;

    /**
     * @dev Gives permission to `to` to transfer `tokenId` token to another account.
     * The approval is cleared when the token is transferred.
     *
     * Only a single account can be approved at a time, so approving the zero address clears previous approvals.
     *
     * Requirements:
     *
     * - The caller must own the token or be an approved operator.
     * - `tokenId` must exist.
     *
     * Emits an {Approval} event.
     */
    function approve(address to, uint256 tokenId) external;

    /**
     * @dev Returns the account approved for `tokenId` token.
     *
     * Requirements:
     *
     * - `tokenId` must exist.
     */
    function getApproved(uint256 tokenId) external view returns (address operator);

    /**
     * @dev Approve or remove `operator` as an operator for the caller.
     * Operators can call {transferFrom} or {safeTransferFrom} for any token owned by the caller.
     *
     * Requirements:
     *
     * - The `operator` cannot be the caller.
     *
     * Emits an {ApprovalForAll} event.
     */
    function setApprovalForAll(address operator, bool _approved) external;

    /**
     * @dev Returns if the `operator` is allowed to manage all of the assets of `owner`.
     *
     * See {setApprovalForAll}
     */
    function isApprovedForAll(address owner, address operator) external view returns (bool);

    /**
     * @dev Safely transfers `tokenId` token from `from` to `to`.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `tokenId` token must exist and be owned by `from`.
     * - If the caller is not `from`, it must be approved to move this token by either {approve} or {setApprovalForAll}.
     * - If `to` refers to a smart contract, it must implement {IERC721Receiver-onERC721Received}, which is called upon a safe transfer.
     *
     * Emits a {Transfer} event.
     */
    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId,
        bytes calldata data
    ) external;
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (token/ERC721/extensions/IERC721Metadata.sol)

pragma solidity ^0.8.0;

import "../IERC721Upgradeable.sol";

/**
 * @title ERC-721 Non-Fungible Token Standard, optional metadata extension
 * @dev See https://eips.ethereum.org/EIPS/eip-721
 */
interface IERC721MetadataUpgradeable is IERC721Upgradeable {
    /**
     * @dev Returns the token collection name.
     */
    function name() external view returns (string memory);

    /**
     * @dev Returns the token collection symbol.
     */
    function symbol() external view returns (string memory);

    /**
     * @dev Returns the Uniform Resource Identifier (URI) for `tokenId` token.
     */
    function tokenURI(uint256 tokenId) external view returns (string memory);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.5.0) (interfaces/IERC2981.sol)

pragma solidity ^0.8.0;

import "./IERC165.sol";

/**
 * @dev Interface for the NFT Royalty Standard.
 *
 * A standardized way to retrieve royalty payment information for non-fungible tokens (NFTs) to enable universal
 * support for royalty payments across all NFT marketplaces and ecosystem participants.
 *
 * _Available since v4.5._
 */
interface IERC2981 is IERC165 {
    /**
     * @dev Returns how much royalty is owed and to whom, based on a sale price that may be denominated in any unit of
     * exchange. The royalty amount is denominated and should be payed in that same unit of exchange.
     */
    function royaltyInfo(uint256 tokenId, uint256 salePrice)
        external
        view
        returns (address receiver, uint256 royaltyAmount);
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

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (interfaces/IERC165.sol)

pragma solidity ^0.8.0;

import "../utils/introspection/IERC165.sol";

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

// SPDX-License-Identifier: Apache 2.0

pragma solidity ^0.8;

import "../ICedarFeatures.sol";
import "../IMulticallable.sol";
import "../ICedarVersioned.sol";
import "../issuance/ICedarSFTIssuance.sol";
import "../lazymint/ICedarLazyMint.sol";
import "../baseURI/ICedarUpdateBaseURI.sol";
import "../standard/IERC1155.sol";
import "../royalties/IRoyalty.sol";
import "../metadata/ICedarSFTMetadata.sol";
import "../metadata/IContractMetadata.sol";
import "../agreement/ICedarAgreement.sol";
import "../primarysale/IPrimarySale.sol";
import "../pausable/ICedarPausable.sol";

interface ICedarERC1155DropV4 is
    ICedarFeaturesV0,
    ICedarVersionedV1,
    IMulticallableV0,
    ICedarSFTIssuanceV2,
    ICedarLazyMintV0,
    ICedarUpdateBaseURIV0,
    IERC1155SupplyV1,
    IRoyaltyV0,
    ICedarMetadataV1,
    ICedarAgreementV0,
    IPrimarySaleV0,
    ICedarPausableV0
{}

// SPDX-License-Identifier: Apache 2.0

pragma solidity ^0.8;

import "../ICedarFeatures.sol";
import "../IMulticallable.sol";
import "../ICedarVersioned.sol";
import "../issuance/ICedarNFTIssuance.sol";
import "../agreement/ICedarAgreement.sol";
import "../lazymint/ICedarLazyMint.sol";
import "../standard/IERC721.sol";
import "../royalties/IRoyalty.sol";
import "../baseURI/ICedarUpdateBaseURI.sol";
import "../metadata/ICedarNFTMetadata.sol";
import "../metadata/IContractMetadata.sol";
import "../primarysale/IPrimarySale.sol";
import "../pausable/ICedarPausable.sol";

// Each CedarERC721 contract should implement a maximal version of the interfaces it supports and should itself carry
// the version major version suffix, in this case CedarERC721V0

interface ICedarERC721DropV6 is
    ICedarFeaturesV0,
    ICedarVersionedV1,
    IMulticallableV0,
    ICedarAgreementV0,
    ICedarNFTIssuanceV3,
    ICedarLazyMintV0,
    IERC721V0,
    IRoyaltyV0,
    ICedarUpdateBaseURIV0,
    ICedarNFTMetadataV1,
    ICedarMetadataV1,
    IPrimarySaleV0,
    ICedarPausableV0
{

}

// SPDX-License-Identifier: Apache 2.0

pragma solidity ^0.8;

import "../ICedarFeatures.sol";
import "../ICedarVersioned.sol";
import "../splitpayment/ICedarSplitPayment.sol";

interface ICedarPaymentSplitterV1 is ICedarFeaturesV0, ICedarVersionedV1, ICedarSplitPaymentV0 {}

// SPDX-License-Identifier: Apache-2.0
pragma solidity ^0.8;

import "./IDropClaimCondition.sol";

/**
 *  Thirdweb's 'Drop' contracts are distribution mechanisms for tokens. The
 *  `DropERC721` contract is a distribution mechanism for ERC721 tokens.
 *
 *  A minter wallet (i.e. holder of `MINTER_ROLE`) can (lazy)mint 'n' tokens
 *  at once by providing a single base URI for all tokens being lazy minted.
 *  The URI for each of the 'n' tokens lazy minted is the provided base URI +
 *  `{tokenId}` of the respective token. (e.g. "ipsf://Qmece.../1").
 *
 *  A minter can choose to lazy mint 'delayed-reveal' tokens. More on 'delayed-reveal'
 *  tokens in [this article](https://blog.thirdweb.com/delayed-reveal-nfts).
 *
 *  A contract admin (i.e. holder of `DEFAULT_ADMIN_ROLE`) can create claim conditions
 *  with non-overlapping time windows, and accounts can claim the tokens according to
 *  restrictions defined in the claim condition that is active at the time of the transaction.
 */

interface ICedarSFTIssuanceV0 is IDropClaimConditionV0 {
    /// @dev Emitted when tokens are claimed.
    event TokensClaimed(
        uint256 indexed claimConditionIndex,
        uint256 indexed tokenId,
        address indexed claimer,
        address receiver,
        uint256 quantityClaimed
    );

    /// @dev Emitted when tokens are issued.
    event TokensIssued(uint256 indexed tokenId, address indexed claimer, address receiver, uint256 quantityClaimed);

    /// @dev Emitted when new claim conditions are set for a token.
    event ClaimConditionsUpdated(uint256 indexed tokenId, ClaimCondition[] claimConditions);

    /**
     *  @notice Lets a contract admin (account with `DEFAULT_ADMIN_ROLE`) set claim conditions.
     *
     *  @param tokenId               The token ID for which to set mint conditions.
     *  @param phases                Claim conditions in ascending order by `startTimestamp`.
     *  @param resetClaimEligibility Whether to reset `limitLastClaimTimestamp` and
     *                               `limitMerkleProofClaim` values when setting new
     *                               claim conditions.
     */
    function setClaimConditions(
        uint256 tokenId,
        ClaimCondition[] calldata phases,
        bool resetClaimEligibility
    ) external;

    /**
     *  @notice Lets an account claim a given quantity of NFTs.
     *
     *  @param receiver                       The receiver of the NFTs to claim.
     *  @param tokenId                       The unique ID of the token to claim.
     *  @param quantity                       The quantity of NFTs to claim.
     *  @param currency                       The currency in which to pay for the claim.
     *  @param pricePerToken                  The price per token to pay for the claim.
     *  @param proofs                         The proof of the claimer's inclusion in the merkle root allowlist
     *                                        of the claim conditions that apply.
     *  @param proofMaxQuantityPerTransaction (Optional) The maximum number of NFTs an address included in an
     *                                        allowlist can claim.
     */
    function claim(
        address receiver,
        uint256 tokenId,
        uint256 quantity,
        address currency,
        uint256 pricePerToken,
        bytes32[] calldata proofs,
        uint256 proofMaxQuantityPerTransaction
    ) external payable;

    /**
     *  @notice Lets an account with ISSUER_ROLE issue NFTs.
     *
     *  @param receiver                       The receiver of the NFTs to claim.
     *  @param tokenId                       The unique ID of the token to claim.
     *  @param quantity                       The quantity of NFTs to claim.
     */
    function issue(
        address receiver,
        uint256 tokenId,
        uint256 quantity
    ) external;
}

interface ICedarSFTIssuanceV1 is ICedarSFTIssuanceV0 {
    /// @dev Expose the current active claim condition including claim limits
    function getActiveClaimConditions(uint256 _tokenId)
        external
        view
        returns (
            ClaimCondition memory condition,
            uint256 conditionId,
            uint256 walletMaxClaimCount,
            uint256 remainingSupply
        );

    /// @dev Expose the user specific limits related to the current active claim condition
    function getUserClaimConditions(uint256 _tokenId, address _claimer)
        external
        view
        returns (
            uint256 conditionId,
            uint256 walletClaimedCount,
            uint256 lastClaimTimestamp,
            uint256 nextValidClaimTimestamp
        );

    /// @dev Checks a request to claim NFTs against the active claim condition's criteria.
    function verifyClaim(
        uint256 _conditionId,
        address _claimer,
        uint256 _tokenId,
        uint256 _quantity,
        address _currency,
        uint256 _pricePerToken,
        bool verifyMaxQuantityPerTransaction
    ) external view;
}

interface ICedarSFTIssuanceV2 is ICedarSFTIssuanceV0 {
    /// @dev Expose the current active claim condition including claim limits
    function getActiveClaimConditions(uint256 _tokenId)
        external
        view
        returns (
            ClaimCondition memory condition,
            uint256 conditionId,
            uint256 walletMaxClaimCount,
            uint256 remainingSupply,
            bool isClaimPaused
        );

    /// @dev Expose the user specific limits related to the current active claim condition
    function getUserClaimConditions(uint256 _tokenId, address _claimer)
        external
        view
        returns (
            uint256 conditionId,
            uint256 walletClaimedCount,
            uint256 walletClaimedCountInPhase,
            uint256 lastClaimTimestamp,
            uint256 nextValidClaimTimestamp
        );

    /// @dev Checks a request to claim NFTs against the active claim condition's criteria.
    function verifyClaim(
        uint256 _conditionId,
        address _claimer,
        uint256 _tokenId,
        uint256 _quantity,
        address _currency,
        uint256 _pricePerToken,
        bool verifyMaxQuantityPerTransaction
    ) external view;
}

// SPDX-License-Identifier: Apache-2.0

pragma solidity ^0.8.4;

interface ICedarLazyMintV0 {
    /// @dev Emitted when tokens are lazy minted.
    event TokensLazyMinted(uint256 startTokenId, uint256 endTokenId, string baseURI);
    
    /**
     *  @notice Lets an account with `MINTER_ROLE` lazy mint 'n' NFTs.
     *          The URIs for each token is the provided `_baseURIForTokens` + `{tokenId}`.
     *
     *  @param amount           The amount of NFTs to lazy mint.
     *  @param baseURIForTokens The URI for the NFTs to lazy mint. If lazy minting
     *                           'delayed-reveal' NFTs, the is a URI for NFTs in the
     *                           un-revealed state.
     */
    function lazyMint(uint256 amount, string calldata baseURIForTokens) external;
}

// SPDX-License-Identifier: Apache-2.0

pragma solidity ^0.8;

interface ICedarUpdateBaseURIV0 {
    /// @dev Emitted when base URI is updated.
    event BaseURIUpdated(uint256 baseURIIndex, string baseURI);

    /**
     *  @notice Lets a minter (account with `MINTER_ROLE`) update base URI
     */
    function updateBaseURI(
        uint256 baseURIIndex, string calldata _baseURIForTokens
    ) external;

    /**
     *  @dev Gets the base URI indices
     */
    function getBaseURIIndices() external view returns(uint256[] memory);
}

// SPDX-License-Identifier: Apache-2.0

pragma solidity ^0.8;

import "@openzeppelin/contracts-upgradeable/token/ERC1155/IERC1155Upgradeable.sol";

interface IERC1155V0 is IERC1155Upgradeable {}

interface IERC1155SupplyV0 is IERC1155V0 {
    /**
     * @dev Total amount of tokens in with a given id.
     */
    function totalSupply(uint256 id) external view returns (uint256);

    /**
     * @dev Indicates whether any token exist with a given id, or not.
     */
    function exists(uint256 id) external view returns (bool);
}

interface IERC1155SupplyV1 is IERC1155SupplyV0 {
    /**
     * @dev Amount of unique tokens minted.
     */
    function getLargestTokenId() external view returns (uint256);
}

// SPDX-License-Identifier: Apache-2.0
pragma solidity ^0.8;

interface ICedarSFTMetadataV1 {
    /// @dev Returns the URI for a given tokenId.
    function uri(uint256 _tokenId) view external returns (string memory);
}

// SPDX-License-Identifier: Apache-2.0
pragma solidity ^0.8;

interface IRoyaltyV0 {
    struct RoyaltyInfo {
        address recipient;
        uint256 bps;
    }

    /// @dev Returns the royalty recipient and fee bps.
    function getDefaultRoyaltyInfo() external view returns (address, uint16);

    /// @dev Lets a module admin update the royalty bps and recipient.
    function setDefaultRoyaltyInfo(address _royaltyRecipient, uint256 _royaltyBps) external;

    /// @dev Lets a module admin set the royalty recipient for a particular token Id.
    function setRoyaltyInfoForToken(
        uint256 tokenId,
        address recipient,
        uint256 bps
    ) external;

    /// @dev Returns the royalty recipient for a particular token Id.
    function getRoyaltyInfoForToken(uint256 tokenId) external view returns (address, uint16);

    /**
     * @dev Returns how much royalty is owed and to whom, based on a sale price that may be denominated in any unit of
     * exchange. The royalty amount is denominated and should be payed in that same unit of exchange.
     */
    function royaltyInfo(uint256 tokenId, uint256 salePrice)
        external
        view
        returns (address receiver, uint256 royaltyAmount);

    /// @dev Emitted when royalty info is updated.
    event DefaultRoyalty(address newRoyaltyRecipient, uint256 newRoyaltyBps);

    /// @dev Emitted when royalty recipient for tokenId is set
    event RoyaltyForToken(uint256 indexed tokenId, address royaltyRecipient, uint256 royaltyBps);
}

// SPDX-License-Identifier: Apache-2.0
pragma solidity ^0.8;

interface ICedarMetadataV1 {
    /// @dev Contract level metadata.
    function contractURI() external view returns (string memory);

    /// @dev Lets a contract admin set the URI for contract-level metadata.
    function setContractURI(string calldata _uri) external;

    /// @dev Emitted when contractURI is updated
    event ContractURIUpdated(address indexed updater, string uri);
}

// SPDX-License-Identifier: Apache-2.0
pragma solidity ^0.8.0;

interface IPrimarySaleV0 {
    /// @dev The adress that receives all primary sales value.
    function primarySaleRecipient() external view returns (address);

    /// @dev Lets a module admin set the default recipient of all primary sales.
    function setPrimarySaleRecipient(address _saleRecipient) external;

    /// @dev Emitted when a new sale recipient is set.
    event PrimarySaleRecipientUpdated(address indexed recipient);
}

interface IPrimarySaleV1 {
    /// @dev The adress that receives all primary sales value.
    function primarySaleRecipient() external view returns (address);

    /// @dev Lets a module admin set the default recipient of all primary sales.
    function setPrimarySaleRecipient(address _saleRecipient) external;

    /// @dev Emitted when a new sale recipient is set.
    event PrimarySaleRecipientUpdated(address indexed recipient, bool frogs);
}

// SPDX-License-Identifier: Apache-2.0
pragma solidity ^0.8;

interface ICedarPausableV0 {
    /// @dev Pause claim functionality.
    function pauseClaims() external;

    /// @dev Un-pause claim functionality.
    function unpauseClaims() external;

    /// @dev Event emitted when claim functionality is paused/un-paused.
    event ClaimPauseStatusUpdated(bool pauseStatus);
}

// SPDX-License-Identifier: Apache-2.0
pragma solidity ^0.8;

import "@openzeppelin/contracts-upgradeable/utils/structs/BitMapsUpgradeable.sol";

/**
 *  Thirdweb's 'Drop' contracts are distribution mechanisms for tokens.
 *
 *  A contract admin (i.e. a holder of `DEFAULT_ADMIN_ROLE`) can set a series of claim conditions,
 *  ordered by their respective `startTimestamp`. A claim condition defines criteria under which
 *  accounts can mint tokens. Claim conditions can be overwritten or added to by the contract admin.
 *  At any moment, there is only one active claim condition.
 */

interface IDropClaimConditionV0 {
    /**
     *  @notice The criteria that make up a claim condition.
     *
     *  @param startTimestamp                 The unix timestamp after which the claim condition applies.
     *                                        The same claim condition applies until the `startTimestamp`
     *                                        of the next claim condition.
     *
     *  @param maxClaimableSupply             The maximum total number of tokens that can be claimed under
     *                                        the claim condition.
     *
     *  @param supplyClaimed                  At any given point, the number of tokens that have been claimed
     *                                        under the claim condition.
     *
     *  @param quantityLimitPerTransaction    The maximum number of tokens that can be claimed in a single
     *                                        transaction.
     *
     *  @param waitTimeInSecondsBetweenClaims The least number of seconds an account must wait after claiming
     *                                        tokens, to be able to claim tokens again.
     *
     *  @param merkleRoot                     The allowlist of addresses that can claim tokens under the claim
     *                                        condition.
     *
     *  @param pricePerToken                  The price required to pay per token claimed.
     *
     *  @param currency                       The currency in which the `pricePerToken` must be paid.
     */
    struct ClaimCondition {
        uint256 startTimestamp;
        uint256 maxClaimableSupply;
        uint256 supplyClaimed;
        uint256 quantityLimitPerTransaction;
        uint256 waitTimeInSecondsBetweenClaims;
        bytes32 merkleRoot;
        uint256 pricePerToken;
        address currency;
    }

    /**
     *  @notice The set of all claim conditions, at any given moment.
     *  Claim Phase ID = [currentStartId, currentStartId + length - 1];
     *
     *  @param currentStartId           The uid for the first claim condition amongst the current set of
     *                                  claim conditions. The uid for each next claim condition is one
     *                                  more than the previous claim condition's uid.
     *
     *  @param count                    The total number of phases / claim conditions in the list
     *                                  of claim conditions.
     *
     *  @param phases                   The claim conditions at a given uid. Claim conditions
     *                                  are ordered in an ascending order by their `startTimestamp`.
     *
     *  @param claimDetails             Map from an account and uid for a claim condition, to the claim
     *                                  records an account has done.
     *
     */
    struct ClaimConditionList {
        uint256 currentStartId;
        uint256 count;
        mapping(uint256 => ClaimCondition) phases;
        mapping(uint256 => mapping(address => ClaimDetails)) userClaims;
    }

    /**
     *  @notice Claim detail for a user claim.
     *
     *  @param lastClaimTimestamp    The timestamp at which the last token was claimed.
     *
     *  @param claimedBalance        The number of tokens claimed.
     *
     */
    struct ClaimDetails {
        uint256 lastClaimTimestamp;
        uint256 claimedBalance;
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/structs/BitMaps.sol)
pragma solidity ^0.8.0;

/**
 * @dev Library for managing uint256 to bool mapping in a compact and efficient way, providing the keys are sequential.
 * Largelly inspired by Uniswap's https://github.com/Uniswap/merkle-distributor/blob/master/contracts/MerkleDistributor.sol[merkle-distributor].
 */
library BitMapsUpgradeable {
    struct BitMap {
        mapping(uint256 => uint256) _data;
    }

    /**
     * @dev Returns whether the bit at `index` is set.
     */
    function get(BitMap storage bitmap, uint256 index) internal view returns (bool) {
        uint256 bucket = index >> 8;
        uint256 mask = 1 << (index & 0xff);
        return bitmap._data[bucket] & mask != 0;
    }

    /**
     * @dev Sets the bit at `index` to the boolean `value`.
     */
    function setTo(
        BitMap storage bitmap,
        uint256 index,
        bool value
    ) internal {
        if (value) {
            set(bitmap, index);
        } else {
            unset(bitmap, index);
        }
    }

    /**
     * @dev Sets the bit at `index`.
     */
    function set(BitMap storage bitmap, uint256 index) internal {
        uint256 bucket = index >> 8;
        uint256 mask = 1 << (index & 0xff);
        bitmap._data[bucket] |= mask;
    }

    /**
     * @dev Unsets the bit at `index`.
     */
    function unset(BitMap storage bitmap, uint256 index) internal {
        uint256 bucket = index >> 8;
        uint256 mask = 1 << (index & 0xff);
        bitmap._data[bucket] &= ~mask;
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (token/ERC1155/IERC1155.sol)

pragma solidity ^0.8.0;

import "../../utils/introspection/IERC165Upgradeable.sol";

/**
 * @dev Required interface of an ERC1155 compliant contract, as defined in the
 * https://eips.ethereum.org/EIPS/eip-1155[EIP].
 *
 * _Available since v3.1._
 */
interface IERC1155Upgradeable is IERC165Upgradeable {
    /**
     * @dev Emitted when `value` tokens of token type `id` are transferred from `from` to `to` by `operator`.
     */
    event TransferSingle(address indexed operator, address indexed from, address indexed to, uint256 id, uint256 value);

    /**
     * @dev Equivalent to multiple {TransferSingle} events, where `operator`, `from` and `to` are the same for all
     * transfers.
     */
    event TransferBatch(
        address indexed operator,
        address indexed from,
        address indexed to,
        uint256[] ids,
        uint256[] values
    );

    /**
     * @dev Emitted when `account` grants or revokes permission to `operator` to transfer their tokens, according to
     * `approved`.
     */
    event ApprovalForAll(address indexed account, address indexed operator, bool approved);

    /**
     * @dev Emitted when the URI for token type `id` changes to `value`, if it is a non-programmatic URI.
     *
     * If an {URI} event was emitted for `id`, the standard
     * https://eips.ethereum.org/EIPS/eip-1155#metadata-extensions[guarantees] that `value` will equal the value
     * returned by {IERC1155MetadataURI-uri}.
     */
    event URI(string value, uint256 indexed id);

    /**
     * @dev Returns the amount of tokens of token type `id` owned by `account`.
     *
     * Requirements:
     *
     * - `account` cannot be the zero address.
     */
    function balanceOf(address account, uint256 id) external view returns (uint256);

    /**
     * @dev xref:ROOT:erc1155.adoc#batch-operations[Batched] version of {balanceOf}.
     *
     * Requirements:
     *
     * - `accounts` and `ids` must have the same length.
     */
    function balanceOfBatch(address[] calldata accounts, uint256[] calldata ids)
        external
        view
        returns (uint256[] memory);

    /**
     * @dev Grants or revokes permission to `operator` to transfer the caller's tokens, according to `approved`,
     *
     * Emits an {ApprovalForAll} event.
     *
     * Requirements:
     *
     * - `operator` cannot be the caller.
     */
    function setApprovalForAll(address operator, bool approved) external;

    /**
     * @dev Returns true if `operator` is approved to transfer ``account``'s tokens.
     *
     * See {setApprovalForAll}.
     */
    function isApprovedForAll(address account, address operator) external view returns (bool);

    /**
     * @dev Transfers `amount` tokens of token type `id` from `from` to `to`.
     *
     * Emits a {TransferSingle} event.
     *
     * Requirements:
     *
     * - `to` cannot be the zero address.
     * - If the caller is not `from`, it must be have been approved to spend ``from``'s tokens via {setApprovalForAll}.
     * - `from` must have a balance of tokens of type `id` of at least `amount`.
     * - If `to` refers to a smart contract, it must implement {IERC1155Receiver-onERC1155Received} and return the
     * acceptance magic value.
     */
    function safeTransferFrom(
        address from,
        address to,
        uint256 id,
        uint256 amount,
        bytes calldata data
    ) external;

    /**
     * @dev xref:ROOT:erc1155.adoc#batch-operations[Batched] version of {safeTransferFrom}.
     *
     * Emits a {TransferBatch} event.
     *
     * Requirements:
     *
     * - `ids` and `amounts` must have the same length.
     * - If `to` refers to a smart contract, it must implement {IERC1155Receiver-onERC1155BatchReceived} and return the
     * acceptance magic value.
     */
    function safeBatchTransferFrom(
        address from,
        address to,
        uint256[] calldata ids,
        uint256[] calldata amounts,
        bytes calldata data
    ) external;
}

// SPDX-License-Identifier: Apache-2.0
pragma solidity ^0.8;

//import "@openzeppelin/contracts-upgradeable/token/ERC721/IERC721Upgradeable.sol";
import "./IDropClaimCondition.sol";

/**
 *  Thirdweb's 'Drop' contracts are distribution mechanisms for tokens. The
 *  `DropERC721` contract is a distribution mechanism for ERC721 tokens.
 *
 *  A minter wallet (i.e. holder of `MINTER_ROLE`) can (lazy)mint 'n' tokens
 *  at once by providing a single base URI for all tokens being lazy minted.
 *  The URI for each of the 'n' tokens lazy minted is the provided base URI +
 *  `{tokenId}` of the respective token. (e.g. "ipsf://Qmece.../1").
 *
 *  A minter can choose to lazy mint 'delayed-reveal' tokens. More on 'delayed-reveal'
 *  tokens in [this article](https://blog.thirdweb.com/delayed-reveal-nfts).
 *
 *  A contract admin (i.e. holder of `DEFAULT_ADMIN_ROLE`) can create claim conditions
 *  with non-overlapping time windows, and accounts can claim the tokens according to
 *  restrictions defined in the claim condition that is active at the time of the transaction.
 */

interface ICedarNFTIssuanceV0 is IDropClaimConditionV0 {
    /// @dev Emitted when tokens are claimed.
    event TokensClaimed(
        uint256 indexed claimConditionIndex,
        address indexed claimer,
        address indexed receiver,
        uint256 startTokenId,
        uint256 quantityClaimed
    );

    /// @dev Emitted when new claim conditions are set.
    event ClaimConditionsUpdated(ClaimCondition[] claimConditions);

    /**
     *  @notice Lets a contract admin (account with `DEFAULT_ADMIN_ROLE`) set claim conditions.
     *
     *  @param phases                Claim conditions in ascending order by `startTimestamp`.
     *  @param resetClaimEligibility Whether to reset `limitLastClaimTimestamp` and
     *                               `limitMerkleProofClaim` values when setting new
     *                               claim conditions.
     */
    function setClaimConditions(ClaimCondition[] calldata phases, bool resetClaimEligibility) external;

    /**
     *  @notice Lets an account claim a given quantity of NFTs.
     *
     *  @param receiver                       The receiver of the NFTs to claim.
     *  @param quantity                       The quantity of NFTs to claim.
     *  @param currency                       The currency in which to pay for the claim.
     *  @param pricePerToken                  The price per token to pay for the claim.
     *  @param proofs                         The proof of the claimer's inclusion in the merkle root allowlist
     *                                        of the claim conditions that apply.
     *  @param proofMaxQuantityPerTransaction (Optional) The maximum number of NFTs an address included in an
     *                                        allowlist can claim.
     */
    function claim(
        address receiver,
        uint256 quantity,
        address currency,
        uint256 pricePerToken,
        bytes32[] calldata proofs,
        uint256 proofMaxQuantityPerTransaction
    ) external payable;
}

interface ICedarNFTIssuanceV1 is ICedarNFTIssuanceV0 {
    /// @dev Expose the current active claim condition including claim limits
    function getActiveClaimConditions()
        external
        view
        returns (
            ClaimCondition memory condition,
            uint256 conditionId,
            uint256 walletMaxClaimCount,
            uint256 remainingSupply
        );

    /// @dev Expose the user specific limits related to the current active claim condition
    function getUserClaimConditions(address _claimer)
        external
        view
        returns (
            uint256 conditionId,
            uint256 walletClaimedCount,
            uint256 lastClaimTimestamp,
            uint256 nextValidClaimTimestamp
        );

    /// @dev Checks a request to claim NFTs against the active claim condition's criteria.
    function verifyClaim(
        uint256 _conditionId,
        address _claimer,
        uint256 _quantity,
        address _currency,
        uint256 _pricePerToken,
        bool verifyMaxQuantityPerTransaction
    ) external view;
}

interface ICedarNFTIssuanceV2 is ICedarNFTIssuanceV1 {
    event TokensIssued(
        uint256 indexed startTokenId,
        address indexed issuer,
        address indexed receiver,
        uint256 quantity
    );

    event TokenIssued(uint256 indexed tokenId, address indexed issuer, address indexed receiver, string tokenURI);

    event TokenURIUpdated(uint256 indexed tokenId, address indexed updater, string tokenURI);

    /// @dev Issue quantity tokens directly to receiver, only callable by ISSUER_ROLE. Emits TokensIssued event.
    function issue(address receiver, uint256 quantity) external;

    /// @dev Issue a single token directly to receiver with a custom tokenURI, only callable by ISSUER_ROLE.
    /// Emits TokenIssued event.
    function issueWithTokenURI(address receiver, string calldata tokenURI) external;

    /// @dev Sets the tokenURI of a specific token which overrides the one that would otherwise
    /// be generated from the baseURI. This function keeps tracks of whether the tokenURI or baseURI is fresher for a
    /// particular token. Emits TokenURIUpdated event.
    function setTokenURI(uint256 tokenId, string memory _tokenURI) external;
}

interface ICedarNFTIssuanceV3 is ICedarNFTIssuanceV0 {
    event TokensIssued(
        uint256 indexed startTokenId,
        address indexed issuer,
        address indexed receiver,
        uint256 quantity
    );

    event TokenIssued(uint256 indexed tokenId, address indexed issuer, address indexed receiver, string tokenURI);

    event TokenURIUpdated(uint256 indexed tokenId, address indexed updater, string tokenURI);

    /// @dev Issue quantity tokens directly to receiver, only callable by ISSUER_ROLE. Emits TokensIssued event.
    function issue(address receiver, uint256 quantity) external;

    /// @dev Issue a single token directly to receiver with a custom tokenURI, only callable by ISSUER_ROLE.
    /// Emits TokenIssued event.
    function issueWithTokenURI(address receiver, string calldata tokenURI) external;

    /// @dev Sets the tokenURI of a specific token which overrides the one that would otherwise
    /// be generated from the baseURI. This function keeps tracks of whether the tokenURI or baseURI is fresher for a
    /// particular token. Emits TokenURIUpdated event.
    function setTokenURI(uint256 tokenId, string memory _tokenURI) external;

    /// @dev Expose the current active claim condition including claim limits
    function getActiveClaimConditions()
        external
        view
        returns (
            ClaimCondition memory condition,
            uint256 conditionId,
            uint256 walletMaxClaimCount,
            uint256 remainingSupply,
            bool isClaimPaused
        );

    /// @dev Expose the user specific limits related to the current active claim condition
    function getUserClaimConditions(address _claimer)
        external
        view
        returns (
            uint256 conditionId,
            uint256 walletClaimedCount,
            uint256 walletClaimedCountInPhase,
            uint256 lastClaimTimestamp,
            uint256 nextValidClaimTimestamp
        );

    /// @dev Checks a request to claim NFTs against the active claim condition's criteria.
    function verifyClaim(
        uint256 _conditionId,
        address _claimer,
        uint256 _quantity,
        address _currency,
        uint256 _pricePerToken,
        bool verifyMaxQuantityPerTransaction
    ) external view;
}

// SPDX-License-Identifier: Apache-2.0

pragma solidity ^0.8;

import "@openzeppelin/contracts-upgradeable/token/ERC721/IERC721Upgradeable.sol";

interface IERC721V0 is IERC721Upgradeable {}

// SPDX-License-Identifier: Apache-2.0
pragma solidity ^0.8;

// TODO: unify with ICedarSFTMetadata into ICedarTokenMetadata
interface ICedarNFTMetadataV1 {
    /// @dev Returns the URI for a given tokenId.
    function tokenURI(uint256 _tokenId) external view returns (string memory);
}

// SPDX-License-Identifier: Apache-2.0

pragma solidity ^0.8;

import "@openzeppelin/contracts-upgradeable/token/ERC20/IERC20Upgradeable.sol";

interface ICedarSplitPaymentV0 {
    function getTotalReleased() external view returns (uint256);
    function getTotalReleased(IERC20Upgradeable token) external view returns (uint256);
    function getReleased(address account) external view returns (uint256);
    function getReleased(IERC20Upgradeable token, address account) external view returns (uint256);
    function releasePayment(address payable account) external;
    function releasePayment(IERC20Upgradeable token, address account) external;
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.5.0) (token/ERC20/IERC20.sol)

pragma solidity ^0.8.0;

/**
 * @dev Interface of the ERC20 standard as defined in the EIP.
 */
interface IERC20Upgradeable {
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
}

// SPDX-License-Identifier: Apache-2.0
pragma solidity ^0.8;

//  ==========  External imports    ==========
import "@openzeppelin/contracts-upgradeable/token/ERC1155/ERC1155Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/interfaces/IERC2981Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/utils/MulticallUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/utils/StringsUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/access/AccessControlEnumerableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/security/ReentrancyGuardUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/utils/CountersUpgradeable.sol";
/// ========== Internal imports ==========
import "./interfaces/IThirdwebContract.sol";

/// ========== Features ==========
import "./interfaces/IOwnable.sol";
import "./interfaces/IPlatformFee.sol";

import "./openzeppelin-presets/metatx/ERC2771ContextUpgradeable.sol";
import "../generated/impl/BaseCedarERC1155DropV4.sol";

import "./lib/FeeType.sol";
import "./lib/MerkleProof.sol";

import "../Agreement.sol";

import "./errors/IErrors.sol";

import "./types/DropERC1155DataTypes.sol";
import "./CedarERC1155DropLogic.sol";

/// @title The CedarERC1155Drop contract
/// @dev TODO: Add more details
contract CedarERC1155Drop is
    Initializable,
    IThirdwebContract,
    IOwnable,
    ReentrancyGuardUpgradeable,
    ERC2771ContextUpgradeable,
    MulticallUpgradeable,
    AccessControlEnumerableUpgradeable,
    ERC1155Upgradeable,
    IPlatformFee,
    Agreement,
    BaseCedarERC1155DropV4
{
    /// ================================
    /// =========== Libraries ==========
    /// ================================
    using StringsUpgradeable for uint256;
    using CedarERC1155DropLogic for DropERC1155DataTypes.ClaimData;

    /// =============================
    /// =========== Events ==========
    /// =============================
    /// @dev Emitted when the global max supply of a token is updated.
    event MaxTotalSupplyUpdated(uint256 tokenId, uint256 maxTotalSupply);
    /// @dev Emitted when the wallet claim count for a given tokenId and address is updated.
    event WalletClaimCountUpdated(uint256 tokenId, address indexed wallet, uint256 count);
    /// @dev Emitted when the max wallet claim count for a given tokenId is updated.
    event MaxWalletClaimCountUpdated(uint256 tokenId, uint256 count);
    /// @dev Emitted when the sale recipient for a particular tokenId is updated.
    event SaleRecipientForTokenUpdated(uint256 indexed tokenId, address saleRecipient);

    /// ===============================================
    /// =========== State variables - public ==========
    /// ===============================================
    /// @dev Token name
    string public name;
    /// @dev Token symbol
    string public symbol;
    /// @dev The address that receives all primary sales value.
    address public override primarySaleRecipient;
    /// @dev Only transfers to or from TRANSFER_ROLE holders are valid, when transfers are restricted.
    bytes32 public constant TRANSFER_ROLE = keccak256("TRANSFER_ROLE");
    /// @dev Only MINTER_ROLE holders can lazy mint NFTs.
    bytes32 public constant MINTER_ROLE = keccak256("MINTER_ROLE");
    /// @dev Only ISSUER_ROLE holders can issue NFTs.
    bytes32 public constant ISSUER_ROLE = keccak256("ISSUER_ROLE");
    /// @dev If true, users cannot claim.
    bool public claimIsPaused = false;

    /// ================================================
    /// =========== State variables - private ==========
    /// ================================================
    uint256 private constant MAX_UINT256 = 2**256 - 1;
    bytes32 private constant MODULE_TYPE = bytes32("DropERC1155");
    uint256 private constant VERSION = 2;
    /// @dev Max bps in the thirdweb system
    uint256 private constant MAX_BPS = 10_000;
    /// @dev Owner of the contract (purpose: OpenSea compatibility)
    address private _owner;
    /// @dev The recipient of who gets the royalty.
    address private royaltyRecipient;
    /// @dev The (default) address that receives all royalty value.
    uint16 private royaltyBps;
    /// @dev Contract level metadata.
    string private _contractUri;
    /// @dev Largest tokenId of each batch of tokens with the same baseURI
    uint256[] private baseURIIndices;

    /// ===============================
    /// =========== Mappings ==========
    /// ===============================
    /// @dev Mapping from 'Largest tokenId of a batch of tokens with the same baseURI'
    ///         to base URI for the respective batch of tokens.
    mapping(uint256 => string) private baseURI;
    /// @dev Mapping from token ID => royalty recipient and bps for tokens of the token ID.
    mapping(uint256 => RoyaltyInfo) private royaltyInfoForToken;

    DropERC1155DataTypes.ClaimData claimData;

    /// =============================
    /// ========== Structs ==========
    /// =============================
    struct FeaturesInput {
        string userAgreement;
        address signatureVerifier;
    }

    /// ====================================================
    /// ========== Constructor + initializer logic =========
    /// ====================================================
    constructor() {}

    /// @dev Initializes the contract, like a constructor.
    function initialize(
        address _defaultAdmin,
        string memory _name,
        string memory _symbol,
        string memory _contractURI,
        address[] memory _trustedForwarders,
        address _saleRecipient,
        address _royaltyRecipient,
        uint128 _royaltyBps,
        FeaturesInput memory featuresInput,
        uint128 _platformFeeBps,
        address _platformFeeRecipient
    ) external initializer {
        // Initialize inherited contracts, most base-like -> most derived.
        __ReentrancyGuard_init();
        __ERC2771Context_init_unchained(_trustedForwarders);
        __ERC1155_init_unchained("");

        __Agreement_init(featuresInput.userAgreement, featuresInput.signatureVerifier);

        // Initialize this contract's state.
        name = _name;
        symbol = _symbol;
        royaltyRecipient = _royaltyRecipient;
        royaltyBps = uint16(_royaltyBps);
        primarySaleRecipient = _saleRecipient;
        _owner = _defaultAdmin;
        _contractUri = _contractURI;
        claimData.platformFeeRecipient = _platformFeeRecipient;
        claimData.platformFeeBps = uint16(_platformFeeBps);

        _setupRole(DEFAULT_ADMIN_ROLE, _defaultAdmin);
        _setupRole(MINTER_ROLE, _defaultAdmin);
        _setupRole(TRANSFER_ROLE, _defaultAdmin);
        _setupRole(TRANSFER_ROLE, address(0));
        _setupRole(ISSUER_ROLE, _defaultAdmin);
    }

    /// ============================================
    /// ========== Generic contract logic ==========
    /// ============================================
    /// @dev Returns the type of the contract.
    function contractType() external pure override returns (bytes32) {
        return MODULE_TYPE;
    }

    /// @dev Returns the version of the contract.
    function contractVersion() external pure override returns (uint8) {
        return uint8(VERSION);
    }

    /// @dev Returns the address of the current owner.
    function owner() public view override returns (address) {
        return hasRole(DEFAULT_ADMIN_ROLE, _owner) ? _owner : address(0);
    }

    /// @dev See ERC 1155 - Returns the URI for a given tokenId.
    function uri(uint256 _tokenId) public view override returns (string memory _tokenURI) {
        for (uint256 i = 0; i < baseURIIndices.length; i += 1) {
            if (_tokenId < baseURIIndices[i]) {
                return string(abi.encodePacked(baseURI[baseURIIndices[i]], _tokenId.toString()));
            }
        }

        return "";
    }

    /// @dev See ERC-2891 - Returns the royalty recipient and amount, given a tokenId and sale price.
    function royaltyInfo(uint256 tokenId, uint256 salePrice)
        external
        view
        virtual
        override
        returns (address receiver, uint256 royaltyAmount)
    {
        (address recipient, uint256 bps) = getRoyaltyInfoForToken(tokenId);
        receiver = recipient;
        royaltyAmount = (salePrice * bps) / MAX_BPS;
    }

    /// @dev See ERC 165
    function supportsInterface(bytes4 interfaceId)
        public
        view
        virtual
        override(BaseCedarERC1155DropV4, ERC1155Upgradeable, AccessControlEnumerableUpgradeable)
        returns (bool)
    {
        return
            BaseCedarERC1155DropV4.supportsInterface(interfaceId) ||
            ERC1155Upgradeable.supportsInterface(interfaceId) ||
            AccessControlEnumerableUpgradeable.supportsInterface(interfaceId);
    }

    // More pointless yet required overrides
    function totalSupply(uint256 _tokenId) public view override returns (uint256) {
        return claimData.totalSupply[_tokenId];
    }

    function exists(uint256 _tokenId) public view override returns (bool) {
        return claimData.totalSupply[_tokenId] > 0;
    }

    /// @dev returns the total number of unique tokens in existence.
    function getLargestTokenId() public view override returns (uint256) {
        return claimData.nextTokenIdToMint - 1;
    }

    /// @dev allows admin to pause users from claiming.
    function pauseClaims() external onlyRole(DEFAULT_ADMIN_ROLE) {
        claimIsPaused = true;
        emit ClaimPauseStatusUpdated(claimIsPaused);
    }

    /// @dev allows admin to un-pause users from claiming.
    function unpauseClaims() external onlyRole(DEFAULT_ADMIN_ROLE) {
        claimIsPaused = false;
        emit ClaimPauseStatusUpdated(claimIsPaused);
    }

    /// ======================================
    /// =========== Minting logic ============
    /// ======================================
    /// @dev Lets an account with `MINTER_ROLE` lazy mint 'n' NFTs.
    ///        The URIs for each token is the provided `_baseURIForTokens` + `{tokenId}`.
    function lazyMint(uint256 _amount, string calldata _baseURIForTokens) external override onlyRole(MINTER_ROLE) {
        uint256 startId = claimData.nextTokenIdToMint;
        uint256 baseURIIndex = startId + _amount;

        claimData.nextTokenIdToMint = baseURIIndex;
        baseURI[baseURIIndex] = _baseURIForTokens;
        baseURIIndices.push(baseURIIndex);

        emit TokensLazyMinted(startId, baseURIIndex - 1, _baseURIForTokens);
    }

    /// ======================================
    /// ============= Issue logic ============
    /// ======================================
    /// @dev Lets an account claim a given quantity of NFTs, of a single tokenId.
    function issue(
        address _receiver,
        uint256 _tokenId,
        uint256 _quantity
    ) external override nonReentrant onlyRole(ISSUER_ROLE) {
        CedarERC1155DropLogic.verifyIssue(claimData, _tokenId, _quantity);

        _mint(_receiver, _tokenId, _quantity, "");

        emit TokensIssued(_tokenId, _msgSender(), _receiver, _quantity);
    }

    /// ======================================
    /// ============= Claim logic ============
    /// ======================================
    /// @dev Lets an account claim a given quantity of NFTs, of a single tokenId.
    function claim(
        address _receiver,
        uint256 _tokenId,
        uint256 _quantity,
        address _currency,
        uint256 _pricePerToken,
        bytes32[] calldata _proofs,
        uint256 _proofMaxQuantityPerTransaction
    ) external payable override nonReentrant {
        address msgSender = _msgSender();
        if (!(isTrustedForwarder(msg.sender) || msgSender == tx.origin)) revert Bot();
        if (claimIsPaused) revert ClaimPaused();

        CedarERC1155DropLogic.InternalClaim memory internalClaim = CedarERC1155DropLogic.executeClaim(
            claimData,
            _tokenId,
            _quantity,
            _currency,
            _pricePerToken,
            _proofs,
            _proofMaxQuantityPerTransaction,
            msgSender,
            primarySaleRecipient
        );
        _mint(_receiver, _tokenId, _quantity, "");
        emit TokensClaimed(internalClaim.activeConditionId, _tokenId, msgSender, _receiver, _quantity);
    }

    /// @dev Lets a contract admin (account with `DEFAULT_ADMIN_ROLE`) set claim conditions, for a tokenId.
    function setClaimConditions(
        uint256 _tokenId,
        ClaimCondition[] calldata _phases,
        bool _resetClaimEligibility
    ) external override onlyRole(DEFAULT_ADMIN_ROLE) {
        CedarERC1155DropLogic.setClaimConditions(claimData, _tokenId, _phases, _resetClaimEligibility);
        emit ClaimConditionsUpdated(_tokenId, _phases);
    }

    /// @dev Checks a request to claim NFTs against the active claim condition's criteria.
    function verifyClaim(
        uint256 _conditionId,
        address _claimer,
        uint256 _tokenId,
        uint256 _quantity,
        address _currency,
        uint256 _pricePerToken,
        bool verifyMaxQuantityPerTransaction
    ) public view override {
        CedarERC1155DropLogic.verifyClaim(
            claimData,
            _conditionId,
            _claimer,
            _tokenId,
            _quantity,
            _currency,
            _pricePerToken,
            verifyMaxQuantityPerTransaction
        );
    }

    /// ======================================
    /// ========== Setter functions ==========
    /// ======================================
    /// @dev Lets a contract admin set a new owner for the contract. The new owner must be a contract admin.
    function setOwner(address _newOwner) external override onlyRole(DEFAULT_ADMIN_ROLE) {
        if (!(hasRole(DEFAULT_ADMIN_ROLE, _newOwner))) revert InvalidPermission();
        emit OwnerUpdated(_owner, _newOwner);
        _owner = _newOwner;
    }

    /// @dev Lets a contract admin set the recipient for all primary sales.
    function setPrimarySaleRecipient(address _saleRecipient) external override onlyRole(DEFAULT_ADMIN_ROLE) {
        primarySaleRecipient = _saleRecipient;
        emit PrimarySaleRecipientUpdated(_saleRecipient);
    }

    /// @dev Lets a contract admin set the recipient for all primary sales.
    function setSaleRecipientForToken(uint256 _tokenId, address _saleRecipient) external onlyRole(DEFAULT_ADMIN_ROLE) {
        claimData.saleRecipient[_tokenId] = _saleRecipient;
        emit SaleRecipientForTokenUpdated(_tokenId, _saleRecipient);
    }

    /// @dev Lets a contract admin update the platform fee recipient and bps
    function setPlatformFeeInfo(address _platformFeeRecipient, uint256 _platformFeeBps)
        external
        override
        onlyRole(DEFAULT_ADMIN_ROLE)
    {
        if (!(_platformFeeBps <= MAX_BPS)) revert MaxBps();

        claimData.platformFeeBps = uint16(_platformFeeBps);
        claimData.platformFeeRecipient = _platformFeeRecipient;

        emit PlatformFeeInfoUpdated(_platformFeeRecipient, _platformFeeBps);
    }

    /// @dev Lets a contract admin update the default royalty recipient and bps.
    function setDefaultRoyaltyInfo(address _royaltyRecipient, uint256 _royaltyBps)
        external
        override
        onlyRole(DEFAULT_ADMIN_ROLE)
    {
        if (!(_royaltyBps <= MAX_BPS)) revert MaxBps();

        royaltyRecipient = _royaltyRecipient;
        royaltyBps = uint16(_royaltyBps);

        emit DefaultRoyalty(_royaltyRecipient, _royaltyBps);
    }

    /// @dev Lets a contract admin set the royalty recipient and bps for a particular token Id.
    function setRoyaltyInfoForToken(
        uint256 _tokenId,
        address _recipient,
        uint256 _bps
    ) external override onlyRole(DEFAULT_ADMIN_ROLE) {
        if (!(_bps <= MAX_BPS)) revert MaxBps();

        royaltyInfoForToken[_tokenId] = RoyaltyInfo({recipient: _recipient, bps: _bps});

        emit RoyaltyForToken(_tokenId, _recipient, _bps);
    }

    /// @dev Lets a contract admin set a claim count for a wallet.
    function setWalletClaimCount(
        uint256 _tokenId,
        address _claimer,
        uint256 _count
    ) external onlyRole(DEFAULT_ADMIN_ROLE) {
        claimData.walletClaimCount[_tokenId][_claimer] = _count;
        emit WalletClaimCountUpdated(_tokenId, _claimer, _count);
    }

    /// @dev Lets a contract admin set a maximum number of NFTs of a tokenId that can be claimed by any wallet.
    function setMaxWalletClaimCount(uint256 _tokenId, uint256 _count) external onlyRole(DEFAULT_ADMIN_ROLE) {
        claimData.maxWalletClaimCount[_tokenId] = _count;
        emit MaxWalletClaimCountUpdated(_tokenId, _count);
    }

    /// @dev Lets a module admin set a max total supply for token.
    function setMaxTotalSupply(uint256 _tokenId, uint256 _maxTotalSupply) external onlyRole(DEFAULT_ADMIN_ROLE) {
        if (_maxTotalSupply != 0 && claimData.totalSupply[_tokenId] > _maxTotalSupply) {
            revert CrossedLimitMaxTotalSupply();
        }
        claimData.maxTotalSupply[_tokenId] = _maxTotalSupply;
        emit MaxTotalSupplyUpdated(_tokenId, _maxTotalSupply);
    }

    /// @dev Lets a contract admin set the URI for contract-level metadata.
    function setContractURI(string calldata _uri)
        external
        override(ICedarMetadataV1, IThirdwebContract)
        onlyRole(DEFAULT_ADMIN_ROLE)
    {
        _contractUri = _uri;
        emit ContractURIUpdated(_msgSender(), _uri);
    }

    /// @dev Lets an account with `MINTER_ROLE` update base URI.
    function updateBaseURI(uint256 baseURIIndex, string calldata _baseURIForTokens)
        external
        override
        onlyRole(MINTER_ROLE)
    {
        baseURI[baseURIIndex] = _baseURIForTokens;
        emit BaseURIUpdated(baseURIIndex, _baseURIForTokens);
    }

    /// ======================================
    /// ============ Agreement ===============
    /// ======================================
    /// @dev this function activates the user terms
    function setTermsStatus(bool _status) external virtual override onlyRole(DEFAULT_ADMIN_ROLE) {
        _setTermsStatus(_status);
    }

    /// @notice stores terms accepted from a signed message
    /// @dev this function is for acceptors that have signed a message offchain to accept the terms. The function calls the verifier contract to valid the signature before storing acceptance.
    function storeTermsAccepted(address _acceptor, bytes calldata _signature)
        external
        virtual
        override
        onlyRole(DEFAULT_ADMIN_ROLE)
    {
        _storeTermsAccepted(_acceptor, _signature);
    }

    /// ======================================
    /// ========== Getter functions ==========
    /// ======================================
    /// @dev Returns the platform fee recipient and bps.
    function getPlatformFeeInfo() external view override returns (address, uint16) {
        return (claimData.platformFeeRecipient, uint16(claimData.platformFeeBps));
    }

    /// @dev Returns the default royalty recipient and bps.
    function getDefaultRoyaltyInfo() external view override returns (address, uint16) {
        return (royaltyRecipient, uint16(royaltyBps));
    }

    /// @dev Returns the royalty recipient and bps for a particular token Id.
    function getRoyaltyInfoForToken(uint256 _tokenId) public view override returns (address, uint16) {
        RoyaltyInfo memory royaltyForToken = royaltyInfoForToken[_tokenId];

        return
            royaltyForToken.recipient == address(0)
                ? (royaltyRecipient, uint16(royaltyBps))
                : (royaltyForToken.recipient, uint16(royaltyForToken.bps));
    }

    /// @dev At any given moment, returns the uid for the active claim condition, for a given tokenId.
    function getActiveClaimConditionId(uint256 _tokenId) internal view returns (uint256) {
        return CedarERC1155DropLogic.getActiveClaimConditionId(claimData, _tokenId);
    }

    /// @dev Expose the current active claim condition including claim limits
    function getActiveClaimConditions(uint256 _tokenId)
        external
        view
        override
        returns (
            ClaimCondition memory condition,
            uint256 conditionId,
            uint256 walletMaxClaimCount,
            uint256 remainingSupply,
            bool isClaimPaused
        )
    {
        (condition, conditionId, walletMaxClaimCount, remainingSupply) = claimData.getActiveClaimConditions(_tokenId);
        isClaimPaused = claimIsPaused;
    }

    /// @dev Expose the user specific limits related to the current active claim condition
    function getUserClaimConditions(uint256 _tokenId, address _claimer)
        external
        view
        override
        returns (
            uint256 conditionId,
            uint256 walletClaimedCount,
            uint256 walletClaimedCountInPhase,
            uint256 lastClaimTimestamp,
            uint256 nextValidClaimTimestamp
        )
    {
        conditionId = getActiveClaimConditionId(_tokenId);
        (lastClaimTimestamp, nextValidClaimTimestamp) = getClaimTimestamp(_tokenId, conditionId, _claimer);
        walletClaimedCount = claimData.walletClaimCount[_tokenId][_claimer];
        walletClaimedCountInPhase = claimData.claimCondition[_tokenId].userClaims[conditionId][_claimer].claimedBalance;
    }

    /// @dev Returns the timestamp for when a claimer is eligible for claiming NFTs again.
    function getClaimTimestamp(
        uint256 _tokenId,
        uint256 _conditionId,
        address _claimer
    ) public view returns (uint256 lastClaimTimestamp, uint256 nextValidClaimTimestamp) {
        return CedarERC1155DropLogic.getClaimTimestamp(claimData, _tokenId, _conditionId, _claimer);
    }

    /// @dev Gets the base URI indices
    function getBaseURIIndices() external view override returns (uint256[] memory) {
        return baseURIIndices;
    }

    /// @dev Contract level metadata.
    function contractURI() external view override(ICedarMetadataV1, IThirdwebContract) returns (string memory) {
        return _contractUri;
    }

    /// ======================================
    /// =========== Miscellaneous ============
    /// ======================================
    /// @dev Concrete implementation semantic version -
    ///         provided for completeness but not designed to be the point of dispatch
    function minorVersion() public pure override returns (uint256 minor, uint256 patch) {
        minor = 0;
        patch = 0;
    }

    /// @dev Lets a token owner burn the tokens they own (i.e. destroy for good)
    function burn(
        address account,
        uint256 id,
        uint256 value
    ) public virtual {
        if (!(account == _msgSender() || isApprovedForAll(account, _msgSender()))) revert InvalidPermission();
        _burn(account, id, value);
    }

    /// @dev Lets a token owner burn multiple tokens they own at once (i.e. destroy for good)
    function burnBatch(
        address account,
        uint256[] memory ids,
        uint256[] memory values
    ) public virtual {
        if (!(account == _msgSender() || isApprovedForAll(account, _msgSender()))) revert InvalidPermission();
        _burnBatch(account, ids, values);
    }

    /// @dev See {ERC1155-_beforeTokenTransfer}.
    function _beforeTokenTransfer(
        address operator,
        address from,
        address to,
        uint256[] memory ids,
        uint256[] memory amounts,
        bytes memory data
    ) internal virtual override {
        super._beforeTokenTransfer(operator, from, to, ids, amounts, data);

        // if transfer is restricted on the contract, we still want to allow burning and minting
        if (!hasRole(TRANSFER_ROLE, address(0)) && from != address(0) && to != address(0)) {
            if (!(hasRole(TRANSFER_ROLE, from) || hasRole(TRANSFER_ROLE, to))) revert InvalidPermission();
        }

        if (to != address(this)) {
            if (termsActivated) {
                require(
                    termsAccepted[to],
                    string(
                        abi.encodePacked(
                            "Receiver address has not accepted the collection's terms of use at ",
                            userAgreement
                        )
                    )
                );
            }
        }

        if (from == address(0)) {
            for (uint256 i = 0; i < ids.length; ++i) {
                claimData.totalSupply[ids[i]] += amounts[i];
            }
        }

        if (to == address(0)) {
            for (uint256 i = 0; i < ids.length; ++i) {
                claimData.totalSupply[ids[i]] -= amounts[i];
            }
        }
    }

    /// @dev Provides a function to batch together multiple calls in a single external call.
    function multicall(bytes[] calldata data)
        external
        override(IMulticallableV0, MulticallUpgradeable)
        returns (bytes[] memory results)
    {
        return MulticallUpgradeable(this).multicall(data);
    }

    function _msgSender()
        internal
        view
        virtual
        override(ContextUpgradeable, ERC2771ContextUpgradeable)
        returns (address sender)
    {
        return ERC2771ContextUpgradeable._msgSender();
    }

    function _msgData()
        internal
        view
        virtual
        override(ContextUpgradeable, ERC2771ContextUpgradeable)
        returns (bytes calldata)
    {
        return ERC2771ContextUpgradeable._msgData();
    }
}

// SPDX-License-Identifier: Apache-2.0
pragma solidity ^0.8;

import "./lib/CurrencyTransferLib.sol";
import "./lib/MerkleProof.sol";
import "./types/DropERC1155DataTypes.sol";
import "./errors/IErrors.sol";
import "./../api/issuance/IDropClaimCondition.sol";

library CedarERC1155DropLogic {
    using CedarERC1155DropLogic for DropERC1155DataTypes.ClaimData;

    uint256 private constant MAX_UINT256 = 2**256 - 1;

    struct InternalClaim {
        bool validMerkleProof;
        uint256 merkleProofIndex;
        bool toVerifyMaxQuantityPerTransaction;
        uint256 activeConditionId;
        uint256 tokenIdToClaim;
    }

    function setClaimConditions(
        DropERC1155DataTypes.ClaimData storage claimData,
        uint256 _tokenId,
        IDropClaimConditionV0.ClaimCondition[] calldata _phases,
        bool _resetClaimEligibility
    ) external {
        IDropClaimConditionV0.ClaimConditionList storage condition = claimData.claimCondition[_tokenId];
        uint256 existingStartIndex = condition.currentStartId;
        uint256 existingPhaseCount = condition.count;

        /**
         *  `limitLastClaimTimestamp` and `limitMerkleProofClaim` are mappings that use a
         *  claim condition's UID as a key.
         *
         *  If `_resetClaimEligibility == true`, we assign completely new UIDs to the claim
         *  conditions in `_phases`, effectively resetting the restrictions on claims expressed
         *  by `limitLastClaimTimestamp` and `limitMerkleProofClaim`.
         */
        uint256 newStartIndex = existingStartIndex;
        if (_resetClaimEligibility) {
            newStartIndex = existingStartIndex + existingPhaseCount;
        }

        condition.count = _phases.length;
        condition.currentStartId = newStartIndex;

        uint256 lastConditionStartTimestamp;
        for (uint256 i = 0; i < _phases.length; i++) {
            if (!(i == 0 || lastConditionStartTimestamp < _phases[i].startTimestamp)) revert InvalidTime();

            uint256 supplyClaimedAlready = condition.phases[newStartIndex + i].supplyClaimed;

            if (!(supplyClaimedAlready <= _phases[i].maxClaimableSupply)) revert CrossedLimitMaxClaimableSupply();

            condition.phases[newStartIndex + i] = _phases[i];
            condition.phases[newStartIndex + i].supplyClaimed = supplyClaimedAlready;

            lastConditionStartTimestamp = _phases[i].startTimestamp;
        }

        /**
         *  Gas refunds (as much as possible)
         *
         *  If `_resetClaimEligibility == true`, we assign completely new UIDs to the claim
         *  conditions in `_phases`. So, we delete claim conditions with UID < `newStartIndex`.
         *
         *  If `_resetClaimEligibility == false`, and there are more existing claim conditions
         *  than in `_phases`, we delete the existing claim conditions that don't get replaced
         *  by the conditions in `_phases`.
         */
        if (_resetClaimEligibility) {
            for (uint256 i = existingStartIndex; i < newStartIndex; i++) {
                delete condition.phases[i];
            }
        } else {
            if (existingPhaseCount > _phases.length) {
                for (uint256 i = _phases.length; i < existingPhaseCount; i++) {
                    delete condition.phases[newStartIndex + i];
                }
            }
        }
    }

    function executeClaim(
        DropERC1155DataTypes.ClaimData storage claimData,
        uint256 _tokenId,
        uint256 _quantity,
        address _currency,
        uint256 _pricePerToken,
        bytes32[] calldata _proofs,
        uint256 _proofMaxQuantityPerTransaction,
        address msgSender,
        address primarySaleRecipient
    ) public returns (InternalClaim memory internalData) {
        // Get the active claim condition index.
        internalData.activeConditionId = getActiveClaimConditionId(claimData, _tokenId);

        /**
         *  We make allowlist checks (i.e. verifyClaimMerkleProof) before verifying the claim's general
         *  validity (i.e. verifyClaim) because we give precedence to the check of allow list quantity
         *  restriction over the check of the general claim condition's quantityLimitPerTransaction
         *  restriction.
         */
        (internalData.validMerkleProof, internalData.merkleProofIndex) = verifyClaimMerkleProof(
            claimData,
            internalData.activeConditionId,
            msgSender,
            _tokenId,
            _quantity,
            _proofs,
            _proofMaxQuantityPerTransaction
        );

        // Verify claim validity. If not valid, revert.
        // when there's allowlist present --> verifyClaimMerkleProof will verify the _proofMaxQuantityPerTransaction value with hashed leaf in the allowlist
        // when there's no allowlist, this check is true --> verifyClaim will check for _quantity being less/equal than the limit
        internalData.toVerifyMaxQuantityPerTransaction =
            _proofMaxQuantityPerTransaction == 0 ||
            claimData.claimCondition[_tokenId].phases[internalData.activeConditionId].merkleRoot == bytes32(0);

        verifyClaim(
            claimData,
            internalData.activeConditionId,
            msgSender,
            _tokenId,
            _quantity,
            _currency,
            _pricePerToken,
            internalData.toVerifyMaxQuantityPerTransaction
        );

        // If there's a price, collect price.
        collectClaimPrice(claimData, _quantity, _currency, _pricePerToken, _tokenId, msgSender, primarySaleRecipient);

        // Book-keeping before the calling contract does the actual transfer and mint the relevant NFTs to claimer.
        recordTransferClaimedTokens(claimData, internalData.activeConditionId, _tokenId, _quantity, msgSender);
    }

    /// @dev Verify inclusion in allow-list.
    function verifyClaimMerkleProof(
        DropERC1155DataTypes.ClaimData storage claimData,
        uint256 _conditionId,
        address _claimer,
        uint256 _tokenId,
        uint256 _quantity,
        bytes32[] calldata _proofs,
        uint256 _proofMaxQuantityPerTransaction
    ) public view returns (bool validMerkleProof, uint256 merkleProofIndex) {
        IDropClaimConditionV0.ClaimCondition memory currentClaimPhase = claimData.claimCondition[_tokenId].phases[
            _conditionId
        ];

        if (currentClaimPhase.merkleRoot != bytes32(0)) {
            (validMerkleProof, merkleProofIndex) = MerkleProof.verify(
                _proofs,
                currentClaimPhase.merkleRoot,
                keccak256(abi.encodePacked(_claimer, _proofMaxQuantityPerTransaction))
            );

            if (!validMerkleProof) revert InvalidMerkleProof();
            if (
                !(_proofMaxQuantityPerTransaction == 0 ||
                    _quantity <=
                    _proofMaxQuantityPerTransaction -
                        claimData.claimCondition[_tokenId].userClaims[_conditionId][_claimer].claimedBalance)
            ) revert InvalidMaxQuantityProof();
        }
    }

    /// @dev Checks a request to claim NFTs against the active claim condition's criteria.
    function verifyClaim(
        DropERC1155DataTypes.ClaimData storage claimData,
        uint256 _conditionId,
        address _claimer,
        uint256 _tokenId,
        uint256 _quantity,
        address _currency,
        uint256 _pricePerToken,
        bool verifyMaxQuantityPerTransaction
    ) public view {
        IDropClaimConditionV0.ClaimCondition memory currentClaimPhase = claimData.claimCondition[_tokenId].phases[
            _conditionId
        ];

        if (!(_currency == currentClaimPhase.currency && _pricePerToken == currentClaimPhase.pricePerToken)) {
            revert InvalidPrice();
        }
        if (
            !(_quantity > 0 &&
                (!verifyMaxQuantityPerTransaction || _quantity <= currentClaimPhase.quantityLimitPerTransaction))
        ) {
            revert CrossedLimitQuantityPerTransaction();
        }

        if (!(currentClaimPhase.supplyClaimed + _quantity <= currentClaimPhase.maxClaimableSupply)) {
            revert CrossedLimitMaxClaimableSupply();
        }
        if (
            !(claimData.maxTotalSupply[_tokenId] == 0 ||
                claimData.totalSupply[_tokenId] + _quantity <= claimData.maxTotalSupply[_tokenId])
        ) {
            revert CrossedLimitMaxTotalSupply();
        }
        if (
            !(claimData.maxWalletClaimCount[_tokenId] == 0 ||
                claimData.walletClaimCount[_tokenId][_claimer] + _quantity <= claimData.maxWalletClaimCount[_tokenId])
        ) {
            revert CrossedLimitMaxWalletClaimCount();
        }

        (uint256 lastClaimTimestamp, uint256 nextValidClaimTimestamp) = getClaimTimestamp(
            claimData,
            _tokenId,
            _conditionId,
            _claimer
        );

        if (!(lastClaimTimestamp == 0 || block.timestamp >= nextValidClaimTimestamp)) revert InvalidTime();
    }

    /// @dev Collects and distributes the primary sale value of NFTs being claimed.
    function collectClaimPrice(
        DropERC1155DataTypes.ClaimData storage claimData,
        uint256 _quantityToClaim,
        address _currency,
        uint256 _pricePerToken,
        uint256 _tokenId,
        address msgSender,
        address primarySaleRecipient
    ) internal {
        if (_pricePerToken == 0) {
            return;
        }

        uint256 MAX_BPS = 10_000;

        uint256 totalPrice = _quantityToClaim * _pricePerToken;
        uint256 platformFees = (totalPrice * claimData.platformFeeBps) / MAX_BPS;

        if (_currency == CurrencyTransferLib.NATIVE_TOKEN && !(msg.value == totalPrice)) revert InvalidPrice();

        address recipient = claimData.saleRecipient[_tokenId] == address(0)
            ? primarySaleRecipient
            : claimData.saleRecipient[_tokenId];

        CurrencyTransferLib.transferCurrency(_currency, msgSender, claimData.platformFeeRecipient, platformFees);
        CurrencyTransferLib.transferCurrency(_currency, msgSender, recipient, totalPrice - platformFees);
    }

    /// @dev Book-keeping before the calling contract does the actual transfer and mint the relevant NFTs to claimer.
    function recordTransferClaimedTokens(
        DropERC1155DataTypes.ClaimData storage claimData,
        uint256 _conditionId,
        uint256 _tokenId,
        uint256 _quantityBeingClaimed,
        address msgSender
    ) public {
        // Update the supply minted under mint condition.
        claimData.claimCondition[_tokenId].phases[_conditionId].supplyClaimed += _quantityBeingClaimed;

        // if transfer claimed tokens is called when to != msg.sender, it'd use msg.sender's limits.
        // behavior would be similar to msg.sender mint for itself, then transfer to `to`.
        claimData.claimCondition[_tokenId].userClaims[_conditionId][msgSender].lastClaimTimestamp = block.timestamp;
        claimData.claimCondition[_tokenId].userClaims[_conditionId][msgSender].claimedBalance += _quantityBeingClaimed;
        claimData.walletClaimCount[_tokenId][msgSender] += _quantityBeingClaimed;
    }

    function verifyIssue(
        DropERC1155DataTypes.ClaimData storage claimData,
        uint256 _tokenId,
        uint256 _quantity
    ) external view {
        if (_quantity == 0) {
            revert InvalidQuantity();
        }
        if (
            claimData.maxTotalSupply[_tokenId] != 0 &&
            claimData.totalSupply[_tokenId] + _quantity > claimData.maxTotalSupply[_tokenId]
        ) {
            revert CrossedLimitMaxTotalSupply();
        }
    }

    /// @dev Expose the current active claim condition including claim limits
    function getActiveClaimConditions(DropERC1155DataTypes.ClaimData storage claimData, uint256 _tokenId)
        public
        view
        returns (
            IDropClaimConditionV0.ClaimCondition memory condition,
            uint256 conditionId,
            uint256 walletMaxClaimCount,
            uint256 remainingSupply
        )
    {
        conditionId = getActiveClaimConditionId(claimData, _tokenId);
        condition = claimData.claimCondition[_tokenId].phases[conditionId];
        walletMaxClaimCount = claimData.maxWalletClaimCount[_tokenId];

        if (claimData.maxTotalSupply[_tokenId] > 0) {
            remainingSupply = claimData.maxTotalSupply[_tokenId] - claimData.totalSupply[_tokenId];
        } else {
            remainingSupply = MAX_UINT256;
        }
    }

    /// @dev Returns the user specific limits related to the current active claim condition
    function getUserClaimConditions(
        DropERC1155DataTypes.ClaimData storage claimData,
        uint256 _tokenId,
        address _claimer
    )
        public
        view
        returns (
            uint256 conditionId,
            uint256 walletClaimedCount,
            uint256 lastClaimTimestamp,
            uint256 nextValidClaimTimestamp
        )
    {
        conditionId = getActiveClaimConditionId(claimData, _tokenId);
        (lastClaimTimestamp, nextValidClaimTimestamp) = getClaimTimestamp(claimData, _tokenId, conditionId, _claimer);
        walletClaimedCount = claimData.walletClaimCount[_tokenId][_claimer];
    }

    /// @dev Returns the current active claim condition ID.
    function getActiveClaimConditionId(DropERC1155DataTypes.ClaimData storage claimData, uint256 _tokenId)
        public
        view
        returns (uint256)
    {
        IDropClaimConditionV0.ClaimConditionList storage conditionList = claimData.claimCondition[_tokenId];
        for (uint256 i = conditionList.currentStartId + conditionList.count; i > conditionList.currentStartId; i--) {
            if (block.timestamp >= conditionList.phases[i - 1].startTimestamp) {
                return i - 1;
            }
        }

        revert NoActiveMintCondition();
    }

    /// @dev Returns the timestamp for when a claimer is eligible for claiming NFTs again.
    function getClaimTimestamp(
        DropERC1155DataTypes.ClaimData storage claimData,
        uint256 _tokenId,
        uint256 _conditionId,
        address _claimer
    ) public view returns (uint256 lastClaimTimestamp, uint256 nextValidClaimTimestamp) {
        lastClaimTimestamp = claimData.claimCondition[_tokenId].userClaims[_conditionId][_claimer].lastClaimTimestamp;

        unchecked {
            nextValidClaimTimestamp =
                lastClaimTimestamp +
                claimData.claimCondition[_tokenId].phases[_conditionId].waitTimeInSecondsBetweenClaims;

            if (nextValidClaimTimestamp < lastClaimTimestamp) {
                nextValidClaimTimestamp = type(uint256).max;
            }
        }
    }
}

// SPDX-License-Identifier: Apache-2.0
pragma solidity ^0.8;

interface IOwnable {
    /// @dev Returns the owner of the contract.
    function owner() external view returns (address);

    /// @dev Lets a module admin set a new owner for the contract. The new owner must be a module admin.
    function setOwner(address _newOwner) external;

    /// @dev Emitted when a new Owner is set.
    event OwnerUpdated(address prevOwner, address newOwner);
}

// SPDX-License-Identifier: Apache-2.0
pragma solidity ^0.8;

interface IThirdwebContract {
    /// @dev Returns the module type of the contract.
    function contractType() external pure returns (bytes32);

    /// @dev Returns the version of the contract.
    function contractVersion() external pure returns (uint8);

    /// @dev Returns the metadata URI of the contract.
    function contractURI() external view returns (string memory);

    /**
     *  @dev Sets contract URI for the storefront-level metadata of the contract.
     *       Only module admin can call this function.
     */
    function setContractURI(string calldata _uri) external;
}

// SPDX-License-Identifier: Apache-2.0
pragma solidity ^0.8;

interface IPlatformFee {
    /// @dev Returns the platform fee bps and recipient.
    function getPlatformFeeInfo() external view returns (address, uint16);

    /// @dev Lets a module admin update the fees on primary sales.
    function setPlatformFeeInfo(address _platformFeeRecipient, uint256 _platformFeeBps) external;

    /// @dev Emitted when fee on primary sales is updated.
    event PlatformFeeInfoUpdated(address platformFeeRecipient, uint256 platformFeeBps);
}

// SPDX-License-Identifier: Apache-2.0

// Generated by impl.ts. Will be overwritten.
// Filename: './BaseCedarERC1155DropV4.sol'

pragma solidity ^0.8.4;

import "../../api/impl/ICedarERC1155Drop.sol";

/// Inherit from this base to implement introspection
abstract contract BaseCedarERC1155DropV4 is ICedarERC1155DropV4 {
    function supportedFeatures() override public pure returns (string[] memory features) {
        features = new string[](12);
        features[0] = "ICedarFeatures.sol:ICedarFeaturesV0";
        features[1] = "ICedarVersioned.sol:ICedarVersionedV1";
        features[2] = "IMulticallable.sol:IMulticallableV0";
        features[3] = "issuance/ICedarSFTIssuance.sol:ICedarSFTIssuanceV2";
        features[4] = "lazymint/ICedarLazyMint.sol:ICedarLazyMintV0";
        features[5] = "baseURI/ICedarUpdateBaseURI.sol:ICedarUpdateBaseURIV0";
        features[6] = "standard/IERC1155.sol:IERC1155SupplyV1";
        features[7] = "royalties/IRoyalty.sol:IRoyaltyV0";
        features[8] = "metadata/IContractMetadata.sol:ICedarMetadataV1";
        features[9] = "agreement/ICedarAgreement.sol:ICedarAgreementV0";
        features[10] = "primarysale/IPrimarySale.sol:IPrimarySaleV0";
        features[11] = "pausable/ICedarPausable.sol:ICedarPausableV0";
    }

    /// This needs to be public to be callable from initialize via delegatecall
    function minorVersion() virtual override public pure returns (uint256 minor, uint256 patch);

    function implementationVersion() override public pure returns (uint256 major, uint256 minor, uint256 patch) {
        (minor, patch) = minorVersion();
        major = 4;
    }

    function implementationInterfaceName() virtual override public pure returns (string memory interfaceName) {
        interfaceName = "ICedarERC1155DropV4";
    }

    function supportsInterface(bytes4 interfaceID) virtual override public view returns (bool) {
        return (interfaceID == type(IERC165Upgradeable).interfaceId) || ((interfaceID == type(ICedarFeaturesV0).interfaceId) || ((interfaceID == type(ICedarVersionedV1).interfaceId) || ((interfaceID == type(IMulticallableV0).interfaceId) || ((interfaceID == type(ICedarSFTIssuanceV2).interfaceId) || ((interfaceID == type(ICedarLazyMintV0).interfaceId) || ((interfaceID == type(ICedarUpdateBaseURIV0).interfaceId) || ((interfaceID == type(IERC1155SupplyV1).interfaceId) || ((interfaceID == type(IRoyaltyV0).interfaceId) || ((interfaceID == type(ICedarMetadataV1).interfaceId) || ((interfaceID == type(ICedarAgreementV0).interfaceId) || ((interfaceID == type(IPrimarySaleV0).interfaceId) || (interfaceID == type(ICedarPausableV0).interfaceId))))))))))));
    }

    function isICedarFeaturesV0() override public pure returns (bool) {
        return true;
    }
}

// SPDX-License-Identifier: Apache-2.0
pragma solidity ^0.8;

library FeeType {
    uint256 internal constant PRIMARY_SALE = 0;
    uint256 internal constant MARKET_SALE = 1;
    uint256 internal constant SPLIT = 2;
}

// SPDX-License-Identifier: MIT
// Modified from https://github.com/OpenZeppelin/openzeppelin-contracts/blob/v4.3.0/contracts/utils/cryptography/MerkleProof.sol
// Copied from https://github.com/ensdomains/governance/blob/master/contracts/MerkleProof.sol

pragma solidity ^0.8;

/**
 * @dev These functions deal with verification of Merkle Trees proofs.
 *
 * The proofs can be generated using the JavaScript library
 * https://github.com/miguelmota/merkletreejs[merkletreejs].
 * Note: the hashing algorithm should be keccak256 and pair sorting should be enabled.
 *
 * See `test/utils/cryptography/MerkleProof.test.js` for some examples.
 *
 * Source: https://github.com/ensdomains/governance/blob/master/contracts/MerkleProof.sol
 */
library MerkleProof {
    /**
     * @dev Returns true if a `leaf` can be proved to be a part of a Merkle tree
     * defined by `root`. For this, a `proof` must be provided, containing
     * sibling hashes on the branch from the leaf to the root of the tree. Each
     * pair of leaves and each pair of pre-images are assumed to be sorted.
     */
    function verify(
        bytes32[] memory proof,
        bytes32 root,
        bytes32 leaf
    ) internal pure returns (bool, uint256) {
        bytes32 computedHash = leaf;
        uint256 index = 0;

        for (uint256 i = 0; i < proof.length; i++) {
            index *= 2;
            bytes32 proofElement = proof[i];

            if (computedHash <= proofElement) {
                // Hash(current computed hash + current element of the proof)
                computedHash = keccak256(abi.encodePacked(computedHash, proofElement));
            } else {
                // Hash(current element of the proof + current computed hash)
                computedHash = keccak256(abi.encodePacked(proofElement, computedHash));
                index += 1;
            }
        }

        // Check if the computed hash (root) is equal to the provided root
        return (computedHash == root, index);
    }
}

// SPDX-License-Identifier: Apache-2.0
pragma solidity ^0.8;

error InvalidPermission();
error InvalidIndex();
error NothingToReveal();
error Bot();
error ST();
error CrossedLimitLazyMintedTokens();
error CrossedLimitMinTokenIdGreaterThanMaxTotalSupply();
error CrossedLimitQuantityPerTransaction();
error CrossedLimitMaxClaimableSupply();
error CrossedLimitMaxTotalSupply();
error CrossedLimitMaxWalletClaimCount();
error InvalidPrice();
error InvalidQuantity();
error InvalidTime();
error InvalidGating();
error InvalidMerkleProof();
error InvalidMaxQuantityProof();
error MaxBps();
error ClaimPaused();
error NoActiveMintCondition();

// SPDX-License-Identifier: Apache-2.0
pragma solidity ^0.8;

import "../../api/issuance/IDropClaimCondition.sol";

interface DropERC1155DataTypes {
  struct ClaimData {
    /// @dev The set of all claim conditions, at any given moment.
     mapping(uint256 => IDropClaimConditionV0.ClaimConditionList) claimCondition;

    /// @dev Mapping from token ID => claimer wallet address => total number of NFTs of the token ID a wallet has claimed.
    mapping(uint256 => mapping(address => uint256)) walletClaimCount;

    /// @dev The next token ID of the NFT to "lazy mint".
    uint256 nextTokenIdToMint;

    /// @dev Mapping from token ID => maximum possible total circulating supply of tokens with that ID.
    mapping(uint256 => uint256) maxTotalSupply;

    /// @dev Mapping from token ID => the max number of NFTs of the token ID a wallet can claim.
    mapping(uint256 => uint256) maxWalletClaimCount;

    /// @dev The address that receives all platform fees from all sales.
    address platformFeeRecipient;

    /// @dev The % of primary sales collected as platform fees.
    uint16 platformFeeBps;

    /// @dev Mapping from token ID => total circulating supply of tokens with that ID.
    mapping(uint256 => uint256) totalSupply;

    /// @dev Mapping from token ID => the address of the recipient of primary sales.
    mapping(uint256 => address) saleRecipient;
  }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.0 (metatx/ERC2771Context.sol)

pragma solidity ^0.8;

import "@openzeppelin/contracts-upgradeable/utils/ContextUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";

/**
 * @dev Context variant with ERC2771 support.
 */
abstract contract ERC2771ContextUpgradeable is Initializable, ContextUpgradeable {
    mapping(address => bool) private _trustedForwarder;

    function __ERC2771Context_init(address[] memory trustedForwarder) internal onlyInitializing {
        __Context_init_unchained();
        __ERC2771Context_init_unchained(trustedForwarder);
    }

    function __ERC2771Context_init_unchained(address[] memory trustedForwarder) internal onlyInitializing {
        for (uint256 i = 0; i < trustedForwarder.length; i++) {
            _trustedForwarder[trustedForwarder[i]] = true;
        }
    }

    function isTrustedForwarder(address forwarder) public view virtual returns (bool) {
        return _trustedForwarder[forwarder];
    }

    function _msgSender() internal view virtual override returns (address sender) {
        if (isTrustedForwarder(msg.sender)) {
            // The assembly code is more direct than the Solidity version using `abi.decode`.
            assembly {
                sender := shr(96, calldataload(sub(calldatasize(), 20)))
            }
        } else {
            return super._msgSender();
        }
    }

    function _msgData() internal view virtual override returns (bytes calldata) {
        if (isTrustedForwarder(msg.sender)) {
            return msg.data[:msg.data.length - 20];
        } else {
            return super._msgData();
        }
    }

    uint256[49] private __gap;
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.5.0) (utils/Multicall.sol)

pragma solidity ^0.8.0;

import "./AddressUpgradeable.sol";
import "../proxy/utils/Initializable.sol";

/**
 * @dev Provides a function to batch together multiple calls in a single external call.
 *
 * _Available since v4.1._
 */
abstract contract MulticallUpgradeable is Initializable {
    function __Multicall_init() internal onlyInitializing {
    }

    function __Multicall_init_unchained() internal onlyInitializing {
    }
    /**
     * @dev Receives and executes a batch of function calls on this contract.
     */
    function multicall(bytes[] calldata data) external virtual returns (bytes[] memory results) {
        results = new bytes[](data.length);
        for (uint256 i = 0; i < data.length; i++) {
            results[i] = _functionDelegateCall(address(this), data[i]);
        }
        return results;
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-string-}[`functionCall`],
     * but performing a delegate call.
     *
     * _Available since v3.4._
     */
    function _functionDelegateCall(address target, bytes memory data) private returns (bytes memory) {
        require(AddressUpgradeable.isContract(target), "Address: delegate call to non-contract");

        // solhint-disable-next-line avoid-low-level-calls
        (bool success, bytes memory returndata) = target.delegatecall(data);
        return AddressUpgradeable.verifyCallResult(success, returndata, "Address: low-level delegate call failed");
    }

    /**
     * @dev This empty reserved space is put in place to allow future versions to add new
     * variables without shifting down storage in the inheritance chain.
     * See https://docs.openzeppelin.com/contracts/4.x/upgradeable#storage_gaps
     */
    uint256[50] private __gap;
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.5.0) (interfaces/IERC2981.sol)

pragma solidity ^0.8.0;

import "./IERC165Upgradeable.sol";

/**
 * @dev Interface for the NFT Royalty Standard.
 *
 * A standardized way to retrieve royalty payment information for non-fungible tokens (NFTs) to enable universal
 * support for royalty payments across all NFT marketplaces and ecosystem participants.
 *
 * _Available since v4.5._
 */
interface IERC2981Upgradeable is IERC165Upgradeable {
    /**
     * @dev Returns how much royalty is owed and to whom, based on a sale price that may be denominated in any unit of
     * exchange. The royalty amount is denominated and should be payed in that same unit of exchange.
     */
    function royaltyInfo(uint256 tokenId, uint256 salePrice)
        external
        view
        returns (address receiver, uint256 royaltyAmount);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.5.0) (access/AccessControlEnumerable.sol)

pragma solidity ^0.8.0;

import "./IAccessControlEnumerableUpgradeable.sol";
import "./AccessControlUpgradeable.sol";
import "../utils/structs/EnumerableSetUpgradeable.sol";
import "../proxy/utils/Initializable.sol";

/**
 * @dev Extension of {AccessControl} that allows enumerating the members of each role.
 */
abstract contract AccessControlEnumerableUpgradeable is Initializable, IAccessControlEnumerableUpgradeable, AccessControlUpgradeable {
    function __AccessControlEnumerable_init() internal onlyInitializing {
    }

    function __AccessControlEnumerable_init_unchained() internal onlyInitializing {
    }
    using EnumerableSetUpgradeable for EnumerableSetUpgradeable.AddressSet;

    mapping(bytes32 => EnumerableSetUpgradeable.AddressSet) private _roleMembers;

    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId) public view virtual override returns (bool) {
        return interfaceId == type(IAccessControlEnumerableUpgradeable).interfaceId || super.supportsInterface(interfaceId);
    }

    /**
     * @dev Returns one of the accounts that have `role`. `index` must be a
     * value between 0 and {getRoleMemberCount}, non-inclusive.
     *
     * Role bearers are not sorted in any particular way, and their ordering may
     * change at any point.
     *
     * WARNING: When using {getRoleMember} and {getRoleMemberCount}, make sure
     * you perform all queries on the same block. See the following
     * https://forum.openzeppelin.com/t/iterating-over-elements-on-enumerableset-in-openzeppelin-contracts/2296[forum post]
     * for more information.
     */
    function getRoleMember(bytes32 role, uint256 index) public view virtual override returns (address) {
        return _roleMembers[role].at(index);
    }

    /**
     * @dev Returns the number of accounts that have `role`. Can be used
     * together with {getRoleMember} to enumerate all bearers of a role.
     */
    function getRoleMemberCount(bytes32 role) public view virtual override returns (uint256) {
        return _roleMembers[role].length();
    }

    /**
     * @dev Overload {_grantRole} to track enumerable memberships
     */
    function _grantRole(bytes32 role, address account) internal virtual override {
        super._grantRole(role, account);
        _roleMembers[role].add(account);
    }

    /**
     * @dev Overload {_revokeRole} to track enumerable memberships
     */
    function _revokeRole(bytes32 role, address account) internal virtual override {
        super._revokeRole(role, account);
        _roleMembers[role].remove(account);
    }

    /**
     * @dev This empty reserved space is put in place to allow future versions to add new
     * variables without shifting down storage in the inheritance chain.
     * See https://docs.openzeppelin.com/contracts/4.x/upgradeable#storage_gaps
     */
    uint256[49] private __gap;
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (security/ReentrancyGuard.sol)

pragma solidity ^0.8.0;
import "../proxy/utils/Initializable.sol";

/**
 * @dev Contract module that helps prevent reentrant calls to a function.
 *
 * Inheriting from `ReentrancyGuard` will make the {nonReentrant} modifier
 * available, which can be applied to functions to make sure there are no nested
 * (reentrant) calls to them.
 *
 * Note that because there is a single `nonReentrant` guard, functions marked as
 * `nonReentrant` may not call one another. This can be worked around by making
 * those functions `private`, and then adding `external` `nonReentrant` entry
 * points to them.
 *
 * TIP: If you would like to learn more about reentrancy and alternative ways
 * to protect against it, check out our blog post
 * https://blog.openzeppelin.com/reentrancy-after-istanbul/[Reentrancy After Istanbul].
 */
abstract contract ReentrancyGuardUpgradeable is Initializable {
    // Booleans are more expensive than uint256 or any type that takes up a full
    // word because each write operation emits an extra SLOAD to first read the
    // slot's contents, replace the bits taken up by the boolean, and then write
    // back. This is the compiler's defense against contract upgrades and
    // pointer aliasing, and it cannot be disabled.

    // The values being non-zero value makes deployment a bit more expensive,
    // but in exchange the refund on every call to nonReentrant will be lower in
    // amount. Since refunds are capped to a percentage of the total
    // transaction's gas, it is best to keep them low in cases like this one, to
    // increase the likelihood of the full refund coming into effect.
    uint256 private constant _NOT_ENTERED = 1;
    uint256 private constant _ENTERED = 2;

    uint256 private _status;

    function __ReentrancyGuard_init() internal onlyInitializing {
        __ReentrancyGuard_init_unchained();
    }

    function __ReentrancyGuard_init_unchained() internal onlyInitializing {
        _status = _NOT_ENTERED;
    }

    /**
     * @dev Prevents a contract from calling itself, directly or indirectly.
     * Calling a `nonReentrant` function from another `nonReentrant`
     * function is not supported. It is possible to prevent this from happening
     * by making the `nonReentrant` function external, and making it call a
     * `private` function that does the actual work.
     */
    modifier nonReentrant() {
        // On the first call to nonReentrant, _notEntered will be true
        require(_status != _ENTERED, "ReentrancyGuard: reentrant call");

        // Any calls to nonReentrant after this point will fail
        _status = _ENTERED;

        _;

        // By storing the original value once again, a refund is triggered (see
        // https://eips.ethereum.org/EIPS/eip-2200)
        _status = _NOT_ENTERED;
    }

    /**
     * @dev This empty reserved space is put in place to allow future versions to add new
     * variables without shifting down storage in the inheritance chain.
     * See https://docs.openzeppelin.com/contracts/4.x/upgradeable#storage_gaps
     */
    uint256[49] private __gap;
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/Counters.sol)

pragma solidity ^0.8.0;

/**
 * @title Counters
 * @author Matt Condon (@shrugs)
 * @dev Provides counters that can only be incremented, decremented or reset. This can be used e.g. to track the number
 * of elements in a mapping, issuing ERC721 ids, or counting request ids.
 *
 * Include with `using Counters for Counters.Counter;`
 */
library CountersUpgradeable {
    struct Counter {
        // This variable should never be directly accessed by users of the library: interactions must be restricted to
        // the library's function. As of Solidity v0.5.2, this cannot be enforced, though there is a proposal to add
        // this feature: see https://github.com/ethereum/solidity/issues/4637
        uint256 _value; // default: 0
    }

    function current(Counter storage counter) internal view returns (uint256) {
        return counter._value;
    }

    function increment(Counter storage counter) internal {
        unchecked {
            counter._value += 1;
        }
    }

    function decrement(Counter storage counter) internal {
        uint256 value = counter._value;
        require(value > 0, "Counter: decrement overflow");
        unchecked {
            counter._value = value - 1;
        }
    }

    function reset(Counter storage counter) internal {
        counter._value = 0;
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (token/ERC1155/ERC1155.sol)

pragma solidity ^0.8.0;

import "./IERC1155Upgradeable.sol";
import "./IERC1155ReceiverUpgradeable.sol";
import "./extensions/IERC1155MetadataURIUpgradeable.sol";
import "../../utils/AddressUpgradeable.sol";
import "../../utils/ContextUpgradeable.sol";
import "../../utils/introspection/ERC165Upgradeable.sol";
import "../../proxy/utils/Initializable.sol";

/**
 * @dev Implementation of the basic standard multi-token.
 * See https://eips.ethereum.org/EIPS/eip-1155
 * Originally based on code by Enjin: https://github.com/enjin/erc-1155
 *
 * _Available since v3.1._
 */
contract ERC1155Upgradeable is Initializable, ContextUpgradeable, ERC165Upgradeable, IERC1155Upgradeable, IERC1155MetadataURIUpgradeable {
    using AddressUpgradeable for address;

    // Mapping from token ID to account balances
    mapping(uint256 => mapping(address => uint256)) private _balances;

    // Mapping from account to operator approvals
    mapping(address => mapping(address => bool)) private _operatorApprovals;

    // Used as the URI for all token types by relying on ID substitution, e.g. https://token-cdn-domain/{id}.json
    string private _uri;

    /**
     * @dev See {_setURI}.
     */
    function __ERC1155_init(string memory uri_) internal onlyInitializing {
        __ERC1155_init_unchained(uri_);
    }

    function __ERC1155_init_unchained(string memory uri_) internal onlyInitializing {
        _setURI(uri_);
    }

    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId) public view virtual override(ERC165Upgradeable, IERC165Upgradeable) returns (bool) {
        return
            interfaceId == type(IERC1155Upgradeable).interfaceId ||
            interfaceId == type(IERC1155MetadataURIUpgradeable).interfaceId ||
            super.supportsInterface(interfaceId);
    }

    /**
     * @dev See {IERC1155MetadataURI-uri}.
     *
     * This implementation returns the same URI for *all* token types. It relies
     * on the token type ID substitution mechanism
     * https://eips.ethereum.org/EIPS/eip-1155#metadata[defined in the EIP].
     *
     * Clients calling this function must replace the `\{id\}` substring with the
     * actual token type ID.
     */
    function uri(uint256) public view virtual override returns (string memory) {
        return _uri;
    }

    /**
     * @dev See {IERC1155-balanceOf}.
     *
     * Requirements:
     *
     * - `account` cannot be the zero address.
     */
    function balanceOf(address account, uint256 id) public view virtual override returns (uint256) {
        require(account != address(0), "ERC1155: balance query for the zero address");
        return _balances[id][account];
    }

    /**
     * @dev See {IERC1155-balanceOfBatch}.
     *
     * Requirements:
     *
     * - `accounts` and `ids` must have the same length.
     */
    function balanceOfBatch(address[] memory accounts, uint256[] memory ids)
        public
        view
        virtual
        override
        returns (uint256[] memory)
    {
        require(accounts.length == ids.length, "ERC1155: accounts and ids length mismatch");

        uint256[] memory batchBalances = new uint256[](accounts.length);

        for (uint256 i = 0; i < accounts.length; ++i) {
            batchBalances[i] = balanceOf(accounts[i], ids[i]);
        }

        return batchBalances;
    }

    /**
     * @dev See {IERC1155-setApprovalForAll}.
     */
    function setApprovalForAll(address operator, bool approved) public virtual override {
        _setApprovalForAll(_msgSender(), operator, approved);
    }

    /**
     * @dev See {IERC1155-isApprovedForAll}.
     */
    function isApprovedForAll(address account, address operator) public view virtual override returns (bool) {
        return _operatorApprovals[account][operator];
    }

    /**
     * @dev See {IERC1155-safeTransferFrom}.
     */
    function safeTransferFrom(
        address from,
        address to,
        uint256 id,
        uint256 amount,
        bytes memory data
    ) public virtual override {
        require(
            from == _msgSender() || isApprovedForAll(from, _msgSender()),
            "ERC1155: caller is not owner nor approved"
        );
        _safeTransferFrom(from, to, id, amount, data);
    }

    /**
     * @dev See {IERC1155-safeBatchTransferFrom}.
     */
    function safeBatchTransferFrom(
        address from,
        address to,
        uint256[] memory ids,
        uint256[] memory amounts,
        bytes memory data
    ) public virtual override {
        require(
            from == _msgSender() || isApprovedForAll(from, _msgSender()),
            "ERC1155: transfer caller is not owner nor approved"
        );
        _safeBatchTransferFrom(from, to, ids, amounts, data);
    }

    /**
     * @dev Transfers `amount` tokens of token type `id` from `from` to `to`.
     *
     * Emits a {TransferSingle} event.
     *
     * Requirements:
     *
     * - `to` cannot be the zero address.
     * - `from` must have a balance of tokens of type `id` of at least `amount`.
     * - If `to` refers to a smart contract, it must implement {IERC1155Receiver-onERC1155Received} and return the
     * acceptance magic value.
     */
    function _safeTransferFrom(
        address from,
        address to,
        uint256 id,
        uint256 amount,
        bytes memory data
    ) internal virtual {
        require(to != address(0), "ERC1155: transfer to the zero address");

        address operator = _msgSender();

        _beforeTokenTransfer(operator, from, to, _asSingletonArray(id), _asSingletonArray(amount), data);

        uint256 fromBalance = _balances[id][from];
        require(fromBalance >= amount, "ERC1155: insufficient balance for transfer");
        unchecked {
            _balances[id][from] = fromBalance - amount;
        }
        _balances[id][to] += amount;

        emit TransferSingle(operator, from, to, id, amount);

        _doSafeTransferAcceptanceCheck(operator, from, to, id, amount, data);
    }

    /**
     * @dev xref:ROOT:erc1155.adoc#batch-operations[Batched] version of {_safeTransferFrom}.
     *
     * Emits a {TransferBatch} event.
     *
     * Requirements:
     *
     * - If `to` refers to a smart contract, it must implement {IERC1155Receiver-onERC1155BatchReceived} and return the
     * acceptance magic value.
     */
    function _safeBatchTransferFrom(
        address from,
        address to,
        uint256[] memory ids,
        uint256[] memory amounts,
        bytes memory data
    ) internal virtual {
        require(ids.length == amounts.length, "ERC1155: ids and amounts length mismatch");
        require(to != address(0), "ERC1155: transfer to the zero address");

        address operator = _msgSender();

        _beforeTokenTransfer(operator, from, to, ids, amounts, data);

        for (uint256 i = 0; i < ids.length; ++i) {
            uint256 id = ids[i];
            uint256 amount = amounts[i];

            uint256 fromBalance = _balances[id][from];
            require(fromBalance >= amount, "ERC1155: insufficient balance for transfer");
            unchecked {
                _balances[id][from] = fromBalance - amount;
            }
            _balances[id][to] += amount;
        }

        emit TransferBatch(operator, from, to, ids, amounts);

        _doSafeBatchTransferAcceptanceCheck(operator, from, to, ids, amounts, data);
    }

    /**
     * @dev Sets a new URI for all token types, by relying on the token type ID
     * substitution mechanism
     * https://eips.ethereum.org/EIPS/eip-1155#metadata[defined in the EIP].
     *
     * By this mechanism, any occurrence of the `\{id\}` substring in either the
     * URI or any of the amounts in the JSON file at said URI will be replaced by
     * clients with the token type ID.
     *
     * For example, the `https://token-cdn-domain/\{id\}.json` URI would be
     * interpreted by clients as
     * `https://token-cdn-domain/000000000000000000000000000000000000000000000000000000000004cce0.json`
     * for token type ID 0x4cce0.
     *
     * See {uri}.
     *
     * Because these URIs cannot be meaningfully represented by the {URI} event,
     * this function emits no events.
     */
    function _setURI(string memory newuri) internal virtual {
        _uri = newuri;
    }

    /**
     * @dev Creates `amount` tokens of token type `id`, and assigns them to `to`.
     *
     * Emits a {TransferSingle} event.
     *
     * Requirements:
     *
     * - `to` cannot be the zero address.
     * - If `to` refers to a smart contract, it must implement {IERC1155Receiver-onERC1155Received} and return the
     * acceptance magic value.
     */
    function _mint(
        address to,
        uint256 id,
        uint256 amount,
        bytes memory data
    ) internal virtual {
        require(to != address(0), "ERC1155: mint to the zero address");

        address operator = _msgSender();

        _beforeTokenTransfer(operator, address(0), to, _asSingletonArray(id), _asSingletonArray(amount), data);

        _balances[id][to] += amount;
        emit TransferSingle(operator, address(0), to, id, amount);

        _doSafeTransferAcceptanceCheck(operator, address(0), to, id, amount, data);
    }

    /**
     * @dev xref:ROOT:erc1155.adoc#batch-operations[Batched] version of {_mint}.
     *
     * Requirements:
     *
     * - `ids` and `amounts` must have the same length.
     * - If `to` refers to a smart contract, it must implement {IERC1155Receiver-onERC1155BatchReceived} and return the
     * acceptance magic value.
     */
    function _mintBatch(
        address to,
        uint256[] memory ids,
        uint256[] memory amounts,
        bytes memory data
    ) internal virtual {
        require(to != address(0), "ERC1155: mint to the zero address");
        require(ids.length == amounts.length, "ERC1155: ids and amounts length mismatch");

        address operator = _msgSender();

        _beforeTokenTransfer(operator, address(0), to, ids, amounts, data);

        for (uint256 i = 0; i < ids.length; i++) {
            _balances[ids[i]][to] += amounts[i];
        }

        emit TransferBatch(operator, address(0), to, ids, amounts);

        _doSafeBatchTransferAcceptanceCheck(operator, address(0), to, ids, amounts, data);
    }

    /**
     * @dev Destroys `amount` tokens of token type `id` from `from`
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `from` must have at least `amount` tokens of token type `id`.
     */
    function _burn(
        address from,
        uint256 id,
        uint256 amount
    ) internal virtual {
        require(from != address(0), "ERC1155: burn from the zero address");

        address operator = _msgSender();

        _beforeTokenTransfer(operator, from, address(0), _asSingletonArray(id), _asSingletonArray(amount), "");

        uint256 fromBalance = _balances[id][from];
        require(fromBalance >= amount, "ERC1155: burn amount exceeds balance");
        unchecked {
            _balances[id][from] = fromBalance - amount;
        }

        emit TransferSingle(operator, from, address(0), id, amount);
    }

    /**
     * @dev xref:ROOT:erc1155.adoc#batch-operations[Batched] version of {_burn}.
     *
     * Requirements:
     *
     * - `ids` and `amounts` must have the same length.
     */
    function _burnBatch(
        address from,
        uint256[] memory ids,
        uint256[] memory amounts
    ) internal virtual {
        require(from != address(0), "ERC1155: burn from the zero address");
        require(ids.length == amounts.length, "ERC1155: ids and amounts length mismatch");

        address operator = _msgSender();

        _beforeTokenTransfer(operator, from, address(0), ids, amounts, "");

        for (uint256 i = 0; i < ids.length; i++) {
            uint256 id = ids[i];
            uint256 amount = amounts[i];

            uint256 fromBalance = _balances[id][from];
            require(fromBalance >= amount, "ERC1155: burn amount exceeds balance");
            unchecked {
                _balances[id][from] = fromBalance - amount;
            }
        }

        emit TransferBatch(operator, from, address(0), ids, amounts);
    }

    /**
     * @dev Approve `operator` to operate on all of `owner` tokens
     *
     * Emits a {ApprovalForAll} event.
     */
    function _setApprovalForAll(
        address owner,
        address operator,
        bool approved
    ) internal virtual {
        require(owner != operator, "ERC1155: setting approval status for self");
        _operatorApprovals[owner][operator] = approved;
        emit ApprovalForAll(owner, operator, approved);
    }

    /**
     * @dev Hook that is called before any token transfer. This includes minting
     * and burning, as well as batched variants.
     *
     * The same hook is called on both single and batched variants. For single
     * transfers, the length of the `id` and `amount` arrays will be 1.
     *
     * Calling conditions (for each `id` and `amount` pair):
     *
     * - When `from` and `to` are both non-zero, `amount` of ``from``'s tokens
     * of token type `id` will be  transferred to `to`.
     * - When `from` is zero, `amount` tokens of token type `id` will be minted
     * for `to`.
     * - when `to` is zero, `amount` of ``from``'s tokens of token type `id`
     * will be burned.
     * - `from` and `to` are never both zero.
     * - `ids` and `amounts` have the same, non-zero length.
     *
     * To learn more about hooks, head to xref:ROOT:extending-contracts.adoc#using-hooks[Using Hooks].
     */
    function _beforeTokenTransfer(
        address operator,
        address from,
        address to,
        uint256[] memory ids,
        uint256[] memory amounts,
        bytes memory data
    ) internal virtual {}

    function _doSafeTransferAcceptanceCheck(
        address operator,
        address from,
        address to,
        uint256 id,
        uint256 amount,
        bytes memory data
    ) private {
        if (to.isContract()) {
            try IERC1155ReceiverUpgradeable(to).onERC1155Received(operator, from, id, amount, data) returns (bytes4 response) {
                if (response != IERC1155ReceiverUpgradeable.onERC1155Received.selector) {
                    revert("ERC1155: ERC1155Receiver rejected tokens");
                }
            } catch Error(string memory reason) {
                revert(reason);
            } catch {
                revert("ERC1155: transfer to non ERC1155Receiver implementer");
            }
        }
    }

    function _doSafeBatchTransferAcceptanceCheck(
        address operator,
        address from,
        address to,
        uint256[] memory ids,
        uint256[] memory amounts,
        bytes memory data
    ) private {
        if (to.isContract()) {
            try IERC1155ReceiverUpgradeable(to).onERC1155BatchReceived(operator, from, ids, amounts, data) returns (
                bytes4 response
            ) {
                if (response != IERC1155ReceiverUpgradeable.onERC1155BatchReceived.selector) {
                    revert("ERC1155: ERC1155Receiver rejected tokens");
                }
            } catch Error(string memory reason) {
                revert(reason);
            } catch {
                revert("ERC1155: transfer to non ERC1155Receiver implementer");
            }
        }
    }

    function _asSingletonArray(uint256 element) private pure returns (uint256[] memory) {
        uint256[] memory array = new uint256[](1);
        array[0] = element;

        return array;
    }

    /**
     * @dev This empty reserved space is put in place to allow future versions to add new
     * variables without shifting down storage in the inheritance chain.
     * See https://docs.openzeppelin.com/contracts/4.x/upgradeable#storage_gaps
     */
    uint256[47] private __gap;
}

// SPDX-License-Identifier: Apache-2.0
pragma solidity ^0.8;

// Helper interfaces
import { IWETH } from "../interfaces/IWETH.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC20/IERC20Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC20/utils/SafeERC20Upgradeable.sol";

library CurrencyTransferLib {
    using SafeERC20Upgradeable for IERC20Upgradeable;

    /// @dev The address interpreted as native token of the chain.
    address public constant NATIVE_TOKEN = 0xEeeeeEeeeEeEeeEeEeEeeEEEeeeeEeeeeeeeEEeE;

    /// @dev Transfers a given amount of currency.
    function transferCurrency(
        address _currency,
        address _from,
        address _to,
        uint256 _amount
    ) internal {
        if (_amount == 0) {
            return;
        }

        if (_currency == NATIVE_TOKEN) {
            safeTransferNativeToken(_to, _amount);
        } else {
            safeTransferERC20(_currency, _from, _to, _amount);
        }
    }

    /// @dev Transfers a given amount of currency. (With native token wrapping)
    function transferCurrencyWithWrapper(
        address _currency,
        address _from,
        address _to,
        uint256 _amount,
        address _nativeTokenWrapper
    ) internal {
        if (_amount == 0) {
            return;
        }

        if (_currency == NATIVE_TOKEN) {
            if (_from == address(this)) {
                // withdraw from weth then transfer withdrawn native token to recipient
                IWETH(_nativeTokenWrapper).withdraw(_amount);
                safeTransferNativeTokenWithWrapper(_to, _amount, _nativeTokenWrapper);
            } else if (_to == address(this)) {
                // store native currency in weth
                require(_amount == msg.value, "msg.value != amount");
                IWETH(_nativeTokenWrapper).deposit{ value: _amount }();
            } else {
                safeTransferNativeTokenWithWrapper(_to, _amount, _nativeTokenWrapper);
            }
        } else {
            safeTransferERC20(_currency, _from, _to, _amount);
        }
    }

    /// @dev Transfer `amount` of ERC20 token from `from` to `to`.
    function safeTransferERC20(
        address _currency,
        address _from,
        address _to,
        uint256 _amount
    ) internal {
        if (_from == _to) {
            return;
        }

        if (_from == address(this)) {
            IERC20Upgradeable(_currency).safeTransfer(_to, _amount);
        } else {
            IERC20Upgradeable(_currency).safeTransferFrom(_from, _to, _amount);
        }
    }

    /// @dev Transfers `amount` of native token to `to`.
    function safeTransferNativeToken(address to, uint256 value) internal {
        // solhint-disable avoid-low-level-calls
        // slither-disable-next-line low-level-calls
        (bool success, ) = to.call{ value: value }("");
        require(success, "native token transfer failed");
    }

    /// @dev Transfers `amount` of native token to `to`. (With native token wrapping)
    function safeTransferNativeTokenWithWrapper(
        address to,
        uint256 value,
        address _nativeTokenWrapper
    ) internal {
        // solhint-disable avoid-low-level-calls
        // slither-disable-next-line low-level-calls
        (bool success, ) = to.call{ value: value }("");
        if (!success) {
            IWETH(_nativeTokenWrapper).deposit{ value: value }();
            IERC20Upgradeable(_nativeTokenWrapper).safeTransfer(to, value);
        }
    }
}

// SPDX-License-Identifier: Apache-2.0
pragma solidity ^0.8;

interface IWETH {
    function deposit() external payable;

    function withdraw(uint256 amount) external;

    function transfer(address to, uint256 value) external returns (bool);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (token/ERC20/utils/SafeERC20.sol)

pragma solidity ^0.8.0;

import "../IERC20Upgradeable.sol";
import "../../../utils/AddressUpgradeable.sol";

/**
 * @title SafeERC20
 * @dev Wrappers around ERC20 operations that throw on failure (when the token
 * contract returns false). Tokens that return no value (and instead revert or
 * throw on failure) are also supported, non-reverting calls are assumed to be
 * successful.
 * To use this library you can add a `using SafeERC20 for IERC20;` statement to your contract,
 * which allows you to call the safe operations as `token.safeTransfer(...)`, etc.
 */
library SafeERC20Upgradeable {
    using AddressUpgradeable for address;

    function safeTransfer(
        IERC20Upgradeable token,
        address to,
        uint256 value
    ) internal {
        _callOptionalReturn(token, abi.encodeWithSelector(token.transfer.selector, to, value));
    }

    function safeTransferFrom(
        IERC20Upgradeable token,
        address from,
        address to,
        uint256 value
    ) internal {
        _callOptionalReturn(token, abi.encodeWithSelector(token.transferFrom.selector, from, to, value));
    }

    /**
     * @dev Deprecated. This function has issues similar to the ones found in
     * {IERC20-approve}, and its usage is discouraged.
     *
     * Whenever possible, use {safeIncreaseAllowance} and
     * {safeDecreaseAllowance} instead.
     */
    function safeApprove(
        IERC20Upgradeable token,
        address spender,
        uint256 value
    ) internal {
        // safeApprove should only be called when setting an initial allowance,
        // or when resetting it to zero. To increase and decrease it, use
        // 'safeIncreaseAllowance' and 'safeDecreaseAllowance'
        require(
            (value == 0) || (token.allowance(address(this), spender) == 0),
            "SafeERC20: approve from non-zero to non-zero allowance"
        );
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, value));
    }

    function safeIncreaseAllowance(
        IERC20Upgradeable token,
        address spender,
        uint256 value
    ) internal {
        uint256 newAllowance = token.allowance(address(this), spender) + value;
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
    }

    function safeDecreaseAllowance(
        IERC20Upgradeable token,
        address spender,
        uint256 value
    ) internal {
        unchecked {
            uint256 oldAllowance = token.allowance(address(this), spender);
            require(oldAllowance >= value, "SafeERC20: decreased allowance below zero");
            uint256 newAllowance = oldAllowance - value;
            _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
        }
    }

    /**
     * @dev Imitates a Solidity high-level call (i.e. a regular function call to a contract), relaxing the requirement
     * on the return value: the return value is optional (but if data is returned, it must not be false).
     * @param token The token targeted by the call.
     * @param data The call data (encoded using abi.encode or one of its variants).
     */
    function _callOptionalReturn(IERC20Upgradeable token, bytes memory data) private {
        // We need to perform a low level call here, to bypass Solidity's return data size checking mechanism, since
        // we're implementing it ourselves. We use {Address.functionCall} to perform this call, which verifies that
        // the target address contains contract code and also asserts for success in the low-level call.

        bytes memory returndata = address(token).functionCall(data, "SafeERC20: low-level call failed");
        if (returndata.length > 0) {
            // Return data is optional
            require(abi.decode(returndata, (bool)), "SafeERC20: ERC20 operation did not succeed");
        }
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (interfaces/IERC165.sol)

pragma solidity ^0.8.0;

import "../utils/introspection/IERC165Upgradeable.sol";

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (access/IAccessControlEnumerable.sol)

pragma solidity ^0.8.0;

import "./IAccessControlUpgradeable.sol";

/**
 * @dev External interface of AccessControlEnumerable declared to support ERC165 detection.
 */
interface IAccessControlEnumerableUpgradeable is IAccessControlUpgradeable {
    /**
     * @dev Returns one of the accounts that have `role`. `index` must be a
     * value between 0 and {getRoleMemberCount}, non-inclusive.
     *
     * Role bearers are not sorted in any particular way, and their ordering may
     * change at any point.
     *
     * WARNING: When using {getRoleMember} and {getRoleMemberCount}, make sure
     * you perform all queries on the same block. See the following
     * https://forum.openzeppelin.com/t/iterating-over-elements-on-enumerableset-in-openzeppelin-contracts/2296[forum post]
     * for more information.
     */
    function getRoleMember(bytes32 role, uint256 index) external view returns (address);

    /**
     * @dev Returns the number of accounts that have `role`. Can be used
     * together with {getRoleMember} to enumerate all bearers of a role.
     */
    function getRoleMemberCount(bytes32 role) external view returns (uint256);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.5.0) (access/AccessControl.sol)

pragma solidity ^0.8.0;

import "./IAccessControlUpgradeable.sol";
import "../utils/ContextUpgradeable.sol";
import "../utils/StringsUpgradeable.sol";
import "../utils/introspection/ERC165Upgradeable.sol";
import "../proxy/utils/Initializable.sol";

/**
 * @dev Contract module that allows children to implement role-based access
 * control mechanisms. This is a lightweight version that doesn't allow enumerating role
 * members except through off-chain means by accessing the contract event logs. Some
 * applications may benefit from on-chain enumerability, for those cases see
 * {AccessControlEnumerable}.
 *
 * Roles are referred to by their `bytes32` identifier. These should be exposed
 * in the external API and be unique. The best way to achieve this is by
 * using `public constant` hash digests:
 *
 * ```
 * bytes32 public constant MY_ROLE = keccak256("MY_ROLE");
 * ```
 *
 * Roles can be used to represent a set of permissions. To restrict access to a
 * function call, use {hasRole}:
 *
 * ```
 * function foo() public {
 *     require(hasRole(MY_ROLE, msg.sender));
 *     ...
 * }
 * ```
 *
 * Roles can be granted and revoked dynamically via the {grantRole} and
 * {revokeRole} functions. Each role has an associated admin role, and only
 * accounts that have a role's admin role can call {grantRole} and {revokeRole}.
 *
 * By default, the admin role for all roles is `DEFAULT_ADMIN_ROLE`, which means
 * that only accounts with this role will be able to grant or revoke other
 * roles. More complex role relationships can be created by using
 * {_setRoleAdmin}.
 *
 * WARNING: The `DEFAULT_ADMIN_ROLE` is also its own admin: it has permission to
 * grant and revoke this role. Extra precautions should be taken to secure
 * accounts that have been granted it.
 */
abstract contract AccessControlUpgradeable is Initializable, ContextUpgradeable, IAccessControlUpgradeable, ERC165Upgradeable {
    function __AccessControl_init() internal onlyInitializing {
    }

    function __AccessControl_init_unchained() internal onlyInitializing {
    }
    struct RoleData {
        mapping(address => bool) members;
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
        _checkRole(role, _msgSender());
        _;
    }

    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId) public view virtual override returns (bool) {
        return interfaceId == type(IAccessControlUpgradeable).interfaceId || super.supportsInterface(interfaceId);
    }

    /**
     * @dev Returns `true` if `account` has been granted `role`.
     */
    function hasRole(bytes32 role, address account) public view virtual override returns (bool) {
        return _roles[role].members[account];
    }

    /**
     * @dev Revert with a standard message if `account` is missing `role`.
     *
     * The format of the revert reason is given by the following regular expression:
     *
     *  /^AccessControl: account (0x[0-9a-f]{40}) is missing role (0x[0-9a-f]{64})$/
     */
    function _checkRole(bytes32 role, address account) internal view virtual {
        if (!hasRole(role, account)) {
            revert(
                string(
                    abi.encodePacked(
                        "AccessControl: account ",
                        StringsUpgradeable.toHexString(uint160(account), 20),
                        " is missing role ",
                        StringsUpgradeable.toHexString(uint256(role), 32)
                    )
                )
            );
        }
    }

    /**
     * @dev Returns the admin role that controls `role`. See {grantRole} and
     * {revokeRole}.
     *
     * To change a role's admin, use {_setRoleAdmin}.
     */
    function getRoleAdmin(bytes32 role) public view virtual override returns (bytes32) {
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
    function grantRole(bytes32 role, address account) public virtual override onlyRole(getRoleAdmin(role)) {
        _grantRole(role, account);
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
    function revokeRole(bytes32 role, address account) public virtual override onlyRole(getRoleAdmin(role)) {
        _revokeRole(role, account);
    }

    /**
     * @dev Revokes `role` from the calling account.
     *
     * Roles are often managed via {grantRole} and {revokeRole}: this function's
     * purpose is to provide a mechanism for accounts to lose their privileges
     * if they are compromised (such as when a trusted device is misplaced).
     *
     * If the calling account had been revoked `role`, emits a {RoleRevoked}
     * event.
     *
     * Requirements:
     *
     * - the caller must be `account`.
     */
    function renounceRole(bytes32 role, address account) public virtual override {
        require(account == _msgSender(), "AccessControl: can only renounce roles for self");

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
     *
     * NOTE: This function is deprecated in favor of {_grantRole}.
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

    /**
     * @dev Grants `role` to `account`.
     *
     * Internal function without access restriction.
     */
    function _grantRole(bytes32 role, address account) internal virtual {
        if (!hasRole(role, account)) {
            _roles[role].members[account] = true;
            emit RoleGranted(role, account, _msgSender());
        }
    }

    /**
     * @dev Revokes `role` from `account`.
     *
     * Internal function without access restriction.
     */
    function _revokeRole(bytes32 role, address account) internal virtual {
        if (hasRole(role, account)) {
            _roles[role].members[account] = false;
            emit RoleRevoked(role, account, _msgSender());
        }
    }

    /**
     * @dev This empty reserved space is put in place to allow future versions to add new
     * variables without shifting down storage in the inheritance chain.
     * See https://docs.openzeppelin.com/contracts/4.x/upgradeable#storage_gaps
     */
    uint256[49] private __gap;
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/structs/EnumerableSet.sol)

pragma solidity ^0.8.0;

/**
 * @dev Library for managing
 * https://en.wikipedia.org/wiki/Set_(abstract_data_type)[sets] of primitive
 * types.
 *
 * Sets have the following properties:
 *
 * - Elements are added, removed, and checked for existence in constant time
 * (O(1)).
 * - Elements are enumerated in O(n). No guarantees are made on the ordering.
 *
 * ```
 * contract Example {
 *     // Add the library methods
 *     using EnumerableSet for EnumerableSet.AddressSet;
 *
 *     // Declare a set state variable
 *     EnumerableSet.AddressSet private mySet;
 * }
 * ```
 *
 * As of v3.3.0, sets of type `bytes32` (`Bytes32Set`), `address` (`AddressSet`)
 * and `uint256` (`UintSet`) are supported.
 */
library EnumerableSetUpgradeable {
    // To implement this library for multiple types with as little code
    // repetition as possible, we write it in terms of a generic Set type with
    // bytes32 values.
    // The Set implementation uses private functions, and user-facing
    // implementations (such as AddressSet) are just wrappers around the
    // underlying Set.
    // This means that we can only create new EnumerableSets for types that fit
    // in bytes32.

    struct Set {
        // Storage of set values
        bytes32[] _values;
        // Position of the value in the `values` array, plus 1 because index 0
        // means a value is not in the set.
        mapping(bytes32 => uint256) _indexes;
    }

    /**
     * @dev Add a value to a set. O(1).
     *
     * Returns true if the value was added to the set, that is if it was not
     * already present.
     */
    function _add(Set storage set, bytes32 value) private returns (bool) {
        if (!_contains(set, value)) {
            set._values.push(value);
            // The value is stored at length-1, but we add 1 to all indexes
            // and use 0 as a sentinel value
            set._indexes[value] = set._values.length;
            return true;
        } else {
            return false;
        }
    }

    /**
     * @dev Removes a value from a set. O(1).
     *
     * Returns true if the value was removed from the set, that is if it was
     * present.
     */
    function _remove(Set storage set, bytes32 value) private returns (bool) {
        // We read and store the value's index to prevent multiple reads from the same storage slot
        uint256 valueIndex = set._indexes[value];

        if (valueIndex != 0) {
            // Equivalent to contains(set, value)
            // To delete an element from the _values array in O(1), we swap the element to delete with the last one in
            // the array, and then remove the last element (sometimes called as 'swap and pop').
            // This modifies the order of the array, as noted in {at}.

            uint256 toDeleteIndex = valueIndex - 1;
            uint256 lastIndex = set._values.length - 1;

            if (lastIndex != toDeleteIndex) {
                bytes32 lastvalue = set._values[lastIndex];

                // Move the last value to the index where the value to delete is
                set._values[toDeleteIndex] = lastvalue;
                // Update the index for the moved value
                set._indexes[lastvalue] = valueIndex; // Replace lastvalue's index to valueIndex
            }

            // Delete the slot where the moved value was stored
            set._values.pop();

            // Delete the index for the deleted slot
            delete set._indexes[value];

            return true;
        } else {
            return false;
        }
    }

    /**
     * @dev Returns true if the value is in the set. O(1).
     */
    function _contains(Set storage set, bytes32 value) private view returns (bool) {
        return set._indexes[value] != 0;
    }

    /**
     * @dev Returns the number of values on the set. O(1).
     */
    function _length(Set storage set) private view returns (uint256) {
        return set._values.length;
    }

    /**
     * @dev Returns the value stored at position `index` in the set. O(1).
     *
     * Note that there are no guarantees on the ordering of values inside the
     * array, and it may change when more values are added or removed.
     *
     * Requirements:
     *
     * - `index` must be strictly less than {length}.
     */
    function _at(Set storage set, uint256 index) private view returns (bytes32) {
        return set._values[index];
    }

    /**
     * @dev Return the entire set in an array
     *
     * WARNING: This operation will copy the entire storage to memory, which can be quite expensive. This is designed
     * to mostly be used by view accessors that are queried without any gas fees. Developers should keep in mind that
     * this function has an unbounded cost, and using it as part of a state-changing function may render the function
     * uncallable if the set grows to a point where copying to memory consumes too much gas to fit in a block.
     */
    function _values(Set storage set) private view returns (bytes32[] memory) {
        return set._values;
    }

    // Bytes32Set

    struct Bytes32Set {
        Set _inner;
    }

    /**
     * @dev Add a value to a set. O(1).
     *
     * Returns true if the value was added to the set, that is if it was not
     * already present.
     */
    function add(Bytes32Set storage set, bytes32 value) internal returns (bool) {
        return _add(set._inner, value);
    }

    /**
     * @dev Removes a value from a set. O(1).
     *
     * Returns true if the value was removed from the set, that is if it was
     * present.
     */
    function remove(Bytes32Set storage set, bytes32 value) internal returns (bool) {
        return _remove(set._inner, value);
    }

    /**
     * @dev Returns true if the value is in the set. O(1).
     */
    function contains(Bytes32Set storage set, bytes32 value) internal view returns (bool) {
        return _contains(set._inner, value);
    }

    /**
     * @dev Returns the number of values in the set. O(1).
     */
    function length(Bytes32Set storage set) internal view returns (uint256) {
        return _length(set._inner);
    }

    /**
     * @dev Returns the value stored at position `index` in the set. O(1).
     *
     * Note that there are no guarantees on the ordering of values inside the
     * array, and it may change when more values are added or removed.
     *
     * Requirements:
     *
     * - `index` must be strictly less than {length}.
     */
    function at(Bytes32Set storage set, uint256 index) internal view returns (bytes32) {
        return _at(set._inner, index);
    }

    /**
     * @dev Return the entire set in an array
     *
     * WARNING: This operation will copy the entire storage to memory, which can be quite expensive. This is designed
     * to mostly be used by view accessors that are queried without any gas fees. Developers should keep in mind that
     * this function has an unbounded cost, and using it as part of a state-changing function may render the function
     * uncallable if the set grows to a point where copying to memory consumes too much gas to fit in a block.
     */
    function values(Bytes32Set storage set) internal view returns (bytes32[] memory) {
        return _values(set._inner);
    }

    // AddressSet

    struct AddressSet {
        Set _inner;
    }

    /**
     * @dev Add a value to a set. O(1).
     *
     * Returns true if the value was added to the set, that is if it was not
     * already present.
     */
    function add(AddressSet storage set, address value) internal returns (bool) {
        return _add(set._inner, bytes32(uint256(uint160(value))));
    }

    /**
     * @dev Removes a value from a set. O(1).
     *
     * Returns true if the value was removed from the set, that is if it was
     * present.
     */
    function remove(AddressSet storage set, address value) internal returns (bool) {
        return _remove(set._inner, bytes32(uint256(uint160(value))));
    }

    /**
     * @dev Returns true if the value is in the set. O(1).
     */
    function contains(AddressSet storage set, address value) internal view returns (bool) {
        return _contains(set._inner, bytes32(uint256(uint160(value))));
    }

    /**
     * @dev Returns the number of values in the set. O(1).
     */
    function length(AddressSet storage set) internal view returns (uint256) {
        return _length(set._inner);
    }

    /**
     * @dev Returns the value stored at position `index` in the set. O(1).
     *
     * Note that there are no guarantees on the ordering of values inside the
     * array, and it may change when more values are added or removed.
     *
     * Requirements:
     *
     * - `index` must be strictly less than {length}.
     */
    function at(AddressSet storage set, uint256 index) internal view returns (address) {
        return address(uint160(uint256(_at(set._inner, index))));
    }

    /**
     * @dev Return the entire set in an array
     *
     * WARNING: This operation will copy the entire storage to memory, which can be quite expensive. This is designed
     * to mostly be used by view accessors that are queried without any gas fees. Developers should keep in mind that
     * this function has an unbounded cost, and using it as part of a state-changing function may render the function
     * uncallable if the set grows to a point where copying to memory consumes too much gas to fit in a block.
     */
    function values(AddressSet storage set) internal view returns (address[] memory) {
        bytes32[] memory store = _values(set._inner);
        address[] memory result;

        assembly {
            result := store
        }

        return result;
    }

    // UintSet

    struct UintSet {
        Set _inner;
    }

    /**
     * @dev Add a value to a set. O(1).
     *
     * Returns true if the value was added to the set, that is if it was not
     * already present.
     */
    function add(UintSet storage set, uint256 value) internal returns (bool) {
        return _add(set._inner, bytes32(value));
    }

    /**
     * @dev Removes a value from a set. O(1).
     *
     * Returns true if the value was removed from the set, that is if it was
     * present.
     */
    function remove(UintSet storage set, uint256 value) internal returns (bool) {
        return _remove(set._inner, bytes32(value));
    }

    /**
     * @dev Returns true if the value is in the set. O(1).
     */
    function contains(UintSet storage set, uint256 value) internal view returns (bool) {
        return _contains(set._inner, bytes32(value));
    }

    /**
     * @dev Returns the number of values on the set. O(1).
     */
    function length(UintSet storage set) internal view returns (uint256) {
        return _length(set._inner);
    }

    /**
     * @dev Returns the value stored at position `index` in the set. O(1).
     *
     * Note that there are no guarantees on the ordering of values inside the
     * array, and it may change when more values are added or removed.
     *
     * Requirements:
     *
     * - `index` must be strictly less than {length}.
     */
    function at(UintSet storage set, uint256 index) internal view returns (uint256) {
        return uint256(_at(set._inner, index));
    }

    /**
     * @dev Return the entire set in an array
     *
     * WARNING: This operation will copy the entire storage to memory, which can be quite expensive. This is designed
     * to mostly be used by view accessors that are queried without any gas fees. Developers should keep in mind that
     * this function has an unbounded cost, and using it as part of a state-changing function may render the function
     * uncallable if the set grows to a point where copying to memory consumes too much gas to fit in a block.
     */
    function values(UintSet storage set) internal view returns (uint256[] memory) {
        bytes32[] memory store = _values(set._inner);
        uint256[] memory result;

        assembly {
            result := store
        }

        return result;
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (access/IAccessControl.sol)

pragma solidity ^0.8.0;

/**
 * @dev External interface of AccessControl declared to support ERC165 detection.
 */
interface IAccessControlUpgradeable {
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
// OpenZeppelin Contracts (last updated v4.5.0) (token/ERC1155/IERC1155Receiver.sol)

pragma solidity ^0.8.0;

import "../../utils/introspection/IERC165Upgradeable.sol";

/**
 * @dev _Available since v3.1._
 */
interface IERC1155ReceiverUpgradeable is IERC165Upgradeable {
    /**
     * @dev Handles the receipt of a single ERC1155 token type. This function is
     * called at the end of a `safeTransferFrom` after the balance has been updated.
     *
     * NOTE: To accept the transfer, this must return
     * `bytes4(keccak256("onERC1155Received(address,address,uint256,uint256,bytes)"))`
     * (i.e. 0xf23a6e61, or its own function selector).
     *
     * @param operator The address which initiated the transfer (i.e. msg.sender)
     * @param from The address which previously owned the token
     * @param id The ID of the token being transferred
     * @param value The amount of tokens being transferred
     * @param data Additional data with no specified format
     * @return `bytes4(keccak256("onERC1155Received(address,address,uint256,uint256,bytes)"))` if transfer is allowed
     */
    function onERC1155Received(
        address operator,
        address from,
        uint256 id,
        uint256 value,
        bytes calldata data
    ) external returns (bytes4);

    /**
     * @dev Handles the receipt of a multiple ERC1155 token types. This function
     * is called at the end of a `safeBatchTransferFrom` after the balances have
     * been updated.
     *
     * NOTE: To accept the transfer(s), this must return
     * `bytes4(keccak256("onERC1155BatchReceived(address,address,uint256[],uint256[],bytes)"))`
     * (i.e. 0xbc197c81, or its own function selector).
     *
     * @param operator The address which initiated the batch transfer (i.e. msg.sender)
     * @param from The address which previously owned the token
     * @param ids An array containing ids of each token being transferred (order and length must match values array)
     * @param values An array containing amounts of each token being transferred (order and length must match ids array)
     * @param data Additional data with no specified format
     * @return `bytes4(keccak256("onERC1155BatchReceived(address,address,uint256[],uint256[],bytes)"))` if transfer is allowed
     */
    function onERC1155BatchReceived(
        address operator,
        address from,
        uint256[] calldata ids,
        uint256[] calldata values,
        bytes calldata data
    ) external returns (bytes4);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (token/ERC1155/extensions/IERC1155MetadataURI.sol)

pragma solidity ^0.8.0;

import "../IERC1155Upgradeable.sol";

/**
 * @dev Interface of the optional ERC1155MetadataExtension interface, as defined
 * in the https://eips.ethereum.org/EIPS/eip-1155#metadata-extensions[EIP].
 *
 * _Available since v3.1._
 */
interface IERC1155MetadataURIUpgradeable is IERC1155Upgradeable {
    /**
     * @dev Returns the URI for token type `id`.
     *
     * If the `\{id\}` substring is present in the URI, it must be replaced by
     * clients with the actual token type ID.
     */
    function uri(uint256 id) external view returns (string memory);
}

// SPDX-License-Identifier: Apache-2.0
pragma solidity ^0.8;

/// ========== External imports ==========
import "@openzeppelin/contracts-upgradeable/token/ERC721/extensions/ERC721EnumerableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/interfaces/IERC2981Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/utils/MulticallUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/utils/StringsUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/access/AccessControlEnumerableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/security/ReentrancyGuardUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/utils/CountersUpgradeable.sol";

/// ========== Internal imports ==========
import "./interfaces/IThirdwebContract.sol";

/// ========== Features ==========
import "./interfaces/IPlatformFee.sol";
import "./interfaces/IOwnable.sol";

import "./openzeppelin-presets/metatx/ERC2771ContextUpgradeable.sol";
import "../generated/impl/BaseCedarERC721DropV6.sol";

import "./lib/FeeType.sol";
import "./lib/MerkleProof.sol";

import "../SignatureVerifier.sol";
import "../Agreement.sol";

import "./errors/IErrors.sol";

import "./types/DropERC721DataTypes.sol";
import "./CedarERC721DropLogic.sol";

/// @title The CedarERC721Drop contract
/// @dev TODO: Add more details
contract CedarERC721Drop is
    Initializable,
    IThirdwebContract,
    IOwnable,
    ReentrancyGuardUpgradeable,
    ERC2771ContextUpgradeable,
    MulticallUpgradeable,
    AccessControlEnumerableUpgradeable,
    ERC721EnumerableUpgradeable,
    Agreement,
    IPlatformFee,
    BaseCedarERC721DropV6
{
    /// ================================
    /// =========== Libraries ==========
    /// ================================
    using StringsUpgradeable for uint256;
    using CedarERC721DropLogic for DropERC721DataTypes.ClaimData;
    using CountersUpgradeable for CountersUpgradeable.Counter;

    /// =============================
    /// =========== Events ==========
    /// =============================
    /// @dev Emitted when the global max supply of tokens is updated.
    event MaxTotalSupplyUpdated(uint256 maxTotalSupply);
    /// @dev Emitted when the wallet claim count for an address is updated.
    event WalletClaimCountUpdated(address indexed wallet, uint256 count);
    /// @dev Emitted when the global max wallet claim count is updated.
    event MaxWalletClaimCountUpdated(uint256 count);

    /// ===============================================
    /// =========== State variables - public ==========
    /// ===============================================
    /// @dev Contract level metadata.
    string public override(ICedarMetadataV1, IThirdwebContract) contractURI;
    /// @dev Only transfers to or from TRANSFER_ROLE holders are valid, when transfers are restricted.
    bytes32 public constant TRANSFER_ROLE = keccak256("TRANSFER_ROLE");
    /// @dev Only MINTER_ROLE holders can lazy mint NFTs.
    bytes32 public constant MINTER_ROLE = keccak256("MINTER_ROLE");
    /// @dev Only ISSUER_ROLE holders can issue NFTs.
    bytes32 public constant ISSUER_ROLE = keccak256("ISSUER_ROLE");
    /// @dev If true, users cannot claim.
    bool public claimIsPaused = false;
    /// ================================================
    /// =========== State variables - private ==========
    /// ================================================
    bytes32 private constant MODULE_TYPE = bytes32("DropERC721");
    uint256 private constant VERSION = 2;
    /// @dev Max bps in the thirdweb system.
    uint256 private constant MAX_BPS = 10_000;
    /// @dev Owner of the contract (purpose: OpenSea compatibility)
    address private _owner;
    /// @dev The (default) address that receives all royalty value.
    address private royaltyRecipient;
    /// @dev The (default) % of a sale to take as royalty (in basis points).
    uint16 private royaltyBps;
    /// @dev The address that receives all platform fees from all sales.
    address private platformFeeRecipient;
    /// @dev The % of primary sales collected as platform fees.
    uint16 private platformFeeBps;

    /// ===============================
    /// =========== Mappings ==========
    /// ===============================
    /// @dev Token ID => royalty recipient and bps for token
    mapping(uint256 => RoyaltyInfo) private royaltyInfoForToken;

    DropERC721DataTypes.ClaimData claimData;

    /// =============================
    /// ========== Structs ==========
    /// =============================
    struct FeaturesInput {
        string userAgreement;
        address signatureVerifier;
    }

    /// ====================================================
    /// ========== Constructor + initializer logic =========
    /// ====================================================
    constructor() {}

    /// @dev Initializes the contract, like a constructor.
    function initialize(
        address _defaultAdmin,
        string memory _name,
        string memory _symbol,
        string memory _contractURI,
        address[] memory _trustedForwarders,
        address _saleRecipient,
        address _royaltyRecipient,
        uint128 _royaltyBps,
        FeaturesInput memory featuresInput,
        uint128 _platformFeeBps,
        address _platformFeeRecipient
    ) external initializer {
        // Initialize inherited contracts, most base-like -> most derived.
        __ReentrancyGuard_init();
        __ERC2771Context_init(_trustedForwarders);
        __ERC721_init(_name, _symbol);

        __Agreement_init(featuresInput.userAgreement, featuresInput.signatureVerifier);

        // Initialize this contract's state.
        royaltyRecipient = _royaltyRecipient;
        royaltyBps = uint16(_royaltyBps);
        contractURI = _contractURI;
        _owner = _defaultAdmin;
        claimData.primarySaleRecipient = _saleRecipient;
        claimData.platformFeeRecipient = _platformFeeRecipient;
        claimData.platformFeeBps = uint16(_platformFeeBps);

        _setupRole(DEFAULT_ADMIN_ROLE, _defaultAdmin);
        _setupRole(MINTER_ROLE, _defaultAdmin);
        _setupRole(TRANSFER_ROLE, _defaultAdmin);
        _setupRole(TRANSFER_ROLE, address(0));
        _setupRole(ISSUER_ROLE, _defaultAdmin);
    }

    /// ============================================
    /// ========== Generic contract logic ==========
    /// ============================================
    /// @dev Returns the type of the contract.
    function contractType() external pure override returns (bytes32) {
        return MODULE_TYPE;
    }

    /// @dev Returns the version of the contract.
    function contractVersion() external pure override returns (uint8) {
        return uint8(VERSION);
    }

    /// @dev Returns the address of the current owner.
    function owner() public view override returns (address) {
        return hasRole(DEFAULT_ADMIN_ROLE, _owner) ? _owner : address(0);
    }

    /// @dev See ERC 721 - Returns the URI for a given tokenId.
    function tokenURI(uint256 _tokenId)
        public
        view
        override(ERC721Upgradeable, ICedarNFTMetadataV1)
        returns (string memory)
    {
        return CedarERC721DropLogic.tokenURI(claimData, _tokenId);
    }

    /**
     * @dev Sets `_tokenURI` as the tokenURI of `tokenId`.
     *
     * Requirements:
     *
     * - `tokenId` must exist.
     */
    function setTokenURI(uint256 _tokenId, string memory _tokenURI)
        external
        virtual
        override
        onlyRole(DEFAULT_ADMIN_ROLE)
    {
        _setTokenURI(_tokenId, _tokenURI);
    }

    function _setTokenURI(uint256 _tokenId, string memory _tokenURI) internal {
        require(_exists(_tokenId), "URI set of nonexistent token");
        CedarERC721DropLogic.setTokenURI(claimData, _tokenId, _tokenURI);
        emit TokenURIUpdated(_tokenId, _msgSender(), _tokenURI);
    }

    /// @dev See ERC-2891 - Returns the royalty recipient and amount, given a tokenId and sale price.
    function royaltyInfo(uint256 tokenId, uint256 salePrice)
        external
        view
        virtual
        override
        returns (address receiver, uint256 royaltyAmount)
    {
        (address recipient, uint256 bps) = getRoyaltyInfoForToken(tokenId);
        receiver = recipient;
        royaltyAmount = (salePrice * bps) / MAX_BPS;
    }

    /// @dev See ERC 165
    function supportsInterface(bytes4 interfaceId)
        public
        view
        override(BaseCedarERC721DropV6, ERC721EnumerableUpgradeable, AccessControlEnumerableUpgradeable)
        returns (bool)
    {
        return
            BaseCedarERC721DropV6.supportsInterface(interfaceId) ||
            ERC721EnumerableUpgradeable.supportsInterface(interfaceId) ||
            AccessControlEnumerableUpgradeable.supportsInterface(interfaceId);
    }

    /// @dev allows admin to pause users from claiming.
    function pauseClaims() external onlyRole(DEFAULT_ADMIN_ROLE) {
        claimIsPaused = true;
        emit ClaimPauseStatusUpdated(claimIsPaused);
    }

    /// @dev allows admin to un-pause users from claiming.
    function unpauseClaims() external onlyRole(DEFAULT_ADMIN_ROLE) {
        claimIsPaused = false;
        emit ClaimPauseStatusUpdated(claimIsPaused);
    }

    /// ======================================
    /// =========== Minting logic ============
    /// ======================================
    /// @dev Lets an account with `MINTER_ROLE` lazy mint 'n' NFTs.
    ///        The URIs for each token is the provided `_baseURIForTokens` + `{tokenId}`.
    function lazyMint(uint256 _amount, string calldata _baseURIForTokens) external override onlyRole(MINTER_ROLE) {
        (uint256 startId, uint256 baseURIIndex) = CedarERC721DropLogic.lazyMint(claimData, _amount, _baseURIForTokens);
        emit TokensLazyMinted(startId, baseURIIndex - 1, _baseURIForTokens);
    }

    function issue(address _receiver, uint256 _quantity) external override onlyRole(ISSUER_ROLE) {
        uint256[] memory tokens = CedarERC721DropLogic.verifyIssue(claimData, _quantity);

        for (uint256 i = 0; i < tokens.length; i += 1) {
            _mint(_receiver, tokens[i]);
        }

        emit TokensIssued(tokens[0], _msgSender(), _receiver, _quantity);
    }

    function issueWithTokenURI(address _receiver, string calldata _tokenURI) external override onlyRole(ISSUER_ROLE) {
        uint256[] memory tokens = CedarERC721DropLogic.verifyIssue(claimData, 1);
        // First mint the token
        _mint(_receiver, tokens[0]);
        // Then set the tokenURI
        _setTokenURI(tokens[0], _tokenURI);

        emit TokenIssued(tokens[0], _msgSender(), _receiver, _tokenURI);
    }

    /// ======================================
    /// ============= Claim logic ============
    /// ======================================
    /// @dev Lets an account claim NFTs.
    function claim(
        address _receiver,
        uint256 _quantity,
        address _currency,
        uint256 _pricePerToken,
        bytes32[] calldata _proofs,
        uint256 _proofMaxQuantityPerTransaction
    ) external payable override nonReentrant {
        address msgSender = _msgSender();
        if (!(isTrustedForwarder(msg.sender) || msgSender == tx.origin)) revert Bot();
        if (claimIsPaused) revert ClaimPaused();

        (uint256[] memory tokens, CedarERC721DropLogic.InternalClaim memory internalClaim) = CedarERC721DropLogic
            .executeClaim(
                claimData,
                _quantity,
                _currency,
                _pricePerToken,
                _proofs,
                _proofMaxQuantityPerTransaction,
                _msgSender()
            );

        for (uint256 i = 0; i < tokens.length; i += 1) {
            _mint(_receiver, tokens[i]);
        }

        emit TokensClaimed(
            internalClaim.activeConditionId,
            msgSender,
            _receiver,
            internalClaim.tokenIdToClaim,
            _quantity
        );
    }

    /// @dev Lets a contract admin (account with `DEFAULT_ADMIN_ROLE`) set claim conditions.
    function setClaimConditions(ClaimCondition[] calldata _phases, bool _resetClaimEligibility)
        external
        override
        onlyRole(DEFAULT_ADMIN_ROLE)
    {
        CedarERC721DropLogic.setClaimConditions(claimData, _phases, _resetClaimEligibility);
        emit ClaimConditionsUpdated(_phases);
    }

    /// @dev Checks a request to claim NFTs against the active claim condition's criteria.
    function verifyClaim(
        uint256 _conditionId,
        address _claimer,
        uint256 _quantity,
        address _currency,
        uint256 _pricePerToken,
        bool verifyMaxQuantityPerTransaction
    ) public view override {
        CedarERC721DropLogic.verifyClaim(
            claimData,
            _conditionId,
            _claimer,
            _quantity,
            _currency,
            _pricePerToken,
            verifyMaxQuantityPerTransaction
        );
    }

    /// ======================================
    /// ========== Setter functions ==========
    /// ======================================
    /// @dev Lets a contract admin set a new owner for the contract. The new owner must be a contract admin.
    function setOwner(address _newOwner) external override onlyRole(DEFAULT_ADMIN_ROLE) {
        if (!hasRole(DEFAULT_ADMIN_ROLE, _newOwner)) revert InvalidPermission();
        address _prevOwner = _owner;
        _owner = _newOwner;

        emit OwnerUpdated(_prevOwner, _newOwner);
    }

    /// @dev Lets a contract admin set the recipient for all primary sales.
    function setPrimarySaleRecipient(address _saleRecipient) external override onlyRole(DEFAULT_ADMIN_ROLE) {
        claimData.primarySaleRecipient = _saleRecipient;
        emit PrimarySaleRecipientUpdated(_saleRecipient);
    }

    /// @dev Lets a contract admin update the platform fee recipient and bps
    function setPlatformFeeInfo(address _platformFeeRecipient, uint256 _platformFeeBps)
        external
        override
        onlyRole(DEFAULT_ADMIN_ROLE)
    {
        require(_platformFeeBps <= MAX_BPS, "> MAX_BPS.");

        claimData.platformFeeBps = uint16(_platformFeeBps);
        claimData.platformFeeRecipient = _platformFeeRecipient;

        emit PlatformFeeInfoUpdated(_platformFeeRecipient, _platformFeeBps);
    }

    /// @dev Lets a contract admin update the default royalty recipient and bps.
    function setDefaultRoyaltyInfo(address _royaltyRecipient, uint256 _royaltyBps)
        external
        override
        onlyRole(DEFAULT_ADMIN_ROLE)
    {
        if (!(_royaltyBps <= MAX_BPS)) revert MaxBps();

        royaltyRecipient = _royaltyRecipient;
        royaltyBps = uint16(_royaltyBps);

        emit DefaultRoyalty(_royaltyRecipient, _royaltyBps);
    }

    /// @dev Lets a contract admin set the royalty recipient and bps for a particular token Id.
    function setRoyaltyInfoForToken(
        uint256 _tokenId,
        address _recipient,
        uint256 _bps
    ) external override onlyRole(DEFAULT_ADMIN_ROLE) {
        if (!(_bps <= MAX_BPS)) revert MaxBps();

        royaltyInfoForToken[_tokenId] = RoyaltyInfo({recipient: _recipient, bps: _bps});

        emit RoyaltyForToken(_tokenId, _recipient, _bps);
    }

    /// @dev Lets a contract admin set a maximum number of NFTs that can be claimed by any wallet.
    function setMaxWalletClaimCount(uint256 _count) external onlyRole(DEFAULT_ADMIN_ROLE) {
        claimData.maxWalletClaimCount = _count;
        emit MaxWalletClaimCountUpdated(_count);
    }

    /// @dev Lets a contract admin set the global maximum supply for collection's NFTs.
    function setMaxTotalSupply(uint256 _maxTotalSupply) external onlyRole(DEFAULT_ADMIN_ROLE) {
        if (_maxTotalSupply != 0 && claimData.nextTokenIdToMint > _maxTotalSupply) {
            revert CrossedLimitMinTokenIdGreaterThanMaxTotalSupply();
        }
        claimData.maxTotalSupply = _maxTotalSupply;
        emit MaxTotalSupplyUpdated(_maxTotalSupply);
    }

    /// @dev Lets a contract admin set a claim count for a wallet.
    function setWalletClaimCount(address _claimer, uint256 _count) external onlyRole(DEFAULT_ADMIN_ROLE) {
        claimData.walletClaimCount[_claimer] = _count;
        emit WalletClaimCountUpdated(_claimer, _count);
    }

    /// @dev Lets a contract admin set the URI for contract-level metadata.
    function setContractURI(string calldata _uri)
        external
        override(ICedarMetadataV1, IThirdwebContract)
        onlyRole(DEFAULT_ADMIN_ROLE)
    {
        contractURI = _uri;
        emit ContractURIUpdated(_msgSender(), _uri);
    }

    /// @dev Lets an account with `MINTER_ROLE` update base URI.
    function updateBaseURI(uint256 baseURIIndex, string calldata _baseURIForTokens)
        external
        override
        onlyRole(MINTER_ROLE)
    {
        claimData.uriSequenceCounter.increment();
        claimData.baseURI[baseURIIndex].uri = _baseURIForTokens;
        claimData.baseURI[baseURIIndex].sequenceNumber = claimData.uriSequenceCounter.current();
        emit BaseURIUpdated(baseURIIndex, _baseURIForTokens);
    }

    /// ======================================
    /// ============ Agreement ===============
    /// ======================================
    /// @notice activates the terms
    /// @dev this function activates the user terms
    function setTermsStatus(bool _status) external virtual override onlyRole(DEFAULT_ADMIN_ROLE) {
        _setTermsStatus(_status);
    }

    /// @notice stores terms accepted from a signed message
    /// @dev this function is for acceptors that have signed a message offchain to accept the terms. The function calls the verifier contract to valid the signature before storing acceptance.
    function storeTermsAccepted(address _acceptor, bytes calldata _signature)
        external
        virtual
        override
        onlyRole(DEFAULT_ADMIN_ROLE)
    {
        _storeTermsAccepted(_acceptor, _signature);
    }

    /// ======================================
    /// ========== Getter functions ==========
    /// ======================================
    /// @dev Returns the sale recipient address.
    function primarySaleRecipient() external view override returns (address) {
        return claimData.primarySaleRecipient;
    }

    /// @dev Returns the platform fee recipient and bps.
    function getPlatformFeeInfo() external view override returns (address, uint16) {
        return (claimData.platformFeeRecipient, uint16(claimData.platformFeeBps));
    }

    /// @dev Returns the default royalty recipient and bps.
    function getDefaultRoyaltyInfo() external view override returns (address, uint16) {
        return (royaltyRecipient, uint16(royaltyBps));
    }

    /// @dev Returns the royalty recipient and bps for a particular token Id.
    function getRoyaltyInfoForToken(uint256 _tokenId) public view override returns (address, uint16) {
        RoyaltyInfo memory royaltyForToken = royaltyInfoForToken[_tokenId];

        return
            royaltyForToken.recipient == address(0)
                ? (royaltyRecipient, uint16(royaltyBps))
                : (royaltyForToken.recipient, uint16(royaltyForToken.bps));
    }

    /// @dev Returns the amount of stored baseURIs
    function getBaseURICount() external view returns (uint256) {
        return claimData.baseURIIndices.length;
    }

    /// @dev Gets the base URI indices
    function getBaseURIIndices() external view override returns (uint256[] memory) {
        return claimData.baseURIIndices;
    }

    /// @dev Expose the current active claim condition including claim limits
    function getActiveClaimConditions()
        external
        view
        override
        returns (
            ClaimCondition memory condition,
            uint256 conditionId,
            uint256 walletMaxClaimCount,
            uint256 remainingSupply,
            bool isClaimPaused
        )
    {
        (condition, conditionId, walletMaxClaimCount, remainingSupply) = claimData.getActiveClaimConditions();
        isClaimPaused = claimIsPaused;
    }

    /// @dev Expose the user specific limits related to the current active claim condition
    function getUserClaimConditions(address _claimer)
        external
        view
        override
        returns (
            uint256 conditionId,
            uint256 walletClaimedCount,
            uint256 walletClaimedCountInPhase,
            uint256 lastClaimTimestamp,
            uint256 nextValidClaimTimestamp
        )
    {
        return CedarERC721DropLogic.getUserClaimConditions(claimData, _claimer);
    }

    /// ======================================
    /// =========== Miscellaneous ============
    /// ======================================
    /// @dev Concrete implementation semantic version -
    ///         provided for completeness but not designed to be the point of dispatch
    function minorVersion() public pure override returns (uint256 minor, uint256 patch) {
        minor = 0;
        patch = 0;
    }

    /// @dev Burns `tokenId`. See {ERC721-_burn}.
    function burn(uint256 tokenId) public virtual {
        //solhint-disable-next-line max-line-length
        if (!(_isApprovedOrOwner(_msgSender(), tokenId))) revert InvalidPermission();
        _burn(tokenId);
        // Not strictly necessary since we shouldn't issue this token again
        claimData.tokenURIs[tokenId].sequenceNumber = 0;
    }

    /// @dev See {ERC721-_beforeTokenTransfer}.
    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 tokenId
    ) internal virtual override(ERC721EnumerableUpgradeable) {
        super._beforeTokenTransfer(from, to, tokenId);

        // if transfer is restricted on the contract, we still want to allow burning and minting
        if (!hasRole(TRANSFER_ROLE, address(0)) && from != address(0) && to != address(0)) {
            if (!(hasRole(TRANSFER_ROLE, from) || hasRole(TRANSFER_ROLE, to))) revert InvalidPermission();
        }

        if (to != address(this)) {
            if (termsActivated) {
                require(
                    termsAccepted[to],
                    string(
                        abi.encodePacked(
                            "Receiver address has not accepted the collection's terms of use at ",
                            userAgreement
                        )
                    )
                );
            }
        }
    }

    /// @dev Provides a function to batch together multiple calls in a single external call.
    function multicall(bytes[] calldata data)
        external
        override(IMulticallableV0, MulticallUpgradeable)
        returns (bytes[] memory results)
    {
        return MulticallUpgradeable(this).multicall(data);
    }

    function _msgSender()
        internal
        view
        virtual
        override(ContextUpgradeable, ERC2771ContextUpgradeable)
        returns (address sender)
    {
        return ERC2771ContextUpgradeable._msgSender();
    }

    function _msgData()
        internal
        view
        virtual
        override(ContextUpgradeable, ERC2771ContextUpgradeable)
        returns (bytes calldata)
    {
        return ERC2771ContextUpgradeable._msgData();
    }
}

// SPDX-License-Identifier: Apache-2.0
pragma solidity ^0.8;

import "@openzeppelin/contracts-upgradeable/utils/StringsUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/utils/CountersUpgradeable.sol";

import "./lib/CurrencyTransferLib.sol";
import "./lib/MerkleProof.sol";
import "./types/DropERC721DataTypes.sol";
import "./errors/IErrors.sol";
import "./../api/standard/IERC1155.sol";

library CedarERC721DropLogic {
    using StringsUpgradeable for uint256;

    uint256 private constant MAX_UINT256 = 2**256 - 1;

    using CedarERC721DropLogic for DropERC721DataTypes.ClaimData;
    using CountersUpgradeable for CountersUpgradeable.Counter;

    struct InternalClaim {
        bool validMerkleProof;
        uint256 merkleProofIndex;
        bool toVerifyMaxQuantityPerTransaction;
        uint256 activeConditionId;
        uint256 tokenIdToClaim;
    }

    function setClaimConditions(
        DropERC721DataTypes.ClaimData storage claimData,
        IDropClaimConditionV0.ClaimCondition[] calldata _phases,
        bool _resetClaimEligibility
    ) public {
        uint256 existingStartIndex = claimData.claimCondition.currentStartId;
        uint256 existingPhaseCount = claimData.claimCondition.count;

        uint256 newStartIndex = existingStartIndex;
        if (_resetClaimEligibility) {
            newStartIndex = existingStartIndex + existingPhaseCount;
        }

        claimData.claimCondition.count = _phases.length;
        claimData.claimCondition.currentStartId = newStartIndex;

        uint256 lastConditionStartTimestamp;
        for (uint256 i = 0; i < _phases.length; i++) {
            if (!(i == 0 || lastConditionStartTimestamp < _phases[i].startTimestamp)) revert ST();

            uint256 supplyClaimedAlready = claimData.claimCondition.phases[newStartIndex + i].supplyClaimed;

            if (!(supplyClaimedAlready <= _phases[i].maxClaimableSupply)) revert CrossedLimitMaxClaimableSupply();

            claimData.claimCondition.phases[newStartIndex + i] = _phases[i];
            claimData.claimCondition.phases[newStartIndex + i].supplyClaimed = supplyClaimedAlready;

            lastConditionStartTimestamp = _phases[i].startTimestamp;
        }

        /**
         *  Gas refunds (as much as possible)
         *
         *  If `_resetClaimEligibility == true`, we assign completely new UIDs to the claim
         *  conditions in `_phases`. So, we delete claim conditions with UID < `newStartIndex`.
         *
         *  If `_resetClaimEligibility == false`, and there are more existing claim conditions
         *  than in `_phases`, we delete the existing claim conditions that don't get replaced
         *  by the conditions in `_phases`.
         */
        if (_resetClaimEligibility) {
            for (uint256 i = existingStartIndex; i < newStartIndex; i++) {
                delete claimData.claimCondition.phases[i];
            }
        } else {
            if (existingPhaseCount > _phases.length) {
                for (uint256 i = _phases.length; i < existingPhaseCount; i++) {
                    delete claimData.claimCondition.phases[newStartIndex + i];
                }
            }
        }
    }

    function executeClaim(
        DropERC721DataTypes.ClaimData storage claimData,
        uint256 _quantity,
        address _currency,
        uint256 _pricePerToken,
        bytes32[] calldata _proofs,
        uint256 _proofMaxQuantityPerTransaction,
        address msgSender
    ) public returns (uint256[] memory tokens, InternalClaim memory internalData) {
        internalData.tokenIdToClaim = claimData.nextTokenIdToClaim;

        // Get the claim conditions.
        internalData.activeConditionId = getActiveClaimConditionId(claimData);

        /**
         *  We make allowlist checks (i.e. verifyClaimMerkleProof) before verifying the claim's general
         *  validity (i.e. verifyClaim) because we give precedence to the check of allow list quantity
         *  restriction over the check of the general claim condition's quantityLimitPerTransaction
         *  restriction.
         */

        // Verify inclusion in allowlist.
        (internalData.validMerkleProof, internalData.merkleProofIndex) = verifyClaimMerkleProof(
            claimData,
            internalData.activeConditionId,
            msgSender,
            _quantity,
            _proofs,
            _proofMaxQuantityPerTransaction
        );

        // Verify claim validity. If not valid, revert.
        // when there's allowlist present --> verifyClaimMerkleProof will verify the _proofMaxQuantityPerTransaction value with hashed leaf in the allowlist
        // when there's no allowlist, this check is true --> verifyClaim will check for _quantity being less/equal than the limit
        internalData.toVerifyMaxQuantityPerTransaction =
            _proofMaxQuantityPerTransaction == 0 ||
            claimData.claimCondition.phases[internalData.activeConditionId].merkleRoot == bytes32(0);

        verifyClaim(
            claimData,
            internalData.activeConditionId,
            msgSender,
            _quantity,
            _currency,
            _pricePerToken,
            internalData.toVerifyMaxQuantityPerTransaction
        );

        // If there's a price, collect price.
        claimData.collectClaimPrice(_quantity, _currency, _pricePerToken, msgSender);

        // Book-keeping before the calling contract does the actual transfer and mint the relevant NFTs to claimer.
        tokens = recordTransferClaimedTokens(claimData, internalData.activeConditionId, _quantity, msgSender);
    }

    function verifyClaimMerkleProof(
        DropERC721DataTypes.ClaimData storage claimData,
        uint256 _conditionId,
        address _claimer,
        uint256 _quantity,
        bytes32[] calldata _proofs,
        uint256 _proofMaxQuantityPerTransaction
    ) public view returns (bool validMerkleProof, uint256 merkleProofIndex) {
        IDropClaimConditionV0.ClaimCondition memory currentClaimPhase = claimData.claimCondition.phases[_conditionId];

        if (currentClaimPhase.merkleRoot != bytes32(0)) {
            (validMerkleProof, merkleProofIndex) = MerkleProof.verify(
                _proofs,
                currentClaimPhase.merkleRoot,
                keccak256(abi.encodePacked(_claimer, _proofMaxQuantityPerTransaction))
            );

            if (!validMerkleProof) revert InvalidMerkleProof();
            if (
                !(_proofMaxQuantityPerTransaction == 0 ||
                    _quantity <=
                    _proofMaxQuantityPerTransaction -
                        claimData.claimCondition.userClaims[_conditionId][_claimer].claimedBalance)
            ) revert InvalidMaxQuantityProof();
        }
    }

    /// @dev Checks a request to claim NFTs against the active claim condition's criteria.
    function verifyClaim(
        DropERC721DataTypes.ClaimData storage claimData,
        uint256 _conditionId,
        address _claimer,
        uint256 _quantity,
        address _currency,
        uint256 _pricePerToken,
        bool verifyMaxQuantityPerTransaction
    ) public view {
        IDropClaimConditionV0.ClaimCondition memory currentClaimPhase = claimData.claimCondition.phases[_conditionId];

        if (!(_currency == currentClaimPhase.currency && _pricePerToken == currentClaimPhase.pricePerToken)) {
            revert InvalidPrice();
        }
        // If we're checking for an allowlist quantity restriction, ignore the general quantity restriction.
        if (
            !(_quantity > 0 &&
                (!verifyMaxQuantityPerTransaction || _quantity <= currentClaimPhase.quantityLimitPerTransaction))
        ) {
            revert InvalidQuantity();
        }
        if (!(currentClaimPhase.supplyClaimed + _quantity <= currentClaimPhase.maxClaimableSupply)) {
            revert CrossedLimitMaxClaimableSupply();
        }
        // nextTokenIdToMint is the supremum of all tokens currently lazy minted so this is just checking we are no
        // trying to claim a token that has not yet been lazyminted (therefore has no URI)
        if (!(claimData.nextTokenIdToClaim + _quantity <= claimData.nextTokenIdToMint)) {
            revert CrossedLimitLazyMintedTokens();
        }
        if (!(claimData.maxTotalSupply == 0 || claimData.nextTokenIdToClaim + _quantity <= claimData.maxTotalSupply)) {
            revert CrossedLimitMaxTotalSupply();
        }
        if (
            !(claimData.maxWalletClaimCount == 0 ||
                claimData.walletClaimCount[_claimer] + _quantity <= claimData.maxWalletClaimCount)
        ) {
            revert CrossedLimitMaxWalletClaimCount();
        }
        (uint256 lastClaimTimestamp, uint256 nextValidClaimTimestamp) = getClaimTimestamp(
            claimData,
            _conditionId,
            _claimer
        );
        if (!(lastClaimTimestamp == 0 || block.timestamp >= nextValidClaimTimestamp)) revert InvalidTime();
    }

    /// @dev Collects and distributes the primary sale value of NFTs being claimed.
    function collectClaimPrice(
        DropERC721DataTypes.ClaimData storage claimData,
        uint256 _quantityToClaim,
        address _currency,
        uint256 _pricePerToken,
        address msgSender
    ) internal {
        if (_pricePerToken == 0) {
            return;
        }

        uint256 MAX_BPS = 10_000;

        uint256 totalPrice = _quantityToClaim * _pricePerToken;
        uint256 platformFees = (totalPrice * claimData.platformFeeBps) / MAX_BPS;

        if (_currency == CurrencyTransferLib.NATIVE_TOKEN && !(msg.value == totalPrice)) revert InvalidPrice();

        CurrencyTransferLib.transferCurrency(_currency, msgSender, claimData.platformFeeRecipient, platformFees);
        CurrencyTransferLib.transferCurrency(
            _currency,
            msgSender,
            claimData.primarySaleRecipient,
            totalPrice - platformFees
        );
    }

    /// @dev Book-keeping before the calling contract does the actual transfer and mint the relevant NFTs to claimer.
    function recordTransferClaimedTokens(
        DropERC721DataTypes.ClaimData storage claimData,
        uint256 _conditionId,
        uint256 _quantityBeingClaimed,
        address msgSender
    ) public returns (uint256[] memory tokens) {
        // Update the supply minted under mint condition.
        claimData.claimCondition.phases[_conditionId].supplyClaimed += _quantityBeingClaimed;

        // if transfer claimed tokens is called when `to != msg.sender`, it'd use msg.sender's limits.
        // behavior would be similar to `msg.sender` mint for itself, then transfer to `_to`.
        claimData.claimCondition.userClaims[_conditionId][msgSender].lastClaimTimestamp = block.timestamp;
        claimData.claimCondition.userClaims[_conditionId][msgSender].claimedBalance += _quantityBeingClaimed;
        claimData.walletClaimCount[msgSender] += _quantityBeingClaimed;

        tokens = transferTokens(claimData, _quantityBeingClaimed);
    }

    function verifyIssue(DropERC721DataTypes.ClaimData storage claimData, uint256 _quantity)
        public
        returns (uint256[] memory tokens)
    {
        if (_quantity == 0) {
            revert InvalidQuantity();
        }
        uint256 nextNextTokenIdToMint = claimData.nextTokenIdToClaim + _quantity;
        if (nextNextTokenIdToMint > claimData.nextTokenIdToMint) {
            revert CrossedLimitLazyMintedTokens();
        }
        if (claimData.maxTotalSupply != 0 && nextNextTokenIdToMint > claimData.maxTotalSupply) {
            revert CrossedLimitMaxTotalSupply();
        }
        tokens = transferTokens(claimData, _quantity);
    }

    function setTokenURI(
        DropERC721DataTypes.ClaimData storage claimData,
        uint256 _tokenId,
        string memory _tokenURI
    ) public {
        // Interpret empty string as unsetting tokenURI
        if (bytes(_tokenURI).length == 0) {
            claimData.tokenURIs[_tokenId].sequenceNumber = 0;
            return;
        }
        // Bump the sequence first
        claimData.uriSequenceCounter.increment();
        claimData.tokenURIs[_tokenId].uri = _tokenURI;
        claimData.tokenURIs[_tokenId].sequenceNumber = claimData.uriSequenceCounter.current();
    }

    function tokenURI(DropERC721DataTypes.ClaimData storage claimData, uint256 _tokenId)
        public
        view
        returns (string memory)
    {
        // Try to fetch possibly overridden tokenURI
        DropERC721DataTypes.SequencedURI storage _tokenURI = claimData.tokenURIs[_tokenId];

        for (uint256 i = 0; i < claimData.baseURIIndices.length; i += 1) {
            if (_tokenId < claimData.baseURIIndices[i]) {
                DropERC721DataTypes.SequencedURI storage _baseURI = claimData.baseURI[claimData.baseURIIndices[i]];
                if (_tokenURI.sequenceNumber > _baseURI.sequenceNumber) {
                    // If the specifically set tokenURI is fresher than the baseURI then return that (it is in-force)
                    return _tokenURI.uri;
                }
                // Otherwise either there is no override (sequenceNumber == 0) or the baseURI is fresher, so return the
                // baseURI-derived tokenURI
                return string(abi.encodePacked(_baseURI.uri, _tokenId.toString()));
            }
        }
        return "";
    }

    function lazyMint(
        DropERC721DataTypes.ClaimData storage claimData,
        uint256 _amount,
        string calldata _baseURIForTokens
    ) public returns (uint256 startId, uint256 baseURIIndex) {
        claimData.uriSequenceCounter.increment();
        startId = claimData.nextTokenIdToMint;
        baseURIIndex = startId + _amount;

        claimData.nextTokenIdToMint = baseURIIndex;
        claimData.baseURI[baseURIIndex].uri = _baseURIForTokens;
        claimData.baseURI[baseURIIndex].sequenceNumber = claimData.uriSequenceCounter.current();
        claimData.baseURIIndices.push(baseURIIndex);
    }

    function transferTokens(DropERC721DataTypes.ClaimData storage claimData, uint256 _quantityBeingClaimed)
        public
        returns (uint256[] memory tokens)
    {
        uint256 tokenIdToClaim = claimData.nextTokenIdToClaim;

        tokens = new uint256[](_quantityBeingClaimed);

        for (uint256 i = 0; i < _quantityBeingClaimed; i += 1) {
            tokens[i] = tokenIdToClaim;
            tokenIdToClaim += 1;
        }

        claimData.nextTokenIdToClaim = tokenIdToClaim;
    }

    function getActiveClaimConditions(DropERC721DataTypes.ClaimData storage claimData)
        public
        view
        returns (
            IDropClaimConditionV0.ClaimCondition memory condition,
            uint256 conditionId,
            uint256 walletMaxClaimCount,
            uint256 remainingSupply
        )
    {
        conditionId = getActiveClaimConditionId(claimData);
        condition = claimData.claimCondition.phases[conditionId];
        walletMaxClaimCount = claimData.maxWalletClaimCount;

        if (claimData.maxTotalSupply > 0) {
            remainingSupply = claimData.maxTotalSupply - claimData.nextTokenIdToClaim;
        } else {
            remainingSupply = MAX_UINT256;
        }
    }

    /// @dev Returns the user specific limits related to the current active claim condition
    function getUserClaimConditions(DropERC721DataTypes.ClaimData storage claimData, address _claimer)
        public
        view
        returns (
            uint256 conditionId,
            uint256 walletClaimedCount,
            uint256 walletClaimedCountInPhase,
            uint256 lastClaimTimestamp,
            uint256 nextValidClaimTimestamp
        )
    {
        conditionId = getActiveClaimConditionId(claimData);
        (lastClaimTimestamp, nextValidClaimTimestamp) = getClaimTimestamp(claimData, conditionId, _claimer);
        walletClaimedCount = claimData.walletClaimCount[_claimer];
        walletClaimedCountInPhase = claimData.claimCondition.userClaims[conditionId][_claimer].claimedBalance;
    }

    /// @dev Returns the current active claim condition ID.
    function getActiveClaimConditionId(DropERC721DataTypes.ClaimData storage claimData) public view returns (uint256) {
        for (
            uint256 i = claimData.claimCondition.currentStartId + claimData.claimCondition.count;
            i > claimData.claimCondition.currentStartId;
            i--
        ) {
            if (block.timestamp >= claimData.claimCondition.phases[i - 1].startTimestamp) {
                return i - 1;
            }
        }

        revert NoActiveMintCondition();
    }

    /// @dev Returns the timestamp for when a claimer is eligible for claiming NFTs again.
    function getClaimTimestamp(
        DropERC721DataTypes.ClaimData storage claimData,
        uint256 _conditionId,
        address _claimer
    ) public view returns (uint256 lastClaimTimestamp, uint256 nextValidClaimTimestamp) {
        lastClaimTimestamp = claimData.claimCondition.userClaims[_conditionId][_claimer].lastClaimTimestamp;

        unchecked {
            nextValidClaimTimestamp =
                lastClaimTimestamp +
                claimData.claimCondition.phases[_conditionId].waitTimeInSecondsBetweenClaims;

            if (nextValidClaimTimestamp < lastClaimTimestamp) {
                nextValidClaimTimestamp = type(uint256).max;
            }
        }
    }
}

// SPDX-License-Identifier: Apache-2.0

// Generated by impl.ts. Will be overwritten.
// Filename: './BaseCedarERC721DropV6.sol'

pragma solidity ^0.8.4;

import "../../api/impl/ICedarERC721Drop.sol";

/// Inherit from this base to implement introspection
abstract contract BaseCedarERC721DropV6 is ICedarERC721DropV6 {
    function supportedFeatures() override public pure returns (string[] memory features) {
        features = new string[](13);
        features[0] = "ICedarFeatures.sol:ICedarFeaturesV0";
        features[1] = "ICedarVersioned.sol:ICedarVersionedV1";
        features[2] = "IMulticallable.sol:IMulticallableV0";
        features[3] = "agreement/ICedarAgreement.sol:ICedarAgreementV0";
        features[4] = "issuance/ICedarNFTIssuance.sol:ICedarNFTIssuanceV3";
        features[5] = "lazymint/ICedarLazyMint.sol:ICedarLazyMintV0";
        features[6] = "standard/IERC721.sol:IERC721V0";
        features[7] = "royalties/IRoyalty.sol:IRoyaltyV0";
        features[8] = "baseURI/ICedarUpdateBaseURI.sol:ICedarUpdateBaseURIV0";
        features[9] = "metadata/ICedarNFTMetadata.sol:ICedarNFTMetadataV1";
        features[10] = "metadata/IContractMetadata.sol:ICedarMetadataV1";
        features[11] = "primarysale/IPrimarySale.sol:IPrimarySaleV0";
        features[12] = "pausable/ICedarPausable.sol:ICedarPausableV0";
    }

    /// This needs to be public to be callable from initialize via delegatecall
    function minorVersion() virtual override public pure returns (uint256 minor, uint256 patch);

    function implementationVersion() override public pure returns (uint256 major, uint256 minor, uint256 patch) {
        (minor, patch) = minorVersion();
        major = 6;
    }

    function implementationInterfaceName() virtual override public pure returns (string memory interfaceName) {
        interfaceName = "ICedarERC721DropV6";
    }

    function supportsInterface(bytes4 interfaceID) virtual override public view returns (bool) {
        return (interfaceID == type(IERC165Upgradeable).interfaceId) || ((interfaceID == type(ICedarFeaturesV0).interfaceId) || ((interfaceID == type(ICedarVersionedV1).interfaceId) || ((interfaceID == type(IMulticallableV0).interfaceId) || ((interfaceID == type(ICedarAgreementV0).interfaceId) || ((interfaceID == type(ICedarNFTIssuanceV3).interfaceId) || ((interfaceID == type(ICedarLazyMintV0).interfaceId) || ((interfaceID == type(IERC721V0).interfaceId) || ((interfaceID == type(IRoyaltyV0).interfaceId) || ((interfaceID == type(ICedarUpdateBaseURIV0).interfaceId) || ((interfaceID == type(ICedarNFTMetadataV1).interfaceId) || ((interfaceID == type(ICedarMetadataV1).interfaceId) || ((interfaceID == type(IPrimarySaleV0).interfaceId) || (interfaceID == type(ICedarPausableV0).interfaceId)))))))))))));
    }

    function isICedarFeaturesV0() override public pure returns (bool) {
        return true;
    }
}

// SPDX-License-Identifier: Apache-2.0
pragma solidity ^0.8;

import "../../api/issuance/IDropClaimCondition.sol";

import "@openzeppelin/contracts-upgradeable/utils/CountersUpgradeable.sol";

interface DropERC721DataTypes {
    struct SequencedURI {
        string uri;
        /// @dev The high-watermark sequence number a URI - used to tell if one URI is fresher than a another
        /// taken from the current value of uriSequenceCounter after it is incremented.
        uint256 sequenceNumber;
    }

    struct ClaimData {
        /// @dev The set of all claim conditions, at any given moment.
        IDropClaimConditionV0.ClaimConditionList claimCondition;
        /// @dev The next token ID of the NFT that can be claimed.
        uint256 nextTokenIdToClaim;
        /// @dev Mapping from address => total number of NFTs a wallet has claimed.
        mapping(address => uint256) walletClaimCount;
        /// @dev The next token ID of the NFT to "lazy mint".
        uint256 nextTokenIdToMint;
        /// @dev Global max total supply of NFTs.
        uint256 maxTotalSupply;
        /// @dev The max number of NFTs a wallet can claim.
        uint256 maxWalletClaimCount;
        /// @dev The address that receives all primary sales value.
        address primarySaleRecipient;
        /// @dev The address that receives all platform fees from all sales.
        address platformFeeRecipient;
        /// @dev The % of primary sales collected as platform fees.
        uint16 platformFeeBps;
        /// @dev Sequence number counter for the synchronisation of per-token URIs and baseURIs relative base on which
        /// was set most recently. Incremented on each URI-mutating action.
        CountersUpgradeable.Counter uriSequenceCounter;
        /// @dev One more than the Largest tokenId of each batch of tokens with the same baseURI
        uint256[] baseURIIndices;
        /// @dev Mapping from the 'base URI index' defined as the tokenId one more than the largest tokenId a batch of
        /// tokens which all same the same baseURI.
        /// Suppose we have two batches (and two baseURIs), with 3 and 4 tokens respectively, then in pictures we have:
        /// [baseURI1 | baseURI2]
        /// [ 0, 1, 2 | 3, 4, 5, 6]
        /// The baseURIIndices would be:
        /// [ 3, 7]
        mapping(uint256 => SequencedURI) baseURI;
        // Optional mapping for token URIs
        mapping(uint256 => SequencedURI) tokenURIs;
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (token/ERC721/extensions/ERC721Enumerable.sol)

pragma solidity ^0.8.0;

import "../ERC721Upgradeable.sol";
import "./IERC721EnumerableUpgradeable.sol";
import "../../../proxy/utils/Initializable.sol";

/**
 * @dev This implements an optional extension of {ERC721} defined in the EIP that adds
 * enumerability of all the token ids in the contract as well as all token ids owned by each
 * account.
 */
abstract contract ERC721EnumerableUpgradeable is Initializable, ERC721Upgradeable, IERC721EnumerableUpgradeable {
    function __ERC721Enumerable_init() internal onlyInitializing {
    }

    function __ERC721Enumerable_init_unchained() internal onlyInitializing {
    }
    // Mapping from owner to list of owned token IDs
    mapping(address => mapping(uint256 => uint256)) private _ownedTokens;

    // Mapping from token ID to index of the owner tokens list
    mapping(uint256 => uint256) private _ownedTokensIndex;

    // Array with all token ids, used for enumeration
    uint256[] private _allTokens;

    // Mapping from token id to position in the allTokens array
    mapping(uint256 => uint256) private _allTokensIndex;

    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId) public view virtual override(IERC165Upgradeable, ERC721Upgradeable) returns (bool) {
        return interfaceId == type(IERC721EnumerableUpgradeable).interfaceId || super.supportsInterface(interfaceId);
    }

    /**
     * @dev See {IERC721Enumerable-tokenOfOwnerByIndex}.
     */
    function tokenOfOwnerByIndex(address owner, uint256 index) public view virtual override returns (uint256) {
        require(index < ERC721Upgradeable.balanceOf(owner), "ERC721Enumerable: owner index out of bounds");
        return _ownedTokens[owner][index];
    }

    /**
     * @dev See {IERC721Enumerable-totalSupply}.
     */
    function totalSupply() public view virtual override returns (uint256) {
        return _allTokens.length;
    }

    /**
     * @dev See {IERC721Enumerable-tokenByIndex}.
     */
    function tokenByIndex(uint256 index) public view virtual override returns (uint256) {
        require(index < ERC721EnumerableUpgradeable.totalSupply(), "ERC721Enumerable: global index out of bounds");
        return _allTokens[index];
    }

    /**
     * @dev Hook that is called before any token transfer. This includes minting
     * and burning.
     *
     * Calling conditions:
     *
     * - When `from` and `to` are both non-zero, ``from``'s `tokenId` will be
     * transferred to `to`.
     * - When `from` is zero, `tokenId` will be minted for `to`.
     * - When `to` is zero, ``from``'s `tokenId` will be burned.
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     *
     * To learn more about hooks, head to xref:ROOT:extending-contracts.adoc#using-hooks[Using Hooks].
     */
    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 tokenId
    ) internal virtual override {
        super._beforeTokenTransfer(from, to, tokenId);

        if (from == address(0)) {
            _addTokenToAllTokensEnumeration(tokenId);
        } else if (from != to) {
            _removeTokenFromOwnerEnumeration(from, tokenId);
        }
        if (to == address(0)) {
            _removeTokenFromAllTokensEnumeration(tokenId);
        } else if (to != from) {
            _addTokenToOwnerEnumeration(to, tokenId);
        }
    }

    /**
     * @dev Private function to add a token to this extension's ownership-tracking data structures.
     * @param to address representing the new owner of the given token ID
     * @param tokenId uint256 ID of the token to be added to the tokens list of the given address
     */
    function _addTokenToOwnerEnumeration(address to, uint256 tokenId) private {
        uint256 length = ERC721Upgradeable.balanceOf(to);
        _ownedTokens[to][length] = tokenId;
        _ownedTokensIndex[tokenId] = length;
    }

    /**
     * @dev Private function to add a token to this extension's token tracking data structures.
     * @param tokenId uint256 ID of the token to be added to the tokens list
     */
    function _addTokenToAllTokensEnumeration(uint256 tokenId) private {
        _allTokensIndex[tokenId] = _allTokens.length;
        _allTokens.push(tokenId);
    }

    /**
     * @dev Private function to remove a token from this extension's ownership-tracking data structures. Note that
     * while the token is not assigned a new owner, the `_ownedTokensIndex` mapping is _not_ updated: this allows for
     * gas optimizations e.g. when performing a transfer operation (avoiding double writes).
     * This has O(1) time complexity, but alters the order of the _ownedTokens array.
     * @param from address representing the previous owner of the given token ID
     * @param tokenId uint256 ID of the token to be removed from the tokens list of the given address
     */
    function _removeTokenFromOwnerEnumeration(address from, uint256 tokenId) private {
        // To prevent a gap in from's tokens array, we store the last token in the index of the token to delete, and
        // then delete the last slot (swap and pop).

        uint256 lastTokenIndex = ERC721Upgradeable.balanceOf(from) - 1;
        uint256 tokenIndex = _ownedTokensIndex[tokenId];

        // When the token to delete is the last token, the swap operation is unnecessary
        if (tokenIndex != lastTokenIndex) {
            uint256 lastTokenId = _ownedTokens[from][lastTokenIndex];

            _ownedTokens[from][tokenIndex] = lastTokenId; // Move the last token to the slot of the to-delete token
            _ownedTokensIndex[lastTokenId] = tokenIndex; // Update the moved token's index
        }

        // This also deletes the contents at the last position of the array
        delete _ownedTokensIndex[tokenId];
        delete _ownedTokens[from][lastTokenIndex];
    }

    /**
     * @dev Private function to remove a token from this extension's token tracking data structures.
     * This has O(1) time complexity, but alters the order of the _allTokens array.
     * @param tokenId uint256 ID of the token to be removed from the tokens list
     */
    function _removeTokenFromAllTokensEnumeration(uint256 tokenId) private {
        // To prevent a gap in the tokens array, we store the last token in the index of the token to delete, and
        // then delete the last slot (swap and pop).

        uint256 lastTokenIndex = _allTokens.length - 1;
        uint256 tokenIndex = _allTokensIndex[tokenId];

        // When the token to delete is the last token, the swap operation is unnecessary. However, since this occurs so
        // rarely (when the last minted token is burnt) that we still do the swap here to avoid the gas cost of adding
        // an 'if' statement (like in _removeTokenFromOwnerEnumeration)
        uint256 lastTokenId = _allTokens[lastTokenIndex];

        _allTokens[tokenIndex] = lastTokenId; // Move the last token to the slot of the to-delete token
        _allTokensIndex[lastTokenId] = tokenIndex; // Update the moved token's index

        // This also deletes the contents at the last position of the array
        delete _allTokensIndex[tokenId];
        _allTokens.pop();
    }

    /**
     * @dev This empty reserved space is put in place to allow future versions to add new
     * variables without shifting down storage in the inheritance chain.
     * See https://docs.openzeppelin.com/contracts/4.x/upgradeable#storage_gaps
     */
    uint256[46] private __gap;
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.5.0) (token/ERC721/ERC721.sol)

pragma solidity ^0.8.0;

import "./IERC721Upgradeable.sol";
import "./IERC721ReceiverUpgradeable.sol";
import "./extensions/IERC721MetadataUpgradeable.sol";
import "../../utils/AddressUpgradeable.sol";
import "../../utils/ContextUpgradeable.sol";
import "../../utils/StringsUpgradeable.sol";
import "../../utils/introspection/ERC165Upgradeable.sol";
import "../../proxy/utils/Initializable.sol";

/**
 * @dev Implementation of https://eips.ethereum.org/EIPS/eip-721[ERC721] Non-Fungible Token Standard, including
 * the Metadata extension, but not including the Enumerable extension, which is available separately as
 * {ERC721Enumerable}.
 */
contract ERC721Upgradeable is Initializable, ContextUpgradeable, ERC165Upgradeable, IERC721Upgradeable, IERC721MetadataUpgradeable {
    using AddressUpgradeable for address;
    using StringsUpgradeable for uint256;

    // Token name
    string private _name;

    // Token symbol
    string private _symbol;

    // Mapping from token ID to owner address
    mapping(uint256 => address) private _owners;

    // Mapping owner address to token count
    mapping(address => uint256) private _balances;

    // Mapping from token ID to approved address
    mapping(uint256 => address) private _tokenApprovals;

    // Mapping from owner to operator approvals
    mapping(address => mapping(address => bool)) private _operatorApprovals;

    /**
     * @dev Initializes the contract by setting a `name` and a `symbol` to the token collection.
     */
    function __ERC721_init(string memory name_, string memory symbol_) internal onlyInitializing {
        __ERC721_init_unchained(name_, symbol_);
    }

    function __ERC721_init_unchained(string memory name_, string memory symbol_) internal onlyInitializing {
        _name = name_;
        _symbol = symbol_;
    }

    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId) public view virtual override(ERC165Upgradeable, IERC165Upgradeable) returns (bool) {
        return
            interfaceId == type(IERC721Upgradeable).interfaceId ||
            interfaceId == type(IERC721MetadataUpgradeable).interfaceId ||
            super.supportsInterface(interfaceId);
    }

    /**
     * @dev See {IERC721-balanceOf}.
     */
    function balanceOf(address owner) public view virtual override returns (uint256) {
        require(owner != address(0), "ERC721: balance query for the zero address");
        return _balances[owner];
    }

    /**
     * @dev See {IERC721-ownerOf}.
     */
    function ownerOf(uint256 tokenId) public view virtual override returns (address) {
        address owner = _owners[tokenId];
        require(owner != address(0), "ERC721: owner query for nonexistent token");
        return owner;
    }

    /**
     * @dev See {IERC721Metadata-name}.
     */
    function name() public view virtual override returns (string memory) {
        return _name;
    }

    /**
     * @dev See {IERC721Metadata-symbol}.
     */
    function symbol() public view virtual override returns (string memory) {
        return _symbol;
    }

    /**
     * @dev See {IERC721Metadata-tokenURI}.
     */
    function tokenURI(uint256 tokenId) public view virtual override returns (string memory) {
        require(_exists(tokenId), "ERC721Metadata: URI query for nonexistent token");

        string memory baseURI = _baseURI();
        return bytes(baseURI).length > 0 ? string(abi.encodePacked(baseURI, tokenId.toString())) : "";
    }

    /**
     * @dev Base URI for computing {tokenURI}. If set, the resulting URI for each
     * token will be the concatenation of the `baseURI` and the `tokenId`. Empty
     * by default, can be overriden in child contracts.
     */
    function _baseURI() internal view virtual returns (string memory) {
        return "";
    }

    /**
     * @dev See {IERC721-approve}.
     */
    function approve(address to, uint256 tokenId) public virtual override {
        address owner = ERC721Upgradeable.ownerOf(tokenId);
        require(to != owner, "ERC721: approval to current owner");

        require(
            _msgSender() == owner || isApprovedForAll(owner, _msgSender()),
            "ERC721: approve caller is not owner nor approved for all"
        );

        _approve(to, tokenId);
    }

    /**
     * @dev See {IERC721-getApproved}.
     */
    function getApproved(uint256 tokenId) public view virtual override returns (address) {
        require(_exists(tokenId), "ERC721: approved query for nonexistent token");

        return _tokenApprovals[tokenId];
    }

    /**
     * @dev See {IERC721-setApprovalForAll}.
     */
    function setApprovalForAll(address operator, bool approved) public virtual override {
        _setApprovalForAll(_msgSender(), operator, approved);
    }

    /**
     * @dev See {IERC721-isApprovedForAll}.
     */
    function isApprovedForAll(address owner, address operator) public view virtual override returns (bool) {
        return _operatorApprovals[owner][operator];
    }

    /**
     * @dev See {IERC721-transferFrom}.
     */
    function transferFrom(
        address from,
        address to,
        uint256 tokenId
    ) public virtual override {
        //solhint-disable-next-line max-line-length
        require(_isApprovedOrOwner(_msgSender(), tokenId), "ERC721: transfer caller is not owner nor approved");

        _transfer(from, to, tokenId);
    }

    /**
     * @dev See {IERC721-safeTransferFrom}.
     */
    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId
    ) public virtual override {
        safeTransferFrom(from, to, tokenId, "");
    }

    /**
     * @dev See {IERC721-safeTransferFrom}.
     */
    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId,
        bytes memory _data
    ) public virtual override {
        require(_isApprovedOrOwner(_msgSender(), tokenId), "ERC721: transfer caller is not owner nor approved");
        _safeTransfer(from, to, tokenId, _data);
    }

    /**
     * @dev Safely transfers `tokenId` token from `from` to `to`, checking first that contract recipients
     * are aware of the ERC721 protocol to prevent tokens from being forever locked.
     *
     * `_data` is additional data, it has no specified format and it is sent in call to `to`.
     *
     * This internal function is equivalent to {safeTransferFrom}, and can be used to e.g.
     * implement alternative mechanisms to perform token transfer, such as signature-based.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `tokenId` token must exist and be owned by `from`.
     * - If `to` refers to a smart contract, it must implement {IERC721Receiver-onERC721Received}, which is called upon a safe transfer.
     *
     * Emits a {Transfer} event.
     */
    function _safeTransfer(
        address from,
        address to,
        uint256 tokenId,
        bytes memory _data
    ) internal virtual {
        _transfer(from, to, tokenId);
        require(_checkOnERC721Received(from, to, tokenId, _data), "ERC721: transfer to non ERC721Receiver implementer");
    }

    /**
     * @dev Returns whether `tokenId` exists.
     *
     * Tokens can be managed by their owner or approved accounts via {approve} or {setApprovalForAll}.
     *
     * Tokens start existing when they are minted (`_mint`),
     * and stop existing when they are burned (`_burn`).
     */
    function _exists(uint256 tokenId) internal view virtual returns (bool) {
        return _owners[tokenId] != address(0);
    }

    /**
     * @dev Returns whether `spender` is allowed to manage `tokenId`.
     *
     * Requirements:
     *
     * - `tokenId` must exist.
     */
    function _isApprovedOrOwner(address spender, uint256 tokenId) internal view virtual returns (bool) {
        require(_exists(tokenId), "ERC721: operator query for nonexistent token");
        address owner = ERC721Upgradeable.ownerOf(tokenId);
        return (spender == owner || getApproved(tokenId) == spender || isApprovedForAll(owner, spender));
    }

    /**
     * @dev Safely mints `tokenId` and transfers it to `to`.
     *
     * Requirements:
     *
     * - `tokenId` must not exist.
     * - If `to` refers to a smart contract, it must implement {IERC721Receiver-onERC721Received}, which is called upon a safe transfer.
     *
     * Emits a {Transfer} event.
     */
    function _safeMint(address to, uint256 tokenId) internal virtual {
        _safeMint(to, tokenId, "");
    }

    /**
     * @dev Same as {xref-ERC721-_safeMint-address-uint256-}[`_safeMint`], with an additional `data` parameter which is
     * forwarded in {IERC721Receiver-onERC721Received} to contract recipients.
     */
    function _safeMint(
        address to,
        uint256 tokenId,
        bytes memory _data
    ) internal virtual {
        _mint(to, tokenId);
        require(
            _checkOnERC721Received(address(0), to, tokenId, _data),
            "ERC721: transfer to non ERC721Receiver implementer"
        );
    }

    /**
     * @dev Mints `tokenId` and transfers it to `to`.
     *
     * WARNING: Usage of this method is discouraged, use {_safeMint} whenever possible
     *
     * Requirements:
     *
     * - `tokenId` must not exist.
     * - `to` cannot be the zero address.
     *
     * Emits a {Transfer} event.
     */
    function _mint(address to, uint256 tokenId) internal virtual {
        require(to != address(0), "ERC721: mint to the zero address");
        require(!_exists(tokenId), "ERC721: token already minted");

        _beforeTokenTransfer(address(0), to, tokenId);

        _balances[to] += 1;
        _owners[tokenId] = to;

        emit Transfer(address(0), to, tokenId);

        _afterTokenTransfer(address(0), to, tokenId);
    }

    /**
     * @dev Destroys `tokenId`.
     * The approval is cleared when the token is burned.
     *
     * Requirements:
     *
     * - `tokenId` must exist.
     *
     * Emits a {Transfer} event.
     */
    function _burn(uint256 tokenId) internal virtual {
        address owner = ERC721Upgradeable.ownerOf(tokenId);

        _beforeTokenTransfer(owner, address(0), tokenId);

        // Clear approvals
        _approve(address(0), tokenId);

        _balances[owner] -= 1;
        delete _owners[tokenId];

        emit Transfer(owner, address(0), tokenId);

        _afterTokenTransfer(owner, address(0), tokenId);
    }

    /**
     * @dev Transfers `tokenId` from `from` to `to`.
     *  As opposed to {transferFrom}, this imposes no restrictions on msg.sender.
     *
     * Requirements:
     *
     * - `to` cannot be the zero address.
     * - `tokenId` token must be owned by `from`.
     *
     * Emits a {Transfer} event.
     */
    function _transfer(
        address from,
        address to,
        uint256 tokenId
    ) internal virtual {
        require(ERC721Upgradeable.ownerOf(tokenId) == from, "ERC721: transfer from incorrect owner");
        require(to != address(0), "ERC721: transfer to the zero address");

        _beforeTokenTransfer(from, to, tokenId);

        // Clear approvals from the previous owner
        _approve(address(0), tokenId);

        _balances[from] -= 1;
        _balances[to] += 1;
        _owners[tokenId] = to;

        emit Transfer(from, to, tokenId);

        _afterTokenTransfer(from, to, tokenId);
    }

    /**
     * @dev Approve `to` to operate on `tokenId`
     *
     * Emits a {Approval} event.
     */
    function _approve(address to, uint256 tokenId) internal virtual {
        _tokenApprovals[tokenId] = to;
        emit Approval(ERC721Upgradeable.ownerOf(tokenId), to, tokenId);
    }

    /**
     * @dev Approve `operator` to operate on all of `owner` tokens
     *
     * Emits a {ApprovalForAll} event.
     */
    function _setApprovalForAll(
        address owner,
        address operator,
        bool approved
    ) internal virtual {
        require(owner != operator, "ERC721: approve to caller");
        _operatorApprovals[owner][operator] = approved;
        emit ApprovalForAll(owner, operator, approved);
    }

    /**
     * @dev Internal function to invoke {IERC721Receiver-onERC721Received} on a target address.
     * The call is not executed if the target address is not a contract.
     *
     * @param from address representing the previous owner of the given token ID
     * @param to target address that will receive the tokens
     * @param tokenId uint256 ID of the token to be transferred
     * @param _data bytes optional data to send along with the call
     * @return bool whether the call correctly returned the expected magic value
     */
    function _checkOnERC721Received(
        address from,
        address to,
        uint256 tokenId,
        bytes memory _data
    ) private returns (bool) {
        if (to.isContract()) {
            try IERC721ReceiverUpgradeable(to).onERC721Received(_msgSender(), from, tokenId, _data) returns (bytes4 retval) {
                return retval == IERC721ReceiverUpgradeable.onERC721Received.selector;
            } catch (bytes memory reason) {
                if (reason.length == 0) {
                    revert("ERC721: transfer to non ERC721Receiver implementer");
                } else {
                    assembly {
                        revert(add(32, reason), mload(reason))
                    }
                }
            }
        } else {
            return true;
        }
    }

    /**
     * @dev Hook that is called before any token transfer. This includes minting
     * and burning.
     *
     * Calling conditions:
     *
     * - When `from` and `to` are both non-zero, ``from``'s `tokenId` will be
     * transferred to `to`.
     * - When `from` is zero, `tokenId` will be minted for `to`.
     * - When `to` is zero, ``from``'s `tokenId` will be burned.
     * - `from` and `to` are never both zero.
     *
     * To learn more about hooks, head to xref:ROOT:extending-contracts.adoc#using-hooks[Using Hooks].
     */
    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 tokenId
    ) internal virtual {}

    /**
     * @dev Hook that is called after any transfer of tokens. This includes
     * minting and burning.
     *
     * Calling conditions:
     *
     * - when `from` and `to` are both non-zero.
     * - `from` and `to` are never both zero.
     *
     * To learn more about hooks, head to xref:ROOT:extending-contracts.adoc#using-hooks[Using Hooks].
     */
    function _afterTokenTransfer(
        address from,
        address to,
        uint256 tokenId
    ) internal virtual {}

    /**
     * @dev This empty reserved space is put in place to allow future versions to add new
     * variables without shifting down storage in the inheritance chain.
     * See https://docs.openzeppelin.com/contracts/4.x/upgradeable#storage_gaps
     */
    uint256[44] private __gap;
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.5.0) (token/ERC721/extensions/IERC721Enumerable.sol)

pragma solidity ^0.8.0;

import "../IERC721Upgradeable.sol";

/**
 * @title ERC-721 Non-Fungible Token Standard, optional enumeration extension
 * @dev See https://eips.ethereum.org/EIPS/eip-721
 */
interface IERC721EnumerableUpgradeable is IERC721Upgradeable {
    /**
     * @dev Returns the total amount of tokens stored by the contract.
     */
    function totalSupply() external view returns (uint256);

    /**
     * @dev Returns a token ID owned by `owner` at a given `index` of its token list.
     * Use along with {balanceOf} to enumerate all of ``owner``'s tokens.
     */
    function tokenOfOwnerByIndex(address owner, uint256 index) external view returns (uint256);

    /**
     * @dev Returns a token ID at a given `index` of all the tokens stored by the contract.
     * Use along with {totalSupply} to enumerate all tokens.
     */
    function tokenByIndex(uint256 index) external view returns (uint256);
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8;

import "@openzeppelin/contracts-upgradeable/finance/PaymentSplitterUpgradeable.sol";
import "../generated/impl/BaseCedarPaymentSplitterV1.sol";


contract CedarPaymentSplitter is PaymentSplitterUpgradeable, BaseCedarPaymentSplitterV1 {
  mapping(address => bool) private payeeExists;

  function initialize (address[] memory payees, uint256[] memory shares_) external initializer {
    uint256 totalShares = 0;
    for(uint i = 0; i < shares_.length; i++) {
      totalShares = totalShares + shares_[i];

      require(payeeExists[payees[i]] == false, "duplicate");
      payeeExists[payees[i]] = true;
    }

    require(totalShares == 10000, "total share should be 10000");

    __PaymentSplitter_init(payees, shares_);
  }

  // Concrete implementation semantic version - provided for completeness but not designed to be the point of dispatch
  function minorVersion() public pure override returns (uint256 minor, uint256 patch) {
      minor = 0;
      patch = 0;
  }

  function getTotalReleased() external override view returns (uint256) {
    return totalReleased();
  }

  function getTotalReleased(IERC20Upgradeable token) external override view returns (uint256) {
    return totalReleased(token);
  }

  function getReleased(address account) external override view returns (uint256) {
    return released(account);
  }

  function getReleased(IERC20Upgradeable token, address account) external override view returns (uint256) {
    return released(token, account);
  }

  function releasePayment(address payable account) external override {
    release(account);
  }

  function releasePayment(IERC20Upgradeable token, address account) external override {
    release(token, account);
  }
}

// SPDX-License-Identifier: Apache-2.0

// Generated by impl.ts. Will be overwritten.
// Filename: './BaseCedarPaymentSplitterV1.sol'

pragma solidity ^0.8.4;

import "../../api/impl/ICedarPaymentSplitter.sol";

/// Inherit from this base to implement introspection
abstract contract BaseCedarPaymentSplitterV1 is ICedarPaymentSplitterV1 {
    function supportedFeatures() override public pure returns (string[] memory features) {
        features = new string[](3);
        features[0] = "ICedarFeatures.sol:ICedarFeaturesV0";
        features[1] = "ICedarVersioned.sol:ICedarVersionedV1";
        features[2] = "splitpayment/ICedarSplitPayment.sol:ICedarSplitPaymentV0";
    }

    /// This needs to be public to be callable from initialize via delegatecall
    function minorVersion() virtual override public pure returns (uint256 minor, uint256 patch);

    function implementationVersion() override public pure returns (uint256 major, uint256 minor, uint256 patch) {
        (minor, patch) = minorVersion();
        major = 1;
    }

    function implementationInterfaceName() virtual override public pure returns (string memory interfaceName) {
        interfaceName = "ICedarPaymentSplitterV1";
    }

    function supportsInterface(bytes4 interfaceID) virtual override public view returns (bool) {
        return (interfaceID == type(IERC165Upgradeable).interfaceId) || ((interfaceID == type(ICedarFeaturesV0).interfaceId) || ((interfaceID == type(ICedarVersionedV1).interfaceId) || (interfaceID == type(ICedarSplitPaymentV0).interfaceId)));
    }

    function isICedarFeaturesV0() override public pure returns (bool) {
        return true;
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (finance/PaymentSplitter.sol)

pragma solidity ^0.8.0;

import "../token/ERC20/utils/SafeERC20Upgradeable.sol";
import "../utils/AddressUpgradeable.sol";
import "../utils/ContextUpgradeable.sol";
import "../proxy/utils/Initializable.sol";

/**
 * @title PaymentSplitter
 * @dev This contract allows to split Ether payments among a group of accounts. The sender does not need to be aware
 * that the Ether will be split in this way, since it is handled transparently by the contract.
 *
 * The split can be in equal parts or in any other arbitrary proportion. The way this is specified is by assigning each
 * account to a number of shares. Of all the Ether that this contract receives, each account will then be able to claim
 * an amount proportional to the percentage of total shares they were assigned.
 *
 * `PaymentSplitter` follows a _pull payment_ model. This means that payments are not automatically forwarded to the
 * accounts but kept in this contract, and the actual transfer is triggered as a separate step by calling the {release}
 * function.
 *
 * NOTE: This contract assumes that ERC20 tokens will behave similarly to native tokens (Ether). Rebasing tokens, and
 * tokens that apply fees during transfers, are likely to not be supported as expected. If in doubt, we encourage you
 * to run tests before sending real value to this contract.
 */
contract PaymentSplitterUpgradeable is Initializable, ContextUpgradeable {
    event PayeeAdded(address account, uint256 shares);
    event PaymentReleased(address to, uint256 amount);
    event ERC20PaymentReleased(IERC20Upgradeable indexed token, address to, uint256 amount);
    event PaymentReceived(address from, uint256 amount);

    uint256 private _totalShares;
    uint256 private _totalReleased;

    mapping(address => uint256) private _shares;
    mapping(address => uint256) private _released;
    address[] private _payees;

    mapping(IERC20Upgradeable => uint256) private _erc20TotalReleased;
    mapping(IERC20Upgradeable => mapping(address => uint256)) private _erc20Released;

    /**
     * @dev Creates an instance of `PaymentSplitter` where each account in `payees` is assigned the number of shares at
     * the matching position in the `shares` array.
     *
     * All addresses in `payees` must be non-zero. Both arrays must have the same non-zero length, and there must be no
     * duplicates in `payees`.
     */
    function __PaymentSplitter_init(address[] memory payees, uint256[] memory shares_) internal onlyInitializing {
        __PaymentSplitter_init_unchained(payees, shares_);
    }

    function __PaymentSplitter_init_unchained(address[] memory payees, uint256[] memory shares_) internal onlyInitializing {
        require(payees.length == shares_.length, "PaymentSplitter: payees and shares length mismatch");
        require(payees.length > 0, "PaymentSplitter: no payees");

        for (uint256 i = 0; i < payees.length; i++) {
            _addPayee(payees[i], shares_[i]);
        }
    }

    /**
     * @dev The Ether received will be logged with {PaymentReceived} events. Note that these events are not fully
     * reliable: it's possible for a contract to receive Ether without triggering this function. This only affects the
     * reliability of the events, and not the actual splitting of Ether.
     *
     * To learn more about this see the Solidity documentation for
     * https://solidity.readthedocs.io/en/latest/contracts.html#fallback-function[fallback
     * functions].
     */
    receive() external payable virtual {
        emit PaymentReceived(_msgSender(), msg.value);
    }

    /**
     * @dev Getter for the total shares held by payees.
     */
    function totalShares() public view returns (uint256) {
        return _totalShares;
    }

    /**
     * @dev Getter for the total amount of Ether already released.
     */
    function totalReleased() public view returns (uint256) {
        return _totalReleased;
    }

    /**
     * @dev Getter for the total amount of `token` already released. `token` should be the address of an IERC20
     * contract.
     */
    function totalReleased(IERC20Upgradeable token) public view returns (uint256) {
        return _erc20TotalReleased[token];
    }

    /**
     * @dev Getter for the amount of shares held by an account.
     */
    function shares(address account) public view returns (uint256) {
        return _shares[account];
    }

    /**
     * @dev Getter for the amount of Ether already released to a payee.
     */
    function released(address account) public view returns (uint256) {
        return _released[account];
    }

    /**
     * @dev Getter for the amount of `token` tokens already released to a payee. `token` should be the address of an
     * IERC20 contract.
     */
    function released(IERC20Upgradeable token, address account) public view returns (uint256) {
        return _erc20Released[token][account];
    }

    /**
     * @dev Getter for the address of the payee number `index`.
     */
    function payee(uint256 index) public view returns (address) {
        return _payees[index];
    }

    /**
     * @dev Triggers a transfer to `account` of the amount of Ether they are owed, according to their percentage of the
     * total shares and their previous withdrawals.
     */
    function release(address payable account) public virtual {
        require(_shares[account] > 0, "PaymentSplitter: account has no shares");

        uint256 totalReceived = address(this).balance + totalReleased();
        uint256 payment = _pendingPayment(account, totalReceived, released(account));

        require(payment != 0, "PaymentSplitter: account is not due payment");

        _released[account] += payment;
        _totalReleased += payment;

        AddressUpgradeable.sendValue(account, payment);
        emit PaymentReleased(account, payment);
    }

    /**
     * @dev Triggers a transfer to `account` of the amount of `token` tokens they are owed, according to their
     * percentage of the total shares and their previous withdrawals. `token` must be the address of an IERC20
     * contract.
     */
    function release(IERC20Upgradeable token, address account) public virtual {
        require(_shares[account] > 0, "PaymentSplitter: account has no shares");

        uint256 totalReceived = token.balanceOf(address(this)) + totalReleased(token);
        uint256 payment = _pendingPayment(account, totalReceived, released(token, account));

        require(payment != 0, "PaymentSplitter: account is not due payment");

        _erc20Released[token][account] += payment;
        _erc20TotalReleased[token] += payment;

        SafeERC20Upgradeable.safeTransfer(token, account, payment);
        emit ERC20PaymentReleased(token, account, payment);
    }

    /**
     * @dev internal logic for computing the pending payment of an `account` given the token historical balances and
     * already released amounts.
     */
    function _pendingPayment(
        address account,
        uint256 totalReceived,
        uint256 alreadyReleased
    ) private view returns (uint256) {
        return (totalReceived * _shares[account]) / _totalShares - alreadyReleased;
    }

    /**
     * @dev Add a new payee to the contract.
     * @param account The address of the payee to add.
     * @param shares_ The number of shares owned by the payee.
     */
    function _addPayee(address account, uint256 shares_) private {
        require(account != address(0), "PaymentSplitter: account is the zero address");
        require(shares_ > 0, "PaymentSplitter: shares are 0");
        require(_shares[account] == 0, "PaymentSplitter: account already has shares");

        _payees.push(account);
        _shares[account] = shares_;
        _totalShares = _totalShares + shares_;
        emit PayeeAdded(account, shares_);
    }

    /**
     * @dev This empty reserved space is put in place to allow future versions to add new
     * variables without shifting down storage in the inheritance chain.
     * See https://docs.openzeppelin.com/contracts/4.x/upgradeable#storage_gaps
     */
    uint256[43] private __gap;
}