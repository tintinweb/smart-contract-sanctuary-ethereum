// SPDX-License-Identifier: MIT
pragma solidity 0.7.3;

import "@openzeppelin/contracts-upgradeable-0.7.2/access/OwnableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable-0.7.2/utils/ReentrancyGuardUpgradeable.sol";
import "@openzeppelin/contracts-0.7.2/token/ERC721/IERC721.sol";
import "./storage/SuperRareBazaarStorage.sol";
import "./ISuperRareBazaar.sol";

/// @author koloz
/// @title SuperRareBazaar
/// @notice The unified contract for the bazaar logic (Marketplace and Auction House).
/// @dev All storage is inherrited and append only (no modifications) to make upgrade compliant.
contract SuperRareBazaar is
    ISuperRareBazaar,
    OwnableUpgradeable,
    ReentrancyGuardUpgradeable,
    SuperRareBazaarStorage
{
    /////////////////////////////////////////////////////////////////////////
    // Initializer
    /////////////////////////////////////////////////////////////////////////
    function initialize(
        address _marketplaceSettings,
        address _royaltyRegistry,
        address _royaltyEngine,
        address _superRareMarketplace,
        address _superRareAuctionHouse,
        address _spaceOperatorRegistry,
        address _approvedTokenRegistry,
        address _payments,
        address _stakingRegistry,
        address _networkBeneficiary
    ) public initializer {
        require(_marketplaceSettings != address(0));
        require(_royaltyRegistry != address(0));
        require(_royaltyEngine != address(0));
        require(_superRareMarketplace != address(0));
        require(_superRareAuctionHouse != address(0));
        require(_spaceOperatorRegistry != address(0));
        require(_approvedTokenRegistry != address(0));
        require(_payments != address(0));
        require(_networkBeneficiary != address(0));

        marketplaceSettings = IMarketplaceSettings(_marketplaceSettings);
        royaltyRegistry = IERC721CreatorRoyalty(_royaltyRegistry);
        royaltyEngine = IRoyaltyEngineV1(_royaltyEngine);
        superRareMarketplace = _superRareMarketplace;
        superRareAuctionHouse = _superRareAuctionHouse;
        spaceOperatorRegistry = ISpaceOperatorRegistry(_spaceOperatorRegistry);
        approvedTokenRegistry = IApprovedTokenRegistry(_approvedTokenRegistry);
        payments = IPayments(_payments);
        stakingRegistry = _stakingRegistry;
        networkBeneficiary = _networkBeneficiary;

        minimumBidIncreasePercentage = 10;
        maxAuctionLength = 7 days;
        auctionLengthExtension = 15 minutes;
        offerCancelationDelay = 5 minutes;

        __Ownable_init();
        __ReentrancyGuard_init();
    }

    /////////////////////////////////////////////////////////////////////////
    // Admin Functions
    /////////////////////////////////////////////////////////////////////////
    function setMarketplaceSettings(address _marketplaceSettings)
        external
        onlyOwner
    {
        require(_marketplaceSettings != address(0));
        marketplaceSettings = IMarketplaceSettings(_marketplaceSettings);
    }

    function setRoyaltyRegistry(address _royaltyRegistry) external onlyOwner {
        require(_royaltyRegistry != address(0));
        royaltyRegistry = IERC721CreatorRoyalty(_royaltyRegistry);
    }

    function setRoyaltyEngine(address _royaltyEngine) external onlyOwner {
        require(_royaltyEngine != address(0));
        royaltyEngine = IRoyaltyEngineV1(_royaltyEngine);
    }

    function setSuperRareMarketplace(address _superRareMarketplace)
        external
        onlyOwner
    {
        require(_superRareMarketplace != address(0));
        superRareMarketplace = _superRareMarketplace;
    }

    function setSuperRareAuctionHouse(address _superRareAuctionHouse)
        external
        onlyOwner
    {
        require(_superRareAuctionHouse != address(0));
        superRareAuctionHouse = _superRareAuctionHouse;
    }

    function setSpaceOperatorRegistry(address _spaceOperatorRegistry)
        external
        onlyOwner
    {
        require(_spaceOperatorRegistry != address(0));
        spaceOperatorRegistry = ISpaceOperatorRegistry(_spaceOperatorRegistry);
    }

    function setApprovedTokenRegistry(address _approvedTokenRegistry)
        external
        onlyOwner
    {
        require(_approvedTokenRegistry != address(0));
        approvedTokenRegistry = IApprovedTokenRegistry(_approvedTokenRegistry);
    }

    function setPayments(address _payments) external onlyOwner {
        require(_payments != address(0));
        payments = IPayments(_payments);
    }

    function setStakingRegistry(address _stakingRegistry) external onlyOwner {
        require(_stakingRegistry != address(0));
        stakingRegistry = _stakingRegistry;
    }

    function setNetworkBeneficiary(address _networkBeneficiary)
        external
        onlyOwner
    {
        require(_networkBeneficiary != address(0));
        networkBeneficiary = _networkBeneficiary;
    }

    function setMinimumBidIncreasePercentage(
        uint8 _minimumBidIncreasePercentage
    ) external onlyOwner {
        minimumBidIncreasePercentage = _minimumBidIncreasePercentage;
    }

    function setMaxAuctionLength(uint8 _maxAuctionLength) external onlyOwner {
        maxAuctionLength = _maxAuctionLength;
    }

    function setAuctionLengthExtension(uint256 _auctionLengthExtension)
        external
        onlyOwner
    {
        auctionLengthExtension = _auctionLengthExtension;
    }

    function setOfferCancelationDelay(uint256 _offerCancelationDelay)
        external
        onlyOwner
    {
        offerCancelationDelay = _offerCancelationDelay;
    }

    /////////////////////////////////////////////////////////////////////////
    // Marketplace Functions
    /////////////////////////////////////////////////////////////////////////

    /// @notice Place an offer for a given asset
    /// @dev Notice we need to verify that the msg sender has approved us to move funds on their behalf.
    /// @dev Covers use of any currency (0 address is eth).
    /// @dev _amount is the amount of the offer excluding the marketplace fee.
    /// @dev There can be multiple offers of different currencies, but only 1 per currency.
    /// @param _originContract Contract address of the asset being listed.
    /// @param _tokenId Token Id of the asset.
    /// @param _currencyAddress Address of the token being offered.
    /// @param _amount Amount being offered.
    /// @param _convertible If the offer can be converted into an auction
    function offer(
        address _originContract,
        uint256 _tokenId,
        address _currencyAddress,
        uint256 _amount,
        bool _convertible
    ) external payable override {
        (bool success, bytes memory data) = superRareMarketplace.delegatecall(
            abi.encodeWithSelector(
                this.offer.selector,
                _originContract,
                _tokenId,
                _currencyAddress,
                _amount,
                _convertible
            )
        );

        require(success, string(data));
    }

    /// @notice Purchases the token for the current sale price.
    /// @dev Covers use of any currency (0 address is eth).
    /// @dev Need to verify that the buyer (if not using eth) has the marketplace approved for _currencyContract.
    /// @dev Need to verify that the seller has the marketplace approved for _originContract.
    /// @param _originContract Contract address for asset being bought.
    /// @param _tokenId TokenId of asset being bought.
    /// @param _currencyAddress Currency address of asset being used to buy.
    /// @param _amount Amount the piece if being bought for (including marketplace fee).
    function buy(
        address _originContract,
        uint256 _tokenId,
        address _currencyAddress,
        uint256 _amount
    ) external payable override {
        (bool success, bytes memory data) = superRareMarketplace.delegatecall(
            abi.encodeWithSelector(
                this.buy.selector,
                _originContract,
                _tokenId,
                _currencyAddress,
                _amount
            )
        );

        require(success, string(data));
    }

    /// @notice Cancels an existing offer the sender has placed on a piece.
    /// @param _originContract Contract address of token.
    /// @param _tokenId TokenId that has an offer.
    /// @param _currencyAddress Currency address of the offer.
    function cancelOffer(
        address _originContract,
        uint256 _tokenId,
        address _currencyAddress
    ) external override {
        (bool success, bytes memory data) = superRareMarketplace.delegatecall(
            abi.encodeWithSelector(
                this.cancelOffer.selector,
                _originContract,
                _tokenId,
                _currencyAddress
            )
        );

        require(success, string(data));
    }

    /// @notice Sets a sale price for the given asset(s) directed at the _target address.
    /// @dev Covers use of any currency (0 address is eth).
    /// @dev Sale price for everyone is denoted as the 0 address.
    /// @dev Only 1 currency can be used for the sale price directed at a speicific target.
    /// @dev _listPrice of 0 signifies removing the list price for the provided currency.
    /// @dev This function can be used for counter offers as well.
    /// @param _originContract Contract address of the asset being listed.
    /// @param _tokenId Token Id of the asset.
    /// @param _currencyAddress Contract address of the currency asset is being listed for.
    /// @param _listPrice Amount of the currency the asset is being listed for (including all decimal points).
    /// @param _target Address of the person this sale price is target to.
    /// @param _splitAddresses Addresses to split the sellers commission with.
    /// @param _splitRatios The ratio for the split corresponding to each of the addresses being split with.
    function setSalePrice(
        address _originContract,
        uint256 _tokenId,
        address _currencyAddress,
        uint256 _listPrice,
        address _target,
        address payable[] calldata _splitAddresses,
        uint8[] calldata _splitRatios
    ) external override {
        (bool success, bytes memory data) = superRareMarketplace.delegatecall(
            abi.encodeWithSelector(
                this.setSalePrice.selector,
                _originContract,
                _tokenId,
                _currencyAddress,
                _listPrice,
                _target,
                _splitAddresses,
                _splitRatios
            )
        );

        require(success, string(data));
    }

    /// @notice Removes the current sale price of an asset for _target for the given currency.
    /// @dev Sale prices could still exist for different currencies.
    /// @dev Sale prices could still exist for different targets.
    /// @dev Zero address for _currency means that its listed in ether.
    /// @dev _target of zero address is the general sale price.
    /// @param _originContract The origin contract of the asset.
    /// @param _tokenId The tokenId of the asset within the _originContract.
    /// @param _target The address of the person
    function removeSalePrice(
        address _originContract,
        uint256 _tokenId,
        address _target
    ) external override {
        IERC721 erc721 = IERC721(_originContract);
        address tokenOwner = erc721.ownerOf(_tokenId);

        require(
            msg.sender == tokenOwner,
            "removeSalePrice::Must be tokenOwner."
        );

        delete tokenSalePrices[_originContract][_tokenId][_target];

        emit SetSalePrice(
            _originContract,
            address(0),
            address(0),
            0,
            _tokenId,
            new address payable[](0),
            new uint8[](0)
        );
    }

    /// @notice Accept an offer placed on _originContract : _tokenId.
    /// @dev Zero address for _currency means that the offer being accepted is in ether.
    /// @param _originContract Contract of the asset the offer was made on.
    /// @param _tokenId TokenId of the asset.
    /// @param _currencyAddress Address of the currency used for the offer.
    /// @param _amount Amount the offer was for/and is being accepted.
    /// @param _splitAddresses Addresses to split the sellers commission with.
    /// @param _splitRatios The ratio for the split corresponding to each of the addresses being split with.
    function acceptOffer(
        address _originContract,
        uint256 _tokenId,
        address _currencyAddress,
        uint256 _amount,
        address payable[] calldata _splitAddresses,
        uint8[] calldata _splitRatios
    ) external override {
        (bool success, bytes memory data) = superRareMarketplace.delegatecall(
            abi.encodeWithSelector(
                this.acceptOffer.selector,
                _originContract,
                _tokenId,
                _currencyAddress,
                _amount,
                _splitAddresses,
                _splitRatios
            )
        );

        require(success, string(data));
    }

    /////////////////////////////////////////////////////////////////////////
    // Auction House Functions
    /////////////////////////////////////////////////////////////////////////

    /// @notice Configures an Auction for a given asset.
    /// @dev If auction type is coldie (reserve) then _startingAmount cant be 0.
    /// @dev _currencyAddress equal to the zero address denotes eth.
    /// @dev All time related params are unix epoch timestamps.
    /// @param _auctionType The type of auction being configured.
    /// @param _originContract Contract address of the asset being put up for auction.
    /// @param _tokenId Token Id of the asset.
    /// @param _startingAmount The reserve price or min bid of an auction.
    /// @param _currencyAddress The currency the auction is being conducted in.
    /// @param _lengthOfAuction The amount of time in seconds that the auction is configured for.
    /// @param _splitAddresses Addresses to split the sellers commission with.
    /// @param _splitRatios The ratio for the split corresponding to each of the addresses being split with.
    function configureAuction(
        bytes32 _auctionType,
        address _originContract,
        uint256 _tokenId,
        uint256 _startingAmount,
        address _currencyAddress,
        uint256 _lengthOfAuction,
        uint256 _startTime,
        address payable[] calldata _splitAddresses,
        uint8[] calldata _splitRatios
    ) external override {
        (bool success, bytes memory data) = superRareAuctionHouse.delegatecall(
            abi.encodeWithSelector(
                this.configureAuction.selector,
                _auctionType,
                _originContract,
                _tokenId,
                _startingAmount,
                _currencyAddress,
                _lengthOfAuction,
                _startTime,
                _splitAddresses,
                _splitRatios
            )
        );

        require(success, string(data));
    }

    /// @notice Converts an offer into a coldie auction.
    /// @dev Covers use of any currency (0 address is eth).
    /// @dev Only covers converting an offer to a coldie auction.
    /// @dev Cant convert offer if an auction currently exists.
    /// @param _originContract Contract address of the asset.
    /// @param _tokenId Token Id of the asset.
    /// @param _currencyAddress Address of the currency being converted.
    /// @param _amount Amount being converted into an auction.
    /// @param _lengthOfAuction Number of seconds the auction will last.
    /// @param _splitAddresses Addresses that the sellers take in will be split amongst.
    /// @param _splitRatios Ratios that the take in will be split by.
    function convertOfferToAuction(
        address _originContract,
        uint256 _tokenId,
        address _currencyAddress,
        uint256 _amount,
        uint256 _lengthOfAuction,
        address payable[] calldata _splitAddresses,
        uint8[] calldata _splitRatios
    ) external override {
        (bool success, bytes memory data) = superRareAuctionHouse.delegatecall(
            abi.encodeWithSelector(
                this.convertOfferToAuction.selector,
                _originContract,
                _tokenId,
                _currencyAddress,
                _amount,
                _lengthOfAuction,
                _splitAddresses,
                _splitRatios
            )
        );

        require(success, string(data));
    }

    /// @notice Cancels a configured Auction that has not started.
    /// @dev Requires the person sending the message to be the auction creator or token owner.
    /// @param _originContract Contract address of the asset pending auction.
    /// @param _tokenId Token Id of the asset.
    function cancelAuction(address _originContract, uint256 _tokenId)
        external
        override
    {
        (bool success, bytes memory data) = superRareAuctionHouse.delegatecall(
            abi.encodeWithSelector(
                this.cancelAuction.selector,
                _originContract,
                _tokenId
            )
        );

        require(success, string(data));
    }

    /// @notice Places a bid on a valid auction.
    /// @dev Only the configured currency can be used (Zero address for eth)
    /// @param _originContract Contract address of asset being bid on.
    /// @param _tokenId Token Id of the asset.
    /// @param _currencyAddress Address of currency being used to bid.
    /// @param _amount Amount of the currency being used for the bid.
    function bid(
        address _originContract,
        uint256 _tokenId,
        address _currencyAddress,
        uint256 _amount
    ) external payable override {
        (bool success, bytes memory data) = superRareAuctionHouse.delegatecall(
            abi.encodeWithSelector(
                this.bid.selector,
                _originContract,
                _tokenId,
                _currencyAddress,
                _amount
            )
        );

        require(success, string(data));
    }

    /// @notice Settles an auction that has ended.
    /// @dev Anyone is able to settle an auction since non-input params are used.
    /// @param _originContract Contract address of asset.
    /// @param _tokenId Token Id of the asset.
    function settleAuction(address _originContract, uint256 _tokenId)
        external
        override
    {
        (bool success, bytes memory data) = superRareAuctionHouse.delegatecall(
            abi.encodeWithSelector(
                this.settleAuction.selector,
                _originContract,
                _tokenId
            )
        );

        require(success, string(data));
    }

    /// @notice Grabs the current auction details for a token.
    /// @param _originContract Contract address of asset.
    /// @param _tokenId Token Id of the asset.
    /** @return Auction Struct: creatorAddress, creationTime, startingTime, lengthOfAuction,
                currencyAddress, minimumBid, auctionType, splitRecipients array, and splitRatios array.
    */
    function getAuctionDetails(address _originContract, uint256 _tokenId)
        external
        view
        override
        returns (
            address,
            uint256,
            uint256,
            uint256,
            address,
            uint256,
            bytes32,
            address payable[] memory,
            uint8[] memory
        )
    {
        Auction memory auction = tokenAuctions[_originContract][_tokenId];

        return (
            auction.auctionCreator,
            auction.creationBlock,
            auction.startingTime,
            auction.lengthOfAuction,
            auction.currencyAddress,
            auction.minimumBid,
            auction.auctionType,
            auction.splitRecipients,
            auction.splitRatios
        );
    }

    function getSalePrice(
        address _originContract,
        uint256 _tokenId,
        address _target
    )
        external
        view
        override
        returns (
            address,
            address,
            uint256,
            address payable[] memory,
            uint8[] memory
        )
    {
        SalePrice memory sp = tokenSalePrices[_originContract][_tokenId][
            _target
        ];

        return (
            sp.seller,
            sp.currencyAddress,
            sp.amount,
            sp.splitRecipients,
            sp.splitRatios
        );
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.7.0;

import "../utils/ContextUpgradeable.sol";
import "../proxy/Initializable.sol";
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
        address msgSender = _msgSender();
        _owner = msgSender;
        emit OwnershipTransferred(address(0), msgSender);
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
        emit OwnershipTransferred(_owner, address(0));
        _owner = address(0);
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        emit OwnershipTransferred(_owner, newOwner);
        _owner = newOwner;
    }
    uint256[49] private __gap;
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.7.0;
import "../proxy/Initializable.sol";

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
     * by making the `nonReentrant` function external, and make it call a
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

pragma solidity >=0.6.2 <0.8.0;

import "../../introspection/IERC165.sol";

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
    function safeTransferFrom(address from, address to, uint256 tokenId) external;

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
    function transferFrom(address from, address to, uint256 tokenId) external;

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
    function safeTransferFrom(address from, address to, uint256 tokenId, bytes calldata data) external;
}

