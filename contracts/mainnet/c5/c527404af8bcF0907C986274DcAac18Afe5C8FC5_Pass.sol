// SPDX-License-Identifier: MIT

/**
* Author: Lambdalf the White
*/

pragma solidity 0.8.10;

import "../EthereumContracts/contracts/interfaces/IERC1155.sol";
import "../EthereumContracts/contracts/interfaces/IERC1155Receiver.sol";
import "../EthereumContracts/contracts/interfaces/IERC1155MetadataURI.sol";
import "../EthereumContracts/contracts/utils/ERC2981Base.sol";
import "../EthereumContracts/contracts/utils/IOwnable.sol";
import "../EthereumContracts/contracts/utils/IPausable.sol";
import "../EthereumContracts/contracts/utils/ITradable.sol";
import "../EthereumContracts/contracts/utils/IWhitelistable_ECDSA.sol";
import "@openzeppelin/contracts/utils/Context.sol";

contract Pass is Context, IERC1155MetadataURI, IOwnable, IPausable, ITradable, IWhitelistable_ECDSA, ERC2981Base {
	// Error
	error IERC1155_APPROVE_CALLER();
	error IERC1155_ARRAY_LENGTH_MISMATCH();
	error IERC1155_CALLER_NOT_APPROVED( address from, address operator );
	error IERC1155_REJECTED();
	error IERC1155_INSUFFICIENT_BALANCE( address from, uint256 id, uint256 balance );
	error IERC1155_NON_ERC1155_RECEIVER();
	error IERC1155_NON_EXISTANT_TOKEN( uint256 id );
	error IERC1155_NULL_ADDRESS_TRANSFER();
	error NFT_ETHER_TRANSFER_FAIL( address recipient, uint256 amount );
	error NFT_INCORRECT_PRICE( uint256 amountSent, uint256 amountExpected );
	error NFT_INVALID_QTY();
	error NFT_MAX_BATCH( uint256 qty, uint256 maxBatch );
	error NFT_MAX_SUPPLY( uint256 qty, uint256 remainingSupply );
	error NFT_NO_ETHER_BALANCE();

	uint256 public constant MAX_BATCH = 10;
	uint256 public constant PASS_ID = 1;
	uint8 public constant CLAIM = 2;

	uint256 public publicPrice;
	uint256 public remainingSupply;
	string private _uri = "ipfs://QmXede8ghiap9hoppY2NVTFEXpshmcfPsDzxFE9ydVMXby";
	mapping( address => uint256 ) private _balances;
	mapping( address => mapping( address => bool ) ) private _operatorApprovals;

	constructor() {
		address _account_ = _msgSender();
		_initIOwnable( _account_ );
		_initERC2981Base( _account_, 500 );
		remainingSupply = 2000;
	}

	// **************************************
	// *****          MODIFIER          *****
	// **************************************
		/**
		* @dev Throws if sale state is not ``CLAIM``.
		*/
		modifier isClaim() {
			uint8 _currentState_ = getPauseState();
			if ( _currentState_ != CLAIM ) {
				revert IPausable_INCORRECT_STATE( _currentState_ );
			}
			_;
		}

		/**
		* @dev Ensures that `qty_` is higher than 0 and lesser than `remainingSupply`
		* 
		* @param qty_ : the amount to validate 
		*/
		modifier validateAmount( uint256 qty_ ) {
			if ( qty_ == 0 ) {
				revert NFT_INVALID_QTY();
			}
			if ( qty_ > remainingSupply ) {
				revert NFT_MAX_SUPPLY( qty_, remainingSupply );
			}
			_;
		}

		/**
		* @dev Ensures that `id_` is a valid series
		* 
		* @param id_ : the series id to validate 
		*/
		modifier isValidSeries( uint256 id_ ) {
			if ( id_ != PASS_ID ) {
				revert IERC1155_NON_EXISTANT_TOKEN( id_ );
			}
			_;
		}
	// **************************************

	// **************************************
	// *****          INTERNAL          *****
	// **************************************
		/**
		* @dev Internal function that checks if the receiver address is a smart contract able to handle batches of IERC1155 tokens.
		*/
		function _doSafeBatchTransferAcceptanceCheck( address operator_, address from_, address to_, uint256[] memory ids_, uint256[] memory amounts_, bytes memory data_ ) private {
			uint256 _size_;
			assembly {
				_size_ := extcodesize( to_ )
			}
			if ( _size_ > 0 ) {
				try IERC1155Receiver( to_ ).onERC1155BatchReceived( operator_, from_, ids_, amounts_, data_ ) returns ( bytes4 response ) {
					if ( response != IERC1155Receiver.onERC1155BatchReceived.selector ) {
						revert IERC1155_REJECTED();
					}
				}
				catch ( bytes memory reason ) {
					if ( reason.length == 0 ) {
						revert IERC1155_REJECTED();
					}
					else {
						assembly {
							revert( add( 32, reason ), mload( reason ) )
						}
					}
				}
			}
		}

		/**
		* @dev Internal function that checks if the receiver address is a smart contract able to handle IERC1155 tokens.
		*/
		function _doSafeTransferAcceptanceCheck( address operator_, address from_, address to_, uint256 id_, uint256 amount_, bytes memory data_ ) private {
			uint256 _size_;
			assembly {
				_size_ := extcodesize( to_ )
			}
			if ( _size_ > 0 ) {
				try IERC1155Receiver( to_ ).onERC1155Received( operator_, from_, id_, amount_, data_ ) returns ( bytes4 response ) {
					if ( response != IERC1155Receiver.onERC1155Received.selector ) {
						revert IERC1155_REJECTED();
					}
				}
				catch ( bytes memory reason ) {
					if ( reason.length == 0 ) {
						revert IERC1155_REJECTED();
					}
					else {
						assembly {
							revert( add( 32, reason ), mload( reason ) )
						}
					}
				}
			}
		}

		/**
		* @dev Internal function that checks if `operator_` is allowed to handle tokens on behalf of `owner_`
		*/
		function _isApprovedOrOwner( address owner_, address operator_ ) internal view returns ( bool ) {
			return owner_ == operator_ ||
						 isApprovedForAll( owner_, operator_ );
		}

		/**
		* @dev Internal function that mints `amount_` tokens from series `PASS_ID` into `account_`.
		*/
		function _mint( address account_, uint256 amount_ ) internal {
			unchecked {
				_balances[ account_ ] += amount_;
				remainingSupply -= amount_;
			}
			emit TransferSingle( account_, address( 0 ), account_, PASS_ID, amount_ );
		}
	// **************************************

	// **************************************
	// *****           PUBLIC           *****
	// **************************************
		/**
		* @notice Mints `qty_` amount of `PASS_ID` to the caller address.
		* 
		* @param qty_      Amount of tokens to mint
		* @param alloted_  Amount of tokens that caller is allowed to claim
		* @param proof_    Signature confirming that the caller is allowed to mint `alloeted_` number of tokens
		* 
		* Requirements:
		* 
		* - Contract state must be `CLAIM`
		* - Whitelist must be set 
		* - Caller must be allowed to mint `qty_` tokens
		*/
		function claimPass( uint256 qty_, uint256 alloted_, Proof memory proof_ ) external isClaim validateAmount( qty_ ) isWhitelisted( _msgSender(), CLAIM, alloted_, proof_, qty_ ) {
			address _account_ = _msgSender();
			_consumeWhitelist( _account_, CLAIM, qty_ );
			_mint( _account_, qty_ );
		}

		/**
		* @notice Mints `qty_` amount of `PASS_ID` to the caller address.
		* 
		* @param qty_  Amount of tokens to mint
		* 
		* Requirements:
		* 
		* - Contract state must be `OPEN`
		* - `qty_` must be lower than `MAX_BATCH`
		* - `qty_` must be lower or equal to `remainingSupply`
		* - Caller must send enough eth to pay for `qty_` tokens
		*/
		function mintPublic( uint256 qty_ ) external payable isOpen validateAmount( qty_ ) {
			if ( qty_ > MAX_BATCH ) {
				revert NFT_MAX_BATCH( qty_, MAX_BATCH );
			}

			uint256 _expected_ = qty_ * publicPrice;
			if ( _expected_ != msg.value ) {
				revert NFT_INCORRECT_PRICE( msg.value, _expected_ );
			}

			_mint( _msgSender(), qty_ );
		}

		/**
		* @notice Transfers `amounts_` amount(s) of `ids_` from the `from_` address to the `to_` address specified (with safety call).
		* 
		* @param from_     Source address
		* @param to_       Target address
		* @param ids_      IDs of each token type (order and length must match `amounts_` array)
		* @param amounts_  Transfer amounts per token type (order and length must match `ids_` array)
		* @param data_     Additional data with no specified format, MUST be sent unaltered in call to the `ERC1155TokenReceiver` hook(s) on `to_`
		* 
		* Requirements:
		* 
		* - Caller must be approved to manage the tokens being transferred out of the `from_` account (see "Approval" section of the standard).
		* - MUST revert if `to_` is the zero address.
		* - MUST revert if length of `ids_` is not the same as length of `amounts_`.
		* - MUST revert if any of the balance(s) of the holder(s) for token(s) in `ids_` is lower than the respective amount(s) in `amounts_` sent to the recipient.
		* - MUST revert on any other error.        
		* - MUST emit `TransferSingle` or `TransferBatch` event(s) such that all the balance changes are reflected (see "Safe Transfer Rules" section of the standard).
		* - Balance changes and events MUST follow the ordering of the arrays (_ids[0]/_amounts[0] before ids_[1]/_amounts[1], etc).
		* - After the above conditions for the transfer(s) in the batch are met, this function MUST check if `to_` is a smart contract (e.g. code size > 0). If so, it MUST call the relevant `ERC1155TokenReceiver` hook(s) on `to_` and act appropriately (see "Safe Transfer Rules" section of the standard).                      
		*/
		function safeBatchTransferFrom( address from_, address to_, uint256[] calldata ids_, uint256[] calldata amounts_, bytes calldata data_ ) external override {
			if ( to_ == address( 0 ) ) {
				revert IERC1155_NULL_ADDRESS_TRANSFER();
			}

			uint256 _len_ = ids_.length;
			if ( amounts_.length != _len_ ) {
				revert IERC1155_ARRAY_LENGTH_MISMATCH();
			}

			address _operator_ = _msgSender();
			if ( ! _isApprovedOrOwner( from_, _operator_ ) ) {
				revert IERC1155_CALLER_NOT_APPROVED( from_, _operator_ );
			}

			for ( uint256 i; i < _len_; ) {
				if ( ids_[ i ] != PASS_ID ) {
					revert IERC1155_NON_EXISTANT_TOKEN( ids_[ i ] );
				}
				uint256 _balance_ = _balances[ from_ ];
				if ( _balance_ < amounts_[ i ] ) {
					revert IERC1155_INSUFFICIENT_BALANCE( from_, PASS_ID, _balance_ );
				}
				unchecked {
					_balances[ from_ ] = _balance_ - amounts_[ i ];
				}
				_balances[ to_ ] += amounts_[ i ];
				unchecked {
					++i;
				}
			}
			emit TransferBatch( _operator_, from_, to_, ids_, amounts_ );

			_doSafeBatchTransferAcceptanceCheck( _operator_, from_, to_, ids_, amounts_, data_ );
		}

		/**
		* @notice Transfers `amount_` amount of an `id_` from the `from_` address to the `to_` address specified (with safety call).
		* 
		* @param from_    Source address
		* @param to_      Target address
		* @param id_      ID of the token type
		* @param amount_  Transfer amount
		* @param data_    Additional data with no specified format, MUST be sent unaltered in call to `onERC1155Received` on `to_`
		* 
		* Requirements:
		* 
		* - Caller must be approved to manage the tokens being transferred out of the `from_` account (see "Approval" section of the standard).
		* - MUST revert if `to_` is the zero address.
		* - MUST revert if balance of holder for token type `id_` is lower than the `amount_` sent.
		* - MUST revert on any other error.
		* - MUST emit the `TransferSingle` event to reflect the balance change (see "Safe Transfer Rules" section of the standard).
		* - After the above conditions are met, this function MUST check if `to_` is a smart contract (e.g. code size > 0). If so, it MUST call `onERC1155Received` on `to_` and act appropriately (see "Safe Transfer Rules" section of the standard).        
		*/
		function safeTransferFrom( address from_, address to_, uint256 id_, uint256 amount_, bytes calldata data_ ) external override isValidSeries( id_ ) {
			if ( to_ == address( 0 ) ) {
				revert IERC1155_NULL_ADDRESS_TRANSFER();
			}

			address _operator_ = _msgSender();
			if ( ! _isApprovedOrOwner( from_, _operator_ ) ) {
				revert IERC1155_CALLER_NOT_APPROVED( from_, _operator_ );
			}

			uint256 _balance_ = _balances[ from_ ];
			if ( _balance_ < amount_ ) {
				revert IERC1155_INSUFFICIENT_BALANCE( from_, id_, _balance_ );
			}
			unchecked {
				_balances[ from_ ] = _balance_ - amount_;
			}
			_balances[ to_ ] += amount_;
			emit TransferSingle( _operator_, from_, to_, id_, amount_ );

			_doSafeTransferAcceptanceCheck( _operator_, from_, to_, id_, amount_, data_ );
		}

		/**
		* @notice Enable or disable approval for a third party ("operator") to manage all of the caller's tokens.
		* 
		* @param operator_  Address to add to the set of authorized operators
		* @param approved_  True if the operator is approved, false to revoke approval
		* 
		* Requirements:
		* 
		* - MUST emit the ApprovalForAll event on success.
		*/
		function setApprovalForAll( address operator_, bool approved_ ) external override {
			address _tokenOwner_ = _msgSender();
			if ( _tokenOwner_ == operator_ ) {
				revert IERC1155_APPROVE_CALLER();
			}

			_operatorApprovals[ _tokenOwner_ ][ operator_ ] = approved_;
			emit ApprovalForAll( _tokenOwner_, operator_, approved_ );
		}
	// **************************************

	// **************************************
	// *****       CONTRACT OWNER       *****
	// **************************************
		/**
		* @notice Adds a proxy registry to the list of accepted proxy registries.
		* 
		* @param proxyRegistryAddress_  the address of the proxy registry to be added
		* 
		* Requirements:
		* 
		* - Caller must be the contract owner.
		*/
		function addProxyRegistry( address proxyRegistryAddress_ ) external onlyOwner {
			_addProxyRegistry( proxyRegistryAddress_ );
		}

		/**
		* @notice Removes a proxy registry from the list of accepted proxy registries.
		* 
		* @param proxyRegistryAddress_  the address of the proxy registry to be removed
		* 
		* Requirements:
		* 
		* - Caller must be the contract owner.
		*/
		function removeProxyRegistry( address proxyRegistryAddress_ ) external onlyOwner {
			_removeProxyRegistry( proxyRegistryAddress_ );
		}

		/**
		* @notice Sets the contract state to `newState_`.
		* 
		* @param newState_  the new sale state
		* 
		* Requirements:
		* 
		* - Caller must be the contract owner.
		*/
		function setPauseState( uint8 newState_ ) external onlyOwner {
			_setPauseState( newState_ );
		}

		/**
		* @notice Updates the royalty recipient and rate.
		* 
		* @param royaltyRecipient_  the new recipient of the royalties
		* @param royaltyRate_       the new royalty rate
		* 
		* Requirements:
		* 
		* - Caller must be the contract owner
		* - `royaltyRate_` must be between 0 and 10,000
		*/
		function setRoyaltyInfo( address royaltyRecipient_, uint256 royaltyRate_ ) external onlyOwner {
			_setRoyaltyInfo( royaltyRecipient_, royaltyRate_ );
		}

		/**
		* @notice Sets the public price of the tokens.
		* 
		* @param price_  The new public price of the tokens
		*/
		function setPublicPrice( uint256 price_ ) external onlyOwner {
			publicPrice = price_;
		}

		/**
		* @notice Sets the uri of the tokens.
		* 
		* @param uri_  The new uri of the tokens
		*/
		function setURI( string memory uri_ ) external onlyOwner {
			_uri = uri_;
			emit URI( uri_, PASS_ID );
		}

		/**
		* @notice Sets the whitelist signer.
		* 
		* @param adminSigner_  The address signing the whitelist permissions
		*/
		function setWhitelist( address adminSigner_ ) public onlyOwner {
			_setWhitelist( adminSigner_ );
		}

		/**
		* @notice Withdraws all the money stored in the contract and sends it to the caller.
		* 
		* Requirements:
		* 
		* - Caller must be the contract owner.
		* - Contract must have a positive balance.
		*/
		function withdraw() public onlyOwner {
			uint256 _balance_ = address( this ).balance;
			if ( _balance_ == 0 ) {
				revert NFT_NO_ETHER_BALANCE();
			}

			address _recipient_ = payable( _msgSender() );
			( bool _success_, ) = _recipient_.call{ value: _balance_ }( "" );
			if ( ! _success_ ) {
				revert NFT_ETHER_TRANSFER_FAIL( _recipient_, _balance_ );
			}
		}
	// **************************************

	// **************************************
	// *****            VIEW            *****
	// **************************************
		/**
		* @notice Get the balance of an account's tokens.
		* 
		* @param owner_  The address of the token holder
		* @param id_     ID of the token type
		* @return        The owner_'s balance of the token type requested
		*/
		function balanceOf( address owner_, uint256 id_ ) public view override isValidSeries( id_ ) returns ( uint256 ) {
			return _balances[ owner_ ];
		}

		/**
		* @notice Get the balance of multiple account/token pairs
		* 
		* @param owners_  The addresses of the token holders
		* @param ids_     ID of the token types
		* @return         The owners_' balance of the token types requested (i.e. balance for each (owner, id) pair)
		*/
		function balanceOfBatch( address[] calldata owners_, uint256[] calldata ids_ ) public view override returns ( uint256[] memory ) {
			uint256 _len_ = owners_.length;
			if ( _len_ != ids_.length ) {
				revert IERC1155_ARRAY_LENGTH_MISMATCH();
			}

			uint256[] memory _balances_ = new uint256[]( _len_ );
			while ( _len_ > 0 ) {
				unchecked {
					--_len_;
				}
				if ( ids_[ _len_ ] != PASS_ID ) {
					revert IERC1155_NON_EXISTANT_TOKEN( ids_[ _len_ ] );
				}

				_balances_[ _len_ ] = _balances[ owners_[ _len_ ] ];
			}

			return _balances_;
		}

		/**
		* @notice Queries the approval status of an operator for a given owner.
		* 
		* @param owner_     The owner of the tokens
		* @param operator_  Address of authorized operator
		* @return           True if the operator is approved, false if not
		*/
		function isApprovedForAll( address owner_, address operator_ ) public view override returns ( bool ) {
			return _operatorApprovals[ owner_ ][ operator_ ] ||
						 _isRegisteredProxy( owner_, operator_ );
		}

		/**
		* @notice Query if a contract implements an interface.
		* 
		* @dev Interface identification is specified in ERC-165. This function uses less than 30,000 gas.
		* @param interfaceID_  The interface identifier, as specified in ERC-165
		* @return 						 `true` if the contract implements `interfaceID` and `interfaceID` is not 0xffffffff, `false` otherwise
		*/
		function supportsInterface( bytes4 interfaceID_ ) public pure override returns ( bool ) {
			return interfaceID_ == type( IERC165 ).interfaceId ||
						 interfaceID_ == type( IERC1155 ).interfaceId ||
						 interfaceID_ == type( IERC1155MetadataURI ).interfaceId ||
						 interfaceID_ == type( IERC2981 ).interfaceId;
		}

		/**
		* @dev Returns the URI for token type `id`.
		*
		* If the `\{id\}` substring is present in the URI, it must be replaced by
		* clients with the actual token type ID.
		*/
		function uri( uint256 id_ ) external view isValidSeries( id_ ) returns ( string memory ) {
			return _uri;
		}
	// **************************************
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

/**
* Author: Lambdalf the White
* Edit  : Squeebo
*/

pragma solidity 0.8.10;

abstract contract IWhitelistable_ECDSA {
	// A constant encoded into the proof. To allow expandability of uses for the whitelist, it is kept constant instead of implemented as enum.
	uint8 public constant DEFAULT_WHITELIST = 1;

	// Errors
	error IWhitelistable_NOT_SET();
	error IWhitelistable_CONSUMED( address account );
	error IWhitelistable_FORBIDDEN( address account );

	struct Proof {
		bytes32 r;
		bytes32 s;
		uint8   v;
	}

	address private _adminSigner;
	mapping( uint8 => mapping ( address => uint256 ) ) private _consumed;

	modifier isWhitelisted( address account_, uint8 whitelistType_, uint256 alloted_, Proof memory proof_, uint256 qty_ ) {
		uint256 _allowed_ = checkWhitelistAllowance( account_, whitelistType_, alloted_, proof_ );

		if ( _allowed_ < qty_ ) {
			revert IWhitelistable_FORBIDDEN( account_ );
		}

		_;
	}

	/**
	* @dev Sets the pass to protect the whitelist.
	*/
	function _setWhitelist( address adminSigner_ ) internal virtual {
		_adminSigner = adminSigner_;
	}

	/**
	* @dev Returns the amount that `account_` is allowed to access from the whitelist.
	* 
	* Requirements:
	* 
	* - `_adminSigner` must be set.
	*/
	function checkWhitelistAllowance( address account_, uint8 whitelistType_, uint256 alloted_, Proof memory proof_ ) public view returns ( uint256 ) {
		if ( _adminSigner == address( 0 ) ) {
			revert IWhitelistable_NOT_SET();
		}

		if ( _consumed[ whitelistType_ ][ account_ ] >= alloted_ ) {
			revert IWhitelistable_CONSUMED( account_ );
		}

		bytes32 _digest_ = keccak256( abi.encode( whitelistType_, alloted_, account_ ) );
		if ( ! _validateProof( _digest_, proof_ ) ) {
			revert IWhitelistable_FORBIDDEN( account_ );
		}

		return alloted_ - _consumed[ whitelistType_ ][ account_ ];
	}

	function _validateProof( bytes32 digest_, Proof memory proof_ ) private view returns ( bool ) {
		address _signer_ = ecrecover( digest_, proof_.v, proof_.r, proof_.s );
		return _signer_ == _adminSigner;
	}

	/**
	* @dev Consumes `amount_` pass passes from `account_`.
	* 
	* Note: Before calling this function, eligibility should be checked through {IWhitelistable-checkWhitelistAllowance}.
	*/
	function _consumeWhitelist( address account_, uint8 whitelistType_, uint256 qty_ ) internal {
		unchecked {
			_consumed[ whitelistType_ ][ account_ ] += qty_;
		}
	}
}

// SPDX-License-Identifier: MIT

/**
* Author: Lambdalf the White
*/

pragma solidity 0.8.10;

contract OwnableDelegateProxy {}

contract ProxyRegistry {
	mapping( address => OwnableDelegateProxy ) public proxies;
}

abstract contract ITradable {
	// OpenSea proxy registry address
	address[] public proxyRegistries;

	/**
	* @dev Internal function that adds a proxy registry to the list of accepted proxy registries.
	*/
	function _addProxyRegistry( address proxyRegistryAddress_ ) internal {
		uint256 _index_ = proxyRegistries.length;
		while ( _index_ > 0 ) {
			unchecked {
				_index_ --;
			}
			if ( proxyRegistries[ _index_ ] == proxyRegistryAddress_ ) {
				return;
			}
		}
		proxyRegistries.push( proxyRegistryAddress_ );
	}

	/**
	* @dev Internal function that removes a proxy registry from the list of accepted proxy registries.
	*/
	function _removeProxyRegistry( address proxyRegistryAddress_ ) internal {
		uint256 _len_ = proxyRegistries.length;
		uint256 _index_ = _len_;
		while ( _index_ > 0 ) {
			unchecked {
				_index_ --;
			}
			if ( proxyRegistries[ _index_ ] == proxyRegistryAddress_ ) {
				if ( _index_ + 1 != _len_ ) {
					proxyRegistries[ _index_ ] = proxyRegistries[ _len_ - 1 ];
				}
				proxyRegistries.pop();
			}
			return;
		}
	}

	/**
	* @dev Checks if `operator_` is a registered proxy for `tokenOwner_`.
	* 
	* Note: Use this function to allow whitelisting of registered proxy.
	*/
	function _isRegisteredProxy( address tokenOwner_, address operator_ ) internal view returns ( bool ) {
		uint256 _index_ = proxyRegistries.length;
		while ( _index_ > 0 ) {
			unchecked {
				_index_ --;
			}
			ProxyRegistry _proxyRegistry_ = ProxyRegistry( proxyRegistries[ _index_ ] );
			if ( address( _proxyRegistry_.proxies( tokenOwner_ ) ) == operator_ ) {
				return true;
			}
		}
		return false;
	}
}

// SPDX-License-Identifier: MIT

/**
* Author: Lambdalf the White
*/

pragma solidity 0.8.10;

abstract contract IPausable {
	// Enum to represent the sale state, defaults to ``CLOSED``.
	uint8 constant CLOSED = 0;
	uint8 constant OPEN   = 1;

	// Errors
	error IPausable_INCORRECT_STATE( uint8 currentState );
	error IPausable_INVALID_STATE( uint8 newState );

	// The current state of the contract
	uint8 private _contractState;

	/**
	* @dev Emitted when the sale state changes
	*/
	event ContractStateChanged( uint8 indexed previousState, uint8 indexed newState );

	/**
	* @dev Internal function setting the contract state to `newState_`.
	* 
	* Note: Contract state can have one of 2 values by default, ``CLOSED`` or ``OPEN``.
	* 			To maintain extendability, the 2 available states are kept as uint8 instead of enum.
	* 			As a result, it is possible to set the state to an incorrect value.
	* 			To avoid issues, `newState_` should be validated before calling this function
	*/
	function _setPauseState( uint8 newState_ ) internal virtual {
		uint8 _previousState_ = _contractState;
		_contractState = newState_;
		emit ContractStateChanged( _previousState_, newState_ );
	}

	/**
	* @dev Internal function returning the contract state.
	*/
	function getPauseState() public virtual view returns ( uint8 ) {
		return _contractState;
	}

	/**
	* @dev Throws if sale state is not ``CLOSED``.
	*/
	modifier isClosed {
		if ( _contractState != CLOSED ) {
			revert IPausable_INCORRECT_STATE( _contractState );
		}
		_;
	}

	/**
	* @dev Throws if sale state is ``CLOSED``.
	*/
	modifier isNotClosed {
		if ( _contractState == CLOSED ) {
			revert IPausable_INCORRECT_STATE( _contractState );
		}
		_;
	}

	/**
	* @dev Throws if sale state is not ``OPEN``.
	*/
	modifier isOpen {
		if ( _contractState != OPEN ) {
			revert IPausable_INCORRECT_STATE( _contractState );
		}
		_;
	}

	/**
	* @dev Throws if sale state is ``OPEN``.
	*/
	modifier isNotOpen {
		if ( _contractState == OPEN ) {
			revert IPausable_INCORRECT_STATE( _contractState );
		}
		_;
	}
}

// SPDX-License-Identifier: MIT

/**
* Author: Lambdalf the White
*/

pragma solidity 0.8.10;

import "@openzeppelin/contracts/utils/Context.sol";

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
abstract contract IOwnable is Context {
	// Errors
	error IOwnable_NOT_OWNER( address operator );

	// The owner of the contract
	address private _owner;

	/**
	* @dev Emitted when contract ownership changes.
	*/
	event OwnershipTransferred( address indexed previousOwner, address indexed newOwner );

	/**
	* @dev Initializes the contract setting the deployer as the initial owner.
	*/
	function _initIOwnable( address owner_ ) internal {
		_owner = owner_;
	}

	/**
	* @dev Returns the address of the current owner.
	*/
	function owner() public view virtual returns ( address ) {
		return _owner;
	}

	/**
	* @dev Throws if called by any account other than the owner.
	*/
	modifier onlyOwner() {
		address _sender_ = _msgSender();
		if ( owner() != _sender_ ) {
			revert IOwnable_NOT_OWNER( _sender_ );
		}
		_;
	}

	/**
	* @dev Transfers ownership of the contract to a new account (`newOwner`).
	* Can only be called by the current owner.
	*/
	function transferOwnership( address newOwner_ ) public virtual onlyOwner {
		address _oldOwner_ = _owner;
		_owner = newOwner_;
		emit OwnershipTransferred( _oldOwner_, newOwner_ );
	}
}

// SPDX-License-Identifier: MIT

/**
* Author: Lambdalf the White
*/

pragma solidity 0.8.10;

import "../interfaces/IERC2981.sol";
import "../interfaces/IERC165.sol";

abstract contract ERC2981Base is IERC165, IERC2981 {
	// Errors
	error IERC2981_INVALID_ROYALTIES( uint256 royaltyRate, uint256 royaltyBase );

	// Royalty rate is stored out of 10,000 instead of a percentage to allow for
	// up to two digits below the unit such as 2.5% or 1.25%.
	uint private constant ROYALTY_BASE = 10000;

	// Represents the percentage of royalties on each sale on secondary markets.
	// Set to 0 to have no royalties.
	uint256 private _royaltyRate;

	// Address of the recipient of the royalties.
	address private _royaltyRecipient;

	function _initERC2981Base( address royaltyRecipient_, uint256 royaltyRate_ ) internal {
		_setRoyaltyInfo( royaltyRecipient_, royaltyRate_ );
	}

	/**
	* @dev See {IERC2981-royaltyInfo}.
	* 
	* Note: This function should be overriden to revert on a query for non existent token.
	*/
	function royaltyInfo( uint256, uint256 salePrice_ ) public view virtual override returns ( address, uint256 ) {
		if ( salePrice_ == 0 || _royaltyRate == 0 ) {
			return ( _royaltyRecipient, 0 );
		}
		uint256 _royaltyAmount_ = _royaltyRate * salePrice_ / ROYALTY_BASE;
		return ( _royaltyRecipient, _royaltyAmount_ );
	}

	/**
	* @dev Sets the royalty rate to `royaltyRate_` and the royalty recipient to `royaltyRecipient_`.
	* 
	* Requirements: 
	* 
	* - `royaltyRate_` cannot be higher than `ROYALTY_BASE`;
	*/
	function _setRoyaltyInfo( address royaltyRecipient_, uint256 royaltyRate_ ) internal virtual {
		if ( royaltyRate_ > ROYALTY_BASE ) {
			revert IERC2981_INVALID_ROYALTIES( royaltyRate_, ROYALTY_BASE );
		}
		_royaltyRate      = royaltyRate_;
		_royaltyRecipient = royaltyRecipient_;
	}

	/**
	* @dev See {IERC165-supportsInterface}.
	*/
	function supportsInterface( bytes4 interfaceId_ ) public view virtual override returns ( bool ) {
		return 
			interfaceId_ == type( IERC2981 ).interfaceId ||
			interfaceId_ == type( IERC165 ).interfaceId;
	}
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (token/ERC1155/extensions/IERC1155MetadataURI.sol)

pragma solidity 0.8.10;

import "./IERC1155.sol";

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
// OpenZeppelin Contracts v4.4.1 (token/ERC1155/IERC1155Receiver.sol)

pragma solidity 0.8.10;

/**
 * @dev _Available since v3.1._
 */
interface IERC1155Receiver {
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
    ) external returns (bytes4);

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
    ) external returns (bytes4);
}

