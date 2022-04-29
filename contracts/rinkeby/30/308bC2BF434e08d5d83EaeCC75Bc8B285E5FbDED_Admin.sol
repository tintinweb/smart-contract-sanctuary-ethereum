// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

/// @author: @props

import "../extensions/IAllowlist.sol";
import "../extensions/IRoyalty.sol";
import "./Base.sol";
import "./IAdmin.sol";
import "./IConfig.sol";

contract Admin is
    Base,
    IAdmin,
    IConfig {

    // TODO: add abi uri
    constructor ()  {}

    IConfig.Config[] public config;
    IConfig.Pricelist[] public pricelists;

    address payable public splitContract;

    mapping(uint256 => uint256) public allocations;
    mapping(IConfig.Extensions => address) public extensions;

    // see https://docs.opensea.io/docs/contract-level-metadata
    string private _contractURI;

    /**
     * @dev see {IERC165-supportsInterface}
     */
    function supportsInterface(bytes4 interfaceId) public view virtual override(IERC165, Base) returns (bool) {
        return interfaceId == type(IAdmin).interfaceId || super.supportsInterface(interfaceId);
    }

    /**
    * @dev see {IAdmin-createConfig}
    */
    function createConfig(IConfig.Config memory _config) external onlyRole(CONTRACT_ADMIN_ROLE) nonReentrant {
        config.push(_config);
    }

    /**
    * @dev see {IAdmin-updateConfig}
    */
    function updateConfig(uint256 _configId, IConfig.Config memory _config) external onlyRole(CONTRACT_ADMIN_ROLE) nonReentrant {
        if (config.length == 0) revert ConfigNotFound(_configId);
        if (!(config.length > _configId)) revert ConfigNotFound(_configId);
        config[_configId].mintConfig = _config.mintConfig;
        config[_configId].tokenConfig = _config.tokenConfig;
    }

    /**
    * @dev see {IAdmin-getAllocationByAddress}
    */
    function getAllocationByAddress(address _address, bytes32[][] memory _proofs) public view returns (Allocation memory) {
        (bool exists, uint256 allowlistId) = getAllowlistIdByAddress(_address, _proofs);
        uint256 allocated = 0;
        uint256 price = 0;
        if (exists) {
            allocated = allocations[allowlistId];
            price = getPricelistByAllowlistId(allowlistId).price;
        }
        return Allocation(allowlistId, allocated, price);
    }

    /**
    * @dev see {IAdmin-getAllocationTotalByAddress}
    */
    function getAllocationTotalByAddress(address _address, bytes32[][] memory _proofs) public view returns (uint256) {
        IAllowlist.Allowlist[] memory allowlists = IAllowlist(extensions[IConfig.Extensions.Allowlist]).getAllowlists();
        uint256 allocated = 0;
        unchecked {
            for (uint i = 0; i < allowlists.length; i++) {
                if (IAllowlist(extensions[IConfig.Extensions.Allowlist]).isAllowedOn(i, _address, _proofs)) allocated += allocations[i];
            }
        }
        return allocated;
    }

    /**
    * @dev see {IAdmin-getAllowlistIdByAddress}
    */
    function getAllowlistIdByAddress(address _address, bytes32[][] memory _proofs) public view returns (bool, uint256) {
        IAllowlist.Allowlist[] memory allowlists = IAllowlist(extensions[IConfig.Extensions.Allowlist]).getAllowlists();
        unchecked {
            for (uint i = 0; i < allowlists.length; i++) {
                if (IAllowlist(extensions[IConfig.Extensions.Allowlist]).isAllowedOn(i, _address, _proofs)) return (true, i);
            }
        }
        return (false, 0);
    }

    /**
    * @dev see {IAdmin-setAllocation}
    */
    function setAllocation(uint256 _allowlistId, uint256 _allocation) external onlyRole(CONTRACT_ADMIN_ROLE) nonReentrant {
        allocations[_allowlistId]= _allocation;
    }

    /**
    * @dev see {IAdmin-setContractURI}
    */
    function setContractURI(string memory contractURI_) external onlyRole(CONTRACT_ADMIN_ROLE) nonReentrant {
        _contractURI = contractURI_;
    }

    /**
    * @dev see {IAdmin-getContractURI}
    */
    function getContractURI() external view returns (string memory) {
        return _contractURI;
    }

    /**
    * @dev see {IAdmin-setExtensions}
    */
    function setExtension(IConfig.Extensions _extension, address _address) external onlyRole(CONTRACT_ADMIN_ROLE) nonReentrant {
        // check whether or not _address supports the proper interface before setting extension address
        if (_extension == IConfig.Extensions.Allowlist) {
            if (!IAllowlist(_address).supportsInterface(type(IAllowlist).interfaceId)) revert ExtensionInvalid();
        } else if (_extension == IConfig.Extensions.Royalty) {
            if (!IRoyalty(_address).supportsInterface(type(IRoyalty).interfaceId)) revert ExtensionInvalid();
        }
        else {
            revert ExtensionInvalid();
        }
        extensions[_extension] = _address;
    }

    /**
    * @dev see {IAdmin-createPricelist}
    */
    function createPricelist(IConfig.Pricelist memory _pricelist) external onlyRole(CONTRACT_ADMIN_ROLE) nonReentrant {
        pricelists.push(_pricelist);
    }

    /**
    * @dev see {IAdmin-updatePricelist}
    */
    function updatePricelist(uint256 _pricelistId, IConfig.Pricelist memory _pricelist) external onlyRole(CONTRACT_ADMIN_ROLE) nonReentrant {
        if (pricelists.length == 0) revert PricelistNotFound(_pricelistId);
        if (!(pricelists.length > _pricelistId)) revert PricelistNotFound(_pricelistId);
        pricelists[_pricelistId] = _pricelist;
    }

    /**
    * @dev see {IAdmin-getPricelistByAllowlistId}
    */
    function getPricelistByAllowlistId(uint256 _allowlistId) public view returns (IConfig.Pricelist memory) {
        unchecked {
            for (uint i = 0; i < pricelists.length; i++) {
                if (pricelists[i].allowlistId == _allowlistId) return pricelists[i];
            }
        }
        revert PricelistNotFound(_allowlistId);
    }

    /**
    * @dev see {IAdmin-setSplitContract}
    */
    function setSplitContract(address payable _address) external onlyRole(CONTRACT_ADMIN_ROLE) {
        splitContract = _address;
    }

    /**
    * @dev see {IAdmin-getSplitContract}
    */
    function getSplitContract() external view returns (address payable) {
        return splitContract;
    }

    /**
    * @dev see {IAdmin-createAllowlist}
    */
    function createAllowlist(IAllowlist.Allowlist memory _allowlist) external onlyRole(CONTRACT_ADMIN_ROLE) nonReentrant {
        IAllowlist(extensions[IConfig.Extensions.Allowlist]).createAllowlist(_allowlist);
    }

    /**
    * @dev see {IAdmin-updateAllowlist}
    */
    function updateAllowlist(uint256 _allowlistId, IAllowlist.Allowlist memory _allowlist) external onlyRole(CONTRACT_ADMIN_ROLE) nonReentrant {
        IAllowlist(extensions[IConfig.Extensions.Allowlist]).updateAllowlist(_allowlistId, _allowlist);
    }

    /**
    * @dev see {IAdmin-getAllowlists}
    */
    function getAllowlists() external view returns (IAllowlist.Allowlist[] memory) {
      IAllowlist.Allowlist[] memory allowlists = IAllowlist(extensions[IConfig.Extensions.Allowlist]).getAllowlists();
      return allowlists;
    }

    /**
    * @dev {IAdmin-addRoyaltyShare}
    */
    function addRoyaltyShare(address _account) external onlyRole(CONTRACT_ADMIN_ROLE) nonReentrant {
        IRoyalty(extensions[IConfig.Extensions.Royalty]).addShare(_account);
    }

    /**
    * @dev {IAdmin-removeRoyaltyShare}
    */
    function removeRoyaltyShare(address _account) external onlyRole(CONTRACT_ADMIN_ROLE) nonReentrant {
        IRoyalty(extensions[IConfig.Extensions.Royalty]).removeShare(_account);
    }

    /**
    * @dev see {IAdmin-revertOnAllocationCheckFailure}
    */
    function revertOnAllocationCheckFailure(address _address, bytes32[][] memory _proofs, uint256 _quantity) external view returns (Allocation memory) {
        return _revertOnAllocationCheckFailure(_address, _proofs, _quantity);
    }

    /**
    * @dev see {IAdmin-revertOnMintCheckFailure}
    */
    function revertOnMintCheckFailure(uint256 _configId, uint256 _quantity, uint256 _totalSupply, bool _paused) external view {
        _revertOnMintCheckFailure(_configId, _quantity, _totalSupply, _paused);
    }

    /**
    * @dev see {IAdmin-revertOnAllocationCheckFailure}
    */
    function _revertOnAllocationCheckFailure(address _address, bytes32[][] memory _proofs, uint256 _quantity) internal view returns (Allocation memory) {
        Allocation memory allocated = getAllocationByAddress(_address, _proofs);
        if (_quantity > allocated.allocation) revert AllocationExceeded();
        return allocated;
    }

    /**
    * @dev see {IAdmin-revertOnPaymentFailure}
    */
    function revertOnPaymentFailure(uint256 _configId, uint256 _price, uint256 _quantity, uint256 _payment, bool _override) external view {
        _revertOnPaymentFailure(_configId, _price, _quantity, _payment, _override);
    }

    /**
    * @dev see {IAdmin-revertOnArbitraryPaymentFailure}
    */
    function revertOnArbitraryPaymentFailure(uint256 _price, uint256 _payment) external view {
        if (_payment < _price) revert InsufficientFunds();
    }

    /**
    * @dev see {IAdmin-revertOnMintCheckFailure}
    */
    function _revertOnMintCheckFailure(
        uint256 _configId,
        uint256 _quantity,
        uint256 _totalSupply,
        bool _paused
    ) internal view {
        if (config.length == 0) revert ConfigNotFound(_configId);
        if (!(config.length > _configId)) revert ConfigNotFound(_configId);
        if (_paused) revert MintPaused();
        if (!config[_configId].mintConfig.isActive) revert MintInactive();
        if (block.timestamp < config[_configId].mintConfig.startTime) revert MintNotStarted();
        if (block.timestamp > config[_configId].mintConfig.endTime) revert MintClosed();
        if (_quantity == 0) revert MintQuantityInvalid();
        if (_quantity > config[_configId].mintConfig.maxPerTxn) revert MintQuantityPerTxnExceeded();
        if (_totalSupply + _quantity > config[_configId].mintConfig.maxSupply) revert MintQuantityExceedsMaxSupply();
    }

    /**
    * @dev see {IAdmin-revertOnArbitraryAllocationCheckFailure}
    */
    function revertOnArbitraryAllocationCheckFailure(address _address, uint256 _quantity, bytes32[] memory _proof, uint256 _allowlistID, uint256 _allowed) external view {
        _revertOnArbitraryAllocationCheckFailure(_address, _quantity, _proof, _allowlistID, _allowed);
    }

    /**
    * @dev see {IAdmin-revertOnMintCheckFailure}
    */
    function _revertOnArbitraryAllocationCheckFailure(
        address _address,
        uint256 _quantity,
        bytes32[] memory _proof,
        uint256 _allowlistID,
        uint256 _allowed
    ) internal view {
        if (_quantity > _allowed) revert ArbitraryAllocationExceeded();
        //if allowlist exists, does merkle proof validate
         IAllowlist.Allowlist memory allowlist = IAllowlist(extensions[IConfig.Extensions.Allowlist]).getAllowlist(_allowlistID);
         if(allowlist.isActive){
             if (!IAllowlist(extensions[IConfig.Extensions.Allowlist]).isAllowedArbitrary(_address, _proof, allowlist, _allowed)) revert ArbitraryAllocationVerificationError();
         }
        
    }

    /**
    * @dev see {IAdmin-revertOnTotalAllocationCheckFailure}
    */
    function revertOnTotalAllocationCheckFailure(uint256 _totalMinted, uint256 _quantity, uint256 _allowed) external view {
        if(_totalMinted + _quantity > _allowed) revert ArbitraryTotalAllocationExceeded();
    }

    /**
    * @dev see {IAdmin-revertOnMaxWalletMintCheckFailure}
    */
    function revertOnMaxWalletMintCheckFailure(uint256 _configId, uint256 _quantity, uint256 _totalMinted) external view {
        if (_totalMinted + _quantity > config[_configId].mintConfig.maxPerWallet) revert MintQuantityPerWalletExceeded();
    }

    /**
    * @dev see {IAdmin-revertOnPaymentFailure}
    */
    function _revertOnPaymentFailure(
        uint256 _configId,
        uint256 _price,
        uint256 _quantity,
        uint256 _payment,
        bool _override
    ) internal view {
        if (config.length == 0) revert ConfigNotFound(_configId);
        if (!(config.length > _configId)) revert ConfigNotFound(_configId);
        // use _price instead of mintConfig.price if _override
        if (_override) {
            if (_payment < (_price * _quantity)) revert InsufficientFunds();
            if (_payment > (_price * _quantity)) revert ExcessiveFunds();
        } else {
            if (_payment < (config[_configId].mintConfig.price * _quantity)) revert InsufficientFunds();
            if (_payment > (config[_configId].mintConfig.price * _quantity)) revert ExcessiveFunds();
        }
    }

}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