// SPDX-License-Identifier: MIT
pragma solidity 0.7.3;

import "../../marketplace/IMarketplaceSettings.sol";
import "../../royalty/creator/IERC721CreatorRoyalty.sol";
import "../../payments/IPayments.sol";
import "../../registry/spaces/ISpaceOperatorRegistry.sol";
import "../../registry/token/IApprovedTokenRegistry.sol";
import "../../royalty/creator/IRoyaltyEngine.sol";

/// @author koloz
/// @title SuperRareBazaar Storage Contract
/// @dev STORAGE CAN ONLY BE APPENDED NOT INSERTED OR MODIFIED
contract SuperRareBazaarStorage {
    /////////////////////////////////////////////////////////////////////////
    // Constants
    /////////////////////////////////////////////////////////////////////////

    // Auction Types
    bytes32 public constant COLDIE_AUCTION = "COLDIE_AUCTION";
    bytes32 public constant SCHEDULED_AUCTION = "SCHEDULED_AUCTION";
    bytes32 public constant NO_AUCTION = bytes32(0);

    /////////////////////////////////////////////////////////////////////////
    // Structs
    /////////////////////////////////////////////////////////////////////////

    // The Offer truct for a given token:
    // buyer - address of person making the offer
    // currencyAddress - address of the erc20 token used for an offer
    //                   or the zero address for eth
    // amount - offer in wei/full erc20 value
    // marketplaceFee - the amount that is taken by the network on offer acceptance.
    struct Offer {
        address payable buyer;
        uint256 amount;
        uint256 timestamp;
        uint8 marketplaceFee;
        bool convertible;
    }

    // The Sale Price struct for a given token:
    // seller - address of the person selling the token
    // currencyAddress - address of the erc20 token used for an offer
    //                   or the zero address for eth
    // amount - offer in wei/full erc20 value
    struct SalePrice {
        address payable seller;
        address currencyAddress;
        uint256 amount;
        address payable[] splitRecipients;
        uint8[] splitRatios;
    }

    // Structure of an Auction:
    // auctionCreator - creator of the auction
    // creationBlock - time that the auction was created/configured
    // startingBlock - time that the auction starts on
    // lengthOfAuction - how long the auction is
    // currencyAddress - address of the erc20 token used for an offer
    //                   or the zero address for eth
    // minimumBid - min amount a bidder can bid at the start of an auction.
    // auctionType - type of auction, represented as the formatted bytes 32 string
    struct Auction {
        address payable auctionCreator;
        uint256 creationBlock;
        uint256 startingTime;
        uint256 lengthOfAuction;
        address currencyAddress;
        uint256 minimumBid;
        bytes32 auctionType;
        address payable[] splitRecipients;
        uint8[] splitRatios;
    }

    struct Bid {
        address payable bidder;
        address currencyAddress;
        uint256 amount;
        uint8 marketplaceFee;
    }

    /////////////////////////////////////////////////////////////////////////
    // Events
    /////////////////////////////////////////////////////////////////////////
    event Sold(
        address indexed _originContract,
        address indexed _buyer,
        address indexed _seller,
        address _currencyAddress,
        uint256 _amount,
        uint256 _tokenId
    );

    event SetSalePrice(
        address indexed _originContract,
        address indexed _currencyAddress,
        address _target,
        uint256 _amount,
        uint256 _tokenId,
        address payable[] _splitRecipients,
        uint8[] _splitRatios
    );

    event OfferPlaced(
        address indexed _originContract,
        address indexed _bidder,
        address indexed _currencyAddress,
        uint256 _amount,
        uint256 _tokenId,
        bool _convertible
    );

    event AcceptOffer(
        address indexed _originContract,
        address indexed _bidder,
        address indexed _seller,
        address _currencyAddress,
        uint256 _amount,
        uint256 _tokenId,
        address payable[] _splitAddresses,
        uint8[] _splitRatios
    );

    event CancelOffer(
        address indexed _originContract,
        address indexed _bidder,
        address indexed _currencyAddress,
        uint256 _amount,
        uint256 _tokenId
    );

    event NewAuction(
        address indexed _contractAddress,
        uint256 indexed _tokenId,
        address indexed _auctionCreator,
        address _currencyAddress,
        uint256 _startingTime,
        uint256 _minimumBid,
        uint256 _lengthOfAuction
    );

    event CancelAuction(
        address indexed _contractAddress,
        uint256 indexed _tokenId,
        address indexed _auctionCreator
    );

    event AuctionBid(
        address indexed _contractAddress,
        address indexed _bidder,
        uint256 indexed _tokenId,
        address _currencyAddress,
        uint256 _amount,
        bool _startedAuction,
        uint256 _newAuctionLength,
        address _previousBidder
    );

    event AuctionSettled(
        address indexed _contractAddress,
        address indexed _bidder,
        address _seller,
        uint256 indexed _tokenId,
        address _currencyAddress,
        uint256 _amount
    );

    /////////////////////////////////////////////////////////////////////////
    // State Variables
    /////////////////////////////////////////////////////////////////////////

    // Current marketplace settings implementation to be used
    IMarketplaceSettings public marketplaceSettings;

    // Current creator royalty implementation to be used
    IERC721CreatorRoyalty public royaltyRegistry;

    // Address of the global royalty engine being used.
    IRoyaltyEngineV1 public royaltyEngine;

    // Current SuperRareMarketplace implementation to be used
    address public superRareMarketplace;

    // Current SuperRareAuctionHouse implementation to be used
    address public superRareAuctionHouse;

    // Current SpaceOperatorRegistry implementation to be used.
    ISpaceOperatorRegistry public spaceOperatorRegistry;

    // Current ApprovedTokenRegistry implementation being used for currencies.
    IApprovedTokenRegistry public approvedTokenRegistry;

    // Current payments contract to use
    IPayments public payments;

    // Address to be used for staking registry.
    address public stakingRegistry;

    // Address of the network beneficiary
    address public networkBeneficiary;

    // A minimum increase in bid amount when out bidding someone.
    uint8 public minimumBidIncreasePercentage; // 10 = 10%

    // Maximum length that an auction can be.
    uint256 public maxAuctionLength;

    // Extension length for an auction
    uint256 public auctionLengthExtension;

    // Offer cancellation delay
    uint256 public offerCancelationDelay;

    // Mapping from contract to mapping of tokenId to mapping of target to sale price.
    mapping(address => mapping(uint256 => mapping(address => SalePrice)))
        public tokenSalePrices;

    // Mapping from contract to mapping of tokenId to mapping of currency address to Current Offer.
    mapping(address => mapping(uint256 => mapping(address => Offer)))
        public tokenCurrentOffers;

    // Mapping from contract to mapping of tokenId to Auction.
    mapping(address => mapping(uint256 => Auction)) public tokenAuctions;

    // Mapping from contract to mapping of tokenId to Bid.
    mapping(address => mapping(uint256 => Bid)) public auctionBids;

    uint256[50] private __gap;
    /// ALL NEW STORAGE MUST COME AFTER THIS
}

