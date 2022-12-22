// SPDX-License-Identifier: MIT

/**
* @team   : Asteria Labs
* @author : Lambdalf the White
*/

pragma solidity 0.8.17;

import 'EthereumContracts/contracts/interfaces/IArrayErrors.sol';
import 'EthereumContracts/contracts/interfaces/IEtherErrors.sol';
import 'EthereumContracts/contracts/interfaces/IERC721Errors.sol';
import 'EthereumContracts/contracts/interfaces/INFTSupplyErrors.sol';
import 'EthereumContracts/contracts/interfaces/IERC165.sol';
import 'EthereumContracts/contracts/interfaces/IERC721.sol';
import 'EthereumContracts/contracts/interfaces/IERC721Metadata.sol';
import 'EthereumContracts/contracts/interfaces/IERC721Enumerable.sol';
import 'EthereumContracts/contracts/interfaces/IERC721Receiver.sol';
import 'EthereumContracts/contracts/utils/ERC173.sol';
import 'EthereumContracts/contracts/utils/ContractState.sol';
import 'EthereumContracts/contracts/utils/Whitelist_ECDSA.sol';
import 'EthereumContracts/contracts/utils/ERC2981.sol';
import 'operator-filter-registry/src/UpdatableOperatorFilterer.sol';

contract EthernalOnes is 
IArrayErrors, IEtherErrors, IERC721Errors, INFTSupplyErrors,
IERC165, IERC721, IERC721Metadata, IERC721Enumerable,
ERC173, ContractState, Whitelist_ECDSA, ERC2981, UpdatableOperatorFilterer {
  // Errors
  error EO_PHASE_DEPLETED( uint8 currentPhase );

  // Constants
  uint8 public constant PHASE1_SALE = 1;
  uint8 public constant PHASE2_SALE = 2;
  uint8 public constant PUBLIC_SALE = 3;
  address public constant DEFAULT_SUBSCRIPTION = address( 0x3cc6CddA760b79bAfa08dF41ECFA224f810dCeB6 );
  address public constant DEFAULT_OPERATOR_FILTER_REGISTRY = address( 0x000000000000AAeB6D7670E522A718067333cd4E );
  string public constant name = "Ethernal Ones - The Awakening";
  string public constant symbol = "EONFT";
  uint256 public constant MAX_BATCH = 2;

  // Private variables
  uint256 public maxSupply = 6666;
  uint256 private _nextId = 1;
  uint256 private _reserve = 50;
  address private _treasury;
  string  private _baseURI = "ipfs://QmPcyrBaY65ZVWReFwkPXUQHGUjq4skCVhk5HfSx1FJoi7";

  // Mapping from token ID to approved address
  mapping( uint256 => address ) private _approvals;

  // Mapping from owner to operator approvals
  mapping( address => mapping( address => bool ) ) private _operatorApprovals;

  // List of owner addresses
  mapping( uint256 => address ) private _owners;

  // Mapping from phase to sale price
  mapping( uint8 => uint256 ) private _salePrice;

  // Mapping from phase to max supply
  mapping( uint8 => uint256 ) private _maxPhase;

  constructor() UpdatableOperatorFilterer( DEFAULT_OPERATOR_FILTER_REGISTRY, DEFAULT_SUBSCRIPTION, true ) {
    _salePrice[ PHASE1_SALE ] = 59000000000000000; // 0.059 ether
    _salePrice[ PHASE2_SALE ] = 79000000000000000; // 0.079 ether
    _salePrice[ PUBLIC_SALE ] = 89000000000000000; // 0.089 ether
    _maxPhase[ PHASE1_SALE ] = 2999;
    _maxPhase[ PHASE2_SALE ] = 5665;
    _treasury = 0x2b1076BF95DA326441e5bf81A1d0357b10bDb933;
    _setOwner( msg.sender );
    _setRoyaltyInfo( 0x4F440081A1c6a94cA5Fa5fEcc31bceC5bba62691, 500 );
    _setWhitelist( 0x7df36A44FcA36F05A6fbF74B7cBdd9B43349e37F );
  }

  // **************************************
  // *****          MODIFIER          *****
  // **************************************
    /**
    * @dev Ensures the token exist. 
    * A token exists if it has been minted and is not owned by the null address.
    * 
    * @param tokenId_ : identifier of the NFT being referenced
    */
    modifier exists( uint256 tokenId_ ) {
      if ( ! _exists( tokenId_ ) ) {
        revert IERC721_NONEXISTANT_TOKEN( tokenId_ );
      }
      _;
    }

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

    /**
    * @dev Ensures that contract state is {PHASE1_SALE} or {PHASE2_SALE}
    */
    modifier isWhitelist() {
      uint8 _currentState_ = getContractState();
      if ( _currentState_ != PHASE1_SALE &&
           _currentState_ != PHASE2_SALE ) {
        revert ContractState_INCORRECT_STATE( _currentState_ );
      }
      _;
    }
  // **************************************

  // **************************************
  // *****          INTERNAL          *****
  // **************************************
    // ***********
    // * IERC721 *
    // ***********
      /**
      * @dev Internal function returning the number of tokens in `userAddress_`'s account.
      * 
      * @param userAddress_ : address that may own tokens
      * 
      * @return uint256 : the number of tokens owned by `userAddress_`
      */
      function _balanceOf( address userAddress_ ) internal view virtual returns ( uint256 ) {
        if ( userAddress_ == address( 0 ) ) {
          return 0;
        }

        uint256 _count_;
        address _currentTokenOwner_;
        uint256 _index_ = 1;
        while ( _index_ < _nextId ) {
          if ( _exists( _index_ ) ) {
            if ( _owners[ _index_ ] != address( 0 ) ) {
              _currentTokenOwner_ = _owners[ _index_ ];
            }
            if ( userAddress_ == _currentTokenOwner_ ) {
              unchecked {
                ++_count_;
              }
            }
          }
          unchecked {
            ++_index_;
          }
        }
        return _count_;
      }

      /**
      * @dev Internal function to invoke {IERC721Receiver-onERC721Received} on a target address.
      * The call is not executed if the target address is not a contract.
      *
      * @param fromAddress_ : previous owner of the NFT
      * @param toAddress_   : new owner of the NFT
      * @param tokenId_     : identifier of the NFT being transferred
      * @param data_        : optional data to send along with the call

      * @return bool : whether the call correctly returned the expected value (IERC721Receiver.onERC721Received.selector)
      */
      function _checkOnERC721Received( address fromAddress_, address toAddress_, uint256 tokenId_, bytes memory data_ ) internal virtual returns ( bool ) {
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
          _size_ := extcodesize( toAddress_ )
        }

        // If address is a contract, check that it is aware of how to handle ERC721 tokens
        if ( _size_ > 0 ) {
          try IERC721Receiver( toAddress_ ).onERC721Received( msg.sender, fromAddress_, tokenId_, data_ ) returns ( bytes4 retval ) {
            return retval == IERC721Receiver.onERC721Received.selector;
          }
          catch ( bytes memory reason ) {
            if ( reason.length == 0 ) {
              revert IERC721_NON_ERC721_RECEIVER( toAddress_ );
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
      * @param tokenId_ : identifier of the NFT to verify
      * 
      * @return bool : whether the NFT exists
      */
      function _exists( uint256 tokenId_ ) internal view virtual returns ( bool ) {
        if ( tokenId_ == 0 ) {
          return false;
        }
        return tokenId_ < _nextId;
      }

      /**
      * @dev Internal function returning whether `operator_` is allowed 
      * to manage tokens on behalf of `tokenOwner_`.
      * 
      * @param tokenOwner_ : address that owns tokens
      * @param operator_   : address that tries to manage tokens
      * 
      * @return bool : whether `operator_` is allowed to handle the token
      */
      function _isApprovedForAll( address tokenOwner_, address operator_ ) internal view virtual returns ( bool ) {
        return _operatorApprovals[ tokenOwner_ ][ operator_ ];
      }

      /**
      * @dev Internal function returning whether `operator_` is allowed to handle `tokenId_`
      * 
      * Note: To avoid multiple checks for the same data, it is assumed that existence of `tokenId_` 
      * has been verified prior via {_exists}
      * If it hasn't been verified, this function might panic
      * 
      * @param tokenOwner_ : address that owns tokens
      * @param operator_   : address that tries to handle the token
      * @param tokenId_    : identifier of the NFT
      * 
      * @return bool whether `operator_` is allowed to handle the token
      */
      function _isApprovedOrOwner( address tokenOwner_, address operator_, uint256 tokenId_ ) internal view virtual returns ( bool ) {
        bool _isApproved_ = operator_ == tokenOwner_ ||
                            operator_ == _approvals[ tokenId_ ] ||
                            _isApprovedForAll( tokenOwner_, operator_ );
        return _isApproved_;
      }

      /**
      * @dev Mints `qty_` tokens and transfers them to `toAddress_`.
      * 
      * This internal function can be used to perform token minting.
      * 
      * Emits one or more {Transfer} event.
      * 
      * @param toAddress_ : address receiving the NFTs
      * @param qty_       : number of NFTs being minted
      */
      function _mint( address toAddress_, uint256 qty_ ) internal virtual {
        uint256 _firstToken_ = _nextId;
        uint256 _nextStart_ = _firstToken_ + qty_;
        uint256 _lastToken_ = _nextStart_ - 1;

        _owners[ _firstToken_ ] = toAddress_;
        if ( _lastToken_ > _firstToken_ ) {
          _owners[ _lastToken_ ] = toAddress_;
        }
        _nextId = _nextStart_;

        if ( ! _checkOnERC721Received( address( 0 ), toAddress_, _firstToken_, "" ) ) {
          revert IERC721_NON_ERC721_RECEIVER( toAddress_ );
        }

        while ( _firstToken_ < _nextStart_ ) {
          emit Transfer( address( 0 ), toAddress_, _firstToken_ );
          unchecked {
            _firstToken_ ++;
          }
        }
      }

      /**
      * @dev Internal function returning the owner of the `tokenId_` token.
      * 
      * @param tokenId_ : identifier of the NFT
      * 
      * @return : address that owns the NFT
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
      * @dev Transfers `tokenId_` from `fromAddress_` to `toAddress_`.
      *
      * This internal function can be used to implement alternative mechanisms to perform 
      * token transfer, such as signature-based, or token burning.
      * 
      * @param fromAddress_ : previous owner of the NFT
      * @param toAddress_   : new owner of the NFT
      * @param tokenId_     : identifier of the NFT being transferred
      * 
      * Emits a {Transfer} event.
      */
      function _transfer( address fromAddress_, address toAddress_, uint256 tokenId_ ) internal virtual {
        _approvals[ tokenId_ ] = address( 0 );
        uint256 _previousId_ = tokenId_ > 1 ? tokenId_ - 1 : 1;
        uint256 _nextId_     = tokenId_ + 1;
        bool _previousShouldUpdate_ = _previousId_ < tokenId_ &&
                                      _exists( _previousId_ ) &&
                                      _owners[ _previousId_ ] == address( 0 );
        bool _nextShouldUpdate_ = _exists( _nextId_ ) &&
                                  _owners[ _nextId_ ] == address( 0 );

        if ( _previousShouldUpdate_ ) {
          _owners[ _previousId_ ] = fromAddress_;
        }

        if ( _nextShouldUpdate_ ) {
          _owners[ _nextId_ ] = fromAddress_;
        }

        _owners[ tokenId_ ] = toAddress_;

        emit Transfer( fromAddress_, toAddress_, tokenId_ );
      }
    // ***********

    // *********************
    // * IERC721Enumerable *
    // *********************
      /**
      * @dev See {IERC721Enumerable-totalSupply}.
      */
      function _totalSupply() internal view virtual returns ( uint256 ) {
        uint256 _supplyMinted_ = supplyMinted();
        uint256 _count_ = _supplyMinted_;
        uint256 _index_ = _supplyMinted_;

        while ( _index_ > 0 ) {
          if ( ! _exists( _index_ ) ) {
            unchecked {
              _count_ --;
            }
          }
          unchecked {
            _index_ --;
          }
        }
        return _count_;
      }
    // *********************

    // *******************
    // * IERC721Metadata *
    // *******************
      /**
      * @dev Converts a `uint256` to its ASCII `string` decimal representation.
      */
      function _toString( uint256 value_ ) internal pure virtual returns ( string memory str ) {
        assembly {
          // The maximum value of a uint256 contains 78 digits (1 byte per digit), but
          // we allocate 0xa0 bytes to keep the free memory pointer 32-byte word aligned.
          // We will need 1 word for the trailing zeros padding, 1 word for the length,
          // and 3 words for a maximum of 78 digits. Total: 5 * 0x20 = 0xa0.
          let m := add( mload( 0x40 ), 0xa0 )
          // Update the free memory pointer to allocate.
          mstore( 0x40, m )
          // Assign the `str` to the end.
          str := sub( m, 0x20 )
          // Zeroize the slot after the string.
          mstore( str, 0 )

          // Cache the end of the memory to calculate the length later.
          let end := str

          // We write the string from rightmost digit to leftmost digit.
          // The following is essentially a do-while loop that also handles the zero case.
          // prettier-ignore
          for { let temp := value_ } 1 {} {
            str := sub( str, 1 )
            // Write the character to the pointer.
            // The ASCII index of the '0' character is 48.
            mstore8( str, add( 48, mod( temp, 10 ) ) )
            // Keep dividing `temp` until zero.
            temp := div( temp, 10 )
            // prettier-ignore
            if iszero( temp ) { break }
          }

          let length := sub( end, str )
          // Move the pointer 32 bytes leftwards to make room for the length.
          str := sub( str, 0x20 )
          // Store the length.
          mstore( str, length )
        }
      }
    // *******************
  // **************************************

  // **************************************
  // *****           PUBLIC           *****
  // **************************************
    /**
    * @notice Mints `qty_` tokens and transfers them to the caller.
    * 
    * @param qty_           : the amount of tokens to be minted
    * @param alloted_       : the maximum alloted for that user
    * @param proof_         : the signature to verify whitelist allocation
    * 
    * Requirements:
    * 
    * - Sale state must be {PHASE1_SALE or PHASE2_SALE}.
    * - Caller must send enough ether to pay for `qty_` tokens at private sale price.
    */
    function mintPrivate( uint256 qty_, uint256 alloted_, Proof memory proof_ ) public payable validateAmount( qty_ ) isWhitelist isWhitelisted( msg.sender, PHASE1_SALE, alloted_, proof_, qty_ ) {
      uint8 _currentState_ = getContractState();
      if ( qty_ + supplyMinted() > _maxPhase[ _currentState_ ] ) {
        revert EO_PHASE_DEPLETED( _currentState_ );
      }

      uint256 _expected_ = qty_ * _salePrice[ _currentState_ ];
      if ( _expected_ != msg.value ) {
        revert ETHER_INCORRECT_PRICE( msg.value, _expected_ );
      }

      _mint( msg.sender, qty_ );
      _consumeWhitelist( msg.sender, PHASE1_SALE, qty_ );
    }

    /**
    * @notice Mints `qty_` tokens and transfers them to the caller.
    * 
    * @param qty_ : the amount of tokens to be minted
    * 
    * Requirements:
    * 
    * - Sale state must be {PUBLIC_SALE}.
    * - There must be enough tokens left to mint outside of the reserve.
    * - Caller must send enough ether to pay for `qty_` tokens at public sale price.
    */
    function mintPublic( uint256 qty_ ) public payable validateAmount( qty_ ) isState( PUBLIC_SALE ) {
      if ( qty_ > MAX_BATCH ) {
        revert NFT_MAX_BATCH( qty_, MAX_BATCH );
      }

      uint256 _remainingSupply_ = maxSupply - _reserve - supplyMinted();
      if ( qty_ > _remainingSupply_ ) {
        revert NFT_MAX_SUPPLY( qty_, _remainingSupply_ );
      }

      uint256 _expected_ = qty_ * _salePrice[ PUBLIC_SALE ];
      if ( _expected_ != msg.value ) {
        revert ETHER_INCORRECT_PRICE( msg.value, _expected_ );
      }

      _mint( msg.sender, qty_ );
    }

    // ***********
    // * IERC721 *
    // ***********
      /**
      * @dev See {IERC721-approve}.
      */
      function approve( address to_, uint256 tokenId_ ) public virtual exists( tokenId_ ) onlyAllowedOperatorApproval( msg.sender ) {
        address _operator_ = msg.sender;
        address _tokenOwner_ = _ownerOf( tokenId_ );
        if ( to_ == _tokenOwner_ ) {
          revert IERC721_INVALID_APPROVAL( to_ );
        }

        bool _isApproved_ = _isApprovedOrOwner( _tokenOwner_, _operator_, tokenId_ );
        if ( ! _isApproved_ ) {
          revert IERC721_CALLER_NOT_APPROVED( _tokenOwner_, _operator_, tokenId_ );
        }

        _approvals[ tokenId_ ] = to_;
        emit Approval( _tokenOwner_, to_, tokenId_ );
      }

      /**
      * @dev See {IERC721-safeTransferFrom}.
      * 
      * Note: We can ignore `from_` as we can compare everything to the actual token owner, 
      * but we cannot remove this parameter to stay in conformity with IERC721
      */
      function safeTransferFrom( address from_, address to_, uint256 tokenId_ ) public virtual override {
        safeTransferFrom( from_, to_, tokenId_, "" );
      }

      /**
      * @dev See {IERC721-safeTransferFrom}.
      * 
      * Note: We can ignore `from_` as we can compare everything to the actual token owner, 
      * but we cannot remove this parameter to stay in conformity with IERC721
      */
      function safeTransferFrom( address from_, address to_, uint256 tokenId_, bytes memory data_ ) public virtual override {
        transferFrom( from_, to_, tokenId_ );
        if ( ! _checkOnERC721Received( from_, to_, tokenId_, data_ ) ) {
          revert IERC721_NON_ERC721_RECEIVER( to_ );
        }
      }

      /**
      * @dev See {IERC721-setApprovalForAll}.
      */
      function setApprovalForAll( address operator_, bool approved_ ) public virtual override onlyAllowedOperatorApproval( msg.sender ) {
        address _account_ = msg.sender;
        if ( operator_ == _account_ ) {
          revert IERC721_INVALID_APPROVAL( operator_ );
        }

        _operatorApprovals[ _account_ ][ operator_ ] = approved_;
        emit ApprovalForAll( _account_, operator_, approved_ );
      }

      /**
      * @dev See {IERC721-transferFrom}.
      */
      function transferFrom( address from_, address to_, uint256 tokenId_ ) public virtual exists( tokenId_ ) onlyAllowedOperator( msg.sender ) {
        if ( to_ == address( 0 ) ) {
          revert IERC721_INVALID_TRANSFER();
        }

        address _operator_ = msg.sender;
        address _tokenOwner_ = _ownerOf( tokenId_ );
        if ( from_ != _tokenOwner_ ) {
          revert IERC721_INVALID_TRANSFER_FROM( _tokenOwner_, from_, tokenId_ );
        }

        bool _isApproved_ = _isApprovedOrOwner( _tokenOwner_, _operator_, tokenId_ );
        if ( ! _isApproved_ ) {
          revert IERC721_CALLER_NOT_APPROVED( _tokenOwner_, _operator_, tokenId_ );
        }

        _transfer( _tokenOwner_, to_, tokenId_ );
      }
    // ***********
  // **************************************

  // **************************************
  // *****       CONTRACT_OWNER       *****
  // **************************************
    /**
    * @notice Mints `amounts_` tokens and transfers them to `accounts_`.
    * 
    * @param accounts_ : the list of accounts that will receive airdropped tokens
    * @param amounts_  : the amount of tokens each account will receive
    * 
    * Requirements:
    * 
    * - Caller must be the contract owner.
    * - `accounts_` and `amounts_` must have the same length.
    * - There must be enough tokens left in the reserve.
    */
    function airdrop( address[] memory accounts_, uint256[] memory amounts_ ) public onlyOwner {
      uint256 _count_ = accounts_.length;
      if ( _count_ != amounts_.length ) {
        revert ARRAY_LENGTH_MISMATCH();
      }

      uint256 _totalQty_;
      while ( _count_ > 0 ) {
        unchecked {
          --_count_;
        }
        _totalQty_ += amounts_[ _count_ ];
        _mint( accounts_[ _count_ ], amounts_[ _count_ ] );
      }
      if ( _totalQty_ > _reserve ) {
        revert NFT_MAX_RESERVE( _totalQty_, _reserve );
      }
      unchecked {
        _reserve -= _totalQty_;
      }
    }

    /**
    * @notice Reduces the max supply.
    * 
    * @param newMaxSupply_ : the new max supply
    * 
    * Requirements:
    * 
    * - Caller must be the contract owner.
    * - `newMaxSupply_` must be lower than `maxSupply`.
    * - `newMaxSupply_` must be higher than `_nextId`.
    */
    function reduceSupply( uint256 newMaxSupply_ ) public onlyOwner {
      if ( newMaxSupply_ > maxSupply || newMaxSupply_ < _nextId + _reserve ) {
        revert NFT_INVALID_SUPPLY();
      }
      maxSupply = newMaxSupply_;
    }

    /**
    * @notice Updates the baseURI for the tokens.
    * 
    * @param newBaseURI_ : the new baseURI for the tokens
    * 
    * Requirements:
    * 
    * - Caller must be the contract owner.
    */
    function setBaseURI( string memory newBaseURI_ ) public onlyOwner {
      _baseURI = newBaseURI_;
    }

    /**
    * @notice Updates the contract state.
    * 
    * @param newState_ : the new sale state
    * 
    * Requirements:
    * 
    * - Caller must be the contract owner.
    * - `newState_` must be a valid state.
    */
    function setContractState( uint8 newState_ ) external onlyOwner {
      if ( newState_ > PUBLIC_SALE ) {
        revert ContractState_INVALID_STATE( newState_ );
      }
      _setContractState( newState_ );
    }

    /**
    * @notice Updates the royalty recipient and rate.
    * 
    * @param newRoyaltyRecipient_ : the new recipient of the royalties
    * @param newRoyaltyRate_      : the new royalty rate
    * 
    * Requirements:
    * 
    * - Caller must be the contract owner.
    * - `newRoyaltyRate_` cannot be higher than 10,000.
    */
    function setRoyaltyInfo( address newRoyaltyRecipient_, uint256 newRoyaltyRate_ ) external onlyOwner {
      _setRoyaltyInfo( newRoyaltyRecipient_, newRoyaltyRate_ );
    }

    /**
    * @notice Updates the royalty recipient and rate.
    * 
    * @param newPhase1Price_ : the new phase 1 price
    * @param newPhase2Price_ : the new phase 2 price
    * @param newPublicPrice_ : the new public price
    * 
    * Requirements:
    * 
    * - Caller must be the contract owner.
    */
    function setPrices( uint256 newPhase1Price_, uint256 newPhase2Price_, uint256 newPublicPrice_ ) external onlyOwner {
      _salePrice[ PHASE1_SALE ] = newPhase1Price_;
      _salePrice[ PHASE2_SALE ] = newPhase2Price_;
      _salePrice[ PUBLIC_SALE ] = newPublicPrice_;
    }

    /**
    * @notice Updates the contract treasury.
    * 
    * @param newTreasury_ : the new trasury
    * 
    * Requirements:
    * 
    * - Caller must be the contract owner.
    */
    function setTreasury( address newTreasury_ ) external onlyOwner {
      _treasury = newTreasury_;
    }

    /**
    * @notice Updates the whitelist signer.
    * 
    * @param newAdminSigner_ : the new whitelist signer
    *  
    * Requirements:
    * 
    * - Caller must be the contract owner.
    */
    function setWhitelist( address newAdminSigner_ ) external onlyOwner {
      _setWhitelist( newAdminSigner_ );
    }

    /**
    * @notice Withdraws all the money stored in the contract and sends it to the treasury.
    * 
    * Requirements:
    * 
    * - Caller must be the contract owner.
    * - `_treasury` must be able to receive the funds.
    * - Contract must have a positive balance.
    */
    function withdraw() public onlyOwner {
      uint256 _balance_ = address( this ).balance;
      if ( _balance_ == 0 ) {
        revert ETHER_NO_BALANCE();
      }

      address _recipient_ = payable( _treasury );
      ( bool _success_, ) = _recipient_.call{ value: _balance_ }( "" );
      if ( ! _success_ ) {
        revert ETHER_TRANSFER_FAIL( _recipient_, _balance_ );
      }
    }
  // **************************************

  // **************************************
  // *****            VIEW            *****
  // **************************************
    /**
    * @notice Returns the current sale price
    * 
    * @return uint256 the current sale price
    */
    function salePrice() public view returns ( uint256 ) {
      return _salePrice[ getContractState() ];
    }

    /**
    * @notice Returns the total number of tokens minted
    * 
    * @return uint256 the number of tokens that have been minted so far
    */
    function supplyMinted() public view returns ( uint256 ) {
      return _nextId - 1;
    }

    // ***********
    // * IERC721 *
    // ***********
      /**
      * @dev See {IERC721-balanceOf}.
      */
      function balanceOf( address tokenOwner_ ) public view virtual returns ( uint256 ) {
        return _balanceOf( tokenOwner_ );
      }

      /**
      * @dev See {IERC721-getApproved}.
      */
      function getApproved( uint256 tokenId_ ) public view virtual exists( tokenId_ ) returns ( address ) {
        return _approvals[ tokenId_ ];
      }

      /**
      * @dev See {IERC721-isApprovedForAll}.
      */
      function isApprovedForAll( address tokenOwner_, address operator_ ) public view virtual returns ( bool ) {
        return _isApprovedForAll( tokenOwner_, operator_ );
      }

      /**
      * @dev See {IERC721-ownerOf}.
      */
      function ownerOf( uint256 tokenId_ ) public view virtual exists( tokenId_ ) returns ( address ) {
        return _ownerOf( tokenId_ );
      }
    // ***********

    // *********************
    // * IERC721Enumerable *
    // *********************
      /**
      * @dev See {IERC721Enumerable-tokenByIndex}.
      */
      function tokenByIndex( uint256 index_ ) public view virtual override returns ( uint256 ) {
        if ( index_ >= supplyMinted() ) {
          revert IERC721Enumerable_INDEX_OUT_OF_BOUNDS( index_ );
        }
        return index_ + 1;
      }

      /**
      * @dev See {IERC721Enumerable-tokenOfOwnerByIndex}.
      */
      function tokenOfOwnerByIndex( address tokenOwner_, uint256 index_ ) public view virtual override returns ( uint256 tokenId ) {
        if ( index_ >= _balanceOf( tokenOwner_ ) ) {
          revert IERC721Enumerable_OWNER_INDEX_OUT_OF_BOUNDS( tokenOwner_, index_ );
        }

        uint256 _count_ = 0;
        uint256 _nextId_ = supplyMinted();
        for ( uint256 i = 1; i < _nextId_; i++ ) {
          if ( _exists( i ) && tokenOwner_ == _ownerOf( i ) ) {
            if ( index_ == _count_ ) {
              return i;
            }
            _count_++;
          }
        }
      }

      /**
      * @dev See {IERC721Enumerable-totalSupply}.
      */
      function totalSupply() public view virtual override returns ( uint256 ) {
        return _totalSupply();
      }
    // *********************

    // *******************
    // * IERC721Metadata *
    // *******************
      /**
      * @dev See {IERC721Metadata-tokenURI}.
      */
      function tokenURI( uint256 tokenId_ ) public view virtual override exists( tokenId_ ) returns ( string memory ) {
        if ( bytes( _baseURI ).length > 0 ) {
          if ( supplyMinted() == maxSupply ) {
            return string( abi.encodePacked( _baseURI, _toString( tokenId_ ) ) );
          }
          else {
            return _baseURI;
          }
        }
        return _toString( tokenId_ );
      }
    // *******************

    // ***********
    // * IERC165 *
    // ***********
      /**
      * @dev See {IERC165-supportsInterface}.
      */
      function supportsInterface( bytes4 interfaceId_ ) public view override returns ( bool ) {
        return 
          interfaceId_ == type( IERC721 ).interfaceId ||
          interfaceId_ == type( IERC721Enumerable ).interfaceId ||
          interfaceId_ == type( IERC721Metadata ).interfaceId ||
          interfaceId_ == type( IERC173 ).interfaceId ||
          interfaceId_ == type( IERC165 ).interfaceId ||
          interfaceId_ == type( IERC2981 ).interfaceId;
      }
    // ***********

    // ***********
    // * IERC173 *
    // ***********
      function owner() public view override(ERC173, UpdatableOperatorFilterer) returns ( address ) {
        return ERC173.owner();
      }
    // ***********
}

// SPDX-License-Identifier: MIT

/**
* Author: Lambdalf the White
*/

pragma solidity 0.8.17;

interface IArrayErrors {
  /**
  * @dev Thrown when two related arrays have different lengths
  */
  error ARRAY_LENGTH_MISMATCH();
}

// SPDX-License-Identifier: MIT

pragma solidity 0.8.17;

interface IERC165 {
    /// @notice Query if a contract implements an interface
    /// @param interfaceID The interface identifier, as specified in ERC-165
    /// @dev Interface identification is specified in ERC-165. This function
    ///  uses less than 30,000 gas.
    /// @return `true` if the contract implements `interfaceID` and
    ///  `interfaceID` is not 0xffffffff, `false` otherwise
    function supportsInterface(bytes4 interfaceID) external view returns (bool);
}

// SPDX-License-Identifier: MIT

pragma solidity 0.8.17;

/**
* @dev Required interface of an ERC173 compliant contract, as defined in the
* https://eips.ethereum.org/EIPS/eip-173[EIP].
*/
interface IERC173 /* is IERC165 */ {
    /// @dev This emits when ownership of a contract changes.    
    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    /// @notice Get the address of the owner    
    /// @return The address of the owner.
    function owner() view external returns(address);
	
    /// @notice Set the address of the new owner of the contract
    /// @dev Set _newOwner to address(0) to renounce any ownership.
    /// @param _newOwner The address of the new owner of the contract    
    function transferOwnership(address _newOwner) external;	
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

///
/// @dev Interface for the NFT Royalty Standard
///
interface IERC2981 /* is IERC165 */ {
  /// ERC165 bytes to add to interface array - set in parent contract
  /// implementing this standard
  ///
  /// bytes4(keccak256("royaltyInfo(uint256,uint256)")) == 0x2a55205a
  /// bytes4 private constant _INTERFACE_ID_ERC2981 = 0x2a55205a;
  /// _registerInterface(_INTERFACE_ID_ERC2981);

  /// @notice Called with the sale price to determine how much royalty
  //          is owed and to whom.
  /// @param tokenId_ - the NFT asset queried for royalty information
  /// @param salePrice_ - the sale price of the NFT asset specified by tokenId_
  /// @return receiver - address of who should be sent the royalty payment
  /// @return royaltyAmount - the royalty payment amount for salePrice_
  function royaltyInfo( uint256 tokenId_, uint256 salePrice_ ) external view returns ( address receiver, uint256 royaltyAmount );
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (token/ERC721/IERC721.sol)

pragma solidity 0.8.17;

/// @title ERC-721 Non-Fungible Token Standard
/// @dev See https://eips.ethereum.org/EIPS/eip-721
///  Note: the ERC-165 identifier for this interface is 0x80ac58cd.
interface IERC721 /* is IERC165 */ {
  /// @dev This emits when ownership of any NFT changes by any mechanism.
  ///  This event emits when NFTs are created (`from` == 0) and destroyed
  ///  (`to` == 0). Exception: during contract creation, any number of NFTs
  ///  may be created and assigned without emitting Transfer. At the time of
  ///  any transfer, the approved address for that NFT (if any) is reset to none.
  event Transfer( address indexed from_, address indexed to_, uint256 indexed tokenId_ );

  /// @dev This emits when the approved address for an NFT is changed or
  ///  reaffirmed. The zero address indicates there is no approved address.
  ///  When a Transfer event emits, this also indicates that the approved
  ///  address for that NFT (if any) is reset to none.
  event Approval( address indexed owner_, address indexed approved_, uint256 indexed tokenId_ );

  /// @dev This emits when an operator is enabled or disabled for an owner.
  ///  The operator can manage all NFTs of the owner.
  event ApprovalForAll( address indexed owner_, address indexed operator_, bool approved_ );

  /// @notice Count all NFTs assigned to an owner
  /// @dev NFTs assigned to the zero address are considered invalid, and this
  ///  function throws for queries about the zero address.
  /// @param owner_ An address for whom to query the balance
  /// @return The number of NFTs owned by `owner_`, possibly zero
  function balanceOf( address owner_ ) external view returns ( uint256 );

  /// @notice Find the owner of an NFT
  /// @dev NFTs assigned to zero address are considered invalid, and queries
  ///  about them do throw.
  /// @param tokenId_ The identifier for an NFT
  /// @return The address of the owner of the NFT
  function ownerOf( uint256 tokenId_ ) external view returns ( address );

  /// @notice Transfers the ownership of an NFT from one address to another address
  /// @dev Throws unless `msg.sender` is the current owner, an authorized
  ///  operator, or the approved address for this NFT. Throws if `from_` is
  ///  not the current owner. Throws if `to_` is the zero address. Throws if
  ///  `tokenId_` is not a valid NFT. When transfer is complete, this function
  ///  checks if `to_` is a smart contract (code size > 0). If so, it calls
  ///  `onERC721Received` on `to_` and throws if the return value is not
  ///  `bytes4(keccak256("onERC721Received(address,address,uint256,bytes)"))`.
  /// @param from_ The current owner of the NFT
  /// @param to_ The new owner
  /// @param tokenId_ The NFT to transfer
  /// @param data_ Additional data with no specified format, sent in call to `to_`
  function safeTransferFrom( address from_, address to_, uint256 tokenId_, bytes calldata data_ ) external;

  /// @notice Transfers the ownership of an NFT from one address to another address
  /// @dev This works identically to the other function with an extra data parameter,
  ///  except this function just sets data to "".
  /// @param from_ The current owner of the NFT
  /// @param to_ The new owner
  /// @param tokenId_ The NFT to transfer
  function safeTransferFrom( address from_, address to_, uint256 tokenId_ ) external;

  /// @notice Transfer ownership of an NFT -- THE CALLER IS RESPONSIBLE
  ///  TO CONFIRM THAT `to_` IS CAPABLE OF RECEIVING NFTS OR ELSE
  ///  THEY MAY BE PERMANENTLY LOST
  /// @dev Throws unless `msg.sender` is the current owner, an authorized
  ///  operator, or the approved address for this NFT. Throws if `from_` is
  ///  not the current owner. Throws if `to_` is the zero address. Throws if
  ///  `tokenId_` is not a valid NFT.
  /// @param from_ The current owner of the NFT
  /// @param to_ The new owner
  /// @param tokenId_ The NFT to transfer
  function transferFrom( address from_, address to_, uint256 tokenId_ ) external;

  /// @notice Change or reaffirm the approved address for an NFT
  /// @dev The zero address indicates there is no approved address.
  ///  Throws unless `msg.sender` is the current NFT owner, or an authorized
  ///  operator of the current owner.
  /// @param approved_ The new approved NFT controller
  /// @param tokenId_ The NFT to approve
  function approve( address approved_, uint256 tokenId_ ) external;

  /// @notice Enable or disable approval for a third party ("operator") to manage
  ///  all of `msg.sender`'s assets
  /// @dev Emits the ApprovalForAll event. The contract MUST allow
  ///  multiple operators per owner.
  /// @param operator_ Address to add to the set of authorized operators
  /// @param approved_ True if the operator is approved, false to revoke approval
  function setApprovalForAll( address operator_, bool approved_ ) external;

  /// @notice Get the approved address for a single NFT
  /// @dev Throws if `tokenId_` is not a valid NFT.
  /// @param tokenId_ The NFT to find the approved address for
  /// @return The approved address for this NFT, or the zero address if there is none
  function getApproved( uint256 tokenId_ ) external view returns ( address );

  /// @notice Query if an address is an authorized operator for another address
  /// @param owner_ The address that owns the NFTs
  /// @param operator_ The address that acts on behalf of the owner
  /// @return True if `operator_` is an approved operator for `owner_`, false otherwise
  function isApprovedForAll( address owner_, address operator_ ) external view returns ( bool );
}

// SPDX-License-Identifier: MIT

pragma solidity 0.8.17;

/// @title ERC-721 Non-Fungible Token Standard, optional enumeration extension
/// @dev See https://eips.ethereum.org/EIPS/eip-721
///  Note: the ERC-165 identifier for this interface is 0x780e9d63.
interface IERC721Enumerable /* is IERC721 */ {
    /// @notice Count NFTs tracked by this contract
    /// @return A count of valid NFTs tracked by this contract, where each one of
    ///  them has an assigned and queryable owner not equal to the zero address
    function totalSupply() external view returns ( uint256 );

    /// @notice Enumerate valid NFTs
    /// @dev Throws if `index_` >= `totalSupply()`.
    /// @param index_ A counter less than `totalSupply()`
    /// @return The token identifier for the `index_`th NFT,
    ///  (sort order not specified)
    function tokenByIndex( uint256 index_ ) external view returns ( uint256 );

    /// @notice Enumerate NFTs assigned to an owner
    /// @dev Throws if `index_` >= `balanceOf(owner_)` or if
    ///  `owner_` is the zero address, representing invalid NFTs.
    /// @param owner_ An address where we are interested in NFTs owned by them
    /// @param index_ A counter less than `balanceOf(owner_)`
    /// @return The token identifier for the `index_`th NFT assigned to `owner_`,
    ///   (sort order not specified)
    function tokenOfOwnerByIndex( address owner_, uint256 index_ ) external view returns ( uint256 );
}

// SPDX-License-Identifier: MIT

/**
* Author: Lambdalf the White
*/

pragma solidity 0.8.17;

interface IERC721Errors {
  /**
  * @dev Thrown when `operator` has not been approved to manage `tokenId` on behalf of `tokenOwner`.
  * 
  * @param tokenOwner : address owning the token
  * @param operator   : address trying to manage the token
  * @param tokenId    : identifier of the NFT being referenced
  */
  error IERC721_CALLER_NOT_APPROVED( address tokenOwner, address operator, uint256 tokenId );
  /**
  * @dev Thrown when `operator` tries to approve themselves for managing a token they own.
  * 
  * @param operator : address that is trying to approve themselves
  */
  error IERC721_INVALID_APPROVAL( address operator );
  /**
  * @dev Thrown when a token is being transferred to the zero address.
  */
  error IERC721_INVALID_TRANSFER();
  /**
  * @dev Thrown when a token is being transferred from an address that doesn't own it.
  * 
  * @param tokenOwner : address owning the token
  * @param from       : address that the NFT is being transferred from
  * @param tokenId    : identifier of the NFT being referenced
  */
  error IERC721_INVALID_TRANSFER_FROM( address tokenOwner, address from, uint256 tokenId );
  /**
  * @dev Thrown when the requested token doesn't exist.
  * 
  * @param tokenId : identifier of the NFT being referenced
  */
  error IERC721_NONEXISTANT_TOKEN( uint256 tokenId );
  /**
  * @dev Thrown when a token is being safely transferred to a contract unable to handle it.
  * 
  * @param receiver : address unable to receive the token
  */
  error IERC721_NON_ERC721_RECEIVER( address receiver );
  /**
  * @dev Thrown when trying to get the token at an index that doesn't exist.
  * 
  * @param index : the inexistant index
  */
  error IERC721Enumerable_INDEX_OUT_OF_BOUNDS( uint256 index );
  /**
  * @dev Thrown when trying to get the token owned by `tokenOwner` at an index that doesn't exist.
  * 
  * @param tokenOwner : address owning the token
  * @param index      : the inexistant index
  */
  error IERC721Enumerable_OWNER_INDEX_OUT_OF_BOUNDS( address tokenOwner, uint256 index );
}

// SPDX-License-Identifier: MIT

pragma solidity 0.8.17;

/// @title ERC-721 Non-Fungible Token Standard, optional metadata extension
/// @dev See https://eips.ethereum.org/EIPS/eip-721
///  Note: the ERC-165 identifier for this interface is 0x5b5e139f.
interface IERC721Metadata /* is IERC721 */ {
    /// @notice A descriptive name for a collection of NFTs in this contract
    function name() external view returns ( string memory _name );

    /// @notice An abbreviated name for NFTs in this contract
    function symbol() external view returns ( string memory _symbol );

    /// @notice A distinct Uniform Resource Identifier (URI) for a given asset.
    /// @dev Throws if `_tokenId` is not a valid NFT. URIs are defined in RFC
    ///  3986. The URI may point to a JSON file that conforms to the "ERC721
    ///  Metadata JSON Schema".
    function tokenURI( uint256 _tokenId ) external view returns ( string memory );
}

// SPDX-License-Identifier: MIT

pragma solidity 0.8.17;

/// @dev Note: the ERC-165 identifier for this interface is 0x150b7a02.
interface IERC721Receiver {
    /// @notice Handle the receipt of an NFT
    /// @dev The ERC721 smart contract calls this function on the recipient
    ///  after a `transfer`. This function MAY throw to revert and reject the
    ///  transfer. Return of other than the magic value MUST result in the
    ///  transaction being reverted.
    ///  Note: the contract address is always the message sender.
    /// @param operator_ The address which called `safeTransferFrom` function
    /// @param from_ The address which previously owned the token
    /// @param tokenId_ The NFT identifier which is being transferred
    /// @param data_ Additional data with no specified format
    /// @return `bytes4(keccak256("onERC721Received(address,address,uint256,bytes)"))`
    ///  unless throwing
    function onERC721Received( address operator_, address from_, uint256 tokenId_, bytes calldata data_ ) external returns( bytes4 );
}

// SPDX-License-Identifier: MIT

/**
* Author: Lambdalf the White
*/

pragma solidity 0.8.17;

interface IEtherErrors {
  /**
  * @dev Thrown when an incorrect amount of eth is being sent for a payable operation.
  * 
  * @param amountReceived : the amount the contract received
  * @param amountExpected : the actual amount the contract expected to receive
  */
  error ETHER_INCORRECT_PRICE( uint256 amountReceived, uint256 amountExpected );
  /**
  * @dev Thrown when trying to withdraw from the contract with no balance.
  */
  error ETHER_NO_BALANCE();
  /**
  * @dev Thrown when contract fails to send ether to recipient.
  * 
  * @param to     : the recipient of the ether
  * @param amount : the amount of ether being sent
  */
  error ETHER_TRANSFER_FAIL( address to, uint256 amount );
}

// SPDX-License-Identifier: MIT

/**
* Author: Lambdalf the White
*/

pragma solidity 0.8.17;

interface INFTSupplyErrors {
  /**
  * @dev Thrown when trying to mint 0 token.
  */
  error NFT_INVALID_QTY();
  /**
  * @dev Thrown when trying to set max supply to an invalid amount.
  */
  error NFT_INVALID_SUPPLY();
  /**
  * @dev Thrown when trying to mint more tokens than the max allowed per transaction.
  * 
  * @param qtyRequested : the amount of tokens requested
  * @param maxBatch     : the maximum amount that can be minted per transaction
  */
  error NFT_MAX_BATCH( uint256 qtyRequested, uint256 maxBatch );
  /**
  * @dev Thrown when trying to mint more tokens from the reserve than the amount left.
  * 
  * @param qtyRequested : the amount of tokens requested
  * @param reserveLeft  : the amount of tokens left in the reserve
  */
  error NFT_MAX_RESERVE( uint256 qtyRequested, uint256 reserveLeft );
  /**
  * @dev Thrown when trying to mint more tokens than the amount left to be minted (except reserve).
  * 
  * @param qtyRequested    : the amount of tokens requested
  * @param remainingSupply : the amount of tokens left in the reserve
  */
  error NFT_MAX_SUPPLY( uint256 qtyRequested, uint256 remainingSupply );
}

// SPDX-License-Identifier: MIT

/**
* Author: Lambdalf the White
*/

pragma solidity 0.8.17;

abstract contract ContractState {
	// Enum to represent the sale state, defaults to ``PAUSED``.
	uint8 public constant PAUSED = 0;

	// Errors
  /**
  * @dev Thrown when a function is called with the wrong contract state.
  * 
  * @param currentState : the current state of the contract
  */
	error ContractState_INCORRECT_STATE( uint8 currentState );
  /**
  * @dev Thrown when trying to set the contract state to an invalid value.
  * 
  * @param invalidState : the invalid contract state
  */
	error ContractState_INVALID_STATE( uint8 invalidState );

	// The current state of the contract
	uint8 private _contractState;

	/**
	* @dev Emitted when the sale state changes
	*/
	event ContractStateChanged( uint8 indexed previousState, uint8 indexed newState );

	/**
	* @dev Ensures that contract state is `expectedState_`.
	* 
	* @param expectedState_ : the desirable contract state
	*/
	modifier isState( uint8 expectedState_ ) {
		if ( _contractState != expectedState_ ) {
			revert ContractState_INCORRECT_STATE( _contractState );
		}
		_;
	}

	/**
	* @dev Ensures that contract state is not `unexpectedState_`.
	* 
	* @param unexpectedState_ : the undesirable contract state
	*/
	modifier isNotState( uint8 unexpectedState_ ) {
		if ( _contractState == unexpectedState_ ) {
			revert ContractState_INCORRECT_STATE( _contractState );
		}
		_;
	}

	/**
	* @dev Internal function setting the contract state to `newState_`.
	* 
	* Note: Contract state defaults to ``PAUSED``.
	* 			To maintain extendability, this value kept as uint8 instead of enum.
	* 			As a result, it is possible to set the state to an incorrect value.
	* 			To avoid issues, `newState_` should be validated before calling this function
	*/
	function _setContractState( uint8 newState_ ) internal virtual {
		uint8 _previousState_ = _contractState;
		_contractState = newState_;
		emit ContractStateChanged( _previousState_, newState_ );
	}

	/**
	* @dev Returns the current contract state.
	* 
	* @return uint8 : the current contract state
	*/
	function getContractState() public virtual view returns ( uint8 ) {
		return _contractState;
	}
}

// SPDX-License-Identifier: MIT

/**
* Author: Lambdalf the White
*/

pragma solidity 0.8.17;

import "../interfaces/IERC173.sol";

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
abstract contract ERC173 is IERC173 {
	// Errors
  /**
  * @dev Thrown when `operator` is not the contract owner.
  * 
  * @param operator : address trying to use a function reserved to contract owner without authorization
  */
  error IERC173_NOT_OWNER( address operator );

	// The owner of the contract
	address private _owner;

	/**
	* @dev Throws if called by any account other than the owner.
	*/
	modifier onlyOwner() {
		address _sender_ = msg.sender;
		if ( owner() != _sender_ ) {
			revert IERC173_NOT_OWNER( _sender_ );
		}
		_;
	}

	/**
	* @dev Sets the contract owner.
	* 
	* Note: This function needs to be called in the contract constructor to initialize the contract owner, 
	* if it is not, then parts of the contract might be non functional
	* 
	* @param owner_ : address that owns the contract
	*/
	function _setOwner( address owner_ ) internal {
		_owner = owner_;
	}

	/**
	* @dev Returns the address of the current contract owner.
	* 
	* @return address : the current contract owner
	*/
	function owner() public view virtual returns ( address ) {
		return _owner;
	}

	/**
	* @dev Transfers ownership of the contract to `newOwner_`.
	* 
	* @param newOwner_ : address of the new contract owner
	* 
	* Requirements:
	* 
  * - Caller must be the contract owner.
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

pragma solidity 0.8.17;

import "../interfaces/IERC2981.sol";

abstract contract ERC2981 is IERC2981 {
	// Errors
  /**
  * @dev Thrown when the desired royalty rate is higher than 10,000
  * 
  * @param royaltyRate : the desired royalty rate
  * @param royaltyBase : the maximum royalty rate
  */
	error IERC2981_INVALID_ROYALTIES( uint256 royaltyRate, uint256 royaltyBase );

	// Royalty rate is stored out of 10,000 instead of a percentage to allow for
	// up to two digits below the unit such as 2.5% or 1.25%.
	uint private constant ROYALTY_BASE = 10000;

	// Represents the percentage of royalties on each sale on secondary markets.
	// Set to 0 to have no royalties.
	uint256 private _royaltyRate;

	// Address of the recipient of the royalties.
	address private _royaltyRecipient;

	/**
	* @notice Called with the sale price to determine how much royalty is owed and to whom.
	* 
	* Note: This function should be overriden to revert on a query for non existent token.
	* 
  * @param tokenId_   : identifier of the NFT being referenced
  * @param salePrice_ : the sale price of the token sold
  * 
  * @return address : the address receiving the royalties
  * @return uint256 : the royalty payment amount
	*/
	function royaltyInfo( uint256 tokenId_, uint256 salePrice_ ) public view virtual override returns ( address, uint256 ) {
		if ( salePrice_ == 0 || _royaltyRate == 0 ) {
			return ( _royaltyRecipient, 0 );
		}
		uint256 _royaltyAmount_ = _royaltyRate * salePrice_ / ROYALTY_BASE;
		return ( _royaltyRecipient, _royaltyAmount_ );
	}

	/**
	* @dev Sets the royalty rate to `royaltyRate_` and the royalty recipient to `royaltyRecipient_`.
	* 
	* @param royaltyRecipient_ : the address that will receive royalty payments
	* @param royaltyRate_      : the percentage of the sale price that will be taken off as royalties, expressed in Basis Points (100 BP = 1%)
	* 
	* Requirements: 
	* 
	* - `royaltyRate_` cannot be higher than `10,000`;
	*/
	function _setRoyaltyInfo( address royaltyRecipient_, uint256 royaltyRate_ ) internal virtual {
		if ( royaltyRate_ > ROYALTY_BASE ) {
			revert IERC2981_INVALID_ROYALTIES( royaltyRate_, ROYALTY_BASE );
		}
		_royaltyRate      = royaltyRate_;
		_royaltyRecipient = royaltyRecipient_;
	}
}

// SPDX-License-Identifier: MIT

/**
* Author: Lambdalf the White
* Edit  : Squeebo
*/

pragma solidity 0.8.17;

abstract contract Whitelist_ECDSA {
	// Errors
  /**
  * @dev Thrown when trying to query the whitelist while it's not set
  */
	error Whitelist_NOT_SET();
  /**
  * @dev Thrown when `account` has consumed their alloted access and tries to query more
  * 
  * @param account : address trying to access the whitelist
  */
	error Whitelist_CONSUMED( address account );
  /**
  * @dev Thrown when `account` does not have enough alloted access to fulfil their query
  * 
  * @param account : address trying to access the whitelist
  */
	error Whitelist_FORBIDDEN( address account );

	/**
  * @dev A structure representing a signature proof to be decoded by the contract
  */
	struct Proof {
		bytes32 r;
		bytes32 s;
		uint8   v;
	}

	address private _adminSigner;
	mapping( uint8 => mapping ( address => uint256 ) ) private _consumed;

	/**
	* @dev Ensures that `account_` has `qty_` alloted access on the `whitelistId_` whitelist.
	* 
	* @param account_     : the address to validate access
	* @param whitelistId_ : the identifier of the whitelist being queried
	* @param alloted_     : the max amount of whitelist spots allocated
	* @param proof_       : the signature proof to validate whitelist allocation
	* @param qty_         : the amount of whitelist access requested
	*/
	modifier isWhitelisted( address account_, uint8 whitelistId_, uint256 alloted_, Proof memory proof_, uint256 qty_ ) {
		uint256 _allowed_ = checkWhitelistAllowance( account_, whitelistId_, alloted_, proof_ );

		if ( _allowed_ < qty_ ) {
			revert Whitelist_FORBIDDEN( account_ );
		}

		_;
	}

	/**
	* @dev Sets the pass to protect the whitelist.
	* 
	* @param adminSigner_ : the address validating the whitelist signatures
	*/
	function _setWhitelist( address adminSigner_ ) internal virtual {
		_adminSigner = adminSigner_;
	}

	/**
	* @dev Returns the amount that `account_` is allowed to access from the whitelist.
	* 
	* @param account_     : the address to validate access
	* @param whitelistId_ : the identifier of the whitelist being queried
	* @param alloted_     : the max amount of whitelist spots allocated
	* @param proof_       : the signature proof to validate whitelist allocation
	* 
	* @return uint256 : the total amount of whitelist allocation remaining for `account_`
	* 
	* Requirements:
	* 
	* - `_adminSigner` must be set.
	*/
	function checkWhitelistAllowance( address account_, uint8 whitelistId_, uint256 alloted_, Proof memory proof_ ) public view returns ( uint256 ) {
		if ( _adminSigner == address( 0 ) ) {
			revert Whitelist_NOT_SET();
		}

		if ( _consumed[ whitelistId_ ][ account_ ] >= alloted_ ) {
			revert Whitelist_CONSUMED( account_ );
		}

		if ( ! _validateProof( account_, whitelistId_, alloted_, proof_ ) ) {
			revert Whitelist_FORBIDDEN( account_ );
		}

		return alloted_ - _consumed[ whitelistId_ ][ account_ ];
	}

	/**
	* @dev Internal function to decode a signature and compare it with the `_adminSigner`.
	* 
	* @param account_     : the address to validate access
	* @param whitelistId_ : the identifier of the whitelist being queried
	* @param alloted_     : the max amount of whitelist spots allocated
	* @param proof_       : the signature proof to validate whitelist allocation
	* 
	* @return bool : whether the signature is valid or not
	*/ 
	function _validateProof( address account_, uint8 whitelistId_, uint256 alloted_, Proof memory proof_ ) private view returns ( bool ) {
		bytes32 _digest_ = keccak256( abi.encode( whitelistId_, alloted_, account_ ) );
		address _signer_ = ecrecover( _digest_, proof_.v, proof_.r, proof_.s );
		return _signer_ == _adminSigner;
	}

	/**
	* @dev Consumes `amount_` whitelist access passes from `account_`.
	* 
	* @param account_     : the address to consume access from
	* @param whitelistId_ : the identifier of the whitelist being queried
	* @param qty_         : the amount of whitelist access consumed
	* 
	* Note: Before calling this function, eligibility should be checked through {Whitelistable-checkWhitelistAllowance}.
	*/
	function _consumeWhitelist( address account_, uint8 whitelistId_, uint256 qty_ ) internal {
		unchecked {
			_consumed[ whitelistId_ ][ account_ ] += qty_;
		}
	}
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

interface IOperatorFilterRegistry {
    function isOperatorAllowed(address registrant, address operator) external view returns (bool);
    function register(address registrant) external;
    function registerAndSubscribe(address registrant, address subscription) external;
    function registerAndCopyEntries(address registrant, address registrantToCopy) external;
    function unregister(address addr) external;
    function updateOperator(address registrant, address operator, bool filtered) external;
    function updateOperators(address registrant, address[] calldata operators, bool filtered) external;
    function updateCodeHash(address registrant, bytes32 codehash, bool filtered) external;
    function updateCodeHashes(address registrant, bytes32[] calldata codeHashes, bool filtered) external;
    function subscribe(address registrant, address registrantToSubscribe) external;
    function unsubscribe(address registrant, bool copyExistingEntries) external;
    function subscriptionOf(address addr) external returns (address registrant);
    function subscribers(address registrant) external returns (address[] memory);
    function subscriberAt(address registrant, uint256 index) external returns (address);
    function copyEntriesOf(address registrant, address registrantToCopy) external;
    function isOperatorFiltered(address registrant, address operator) external returns (bool);
    function isCodeHashOfFiltered(address registrant, address operatorWithCode) external returns (bool);
    function isCodeHashFiltered(address registrant, bytes32 codeHash) external returns (bool);
    function filteredOperators(address addr) external returns (address[] memory);
    function filteredCodeHashes(address addr) external returns (bytes32[] memory);
    function filteredOperatorAt(address registrant, uint256 index) external returns (address);
    function filteredCodeHashAt(address registrant, uint256 index) external returns (bytes32);
    function isRegistered(address addr) external returns (bool);
    function codeHashOf(address addr) external returns (bytes32);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

import {IOperatorFilterRegistry} from "./IOperatorFilterRegistry.sol";

/**
 * @title  UpdatableOperatorFilterer
 * @notice Abstract contract whose constructor automatically registers and optionally subscribes to or copies another
 *         registrant's entries in the OperatorFilterRegistry. This contract allows the Owner to update the
 *         OperatorFilterRegistry address via updateOperatorFilterRegistryAddress, including to the zero address,
 *         which will bypass registry checks.
 *         Note that OpenSea will still disable creator fee enforcement if filtered operators begin fulfilling orders
 *         on-chain, eg, if the registry is revoked or bypassed.
 * @dev    This smart contract is meant to be inherited by token contracts so they can use the following:
 *         - `onlyAllowedOperator` modifier for `transferFrom` and `safeTransferFrom` methods.
 *         - `onlyAllowedOperatorApproval` modifier for `approve` and `setApprovalForAll` methods.
 */
abstract contract UpdatableOperatorFilterer {
    error OperatorNotAllowed(address operator);
    error OnlyOwner();

    IOperatorFilterRegistry public operatorFilterRegistry;

    constructor(address _registry, address subscriptionOrRegistrantToCopy, bool subscribe) {
        IOperatorFilterRegistry registry = IOperatorFilterRegistry(_registry);
        operatorFilterRegistry = registry;
        // If an inheriting token contract is deployed to a network without the registry deployed, the modifier
        // will not revert, but the contract will need to be registered with the registry once it is deployed in
        // order for the modifier to filter addresses.
        if (address(registry).code.length > 0) {
            if (subscribe) {
                registry.registerAndSubscribe(address(this), subscriptionOrRegistrantToCopy);
            } else {
                if (subscriptionOrRegistrantToCopy != address(0)) {
                    registry.registerAndCopyEntries(address(this), subscriptionOrRegistrantToCopy);
                } else {
                    registry.register(address(this));
                }
            }
        }
    }

    modifier onlyAllowedOperator(address from) virtual {
        // Allow spending tokens from addresses with balance
        // Note that this still allows listings and marketplaces with escrow to transfer tokens if transferred
        // from an EOA.
        if (from != msg.sender) {
            _checkFilterOperator(msg.sender);
        }
        _;
    }

    modifier onlyAllowedOperatorApproval(address operator) virtual {
        _checkFilterOperator(operator);
        _;
    }

    /**
     * @notice Update the address that the contract will make OperatorFilter checks against. When set to the zero
     *         address, checks will be bypassed. OnlyOwner.
     */
    function updateOperatorFilterRegistryAddress(address newRegistry) public virtual {
        if (msg.sender != owner()) {
            revert OnlyOwner();
        }
        operatorFilterRegistry = IOperatorFilterRegistry(newRegistry);
    }

    /**
     * @dev assume the contract has an owner, but leave specific Ownable implementation up to inheriting contract
     */
    function owner() public view virtual returns (address);

    function _checkFilterOperator(address operator) internal view virtual {
        IOperatorFilterRegistry registry = operatorFilterRegistry;
        // Check registry code length to facilitate testing in environments without a deployed registry.
        if (address(registry) != address(0) && address(registry).code.length > 0) {
            if (!registry.isOperatorAllowed(address(this), operator)) {
                revert OperatorNotAllowed(operator);
            }
        }
    }
}