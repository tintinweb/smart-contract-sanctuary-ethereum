// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.7;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import "@chainlink/contracts/src/v0.8/interfaces/AggregatorV3Interface.sol";

/// @notice Thrown when state of contract is equal to the one specified
error NftMarketplace__StateIsNot(uint256 state);
/// @notice Thrown when state of contract is not equal to the one specified
error NftMarketplace__StateIs(uint256 state);
/// @notice Thrown when the token (erc20) is not listed as payment token
error NftMarketplace__TokenNotListed(address tokenAddress);
/// @notice Thrown when price is below or equal to zero
error NftMarketplace__PriceMustBeAboveZero();
/// @notice Thrown when market is not approved to transfer `tokenId` of `nftAddress`
error NftMarketplace__NotApprovedForNft(address nftAddress, uint256 tokenId);
/// @notice Thrown when `tokenId` of `nftAddress` is already listed on market
error NftMarketplace__AlreadyListed(address nftAddress, uint256 tokenId);
/// @notice Thrown when `tokenId` of `nftAddress` is not listed on market
error NftMarketplace__NftNotListed(address nftAddress, uint256 tokenId);
/// @notice Thrown when caller is not owner of `tokenId` at `nftAddress`
error NftMarketplace__NotOwnerOfNft(address nftAddress, uint256 tokenId);
/// @notice Thrown when caller does not send enough eth to market
error NftMarketplace__NotEnoughFunds();
/// @notice Thrown when allowance of market is less than required
error NftMarketplace__NotEnoughAllowance();
/// @notice Thrown when erc20 token transfer failed
error NftMarketplace__TokenTransferFailed(address tokenAddress);
/// @notice Thrown when eth transfer failed
error NftMarketplace__EthTransferFailed();
/// @notice Thrown when caller has no eligible funds for withdrawal
error NftMarketplace__NoEligibleFunds();

/**
 * @title NftMarketplace
 * @author Philipp Keinberger
 * @notice This contract is an nft marketplace, where users can list (sell) and buy
 * nfts using eth and erc20 tokens. Payment tokens (e.g. erc20-tokens, accepted by
 * the marketplace as payment for nfts) can be added and removed through access-
 * restricted functions, favourably controlled by a governor contract (e.g. dao) to
 * allow for decentralized governance of the marketplace. The contract is designed
 * to be upgradeable.
 * @dev This contract implements the IERC721 and IERC20 Openzeppelin interfaces for the
 * ERC721 and ERC20 token standards.
 *
 * The Marketplace implements Chainlink price feeds to retrieve prices of listed erc20
 * payment tokens.
 *
 * This contract inherits from Openzeppelins OwnableUpgradeable contract in order to
 * allow owner features, while still keeping upgradeablity functionality. The
 * Marketplace is designed to be deployed through a proxy contract to allow for future
 * upgrades of the contract.
 */