/// @author: @props

import "@openzeppelin/contracts/utils/introspection/IERC165.sol";

/**
 * @dev 
 */
interface IAllowlist is IERC165 {

    /**
     * @dev address was not found on any allowlists
     */
    error AddressNotFound(address);

    /**
     * @dev allowlist does not exist
     */
    error AllowlistNotFound();

    /**
     * @dev proof array contains duplicate proofs
     */
    error DuplicateProofs();

    /**
     * @dev no allowlists exist in the contract
     */
    error NoAllowlistsFound();

    /**
     * @dev contract address is not an ERC721 or ERC1155 contract
     */
    error TypeAddressInvalid(bytes32);

    event AllowlistCreated(uint256);
    event AllowlistUpdated(uint256);

    /**
    * @dev 
    */
    enum Type {
        Merkle,
        ERC721,
        ERC1155
    }

    /**
    * @dev 
    */
    struct Allowlist {
        Type type_;
        bool isActive;
        string name;
        string source;
        string ipfsMetadataHash;
        uint256[] tokenTypeIds;
        bytes32 typedata;
        bool hasArbitraryAllocation;
    }

    /**
    * @dev 
    */
    function createAllowlist(Allowlist memory _allowlist) external;

    /**
    * @dev 
    */
    function updateAllowlist(uint256 _allowlistId, Allowlist memory _allowlist) external;

