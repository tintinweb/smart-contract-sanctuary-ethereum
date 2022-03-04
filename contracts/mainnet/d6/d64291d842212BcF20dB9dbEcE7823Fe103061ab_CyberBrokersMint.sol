// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/utils/cryptography/MerkleProof.sol";
import "./CyberBrokers.sol";

contract CyberBrokersMint is ReentrancyGuard, Ownable
{
	// CyberBrokers token contract
	CyberBrokers public cyberBrokers;

	// CONSTANTS
	uint256 public constant MINT_PRICE = 0.35 ether;

	// Sale Allowlist
	bytes32 public saleMerkleRoot;
	mapping(address => uint) public saleAllowlistClaimed;

	// Claim Allowlist
	bytes32 public claimMerkleRoot;
	mapping(address => uint) public claimAllowlistClaimed;

	// Random mint variables
	uint256 internal _leftToMint;
	uint256 internal _leftToPurchase;
	uint256 internal _leftToClaim;
	mapping(uint256 => uint256) internal _idSwaps;
	uint256 internal _currentPrng;
	uint256 public constant RESERVED_FOR_CLAIM = 309;

	// Sale switches
	bool internal _saleStarted = false;
	bool internal _openWaitList = false;
	bool internal _openSale = false;

	constructor(
		address _CyberBrokersAddress,
		bytes32 _saleMerkleRoot,
		bytes32 _claimMerkleRoot
	) {
		// Set the token address
		cyberBrokers = CyberBrokers(_CyberBrokersAddress);

		// Set the remaining to mint, as well as purchase and claim mints remaining
		_leftToMint     = cyberBrokers.TOTAL_CYBERBROKERS() - cyberBrokers.totalMinted();
		_leftToPurchase = _leftToMint - RESERVED_FOR_CLAIM;
		_leftToClaim    = RESERVED_FOR_CLAIM;

		// Set the allowlist merkleRoots - sales and free claims
		setSaleMerkleRoot(_saleMerkleRoot);
		setClaimMerkleRoot(_claimMerkleRoot);
	}

	function _mintCyberBrokers(
		address _to,
		uint256 _numTokens
	)
		private
	{
		// Validate that number of tokens is greater than zero
		require(_numTokens > 0, "Must mint 1 or more tokens");

		// Sanity check -- validate that we don't mint more than the total
		require(_numTokens <= _leftToMint, "Mint request exceeds supply");

		// Copy the current data
		uint256 leftToMint = _leftToMint;
		uint256 currentPrng = _currentPrng;

		// Mint tokens in random
		uint256 _tokenId;
		for (uint256 i = 0; i < _numTokens; i++) {
			// Generate the next random number
			currentPrng = _prng(currentPrng, leftToMint);

			// Pull the next token ID
			_tokenId = _pullRandomTokenId(currentPrng, leftToMint);

			// Decrement the local mint counter
			leftToMint--;

			// Mint the token
			cyberBrokers.mintCyberBrokerFromMintContract(_to, _tokenId);
		}

		// Store the latest values
		_currentPrng = currentPrng;
		_leftToMint = leftToMint;
	}

	function setSaleStarted(bool _setting) public onlyOwner {
		_saleStarted = _setting;
	}

	function isSaleStarted() public view returns (bool) {
		return _saleStarted;
	}

	function setOpenWaitList(bool _setting) public onlyOwner {
		_openWaitList = _setting;
	}

	function setOpenSale(bool _setting) public onlyOwner {
		_openSale = _setting;
	}

	function isOpenWaitList() public view returns (bool) {
		return _openWaitList;
	}

	function isOpenSaleToAllowlist() public view returns (bool) {
		return _openSale;
	}

	function purchase(
		bytes32[] calldata _proof,
		uint256 _allowedAmount,
		bool _onWaitlist,
		uint256 _numTokens
	)
		external
		payable
		nonReentrant
	{
		// Require that the sale has started
		require(_saleStarted, "Sale has not started");

		// Check that purchase is legal per allowlist
		require(reviewSaleProof(msg.sender, _proof, _allowedAmount, _onWaitlist), "Proof does not match data");
		require(
			(saleAllowlistClaimed[msg.sender] + _numTokens) <= (_allowedAmount + (_openWaitList && _onWaitlist ? 1 : 0)) || // Allowed amount limit
			(_openSale && _numTokens <= 3) // In an open sale, all approved addresses can mint three per transaction
		, "Can not exceed permitted amount");

		// Validate ETH sent
		require((MINT_PRICE * _numTokens) == msg.value, "Incorrect ETH value sent");

		// Check that there are mints available for purchase
		require(_numTokens <= _leftToPurchase, "Mint request exceeds purchase supply");
		_leftToPurchase -= _numTokens;

		// Update allowlist claimed
		saleAllowlistClaimed[msg.sender] = saleAllowlistClaimed[msg.sender] + _numTokens;

		// Continue with the mint
		_mintCyberBrokers(msg.sender, _numTokens);
	}

	function claim(
		bytes32[] calldata _proof,
		uint256 _allowedAmount,
		uint256 _numTokens
	)
		external
		nonReentrant
	{
		// Require that the sale has started
		require(_saleStarted, "Sale has not started");

		// Check that purchase is legal per allowlist
		require(reviewClaimProof(msg.sender, _proof, _allowedAmount, false), "Proof does not match data");
		require((claimAllowlistClaimed[msg.sender] + _numTokens) <= _allowedAmount, "Can not exceed permitted amount");

		// Check that there are mints available for claim
		require(_numTokens <= _leftToClaim, "Mint request exceeds claim supply");
		_leftToClaim -= _numTokens;

		// Update allowlist claimed
		claimAllowlistClaimed[msg.sender] = claimAllowlistClaimed[msg.sender] + _numTokens;

		// Continue with the mint
		_mintCyberBrokers(msg.sender, _numTokens);
	}

	function countRemainingMints() public view returns (uint256) {
		return _leftToMint;
	}

	function countRemainingPurchase() public view returns (uint256) {
		return _leftToPurchase;
	}

	function countRemainingClaims() public view returns (uint256) {
		return _leftToClaim;
	}

	/**
	 * Withdraw functions
	 **/
	function withdraw() public onlyOwner {
		uint256 balance = address(this).balance;
		(bool success,) = msg.sender.call{value: balance}('');
		require(success, 'Fail Transfer');
	}

	/**
	 * Allowlist Merkle Data
	 * Credit for Merkle setup code: Cobble
	 **/
	function getLeaf(address addr, uint256 amount, bool waitlist) public pure returns(bytes32) {
		return keccak256(abi.encodePacked(addr, amount, waitlist));
	}

	function reviewSaleProof(
		address _sender,
		bytes32[] calldata _proof,
		uint256 _allowedAmount,
		bool _onWaitlist
	) public view returns (bool) {
		return MerkleProof.verify(_proof, saleMerkleRoot, getLeaf(_sender, _allowedAmount, _onWaitlist));
	}

	function reviewClaimProof(
		address _sender,
		bytes32[] calldata _proof,
		uint256 _allowedAmount,
		bool _onWaitlist
	) public view returns (bool) {
		return MerkleProof.verify(_proof, claimMerkleRoot, getLeaf(_sender, _allowedAmount, _onWaitlist));
	}

	function setSaleMerkleRoot(bytes32 _merkleRoot) public onlyOwner {
		saleMerkleRoot = _merkleRoot;
	}

	function setClaimMerkleRoot(bytes32 _merkleRoot) public onlyOwner {
		claimMerkleRoot = _merkleRoot;
	}

	/**
	 * Credit: created by dievardump (Simon Fremaux)
	 **/
	function _pullRandomTokenId(
		uint256 currentPrng,
		uint256 leftToMint
	)
		internal
		returns (uint256)
	{
		require(_leftToMint > 0, "No more to mint");

		// get a random id
		uint256 index = 1 + (currentPrng % leftToMint);
		uint256 tokenId = _idSwaps[index];
		if (tokenId == 0) {
			tokenId = index;
		}

		uint256 temp = _idSwaps[leftToMint];

		// "swap" indexes so we don't loose any unminted ids
		// either it's id _leftToMint or the id that was swapped with it
		if (temp == 0) {
			_idSwaps[index] = leftToMint;
		} else {
			// get some refund
			_idSwaps[index] = temp;
			delete _idSwaps[leftToMint];
		}

		return tokenId;
	}

	function _prng(
		uint256 currentPrng,
		uint256 leftToMint
	)
		internal
		view
		returns (uint256)
	{
		return uint256(
			keccak256(
				abi.encodePacked(
					blockhash(block.number - 1),
					currentPrng,
					leftToMint
				)
			)
		);
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
// OpenZeppelin Contracts v4.4.1 (security/ReentrancyGuard.sol)

pragma solidity ^0.8.0;

/**
 * @dev Contract module that helps prevent reentrant calls to a function.
 *
 * Inheriting from `ReentrancyGuard` will make the {nonReentrant} modifier
 * available, which can be applied to functions to make sure there are no nested
 * (reentrant) calls to them.
 *
 * Note that because there is a single `nonReentrant` guard, functions marked as
 * `nonReentrant` may not call one another. This can be worked around by making
 * those functions `private`, and then adding `external` `nonReentrant` entry
 * points to them.
 *
 * TIP: If you would like to learn more about reentrancy and alternative ways
 * to protect against it, check out our blog post
 * https://blog.openzeppelin.com/reentrancy-after-istanbul/[Reentrancy After Istanbul].
 */
abstract contract ReentrancyGuard {
    // Booleans are more expensive than uint256 or any type that takes up a full
    // word because each write operation emits an extra SLOAD to first read the
    // slot's contents, replace the bits taken up by the boolean, and then write
    // back. This is the compiler's defense against contract upgrades and
    // pointer aliasing, and it cannot be disabled.

    // The values being non-zero value makes deployment a bit more expensive,
    // but in exchange the refund on every call to nonReentrant will be lower in
    // amount. Since refunds are capped to a percentage of the total
    // transaction's gas, it is best to keep them low in cases like this one, to
    // increase the likelihood of the full refund coming into effect.
    uint256 private constant _NOT_ENTERED = 1;
    uint256 private constant _ENTERED = 2;

    uint256 private _status;

    constructor() {
        _status = _NOT_ENTERED;
    }

    /**
     * @dev Prevents a contract from calling itself, directly or indirectly.
     * Calling a `nonReentrant` function from another `nonReentrant`
     * function is not supported. It is possible to prevent this from happening
     * by making the `nonReentrant` function external, and making it call a
     * `private` function that does the actual work.
     */
    modifier nonReentrant() {
        // On the first call to nonReentrant, _notEntered will be true
        require(_status != _ENTERED, "ReentrancyGuard: reentrant call");

        // Any calls to nonReentrant after this point will fail
        _status = _ENTERED;

        _;

        // By storing the original value once again, a refund is triggered (see
        // https://eips.ethereum.org/EIPS/eip-2200)
        _status = _NOT_ENTERED;
    }
}

// SPDX-License-Identifier: MIT
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

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Burnable.sol";

import "./CyberBrokersMetadata.sol";

contract CyberBrokers is ERC721Burnable, Ownable
{
	// Contracts
	CyberBrokersMetadata public cyberBrokersMetadata;

	// Metadata information
	string private _baseUri = 'https://cyberbrokers.io/api/cyberbroker/';

	// Minter address
	address public cyberBrokersMintContract;

	// Constants
	uint256 constant public TOTAL_CYBERBROKERS = 10001;

	// Keeping track
	uint256 public totalMinted = 0;
	uint256 public totalUnplugged = 0;

	// Metadata provenance hash
	string public provenanceHash = "c235983e3a4834b2fe7c153da0123f03b7d50e1e80537782fa8d73e642d799fa";

	constructor(
		address _CyberBrokersMetadataAddress
	)
		ERC721("CyberBrokers", "CYBERBROKERS")
	{
		// Set the addresses
		setCyberBrokersMetadataAddress(_CyberBrokersMetadataAddress);

		// Mint Asherah to Josie
		_mintCyberBroker(0x2999377CD7A7b5FC9Fd61dB33610C891602Ce037, 0);
	}


	/**
	 * Metadata functionality
	 **/
	function setCyberBrokersMetadataAddress(address _CyberBrokersMetadataAddress) public onlyOwner {
		cyberBrokersMetadata = CyberBrokersMetadata(_CyberBrokersMetadataAddress);
	}

	function setBaseUri(string calldata _uri) public onlyOwner {
		_baseUri = _uri;
	}

	function _baseURI() internal view virtual override returns (string memory) {
		return _baseUri;
	}

	function tokenURI(uint256 tokenId) public view override returns (string memory) {
		require(_exists(tokenId), "ERC721Metadata: URI query for nonexistent token");

		if (cyberBrokersMetadata.hasOnchainMetadata(tokenId)) {
			return cyberBrokersMetadata.tokenURI(tokenId);
		}

		return super.tokenURI(tokenId);
	}

	function render(uint256 _tokenId)
		external view
		returns (string memory)
	{
		require(_exists(_tokenId), "Non-existent token to render.");
		return cyberBrokersMetadata.render(_tokenId);
	}


	/**
	 * Wrapper for Enumerable functions: totalSupply & getTokens
	 **/
	function totalSupply() public view returns (uint256) {
		return totalMinted - totalUnplugged;
	}

	// Do not use this on-chain, it's O(N)
	// This is why we use a non-standard name instead of tokenOfOwnerByIndex
	function getTokens(address addr) public view returns (uint256[] memory) {
		// Prepare array of tokens
		uint256 numTokensOwned = balanceOf(addr);
		uint[] memory tokens = new uint[](numTokensOwned);

		uint256 currentTokensIdx;
		for (uint256 idx; idx < TOTAL_CYBERBROKERS; idx++) {
			if (_exists(idx) && ownerOf(idx) == addr) {
				tokens[currentTokensIdx++] = idx;

				if (currentTokensIdx == numTokensOwned) {
					break;
				}
			}
		}

		return tokens;
	}


	/**
	 * Minting functionality
	 **/
	function setMintContractAddress(address _mintContract) public onlyOwner {
		cyberBrokersMintContract = _mintContract;
	}

	function mintCyberBrokerFromMintContract(address to, uint256 tokenId) external {
		require(msg.sender == cyberBrokersMintContract, "Only mint contract can mint");
		_mintCyberBroker(to, tokenId);
	}

	function _mintCyberBroker(address to, uint256 tokenId) private {
		require(totalMinted < TOTAL_CYBERBROKERS, "Max CyberBrokers minted");
		_mint(to, tokenId);
		totalMinted++;
	}


	/**
	 * Burn & unplug: alias for burn
	 **/
	function burn(uint256 tokenId) public virtual override {
		super.burn(tokenId);
		totalUnplugged++;
	}

	function unplug(uint256 tokenId) public {
		burn(tokenId);
	}


	/**
	 * Withdraw functions
	 **/
	function withdraw() public onlyOwner {
		uint256 balance = address(this).balance;
		(bool success,) = msg.sender.call{value: balance}('');
		require(success, 'Fail Transfer');
	}


	/**
	 * On-Chain Royalties & Interface
	 **/
	function supportsInterface(bytes4 interfaceId)
		public
		view
		override
		returns (bool)
	{
		return
			interfaceId == this.royaltyInfo.selector ||
			super.supportsInterface(interfaceId);
	}

	function royaltyInfo(uint256, uint256 amount)
		public
		view
		returns (address, uint256)
	{
		// 5% royalties
		return (owner(), (amount * 500) / 10000);
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
// OpenZeppelin Contracts v4.4.1 (token/ERC721/extensions/ERC721Burnable.sol)

pragma solidity ^0.8.0;

import "../ERC721.sol";
import "../../../utils/Context.sol";

/**
 * @title ERC721 Burnable Token
 * @dev ERC721 Token that can be irreversibly burned (destroyed).
 */
abstract contract ERC721Burnable is Context, ERC721 {
    /**
     * @dev Burns `tokenId`. See {ERC721-_burn}.
     *
     * Requirements:
     *
     * - The caller must own `tokenId` or be an approved operator.
     */
    function burn(uint256 tokenId) public virtual {
        //solhint-disable-next-line max-line-length
        require(_isApprovedOrOwner(_msgSender(), tokenId), "ERC721Burnable: caller is not owner nor approved");
        _burn(tokenId);
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/utils/Strings.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

import "./ContractDataStorage.sol";
import "./SvgParser.sol";

contract CyberBrokersMetadata is Ownable {
  using Strings for uint256;

  bool private _useOnChainMetadata = false;

  string private _externalUri = "https://cyberbrokers.io/";
  string private _imageCacheUri = "";

  // Contracts
  ContractDataStorage public contractDataStorage;
  SvgParser public svgParser;

  constructor(
    address _contractDataStorageAddress,
    address _svgParserAddress
  ) {
    // Set the addresses
    setContractDataStorageAddress(_contractDataStorageAddress);
    setSvgParserAddress(_svgParserAddress);
  }

  function setContractDataStorageAddress(address _contractDataStorageAddress) public onlyOwner {
    contractDataStorage = ContractDataStorage(_contractDataStorageAddress);
  }

  function setSvgParserAddress(address _svgParserAddress) public onlyOwner {
    svgParser = SvgParser(_svgParserAddress);
  }


  /**
   * On-Chain Metadata Construction
   **/

  function hasOnchainMetadata(uint256 tokenId) public view returns (bool) {
    return _useOnChainMetadata;
  }

  function setOnChainMetadata(bool _state) public onlyOwner {
    _useOnChainMetadata = _state;
  }

  function setExternalUri(string calldata _uri) public onlyOwner {
    _externalUri = _uri;
  }

  function setImageCacheUri(string calldata _uri) public onlyOwner {
    _imageCacheUri = _uri;
  }

  function tokenURI(uint256 tokenId) public view returns (string memory) {
    return string(
        abi.encodePacked(
            abi.encodePacked(
                bytes('data:application/json;utf8,{"name":"'),
                getName(tokenId),
                bytes('","description":"'),
                getDescription(tokenId),
                bytes('","external_url":"'),
                getExternalUrl(tokenId),
                bytes('","image":"'),
                getImageCache(tokenId)
            ),
            abi.encodePacked(
                bytes('","attributes":['),
                getAttributes(tokenId),
                bytes(']}')
            )
        )
    );
  }

  function getName(uint256 tokenId) public view returns (string memory) {
    return "Test Name";
  }

  function getDescription(uint256 tokenId) public view returns (string memory) {
    return "Test Description";
  }

  function getExternalUrl(uint256 tokenId) public view returns (string memory) {
    return string(abi.encodePacked(_externalUri, tokenId.toString()));
  }

  function getImageCache(uint256 tokenId) public view returns (string memory) {
    return string(abi.encodePacked(_imageCacheUri, tokenId.toString()));
  }

  function getAttributes(uint256 tokenId) public view returns (string memory) {
    return string(
      abi.encodePacked(
        bytes('{"trait_type": "Mind", "value": 30}')
      )
    );
  }


  /**
   * On-Chain Token SVG Rendering
   **/

  function renderData(string memory _key, uint256 _startIndex)
    public
    view
    returns (
      string memory _output,
      uint256 _endIndex
    )
  {
    require(contractDataStorage.hasKey(_key));
    return svgParser.parse(contractDataStorage.getData(_key), _startIndex);
  }

  function render(uint256 _tokenId)
    public
    pure
    returns (string memory)
  {
    require(_tokenId >= 0 && _tokenId <= 10000, "Can only render valid token ID");
    return string("");
  }


  /**
   * Off-Chain Token SVG Rendering
   **/

  function getTokenData(uint256 _tokenId)
    public
    pure
    returns (string memory)
  {
    require(_tokenId >= 0 && _tokenId <= 10000, "Can only render valid token ID");
    return string("");
  }

  function getOffchainSvgParser()
    public
    view
    returns (
      string memory _output
    )
  {
    string memory _key = 'svg-parser.js';
    require(contractDataStorage.hasKey(_key), "Off-chain SVG Parser not uploaded");
    return string(contractDataStorage.getData(_key));
  }

}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.5.0) (token/ERC721/ERC721.sol)

pragma solidity ^0.8.0;

import "./IERC721.sol";
import "./IERC721Receiver.sol";
import "./extensions/IERC721Metadata.sol";
import "../../utils/Address.sol";
import "../../utils/Context.sol";
import "../../utils/Strings.sol";
import "../../utils/introspection/ERC165.sol";

/**
 * @dev Implementation of https://eips.ethereum.org/EIPS/eip-721[ERC721] Non-Fungible Token Standard, including
 * the Metadata extension, but not including the Enumerable extension, which is available separately as
 * {ERC721Enumerable}.
 */
contract ERC721 is Context, ERC165, IERC721, IERC721Metadata {
    using Address for address;
    using Strings for uint256;

    // Token name
    string private _name;

    // Token symbol
    string private _symbol;

    // Mapping from token ID to owner address
    mapping(uint256 => address) private _owners;

    // Mapping owner address to token count
    mapping(address => uint256) private _balances;

    // Mapping from token ID to approved address
    mapping(uint256 => address) private _tokenApprovals;

    // Mapping from owner to operator approvals
    mapping(address => mapping(address => bool)) private _operatorApprovals;

    /**
     * @dev Initializes the contract by setting a `name` and a `symbol` to the token collection.
     */
    constructor(string memory name_, string memory symbol_) {
        _name = name_;
        _symbol = symbol_;
    }

    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId) public view virtual override(ERC165, IERC165) returns (bool) {
        return
            interfaceId == type(IERC721).interfaceId ||
            interfaceId == type(IERC721Metadata).interfaceId ||
            super.supportsInterface(interfaceId);
    }

    /**
     * @dev See {IERC721-balanceOf}.
     */
    function balanceOf(address owner) public view virtual override returns (uint256) {
        require(owner != address(0), "ERC721: balance query for the zero address");
        return _balances[owner];
    }

    /**
     * @dev See {IERC721-ownerOf}.
     */
    function ownerOf(uint256 tokenId) public view virtual override returns (address) {
        address owner = _owners[tokenId];
        require(owner != address(0), "ERC721: owner query for nonexistent token");
        return owner;
    }

    /**
     * @dev See {IERC721Metadata-name}.
     */
    function name() public view virtual override returns (string memory) {
        return _name;
    }

    /**
     * @dev See {IERC721Metadata-symbol}.
     */
    function symbol() public view virtual override returns (string memory) {
        return _symbol;
    }

    /**
     * @dev See {IERC721Metadata-tokenURI}.
     */
    function tokenURI(uint256 tokenId) public view virtual override returns (string memory) {
        require(_exists(tokenId), "ERC721Metadata: URI query for nonexistent token");

        string memory baseURI = _baseURI();
        return bytes(baseURI).length > 0 ? string(abi.encodePacked(baseURI, tokenId.toString())) : "";
    }

    /**
     * @dev Base URI for computing {tokenURI}. If set, the resulting URI for each
     * token will be the concatenation of the `baseURI` and the `tokenId`. Empty
     * by default, can be overriden in child contracts.
     */
    function _baseURI() internal view virtual returns (string memory) {
        return "";
    }

    /**
     * @dev See {IERC721-approve}.
     */
    function approve(address to, uint256 tokenId) public virtual override {
        address owner = ERC721.ownerOf(tokenId);
        require(to != owner, "ERC721: approval to current owner");

        require(
            _msgSender() == owner || isApprovedForAll(owner, _msgSender()),
            "ERC721: approve caller is not owner nor approved for all"
        );

        _approve(to, tokenId);
    }

    /**
     * @dev See {IERC721-getApproved}.
     */
    function getApproved(uint256 tokenId) public view virtual override returns (address) {
        require(_exists(tokenId), "ERC721: approved query for nonexistent token");

        return _tokenApprovals[tokenId];
    }

    /**
     * @dev See {IERC721-setApprovalForAll}.
     */
    function setApprovalForAll(address operator, bool approved) public virtual override {
        _setApprovalForAll(_msgSender(), operator, approved);
    }

    /**
     * @dev See {IERC721-isApprovedForAll}.
     */
    function isApprovedForAll(address owner, address operator) public view virtual override returns (bool) {
        return _operatorApprovals[owner][operator];
    }

    /**
     * @dev See {IERC721-transferFrom}.
     */
    function transferFrom(
        address from,
        address to,
        uint256 tokenId
    ) public virtual override {
        //solhint-disable-next-line max-line-length
        require(_isApprovedOrOwner(_msgSender(), tokenId), "ERC721: transfer caller is not owner nor approved");

        _transfer(from, to, tokenId);
    }

    /**
     * @dev See {IERC721-safeTransferFrom}.
     */
    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId
    ) public virtual override {
        safeTransferFrom(from, to, tokenId, "");
    }

    /**
     * @dev See {IERC721-safeTransferFrom}.
     */
    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId,
        bytes memory _data
    ) public virtual override {
        require(_isApprovedOrOwner(_msgSender(), tokenId), "ERC721: transfer caller is not owner nor approved");
        _safeTransfer(from, to, tokenId, _data);
    }

    /**
     * @dev Safely transfers `tokenId` token from `from` to `to`, checking first that contract recipients
     * are aware of the ERC721 protocol to prevent tokens from being forever locked.
     *
     * `_data` is additional data, it has no specified format and it is sent in call to `to`.
     *
     * This internal function is equivalent to {safeTransferFrom}, and can be used to e.g.
     * implement alternative mechanisms to perform token transfer, such as signature-based.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `tokenId` token must exist and be owned by `from`.
     * - If `to` refers to a smart contract, it must implement {IERC721Receiver-onERC721Received}, which is called upon a safe transfer.
     *
     * Emits a {Transfer} event.
     */
    function _safeTransfer(
        address from,
        address to,
        uint256 tokenId,
        bytes memory _data
    ) internal virtual {
        _transfer(from, to, tokenId);
        require(_checkOnERC721Received(from, to, tokenId, _data), "ERC721: transfer to non ERC721Receiver implementer");
    }

    /**
     * @dev Returns whether `tokenId` exists.
     *
     * Tokens can be managed by their owner or approved accounts via {approve} or {setApprovalForAll}.
     *
     * Tokens start existing when they are minted (`_mint`),
     * and stop existing when they are burned (`_burn`).
     */
    function _exists(uint256 tokenId) internal view virtual returns (bool) {
        return _owners[tokenId] != address(0);
    }

    /**
     * @dev Returns whether `spender` is allowed to manage `tokenId`.
     *
     * Requirements:
     *
     * - `tokenId` must exist.
     */
    function _isApprovedOrOwner(address spender, uint256 tokenId) internal view virtual returns (bool) {
        require(_exists(tokenId), "ERC721: operator query for nonexistent token");
        address owner = ERC721.ownerOf(tokenId);
        return (spender == owner || getApproved(tokenId) == spender || isApprovedForAll(owner, spender));
    }

    /**
     * @dev Safely mints `tokenId` and transfers it to `to`.
     *
     * Requirements:
     *
     * - `tokenId` must not exist.
     * - If `to` refers to a smart contract, it must implement {IERC721Receiver-onERC721Received}, which is called upon a safe transfer.
     *
     * Emits a {Transfer} event.
     */
    function _safeMint(address to, uint256 tokenId) internal virtual {
        _safeMint(to, tokenId, "");
    }

    /**
     * @dev Same as {xref-ERC721-_safeMint-address-uint256-}[`_safeMint`], with an additional `data` parameter which is
     * forwarded in {IERC721Receiver-onERC721Received} to contract recipients.
     */
    function _safeMint(
        address to,
        uint256 tokenId,
        bytes memory _data
    ) internal virtual {
        _mint(to, tokenId);
        require(
            _checkOnERC721Received(address(0), to, tokenId, _data),
            "ERC721: transfer to non ERC721Receiver implementer"
        );
    }

    /**
     * @dev Mints `tokenId` and transfers it to `to`.
     *
     * WARNING: Usage of this method is discouraged, use {_safeMint} whenever possible
     *
     * Requirements:
     *
     * - `tokenId` must not exist.
     * - `to` cannot be the zero address.
     *
     * Emits a {Transfer} event.
     */
    function _mint(address to, uint256 tokenId) internal virtual {
        require(to != address(0), "ERC721: mint to the zero address");
        require(!_exists(tokenId), "ERC721: token already minted");

        _beforeTokenTransfer(address(0), to, tokenId);

        _balances[to] += 1;
        _owners[tokenId] = to;

        emit Transfer(address(0), to, tokenId);

        _afterTokenTransfer(address(0), to, tokenId);
    }

    /**
     * @dev Destroys `tokenId`.
     * The approval is cleared when the token is burned.
     *
     * Requirements:
     *
     * - `tokenId` must exist.
     *
     * Emits a {Transfer} event.
     */
    function _burn(uint256 tokenId) internal virtual {
        address owner = ERC721.ownerOf(tokenId);

        _beforeTokenTransfer(owner, address(0), tokenId);

        // Clear approvals
        _approve(address(0), tokenId);

        _balances[owner] -= 1;
        delete _owners[tokenId];

        emit Transfer(owner, address(0), tokenId);

        _afterTokenTransfer(owner, address(0), tokenId);
    }

    /**
     * @dev Transfers `tokenId` from `from` to `to`.
     *  As opposed to {transferFrom}, this imposes no restrictions on msg.sender.
     *
     * Requirements:
     *
     * - `to` cannot be the zero address.
     * - `tokenId` token must be owned by `from`.
     *
     * Emits a {Transfer} event.
     */
    function _transfer(
        address from,
        address to,
        uint256 tokenId
    ) internal virtual {
        require(ERC721.ownerOf(tokenId) == from, "ERC721: transfer from incorrect owner");
        require(to != address(0), "ERC721: transfer to the zero address");

        _beforeTokenTransfer(from, to, tokenId);

        // Clear approvals from the previous owner
        _approve(address(0), tokenId);

        _balances[from] -= 1;
        _balances[to] += 1;
        _owners[tokenId] = to;

        emit Transfer(from, to, tokenId);

        _afterTokenTransfer(from, to, tokenId);
    }

    /**
     * @dev Approve `to` to operate on `tokenId`
     *
     * Emits a {Approval} event.
     */
    function _approve(address to, uint256 tokenId) internal virtual {
        _tokenApprovals[tokenId] = to;
        emit Approval(ERC721.ownerOf(tokenId), to, tokenId);
    }

    /**
     * @dev Approve `operator` to operate on all of `owner` tokens
     *
     * Emits a {ApprovalForAll} event.
     */
    function _setApprovalForAll(
        address owner,
        address operator,
        bool approved
    ) internal virtual {
        require(owner != operator, "ERC721: approve to caller");
        _operatorApprovals[owner][operator] = approved;
        emit ApprovalForAll(owner, operator, approved);
    }

    /**
     * @dev Internal function to invoke {IERC721Receiver-onERC721Received} on a target address.
     * The call is not executed if the target address is not a contract.
     *
     * @param from address representing the previous owner of the given token ID
     * @param to target address that will receive the tokens
     * @param tokenId uint256 ID of the token to be transferred
     * @param _data bytes optional data to send along with the call
     * @return bool whether the call correctly returned the expected magic value
     */
    function _checkOnERC721Received(
        address from,
        address to,
        uint256 tokenId,
        bytes memory _data
    ) private returns (bool) {
        if (to.isContract()) {
            try IERC721Receiver(to).onERC721Received(_msgSender(), from, tokenId, _data) returns (bytes4 retval) {
                return retval == IERC721Receiver.onERC721Received.selector;
            } catch (bytes memory reason) {
                if (reason.length == 0) {
                    revert("ERC721: transfer to non ERC721Receiver implementer");
                } else {
                    assembly {
                        revert(add(32, reason), mload(reason))
                    }
                }
            }
        } else {
            return true;
        }
    }

    /**
     * @dev Hook that is called before any token transfer. This includes minting
     * and burning.
     *
     * Calling conditions:
     *
     * - When `from` and `to` are both non-zero, ``from``'s `tokenId` will be
     * transferred to `to`.
     * - When `from` is zero, `tokenId` will be minted for `to`.
     * - When `to` is zero, ``from``'s `tokenId` will be burned.
     * - `from` and `to` are never both zero.
     *
     * To learn more about hooks, head to xref:ROOT:extending-contracts.adoc#using-hooks[Using Hooks].
     */
    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 tokenId
    ) internal virtual {}

    /**
     * @dev Hook that is called after any transfer of tokens. This includes
     * minting and burning.
     *
     * Calling conditions:
     *
     * - when `from` and `to` are both non-zero.
     * - `from` and `to` are never both zero.
     *
     * To learn more about hooks, head to xref:ROOT:extending-contracts.adoc#using-hooks[Using Hooks].
     */
    function _afterTokenTransfer(
        address from,
        address to,
        uint256 tokenId
    ) internal virtual {}
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (token/ERC721/IERC721.sol)

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

// SPDX-License-Identifier: MIT
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

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (token/ERC721/extensions/IERC721Metadata.sol)

pragma solidity ^0.8.0;

import "../IERC721.sol";

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
// OpenZeppelin Contracts v4.4.1 (utils/Strings.sol)

pragma solidity ^0.8.0;

/**
 * @dev String operations.
 */
library Strings {
    bytes16 private constant _HEX_SYMBOLS = "0123456789abcdef";

    /**
     * @dev Converts a `uint256` to its ASCII `string` decimal representation.
     */
    function toString(uint256 value) internal pure returns (string memory) {
        // Inspired by OraclizeAPI's implementation - MIT licence
        // https://github.com/oraclize/ethereum-api/blob/b42146b063c7d6ee1358846c198246239e9360e8/oraclizeAPI_0.4.25.sol

        if (value == 0) {
            return "0";
        }
        uint256 temp = value;
        uint256 digits;
        while (temp != 0) {
            digits++;
            temp /= 10;
        }
        bytes memory buffer = new bytes(digits);
        while (value != 0) {
            digits -= 1;
            buffer[digits] = bytes1(uint8(48 + uint256(value % 10)));
            value /= 10;
        }
        return string(buffer);
    }

    /**
     * @dev Converts a `uint256` to its ASCII `string` hexadecimal representation.
     */
    function toHexString(uint256 value) internal pure returns (string memory) {
        if (value == 0) {
            return "0x00";
        }
        uint256 temp = value;
        uint256 length = 0;
        while (temp != 0) {
            length++;
            temp >>= 8;
        }
        return toHexString(value, length);
    }

    /**
     * @dev Converts a `uint256` to its ASCII `string` hexadecimal representation with fixed length.
     */
    function toHexString(uint256 value, uint256 length) internal pure returns (string memory) {
        bytes memory buffer = new bytes(2 * length + 2);
        buffer[0] = "0";
        buffer[1] = "x";
        for (uint256 i = 2 * length + 1; i > 1; --i) {
            buffer[i] = _HEX_SYMBOLS[value & 0xf];
            value >>= 4;
        }
        require(value == 0, "Strings: hex length insufficient");
        return string(buffer);
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
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/access/Ownable.sol";

/**
 * Explaining the `init` variable within saveData:
 *
 * 61_00_00 -- PUSH2 (size)
 * 60_00 -- PUSH1 (code position)
 * 60_00 -- PUSH1 (mem position)
 * 39 CODECOPY
 * 61_00_00 PUSH2 (size)
 * 60_00 PUSH1 (mem position)
 * f3 RETURN
 *
 **/

contract ContractDataStorage is Ownable {

  struct ContractData {
    address rawContract;
    uint128 size;
    uint128 offset;
  }

  struct ContractDataPages {
    uint256 maxPageNumber;
    bool exists;
    mapping (uint256 => ContractData) pages;
  }

  mapping (string => ContractDataPages) internal _contractDataPages;

  mapping (address => bool) internal _controllers;

  constructor() {
    updateController(_msgSender(), true);
  }

  /**
   * Access Control
   **/
  function updateController(address _controller, bool _status) public onlyOwner {
    _controllers[_controller] = _status;
  }

  modifier onlyController() {
    require(_controllers[_msgSender()], "ContractDataStorage: caller is not a controller");
    _;
  }

  /**
   * Storage & Revocation
   **/

  function saveData(
    string memory _key,
    uint128 _pageNumber,
    bytes memory _b
  )
    public
    onlyController
  {
    require(_b.length < 24576, "SvgStorage: Exceeded 24,576 bytes max contract size");

    // Create the header for the contract data
    bytes memory init = hex"610000_600e_6000_39_610000_6000_f3";
    bytes1 size1 = bytes1(uint8(_b.length));
    bytes1 size2 = bytes1(uint8(_b.length >> 8));
    init[2] = size1;
    init[1] = size2;
    init[10] = size1;
    init[9] = size2;

    // Prepare the code for storage in a contract
    bytes memory code = abi.encodePacked(init, _b);

    // Create the contract
    address dataContract;
    assembly {
      dataContract := create(0, add(code, 32), mload(code))
      if eq(dataContract, 0) {
        returndatacopy(0, 0, returndatasize())
        revert(0, returndatasize())
      }
    }

    // Store the record of the contract
    saveDataForDeployedContract(
      _key,
      _pageNumber,
      dataContract,
      uint128(_b.length),
      0
    );
  }

  function saveDataForDeployedContract(
    string memory _key,
    uint256 _pageNumber,
    address dataContract,
    uint128 _size,
    uint128 _offset
  )
    public
    onlyController
  {
    // Pull the current data for the contractData
    ContractDataPages storage _cdPages = _contractDataPages[_key];

    // Store the maximum page
    if (_cdPages.maxPageNumber < _pageNumber) {
      _cdPages.maxPageNumber = _pageNumber;
    }

    // Keep track of the existance of this key
    _cdPages.exists = true;

    // Add the page to the location needed
    _cdPages.pages[_pageNumber] = ContractData(
      dataContract,
      _size,
      _offset
    );
  }

  function revokeContractData(
    string memory _key
  )
    public
    onlyController
  {
    delete _contractDataPages[_key];
  }

  function getSizeOfPages(
    string memory _key
  )
    public
    view
    returns (uint256)
  {
    // For all data within the contract data pages, iterate over and compile them
    ContractDataPages storage _cdPages = _contractDataPages[_key];

    // Determine the total size
    uint256 totalSize;
    for (uint256 idx; idx <= _cdPages.maxPageNumber; idx++) {
      totalSize += _cdPages.pages[idx].size;
    }

    return totalSize;
  }

  function getData(
    string memory _key
  )
    public
    view
    returns (bytes memory)
  {
    // Get the total size
    uint256 totalSize = getSizeOfPages(_key);

    // Create a region large enough for all of the data
    bytes memory _totalData = new bytes(totalSize);

    // Retrieve the pages
    ContractDataPages storage _cdPages = _contractDataPages[_key];

    // For each page, pull and compile
    uint256 currentPointer = 32;
    for (uint256 idx; idx <= _cdPages.maxPageNumber; idx++) {
      ContractData storage dataPage = _cdPages.pages[idx];
      address dataContract = dataPage.rawContract;
      uint256 size = uint256(dataPage.size);
      uint256 offset = uint256(dataPage.offset);

      // Copy directly to total data
      assembly {
        extcodecopy(dataContract, add(_totalData, currentPointer), offset, size)
      }

      // Update the current pointer
      currentPointer += size;
    }

    return _totalData;
  }

  function getDataForAll(string[] memory _keys)
    public
    view
    returns (bytes memory)
  {
    // Get the total size of all of the keys
    uint256 totalSize;
    for (uint256 idx; idx < _keys.length; idx++) {
      totalSize += getSizeOfPages(_keys[idx]);
    }

    // Create a region large enough for all of the data
    bytes memory _totalData = new bytes(totalSize);

    // For each key, pull down all data
    uint256 currentPointer = 32;
    for (uint256 idx; idx < _keys.length; idx++) {
      // Retrieve the set of pages
      ContractDataPages storage _cdPages = _contractDataPages[_keys[idx]];

      // For each page, pull and compile
      for (uint256 innerIdx; innerIdx <= _cdPages.maxPageNumber; innerIdx++) {
        ContractData storage dataPage = _cdPages.pages[innerIdx];
        address dataContract = dataPage.rawContract;
        uint256 size = uint256(dataPage.size);
        uint256 offset = uint256(dataPage.offset);

        // Copy directly to total data
        assembly {
          extcodecopy(dataContract, add(_totalData, currentPointer), offset, size)
        }

        // Update the current pointer
        currentPointer += size;
      }
    }

    return _totalData;
  }

  function hasKey(string memory _key)
    public
    view
    returns (bool)
  {
    return _contractDataPages[_key].exists;
  }

}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./Utils.sol";

contract SvgParser {

    // Limits
    uint256 constant DEFAULT_THRESHOLD_COUNTER = 2500;

    // Bits & Masks
    bytes1 constant tagBit            = bytes1(0x80);
    bytes1 constant startTagBit       = bytes1(0x40);
    bytes1 constant tagTypeMask       = bytes1(0x3F);
    bytes1 constant attributeTypeMask = bytes1(0x7F);

    bytes1 constant dCommandBit       = bytes1(0x80);
    bytes1 constant percentageBit     = bytes1(0x40);
    bytes1 constant negativeBit       = bytes1(0x20);
    bytes1 constant decimalBit        = bytes1(0x10);

    bytes1 constant numberMask        = bytes1(0x0F);

    bytes1 constant filterInIdBit     = bytes1(0x80);

    bytes1 constant filterInIdMask    = bytes1(0x7F);

    // SVG tags
    bytes constant SVG_OPEN_TAG = bytes('<?xml version="1.0" encoding="UTF-8"?><svg width="1320px" height="1760px" viewBox="0 0 1320 1760" version="1.1" xmlns="http://www.w3.org/2000/svg" xmlns:xlink="http://www.w3.org/1999/xlink">');
    bytes constant SVG_CLOSE_TAG = bytes("</svg>");

    bytes[25] TAGS = [
        bytes("g"),
        bytes("polygon"),
        bytes("path"),
        bytes("circle"),
        bytes("defs"),
        bytes("linearGradient"),
        bytes("stop"),
        bytes("rect"),
        bytes("polyline"),
        bytes("text"),
        bytes("tspan"),
        bytes("mask"),
        bytes("use"),
        bytes("ellipse"),
        bytes("radialGradient"),
        bytes("filter"),
        bytes("feColorMatrix"),
        bytes("feComposite"),
        bytes("feGaussianBlur"),
        bytes("feMorphology"),
        bytes("feOffset"),
        bytes("pattern"),
        bytes("feMergeNode"),
        bytes("feMerge"),
        bytes("INVALIDTAG")
    ];

    bytes[54] ATTRIBUTES = [
        bytes("d"),
        bytes("points"),
        bytes("transform"),
        bytes("cx"),
        bytes("cy"),
        bytes("r"),
        bytes("stroke"),
        bytes("stroke-width"),
        bytes("fill"),
        bytes("fill-opacity"),
        bytes("translate"),
        bytes("rotate"),
        bytes("scale"),
        bytes("x1"),
        bytes("y1"),
        bytes("x2"),
        bytes("y2"),
        bytes("stop-color"),
        bytes("offset"),
        bytes("stop-opacity"),
        bytes("width"),
        bytes("height"),
        bytes("x"),
        bytes("y"),
        bytes("font-size"),
        bytes("letter-spacing"),
        bytes("opacity"),
        bytes("id"),
        bytes("xlink:href"),
        bytes("rx"),
        bytes("ry"),
        bytes("mask"),
        bytes("fx"),
        bytes("fy"),
        bytes("gradientTransform"),
        bytes("filter"),
        bytes("filterUnits"),
        bytes("result"),
        bytes("in"),
        bytes("in2"),
        bytes("type"),
        bytes("values"),
        bytes("operator"),
        bytes("k1"),
        bytes("k2"),
        bytes("k3"),
        bytes("k4"),
        bytes("stdDeviation"),
        bytes("edgeMode"),
        bytes("radius"),
        bytes("fill-rule"),
        bytes("dx"),
        bytes("dy"),
        bytes("INVALIDATTRIBUTE")
    ];

    bytes[2] PAIR_NUMBER_SET_ATTRIBUTES = [
        bytes("translate"),
        bytes("scale")
    ];

    bytes[4] PAIR_COLOR_ATTRIBUTES = [
        bytes("stroke"),
        bytes("fill"),
        bytes("stop-color"),
        bytes("mask")
    ];

    bytes[23] SINGLE_NUMBER_SET_ATTRIBUTES = [
        bytes("cx"),
        bytes("cy"),
        bytes("r"),
        bytes("rotate"),
        bytes("x1"),
        bytes("y1"),
        bytes("x2"),
        bytes("y2"),
        bytes("offset"),
        bytes("x"),
        bytes("y"),
        bytes("rx"),
        bytes("ry"),
        bytes("fx"),
        bytes("fy"),
        bytes("font-size"),
        bytes("letter-spacing"),
        bytes("stroke-width"),
        bytes("width"),
        bytes("height"),
        bytes("fill-opacity"),
        bytes("stop-opacity"),
        bytes("opacity")
    ];

    bytes[20] D_COMMANDS = [
        bytes("M"),
        bytes("m"),
        bytes("L"),
        bytes("l"),
        bytes("H"),
        bytes("h"),
        bytes("V"),
        bytes("v"),
        bytes("C"),
        bytes("c"),
        bytes("S"),
        bytes("s"),
        bytes("Q"),
        bytes("q"),
        bytes("T"),
        bytes("t"),
        bytes("A"),
        bytes("a"),
        bytes("Z"),
        bytes("z")
    ];

    bytes[2] FILL_RULE = [
        bytes("nonzero"),
        bytes("evenodd")
    ];

    bytes[2] FILTER_UNIT = [
        bytes("userSpaceOnUse"),
        bytes("objectBoundingBox")
    ];

    bytes[6] FILTER_IN = [
        bytes("SourceGraphic"),
        bytes("SourceAlpha"),
        bytes("BackgroundImage"),
        bytes("BackgroundAlpha"),
        bytes("FillPaint"),
        bytes("StrokePaint")
    ];

    bytes[16] FILTER_TYPE = [
        bytes("translate"),
        bytes("scale"),
        bytes("rotate"),
        bytes("skewX"),
        bytes("skewY"),
        bytes("matrix"),
        bytes("saturate"),
        bytes("hueRotate"),
        bytes("luminanceToAlpha"),
        bytes("identity"),
        bytes("table"),
        bytes("discrete"),
        bytes("linear"),
        bytes("gamma"),
        bytes("fractalNoise"),
        bytes("turbulence")
    ];

    bytes[9] FILTER_OPERATOR = [
        bytes("over"),
        bytes("in"),
        bytes("out"),
        bytes("atop"),
        bytes("xor"),
        bytes("lighter"),
        bytes("arithmetic"),
        bytes("erode"),
        bytes("dilate")
    ];

    bytes[3] FILTER_EDGEMODE = [
        bytes("duplicate"),
        bytes("wrap"),
        bytes("none")
    ];


    function checkTag(bytes1 line) internal pure returns (bool) {
        return line & tagBit > 0;
    }

    function checkStartTag(bytes1 line) internal pure returns (bool) {
        return line & startTagBit > 0;
    }

    function getTag(bytes1 line) internal view returns (bytes memory) {
        uint8 key = uint8(line & tagTypeMask);

        if (key >= TAGS.length - 1) {
            return TAGS[TAGS.length - 1];
        }

        return TAGS[key];
    }

    function getAttribute(bytes1 line) internal view returns (bytes memory) {
        uint8 key = uint8(line & attributeTypeMask);

        if (key >= ATTRIBUTES.length - 1) {
            return ATTRIBUTES[ATTRIBUTES.length - 1];
        }

        return ATTRIBUTES[key];
    }

    function compareAttrib(bytes memory attrib, string memory compareTo) internal pure returns (bool) {
        return keccak256(attrib) == keccak256(bytes(compareTo));
    }

    function compareAttrib(bytes memory attrib, bytes storage compareTo) internal pure returns (bool) {
        return keccak256(attrib) == keccak256(compareTo);
    }

    function addOutput(bytes memory _output, uint256 _outputIdx, bytes memory _addendum) internal pure returns (uint256) {
        for (uint256 _idx; _idx < _addendum.length; _idx++) {
            _output[_outputIdx++] = _addendum[_idx];
        }
        return _outputIdx;
    }

    function addOutput(bytes memory _output, uint256 _outputIdx, bytes memory _addendum1, bytes memory _addendum2)
        internal pure returns (uint256)
    {
        return addOutput(_output, addOutput(_output, _outputIdx, _addendum1), _addendum2);
    }

    function addOutput(bytes memory _output, uint256 _outputIdx, bytes memory _addendum1, bytes memory _addendum2, bytes memory _addendum3)
        internal pure returns (uint256)
    {
        return addOutput(_output, addOutput(_output, addOutput(_output, _outputIdx, _addendum1), _addendum2), _addendum3);
    }

    function addOutput(bytes memory _output, uint256 _outputIdx, bytes memory _addendum1, bytes memory _addendum2, bytes memory _addendum3, bytes memory _addendum4)
        internal pure returns (uint256)
    {
        return addOutput(_output, addOutput(_output, addOutput(_output, addOutput(_output, _outputIdx, _addendum1), _addendum2), _addendum3), _addendum4);
    }

    function parse(bytes memory input, uint256 idx) public view returns (string memory, uint256) {
        return parse(input, idx, DEFAULT_THRESHOLD_COUNTER);
    }

    function parse(bytes memory input, uint256 idx, uint256 thresholdCounter) public view returns (string memory, uint256) {
        // Keep track of what we're returning
        bytes memory output = new bytes(thresholdCounter * 15); // Plenty of padding
        uint256 outputIdx = 0;

        bool isTagOpen = false;
        uint256 counter = idx;

        // Start the output with SVG tags if needed
        if (idx == 0) {
            outputIdx = addOutput(output, outputIdx, SVG_OPEN_TAG);
        }

        // Go through all bytes we want to review
        while (idx < input.length)
        {
            // Get the current byte
            bytes1 _b = bytes1(input[idx]);

            // If this is a tag, determine if we're creating a new tag
            if (checkTag(_b)) {
                // Close the current tag
                bool closeTag = false;
                if (isTagOpen) {
                    closeTag = true;
                    isTagOpen = false;

                    if ((idx - counter) >= thresholdCounter) {
                        outputIdx = addOutput(output, outputIdx, bytes(">"));
                        break;
                    }
                }

                // Start the next tag
                if (checkStartTag(_b)) {
                    isTagOpen = true;

                    if (closeTag) {
                        outputIdx = addOutput(output, outputIdx, bytes("><"), getTag(_b));
                    } else {
                        outputIdx = addOutput(output, outputIdx, bytes("<"), getTag(_b));
                    }
                } else {
                    // If needed, open and close an end tag
                    if (closeTag) {
                        outputIdx = addOutput(output, outputIdx, bytes("></"), getTag(_b), bytes(">"));
                    } else {
                        outputIdx = addOutput(output, outputIdx, bytes("</"), getTag(_b), bytes(">"));
                    }
                }
            }
            else
            {
                // Attributes
                bytes memory attrib = getAttribute(_b);

                if (compareAttrib(attrib, "transform") || compareAttrib(attrib, "gradientTransform")) {
                    // Keep track of which transform we're doing
                    bool isGradientTransform = compareAttrib(attrib, "gradientTransform");

                    // Get the next byte & attribute
                    idx += 2;
                    _b = bytes1(input[idx]);
                    attrib = getAttribute(_b);

                    outputIdx = addOutput(output, outputIdx, bytes(" "), isGradientTransform ? bytes('gradientTransform="') : bytes('transform="'));
                    while (compareAttrib(attrib, 'translate') || compareAttrib(attrib, 'rotate') || compareAttrib(attrib, 'scale')) {
                        outputIdx = addOutput(output, outputIdx, bytes(" "));
                        (idx, outputIdx) = parseAttributeValues(output, outputIdx, attrib, input, idx);

                        // Get the next byte & attribute
                        idx += 2;
                        _b = bytes1(input[idx]);
                        attrib = getAttribute(_b);
                    }

                    outputIdx = addOutput(output, outputIdx, bytes('"'));

                    // Undo the previous index increment
                    idx -= 2;
                }
                else if (compareAttrib(attrib, "d")) {
                    (idx, outputIdx) = packDPoints(output, outputIdx, input, idx);
                }
                else if (compareAttrib(attrib, "points"))
                {
                    (idx, outputIdx) = packPoints(output, outputIdx, input, idx, bytes(' points="'));
                }
                else if (compareAttrib(attrib, "values"))
                {
                    (idx, outputIdx) = packPoints(output, outputIdx, input, idx, bytes(' values="'));
                }
                else
                {
                    outputIdx = addOutput(output, outputIdx, bytes(" "));
                    (idx, outputIdx) = parseAttributeValues(output, outputIdx, attrib, input, idx);
                }
            }

            idx += 2;
        }

        if (idx >= input.length) {
            // Close out the SVG tags
            outputIdx = addOutput(output, outputIdx, SVG_CLOSE_TAG);
            idx = 0;
        }

        // Pack everything down to the size that actually fits
        bytes memory finalOutput = new bytes(outputIdx);
        for (uint256 _idx; _idx < outputIdx; _idx++) {
            finalOutput[_idx] = output[_idx];
        }

        return (string(finalOutput), idx);
    }

    function packDPoints(bytes memory output, uint256 outputIdx, bytes memory input, uint256 idx) internal view returns (uint256, uint256) {
        outputIdx = addOutput(output, outputIdx, bytes(' d="'));

        // Due to the open-ended nature of points, we concat directly to local_output
        idx += 2;
        uint256 count = uint256(uint8(input[idx + 1])) * 2**8 + uint256(uint8(input[idx]));
        for (uint256 countIdx = 0; countIdx < count; countIdx++) {
            idx += 2;

            // Add the d command prior to any bits
            if (uint8(input[idx + 1] & dCommandBit) > 0) {
                outputIdx = addOutput(output, outputIdx, bytes(" "), D_COMMANDS[uint8(input[idx])]);
            }
            else
            {
                countIdx++;
                outputIdx = addOutput(output, outputIdx, bytes(" "), parseNumberSetValues(input[idx], input[idx + 1]), bytes(","), parseNumberSetValues(input[idx + 2], input[idx + 3]));
                idx += 2;
            }
        }

        outputIdx = addOutput(output, outputIdx, bytes('"'));

        return (idx, outputIdx);
    }

    function packPoints(bytes memory output, uint256 outputIdx, bytes memory input, uint256 idx, bytes memory attributePreface) internal view returns (uint256, uint256) {
        outputIdx = addOutput(output, outputIdx, attributePreface);

        // Due to the open-ended nature of points, we concat directly to local_output
        idx += 2;
        uint256 count = uint256(uint8(input[idx + 1])) * 2**8 + uint256(uint8(input[idx]));
        for (uint256 countIdx = 0; countIdx < count; countIdx++) {
            idx += 2;
            bytes memory numberSet = parseNumberSetValues(input[idx], input[idx + 1]);

            if (countIdx > 0) {
                outputIdx = addOutput(output, outputIdx, bytes(" "), numberSet);
            } else {
                outputIdx = addOutput(output, outputIdx, numberSet);
            }
        }

        outputIdx = addOutput(output, outputIdx, bytes('"'));

        return (idx, outputIdx);
    }

    function parseAttributeValues(
        bytes memory output,
        uint256 outputIdx,
        bytes memory attrib,
        bytes memory input,
        uint256 idx
    )
        internal
        view
        returns (uint256, uint256)
    {
        // Handled in main function
        if (compareAttrib(attrib, "d") || compareAttrib(attrib, "points") || compareAttrib(attrib, "values") || compareAttrib(attrib, 'transform')) {
            return (idx + 2, outputIdx);
        }

        if (compareAttrib(attrib, 'id') || compareAttrib(attrib, 'xlink:href') || compareAttrib(attrib, 'filter') || compareAttrib(attrib, 'result'))
        {
            bytes memory number = Utils.uint2bytes(uint256(uint8(input[idx + 3])) * 2**8 + uint256(uint8(input[idx + 2])));

            if (compareAttrib(attrib, 'xlink:href')) {
                outputIdx = addOutput(output, outputIdx, attrib, bytes('="#id-'), number, bytes('"'));
            } else if (compareAttrib(attrib, 'filter')) {
                outputIdx = addOutput(output, outputIdx, attrib, bytes('="url(#id-'), number, bytes(')"'));
            } else {
                outputIdx = addOutput(output, outputIdx, attrib, bytes('="id-'), number, bytes('"'));
            }

            return (idx + 2, outputIdx);
        }

        for (uint256 attribIdx = 0; attribIdx < PAIR_NUMBER_SET_ATTRIBUTES.length; attribIdx++) {
            if (compareAttrib(attrib, PAIR_NUMBER_SET_ATTRIBUTES[attribIdx])) {
                outputIdx = addOutput(output, outputIdx, attrib, bytes('('), parseNumberSetValues(input[idx + 2], input[idx + 3]), bytes(','));
                outputIdx = addOutput(output, outputIdx, parseNumberSetValues(input[idx + 4], input[idx + 5]), bytes(')'));
                return (idx + 4, outputIdx);
            }
        }

        for (uint256 attribIdx = 0; attribIdx < PAIR_COLOR_ATTRIBUTES.length; attribIdx++) {
            if (compareAttrib(attrib, PAIR_COLOR_ATTRIBUTES[attribIdx])) {
                outputIdx = addOutput(output, outputIdx, attrib, bytes('="'), parseColorValues(input[idx + 2], input[idx + 3], input[idx + 4], input[idx + 5]), bytes('"'));
                return (idx + 4, outputIdx);
            }
        }

        if (compareAttrib(attrib, 'rotate')) {
            // Default, single number set values
            outputIdx = addOutput(output, outputIdx, attrib, bytes('('), parseNumberSetValues(input[idx + 2], input[idx + 3]), bytes(')'));
            return (idx + 2, outputIdx);
        }

        // Dictionary lookups
        if (compareAttrib(attrib, 'in') || compareAttrib(attrib, 'in2')) {
            // Special case for the dictionary lookup for in & in2 => allow for ID lookup
            if (uint8(input[idx + 3] & filterInIdBit) > 0) {
                bytes memory number = Utils.uint2bytes(uint256(uint8(input[idx + 3] & filterInIdMask)) * 2**8 + uint256(uint8(input[idx + 2])));
                outputIdx = addOutput(output, outputIdx, attrib, bytes('="id-'), number, bytes('"'));
            } else {
                outputIdx = addOutput(output, outputIdx, attrib, bytes('="'), FILTER_IN[uint8(input[idx + 2])], bytes('"'));
            }

            return (idx + 2, outputIdx);
        } else if (compareAttrib(attrib, 'type')) {
            outputIdx = addOutput(output, outputIdx, attrib, bytes('="'), FILTER_TYPE[uint8(input[idx + 2])], bytes('"'));
            return (idx + 2, outputIdx);
        } else if (compareAttrib(attrib, 'operator')) {
            outputIdx = addOutput(output, outputIdx, attrib, bytes('="'), FILTER_OPERATOR[uint8(input[idx + 2])], bytes('"'));
            return (idx + 2, outputIdx);
        } else if (compareAttrib(attrib, 'edgeMode')) {
            outputIdx = addOutput(output, outputIdx, attrib, bytes('="'), FILTER_EDGEMODE[uint8(input[idx + 2])], bytes('"'));
            return (idx + 2, outputIdx);
        } else if (compareAttrib(attrib, 'fill-rule')) {
            outputIdx = addOutput(output, outputIdx, attrib, bytes('="'), FILL_RULE[uint8(input[idx + 2])], bytes('"'));
            return (idx + 2, outputIdx);
        } else if (compareAttrib(attrib, 'filterUnits')) {
            outputIdx = addOutput(output, outputIdx, attrib, bytes('="'), FILTER_UNIT[uint8(input[idx + 2])], bytes('"'));
            return (idx + 2, outputIdx);
        }

        // Default, single number set values
        outputIdx = addOutput(output, outputIdx, attrib, bytes('="'), parseNumberSetValues(input[idx + 2], input[idx + 3]), bytes('"'));
        return (idx + 2, outputIdx);
    }

    function parseColorValues(bytes1 one, bytes1 two, bytes1 three, bytes1 four) internal pure returns (bytes memory) {
        if (uint8(two) == 0xFF && uint8(one) == 0 && uint8(four) == 0 && uint8(three) == 0) {
            // None identifier case
            return bytes("none");
        }
        else if (uint8(two) == 0x80 && uint8(one) == 0)
        {
            // URL identifier case
            bytes memory number = Utils.uint2bytes(uint256(uint8(four)) * 2**8 + uint256(uint8(three)));
            return abi.encodePacked("url(#id-", number, ")");
        } else {
            return Utils.unpackHexColorValues(uint8(one), uint8(four), uint8(three));
        }
    }

    function parseNumberSetValues(bytes1 one, bytes1 two) internal pure returns (bytes memory) {
        return Utils.unpackNumberSetValues(
            uint256(uint8(two & numberMask)) * 2**8 + uint256(uint8(one)), // number
            uint8(two & decimalBit) > 0, // decimal
            uint8(two & negativeBit) > 0, // negative
            uint8(two & percentageBit) > 0 // percent
        );
    }

}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

library Utils {

  /**
   * From https://github.com/provable-things/ethereum-api/blob/master/oraclizeAPI_0.5.sol
   **/

   function uint2bytes(uint _i) internal pure returns (bytes memory) {
    if (_i == 0) {
      return "0";
    }
    uint j = _i;
    uint len;
    while (j != 0) {
      len++;
      j /= 10;
    }
    bytes memory bstr = new bytes(len);
    uint k = len - 1;
    while (_i != 0) {
      unchecked {
        bstr[k--] = bytes1(uint8(48 + _i % 10));
      }

      _i /= 10;
    }
    return bstr;
  }

  function unpackNumberSetValues(uint _i, bool decimal, bool negative, bool percent) internal pure returns (bytes memory) {
    // Base case
    if (_i == 0) {
      if (percent) {
        return "0%";
      } else {
        return "0";
      }
    }

    // Kick off length with the slots needed to make room for, considering certain bits
    uint j = _i;
    uint len = (negative ? 1 : 0) + (percent ? 1 : 0) + (decimal ? 2 : 0);

    // See how many tens we need
    uint numTens;
    while (j != 0) {
      numTens++;
      j /= 10;
    }

    // Expand length
    // Special case: if decimal & numTens is less than 3, need to pad by 3 since we'll left-pad zeroes
    if (decimal && numTens < 3) {
      len += 3;
    } else {
      len += numTens;
    }

    // Now create the byte "string"
    bytes memory bstr = new bytes(len);

    // Index from right-most to left-most
    uint k = len - 1;

    // Percent character
    if (percent) {
      bstr[k--] = bytes1("%");
    }

    // The entire number
    while (_i != 0) {
      unchecked {
        bstr[k--] = bytes1(uint8(48 + _i % 10));
      }

      _i /= 10;
    }

    // If a decimal, we need to left-pad if the numTens isn't enough
    if (decimal) {
      while (numTens < 3) {
        bstr[k--] = bytes1("0");
        numTens++;
      }
      bstr[k--] = bytes1(".");

      unchecked {
        bstr[k--] = bytes1("0");
      }
    }

    // If negative, the last byte should be negative
    if (negative) {
      bstr[0] = bytes1("-");
    }

    return bstr;
  }

  /**
   * Reference pulled from https://gist.github.com/okwme/f3a35193dc4eb9d1d0db65ccf3eb4034
   **/

  function unpackHexColorValues(uint8 r, uint8 g, uint8 b) internal pure returns (bytes memory) {
    bytes memory rHex = Utils.uint2hexchar(r);
    bytes memory gHex = Utils.uint2hexchar(g);
    bytes memory bHex = Utils.uint2hexchar(b);
    bytes memory bstr = new bytes(7);
    bstr[6] = bHex[1];
    bstr[5] = bHex[0];
    bstr[4] = gHex[1];
    bstr[3] = gHex[0];
    bstr[2] = rHex[1];
    bstr[1] = rHex[0];
    bstr[0] = bytes1("#");
    return bstr;
  }

  function uint2hexchar(uint8 _i) internal pure returns (bytes memory) {
    uint8 mask = 15;
    bytes memory bstr = new bytes(2);
    bstr[1] = (_i & mask) > 9 ? bytes1(uint8(55 + (_i & mask))) : bytes1(uint8(48 + (_i & mask)));
    bstr[0] = ((_i >> 4) & mask) > 9 ? bytes1(uint8(55 + ((_i >> 4) & mask))) : bytes1(uint8(48 + ((_i >> 4) & mask)));
    return bstr;
  }

}