// SPDX-License-Identifier: MIT

/**
* Author: Lambdalf the White
*/

pragma solidity 0.8.10;

import "./IERC165.sol";

/**
* @title ERC-1155 Multi Token Standard
* @dev See https://eips.ethereum.org/EIPS/eip-1155
* Note: The ERC-165 identifier for this interface is 0xd9b67a26.
*/
interface IERC1155 /* is IERC165 */ {
	/**
	* @dev Either `TransferSingle` or `TransferBatch` MUST emit when tokens are transferred, including zero value transfers as well as minting or burning (see "Safe Transfer Rules" section of the standard).
	* The `operator` argument MUST be the address of an account/contract that is approved to make the transfer (SHOULD be msg.sender).
	* The `from` argument MUST be the address of the holder whose balance is decreased.
	* The `to` argument MUST be the address of the recipient whose balance is increased.
	* The `id` argument MUST be the token type being transferred.
	* The `value` argument MUST be the number of tokens the holder balance is decreased by and match what the recipient balance is increased by.
	* When minting/creating tokens, the `from` argument MUST be set to `0x0` (i.e. zero address).
	* When burning/destroying tokens, the `to` argument MUST be set to `0x0` (i.e. zero address).        
	*/
	event TransferSingle(address indexed operator, address indexed from, address indexed to, uint256 id, uint256 value);

