// SPDX-License-Identifier: MIT

/**
* Author: Lambdalf the White
*/

pragma solidity 0.8.17;

import 'EthereumContracts/contracts/interfaces/IArrayErrors.sol';
import 'EthereumContracts/contracts/interfaces/IEtherErrors.sol';
import 'EthereumContracts/contracts/interfaces/IERC721Errors.sol';
import 'EthereumContracts/contracts/interfaces/INFTSupplyErrors.sol';
import 'EthereumContracts/contracts/interfaces/IERC165.sol';
import 'EthereumContracts/contracts/interfaces/IERC20.sol';
import 'EthereumContracts/contracts/interfaces/IERC721.sol';
import 'EthereumContracts/contracts/interfaces/IERC721Metadata.sol';
import 'EthereumContracts/contracts/interfaces/IERC721Enumerable.sol';
import 'EthereumContracts/contracts/interfaces/IERC721Receiver.sol';
import 'EthereumContracts/contracts/interfaces/IERC2981.sol';
import 'EthereumContracts/contracts/utils/ERC173.sol';
import 'EthereumContracts/contracts/utils/ContractState.sol';
import 'EthereumContracts/contracts/utils/Whitelist_ECDSA.sol';

interface Coin is IERC20 {
  function burnFrom( address, uint256 ) external;
  function burn( address, uint256 ) external;
}

