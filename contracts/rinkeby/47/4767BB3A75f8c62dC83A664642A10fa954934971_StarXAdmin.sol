// SPDX-License-Identifier: MIT

pragma solidity ^0.8.4;

import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import "./interfaces/IRequest.sol";
import "./StarXManaged.sol";

contract StarXAdmin is OwnableUpgradeable, IRequest, StarXManaged {
    /// @notice StarX1155Factory contract
    address public starX1155FactoryAddress;

    /// @notice StarXAuction contract
    address public auctionAddress;

    /// @notice StarXMarketplace contract
    address public marketplaceAddress;

    /// @notice StarXBundleMarketplace contract
    address public bundleMarketplaceAddress;

    // TODO: doc
    address public celebrityRegistryAddress;

    // Auction updated event
    event AuctionUpdated(
        address indexed previousAuction,
        address indexed newAuction
    );

    // Marketplace updated event
    event MarketplaceUpdated(
        address indexed previousMarketplace,
        address indexed newMarketplace
    );

    // BundleMarketplace updated event
    event BundleMarketplaceUpdated(
        address indexed previousBundleMarketplace,
        address indexed newBundleMarketplace
    );

    event StarX1155FactoryUpdated(
        address indexed previousStarX1155Factory,
        address indexed newStarX1155Factory
    );

    event StarXCelebrityRegistryUpdated(
        address indexed oldStarXCelebrityRegistryUpdated,
        address indexed newStarXCelebrityRegistryUpdated
    );

    event CreateAndMint1155Token(
        address indexed creator,
        string contractName,
        address indexed nft,
        uint256 tokenId,
        address tokenOwner
    );

    // token contract created, nft minted and listing
    event CreateMintAndListForBuy1155Token(
        uint256 indexed marketId,
        address indexed owner,
        address indexed nft,
        uint256 tokenId,
        uint256 quantity,
        string currency,
        uint256 pricePerItem,
        uint256 startingTime
    );

    event CreateMintAndListForAuction1155Token(
        uint256 indexed auctionId,
        address indexed nftAddress,
        uint256 indexed tokenId,
        uint256 quantity
    );

    event ListBundleForBuy(
        address indexed bundleSellerAddres,
        string bundleID,
        address[] nftContractAddresses,
        uint256[] tokenIds,
        uint256[] quantitiesToBeSold,
        uint256 bundleSellPrice,
        uint256 startingTimeInEpochSeconds
    );

    // TODO: doc
    event NewCelebContractDeployed(
        address indexed celebWallet,
        address indexed newCelebContract,
        uint256 newCelebContractCount
    );
    // TODO: doc
    event NewCelebAssetContractDeployed(
        address indexed celebContract,
        address indexed newAssetContract,
        string indexed assetName,
        string assetSymbol,
        string assetDescription,
        address starXCustodyWallet
    );
    // TODO: doc
    event NewTokenForCelebAssetContract(
        address indexed celebContract,
        address indexed celebAssetContract,
        uint256 indexed newTokenId,
        uint256 tokenInitialPrice,
        uint256 tokenSupply,
        IRequest.AssetType tokenAssetType,
        address tokenCreator,
        uint16 tokenHolderRoyaltyBps,
        bytes32 tokenHashedInvestmentContractUri
    );

    /// @notice Contract initializer
    function initialize(
        address _starX1155FactoryAddress,
        address _auctionAddress,
        address _marketplaceAddress,
        address _bundleMarketplaceAddress,
        address _celebrityRegistryAddress
    ) public initializer {
        auctionAddress = _auctionAddress;
        marketplaceAddress = _marketplaceAddress;
        starX1155FactoryAddress = _starX1155FactoryAddress;
        bundleMarketplaceAddress = _bundleMarketplaceAddress;
        celebrityRegistryAddress = _celebrityRegistryAddress;

        __Ownable_init();
    }

    /**
     * @notice Update auction contract
     * @dev Only admin
     * @param _auction address the auction contract address to set
     */
    function updateAuction(address _auction) external onlyOwner {
        emit AuctionUpdated(auctionAddress, _auction);
        auctionAddress = _auction;
    }

    /**
     * @notice Update marketplace contract
     * @dev Only admin
     * @param _marketplace address the marketplace contract address to set
     */
    function updateMarketplace(address _marketplace) external onlyOwner {
        emit MarketplaceUpdated(marketplaceAddress, _marketplace);
        marketplaceAddress = _marketplace;
    }

    /**
     * @notice Update bundle marketplace contract
     * @dev Only admin
     * @param _bundleMarketplace address the bundle marketplace contract address to set
     */
    function updateBundleMarketplace(address _bundleMarketplace)
        external
        onlyOwner
    {
        emit BundleMarketplaceUpdated(
            bundleMarketplaceAddress,
            _bundleMarketplace
        );
        bundleMarketplaceAddress = _bundleMarketplace;
    }

    function updateCelebrityRegistryAddress(address _celebrityRegistryAddress)
        external
        onlyOwner
    {
        emit StarXCelebrityRegistryUpdated(
            celebrityRegistryAddress,
            _celebrityRegistryAddress
        );
        celebrityRegistryAddress = _celebrityRegistryAddress;
    }

    function updateStarX1155Factory(address _starX1155Factory)
        external
        onlyOwner
    {
        emit StarX1155FactoryUpdated(
            starX1155FactoryAddress,
            _starX1155Factory
        );
        starX1155FactoryAddress = _starX1155Factory;
    }

    function createAndMint1155Token(CreateAndMint1155Request memory mintInfo)
        external
        payable
        starXOnly
        returns (address, uint256)
    {
        IStarX1155Factory factory = IStarX1155Factory(starX1155FactoryAddress);
        address contract_address = factory.createNFTContract(
            mintInfo._name,
            mintInfo._symbol,
            mintInfo._description
        );
        IStarX1155Tradable nft = IStarX1155Tradable(contract_address);
        nft.transferOwnership(mintInfo._owner);
        uint256 tokenId = nft.mint(
            mintInfo._owner,
            mintInfo._supply,
            mintInfo._uri,
            mintInfo._creatorRoyaltyRecipient,
            mintInfo._creatorRoyaltyValue,
            mintInfo._holderRoyaltyValue
        );
        emit CreateAndMint1155Token(
            _msgSender(),
            mintInfo._name,
            contract_address,
            tokenId,
            mintInfo._owner
        );
        return (contract_address, tokenId);
    }

    function createMintAndListForBuy1155Token(
        CreateAndMint1155Request memory mintInfo,
        MarketplaceListRequest memory marketplaceInfo
    )
        external
        payable
        starXOnly
        returns (
            address contract_address,
            uint256 tokenId,
            uint256 listingId
        )
    {
        (contract_address, tokenId) = this.createAndMint1155Token(mintInfo);

        listingId = IStarXMarketplace(marketplaceAddress).listItemByAdmin(
            ListItemRequest({
                _nftOwner: mintInfo._owner,
                _nftAddress: contract_address,
                _tokenId: tokenId,
                _quantity: marketplaceInfo._quantity,
                _currency: marketplaceInfo._currency,
                _pricePerItem: marketplaceInfo._pricePerItem,
                _startingTime: marketplaceInfo._startingTime
            })
        );

        emit CreateMintAndListForBuy1155Token(
            listingId,
            mintInfo._owner,
            contract_address,
            tokenId,
            marketplaceInfo._quantity,
            marketplaceInfo._currency,
            marketplaceInfo._pricePerItem,
            marketplaceInfo._startingTime
        );
    }

    function createMintAndListForAuction1155Token(
        CreateAndMint1155Request memory mintInfo,
        AuctionListRequest memory auctionInfo
    )
        external
        payable
        starXOnly
        returns (
            address,
            uint256,
            uint256
        )
    {
        (address contract_address, uint256 tokenId) = this
            .createAndMint1155Token(mintInfo);
        IStarXAuction auction = IStarXAuction(auctionAddress);
        uint256 auctionId = auction.createAuctionByAdmin(
            mintInfo._owner,
            contract_address,
            tokenId,
            auctionInfo
        );
        emit CreateMintAndListForAuction1155Token(
            auctionId,
            contract_address,
            tokenId,
            auctionInfo._quantity
        );
        return (contract_address, tokenId, auctionId);
    }

    /**
     * @notice List bundle for buy
     */
    function listBundleForBuy(IRequest.BundleListItemRequest memory request)
        external
        starXOnly
    {
        IStarXBundleMarketplace(bundleMarketplaceAddress).listBundleByAdmin(
            BundleListItemRequest({
                _bundleOwner: request._bundleOwner,
                _bundleID: request._bundleID,
                _nftAddresses: request._nftAddresses,
                _tokenIds: request._tokenIds,
                _quantities: request._quantities,
                _currency: request._currency,
                _price: request._price,
                _startingTime: request._startingTime
            })
        );

        emit ListBundleForBuy(
            request._bundleOwner,
            request._bundleID,
            request._nftAddresses,
            request._tokenIds,
            request._quantities,
            request._price,
            request._startingTime
        );
    }

    // TODO: fn doc
    function deployNewCelebContract(
        address _celebWallet,
        address _starXAddressRegistry
    )
        external
        returns (address celebContractAddress, uint256 celebContractCount)
    {
        // call
        (celebContractAddress, celebContractCount) = IStarXCelebrityRegistry(
            celebrityRegistryAddress
        ).addCelebContract(_celebWallet, _starXAddressRegistry);

        // emit event
        emit NewCelebContractDeployed(
            _celebWallet,
            celebContractAddress,
            celebContractCount
        );
    }

    // TODO: fn doc
    function deployNewAssetContractForCelebContract(
        address _celebrityContractAddress,
        IRequest.DeployAssetContractRequest calldata _req
    ) external {
        // call
        address newAssetContractAddress = IStarXCelebrityRegistry(
            celebrityRegistryAddress
        ).deployAssetContractForCelebrity(_celebrityContractAddress, _req);

        // emit event
        emit NewCelebAssetContractDeployed(
            _celebrityContractAddress,
            newAssetContractAddress,
            _req.assetName,
            _req.assetSymbol,
            _req.assetDescription,
            _req.custodyWallet
        );
    }

    // TODO: fn doc
    function mintNewSecurityForCelebAndAssetContract(
        address _celebContractAddress,
        address _celebAssetAddress,
        IRequest.ListAssetRequest calldata _req
    ) external returns (uint256 newTokenId) {
        newTokenId = IStarXCelebrityRegistry(celebrityRegistryAddress)
            .mintNewSecurityForCelebAndAssetContract(
                _celebContractAddress,
                _celebAssetAddress,
                _req
            );
        // emit event
        emit NewTokenForCelebAssetContract(
            _celebContractAddress,
            _celebAssetAddress,
            newTokenId,
            _req.initialOfferingPrice,
            _req.supply,
            _req.assetType,
            _req.creator,
            _req.holderRoyaltyBps,
            _req.hashedInvestmentContractUri
        );
    }
}

