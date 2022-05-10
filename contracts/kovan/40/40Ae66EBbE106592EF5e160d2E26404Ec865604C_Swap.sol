// SPDX-License-Identifier: MIT
// Source: https://github.com/airswap/airswap-protocols/blob/main/source/swap/contracts/Swap.sol

pragma solidity =0.8.4;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "../interfaces/ISwap.sol";
import {IERC20Detailed} from "../interfaces/IERC20Detailed.sol";

contract Swap is ISwap, ReentrancyGuard, Ownable {
    using SafeERC20 for IERC20;

    bytes32 public constant DOMAIN_TYPEHASH =
        keccak256(
            abi.encodePacked(
                "EIP712Domain(",
                "string name,",
                "string version,",
                "uint256 chainId,",
                "address verifyingContract",
                ")"
            )
        );

    bytes32 public constant BID_TYPEHASH =
        keccak256(
            abi.encodePacked(
                "Bid(",
                "uint256 swapId,",
                "uint256 nonce,",
                "address signerWallet,",
                "uint256 sellAmount,",
                "uint256 buyAmount,",
                "address referrer",
                ")"
            )
        );

    bytes32 public constant DOMAIN_NAME = keccak256("RIBBON SWAP");
    bytes32 public constant DOMAIN_VERSION = keccak256("1");
    uint256 public immutable DOMAIN_CHAIN_ID;
    bytes32 public immutable DOMAIN_SEPARATOR;

    uint256 internal constant MAX_PERCENTAGE = 10000;
    uint256 internal constant MAX_FEE = 1000;
    uint256 internal constant MAX_ERROR_COUNT = 10;
    uint256 internal constant OTOKEN_DECIMALS = 8;

    uint256 public offersCounter = 0;

    mapping(uint256 => Offer) public swapOffers;

    mapping(address => uint256) public referralFees;

    /**
     * @notice Double mapping of signers to nonce groups to nonce states
     * @dev The nonce group is computed as nonce / 256, so each group of 256 sequential nonces uses the same key
     * @dev The nonce states are encoded as 256 bits, for each nonce in the group 0 means available and 1 means used
     */
    mapping(address => mapping(uint256 => uint256)) internal _nonceGroups;

    /************************************************
     *  CONSTRUCTOR
     ***********************************************/

    constructor() {
        uint256 currentChainId = getChainId();
        DOMAIN_CHAIN_ID = currentChainId;
        DOMAIN_SEPARATOR = keccak256(
            abi.encode(
                DOMAIN_TYPEHASH,
                DOMAIN_NAME,
                DOMAIN_VERSION,
                currentChainId,
                this
            )
        );
    }

    /************************************************
     *  SETTER
     ***********************************************/

    /**
     * @notice Sets the referral fee for a specific referrer
     * @param referrer is the address of the referrer
     * @param fee is the fee in percent in 2 decimals
     */
    function setFee(address referrer, uint256 fee) external onlyOwner {
        require(referrer != address(0), "Referrer cannot be the zero address");
        require(fee < MAX_FEE, "Fee exceeds maximum");

        referralFees[referrer] = fee;

        emit SetFee(referrer, fee);
    }

    /************************************************
     *  OFFER CREATION AND SETTLEMENT
     ***********************************************/

    /**
     * @notice Create a new offer available for swap
     * @param oToken token offered by seller
     * @param biddingToken token asked by seller
     * @param minPrice minimum price of oToken denominated in biddingToken
     * @param minBidSize minimum amount of oToken requested in a single bid
     * @param totalSize amount of oToken offered by seller
     */
    function createOffer(
        address oToken,
        address biddingToken,
        uint96 minPrice,
        uint96 minBidSize,
        uint128 totalSize
    ) external override returns (uint256 swapId) {
        require(oToken != address(0), "oToken cannot be the zero address");
        require(
            biddingToken != address(0),
            "BiddingToken cannot be the zero address"
        );
        require(minPrice > 0, "MinPrice must be larger than zero");
        require(minBidSize > 0, "MinBidSize must be larger than zero");
        require(minBidSize <= totalSize, "MinBidSize exceeds total size");

        offersCounter += 1;

        swapId = offersCounter;

        swapOffers[swapId].seller = msg.sender;
        swapOffers[swapId].oToken = oToken;
        swapOffers[swapId].biddingToken = biddingToken;
        swapOffers[swapId].minBidSize = minBidSize;
        swapOffers[swapId].minPrice = minPrice;
        swapOffers[swapId].totalSize = totalSize;
        swapOffers[swapId].availableSize = totalSize;
        // We warm the storage slot with 1 wei so we avoid a cold SSTORE
        swapOffers[swapId].totalSales = 1;

        emit NewOffer(
            swapId,
            msg.sender,
            oToken,
            biddingToken,
            minPrice,
            minBidSize,
            totalSize
        );
    }

    /**
     * @notice Settles the swap offering by iterating through the bids
     * @param swapId unique identifier of the swap offer
     * @param bids bids for swaps
     */
    function settleOffer(uint256 swapId, Bid[] calldata bids)
        external
        override
        nonReentrant
    {
        Offer storage offer = swapOffers[swapId];

        address seller = offer.seller;
        require(
            seller == msg.sender,
            "Only seller can settle or offer doesn't exist"
        );
        require(offer.availableSize > 0, "Offer fully settled");

        uint256 totalSales;
        OfferDetails memory offerDetails;
        offerDetails.seller = seller;
        offerDetails.oToken = offer.oToken;
        offerDetails.biddingToken = offer.biddingToken;
        offerDetails.minPrice = offer.minPrice;
        offerDetails.minBidSize = offer.minBidSize;

        for (uint256 i = 0; i < bids.length; i++) {
            require(
                swapId == bids[i].swapId,
                "Offer and bid swapId mismatched"
            );

            _swap(offerDetails, offer, bids[i]);
            totalSales += bids[i].sellAmount;
        }

        bool fullySettled = offer.availableSize == 0;

        // Deduct the initial 1 wei offset if offer is fully settled
        offer.totalSales += totalSales - (fullySettled ? 1 : 0);

        if (fullySettled) {
            offer.seller = address(0);
            offer.oToken = address(0);
            offer.biddingToken = address(0);
            offer.minBidSize = 0;
            offer.minPrice = 0;

            emit SettleOffer(swapId);
        }
    }

    /**
     * @notice Cancel one or more nonces
     * @dev Cancelled nonces are marked as used
     * @dev Emits a Cancel event
     * @dev Out of gas may occur in arrays of length > 400
     * @param nonces uint256[] List of nonces to cancel
     */
    function cancelNonce(uint256[] calldata nonces) external override {
        for (uint256 i = 0; i < nonces.length; i++) {
            uint256 nonce = nonces[i];
            if (_markNonceAsUsed(msg.sender, nonce)) {
                emit Cancel(nonce, msg.sender);
            }
        }
    }

    /************************************************
     *  PUBLIC VIEW FUNCTIONS
     ***********************************************/

    /**
     * @notice Validates Swap bid for any potential errors
     * @param bid Bid struct containing bid details
     * @return tuple of error count and bytes32[] memory array of error messages
     */
    function check(Bid calldata bid)
        external
        view
        override
        returns (uint256, bytes32[] memory)
    {
        Offer memory offer = swapOffers[bid.swapId];
        require(offer.seller != address(0), "Offer does not exist");

        bytes32[] memory errors = new bytes32[](MAX_ERROR_COUNT);

        uint256 errCount;

        // Check signature
        address signatory = _getSignatory(bid);

        if (signatory == address(0)) {
            errors[errCount] = "SIGNATURE_INVALID";
            errCount++;
        }

        if (signatory != bid.signerWallet) {
            errors[errCount] = "SIGNATURE_MISMATCHED";
            errCount++;
        }

        // Check nonce
        if (nonceUsed(signatory, bid.nonce)) {
            errors[errCount] = "NONCE_ALREADY_USED";
            errCount++;
        }

        // Check bid size
        if (bid.buyAmount < offer.minBidSize) {
            errors[errCount] = "BID_TOO_SMALL";
            errCount++;
        }
        if (bid.buyAmount > offer.availableSize) {
            errors[errCount] = "BID_EXCEED_AVAILABLE_SIZE";
            errCount++;
        }

        // Check bid price
        uint256 bidPrice =
            (bid.sellAmount * 10**OTOKEN_DECIMALS) / bid.buyAmount;
        if (bidPrice < offer.minPrice) {
            errors[errCount] = "PRICE_TOO_LOW";
            errCount++;
        }

        // Check signer allowance
        uint256 signerAllowance =
            IERC20(offer.biddingToken).allowance(
                bid.signerWallet,
                address(this)
            );
        if (signerAllowance < bid.sellAmount) {
            errors[errCount] = "SIGNER_ALLOWANCE_LOW";
            errCount++;
        }

        // Check signer balance
        uint256 signerBalance =
            IERC20(offer.biddingToken).balanceOf(bid.signerWallet);
        if (signerBalance < bid.sellAmount) {
            errors[errCount] = "SIGNER_BALANCE_LOW";
            errCount++;
        }

        // Check seller allowance
        uint256 sellerAllowance =
            IERC20(offer.oToken).allowance(offer.seller, address(this));
        if (sellerAllowance < bid.buyAmount) {
            errors[errCount] = "SELLER_ALLOWANCE_LOW";
            errCount++;
        }

        // Check seller balance
        uint256 sellerBalance = IERC20(offer.oToken).balanceOf(offer.seller);
        if (sellerBalance < bid.buyAmount) {
            errors[errCount] = "SELLER_BALANCE_LOW";
            errCount++;
        }

        return (errCount, errors);
    }

    /**
     * @notice Returns the average settlement price for a swap offer
     * @param swapId unique identifier of the swap offer
     */
    function averagePriceForOffer(uint256 swapId)
        external
        view
        override
        returns (uint256)
    {
        Offer storage offer = swapOffers[swapId];
        require(offer.totalSize != 0, "Offer does not exist");

        uint256 availableSize = offer.availableSize;

        // Deduct the initial 1 wei offset if offer is not fully settled
        uint256 adjustment = availableSize != 0 ? 1 : 0;

        return
            ((offer.totalSales - adjustment) * (10**8)) /
            (offer.totalSize - availableSize);
    }

    /**
     * @notice Returns true if the nonce has been used
     * @param signer address Address of the signer
     * @param nonce uint256 Nonce being checked
     */
    function nonceUsed(address signer, uint256 nonce)
        public
        view
        override
        returns (bool)
    {
        uint256 groupKey = nonce / 256;
        uint256 indexInGroup = nonce % 256;
        return (_nonceGroups[signer][groupKey] >> indexInGroup) & 1 == 1;
    }

    /************************************************
     *  INTERNAL FUNCTIONS
     ***********************************************/

    /**
     * @notice Swap Atomic ERC20 Swap
     * @param details Details of offering
     * @param offer Offer struct containing offer details
     * @param bid Bid struct containing bid details
     */
    function _swap(
        OfferDetails memory details,
        Offer storage offer,
        Bid calldata bid
    ) internal {
        require(DOMAIN_CHAIN_ID == getChainId(), "CHAIN_ID_CHANGED");

        address signatory = _getSignatory(bid);
        require(signatory != address(0), "SIGNATURE_INVALID");
        require(signatory == bid.signerWallet, "SIGNATURE_MISMATCHED");
        require(_markNonceAsUsed(signatory, bid.nonce), "NONCE_ALREADY_USED");
        require(
            bid.buyAmount <= offer.availableSize,
            "BID_EXCEED_AVAILABLE_SIZE"
        );
        require(bid.buyAmount >= details.minBidSize, "BID_TOO_SMALL");

        // Ensure min. price is met
        uint256 bidPrice =
            (bid.sellAmount * 10**OTOKEN_DECIMALS) / bid.buyAmount;
        require(bidPrice >= details.minPrice, "PRICE_TOO_LOW");

        // don't have to do a uint128 check because we already check
        // that bid.buyAmount <= offer.availableSize
        offer.availableSize -= uint128(bid.buyAmount);

        // Transfer token from sender to signer
        IERC20(details.oToken).safeTransferFrom(
            details.seller,
            bid.signerWallet,
            bid.buyAmount
        );

        // Transfer to referrer if any
        uint256 feeAmount;
        if (bid.referrer != address(0)) {
            uint256 feePercent = referralFees[bid.referrer];

            if (feePercent > 0) {
                feeAmount = (bid.sellAmount * feePercent) / MAX_PERCENTAGE;

                IERC20(details.biddingToken).safeTransferFrom(
                    bid.signerWallet,
                    bid.referrer,
                    feeAmount
                );
            }
        }

        // Transfer token from signer to recipient
        IERC20(details.biddingToken).safeTransferFrom(
            bid.signerWallet,
            details.seller,
            bid.sellAmount - feeAmount
        );

        // Emit a Swap event
        emit Swap(
            bid.swapId,
            bid.nonce,
            bid.signerWallet,
            bid.sellAmount,
            bid.buyAmount,
            bid.referrer,
            feeAmount
        );
    }

    /**
     * @notice Marks a nonce as used for the given signer
     * @param signer address Address of the signer for which to mark the nonce as used
     * @param nonce uint256 Nonce to be marked as used
     * @return bool True if the nonce was not marked as used already
     */
    function _markNonceAsUsed(address signer, uint256 nonce)
        internal
        returns (bool)
    {
        uint256 groupKey = nonce / 256;
        uint256 indexInGroup = nonce % 256;
        uint256 group = _nonceGroups[signer][groupKey];

        // If it is already used, return false
        if ((group >> indexInGroup) & 1 == 1) {
            return false;
        }

        _nonceGroups[signer][groupKey] = group | (uint256(1) << indexInGroup);

        return true;
    }

    /**
     * @notice Recover the signatory from a signature
     * @param bid Bid struct containing bid details
     */
    function _getSignatory(Bid calldata bid) internal view returns (address) {
        return
            ecrecover(
                keccak256(
                    abi.encodePacked(
                        "\x19\x01",
                        DOMAIN_SEPARATOR,
                        keccak256(
                            abi.encode(
                                BID_TYPEHASH,
                                bid.swapId,
                                bid.nonce,
                                bid.signerWallet,
                                bid.sellAmount,
                                bid.buyAmount,
                                bid.referrer
                            )
                        )
                    )
                ),
                bid.v,
                bid.r,
                bid.s
            );
    }

    /**
     * @notice Returns the current chainId using the chainid opcode
     * @return id uint256 The chain id
     */
    function getChainId() internal view returns (uint256 id) {
        // no-inline-assembly
        assembly {
            id := chainid()
        }
    }
}

