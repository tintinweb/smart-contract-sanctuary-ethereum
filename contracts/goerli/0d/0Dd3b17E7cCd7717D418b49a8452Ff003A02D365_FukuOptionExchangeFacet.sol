// SPDX-License-Identifier: SEE LICENSE IN LICENSE
pragma solidity ^0.8.0;

import { Option, OptionListing, OptionOffer, TokenizedOption } from "../FukuTypes.sol";
import { IFukuOptionExchange } from "../interfaces/facets/IFukuOptionExchange.sol";
import { ITokenizedOptions } from "../interfaces/ITokenizedOptions.sol";
import { ICryptoPunksMarket } from "../interfaces/ICryptoPunksMarket.sol";
import { IWeth } from "../interfaces/IWeth.sol";
import { FukuStorage, FukuOptionExchangeStorage, FukuTokenizedOptionsStorage, TokenAddressStorage } from "../libraries/FukuStorage.sol";
import { SignatureVerification } from "../libraries/SignatureVerification.sol";

import { IERC20 } from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import { IERC721 } from "@openzeppelin/contracts/token/ERC721/IERC721.sol";

// todo: add reentrancy guard
contract FukuOptionExchangeFacet is IFukuOptionExchange {
    /**
     * @notice Cancels listings with specified nonces for sender
     * @dev Cannot pass nonce that is below the current minimum listing nonce
     *
     * @param listingNonces Listing nonces to cancel
     */
    function cancelListingsForSender(uint256[] calldata listingNonces) external override {
        FukuOptionExchangeStorage storage exchangeStorage = FukuStorage.fukuOptionExchangeStorage();

        require(listingNonces.length > 0, "No listings");

        for (uint256 i = 0; i < listingNonces.length; ++i) {
            require(listingNonces[i] >= exchangeStorage.minListingNonce[msg.sender], "Nonce is lower than current");
            require(
                !exchangeStorage.isListingNonceCancelledOrPurchased[msg.sender][listingNonces[i]],
                "Already cancelled"
            );

            exchangeStorage.isListingNonceCancelledOrPurchased[msg.sender][listingNonces[i]] = true;
        }

        emit ListingsCancelled(msg.sender, listingNonces);
    }

    /**
     * @notice Cancels all listings for sender below the specified nonce
     *
     * @param minNonce The new minimum nonce for valid listings
     */
    function cancelAllListingsForSender(uint256 minNonce) external override {
        FukuOptionExchangeStorage storage exchangeStorage = FukuStorage.fukuOptionExchangeStorage();

        require(minNonce > exchangeStorage.minListingNonce[msg.sender], "Nonce is lower than current");

        exchangeStorage.minListingNonce[msg.sender] = minNonce;

        emit AllListingsCancelled(msg.sender, minNonce);
    }

    /**
     * @notice Option buyer calls function to purchase a valid option listing
     *
     * @param optionListing The option listing data
     */
    function purchaseOption(OptionListing calldata optionListing) external payable override {
        FukuOptionExchangeStorage storage exchangeStorage = FukuStorage.fukuOptionExchangeStorage();
        FukuTokenizedOptionsStorage storage tokenizedOptionsStorage = FukuStorage.fukuTokenizedOptionsStorage();

        // validate the option listing data
        _validateListing(optionListing);

        // transfer NFT into custody and send premium
        _exchangePremiumForNft(optionListing.option, optionListing.seller);

        // update the seller nonce
        exchangeStorage.isListingNonceCancelledOrPurchased[optionListing.seller][optionListing.nonce] = true;

        // mint tokenized option
        uint256 tokenizedId = ITokenizedOptions(tokenizedOptionsStorage.tokenizedOptions).mintOption(
            optionListing.option,
            optionListing.seller,
            msg.sender
        );

        emit OptionPurchased(
            msg.sender,
            optionListing.seller,
            optionListing.option.collection,
            optionListing.option.tokenId,
            optionListing.option.strikePrice,
            optionListing.option.premium,
            optionListing.option.duration,
            block.timestamp,
            optionListing.nonce,
            tokenizedId
        );
    }

    /**
     * @notice Option seller calls function to accept offer
     *
     * @param optionOffer The option offer
     */
    function acceptOffer(OptionOffer calldata optionOffer) external override {
        FukuOptionExchangeStorage storage exchangeStorage = FukuStorage.fukuOptionExchangeStorage();
        FukuTokenizedOptionsStorage storage tokenizedOptionsStorage = FukuStorage.fukuTokenizedOptionsStorage();
        TokenAddressStorage storage tokenAddressStorage = FukuStorage.tokenAddressStorage();

        // validate the offer
        _validateOffer(optionOffer);

        // collect weth and unwrap
        IERC20(tokenAddressStorage.wethToken).transferFrom(
            optionOffer.buyer,
            address(this),
            optionOffer.option.premium
        );
        IWeth(tokenAddressStorage.wethToken).withdraw(optionOffer.option.premium);

        // transfer NFT into custody and send premium
        _exchangePremiumForNft(optionOffer.option, msg.sender);

        // update the buyer nonce
        exchangeStorage.isListingNonceCancelledOrPurchased[optionOffer.buyer][optionOffer.nonce] = true;

        // mint tokenized option
        uint256 tokenizedId = ITokenizedOptions(tokenizedOptionsStorage.tokenizedOptions).mintOption(
            optionOffer.option,
            msg.sender,
            optionOffer.buyer
        );

        emit OfferAccepted(
            optionOffer.buyer,
            msg.sender,
            optionOffer.option.collection,
            optionOffer.option.tokenId,
            optionOffer.option.strikePrice,
            optionOffer.option.premium,
            optionOffer.option.duration,
            block.timestamp,
            optionOffer.nonce,
            tokenizedId
        );
    }

    /**
     * @notice Option owner calls function to exercise option
     *
     * @param tokenizedOptionId The tokenized option id
     */
    function exerciseOption(uint256 tokenizedOptionId) external payable override {
        FukuTokenizedOptionsStorage storage tokenizedOptionsStorage = FukuStorage.fukuTokenizedOptionsStorage();
        TokenAddressStorage storage tokenAddressStorage = FukuStorage.tokenAddressStorage();
        ITokenizedOptions tokenizedOptions = ITokenizedOptions(tokenizedOptionsStorage.tokenizedOptions);

        // validate the option
        TokenizedOption memory tokenizedOption = tokenizedOptions.getOption(tokenizedOptionId);
        require(msg.sender == tokenizedOptions.ownerOf(tokenizedOptionId), "Not option owner");
        require(block.timestamp < tokenizedOption.mintTime + tokenizedOption.option.duration, "Option expired");
        require(msg.value == tokenizedOption.option.strikePrice, "Msg.value does not match strike price");

        // transfer the strike price to the seller
        // todo: reentrancy bug needs to be fixed
        payable(tokenizedOption.seller).transfer(tokenizedOption.option.strikePrice);

        // transfer the NFT to the option owner
        if (tokenizedOption.option.collection == tokenAddressStorage.punkToken) {
            ICryptoPunksMarket(tokenizedOption.option.collection).transferPunk(
                msg.sender,
                tokenizedOption.option.tokenId
            );
        } else {
            IERC721(tokenizedOption.option.collection).transferFrom(
                address(this),
                msg.sender,
                tokenizedOption.option.tokenId
            );
        }

        // burn the tokenized option
        tokenizedOptions.burnOption(tokenizedOptionId);

        emit OptionExercised(msg.sender, tokenizedOptionId);
    }

    /**
     * @notice Option seller calls function to retrieve NFT from expired option
     *
     * @param tokenizedOptionId The tokenized option id
     */
    function redeemExpiredOption(uint256 tokenizedOptionId) external override {
        FukuTokenizedOptionsStorage storage tokenizedOptionsStorage = FukuStorage.fukuTokenizedOptionsStorage();
        TokenAddressStorage storage tokenAddressStorage = FukuStorage.tokenAddressStorage();
        ITokenizedOptions tokenizedOptions = ITokenizedOptions(tokenizedOptionsStorage.tokenizedOptions);

        // get the option params
        TokenizedOption memory tokenizedOption = tokenizedOptions.getOption(tokenizedOptionId);

        // validate option for redemption
        require(tokenizedOptions.ownerOf(tokenizedOptionId) != address(0), "Tokenized option nonexistent");
        require(msg.sender == tokenizedOption.seller, "Not option seller");
        require(block.timestamp > tokenizedOption.mintTime + tokenizedOption.option.duration, "Option not expired");

        // burn option nft
        tokenizedOptions.burnOption(tokenizedOptionId);

        // return nft to seller
        if (tokenizedOption.option.collection == tokenAddressStorage.punkToken) {
            ICryptoPunksMarket(tokenizedOption.option.collection).transferPunk(
                tokenizedOption.seller,
                tokenizedOption.option.tokenId
            );
        } else {
            IERC721(tokenizedOption.option.collection).transferFrom(
                address(this),
                tokenizedOption.seller,
                tokenizedOption.option.tokenId
            );
        }

        emit OptionRedeemed(tokenizedOptionId);
    }

    function _validateListing(OptionListing calldata optionListing) internal view {
        // todo: check if gas optimizing by not getting storage twice
        FukuOptionExchangeStorage storage exchangeStorage = FukuStorage.fukuOptionExchangeStorage();

        // validate option
        _validateOption(optionListing.option, optionListing.seller);

        // validate premium
        require(msg.value == optionListing.option.premium, "Msg.value does not match premium");

        // verify nonce
        require(
            !exchangeStorage.isListingNonceCancelledOrPurchased[optionListing.seller][optionListing.nonce] &&
                optionListing.nonce >= exchangeStorage.minListingNonce[optionListing.seller],
            "Listing expired"
        );

        // verify the signature
        require(SignatureVerification.verifyOptionListingSignature(optionListing), "Invalid signature");
    }

    function _validateOffer(OptionOffer calldata optionOffer) internal view {
        // todo: check if gas optimizing by not getting storage twice
        FukuOptionExchangeStorage storage exchangeStorage = FukuStorage.fukuOptionExchangeStorage();
        TokenAddressStorage storage tokenAddressStorage = FukuStorage.tokenAddressStorage();

        // validate the option
        _validateOption(optionOffer.option, msg.sender);

        // validate buyer has enough weth
        require(
            IERC20(tokenAddressStorage.wethToken).balanceOf(optionOffer.buyer) >= optionOffer.option.premium,
            "Buyer insufficent funds"
        );

        // verify nonce
        require(
            !exchangeStorage.isListingNonceCancelledOrPurchased[optionOffer.buyer][optionOffer.nonce] &&
                optionOffer.nonce >= exchangeStorage.minListingNonce[optionOffer.buyer],
            "Listing expired"
        );

        // verify the signature
        require(SignatureVerification.verifyOptionOfferSignature(optionOffer), "Invalid signature");
    }

    function _validateOption(Option calldata option, address seller) internal view {
        TokenAddressStorage storage tokenAddressStorage = FukuStorage.tokenAddressStorage();
        FukuTokenizedOptionsStorage storage tokenizedOptionsStorage = FukuStorage.fukuTokenizedOptionsStorage();

        // validate the nft is not already an option (prevent option-ception)
        require(option.collection != tokenizedOptionsStorage.tokenizedOptions, "Cannot buy option of option");

        // validate the seller is owner of nft
        if (option.collection == tokenAddressStorage.punkToken) {
            require(
                ICryptoPunksMarket(option.collection).punkIndexToAddress(option.tokenId) == seller,
                "Seller not NFT owner"
            );
        } else {
            require(IERC721(option.collection).ownerOf(option.tokenId) == seller, "Seller not NFT owner");
        }

        // verify the strike price is greater than 0
        require(option.strikePrice > 0, "Invalid strike price");

        // verify the premium is greater than 0
        require(option.premium > 0, "Invalid premium");

        // verify the duration is greater than 0
        require(option.duration > 0, "Invalid duration");
    }

    function _exchangePremiumForNft(Option calldata option, address seller) internal {
        TokenAddressStorage storage tokenAddressStorage = FukuStorage.tokenAddressStorage();

        // transfer the nft into custody and transfer premium to seller
        if (option.collection == tokenAddressStorage.punkToken) {
            ICryptoPunksMarket(tokenAddressStorage.punkToken).buyPunk{ value: option.premium }(option.tokenId);
        } else {
            IERC721(option.collection).transferFrom(seller, address(this), option.tokenId);
            payable(seller).transfer(option.premium);
        }
    }
}