    /**
    * @dev get an individual allowlist by id
    */
    function getAllowlist(uint256 _allowlistId) external view returns (Allowlist memory);

    /**
    * @dev get all allowlists
    */
    function getAllowlists() external view returns (Allowlist[] memory);

    /**
    * @dev verifies that address is present on at least one allowlist
    */
    function isAllowed(address _address, bytes32[][] memory _proofs) external view returns (bool);

    /**
    * @dev verifies that address is present on at least one allowlist with arbitrary allocation via merkle tree | @bitcoinski
    */
    function isAllowedArbitrary(address _address, bytes32[] memory _proof, IAllowlist.Allowlist memory _allowlist, uint256 _quantity) external view returns (bool);

    /**
    * @dev verifies that address is present on all allowlists 
    */
    function isAllowedAll(address _address, bytes32[][] memory _proofs) external view returns (bool);

    /**
    * @dev verifies that address is present on at least specific number of allowlists 
    */
    function isAllowedAtLeast(address _address, bytes32[][] memory _proofs, uint256 _quantity) external view returns (bool);

    /**
    * @dev verifies that address is present on a specific allowlist 
    */
    function isAllowedOn(uint256 _allowlistId, address _address, bytes32[][] memory _proofs) external view returns (bool);

}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

/// @author: @props

