// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

import "./openzeppelin/token/ERC721/extensions/ERC721EnumerableUpgradeable.sol";
import "./openzeppelin/access/OwnableUpgradeable.sol";
import "./openzeppelin/security/PausableUpgradeable.sol";
import "./abstract/Generator.sol";
import "./abstract/Whitelist.sol";

import "./interface/ISerum.sol";
import "./interface/IMetadata.sol";
import "./interface/IBlueprint.sol";

error NotWhitelisted(address _account);
error InvalidMintAmount(uint256 _amount);
error LimitExceeded(address _account);
error SoldOut();
error GenerationLimit(uint256 _generation);
error NotEnoughEther(uint256 _given, uint256 _expected);
error InvalidBurnLength(uint256 _given, uint256 _expected);
error BurnNotOwned(address _sender, uint256 _tokenId);
error InvalidBurnGeneration(uint256 _given, uint256 _expected);
error BlueprintNotReady();
error EarlyMintIsEnabled();
error EarlyMintNotEnabled();

// LabGame V2.0
contract LabGame is ERC721EnumerableUpgradeable, OwnableUpgradeable, PausableUpgradeable, Generator, Whitelist {
	uint256 constant GEN0_PRICE = 0 ether; // @since V2.0 Free mint
	uint256 constant GEN1_PRICE = 5_000 ether;
	uint256 constant GEN2_PRICE = 12_500 ether;
	uint256 constant GEN3_PRICE = 45_000 ether;
	
	uint256 constant GEN0_MAX = 1_111;
	uint256 constant GEN1_MAX = 2_222;
	uint256 constant GEN2_MAX = 3_333;
	uint256 constant GEN3_MAX = 4_444;

	uint256 constant WHITELIST_MINT_LIMIT = 2;
	uint256 constant PUBLIC_MINT_LIMIT = 5;
	uint256 constant EXTRA_MINT_LIMIT = 20;

	uint256 constant MAX_TRAITS = 16;
	uint256 constant TYPE_OFFSET = 9;

	mapping(uint256 => uint256) tokens;
	mapping(address => uint256) whitelistMints;
	mapping(address => uint256) publicMints;

	uint256 tokenOffset;

	ISerum public serum;
	IMetadata public metadata;
	IBlueprint public blueprint;

	uint8[][MAX_TRAITS] rarities;
	uint8[][MAX_TRAITS] aliases;

	bool public earlyMintEnabled; // @since V2.0
	mapping(address => bool) public extraMintAccounts;

	/**
	 * LabGame constructor
	 * @param _name ERC721 name
	 * @param _symbol ERC721 symbol
	 * @param _serum Serum contract address
	 * @param _metadata Metadata contract address
	 * @param _vrfCoordinator VRF Coordinator address
	 * @param _keyHash Gas lane key hash
	 * @param _subscriptionId VRF subscription id
	 * @param _callbackGasLimit VRF callback gas limit
	 */
	function initialize(
		string memory _name,
		string memory _symbol,
		address _serum,
		address _metadata,
		address _vrfCoordinator,
		bytes32 _keyHash,
		uint64 _subscriptionId,
		uint32 _callbackGasLimit
	) public initializer {
		__ERC721_init(_name, _symbol);
		__Ownable_init();
		__Pausable_init();
		__Generator_init(_vrfCoordinator, _keyHash, _subscriptionId, _callbackGasLimit);
		__Whitelist_init();

		serum = ISerum(_serum);
		metadata = IMetadata(_metadata);

		// Setup rarity and alias tables for token traits
		rarities[0] = [255, 255, 255, 255, 255, 255, 255, 255];
		aliases[0] = [0, 0, 0, 0, 0, 0, 0, 0];

		rarities[1] = [89, 236, 255, 44, 179, 249, 134];
		aliases[1] = [2, 2, 0, 1, 5, 2, 5];

		rarities[2] = [50, 73, 96, 119, 142, 164, 187, 210, 233, 255, 28];
		aliases[2] = [1, 2, 3, 4, 5, 6, 7, 8, 9, 0, 0];

		rarities[3] = [255, 128, 255, 192, 128, 192, 255, 255, 255, 64, 255, 255, 64, 255, 128, 255, 128, 128, 255, 128, 255, 255, 128, 255, 255];
		aliases[3] = [0, 6, 0, 24, 7, 24, 0, 0, 0, 3, 0, 0, 5, 0, 8, 0, 11, 15, 0, 18, 0, 0, 20, 0, 0];

		rarities[4] = [199, 209, 133, 255, 209, 209, 255, 133, 255, 133, 199, 255, 199, 66, 66, 199, 255, 133, 255, 255, 66, 255, 255, 66, 250, 240];
		aliases[4] = [22, 24, 8, 0, 24, 25, 0, 11, 0, 16, 24, 0, 25, 25, 1, 22, 0, 19, 0, 0, 4, 0, 0, 5, 8, 22];

		rarities[5] = [255, 204, 255, 204, 40, 235, 204, 204, 235, 204, 204, 40, 204, 204, 204, 204];
		aliases[5] = [0, 5, 0, 8, 0, 0, 5, 8, 2, 5, 8, 2, 5, 8, 5, 8];

		rarities[6] = [158, 254, 220, 220, 158, 158, 220, 220, 220, 220, 158, 158, 238, 79, 158, 238, 79, 220, 220, 238, 158, 220, 245, 245, 245, 253, 158, 255, 253, 158, 253];
		aliases[6] = [2, 27, 22, 23, 3, 6, 24, 25, 28, 30, 7, 8, 25, 1, 9, 28, 27, 22, 23, 30, 17, 24, 25, 28, 30, 1, 18, 0, 27, 21, 1];

		rarities[7] = [255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255];
		aliases[7] = [0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0];

		rarities[8] = [112, 112, 160, 160, 208, 64, 64, 208, 255, 255];
		aliases[8] = [2, 3, 4, 7, 8, 0, 1, 9, 0, 0];

		rarities[9] = [255, 255, 255, 255, 255, 255, 255, 255];
		aliases[9] = [0, 0, 0, 0, 0, 0, 0, 0];

		rarities[10] = [235, 250, 46, 30, 255, 76];
		aliases[10] = [4, 4, 1, 0, 0, 4];

		rarities[11] = [153, 204, 255, 102];
		aliases[11] = [1, 2, 0, 0];

		rarities[12] = [81, 138, 133, 30, 184, 189, 189, 138, 235, 240, 240, 255];
		aliases[12] = [2, 5, 4, 0, 8, 9, 10, 6, 11, 11, 11, 0];

		rarities[13] = [255, 255, 255, 255, 255, 255, 255, 255];
		aliases[13] = [0, 0, 0, 0, 0, 0, 0, 0];

		rarities[14] = [76, 192, 255];
		aliases[14] = [2, 2, 0];

		rarities[15] = [236, 236, 224, 224, 249, 249, 255];
		aliases[15] = [4, 5, 0, 1, 6, 6, 0];
	}

	// -- EXTERNAL --

	// @since V2.0 - Whitelist mint no longer needed

	/**
	 * Mint scientists & mutants
	 * @param _amount Number of tokens to mint
	 * @param _burnIds Token Ids to burn as payment (for gen 1 & 2)
	 */
	function mint(uint256 _amount, uint256[] calldata _burnIds) external payable whenNotPaused {
		if (earlyMintEnabled)
			revert EarlyMintIsEnabled();

		uint256 publicMintCount = publicMints[_msgSender()];

		// Verify amount
		// @since V2.0 Transaction limit of 10, account limit of 20
		if (_amount == 0 || _amount > PUBLIC_MINT_LIMIT) revert InvalidMintAmount(_amount);
		// Verify generation and price
		uint256 id = totalMinted();
		if (id >= GEN3_MAX) revert SoldOut();
		uint256 max = id + _amount;
		uint256 generation;

		// Generation 0
		if (id < GEN0_MAX) {
			if (max > GEN0_MAX) revert GenerationLimit(0);
			// @since V2.0 - No ether required to mint
			// Account limit of PUBLIC_MINT_LIMIT not including whitelist mints
			// @since V2.0 - Fix underflow bug
			uint256 currentBalance = balanceOf(_msgSender());
			uint256 whitelistMintCount = whitelistMints[_msgSender()];
			if (
				(currentBalance >= whitelistMintCount && currentBalance - whitelistMintCount + _amount > PUBLIC_MINT_LIMIT) ||
				(publicMintCount + _amount > PUBLIC_MINT_LIMIT)
			)	revert LimitExceeded(_msgSender());

		// Generation 1
		} else if (id < GEN1_MAX) {
			if (max > GEN1_MAX) revert GenerationLimit(1);
			serum.burn(_msgSender(), _amount * GEN1_PRICE);
			generation = 1;

		// Generation 2
		} else if (id < GEN2_MAX) {
			if (max > GEN2_MAX) revert GenerationLimit(2);
			serum.burn(_msgSender(), _amount * GEN2_PRICE);
			generation = 2;

		// Generation 3
		} else if (id < GEN3_MAX) {
			if (address(blueprint) == address(0)) revert BlueprintNotReady();
			if (max > GEN3_MAX) revert GenerationLimit(3);
			serum.burn(_msgSender(), _amount * GEN3_PRICE);
			generation = 3;
		}

		// Burn tokens to mint gen 1, 2, and 3
		uint256 burnLength = _burnIds.length;
		if (generation != 0) {
			if (burnLength != _amount) revert InvalidBurnLength(burnLength, _amount);
			for (uint256 i; i < burnLength; i++) {
				// Verify token to be burned
				if (_msgSender() != ownerOf(_burnIds[i])) revert BurnNotOwned(_msgSender(), _burnIds[i]);
				if (tokens[_burnIds[i]] & 3 != generation - 1) revert InvalidBurnGeneration(tokens[_burnIds[i]] & 3, generation - 1);
				_burn(_burnIds[i]);
			}
			// Add burned tokens to id offset
			tokenOffset += burnLength;

		// Generation 0 no burn needed
		} else {
			if (burnLength != 0) revert InvalidBurnLength(burnLength, 0);
		}
		
		publicMints[_msgSender()] = publicMintCount + _amount;
		// Request token mint
		// @since V2.0 - Single transaction mint
		// Token id to mint in [id + 1, id + _amount]
		max++;
		for (uint i = id + 1; i < max; i++) {
			uint256 seed = _random(i);
			_revealToken(i, seed);
		}
	}

	function earlyMint(uint256 _amount) external whenNotPaused {
		if (!earlyMintEnabled) revert EarlyMintNotEnabled(); // Only when early mint enabled
		uint256 whitelistMintCount = whitelistMints[_msgSender()];
		uint256 publicMintCount = publicMints[_msgSender()];
		bool hasExtraMints = extraMintAccounts[_msgSender()];
		if (whitelistMintCount == 0 && publicMintCount == 0 && hasExtraMints == false)
			revert EarlyMintIsEnabled();

		uint256 limit = hasExtraMints ? EXTRA_MINT_LIMIT : PUBLIC_MINT_LIMIT;
		// Verify amount
		// @since V2.0 Transaction limit of 10, account limit of 20
		if (_amount == 0 || _amount > limit) revert InvalidMintAmount(_amount);
		// Verify generation and price
		uint256 id = totalMinted();
		uint256 max = id + _amount;
		if (id >= GEN0_MAX || max > GEN0_MAX) revert GenerationLimit(0);

		// @since V2.0 - No ether required to mint
		// Account limit of PUBLIC_MINT_LIMIT not including whitelist mints
		// @since V2.0 - Fix underflow bug
		uint256 currentBalance = balanceOf(_msgSender());
		if (
			(currentBalance >= whitelistMintCount && currentBalance - whitelistMintCount + _amount > limit) ||
			(publicMintCount + _amount > limit)
		)	revert LimitExceeded(_msgSender());

		publicMints[_msgSender()] = publicMintCount + _amount;
		// Request token mint
		// @since V2.0 - Single transaction mint
		// Token id to mint in [id + 1, id + _amount]
		max++;
		for (uint i = id + 1; i < max; i++) {
			_revealToken(i, _random(i));
		}
	}

	/**
	 * Reveal pending mints
	 */
	function reveal() external whenNotPaused {
		(, uint256 count) = pendingOf(_msgSender());
		_reveal(_msgSender());
		// Tokens minted, update offset
		tokenOffset -= count;
	}

	/**
	 * Get the metadata uri for a token
	 * @param _tokenId Token ID to query
	 * @return Token metadata json URI
	 */
	function tokenURI(uint256 _tokenId) public view override returns (string memory) {
		if (!_exists(_tokenId)) revert ERC721_QueryForNonexistentToken(_tokenId);
		return metadata.tokenURI(_tokenId);
	}

	/**
	 * Get the total number of minted tokens
	 * @return Total number of minted tokens
	 */
	function totalMinted() public view returns (uint256) {
		return totalSupply() + tokenOffset;
	}

	/**
	 * Get the data of a token
	 * @param _tokenId Token ID to query
	 * @return Token structure
	 */
	function getToken(uint256 _tokenId) external view returns (uint256) {
		if (!_exists(_tokenId)) revert ERC721_QueryForNonexistentToken(_tokenId);
		return tokens[_tokenId];
	}

	// -- INTERNAL --

	function _beforeTokenTransfer(address _from, address _to, uint256 _tokenId) internal override {
		super._beforeTokenTransfer(_from, _to, _tokenId);
		// Update serum claim on transfer and burn
		if (_from != address(0))
			serum.updateClaim(_from, _tokenId);
	}

	/**
	 * Generate and mint pending token using random seed
	 * @param _tokenId Token ID to reveal
	 * @param _seed Random seed
	 */
	function _revealToken(uint256 _tokenId, uint256 _seed) internal override {
		// Calculate generation of token
		uint256 token;
		if (_tokenId <= GEN0_MAX) {}
		else if (_tokenId <= GEN1_MAX) token = 1;
		else if (_tokenId <= GEN2_MAX) token = 2;
		else if (_tokenId <= GEN3_MAX) token = 3;
		// Select scientist or mutant
		// @since V2.0 Mint mutants at 2%
		token |= (((_seed & 0xFFFF) % 100) < 2) ? 128 : 0;
		// Loop over tokens traits (9 scientist, 8 mutant)
		(uint256 start, uint256 count) = (token & 128 != 0) ? (TYPE_OFFSET, MAX_TRAITS - TYPE_OFFSET) : (0, TYPE_OFFSET);
		for (uint256 i; i < count; i++) {
			_seed >>= 16;
			token |= _selectTrait(_seed, start + i) << (8 * i + 8);
		}
		// Save traits
		tokens[_tokenId] = token;
		// Mint token
		_safeMint(_msgSender(), _tokenId);
		// Setup serum claim for token
		serum.initializeClaim(_tokenId);
		// Mint blueprint to gen3 tokens
		if (token & 3 == 3)
			blueprint.mint(_msgSender(), _seed >> 16);
	}

	/**
	 * Select a trait from the alias tables using a random seed (16 bit)
	 * @param _seed Random seed
	 * @param _trait Trait to select
	 * @return Index of the selected trait
	 */
	function _selectTrait(uint256 _seed, uint256 _trait) internal view returns (uint256) {
		uint256 i = (_seed & 0xFF) % rarities[_trait].length;
		return (((_seed >> 8) & 0xFF) < rarities[_trait][i]) ? i : aliases[_trait][i];
	}

	/**
	 * Generate a psuedo-random number
	 * @param _seed Seed for the RNG
	 * @return Random 256 bit number
	 */
	function _random(uint256 _seed) internal view returns (uint256) {
		return uint256(keccak256(abi.encodePacked(
			tx.origin,
			blockhash(block.number - 1),
			block.timestamp,
			_seed
		)));
	}

	// -- OWNER --

	/**
	 * Enable/disable holder only early mint
	 */
	function setEarlyMintEnabled(bool _earlyMintEnabled) external onlyOwner {
		earlyMintEnabled = _earlyMintEnabled;
	}

	/**
	 * Add account to the early mint
	 * @param _accounts Account to add
	 */
	function addEarlyMintAccounts(address[] calldata _accounts) external onlyOwner {
		for (uint256 i; i < _accounts.length; i++)
			whitelistMints[_accounts[i]]++;
	}

	/**
	 * Add account to the extra mint list
	 * @param _accounts Account to add
	 */
	function addExtraMintAccounts(address[] calldata _accounts) external onlyOwner {
		for (uint256 i; i < _accounts.length; i++)
			extraMintAccounts[_accounts[i]] = true;
	}

	/**
	 * Pause the contract
	 */
	function pause() external onlyOwner {
		_pause();
	}
	
	/**
	 * Unpause the contract
	 */
	function unpause() external onlyOwner {
		_unpause();
	}

	/**
	 * Set blueprint contract
	 * @param _blueprint Address of the blueprint contract
	 */
	function setBlueprint(address _blueprint) external onlyOwner {
		blueprint = IBlueprint(_blueprint);
	}

	/**
	 * Withdraw funds to owner
	 */
	function withdraw() external onlyOwner {
		(bool os, ) = payable(owner()).call{value: address(this).balance}("");
		require(os);
	}
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (token/ERC721/extensions/ERC721Enumerable.sol)
// Modified to use custom errors instead of require strings

pragma solidity ^0.8.13;

import "../ERC721Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC721/extensions/IERC721EnumerableUpgradeable.sol";
import "../../../proxy/utils/Initializable.sol";

/**
 * @dev This implements an optional extension of {ERC721} defined in the EIP that adds
 * enumerability of all the token ids in the contract as well as all token ids owned by each
 * account.
 */

error ERC721Enumerable_IndexOutOfBounds(uint256 index, uint256 max);

abstract contract ERC721EnumerableUpgradeable is Initializable, ERC721Upgradeable, IERC721EnumerableUpgradeable {
    function __ERC721Enumerable_init() internal onlyInitializing {
    }

    function __ERC721Enumerable_init_unchained() internal onlyInitializing {
    }
    // Mapping from owner to list of owned token IDs
    mapping(address => mapping(uint256 => uint256)) private _ownedTokens;

    // Mapping from token ID to index of the owner tokens list
    mapping(uint256 => uint256) private _ownedTokensIndex;

    // Array with all token ids, used for enumeration
    uint256[] private _allTokens;

    // Mapping from token id to position in the allTokens array
    mapping(uint256 => uint256) private _allTokensIndex;

    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId) public view virtual override(IERC165Upgradeable, ERC721Upgradeable) returns (bool) {
        return interfaceId == type(IERC721EnumerableUpgradeable).interfaceId || super.supportsInterface(interfaceId);
    }

    /**
     * @dev See {IERC721Enumerable-tokenOfOwnerByIndex}.
     */
    function tokenOfOwnerByIndex(address owner, uint256 index) public view virtual override returns (uint256) {
        if (index >= ERC721Upgradeable.balanceOf(owner))
					revert ERC721Enumerable_IndexOutOfBounds(index, ERC721Upgradeable.balanceOf(owner));
        return _ownedTokens[owner][index];
    }

    /**
     * @dev See {IERC721Enumerable-totalSupply}.
     */
    function totalSupply() public view virtual override returns (uint256) {
        return _allTokens.length;
    }

    /**
     * @dev See {IERC721Enumerable-tokenByIndex}.
     */
    function tokenByIndex(uint256 index) public view virtual override returns (uint256) {
        if (index >= ERC721EnumerableUpgradeable.totalSupply())
					revert ERC721Enumerable_IndexOutOfBounds(index, ERC721EnumerableUpgradeable.totalSupply());
        return _allTokens[index];
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
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     *
     * To learn more about hooks, head to xref:ROOT:extending-contracts.adoc#using-hooks[Using Hooks].
     */
    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 tokenId
    ) internal virtual override {
        super._beforeTokenTransfer(from, to, tokenId);

        if (from == address(0)) {
            _addTokenToAllTokensEnumeration(tokenId);
        } else if (from != to) {
            _removeTokenFromOwnerEnumeration(from, tokenId);
        }
        if (to == address(0)) {
            _removeTokenFromAllTokensEnumeration(tokenId);
        } else if (to != from) {
            _addTokenToOwnerEnumeration(to, tokenId);
        }
    }

    /**
     * @dev Private function to add a token to this extension's ownership-tracking data structures.
     * @param to address representing the new owner of the given token ID
     * @param tokenId uint256 ID of the token to be added to the tokens list of the given address
     */
    function _addTokenToOwnerEnumeration(address to, uint256 tokenId) private {
        uint256 length = ERC721Upgradeable.balanceOf(to);
        _ownedTokens[to][length] = tokenId;
        _ownedTokensIndex[tokenId] = length;
    }

    /**
     * @dev Private function to add a token to this extension's token tracking data structures.
     * @param tokenId uint256 ID of the token to be added to the tokens list
     */
    function _addTokenToAllTokensEnumeration(uint256 tokenId) private {
        _allTokensIndex[tokenId] = _allTokens.length;
        _allTokens.push(tokenId);
    }

    /**
     * @dev Private function to remove a token from this extension's ownership-tracking data structures. Note that
     * while the token is not assigned a new owner, the `_ownedTokensIndex` mapping is _not_ updated: this allows for
     * gas optimizations e.g. when performing a transfer operation (avoiding double writes).
     * This has O(1) time complexity, but alters the order of the _ownedTokens array.
     * @param from address representing the previous owner of the given token ID
     * @param tokenId uint256 ID of the token to be removed from the tokens list of the given address
     */
    function _removeTokenFromOwnerEnumeration(address from, uint256 tokenId) private {
        // To prevent a gap in from's tokens array, we store the last token in the index of the token to delete, and
        // then delete the last slot (swap and pop).

        uint256 lastTokenIndex = ERC721Upgradeable.balanceOf(from) - 1;
        uint256 tokenIndex = _ownedTokensIndex[tokenId];

        // When the token to delete is the last token, the swap operation is unnecessary
        if (tokenIndex != lastTokenIndex) {
            uint256 lastTokenId = _ownedTokens[from][lastTokenIndex];

            _ownedTokens[from][tokenIndex] = lastTokenId; // Move the last token to the slot of the to-delete token
            _ownedTokensIndex[lastTokenId] = tokenIndex; // Update the moved token's index
        }

        // This also deletes the contents at the last position of the array
        delete _ownedTokensIndex[tokenId];
        delete _ownedTokens[from][lastTokenIndex];
    }

    /**
     * @dev Private function to remove a token from this extension's token tracking data structures.
     * This has O(1) time complexity, but alters the order of the _allTokens array.
     * @param tokenId uint256 ID of the token to be removed from the tokens list
     */
    function _removeTokenFromAllTokensEnumeration(uint256 tokenId) private {
        // To prevent a gap in the tokens array, we store the last token in the index of the token to delete, and
        // then delete the last slot (swap and pop).

        uint256 lastTokenIndex = _allTokens.length - 1;
        uint256 tokenIndex = _allTokensIndex[tokenId];

        // When the token to delete is the last token, the swap operation is unnecessary. However, since this occurs so
        // rarely (when the last minted token is burnt) that we still do the swap here to avoid the gas cost of adding
        // an 'if' statement (like in _removeTokenFromOwnerEnumeration)
        uint256 lastTokenId = _allTokens[lastTokenIndex];

        _allTokens[tokenIndex] = lastTokenId; // Move the last token to the slot of the to-delete token
        _allTokensIndex[lastTokenId] = tokenIndex; // Update the moved token's index

        // This also deletes the contents at the last position of the array
        delete _allTokensIndex[tokenId];
        _allTokens.pop();
    }

    /**
     * @dev This empty reserved space is put in place to allow future versions to add new
     * variables without shifting down storage in the inheritance chain.
     * See https://docs.openzeppelin.com/contracts/4.x/upgradeable#storage_gaps
     */
    uint256[46] private __gap;
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (access/Ownable.sol)
// Modified to use custom errors instead of require strings

pragma solidity ^0.8.13;

import "../utils/ContextUpgradeable.sol";
import "../proxy/utils/Initializable.sol";

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

error Ownable_CallerNotOwner(address caller, address owner);
error Ownable_NewOwnerZeroAddress();

abstract contract OwnableUpgradeable is Initializable, ContextUpgradeable {
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    /**
     * @dev Initializes the contract setting the deployer as the initial owner.
     */
    function __Ownable_init() internal onlyInitializing {
        __Ownable_init_unchained();
    }

    function __Ownable_init_unchained() internal onlyInitializing {
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
        if (owner() != _msgSender()) revert Ownable_CallerNotOwner(_msgSender(), owner());
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
        if (newOwner == address(0)) revert Ownable_NewOwnerZeroAddress();
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

    /**
     * @dev This empty reserved space is put in place to allow future versions to add new
     * variables without shifting down storage in the inheritance chain.
     * See https://docs.openzeppelin.com/contracts/4.x/upgradeable#storage_gaps
     */
    uint256[49] private __gap;
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (security/Pausable.sol)
// Modified to use custom errors instead of require strings

pragma solidity ^0.8.13;

import "../utils/ContextUpgradeable.sol";
import "../proxy/utils/Initializable.sol";

/**
 * @dev Contract module which allows children to implement an emergency stop
 * mechanism that can be triggered by an authorized account.
 *
 * This module is used through inheritance. It will make available the
 * modifiers `whenNotPaused` and `whenPaused`, which can be applied to
 * the functions of your contract. Note that they will not be pausable by
 * simply including this module, only once the modifiers are put in place.
 */

error Pausable_Paused();
error Pausable_NotPaused();

abstract contract PausableUpgradeable is Initializable, ContextUpgradeable {
    /**
     * @dev Emitted when the pause is triggered by `account`.
     */
    event Paused(address account);

    /**
     * @dev Emitted when the pause is lifted by `account`.
     */
    event Unpaused(address account);

    bool private _paused;

    /**
     * @dev Initializes the contract in unpaused state.
     */
    function __Pausable_init() internal onlyInitializing {
        __Pausable_init_unchained();
    }

    function __Pausable_init_unchained() internal onlyInitializing {
        _paused = false;
    }

    /**
     * @dev Returns true if the contract is paused, and false otherwise.
     */
    function paused() public view virtual returns (bool) {
        return _paused;
    }

    /**
     * @dev Modifier to make a function callable only when the contract is not paused.
     *
     * Requirements:
     *
     * - The contract must not be paused.
     */
    modifier whenNotPaused() {
        if (paused()) revert Pausable_Paused();
        _;
    }

    /**
     * @dev Modifier to make a function callable only when the contract is paused.
     *
     * Requirements:
     *
     * - The contract must be paused.
     */
    modifier whenPaused() {
        if (!paused()) revert Pausable_NotPaused();
        _;
    }

    /**
     * @dev Triggers stopped state.
     *
     * Requirements:
     *
     * - The contract must not be paused.
     */
    function _pause() internal virtual whenNotPaused {
        _paused = true;
        emit Paused(_msgSender());
    }

    /**
     * @dev Returns to normal state.
     *
     * Requirements:
     *
     * - The contract must be paused.
     */
    function _unpause() internal virtual whenPaused {
        _paused = false;
        emit Unpaused(_msgSender());
    }

    /**
     * @dev This empty reserved space is put in place to allow future versions to add new
     * variables without shifting down storage in the inheritance chain.
     * See https://docs.openzeppelin.com/contracts/4.x/upgradeable#storage_gaps
     */
    uint256[49] private __gap;
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

import "./VRFConsumerBaseV2Upgradable.sol";
import "@chainlink/contracts/src/v0.8/interfaces/VRFCoordinatorV2Interface.sol";
import "../openzeppelin/proxy/utils/Initializable.sol";

error AccountHasPendingMint(address _account);
error AcountHasNoPendingMint(address _account);
error InvalidAccount();
error InvalidRequestBase();
error InvalidRequestCount();
error RevealNotReady();

abstract contract Generator is VRFConsumerBaseV2Upgradable {
	VRFCoordinatorV2Interface internal vrfCoordinator;
	bytes32 internal keyHash;
	uint64 internal subscriptionId;
	uint32 internal callbackGasLimit;

	struct Mint {
		uint64 base;
		uint32 count;
		uint256[] random;
	}
	mapping(uint256 => address) internal mintRequests;
	mapping(address => Mint) internal pendingMints;

	event Requested(address indexed _account, uint256 _baseId, uint256 _count);
	event Pending(address indexed _account, uint256 _baseId, uint256 _count);
	event Revealed(address indexed _account, uint256 _tokenId);

	/**
	 * Constructor to initialize VRF
	 * @param _vrfCoordinator VRF Coordinator address
	 * @param _keyHash Gas lane key hash
	 * @param _subscriptionId VRF subscription id
	 * @param _callbackGasLimit VRF callback gas limit
	 */
	function __Generator_init(
		address _vrfCoordinator,
		bytes32 _keyHash,
		uint64 _subscriptionId,
		uint32 _callbackGasLimit
	) internal onlyInitializing {
		__VRFConsumerBaseV2_init(_vrfCoordinator);
		vrfCoordinator = VRFCoordinatorV2Interface(_vrfCoordinator);
		keyHash = _keyHash;
		subscriptionId = _subscriptionId;
		callbackGasLimit = _callbackGasLimit;
	}
	
	// -- PUBLIC -- 

	modifier zeroPending(address _account) {
		if (pendingMints[_account].base != 0) revert AccountHasPendingMint(_account);
		_;
	}

	/**
	 * Get the current pending mints of a user account
	 * @param _account Address of account to query
	 * @return Pending token base ID, amount of pending tokens
	 */
	function pendingOf(address _account) public view returns (uint256, uint256) {
		return (pendingMints[_account].base, pendingMints[_account].random.length);
	}

	// -- INTERNAL --

	/**
	 * Update pending mint with response from VRF
	 * @param _requestId Request ID that was fulfilled
	 * @param _randomWords Received random numbers
	 */
	function fulfillRandomWords(uint256 _requestId, uint256[] memory _randomWords) internal virtual override {
		// Pop request
		address account = mintRequests[_requestId];
		delete mintRequests[_requestId];

		// Update pending mints with received random numbers
		pendingMints[account].random = _randomWords;

		// Ready to reveal
		emit Pending(account, pendingMints[account].base, _randomWords.length);
	}

	/**
	 * Setup a pending mint and request numbers from VRF
	 * @param _account Account to request for
	 * @param _base Base token ID
	 * @param _count Number of tokens
	 */
	function _request(address _account, uint256 _base, uint256 _count) internal zeroPending(_account) {
		if (_account == address(0)) revert InvalidAccount();
		if (_base == 0) revert InvalidRequestBase();
		if (_count == 0) revert InvalidRequestCount();
		// Request random numbers for tokens, save request id to account
		uint256 requestId = vrfCoordinator.requestRandomWords(
			keyHash,
			subscriptionId,
			3,
			callbackGasLimit,
			uint32(_count)
		);
		mintRequests[requestId] = _account;
		// Initialize mint request with id and count
		pendingMints[_account].base = uint64(_base);
		pendingMints[_account].count = uint32(_count);
		// Mint requested
		emit Requested(_account, _base, _count);
	}

	/**
	 * Reveal pending tokens with received random numbers
	 * @param _account Account to reveal for
	 */
	function _reveal(address _account) internal {
		if (_account == address(0)) revert InvalidAccount();
		Mint memory mint = pendingMints[_account];
		if (mint.base == 0) revert AcountHasNoPendingMint(_account);
		if (mint.random.length == 0) revert RevealNotReady();
		delete pendingMints[_account];
		// Generate all tokens
		for (uint256 i; i < mint.count; i++) {
			_revealToken(mint.base + i, mint.random[i]);
			emit Revealed(_account, mint.base + i);
		}
	}

	/**
	 * Abstract function called on each token when revealing
	 * @param _tokenId Token ID to reveal
	 * @param _seed Random number from VRF for the token
	 */
	function _revealToken(uint256 _tokenId, uint256 _seed) internal virtual;

	/**
	 * Set the VRF key hash
	 * @param _keyHash New keyHash
	 */
	function _setKeyHash(bytes32 _keyHash) internal {
		keyHash = _keyHash;
	}

	/**
	 * Set the VRF subscription ID
	 * @param _subscriptionId New subscriptionId
	 */
	function _setSubscriptionId(uint64 _subscriptionId) internal {
		subscriptionId = _subscriptionId;
	}

	/**
	 * Set the VRF callback gas limit
	 * @param _callbackGasLimit New callbackGasLimit
	 */
	function _setCallbackGasLimit(uint32 _callbackGasLimit) internal {
		callbackGasLimit = _callbackGasLimit;
	}

	/**
	 * @dev This empty reserved space is put in place to allow future versions to add new
	 * variables without shifting down storage in the inheritance chain.
	 * See https://docs.openzeppelin.com/contracts/4.x/upgradeable#storage_gaps
	 */
	uint256[45] private __gap;
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

import "@openzeppelin/contracts-upgradeable/utils/cryptography/MerkleProofUpgradeable.sol";
import "../openzeppelin/proxy/utils/Initializable.sol";

error WhitelistIsEnabled();
error WhitelistNotEnabled();

abstract contract Whitelist is Initializable {
	bytes32 internal merkleRoot;

	event WhitelistEnabled();
	event WhitelistDisabled();

	/** Whitelist contstructor (empty) */
	function __Whitelist_init() internal onlyInitializing {}

	function whitelisted() public view returns (bool) {
		return merkleRoot != bytes32(0);
	}

	modifier whenWhitelisted {
		if (!whitelisted()) revert WhitelistNotEnabled();
		_;
	}

	modifier whenNotWhitelisted {
		if (whitelisted()) revert WhitelistIsEnabled();
		_;
	}

	/**
	 * Checks if an account is whitelisted using the given proof
	 * @param _account Account to verify
	 * @param _merkleProof Proof to verify the account is in the merkle tree
	 */
	function _whitelisted(address _account, bytes32[] calldata _merkleProof) internal view returns (bool) {
		return MerkleProofUpgradeable.verify(_merkleProof, merkleRoot, keccak256(abi.encodePacked(_account)));
	}

	/**
	 * Enable the whitelist and set the merkle tree root
	 * @param _merkleRoot Whitelist merkle tree root hash
	 */
	function _enableWhitelist(bytes32 _merkleRoot) internal {
		if (whitelisted()) revert WhitelistIsEnabled();
		merkleRoot = _merkleRoot;
		emit WhitelistEnabled();
	}

	/**
	 * Disable the whitelist and clear the root hash
	 */
	function _disableWhitelist() internal {
		if (!whitelisted()) revert WhitelistNotEnabled();
		delete merkleRoot;
		emit WhitelistDisabled();
	}

	/**
	 * @dev This empty reserved space is put in place to allow future versions to add new
	 * variables without shifting down storage in the inheritance chain.
	 * See https://docs.openzeppelin.com/contracts/4.x/upgradeable#storage_gaps
	 */
	uint256[49] private __gap;
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

import "./IClaimable.sol";

interface ISerum is IClaimable {
	function mint(address _to, uint256 _amount) external;
	function burn(address _from, uint256 _amount) external;
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

interface IMetadata {
	function tokenURI(uint256 _tokenId) external view returns (string memory);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

interface IBlueprint {
	function mint(address _account, uint256 _seed) external;
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.5.0) (token/ERC721/ERC721.sol)
// Modified to use custom errors instead of require strings

pragma solidity ^0.8.13;

import "@openzeppelin/contracts-upgradeable/token/ERC721/IERC721Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC721/IERC721ReceiverUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC721/extensions/IERC721MetadataUpgradeable.sol";
import "../../utils/AddressUpgradeable.sol";
import "../../utils/ContextUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/utils/StringsUpgradeable.sol";
import "../../utils/introspection/ERC165Upgradeable.sol";
import "../../proxy/utils/Initializable.sol";

/**
 * @dev Implementation of https://eips.ethereum.org/EIPS/eip-721[ERC721] Non-Fungible Token Standard, including
 * the Metadata extension, but not including the Enumerable extension, which is available separately as
 * {ERC721Enumerable}.
 */

error ERC721_QueryOnZeroAddress();
error ERC721_QueryForNonexistentToken(uint256 tokenId);
error ERC721Metadata_QueryForNonexistentToken(uint256 tokenId);
error ERC721_ApprovalToCurrentOwner(address owner);
error ERC721_CallerNotOwnerOrApproved(address caller);
error ERC721_TransferToNonReceiverImplementer(address to, uint256 tokenId);
error ERC721_MintToZeroAddress(uint256 tokenId);
error ERC721_TokenAlreadyMinted(uint256 tokenId);
error ERC721_TransferFromIncorrectOwner(address from, address expected);
error ERC721_TransferToZeroAddress(uint256 tokenId);
error ERC721_ApprovalToCaller(address caller);

contract ERC721Upgradeable is Initializable, ContextUpgradeable, ERC165Upgradeable, IERC721Upgradeable, IERC721MetadataUpgradeable {
    using AddressUpgradeable for address;
    using StringsUpgradeable for uint256;

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
    function __ERC721_init(string memory name_, string memory symbol_) internal onlyInitializing {
        __ERC721_init_unchained(name_, symbol_);
    }

    function __ERC721_init_unchained(string memory name_, string memory symbol_) internal onlyInitializing {
        _name = name_;
        _symbol = symbol_;
    }

    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId) public view virtual override(ERC165Upgradeable, IERC165Upgradeable) returns (bool) {
        return
            interfaceId == type(IERC721Upgradeable).interfaceId ||
            interfaceId == type(IERC721MetadataUpgradeable).interfaceId ||
            super.supportsInterface(interfaceId);
    }

    /**
     * @dev See {IERC721-balanceOf}.
     */
    function balanceOf(address owner) public view virtual override returns (uint256) {
        if (owner == address(0)) revert ERC721_QueryOnZeroAddress();
        return _balances[owner];
    }

    /**
     * @dev See {IERC721-ownerOf}.
     */
    function ownerOf(uint256 tokenId) public view virtual override returns (address) {
        address owner = _owners[tokenId];
        if (owner == address(0)) revert ERC721_QueryForNonexistentToken(tokenId);
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
        if (!_exists(tokenId)) revert ERC721Metadata_QueryForNonexistentToken(tokenId);

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
        address owner = ERC721Upgradeable.ownerOf(tokenId);
        if (to == owner) revert ERC721_ApprovalToCurrentOwner(to);

        if (_msgSender() != owner && !isApprovedForAll(owner, _msgSender())) revert ERC721_CallerNotOwnerOrApproved(_msgSender());
        _approve(to, tokenId);
    }

    /**
     * @dev See {IERC721-getApproved}.
     */
    function getApproved(uint256 tokenId) public view virtual override returns (address) {
        if (!_exists(tokenId)) revert ERC721_QueryForNonexistentToken(tokenId);

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
        if (!_isApprovedOrOwner(_msgSender(), tokenId)) revert ERC721_CallerNotOwnerOrApproved(_msgSender());

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
        if (!_isApprovedOrOwner(_msgSender(), tokenId)) revert ERC721_CallerNotOwnerOrApproved(_msgSender());
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
        if (!_checkOnERC721Received(from, to, tokenId, _data)) revert ERC721_TransferToNonReceiverImplementer(to, tokenId);
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
        if (!_exists(tokenId)) revert ERC721_QueryForNonexistentToken(tokenId);
        address owner = ERC721Upgradeable.ownerOf(tokenId);
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
        if (!_checkOnERC721Received(address(0), to, tokenId, _data)) revert ERC721_TransferToNonReceiverImplementer(to, tokenId);
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
        if (to == address(0)) revert ERC721_MintToZeroAddress(tokenId);
        if (_exists(tokenId)) revert ERC721_TokenAlreadyMinted(tokenId);

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
        address owner = ERC721Upgradeable.ownerOf(tokenId);

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
        if (ERC721Upgradeable.ownerOf(tokenId) != from) revert ERC721_TransferFromIncorrectOwner(from, ERC721Upgradeable.ownerOf(tokenId));
        if (to == address(0)) revert ERC721_TransferToZeroAddress(tokenId);

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
        emit Approval(ERC721Upgradeable.ownerOf(tokenId), to, tokenId);
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
        if (owner == operator) revert ERC721_ApprovalToCaller(owner);
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
            try IERC721ReceiverUpgradeable(to).onERC721Received(_msgSender(), from, tokenId, _data) returns (bytes4 retval) {
                return retval == IERC721ReceiverUpgradeable.onERC721Received.selector;
            } catch (bytes memory reason) {
                if (reason.length == 0) {
                    revert ERC721_TransferToNonReceiverImplementer(to, tokenId);
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

    /**
     * @dev This empty reserved space is put in place to allow future versions to add new
     * variables without shifting down storage in the inheritance chain.
     * See https://docs.openzeppelin.com/contracts/4.x/upgradeable#storage_gaps
     */
    uint256[44] private __gap;
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.5.0) (token/ERC721/extensions/IERC721Enumerable.sol)

pragma solidity ^0.8.0;

import "../IERC721Upgradeable.sol";

/**
 * @title ERC-721 Non-Fungible Token Standard, optional enumeration extension
 * @dev See https://eips.ethereum.org/EIPS/eip-721
 */
interface IERC721EnumerableUpgradeable is IERC721Upgradeable {
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

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.5.0) (proxy/utils/Initializable.sol)
// Modified to use custom errors instead of require strings

pragma solidity ^0.8.13;

import "../../utils/AddressUpgradeable.sol";

/**
 * @dev This is a base contract to aid in writing upgradeable contracts, or any kind of contract that will be deployed
 * behind a proxy. Since proxied contracts do not make use of a constructor, it's common to move constructor logic to an
 * external initializer function, usually called `initialize`. It then becomes necessary to protect this initializer
 * function so it can only be called once. The {initializer} modifier provided by this contract will have this effect.
 *
 * TIP: To avoid leaving the proxy in an uninitialized state, the initializer function should be called as early as
 * possible by providing the encoded function call as the `_data` argument to {ERC1967Proxy-constructor}.
 *
 * CAUTION: When used with inheritance, manual care must be taken to not invoke a parent initializer twice, or to ensure
 * that all initializers are idempotent. This is not verified automatically as constructors are by Solidity.
 *
 * [CAUTION]
 * ====
 * Avoid leaving a contract uninitialized.
 *
 * An uninitialized contract can be taken over by an attacker. This applies to both a proxy and its implementation
 * contract, which may impact the proxy. To initialize the implementation contract, you can either invoke the
 * initializer manually, or you can include a constructor to automatically mark it as initialized when it is deployed:
 *
 * [.hljs-theme-light.nopadding]
 * ```
 * /// @custom:oz-upgrades-unsafe-allow constructor
 * constructor() initializer {}
 * ```
 * ====
 */

error Initializable_AlreadyInitialized();
error Initializable_NotInitializing();

abstract contract Initializable {
    /**
     * @dev Indicates that the contract has been initialized.
     */
    bool private _initialized;

    /**
     * @dev Indicates that the contract is in the process of being initialized.
     */
    bool private _initializing;

    /**
     * @dev Modifier to protect an initializer function from being invoked twice.
     */
    modifier initializer() {
        // If the contract is initializing we ignore whether _initialized is set in order to support multiple
        // inheritance patterns, but we only do this in the context of a constructor, because in other contexts the
        // contract may have been reentered.
        if(_initializing ? !_isConstructor() : _initialized) revert Initializable_AlreadyInitialized();

        bool isTopLevelCall = !_initializing;
        if (isTopLevelCall) {
            _initializing = true;
            _initialized = true;
        }

        _;

        if (isTopLevelCall) {
            _initializing = false;
        }
    }

    /**
     * @dev Modifier to protect an initialization function so that it can only be invoked by functions with the
     * {initializer} modifier, directly or indirectly.
     */
    modifier onlyInitializing() {
        if (!_initializing) revert Initializable_NotInitializing();
        _;
    }

    function _isConstructor() private view returns (bool) {
        return !AddressUpgradeable.isContract(address(this));
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (token/ERC721/IERC721.sol)

pragma solidity ^0.8.0;

import "../../utils/introspection/IERC165Upgradeable.sol";

/**
 * @dev Required interface of an ERC721 compliant contract.
 */
interface IERC721Upgradeable is IERC165Upgradeable {
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
interface IERC721ReceiverUpgradeable {
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

import "../IERC721Upgradeable.sol";

/**
 * @title ERC-721 Non-Fungible Token Standard, optional metadata extension
 * @dev See https://eips.ethereum.org/EIPS/eip-721
 */
interface IERC721MetadataUpgradeable is IERC721Upgradeable {
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
// Modified to use custom errors instead of require strings

pragma solidity ^0.8.13;

/**
 * @dev Collection of functions related to the address type
 */

error Address_InsufficientBalance(uint256 balance, uint256 amount);
error Address_UnableToSendValue(address recipient, uint256 amount);
error Address_CallToNonContract(address target);
error Address_StaticCallToNonContract(address target);

library AddressUpgradeable {
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
        if (address(this).balance < amount) revert Address_InsufficientBalance(address(this).balance, amount);

        (bool success, ) = recipient.call{value: amount}("");
        if (!success) revert Address_UnableToSendValue(recipient, amount);
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
        if (address(this).balance < value) revert Address_InsufficientBalance(address(this).balance, value);
        if (!isContract(target)) revert Address_CallToNonContract(target);

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
        if (!isContract(target)) revert Address_StaticCallToNonContract(target);

        (bool success, bytes memory returndata) = target.staticcall(data);
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
// OpenZeppelin Contracts v4.4.1 (utils/Context.sol)
// Modified to use custom errors instead of require strings

pragma solidity ^0.8.13;
import "../proxy/utils/Initializable.sol";

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
abstract contract ContextUpgradeable is Initializable {
    function __Context_init() internal onlyInitializing {
    }

    function __Context_init_unchained() internal onlyInitializing {
    }
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes calldata) {
        return msg.data;
    }

    /**
     * @dev This empty reserved space is put in place to allow future versions to add new
     * variables without shifting down storage in the inheritance chain.
     * See https://docs.openzeppelin.com/contracts/4.x/upgradeable#storage_gaps
     */
    uint256[50] private __gap;
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/Strings.sol)

pragma solidity ^0.8.0;

/**
 * @dev String operations.
 */
library StringsUpgradeable {
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
// Modified to use custom errors instead of require strings

pragma solidity ^0.8.0;

import "@openzeppelin/contracts-upgradeable/utils/introspection/IERC165Upgradeable.sol";
import "../../proxy/utils/Initializable.sol";

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
abstract contract ERC165Upgradeable is Initializable, IERC165Upgradeable {
    function __ERC165_init() internal onlyInitializing {
    }

    function __ERC165_init_unchained() internal onlyInitializing {
    }
    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId) public view virtual override returns (bool) {
        return interfaceId == type(IERC165Upgradeable).interfaceId;
    }

    /**
     * @dev This empty reserved space is put in place to allow future versions to add new
     * variables without shifting down storage in the inheritance chain.
     * See https://docs.openzeppelin.com/contracts/4.x/upgradeable#storage_gaps
     */
    uint256[50] private __gap;
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
interface IERC165Upgradeable {
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
pragma solidity ^0.8.13;

import "../openzeppelin/proxy/utils/Initializable.sol";

// Modified to use OpenZeppelin upgradeables
/** ****************************************************************************
 * @notice Interface for contracts using VRF randomness
 * *****************************************************************************
 * @dev PURPOSE
 *
 * @dev Reggie the Random Oracle (not his real job) wants to provide randomness
 * @dev to Vera the verifier in such a way that Vera can be sure he's not
 * @dev making his output up to suit himself. Reggie provides Vera a public key
 * @dev to which he knows the secret key. Each time Vera provides a seed to
 * @dev Reggie, he gives back a value which is computed completely
 * @dev deterministically from the seed and the secret key.
 *
 * @dev Reggie provides a proof by which Vera can verify that the output was
 * @dev correctly computed once Reggie tells it to her, but without that proof,
 * @dev the output is indistinguishable to her from a uniform random sample
 * @dev from the output space.
 *
 * @dev The purpose of this contract is to make it easy for unrelated contracts
 * @dev to talk to Vera the verifier about the work Reggie is doing, to provide
 * @dev simple access to a verifiable source of randomness. It ensures 2 things:
 * @dev 1. The fulfillment came from the VRFCoordinator
 * @dev 2. The consumer contract implements fulfillRandomWords.
 * *****************************************************************************
 * @dev USAGE
 *
 * @dev Calling contracts must inherit from VRFConsumerBase, and can
 * @dev initialize VRFConsumerBase's attributes in their constructor as
 * @dev shown:
 *
 * @dev   contract VRFConsumer {
 * @dev     constructor(<other arguments>, address _vrfCoordinator, address _link)
 * @dev       VRFConsumerBase(_vrfCoordinator) public {
 * @dev         <initialization with other arguments goes here>
 * @dev       }
 * @dev   }
 *
 * @dev The oracle will have given you an ID for the VRF keypair they have
 * @dev committed to (let's call it keyHash). Create subscription, fund it
 * @dev and your consumer contract as a consumer of it (see VRFCoordinatorInterface
 * @dev subscription management functions).
 * @dev Call requestRandomWords(keyHash, subId, minimumRequestConfirmations,
 * @dev callbackGasLimit, numWords),
 * @dev see (VRFCoordinatorInterface for a description of the arguments).
 *
 * @dev Once the VRFCoordinator has received and validated the oracle's response
 * @dev to your request, it will call your contract's fulfillRandomWords method.
 *
 * @dev The randomness argument to fulfillRandomWords is a set of random words
 * @dev generated from your requestId and the blockHash of the request.
 *
 * @dev If your contract could have concurrent requests open, you can use the
 * @dev requestId returned from requestRandomWords to track which response is associated
 * @dev with which randomness request.
 * @dev See "SECURITY CONSIDERATIONS" for principles to keep in mind,
 * @dev if your contract could have multiple requests in flight simultaneously.
 *
 * @dev Colliding `requestId`s are cryptographically impossible as long as seeds
 * @dev differ.
 *
 * *****************************************************************************
 * @dev SECURITY CONSIDERATIONS
 *
 * @dev A method with the ability to call your fulfillRandomness method directly
 * @dev could spoof a VRF response with any random value, so it's critical that
 * @dev it cannot be directly called by anything other than this base contract
 * @dev (specifically, by the VRFConsumerBase.rawFulfillRandomness method).
 *
 * @dev For your users to trust that your contract's random behavior is free
 * @dev from malicious interference, it's best if you can write it so that all
 * @dev behaviors implied by a VRF response are executed *during* your
 * @dev fulfillRandomness method. If your contract must store the response (or
 * @dev anything derived from it) and use it later, you must ensure that any
 * @dev user-significant behavior which depends on that stored value cannot be
 * @dev manipulated by a subsequent VRF request.
 *
 * @dev Similarly, both miners and the VRF oracle itself have some influence
 * @dev over the order in which VRF responses appear on the blockchain, so if
 * @dev your contract could have multiple VRF requests in flight simultaneously,
 * @dev you must ensure that the order in which the VRF responses arrive cannot
 * @dev be used to manipulate your contract's user-significant behavior.
 *
 * @dev Since the block hash of the block which contains the requestRandomness
 * @dev call is mixed into the input to the VRF *last*, a sufficiently powerful
 * @dev miner could, in principle, fork the blockchain to evict the block
 * @dev containing the request, forcing the request to be included in a
 * @dev different block with a different hash, and therefore a different input
 * @dev to the VRF. However, such an attack would incur a substantial economic
 * @dev cost. This cost scales with the number of blocks the VRF oracle waits
 * @dev until it calls responds to a request. It is for this reason that
 * @dev that you can signal to an oracle you'd like them to wait longer before
 * @dev responding to the request (however this is not enforced in the contract
 * @dev and so remains effective only in the case of unmodified oracle software).
 */
abstract contract VRFConsumerBaseV2Upgradable is Initializable {
  error OnlyCoordinatorCanFulfill(address have, address want);
  address private vrfCoordinator;

  /**
   * @param _vrfCoordinator address of VRFCoordinator contract
   */
  function __VRFConsumerBaseV2_init(address _vrfCoordinator) internal onlyInitializing {
    vrfCoordinator = _vrfCoordinator;
  }

  /**
   * @notice fulfillRandomness handles the VRF response. Your contract must
   * @notice implement it. See "SECURITY CONSIDERATIONS" above for important
   * @notice principles to keep in mind when implementing your fulfillRandomness
   * @notice method.
   *
   * @dev VRFConsumerBaseV2 expects its subcontracts to have a method with this
   * @dev signature, and will call it once it has verified the proof
   * @dev associated with the randomness. (It is triggered via a call to
   * @dev rawFulfillRandomness, below.)
   *
   * @param requestId The Id initially returned by requestRandomness
   * @param randomWords the VRF output expanded to the requested number of words
   */
  function fulfillRandomWords(uint256 requestId, uint256[] memory randomWords) internal virtual;

  // rawFulfillRandomness is called by VRFCoordinator when it receives a valid VRF
  // proof. rawFulfillRandomness then calls fulfillRandomness, after validating
  // the origin of the call
  function rawFulfillRandomWords(uint256 requestId, uint256[] memory randomWords) external {
    if (msg.sender != vrfCoordinator) {
      revert OnlyCoordinatorCanFulfill(msg.sender, vrfCoordinator);
    }
    fulfillRandomWords(requestId, randomWords);
  }

	/**
	 * @dev This empty reserved space is put in place to allow future versions to add new
	 * variables without shifting down storage in the inheritance chain.
	 * See https://docs.openzeppelin.com/contracts/4.x/upgradeable#storage_gaps
	 */
	uint256[49] private __gap;
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface VRFCoordinatorV2Interface {
  /**
   * @notice Get configuration relevant for making requests
   * @return minimumRequestConfirmations global min for request confirmations
   * @return maxGasLimit global max for request gas limit
   * @return s_provingKeyHashes list of registered key hashes
   */
  function getRequestConfig()
    external
    view
    returns (
      uint16,
      uint32,
      bytes32[] memory
    );

  /**
   * @notice Request a set of random words.
   * @param keyHash - Corresponds to a particular oracle job which uses
   * that key for generating the VRF proof. Different keyHash's have different gas price
   * ceilings, so you can select a specific one to bound your maximum per request cost.
   * @param subId  - The ID of the VRF subscription. Must be funded
   * with the minimum subscription balance required for the selected keyHash.
   * @param minimumRequestConfirmations - How many blocks you'd like the
   * oracle to wait before responding to the request. See SECURITY CONSIDERATIONS
   * for why you may want to request more. The acceptable range is
   * [minimumRequestBlockConfirmations, 200].
   * @param callbackGasLimit - How much gas you'd like to receive in your
   * fulfillRandomWords callback. Note that gasleft() inside fulfillRandomWords
   * may be slightly less than this amount because of gas used calling the function
   * (argument decoding etc.), so you may need to request slightly more than you expect
   * to have inside fulfillRandomWords. The acceptable range is
   * [0, maxGasLimit]
   * @param numWords - The number of uint256 random values you'd like to receive
   * in your fulfillRandomWords callback. Note these numbers are expanded in a
   * secure way by the VRFCoordinator from a single random value supplied by the oracle.
   * @return requestId - A unique identifier of the request. Can be used to match
   * a request to a response in fulfillRandomWords.
   */
  function requestRandomWords(
    bytes32 keyHash,
    uint64 subId,
    uint16 minimumRequestConfirmations,
    uint32 callbackGasLimit,
    uint32 numWords
  ) external returns (uint256 requestId);

  /**
   * @notice Create a VRF subscription.
   * @return subId - A unique subscription id.
   * @dev You can manage the consumer set dynamically with addConsumer/removeConsumer.
   * @dev Note to fund the subscription, use transferAndCall. For example
   * @dev  LINKTOKEN.transferAndCall(
   * @dev    address(COORDINATOR),
   * @dev    amount,
   * @dev    abi.encode(subId));
   */
  function createSubscription() external returns (uint64 subId);

  /**
   * @notice Get a VRF subscription.
   * @param subId - ID of the subscription
   * @return balance - LINK balance of the subscription in juels.
   * @return reqCount - number of requests for this subscription, determines fee tier.
   * @return owner - owner of the subscription.
   * @return consumers - list of consumer address which are able to use this subscription.
   */
  function getSubscription(uint64 subId)
    external
    view
    returns (
      uint96 balance,
      uint64 reqCount,
      address owner,
      address[] memory consumers
    );

  /**
   * @notice Request subscription owner transfer.
   * @param subId - ID of the subscription
   * @param newOwner - proposed new owner of the subscription
   */
  function requestSubscriptionOwnerTransfer(uint64 subId, address newOwner) external;

  /**
   * @notice Request subscription owner transfer.
   * @param subId - ID of the subscription
   * @dev will revert if original owner of subId has
   * not requested that msg.sender become the new owner.
   */
  function acceptSubscriptionOwnerTransfer(uint64 subId) external;

  /**
   * @notice Add a consumer to a VRF subscription.
   * @param subId - ID of the subscription
   * @param consumer - New consumer which can use the subscription
   */
  function addConsumer(uint64 subId, address consumer) external;

  /**
   * @notice Remove a consumer from a VRF subscription.
   * @param subId - ID of the subscription
   * @param consumer - Consumer to remove from the subscription
   */
  function removeConsumer(uint64 subId, address consumer) external;

  /**
   * @notice Cancel a subscription
   * @param subId - ID of the subscription
   * @param to - Where to send the remaining LINK to
   */
  function cancelSubscription(uint64 subId, address to) external;
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
library MerkleProofUpgradeable {
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
pragma solidity ^0.8.13;

error NoClaimAvailable(address _account);

interface IClaimable {
	function claim() external;
	function pendingClaim(address _account) external view returns (uint256);
	function initializeClaim(uint256 _tokenId) external;
	function updateClaim(address _account, uint256 _tokenId) external;

	event Claimed(address indexed _account, uint256 _amount);
	event Updated(address indexed _account, uint256 indexed _tokenId);
}