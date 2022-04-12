// SPDX-License-Identifier: MIT
pragma solidity 0.8.4;

import "./BBPCCreator.sol";
import "./RoyaltySplits.sol";

/**
 *
 *   ██████╗ ██████╗ ██╗████████╗████████╗██╗   ██╗
 *  ██╔════╝ ██╔══██╗██║╚══██╔══╝╚══██╔══╝╚██╗ ██╔╝
 *  ██║  ███╗██████╔╝██║   ██║      ██║    ╚████╔╝
 *  ██║   ██║██╔══██╗██║   ██║      ██║     ╚██╔╝
 *  ╚██████╔╝██║  ██║██║   ██║      ██║      ██║
 *   ╚═════╝ ╚═╝  ╚═╝╚═╝   ╚═╝      ╚═╝      ╚═╝
 *   ██████╗ █████╗ ████████╗███████╗
 *  ██╔════╝██╔══██╗╚══██╔══╝██╔════╝
 *  ██║     ███████║   ██║   ███████╗
 *  ██║     ██╔══██║   ██║   ╚════██║
 *  ╚██████╗██║  ██║   ██║   ███████║
 *   ╚═════╝╚═╝  ╚═╝   ╚═╝   ╚══════╝
 *
 *  Block Block Punch Click
 *  https://www.grittycats.com
 *
 */