// SPDX-License-Identifier: SEE LICENSE IN LICENSE
pragma solidity ^0.8.0;

struct Option {
    address collection; // the nft collection
    uint256 tokenId; // the nft id
    uint256 strikePrice; // the strike price
    uint256 premium; // the option premium
    uint256 duration; // the option duration
}

struct OptionListing {
    Option option; // the option data
    address seller; // the nft owner (signer of listing)
    uint8 v; // signature parameter
    bytes32 r; // signature parameter
    bytes32 s; // signature parameter
    uint256 nonce; // the listing nonce
}

struct OptionOffer {
    Option option; // the option data
    address buyer; // the option offerer (signer of listing)
    uint8 v; // signature parameter
    bytes32 r; // signature parameter
    bytes32 s; // signature parameter
    uint256 nonce; // the listing nonce
}

struct TokenizedOption {
    Option option; // the option data
    address seller; // the option seller
    uint256 mintTime; // the time of mint
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

interface IWeth {
    function deposit() external payable;

    function withdraw(uint256 wad) external;
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

interface ICryptoPunksMarket {
    struct Offer {
        bool isForSale;
        uint256 punkIndex;
        address seller;
        uint256 minValue;
        address onlySellTo;
    }

    struct Bid {
        bool hasBid;
        uint256 punkIndex;
        address bidder;
        uint256 value;
    }