	/**
	* @dev Either `TransferSingle` or `TransferBatch` MUST emit when tokens are transferred, including zero value transfers as well as minting or burning (see "Safe Transfer Rules" section of the standard).      
	* The `operator` argument MUST be the address of an account/contract that is approved to make the transfer (SHOULD be msg.sender).
	* The `from` argument MUST be the address of the holder whose balance is decreased.
	* The `to` argument MUST be the address of the recipient whose balance is increased.
	* The `ids` argument MUST be the list of tokens being transferred.
	* The `values` argument MUST be the list of number of tokens (matching the list and order of tokens specified in ids) the holder balance is decreased by and match what the recipient balance is increased by.
	* When minting/creating tokens, the `from` argument MUST be set to `0x0` (i.e. zero address).
	* When burning/destroying tokens, the `to` argument MUST be set to `0x0` (i.e. zero address).                
	*/
	event TransferBatch(address indexed operator, address indexed from, address indexed to, uint256[] ids, uint256[] values);

	/**
	* @dev MUST emit when approval for a second party/operator address to manage all tokens for an owner address is enabled or disabled (absence of an event assumes disabled).        
	*/
	event ApprovalForAll(address indexed owner, address indexed operator, bool approved);

	/**
	* @dev MUST emit when the URI is updated for a token ID.
	* URIs are defined in RFC 3986.
	* The URI MUST point to a JSON file that conforms to the "ERC-1155 Metadata URI JSON Schema".
	*/
	event URI(string value, uint256 indexed id);

