// SPDX-License-Identifier: SEE LICENSE IN LICENSE
pragma solidity ^0.8.0;

import { Option, OptionListing, TokenizedOption } from "../FukuTypes.sol";
import { IFukuOptionExchange } from "../interfaces/facets/IFukuOptionExchange.sol";
import { ITokenizedOptions } from "../interfaces/ITokenizedOptions.sol";
import { FukuStorage, FukuOptionExchangeStorage, FukuTokenizedOptionsStorage } from "../libraries/FukuStorage.sol";
import { SignatureVerification } from "../libraries/SignatureVerification.sol";

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

        // validate premium and send to seller
        require(msg.value == optionListing.option.premium, "Msg.value does not match premium");
        payable(optionListing.option.seller).transfer(optionListing.option.premium);

        // update the seller nonce
        exchangeStorage.isListingNonceCancelledOrPurchased[optionListing.option.seller][optionListing.nonce] = true;

        // transfer the nft into custody
        IERC721(optionListing.option.collection).transferFrom(
            optionListing.option.seller,
            address(this),
            optionListing.option.tokenId
        );

        // mint tokenized option
        ITokenizedOptions(tokenizedOptionsStorage.tokenizedOptions).mintOption(optionListing.option, msg.sender);

        emit OptionPurchased(
            msg.sender,
            optionListing.option.seller,
            optionListing.option.collection,
            optionListing.option.tokenId,
            optionListing.option.strikePrice,
            optionListing.option.premium,
            optionListing.option.duration,
            optionListing.nonce
        );
    }

    /**
     * @notice Option owner calls function to exercise option
     *
     * @param tokenizedOptionId The tokenized option id
     */
    function exerciseOption(uint256 tokenizedOptionId) external payable override {
        FukuTokenizedOptionsStorage storage tokenizedOptionsStorage = FukuStorage.fukuTokenizedOptionsStorage();
        ITokenizedOptions tokenizedOptions = ITokenizedOptions(tokenizedOptionsStorage.tokenizedOptions);

        // validate the option
        TokenizedOption memory tokenizedOption = tokenizedOptions.getOption(tokenizedOptionId);
        require(msg.sender == tokenizedOptions.ownerOf(tokenizedOptionId), "Not option owner");
        require(block.timestamp < tokenizedOption.mintTime + tokenizedOption.option.duration, "Option expired");
        require(msg.value == tokenizedOption.option.strikePrice, "Msg.value does not match strike price");

        // transfer the strike price to the seller
        payable(tokenizedOption.option.seller).transfer(tokenizedOption.option.strikePrice);

        // transfer the NFT to the option owner
        IERC721(tokenizedOption.option.collection).transferFrom(address(this), msg.sender, tokenizedOptionId);

        // burn the tokenized option
        tokenizedOptions.burnOption(tokenizedOptionId);

        emit OptionExercised(msg.sender, tokenizedOptionId);
    }

    function _validateListing(OptionListing calldata optionListing) internal view {
        // todo: check if gas optimizing by not getting storage twice
        FukuOptionExchangeStorage storage exchangeStorage = FukuStorage.fukuOptionExchangeStorage();

        // validate seller address is not the zero address
        require(optionListing.option.seller != address(0), "Invalid seller");

        // validate the seller is owner of nft
        require(
            IERC721(optionListing.option.collection).ownerOf(optionListing.option.tokenId) ==
                optionListing.option.seller,
            "Seller not NFT owner"
        );

        // verify the strike price is greater than 0
        require(optionListing.option.strikePrice > 0, "Invalid strike price");

        // verify the premium is greater than 0
        require(optionListing.option.premium > 0, "Invalid premium");

        // verify the duration is greater than 0
        require(optionListing.option.duration > 0, "Invalid duration");

        // verify nonce
        require(
            !exchangeStorage.isListingNonceCancelledOrPurchased[optionListing.option.seller][optionListing.nonce] &&
                optionListing.nonce >= exchangeStorage.minListingNonce[optionListing.option.seller],
            "Listing expired"
        );

        // verify the signature
        require(SignatureVerification.verifyOptionListingSignature(optionListing), "Invalid signature");
    }
}

// SPDX-License-Identifier: SEE LICENSE IN LICENSE
pragma solidity ^0.8.0;

