// SPDX-License-Identifier: MIT
pragma solidity 0.8.19;

import {Initializable} from "openzeppelin-upgradeable/proxy/utils/Initializable.sol";
import {
    ERC1155Upgradeable,
    IERC1155Upgradeable,
    ERC165Upgradeable
} from "openzeppelin-upgradeable/token/ERC1155/ERC1155Upgradeable.sol";
import {EIP2981TLUpgradeable} from "tl-sol-tools/upgradeable/royalties/EIP2981TLUpgradeable.sol";
import {OwnableAccessControlUpgradeable} from "tl-sol-tools/upgradeable/access/OwnableAccessControlUpgradeable.sol";
import {StoryContractUpgradeable} from "tl-story/upgradeable/StoryContractUpgradeable.sol";
import {BlockListUpgradeable} from "tl-blocklist/BlockListUpgradeable.sol";

/*//////////////////////////////////////////////////////////////////////////
                            Custom Errors
//////////////////////////////////////////////////////////////////////////*/

/// @dev token uri is an empty string
error EmptyTokenURI();

/// @dev batch size too small
error BatchSizeTooSmall();

/// @dev mint to zero addresses
error MintToZeroAddresses();

/// @dev array length mismatch
error ArrayLengthMismatch();

/// @dev token not owned by the owner of the contract
error TokenNotOwnedByOwner();

/// @dev caller is not approved or owner
error CallerNotApprovedOrOwner();

/// @dev token does not exist
error TokenDoesntExist();

/// @dev burning zero tokens
error BurnZeroTokens();

/*//////////////////////////////////////////////////////////////////////////
                            ERC1155TL
//////////////////////////////////////////////////////////////////////////*/

