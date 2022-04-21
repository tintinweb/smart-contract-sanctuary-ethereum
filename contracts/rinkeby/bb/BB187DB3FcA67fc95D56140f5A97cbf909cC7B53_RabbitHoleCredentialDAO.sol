// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "@openzeppelin/contracts-upgradeable/token/ERC721/ERC721Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/security/PausableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/UUPSUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/utils/CountersUpgradeable.sol";
import "@openzeppelin/contracts/utils/cryptography/ECDSA.sol";
import "@openzeppelin/contracts/utils/Base64.sol";
import "./libraries/NFTDAO.sol";

contract RabbitHoleCredentialDAO is
    Initializable,
    ERC721Upgradeable,
    PausableUpgradeable,
    OwnableUpgradeable,
    UUPSUpgradeable
{
    using CountersUpgradeable for CountersUpgradeable.Counter;
    CountersUpgradeable.Counter private _tokenIdCounter;
    uint256 public id;
    address public signer;

    mapping(uint256 => uint256) private tokenIdToBlockNumber;

    /// @custom:oz-upgrades-unsafe-allow constructor
    constructor() initializer {}

    function initialize(
        string memory _name,
        string memory _symbol,
        uint256 _id,
        address _signer
    ) public initializer {
        __ERC721_init(_name, _symbol);
        __Pausable_init();
        __Ownable_init();
        __UUPSUpgradeable_init();
        id = _id;
        signer = _signer;
    }

    function mint(bytes32 _hash, bytes memory _signature) external {
        require(recoverSigner(_hash, _signature) == signer);
        require(keccak256(abi.encodePacked(msg.sender, id)) == _hash);
        require(balanceOf(msg.sender) == 0);

        uint256 tokenId = _tokenIdCounter.current();
        _tokenIdCounter.increment();
        _safeMint(msg.sender, tokenId);
        tokenIdToBlockNumber[tokenId] = block.number;
    }

    function pause() public onlyOwner {
        _pause();
    }

    function unpause() public onlyOwner {
        _unpause();
    }

    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 startTokenId
    ) internal override whenNotPaused {
        require(balanceOf(msg.sender) == 0);
        super._beforeTokenTransfer(from, to, startTokenId);
    }

    function tokenURI(uint256 _tokenId)
        public
        view
        override
        returns (string memory)
    {
        require(tokenIdToBlockNumber[_tokenId] > 0);
        return constructTokenURI(_tokenId);
    }

    function constructTokenURI(uint256 _tokenId)
        public
        view
        returns (string memory)
    {
        string memory image = Base64.encode(
            bytes(NFTDAO.getSVG(_tokenId, tokenIdToBlockNumber[_tokenId]))
        );

        return
            string(
                abi.encodePacked(
                    "data:application/json;base64,",
                    Base64.encode(
                        bytes(
                            abi.encodePacked(
                                '{"name":"',
                                name(),
                                '", "image": ',
                                "data:image/svg+xml;base64,",
                                image,
                                '"}'
                            )
                        )
                    )
                )
            );
    }

    function changeSigner(address _signer) external onlyOwner {
        signer = _signer;
    }

    function setApprovalForAll(address _operator, bool _approved)
        public
        virtual
        override
    {
        require(_approved == false);
        setApprovalForAll(_operator, false);
    }

    function recoverSigner(bytes32 _hash, bytes memory _signature)
        public
        pure
        returns (address)
    {
        bytes32 messageDigest = keccak256(
            abi.encodePacked("\x19Ethereum Signed Message:\n32", _hash)
        );
        return ECDSA.recover(messageDigest, _signature);
    }

    function supportsInterface(bytes4 interfaceId)
        public
        view
        virtual
        override
        returns (bool)
    {
        return super.supportsInterface(interfaceId);
    }

    function _authorizeUpgrade(address newImplementation)
        internal
        override
        onlyOwner
    {}
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
// OpenZeppelin Contracts v4.4.1 (security/Pausable.sol)

pragma solidity ^0.8.0;

import "../utils/ContextUpgradeable.sol";
import "../proxy/utils/Initializable.sol";

/**
 * @dev Contract module which allows children to implement an emergency stop
 * mechanism that can be triggered by an authorized account.
 *
 * This module is used through inheritance. It will make available the
 * modifiers `whenNotPaused` and `whenPaused`, which can be applied to
 * the functions of your contract. Note that they will not be pausable by
 * simply including this module, only once the modifiers are put in place.
 */
