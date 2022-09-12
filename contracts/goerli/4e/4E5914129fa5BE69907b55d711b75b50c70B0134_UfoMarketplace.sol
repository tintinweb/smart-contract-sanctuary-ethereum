//SPDX-License-Identifier: MIT
pragma solidity ^0.8.7;

import '@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol';
import '@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol';
import '@openzeppelin/contracts-upgradeable/security/PausableUpgradeable.sol';
import '@openzeppelin/contracts-upgradeable/token/ERC721/IERC721Upgradeable.sol';
import '@openzeppelin/contracts/token/ERC721/IERC721Receiver.sol';
import '@openzeppelin/contracts-upgradeable/token/ERC20/IERC20Upgradeable.sol';
import '@openzeppelin/contracts-upgradeable/token/ERC20/utils/SafeERC20Upgradeable.sol';
import './../Errors.sol';
import './../BaseContract.sol';
import './../interfaces/ISuperGalaticFactory.sol';

/**
 * @notice SuperGalatic NFT Contract
 */

contract UfoMarketplace is BaseContract, Initializable, OwnableUpgradeable, PausableUpgradeable, IERC721Receiver {
    using SafeERC20Upgradeable for IERC20Upgradeable;
    //Represents NFT
    struct FixedSellItem {
        //current owner of NFT
        address seller;
        uint256 price;
        uint256 startedAt;
    }

    struct AuctionItem {
        //current owner of NFT
        address seller;
        uint256 startingPrice;
        uint256 endingPrice;
        uint256 duration;
        uint256 startedAt;
    }

    enum SellType {
        NO_TYPE,
        FixedType,
        AuctionType
    }

    // Cut owner takes on each auction, measured in basis points (1/100 of a percent).
    // Values 0-10,000 map to 0%-100%
    uint256 public platformFee;

    address public superGalaticFactory;

    // Map from token ID to their corresponding sell item.
    // gensis nft address => mapping (nft id => item structure))
    mapping(address => mapping(uint256 => FixedSellItem)) public fixedItems;

    // Map from token ID to their corresponding sell item.
    // gensis nft address => mapping (nft id => item structure))
    mapping(address => mapping(uint256 => AuctionItem)) public auctionItems;

    event AuctionItemCreated(
        address indexed _nftAddress,
        uint256 indexed _tokenId,
        uint256 _startingPrice,
        uint256 _endingPrice,
        uint256 _duration,
        address _seller
    );

    event FixedItemCreated(address indexed _nftAddress, uint256 indexed _tokenId, uint256 _price, address _seller);

    event AuctionSuccessful(address indexed _nftAddress, uint256 indexed _tokenId, uint256 _totalPrice, address _winner);

    event AuctionCancelled(address indexed _nftAddress, uint256 indexed _tokenId);

    event FixedItemSuccessful(address indexed _nftAddress, uint256 indexed _tokenId, uint256 _totalPrice, address _winner);

    event FixedItemCancelled(address indexed _nftAddress, uint256 indexed _tokenId);

    function initialize(
        address _admin,
        uint256 _platformFee,
        address _superGalaticFactory
    ) external initializer {
        require(_admin != address(0), Errors.SHOULD_BE_NON_ZERO);
        require(_platformFee <= 10000, Errors.EXCEED_PLATFORM_FEE_VALUE);
        __Ownable_init();
        transferOwnership(_admin);
        __Pausable_init();

        platformFee = _platformFee;
        superGalaticFactory = _superGalaticFactory;
        _initCryptoCurrency();
    }

    function onERC721Received(
        address,
        address,
        uint256,
        bytes calldata
    ) public pure override returns (bytes4) {
        return this.onERC721Received.selector;
    }

    /// @dev update the platform's fee
    /// @param newFee - new fee value to be changed
    function updatePlateformFee(uint256 newFee) external onlyOwner {
        require(newFee <= 10000, Errors.EXCEED_PLATFORM_FEE_VALUE);
        platformFee = newFee;
    }

    /// @dev update the contract address of factory contract
    /// @param newAddr - new contract address to be changed
    function updateSuperGalaticFactoryContract(address newAddr) external onlyOwner {
        require(newAddr != address(0), Errors.SHOULD_BE_NON_ZERO);
        require(newAddr != superGalaticFactory, Errors.SHOULD_BE_DIFFERENT);
        superGalaticFactory = newAddr;
    }

    /// @dev set crypto currency's contract address
    /// @param _type - indicate crypto type from CRYPT_CURRENCY_TYPE enum
    /// @param _addr - address of crypto
    function updateCryptoAddress(CRYPT_CURRENCY_TYPE _type, address _addr) external onlyOwner {
        require(_type != CRYPT_CURRENCY_TYPE.NO_TYPE, Errors.SHOULD_NOT_BE_NO_TYPE);
        require(_addr != address(0), Errors.SHOULD_BE_NON_ZERO);
        cryptAddresses[_type] = _addr;
    }

    /// @dev make a NFT as sellable by owner
    /// @param _nftAddress - The address of the NFT.
    /// @param _tokenId - ID of token whose ownership to verify.
    /// @param _price - the price of NFT item
    function createFixedItem(
        address _nftAddress,
        uint256 _tokenId,
        uint256 _price
    ) external whenNotPaused {
        address _seller = msg.sender;
        require(_owns(_nftAddress, _seller, _tokenId), Errors.ONLY_OWNER);
        require(_price > 0, Errors.SHOULD_BE_NON_ZERO);
        _checkAddressIsSuperGalatic(_nftAddress);
        fixedItems[_nftAddress][_tokenId] = FixedSellItem(_seller, _price, block.timestamp);
        _escrow(_nftAddress, _seller, _tokenId);

        emit FixedItemCreated(_nftAddress, _tokenId, _price, _seller);
    }

    /// @dev make a NFT as sellable by owner with duration
    /// @param _nftAddress - The address of the NFT.
    /// @param _tokenId - ID of token whose ownership to verify.
    /// @param _startingPrice - Price of item (in wei) at beginning of auction.
    /// @param _endingPrice - Price of item (in wei) at end of auction.
    /// @param _duration - Length of time to move between starting
    ///  price and ending price (in seconds).
    function createAuctionItem(
        address _nftAddress,
        uint256 _tokenId,
        uint256 _startingPrice,
        uint256 _endingPrice,
        uint256 _duration
    ) external whenNotPaused {
        address _seller = msg.sender;
        require(_owns(_nftAddress, _seller, _tokenId), Errors.ONLY_OWNER);
        require(_duration > 1 minutes, Errors.SHOULD_BE_MORE_THAN_ONE_MINUTE);
        require(_startingPrice > _endingPrice, Errors.START_PRICE__IS_BIGGER_THAN_END_PRICE);
        _checkAddressIsSuperGalatic(_nftAddress);

        auctionItems[_nftAddress][_tokenId] = AuctionItem(_seller, _startingPrice, _endingPrice, _duration, block.timestamp);
        _escrow(_nftAddress, _seller, _tokenId);

        emit AuctionItemCreated(_nftAddress, _tokenId, _startingPrice, _endingPrice, _duration, _seller);
    }

    /// @dev buy NFT which is listed on marketplace with other tokens than native token(MATIC)
    /// @param _nftAddress - The address of the NFT.
    /// @param _tokenId - ID of token of which user wants to buy.
    /// @param _price - price of NFT
    function buyFixedSellItem(
        address _nftAddress,
        uint256 _tokenId,
        uint256 _price,
        CRYPT_CURRENCY_TYPE _type
    ) external whenNotPaused {
        //update needed regards to many crypto currency types
        FixedSellItem storage _item = fixedItems[_nftAddress][_tokenId];
        require(_item.startedAt > 0, Errors.SHOULD_BE_ON_SELL_STATUS);
        require(_item.price <= _price, Errors.INSUFFICIENT_PRICE);
        require(cryptAddresses[_type] != address(0), Errors.SHOULD_BE_NON_ZERO);

        _removeSellItem(_nftAddress, _tokenId);

        IERC20Upgradeable crypto = IERC20Upgradeable(cryptAddresses[_type]);
        crypto.safeTransferFrom(_item.seller, msg.sender, _price);
        _transfer(_nftAddress, address(this), msg.sender, _tokenId);
    }

    /// @dev buy NFT which is listed on marketplace with native token
    /// @param _nftAddress - The address of the NFT.
    /// @param _tokenId - ID of token of which user wants to buy.
    function buyFixedSellItemByNativeToken(address _nftAddress, uint256 _tokenId) external payable whenNotPaused {
        FixedSellItem storage _item = fixedItems[_nftAddress][_tokenId];
        require(_item.startedAt > 0, Errors.SHOULD_BE_ON_SELL_STATUS);
        uint256 actualPrice = _actualFxiedPrice(_item, msg.value);
        _removeSellItem(_nftAddress, _tokenId);
        payable(_item.seller).transfer(actualPrice);
        _transfer(_nftAddress, address(this), msg.sender, _tokenId);
        emit FixedItemSuccessful(_nftAddress, _tokenId, msg.value, msg.sender);
    }

    /// @dev buy NFT which is listed on auction at marketplace with native token
    /// @param _nftAddress - The address of the NFT.
    /// @param _tokenId - ID of token of which user wants to buy.
    function buyAuctionItemByNativeToken(address _nftAddress, uint256 _tokenId) external payable whenNotPaused {
        AuctionItem storage _item = auctionItems[_nftAddress][_tokenId];
        require(_item.startedAt > 0, Errors.SHOULD_BE_ON_SELL_STATUS);
        _removeSellItem(_nftAddress, _tokenId);
        uint256 actualPrice = _actualAuctionPrice(_item, msg.value);
        _transfer(_nftAddress, address(this), msg.sender, _tokenId);
        payable(_item.seller).transfer(actualPrice);
        emit AuctionSuccessful(_nftAddress, _tokenId, msg.value, msg.sender);
    }

    /// @dev Cancels an auction that hasn't been won yet.
    ///  Returns the NFT to original owner.
    /// @notice This is a state-modifying function that can
    ///  be called while the contract is paused.
    /// @param _nftAddress - Address of the NFT.
    /// @param _tokenId - ID of token on auction
    function cancelAuctionItem(address _nftAddress, uint256 _tokenId) external {
        AuctionItem storage _auction = auctionItems[_nftAddress][_tokenId];
        require(_auction.startedAt > 0, Errors.SHOULD_BE_ON_SELL_STATUS);
        require(msg.sender == _auction.seller, Errors.ONLY_OWNER);
        _cancelAuction(_nftAddress, _tokenId, _auction.seller);
    }

    /// @dev emergency cancel progress
    /// @notice This is a state-modifying function that can
    ///  be called while the contract is paused.
    /// @param _nftAddress - Address of the NFT.
    /// @param _tokenId - ID of token which is on pending status
    function cancelSellWhenPaused(
        address _nftAddress,
        uint256 _tokenId,
        SellType _type
    ) external whenPaused onlyOwner {
        require(_type == SellType.FixedType || _type == SellType.AuctionType, Errors.SHOULD_NOT_BE_NO_TYPE);
        if (_type == SellType.FixedType) {
            FixedSellItem storage fixedItem = fixedItems[_nftAddress][_tokenId];
            require(fixedItem.startedAt > 0, Errors.SHOULD_BE_ON_SELL_STATUS);
            _cancelFixedSell(_nftAddress, _tokenId, fixedItem.seller);
        } else {
            AuctionItem storage auctionItem = auctionItems[_nftAddress][_tokenId];
            require(auctionItem.startedAt > 0, Errors.SHOULD_BE_ON_SELL_STATUS);
            _cancelFixedSell(_nftAddress, _tokenId, auctionItem.seller);
        }
    }

    /// @dev Cancels an fixted sell that hasn't been won yet.
    ///  Returns the NFT to original owner.
    /// @notice This is a state-modifying function that can
    ///  be called while the contract is paused.
    /// @param _nftAddress - Address of the NFT.
    /// @param _tokenId - ID of token on auction
    function cancelFixedSell(address _nftAddress, uint256 _tokenId) external {
        FixedSellItem storage _fixed = fixedItems[_nftAddress][_tokenId];
        require(_fixed.startedAt > 0, Errors.SHOULD_BE_ON_SELL_STATUS);
        require(msg.sender == _fixed.seller, Errors.ONLY_OWNER);
        _cancelFixedSell(_nftAddress, _tokenId, _fixed.seller);
    }

    /// @dev Transfers an NFT owned by seller to another address.
    /// @param _nftAddress - The address of the NFT.
    /// @param _seller - Address to transfer NFT from.
    /// @param _buyer - Address to transfer NFT to.
    /// @param _tokenId - ID of token to transfer.
    function _transfer(
        address _nftAddress,
        address _seller,
        address _buyer,
        uint256 _tokenId
    ) internal {
        IERC721Upgradeable _nftContract = IERC721Upgradeable(_nftAddress);
        // It will throw if transfer fails
        _nftContract.safeTransferFrom(_seller, _buyer, _tokenId, '');
    }

    /// @dev remove NFT on listing
    /// @param _nftAddress - The address of the NFT.
    /// @param _tokenId - ID of token of which user wants to buy.
    function _removeSellItem(address _nftAddress, uint256 _tokenId) internal {
        delete fixedItems[_nftAddress][_tokenId];
    }

    /// @dev remove NFT on listing
    /// @param _nftAddress - The address of the NFT.
    /// @param _tokenId - ID of token of which user wants to buy.
    function _removeAuction(address _nftAddress, uint256 _tokenId) internal {
        delete auctionItems[_nftAddress][_tokenId];
    }

    /// @dev Escrows the NFT, assigning ownership to this contract.
    /// Throws if the escrow fails.
    /// @param _nftAddress - The address of the NFT.
    /// @param _owner - Current owner address of token to escrow.
    /// @param _tokenId - ID of token whose approval to verify.
    function _escrow(
        address _nftAddress,
        address _owner,
        uint256 _tokenId
    ) internal {
        IERC721Upgradeable addr = IERC721Upgradeable(_nftAddress);
        addr.safeTransferFrom(_owner, address(this), _tokenId);
    }

    /// @dev check the address is super galatic nft address or not. revert if the address is not super galatic
    /// @param _nftAddress - The address of the NFT.
    function _checkAddressIsSuperGalatic(address _nftAddress) internal view {
        bool _isSuperGalaticNFT = ISuperGalaticFactory(superGalaticFactory)._isSuperGalaticNFTContract(_nftAddress);
        require(_isSuperGalaticNFT, Errors.ONLY_SUPERGALATIC_CONTRACT);
    }

    /// @dev Returns true if the claimant owns the token.
    /// @param _nftAddress - The address of the NFT.
    /// @param _claimant - Address claiming to own the token.
    /// @param _tokenId - ID of token whose ownership to verify.
    function _owns(
        address _nftAddress,
        address _claimant,
        uint256 _tokenId
    ) internal view returns (bool) {
        IERC721Upgradeable _nftContract = IERC721Upgradeable(_nftAddress);
        return (_nftContract.ownerOf(_tokenId) == _claimant);
    }

    /// @dev Returns current price of an NFT on auction. Broken into two
    ///  functions (this one, that computes the duration from the auction
    ///  structure, and the other that does the price computation) so we
    ///  can easily test that the price computation works correctly.
    function _getCurrentPrice(AuctionItem storage _auction) internal view returns (uint256) {
        uint256 _secondsPassed = 0;
        if (block.timestamp > _auction.startedAt) {
            _secondsPassed = block.timestamp - _auction.startedAt;
        }

        if (_secondsPassed >= _auction.duration) {
            // We've reached the end of the dynamic pricing portion
            // of the auction, just return the end price.
            return _auction.endingPrice;
        } else {
            uint256 _totalPriceChange = _auction.endingPrice - _auction.startingPrice;
            uint256 _currentPriceChange = (_totalPriceChange * _secondsPassed) / _auction.duration;

            // _currentPriceChange can be negative, but if so, will have a magnitude
            // less that _startingPrice. Thus, this result will always end up positive.
            uint256 _currentPrice = _auction.startingPrice + _currentPriceChange;

            return _currentPrice;
        }
    }

    /// @dev Computes owner's cut of a sale.
    /// @param _price - Sale price of NFT.
    function _computeCut(uint256 _price) internal view returns (uint256) {
        // NOTE: We don't use SafeMath (or similar) in this function because
        //  all of our entry functions carefully cap the maximum values for
        //  currency (at 128-bits), and ownerCut <= 10000 (see the require()
        //  statement in the ClockAuction constructor). The result of this
        //  function is always guaranteed to be <= _price.
        return (_price * platformFee) / 10000;
    }

    /// @dev actual amount which is sent to seller
    /// @param _auctionItem - auction item which is stored at map.
    /// @param requestedPrice - price of buyer.
    function _actualAuctionPrice(AuctionItem storage _auctionItem, uint256 requestedPrice) internal view returns (uint256) {
        uint256 _price = _getCurrentPrice(_auctionItem);
        require(_price <= requestedPrice, Errors.INSUFFICIENT_PRICE);
        uint256 _plateformFee = _computeCut(_price);
        uint256 actualPrice = _price - _plateformFee;
        require(actualPrice > 0, Errors.SHOULD_BE_MORE_THAN_ZERO);
        return actualPrice;
    }

    /// @dev actual amount which is sent to seller
    /// @param _fixedItem - auction item which is stored at map.
    /// @param requestedPrice - price of buyer.
    function _actualFxiedPrice(FixedSellItem storage _fixedItem, uint256 requestedPrice) internal view returns (uint256) {
        uint256 _price = _fixedItem.price;
        require(_price <= requestedPrice, Errors.INSUFFICIENT_PRICE);
        uint256 _plateformFee = _computeCut(_price);
        uint256 actualPrice = _price - _plateformFee;
        require(actualPrice > 0, Errors.SHOULD_BE_MORE_THAN_ZERO);
        return actualPrice;
    }

    /// @dev Cancels an auction unconditionally.
    function _cancelAuction(
        address _nftAddress,
        uint256 _tokenId,
        address _seller
    ) internal {
        _removeAuction(_nftAddress, _tokenId);
        _transfer(_nftAddress, address(this), _seller, _tokenId);
        emit AuctionCancelled(_nftAddress, _tokenId);
    }

    /// @dev Cancels an auction unconditionally.
    function _cancelFixedSell(
        address _nftAddress,
        uint256 _tokenId,
        address _seller
    ) internal {
        _removeSellItem(_nftAddress, _tokenId);
        _transfer(_nftAddress, address(this), _seller, _tokenId);
        emit FixedItemCancelled(_nftAddress, _tokenId);
    }

    function _initCryptoCurrency() internal {
        //need to be updated with correct addresses
        cryptAddresses[CRYPT_CURRENCY_TYPE.ETH] = 0xD6e842B844a67151D9319CFED96B39EEeC6D466f;
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

//SPDX-License-Identifier: MIT
pragma solidity 0.8.7;

library Errors {
    string public constant SHOULD_BE_ON_SELL_STATUS = '1';
    string public constant ONLY_OWNER = '2';
    string public constant INSUFFICIENT_PRICE = '3';
    string public constant SHOULD_NOT_BE_NO_TYPE = '4';
    string public constant SHOULD_BE_MORE_THAN_ZERO = '5';
    string public constant ONLY_FACTORY_CAN_CALL = '6';
    string public constant DEFENCE = '7';
    string public constant SHOULD_SAME = '8';
    string public constant SHOULD_BE_NON_ZERO = '9';
    string public constant SHOULD_BE_LESS_THAN_FIVE = 'A';
    string public constant ONLY_POOLS_CAN_CALL = 'B';
    string public constant LOCK_IN_BLOCK_LESS_THAN_MIN = 'C';
    string public constant EXCEEDS_MAX_ITERATION = 'D';
    string public constant SHOULD_BE_ZERO = 'E';
    string public constant ARITY_MISMATCH = 'F';
    string public constant APPROVAL_UNSUCCESSFUL = '10';
    string public constant MORE_THAN_FRACTION = '11';
    string public constant ONLY_FEATURE_OF_FLEXI_POOLS = '12';
    string public constant ALREADY_SETUP = '13';
    string public constant ONLY_MINTER = '14';
    string public constant ONLY_SUPERGALATIC_CONTRACT = '15';
    string public constant EXCEED_PLATFORM_FEE_VALUE = '16';
    string public constant SHOULD_BE_DIFFERENT = '17';
    string public constant SHOULD_BE_MORE_THAN_ONE_MINUTE = '18';
    string public constant START_PRICE__IS_BIGGER_THAN_END_PRICE = '19';
}

//SPDX-License-Identifier: MIT
pragma solidity ^0.8.7;
import './Errors.sol';
import '@chainlink/contracts/src/v0.8/interfaces/AggregatorV3Interface.sol';

/**
 @notice NFT UFO contract function
 @dev The interface only currently contains only breeding function. Any other functions can be added as per requirement
 */
contract BaseContract {
    AggregatorV3Interface internal priceFeed;
    enum CRYPT_CURRENCY_TYPE {
        NO_TYPE,
        UFO,
        ETH,
        MATIC,
        USDC,
        USDT,
        UAP,
        PRESERVE1,
        PRESERVE2
    }
    mapping(CRYPT_CURRENCY_TYPE => address) public cryptAddresses;

    constructor() {
        priceFeed = AggregatorV3Interface(0xD4a33860578De61DBAbDc8BFdb98FD742fA7028e);
    }

    /**
     * Returns the latest price
     */
    function getLatestPrice() public view returns (int256) {
        (
            ,
            /*uint80 roundID*/
            int256 price, /*uint startedAt*/ /*uint timeStamp*/ /*uint80 answeredInRound*/
            ,
            ,

        ) = priceFeed.latestRoundData();
        return price;
    }
}

//SPDX-License-Identifier: MIT
pragma solidity ^0.8.7;

/**
 @notice NFT factory contract function
 @dev 
 */
interface ISuperGalaticFactory {
    function _isSuperGalaticNFTContract(address _nftAddress) external view returns (bool);
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
pragma solidity ^0.8.0;

interface AggregatorV3Interface {
  function decimals() external view returns (uint8);

  function description() external view returns (string memory);

  function version() external view returns (uint256);

  // getRoundData and latestRoundData should both raise "No data present"
  // if they do not have data to report, instead of returning unset values
  // which could be misinterpreted as actual reported values.
  function getRoundData(uint80 _roundId)
    external
    view
    returns (
      uint80 roundId,
      int256 answer,
      uint256 startedAt,
      uint256 updatedAt,
      uint80 answeredInRound
    );

  function latestRoundData()
    external
    view
    returns (
      uint80 roundId,
      int256 answer,
      uint256 startedAt,
      uint256 updatedAt,
      uint80 answeredInRound
    );
}