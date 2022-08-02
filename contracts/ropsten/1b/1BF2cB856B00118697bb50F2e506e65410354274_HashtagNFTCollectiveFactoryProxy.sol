// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/security/PausableUpgradeable.sol";
import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC721/utils/ERC721HolderUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC20/utils/SafeERC20Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC20/IERC20Upgradeable.sol";
import "./HashtagNFTCollectiveERC721.sol";
import "./HashtagNFTCollectiveUtils.sol";
import "./Interface/IHashtagNFTCollectiveManager.sol";
import "./InitializedProxy.sol";
import "./Settings.sol";
import "./HashtagNFTCollectiveManager.sol";
import "./Interface/IHashtagNFTCollectiveERC721.sol";
import "./Interface/IHashtagNFTCollectiveFactoryProxy.sol";
import "./Interface/ISetting.sol";
import "./Interface/IHashtagNFTCollectiveResolver.sol";
import "./EIP712MetaTransaction.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/IERC721Metadata.sol";
import "@openzeppelin/contracts-upgradeable/security/ReentrancyGuardUpgradeable.sol";

contract HashtagNFTCollectiveFactoryProxy is
    Initializable,
    OwnableUpgradeable,
    PausableUpgradeable,
    ERC721HolderUpgradeable,
    HashtagNFTCollectiveUtils,
    ERC2771Config,
    IHashtagNFTCollectiveFactoryProxy,
    ReentrancyGuardUpgradeable
{
    /// @notice the number of NFT Vaults and Collective Manager
    uint256 public vaultCount;

    address public constant LIVETREE_ADDRESS = address(0xa4Bd0Bd50f12e43796eC8C50D66EEF484900a7b4);

    address public deployer;

    address public resolver;

    address private seedCToken;

    string nftDefaultLicenseURL;

    mapping(address => NFTInfo[]) public ownerNFTList;

    mapping(address => uint256) public ownerCount;

    mapping(uint256 => bool) public itemIdMinted;

    /// @notice the mapping of vault number to vault contract
    mapping(uint256 => address) public managers;

    mapping(uint256 => address) public nftVaults;

    /// @notice a settings contract controlled by governance
    address public settings;

    /// @notice the Collective Manager logic contract
    address public managerLogic;

    /// @notice the NFTVault logic
    address public nftVaultLogic;

    /// @notice the NFT logic contract
    address public nftLogic;

    /// @notice the Settings contract
    address public settingsLogic;

    address[] private royaltyItemMgrSettings;

    address private governorLogic;

    address private treasury;

    address private timelockControllerLogic;

    mapping(uint256 => string) public proxyMint;

    mapping(uint256 => address) private proxyMintItem;

    mapping(uint256 => bool) public proxyMintTransferred;

    using SafeERC20Upgradeable for IERC20Upgradeable;

    event Mint(
        address indexed token,
        uint256 id,
        address vault,
        uint256 vaultId,
        address owner,
        address buyerAddress,
        uint256 buyerNumberofERC20
    );

    event MintNFT(
        address indexed token,
        uint256 indexed itemId,
        address indexed owner
    );

    function initialize(
        address _settings,
        address _managerLogic,
        address _nftVaultLogic,
        address _nftLogic,
        address _settingsLogic,
        address _timelockControllerLogic,
        address _govLogic,
        address _treasury,
        address _resolver,
        string memory _nftDefaultLicenseURL
    ) external initializer {
        __ERC2771Config_init();
        __ERC721Holder_init();
        __Ownable_init();
        __Pausable_init();
        __HashtagNFTCollectiveUtils_init();
        settings = _settings;
        managerLogic = _managerLogic;
        nftVaultLogic = _nftVaultLogic;
        nftLogic = _nftLogic;
        seedCToken = address(0x0);
        settingsLogic = _settingsLogic;
        timelockControllerLogic = _timelockControllerLogic;
        governorLogic = _govLogic;
        treasury = _treasury;
        deployer = _msgSender();
        resolver = _resolver;
        nftDefaultLicenseURL = _nftDefaultLicenseURL;
    }

    function byteId(string memory sequence) internal pure returns (bytes32) {
        return keccak256(abi.encodePacked(sequence));
    }

    function userTokenExists(
        address user,
        string memory name,
        string memory symbol
    ) public view returns (bool, uint256) {
        if (ownerCount[user] == 0)
            return (false, 0);

        NFTInfo[] memory ownerNFTs = ownerNFTList[user];
        for (uint256 i; i < ownerCount[user]; i++)
            if (byteId(name) == byteId(ownerNFTs[i].name) && byteId(symbol) == byteId(ownerNFTs[i].symbol))
                return (true, i);
    }

    function isUniqueItemId(uint256 itemId) internal view returns (bool) {
        return !itemIdMinted[itemId];
    }

    function hashtagNFTCollectiveExists(string calldata name)
        external
        view
        override
        returns (bool)
    {
        return _hashtagNFTCollectiveExists(name);
    }

    function _hashtagNFTCollectiveExists(string memory name)
        internal
        view
        returns (bool)
    {
        return (IHashtagNFTCollectiveResolver(resolver).ResolveURI(name) != address(0x0));
    }

    function _mintManagerCalldata(
        address token,
        address _setting,
        address _nftVault,
        MintCollectiveParams memory params
    ) internal view returns (bytes memory) {
        return
            abi.encodeWithSignature(
                "initialize(address,address,uint256,address,address,string,string,address)",
                _msgSender(),
                token,
                params.totalSupply,
                _setting,
                _nftVault,
                params.erc20TokenName,
                params.erc20TokenSymbol,
                timelockControllerLogic
            );
    }

    function _validateMintParams(
        uint256 itemId,
        string memory erc20TokenName,
        string memory erc20TokenSymbol,
        string memory nftMetadataJsonUrl,
        bool isMintItem
    ) internal {
        require(isUniqueItemId(itemId), "FactoryProxy: itemId already exists");
        require(bytes(erc20TokenName).length > 0, "FactoryProxy: empty erc20TokenName");
        require(bytes(erc20TokenSymbol).length > 0, "FactoryProxy: empty erc20TokenSymbol");
        require(bytes(nftMetadataJsonUrl).length > 0, "FactoryProxy: empty nftMetadataJsonUrl");

        bool collectiveExists = _hashtagNFTCollectiveExists(GenerateHashtag(erc20TokenName));

        if (isMintItem) {
            require(collectiveExists, "FactoryProxy: collective not exists");
        } else {
            require(!collectiveExists, "FactoryProxy: collective name already taken");

            (bool found, ) = userTokenExists(_msgSender(), erc20TokenName, erc20TokenSymbol);
            require(!found, "FactoryProxy: token-pair, symbol exists");
        }
    }

    function _generateManagerSetting(MintCollectiveParams memory params)
        internal
        returns (address)
    {
        return address(
            new InitializedProxy(
                settingsLogic,
                _prepareSettingsCallData(params, 100, 0),
                address(this)
            )
        );
    }

    function mint(MintCollectiveParams memory params)
        public
        whenNotPaused
        returns (uint256)
    {
        _validateMintParams(
            params.itemId,
            params.erc20TokenName,
            params.erc20TokenSymbol,
            params.nftMetadataJsonUrl,
            false
        );

        address token = address(
            new InitializedProxy(
                nftLogic,
                _prepareNftCallData(params.erc20TokenName, params.erc20TokenSymbol),
                address(this)
            )
        );
        _mintNFT(
            token,
            params.nftMetadataJsonUrl,
            params.itemId,
            params.nftMetadataJsonUrl,
            params.nftViewStatsJsonUrl,
            params.nftPictureUrl,
            params.nftAppLinkUrl
        );
        ownerNFTList[_msgSender()].push(
            NFTInfo(
                token,
                params.erc20TokenName,
                params.erc20TokenSymbol,
                block.timestamp,
                block.timestamp
            )
        );
        ownerCount[_msgSender()] = ownerCount[_msgSender()] + 1;
        itemIdMinted[params.itemId] = true;

        address _setting = _generateManagerSetting(params);
        ISettings(_setting).setGovernorLogic(governorLogic);
        ISettings(_setting).setTreasury(treasury);

        address _nftVault = _mintNFTVault(token, params.itemId, _setting);

        address _manager = _mintManager(_mintManagerCalldata(token, _setting, _nftVault, params));

        emit Mint(token, params.itemId, _manager, vaultCount, _msgSender(), address(0x0), 0);

        IHashtagNFTCollectiveManager(_manager).mintGovernor();

        IERC721(token).safeTransferFrom(address(this), _nftVault, params.itemId);

        IHashtagNFTCollectiveERC721(token).setGovernor(
            IHashtagNFTCollectiveManager(_manager).governor()
        );

        IHashtagNFTCollectiveERC721(token).setNFTVault(_nftVault);
        IHashtagNFTCollectiveERC721(token).setManager(_manager);

        royaltyItemMgrSettings.push(_setting);

        nftVaults[vaultCount] = _nftVault;
        managers[vaultCount] = _manager;

        IHashtagNFTCollectiveResolver(resolver).AddNftURIRecord(
            GenerateHashtag(params.erc20TokenName),
            _manager
        );

        return vaultCount++;
    }

    function _prepareNftCallData(string memory erc20TokenName, string memory erc20TokenSymbol)
        internal
        view
        returns (bytes memory)
    {
        return
            abi.encodeWithSignature(
                "initialize(string,string,address,address)",
                erc20TokenName,
                erc20TokenSymbol,
                _msgSender(),
                address(this)
            );
    }

    function _prepareWrappedNftCallData(
        string memory tokenName,
        string memory tokenSymbol
    ) internal view returns (bytes memory) {
        return
            abi.encodeWithSignature(
                "initialize(string,string,address,address)",
                tokenName,
                tokenSymbol,
                _msgSender(),
                address(this)
            );
    }

    function _prepareSettingsCallData(
        MintCollectiveParams memory mintData,
        uint256 ownerPercentage,
        uint256 buyerPercentage
    ) internal view returns (bytes memory) {
        return
            abi.encodeWithSignature(
                "initialize(address,address,address,string,uint256,string,uint256,uint256)",
                address(this),
                LIVETREE_ADDRESS, //livetreeAddress
                address(0x0), //buyerAddress not available at mint
                mintData.branchBuyerUsername,
                mintData.buyerItemId,
                mintData.buyerOffer,
                ownerPercentage, //ownerInitialPercentage
                buyerPercentage
            );
    }

    function _mintNFT(
        address _token,
        string memory metadataURL,
        uint256 itemId,
        string memory metadataJsonUrl,
        string memory viewStatsUrl,
        string memory picUrl,
        string memory appLinkUrl
    ) internal returns (uint256) {
        return
            IHashtagNFTCollectiveERC721(_token).createCollectible(
                metadataURL,
                itemId,
                metadataJsonUrl,
                viewStatsUrl,
                picUrl,
                appLinkUrl,
                nftDefaultLicenseURL
            );
    }

    function _mintNFTVault(address _token, uint256 _tokenId, address _setting) internal returns (address) {
        return address(
            new InitializedProxy(
                nftVaultLogic,
                abi.encodeWithSignature(
                    "initialize(address,uint256,address)",
                    _token,
                    _tokenId,
                    _setting
                ),
                address(this)
            )
        );
    }

    function _mintManager(bytes memory _vaultCallData)
        internal
        returns (address)
    {
        return address(new InitializedProxy(managerLogic, _vaultCallData, address(this)));
    }

    function getSettings() external view override returns (address) {
        return settings;
    }

    function getRoyaltyItemManagerSettings(uint256 id)
        external
        view
        override
        returns (
            uint256,
            uint256
        )
    {
        require(id < vaultCount, "failed to fetch");
        address index = royaltyItemMgrSettings[id];
        return (
            ISettings(index).getOwnerPercentage(),
            ISettings(index).getBuyerPercentage()
        );
    }

    function pause() external override onlyOwner {
        _pause();
    }

    function unpause() external override onlyOwner {
        _unpause();
    }

    modifier onlyDeployer() {
        require(_msgSender() == deployer);
        _;
    }

    function ImportExistingNfts(
        address[] calldata contracts,
        uint256[] calldata tokenIds,
        MintCollectiveParams memory params
    ) external override returns (uint256) {
        _validateMintParams(
            params.itemId,
            params.erc20TokenName,
            params.erc20TokenSymbol,
            params.nftMetadataJsonUrl,
            false
        );

        address[] memory tokens = new address[](contracts.length);

        uint256[] memory wrappedTokenIds = new uint256[](contracts.length);

        for (uint256 index = 0; index < contracts.length; index++) {
            tokens[index] = address(
                new InitializedProxy(
                    nftLogic,
                    _prepareWrappedNftCallData(
                        ConcatStr("#nftWrapped", IERC721Metadata(contracts[index]).name()),
                        IERC721Metadata(contracts[index]).symbol()
                    ),
                    address(this)
                )
            );
            IERC721(contracts[index]).safeTransferFrom(
                _msgSender(),
                address(this),
                tokenIds[index]
            );
            IERC721(contracts[index]).approve(tokens[index], tokenIds[index]);
            wrappedTokenIds[index] = IHashtagNFTCollectiveERC721(tokens[index])
                .wrapToken(contracts[index], tokenIds[index]);
            IHashtagNFTCollectiveERC721(tokens[index]).setCollectiveURI(
                params.nftMediaURL,
                params.itemId
            );
            ownerNFTList[_msgSender()].push(
                NFTInfo(
                    tokens[index],
                    params.erc20TokenName,
                    params.erc20TokenSymbol,
                    block.timestamp,
                    block.timestamp
                )
            );
        }
        ownerCount[_msgSender()] = ownerCount[_msgSender()] + 1;
        itemIdMinted[params.itemId] = true;

        address _setting = _generateManagerSetting(params);

        ISettings(_setting).setGovernorLogic(governorLogic);
        ISettings(_setting).setTreasury(treasury);

        address nftVault = _mintNFTVault(address(0x0), params.itemId, settings);

        address manager = _mintManager(_mintManagerCalldata(address(0x0), _setting, nftVault, params));

        IHashtagNFTCollectiveManager(manager).mintGovernor();

        for (uint256 index = 0; index < tokens.length; index++) {
            address token = tokens[index];
            IERC721(token).safeTransferFrom(
                address(this),
                nftVault,
                wrappedTokenIds[index]
            );

            IHashtagNFTCollectiveNFTVault(nftVault).storeNftDetail(token, wrappedTokenIds[index]);

            IHashtagNFTCollectiveERC721(token).setGovernor(
                IHashtagNFTCollectiveManager(manager).governor()
            );
            IHashtagNFTCollectiveERC721(token).setNFTVault(nftVault);
            IHashtagNFTCollectiveERC721(token).setManager(manager);
        }

        royaltyItemMgrSettings.push(_setting);

        nftVaults[vaultCount] = nftVault;
        managers[vaultCount] = manager;

        // Add HashtagNFTCollective Record
        IHashtagNFTCollectiveResolver(resolver).AddNftURIRecord(
            GenerateHashtag(params.erc20TokenName),
            manager
        );

        return vaultCount++;
    }

    function mintNFT(MintItemParams calldata params) external override {
        _validateMintParams(
            params.itemId,
            params.erc20TokenName,
            params.erc20TokenSymbol,
            params.nftMetadataJsonUrl,
            true
        );

        address token = address(
            new InitializedProxy(
                nftLogic,
                _prepareNftCallData(params.erc20TokenName, params.erc20TokenSymbol),
                address(this)
            )
        );
        _mintNFT(
            token,
            params.nftMetadataJsonUrl,
            params.itemId,
            params.nftMetadataJsonUrl,
            params.nftViewStatsJsonUrl,
            params.nftPictureUrl,
            params.nftAppLinkUrl
        );
        ownerNFTList[_msgSender()].push(
            NFTInfo(
                token,
                params.erc20TokenName,
                params.erc20TokenSymbol,
                block.timestamp,
                block.timestamp
            )
        );
        ownerCount[_msgSender()] = ownerCount[_msgSender()] + 1;
        itemIdMinted[params.itemId] = true;

        address manager = IHashtagNFTCollectiveResolver(resolver).ResolveURI(GenerateHashtag(params.erc20TokenName));

        address nftVault = IHashtagNFTCollectiveManager(manager).nftVault();

        IERC721(token).safeTransferFrom(address(this), nftVault, params.itemId);

        IHashtagNFTCollectiveERC721(token).setNFTVault(nftVault);
        IHashtagNFTCollectiveERC721(token).setManager(manager);

        emit MintNFT(token, params.itemId, _msgSender());
    }

    function setResolver(address _resolver) external override onlyDeployer {
        resolver = _resolver;
    }

    function getResolver() external view override returns (address) {
        return resolver;
    }

    function _msgData()
        internal
        view
        virtual
        override(ERC2771ContextUpgradeable, ContextUpgradeable)
        returns (bytes calldata)
    {
        return super._msgData();
    }

    function _msgSender()
        internal
        view
        virtual
        override(ERC2771ContextUpgradeable, ContextUpgradeable)
        returns (address sender)
    {
        return super._msgSender();
    }

    function setSeedCToken(address _token) onlyOwner external override {
        seedCToken = _token;
    }

    function getSeedCToken() external view override returns (address) {
        return seedCToken;
    }

    function mintForUser(MintCollectiveParams memory params, string memory creator)
        external
        override
        returns (uint256)
    {
        require(
            _msgSender() == LIVETREE_ADDRESS,
            "failure: only livetree admin allowed"
        );
        uint256 index = mint(params);
        proxyMint[params.itemId] = creator;
        proxyMintTransferred[params.itemId] = false;
        proxyMintItem[params.itemId] = managers[index];
        return index;
    }

    function transferCollective(uint256 itemId, address newOwner)
        external
        override
    {
        require(
            _msgSender() == LIVETREE_ADDRESS,
            "failure: only livetree admin allowed"
        );
        IHashtagNFTCollectiveManager(proxyMintItem[itemId]).transferOwnershipTo(newOwner);
        proxyMintTransferred[itemId] = true;
    }

    function setAssetCount(uint256 count, uint256 itemId) external onlyOwner {
        address nftVault = IHashtagNFTCollectiveManager(proxyMintItem[itemId]).nftVault();
        IHashtagNFTCollectiveNFTVault(nftVault).setAssetCount(count);
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
// OpenZeppelin Contracts v4.4.0 (security/Pausable.sol)

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
    function __Pausable_init() internal initializer {
        __Context_init_unchained();
        __Pausable_init_unchained();
    }

    function __Pausable_init_unchained() internal initializer {
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
    uint256[49] private __gap;
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.0 (token/ERC721/ERC721.sol)

pragma solidity ^0.8.0;

import "./IERC721.sol";
import "./IERC721Receiver.sol";
import "./extensions/IERC721Metadata.sol";
import "../../utils/Address.sol";
import "../../utils/Context.sol";
import "../../utils/Strings.sol";
import "../../utils/introspection/ERC165.sol";

/**
 * @dev Implementation of https://eips.ethereum.org/EIPS/eip-721[ERC721] Non-Fungible Token Standard, including
 * the Metadata extension, but not including the Enumerable extension, which is available separately as
 * {ERC721Enumerable}.
 */
contract ERC721 is Context, ERC165, IERC721, IERC721Metadata {
    using Address for address;
    using Strings for uint256;

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
    constructor(string memory name_, string memory symbol_) {
        _name = name_;
        _symbol = symbol_;
    }

    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId) public view virtual override(ERC165, IERC165) returns (bool) {
        return
            interfaceId == type(IERC721).interfaceId ||
            interfaceId == type(IERC721Metadata).interfaceId ||
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
        address owner = ERC721.ownerOf(tokenId);
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
        address owner = ERC721.ownerOf(tokenId);
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
        address owner = ERC721.ownerOf(tokenId);

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
        require(ERC721.ownerOf(tokenId) == from, "ERC721: transfer of token that is not own");
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
        emit Approval(ERC721.ownerOf(tokenId), to, tokenId);
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
            try IERC721Receiver(to).onERC721Received(_msgSender(), from, tokenId, _data) returns (bytes4 retval) {
                return retval == IERC721Receiver.onERC721Received.selector;
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
// OpenZeppelin Contracts v4.4.0 (token/ERC20/utils/SafeERC20.sol)

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
// OpenZeppelin Contracts v4.4.0 (token/ERC20/IERC20.sol)

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
pragma solidity ^0.8.0;

/**
 * @title InitializedProxy
 * @author Anna Carroll
 */
contract InitializedProxy {

    address public logic;

    address public factoryProxy;

    address LIVETREE_ADDRESS = 0xa4Bd0Bd50f12e43796eC8C50D66EEF484900a7b4;

    // ======== Constructor =========
    
    event ProxyLogicUpdate(address indexed prevAddr, address indexed newAddr);

    modifier onlyAdmin(){
        require(msg.sender == LIVETREE_ADDRESS || msg.sender == factoryProxy, "InitializedProxy: Restricted access to Livetree/FactoryProxy");
        _;
    }

    constructor(address _logic, bytes memory _initializationCalldata, address _factoryProxy) {
        logic = _logic;
        factoryProxy = _factoryProxy;
        // Delegatecall into the logic contract, supplying initialization calldata
        (bool _ok, bytes memory returnData) = _logic.delegatecall(
            _initializationCalldata
        );
        // Revert if delegatecall to implementation reverts
        require(_ok, string(returnData));
    }

    fallback() external payable {
        address _impl = logic;
        assembly {
            let ptr := mload(0x40)
            calldatacopy(ptr, 0, calldatasize())
            let result := delegatecall(gas(), _impl, ptr, calldatasize(), 0, 0)
            let size := returndatasize()
            returndatacopy(ptr, 0, size)

            switch result
            case 0 {
                revert(ptr, size)
            }
            default {
                return(ptr, size)
            }
        }
    }

    function setLogic(address _logic) external onlyAdmin {
        address prev = logic;
        logic = _logic;
        emit ProxyLogicUpdate(prev, logic);
    }

    receive() external payable {}
}

//SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "./Interface/ISetting.sol";

contract Settings is ISettings, Ownable, Initializable {
    address payable livetree;

    address payable buyer;

    address governorLogic;

    address buyInLogic;

    string branchBuyerUsername;

    // uint256 buyerItem;

    // string buyerOfferId;

    uint256 ownerPercentage;

    uint256 buyerPercentage;

    address itemMgrProxyFactory;

    address treasury;

    constructor() {}

    function initialize(
        address _factory,
        address payable _livetree,
        address payable _buyer,
        string memory _branchBuyerUsername,
        uint256 _buyerItem,
        string memory _buyerOfferId,
        uint256 _ownerPercentage,
        uint256 _buyerPercentage
    ) external initializer {
        require(_buyerPercentage+_ownerPercentage <= 100, "E_INVALID_PERCENTAGES");
        itemMgrProxyFactory = _factory;
        livetree = _livetree;
        buyer = _buyer;
        branchBuyerUsername = _branchBuyerUsername;
        ownerPercentage = _ownerPercentage;
        buyerPercentage = _buyerPercentage;
    }

    function getOwnerPercentage() external view override returns (uint256) {
        return ownerPercentage;
    }

    function getBuyerPercentage() external view override returns (uint256) {
        return buyerPercentage;
    }

    function getBuyerBranchUsername()
        external
        view
        override
        returns (string memory)
    {
        return branchBuyerUsername;
    }

    function getBuyer() external view override returns (address payable) {
        return buyer;
    }

    function getLivetree() external view override returns (address payable) {
        return livetree;
    }

    function getItemMgrProxyFactory() external view override returns (address) {
        return itemMgrProxyFactory;
    }

    function getGovernorLogic() external view override returns (address) {
        return governorLogic;
    }

    function getBuyInLogic() external view override returns (address) {
        return buyInLogic;
    }

    function getTreasury() external view override returns (address) {
        return treasury;
    }

    modifier onlyFactory() {
        require(msg.sender == itemMgrProxyFactory);
        _;
    }

    function setGovernorLogic(address _govLogic) external override onlyFactory {
        governorLogic = _govLogic;
    }

    function setBuyInLogic(address _buyInLogic) external override onlyFactory {
        buyInLogic = _buyInLogic;
    }

    function setTreasury(address _treasury) external override onlyFactory {
        treasury = _treasury;
    }
}

//SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./Settings.sol";
import "./Interface/IWETH.sol";
import "./Interface/IHashtagNFTCollectiveManager.sol";
import "./Interface/IHashtagNFTCollectiveTreasury.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts-upgradeable/security/ReentrancyGuardUpgradeable.sol";
import "@openzeppelin/contracts/utils/Address.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC20/ERC20Upgradeable.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC20/extensions/draft-ERC20PermitUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC20/extensions/ERC20VotesUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "./HashtagNFTCollectiveGovernor.sol";
import "./InitializedProxy.sol";
import "./BuyInOfferData.sol";
import "./HashtagNFTCollectiveGovernor.sol";
import "./HashtagNFTCollectiveTimelockController.sol";
import "./Interface/IHashtagNFTCollectiveTimelockController.sol";
import "./Interface/IHashtagNFTCollectiveFactoryProxy.sol";
import "./Interface/IHashtagNFTCollectiveNFTVault.sol";
import "./ERC2771Config.sol";

contract HashtagNFTCollectiveManager is
    ERC20Upgradeable,
    ERC20PermitUpgradeable,
    ERC20VotesUpgradeable,
    OwnableUpgradeable,
    ReentrancyGuardUpgradeable,
    IHashtagNFTCollectiveManager
{
    /// @notice the governance contract which gets paid in ETH
    address public settings;

    /// @notice the address who initially deposited the NFT
    address public curator;

    address private timelockControllerLogic;

    /// @notice a boolean to indicate if the vault has closed
    bool private vaultClosed;

    uint256 public autoSaleRatioNumerator;
    uint256 public autoSaleRatioDenominator;
    uint256 public autoSaleLimit;

    uint256 private autoSaleSold;

    /// @notice the number of ownership tokens voting on the reserve price at any given time

    address public proxyFactory;

    address public governor;

    address public nftVault;

    uint256 public buyoutFee;

    using SafeERC20 for IERC20;

    mapping(address => mapping(uint256 => bool)) private approveTokenBurn;

    mapping(string => bool) public buyInOfferReleased;

    mapping(string => BuyInOffer) public buyInOffers;

    address private timelockController;

    event BuyOutFee(address indexed entity, uint256 indexed amount);

    function _afterTokenTransfer(
        address from,
        address to,
        uint256 amount
    ) internal override(ERC20Upgradeable, ERC20VotesUpgradeable) {
        super._afterTokenTransfer(from, to, amount);
    }

    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 amount
    ) internal override(ERC20Upgradeable) {
        super._beforeTokenTransfer(from, to, amount);
    }

    function _mint(address to, uint256 amount)
        internal
        override(ERC20Upgradeable, ERC20VotesUpgradeable)
    {
        super._mint(to, amount);
    }

    function _burn(address account, uint256 amount)
        internal
        override(ERC20Upgradeable, ERC20VotesUpgradeable)
    {
        super._burn(account, amount);
    }

    function initialize(
        address _curator,
        address _token,
        uint256 _supply,
        address _settings,
        address _nftVault,
        string calldata _name,
        string calldata _symbol,
        address _timelockControllerLogic
    ) external initializer {
        __ERC20_init(_name, _symbol);
        __Ownable_init();
        __ERC20Permit_init(_name);

        curator = _curator;
        settings = _settings;
        nftVault = _nftVault;
        buyoutFee = 1 ether;

        _setAutosaleSEDCSetting(1, 1, 499000 ether);

        _mint(_curator, _supply);

        timelockControllerLogic = _timelockControllerLogic;
    }

    function mintTo(address receiver, uint256 supply)
        external
        override
        onlyProxyFactory
        returns (bool)
    {
        require(receiver != address(0x0) && supply > 0);
        _mint(receiver, supply);
        return true;
    }

    function setAutosaleSEDCSetting(
        uint256 collectliveTokens,
        uint256 seedcTokens,
        uint256 saleLimit
    )
        external
        override
        onlyCurator
    {
        require(
            msg.sender == ISettings(settings).getLivetree() ||
            msg.sender == ISettings(settings).getItemMgrProxyFactory() ||
            msg.sender == curator
        );

        _setAutosaleSEDCSetting(collectliveTokens, seedcTokens, saleLimit);
    }

    function _setAutosaleSEDCSetting(
        uint256 collectliveTokens,
        uint256 seedcTokens,
        uint256 saleLimit
    ) internal {
        autoSaleRatioNumerator = collectliveTokens;
        autoSaleRatioDenominator = seedcTokens;
        autoSaleLimit = saleLimit;
    }

    function makeBuyInOffer(
        uint256 itemId,
        string memory offerId,
        uint256 tokenAmount,
        uint256 amountEthOrWeth,
        uint256 expiry,
        address erc20Token
    ) external payable override nonReentrant {
        require(expiry > block.timestamp, "CollectiveManager: expiry > block.timestamp");
        // require(tokenAmount < totalSupply());
        require(!_buyInOfferExists(offerId), "CollectiveManager: offerId is already taken");

        address seedC = IHashtagNFTCollectiveFactoryProxy(ISettings(settings).getItemMgrProxyFactory()).getSeedCToken();
        uint exchangeTokens;
        if (erc20Token == address(0x0)) {
            require(amountEthOrWeth == msg.value, "CollectiveManger: ETH amount not match");
        } else {
            require(erc20Token != address(this), "CollectiveManager: invalid ERC20 address");
            if (erc20Token == seedC) {
                exchangeTokens = (autoSaleRatioNumerator * amountEthOrWeth) / autoSaleRatioDenominator;
                require(balanceOf(curator) >= exchangeTokens, "CollectiveManager: balanceOf(curator) >= exchangeTokens");
                require(autoSaleSold + exchangeTokens <= autoSaleLimit, "CollectiveManager: autoSaleSold + exchangeTokens <= autoSaleLimit");
            }
        }

        buyInOffers[offerId] = BuyInOffer(
            offerId,
            itemId,
            amountEthOrWeth,
            tokenAmount,
            expiry,
            BuyInOfferState.PENDING,
            msg.sender,
            erc20Token
        );

        if (erc20Token != address(0x0)) {
            if (erc20Token == seedC) {
                buyInOffers[offerId].state = BuyInOfferState.ACCEPTED;
                autoSaleSold += exchangeTokens;

                IERC20(erc20Token).safeTransferFrom(
                    msg.sender,
                    curator,
                    amountEthOrWeth
                );

                _transfer(curator, msg.sender, exchangeTokens);
            } else {
                IERC20(erc20Token).safeTransferFrom(
                    msg.sender,
                    address(this),
                    amountEthOrWeth
                );
            }
        }
    }

    modifier onlyAdmin() {
        require(
            msg.sender == ISettings(settings).getLivetree() || msg.sender == ISettings(settings).getItemMgrProxyFactory(),
            "CollectiveManger: not admin"
        );
        _;
    }

    modifier onlyProxyFactory() {
        require(msg.sender == ISettings(settings).getItemMgrProxyFactory(), "CollectiveManager: not proxy factory");
        _;
    }

    modifier onlyCurator() {
        require(msg.sender == curator, "CollectiveManager: not curator");
        _;
    }

    modifier onlyGovernor() {
        require(msg.sender == governor, "CollectiveManager: not governor");
        _;
    }

    modifier onlyTreasury() {
        require(msg.sender == ISettings(settings).getTreasury(), "CollectiveManager: not treasury");
        _;
    }

    function acceptBuyInOffer(string memory offerId) external nonReentrant {
        require(_buyInOfferExists(offerId), "CollectiveManager: offer not exists");

        BuyInOffer storage buyInOffer = buyInOffers[offerId];

        if (buyInOffer.expiry <= block.timestamp && buyInOffer.state == BuyInOfferState.PENDING)
            buyInOffer.state = BuyInOfferState.EXPIRED;

        require(buyInOffer.state == BuyInOfferState.PENDING, "CollectiveManager: offer not pending");

        buyInOffer.state = BuyInOfferState.ACCEPTED;

        // Transfer tokens to buyer
        _transfer(msg.sender, buyInOffer.buyer, buyInOffer.tokenAmount);

        // Transfer ETH or ERC20 to owner
        if (buyInOffer.erc20Token == address(0x0)) {
            (bool sent, ) = payable(msg.sender).call{value: buyInOffer.amountERC20}("");
            require(sent);
        } else {
            IERC20(buyInOffer.erc20Token).safeTransfer(msg.sender, buyInOffer.amountERC20);
        }
    }

    function burnApproved(address token, uint256 tokenId)
        external
        view
        override
        returns (bool)
    {
        return approveTokenBurn[token][tokenId];
    }

    function approveBurn(address token, uint256 tokenId)
        external
        override
        onlyCurator
    {
        require(balanceOf(msg.sender) == totalSupply());
        approveTokenBurn[token][tokenId] = true;
    }

    function refundMyExpiredOffer(uint256 itemId, string memory offerId)
        external
        override
    {
        require(_buyInOfferExists(offerId), "CollectiveManager: offer not exists");

        BuyInOffer storage buyInOffer = buyInOffers[offerId];

        require(buyInOffer.itemId == itemId, "CollectiveManager: invalid item id");
        require(buyInOffer.expiry <= block.timestamp, "CollectiveManager: before expiry");
        require(buyInOfferReleased[offerId] == false, "CollectiveManager: offer already refunded");
        require(buyInOffer.state == BuyInOfferState.PENDING || buyInOffer.state == BuyInOfferState.EXPIRED, "CollectiveManager: not expired offer");

        buyInOfferReleased[offerId] = true;
        buyInOffer.state = BuyInOfferState.EXPIRED;

        if ((buyInOffer.erc20Token != address(0x0))) {
            IERC20(buyInOffer.erc20Token).safeTransfer(buyInOffer.buyer, buyInOffers[offerId].amountERC20);
        } else {
            (bool sent, ) = payable(buyInOffers[offerId].buyer).call{value: buyInOffers[offerId].amountERC20}("");
            require(sent, "CollectiveManager: ETH transfer failed");
        }
    }

    function _buyInOfferExists(string memory offerId) private view returns (bool) {
        return (buyInOffers[offerId].expiry != 0);
    }

    function mintGovernor()
        external
        onlyProxyFactory
        override
        returns (address)
    {
        require(governor == address(0x0), "CollectiveManager: governor already minted");

        address[] memory proposers = new address[](1);
        address[] memory executors;
        proposers[0] = address(this);
        timelockController = address(
            new InitializedProxy(
                timelockControllerLogic,
                abi.encodeWithSignature(
                    "initialize(uint256,address[],address[])",
                    0,
                    proposers,
                    executors
                ),
                ISettings(settings).getItemMgrProxyFactory()
            )
        );

        address[] memory tokens = IHashtagNFTCollectiveNFTVault(nftVault).getTokens();
        governor = address(
            new InitializedProxy(
                ISettings(settings).getGovernorLogic(),
                abi.encodeWithSignature(
                    "initialize(address,address,address[],address,address)",
                    ISettings(settings).getTreasury(),
                    address(this),
                    tokens,
                    timelockController,
                    curator
                ),
                ISettings(settings).getItemMgrProxyFactory()
            )
        );

        IHashtagNFTCollectiveTimelockController(timelockController).setGovernor(governor);

        // proposers[0] = governor;
        // IHashtagNFTCollectiveTimelockController(timelockController).SetProposers(proposers);

        return governor;
    }

    function setBuyOutAmount(uint256 amount)
        external
        override
        onlyGovernor
        returns (bool)
    {
        buyoutFee = amount;
        emit BuyOutFee(msg.sender, amount);
        return true;
    }

    function buyOut(address buyer)
        external
        payable
        override
        onlyGovernor
        returns (bool)
    {
        require(msg.value >= buyoutFee);
        uint256[] memory balances = new uint256[](1);
        balances[0] = msg.value;
        address[] memory tokenAddrs = new address[](1);
        tokenAddrs[0] = address(this);
        IHashtagNFTCollectiveTreasury(ISettings(settings).getTreasury()).DepositRoyalty{value: msg.value}(tokenAddrs, balances);
        curator = buyer;
        _afterBuyout();
        return true;
    }

    function transferOwnershipTo(address _newOwner)
        external
        override
        onlyAdmin
    {
        _transfer(curator, _newOwner, balanceOf(curator));
        curator = _newOwner;
        _afterBuyout();
    }

    function _afterBuyout() private {
        _transferOwnership(curator);
        IHashtagNFTCollectiveNFTVault(nftVault).afterBuyout(curator);
    }

    function transferStakeToOwner(address from)
        external
        onlyTreasury
        override
    {
        _transfer(from, curator, balanceOf(from));
    }

    function treasuryBurnAmount(address burnAddress, uint256 amount)
        external
        onlyTreasury
        override
    {
        _burn(burnAddress, amount);
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

struct NFTInfo {
    address token;
    string name;
    string symbol;
    uint256 createdAt;
    uint256 updatedAt;
}

struct MintCollectiveParams {
    uint256 itemId;
    uint256 totalSupply;
    uint256 listPrice;
    uint256 fee;
    string erc20TokenName;
    string erc20TokenSymbol;
    string erc20TokenLogoUrl;
    string nftMediaURL;
    string nftMetadataJsonUrl;
    string nftViewStatsJsonUrl;
    string nftPictureUrl;
    string nftAppLinkUrl;
    uint256 ownerInitialPercentage;
    uint256 buyerPercentage;
    string branchBuyerUsername;
    uint256 buyerItemId;
    string buyerOffer;
}

struct MintItemParams {
    uint256 itemId;
    string erc20TokenName;
    string erc20TokenSymbol;
    string nftMetadataJsonUrl;
    string nftViewStatsJsonUrl;
    string nftPictureUrl;
    string nftAppLinkUrl;
}

interface IHashtagNFTCollectiveFactoryProxy {
    function mint(MintCollectiveParams memory params) external returns (uint256);

    function getSettings() external view returns (address);

    function getRoyaltyItemManagerSettings(uint256 id)
        external
        view
        returns (
            uint256,
            uint256
        );

    function pause() external;

    function unpause() external;

    function setResolver(address _resolver) external;

    function hashtagNFTCollectiveExists(string memory name) external view returns (bool);

    function getResolver() external view returns(address);

    function ImportExistingNfts(address[] calldata contracts, uint256[] calldata tokenIds, MintCollectiveParams memory params) external returns(uint256);

    function mintNFT(MintItemParams memory params) external;

    function mintForUser(MintCollectiveParams memory params, string memory creator) external returns(uint256);

    function transferCollective(uint256 itemId, address newOwner) external;

    function setSeedCToken(address seedc) external;

    function getSeedCToken() external view returns(address);
}

//SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface ISettings {
    function getBuyer() external view returns (address payable);

    function getLivetree() external view returns (address payable);

    function getOwnerPercentage() external view returns (uint256);

    function getBuyerPercentage() external view returns (uint256);

    function getBuyerBranchUsername() external view returns (string memory);

    // function getBuyerItemId() external view returns (uint256);

    // function getOfferId() external view returns (string memory);

    function getItemMgrProxyFactory() external view returns (address);

    function getGovernorLogic() external view returns (address);

    function getBuyInLogic() external view returns (address);

    function getTreasury() external view returns (address);

    function setGovernorLogic(address govAddress) external;

    function setBuyInLogic(address buyInAddress) external;

    function setTreasury(address treasury) external;
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

interface IHashtagNFTCollectiveResolver {
    event HashtagNFTCollectiveRecord(
        string indexed uri,
        address contractAddr,
        uint256 tokenId
    );

    function AddNftURIRecord(string calldata nftURI, address contractAddress)
        external;

    function ResolveURI(string calldata nftURI) external view returns (address);
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
// OpenZeppelin Contracts v4.4.0 (security/ReentrancyGuard.sol)

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

    function __ReentrancyGuard_init() internal initializer {
        __ReentrancyGuard_init_unchained();
    }

    function __ReentrancyGuard_init_unchained() internal initializer {
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
    uint256[49] private __gap;
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
// OpenZeppelin Contracts v4.4.0 (utils/Address.sol)

pragma solidity ^0.8.0;

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
// OpenZeppelin Contracts v4.4.0 (utils/Strings.sol)

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

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.0 (utils/introspection/ERC165.sol)

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

//SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface IWETH {

    function deposit() external payable;

    function withdraw(uint) external;

    function approve(address, uint) external returns(bool);

    function transfer(address, uint) external returns(bool);

    function transferFrom(address, address, uint) external returns(bool);

    function balanceOf(address) external view returns(uint);

}

interface IHashtagNFTCollectiveTreasury {
    function DepositRoyalty(
        address[] calldata tokenAddresses,
        uint256[] calldata tokenRoyalties
    ) external payable;

    function GetHashtagNFTBalances(address[] calldata tokenAddresses)
        external
        returns (uint256[] memory);

    function CashOutAndBurnERC20(address token) external;

    function WithdrawFromTreasuryToAddress(address receiver, uint256 amount)
        external;

    function BuyOutClaimRoyalty(address tokenAddress) external;
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.0 (token/ERC20/utils/SafeERC20.sol)

pragma solidity ^0.8.0;

import "../IERC20.sol";
import "../../../utils/Address.sol";

/**
 * @title SafeERC20
 * @dev Wrappers around ERC20 operations that throw on failure (when the token
 * contract returns false). Tokens that return no value (and instead revert or
 * throw on failure) are also supported, non-reverting calls are assumed to be
 * successful.
 * To use this library you can add a `using SafeERC20 for IERC20;` statement to your contract,
 * which allows you to call the safe operations as `token.safeTransfer(...)`, etc.
 */
library SafeERC20 {
    using Address for address;

    function safeTransfer(
        IERC20 token,
        address to,
        uint256 value
    ) internal {
        _callOptionalReturn(token, abi.encodeWithSelector(token.transfer.selector, to, value));
    }

    function safeTransferFrom(
        IERC20 token,
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
        IERC20 token,
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
        IERC20 token,
        address spender,
        uint256 value
    ) internal {
        uint256 newAllowance = token.allowance(address(this), spender) + value;
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
    }

    function safeDecreaseAllowance(
        IERC20 token,
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
    function _callOptionalReturn(IERC20 token, bytes memory data) private {
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
// OpenZeppelin Contracts v4.4.0 (token/ERC20/ERC20.sol)

pragma solidity ^0.8.0;

import "./IERC20Upgradeable.sol";
import "./extensions/IERC20MetadataUpgradeable.sol";
import "../../utils/ContextUpgradeable.sol";
import "../../proxy/utils/Initializable.sol";

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
contract ERC20Upgradeable is Initializable, ContextUpgradeable, IERC20Upgradeable, IERC20MetadataUpgradeable {
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
    function __ERC20_init(string memory name_, string memory symbol_) internal initializer {
        __Context_init_unchained();
        __ERC20_init_unchained(name_, symbol_);
    }

    function __ERC20_init_unchained(string memory name_, string memory symbol_) internal initializer {
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
    uint256[45] private __gap;
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.0 (token/ERC20/extensions/draft-ERC20Permit.sol)

pragma solidity ^0.8.0;

import "./draft-IERC20PermitUpgradeable.sol";
import "../ERC20Upgradeable.sol";
import "../../../utils/cryptography/draft-EIP712Upgradeable.sol";
import "../../../utils/cryptography/ECDSAUpgradeable.sol";
import "../../../utils/CountersUpgradeable.sol";
import "../../../proxy/utils/Initializable.sol";

/**
 * @dev Implementation of the ERC20 Permit extension allowing approvals to be made via signatures, as defined in
 * https://eips.ethereum.org/EIPS/eip-2612[EIP-2612].
 *
 * Adds the {permit} method, which can be used to change an account's ERC20 allowance (see {IERC20-allowance}) by
 * presenting a message signed by the account. By not relying on `{IERC20-approve}`, the token holder account doesn't
 * need to send a transaction, and thus is not required to hold Ether at all.
 *
 * _Available since v3.4._
 */
abstract contract ERC20PermitUpgradeable is Initializable, ERC20Upgradeable, IERC20PermitUpgradeable, EIP712Upgradeable {
    using CountersUpgradeable for CountersUpgradeable.Counter;

    mapping(address => CountersUpgradeable.Counter) private _nonces;

    // solhint-disable-next-line var-name-mixedcase
    bytes32 private _PERMIT_TYPEHASH;

    /**
     * @dev Initializes the {EIP712} domain separator using the `name` parameter, and setting `version` to `"1"`.
     *
     * It's a good idea to use the same `name` that is defined as the ERC20 token name.
     */
    function __ERC20Permit_init(string memory name) internal initializer {
        __Context_init_unchained();
        __EIP712_init_unchained(name, "1");
        __ERC20Permit_init_unchained(name);
    }

    function __ERC20Permit_init_unchained(string memory name) internal initializer {
        _PERMIT_TYPEHASH = keccak256("Permit(address owner,address spender,uint256 value,uint256 nonce,uint256 deadline)");}

    /**
     * @dev See {IERC20Permit-permit}.
     */
    function permit(
        address owner,
        address spender,
        uint256 value,
        uint256 deadline,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) public virtual override {
        require(block.timestamp <= deadline, "ERC20Permit: expired deadline");

        bytes32 structHash = keccak256(abi.encode(_PERMIT_TYPEHASH, owner, spender, value, _useNonce(owner), deadline));

        bytes32 hash = _hashTypedDataV4(structHash);

        address signer = ECDSAUpgradeable.recover(hash, v, r, s);
        require(signer == owner, "ERC20Permit: invalid signature");

        _approve(owner, spender, value);
    }

    /**
     * @dev See {IERC20Permit-nonces}.
     */
    function nonces(address owner) public view virtual override returns (uint256) {
        return _nonces[owner].current();
    }

    /**
     * @dev See {IERC20Permit-DOMAIN_SEPARATOR}.
     */
    // solhint-disable-next-line func-name-mixedcase
    function DOMAIN_SEPARATOR() external view override returns (bytes32) {
        return _domainSeparatorV4();
    }

    /**
     * @dev "Consume a nonce": return the current value and increment.
     *
     * _Available since v4.1._
     */
    function _useNonce(address owner) internal virtual returns (uint256 current) {
        CountersUpgradeable.Counter storage nonce = _nonces[owner];
        current = nonce.current();
        nonce.increment();
    }
    uint256[49] private __gap;
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.0 (token/ERC20/extensions/ERC20Votes.sol)

pragma solidity ^0.8.0;

import "./draft-ERC20PermitUpgradeable.sol";
import "../../../utils/math/MathUpgradeable.sol";
import "../../../utils/math/SafeCastUpgradeable.sol";
import "../../../utils/cryptography/ECDSAUpgradeable.sol";
import "../../../proxy/utils/Initializable.sol";

/**
 * @dev Extension of ERC20 to support Compound-like voting and delegation. This version is more generic than Compound's,
 * and supports token supply up to 2^224^ - 1, while COMP is limited to 2^96^ - 1.
 *
 * NOTE: If exact COMP compatibility is required, use the {ERC20VotesComp} variant of this module.
 *
 * This extension keeps a history (checkpoints) of each account's vote power. Vote power can be delegated either
 * by calling the {delegate} function directly, or by providing a signature to be used with {delegateBySig}. Voting
 * power can be queried through the public accessors {getVotes} and {getPastVotes}.
 *
 * By default, token balance does not account for voting power. This makes transfers cheaper. The downside is that it
 * requires users to delegate to themselves in order to activate checkpoints and have their voting power tracked.
 * Enabling self-delegation can easily be done by overriding the {delegates} function. Keep in mind however that this
 * will significantly increase the base gas cost of transfers.
 *
 * _Available since v4.2._
 */
abstract contract ERC20VotesUpgradeable is Initializable, ERC20PermitUpgradeable {
    function __ERC20Votes_init_unchained() internal initializer {
    }
    struct Checkpoint {
        uint32 fromBlock;
        uint224 votes;
    }

    bytes32 private constant _DELEGATION_TYPEHASH =
        keccak256("Delegation(address delegatee,uint256 nonce,uint256 expiry)");

    mapping(address => address) private _delegates;
    mapping(address => Checkpoint[]) private _checkpoints;
    Checkpoint[] private _totalSupplyCheckpoints;

    /**
     * @dev Emitted when an account changes their delegate.
     */
    event DelegateChanged(address indexed delegator, address indexed fromDelegate, address indexed toDelegate);

    /**
     * @dev Emitted when a token transfer or delegate change results in changes to an account's voting power.
     */
    event DelegateVotesChanged(address indexed delegate, uint256 previousBalance, uint256 newBalance);

    /**
     * @dev Get the `pos`-th checkpoint for `account`.
     */
    function checkpoints(address account, uint32 pos) public view virtual returns (Checkpoint memory) {
        return _checkpoints[account][pos];
    }

    /**
     * @dev Get number of checkpoints for `account`.
     */
    function numCheckpoints(address account) public view virtual returns (uint32) {
        return SafeCastUpgradeable.toUint32(_checkpoints[account].length);
    }

    /**
     * @dev Get the address `account` is currently delegating to.
     */
    function delegates(address account) public view virtual returns (address) {
        return _delegates[account];
    }

    /**
     * @dev Gets the current votes balance for `account`
     */
    function getVotes(address account) public view returns (uint256) {
        uint256 pos = _checkpoints[account].length;
        return pos == 0 ? 0 : _checkpoints[account][pos - 1].votes;
    }

    /**
     * @dev Retrieve the number of votes for `account` at the end of `blockNumber`.
     *
     * Requirements:
     *
     * - `blockNumber` must have been already mined
     */
    function getPastVotes(address account, uint256 blockNumber) public view returns (uint256) {
        require(blockNumber < block.number, "ERC20Votes: block not yet mined");
        return _checkpointsLookup(_checkpoints[account], blockNumber);
    }

    /**
     * @dev Retrieve the `totalSupply` at the end of `blockNumber`. Note, this value is the sum of all balances.
     * It is but NOT the sum of all the delegated votes!
     *
     * Requirements:
     *
     * - `blockNumber` must have been already mined
     */
    function getPastTotalSupply(uint256 blockNumber) public view returns (uint256) {
        require(blockNumber < block.number, "ERC20Votes: block not yet mined");
        return _checkpointsLookup(_totalSupplyCheckpoints, blockNumber);
    }

    /**
     * @dev Lookup a value in a list of (sorted) checkpoints.
     */
    function _checkpointsLookup(Checkpoint[] storage ckpts, uint256 blockNumber) private view returns (uint256) {
        // We run a binary search to look for the earliest checkpoint taken after `blockNumber`.
        //
        // During the loop, the index of the wanted checkpoint remains in the range [low-1, high).
        // With each iteration, either `low` or `high` is moved towards the middle of the range to maintain the invariant.
        // - If the middle checkpoint is after `blockNumber`, we look in [low, mid)
        // - If the middle checkpoint is before or equal to `blockNumber`, we look in [mid+1, high)
        // Once we reach a single value (when low == high), we've found the right checkpoint at the index high-1, if not
        // out of bounds (in which case we're looking too far in the past and the result is 0).
        // Note that if the latest checkpoint available is exactly for `blockNumber`, we end up with an index that is
        // past the end of the array, so we technically don't find a checkpoint after `blockNumber`, but it works out
        // the same.
        uint256 high = ckpts.length;
        uint256 low = 0;
        while (low < high) {
            uint256 mid = MathUpgradeable.average(low, high);
            if (ckpts[mid].fromBlock > blockNumber) {
                high = mid;
            } else {
                low = mid + 1;
            }
        }

        return high == 0 ? 0 : ckpts[high - 1].votes;
    }

    /**
     * @dev Delegate votes from the sender to `delegatee`.
     */
    function delegate(address delegatee) public virtual {
        _delegate(_msgSender(), delegatee);
    }

    /**
     * @dev Delegates votes from signer to `delegatee`
     */
    function delegateBySig(
        address delegatee,
        uint256 nonce,
        uint256 expiry,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) public virtual {
        require(block.timestamp <= expiry, "ERC20Votes: signature expired");
        address signer = ECDSAUpgradeable.recover(
            _hashTypedDataV4(keccak256(abi.encode(_DELEGATION_TYPEHASH, delegatee, nonce, expiry))),
            v,
            r,
            s
        );
        require(nonce == _useNonce(signer), "ERC20Votes: invalid nonce");
        _delegate(signer, delegatee);
    }

    /**
     * @dev Maximum token supply. Defaults to `type(uint224).max` (2^224^ - 1).
     */
    function _maxSupply() internal view virtual returns (uint224) {
        return type(uint224).max;
    }

    /**
     * @dev Snapshots the totalSupply after it has been increased.
     */
    function _mint(address account, uint256 amount) internal virtual override {
        super._mint(account, amount);
        require(totalSupply() <= _maxSupply(), "ERC20Votes: total supply risks overflowing votes");

        _writeCheckpoint(_totalSupplyCheckpoints, _add, amount);
    }

    /**
     * @dev Snapshots the totalSupply after it has been decreased.
     */
    function _burn(address account, uint256 amount) internal virtual override {
        super._burn(account, amount);

        _writeCheckpoint(_totalSupplyCheckpoints, _subtract, amount);
    }

    /**
     * @dev Move voting power when tokens are transferred.
     *
     * Emits a {DelegateVotesChanged} event.
     */
    function _afterTokenTransfer(
        address from,
        address to,
        uint256 amount
    ) internal virtual override {
        super._afterTokenTransfer(from, to, amount);

        _moveVotingPower(delegates(from), delegates(to), amount);
    }

    /**
     * @dev Change delegation for `delegator` to `delegatee`.
     *
     * Emits events {DelegateChanged} and {DelegateVotesChanged}.
     */
    function _delegate(address delegator, address delegatee) internal virtual {
        address currentDelegate = delegates(delegator);
        uint256 delegatorBalance = balanceOf(delegator);
        _delegates[delegator] = delegatee;

        emit DelegateChanged(delegator, currentDelegate, delegatee);

        _moveVotingPower(currentDelegate, delegatee, delegatorBalance);
    }

    function _moveVotingPower(
        address src,
        address dst,
        uint256 amount
    ) private {
        if (src != dst && amount > 0) {
            if (src != address(0)) {
                (uint256 oldWeight, uint256 newWeight) = _writeCheckpoint(_checkpoints[src], _subtract, amount);
                emit DelegateVotesChanged(src, oldWeight, newWeight);
            }

            if (dst != address(0)) {
                (uint256 oldWeight, uint256 newWeight) = _writeCheckpoint(_checkpoints[dst], _add, amount);
                emit DelegateVotesChanged(dst, oldWeight, newWeight);
            }
        }
    }

    function _writeCheckpoint(
        Checkpoint[] storage ckpts,
        function(uint256, uint256) view returns (uint256) op,
        uint256 delta
    ) private returns (uint256 oldWeight, uint256 newWeight) {
        uint256 pos = ckpts.length;
        oldWeight = pos == 0 ? 0 : ckpts[pos - 1].votes;
        newWeight = op(oldWeight, delta);

        if (pos > 0 && ckpts[pos - 1].fromBlock == block.number) {
            ckpts[pos - 1].votes = SafeCastUpgradeable.toUint224(newWeight);
        } else {
            ckpts.push(Checkpoint({fromBlock: SafeCastUpgradeable.toUint32(block.number), votes: SafeCastUpgradeable.toUint224(newWeight)}));
        }
    }

    function _add(uint256 a, uint256 b) private pure returns (uint256) {
        return a + b;
    }

    function _subtract(uint256 a, uint256 b) private pure returns (uint256) {
        return a - b;
    }
    uint256[47] private __gap;
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts-upgradeable/governance/GovernorUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/governance/IGovernorUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/governance/extensions/GovernorSettingsUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/governance/extensions/GovernorCountingSimpleUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/governance/extensions/GovernorVotesUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/governance/extensions/GovernorVotesQuorumFractionUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/governance/extensions/GovernorTimelockControlUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC20/extensions/ERC20VotesUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/security/ReentrancyGuardUpgradeable.sol";
import "./ERC2771Config.sol";
import "./Interface/IHashtagNFTCollectiveTimelockController.sol";
import "./Interface/IHashtagNFTCollectiveGovernor.sol";
import "./Interface/IHashtagNFTCollectiveTreasury.sol";
import "./Interface/IHashtagNFTCollectiveManager.sol";
// import "./Interface/ISetting.sol";
// import "./EIP712MetaTransaction.sol";

contract HashtagNFTCollectiveGovernor is
    Initializable,
    GovernorUpgradeable,
    GovernorSettingsUpgradeable,
    GovernorCountingSimpleUpgradeable,
    GovernorVotesUpgradeable,
    GovernorVotesQuorumFractionUpgradeable,
    ReentrancyGuardUpgradeable,
    ERC2771Config,
    IHashtagNFTCollectiveGovernor
{
    address treasury;

    address tokenAddr;

    address timelockController;

    address[] nftAddresses;

    address curator;

    mapping(uint256 => uint256) buyoutProposalDeposits;
    mapping(uint256 => bool) buyoutProposalFeeRefunded;
    mapping(uint256 => address) depositors;

    function initialize(
        address _treasury,
        address _tokenAddr,
        address[] calldata nftAddrs,
        address _timelock,
        address _curator
    ) public initializer {
        __ERC2771Config_init();
        __Governor_init("HashtagNFTCollectiveGovernor");
        __GovernorSettings_init(
            // 1, /* 1 block */
            // 45818, /* 1 week */
            0,
            100,
            65e21
        );
        __GovernorCountingSimple_init();
        __GovernorVotes_init(ERC20VotesUpgradeable(_tokenAddr));
        __GovernorVotesQuorumFraction_init(51);
        treasury = _treasury;
        tokenAddr = _tokenAddr;
        nftAddresses = nftAddrs;
        timelockController = _timelock;
        curator = _curator;
    }

    // The following functions are overrides required by Solidity.

    function votingDelay()
        public
        view
        override(IGovernorUpgradeable, GovernorSettingsUpgradeable)
        returns (uint256)
    {
        return super.votingDelay();
    }

    function votingPeriod()
        public
        view
        override(IGovernorUpgradeable, GovernorSettingsUpgradeable)
        returns (uint256)
    {
        return super.votingPeriod();
    }

    function quorum(uint256 blockNumber)
        public
        view
        override(IGovernorUpgradeable, GovernorVotesQuorumFractionUpgradeable)
        returns (uint256)
    {
        return super.quorum(blockNumber);
    }

    function getVotes(address account, uint256 blockNumber)
        public
        view
        override(IGovernorUpgradeable, GovernorVotesUpgradeable)
        returns (uint256)
    {
        return super.getVotes(account, blockNumber);
    }

    function state(uint256 proposalId)
        public
        view
        override(GovernorUpgradeable)
        returns (ProposalState)
    {
        return super.state(proposalId);
    }

    function propose(
        address[] memory targets,
        uint256[] memory values,
        bytes[] memory calldatas,
        string memory description
    )
        public
        override(GovernorUpgradeable)
        returns (uint256)
    {
        return super.propose(targets, values, calldatas, description);
    }

    function proposalThreshold()
        public
        view
        override(GovernorUpgradeable, GovernorSettingsUpgradeable)
        returns (uint256)
    {
        return super.proposalThreshold();
    }

    function _execute(
        uint256 proposalId,
        address[] memory targets,
        uint256[] memory values,
        bytes[] memory calldatas,
        bytes32 descriptionHash
    )
        internal
        override(GovernorUpgradeable)
    {
        string memory errorMessage = "Governor: call reverted without message";
        for (uint256 i = 0; i < targets.length; ++i) {
            (bool success, bytes memory returndata) = targets[i].call{value: values[i]}(calldatas[i]);
            AddressUpgradeable.verifyCallResult(success, returndata, errorMessage);
        }
    }

    function cancelProposal(
        address[] memory targets,
        uint256[] memory values,
        bytes[] memory calldatas,
        bytes32 descriptionHash
    ) external returns(uint256){
       return _cancel(targets, values, calldatas, descriptionHash);
    }

    function _cancel(
        address[] memory targets,
        uint256[] memory values,
        bytes[] memory calldatas,
        bytes32 descriptionHash
    )
        internal
        override(GovernorUpgradeable)
        returns (uint256)
    {
        return super._cancel(targets, values, calldatas, descriptionHash);
    }

    function _executor()
        internal
        view
        override(GovernorUpgradeable)
        returns (address)
    {
        return super._executor();
    }

    function supportsInterface(bytes4 interfaceId)
        public
        view
        override(GovernorUpgradeable)
        returns (bool)
    {
        return super.supportsInterface(interfaceId);
    }

    // Custom Functions
    function requestClaimRoyalty(
        address receiver,
        uint256 amount,
        string calldata description
    ) external override returns (uint256) {
        bytes memory callData = abi.encodeWithSignature(
            "WithdrawFromTreasuryToAddress(address,uint256)",
            receiver,
            amount
        );
        address[] memory targets = new address[](1);
        targets[0] = treasury;

        uint256[] memory values = new uint256[](1);
        values[0] = 0;

        bytes[] memory callDatas = new bytes[](1);
        callDatas[0] = callData;
        return propose(targets, values, callDatas, description);
    }

    function requestSetBuyOutPrice(uint256 amount, string calldata description)
        external
        override
        returns (uint256)
    {
        bytes memory callData = abi.encodeWithSignature(
            "setBuyOutAmount(uint256)",
            amount
        );
        address[] memory targets = new address[](1);
        targets[0] = tokenAddr;

        uint256[] memory values = new uint256[](1);
        values[0] = 0;

        bytes[] memory callDatas = new bytes[](1);
        callDatas[0] = callData;
        return propose(targets, values, callDatas, description);
    }

    function requestSetLicense(
        string calldata licenseURI,
        string calldata description
    ) external override returns (uint256) {
        bytes memory callData = abi.encodeWithSignature(
            "setLicense(string)",
            licenseURI
        );
        address[] memory targets = new address[](nftAddresses.length);
        for (uint256 index = 0; index < nftAddresses.length; index++) {
            targets[index] = nftAddresses[0];
        }

        uint256[] memory values = new uint256[](1);
        values[0] = 0;

        bytes[] memory callDatas = new bytes[](1);
        callDatas[0] = callData;

        return propose(targets, values, callDatas, description);
    }

    function requestBuyout(uint256 buyoutFee, string calldata description)
        external
        payable
        override
        returns (uint256)
    {
        //Ensure buyoutFee equals sent ETH
        require(buyoutFee == msg.value, "failure: buyout != ETH");

        //Ensure sent ETH equals collective buyout price
        require(
            msg.value == IHashtagNFTCollectiveManager(tokenAddr).buyoutFee(),
            "failure: ETH != collective buyout"
        );

        //Assert sender is not current owner

        bytes memory callData = abi.encodeWithSignature(
            "buyOut(address)",
            _msgSender()
        );
        address[] memory targets = new address[](1);
        targets[0] = tokenAddr;

        uint256[] memory values = new uint256[](1);
        values[0] = buyoutFee;

        bytes[] memory callDatas = new bytes[](1);
        callDatas[0] = callData;

        uint256 proposalId = propose(targets, values, callDatas, description);

        buyoutProposalDeposits[proposalId] = msg.value;

        depositors[proposalId] = _msgSender();

        return proposalId;
    }

    function requestSetProposalThreshold(uint256 newProposalThreshold, string calldata description)
        external
        override
        returns (uint256)
    {
        address[] memory targets = new address[](1);
        targets[0] = address(this);

        uint256[] memory values = new uint256[](1);
        values[0] = newProposalThreshold;

        bytes[] memory calldatas = new bytes[](1);
        calldatas[0] = abi.encodeWithSignature(
            "setProposalThreshold(uint256)",
            newProposalThreshold
        );

        uint256 proposalId = propose(targets, values, calldatas, description);

        return proposalId;
    }

    function HashtagNFTCollectiveManager()
        external
        view
        override
        returns (address)
    {
        return address(tokenAddr);
    }

    function requestLendAssets(
        uint256 timeOutBlockTime,
        address newOwnerAddress,
        uint256 amountOfERC20Request,
        address addressERC20,
        address assetAddress,
        string calldata description
    ) external override returns (uint256) {}

    function refundBuyoutFee(uint256 proposalId) external nonReentrant override {
        require(_msgSender() == depositors[proposalId], "failure: wrong depositor");

        require(
            state(proposalId) == ProposalState.Canceled,
            "failure: proposal must be cancelled"
        );
        require(
            buyoutProposalFeeRefunded[proposalId] == false,
            "failure: buyout-fee refunded"
        );
        buyoutProposalFeeRefunded[proposalId] = true;
        (bool sent,) = payable(_msgSender()).call{
                value: buyoutProposalDeposits[proposalId]
        }("");
        require(sent, "Failed to send transaction");
    }

    function requestRetrieveAsset(
        address assetAddress,
        address oldOwnerAddress,
        address newOwnerAddress,
        string calldata description
    ) external override returns (uint256) {}

    function SetProposers(address[] memory proposers) external onlyCurator {
        require(IERC20(tokenAddr).balanceOf(msg.sender) > (IERC20(tokenAddr).totalSupply() / 2));
        IHashtagNFTCollectiveTimelockController(timelockController).SetProposers(proposers);
    }

    function SetExecutors(address[] memory executors) external onlyCurator {
        require(IERC20(tokenAddr).balanceOf(msg.sender) > (IERC20(tokenAddr).totalSupply() / 2));
        IHashtagNFTCollectiveTimelockController(timelockController).SetExecutors(executors);
    }

    function SetAdmins(address[] memory admins) external onlyCurator {
        require(IERC20(tokenAddr).balanceOf(msg.sender) > (IERC20(tokenAddr).totalSupply() / 2));
        IHashtagNFTCollectiveTimelockController(timelockController).SetAdmins(admins);
    }

    modifier onlyCurator {
        require(msg.sender == curator, "CollectiveGovernor: not curator");
        _;
    }

    function _msgData() internal view virtual override(ERC2771ContextUpgradeable, ContextUpgradeable) returns (bytes calldata) {
        return super._msgData();
    }

    function _msgSender() internal view virtual override(ERC2771ContextUpgradeable, ContextUpgradeable) returns (address sender) {
        return super._msgSender();
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

enum BuyInOfferState {
    PENDING,
    REJECTED,
    ACCEPTED,
    EXPIRED
}

struct BuyInOffer {
    string offerId;
    uint256 itemId;
    // uint256 percentage;
    uint256 amountERC20;
    uint256 tokenAmount;
    uint256 expiry;
    BuyInOfferState state;
    // address creator;
    address buyer;
    address erc20Token;
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;
import "./Interface/IHashtagNFTCollectiveTimelockController.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "@openzeppelin/contracts-upgradeable/governance/extensions/GovernorTimelockControlUpgradeable.sol";
import "./ERC2771Config.sol";

contract HashtagNFTCollectiveTimelockController is
    Initializable,
    IHashtagNFTCollectiveTimelockController,
    ERC2771Config,
    TimelockControllerUpgradeable
{
    address private manager;
    address private governor;

    modifier onlyManager() {
        require(_msgSender() == manager, "TimelockController: only manager authorized");
        _;
    }

    modifier onlyGovernor() {
        require(_msgSender() == governor, "TimelockController: only governor authorized");
        _;
    }

    function initialize(
        uint256 _minDelay,
        address[] calldata _proposers,
        address[] calldata _executors
    ) external initializer {
        __ERC2771Config_init();
        __TimelockController_init(_minDelay, _proposers, _executors);
        manager = _msgSender();
    }

    function SetProposers(address[] memory proposers)
        external
        override
        onlyGovernor
    {
        for (uint256 i = 0; i < proposers.length; i++) {
            _setupRole(PROPOSER_ROLE, proposers[i]);
        }
    }

    function SetExecutors(address[] memory executors)
        external
        override
        onlyGovernor
    {
        for (uint256 i = 0; i < executors.length; i++) {
            _setupRole(EXECUTOR_ROLE, executors[i]);
        }
    }

    function SetAdmins(address[] memory admins) external override onlyGovernor {
        for (uint256 i = 0; i < admins.length; i++) {
            _setupRole(TIMELOCK_ADMIN_ROLE, admins[i]);
        }
    }

    function setGovernor(address _governor) external onlyManager {
        governor = _governor;
    }

    function _msgData()
        internal
        view
        virtual
        override(ERC2771ContextUpgradeable, ContextUpgradeable)
        returns (bytes calldata)
    {
        return super._msgData();
    }

    function _msgSender()
        internal
        view
        virtual
        override(ERC2771ContextUpgradeable, ContextUpgradeable)
        returns (address sender)
    {
        return super._msgSender();
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

interface IHashtagNFTCollectiveTimelockController{
    function SetProposers(address[] memory proposers) external;
    function SetExecutors(address[] memory executors) external;
    function SetAdmins(address[] memory admins) external;
    function setGovernor(address governor) external;
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface IHashtagNFTCollectiveNFTVault {

    function storeNftDetail(address _from, uint _tokenId) external;

    function setAssetCount(uint256 _count) external returns (uint256);

    function afterBuyout(address _curator) external;

    function getTokens() external view returns (address[] memory);

}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.0 (token/ERC20/extensions/IERC20Metadata.sol)

pragma solidity ^0.8.0;

import "../IERC20Upgradeable.sol";

/**
 * @dev Interface for the optional metadata functions from the ERC20 standard.
 *
 * _Available since v4.1._
 */
interface IERC20MetadataUpgradeable is IERC20Upgradeable {
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

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.0 (token/ERC20/extensions/draft-IERC20Permit.sol)

pragma solidity ^0.8.0;

/**
 * @dev Interface of the ERC20 Permit extension allowing approvals to be made via signatures, as defined in
 * https://eips.ethereum.org/EIPS/eip-2612[EIP-2612].
 *
 * Adds the {permit} method, which can be used to change an account's ERC20 allowance (see {IERC20-allowance}) by
 * presenting a message signed by the account. By not relying on {IERC20-approve}, the token holder account doesn't
 * need to send a transaction, and thus is not required to hold Ether at all.
 */
interface IERC20PermitUpgradeable {
    /**
     * @dev Sets `value` as the allowance of `spender` over ``owner``'s tokens,
     * given ``owner``'s signed approval.
     *
     * IMPORTANT: The same issues {IERC20-approve} has related to transaction
     * ordering also apply here.
     *
     * Emits an {Approval} event.
     *
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     * - `deadline` must be a timestamp in the future.
     * - `v`, `r` and `s` must be a valid `secp256k1` signature from `owner`
     * over the EIP712-formatted function arguments.
     * - the signature must use ``owner``'s current nonce (see {nonces}).
     *
     * For more information on the signature format, see the
     * https://eips.ethereum.org/EIPS/eip-2612#specification[relevant EIP
     * section].
     */
    function permit(
        address owner,
        address spender,
        uint256 value,
        uint256 deadline,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) external;

    /**
     * @dev Returns the current nonce for `owner`. This value must be
     * included whenever a signature is generated for {permit}.
     *
     * Every successful call to {permit} increases ``owner``'s nonce by one. This
     * prevents a signature from being used multiple times.
     */
    function nonces(address owner) external view returns (uint256);

    /**
     * @dev Returns the domain separator used in the encoding of the signature for {permit}, as defined by {EIP712}.
     */
    // solhint-disable-next-line func-name-mixedcase
    function DOMAIN_SEPARATOR() external view returns (bytes32);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.0 (utils/cryptography/draft-EIP712.sol)

pragma solidity ^0.8.0;

import "./ECDSAUpgradeable.sol";
import "../../proxy/utils/Initializable.sol";

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
abstract contract EIP712Upgradeable is Initializable {
    /* solhint-disable var-name-mixedcase */
    bytes32 private _HASHED_NAME;
    bytes32 private _HASHED_VERSION;
    bytes32 private constant _TYPE_HASH = keccak256("EIP712Domain(string name,string version,uint256 chainId,address verifyingContract)");

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
    function __EIP712_init(string memory name, string memory version) internal initializer {
        __EIP712_init_unchained(name, version);
    }

    function __EIP712_init_unchained(string memory name, string memory version) internal initializer {
        bytes32 hashedName = keccak256(bytes(name));
        bytes32 hashedVersion = keccak256(bytes(version));
        _HASHED_NAME = hashedName;
        _HASHED_VERSION = hashedVersion;
    }

    /**
     * @dev Returns the domain separator for the current chain.
     */
    function _domainSeparatorV4() internal view returns (bytes32) {
        return _buildDomainSeparator(_TYPE_HASH, _EIP712NameHash(), _EIP712VersionHash());
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
        return ECDSAUpgradeable.toTypedDataHash(_domainSeparatorV4(), structHash);
    }

    /**
     * @dev The hash of the name parameter for the EIP712 domain.
     *
     * NOTE: This function reads from storage by default, but can be redefined to return a constant value if gas costs
     * are a concern.
     */
    function _EIP712NameHash() internal virtual view returns (bytes32) {
        return _HASHED_NAME;
    }

    /**
     * @dev The hash of the version parameter for the EIP712 domain.
     *
     * NOTE: This function reads from storage by default, but can be redefined to return a constant value if gas costs
     * are a concern.
     */
    function _EIP712VersionHash() internal virtual view returns (bytes32) {
        return _HASHED_VERSION;
    }
    uint256[50] private __gap;
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.0 (utils/cryptography/ECDSA.sol)

pragma solidity ^0.8.0;

import "../StringsUpgradeable.sol";

/**
 * @dev Elliptic Curve Digital Signature Algorithm (ECDSA) operations.
 *
 * These functions can be used to verify that a message was signed by the holder
 * of the private keys of a given address.
 */
library ECDSAUpgradeable {
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
        bytes32 s;
        uint8 v;
        assembly {
            s := and(vs, 0x7fffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff)
            v := add(shr(255, vs), 27)
        }
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
        return keccak256(abi.encodePacked("\x19Ethereum Signed Message:\n", StringsUpgradeable.toString(s.length), s));
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
// OpenZeppelin Contracts v4.4.0 (utils/math/Math.sol)

pragma solidity ^0.8.0;

/**
 * @dev Standard math utilities missing in the Solidity language.
 */
library MathUpgradeable {
    /**
     * @dev Returns the largest of two numbers.
     */
    function max(uint256 a, uint256 b) internal pure returns (uint256) {
        return a >= b ? a : b;
    }

    /**
     * @dev Returns the smallest of two numbers.
     */
    function min(uint256 a, uint256 b) internal pure returns (uint256) {
        return a < b ? a : b;
    }

    /**
     * @dev Returns the average of two numbers. The result is rounded towards
     * zero.
     */
    function average(uint256 a, uint256 b) internal pure returns (uint256) {
        // (a + b) / 2 can overflow.
        return (a & b) + (a ^ b) / 2;
    }

    /**
     * @dev Returns the ceiling of the division of two numbers.
     *
     * This differs from standard division with `/` in that it rounds up instead
     * of rounding down.
     */
    function ceilDiv(uint256 a, uint256 b) internal pure returns (uint256) {
        // (a + b - 1) / b can overflow on addition, so we distribute.
        return a / b + (a % b == 0 ? 0 : 1);
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.0 (utils/math/SafeCast.sol)

pragma solidity ^0.8.0;

/**
 * @dev Wrappers over Solidity's uintXX/intXX casting operators with added overflow
 * checks.
 *
 * Downcasting from uint256/int256 in Solidity does not revert on overflow. This can
 * easily result in undesired exploitation or bugs, since developers usually
 * assume that overflows raise errors. `SafeCast` restores this intuition by
 * reverting the transaction when such an operation overflows.
 *
 * Using this library instead of the unchecked operations eliminates an entire
 * class of bugs, so it's recommended to use it always.
 *
 * Can be combined with {SafeMath} and {SignedSafeMath} to extend it to smaller types, by performing
 * all math on `uint256` and `int256` and then downcasting.
 */
library SafeCastUpgradeable {
    /**
     * @dev Returns the downcasted uint224 from uint256, reverting on
     * overflow (when the input is greater than largest uint224).
     *
     * Counterpart to Solidity's `uint224` operator.
     *
     * Requirements:
     *
     * - input must fit into 224 bits
     */
    function toUint224(uint256 value) internal pure returns (uint224) {
        require(value <= type(uint224).max, "SafeCast: value doesn't fit in 224 bits");
        return uint224(value);
    }

    /**
     * @dev Returns the downcasted uint128 from uint256, reverting on
     * overflow (when the input is greater than largest uint128).
     *
     * Counterpart to Solidity's `uint128` operator.
     *
     * Requirements:
     *
     * - input must fit into 128 bits
     */
    function toUint128(uint256 value) internal pure returns (uint128) {
        require(value <= type(uint128).max, "SafeCast: value doesn't fit in 128 bits");
        return uint128(value);
    }

    /**
     * @dev Returns the downcasted uint96 from uint256, reverting on
     * overflow (when the input is greater than largest uint96).
     *
     * Counterpart to Solidity's `uint96` operator.
     *
     * Requirements:
     *
     * - input must fit into 96 bits
     */
    function toUint96(uint256 value) internal pure returns (uint96) {
        require(value <= type(uint96).max, "SafeCast: value doesn't fit in 96 bits");
        return uint96(value);
    }

    /**
     * @dev Returns the downcasted uint64 from uint256, reverting on
     * overflow (when the input is greater than largest uint64).
     *
     * Counterpart to Solidity's `uint64` operator.
     *
     * Requirements:
     *
     * - input must fit into 64 bits
     */
    function toUint64(uint256 value) internal pure returns (uint64) {
        require(value <= type(uint64).max, "SafeCast: value doesn't fit in 64 bits");
        return uint64(value);
    }

    /**
     * @dev Returns the downcasted uint32 from uint256, reverting on
     * overflow (when the input is greater than largest uint32).
     *
     * Counterpart to Solidity's `uint32` operator.
     *
     * Requirements:
     *
     * - input must fit into 32 bits
     */
    function toUint32(uint256 value) internal pure returns (uint32) {
        require(value <= type(uint32).max, "SafeCast: value doesn't fit in 32 bits");
        return uint32(value);
    }

    /**
     * @dev Returns the downcasted uint16 from uint256, reverting on
     * overflow (when the input is greater than largest uint16).
     *
     * Counterpart to Solidity's `uint16` operator.
     *
     * Requirements:
     *
     * - input must fit into 16 bits
     */
    function toUint16(uint256 value) internal pure returns (uint16) {
        require(value <= type(uint16).max, "SafeCast: value doesn't fit in 16 bits");
        return uint16(value);
    }

    /**
     * @dev Returns the downcasted uint8 from uint256, reverting on
     * overflow (when the input is greater than largest uint8).
     *
     * Counterpart to Solidity's `uint8` operator.
     *
     * Requirements:
     *
     * - input must fit into 8 bits.
     */
    function toUint8(uint256 value) internal pure returns (uint8) {
        require(value <= type(uint8).max, "SafeCast: value doesn't fit in 8 bits");
        return uint8(value);
    }

    /**
     * @dev Converts a signed int256 into an unsigned uint256.
     *
     * Requirements:
     *
     * - input must be greater than or equal to 0.
     */
    function toUint256(int256 value) internal pure returns (uint256) {
        require(value >= 0, "SafeCast: value must be positive");
        return uint256(value);
    }

    /**
     * @dev Returns the downcasted int128 from int256, reverting on
     * overflow (when the input is less than smallest int128 or
     * greater than largest int128).
     *
     * Counterpart to Solidity's `int128` operator.
     *
     * Requirements:
     *
     * - input must fit into 128 bits
     *
     * _Available since v3.1._
     */
    function toInt128(int256 value) internal pure returns (int128) {
        require(value >= type(int128).min && value <= type(int128).max, "SafeCast: value doesn't fit in 128 bits");
        return int128(value);
    }

    /**
     * @dev Returns the downcasted int64 from int256, reverting on
     * overflow (when the input is less than smallest int64 or
     * greater than largest int64).
     *
     * Counterpart to Solidity's `int64` operator.
     *
     * Requirements:
     *
     * - input must fit into 64 bits
     *
     * _Available since v3.1._
     */
    function toInt64(int256 value) internal pure returns (int64) {
        require(value >= type(int64).min && value <= type(int64).max, "SafeCast: value doesn't fit in 64 bits");
        return int64(value);
    }

    /**
     * @dev Returns the downcasted int32 from int256, reverting on
     * overflow (when the input is less than smallest int32 or
     * greater than largest int32).
     *
     * Counterpart to Solidity's `int32` operator.
     *
     * Requirements:
     *
     * - input must fit into 32 bits
     *
     * _Available since v3.1._
     */
    function toInt32(int256 value) internal pure returns (int32) {
        require(value >= type(int32).min && value <= type(int32).max, "SafeCast: value doesn't fit in 32 bits");
        return int32(value);
    }

    /**
     * @dev Returns the downcasted int16 from int256, reverting on
     * overflow (when the input is less than smallest int16 or
     * greater than largest int16).
     *
     * Counterpart to Solidity's `int16` operator.
     *
     * Requirements:
     *
     * - input must fit into 16 bits
     *
     * _Available since v3.1._
     */
    function toInt16(int256 value) internal pure returns (int16) {
        require(value >= type(int16).min && value <= type(int16).max, "SafeCast: value doesn't fit in 16 bits");
        return int16(value);
    }

    /**
     * @dev Returns the downcasted int8 from int256, reverting on
     * overflow (when the input is less than smallest int8 or
     * greater than largest int8).
     *
     * Counterpart to Solidity's `int8` operator.
     *
     * Requirements:
     *
     * - input must fit into 8 bits.
     *
     * _Available since v3.1._
     */
    function toInt8(int256 value) internal pure returns (int8) {
        require(value >= type(int8).min && value <= type(int8).max, "SafeCast: value doesn't fit in 8 bits");
        return int8(value);
    }

    /**
     * @dev Converts an unsigned uint256 into a signed int256.
     *
     * Requirements:
     *
     * - input must be less than or equal to maxInt256.
     */
    function toInt256(uint256 value) internal pure returns (int256) {
        // Note: Unsafe cast below is okay because `type(int256).max` is guaranteed to be positive
        require(value <= uint256(type(int256).max), "SafeCast: value doesn't fit in an int256");
        return int256(value);
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.0 (governance/Governor.sol)

pragma solidity ^0.8.0;

import "../utils/cryptography/ECDSAUpgradeable.sol";
import "../utils/cryptography/draft-EIP712Upgradeable.sol";
import "../utils/introspection/ERC165Upgradeable.sol";
import "../utils/math/SafeCastUpgradeable.sol";
import "../utils/AddressUpgradeable.sol";
import "../utils/ContextUpgradeable.sol";
import "../utils/TimersUpgradeable.sol";
import "./IGovernorUpgradeable.sol";
import "../proxy/utils/Initializable.sol";

/**
 * @dev Core of the governance system, designed to be extended though various modules.
 *
 * This contract is abstract and requires several function to be implemented in various modules:
 *
 * - A counting module must implement {quorum}, {_quorumReached}, {_voteSucceeded} and {_countVote}
 * - A voting module must implement {getVotes}
 * - Additionanly, the {votingPeriod} must also be implemented
 *
 * _Available since v4.3._
 */
abstract contract GovernorUpgradeable is Initializable, ContextUpgradeable, ERC165Upgradeable, EIP712Upgradeable, IGovernorUpgradeable {
    using SafeCastUpgradeable for uint256;
    using TimersUpgradeable for TimersUpgradeable.BlockNumber;

    bytes32 public constant BALLOT_TYPEHASH = keccak256("Ballot(uint256 proposalId,uint8 support)");

    struct ProposalCore {
        TimersUpgradeable.BlockNumber voteStart;
        TimersUpgradeable.BlockNumber voteEnd;
        bool executed;
        bool canceled;
    }

    string private _name;

    mapping(uint256 => ProposalCore) private _proposals;

    /**
     * @dev Restrict access to governor executing address. Some module might override the _executor function to make
     * sure this modifier is consistant with the execution model.
     */
    modifier onlyGovernance() {
        require(_msgSender() == _executor(), "Governor: onlyGovernance");
        _;
    }

    /**
     * @dev Sets the value for {name} and {version}
     */
    function __Governor_init(string memory name_) internal initializer {
        __Context_init_unchained();
        __ERC165_init_unchained();
        __EIP712_init_unchained(name_, version());
        __IGovernor_init_unchained();
        __Governor_init_unchained(name_);
    }

    function __Governor_init_unchained(string memory name_) internal initializer {
        _name = name_;
    }

    /**
     * @dev Function to receive ETH that will be handled by the governor (disabled if executor is a third party contract)
     */
    receive() external payable virtual {
        require(_executor() == address(this));
    }

    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId) public view virtual override(IERC165Upgradeable, ERC165Upgradeable) returns (bool) {
        return interfaceId == type(IGovernorUpgradeable).interfaceId || super.supportsInterface(interfaceId);
    }

    /**
     * @dev See {IGovernor-name}.
     */
    function name() public view virtual override returns (string memory) {
        return _name;
    }

    /**
     * @dev See {IGovernor-version}.
     */
    function version() public view virtual override returns (string memory) {
        return "1";
    }

    /**
     * @dev See {IGovernor-hashProposal}.
     *
     * The proposal id is produced by hashing the RLC encoded `targets` array, the `values` array, the `calldatas` array
     * and the descriptionHash (bytes32 which itself is the keccak256 hash of the description string). This proposal id
     * can be produced from the proposal data which is part of the {ProposalCreated} event. It can even be computed in
     * advance, before the proposal is submitted.
     *
     * Note that the chainId and the governor address are not part of the proposal id computation. Consequently, the
     * same proposal (with same operation and same description) will have the same id if submitted on multiple governors
     * accross multiple networks. This also means that in order to execute the same operation twice (on the same
     * governor) the proposer will have to change the description in order to avoid proposal id conflicts.
     */
    function hashProposal(
        address[] memory targets,
        uint256[] memory values,
        bytes[] memory calldatas,
        bytes32 descriptionHash
    ) public pure virtual override returns (uint256) {
        return uint256(keccak256(abi.encode(targets, values, calldatas, descriptionHash)));
    }

    /**
     * @dev See {IGovernor-state}.
     */
    function state(uint256 proposalId) public view virtual override returns (ProposalState) {
        ProposalCore memory proposal = _proposals[proposalId];

        if (proposal.executed) {
            return ProposalState.Executed;
        } else if (proposal.canceled) {
            return ProposalState.Canceled;
        } else if (proposal.voteStart.getDeadline() >= block.number) {
            return ProposalState.Pending;
        } else if (proposal.voteEnd.getDeadline() >= block.number) {
            return ProposalState.Active;
        } else if (proposal.voteEnd.isExpired()) {
            return
                _quorumReached(proposalId) && _voteSucceeded(proposalId)
                    ? ProposalState.Succeeded
                    : ProposalState.Defeated;
        } else {
            revert("Governor: unknown proposal id");
        }
    }

    /**
     * @dev See {IGovernor-proposalSnapshot}.
     */
    function proposalSnapshot(uint256 proposalId) public view virtual override returns (uint256) {
        return _proposals[proposalId].voteStart.getDeadline();
    }

    /**
     * @dev See {IGovernor-proposalDeadline}.
     */
    function proposalDeadline(uint256 proposalId) public view virtual override returns (uint256) {
        return _proposals[proposalId].voteEnd.getDeadline();
    }

    /**
     * @dev Part of the Governor Bravo's interface: _"The number of votes required in order for a voter to become a proposer"_.
     */
    function proposalThreshold() public view virtual returns (uint256) {
        return 0;
    }

    /**
     * @dev Amount of votes already cast passes the threshold limit.
     */
    function _quorumReached(uint256 proposalId) internal view virtual returns (bool);

    /**
     * @dev Is the proposal successful or not.
     */
    function _voteSucceeded(uint256 proposalId) internal view virtual returns (bool);

    /**
     * @dev Register a vote with a given support and voting weight.
     *
     * Note: Support is generic and can represent various things depending on the voting system used.
     */
    function _countVote(
        uint256 proposalId,
        address account,
        uint8 support,
        uint256 weight
    ) internal virtual;

    /**
     * @dev See {IGovernor-propose}.
     */
    function propose(
        address[] memory targets,
        uint256[] memory values,
        bytes[] memory calldatas,
        string memory description
    ) public virtual override returns (uint256) {
        require(
            getVotes(msg.sender, block.number - 1) >= proposalThreshold(),
            "GovernorCompatibilityBravo: proposer votes below proposal threshold"
        );

        uint256 proposalId = hashProposal(targets, values, calldatas, keccak256(bytes(description)));

        require(targets.length == values.length, "Governor: invalid proposal length");
        require(targets.length == calldatas.length, "Governor: invalid proposal length");
        require(targets.length > 0, "Governor: empty proposal");

        ProposalCore storage proposal = _proposals[proposalId];
        require(proposal.voteStart.isUnset(), "Governor: proposal already exists");

        uint64 snapshot = block.number.toUint64() + votingDelay().toUint64();
        uint64 deadline = snapshot + votingPeriod().toUint64();

        proposal.voteStart.setDeadline(snapshot);
        proposal.voteEnd.setDeadline(deadline);

        emit ProposalCreated(
            proposalId,
            _msgSender(),
            targets,
            values,
            new string[](targets.length),
            calldatas,
            snapshot,
            deadline,
            description
        );

        return proposalId;
    }

    /**
     * @dev See {IGovernor-execute}.
     */
    function execute(
        address[] memory targets,
        uint256[] memory values,
        bytes[] memory calldatas,
        bytes32 descriptionHash
    ) public payable virtual override returns (uint256) {
        uint256 proposalId = hashProposal(targets, values, calldatas, descriptionHash);

        ProposalState status = state(proposalId);
        require(
            status == ProposalState.Succeeded || status == ProposalState.Queued,
            "Governor: proposal not successful"
        );
        _proposals[proposalId].executed = true;

        emit ProposalExecuted(proposalId);

        _execute(proposalId, targets, values, calldatas, descriptionHash);

        return proposalId;
    }

    /**
     * @dev Internal execution mechanism. Can be overriden to implement different execution mechanism
     */
    function _execute(
        uint256, /* proposalId */
        address[] memory targets,
        uint256[] memory values,
        bytes[] memory calldatas,
        bytes32 /*descriptionHash*/
    ) internal virtual {
        string memory errorMessage = "Governor: call reverted without message";
        for (uint256 i = 0; i < targets.length; ++i) {
            (bool success, bytes memory returndata) = targets[i].call{value: values[i]}(calldatas[i]);
            AddressUpgradeable.verifyCallResult(success, returndata, errorMessage);
        }
    }

    /**
     * @dev Internal cancel mechanism: locks up the proposal timer, preventing it from being re-submitted. Marks it as
     * canceled to allow distinguishing it from executed proposals.
     *
     * Emits a {IGovernor-ProposalCanceled} event.
     */
    function _cancel(
        address[] memory targets,
        uint256[] memory values,
        bytes[] memory calldatas,
        bytes32 descriptionHash
    ) internal virtual returns (uint256) {
        uint256 proposalId = hashProposal(targets, values, calldatas, descriptionHash);
        ProposalState status = state(proposalId);

        require(
            status != ProposalState.Canceled && status != ProposalState.Expired && status != ProposalState.Executed,
            "Governor: proposal not active"
        );
        _proposals[proposalId].canceled = true;

        emit ProposalCanceled(proposalId);

        return proposalId;
    }

    /**
     * @dev See {IGovernor-castVote}.
     */
    function castVote(uint256 proposalId, uint8 support) public virtual override returns (uint256) {
        address voter = _msgSender();
        return _castVote(proposalId, voter, support, "");
    }

    /**
     * @dev See {IGovernor-castVoteWithReason}.
     */
    function castVoteWithReason(
        uint256 proposalId,
        uint8 support,
        string calldata reason
    ) public virtual override returns (uint256) {
        address voter = _msgSender();
        return _castVote(proposalId, voter, support, reason);
    }

    /**
     * @dev See {IGovernor-castVoteBySig}.
     */
    function castVoteBySig(
        uint256 proposalId,
        uint8 support,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) public virtual override returns (uint256) {
        address voter = ECDSAUpgradeable.recover(
            _hashTypedDataV4(keccak256(abi.encode(BALLOT_TYPEHASH, proposalId, support))),
            v,
            r,
            s
        );
        return _castVote(proposalId, voter, support, "");
    }

    /**
     * @dev Internal vote casting mechanism: Check that the vote is pending, that it has not been cast yet, retrieve
     * voting weight using {IGovernor-getVotes} and call the {_countVote} internal function.
     *
     * Emits a {IGovernor-VoteCast} event.
     */
    function _castVote(
        uint256 proposalId,
        address account,
        uint8 support,
        string memory reason
    ) internal virtual returns (uint256) {
        ProposalCore storage proposal = _proposals[proposalId];
        require(state(proposalId) == ProposalState.Active, "Governor: vote not currently active");

        uint256 weight = getVotes(account, proposal.voteStart.getDeadline());
        _countVote(proposalId, account, support, weight);

        emit VoteCast(account, proposalId, support, weight, reason);

        return weight;
    }

    /**
     * @dev Address through which the governor executes action. Will be overloaded by module that execute actions
     * through another contract such as a timelock.
     */
    function _executor() internal view virtual returns (address) {
        return address(this);
    }
    uint256[48] private __gap;
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.0 (governance/IGovernor.sol)

pragma solidity ^0.8.0;

import "../utils/introspection/ERC165Upgradeable.sol";
import "../proxy/utils/Initializable.sol";

/**
 * @dev Interface of the {Governor} core.
 *
 * _Available since v4.3._
 */
abstract contract IGovernorUpgradeable is Initializable, IERC165Upgradeable {
    function __IGovernor_init() internal initializer {
        __IGovernor_init_unchained();
    }

    function __IGovernor_init_unchained() internal initializer {
    }
    enum ProposalState {
        Pending,
        Active,
        Canceled,
        Defeated,
        Succeeded,
        Queued,
        Expired,
        Executed
    }

    /**
     * @dev Emitted when a proposal is created.
     */
    event ProposalCreated(
        uint256 proposalId,
        address proposer,
        address[] targets,
        uint256[] values,
        string[] signatures,
        bytes[] calldatas,
        uint256 startBlock,
        uint256 endBlock,
        string description
    );

    /**
     * @dev Emitted when a proposal is canceled.
     */
    event ProposalCanceled(uint256 proposalId);

    /**
     * @dev Emitted when a proposal is executed.
     */
    event ProposalExecuted(uint256 proposalId);

    /**
     * @dev Emitted when a vote is cast.
     *
     * Note: `support` values should be seen as buckets. There interpretation depends on the voting module used.
     */
    event VoteCast(address indexed voter, uint256 proposalId, uint8 support, uint256 weight, string reason);

    /**
     * @notice module:core
     * @dev Name of the governor instance (used in building the ERC712 domain separator).
     */
    function name() public view virtual returns (string memory);

    /**
     * @notice module:core
     * @dev Version of the governor instance (used in building the ERC712 domain separator). Default: "1"
     */
    function version() public view virtual returns (string memory);

    /**
     * @notice module:voting
     * @dev A description of the possible `support` values for {castVote} and the way these votes are counted, meant to
     * be consumed by UIs to show correct vote options and interpret the results. The string is a URL-encoded sequence of
     * key-value pairs that each describe one aspect, for example `support=bravo&quorum=for,abstain`.
     *
     * There are 2 standard keys: `support` and `quorum`.
     *
     * - `support=bravo` refers to the vote options 0 = Against, 1 = For, 2 = Abstain, as in `GovernorBravo`.
     * - `quorum=bravo` means that only For votes are counted towards quorum.
     * - `quorum=for,abstain` means that both For and Abstain votes are counted towards quorum.
     *
     * NOTE: The string can be decoded by the standard
     * https://developer.mozilla.org/en-US/docs/Web/API/URLSearchParams[`URLSearchParams`]
     * JavaScript class.
     */
    // solhint-disable-next-line func-name-mixedcase
    function COUNTING_MODE() public pure virtual returns (string memory);

    /**
     * @notice module:core
     * @dev Hashing function used to (re)build the proposal id from the proposal details..
     */
    function hashProposal(
        address[] calldata targets,
        uint256[] calldata values,
        bytes[] calldata calldatas,
        bytes32 descriptionHash
    ) public pure virtual returns (uint256);

    /**
     * @notice module:core
     * @dev Current state of a proposal, following Compound's convention
     */
    function state(uint256 proposalId) public view virtual returns (ProposalState);

    /**
     * @notice module:core
     * @dev Block number used to retrieve user's votes and quorum. As per Compound's Comp and OpenZeppelin's
     * ERC20Votes, the snapshot is performed at the end of this block. Hence, voting for this proposal starts at the
     * beginning of the following block.
     */
    function proposalSnapshot(uint256 proposalId) public view virtual returns (uint256);

    /**
     * @notice module:core
     * @dev Block number at which votes close. Votes close at the end of this block, so it is possible to cast a vote
     * during this block.
     */
    function proposalDeadline(uint256 proposalId) public view virtual returns (uint256);

    /**
     * @notice module:user-config
     * @dev Delay, in number of block, between the proposal is created and the vote starts. This can be increassed to
     * leave time for users to buy voting power, of delegate it, before the voting of a proposal starts.
     */
    function votingDelay() public view virtual returns (uint256);

    /**
     * @notice module:user-config
     * @dev Delay, in number of blocks, between the vote start and vote ends.
     *
     * NOTE: The {votingDelay} can delay the start of the vote. This must be considered when setting the voting
     * duration compared to the voting delay.
     */
    function votingPeriod() public view virtual returns (uint256);

    /**
     * @notice module:user-config
     * @dev Minimum number of cast voted required for a proposal to be successful.
     *
     * Note: The `blockNumber` parameter corresponds to the snaphot used for counting vote. This allows to scale the
     * quroum depending on values such as the totalSupply of a token at this block (see {ERC20Votes}).
     */
    function quorum(uint256 blockNumber) public view virtual returns (uint256);

    /**
     * @notice module:reputation
     * @dev Voting power of an `account` at a specific `blockNumber`.
     *
     * Note: this can be implemented in a number of ways, for example by reading the delegated balance from one (or
     * multiple), {ERC20Votes} tokens.
     */
    function getVotes(address account, uint256 blockNumber) public view virtual returns (uint256);

    /**
     * @notice module:voting
     * @dev Returns weither `account` has cast a vote on `proposalId`.
     */
    function hasVoted(uint256 proposalId, address account) public view virtual returns (bool);

    /**
     * @dev Create a new proposal. Vote start {IGovernor-votingDelay} blocks after the proposal is created and ends
     * {IGovernor-votingPeriod} blocks after the voting starts.
     *
     * Emits a {ProposalCreated} event.
     */
    function propose(
        address[] memory targets,
        uint256[] memory values,
        bytes[] memory calldatas,
        string memory description
    ) public virtual returns (uint256 proposalId);

    /**
     * @dev Execute a successful proposal. This requires the quorum to be reached, the vote to be successful, and the
     * deadline to be reached.
     *
     * Emits a {ProposalExecuted} event.
     *
     * Note: some module can modify the requirements for execution, for example by adding an additional timelock.
     */
    function execute(
        address[] memory targets,
        uint256[] memory values,
        bytes[] memory calldatas,
        bytes32 descriptionHash
    ) public payable virtual returns (uint256 proposalId);

    /**
     * @dev Cast a vote
     *
     * Emits a {VoteCast} event.
     */
    function castVote(uint256 proposalId, uint8 support) public virtual returns (uint256 balance);

    /**
     * @dev Cast a with a reason
     *
     * Emits a {VoteCast} event.
     */
    function castVoteWithReason(
        uint256 proposalId,
        uint8 support,
        string calldata reason
    ) public virtual returns (uint256 balance);

    /**
     * @dev Cast a vote using the user cryptographic signature.
     *
     * Emits a {VoteCast} event.
     */
    function castVoteBySig(
        uint256 proposalId,
        uint8 support,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) public virtual returns (uint256 balance);
    uint256[50] private __gap;
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.0 (governance/extensions/GovernorSettings.sol)

pragma solidity ^0.8.0;

import "../GovernorUpgradeable.sol";
import "../../proxy/utils/Initializable.sol";

/**
 * @dev Extension of {Governor} for settings updatable through governance.
 *
 * _Available since v4.4._
 */
abstract contract GovernorSettingsUpgradeable is Initializable, GovernorUpgradeable {
    uint256 private _votingDelay;
    uint256 private _votingPeriod;
    uint256 private _proposalThreshold;

    event VotingDelaySet(uint256 oldVotingDelay, uint256 newVotingDelay);
    event VotingPeriodSet(uint256 oldVotingPeriod, uint256 newVotingPeriod);
    event ProposalThresholdSet(uint256 oldProposalThreshold, uint256 newProposalThreshold);

    /**
     * @dev Initialize the governance parameters.
     */
    function __GovernorSettings_init(
        uint256 initialVotingDelay,
        uint256 initialVotingPeriod,
        uint256 initialProposalThreshold
    ) internal initializer {
        __Context_init_unchained();
        __ERC165_init_unchained();
        __IGovernor_init_unchained();
        __GovernorSettings_init_unchained(initialVotingDelay, initialVotingPeriod, initialProposalThreshold);
    }

    function __GovernorSettings_init_unchained(
        uint256 initialVotingDelay,
        uint256 initialVotingPeriod,
        uint256 initialProposalThreshold
    ) internal initializer {
        _setVotingDelay(initialVotingDelay);
        _setVotingPeriod(initialVotingPeriod);
        _setProposalThreshold(initialProposalThreshold);
    }

    /**
     * @dev See {IGovernor-votingDelay}.
     */
    function votingDelay() public view virtual override returns (uint256) {
        return _votingDelay;
    }

    /**
     * @dev See {IGovernor-votingPeriod}.
     */
    function votingPeriod() public view virtual override returns (uint256) {
        return _votingPeriod;
    }

    /**
     * @dev See {Governor-proposalThreshold}.
     */
    function proposalThreshold() public view virtual override returns (uint256) {
        return _proposalThreshold;
    }

    /**
     * @dev Update the voting delay. This operation can only be performed through a governance proposal.
     *
     * Emits a {VotingDelaySet} event.
     */
    function setVotingDelay(uint256 newVotingDelay) public virtual onlyGovernance {
        _setVotingDelay(newVotingDelay);
    }

    /**
     * @dev Update the voting period. This operation can only be performed through a governance proposal.
     *
     * Emits a {VotingPeriodSet} event.
     */
    function setVotingPeriod(uint256 newVotingPeriod) public virtual onlyGovernance {
        _setVotingPeriod(newVotingPeriod);
    }

    /**
     * @dev Update the proposal threshold. This operation can only be performed through a governance proposal.
     *
     * Emits a {ProposalThresholdSet} event.
     */
    function setProposalThreshold(uint256 newProposalThreshold) public virtual onlyGovernance {
        _setProposalThreshold(newProposalThreshold);
    }

    /**
     * @dev Internal setter for the voting delay.
     *
     * Emits a {VotingDelaySet} event.
     */
    function _setVotingDelay(uint256 newVotingDelay) internal virtual {
        emit VotingDelaySet(_votingDelay, newVotingDelay);
        _votingDelay = newVotingDelay;
    }

    /**
     * @dev Internal setter for the voting period.
     *
     * Emits a {VotingPeriodSet} event.
     */
    function _setVotingPeriod(uint256 newVotingPeriod) internal virtual {
        // voting period must be at least one block long
        require(newVotingPeriod > 0, "GovernorSettings: voting period too low");
        emit VotingPeriodSet(_votingPeriod, newVotingPeriod);
        _votingPeriod = newVotingPeriod;
    }

    /**
     * @dev Internal setter for the proposal threshold.
     *
     * Emits a {ProposalThresholdSet} event.
     */
    function _setProposalThreshold(uint256 newProposalThreshold) internal virtual {
        emit ProposalThresholdSet(_proposalThreshold, newProposalThreshold);
        _proposalThreshold = newProposalThreshold;
    }
    uint256[47] private __gap;
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.0 (governance/extensions/GovernorCountingSimple.sol)

pragma solidity ^0.8.0;

import "../GovernorUpgradeable.sol";
import "../../proxy/utils/Initializable.sol";

/**
 * @dev Extension of {Governor} for simple, 3 options, vote counting.
 *
 * _Available since v4.3._
 */
abstract contract GovernorCountingSimpleUpgradeable is Initializable, GovernorUpgradeable {
    function __GovernorCountingSimple_init() internal initializer {
        __Context_init_unchained();
        __ERC165_init_unchained();
        __IGovernor_init_unchained();
        __GovernorCountingSimple_init_unchained();
    }

    function __GovernorCountingSimple_init_unchained() internal initializer {
    }
    /**
     * @dev Supported vote types. Matches Governor Bravo ordering.
     */
    enum VoteType {
        Against,
        For,
        Abstain
    }

    struct ProposalVote {
        uint256 againstVotes;
        uint256 forVotes;
        uint256 abstainVotes;
        mapping(address => bool) hasVoted;
    }

    mapping(uint256 => ProposalVote) private _proposalVotes;

    /**
     * @dev See {IGovernor-COUNTING_MODE}.
     */
    // solhint-disable-next-line func-name-mixedcase
    function COUNTING_MODE() public pure virtual override returns (string memory) {
        return "support=bravo&quorum=for,abstain";
    }

    /**
     * @dev See {IGovernor-hasVoted}.
     */
    function hasVoted(uint256 proposalId, address account) public view virtual override returns (bool) {
        return _proposalVotes[proposalId].hasVoted[account];
    }

    /**
     * @dev Accessor to the internal vote counts.
     */
    function proposalVotes(uint256 proposalId)
        public
        view
        virtual
        returns (
            uint256 againstVotes,
            uint256 forVotes,
            uint256 abstainVotes
        )
    {
        ProposalVote storage proposalvote = _proposalVotes[proposalId];
        return (proposalvote.againstVotes, proposalvote.forVotes, proposalvote.abstainVotes);
    }

    /**
     * @dev See {Governor-_quorumReached}.
     */
    function _quorumReached(uint256 proposalId) internal view virtual override returns (bool) {
        ProposalVote storage proposalvote = _proposalVotes[proposalId];

        return quorum(proposalSnapshot(proposalId)) <= proposalvote.forVotes + proposalvote.abstainVotes;
    }

    /**
     * @dev See {Governor-_voteSucceeded}. In this module, the forVotes must be strictly over the againstVotes.
     */
    function _voteSucceeded(uint256 proposalId) internal view virtual override returns (bool) {
        ProposalVote storage proposalvote = _proposalVotes[proposalId];

        return proposalvote.forVotes > proposalvote.againstVotes;
    }

    /**
     * @dev See {Governor-_countVote}. In this module, the support follows the `VoteType` enum (from Governor Bravo).
     */
    function _countVote(
        uint256 proposalId,
        address account,
        uint8 support,
        uint256 weight
    ) internal virtual override {
        ProposalVote storage proposalvote = _proposalVotes[proposalId];

        require(!proposalvote.hasVoted[account], "GovernorVotingSimple: vote already cast");
        proposalvote.hasVoted[account] = true;

        if (support == uint8(VoteType.Against)) {
            proposalvote.againstVotes += weight;
        } else if (support == uint8(VoteType.For)) {
            proposalvote.forVotes += weight;
        } else if (support == uint8(VoteType.Abstain)) {
            proposalvote.abstainVotes += weight;
        } else {
            revert("GovernorVotingSimple: invalid value for enum VoteType");
        }
    }
    uint256[49] private __gap;
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.0 (governance/extensions/GovernorVotes.sol)

pragma solidity ^0.8.0;

import "../GovernorUpgradeable.sol";
import "../../token/ERC20/extensions/ERC20VotesUpgradeable.sol";
import "../../utils/math/MathUpgradeable.sol";
import "../../proxy/utils/Initializable.sol";

/**
 * @dev Extension of {Governor} for voting weight extraction from an {ERC20Votes} token.
 *
 * _Available since v4.3._
 */
abstract contract GovernorVotesUpgradeable is Initializable, GovernorUpgradeable {
    ERC20VotesUpgradeable public token;

    function __GovernorVotes_init(ERC20VotesUpgradeable tokenAddress) internal initializer {
        __Context_init_unchained();
        __ERC165_init_unchained();
        __IGovernor_init_unchained();
        __GovernorVotes_init_unchained(tokenAddress);
    }

    function __GovernorVotes_init_unchained(ERC20VotesUpgradeable tokenAddress) internal initializer {
        token = tokenAddress;
    }

    /**
     * Read the voting weight from the token's built in snapshot mechanism (see {IGovernor-getVotes}).
     */
    function getVotes(address account, uint256 blockNumber) public view virtual override returns (uint256) {
        return token.getPastVotes(account, blockNumber);
    }
    uint256[50] private __gap;
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.0 (governance/extensions/GovernorVotesQuorumFraction.sol)

pragma solidity ^0.8.0;

import "./GovernorVotesUpgradeable.sol";
import "../../proxy/utils/Initializable.sol";

/**
 * @dev Extension of {Governor} for voting weight extraction from an {ERC20Votes} token and a quorum expressed as a
 * fraction of the total supply.
 *
 * _Available since v4.3._
 */
abstract contract GovernorVotesQuorumFractionUpgradeable is Initializable, GovernorVotesUpgradeable {
    uint256 private _quorumNumerator;

    event QuorumNumeratorUpdated(uint256 oldQuorumNumerator, uint256 newQuorumNumerator);

    function __GovernorVotesQuorumFraction_init(uint256 quorumNumeratorValue) internal initializer {
        __Context_init_unchained();
        __ERC165_init_unchained();
        __IGovernor_init_unchained();
        __GovernorVotesQuorumFraction_init_unchained(quorumNumeratorValue);
    }

    function __GovernorVotesQuorumFraction_init_unchained(uint256 quorumNumeratorValue) internal initializer {
        _updateQuorumNumerator(quorumNumeratorValue);
    }

    function quorumNumerator() public view virtual returns (uint256) {
        return _quorumNumerator;
    }

    function quorumDenominator() public view virtual returns (uint256) {
        return 100;
    }

    function quorum(uint256 blockNumber) public view virtual override returns (uint256) {
        return (token.getPastTotalSupply(blockNumber) * quorumNumerator()) / quorumDenominator();
    }

    function updateQuorumNumerator(uint256 newQuorumNumerator) external virtual onlyGovernance {
        _updateQuorumNumerator(newQuorumNumerator);
    }

    function _updateQuorumNumerator(uint256 newQuorumNumerator) internal virtual {
        require(
            newQuorumNumerator <= quorumDenominator(),
            "GovernorVotesQuorumFraction: quorumNumerator over quorumDenominator"
        );

        uint256 oldQuorumNumerator = _quorumNumerator;
        _quorumNumerator = newQuorumNumerator;

        emit QuorumNumeratorUpdated(oldQuorumNumerator, newQuorumNumerator);
    }
    uint256[49] private __gap;
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.0 (governance/extensions/GovernorTimelockControl.sol)

pragma solidity ^0.8.0;

import "./IGovernorTimelockUpgradeable.sol";
import "../GovernorUpgradeable.sol";
import "../TimelockControllerUpgradeable.sol";
import "../../proxy/utils/Initializable.sol";

/**
 * @dev Extension of {Governor} that binds the execution process to an instance of {TimelockController}. This adds a
 * delay, enforced by the {TimelockController} to all successful proposal (in addition to the voting duration). The
 * {Governor} needs the proposer (an ideally the executor) roles for the {Governor} to work properly.
 *
 * Using this model means the proposal will be operated by the {TimelockController} and not by the {Governor}. Thus,
 * the assets and permissions must be attached to the {TimelockController}. Any asset sent to the {Governor} will be
 * inaccessible.
 *
 * _Available since v4.3._
 */
abstract contract GovernorTimelockControlUpgradeable is Initializable, IGovernorTimelockUpgradeable, GovernorUpgradeable {
    TimelockControllerUpgradeable private _timelock;
    mapping(uint256 => bytes32) private _timelockIds;

    /**
     * @dev Emitted when the timelock controller used for proposal execution is modified.
     */
    event TimelockChange(address oldTimelock, address newTimelock);

    /**
     * @dev Set the timelock.
     */
    function __GovernorTimelockControl_init(TimelockControllerUpgradeable timelockAddress) internal initializer {
        __Context_init_unchained();
        __ERC165_init_unchained();
        __IGovernor_init_unchained();
        __IGovernorTimelock_init_unchained();
        __GovernorTimelockControl_init_unchained(timelockAddress);
    }

    function __GovernorTimelockControl_init_unchained(TimelockControllerUpgradeable timelockAddress) internal initializer {
        _updateTimelock(timelockAddress);
    }

    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId) public view virtual override(IERC165Upgradeable, GovernorUpgradeable) returns (bool) {
        return interfaceId == type(IGovernorTimelockUpgradeable).interfaceId || super.supportsInterface(interfaceId);
    }

    /**
     * @dev Overriden version of the {Governor-state} function with added support for the `Queued` status.
     */
    function state(uint256 proposalId) public view virtual override(IGovernorUpgradeable, GovernorUpgradeable) returns (ProposalState) {
        ProposalState status = super.state(proposalId);

        if (status != ProposalState.Succeeded) {
            return status;
        }

        // core tracks execution, so we just have to check if successful proposal have been queued.
        bytes32 queueid = _timelockIds[proposalId];
        if (queueid == bytes32(0)) {
            return status;
        } else if (_timelock.isOperationDone(queueid)) {
            return ProposalState.Executed;
        } else {
            return ProposalState.Queued;
        }
    }

    /**
     * @dev Public accessor to check the address of the timelock
     */
    function timelock() public view virtual override returns (address) {
        return address(_timelock);
    }

    /**
     * @dev Public accessor to check the eta of a queued proposal
     */
    function proposalEta(uint256 proposalId) public view virtual override returns (uint256) {
        uint256 eta = _timelock.getTimestamp(_timelockIds[proposalId]);
        return eta == 1 ? 0 : eta; // _DONE_TIMESTAMP (1) should be replaced with a 0 value
    }

    /**
     * @dev Function to queue a proposal to the timelock.
     */
    function queue(
        address[] memory targets,
        uint256[] memory values,
        bytes[] memory calldatas,
        bytes32 descriptionHash
    ) public virtual override returns (uint256) {
        uint256 proposalId = hashProposal(targets, values, calldatas, descriptionHash);

        require(state(proposalId) == ProposalState.Succeeded, "Governor: proposal not successful");

        uint256 delay = _timelock.getMinDelay();
        _timelockIds[proposalId] = _timelock.hashOperationBatch(targets, values, calldatas, 0, descriptionHash);
        _timelock.scheduleBatch(targets, values, calldatas, 0, descriptionHash, delay);

        emit ProposalQueued(proposalId, block.timestamp + delay);

        return proposalId;
    }

    /**
     * @dev Overriden execute function that run the already queued proposal through the timelock.
     */
    function _execute(
        uint256, /* proposalId */
        address[] memory targets,
        uint256[] memory values,
        bytes[] memory calldatas,
        bytes32 descriptionHash
    ) internal virtual override {
        _timelock.executeBatch{value: msg.value}(targets, values, calldatas, 0, descriptionHash);
    }

    /**
     * @dev Overriden version of the {Governor-_cancel} function to cancel the timelocked proposal if it as already
     * been queued.
     */
    function _cancel(
        address[] memory targets,
        uint256[] memory values,
        bytes[] memory calldatas,
        bytes32 descriptionHash
    ) internal virtual override returns (uint256) {
        uint256 proposalId = super._cancel(targets, values, calldatas, descriptionHash);

        if (_timelockIds[proposalId] != 0) {
            _timelock.cancel(_timelockIds[proposalId]);
            delete _timelockIds[proposalId];
        }

        return proposalId;
    }

    /**
     * @dev Address through which the governor executes action. In this case, the timelock.
     */
    function _executor() internal view virtual override returns (address) {
        return address(_timelock);
    }

    /**
     * @dev Public endpoint to update the underlying timelock instance. Restricted to the timelock itself, so updates
     * must be proposed, scheduled and executed using the {Governor} workflow.
     */
    function updateTimelock(TimelockControllerUpgradeable newTimelock) external virtual onlyGovernance {
        _updateTimelock(newTimelock);
    }

    function _updateTimelock(TimelockControllerUpgradeable newTimelock) private {
        emit TimelockChange(address(_timelock), address(newTimelock));
        _timelock = newTimelock;
    }
    uint256[48] private __gap;
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

interface IHashtagNFTCollectiveGovernor{
    function requestClaimRoyalty(address receiver, uint256 amount, string calldata description) external returns(uint256);
    function requestSetBuyOutPrice(uint256 amount, string calldata description) external returns(uint256);
    function requestSetLicense(string calldata licenceURI, string calldata description) external returns(uint256);
    function requestLendAssets(uint256 timeOutBlockTime, address newOwnerAddress, uint256 amountOfERC20Request, address addressERC20, address assetAddress, string calldata description) external returns(uint256);
    function requestRetrieveAsset(address assetAddress, address oldOwnerAddress, address newOwnerAddress, string calldata description) external returns (uint256);
    function requestBuyout(uint256 buyoutFee, string calldata description) external payable returns(uint256);
    function requestSetProposalThreshold(uint256 newProposalThreshold, string calldata description) external returns(uint256);
    function refundBuyoutFee(uint256 proposalId) external;
    function cancelProposal(address[] memory targets,uint256[] memory values, bytes[] memory calldatas,bytes32 descriptionHash) external returns(uint256);
    function HashtagNFTCollectiveManager() external returns (address);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.0 (utils/Timers.sol)

pragma solidity ^0.8.0;

/**
 * @dev Tooling for timepoints, timers and delays
 */
library TimersUpgradeable {
    struct Timestamp {
        uint64 _deadline;
    }

    function getDeadline(Timestamp memory timer) internal pure returns (uint64) {
        return timer._deadline;
    }

    function setDeadline(Timestamp storage timer, uint64 timestamp) internal {
        timer._deadline = timestamp;
    }

    function reset(Timestamp storage timer) internal {
        timer._deadline = 0;
    }

    function isUnset(Timestamp memory timer) internal pure returns (bool) {
        return timer._deadline == 0;
    }

    function isStarted(Timestamp memory timer) internal pure returns (bool) {
        return timer._deadline > 0;
    }

    function isPending(Timestamp memory timer) internal view returns (bool) {
        return timer._deadline > block.timestamp;
    }

    function isExpired(Timestamp memory timer) internal view returns (bool) {
        return isStarted(timer) && timer._deadline <= block.timestamp;
    }

    struct BlockNumber {
        uint64 _deadline;
    }

    function getDeadline(BlockNumber memory timer) internal pure returns (uint64) {
        return timer._deadline;
    }

    function setDeadline(BlockNumber storage timer, uint64 timestamp) internal {
        timer._deadline = timestamp;
    }

    function reset(BlockNumber storage timer) internal {
        timer._deadline = 0;
    }

    function isUnset(BlockNumber memory timer) internal pure returns (bool) {
        return timer._deadline == 0;
    }

    function isStarted(BlockNumber memory timer) internal pure returns (bool) {
        return timer._deadline > 0;
    }

    function isPending(BlockNumber memory timer) internal view returns (bool) {
        return timer._deadline > block.number;
    }

    function isExpired(BlockNumber memory timer) internal view returns (bool) {
        return isStarted(timer) && timer._deadline <= block.number;
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.0 (governance/extensions/IGovernorTimelock.sol)

pragma solidity ^0.8.0;

import "../IGovernorUpgradeable.sol";
import "../../proxy/utils/Initializable.sol";

/**
 * @dev Extension of the {IGovernor} for timelock supporting modules.
 *
 * _Available since v4.3._
 */
abstract contract IGovernorTimelockUpgradeable is Initializable, IGovernorUpgradeable {
    function __IGovernorTimelock_init() internal initializer {
        __IGovernor_init_unchained();
        __IGovernorTimelock_init_unchained();
    }

    function __IGovernorTimelock_init_unchained() internal initializer {
    }
    event ProposalQueued(uint256 proposalId, uint256 eta);

    function timelock() public view virtual returns (address);

    function proposalEta(uint256 proposalId) public view virtual returns (uint256);

    function queue(
        address[] memory targets,
        uint256[] memory values,
        bytes[] memory calldatas,
        bytes32 descriptionHash
    ) public virtual returns (uint256 proposalId);
    uint256[50] private __gap;
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.0 (governance/TimelockController.sol)

pragma solidity ^0.8.0;

import "../access/AccessControlUpgradeable.sol";
import "../proxy/utils/Initializable.sol";

/**
 * @dev Contract module which acts as a timelocked controller. When set as the
 * owner of an `Ownable` smart contract, it enforces a timelock on all
 * `onlyOwner` maintenance operations. This gives time for users of the
 * controlled contract to exit before a potentially dangerous maintenance
 * operation is applied.
 *
 * By default, this contract is self administered, meaning administration tasks
 * have to go through the timelock process. The proposer (resp executor) role
 * is in charge of proposing (resp executing) operations. A common use case is
 * to position this {TimelockController} as the owner of a smart contract, with
 * a multisig or a DAO as the sole proposer.
 *
 * _Available since v3.3._
 */
contract TimelockControllerUpgradeable is Initializable, AccessControlUpgradeable {
    bytes32 public constant TIMELOCK_ADMIN_ROLE = keccak256("TIMELOCK_ADMIN_ROLE");
    bytes32 public constant PROPOSER_ROLE = keccak256("PROPOSER_ROLE");
    bytes32 public constant EXECUTOR_ROLE = keccak256("EXECUTOR_ROLE");
    uint256 internal constant _DONE_TIMESTAMP = uint256(1);

    mapping(bytes32 => uint256) private _timestamps;
    uint256 private _minDelay;

    /**
     * @dev Emitted when a call is scheduled as part of operation `id`.
     */
    event CallScheduled(
        bytes32 indexed id,
        uint256 indexed index,
        address target,
        uint256 value,
        bytes data,
        bytes32 predecessor,
        uint256 delay
    );

    /**
     * @dev Emitted when a call is performed as part of operation `id`.
     */
    event CallExecuted(bytes32 indexed id, uint256 indexed index, address target, uint256 value, bytes data);

    /**
     * @dev Emitted when operation `id` is cancelled.
     */
    event Cancelled(bytes32 indexed id);

    /**
     * @dev Emitted when the minimum delay for future operations is modified.
     */
    event MinDelayChange(uint256 oldDuration, uint256 newDuration);

    /**
     * @dev Initializes the contract with a given `minDelay`.
     */
    function __TimelockController_init(
        uint256 minDelay,
        address[] memory proposers,
        address[] memory executors
    ) internal initializer {
        __Context_init_unchained();
        __ERC165_init_unchained();
        __AccessControl_init_unchained();
        __TimelockController_init_unchained(minDelay, proposers, executors);
    }

    function __TimelockController_init_unchained(
        uint256 minDelay,
        address[] memory proposers,
        address[] memory executors
    ) internal initializer {
        _setRoleAdmin(TIMELOCK_ADMIN_ROLE, TIMELOCK_ADMIN_ROLE);
        _setRoleAdmin(PROPOSER_ROLE, TIMELOCK_ADMIN_ROLE);
        _setRoleAdmin(EXECUTOR_ROLE, TIMELOCK_ADMIN_ROLE);

        // deployer + self administration
        _setupRole(TIMELOCK_ADMIN_ROLE, _msgSender());
        _setupRole(TIMELOCK_ADMIN_ROLE, address(this));

        // register proposers
        for (uint256 i = 0; i < proposers.length; ++i) {
            _setupRole(PROPOSER_ROLE, proposers[i]);
        }

        // register executors
        for (uint256 i = 0; i < executors.length; ++i) {
            _setupRole(EXECUTOR_ROLE, executors[i]);
        }

        _minDelay = minDelay;
        emit MinDelayChange(0, minDelay);
    }

    /**
     * @dev Modifier to make a function callable only by a certain role. In
     * addition to checking the sender's role, `address(0)` 's role is also
     * considered. Granting a role to `address(0)` is equivalent to enabling
     * this role for everyone.
     */
    modifier onlyRoleOrOpenRole(bytes32 role) {
        if (!hasRole(role, address(0))) {
            _checkRole(role, _msgSender());
        }
        _;
    }

    /**
     * @dev Contract might receive/hold ETH as part of the maintenance process.
     */
    receive() external payable {}

    /**
     * @dev Returns whether an id correspond to a registered operation. This
     * includes both Pending, Ready and Done operations.
     */
    function isOperation(bytes32 id) public view virtual returns (bool pending) {
        return getTimestamp(id) > 0;
    }

    /**
     * @dev Returns whether an operation is pending or not.
     */
    function isOperationPending(bytes32 id) public view virtual returns (bool pending) {
        return getTimestamp(id) > _DONE_TIMESTAMP;
    }

    /**
     * @dev Returns whether an operation is ready or not.
     */
    function isOperationReady(bytes32 id) public view virtual returns (bool ready) {
        uint256 timestamp = getTimestamp(id);
        return timestamp > _DONE_TIMESTAMP && timestamp <= block.timestamp;
    }

    /**
     * @dev Returns whether an operation is done or not.
     */
    function isOperationDone(bytes32 id) public view virtual returns (bool done) {
        return getTimestamp(id) == _DONE_TIMESTAMP;
    }

    /**
     * @dev Returns the timestamp at with an operation becomes ready (0 for
     * unset operations, 1 for done operations).
     */
    function getTimestamp(bytes32 id) public view virtual returns (uint256 timestamp) {
        return _timestamps[id];
    }

    /**
     * @dev Returns the minimum delay for an operation to become valid.
     *
     * This value can be changed by executing an operation that calls `updateDelay`.
     */
    function getMinDelay() public view virtual returns (uint256 duration) {
        return _minDelay;
    }

    /**
     * @dev Returns the identifier of an operation containing a single
     * transaction.
     */
    function hashOperation(
        address target,
        uint256 value,
        bytes calldata data,
        bytes32 predecessor,
        bytes32 salt
    ) public pure virtual returns (bytes32 hash) {
        return keccak256(abi.encode(target, value, data, predecessor, salt));
    }

    /**
     * @dev Returns the identifier of an operation containing a batch of
     * transactions.
     */
    function hashOperationBatch(
        address[] calldata targets,
        uint256[] calldata values,
        bytes[] calldata datas,
        bytes32 predecessor,
        bytes32 salt
    ) public pure virtual returns (bytes32 hash) {
        return keccak256(abi.encode(targets, values, datas, predecessor, salt));
    }

    /**
     * @dev Schedule an operation containing a single transaction.
     *
     * Emits a {CallScheduled} event.
     *
     * Requirements:
     *
     * - the caller must have the 'proposer' role.
     */
    function schedule(
        address target,
        uint256 value,
        bytes calldata data,
        bytes32 predecessor,
        bytes32 salt,
        uint256 delay
    ) public virtual onlyRole(PROPOSER_ROLE) {
        bytes32 id = hashOperation(target, value, data, predecessor, salt);
        _schedule(id, delay);
        emit CallScheduled(id, 0, target, value, data, predecessor, delay);
    }

    /**
     * @dev Schedule an operation containing a batch of transactions.
     *
     * Emits one {CallScheduled} event per transaction in the batch.
     *
     * Requirements:
     *
     * - the caller must have the 'proposer' role.
     */
    function scheduleBatch(
        address[] calldata targets,
        uint256[] calldata values,
        bytes[] calldata datas,
        bytes32 predecessor,
        bytes32 salt,
        uint256 delay
    ) public virtual onlyRole(PROPOSER_ROLE) {
        require(targets.length == values.length, "TimelockController: length mismatch");
        require(targets.length == datas.length, "TimelockController: length mismatch");

        bytes32 id = hashOperationBatch(targets, values, datas, predecessor, salt);
        _schedule(id, delay);
        for (uint256 i = 0; i < targets.length; ++i) {
            emit CallScheduled(id, i, targets[i], values[i], datas[i], predecessor, delay);
        }
    }

    /**
     * @dev Schedule an operation that is to becomes valid after a given delay.
     */
    function _schedule(bytes32 id, uint256 delay) private {
        require(!isOperation(id), "TimelockController: operation already scheduled");
        require(delay >= getMinDelay(), "TimelockController: insufficient delay");
        _timestamps[id] = block.timestamp + delay;
    }

    /**
     * @dev Cancel an operation.
     *
     * Requirements:
     *
     * - the caller must have the 'proposer' role.
     */
    function cancel(bytes32 id) public virtual onlyRole(PROPOSER_ROLE) {
        require(isOperationPending(id), "TimelockController: operation cannot be cancelled");
        delete _timestamps[id];

        emit Cancelled(id);
    }

    /**
     * @dev Execute an (ready) operation containing a single transaction.
     *
     * Emits a {CallExecuted} event.
     *
     * Requirements:
     *
     * - the caller must have the 'executor' role.
     */
    function execute(
        address target,
        uint256 value,
        bytes calldata data,
        bytes32 predecessor,
        bytes32 salt
    ) public payable virtual onlyRoleOrOpenRole(EXECUTOR_ROLE) {
        bytes32 id = hashOperation(target, value, data, predecessor, salt);
        _beforeCall(id, predecessor);
        _call(id, 0, target, value, data);
        _afterCall(id);
    }

    /**
     * @dev Execute an (ready) operation containing a batch of transactions.
     *
     * Emits one {CallExecuted} event per transaction in the batch.
     *
     * Requirements:
     *
     * - the caller must have the 'executor' role.
     */
    function executeBatch(
        address[] calldata targets,
        uint256[] calldata values,
        bytes[] calldata datas,
        bytes32 predecessor,
        bytes32 salt
    ) public payable virtual onlyRoleOrOpenRole(EXECUTOR_ROLE) {
        require(targets.length == values.length, "TimelockController: length mismatch");
        require(targets.length == datas.length, "TimelockController: length mismatch");

        bytes32 id = hashOperationBatch(targets, values, datas, predecessor, salt);
        _beforeCall(id, predecessor);
        for (uint256 i = 0; i < targets.length; ++i) {
            _call(id, i, targets[i], values[i], datas[i]);
        }
        _afterCall(id);
    }

    /**
     * @dev Checks before execution of an operation's calls.
     */
    function _beforeCall(bytes32 id, bytes32 predecessor) private view {
        require(isOperationReady(id), "TimelockController: operation is not ready");
        require(predecessor == bytes32(0) || isOperationDone(predecessor), "TimelockController: missing dependency");
    }

    /**
     * @dev Checks after execution of an operation's calls.
     */
    function _afterCall(bytes32 id) private {
        require(isOperationReady(id), "TimelockController: operation is not ready");
        _timestamps[id] = _DONE_TIMESTAMP;
    }

    /**
     * @dev Execute an operation's call.
     *
     * Emits a {CallExecuted} event.
     */
    function _call(
        bytes32 id,
        uint256 index,
        address target,
        uint256 value,
        bytes calldata data
    ) private {
        (bool success, ) = target.call{value: value}(data);
        require(success, "TimelockController: underlying transaction reverted");

        emit CallExecuted(id, index, target, value, data);
    }

    /**
     * @dev Changes the minimum timelock duration for future operations.
     *
     * Emits a {MinDelayChange} event.
     *
     * Requirements:
     *
     * - the caller must be the timelock itself. This can only be achieved by scheduling and later executing
     * an operation where the timelock is the target and the data is the ABI-encoded call to this function.
     */
    function updateDelay(uint256 newDelay) external virtual {
        require(msg.sender == address(this), "TimelockController: caller must be timelock");
        emit MinDelayChange(_minDelay, newDelay);
        _minDelay = newDelay;
    }
    uint256[48] private __gap;
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.0 (access/AccessControl.sol)

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
    function __AccessControl_init() internal initializer {
        __Context_init_unchained();
        __ERC165_init_unchained();
        __AccessControl_init_unchained();
    }

    function __AccessControl_init_unchained() internal initializer {
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
    function hasRole(bytes32 role, address account) public view override returns (bool) {
        return _roles[role].members[account];
    }

    /**
     * @dev Revert with a standard message if `account` is missing `role`.
     *
     * The format of the revert reason is given by the following regular expression:
     *
     *  /^AccessControl: account (0x[0-9a-f]{40}) is missing role (0x[0-9a-f]{64})$/
     */
    function _checkRole(bytes32 role, address account) internal view {
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
    uint256[49] private __gap;
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.0 (access/IAccessControl.sol)

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