// SPDX-License-Identifier: MIT

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
        _setOwner(_msgSender());
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
        _setOwner(address(0));
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        _setOwner(newOwner);
    }

    function _setOwner(address newOwner) private {
        address oldOwner = _owner;
        _owner = newOwner;
        emit OwnershipTransferred(oldOwner, newOwner);
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "../IERC20.sol";
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
}

// SPDX-License-Identifier: MIT

pragma solidity =0.8.4;

interface ISwap {
    struct Offer {
        // 32 byte slot 1, partial fill
        // Seller wallet address
        address seller;
        // 32 byte slot 2
        // Addess of oToken
        address oToken;
        // Price per oToken denominated in biddingToken
        uint96 minPrice;
        // 32 byte slot 3
        // ERC20 Token to bid for oToken
        address biddingToken;
        // Minimum oToken amount acceptable for a single bid
        uint96 minBidSize;
        // 32 byte slot 4
        // Total available oToken amount
        uint128 totalSize;
        // Remaining available oToken amount
        // This figure is updated after each successfull swap
        uint128 availableSize;
        // 32 byte slot 5
        // Amount of biddingToken received
        // This figure is updated after each successfull swap
        uint256 totalSales;
    }

    struct Bid {
        // ID assigned to offers
        uint256 swapId;
        // Number only used once for each wallet
        uint256 nonce;
        // Signer wallet address
        address signerWallet;
        // Amount of biddingToken offered by signer
        uint256 sellAmount;
        // Amount of oToken requested by signer
        uint256 buyAmount;
        // Referrer wallet address
        address referrer;
        // Signature recovery id
        uint8 v;
        // r portion of the ECSDA signature
        bytes32 r;
        // s portion of the ECSDA signature
        bytes32 s;
    }