abstract contract PausableUpgradeable is Initializable, ContextUpgradeable {
    /**
     * @dev Emitted when the pause is triggered by `account`.
     */
    event Paused(address account);

    /**
     * @dev Emitted when the pause is lifted by `account`.
     */
    event Unpaused(address account);

    bool private _paused;

    /**
     * @dev Initializes the contract in unpaused state.
     */
    function __Pausable_init() internal onlyInitializing {
        __Pausable_init_unchained();
    }

    function __Pausable_init_unchained() internal onlyInitializing {
        _paused = false;
    }

    /**
     * @dev Returns true if the contract is paused, and false otherwise.
     */
    function paused() public view virtual returns (bool) {
        return _paused;
    }

    /**
     * @dev Modifier to make a function callable only when the contract is not paused.
     *
     * Requirements:
     *
     * - The contract must not be paused.
     */
    modifier whenNotPaused() {
        require(!paused(), "Pausable: paused");
        _;
    }

    /**
     * @dev Modifier to make a function callable only when the contract is paused.
     *
     * Requirements:
     *
     * - The contract must be paused.
     */
    modifier whenPaused() {
        require(paused(), "Pausable: not paused");
        _;
    }

    /**
     * @dev Triggers stopped state.
     *
     * Requirements:
     *
     * - The contract must not be paused.
     */
    function _pause() internal virtual whenNotPaused {
        _paused = true;
        emit Paused(_msgSender());
    }

    /**
     * @dev Returns to normal state.
     *
     * Requirements:
     *
     * - The contract must be paused.
     */
    function _unpause() internal virtual whenPaused {
        _paused = false;
        emit Unpaused(_msgSender());
    }

    /**
     * @dev This empty reserved space is put in place to allow future versions to add new
     * variables without shifting down storage in the inheritance chain.
     * See https://docs.openzeppelin.com/contracts/4.x/upgradeable#storage_gaps
     */
    uint256[49] private __gap;
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
// OpenZeppelin Contracts (last updated v4.5.0) (utils/Base64.sol)

pragma solidity ^0.8.0;

/**
 * @dev Provides a set of functions to operate with Base64 strings.
 *
 * _Available since v4.5._
 */
library Base64 {
    /**
     * @dev Base64 Encoding/Decoding Table
     */
    string internal constant _TABLE = "ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789+/";

    /**
     * @dev Converts a `bytes` to its Bytes64 `string` representation.
     */
    function encode(bytes memory data) internal pure returns (string memory) {
        /**
         * Inspired by Brecht Devos (Brechtpd) implementation - MIT licence
         * https://github.com/Brechtpd/base64/blob/e78d9fd951e7b0977ddca77d92dc85183770daf4/base64.sol
         */
        if (data.length == 0) return "";

        // Loads the table into memory
        string memory table = _TABLE;

        // Encoding takes 3 bytes chunks of binary data from `bytes` data parameter
        // and split into 4 numbers of 6 bits.
        // The final Base64 length should be `bytes` data length multiplied by 4/3 rounded up
        // - `data.length + 2`  -> Round up
        // - `/ 3`              -> Number of 3-bytes chunks
        // - `4 *`              -> 4 characters for each chunk
        string memory result = new string(4 * ((data.length + 2) / 3));

        assembly {
            // Prepare the lookup table (skip the first "length" byte)
            let tablePtr := add(table, 1)

            // Prepare result pointer, jump over length
            let resultPtr := add(result, 32)

            // Run over the input, 3 bytes at a time
            for {
                let dataPtr := data
                let endPtr := add(data, mload(data))
            } lt(dataPtr, endPtr) {

            } {
                // Advance 3 bytes
                dataPtr := add(dataPtr, 3)
                let input := mload(dataPtr)

                // To write each character, shift the 3 bytes (18 bits) chunk
                // 4 times in blocks of 6 bits for each character (18, 12, 6, 0)
                // and apply logical AND with 0x3F which is the number of
                // the previous character in the ASCII table prior to the Base64 Table
                // The result is then added to the table to get the character to write,
                // and finally write it in the result pointer but with a left shift
                // of 256 (1 byte) - 8 (1 ASCII char) = 248 bits

                mstore8(resultPtr, mload(add(tablePtr, and(shr(18, input), 0x3F))))
                resultPtr := add(resultPtr, 1) // Advance

                mstore8(resultPtr, mload(add(tablePtr, and(shr(12, input), 0x3F))))
                resultPtr := add(resultPtr, 1) // Advance

                mstore8(resultPtr, mload(add(tablePtr, and(shr(6, input), 0x3F))))
                resultPtr := add(resultPtr, 1) // Advance

                mstore8(resultPtr, mload(add(tablePtr, and(input, 0x3F))))
                resultPtr := add(resultPtr, 1) // Advance
            }

            // When data `bytes` is not exactly 3 bytes long
            // it is padded with `=` characters at the end
            switch mod(mload(data), 3)
            case 1 {
                mstore8(sub(resultPtr, 1), 0x3d)
                mstore8(sub(resultPtr, 2), 0x3d)
            }
            case 2 {
                mstore8(sub(resultPtr, 1), 0x3d)
            }
        }

        return result;
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "@openzeppelin/contracts/utils/Strings.sol";

library NFTDAO {
    struct SVGParams {
        uint256 tokenId;
        uint256 blockNumber;
    }

    function getSVG(uint256 _tokenId, uint256 _blockNumber)
        internal
        pure
        returns (string memory)
    {
        SVGParams memory params = SVGParams({
            tokenId: _tokenId,
            blockNumber: _blockNumber
        });
        return generateSVG(params);
    }

    function generateSVG(SVGParams memory params)
        internal
        pure
        returns (string memory svg)
    {
        svg = string(
            abi.encodePacked(
                '<svg width="448" height="448" viewBox="0 0 448 448" fill="none" xmlns="http://www.w3.org/2000/svg">',
                // "<defs><style>",
                // "@font-face {",
                // "font-family: 'Inter';",
                // "font-style: normal;",
                // "font-weight: 500;",
                // "font-display: swap;",
                // "src: url(data:font/woff;base64,d09GRgABAAAAAFdgAA8AAAAAtpQAAQABAAAAAAAAAAAAAAAAAAAAAAAAAABHREVGAAABWAAAAFQAAAB2DMUMq0dQT1MAAAGsAAAMFgAAMYSvILtIR1NVQgAADcQAAA2pAAAjBpZSmNVPUy8yAAAbcAAAAFUAAABgfo37YlNUQVQAABvIAAAAOgAAAETvFdlDY21hcAAAHAQAAAG9AAAChEImjepnYXNwAAAdxAAAAAgAAAAIAAAAEGdseWYAAB3MAAAymAAAUm6g5WhEaGVhZAAAUGQAAAA2AAAANi3DYUVoaGVhAABQnAAAACAAAAAkHvURJmhtdHgAAFC8AAACsQAABWTyctlEbG9jYQAAU3AAAAKdAAACtGNueMBtYXhwAABWEAAAABwAAAAgAXIBBm5hbWUAAFYsAAABHQAAAkA1dF64cG9zdAAAV0wAAAATAAAAIP4zAMB42g3EAQaEUABF0XsHQD6zgAADhhYzpnaQJIBQIACtNggQ9RwOAhUA8OKNVEjhl//0eWDME3NeWPMWsoccIWfIFXKHFkuurfPHb25scmuHDxxTD3t42lSPU5TYQBRAb5xMatu22//atm3btvlb27Zt27bdrl7We+6ZeRYaoMhFCfQKlWo0IEmPtgN6kQQTIDw8Mq5179ivFy5EWZjouPKUXwpNK4YJzNebJaCH3sNPo/dTY6IwTH2MPi9K99PER98i75BhxpLEqGC0M/oIi6RuifHLOCesi/z3yLsh3mfGlwCJhZg5zEJmCfONkhdg6VYD+5jVzRpiTbNW2MfsC04tp4czy9mgxjjn/GQBbg63lJtOCGS7SCa4p4QrQdTLIn8sXikvz",
                // "AtTiVQJP40apsrJi2KM+qE2qGnyfiRgW+T/Qr2TPyx+J7k2Gxrz5ekYmFjYOCh8EpGS1KQhHenJSCYyk4WsZCM7OchJLnKTh7zkpwCFKUJRilGcEpSkFKUpQ1nKUYFqVKcmtahNHepSj/o0oCGNaEpzWtCeDnSiM93oRW/60o/+DGQYIxnLOMYzgUnMZT4LWMgqVrOWdaxnM9vZwS52s4e9HOIwRzjDOS5wiStc5RrXucld7vGARzzhKc94zgte8orXvOEt73jPB77wjb/8jyCsHoArS6Iwjn/neRyuxjZjZ23btoI149riuLQavlprFFTlBYWxzbu2rdfzr4xdVb90972nT/PdWFfrZt2thyVYoiVZsqVYqvWxATbQhlmO5VqenWfn2wV2tV2jgKa5y7TYzdAKt1mfUpo8N0l+xai3uAR5lAEiKogo1i5XIqLY0beoLabvBqJ3xSfpE0re6Esi/ZpMLYaW+E9KVD7vinAOfW7ETbgfZURUkpVoRV0/cp4jxlQbsYtpr4DnbhN55VOUmkevbiIfOSroO4O+JZruPL3SkSOHPY3QdxJ9x2kt5S7m6JEnfHA0kbv2RrJyIv17V8hYlJ10uXtj78wuE2vgbYlWxD0yVuzdg0ny7e19GbXKjlE2k+cy3aYrUGNSQJdSu1IleobSo/Ttr/npw4gugXzFtE7mqafb7Grem0Yzhok2c8lxv3CfxqkEpShDOaJuNv1ZYcfuzCNLPYxnH2g0b2ewn1G9jfcxj4z1WEydXlpNuQbrsAFbsBXbsRNklYf/XbnicK7cBIMPfgQQRAhdVWHd0B09kIBEJCEZKUjFQBS4qBWiCBfhYlzCmCFdwSo5Z7VwJisYfRcz5fSUIqPmgx8BBB",
                // "FCGBH0xGh6prHGbOpvUs6jXY/G+Aw1oZkTjKEFQV3M7l6Cy3A5roBfzW6eYmhBgFa9YmjBZ+4nZtjIqTWh2c1RDC3waJ8ri6+WD34EEEQIYUTQk3uUQ2Qu8pCPAhSiCMU4g1mfibNwNs7BuTgP5+NCXGrSDQf9km7GLbgVt+F23Im72YUnKJ/G8269Ktxq7txNqnKfqZp2jbJVy52toz2Zsed07FSJmtDMbsXQglbOoQ3tWMI9X4YVTvLixdyONMXhXJoJBh/8CCCIEO99qnGLxT6p395TukzpzC+Tc87CI+R+FKUoQzneJGaekxZSX4R66p+5Fn1Bv6/wNb7Bt26SdXXcPnRHDyQgEUlIRgpSMZAZhJlBsdLImEmZhTepz0M9IjLG9cGPAIIIIYwIwvT1lI43MY8n8x19KRsow+pJLY086XgTzcwxhhYkM/Yk+j9E/1tZdYlKUYZy8C0m50PkfImc3F3KBspmlSiGFhz0rd773ZlMLbCnhumIctO66AHWWkmtlhEns8rpeIVsc+IziOB7xrsNxHi8j3ArPM5oOdGN3IgvNMX9qmnxP2xEvMJYqxJkjhHhRwBBhBBGBD3JNZrfahr5MqhnsqIs1JDxTZ5xB2jVEpksYwU++BFAECGEEcGePOOUjgx3G7mkLGSzuhqevYl5zL8ewb03itvEqFlgNE1QZ/52QQr6YwAGYhAGYwiGYhhGgCwaQzkW4zAeE5DGXI72rbjSEnStKnQdrscduAuPEF+KMpTjeWb0Ar//CspKxqiirEYt6vAmMfMYpx4fc0af4HPqX1J+5yr2/qfglOXxpNMJz2E0TMQrgT3Yqi5IQX8MwEAMwmAMwVAMwwgcPNLntI0WJ7fvv5Mi+oW78bv",
                // "7VH+41/Sn+1F/0f5bA/SP+0r/0jb97Xaqq1ipdZWsG7qjBxJc1BIpk5CMFKRioES//xx3gr+jrK+LUiMDOywF9v7Givf+xoqJ5U4REWVuHnzKZM5Z8PX9ifjdzNgBZCRXHMfxXyBO3RFQQbGUKG0ZQgXFooCGARAwIG0KHlcUMABoGHAIeCC4KsGpcyDSHnGn5E4Vx1XodaWn0XGtc6J934OZZ7Nv5mZmsrt7H8TfE/vevn3////NaHDv/a/0mT5VR+yy6eObPtpily0FeOKjEd/7+FDdfKz2TtQBquNO5GElyRkVXPP6E70Re6pBWv4Ht4oow6rAbUY8VAVy9cBxMGJYHVuLjzAKkEmcqQXs5ZgHksRv8th2L3wc+yjDcKAKnAYjjzhqPr3ByBoKuRHrmrTrx2pwJmHxOylJukEkMWRFY8j5kAiLZSC5zBXfhuvEksRLlVIJyzM2+HdiH4eapRNdAY/Dc+VeKYDBqBLB/PzHU7WGDUYGmimf9QMfh8Jxow4wQQZOYOhyHyfyiDF9965BMBuZPqhab/f5idQDkXrhge9xQx6TNazNkvlzlRR7bKUr/b4rquFS1Ulcrl4YaRaGmhGs5ohYASL+kNr2X/5RV77rsixJbHCn/ptzDePju2pnoNCXevslai/c+eXeWZGol/nuMrmmJVUjltnkloSIWHU5mcSr8W5ETCoPEY/fqLH1s3DGcNrZSzr7CsLRZJ3CaOEwCr0z3YpL3HJe9Z8XG85KRdd0GQkZNrwlhU8yWKxa487kWjCkmhIG3W8Ekot0BS5v87sxlrfOuryIcmIFGPae23MXwYj1UaJeiLlZ3qJISMiK8Z8UFVHijif3/P+8qB1+BSFOi9vmR6rg50kRF2Mn",
                // "5xxbf4N3B+F+9s6bw6Y+xiH3FOC7ij6YqAEZN9iTLuVXUvUtuWhdJYqTwq9vrPBDDlwsafvyGWPoJmf+hB1iCUmslOtyL3lSfRPjPb+PAc7ZkyQ2WeOFQtW/rwmzoBvO1Ro/88PU+v6ALW5LbsR1IgmfPcRVNdVlmEvnWaGl2qc24rLCss0uexJrRHxBrADx+F6S+Ld09fvsx0hVg51i3nVidojDLMO4vDzPft4TFYj79VYO2ORh+15Kptb4S6rHPnbKz2O5GvEjdyWts4/lRJK4X/92Qe+S+dNUu89LAxW4z6HmimcSueaIDS0EI80df2tB+FNtGFVY6pQfS+Vfo5IhUapSVtPL91TtWrunAxLNCN9WdNcr4ph9SYZdson+u1pfGxhIioq+lRR1bEsVyC+Nr5afykGZ32xwqgacVWSrr8R8XXWnvDpSovAdOxG2fpWLVHH/GpAXXXCzud7wnKc+zvS5v48897u6kNrFL3or8bvmLLy58qj5SYdIHtbn7zdF/ho/3gFHHPrYYbvfczCLOQtYdfWaoXBYqwCAwuCctAm79uEl0j6t74tk29xk27Zt265dtuue7/9nxgR7BCvABj9tAMH4Ek40gcSRQBg5FBJJsS6eUl0C5bpEanVJ1NNIMq26NDrpIp0eBslkhHGymdTlM8cSBayyTimbbFPBHgdUc8QJdZxzQSNX3NDMPY/08KLr5003wKdukB+xYEisxJZZcRRH1sVZ3NgQD/FmRwxi4ABBjJXSVZIcUQwEwGxaZmZmZjT7/ndymWaiY1kZpQf6Vc7elj4zZqNCX8e2HUXM/esDdu0phKqlz376gXmHBjqOHDuxEKfqln6NySj0d5xZVhuMmyTiVhG10LT0J8vuP",
                // "Zrx2XCXUd/9SA8/0cS8ScCaO18sOQefclvzeo2b6ITpbgAU6PW0Nm1hPXKzETAlLJIAsGJVAoagdXv6MxY8qIwYSyIK8FXpG7jEFbgGF3qeam35Uy9X6aM19OFp5em+hkIdBUlXfmLmX99oTdoKiVmbAJizZdt87OjTVii17SaFoThKwrFCGBFKbSMS5wqXBnSNuveQHh4VymQ2HVhz4tqVPawBH9rXpxt7ocCcKmCwc2b/sBS5WY7uvk4KAJUFixLQr4rBJLenP8FYDDpTGzaWRJziFjfusI8DhwDwxr42T3m5Gh+vSuiP903XfwEWzDTYAAB42oSUA5D0WhSEvz43g7WN37Zt27aNZ9u2bdu2bdu2mU1NzdSkFtXVF919ThwEZDKZ+7HRYyfPJnfzip23UkhuoGvUiNnNqYb//iMKCMMjQjRQYgnFJbTYqhWbd6bz6q3bttB/7Y4rVjF087ZVm1m8dZctO7Jyuz+xfue6cSvg0YzmtKI1IGqBHBwRYmSQ5a/zKKCIEsqooAoQAKIGEMMBMYKRHMrjfK64K3edvePdWJ8rfe7v83yfD/r81Dvey/bZ2+dSn+d6D3rPR6KRysjmyLWl35dNLNtYdmJF5+aTm++bjhbUgz1bXJ2GR1tCFBBxRCZGIW0RRg1zEB5gPB6cuQBL0+oSILxkh8LE7DE3kfFT9flK+TXJMzArpZx8nwa0R1yKEIaxD4ciLvVhlNCZiaznYM7nTl7ma3mqVHeN1nxt1N46WmfrSt2uh/U8WageGAIA1GACMpuorN+HjEar6nMh3nBFPR7EGkyHHYjWnwzpEKkvlaaCV08ipYELu0kFLORYQBApgIeSVx1lLkJcmnxHHCDdjlTnQDTknIvpcg",
                // "1GQDzkHYjT0T6aIyAz5K7G09YAhoDskD+aiKYqAB8iIDeUaElUnZUA9yMgPz3Dv8QUT4GzEVAYSr1OnA/TsCsCikO568ngzhCmIqA0lDyUTI4njNYIKEeIv0nd99mcS6peFCLGAgIqMcSPCvxkRUt2SasoRgxG1CKgGkPBNwyGKVsloCq1JjPtaTuE1DupGe0p4Eu+UrZylKs85atAhSpSsUpUoUqVq1RlGBGm+ID5PoIjYZzKaWTzHC+QS6pja/L4h3/5T0gyOXmKKKpMZSlDMdVlXNCBoENm0CE79RcraEucUo7lWO2uV/WqezqyN/350sqtJT9bZ+vLvzbcJtpsW2rrbUfb2w5V3I63M1VoF9u1qrbb7UF72l619+1L+9n+VVsXd4Xq7qpdWw103d1AN9pNdfPdSrfZ7arRbn93uCa7493pmu3Od5ezo+7UEIxn6e+vz9eV7K2bdS+H6nG9qLf1qb7Xn+ZZLscHZ3VmcFYXh8+Ka+vOitvrzooHw2fF0/5Z5fOyK3fNedu1d9352PXXMDyu8fFsYnV1cnVlYnV10r066V6ddK9Mulcm3SsDdygu8OrmqxNzoAdX2olbuZ8neZl3+Zwf+VtR5atSrdVV/TVSkzVXy7VRO2tfHa4TdbYu1fW6Uw/rWb2uD/W1fjUs04qt1tpaV+trQ20s8zUZ4zU6MZ+VbGZX9udITuZcLudG7uZRnudNPuZbfpcpW6Vqro7qraEar5larLX/c0qHMA3GUBCAe0+j0SgEGgUJGsMEGklQiAnUgpwkUwgEiqBermlr0EgkDiQSiVf8+3M5n6n7cuf6iiVWWGODJ7yAeMM7PvCJb/zgF39Y6LW+pGHR6lZaTRqlWsOi1a20msRSrWH",
                // "R6lZaTeqlWsOi1a20mpSlWsOi1a20mtRKtYZFq1tptUkX27+jHEoquzKVbZvz1Q/LYse7X+MWd7jHGg94xDNekTjVratFKyV6pVd6Ta/pNbVycrVopTTZopVSek2vqXXaSrVopUSv9EqvWapFK3EyX6Qqqcw5qZ7qqT7Vp/qc+5jbKESJiL3Yj4M4iuM4i/O4jKu4iWWsYh2b+CcIHgDEiIEAAH4v69S2bdu2bdu2bdu2bdu2bVsz04OFwepga7A/OBlcDu4Gz4OPwW9HLryL6RK7tC67K+hKu6quvmvpOru+brib6Ga7pW692+kOu7PuunvoXruvEAIGkSEuJIeMkBuKQnmoCY2hLXSHgTAapsJ8WAmbYS8ch4twG57Ce/iJgGExOibE1JgV82NJrIx1sTl2xN44FMfjTFyMa3E7HsTTeBXv40v8jH9JKCLFpqSUnnJSYSpL1akhtaau1J9G0mSaS8tpI+2mo3SebtJjekvfOeDQHJXjc0rOzHm5OFfk2tyU23NPHsxjeTov5NW8lffzSb7Md/k5f+TfQhJeYkpiSSvZpaCUlqpSX1pKZ+krw2WizJalsl52ymE5K9flobyWrxqippE1ribXjJpbi2p5ramNta1214E6WqfqfF2pm3WvHteLeluf6nv9aWBhLboltNSW1fJbSatsda25dbSeNtBG2kSbaQttpW20nXbQTtpFu2kP7aV9tJ8+8OYj+pg+oU/pM/qcvqAv6Sv6mr6hb+k7+p5+oB/pJ/rpfq5fHKrkf57pAAOCAIiB4P+/MoZJfni37BbQUBDiY19VrYoadW+VLVu2bNmyyy677LLLLhs2bNiwYcMOO+ywww477LHHHnvssffaPrupqlVR8xVbtmzZ",
                // "smXLLrvssssuu2zYsGHDhg077LDDDjvssMcee+yxx95r185PVa2Kmq/YsmXLli1bdtlll1122WXDhg0bNmzYYYcddthhhz322GOPPfZem2dnVbUqar5iy5YtW7Zs2WWXXXbZZZcNGzZs2LBhhx122GGHHfbYY4899th77Tw7q6pVUfMVW7Zs2bJlyy677LLLLrts2LBhw4YNO+ywww477LDHHnvsscfea+/ZWVWtipqv2LJly5YtW3bZZZdddtllw4YNGzZs2GGHHXbYYYc99thjj/0b9WOxDjAgCIAYCLr73X51DDv54ZJuUNAgIO/v4cVqdPV0kL7LYnT1dJC+a2J09XSQvgtidPV0kL6rYXT1dJC+S2F09XSw/f9rzSyAJbmRIPqy1DMfbrxm5mVm5v1kWuZjJjOzl9fMzMzMzIzHzMzMfC5XVITHG3agf0a3UplV0oy+NB1qRbRFrEWkec+ilViPxP+Z1/gadaCiFzsxnJkUwPiA/QC1dUHW92Ws18eSdabak4CAXVPZk81S6Y2wWA/5biavXsjxGqLSpIh4O/9rGHUa2h2PiHtTO1oR73hm8ykNVI/m633alxY2YTt6M1h1Rqqhbio+7/icplJwpi5K1DswTVMnpunUaPATfsMW/EWz0p+J8bl41z6SyXQ17UJXcDyncz6Xcz23cz+PajHZi5Lx9WTfSM1Zat8g44Kl5kgt4vYiPmuW39Ci/ExRpu/ZWbofZfiRvwDTbC3EYi/dir+v1/zMnZ8x8zC+HuPfgfG5YJ04yzFfgPO4fz2VhaEszLxWXvP2vua9T9Jk7a49qAMzWMflPMiXfCQHa6rm61NaoTN1te7Xy/qB/mBmW9lAO9uutDvtafuC/aC0lh3K8",
                // "NJRlpe9y4pybrm1PF++Vf5QtVa9q+nV4mrf6vjq6lqjtrS2d21V7ULfoz3vu7N/+L5seL3D92MH1o/3fdiDvgP7FQUQW2Cs4zMI6IccT1EQK8ITc5ucm8P5RDpjm5xbw9kzne2anNsQxgVcTsHcHYgYCRmx4br6It+K+Kd4GiHPKxT1VL31Iqp6A1CoNFZjq010v2ubpFbTLnKU/+hqVP6Tal3tCpSf6VTXf5a6lc/pUFQ+h3g8FOljqDyK1Y7l1lTmu3Izxcdyby7OvPM11dXzPW4px6e2RgNdW+ORHbUODs7szVzbF/GBqIPKByjMlpU3lT2pmMz+/MEZFEd/vlPGI7/yu7IFu/Ny6Yv8ArBY9Q2gFxO9PMwxgSM5z2s3OJbyG8cy9dNAlmuJlvIBjBqZoyE0NEzDNVgjHUM1Wss1jIL4CKqdS45Q7XgWev34rJfa4bXD6XDl8FRw/gnESMja0hiV3pD1Hs/q8ftmgFGYxGeBfTiUURzOEUyhYFVlXcgvZ3owx+5aVGsHBPSPMf6ezkbVP1IbQKGUl8vLWuHqT1IdSAGvfw7pM6EMSuVRrHo0z1gGp3YjpbqxulEdoQ5J9Wyq6uw3oKGhD039aGrV0VVAW4QzLJ2PYKWHf4U2PLXZlGp2Gc3PQh2R6niqanw1vuzAF0IfmfpO3vZOb6BUPBjOqHQq6lX+2a+4PLzROXd+QbHP2edYE+qYVL9EVb5kD9qD7Bv62NQfplYeLg/blXYli8MZl86V1MuVxWHH2/FMDm98eutoKetKwPa2vfP8YwJG4x3n4GVcw9KYiR/kDu7mQzzt+Bhf43t8PObmvjE399PuWspB+bswnjxJBiZi1LjeW4B7eBLjGccm/IAfsamGaZ",
                // "jHG/KeroZg53NJzpwnUZlKlEA/CqardaurA5GX0T4lz87Od30zJC+BSdHCCmT/wnSonAGTo40P6TOu/4RkELO3qMcxH9mrmIIBU6Od8a7eTdFQh3NgWrS0hXZCdjHFWXBgOsXxL/6lCtmqNzkwg4L4BeIbWeb3itMD8SzyMleK417H44jbkZe5WvL0+XyMS3GWq8U4njMRq5LlmnHs7zgS8RksGbFyxIcQcyksdjjPtWNMpQfFzJmaPFaPo7djKGKHJg7DkONADGmsJkKeqp0JTedbW/n921yez4ennf84nAO5IJ8cT/ElftSUMZs+HnWZ51zBlVzF1VyT2Xd7/tf4Ot/gm3zLY77Dd/me/HmsPbWXZmuO5mqe5muBFmqRFmO0cKADzudSxM2OVm7ldtp4ytHgNb7KRpqkbrZq+gR70vtd6r8ePRM9t0TPrdHze6LnRvS85Qaj1dxzjlac/F3IRVzMJRuMVjuWUbaB05teHMcKVrKK1axhLetYz/E8zhM8xTOY4wTOBJ7lBdrfmunOiZzEyZzCqZzG6ZzBmR73HM97rFHliaS3RXuO5TOOjV4H/4lAfAAAAHjaLcUbFIAwAEDRt39nJ+dRWe6eNMk199wpSecOc81yp7TfTl25aNeJAwOusQuwfaudrN4lRlHSM7TAxG+IfSQTrtuncwSfZAKxAliqUqB+AOMbD1wAAAB42h3EAQaAUAAFsL1fCChEAqC7FRIUXTwBlBomolHQ/0/KOS9HWvZ1O9KJ2jcy5kIlSgZ4bl7HYgcdAAB42n3LQ2NcUQCA0e/e2LbuTGyzblPHTu3Utva1bXNV27bdvje12z8Qr8qc/QEkYAa4Y4YA3DGXo4EsFOb4Ek8mM6kViaJYnpC",
                // "X5DP5Qkllo+yUu/JVgcqowlSyylLZarzaazAaFhmWGF1ramtrAUUCWWysv0Xy+G/XTXkr/8abpDL/eXMBagMAaqpqKmqKTCmmOFOsvgr0tfpcfbU+W1+oH9FnaHe0C9pB7cCr07ISQRZQxisQq8VafiMW0gSRwmIOs5XJIoJFHGI5K3jNHU6xm9Ns5yznucltbrGUtQhssMUeR9xwxwNP/PAngECCMBBJFNHEEEscyaSQShoZrGQXqzChiygyaUNbsmlPF7qSQy7FlFBKORV0ox/9GcBAqhjMSEYxmjGMZzU7WMNDkcoSpjCNbUxlJ99ENO/4yHU09vBWJPCBB/zgp4hkKF+5IpL5ziduiDARKsJZhjkWWGKGxApr7HDCGRdc8cYHX7xEKYpQwggnGCP3CCGeBBJJIp0JDKIFWTSjFc1pSWva0ZFOdKYDBRRSRD4TqaQXvelDD7pzn54MYzgjGMI4JjGWCPqKcg6ynwMcrwNRPYhmAAAAAAEAAf//AA942q18AVxN2fP4mXvvu+8VqFIBSFWARVUWWgFAqqpSokKUiIBIUgQi1EIAoCKIJUCszQrW2gWxVstaCwSieu/0n3PeqxK+u/v5/z56994795yZmTlzZubOORdRgKyJ1W+iH0tEoiQ1SB1iTIizobkhVP/JevWKHn/808QKhBJVd3YUctjxfU7lNRFIH0KU41WEYyZB5sD+WYC5oTkso9lCAYwWCmi25qSB5o3UovSWinwgcqJ6FVUTImn76rvwvmbE4uP+xs2t7e0cbDuamtSVzatcfxbvy75hYX0Hjh4tgO6ikpD8S2jvgaNGDewdWn4uK9NRHiJbEyB4CV+BOyEV8NQKeCuSIHwO3hIcq8AjKuBtoYVQ",
                // "KdlVLlkDYl1NM1waJg6TR7bp6GBvZ23RXDapa/pZ4QSTWZlDFri7LXB1XeDW1dW1a1c31yryjdkT5ZYwZEiCm9v8IWvdO3dxd+/S2UM7MvpDVUQ73pORcOU/CzDGYx/xmDxY3UFMVE8R75QUJqsfhouPVYQWaZbT95qltEj+vdhcaAISGy2RFBAi71ARxNaY2CBGQ/OOEhdAadJEwLOEwnFRrC3M7fGKS2VeILzIhybLhm8YHvJ9bDK98oJawql7OcHfRVNH2Dh218isbOqnIklv1sTuC61XVxF1b9OG4hWgt2du0NbAV64rRs7ZQ4BsKnuoTFA1IlZouebtRIvmElI0kmw7OgmOitqCZNHMUjA0MLJkLBkpE+iPRsHL9gUfoH9v2QL19gXtWzbSGDrVT/qd/pFOi2jgy0LYDHrboOEfKYqQUWvCHLJo2ocSmrbffuzqYFitOTJKA7egL/SDm5qAg7QMR3qTZinjAEdan4+0rTC/7B0RmFaUbiqCUBMcZVRuM8nI0ECQUBeWRvZ2gqWFuThDEyrsQdvY/9fftJ8mBNyegEPqWnrtPl2vIu+oIz1Dc6jde6h9ANzevALXvUQs26fDa0Lqk8YccwXCSiJ81tqbm4gzqAx/l2PVFAsNKqnRi/SKuLoSN9SupMisSEVKz1y5QoBJoniFFGvwsa34V6CQym2kqm0w6+c9+KyorZstdYTPwVuSnCrwiAp4W3KgCtxFB5ehTbdGOn5uIj96VfkpkIrU34gh6tRyXtTxRGcfq9A+WqB9VDUPNEIzc1SQATMRIhjaGRlZ2qKNmJrJAxsHJewOyaRPtmyFBod2FS9y1RwWre7QOR/oExrwZOF7GHJ+JzQtSGmgiPJfMQZNJP1DM",
                // "U3LWlicXqfsb0rp/CtA4Cb0egcJYLgi+ND7VUTLtbL/Z7QI9qIGHGieWlQRdYI48wMRZzPeeQ/BFHuIWq8smNKL2nFBK9iJB3f0kCLO4oba5zZf8Ius35I+YWF9uBvUXWgRvfrUA5ZdY1T5GJlqx462LB8L0boKvCXNZ/CyzQj35WOnhbeleQLjfmTZQ0UH7hVwZhrWRT03t7S2N69rasq1j0LbraOPT2TS55vAdsgSv+BF/VSkxPMH+jg55lWmV3Rvj61Ty/VmhHhqavVmC+aAfyJTXH3RH+arc8VuNFET9hrV1068pg4pTRWT6RNNvM5SDqvwwPvqtL1ZRYr1aZEOt6qMe0LiYQ6ImrtA/GdoXgDThcR6QiJMp/nGmu1vNduNaT72/FHu9IEo8kq+VvxYYl/OnzcfVzYKrCsebQ2V3vRh6UtjehGaSEbGTN2KeyXNUcJmivuoTd5L3wm11pRrrR0ME1Dx3F5/RXutw+DOaJ3mOgfGZjbgJK80YUsj5a+FdAR9j45rRGEhbAF90IMthfTKFvr3/gNov1vA9MB+MNsiEZpNW2oqXZeGtqTZJeBz4ABNLymh6QcOgA8hkpa6vgun3po4/jMH8AWb+7ecqSOrx+d/xaviaXXDZRbKueex21wXu7PwLCJ8F+rUC6+MWS7R2wbMjP9JrmM7FRt3zfp3QgyNVHWNVDf+F3xXcplawWUr8kj4HLwlrK4Cj6iAt4WFWkvB0KJCuzPiUaBclkrHAoYVAknt6Rs66vFjWA+1FJfUHbnTzi8p/PEQfZGaCkaHSuAidIZucOlDpR8HfcWzQ3TPy+c08zudncuxSM9MF+GNTNicZtHHQRfbDQuE/JfQef0G+sMLqg/5q0/4+p5Mpd",
                // "Eqspf+cuIk/WUfyKGHp0w5FFKspx2XftzWlYjThnkJYzMwF23gH8ZGvAbtb4wGL3ruoYuw/98NkbCG/h1Ne0LLcNHiX80Fgct7hcvb8MsSM1eEUr+ALlxqzU2h1qqTvkNPrqXRwikooZupgYpsp7+fPEEfbAR97+2Tp2T4F+uJ69WjxPVMq8vL7snzUAe2KL81y/Uw2WsimJk1EU20LlOwMW8i2Ooo2thYE3s7baQyUzgZPN4fkz2696S4rj8GX9k//iDNLHxE95/SBwe9Oeenx1+eNmbfhNdFtCAH+l25Ct9kS4pHyzYMWeTTP6zvV3Xs6rkn5C7eS1+vXwm1jkYk9/X4dpT/lEGNe/QE6cYBUCWvLNvBOIxGPWTyPJ546EwrWu6gmUsvyWgjtKhYX9b60rJ7yq48L6n094I9ti73+LIMDnl0ZdE7ujIP7Gf9sW79gyj0hydv0u9OnoSBNxU9S24suTVr1q0laPUcG58N7XSz5LhAPgNvCeFV4BEV8LYQUAXuUgFvQ/4mjQhUeTshzmDLU3BIETqbCZ3BRdOUrtM0RV8fLc/j4Rbbd8bZtlAbKYKAhwpdLwsQIjU/Qm9IMoZN0AM2GcMy6KM5Ty9QNwPqhliuyB2LL8u2GABoCY+MLkhWRly1ymlzNHiCbHhiAE8gRBMnxNE1tK4BrUvXCEs10zG2/S6aq4maiKbqJxKRGJ6eiKc3z4N00QtQ2z1hhGBmKpjBCE19egn7BYjbSi3Vd0VL1AbvwbXnoNNec87RNhzjUbqMyp5FQRM87JHsS88qsksvSk5X5Bagf6X4FouaAplbdk8RI9clVgxL7+bW6PYx23YS7LVvK0orJzRYzPwNze0tags2bOzta4vK2jiDTYW",
                // "FK58tGpVxbfziPS7JK1ZnmtO/Op5RLxn203dT6N2ajaccdoo+EGDgP2WClU+S1/bm46+ujksL7ljLwKS9gzJ++Xy37omZQ1pH/pKmlq51njigMHiTf65BQ+M6ihp2Qa4Rk9iIc+5UTMavdTnmalIJj6iAtyUL8Szp4C5cmh7E5T9LJH4hBP43SR2qx8H/KrpsUT0kfqILGVo9qpBYz4NL3Ie4/2eJjXnzKu+p+JD3+s/jWzhq64gRW0eN3Dx8+OaRLiEhLkP+u+CKu0PXjMC3SPwbsWboZhjXq09ERJ9e4ZVj7lQhf7uZhIgMqrdRZ79+THpLG2MHSyaNkYkJvhTY6Ryxic5zOSpkWbL6SAVmX9SYmYj6Uhq/oofa1XeDRufj35ydVNpLXBWYOSXmWMiEc3HeS0IaQsPme2lpad2quuiz6uXi0em/hHPFrdrLFJdDE51XJ89o5mJmnv606Z85Yqs92d7Z9M7PYfenHQmblRu5L/XWpA7B/WxnHx/zvJpaCrkaR3asaWD6lYMybsU8d6bGes4zR6rbey925RGu7A95mIoQU2Kty62ZCLowhwLaWJgYlztvnU4KoLVRg+C9ScfActdOeu9Y4oFRDevD8Ky5CYcC/L9bEHcQ8WmU7WNGnKAbi4vphtPDYzq8FMnWt4uSilLXvE5MKCRA5pUVKM6j/ptx3QsVAc1cS6NC7eaodtH1d3p6z37ofnsfGKUb0N/q7U6afXxsyPE5XktGGIOFwVb6qulFCPnrCYzJm/t4Xfj6+Ffb094mfDPN49snCcwG5mnWMGpoAz207+eQSpj0CSg96KSvwge+AdqiKirN3q6SK1F1jP62YxdYHk3aF9TQCFrTu/Ubjt4/YO7BgGFZ8QsO",
                // "+Q/7rslpGFlcDMEnRsS0F4o/kJcdYoaXLXq7dXNhQuLrNalFSTr5X6P8lXT/yfjEEQ/oUUxMvrkR9/bsxNIu4mZmTsdHjz8X75XIzWkfLW76PYx8+QzG5lUxkR8mVzERZvuctsoFaXckTv+a/pfS/H/FFzWq7tv+kVOlwefye84792a9td7s6SdQ7u/Xk0p4RAW8LVnKx707quGlKhB1URfjL4psbKj1ZWZKLrqJobhdvf5FzNWZfrFN+5j0+Gp8gEwKC0uInLX89IjGNV/LhuEhxdOYBWk2ywL3I/aICd9ubax4qmZviLZj8ZFF2WMahMNY3Z4GH6HFO1sCNPTfEJ1xzxhtaelh+ls6t7D9IxuaglU2PX++inlpNgduHB7WZmSfHYegXYcZvrthyLt3MPw4Wltx8b1cOlOMiHqwad2z+UteJK9+GMti+wVCFLe4nfMqAc5yLq2RCV7acVbgLb0O6ALvHdz4PJ5e37subNcIcbl6Ik5lOXplHC3LUX8lZqYf98tk+tuGh8Yqd1554F6jagC8AK1TXCIiXPAnE1TZ89D+A0JDB/QP1XECb2VUv7YftmVt8L5sMR4cVOXVDP70SyaHvWif6tUMTuvVZ2ym7DCjya3DRVfNqMWtA3kR9avAW9JThLWfh/CuqogKeFu6l1lN2VVNjtAApTbA7JF4sNGULZo3tzHs2JENuPHHDEbc3mTQ2KC2Sa2wEZXaKF6f+usEAJg0TjmkUisi40QWVHgg+qzK5Sza8nSQlxEcAe4KdsIoCNH0+UqTD62FTZr8K8J5QQ/GC4s1jdQPWWFByP9Z7VWu38p6ERtWXuZh8l5CcKGKSNbES2RydYA89TVtH9UrZsNc6yZa2zDjJ2JYbiGVp",
                // "mKCo9bUuH3+mtSfOxo4Fu78GfTo9YxpK7fSG+tneyX54EDMSVoeMyuZltAPpSXik/WJBxPVbUXN7DVDN45VD9bZ40WkWG6PJp+1R6Ri/yBzw7M4tMc1Y7cEMHtE5DNT4ik9xcxx10m/TJSLY+MR3ldbRyGL2Xix2S83Qiq8jlIlyvDg9olfd71FT2VlQY9bt6BHVhY9dTMxe+jQ7MSlR4cOPdo0F0a9eAkhubk09eULuj63NKUoJfn9qlXvk/GCEElLS1VZNflnel+w7f/JR2p1o//fjMkmn8kHOadcW346bS0n2qiwC7U1uGqFBP5BBkjYJXXZpUn6HxwPjZTtIksUn7D5bVFy8odVqz4kJxd9Syq4SuVccb+u+QTK/fpeUgmPqIC3JRs5PKGsQD9ErishXEA46S1N5pZwQZMj9+L2Zs3fYE0+yXIMxWpZzgWwrF89yzGSq2Y5mhxV9+KP0xz1z4ruVfMcjA9IGcopO382KEA1rUo3jDAIJFZNM+qDpaZ/1RCQI36FSUWVPKP4fY5oXi3HYP6tTDYjxh/Na0PrillsbtDq+oJGg02NhrUL2xEok7fRSZJI/1DUGrphlNobMczH+In6JK2Qd0U7QZvem5nxlJ8tq9hYcaUh9zZW/H2AmYqiH31l2D86YE5G5Jy3v17dRP88Rik9ZgXmDdMWJO8fN4Gqb15eAzUzi6GJtKi93fCuk4YOHt6kU4dL2xbfnPnbpTaTJs8a2i+4/tcdbmxfeGnyTV3dyRsrJG2YJFoqvMJogi5DRk4sDHVDV3nFXVbBJmh4/BBYZOxZdu4dpNKnR1/eGbPKIy9zz4xhCf0PpCafVrzILE2YU5iR/rSdiSEtvJlGl4HsmhSw4hhIw771TD",
                // "icuaTEmghkSNkTMUs5kYjERJcxlBc1HM1kWSmj9OIq9VHMje08Olg61HFoENhv2qUYljXAxBIPH5+m+uJ7fRMQfLOX8DhY9kxxVq4SkS1YMLHWFUuYDNIqaEPzDez/zkx5MBda713iuStCmC3GlxDQn7UtHoRT4s9qjw3HPDOY5XN8KlbjGMvnT+vmnIomV/4aqdTnVl9RheG5LSfILB+D1ciD06cfHIlRNb9mp2vR0T93rqnJVXVWz47cGxScGcloFkRGRUWq/6yglFpBqdVbUh3KZ+oOUgmPqIC3JasI48yVEMVTWVd7MeeVFMVTzS80R3MNnGG+Aczj8ZyUBksbWXt3QlRn5M/XXkxpV7CHtnWgHZ7a1IHWYE+70Z/oj2b0R8SwRhpbukEaWUIkr9LdDNcYpJ0ua6v1AOblf/AdeIA39KXmgBkt3Ul30Wy4R1vIRJMheGuIhghOmrMiETn/mhzOvzHiQC06mmKW7KhjqrYACT0nNOznHjvS2kpzBbozeeaDs2ZBm4UnNDkmNd+Zyn4hOK9KfaW0YtsZuzwJEbUYMYIY8wjyOaxfChn/g1qN6mn3Z8nrdfhMnOD88BGdxMe55UwmdzrqbibTHa8S2fMykYm5YbrYXX1HSlXfF7telsxrg5Rf+qw2VTPfex07d+IZCbNC7GD82TLqdRy0i8sFw4fQZds2+sNDzUvBcOHhgIDDCzUv+Xr22M30ZVoaLdwMgvvaMWPX+/CYdV/xUjULr5qQdmw0bQA+cq/WAkEtEmJk+JnwpWil3u4g+tNe1+iFjK1gti981zTLurY/0Lx8jxMQClaZe+j5n+YfDvA8tHzBQV+vA8pV1Hc77Hq/C0uVt67DgON9wjvFQQPQCzsxmGr",
                // "oetqdvium606VzLm9OObZmoUPF88rWISS8/jTked39UlLrgXRGBXxSRQCu49ff3Fq+vnR61mJDUbsSjgKlmm7MBLFpwU3TBST/Y8sTjjgO/TA/EWHA1REvZ960WbqdcrgtpM8yyOSR+RXQqvUV0sWFW7Y+C5xaRERsNZM5Hm88u7IPI+tIfzHirPYbTsE/OeicxnRJ0VE/q+lZ8zh0N7Oc+uxxJmP/Nr8U7VAeLu93z/XC5hJPWI1g6cQcrGiZvBuPq8ZLECipAUeilTko30xoNQTzPn2CAWGAGC/KfCkQLNbSIXHMEizW6aXhEelw6WtpcNVpHT/HOmn0oPS4NIOIGEJ1b5tXh6dkpfHcB4mRPZVNeLYLbQr+MB+xqa8imQjWjMRmwhKKwetjLJ9yULFDDpMbSXeoQ2byS4hZcShc118DcuEZjtTnm/rY0J/13df7ua1dgToC/VAH6apt8y92HWIOHbp1+KYa9BgWXD6rentguN6uG5HugPLHspntBzwlReluSPwH4/zbKVFq1MzmRuEoQHXueLyiJLfBkrzgkpXDpRbT+s0b43P5pKkpJLNvmvn2EaF0ceppXT23bsQX7oZ6io6XrlCw65eFb/TtHf5ag9NLyujGbvbDWylDgymcBP6QF+4RUO1a5735Gi+5tkYc0/rCnp8J4PY0cjQTkA1CKKBkam47Dndn3UQ3J4+BdeDWXT/s6tPx51f9NMzGJfbHD5APrjAYLiF6/Et6UF6gNoUQw1YBbFlEHSEjqVzywjdxFezthIiXtHV//miryGIV2heTWoKZdzl5NEcaAEurO33OF56yF9T7vechAo/Yl6RH8uCkrnCH4TvIlb0C9w5dsJ2X3p7D7Q5fQZsdnpdO05D",
                // "xdT7wpWpBzb7hXzr5rd9wnGot24tLd4RmU/fnaLedeh7Ruk4jstIthrE3yGsq05ECwv7qimq0txBmwopTXkqpDRFVS27Qk8eV0JnOeLQhKjjYaEXlmVmRmYGe60LHZUZLtHriuNgd+IHaLoB4MzmSwUAJ+mxRss0u/zn9/NcPXLMBj+1e/LIEUtd+y8YvlO9bC1dvaewpUFTWnI2nb5dy0YqFTWxjq0T8BVze7BFxaHYYOiIOkwVp/4wW7NAOqnJE8AKlpcoptHlalMDWkInwt1IRdYHHv3zUMbWiMOyXMbK3NuGlVGNcSqIPF+VtFKFnkAvKEObGr+mTDsSGn5yZsCJzvTPyVKIep1zza7nI4+DVToGcHqm0Qq6bV7G+JxZs89NhO52rSQVfa/5vrNLFr18/jz98SCTYAdW/XxQw+akI7c1a2ZsVT2KIFZ65ioFG171NRWXL6Lvb80dlwdNso5AowP16E9Ns1MKSqGO/boz47LAfM8BmnNz2rHw0CNTh66OdB53vJEQeB9mQkOoCZuh6arldGvsVjqDbvOZ1TOTXj13jp49CvKUc1HTzkb2mrHOe/K56UxHMYQoftRaZxAPtIYA+mJMaZFigHq+/LgO6NEXxUZ8DRW16c5t8yvyDdeo4GiNM9fe2hrPWrm0G7HMZG0UdORzXDaTTU2NP74Vo27SI8cAxp+YsjYbIB1anDwONhkAx76dfDQCT/TI9TnHQrDBsRlRJ8IBRp+IDdnoD4Cv9mGbfAH8NjVKAWln3J3kujWt6I4N75clvV+/g1rVrJt8J24nVadovNaOGbd9+PDt48as9RKPuq8MDlw+ZMjywOCV7kQgu1AWP1UT7dg4m0qmRrhMz0OSzkqMjKu8QxlXO",
                // "H/tjBQnLAL9m3Mh/AL94+AR+jDLFDo0OZpcoAYDu3U54w/Qe3uwUHlr6nEcnGm+ayK7jzumagTB9+gC+pi+oQH0/qrlZTvnbYNFEOQd3WsvtP/+LHQ9Sksmfz99+plJvaJSvSadnc7y2gPor5JUjSSZzDbCe9hLiJSvIpKSxEBNwiASIXJ/3mJOd9bjZ5RsBr+PNWX3unmE93MJuy/F58P4fVxHdv8DWul03j6+GbsvxPad+fN5kew+F9tH8efzbXh7jr8J3ic0YfaTUPZAqacyJd3LaxE4zlbclMtDphmYQzuhyiqOEipjqRFu0xFkpYx/ktj4Cr25eeyxmTDAc3j02H7juw2e2VM8Qveqn4/MCJ37eP3GB7NWzKGjZwT474iIvH1gLNT2m9PJqJnRWHq78SoQt8/+fqfn346z/PvN6zO+a59lq91Kk8QNU3+6Hr30TvSsizNW/h5Af/bd3d53ld/IYyBtyaUvd7c3aGYQOorlj2XPhRAehw1YZcxcNG6OZs1fZWsLQo8G9GmDHR7TAKZ5uOHR0U9FSgYrDr5/PtXDfepUd0d/B4ZDUyyEyDV1ODADFbE3f/9hE0XoQY80AJPFbgyLG8Pl6K8pVhwUArU4OvkxHBPKniu+wVlmQdojDnu+7vOJJ+Y7HnHtx6Rqri4LBkLfeQFdAzt5LvEanDhMSa8q08AkLRvqru0z188rtL2wwH3aNHe36Y5+wmDjY3cXdrIePnPA0Li+3ReEHSqOXfRu28SDiQ72kesnG2s2V5VrkSZf4Sfr63gyQcK1harJEJ83fOSRXXtjzg0KzSBiNvSbF9AlSMtTgAzt5XT6NC2bPlvbJ25oVZ78xYy62b8t6GwZGDXQN76vc0LYoQ9zFx",
                // "VtnYQ82U1eN7muEDjNnbV19HMkAM2ot3hYNZhr2sDI2FzWZ7mEkZm5IECz3FNgNCA20GH45mD64lSu6A4zhBlQYyS9T9PpiqwXtB4dPg9qCDOYBUciJlU5JkE0d2iAChcwNTUyElW5p+gLHSYwYpjoAs1C+m4kNAMfmJj1HB7D1nn0nWYhYgJnxHQNMWkjvQl/a3EWVtClMJl6671//v7Bc6TnTb2FvypaMZdrL/ylicA2S1WDi/Seqxo/JyIJ1uGqS1qStiwCsmK/HcYLE15VqVtbgOY4q1gd056vnrLxYKXc4PSE3svyU6bE2baLfiQcTclf1jsh/cij6Ha2cVPUy8FEHLRqyRZouvbnmE7PeyVF0JTB8YEOpfqdYn5eC802J35rHxQ/mKZMSOotzkEl3ydEZByLuZW8OCMLnAOk7KDlCnQsIHdapqx5WVnMrcqMpu9HzIgT6VPR59vEzfQ+Z6Z30gQIHxwfZC8VMWZowZYlqxwC4wdDeERSL3UcvQ/NiECSNb/oWyrziAsZjpw0syQsqhK2e4ewOKotktiwFbV2Il82deD1L1ttuYNtXrW25nt8mLkQiZswznAefrXxSdlEUKTSPGpOszP2QH+4BW2gKRyG1mtajLuw2WvzxJo1603MjIzJSxrk/e3Z8ND9U+vUKvIY7D+mtduGh/S3/S9pYll8AsgQp554K71VH6fLL6/GbeoLAzfMmrTJA6DnWs0v6dAX8qE9tEDsg/cfork07I+N9Jc3K0Sx3RjXLqO7KBRjs9WpKU93j6pV03JAm4nqwCETEsD09hqodWejdzJ9Rue8LKZz6IdFNh3q3GncyVLsPvan9Wu+GzLhxOSo6/NYZGhWpsAZUioreS1kL/ruSIS",
                // "oOGS1FgLOCLnGIWt0bbzLFMJfHLJWBwmuaJNa2UbM5ZB1OshiWqLfUPUaIevL3oMNkVgtT75V5b2GBIEtgKO5EnRn8QK4FtL9pZNsZAObktP8hmazG77QYFlYqLnLrqRnhYVEJntwb1qkfIYYE0vSgrRBT2SnzepYhNZ6RT7+kg0P0pX7uAArzCI4gkJ3lvR30+sP58x5CK1374bWD+LiHtDru2fe2DJsE323bQd9s2kT1BJeZ4Dpvn30SQY0LH5Yed0o/hl0PnIEvn4SF/eEnj9yhOY+i38SnPln3H5onJ5OH+zfS//IkKyyoFFW8S1otJc+xpJ1vb1iIQLoQwLEgV4Sr/M1QV6REq9rwuk7IUUVWBSul0IAhmnChbH6KRU7ccfSt/opr2/VakEEMKKxgqVWp3znE9+FA0YIf8F+Qju1u16s2lvM+JSOkKcJR4eXQi/ppRSF4/Nc4b7kLj4opyO5q6eID6gGRBxN3TNZJhk8jybCfUVsZVtFbEmstq32WQ1S+awGeUfKn0FHmCFtlR6z0XeutpFDeBL14/TpP0bNPD99+nmYUX41E6GEcSfGSO5SXFXupDiqBgm5I2KMIlaKQ1vbg9xt1EJqEA7J1EKgo9BP2qrIRshehFxFjMsUsYK5qjPRR1/KQ5UZW3le1j1ycEo3b0VsjteJPd3Chp6N/B7bdlL0gTwVYW2deahl207sIe8bbNzFR0VyvI7vcQrzPjv1e4LUO2PrSzxjOiQw3g+hpe0pXxuzMIQ9H1REYyPcxrbsmbiXr40dJiznPiwIBOGMO6mJqjPCD3L4QaB4Fhgn4nndzv6qvJh/ypag+ZS9yiuk4UD7iLlAUCdHy2gxo2pP+8B5YNnkoTJNMeM9RVFL",
                // "qKPl3QPTl5R+YJuGoDeaWtiePZW+4tyf4FyeEJpx+8iiNQUXqMcrnUoZ0zkLTOwcHQWXOnX6Dqz3a612bWroQ73xM2jp/R5Ov4C0YCIfY8y4vCGa1MR5XDWNgWXu01ikd/QzrkxCeI33uao9RCP108ieDTktvOBcnFbkc11xfHhdk9SvhlH8PHrHT+lIwxGivWQYCRW85SQtxtH/BSOtxChUyaS4pmYijzVIvY91ZVwV4UeKm1eO82MNirYVnKJu0hFvb6iHNnjqvU5Xgh9EyzLqquJekY/3Z/j9Xmw/TZGP7b9XEz7jswVvqZ+M2kRVXkJOD5G7oocijUhED2U3B3tWvbYH0YO+o+HQFGJpLC2AlLuCLyZmmpS6gi8bg0zsNai813QwN8FOYGKeCbHQlKKjgxqQQgvuCuF1NWnSJU1aXaSNlBTzFGk4rhf4eF4QOvA5kYnwWA7P4/A8wQ7PAEako9xDbsAoONuDITia2ODRSNFe3UZPT/xVOHxfmEd/os5GrQ1pD3qlWg9sqrQ3w6Pco+Sq+Ku+vrqNor1wWBMNHeGUYWsjOA0dNNEoC7SECLmVdI9728pv1VoqoKRMAeJNUNJizRp2xLYyiZNdFHnatqN1bUULqKW+oegXp+hXki00gVr0DePfVNgsO4mZ5b5Ndiq5JWbSN1AL8dQki+S+inM6PLqopVhcGndSiuGHk4uk2afwCi9PERFMyWDZSSZ8N0MjHZeVlsTMtPKGERJSPKdO9XSdMsW1k7/DVE+3yZPFDFoMSvU2LdRzqmTlMMzRbcoUfEFB/EbEDzVnoIviOsn4j2u85CpqvQBq+YFMS8T2IFINjZb0S/ku3XtCfXmq1IvtsvCw1i4K8lcGG1tT7ZoQf",
                // "6kx+0OKODFpVMb4Xt72bkGCRoo4OXF0RngfT/vBowXBJfPeOK/ALvZR0/feC/MZ3s02Yi4fz9fIVf6XLECc9hkL4D2+bAHitM9ZgNBfbqU48nkLkA4woTVr2JFZAPjKLvJmXdtqFgC+OhOoSd8yCxBnyk5SQlULkBLoW6jJLAA85b5ykg7P5ywAPPGAl+yaMBsAa7SB/P8PG5DiaQnI6m3TPLQDL1k7+Hdil55TMZYawUC5hxI9FfmVEPK6rAxH9m95qqIuQq7z6Crg3JQUbpIn55qvWypYnuBWGiUtoH9Lns+ehdNG8JAQKNOUCQojwiNMEGtnVPKUUsQQJgVKV5W5RORRxNbEAnTrdUJUv36aV7AJWsAm+p5eNKVXlM5jNAnsAyxhq2Y4i7hirEJPRYgh9jRW2FhZOSpEW9HKTKHAGp8QaUzXj4eZNGE8jDK+bQyjxtMEmDmerjcWY2Hnn6fOnDn1J+ykftor6sfjNOQo9OTuKOEfhNDuRCJL4a58WdWIfwvXlnTjetblMhbmWC/VLQuDsYVo/Nms1NKoalYqrIRJDuP7D4r8mpbcsuzb1zwJGhw8uacG7gG4Gx19F5rv3AnN2RW9h1eGW7fSlzt30hdbt4KRmCL8YT9uiOvEznOcunVvr9kAfnQn+KlfVOvGUeVuA0OGYNs2juDlNqb5v8ru67VUNSNNiS3pi5Lo1rGqrXM4mmsrYLjURfA1yogwcYiRmalAsFpp6WBkYyfwVylZMJGNTCXhwkbQ25L4Yr0hVRvtChu2xs9vzbCwVcYgGaY8StxC328Uvsmnc3G/AcAOaA4x+XdgDphvB9hO79HYO9uh2e2ZMOs2/WP7NvrH7Wi8hKYS2QL6G6KuxQdM91sdgD",
                // "inB8Rfi9oA+uq528ECYu7cgRiw2L6d/kbj7tyhcfS37aA/Eztu4+hm5tOC7Vtpwe1ZbK1loqKZ7Fqx/8mIr4qDrbEx+xrL1lD34x8zSlvpuaTrvybRH6hbMvyVXEqS6VLBQ9FMuK8pEvQ1eNb9NmsCheCYGCKQPVKwNFRVh+/N+STfrb4oKMTFXZ8z53pc3I05c27E9Zrg7DyhV092lILxvuLZwx4TenIwHnuweSZmSwOUhWiFbZCGbsuUDZ/d7PXbzMLa2tiEwbSL+/a8+sSnv2g7xN0/5OXTH777vbZpUR2jbnkzJgz26jTFpV7Trct2fvf8pbQZfvX269PDeMnh0yepa/dZTu0nQO7mYV07dbft13xLj7m7l67dyWJ8mnhECkMe+BqKh1ZIYsInQnNirKWs26mcNvV28n2AKTeSC6j69cyoaVOmRk2LUqwfl3Q3hj6/MW5Z/mwwgO7jZm3ZMmvcjB1sJS5CIhCrd4WIvO6Pw1E11Yp5M6OTu9vXDm5uEpG6l+ZI37s62LsOcfia7faahTBQDSJ1tXm3rW4niglec2ZgwpvH+hZbI9afezMhIGCGvE4zWuqe5RtyMUvTQdgZMiWKVRfQTM7wLwB5Bc+wYheNucgcWhxtP+U3+tOGDdDhN6HXLTBTktIPu8DiWDZYpH8g7HWVMCw0SLETfUUP4sGwVCmFKpqIrG6n1BpF+WeKjh21axJW7UReQas0HdGBga1ZVQM74zq9wpI+nTnXJcyxR2BbiGsxNugbSXCL6iEMGpjydvkuSldCvW1zR63vMaINnW0TGuQkCoOi+vVyn//36i3P4xYJ7d1t6ZKWo/oJ4jgXGGsd6ibXnZji4NuhU+DAer/U7Rf+bfDgRcEmUo8",
                // "9IavzRsc+3xq3WBgR3CvAuf5PJv3Grxo5aPFoE7nnjjFxl6YmPFHX7+jdt8FFsxZj+rhFtjpjYh3Mov54iQirVZe0UdBCYW+FE2q3Hr0IPf+SiHgv789fSu1YuygcLTvVXb7Hka90aW3Zws6yfMoolSbmJglwx9nvq/jAkOjnIF9efGVyr+WTHgsDJJIFqzv5+XT0DAobmvVrcFqY5/IUv3N6FxDzBLFQ8kfMbbWz0MZWt3lIt66lJaS0cBJ0hJQmWnpCUNLvcaJaXDomfNm3sZMmhS6eOiJosfhcmHNjfsLFyd+OS94Y96dYGLAtvL/3CJdBwYeHDeo7zG/AuC3+fuuDwxcY6hmtnzR2WwARSDDKFq+6VG3tykRh6Ij2HCw4p4XQKNGKhsEz6V6O2I6+1jzXO3cP6nuKI1A5AvEteyw1kVwxEpqxNxliaEBwiuGx6mf6QpcCSkG8XwACpQUT582bGJEwvx60gZqgBzb0NsbKN/T66ZMnvjtx/PDxU0znwwjBLL87X+spH5sIPVoE9f4QffYWHC7NYa3CCBFvIPUGfA3SoZyiBZ+EFQMzE/b7Dp3i7RN578WpUw+7xoWeF2qmQXD/sG4DvPxdNp35PmnAnHmu6/VOIMagskLxDWJsi9L8pxFpMf/yFHgG0cOGR8+bEBISMCvU23O6UCBEnp0180RoXGhC0rSfDLxXBToN8fqmh1vakG+6ubk6DV/p6bbEZ9is2noGi0YFrPRgM9KbEKkBSs5HZDqOiIl2ROzZiHgLyk0jaJpwnS6Ubp88IlwqpV/Lx08WuQnFWo1MQP5/x97Nq/HP2bYxNjfRrSLquG4y+0yE+ECa7h44Jy7IMbTR9a7CLc0TS4XF/CHj9o6JzDPw",
                // "WhXU2yPc22d8O+uWgvMJ+qDd10M3jY3IDGacIq1XmEk1Ia0ZtXY8kUDU6Nr5MFQhVGENMibWgu2w3QuGTL29dt8jw79qjxkQE69nlTkyPD144oWFw2NjhzmFdBHEmQZdYi+v3A+qlacWd+t5ZudAH/+No8J3jzw00d11vK2PndtEAmwPu7hCayWTMRZiNIS1gkKzSxykKRVn6Z04pY4hIvFBPktxTBuX70PlTqvSd1UOJOe06oqQcVUrbr3gl5mpkaHTIk5HTT81YVro9G+jrs13HtUpNsAppFv0aPeICHev8PEG7om+wWsMVcaJXh7xgwfHe3glGquM1wT6JrqnterXtvfwVgO+6jkMHvl0c/LycurGv6r0Qw7fMU3yWMkK1HUFFg11w6fbmcbZNeOM8ZCJbyVCvYDdC1xQlVkPUJUhA+fE6dmkhXBVzu82ssvsEb1CHEQxWvJkytxHPySfXtSt59kdXJkTdgcdsvNxdIno7NuGaZMOQMs7qtLmu2CL94rYlyWxPFJgnulLV0pNhBJZSV4TQjMQMoziLjDhCULe6CBhNEO8wdu81UGCaKr4hkPe6SDeNENqwHsV6SATsM3vHPK+vA1CXgkUIR90kN6IeQVvU6yD+GCbUo65RAfxQ8g73qtUB0kt8xB/FpxkJZgSUsIhJFT8GVoixAwhuxGyt+yoeBzuIKQeQvYiZDu1E8LFKQipj5ATCOmEEMIhDXQQXxH9nspVqw2JeywJPZaK26JzNY8lkXKfxXSEdzd4z7e6nkEi+hyVK48C/+c+Ryz8J6fD9C2hz1F1146JRLSRSfxdxf2I8/+BHxELv+xIGH2k9krlqR1vTr+3hDNbq02P6jNbIrq5zawAe5ZybZawnswKE",
                // "PKO4yrluASSKqWLPytTdG98urQZfjlHRdFRSheeakzAJId7z1QFbiGVmc/gb4a4nfSCHIOPBLJXUUM8rmynxeHB+uNvr1hL/UasJU/IycG9ZacZhu3iDCFclc2jqZ2Roy1ffWQeUdg+efq9riM7OwQ735sRKdfDVYQVA25p5s4o/t11JXiyvp2wL9H2da4rsAFHfTPVGwkEOzsFf90pqPu96ZPlesfpnhUD72hmzyq965JMv+P2mIb2aKC1RzGHzU4xB+2RaGcnh4SJOeIN3uatDhIk7hffcMg7HcRbzJEa8F5FOsgEbPM7h7yvaLMfR6uudrQ4pDdiXsHbFOsgPtimlGMu0UH8EPKO9yot55AQvVwVkWyIWrQhhFhDLZJDkDvFS0J0z0M+87xIMYg/DyJEv4PKgD9HqYkNKZLN+M7MOthOQZ6V3VB1VLUihqQp6UC+IT1RrxUeH82W+1THj94C4B+ei2AL0uug4/MXZo8IPJqw4Fjg3+4ho10Hjx3lWWrIwcNHHE1YeDTwiVvIKDeXMaM8lnAnCrHhU85MnXJ2CjtNPXM/3Dsx0ZsdxGvhCP3Mg+JW3PGCYCNflgapUrlNGpvj/RPoQvPky3CZ2uJzyJAvi1d0z8HcWPidXoQuf5c/F2CI/EpSq1y0GZrzlz7LJdW3xX7mwyHEpbouqfU7/ldcquuf4AJyQ86WlqkiiAoxiaK5PWrWRJxz+Qp9DSOKIVDOZhWoOpBGfetg6zz5mHRY5cTp8pdI7TdlZmhPzflaKCRfODiv2zA3t46d+/9wKL5vQL9B9p36ysfknbkt7Vv6OtfadRpa2rfyQVwrVBelGP0h5bgcGS7dC6gOl3/eoXinYa7uHb/unwsH4/sOR2SOfV",
                // "UXlTtyoaVDS/Bh6BCtN2L7VdlOWqQi5T5DWqQeqCLXruGTPfJzwVrlTmp8rCsI1X39VPU7MIFMlTPELnoeuv+55n98TAz5n/k+WM74wve+BEBPs0a4RVSImYy2VSJCU9kC0xxHB2sbGHDOwCcOnt6Tx84FGD1B5V574qQFabu69uzpUINXgMvu6DVTWrFR6g1gxndkSsfV/uKOQ5okuXnxPWGSlbhD3JGlSaJqzXJtj1qBX+qhH/xu4+d6NPoijfrNH1WnIVbQUBA9UkvbS0+wQqeMv/KebCnoYhmpYf02H4i+NcdwUFNbUwtmlZXBK/QfAIEoXZiOsg2n6wiKHw4Jk4rvyc01SYfEHVZZwiSQhIkH1f7a9rUyqrXXV2D7dxv1g7XtDwoTsf2krPL2jarjr8fwP7pXv/kn7UUdP5Vy2QB2wEijYD/GGK5uYaf3RfKjMlLSQPEICDL4RniN7NGFOrGIqOPzC3iQYR2eN4drWJeRd/n61p/Dw0fmDeKpVa5jYPwDCgLSNvVkcekhzS7VOc2uQ+JS9eRDwtD3XYWhtcSl4tIszS5haJZ6MoP6aNJ1mIxa/U9MtXpVYnp94kuYJDCtkI3vQdZJpydyC1CiBZhVCvje8CNb0O+jLjoMRDVAXSEte17dLjgN5PZ/0ag9v5zG6xUf0aidq37tAKRm3v+mAXCAENVlVU2iYm+4gPiVYCid0qQfFpO43LJlpT6K7zIdHix7q/pJRbjHNAQzNqaGirOCz2H1JPXkLGGoihTfFYYe4vpk/bneiT/O3x2sz+gvzF//KnMLucMeOLd2yEroTAiJ1UJwfjJIFw6p2qYrgzBLRzphOjqfn0n+H88kxJChbe8MoO2hrxB3qP0rZpMSb9T",
                // "lvTDesz6NwjjVb3R8cKoc0l0H4Xg5xLmC18kIWYqQHpUQHF0G6VkOqejVqxKCbRiktxZS/j/MyTLRfiv7gBBFNt5bk8YC/3ZUiNLUJED2KzwFf9VEvnpvqFu9Vxru7x45KLNrL1B4gjAs93CPsOFXY2gJ+X9Qz+60AAEAAAADBN0fuSCgXw889QAbCwAAAAAA3PK7GwAAAADdVVDW9+D8fBxqDAAAAAAGAAIAAAAAAAB42mNgZGDgWvE3goFBtuH7gy9fZLKAIiiAMRIAq60HRnjavZQDzB5BGITn7vZ2P9S2HdW2bdu2bVtBbdt2+9uMatvm7JfaTvJk5sVh6c5gSLUNZb+F20XNibOOxFikUXdwVt15vUkuxdkv6Mm+IuzLhrPmY83rlSTsrV8s46GVqsa+PDjrPMPefG/phUXfwrWH33Swpzc1Cb+dANNVVgx2pGTuM/T/uo6ioKqNqmo8SnlQWCZLYcS3cKWjnsNZWQyjNfRjZV/qZ4jYKC79WFsEX/MAlhHq64lk51s/moTI1PSMrTAEOHfDV858y2KM/hauaL7XD75krCgIX/sixsjLOCsSo5qcyDxRptaPKITqzvioKeOgnfbviYs1KhEiZS++exd89Xx5xpUKWZjfqVqjkkqORXYuLJWHcIy5fVzfuTIMfvIVVsimGCrvYRH9KlUcW1RxYyMR9KGqKOZSn5MT5A7x8visGGsVQqTG9kFXMkFkMdKILOhJLUGtS1pqda3ArO/UJnKc2RzJsV64kdc6bjS28hrxtLeTwMvDcMANwA43cn4emw0w1cyB/OZgFDRbY7toS+piKslP8rKex1yG2eIYZlvZsNVKCS/Hffhq9aBzqbCGnjmSHBt1XsTBdrJBlsB2",
                // "WRobVC0j3luyEkkSkRhvlXmc+pkemQh+duzXL+2C6GgfwHaNaogprji4LEPQ3bax3k7AnnhYbdxANzEYg+RSzJL5MMsagC5iGQYIb3QVZzh/fVGf/95Y5ENHUQMtRHvOax7WKqGudRFlRE3Uo29oWa8q/myv6Ii5Hjpgo7kcy0n+//GsKxMaO7ejsWsYWjhT4Ibd38xs9zfWykpGNY3dClH2cD13mGE3QYQZhvXWNvSx6hhO8xqgYR3GJQAAXMONRLEOG4lSvlXGzanNU1LfeZ2PX5z1t8r8FrLtd5713I/Fcd5yYzMAvAGyV0pQAAAAeNpNwVMAq1AAANC0ZWzLNdWttWfbtm3btm3btm3btm1bv+8cCILSQKWg4dBkaD60GtoO/YRtuD68AF4D30BCSCokG1IIKYfURNojW5CzyG2UQmXUQtOgFdB2aD90AbobPY4RWFOsI7YDO4JdwO74ZF9e3xjffn/Q7/pL+6v7G/vb+3v7J/t3+u/6v+EYbuAt8C74APwd/pNoR/Qk/pI5yQ5kH3In+Z2qSjWg2lA9qLnUB1qns9KF6PZ0b3o4PZk+QD+lPzMwk4Opz7RmFjLfWIwtyJZha7BN2A7sWvY1x3EVuIncTu4h94ZXeZtPy+fkK/Ld+Zn8IYERFCGdUEfYIHwNlA2MCuwM/AoWDPYOTgweC6mhHKHuoVOh+2JRcaa4UFwlbhJ3iYfEU+Il8Zb4SHwllZM6SJOkO7Inl5Y7yIPlafIdBSjblQPKSeWSclt5orxVvqkxdZA6SV2gblOPqVfUO+or9YemaI6WRsuq5dOqaK21ztpAbaw2U9uvndAuag+0Nzqpx/X0eg19oL5W36rv1Y/qZ/Vr+keDNTTDMfIY1Y22x",
                // "mBjorHSuGl8N10zr1nDbGcOMSeZq83b5hPzbRgLC+E04arheuEjkQKR9pGFkcdRMZo+WjHaJfopRsQyx7rEpsQOxC7H/sTzxuvEJ8Uvx59Z2a1e1khrkjXbWmKttbZZ+60T1kXrlvXYemN9tSGbtIO2Yae1s9nd7QH2dvuAfcW+az+zfwMKREAuUAM0BK1AZ9AHDAXjwHSwAKwEm8AhcAk8coo6VZ2mzmhno3PCeecqLnBzus3cIf+d625zz7ufE2zCSeRO1E8MTqxInPVgL6NXymvi9fWGeeO9Gd4G75R32bvjPfXeed+TSJJOhpLRZNZk1n8JA9JIAAAAeNpjYGRgYIxkmMLAw1DAwA7kIQNWBkYAIxwBenjadZA1QgRBEEXf2uCWYNFmuDskuLum6+5uByDcYxARciIOwg8ah7F6pX+qgW6ecWBztombYNjGIE3DdtU8GXYwzYth55caF8u8GrYYtA0b7mbRNm+4l3ZbyHAfnbaMWGzrETcMq8b2aHjgU9c2hOrZIU2GKjmihIlQwM08s+gV3SoSlD0iRUGUE1/qmyYmz4+q2aIoGyGteF7+qLigOyNvnRndYaKoQnU+pvGrMqmoqmXzoihmOmPflM5kA8oWVXctDosSeJVbYJpZ5lhjQ5kbVd6IPnunvvXei6UmL60K99du829T8r0sKTbLsqpn8f07zWxndsvjV0VUfkE8TV6ckE0rGlb+gn1OP2d9m/QgNqfODdoMVb0BVQFRcAAAAHjaY2BmAIN/BgwHGLAAACxdAfIA) format('woff');",
                // "unicode-range: U+0000-00FF, U+0131, U+0152-0153, U+02BB-02BC, U+02C6, U+02DA, U+02DC, U+2000-206F, U+2074, U+20AC, U+2122, U+2191, U+2193, U+2212, U+2215, U+FEFF, U+FFFD;",
                // "}</style></defs>",
                '<g clip-path="url(#clip0_8253_17500)">',
                '<rect width="448" height="448" rx="12.4444" fill="url(#paint0_linear_8253_17500)"/>',
                '<g clip-path="url(#clip1_8253_17500)"><rect width="698.667" height="524" transform="translate(-167 -76)" fill="black"/></g>',
                '<text x="290" y="395" fill="#ffffff" font-size="8" font-family="Arial">ID - ',
                Strings.toString(params.tokenId),
                '</text><text x="290" y="420" fill="#ffffff" font-size="8" font-family="Arial">BLOCK NUMBER - ',
                Strings.toString(params.blockNumber),
                "</text>",
                '<path d="M153.58 73V55.984H150.652V73H153.58ZM159.964 66.256C159.964 64.72 160.804 63.496 162.388 63.496C164.14 63.496 164.788 64.648 164.788 66.088V73H167.572V65.608C167.572 63.04 166.204 60.976 163.348 60.976C162.052 60.976 160.66 61.528 159.892 62.872V61.312H157.18V73H159.964V66.256ZM174.249 57.736H171.729V59.488C171.729 60.52 171.177 61.312 169.929 61.312H169.329V63.784H171.489V69.664C171.489 71.848 172.833 73.144 174.993 73.144C176.001 73.144 176.529 72.952 176.697 72.88V70.576C176.577 70.6 176.121 70.672 175.737 70.672C174.705 70.672 174.249 70.24 174.249 69.208V63.784H176.673V61.312H174.249V57.736ZM185.923 61.24C185.803 61.216 185.515 61.168 185.179 61.168C183.643 61.168 182.347 61.912 181.795 63.184V61.312H179.083V73H181.867V67.432C181.867 65.248 182.851 64 185.011 64C185.299 64 185.611 64.024 185.923 64.072V61.24ZM193.025 70.864C191.321 70.864 189.761 69.568 189.761 67.144C189.761 64.72 191.321 63.472 193.025 63.472C194.753 63.472 196.289 64.72 196.289 67.144C196.289 69.592 194.753 70.864 193.025 70.864ZM193.025 60.952C189.545 60.952 186.977 63.568 186.977 67.144C186.977 70.744 189.545 73.36 193.025 73.36C196.529 73.36 199.097 70.744 199.097 67.144C199.097 63.568 196.529 60.952 193.025 60.952ZM219.717 58.696V55.984H205.773V58.696H211.293V73H214.173V58.696H219.717ZM224.462 70.864C222.758 70.864 221.198 69.568 221.198 67.144C221.198 64.72 222.758 63.472 224.462 63.472C226.19 63.472 227.726 64.72 227.726 67.144C227.726 69.592 226.19 70.864 224.462 70.864ZM224.462 60.952C220.982 60.952 218.414 63.568 218.414 67.144C218.414 70.744 220.982 73.36 224.462 73.36C227.966 73.36 230.534 70.744 230.534 67.144C230.534 63.568 227.966 60.952 224.462 60.952ZM241.817 70.36V58.624H244.865C247.817 58.624 250.241 60.544 250.241 64.528C250.241 68.464 247.793 70.36 244.841 70.36H241.817ZM244.937 73C249.545 73 253.241 69.976 253.241 64.528C253.241 59.056 249.593 55.984 244.961 55.984H238.937V73H244.937ZM266.931 73H270.075L263.451 55.984H260.115L253.491 73H256.539L258.123 68.728H265.323L266.931 73ZM261.723 59.104L264.315 66.064H259.131L261.723 59.104ZM273.307 64.48C273.307 60.376 276.139 58.336 278.995 58.336C281.875 58.336 284.707 60.376 284.707 64.48C284.707 68.584 281.875 70.624 278.995 70.624C276.139 70.624 273.307 68.584 273.307 64.48ZM270.355 64.48C270.355 70.072 274.531 73.36 278.995 73.36C283.459 73.36 287.659 70.072 287.659 64.48C287.659 58.912 283.459 55.624 278.995 55.624C274.531 55.624 270.355 58.912 270.355 64.48ZM289.187 69.832C289.331 71.152 290.627 73.36 294.011 73.36C296.987 73.36 298.427 71.392 298.427 69.616C298.427 67.888 297.275 66.544 295.067 66.064L293.291 65.704C292.571 65.56 292.115 65.104 292.115 64.48C292.115 63.76 292.811 63.136 293.795 63.136C295.355 63.136 295.859 64.216 295.955 64.888L298.307 64.216C298.115 63.064 297.059 60.952 293.795 60.952C291.371 60.952 289.499 62.68 289.499 64.72C289.499 66.328 290.579 67.672 292.643 68.128L294.371 68.512C295.307 68.704 295.739 69.184 295.739 69.808C295.739 70.528 295.139 71.152 293.987 71.152C292.499 71.152 291.707 70.216 291.611 69.16L289.187 69.832Z" fill="white"/>',
                '<circle cx="279" cy="417" r="4" fill="#24FFA3"/>',
                '<path fill-rule="evenodd" clip-rule="evenodd" d="M205.865 126C205.865 120.477 210.342 116 215.865 116H231.863C237.386 116 241.863 120.477 241.863 126V175.5C241.863 183.198 250.196 188.009 256.863 184.16L299.732 159.409C304.515 156.648 310.631 158.287 313.393 163.069L321.392 176.924C324.153 181.707 322.514 187.823 317.731 190.584L274.865 215.333C268.199 219.182 268.199 228.804 274.865 232.653L317.733 257.403C322.516 260.165 324.155 266.281 321.394 271.064L313.395 284.918C310.633 289.701 304.517 291.34 299.734 288.578L256.863 263.826C250.196 259.977 241.863 264.789 241.863 272.487V321.988C241.863 327.511 237.386 331.988 231.863 331.988H215.865C210.342 331.988 205.865 327.511 205.865 321.988V272.491C205.865 264.793 197.531 259.982 190.865 263.831L148.001 288.578C143.218 291.34 137.102 289.701 134.34 284.918L126.341 271.063C123.58 266.281 125.219 260.165 130.002 257.403L172.869 232.653C179.536 228.804 179.536 219.182 172.869 215.333L130.004 190.584C125.221 187.823 123.582 181.707 126.344 176.924L134.343 163.07C137.104 158.287 143.22 156.648 148.003 159.409L190.865 184.156C197.531 188.005 205.865 183.193 205.865 175.495V126Z" fill="black"/>',
                '<path fill-rule="evenodd" clip-rule="evenodd" d="M205.865 126C205.865 120.477 210.342 116 215.865 116H231.863C237.386 116 241.863 120.477 241.863 126V175.5C241.863 183.198 250.196 188.009 256.863 184.16L299.732 159.409C304.515 156.648 310.631 158.287 313.393 163.069L321.392 176.924C324.153 181.707 322.514 187.823 317.731 190.584L274.865 215.333C268.199 219.182 268.199 228.804 274.865 232.653L317.733 257.403C322.516 260.165 324.155 266.281 321.394 271.064L313.395 284.918C310.633 289.701 304.517 291.34 299.734 288.578L256.863 263.826C250.196 259.977 241.863 264.789 241.863 272.487V321.988C241.863 327.511 237.386 331.988 231.863 331.988H215.865C210.342 331.988 205.865 327.511 205.865 321.988V272.491C205.865 264.793 197.531 259.982 190.865 263.831L148.001 288.578C143.218 291.34 137.102 289.701 134.34 284.918L126.341 271.063C123.58 266.281 125.219 260.165 130.002 257.403L172.869 232.653C179.536 228.804 179.536 219.182 172.869 215.333L130.004 190.584C125.221 187.823 123.582 181.707 126.344 176.924L134.343 163.07C137.104 158.287 143.22 156.648 148.003 159.409L190.865 184.156C197.531 188.005 205.865 183.193 205.865 175.495V126Z" fill="url(#paint1_linear_8253_17500)"/>',
                '</g><defs><linearGradient id="paint0_linear_8253_17500" x1="-32" y1="457" x2="599" y2="23" gradientUnits="userSpaceOnUse">',
                '<stop stop-color="#191919"/>',
                '<stop offset="0.792206" stop-color="#323232"/>',
                '<stop offset="0.94763" stop-color="#222222"/></linearGradient>',
                '<linearGradient id="paint1_linear_8253_17500" x1="472.384" y1="24.2051" x2="-432.545" y2="745.899" gradientUnits="userSpaceOnUse">',
                '<stop offset="0.17646" stop-color="#FF7360"/>',
                '<stop offset="0.300949" stop-color="#24FFA3"/>',
                '<stop offset="0.375227" stop-color="white"/></linearGradient>',
                '<clipPath id="clip0_8253_17500">',
                '<rect width="448" height="448" rx="12.4444" fill="white"/>',
                '</clipPath><clipPath id="clip1_8253_17500">',
                '<rect width="698.667" height="524" fill="white" transform="translate(-167 -76)"/>',
                "</clipPath></defs></svg>"
            )
        );
    }
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