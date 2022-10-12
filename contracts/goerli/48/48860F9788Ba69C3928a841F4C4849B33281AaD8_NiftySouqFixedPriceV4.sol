// SPDX-License-Identifier: UNLICENSED

pragma solidity ^0.8.4;

import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC20/utils/SafeERC20Upgradeable.sol";

import "./interface/NiftySouq-IMarketplace.sol";
import "./interface/NiftySouq-IMarketplaceManager.sol";
import "./interface/NiftySouq-IERC721.sol";
import "./interface/NiftySouq-IERC1155.sol";

struct PurchaseOffer {
    address offeredBy;
    uint256 quantity;
    uint256 price;
    uint256 offeredAt;
    bool canceled;
}

struct Sale {
    uint256 tokenId;
    address tokenContract;
    bool isERC1155;
    uint256 quantity;
    uint256 price;
    address seller;
    uint256 createdAt;
    uint256 soldQuantity;
    address[] buyer;
    uint256[] purchaseQuantity;
    uint256[] soldAt;
    bool isBargainable;
    PurchaseOffer[] offers;
}

struct SellData {
    uint256 offerId;
    uint256 tokenId;
    address tokenContract;
    bool isERC1155;
    uint256 quantity;
    uint256 price;
    address seller;
    string currency;
}

struct LazyMintData {
    uint256 offerId;
    uint256 tokenId;
    address tokenContract;
    bool isERC1155;
    uint256 quantity;
    uint256 price;
    address seller;
    address buyer;
    uint256 purchaseQuantity;
    address[] investors;
    uint256[] revenues;
    string currency;
}

struct BuyNFT {
    uint256 offerId;
    address buyer;
    uint256 quantity;
    uint256 payment;
}

struct AcceptOfferData {
    uint256 offerId;
    uint256 tokenId;
    address tokenContract;
    bool isERC1155;
    uint256 quantity;
    uint256 price;
    address seller;
    uint256 createdAt;
    address buyer;
    uint256 soldAt;
    string currency;
}

struct Payout {
    address currency;
    address seller;
    address buyer;
    uint256 tokenId;
    address tokenAddress;
    uint256 quantity;
    address[] refundAddresses;
    uint256[] refundAmount;
    bool soldout;
}

struct CalculatePayout1155 {
    uint256 price;
    uint256 totalSupply;
    uint256 quantity;
    uint256 serviceFeePercent;
    address admin;
    address seller;
    address[] creators;
    uint256[] royalties;
    address[] investors;
    uint256[] revenues;
    uint256 firstSaleQuantity;
}