contract ZenApeVoxel is 
  IArrayErrors, IEtherErrors, IERC721Errors, INFTSupplyErrors,
  IERC165, IERC721, IERC721Metadata, IERC721Enumerable,
  ERC173, ContractState {

  // List of partner contracts
  enum Partner {
    ZENAPES,
    CYBERKONGZ,
    KAIJU_KINGZ,
    BEARS_DELUXE,
    WULFZ,
    ANONYMICE,
    CYBERKONGZ_BABIES,
    CYBERKONGZ_VX
  }
  // Structure to store token data
  // ~ tokenOwner: address owning the token
  // ~ partner: the partner used to generate the token
  struct TokenData {
    address tokenOwner;
    Partner partner;
  }

  // Errors
  /**
  * @dev Emitted when `account` doesn't own `tokenId` from partner `collection`
  */
  error VX_NOT_OWNER( address account, uint256 tokenId, Partner collection );
  /**
  * @dev Emitted when `account` doesn't own `amount` of coin from partner `collection`
  */
  error VX_INSUFFICIENT_BALANCE( address account, uint256 amount, Partner collection );
  /**
  * @dev Emitted when trying to breed a token alone
  */
  error VX_NO_PARTNER();
  /**
  * @dev Emitted when `tokenId` from partner `collection` has reached max breed quantity
  */
  error VX_MAX_BREED_COUNT( uint256 tokenId, Partner collection, uint256 currentBreedCount );
  /**
  * @dev Emitted when max supply for partner `collection` has been reached
  */
  error VX_MAX_SUPPLY( Partner collection );

  // Constants
  // `name` and `symbol` don't follow constant syntax to match IERC721Metadata interface
  uint8   public constant BREEDING_OPEN = 1;
  string  public constant name = "ZenApe Voxel";
  string  public constant symbol = "VX";

  uint256 private _nextId = 1;
  string  private _baseURI;

  // Mapping from collection ID to its coin contract address
  mapping( Partner => address ) public coinAddresses;
  // Mapping from collection ID to its contract address
  mapping( Partner => address ) public contractAddresses;
  // Mapping from collection ID to its associated ERC20 price
  mapping( Partner => uint256 ) public prices;
  // Mapping from collection ID to its current breeding supply
  mapping( Partner => uint256 ) public supplies;
  // Mapping from collection ID to its associated max breeding supply
  mapping( Partner => uint256 ) public maxSupplies;
  // Mapping from collection ID to its current internal index
  mapping( Partner => uint256[] ) private _partnerIndex;
  // Mapping from collection ID to token ID to number of times it breeded
  mapping( Partner => mapping( uint256 => uint256 ) ) private _partnerBreedCount;
  // Mapping from token ID to approved address
  mapping( uint256 => address ) private _approvals;
  // List of owner addresses
  mapping( uint256 => TokenData ) private _owners;
  // Mapping from owner to operator approvals
  mapping( address => mapping( address => bool ) ) private _operatorApprovals;

  constructor ( address[] memory contracts_, address[] memory coins_ ) {
    _setOwner( msg.sender );
    prices[ Partner.ZENAPES      ] = 500;
    prices[ Partner.CYBERKONGZ   ] = 60;
    prices[ Partner.KAIJU_KINGZ  ] = 300;
    prices[ Partner.BEARS_DELUXE ] = 60;
    prices[ Partner.WULFZ        ] = 300;
    prices[ Partner.ANONYMICE    ] = 6000;

    maxSupplies[ Partner.ZENAPES      ] = 4500;
    maxSupplies[ Partner.CYBERKONGZ   ] = 2500;
    maxSupplies[ Partner.KAIJU_KINGZ  ] = 150;
    maxSupplies[ Partner.BEARS_DELUXE ] = 150;
    maxSupplies[ Partner.WULFZ        ] = 100;
    maxSupplies[ Partner.ANONYMICE    ] = 100;

    // coinAddresses[ Partner.ZENAPES      ] = 0x0591c71E88a74E612aE1759ABc938973421Ba027; // ZEN    => ERC20 + burnFrom
    // coinAddresses[ Partner.CYBERKONGZ   ] = 0x94e496474F1725f1c1824cB5BDb92d7691A4F03a; // BANANA => ERC20 + burnFrom
    // coinAddresses[ Partner.KAIJU_KINGZ  ] = 0x5cd2FAc9702D68dde5a94B1af95962bCFb80fC7d; // RWASTE => ERC20 + burn
    // coinAddresses[ Partner.BEARS_DELUXE ] = 0x40615B82999b8aa46803F11493BeDAB0314EB5E7; // HONEYD => ERC20 + burn
    // coinAddresses[ Partner.WULFZ        ] = 0x3864b787e498BF89eDFf0ED6258393D4CF462855; // AWOO   => ERC20 + burn
    // coinAddresses[ Partner.ANONYMICE    ] = 0x54C4419b7be48889097a70Ef6Bdc47feAC54AEF5; // CHEETH => ERC20 + burnFrom

    // contractAddresses[ Partner.ZENAPES           ] = 0x838804a3dd7c717396a68F94E736eAf76b911632; // ERC721
    // contractAddresses[ Partner.CYBERKONGZ        ] = 0x57a204AA1042f6E66DD7730813f4024114d74f37; // ERC721
    // contractAddresses[ Partner.CYBERKONGZ_BABIES ] = 0x7EA3Cca10668B8346aeC0bf1844A49e995527c8B; // ERC721
    // contractAddresses[ Partner.CYBERKONGZ_VX     ] = 0x57a204AA1042f6E66DD7730813f4024114d74f37; // ERC721
    // contractAddresses[ Partner.KAIJU_KINGZ       ] = 0x0c2E57EFddbA8c768147D1fdF9176a0A6EBd5d83; // ERC721
    // contractAddresses[ Partner.BEARS_DELUXE      ] = 0x4BB33f6E69fd62cf3abbcC6F1F43b94A5D572C2B; // ERC721
    // contractAddresses[ Partner.WULFZ             ] = 0x9712228cEeDA1E2dDdE52Cd5100B88986d1Cb49c; // ERC721
    // contractAddresses[ Partner.ANONYMICE         ] = 0xbad6186E92002E312078b5a1dAfd5ddf63d3f731; // ERC721

    coinAddresses[ Partner.ZENAPES      ] = coins_[ uint256( Partner.ZENAPES      ) ]; // ZEN    => ERC20 + burnFrom
    coinAddresses[ Partner.CYBERKONGZ   ] = coins_[ uint256( Partner.CYBERKONGZ   ) ]; // BANANA => ERC20 + burnFrom
    coinAddresses[ Partner.KAIJU_KINGZ  ] = coins_[ uint256( Partner.KAIJU_KINGZ  ) ]; // RWASTE => ERC20 + burn
    coinAddresses[ Partner.BEARS_DELUXE ] = coins_[ uint256( Partner.BEARS_DELUXE ) ]; // HONEYD => ERC20 + burn
    coinAddresses[ Partner.WULFZ        ] = coins_[ uint256( Partner.WULFZ        ) ]; // AWOO   => ERC20 + burn
    coinAddresses[ Partner.ANONYMICE    ] = coins_[ uint256( Partner.ANONYMICE    ) ]; // CHEETH => ERC20 + burnFrom

    contractAddresses[ Partner.ZENAPES           ] = contracts_[ uint256( Partner.ZENAPES           ) ]; // ERC721
    contractAddresses[ Partner.CYBERKONGZ        ] = contracts_[ uint256( Partner.CYBERKONGZ        ) ]; // ERC721
    contractAddresses[ Partner.CYBERKONGZ_BABIES ] = contracts_[ uint256( Partner.CYBERKONGZ_BABIES ) ]; // ERC721
    contractAddresses[ Partner.CYBERKONGZ_VX     ] = contracts_[ uint256( Partner.CYBERKONGZ_VX     ) ]; // ERC721
    contractAddresses[ Partner.KAIJU_KINGZ       ] = contracts_[ uint256( Partner.KAIJU_KINGZ       ) ]; // ERC721
    contractAddresses[ Partner.BEARS_DELUXE      ] = contracts_[ uint256( Partner.BEARS_DELUXE      ) ]; // ERC721
    contractAddresses[ Partner.WULFZ             ] = contracts_[ uint256( Partner.WULFZ             ) ]; // ERC721
    contractAddresses[ Partner.ANONYMICE         ] = contracts_[ uint256( Partner.ANONYMICE         ) ]; // ERC721
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
  // **************************************

  // **************************************
  // *****          INTERNAL          *****
  // **************************************
    /**
    * @dev Internal function counting partner project breeding.
    * 
    * @param tokenId_    : the token ID of the breeding token.
    * @param collection_ : identifies the partner collection
    */
    function _breedPartner( uint256 tokenId_, Partner collection_ ) internal {
      if ( collection_ == Partner.ZENAPES &&
           _partnerBreedCount[ collection_ ][ tokenId_ ] > 1 ) {
        revert VX_MAX_BREED_COUNT( tokenId_, collection_, _partnerBreedCount[ collection_ ][ tokenId_ ] );
      }
      else if ( collection_ != Partner.ZENAPES &&
                _partnerBreedCount[ collection_ ][ tokenId_ ] > 0 ) {
        revert VX_MAX_BREED_COUNT( tokenId_, collection_, _partnerBreedCount[ collection_ ][ tokenId_ ] );
      }
      unchecked {
        ++_partnerBreedCount[ collection_ ][ tokenId_ ];
      }
    }

    /**
    * @dev Internal function burning the necessary amount of currency from `tokenOwner_`.
    * 
    * @param tokenOwner_ : the token owner to check
    * @param collection_ : identifies the partner collection
    */
    function _currencyBurn( address tokenOwner_, Partner collection_ ) internal {
      if ( Coin( coinAddresses[ collection_ ] ).balanceOf( tokenOwner_ ) < prices[ collection_ ] &&
           Coin( coinAddresses[ collection_ ] ).allowance( tokenOwner_, address( this ) ) < prices[ collection_ ] ) {
        revert VX_INSUFFICIENT_BALANCE( tokenOwner_, prices[ collection_ ], collection_ );
      }
      if ( collection_ == Partner.KAIJU_KINGZ ||
           collection_ == Partner.BEARS_DELUXE ||
           collection_ == Partner.WULFZ ) {
        try Coin( coinAddresses[ collection_ ] ).burn( tokenOwner_, prices[ collection_ ] ) {}
        catch Error( string memory reason ) {
          revert( reason );
        }
      }
      else {
        try Coin( coinAddresses[ collection_ ] ).burnFrom( tokenOwner_, prices[ collection_ ] ) {}
        catch Error( string memory reason ) {
          revert( reason );
        }
      }
    }

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
      return _operatorApprovals[ tokenOwner_ ][ operator_ ];
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
    * @dev Mints a token and transfer it to `to_`.
    * 
    * This internal function can be used to perform token minting.
    * 
    * @param to_  : address receiving the tokens
    * 
    * Emits a {Transfer} event.
    */
    function _mint( address to_, Partner collection_ ) internal {
      _owners[ _nextId ] = TokenData( to_, collection_ );
      emit Transfer( address( 0 ), to_, _nextId );
      _partnerIndex[ collection_ ].push( _nextId );
      unchecked {
        ++supplies[ collection_ ];
        ++_nextId;
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
      return _owners[ tokenId_ ].tokenOwner;
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
    function _toString( uint256 value_ ) internal pure returns ( string memory ) {
      // Inspired by OraclizeAPI's implementation - MIT licence
      // https://github.com/oraclize/ethereum-api/blob/b42146b063c7d6ee1358846c198246239e9360e8/oraclizeAPI_0.4.25.sol
      if ( value_ == 0 ) {
        return "0";
      }
      uint256 _temp_ = value_;
      uint256 _digits_;
      while ( _temp_ != 0 ) {
        ++_digits_;
        _temp_ /= 10;
      }
      bytes memory _buffer_ = new bytes( _digits_ );
      while ( value_ != 0 ) {
        _digits_ -= 1;
        _buffer_[ _digits_ ] = bytes1( uint8( 48 + uint256( value_ % 10 ) ) );
        value_ /= 10;
      }
      return string( _buffer_ );
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
      _owners[ tokenId_ ].tokenOwner = to_;
      _approvals[ tokenId_ ] = address( 0 );

      emit Transfer( from_, to_, tokenId_ );
    }

    /**
    * @dev Internal function that verifies that `tokenOwner_` owns token number `tokenId_` of collection `collection_`.
    * 
    * @param tokenOwner_ : the token owner to check
    * @param tokenId_    : the token ID to check
    * @param collection_ : identifies the partner collection
    */
    function _verifyOwner( address tokenOwner_, uint256 tokenId_, Partner collection_ ) internal view {
      try IERC721( contractAddresses[ collection_ ] ).ownerOf( tokenId_ ) {
        address _tokenOwner_ = IERC721( contractAddresses[ collection_ ] ).ownerOf( tokenId_ );
        if ( tokenOwner_ != _tokenOwner_ ) {
          revert VX_NOT_OWNER( tokenOwner_, tokenId_, collection_ );
        }
      }
      catch Error( string memory reason ) {
        revert( reason );
      }
    }
  // **************************************

  // **************************************
  // *****           PUBLIC           *****
  // **************************************
    /**
    * @dev Breeds a ZenApe with a partner.
    * 
    * @param apeId_      : token ID of the first ape
    * @param partnerId_  : token ID of the second ape
    * @param collection_ : identifies the partner collection
    * 
    * Requirements:
    * 
    * - caller must own `apeId_`.
    * - caller must own `partnerId_` in `collection_`.
    * - max supply for `collection_` partner must not be reached.
    */
    function breed( uint256 apeId_, uint256 partnerId_, Partner collection_ ) public isState( BREEDING_OPEN ) {
      _verifyOwner( msg.sender, apeId_, Partner.ZENAPES );
      _verifyOwner( msg.sender, partnerId_, collection_ );
      if ( collection_ == Partner.ZENAPES &&
           apeId_ == partnerId_ ) {
        revert VX_NO_PARTNER();
      }
      _breedPartner( apeId_, Partner.ZENAPES );
      _breedPartner( partnerId_, collection_ );
      if ( collection_ == Partner.CYBERKONGZ_VX ||
           collection_ == Partner.CYBERKONGZ_BABIES ) {
        if ( supplies[ Partner.CYBERKONGZ ] >= maxSupplies[ Partner.CYBERKONGZ ] ) {
          revert VX_MAX_SUPPLY( Partner.CYBERKONGZ );
        }
        _mint( msg.sender, Partner.CYBERKONGZ );
        _currencyBurn( msg.sender, Partner.CYBERKONGZ );
      }
      else {
        if ( supplies[ collection_ ] >= maxSupplies[ collection_ ] ) {
          revert VX_MAX_SUPPLY( collection_ );
        }
        _mint( msg.sender, collection_ );
        if ( collection_ != Partner.ZENAPES ) {
          _currencyBurn( msg.sender, collection_ );
        }
      }
      _currencyBurn( msg.sender, Partner.ZENAPES );
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
        address _tokenOwner_ = _ownerOf( tokenId_ );
        if ( to_ == _tokenOwner_ ) {
          revert IERC721_INVALID_APPROVAL( to_ );
        }

        bool _isApproved_ = _isApprovedOrOwner( _tokenOwner_, msg.sender, tokenId_ );
        if ( ! _isApproved_ ) {
          revert IERC721_CALLER_NOT_APPROVED( _tokenOwner_, msg.sender, tokenId_ );
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
      function transferFrom( address from_, address to_, uint256 tokenId_ ) public override {
        if ( to_ == address( 0 ) ) {
          revert IERC721_INVALID_TRANSFER();
        }

        address _tokenOwner_ = ownerOf( tokenId_ );
        if ( from_ != _tokenOwner_ ) {
          revert IERC721_INVALID_TRANSFER_FROM( _tokenOwner_, from_, tokenId_ );
        }

        if ( ! _isApprovedOrOwner( _tokenOwner_, msg.sender, tokenId_ ) ) {
          revert IERC721_CALLER_NOT_APPROVED( _tokenOwner_, msg.sender, tokenId_ );
        }

        _transfer( _tokenOwner_, to_, tokenId_ );
      }
    // +---------+
  // **************************************

  // **************************************
  // *****       CONTRACT_OWNER       *****
  // **************************************
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
    function setContractState( uint8 newState_ ) external onlyOwner {
      if ( newState_ > BREEDING_OPEN ) {
        revert ContractState_INVALID_STATE( newState_ );
      }
      _setContractState( newState_ );
    }

    /**
    * @notice Updates a partner collection details.
    * 
    * @param collection_      : identifies the partner collection
    * @param contractAddress_ : the collection contract address
    * @param coinAddress_     : the collection coin contract address
    * @param price_           : the collection coin price
    * @param maxSupply_       : the collection max supply
    * 
    * Requirements:
    * 
    * - Caller must be the contract owner.
    * 
    * Note:
    * 
    * - If collection is {Partner.CYBERKONGZ_VX} or {Partner.CYBERKONGZ_BABIES}, only the contract address is processed
    */
    function updatePartner(
      Partner collection_,
      address contractAddress_,
      address coinAddress_,
      uint256 price_,
      uint256 maxSupply_
    ) external onlyOwner {
      if ( collection_ != Partner.CYBERKONGZ_VX &&
           collection_ != Partner.CYBERKONGZ_BABIES ) {
        coinAddresses[ collection_ ] = coinAddress_;
        maxSupplies[ collection_ ] = maxSupply_;
        prices[ collection_ ] = price_;
      }
      contractAddresses[ collection_ ] = contractAddress_;
    }

    /**
    * @notice Sets the breeding price.
    * 
    * @param zenPrice_    : the amount of $ZEN burned
    * @param bananaPrice_ : the amount of $BANANA burned
    * @param rwastePrice_ : the amount of $RWASTE burned
    * @param honeydPrice_ : the amount of $HONEYD burned
    * @param awooPrice_   : the amount of $AWOO burned
    * @param cheethPrice_ : the amount of $CHEETH burned
    * 
    * Requirements:
    * 
    * - Caller must be the contract owner.
    */
    function updatePrices(
      uint256 zenPrice_,
      uint256 bananaPrice_,
      uint256 rwastePrice_,
      uint256 honeydPrice_,
      uint256 awooPrice_,
      uint256 cheethPrice_
    ) external onlyOwner {
      prices[ Partner.ZENAPES      ] = zenPrice_;
      prices[ Partner.CYBERKONGZ   ] = bananaPrice_;
      prices[ Partner.KAIJU_KINGZ  ] = rwastePrice_;
      prices[ Partner.BEARS_DELUXE ] = honeydPrice_;
      prices[ Partner.WULFZ        ] = awooPrice_;
      prices[ Partner.ANONYMICE    ] = cheethPrice_;
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
    * @notice Returns the total number of times `tokenId_` has been bread
    * 
    * @param collection_ : identifies the partner collection
    * @param tokenId_    : identifies the token within the partner collection
    * 
    * @return uint256 the number of times the identified token has been bread
    */
    function partnerBreedCount( Partner collection_, uint256 tokenId_ ) public view returns ( uint256 ) {
      return _partnerBreedCount[ collection_ ][ tokenId_ ];
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
            if ( _owners[ i ].tokenOwner != address( 0 ) ) {
              _currentTokenOwner_ = _owners[ i ].tokenOwner;
            }
            if ( tokenOwner_ == _currentTokenOwner_ ) {
              ++_count_;
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
        Partner _collection_ = _owners[ tokenId_ ].partner;
        uint256 _collectionIndex_;
        while ( _partnerIndex[ _collection_ ][ _collectionIndex_ ] != tokenId_ ) {
          unchecked {
            ++_collectionIndex_;
          }
        }
        return bytes( _baseURI ).length > 0 ? string( abi.encodePacked( _baseURI, _toString( uint8( _collection_ ) ), "/", _toString( _collectionIndex_ ) ) ) : string( abi.encodePacked( _toString( uint8( _collection_ ) ), "/", _toString( _collectionIndex_ ) ) );
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
        return index_ + 1;
      }

      /**
      * @notice Enumerate NFTs assigned to an owner.
      * 
      * @param tokenOwner_ : the address for which we want to know the tokens owned
      * @param index_      : a counter less than `balanceOf(tokenOwner_)`
      * 
      * @return uint256 : the token identifier of the `index_`th NFT
      * 
      * Requirements:
      * 
      * - `index_` must be lower than `balanceOf(tokenOwner_)`.
      */
      function tokenOfOwnerByIndex( address tokenOwner_, uint256 index_ ) public view override returns ( uint256 ) {
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
              ++_count_;
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
      function supportsInterface( bytes4 interfaceId_ ) public view override returns ( bool ) {
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
// OpenZeppelin Contracts v4.4.1 (token/ERC20/IERC20.sol)
// https://eips.ethereum.org/EIPS/eip-20

pragma solidity 0.8.17;

/**
* @dev Interface of the ERC20 standard as defined in the EIP.
*/
interface IERC20 /* is IERC165 */ {
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
    function transferFrom(
        address sender,
        address recipient,
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