interface IStarX1155Factory {
    function createNFTContract(
        string memory _name,
        string memory _symbol,
        string memory _description
    ) external payable returns (address);
}

interface IStarX1155Tradable {
    function mint(
        address _to,
        uint256 _supply,
        string calldata _uri,
        address _creatorRoyaltyRecipient,
        uint16 _creatorRoyaltyValue,
        uint16 _holderRoyaltyValue
    ) external payable returns (uint256);

    function transferOwnership(address newOwner) external;
}

interface IStarXMarketplace {
    function defaultHighestRoyaltyFee() external view returns (uint256);

    function listItemByAdmin(IRequest.ListItemRequest calldata request)
        external
        returns (uint256);
}

interface IStarXAuction is IRequest {
    function createAuctionByAdmin(
        address _owner,
        address _nftAddress,
        uint256 _tokenId,
        AuctionListRequest memory auctionInfo
    ) external returns (uint256);
}

interface IStarXBundleMarketplace {
    function listBundleByAdmin(IRequest.BundleListItemRequest calldata request)
        external;
}

interface IStarXCelebrityRegistry {
    function addCelebContract(
        address _celebWallet,
        address _starXAddressRegistry
    ) external returns (address, uint256);

    function deployAssetContractForCelebrity(
        address _celebrityContractAddress,
        IRequest.DeployAssetContractRequest calldata _req
    ) external returns (address);

