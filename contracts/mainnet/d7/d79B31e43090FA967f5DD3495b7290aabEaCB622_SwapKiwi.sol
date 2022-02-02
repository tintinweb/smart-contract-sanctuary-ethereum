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
    constructor () {
        address msgSender = _msgSender();
        _owner = msgSender;
        emit OwnershipTransferred(address(0), msgSender);
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
        emit OwnershipTransferred(_owner, address(0));
        _owner = address(0);
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        emit OwnershipTransferred(_owner, newOwner);
        _owner = newOwner;
    }
}

// SPDX-License-Identifier: MIT

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
    event TransferBatch(address indexed operator, address indexed from, address indexed to, uint256[] ids, uint256[] values);

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
    function balanceOfBatch(address[] calldata accounts, uint256[] calldata ids) external view returns (uint256[] memory);

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
    function safeTransferFrom(address from, address to, uint256 id, uint256 amount, bytes calldata data) external;

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
    function safeBatchTransferFrom(address from, address to, uint256[] calldata ids, uint256[] calldata amounts, bytes calldata data) external;
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "../../utils/introspection/IERC165.sol";

/**
 * _Available since v3.1._
 */
interface IERC1155Receiver is IERC165 {

    /**
        @dev Handles the receipt of a single ERC1155 token type. This function is
        called at the end of a `safeTransferFrom` after the balance has been updated.
        To accept the transfer, this must return
        `bytes4(keccak256("onERC1155Received(address,address,uint256,uint256,bytes)"))`
        (i.e. 0xf23a6e61, or its own function selector).
        @param operator The address which initiated the transfer (i.e. msg.sender)
        @param from The address which previously owned the token
        @param id The ID of the token being transferred
        @param value The amount of tokens being transferred
        @param data Additional data with no specified format
        @return `bytes4(keccak256("onERC1155Received(address,address,uint256,uint256,bytes)"))` if transfer is allowed
    */
    function onERC1155Received(
        address operator,
        address from,
        uint256 id,
        uint256 value,
        bytes calldata data
    )
        external
        returns(bytes4);

