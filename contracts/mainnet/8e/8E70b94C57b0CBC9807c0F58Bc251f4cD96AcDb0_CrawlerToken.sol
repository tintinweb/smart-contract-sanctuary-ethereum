// SPDX-License-Identifier: MIT
//
//    ██████████
//   █          █
//  █            █
//  █            █
//  █            █
//  █    ░░░░    █
//  █   ▓▓▓▓▓▓   █
//  █  ████████  █
//
// https://endlesscrawler.io
// @EndlessCrawler
//
/// @title Endless Crawler Chamber Minter
/// @author Studio Avante
/// @notice Mints new Chambers for Endless Crawler
/// @dev Depends on upgradeable ICrawlerIndex and ICrawlerPlayer
//
pragma solidity ^0.8.16;
import { DefaultOperatorFilterer } from "operator-filter-registry/src/DefaultOperatorFilterer.sol";
import { ERC721, IERC721, IERC165, IERC721Metadata } from '@openzeppelin/contracts/token/ERC721/ERC721.sol';
import { Ownable } from '@openzeppelin/contracts/access/Ownable.sol';
import { ECDSA } from './extras/ECDSA.sol';
import { ERC721Enumerable } from './extras/ERC721Enumerable.sol';
import { ICrawlerIndex } from './ICrawlerIndex.sol';
import { ICrawlerPlayer } from './ICrawlerPlayer.sol';
import { ICrawlerToken } from './ICrawlerToken.sol';
import { Crawl } from './Crawl.sol';

contract CrawlerToken is ERC721, ERC721Enumerable, DefaultOperatorFilterer, Ownable, ICrawlerToken {

	error MintingIsPaused();
	error InvalidFromChamber();
	error InvalidDoor();
	error InvalidSignature();
	error InvalidValue();
	error InvalidTokenId();

	ICrawlerIndex private _index;
  ICrawlerPlayer private _player;
	address private _signerAddress;
	uint256 private _mintedCount;
	uint256 private _priceInPwei;
	uint256 private _priceInWei;
	bool private _paused = true;

	mapping(uint256 => uint256) private _tokenIdToCoord;
	mapping(uint256 => Crawl.ChamberSeed) private _coordToSeed;

	event Paused(bool indexed paused);
	event Minted(address indexed to, uint256 indexed tokenId, uint256 indexed coord);

	constructor(address index_, address player_, address signer_) ERC721('Endless Crawler', 'CRWLR') {
		setIndexContract(index_);
		setPlayerContract(player_);
		setSigner(signer_);
		setPrice(10);

		// Mint origins, Yonder 1, as...
		// 2 Water | 3 Air
		// --------|--------
		// 1 Earth | 4 Fire
		_mint((1 << 64) + 1, 1, Crawl.Terrain.Earth, Crawl.Dir.East);						// same as Crawl.makeCoord(0, 0, 1, 1) or __WS
		_mint((1 << 192) + (1 << 64), 1, Crawl.Terrain.Water, Crawl.Dir.South);	// same as Crawl.makeCoord(1, 0, 1, 0) or N_W_
		_mint((1 << 192) + (1 << 128), 1, Crawl.Terrain.Air, Crawl.Dir.West); 	// same as Crawl.makeCoord(1, 1, 0, 0) or NE__
		_mint((1 << 128) + 1, 1, Crawl.Terrain.Fire, Crawl.Dir.North);					// same as Crawl.makeCoord(0, 1, 0, 1) or _E_S
	}

	/// @dev Required by ERC721 interfaces
	function supportsInterface(bytes4 interfaceId) public view override (IERC165, ERC721, ERC721Enumerable) returns (bool) {
		return ERC721Enumerable.supportsInterface(interfaceId);
	}

	/// @dev Required by ERC721 interfaces
	function _beforeTokenTransfer(address from, address to, uint256 tokenId, uint256 batchSize) internal override (ERC721, ERC721Enumerable) {
		ERC721Enumerable._beforeTokenTransfer(from, to, tokenId, batchSize);
		_player.transferChamberHoard(from, to, tokenIdToHoard(tokenId));
	}

	/// @dev Required by ERC721 interfaces
	function _totalSupply() public view override returns (uint256) {
		return _mintedCount;
	}

	/// @dev Required by OpenSea operator-filter-registry
	function setApprovalForAll(address operator, bool approved) public override(ERC721, IERC721) onlyAllowedOperatorApproval(operator) {
		super.setApprovalForAll(operator, approved);
	}
	/// @dev Required by OpenSea operator-filter-registry
	function approve(address operator, uint256 tokenId) public override(ERC721, IERC721) onlyAllowedOperatorApproval(operator) {
		super.approve(operator, tokenId);
	}
	/// @dev Required by OpenSea operator-filter-registry
	function transferFrom(address from, address to, uint256 tokenId) public override(ERC721, IERC721) onlyAllowedOperator(from) {
		super.transferFrom(from, to, tokenId);
	}
	/// @dev Required by OpenSea operator-filter-registry
	function safeTransferFrom(address from, address to, uint256 tokenId) public override(ERC721, IERC721) onlyAllowedOperator(from) {
		super.safeTransferFrom(from, to, tokenId);
	}
	/// @dev Required by OpenSea operator-filter-registry
	function safeTransferFrom(address from, address to, uint256 tokenId, bytes memory data) public override(ERC721, IERC721) onlyAllowedOperator(from) {
		super.safeTransferFrom(from, to, tokenId, data);
	}

	//---------------
	// Admin
	//

	/// @notice Admin function
	function setIndexContract(address index_) public onlyOwner {
		_index = ICrawlerIndex(index_);
	}

	/// @notice Admin function
	function setPlayerContract(address player_) public onlyOwner {
		_player = ICrawlerPlayer(player_);
	}

	/// @notice Admin function
	function setSigner(address signer_) public onlyOwner {
		_signerAddress = signer_;
	}

	/// @notice Admin function
	function setPrice(uint256 priceInPwei_) public onlyOwner {
		_priceInPwei = priceInPwei_;
		_priceInWei = priceInPwei_ * 1_000_000_000_000_000;
	}

	/// @notice Admin function
	function setPaused(bool paused_) public onlyOwner {
		_paused = paused_;
		emit Paused(_paused);
	}

	/// @notice Admin function
	function checkout(uint256 eth) public onlyOwner {
		payable(msg.sender).transfer(Crawl.min(eth * 1_000_000_000_000_000_000, address(this).balance));
	}

	//---------------
	// Public
	//

	/// @notice Return the current pause status
	/// @return paused True if paused (cannot mint), False if not (can mint)
	function isPaused() public view override returns (bool) {
		return _paused;
	}

	/// @notice Return the current Index contract
	/// @return paused Contract address
	function getIndexContract() public view returns(ICrawlerIndex) {
		return _index;
	}

	/// @notice Return the current Player contract
	/// @return paused Contract address
	function getPlayerContract() public view returns(ICrawlerPlayer) {
		return _player;
	}

	/// @notice Return the current mint prices
	/// @return prices Prices in WEI (for msg.value), and PWEI (stored, 1 pwei = ETH/1000)
	function getPrices() public view override returns (uint256, uint256) {
		return (_priceInWei, _priceInPwei);
	}

	/// @notice Return the current mint prices
	/// Price is FREE for the first token
	/// Price is FREE when minted in-game, provided signature
	/// Otherwise, price is _priceInPwei
	/// @param to Account for which price will be calculated
	/// @return price Token price for account, in WEI
	function calculateMintPrice(address to) public view override returns (uint256) {
		return balanceOf(to) == 0 || to == owner() ? 0 : _priceInWei;
	}

	/// @notice Returns a Chamber coordinate
	/// @param tokenId Token id
	/// @return result Chamber coordinate
	function tokenIdToCoord(uint256 tokenId) public view override returns (uint256) {
		return _tokenIdToCoord[tokenId];
	}

	/// @notice Returns a Chamber static immutable data
	/// @param coord Chamber coordinate
	/// @return result Crawl.ChamberSeed struct
	function coordToSeed(uint256 coord) public view override returns (Crawl.ChamberSeed memory) {
		return _coordToSeed[coord];
	}

	/// @notice Returns a Chamber generated data
	/// @param chapterNumber The Chapter number, or 0 for current chapter
	/// @param coord Chamber coordinate
	/// @param generateMaps True for generating bitmap and tilemap
	/// @return result Crawl.ChamberData struct
	function coordToChamberData(uint8 chapterNumber, uint256 coord, bool generateMaps) public view override returns (Crawl.ChamberData memory result) {
		return _index.getChamberData(chapterNumber, coord, _coordToSeed[coord], generateMaps);
	}

	/// @notice Returns a Chamber Hoard (gems and coins)
	/// @param tokenId Token id
	/// @return result Crawl.Hoard struct
	function tokenIdToHoard(uint256 tokenId) public view override returns (Crawl.Hoard memory) {
		return _index.getChamberGenerator().generateHoard(_coordToSeed[_tokenIdToCoord[tokenId]].seed);
	}

	/// @notice Unlocks a door, minting a new Chamber
	/// @param fromCoord Chamber coordinate, where door is located
	/// @param dir Door direction
	/// @param signature signature from endlesscrawler.io allowing free mint. if absent, calculateMintPrice(msg.sender) must be sent as msg.value
	/// @return tokenId Token id
	function mintDoor(uint256 fromCoord, Crawl.Dir dir, bytes calldata signature) public payable returns (uint256) {
		if(_paused) revert MintingIsPaused();

		Crawl.ChamberSeed storage fromChamber = _coordToSeed[fromCoord];
		if(fromChamber.tokenId == 0) revert InvalidFromChamber();

		// New chamber must be empty
		uint256 newCoord = Crawl.offsetCoord(fromCoord, dir);
		if(_coordToSeed[newCoord].tokenId != 0) revert InvalidDoor();

		if(signature.length != 0) {
			// If has signature, validate it to mint for free
			if(ECDSA.recover(ECDSA.toEthSignedMessageHash(keccak256(abi.encode(msg.sender, newCoord))), signature) != _signerAddress) revert InvalidSignature();
		} else {
			// Validate price
			if(msg.value < calculateMintPrice(msg.sender)) revert InvalidValue();
		}

		// Terrain type will be defined by a super simple cellular automata
		// If chamber opposite to fromCoord is different than it, repeat its Terrain, else randomize
		Crawl.Terrain fromTerrain = fromChamber.terrain;
		Crawl.Dir entryDir = Crawl.flipDir(dir);
		Crawl.Terrain terrain = fromTerrain != _coordToSeed[Crawl.offsetCoord(fromCoord, entryDir)].terrain ? fromTerrain
			: _index.getChamberGenerator().generateTerrainType(fromChamber.seed+uint256(dir), fromTerrain);

		// mint!
		return _mint(
			newCoord,
			fromChamber.yonder + 1,
			terrain,
			entryDir);
	}

	/// @dev Internal mint function
	function _mint(uint256 coord, uint232 yonder, Crawl.Terrain terrain, Crawl.Dir entryDir) internal returns (uint256) {
		uint256 tokenId = _mintedCount + 1;
		uint256 seed = uint256(keccak256(abi.encode(blockhash(block.number-1), tokenId)));
		_tokenIdToCoord[tokenId] = coord;
		_coordToSeed[coord] = Crawl.ChamberSeed(
			tokenId,
			seed,
			yonder,
			_index.getCurrentChapterNumber(),
			terrain,
			entryDir
		);
		_safeMint(msg.sender, tokenId);
		emit Minted(msg.sender, tokenId, coord);
		_mintedCount = tokenId;
		return tokenId;
	}

	/// @notice Returns IERC721Metadata compliant metadata
	/// @param tokenId Token id
	/// @return metadata Metadata, as base64 json string
	function tokenURI(uint256 tokenId) public view override (ERC721, IERC721Metadata) returns (string memory) {
		if(!_exists(tokenId)) revert InvalidTokenId();
		return getTokenMetadata(0, _tokenIdToCoord[tokenId]);
	}

	/// @notice Returns IERC721Metadata compliant metadata, used by tokenURI()
	/// @param chapterNumber The Chapter number, or 0 for current chapter
	/// @param coord Chamber coordinate
	/// @return metadata Metadata, as base64 json string
	function getTokenMetadata(uint8 chapterNumber, uint256 coord) public view returns (string memory) {
		return _index.getTokenMetadata(chapterNumber, coord, _coordToSeed[coord]);
	}

	/// @notice Returns a Chamber metadata, without maps
	/// @param chapterNumber The Chapter number, or 0 for current chapter
	/// @param coord Chamber coordinate
	/// @return metadata Metadata, as plain json string
	function getChamberMetadata(uint8 chapterNumber, uint256 coord) public view returns (string memory) {
		return _index.getChamberMetadata(chapterNumber, coord, _coordToSeed[coord]);
	}

	/// @notice Returns the seed and tilemap of a Chamber, used for world building
	/// @param chapterNumber The Chapter number, or 0 for current chapter
	/// @param coord Chamber coordinate
	/// @return metadata Metadata, as plain json string
	function getMapMetadata(uint8 chapterNumber, uint256 coord) public view returns (string memory) {
		return _index.getMapMetadata(chapterNumber, coord, _coordToSeed[coord]);
	}

}