    function mintNewSecurityForCelebAndAssetContract(
        address _celebContract,
        address _celebAssetContract,
        IRequest.ListAssetRequest calldata _req
    ) external returns (uint256);
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

pragma solidity ^0.8.4;

interface IRequest {
    // struct for createAndListForBuyNFT, avoid Stack too deep
    /**
     * @param supply The supply of certain token id
     * @param tokenUri Token url.
     * @param royaltyRecipient Recipient of the royalties.
     * @param royaltyValue percentage (using 2 decimals - 10000 = 100, 0 = 0)
     * @param payToken Paying token (address(0) stands for ether, otherwise ERC20 token)
     * @param pricePerItem sale price for each item
     * @param startingTime scheduling for a future sale
     */
    struct CreateAndListForBuyRequest {
        uint256 supply;
        string tokenUri;
        address royaltyRecipient;
        uint16 royaltyValue;
        address payToken;
        uint256 pricePerItem;
        uint256 startingTime;
    }

    // struct for createAndListForAuctionNFT, avoid Stack too deep
    /**
     * @param supply The supply of certain token id
     * @param tokenUri Token url.
     * @param royaltyRecipient Recipient of the royalties.
     * @param royaltyValue percentage (using 2 decimals - 10000 = 100, 0 = 0)
     * @param payToken Paying token
     * @param reservePrice Item cannot be sold for less than this or minBidIncrement, whichever is higher
     * @param startTimestamp Unix epoch in seconds for the auction start time
     * @param minBidReserve If true set a minimum starting price as reserve price
     * @param endTimestamp Unix epoch in seconds for the auction end time.
     */
    struct CreateAndAuctionRequest {
        uint256 supply;
        string tokenUri;
        address royaltyRecipient;
        uint16 royaltyValue;
        address payToken;
        uint256 reservePrice;
        uint256 startTimestamp;
        bool minBidReserve;
        uint256 endTimestamp;
    }