// SPDX-License-Identifier: MIT
pragma solidity 0.7.3;

/// @author koloz
/// @title ISuperRareBazaar
/// @notice Interface for the SuperRareBazaar Contract
interface ISuperRareBazaar {
    // Marketplace Functions
    // Buyer

    /// @notice Create an offer for a given asset
    /// @param _originContract Contract address of the asset being listed.
    /// @param _tokenId Token Id of the asset.
    /// @param _currencyAddress Address of the token being offered.
    /// @param _amount Amount being offered.
    /// @param _convertible If the offer can be converted into an auction
    function offer(
        address _originContract,
        uint256 _tokenId,
        address _currencyAddress,
        uint256 _amount,
        bool _convertible
    ) external payable;

    /// @notice Purchases the token for the current sale price.
    /// @param _originContract Contract address for asset being bought.
    /// @param _tokenId TokenId of asset being bought.
    /// @param _currencyAddress Currency address of asset being used to buy.
    /// @param _amount Amount the piece if being bought for.
    function buy(
        address _originContract,
        uint256 _tokenId,
        address _currencyAddress,
        uint256 _amount
    ) external payable;

    /// @notice Cancels an existing offer the sender has placed on a piece.
    /// @param _originContract Contract address of token.
    /// @param _tokenId TokenId that has an offer.
    /// @param _currencyAddress Currency address of the offer.
    function cancelOffer(
        address _originContract,
        uint256 _tokenId,
        address _currencyAddress
    ) external;