import "@openzeppelin/contracts/utils/introspection/IERC165.sol";

/**
 * @dev 
 */
interface IRoyalty is IERC165 {

    /**
    * @dev add share to royalty contract for address
    */
    function addShare(address _account) external;

    /**
    * @dev remove share from royalty contract for address
    */
    function removeShare(address _account) external;

}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

/// @author: @props

import "@openzeppelin/contracts/access/AccessControl.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/utils/introspection/ERC165.sol";

/**
 * @dev base contract that includes functionality common to all contracts 
 */
contract Base is
    ERC165,
    AccessControl,
    Ownable,
    ReentrancyGuard {

    constructor ()  {
        // owner is the only address permitted hold DEFAULT_ADMIN_ROLE and manage access for this contract
        _grantRole(DEFAULT_ADMIN_ROLE, owner());
        // owner is also CONTRACT_ADMIN_ROLE by default (revocable)
        _grantRole(CONTRACT_ADMIN_ROLE, owner());
    }

    // no account other than owner is permitted to have DEFAULT_ADMIN_ROLE
    error DefaultAdminRoleNotPermitted();
    // revokeRole may not be called on owner's address for DEFAULT_ADMIN_ROLE
    error OwnerAdminRoleIrrevocable();
    // renouncing owner roles is not allowed because we have explicitly disabled it
    error OwnerAdminRoleUnrenounceable();
    
    bytes32 public constant CONTRACT_ADMIN_ROLE = keccak256("CONTRACT_ADMIN_ROLE");

    /**
     * @dev see {IERC165-supportsInterface}
     */
    function supportsInterface(bytes4 interfaceId) public view virtual override(AccessControl, ERC165) returns (bool) {
        return interfaceId == type(IAccessControl).interfaceId || super.supportsInterface(interfaceId);
    }

    /**
     * @dev overrides AccessControl.grantRole function
     */
    function grantRole(bytes32 role, address account) public virtual override onlyRole(DEFAULT_ADMIN_ROLE) {
        // no account other than owner is permitted to have DEFAULT_ADMIN_ROLE
        if(role == DEFAULT_ADMIN_ROLE) revert DefaultAdminRoleNotPermitted();
        _grantRole(role, account);
    }

    /**
     * @dev overrides AccessControl.renounceRole function
     */
    function renounceRole(bytes32 role, address account) public virtual override onlyRole(DEFAULT_ADMIN_ROLE) {
        // owner must always have DEFAULT_ADMIN_ROLE
        if(role == DEFAULT_ADMIN_ROLE && account == owner()) revert OwnerAdminRoleUnrenounceable();
        _revokeRole(role, account);
    }

    /**
     * @dev overrides AccessControl.revokeRole function
     */
    function revokeRole(bytes32 role, address account) public virtual override onlyRole(DEFAULT_ADMIN_ROLE) {
        // owner must always have DEFAULT_ADMIN_ROLE
        if(role == DEFAULT_ADMIN_ROLE && account == owner()) revert OwnerAdminRoleIrrevocable();
        _revokeRole(role, account);
    }

}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