    struct CreateAndMint1155Request {
        string _name;
        string _symbol;
        string _description;
        string _uri;
        uint256 _supply;
        address _creatorRoyaltyRecipient;
        uint16 _creatorRoyaltyValue;
        uint16 _holderRoyaltyValue;
        address _owner;
    }

    struct MarketplaceListRequest {
        uint256 _quantity;
        string _currency;
        uint256 _pricePerItem;
        uint256 _startingTime;
    }

    struct AuctionListRequest {
        uint256 _quantity;
        address _payToken;
        uint256 _reservePrice;
        uint256 _startTimestamp;
        bool minBidReserve;
        uint256 _endTimestamp;
    }

    struct TransferNftRequest {
        address _nftAddress;
        uint256 _tokenId;
        uint256 _listId;
        address _owner;
        address _buyer;
    }

    struct PaymentRecord {
        uint256 listId;
        uint256 marketId;
        address payer;
        address payee;
        string currency;
        string paymentAmount;
        uint256 paymentTime;
    }

    struct ListItemRequest {
        address _nftOwner;
        address _nftAddress;
        uint256 _tokenId;
        uint256 _quantity;
        string _currency;
        uint256 _pricePerItem;
        uint256 _startingTime;
    }

    // struct for StarXBundleMarketplace
    /**
     * @param _bundleOwner Bundle owner
     * @param _bundleID Bundle ID (Notice: bundle id must be unique)
     * @param _nftAddresses Addresses of NFT contract
     * @param _tokenIds Token IDs of NFT
     * @param _quantities token amounts to list (needed for ERC-1155 NFTs, set as 1 for ERC-721)
     * @param _price sale price for bundle
     * @param _startingTime scheduling for a future sale
     */
    struct BundleListItemRequest {
        address _bundleOwner;
        string _bundleID;
        address[] _nftAddresses;
        uint256[] _tokenIds;
        uint256[] _quantities;
        string _currency;
        uint256 _price;
        uint256 _startingTime;
    }

    struct TransferBundleRequest {
        string _bundleID;
        address _owner;
        address _buyer;
    }

    struct BundlePaymentRecord {
        string bundleId;
        address payer;
        address payee;
        string currency;
        string paymentAmount;
        uint256 paymentTime;
    }

    struct DeployAssetContractRequest {
        string assetName;
        string assetSymbol;
        string assetDescription;
        address custodyWallet;
    }

    enum AssetType {
        None,
        Equity,
        Debt,
        Nft
    }

    struct ListAssetRequest {
        uint256 initialOfferingPrice;
        uint256 supply;
        AssetType assetType;
        address creator;
        uint16 holderRoyaltyBps;
        bytes32 hashedInvestmentContractUri;
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.4;
import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
contract StarXManaged is OwnableUpgradeable {          

    mapping (address => bool) public managers;

    /**@dev Allows execution by managers only */
    modifier starXOnly {
        require(managers[msg.sender], "StarX only");
        _;
    }

    function setManager(address manager, bool state) public onlyOwner {
        managers[manager] = state;
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