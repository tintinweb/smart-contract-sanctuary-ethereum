// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.9;

import "@openzeppelin-4.7/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin-4.7/contracts/token/ERC721/extensions/ERC721Burnable.sol";
import "@openzeppelin-4.7/contracts/access/Ownable.sol";

import "./interfaces/IGashapondo.sol";
import "./interfaces/IRandomizer.sol";

contract Gashapondo is ERC721, ERC721Burnable, Ownable, IGashapondo {
    uint256 public constant ONE_MILLION = 1_000_000;
    bytes32 public constant COLLECTION_ADDED_NEW = keccak256("ADDED_NEW");
    bytes32 public constant COLLECTION_UPDATED_MINT_PRICES = keccak256("UPDATED_MINT_PRICES");
    bytes32 public constant COLLECTION_UPDATED_GAS_PRICE_IN_WEI = keccak256("UPDATED_GAS_PRICE_IN_WEI");
    bytes32 public constant COLLECTION_UPDATED_ERC20_GAS_PRICE_IN_WEI = keccak256("UPDATED_ERC20_GAS_PRICE_IN_WEI");
    bytes32 public constant COLLECTION_UPDATED_STATE = keccak256("UPDATED_STATE");
    bytes32 public constant COLLECTION_ADDED_PAYEES = keccak256("ADDED_PAYEES");
    bytes32 public constant COLLECTION_REMOVED_PAYEES = keccak256("REMOVED_PAYEES");
    bytes32 public constant COLLECTION_UPDATED_NAME = keccak256("UPDATED_NAME");
    bytes32 public constant COLLECTION_UPDATED_AUTHOR_ADDRESS = keccak256("UPDATED_AUTHOR_ADDRESS");
    bytes32 public constant COLLECTION_UPDATED_TOKEN_URI = keccak256("UPDATED_TOKEN_URI");
    bytes32 public constant COLLECTION_UPDATED_TOTAL_TOKENS = keccak256("UPDATED_TOTAL_TOKENS");
    bytes32 public constant COLLECTION_UPDATED_MAX_PURCHASE_PER_TX = keccak256("UPDATED_MAX_PURCHASE_PER_TX");
    bytes32 public constant COLLECTION_UPDATED_AUTHOR = keccak256("UPDATED_AUTHOR");
    bytes32 public constant COLLECTION_UPDATED_DESCRIPTION = keccak256("UPDATED_DESCRIPTION");
    bytes32 public constant COLLECTION_UPDATED_WEBSITE_URI = keccak256("UPDATED_WEBSITE_URI");
    bytes32 public constant COLLECTION_UPDATED_LICENSE = keccak256("UPDATED_LICENSE");
    bytes32 public constant COLLECTION_UPDATED_IMAGE_URI = keccak256("UPDATED_IMAGE_URI");
    bytes32 public constant COLLECTION_UPDATED_RANDOM_TOKEN_ID = keccak256("UPDATED_RANDOM_TOKEN_ID");
    bytes32 public constant PLATFORM_UPDATED_PRIMARY_SALES_PERCENTAGE = keccak256("UPDATED_PRIMARY_SALES_PERCENTAGE");

    IRandomizer public randomizerContract;

    mapping(address => bool) public admins;
    mapping(address => bool) public minters;

    uint256 public platformPrimarySalesPercentage = 10;
    address payable public platformPrimarySalesAddress;

    mapping(uint256 => bytes32) public tokenIdToHash;

    mapping(uint256 => Collection) private _collections;
    mapping(uint256 => CollectionMintPrice) private _collectionMintPrices;
    mapping(uint256 => CollectionPayment) private _collectionPayments;
    mapping(uint256 => mapping(uint256 => uint256)) private _tokenSlotInCollection;
    uint256 private _collectionCount;

    /**
     * @dev Throws if called by any account other than admins.
     */
    modifier onlyAdmin() {
        _requireAdmin();
        _;
    }

    /**
     * @dev Throws if called by any account other than minters.
     */
    modifier onlyMinter() {
        require(minters[_msgSender()], "Caller is not the minter");
        _;
    }

    /**
     * @dev Throws if called by any account other than author of the collection.
     */
    modifier onlyAuthor(uint256 collectionId) {
        _requireAuthor(collectionId);
        _;
    }

    /**
     * @dev Throws if called by any account other than author of the collection.
     */
    modifier onlyAuthorOrAdmin(uint256 collectionId) {
        require(
            _collections[collectionId].authorAddress == _msgSender() || admins[_msgSender()],
            "Author or admin required"
        );
        _;
    }

    /**
     * @dev Throws if invalid state
     */
    modifier whenNotInState(CollectionState state, uint256 collectionId) {
        require(_collections[collectionId].state != state, "Invalid state");
        _;
    }

    /**
     * @dev Throws if invalid state.
     */
    modifier whenInState(CollectionState state, uint256 collectionId) {
        require(_collections[collectionId].state == state, "Invalid state");
        _;
    }

    /**
     * @dev Throws if invalid
     */
    modifier validateWhenUpdateCollectionDetail(uint256 collectionId) {
        require(
            _collections[collectionId].authorAddress == _msgSender() || admins[_msgSender()],
            "Author or admin required"
        );
        CollectionState state = _collections[collectionId].state;
        if (state == CollectionState.DRAFT || state == CollectionState.LOCKED || state == CollectionState.COMPLETED) {
            _requireAdmin();
        }
        _;
    }

    constructor(address randomizer, address payable initialPlatformPrimarySalesAddress) ERC721("Gashapondo", "GASHA") {
        randomizerContract = IRandomizer(randomizer);
        _setPlatformPrimarySalesAddress(initialPlatformPrimarySalesAddress);
    }

    /** ----external functions - BEGIN-----*/

    function mint(address to, uint256 collectionId)
        external
        override
        onlyMinter
        whenInState(CollectionState.ACTIVE, collectionId)
        returns (uint256 tokenId)
    {
        // CHECKS
        require(_collections[collectionId].minted < _collections[collectionId].totalTokens, "All tokens were minted");

        // EFFECTS
        uint24 numberOfTokensAfterMinted = _collections[collectionId].minted + 1;
        if (numberOfTokensAfterMinted == _collections[collectionId].totalTokens) {
            _collections[collectionId].state = CollectionState.COMPLETED;
            _collections[collectionId].endDate = uint24(block.timestamp);
            emit CollectionUpdated(collectionId, COLLECTION_UPDATED_STATE);
        }

        // INTERACTIONS
        tokenId = _mintToken(to, collectionId);
    }

    function mintBatch(
        address to,
        uint256 collectionId,
        uint24 numberOfTokens
    )
        external
        override
        onlyMinter
        whenInState(CollectionState.ACTIVE, collectionId)
        returns (uint256[] memory tokenIds)
    {
        require(numberOfTokens > 0, "Number of tokens should be greater than 0");
        require(
            _collections[collectionId].minted + numberOfTokens <= _collections[collectionId].totalTokens,
            "Not enough tokens to mint"
        );
        require(
            numberOfTokens <= _collections[collectionId].maxPurchasePerTx,
            "Exceed number of tokens allowed for each purchase"
        );

        // EFFECTS
        uint24 numberOfTokensAfterMinted = _collections[collectionId].minted + numberOfTokens;
        if (numberOfTokensAfterMinted == _collections[collectionId].totalTokens) {
            _collections[collectionId].state = CollectionState.COMPLETED;
            _collections[collectionId].endDate = uint24(block.timestamp);
            emit CollectionUpdated(collectionId, COLLECTION_UPDATED_STATE);
        }

        // INTERACTIONS
        tokenIds = new uint256[](numberOfTokens);
        for (uint256 i = 0; i < numberOfTokens; i++) {
            tokenIds[i] = _mintToken(to, collectionId);
        }
    }

    function setRandomizer(address randomizer) external onlyOwner {
        randomizerContract = IRandomizer(randomizer);
    }

    function setPlatformPrimarySalesAddress(address payable addr) external override onlyOwner {
        _setPlatformPrimarySalesAddress(addr);
    }

    function setPlatformPrimarySalesPercentage(uint256 newPercentage) external override onlyOwner {
        require(newPercentage < 100, "Platform primary sales percentage must be less than 100");
        platformPrimarySalesPercentage = newPercentage;
        emit PlatformUpdated(PLATFORM_UPDATED_PRIMARY_SALES_PERCENTAGE);
    }

    /**
     * Add a new admin
     */
    function addAdmin(address admin) external override onlyOwner {
        admins[admin] = true;
    }

    /**
     * Remove admin
     */
    function removeAdmin(address admin) external override onlyOwner {
        admins[admin] = false;
    }

    /**
     * Add a new minter
     */
    function addMinter(address minter) external override onlyOwner {
        minters[minter] = true;
    }

    /**
     * Remove minter
     */
    function removeMinter(address minter) external override onlyOwner {
        minters[minter] = false;
    }

    /**
     * default collection state is DRAFT
     */
    function addCollection(
        string calldata name,
        address payable authorAddress,
        string calldata baseUri,
        string calldata tokenUriSuffix,
        bool useIpfs,
        bool randomTokenId,
        uint24 totalTokens,
        uint24 maxPurchasePerTx
    ) external override onlyAdmin returns (uint256 collectionId) {
        _collectionCount += 1; // start from 1
        collectionId = _collectionCount;
        _collections[collectionId].name = name;
        _collections[collectionId].authorAddress = authorAddress;
        _collections[collectionId].baseUri = baseUri;
        _collections[collectionId].tokenUriSuffix = tokenUriSuffix;
        _collections[collectionId].useIpfs = useIpfs;
        _collections[collectionId].randomTokenId = randomTokenId;
        _collections[collectionId].totalTokens = totalTokens;
        _collections[collectionId].maxPurchasePerTx = maxPurchasePerTx; // default to 1

        emit CollectionUpdated(collectionId, COLLECTION_ADDED_NEW);
    }

    function setCollectionGasPriceInWei(uint256 collectionId, uint256 gasPriceInWei)
        external
        override
        onlyAdmin
        whenNotInState(CollectionState.FROZEN, collectionId)
    {
        _collectionMintPrices[collectionId].gasPriceInWei = gasPriceInWei;
        emit CollectionUpdated(collectionId, COLLECTION_UPDATED_GAS_PRICE_IN_WEI);
    }

    function setCollectionErc20PriceInWei(
        uint256 collectionId,
        address[] calldata erc20Tokens,
        bool[] calldata supported,
        uint256[] calldata pricesInWei
    ) external override onlyAdmin whenNotInState(CollectionState.FROZEN, collectionId) {
        require(erc20Tokens.length == supported.length, "Array lengths don't match");
        require(erc20Tokens.length == pricesInWei.length, "Array lengths don't match");

        for (uint256 i = 0; i < erc20Tokens.length; i++) {
            address token = erc20Tokens[i];
            _collectionMintPrices[collectionId].acceptedErc20Tokens[token] = supported[i];
            _collectionMintPrices[collectionId].erc20TokenPricesInWei[token] = pricesInWei[i];
        }

        emit CollectionUpdated(collectionId, COLLECTION_UPDATED_ERC20_GAS_PRICE_IN_WEI);
    }

    function addPayees(
        uint256 collectionId,
        address payable[] calldata payees,
        uint256[] calldata percentages
    ) external override onlyAdmin whenNotInState(CollectionState.FROZEN, collectionId) {
        require(payees.length == percentages.length, "Array lengths don't match");

        uint256 totalPercentage = 0;
        for (uint256 i = 0; i < payees.length; i++) {
            totalPercentage += _collectionPayments[collectionId].additionalPayeePercentages[i];
        }
        for (uint256 i = 0; i < percentages.length; i++) {
            totalPercentage += percentages[i];
        }
        require(totalPercentage < 100, "Total percentages of addtional payees must be less than 100");

        uint256 index = _collectionPayments[collectionId].numberOfAddtionalPayees;
        for (uint256 i = 0; i < payees.length; i++) {
            _collectionPayments[collectionId].additionalPayees[index] = payees[i];
            _collectionPayments[collectionId].additionalPayeePercentages[index] = percentages[i];
            index += 1;
        }
        _collectionPayments[collectionId].numberOfAddtionalPayees = index;

        emit CollectionUpdated(collectionId, COLLECTION_ADDED_PAYEES);
    }

    function removeLastPayees(uint256 collectionId, uint256 numberOfLastPayees)
        external
        override
        onlyAdmin
        whenNotInState(CollectionState.FROZEN, collectionId)
    {
        uint256 numberOfAddtionalPayees = _collectionPayments[collectionId].numberOfAddtionalPayees;
        require(numberOfLastPayees <= numberOfAddtionalPayees, "Exceeds current number of addtional payees");

        for (uint256 i = numberOfAddtionalPayees - 1; i >= numberOfAddtionalPayees - numberOfLastPayees; i--) {
            delete _collectionPayments[collectionId].additionalPayees[i];
            delete _collectionPayments[collectionId].additionalPayeePercentages[i];
        }
        _collectionPayments[collectionId].numberOfAddtionalPayees -= numberOfLastPayees;

        emit CollectionUpdated(collectionId, COLLECTION_REMOVED_PAYEES);
    }

    function setCollectionName(uint256 collectionId, string calldata name)
        external
        override
        onlyAdmin
        whenNotInState(CollectionState.FROZEN, collectionId)
    {
        _collections[collectionId].name = name;

        emit CollectionUpdated(collectionId, COLLECTION_UPDATED_NAME);
    }

    function setCollectionAuthorAddress(uint256 collectionId, address payable authorAddress)
        external
        override
        onlyAdmin
        whenNotInState(CollectionState.FROZEN, collectionId)
    {
        _collections[collectionId].authorAddress = authorAddress;

        emit CollectionUpdated(collectionId, COLLECTION_UPDATED_AUTHOR_ADDRESS);
    }

    function setCollectionTokenUri(
        uint256 collectionId,
        string calldata baseUri,
        string calldata tokenUriSuffix,
        bool useIpfs
    ) external override onlyAdmin whenNotInState(CollectionState.FROZEN, collectionId) {
        _collections[collectionId].baseUri = baseUri;
        _collections[collectionId].tokenUriSuffix = tokenUriSuffix;
        _collections[collectionId].useIpfs = useIpfs;

        emit CollectionUpdated(collectionId, COLLECTION_UPDATED_TOKEN_URI);
    }

    function setCollectionRandomTokenId(uint256 collectionId, bool randomTokenId)
        external
        override
        onlyAdmin
        whenNotInState(CollectionState.FROZEN, collectionId)
    {
        require(_collections[collectionId].minted == 0, "Cannot change if already minted");
        _collections[collectionId].randomTokenId = randomTokenId;

        emit CollectionUpdated(collectionId, COLLECTION_UPDATED_RANDOM_TOKEN_ID);
    }

    function setCollectionTotalTokens(uint256 collectionId, uint24 totalTokens)
        external
        override
        onlyAdmin
        whenNotInState(CollectionState.FROZEN, collectionId)
    {
        require(
            totalTokens >= _collections[collectionId].minted,
            "Total tokens must be greater then number of minted tokens"
        );
        _collections[collectionId].totalTokens = totalTokens;

        emit CollectionUpdated(collectionId, COLLECTION_UPDATED_TOTAL_TOKENS);
    }

    function setCollectionMaxPurchasePerTx(uint256 collectionId, uint24 maxPurchasePerTx)
        external
        onlyAdmin
        whenNotInState(CollectionState.FROZEN, collectionId)
    {
        _collections[collectionId].maxPurchasePerTx = maxPurchasePerTx;

        emit CollectionUpdated(collectionId, COLLECTION_UPDATED_MAX_PURCHASE_PER_TX);
    }

    function setCollectionState(uint256 collectionId, CollectionState nextState) external override onlyAdmin {
        CollectionState currentState = _collections[collectionId].state;
        require(
            currentState != CollectionState.COMPLETED && currentState != CollectionState.FROZEN,
            "Cannot change state anymore"
        );
        if (currentState == CollectionState.DRAFT) {
            require(nextState == CollectionState.ACTIVE, "Only able to change to ACTIVE");
            _collections[collectionId].startDate = uint24(block.timestamp);
        } else if (currentState == CollectionState.ACTIVE) {
            require(nextState == CollectionState.LOCKED, "Only able to change to LOCKED");
        } else {
            require(nextState == CollectionState.ACTIVE, "Only able to change to ACTIVE");
        }
        _collections[collectionId].state = nextState;
        if (currentState != CollectionState.COMPLETED && nextState == CollectionState.FROZEN) {
            _collections[collectionId].endDate = uint24(block.timestamp);
        }

        emit CollectionUpdated(collectionId, COLLECTION_UPDATED_STATE);
    }

    function togglePaused(uint256 collectionId) external override onlyAuthor(collectionId) {
        CollectionState currentState = _collections[collectionId].state;
        require(
            currentState == CollectionState.ACTIVE || currentState == CollectionState.PAUSED,
            "Can only change when ACTIVE or PAUSED"
        );
        if (currentState == CollectionState.ACTIVE) {
            _collections[collectionId].state = CollectionState.PAUSED;
        } else {
            _collections[collectionId].state = CollectionState.ACTIVE;
        }

        emit CollectionUpdated(collectionId, COLLECTION_UPDATED_STATE);
    }

    function setCollectionAuthor(uint256 collectionId, string calldata author)
        external
        override
        validateWhenUpdateCollectionDetail(collectionId)
        whenNotInState(CollectionState.FROZEN, collectionId)
    {
        _collections[collectionId].author = author;

        emit CollectionUpdated(collectionId, COLLECTION_UPDATED_AUTHOR);
    }

    function setCollectionDescription(uint256 collectionId, string calldata description)
        external
        override
        validateWhenUpdateCollectionDetail(collectionId)
        whenNotInState(CollectionState.FROZEN, collectionId)
    {
        _collections[collectionId].description = description;

        emit CollectionUpdated(collectionId, COLLECTION_UPDATED_DESCRIPTION);
    }

    function setCollectionWebsiteUri(uint256 collectionId, string calldata websiteUri)
        external
        override
        validateWhenUpdateCollectionDetail(collectionId)
        whenNotInState(CollectionState.FROZEN, collectionId)
    {
        _collections[collectionId].websiteUri = websiteUri;

        emit CollectionUpdated(collectionId, COLLECTION_UPDATED_WEBSITE_URI);
    }

    function setCollectionLicense(uint256 collectionId, string calldata license)
        external
        override
        validateWhenUpdateCollectionDetail(collectionId)
        whenNotInState(CollectionState.FROZEN, collectionId)
    {
        _collections[collectionId].license = license;

        emit CollectionUpdated(collectionId, COLLECTION_UPDATED_LICENSE);
    }

    function setCollectionImageUri(uint256 collectionId, string calldata imageUri)
        external
        override
        validateWhenUpdateCollectionDetail(collectionId)
        whenNotInState(CollectionState.FROZEN, collectionId)
    {
        _collections[collectionId].imageUri = imageUri;
        emit CollectionUpdated(collectionId, COLLECTION_UPDATED_IMAGE_URI);
    }

    function getCollection(uint256 collectionId) external view override returns (Collection memory collection) {
        collection = _collections[collectionId];
    }

    function getCollectionGasPriceInWei(uint256 collectionId) external view returns (uint256 gasPriceInWei) {
        gasPriceInWei = _collectionMintPrices[collectionId].gasPriceInWei;
    }

    function getCollectionErc20TokenPrice(uint256 collectionId, address erc20Token)
        external
        view
        override
        returns (uint256 priceInWei)
    {
        priceInWei = _collectionMintPrices[collectionId].erc20TokenPricesInWei[erc20Token];
    }

    function isErc20TokenPaymentSupported(uint256 collectionId, address erc20Token)
        external
        view
        override
        returns (bool supported)
    {
        supported = _collectionMintPrices[collectionId].acceptedErc20Tokens[erc20Token];
    }

    function getCollectionPaymentMetadata(uint256 collectionId)
        external
        view
        override
        returns (PaymentMetadata memory paymentMetadata)
    {
        uint256 numberOfAddtionalPayees = _collectionPayments[collectionId].numberOfAddtionalPayees;
        if (numberOfAddtionalPayees > 0) {
            paymentMetadata.payees = new PayeeInfo[](numberOfAddtionalPayees);
            for (uint256 i = 0; i < numberOfAddtionalPayees; i++) {
                paymentMetadata.payees[i] = PayeeInfo({
                    addr: _collectionPayments[collectionId].additionalPayees[i],
                    percentage: _collectionPayments[collectionId].additionalPayeePercentages[i]
                });
            }
        }
        paymentMetadata.authorAddress = _collections[collectionId].authorAddress;
        paymentMetadata.platformPrimarySalesAddress = platformPrimarySalesAddress;
        paymentMetadata.platformPrimarySalesPercentage = platformPrimarySalesPercentage;
    }

    function getCollectionCount() external view override returns (uint256 count) {
        count = _collectionCount;
    }

    function getCollectionId(uint256 tokenId) external pure override returns (uint256 collectionId) {
        collectionId = _getCollectionId(tokenId);
    }

    function tokenURI(uint256 tokenId) public view override returns (string memory) {
        require(_exists(tokenId), "Token ID does not exist");
        uint256 collectionId = _getCollectionId(tokenId);
        Collection storage collection = _collections[collectionId];

        // if use ipfs (static assets), we should get real tokenId in uri
        if (collection.useIpfs) {
            tokenId = tokenId % ONE_MILLION;
        }

        return string(abi.encodePacked(collection.baseUri, Strings.toString(tokenId), collection.tokenUriSuffix));
    }

    /** ----external functions - BEGIN-----*/

    /** ----internal functions - BEGIN-----*/
    function _mintToken(address to, uint256 collectionId) internal returns (uint256 tokenId) {
        uint24 minted = _collections[collectionId].minted;

        bytes32 seed = keccak256(abi.encodePacked(_msgSender(), minted, block.number, block.timestamp));
        bytes32 hash = randomizerContract.getRandomHash(seed);

        if (_collections[collectionId].randomTokenId) {
            uint256 totalTokens = uint256(_collections[collectionId].totalTokens);
            uint256 currentSlot = minted + 1;
            uint256 randomSlot = randomizerContract.getRandomUint(seed, currentSlot, totalTokens);
            uint256 valueInCurrentSlot = _tokenSlotInCollection[collectionId][currentSlot] == 0
                ? currentSlot
                : _tokenSlotInCollection[collectionId][currentSlot];
            if (currentSlot == randomSlot) {
                // get value in the the current slot
                tokenId = valueInCurrentSlot;
            } else {
                // get value in the random slot then swap it with valueInCurrentSlot
                uint256 valueInRandomSlot = _tokenSlotInCollection[collectionId][randomSlot] == 0
                    ? randomSlot
                    : _tokenSlotInCollection[collectionId][randomSlot];
                tokenId = valueInRandomSlot;
                _tokenSlotInCollection[collectionId][randomSlot] = valueInCurrentSlot;
            }
            tokenId += collectionId * ONE_MILLION;
        } else {
            tokenId = collectionId * ONE_MILLION + minted + 1;
        }

        tokenIdToHash[tokenId] = hash;
        _collections[collectionId].minted = minted + 1;

        _mint(to, tokenId);
    }

    function _setPlatformPrimarySalesAddress(address payable addr) private {
        require(addr != address(0), "Must not be Null address");
        platformPrimarySalesAddress = addr;
        emit PlatformUpdated(PLATFORM_UPDATED_PRIMARY_SALES_PERCENTAGE);
    }

    function _getCollectionId(uint256 tokenId) internal pure returns (uint256 collectionId) {
        collectionId = tokenId / ONE_MILLION;
    }

    function _requireAdmin() private view {
        require(admins[_msgSender()], "Caller is not the admin");
    }

    function _requireAuthor(uint256 collectionId) private view {
        require(_collections[collectionId].authorAddress == _msgSender(), "Caller is not the author");
    }

    /** ----internal functions - END-----*/
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (token/ERC721/ERC721.sol)

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
        require(owner != address(0), "ERC721: address zero is not a valid owner");
        return _balances[owner];
    }

    /**
     * @dev See {IERC721-ownerOf}.
     */
    function ownerOf(uint256 tokenId) public view virtual override returns (address) {
        address owner = _owners[tokenId];
        require(owner != address(0), "ERC721: invalid token ID");
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
        _requireMinted(tokenId);

        string memory baseURI = _baseURI();
        return bytes(baseURI).length > 0 ? string(abi.encodePacked(baseURI, tokenId.toString())) : "";
    }

    /**
     * @dev Base URI for computing {tokenURI}. If set, the resulting URI for each
     * token will be the concatenation of the `baseURI` and the `tokenId`. Empty
     * by default, can be overridden in child contracts.
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
            "ERC721: approve caller is not token owner nor approved for all"
        );

        _approve(to, tokenId);
    }

    /**
     * @dev See {IERC721-getApproved}.
     */
    function getApproved(uint256 tokenId) public view virtual override returns (address) {
        _requireMinted(tokenId);

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
        require(_isApprovedOrOwner(_msgSender(), tokenId), "ERC721: caller is not token owner nor approved");

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
        bytes memory data
    ) public virtual override {
        require(_isApprovedOrOwner(_msgSender(), tokenId), "ERC721: caller is not token owner nor approved");
        _safeTransfer(from, to, tokenId, data);
    }

    /**
     * @dev Safely transfers `tokenId` token from `from` to `to`, checking first that contract recipients
     * are aware of the ERC721 protocol to prevent tokens from being forever locked.
     *
     * `data` is additional data, it has no specified format and it is sent in call to `to`.
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
        bytes memory data
    ) internal virtual {
        _transfer(from, to, tokenId);
        require(_checkOnERC721Received(from, to, tokenId, data), "ERC721: transfer to non ERC721Receiver implementer");
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
        address owner = ERC721.ownerOf(tokenId);
        return (spender == owner || isApprovedForAll(owner, spender) || getApproved(tokenId) == spender);
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
        bytes memory data
    ) internal virtual {
        _mint(to, tokenId);
        require(
            _checkOnERC721Received(address(0), to, tokenId, data),
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
        address owner = ERC721.ownerOf(tokenId);

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
        require(ERC721.ownerOf(tokenId) == from, "ERC721: transfer from incorrect owner");
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
     * Emits an {Approval} event.
     */
    function _approve(address to, uint256 tokenId) internal virtual {
        _tokenApprovals[tokenId] = to;
        emit Approval(ERC721.ownerOf(tokenId), to, tokenId);
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
        require(owner != operator, "ERC721: approve to caller");
        _operatorApprovals[owner][operator] = approved;
        emit ApprovalForAll(owner, operator, approved);
    }

    /**
     * @dev Reverts if the `tokenId` has not been minted yet.
     */
    function _requireMinted(uint256 tokenId) internal view virtual {
        require(_exists(tokenId), "ERC721: invalid token ID");
    }

    /**
     * @dev Internal function to invoke {IERC721Receiver-onERC721Received} on a target address.
     * The call is not executed if the target address is not a contract.
     *
     * @param from address representing the previous owner of the given token ID
     * @param to target address that will receive the tokens
     * @param tokenId uint256 ID of the token to be transferred
     * @param data bytes optional data to send along with the call
     * @return bool whether the call correctly returned the expected magic value
     */
    function _checkOnERC721Received(
        address from,
        address to,
        uint256 tokenId,
        bytes memory data
    ) private returns (bool) {
        if (to.isContract()) {
            try IERC721Receiver(to).onERC721Received(_msgSender(), from, tokenId, data) returns (bytes4 retval) {
                return retval == IERC721Receiver.onERC721Received.selector;
            } catch (bytes memory reason) {
                if (reason.length == 0) {
                    revert("ERC721: transfer to non ERC721Receiver implementer");
                } else {
                    /// @solidity memory-safe-assembly
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
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (token/ERC721/extensions/ERC721Burnable.sol)

pragma solidity ^0.8.0;

import "../ERC721.sol";
import "../../../utils/Context.sol";

/**
 * @title ERC721 Burnable Token
 * @dev ERC721 Token that can be burned (destroyed).
 */
abstract contract ERC721Burnable is Context, ERC721 {
    /**
     * @dev Burns `tokenId`. See {ERC721-_burn}.
     *
     * Requirements:
     *
     * - The caller must own `tokenId` or be an approved operator.
     */
    function burn(uint256 tokenId) public virtual {
        //solhint-disable-next-line max-line-length
        require(_isApprovedOrOwner(_msgSender(), tokenId), "ERC721: caller is not token owner nor approved");
        _burn(tokenId);
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

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.9;

/**
 * TODO: add collection metadata
 */
interface IGashapondo {
    enum CollectionState {
        DRAFT,
        ACTIVE,
        PAUSED,
        LOCKED,
        COMPLETED,
        FROZEN
    }

    struct Collection {
        uint24 totalTokens;
        uint24 minted;
        uint24 metadataCount;
        uint24 maxPurchasePerTx;
        uint24 startDate;
        uint24 endDate;
        bool useIpfs;
        bool randomTokenId;
        address payable authorAddress;
        CollectionState state;
        string name;
        string baseUri;
        string tokenUriSuffix;
        string author;
        string description;
        string websiteUri;
        string license;
        string imageUri;
    }

    struct CollectionMintPrice {
        uint256 gasPriceInWei;
        mapping(address => bool) acceptedErc20Tokens;
        mapping(address => uint256) erc20TokenPricesInWei;
    }

    struct CollectionPayment {
        mapping(uint256 => address payable) additionalPayees;
        mapping(uint256 => uint256) additionalPayeePercentages;
        uint256 numberOfAddtionalPayees;
    }

    struct PayeeInfo {
        address payable addr;
        uint256 percentage;
    }

    struct PaymentMetadata {
        address payable authorAddress;
        address payable platformPrimarySalesAddress;
        uint256 platformPrimarySalesPercentage;
        PayeeInfo[] payees;
    }

    event CollectionUpdated(uint256 indexed collectionId, bytes32 eventName);
    event PlatformUpdated(bytes32 eventName);

    function mint(address to, uint256 collectionId) external returns (uint256 tokenId);

    function mintBatch(
        address to,
        uint256 collectionId,
        uint24 numberOfTokens
    ) external returns (uint256[] memory tokenIds);

    function setRandomizer(address randomizer) external;

    function setPlatformPrimarySalesAddress(address payable addr) external;

    function setPlatformPrimarySalesPercentage(uint256 newPercentage) external;

    function addAdmin(address admin) external;

    function removeAdmin(address admin) external;

    function addMinter(address minter) external;

    function removeMinter(address minter) external;

    function addCollection(
        string calldata name,
        address payable authorAddress,
        string calldata baseUri,
        string calldata tokenUriSuffix,
        bool useIpfs,
        bool randomTokenId,
        uint24 totalTokens,
        uint24 maxPurchasePerTx
    ) external returns (uint256 collectionId);

    function setCollectionGasPriceInWei(uint256 collectionId, uint256 gasPriceInWei) external;

    function setCollectionErc20PriceInWei(
        uint256 collectionId,
        address[] calldata erc20Tokens,
        bool[] calldata supported,
        uint256[] calldata pricesInWei
    ) external;

    function addPayees(
        uint256 collectionId,
        address payable[] calldata payees,
        uint256[] calldata percentages
    ) external;

    function removeLastPayees(uint256 collectionId, uint256 numberOfLastPayees) external;

    function setCollectionName(uint256 collectionId, string calldata name) external;

    function setCollectionAuthorAddress(uint256 collectionId, address payable authorAddress) external;

    function setCollectionTokenUri(
        uint256 collectionId,
        string calldata baseUri,
        string calldata tokenUriSuffix,
        bool useIpfs
    ) external;

    function setCollectionRandomTokenId(uint256 collectionId, bool randomTokenId) external;

    function setCollectionTotalTokens(uint256 collectionId, uint24 totalTokens) external;

    function setCollectionMaxPurchasePerTx(uint256 collectionId, uint24 maxPurchasePerTx) external;

    function setCollectionState(uint256 collectionId, CollectionState nextState) external;

    function togglePaused(uint256 collectionId) external;

    function setCollectionAuthor(uint256 collectionId, string calldata author) external;

    function setCollectionDescription(uint256 collectionId, string calldata description) external;

    function setCollectionWebsiteUri(uint256 collectionId, string calldata websiteUri) external;

    function setCollectionLicense(uint256 collectionId, string calldata license) external;

    function setCollectionImageUri(uint256 collectionId, string calldata imageUri) external;

    function getCollection(uint256 collectionId) external view returns (Collection memory collection);

    function getCollectionGasPriceInWei(uint256 collectionId) external view returns (uint256 gasPriceInWei);

    function getCollectionErc20TokenPrice(uint256 collectionId, address erc20Token)
        external
        view
        returns (uint256 priceInWei);

    function isErc20TokenPaymentSupported(uint256 collectionId, address erc20Token)
        external
        view
        returns (bool supported);

    function getCollectionPaymentMetadata(uint256 collectionId)
        external
        view
        returns (PaymentMetadata memory paymentMetadata);

    function getCollectionCount() external view returns (uint256 count);

    function platformPrimarySalesPercentage() external view returns (uint256 percentage);

    function getCollectionId(uint256 tokenId) external pure returns (uint256 collectionId);
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.9;

interface IRandomizer {
    function getRandomHash(bytes32 seed) external view returns (bytes32 randomHash);

    function getRandomUint(
        bytes32 seed,
        uint256 from,
        uint256 to
    ) external view returns (uint256 randomUint);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (token/ERC721/IERC721.sol)

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

    /**
     * @dev Safely transfers `tokenId` token from `from` to `to`, checking first that contract recipients
     * are aware of the ERC721 protocol to prevent tokens from being forever locked.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `tokenId` token must exist and be owned by `from`.
     * - If the caller is not `from`, it must have been allowed to move this token by either {approve} or {setApprovalForAll}.
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
     * @dev Returns the account approved for `tokenId` token.
     *
     * Requirements:
     *
     * - `tokenId` must exist.
     */
    function getApproved(uint256 tokenId) external view returns (address operator);

    /**
     * @dev Returns if the `operator` is allowed to manage all of the assets of `owner`.
     *
     * See {setApprovalForAll}
     */
    function isApprovedForAll(address owner, address operator) external view returns (bool);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.6.0) (token/ERC721/IERC721Receiver.sol)

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
     * The selector can be obtained in Solidity with `IERC721Receiver.onERC721Received.selector`.
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
// OpenZeppelin Contracts (last updated v4.7.0) (utils/Strings.sol)

pragma solidity ^0.8.0;

/**
 * @dev String operations.
 */
library Strings {
    bytes16 private constant _HEX_SYMBOLS = "0123456789abcdef";
    uint8 private constant _ADDRESS_LENGTH = 20;

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

    /**
     * @dev Converts an `address` with fixed length of 20 bytes to its not checksummed ASCII `string` hexadecimal representation.
     */
    function toHexString(address addr) internal pure returns (string memory) {
        return toHexString(uint256(uint160(addr)), _ADDRESS_LENGTH);
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