    struct OfferDetails {
        // Seller wallet address
        address seller;
        // Addess of oToken
        address oToken;
        // Price per oToken denominated in biddingToken
        uint256 minPrice;
        // ERC20 Token to bid for oToken
        address biddingToken;
        // Minimum oToken amount acceptable for a single bid
        uint256 minBidSize;
    }

    event Swap(
        uint256 indexed swapId,
        uint256 nonce,
        address indexed signerWallet,
        uint256 signerAmount,
        uint256 sellerAmount,
        address referrer,
        uint256 feeAmount
    );

    event NewOffer(
        uint256 swapId,
        address seller,
        address oToken,
        address biddingToken,
        uint256 minPrice,
        uint256 minBidSize,
        uint256 totalSize
    );

    event SetFee(address referrer, uint256 fee);

    event SettleOffer(uint256 swapId);

    event Cancel(uint256 indexed nonce, address indexed signerWallet);

    function createOffer(
        address oToken,
        address biddingToken,
        uint96 minPrice,
        uint96 minBidSize,
        uint128 totalSize
    ) external returns (uint256 swapId);

    function settleOffer(uint256 swapId, Bid[] calldata bids) external;

    function cancelNonce(uint256[] calldata nonces) external;

    function check(Bid calldata bid)
        external
        view
        returns (uint256, bytes32[] memory);

    function averagePriceForOffer(uint256 swapId)
        external
        view
        returns (uint256);

    function nonceUsed(address, uint256) external view returns (bool);
}

// SPDX-License-Identifier: MIT
pragma solidity =0.8.4;

import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";

interface IERC20Detailed is IERC20 {
    function decimals() external view returns (uint8);

    function symbol() external view returns (string calldata);

    function name() external view returns (string calldata);
}

// SPDX-License-Identifier: MIT

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

pragma solidity ^0.8.0;

/**
 * @dev Interface of the ERC20 standard as defined in the EIP.
 */
interface IERC20 {
    /**
     * @dev Returns the amount of tokens in existence.
     */
    function totalSupply() external view returns (uint256);

    /**
     * @dev Returns the amount of tokens owned by `account`.
     */
    function balanceOf(address account) external view returns (uint256);

    /**
     * @dev Moves `amount` tokens from the caller's account to `recipient`.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transfer(address recipient, uint256 amount) external returns (bool);

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
     * @dev Moves `amount` tokens from `sender` to `recipient` using the
     * allowance mechanism. `amount` is then deducted from the caller's
     * allowance.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transferFrom(
        address sender,
        address recipient,
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

pragma solidity ^0.8.0;

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