    // Seller

    /// @notice Sets a sale price for the given asset(s).
    /// @param _originContract Contract address of the asset being listed.
    /// @param _tokenId Token Id of the asset.
    /// @param _currencyAddress Contract address of the currency asset is being listed for.
    /// @param _listPrice Amount of the currency the asset is being listed for (including all decimal points).
    /// @param _target Address of the person this sale price is target to.
    /// @param _splitAddresses Addresses to split the sellers commission with.
    /// @param _splitRatios The ratio for the split corresponding to each of the addresses being split with.
    function setSalePrice(
        address _originContract,
        uint256 _tokenId,
        address _currencyAddress,
        uint256 _listPrice,
        address _target,
        address payable[] calldata _splitAddresses,
        uint8[] calldata _splitRatios
    ) external;

    /// @notice Removes the current sale price of an asset for the given currency.
    /// @param _originContract The origin contract of the asset.
    /// @param _tokenId The tokenId of the asset within the _originContract.
    /// @param _target The address of the person
    function removeSalePrice(
        address _originContract,
        uint256 _tokenId,
        address _target
    ) external;

    /// @notice Accept an offer placed on _originContract : _tokenId.
    /// @param _originContract Contract of the asset the offer was made on.
    /// @param _tokenId TokenId of the asset.
    /// @param _currencyAddress Address of the currency used for the offer.
    /// @param _amount Amount the offer was for/and is being accepted.
    /// @param _splitAddresses Addresses to split the sellers commission with.
    /// @param _splitRatios The ratio for the split corresponding to each of the addresses being split with.
    function acceptOffer(
        address _originContract,
        uint256 _tokenId,
        address _currencyAddress,
        uint256 _amount,
        address payable[] calldata _splitAddresses,
        uint8[] calldata _splitRatios
    ) external;

