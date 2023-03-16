// SPDX-License-Identifier: AGPL-3.0
pragma solidity ^0.8.7;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC1155/IERC1155Receiver.sol";
import "@openzeppelin/contracts/token/ERC1155/extensions/IERC1155MetadataURI.sol";
import "@openzeppelin/contracts/utils/Address.sol";
import "@openzeppelin/contracts/utils/introspection/ERC165.sol";

/*
	It saves bytecode to revert on custom errors instead of using require
	statements. We are just declaring these errors for reverting with upon various
	conditions later in this contract.
*/
error CollectionURIHasBeenLocked ();
error ContractURIHasBeenLocked ();
error BalanceQueryForZeroAddress ();
error AccountsAndIdsLengthMismatched ();
error SettingApprovalStatusForSelf ();
error IdsAndAmountsLengthsMismatch ();
error TransferToZeroAddress ();
error CallerIsNotOwnerOrApproved ();
error InsufficientBalanceForTransfer ();
error MintToZeroAddress ();
error MintIdsAndAmountsLengthsMismatch ();
error DoNotHaveRigthToSetMetadata ();
error CanNotEditMetadateThatFrozen ();
error DoNotHaveRigthToLockURI ();
error ERC1155ReceiverRejectTokens ();
error NonERC1155Receiver ();
error NotAnAdmin ();
error TransferIsLocked ();
error BurnFromZeroAddress ();
error InsufficientBalanceForBurn ();
error BurnIdsAndAmountsLengthsMismatch ();

