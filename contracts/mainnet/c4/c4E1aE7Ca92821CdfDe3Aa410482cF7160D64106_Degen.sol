// SPDX-License-Identifier: MIT

/**
* Author: Lambdalf the White
*/

pragma solidity 0.8.10;

import '../EthereumContracts/contracts/NFT/NFTFree.sol';
import '../EthereumContracts/contracts/interfaces/IERC721.sol';

abstract contract CCVault {
	function balanceOf( address tokenOwner ) public virtual view returns ( uint256 key ) {}
}

contract Degen is NFTFree {
	error NFT_FORBIDDEN( address account );
	error NFT_ALLOCATION_CONSUMED( address account );
	error NFT_MAX_ALLOCATION( address account, uint256 allocated );

	uint8   public constant PRIVATE_SALE      = 2;
	uint8   public constant PARTNER_SALE      = 3;

	uint256 public constant MINTS_PER_KEY     = 3;
	uint256 public constant MINTS_PER_PARTNER = 1;

	mapping( address => uint256 ) public privateMints;
	mapping( address => uint256 ) public partnerMints;

	CCVault private _vault;
	IERC721 private _tab;
	IERC721 private _fmc;

	constructor () {
		_initNFTFree (
			300,
			5,
			4000,
			1250,
			"GMers",
			"GMER",
			"https://collectorsclub.io/api/gmers/metadata?tokenId="
		);
	}

	/**
	* Ensures the contract state is PRIVATE_SALE or PARTNER_SALE
	*/
	modifier isPrivateOrPartnerSale {
		uint8 _currentState_ = getPauseState();
		if ( _currentState_ != PRIVATE_SALE && _currentState_ != PARTNER_SALE ) {
			revert IPausable_INCORRECT_STATE( _currentState_ );
		}

		_;
	}

	/**
	* Ensures the contract state is PARTNER_SALE
	*/
	modifier isPartnerSale {
		uint8 _currentState_ = getPauseState();
		if ( _currentState_ != PARTNER_SALE ) {
			revert IPausable_INCORRECT_STATE( _currentState_ );
		}

		_;
	}

	// **************************************
	// *****          INTERNAL          *****
	// **************************************
		/**
		* @dev Internal function returning whether `operator_` is allowed to manage tokens on behalf of `tokenOwner_`.
		* 
		* @param tokenOwner_ : address that owns tokens
		* @param operator_   : address that tries to manage tokens
		* 
		* @return bool whether `operator_` is allowed to manage the token
		*/
		function _isApprovedForAll( address tokenOwner_, address operator_ ) internal view virtual override(NFTFree) returns ( bool ) {
			return operator_ == address( _vault ) ||
						 super._isApprovedForAll( tokenOwner_, operator_ );
		}
	// **************************************

	// **************************************
	// *****           PUBLIC           *****
	// **************************************
		/**
		* Mints a single token during the PARTNER_SALE period.
		* 
		* Requirements:
		* - Contract state must be PARTNER_SALE
		* - Caller must own one of the PARTNER NFTs
		* - Caller must not have minted through this function before
		*/
		function mintPartner() public isPartnerSale {
			address _account_ = _msgSender();
			if ( partnerMints[ _account_ ] == MINTS_PER_PARTNER ) {
				revert NFT_ALLOCATION_CONSUMED( _account_ );
			}

			uint256 _remainingSupply_ = MAX_SUPPLY - _reserve - supplyMinted();
			if ( _remainingSupply_ < MINTS_PER_PARTNER ) {
				revert NFT_MAX_SUPPLY( MINTS_PER_PARTNER, _remainingSupply_ );
			}

			uint256 _allocated_;
			uint256 _tabOwned_ = _tab.balanceOf( _account_ );
			if ( _tabOwned_ > 0 ) {
				_allocated_ = MINTS_PER_PARTNER;
			}
			else {
				uint256 _fmcOwned_ = _fmc.balanceOf( _account_ );
				if ( _fmcOwned_ > 0 ) {
					_allocated_ = MINTS_PER_PARTNER;
				}
			}
			if ( _allocated_ < MINTS_PER_PARTNER ) {
				revert NFT_FORBIDDEN( _account_ );
			}

			unchecked {
				partnerMints[ _account_ ] = MINTS_PER_PARTNER;
			}

			_mint( _account_, MINTS_PER_PARTNER );
		}

		/**
		* Mints tokens for key stakers.
		* 
		* @param qty_ ~ type = uint256 : the number of tokens to mint 
		* 
		* Requirements:
		* - `qty_` must be greater than 0
		* - Contract state must be PARTNER_SALE or PRIVATE_SALE
		* - Caller must have enough keys staked (one key staked = 3 tokens)
		* - Caller must have enough remaining tokens allocated to mint `qty_` tokens
		*/
		function mintPrivate( uint256 qty_ ) public validateAmount( qty_ ) isPrivateOrPartnerSale {
			address _account_ = _msgSender();
			if ( privateMints[ _account_ ] == MINTS_PER_KEY ) {
				revert NFT_ALLOCATION_CONSUMED( _account_ );
			}

			uint256 _remainingSupply_ = MAX_SUPPLY - _reserve - supplyMinted();
			if ( _remainingSupply_ < qty_ ) {
				revert NFT_MAX_SUPPLY( qty_, _remainingSupply_ );
			}

			uint256 _keys_ = _vault.balanceOf( _account_ );
			uint256 _allocated_ = _keys_ * MINTS_PER_KEY;
			uint256 _claimed_ = privateMints[ _account_ ];
			if ( qty_ > _allocated_ - _claimed_ ) {
				revert NFT_MAX_ALLOCATION( _account_, _allocated_ );
			}

			unchecked {
				privateMints[ _account_ ] = _claimed_ + qty_;
			}

			_mint( _account_, qty_ );
		}
	// **************************************

	// **************************************
	// *****       CONTRACT OWNER       *****
	// **************************************
		/**
		* @dev Sets the vault contract address.
		*/
		function setVault( address vault_ ) public onlyOwner {
			_vault = CCVault( vault_ );
		}

		/**
		* @dev Sets the FMC contract address.
		*/
		function setFmc( address fmc_ ) public onlyOwner {
			_fmc = IERC721( fmc_ );
		}

		/**
		* @dev Sets the TAB contract address.
		*/
		function setTab( address tab_ ) public onlyOwner {
			_tab = IERC721( tab_ );
		}
	// **************************************
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (token/ERC721/IERC721.sol)

pragma solidity 0.8.10;

import "./IERC165.sol";

/**
* @dev Required interface of an ERC721 compliant contract.
*/
interface IERC721 is IERC165 {
  /**
  * @dev Emitted when `tokenId_` token is transferred from `from_` to `to_`.
  */
  event Transfer( address indexed from_, address indexed to_, uint256 indexed tokenId_ );

  /**
  * @dev Emitted when `owner_` enables `approved_` to manage the `tokenId_` token.
  */
  event Approval( address indexed owner_, address indexed approved_, uint256 indexed tokenId_ );

  /**
  * @dev Emitted when `owner_` enables or disables (`approved`) `operator_` to manage all of its assets.
  */
  event ApprovalForAll( address indexed owner_ , address indexed operator_ , bool approved_ );

  /**
  * @dev Gives permission to `to_` to transfer `tokenId_` token to another account.
  * The approval is cleared when the token is transferred.
  *
  * Only a single account can be approved at a time, so approving the zero address clears previous approvals.
  *
  * Requirements:
  *
  * - The caller must own the token or be an approved operator.
  * - `tokenId_` must exist.
  *
  * Emits an {Approval} event.
  */
  function approve( address to_, uint256 tokenId_ ) external;

  /**
  * @dev Safely transfers `tokenId_` token from `from_` to `to_`, checking first that contract recipients
  * are aware of the ERC721 protocol to prevent tokens from being forever locked.
  *
  * Requirements:
  *
  * - `from_` cannot be the zero address.
  * - `to_` cannot be the zero address.
  * - `tokenId_` token must exist and be owned by `from_`.
  * - If the caller is not `from_`, it must have been allowed to move this token by either {approve} or {setApprovalForAll}.
  * - If `to_` refers to a smart contract, it must implement {IERC721Receiver-onERC721Received}, which is called upon a safe transfer.
  *
  * Emits a {Transfer} event.
  */
  function safeTransferFrom( address from_, address to_, uint256 tokenI_d ) external;

  /**
  * @dev Safely transfers `tokenId_` token from `from_` to `to_`.
  *
  * Requirements:
  *
  * - `from_` cannot be the zero address.
  * - `to_` cannot be the zero address.
  * - `tokenId_` token must exist and be owned by `from_`.
  * - If the caller is not `from_`, it must be approved to move this token by either {approve} or {setApprovalForAll}.
  * - If `to_` refers to a smart contract, it must implement {IERC721Receiver-onERC721Received}, which is called upon a safe transfer.
  *
  * Emits a {Transfer} event.
  */
  function safeTransferFrom( address from_, address to_, uint256 tokenId_, bytes calldata data_ ) external;

  /**
  * @dev Approve or remove `operator_` as an operator for the caller.
  * Operators can call {transferFrom} or {safeTransferFrom} for any token owned by the caller.
  *
  * Requirements:
  *
  * - The `operator_` cannot be the caller.
  *
  * Emits an {ApprovalForAll} event.
  */
  function setApprovalForAll( address operator_, bool approved_ ) external;

  /**
  * @dev Transfers `tokenId_` token from `from_` to `to_`.
  *
  * WARNING: Usage of this method is discouraged, use {safeTransferFrom} whenever possible.
  *
  * Requirements:
  *
  * - `from_` cannot be the zero address.
  * - `to_` cannot be the zero address.
  * - `tokenId_` token must be owned by `from_`.
  * - If the caller is not `from_`, it must be approved to move this token by either {approve} or {setApprovalForAll}.
  *
  * Emits a {Transfer} event.
  */
  function transferFrom( address from_, address to_, uint256 tokenId_ ) external;

  /**
  * @dev Returns the number of tokens in `tokenOwner_`'s account.
  */
  function balanceOf( address tokenOwner_ ) external view returns ( uint256 balance );

  /**
  * @dev Returns the account approved for `tokenId_` token.
  *
  * Requirements:
  *
  * - `tokenId_` must exist.
  */
  function getApproved( uint256 tokenId_ ) external view returns ( address operator );

  /**
  * @dev Returns if the `operator_` is allowed to manage all of the assets of `tokenOwner_`.
  *
  * See {setApprovalForAll}
  */
  function isApprovedForAll( address tokenOwner_, address operator_ ) external view returns ( bool );

  /**
  * @dev Returns the owner of the `tokenId_` token.
  *
  * Requirements:
  *
  * - `tokenId_` must exist.
  */
  function ownerOf( uint256 tokenId_ ) external view returns ( address owner );
}

// SPDX-License-Identifier: MIT

/**
* Author: Lambdalf the White
*/

pragma solidity 0.8.10;

import '../tokens/ERC721/Reg_ERC721Batch.sol';
import '../utils/IOwnable.sol';
import '../utils/IPausable.sol';
import '../utils/ITradable.sol';
import '../utils/ERC2981Base.sol';

abstract contract NFTFree is Reg_ERC721Batch, IOwnable, IPausable, ITradable, ERC2981Base {
	// Errors 
	error NFT_ARRAY_LENGTH_MISMATCH( uint256 len1, uint256 len2 );
	error NFT_INVALID_QTY();
	error NFT_MAX_BATCH( uint256 qtyRequested, uint256 maxBatch );
	error NFT_MAX_RESERVE( uint256 qtyRequested, uint256 reserveLeft );
	error NFT_MAX_SUPPLY( uint256 qtyRequested, uint256 remainingSupply );

	uint256 private constant SHARE_BASE = 10000;
	uint256 public MAX_SUPPLY;
	uint256 public MAX_BATCH;
	uint256 internal _reserve;

	/**
	* @dev Ensures that `qty_` is higher than 0
	* 
	* @param qty_ : the amount to validate 
	*/
	modifier validateAmount( uint256 qty_ ) {
		if ( qty_ == 0 ) {
			revert NFT_INVALID_QTY();
		}

		_;
	}

	// **************************************
	// *****          INTERNAL          *****
	// **************************************
		/**
		* @dev Internal function to initialize the NFT contract.
		* 
		* @param reserve_       : total amount of reserved tokens for airdrops
		* @param maxBatch_      : maximum quantity of token that can be minted in one transaction
		* @param maxSupply_     : maximum number of tokens that can exist
		* @param royaltyRate_   : portion of the secondary sale that will be paid out to the collection, out of 10,000 total shares
		* @param name_          : name of the token
		* @param symbol_        : symbol representing the token
		* @param baseURI_       : baseURI for the tokens
		*/
		function _initNFTFree (
			uint256 reserve_,
			uint256 maxBatch_,
			uint256 maxSupply_,
			uint256 royaltyRate_,
			string memory name_,
			string memory symbol_,
			string memory baseURI_
		) internal {
			_initERC721Metadata( name_, symbol_, baseURI_ );
			_initIOwnable( _msgSender() );
			_initERC2981Base( _msgSender(), royaltyRate_ );
			MAX_SUPPLY     = maxSupply_;
			MAX_BATCH      = maxBatch_;
			_reserve       = reserve_;
		}

		/**
		* @dev Internal function returning whether `operator_` is allowed to manage tokens on behalf of `tokenOwner_`.
		* 
		* @param tokenOwner_ : address that owns tokens
		* @param operator_   : address that tries to manage tokens
		* 
		* @return bool whether `operator_` is allowed to manage the token
		*/
		function _isApprovedForAll( address tokenOwner_, address operator_ ) internal view virtual override(Reg_ERC721Batch) returns ( bool ) {
			return _isRegisteredProxy( tokenOwner_, operator_ ) ||
						 super._isApprovedForAll( tokenOwner_, operator_ );
		}

		/**
		* @dev Internal function returning whether `addr_` is a contract.
		* Note this function will be inacurate if `addr_` is a contract in deployment.
		* 
		* @param addr_ : address to be verified
		* 
		* @return bool whether `addr_` is a fully deployed contract
		*/
		function _isContract( address addr_ ) internal view returns ( bool ) {
			uint size;
			assembly {
				size := extcodesize( addr_ )
			}
			return size > 0;
		}
	// **************************************

	// **************************************
	// *****           PUBLIC           *****
	// **************************************
		/**
		* @dev Mints `qty_` tokens and transfers them to the caller.
		* 
		* Requirements:
		* 
		* - Sale state must be {SaleState.SALE}.
		* - There must be enough tokens left to mint outside of the reserve.
		* - Caller must send enough ether to pay for `qty_` tokens at public sale price.
		* 
		* @param qty_ : the amount of tokens to be minted
		*/
		function mintPublic( uint256 qty_ ) public validateAmount( qty_ ) isOpen {
			if ( qty_ > MAX_BATCH ) {
				revert NFT_MAX_BATCH( qty_, MAX_BATCH );
			}

			uint256 _remainingSupply_ = MAX_SUPPLY - _reserve - supplyMinted();
			if ( qty_ > _remainingSupply_ ) {
				revert NFT_MAX_SUPPLY( qty_, _remainingSupply_ );
			}

			_mint( _msgSender(), qty_ );
		}
	// **************************************

	// **************************************
	// *****       CONTRACT_OWNER       *****
	// **************************************
		/**
		* @dev See {ITradable-addProxyRegistry}.
		* 
		* @param proxyRegistryAddress_ : the address of the proxy registry to be added
		* 
		* Requirements:
		* 
		* - Caller must be the contract owner.
		*/
		function addProxyRegistry( address proxyRegistryAddress_ ) external onlyOwner {
			_addProxyRegistry( proxyRegistryAddress_ );
		}

		/**
		* @dev See {ITradable-removeProxyRegistry}.
		* 
		* @param proxyRegistryAddress_ : the address of the proxy registry to be removed
		* 
		* Requirements:
		* 
		* - Caller must be the contract owner.
		*/
		function removeProxyRegistry( address proxyRegistryAddress_ ) external onlyOwner {
			_removeProxyRegistry( proxyRegistryAddress_ );
		}

		/**
		* @dev Mints `amounts_` tokens and transfers them to `accounts_`.
		* 
		* @param accounts_ : the list of accounts that will receive airdropped tokens
		* @param amounts_  : the amount of tokens each account in `accounts_` will receive
		* 
		* Requirements:
		* 
		* - Caller must be the contract owner.
		* - `accounts_` and `amounts_` must have the same length.
		* - There must be enough tokens left in the reserve.
		*/
		function airdrop( address[] memory accounts_, uint256[] memory amounts_ ) public onlyOwner {
			uint256 _accountsLen_ = accounts_.length;
			uint256 _amountsLen_  = amounts_.length;
			if ( _accountsLen_ != _amountsLen_ ) {
				revert NFT_ARRAY_LENGTH_MISMATCH( _accountsLen_, _amountsLen_ );
			}

			uint256 _totalQty_;
			for ( uint256 i = _amountsLen_; i > 0; i -- ) {
				_totalQty_ += amounts_[ i - 1 ];
			}
			if ( _totalQty_ > _reserve ) {
				revert NFT_MAX_RESERVE( _totalQty_, _reserve );
			}
			unchecked {
				_reserve -= _totalQty_;
			}

			for ( uint256 i; i < _accountsLen_; i ++ ) {
				_mint( accounts_[ i ], amounts_[ i ] );
			}
		}

		/**
		* @dev Updates the baseURI for the tokens.
		* 
		* @param baseURI_ : the new baseURI for the tokens
		* 
		* Requirements:
		* 
		* - Caller must be the contract owner.
		*/
		function setBaseURI( string memory baseURI_ ) public onlyOwner {
			_setBaseURI( baseURI_ );
		}

		/**
		* @dev Updates the royalty recipient and rate.
		* 
		* @param royaltyRecipient_ : the new recipient of the royalties
		* @param royaltyRate_      : the new royalty rate
		* 
		* Requirements:
		* 
		* - Caller must be the contract owner
		* - `royaltyRate_` cannot be higher than 10,000
		*/
		function setRoyaltyInfo( address royaltyRecipient_, uint256 royaltyRate_ ) external onlyOwner {
			_setRoyaltyInfo( royaltyRecipient_, royaltyRate_ );
		}

		/**
		* @dev See {IPausable-setPauseState}.
		* 
		* @param newState_ : the new sale state
		* 
		* Requirements:
		* 
		* - Caller must be the contract owner.
		*/
		function setPauseState( uint8 newState_ ) external onlyOwner {
			_setPauseState( newState_ );
		}
	// **************************************

	// **************************************
	// *****            VIEW            *****
	// **************************************
		function supportsInterface( bytes4 interfaceId_ ) public view virtual override(Reg_ERC721Batch, ERC2981Base) returns ( bool ) {
			return ERC2981Base.supportsInterface( interfaceId_ ) ||
						 Reg_ERC721Batch.supportsInterface( interfaceId_ );
		}
	// **************************************
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
	address[] internal _proxyRegistries;

	/**
	* @dev Internal function that adds a proxy registry to the list of accepted proxy registries.
	*/
	function _addProxyRegistry( address proxyRegistryAddress_ ) internal {
		uint256 _index_ = _proxyRegistries.length;
		while ( _index_ > 0 ) {
			unchecked {
				_index_ --;
			}
			if ( _proxyRegistries[ _index_ ] == proxyRegistryAddress_ ) {
				return;
			}
		}
		_proxyRegistries.push( proxyRegistryAddress_ );
	}

	/**
	* @dev Internal function that removes a proxy registry from the list of accepted proxy registries.
	*/
	function _removeProxyRegistry( address proxyRegistryAddress_ ) internal {
		uint256 _len_ = _proxyRegistries.length;
		uint256 _index_ = _len_;
		while ( _index_ > 0 ) {
			unchecked {
				_index_ --;
			}
			if ( _proxyRegistries[ _index_ ] == proxyRegistryAddress_ ) {
				if ( _index_ + 1 != _len_ ) {
					_proxyRegistries[ _index_ ] = _proxyRegistries[ _len_ - 1 ];
				}
				_proxyRegistries.pop();
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
		uint256 _index_ = _proxyRegistries.length;
		while ( _index_ > 0 ) {
			unchecked {
				_index_ --;
			}
			ProxyRegistry _proxyRegistry_ = ProxyRegistry( _proxyRegistries[ _index_ ] );
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

import "../../interfaces/IERC721Enumerable.sol";
import "../../interfaces/IERC721Metadata.sol";
import "../../interfaces/IERC721Receiver.sol";
import "@openzeppelin/contracts/utils/Context.sol";

/**
* @dev Required interface of an ERC721 compliant contract.
*/
abstract contract Reg_ERC721Batch is Context, IERC721Metadata, IERC721Enumerable {
	// Errors
	error IERC721_CALLER_NOT_APPROVED( address tokenOwner, address operator, uint256 tokenId );
	error IERC721_NONEXISTANT_TOKEN( uint256 tokenId );
	error IERC721_NON_ERC721_RECEIVER( address receiver );
	error IERC721_INVALID_APPROVAL( address operator );
	error IERC721_INVALID_TRANSFER( address recipient );
	error IERC721_INVALID_TRANSFER_FROM();
	error IERC721Enumerable_INDEX_OUT_OF_BOUNDS( uint256 index );
	error IERC721Enumerable_OWNER_INDEX_OUT_OF_BOUNDS( address tokenOwner, uint256 index );

	uint256 private _nextId = 1;
	string  public  name;
	string  public  symbol;

	// Mapping from token ID to approved address
	mapping( uint256 => address ) public getApproved;

	// Mapping from owner to operator approvals
	mapping( address => mapping( address => bool ) ) private _operatorApprovals;

	// List of owner addresses
	mapping( uint256 => address ) private _owners;

	// Token Base URI
	string  private _baseURI;

	/**
	* @dev Ensures the token exist. 
	* A token exists if it has been minted and is not owned by the null address.
	* 
	* @param tokenId_ uint256 ID of the token to verify
	*/
	modifier exists( uint256 tokenId_ ) {
		if ( ! _exists( tokenId_ ) ) {
			revert IERC721_NONEXISTANT_TOKEN( tokenId_ );
		}
		_;
	}

	// **************************************
	// *****          INTERNAL          *****
	// **************************************
		/**
		* @dev Internal function returning the number of tokens in `tokenOwner_`'s account.
		*/
		function _balanceOf( address tokenOwner_ ) internal view virtual returns ( uint256 ) {
			if ( tokenOwner_ == address( 0 ) ) {
				return 0;
			}

			uint256 _count_ = 0;
			address _currentTokenOwner_;
			for ( uint256 i = 1; i < _nextId; ++ i ) {
        if ( _exists( i ) ) {
          if ( _owners[ i ] != address( 0 ) ) {
            _currentTokenOwner_ = _owners[ i ];
          }
          if ( tokenOwner_ == _currentTokenOwner_ ) {
            _count_++;
          }
        }
			}
			return _count_;
		}

		/**
		* @dev Internal function to invoke {IERC721Receiver-onERC721Received} on a target address.
		* The call is not executed if the target address is not a contract.
		*
		* @param from_ address representing the previous owner of the given token ID
		* @param to_ target address that will receive the tokens
		* @param tokenId_ uint256 ID of the token to be transferred
		* @param data_ bytes optional data to send along with the call
		* @return bool whether the call correctly returned the expected magic value
		*/
		function _checkOnERC721Received( address from_, address to_, uint256 tokenId_, bytes memory data_ ) internal virtual returns ( bool ) {
			// This method relies on extcodesize, which returns 0 for contracts in
			// construction, since the code is only stored at the end of the
			// constructor execution.
			// 
			// IMPORTANT
			// It is unsafe to assume that an address not flagged by this method
			// is an externally-owned account (EOA) and not a contract.
			//
			// Among others, the following types of addresses will not be flagged:
			//
			//  - an externally-owned account
			//  - a contract in construction
			//  - an address where a contract will be created
			//  - an address where a contract lived, but was destroyed
			uint256 _size_;
			assembly {
				_size_ := extcodesize( to_ )
			}

			// If address is a contract, check that it is aware of how to handle ERC721 tokens
			if ( _size_ > 0 ) {
				try IERC721Receiver( to_ ).onERC721Received( _msgSender(), from_, tokenId_, data_ ) returns ( bytes4 retval ) {
					return retval == IERC721Receiver.onERC721Received.selector;
				}
				catch ( bytes memory reason ) {
					if ( reason.length == 0 ) {
						revert IERC721_NON_ERC721_RECEIVER( to_ );
					}
					else {
						assembly {
							revert( add( 32, reason ), mload( reason ) )
						}
					}
				}
			}
			else {
				return true;
			}
		}

		/**
		* @dev Internal function returning whether a token exists. 
		* A token exists if it has been minted and is not owned by the null address.
		* 
		* @param tokenId_ uint256 ID of the token to verify
		* 
		* @return bool whether the token exists
		*/
		function _exists( uint256 tokenId_ ) internal view virtual returns ( bool ) {
      if ( tokenId_ == 0 ) {
        return false;
      }
			return tokenId_ < _nextId;
		}

		/**
		* @dev Initializes the contract by setting a `name` and a `symbol` to the token collection.
		*/
		function _initERC721Metadata( string memory name_, string memory symbol_, string memory baseURI_ ) internal {
			name     = name_;
			symbol   = symbol_;
			_baseURI = baseURI_;
		}

		/**
		* @dev Internal function returning whether `operator_` is allowed 
		* to manage tokens on behalf of `tokenOwner_`.
		* 
		* @param tokenOwner_ address that owns tokens
		* @param operator_ address that tries to manage tokens
		* 
		* @return bool whether `operator_` is allowed to handle the token
		*/
		function _isApprovedForAll( address tokenOwner_, address operator_ ) internal view virtual returns ( bool ) {
			return _operatorApprovals[ tokenOwner_ ][ operator_ ];
		}

		/**
		* @dev Internal function returning whether `operator_` is allowed to handle `tokenId_`
		* 
		* Note: To avoid multiple checks for the same data, it is assumed that existence of `tokeId_` 
		* has been verified prior via {_exists}
		* If it hasn't been verified, this function might panic
		* 
		* @param operator_ address that tries to handle the token
		* @param tokenId_ uint256 ID of the token to be handled
		* 
		* @return bool whether `operator_` is allowed to handle the token
		*/
		function _isApprovedOrOwner( address tokenOwner_, address operator_, uint256 tokenId_ ) internal view virtual returns ( bool ) {
			bool _isApproved_ = operator_ == tokenOwner_ ||
													operator_ == getApproved[ tokenId_ ] ||
													_isApprovedForAll( tokenOwner_, operator_ );
			return _isApproved_;
		}

		/**
		* @dev Mints `qty_` tokens and transfers them to `to_`.
		* 
		* This internal function can be used to perform token minting.
		* 
		* Emits one or more {Transfer} event.
		*/
		function _mint( address to_, uint256 qty_ ) internal virtual {
			uint256 _firstToken_ = _nextId;
			uint256 _nextStart_ = _firstToken_ + qty_;
			uint256 _lastToken_ = _nextStart_ - 1;

			_owners[ _firstToken_ ] = to_;
			if ( _lastToken_ > _firstToken_ ) {
				_owners[ _lastToken_ ] = to_;
			}
			_nextId = _nextStart_;

			if ( ! _checkOnERC721Received( address( 0 ), to_, _firstToken_, "" ) ) {
				revert IERC721_NON_ERC721_RECEIVER( to_ );
			}

			for ( uint256 i = _firstToken_; i < _nextStart_; ++i ) {
				emit Transfer( address( 0 ), to_, i );
			}
		}

		/**
		* @dev Internal function returning the owner of the `tokenId_` token.
		* 
		* @param tokenId_ uint256 ID of the token to verify
		* 
		* @return address the address of the token owner
		*/
		function _ownerOf( uint256 tokenId_ ) internal view virtual returns ( address ) {
			uint256 _tokenId_ = tokenId_;
			address _tokenOwner_ = _owners[ _tokenId_ ];
			while ( _tokenOwner_ == address( 0 ) ) {
				_tokenId_ --;
				_tokenOwner_ = _owners[ _tokenId_ ];
			}

			return _tokenOwner_;
		}

		/**
		* @dev Internal function used to set the base URI of the collection.
		*/
		function _setBaseURI( string memory baseURI_ ) internal virtual {
			_baseURI = baseURI_;
		}

		/**
		* @dev Internal function returning the total supply.
		*/
		function _totalSupply() internal view virtual returns ( uint256 ) {
			return supplyMinted();
		}

		/**
		* @dev Converts a `uint256` to its ASCII `string` decimal representation.
		*/
		function _toString( uint256 value ) internal pure returns ( string memory ) {
			// Inspired by OraclizeAPI's implementation - MIT licence
			// https://github.com/oraclize/ethereum-api/blob/b42146b063c7d6ee1358846c198246239e9360e8/oraclizeAPI_0.4.25.sol
			if ( value == 0 ) {
				return "0";
			}
			uint256 temp = value;
			uint256 digits;
			while ( temp != 0 ) {
				digits ++;
				temp /= 10;
			}
			bytes memory buffer = new bytes( digits );
			while ( value != 0 ) {
				digits -= 1;
				buffer[ digits ] = bytes1( uint8( 48 + uint256( value % 10 ) ) );
				value /= 10;
			}
			return string( buffer );
		}

		/**
		* @dev Transfers `tokenId_` from `from_` to `to_`.
		*
		* This internal function can be used to implement alternative mechanisms to perform 
		* token transfer, such as signature-based, or token burning.
		* 
		* Emits a {Transfer} event.
		*/
		function _transfer( address from_, address to_, uint256 tokenId_ ) internal virtual {
			getApproved[ tokenId_ ] = address( 0 );
			uint256 _previousId_ = tokenId_ > 1 ? tokenId_ - 1 : 1;
			uint256 _nextId_     = tokenId_ + 1;
			bool _previousShouldUpdate_ = _previousId_ < tokenId_ &&
																		_exists( _previousId_ ) &&
																		_owners[ _previousId_ ] == address( 0 );
			bool _nextShouldUpdate_ = _exists( _nextId_ ) &&
																_owners[ _nextId_ ] == address( 0 );

			if ( _previousShouldUpdate_ ) {
				_owners[ _previousId_ ] = from_;
			}

			if ( _nextShouldUpdate_ ) {
				_owners[ _nextId_ ] = from_;
			}

			_owners[ tokenId_ ] = to_;

			emit Transfer( from_, to_, tokenId_ );
		}
	// **************************************

	// **************************************
	// *****           PUBLIC           *****
	// **************************************
		/**
		* @dev See {IERC721-approve}.
		*/
		function approve( address to_, uint256 tokenId_ ) public virtual exists( tokenId_ ) {
			address _operator_ = _msgSender();
			address _tokenOwner_ = _ownerOf( tokenId_ );
			bool _isApproved_ = _isApprovedOrOwner( _tokenOwner_, _operator_, tokenId_ );

			if ( ! _isApproved_ ) {
				revert IERC721_CALLER_NOT_APPROVED( _tokenOwner_, _operator_, tokenId_ );
			}

			if ( to_ == _tokenOwner_ ) {
				revert IERC721_INVALID_APPROVAL( to_ );
			}

			getApproved[ tokenId_ ] = to_;
			emit Approval( _tokenOwner_, to_, tokenId_ );
		}

		/**
		* @dev See {IERC721-safeTransferFrom}.
		* 
		* Note: We can ignore `from_` as we can compare everything to the actual token owner, 
		* but we cannot remove this parameter to stay in conformity with IERC721
		*/
		function safeTransferFrom( address from_, address to_, uint256 tokenId_ ) public virtual exists( tokenId_ ) {
			address _operator_ = _msgSender();
			address _tokenOwner_ = _ownerOf( tokenId_ );
			if ( from_ != _tokenOwner_ ) {
				revert IERC721_INVALID_TRANSFER_FROM();
			}
			bool _isApproved_ = _isApprovedOrOwner( _tokenOwner_, _operator_, tokenId_ );

			if ( ! _isApproved_ ) {
				revert IERC721_CALLER_NOT_APPROVED( _tokenOwner_, _operator_, tokenId_ );
			}

			if ( to_ == address( 0 ) ) {
				revert IERC721_INVALID_TRANSFER( to_ );
			}

			_transfer( _tokenOwner_, to_, tokenId_ );

			if ( ! _checkOnERC721Received( _tokenOwner_, to_, tokenId_, "" ) ) {
				revert IERC721_NON_ERC721_RECEIVER( to_ );
			}
		}

		/**
		* @dev See {IERC721-safeTransferFrom}.
		* 
		* Note: We can ignore `from_` as we can compare everything to the actual token owner, 
		* but we cannot remove this parameter to stay in conformity with IERC721
		*/
		function safeTransferFrom( address from_, address to_, uint256 tokenId_, bytes calldata data_ ) public virtual exists( tokenId_ ) {
			address _operator_ = _msgSender();
			address _tokenOwner_ = _ownerOf( tokenId_ );
			if ( from_ != _tokenOwner_ ) {
				revert IERC721_INVALID_TRANSFER_FROM();
			}
			bool _isApproved_ = _isApprovedOrOwner( _tokenOwner_, _operator_, tokenId_ );

			if ( ! _isApproved_ ) {
				revert IERC721_CALLER_NOT_APPROVED( _tokenOwner_, _operator_, tokenId_ );
			}

			if ( to_ == address( 0 ) ) {
				revert IERC721_INVALID_TRANSFER( to_ );
			}

			_transfer( _tokenOwner_, to_, tokenId_ );

			if ( ! _checkOnERC721Received( _tokenOwner_, to_, tokenId_, data_ ) ) {
				revert IERC721_NON_ERC721_RECEIVER( to_ );
			}
		}

		/**
		* @dev See {IERC721-setApprovalForAll}.
		*/
		function setApprovalForAll( address operator_, bool approved_ ) public virtual override {
			address _account_ = _msgSender();
			if ( operator_ == _account_ ) {
				revert IERC721_INVALID_APPROVAL( operator_ );
			}

			_operatorApprovals[ _account_ ][ operator_ ] = approved_;
			emit ApprovalForAll( _account_, operator_, approved_ );
		}

		/**
		* @dev See {IERC721-transferFrom}.
		* 
		* Note: We can ignore `from_` as we can compare everything to the actual token owner, 
		* but we cannot remove this parameter to stay in conformity with IERC721
		*/
		function transferFrom( address from_, address to_, uint256 tokenId_ ) public virtual exists( tokenId_ ) {
			address _operator_ = _msgSender();
			address _tokenOwner_ = _ownerOf( tokenId_ );
			if ( from_ != _tokenOwner_ ) {
				revert IERC721_INVALID_TRANSFER_FROM();
			}
			bool _isApproved_ = _isApprovedOrOwner( _tokenOwner_, _operator_, tokenId_ );

			if ( ! _isApproved_ ) {
				revert IERC721_CALLER_NOT_APPROVED( _tokenOwner_, _operator_, tokenId_ );
			}

			if ( to_ == address( 0 ) ) {
				revert IERC721_INVALID_TRANSFER( to_ );
			}

			_transfer( _tokenOwner_, to_, tokenId_ );
		}
	// **************************************

	// **************************************
	// *****            VIEW            *****
	// **************************************
		/**
		* @dev Returns the number of tokens in `tokenOwner_`'s account.
		*/
		function balanceOf( address tokenOwner_ ) public view virtual returns ( uint256 ) {
			return _balanceOf( tokenOwner_ );
		}

		/**
		* @dev Returns if the `operator_` is allowed to manage all of the assets of `tokenOwner_`.
		*
		* See {setApprovalForAll}
		*/
		function isApprovedForAll( address tokenOwner_, address operator_ ) public view virtual returns ( bool ) {
			return _isApprovedForAll( tokenOwner_, operator_ );
		}

		/**
		* @dev Returns the owner of the `tokenId_` token.
		*
		* Requirements:
		*
		* - `tokenId_` must exist.
		*/
		function ownerOf( uint256 tokenId_ ) public view virtual exists( tokenId_ ) returns ( address ) {
			return _ownerOf( tokenId_ );
		}

		/**
		* @dev Returns the total number of tokens minted
		* 
		* @return uint256 the number of tokens that have been minted so far
		*/
		function supplyMinted() public view virtual returns ( uint256 ) {
			return _nextId - 1;
		}

		/**
		* @dev See {IERC165-supportsInterface}.
		*/
		function supportsInterface( bytes4 interfaceId_ ) public view virtual override returns ( bool ) {
			return 
				interfaceId_ == type( IERC721Enumerable ).interfaceId ||
				interfaceId_ == type( IERC721Metadata ).interfaceId ||
				interfaceId_ == type( IERC721 ).interfaceId ||
				interfaceId_ == type( IERC165 ).interfaceId;
		}

		/**
		* @dev See {IERC721Enumerable-tokenByIndex}.
		*/
		function tokenByIndex( uint256 index_ ) public view virtual override returns ( uint256 ) {
			if ( index_ >= supplyMinted() ) {
				revert IERC721Enumerable_INDEX_OUT_OF_BOUNDS( index_ );
			}
			return index_;
		}

		/**
		* @dev See {IERC721Enumerable-tokenOfOwnerByIndex}.
		*/
		function tokenOfOwnerByIndex( address tokenOwner_, uint256 index_ ) public view virtual override returns ( uint256 tokenId ) {
      if ( index_ >= _balanceOf( tokenOwner_ ) ) {
        revert IERC721Enumerable_OWNER_INDEX_OUT_OF_BOUNDS( tokenOwner_, index_ );
      }

      uint256 _count_ = 0;
      for ( uint256 i = 1; i < _nextId; i++ ) {
        if ( _exists( i ) && tokenOwner_ == _ownerOf( i ) ) {
          if ( index_ == _count_ ) {
            return i;
          }
          _count_++;
        }
      }
		}

		/**
		* @dev See {IERC721Metadata-tokenURI}.
		*/
		function tokenURI( uint256 tokenId_ ) public view virtual override exists( tokenId_ ) returns ( string memory ) {
			return bytes( _baseURI ).length > 0 ? string( abi.encodePacked( _baseURI, _toString( tokenId_ ) ) ) : _toString( tokenId_ );
		}

		/**
		* @dev See {IERC721Enumerable-totalSupply}.
		*/
		function totalSupply() public view virtual override returns ( uint256 ) {
			return _totalSupply();
		}
	// **************************************
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

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (token/ERC721/IERC721Receiver.sol)

pragma solidity 0.8.10;

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
    function onERC721Received(
        address operator,
        address from,
        uint256 tokenId,
        bytes calldata data
    ) external returns (bytes4);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (token/ERC721/extensions/IERC721Metadata.sol)

pragma solidity 0.8.10;

import "./IERC721.sol";

/**
 * @title ERC-721 Non-Fungible Token Standard, optional metadata extension
 * @dev See https://eips.ethereum.org/EIPS/eip-721
 */
interface IERC721Metadata is IERC721 {
    /**
     * @dev Returns the token collection name.
     */
    function name() external view returns (string memory);

    /**
     * @dev Returns the token collection symbol.
     */
    function symbol() external view returns (string memory);

    /**
     * @dev Returns the Uniform Resource Identifier (URI) for `tokenId` token.
     */
    function tokenURI(uint256 tokenId) external view returns (string memory);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (token/ERC721/extensions/IERC721Enumerable.sol)

pragma solidity 0.8.10;

import "./IERC721.sol";

/**
 * @title ERC-721 Non-Fungible Token Standard, optional enumeration extension
 * @dev See https://eips.ethereum.org/EIPS/eip-721
 */
interface IERC721Enumerable is IERC721 {
    /**
     * @dev Returns the total amount of tokens stored by the contract.
     */
    function totalSupply() external view returns ( uint256 );

    /**
     * @dev Returns a token ID owned by `owner` at a given `index` of its token list.
     * Use along with {balanceOf} to enumerate all of `owner`'s tokens.
     */
    function tokenOfOwnerByIndex( address owner_, uint256 index_ ) external view returns ( uint256 tokenId );

    /**
     * @dev Returns a token ID at a given `index` of all the tokens stored by the contract.
     * Use along with {totalSupply} to enumerate all tokens.
     */
    function tokenByIndex( uint256 index_ ) external view returns ( uint256 );
}