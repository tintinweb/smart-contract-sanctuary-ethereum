/**
 *Submitted for verification at Etherscan.io on 2022-04-16
*/

// SPDX-License-Identifier: MIT

// File: contracts/MerkleProof.sol


// OpenZeppelin Contracts (last updated v4.5.0) (utils/cryptography/MerkleProof.sol)

pragma solidity ^0.8.0;

/**
 * @dev These functions deal with verification of Merkle Trees proofs.
 *
 * The proofs can be generated using the JavaScript library
 * https://github.com/miguelmota/merkletreejs[merkletreejs].
 * Note: the hashing algorithm should be keccak256 and pair sorting should be enabled.
 *
 * See `test/utils/cryptography/MerkleProof.test.js` for some examples.
 */
library MerkleProof {
    /**
     * @dev Returns true if a `leaf` can be proved to be a part of a Merkle tree
     * defined by `root`. For this, a `proof` must be provided, containing
     * sibling hashes on the branch from the leaf to the root of the tree. Each
     * pair of leaves and each pair of pre-images are assumed to be sorted.
     */
    function verify(
        bytes32[] memory proof,
        bytes32 root,
        bytes32 leaf
    ) internal pure returns (bool) {
        return processProof(proof, leaf) == root;
    }

    /**
     * @dev Returns the rebuilt hash obtained by traversing a Merklee tree up
     * from `leaf` using `proof`. A `proof` is valid if and only if the rebuilt
     * hash matches the root of the tree. When processing the proof, the pairs
     * of leafs & pre-images are assumed to be sorted.
     *
     * _Available since v4.4._
     */
    function processProof(bytes32[] memory proof, bytes32 leaf) internal pure returns (bytes32) {
        bytes32 computedHash = leaf;
        for (uint256 i = 0; i < proof.length; i++) {
            bytes32 proofElement = proof[i];
            if (computedHash <= proofElement) {
                // Hash(current computed hash + current element of the proof)
                computedHash = _efficientHash(computedHash, proofElement);
            } else {
                // Hash(current element of the proof + current computed hash)
                computedHash = _efficientHash(proofElement, computedHash);
            }
        }
        return computedHash;
    }

    function _efficientHash(bytes32 a, bytes32 b) private pure returns (bytes32 value) {
        assembly {
            mstore(0x00, a)
            mstore(0x20, b)
            value := keccak256(0x00, 0x40)
        }
    }
}

// File: contracts/IWhitelistable.sol



/**
* Author: Lambdalf the White
* Edit  : Squeebo
*/

pragma solidity 0.8.10;


abstract contract IWhitelistable {
	// Errors
	error IWhitelistable_NOT_SET();
	error IWhitelistable_CONSUMED();
	error IWhitelistable_FORBIDDEN();
	error IWhitelistable_NO_ALLOWANCE();

	bytes32 private _root;
	mapping( address => uint256 ) private _consumed;

	modifier isWhitelisted( address account_, bytes32[] memory proof_, uint256 passMax_, uint256 qty_ ) {
		if ( qty_ > passMax_ ) {
			revert IWhitelistable_FORBIDDEN();
		}

		uint256 _allowed_ = _checkWhitelistAllowance( account_, proof_, passMax_ );

		if ( _allowed_ < qty_ ) {
			revert IWhitelistable_FORBIDDEN();
		}

		_;
	}

	/**
	* @dev Sets the pass to protect the whitelist.
	*/
	function _setWhitelist( bytes32 root_ ) internal virtual {
		_root = root_;
	}

	/**
	* @dev Returns the amount that `account_` is allowed to access from the whitelist.
	* 
	* Requirements:
	* 
	* - `_root` must be set.
	* 
	* See {IWhitelistable-_consumeWhitelist}.
	*/
	function _checkWhitelistAllowance( address account_, bytes32[] memory proof_, uint256 passMax_ ) internal view returns ( uint256 ) {
		if ( _root == 0 ) {
			revert IWhitelistable_NOT_SET();
		}

		if ( _consumed[ account_ ] >= passMax_ ) {
			revert IWhitelistable_CONSUMED();
		}

		if ( ! _computeProof( account_, proof_ ) ) {
			revert IWhitelistable_FORBIDDEN();
		}

		uint256 _res_;
		unchecked {
			_res_ = passMax_ - _consumed[ account_ ];
		}

		return _res_;
	}

	function _computeProof( address account_, bytes32[] memory proof_ ) private view returns ( bool ) {
		bytes32 leaf = keccak256(abi.encodePacked(account_));
		return MerkleProof.processProof( proof_, leaf ) == _root;
	}

	/**
	* @dev Consumes `amount_` pass passes from `account_`.
	* 
	* Note: Before calling this function, eligibility should be checked through {IWhitelistable-checkWhitelistAllowance}.
	*/
	function _consumeWhitelist( address account_, uint256 qty_ ) internal {
		unchecked {
			_consumed[ account_ ] += qty_;
		}
	}
}

// File: contracts/ITradable.sol



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

	function _setProxyRegistry( address proxyRegistryAddress_ ) internal {
		_proxyRegistries.push( proxyRegistryAddress_ );
	}

	/**
	* @dev Checks if `operator_` is the registered proxy for `tokenOwner_`.
	* 
	* Note: Use this function to allow whitelisting of registered proxy.
	*/
	function _isRegisteredProxy( address tokenOwner_, address operator_ ) internal view returns ( bool ) {
		for ( uint256 i; i < _proxyRegistries.length; i++ ) {
			ProxyRegistry _proxyRegistry_ = ProxyRegistry( _proxyRegistries[ i ] );
			if ( address( _proxyRegistry_.proxies( tokenOwner_ ) ) == operator_ ) {
				return true;
			}
		}
		return false;
	}
}
// File: contracts/IPausable.sol



