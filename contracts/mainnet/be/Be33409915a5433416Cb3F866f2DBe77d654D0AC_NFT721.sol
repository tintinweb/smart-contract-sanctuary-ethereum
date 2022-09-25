// SPDX-License-Identifier: MIT

/**
* Author: Lambdalf the White
*/

pragma solidity 0.8.17;

import '../EthereumContracts/contracts/interfaces/IERC165.sol';
import '../EthereumContracts/contracts/interfaces/IERC721.sol';
import '../EthereumContracts/contracts/interfaces/IERC721Metadata.sol';
import '../EthereumContracts/contracts/interfaces/IERC721Enumerable.sol';
import '../EthereumContracts/contracts/interfaces/IERC721Receiver.sol';
import '../EthereumContracts/contracts/interfaces/IERC2981.sol';
import '../EthereumContracts/contracts/utils/IOwnable.sol';
import '../EthereumContracts/contracts/utils/IPausable.sol';
import '../EthereumContracts/contracts/utils/ITradable.sol';
import '../EthereumContracts/contracts/utils/IWhitelistable_ECDSA.sol';
import '../EthereumContracts/contracts/utils/ERC2981Base.sol';

contract NFT721 is IERC721, IERC721Metadata, IERC721Enumerable, ERC2981Base, IOwnable, IPausable, ITradable, IWhitelistable_ECDSA, IERC165 {
  // **************************************
  // *****           ERRORS           *****
  // **************************************
    /**
    * @dev Thrown when two related arrays have different lengths
    */
    error ARRAY_LENGTH_MISMATCH();
    /**
    * @dev Thrown when contract fails to send ether to recipient.
    * 
    * @param to     : the recipient of the ether
    * @param amount : the amount of ether being sent
    */
    error ETHER_TRANSFER_FAIL( address to, uint256 amount );
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
    /**
    * @dev Thrown when an incorrect amount of eth is being sent for a payable operation.
    * 
    * @param amountReceived : the amount the contract received
    * @param amountExpected : the actual amount the contract expected to receive
    */
    error INCORRECT_PRICE( uint256 amountReceived, uint256 amountExpected );
    /**
    * @dev Thrown when trying to mint 0 token.
    */
    error NFT_INVALID_QTY();
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
    /**
    * @dev Thrown when trying to withdraw from the contract with no balance.
    */
    error NO_ETHER_BALANCE();
  // **************************************

  /**
  * @dev A structure representing the deployment configuration of the contract.
  * It contains several pieces of information:
  * - reserve          : The amount of tokens that are reserved for airdrops
  * - maxBatch         : The maximum amount of tokens that can be minted in one transaction (for public sale)
  * - maxSupply        : The maximum amount of tokens that can be minted
  * - publicSalePrice  : The price of the tokens during public sale
  * - privateSalePrice : The price of the tokens during private sale
  * - treasury         : The address that will receive the proceeds of the mint
  * - name             : The name of the tokens, for token trackers (i.e. 'Cool Cats')
  * - symbol           : The symbol of the tokens, for token trackers (i.e. 'COOL')
  */
  struct Config {
    uint256 maxBatch;
    uint256 maxSupply;
    uint256 publicSalePrice;
    uint256 privateSalePrice;
    string  name;
    string  symbol;
  }

  // Constants
  uint8   public constant PUBLIC_SALE   = 1;
  uint8   public constant PRIVATE_SALE  = 2;
  uint8   public constant WAITLIST_SALE = 3;
  uint8   public constant CLAIM         = 4;

  uint256 private _nextId = 1;
  uint256 private _reserve;
  string  private _baseURI;
  Config  private _config;
  address private _treasury;

  // Mapping from token ID to approved address
  mapping( uint256 => address ) private _approvals;

  // Mapping from owner to operator approvals
  mapping( address => mapping( address => bool ) ) private _operatorApprovals;

  // List of owner addresses
  mapping( uint256 => address ) private _owners;

  constructor(
    uint256 reserve_,
    uint256 maxBatch_,
    uint256 maxSupply_,
    uint256 publicSalePrice_,
    uint256 privateSalePrice_,
    string memory name_,
    string memory symbol_
  ) {
    Config memory _config_ = Config(
      maxBatch_,
      maxSupply_,
      publicSalePrice_,
      privateSalePrice_,
      name_,
      symbol_
    );
    _init( _config_, reserve_ );
  }

  /**
  * @dev Internal function to initialize the contract.
  * 
  * @param config_ : the  initial configuration of the contract
  */
  function _init( Config memory config_, uint256 reserve_ ) internal {
      _config = config_;
      _reserve = reserve_;
      _treasury = msg.sender;
      _initIOwnable( msg.sender );
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
  // **************************************

  // **************************************
  // *****          INTERNAL          *****
  // **************************************
    /**
    * @dev Internal function to invoke {IERC721Receiver-onERC721Received} on a target address.
    * The call is not executed if the target address is not a contract.
    *
    * @param from_    : address owning the token being transferred
    * @param to_      : address the token is being transferred to
    * @param tokenId_ : identifier of the NFT being referenced
    * @param data_    : optional data to send along with the call
    * 
    * @return bool : whether the call correctly returned the expected magic value
    */
    function _checkOnERC721Received( address from_, address to_, uint256 tokenId_, bytes memory data_ ) internal returns ( bool ) {
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
        try IERC721Receiver( to_ ).onERC721Received( msg.sender, from_, tokenId_, data_ ) returns ( bytes4 retval ) {
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
    * Note: this function must be overriden if tokens are burnable.
    * 
    * @param tokenId_ : identifier of the NFT being referenced
    * 
    * @return bool : whether the token exists
    */
    function _exists( uint256 tokenId_ ) internal view returns ( bool ) {
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
    * @return bool : whether `operator_` is allowed to manage the tokens
    */
    function _isApprovedForAll( address tokenOwner_, address operator_ ) internal view returns ( bool ) {
      return _isRegisteredProxy( tokenOwner_, operator_ ) ||
             _operatorApprovals[ tokenOwner_ ][ operator_ ];
    }

    /**
    * @dev Internal function returning whether `operator_` is allowed to handle `tokenId_`
    * 
    * Note: To avoid multiple checks for the same data, it is assumed 
    * that existence of `tokenId_` has been verified prior via {_exists}
    * If it hasn't been verified, this function might panic
    * 
    * @param operator_ : address that tries to handle the token
    * @param tokenId_  : identifier of the NFT being referenced
    * 
    * @return bool : whether `operator_` is allowed to manage the token
    */
    function _isApprovedOrOwner( address tokenOwner_, address operator_, uint256 tokenId_ ) internal view returns ( bool ) {
      bool _isApproved_ = operator_ == tokenOwner_ ||
                          operator_ == getApproved( tokenId_ ) ||
                          isApprovedForAll( tokenOwner_, operator_ );
      return _isApproved_;
    }

    /**
    * @dev Mints `qty_` tokens and transfers them to `to_`.
    * 
    * This internal function can be used to perform token minting.
    * 
    * @param to_  : address receiving the tokens
    * @param qty_ : the amount of tokens to be minted
    * 
    * Emits one or more {Transfer} event.
    */
    function _mint( address to_, uint256 qty_ ) internal {
      uint256 _firstToken_ = _nextId;
      uint256 _nextStart_ = _firstToken_ + qty_;
      uint256 _lastToken_ = _nextStart_ - 1;

      _owners[ _firstToken_ ] = to_;
      if ( _lastToken_ > _firstToken_ ) {
        _owners[ _lastToken_ ] = to_;
      }
      _nextId = _nextStart_;

      for ( uint256 i = _firstToken_; i < _nextStart_; ++i ) {
        emit Transfer( address( 0 ), to_, i );
      }
    }

    /**
    * @dev Internal function returning the owner of the `tokenId_` token.
    * 
    * @param tokenId_ : identifier of the NFT being referenced
    * 
    * @return address the address of the token owner
    */
    function _ownerOf( uint256 tokenId_ ) internal view returns ( address ) {
      uint256 _index_ = tokenId_;
      address _tokenOwner_ = _owners[ _index_ ];
      while ( _tokenOwner_ == address( 0 ) ) {
        _index_ --;
        _tokenOwner_ = _owners[ _index_ ];
      }

      return _tokenOwner_;
    }

    /**
    * @dev Internal function returning the total supply.
    * 
    * Note: this function must be overriden if tokens are burnable.
    */
    function _totalSupply() internal view returns ( uint256 ) {
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
    * @param from_    : the current owner of the NFT
    * @param to_      : the new owner
    * @param tokenId_ : identifier of the NFT being referenced
    * 
    * Emits a {Transfer} event.
    */
    function _transfer( address from_, address to_, uint256 tokenId_ ) internal {
      _approvals[ tokenId_ ] = address( 0 );
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
    * @notice Mints `qty_` tokens and transfers them to the caller.
    * 
    * @param qty_           : the amount of tokens to be minted
    * @param alloted_       : the maximum alloted for that user
    * @param proof_         : the signature to verify whitelist allocation
    * 
    * Requirements:
    * 
    * - Sale state must be {PRIVATE_SALE}.
    * - Caller must send enough ether to pay for `qty_` tokens at private sale price.
    */
    function mintPrivate( uint256 qty_, uint256 alloted_, Proof memory proof_ ) public payable validateAmount( qty_ ) isState( PRIVATE_SALE ) isWhitelisted( msg.sender, PRIVATE_SALE, alloted_, proof_, qty_ ) {
      uint256 _remainingSupply_ = _config.maxSupply - _reserve - supplyMinted();
      if ( qty_ > _remainingSupply_ ) {
        revert NFT_MAX_SUPPLY( qty_, _remainingSupply_ );
      }

      uint256 _expected_ = qty_ * _config.privateSalePrice;
      if ( _expected_ != msg.value ) {
        revert INCORRECT_PRICE( msg.value, _expected_ );
      }

      _consumeWhitelist( msg.sender, PRIVATE_SALE, qty_ );
      _mint( msg.sender, qty_ );
    }

    /**
    * @notice Mints `qty_` tokens and transfers them to the caller.
    * 
    * @param qty_           : the amount of tokens to be minted
    * @param alloted_       : the maximum alloted for that user
    * @param proof_         : the signature to verify whitelist allocation
    * 
    * Requirements:
    * 
    * - Sale state must be {WAITLIST_SALE}.
    * - Caller must send enough ether to pay for `qty_` tokens at private sale price.
    */
    function mintWaitlist( uint256 qty_, uint256 alloted_, Proof memory proof_ ) public payable validateAmount( qty_ ) isState( WAITLIST_SALE ) isWhitelisted( msg.sender, WAITLIST_SALE, alloted_, proof_, qty_ ) {
      uint256 _remainingSupply_ = _config.maxSupply - _reserve - supplyMinted();
      if ( qty_ > _remainingSupply_ ) {
        revert NFT_MAX_SUPPLY( qty_, _remainingSupply_ );
      }

      uint256 _expected_ = qty_ * _config.privateSalePrice;
      if ( _expected_ != msg.value ) {
        revert INCORRECT_PRICE( msg.value, _expected_ );
      }

      _consumeWhitelist( msg.sender, WAITLIST_SALE, qty_ );
      _mint( msg.sender, qty_ );
    }

    /**
    * @notice Mints `qty_` tokens and transfers them to the caller.
    * 
    * @param qty_           : the amount of tokens to be minted
    * @param alloted_       : the maximum alloted for that user
    * @param proof_         : the signature to verify whitelist allocation
    * 
    * - Sale state must not be {PAUSED}.
    * - Caller must send enough ether to pay for `qty_` tokens at private sale price.
    */
    function claimDualSouls( uint256 qty_, uint256 alloted_, Proof memory proof_ ) public payable validateAmount( qty_ ) isNotState( PAUSED ) isWhitelisted( msg.sender, CLAIM, alloted_, proof_, qty_ ) {
      if ( qty_ > _reserve ) {
        revert NFT_MAX_SUPPLY( qty_, _reserve );
      }

      uint256 _expected_ = qty_ * _config.privateSalePrice;
      if ( _expected_ != msg.value ) {
        revert INCORRECT_PRICE( msg.value, _expected_ );
      }

      unchecked {
        _reserve -= qty_;
      }
      _consumeWhitelist( msg.sender, CLAIM, qty_ );
      _mint( msg.sender, qty_ );
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
      if ( qty_ > _config.maxBatch ) {
        revert NFT_MAX_BATCH( qty_, _config.maxBatch );
      }

      uint256 _remainingSupply_ = _config.maxSupply - _reserve - supplyMinted();
      if ( qty_ > _remainingSupply_ ) {
        revert NFT_MAX_SUPPLY( qty_, _remainingSupply_ );
      }

      uint256 _expected_ = qty_ * _config.publicSalePrice;
      if ( _expected_ != msg.value ) {
        revert INCORRECT_PRICE( msg.value, _expected_ );
      }

      _mint( msg.sender, qty_ );
    }

    // +---------+
    // | IERC721 |
    // +---------+
      /**
      * @notice Gives permission to `to_` to transfer the token number `tokenId_` on behalf of its owner.
      * The approval is cleared when the token is transferred.
      * 
      * Only a single account can be approved at a time, so approving the zero address clears previous approvals.
      * 
      * @param to_      : The new approved NFT controller
      * @param tokenId_ : The NFT to approve
      * 
      * Requirements:
      * 
      * - The token number `tokenId_` must exist.
      * - The caller must own the token or be an approved operator.
      * - Must emit an {Approval} event.
      */
      function approve( address to_, uint256 tokenId_ ) public override exists( tokenId_ ) {
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
      * @notice Transfers the token number `tokenId_` from `from_` to `to_`.
      * 
      * @param from_    : The current owner of the NFT
      * @param to_      : The new owner
      * @param tokenId_ : identifier of the NFT being referenced
      * 
      * Requirements:
      * 
      * - The token number `tokenId_` must exist.
      * - `from_` must be the token owner.
      * - The caller must own the token or be an approved operator.
      * - `to_` must not be the zero address.
      * - If `to_` is a contract, it must implement {IERC721Receiver-onERC721Received} with a return value of `bytes4(keccak256("onERC721Received(address,address,uint256,bytes)"))`,
      * - Must emit a {Transfer} event.
      */
      function safeTransferFrom( address from_, address to_, uint256 tokenId_ ) public override {
        safeTransferFrom( from_, to_, tokenId_, "" );
      }

      /**
      * @notice Transfers the token number `tokenId_` from `from_` to `to_`.
      * 
      * @param from_    : The current owner of the NFT
      * @param to_      : The new owner
      * @param tokenId_ : identifier of the NFT being referenced
      * @param data_    : Additional data with no specified format, sent in call to `to_`
      * 
      * Requirements:
      * 
      * - The token number `tokenId_` must exist.
      * - `from_` must be the token owner.
      * - The caller must own the token or be an approved operator.
      * - `to_` must not be the zero address.
      * - If `to_` is a contract, it must implement {IERC721Receiver-onERC721Received} with a return value of `bytes4(keccak256("onERC721Received(address,address,uint256,bytes)"))`,
      * - Must emit a {Transfer} event.
      */
      function safeTransferFrom( address from_, address to_, uint256 tokenId_, bytes memory data_ ) public override {
        transferFrom( from_, to_, tokenId_ );
        if ( ! _checkOnERC721Received( from_, to_, tokenId_, data_ ) ) {
          revert IERC721_NON_ERC721_RECEIVER( to_ );
        }
      }

      /**
      * @notice Allows or disallows `operator_` to manage the caller's tokens on their behalf.
      * 
      * @param operator_ : Address to add to the set of authorized operators
      * @param approved_ : True if the operator is approved, false to revoke approval
      * 
      * Requirements:
      * 
      * - Must emit an {ApprovalForAll} event.
      */
      function setApprovalForAll( address operator_, bool approved_ ) public override {
        address _account_ = msg.sender;
        if ( operator_ == _account_ ) {
          revert IERC721_INVALID_APPROVAL( operator_ );
        }

        _operatorApprovals[ _account_ ][ operator_ ] = approved_;
        emit ApprovalForAll( _account_, operator_, approved_ );
      }

      /**
      * @notice Transfers the token number `tokenId_` from `from_` to `to_`.
      * 
      * @param from_    : the current owner of the NFT
      * @param to_      : the new owner
      * @param tokenId_ : identifier of the NFT being referenced
      * 
      * Requirements:
      * 
      * - The token number `tokenId_` must exist.
      * - `from_` must be the token owner.
      * - The caller must own the token or be an approved operator.
      * - `to_` must not be the zero address.
      * - Must emit a {Transfer} event.
      */
      function transferFrom( address from_, address to_, uint256 tokenId_ ) public override exists( tokenId_ ) {
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
    // +---------+
  // **************************************

  // **************************************
  // *****       CONTRACT_OWNER       *****
  // **************************************
    /**
    * @dev Adds a proxy registry to the list of accepted proxy registries.
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
      uint256 _amountsLen_ = amounts_.length;
      if ( accounts_.length != _amountsLen_ ) {
        revert ARRAY_LENGTH_MISMATCH();
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

      uint256 _count_ = _amountsLen_;
      while ( _count_ > 0 ) {
        unchecked {
          _count_ --;
        }
        _mint( accounts_[ _count_ ], amounts_[ _count_ ] );
      }
    }

    /**
    * @dev Removes a proxy registry from the list of accepted proxy registries.
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
    * @notice Updates the baseURI for the tokens.
    * 
    * @param baseURI_ : the new baseURI for the tokens
    * 
    * Requirements:
    * 
    * - Caller must be the contract owner.
    */
    function setBaseURI( string memory baseURI_ ) public onlyOwner {
      _baseURI = baseURI_;
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
    function setPauseState( uint8 newState_ ) external onlyOwner {
      if ( newState_ > CLAIM ) {
        revert IPausable_INVALID_STATE( newState_ );
      }
      _setPauseState( newState_ );
    }

    /**
    * @notice Updates the royalty recipient and rate.
    * 
    * @param royaltyRecipient_ : the new recipient of the royalties
    * @param royaltyRate_      : the new royalty rate
    * 
    * Requirements:
    * 
    * - Caller must be the contract owner.
    * - `royaltyRate_` cannot be higher than 10,000.
    */
    function setRoyaltyInfo( address royaltyRecipient_, uint256 royaltyRate_ ) external onlyOwner {
      _setRoyaltyInfo( royaltyRecipient_, royaltyRate_ );
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
    * @param adminSigner_ : the new whitelist signer
    *  
    * Requirements:
    * 
    * - Caller must be the contract owner.
    */
    function setWhitelist( address adminSigner_ ) external onlyOwner {
      _setWhitelist( adminSigner_ );
    }

    /**
    * @notice Withdraws all the money stored in the contract and sends it to the treasury.
    * 
    * Requirements:
    * 
    * - Caller must be the contract owner.
    * - Contract must have a positive balance.
    */
    function withdraw() public onlyOwner {
      uint256 _balance_ = address( this ).balance;
      if ( _balance_ == 0 ) {
        revert NO_ETHER_BALANCE();
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
    * @notice Returns the total number of tokens minted
    * 
    * @return uint256 the number of tokens that have been minted so far
    */
    function supplyMinted() public view returns ( uint256 ) {
      return _nextId - 1;
    }

	/**
	* @notice Called with the sale price to determine how much royalty is owed and to whom.
	* 
	* @param tokenId_   : identifier of the NFT being referenced
	* @param salePrice_ : the sale price of the token sold
	* 
	* @return address : the address receiving the royalties
	* @return uint256 : the royalty payment amount
	*/
	function royaltyInfo( uint256 tokenId_, uint256 salePrice_ ) public view virtual override exists( tokenId_ ) returns ( address, uint256 ) {
		return super.royaltyInfo( tokenId_, salePrice_ );
	}

    // +---------+
    // | IERC721 |
    // +---------+
      /**
      * @notice Returns the number of tokens in `tokenOwner_`'s account.
      * 
      * @param tokenOwner_ : address that owns tokens
      * 
      * @return uint256 : the nomber of tokens owned by `tokenOwner_`
      */
      function balanceOf( address tokenOwner_ ) public view override returns ( uint256 ) {
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
      * @notice Returns the address that has been specifically allowed to manage `tokenId_` on behalf of its owner.
      * 
      * @param tokenId_ : the NFT that has been approved
      * 
      * @return address : the address allowed to manage `tokenId_`
      * 
      * Requirements:
      * 
      * - `tokenId_` must exist.
      * 
      * Note: See {Approve}
      */
      function getApproved( uint256 tokenId_ ) public view override exists( tokenId_ ) returns ( address ) {
        return _approvals[ tokenId_ ];
      }

      /**
      * @notice Returns whether `operator_` is allowed to manage tokens on behalf of `tokenOwner_`.
      * 
      * @param tokenOwner_ : address that owns tokens
      * @param operator_   : address that tries to manage tokens
      * 
      * @return bool : whether `operator_` is allowed to handle `tokenOwner`'s tokens
      * 
      * Note: See {setApprovalForAll}
      */
      function isApprovedForAll( address tokenOwner_, address operator_ ) public view override returns ( bool ) {
        return _operatorApprovals[ tokenOwner_ ][ operator_ ];
      }

      /**
      * @notice Returns the owner of the token number `tokenId_`.
      * 
      * @param tokenId_ : the NFT to verify ownership of
      * 
      * @return address : the owner of token number `tokenId_`
      * 
      * Requirements:
      * 
      * - `tokenId_` must exist.
      */
      function ownerOf( uint256 tokenId_ ) public view override exists( tokenId_ ) returns ( address ) {
        return _ownerOf( tokenId_ );
      }
    // +---------+

    // +-----------------+
    // | IERC721Metadata |
    // +-----------------+
      /**
      * @notice A descriptive name for a collection of NFTs in this contract.
      * 
      * @return string : The name of the collection
      */
      function name() public view override returns ( string memory ) {
        return _config.name;
      }

      /**
      * @notice An abbreviated name for NFTs in this contract.
      * 
      * @return string : The abbreviated name of the collection
      */
      function symbol() public view override returns ( string memory ) {
        return _config.symbol;
      }

      /**
      * @notice A distinct Uniform Resource Identifier (URI) for a given asset.
      * 
      * @param tokenId_ : the NFT that has been approved
      * 
      * @return string : the URI of the token
      * 
      * Requirements:
      * 
      * - `tokenId_` must exist.
      */
      function tokenURI( uint256 tokenId_ ) public view override exists( tokenId_ ) returns ( string memory ) {
        return bytes( _baseURI ).length > 0 ? string( abi.encodePacked( _baseURI, _toString( tokenId_ ) ) ) : _toString( tokenId_ );
      }
    // +---------+

    // +-------------------+
    // | IERC721Enumerable |
    // +-------------------+
      /**
      * @notice Enumerate valid NFTs.
      * 
      * @param index_ : a counter less than `totalSupply()`
      * 
      * @return uint256 : the token identifier of the `index_`th NFT
      * 
      * Requirements:
      * 
      * - `index_` must be lower than `totalSupply()`.
      */
      function tokenByIndex( uint256 index_ ) public view override returns ( uint256 ) {
        if ( index_ >= supplyMinted() ) {
          revert IERC721Enumerable_INDEX_OUT_OF_BOUNDS( index_ );
        }
        return index_;
      }

      /**
      * @notice Enumerate NFTs assigned to an owner.
      * 
      * @param tokenOwner_ : the address for which we want to know the tokens owned
      * @param index_      : a counter less than `balanceOf(tokenOwner_)`
      * 
      * @return tokenId : the token identifier of the `index_`th NFT
      * 
      * Requirements:
      * 
      * - `index_` must be lower than `balanceOf(tokenOwner_)`.
      */
      function tokenOfOwnerByIndex( address tokenOwner_, uint256 index_ ) public view override returns ( uint256 tokenId ) {
        if ( index_ >= balanceOf( tokenOwner_ ) ) {
          revert IERC721Enumerable_OWNER_INDEX_OUT_OF_BOUNDS( tokenOwner_, index_ );
        }

        uint256 _count_ = 0;
        for ( uint256 i = 1; i < _nextId; ++i ) {
          if ( _exists( i ) && tokenOwner_ == _ownerOf( i ) ) {
            if ( index_ == _count_ ) {
              return i;
            }
            unchecked {
              _count_++;
            }
          }
        }
      }

      /**
      * @notice Count NFTs tracked by this contract.
      * 
      * @return the total number of existing NFTs tracked by the contract
      */
      function totalSupply() public view override returns ( uint256 ) {
        return _totalSupply();
      }
    // +---------+

    // +---------+
    // | IERC165 |
    // +---------+
      /**
      * @notice Query if a contract implements an interface.
      * @dev see https://eips.ethereum.org/EIPS/eip-165
      * 
      * @param interfaceId_ : the interface identifier, as specified in ERC-165
      * 
      * @return bool : true if the contract implements the specified interface, false otherwise
      * 
      * Requirements:
      * 
      * - This function must use less than 30,000 gas.
      */
      function supportsInterface( bytes4 interfaceId_ ) public pure override returns ( bool ) {
        return 
          interfaceId_ == type( IERC721 ).interfaceId ||
          interfaceId_ == type( IERC721Enumerable ).interfaceId ||
          interfaceId_ == type( IERC721Metadata ).interfaceId ||
          interfaceId_ == type( IERC173 ).interfaceId ||
          interfaceId_ == type( IERC165 ).interfaceId ||
          interfaceId_ == type( IERC2981 ).interfaceId;
      }
    // +---------+
  // **************************************
}

// SPDX-License-Identifier: MIT

/**
* Author: Lambdalf the White
*/

pragma solidity 0.8.17;

import "../interfaces/IERC2981.sol";

abstract contract ERC2981Base is IERC2981 {
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
	*  param tokenId_   : identifier of the NFT being referenced
	* @param salePrice_ : the sale price of the token sold
	* 
	* @return address : the address receiving the royalties
	* @return uint256 : the royalty payment amount
	*/
	function royaltyInfo( uint256 /* tokenId_ */, uint256 salePrice_ ) public view virtual override returns ( address, uint256 ) {
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

abstract contract IWhitelistable_ECDSA {
	// Errors
  /**
  * @dev Thrown when trying to query the whitelist while it's not set
  */
	error IWhitelistable_NOT_SET();
  /**
  * @dev Thrown when `account` has consumed their alloted access and tries to query more
  * 
  * @param account : address trying to access the whitelist
  */
	error IWhitelistable_CONSUMED( address account );
  /**
  * @dev Thrown when `account` does not have enough alloted access to fulfil their query
  * 
  * @param account : address trying to access the whitelist
  */
	error IWhitelistable_FORBIDDEN( address account );

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
			revert IWhitelistable_FORBIDDEN( account_ );
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
			revert IWhitelistable_NOT_SET();
		}

		if ( _consumed[ whitelistId_ ][ account_ ] >= alloted_ ) {
			revert IWhitelistable_CONSUMED( account_ );
		}

		if ( ! _validateProof( account_, whitelistId_, alloted_, proof_ ) ) {
			revert IWhitelistable_FORBIDDEN( account_ );
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
	* Note: Before calling this function, eligibility should be checked through {IWhitelistable-checkWhitelistAllowance}.
	*/
	function _consumeWhitelist( address account_, uint8 whitelistId_, uint256 qty_ ) internal {
		unchecked {
			_consumed[ whitelistId_ ][ account_ ] += qty_;
		}
	}
}

// SPDX-License-Identifier: MIT

/**
* Author: Lambdalf the White
*/

pragma solidity 0.8.17;

contract OwnableDelegateProxy {}

contract ProxyRegistry {
	mapping( address => OwnableDelegateProxy ) public proxies;
}

abstract contract ITradable {
	// list of accepted proxy registries
	address[] public proxyRegistries;

	/**
	* @dev Internal function that adds a proxy registry to the list of accepted proxy registries.
	* 
	* @param proxyRegistryAddress_ : the address of the new proxy registry
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
	* 
	* @param proxyRegistryAddress_ : the address of the proxy registry to remove
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
	* @dev Internal function that checks if `operator_` is a registered proxy for `tokenOwner_`.
	* 
	* Note: Use this function to allow whitelisting of registered proxy.
	* 
	* @param tokenOwner_ : the address the proxy operates on the behalf of
	* @param operator_   : the proxy address that operates on behalf of the token owner
	* 
	* @return bool : whether `operator_` is allowed to operate on behalf of `tokenOwner_` or not
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

pragma solidity 0.8.17;

abstract contract IPausable {
	// Enum to represent the sale state, defaults to ``PAUSED``.
	uint8 public constant PAUSED = 0;

	// Errors
  /**
  * @dev Thrown when a function is called with the wrong contract state.
  * 
  * @param currentState : the current state of the contract
  */
	error IPausable_INCORRECT_STATE( uint8 currentState );
  /**
  * @dev Thrown when trying to set the contract state to an invalid value.
  * 
  * @param invalidState : the invalid contract state
  */
	error IPausable_INVALID_STATE( uint8 invalidState );

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
			revert IPausable_INCORRECT_STATE( _contractState );
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
			revert IPausable_INCORRECT_STATE( _contractState );
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
	function _setPauseState( uint8 newState_ ) internal virtual {
		uint8 _previousState_ = _contractState;
		_contractState = newState_;
		emit ContractStateChanged( _previousState_, newState_ );
	}

	/**
	* @dev Returns the current contract state.
	* 
	* @return uint8 : the current contract state
	*/
	function getPauseState() public virtual view returns ( uint8 ) {
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
abstract contract IOwnable is IERC173 {
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
	* @dev Initializes the contract setting `owner_` as the initial owner.
	* 
	* Note: This function needs to be called in the contract constructor to initialize the contract owner, 
	* if it is not, then parts of the contract might be non functional
	* 
	* @param owner_ : address that owns the contract
	*/
	function _initIOwnable( address owner_ ) internal {
		_owner = owner_;
	}

	/**
	* @dev Returns the address of the current owner.
	* 
	* @return address : the current contract owner
	*/
	function owner() public view virtual returns ( address ) {
		return _owner;
	}

	/**
	* @dev Transfers ownership of the contract to `newOwner`.
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