// SPDX-License-Identifier: MIT
//
//    ██████████
//   █          █
//  █            █
//  █            █
//  █            █
//  █    ░░░░    █
//  █   ▓▓▓▓▓▓   █
//  █  ████████  █
//
// https://endlesscrawler.io
// @EndlessCrawler
//
/// @title Endless Crawler IERC721Enumerable implementation Interface
/// @author Studio Avante
//
pragma solidity ^0.8.0;
import '@openzeppelin/contracts/token/ERC721/IERC721.sol';

interface IERC721Enumerable is IERC721 {
	function totalSupply() external view returns (uint256);
	function tokenOfOwnerByIndex(address owner, uint256 index) external view returns (uint256);
	function tokenByIndex(uint256 index) external view returns (uint256);
}

// SPDX-License-Identifier: MIT
//
//    ██████████
//   █          █
//  █            █
//  █            █
//  █            █
//  █    ░░░░    █
//  █   ▓▓▓▓▓▓   █
//  █  ████████  █
//
// https://endlesscrawler.io
// @EndlessCrawler
//
/// @title Endless Crawler IERC721Enumerable implementation
/// @author OpenZeppelin, adapted by Studio Avante
/// @notice Simplified IERC721Enumerable implementation for gas saving
/// @dev As tokens cannot be burned and are minted in consecutive order, allTokens_ and _allTokensIndex could be removed
/// Based on: OpenZeppelin Contracts (last updated v4.5.0) (token/ERC721/extensions/IERC721Enumerable.sol)
/// https://github.com/OpenZeppelin/openzeppelin-contracts/blob/release-v4.8/contracts/token/ERC721/extensions/IERC721Enumerable.sol
//
pragma solidity ^0.8.16;
import { ERC721, IERC165 } from '@openzeppelin/contracts/token/ERC721/ERC721.sol';
import { IERC721Enumerable } from  './IERC721Enumerable.sol';