/**
* Author: Lambdalf the White
*/

pragma solidity 0.8.10;

abstract contract IPausable {
	// Errors
	error IPausable_SALE_NOT_CLOSED();
	error IPausable_SALE_NOT_OPEN();
	error IPausable_PRESALE_NOT_OPEN();

	// Enum to represent the sale state, defaults to ``CLOSED``.
	enum SaleState { CLOSED, PRESALE, SALE }

	// The current state of the contract
	SaleState public saleState;

	/**
	* @dev Emitted when the sale state changes
	*/
	event SaleStateChanged( SaleState indexed previousState, SaleState indexed newState );

	/**
	* @dev Sale state can have one of 3 values, ``CLOSED``, ``PRESALE``, or ``SALE``.
	*/
	function _setSaleState( SaleState newState_ ) internal virtual {
		SaleState _previousState_ = saleState;
		saleState = newState_;
		emit SaleStateChanged( _previousState_, newState_ );
	}

	/**
	* @dev Throws if sale state is not ``CLOSED``.
	*/
	modifier saleClosed {
		if ( saleState != SaleState.CLOSED ) {
			revert IPausable_SALE_NOT_CLOSED();
		}
		_;
	}

	/**
	* @dev Throws if sale state is not ``SALE``.
	*/
	modifier saleOpen {
		if ( saleState != SaleState.SALE ) {
			revert IPausable_SALE_NOT_OPEN();
		}
		_;
	}

	/**
	* @dev Throws if sale state is not ``PRESALE``.
	*/
	modifier presaleOpen {
		if ( saleState != SaleState.PRESALE ) {
			revert IPausable_PRESALE_NOT_OPEN();
		}
		_;
	}
}

// File: contracts/IOwnable.sol



/**
* Author: Lambdalf the White
*/