/**
	@custom:benediction DEVS BENEDICAT ET PROTEGAT CONTRACTVS MEAM
	@title  A lite ERC-1155 item creation contract.
	@author Tim Clancy <@_Enoch>
	@author Qazawat Zirak
	@author Rostislav Khlebnikov <@_catpic5buck>
	@author Nikita Elunin
	@author Mikhail Rozalenok
	@author Egor Dergunov

	This contract represents the NFTs within a single collection. It allows for a
	designated collection owner address to manage the creation of NFTs within this
	collection. The collection owner grants approval to or removes approval from
	other addresses governing their ability to mint NFTs from this collection.

	This contract is forked from the inherited OpenZeppelin dependency, and uses
	ideas from the original ERC-1155 reference implementation.

	January 15th, 2022.
*/
contract Tiny1155 is ERC165, Ownable, IERC1155MetadataURI {
	using Address for address;

	/// The name of this ERC-1155 contract.
	string public name;

	/** 
		The ERC-1155 URI for tracking item metadata, supporting {id} substitution. 
		For example: https://token-cdn-domain/{id}.json. See the ERC-1155 spec for
		more details: https://eips.ethereum.org/EIPS/eip-1155#metadata.
	*/
	string private metadataUri;

	/// A mapping from token IDs to address balance.
	mapping ( uint256 => mapping ( address => uint256 )) internal balances;

	/// A mappigng that keeps track of totals supplies per token ID.
	mapping ( uint256 => uint256 ) public circulatingSupply;

	/**
		This is a mapping from each address to per-address operator approvals. 
		Operators are those addresses that have been approved to transfer tokens on 
		behalf of the approver.
	*/
	mapping( address => mapping( address => bool )) public operatorApprovals;

	/// Whether or not the metadata URI has been locked to future changes.
	bool public uriLocked;

	/// A mapping to track administrative callers who have been set by the owner.
	mapping ( address => bool ) private administrators;

	/**
		Variable that contains info about locks for each item with id from 0 to 
		254. If bit with number of _id contains 1 then item transfers locked. If 
		255th bit is 1 then all transfers locked.
	*/
	bytes32 public transferLocks;

	/**
		An event that gets emitted when the metadata collection URI is changed.

		@param oldURI The old metadata URI.
		@param newURI The new metadata URI.
	*/
	event URIChanged (
		string indexed oldURI,
		string indexed newURI
	);

	/**
		An event that indicates we have set a permanent metadata URI for a token.

		@param operator Address that locked URI.
		@param value The value of the permanent metadata URI.
	*/
	event URILocked (
		address indexed operator,
		string value
	);

	/**
		An event that gets emitted when owner or admin called allTransferLocked
		function.
		
		@param time Time, when function was called.
		@param isLocked Bool value that represents is token transfers locked.
	*/
	event AllTransfersLocked (
		bool indexed isLocked,
		uint256 indexed time
	);

	/**
		An event that gets emitted when owner or admin called allTransferLocked 
		function.

		@param time Time, when function was called.
		@param isLocked Bool value that represents is token transfers locked.
		@param id Id of token for which transfers is locked.
	*/
	event TransfersLocked (
		bool indexed isLocked,
		uint256 indexed time,
		uint256 id
	);

	/**
		A modifier to see if a caller is an approved administrator.
	*/
	modifier onlyAdmin () {
		if (_msgSender() != owner() && !administrators[_msgSender()]) {
			revert NotAnAdmin();
		}
		_;
	}

	/** 
		Construct a new Tiny1155 item collection.

		@param _name The name to assign to this item collection contract.
		@param _metadataURI The metadata URI to perform later token ID substitution 
			with.
	*/
	constructor (
		string memory _name,
		string memory _metadataURI
	) {
		name = _name;
		metadataUri = _metadataURI;
	}

	/**
		EIP-165 function. Hardcoded value is INTERFACE_ERC1155 interface id.
	*/
	function supportsInterface (
		bytes4 _interfaceId
	)	public view virtual override(ERC165, IERC165) returns (bool) {
		return
			_interfaceId == type(IERC1155).interfaceId ||
			_interfaceId == type(IERC1155MetadataURI).interfaceId ||
			(super.supportsInterface(_interfaceId));
	}

	/**
		Returns the URI for token type `id`. If the `\{id\}` substring is present 
		in the URI, it must be replaced by clients with the actual token type ID.
	*/
	function uri (uint256) external view returns (string memory) {
		return metadataUri;
	}

	/**
		This function allows the original owner of the contract to add or remove
		other addresses as administrators. Administrators may perform mints and may
		lock token transfers.

		@param _newAdmin The new admin to update permissions for.
		@param _isAdmin Whether or not the new admin should be an admin.
	*/
	function setAdmin (
		address _newAdmin,
		bool _isAdmin
	) external onlyOwner {
		administrators[_newAdmin] = _isAdmin;
	}

	/**
		Allow the item collection owner or an approved manager to update the
		metadata URI of this collection. This implementation relies on a single URI
		for all items within the collection, and as such does not emit the standard
		URI event. Instead, we emit our own event to reflect changes in the URI.

		@param _uri The new URI to update to.
	*/
	function setURI(string calldata _uri) external virtual onlyOwner {
		if (uriLocked) {
			revert CollectionURIHasBeenLocked();
		}
		string memory oldURI = metadataUri;
		metadataUri = _uri;
		emit URIChanged(oldURI, _uri);
	}

		/**
		Retrieve the balance of a particular token `_id` for a particular address
		`_owner`.

		@param _owner The owner to check for this token balance.
		@param _id The ID of the token to check for a balance.
		@return The amount of token `_id` owned by `_owner`.
	*/
		function balanceOf(address _owner, uint256 _id)
				public
				view
				virtual
				returns (uint256)
		{
				if (_owner == address(0)) {
						revert BalanceQueryForZeroAddress();
				}
				return balances[_id][_owner];
		}

		/**
		Retrieve in a single call the balances of some mulitple particular token
		`_ids` held by corresponding `_owners`.

		@param _owners The owners to check for token balances.
		@param _ids The IDs of tokens to check for balances.
		@return the amount of each token owned by each owner.
	*/
		function balanceOfBatch(address[] calldata _owners, uint256[] calldata _ids)
				external
				view
				virtual
				returns (uint256[] memory)
		{
				if (_owners.length != _ids.length) {
						revert AccountsAndIdsLengthMismatched();
				}

				// Populate and return an array of balances.
				uint256[] memory batchBalances = new uint256[](_owners.length);
				for (uint256 i; i < _owners.length; ++i) {
						batchBalances[i] = balanceOf(_owners[i], _ids[i]);
				}
				return batchBalances;
		}

		/**
		This function returns true if `_operator` is approved to transfer items
		owned by `_owner`.

		@param _owner The owner of items to check for transfer ability.
		@param _operator The potential transferrer of `_owner`'s items.
		@return Whether `_operator` may transfer items owned by `_owner`.
	*/
		function isApprovedForAll(address _owner, address _operator)
				public
				view
				virtual
				returns (bool)
		{
				return operatorApprovals[_owner][_operator];
		}

		/**
		Enable or disable approval for a third party `_operator` address to manage
		(transfer or burn) all of the caller's tokens.

		@param _operator The address to grant management rights over all of the
			caller's tokens.
		@param _approved The status of the `_operator`'s approval for the caller.
	*/
		function setApprovalForAll(address _operator, bool _approved)
				external
				virtual
		{
				if (_msgSender() == _operator) {
						revert SettingApprovalStatusForSelf();
				}
				operatorApprovals[_msgSender()][_operator] = _approved;
				emit ApprovalForAll(_msgSender(), _operator, _approved);
		}

		/** 
				ERC-1155 dictates that any contract which wishes to receive ERC-1155 tokens
				must explicitly designate itself as such. This function checks for such
				designation to prevent undesirable token transfers.

				@param _operator The caller who triggers the token transfer.
				@param _from The address to transfer tokens from.
				@param _to The address to transfer tokens to.
				@param _id The specific token ID to transfer.
				@param _amount The amount of the specific `_id` to transfer.
				@param _data Additional call data to send with this transfer.
			*/
		function _doSafeTransferAcceptanceCheck(
				address _operator,
				address _from,
				address _to,
				uint256 _id,
				uint256 _amount,
				bytes calldata _data
		) private {
				if (_to.isContract()) {
						try
								IERC1155Receiver(_to).onERC1155Received(
										_operator,
										_from,
										_id,
										_amount,
										_data
								)
						returns (bytes4 response) {
								if (
										response != IERC1155Receiver(_to).onERC1155Received.selector
								) {
										revert ERC1155ReceiverRejectTokens();
								}
						} catch Error(string memory reason) {
								revert(reason);
						} catch {
								revert NonERC1155Receiver();
						}
				}
		}

		/**
		The batch equivalent of `_doSafeTransferAcceptanceCheck()`.

		@param _operator The caller who triggers the token transfer.
		@param _from The address to transfer tokens from.
		@param _to The address to transfer tokens to.
		@param _ids The specific token IDs to transfer.
		@param _amounts The amounts of the specific `_ids` to transfer.
		@param _data Additional call data to send with this transfer.
	*/
		function _doSafeBatchTransferAcceptanceCheck(
				address _operator,
				address _from,
				address _to,
				uint256[] calldata _ids,
				uint256[] calldata _amounts,
				bytes calldata _data
		) private {
				if (_to.isContract()) {
						try
								IERC1155Receiver(_to).onERC1155BatchReceived(
										_operator,
										_from,
										_ids,
										_amounts,
										_data
								)
						returns (bytes4 response) {
								if (
										response !=
										IERC1155Receiver(_to).onERC1155BatchReceived.selector
								) {
										revert ERC1155ReceiverRejectTokens();
								}
						} catch Error(string memory reason) {
								revert(reason);
						} catch {
								revert NonERC1155Receiver();
						}
				}
		}

		/**
		This function performs an unsafe transfer of amount `_amount` of token ID 
		`_id` from address `_from` to address `_to`. The transfer is considered 
		unsafe because it does not validate that the receiver can actually take 
		proper receipt of an ERC-1155 token.

		@param _from The address to transfer the token with ID of `_id` from.
		@param _to The address to transfer the token to.
		@param _id The ID of the token to transfer.
		@param _amount The amount of the specific `_id` to transfer.
	*/
		function transferFrom(
				address _from,
				address _to,
				uint256 _id,
				uint256 _amount
		) public {
				if (_to == address(0)) {
						revert TransferToZeroAddress();
				}
				if (_from != _msgSender() && !isApprovedForAll(_from, _msgSender())) {
						revert CallerIsNotOwnerOrApproved();
				}
				bytes32 _transferLocks = transferLocks;
				if (_transferLocks >> 255 == bytes32(uint256(1))) {
						revert TransferIsLocked();
				}
				if ((_transferLocks << (255 - _id)) >> 255 == bytes32(uint256(1))) {
						revert TransferIsLocked();
				}

				uint256 fromBalance = balances[_id][_from];
				if (fromBalance < _amount) {
						revert InsufficientBalanceForTransfer();
				}
				unchecked {
						balances[_id][_from] = fromBalance - _amount;
						balances[_id][_to] += _amount;
				}

				emit TransferSingle(_msgSender(), _from, _to, _id, _amount);
		}

		/**
		This function performs an unsafe batch transfer of `_amounts` amounts of 
		tokens IDs `_ids` from address `_from` to address `_to`. The transfer is 
		considered unsafe because it does not validate that the receiver can actually 
		take proper receipt of an ERC-1155 token.

		@param _from The address to transfer the token with ID of `_id` from.
		@param _to The address to transfer the token to.
		@param _ids The ID of the token to transfer.
		@param _amounts The amount of the specific `_id` to transfer.
	*/
		function batchTransferFrom(
				address _from,
				address _to,
				uint256[] calldata _ids,
				uint256[] calldata _amounts
		) public {
				if (_ids.length != _amounts.length) {
						revert IdsAndAmountsLengthsMismatch();
				}
				if (_to == address(0)) {
						revert TransferToZeroAddress();
				}
				if (_from != _msgSender() && !isApprovedForAll(_from, _msgSender())) {
						revert CallerIsNotOwnerOrApproved();
				}
				bytes32 _transferLocks = transferLocks;
				if (_transferLocks >> 255 == bytes32(uint256(1))) {
						revert TransferIsLocked();
				}

				// Validate transfer and perform all batch token sends.
				for (uint256 i; i < _ids.length; ++i) {
						// Update all specially-tracked balances.
						uint256 id = _ids[i];
						uint256 amount = _amounts[i];
						if ((_transferLocks << (255 - id)) >> 255 == bytes32(uint256(1))) {
								revert TransferIsLocked();
						}

						uint256 fromBalance = balances[id][_from];
						if (fromBalance < amount) {
								revert InsufficientBalanceForTransfer();
						}
						unchecked {
								balances[id][_from] = fromBalance - amount;
								balances[id][_to] += amount;
						}
				}

				emit TransferBatch(_msgSender(), _from, _to, _ids, _amounts);
		}

		/**
		Transfer on behalf of a caller or one of their authorized token managers
		items from one address to another.

		@param _from The address to transfer tokens from.
		@param _to The address to transfer tokens to.
		@param _id The specific token ID to transfer.
		@param _amount The amount of the specific `_id` to transfer.
		@param _data Additional call data to send with this transfer.
	*/
		function safeTransferFrom(
				address _from,
				address _to,
				uint256 _id,
				uint256 _amount,
				bytes calldata _data
		) external virtual {
				transferFrom(_from, _to, _id, _amount);
				_doSafeTransferAcceptanceCheck(
						_msgSender(),
						_from,
						_to,
						_id,
						_amount,
						_data
				);
		}

		/**
		Transfer on behalf of a caller or one of their authorized token managers
		items from one address to another.

		@param _from The address to transfer tokens from.
		@param _to The address to transfer tokens to.
		@param _ids The specific token IDs to transfer.
		@param _amounts The amounts of the specific `_ids` to transfer.
		@param _data Additional call data to send with this transfer.
	*/
		function safeBatchTransferFrom(
				address _from,
				address _to,
				uint256[] calldata _ids,
				uint256[] calldata _amounts,
				bytes calldata _data
		) external virtual {
				batchTransferFrom(_from, _to, _ids, _amounts);
				_doSafeBatchTransferAcceptanceCheck(
						msg.sender,
						_from,
						_to,
						_ids,
						_amounts,
						_data
				);
		}

		/**
		Mint a token into existence and send it to the `_recipient`
		address.

		@param _recipient The address to receive NFT.
		@param _id The item ID for the new item to create.
		@param _amount The amount of item ID to create.
	 */
		function mintSingle(
				address _recipient,
				uint256 _id,
				uint256 _amount
		) external virtual onlyAdmin {
				if (_recipient == address(0)) {
						revert MintToZeroAddress();
				}

				unchecked {
						circulatingSupply[_id] = circulatingSupply[_id] + _amount;
						balances[_id][_recipient] = balances[_id][_recipient] + _amount;
				}

				emit TransferSingle(_msgSender(), address(0), _recipient, _id, _amount);
		}

		/**
		Mint a batch of tokens into existence and send them to the `_recipient`
		address.

		@param _recipient The address to receive all NFTs.
		@param _ids The item IDs for the new items to create.
		@param _amounts The amount of each corresponding item ID to create.
	*/
		function mintBatch(
				address _recipient,
				uint256[] calldata _ids,
				uint256[] calldata _amounts
		) external virtual onlyAdmin {
				if (_recipient == address(0)) {
						revert MintToZeroAddress();
				}
				if (_ids.length != _amounts.length) {
						revert MintIdsAndAmountsLengthsMismatch();
				}

				// Loop through each of the batched IDs to update balances.
				for (uint256 i; i < _ids.length; ++i) {
						uint256 id = _ids[i];
						uint256 amount = _amounts[i];
						// Update storage of special balances and circulating values.
						unchecked {
								circulatingSupply[id] = circulatingSupply[id] + amount;
								balances[id][_recipient] = balances[id][_recipient] + amount;
						}
				}

				emit TransferBatch(
						_msgSender(),
						address(0),
						_recipient,
						_ids,
						_amounts
				);
		}

		/**
		This function allows an address to destroy some of its items.

		@param _from The address whose item is burning.
		@param _id The item ID to burn.
		@param _amount The amount of the corresponding item ID to burn.
	*/
		function burnSingle(
				address _from,
				uint256 _id,
				uint256 _amount
		) external virtual onlyAdmin {
				if (_from == address(0)) {
						revert BurnFromZeroAddress();
				}

				uint256 fromBalance = balances[_id][_from];
				if (fromBalance < _amount) {
						revert InsufficientBalanceForBurn();
				}
				unchecked {
						balances[_id][_from] = fromBalance - _amount;
						circulatingSupply[_id] -= _amount;
				}

				emit TransferSingle(_msgSender(), _from, address(0), _id, _amount);
		}

		/**
		This function allows an address to destroy multiple different items in a
		single call.

		@param _from The address whose items are burning.
		@param _ids The item IDs to burn.
		@param _amounts The amounts of the corresponding item IDs to burn.
	*/
		function burnBatch(
				address _from,
				uint256[] calldata _ids,
				uint256[] calldata _amounts
		) external virtual onlyAdmin {
				if (_from == address(0)) {
						revert BurnFromZeroAddress();
				}
				if (_ids.length != _amounts.length) {
						revert BurnIdsAndAmountsLengthsMismatch();
				}

				for (uint256 i; i < _ids.length; ++i) {
						uint256 id = _ids[i];
						uint256 amount = _amounts[i];

						uint256 fromBalance = balances[id][_from];
						if (fromBalance < amount) {
								revert InsufficientBalanceForBurn();
						}
						unchecked {
								balances[id][_from] = fromBalance - amount;
								circulatingSupply[id] -= amount;
						}
				}

				emit TransferBatch(_msgSender(), _from, address(0), _ids, _amounts);
		}

		/**
		Allow the item collection owner or an associated manager to forever lock the
		metadata URI on the entire collection to future changes.
	*/
		function lockURI() external onlyOwner {
				uriLocked = true;
				emit URILocked(msg.sender, metadataUri);
		}

		/**
		This function allows the owner to lock the transfer of all token IDs. This
		is designed to prevent whitelisted presale users from using the secondary
		market to undercut the auction before the sale has ended.

		@param _locked The status of the lock; true to lock, false to unlock.
	*/
		function lockAllTransfers(bool _locked) external onlyOwner {
				bytes32 mask = bytes32(uint256(1));
				mask <<= 255;

				if (_locked) {
						transferLocks |= mask;
				} else {
						mask = ~mask;
						transferLocks &= mask;
				}
				emit AllTransfersLocked(_locked, block.timestamp);
		}

		/**
		This function allows an administrative caller to lock the transfer of
		particular token IDs. This is designed for a non-escrow staking contract
		that comes later to lock a user's tokens while still letting them keep it in
		their wallet.

		@param _id The ID of the token to lock.
		@param _locked The status of the lock; true to lock, false to unlock.
	*/
		function lockTransfer(uint256 _id, bool _locked) external onlyAdmin {
				bytes32 mask = bytes32(uint256(1));
				mask <<= _id;

				if (_locked) {
						transferLocks |= mask;
				} else {
						mask = ~mask;
						transferLocks &= mask;
				}
				emit TransfersLocked(_locked, block.timestamp, _id);
		}
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
// OpenZeppelin Contracts (last updated v4.5.0) (token/ERC1155/IERC1155Receiver.sol)

pragma solidity ^0.8.0;

import "../../utils/introspection/IERC165.sol";

/**
 * @dev _Available since v3.1._
 */
interface IERC1155Receiver is IERC165 {
    /**
     * @dev Handles the receipt of a single ERC1155 token type. This function is
     * called at the end of a `safeTransferFrom` after the balance has been updated.
     *
     * NOTE: To accept the transfer, this must return
     * `bytes4(keccak256("onERC1155Received(address,address,uint256,uint256,bytes)"))`
     * (i.e. 0xf23a6e61, or its own function selector).
     *
     * @param operator The address which initiated the transfer (i.e. msg.sender)
     * @param from The address which previously owned the token
     * @param id The ID of the token being transferred
     * @param value The amount of tokens being transferred
     * @param data Additional data with no specified format
     * @return `bytes4(keccak256("onERC1155Received(address,address,uint256,uint256,bytes)"))` if transfer is allowed
     */
    function onERC1155Received(
        address operator,
        address from,
        uint256 id,
        uint256 value,
        bytes calldata data
    ) external returns (bytes4);

    /**
     * @dev Handles the receipt of a multiple ERC1155 token types. This function
     * is called at the end of a `safeBatchTransferFrom` after the balances have
     * been updated.
     *
     * NOTE: To accept the transfer(s), this must return
     * `bytes4(keccak256("onERC1155BatchReceived(address,address,uint256[],uint256[],bytes)"))`
     * (i.e. 0xbc197c81, or its own function selector).
     *
     * @param operator The address which initiated the batch transfer (i.e. msg.sender)
     * @param from The address which previously owned the token
     * @param ids An array containing ids of each token being transferred (order and length must match values array)
     * @param values An array containing amounts of each token being transferred (order and length must match ids array)
     * @param data Additional data with no specified format
     * @return `bytes4(keccak256("onERC1155BatchReceived(address,address,uint256[],uint256[],bytes)"))` if transfer is allowed
     */
    function onERC1155BatchReceived(
        address operator,
        address from,
        uint256[] calldata ids,
        uint256[] calldata values,
        bytes calldata data
    ) external returns (bytes4);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (token/ERC1155/extensions/IERC1155MetadataURI.sol)

pragma solidity ^0.8.0;

import "../IERC1155.sol";

/**
 * @dev Interface of the optional ERC1155MetadataExtension interface, as defined
 * in the https://eips.ethereum.org/EIPS/eip-1155#metadata-extensions[EIP].
 *
 * _Available since v3.1._
 */
interface IERC1155MetadataURI is IERC1155 {
    /**
     * @dev Returns the URI for token type `id`.
     *
     * If the `\{id\}` substring is present in the URI, it must be replaced by
     * clients with the actual token type ID.
     */
    function uri(uint256 id) external view returns (string memory);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.5.0) (utils/Address.sol)

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
// OpenZeppelin Contracts v4.4.1 (utils/introspection/ERC165.sol)

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