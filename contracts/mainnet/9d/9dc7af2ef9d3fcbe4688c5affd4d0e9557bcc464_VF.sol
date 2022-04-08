// SPDX-License-Identifier: MIT

/**
* Author: Lambdalf the White
*/

pragma solidity 0.8.10;

import './ERC721BatchBurnable.sol';
import './ERC2981Base.sol';
import './IAdministrable.sol';
import './IPausable.sol';
import './ITradable.sol';

contract VF is ERC721BatchBurnable, ERC2981Base, IAdministrable, IPausable, ITradable {
	// Events
	event PaymentSent( address indexed from, address indexed to, uint256 indexed amount );

	// Errors
	error VF_MAX_BATCH();
	error VF_MAX_SUPPLY();
	error VF_TRANSFER_FAIL();
	error VF_INCORRECT_PRICE();
	error VF_NO_ETHER_BALANCE();
	error VF_WALLETS_MISMATCH();
	error VF_INSUFFICIENT_KEY_BALANCE();
	error VF_INSUFFICIENT_ETHER_BALANCE();

	// Max supply
	uint public immutable MAX_SUPPLY;

	// Max TX
	uint public immutable MAX_BATCH;

	// Mint Price
	uint public immutable MINT_PRICE;

	// Team wallets
	address private constant COMMUNITY = 0x73DAdB28902A54d197D541E290a9F05Ed4e033e2; // 25%
	address private constant FOUNDERS  = 0x7E5541CEeb1C1B24Ca847F52f9505533F1c557e0; // 40%
	address private constant MCS       = 0x6Bc8c4Ef598218cbcB903efB9b711dA88C8f202b; // 35%

	constructor(
		uint256 royaltyRate_,
		uint256 maxSupply_,
		uint256 maxBatch_,
		uint256 mintPrice_,
		string memory name_,
		string memory symbol_,
		string memory baseURI_
	) {
		_initIOwnable( _msgSender() );
		_initERC2981Base( COMMUNITY, royaltyRate_ );
		_initERC721BatchMetadata( name_, symbol_ );
		_setBaseURI( baseURI_ );
		MAX_SUPPLY   = maxSupply_;
		MAX_BATCH    = maxBatch_;
		MINT_PRICE   = mintPrice_;
	}

	function mintSale( uint256 qty_ ) external payable saleOpen {
		if ( qty_ > MAX_BATCH ) {
			revert VF_MAX_BATCH();
		}

		if ( qty_ + _supplyMinted() > MAX_SUPPLY ) {
			revert VF_MAX_SUPPLY();
		}

		if ( qty_ * MINT_PRICE != msg.value ) {
			revert VF_INCORRECT_PRICE();
		}
		_mint( _msgSender(), qty_ );
	}

	function withdraw() external onlyAdmin {
		uint256 _balance_ = address( this ).balance;
		if ( _balance_ == 0 ) {
			revert VF_NO_ETHER_BALANCE();
		}

		uint256 _communityShare_ = _balance_ * 250 / 1000;
		uint256 _foundersShare_  = _balance_ * 400 / 1000;
		uint256 _mcsShare_       = _balance_ * 350 / 1000;
		_sendValue( payable( COMMUNITY ), _communityShare_ );
		_sendValue( payable( FOUNDERS  ), _foundersShare_  );
		_sendValue( payable( MCS       ), _mcsShare_       );
	}

	function setSaleState( SaleState newState_ ) external onlyAdmin {
		_setSaleState( newState_ );
	}

	function setBaseURI( string memory baseURI_ ) external onlyOwner {
		_setBaseURI( baseURI_ );
	}

	function setProxyRegistry( address proxyRegistryAddress_ ) external onlyOwner {
		_setProxyRegistry( proxyRegistryAddress_ );
	}

	function setRoyaltyInfo( address recipient_, uint256 royaltyRate_ ) external onlyAdmin {
		_setRoyaltyInfo( recipient_, royaltyRate_ );
	}

	/**
	* @dev Replacement for Solidity's `transfer`: sends `amount_` wei to
	* `recipient_`, forwarding all available gas and reverting on errors.
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
	function _sendValue( address payable recipient_, uint256 amount_ ) internal {
		if ( address( this ).balance < amount_ ) {
			revert VF_INSUFFICIENT_ETHER_BALANCE();
		}
		( bool _success_, ) = recipient_.call{ value: amount_ }( "" );
		if ( ! _success_ ) {
			revert VF_TRANSFER_FAIL();
		}
    emit PaymentSent( address( this ), recipient_, amount_ );
	}

	function supportsInterface( bytes4 interfaceId_ ) public view virtual override(ERC721Batch, ERC2981Base) returns ( bool ) {
		return 
			interfaceId_ == type( IERC2981 ).interfaceId ||
			ERC721Batch.supportsInterface( interfaceId_ );
	}

	/**
	* @dev See {IERC2981-royaltyInfo}.
	* 
	* Note: This function should be overriden to revert on a query for non existent token.
	*/
	function royaltyInfo( uint256 tokenId_, uint256 salePrice_ ) public view virtual override exists( tokenId_ ) returns ( address, uint256 ) {
		return super.royaltyInfo( tokenId_, salePrice_ );
	}

  function _isApprovedForAll( address tokenOwner_, address operator_ ) internal view virtual override returns ( bool ) {
    return _isRegisteredProxy( tokenOwner_, operator_ ) ||
    			 super._isApprovedForAll( tokenOwner_, operator_ );
  }
}