    event Transfer(address indexed from, address indexed to, uint256 value);
    event PunkTransfer(address indexed from, address indexed to, uint256 punkIndex);
    event PunkOffered(uint256 indexed punkIndex, uint256 minValue, address indexed toAddress);
    event PunkBought(uint256 indexed punkIndex, uint256 value, address indexed fromAddress, address indexed toAddress);
    event PunkNoLongerForSale(uint256 indexed punkIndex);

    function transferPunk(address to, uint256 punkIndex) external;

    function punkNoLongerForSale(uint256 punkIndex) external;

    function offerPunkForSaleToAddress(
        uint256 punkIndex,
        uint256 minSalePriceInWei,
        address toAddress
    ) external;

    function buyPunk(uint256 punkIndex) external payable;

    function withdraw() external;

    function punkIndexToAddress(uint256 punkIndex) external view returns (address);
}

// SPDX-License-Identifier: SEE LICENSE IN LICENSE
pragma solidity ^0.8.0;

import { Option, TokenizedOption } from "../FukuTypes.sol";

import { IERC721 } from "@openzeppelin/contracts/token/ERC721/IERC721.sol";

interface ITokenizedOptions is IERC721 {
    event OptionMinted(
        address indexed recipient,
        uint256 tokenId,
        address indexed seller,
        address indexed collection,
        uint256 nftTokenId,
        uint256 strikePrice,
        uint256 premium,
        uint256 duration,
        uint256 mintTime
    );

