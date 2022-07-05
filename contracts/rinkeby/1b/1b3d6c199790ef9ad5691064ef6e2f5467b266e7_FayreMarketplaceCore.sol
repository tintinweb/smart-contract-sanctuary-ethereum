// SPDX-License-Identifier: MIT
pragma solidity 0.8.9;

import "./FayreMultichainBaseUpgradable.sol";

contract FayreMarketplaceCore is FayreMultichainBaseUpgradable {
    /**
        E#1: ERC721 has no nft amount
        E#2: ERC1155 needs nft amount
        E#3: not the owner
        E#4: invalid trade type
        E#5: sale amount not specified
        E#6: sale expiration must be greater than start
        E#7: invalid network id
        E#8: cannot finalize your sale, cancel?
        E#9: salelist expired
        E#10: asset type not supported
        E#11: a sale already active
        E#12: a bid already active
        E#13: cannot finalize unexpired auction
        E#14: cannot accept your offer
        E#15: free offer expired
        E#16: wrong base amount
        E#17: wrong trade status
        E#18: not the signed sender
    */

    enum AssetType {
        ERC20,
        ERC721,
        ERC1155
    }

    enum TradeType {
        SALE_FIXEDPRICE,
        SALE_ENGLISHAUCTION,
        SALE_DUTCHAUCTION,
        BID
    }

    enum TradeStatusType {
        NONE,
        CREATED,
        CANCELLED,
        FAILURE,
        PENDINGTRANSACTION,
        CONCLUDED
    }

    struct TradeRequest {
        uint256 networkId;
        address collectionAddress;
        uint256 tokenId;
        address owner;
        TradeType tradeType;
        AssetType assetType;
        uint256 nftAmount;
        address tokenAddress;
        uint256 amount;
        uint256 start;
        uint256 expiration;
        uint256 saleId;
        uint256 baseAmount;
        TradeStatusType tradeStatusType;
    }

    struct CoreTokenData {
        uint256[] salesIds;
        mapping(uint256 => uint256[]) bidsIds;
    }

    event PutOnSale(uint256 indexed saleId, TradeRequest tradeRequest);
    event CancelSale(uint256 indexed saleId, TradeRequest tradeRequest);
    event SaleIsPending(uint256 indexed saleId, TradeRequest tradeRequest, address buyer, uint256 price, uint256 blockNumber);
    event CloseSale(uint256 indexed saleId, TradeRequest tradeRequest);
    event PlaceBid(uint256 indexed bidId, TradeRequest tradeRequest);
    event CancelBid(uint256 indexed bidId, TradeRequest tradeRequest);
    event FreeOfferIsPending(uint256 indexed bidId, TradeRequest tradeRequest, address seller, uint256 blockNumber);
    event CloseFreeOffer(uint256 indexed bidId, TradeRequest tradeRequest);

    mapping(uint256 => TradeRequest) public sales;
    mapping(uint256 => mapping(address => mapping(uint256 => mapping(address => bool)))) public hasActiveSale;
    mapping(uint256 => TradeRequest) public bids;
    mapping(uint256 => mapping(address => mapping(uint256 => mapping(address => bool)))) public hasActiveBid;

    mapping(uint256 => mapping(address => mapping(uint256 => CoreTokenData))) private _tokensData;
    uint256 private _currentSaleId;
    uint256 private _currentBidId;
    
    function cancelSale(uint256 saleId) external {
        TradeRequest storage saleTradeRequest = sales[saleId];

        require(saleTradeRequest.owner == _msgSender(), "E#3");
        require(saleTradeRequest.tradeStatusType != TradeStatusType.CONCLUDED, "E#17");

        saleTradeRequest.tradeStatusType = TradeStatusType.CANCELLED;

        _clearSaleData(saleId);

        emit CancelSale(saleId, saleTradeRequest);
    }

    function cancelBid(uint256 bidId) external {
        TradeRequest storage bidTradeRequest = bids[bidId];

        require(bidTradeRequest.owner == _msgSender(), "E#3");
        require(bidTradeRequest.tradeStatusType != TradeStatusType.CONCLUDED, "E#17");

        hasActiveBid[bidTradeRequest.networkId][bidTradeRequest.collectionAddress][bidTradeRequest.tokenId][_msgSender()] = false;

        uint256[] storage bidsIds = _tokensData[bidTradeRequest.networkId][bidTradeRequest.collectionAddress][bidTradeRequest.tokenId].bidsIds[bidTradeRequest.saleId];

        uint256 indexToDelete = 0;

        for (uint256 i = 0; i < bidsIds.length; i++)
            if (bidsIds[i] == bidId)
                indexToDelete = i;

        bidsIds[indexToDelete] = bidsIds[bidsIds.length - 1];

        bidsIds.pop();

        bidTradeRequest.tradeStatusType = TradeStatusType.CANCELLED;

        emit CancelBid(bidId, bidTradeRequest);
    }

    function getSaleBidsIds(uint256 networkId, address collectionAddress, uint256 tokenId, uint256 saleId) external view returns(uint256[] memory){
        return _tokensData[networkId][collectionAddress][tokenId].bidsIds[saleId];
    }

    function initialize() public initializer {
        __FayreMultichainBaseUpgradable_init();
    }

    function _executeFunctionWithSignedData(FayreMultichainMessage memory fayreMultichainMessage) internal override {
        if (fayreMultichainMessage.functionIndex == 1)
            _closeSale(fayreMultichainMessage);
        else if (fayreMultichainMessage.functionIndex == 2)
            _closeFreeOffer(fayreMultichainMessage);
        else if (fayreMultichainMessage.functionIndex == 3)
            _putOnSale(fayreMultichainMessage);
        else if (fayreMultichainMessage.functionIndex == 4)
            _finalizeSale(fayreMultichainMessage);
        else if (fayreMultichainMessage.functionIndex == 5)
            _placeBid(fayreMultichainMessage);         
        else if (fayreMultichainMessage.functionIndex == 6)
            _acceptFreeOffer(fayreMultichainMessage);           
    }

    function _putOnSale(FayreMultichainMessage memory fayreMultichainMessage) internal { 
        TradeRequest memory tradeRequest = abi.decode(fayreMultichainMessage.data, (TradeRequest));

        require(tradeRequest.owner == _msgSender(), "E#3");
        require(tradeRequest.networkId > 0, "E#7");
        require(tradeRequest.assetType == AssetType.ERC721 || tradeRequest.assetType == AssetType.ERC1155, "E#10");

        _checkNftAmount(tradeRequest);

        require(tradeRequest.amount > 0, "E#5");
        require(tradeRequest.expiration > block.timestamp, "E#6");
        require(tradeRequest.tradeType == TradeType.SALE_FIXEDPRICE || tradeRequest.tradeType == TradeType.SALE_ENGLISHAUCTION || tradeRequest.tradeType == TradeType.SALE_DUTCHAUCTION, "E#4");
        
        if (tradeRequest.tradeType == TradeType.SALE_DUTCHAUCTION)
            require(tradeRequest.baseAmount > 0 && tradeRequest.baseAmount < tradeRequest.amount, "E#16");

        require(!hasActiveSale[tradeRequest.networkId][tradeRequest.collectionAddress][tradeRequest.tokenId][_msgSender()], "E#11");

        tradeRequest.collectionAddress = tradeRequest.collectionAddress;
        tradeRequest.start = block.timestamp;

        if (tradeRequest.tradeType == TradeType.SALE_ENGLISHAUCTION)
            _clearSaleIdBids(tradeRequest.networkId, tradeRequest.collectionAddress, tradeRequest.tokenId, _currentSaleId);
            
        hasActiveSale[tradeRequest.networkId][tradeRequest.collectionAddress][tradeRequest.tokenId][_msgSender()] = true;

        _tokensData[tradeRequest.networkId][tradeRequest.collectionAddress][tradeRequest.tokenId].salesIds.push(_currentSaleId);

        tradeRequest.tradeStatusType = TradeStatusType.CREATED;

        sales[_currentSaleId] = tradeRequest;

        emit PutOnSale(_currentSaleId, tradeRequest);

        _currentSaleId++;
    }

    function _closeSale(FayreMultichainMessage memory fayreMultichainMessage) internal {
        uint256 saleId = abi.decode(fayreMultichainMessage.data, (uint256));

        TradeRequest storage saleTradeRequest = sales[saleId];

        require(saleTradeRequest.tradeStatusType == TradeStatusType.PENDINGTRANSACTION, "E#17");

        _clearSaleData(saleId);

        saleTradeRequest.tradeStatusType = TradeStatusType.CONCLUDED;

        emit CloseSale(saleId, saleTradeRequest);
    }

    function _finalizeSale(FayreMultichainMessage memory fayreMultichainMessage) internal {
        (uint256 saleId, address sender) = abi.decode(fayreMultichainMessage.data, (uint256, address));

        require(sender == _msgSender(), "E#18");

        TradeRequest storage saleTradeRequest = sales[saleId];

        require(saleTradeRequest.tradeStatusType == TradeStatusType.CREATED, "E#17");

        address buyer = address(0);

        uint256 price = 0;

        if (saleTradeRequest.tradeType == TradeType.SALE_FIXEDPRICE) {
            require(saleTradeRequest.owner != _msgSender(), "E#8");
            require(saleTradeRequest.expiration > block.timestamp, "E#9");

            price = saleTradeRequest.amount;

            buyer = _msgSender();
        } else if (saleTradeRequest.tradeType == TradeType.SALE_ENGLISHAUCTION) {
            require(saleTradeRequest.expiration <= block.timestamp, "E#13");

            uint256[] storage bidsIds = _tokensData[saleTradeRequest.networkId][saleTradeRequest.collectionAddress][saleTradeRequest.tokenId].bidsIds[saleId];

            uint256 highestBidId = 0;
            uint256 highestBidAmount = 0;

            for (uint256 i = 0; i < bidsIds.length; i++)
                if (bids[bidsIds[i]].amount >= saleTradeRequest.amount)
                    if (bids[bidsIds[i]].amount > highestBidAmount) {
                        highestBidId = bidsIds[i];
                        highestBidAmount = bids[bidsIds[i]].amount;
                    }
                    
            price = highestBidAmount;

            buyer = bids[highestBidId].owner;
        } else if (saleTradeRequest.tradeType == TradeType.SALE_DUTCHAUCTION) {
            require(saleTradeRequest.owner != _msgSender(), "E#8");
            require(saleTradeRequest.expiration > block.timestamp, "E#9");

            uint256 amountsDiff = saleTradeRequest.amount - saleTradeRequest.baseAmount;

            uint256 priceDelta = amountsDiff - ((amountsDiff * (block.timestamp - saleTradeRequest.start)) / (saleTradeRequest.expiration - saleTradeRequest.start));

            uint256 currentPrice = saleTradeRequest.baseAmount + priceDelta;

            price = currentPrice;

            buyer = _msgSender();
        }

        saleTradeRequest.tradeStatusType = TradeStatusType.PENDINGTRANSACTION;

        emit SaleIsPending(saleId, saleTradeRequest, buyer, price, block.number);
    }

    function _placeBid(FayreMultichainMessage memory fayreMultichainMessage) internal {
        TradeRequest memory tradeRequest = abi.decode(fayreMultichainMessage.data, (TradeRequest));

        require(tradeRequest.owner == _msgSender(), "E#3");
        require(tradeRequest.networkId > 0, "E#7");
        require(tradeRequest.assetType == AssetType.ERC721 || tradeRequest.assetType == AssetType.ERC1155, "E#10");

        _checkNftAmount(tradeRequest);

        require(tradeRequest.amount > 0, "E#5");
        require(tradeRequest.tradeType == TradeType.BID, "E#4");
        require(!hasActiveBid[tradeRequest.networkId][tradeRequest.collectionAddress][tradeRequest.tokenId][_msgSender()], "E#12");

        tradeRequest.start = block.timestamp;
        tradeRequest.tradeStatusType = TradeStatusType.CREATED;

        bids[_currentBidId] = tradeRequest;

        hasActiveBid[tradeRequest.networkId][tradeRequest.collectionAddress][tradeRequest.tokenId][_msgSender()] = true;

        _tokensData[bids[_currentBidId].networkId][bids[_currentBidId].collectionAddress][bids[_currentBidId].tokenId].bidsIds[tradeRequest.saleId].push(_currentBidId);

        emit PlaceBid(_currentBidId, tradeRequest);

        _currentBidId++;
    }

    function _acceptFreeOffer(FayreMultichainMessage memory fayreMultichainMessage) internal {
        (uint256 bidId, address sender) = abi.decode(fayreMultichainMessage.data, (uint256, address));

        require(sender == _msgSender(), "E#18");

        TradeRequest storage bidTradeRequest = bids[bidId];

        require(bidTradeRequest.owner != _msgSender(), "E#14");
        require(bidTradeRequest.expiration > block.timestamp, "E#15");
        require(bidTradeRequest.tradeStatusType != TradeStatusType.PENDINGTRANSACTION, "E#17");

        bidTradeRequest.tradeStatusType = TradeStatusType.PENDINGTRANSACTION;

        emit FreeOfferIsPending(bidId, bidTradeRequest, _msgSender(), block.number);
    }

    function _closeFreeOffer(FayreMultichainMessage memory fayreMultichainMessage) internal {
        uint256 bidId = abi.decode(fayreMultichainMessage.data, (uint256));

        TradeRequest storage bidTradeRequest = bids[bidId];

        require(bidTradeRequest.tradeStatusType == TradeStatusType.PENDINGTRANSACTION, "E#17");

        hasActiveBid[bidTradeRequest.networkId][bidTradeRequest.collectionAddress][bidTradeRequest.tokenId][bidTradeRequest.owner] = false;

        bidTradeRequest.tradeStatusType = TradeStatusType.CONCLUDED;

        emit CloseFreeOffer(bidId, bidTradeRequest);
    }

    function _clearSaleData(uint256 saleId) private {
        TradeRequest storage saleTradeRequest = sales[saleId];

        if (saleTradeRequest.tradeType == TradeType.SALE_ENGLISHAUCTION)
            _clearSaleIdBids(saleTradeRequest.networkId, saleTradeRequest.collectionAddress, saleTradeRequest.tokenId, 0);

        hasActiveSale[saleTradeRequest.networkId][saleTradeRequest.collectionAddress][saleTradeRequest.tokenId][saleTradeRequest.owner] = false;

        uint256[] storage salesIds = _tokensData[saleTradeRequest.networkId][saleTradeRequest.collectionAddress][saleTradeRequest.tokenId].salesIds;

        uint256 indexToDelete = 0;

        for (uint256 i = 0; i < salesIds.length; i++)
            if (salesIds[i] == saleId)
                indexToDelete = i;

        salesIds[indexToDelete] = salesIds[salesIds.length - 1];

        salesIds.pop();
    }

    function _clearSaleIdBids(uint256 networkId, address collectionAddress, uint256 tokenId, uint256 saleId) private {
        uint256[] storage bidsIds = _tokensData[networkId][collectionAddress][tokenId].bidsIds[saleId];

        for (uint256 i = 0; i < bidsIds.length; i++) {
            bids[bidsIds[i]].start = 0;
            bids[bidsIds[i]].expiration = 0;

            hasActiveBid[networkId][collectionAddress][tokenId][bids[bidsIds[i]].owner] = false;
        }
        
        delete _tokensData[networkId][collectionAddress][tokenId].bidsIds[saleId];
    }

    function _checkNftAmount(TradeRequest memory tradeRequest) private pure {
        if (tradeRequest.assetType == AssetType.ERC721)
            require(tradeRequest.nftAmount == 0, "E#1");
        else if (tradeRequest.assetType == AssetType.ERC1155)
            require(tradeRequest.nftAmount > 0, "E#2");
    }
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.9;

import "./ERC2771ContextUpgradeable.sol";

abstract contract FayreMultichainBaseUpgradable is ERC2771ContextUpgradeable {
    struct FayreMultichainMessage {
        uint256 destinationNetworkId;
        address destinationContractAddress;
        uint256 functionIndex;
        uint256 blockNumber;
        bytes data;
    }

    mapping(address => bool) public isValidator;
    mapping(address => bool) public isFayreValidator;
    uint256 public validationChecksRequired;
    uint256 public fayreValidationChecksRequired;
    mapping(bytes32 => bool) public isMessageHashProcessed;

    uint256 internal _networkId;

    function setValidationChecksRequired(uint256 newValidationChecksRequired) external onlyOwner {
        validationChecksRequired = newValidationChecksRequired;
    }

    function changeAddressIsValidator(address validatorAddress, bool state) external onlyOwner {
        isValidator[validatorAddress] = state;
    }

    function setFayreValidationChecksRequired(uint256 newFayreValidationChecksRequired) external onlyOwner {
        fayreValidationChecksRequired = newFayreValidationChecksRequired;
    }

    function changeAddressIsFayreValidator(address fayreValidatorAddress, bool state) external onlyOwner {
        require(isValidator[fayreValidatorAddress], "Must be a validator");

        isFayreValidator[fayreValidatorAddress] = state;
    }

    function processSignedData(FayreMultichainMessage memory fayreMultichainMessage, uint8[] calldata v, bytes32[] calldata r, bytes32[] calldata s) external {
        _verifySignedMessage(fayreMultichainMessage, v, r, s);

        require(fayreMultichainMessage.destinationContractAddress == address(this), "Wrong destination contract address");
        require(fayreMultichainMessage.destinationNetworkId == _networkId, "Wrong destination network id");

        _executeFunctionWithSignedData(fayreMultichainMessage);
    }

    function _executeFunctionWithSignedData(FayreMultichainMessage memory fayreMultichainMessage) internal virtual {}

    function __FayreMultichainBaseUpgradable_init() internal onlyInitializing {
        __Ownable_init();

        __FayreMultichainBaseUpgradable_init_unchained();
    }

    function __FayreMultichainBaseUpgradable_init_unchained() internal onlyInitializing {
        _networkId = block.chainid;
    }

    function _verifySignedMessage(FayreMultichainMessage memory fayreMultichainMessage, uint8[] memory v, bytes32[] memory r, bytes32[] memory s) internal {
        bytes32 generatedHash = keccak256(abi.encodePacked("\x19Ethereum Signed Message:\n32", keccak256(abi.encode(fayreMultichainMessage.destinationNetworkId, fayreMultichainMessage.destinationContractAddress, fayreMultichainMessage.functionIndex, fayreMultichainMessage.blockNumber, fayreMultichainMessage.data))));
        
        uint256 validationChecks = 0;
        uint256 fayreValidationChecks = 0;

        for (uint256 i = 0; i < v.length; i++) {
            address signer = ecrecover(generatedHash, v[i], r[i], s[i]);

            if (isValidator[signer]) {
                if (isFayreValidator[signer])
                    fayreValidationChecks++;

                validationChecks++;
            }
        }

        require(validationChecks >= validationChecksRequired, "Not enough validation checks");
        require(fayreValidationChecks >= fayreValidationChecksRequired, "Not enough fayre validation checks");
        require(!isMessageHashProcessed[generatedHash], "Message already processed");

        isMessageHashProcessed[generatedHash] = true;
    }

    uint256[46] private __gap;
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.9;

import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";

abstract contract ERC2771ContextUpgradeable is OwnableUpgradeable {
    address private _trustedForwarder;

    function setTrustedForwarder(address newTrustedForwarder) external onlyOwner {
        _trustedForwarder = newTrustedForwarder;
    }

    function isTrustedForwarder(address trustedForwarder) public view returns (bool) {
        return trustedForwarder == _trustedForwarder;
    }

    function _msgSender() internal view virtual override returns (address sender) {
        if (isTrustedForwarder(msg.sender)) {
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

    function __ERC2771ContextUpgradeable_init() internal onlyInitializing {
        __Ownable_init();

        __ERC2771ContextUpgradeable_init_unchained();
    }

    function __ERC2771ContextUpgradeable_init_unchained() internal onlyInitializing {
    }

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
        __Context_init_unchained();
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
    uint256[49] private __gap;
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
        __Context_init_unchained();
    }

    function __Context_init_unchained() internal onlyInitializing {
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
// OpenZeppelin Contracts v4.4.1 (proxy/utils/Initializable.sol)

pragma solidity ^0.8.0;

import "../../utils/AddressUpgradeable.sol";

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
// OpenZeppelin Contracts v4.4.1 (utils/Address.sol)

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