struct Option {
    address seller; // the option seller (signer of listing)
    address collection; // the nft collection
    uint256 tokenId; // the nft id
    uint256 strikePrice; // the strike price
    uint256 premium; // the option premium
    uint256 duration; // the option duration
}

struct OptionListing {
    Option option; // the option data
    uint256 nonce; // the listing nonce
    uint8 v; // signature parameter
    bytes32 r; // signature parameter
    bytes32 s; // signature parameter
}

struct TokenizedOption {
    Option option; // the option data
    uint256 mintTime; // the time of mint
}

// SPDX-License-Identifier: SEE LICENSE IN LICENSE
pragma solidity ^0.8.0;

import { OptionListing } from "../../FukuTypes.sol";

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
        uint256 nonce
    );

    event OptionExercised(address indexed optionOwner, uint256 tokenizedOptionId);

    function cancelListingsForSender(uint256[] calldata listingNonces) external;

    function cancelAllListingsForSender(uint256 minNonce) external;

    function purchaseOption(OptionListing calldata optionListing) external payable;

    function exerciseOption(uint256 tokenizedOptionId) external payable;
}

// SPDX-License-Identifier: SEE LICENSE IN LICENSE
pragma solidity ^0.8.0;

import { Option, TokenizedOption } from "../FukuTypes.sol";

import { IERC721 } from "@openzeppelin/contracts/token/ERC721/IERC721.sol";

interface ITokenizedOptions is IERC721 {
    event OptionMinted(
        address indexed recipient,
        uint256 tokenId,
        address seller,
        address collection,
        uint256 nftTokenId,
        uint256 strikePrice,
        uint256 premium,
        uint256 duration,
        uint256 mintTime
    );

    event OptionBurned(uint256 tokenId);

    function getOption(uint256 tokenId) external view returns (TokenizedOption memory);

    function mintOption(Option calldata option, address recipient) external;

    function burnOption(uint256 tokenId) external;
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
}

struct FukuOptionExchangeStorage {
    mapping(address => uint256) minListingNonce;
    mapping(address => mapping(uint256 => bool)) isListingNonceCancelledOrPurchased;
}

struct FukuTokenizedOptionsStorage {
    address tokenizedOptions;
}

library FukuStorage {
    bytes32 constant EIP_712_DOMAIN_POSITION = keccak256("fuku.storage.eip.712.domain");
    bytes32 constant EIP_712_HASHES_POSITION = keccak256("fuku.storage.eip.712.hashes");
    bytes32 constant FUKU_OPTION_EXCHANGE_STORAGE_POSITION = keccak256("fuku.storage.fuku.option.exchange.storage");
    bytes32 constant FUKU_TOKENIZED_OPTIONS_STORAGE_POSITION = keccak256("fuku.storage.fuku.tokenized.options.storage");

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
}

// SPDX-License-Identifier: SEE LICENSE IN LICENSE
pragma solidity ^0.8.0;

import { OptionListing } from "../FukuTypes.sol";
import { FukuStorage, EIP712Hashes } from "./FukuStorage.sol";

library SignatureVerification {
    function hashOptionListing(OptionListing calldata optionListing) internal view returns (bytes32) {
        EIP712Hashes storage eip712Hashes = FukuStorage.eip712Hashes();

        return
            keccak256(
                abi.encode(
                    eip712Hashes.optionListing,
                    optionListing.option.seller,
                    optionListing.option.collection,
                    optionListing.option.tokenId,
                    optionListing.option.strikePrice,
                    optionListing.option.premium,
                    optionListing.option.duration,
                    optionListing.nonce
                )
            );
    }

    function verifyOptionListingSignature(OptionListing calldata optionListing) internal view returns (bool) {
        EIP712Hashes storage eip712Hashes = FukuStorage.eip712Hashes();

        // get hash of option listing
        bytes32 hash = hashOptionListing(optionListing);

        // \x19\x01 is the standardized encoding prefix
        // https://eips.ethereum.org/EIPS/eip-712#specification
        bytes32 digest = keccak256(abi.encodePacked("\x19\x01", eip712Hashes.domain, hash));

        // todo: check case if contract is signer
        return ecrecover(digest, optionListing.v, optionListing.r, optionListing.s) == optionListing.option.seller;
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.6.0) (token/ERC721/IERC721.sol)

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