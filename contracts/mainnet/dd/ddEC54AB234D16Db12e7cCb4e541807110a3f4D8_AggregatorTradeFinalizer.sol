// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity ^0.8.15;

import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import "@openzeppelin/contracts/token/ERC1155/IERC1155.sol";

import "./lib/LooksRareHelper.sol";
import "./lib/X2Y2Helper.sol";

/**
	@custom:benediction DEVS BENEDICAT ET PROTEGAT CONTRACTVS MEAM
	@title GigaMart Aggregated Finalizer
	@author Rostislav Khlebnikov <@catpic5buck>
	@author Tim Clancy <@_Enoch>

	This contract implements delegated order finalization for particular 
	exchanges supported by the multi-market aggregator for GigaMart. In 
	particular, certain exchanges require the orders to be issued from the 
	recipient of the item, like X2Y2 and LooksRare.

	@custom:version 1.0
	@custom:date February 1st, 2023.
*/
contract AggregatorTradeFinalizer {

	/// A constant for the ERC-721 interface ID.
	bytes4 public constant INTERFACE_ID_ERC721 = 0x80ac58cd;

	/// Track the slot for a supported exchange.
	uint256 private constant _SUPPORTED_EXCHANGES_SLOT = 4;
	
	/// Record the address of LooksRare's exchange.
	address private constant _LOOKSRARE_ADDRESS =
		0x59728544B08AB483533076417FbBB2fD0B17CE3a;
	
	/// Record the address of X2Y2's exchange.
	address private constant _X2Y2_ADDRESS =
		0x74312363e45DCaBA76c59ec49a7Aa8A65a67EeD3;

	/**
		A function to initialize storage for this aggregated trade finalizer.
	*/
	function initialize () external {
		assembly {
			mstore(0x00, _LOOKSRARE_ADDRESS)
			mstore(0x20, _SUPPORTED_EXCHANGES_SLOT)
			let lr_key := keccak256(0x00, 0x40)
			mstore(0x00, _X2Y2_ADDRESS)
			let x2y2_key := keccak256(0x00, 0x40)
			sstore(lr_key, add(sload(lr_key), 1))
			sstore(x2y2_key, add(sload(x2y2_key), 1))
		}
	}

	/**
		Match a LooksRare ask, fulfilled using ETH, via this finalizer to transfer 
		the purchased item to the buyer.

		@param _ask The LooksRare ask order being fulfilled.
	*/
	function matchAskWithTakerBidUsingETHAndWETH (
		LooksRareHelper.TakerOrder calldata,
		LooksRareHelper.MakerOrder calldata _ask
	) external payable {
		if (IERC165(_ask.collection).supportsInterface(INTERFACE_ID_ERC721)) {
			IERC721(_ask.collection).safeTransferFrom(
				address(this),
				msg.sender,
				_ask.tokenId
			);
		} else {
			IERC1155(_ask.collection).safeTransferFrom(
				address(this),
				msg.sender,
				_ask.tokenId,
				_ask.amount,
				""
			);
		}
	}

	/**
		Match a LooksRare ask via this finalizer to transfer the purchased item to 
		the buyer.

		@param _ask The LooksRare ask order being fulfilled.
	*/
	function matchAskWithTakerBid (
		LooksRareHelper.TakerOrder calldata,
		LooksRareHelper.MakerOrder calldata _ask
	) external payable {
		if (IERC165(_ask.collection).supportsInterface(INTERFACE_ID_ERC721)) {
			IERC721(_ask.collection).safeTransferFrom(
				address(this),
				msg.sender,
				_ask.tokenId
			);
		} else {
			IERC1155(_ask.collection).safeTransferFrom(
				address(this),
				msg.sender,
				_ask.tokenId,
				_ask.amount,
				""
			);
		}
	}

	/**
		Finalize an X2Y2 purchase.

		@param _input The X2Y2 order input struct.
	*/
	function run (
		X2Y2Helper.RunInput calldata _input
	) external payable {
		for (uint256 i; i < _input.details.length; ) {
			bytes memory data = _input.orders[_input.details[i].orderIdx]
				.items[_input.details[i].itemIdx].data;

			// Replace any data masked within the order.
			{
				if (
					_input.orders[_input.details[i].orderIdx].dataMask.length > 0 
					&& _input.details[i].dataReplacement.length > 0
				) {
					X2Y2Helper.arrayReplace(
						data,
						_input.details[i].dataReplacement,
						_input.orders[_input.details[i].orderIdx].dataMask
					);
				}
			}

			/*
				Divide the data length on the amount of structs in the original bytes 
				array to get a bytes length for a single struct.
			*/
			uint256 pairSize;
			assembly {
				pairSize := div(

					/*
						Load the length of the entire bytes array and escape 64 bytes of 
						offset and length.
					*/
					sub(mload(data), 0x40), 
					
					// Load the length of the Pair structs encoded into the bytes array.
					mload(add(data, 0x40))
				)
			}

			// ERC-721 items transferred by X2Y2 have a data length of two words.
			if (pairSize == 64) {
				X2Y2Helper.Pair721[] memory pairs = abi.decode(
					data,
					(X2Y2Helper.Pair721[])
				);
				for (uint256 j; j < pairs.length; ) {
					IERC721(pairs[j].token).safeTransferFrom(
						address(this),
						msg.sender,
						pairs[j].tokenId
					);

					unchecked {
						++j;
					}
				}

			// If the length is three words, the item is an ERC-1155.
			} else if (pairSize == 96) {
				X2Y2Helper.Pair1155[] memory pairs = abi.decode(
					data,
					(X2Y2Helper.Pair1155[])
				);
				for (uint256 j; j < pairs.length; ) {
					IERC1155(pairs[j].token).safeTransferFrom(
						address(this),
						msg.sender,
						pairs[j].tokenId, pairs[j].amount,
						""
					);

					unchecked {
						++j;
					}
				}
			}

			unchecked {
				++i;
			}
		}
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

// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity ^0.8.15;

/**
	@title LooksRare Helper
	@author LooksRare

	This library defines the structs needed to interface with the LooksRare 
	exchange for fulfilling aggregated orders.
*/
library LooksRareHelper {

	/**
		This struct defines the maker side of a LooksRare order.

		@param isOrderAsk Whether the order is an ask or a bid.
		@param signer The address of the order signer.
		@param collection The address of the NFT collection.
		@param price The price of fulfilling the order.
		@param tokenId The ID of the NFT in the order.
		@param amount The number of the specific token ID being purchased (strictly 
			one for ERC-721 items, potentially greater than one for fungible ERC-1155 
			items).
		@param strategy The strategy to use for trade execution (fixed price, 
			auction, other).
		@param currency The address of the asset being used to pay for the NFT.
		@param nonce An order nonce (unique unless overriding existing order to 
			lower asking price).
		@param startTime The start time of the order.
		@param endTime The end time of the order.
		@param minPercentageToAsk The acceptable slippage on order fulfillment.
		@param params Additional parameters.
		@param v The v component of a signature.
		@param r The r component of a signature.
		@param s The s component of a signature.
	*/
	struct MakerOrder {
		bool isOrderAsk;
		address signer;
		address collection;
		uint256 price;
		uint256 tokenId;
		uint256 amount;
		address strategy;
		address currency;
		uint256 nonce;
		uint256 startTime;
		uint256 endTime;
		uint256 minPercentageToAsk;
		bytes params;
		uint8 v;
		bytes32 r;
		bytes32 s;
	}

	/**
		This struct defines the taker side of a LooksRare order.

		@param isOrderAsk Whether the order is an ask or a bid.
		@param taker The caller fulfilling the order.
		@param price The price of fulfilling the order.
		@param tokenId The ID of the NFT in the order.
		@param minPercentageToAsk The acceptable slippage on order fulfillment.
		@param params Additional parameters.
	*/
	struct TakerOrder {
		bool isOrderAsk;
		address taker;
		uint256 price;
		uint256 tokenId;
		uint256 minPercentageToAsk;
		bytes params;
	}
}

// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity ^0.8.15;

/**
	@title X2Y2 Helper
	@author X2Y2

	This library defines the structs needed to interface with the X2Y2 exchange 
	for fulfilling aggregated orders. Full documentation of X2Y2 structs is left 
	as an exercise of the reader.
*/
library X2Y2Helper {

	/**
		This struct defines an ERC-721 item as a token address and a token ID.

		@param token The address of the ERC-721 item contract.
		@param tokenId The ID of the ERC-721 item.
	*/
	struct Pair721 {
		address token;
		uint256 tokenId;
	}

	/**
		This struct defines an ERC-1155 item as a token address, token ID, and 
		amount.

		@param token The address of the ERC-1155 item contract.
		@param tokenId The ID of the ERC-1155 item.
		@param amount The amount of the ERC-1155 item to transfer.
	*/
	struct Pair1155 {
		address token;
		uint256 tokenId;
		uint256 amount;
	}

	/**
		A helper function to replace particular masked values in the `_src` array.

		@param _src The array to replace elements within.
		@param _replacement The array of potential replacement elements.
		@param _mask A mask of indices correlating to truthy values which indicate 
			which elements in `_src` should be replaced with elements in 
			`_replacement`.
	*/
	function arrayReplace (
		bytes memory _src,
		bytes memory _replacement,
		bytes memory _mask
	) internal pure {
		for (uint256 i = 0; i < _src.length; i++) {
			if (_mask[i] != 0) {
				_src[i] = _replacement[i];
			}
		}
	}

	struct OrderItem {
		uint256 price;
		bytes data;
	}

	struct Order {
		uint256 salt;
		address user;
		uint256 network;
		uint256 intent;
		uint256 delegateType;
		uint256 deadline;
		address currency;
		bytes dataMask;
		OrderItem[] items;
		bytes32 r;
		bytes32 s;
		uint8 v;
		uint8 signVersion;
	}

	enum Operation {
		INVALID,
		COMPLETE_SELL_OFFER,
		COMPLETE_BUY_OFFER,
		CANCEL_OFFER,
		BID,
		COMPLETE_AUCTION,
		REFUND_AUCTION,
		REFUND_AUCTION_STUCK_ITEM
	}

	struct Fee {
		uint256 percentage;
		address to;
	}

	struct SettleDetail {
		Operation op;
		uint256 orderIdx;
		uint256 itemIdx;
		uint256 price;
		bytes32 itemHash;
		address executionDelegate;
		bytes dataReplacement;
		uint256 bidIncentivePct;
		uint256 aucMinIncrementPct;
		uint256 aucIncDurationSecs;
		Fee[] fees;
	}

	struct SettleShared {
		uint256 salt;
		uint256 deadline;
		uint256 amountToEth;
		uint256 amountToWeth;
		address user;
		bool canFail;
	}

	struct RunInput {
		Order[] orders;
		SettleDetail[] details;
		SettleShared shared;
		bytes32 r;
		bytes32 s;
		uint8 v;
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