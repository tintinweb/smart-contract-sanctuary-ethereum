// SPDX-License-Identifier: MIT
pragma solidity 0.8.15;

import {Ownable} from "@openzeppelin/contracts/access/Ownable.sol";
import {Pausable} from "@openzeppelin/contracts/security/Pausable.sol";
import {ReentrancyGuard} from
    "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import {INFT} from "./interfaces/INFT.sol";
import {IFacilitator} from "./interfaces/IFacilitator.sol";
import {IERC2981} from "@openzeppelin/contracts/interfaces/IERC2981.sol";
import {
    SafeERC20,
    IERC20
} from "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import {IERC20Metadata} from
    "@openzeppelin/contracts/token/ERC20/extensions/IERC20Metadata.sol";
import {
    EIP712,
    ECDSA
} from "@openzeppelin/contracts/utils/cryptography/draft-EIP712.sol";
import {IOracleRegistry} from "./interfaces/IOracleRegistry.sol";

contract Facilitator is IFacilitator, Ownable, Pausable, ReentrancyGuard, EIP712 {
    using SafeERC20 for IERC20;

    //------------------- Errors ---------------------//

    error NotAFactoryOrOwner();
    error ZeroAddress();
    error NFTNotListed();
    error AlreadyListed();
    error NotOpenForPurchase();
    error NotOpenForPackPurchase();
    error InsufficientFundsSent();
    error IncorrectArrayLength();
    error MintPriceIsZero();
    error InvalidSignature();
    error ZeroAuthorisedPurchaseSigner();
    error ZeroFundCollector();
    error ExceedingAllowedMaxSupply();
    error EmptyTokenURI();
    error SignatureExpired();
    error QuantityExceedingMaximumSupply();
    error ZeroOracleRegistryAddress();
    error ZeroPriceFromOracle();
    error OracleCurrencyPairNotExist(string);
    error AmountIsZero();
    error PackInfoAlreadyExists();
    error PackInfoNotExists();
    error PackIdDoesnotExists();
    error IncorrectPackQuantity();
    error FailedToSendEther();
    error DiscountGreaterThan100();

    //------------------- Store variables ----------------//

    /// TypeHash
    bytes32 private constant _VOUCHER_TYPE_HASH = keccak256(
        "BatchPurchaseNFT(address nft, uint256 packId, address receiver, uint256 nonce, uint256 expiry, address verifyContract, string[] memory tokenURIs)"
    );

    /// Signature nonce count.
    uint256 public nonce;

    /// Authorised signer for the NFT Purchase transactions.
    address public authorisedPurchaseSigner;

    /// Address of the nftFactory.
    address public immutable nftFactory;

    /// Address which collects all the funds of the sale.
    address public fundCollector;

    /// Instance of the Oracle Registry.
    IOracleRegistry public immutable oracleRegistry;

    struct ListingDetails {
        // Already sold NFT count.
        uint256 soldCount;
        // Price of last series in sale currency.
        uint256 currentSeriesPrice;
        // Index of currentSeries.
        uint256 currentSeriesIndex;
        // Switch to facilitate the purchase of the nft project.
        bool isOpenForPurchase;
        // Base price of the NFT project, In terms of ETH
        uint256[] basePrices;
        // maximum token Id supported for provided series.
        uint256[] maxTokenIds;
        // Series
        string[] series;
        // Token address
        // address(1) for Native Currency
        address tokenAddress;
        // Oracle type for currency
        string oracleCurrencyPair;
        // Switch to facilitate the pack purchase of the nft project
        bool isOpenForPackPurchase;
    }

    /// Mapping to keep track the listed nfts with the contract.
    mapping(address => bool) public listedNFTs;

    /// Mapping to keep track of the listing details corresponds to the nft.
    mapping(address => ListingDetails) public listings;

    /// Mapping to keep track of the packs discount corresponding to its Ids.
    /// Id is always equal to the no. of NFT a pack offers.
    mapping(uint256 => uint256) public packInfo;

    /// Emitted when new pack info get added.
    event PackInfoAdded(uint256 _packId, uint256 _discountOffered);

    /// Emitted when pack info get updated.
    event PackInfoUpdated(uint256 _packId, uint256 _updatedDiscount);

    /// Emitted when nft is open for purchase.
    event OpenForPurchase();

    /// Emitted when nft is close for purchase.
    event CloseForPurchase();

    /// Emitted when nft is open for pack purchase.
    event OpenForPackPurchase();

    /// Emitted when nft is close for pack purchase.
    event CloseForPackPurchase();

    /// Emitted when the nft get listed with the facilitator contract.
    event NFTListed(
        address _nft,
        uint256[] _basePrice,
        uint256[] _maxTokenIds,
        string[] _series,
        address _tokenAddress,
        string _oracleCurrencyPair
    );

    /// Emitted when the provided nft get unlisted.
    event NFTUnlisted(address _nft);

    /// Emitted when authorised signer changes.
    event AuthorisedSignerChanged(address _newSigner);

    /// Emitted when fund collector changes.
    event FundCollectorChanged(address _newFundCollector);

    /// Emitted when the NFT get purchased.
    event NFTPurchased(
        address indexed _nft,
        address indexed _receiver,
        address _royaltyReceiver,
        uint256 _tokenId,
        uint256 _mintFeePaid,
        uint256 _royaltyFeePaid,
        string _tokenURI
    );

    /// Emitted when the NFT get purchased in batch.
    event BatchNFTPurchased(
        address indexed _nft,
        address indexed _receiver,
        uint256 _totalPrice,
        uint256 _totalMintFee,
        uint256 _batchSize,
        string[] _tokenURI
    );

    /// Emitted when the NFT get purchased in pack.
    event PackPurchased(
        address indexed _nft,
        address indexed _receiver,
        uint256 _totalPrice,
        uint256 _totalMintFee,
        uint256 _packId,
        string[] _tokenURI
    );

    /// @notice Initializer of the contract.
    /// @param _nftFactory Address of the factory contract.
    constructor(
        address _nftFactory,
        address _authorisedPurchaseSigner,
        address _fundCollector,
        IOracleRegistry _oracleRegistry
    )
        EIP712("Facilitator", "1")
    {
        nftFactory = _nftFactory;
        if (_authorisedPurchaseSigner == address(0)) {
            revert ZeroAuthorisedPurchaseSigner();
        }
        if (_fundCollector == address(0)) {
            revert ZeroFundCollector();
        }
        if (address(_oracleRegistry) == address(0)) {
            revert ZeroOracleRegistryAddress();
        }
        authorisedPurchaseSigner = _authorisedPurchaseSigner;
        fundCollector = _fundCollector;
        oracleRegistry = _oracleRegistry;
    }

    /// @notice only factory or owner can call this
    modifier onlyFactoryOrOwner() {
        if (msg.sender != nftFactory && owner() != msg.sender) {
            revert NotAFactoryOrOwner();
        }
        _;
    }

    /// @notice Function to provide the ownership of the minting of the given nft.
    /// @param nft Address of the nft whose purchase would be allowed.
    /// @param basePrices Base prices of the NFT during the primary sales for different series.
    /// @param series Supported series for a given nft sale.
    /// @param maxTokenIdForSeries Maximum tokenId supported for different series. (Should be sorted in order).
    /// @param tokenAddress Token address if currency is ERC20.
    /// @param oracleCurrencyPair Currency pair to get price from oracle.
    function addNFTInPrimaryMarket(
        address nft,
        uint256[] calldata basePrices,
        string[] calldata series,
        uint256[] calldata maxTokenIdForSeries,
        address tokenAddress,
        string calldata oracleCurrencyPair
    )
        external
        onlyFactoryOrOwner
        whenNotPaused
    {
        if (basePrices.length == uint256(0)) {
            revert MintPriceIsZero();
        }
        if (
            maxTokenIdForSeries.length != basePrices.length
                || series.length != basePrices.length
        ) {
            revert IncorrectArrayLength();
        }
        if (nft == address(0)) {
            revert ZeroAddress();
        }
        // Should not be already listed.
        if (listedNFTs[nft]) {
            revert AlreadyListed();
        }

        /// Currency should exist in oracle
        if (
            keccak256(
                abi.encodePacked(oracleRegistry.description(oracleCurrencyPair))
            ) == keccak256(abi.encodePacked(""))
        ) {
            revert OracleCurrencyPairNotExist(oracleCurrencyPair);
        }

        listedNFTs[nft] = true;
        listings[nft] = ListingDetails({
            basePrices: basePrices,
            maxTokenIds: maxTokenIdForSeries,
            series: series,
            isOpenForPurchase: true,
            soldCount: uint256(0),
            tokenAddress: tokenAddress,
            oracleCurrencyPair: oracleCurrencyPair,
            currentSeriesPrice: uint256(0),
            currentSeriesIndex: uint256(0),
            isOpenForPackPurchase: true
        });

        // Emit event
        emit NFTListed(
            nft,
            basePrices,
            maxTokenIdForSeries,
            series,
            tokenAddress,
            oracleCurrencyPair
            );
        emit OpenForPurchase();
    }

    /// @notice Add pack info.
    /// @param packId Id of the pack corresponding to which discount value get added.
    /// @param discountOffered Discount offered by the given pack.
    function addPackInfo(uint256 packId, uint256 discountOffered)
        external
        onlyOwner
    {
        if (packInfo[packId] != uint256(0)) {
            revert PackInfoAlreadyExists();
        }
        if (discountOffered > uint256(100)) {
            revert DiscountGreaterThan100();
        }
        packInfo[packId] = discountOffered;
        emit PackInfoAdded(packId, discountOffered);
    }

    /// @notice Update pack info.
    /// @param packId Id of the pack corresponding to which discount value get updated.
    /// @param newDiscount Updated Discount offered by the given pack.
    function updatePackInfo(uint256 packId, uint256 newDiscount)
        external
        onlyOwner
    {
        if (packInfo[packId] == uint256(0)) {
            revert PackInfoNotExists();
        }
        if (newDiscount > uint256(100)) {
            revert DiscountGreaterThan100();
        }
        packInfo[packId] = newDiscount;
        emit PackInfoUpdated(packId, newDiscount);
    }

    /// @notice Returns the listing details of an nft.
    function getListedNftDetails(address nft)
        external
        view
        returns (
            bool,
            string memory,
            uint256,
            uint256,
            uint256,
            uint256[] memory,
            uint256[] memory
        )
    {
        return (
            listings[nft].isOpenForPurchase,
            listings[nft].oracleCurrencyPair,
            listings[nft].soldCount,
            listings[nft].currentSeriesPrice,
            listings[nft].currentSeriesIndex,
            listings[nft].basePrices,
            listings[nft].maxTokenIds
        );
    }

    /// @notice Expected price of NFT purchase
    /// @dev it is not guranteed that expected price is always a true purchase price
    /// because it takes the sale currency oracle price at the time of execution of this
    /// function, It can be different during the actual purchase of the NFT.
    /// @param nft Address of the NFT whose prices are queried.
    /// @param purchaseQuantity Amount of nfts user is expecting to purchase.
    function getExpectedTotalPrice(address nft, uint256 purchaseQuantity, uint256 packId)
        external
        view
        returns (uint256 totalPrices)
    {
        ListingDetails memory details = listings[nft];
        (totalPrices,,,) = _derivePrices(details, purchaseQuantity);
        if (packId > 0 && packInfo[packId] != uint256(0)) {
            uint256 remainderAfterDiscount = 100 - packInfo[packId];
            totalPrices = totalPrices * remainderAfterDiscount / 100;
        }
    }

    /// @notice Allow the owner to remove the given NFT from the listings.
    /// @param nft Address of the NFT that needs to be unlisted.
    function removeNFTFromPrimaryMarket(address nft)
        external
        onlyOwner
        whenNotPaused
    {
        if (!listedNFTs[nft]) {
            revert NFTNotListed();
        }
        delete listedNFTs[nft];
        delete listings[nft];

        // Emit logs
        emit NFTUnlisted(nft);
    }

    /// @notice Allow to change the aurhorised signer.
    /// @dev Not going to change the signer on the fly, A designated downtime would be provided during the change
    /// so least possibility of the frontrun from the owner side.
    /// @param newAuthorisedSigner New address set as the authorised signer.
    function changeAuthorisedSigner(address newAuthorisedSigner)
        external
        onlyOwner
        whenNotPaused
    {
        if (newAuthorisedSigner == address(0)) {
            revert ZeroAddress();
        }
        authorisedPurchaseSigner = newAuthorisedSigner;
        emit AuthorisedSignerChanged(newAuthorisedSigner);
    }

    /// @notice Allow a user to purchase the NFTs in a pack.
    /// @param nft Address of the NFT which need to get purcahse.
    /// @param receiver Address of the receiver.
    /// @param tokenURIs URIs for the tokenIds that get minted.
    /// @param expiry Expiry of the signature.
    /// @param packId Id of the pack that get purchased.
    /// @param signature Offchain signature of the authorised address.
    function purchasePack(
        address nft,
        address receiver,
        string[] memory tokenURIs,
        uint256 expiry,
        uint256 packId,
        bytes memory signature,
        uint256 erc20TokenAmt
    )
        external
        payable
        nonReentrant
        whenNotPaused
    {
        if (packInfo[packId] == uint256(0)) {
            revert PackIdDoesnotExists();
        }
        if (tokenURIs.length != packId) {
            revert IncorrectPackQuantity();
        }
        _batchPurchaseNFT(
            nft, receiver, expiry, packId, signature, erc20TokenAmt, tokenURIs
        );
    }

    /// @notice Allow a user to purchase the NFTs in batch.
    /// @param nft Address of the NFT which need to get purcahse.
    /// @param receiver Address of the receiver.
    /// @param tokenURIs URIs for the tokenIds that get minted.
    /// @param expiry Expiry of the signature.
    /// @param signature Offchain signature of the authorised address.
    /// @param erc20TokenAmt Amount of tokens if currency is ERC20.
    function batchPurchaseNFT(
        address nft,
        address receiver,
        uint256 expiry,
        bytes memory signature,
        uint256 erc20TokenAmt,
        string[] memory tokenURIs
    )
        external
        payable
        nonReentrant
        whenNotPaused
    {
        _batchPurchaseNFT(
            nft, receiver, expiry, uint256(0), signature, erc20TokenAmt, tokenURIs
        );
    }

    function _batchPurchaseNFT(
        address nft,
        address receiver,
        uint256 expiry,
        uint256 packId,
        bytes memory signature,
        uint256 erc20TokenAmt,
        string[] memory tokenURIs
    )
        internal
    {
        // Check whether tokenURI exist for all NFTs
        if (tokenURIs.length == 0) {
            revert EmptyTokenURI();
        }
        // Chech whether signature get expired or not.
        if (expiry < block.timestamp) {
            revert SignatureExpired();
        }
        // Chech whether nft listed in market.
        if (!listedNFTs[nft]) {
            revert NFTNotListed();
        }
        address tokenAddress = listings[nft].tokenAddress;
        // If currency is not native then amount should be non-zero.
        if (tokenAddress != address(1) && erc20TokenAmt == 0) {
            revert AmountIsZero();
        } else if (tokenAddress == address(1)) {
            erc20TokenAmt = msg.value;
        }
        receiver = receiver != address(0) ? receiver : msg.sender;
        // Verify signature and price
        (uint256 totalPrices, uint256[] memory cachedNFTPrices) =
        _verifySignatureAndPrice(
            nft, receiver, tokenURIs, expiry, packId, signature
        );
        uint256 totalFee;
        uint256 remainderAfterDiscount = 100 - packInfo[packId];
        totalPrices = totalPrices * remainderAfterDiscount / 100;
        // Validate whether the sufficient funds are sent by the purchaser.
        if (erc20TokenAmt < totalPrices) {
            revert InsufficientFundsSent();
        }
        // Get the `tokenId` to mint next.
        uint256 tokenId = INFT(nft).nextTokenId();
        // Iterate to mint each NFT and send royality.
        for (uint256 i = 0; i < cachedNFTPrices.length;) {
            totalFee = totalFee
                + _transferRoyaltyAndMintNFT(
                    nft,
                    receiver,
                    cachedNFTPrices[i] * remainderAfterDiscount / 100,
                    tokenId,
                    tokenURIs[i],
                    tokenAddress
                );
            tokenId = tokenId + 1;
            unchecked {
                ++i;
            }
        }
        // Update to `soldCount`
        listings[nft].soldCount += tokenURIs.length;

        // If native currency
        if (tokenAddress == address(1)) {
            // Transfer minting funds to the veiovia
            payable(fundCollector).transfer(totalFee);
            // Check whether there is any funds remain in the contract for the msg.sender.
            uint256 remainingBalance = erc20TokenAmt - totalPrices;
            if (remainingBalance > 0) {
                payable(msg.sender).transfer(remainingBalance);
            }
        } else {
            // Transfer minting funds to the veiovia
            IERC20(tokenAddress).safeTransferFrom(
                msg.sender, fundCollector, totalFee
            );
        }

        if (packId == 0) {
            emit BatchNFTPurchased(
                nft, receiver, totalPrices, totalFee, tokenURIs.length, tokenURIs
                );
        } else {
            emit PackPurchased(nft, receiver, totalPrices, totalFee, packId, tokenURIs);
        }
    }

    function _verifySignatureAndPrice(
        address nft,
        address receiver,
        string[] memory tokenURIs,
        uint256 expiry,
        uint256 packId,
        bytes memory signature
    )
        internal
        returns (uint256 totalPrices, uint256[] memory cachedNFTPrices)
    {
        //--------------------- Verify the Offchain signature -----------------//
        // Update the nonce and check for it.
        {
            nonce = nonce + 1;
            bytes32 messageHash = keccak256(
                abi.encode(
                    _VOUCHER_TYPE_HASH,
                    nft,
                    packId,
                    receiver,
                    nonce,
                    expiry,
                    address(this),
                    tokenURIs
                )
            );
            bytes32 hash = _hashTypedDataV4(messageHash);
            address recoveredAddress = ECDSA.recover(hash, signature);
            if (
                recoveredAddress == address(0)
                    || recoveredAddress != authorisedPurchaseSigner
            ) {
                revert InvalidSignature();
            }
        }
        //--------------------------------------------------------------------//

        // Access the details of the listing .
        ListingDetails storage _details = listings[nft];

        // Check whether purchase of nft is allowed or not.
        if (!_details.isOpenForPurchase) {
            revert NotOpenForPurchase();
        }

        // Check whether pack purchase of nft is allowed or not.
        if (packId != uint256(0) && !_details.isOpenForPackPurchase) {
            revert NotOpenForPackPurchase();
        }

        // Derive prices.
        (
            totalPrices,
            _details.currentSeriesPrice,
            _details.currentSeriesIndex,
            cachedNFTPrices
        ) = _derivePrices(_details, tokenURIs.length);
    }

    function _transferRoyaltyAndMintNFT(
        address nft,
        address receiver,
        uint256 price,
        uint256 tokenId,
        string memory _tokenURI,
        address tokenAddress
    )
        internal
        returns (uint256 mintFee)
    {
        // Getting royalty information
        (address rRecv, uint256 rAmt) =
            IERC2981(nft).royaltyInfo(tokenId, price);
        if (rRecv != address(0) && rAmt != uint256(0) && rAmt < price) {
            if (tokenAddress == address(1)) {
                (bool sent,) = payable(rRecv).call{value:rAmt}("");
                if(!sent) {
                    revert FailedToSendEther();
                }
            } else {
                IERC20(tokenAddress).safeTransferFrom(msg.sender, rRecv, rAmt);
            }
            mintFee = price - rAmt;
        } else {
            mintFee = price; 
        }
        // Transfer of nft to the purchaser.
        INFT(nft).mint(receiver, _tokenURI);
        emit NFTPurchased(nft, receiver, rRecv, tokenId, mintFee, rAmt, _tokenURI);
        return mintFee;
    }

    // Algorithm the derive price to buy next NFT
    // - Cost or price of NFT in a given series would be constant
    // - Series price (i.e price of NFT in that series) would always be greater than the 10 % of previous series price.
    // Ex - A listing has 2 series A & B
    //      Whole series A costing would calculate at the time of purchase of first NFT from the series
    //      i.e op of MATIC = 1 and bp = 100 then price in terms of sale currency would be 100 MATIC throught the series.
    //      While for series B
    //      bp = 110 & op = 2 then base calculative price would be 55 MATIC, so the actual price of
    //      series B would be MAX(series A price + 10 % of series A price , base calculative price).
    function _derivePrices(ListingDetails memory _details, uint256 quantity)
        internal
        view
        returns (
            uint256 totalPrice,
            uint256 currentSeriesPrice,
            uint256 currentSeriesIndex,
            uint256[] memory cachedIndividualNFTPrices
        )
    {
        uint256 soldCount;
        (soldCount, currentSeriesPrice, currentSeriesIndex) = (
            _details.soldCount,
            _details.currentSeriesPrice,
            _details.currentSeriesIndex
        );
        // Fetch the price of sale currency in terms of USD.
        (, int256 oraclePrice,,,) =
            oracleRegistry.latestRoundData(_details.oracleCurrencyPair);
        // Make sure the retrieved price from oracle is non-negative.
        if (oraclePrice < 0) {
            revert ZeroPriceFromOracle();
        }
        // Fetch the supported decimal of oracle prices.
        uint8 decimal = oracleRegistry.decimals(_details.oracleCurrencyPair);
        uint8 tokenDecimal =
            _details.tokenAddress == address(1)
            ? 18
            : IERC20Metadata(_details.tokenAddress).decimals();
        uint256[] memory individualPriceOfNFT = new uint256[](quantity);
        uint256 fromIndex = 0;
        while (quantity != 0) {
            uint256 maxTokenIdInCurrentSeries =
                _details.maxTokenIds[currentSeriesIndex];
            uint256 noOfNFTCoveredInSeries;
            // Enter in `if` statement if the price of next series get calculated.
            if (
                currentSeriesIndex != 0
                    && soldCount == _details.maxTokenIds[currentSeriesIndex - 1]
                    || soldCount == 0
            ) {
                // bp = base sale prices in USD
                // c  = supported buy currency ,i.e Matic
                // dc = decimal precision of supported buy currency
                // op = oracle prices from chainlink. i.e MATIC/USD
                // od = oracle prices decimal precision
                //
                //            bp * 10**dc * 10**od
                // prices =   -------------------
                //            op * 100
                //
                {
                    uint256 basePriceOfSeries =
                        _details.basePrices[currentSeriesIndex];
                    uint256 basePriceInSaleCurrency = 10 ** decimal
                        * 10 ** tokenDecimal * basePriceOfSeries
                        / (uint256(oraclePrice) * 100);
                    // Minimum change in next series price i.e 10 % of last series price.
                    uint256 minimumPrice = currentSeriesPrice * 11 / 10;
                    // MAX(minimumPrice, basePriceInSaleCurrency)
                    currentSeriesPrice =
                        basePriceInSaleCurrency > minimumPrice
                        ? basePriceInSaleCurrency
                        : minimumPrice;
                }
            }
            // Enter in `if` statement if this is true quantity + soldCount <= maxTokenIdInCurrentSeries
            if (quantity <= maxTokenIdInCurrentSeries - soldCount) {
                totalPrice += quantity * currentSeriesPrice;
                soldCount = soldCount + quantity;
                noOfNFTCoveredInSeries = quantity;
                quantity = 0;
            } else {
                noOfNFTCoveredInSeries = maxTokenIdInCurrentSeries - soldCount;
                totalPrice += currentSeriesPrice * noOfNFTCoveredInSeries;
                soldCount = soldCount + noOfNFTCoveredInSeries;
                quantity = quantity - noOfNFTCoveredInSeries;
                currentSeriesIndex = currentSeriesIndex + 1;
            }
            _cacheNFTPrices(
                individualPriceOfNFT,
                fromIndex,
                fromIndex = fromIndex + noOfNFTCoveredInSeries,
                currentSeriesPrice
            );
        }
        return (
            totalPrice, currentSeriesPrice, currentSeriesIndex, individualPriceOfNFT
        );
    }

    function _cacheNFTPrices(
        uint256[] memory nftPrices,
        uint256 fromIndex,
        uint256 toIndex,
        uint256 price
    )
        internal
        pure
    {
        for (uint256 i = fromIndex; i < toIndex; i++) {
            nftPrices[i] = price;
        }
    }

    /// @notice Allow owner of the facilitator contract to close the purchase of the given NFT.
    /// @param nft Address of the nft whose purchase need to be closed.
    function closePurchase(address nft) external onlyOwner {
        if (!listedNFTs[nft]) {
            revert NFTNotListed();
        }
        listings[nft].isOpenForPurchase = false;
        emit CloseForPurchase();
    }

    // @notice Allow owner of the facilitator contract to open the purchase of the given NFT.
    /// @param nft Address of the nft whose purchase need to be open.
    function openPurchase(address nft) external onlyOwner {
        if (!listedNFTs[nft]) {
            revert NFTNotListed();
        }
        listings[nft].isOpenForPurchase = true;
        emit OpenForPurchase();
    }

    /// @notice Allow owner of the facilitator contract to close the pack purchase of the given NFT.
    /// @param nft Address of the nft whose purchase need to be closed.
    function closePackPurchase(address nft) external onlyOwner {
        if (!listedNFTs[nft]) {
            revert NFTNotListed();
        }
        listings[nft].isOpenForPackPurchase = false;
        emit CloseForPackPurchase();
    }

    // @notice Allow owner of the facilitator contract to open the pack purchase of the given NFT.
    /// @param nft Address of the nft whose purchase need to be open.
    function openPackPurchase(address nft) external onlyOwner {
        if (!listedNFTs[nft]) {
            revert NFTNotListed();
        }
        listings[nft].isOpenForPackPurchase = true;
        emit OpenForPackPurchase();
    }

    /// @notice Allow owner of the facilitator contract to update the fundCollector address.
    /// @param _fundCollector Address of the new fund collector.
    function changeFundCollector(address _fundCollector) external onlyOwner {
        if (_fundCollector == address(0)) {
            revert ZeroAddress();
        }
        fundCollector = _fundCollector;
        emit FundCollectorChanged(_fundCollector);
    }

    /// @notice Domain separator.
    function DOMAIN_SEPARATOR() external view returns (bytes32) {
        return _domainSeparatorV4();
    }

    /// @notice allow the owner to pause some of the functionalities offered by the contract.
    function pause() external onlyOwner {
        _pause();
    }

    /// @notice allow the owner to unpause the contract.
    function unpause() external onlyOwner {
        _unpause();
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

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (security/Pausable.sol)

pragma solidity ^0.8.0;

import "../utils/Context.sol";

/**
 * @dev Contract module which allows children to implement an emergency stop
 * mechanism that can be triggered by an authorized account.
 *
 * This module is used through inheritance. It will make available the
 * modifiers `whenNotPaused` and `whenPaused`, which can be applied to
 * the functions of your contract. Note that they will not be pausable by
 * simply including this module, only once the modifiers are put in place.
 */
abstract contract Pausable is Context {
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
    constructor() {
        _paused = false;
    }

    /**
     * @dev Modifier to make a function callable only when the contract is not paused.
     *
     * Requirements:
     *
     * - The contract must not be paused.
     */
    modifier whenNotPaused() {
        _requireNotPaused();
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
        _requirePaused();
        _;
    }

    /**
     * @dev Returns true if the contract is paused, and false otherwise.
     */
    function paused() public view virtual returns (bool) {
        return _paused;
    }

    /**
     * @dev Throws if the contract is paused.
     */
    function _requireNotPaused() internal view virtual {
        require(!paused(), "Pausable: paused");
    }

    /**
     * @dev Throws if the contract is not paused.
     */
    function _requirePaused() internal view virtual {
        require(paused(), "Pausable: not paused");
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
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (security/ReentrancyGuard.sol)

pragma solidity ^0.8.0;

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
abstract contract ReentrancyGuard {
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

    constructor() {
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
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.15;

import {IERC721} from "@openzeppelin/contracts/token/ERC721/IERC721.sol";

interface INFT is IERC721 {
    /// @notice Initialize the NFT collection.
    /// @param _maxSupply maximum supply of a collection.
    /// @param baseUri base Url of the nft's metadata.
    /// @param _name name of the collection.
    /// @param _symbol symbol of the collection.
    /// @param _owner owner of the collection.
    /// @param _minter Address of the minter allowed to mint tokenIds.
    /// @param _royaltyReceiver Beneficary of the royalty.
    /// @param _feeNumerator Percentage of fee charged as royalty.
    function initialize(
        uint256 _maxSupply,
        string calldata baseUri,
        string calldata _name,
        string calldata _symbol,
        address _owner,
        address _minter,
        address _royaltyReceiver,
        uint96 _feeNumerator
    )
        external;

    /// @notice Mint a token and assign it to an address.
    /// @param _to NFT transferred to the given address.
    /// @param _tokenURI URI for token metadata.
    function mint(address _to, string memory _tokenURI) external;

    /// @notice Sets the royalty information that all ids in this contract will default to.
    /// Requirements:
    /// `receiver` cannot be the zero address.
    /// `feeNumerator` cannot be greater than the fee denominator.
    function setDefaultRoyalty(address receiver, uint96 feeNumerator) external;

    /// @notice Sets the royalty information for a specific token id, overriding the global default.
    /// Requirements:
    /// `receiver` cannot be the zero address.
    /// `feeNumerator` cannot be greater than the fee denominator.
    /// @param tokenId Token identitifer whom royalty information gonna set.
    /// @param receiver Beneficiary of the royalty.
    /// @param feeNumerator Percentage of fee gonna charge as royalty.
    function setTokenRoyalty(
        uint256 tokenId,
        address receiver,
        uint96 feeNumerator
    )
        external;

    /// @notice Deletes the default royalty information.
    function deleteDefaultRoyalty() external;

    /// @notice Global royalty would not be in use after this.
    function closeGlobalRoyalty() external;

    /// @notice Global royalty would be in use after this.
    function openGlobalRoyalty() external;

    /// @notice Resets royalty information for the token id back to the global default.
    function resetTokenRoyalty(uint256 tokenId) external;

    /// @notice Returns the URI that provides the details of royalty for OpenSea support.
    /// Ref - https://docs.opensea.io/v2.0/docs/contract-level-metadata
    function contractURI() external view returns (string memory);

    /// @notice Returns the Uniform Resource Identifier (URI) for `tokenId` token.
    /// @param tokenId Identifier for the token
    function tokenURI(uint256 tokenId)
        external
        view
        returns (string memory);
    
    /// @notice Returns the base URI for the contract.
    function baseURI() external view returns (string memory);

    /// @notice Set the base URI, Only ADMIN can call it.
    /// @param newBaseUri New base uri for the metadata.
    function setBaseUri(string memory newBaseUri) external;

    /// @notice Set the token URI for the given tokenId.
    /// @param tokenId Identifier for the token
    /// @param tokenUri URI for the given tokenId.
    function setTokenUri(uint256 tokenId, string memory tokenUri) external;

    function nextTokenId() external view returns (uint256);

    function maximumSupply() external view returns (uint256);

    function globalRoyaltyInEffect() external view returns (bool);
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.15;

interface IFacilitator {
    /// @notice Function to provide the ownership of the minting of the given nft.
    /// @param nft Address of the nft whose purchase would be allowed.
    /// @param basePrices Base prices of the NFT during the primary sales for different series.
    /// @param series Supoorted series for a given nft sale.
    /// @param maxTokenIdForSeries Maximum tokenId supported for different series. (Should be sorted in order).
    /// @param tokenAddress Token address if currency is ERC20.
    /// @param oracleCurrencyPair Currency pair to get price from oracle.
    function addNFTInPrimaryMarket(
        address nft,
        uint256[] calldata basePrices,
        string[] calldata series,
        uint256[] calldata maxTokenIdForSeries,
        address tokenAddress,
        string calldata oracleCurrencyPair
    )
        external;

    /// @notice Allow the owner to remove the given NFT from the listings.
    /// @param nft Address of the NFT that needs to be unlisted.
    function removeNFTFromPrimaryMarket(address nft) external;

    /// @notice Allow a user to purchase the NFTs in batch.
    /// @param nft Address of the NFT which need to get purcahse.
    /// @param receiver Address of the receiver.
    /// @param tokenURIs URIs for the tokenIds that get minted.
    /// @param expiry Expiry of the signature.
    /// @param signature Offchain signature of the authorised address.
    /// @param amount Amount of tokens if currency is ERC20.
    function batchPurchaseNFT(
        address nft,
        address receiver,
        uint256 expiry,
        bytes memory signature,
        uint256 amount,
        string[] memory tokenURIs
    )
        external
        payable;
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.6.0) (interfaces/IERC2981.sol)

pragma solidity ^0.8.0;

import "../utils/introspection/IERC165.sol";

/**
 * @dev Interface for the NFT Royalty Standard.
 *
 * A standardized way to retrieve royalty payment information for non-fungible tokens (NFTs) to enable universal
 * support for royalty payments across all NFT marketplaces and ecosystem participants.
 *
 * _Available since v4.5._
 */
interface IERC2981 is IERC165 {
    /**
     * @dev Returns how much royalty is owed and to whom, based on a sale price that may be denominated in any unit of
     * exchange. The royalty amount is denominated and should be paid in that same unit of exchange.
     */
    function royaltyInfo(uint256 tokenId, uint256 salePrice)
        external
        view
        returns (address receiver, uint256 royaltyAmount);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (token/ERC20/utils/SafeERC20.sol)

pragma solidity ^0.8.0;

import "../IERC20.sol";
import "../extensions/draft-IERC20Permit.sol";
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

    function safePermit(
        IERC20Permit token,
        address owner,
        address spender,
        uint256 value,
        uint256 deadline,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) internal {
        uint256 nonceBefore = token.nonces(owner);
        token.permit(owner, spender, value, deadline, v, r, s);
        uint256 nonceAfter = token.nonces(owner);
        require(nonceAfter == nonceBefore + 1, "SafeERC20: permit did not succeed");
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
// OpenZeppelin Contracts v4.4.1 (token/ERC20/extensions/IERC20Metadata.sol)

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

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/cryptography/draft-EIP712.sol)

pragma solidity ^0.8.0;

import "./ECDSA.sol";

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
abstract contract EIP712 {
    /* solhint-disable var-name-mixedcase */
    // Cache the domain separator as an immutable value, but also store the chain id that it corresponds to, in order to
    // invalidate the cached domain separator if the chain id changes.
    bytes32 private immutable _CACHED_DOMAIN_SEPARATOR;
    uint256 private immutable _CACHED_CHAIN_ID;
    address private immutable _CACHED_THIS;

    bytes32 private immutable _HASHED_NAME;
    bytes32 private immutable _HASHED_VERSION;
    bytes32 private immutable _TYPE_HASH;

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
    constructor(string memory name, string memory version) {
        bytes32 hashedName = keccak256(bytes(name));
        bytes32 hashedVersion = keccak256(bytes(version));
        bytes32 typeHash = keccak256(
            "EIP712Domain(string name,string version,uint256 chainId,address verifyingContract)"
        );
        _HASHED_NAME = hashedName;
        _HASHED_VERSION = hashedVersion;
        _CACHED_CHAIN_ID = block.chainid;
        _CACHED_DOMAIN_SEPARATOR = _buildDomainSeparator(typeHash, hashedName, hashedVersion);
        _CACHED_THIS = address(this);
        _TYPE_HASH = typeHash;
    }

    /**
     * @dev Returns the domain separator for the current chain.
     */
    function _domainSeparatorV4() internal view returns (bytes32) {
        if (address(this) == _CACHED_THIS && block.chainid == _CACHED_CHAIN_ID) {
            return _CACHED_DOMAIN_SEPARATOR;
        } else {
            return _buildDomainSeparator(_TYPE_HASH, _HASHED_NAME, _HASHED_VERSION);
        }
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
        return ECDSA.toTypedDataHash(_domainSeparatorV4(), structHash);
    }
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.15;

interface IOracleRegistry {
    function decimals(string memory target) external view returns (uint8);

    function description(string memory target)
        external
        view
        returns (string memory);

    function latestRoundData(string memory target)
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
// OpenZeppelin Contracts v4.4.1 (token/ERC20/extensions/draft-IERC20Permit.sol)

pragma solidity ^0.8.0;

/**
 * @dev Interface of the ERC20 Permit extension allowing approvals to be made via signatures, as defined in
 * https://eips.ethereum.org/EIPS/eip-2612[EIP-2612].
 *
 * Adds the {permit} method, which can be used to change an account's ERC20 allowance (see {IERC20-allowance}) by
 * presenting a message signed by the account. By not relying on {IERC20-approve}, the token holder account doesn't
 * need to send a transaction, and thus is not required to hold Ether at all.
 */
interface IERC20Permit {
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
// OpenZeppelin Contracts (last updated v4.7.3) (utils/cryptography/ECDSA.sol)

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
        if (signature.length == 65) {
            bytes32 r;
            bytes32 s;
            uint8 v;
            // ecrecover takes the signature parameters, and the only way to get them
            // currently is to use assembly.
            /// @solidity memory-safe-assembly
            assembly {
                r := mload(add(signature, 0x20))
                s := mload(add(signature, 0x40))
                v := byte(0, mload(add(signature, 0x60)))
            }
            return tryRecover(hash, v, r, s);
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