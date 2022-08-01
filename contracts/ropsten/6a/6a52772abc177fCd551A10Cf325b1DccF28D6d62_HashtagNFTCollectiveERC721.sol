// SPDX-License-Identifier: UNLICENSED

pragma solidity ^0.8.0;

import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC721/ERC721Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC721/extensions/ERC721URIStorageUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC721/utils/ERC721HolderUpgradeable.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/IERC721Metadata.sol";
import "./HashtagNFTCollectiveUtils.sol";
import "./Interface/IHashtagNFTCollectiveERC721.sol";
import "./Interface/IERC2981.sol";
import "@openzeppelin/contracts-upgradeable/utils/introspection/ERC165StorageUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/utils/CountersUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/utils/StringsUpgradeable.sol";
import "./ERCX.sol";
import "./NFT.sol";
import "./EIP712MetaTransaction.sol";
import "./ERC2771Config.sol";
import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "./Interface/IHashtagNFTCollectiveManager.sol";

contract HashtagNFTCollectiveERC721 is
    IHashtagNFTCollectiveERC721,
    IERC2981,
    HashtagNFTCollectiveUtils,
    OwnableUpgradeable,
    ERC721URIStorageUpgradeable
{
    using CountersUpgradeable for CountersUpgradeable.Counter;

    mapping(uint256 => bool) public takenItems;

    string public nftHashtag;

    address public proxyFactory;

    address public nftVault;

    address public manager;

    // Receiver of royalties
    address public rightsOwner;

    License[] public licenseHistory;

    License public license;

    address public governor;

    CountersUpgradeable.Counter private tokenIdsTracker;

    struct NftMetadata {
        string metadataJsonUrl;
        string viewStataUrl;
        string picUrl;
        string appLinkUrl;
    }

    struct WrappedTokenInfo {
        address tokenAddress;
        uint256 tokenId;
        uint256 timestamp;
    }

    mapping(uint256 => WrappedTokenInfo) wrappedTokens;

    mapping(uint256 => bool) tokenExists;

    mapping(uint256 => NftMetadata) nftMetadata;

    mapping(uint256 => uint256) tokenRoyalties;

    string private collectiveURI;

    bytes4 private constant _INTERFACE_ID_ERC2981 = 0x2a55205a;

    struct License {
        string url;
        uint256 timestamp;
    }

    function initialize(
        string memory _name,
        string memory _symbol,
        address _tokenOwner,
        address _factory
    ) external initializer {
        // __ERC2771Config_init();
        // __NFT_init(_name, _symbol);
        // _registerInterface(_INTERFACE_ID_ERC2981);
        nftHashtag = _generateHashtag(_name);
        rightsOwner = _tokenOwner;
        proxyFactory = _factory;
    }

    function createCollectible(
        string memory _mediaURL,
        uint256 itemId,
        string memory metadataJsonUrl,
        string memory viewStataUrl,
        string memory picUrl,
        string memory appLinkUrl,
        string memory defaultLicenseURL
    ) external override onlyProxyFactory returns (uint256) {
        require(bytes(_mediaURL).length > 0, "invalid media resource URL");
        require(takenItems[itemId] == false, "itemId in use");
        uint256 tokenId = itemId;
        _mint(_msgSender(), tokenId);
        _setTokenURI(tokenId, _mediaURL);
        takenItems[itemId] = true;
        nftMetadata[tokenId] = NftMetadata(
            metadataJsonUrl,
            viewStataUrl,
            picUrl,
            appLinkUrl
        );
        _setLicense(defaultLicenseURL);

        return tokenId;
    }

    function _generateHashtag(string memory _name)
        internal
        returns (string memory)
    {
        return GenerateHashtag(_name);
    }

    modifier onlyProxyFactory() {
        require(_msgSender() == proxyFactory, "CollectiveERC721: only ProxyFactory allowed");
        _;
    }

    modifier onlyGovernor() {
        require(_msgSender() == governor, "CollectiveERC721: only Governor allowed");
        _;
    }

    modifier onlyNFTVault() {
        require(_msgSender() == nftVault, "CollectiveERC721: only NFTVault allowed");
        _;
    }

    function setGovernor(address _governor)
        external
        override
        onlyProxyFactory
        returns (bool)
    {
        governor = _governor;
        return true;
    }

    function setLicense(string calldata url)
        external
        override
        onlyGovernor
    {
        _setLicense(url);
    }

    function wrapToken(address from, uint256 tokenId)
        external
        override
        returns (uint256)
    {
        // IERC721(from).safeTransferFrom(_msgSender(), address(this), tokenId);
        IERC721(from).transferFrom(_msgSender(), address(this), tokenId);
        tokenIdsTracker.increment();
        uint256 newTokenId = tokenIdsTracker.current();
        wrappedTokens[newTokenId] = WrappedTokenInfo(
            from,
            tokenId,
            block.timestamp
        );
        _mint(_msgSender(), newTokenId);
        if ( IERC165(from).supportsInterface(type(IERC721Metadata).interfaceId)) {
            _setTokenURI(newTokenId, IERC721Metadata(from).tokenURI(tokenId));}
        // if (IERC165(from).supportsInterface(this.tokenURI.selector)) {
        //     _setTokenURI(newTokenId, IERC721Metadata(from).tokenURI(tokenId));} 
            else {
            _setTokenURI(newTokenId, "");
        }
        return newTokenId;
    }

    function unWrapToken(uint256 tokenId)
        external
        override
        onlyNFTVault
        returns (address, uint256)
    {
        require(_exists(tokenId) == true, "ERC721: token does not exist");
        require(
            IHashtagNFTCollectiveManager(manager).burnApproved(
                address(this),
                tokenId
            ),
            "E_APPROVE_BURN"
        );
        _burn(tokenId);
        IERC721(wrappedTokens[tokenId].tokenAddress).safeTransferFrom(
            address(this),
            manager,
            wrappedTokens[tokenId].tokenId
        );
        return (
            wrappedTokens[tokenId].tokenAddress,
            wrappedTokens[tokenId].tokenId
        );
    }

    // Set Admin of NFT's -> Will be changed from CollectiveManager|Proxy to Admin on sellout
    function setManager(address _manager) external override onlyProxyFactory {
        manager = _manager;
    }

    function setNFTVault(address _nftVault) external override onlyProxyFactory {
        nftVault = _nftVault;
    }

    function setWrappedTokenURI(
        address from,
        uint256 tokenId,
        string calldata uri
    ) external override returns (uint256) {
        require(msg.sender == ownerOf(tokenId));
        _setTokenURI(tokenId, uri);
    }

    function setCollectiveURI(string memory uri, uint256 tokenId) external override {
         require(msg.sender == ownerOf(tokenId));
        collectiveURI = uri;
    }

    function setRoyalties(uint256[] memory tokenIds, uint256[] memory royalties)
        external
        override
        onlyNFTVault
    {
        require(
            tokenIds.length == royalties.length,
            "ERC721: setRoyalties args len mismatch"
        );
        for (uint256 index = 0; index < tokenIds.length; index++) {
            require(
                _exists(tokenIds[index]) == true,
                "ERC721: token does not exist"
            );
            tokenRoyalties[tokenIds[index]] = royalties[index];
        }
    }

    // Rights owner is the receiver of royalties
    function setRightsOwner(address _rightsOwner)
        external
        override
        onlyNFTVault
    {
        rightsOwner = _rightsOwner;
    }

    // Rights owner is the receiver of royalties
    function getRightsOwner() external view override returns (address) {
        return rightsOwner;
    }

    function upgradeRightsOwnerToManager() external override onlyNFTVault {
        manager = rightsOwner;
    }

    function getLicenseInfo()
        external
        view
        override
        returns (string[] memory, string[][] memory)
    {
        string[][] memory history = new string[][](licenseHistory.length);
        for (uint256 index = 0; index < licenseHistory.length; index++) {
            string[] memory _license = new string[](2);
            _license[0] = licenseHistory[index].url;
            _license[1] = StringsUpgradeable.toString(
                licenseHistory[index].timestamp
            );
            history[index] = _license;
        }
        string[] memory currentLicense = new string[](2);
        currentLicense[0] = license.url;
        currentLicense[1] = StringsUpgradeable.toString(license.timestamp);
        return (currentLicense, history);
    }

    function royaltyInfo(uint256 _tokenId, uint256 _salePrice)
        external
        view
        override
        returns (address receiver, uint256 royaltyAmount)
    {
        require(_exists(_tokenId) == true, "ERC721: token does not exist");
        return (rightsOwner, (_salePrice * tokenRoyalties[_tokenId]) / 100);
    }

    function _setLicense(string memory url) private {
        if (bytes(license.url).length > 0)
            licenseHistory.push(license);

        license = License(url, block.timestamp);
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.0 (access/Ownable.sol)

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
    function __Ownable_init() internal initializer {
        __Context_init_unchained();
        __Ownable_init_unchained();
    }

    function __Ownable_init_unchained() internal initializer {
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
    uint256[49] private __gap;
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.0 (token/ERC721/ERC721.sol)

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
    function __ERC721_init(string memory name_, string memory symbol_) internal initializer {
        __Context_init_unchained();
        __ERC165_init_unchained();
        __ERC721_init_unchained(name_, symbol_);
    }

    function __ERC721_init_unchained(string memory name_, string memory symbol_) internal initializer {
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
        require(ERC721Upgradeable.ownerOf(tokenId) == from, "ERC721: transfer of token that is not own");
        require(to != address(0), "ERC721: transfer to the zero address");

        _beforeTokenTransfer(from, to, tokenId);

        // Clear approvals from the previous owner
        _approve(address(0), tokenId);

        _balances[from] -= 1;
        _balances[to] += 1;
        _owners[tokenId] = to;

        emit Transfer(from, to, tokenId);
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
    uint256[44] private __gap;
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.0 (token/ERC721/extensions/ERC721URIStorage.sol)

pragma solidity ^0.8.0;

import "../ERC721Upgradeable.sol";
import "../../../proxy/utils/Initializable.sol";

/**
 * @dev ERC721 token with storage based token URI management.
 */
abstract contract ERC721URIStorageUpgradeable is Initializable, ERC721Upgradeable {
    function __ERC721URIStorage_init() internal initializer {
        __Context_init_unchained();
        __ERC165_init_unchained();
        __ERC721URIStorage_init_unchained();
    }

    function __ERC721URIStorage_init_unchained() internal initializer {
    }
    using StringsUpgradeable for uint256;

    // Optional mapping for token URIs
    mapping(uint256 => string) private _tokenURIs;

    /**
     * @dev See {IERC721Metadata-tokenURI}.
     */
    function tokenURI(uint256 tokenId) public view virtual override returns (string memory) {
        require(_exists(tokenId), "ERC721URIStorage: URI query for nonexistent token");

        string memory _tokenURI = _tokenURIs[tokenId];
        string memory base = _baseURI();

        // If there is no base URI, return the token URI.
        if (bytes(base).length == 0) {
            return _tokenURI;
        }
        // If both are set, concatenate the baseURI and tokenURI (via abi.encodePacked).
        if (bytes(_tokenURI).length > 0) {
            return string(abi.encodePacked(base, _tokenURI));
        }

        return super.tokenURI(tokenId);
    }

    /**
     * @dev Sets `_tokenURI` as the tokenURI of `tokenId`.
     *
     * Requirements:
     *
     * - `tokenId` must exist.
     */
    function _setTokenURI(uint256 tokenId, string memory _tokenURI) internal virtual {
        require(_exists(tokenId), "ERC721URIStorage: URI set of nonexistent token");
        _tokenURIs[tokenId] = _tokenURI;
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
    function _burn(uint256 tokenId) internal virtual override {
        super._burn(tokenId);

        if (bytes(_tokenURIs[tokenId]).length != 0) {
            delete _tokenURIs[tokenId];
        }
    }
    uint256[49] private __gap;
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.0 (token/ERC721/utils/ERC721Holder.sol)

pragma solidity ^0.8.0;

import "../IERC721ReceiverUpgradeable.sol";
import "../../../proxy/utils/Initializable.sol";

/**
 * @dev Implementation of the {IERC721Receiver} interface.
 *
 * Accepts all token transfers.
 * Make sure the contract is able to use its token with {IERC721-safeTransferFrom}, {IERC721-approve} or {IERC721-setApprovalForAll}.
 */
contract ERC721HolderUpgradeable is Initializable, IERC721ReceiverUpgradeable {
    function __ERC721Holder_init() internal initializer {
        __ERC721Holder_init_unchained();
    }

    function __ERC721Holder_init_unchained() internal initializer {
    }
    /**
     * @dev See {IERC721Receiver-onERC721Received}.
     *
     * Always returns `IERC721Receiver.onERC721Received.selector`.
     */
    function onERC721Received(
        address,
        address,
        uint256,
        bytes memory
    ) public virtual override returns (bytes4) {
        return this.onERC721Received.selector;
    }
    uint256[50] private __gap;
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.0 (access/Ownable.sol)

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
// OpenZeppelin Contracts v4.4.0 (token/ERC721/IERC721.sol)

pragma solidity ^0.8.0;

import "../../utils/introspection/IERC165.sol";

/**
 * @dev Required interface of an ERC721 compliant contract.
 */
interface IERC721 is IERC165 {
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
// OpenZeppelin Contracts v4.4.0 (token/ERC721/extensions/IERC721Metadata.sol)

pragma solidity ^0.8.0;

import "../IERC721.sol";

/**
 * @title ERC-721 Non-Fungible Token Standard, optional metadata extension
 * @dev See https://eips.ethereum.org/EIPS/eip-721
 */
interface IERC721Metadata is IERC721 {
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

import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";

pragma solidity ^0.8.0;

contract HashtagNFTCollectiveUtils is Initializable {
    function __HashtagNFTCollectiveUtils_init() internal initializer {}

    function concatAll(string memory _a, string memory _b)
        public
        returns (string memory)
    {
        bytes memory _ba = bytes(_a);
        bytes memory _bb = bytes(_b);
        string memory abcde = new string(_ba.length + _bb.length);
        bytes memory babcde = bytes(abcde);
        uint256 k = 0;
        for (uint256 i = 0; i < _ba.length; i++) {
            babcde[k++] = _ba[i];
        }
        for (uint256 i = 0; i < _bb.length; i++) {
            babcde[k++] = _bb[i];
        }
        return string(babcde);
    }

    function strConcat(string memory _a, string memory _b)
        internal
        returns (string memory)
    {
        return concatAll(_a, _b);
    }

    function GenerateHashtag(string memory _name)
        internal
        returns (string memory)
    {
        string memory prefix = "#nft";
        return strConcat(prefix, _name);
    }

    function ConcatStr(string memory prefix, string memory word)
        internal
        returns (string memory)
    {
        return strConcat(prefix, word);
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.11;

interface IHashtagNFTCollectiveERC721 {
    function createCollectible(
        string memory _mediaURL,
        uint256 itemId,
        string memory metadataJsonUrl,
        string memory viewStataUrl,
        string memory picUrl,
        string memory appLinkUrl,
        string memory defaultLicenseURL
    ) external returns (uint256);

    function setLicense(string calldata _url) external;

    function setGovernor(address _governor) external returns (bool);

    function wrapToken(address from, uint256 tokenId)
        external
        returns (uint256);

    function unWrapToken(uint256 tokenId) external returns (address, uint256);

    function setWrappedTokenURI(
        address from,
        uint256 tokenId,
        string calldata uri
    ) external returns (uint256);

    function setCollectiveURI(string memory uri, uint256 itemId) external;

    function setNFTVault(address _nftVault) external;

    function setManager(address _manager) external;

    function setRoyalties(uint256[] memory tokenIds, uint256[] memory royalties)
        external;

    function setRightsOwner(address) external;

    function getRightsOwner() external view returns (address);

    function upgradeRightsOwnerToManager() external;

    function getLicenseInfo()
        external
        view
        returns (string[] memory, string[][] memory);
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "@openzeppelin/contracts/utils/introspection/IERC165.sol";

///
/// @dev Interface for the NFT Royalty Standard
///
interface IERC2981 {
    /// ERC165 bytes to add to interface array - set in parent contract
    /// implementing this standard
    ///
    // bytes4(keccak256("royaltyInfo(uint256,uint256)")) == 0x2a55205a
    // bytes4 private constant _INTERFACE_ID_ERC2981 = 0x2a55205a;
    /// _registerInterface(_INTERFACE_ID_ERC2981);

    /// @notice Called with the sale price to determine how much royalty
    //          is owed and to whom.
    /// @param _tokenId - the NFT asset queried for royalty information
    /// @param _salePrice - the sale price of the NFT asset specified by _tokenId
    /// @return receiver - address of who should be sent the royalty payment
    /// @return royaltyAmount - the royalty payment amount for _salePrice
    function royaltyInfo(
        uint256 _tokenId,
        uint256 _salePrice
    ) external view returns (
        address receiver,
        uint256 royaltyAmount
    );
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.0 (utils/introspection/ERC165Storage.sol)

pragma solidity ^0.8.0;

import "./ERC165Upgradeable.sol";
import "../../proxy/utils/Initializable.sol";

/**
 * @dev Storage based implementation of the {IERC165} interface.
 *
 * Contracts may inherit from this and call {_registerInterface} to declare
 * their support of an interface.
 */
abstract contract ERC165StorageUpgradeable is Initializable, ERC165Upgradeable {
    function __ERC165Storage_init() internal initializer {
        __ERC165_init_unchained();
        __ERC165Storage_init_unchained();
    }

    function __ERC165Storage_init_unchained() internal initializer {
    }
    /**
     * @dev Mapping of interface ids to whether or not it's supported.
     */
    mapping(bytes4 => bool) private _supportedInterfaces;

    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId) public view virtual override returns (bool) {
        return super.supportsInterface(interfaceId) || _supportedInterfaces[interfaceId];
    }

    /**
     * @dev Registers the contract as an implementer of the interface defined by
     * `interfaceId`. Support of the actual ERC165 interface is automatic and
     * registering its interface id is not required.
     *
     * See {IERC165-supportsInterface}.
     *
     * Requirements:
     *
     * - `interfaceId` cannot be the ERC165 invalid interface (`0xffffffff`).
     */
    function _registerInterface(bytes4 interfaceId) internal virtual {
        require(interfaceId != 0xffffffff, "ERC165: invalid interface id");
        _supportedInterfaces[interfaceId] = true;
    }
    uint256[49] private __gap;
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.0 (utils/Counters.sol)

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
// OpenZeppelin Contracts v4.4.0 (utils/Strings.sol)

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

pragma solidity ^0.8.0;

import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "@openzeppelin/contracts-upgradeable/utils/introspection/ERC165StorageUpgradeable.sol";
import "./Interface/IERCX.sol";
import "./Libraries/AddressX.sol";
import "@openzeppelin/contracts-upgradeable/utils/math/SafeMathUpgradeable.sol";
import "@openzeppelin/contracts/utils/Counters.sol";
import "@openzeppelin/contracts-upgradeable/utils/AddressUpgradeable.sol";
import "./Interface/IERCXReceiver.sol";
import "./EIP712MetaTransaction.sol";
import "./ERC2771Config.sol";

contract ERCX is ERC165StorageUpgradeable, IERCX, ERC2771ContextUpgradeable, ERC2771Config {
    using SafeMathUpgradeable for uint256;
    using AddressUpgradeable for address;
    using Counters for Counters.Counter;

    bytes4 private constant _ERCX_RECEIVED = 0x11111111;
    //bytes4(keccak256("onERCXReceived(address,address,uint256,bytes)"));

    // Mapping from item ID to layer to owner
    mapping(uint256 => mapping(uint256 => address)) private _itemOwner;

    // Mapping from item ID to layer to approved address
    mapping(uint256 => mapping(uint256 => address)) private _transferApprovals;

    // Mapping from owner to layer to number of owned item
    mapping(address => mapping(uint256 => Counters.Counter)) private _ownedItemsCount;

    // Mapping from owner to operator approvals
    mapping(address => mapping(address => bool)) private _operatorApprovals;

    // Mapping from item ID to approved address of setting lien
    mapping(uint256 => address) private _lienApprovals;

    // Mapping from item ID to contract address of lien
    mapping(uint256 => address) private _lienAddress;

    // Mapping from item ID to approved address of setting tenant right agreement
    mapping(uint256 => address) private _tenantRightApprovals;

    // Mapping from item ID to contract address of TenantRight
    mapping(uint256 => address) private _tenantRightAddress;

    // Change to fix error-clash with ApprovalForAll Zeppelin event
    event ApprovedForAll(
        address indexed owner,
        address indexed approved,
        bool approval
    );

    bytes4 private constant _InterfaceId_ERCX = bytes4(
        keccak256("balanceOfOwner(address)")
    ) ^
        bytes4(keccak256("balanceOfUser(address)")) ^
        bytes4(keccak256("ownerOf(uint256)")) ^
        bytes4(keccak256("userOf(uint256)")) ^
        bytes4(keccak256("safeTransferOwner(address, address, uint256)")) ^
        bytes4(
            keccak256("safeTransferOwner(address, address, uint256, bytes)")
        ) ^
        bytes4(keccak256("safeTransferUser(address, address, uint256)")) ^
        bytes4(
            keccak256("safeTransferUser(address, address, uint256, bytes)")
        ) ^
        bytes4(keccak256("approveForOwner(address, uint256)")) ^
        bytes4(keccak256("getApprovedForOwner(uint256)")) ^
        bytes4(keccak256("approveForUser(address, uint256)")) ^
        bytes4(keccak256("getApprovedForUser(uint256)")) ^
        bytes4(keccak256("setApprovalForAll(address, bool)")) ^
        bytes4(keccak256("isApprovedForAll(address, address)")) ^
        bytes4(keccak256("approveLien(address, uint256)")) ^
        bytes4(keccak256("getApprovedLien(uint256)")) ^
        bytes4(keccak256("setLien(uint256)")) ^
        bytes4(keccak256("getCurrentLien(uint256)")) ^
        bytes4(keccak256("revokeLien(uint256)")) ^
        bytes4(keccak256("approveTenantRight(address, uint256)")) ^
        bytes4(keccak256("getApprovedTenantRight(uint256)")) ^
        bytes4(keccak256("setTenantRight(uint256)")) ^
        bytes4(keccak256("getCurrentTenantRight(uint256)")) ^
        bytes4(keccak256("revokeTenantRight(uint256)"));

    // constructor() {
    //     // register the supported interfaces to conform to ERCX via ERC165
    //     _registerInterface(_InterfaceId_ERCX);
    //     console.log("INTERFACE_ID: ");
    //     console.logBytes4(_InterfaceId_ERCX);
    // }

    function __ERCX_init() internal initializer{
        __ERC2771Config_init();
        __ERC165Storage_init();
        _registerInterface(_InterfaceId_ERCX);
    }

    /**
   * @dev Gets the balance of the specified address
   * @param owner address to query the balance of
   * @return uint256 representing the amount of items owned by the passed address in the specified layer
   */
    function balanceOfOwner(address owner) external view override  returns (uint256) {
        return _balanceOfOwner(owner);
    }

    function _balanceOfOwner(address owner) internal view  returns (uint256) {
        require(owner != address(0));
        uint256 balance = _ownedItemsCount[owner][2].current();
        return balance;
    }

    /**
   * @dev Gets the balance of the specified address
   * @param user address to query the balance of
   * @return uint256 representing the amount of items owned by the passed address
   */
    function balanceOfUser(address user) external view override  returns (uint256) {
        return _balanceOfUser(user);
    }

    function _balanceOfUser(address user) internal view  returns (uint256) {
        require(user != address(0));
        uint256 balance = _ownedItemsCount[user][1].current();
        return balance;
    }

    /**
   * @dev Gets the user of the specified item ID
   * @param itemId uint256 ID of the item to query the user of
   * @return owner address currently marked as the owner of the given item ID
   */
    function userOf(uint256 itemId) external view  override returns (address) {
        return _userOf(itemId);
    }

    function _userOf(uint256 itemId) internal view  returns (address) {
        address user = _itemOwner[itemId][1];
        require(user != address(0));
        return user;
    }

    /**
   * @dev Gets the owner of the specified item ID
   * @param itemId uint256 ID of the item to query the owner of
   * @return owner address currently marked as the owner of the given item ID
   */
    function ownerOf(uint256 itemId) external virtual override view returns (address) {
        return _ownerOf(itemId);
    }

    function _ownerOf(uint256 itemId) internal virtual view  returns (address) {
        address owner = _itemOwner[itemId][2];
        require(owner != address(0));
        return owner;
    }

    /**
   * @dev Approves another address to transfer the user of the given item ID
   * The zero address indicates there is no approved address.
   * There can only be one approved address per item at a given time.
   * Can only be called by the item owner or an approved operator.
   * @param to address to be approved for the given item ID
   */
    function approveForUser(address to, uint256 itemId) external override  {
        address user = _userOf(itemId);
        address owner = _ownerOf(itemId);

        require(to != owner && to != user,"ERCX: to/from cannot be owner/user");
        require(
            _msgSender() == user ||
                _msgSender() == owner ||
                _isApprovedForAll(user, _msgSender()) ||
                _isApprovedForAll(owner, _msgSender())
        , "ERCX: must be user or owner or approved for address");
        if (_msgSender() == owner || _isApprovedForAll(owner, _msgSender())) {
            require(_getCurrentTenantRight(itemId) == address(0));
        }
        _transferApprovals[itemId][1] = to;
        emit ApprovalForUser(user, to, itemId);
    }

    /**
   * @dev Gets the approved address for the user of the item ID, or zero if no address set
   * Reverts if the item ID does not exist.
   * @param itemId uint256 ID of the item to query the approval of
   * @return address currently approved for the given item ID
   */
    function getApprovedForUser(uint256 itemId) external override view  returns (address) {
        return _getApprovedForUser(itemId);
    }

    function _getApprovedForUser(uint256 itemId) internal view  returns (address) {
        require(_exists(itemId, 1));
        return _transferApprovals[itemId][1];
    }

    /**
   * @dev Approves another address to transfer the owner of the given item ID
   * The zero address indicates there is no approved address.
   * There can only be one approved address per item at a given time.
   * Can only be called by the item owner or an approved operator.
   * @param to address to be approved for the given item ID
   * @param itemId uint256 ID of the item to be approved
   */
    function approveForOwner(address to, uint256 itemId) external override  {
        _approveForOwner(to, itemId);
    }

    function _approveForOwner(address to, uint256 itemId) internal  {
        address owner = _ownerOf(itemId);

        require(to != owner);
        require(_msgSender() == owner || _isApprovedForAll(owner, _msgSender()));
        _transferApprovals[itemId][2] = to;
        emit ApprovalForOwner(owner, to, itemId);

    }

    /**
   * @dev Gets the approved address for the of the item ID, or zero if no address set
   * Reverts if the item ID does not exist.
   * @param itemId uint256 ID of the item to query the approval o
   * @return address currently approved for the given item ID
   */
    function getApprovedForOwner(uint256 itemId) external override view  returns (address) {
        return _getApprovedForOwner(itemId);
    }

    function _getApprovedForOwner(uint256 itemId) internal view  returns (address) {
        require(_exists(itemId, 2));
        return _transferApprovals[itemId][2];
    }

    /**
   * @dev Sets or unsets the approval of a given operator
   * An operator is allowed to transfer all items of the sender on their behalf
   * @param to operator address to set the approval
   * @param approved representing the status of the approval to be set
   */
    function setApprovalForAll(address to, bool approved) external virtual override  {
        _setApprovalForAll(to, approved);
    }

    function _setApprovalForAll(address to, bool approved) internal virtual  {
        require(to != _msgSender());
        _operatorApprovals[_msgSender()][to] = approved;
        emit ApprovedForAll(_msgSender(), to, approved);
    }

    /**
   * @dev Tells whether an operator is approved by a given owner
   * @param owner owner address which you want to query the approval of
   * @param operator operator address which you want to query the approval of
   * @return bool whether the given operator is approved by the given owner
   */
    function isApprovedForAll(address owner, address operator)
        public
        virtual
        override
        view
        returns (bool)
    {
        return _isApprovedForAll( owner,  operator);
    }

    function _isApprovedForAll(address owner, address operator)
        internal
        virtual
        view
        returns (bool)
    {
        return _operatorApprovals[owner][operator];
    }

    /**
   * @dev Approves another address to set lien contract for the given item ID
   * The zero address indicates there is no approved address.
   * There can only be one approved address per item at a given time.
   * Can only be called by the item owner or an approved operator.
   * @param to address to be approved for the given item ID
   * @param itemId uint256 ID of the item to be approved
   */
    function approveLien(address to, uint256 itemId) external override {
        address owner = _ownerOf(itemId);
        require(to != owner);
        require(_msgSender() == owner || _isApprovedForAll(owner, _msgSender()));
        _lienApprovals[itemId] = to;
        emit LienApproval(to, itemId);
    }

    /**
   * @dev Gets the approved address for setting lien for a item ID, or zero if no address set
   * Reverts if the item ID does not exist.
   * @param itemId uint256 ID of the item to query the approval of
   * @return address currently approved for the given item ID
   */
    function getApprovedLien(uint256 itemId) external override view  returns (address) {
        return _getApprovedLien(itemId);
    }

    function _getApprovedLien(uint256 itemId) internal view  returns (address) {
        require(_exists(itemId, 2));
        return _lienApprovals[itemId];
    }
    /**
   * @dev Sets lien agreements to already approved address
   * The lien address is allowed to transfer all items of the sender on their behalf
   * @param itemId uint256 ID of the item
   */
    function setLien(uint256 itemId) external override {
        require(_msgSender() == _getApprovedLien(itemId));
        _lienAddress[itemId] = _msgSender();
        _clearLienApproval(itemId);
        emit LienSet(_msgSender(), itemId, true);
    }

    /**
   * @dev Gets the current lien agreement address, or zero if no address set
   * Reverts if the item ID does not exist.
   * @param itemId uint256 ID of the item to query the lien address
   * @return address of the lien agreement address for the given item ID
   */
    function getCurrentLien(uint256 itemId) public virtual override view returns (address) {
        return _getCurrentLien(itemId);
    }

    function _getCurrentLien(uint256 itemId) internal virtual view returns (address) {
        require(_exists(itemId, 2));
        return _lienAddress[itemId];
    }

    /**
   * @dev Revoke the lien agreements. Only the lien address can revoke.
   * @param itemId uint256 ID of the item
   */
    function revokeLien(uint256 itemId) external override  {
        require(_msgSender() == _getCurrentLien(itemId));
        _lienAddress[itemId] = address(0);
        emit LienSet(address(0), itemId, false);
    }

    /**
   * @dev Approves another address to set tenant right agreement for the given item ID
   * The zero address indicates there is no approved address.
   * There can only be one approved address per item at a given time.
   * Can only be called by the item owner or an approved operator.
   * @param to address to be approved for the given item ID
   * @param itemId uint256 ID of the item to be approved
   */
    function approveTenantRight(address to, uint256 itemId) external override  {
        address owner = _ownerOf(itemId);
        require(to != owner, "Cannot be owner");
        require(_msgSender() == owner || _isApprovedForAll(owner, _msgSender()));
        _tenantRightApprovals[itemId] = to;
        emit TenantRightApproval(to, itemId);
    }

    /**
   * @dev Gets the approved address for setting tenant right for a item ID, or zero if no address set
   * Reverts if the item ID does not exist.
   * @param itemId uint256 ID of the item to query the approval of
   * @return address currently approved for the given item ID
   */
    function getApprovedTenantRight(uint256 itemId)
        external
        override
        view
        returns (address)
    {
        return _getApprovedTenantRight(itemId);
    }


    function _getApprovedTenantRight(uint256 itemId)
        internal
        view
        returns (address)
    {
        require(_exists(itemId, 2));
        return _tenantRightApprovals[itemId];
    }
    /**
   * @dev Sets the tenant right agreement to already approved address
   * The lien address is allowed to transfer all items of the sender on their behalf
   * @param itemId uint256 ID of the item
   */
    function setTenantRight(uint256 itemId) external override {
        require(_msgSender() == _getApprovedTenantRight(itemId));
        _tenantRightAddress[itemId] = _msgSender();
        _clearTenantRightApproval(itemId);
        _clearTransferApproval(itemId, 1); //Reset transfer approval
        emit TenantRightSet(_msgSender(), itemId, true);
    }

    /**
   * @dev Gets the current tenant right agreement address, or zero if no address set
   * Reverts if the item ID does not exist.
   * @param itemId uint256 ID of the item to query the tenant right address
   * @return address of the tenant right agreement address for the given item ID
   */
    function getCurrentTenantRight(uint256 itemId)
        external
        override
        view
        returns (address)
    {
        return _getCurrentTenantRight(itemId);
    }

    function _getCurrentTenantRight(uint256 itemId)
        internal
        view
        returns (address)
    {
        require(_exists(itemId, 2));
        return _tenantRightAddress[itemId];
    }

    /**
   * @dev Revoke the tenant right agreement. Only the lien address can revoke.
   * @param itemId uint256 ID of the item
   */
    function revokeTenantRight(uint256 itemId) external override  {
        require(_msgSender() == _getCurrentTenantRight(itemId));
        _tenantRightAddress[itemId] = address(0);
        emit TenantRightSet(address(0), itemId, false);
    }

    /**
   * @dev Safely transfers the user of a given item ID to another address
   * If the target address is a contract, it must implement `onERCXReceived`,
   * which is called upon a safe transfer, and return the magic value
   * `bytes4(keccak256("onERCXReceived(address,address,uint256,bytes)"))`; otherwise,
   * the transfer is reverted.
   *
   * Requires the msg sender to be the owner, approved, or operator
   * @param from current owner of the item
   * @param to address to receive the ownership of the given item ID
   * @param itemId uint256 ID of the item to be transferred

  */
    function safeTransferUser(address from, address to, uint256 itemId) external override  {
        // solium-disable-next-line arg-overflow
        _safeTransferUser(from, to, itemId, "");
    }

    /**
   * @dev Safely transfers the user of a given item ID to another address
   * If the target address is a contract, it must implement `onERCXReceived`,
   * which is called upon a safe transfer, and return the magic value
   * `bytes4(keccak256("onERCXReceived(address,address,uint256,bytes)"))`; otherwise,
   * the transfer is reverted.
   * Requires the msg sender to be the owner, approved, or operator
   * @param from current owner of the item
   * @param to address to receive the ownership of the given item ID
   * @param itemId uint256 ID of the item to be transferred
   * @param data bytes data to send along with a safe transfer check
   */
    function safeTransferUser(
        address from,
        address to,
        uint256 itemId,
        bytes memory data
    ) external override {
        _safeTransferUser(
        from,
        to,
        itemId,
        data
        );
    }

    function _safeTransferUser(
        address from,
        address to,
        uint256 itemId,
        bytes memory data
    ) internal {
        require(_isEligibleForTransfer(_msgSender(), itemId, 1));
        _safeTransfer(from, to, itemId, 1, data);
    }

    /**
   * @dev Safely transfers the ownership of a given item ID to another address
   * If the target address is a contract, it must implement `onERCXReceived`,
   * which is called upon a safe transfer, and return the magic value
   * `bytes4(keccak256("onERCXReceived(address,address,uint256,bytes)"))`; otherwise,
   * the transfer is reverted.
   *
   * Requires the msg sender to be the owner, approved, or operator
   * @param from current owner of the item
   * @param to address to receive the ownership of the given item ID
   * @param itemId uint256 ID of the item to be transferred
  */
    function safeTransferOwner(address from, address to, uint256 itemId)
        external 
        virtual
        override
    {
        // solium-disable-next-line arg-overflow
        _safeTransferOwner(from, to, itemId, "");
    }

    /**
   * @dev Safely transfers the ownership of a given item ID to another address
   * If the target address is a contract, it must implement `onERCXReceived`,
   * which is called upon a safe transfer, and return the magic value
   * `bytes4(keccak256("onERCXReceived(address,address,uint256,bytes)"))`; otherwise,
   * the transfer is reverted.
   * Requires the msg sender to be the owner, approved, or operator
   * @param from current owner of the item
   * @param to address to receive the ownership of the given item ID
   * @param itemId uint256 ID of the item to be transferred
   * @param data bytes data to send along with a safe transfer check
   */
    function safeTransferOwner(
        address from,
        address to,
        uint256 itemId,
        bytes memory data
    ) external override  {
        _safeTransferOwner(
            from,
            to,
            itemId,
            data
        );
    }

    function _safeTransferOwner(
        address from,
        address to,
        uint256 itemId,
        bytes memory data
    ) internal  {
        require(_isEligibleForTransfer(_msgSender(), itemId, 2));
        _safeTransfer(from, to, itemId, 2, data);
    }

    /**
    * @dev Safely transfers the ownership of a given item ID to another address
    * If the target address is a contract, it must implement `onERCXReceived`,
    * which is called upon a safe transfer, and return the magic value
    * `bytes4(keccak256("onERCXReceived(address,address,uint256,bytes)"))`; otherwise,
    * the transfer is reverted.
    * Requires the _msgSender() to be the owner, approved, or operator
    * @param from current owner of the item
    * @param to address to receive the ownership of the given item ID
    * @param itemId uint256 ID of the item to be transferred
    * @param layer uint256 number to specify the layer
    * @param data bytes data to send along with a safe transfer check
    */
    function _safeTransfer(
        address from,
        address to,
        uint256 itemId,
        uint256 layer,
        bytes memory data
    ) internal {
        _transfer(from, to, itemId, layer);
        require(
            _checkOnERCXReceived(from, to, itemId, layer, data),
            "ERCX: transfer to non ERCXReceiver implementer"
        );
    }

    /**
    * @dev Returns whether the given spender can transfer a given item ID.
    * @param spender address of the spender to query
    * @param itemId uint256 ID of the item to be transferred
    * @param layer uint256 number to specify the layer
    * @return bool whether the _msgSender() is approved for the given item ID,
    * is an operator of the owner, or is the owner of the item
    */
    function _isEligibleForTransfer(
        address spender,
        uint256 itemId,
        uint256 layer
    ) internal view returns (bool) {
        require(_exists(itemId, layer));
        if (layer == 1) {
            address user = _userOf(itemId);
            address owner = _ownerOf(itemId);
            require(
                spender == user ||
                    spender == owner ||
                    _isApprovedForAll(user, spender) ||
                    _isApprovedForAll(owner, spender) ||
                    spender == _getApprovedForUser(itemId) ||
                    spender == _getCurrentLien(itemId)
            );
            if (spender == owner || _isApprovedForAll(owner, spender)) {
                require(_getCurrentTenantRight(itemId) == address(0));
            }
            return true;
        }

        if (layer == 2) {
            address owner = _ownerOf(itemId);
            require(
                spender == owner ||
                    _isApprovedForAll(owner, spender) ||
                    spender == _getApprovedForOwner(itemId) ||
                    spender == _getCurrentLien(itemId)
            );
            return true;
        }
    }

    /**
   * @dev Returns whether the specified item exists
   * @param itemId uint256 ID of the item to query the existence of
   * @param layer uint256 number to specify the layer
   * @return whether the item exists
   */
    function _exists(uint256 itemId, uint256 layer)
        internal
        view
        returns (bool)
    {
        address owner = _itemOwner[itemId][layer];
        return owner != address(0);
    }

    /**
    * @dev Internal function to safely mint a new item.
    * Reverts if the given item ID already exists.
    * If the target address is a contract, it must implement `onERCXReceived`,
    * which is called upon a safe transfer, and return the magic value
    * `bytes4(keccak256("onERCXReceived(address,address,uint256,bytes)"))`; otherwise,
    * the transfer is reverted.
    * @param to The address that will own the minted item
    * @param itemId uint256 ID of the item to be minted
    */
    function _safeMint(address to, uint256 itemId) internal virtual {
        _safeMint(to, itemId, "");
    }

    /**
    * @dev Internal function to safely mint a new item.
    * Reverts if the given item ID already exists.
    * If the target address is a contract, it must implement `onERCXReceived`,
    * which is called upon a safe transfer, and return the magic value
    * `bytes4(keccak256("onERCXReceived(address,address,uint256,bytes)"))`; otherwise,
    * the transfer is reverted.
    * @param to The address that will own the minted item
    * @param itemId uint256 ID of the item to be minted
    * @param data bytes data to send along with a safe transfer check
    */
    function _safeMint(address to, uint256 itemId, bytes memory data) internal virtual{
        _mint(to, itemId);
        require(_checkOnERCXReceived(address(0), to, itemId, 1, data));
        require(_checkOnERCXReceived(address(0), to, itemId, 2, data));
    }

    /**
    * @dev Internal function to mint a new item.
    * Reverts if the given item ID already exists.
    * A new item iss minted with all three layers.
    * @param to The address that will own the minted item
    * @param itemId uint256 ID of the item to be minted
    */
    function _mint(address to, uint256 itemId) internal virtual {
        require(to != address(0), "ERCX: mint to the zero address");
        require(!_exists(itemId, 1), "ERCX: item already minted");

        _itemOwner[itemId][1] = to;
        _itemOwner[itemId][2] = to;
        _ownedItemsCount[to][1].increment();
        _ownedItemsCount[to][2].increment();

        emit TransferUser(address(0), to, itemId, _msgSender());
        emit TransferOwner(address(0), to, itemId, _msgSender());

    }

    /**
    * @dev Internal function to burn a specific item.
    * Reverts if the item does not exist.
    * @param itemId uint256 ID of the item being burned
    */
    function _burn(uint256 itemId) internal virtual {
        address user = _userOf(itemId);
        address owner = _ownerOf(itemId);
        require(user == _msgSender() && owner == _msgSender());

        _clearTransferApproval(itemId, 1);
        _clearTransferApproval(itemId, 2);

        _ownedItemsCount[user][1].decrement();
        _ownedItemsCount[owner][2].decrement();
        _itemOwner[itemId][1] = address(0);
        _itemOwner[itemId][2] = address(0);

        emit TransferUser(user, address(0), itemId, _msgSender());
        emit TransferOwner(owner, address(0), itemId, _msgSender());
    }

    /**
    * @dev Internal function to transfer ownership of a given item ID to another address.
    * As opposed to {transferFrom}, this imposes no restrictions on _msgSender().
    * @param from current owner of the item
    * @param to address to receive the ownership of the given item ID
    * @param itemId uint256 ID of the item to be transferred
    * @param layer uint256 number to specify the layer
    */
    function _transfer(address from, address to, uint256 itemId, uint256 layer)
        virtual
        internal
    {
        if (layer == 1) {
            require(_userOf(itemId) == from);
        } else {
            require(_ownerOf(itemId) == from);
        }
        require(to != address(0));

        _clearTransferApproval(itemId, layer);

        if (layer == 2) {
            _clearLienApproval(itemId);
            _clearTenantRightApproval(itemId);
        }

        _ownedItemsCount[from][layer].decrement();
        _ownedItemsCount[to][layer].increment();

        _itemOwner[itemId][layer] = to;

        if (layer == 1) {
            emit TransferUser(from, to, itemId, _msgSender());
        } else {
            emit TransferOwner(from, to, itemId, _msgSender());
        }

    }

    /**
    * @dev Internal function to invoke {IERCXReceiver-onERCXReceived} on a target address.
    * The call is not executed if the target address is not a contract.
    *
    * This is an internal detail of the `ERCX` contract and its use is deprecated.
    * @param from address representing the previous owner of the given item ID
    * @param to target address that will receive the items
    * @param itemId uint256 ID of the item to be transferred
    * @param layer uint256 number to specify the layer
    * @param data bytes optional data to send along with the call
    * @return bool whether the call correctly returned the expected magic value
    */
    function _checkOnERCXReceived(
        address from,
        address to,
        uint256 itemId,
        uint256 layer,
        bytes memory data
    ) internal returns (bool) {
        if (!to.isContract()) {
            return true;
        }

        bytes4 retval = IERCXReceiver(to).onERCXReceived(
            _msgSender(),
            from,
            itemId,
            layer,
            data
        );
        return (retval == _ERCX_RECEIVED);
    }

    /**
    * @dev Private function to clear current approval of a given item ID.
    * @param itemId uint256 ID of the item to be transferred
    * @param layer uint256 number to specify the layer
    */
    function _clearTransferApproval(uint256 itemId, uint256 layer) private {
        if (_transferApprovals[itemId][layer] != address(0)) {
            _transferApprovals[itemId][layer] = address(0);
        }
    }

    function _clearTenantRightApproval(uint256 itemId) private {
        if (_tenantRightApprovals[itemId] != address(0)) {
            _tenantRightApprovals[itemId] = address(0);
        }
    }

    function _clearLienApproval(uint256 itemId) private {
        if (_lienApprovals[itemId] != address(0)) {
            _lienApprovals[itemId] = address(0);
        }
    }

    function supportsInterface(bytes4 interfaceId) public view virtual override(ERC165StorageUpgradeable) returns (bool) {
        return super.supportsInterface(interfaceId);
    }

}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "./ERCXFull.sol";
import "./ERCXEnumerable.sol";
import "./ERCXMetadata.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "@openzeppelin/contracts/utils/Counters.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/IERC721Metadata.sol";


contract NFT is Initializable, ERCXFull {

    uint256 counter;

    constructor(){}

    function __NFT_init(string memory name, string memory symbol) public initializer{
        __ERCXFull_init(name, symbol);
    }

    function createNFT(string memory uri) external returns(uint256){
        counter +=1;
        _safeMint(_msgSender(), counter);
        _setTokenURI(counter, uri);
        return counter;
    }

    function safeTransferOwner(address from, address to, uint256 itemId) external virtual override(ERCXFull) {
        _safeTransferOwner(from, to, itemId, "");
    }
}

//SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./EIP712Base.sol";
import "@openzeppelin/contracts-upgradeable/utils/math/SafeMathUpgradeable.sol";

contract EIP712MetaTransaction is EIP712Base {
    using SafeMathUpgradeable for uint256;
    bytes32 private constant META_TRANSACTION_TYPEHASH = keccak256(bytes("MetaTransaction(uint256 nonce,address from,bytes functionSignature)"));

    event MetaTransactionExecuted(address userAddress, address payable relayerAddress, bytes functionSignature);
    mapping(address => uint256) private nonces;

    /*
     * Meta transaction structure.
     * No point of including value field here as if user is doing value transfer then he has the funds to pay for gas
     * He should call the desired function directly in that case.
     */
    struct MetaTransaction {
        uint256 nonce;
        address from;
        bytes functionSignature;
    }

    function __EIP712MetaTransaction_init(string memory name, string memory version) internal initializer {
        __EIP712Base_init(name, version);
    }


    function convertBytesToBytes4(bytes memory inBytes) internal pure returns (bytes4 outBytes4) {
        if (inBytes.length == 0) {
            return 0x0;
        }

        assembly {
            outBytes4 := mload(add(inBytes, 32))
        }
    }

    function executeMetaTransaction(address userAddress,
        bytes memory functionSignature, bytes32 sigR, bytes32 sigS, uint8 sigV) public payable returns(bytes memory) {
        bytes4 destinationFunctionSig = convertBytesToBytes4(functionSignature);
        require(destinationFunctionSig != msg.sig, "functionSignature can not be of executeMetaTransaction method");
        MetaTransaction memory metaTx = MetaTransaction({
            nonce: nonces[userAddress],
            from: userAddress,
            functionSignature: functionSignature
        });
        require(verify(userAddress, metaTx, sigR, sigS, sigV), "Signer and signature do not match");
        nonces[userAddress] = nonces[userAddress].add(1);
        // Append userAddress at the end to extract it from calling context
        (bool success, bytes memory returnData) = address(this).call(abi.encodePacked(functionSignature, userAddress));

        require(success, "Function call not successful");
        emit MetaTransactionExecuted(userAddress, payable(msg.sender), functionSignature);
        return returnData;
    }

    function hashMetaTransaction(MetaTransaction memory metaTx) internal pure returns (bytes32) {
        return keccak256(abi.encode(
            META_TRANSACTION_TYPEHASH,
            metaTx.nonce,
            metaTx.from,
            keccak256(metaTx.functionSignature)
        ));
    }

    function getNonce(address user) external view returns(uint256 nonce) {
        nonce = nonces[user];
    }

    function verify(address user, MetaTransaction memory metaTx, bytes32 sigR, bytes32 sigS, uint8 sigV) internal view returns (bool) {
        address signer = ecrecover(toTypedMessageHash(hashMetaTransaction(metaTx)), sigV, sigR, sigS);
        require(signer != address(0), "Invalid signature");
        return signer == user;
    }

    function msgSender() internal view returns(address sender) {
        if(msg.sender == address(this)) {
            bytes memory array = msg.data;
            uint256 index = msg.data.length;
            assembly {
                // Load the 32 bytes word from memory with the address on the lower 20 bytes, and mask those.
                sender := and(mload(add(array, index)), 0xffffffffffffffffffffffffffffffffffffffff)
            }
        } else {
            sender = msg.sender;
        }
        return sender;
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "@openzeppelin/contracts-upgradeable/metatx/ERC2771ContextUpgradeable.sol";

contract ERC2771Config is ERC2771ContextUpgradeable{

    address MOONRIVER_FWD;

    function __ERC2771Config_init() internal{
        MOONRIVER_FWD = 0x64CD353384109423a966dCd3Aa30D884C9b2E057;
        __ERC2771Context_init(MOONRIVER_FWD);
    }

}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.0 (token/ERC20/ERC20.sol)

pragma solidity ^0.8.0;

import "./IERC20.sol";
import "./extensions/IERC20Metadata.sol";
import "../../utils/Context.sol";

/**
 * @dev Implementation of the {IERC20} interface.
 *
 * This implementation is agnostic to the way tokens are created. This means
 * that a supply mechanism has to be added in a derived contract using {_mint}.
 * For a generic mechanism see {ERC20PresetMinterPauser}.
 *
 * TIP: For a detailed writeup see our guide
 * https://forum.zeppelin.solutions/t/how-to-implement-erc20-supply-mechanisms/226[How
 * to implement supply mechanisms].
 *
 * We have followed general OpenZeppelin Contracts guidelines: functions revert
 * instead returning `false` on failure. This behavior is nonetheless
 * conventional and does not conflict with the expectations of ERC20
 * applications.
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
contract ERC20 is Context, IERC20, IERC20Metadata {
    mapping(address => uint256) private _balances;

    mapping(address => mapping(address => uint256)) private _allowances;

    uint256 private _totalSupply;

    string private _name;
    string private _symbol;

    /**
     * @dev Sets the values for {name} and {symbol}.
     *
     * The default value of {decimals} is 18. To select a different value for
     * {decimals} you should overload it.
     *
     * All two of these values are immutable: they can only be set once during
     * construction.
     */
    constructor(string memory name_, string memory symbol_) {
        _name = name_;
        _symbol = symbol_;
    }

    /**
     * @dev Returns the name of the token.
     */
    function name() public view virtual override returns (string memory) {
        return _name;
    }

    /**
     * @dev Returns the symbol of the token, usually a shorter version of the
     * name.
     */
    function symbol() public view virtual override returns (string memory) {
        return _symbol;
    }

    /**
     * @dev Returns the number of decimals used to get its user representation.
     * For example, if `decimals` equals `2`, a balance of `505` tokens should
     * be displayed to a user as `5.05` (`505 / 10 ** 2`).
     *
     * Tokens usually opt for a value of 18, imitating the relationship between
     * Ether and Wei. This is the value {ERC20} uses, unless this function is
     * overridden;
     *
     * NOTE: This information is only used for _display_ purposes: it in
     * no way affects any of the arithmetic of the contract, including
     * {IERC20-balanceOf} and {IERC20-transfer}.
     */
    function decimals() public view virtual override returns (uint8) {
        return 18;
    }

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
     * required by the EIP. See the note at the beginning of {ERC20}.
     *
     * Requirements:
     *
     * - `sender` and `recipient` cannot be the zero address.
     * - `sender` must have a balance of at least `amount`.
     * - the caller must have allowance for ``sender``'s tokens of at least
     * `amount`.
     */
    function transferFrom(
        address sender,
        address recipient,
        uint256 amount
    ) public virtual override returns (bool) {
        _transfer(sender, recipient, amount);

        uint256 currentAllowance = _allowances[sender][_msgSender()];
        require(currentAllowance >= amount, "ERC20: transfer amount exceeds allowance");
        unchecked {
            _approve(sender, _msgSender(), currentAllowance - amount);
        }

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
        _approve(_msgSender(), spender, _allowances[_msgSender()][spender] + addedValue);
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
        uint256 currentAllowance = _allowances[_msgSender()][spender];
        require(currentAllowance >= subtractedValue, "ERC20: decreased allowance below zero");
        unchecked {
            _approve(_msgSender(), spender, currentAllowance - subtractedValue);
        }

        return true;
    }

    /**
     * @dev Moves `amount` of tokens from `sender` to `recipient`.
     *
     * This internal function is equivalent to {transfer}, and can be used to
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
    ) internal virtual {
        require(sender != address(0), "ERC20: transfer from the zero address");
        require(recipient != address(0), "ERC20: transfer to the zero address");

        _beforeTokenTransfer(sender, recipient, amount);

        uint256 senderBalance = _balances[sender];
        require(senderBalance >= amount, "ERC20: transfer amount exceeds balance");
        unchecked {
            _balances[sender] = senderBalance - amount;
        }
        _balances[recipient] += amount;

        emit Transfer(sender, recipient, amount);

        _afterTokenTransfer(sender, recipient, amount);
    }

    /** @dev Creates `amount` tokens and assigns them to `account`, increasing
     * the total supply.
     *
     * Emits a {Transfer} event with `from` set to the zero address.
     *
     * Requirements:
     *
     * - `account` cannot be the zero address.
     */
    function _mint(address account, uint256 amount) internal virtual {
        require(account != address(0), "ERC20: mint to the zero address");

        _beforeTokenTransfer(address(0), account, amount);

        _totalSupply += amount;
        _balances[account] += amount;
        emit Transfer(address(0), account, amount);

        _afterTokenTransfer(address(0), account, amount);
    }

    /**
     * @dev Destroys `amount` tokens from `account`, reducing the
     * total supply.
     *
     * Emits a {Transfer} event with `to` set to the zero address.
     *
     * Requirements:
     *
     * - `account` cannot be the zero address.
     * - `account` must have at least `amount` tokens.
     */
    function _burn(address account, uint256 amount) internal virtual {
        require(account != address(0), "ERC20: burn from the zero address");

        _beforeTokenTransfer(account, address(0), amount);

        uint256 accountBalance = _balances[account];
        require(accountBalance >= amount, "ERC20: burn amount exceeds balance");
        unchecked {
            _balances[account] = accountBalance - amount;
        }
        _totalSupply -= amount;

        emit Transfer(account, address(0), amount);

        _afterTokenTransfer(account, address(0), amount);
    }

    /**
     * @dev Sets `amount` as the allowance of `spender` over the `owner` s tokens.
     *
     * This internal function is equivalent to `approve`, and can be used to
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
    ) internal virtual {
        require(owner != address(0), "ERC20: approve from the zero address");
        require(spender != address(0), "ERC20: approve to the zero address");

        _allowances[owner][spender] = amount;
        emit Approval(owner, spender, amount);
    }

    /**
     * @dev Hook that is called before any transfer of tokens. This includes
     * minting and burning.
     *
     * Calling conditions:
     *
     * - when `from` and `to` are both non-zero, `amount` of ``from``'s tokens
     * will be transferred to `to`.
     * - when `from` is zero, `amount` tokens will be minted for `to`.
     * - when `to` is zero, `amount` of ``from``'s tokens will be burned.
     * - `from` and `to` are never both zero.
     *
     * To learn more about hooks, head to xref:ROOT:extending-contracts.adoc#using-hooks[Using Hooks].
     */
    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 amount
    ) internal virtual {}

    /**
     * @dev Hook that is called after any transfer of tokens. This includes
     * minting and burning.
     *
     * Calling conditions:
     *
     * - when `from` and `to` are both non-zero, `amount` of ``from``'s tokens
     * has been transferred to `to`.
     * - when `from` is zero, `amount` tokens have been minted for `to`.
     * - when `to` is zero, `amount` of ``from``'s tokens have been burned.
     * - `from` and `to` are never both zero.
     *
     * To learn more about hooks, head to xref:ROOT:extending-contracts.adoc#using-hooks[Using Hooks].
     */
    function _afterTokenTransfer(
        address from,
        address to,
        uint256 amount
    ) internal virtual {}
}

// SPDX-License: MIT

pragma solidity ^0.8.0;

interface IHashtagNFTCollectiveManager {

    function buyoutFee() external view returns (uint256);

    function governor() external view returns (address);

    function nftVault() external view returns (address);

    function burnApproved(address token,uint256 tokenId) external view returns(bool);

    function approveBurn(address token, uint256 tokenId) external ;

    function mintTo(address receiver, uint256 supply) external returns(bool);

    function setAutosaleSEDCSetting(uint256 collectliveTokens, uint256 seedcTokens, uint256 saleLimit) external;

    function makeBuyInOffer(uint256 itemId, string memory offerId, uint256 tokenAmount, uint256 amountEthWeth, uint256 expiry, address erc20Token) external payable;

    function acceptBuyInOffer(string memory offerId) external;

    function refundMyExpiredOffer(uint256 itemId, string memory offerId) external;

    function mintGovernor() external returns (address);

    function setBuyOutAmount(uint256 amount) external returns(bool);

    function buyOut(address buyer) external payable returns (bool);

    function transferOwnershipTo(address newOwner) external;

    function transferStakeToOwner(address from) external;

    function treasuryBurnAmount(address burnAddress, uint256 amount) external;

    // function setAutosaleSEEDCSetting(uint256 collectliveTokens, uint256 seedcTokens, uint256 saleLimit) external;

    event requestedReleaseAssetsOwnership(address buyer);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.0 (utils/Context.sol)

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
    function __Context_init() internal initializer {
        __Context_init_unchained();
    }

    function __Context_init_unchained() internal initializer {
    }
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes calldata) {
        return msg.data;
    }
    uint256[50] private __gap;
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.0 (proxy/utils/Initializable.sol)

pragma solidity ^0.8.0;

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
        require(_initializing || !_initialized, "Initializable: contract is already initialized");

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
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.0 (token/ERC721/IERC721.sol)

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
// OpenZeppelin Contracts v4.4.0 (token/ERC721/IERC721Receiver.sol)

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
// OpenZeppelin Contracts v4.4.0 (token/ERC721/extensions/IERC721Metadata.sol)

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
// OpenZeppelin Contracts v4.4.0 (utils/Address.sol)

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
// OpenZeppelin Contracts v4.4.0 (utils/introspection/ERC165.sol)

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
    function __ERC165_init() internal initializer {
        __ERC165_init_unchained();
    }

    function __ERC165_init_unchained() internal initializer {
    }
    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId) public view virtual override returns (bool) {
        return interfaceId == type(IERC165Upgradeable).interfaceId;
    }
    uint256[50] private __gap;
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.0 (utils/introspection/IERC165.sol)

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
// OpenZeppelin Contracts v4.4.0 (utils/Context.sol)

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
// OpenZeppelin Contracts v4.4.0 (utils/introspection/IERC165.sol)

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

pragma solidity ^0.8.0;

import "@openzeppelin/contracts/utils/introspection/IERC165.sol";

interface IERCX {
    event TransferUser(
        address indexed from,
        address indexed to,
        uint256 indexed itemId,
        address operator
    );
    event ApprovalForUser(
        address indexed user,
        address indexed approved,
        uint256 itemId
    );
    event TransferOwner(
        address indexed from,
        address indexed to,
        uint256 indexed itemId,
        address operator
    );
    event ApprovalForOwner(
        address indexed owner,
        address indexed approved,
        uint256 itemId
    );
    event LienApproval(address indexed to, uint256 indexed itemId);
    event TenantRightApproval(address indexed to, uint256 indexed itemId);
    event LienSet(address indexed to, uint256 indexed itemId, bool status);
    event TenantRightSet(
        address indexed to,
        uint256 indexed itemId,
        bool status
    );

    function balanceOfOwner(address owner) external  view returns (uint256);

    function balanceOfUser(address user) external  view returns (uint256);

    function userOf(uint256 itemId) external  view returns (address);

    function ownerOf(uint256 itemId) external  view returns (address);

    function safeTransferOwner(address from, address to, uint256 itemId) external ;
    function safeTransferOwner(
        address from,
        address to,
        uint256 itemId,
        bytes memory data
    ) external ;

    function safeTransferUser(address from, address to, uint256 itemId) external ;
    function safeTransferUser(
        address from,
        address to,
        uint256 itemId,
        bytes memory data
    ) external ;

    function approveForOwner(address to, uint256 itemId) external ;
    function getApprovedForOwner(uint256 itemId) external  view returns (address);

    function approveForUser(address to, uint256 itemId) external ;
    function getApprovedForUser(uint256 itemId) external  view returns (address);

    function setApprovalForAll(address operator, bool approved) external ;
    function isApprovedForAll(address requester, address operator)
        external
        
        view
        returns (bool);

    function approveLien(address to, uint256 itemId) external ;
    function getApprovedLien(uint256 itemId) external  view returns (address);
    function setLien(uint256 itemId) external ;
    function getCurrentLien(uint256 itemId) external  view returns (address);
    function revokeLien(uint256 itemId) external ;

    function approveTenantRight(address to, uint256 itemId) external ;
    function getApprovedTenantRight(uint256 itemId)
        external
        view
        returns (address);
    function setTenantRight(uint256 itemId) external ;
    function getCurrentTenantRight(uint256 itemId)
        external
        
        view
        returns (address);
    function revokeTenantRight(uint256 itemId) external ;
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

library AddressX {
    /**
     * @dev Returns true if `account` is a contract.
     *
     * This test is non-exhaustive, and there may be false-negatives: during the
     * execution of a contract's constructor, its address will be reported as
     * not containing a contract.
     *
     * > It is unsafe to assume that an address for which this function returns
     * false is an externally-owned account (EOA) and not a contract.
     */
    function isContract(address account) internal view returns (bool) {
        // This method relies in extcodesize, which returns 0 for contracts in
        // construction, since the code is only stored at the end of the
        // constructor execution.

        uint256 size;
        // solhint-disable-next-line no-inline-assembly
        assembly { size := extcodesize(account) }
        return size > 0;
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.0 (utils/math/SafeMath.sol)

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
library SafeMathUpgradeable {
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
     * @dev Returns the substraction of two unsigned integers, with an overflow flag.
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

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.0 (utils/Counters.sol)

pragma solidity ^0.8.0;

/**
 * @title Counters
 * @author Matt Condon (@shrugs)
 * @dev Provides counters that can only be incremented, decremented or reset. This can be used e.g. to track the number
 * of elements in a mapping, issuing ERC721 ids, or counting request ids.
 *
 * Include with `using Counters for Counters.Counter;`
 */
library Counters {
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

pragma solidity ^0.8.0;

/**
 * @title ERCX token receiver interface
 * @dev Interface for any contract that wants to support safeTransfers
 * from ERCX asset contracts.
 */
interface IERCXReceiver {
    /**
    * @notice Handle the receipt of an NFT
    * @dev The ERCX smart contract calls this function on the recipient
    * after a {IERCX-safeTransferFrom}. This function MUST return the function selector,
    * otherwise the caller will revert the transaction. The selector to be
    * returned can be obtained as `this.onERCXReceived.selector`. This
    * function MAY throw to revert and reject the transfer.
    * Note: the ERCX contract address is always the message sender.
    * @param operator The address which called `safeTransferFrom` function
    * @param from The address which previously owned the token
    * @param itemId The NFT identifier which is being transferred
    * @param data Additional data with no specified format
    * @return bytes4 `bytes4(keccak256("onERCXReceived(address,address,uint256,uint256,bytes)"))`
    */
    function onERCXReceived(
        address operator,
        address from,
        uint256 itemId,
        uint256 layer,
        bytes memory data
    ) external  returns (bytes4);
}

//SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;
import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";

contract EIP712Base is Initializable {

    struct EIP712Domain {
        string name;
        string version;
        address verifyingContract;
        bytes32 salt;
    }

    bytes32 internal constant EIP712_DOMAIN_TYPEHASH = keccak256(bytes("EIP712Domain(string name,string version,address verifyingContract,bytes32 salt)"));

    bytes32 internal domainSeparator;

    // constructor(string memory name, string memory version) {
    //     domainSeparator = keccak256(abi.encode(
    //         EIP712_DOMAIN_TYPEHASH,
    //         keccak256(bytes(name)),
    //         keccak256(bytes(version)),
    //         address(this),
    //         bytes32(getChainID())
    //     ));
    // }

    function __EIP712Base_init(string memory name, string memory version) internal initializer {
        domainSeparator = keccak256(abi.encode(
            EIP712_DOMAIN_TYPEHASH,
            keccak256(bytes(name)),
            keccak256(bytes(version)),
            address(this),
            bytes32(getChainID())
        ));
    }

    function getChainID() internal view returns (uint256 id) {
        assembly {
            id := chainid()
        }
    }

    function getDomainSeparator() private view returns(bytes32) {
        return domainSeparator;
    }

    /**
    * Accept message hash and returns hash message in EIP712 compatible form
    * So that it can be used to recover signer from signature signed using EIP712 formatted data
    * https://eips.ethereum.org/EIPS/eip-712
    * "\\x19" makes the encoding deterministic
    * "\\x01" is the version byte to make it compatible to EIP-191
    */
    function toTypedMessageHash(bytes32 messageHash) internal view returns(bytes32) {
        return keccak256(abi.encodePacked("\x19\x01", getDomainSeparator(), messageHash));
    }

}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.0 (metatx/ERC2771Context.sol)

pragma solidity ^0.8.0;

import "../utils/ContextUpgradeable.sol";
import "../proxy/utils/Initializable.sol";

/**
 * @dev Context variant with ERC2771 support.
 */
abstract contract ERC2771ContextUpgradeable is Initializable, ContextUpgradeable {
    address private _trustedForwarder;

    function __ERC2771Context_init(address trustedForwarder) internal initializer {
        __Context_init_unchained();
        __ERC2771Context_init_unchained(trustedForwarder);
    }

    function __ERC2771Context_init_unchained(address trustedForwarder) internal initializer {
        _trustedForwarder = trustedForwarder;
    }

    function isTrustedForwarder(address forwarder) public view virtual returns (bool) {
        return forwarder == _trustedForwarder;
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

pragma solidity ^0.8.0;

import "./ERCX.sol";
import "./ERCXEnumerable.sol";
import "./ERCXMetadata.sol";
import "./ERCX721fier.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/IERC721Metadata.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";


contract ERCXFull is
    Initializable,
    ERCX,
    ERCXEnumerable,
    IERC721Metadata,
    ERCXMetadata,
    ERCX721fier
{
    // constructor(string memory name, string memory symbol)
    //     ERCXMetadata(name, symbol)
    // {}

    function __ERCXFull_init(string memory name, string memory symbol) public initializer
    {
        __ERCXMetadata_init(name, symbol);
    }

    function _mint(address to, uint256 itemId)
        internal
        override(ERCX, ERCXEnumerable)
    {
        super._mint(to, itemId);
    }

    function _burn(uint256 itemId)
        internal
        override(ERCX, ERCXEnumerable, ERCXMetadata)
    {
        super._burn(itemId);
    }

    function _transfer(
        address from,
        address to,
        uint256 itemId,
        uint256 layer
    ) internal virtual override(ERCX, ERCXEnumerable) {
        super._transfer(from, to, itemId, layer);
    }

    function getCurrentLien(uint256 itemId)
        public
        view
        virtual
        override(ERCX, ERCXEnumerable)
        returns (address)
    {
        return _getCurrentLien(itemId);
    }

    function isApprovedForAll(address owner, address operator)
        public
        view
        virtual
        override(IERC721, ERCX, ERCX721fier)
        returns (bool)
    {
        return _isApprovedForAll(owner, operator);
    }

    function ownerOf(uint256 itemId)
        external
        view
        virtual
        override(IERC721, ERCX, ERCX721fier)
        returns (address)
    {
        return _ownerOf(itemId);
    }

    function setApprovalForAll(address to, bool approved)
        external
        virtual
        override(IERC721, ERCX, ERCX721fier)
    {
        _setApprovalForAll(to, approved);
    }

    function name()
        external
        view
        override(IERC721Metadata, ERCXMetadata)
        returns (string memory)
    {
        return _name;
    }

    function symbol()
        external
        view
        override(IERC721Metadata, ERCXMetadata)
        returns (string memory)
    {
        return _symbol;
    }

    function tokenURI(uint256 tokenId)
        external
        view
        override(IERC721Metadata)
        returns (string memory)
    {
        return _itemURI(tokenId);
    }

    function safeTransferOwner(address from, address to, uint256 itemId) external virtual override(ERCX) {
        _safeTransferOwner(from, to, itemId, "");
    }

    function supportsInterface(bytes4 interfaceId) public view virtual override(IERC165, ERCX721fier,ERCX,ERCXEnumerable,ERCXMetadata) returns (bool) {
        return super.supportsInterface(interfaceId);
    }
}

pragma solidity ^0.8.0;

import "./ERCX.sol";
import "./Interface/IERCXEnumerable.sol";
import "@openzeppelin/contracts-upgradeable/utils/introspection/ERC165StorageUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "@openzeppelin/contracts-upgradeable/utils/math/SafeMathUpgradeable.sol";

contract ERCXEnumerable is Initializable, ERC165StorageUpgradeable, ERCX, IERCXEnumerable {

    using SafeMathUpgradeable for uint256;

    // Mapping from layer to owner to list of owned item IDs
    mapping(uint256 => mapping(address => uint256[])) private _ownedItems;

    // Mapping from layer to item ID to index of the owner items list
    mapping(uint256 => mapping(uint256 => uint256)) private _ownedItemsIndex;

    // Array with all item ids, used for enumeration
    uint256[] private _allItems;

    // Mapping from item id to position in the allItems array
    mapping(uint256 => uint256) private _allItemsIndex;

    bytes4 private constant _InterfaceId_ERCXEnumerable = bytes4(
        keccak256("totalNumberOfItems()")
    ) ^
        bytes4(keccak256("itemOfOwnerByIndex(address,uint256,uint256)")) ^
        bytes4(keccak256("itemByIndex(uint256)"));

    /**
   * @dev Constructor function
   */
    // constructor() {
    //     // register the supported interface to conform to ERCX via ERC165
    //     _registerInterface(_InterfaceId_ERCXEnumerable);
    // }

    function __ERCXEnumerable_init() public initializer{
        _registerInterface(_InterfaceId_ERCXEnumerable);
    }

    /**
   * @dev Gets the item ID at a given index of the items list of the requested user
   * @param user address owning the items list to be accessed
   * @param index uint256 representing the index to be accessed of the requested items list
   * @return uint256 item ID at the given index of the items list owned by the requested address
   */

    function itemOfUserByIndex(address user, uint256 index)
        external
        override
        view
        returns (uint256)
    {
        require(index < _balanceOfUser(user));
        return _ownedItems[1][user][index];
    }

    /**
   * @dev Gets the item ID at a given index of the items list of the requested owner
   * @param owner address owning the items list to be accessed
   * @param index uint256 representing the index to be accessed of the requested items list
   * @return uint256 item ID at the given index of the items list owned by the requested address
   */

    function itemOfOwnerByIndex(address owner, uint256 index)
        external
        override
        view
        returns (uint256)
    {
        require(index < _balanceOfOwner(owner));
        return _ownedItems[2][owner][index];
    }

    /**
   * @dev Gets the total amount of items stored by the contract
   * @return uint256 representing the total amount of items
   */
    function totalNumberOfItems() external override view returns (uint256) {
        return _totalNumberOfItems();
    }

    function _totalNumberOfItems() internal view returns (uint256) {
        return _allItems.length;
    }

    /**
   * @dev Gets the item ID at a given index of all the items in this contract
   * Reverts if the index is greater or equal to the total number of items
   * @param index uint256 representing the index to be accessed of the items list
   * @return uint256 item ID at the given index of the items list
   */
    function itemByIndex(uint256 index) external override view returns (uint256) {
        require(index < _totalNumberOfItems());
        return _allItems[index];
    }

    /**
    * @dev Internal function to transfer ownership of a given item ID to another address.
    * As opposed to transfer, this imposes no restrictions on msgSender().
    * @param from current owner of the item
    * @param to address to receive the ownership of the given item ID
    * @param itemId uint256 ID of the item to be transferred
    * @param layer uint256 number to specify the layer
    */
    function _transfer(address from, address to, uint256 itemId, uint256 layer)
        internal
        virtual
        override(ERCX)
    {
        super._transfer(from, to, itemId, layer);
        _removeItemFromOwnerEnumeration(from, itemId, layer);
        _addItemToOwnerEnumeration(to, itemId, layer);
    }

    /**
    * @dev Internal function to mint a new item.
    * Reverts if the given item ID already exists.
    * @param to address the beneficiary that will own the minted item
    * @param itemId uint256 ID of the item to be minted
    */
    function _mint(address to, uint256 itemId) override internal virtual {
        super._mint(to, itemId);

        _addItemToOwnerEnumeration(to, itemId, 1);
        _addItemToOwnerEnumeration(to, itemId, 2);

        _addItemToAllItemsEnumeration(itemId);
    }

    /**
    * @dev Internal function to burn a specific item.
    * Reverts if the item does not exist.
    * Deprecated, use {ERCX-_burn} instead.
    * @param itemId uint256 ID of the item being burned
    */
    function _burn(uint256 itemId) internal virtual override(ERCX) {
        address user = _userOf(itemId);
        address owner = _ownerOf(itemId);

        super._burn(itemId);

        _removeItemFromOwnerEnumeration(user, itemId, 1);
        _removeItemFromOwnerEnumeration(owner, itemId, 2);

        // Since itemId will be deleted, we can clear its slot in _ownedItemsIndex to trigger a gas refund
        _ownedItemsIndex[1][itemId] = 0;
        _ownedItemsIndex[2][itemId] = 0;

        _removeItemFromAllItemsEnumeration(itemId);

    }

    /**
    * @dev Private function to add a item to this extension's ownership-tracking data structures.
    * @param to address representing the new owner of the given item ID
    * @param itemId uint256 ID of the item to be added to the items list of the given address
    */
    function _addItemToOwnerEnumeration(
        address to,
        uint256 itemId,
        uint256 layer
    ) private {
        _ownedItemsIndex[layer][itemId] = _ownedItems[layer][to].length;
        _ownedItems[layer][to].push(itemId);
    }

    /**
    * @dev Private function to add a item to this extension's item tracking data structures.
    * @param itemId uint256 ID of the item to be added to the items list
    */
    function _addItemToAllItemsEnumeration(uint256 itemId) private {
        _allItemsIndex[itemId] = _allItems.length;
        _allItems.push(itemId);
    }

    /**
    * @dev Private function to remove a item from this extension's ownership-tracking data structures. Note that
    * while the item is not assigned a new owner, the `_ownedItemsIndex` mapping is _not_ updated: this allows for
    * gas optimizations e.g. when performing a transfer operation (avoiding double writes).
    * This has O(1) time complexity, but alters the order of the _ownedItems array.
    * @param from address representing the previous owner of the given item ID
    * @param itemId uint256 ID of the item to be removed from the items list of the given address
    */
    function _removeItemFromOwnerEnumeration(
        address from,
        uint256 itemId,
        uint256 layer
    ) private {
        // To prevent a gap in from's items array, we store the last item in the index of the item to delete, and
        // then delete the last slot (swap and pop).

        uint256 lastItemIndex = _ownedItems[layer][from].length.sub(1);
        uint256 itemIndex = _ownedItemsIndex[layer][itemId];

        // When the item to delete is the last item, the swap operation is unnecessary
        if (itemIndex != lastItemIndex) {
            uint256 lastItemId = _ownedItems[layer][from][lastItemIndex];

            _ownedItems[layer][from][itemIndex] = lastItemId; // Move the last item to the slot of the to-delete item
            _ownedItemsIndex[layer][lastItemId] = itemIndex; // Update the moved item's index
        }

        // This also deletes the contents at the last position of the array

        /** */
        delete _ownedItems[layer][from][_ownedItems[layer][from].length-1];
        // _ownedItems[layer][from].length--;

        // Note that _ownedItemsIndex[itemId] hasn't been cleared: it still points to the old slot (now occupied by
        // lastItemId, or just over the end of the array if the item was the last one).

    }

    /**
    * @dev Private function to remove a item from this extension's item tracking data structures.
    * This has O(1) time complexity, but alters the order of the _allItems array.
    * @param itemId uint256 ID of the item to be removed from the items list
    */
    function _removeItemFromAllItemsEnumeration(uint256 itemId) private {
        // To prevent a gap in the items array, we store the last item in the index of the item to delete, and
        // then delete the last slot (swap and pop).

        uint256 lastItemIndex = _allItems.length.sub(1);
        uint256 itemIndex = _allItemsIndex[itemId];

        // When the item to delete is the last item, the swap operation is unnecessary. However, since this occurs so
        // rarely (when the last minted item is burnt) that we still do the swap here to avoid the gas cost of adding
        // an 'if' statement (like in _removeItemFromOwnerEnumeration)
        uint256 lastItemId = _allItems[lastItemIndex];

        _allItems[itemIndex] = lastItemId; // Move the last item to the slot of the to-delete item
        _allItemsIndex[lastItemId] = itemIndex; // Update the moved item's index

        // This also deletes the contents at the last position of the array
        delete _allItems[_allItems.length-1];
        // _allItems.length--;
        _allItemsIndex[itemId] = 0;
    }

    function getCurrentLien(uint256 itemId) public override(ERCX,IERCX) view virtual  returns (address) {
        return _getCurrentLien(itemId);
    }

    function supportsInterface(bytes4 interfaceId) public view virtual override(ERC165StorageUpgradeable,ERCX) returns (bool) {
        return super.supportsInterface(interfaceId);
    }
}

pragma solidity ^0.8.0;

import './ERCX.sol';
import './Interface/IERCXMetadata.sol';
import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "@openzeppelin/contracts-upgradeable/utils/introspection/ERC165StorageUpgradeable.sol";

contract ERCXMetadata is Initializable, ERC165StorageUpgradeable, ERCX, IERCXMetadata {
  // item name
  string internal _name;

  // item symbol
  string internal _symbol;

  // Base URI
  string private _baseURI;

  // Optional mapping for item URIs
  mapping(uint256 => string) private _itemURIs;

  bytes4 private constant InterfaceId_ERCXMetadata =
    bytes4(keccak256('name()')) ^
    bytes4(keccak256('symbol()')) ^
    bytes4(keccak256('itemURI(uint256)'));

  /**
   * @dev Constructor function
   */
  // constructor(string memory name, string memory symbol) {
  //   _name = name;
  //   _symbol = symbol;

  //   // register the supported interfaces to conform to ERCX via ERC165
  //   _registerInterface(InterfaceId_ERCXMetadata);
  // }

  function __ERCXMetadata_init (string memory name, string memory symbol) public initializer{
    __ERC165Storage_init();
    __ERCX_init();
    _name = name;
    _symbol = symbol;
    // register the supported interfaces to conform to ERCX via ERC165
    _registerInterface(InterfaceId_ERCXMetadata);
  }
  

  /**
   * @dev Gets the item name
   * @return string representing the item name
   */
  function name() external virtual override view returns (string memory) {
    return _name;
  }

  /**
   * @dev Gets the item symbol
   * @return string representing the item symbol
   */
  function symbol() external virtual override view returns (string memory) {
    return _symbol;
  }

  /**
   * @dev Returns an URI for a given item ID
   * Throws if the item ID does not exist. May return an empty string.
   * @param itemId uint256 ID of the item to query
   */
  function itemURI(uint256 itemId) external override view returns (string memory) {
    return _itemURI(itemId);
  }

  function _itemURI(uint256 itemId) internal view returns (string memory){
    require(
      _exists(itemId,1),
      "URI query for nonexistent item");

    string memory _itemURI = _itemURIs[itemId];

    // Even if there is a base URI, it is only appended to non-empty item-specific URIs
    if (bytes(_itemURI).length == 0) {
        return "";
    } else {
        // abi.encodePacked is being used to concatenate strings
        return string(abi.encodePacked(_baseURI, _itemURI));
    }
  }

  /**
  * @dev Returns the base URI set via {_setBaseURI}. This will be
  * automatically added as a preffix in {itemURI} to each item's URI, when
  * they are non-empty.
  */
  function baseURI() external view returns (string memory) {
      return _baseURI;
  }

  /**
   * @dev Internal function to set the item URI for a given item
   * Reverts if the item ID does not exist
   * @param itemId uint256 ID of the item to set its URI
   * @param uri string URI to assign
   */
  function _setItemURI(uint256 itemId, string memory uri) internal {
    require(_exists(itemId,1));
    _itemURIs[itemId] = uri;
  }

  function _setTokenURI(uint256 itemId, string memory uri) internal {
    _setItemURI(itemId, uri);
  }

  /**
    * @dev Internal function to set the base URI for all item IDs. It is
    * automatically added as a prefix to the value returned in {itemURI}.
    *
    * _Available since v2.5.0._
    */
  function _setBaseURI(string memory baseUri) internal {
      _baseURI = baseUri;
  }

  /**
   * @dev Internal function to burn a specific item
   * Reverts if the item does not exist
   * @param itemId uint256 ID of the item being burned by the msgSender()
   */
  function _burn(uint256 itemId) internal virtual override(ERCX) {
    super._burn(itemId);

    // Clear metadata (if any)
    if (bytes(_itemURIs[itemId]).length != 0) {
      delete _itemURIs[itemId];
    }

  }
    function supportsInterface(bytes4 interfaceId) public view virtual override(ERC165StorageUpgradeable,ERCX) returns (bool) {
        return super.supportsInterface(interfaceId);
    }
}

pragma solidity ^0.8.0;

import "./ERCX.sol";
import "./Libraries/AddressX.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import "@openzeppelin/contracts-upgradeable/utils/introspection/ERC165StorageUpgradeable.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721Receiver.sol";

/**
 * @title ERC721 Non-Fungible Token Standard compatible layer
 * Each items here represents owner of the item set.
 * By implementing this contract set, ERCX can pretend to be an ERC721 contrtact set.
 * @dev see https://eips.ethereum.org/EIPS/eip-721
 */
contract ERCX721fier is ERC165StorageUpgradeable, IERC721, ERCX {
    bytes4 private constant _ERC721_RECEIVED = 0x150b7a02;
    bytes4 private constant _INTERFACE_ID_ERC721 = 0x80ac58cd;

    using AddressX for address;

    // constructor() {
    //     // register the supported interfaces to conform to ERC721 via ERC165
    //     _registerInterface(_INTERFACE_ID_ERC721);
    // }

    function __ERCX721fier_init() external {
        __ERC165Storage_init();
        _registerInterface(_INTERFACE_ID_ERC721);
    }

    function balanceOf(address owner) external view override returns (uint256) {
        return _balanceOfOwner(owner);
    }

    function ownerOf(uint256 itemId)
        external
        view
        virtual
        override(IERC721, ERCX)
        returns (address)
    {
        return _ownerOf(itemId);
    }

    // function _ownerOf(uint256 itemId) internal virtual view returns (address) {
    //     return super.ownerOf(itemId);
    // }

    function approve(address to, uint256 itemId) external override {
        _approveForOwner(to, itemId);
        address owner = _ownerOf(itemId);
        emit Approval(owner, to, itemId);
    }

    function getApproved(uint256 itemId)
        external
        view
        override
        returns (address)
    {
        return _getApprovedForOwner(itemId);
    }

    function transferFrom(
        address from,
        address to,
        uint256 itemId
    ) external override {
        _transferFrom(from, to, itemId);
    }

    function _transferFrom(
        address from,
        address to,
        uint256 itemId
    ) internal {
        require(_isEligibleForTransfer(_msgSender(), itemId, 2));
        if (_getCurrentTenantRight(itemId) == address(0)) {
            _transfer(from, to, itemId, 1);
            _transfer(from, to, itemId, 2);
        } else {
            _transfer(from, to, itemId, 2);
        }
        emit Transfer(from, to, itemId);
    }

    function safeTransferFrom(
        address from,
        address to,
        uint256 itemId
    ) external override {
        _safeTransferFrom(from, to, itemId, "");
    }

    function safeTransferFrom(
        address from,
        address to,
        uint256 itemId,
        bytes memory data
    ) external override {
        _safeTransferFrom(from, to, itemId, data);
    }

    function _safeTransferFrom(
        address from,
        address to,
        uint256 itemId,
        bytes memory data
    ) internal {
        _transferFrom(from, to, itemId);
        require(
            _checkOnERC721Received(from, to, itemId, data),
            "ERC721: transfer to non ERC721Receiver implementer"
        );
    }

    function _checkOnERC721Received(
        address from,
        address to,
        uint256 itemId,
        bytes memory data
    ) internal returns (bool) {
        if (!to.isContract()) {
            return true;
        }

        bytes4 retval = IERC721Receiver(to).onERC721Received(
            _msgSender(),
            from,
            itemId,
            data
        );
        return (retval == _ERC721_RECEIVED);
    }

    function isApprovedForAll(address owner, address operator)
        public
        view
        virtual
        override(IERC721, ERCX)
        returns (bool)
    {
        return _isApprovedForAll(owner, operator);
    }

    function setApprovalForAll(address to, bool approved)
        external
        virtual
        override(IERC721, ERCX)
    {
        _setApprovalForAll(to, approved);
    }

    function supportsInterface(bytes4 interfaceId)
        public
        view
        virtual
        override(ERC165StorageUpgradeable, IERC165, ERCX)
        returns (bool)
    {
        return super.supportsInterface(interfaceId);
    }
}

pragma solidity ^0.8.0;

import "./IERCX.sol";

interface IERCXEnumerable is IERCX {
    function totalNumberOfItems() external view returns (uint256);
    function itemOfUserByIndex(address owner, uint256 index)
        external
        view
        returns (uint256 itemId);
    function itemOfOwnerByIndex(address owner, uint256 index)
        external
        view
        returns (uint256 itemId);
    function itemByIndex(uint256 index) external view returns (uint256);

}

pragma solidity ^0.8.0;

import './IERCX.sol';
interface IERCXMetadata is IERCX {
  function itemURI(uint256 itemId) external view returns (string memory);
  function name() external view returns (string memory);
  function symbol() external view returns (string memory);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.0 (token/ERC721/IERC721Receiver.sol)

pragma solidity ^0.8.0;

/**
 * @title ERC721 token receiver interface
 * @dev Interface for any contract that wants to support safeTransfers
 * from ERC721 asset contracts.
 */
interface IERC721Receiver {
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
// OpenZeppelin Contracts v4.4.0 (token/ERC20/IERC20.sol)

pragma solidity ^0.8.0;

/**
 * @dev Interface of the ERC20 standard as defined in the EIP.
 */
interface IERC20 {
    /**
     * @dev Returns the amount of tokens in existence.
     */
    function totalSupply() external view returns (uint256);

    /**
     * @dev Returns the amount of tokens owned by `account`.
     */
    function balanceOf(address account) external view returns (uint256);

    /**
     * @dev Moves `amount` tokens from the caller's account to `recipient`.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transfer(address recipient, uint256 amount) external returns (bool);

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
     * @dev Moves `amount` tokens from `sender` to `recipient` using the
     * allowance mechanism. `amount` is then deducted from the caller's
     * allowance.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transferFrom(
        address sender,
        address recipient,
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

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.0 (token/ERC20/extensions/IERC20Metadata.sol)

pragma solidity ^0.8.0;

import "../IERC20.sol";

/**
 * @dev Interface for the optional metadata functions from the ERC20 standard.
 *
 * _Available since v4.1._
 */
interface IERC20Metadata is IERC20 {
    /**
     * @dev Returns the name of the token.
     */
    function name() external view returns (string memory);

    /**
     * @dev Returns the symbol of the token.
     */
    function symbol() external view returns (string memory);

    /**
     * @dev Returns the decimals places of the token.
     */
    function decimals() external view returns (uint8);
}