pragma solidity 0.8.10;

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
abstract contract IOwnable {
	// Errors
	error IOwnable_NOT_OWNER();

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
		if ( owner() != msg.sender ) {
			revert IOwnable_NOT_OWNER();
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

// File: contracts/IERC2981.sol


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

// File: contracts/Context.sol


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

// File: contracts/IERC721Receiver.sol


// OpenZeppelin Contracts v4.4.1 (token/ERC721/IERC721Receiver.sol)

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
    function onERC721Received(
        address operator,
        address from,
        uint256 tokenId,
        bytes calldata data
    ) external returns (bytes4);
}

// File: contracts/IERC165.sol


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

// File: contracts/ERC2981Base.sol



/**
* Author: Lambdalf the White
*/

pragma solidity 0.8.10;



abstract contract ERC2981Base is IERC165, IERC2981 {
	// Errors
	error IERC2981_INVALID_ROYALTIES();

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
			revert IERC2981_INVALID_ROYALTIES();
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

// File: contracts/IERC721.sol


// OpenZeppelin Contracts v4.4.1 (token/ERC721/IERC721.sol)

pragma solidity ^0.8.0;


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

// File: contracts/IERC721Metadata.sol


// OpenZeppelin Contracts v4.4.1 (token/ERC721/extensions/IERC721Metadata.sol)

pragma solidity ^0.8.0;


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

// File: contracts/ERC721Batch.sol



/**
* Author: Lambdalf the White
*/

pragma solidity 0.8.10;




/**
* @dev Required interface of an ERC721 compliant contract.
*/
abstract contract ERC721Batch is Context, IERC721Metadata {
	// Errors
	error IERC721_APPROVE_OWNER();
	error IERC721_APPROVE_CALLER();
	error IERC721_CALLER_NOT_APPROVED();
	error IERC721_NONEXISTANT_TOKEN();
	error IERC721_NON_ERC721_RECEIVER();
	error IERC721_NULL_ADDRESS_BALANCE();
	error IERC721_NULL_ADDRESS_TRANSFER();

	// Token name
	string private _name;

	// Token symbol
	string private _symbol;

	// Token Base URI
	string private _baseURI;

	// Token IDs
	uint256 private _numTokens;

	// List of owner addresses
	mapping( uint256 => address ) private _owners;

	// Mapping from token ID to approved address
	mapping( uint256 => address ) private _tokenApprovals;

	// Mapping from owner to operator approvals
	mapping( address => mapping( address => bool ) ) private _operatorApprovals;

	/**
	* @dev Ensures the token exist. 
	* A token exists if it has been minted and is not owned by the null address.
	* 
	* @param tokenId_ uint256 ID of the token to verify
	*/
	modifier exists( uint256 tokenId_ ) {
		if ( ! _exists( tokenId_ ) ) {
			revert IERC721_NONEXISTANT_TOKEN();
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

			uint256 _supplyMinted_ = _supplyMinted();
			uint256 _count_ = 0;
			address _currentTokenOwner_;
			for ( uint256 i; i < _supplyMinted_; i++ ) {
				if ( _owners[ i ] != address( 0 ) ) {
					_currentTokenOwner_ = _owners[ i ];
				}
				if ( tokenOwner_ == _currentTokenOwner_ ) {
					_count_++;
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
						revert IERC721_NON_ERC721_RECEIVER();
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
			return tokenId_ < _numTokens;
		}

		/**
		* @dev Initializes the contract by setting a `name` and a `symbol` to the token collection.
		*/
		function _initERC721BatchMetadata( string memory name_, string memory symbol_ ) internal {
			_name   = name_;
			_symbol = symbol_;
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
													operator_ == _tokenApprovals[ tokenId_ ] ||
													_isApprovedForAll( tokenOwner_, operator_ );
			return _isApproved_;
		}

		/**
		* @dev Mints `qty_` tokens and transfers them to `to_`.
		* 
		* This internal function can be used to perform token minting.
		* 
		* Emits a {ConsecutiveTransfer} event.
		*/
		function _mint( address to_, uint256 qty_ ) internal virtual {
			uint256 _firstToken_ = _numTokens;
			uint256 _lastToken_ = _firstToken_ + qty_ - 1;

			_owners[ _firstToken_ ] = to_;
			if ( _lastToken_ > _firstToken_ ) {
				_owners[ _lastToken_ ] = to_;
			}
			for ( uint256 i; i < qty_; i ++ ) {
				emit Transfer( address( 0 ), to_, _firstToken_ + i );
			}
			_numTokens = _lastToken_ + 1;
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
		* @dev Internal function returning the total number of tokens minted
		* 
		* @return uint256 the number of tokens that have been minted so far
		*/
		function _supplyMinted() internal view virtual returns ( uint256 ) {
			return _numTokens;
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
			_tokenApprovals[ tokenId_ ] = address( 0 );
			uint256 _previousId_ = tokenId_ > 0 ? tokenId_ - 1 : 0;
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
	// *****           PUBLIC           *****
	// **************************************
		/**
		* @dev See {IERC721-approve}.
		*/
		function approve( address to_, uint256 tokenId_ ) external virtual exists( tokenId_ ) {
			address _operator_ = _msgSender();
			address _tokenOwner_ = _ownerOf( tokenId_ );
			bool _isApproved_ = _isApprovedOrOwner( _tokenOwner_, _operator_, tokenId_ );

			if ( ! _isApproved_ ) {
				revert IERC721_CALLER_NOT_APPROVED();
			}

			if ( to_ == _tokenOwner_ ) {
				revert IERC721_APPROVE_OWNER();
			}

			_tokenApprovals[ tokenId_ ] = to_;
			emit Approval( _tokenOwner_, to_, tokenId_ );
		}

		/**
		* @dev See {IERC721-safeTransferFrom}.
		* 
		* Note: We can ignore `from_` as we can compare everything to the actual token owner, 
		* but we cannot remove this parameter to stay in conformity with IERC721
		*/
		function safeTransferFrom( address, address to_, uint256 tokenId_ ) external virtual exists( tokenId_ ) {
			address _operator_ = _msgSender();
			address _tokenOwner_ = _ownerOf( tokenId_ );
			bool _isApproved_ = _isApprovedOrOwner( _tokenOwner_, _operator_, tokenId_ );

			if ( ! _isApproved_ ) {
				revert IERC721_CALLER_NOT_APPROVED();
			}

			if ( to_ == address( 0 ) ) {
				revert IERC721_NULL_ADDRESS_TRANSFER();
			}

			_transfer( _tokenOwner_, to_, tokenId_ );

			if ( ! _checkOnERC721Received( _tokenOwner_, to_, tokenId_, "" ) ) {
				revert IERC721_NON_ERC721_RECEIVER();
			}
		}

		/**
		* @dev See {IERC721-safeTransferFrom}.
		* 
		* Note: We can ignore `from_` as we can compare everything to the actual token owner, 
		* but we cannot remove this parameter to stay in conformity with IERC721
		*/
		function safeTransferFrom( address, address to_, uint256 tokenId_, bytes calldata data_ ) external virtual exists( tokenId_ ) {
			address _operator_ = _msgSender();
			address _tokenOwner_ = _ownerOf( tokenId_ );
			bool _isApproved_ = _isApprovedOrOwner( _tokenOwner_, _operator_, tokenId_ );

			if ( ! _isApproved_ ) {
				revert IERC721_CALLER_NOT_APPROVED();
			}

			if ( to_ == address( 0 ) ) {
				revert IERC721_NULL_ADDRESS_TRANSFER();
			}

			_transfer( _tokenOwner_, to_, tokenId_ );

			if ( ! _checkOnERC721Received( _tokenOwner_, to_, tokenId_, data_ ) ) {
				revert IERC721_NON_ERC721_RECEIVER();
			}
		}

		/**
		* @dev See {IERC721-setApprovalForAll}.
		*/
		function setApprovalForAll( address operator_, bool approved_ ) public virtual override {
			address _account_ = _msgSender();
			if ( operator_ == _account_ ) {
				revert IERC721_APPROVE_CALLER();
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
		function transferFrom( address, address to_, uint256 tokenId_ ) external virtual exists( tokenId_ ) {
			address _operator_ = _msgSender();
			address _tokenOwner_ = _ownerOf( tokenId_ );
			bool _isApproved_ = _isApprovedOrOwner( _tokenOwner_, _operator_, tokenId_ );

			if ( ! _isApproved_ ) {
				revert IERC721_CALLER_NOT_APPROVED();
			}

			if ( to_ == address( 0 ) ) {
				revert IERC721_NULL_ADDRESS_TRANSFER();
			}

			_transfer( _tokenOwner_, to_, tokenId_ );
		}

	// **************************************
	// *****            VIEW            *****
	// **************************************
		/**
		* @dev Returns the number of tokens in `tokenOwner_`'s account.
		*/
		function balanceOf( address tokenOwner_ ) external view virtual returns ( uint256 ) {
			return _balanceOf( tokenOwner_ );
		}

		/**
		* @dev Returns the account approved for `tokenId_` token.
		*
		* Requirements:
		*
		* - `tokenId_` must exist.
		*/
		function getApproved( uint256 tokenId_ ) external view virtual exists( tokenId_ ) returns ( address ) {
			return _tokenApprovals[ tokenId_ ];
		}

		/**
		* @dev Returns if the `operator_` is allowed to manage all of the assets of `tokenOwner_`.
		*
		* See {setApprovalForAll}
		*/
		function isApprovedForAll( address tokenOwner_, address operator_ ) external view virtual returns ( bool ) {
			return _isApprovedForAll( tokenOwner_, operator_ );
		}

		/**
		* @dev See {IERC721Metadata-name}.
		*/
		function name() public view virtual override returns ( string memory ) {
			return _name;
		}

		/**
		* @dev Returns the owner of the `tokenId_` token.
		*
		* Requirements:
		*
		* - `tokenId_` must exist.
		*/
		function ownerOf( uint256 tokenId_ ) external view virtual exists( tokenId_ ) returns ( address ) {
			return _ownerOf( tokenId_ );
		}

		/**
		* @dev See {IERC165-supportsInterface}.
		*/
		function supportsInterface( bytes4 interfaceId_ ) public view virtual override returns ( bool ) {
			return 
				interfaceId_ == type( IERC721Metadata ).interfaceId ||
				interfaceId_ == type( IERC721 ).interfaceId ||
				interfaceId_ == type( IERC165 ).interfaceId;
		}

		/**
		* @dev See {IERC721Metadata-symbol}.
		*/
		function symbol() public view virtual override returns ( string memory ) {
			return _symbol;
		}

		/**
		* @dev See {IERC721Metadata-tokenURI}.
		*/
		function tokenURI( uint256 tokenId_ ) public view virtual override exists( tokenId_ ) returns ( string memory ) {
			return bytes( _baseURI ).length > 0 ? string( abi.encodePacked( _baseURI, _toString( tokenId_ ) ) ) : _toString( tokenId_ );
		}
}

// File: contracts/ERC721BatchStakable.sol



/**
* Author: Lambdalf the White
*/

pragma solidity 0.8.10;



/**
* @dev Implementation of https://eips.ethereum.org/EIPS/eip-721[ERC721] Non-Fungible Token Standard, including
* the Metadata extension and the Enumerable extension.
* 
* Note: This implementation is only compatible with a sequential order of tokens minted.
* If you need to mint tokens in a random order, you will need to override the following functions:
* Note also that this implementations is fairly inefficient and as such, 
* those functions should be avoided inside non-view functions.
*/
abstract contract ERC721BatchStakable is ERC721Batch, IERC721Receiver {
	// Mapping of tokenId to stakeholder address
	mapping( uint256 => address ) internal _stakedOwners;

	// **************************************
	// *****          INTERNAL          *****
	// **************************************
		/**
		* @dev Internal function returning the number of tokens staked by `tokenOwner_`.
		*/
		function _balanceOfStaked( address tokenOwner_ ) internal view virtual returns ( uint256 ) {
			if ( tokenOwner_ == address( 0 ) ) {
				return 0;
			}

			uint256 _supplyMinted_ = _supplyMinted();
			uint256 _count_ = 0;
			for ( uint256 i; i < _supplyMinted_; i++ ) {
				if ( _stakedOwners[ i ] == tokenOwner_ ) {
					_count_++;
				}
			}
			return _count_;
		}

		/**
		* @dev Internal function that mints `qtyMinted_` tokens and stakes `qtyStaked_` of them to the count of `tokenOwner_`.
		*/
		function _mintAndStake( address tokenOwner_, uint256 qtyMinted_, uint256 qtyStaked_ ) internal {
			uint256 _qtyNotStaked_;
			uint256 _qtyStaked_ = qtyStaked_;
			if ( qtyStaked_ > qtyMinted_ ) {
				_qtyStaked_ = qtyMinted_;
			}
			else if ( qtyStaked_ < qtyMinted_ ) {
				_qtyNotStaked_ = qtyMinted_ - qtyStaked_;
			}
			if ( _qtyStaked_ > 0 ) {
				_mintInContract( tokenOwner_, _qtyStaked_ );
			}
			if ( _qtyNotStaked_ > 0 ) {
				_mint( tokenOwner_, _qtyNotStaked_ );
			}
		}

		/**
		* @dev Internal function that mints `qtyStaked_` tokens and stakes them to the count of `tokenOwner_`.
		*/
		function _mintInContract( address tokenOwner_, uint256 qtyStaked_ ) internal {
			uint256 _currentToken_ = _supplyMinted();
			uint256 _lastToken_ = _currentToken_ + qtyStaked_ - 1;

			while ( _currentToken_ <= _lastToken_ ) {
				_stakedOwners[ _currentToken_ ] = tokenOwner_;
				_currentToken_ ++;
			}

			_mint( address( this ), qtyStaked_ );
		}

		/**
		* @dev Internal function returning the owner of the staked token number `tokenId_`.
		*
		* Requirements:
		*
		* - `tokenId_` must exist.
		*/
		function _ownerOfStaked( uint256 tokenId_ ) internal view virtual returns ( address ) {
			return _stakedOwners[ tokenId_ ];
		}

		/**
		* @dev Internal function that stakes the token number `tokenId_` to the count of `tokenOwner_`.
		*/
		function _stake( address tokenOwner_, uint256 tokenId_ ) internal {
			_stakedOwners[ tokenId_ ] = tokenOwner_;
			_transfer( tokenOwner_, address( this ), tokenId_ );
		}

		/**
		* @dev Internal function that unstakes the token `tokenId_` and transfers it back to `tokenOwner_`.
		*/
		function _unstake( address tokenOwner_, uint256 tokenId_ ) internal {
			_transfer( address( this ), tokenOwner_, tokenId_ );
			delete _stakedOwners[ tokenId_ ];
		}
	// **************************************

	// **************************************
	// *****           PUBLIC           *****
	// **************************************
		/**
		* @dev Stakes the token `tokenId_` to the count of its owner.
		* 
		* Requirements:
		* 
		* - Caller must be allowed to manage `tokenId_` or its owner's tokens.
		* - `tokenId_` must exist.
		*/
		function stake( uint256 tokenId_ ) external exists( tokenId_ ) {
			address _operator_ = _msgSender();
			address _tokenOwner_ = _ownerOf( tokenId_ );
			bool _isApproved_ = _isApprovedOrOwner( _tokenOwner_, _operator_, tokenId_ );

			if ( ! _isApproved_ ) {
				revert IERC721_CALLER_NOT_APPROVED();
			}
			_stake( _tokenOwner_, tokenId_ );
		}

		/**
		* @dev Unstakes the token `tokenId_` and returns it to its owner.
		* 
		* Requirements:
		* 
		* - Caller must be allowed to manage `tokenId_` or its owner's tokens.
		* - `tokenId_` must exist.
		*/
		function unstake( uint256 tokenId_ ) external exists( tokenId_ ) {
			address _operator_ = _msgSender();
			address _tokenOwner_ = _ownerOfStaked( tokenId_ );
			bool _isApproved_ = _isApprovedOrOwner( _tokenOwner_, _operator_, tokenId_ );

			if ( ! _isApproved_ ) {
				revert IERC721_CALLER_NOT_APPROVED();
			}
			_unstake( _tokenOwner_, tokenId_ );
		}
	// **************************************

	// **************************************
	// *****            VIEW            *****
	// **************************************
		/**
		* @dev Returns the number of tokens owned by `tokenOwner_`.
		*/
		function balanceOf( address tokenOwner_ ) public view virtual override returns ( uint256 balance ) {
			return _balanceOfStaked( tokenOwner_ ) + _balanceOf( tokenOwner_ );
		}

		/**
		* @dev Returns the number of tokens staked by `tokenOwner_`.
		*/
		function balanceOfStaked( address tokenOwner_ ) public view virtual returns ( uint256 ) {
			return _balanceOfStaked( tokenOwner_ );
		}

		/**
		* @dev Returns the owner of token number `tokenId_`.
		*
		* Requirements:
		*
		* - `tokenId_` must exist.
		*/
		function ownerOf( uint256 tokenId_ ) public view virtual override exists( tokenId_ ) returns ( address ) {
			address _tokenOwner_ = _ownerOf( tokenId_ );
			if ( _tokenOwner_ == address( this ) ) {
				return _ownerOfStaked( tokenId_ );
			}
			return _tokenOwner_;
		}

		/**
		* @dev Returns the owner of staked token number `tokenId_`.
		*
		* Requirements:
		*
		* - `tokenId_` must exist.
		*/
		function ownerOfStaked( uint256 tokenId_ ) public view virtual exists( tokenId_ ) returns ( address ) {
			return _ownerOfStaked( tokenId_ );
		}
	// **************************************

	// **************************************
	// *****            PURE            *****
	// **************************************
		/**
		* @dev Signals that this contract knows how to handle ERC721 tokens.
		*/
		function onERC721Received( address, address, uint256, bytes memory ) public override pure returns ( bytes4 ) {
			return type( IERC721Receiver ).interfaceId;
		}
	// **************************************
}

// File: contracts/IERC721Enumerable.sol


// OpenZeppelin Contracts (last updated v4.5.0) (token/ERC721/extensions/IERC721Enumerable.sol)

pragma solidity ^0.8.0;


/**
 * @title ERC-721 Non-Fungible Token Standard, optional enumeration extension
 * @dev See https://eips.ethereum.org/EIPS/eip-721
 */
interface IERC721Enumerable is IERC721 {
    /**
     * @dev Returns the total amount of tokens stored by the contract.
     */
    function totalSupply() external view returns (uint256);

    /**
     * @dev Returns a token ID owned by `owner` at a given `index` of its token list.
     * Use along with {balanceOf} to enumerate all of ``owner``'s tokens.
     */
    function tokenOfOwnerByIndex(address owner, uint256 index) external view returns (uint256);

    /**
     * @dev Returns a token ID at a given `index` of all the tokens stored by the contract.
     * Use along with {totalSupply} to enumerate all tokens.
     */
    function tokenByIndex(uint256 index) external view returns (uint256);
}

// File: contracts/ERC721BatchEnumerable.sol



/**
* Author: Lambdalf the White
*/

pragma solidity 0.8.10;



/**
* @dev Implementation of https://eips.ethereum.org/EIPS/eip-721[ERC721] Non-Fungible Token Standard, including
* the Metadata extension and the Enumerable extension.
* 
* Note: This implementation is only compatible with a sequential order of tokens minted.
* If you need to mint tokens in a random order, you will need to override the following functions:
* Note also that this implementations is fairly inefficient and as such, 
* those functions should be avoided inside non-view functions.
*/
abstract contract ERC721BatchEnumerable is ERC721Batch, IERC721Enumerable {
	// Errors
	error IERC721Enumerable_OWNER_INDEX_OUT_OF_BOUNDS();
	error IERC721Enumerable_INDEX_OUT_OF_BOUNDS();

	/**
	* @dev See {IERC165-supportsInterface}.
	*/
	function supportsInterface( bytes4 interfaceId_ ) public view virtual override(IERC165, ERC721Batch) returns ( bool ) {
		return 
			interfaceId_ == type( IERC721Enumerable ).interfaceId ||
			super.supportsInterface( interfaceId_ );
	}

	/**
	* @dev See {IERC721Enumerable-tokenByIndex}.
	*/
	function tokenByIndex( uint256 index_ ) public view virtual override returns ( uint256 ) {
		if ( index_ >= _supplyMinted() ) {
			revert IERC721Enumerable_INDEX_OUT_OF_BOUNDS();
		}
		return index_;
	}

	/**
	* @dev See {IERC721Enumerable-tokenOfOwnerByIndex}.
	*/
	function tokenOfOwnerByIndex( address tokenOwner_, uint256 index_ ) public view virtual override returns ( uint256 tokenId ) {
		uint256 _supplyMinted_ = _supplyMinted();
		if ( index_ >= _balanceOf( tokenOwner_ ) ) {
			revert IERC721Enumerable_OWNER_INDEX_OUT_OF_BOUNDS();
		}

		uint256 _count_ = 0;
		for ( uint256 i = 0; i < _supplyMinted_; i++ ) {
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
		uint256 _supplyMinted_ = _supplyMinted();
		uint256 _count_ = 0;
		for ( uint256 i; i < _supplyMinted_; i++ ) {
			if ( _exists( i ) ) {
				_count_++;
			}
		}
		return _count_;
	}
}

// File: contracts/CCFoundersKeys.sol



/**
* Author: Lambdalf the White
*/

pragma solidity 0.8.10;



contract CCFoundersKeys is ERC721BatchEnumerable, ERC721BatchStakable, ERC2981Base, IOwnable, IPausable, ITradable, IWhitelistable {
	// Events
	event PaymentReleased( address indexed from, address[] indexed tos, uint256[] indexed amounts );

	// Errors
	error CCFoundersKeys_ARRAY_LENGTH_MISMATCH();
	error CCFoundersKeys_FORBIDDEN();
	error CCFoundersKeys_INCORRECT_PRICE();
	error CCFoundersKeys_INSUFFICIENT_KEY_BALANCE();
	error CCFoundersKeys_MAX_BATCH();
	error CCFoundersKeys_MAX_RESERVE();
	error CCFoundersKeys_MAX_SUPPLY();
	error CCFoundersKeys_NO_ETHER_BALANCE();
	error CCFoundersKeys_TRANSFER_FAIL();

	// Founders Key whitelist mint price
	uint public immutable WL_MINT_PRICE; // = 0.069 ether;

	// Founders Key public mint price
	uint public immutable PUBLIC_MINT_PRICE; // = 0.1 ether;

	// Max supply
	uint public immutable MAX_SUPPLY;

	// Max TX
	uint public immutable MAX_BATCH;

	// 2C Safe wallet ~ 90%
	address private immutable _CC_SAFE;

	// 2C Operations wallet ~ 5%
	address private immutable _CC_CHARITY;

	// 2C Founders wallet ~ 2.5%
	address private immutable _CC_FOUNDERS;

	// 2C Community wallet ~ 2.5%
	address private immutable _CC_COMMUNITY;

	// Mapping of Anon holders to amount of free key claimable
	mapping( address => uint256 ) public anonClaimList;

	uint256 private _reserve;

	constructor(
		uint256 reserve_,
		uint256 maxBatch_,
		uint256 maxSupply_,
		uint256 royaltyRate_,
		uint256 wlMintPrice_,
		uint256 publicMintPrice_,
		string memory name_,
		string memory symbol_,
		string memory baseURI_,
		// address devAddress_,
		address[] memory wallets_
	) {
		address _contractOwner_ = _msgSender();
		_initIOwnable( _contractOwner_ );
		_initERC2981Base( _contractOwner_, royaltyRate_ );
		_initERC721BatchMetadata( name_, symbol_ );
		_setBaseURI( baseURI_ );
		_CC_SAFE          = wallets_[ 0 ];
		_CC_CHARITY       = wallets_[ 1 ];
		_CC_FOUNDERS      = wallets_[ 2 ];
		_CC_COMMUNITY     = wallets_[ 3 ];
		_reserve          = reserve_;
		MAX_BATCH         = maxBatch_;
		MAX_SUPPLY        = maxSupply_;
		WL_MINT_PRICE     = wlMintPrice_;
		PUBLIC_MINT_PRICE = publicMintPrice_;
		// _mintAndStake( devAddress_, 5 );
	}

	// **************************************
	// *****          INTERNAL          *****
	// **************************************
		/**
		* @dev Internal function returning whether `operator_` is allowed to manage tokens on behalf of `tokenOwner_`.
		* 
		* @param tokenOwner_ address that owns tokens
		* @param operator_ address that tries to manage tokens
		* 
		* @return bool whether `operator_` is allowed to manage the token
		*/
		function _isApprovedForAll( address tokenOwner_, address operator_ ) internal view virtual override returns ( bool ) {
			return _isRegisteredProxy( tokenOwner_, operator_ ) ||
						 super._isApprovedForAll( tokenOwner_, operator_ );
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
				revert CCFoundersKeys_INCORRECT_PRICE();
			}
			( bool _success_, ) = recipient_.call{ value: amount_ }( "" );
			if ( ! _success_ ) {
				revert CCFoundersKeys_TRANSFER_FAIL();
			}
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
		* - Sale state must be {SaleState.PRESALE}.
		* - There must be enough tokens left to mint outside of the reserve.
		* - Caller must be whitelisted.
		*/
		function claim( uint256 qty_ ) external presaleOpen {
			address _account_   = _msgSender();
			if ( qty_ > anonClaimList[ _account_ ] ) {
				revert CCFoundersKeys_FORBIDDEN();
			}

			uint256 _endSupply_ = _supplyMinted() + qty_;
			if ( _endSupply_ > MAX_SUPPLY - _reserve ) {
				revert CCFoundersKeys_MAX_SUPPLY();
			}

			unchecked {
				anonClaimList[ _account_ ] -= qty_;
			}
			_mint( _account_, qty_ );
		}

		/**
		* @dev Mints `qty_` tokens, stakes `qtyStaked_` of them to the count of the caller, and transfers the remaining to them.
		* 
		* Requirements:
		* 
		* - Sale state must be {SaleState.PRESALE}.
		* - There must be enough tokens left to mint outside of the reserve.
		* - Caller must be whitelisted.
		* - If `qtyStaked_` is higher than `qty_`, only `qty_` tokens are staked.
		*/
		function claimAndStake( uint256 qty_, uint256 qtyStaked_ ) external presaleOpen {
			address _account_   = _msgSender();
			if ( qty_ > anonClaimList[ _account_ ] ) {
				revert CCFoundersKeys_FORBIDDEN();
			}

			uint256 _endSupply_ = _supplyMinted() + qty_;
			if ( _endSupply_ > MAX_SUPPLY - _reserve ) {
				revert CCFoundersKeys_MAX_SUPPLY();
			}

			unchecked {
				anonClaimList[ _account_ ] -= qty_;
			}
			_mintAndStake( _account_, qty_, qtyStaked_ );
		}

		/**
		* @dev Mints a token and transfers it to the caller.
		* 
		* Requirements:
		* 
		* - Sale state must be {SaleState.PRESALE}.
		* - There must be enough tokens left to mint outside of the reserve.
		* - Caller must send enough ether to pay for 1 token at presale price.
		* - Caller must be whitelisted.
		*/
		function mintPreSale( bytes32[] memory proof_ ) external payable presaleOpen isWhitelisted( _msgSender(), proof_, 1, 1 ) {
			if ( _supplyMinted() + 1 > MAX_SUPPLY - _reserve ) {
				revert CCFoundersKeys_MAX_SUPPLY();
			}

			if ( WL_MINT_PRICE != msg.value ) {
				revert CCFoundersKeys_INCORRECT_PRICE();
			}

			address _account_    = _msgSender();
			_consumeWhitelist( _account_, 1 );
			_mint( _account_, 1 );
		}

		/**
		* @dev Mints a token and stakes it to the count of the caller.
		* 
		* Requirements:
		* 
		* - Sale state must be {SaleState.PRESALE}.
		* - There must be enough tokens left to mint outside of the reserve.
		* - Caller must send enough ether to pay for 1 token at presale price.
		* - Caller must be whitelisted.
		*/
		function mintPreSaleAndStake( bytes32[] memory proof_ ) external payable presaleOpen isWhitelisted( _msgSender(), proof_, 1, 1 ) {
			if ( _supplyMinted() + 1 > MAX_SUPPLY - _reserve ) {
				revert CCFoundersKeys_MAX_SUPPLY();
			}

			if ( WL_MINT_PRICE != msg.value ) {
				revert CCFoundersKeys_INCORRECT_PRICE();
			}

			address _account_    = _msgSender();
			_consumeWhitelist( _account_, 1 );
			_mintAndStake( _account_, 1, 1 );
		}

		/**
		* @dev Mints `qty_` tokens and transfers them to the caller.
		* 
		* Requirements:
		* 
		* - Sale state must be {SaleState.SALE}.
		* - There must be enough tokens left to mint outside of the reserve.
		* - Caller must send enough ether to pay for `qty_` tokens at public sale price.
		*/
		function mint( uint256 qty_ ) external payable saleOpen {
			if ( qty_ > MAX_BATCH ) {
				revert CCFoundersKeys_MAX_BATCH();
			}

			uint256 _endSupply_  = _supplyMinted() + qty_;
			if ( _endSupply_ > MAX_SUPPLY - _reserve ) {
				revert CCFoundersKeys_MAX_SUPPLY();
			}

			if ( qty_ * PUBLIC_MINT_PRICE != msg.value ) {
				revert CCFoundersKeys_INCORRECT_PRICE();
			}
			address _account_    = _msgSender();
			_mint( _account_, qty_ );
		}

		/**
		* @dev Mints `qty_` tokens, stakes `qtyStaked_` of them to the count of the caller, and transfers the remaining to them.
		* 
		* Requirements:
		* 
		* - Sale state must be {SaleState.SALE}.
		* - There must be enough tokens left to mint outside of the reserve.
		* - Caller must send enough ether to pay for `qty_` tokens at public sale price.
		* - If `qtyStaked_` is higher than `qty_`, only `qty_` tokens are staked.
		*/
		function mintAndStake( uint256 qty_, uint256 qtyStaked_ ) external payable saleOpen {
			if ( qty_ > MAX_BATCH ) {
				revert CCFoundersKeys_MAX_BATCH();
			}

			uint256 _endSupply_  = _supplyMinted() + qty_;
			if ( _endSupply_ > MAX_SUPPLY - _reserve ) {
				revert CCFoundersKeys_MAX_SUPPLY();
			}

			if ( qty_ * PUBLIC_MINT_PRICE != msg.value ) {
				revert CCFoundersKeys_INCORRECT_PRICE();
			}
			address _account_    = _msgSender();
			_mintAndStake( _account_, qty_, qtyStaked_ );
		}
	// **************************************

	// **************************************
	// *****       CONTRACT_OWNER       *****
	// **************************************
		/**
		* @dev Mints `amounts_` tokens and transfers them to `accounts_`.
		* 
		* Requirements:
		* 
		* - Caller must be the contract owner.
		* - `accounts_` and `amounts_` must have the same length.
		* - There must be enough tokens left in the reserve.
		*/
		function airdrop( address[] memory accounts_, uint256[] memory amounts_ ) external onlyOwner {
			uint256 _len_ = amounts_.length;
			if ( _len_ != accounts_.length ) {
				revert CCFoundersKeys_ARRAY_LENGTH_MISMATCH();
			}
			uint _totalQty_;
			for ( uint256 i = _len_; i > 0; i -- ) {
				_totalQty_ += amounts_[ i - 1 ];
			}
			if ( _totalQty_ > _reserve ) {
				revert CCFoundersKeys_MAX_RESERVE();
			}
			unchecked {
				_reserve -= _totalQty_;
			}
			for ( uint256 i = _len_; i > 0; i -- ) {
				_mint( accounts_[ i - 1], amounts_[ i - 1] );
			}
		}

		/**
		* @dev Saves `accounts_` in the anon claim list.
		* 
		* Requirements:
		* 
		* - Caller must be the contract owner.
		* - Sale state must be {SaleState.CLOSED}.
		* - `accounts_` and `amounts_` must have the same length.
		*/
		function setAnonClaimList( address[] memory accounts_, uint256[] memory amounts_ ) external onlyOwner saleClosed {
			uint256 _len_ = amounts_.length;
			if ( _len_ != accounts_.length ) {
				revert CCFoundersKeys_ARRAY_LENGTH_MISMATCH();
			}
			for ( uint256 i; i < _len_; i ++ ) {
				anonClaimList[ accounts_[ i ] ] = amounts_[ i ];
			}
		}

		/**
		* @dev See {ITradable-setProxyRegistry}.
		* 
		* Requirements:
		* 
		* - Caller must be the contract owner.
		*/
		function setProxyRegistry( address proxyRegistryAddress_ ) external onlyOwner {
			_setProxyRegistry( proxyRegistryAddress_ );
		}

		/**
		* @dev Updates the royalty recipient and rate.
		* 
		* Requirements:
		* 
		* - Caller must be the contract owner.
		*/
		function setRoyaltyInfo( address royaltyRecipient_, uint256 royaltyRate_ ) external onlyOwner {
			_setRoyaltyInfo( royaltyRecipient_, royaltyRate_ );
		}

		/**
		* @dev See {IPausable-setSaleState}.
		* 
		* Requirements:
		* 
		* - Caller must be the contract owner.
		*/
		function setSaleState( SaleState newState_ ) external onlyOwner {
			_setSaleState( newState_ );
		}

		/**
		* @dev See {IWhitelistable-setWhitelist}.
		* 
		* Requirements:
		* 
		* - Caller must be the contract owner.
		* - Sale state must be {SaleState.CLOSED}.
		*/
		function setWhitelist( bytes32 root_ ) external onlyOwner saleClosed {
			_setWhitelist( root_ );
		}

		/**
		* @dev Withdraws all the money stored in the contract and splits it amongst the set wallets.
		* 
		* Requirements:
		* 
		* - Caller must be the contract owner.
		*/
		function withdraw() external onlyOwner {
			uint256 _balance_ = address(this).balance;
			if ( _balance_ == 0 ) {
				revert CCFoundersKeys_NO_ETHER_BALANCE();
			}

			uint256 _safeShare_ = _balance_ * 900 / 1000;
			uint256 _charityShare_ = _balance_ * 50 / 1000;
			uint256 _othersShare_ = _charityShare_ / 2;
			_sendValue( payable( _CC_COMMUNITY ), _othersShare_ );
			_sendValue( payable( _CC_FOUNDERS ), _othersShare_ );
			_sendValue( payable( _CC_CHARITY ), _charityShare_ );
			_sendValue( payable( _CC_SAFE ), _safeShare_ );

			address[] memory _tos_ = new address[]( 4 );
			_tos_[ 0 ] = _CC_COMMUNITY;
			_tos_[ 1 ] = _CC_FOUNDERS;
			_tos_[ 2 ] = _CC_CHARITY;
			_tos_[ 3 ] = _CC_SAFE;
			uint256[] memory _amounts_ = new uint256[]( 4 );
			_amounts_[ 0 ] = _othersShare_;
			_amounts_[ 1 ] = _othersShare_;
			_amounts_[ 2 ] = _charityShare_;
			_amounts_[ 3 ] = _safeShare_;
			emit PaymentReleased( address( this ), _tos_, _amounts_ );
		}
	// **************************************

	// **************************************
	// *****            VIEW            *****
	// **************************************
		/**
		* @dev Returns the number of tokens owned by `tokenOwner_`.
		*/
		function balanceOf( address tokenOwner_ ) public view virtual override(ERC721Batch, ERC721BatchStakable) returns ( uint256 balance ) {
			return ERC721BatchStakable.balanceOf( tokenOwner_ );
		}

		/**
		* @dev Returns the owner of token number `tokenId_`.
		*
		* Requirements:
		*
		* - `tokenId_` must exist.
		*/
		function ownerOf( uint256 tokenId_ ) public view virtual override(ERC721Batch, ERC721BatchStakable) exists( tokenId_ ) returns ( address ) {
			return ERC721BatchStakable.ownerOf( tokenId_ );
		}

		/**
		* @dev See {IERC2981-royaltyInfo}.
		*
		* Requirements:
		*
		* - `tokenId_` must exist.
		*/
		function royaltyInfo( uint256 tokenId_, uint256 salePrice_ ) public view virtual override exists( tokenId_ ) returns ( address, uint256 ) {
			return super.royaltyInfo( tokenId_, salePrice_ );
		}

		/**
		* @dev See {IERC165-supportsInterface}.
		*/
		function supportsInterface( bytes4 interfaceId_ ) public view virtual override(ERC721BatchEnumerable, ERC721Batch, ERC2981Base) returns ( bool ) {
			return 
				interfaceId_ == type( IERC2981 ).interfaceId ||
				ERC721Batch.supportsInterface( interfaceId_ ) ||
				ERC721BatchEnumerable.supportsInterface( interfaceId_ );
		}
	// **************************************
}