// SPDX-License-Identifier: UNLICENSED

pragma solidity ^0.8.4;
pragma abicoder v2;

import "./interface/NiftySouq-IMarketplaceManager.sol";
import "./interface/NiftySouq-IERC721.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";

struct Bid {
    address bidder;
    uint256 price;
    uint256 bidAt;
    bool canceled;
}

struct Auction {
    uint256 tokenId;
    address tokenContract;
    uint256 startTime;
    uint256 endTime;
    address seller;
    uint256 startBidPrice;
    uint256 reservePrice;
    uint256 highestBidIdx;
    uint256 selectedBid;
    Bid[] bids;
}

struct CreateAuction {
    uint256 offerId;
    uint256 tokenId;
    address tokenContract;
    uint256 startTime;
    uint256 duration;
    address seller;
    uint256 startBidPrice;
    uint256 reservePrice;
}

contract NiftySouqAuctionV2 is Initializable {
    using SafeMath for uint256;

    uint256 public constant PERCENT_UNIT = 1e4;
    uint256 public bidIncreasePercentage;

    address private _marketplace;
    NiftySouqIMarketplaceManager private _marketplaceManager;

    mapping(uint256 => Auction) private _auction;

    modifier isNiftyMarketplace() {
        require(
            msg.sender == _marketplace,
            "Nifty721: unauthorized. not niftysouq marketplace"
        );
        _;
    }

    function initialize(
        address marketplace_,
        address marketplaceManager_,
        uint256 bidIncreasePercentage_
    ) public initializer {
        _marketplace = marketplace_;
        _marketplaceManager = NiftySouqIMarketplaceManager(marketplaceManager_);
        bidIncreasePercentage = bidIncreasePercentage_;
    }

    function createAuction(CreateAuction calldata createAuctionData_)
        external
        isNiftyMarketplace
    {
        _auction[createAuctionData_.offerId].tokenId = createAuctionData_
            .tokenId;
        _auction[createAuctionData_.offerId].tokenContract = createAuctionData_
            .tokenContract;
        _auction[createAuctionData_.offerId].startTime = createAuctionData_
            .startTime;
        _auction[createAuctionData_.offerId].endTime = createAuctionData_
            .startTime
            .add(createAuctionData_.duration);
        _auction[createAuctionData_.offerId].seller = createAuctionData_.seller;
        _auction[createAuctionData_.offerId].startBidPrice = createAuctionData_
            .startBidPrice;
        _auction[createAuctionData_.offerId].reservePrice = createAuctionData_
            .reservePrice;
    }

    function cancelAuction(uint256 offerId)
        external
        isNiftyMarketplace
        returns (
            address[] memory refundAddresses_,
            uint256[] memory refundAmount_
        )
    {
        refundAddresses_ = new address[](_auction[offerId].bids.length);
        refundAmount_ = new uint256[](_auction[offerId].bids.length);
        uint256 j = 0;
        for (uint256 i = 0; i < _auction[offerId].bids.length; i++) {
            Bid storage bid = _auction[offerId].bids[i];
            if (!bid.canceled) {
                refundAddresses_[j] = bid.bidder;
                refundAmount_[j] = bid.price;
                j = j.add(1);
                _auction[offerId].bids[i].canceled = true;
            }
        }
    }

    function placeBid(
        uint256 offerId,
        address bidder,
        uint256 bidPrice
    ) external isNiftyMarketplace returns (uint256 bidIdx_) {
        require(_auction[offerId].seller != bidder, "seller can not bid");

        uint256 highestBidPrice = _auction[offerId].startBidPrice;

        if (_auction[offerId].bids.length > 0) {
            Bid storage highestBid = _auction[offerId].bids[
                _auction[offerId].highestBidIdx
            ];
            require(highestBid.bidder != bidder, "already bid");

            highestBidPrice = highestBid
                .price
                .mul(PERCENT_UNIT + bidIncreasePercentage)
                .div(PERCENT_UNIT);

            require(highestBidPrice > highestBid.price, "not enough bid");
        }

        require(bidPrice >= highestBidPrice, "not enough bid");

        _auction[offerId].bids.push(
            Bid({
                bidder: bidder,
                price: bidPrice,
                bidAt: block.timestamp,
                canceled: false
            })
        );

        _auction[offerId].highestBidIdx = _auction[offerId].bids.length - 1;
        bidIdx_ = _auction[offerId].highestBidIdx;
    }

    function placeHigherBid(
        uint256 offerId,
        address bidder,
        uint256 bidIdx,
        uint256 bidPrice
    ) external isNiftyMarketplace returns (uint256 currentBidPrice_) {
        require(bidIdx < _auction[offerId].bids.length, "invalid bid");
        require(
            bidder == _auction[offerId].bids[bidIdx].bidder,
            "not the bidder"
        );
        require(
            _auction[offerId].highestBidIdx != bidIdx,
            "Already highest bidder"
        );

        Bid storage bid = _auction[offerId].bids[bidIdx];
        Bid storage highestBid = _auction[offerId].bids[
            _auction[offerId].highestBidIdx
        ];

        uint256 requiredMinBidPrice = highestBid
            .price
            .mul(PERCENT_UNIT + bidIncreasePercentage)
            .div(PERCENT_UNIT);

        require(
            bidPrice.add(bid.price) > requiredMinBidPrice,
            "not enough bid"
        );

        _auction[offerId].bids[bidIdx].price = bidPrice.add(bid.price);

        _auction[offerId].highestBidIdx = bidIdx;
        currentBidPrice_ = _auction[offerId].bids[bidIdx].price;
    }

    function cancelBid(
        uint256 offerId,
        address bidder,
        uint256 bidIdx
    )
        external
        isNiftyMarketplace
        returns (
            address[] memory refundAddresses_,
            uint256[] memory refundAmount_
        )
    {
        require(bidIdx < _auction[offerId].bids.length, "invalid bid");
        require(
            bidder == _auction[offerId].bids[bidIdx].bidder,
            "not a bidder"
        );
        refundAddresses_ = new address[](1);
        refundAmount_ = new uint256[](1);
        _auction[offerId].bids[bidIdx].canceled = true;
        refundAddresses_[0] = _auction[offerId].bids[bidIdx].bidder;
        refundAmount_[0] = _auction[offerId].bids[bidIdx].price;

        // update highest bidder
        if (_auction[offerId].highestBidIdx == bidIdx) {
            for (uint256 i = bidIdx; i >= 0; i--) {
                if (!_auction[offerId].bids[i].canceled) {
                    _auction[offerId].highestBidIdx = i;
                    break;
                }
            }
        }
    }

    function endAuction(
        uint256 offerId_,
        address creator,
        uint256 bidIdx
    )
        public
        isNiftyMarketplace
        returns (
            uint256 bidAmount_,
            address[] memory recipientAddresses_,
            uint256[] memory paymentAmount_
        )
    {
        require(creator == _auction[offerId_].seller, "not seller");
        require(bidIdx < _auction[offerId_].bids.length, "invalid bid");
        require(
            _auction[offerId_].bids[bidIdx].canceled == false,
            "bid already canceled"
        );
        NiftySouqIERC721V2.NftData memory nftData = NiftySouqIERC721V2(
            _auction[offerId_].tokenContract
        ).getNftInfo(_auction[offerId_].tokenId);
        uint256 serviceFeePercentage = _marketplaceManager.serviceFeePercent();
        address serviceFeeWallet = _marketplaceManager.serviceFeeWallet();
        uint256 offerId = offerId_;
        uint256 j = 0;

        if (nftData.isFirstSale) {
            (
                uint256 adminfee,
                uint256[] memory payoutFees,
                uint256 netfee
            ) = _calculatePayout(
                    _auction[offerId].bids[bidIdx].price,
                    serviceFeePercentage,
                    nftData.revenues
                );

            recipientAddresses_ = new address[](
                (_auction[offerId].bids.length).add(payoutFees.length).add(2)
            );
            paymentAmount_ = new uint256[](
                (_auction[offerId].bids.length).add(payoutFees.length).add(2)
            );

            recipientAddresses_[j] = serviceFeeWallet;
            paymentAmount_[j] = adminfee;
            j = j.add(1);

            recipientAddresses_[j] = _auction[offerId].seller;
            paymentAmount_[j] = netfee;
            j = j.add(1);

            for (uint256 i = 0; i < nftData.investors.length; i++) {
                recipientAddresses_[j] = nftData.investors[i];
                paymentAmount_[j] = payoutFees[i];
                j = j.add(1);
            }
        } else {
            (
                uint256 adminfee,
                uint256[] memory payoutFees,
                uint256 netfee
            ) = _calculatePayout(
                    _auction[offerId].bids[bidIdx].price,
                    serviceFeePercentage,
                    nftData.royalties
                );

            recipientAddresses_ = new address[](
                (_auction[offerId].bids.length).add(payoutFees.length).add(2)
            );
            paymentAmount_ = new uint256[](
                (_auction[offerId].bids.length).add(payoutFees.length).add(2)
            );

            recipientAddresses_[j] = serviceFeeWallet;
            paymentAmount_[j] = adminfee;
            j = j.add(1);

            recipientAddresses_[j] = _auction[offerId].seller;
            paymentAmount_[j] = netfee;
            j = j.add(1);

            for (uint256 i = 0; i < nftData.creators.length; i++) {
                recipientAddresses_[j] = nftData.creators[i];
                paymentAmount_[j] = payoutFees[i];
                j = j.add(1);
            }
        }

        // refund
        {
            for (uint256 i = 0; i < _auction[offerId].bids.length; i++) {
                Bid storage bid = _auction[offerId].bids[i];
                if (i != bidIdx && !bid.canceled) {
                    recipientAddresses_[j] = bid.bidder;
                    paymentAmount_[j] = bid.price;
                    j = j.add(1);
                    _auction[offerId].bids[i].canceled = true;
                }
            }
        }

        bidAmount_ = _auction[offerId_].bids[bidIdx].price;
    }

    function endAuctionWithHighestBid(uint256 offerId_, address creator_)
        external
        isNiftyMarketplace
        returns (
            uint256 bidIdx_,
            uint256 bidAmount_,
            address[] memory recipientAddresses_,
            uint256[] memory paymentAmount_
        )
    {
        bidIdx_ = _auction[offerId_].highestBidIdx;
        (bidAmount_, recipientAddresses_, paymentAmount_) = endAuction(
            offerId_,
            creator_,
            bidIdx_
        );
    }

    function getAuctionDetails(uint256 offerId_)
        external
        view
        returns (Auction memory auction_)
    {
        auction_ = _auction[offerId_];

    }

    function _calculatePayout(
        uint256 price_,
        uint256 serviceFeePercent_,
        uint256[] memory payouts_
    )
        internal
        view
        virtual
        returns (
            uint256 serviceFee_,
            uint256[] memory payoutFees_,
            uint256 netFee_
        )
    {
        payoutFees_ = new uint256[](payouts_.length);
        uint256 payoutSum = 0;
        serviceFee_ = percent(price_, serviceFeePercent_);

        for (uint256 i = 0; i < payouts_.length; i++) {
            uint256 royalFee = percent(price_, payouts_[i]);
            payoutFees_[i] = royalFee;
            payoutSum = payoutSum.add(royalFee);
        }

        netFee_ = price_.sub(serviceFee_).sub(payoutSum);
    }

    function percent(uint256 value_, uint256 percentage_)
        public
        pure
        virtual
        returns (uint256)
    {
        uint256 result = value_.mul(percentage_).div(PERCENT_UNIT);
        return (result);
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

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

// SPDX-License-Identifier: UNLICENSED

pragma solidity ^0.8.4;

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

interface NiftySouqIMarketplaceManager {
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

    function owner() external returns (address);

    function isAdmin(address caller_) external view returns (bool);

    function serviceFeeWallet() external returns (address);

    function serviceFeePercent() external returns (uint256);

    function cryptoTokenList(string memory)
        external
        returns (CryptoTokens memory);

    function verifyFixedPriceLazyMint(LazyMintSellData calldata lazyData_)
        external
        returns (address);

    function verifyAuctionLazyMint(LazyMintAuctionData calldata lazyData_)
        external
        returns (address);

    function getContractDetails(address contractAddress_, uint256 quantity_)
        external
        returns (ContractType contractType_, bool isERC1155_, address tokenAddress_);

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