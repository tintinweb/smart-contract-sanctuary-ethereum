// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.7;

import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC1155/IERC1155.sol";
import "@openzeppelin/contracts/utils/Counters.sol";
import "./Interfaces/IERC721Transferable.sol";
import "./Interfaces/IERC1155Transferable.sol";
import "@openzeppelin/contracts-upgradeable/security/ReentrancyGuardUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";

/**
 * @title MachoMarket
 * @notice This contract allows you to buy and sell tokens that have been approved by the contract owner.
 * @dev This marketplace supports four types of tokens (ERC721, ERC721Transferable, ERC1155, ERC1155Transferable). The 'Transferable' extension
 * has been created to allow approved contracts to change the 'transferable' status of the token's stored in these 'Transferable' contracts. This marketplace does not
 * gain ownership of any tokens when a user creates a listing but simply creates a listing for an item and changes it's transferable status (if applicable).
 *
 */
contract MachoMarket is
    Initializable,
    OwnableUpgradeable,
    ReentrancyGuardUpgradeable
{
    using Counters for Counters.Counter;

    Counters.Counter public nextListingId;

    /// @notice The fee for each sale. '100' would represent 1% (100/BASIS_POINTS) = 0.01 where BASIS_POINTS = 10,000
    uint256 public fee;

    /// @notice The address that will recieve the fees
    address public feeRecipient;

    /// @notice Used as the denominator when figuring a fee percentage (10,000 points makes up 100%)
    uint16 public constant BASIS_POINTS = 10000;

    /// @notice The minimum price an item can be listed for (equivalent to '0.000000001' if there are 18 decimal places)
    uint256 public constant MIN_PRICE = 1e9;

    /// @notice The maximum fee that is allowed to be set (10%)
    uint256 public constant MAX_FEE = 1000;

    /// @notice Used to correspond an id to a currency, maps: an id to a Currency
    mapping(uint256 => Currency) public idToCurrency;

    /// @notice Used to check if a currencyId has been set, maps: currency id to bool
    mapping(uint256 => bool) public currIdToApproved;

    /// @notice Used to check if an address has been created as a currency, maps: ERC20/ERC1155 contract to bool
    mapping(address => bool) public isAcceptedCurrency;

    /// @notice Used to check if a contract is allowed to list, maps: ERC721/ERC1155 contract to bool
    mapping(address => bool) public approvedItemContracts;

    /// @notice Used to know what ERC type a contract is, maps: ERC721/ERC1155 contract to its type
    mapping(address => ContractType) public contractTypes;

    /// @notice Used to retrieve a market item given a listing id, maps: listing id to marketItem
    mapping(uint256 => MarketItem) public idToMarketItems;

    /// @notice Used to check if a specific token is already listed, maps: nft address to tokenId to bool
    mapping(address => mapping(uint256 => bool)) public isItemListed;

    /// @notice Used to check if a specific ERC1155 token is already listed by a user and how much they have listed already, maps: nft address to user address to tokenId to token amount
    mapping(address => mapping(address => mapping(uint256 => uint256)))
        public amountOf1155Listed;

    /// @notice Used to check if an ERC1155 contract has already used a certain tokenId as currency, maps: ERC1155 address to tokenId to bool
    mapping(address => mapping(uint256 => bool)) public isUsedPurchaseId;

    /// @notice Used to get the fee information for contracts that are allowed to list, maps: item contract address to fee information
    mapping(address => FeeInfo) public contractToFee;

    struct Currency {
        /// @dev Contract address of the currency
        address tokenAddress;
        /// @dev The type of contract that the currency is
        CurrencyType currencyType;
        /// @dev The tokenId of the currency in the contract (only applicable to ERC1155)
        uint256 tokenId;
    }

    struct MarketItem {
        /// @dev The tokenId of the token in the 'itemAddress' contract
        uint256 tokenId;
        /// @dev The amount of tokens listed (only applicable to ERC1155)
        uint256 itemQuantity;
        /// @dev The price in units of the currency
        uint256 itemPrice;
        /// @dev The id of the currency to use when a buyer wants to purchase the market item
        uint256 currencyId;
        /// @dev The contract address of the item that is listed
        address itemAddress;
        /// @dev The address of the user who created the market item
        address itemOwner;
        /// @dev Whether or not the market item is currently listed
        bool isListed;
    }

    struct FeeInfo {
        /// @dev The address that should recieve the fee
        address recipient;
        /// @dev The percentage of the transaction the fee will be for out of 'BASIS_POINTS'.
        uint32 feeAmount;
    }

    enum CurrencyType {
        Ether,
        ERC20,
        ERC1155
    }

    /// @dev The type that an item contract will be
    enum ContractType {
        ERC721T,
        ERC721,
        ERC1155T,
        ERC1155
    }

    /// @notice A new listing has been created
    /// @param listingId The listingId that is associated with the new listing
    event NewListing(uint256 listingId);

    /// @notice A listing has been updated
    /// @param listingId The listingId that is associated with the updated listing
    event ListingUpdated(uint256 listingId);

    /// @notice A listing has been purchased
    /// @param listingId The listingId that is associated with the purchased listing
    event ListingPurchased(uint256 listingId);

    /// @notice A listing has been removed
    /// @param listingId The listingId that is associated with the removed listing
    event ListingRemoved(uint256 listingId);

    function initialize() public initializer {
        __ReentrancyGuard_init_unchained();
        __Ownable_init_unchained();
        idToCurrency[0] = Currency(address(0), CurrencyType.Ether, 0);
        currIdToApproved[0] = true;
        feeRecipient = address(0xf8c2099B8F5403356ACA29cB5aFFf4f861D7fd99);
        fee = 500;
    }

    /** @dev Retrieves a market item through a listingId
     * @param listingId The ID of the listing to retrieve
     */
    function getMarketItem(uint256 listingId)
        public
        view
        returns (MarketItem memory)
    {
        require(
            listingId < nextListingId.current(),
            "MachoMarket: Invalid item Id"
        );
        return idToMarketItems[listingId];
    }

    /** @dev Lists an item to the marketplace
     * @param tokenId The ID of the token to list
     * @param nftAddress The address of the contract in which the token belongs
     * @param nftAmount The amount of the token to list (only applicable to ERC1155)
     * @param currencyId The ID of the currency that the item will be sold in
     * @param currencyAmount The amount of currency that is to be used to purchase this item
     */
    function listItem(
        uint256 tokenId,
        address nftAddress,
        uint256 nftAmount,
        uint256 currencyId,
        uint256 currencyAmount
    ) external nonReentrant {
        require(
            approvedItemContracts[nftAddress],
            "MachoMarket: Contract is not allowed to list items"
        );
        require(
            !isItemListed[nftAddress][tokenId],
            "MachoMarket: Item is already listed"
        );
        require(
            currIdToApproved[currencyId],
            "MachoMarket: Currency ID is not supported"
        );
        uint256 listingId = nextListingId.current();
        ContractType contractType = contractTypes[nftAddress];
        if (contractType == ContractType.ERC721T) {
            _listERC721T(
                tokenId,
                currencyId,
                currencyAmount,
                listingId,
                msg.sender,
                nftAddress,
                false
            );
        } else if (contractType == ContractType.ERC721) {
            _listERC721(
                tokenId,
                currencyId,
                currencyAmount,
                listingId,
                msg.sender,
                nftAddress,
                false
            );
        } else if (contractType == ContractType.ERC1155T) {
            _listERC1155T(
                tokenId,
                currencyId,
                currencyAmount,
                listingId,
                nftAmount,
                msg.sender,
                nftAddress
            );
        } else if (contractType == ContractType.ERC1155) {
            _listERC1155(
                tokenId,
                currencyId,
                currencyAmount,
                listingId,
                nftAmount,
                msg.sender,
                nftAddress
            );
        }

        nextListingId.increment();
        emit NewListing(listingId);
    }

    /** @dev Checks all the requirements for an ERC721T before handing off the listing to '_list'
     * @param tokenId The ID of the token to list
     * @param currencyId The ID of the currency that is to be used to purchase this item
     * @param currencyAmount The amount of currency that is to be used to purchase this item
     * @param listingId The ID that will be used to define this listing in the mapping
     * @param sender The user's address that is making this listing
     * @param nftAddress The address of the contract in which the item belongs
     * @param currencyId The ID of the currency that the item will be sold in
     * @param listingUpdate Whether or not this function was called to create a listing (false) or update a listing (true)
     */
    function _listERC721T(
        uint256 tokenId,
        uint256 currencyId,
        uint256 currencyAmount,
        uint256 listingId,
        address sender,
        address nftAddress,
        bool listingUpdate
    ) internal {
        IERC721Transferable nftContract = IERC721Transferable(nftAddress);
        require(
            nftContract.ownerOf(tokenId) == sender,
            "MachoMarket: Sender is not owner of token"
        );
        require(
            nftContract.isTransferable(tokenId) ||
                isItemListed[nftAddress][tokenId] == listingUpdate,
            "MachoMarket: NFT is not transferable"
        );
        require(
            nftContract.isApprovedForAll(msg.sender, address(this)),
            "MachoMarket: Market is not approved to handle your tokens"
        );

        nftContract.setTransferable(tokenId, false);

        _list(
            tokenId,
            currencyId,
            currencyAmount,
            listingId,
            1,
            sender,
            nftAddress
        );

        isItemListed[nftAddress][tokenId] = true;
    }

    /** @dev Checks all the requirements for an ERC721 before handing off the listing to '_list'
     * @param tokenId The ID of the token to list
     * @param currencyId The ID of the currency that is to be used to purchase this item
     * @param currencyAmount The amount of currency that is to be used to purchase this item
     * @param listingId The ID that will be used to define this listing in the mapping
     * @param sender The user's address that is making this listing
     * @param nftAddress The address of the contract in which the item belongs
     * @param currencyId The ID of the currency that the item will be sold in
     * @param listingUpdate Whether or not this function was called to create a listing (false) or update a listing (true)
     */
    function _listERC721(
        uint256 tokenId,
        uint256 currencyId,
        uint256 currencyAmount,
        uint256 listingId,
        address sender,
        address nftAddress,
        bool listingUpdate
    ) internal {
        IERC721 nftContract = IERC721(nftAddress);
        require(
            nftContract.ownerOf(tokenId) == sender,
            "MachoMarket: Sender is not owner of token"
        );
        require(
            isItemListed[nftAddress][tokenId] == listingUpdate,
            "MachoMarket: Unable to modify listing or create the listing"
        );
        require(
            nftContract.isApprovedForAll(msg.sender, address(this)),
            "MachoMarket: Market is not approved to handle your tokens"
        );

        _list(
            tokenId,
            currencyId,
            currencyAmount,
            listingId,
            1,
            sender,
            nftAddress
        );

        isItemListed[nftAddress][tokenId] = true;
    }

    /** @dev Checks all the requirements for an ERC1155T before handing off the listing to '_list'
     * @param tokenId The ID of the token to list
     * @param currencyId The ID of the currency that is to be used to purchase this item
     * @param currencyAmount The amount of currency that is to be used to purchase this item
     * @param listingId The ID that will be used to define this listing in the mapping
     * @param nftAmount The amount of tokens to list
     * @param sender The user's address that is making this listing
     * @param nftAddress The address of the contract in which the item belongs
     */
    function _listERC1155T(
        uint256 tokenId,
        uint256 currencyId,
        uint256 currencyAmount,
        uint256 listingId,
        uint256 nftAmount,
        address sender,
        address nftAddress
    ) internal {
        IERC1155Transferable nftContract = IERC1155Transferable(nftAddress);
        require(
            nftContract.isTransferable(sender, tokenId, nftAmount),
            "MachoMarket: Sender does not hold enough transferable tokens"
        );
        require(
            nftContract.balanceOf(sender, tokenId) >= nftAmount,
            "MachoMarket: You are not able to list more tokens than you own"
        );
        require(
            nftContract.isApprovedForAll(msg.sender, address(this)),
            "MachoMarket: Market is not approved to handle your tokens"
        );
        require(
            nftAmount > 0,
            "MachoMarket: You can not list 0 or less tokens"
        );

        nftContract.setTransferable(sender, tokenId, nftAmount, false);

        _list(
            tokenId,
            currencyId,
            currencyAmount,
            listingId,
            nftAmount,
            sender,
            nftAddress
        );
    }

    /** @dev Checks all the requirements for an ERC1155 before handing off the listing to '_list'
     * @param tokenId The ID of the token to list
     * @param currencyId The ID of the currency that is to be used to purchase this item
     * @param currencyAmount The amount of currency that is to be used to purchase this item
     * @param listingId The ID that will be used to define this listing in the mapping
     * @param nftAmount The amount of tokens to list
     * @param sender The user's address that is making this listing
     * @param nftAddress The address of the contract in which the item belongs
     */
    function _listERC1155(
        uint256 tokenId,
        uint256 currencyId,
        uint256 currencyAmount,
        uint256 listingId,
        uint256 nftAmount,
        address sender,
        address nftAddress
    ) internal {
        IERC1155 nftContract = IERC1155(nftAddress);
        uint256 balance = nftContract.balanceOf(sender, tokenId);
        uint256 amountListed = amountOf1155Listed[nftAddress][sender][tokenId];
        require(
            balance > amountListed && balance - amountListed >= nftAmount,
            "MachoMarket: You are not able to list more tokens than you own"
        );
        require(
            nftContract.isApprovedForAll(msg.sender, address(this)),
            "MachoMarket: Market is not approved to handle your tokens"
        );
        require(
            nftAmount > 0,
            "MachoMarket: You can not list 0 or less tokens"
        );

        _list(
            tokenId,
            currencyId,
            currencyAmount,
            listingId,
            nftAmount,
            sender,
            nftAddress
        );

        amountOf1155Listed[nftAddress][sender][tokenId] += nftAmount;
    }

    /** @dev Creates a new listing
     * @param tokenId The ID of the token to list
     * @param currencyId The ID of the currency that is to be used to purchase this item
     * @param currencyAmount The amount of currency that is to be used to purchase this item
     * @param listingId The ID that will be used to define this listing in the mapping
     * @param nftAmount The amount of tokens to list (Will be '1' for ERC721)
     * @param sender The user's address that is making this listing
     * @param nftAddress The address of the contract in which the item belongs
     */
    function _list(
        uint256 tokenId,
        uint256 currencyId,
        uint256 currencyAmount,
        uint256 listingId,
        uint256 nftAmount,
        address sender,
        address nftAddress
    ) internal {
        Currency memory currency = idToCurrency[currencyId];
        if (
            currency.currencyType == CurrencyType.Ether ||
            currency.currencyType == CurrencyType.ERC20
        ) {
            require(
                currencyAmount >= MIN_PRICE,
                "MachoMarket: Listing price is too low"
            );
            idToMarketItems[listingId] = MarketItem(
                tokenId,
                nftAmount,
                currencyAmount,
                currencyId,
                nftAddress,
                sender,
                true
            );
        } else {
            require(
                currencyAmount > 0,
                "MachoMarket: Listing price is too low"
            );
            idToMarketItems[listingId] = MarketItem(
                tokenId,
                nftAmount,
                currencyAmount,
                currencyId,
                nftAddress,
                sender,
                true
            );
        }
    }

    /**
     * @dev Updates a current listing
     * @param listingId The ID of the listing that is to be updated
     * @param itemQuantity The amount of tokens to be listed (only applicable to ERC1155)
     * @param currencyId The ID of the currency to use
     * @param itemPrice The price of the listing
     */
    function updateListing(
        uint256 listingId,
        uint256 itemQuantity,
        uint256 currencyId,
        uint256 itemPrice
    ) external nonReentrant {
        MarketItem memory marketItem = idToMarketItems[listingId];
        require(
            msg.sender == marketItem.itemOwner,
            "MachoMarket: You are not allowed to modify this listing"
        );
        require(
            marketItem.isListed,
            "MachoMarket: The given listingId is not active"
        );
        require(
            currIdToApproved[currencyId],
            "MachMarket: Given currencyId is invalid"
        );
        ContractType contractType = contractTypes[marketItem.itemAddress];
        if (contractType == ContractType.ERC721T) {
            _listERC721T(
                marketItem.tokenId,
                currencyId,
                itemPrice,
                listingId,
                marketItem.itemOwner,
                marketItem.itemAddress,
                true
            );
        } else if (contractType == ContractType.ERC721) {
            _listERC721(
                marketItem.tokenId,
                currencyId,
                itemPrice,
                listingId,
                marketItem.itemOwner,
                marketItem.itemAddress,
                true
            );
        } else if (contractType == ContractType.ERC1155T) {
            /// @dev Will set previous listed ERC1155T tokens to transferable because '_listERC1155T' will handle the setting of the new tokens to non-transferable
            IERC1155Transferable(marketItem.itemAddress).setTransferable(
                msg.sender,
                marketItem.tokenId,
                marketItem.itemQuantity,
                true
            );

            _listERC1155T(
                marketItem.tokenId,
                currencyId,
                itemPrice,
                listingId,
                itemQuantity,
                marketItem.itemOwner,
                marketItem.itemAddress
            );
        } else if (contractType == ContractType.ERC1155) {
            /// @dev Will remove the old listing amount and '_listERC1155' will update it to the new amount
            amountOf1155Listed[marketItem.itemAddress][marketItem.itemOwner][
                marketItem.tokenId
            ] -= marketItem.itemQuantity;
            _listERC1155(
                marketItem.tokenId,
                currencyId,
                itemPrice,
                listingId,
                itemQuantity,
                marketItem.itemOwner,
                marketItem.itemAddress
            );
        }

        emit ListingUpdated(listingId);
    }

    /** @dev Purchases a listing
     * @param listingId The ID of the listing that is to be purchased
     */
    function purchaseItem(uint256 listingId) external payable nonReentrant {
        MarketItem memory marketItem = idToMarketItems[listingId];
        require(marketItem.isListed, "MachoMarket: Listing has been removed");
        require(
            marketItem.itemOwner != msg.sender,
            "MachoMarket: Cannot purchase your own token"
        );
        Currency memory currency = idToCurrency[marketItem.currencyId];
        CurrencyType currencyType = currency.currencyType;
        if (currency.currencyType == CurrencyType.Ether) {
            require(
                msg.value == marketItem.itemPrice,
                "MachoMarket: Insufficient ether amount"
            );
        } else if (currencyType == CurrencyType.ERC20) {
            _handleERC20(
                msg.sender,
                marketItem.itemPrice,
                currency.tokenAddress
            );
        } else if (currencyType == CurrencyType.ERC1155) {
            _handleERC1155(
                msg.sender,
                currency.tokenAddress,
                currency.tokenId,
                marketItem.itemPrice
            );
        }

        address itemAddress = marketItem.itemAddress;
        ContractType contractType = contractTypes[itemAddress];

        _transferMarketItem(
            marketItem.itemOwner,
            msg.sender,
            itemAddress,
            marketItem.itemQuantity,
            marketItem.tokenId,
            contractType
        );

        if (currency.currencyType == CurrencyType.ERC1155) {
            _transferFunds(
                msg.sender,
                marketItem.itemOwner,
                marketItem.itemPrice,
                currency
            );
        } else {
            _payFees(
                msg.sender,
                marketItem.itemOwner,
                marketItem.itemAddress,
                marketItem.itemPrice,
                currency
            );
        }

        _removeListing(listingId);
        emit ListingPurchased(listingId);
    }

    /** @dev Handles the requirements to be able to purchase an item with an ERC20 token
     * @param buyer The buyer's address
     * @param itemPrice The amount of tokens the buyer needs
     * @param currencyAddress The address of the currency contract
     */
    function _handleERC20(
        address buyer,
        uint256 itemPrice,
        address currencyAddress
    ) internal view {
        require(
            IERC20(currencyAddress).allowance(buyer, address(this)) >=
                itemPrice,
            "MachoMarket: Market is not approved to handle personal ERC20 tokens"
        );
    }

    /** @dev Handles the requirements to be able to purchase an item with an ERC1155 token
     * @param buyer The buyer's address
     * @param currencyAddress The address of the currency contract
     */
    function _handleERC1155(
        address buyer,
        address currencyAddress,
        uint256 tokenId,
        uint256 currencyAmount
    ) internal view {
        IERC1155 erc1155Contract = IERC1155(currencyAddress);
        uint256 balance = erc1155Contract.balanceOf(buyer, tokenId);
        uint256 amountListed = amountOf1155Listed[currencyAddress][buyer][
            tokenId
        ];

        require(
            erc1155Contract.isApprovedForAll(buyer, address(this)),
            "MachoMarket: Market is not approved to handle personal ERC1155 tokens"
        );
        require(
            balance > amountListed && balance - amountListed >= currencyAmount,
            "MachMarket: Delist your tokens so you have enough to purchase this item"
        );
    }

    /** @dev Calculates the amount of fees the market and collection contract will recieve and transfers the rest of the amount to the listing owner
     * @param from The address of the user paying the fees and buying the listing
     * @param to The address of the user selling the listing
     * @param itemContract The address of the contract in which the listing item was from
     * @param amount The amount the listing was worth
     * @param currency The currency that is to be used to buy the listing
     */
    function _payFees(
        address from,
        address to,
        address itemContract,
        uint256 amount,
        Currency memory currency
    ) internal {
        FeeInfo memory feeInfo = contractToFee[itemContract];
        address collectionRecipient = feeInfo.recipient;
        uint256 collectionFee;

        if (collectionRecipient != address(0)) {
            collectionFee = feeInfo.feeAmount;
        } else {
            collectionFee = 0;
        }

        uint256 marketFeeAmount = (amount * fee) / BASIS_POINTS;
        uint256 collectionFeeAmount = (amount * collectionFee) / BASIS_POINTS;
        uint256 listingOwnerAmount = amount -
            marketFeeAmount -
            collectionFeeAmount;
        _transferFunds(from, feeRecipient, marketFeeAmount, currency);
        _transferFunds(
            from,
            collectionRecipient,
            collectionFeeAmount,
            currency
        );
        _transferFunds(from, to, listingOwnerAmount, currency);
    }

    /** @dev Cancels a listing
     * @param listingId The ID of the listing that is to be removed
     */
    function cancelListing(uint256 listingId) external nonReentrant {
        MarketItem memory marketItem = idToMarketItems[listingId];
        require(
            marketItem.isListed,
            "MachoMarket: Cannot cancel a listing of an unlisted item"
        );
        require(
            msg.sender == marketItem.itemOwner,
            "MachoMarket: You are not the owner of this listing"
        );

        _updateTransferStatus(
            marketItem.tokenId,
            marketItem.itemQuantity,
            marketItem.itemAddress,
            marketItem.itemOwner,
            true,
            contractTypes[marketItem.itemAddress]
        );
        _removeListing(listingId);
        emit ListingRemoved(listingId);
    }

    /** @dev Handles the removing of a listing
     * @param listingId The ID of the listing to remove
     */
    function _removeListing(uint256 listingId) internal {
        idToMarketItems[listingId].isListed = false;
        MarketItem memory marketItem = idToMarketItems[listingId];

        ContractType contractType = contractTypes[marketItem.itemAddress];
        if (
            contractType == ContractType.ERC721 ||
            contractType == ContractType.ERC721T
        ) {
            isItemListed[marketItem.itemAddress][marketItem.tokenId] = false;
        }
        if (contractType == ContractType.ERC1155) {
            amountOf1155Listed[marketItem.itemAddress][marketItem.itemOwner][
                marketItem.tokenId
            ] -= marketItem.itemQuantity;
        }
    }

    /** @dev Updates the transfer status of ERC721T/ERC1155T tokens
     * @param tokenId The ID of the token to update
     * @param itemQuantity The amount of tokens to update (only applicable to ERC1155)
     * @param user The address of the user whos tokens are to be updated (only needed for ERC1155)
     * @param canTransfer Whether or not the tokens should be made transferable (true) or non-transferable (false)
     * @param contractType The type of contract that the item belongs to
     */
    function _updateTransferStatus(
        uint256 tokenId,
        uint256 itemQuantity,
        address itemContract,
        address user,
        bool canTransfer,
        ContractType contractType
    ) internal {
        if (contractType == ContractType.ERC721T) {
            IERC721Transferable(itemContract).setTransferable(
                tokenId,
                canTransfer
            );
        } else if (contractType == ContractType.ERC1155T) {
            IERC1155Transferable(itemContract).setTransferable(
                user,
                tokenId,
                itemQuantity,
                canTransfer
            );
        }
    }

    /** @dev Handles the transfering of a market item
     * @param from The address of the listing owner
     * @param to The address of the listing buyer
     * @param itemAddress The address of the contract where the market item is located
     * @param amount The amount of tokens to transfer (only applicable to ERC1155)
     * @param tokenId The ID of the token to transfer
     * @param contractType The type of contract that the market item belongs to
     */
    function _transferMarketItem(
        address from,
        address to,
        address itemAddress,
        uint256 amount,
        uint256 tokenId,
        ContractType contractType
    ) internal {
        if (contractType == ContractType.ERC721T) {
            IERC721Transferable ercContract = IERC721Transferable(itemAddress);
            ercContract.setTransferable(tokenId, true);
            ercContract.safeTransferFrom(from, to, tokenId);
        } else if (contractType == ContractType.ERC721) {
            IERC721(itemAddress).safeTransferFrom(from, to, tokenId);
        } else if (contractType == ContractType.ERC1155T) {
            IERC1155Transferable ercContract = IERC1155Transferable(
                itemAddress
            );
            ercContract.setTransferable(from, tokenId, amount, true);
            ercContract.safeTransferFrom(from, to, tokenId, amount, "");
        } else if (contractType == ContractType.ERC1155) {
            IERC1155(itemAddress).safeTransferFrom(
                from,
                to,
                tokenId,
                amount,
                ""
            );
        }
    }

    /** @dev Handles the funds transfer when a listing is purchased
     * @param from The address of the listing buyer
     * @param to The address of the listing owner
     * @param amount The ammount of currency to transfer
     * @param currency The type of currency that is to be transfered
     */
    function _transferFunds(
        address from,
        address to,
        uint256 amount,
        Currency memory currency
    ) internal {
        if (amount == 0) {
            return;
        }
        if (currency.currencyType == CurrencyType.Ether) {
            (bool success, ) = payable(to).call{value: amount}("");
            require(success, "MachoMarket: Ether transfer unsuccessful");
        } else if (currency.currencyType == CurrencyType.ERC20) {
            IERC20(currency.tokenAddress).transferFrom(from, to, amount);
        } else if (currency.currencyType == CurrencyType.ERC1155) {
            IERC1155(currency.tokenAddress).safeTransferFrom(
                from,
                to,
                currency.tokenId,
                amount,
                ""
            );
        }
    }

    /** @dev Used to add or remove market item contracts
     * @param nftAddress The address of the market item contract
     * @param approval Whether or not to remove (false) or add (true) the contract to the marketplace
     * @param contractType The type of contract that the address is
     */
    function modifyItemContract(
        address nftAddress,
        bool approval,
        ContractType contractType
    ) external onlyOwner {
        require(
            !approvedItemContracts[nftAddress] == approval,
            "MachoMarket: No modification needed"
        );

        approvedItemContracts[nftAddress] = approval;
        contractTypes[nftAddress] = contractType;
    }

    /** @dev Adds a currency to the marketplace
     * @param currencyId The ID to assign to the new currency
     * @param purchaseId The tokenId of the currency (only applicable to ERC1155, this value will impact nothing if the currency is an ERC20)
     * @param currencyAddress The address of the currency contract
     * @param currencyType The type of the currency
     */
    function addCurrency(
        uint256 currencyId,
        uint256 purchaseId,
        address currencyAddress,
        CurrencyType currencyType
    ) external onlyOwner {
        require(
            !currIdToApproved[currencyId],
            "MachoMarket: Currency Id is already in use"
        );
        if (currencyType == CurrencyType.ERC20) {
            require(
                !isAcceptedCurrency[currencyAddress],
                "MachoMarket: Address is already used for a currency"
            );

            idToCurrency[currencyId] = Currency(
                currencyAddress,
                currencyType,
                purchaseId
            );
            currIdToApproved[currencyId] = true;
            isAcceptedCurrency[currencyAddress] = true;
        } else if (currencyType == CurrencyType.ERC1155) {
            require(
                !isUsedPurchaseId[currencyAddress][purchaseId],
                "MachoMarket: That tokenId has already been used as a currency"
            );

            idToCurrency[currencyId] = Currency(
                currencyAddress,
                currencyType,
                purchaseId
            );
            currIdToApproved[currencyId] = true;
            isUsedPurchaseId[currencyAddress][purchaseId] = true;
            isAcceptedCurrency[currencyAddress] = true;
        }
    }

    /** @dev Removes a currency to the marketplace
     * @param currencyId The ID of the currency to remove
     */
    function removeCurrency(uint256 currencyId) external onlyOwner {
        require(
            !currIdToApproved[currencyId],
            "MachoMarket: ID is already disallowed"
        );

        delete isAcceptedCurrency[idToCurrency[currencyId].tokenAddress];
        delete idToCurrency[currencyId];
        delete currIdToApproved[currencyId];
    }

    /** @dev Updates the fee info for a given collection
     * @param itemAddress The address of the item contract
     * @param feeRecip The address of the fee recipient
     * @param amount The fee amount
     */
    function updateCollectionFee(
        address itemAddress,
        address feeRecip,
        uint32 amount
    ) external onlyOwner {
        require(amount <= MAX_FEE, "MachoMarket: Fee is too high");
        require(
            approvedItemContracts[itemAddress],
            "MachoMarket: This collection has not been approved to list"
        );
        FeeInfo memory feeInfo = FeeInfo(feeRecip, amount);
        contractToFee[itemAddress] = feeInfo;
    }

    /** @dev Updates the fee info for the marketplace
     * @param feeRecip The address of the fee recipient
     * @param amount The fee amount
     */
    function updateMarketFee(address feeRecip, uint32 amount)
        external
        onlyOwner
    {
        require(amount <= MAX_FEE * 2, "MachoMarket: Fee is too high");
        feeRecipient = feeRecip;
        fee = amount;
    }

    /** @dev Used to check if a token is listed and if applicable, how many of the tokens are listed
     * @param tokenId The tokenId of the token to check
     * @param user The account to check
     * @param nftAddress The contract where the tokenId is located
     * @param contractType The type of contract that the nftAddress is
     */
    function isListed(
        uint256 tokenId,
        address user,
        address nftAddress,
        ContractType contractType
    ) public view returns (uint256) {
        if (
            contractType == ContractType.ERC721 ||
            contractType == ContractType.ERC721T
        ) {
            if (isItemListed[nftAddress][tokenId]) {
                return 1;
            } else {
                return 0;
            }
        } else {
            return amountOf1155Listed[nftAddress][user][tokenId];
        }
    }
}

// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.7;

import "@openzeppelin/contracts/token/ERC721/IERC721.sol";

interface IERC721Transferable is IERC721 {
    /**
     * @dev Grants or revokes permission to transfer 'tokenId' according to 'canTransfer'
     *
     * Requirements:
     *
     * - msg.sender must be approved
     */
    function setTransferable(uint256 tokenId, bool canTransfer) external;

    /**
     * @dev Returns true if 'tokenId' can be transfered
     *
     * See {setTransferable}
     */
    function isTransferable(uint256 tokenId) external view returns (bool);

    /**
     * @dev Allows for contracts to be whitelisted so they can change the transferable status tokens
     */
    function setContractApproval(address contractAddress, bool approve)
        external;
}

// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.7;

import "@openzeppelin/contracts/token/ERC1155/IERC1155.sol";

interface IERC1155Transferable is IERC1155 {
    /**
     * @dev Grants or revokes permission to transfer 'amount' of 'tokenId' according to 'canTransfer'
     *
     * Requirements:
     *
     * - msg.sender must own 'tokenId' or be approved
     */
    function setTransferable(
        address user,
        uint256 tokenId,
        uint256 amount,
        bool canTransfer
    ) external;

    /**
     * @dev Returns true if 'amount' of 'tokenId' can be transfered
     *
     * See {setTransferable}
     */
    function isTransferable(
        address user,
        uint256 tokenId,
        uint256 amount
    ) external view returns (bool);

    /**
     * @dev Allows for contracts to be whitelisted so they can change the transferable status tokens
     */
    function setContractApproval(address contractAddress, bool approve)
        external;
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
// OpenZeppelin Contracts (last updated v4.7.0) (token/ERC1155/IERC1155.sol)

pragma solidity ^0.8.0;

import "../../utils/introspection/IERC165.sol";

/**
 * @dev Required interface of an ERC1155 compliant contract, as defined in the
 * https://eips.ethereum.org/EIPS/eip-1155[EIP].
 *
 * _Available since v3.1._
 */
interface IERC1155 is IERC165 {
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

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (security/ReentrancyGuard.sol)

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

    function __ReentrancyGuard_init() internal onlyInitializing {
        __ReentrancyGuard_init_unchained();
    }

    function __ReentrancyGuard_init_unchained() internal onlyInitializing {
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

    /**
     * @dev This empty reserved space is put in place to allow future versions to add new
     * variables without shifting down storage in the inheritance chain.
     * See https://docs.openzeppelin.com/contracts/4.x/upgradeable#storage_gaps
     */
    uint256[49] private __gap;
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