contract NiftySouqFixedPriceV4 is Initializable {
    using SafeMath for uint256;
    using SafeERC20Upgradeable for IERC20Upgradeable;

    uint256 public constant PERCENT_UNIT = 1e4;

    address private _marketplace;
    NiftySouqIMarketplaceManager private _marketplaceManager;

    mapping(uint256 => Sale) private _sale;
    mapping(uint256 => string) private _saleCurrency;

    mapping(string => bool) public isSalesupportedTokens;

    event eFixedPriceSale(
        uint256 offerId,
        uint256 tokenId,
        address contractAddress,
        bool isERC1155,
        address owner,
        uint256 quantity,
        uint256 price
    );
    event eUpdateSalePrice(uint256 offerId, uint256 price);
    event eCancelSale(uint256 offerId);
    event ePurchase(
        uint256 offerId,
        address buyer,
        address currency,
        uint256 quantity,
        bool isSaleCompleted
    );

    event ePayoutTransfer(
        address indexed withdrawer,
        uint256 indexed amount,
        address indexed currency
    );

    modifier isNiftyMarketplace() {
        require(
            msg.sender == _marketplace,
            "Nifty721: unauthorized. not niftysouq marketplace"
        );
        _;
    }

    function initialize(address marketplace_, address marketplaceManager_)
        public
        initializer
    {
        _marketplace = marketplace_;
        _marketplaceManager = NiftySouqIMarketplaceManager(marketplaceManager_);
    }

    function enableDisableSaleToken(string memory tokenName_, bool enable_)
        public
    {
        isSalesupportedTokens[tokenName_] = enable_;
    }

    function getSaleDetails(uint256 offerId_)
        external
        view
        returns (Sale memory sale_)
    {
        sale_ = _sale[offerId_];
    }

    //Sell
    function sellNft(
        uint256 tokenId_,
        address tokenAddress_,
        uint256 price_,
        uint256 quantity_,
        string memory currency_
    ) public returns (uint256 offerId_) {
        (
            ContractType contractType,
            bool isERC1155,
            bool isOwner,
            uint256 quantity
        ) = _marketplaceManager.isOwnerOfNFT(
                msg.sender,
                tokenId_,
                tokenAddress_
            );
        require(isOwner, "seller not owner");
        require(quantity >= quantity_, "insufficient token balance");
        offerId_ = NiftySouqIMarketplace(_marketplace).createSale(
            tokenId_,
            NiftySouqIMarketplace.ContractType(uint256(contractType)),
            NiftySouqIMarketplace.OfferType.SALE
        );

        SellData memory sellData = SellData(
            offerId_,
            tokenId_,
            tokenAddress_,
            isERC1155,
            isERC1155 ? quantity_ : 1,
            price_,
            msg.sender,
            currency_
        );
        _sell(sellData);
        emit eFixedPriceSale(
            offerId_,
            tokenId_,
            tokenAddress_,
            isERC1155,
            msg.sender,
            isERC1155 ? quantity_ : 1,
            price_
        );
    }

    //Mint & Sell
    function mintSellNft(
        NiftySouqIMarketplace.MintData memory mintData_,
        uint256 price_,
        string memory currency_
    ) public returns (uint256 tokenId_, uint256 offerId_) {
        (uint256 tokenId, , address tokenAddress) = NiftySouqIMarketplace(
            _marketplace
        ).mintNft(mintData_);
        tokenId_ = tokenId;

        offerId_ = sellNft(
            tokenId,
            tokenAddress,
            price_,
            mintData_.quantity,
            currency_
        );
    }

    //Update Price
    function updateSalePrice(
        uint256 offerId_,
        uint256 updatedPrice_,
        string memory currency_
    ) public {
        NiftySouqIMarketplace.Offer memory offer = NiftySouqIMarketplace(
            _marketplace
        ).getOfferStatus(offerId_);
        require(
            offer.offerType == NiftySouqIMarketplace.OfferType.SALE,
            "offer id is not sale"
        );
        require(
            offer.status == NiftySouqIMarketplace.OfferState.OPEN,
            "offer is not active"
        );
        _updateSalePrice(offerId_, currency_, updatedPrice_, msg.sender);
        emit eUpdateSalePrice(offerId_, updatedPrice_);
    }

    //Cancel Sale
    function cancelSale(uint256 offerId_) public {
        NiftySouqIMarketplace.Offer memory offer = NiftySouqIMarketplace(
            _marketplace
        ).getOfferStatus(offerId_);
        require(
            offer.offerType == NiftySouqIMarketplace.OfferType.SALE,
            "offer id is not sale"
        );
        require(
            offer.status == NiftySouqIMarketplace.OfferState.OPEN,
            "offer is not active"
        );
        NiftySouqIMarketplace(_marketplace).endSale(
            offerId_,
            NiftySouqIMarketplace.OfferState.CANCELLED
        );

        emit eCancelSale(offerId_);
    }

    //Purchase
    function buyNft(uint256 offerId_, uint256 quantity_) public payable {
        NiftySouqIMarketplace.Offer memory offer = NiftySouqIMarketplace(
            _marketplace
        ).getOfferStatus(offerId_);
        require(
            offer.offerType == NiftySouqIMarketplace.OfferType.SALE,
            "offer id is not sale"
        );
        require(
            offer.status == NiftySouqIMarketplace.OfferState.OPEN,
            "offer is not active"
        );
        Payout memory payoutData = _buyNft(
            BuyNFT(offerId_, msg.sender, quantity_, msg.value)
        );

        _payout(
            NiftySouqIMarketplace.Payout(
                payoutData.currency,
                payoutData.refundAddresses,
                payoutData.refundAmount
            )
        );

        NiftySouqIMarketplace(_marketplace).transferNFT(
            payoutData.seller,
            payoutData.buyer,
            payoutData.tokenId,
            payoutData.tokenAddress,
            payoutData.quantity
        );

        if (payoutData.soldout) {
            NiftySouqIMarketplace(_marketplace).endSale(
                offerId_,
                NiftySouqIMarketplace.OfferState.ENDED
            );
            emit ePurchase(offerId_, msg.sender, address(0), quantity_, true);
        } else {
            emit ePurchase(offerId_, msg.sender, address(0), quantity_, false);
        }
    }

    //accept offer
    function acceptOffer(AcceptOfferData calldata acceptOfferData_)
        external
        isNiftyMarketplace
        returns (Payout memory payout_)
    {
        _sale[acceptOfferData_.offerId].tokenId = acceptOfferData_.tokenId;
        _sale[acceptOfferData_.offerId].tokenContract = acceptOfferData_
            .tokenContract;
        _sale[acceptOfferData_.offerId].isERC1155 = acceptOfferData_.isERC1155;
        _sale[acceptOfferData_.offerId].quantity = acceptOfferData_.quantity;
        _sale[acceptOfferData_.offerId].price = acceptOfferData_.price;
        _sale[acceptOfferData_.offerId].seller = acceptOfferData_.seller;
        _sale[acceptOfferData_.offerId].createdAt = block.timestamp;
        _sale[acceptOfferData_.offerId].soldQuantity = acceptOfferData_
            .quantity;
        _sale[acceptOfferData_.offerId].buyer.push(acceptOfferData_.buyer);
        _sale[acceptOfferData_.offerId].purchaseQuantity.push(
            acceptOfferData_.quantity
        );
        _sale[acceptOfferData_.offerId].soldAt.push(block.timestamp);
        _saleCurrency[acceptOfferData_.offerId] = acceptOfferData_.currency;

        (
            address[] memory recipientAddresses,
            uint256[] memory paymentAmount,
            ,

        ) = _marketplaceManager.calculatePayout(
                CalculatePayout(
                    acceptOfferData_.tokenId,
                    acceptOfferData_.tokenContract,
                    acceptOfferData_.seller,
                    acceptOfferData_.price,
                    acceptOfferData_.quantity
                )
            );
        payout_ = Payout(
            address(0),
            acceptOfferData_.seller,
            acceptOfferData_.buyer,
            acceptOfferData_.tokenId,
            acceptOfferData_.tokenContract,
            acceptOfferData_.quantity,
            recipientAddresses,
            paymentAmount,
            true
        );
    }

    function _sell(SellData memory sell_) internal {
        _sale[sell_.offerId].tokenId = sell_.tokenId;
        _sale[sell_.offerId].tokenContract = sell_.tokenContract;
        _sale[sell_.offerId].isERC1155 = sell_.isERC1155;
        _sale[sell_.offerId].quantity = sell_.quantity;
        _sale[sell_.offerId].price = sell_.price;
        _sale[sell_.offerId].seller = sell_.seller;
        _sale[sell_.offerId].isBargainable = false;
        _sale[sell_.offerId].createdAt = block.timestamp;
        _saleCurrency[sell_.offerId] = sell_.currency;
    }

    function lazyMint(LazyMintData calldata lazyMintData_) external {
        _sale[lazyMintData_.offerId].tokenId = lazyMintData_.tokenId;
        _sale[lazyMintData_.offerId].tokenContract = lazyMintData_
            .tokenContract;
        _sale[lazyMintData_.offerId].isERC1155 = lazyMintData_.isERC1155;
        _sale[lazyMintData_.offerId].quantity = lazyMintData_.quantity;
        _sale[lazyMintData_.offerId].price = lazyMintData_.price;
        _sale[lazyMintData_.offerId].seller = lazyMintData_.seller;
        _sale[lazyMintData_.offerId].createdAt = block.timestamp;
        _sale[lazyMintData_.offerId].soldQuantity = lazyMintData_
            .purchaseQuantity;
        _sale[lazyMintData_.offerId].buyer.push(lazyMintData_.buyer);
        _sale[lazyMintData_.offerId].purchaseQuantity.push(
            lazyMintData_.purchaseQuantity
        );
        _sale[lazyMintData_.offerId].soldAt.push(block.timestamp);
        _saleCurrency[lazyMintData_.offerId] = lazyMintData_.currency;

        emit eFixedPriceSale(
            lazyMintData_.offerId,
            lazyMintData_.tokenId,
            lazyMintData_.tokenContract,
            lazyMintData_.isERC1155,
            lazyMintData_.seller,
            lazyMintData_.quantity,
            lazyMintData_.price
        );

        emit ePurchase(
            lazyMintData_.offerId,
            lazyMintData_.buyer,
            address(0),
            lazyMintData_.quantity,
            lazyMintData_.purchaseQuantity == lazyMintData_.quantity
                ? true
                : false
        );
    }

    //Update Price
    function _updateSalePrice(
        uint256 offerId_,
        string memory currency_,
        uint256 updatedPrice_,
        address seller_
    ) internal {
        require(seller_ == _sale[offerId_].seller, "user not seller");
        _sale[offerId_].price = updatedPrice_;
        _saleCurrency[offerId_] = currency_;
    }

    //Purchase
    function _buyNft(BuyNFT memory buyNft_)
        internal
        returns (Payout memory payout_)
    {
        Sale memory sale = _sale[buyNft_.offerId];
        CryptoTokens memory tokenDetails;
        if (sale.isERC1155) {
            uint256 serviceFee = _percent(
                (sale.price).mul(buyNft_.quantity),
                _marketplaceManager.serviceFeePercent()
            );
            if (
                keccak256(abi.encodePacked(_saleCurrency[buyNft_.offerId])) ==
                keccak256(abi.encodePacked(""))
            ) {
                require(
                    buyNft_.payment >=
                        serviceFee.add((sale.price).mul(buyNft_.quantity)),
                    "not enough funds sent"
                );
            } else {
                require(
                    isSalesupportedTokens[_saleCurrency[buyNft_.offerId]],
                    "unsupported token"
                );
                tokenDetails = _marketplaceManager.cryptoTokenList(
                    _saleCurrency[buyNft_.offerId]
                );
                uint256 allowance = IERC20Upgradeable(tokenDetails.tokenAddress)
                    .allowance(msg.sender, address(this));
                require(
                    allowance >=
                        serviceFee.add((sale.price).mul(buyNft_.quantity)),
                    "not enough token allowance"
                );
                IERC20Upgradeable(tokenDetails.tokenAddress).transferFrom(
                    msg.sender,
                    address(this),
                    serviceFee.add((sale.price).mul(buyNft_.quantity))
                );
            }

            (
                address[] memory recipientAddresses,
                uint256[] memory paymentAmount,
                ,

            ) = _marketplaceManager.calculatePayout(
                    CalculatePayout(
                        sale.tokenId,
                        sale.tokenContract,
                        sale.seller,
                        sale.price,
                        buyNft_.quantity
                    )
                );

            payout_ = Payout(
                tokenDetails.tokenAddress,
                sale.seller,
                buyNft_.buyer,
                sale.tokenId,
                sale.tokenContract,
                buyNft_.quantity,
                recipientAddresses,
                paymentAmount,
                sale.quantity == sale.soldQuantity.add(buyNft_.quantity)
                    ? true
                    : false
            );
        } else {
            uint256 offerId = buyNft_.offerId;
            uint256 serviceFee = _percent(
                sale.price,
                _marketplaceManager.serviceFeePercent()
            );
            if (
                keccak256(abi.encodePacked(_saleCurrency[buyNft_.offerId])) ==
                keccak256(abi.encodePacked(""))
            ) {
                require(
                    buyNft_.payment >= (serviceFee.add(_sale[offerId].price)),
                    "not enough funds sent"
                );
            } else {
                require(
                    isSalesupportedTokens[_saleCurrency[buyNft_.offerId]],
                    "unsupported token"
                );
                tokenDetails = _marketplaceManager.cryptoTokenList(
                    _saleCurrency[buyNft_.offerId]
                );
                uint256 allowance = IERC20Upgradeable(tokenDetails.tokenAddress)
                    .allowance(msg.sender, address(this));
                require(
                    allowance >= (serviceFee.add(_sale[offerId].price)),
                    "not enough token allowance"
                );

                IERC20Upgradeable(tokenDetails.tokenAddress).transferFrom(
                    msg.sender,
                    address(this),
                    serviceFee.add(_sale[offerId].price)
                );
            }
            (
                address[] memory recipientAddresses,
                uint256[] memory paymentAmount,
                ,

            ) = _marketplaceManager.calculatePayout(
                    CalculatePayout(
                        sale.tokenId,
                        sale.tokenContract,
                        sale.seller,
                        _sale[offerId].price,
                        buyNft_.quantity
                    )
                );
            payout_ = Payout(
                tokenDetails.tokenAddress,
                sale.seller,
                buyNft_.buyer,
                sale.tokenId,
                sale.tokenContract,
                1,
                recipientAddresses,
                paymentAmount,
                true
            );
        }
        _sale[buyNft_.offerId].soldQuantity = _sale[buyNft_.offerId]
            .soldQuantity
            .add(buyNft_.quantity);
        _sale[buyNft_.offerId].buyer.push(buyNft_.buyer);
        _sale[buyNft_.offerId].purchaseQuantity.push(buyNft_.quantity);
        _sale[buyNft_.offerId].soldAt.push(block.timestamp);
    }

    function _percent(uint256 value_, uint256 percentage_)
        internal
        pure
        virtual
        returns (uint256)
    {
        uint256 result = value_.mul(percentage_).div(PERCENT_UNIT);
        return (result);
    }

    function _payout(NiftySouqIMarketplace.Payout memory payoutData_) internal {
        for (uint256 i = 0; i < payoutData_.refundAddresses.length; i++) {
            if (payoutData_.refundAddresses[i] != address(0)) {
                if (address(0) == payoutData_.currency) {
                    payable(payoutData_.refundAddresses[i]).transfer(
                        payoutData_.refundAmounts[i]
                    );
                } else {
                    IERC20Upgradeable(payoutData_.currency).safeTransfer(
                        payoutData_.refundAddresses[i],
                        payoutData_.refundAmounts[i]
                    );
                }
                emit ePayoutTransfer(
                    payoutData_.refundAddresses[i],
                    payoutData_.refundAmounts[i],
                    payoutData_.currency
                );
            }
        }
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.10;

interface NiftySouqIMarketplace {
    enum ContractType {
        NIFTY_V1,
        NIFTY_V2,
        COLLECTOR,
        EXTERNAL,
        UNSUPPORTED
    }

    enum OfferState {
        OPEN,
        CANCELLED,
        ENDED
    }

    enum OfferType {
        SALE,
        AUCTION
    }

    struct Offer {
        uint256 tokenId;
        OfferType offerType;
        OfferState status;
        ContractType contractType;
    }

    struct MintData {
        address minter;
        address tokenAddress;
        string uri;
        address[] creators;
        uint256[] royalties;
        address[] investors;
        uint256[] revenues;
        uint256 quantity;
    }

    struct Payout {
        address currency;
        address[] refundAddresses;
        uint256[] refundAmounts;
    }

    function mintNft(MintData memory mintData_)
        external
        returns (
            uint256 tokenId_,
            bool erc1155_,
            address tokenAddress_
        );

    function createSale(uint256 tokenId_, ContractType contractType_, OfferType offerType_)
        external
        returns (uint256 offerId_);

    function endSale(uint256 offerId_, OfferState offerState_) external;

    function payout(Payout memory payoutData_) external;

    function transferNFT(
        address from_,
        address to_,
        uint256 tokenId_,
        address tokenAddress_,
        uint256 quantity_
    ) external;

    function getOfferStatus(uint256 offerId_)
        external
        view
        returns (Offer memory offerDetails_);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.10;

interface NiftySouqIERC1155V2 {
    struct NftData {
        string uri;
        address[] creators;
        uint256[] royalties;
        address[] investors;
        uint256[] revenues;
        address minter;
        uint256 firstSaleQuantity;
    }

    struct MintData {
        string uri;
        address minter;
        address[] creators;
        uint256[] royalties;
        address[] investors;
        uint256[] revenues;
        uint256 quantity;
    }

    struct LazyMintData {
        string uri;
        address minter;
        address buyer;
        address[] creators;
        uint256[] royalties;
        address[] investors;
        uint256[] revenues;
        uint256 quantity;
        uint256 soldQuantity;
    }

    function getNftInfo(uint256 tokenId_)
        external
        view
        returns (NftData memory nfts_);

    function totalSupply(uint256 tokenId)
        external
        view
        returns (uint256 totalSupply_);

    function mint(MintData calldata mintData_)
        external
        returns (uint256 tokenId_);

    function lazyMint(LazyMintData calldata lazyMintData_)
        external
        returns (uint256 tokenId_);

    function safeTransferFrom(
        address from,
        address to,
        uint256 id,
        uint256 amount,
        bytes memory data
    ) external;

    function transferNft(
        address from_,
        address to_,
        uint256 tokenId_,
        uint256 quantity_
    ) external;
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.10;

enum ContractType {
    NIFTY_V1,
    NIFTY_V2,
    COLLECTOR,
    EXTERNAL,
    UNSUPPORTED
}
struct CalculatePayout {
    uint256 tokenId;
    address contractAddress;
    address seller;
    uint256 price;
    uint256 quantity;
}

struct LazyMintSellData {
    address tokenAddress;
    string uri;
    address seller;
    address[] creators;
    uint256[] royalties;
    address[] investors;
    uint256[] revenues;
    uint256 minPrice;
    uint256 quantity;
    bytes signature;
    string currency;
}

struct LazyMintAuctionData {
    address tokenAddress;
    string uri;
    address seller;
    address[] creators;
    uint256[] royalties;
    address[] investors;
    uint256[] revenues;
    uint256 startTime;
    uint256 duration;
    uint256 startBidPrice;
    uint256 reservePrice;
    bytes signature;
}

struct CryptoTokens {
    address tokenAddress;
    uint256 tokenValue;
    bool isEnabled;
}

interface NiftySouqIMarketplaceManager {
    function owner() external returns (address);

    function isAdmin(address caller_) external view returns (bool);

    function serviceFeeWallet() external returns (address);

    function serviceFeePercent() external returns (uint256);

    function cryptoTokenList(string memory)
        external
        returns (CryptoTokens memory);

    function verifyFixedPriceLazyMintV1(LazyMintSellData calldata lazyData_)
        external
        returns (address);

    function verifyFixedPriceLazyMintV2(LazyMintSellData calldata lazyData_)
        external
        returns (address);

    function verifyAuctionLazyMint(LazyMintAuctionData calldata lazyData_)
        external
        returns (address);

    function getContractDetails(address contractAddress_, uint256 quantity_)
        external
        returns (
            ContractType contractType_,
            bool isERC1155_,
            address tokenAddress_
        );

    function isOwnerOfNFT(
        address address_,
        uint256 tokenId_,
        address contractAddress_
    )
        external
        returns (
            ContractType contractType_,
            bool isERC1155_,
            bool isOwner_,
            uint256 quantity_
        );

    function calculatePayout(CalculatePayout memory calculatePayout_)
        external
        returns (
            address[] memory recepientAddresses_,
            uint256[] memory paymentAmount_,
            bool isTokenTransferable_,
            bool isOwner_
        );
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.10;

interface NiftySouqIERC721V2 {
    struct NftData {
        string uri;
        address[] creators;
        uint256[] royalties;
        address[] investors;
        uint256[] revenues;
        bool isFirstSale;
    }

    struct MintData {
        string uri;
        address minter;
        address[] creators;
        uint256[] royalties;
        address[] investors;
        uint256[] revenues;
        bool isFirstSale;
    }

    function ownerOf(uint256 tokenId) external view returns (address owner);

    function getNftInfo(uint256 tokenId_)
        external
        view
        returns (NftData memory nfts_);

    function mint(MintData calldata mintData_)
        external
        returns (uint256 tokenId_);

    function transferFrom(
        address from,
        address to,
        uint256 tokenId
    ) external;

    function transferNft(
        address from_,
        address to_,
        uint256 tokenId_
    ) external;
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
// OpenZeppelin Contracts (last updated v4.6.0) (utils/math/SafeMath.sol)

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
library SafeMath {
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
     * @dev Returns the subtraction of two unsigned integers, with an overflow flag.
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
// OpenZeppelin Contracts (last updated v4.7.0) (token/ERC20/utils/SafeERC20.sol)

pragma solidity ^0.8.0;

import "../IERC20Upgradeable.sol";
import "../extensions/draft-IERC20PermitUpgradeable.sol";
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

    function safePermit(
        IERC20PermitUpgradeable token,
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
// OpenZeppelin Contracts (last updated v4.6.0) (token/ERC20/IERC20.sol)

pragma solidity ^0.8.0;

/**
 * @dev Interface of the ERC20 standard as defined in the EIP.
 */
interface IERC20Upgradeable {
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