    event OptionBurned(uint256 tokenId);

    function getOption(uint256 tokenId) external view returns (TokenizedOption memory);

    function mintOption(
        Option calldata option,
        address seller,
        address buyer
    ) external returns (uint256);

    function burnOption(uint256 tokenId) external;

    function setBaseURI(string calldata baseURI_) external;
}

// SPDX-License-Identifier: SEE LICENSE IN LICENSE
pragma solidity ^0.8.0;

import { OptionListing, OptionOffer } from "../FukuTypes.sol";
import { FukuStorage, EIP712Hashes } from "./FukuStorage.sol";

library SignatureVerification {
    function verifyOptionListingSignature(OptionListing calldata optionListing) internal view returns (bool) {
        EIP712Hashes storage eip712Hashes = FukuStorage.eip712Hashes();

        // get hash of option listing
        bytes32 optionListingHash = _hashOptionListing(optionListing);

        return
            _verifySignature(
                optionListing.seller,
                eip712Hashes.domain,
                optionListingHash,
                optionListing.v,
                optionListing.r,
                optionListing.s
            );
    }

    function verifyOptionOfferSignature(OptionOffer calldata optionOffer) internal view returns (bool) {
        EIP712Hashes storage eip712Hashes = FukuStorage.eip712Hashes();

        // get hash of option offer
        bytes32 optionOfferHash = _hashOptionOffer(optionOffer);

        return
            _verifySignature(
                optionOffer.buyer,
                eip712Hashes.domain,
                optionOfferHash,
                optionOffer.v,
                optionOffer.r,
                optionOffer.s
            );
    }

    function _hashOptionListing(OptionListing calldata optionListing) private view returns (bytes32) {
        EIP712Hashes storage eip712Hashes = FukuStorage.eip712Hashes();

        return
            keccak256(
                abi.encode(
                    eip712Hashes.optionListing,
                    optionListing.seller,
                    optionListing.option.collection,
                    optionListing.option.tokenId,
                    optionListing.option.strikePrice,
                    optionListing.option.premium,
                    optionListing.option.duration,
                    optionListing.nonce
                )
            );
    }

    function _hashOptionOffer(OptionOffer calldata optionOffer) private view returns (bytes32) {
        EIP712Hashes storage eip712Hashes = FukuStorage.eip712Hashes();

        return
            keccak256(
                abi.encode(
                    eip712Hashes.optionOffer,
                    optionOffer.buyer,
                    optionOffer.option.collection,
                    optionOffer.option.tokenId,
                    optionOffer.option.strikePrice,
                    optionOffer.option.premium,
                    optionOffer.option.duration,
                    optionOffer.nonce
                )
            );
    }

    function _verifySignature(
        address signer,
        bytes32 domainHash,
        bytes32 typeHash,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) private pure returns (bool) {
        // \x19\x01 is the standardized encoding prefix
        // https://eips.ethereum.org/EIPS/eip-712#specification
        bytes32 digest = keccak256(abi.encodePacked("\x19\x01", domainHash, typeHash));

        // todo: check case if contract is signer
        return ecrecover(digest, v, r, s) == signer;
    }
}

// SPDX-License-Identifier: SEE LICENSE IN LICENSE
pragma solidity ^0.8.0;

struct EIP712Domain {
    string name;
    string version;
    uint256 chainId;
    address verifyingContract;
}

struct EIP712Hashes {
    bytes32 domain;
    bytes32 optionListing;
    bytes32 optionOffer;
}

struct FukuOptionExchangeStorage {
    mapping(address => uint256) minListingNonce;
    mapping(address => mapping(uint256 => bool)) isListingNonceCancelledOrPurchased;
}

struct FukuTokenizedOptionsStorage {
    address tokenizedOptions;
}

struct TokenAddressStorage {
    address punkToken;
    address wethToken;
}

library FukuStorage {
    bytes32 constant EIP_712_DOMAIN_POSITION = keccak256("fuku.storage.eip.712.domain");
    bytes32 constant EIP_712_HASHES_POSITION = keccak256("fuku.storage.eip.712.hashes");
    bytes32 constant FUKU_OPTION_EXCHANGE_STORAGE_POSITION = keccak256("fuku.storage.fuku.option.exchange.storage");
    bytes32 constant FUKU_TOKENIZED_OPTIONS_STORAGE_POSITION = keccak256("fuku.storage.fuku.tokenized.options.storage");
    bytes32 constant TOKEN_ADDRESS_STORAGE_POSTION = keccak256("fuku.storage.token.address.storage");

    function eip712Domain() internal pure returns (EIP712Domain storage domain) {
        bytes32 position = EIP_712_DOMAIN_POSITION;
        assembly {
            domain.slot := position
        }
    }

    function eip712Hashes() internal pure returns (EIP712Hashes storage hashes) {
        bytes32 position = EIP_712_HASHES_POSITION;
        assembly {
            hashes.slot := position
        }
    }

    function fukuOptionExchangeStorage()
        internal
        pure
        returns (FukuOptionExchangeStorage storage optionExchangeStorage)
    {
        bytes32 position = FUKU_OPTION_EXCHANGE_STORAGE_POSITION;
        assembly {
            optionExchangeStorage.slot := position
        }
    }

    function fukuTokenizedOptionsStorage()
        internal
        pure
        returns (FukuTokenizedOptionsStorage storage tokenizedOptionsStorage)
    {
        bytes32 position = FUKU_TOKENIZED_OPTIONS_STORAGE_POSITION;
        assembly {
            tokenizedOptionsStorage.slot := position
        }
    }

    function tokenAddressStorage() internal pure returns (TokenAddressStorage storage tokenStorage) {
        bytes32 position = TOKEN_ADDRESS_STORAGE_POSTION;
        assembly {
            tokenStorage.slot := position
        }
    }
}

// SPDX-License-Identifier: SEE LICENSE IN LICENSE
pragma solidity ^0.8.0;

import { OptionListing, OptionOffer } from "../../FukuTypes.sol";

interface IFukuOptionExchange {
    event ListingsCancelled(address seller, uint256[] listingNonces);

    event AllListingsCancelled(address seller, uint256 minNonce);

    event OptionPurchased(
        address indexed buyer,
        address indexed seller,
        address indexed collection,
        uint256 tokenId,
        uint256 strikePrice,
        uint256 premium,
        uint256 duration,
        uint256 mintTime,
        uint256 nonce,
        uint256 tokenizedOptionId
    );

    event OfferAccepted(
        address indexed buyer,
        address indexed seller,
        address indexed collection,
        uint256 tokenId,
        uint256 strikePrice,
        uint256 premium,
        uint256 duration,
        uint256 mintTime,
        uint256 nonce,
        uint256 tokenizedOptionId
    );

    event OptionExercised(address indexed optionOwner, uint256 tokenizedOptionId);

    event OptionRedeemed(uint256 tokenizedOptionid);

    function cancelListingsForSender(uint256[] calldata listingNonces) external;

    function cancelAllListingsForSender(uint256 minNonce) external;

    function purchaseOption(OptionListing calldata optionListing) external payable;

    function acceptOffer(OptionOffer calldata optionOffer) external;

    function exerciseOption(uint256 tokenizedOptionId) external payable;

    function redeemExpiredOption(uint256 tokenizedOptionId) external;
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