contract NftMarketplace is OwnableUpgradeable {
    /**
     * @dev Defines the state of the contract, allows for state restricted functionality
     * of the contract
     */
    enum MarketState {
        CLOSED,
        UPDATING,
        OPEN
    }

    /// @dev Defines the data structure for a listing (listed nft) on the market
    struct Listing {
        address seller;
        uint256 nftPrice;
        /**
         * @dev Specifies payment tokens accepted by the seller as payments (have to be
         * listed as paymentTokens in `s_paymentTokens`)
         */
        address[] paymentTokenAddresses;
    }

    /**
     * @dev Defines the data structure for a payment token (erc20) to be used as payment
     * for listed nfts
     */
    struct PaymentToken {
        address priceFeedAddress;
        uint8 decimals;
    }

    MarketState private s_marketState;
    /// @dev nftContractAddress => nftTokenId => Listing
    mapping(address => mapping(uint256 => Listing)) private s_listings;
    /// @dev userAddress to eligible eth (in wei) for withdrawal
    mapping(address => uint256) private s_eligibleFunds;
    /// @dev erc20ContractAddress => PaymentToken
    mapping(address => PaymentToken) private s_paymentTokens;

    /// @notice Event emitted when a new nft is listed on the market
    event NftListed(
        address indexed seller,
        address indexed nftAddr,
        uint256 indexed tokenId,
        uint256 price,
        address[] tokensForPayment
    );
    /// @notice Event emitted when an nft is delisted by the seller
    event NftDelisted(address indexed nftAddr, uint256 indexed tokenId);
    /// @notice Event emitted when seller updates the price of an nft
    event NftPriceUpdated(address indexed nftAddr, uint256 indexed tokenId, uint256 indexed price);
    /// @notice Event emitted when seller updates an erc20 token accepted as payment for the nft
    event NftPaymentTokenUpdated(
        address indexed nftAddr,
        uint256 indexed tokenId,
        uint256 indexed indexUpdated,
        address paymentTokenAddress
    );
    /// @notice Event emitted when an nft is bought
    event NftBought(address nftAddr, uint256 tokenId, address indexed buyer, uint256 indexed price);

    /// @notice Event emitted when a new payment token gets added to the market
    event PaymentTokenAdded(address tokenAddress);
    /// @notice Event emitted when a payment token is removed from the market
    event PaymentTokenRemoved(address tokenAddress);

    /// @notice Checks if market state is equal to `state`
    modifier stateIs(MarketState state) {
        if (state != s_marketState) revert NftMarketplace__StateIsNot(uint256(state));
        _;
    }

    /// @notice Checks if market state is not equal to `state`
    modifier stateIsNot(MarketState state) {
        if (state == s_marketState) revert NftMarketplace__StateIs(uint256(state));
        _;
    }

    /// @notice Checks if nft `tokenId` of `nftAddr` is listed on market
    modifier isListed(address nftAddr, uint256 tokenId) {
        Listing memory l_listing = s_listings[nftAddr][tokenId];
        if (l_listing.nftPrice <= 0) revert NftMarketplace__NftNotListed(nftAddr, tokenId);
        _;
    }

    /// @notice Checks if `shouldBeOwner` is owner of `tokenId` at `nftAddr`
    modifier isNftOwner(
        address shouldBeOwner,
        address nftAddr,
        uint256 tokenId
    ) {
        IERC721 nft = IERC721(nftAddr);
        if (nft.ownerOf(tokenId) != shouldBeOwner)
            revert NftMarketplace__NotOwnerOfNft(nftAddr, tokenId);
        _;
    }

    /// @notice ensures that initialize can only be called through proxy
    constructor() {
        _disableInitializers();
    }

    /**
     * @dev Initializer function which replaces constructor for upgradeability functionality.
     * Sets the msg.sender as owner
     */
    function initialize() public initializer {
        __Ownable_init();
    }

    /**
     * @notice Function for setting the state of the marketplace
     * @param newState Is the new value for the state
     * @dev This function can only be called by the owner
     */
    function setState(MarketState newState) external onlyOwner {
        s_marketState = newState;
    }

    /**
     * @notice Function for adding a payment token (erc20) as payment method for nft
     * purchases using erc20 tokens
     * @param tokenAddress Is the address of the erc20 contract
     * @param priceFeedAddress Is the address of the chainlink price feed for the
     * erc20
     * @param decimals Is the amount of decimals returned by the chainlink price
     * feed
     * @dev This function reverts if the market is CLOSED or the caller is not
     * the owner of the marketplace.
     *
     * Checking if the tokenAddress indeed implements the IERC20 interface is not
     * provided since the function can only be called by the owner, while the owner
     * should be trustworthy enough to check for that beforehand. Main reason for
     * that is gas savings.
     *
     * This function emits the {PaymentTokenAdded} event.
     */
    function addPaymentToken(
        address tokenAddress,
        address priceFeedAddress,
        uint8 decimals
    ) external onlyOwner stateIsNot(MarketState.CLOSED) {
        s_paymentTokens[tokenAddress] = PaymentToken(priceFeedAddress, decimals);

        emit PaymentTokenAdded(tokenAddress);
    }

    /**
     * @notice Function for removing a payment token from the contract
     * @param tokenAddress Is the address of the payment token (erc20) to be removed
     * @dev This function reverts if the market is CLOSED or the caller is not
     * the owner of the marketplace.
     *
     * This function emits the {PaymentTokenRemoved} event.
     */
    function removePaymentToken(address tokenAddress)
        external
        onlyOwner
        stateIsNot(MarketState.CLOSED)
    {
        delete s_paymentTokens[tokenAddress];

        emit PaymentTokenRemoved(tokenAddress);
    }

    /**
     * @notice Function for listing an nft on the marketplace
     * @param nftAddr Is the address of the nft contract
     * @param tokenId Is the token id of the nft
     * @param nftPrice Is the price set by msg.sender for the listing
     * @param allowedPaymentTokens Are payment tokens allowed as
     * payment methods for the nft (optional)
     * @dev This function reverts if the market is not OPEN, the caller is
     * not the owner of `tokenId` at `nftAddr`, or the marketplace is not
     * approved to transfer the nft. The function also reverts if
     * `allowedPaymentTokens` contains an erc20-token, which is not added as
     * a paymentToken on the marketplace. If `allowedPaymentTokens` are not
     * specified, the nft will only be able to be sold using the buyNftEth
     * function.
     *
     * This implementation still lets sellers hold their nft until
     * the item actually gets sold. The buyNft functions will check for
     * allowance to spend the nft still being present when called.
     * This function emits the {NftListed} event.
     */
    function listNft(
        address nftAddr,
        uint256 tokenId,
        uint256 nftPrice,
        address[] calldata allowedPaymentTokens
    ) external stateIs(MarketState.OPEN) isNftOwner(msg.sender, nftAddr, tokenId) {
        IERC721 nft = IERC721(nftAddr);
        if (nft.getApproved(tokenId) != address(this))
            revert NftMarketplace__NotApprovedForNft(nftAddr, tokenId);

        uint256 alreadylistedPrice = s_listings[nftAddr][tokenId].nftPrice;
        if (alreadylistedPrice > 0) revert NftMarketplace__AlreadyListed(nftAddr, tokenId);
        if (nftPrice <= 0) revert NftMarketplace__PriceMustBeAboveZero();

        for (uint256 index = 0; index < allowedPaymentTokens.length; index++) {
            address l_address = allowedPaymentTokens[index];
            PaymentToken memory l_paymentToken = s_paymentTokens[l_address];
            if (l_paymentToken.decimals == 0) revert NftMarketplace__TokenNotListed(l_address);
        }

        s_listings[nftAddr][tokenId] = Listing(msg.sender, nftPrice, allowedPaymentTokens);
        emit NftListed(msg.sender, nftAddr, tokenId, nftPrice, allowedPaymentTokens);
    }

    /**
     * @notice Function for cancelling a listing on the marketplace
     * @param nftAddr Is the address of the nft contract
     * @param tokenId Is the id of the nft
     * @dev This function reverts if the market is not OPEN, the caller
     * is not the owner of `tokenId` at `nftAddr`, or the nft is not
     * listed on the marketplace.
     *
     * This implementation only deletes the listing from the
     * mapping. Sellers have to revoke approval rights for their nft
     * on their own or through a frontend application.
     * This function emits the {NftDelisted} event.
     */
    function cancelListing(address nftAddr, uint256 tokenId)
        external
        stateIs(MarketState.OPEN)
        isNftOwner(msg.sender, nftAddr, tokenId)
        isListed(nftAddr, tokenId)
    {
        delete s_listings[nftAddr][tokenId];

        emit NftDelisted(nftAddr, tokenId);
    }

    /**
     * @notice Function for updating the price of the listing on the marketplace
     * @param nftAddr Is the address of the nft contract
     * @param tokenId Is the id of the nft
     * @param newPrice Is the new price for the nft
     * @dev This function reverts if the market is not OPEN, the caller
     * is not the owner of `tokenId` at `nftAddr`, or the nft is not
     * listed on the marketplace.
     *
     * This function emits the {NftPriceUpdated} event.
     */
    function updateListingPrice(
        address nftAddr,
        uint256 tokenId,
        uint256 newPrice
    )
        external
        stateIs(MarketState.OPEN)
        isNftOwner(msg.sender, nftAddr, tokenId)
        isListed(nftAddr, tokenId)
    {
        if (newPrice <= 0) revert NftMarketplace__PriceMustBeAboveZero();

        s_listings[nftAddr][tokenId].nftPrice = newPrice;
        emit NftPriceUpdated(nftAddr, tokenId, newPrice);
    }

    /**
     * @notice Function for updating a payment token (erc20 token allowed
     * as payment method) of an nft listed on the marketplace.
     * @param nftAddr Is the address of the nft contract
     * @param tokenId Is the id of the nft
     * @param indexToUpdate Is the index of the paymentToken in the
     * Listing.paymentTokenAddresses array
     * @param paymentTokenAddress Is the new address as replacement for the
     * old paymentTokenAddress
     * @dev This function reverts if the market is not OPEN, the caller
     * is not the owner of `tokenId` at `nftAddr`, or the nft is not
     * listed on the marketplace. The function also reverts if the
     * `paymentTokenAddress` is not allowed to be used as a paymentToken by
     * the contract. (not part of `s_paymentTokens`)
     *
     * This function emits the {NftPaymentTokenUpdated} event.
     */
    function updateListingPaymentToken(
        address nftAddr,
        uint256 tokenId,
        uint256 indexToUpdate,
        address paymentTokenAddress
    )
        external
        stateIs(MarketState.OPEN)
        isNftOwner(msg.sender, nftAddr, tokenId)
        isListed(nftAddr, tokenId)
    {
        if (s_paymentTokens[paymentTokenAddress].decimals == 0)
            revert NftMarketplace__TokenNotListed(paymentTokenAddress);

        s_listings[nftAddr][tokenId].paymentTokenAddresses[indexToUpdate] = paymentTokenAddress;
        emit NftPaymentTokenUpdated(nftAddr, tokenId, indexToUpdate, paymentTokenAddress);
    }

    /**
     * @notice Function for buying an nft on the marketplace with eth
     * @param nftAddr Is the address of the nft contract
     * @param tokenId Is the id of the nft
     * @dev This function reverts if the market is not OPEN, the nft
     * is not listed on the marketplace, the marketplace is not approved
     * to transfer the nft or the amount of eth sent to the marketplace is
     * smaller than the price of the nft.
     *
     * This implementation will transfer the nft to the buyer directly,
     * while granting the seller address the right to withdraw the eth
     * amount sent by the buyer to the marketplace by calling the
     * withdrawFunds function. Checking the amount of eligible funds
     * for withdrawal can be done by calling getEligibleFunds.
     *
     * This function emits the {NftBought} event.
     */
    function buyNftEth(address nftAddr, uint256 tokenId)
        external
        payable
        stateIs(MarketState.OPEN)
        isListed(nftAddr, tokenId)
    {
        IERC721 nft = IERC721(nftAddr);
        if (nft.getApproved(tokenId) != address(this))
            revert NftMarketplace__NotApprovedForNft(nftAddr, tokenId);

        Listing memory l_listing = s_listings[nftAddr][tokenId];

        if (msg.value < l_listing.nftPrice) revert NftMarketplace__NotEnoughFunds();

        delete s_listings[nftAddr][tokenId];

        s_eligibleFunds[l_listing.seller] += msg.value;

        nft.safeTransferFrom(l_listing.seller, msg.sender, tokenId);

        emit NftBought(nftAddr, tokenId, msg.sender, l_listing.nftPrice);
    }

    /**
     * @notice Function for buying an nft on the marketplace with an erc20
     * (payment) token.
     * @param nftAddr Is the address of the nft contract
     * @param tokenId Is the id of the nft
     * @param paymentTokenIndex Is the index of the paymentToken in the
     * Listing.paymentTokenAddresses array
     * @dev This function reverts if the market is not OPEN, the nft
     * is not listed on the marketplace or the marketplace, the marketplace
     * is not approved to spend the nft or the approved token amount by
     * buyer is smaller than the amount of tokens required to pay for the
     * nft.
     *
     * The amount of tokens needed of paymentToken at index `paymentTokenIndex`
     * is retrieved from the getTokenAmountFromEthAmount function, which converts
     * the price (eth in wei) to the token amount (in wei) using Chainlink
     * price feeds.
     *
     * This implementation will transfer the nft to the buyer directly,
     * while also transferring the amount of tokens paid directly to the
     * seller. If the transfer of the erc20 tokens fails, the function
     * is reverted (nft will not be transferred to buyer).
     *
     * This function emits the {NftBought} event.
     */
    function buyNftErc20(
        address nftAddr,
        uint256 tokenId,
        uint256 paymentTokenIndex
    ) external stateIs(MarketState.OPEN) isListed(nftAddr, tokenId) {
        IERC721 nft = IERC721(nftAddr);
        if (nft.getApproved(tokenId) != address(this))
            revert NftMarketplace__NotApprovedForNft(nftAddr, tokenId);

        Listing memory l_listing = s_listings[nftAddr][tokenId];

        address erc20TokenAddress = l_listing.paymentTokenAddresses[paymentTokenIndex];

        uint256 requiredTokenAllowance = getTokenAmountFromEthAmount(
            l_listing.nftPrice,
            erc20TokenAddress
        );

        IERC20 erc20Token = IERC20(erc20TokenAddress);
        uint256 allowance = erc20Token.allowance(msg.sender, address(this));

        if (allowance < requiredTokenAllowance) revert NftMarketplace__NotEnoughAllowance();

        delete s_listings[nftAddr][tokenId];

        if (!erc20Token.transferFrom(msg.sender, l_listing.seller, requiredTokenAllowance))
            revert NftMarketplace__TokenTransferFailed(erc20TokenAddress);

        nft.safeTransferFrom(l_listing.seller, msg.sender, tokenId);

        emit NftBought(nftAddr, tokenId, msg.sender, l_listing.nftPrice);
    }

    /**
     * @notice Function for withdrawing eth from the marketplace, if eligible
     * funds is greater than zero (only after purchases with eth)
     * @dev This function reverts if the market is CLOSED or if there are no
     * eligible funds of the caller to withdraw.
     */
    function withdrawFunds() external stateIsNot(MarketState.CLOSED) {
        uint256 amount = s_eligibleFunds[msg.sender];
        if (amount <= 0) revert NftMarketplace__NoEligibleFunds();

        s_eligibleFunds[msg.sender] = 0;
        (bool sent, ) = payable(msg.sender).call{value: amount}("");
        if (!sent) revert NftMarketplace__EthTransferFailed();
    }

    /**
     * @notice Function for converting `ethAmount` to amount of tokens using
     * Chainlink price feeds
     * @param ethAmount Amount of eth (in wei) to be converted
     * @param tokenAddress Is the address of the erc20 token
     * @return Token amount (in wei)
     * @dev This function reverts if the `tokenAddress` is not listed as a
     * paymentToken.
     *
     * This implementation returns the token amount in wei (18 decimals).
     */
    function getTokenAmountFromEthAmount(uint256 ethAmount, address tokenAddress)
        public
        view
        returns (uint256)
    {
        PaymentToken memory l_paymentToken = s_paymentTokens[tokenAddress];

        if (l_paymentToken.priceFeedAddress == address(0))
            revert NftMarketplace__TokenNotListed(tokenAddress);

        AggregatorV3Interface priceFeed = AggregatorV3Interface(l_paymentToken.priceFeedAddress);
        (, int256 ercPrice, , , ) = priceFeed.latestRoundData();

        uint256 power = 18 - l_paymentToken.decimals;
        uint256 decimalAdjustedErcPrice = uint256(ercPrice) * (10**power);
        return (decimalAdjustedErcPrice * ethAmount) / 1e18;
    }

    /**
     * @notice This function returns the current MarketState of the
     * marketplace
     * @return State of the marketplace
     */
    function getState() public view returns (MarketState) {
        return s_marketState;
    }

    /**
     * @notice This function returns the current Listing of `tokenId`
     * at `nftAddr` (if existing)
     * @param nftAddr Is the address of the nft contract
     * @param tokenId Is the id of the nft
     * @return Listing of `tokenId` at `nftAddr`
     */
    function getListing(address nftAddr, uint256 tokenId) public view returns (Listing memory) {
        return s_listings[nftAddr][tokenId];
    }

    /**
     * @notice Function for looking up the amount of eligible funds
     * that can be withdrawn
     * @param addr Is the address to be looked up
     * @return Eligible funds of `addr` for withdrawal from
     * marketplace
     */
    function getEligibleFunds(address addr) public view returns (uint256) {
        return s_eligibleFunds[addr];
    }

    /**
     * @notice Function for looking up payment token of marketplace
     * @param addr Is the contract address of the payment token
     * @return PaymentToken of `addr`
     */
    function getPaymentToken(address addr) public view returns (PaymentToken memory) {
        return s_paymentTokens[addr];
    }

    /**
     * @notice Function for retrieving version of marketplace
     * @return Version
     */
    function getVersion() public pure returns (uint8) {
        return 1;
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.6.0) (token/ERC20/IERC20.sol)

pragma solidity ^0.8.0;

/**
 * @dev Interface of the ERC20 standard as defined in the EIP.
 */
interface IERC20 {
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
// OpenZeppelin Contracts (last updated v4.7.0) (proxy/utils/Initializable.sol)

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
     * `onlyInitializing` functions can be used to initialize parent contracts. Equivalent to `reinitializer(1)`.
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
     * `initializer` is equivalent to `reinitializer(1)`, so a reinitializer may be used after the original
     * initialization step. This is essential to configure modules that are added through upgrades and that require
     * initialization.
     *
     * Note that versions can jump in increments greater than 1; this implies that if multiple reinitializers coexist in
     * a contract, executing them in the right order is up to the developer or operator.
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
     */
    function _disableInitializers() internal virtual {
        require(!_initializing, "Initializable: contract is initializing");
        if (_initialized < type(uint8).max) {
            _initialized = type(uint8).max;
            emit Initialized(type(uint8).max);
        }
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (utils/Address.sol)

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