    // Auction House
    // Anyone

    /// @notice Settles an auction that has ended.
    /// @param _originContract Contract address of asset.
    /// @param _tokenId Token Id of the asset.
    function settleAuction(address _originContract, uint256 _tokenId) external;

    // Buyer

    /// @notice Places a bid on a valid auction.
    /// @param _originContract Contract address of asset being bid on.
    /// @param _tokenId Token Id of the asset.
    /// @param _currencyAddress Address of currency being used to bid.
    /// @param _amount Amount of the currency being used for the bid.
    function bid(
        address _originContract,
        uint256 _tokenId,
        address _currencyAddress,
        uint256 _amount
    ) external payable;

    // Seller

    /// @notice Configures an Auction for a given asset.
    /// @param _auctionType The type of auction being configured.
    /// @param _originContract Contract address of the asset being put up for auction.
    /// @param _tokenId Token Id of the asset.
    /// @param _startingAmount The reserve price or min bid of an auction.
    /// @param _currencyAddress The currency the auction is being conducted in.
    /// @param _lengthOfAuction The amount of time in seconds that the auction is configured for.
    /// @param _splitAddresses Addresses to split the sellers commission with.
    /// @param _splitRatios The ratio for the split corresponding to each of the addresses being split with.
    function configureAuction(
        bytes32 _auctionType,
        address _originContract,
        uint256 _tokenId,
        uint256 _startingAmount,
        address _currencyAddress,
        uint256 _lengthOfAuction,
        uint256 _startTime,
        address payable[] calldata _splitAddresses,
        uint8[] calldata _splitRatios
    ) external;