abstract contract ERC721Enumerable is ERC721, IERC721Enumerable {
	error OwnerIndexOutOfBounds();
	error GlobalIndexOutOfBounds();

	// Mapping from owner to list of owned token IDs
	mapping(address => mapping(uint256 => uint256)) private _ownedTokens;

	// Mapping from token ID to index of the owner tokens list
	mapping(uint256 => uint256) private _ownedTokensIndex;

	/// @dev Replaces _allTokens and _allTokensIndex, since tokens are sequential and burn proof
	function _totalSupply() public view virtual returns (uint256);

	/// @dev See {IERC165-supportsInterface}.
	function supportsInterface(bytes4 interfaceId) public view virtual override (IERC165, ERC721) returns (bool) {
		return interfaceId == type(IERC721Enumerable).interfaceId || ERC721.supportsInterface(interfaceId);
	}

	/// @dev See {IERC721Enumerable-tokenOfOwnerByIndex}.
	function tokenOfOwnerByIndex(address owner, uint256 index) public view virtual override returns (uint256) {
		if(index >= ERC721.balanceOf(owner)) revert OwnerIndexOutOfBounds();
		return _ownedTokens[owner][index];
	}

	/// @dev See {IERC721Enumerable-totalSupply}.
	function totalSupply() public view virtual override returns (uint256) {
		return _totalSupply();
	}

	/// @dev See {IERC721Enumerable-tokenByIndex}.
	function tokenByIndex(uint256 index) public view virtual override returns (uint256) {
		if(index >= _totalSupply()) revert GlobalIndexOutOfBounds();
		return index + 1;
	}

	/// @dev See {ERC721-_beforeTokenTransfer}.
	function _beforeTokenTransfer(
		address from,
		address to,
		uint256 tokenId,
		uint256 batchSize
	) internal virtual override {
		ERC721._beforeTokenTransfer(from, to, tokenId, batchSize);
		if (to != from) {
			if (from != address(0)) {
				uint256 lastTokenIndex = ERC721.balanceOf(from) - 1;
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
			uint256 length = ERC721.balanceOf(to);
			_ownedTokens[to][length] = tokenId;
			_ownedTokensIndex[tokenId] = length;
		}
	}
}

// SPDX-License-Identifier: MIT
/// @author OpenZeppelin
/// @dev Exact OpenZeppelin copy but public, to be removed from CrawlerToken ABI
// OpenZeppelin Contracts (last updated v4.8.0) (utils/cryptography/ECDSA.sol)
// https://github.com/OpenZeppelin/openzeppelin-contracts/blob/release-v4.8/contracts/utils/cryptography/ECDSA.sol
pragma solidity ^0.8.0;
import "../Crawl.sol";

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
		InvalidSignatureV // Deprecated in v4.8
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
	function tryRecover(bytes32 hash, bytes memory signature) public pure returns (address, RecoverError) {
		if (signature.length == 65) {
			bytes32 r;
			bytes32 s;
			uint8 v;
			// ecrecover takes the signature parameters, and the only way to get them
			// currently is to use assembly.
			/// @solidity memory-safe-assembly
			assembly {
				r := mload(add(signature, 0x20))
				s := mload(add(signature, 0x40))
				v := byte(0, mload(add(signature, 0x60)))
			}
			return tryRecover(hash, v, r, s);
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
	function recover(bytes32 hash, bytes memory signature) public pure returns (address) {
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
	) public pure returns (address, RecoverError) {
		bytes32 s = vs & bytes32(0x7fffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff);
		uint8 v = uint8((uint256(vs) >> 255) + 27);
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
	) public pure returns (address) {
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
	) public pure returns (address, RecoverError) {
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
	) public pure returns (address) {
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
	function toEthSignedMessageHash(bytes32 hash) public pure returns (bytes32) {
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
	function toEthSignedMessageHash(bytes memory s) public pure returns (bytes32) {
		return keccak256(abi.encodePacked("\x19Ethereum Signed Message:\n", Crawl.toString(s.length), s));
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
	function toTypedDataHash(bytes32 domainSeparator, bytes32 structHash) public pure returns (bytes32) {
		return keccak256(abi.encodePacked("\x19\x01", domainSeparator, structHash));
	}
}

// SPDX-License-Identifier: MIT
//
//    ██████████
//   █          █
//  █            █
//  █            █
//  █            █
//  █    ░░░░    █
//  █   ▓▓▓▓▓▓   █
//  █  ████████  █
//
// https://endlesscrawler.io
// @EndlessCrawler
//
/// @title Endless Crawler Chamber Minter Interface
/// @author Studio Avante
//
pragma solidity ^0.8.16;
import { IERC165 } from '@openzeppelin/contracts/utils/introspection/IERC165.sol';
import { IERC721 } from '@openzeppelin/contracts/token/ERC721/IERC721.sol';
import { IERC721Metadata } from '@openzeppelin/contracts/token/ERC721/extensions/IERC721Metadata.sol';
import { IERC721Enumerable } from './extras/IERC721Enumerable.sol';
import { Crawl } from './Crawl.sol';

interface ICrawlerToken is IERC165, IERC721, IERC721Metadata, IERC721Enumerable {
	function isPaused() external view returns (bool);
	function getPrices() external view returns (uint256, uint256);
	function calculateMintPrice(address to) external view returns (uint256);
	function tokenIdToCoord(uint256 tokenId) external view returns (uint256);
	function coordToSeed(uint256 coord) external view returns (Crawl.ChamberSeed memory);
	function coordToChamberData(uint8 chapterNumber, uint256 coord, bool generateMaps) external view returns (Crawl.ChamberData memory);
	function tokenIdToHoard(uint256 tokenId) external view returns (Crawl.Hoard memory);
	// Metadata calls
	function getChamberMetadata(uint8 chapterNumber, uint256 coord) external view returns (string memory);
	function getMapMetadata(uint8 chapterNumber, uint256 coord) external view returns (string memory);
	function getTokenMetadata(uint8 chapterNumber, uint256 coord) external view returns (string memory);
}

// SPDX-License-Identifier: MIT
//
//    ██████████
//   █          █
//  █            █
//  █            █
//  █            █
//  █    ░░░░    █
//  █   ▓▓▓▓▓▓   █
//  █  ████████  █
//
// https://endlesscrawler.io
// @EndlessCrawler
//
/// @title Endless Crawler Chamber Renderer Interface
/// @author Studio Avante
//
pragma solidity ^0.8.16;
import { IERC165 } from '@openzeppelin/contracts/utils/introspection/IERC165.sol';
import { ICrawlerMapper } from './ICrawlerMapper.sol';
import { Crawl } from './Crawl.sol';

interface ICrawlerRenderer is IERC165 {
	function renderAdditionalChamberMetadata(Crawl.ChamberData memory chamber, ICrawlerMapper mapper) external view returns (string memory);
	function renderMapMetadata(Crawl.ChamberData memory chamber, ICrawlerMapper mapper) external view returns (string memory);
	function renderTokenMetadata(Crawl.ChamberData memory chamber, ICrawlerMapper mapper) external view returns (string memory);
}

// SPDX-License-Identifier: MIT
//
//    ██████████
//   █          █
//  █            █
//  █            █
//  █            █
//  █    ░░░░    █
//  █   ▓▓▓▓▓▓   █
//  █  ████████  █
//
// https://endlesscrawler.io
// @EndlessCrawler
//
/// @title Endless Crawler Player Manager Interface
/// @author Studio Avante
//
pragma solidity ^0.8.16;
import { Crawl } from './Crawl.sol';

interface ICrawlerPlayer {
	function transferChamberHoard(address from, address to, Crawl.Hoard memory hoard) external;
}

// SPDX-License-Identifier: MIT
//
//    ██████████
//   █          █
//  █            █
//  █            █
//  █            █
//  █    ░░░░    █
//  █   ▓▓▓▓▓▓   █
//  █  ████████  █
//
// https://endlesscrawler.io
// @EndlessCrawler
//
/// @title Endless Crawler Chamber Mapper Interface
/// @author Studio Avante
//
pragma solidity ^0.8.16;
import { IERC165 } from '@openzeppelin/contracts/utils/introspection/IERC165.sol';
import { Crawl } from './Crawl.sol';

interface ICrawlerMapper is IERC165 {
	// for generators
	function generateTileMap(Crawl.ChamberData memory chamber) external view returns (bytes memory);
	// getters / for renderers
	function getTerrainName(Crawl.Terrain terrain) external view returns (string memory);
	function getGemName(Crawl.Gem gem) external view returns (string memory);
	function getTileName(bytes1 tile, uint8 bitPos) external view returns (string memory);
	function getColors(Crawl.Terrain terrain) external view returns (string[] memory);
	function getColor(Crawl.Terrain terrain, uint8 colorId) external view returns (string memory);
	function getGemColors() external view returns (string[] memory);
	function getGemColor(Crawl.Gem gemType) external view returns (string memory);
	// for renderers
	function getAttributes(Crawl.ChamberData memory chamber) external view returns (string[] memory, string[] memory);
	function renderSvgStyles(Crawl.ChamberData memory chamber) external view returns (string memory);
	function renderSvgDefs(Crawl.ChamberData memory chamber) external view returns (string memory);
}

// SPDX-License-Identifier: MIT
//
//    ██████████
//   █          █
//  █            █
//  █            █
//  █            █
//  █    ░░░░    █
//  █   ▓▓▓▓▓▓   █
//  █  ████████  █
//
// https://endlesscrawler.io
// @EndlessCrawler
//
/// @title Endless Crawler Chapter Index Interface
/// @author Studio Avante
//
pragma solidity ^0.8.16;
import { ICrawlerChamberGenerator } from './ICrawlerChamberGenerator.sol';
import { ICrawlerGenerator } from './ICrawlerGenerator.sol';
import { ICrawlerMapper } from './ICrawlerMapper.sol';
import { ICrawlerRenderer } from './ICrawlerRenderer.sol';
import { Crawl } from './Crawl.sol';

interface ICrawlerIndex {
	struct Chapter {
		uint8 chapterNumber;
		ICrawlerGenerator generator;
		ICrawlerMapper mapper;
		ICrawlerRenderer renderer;
	}
	// Public
	function getCurrentChapterNumber() external view returns (uint8);
	function getCurrentChapter() external view returns (Chapter memory);
	function getChapter(uint8 chapterNumber) external view returns (Chapter memory);
	function getChamberGenerator() external view returns (ICrawlerChamberGenerator);
	function getGenerator(uint8 chapterNumber) external view returns (ICrawlerGenerator);
	function getMapper(uint8 chapterNumber) external view returns (ICrawlerMapper);
	function getRenderer(uint8 chapterNumber) external view returns (ICrawlerRenderer);
	// Metadata calls
	function getChamberData(uint8 chapterNumber, uint256 coord, Crawl.ChamberSeed memory chamberSeed, bool generateMaps) external view returns (Crawl.ChamberData memory);
	function getChamberMetadata(uint8 chapterNumber, uint256 coord, Crawl.ChamberSeed memory chamberSeed) external view returns (string memory);
	function getMapMetadata(uint8 chapterNumber, uint256 coord, Crawl.ChamberSeed memory chamberSeed) external view returns (string memory);
	function getTokenMetadata(uint8 chapterNumber, uint256 coord, Crawl.ChamberSeed memory chamberSeed) external view returns (string memory);
}

// SPDX-License-Identifier: MIT
//
//    ██████████
//   █          █
//  █            █
//  █            █
//  █            █
//  █    ░░░░    █
//  █   ▓▓▓▓▓▓   █
//  █  ████████  █
//
// https://endlesscrawler.io
// @EndlessCrawler
//
/// @title Endless Crawler Chamber Generator Interface (Custom data)
/// @author Studio Avante
//
pragma solidity ^0.8.16;
import { IERC165 } from '@openzeppelin/contracts/utils/introspection/IERC165.sol';
import { Crawl } from './Crawl.sol';

interface ICrawlerGenerator is IERC165 {
	function generateCustomChamberData(Crawl.ChamberData memory chamber) external view returns (Crawl.CustomData[] memory);
}

// SPDX-License-Identifier: MIT
//
//    ██████████
//   █          █
//  █            █
//  █            █
//  █            █
//  █    ░░░░    █
//  █   ▓▓▓▓▓▓   █
//  █  ████████  █
//
// https://endlesscrawler.io
// @EndlessCrawler
//
/// @title Endless Crawler Static Chamber Generator Interface (static data)
/// @author Studio Avante
//
pragma solidity ^0.8.16;
import { ICrawlerGenerator } from './ICrawlerGenerator.sol';
import { ICrawlerToken } from './ICrawlerToken.sol';
import { Crawl } from './Crawl.sol';

interface ICrawlerChamberGenerator {
	function generateTerrainType(uint256 seed, Crawl.Terrain fromTerrain) external view returns (Crawl.Terrain);
	function generateHoard(uint256 seed) external view returns (Crawl.Hoard memory);
	function generateChamberData(uint256 coord, Crawl.ChamberSeed memory chamberSeed, bool generateMaps, ICrawlerToken tokenContract, ICrawlerGenerator customGenerator) external view returns (Crawl.ChamberData memory);
}

// SPDX-License-Identifier: MIT
//
//    ██████████
//   █          █
//  █            █
//  █            █
//  █            █
//  █    ░░░░    █
//  █   ▓▓▓▓▓▓   █
//  █  ████████  █
//
// https://endlesscrawler.io
// @EndlessCrawler
//
/// @title Endless Crawler Game Definitions and Library
/// @author Studio Avante
/// @notice Contains common definitions and functions
//
pragma solidity ^0.8.16;

library Crawl {

  //-----------------------------------
  // ChamberSeed, per token static data
  // generated on mint, stored on-chain
  //
	struct ChamberSeed {
		uint256 tokenId;
		uint256 seed;
		uint232 yonder;
		uint8 chapter;
		Crawl.Terrain terrain;
		Crawl.Dir entryDir;
	}


  //------------------------------------
  // ChamberData, per token dynamic data
  // generated on demand
  //
	struct ChamberData {
		// from ChamberSeed (static)
		uint256 coord;
		uint256 tokenId;
		uint256 seed;
		uint232 yonder;
		uint8 chapter;			// Chapter minted
		Crawl.Terrain terrain;
		Crawl.Dir entryDir;

		// generated on demand (deterministic)
		Crawl.Hoard hoard;
		uint8 gemPos;				// gem bitmap position

		// dynamic until all doors are unlocked
		uint8[4] doors; 		// bitmap position in NEWS order
		uint8[4] locks; 		// lock status in NEWS order

		// optional
		uint256 bitmap;			// bit map, 0 is void/walls, 1 is path
		bytes tilemap;			// tile map

		// custom data
		CustomData[] customData;
	}

	struct Hoard {
		Crawl.Gem gemType;
		uint16 coins;		// coins value
		uint16 worth;		// gem + coins value
	}

	enum CustomDataType {
		Custom0, Custom1, Custom2, Custom3, Custom4,
		Custom5, Custom6, Custom7, Custom8, Custom9,
		Tile,
		Palette,
		Background,
		Foreground,
		CharSet,
		Music
	}

	struct CustomData {
		CustomDataType dataType;
		bytes data;
	}


	//-----------------------
	// Terrain types
	//
	// 2 Water | 3 Air
	// --------|--------
	// 1 Earth | 4 Fire
	//
	enum Terrain {
		Empty,	// 0
		Earth,	// 1
		Water,	// 2
		Air,		// 3
		Fire		// 4
	}

	/// @dev Returns the opposite of a Terrain
	// Opposite terrains cannot access to each other
	// Earth <> Air
	// Water <> Fire
	function getOppositeTerrain(Crawl.Terrain terrain) internal pure returns (Crawl.Terrain) {
		uint256 t = uint256(terrain);
		return t >= 3 ? Crawl.Terrain(t-2) : t >= 1 ? Crawl.Terrain(t+2) : Crawl.Terrain.Empty;
	}

	//-----------------------
	// Gem types
	//
	enum Gem {
		Silver,			// 0
		Gold,				// 1
		Sapphire,		// 2
		Emerald,		// 3
		Ruby,				// 4
		Diamond,		// 5
		Ethernite,	// 6
		Kao,				// 7
		Coin				// 8 (not a gem!)
	}

	/// @dev Returns the Worth value of a Gem
	function getGemValue(Crawl.Gem gem) internal pure returns (uint16) {
		if (gem == Crawl.Gem.Silver) return 50;
		if (gem == Crawl.Gem.Gold) return 100;
		if (gem == Crawl.Gem.Sapphire) return 150;
		if (gem == Crawl.Gem.Emerald) return 200;
		if (gem == Crawl.Gem.Ruby) return 300;
		if (gem == Crawl.Gem.Diamond) return 500;
		if (gem == Crawl.Gem.Ethernite) return 800;
		return 1001; // Crawl.Gem.Kao
	}

	/// @dev Calculates a Chamber Worth value
	function calcWorth(Crawl.Gem gem, uint16 coins) internal pure returns (uint16) {
		return getGemValue(gem) + coins;
	}

	//--------------------------
	// Directions, in NEWS order
	//
	enum Dir {
		North,	// 0
		East,		// 1
		West,		// 2
		South		// 3
	}
	uint256 internal constant mask_South = uint256(type(uint64).max);
	uint256 internal constant mask_West = (mask_South << 64);
	uint256 internal constant mask_East = (mask_South << 128);
	uint256 internal constant mask_North = (mask_South << 192);

	/// @dev Flips a direction
	/// North <> South
	/// East <> West
	function flipDir(Crawl.Dir dir) internal pure returns (Crawl.Dir) {
		return Crawl.Dir(3 - uint256(dir));
	}

	/// @dev Flips a door possition at a direction to connect to neighboring chamber
	function flipDoorPosition(uint8 doorPos, Crawl.Dir dir) internal pure returns (uint8 result) {
		if (dir == Crawl.Dir.North) return doorPos > 0 ? doorPos + (15 * 16) : 0;
		if (dir == Crawl.Dir.South) return doorPos > 0 ? doorPos - (15 * 16) : 0;
		if (dir == Crawl.Dir.West) return doorPos > 0 ? doorPos + 15 : 0;
		return doorPos > 0 ? doorPos - 15 : 0; // Crawl.Dir.East
	}

	//-----------------------
	// Coords
	//	
	// coords have 4 components packed in uint256
	// in NEWS direction:
	// (N)orth, (E)ast, (W)est, (S)outh
	// o-------o-------o-------o-------o
	// 0       32     128     192    256

	/// @dev Extracts the North component from a Chamber coordinate
	function getNorth(uint256 coord) internal pure returns (uint256 result) {
		return (coord >> 192);
	}
	/// @dev Extracts the East component from a Chamber coordinate
	function getEast(uint256 coord) internal pure returns (uint256) {
		return ((coord & mask_East) >> 128);
	}
	/// @dev Extracts the West component from a Chamber coordinate
	function getWest(uint256 coord) internal pure returns (uint256) {
		return ((coord & mask_West) >> 64);
	}
	/// @dev Extracts the South component from a Chamber coordinate
	function getSouth(uint256 coord) internal pure returns (uint256) {
		return coord & mask_South;
	}

	/// @dev Builds a Chamber coordinate from its direction components
	/// a coord is composed of 4 uint64 components packed in a uint256
	/// Components are combined in NEWS order: Nort, East, West, South
	/// @param north North component, zero if South
	/// @param east East component, zero id West
	/// @param west West component, zero if East
	/// @param south South component, zero if North
	/// @return result Chamber coordinate
	function makeCoord(uint256 north, uint256 east, uint256 west, uint256 south) internal pure returns (uint256 result) {
		// North or South need to be positive, but not both
		if(north > 0) {
			require(south == 0, 'Crawl.makeCoord(): bad North/South');
			result += (north << 192);
		} else if(south > 0) {
			result += south;
		} else {
			revert('Crawl.makeCoord(): need North or South');
		}
		// West or East need to be positive, but not both
		if(east > 0) {
			require(west == 0, 'Crawl.makeCoord(): bad West/East');
			result += (east << 128);
		} else if(west > 0) {
			result += (west << 64);
		} else {
			revert('Crawl.makeCoord(): need West or East');
		}
	}

	/// @dev Offsets a Chamber coordinate in one direction
	/// @param coord Chamber coordinate
	/// @param dir Direction to offset
	/// @return coord The new coordinate. If reached limits, return same coord
	// TODO: Use assembly?
	function offsetCoord(uint256 coord, Crawl.Dir dir) internal pure returns (uint256) {
		if(dir == Crawl.Dir.North) {
			if(coord & mask_South > 1) return coord - 1; // --South
			if(coord & mask_North != mask_North) return (coord & ~mask_South) + (1 << 192); // ++North
		} else if(dir == Crawl.Dir.East) {
			if(coord & mask_West > (1 << 64)) return coord - (1 << 64); // --West
			if(coord & mask_East != mask_East) return (coord & ~mask_West) + (1 << 128); // ++East
		} else if(dir == Crawl.Dir.West) {
			if(coord & mask_East > (1 << 128)) return coord - (1 << 128); // --East
			if(coord & mask_West != mask_West) return (coord & ~mask_East) + (1 << 64); // ++West
		} else { //if(dir == Crawl.Dir.South) {
			if(coord & mask_North > (1 << 192)) return coord - (1 << 192); // --North
			if(coord & mask_South != mask_South) return (coord & ~mask_North) + 1; // ++South
		}
		return coord;
	}


	//-----------------------
	// String Builders
	//

	/// @dev Returns a token description for tokenURI()
	function tokenName(string memory tokenId) public pure returns (string memory) {
		return string.concat('Chamber #', tokenId);
	}

	/// @dev Short string representation of a Chamebr coordinate and Yonder
	function coordsToString(uint256 coord, uint256 yonder, string memory separator) public pure returns (string memory) {
		return string.concat(
			((coord & Crawl.mask_North) > 0
				? string.concat('N', toString((coord & Crawl.mask_North)>>192))
				: string.concat('S', toString(coord & Crawl.mask_South))),
			((coord & Crawl.mask_East) > 0
				? string.concat(separator, 'E', toString((coord & Crawl.mask_East)>>128))
				: string.concat(separator, 'W', toString((coord & Crawl.mask_West)>>64))),
			(yonder > 0 ? string.concat(separator, 'Y', toString(yonder)) : '')
		);
	}

	/// @dev Renders IERC721Metadata attributes for tokenURI()
	/// Reference: https://docs.opensea.io/docs/metadata-standards
	function renderAttributesMetadata(string[] memory labels, string[] memory values) public pure returns (string memory result) {
		for(uint256 i = 0 ; i < labels.length ; ++i) {
			result = string.concat(result,
				'{'
					'"trait_type":"', labels[i], '",'
					'"value":"', values[i], '"'
				'}',
				(i < (labels.length - 1) ? ',' : '')
			);
		}
	}

	/// @dev Returns a Chamber metadata, without maps
	/// @param chamber The Chamber, no maps required
	/// @return metadata Metadata, as plain json string
	function renderChamberMetadata(Crawl.ChamberData memory chamber, string memory additionalMetadata) internal pure returns (string memory) {
		return string.concat(
			'{'
				'"tokenId":"', toString(chamber.tokenId), '",'
				'"name":"', tokenName(toString(chamber.tokenId)), '",'
				'"chapter":"', toString(chamber.chapter), '",'
				'"terrain":"', toString(uint256(chamber.terrain)), '",'
				'"gem":"', toString(uint256(chamber.hoard.gemType)), '",'
				'"coins":"', toString(chamber.hoard.coins), '",'
				'"worth":"', toString(chamber.hoard.worth), '",'
				'"coord":"', toString(chamber.coord), '",'
				'"yonder":"', toString(chamber.yonder), '",',
				_renderCompassMetadata(chamber.coord),
				_renderLocksMetadata(chamber.locks),
				additionalMetadata,
			'}'
		);
	}
	function _renderCompassMetadata(uint256 coord) private pure returns (string memory) {
		return string.concat(
			'"compass":{',
				((coord & Crawl.mask_North) > 0
					? string.concat('"north":"', toString((coord & Crawl.mask_North)>>192))
					: string.concat('"south":"', toString(coord & Crawl.mask_South))),
				((coord & Crawl.mask_East) > 0
					? string.concat('","east":"', toString((coord & Crawl.mask_East)>>128))
					: string.concat('","west":"', toString((coord & Crawl.mask_West)>>64))),
			'"},'
		);
	}
	function _renderLocksMetadata(uint8[4] memory locks) private pure returns (string memory) {
		return string.concat(
			'"locks":[',
				(locks[0] == 0 ? 'false,' : 'true,'),
				(locks[1] == 0 ? 'false,' : 'true,'),
				(locks[2] == 0 ? 'false,' : 'true,'),
				(locks[3] == 0 ? 'false' : 'true'),
			'],'
		);
	}


	//-----------------------
	// Utils
	//

	/// @dev converts uint8 tile position to a bitmap position mask
	function tilePosToBitmap(uint8 tilePos) internal pure returns (uint256) {
		return (1 << (255 - tilePos));
	}

	/// @dev overSeed has ~50% more bits
	function overSeed(uint256 seed_) internal pure returns (uint256) {
		return seed_ | uint256(keccak256(abi.encodePacked(seed_)));
	}

	/// @dev underSeed has ~50% less bits
	function underSeed(uint256 seed_) internal pure returns (uint256) {
		return seed_ & uint256(keccak256(abi.encodePacked(seed_)));
	}

	/// @dev maps seed value modulus to range
	function mapSeed(uint256 seed_, uint256 min_, uint256 maxExcl_) internal pure returns (uint256) {
		return min_ + (seed_ % (maxExcl_ - min_));
	}

	/// @dev maps seed value modulus to bitmap position (takes 8 bits)
	/// the position lands in a 12x12 space at the center of the 16x16 map
	function mapSeedToBitmapPosition(uint256 seed_) internal pure returns (uint8) {
		uint8 i = uint8(seed_ % 144);
		return ((i / 12) + 2) * 16 + (i % 12) + 2;
	}

	/// @dev min function
	function min(uint256 a, uint256 b) internal pure returns (uint256) {
		return a < b ? a : b;
	}

	/// @dev max function
	function max(uint256 a, uint256 b) internal pure returns (uint256) {
		return a > b ? a : b;
	}

	//-----------------------------
	// OpenZeppelin Strings library
	// https://github.com/OpenZeppelin/openzeppelin-contracts/blob/release-v4.8/contracts/utils/Strings.sol
	// https://github.com/OpenZeppelin/openzeppelin-contracts/blob/release-v4.8/contracts/utils/math/Math.sol
	//
	bytes16 private constant _SYMBOLS = "0123456789abcdef";
	uint8 private constant _ADDRESS_LENGTH = 20;

	/// @dev Return the log in base 10, rounded down, of a positive value.
	function log10(uint256 value) private pure returns (uint256) {
		uint256 result = 0;
		unchecked {
			if (value >= 10**64) { value /= 10**64; result += 64; }
			if (value >= 10**32) { value /= 10**32; result += 32; }
			if (value >= 10**16) { value /= 10**16; result += 16; }
			if (value >= 10**8) { value /= 10**8; result += 8; }
			if (value >= 10**4) { value /= 10**4; result += 4; }
			if (value >= 10**2) { value /= 10**2; result += 2; }
			if (value >= 10**1) { result += 1; }
		}
		return result;
	}

	/// @dev Return the log in base 256, rounded down, of a positive value.
	function log256(uint256 value) private pure returns (uint256) {
		uint256 result = 0;
		unchecked {
			if (value >> 128 > 0) { value >>= 128; result += 16; }
			if (value >> 64 > 0) { value >>= 64; result += 8; }
			if (value >> 32 > 0) { value >>= 32; result += 4; }
			if (value >> 16 > 0) { value >>= 16; result += 2; }
			if (value >> 8 > 0) { result += 1; }
		}
		return result;
	}

	/// @dev Converts a `uint256` to its ASCII `string` decimal representation.
	function toString(uint256 value) internal pure returns (string memory) {
		unchecked {
			uint256 length = log10(value) + 1;
			string memory buffer = new string(length);
			uint256 ptr;
			/// @solidity memory-safe-assembly
			assembly {
				ptr := add(buffer, add(32, length))
			}
			while (true) {
				ptr--;
				/// @solidity memory-safe-assembly
				assembly {
					mstore8(ptr, byte(mod(value, 10), _SYMBOLS))
				}
				value /= 10;
				if (value == 0) break;
			}
			return buffer;
		}
	}

	/// @dev Converts a `uint256` to its ASCII `string` hexadecimal representation.
	/// defined as public to be excluded from the contract ABI and avoid Stack Too Deep error
	function toHexString(uint256 value) public pure returns (string memory) {
		unchecked {
			return toHexString(value, log256(value) + 1);
		}
	}

	/// @dev Converts a `uint256` to its ASCII `string` hexadecimal representation with fixed length.
	/// defined as public to be excluded from the contract ABI and avoid Stack Too Deep error
	function toHexString(uint256 value, uint256 length) public pure returns (string memory) {
		bytes memory buffer = new bytes(2 * length + 2);
		buffer[0] = "0";
		buffer[1] = "x";
		for (uint256 i = 2 * length + 1; i > 1; --i) {
			buffer[i] = _SYMBOLS[value & 0xf];
			value >>= 4;
		}
		require(value == 0, "Strings: hex length insufficient");
		return string(buffer);
	}

	/// @dev Converts an `address` with fixed length of 20 bytes to its not checksummed ASCII `string` hexadecimal representation.
	function toHexString(address addr) public pure returns (string memory) {
		return toHexString(uint256(uint160(addr)), _ADDRESS_LENGTH);
	}

	/// @dev Converts a single `bytes1` to its ASCII `string` hexadecimal
	function toHexString(bytes1 value) public pure returns (string memory) {
		bytes memory buffer = new bytes(2);
		buffer[0] = _SYMBOLS[uint8(value>>4) & 0xf];
		buffer[1] = _SYMBOLS[uint8(value) & 0xf];
		return string(buffer);
	}

	/// @dev Converts a `bytes` to its ASCII `string` hexadecimal, without '0x' prefix
	function toHexString(bytes memory value, uint256 start, uint256 length) public pure returns (string memory) {
		require(start < value.length, "Strings: hex start overflow");
		require(start + length <= value.length, "Strings: hex length overflow");
		bytes memory buffer = new bytes(2 * length);
		for (uint256 i = 0; i < length; i++) {
			buffer[i*2+0] = _SYMBOLS[uint8(value[start+i]>>4) & 0xf];
			buffer[i*2+1] = _SYMBOLS[uint8(value[start+i]) & 0xf];
		}
		return string(buffer);
	}
	/// @dev Converts a `bytes` to its ASCII `string` hexadecimal, without '0x' prefix
	function toHexString(bytes memory value) public pure returns (string memory) {
		return toHexString(value, 0, value.length);
	}

}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

import {IOperatorFilterRegistry} from "./IOperatorFilterRegistry.sol";

/**
 * @title  OperatorFilterer
 * @notice Abstract contract whose constructor automatically registers and optionally subscribes to or copies another
 *         registrant's entries in the OperatorFilterRegistry.
 * @dev    This smart contract is meant to be inherited by token contracts so they can use the following:
 *         - `onlyAllowedOperator` modifier for `transferFrom` and `safeTransferFrom` methods.
 *         - `onlyAllowedOperatorApproval` modifier for `approve` and `setApprovalForAll` methods.
 */
abstract contract OperatorFilterer {
    error OperatorNotAllowed(address operator);

    IOperatorFilterRegistry public constant OPERATOR_FILTER_REGISTRY =
        IOperatorFilterRegistry(0x000000000000AAeB6D7670E522A718067333cd4E);

    constructor(address subscriptionOrRegistrantToCopy, bool subscribe) {
        // If an inheriting token contract is deployed to a network without the registry deployed, the modifier
        // will not revert, but the contract will need to be registered with the registry once it is deployed in
        // order for the modifier to filter addresses.
        if (address(OPERATOR_FILTER_REGISTRY).code.length > 0) {
            if (subscribe) {
                OPERATOR_FILTER_REGISTRY.registerAndSubscribe(address(this), subscriptionOrRegistrantToCopy);
            } else {
                if (subscriptionOrRegistrantToCopy != address(0)) {
                    OPERATOR_FILTER_REGISTRY.registerAndCopyEntries(address(this), subscriptionOrRegistrantToCopy);
                } else {
                    OPERATOR_FILTER_REGISTRY.register(address(this));
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

    function _checkFilterOperator(address operator) internal view virtual {
        // Check registry code length to facilitate testing in environments without a deployed registry.
        if (address(OPERATOR_FILTER_REGISTRY).code.length > 0) {
            if (!OPERATOR_FILTER_REGISTRY.isOperatorAllowed(address(this), operator)) {
                revert OperatorNotAllowed(operator);
            }
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

import {OperatorFilterer} from "./OperatorFilterer.sol";

/**
 * @title  DefaultOperatorFilterer
 * @notice Inherits from OperatorFilterer and automatically subscribes to the default OpenSea subscription.
 */
abstract contract DefaultOperatorFilterer is OperatorFilterer {
    address constant DEFAULT_SUBSCRIPTION = address(0x3cc6CddA760b79bAfa08dF41ECFA224f810dCeB6);

    constructor() OperatorFilterer(DEFAULT_SUBSCRIPTION, true) {}
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.8.0) (utils/math/Math.sol)

pragma solidity ^0.8.0;

/**
 * @dev Standard math utilities missing in the Solidity language.
 */
library Math {
    enum Rounding {
        Down, // Toward negative infinity
        Up, // Toward infinity
        Zero // Toward zero
    }

    /**
     * @dev Returns the largest of two numbers.
     */
    function max(uint256 a, uint256 b) internal pure returns (uint256) {
        return a > b ? a : b;
    }

    /**
     * @dev Returns the smallest of two numbers.
     */
    function min(uint256 a, uint256 b) internal pure returns (uint256) {
        return a < b ? a : b;
    }

    /**
     * @dev Returns the average of two numbers. The result is rounded towards
     * zero.
     */
    function average(uint256 a, uint256 b) internal pure returns (uint256) {
        // (a + b) / 2 can overflow.
        return (a & b) + (a ^ b) / 2;
    }

    /**
     * @dev Returns the ceiling of the division of two numbers.
     *
     * This differs from standard division with `/` in that it rounds up instead
     * of rounding down.
     */
    function ceilDiv(uint256 a, uint256 b) internal pure returns (uint256) {
        // (a + b - 1) / b can overflow on addition, so we distribute.
        return a == 0 ? 0 : (a - 1) / b + 1;
    }

    /**
     * @notice Calculates floor(x * y / denominator) with full precision. Throws if result overflows a uint256 or denominator == 0
     * @dev Original credit to Remco Bloemen under MIT license (https://xn--2-umb.com/21/muldiv)
     * with further edits by Uniswap Labs also under MIT license.
     */
    function mulDiv(
        uint256 x,
        uint256 y,
        uint256 denominator
    ) internal pure returns (uint256 result) {
        unchecked {
            // 512-bit multiply [prod1 prod0] = x * y. Compute the product mod 2^256 and mod 2^256 - 1, then use
            // use the Chinese Remainder Theorem to reconstruct the 512 bit result. The result is stored in two 256
            // variables such that product = prod1 * 2^256 + prod0.
            uint256 prod0; // Least significant 256 bits of the product
            uint256 prod1; // Most significant 256 bits of the product
            assembly {
                let mm := mulmod(x, y, not(0))
                prod0 := mul(x, y)
                prod1 := sub(sub(mm, prod0), lt(mm, prod0))
            }

            // Handle non-overflow cases, 256 by 256 division.
            if (prod1 == 0) {
                return prod0 / denominator;
            }

            // Make sure the result is less than 2^256. Also prevents denominator == 0.
            require(denominator > prod1);

            ///////////////////////////////////////////////
            // 512 by 256 division.
            ///////////////////////////////////////////////

            // Make division exact by subtracting the remainder from [prod1 prod0].
            uint256 remainder;
            assembly {
                // Compute remainder using mulmod.
                remainder := mulmod(x, y, denominator)

                // Subtract 256 bit number from 512 bit number.
                prod1 := sub(prod1, gt(remainder, prod0))
                prod0 := sub(prod0, remainder)
            }

            // Factor powers of two out of denominator and compute largest power of two divisor of denominator. Always >= 1.
            // See https://cs.stackexchange.com/q/138556/92363.

            // Does not overflow because the denominator cannot be zero at this stage in the function.
            uint256 twos = denominator & (~denominator + 1);
            assembly {
                // Divide denominator by twos.
                denominator := div(denominator, twos)

                // Divide [prod1 prod0] by twos.
                prod0 := div(prod0, twos)

                // Flip twos such that it is 2^256 / twos. If twos is zero, then it becomes one.
                twos := add(div(sub(0, twos), twos), 1)
            }

            // Shift in bits from prod1 into prod0.
            prod0 |= prod1 * twos;

            // Invert denominator mod 2^256. Now that denominator is an odd number, it has an inverse modulo 2^256 such
            // that denominator * inv = 1 mod 2^256. Compute the inverse by starting with a seed that is correct for
            // four bits. That is, denominator * inv = 1 mod 2^4.
            uint256 inverse = (3 * denominator) ^ 2;

            // Use the Newton-Raphson iteration to improve the precision. Thanks to Hensel's lifting lemma, this also works
            // in modular arithmetic, doubling the correct bits in each step.
            inverse *= 2 - denominator * inverse; // inverse mod 2^8
            inverse *= 2 - denominator * inverse; // inverse mod 2^16
            inverse *= 2 - denominator * inverse; // inverse mod 2^32
            inverse *= 2 - denominator * inverse; // inverse mod 2^64
            inverse *= 2 - denominator * inverse; // inverse mod 2^128
            inverse *= 2 - denominator * inverse; // inverse mod 2^256

            // Because the division is now exact we can divide by multiplying with the modular inverse of denominator.
            // This will give us the correct result modulo 2^256. Since the preconditions guarantee that the outcome is
            // less than 2^256, this is the final result. We don't need to compute the high bits of the result and prod1
            // is no longer required.
            result = prod0 * inverse;
            return result;
        }
    }

    /**
     * @notice Calculates x * y / denominator with full precision, following the selected rounding direction.
     */
    function mulDiv(
        uint256 x,
        uint256 y,
        uint256 denominator,
        Rounding rounding
    ) internal pure returns (uint256) {
        uint256 result = mulDiv(x, y, denominator);
        if (rounding == Rounding.Up && mulmod(x, y, denominator) > 0) {
            result += 1;
        }
        return result;
    }

    /**
     * @dev Returns the square root of a number. If the number is not a perfect square, the value is rounded down.
     *
     * Inspired by Henry S. Warren, Jr.'s "Hacker's Delight" (Chapter 11).
     */
    function sqrt(uint256 a) internal pure returns (uint256) {
        if (a == 0) {
            return 0;
        }

        // For our first guess, we get the biggest power of 2 which is smaller than the square root of the target.
        //
        // We know that the "msb" (most significant bit) of our target number `a` is a power of 2 such that we have
        // `msb(a) <= a < 2*msb(a)`. This value can be written `msb(a)=2**k` with `k=log2(a)`.
        //
        // This can be rewritten `2**log2(a) <= a < 2**(log2(a) + 1)`
        // → `sqrt(2**k) <= sqrt(a) < sqrt(2**(k+1))`
        // → `2**(k/2) <= sqrt(a) < 2**((k+1)/2) <= 2**(k/2 + 1)`
        //
        // Consequently, `2**(log2(a) / 2)` is a good first approximation of `sqrt(a)` with at least 1 correct bit.
        uint256 result = 1 << (log2(a) >> 1);

        // At this point `result` is an estimation with one bit of precision. We know the true value is a uint128,
        // since it is the square root of a uint256. Newton's method converges quadratically (precision doubles at
        // every iteration). We thus need at most 7 iteration to turn our partial result with one bit of precision
        // into the expected uint128 result.
        unchecked {
            result = (result + a / result) >> 1;
            result = (result + a / result) >> 1;
            result = (result + a / result) >> 1;
            result = (result + a / result) >> 1;
            result = (result + a / result) >> 1;
            result = (result + a / result) >> 1;
            result = (result + a / result) >> 1;
            return min(result, a / result);
        }
    }

    /**
     * @notice Calculates sqrt(a), following the selected rounding direction.
     */
    function sqrt(uint256 a, Rounding rounding) internal pure returns (uint256) {
        unchecked {
            uint256 result = sqrt(a);
            return result + (rounding == Rounding.Up && result * result < a ? 1 : 0);
        }
    }

    /**
     * @dev Return the log in base 2, rounded down, of a positive value.
     * Returns 0 if given 0.
     */
    function log2(uint256 value) internal pure returns (uint256) {
        uint256 result = 0;
        unchecked {
            if (value >> 128 > 0) {
                value >>= 128;
                result += 128;
            }
            if (value >> 64 > 0) {
                value >>= 64;
                result += 64;
            }
            if (value >> 32 > 0) {
                value >>= 32;
                result += 32;
            }
            if (value >> 16 > 0) {
                value >>= 16;
                result += 16;
            }
            if (value >> 8 > 0) {
                value >>= 8;
                result += 8;
            }
            if (value >> 4 > 0) {
                value >>= 4;
                result += 4;
            }
            if (value >> 2 > 0) {
                value >>= 2;
                result += 2;
            }
            if (value >> 1 > 0) {
                result += 1;
            }
        }
        return result;
    }

    /**
     * @dev Return the log in base 2, following the selected rounding direction, of a positive value.
     * Returns 0 if given 0.
     */
    function log2(uint256 value, Rounding rounding) internal pure returns (uint256) {
        unchecked {
            uint256 result = log2(value);
            return result + (rounding == Rounding.Up && 1 << result < value ? 1 : 0);
        }
    }

    /**
     * @dev Return the log in base 10, rounded down, of a positive value.
     * Returns 0 if given 0.
     */
    function log10(uint256 value) internal pure returns (uint256) {
        uint256 result = 0;
        unchecked {
            if (value >= 10**64) {
                value /= 10**64;
                result += 64;
            }
            if (value >= 10**32) {
                value /= 10**32;
                result += 32;
            }
            if (value >= 10**16) {
                value /= 10**16;
                result += 16;
            }
            if (value >= 10**8) {
                value /= 10**8;
                result += 8;
            }
            if (value >= 10**4) {
                value /= 10**4;
                result += 4;
            }
            if (value >= 10**2) {
                value /= 10**2;
                result += 2;
            }
            if (value >= 10**1) {
                result += 1;
            }
        }
        return result;
    }

    /**
     * @dev Return the log in base 10, following the selected rounding direction, of a positive value.
     * Returns 0 if given 0.
     */
    function log10(uint256 value, Rounding rounding) internal pure returns (uint256) {
        unchecked {
            uint256 result = log10(value);
            return result + (rounding == Rounding.Up && 10**result < value ? 1 : 0);
        }
    }

    /**
     * @dev Return the log in base 256, rounded down, of a positive value.
     * Returns 0 if given 0.
     *
     * Adding one to the result gives the number of pairs of hex symbols needed to represent `value` as a hex string.
     */
    function log256(uint256 value) internal pure returns (uint256) {
        uint256 result = 0;
        unchecked {
            if (value >> 128 > 0) {
                value >>= 128;
                result += 16;
            }
            if (value >> 64 > 0) {
                value >>= 64;
                result += 8;
            }
            if (value >> 32 > 0) {
                value >>= 32;
                result += 4;
            }
            if (value >> 16 > 0) {
                value >>= 16;
                result += 2;
            }
            if (value >> 8 > 0) {
                result += 1;
            }
        }
        return result;
    }

    /**
     * @dev Return the log in base 10, following the selected rounding direction, of a positive value.
     * Returns 0 if given 0.
     */
    function log256(uint256 value, Rounding rounding) internal pure returns (uint256) {
        unchecked {
            uint256 result = log256(value);
            return result + (rounding == Rounding.Up && 1 << (result * 8) < value ? 1 : 0);
        }
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
// OpenZeppelin Contracts (last updated v4.8.0) (utils/Strings.sol)

pragma solidity ^0.8.0;

import "./math/Math.sol";

/**
 * @dev String operations.
 */
library Strings {
    bytes16 private constant _SYMBOLS = "0123456789abcdef";
    uint8 private constant _ADDRESS_LENGTH = 20;

    /**
     * @dev Converts a `uint256` to its ASCII `string` decimal representation.
     */
    function toString(uint256 value) internal pure returns (string memory) {
        unchecked {
            uint256 length = Math.log10(value) + 1;
            string memory buffer = new string(length);
            uint256 ptr;
            /// @solidity memory-safe-assembly
            assembly {
                ptr := add(buffer, add(32, length))
            }
            while (true) {
                ptr--;
                /// @solidity memory-safe-assembly
                assembly {
                    mstore8(ptr, byte(mod(value, 10), _SYMBOLS))
                }
                value /= 10;
                if (value == 0) break;
            }
            return buffer;
        }
    }

    /**
     * @dev Converts a `uint256` to its ASCII `string` hexadecimal representation.
     */
    function toHexString(uint256 value) internal pure returns (string memory) {
        unchecked {
            return toHexString(value, Math.log256(value) + 1);
        }
    }

    /**
     * @dev Converts a `uint256` to its ASCII `string` hexadecimal representation with fixed length.
     */
    function toHexString(uint256 value, uint256 length) internal pure returns (string memory) {
        bytes memory buffer = new bytes(2 * length + 2);
        buffer[0] = "0";
        buffer[1] = "x";
        for (uint256 i = 2 * length + 1; i > 1; --i) {
            buffer[i] = _SYMBOLS[value & 0xf];
            value >>= 4;
        }
        require(value == 0, "Strings: hex length insufficient");
        return string(buffer);
    }

    /**
     * @dev Converts an `address` with fixed length of 20 bytes to its not checksummed ASCII `string` hexadecimal representation.
     */
    function toHexString(address addr) internal pure returns (string memory) {
        return toHexString(uint256(uint160(addr)), _ADDRESS_LENGTH);
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
// OpenZeppelin Contracts (last updated v4.8.0) (utils/Address.sol)

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
        return functionCallWithValue(target, data, 0, "Address: low-level call failed");
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
        (bool success, bytes memory returndata) = target.call{value: value}(data);
        return verifyCallResultFromTarget(target, success, returndata, errorMessage);
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
        (bool success, bytes memory returndata) = target.staticcall(data);
        return verifyCallResultFromTarget(target, success, returndata, errorMessage);
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
        (bool success, bytes memory returndata) = target.delegatecall(data);
        return verifyCallResultFromTarget(target, success, returndata, errorMessage);
    }

    /**
     * @dev Tool to verify that a low level call to smart-contract was successful, and revert (either by bubbling
     * the revert reason or using the provided one) in case of unsuccessful call or if target was not a contract.
     *
     * _Available since v4.8._
     */
    function verifyCallResultFromTarget(
        address target,
        bool success,
        bytes memory returndata,
        string memory errorMessage
    ) internal view returns (bytes memory) {
        if (success) {
            if (returndata.length == 0) {
                // only check isContract if the call was successful and the return data is empty
                // otherwise we already know that it was a contract
                require(isContract(target), "Address: call to non-contract");
            }
            return returndata;
        } else {
            _revert(returndata, errorMessage);
        }
    }

    /**
     * @dev Tool to verify that a low level call was successful, and revert if it wasn't, either by bubbling the
     * revert reason or using the provided one.
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
            _revert(returndata, errorMessage);
        }
    }

    function _revert(bytes memory returndata, string memory errorMessage) private pure {
        // Look for revert reason and bubble it up if present
        if (returndata.length > 0) {
            // The easiest way to bubble the revert reason is using memory via assembly
            /// @solidity memory-safe-assembly
            assembly {
                let returndata_size := mload(returndata)
                revert(add(32, returndata), returndata_size)
            }
        } else {
            revert(errorMessage);
        }
    }
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
// OpenZeppelin Contracts (last updated v4.6.0) (token/ERC721/IERC721Receiver.sol)

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
     * The selector can be obtained in Solidity with `IERC721Receiver.onERC721Received.selector`.
     */
    function onERC721Received(
        address operator,
        address from,
        uint256 tokenId,
        bytes calldata data
    ) external returns (bytes4);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.8.0) (token/ERC721/IERC721.sol)

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

    /**
     * @dev Safely transfers `tokenId` token from `from` to `to`, checking first that contract recipients
     * are aware of the ERC721 protocol to prevent tokens from being forever locked.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `tokenId` token must exist and be owned by `from`.
     * - If the caller is not `from`, it must have been allowed to move this token by either {approve} or {setApprovalForAll}.
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
     * WARNING: Note that the caller is responsible to confirm that the recipient is capable of receiving ERC721
     * or else they may be permanently lost. Usage of {safeTransferFrom} prevents loss, though the caller must
     * understand this adds an external call which potentially creates a reentrancy vulnerability.
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
     * @dev Returns the account approved for `tokenId` token.
     *
     * Requirements:
     *
     * - `tokenId` must exist.
     */
    function getApproved(uint256 tokenId) external view returns (address operator);

    /**
     * @dev Returns if the `operator` is allowed to manage all of the assets of `owner`.
     *
     * See {setApprovalForAll}
     */
    function isApprovedForAll(address owner, address operator) external view returns (bool);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.8.0) (token/ERC721/ERC721.sol)

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
        require(owner != address(0), "ERC721: address zero is not a valid owner");
        return _balances[owner];
    }

    /**
     * @dev See {IERC721-ownerOf}.
     */
    function ownerOf(uint256 tokenId) public view virtual override returns (address) {
        address owner = _ownerOf(tokenId);
        require(owner != address(0), "ERC721: invalid token ID");
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
        _requireMinted(tokenId);

        string memory baseURI = _baseURI();
        return bytes(baseURI).length > 0 ? string(abi.encodePacked(baseURI, tokenId.toString())) : "";
    }

    /**
     * @dev Base URI for computing {tokenURI}. If set, the resulting URI for each
     * token will be the concatenation of the `baseURI` and the `tokenId`. Empty
     * by default, can be overridden in child contracts.
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
            "ERC721: approve caller is not token owner or approved for all"
        );

        _approve(to, tokenId);
    }

    /**
     * @dev See {IERC721-getApproved}.
     */
    function getApproved(uint256 tokenId) public view virtual override returns (address) {
        _requireMinted(tokenId);

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
        require(_isApprovedOrOwner(_msgSender(), tokenId), "ERC721: caller is not token owner or approved");

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
        bytes memory data
    ) public virtual override {
        require(_isApprovedOrOwner(_msgSender(), tokenId), "ERC721: caller is not token owner or approved");
        _safeTransfer(from, to, tokenId, data);
    }

    /**
     * @dev Safely transfers `tokenId` token from `from` to `to`, checking first that contract recipients
     * are aware of the ERC721 protocol to prevent tokens from being forever locked.
     *
     * `data` is additional data, it has no specified format and it is sent in call to `to`.
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
        bytes memory data
    ) internal virtual {
        _transfer(from, to, tokenId);
        require(_checkOnERC721Received(from, to, tokenId, data), "ERC721: transfer to non ERC721Receiver implementer");
    }

    /**
     * @dev Returns the owner of the `tokenId`. Does NOT revert if token doesn't exist
     */
    function _ownerOf(uint256 tokenId) internal view virtual returns (address) {
        return _owners[tokenId];
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
        return _ownerOf(tokenId) != address(0);
    }

    /**
     * @dev Returns whether `spender` is allowed to manage `tokenId`.
     *
     * Requirements:
     *
     * - `tokenId` must exist.
     */
    function _isApprovedOrOwner(address spender, uint256 tokenId) internal view virtual returns (bool) {
        address owner = ERC721.ownerOf(tokenId);
        return (spender == owner || isApprovedForAll(owner, spender) || getApproved(tokenId) == spender);
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
        bytes memory data
    ) internal virtual {
        _mint(to, tokenId);
        require(
            _checkOnERC721Received(address(0), to, tokenId, data),
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

        _beforeTokenTransfer(address(0), to, tokenId, 1);

        // Check that tokenId was not minted by `_beforeTokenTransfer` hook
        require(!_exists(tokenId), "ERC721: token already minted");

        unchecked {
            // Will not overflow unless all 2**256 token ids are minted to the same owner.
            // Given that tokens are minted one by one, it is impossible in practice that
            // this ever happens. Might change if we allow batch minting.
            // The ERC fails to describe this case.
            _balances[to] += 1;
        }

        _owners[tokenId] = to;

        emit Transfer(address(0), to, tokenId);

        _afterTokenTransfer(address(0), to, tokenId, 1);
    }

    /**
     * @dev Destroys `tokenId`.
     * The approval is cleared when the token is burned.
     * This is an internal function that does not check if the sender is authorized to operate on the token.
     *
     * Requirements:
     *
     * - `tokenId` must exist.
     *
     * Emits a {Transfer} event.
     */
    function _burn(uint256 tokenId) internal virtual {
        address owner = ERC721.ownerOf(tokenId);

        _beforeTokenTransfer(owner, address(0), tokenId, 1);

        // Update ownership in case tokenId was transferred by `_beforeTokenTransfer` hook
        owner = ERC721.ownerOf(tokenId);

        // Clear approvals
        delete _tokenApprovals[tokenId];

        unchecked {
            // Cannot overflow, as that would require more tokens to be burned/transferred
            // out than the owner initially received through minting and transferring in.
            _balances[owner] -= 1;
        }
        delete _owners[tokenId];

        emit Transfer(owner, address(0), tokenId);

        _afterTokenTransfer(owner, address(0), tokenId, 1);
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

        _beforeTokenTransfer(from, to, tokenId, 1);

        // Check that tokenId was not transferred by `_beforeTokenTransfer` hook
        require(ERC721.ownerOf(tokenId) == from, "ERC721: transfer from incorrect owner");

        // Clear approvals from the previous owner
        delete _tokenApprovals[tokenId];

        unchecked {
            // `_balances[from]` cannot overflow for the same reason as described in `_burn`:
            // `from`'s balance is the number of token held, which is at least one before the current
            // transfer.
            // `_balances[to]` could overflow in the conditions described in `_mint`. That would require
            // all 2**256 token ids to be minted, which in practice is impossible.
            _balances[from] -= 1;
            _balances[to] += 1;
        }
        _owners[tokenId] = to;

        emit Transfer(from, to, tokenId);

        _afterTokenTransfer(from, to, tokenId, 1);
    }

    /**
     * @dev Approve `to` to operate on `tokenId`
     *
     * Emits an {Approval} event.
     */
    function _approve(address to, uint256 tokenId) internal virtual {
        _tokenApprovals[tokenId] = to;
        emit Approval(ERC721.ownerOf(tokenId), to, tokenId);
    }

    /**
     * @dev Approve `operator` to operate on all of `owner` tokens
     *
     * Emits an {ApprovalForAll} event.
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
     * @dev Reverts if the `tokenId` has not been minted yet.
     */
    function _requireMinted(uint256 tokenId) internal view virtual {
        require(_exists(tokenId), "ERC721: invalid token ID");
    }

    /**
     * @dev Internal function to invoke {IERC721Receiver-onERC721Received} on a target address.
     * The call is not executed if the target address is not a contract.
     *
     * @param from address representing the previous owner of the given token ID
     * @param to target address that will receive the tokens
     * @param tokenId uint256 ID of the token to be transferred
     * @param data bytes optional data to send along with the call
     * @return bool whether the call correctly returned the expected magic value
     */
    function _checkOnERC721Received(
        address from,
        address to,
        uint256 tokenId,
        bytes memory data
    ) private returns (bool) {
        if (to.isContract()) {
            try IERC721Receiver(to).onERC721Received(_msgSender(), from, tokenId, data) returns (bytes4 retval) {
                return retval == IERC721Receiver.onERC721Received.selector;
            } catch (bytes memory reason) {
                if (reason.length == 0) {
                    revert("ERC721: transfer to non ERC721Receiver implementer");
                } else {
                    /// @solidity memory-safe-assembly
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
     * @dev Hook that is called before any token transfer. This includes minting and burning. If {ERC721Consecutive} is
     * used, the hook may be called as part of a consecutive (batch) mint, as indicated by `batchSize` greater than 1.
     *
     * Calling conditions:
     *
     * - When `from` and `to` are both non-zero, ``from``'s tokens will be transferred to `to`.
     * - When `from` is zero, the tokens will be minted for `to`.
     * - When `to` is zero, ``from``'s tokens will be burned.
     * - `from` and `to` are never both zero.
     * - `batchSize` is non-zero.
     *
     * To learn more about hooks, head to xref:ROOT:extending-contracts.adoc#using-hooks[Using Hooks].
     */
    function _beforeTokenTransfer(
        address from,
        address to,
        uint256, /* firstTokenId */
        uint256 batchSize
    ) internal virtual {
        if (batchSize > 1) {
            if (from != address(0)) {
                _balances[from] -= batchSize;
            }
            if (to != address(0)) {
                _balances[to] += batchSize;
            }
        }
    }

    /**
     * @dev Hook that is called after any token transfer. This includes minting and burning. If {ERC721Consecutive} is
     * used, the hook may be called as part of a consecutive (batch) mint, as indicated by `batchSize` greater than 1.
     *
     * Calling conditions:
     *
     * - When `from` and `to` are both non-zero, ``from``'s tokens were transferred to `to`.
     * - When `from` is zero, the tokens were minted for `to`.
     * - When `to` is zero, ``from``'s tokens were burned.
     * - `from` and `to` are never both zero.
     * - `batchSize` is non-zero.
     *
     * To learn more about hooks, head to xref:ROOT:extending-contracts.adoc#using-hooks[Using Hooks].
     */
    function _afterTokenTransfer(
        address from,
        address to,
        uint256 firstTokenId,
        uint256 batchSize
    ) internal virtual {}
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (access/Ownable.sol)

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
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        _checkOwner();
        _;
    }

    /**
     * @dev Returns the address of the current owner.
     */
    function owner() public view virtual returns (address) {
        return _owner;
    }

    /**
     * @dev Throws if the sender is not the owner.
     */
    function _checkOwner() internal view virtual {
        require(owner() == _msgSender(), "Ownable: caller is not the owner");
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