	/**
	* @notice Transfers `value` amount of an `id` from the `from` address to the `to` address specified (with safety call).
	* @dev Caller must be approved to manage the tokens being transferred out of the `from` account (see "Approval" section of the standard).
	* MUST revert if `to` is the zero address.
	* MUST revert if balance of holder for token `id` is lower than the `value` sent.
	* MUST revert on any other error.
	* MUST emit the `TransferSingle` event to reflect the balance change (see "Safe Transfer Rules" section of the standard).
	* After the above conditions are met, this function MUST check if `to` is a smart contract (e.g. code size > 0). If so, it MUST call `onERC1155Received` on `to` and act appropriately (see "Safe Transfer Rules" section of the standard).        
	* @param from    Source address
	* @param to      Target address
	* @param id      ID of the token type
	* @param value   Transfer amount
	* @param data    Additional data with no specified format, MUST be sent unaltered in call to `onERC1155Received` on `to`
	*/
	function safeTransferFrom(address from, address to, uint256 id, uint256 value, bytes calldata data) external;

	/**
	* @notice Transfers `values` amount(s) of `ids` from the `from` address to the `to` address specified (with safety call).
	* @dev Caller must be approved to manage the tokens being transferred out of the `from` account (see "Approval" section of the standard).
	* MUST revert if `to` is the zero address.
	* MUST revert if length of `ids` is not the same as length of `values`.
	* MUST revert if any of the balance(s) of the holder(s) for token(s) in `ids` is lower than the respective amount(s) in `values` sent to the recipient.
	* MUST revert on any other error.        
	* MUST emit `TransferSingle` or `TransferBatch` event(s) such that all the balance changes are reflected (see "Safe Transfer Rules" section of the standard).
	* Balance changes and events MUST follow the ordering of the arrays (_ids[0]/_values[0] before ids[1]/_values[1], etc).
	* After the above conditions for the transfer(s) in the batch are met, this function MUST check if `to` is a smart contract (e.g. code size > 0). If so, it MUST call the relevant `ERC1155TokenReceiver` hook(s) on `to` and act appropriately (see "Safe Transfer Rules" section of the standard).                      
	* @param from    Source address
	* @param to      Target address
	* @param ids     IDs of each token type (order and length must match values array)
	* @param values  Transfer amounts per token type (order and length must match ids array)
	* @param data    Additional data with no specified format, MUST be sent unaltered in call to the `ERC1155TokenReceiver` hook(s) on `to`
	*/
	function safeBatchTransferFrom(address from, address to, uint256[] calldata ids, uint256[] calldata values, bytes calldata data) external;