    /// @notice Cancels a configured Auction that has not started.
    /// @param _originContract Contract address of the asset pending auction.
    /// @param _tokenId Token Id of the asset.
    function cancelAuction(address _originContract, uint256 _tokenId) external;

    /// @notice Converts an offer into a coldie auction.
    /// @param _originContract Contract address of the asset.
    /// @param _tokenId Token Id of the asset.
    /// @param _currencyAddress Address of the currency being converted.
    /// @param _amount Amount being converted into an auction.
    /// @param _lengthOfAuction Number of seconds the auction will last.
    /// @param _splitAddresses Addresses that the sellers take in will be split amongst.
    /// @param _splitRatios Ratios that the take in will be split by.
    function convertOfferToAuction(
        address _originContract,
        uint256 _tokenId,
        address _currencyAddress,
        uint256 _amount,
        uint256 _lengthOfAuction,
        address payable[] calldata _splitAddresses,
        uint8[] calldata _splitRatios
    ) external;

    /// @notice Grabs the current auction details for a token.
    /// @param _originContract Contract address of asset.
    /// @param _tokenId Token Id of the asset.
    /** @return Auction Struct: creatorAddress, creationTime, startingTime, lengthOfAuction,
                currencyAddress, minimumBid, auctionType, splitRecipients array, and splitRatios array.
    */
    function getAuctionDetails(address _originContract, uint256 _tokenId)
        external
        view
        returns (
            address,
            uint256,
            uint256,
            uint256,
            address,
            uint256,
            bytes32,
            address payable[] calldata,
            uint8[] calldata
        );