/// @author: @props

import "@openzeppelin/contracts/utils/introspection/IERC165.sol";
import "../extensions/IAllowlist.sol";
import "./IConfig.sol";

/**
 * @dev 
 */
interface IAdmin is IERC165 {

    error AllocationExceeded();
    error ArbitraryAllocationExceeded();
    error ArbitraryTotalAllocationExceeded();
    error ArbitraryAllocationVerificationError();
    error ConfigNotFound(uint256);
    error ExcessiveFunds();
    error ExtensionInvalid();
    error InsufficientFunds();
    error MintClosed();
    error MintQuantityInvalid();
    error MintQuantityPerTxnExceeded();
    error MintQuantityPerWalletExceeded();
    error MintInactive();
    error MintNotStarted();
    error MintPaused();
    error MintProofInvalid();
    error MintQuantityExceedsMaxSupply();
    error PricelistNotFound(uint256);

    /**
    * @dev
    */
    struct Allocation {
        uint256 allowlistId;
        uint256 allocation;
        uint256 price;
    }

    /**
    * @dev creates a configuration
    */
    function createConfig(IConfig.Config memory _config) external;

    /**
    * @dev updates a configuration
    */
    function updateConfig(uint256 _configId, IConfig.Config memory _config) external;

    /**
    * @dev gets allocation data structure by address
    */
    function getAllocationByAddress(address _address, bytes32[][] memory _proofs) external view returns (Allocation memory);

    /**
    * @dev gets total allocation for an address
    */
    function getAllocationTotalByAddress(address _address, bytes32[][] memory _proofs) external view returns (uint256);

    /**
    * @dev sets allocations for an allowlist
    */
    function setAllocation(uint256 _allowlistId, uint256 _allocation) external;

    /**
    * @dev sets contract URI
    */
    function setContractURI(string memory _contractURI) external;

    /**
    * @dev gets contract URI
    */
    function getContractURI() external view returns (string memory);