	/**
	* @notice Get the balance of an account's tokens.
	* @param owner  The address of the token holder
	* @param id     ID of the token
	* @return       The owner's balance of the token type requested
	*/
	function balanceOf(address owner, uint256 id) external view returns (uint256);

	/**
	* @notice Get the balance of multiple account/token pairs
	* @param owners The addresses of the token holders
	* @param ids    ID of the tokens
	* @return       The owner's balance of the token types requested (i.e. balance for each (owner, id) pair)
	*/
	function balanceOfBatch(address[] calldata owners, uint256[] calldata ids) external view returns (uint256[] memory);

	/**
	* @notice Enable or disable approval for a third party ("operator") to manage all of the caller's tokens.
	* @dev MUST emit the ApprovalForAll event on success.
	* @param operator  Address to add to the set of authorized operators
	* @param approved  True if the operator is approved, false to revoke approval
	*/
	function setApprovalForAll(address operator, bool approved) external;

	/**
	* @notice Queries the approval status of an operator for a given owner.
	* @param owner     The owner of the tokens
	* @param operator  Address of authorized operator
	* @return          True if the operator is approved, false if not
	*/
	function isApprovedForAll(address owner, address operator) external view returns (bool);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/introspection/IERC165.sol)

pragma solidity 0.8.10;

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
pragma solidity 0.8.10;

interface IERC2981 {
  /**
  * @dev ERC165 bytes to add to interface array - set in parent contract
  * implementing this standard
  *
  * bytes4(keccak256("royaltyInfo(uint256,uint256)")) == 0x2a55205a
  * bytes4 private constant _INTERFACE_ID_ERC2981 = 0x2a55205a;
  * _registerInterface(_INTERFACE_ID_ERC2981);
  *
  * @notice Called with the sale price to determine how much royalty
  *           is owed and to whom.
  * @param _tokenId - the NFT asset queried for royalty information
  * @param _salePrice - the sale price of the NFT asset specified by _tokenId
  * @return receiver - address of who should be sent the royalty payment
  * @return royaltyAmount - the royalty payment amount for _salePrice
  */
  function royaltyInfo(uint256 _tokenId, uint256 _salePrice) external view returns (address receiver, uint256 royaltyAmount);
}