    function getSalePrice(
        address _originContract,
        uint256 _tokenId,
        address _target
    )
        external
        view
        returns (
            address,
            address,
            uint256,
            address payable[] memory,
            uint8[] memory
        );
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.0 <0.8.0;
import "../proxy/Initializable.sol";

/*
 * @dev Provides information about the current execution context, including the
 * sender of the transaction and its data. While these are generally available
 * via msg.sender and msg.data, they should not be accessed in such a direct
 * manner, since when dealing with GSN meta-transactions the account sending and
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
    function _msgSender() internal view virtual returns (address payable) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes memory) {
        this; // silence state mutability warning without generating bytecode - see https://github.com/ethereum/solidity/issues/2691
        return msg.data;
    }
    uint256[50] private __gap;
}

// SPDX-License-Identifier: MIT

// solhint-disable-next-line compiler-version
pragma solidity >=0.4.24 <0.8.0;

import "../utils/AddressUpgradeable.sol";

/**
 * @dev This is a base contract to aid in writing upgradeable contracts, or any kind of contract that will be deployed
 * behind a proxy. Since a proxied contract can't have a constructor, it's common to move constructor logic to an
 * external initializer function, usually called `initialize`. It then becomes necessary to protect this initializer
 * function so it can only be called once. The {initializer} modifier provided by this contract will have this effect.
 *
 * TIP: To avoid leaving the proxy in an uninitialized state, the initializer function should be called as early as
 * possible by providing the encoded function call as the `_data` argument to {UpgradeableProxy-constructor}.
 *
 * CAUTION: When used with inheritance, manual care must be taken to not invoke a parent initializer twice, or to ensure
 * that all initializers are idempotent. This is not verified automatically as constructors are by Solidity.
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
        require(_initializing || _isConstructor() || !_initialized, "Initializable: contract is already initialized");

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

    /// @dev Returns true if and only if the function is running in the constructor
    function _isConstructor() private view returns (bool) {
        return !AddressUpgradeable.isContract(address(this));
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.7.0;

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
        // solhint-disable-next-line no-inline-assembly
        assembly { size := extcodesize(account) }
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

        // solhint-disable-next-line avoid-low-level-calls, avoid-call-value
        (bool success, ) = recipient.call{ value: amount }("");
        require(success, "Address: unable to send value, recipient may have reverted");
    }

    /**
     * @dev Performs a Solidity function call using a low level `call`. A
     * plain`call` is an unsafe replacement for a function call: use this
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
    function functionCall(address target, bytes memory data, string memory errorMessage) internal returns (bytes memory) {
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
    function functionCallWithValue(address target, bytes memory data, uint256 value) internal returns (bytes memory) {
        return functionCallWithValue(target, data, value, "Address: low-level call with value failed");
    }

    /**
     * @dev Same as {xref-Address-functionCallWithValue-address-bytes-uint256-}[`functionCallWithValue`], but
     * with `errorMessage` as a fallback revert reason when `target` reverts.
     *
     * _Available since v3.1._
     */
    function functionCallWithValue(address target, bytes memory data, uint256 value, string memory errorMessage) internal returns (bytes memory) {
        require(address(this).balance >= value, "Address: insufficient balance for call");
        require(isContract(target), "Address: call to non-contract");

        // solhint-disable-next-line avoid-low-level-calls
        (bool success, bytes memory returndata) = target.call{ value: value }(data);
        return _verifyCallResult(success, returndata, errorMessage);
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
    function functionStaticCall(address target, bytes memory data, string memory errorMessage) internal view returns (bytes memory) {
        require(isContract(target), "Address: static call to non-contract");

        // solhint-disable-next-line avoid-low-level-calls
        (bool success, bytes memory returndata) = target.staticcall(data);
        return _verifyCallResult(success, returndata, errorMessage);
    }

    function _verifyCallResult(bool success, bytes memory returndata, string memory errorMessage) private pure returns(bytes memory) {
        if (success) {
            return returndata;
        } else {
            // Look for revert reason and bubble it up if present
            if (returndata.length > 0) {
                // The easiest way to bubble the revert reason is using memory via assembly

                // solhint-disable-next-line no-inline-assembly
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

pragma solidity >=0.6.0 <0.8.0;

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
pragma solidity 0.7.3;

/**
 * @title IMarketplaceSettings Settings governing a marketplace.
 */
interface IMarketplaceSettings {
    /////////////////////////////////////////////////////////////////////////
    // Marketplace Min and Max Values
    /////////////////////////////////////////////////////////////////////////
    /**
     * @dev Get the max value to be used with the marketplace.
     * @return uint256 wei value.
     */
    function getMarketplaceMaxValue() external view returns (uint256);

    /**
     * @dev Get the max value to be used with the marketplace.
     * @return uint256 wei value.
     */
    function getMarketplaceMinValue() external view returns (uint256);

    /////////////////////////////////////////////////////////////////////////
    // Marketplace Fee
    /////////////////////////////////////////////////////////////////////////
    /**
     * @dev Get the marketplace fee percentage.
     * @return uint8 wei fee.
     */
    function getMarketplaceFeePercentage() external view returns (uint8);

    /**
     * @dev Utility function for calculating the marketplace fee for given amount of wei.
     * @param _amount uint256 wei amount.
     * @return uint256 wei fee.
     */
    function calculateMarketplaceFee(uint256 _amount)
        external
        view
        returns (uint256);

    /////////////////////////////////////////////////////////////////////////
    // Primary Sale Fee
    /////////////////////////////////////////////////////////////////////////
    /**
     * @dev Get the primary sale fee percentage for a specific ERC721 contract.
     * @param _contractAddress address ERC721Contract address.
     * @return uint8 wei primary sale fee.
     */
    function getERC721ContractPrimarySaleFeePercentage(address _contractAddress)
        external
        view
        returns (uint8);

    /**
     * @dev Utility function for calculating the primary sale fee for given amount of wei
     * @param _contractAddress address ERC721Contract address.
     * @param _amount uint256 wei amount.
     * @return uint256 wei fee.
     */
    function calculatePrimarySaleFee(address _contractAddress, uint256 _amount)
        external
        view
        returns (uint256);

    /**
     * @dev Check whether the ERC721 token has sold at least once.
     * @param _contractAddress address ERC721Contract address.
     * @param _tokenId uint256 token ID.
     * @return bool of whether the token has sold.
     */
    function hasERC721TokenSold(address _contractAddress, uint256 _tokenId)
        external
        view
        returns (bool);

    /**
     * @dev Mark a token as sold.
     * Requirements:
     *
     * - `_contractAddress` cannot be the zero address.
     * @param _contractAddress address ERC721Contract address.
     * @param _tokenId uint256 token ID.
     * @param _hasSold bool of whether the token should be marked sold or not.
     */
    function markERC721Token(
        address _contractAddress,
        uint256 _tokenId,
        bool _hasSold
    ) external;

    function setERC721ContractPrimarySaleFeePercentage(
        address _contractAddress,
        uint8 _percentage
    ) external;
}

// SPDX-License-Identifier: MIT
pragma solidity 0.7.3;

import "../../token/ERC721/IERC721TokenCreator.sol";

/**
 * @title IERC721CreatorRoyalty Token level royalty interface.
 */
interface IERC721CreatorRoyalty is IERC721TokenCreator {
    /**
     * @dev Get the royalty fee percentage for a specific ERC721 contract.
     * @param _contractAddress address ERC721Contract address.
     * @param _tokenId uint256 token ID.
     * @return uint8 wei royalty fee.
     */
    function getERC721TokenRoyaltyPercentage(
        address _contractAddress,
        uint256 _tokenId
    ) external view returns (uint8);

    /**
     * @dev Utililty function to calculate the royalty fee for a token.
     * @param _contractAddress address ERC721Contract address.
     * @param _tokenId uint256 token ID.
     * @param _amount uint256 wei amount.
     * @return uint256 wei fee.
     */
    function calculateRoyaltyFee(
        address _contractAddress,
        uint256 _tokenId,
        uint256 _amount
    ) external view returns (uint256);

    /**
     * @dev Utililty function to set the royalty percentage for a specific ERC721 contract.
     * @param _contractAddress address ERC721Contract address.
     * @param _percentage percentage for royalty
     */
    function setPercentageForSetERC721ContractRoyalty(
        address _contractAddress,
        uint8 _percentage
    ) external;
}

// SPDX-License-Identifier: MIT
pragma solidity 0.7.3;

/// @author koloz
/// @title IPayments
/// @notice Interface for the Payments contract used.
interface IPayments {
    function refund(address _payee, uint256 _amount) external payable;

    function payout(address[] calldata _splits, uint256[] calldata _amounts)
        external
        payable;
}

// SPDX-License-Identifier: MIT
pragma solidity 0.7.3;

/// @author koloz
/// @title ISpaceOperatorRegistry
/// @notice The interface for the SpaceOperatorRegistry
interface ISpaceOperatorRegistry {
    function getPlatformCommission(address _operator)
        external
        view
        returns (uint8);

    function setPlatformCommission(address _operator, uint8 _commission)
        external;

    function isApprovedSpaceOperator(address _operator)
        external
        view
        returns (bool);

    function setSpaceOperatorApproved(address _operator, bool _approved)
        external;
}

// SPDX-License-Identifier: MIT
pragma solidity 0.7.3;

interface IApprovedTokenRegistry {
    /// @notice Returns if a token has been approved or not.
    /// @param _tokenContract Contract of token being checked.
    /// @return True if the token is allowed, false otherwise.
    function isApprovedToken(address _tokenContract)
        external
        view
        returns (bool);

    /// @notice Adds a token to the list of approved tokens.
    /// @param _tokenContract Contract of token being approved.
    function addApprovedToken(address _tokenContract) external;

    /// @notice Removes a token from the approved tokens list.
    /// @param _tokenContract Contract of token being approved.
    function removeApprovedToken(address _tokenContract) external;

    /// @notice Sets whether all token contracts should be approved.
    /// @param _allTokensApproved Bool denoting if all tokens should be approved.
    function setAllTokensApproved(bool _allTokensApproved) external;
}

// SPDX-License-Identifier: MIT
pragma solidity 0.7.3;

/// @author: manifold.xyz

/**
 * @dev Lookup engine interface
 */
interface IRoyaltyEngineV1 {
    /**
     * Get the royalty for a given token (address, id) and value amount.  Does not cache the bps/amounts.  Caches the spec for a given token address
     *
     * @param tokenAddress - The address of the token
     * @param tokenId      - The id of the token
     * @param value        - The value you wish to get the royalty of
     *
     * returns Two arrays of equal length, royalty recipients and the corresponding amount each recipient should get
     */
    function getRoyalty(
        address tokenAddress,
        uint256 tokenId,
        uint256 value
    )
        external
        returns (address payable[] memory recipients, uint256[] memory amounts);

    /**
     * View only version of getRoyalty
     *
     * @param tokenAddress - The address of the token
     * @param tokenId      - The id of the token
     * @param value        - The value you wish to get the royalty of
     *
     * returns Two arrays of equal length, royalty recipients and the corresponding amount each recipient should get
     */
    function getRoyaltyView(
        address tokenAddress,
        uint256 tokenId,
        uint256 value
    )
        external
        view
        returns (address payable[] memory recipients, uint256[] memory amounts);
}

// SPDX-License-Identifier: MIT
pragma solidity 0.7.3;

interface IERC721TokenCreator {
    function tokenCreator(address _contractAddress, uint256 _tokenId)
        external
        view
        returns (address payable);
}