    /**
    * @dev sets extension addresses
    */
    function setExtension(IConfig.Extensions _extension, address _address) external;

    /**
    * @dev creates a pricelist
    */
    function createPricelist(IConfig.Pricelist memory _pricelist) external;

    /**
    * @dev updates a pricelist
    */
    function updatePricelist(uint256 _pricelistId, IConfig.Pricelist memory _pricelist) external;

    /**
    * @dev gets pricelist by allowlist id
    */
    function getPricelistByAllowlistId(uint256 _allowlistId) external view returns (IConfig.Pricelist memory);

    /**
    * @dev sets split contract address
    */
    function setSplitContract(address payable _address) external;

    /**
    * @dev gets split contract address
    */
    function getSplitContract() external view returns (address payable);

    /**
    * @dev creates an allowlist
    */
    function createAllowlist(IAllowlist.Allowlist memory _allowlist) external;

    /**
    * @dev updates an allowlist
    */
    function updateAllowlist(uint256 _allowlistId, IAllowlist.Allowlist memory _allowlist) external;

    /**
    * @dev adds share to royalty contract for an account
    */
    function addRoyaltyShare(address _account) external;

    /**
    * @dev removes share from royalty contract for an account
    */
    function removeRoyaltyShare(address _account) external;

    /**
    * @dev reverts transaction if allocation check fails
    */
    function revertOnAllocationCheckFailure(address _address, bytes32[][] memory _proofs, uint256 _quantity) external returns (Allocation memory);

    /**
    * @dev reverts transaction if allocation check fails
    */
    function revertOnArbitraryAllocationCheckFailure(address _address, uint256 _quantity, bytes32[] memory _proof, uint256 _allowlistID, uint256 _allowed) external;

    /**
    * @dev reverts transaction if allocation check fails
    */
    function revertOnTotalAllocationCheckFailure(uint256 _totalMinted, uint256 _quantity, uint256 _allowed) external;

    /**
    * @dev reverts transaction if max per wallet check fails
    */
    function revertOnMaxWalletMintCheckFailure(uint256 _configId, uint256 _quantity, uint256 _totalMinted) external;

    /**
    * @dev reverts transaction if pre-defined mint config checks fail to pass
    */
    function revertOnMintCheckFailure(uint256 _configId, uint256 _quantity, uint256 _totalSupply, bool _paused) external;

    /**
    * @dev reverts transaction if payment doesn't meet required parameters
    */
    function revertOnPaymentFailure(uint256 _configId, uint256 _price, uint256 _quantity, uint256 _payment, bool _override) external;

    /**
    * @dev reverts transaction if payment doesn't meet required parameters
    */
    function revertOnArbitraryPaymentFailure(uint256 _price, uint256 _payment) external;

}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

/// @author: @props

/**
 * @dev 
 */
interface IConfig {

    /**
    * @dev 
    */
    enum Extensions {
        Allowlist,
        Royalty,
        Split
    }

    /**
    * @dev 
    */
    struct Config {
        Mint mintConfig; 
        Token tokenConfig;
    }

    /**
    * @dev 
    */
    struct Mint {
        bool isActive;
        uint256 startTime;
        uint256 endTime;
        uint256 maxSupply;
        uint256 maxPerWallet;
        uint256 maxPerTxn;
        uint256 price;
    }

    /**
    * @dev
    */
    struct Pricelist {
        uint256 allowlistId;
        uint256 price;
    }

    /**
    * @dev 
    */
    struct Token {
        string ipfsMetadataHash;
    }

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

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.5.0) (access/AccessControl.sol)

pragma solidity ^0.8.0;

import "./IAccessControl.sol";
import "../utils/Context.sol";
import "../utils/Strings.sol";
import "../utils/introspection/ERC165.sol";

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
abstract contract AccessControl is Context, IAccessControl, ERC165 {
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
        return interfaceId == type(IAccessControl).interfaceId || super.supportsInterface(interfaceId);
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
                        Strings.toHexString(uint160(account), 20),
                        " is missing role ",
                        Strings.toHexString(uint256(role), 32)
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
// OpenZeppelin Contracts v4.4.1 (security/ReentrancyGuard.sol)

pragma solidity ^0.8.0;

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
abstract contract ReentrancyGuard {
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

    constructor() {
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