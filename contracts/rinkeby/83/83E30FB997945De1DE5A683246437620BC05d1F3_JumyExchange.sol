pragma solidity 0.8.12;

// Author: zkstoic (uranium93)

import {IERC721} from "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import {IERC1155} from "@openzeppelin/contracts/token/ERC1155/IERC1155.sol";
import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {IWETH} from "./interfaces/IWETH.sol";
import {ExchangeCore} from "./core/ExchangeCore.sol";
import {ExchangeManager} from "./core/ExchangeManager.sol";
import {ERC721FixedPrice} from "./ERC721/FixedPrice.sol";
import {ReserveAuction} from "./ERC721/ReserveAuction.sol";
import {ERC1155FixedPrice} from "./ERC1155/FixedPrice.sol";

contract JumyExchange is
    ExchangeCore,
    ExchangeManager,
    ERC721FixedPrice,
    ReserveAuction,
    ERC1155FixedPrice
{
    constructor(
        address weth,
        address jumyNftCollection,
        address royaltyManagerContract,
        address collectionRegistryContract,
        address protocolFeesRecipientWallet
    )
        ExchangeCore(
            weth,
            jumyNftCollection,
            royaltyManagerContract,
            collectionRegistryContract,
            protocolFeesRecipientWallet
        )
    {}

    receive() external payable {}

    // __/~~~~\_/~~\__/~~\_/~~\__/~~\_/~~\__/~~\_/~~\__/~~\_\__/~~\~
    // ___/~~\__/~~\__/~~\_/~~~\/~~~\__/~~\/~~\__/~~\__/~~\_\__/~~\~
    // ___/~~\__/~~\__/~~\_/~~~~~~~~\___/~~~~\___/~~\__/~~\_/~~\__/~
    // ___/~~\__/~~\__/~~\_/~~\__/~~\____/~~\____/~~\__/~~\_/~~\__/~
    // /~~~~\____/~~~~~~\__/~~\__/~~\____/~~\____/~~\__/~~\_/~~\__/~
    // /~~\__/~░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░/~~\__/~~\_
    // /~~\__/~░░░░░░░░██╗██╗░░░██╗███╗░░░███╗██╗░░░██╗░░░░░/~~\__/~
    // /~~\__/~░░░░░░░░██║██║░░░██║████╗░████║╚██╗░██╔╝░░░░/~~\__/~~
    // ___/~~\~░░░░░░░░██║██║░░░██║██╔████╔██║░╚████╔╝░░░░░░░/~~\__/
    // ___/~~\~░░░██╗░░██║██║░░░██║██║╚██╔╝██║░░╚██╔╝░░░░░░░░░░/~~\_
    // ___/~~\~░░░██╗░░██░╚██████╔╝██║░╚═╝░██║░░░██║░░░░░░░░░/~~\__/
    // ___/~~\~░░░██╗░░██░░╚═════╝░╚═╝░░░░░╚═╝░░░██║░░░░░░/~~\__/~~\
    // /\__/~\~░░░╚█████╝░░░░░░░░░░░░░░░░░░░░░░░░██║░░░░░░░░░░░/~~\_
    // \_/~\~/~░░░░╚════╝░░░░░░░░░░░░░░░░░░░░╚═════╝░░░░░░░░/~~\__/~
    // /\_/~\_~░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░/~~\__/
    // __/~~~~\_/~~\__/~~\_/~~\__/~~\_/~~\__/~~\_/~~\__/~~\_~\__/~\~
    // ___/~~\__/~~\__/~~\_/~~~\/~~~\__/~~\/~~\__/~~\__/~~\_~\__/~\~
    // ___/~~\__/~~\__/~~\_/~~~~~~~~\___/~~~~\___/~~\__/~~\_/~~\__/\
    // ___/~~\__/~~\__/~~\_/~~\__/~~\____/~~\____/~~\__/~~\_/~~\_/~\
    // /~~~~\____/~~~~~~\__/~~\__/~~\____/~~\____/~~\__/~~\_\__/~\~/
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (token/ERC721/IERC721.sol)

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
// OpenZeppelin Contracts v4.4.1 (token/ERC1155/IERC1155.sol)

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
     * - If the caller is not `from`, it must be have been approved to spend ``from``'s tokens via {setApprovalForAll}.
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
// OpenZeppelin Contracts (last updated v4.5.0) (token/ERC20/IERC20.sol)

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

// SPDX-License-Identifier: GNU
pragma solidity >=0.5.0;
import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";

interface IWETH is IERC20 {
    function deposit() external payable;

    function withdraw(uint256) external;
}

pragma solidity 0.8.12;

import {Ownable} from "@openzeppelin/contracts/access/Ownable.sol";
import {Pausable} from "@openzeppelin/contracts/security/Pausable.sol";
import {ReentrancyGuard} from "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import {IRoyaltyFeeManager} from "../interfaces/IRoyaltyFeeManager.sol";
import {ICollectionRegistry} from "../../collections/interfaces/ICollectionRegistry.sol";

import {IRewards} from "../../rewards/interfaces/IRewards.sol";
import {Errors} from "./Errors.sol";
import {IWETH} from "../interfaces/IWETH.sol";

contract ExchangeCore is Ownable, Pausable, ReentrancyGuard, Errors {
    // Wrapped ETH
    address public immutable WETH;
    // Genesis jumy nft collection
    address public immutable JUMY_COLLECTION;

    // Jumy royalty fee manager and registry
    IRoyaltyFeeManager public royaltyManager;

    // Jumy creator collections registry
    ICollectionRegistry public collectionRegistry;

    // Jumy token rewards
    IRewards public rewardsManager;

    address public protocolFeesRecipient;
    uint256 public protocolFeesPercentage = 500; // 5%, {100_00}Base

    // Allowed collection to be listed
    mapping(address => bool) public whitelistedCustomCollection;

    // Not Allowed collection from been listed
    mapping(address => bool) public blackListedCollection;

    // Not Allowed users from listing
    mapping(address => bool) public blackListedUser;

    // Defines a different service fees percentage than the global one for some specific collections (e.g., Brands)
    mapping(address => uint256) public specialProtocolFeesPercentage;

    // Withdrawable ETH of failed transfers
    mapping(address => uint256) public failedEthTransfer;

    event RoyaltySent(address indexed to, address collection, uint256 amount);

    event ServiceFeesCollected(address indexed to, uint256 amount);

    event FailedToSendEth(address to, uint256 amount);

    event FailedEthWithdrawn(address from, address to, uint256 amount);

    event StuckEthWithdrawn(uint256 amount);

    event StuckERC721Transferred(
        address collection,
        uint256 tokenId,
        address to
    );

    event StuckERC1155Transferred(
        address collection,
        uint256 tokenId,
        uint256 amount,
        address to
    );

    modifier onlyNonBlacklistedUsers() {
        if (blackListedUser[msg.sender]) revert BlacklistedUser();
        _;
    }

    modifier onlyAllowedToBeListed(address collection) {
        if (!_isAllowedToBeListed(collection))
            revert Exchange_UnAuthorized_Collection();
        _;
    }

    constructor(
        address weth,
        address jumyNftCollection,
        address royaltyManagerContract,
        address collectionRegistryContract,
        address protocolFeesRecipientWallet
    ) {
        if (protocolFeesRecipientWallet == address(0))
            revert RejectedNullishAddress();

        if (weth == address(0)) revert RejectedNullishAddress();

        if (jumyNftCollection == address(0)) revert RejectedNullishAddress();

        WETH = weth;
        JUMY_COLLECTION = jumyNftCollection;
        royaltyManager = IRoyaltyFeeManager(royaltyManagerContract);
        collectionRegistry = ICollectionRegistry(collectionRegistryContract);
        protocolFeesRecipient = protocolFeesRecipientWallet;
    }

    function isAllowedToBeListed(address collection)
        external
        view
        returns (bool)
    {
        return _isAllowedToBeListed(collection);
    }

    function getProtocolFeesPercentage(address collection)
        external
        view
        returns (uint256)
    {
        return _getProtocolFeesPercentage(collection);
    }

    /**
     * @dev Get the service fees percentage 10_000 base (500 ==> 5%, 50 ==> 0.5%).
     * @notice function will check if there's any manually custom fees percentage.
     * set for a specific collection in the `specialProtocolFeesPercentage` mapping
     * if there's no custom collection specific fees it returns the global fees percentage `protocolFeesPercentage`.
     */
    function _getProtocolFeesPercentage(address collection)
        internal
        view
        returns (uint256)
    {
        uint256 percentage = specialProtocolFeesPercentage[collection];

        if (percentage == 0) return protocolFeesPercentage;
        return percentage;
    }

    /**
     * @dev Calculate the service fees amount.
     * @notice Take the total amount and calculate the service fees amount
     * by getting the fees percentage and divide by 10,000.
     */
    function _calculateProtocolFeesAmount(uint256 amount, address collection)
        internal
        view
        returns (uint256)
    {
        return (amount * _getProtocolFeesPercentage(collection)) / 10_000;
    }

    /**
     * @dev define the whitelist collection logic.
     * @notice the whitelisted collections are:
     * - genesis collection `JUMY_COLLECTION`.
     * - creators collections registered in `collectionRegistry`.
     * - custom manually imported collections.
     * @notice all manually blacklisted collection are rejected.
     */
    function _isAllowedToBeListed(address collection)
        internal
        view
        returns (bool)
    {
        return ((!blackListedCollection[collection] &&
            // must not be blacklisted
            // if it's genesis jumy collection
            // if it's jumy collection created via factory
            // if it's any other collection added bya admin
            (collection == JUMY_COLLECTION)) ||
            collectionRegistry.isJumyCollection(collection) ||
            whitelistedCustomCollection[collection]);
    }

    /**
     * @dev Split and Send ETH or FAIL.
     * @notice ETH amount will be split to:
     * - #1 Service fees, Will be sent to {protocolFeesRecipient}.
     * - #2 Royalty fees, Will be sent to royalty recipient.
     * - #3 Remaining funds (total - #1 - #2), Will be sent to {to}.
     *
     * @notice If any of the above failed to send ETH, transaction will revert.
     */
    function _executeETHPayment(
        address collection,
        uint256 tokenId,
        address to,
        uint256 amount
    ) internal {
        (address royaltyFeesRecipient, uint256 royaltyCut) = royaltyManager
            .calculateRoyaltyFeeAndGetRecipient(collection, tokenId, amount);

        uint256 serviceCut = _calculateProtocolFeesAmount(amount, collection);

        uint256 recipientCut = amount - serviceCut - royaltyCut;

        payable(to).transfer(recipientCut);
        payable(royaltyFeesRecipient).transfer(royaltyCut);
        payable(protocolFeesRecipient).transfer(serviceCut);

        emit RoyaltySent(royaltyFeesRecipient, collection, royaltyCut);
    }

    /**
     * @dev Split and Send ETH and save for withdraw if FAIL.
     * @notice ETH amount will be split to:
     * - #1 Service fees, Will be sent to {protocolFeesRecipient}.
     * - #2 Royalty fees, Will be sent to royalty recipient.
     * - #3 Remaining funds (total - #1 - #2), Will be sent to {to}.
     *
     * @notice If any of the above failed to send ETH, ETH amount will
     * be stored and made available to withdraw by the recipient.
     */
    function _executeETHPaymentWithFallback(
        address collection,
        uint256 tokenId,
        address to,
        uint256 amount
    ) internal {
        (address royaltyFeesRecipient, uint256 royaltyCut) = royaltyManager
            .calculateRoyaltyFeeAndGetRecipient(collection, tokenId, amount);

        uint256 serviceCut = _calculateProtocolFeesAmount(amount, collection);

        uint256 recipientCut = amount - serviceCut - royaltyCut;

        payable(protocolFeesRecipient).transfer(serviceCut);

        if (!payable(to).send(recipientCut)) {
            failedEthTransfer[to] = recipientCut;
            emit FailedToSendEth(to, recipientCut);
        }

        if (!payable(royaltyFeesRecipient).send(royaltyCut)) {
            failedEthTransfer[royaltyFeesRecipient] = royaltyCut;
            emit FailedToSendEth(royaltyFeesRecipient, royaltyCut);
            return;
        }

        emit RoyaltySent(royaltyFeesRecipient, collection, royaltyCut);
    }

    /**
     * @dev Withdraw WETH then Split Send ETH or FAIL.
     * @notice WETH will be transferred from {from} then withdrawn (WETH => ETH).
     * @notice ETH amount will be split to:
     * - #1 Service fees, Will be sent to {protocolFeesRecipient}.
     * - #2 Royalty fees, Will be sent to royalty recipient.
     * - #3 Remaining funds (total - #1 - #2), Will be sent to {to}.
     *
     * @notice If any of the above failed to send ETH, transaction will revert.
     */
    function _executeWETHPayment(
        address collection,
        uint256 tokenId,
        address from,
        address to,
        uint256 amount
    ) internal {
        (address royaltyFeesRecipient, uint256 royaltyCut) = royaltyManager
            .calculateRoyaltyFeeAndGetRecipient(collection, tokenId, amount);

        uint256 serviceCut = _calculateProtocolFeesAmount(amount, collection);

        uint256 recipientCut = amount - serviceCut - royaltyCut;

        IWETH(WETH).transferFrom(from, address(this), amount);

        IWETH(WETH).withdraw(amount);

        payable(to).transfer(recipientCut);

        payable(royaltyFeesRecipient).transfer(royaltyCut);

        payable(protocolFeesRecipient).transfer(serviceCut);

        emit RoyaltySent(royaltyFeesRecipient, collection, royaltyCut);
    }

    /**
     * @dev Send ETH or save for withdraw on FAIL
     * @notice If FAILED to send ETH, ETH amount will be stored and made available
     * for withdraw.
     */
    function _sendEthWithFallback(address to, uint256 amount) internal {
        if (!payable(to).send(amount)) {
            failedEthTransfer[to] = amount;
            emit FailedToSendEth(to, amount);
            return;
        }
    }

    function withdrawETH(address to) external nonReentrant {
        uint256 amount = failedEthTransfer[msg.sender];

        if (amount == 0) revert();

        delete failedEthTransfer[msg.sender];

        payable(to).transfer(amount);

        emit FailedEthWithdrawn(msg.sender, to, amount);
    }
}

pragma solidity 0.8.12;

import {IRoyaltyFeeManager} from "../interfaces/IRoyaltyFeeManager.sol";
import {ICollectionRegistry} from "../../collections/interfaces/ICollectionRegistry.sol";
import {ExchangeCore} from "./ExchangeCore.sol";
import {IERC721} from "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import {IERC1155} from "@openzeppelin/contracts/token/ERC1155/IERC1155.sol";

import {IRewards} from "../../rewards/interfaces/IRewards.sol";
abstract contract ExchangeManager is ExchangeCore {
    event ProtocolFeesRecipientUpdated(address indexed recipient);
    event ProtocolFeesPercentageUpdated(uint256 percentage);
    event SpecialCollectionProtocolFeesUpdated(
        address collection,
        uint256 percentage
    );
    event RoyaltyManagerUpdated(address indexed royaltyManager);
    event CollectionRegistryUpdated(address indexed collectionRegistry);
    event WhitelistedCustomCollectionUpdated(address collection, bool state);
    event BlackListedCollectionUpdated(address collection, bool state);
    event BlackListedUserUpdated(address account, bool state);

    function pause() external onlyOwner {
        _pause();
    }

    function unpause() external onlyOwner {
        _unpause();
    }

    function updateProtocolFeesPercentage(uint256 newPercentage)
        external
        onlyOwner
        returns (uint256)
    {
        if (newPercentage > 5_000) revert InvalidArg("max newPercentage");

        if (newPercentage == protocolFeesPercentage)
            revert RejectedAlreadyInState();

        protocolFeesPercentage = newPercentage;
        emit ProtocolFeesPercentageUpdated(newPercentage);
        return newPercentage;
    }

    function updateSpecialProtocolFeesPercentage(
        address collection,
        uint256 percentage
    ) external onlyOwner returns (uint256) {
        if (percentage > 5_000) revert InvalidArg("max newPercentage");

        if (collection == address(0)) revert RejectedNullishAddress();

        if (specialProtocolFeesPercentage[collection] == percentage)
            revert RejectedAlreadyInState();

        specialProtocolFeesPercentage[collection] = percentage;
        emit SpecialCollectionProtocolFeesUpdated(collection, percentage);
        return percentage;
    }

    function updateProtocolFeesRecipient(address newRecipient)
        external
        onlyOwner
        returns (address)
    {
        if (newRecipient == address(0)) revert RejectedNullishAddress();
        protocolFeesRecipient = newRecipient;
        emit ProtocolFeesRecipientUpdated(newRecipient);
        return newRecipient;
    }

    /**
     * @dev Update {royaltyManager}
     * @notice {onlyOwner} protected
     */
    function updateRoyaltyManager(address newRoyaltyManager)
        external
        onlyOwner
        returns (address)
    {
        if (newRoyaltyManager == address(0)) revert RejectedNullishAddress();
        royaltyManager = IRoyaltyFeeManager(newRoyaltyManager);
        emit RoyaltyManagerUpdated(newRoyaltyManager);
        return newRoyaltyManager;
    }

      /**
     * @dev Update {rewardsManager}
     * @notice {onlyOwner} protected
     */
    function updateRewardsManager(address newRewardsManager)
        external
        onlyOwner
        returns (address)
    {
        if (newRewardsManager == address(0)) revert RejectedNullishAddress();
        rewardsManager = IRewards(newRewardsManager);
        emit RoyaltyManagerUpdated(newRewardsManager);
        return newRewardsManager;
    }

    function updateCollectionRegistry(address newCollectionRegistry)
        external
        onlyOwner
        returns (address)
    {
        if (newCollectionRegistry == address(0))
            revert RejectedNullishAddress();
        collectionRegistry = ICollectionRegistry(newCollectionRegistry);
        emit CollectionRegistryUpdated(newCollectionRegistry);
        return newCollectionRegistry;
    }

    function updateWhitelistedCustomCollection(address collection, bool state)
        external
        onlyOwner
        returns (bool)
    {
        if (collection == address(0)) revert RejectedNullishAddress();

        if (whitelistedCustomCollection[collection] == state)
            revert RejectedAlreadyInState();

        whitelistedCustomCollection[collection] = state;
        emit WhitelistedCustomCollectionUpdated(collection, state);
        return true;
    }

    function updateBlacklistedUser(address account, bool state)
        external
        onlyOwner
        returns (bool)
    {
        if (account == address(0)) revert RejectedNullishAddress();

        if (blackListedUser[account] == state) revert RejectedAlreadyInState();

        blackListedUser[account] = state;
        emit BlackListedUserUpdated(account, state);
        return true;
    }

    function updateBlackListedCollection(address collection, bool state)
        external
        onlyOwner
        returns (bool)
    {
        if (collection == address(0)) revert RejectedNullishAddress();

        if (blackListedCollection[collection] == state)
            revert RejectedAlreadyInState();

        blackListedCollection[collection] = state;
        emit BlackListedCollectionUpdated(collection, state);
        return true;
    }

    function withdrawStuckETH(uint256 amount, address to)
        external
        onlyOwner
        nonReentrant
    {
        payable(to).transfer(amount);
        emit StuckEthWithdrawn(amount);
    }

    function withdrawStuckETHFrom(address from, address to)
        external
        onlyOwner
        nonReentrant
    {
        uint256 amount = failedEthTransfer[from];

        if (amount == 0) revert();

        delete failedEthTransfer[from];

        payable(to).transfer(amount);

        emit StuckEthWithdrawn(amount);
        emit FailedEthWithdrawn(from, to, amount);
    }

    function transferStuckERC721(
        address collection,
        uint256 tokenId,
        address to
    ) external onlyOwner nonReentrant {
        IERC721(collection).safeTransferFrom(address(this), to, tokenId);

        emit StuckERC721Transferred(collection, tokenId, to);
    }

    function transferStuckERC1155(
        address collection,
        uint256 tokenId,
        uint256 amount,
        address to
    ) external onlyOwner nonReentrant {
        IERC1155(collection).safeTransferFrom(
            address(this),
            to,
            tokenId,
            amount,
            ""
        );

        emit StuckERC1155Transferred(collection, tokenId, amount, to);
    }
}

pragma solidity 0.8.12;

import {ExchangeCore} from "../core/ExchangeCore.sol";
import {IERC721} from "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import {IWETH} from "../interfaces/IWETH.sol";

abstract contract ERC721FixedPrice is ExchangeCore {
    struct FixedPriceListing {
        address seller;
        uint256 price;
    }

    struct Offer {
        uint256 value;
        uint256 expiresAt;
    }

    mapping(address => mapping(uint256 => FixedPriceListing))
        public fixedPriceListings;

    mapping(address => mapping(uint256 => mapping(address => Offer)))
        public offers;

    event ItemListed(
        address indexed account,
        address indexed collection,
        uint256 tokenId,
        uint256 price
    );

    event ItemRemoved(
        address indexed account,
        address indexed collection,
        uint256 tokenId
    );

    event ItemPurchased(
        address indexed buyer,
        address seller,
        address indexed collection,
        uint256 tokenId,
        uint256 price
    );

    event OfferMade(
        address account,
        address indexed collection,
        uint256 tokenId,
        uint256 offerValue,
        uint256 validityDuration,
        uint256 expiresAt
    );

    event OfferCancelled(
        address account,
        address indexed collection,
        uint256 tokenId
    );

    event OfferAccepted(
        address beneficiary,
        address indexed collection,
        uint256 tokenId,
        uint256 price
    );

    function listItem(
        address collection,
        uint256 tokenId,
        uint256 price
    )
        external
        onlyAllowedToBeListed(collection)
        whenNotPaused
        onlyNonBlacklistedUsers
        nonReentrant
    {
        _listItem(collection, tokenId, price);
    }

    function listItem(
        address collection,
        uint256 tokenId,
        uint256 price,
        address royaltyReceiver,
        uint256 royaltyPercentage
    ) external whenNotPaused onlyNonBlacklistedUsers nonReentrant {
        if (collection != JUMY_COLLECTION)
            revert Exchange_Rejected_Genesis_Collection_Only();

        _listItem(collection, tokenId, price);

        royaltyManager.setJumyTokenRoyalty(
            collection,
            tokenId,
            royaltyReceiver,
            royaltyPercentage
        );
    }

    function removeItem(address collection, uint256 tokenId)
        external
        nonReentrant
    {
        if (collection == address(0)) revert RejectedNullishAddress();

        if (fixedPriceListings[collection][tokenId].seller != msg.sender) {
            revert Exchange_Not_Sale_Owner();
        }

        delete fixedPriceListings[collection][tokenId];

        emit ItemRemoved(msg.sender, collection, tokenId);
    }

    function purchaseItem(
        address collection,
        uint256 tokenId,
        address to
    ) external payable nonReentrant {
        if (collection == address(0)) revert RejectedNullishAddress();
        if (to == address(0)) revert RejectedNullishAddress();

        FixedPriceListing memory item = fixedPriceListings[collection][tokenId];

        if (item.seller == address(0) || item.price == 0)
            revert Exchange_Listing_Not_Found();

        if (msg.value != item.price) revert Exchange_Wrong_Price_Value();

        delete fixedPriceListings[collection][tokenId];

        ExchangeCore._executeETHPayment(
            collection,
            tokenId,
            item.seller,
            item.price
        );

        IERC721(collection).transferFrom(item.seller, to, tokenId);

        if (address(rewardsManager) != address(0)) {
            rewardsManager.purchaseEvent(
                item.seller,
                to,
                item.price,
                collection,
                tokenId
            );
        }

        emit ItemPurchased(to, item.seller, collection, tokenId, item.price);
    }

    function makeOffer(
        uint256 offerValue,
        uint256 validityDuration,
        address collection,
        uint256 tokenId
    ) external nonReentrant {
        if (collection == address(0)) revert RejectedNullishAddress();

        if (validityDuration == 0) revert Exchange_Rejected_Nullish_Duration();

        if (offerValue == 0) revert Exchange_Rejected_Nullish_Offer_Value();

        uint256 wethAllowance = IWETH(WETH).allowance(
            msg.sender,
            address(this)
        );
        if (wethAllowance < offerValue)
            revert Exchange_Insufficient_WETH_Allowance(wethAllowance);

        uint256 expiresAt = block.timestamp + validityDuration;

        offers[collection][tokenId][msg.sender].value = offerValue;
        offers[collection][tokenId][msg.sender].expiresAt = expiresAt;

        emit OfferMade(
            msg.sender,
            collection,
            tokenId,
            offerValue,
            validityDuration,
            expiresAt
        );
    }

    function cancelOffer(address collection, uint256 tokenId)
        external
        nonReentrant
    {
        if (collection == address(0)) revert RejectedNullishAddress();

        delete offers[collection][tokenId][msg.sender];

        emit OfferCancelled(msg.sender, collection, tokenId);
    }

    function acceptOffer(
        address beneficiary,
        uint256 offerValue,
        address collection,
        uint256 tokenId
    ) external nonReentrant {
        if (collection == address(0)) revert RejectedNullishAddress();
        if (beneficiary == address(0)) revert RejectedNullishAddress();

        Offer memory offer = offers[collection][tokenId][beneficiary];

        delete offers[collection][tokenId][beneficiary];
        delete fixedPriceListings[collection][tokenId];

        if (offer.value != offerValue)
            revert Exchange_Wrong_Offer_Value(offer.value);
        if (offer.expiresAt < block.timestamp)
            revert Exchange_Expired_Offer(offer.expiresAt);

        ExchangeCore._executeWETHPayment(
            collection,
            tokenId,
            beneficiary,
            msg.sender,
            offerValue
        );
        IERC721(collection).safeTransferFrom(msg.sender, beneficiary, tokenId);

        if (address(rewardsManager) != address(0)) {
            rewardsManager.purchaseEvent(
                msg.sender,
                beneficiary,
                offer.value,
                collection,
                tokenId
            );
        }

        emit OfferAccepted(beneficiary, collection, tokenId, offerValue);
    }

    function _listItem(
        address collection,
        uint256 tokenId,
        uint256 price
    ) private {
        if (price == 0) revert Exchange_Invalid_Nullish_Price();

        if (IERC721(collection).ownerOf(tokenId) != msg.sender)
            revert Exchange_Not_The_Token_Owner();

        if (
            !IERC721(collection).isApprovedForAll(msg.sender, address(this)) &&
            IERC721(collection).getApproved(tokenId) != address(this)
        ) revert Exchange_Insufficient_Operator_Privilege();

        fixedPriceListings[collection][tokenId] = FixedPriceListing(
            msg.sender,
            price
        );

        emit ItemListed(msg.sender, collection, tokenId, price);
    }
}

pragma solidity 0.8.12;

import {IERC721} from "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import {ExchangeCore} from "../core/ExchangeCore.sol";

abstract contract ReserveAuction is ExchangeCore {
    uint32 constant AUCTION_DURATION = 24 hours;
    uint16 constant MINIMUM_BID_END_AUCTION_BUFFER = 15 minutes;
    uint8 constant MINIMUM_BID_INCREASE_PERCENTAGE = 5;

    struct Auction {
        address seller;
        uint256 startPrice;
        address maxBidder;
        uint256 maxBid;
        uint256 startsAt;
        uint128 endsAt;
    }

    mapping(address => mapping(uint256 => Auction)) public auctions;

    event ReserveAuctionCreated(
        address creator,
        address indexed collection,
        uint256 tokenId,
        uint256 startPrice,
        uint256 startsAt
    );

    event ReserveAuctionBid(
        address bidder,
        address indexed collection,
        uint256 tokenId,
        uint256 bidValue,
        uint256 endsAt
    );

    event ReserveAuctionClaimed(
        address seller,
        address maxBidder,
        address indexed collection,
        uint256 tokenId,
        uint256 endedAt,
        uint256 maxBid
    );

    event ReserveAuctionCanceled(
        address seller,
        address indexed collection,
        uint256 tokenId
    );

    function createReserveAuction(
        address collection,
        uint256 tokenId,
        uint256 startPrice,
        uint256 startsAt
    )
        external
        onlyAllowedToBeListed(collection)
        whenNotPaused
        onlyNonBlacklistedUsers
        nonReentrant
    {
        if (startsAt < block.timestamp)
            revert Exchange_Starts_At_Must_Be_In_Future();
        if (startsAt - block.timestamp > 15 days)
            revert Exchange_Starts_At_Too_Far();

        _createReserveAuction(collection, tokenId, startPrice, startsAt);
    }

    function createReserveAuction(
        address collection,
        uint256 tokenId,
        uint256 startPrice
    )
        external
        onlyAllowedToBeListed(collection)
        whenNotPaused
        onlyNonBlacklistedUsers
        nonReentrant
    {
        _createReserveAuction(collection, tokenId, startPrice, block.timestamp);
    }

    function createReserveAuction(
        address collection,
        uint256 tokenId,
        address royaltyReceiver,
        uint256 royaltyPercentage,
        uint256 startPrice,
        uint256 startsAt
    )
        external
        onlyAllowedToBeListed(collection)
        whenNotPaused
        onlyNonBlacklistedUsers
        nonReentrant
    {
        if (collection != JUMY_COLLECTION)
            revert Exchange_Rejected_Genesis_Collection_Only();

        if (startsAt < block.timestamp)
            revert Exchange_Starts_At_Must_Be_In_Future();
        if (startsAt - block.timestamp > 15 days)
            revert Exchange_Starts_At_Too_Far();

        _createReserveAuction(collection, tokenId, startPrice, startsAt);

        royaltyManager.setJumyTokenRoyalty(
            collection,
            tokenId,
            royaltyReceiver,
            royaltyPercentage
        );
    }

    function createReserveAuction(
        address collection,
        uint256 tokenId,
        address royaltyReceiver,
        uint256 royaltyPercentage,
        uint256 startPrice
    )
        external
        onlyAllowedToBeListed(collection)
        whenNotPaused
        onlyNonBlacklistedUsers
        nonReentrant
    {
        if (collection != JUMY_COLLECTION)
            revert Exchange_Rejected_Genesis_Collection_Only();

        _createReserveAuction(collection, tokenId, startPrice, block.timestamp);

        royaltyManager.setJumyTokenRoyalty(
            collection,
            tokenId,
            royaltyReceiver,
            royaltyPercentage
        );
    }

    function bid(address collection, uint256 tokenId)
        external
        payable
        nonReentrant
        onlyNonBlacklistedUsers
    {
        if (collection == address(0)) revert RejectedNullishAddress();

        Auction memory auction = auctions[collection][tokenId];

        if (block.timestamp < auction.startsAt)
            revert Exchange_Drop_Not_Started_Yet();

        // FLOW 01:: Auction did't start yet, and this is the first bid
        // Execute the bellow block and return
        if (auction.endsAt == 0) {
            if (msg.value < auction.startPrice)
                revert Exchange_Invalid_Start_Price(
                    auction.startPrice,
                    msg.value
                );
            auctions[collection][tokenId].endsAt =
                uint128(block.timestamp) +
                AUCTION_DURATION;

            auctions[collection][tokenId].maxBidder = msg.sender;
            auctions[collection][tokenId].maxBid = msg.value;

            emit ReserveAuctionBid(
                msg.sender,
                collection,
                tokenId,
                msg.value,
                auctions[collection][tokenId].endsAt
            );
            return;
        }

        // FLOW 02:: Auction already started but expired
        // (FLOW 01) is ignored
        if (block.timestamp > auction.endsAt) {
            revert Exchange_Rejected_Ended_Auction(
                auction.endsAt,
                block.timestamp
            );
        }

        // FLOW 03:: Auction already started and not expired
        // (FLOW 01) and (FLOW 02) are ignored
        // Extend if it Will expire in less than 15 minutes
        uint128 fifteenMinutesLater = uint128(block.timestamp) +
            MINIMUM_BID_END_AUCTION_BUFFER;
        if (fifteenMinutesLater > auction.endsAt) {
            auctions[collection][tokenId].endsAt = fifteenMinutesLater;
        }

        // Revert if value is not 5% higher than previous bid
        uint256 minimumNextBid = auction.maxBid +
            ((auction.maxBid * MINIMUM_BID_INCREASE_PERCENTAGE) / 100);
        if (msg.value < minimumNextBid)
            revert Exchange_Rejected_Must_Be_5_Percent_Higher(
                minimumNextBid,
                msg.value
            );

        auctions[collection][tokenId].maxBidder = msg.sender;
        auctions[collection][tokenId].maxBid = msg.value;

        // Refund previous bidder, send eth with fallback
        ExchangeCore._sendEthWithFallback(auction.maxBidder, auction.maxBid);

        emit ReserveAuctionBid(
            msg.sender,
            collection,
            tokenId,
            msg.value,
            auctions[collection][tokenId].endsAt
        );
    }

    function cancelAuction(address collection, uint256 tokenId)
        external
        nonReentrant
    {
        if (auctions[collection][tokenId].seller != msg.sender)
            revert Exchange_Rejected_Not_Auction_Owner();

        if (auctions[collection][tokenId].endsAt != 0)
            revert Exchange_Rejected_Auction_In_Progress();

        delete auctions[collection][tokenId];

        IERC721(collection).transferFrom(address(this), msg.sender, tokenId);

        emit ReserveAuctionCanceled(msg.sender, collection, tokenId);
    }

    function claimAuction(address collection, uint256 tokenId)
        external
        nonReentrant
    {
        Auction memory auction = auctions[collection][tokenId];
        delete auctions[collection][tokenId];

        // Auction not found
        if (auction.seller == address(0) || auction.maxBidder == address(0))
            revert Exchange_Auction_Not_Found();

        // Auction didn't start yet
        if (auction.endsAt == 0)
            revert Exchange_Rejected_Auction_Not_Started_Yet();

        // Auction still in progress
        if (block.timestamp < auction.endsAt)
            revert Exchange_Rejected_Auction_In_Progress();

        ExchangeCore._executeETHPaymentWithFallback(
            collection,
            tokenId,
            auction.seller,
            auction.maxBid
        );

        IERC721(collection).transferFrom(
            address(this),
            auction.maxBidder,
            tokenId
        );

        if (address(rewardsManager) != address(0)) {
            rewardsManager.purchaseEvent(
                auction.maxBidder,
                auction.seller,
                auction.maxBid,
                collection,
                tokenId
            );
        }

        emit ReserveAuctionClaimed(
            auction.seller,
            auction.maxBidder,
            collection,
            tokenId,
            auction.endsAt,
            auction.maxBid
        );
    }

    function _createReserveAuction(
        address collection,
        uint256 tokenId,
        uint256 startPrice,
        uint256 startsAt
    ) private {
        if (startPrice == 0) revert Exchange_Invalid_Nullish_Price();
        if (collection == address(0)) revert RejectedNullishAddress();

        IERC721(collection).transferFrom(msg.sender, address(this), tokenId);

        auctions[collection][tokenId] = Auction({
            seller: msg.sender,
            startPrice: startPrice,
            maxBidder: address(0),
            maxBid: 0,
            startsAt: startsAt,
            endsAt: 0
        });

        emit ReserveAuctionCreated(
            msg.sender,
            collection,
            tokenId,
            startPrice,
            startsAt
        );
    }
}

pragma solidity 0.8.12;

import {ExchangeCore} from "../core/ExchangeCore.sol";
import {IERC1155} from "@openzeppelin/contracts/token/ERC1155/IERC1155.sol";
import {IWETH} from "../interfaces/IWETH.sol";

abstract contract ERC1155FixedPrice is ExchangeCore {
    struct FixedPriceListingERC1155 {
        uint256 quantity;
        uint256 price;
    }

    struct OfferERC1155 {
        uint256 value;
        uint128 quantity;
        uint128 expiresAt;
    }

    mapping(address => mapping(uint256 => mapping(address => FixedPriceListingERC1155)))
        public fixedPriceListingsERC1155;

    mapping(address => mapping(uint256 => mapping(address => OfferERC1155)))
        public offersERC1155;

    event ItemListedERC1155(
        address indexed account,
        address indexed collection,
        uint256 tokenId,
        uint256 price,
        uint256 quantity
    );

    event ItemRemovedERC1155(
        address indexed account,
        address indexed collection,
        uint256 tokenId
    );

    event ItemPurchasedERC1155(
        address indexed buyer,
        address seller,
        address indexed collection,
        uint256 tokenId,
        uint256 quantity,
        uint256 price
    );

    event OfferMadeERC1155(
        address account,
        address indexed collection,
        uint256 tokenId,
        uint256 quantity,
        uint256 offerValue,
        uint256 validityDuration,
        uint256 expiresAt
    );

    event OfferCancelledERC1155(
        address account,
        address indexed collection,
        uint256 tokenId
    );

    event OfferAcceptedERC1155(
        address beneficiary,
        address seller,
        address indexed collection,
        uint256 tokenId,
        uint128 quantity,
        uint256 price
    );

    function listItemERC1155(
        address collection,
        uint256 tokenId,
        uint256 quantity,
        uint256 price
    )
        external
        onlyAllowedToBeListed(collection)
        whenNotPaused
        onlyNonBlacklistedUsers
        nonReentrant
    {
        if (price == 0) revert Exchange_Invalid_Nullish_Price();

        if (IERC1155(collection).balanceOf(msg.sender, tokenId) < quantity)
            revert Exchange_Not_The_Token_Owner();

        if (!IERC1155(collection).isApprovedForAll(msg.sender, address(this)))
            revert Exchange_Insufficient_Operator_Privilege();

        fixedPriceListingsERC1155[collection][tokenId][
            msg.sender
        ] = FixedPriceListingERC1155(quantity, price);

        emit ItemListedERC1155(
            msg.sender,
            collection,
            tokenId,
            price,
            quantity
        );
    }

    function removeItemERC1155(address collection, uint256 tokenId)
        external
        nonReentrant
    {
        if (collection == address(0)) revert RejectedNullishAddress();

        delete fixedPriceListingsERC1155[collection][tokenId][msg.sender];

        emit ItemRemovedERC1155(msg.sender, collection, tokenId);
    }

    function purchaseItemERC1155(
        address collection,
        uint256 tokenId,
        uint256 quantity,
        address seller,
        address to
    ) external payable nonReentrant {
        if (
            collection == address(0) || to == address(0) || seller == address(0)
        ) revert RejectedNullishAddress();

        FixedPriceListingERC1155 memory item = fixedPriceListingsERC1155[
            collection
        ][tokenId][seller];

        if (item.quantity == 0 || item.price == 0)
            revert Exchange_Listing_Not_Found();

        if (item.quantity != quantity) {
            revert Exchange_Unmatched_Quantity(item.quantity, quantity);
        }

        if (msg.value != item.price) revert Exchange_Wrong_Price_Value();

        delete fixedPriceListingsERC1155[collection][tokenId][seller];

        ExchangeCore._executeETHPayment(
            collection,
            tokenId,
            seller,
            item.price
        );

        IERC1155(collection).safeTransferFrom(
            seller,
            to,
            tokenId,
            item.quantity,
            ""
        );

        if (address(rewardsManager) != address(0)) {
            rewardsManager.purchaseEvent(
                seller,
                to,
                item.price,
                collection,
                tokenId,
                quantity
            );
        }

        emit ItemPurchasedERC1155(
            msg.sender,
            seller,
            collection,
            tokenId,
            quantity,
            item.price
        );
    }

    function makeOfferERC1155(
        address collection,
        uint256 tokenId,
        uint128 quantity,
        uint128 validityDuration,
        uint256 offerValue
    ) external nonReentrant {
        if (collection == address(0)) revert RejectedNullishAddress();

        if (validityDuration == 0) revert Exchange_Rejected_Nullish_Duration();

        if (offerValue == 0) revert Exchange_Rejected_Nullish_Offer_Value();

        if (quantity == 0) revert Exchange_Rejected_Nullish_Quantity();

        uint256 wethAllowance = IWETH(WETH).allowance(
            msg.sender,
            address(this)
        );
        if (wethAllowance < offerValue)
            revert Exchange_Insufficient_WETH_Allowance(wethAllowance);

        uint128 expiresAt = uint128(block.timestamp) + validityDuration;

        offersERC1155[collection][tokenId][msg.sender] = OfferERC1155({
            value: offerValue,
            quantity: quantity,
            expiresAt: expiresAt
        });

        emit OfferMadeERC1155(
            msg.sender,
            collection,
            tokenId,
            quantity,
            offerValue,
            validityDuration,
            expiresAt
        );
    }

    function cancelOfferERC1155(address collection, uint256 tokenId)
        external
        nonReentrant
    {
        if (collection == address(0)) revert RejectedNullishAddress();

        delete offersERC1155[collection][tokenId][msg.sender];

        emit OfferCancelledERC1155(msg.sender, collection, tokenId);
    }

    function acceptOfferERC1155(
        address beneficiary,
        address collection,
        uint256 tokenId,
        uint128 quantity,
        uint256 offerValue
    ) external nonReentrant {
        if (collection == address(0)) revert RejectedNullishAddress();
        if (beneficiary == address(0)) revert RejectedNullishAddress();
        if (quantity == 0) revert Exchange_Rejected_Nullish_Quantity();

        OfferERC1155 memory offer = offersERC1155[collection][tokenId][
            beneficiary
        ];

        delete offersERC1155[collection][tokenId][beneficiary];
        delete fixedPriceListingsERC1155[collection][tokenId][msg.sender];

        if (offer.value != offerValue)
            revert Exchange_Wrong_Offer_Value(offer.value);

        if (offer.expiresAt < block.timestamp)
            revert Exchange_Expired_Offer(offer.expiresAt);

        if (quantity != offer.quantity)
            revert Exchange_Unmatched_Quantity(offer.quantity, quantity);

        ExchangeCore._executeWETHPayment(
            collection,
            tokenId,
            beneficiary,
            msg.sender,
            offerValue
        );
        IERC1155(collection).safeTransferFrom(
            msg.sender,
            beneficiary,
            tokenId,
            quantity,
            ""
        );

        if (address(rewardsManager) != address(0)) {
            rewardsManager.purchaseEvent(
                msg.sender,
                beneficiary,
                offer.value,
                collection,
                tokenId,
                quantity
            );
        }

        emit OfferAcceptedERC1155(
            beneficiary,
            msg.sender,
            collection,
            tokenId,
            quantity,
            offerValue
        );
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
// OpenZeppelin Contracts v4.4.1 (access/Ownable.sol)

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
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (security/Pausable.sol)

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

pragma solidity 0.8.12;

interface IRoyaltyFeeManager {
    function calculateRoyaltyFeeAndGetRecipient(
        address collection,
        uint256 tokenId,
        uint256 amount
    ) external view returns (address, uint256);

    function updateRoyaltyInfoForCollection(
        address collection,
        address setter,
        address receiver,
        uint256 fee
    ) external;

    function updateRoyaltyFeeLimit(uint256 _royaltyFeeLimit) external;

    function royaltyInfo(address collection, uint256 amount)
        external
        view
        returns (address, uint256);

    function royaltyFeeInfoCollection(address collection)
        external
        view
        returns (
            address,
            address,
            uint256
        );

    function setJumyTokenRoyalty(
        address collection,
        uint256 tokenId,
        address receiver,
        uint256 percentage
    ) external;
}

pragma solidity 0.8.12;
interface ICollectionRegistry {
    function isJumyCollection(address collection) external view returns (bool);
}

pragma solidity ^0.8.0;

interface IRewards {
    function purchaseEvent(
        address buyer,
        address seller,
        uint256 price,
        address collection,
        uint256 tokenId
    ) external;

    function purchaseEvent(
        address buyer,
        address seller,
        uint256 price,
        address collection,
        uint256 tokenId,
        uint256 amount
    ) external;
}

pragma solidity 0.8.12;

abstract contract Errors {
    error RejectedNullishAddress();
    error RejectedAlreadyInState();
    error InvalidArg(string message);
    error BlacklistedUser();

    error Exchange_Not_The_Token_Owner();
    error Exchange_UnAuthorized_Collection();
    error Exchange_Insufficient_Operator_Privilege();
    error Exchange_Invalid_Nullish_Price();
    error Exchange_Not_Sale_Owner();
    error Exchange_Wrong_Price_Value();
    error Exchange_Listing_Not_Found();
    error Exchange_Rejected_Nullish_Duration();
    error Exchange_Rejected_Nullish_Offer_Value();
    error Exchange_Insufficient_WETH_Allowance(uint256 minAllowance);
    error Exchange_Wrong_Offer_Value(uint256 offerValue);
    error Exchange_Expired_Offer(uint256 expiredAt);
    error Exchange_Unmatched_Quantity(uint256 expected, uint256 received);
    error Exchange_Rejected_Nullish_Quantity();

    error Exchange_Rejected_Genesis_Collection_Only();

    // Reserve Auction
    error Exchange_Invalid_Start_Price(uint256 expected, uint256 received);
    error Exchange_Rejected_Ended_Auction(uint256 endsAt, uint256 current);
    error Exchange_Rejected_Must_Be_5_Percent_Higher(
        uint256 expected,
        uint256 received
    );
    error Exchange_Rejected_Not_Auction_Owner();
    error Exchange_Rejected_Auction_In_Progress();
    error Exchange_Auction_Not_Found();
    error Exchange_Rejected_Auction_Not_Started_Yet();

    error Exchange_Starts_At_Must_Be_In_Future();
    error Exchange_Starts_At_Too_Far();
    error Exchange_Drop_Not_Started_Yet();
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