contract GrittyCats is RoyaltySplits, BBPCCreator {
	constructor(
		string memory _baseURI,
		uint256 _maxPresaleMint,
		uint256 _maxPublicMint,
		uint256 _maxSupply,
		uint256 _reserveAmount
	)
		BBPCCreator(
			"GrittyCats",
			"GCAT",
			_baseURI,
			_maxPresaleMint,
			_maxPublicMint,
			_maxSupply,
			_reserveAmount,
			addresses,
			splits
		)
	{}
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.4;

/// @author Block Block Punch Click (blockblockpunchclick.com)

import "erc721a/contracts/ERC721A.sol";
import "./libs/BetterBoolean.sol";
import "./libs/SafeAddress.sol";
import "./libs/ABDKMath64x64.sol";
import "./security/ContractGuardian.sol";
import "./finance/LockedPaymentSplitter.sol";

import "@openzeppelin/contracts/token/ERC1155/IERC1155.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Context.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "@openzeppelin/contracts/utils/introspection/ERC165.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/utils/cryptography/ECDSA.sol";
import "@openzeppelin/contracts/utils/cryptography/MerkleProof.sol";

/// @dev Errors
/**
 * @notice Insufficient balance for transfer. Needed `required` but only `available` available.
 * @param available balance available.
 * @param required requested amount to transfer.
 */
error InsufficientBalance(uint256 available, uint256 required);
/**
 * @notice Maximum mints exceeded. Allowed `allowed` but trying to mint `trying`.
 * @param trying total trying to mint.
 * @param allowed allowed amount to mint per wallet.
 */
error MaxPerWalletCap(uint256 trying, uint256 allowed);
/**
 * @notice Maximum supply exceeded. Allowed `allowed` but trying to mint `trying`.
 * @param trying total trying to mint.
 * @param allowed allowed amount to mint per wallet.
 */
error MaxSupplyExceeded(uint256 trying, uint256 allowed);
/**
 * @notice Not allowed. Address is not allowed.
 * @param _address wallet address checked.
 */
error NotAllowed(address _address);
/**
 * @notice Token does not exist.
 * @param tokenId token id checked.
 */
error DoesNotExist(uint256 tokenId);

/**
 * @title BBPCCreator
 * @author Block Block Punch Click (blockblockpunchclick.com)
 * @dev Standard ERC721A implementation
 *
 * ERC721A NFT contract, with a presale phase (paid tokens).
 *
 * In addition to using ERC721A, gas is optimized via Merkle Trees, boolean packing
 * and use of constants where possible.
 */
abstract contract BBPCCreator is
	Context,
	Ownable,
	ContractGuardian,
	ReentrancyGuard,
	LockedPaymentSplitter,
	ERC721A
{
	enum Status {
		Pending,
		PreSale,
		PublicSale,
		Finished
	}

	using SafeAddress for address;
	using ABDKMath64x64 for uint;
	using BetterBoolean for uint256;
	using SafeMath for uint256;
	using Strings for uint256;
	using ECDSA for bytes32;

	Status public status;

	uint256 public constant MAX_PER_TRANSACTION = 9;
	uint256 public constant MAX_PER_WALLET_LIMIT = 500;

	string public baseURI;
	string public provenanceHash;
	uint256 public tokensReserved;
	uint256 public mintCost = 0.07 ether;

	uint256 public immutable reserveAmount;
	uint256 public immutable maxPresaleMint;
	uint256 public immutable maxPublicMint;
	uint256 public immutable maxBatchSize;
	uint256 public immutable maxSupply;
	bool public metadataRevealed;
	bool public metadataFinalised;

	mapping(address => uint256) private _mintedPerAddress;

	/// @dev Merkle root
	bytes32 internal rootHash;

	/// @dev Events
	event PermanentURI(string _value, uint256 indexed _id);
	event TokensMinted(address indexed mintedBy, uint256 indexed tokensNumber);
	event BaseUriUpdated(string oldBaseUri, string newBaseUri);
	event CostUpdated(uint256 oldCost, uint256 newCost);
	event PresaleListInitialized(address indexed admin, bytes32 rootHash);
	event ReservedToken(address minter, address recipient, uint256 amount);
	event StatusChanged(Status status);

	constructor(
		string memory __name,
		string memory __symbol,
		string memory __baseURI,
		uint256 _maxPresaleMint,
		uint256 _maxPublicMint,
		uint256 _maxSupply,
		uint256 _reserveAmount,
		address[] memory __addresses,
		uint256[] memory __splits
	) ERC721A(__name, __symbol) SlimPaymentSplitter(__addresses, __splits) {
		baseURI = __baseURI;
		maxPresaleMint = _maxPresaleMint;
		maxPublicMint = _maxPublicMint;
		maxSupply = _maxSupply;
		maxBatchSize = _maxPresaleMint > _maxPublicMint
			? _maxPresaleMint
			: _maxPublicMint;
		reserveAmount = _reserveAmount;
	}

	/**
	 * @dev Throws if presale is NOT active.
	 */
	function _isPresaleActive() internal view {
		if (_msgSender() != owner()) {
			require(status == Status.PreSale, "Presale is not active.");
		}
	}

	/**
	 * @dev Throws if public sale is NOT active.
	 */
	function _isPublicSaleActive() internal view {
		if (_msgSender() != owner()) {
			require(status == Status.PublicSale, "Public sale is not active.");
		}
	}

	/**
	 * @dev Throws if the sender is not on the presale list
	 */
	function _isOnPresaleList(bytes32[] memory proof) internal view {
		bool isOnList = MerkleProof.verify(
			proof,
			rootHash,
			keccak256(abi.encodePacked(_msgSender()))
		);
		if (
			status != Status.PreSale || !(isOnList || _msgSender() == owner())
		) {
			revert NotAllowed(_msgSender());
		}
	}

	/**
	 * @dev Throws if max tokens per wallet
	 */
	function _isMaxTokensPerWallet(uint256 quantity) internal view {
		if (_msgSender() != owner()) {
			uint256 mintedBalance = _mintedPerAddress[_msgSender()];
			uint256 currentMintingAmount = mintedBalance + quantity;
			if (currentMintingAmount > MAX_PER_WALLET_LIMIT) {
				revert MaxPerWalletCap(
					currentMintingAmount,
					MAX_PER_WALLET_LIMIT
				);
			}
		}
	}

	/**
	 * @dev Throws if the amount sent is not equal to the total cost.
	 */
	function _isCorrectAmountProvided(uint256 quantity) internal view {
		uint256 totalCost = quantity * mintCost;
		if (msg.value < totalCost && _msgSender() != owner()) {
			revert InsufficientBalance(msg.value, totalCost);
		}
	}

	/**
	 * @dev Throws if the claim size is not valid
	 */
	function _isValidBatchSize(uint256 count) internal view {
		require(
			0 < count && count <= maxBatchSize,
			"Max tokens per batch exceeded"
		);
	}

	/**
	 * @dev Throws if the total token number being minted is zero
	 */
	function _isMintingOne(uint256 quantity) internal pure {
		require(quantity > 0, "Must mint at least 1 token");
	}

	/**
	 * @dev Throws if the total token number being minted is zero
	 */
	function _isNotRevealed() internal view {
		require(!metadataRevealed, "Must not be revealed");
	}

	/**
	 * @dev Throws if the total being minted is greater than the max supply
	 */
	function _isLessThanMaxSupply(uint256 quantity) internal view {
		if (totalSupply() + quantity > maxSupply) {
			revert MaxSupplyExceeded(totalSupply() + quantity, maxSupply);
		}
	}

	/**
	 * @dev Handles refunding the buter if the value is greater than the mint cost
	 */
	function _refundIfOver(uint256 price) private {
		require(msg.value >= price, "Need to send more ETH.");
		if (msg.value > price) {
			payable(msg.sender).transfer(msg.value - price);
		}
	}

	/**
	 * @dev Mint function for reserved tokens.
	 */
	function _internalMintTokens(address minter, uint256 quantity) internal {
		_isLessThanMaxSupply(quantity);
		_safeMint(minter, quantity);
	}

	/**
	 * @notice Reserve token(s) to multiple team members.
	 *
	 * @param frens addresses to send tokens to
	 * @param quantity the number of tokens to mint.
	 */
	function reserve(address[] memory frens, uint256 quantity)
		external
		onlyOwner
	{
		_isMintingOne(quantity);
		_isValidBatchSize(quantity);
		_isLessThanMaxSupply(quantity);

		uint256 idx;
		for (idx = 0; idx < frens.length; idx++) {
			require(frens[idx] != address(0), "Zero address");
			_internalMintTokens(frens[idx], quantity);
			tokensReserved += quantity;
			emit ReservedToken(msg.sender, frens[idx], quantity);
		}
	}

	/**
	 * @notice Reserve multiple tokens to a single team member.
	 *
	 * @param fren address to send tokens to
	 * @param quantity the number of tokens to mint.
	 */
	function reserveSingle(address fren, uint256 quantity) external onlyOwner {
		_isMintingOne(quantity);
		_isValidBatchSize(quantity);
		_isLessThanMaxSupply(quantity);

		uint256 multiple = quantity / maxBatchSize;
		for (uint256 i = 0; i < multiple; i++) {
			_internalMintTokens(fren, maxBatchSize);
		}
		uint256 remainder = quantity % maxBatchSize;
		if (remainder != 0) {
			_internalMintTokens(fren, remainder);
		}
		tokensReserved += quantity;
		emit ReservedToken(msg.sender, fren, quantity);
	}

	/**
	 * @dev The presale mint function.
	 * @param quantity Total number of tokens to mint.
	 * @param proof Cryptographic proof checked to see if the wallet address is allowed.
	 */
	function mintPresale(uint256 quantity, bytes32[] memory proof)
		public
		payable
		nonReentrant
		onlyUsers
	{
		_isMintingOne(quantity);
		_isOnPresaleList(proof);
		_isMaxTokensPerWallet(quantity);
		_isCorrectAmountProvided(quantity);
		_isLessThanMaxSupply(quantity);

		if (_msgSender() != owner()) {
			_mintedPerAddress[_msgSender()] += quantity;
		}

		// _safeMint's second argument now takes in a quantity, not a tokenId.
		_safeMint(msg.sender, quantity);
		if (_msgSender() != owner()) {
			_refundIfOver(mintCost * quantity);
		}
		emit TokensMinted(_msgSender(), quantity);
	}

	/**
	 * @dev The public mint function.
	 * @param quantity Total number of tokens to mint.
	 */
	function mint(uint256 quantity) public payable nonReentrant onlyUsers {
		_isPublicSaleActive();
		_isMaxTokensPerWallet(quantity);
		_isCorrectAmountProvided(quantity);
		_isMintingOne(quantity);
		_isLessThanMaxSupply(quantity);

		if (_msgSender() != owner()) {
			_mintedPerAddress[_msgSender()] += quantity;
		}

		// _safeMint's second argument now takes in a quantity, not a tokenId.
		_safeMint(msg.sender, quantity);
		if (_msgSender() != owner()) {
			_refundIfOver(mintCost * quantity);
		}

		emit TokensMinted(_msgSender(), quantity);
	}

	/**
	 * @dev Proves fair generation and distribution.
	 * @param _provenanceHash hash composed from all the hashes of all the NFTs, in order, with
	 * which you can verify that the set is the exact same as the ones that we’ve generated.
	 */
	function setProvenanceHash(string memory _provenanceHash) public onlyOwner {
		_isNotRevealed();
		require(
			bytes(provenanceHash).length == 0,
			"Provenance hash already set"
		);
		provenanceHash = _provenanceHash;
	}

	/**
	 * @dev Set the presale list
	 * @param _rootHash Root hash of the Merkle tree
	 */
	function setPresaleList(bytes32 _rootHash) public onlyOwner {
		rootHash = _rootHash;
		emit PresaleListInitialized(_msgSender(), rootHash);
	}

	/**
	 * @dev Check to see if the address is on the presale list.
	 * @param claimer The address trying to claim the tokens.
	 * @param proof Merkle proof of the claimer.
	 */
	function onPresaleList(address claimer, bytes32[] memory proof)
		external
		view
		returns (bool)
	{
		return
			MerkleProof.verify(
				proof,
				rootHash,
				keccak256(abi.encodePacked(claimer))
			);
	}

	/**
	 * @dev Set the base URI for the tokens
	 * @param baseURI_ Base URI for the token
	 */
	function setBaseURI(string memory baseURI_) external onlyOwner {
		require(!metadataFinalised, "Metadata already revealed");

		string memory _currentURI = baseURI;
		baseURI = baseURI_;
		emit BaseUriUpdated(_currentURI, baseURI_);
	}

	/**
	 * @notice This is a mint cost override
	 * @dev Handles setting the mint cost
	 * @param _newCost is the new cost to associate with minting
	 */
	function setMintCost(uint256 _newCost) public onlyOwner {
		uint256 currentCost = mintCost;
		mintCost = _newCost;
		emit CostUpdated(currentCost, _newCost);
	}

	/**
	 * @dev Retrieves the token information
	 * @param tokenId is the token id to retrieve data for
	 */
	function tokenURI(uint256 tokenId)
		public
		view
		virtual
		override
		returns (string memory)
	{
		require(_exists(tokenId), "No token");
		string memory baseURI_ = _baseURI();
		require(bytes(baseURI_).length > 0, "Base unset");
		return
			metadataRevealed && bytes(baseURI_).length != 0
				? string(abi.encodePacked(baseURI_, tokenId.toString()))
				: baseURI_;
	}

	/**
	 * @dev Handles hiding the pre-reveal metadata and revealing the final metadata.
	 */
	function revealMetadata() public onlyOwner {
		require(bytes(provenanceHash).length > 0, "Provenance hash not set");
		require(!metadataRevealed, "Metadata already revealed");
		metadataRevealed = true;
	}

	/**
	 * @dev Handles updating the status
	 */
	function setStatus(Status _status) external onlyOwner {
		status = _status;
		emit StatusChanged(_status);
	}

	/**
	 * @dev Ensures the baseURI can no longer be set
	 */
	function finalizeMetadata() public onlyOwner {
		require(!metadataFinalised, "Metadata already finalised");
		metadataFinalised = true;
	}

	/**
	 * @dev Fetches the baseURI
	 */
	function _baseURI() internal view override returns (string memory) {
		return baseURI;
	}

	function getOwnershipData(uint256 tokenId)
		external
		view
		returns (TokenOwnership memory)
	{
		return _ownershipOf(tokenId);
	}
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.4;

/// @author Block Block Punch Click (blockblockpunchclick.com)

contract RoyaltySplits {
	address[] internal addresses = [
		0x39fe417823d976AD135CdbDC5881b75A7cEA0c24, // founder
		0x9262890D8f137501AAC2bEe8720D4177F2d1543b, // production
		0xB03dD45C61ABE74b10148F049C2Cca3098Ef50BF // developer
	];

	uint256[] internal splits = [58, 21, 21];
}

// SPDX-License-Identifier: MIT
// Creator: Chiru Labs

pragma solidity ^0.8.4;

import '@openzeppelin/contracts/token/ERC721/IERC721.sol';
import '@openzeppelin/contracts/token/ERC721/IERC721Receiver.sol';
import '@openzeppelin/contracts/token/ERC721/extensions/IERC721Metadata.sol';
import '@openzeppelin/contracts/utils/Address.sol';
import '@openzeppelin/contracts/utils/Context.sol';
import '@openzeppelin/contracts/utils/Strings.sol';
import '@openzeppelin/contracts/utils/introspection/ERC165.sol';

error ApprovalCallerNotOwnerNorApproved();
error ApprovalQueryForNonexistentToken();
error ApproveToCaller();
error ApprovalToCurrentOwner();
error BalanceQueryForZeroAddress();
error MintToZeroAddress();
error MintZeroQuantity();
error OwnerQueryForNonexistentToken();
error TransferCallerNotOwnerNorApproved();
error TransferFromIncorrectOwner();
error TransferToNonERC721ReceiverImplementer();
error TransferToZeroAddress();
error URIQueryForNonexistentToken();

/**
 * @dev Implementation of https://eips.ethereum.org/EIPS/eip-721[ERC721] Non-Fungible Token Standard, including
 * the Metadata extension. Built to optimize for lower gas during batch mints.
 *
 * Assumes serials are sequentially minted starting at _startTokenId() (defaults to 0, e.g. 0, 1, 2, 3..).
 *
 * Assumes that an owner cannot have more than 2**64 - 1 (max value of uint64) of supply.
 *
 * Assumes that the maximum token id cannot exceed 2**256 - 1 (max value of uint256).
 */
contract ERC721A is Context, ERC165, IERC721, IERC721Metadata {
    using Address for address;
    using Strings for uint256;

    // Compiler will pack this into a single 256bit word.
    struct TokenOwnership {
        // The address of the owner.
        address addr;
        // Keeps track of the start time of ownership with minimal overhead for tokenomics.
        uint64 startTimestamp;
        // Whether the token has been burned.
        bool burned;
    }

    // Compiler will pack this into a single 256bit word.
    struct AddressData {
        // Realistically, 2**64-1 is more than enough.
        uint64 balance;
        // Keeps track of mint count with minimal overhead for tokenomics.
        uint64 numberMinted;
        // Keeps track of burn count with minimal overhead for tokenomics.
        uint64 numberBurned;
        // For miscellaneous variable(s) pertaining to the address
        // (e.g. number of whitelist mint slots used).
        // If there are multiple variables, please pack them into a uint64.
        uint64 aux;
    }

    // The tokenId of the next token to be minted.
    uint256 internal _currentIndex;

    // The number of tokens burned.
    uint256 internal _burnCounter;

    // Token name
    string private _name;

    // Token symbol
    string private _symbol;

    // Mapping from token ID to ownership details
    // An empty struct value does not necessarily mean the token is unowned. See _ownershipOf implementation for details.
    mapping(uint256 => TokenOwnership) internal _ownerships;

    // Mapping owner address to address data
    mapping(address => AddressData) private _addressData;

    // Mapping from token ID to approved address
    mapping(uint256 => address) private _tokenApprovals;

    // Mapping from owner to operator approvals
    mapping(address => mapping(address => bool)) private _operatorApprovals;

    constructor(string memory name_, string memory symbol_) {
        _name = name_;
        _symbol = symbol_;
        _currentIndex = _startTokenId();
    }

    /**
     * To change the starting tokenId, please override this function.
     */
    function _startTokenId() internal view virtual returns (uint256) {
        return 0;
    }

    /**
     * @dev Burned tokens are calculated here, use _totalMinted() if you want to count just minted tokens.
     */
    function totalSupply() public view returns (uint256) {
        // Counter underflow is impossible as _burnCounter cannot be incremented
        // more than _currentIndex - _startTokenId() times
        unchecked {
            return _currentIndex - _burnCounter - _startTokenId();
        }
    }

    /**
     * Returns the total amount of tokens minted in the contract.
     */
    function _totalMinted() internal view returns (uint256) {
        // Counter underflow is impossible as _currentIndex does not decrement,
        // and it is initialized to _startTokenId()
        unchecked {
            return _currentIndex - _startTokenId();
        }
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
    function balanceOf(address owner) public view override returns (uint256) {
        if (owner == address(0)) revert BalanceQueryForZeroAddress();
        return uint256(_addressData[owner].balance);
    }

    /**
     * Returns the number of tokens minted by `owner`.
     */
    function _numberMinted(address owner) internal view returns (uint256) {
        return uint256(_addressData[owner].numberMinted);
    }

    /**
     * Returns the number of tokens burned by or on behalf of `owner`.
     */
    function _numberBurned(address owner) internal view returns (uint256) {
        return uint256(_addressData[owner].numberBurned);
    }

    /**
     * Returns the auxillary data for `owner`. (e.g. number of whitelist mint slots used).
     */
    function _getAux(address owner) internal view returns (uint64) {
        return _addressData[owner].aux;
    }

    /**
     * Sets the auxillary data for `owner`. (e.g. number of whitelist mint slots used).
     * If there are multiple variables, please pack them into a uint64.
     */
    function _setAux(address owner, uint64 aux) internal {
        _addressData[owner].aux = aux;
    }

    /**
     * Gas spent here starts off proportional to the maximum mint batch size.
     * It gradually moves to O(1) as tokens get transferred around in the collection over time.
     */
    function _ownershipOf(uint256 tokenId) internal view returns (TokenOwnership memory) {
        uint256 curr = tokenId;

        unchecked {
            if (_startTokenId() <= curr && curr < _currentIndex) {
                TokenOwnership memory ownership = _ownerships[curr];
                if (!ownership.burned) {
                    if (ownership.addr != address(0)) {
                        return ownership;
                    }
                    // Invariant:
                    // There will always be an ownership that has an address and is not burned
                    // before an ownership that does not have an address and is not burned.
                    // Hence, curr will not underflow.
                    while (true) {
                        curr--;
                        ownership = _ownerships[curr];
                        if (ownership.addr != address(0)) {
                            return ownership;
                        }
                    }
                }
            }
        }
        revert OwnerQueryForNonexistentToken();
    }

    /**
     * @dev See {IERC721-ownerOf}.
     */
    function ownerOf(uint256 tokenId) public view override returns (address) {
        return _ownershipOf(tokenId).addr;
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
        if (!_exists(tokenId)) revert URIQueryForNonexistentToken();

        string memory baseURI = _baseURI();
        return bytes(baseURI).length != 0 ? string(abi.encodePacked(baseURI, tokenId.toString())) : '';
    }

    /**
     * @dev Base URI for computing {tokenURI}. If set, the resulting URI for each
     * token will be the concatenation of the `baseURI` and the `tokenId`. Empty
     * by default, can be overriden in child contracts.
     */
    function _baseURI() internal view virtual returns (string memory) {
        return '';
    }

    /**
     * @dev See {IERC721-approve}.
     */
    function approve(address to, uint256 tokenId) public override {
        address owner = ERC721A.ownerOf(tokenId);
        if (to == owner) revert ApprovalToCurrentOwner();

        if (_msgSender() != owner && !isApprovedForAll(owner, _msgSender())) {
            revert ApprovalCallerNotOwnerNorApproved();
        }

        _approve(to, tokenId, owner);
    }

    /**
     * @dev See {IERC721-getApproved}.
     */
    function getApproved(uint256 tokenId) public view override returns (address) {
        if (!_exists(tokenId)) revert ApprovalQueryForNonexistentToken();

        return _tokenApprovals[tokenId];
    }

    /**
     * @dev See {IERC721-setApprovalForAll}.
     */
    function setApprovalForAll(address operator, bool approved) public virtual override {
        if (operator == _msgSender()) revert ApproveToCaller();

        _operatorApprovals[_msgSender()][operator] = approved;
        emit ApprovalForAll(_msgSender(), operator, approved);
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
        safeTransferFrom(from, to, tokenId, '');
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
        _transfer(from, to, tokenId);
        if (to.isContract() && !_checkContractOnERC721Received(from, to, tokenId, _data)) {
            revert TransferToNonERC721ReceiverImplementer();
        }
    }

    /**
     * @dev Returns whether `tokenId` exists.
     *
     * Tokens can be managed by their owner or approved accounts via {approve} or {setApprovalForAll}.
     *
     * Tokens start existing when they are minted (`_mint`),
     */
    function _exists(uint256 tokenId) internal view returns (bool) {
        return _startTokenId() <= tokenId && tokenId < _currentIndex && !_ownerships[tokenId].burned;
    }

    function _safeMint(address to, uint256 quantity) internal {
        _safeMint(to, quantity, '');
    }

    /**
     * @dev Safely mints `quantity` tokens and transfers them to `to`.
     *
     * Requirements:
     *
     * - If `to` refers to a smart contract, it must implement {IERC721Receiver-onERC721Received}, which is called for each safe transfer.
     * - `quantity` must be greater than 0.
     *
     * Emits a {Transfer} event.
     */
    function _safeMint(
        address to,
        uint256 quantity,
        bytes memory _data
    ) internal {
        _mint(to, quantity, _data, true);
    }

    /**
     * @dev Mints `quantity` tokens and transfers them to `to`.
     *
     * Requirements:
     *
     * - `to` cannot be the zero address.
     * - `quantity` must be greater than 0.
     *
     * Emits a {Transfer} event.
     */
    function _mint(
        address to,
        uint256 quantity,
        bytes memory _data,
        bool safe
    ) internal {
        uint256 startTokenId = _currentIndex;
        if (to == address(0)) revert MintToZeroAddress();
        if (quantity == 0) revert MintZeroQuantity();

        _beforeTokenTransfers(address(0), to, startTokenId, quantity);

        // Overflows are incredibly unrealistic.
        // balance or numberMinted overflow if current value of either + quantity > 1.8e19 (2**64) - 1
        // updatedIndex overflows if _currentIndex + quantity > 1.2e77 (2**256) - 1
        unchecked {
            _addressData[to].balance += uint64(quantity);
            _addressData[to].numberMinted += uint64(quantity);

            _ownerships[startTokenId].addr = to;
            _ownerships[startTokenId].startTimestamp = uint64(block.timestamp);

            uint256 updatedIndex = startTokenId;
            uint256 end = updatedIndex + quantity;

            if (safe && to.isContract()) {
                do {
                    emit Transfer(address(0), to, updatedIndex);
                    if (!_checkContractOnERC721Received(address(0), to, updatedIndex++, _data)) {
                        revert TransferToNonERC721ReceiverImplementer();
                    }
                } while (updatedIndex != end);
                // Reentrancy protection
                if (_currentIndex != startTokenId) revert();
            } else {
                do {
                    emit Transfer(address(0), to, updatedIndex++);
                } while (updatedIndex != end);
            }
            _currentIndex = updatedIndex;
        }
        _afterTokenTransfers(address(0), to, startTokenId, quantity);
    }

    /**
     * @dev Transfers `tokenId` from `from` to `to`.
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
    ) private {
        TokenOwnership memory prevOwnership = _ownershipOf(tokenId);

        if (prevOwnership.addr != from) revert TransferFromIncorrectOwner();

        bool isApprovedOrOwner = (_msgSender() == from ||
            isApprovedForAll(from, _msgSender()) ||
            getApproved(tokenId) == _msgSender());

        if (!isApprovedOrOwner) revert TransferCallerNotOwnerNorApproved();
        if (to == address(0)) revert TransferToZeroAddress();

        _beforeTokenTransfers(from, to, tokenId, 1);

        // Clear approvals from the previous owner
        _approve(address(0), tokenId, from);

        // Underflow of the sender's balance is impossible because we check for
        // ownership above and the recipient's balance can't realistically overflow.
        // Counter overflow is incredibly unrealistic as tokenId would have to be 2**256.
        unchecked {
            _addressData[from].balance -= 1;
            _addressData[to].balance += 1;

            TokenOwnership storage currSlot = _ownerships[tokenId];
            currSlot.addr = to;
            currSlot.startTimestamp = uint64(block.timestamp);

            // If the ownership slot of tokenId+1 is not explicitly set, that means the transfer initiator owns it.
            // Set the slot of tokenId+1 explicitly in storage to maintain correctness for ownerOf(tokenId+1) calls.
            uint256 nextTokenId = tokenId + 1;
            TokenOwnership storage nextSlot = _ownerships[nextTokenId];
            if (nextSlot.addr == address(0)) {
                // This will suffice for checking _exists(nextTokenId),
                // as a burned slot cannot contain the zero address.
                if (nextTokenId != _currentIndex) {
                    nextSlot.addr = from;
                    nextSlot.startTimestamp = prevOwnership.startTimestamp;
                }
            }
        }

        emit Transfer(from, to, tokenId);
        _afterTokenTransfers(from, to, tokenId, 1);
    }

    /**
     * @dev This is equivalent to _burn(tokenId, false)
     */
    function _burn(uint256 tokenId) internal virtual {
        _burn(tokenId, false);
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
    function _burn(uint256 tokenId, bool approvalCheck) internal virtual {
        TokenOwnership memory prevOwnership = _ownershipOf(tokenId);

        address from = prevOwnership.addr;

        if (approvalCheck) {
            bool isApprovedOrOwner = (_msgSender() == from ||
                isApprovedForAll(from, _msgSender()) ||
                getApproved(tokenId) == _msgSender());

            if (!isApprovedOrOwner) revert TransferCallerNotOwnerNorApproved();
        }

        _beforeTokenTransfers(from, address(0), tokenId, 1);

        // Clear approvals from the previous owner
        _approve(address(0), tokenId, from);

        // Underflow of the sender's balance is impossible because we check for
        // ownership above and the recipient's balance can't realistically overflow.
        // Counter overflow is incredibly unrealistic as tokenId would have to be 2**256.
        unchecked {
            AddressData storage addressData = _addressData[from];
            addressData.balance -= 1;
            addressData.numberBurned += 1;

            // Keep track of who burned the token, and the timestamp of burning.
            TokenOwnership storage currSlot = _ownerships[tokenId];
            currSlot.addr = from;
            currSlot.startTimestamp = uint64(block.timestamp);
            currSlot.burned = true;

            // If the ownership slot of tokenId+1 is not explicitly set, that means the burn initiator owns it.
            // Set the slot of tokenId+1 explicitly in storage to maintain correctness for ownerOf(tokenId+1) calls.
            uint256 nextTokenId = tokenId + 1;
            TokenOwnership storage nextSlot = _ownerships[nextTokenId];
            if (nextSlot.addr == address(0)) {
                // This will suffice for checking _exists(nextTokenId),
                // as a burned slot cannot contain the zero address.
                if (nextTokenId != _currentIndex) {
                    nextSlot.addr = from;
                    nextSlot.startTimestamp = prevOwnership.startTimestamp;
                }
            }
        }

        emit Transfer(from, address(0), tokenId);
        _afterTokenTransfers(from, address(0), tokenId, 1);

        // Overflow not possible, as _burnCounter cannot be exceed _currentIndex times.
        unchecked {
            _burnCounter++;
        }
    }

    /**
     * @dev Approve `to` to operate on `tokenId`
     *
     * Emits a {Approval} event.
     */
    function _approve(
        address to,
        uint256 tokenId,
        address owner
    ) private {
        _tokenApprovals[tokenId] = to;
        emit Approval(owner, to, tokenId);
    }

    /**
     * @dev Internal function to invoke {IERC721Receiver-onERC721Received} on a target contract.
     *
     * @param from address representing the previous owner of the given token ID
     * @param to target address that will receive the tokens
     * @param tokenId uint256 ID of the token to be transferred
     * @param _data bytes optional data to send along with the call
     * @return bool whether the call correctly returned the expected magic value
     */
    function _checkContractOnERC721Received(
        address from,
        address to,
        uint256 tokenId,
        bytes memory _data
    ) private returns (bool) {
        try IERC721Receiver(to).onERC721Received(_msgSender(), from, tokenId, _data) returns (bytes4 retval) {
            return retval == IERC721Receiver(to).onERC721Received.selector;
        } catch (bytes memory reason) {
            if (reason.length == 0) {
                revert TransferToNonERC721ReceiverImplementer();
            } else {
                assembly {
                    revert(add(32, reason), mload(reason))
                }
            }
        }
    }

    /**
     * @dev Hook that is called before a set of serially-ordered token ids are about to be transferred. This includes minting.
     * And also called before burning one token.
     *
     * startTokenId - the first token id to be transferred
     * quantity - the amount to be transferred
     *
     * Calling conditions:
     *
     * - When `from` and `to` are both non-zero, `from`'s `tokenId` will be
     * transferred to `to`.
     * - When `from` is zero, `tokenId` will be minted for `to`.
     * - When `to` is zero, `tokenId` will be burned by `from`.
     * - `from` and `to` are never both zero.
     */
    function _beforeTokenTransfers(
        address from,
        address to,
        uint256 startTokenId,
        uint256 quantity
    ) internal virtual {}

    /**
     * @dev Hook that is called after a set of serially-ordered token ids have been transferred. This includes
     * minting.
     * And also called after one token has been burned.
     *
     * startTokenId - the first token id to be transferred
     * quantity - the amount to be transferred
     *
     * Calling conditions:
     *
     * - When `from` and `to` are both non-zero, `from`'s `tokenId` has been
     * transferred to `to`.
     * - When `from` is zero, `tokenId` has been minted for `to`.
     * - When `to` is zero, `tokenId` has been burned by `from`.
     * - `from` and `to` are never both zero.
     */
    function _afterTokenTransfers(
        address from,
        address to,
        uint256 startTokenId,
        uint256 quantity
    ) internal virtual {}
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.4;

/**
 * @title BetterBoolean
 * @author Block Block Punch Click (blockblockpunchclick.com)
 * @dev Credit to Zimri Leijen
 * See https://ethereum.stackexchange.com/a/92235
 */
library BetterBoolean {
	function getBoolean(uint256 _packedBools, uint256 _columnNumber)
		internal
		pure
		returns (bool)
	{
		uint256 flag = (_packedBools >> _columnNumber) & uint256(1);
		return (flag == 1 ? true : false);
	}

	function setBoolean(
		uint256 _packedBools,
		uint256 _columnNumber,
		bool _value
	) internal pure returns (uint256) {
		if (_value) {
			_packedBools = _packedBools | (uint256(1) << _columnNumber);
			return _packedBools;
		} else {
			_packedBools = _packedBools & ~(uint256(1) << _columnNumber);
			return _packedBools;
		}
	}
}

// SPDX-License-Identifier: BSD-4-Clause
/*
 * Handles ensuring that the contract is being called by a user and not a contract.
 */
pragma solidity 0.8.4;

library SafeAddress {
	function isContract(address account) internal view returns (bool) {
		uint size;
		assembly {
			size := extcodesize(account)
		}
		return size > 0;
	}
}

// SPDX-License-Identifier: BSD-4-Clause
/*
 * ABDK Math 64.64 Smart Contract Library.  Copyright © 2019 by ABDK Consulting.
 * Author: Mikhail Vladimirov <[email protected]>
 */
pragma solidity 0.8.4;

/**
 * Smart contract library of mathematical functions operating with signed
 * 64.64-bit fixed point numbers.  Signed 64.64-bit fixed point number is
 * basically a simple fraction whose numerator is signed 128-bit integer and
 * denominator is 2^64.  As long as denominator is always the same, there is no
 * need to store it, thus in Solidity signed 64.64-bit fixed point numbers are
 * represented by int128 type holding only the numerator.
 */
library ABDKMath64x64 {
	/*
	 * Minimum value signed 64.64-bit fixed point number may have.
	 */
	int128 private constant MIN_64x64 = -0x80000000000000000000000000000000;

	/*
	 * Maximum value signed 64.64-bit fixed point number may have.
	 */
	int128 private constant MAX_64x64 = 0x7FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF;

	/**
	 * Convert signed 256-bit integer number into signed 64.64-bit fixed point
	 * number.  Revert on overflow.
	 *
	 * @param x signed 256-bit integer number
	 * @return signed 64.64-bit fixed point number
	 */
	function fromInt(int256 x) internal pure returns (int128) {
		unchecked {
			require(x >= -0x8000000000000000 && x <= 0x7FFFFFFFFFFFFFFF);
			return int128(x << 64);
		}
	}

	/**
	 * Convert signed 64.64 fixed point number into signed 64-bit integer number
	 * rounding down.
	 *
	 * @param x signed 64.64-bit fixed point number
	 * @return signed 64-bit integer number
	 */
	function toInt(int128 x) internal pure returns (int64) {
		unchecked {
			return int64(x >> 64);
		}
	}

	/**
	 * Convert unsigned 256-bit integer number into signed 64.64-bit fixed point
	 * number.  Revert on overflow.
	 *
	 * @param x unsigned 256-bit integer number
	 * @return signed 64.64-bit fixed point number
	 */
	function fromUInt(uint256 x) internal pure returns (int128) {
		unchecked {
			require(x <= 0x7FFFFFFFFFFFFFFF);
			return int128(int256(x << 64));
		}
	}

	/**
	 * Convert signed 64.64 fixed point number into unsigned 64-bit integer
	 * number rounding down.  Revert on underflow.
	 *
	 * @param x signed 64.64-bit fixed point number
	 * @return unsigned 64-bit integer number
	 */
	function toUInt(int128 x) internal pure returns (uint64) {
		unchecked {
			require(x >= 0);
			return uint64(uint128(x >> 64));
		}
	}

	/**
	 * Convert signed 128.128 fixed point number into signed 64.64-bit fixed point
	 * number rounding down.  Revert on overflow.
	 *
	 * @param x signed 128.128-bin fixed point number
	 * @return signed 64.64-bit fixed point number
	 */
	function from128x128(int256 x) internal pure returns (int128) {
		unchecked {
			int256 result = x >> 64;
			require(result >= MIN_64x64 && result <= MAX_64x64);
			return int128(result);
		}
	}

	/**
	 * Convert signed 64.64 fixed point number into signed 128.128 fixed point
	 * number.
	 *
	 * @param x signed 64.64-bit fixed point number
	 * @return signed 128.128 fixed point number
	 */
	function to128x128(int128 x) internal pure returns (int256) {
		unchecked {
			return int256(x) << 64;
		}
	}

	/**
	 * Calculate x + y.  Revert on overflow.
	 *
	 * @param x signed 64.64-bit fixed point number
	 * @param y signed 64.64-bit fixed point number
	 * @return signed 64.64-bit fixed point number
	 */
	function add(int128 x, int128 y) internal pure returns (int128) {
		unchecked {
			int256 result = int256(x) + y;
			require(result >= MIN_64x64 && result <= MAX_64x64);
			return int128(result);
		}
	}

	/**
	 * Calculate x - y.  Revert on overflow.
	 *
	 * @param x signed 64.64-bit fixed point number
	 * @param y signed 64.64-bit fixed point number
	 * @return signed 64.64-bit fixed point number
	 */
	function sub(int128 x, int128 y) internal pure returns (int128) {
		unchecked {
			int256 result = int256(x) - y;
			require(result >= MIN_64x64 && result <= MAX_64x64);
			return int128(result);
		}
	}

	/**
	 * Calculate x * y rounding down.  Revert on overflow.
	 *
	 * @param x signed 64.64-bit fixed point number
	 * @param y signed 64.64-bit fixed point number
	 * @return signed 64.64-bit fixed point number
	 */
	function mul(int128 x, int128 y) internal pure returns (int128) {
		unchecked {
			int256 result = (int256(x) * y) >> 64;
			require(result >= MIN_64x64 && result <= MAX_64x64);
			return int128(result);
		}
	}

	/**
	 * Calculate x * y rounding towards zero, where x is signed 64.64 fixed point
	 * number and y is signed 256-bit integer number.  Revert on overflow.
	 *
	 * @param x signed 64.64 fixed point number
	 * @param y signed 256-bit integer number
	 * @return signed 256-bit integer number
	 */
	function muli(int128 x, int256 y) internal pure returns (int256) {
		unchecked {
			if (x == MIN_64x64) {
				require(
					y >= -0xFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF &&
						y <= 0x1000000000000000000000000000000000000000000000000
				);
				return -y << 63;
			} else {
				bool negativeResult = false;
				if (x < 0) {
					x = -x;
					negativeResult = true;
				}
				if (y < 0) {
					y = -y; // We rely on overflow behavior here
					negativeResult = !negativeResult;
				}
				uint256 absoluteResult = mulu(x, uint256(y));
				if (negativeResult) {
					require(
						absoluteResult <=
							0x8000000000000000000000000000000000000000000000000000000000000000
					);
					return -int256(absoluteResult); // We rely on overflow behavior here
				} else {
					require(
						absoluteResult <=
							0x7FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF
					);
					return int256(absoluteResult);
				}
			}
		}
	}

	/**
	 * Calculate x * y rounding down, where x is signed 64.64 fixed point number
	 * and y is unsigned 256-bit integer number.  Revert on overflow.
	 *
	 * @param x signed 64.64 fixed point number
	 * @param y unsigned 256-bit integer number
	 * @return unsigned 256-bit integer number
	 */
	function mulu(int128 x, uint256 y) internal pure returns (uint256) {
		unchecked {
			if (y == 0) return 0;

			require(x >= 0);

			uint256 lo = (uint256(int256(x)) *
				(y & 0xFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF)) >> 64;
			uint256 hi = uint256(int256(x)) * (y >> 128);

			require(hi <= 0xFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF);
			hi <<= 64;

			require(
				hi <=
					0xFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF -
						lo
			);
			return hi + lo;
		}
	}

	/**
	 * Calculate x / y rounding towards zero.  Revert on overflow or when y is
	 * zero.
	 *
	 * @param x signed 64.64-bit fixed point number
	 * @param y signed 64.64-bit fixed point number
	 * @return signed 64.64-bit fixed point number
	 */
	function div(int128 x, int128 y) internal pure returns (int128) {
		unchecked {
			require(y != 0);
			int256 result = (int256(x) << 64) / y;
			require(result >= MIN_64x64 && result <= MAX_64x64);
			return int128(result);
		}
	}

	/**
	 * Calculate x / y rounding towards zero, where x and y are signed 256-bit
	 * integer numbers.  Revert on overflow or when y is zero.
	 *
	 * @param x signed 256-bit integer number
	 * @param y signed 256-bit integer number
	 * @return signed 64.64-bit fixed point number
	 */
	function divi(int256 x, int256 y) internal pure returns (int128) {
		unchecked {
			require(y != 0);

			bool negativeResult = false;
			if (x < 0) {
				x = -x; // We rely on overflow behavior here
				negativeResult = true;
			}
			if (y < 0) {
				y = -y; // We rely on overflow behavior here
				negativeResult = !negativeResult;
			}
			uint128 absoluteResult = divuu(uint256(x), uint256(y));
			if (negativeResult) {
				require(absoluteResult <= 0x80000000000000000000000000000000);
				return -int128(absoluteResult); // We rely on overflow behavior here
			} else {
				require(absoluteResult <= 0x7FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF);
				return int128(absoluteResult); // We rely on overflow behavior here
			}
		}
	}

	/**
	 * Calculate x / y rounding towards zero, where x and y are unsigned 256-bit
	 * integer numbers.  Revert on overflow or when y is zero.
	 *
	 * @param x unsigned 256-bit integer number
	 * @param y unsigned 256-bit integer number
	 * @return signed 64.64-bit fixed point number
	 */
	function divu(uint256 x, uint256 y) internal pure returns (int128) {
		unchecked {
			require(y != 0);
			uint128 result = divuu(x, y);
			require(result <= uint128(MAX_64x64));
			return int128(result);
		}
	}

	/**
	 * Calculate -x.  Revert on overflow.
	 *
	 * @param x signed 64.64-bit fixed point number
	 * @return signed 64.64-bit fixed point number
	 */
	function neg(int128 x) internal pure returns (int128) {
		unchecked {
			require(x != MIN_64x64);
			return -x;
		}
	}

	/**
	 * Calculate |x|.  Revert on overflow.
	 *
	 * @param x signed 64.64-bit fixed point number
	 * @return signed 64.64-bit fixed point number
	 */
	function abs(int128 x) internal pure returns (int128) {
		unchecked {
			require(x != MIN_64x64);
			return x < 0 ? -x : x;
		}
	}

	/**
	 * Calculate 1 / x rounding towards zero.  Revert on overflow or when x is
	 * zero.
	 *
	 * @param x signed 64.64-bit fixed point number
	 * @return signed 64.64-bit fixed point number
	 */
	function inv(int128 x) internal pure returns (int128) {
		unchecked {
			require(x != 0);
			int256 result = int256(0x100000000000000000000000000000000) / x;
			require(result >= MIN_64x64 && result <= MAX_64x64);
			return int128(result);
		}
	}

	/**
	 * Calculate arithmetics average of x and y, i.e. (x + y) / 2 rounding down.
	 *
	 * @param x signed 64.64-bit fixed point number
	 * @param y signed 64.64-bit fixed point number
	 * @return signed 64.64-bit fixed point number
	 */
	function avg(int128 x, int128 y) internal pure returns (int128) {
		unchecked {
			return int128((int256(x) + int256(y)) >> 1);
		}
	}

	/**
	 * Calculate geometric average of x and y, i.e. sqrt (x * y) rounding down.
	 * Revert on overflow or in case x * y is negative.
	 *
	 * @param x signed 64.64-bit fixed point number
	 * @param y signed 64.64-bit fixed point number
	 * @return signed 64.64-bit fixed point number
	 */
	function gavg(int128 x, int128 y) internal pure returns (int128) {
		unchecked {
			int256 m = int256(x) * int256(y);
			require(m >= 0);
			require(
				m <
					0x4000000000000000000000000000000000000000000000000000000000000000
			);
			return int128(sqrtu(uint256(m)));
		}
	}

	/**
	 * Calculate x^y assuming 0^0 is 1, where x is signed 64.64 fixed point number
	 * and y is unsigned 256-bit integer number.  Revert on overflow.
	 *
	 * @param x signed 64.64-bit fixed point number
	 * @param y uint256 value
	 * @return signed 64.64-bit fixed point number
	 */
	function pow(int128 x, uint256 y) internal pure returns (int128) {
		unchecked {
			bool negative = x < 0 && y & 1 == 1;

			uint256 absX = uint128(x < 0 ? -x : x);
			uint256 absResult;
			absResult = 0x100000000000000000000000000000000;

			if (absX <= 0x10000000000000000) {
				absX <<= 63;
				while (y != 0) {
					if (y & 0x1 != 0) {
						absResult = (absResult * absX) >> 127;
					}
					absX = (absX * absX) >> 127;

					if (y & 0x2 != 0) {
						absResult = (absResult * absX) >> 127;
					}
					absX = (absX * absX) >> 127;

					if (y & 0x4 != 0) {
						absResult = (absResult * absX) >> 127;
					}
					absX = (absX * absX) >> 127;

					if (y & 0x8 != 0) {
						absResult = (absResult * absX) >> 127;
					}
					absX = (absX * absX) >> 127;

					y >>= 4;
				}

				absResult >>= 64;
			} else {
				uint256 absXShift = 63;
				if (absX < 0x1000000000000000000000000) {
					absX <<= 32;
					absXShift -= 32;
				}
				if (absX < 0x10000000000000000000000000000) {
					absX <<= 16;
					absXShift -= 16;
				}
				if (absX < 0x1000000000000000000000000000000) {
					absX <<= 8;
					absXShift -= 8;
				}
				if (absX < 0x10000000000000000000000000000000) {
					absX <<= 4;
					absXShift -= 4;
				}
				if (absX < 0x40000000000000000000000000000000) {
					absX <<= 2;
					absXShift -= 2;
				}
				if (absX < 0x80000000000000000000000000000000) {
					absX <<= 1;
					absXShift -= 1;
				}

				uint256 resultShift = 0;
				while (y != 0) {
					require(absXShift < 64);

					if (y & 0x1 != 0) {
						absResult = (absResult * absX) >> 127;
						resultShift += absXShift;
						if (absResult > 0x100000000000000000000000000000000) {
							absResult >>= 1;
							resultShift += 1;
						}
					}
					absX = (absX * absX) >> 127;
					absXShift <<= 1;
					if (absX >= 0x100000000000000000000000000000000) {
						absX >>= 1;
						absXShift += 1;
					}

					y >>= 1;
				}

				require(resultShift < 64);
				absResult >>= 64 - resultShift;
			}
			int256 result = negative ? -int256(absResult) : int256(absResult);
			require(result >= MIN_64x64 && result <= MAX_64x64);
			return int128(result);
		}
	}

	/**
	 * Calculate sqrt (x) rounding down.  Revert if x < 0.
	 *
	 * @param x signed 64.64-bit fixed point number
	 * @return signed 64.64-bit fixed point number
	 */
	function sqrt(int128 x) internal pure returns (int128) {
		unchecked {
			require(x >= 0);
			return int128(sqrtu(uint256(int256(x)) << 64));
		}
	}

	/**
	 * Calculate binary logarithm of x.  Revert if x <= 0.
	 *
	 * @param x signed 64.64-bit fixed point number
	 * @return signed 64.64-bit fixed point number
	 */
	function log_2(int128 x) internal pure returns (int128) {
		unchecked {
			require(x > 0);

			int256 msb = 0;
			int256 xc = x;
			if (xc >= 0x10000000000000000) {
				xc >>= 64;
				msb += 64;
			}
			if (xc >= 0x100000000) {
				xc >>= 32;
				msb += 32;
			}
			if (xc >= 0x10000) {
				xc >>= 16;
				msb += 16;
			}
			if (xc >= 0x100) {
				xc >>= 8;
				msb += 8;
			}
			if (xc >= 0x10) {
				xc >>= 4;
				msb += 4;
			}
			if (xc >= 0x4) {
				xc >>= 2;
				msb += 2;
			}
			if (xc >= 0x2) msb += 1; // No need to shift xc anymore

			int256 result = (msb - 64) << 64;
			uint256 ux = uint256(int256(x)) << uint256(127 - msb);
			for (int256 bit = 0x8000000000000000; bit > 0; bit >>= 1) {
				ux *= ux;
				uint256 b = ux >> 255;
				ux >>= 127 + b;
				result += bit * int256(b);
			}

			return int128(result);
		}
	}

	/**
	 * Calculate natural logarithm of x.  Revert if x <= 0.
	 *
	 * @param x signed 64.64-bit fixed point number
	 * @return signed 64.64-bit fixed point number
	 */
	function ln(int128 x) internal pure returns (int128) {
		unchecked {
			require(x > 0);

			return
				int128(
					int256(
						(uint256(int256(log_2(x))) *
							0xB17217F7D1CF79ABC9E3B39803F2F6AF) >> 128
					)
				);
		}
	}

	/**
	 * Calculate binary exponent of x.  Revert on overflow.
	 *
	 * @param x signed 64.64-bit fixed point number
	 * @return signed 64.64-bit fixed point number
	 */
	function exp_2(int128 x) internal pure returns (int128) {
		unchecked {
			require(x < 0x400000000000000000); // Overflow

			if (x < -0x400000000000000000) return 0; // Underflow

			uint256 result = 0x80000000000000000000000000000000;

			if (x & 0x8000000000000000 > 0)
				result = (result * 0x16A09E667F3BCC908B2FB1366EA957D3E) >> 128;
			if (x & 0x4000000000000000 > 0)
				result = (result * 0x1306FE0A31B7152DE8D5A46305C85EDEC) >> 128;
			if (x & 0x2000000000000000 > 0)
				result = (result * 0x1172B83C7D517ADCDF7C8C50EB14A791F) >> 128;
			if (x & 0x1000000000000000 > 0)
				result = (result * 0x10B5586CF9890F6298B92B71842A98363) >> 128;
			if (x & 0x800000000000000 > 0)
				result = (result * 0x1059B0D31585743AE7C548EB68CA417FD) >> 128;
			if (x & 0x400000000000000 > 0)
				result = (result * 0x102C9A3E778060EE6F7CACA4F7A29BDE8) >> 128;
			if (x & 0x200000000000000 > 0)
				result = (result * 0x10163DA9FB33356D84A66AE336DCDFA3F) >> 128;
			if (x & 0x100000000000000 > 0)
				result = (result * 0x100B1AFA5ABCBED6129AB13EC11DC9543) >> 128;
			if (x & 0x80000000000000 > 0)
				result = (result * 0x10058C86DA1C09EA1FF19D294CF2F679B) >> 128;
			if (x & 0x40000000000000 > 0)
				result = (result * 0x1002C605E2E8CEC506D21BFC89A23A00F) >> 128;
			if (x & 0x20000000000000 > 0)
				result = (result * 0x100162F3904051FA128BCA9C55C31E5DF) >> 128;
			if (x & 0x10000000000000 > 0)
				result = (result * 0x1000B175EFFDC76BA38E31671CA939725) >> 128;
			if (x & 0x8000000000000 > 0)
				result = (result * 0x100058BA01FB9F96D6CACD4B180917C3D) >> 128;
			if (x & 0x4000000000000 > 0)
				result = (result * 0x10002C5CC37DA9491D0985C348C68E7B3) >> 128;
			if (x & 0x2000000000000 > 0)
				result = (result * 0x1000162E525EE054754457D5995292026) >> 128;
			if (x & 0x1000000000000 > 0)
				result = (result * 0x10000B17255775C040618BF4A4ADE83FC) >> 128;
			if (x & 0x800000000000 > 0)
				result = (result * 0x1000058B91B5BC9AE2EED81E9B7D4CFAB) >> 128;
			if (x & 0x400000000000 > 0)
				result = (result * 0x100002C5C89D5EC6CA4D7C8ACC017B7C9) >> 128;
			if (x & 0x200000000000 > 0)
				result = (result * 0x10000162E43F4F831060E02D839A9D16D) >> 128;
			if (x & 0x100000000000 > 0)
				result = (result * 0x100000B1721BCFC99D9F890EA06911763) >> 128;
			if (x & 0x80000000000 > 0)
				result = (result * 0x10000058B90CF1E6D97F9CA14DBCC1628) >> 128;
			if (x & 0x40000000000 > 0)
				result = (result * 0x1000002C5C863B73F016468F6BAC5CA2B) >> 128;
			if (x & 0x20000000000 > 0)
				result = (result * 0x100000162E430E5A18F6119E3C02282A5) >> 128;
			if (x & 0x10000000000 > 0)
				result = (result * 0x1000000B1721835514B86E6D96EFD1BFE) >> 128;
			if (x & 0x8000000000 > 0)
				result = (result * 0x100000058B90C0B48C6BE5DF846C5B2EF) >> 128;
			if (x & 0x4000000000 > 0)
				result = (result * 0x10000002C5C8601CC6B9E94213C72737A) >> 128;
			if (x & 0x2000000000 > 0)
				result = (result * 0x1000000162E42FFF037DF38AA2B219F06) >> 128;
			if (x & 0x1000000000 > 0)
				result = (result * 0x10000000B17217FBA9C739AA5819F44F9) >> 128;
			if (x & 0x800000000 > 0)
				result = (result * 0x1000000058B90BFCDEE5ACD3C1CEDC823) >> 128;
			if (x & 0x400000000 > 0)
				result = (result * 0x100000002C5C85FE31F35A6A30DA1BE50) >> 128;
			if (x & 0x200000000 > 0)
				result = (result * 0x10000000162E42FF0999CE3541B9FFFCF) >> 128;
			if (x & 0x100000000 > 0)
				result = (result * 0x100000000B17217F80F4EF5AADDA45554) >> 128;
			if (x & 0x80000000 > 0)
				result = (result * 0x10000000058B90BFBF8479BD5A81B51AD) >> 128;
			if (x & 0x40000000 > 0)
				result = (result * 0x1000000002C5C85FDF84BD62AE30A74CC) >> 128;
			if (x & 0x20000000 > 0)
				result = (result * 0x100000000162E42FEFB2FED257559BDAA) >> 128;
			if (x & 0x10000000 > 0)
				result = (result * 0x1000000000B17217F7D5A7716BBA4A9AE) >> 128;
			if (x & 0x8000000 > 0)
				result = (result * 0x100000000058B90BFBE9DDBAC5E109CCE) >> 128;
			if (x & 0x4000000 > 0)
				result = (result * 0x10000000002C5C85FDF4B15DE6F17EB0D) >> 128;
			if (x & 0x2000000 > 0)
				result = (result * 0x1000000000162E42FEFA494F1478FDE05) >> 128;
			if (x & 0x1000000 > 0)
				result = (result * 0x10000000000B17217F7D20CF927C8E94C) >> 128;
			if (x & 0x800000 > 0)
				result = (result * 0x1000000000058B90BFBE8F71CB4E4B33D) >> 128;
			if (x & 0x400000 > 0)
				result = (result * 0x100000000002C5C85FDF477B662B26945) >> 128;
			if (x & 0x200000 > 0)
				result = (result * 0x10000000000162E42FEFA3AE53369388C) >> 128;
			if (x & 0x100000 > 0)
				result = (result * 0x100000000000B17217F7D1D351A389D40) >> 128;
			if (x & 0x80000 > 0)
				result = (result * 0x10000000000058B90BFBE8E8B2D3D4EDE) >> 128;
			if (x & 0x40000 > 0)
				result = (result * 0x1000000000002C5C85FDF4741BEA6E77E) >> 128;
			if (x & 0x20000 > 0)
				result = (result * 0x100000000000162E42FEFA39FE95583C2) >> 128;
			if (x & 0x10000 > 0)
				result = (result * 0x1000000000000B17217F7D1CFB72B45E1) >> 128;
			if (x & 0x8000 > 0)
				result = (result * 0x100000000000058B90BFBE8E7CC35C3F0) >> 128;
			if (x & 0x4000 > 0)
				result = (result * 0x10000000000002C5C85FDF473E242EA38) >> 128;
			if (x & 0x2000 > 0)
				result = (result * 0x1000000000000162E42FEFA39F02B772C) >> 128;
			if (x & 0x1000 > 0)
				result = (result * 0x10000000000000B17217F7D1CF7D83C1A) >> 128;
			if (x & 0x800 > 0)
				result = (result * 0x1000000000000058B90BFBE8E7BDCBE2E) >> 128;
			if (x & 0x400 > 0)
				result = (result * 0x100000000000002C5C85FDF473DEA871F) >> 128;
			if (x & 0x200 > 0)
				result = (result * 0x10000000000000162E42FEFA39EF44D91) >> 128;
			if (x & 0x100 > 0)
				result = (result * 0x100000000000000B17217F7D1CF79E949) >> 128;
			if (x & 0x80 > 0)
				result = (result * 0x10000000000000058B90BFBE8E7BCE544) >> 128;
			if (x & 0x40 > 0)
				result = (result * 0x1000000000000002C5C85FDF473DE6ECA) >> 128;
			if (x & 0x20 > 0)
				result = (result * 0x100000000000000162E42FEFA39EF366F) >> 128;
			if (x & 0x10 > 0)
				result = (result * 0x1000000000000000B17217F7D1CF79AFA) >> 128;
			if (x & 0x8 > 0)
				result = (result * 0x100000000000000058B90BFBE8E7BCD6D) >> 128;
			if (x & 0x4 > 0)
				result = (result * 0x10000000000000002C5C85FDF473DE6B2) >> 128;
			if (x & 0x2 > 0)
				result = (result * 0x1000000000000000162E42FEFA39EF358) >> 128;
			if (x & 0x1 > 0)
				result = (result * 0x10000000000000000B17217F7D1CF79AB) >> 128;

			result >>= uint256(int256(63 - (x >> 64)));
			require(result <= uint256(int256(MAX_64x64)));

			return int128(int256(result));
		}
	}

	/**
	 * Calculate natural exponent of x.  Revert on overflow.
	 *
	 * @param x signed 64.64-bit fixed point number
	 * @return signed 64.64-bit fixed point number
	 */
	function exp(int128 x) internal pure returns (int128) {
		unchecked {
			require(x < 0x400000000000000000); // Overflow

			if (x < -0x400000000000000000) return 0; // Underflow

			return
				exp_2(
					int128(
						(int256(x) * 0x171547652B82FE1777D0FFDA0D23A7D12) >> 128
					)
				);
		}
	}

	/**
	 * Calculate x / y rounding towards zero, where x and y are unsigned 256-bit
	 * integer numbers.  Revert on overflow or when y is zero.
	 *
	 * @param x unsigned 256-bit integer number
	 * @param y unsigned 256-bit integer number
	 * @return unsigned 64.64-bit fixed point number
	 */
	function divuu(uint256 x, uint256 y) private pure returns (uint128) {
		unchecked {
			require(y != 0);

			uint256 result;

			if (x <= 0xFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF)
				result = (x << 64) / y;
			else {
				uint256 msb = 192;
				uint256 xc = x >> 192;
				if (xc >= 0x100000000) {
					xc >>= 32;
					msb += 32;
				}
				if (xc >= 0x10000) {
					xc >>= 16;
					msb += 16;
				}
				if (xc >= 0x100) {
					xc >>= 8;
					msb += 8;
				}
				if (xc >= 0x10) {
					xc >>= 4;
					msb += 4;
				}
				if (xc >= 0x4) {
					xc >>= 2;
					msb += 2;
				}
				if (xc >= 0x2) msb += 1; // No need to shift xc anymore

				result = (x << (255 - msb)) / (((y - 1) >> (msb - 191)) + 1);
				require(result <= 0xFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF);

				uint256 hi = result * (y >> 128);
				uint256 lo = result * (y & 0xFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF);

				uint256 xh = x >> 192;
				uint256 xl = x << 64;

				if (xl < lo) xh -= 1;
				xl -= lo; // We rely on overflow behavior here
				lo = hi << 128;
				if (xl < lo) xh -= 1;
				xl -= lo; // We rely on overflow behavior here

				assert(xh == hi >> 128);

				result += xl / y;
			}

			require(result <= 0xFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF);
			return uint128(result);
		}
	}

	/**
	 * Calculate sqrt (x) rounding down, where x is unsigned 256-bit integer
	 * number.
	 *
	 * @param x unsigned 256-bit integer number
	 * @return unsigned 128-bit integer number
	 */
	function sqrtu(uint256 x) private pure returns (uint128) {
		unchecked {
			if (x == 0) return 0;
			else {
				uint256 xx = x;
				uint256 r = 1;
				if (xx >= 0x100000000000000000000000000000000) {
					xx >>= 128;
					r <<= 64;
				}
				if (xx >= 0x10000000000000000) {
					xx >>= 64;
					r <<= 32;
				}
				if (xx >= 0x100000000) {
					xx >>= 32;
					r <<= 16;
				}
				if (xx >= 0x10000) {
					xx >>= 16;
					r <<= 8;
				}
				if (xx >= 0x100) {
					xx >>= 8;
					r <<= 4;
				}
				if (xx >= 0x10) {
					xx >>= 4;
					r <<= 2;
				}
				if (xx >= 0x8) {
					r <<= 1;
				}
				r = (r + x / r) >> 1;
				r = (r + x / r) >> 1;
				r = (r + x / r) >> 1;
				r = (r + x / r) >> 1;
				r = (r + x / r) >> 1;
				r = (r + x / r) >> 1;
				r = (r + x / r) >> 1; // Seven iterations should be enough
				uint256 r1 = x / r;
				return uint128(r < r1 ? r : r1);
			}
		}
	}
}

// SPDX-License-Identifier: MIT

pragma solidity 0.8.4;

/**
 * @title ContractGuardian
 * @dev Helper contract to help protect against contract based mint spamming attacks.
 */
abstract contract ContractGuardian {
	modifier onlyUsers() {
		require(tx.origin == msg.sender, "Must be user");
		_;
	}
}

// SPDX-License-Identifier: MIT

pragma solidity 0.8.4;

import "./SlimPaymentSplitter.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

/**
 * @title LockedPaymentSplitter
 * @author @NiftyMike, NFT Culture
 * @dev A wrapper around SlimPaymentSplitter which adds on security elements.
 *
 * Based on OpenZeppelin Contracts v4.4.1 (finance/PaymentSplitter.sol)
 */
abstract contract LockedPaymentSplitter is SlimPaymentSplitter, Ownable {
	/**
	 * @dev Overrides release() method, so that it can only be called by owner.
	 * @notice Owner: Release funds to a specific address.
	 *
	 * @param account Payable address that will receive funds.
	 */
	function release(address payable account) public override onlyOwner {
		super.release(account);
	}

	/**
	 * @dev Triggers a transfer to caller's address of the amount of Ether they are owed, according to their percentage of the
	 * total shares and their previous withdrawals.
	 * @notice Sender: request payment.
	 */
	function releaseToSelf() public {
		super.release(payable(msg.sender));
	}
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
// OpenZeppelin Contracts v4.4.1 (utils/math/SafeMath.sol)

pragma solidity ^0.8.0;

// CAUTION
// This version of SafeMath should only be used with Solidity 0.8 or later,
// because it relies on the compiler's built in overflow checks.

/**
 * @dev Wrappers over Solidity's arithmetic operations.
 *
 * NOTE: `SafeMath` is generally not needed starting with Solidity 0.8, since the compiler
 * now has built in overflow checking.
 */
library SafeMath {
    /**
     * @dev Returns the addition of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function tryAdd(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            uint256 c = a + b;
            if (c < a) return (false, 0);
            return (true, c);
        }
    }

    /**
     * @dev Returns the substraction of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function trySub(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            if (b > a) return (false, 0);
            return (true, a - b);
        }
    }

    /**
     * @dev Returns the multiplication of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function tryMul(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            // Gas optimization: this is cheaper than requiring 'a' not being zero, but the
            // benefit is lost if 'b' is also tested.
            // See: https://github.com/OpenZeppelin/openzeppelin-contracts/pull/522
            if (a == 0) return (true, 0);
            uint256 c = a * b;
            if (c / a != b) return (false, 0);
            return (true, c);
        }
    }

    /**
     * @dev Returns the division of two unsigned integers, with a division by zero flag.
     *
     * _Available since v3.4._
     */
    function tryDiv(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            if (b == 0) return (false, 0);
            return (true, a / b);
        }
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers, with a division by zero flag.
     *
     * _Available since v3.4._
     */
    function tryMod(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            if (b == 0) return (false, 0);
            return (true, a % b);
        }
    }

    /**
     * @dev Returns the addition of two unsigned integers, reverting on
     * overflow.
     *
     * Counterpart to Solidity's `+` operator.
     *
     * Requirements:
     *
     * - Addition cannot overflow.
     */
    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        return a + b;
    }

    /**
     * @dev Returns the subtraction of two unsigned integers, reverting on
     * overflow (when the result is negative).
     *
     * Counterpart to Solidity's `-` operator.
     *
     * Requirements:
     *
     * - Subtraction cannot overflow.
     */
    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        return a - b;
    }

    /**
     * @dev Returns the multiplication of two unsigned integers, reverting on
     * overflow.
     *
     * Counterpart to Solidity's `*` operator.
     *
     * Requirements:
     *
     * - Multiplication cannot overflow.
     */
    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        return a * b;
    }

    /**
     * @dev Returns the integer division of two unsigned integers, reverting on
     * division by zero. The result is rounded towards zero.
     *
     * Counterpart to Solidity's `/` operator.
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        return a / b;
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers. (unsigned integer modulo),
     * reverting when dividing by zero.
     *
     * Counterpart to Solidity's `%` operator. This function uses a `revert`
     * opcode (which leaves remaining gas untouched) while Solidity uses an
     * invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function mod(uint256 a, uint256 b) internal pure returns (uint256) {
        return a % b;
    }

    /**
     * @dev Returns the subtraction of two unsigned integers, reverting with custom message on
     * overflow (when the result is negative).
     *
     * CAUTION: This function is deprecated because it requires allocating memory for the error
     * message unnecessarily. For custom revert reasons use {trySub}.
     *
     * Counterpart to Solidity's `-` operator.
     *
     * Requirements:
     *
     * - Subtraction cannot overflow.
     */
    function sub(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        unchecked {
            require(b <= a, errorMessage);
            return a - b;
        }
    }

    /**
     * @dev Returns the integer division of two unsigned integers, reverting with custom message on
     * division by zero. The result is rounded towards zero.
     *
     * Counterpart to Solidity's `/` operator. Note: this function uses a
     * `revert` opcode (which leaves remaining gas untouched) while Solidity
     * uses an invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function div(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        unchecked {
            require(b > 0, errorMessage);
            return a / b;
        }
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers. (unsigned integer modulo),
     * reverting with custom message when dividing by zero.
     *
     * CAUTION: This function is deprecated because it requires allocating memory for the error
     * message unnecessarily. For custom revert reasons use {tryMod}.
     *
     * Counterpart to Solidity's `%` operator. This function uses a `revert`
     * opcode (which leaves remaining gas untouched) while Solidity uses an
     * invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function mod(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        unchecked {
            require(b > 0, errorMessage);
            return a % b;
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
// OpenZeppelin Contracts v4.4.1 (utils/cryptography/ECDSA.sol)

pragma solidity ^0.8.0;

import "../Strings.sol";

/**
 * @dev Elliptic Curve Digital Signature Algorithm (ECDSA) operations.
 *
 * These functions can be used to verify that a message was signed by the holder
 * of the private keys of a given address.
 */
library ECDSA {
    enum RecoverError {
        NoError,
        InvalidSignature,
        InvalidSignatureLength,
        InvalidSignatureS,
        InvalidSignatureV
    }

    function _throwError(RecoverError error) private pure {
        if (error == RecoverError.NoError) {
            return; // no error: do nothing
        } else if (error == RecoverError.InvalidSignature) {
            revert("ECDSA: invalid signature");
        } else if (error == RecoverError.InvalidSignatureLength) {
            revert("ECDSA: invalid signature length");
        } else if (error == RecoverError.InvalidSignatureS) {
            revert("ECDSA: invalid signature 's' value");
        } else if (error == RecoverError.InvalidSignatureV) {
            revert("ECDSA: invalid signature 'v' value");
        }
    }

    /**
     * @dev Returns the address that signed a hashed message (`hash`) with
     * `signature` or error string. This address can then be used for verification purposes.
     *
     * The `ecrecover` EVM opcode allows for malleable (non-unique) signatures:
     * this function rejects them by requiring the `s` value to be in the lower
     * half order, and the `v` value to be either 27 or 28.
     *
     * IMPORTANT: `hash` _must_ be the result of a hash operation for the
     * verification to be secure: it is possible to craft signatures that
     * recover to arbitrary addresses for non-hashed data. A safe way to ensure
     * this is by receiving a hash of the original message (which may otherwise
     * be too long), and then calling {toEthSignedMessageHash} on it.
     *
     * Documentation for signature generation:
     * - with https://web3js.readthedocs.io/en/v1.3.4/web3-eth-accounts.html#sign[Web3.js]
     * - with https://docs.ethers.io/v5/api/signer/#Signer-signMessage[ethers]
     *
     * _Available since v4.3._
     */
    function tryRecover(bytes32 hash, bytes memory signature) internal pure returns (address, RecoverError) {
        // Check the signature length
        // - case 65: r,s,v signature (standard)
        // - case 64: r,vs signature (cf https://eips.ethereum.org/EIPS/eip-2098) _Available since v4.1._
        if (signature.length == 65) {
            bytes32 r;
            bytes32 s;
            uint8 v;
            // ecrecover takes the signature parameters, and the only way to get them
            // currently is to use assembly.
            assembly {
                r := mload(add(signature, 0x20))
                s := mload(add(signature, 0x40))
                v := byte(0, mload(add(signature, 0x60)))
            }
            return tryRecover(hash, v, r, s);
        } else if (signature.length == 64) {
            bytes32 r;
            bytes32 vs;
            // ecrecover takes the signature parameters, and the only way to get them
            // currently is to use assembly.
            assembly {
                r := mload(add(signature, 0x20))
                vs := mload(add(signature, 0x40))
            }
            return tryRecover(hash, r, vs);
        } else {
            return (address(0), RecoverError.InvalidSignatureLength);
        }
    }

    /**
     * @dev Returns the address that signed a hashed message (`hash`) with
     * `signature`. This address can then be used for verification purposes.
     *
     * The `ecrecover` EVM opcode allows for malleable (non-unique) signatures:
     * this function rejects them by requiring the `s` value to be in the lower
     * half order, and the `v` value to be either 27 or 28.
     *
     * IMPORTANT: `hash` _must_ be the result of a hash operation for the
     * verification to be secure: it is possible to craft signatures that
     * recover to arbitrary addresses for non-hashed data. A safe way to ensure
     * this is by receiving a hash of the original message (which may otherwise
     * be too long), and then calling {toEthSignedMessageHash} on it.
     */
    function recover(bytes32 hash, bytes memory signature) internal pure returns (address) {
        (address recovered, RecoverError error) = tryRecover(hash, signature);
        _throwError(error);
        return recovered;
    }

    /**
     * @dev Overload of {ECDSA-tryRecover} that receives the `r` and `vs` short-signature fields separately.
     *
     * See https://eips.ethereum.org/EIPS/eip-2098[EIP-2098 short signatures]
     *
     * _Available since v4.3._
     */
    function tryRecover(
        bytes32 hash,
        bytes32 r,
        bytes32 vs
    ) internal pure returns (address, RecoverError) {
        bytes32 s;
        uint8 v;
        assembly {
            s := and(vs, 0x7fffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff)
            v := add(shr(255, vs), 27)
        }
        return tryRecover(hash, v, r, s);
    }

    /**
     * @dev Overload of {ECDSA-recover} that receives the `r and `vs` short-signature fields separately.
     *
     * _Available since v4.2._
     */
    function recover(
        bytes32 hash,
        bytes32 r,
        bytes32 vs
    ) internal pure returns (address) {
        (address recovered, RecoverError error) = tryRecover(hash, r, vs);
        _throwError(error);
        return recovered;
    }

    /**
     * @dev Overload of {ECDSA-tryRecover} that receives the `v`,
     * `r` and `s` signature fields separately.
     *
     * _Available since v4.3._
     */
    function tryRecover(
        bytes32 hash,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) internal pure returns (address, RecoverError) {
        // EIP-2 still allows signature malleability for ecrecover(). Remove this possibility and make the signature
        // unique. Appendix F in the Ethereum Yellow paper (https://ethereum.github.io/yellowpaper/paper.pdf), defines
        // the valid range for s in (301): 0 < s < secp256k1n ÷ 2 + 1, and for v in (302): v ∈ {27, 28}. Most
        // signatures from current libraries generate a unique signature with an s-value in the lower half order.
        //
        // If your library generates malleable signatures, such as s-values in the upper range, calculate a new s-value
        // with 0xFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFEBAAEDCE6AF48A03BBFD25E8CD0364141 - s1 and flip v from 27 to 28 or
        // vice versa. If your library also generates signatures with 0/1 for v instead 27/28, add 27 to v to accept
        // these malleable signatures as well.
        if (uint256(s) > 0x7FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF5D576E7357A4501DDFE92F46681B20A0) {
            return (address(0), RecoverError.InvalidSignatureS);
        }
        if (v != 27 && v != 28) {
            return (address(0), RecoverError.InvalidSignatureV);
        }

        // If the signature is valid (and not malleable), return the signer address
        address signer = ecrecover(hash, v, r, s);
        if (signer == address(0)) {
            return (address(0), RecoverError.InvalidSignature);
        }

        return (signer, RecoverError.NoError);
    }

    /**
     * @dev Overload of {ECDSA-recover} that receives the `v`,
     * `r` and `s` signature fields separately.
     */
    function recover(
        bytes32 hash,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) internal pure returns (address) {
        (address recovered, RecoverError error) = tryRecover(hash, v, r, s);
        _throwError(error);
        return recovered;
    }

    /**
     * @dev Returns an Ethereum Signed Message, created from a `hash`. This
     * produces hash corresponding to the one signed with the
     * https://eth.wiki/json-rpc/API#eth_sign[`eth_sign`]
     * JSON-RPC method as part of EIP-191.
     *
     * See {recover}.
     */
    function toEthSignedMessageHash(bytes32 hash) internal pure returns (bytes32) {
        // 32 is the length in bytes of hash,
        // enforced by the type signature above
        return keccak256(abi.encodePacked("\x19Ethereum Signed Message:\n32", hash));
    }

    /**
     * @dev Returns an Ethereum Signed Message, created from `s`. This
     * produces hash corresponding to the one signed with the
     * https://eth.wiki/json-rpc/API#eth_sign[`eth_sign`]
     * JSON-RPC method as part of EIP-191.
     *
     * See {recover}.
     */
    function toEthSignedMessageHash(bytes memory s) internal pure returns (bytes32) {
        return keccak256(abi.encodePacked("\x19Ethereum Signed Message:\n", Strings.toString(s.length), s));
    }

    /**
     * @dev Returns an Ethereum Signed Typed Data, created from a
     * `domainSeparator` and a `structHash`. This produces hash corresponding
     * to the one signed with the
     * https://eips.ethereum.org/EIPS/eip-712[`eth_signTypedData`]
     * JSON-RPC method as part of EIP-712.
     *
     * See {recover}.
     */
    function toTypedDataHash(bytes32 domainSeparator, bytes32 structHash) internal pure returns (bytes32) {
        return keccak256(abi.encodePacked("\x19\x01", domainSeparator, structHash));
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/cryptography/MerkleProof.sol)

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
                computedHash = keccak256(abi.encodePacked(computedHash, proofElement));
            } else {
                // Hash(current element of the proof + current computed hash)
                computedHash = keccak256(abi.encodePacked(proofElement, computedHash));
            }
        }
        return computedHash;
    }
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
// OpenZeppelin Contracts v4.4.1 (utils/Address.sol)

pragma solidity ^0.8.0;

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
     */
    function isContract(address account) internal view returns (bool) {
        // This method relies on extcodesize, which returns 0 for contracts in
        // construction, since the code is only stored at the end of the
        // constructor execution.

        uint256 size;
        assembly {
            size := extcodesize(account)
        }
        return size > 0;
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

pragma solidity 0.8.4;

import "@openzeppelin/contracts/utils/Address.sol";
import "@openzeppelin/contracts/utils/Context.sol";

/**
 * @title SlimPaymentSplitter
 * @author @NiftyMike, NFT Culture (original)
 * @author Block Block Punch Click (blockblockpunchclick.com) (revised) minimized gas costs via shorter errors
 * @dev A drop-in slim replacement version of OZ's Payment Splitter. All ERC-20 token functionality removed.
 *
 * Based on OpenZeppelin Contracts v4.4.1 (finance/PaymentSplitter.sol)
 */
contract SlimPaymentSplitter is Context {
	event PayeeAdded(address account, uint256 shares);
	event PaymentReleased(address to, uint256 amount);
	event AllPaymentsReleased(address[] to, uint256[] amount);
	event PaymentReceived(address from, uint256 amount);

	uint256 private _totalShares;
	uint256 private _totalReleased;

	mapping(address => uint256) private _shares;
	mapping(address => uint256) private _released;

	address[] private _payees;

	/**
	 * @dev Creates an instance of `PaymentSplitter` where each account in `payees` is assigned the number of shares at
	 * the matching position in the `shares` array.
	 *
	 * All addresses in `payees` must be non-zero. Both arrays must have the same non-zero length, and there must be no
	 * duplicates in `payees`.
	 */
	constructor(address[] memory payees, uint256[] memory shares_) payable {
		require(payees.length == shares_.length, "payees and shares mismatch");
		require(payees.length > 0, "no payees");

		for (uint256 i = 0; i < payees.length; i++) {
			_addPayee(payees[i], shares_[i]);
		}
	}

	/**
	 * @dev The Ether received will be logged with {PaymentReceived} events. Note that these events are not fully
	 * reliable: it's possible for a contract to receive Ether without triggering this function. This only affects the
	 * reliability of the events, and not the actual splitting of Ether.
	 *
	 * To learn more about this see the Solidity documentation for
	 * https://solidity.readthedocs.io/en/latest/contracts.html#fallback-function[fallback
	 * functions].
	 */
	receive() external payable virtual {
		emit PaymentReceived(_msgSender(), msg.value);
	}

	/**
	 * @dev Getter for the total shares held by payees.
	 */
	function totalShares() public view returns (uint256) {
		return _totalShares;
	}

	/**
	 * @dev Getter for the total amount of Ether already released.
	 */
	function totalReleased() public view returns (uint256) {
		return _totalReleased;
	}

	/**
	 * @dev Getter for the total number of payees.
	 */
	function totalPayees() public view returns (uint256) {
		return _payees.length;
	}

	/**
	 * @dev Getter for the amount of shares held by an account.
	 */
	function shares(address account) public view returns (uint256) {
		return _shares[account];
	}

	/**
	 * @dev Getter for the amount of Ether already released to a payee.
	 */
	function released(address account) public view returns (uint256) {
		return _released[account];
	}

	/**
	 * @dev Getter for the address of the payee number `index`.
	 */
	function payee(uint256 index) public view returns (address) {
		return _payees[index];
	}

	/**
	 * @dev Triggers a transfer to `account` of the amount of Ether they are owed, according to their percentage of the
	 * total shares and their previous withdrawals.
	 */
	function release(address payable account) public virtual {
		require(_shares[account] > 0, "account has no shares");

		uint256 totalReceived = address(this).balance + totalReleased();
		uint256 payment = _pendingPayment(
			account,
			totalReceived,
			released(account)
		);

		require(payment != 0, "account is not due payment");

		_released[account] += payment;
		_totalReleased += payment;

		Address.sendValue(account, payment);
		emit PaymentReleased(account, payment);
	}

	/**
	 * @dev Triggers a release for all of the accounts in the royalty pool.
	 */
	function releaseAll() public {
		uint256 total = totalPayees();
		address[] memory _tos = new address[](total);
		uint256[] memory _amounts = new uint256[](total);
		for (uint256 i = 0; i < total; i++) {
			address payable to = payable(_payees[i]);
			uint256 amount = _shares[to];
			require(amount != uint256(0), "Share amount is zero");
			_amounts[i] = amount;
			_tos[i] = to;
			release(to);
		}
		emit AllPaymentsReleased(_tos, _amounts);
	}

	/**
	 * @dev internal logic for computing the pending payment of an `account` given the token historical balances and
	 * already released amounts.
	 */
	function _pendingPayment(
		address account,
		uint256 totalReceived,
		uint256 alreadyReleased
	) private view returns (uint256) {
		return
			(totalReceived * _shares[account]) / _totalShares - alreadyReleased;
	}

	/**
	 * @dev Add a new payee to the contract.
	 * @param account The address of the payee to add.
	 * @param shares_ The number of shares owned by the payee.
	 */
	function _addPayee(address account, uint256 shares_) private {
		require(account != address(0), "account is the zero address");
		require(shares_ > 0, "shares are 0");
		require(_shares[account] == 0, "account already has shares");

		_payees.push(account);
		_shares[account] = shares_;
		_totalShares = _totalShares + shares_;
		emit PayeeAdded(account, shares_);
	}
}