    /**
        @dev Handles the receipt of a multiple ERC1155 token types. This function
        is called at the end of a `safeBatchTransferFrom` after the balances have
        been updated. To accept the transfer(s), this must return
        `bytes4(keccak256("onERC1155BatchReceived(address,address,uint256[],uint256[],bytes)"))`
        (i.e. 0xbc197c81, or its own function selector).
        @param operator The address which initiated the batch transfer (i.e. msg.sender)
        @param from The address which previously owned the token
        @param ids An array containing ids of each token being transferred (order and length must match values array)
        @param values An array containing amounts of each token being transferred (order and length must match ids array)
        @param data Additional data with no specified format
        @return `bytes4(keccak256("onERC1155BatchReceived(address,address,uint256[],uint256[],bytes)"))` if transfer is allowed
    */
    function onERC1155BatchReceived(
        address operator,
        address from,
        uint256[] calldata ids,
        uint256[] calldata values,
        bytes calldata data
    )
        external
        returns(bytes4);
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "./ERC1155Receiver.sol";

/**
 * @dev _Available since v3.1._
 */
contract ERC1155Holder is ERC1155Receiver {
    function onERC1155Received(address, address, uint256, uint256, bytes memory) public virtual override returns (bytes4) {
        return this.onERC1155Received.selector;
    }

    function onERC1155BatchReceived(address, address, uint256[] memory, uint256[] memory, bytes memory) public virtual override returns (bytes4) {
        return this.onERC1155BatchReceived.selector;
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "../IERC1155Receiver.sol";
import "../../../utils/introspection/ERC165.sol";

/**
 * @dev _Available since v3.1._
 */
abstract contract ERC1155Receiver is ERC165, IERC1155Receiver {
    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId) public view virtual override(ERC165, IERC165) returns (bool) {
        return interfaceId == type(IERC1155Receiver).interfaceId
            || super.supportsInterface(interfaceId);
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
    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);

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
    function safeTransferFrom(address from, address to, uint256 tokenId) external;

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
    function transferFrom(address from, address to, uint256 tokenId) external;

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
    function safeTransferFrom(address from, address to, uint256 tokenId, bytes calldata data) external;
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/**
 * @title ERC721 token receiver interface
 * @dev Interface for any contract that wants to support safeTransfers
 * from ERC721 asset contracts.
 */
interface IERC721Receiver {
    /**
     * @dev Whenever an {IERC721} `tokenId` token is transferred to this contract via {IERC721-safeTransferFrom}
     * by `operator` from `from`, this function is called.
     *
     * It must return its Solidity selector to confirm the token transfer.
     * If any other value is returned or the interface is not implemented by the recipient, the transfer will be reverted.
     *
     * The selector can be obtained in Solidity with `IERC721.onERC721Received.selector`.
     */
    function onERC721Received(address operator, address from, uint256 tokenId, bytes calldata data) external returns (bytes4);
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "../IERC721Receiver.sol";

  /**
   * @dev Implementation of the {IERC721Receiver} interface.
   *
   * Accepts all token transfers.
   * Make sure the contract is able to use its token with {IERC721-safeTransferFrom}, {IERC721-approve} or {IERC721-setApprovalForAll}.
   */
contract ERC721Holder is IERC721Receiver {

    /**
     * @dev See {IERC721Receiver-onERC721Received}.
     *
     * Always returns `IERC721Receiver.onERC721Received.selector`.
     */
    function onERC721Received(address, address, uint256, bytes memory) public virtual override returns (bytes4) {
        return this.onERC721Received.selector;
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/*
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
        this; // silence state mutability warning without generating bytecode - see https://github.com/ethereum/solidity/issues/2691
        return msg.data;
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "./IERC165.sol";

/**
 * @dev Implementation of the {IERC165} interface.
 *
 * Contracts that want to implement ERC165 should inherit from this contract and override {supportsInterface} to check
 * for the additional interface id that will be supported. For example:
 *
 * ```solidity
 * function supportsInterface(bytes4 interfaceId) public view virtual override returns (bool) {
 *     return interfaceId == type(MyInterface).interfaceId || super.supportsInterface(interfaceId);
 * }
 * ```
 *
 * Alternatively, {ERC165Storage} provides an easier to use but more expensive implementation.
 */
abstract contract ERC165 is IERC165 {
    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId) public view virtual override returns (bool) {
        return interfaceId == type(IERC165).interfaceId;
    }
}

// SPDX-License-Identifier: MIT

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

// SPDX-License-Identifier: GPL-3.0

pragma solidity ^0.8.1;

import "@openzeppelin/contracts/token/ERC721/utils/ERC721Holder.sol";
import "@openzeppelin/contracts/token/ERC1155/utils/ERC1155Holder.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC1155/IERC1155.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

/**
* @title This is the contract which added erc1155 into the previous swap contract.
*/
contract SwapKiwi is Ownable, ERC721Holder, ERC1155Holder {

	uint64 private _swapsCounter;
	uint128 private _etherLocked;
	uint128 public fee;

	mapping (uint64 => Swap) private _swaps;

	struct Swap {
		address payable initiator;
		address[] initiatorNftAddresses;
		uint256[] initiatorNftIds;
		uint256[] initiatorNftAmounts;
		address payable secondUser;
		address[] secondUserNftAddresses;
		uint256[] secondUserNftIds;
		uint256[] secondUserNftAmounts;
		uint128 initiatorEtherValue;
		uint128 secondUserEtherValue;
	}

	event SwapExecuted(address indexed from, address indexed to, uint64 indexed swapId);
	event SwapCanceled(address indexed canceledBy, uint64 indexed swapId);
	event SwapProposed(
		address indexed from,
		address indexed to,
		uint64 indexed swapId,
		uint128 etherValue,
		address[] nftAddresses,
		uint256[] nftIds,
		uint256[] nftAmounts
	);
	event SwapInitiated(
		address indexed from,
		address indexed to,
		uint64 indexed swapId,
		uint128 etherValue,
		address[] nftAddresses,
		uint256[] nftIds,
		uint256[] nftAmounts
	);
	event AppFeeChanged(
		uint128 fee
	);

	modifier onlyInitiator(uint64 swapId) {
		require(msg.sender == _swaps[swapId].initiator,
			"SwapKiwi: caller is not swap initiator");
		_;
	}

	modifier requireSameLength(address[] memory nftAddresses, uint256[] memory nftIds, uint256[] memory nftAmounts) {
		require(nftAddresses.length == nftIds.length, "SwapKiwi: NFT and ID arrays have to be same length");
		require(nftAddresses.length == nftAmounts.length, "SwapKiwi: NFT and AMOUNT arrays have to be same length");
		_;
	}

	modifier chargeAppFee() {
		require(msg.value >= fee, "SwapKiwi: Sent ETH amount needs to be more or equal application fee");
		_;
	}

	constructor(uint128 initalAppFee, address contractOwnerAddress) {
		fee = initalAppFee;
		super.transferOwnership(contractOwnerAddress);
	}

	function setAppFee(uint128 newFee) external onlyOwner {
		fee = newFee;
		emit AppFeeChanged(newFee);
	}

	/**
	* @dev First user proposes a swap to the second user with the NFTs that he deposits and wants to trade.
	*      Proposed NFTs are transfered to the SwapKiwi contract and
	*      kept there until the swap is accepted or canceled/rejected.
	*
	* @param secondUser address of the user that the first user wants to trade NFTs with
	* @param nftAddresses array of NFT addressed that want to be traded
	* @param nftIds array of IDs belonging to NFTs that want to be traded
	* @param nftAmounts array of NFT amounts that want to be traded. If the amount is zero, that means 
	* the token is ERC721 token. Otherwise the token is ERC1155 token.
	*/
	function proposeSwap(
		address secondUser,
		address[] memory nftAddresses,
		uint256[] memory nftIds,
		uint256[] memory nftAmounts
	) external payable chargeAppFee requireSameLength(nftAddresses, nftIds, nftAmounts) {
		_swapsCounter += 1;

		safeMultipleTransfersFrom(
			msg.sender,
			address(this),
			nftAddresses,
			nftIds,
			nftAmounts
		);

		Swap storage swap = _swaps[_swapsCounter];
		swap.initiator = payable(msg.sender);
		swap.initiatorNftAddresses = nftAddresses;
		swap.initiatorNftIds = nftIds;
		swap.initiatorNftAmounts = nftAmounts;

		uint128 _fee = fee;

		if (msg.value > _fee) {
			swap.initiatorEtherValue = uint128(msg.value) - _fee;
			_etherLocked += swap.initiatorEtherValue;
		}
		swap.secondUser = payable(secondUser);

		emit SwapProposed(
			msg.sender,
			secondUser,
			_swapsCounter,
			swap.initiatorEtherValue,
			nftAddresses,
			nftIds,
			nftAmounts
		);
	}

	/**
	* @dev Second user accepts the swap (with proposed NFTs) from swap initiator and
	*      deposits his NFTs into the SwapKiwi contract.
	*      Callable only by second user that is invited by swap initiator.
	*
	* @param swapId ID of the swap that the second user is invited to participate in
	* @param nftAddresses array of NFT addressed that want to be traded
	* @param nftIds array of IDs belonging to NFTs that want to be traded
	* @param nftAmounts array of NFT amounts that want to be traded. If the amount is zero, that means 
	* the token is ERC721 token. Otherwise the token is ERC1155 token.
	*/
	function initiateSwap(
		uint64 swapId,
		address[] memory nftAddresses,
		uint256[] memory nftIds,
		uint256[] memory nftAmounts
	) external payable chargeAppFee requireSameLength(nftAddresses, nftIds, nftAmounts) {
		require(_swaps[swapId].secondUser == msg.sender, "SwapKiwi: caller is not swap participator");
		require(
			_swaps[swapId].secondUserEtherValue == 0 &&
			( _swaps[swapId].secondUserNftAddresses.length == 0 &&
			_swaps[swapId].secondUserNftIds.length == 0 &&
			_swaps[swapId].secondUserNftAmounts.length == 0
			), "SwapKiwi: swap already initiated"
		);

		safeMultipleTransfersFrom(
			msg.sender,
			address(this),
			nftAddresses,
			nftIds,
			nftAmounts
		);

		_swaps[swapId].secondUserNftAddresses = nftAddresses;
		_swaps[swapId].secondUserNftIds = nftIds;
		_swaps[swapId].secondUserNftAmounts = nftAmounts;

		uint128 _fee = fee;

		if (msg.value > _fee) {
			_swaps[swapId].secondUserEtherValue = uint128(msg.value) - _fee;
			_etherLocked += _swaps[swapId].secondUserEtherValue;
		}

		emit SwapInitiated(
			msg.sender,
			_swaps[swapId].initiator,
			swapId,
			_swaps[swapId].secondUserEtherValue,
			nftAddresses,
			nftIds,
			nftAmounts
		);
	}

	/**
	* @dev Swap initiator accepts the swap (NFTs proposed by the second user).
	*      Executeds the swap - transfers NFTs from SwapKiwi to the participating users.
	*      Callable only by swap initiator.
	*
	* @param swapId ID of the swap that the initator wants to execute
	*/
	function acceptSwap(uint64 swapId) external onlyInitiator(swapId) {
		require(
			(_swaps[swapId].secondUserNftAddresses.length != 0 || _swaps[swapId].secondUserEtherValue > 0) &&
			(_swaps[swapId].initiatorNftAddresses.length != 0 || _swaps[swapId].initiatorEtherValue > 0),
			"SwapKiwi: Can't accept swap, both participants didn't add NFTs"
		);

		// transfer NFTs from escrow to initiator
		safeMultipleTransfersFrom(
			address(this),
			_swaps[swapId].initiator,
			_swaps[swapId].secondUserNftAddresses,
			_swaps[swapId].secondUserNftIds,
			_swaps[swapId].secondUserNftAmounts
		);

		// transfer NFTs from escrow to second user
		safeMultipleTransfersFrom(
			address(this),
			_swaps[swapId].secondUser,
			_swaps[swapId].initiatorNftAddresses,
			_swaps[swapId].initiatorNftIds,
			_swaps[swapId].initiatorNftAmounts
		);

		if (_swaps[swapId].initiatorEtherValue != 0) {
			_etherLocked -= _swaps[swapId].initiatorEtherValue;
			uint128 amountToTransfer = _swaps[swapId].initiatorEtherValue;
			_swaps[swapId].initiatorEtherValue = 0;
			_swaps[swapId].secondUser.transfer(amountToTransfer);
		}
		if (_swaps[swapId].secondUserEtherValue != 0) {
			_etherLocked -= _swaps[swapId].secondUserEtherValue;
			uint128 amountToTransfer = _swaps[swapId].secondUserEtherValue;
			_swaps[swapId].secondUserEtherValue = 0;
			_swaps[swapId].initiator.transfer(amountToTransfer);
		}

		emit SwapExecuted(_swaps[swapId].initiator, _swaps[swapId].secondUser, swapId);

		delete _swaps[swapId];
	}

	/**
	* @dev Returns NFTs from SwapKiwi to swap initator.
	*      Callable only if second user hasn't yet added NFTs.
	*
	* @param swapId ID of the swap that the swap participants want to cancel
	*/
	function cancelSwap(uint64 swapId) external {
		require(
			_swaps[swapId].initiator == msg.sender || _swaps[swapId].secondUser == msg.sender,
			"SwapKiwi: Can't cancel swap, must be swap participant"
		);
		// return initiator NFTs
		safeMultipleTransfersFrom(
			address(this),
			_swaps[swapId].initiator,
			_swaps[swapId].initiatorNftAddresses,
			_swaps[swapId].initiatorNftIds,
			_swaps[swapId].initiatorNftAmounts
		);

		if(_swaps[swapId].secondUserNftAddresses.length != 0) {
			// return second user NFTs
			safeMultipleTransfersFrom(
				address(this),
				_swaps[swapId].secondUser,
				_swaps[swapId].secondUserNftAddresses,
				_swaps[swapId].secondUserNftIds,
				_swaps[swapId].secondUserNftAmounts
			);
		}

		if (_swaps[swapId].initiatorEtherValue != 0) {
			_etherLocked -= _swaps[swapId].initiatorEtherValue;
			uint128 amountToTransfer = _swaps[swapId].initiatorEtherValue;
			_swaps[swapId].initiatorEtherValue = 0;
			_swaps[swapId].initiator.transfer(amountToTransfer);
		}
		if (_swaps[swapId].secondUserEtherValue != 0) {
			_etherLocked -= _swaps[swapId].secondUserEtherValue;
			uint128 amountToTransfer = _swaps[swapId].secondUserEtherValue;
			_swaps[swapId].secondUserEtherValue = 0;
			_swaps[swapId].secondUser.transfer(amountToTransfer);
		}

		emit SwapCanceled(msg.sender, swapId);

		delete _swaps[swapId];
	}

	function safeMultipleTransfersFrom(
		address from,
		address to,
		address[] memory nftAddresses,
		uint256[] memory nftIds,
		uint256[] memory nftAmounts
	) internal virtual {
		for (uint256 i=0; i < nftIds.length; i++){
			safeTransferFrom(from, to, nftAddresses[i], nftIds[i], nftAmounts[i], "");
		}
	}

	function safeTransferFrom(
		address from,
		address to,
		address tokenAddress,
		uint256 tokenId,
		uint256 tokenAmount,
		bytes memory _data
	) internal virtual {
		if (tokenAmount == 0) {
			IERC721(tokenAddress).safeTransferFrom(from, to, tokenId, _data);
		} else {
			IERC1155(tokenAddress).safeTransferFrom(from, to, tokenId, tokenAmount, _data);
		}
		
	}

	function withdrawEther(address payable recipient) external onlyOwner {
		require(recipient != address(0), "SwapKiwi: transfer to the zero address");

		recipient.transfer((address(this).balance - _etherLocked));
	}
}