/// @title ERC1155TL.sol
/// @notice Transient Labs ERC-1155 Creator Contract
/// @dev features include
///      - batch minting
///      - airdrops
///      - ability to hook in external mint contracts
///      - ability to set multiple admins
///      - Story Contract
///      - BlockList
///      - individual token royalties
/// @author transientlabs.xyz
/// @custom:version 2.3.0
contract ERC1155TL is
    ERC1155Upgradeable,
    EIP2981TLUpgradeable,
    OwnableAccessControlUpgradeable,
    StoryContractUpgradeable,
    BlockListUpgradeable
{
    /*//////////////////////////////////////////////////////////////////////////
                                Custom Types
    //////////////////////////////////////////////////////////////////////////*/

    /// @dev struct defining a token
    struct Token {
        bool created;
        string uri;
    }

    /*//////////////////////////////////////////////////////////////////////////
                                State Variables
    //////////////////////////////////////////////////////////////////////////*/

    string public constant VERSION = "2.3.0";
    bytes32 public constant ADMIN_ROLE = keccak256("ADMIN_ROLE");
    bytes32 public constant APPROVED_MINT_CONTRACT = keccak256("APPROVED_MINT_CONTRACT");
    uint256 private _counter;
    string public name;
    string public symbol;
    mapping(uint256 => Token) private _tokens;

    /*//////////////////////////////////////////////////////////////////////////
                                Constructor
    //////////////////////////////////////////////////////////////////////////*/

    /// @param disable: boolean to disable initialization for the implementation contract
    constructor(bool disable) {
        if (disable) _disableInitializers();
    }

    /*//////////////////////////////////////////////////////////////////////////
                                Initializer
    //////////////////////////////////////////////////////////////////////////*/

    /// @param name_: the name of the 1155 contract
    /// @param symbol_: the symbol for the 1155 contract
    /// @param defaultRoyaltyRecipient: the default address for royalty payments
    /// @param defaultRoyaltyPercentage: the default royalty percentage of basis points (out of 10,000)
    /// @param initOwner: the owner of the contract
    /// @param admins: array of admin addresses to add to the contract
    /// @param enableStory: a bool deciding whether to add story fuctionality or not
    /// @param blockListRegistry: address of the blocklist registry to use
    function initialize(
        string memory name_,
        string memory symbol_,
        address defaultRoyaltyRecipient,
        uint256 defaultRoyaltyPercentage,
        address initOwner,
        address[] memory admins,
        bool enableStory,
        address blockListRegistry
    ) external initializer {
        // initialize parent contracts
        __ERC1155_init("");
        __EIP2981TL_init(defaultRoyaltyRecipient, defaultRoyaltyPercentage);
        __OwnableAccessControl_init(initOwner);
        __StoryContractUpgradeable_init(enableStory);
        __BlockList_init(blockListRegistry);

        // add admins
        _setRole(ADMIN_ROLE, admins, true);

        // set name & symbol
        name = name_;
        symbol = symbol_;
    }

    /*//////////////////////////////////////////////////////////////////////////
                                General Functions
    //////////////////////////////////////////////////////////////////////////*/

    /// @notice function to get token creation details
    /// @param tokenId: the token to lookup
    function getTokenDetails(uint256 tokenId) external view returns (Token memory) {
        return _tokens[tokenId];
    }

    /*//////////////////////////////////////////////////////////////////////////
                                Access Control Functions
    //////////////////////////////////////////////////////////////////////////*/

    /// @notice function to set approved mint contracts
    /// @dev access to owner or admin
    /// @param minters: array of minters to grant approval to
    /// @param status: status for the minters
    function setApprovedMintContracts(address[] calldata minters, bool status) external onlyRoleOrOwner(ADMIN_ROLE) {
        _setRole(APPROVED_MINT_CONTRACT, minters, status);
    }

    /*//////////////////////////////////////////////////////////////////////////
                                Creation Functions
    //////////////////////////////////////////////////////////////////////////*/

    /// @notice function to create a token that can be minted to creator or airdropped
    /// @dev requires owner or admin
    /// @param newUri: the uri for the token to create
    /// @param addresses: the addresses to mint the new token to
    /// @param amounts: the amount of the new token to mint to each address
    function createToken(string calldata newUri, address[] calldata addresses, uint256[] calldata amounts)
        external
        onlyRoleOrOwner(ADMIN_ROLE)
    {
        _createToken(newUri, addresses, amounts);
    }

    /// @notice function to create a token that can be minted to creator or airdropped
    /// @dev overloaded function where you can set the token royalty config in this tx
    /// @dev requires owner or admin
    /// @param newUri: the uri for the token to create
    /// @param addresses: the addresses to mint the new token to
    /// @param amounts: the amount of the new token to mint to each address
    /// @param royaltyAddress: royalty payout address for the created token
    /// @param royaltyPercent: royalty percentage for this token
    function createToken(
        string calldata newUri,
        address[] calldata addresses,
        uint256[] calldata amounts,
        address royaltyAddress,
        uint256 royaltyPercent
    ) external onlyRoleOrOwner(ADMIN_ROLE) {
        uint256 tokenId = _createToken(newUri, addresses, amounts);
        _overrideTokenRoyaltyInfo(tokenId, royaltyAddress, royaltyPercent);
    }

    /// @notice function to batch create tokens that can be minted to creator or airdropped
    /// @dev requires owner or admin
    /// @param newUris: the uris for the tokens to create
    /// @param addresses: 2d dynamic array holding the addresses to mint the new tokens to
    /// @param amounts: 2d dynamic array holding the amounts of the new tokens to mint to each address
    function batchCreateToken(string[] calldata newUris, address[][] calldata addresses, uint256[][] calldata amounts)
        external
        onlyRoleOrOwner(ADMIN_ROLE)
    {
        if (newUris.length == 0) revert EmptyTokenURI();
        for (uint256 i = 0; i < newUris.length; i++) {
            _createToken(newUris[i], addresses[i], amounts[i]);
        }
    }

    /// @notice function to batch create tokens that can be minted to creator or airdropped
    /// @dev overloaded function where you can set the token royalty config in this tx
    /// @dev requires owner or admin
    /// @param newUris: the uris for the tokens to create
    /// @param addresses: 2d dynamic array holding the addresses to mint the new tokens to
    /// @param amounts: 2d dynamic array holding the amounts of the new tokens to mint to each address
    /// @param royaltyAddresses: royalty payout addresses for the tokens
    /// @param royaltyPercents: royalty payout percents for the tokens
    function batchCreateToken(
        string[] calldata newUris,
        address[][] calldata addresses,
        uint256[][] calldata amounts,
        address[] calldata royaltyAddresses,
        uint256[] calldata royaltyPercents
    ) external onlyRoleOrOwner(ADMIN_ROLE) {
        if (newUris.length == 0) revert EmptyTokenURI();
        for (uint256 i = 0; i < newUris.length; i++) {
            uint256 tokenId = _createToken(newUris[i], addresses[i], amounts[i]);
            _overrideTokenRoyaltyInfo(tokenId, royaltyAddresses[i], royaltyPercents[i]);
        }
    }

    /// @notice private helper function to create a new token
    /// @param newUri: the uri for the token to create
    /// @param addresses: the addresses to mint the new token to
    /// @param amounts: the amount of the new token to mint to each address
    /// @return _counter: token id created
    function _createToken(string memory newUri, address[] memory addresses, uint256[] memory amounts)
        private
        returns (uint256)
    {
        if (bytes(newUri).length == 0) revert EmptyTokenURI();
        if (addresses.length == 0) revert MintToZeroAddresses();
        if (addresses.length != amounts.length) revert ArrayLengthMismatch();
        _counter++;
        _tokens[_counter] = Token(true, newUri);
        for (uint256 i = 0; i < addresses.length; i++) {
            _mint(addresses[i], _counter, amounts[i], "");
        }

        return _counter;
    }

    /// @notice private helper function to verify a token exists
    /// @param tokenId: the token to check existence for
    function _exists(uint256 tokenId) private view returns (bool) {
        return _tokens[tokenId].created;
    }

    /*//////////////////////////////////////////////////////////////////////////
                                Mint Functions
    //////////////////////////////////////////////////////////////////////////*/

    /// @notice function to mint existing token to recipients
    /// @dev requires owner or admin
    /// @param tokenId: the token to mint
    /// @param addresses: the addresses to mint to
    /// @param amounts: amounts of the token to mint to each address
    function mintToken(uint256 tokenId, address[] calldata addresses, uint256[] calldata amounts)
        external
        onlyRoleOrOwner(ADMIN_ROLE)
    {
        _mintToken(tokenId, addresses, amounts);
    }

    /// @notice external mint function
    /// @dev requires caller to be an approved mint contract
    /// @param tokenId: the token to mint
    /// @param addresses: the addresses to mint to
    /// @param amounts: amounts of the token to mint to each address
    function externalMint(uint256 tokenId, address[] calldata addresses, uint256[] calldata amounts)
        external
        onlyRole(APPROVED_MINT_CONTRACT)
    {
        _mintToken(tokenId, addresses, amounts);
    }

    /// @notice private helper function
    /// @param tokenId: the token to mint
    /// @param addresses: the addresses to mint to
    /// @param amounts: amounts of the token to mint to each address
    function _mintToken(uint256 tokenId, address[] calldata addresses, uint256[] calldata amounts) private {
        if (!_exists(tokenId)) revert TokenDoesntExist();
        if (addresses.length == 0) revert MintToZeroAddresses();
        if (addresses.length != amounts.length) revert ArrayLengthMismatch();
        for (uint256 i = 0; i < addresses.length; i++) {
            _mint(addresses[i], tokenId, amounts[i], "");
        }
    }

    /*//////////////////////////////////////////////////////////////////////////
                                Burn Functions
    //////////////////////////////////////////////////////////////////////////*/

    /// @notice function to burn tokens from an account
    /// @dev msg.sender must be owner or operator
    /// @dev if this function is called from another contract as part of a burn/redeem,
    ///      the contract must ensure that no amount is '0' or if it is, that it isn't a vulnerability.
    /// @param from: address to burn from
    /// @param tokenIds: array of tokens to burn
    /// @param amounts: amount of each token to burn
    function burn(address from, uint256[] calldata tokenIds, uint256[] calldata amounts) external {
        if (tokenIds.length == 0) revert BurnZeroTokens();
        if (msg.sender != from && !isApprovedForAll(from, msg.sender)) revert CallerNotApprovedOrOwner();
        _burnBatch(from, tokenIds, amounts);
    }

    /*//////////////////////////////////////////////////////////////////////////
                                Royalty Functions
    //////////////////////////////////////////////////////////////////////////*/

    /// @notice function to set the default royalty specification
    /// @dev requires owner
    /// @param newRecipient: the new royalty payout address
    /// @param newPercentage: the new royalty percentage in basis (out of 10,000)
    function setDefaultRoyalty(address newRecipient, uint256 newPercentage) external onlyOwner {
        _setDefaultRoyaltyInfo(newRecipient, newPercentage);
    }

    /// @notice function to override a token's royalty info
    /// @dev requires owner
    /// @param tokenId: the token to override royalty for
    /// @param newRecipient: the new royalty payout address for the token id
    /// @param newPercentage: the new royalty percentage in basis (out of 10,000) for the token id
    function setTokenRoyalty(uint256 tokenId, address newRecipient, uint256 newPercentage) external onlyOwner {
        _overrideTokenRoyaltyInfo(tokenId, newRecipient, newPercentage);
    }

    /*//////////////////////////////////////////////////////////////////////////
                                Token Uri Functions
    //////////////////////////////////////////////////////////////////////////*/

    /// @notice function to set token Uri for a token
    /// @dev requires owner or admin
    /// @param tokenId: token to set a uri for
    /// @param newUri: the new uri for the token
    function setTokenUri(uint256 tokenId, string calldata newUri) external onlyRoleOrOwner(ADMIN_ROLE) {
        if (!_exists(tokenId)) revert TokenDoesntExist();
        if (bytes(newUri).length == 0) revert EmptyTokenURI();
        _tokens[tokenId].uri = newUri;
        emit IERC1155Upgradeable.URI(newUri, tokenId);
    }

    /// @notice function for token uris
    /// @param tokenId: token for which to get the uri
    function uri(uint256 tokenId) public view override(ERC1155Upgradeable) returns (string memory) {
        if (!_exists(tokenId)) revert TokenDoesntExist();
        return _tokens[tokenId].uri;
    }

    /*//////////////////////////////////////////////////////////////////////////
                                Story Contract Hooks
    //////////////////////////////////////////////////////////////////////////*/

    /// @inheritdoc StoryContractUpgradeable
    /// @dev restricted to the owner of the contract
    function _isStoryAdmin(address potentialAdmin) internal view override(StoryContractUpgradeable) returns (bool) {
        return potentialAdmin == owner() || hasRole(ADMIN_ROLE, potentialAdmin);
    }

    /// @inheritdoc StoryContractUpgradeable
    function _tokenExists(uint256 tokenId) internal view override(StoryContractUpgradeable) returns (bool) {
        return _exists(tokenId);
    }

    /// @inheritdoc StoryContractUpgradeable
    function _isTokenOwner(address potentialOwner, uint256 tokenId)
        internal
        view
        override(StoryContractUpgradeable)
        returns (bool)
    {
        return balanceOf(potentialOwner, tokenId) > 0;
    }

    /// @inheritdoc StoryContractUpgradeable
    /// @dev restricted to the owner of the contract
    function _isCreator(address potentialCreator, uint256 /* tokenId */ )
        internal
        view
        override(StoryContractUpgradeable)
        returns (bool)
    {
        return potentialCreator == owner() || hasRole(ADMIN_ROLE, potentialCreator);
    }

    /*//////////////////////////////////////////////////////////////////////////
                                BlockList Functions
    //////////////////////////////////////////////////////////////////////////*/

    /// @inheritdoc BlockListUpgradeable
    /// @dev restricted to the owner of the contract
    function isBlockListAdmin(address potentialAdmin) public view override(BlockListUpgradeable) returns (bool) {
        return potentialAdmin == owner();
    }

    /// @inheritdoc ERC1155Upgradeable
    /// @dev added the `notBlocked` modifier for blocklist
    function setApprovalForAll(address operator, bool approved)
        public
        override(ERC1155Upgradeable)
        notBlocked(operator)
    {
        ERC1155Upgradeable.setApprovalForAll(operator, approved);
    }

    /*//////////////////////////////////////////////////////////////////////////
                                ERC-165 Support
    //////////////////////////////////////////////////////////////////////////*/

    /// @inheritdoc ERC165Upgradeable
    function supportsInterface(bytes4 interfaceId)
        public
        view
        override(ERC1155Upgradeable, EIP2981TLUpgradeable, StoryContractUpgradeable)
        returns (bool)
    {
        return (
            ERC1155Upgradeable.supportsInterface(interfaceId) || EIP2981TLUpgradeable.supportsInterface(interfaceId)
                || StoryContractUpgradeable.supportsInterface(interfaceId)
        );
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.8.1) (proxy/utils/Initializable.sol)

pragma solidity ^0.8.2;

import "../../utils/AddressUpgradeable.sol";

/**
 * @dev This is a base contract to aid in writing upgradeable contracts, or any kind of contract that will be deployed
 * behind a proxy. Since proxied contracts do not make use of a constructor, it's common to move constructor logic to an
 * external initializer function, usually called `initialize`. It then becomes necessary to protect this initializer
 * function so it can only be called once. The {initializer} modifier provided by this contract will have this effect.
 *
 * The initialization functions use a version number. Once a version number is used, it is consumed and cannot be
 * reused. This mechanism prevents re-execution of each "step" but allows the creation of new initialization steps in
 * case an upgrade adds a module that needs to be initialized.
 *
 * For example:
 *
 * [.hljs-theme-light.nopadding]
 * ```
 * contract MyToken is ERC20Upgradeable {
 *     function initialize() initializer public {
 *         __ERC20_init("MyToken", "MTK");
 *     }
 * }
 * contract MyTokenV2 is MyToken, ERC20PermitUpgradeable {
 *     function initializeV2() reinitializer(2) public {
 *         __ERC20Permit_init("MyToken");
 *     }
 * }
 * ```
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
 * contract, which may impact the proxy. To prevent the implementation contract from being used, you should invoke
 * the {_disableInitializers} function in the constructor to automatically lock it when it is deployed:
 *
 * [.hljs-theme-light.nopadding]
 * ```
 * /// @custom:oz-upgrades-unsafe-allow constructor
 * constructor() {
 *     _disableInitializers();
 * }
 * ```
 * ====
 */
abstract contract Initializable {
    /**
     * @dev Indicates that the contract has been initialized.
     * @custom:oz-retyped-from bool
     */
    uint8 private _initialized;

    /**
     * @dev Indicates that the contract is in the process of being initialized.
     */
    bool private _initializing;

    /**
     * @dev Triggered when the contract has been initialized or reinitialized.
     */
    event Initialized(uint8 version);

    /**
     * @dev A modifier that defines a protected initializer function that can be invoked at most once. In its scope,
     * `onlyInitializing` functions can be used to initialize parent contracts.
     *
     * Similar to `reinitializer(1)`, except that functions marked with `initializer` can be nested in the context of a
     * constructor.
     *
     * Emits an {Initialized} event.
     */
    modifier initializer() {
        bool isTopLevelCall = !_initializing;
        require(
            (isTopLevelCall && _initialized < 1) || (!AddressUpgradeable.isContract(address(this)) && _initialized == 1),
            "Initializable: contract is already initialized"
        );
        _initialized = 1;
        if (isTopLevelCall) {
            _initializing = true;
        }
        _;
        if (isTopLevelCall) {
            _initializing = false;
            emit Initialized(1);
        }
    }

    /**
     * @dev A modifier that defines a protected reinitializer function that can be invoked at most once, and only if the
     * contract hasn't been initialized to a greater version before. In its scope, `onlyInitializing` functions can be
     * used to initialize parent contracts.
     *
     * A reinitializer may be used after the original initialization step. This is essential to configure modules that
     * are added through upgrades and that require initialization.
     *
     * When `version` is 1, this modifier is similar to `initializer`, except that functions marked with `reinitializer`
     * cannot be nested. If one is invoked in the context of another, execution will revert.
     *
     * Note that versions can jump in increments greater than 1; this implies that if multiple reinitializers coexist in
     * a contract, executing them in the right order is up to the developer or operator.
     *
     * WARNING: setting the version to 255 will prevent any future reinitialization.
     *
     * Emits an {Initialized} event.
     */
    modifier reinitializer(uint8 version) {
        require(!_initializing && _initialized < version, "Initializable: contract is already initialized");
        _initialized = version;
        _initializing = true;
        _;
        _initializing = false;
        emit Initialized(version);
    }

    /**
     * @dev Modifier to protect an initialization function so that it can only be invoked by functions with the
     * {initializer} and {reinitializer} modifiers, directly or indirectly.
     */
    modifier onlyInitializing() {
        require(_initializing, "Initializable: contract is not initializing");
        _;
    }

    /**
     * @dev Locks the contract, preventing any future reinitialization. This cannot be part of an initializer call.
     * Calling this in the constructor of a contract will prevent that contract from being initialized or reinitialized
     * to any version. It is recommended to use this to lock implementation contracts that are designed to be called
     * through proxies.
     *
     * Emits an {Initialized} event the first time it is successfully executed.
     */
    function _disableInitializers() internal virtual {
        require(!_initializing, "Initializable: contract is initializing");
        if (_initialized < type(uint8).max) {
            _initialized = type(uint8).max;
            emit Initialized(type(uint8).max);
        }
    }

    /**
     * @dev Returns the highest version that has been initialized. See {reinitializer}.
     */
    function _getInitializedVersion() internal view returns (uint8) {
        return _initialized;
    }

    /**
     * @dev Returns `true` if the contract is currently initializing. See {onlyInitializing}.
     */
    function _isInitializing() internal view returns (bool) {
        return _initializing;
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.8.0) (token/ERC1155/ERC1155.sol)

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
        require(account != address(0), "ERC1155: address zero is not a valid owner");
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
            "ERC1155: caller is not token owner or approved"
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
            "ERC1155: caller is not token owner or approved"
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
        uint256[] memory ids = _asSingletonArray(id);
        uint256[] memory amounts = _asSingletonArray(amount);

        _beforeTokenTransfer(operator, from, to, ids, amounts, data);

        uint256 fromBalance = _balances[id][from];
        require(fromBalance >= amount, "ERC1155: insufficient balance for transfer");
        unchecked {
            _balances[id][from] = fromBalance - amount;
        }
        _balances[id][to] += amount;

        emit TransferSingle(operator, from, to, id, amount);

        _afterTokenTransfer(operator, from, to, ids, amounts, data);

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

        _afterTokenTransfer(operator, from, to, ids, amounts, data);

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
        uint256[] memory ids = _asSingletonArray(id);
        uint256[] memory amounts = _asSingletonArray(amount);

        _beforeTokenTransfer(operator, address(0), to, ids, amounts, data);

        _balances[id][to] += amount;
        emit TransferSingle(operator, address(0), to, id, amount);

        _afterTokenTransfer(operator, address(0), to, ids, amounts, data);

        _doSafeTransferAcceptanceCheck(operator, address(0), to, id, amount, data);
    }

    /**
     * @dev xref:ROOT:erc1155.adoc#batch-operations[Batched] version of {_mint}.
     *
     * Emits a {TransferBatch} event.
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

        _afterTokenTransfer(operator, address(0), to, ids, amounts, data);

        _doSafeBatchTransferAcceptanceCheck(operator, address(0), to, ids, amounts, data);
    }

    /**
     * @dev Destroys `amount` tokens of token type `id` from `from`
     *
     * Emits a {TransferSingle} event.
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
        uint256[] memory ids = _asSingletonArray(id);
        uint256[] memory amounts = _asSingletonArray(amount);

        _beforeTokenTransfer(operator, from, address(0), ids, amounts, "");

        uint256 fromBalance = _balances[id][from];
        require(fromBalance >= amount, "ERC1155: burn amount exceeds balance");
        unchecked {
            _balances[id][from] = fromBalance - amount;
        }

        emit TransferSingle(operator, from, address(0), id, amount);

        _afterTokenTransfer(operator, from, address(0), ids, amounts, "");
    }

    /**
     * @dev xref:ROOT:erc1155.adoc#batch-operations[Batched] version of {_burn}.
     *
     * Emits a {TransferBatch} event.
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

        _afterTokenTransfer(operator, from, address(0), ids, amounts, "");
    }

    /**
     * @dev Approve `operator` to operate on all of `owner` tokens
     *
     * Emits an {ApprovalForAll} event.
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
     * transfers, the length of the `ids` and `amounts` arrays will be 1.
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

    /**
     * @dev Hook that is called after any token transfer. This includes minting
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
    function _afterTokenTransfer(
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
                revert("ERC1155: transfer to non-ERC1155Receiver implementer");
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
                revert("ERC1155: transfer to non-ERC1155Receiver implementer");
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

// SPDX-License-Identifier: MIT
pragma solidity 0.8.19;

import {Initializable} from "openzeppelin-upgradeable/proxy/utils/Initializable.sol";
import {ERC165Upgradeable} from "openzeppelin-upgradeable/utils/introspection/ERC165Upgradeable.sol";
import {IEIP2981} from "../../royalties/IEIP2981.sol";

/*//////////////////////////////////////////////////////////////////////////
                            Custom Errors
//////////////////////////////////////////////////////////////////////////*/

/// @dev error if the recipient is set to address(0)
error ZeroAddressError();

/// @dev error if the royalty percentage is greater than to 100%
error MaxRoyaltyError();

/*//////////////////////////////////////////////////////////////////////////
                            EIP2981TL
//////////////////////////////////////////////////////////////////////////*/

/// @title EIP2981TLUpgradeable.sol
/// @notice abstract contract to define a default royalty spec
///         while allowing for specific token overrides
/// @dev follows EIP-2981 (https://eips.ethereum.org/EIPS/eip-2981)
/// @author transientlabs.xyz
/// @custom:version 2.2.0
abstract contract EIP2981TLUpgradeable is IEIP2981, Initializable, ERC165Upgradeable {
    /*//////////////////////////////////////////////////////////////////////////
                                Royalty Struct
    //////////////////////////////////////////////////////////////////////////*/

    struct RoyaltySpec {
        address recipient;
        uint256 percentage;
    }

    /*//////////////////////////////////////////////////////////////////////////
                                State Variables
    //////////////////////////////////////////////////////////////////////////*/

    address private _defaultRecipient;
    uint256 private _defaultPercentage;
    mapping(uint256 => RoyaltySpec) private _tokenOverrides;

    /*//////////////////////////////////////////////////////////////////////////
                                Initializer
    //////////////////////////////////////////////////////////////////////////*/

    /// @notice function to initialize the contract
    /// @param defaultRecipient - the default royalty payout address
    /// @param defaultPercentage - the deafult royalty percentage, out of 10,000
    function __EIP2981TL_init(address defaultRecipient, uint256 defaultPercentage) internal onlyInitializing {
        __EIP2981TL_init_unchained(defaultRecipient, defaultPercentage);
    }

    /// @notice unchained function to initialize the contract
    /// @param defaultRecipient - the default royalty payout address
    /// @param defaultPercentage - the deafult royalty percentage, out of 10,000
    function __EIP2981TL_init_unchained(address defaultRecipient, uint256 defaultPercentage)
        internal
        onlyInitializing
    {
        _setDefaultRoyaltyInfo(defaultRecipient, defaultPercentage);
    }

    /*//////////////////////////////////////////////////////////////////////////
                                Royalty Changing Functions
    //////////////////////////////////////////////////////////////////////////*/

    /// @notice function to set default royalty info
    /// @param newRecipient - the new default royalty payout address
    /// @param newPercentage - the new default royalty percentage, out of 10,000
    function _setDefaultRoyaltyInfo(address newRecipient, uint256 newPercentage) internal {
        if (newRecipient == address(0)) revert ZeroAddressError();
        if (newPercentage > 10_000) revert MaxRoyaltyError();
        _defaultRecipient = newRecipient;
        _defaultPercentage = newPercentage;
    }

    /// @notice function to override royalty spec on a specific token
    /// @param tokenId - the token id to override royalty for
    /// @param newRecipient - the new royalty payout address
    /// @param newPercentage - the new royalty percentage, out of 10,000
    function _overrideTokenRoyaltyInfo(uint256 tokenId, address newRecipient, uint256 newPercentage) internal {
        if (newRecipient == address(0)) revert ZeroAddressError();
        if (newPercentage > 10_000) revert MaxRoyaltyError();
        _tokenOverrides[tokenId].recipient = newRecipient;
        _tokenOverrides[tokenId].percentage = newPercentage;
    }

    /*//////////////////////////////////////////////////////////////////////////
                                Royalty Info
    //////////////////////////////////////////////////////////////////////////*/

    /// @inheritdoc IEIP2981
    function royaltyInfo(uint256 tokenId, uint256 salePrice)
        external
        view
        returns (address receiver, uint256 royaltyAmount)
    {
        address recipient = _defaultRecipient;
        uint256 percentage = _defaultPercentage;
        if (_tokenOverrides[tokenId].recipient != address(0)) {
            recipient = _tokenOverrides[tokenId].recipient;
            percentage = _tokenOverrides[tokenId].percentage;
        }
        return (recipient, salePrice / 10_000 * percentage); // divide first to avoid overflow
    }

    /*//////////////////////////////////////////////////////////////////////////
                                ERC-165 Override
    //////////////////////////////////////////////////////////////////////////*/

    /// @inheritdoc ERC165Upgradeable
    function supportsInterface(bytes4 interfaceId) public view virtual override(ERC165Upgradeable) returns (bool) {
        return interfaceId == type(IEIP2981).interfaceId || ERC165Upgradeable.supportsInterface(interfaceId);
    }

    /*//////////////////////////////////////////////////////////////////////////
                            External View Functions
    //////////////////////////////////////////////////////////////////////////*/

    /// @notice Query the default royalty receiver and percentage.
    /// @return Tuple containing the default royalty recipient and percentage out of 10_000
    function getDefaultRoyaltyRecipientAndPercentage() external view returns (address, uint256) {
        return (_defaultRecipient, _defaultPercentage);
    }

    /*//////////////////////////////////////////////////////////////////////////
                                Upgradeability Gap
    //////////////////////////////////////////////////////////////////////////*/

    /// @dev gap variable - see https://docs.openzeppelin.com/contracts/4.x/upgradeable#storage_gaps
    uint256[50] private _gap;
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.19;

import {Initializable} from "openzeppelin-upgradeable/proxy/utils/Initializable.sol";
import {EnumerableSetUpgradeable} from "openzeppelin-upgradeable/utils/structs/EnumerableSetUpgradeable.sol";
import {OwnableUpgradeable} from "openzeppelin-upgradeable/access/OwnableUpgradeable.sol";

/*//////////////////////////////////////////////////////////////////////////
                            Custom Errors
//////////////////////////////////////////////////////////////////////////*/

/// @dev does not have specified role
error NotSpecifiedRole(bytes32 role);

/// @dev is not specified role or owner
error NotRoleOrOwner(bytes32 role);

/*//////////////////////////////////////////////////////////////////////////
                        OwnableAccessControlUpgradeable
//////////////////////////////////////////////////////////////////////////*/

/// @title OwnableAccessControl.sol
/// @notice single owner, flexible access control mechanics
/// @dev can easily be extended by inheriting and applying additional roles
/// @dev by default, only the owner can grant roles but by inheriting, but you
///      may allow other roles to grant roles by using the internal helper.
/// @author transientlabs.xyz
/// @custom:version 2.2.0
abstract contract OwnableAccessControlUpgradeable is Initializable, OwnableUpgradeable {
    /*//////////////////////////////////////////////////////////////////////////
                                State Variables
    //////////////////////////////////////////////////////////////////////////*/

    using EnumerableSetUpgradeable for EnumerableSetUpgradeable.AddressSet;

    uint256 private _c; // counter to be able to revoke all priviledges
    mapping(uint256 => mapping(bytes32 => mapping(address => bool))) private _roleStatus;
    mapping(uint256 => mapping(bytes32 => EnumerableSetUpgradeable.AddressSet)) private _roleMembers;

    /*//////////////////////////////////////////////////////////////////////////
                                Events
    //////////////////////////////////////////////////////////////////////////*/

    /// @param from - address that authorized the role change
    /// @param user - the address who's role has been changed
    /// @param approved - boolean indicating the user's status in role
    /// @param role - the bytes32 role created in the inheriting contract
    event RoleChange(address indexed from, address indexed user, bool indexed approved, bytes32 role);

    /// @param from - address that authorized the revoke
    event AllRolesRevoked(address indexed from);

    /*//////////////////////////////////////////////////////////////////////////
                                Modifiers
    //////////////////////////////////////////////////////////////////////////*/

    modifier onlyRole(bytes32 role) {
        if (!hasRole(role, msg.sender)) {
            revert NotSpecifiedRole(role);
        }
        _;
    }

    modifier onlyRoleOrOwner(bytes32 role) {
        if (!hasRole(role, msg.sender) && owner() != msg.sender) {
            revert NotRoleOrOwner(role);
        }
        _;
    }

    /*//////////////////////////////////////////////////////////////////////////
                                Initializer
    //////////////////////////////////////////////////////////////////////////*/

    /// @param initOwner - the address of the initial owner
    function __OwnableAccessControl_init(address initOwner) internal onlyInitializing {
        __Ownable_init();
        _transferOwnership(initOwner);
        __OwnableAccessControl_init_unchained();
    }

    function __OwnableAccessControl_init_unchained() internal onlyInitializing {}

    /*//////////////////////////////////////////////////////////////////////////
                                External Role Functions
    //////////////////////////////////////////////////////////////////////////*/

    /// @notice function to revoke all roles currently present
    /// @dev increments the `_c` variables
    /// @dev requires owner privileges
    function revokeAllRoles() external onlyOwner {
        _c++;
        emit AllRolesRevoked(msg.sender);
    }

    /// @notice function to renounce role
    /// @param role - bytes32 role created in inheriting contracts
    function renounceRole(bytes32 role) external {
        address[] memory members = new address[](1);
        members[0] = msg.sender;
        _setRole(role, members, false);
    }

    /// @notice function to grant/revoke a role to an address
    /// @dev requires owner to call this function but this may be further
    ///      extended using the internal helper function in inheriting contracts
    /// @param role - bytes32 role created in inheriting contracts
    /// @param roleMembers - list of addresses that should have roles attached to them based on `status`
    /// @param status - bool whether to remove or add `roleMembers` to the `role`
    function setRole(bytes32 role, address[] memory roleMembers, bool status) external onlyOwner {
        _setRole(role, roleMembers, status);
    }

    /*//////////////////////////////////////////////////////////////////////////
                                External View Functions
    //////////////////////////////////////////////////////////////////////////*/

    /// @notice function to see if an address is the owner
    /// @param role - bytes32 role created in inheriting contracts
    /// @param potentialRoleMember - address to check for role membership
    function hasRole(bytes32 role, address potentialRoleMember) public view returns (bool) {
        return _roleStatus[_c][role][potentialRoleMember];
    }

    /// @notice function to get role members
    /// @param role - bytes32 role created in inheriting contracts
    function getRoleMembers(bytes32 role) public view returns (address[] memory) {
        return _roleMembers[_c][role].values();
    }

    /*//////////////////////////////////////////////////////////////////////////
                                Internal Helper Functions
    //////////////////////////////////////////////////////////////////////////*/

    /// @notice helper function to set addresses for a role
    /// @param role - bytes32 role created in inheriting contracts
    /// @param roleMembers - list of addresses that should have roles attached to them based on `status`
    /// @param status - bool whether to remove or add `roleMembers` to the `role`
    function _setRole(bytes32 role, address[] memory roleMembers, bool status) internal {
        for (uint256 i = 0; i < roleMembers.length; i++) {
            _roleStatus[_c][role][roleMembers[i]] = status;
            if (status) {
                _roleMembers[_c][role].add(roleMembers[i]);
            } else {
                _roleMembers[_c][role].remove(roleMembers[i]);
            }
            emit RoleChange(msg.sender, roleMembers[i], status, role);
        }
    }

    /*//////////////////////////////////////////////////////////////////////////
                                Upgradeability Gap
    //////////////////////////////////////////////////////////////////////////*/

    /// @dev gap variable - see https://docs.openzeppelin.com/contracts/4.x/upgradeable#storage_gaps
    uint256[50] private _gap;
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.19;

import {Initializable} from "openzeppelin-upgradeable/proxy/utils/Initializable.sol";
import {ERC165Upgradeable} from "openzeppelin-upgradeable/utils/introspection/ERC165Upgradeable.sol";
import {
    IStory, StoryNotEnabled, TokenDoesNotExist, NotTokenOwner, NotTokenCreator, NotStoryAdmin
} from "../IStory.sol";

/*//////////////////////////////////////////////////////////////////////////
                            Story Contract
//////////////////////////////////////////////////////////////////////////*/

/// @title Story Contract
/// @dev upgradeable, inheritable abstract contract implementing the Story Contract interface
/// @author transientlabs.xyz
/// @custom:version 3.0.0
abstract contract StoryContractUpgradeable is Initializable, IStory, ERC165Upgradeable {
    /*//////////////////////////////////////////////////////////////////////////
                                State Variables
    //////////////////////////////////////////////////////////////////////////*/

    bool public storyEnabled;

    /*//////////////////////////////////////////////////////////////////////////
                                Modifiers
    //////////////////////////////////////////////////////////////////////////*/

    modifier storyMustBeEnabled() {
        if (!storyEnabled) revert StoryNotEnabled();
        _;
    }

    /*//////////////////////////////////////////////////////////////////////////
                                Initializer
    //////////////////////////////////////////////////////////////////////////*/

    /// @param enabled - a bool to enable or disable Story addition
    function __StoryContractUpgradeable_init(bool enabled) internal {
        __StoryContractUpgradeable_init_unchained(enabled);
    }

    /// @param enabled - a bool to enable or disable Story addition
    function __StoryContractUpgradeable_init_unchained(bool enabled) internal {
        storyEnabled = enabled;
    }

    /*//////////////////////////////////////////////////////////////////////////
                                Story Functions
    //////////////////////////////////////////////////////////////////////////*/

    /// @dev function to set story enabled/disabled
    /// @dev requires story admin
    /// @param enabled - a boolean setting to enable or disable Story additions
    function setStoryEnabled(bool enabled) external {
        if (!_isStoryAdmin(msg.sender)) revert NotStoryAdmin();
        storyEnabled = enabled;
    }

    /// @inheritdoc IStory
    function addCreatorStory(uint256 tokenId, string calldata creatorName, string calldata story)
        external
        storyMustBeEnabled
    {
        if (!_tokenExists(tokenId)) revert TokenDoesNotExist();
        if (!_isCreator(msg.sender, tokenId)) revert NotTokenCreator();

        emit CreatorStory(tokenId, msg.sender, creatorName, story);
    }

    /// @inheritdoc IStory
    function addStory(uint256 tokenId, string calldata collectorName, string calldata story)
        external
        storyMustBeEnabled
    {
        if (!_tokenExists(tokenId)) revert TokenDoesNotExist();
        if (!_isTokenOwner(msg.sender, tokenId)) revert NotTokenOwner();

        emit Story(tokenId, msg.sender, collectorName, story);
    }

    /*//////////////////////////////////////////////////////////////////////////
                                Hooks
    //////////////////////////////////////////////////////////////////////////*/

    /// @dev function to allow access to enabling/disabling story
    /// @param potentialAdmin - the address to check for admin priviledges
    function _isStoryAdmin(address potentialAdmin) internal view virtual returns (bool);

    /// @dev function to check if a token exists on the token contract
    /// @param tokenId - the token id to check for existence
    function _tokenExists(uint256 tokenId) internal view virtual returns (bool);

    /// @dev function to check ownership of a token
    /// @param potentialOwner - the address to check for ownership of `tokenId`
    /// @param tokenId - the token id to check ownership against
    function _isTokenOwner(address potentialOwner, uint256 tokenId) internal view virtual returns (bool);

    /// @dev function to check creatorship of a token
    /// @param potentialCreator - the address to check creatorship of `tokenId`
    /// @param tokenId - the token id to check creatorship against
    function _isCreator(address potentialCreator, uint256 tokenId) internal view virtual returns (bool);

    /*//////////////////////////////////////////////////////////////////////////
                                Overrides
    //////////////////////////////////////////////////////////////////////////*/

    /// @inheritdoc ERC165Upgradeable
    function supportsInterface(bytes4 interfaceId) public view virtual override (ERC165Upgradeable) returns (bool) {
        return interfaceId == type(IStory).interfaceId || ERC165Upgradeable.supportsInterface(interfaceId);
    }

    /*//////////////////////////////////////////////////////////////////////////
                                Upgradeability Gap
    //////////////////////////////////////////////////////////////////////////*/

    /// @dev gap variable - see https://docs.openzeppelin.com/contracts/4.x/upgradeable#storage_gaps
    uint256[50] private _gap;
}

// SPDX-License-Identifier: MIT

pragma solidity 0.8.19;

import {Initializable} from "openzeppelin-upgradeable/proxy/utils/Initializable.sol";
import {BlockedOperator, Unauthorized, IBlockList} from "./IBlockList.sol";
import {IBlockListRegistry} from "./IBlockListRegistry.sol";

/// @title BlockList
/// @author transientlabs.xyz
/// @notice abstract contract that can be inherited to block
///         approvals from non-royalty paying marketplaces
/// @custom:version 4.0.0
abstract contract BlockListUpgradeable is Initializable, IBlockList {
    /*//////////////////////////////////////////////////////////////////////////
                                Public State Variables
    //////////////////////////////////////////////////////////////////////////*/

    IBlockListRegistry public blockListRegistry;

    /*//////////////////////////////////////////////////////////////////////////
                                Events
    //////////////////////////////////////////////////////////////////////////*/

    event BlockListRegistryUpdated(address indexed caller, address indexed oldRegistry, address indexed newRegistry);

    /*//////////////////////////////////////////////////////////////////////////
                                Modifiers
    //////////////////////////////////////////////////////////////////////////*/

    /// @dev modifier that can be applied to approval functions in order to block listings on marketplaces
    modifier notBlocked(address operator) {
        if (getBlockListStatus(operator)) {
            revert BlockedOperator();
        }
        _;
    }

    /*//////////////////////////////////////////////////////////////////////////
                                Initializer
    //////////////////////////////////////////////////////////////////////////*/

    /// @param blockListRegistryAddr - the initial BlockList Registry Address
    function __BlockList_init(address blockListRegistryAddr) internal onlyInitializing {
        __BlockList_init_unchained(blockListRegistryAddr);
    }

    /// @param blockListRegistryAddr - the initial BlockList Registry Address
    function __BlockList_init_unchained(address blockListRegistryAddr) internal onlyInitializing {
        blockListRegistry = IBlockListRegistry(blockListRegistryAddr);
        emit BlockListRegistryUpdated(msg.sender, address(0), blockListRegistryAddr);
    }

    /*//////////////////////////////////////////////////////////////////////////
                            Admin Functions
    //////////////////////////////////////////////////////////////////////////*/

    /// @notice function to transfer ownership of the blockList
    /// @dev requires blockList owner
    /// @dev can be transferred to the ZERO_ADDRESS if desired
    /// @dev BE VERY CAREFUL USING THIS
    /// @param newBlockListRegistry - the address of the new BlockList registry
    function updateBlockListRegistry(address newBlockListRegistry) public {
        if (!isBlockListAdmin(msg.sender)) revert Unauthorized();

        address oldRegistry = address(blockListRegistry);
        blockListRegistry = IBlockListRegistry(newBlockListRegistry);
        emit BlockListRegistryUpdated(msg.sender, oldRegistry, newBlockListRegistry);
    }

    /*//////////////////////////////////////////////////////////////////////////
                          Public Read Functions
    //////////////////////////////////////////////////////////////////////////*/

    /// @inheritdoc IBlockList
    function getBlockListStatus(address operator) public view override returns (bool) {
        if (address(blockListRegistry).code.length == 0) return false;
        try blockListRegistry.getBlockListStatus(operator) returns (bool isBlocked) {
            return isBlocked;
        } catch {
            return false;
        }
    }

    /// @notice Abstract function to determine if the operator is a blocklist admin.
    /// @param potentialAdmin - the potential admin address to check
    function isBlockListAdmin(address potentialAdmin) public view virtual returns (bool);

    /*//////////////////////////////////////////////////////////////////////////
                                Upgradeability Gap
    //////////////////////////////////////////////////////////////////////////*/

    /// @dev gap variable - see https://docs.openzeppelin.com/contracts/4.x/upgradeable#storage_gaps
    uint256[50] private _gap;
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.8.0) (utils/Address.sol)

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
        return functionCallWithValue(target, data, 0, "Address: low-level call failed");
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
        (bool success, bytes memory returndata) = target.call{value: value}(data);
        return verifyCallResultFromTarget(target, success, returndata, errorMessage);
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
        (bool success, bytes memory returndata) = target.staticcall(data);
        return verifyCallResultFromTarget(target, success, returndata, errorMessage);
    }

    /**
     * @dev Tool to verify that a low level call to smart-contract was successful, and revert (either by bubbling
     * the revert reason or using the provided one) in case of unsuccessful call or if target was not a contract.
     *
     * _Available since v4.8._
     */
    function verifyCallResultFromTarget(
        address target,
        bool success,
        bytes memory returndata,
        string memory errorMessage
    ) internal view returns (bytes memory) {
        if (success) {
            if (returndata.length == 0) {
                // only check isContract if the call was successful and the return data is empty
                // otherwise we already know that it was a contract
                require(isContract(target), "Address: call to non-contract");
            }
            return returndata;
        } else {
            _revert(returndata, errorMessage);
        }
    }

    /**
     * @dev Tool to verify that a low level call was successful, and revert if it wasn't, either by bubbling the
     * revert reason or using the provided one.
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
            _revert(returndata, errorMessage);
        }
    }

    function _revert(bytes memory returndata, string memory errorMessage) private pure {
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

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (token/ERC1155/IERC1155.sol)

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
     * - If the caller is not `from`, it must have been approved to spend ``from``'s tokens via {setApprovalForAll}.
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
pragma solidity 0.8.19;

///
/// @dev Interface for the NFT Royalty Standard
///
interface IEIP2981 {
    /// ERC165 bytes to add to interface array - set in parent contract
    /// implementing this standard
    ///
    /// bytes4(keccak256("royaltyInfo(uint256,uint256)")) == 0x2a55205a

    /// @notice Called with the sale price to determine how much royalty
    //          is owed and to whom.
    /// @param tokenId - the NFT asset queried for royalty information
    /// @param salePrice - the sale price of the NFT asset specified by tokenId
    /// @return receiver - address of who should be sent the royalty payment
    /// @return royaltyAmount - the royalty payment amount for salePrice
    function royaltyInfo(uint256 tokenId, uint256 salePrice)
        external
        view
        returns (address receiver, uint256 royaltyAmount);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.8.0) (utils/structs/EnumerableSet.sol)
// This file was procedurally generated from scripts/generate/templates/EnumerableSet.js.

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
 *
 * [WARNING]
 * ====
 * Trying to delete such a structure from storage will likely result in data corruption, rendering the structure
 * unusable.
 * See https://github.com/ethereum/solidity/pull/11843[ethereum/solidity#11843] for more info.
 *
 * In order to clean an EnumerableSet, you can either remove all elements one by one or create a fresh instance using an
 * array of EnumerableSet.
 * ====
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
                bytes32 lastValue = set._values[lastIndex];

                // Move the last value to the index where the value to delete is
                set._values[toDeleteIndex] = lastValue;
                // Update the index for the moved value
                set._indexes[lastValue] = valueIndex; // Replace lastValue's index to valueIndex
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
        bytes32[] memory store = _values(set._inner);
        bytes32[] memory result;

        /// @solidity memory-safe-assembly
        assembly {
            result := store
        }

        return result;
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

        /// @solidity memory-safe-assembly
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
     * @dev Returns the number of values in the set. O(1).
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

        /// @solidity memory-safe-assembly
        assembly {
            result := store
        }

        return result;
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (access/Ownable.sol)

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

    /**
     * @dev This empty reserved space is put in place to allow future versions to add new
     * variables without shifting down storage in the inheritance chain.
     * See https://docs.openzeppelin.com/contracts/4.x/upgradeable#storage_gaps
     */
    uint256[49] private __gap;
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.19;

/*//////////////////////////////////////////////////////////////////////////
                            Custom Errors
//////////////////////////////////////////////////////////////////////////*/

/// @dev story additions are not enabled
error StoryNotEnabled();

/// @dev token does not exist
error TokenDoesNotExist();

/// @dev caller is not the token owner
error NotTokenOwner();

/// @dev caller is not the token creator
error NotTokenCreator();

/// @dev caller is not a story admin
error NotStoryAdmin();

/*//////////////////////////////////////////////////////////////////////////
                            IStory
//////////////////////////////////////////////////////////////////////////*/

/// @title Story Contract Interface
/// @author transientlabs.xyz
/// @custom:version 3.0.0
interface IStory {
    /*//////////////////////////////////////////////////////////////////////////
                                Events
    //////////////////////////////////////////////////////////////////////////*/

    /// @notice event describing a creator story getting added to a token
    /// @dev this events stores creator stories on chain in the event log
    /// @param tokenId - the token id to which the story is attached
    /// @param creatorAddress - the address of the creator of the token
    /// @param creatorName - string representation of the creator's name
    /// @param story - the story written and attached to the token id
    event CreatorStory(uint256 indexed tokenId, address indexed creatorAddress, string creatorName, string story);

    /// @notice event describing a collector story getting added to a token
    /// @dev this events stores collector stories on chain in the event log
    /// @param tokenId - the token id to which the story is attached
    /// @param collectorAddress - the address of the collector of the token
    /// @param collectorName - string representation of the collectors's name
    /// @param story - the story written and attached to the token id
    event Story(uint256 indexed tokenId, address indexed collectorAddress, string collectorName, string story);

    /*//////////////////////////////////////////////////////////////////////////
                                Story Functions
    //////////////////////////////////////////////////////////////////////////*/

    /// @notice function to let the creator add a story to any token they have created
    /// @dev depending on the implementation, this function may be restricted in various ways, such as
    ///      limiting the number of times the creator may write a story.
    /// @dev this function MUST emit the CreatorStory event each time it is called
    /// @dev this function MUST implement logic to restrict access to only the creator
    /// @dev this function MUST revert if a story is written to a non-existent token
    /// @param tokenId - the token id to which the story is attached
    /// @param creatorName - string representation of the creator's name
    /// @param story - the story written and attached to the token id
    function addCreatorStory(uint256 tokenId, string calldata creatorName, string calldata story) external;

    /// @notice function to let collectors add a story to any token they own
    /// @dev depending on the implementation, this function may be restricted in various ways, such as
    ///      limiting the number of times a collector may write a story.
    /// @dev this function MUST emit the Story event each time it is called
    /// @dev this function MUST implement logic to restrict access to only the owner of the token
    /// @dev this function MUST revert if a story is written to a non-existent token
    /// @param tokenId - the token id to which the story is attached
    /// @param collectorName - string representation of the collectors's name
    /// @param story - the story written and attached to the token id
    function addStory(uint256 tokenId, string calldata collectorName, string calldata story) external;
}

// SPDX-License-Identifier: MIT

pragma solidity 0.8.19;

/*//////////////////////////////////////////////////////////////////////////
                                Custom Errors
//////////////////////////////////////////////////////////////////////////*/

/// @dev blocked operator error
error BlockedOperator();

/// @dev unauthorized to call fn method
error Unauthorized();

/*//////////////////////////////////////////////////////////////////////////
                                IBlockList
//////////////////////////////////////////////////////////////////////////*/

/// @title IBlockList
/// @notice interface for the BlockList Contract
/// @author transientlabs.xyz
/// @custom:version 4.0.0
interface IBlockList {
    /// @notice function to get blocklist status with True meaning that the operator is blocked
    /// @dev must return false if the blocklist registry is an EOA or an incompatible contract, true/false if compatible
    /// @param operator - operator to check against for blocking
    function getBlockListStatus(address operator) external view returns (bool);
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.19;

/// @title BlockList Registry
/// @notice interface for the BlockListRegistry Contract
/// @author transientlabs.xyz
/// @custom:version 4.0.0
interface IBlockListRegistry {
    /*//////////////////////////////////////////////////////////////////////////
                                Events
    //////////////////////////////////////////////////////////////////////////*/

    event BlockListStatusChange(address indexed user, address indexed operator, bool indexed status);

    event BlockListCleared(address indexed user);

    /*//////////////////////////////////////////////////////////////////////////
                          Public Read Functions
    //////////////////////////////////////////////////////////////////////////*/

    /// @notice function to get blocklist status with True meaning that the operator is blocked
    function getBlockListStatus(address operator) external view returns (bool);

    /*//////////////////////////////////////////////////////////////////////////
                          Public Write Functions
    //////////////////////////////////////////////////////////////////////////*/

    /// @notice function to set the block list status for multiple operators
    /// @dev must be called by the blockList owner
    function setBlockListStatus(address[] calldata operators, bool status) external;

    /// @notice function to clear the block list status
    /// @dev must be called by the blockList owner
    function clearBlockList() external;
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