// SPDX-License-Identifier: MIT
pragma solidity ^0.8.11;

import "@openzeppelin/contracts/proxy/Clones.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

import "../interfaces/IPassport2.sol";
import "../interfaces/ILoyaltyLedger2.sol";
import "../interfaces/IPassageRegistry2.sol";

contract PassagePresetFactory is Ownable {
    // structs
    struct AirdropParameters {
        address[] addresses;
        uint256[] amounts;
    }
    struct LoyaltyTokenParameters {
        string name;
        uint256 maxSupply;
    }
    struct MintingModuleParameters {
        string name;
        bytes data;
    }

    // constants
    address public immutable registry; // Passage Registry v2
    bytes32 public constant DEFAULT_ADMIN_ROLE = 0x0000000000000000000000000000000000000000000000000000000000000000;
    bytes32 public constant MANAGER_ROLE = keccak256("MANAGER_ROLE");
    bytes32 public constant UPGRADER_ROLE = keccak256("UPGRADER_ROLE");
    bytes32 public constant MINTER_ROLE = keccak256("MINTER_ROLE");

    // module addresses
    address public nonTransferableAddr; // shared contract
    address public nonTransferable1155Addr; // shared contract
    mapping(string => address) public mmNameToImplAddr; // minting module human readable name -> cloneable implementation address

    // events
    event PresetPassportCreated(address indexed creator, address passportAddress);
    event PresetLoyaltyLedgerCreated(address indexed creator, address llAddress);
    event NonTransferable721ModuleSet(address implAddress);
    event NonTransferable1155ModuleSet(address implAddress);
    event MintingModuleSet(string indexed name, address implAddress);

    /// @param _registry Passage registry address
    constructor(address _registry) {
        require(_registry != address(0), "Invalid registry address");

        registry = _registry;
    }

    /// @notice Creates a new Loyalty Ledger
    /// @param royaltyWallet The address of the wallet to designated to receive royalty payments
    /// @param royaltyBasisPoints The number representing the basis points of royalty fees out of 10000 (e.g. 750 = 7.5% royalty)
    /// @param transferEnabled If transfer should be enabled
    /// @param mmParameters Human readable minting module name (for impl address lookups) & their respective bytes encoded initializer data
    /// @param tokenParameters Token name & maxSupply parameters to create on the Loyalty Ledger
    /// @param airdropParameters Addresses and amounts for each address to mint tokens for after contract creation. Lengths must be equal. For no airdrop, pass an empty array for both values. Lengths must be equal
    function createLoyalty(
        address royaltyWallet,
        uint96 royaltyBasisPoints,
        bool transferEnabled,
        MintingModuleParameters[] calldata mmParameters,
        LoyaltyTokenParameters calldata tokenParameters,
        AirdropParameters calldata airdropParameters
    ) external returns (address) {
        address loyaltyLedger = _createLoyalty(royaltyWallet, royaltyBasisPoints);
        ILoyaltyLedger2(loyaltyLedger).createToken(tokenParameters.name, tokenParameters.maxSupply);
        for (uint256 i = 0; i < mmParameters.length; ) {
            address mmAddress = mmNameToImplAddr[mmParameters[i].name];
            require(mmAddress != address(0), "invalid minting module name");
            require(mmParameters[i].data.length > 0, "invalid minting module data");
            bytes memory data = abi.encodeWithSignature(
                "initialize(address,address,bytes)",
                msg.sender,
                loyaltyLedger,
                mmParameters[i].data
            );
            mmAddress = _cloneAndInitalizeMintingModule(mmAddress, data);
            ILoyaltyLedger2(loyaltyLedger).setTokenMintingModule(0, i, mmAddress);
            unchecked {
                ++i;
            }
        }
        if (!transferEnabled) {
            ILoyaltyLedger2(loyaltyLedger).setBeforeTransfersModule(nonTransferable1155Addr);
        }
        if (airdropParameters.addresses.length > 0) {
            require(
                airdropParameters.amounts.length == airdropParameters.addresses.length,
                "airdrop params length mismatch"
            );

            ILoyaltyLedger2(loyaltyLedger).mintBulk(
                airdropParameters.addresses,
                new uint256[](airdropParameters.addresses.length), // minting token 0 and defaults to 0
                airdropParameters.amounts
            );
        }
        _grantRoles(loyaltyLedger, msg.sender);
        _revokeRoles(loyaltyLedger, address(this));
        return loyaltyLedger;
    }

    /// @notice Creates a new Passport
    /// @param tokenName The token name
    /// @param tokenSymbol The token symbol
    /// @param maxSupply Max supply of tokens
    /// @param royaltyWallet The address of the wallet to designated to receive royalty payments
    /// @param royaltyBasisPoints The number representing the basis points of royalty fees out of 10000 (e.g. 750 = 7.5% royalty)
    /// @param transferEnabled If transfer should be enabled
    /// @param mmParameters Human readable minting module name (for impl address lookups) & their respective bytes encoded initializer data.
    /// @param airdropParameters Addresses and amounts for each address to mint passports for after contract creation. Lengths must be equal. For no airdrop, pass an empty array for both values.
    function createPassport(
        string memory tokenName,
        string memory tokenSymbol,
        uint256 maxSupply,
        address royaltyWallet,
        uint96 royaltyBasisPoints,
        bool transferEnabled,
        MintingModuleParameters[] calldata mmParameters,
        AirdropParameters calldata airdropParameters
    ) external returns (address) {
        address passport = _createPassport(tokenName, tokenSymbol, maxSupply, royaltyWallet, royaltyBasisPoints);

        if (mmParameters.length > 0) {
            for (uint256 i = 0; i < mmParameters.length; ) {
                address mmAddress = mmNameToImplAddr[mmParameters[i].name];
                require(mmAddress != address(0), "invalid minting module name");
                require(mmParameters[i].data.length > 0, "invalid minting module data");
                bytes memory data = abi.encodeWithSignature(
                    "initialize(address,address,bytes)",
                    msg.sender,
                    passport,
                    mmParameters[i].data
                );
                mmAddress = _cloneAndInitalizeMintingModule(mmAddress, data);
                IPassport2(passport).setMintingModule(i, mmAddress);
                unchecked {
                    ++i;
                }
            }
        }
        if (!transferEnabled) {
            IPassport2(passport).setBeforeTransfersModule(nonTransferableAddr);
        }
        if (airdropParameters.addresses.length > 0) {
            require(
                airdropParameters.amounts.length == airdropParameters.addresses.length,
                "airdrop params length mismatch"
            );

            IPassport2(passport).mintPassports(airdropParameters.addresses, airdropParameters.amounts);
        }
        _grantRoles(passport, msg.sender);
        _revokeRoles(passport, address(this));
        return passport;
    }

    function setNonTransferable721Addr(address contractAddress) external onlyOwner {
        nonTransferableAddr = contractAddress;
        emit NonTransferable721ModuleSet(contractAddress);
    }

    function setNonTransferable1155Addr(address contractAddress) external onlyOwner {
        nonTransferable1155Addr = contractAddress;
        emit NonTransferable1155ModuleSet(contractAddress);
    }

    function setMintingModule(string calldata name, address implAddress) external onlyOwner {
        require(bytes(name).length > 0, "mm name required");
        mmNameToImplAddr[name] = implAddress;
        emit MintingModuleSet(name, implAddress);
    }

    function _createPassport(
        string memory tokenName,
        string memory tokenSymbol,
        uint256 maxSupply,
        address royaltyWallet,
        uint96 royaltyBasisPoints
    ) internal returns (address) {
        IPassageRegistry2 r = IPassageRegistry2(registry);
        bytes memory args = abi.encodeWithSignature(
            "initialize(address,string,string,uint256,uint256,address,uint96)",
            address(this), // factory gets initial permissions
            tokenName,
            tokenSymbol,
            maxSupply,
            0,
            royaltyWallet,
            royaltyBasisPoints
        );
        address passport = r.createPassport(args);

        emit PresetPassportCreated(msg.sender, passport);
        return passport;
    }

    function _grantRoles(address _contract, address _address) internal {
        IPassport2(_contract).grantRole(DEFAULT_ADMIN_ROLE, _address);
        IPassport2(_contract).grantRole(UPGRADER_ROLE, _address);
        IPassport2(_contract).grantRole(MANAGER_ROLE, _address);
        IPassport2(_contract).grantRole(MINTER_ROLE, _address);
        IPassport2(_contract).setOwnership(_address);
    }

    function _revokeRoles(address _contract, address _address) internal {
        IPassport2(_contract).revokeRole(UPGRADER_ROLE, _address);
        IPassport2(_contract).revokeRole(MANAGER_ROLE, _address);
        IPassport2(_contract).revokeRole(MINTER_ROLE, _address);
        IPassport2(_contract).revokeRole(DEFAULT_ADMIN_ROLE, _address);
    }

    function _cloneAndInitalizeMintingModule(address mmImplAddr, bytes memory data) internal returns (address) {
        address cloneAddr = Clones.clone(mmImplAddr);
        (bool success, ) = cloneAddr.call(data);
        require(success, "module initialize failed");
        return cloneAddr;
    }

    function _createLoyalty(address royaltyWallet, uint96 royaltyBasisPoints) internal returns (address) {
        IPassageRegistry2 r = IPassageRegistry2(registry);
        bytes memory args = abi.encodeWithSignature(
            "initialize(address,address,uint96)",
            address(this), // factory gets initial permissions
            royaltyWallet,
            royaltyBasisPoints
        );
        address loyaltyLedger = r.createLoyalty(args);

        emit PresetLoyaltyLedgerCreated(msg.sender, loyaltyLedger);
        return loyaltyLedger;
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (proxy/Clones.sol)

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
        /// @solidity memory-safe-assembly
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
        /// @solidity memory-safe-assembly
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
        /// @solidity memory-safe-assembly
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
pragma solidity ^0.8.11;

import "../interfaces/IPassageAccess.sol";

interface IPassport2 is IPassageAccess {
    event BaseUriUpdated(string uri);
    event MaxSupplyLocked();
    event MaxSupplyUpdated(uint256 maxSupply);
    event PassportInitialized(
        address registryAddress,
        address passportAddress,
        string symbol,
        string name,
        uint256 maxSupply
    );
    event RenderModuleSet(address moduleAddress);
    event BeforeTransferModuleSet(address moduleAddress);
    event MintingModuleAdded(address moduleAddress, uint256 index);
    event Withdraw(uint256 value, address indexed withdrawnBy);
    event VersionLocked();
    event RoyaltyInfoSet(address wallet, uint96 basisPoints);

    function claim(
        uint256 mintingModuleIndex,
        uint256[] calldata tokenIds,
        uint256[] calldata mintAmounts,
        bytes32[] calldata proof,
        bytes calldata data
    ) external payable;

    function eject() external;

    function initialize(
        address _creator,
        string memory _tokenName,
        string memory _tokenSymbol,
        uint256 _maxSupply,
        uint256 _initialTokenId,
        address _royaltyWallet,
        uint96 _royaltyBasisPoints
    ) external;

    function lockMaxSupply() external;

    function lockVersion() external;

    function mintPassports(address[] calldata _addresses, uint256[] calldata _amounts)
        external
        returns (uint256, uint256);

    function passportVersion() external pure returns (uint256 version);

    function setBaseURI(string memory _uri) external;

    function setOwnership(address newOwner) external;

    function setTrustedForwarder(address forwarder) external;

    function withdraw() external;

    function isManaged() external returns (bool);

    function setMaxSupply(uint256 _maxSupply) external;

    function setRenderModule(address _contractAddress) external;

    function setBeforeTransfersModule(address _contractAddress) external;

    function setMintingModule(uint256 index, address _contractAddress) external;

    function setRoyalty(address _royaltyWallet, uint96 _royaltyBasisPoints) external;

    function hasUpgraderRole(address _address) external view returns (bool);

    function upgradeTo(address newImplementation) external;

    function upgradeToAndCall(address newImplementation, bytes memory data) external payable;

    function supportsInterface(bytes4 interfaceId) external returns (bool);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.11;

import "@openzeppelin/contracts-upgradeable/access/IAccessControlUpgradeable.sol";
import "./modules/minting/IMintingModule.sol";

interface ILoyaltyLedger2 is IAccessControlUpgradeable {
    struct Token {
        string name;
        uint256 maxSupply; // 0 is no max
        uint256 totalMinted;
        mapping(uint256 => IMintingModule) mintingModules;
    }

    // ---- events ----
    event BaseUriUpdated(string uri);
    event TokenCreated(uint256 id, string name, uint256 maxSupply);
    event MaxSupplyUpdated(uint256 id, uint256 maxSupply);
    event Withdraw(uint256 value, address indexed withdrawnBy);
    event VersionLocked();
    event RenderModuleSet(address moduleAddress);
    event BeforeTransferModuleSet(address moduleAddress);
    event MintingModuleSet(uint256 id, uint256 index, address moduleAddress);
    event RoyaltyInfoSet(address wallet, uint96 basisPoints);
    event LoyaltyLedgerInitialized(address creator, address ll, address royaltyWallet, uint96 royaltyPoints);

    function claim(
        uint256 id,
        uint256 mmIndex,
        uint256[] calldata tokenIds,
        uint256[] calldata claimAmounts,
        bytes32[] calldata proof,
        bytes calldata data
    ) external payable;

    function createToken(string memory _name, uint256 _maxSupply) external returns (uint256);

    function eject() external;

    function hasUpgraderRole(address _address) external view returns (bool);

    function initialize(
        address _creator,
        address _royaltyWallet,
        uint96 _royaltyBasisPoints
    ) external;

    function isManaged() external view returns (bool);

    function lockVersion() external;

    function loyaltyLedgerVersion() external pure returns (uint256);

    function mint(
        address _to,
        uint256 _id,
        uint256 _amount
    ) external;

    function mintBatch(
        address _to,
        uint256[] calldata _ids,
        uint256[] calldata _amounts
    ) external;

    function mintBulk(
        address[] calldata _addresses,
        uint256[] calldata _ids,
        uint256[] calldata _amounts
    ) external;

    function setOwnership(address newOwner) external;

    function setTokenMaxSupply(uint256 _id, uint256 _maxSupply) external;

    function setRenderModule(address _contractAddress) external;

    function setBeforeTransfersModule(address _contractAddress) external;

    function setTokenMintingModule(
        uint256 _id,
        uint256 _index,
        address _contractAddress
    ) external;

    function getTokenMintingModule(uint256 _id, uint256 _index) external view returns (address);

    function setRoyalty(address _royaltyWallet, uint96 _royaltyBasisPoints) external;

    function upgradeTo(address newImplementation) external;

    function upgradeToAndCall(address newImplementation, bytes memory data) external payable;

    function supportsInterface(bytes4 interfaceId) external returns (bool);

    function withdraw() external;
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.11;

import "@openzeppelin/contracts-upgradeable/access/IAccessControlUpgradeable.sol";

interface IPassageRegistry2 is IAccessControlUpgradeable {
    // ---- events ----
    event PassportBaseUriUpdated(string uri);
    event PassportCreated(address indexed passportAddress);
    event PassportEjected(address ejectedAddress);
    event PassportImplementationAdded(uint256 version, address implementation);
    event PassportVersionUpgraded(address indexed passportAddress, uint256 version);
    event LoyaltyBaseUriUpdated(string uri);
    event LoyaltyCreated(address indexed loyaltyAddress);
    event LoyaltyLedgerEjected(address ejectedAddress);
    event LoyaltyLedgerImplementationAdded(uint256 version, address implementation);
    event LoyaltyVersionUpgraded(address indexed loyaltyAddress, uint256 version);

    function loyaltyImplementations(uint256) external view returns (address);

    function passportImplementations(uint256) external view returns (address);

    function addLoyaltyImplementation(address implementation) external;

    function addPassportImplementation(address implementation) external;

    function createLoyalty(address _royaltyWallet, uint96 _royaltyBasisPoints)
        external
        returns (address loyaltyAddress);

    function createLoyalty(bytes memory data) external returns (address loyaltyAddress);

    function createPassport(
        string calldata _tokenName,
        string calldata _tokenSymbol,
        uint256 _maxSupply,
        uint256 _startTokenId,
        address _royaltyWallet,
        uint96 _royaltyBasisPoints
    ) external returns (address passportAddress);

    function createPassport(bytes memory data) external returns (address passportAddress);

    function ejectLoyaltyLedger() external;

    function ejectPassport() external;

    function globalLoyaltyBaseURI() external view returns (string memory);

    function globalPassportBaseURI() external view returns (string memory);

    function initialize(string memory _globalPassportBaseURI, string memory _globalLoyaltyBaseURI) external;

    function loyaltyLatestVersion() external view returns (uint256);

    function managedLoyaltyLedgers(address) external view returns (bool);

    function managedPassports(address) external view returns (bool);

    function passportLatestVersion() external view returns (uint256);

    function setGlobalLoyaltyBaseURI(string memory _uri) external;

    function setGlobalPassportBaseURI(string memory _uri) external;

    function setTrustedForwarder(address forwarder) external;

    function upgradeLoyalty(uint256 version, address loyaltyAddress) external returns (uint256 newVersion);

    function upgradePassport(uint256 version, address passportAddress) external returns (uint256 newVersion);
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
pragma solidity ^0.8.11;

import "@openzeppelin/contracts-upgradeable/access/IAccessControlUpgradeable.sol";

interface IPassageAccess is IAccessControlUpgradeable {
    function hasUpgraderRole(address _address) external view returns (bool);
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

pragma solidity ^0.8.11;

interface IMintingModule {
    /// @dev Called by original contract to return how many tokens sender can mint
    /// @notice if performing storage updates, good practice to check that msg.sender is original contract
    function canMint(
        address minter,
        uint256 value,
        uint256[] calldata tokenIds,
        uint256[] calldata mintAmounts,
        bytes32[] calldata proof,
        bytes calldata data
    ) external returns (uint256);
}