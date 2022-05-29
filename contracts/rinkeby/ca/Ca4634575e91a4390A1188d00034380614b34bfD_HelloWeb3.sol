// SPDX-License-Identifier: MIT
pragma solidity 0.8.4;

import "./FOMOPASS.sol";
import "./RoyaltySplits.sol";

/// @author FOMOLOL (fomolol.com)

/**
 *
 * ██╗░░██╗███████╗██╗░░░░░██╗░░░░░░█████╗░███╗░░██╗███████╗████████╗██╗
 * ██║░░██║██╔════╝██║░░░░░██║░░░░░██╔══██╗████╗░██║██╔════╝╚══██╔══╝██║
 * ███████║█████╗░░██║░░░░░██║░░░░░██║░░██║██╔██╗██║█████╗░░░░░██║░░░██║
 * ██╔══██║██╔══╝░░██║░░░░░██║░░░░░██║░░██║██║╚████║██╔══╝░░░░░██║░░░╚═╝
 * ██║░░██║███████╗███████╗███████╗╚█████╔╝██║░╚███║██║░░░░░░░░██║░░░██╗
 * ╚═╝░░╚═╝╚══════╝╚══════╝╚══════╝░╚════╝░╚═╝░░╚══╝╚═╝░░░░░░░░╚═╝░░░╚═╝
 * @title HELLO NFT!
 */
contract HelloWeb3 is RoyaltySplits, FOMOPASS {
	constructor(
		string memory _symbol,
		string memory _name,
		string memory _uri
	) FOMOPASS(_symbol, _name, _uri, addresses, splits) {}
}

/*
 *
 *   Permission is hereby granted, free of charge, to any person obtaining a copy of this...HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF
 *   CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER...SOFTWARE.
 *
 *   Art by EON (@Colette00000), and concept by Jiwon (@dimanchelunch) and Youngsun (@youngsunlive)
 *   Twitter @hello_web3
 *
 *   Smart contract developed for Hello NFT! by FOMOLOL LLC
 */

// SPDX-License-Identifier: MIT
pragma solidity 0.8.4;

/// @author FOMOLOL (fomolol.com)

import "./libs/BetterBoolean.sol";
import "./libs/SafeAddress.sol";
import "./libs/ABDKMath64x64.sol";
import "./security/ContractGuardian.sol";
import "./finance/LockedPaymentSplitter.sol";

import "@openzeppelin/contracts/interfaces/IERC2981.sol";
import "@openzeppelin/contracts/token/ERC1155/ERC1155.sol";
import "@openzeppelin/contracts/token/ERC1155/extensions/ERC1155Supply.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/Pausable.sol";
import "@openzeppelin/contracts/utils/Context.sol";
import "@openzeppelin/contracts/utils/introspection/ERC165.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/utils/cryptography/ECDSA.sol";

/// @dev Errors
/**
 * @notice Token is not free. Needed `amount` to be more than zero.
 * @param amount total mint price.
 */
error NotFree(uint256 amount);
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
 * @title FOMOPASS
 * @author FOMOLOL (fomolol.com)
 * @dev Standard ERC1155 implementation
 *
 * ERC1155 NFT contract, with reserves, payment splitting and paid token features.
 *
 * In addition to using ERC1155, gas is optimized via boolean packing
 * and use of constants where possible.
 */
/// @custom:security-contact [email protected]
abstract contract FOMOPASS is
	ERC1155,
	IERC2981,
	Ownable,
	Pausable,
	ERC1155Supply,
	ContractGuardian,
	ReentrancyGuard,
	LockedPaymentSplitter
{
	enum Status {
		Pending,
		PublicSale,
		Finished
	}

	using SafeAddress for address;
	using ABDKMath64x64 for uint;
	using BetterBoolean for uint256;
	using Strings for uint256;
	using ECDSA for bytes32;

	Status public status;

	string private name_;
	string private symbol_;
	address private _recipient;

	uint256 public constant MAX_PER_WALLET_LIMIT = 50;
	uint256 public constant PASS_ALL_ACCESS_ID = 0;
	uint256 public constant PASS_EVENTS_ONLY_ID = 1;
	uint256 public tokensReserved;

	bool public metadataRevealed;
	bool public metadataFinalised;

	mapping(uint256 => string) private _uris;
	mapping(uint256 => uint256) private _costs;
	mapping(uint256 => uint256) private _maxSupplies;
	mapping(uint256 => uint256) private _maxBatchSizes;

	/// @dev Events
	event PermanentURI(string _value, uint256 indexed _id);
	event TokensMinted(
		address indexed mintedBy,
		uint256 indexed id,
		uint256 indexed quantity
	);
	event BaseUriUpdated(string oldBaseUri, string newBaseUri);
	event CostUpdated(uint256 oldCost, uint256 newCost);
	event ReservedToken(address minter, address recipient, uint256 amount);
	event StatusChanged(Status status);

	constructor(
		string memory _symbol,
		string memory _name,
		string memory __uri,
		address[] memory __addresses,
		uint256[] memory __splits
	) ERC1155(__uri) SlimPaymentSplitter(__addresses, __splits) {
		name_ = _name;
		symbol_ = _symbol;

		// Set royalty recipient
		_recipient = owner();

		// All Access Pass
		_costs[PASS_ALL_ACCESS_ID] = 0.1 ether;
		_uris[
			PASS_ALL_ACCESS_ID
		] = "ipfs://QmUvDi6gUZ8HLazUuuzij4bi3GoJWoLEg2bL95AH3r7qih/0.json";
		_maxSupplies[PASS_ALL_ACCESS_ID] = 200;
		_maxBatchSizes[PASS_ALL_ACCESS_ID] = 25;

		// Events Only Pass
		_costs[PASS_EVENTS_ONLY_ID] = 0.05 ether;
		_uris[
			PASS_EVENTS_ONLY_ID
		] = "ipfs://QmUvDi6gUZ8HLazUuuzij4bi3GoJWoLEg2bL95AH3r7qih/1.json";
		_maxSupplies[PASS_EVENTS_ONLY_ID] = 300;
		_maxBatchSizes[PASS_EVENTS_ONLY_ID] = 25;
	}

	/**
	 * @dev Throws if amount if less than zero.
	 */
	function _isNotFree(uint256 amount) internal pure {
		if (amount <= 0) {
			revert NotFree(amount);
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
	 * @dev Throws if max tokens per wallet
	 * @param id token id to check
	 * @param quantity quantity to check
	 */
	function _isMaxTokensPerWallet(uint256 id, uint256 quantity) internal view {
		if (_msgSender() != owner()) {
			uint256 mintedBalance = balanceOf(_msgSender(), id);
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
	 * @param id token id to check
	 * @param quantity quantity to check
	 */
	function _isCorrectAmountProvided(uint256 id, uint256 quantity)
		internal
		view
	{
		uint256 mintCost = _costs[id];
		uint256 totalCost = quantity * mintCost;
		if (msg.value < totalCost && _msgSender() != owner()) {
			revert InsufficientBalance(msg.value, totalCost);
		}
	}

	/**
	 * @dev Throws if the claim size is not valid
	 * @param id token id to check
	 * @param count total to check
	 */
	function _isValidBatchSize(uint256 id, uint256 count) internal view {
		require(
			0 < count && count <= _maxBatchSizes[id],
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
	 * @dev Throws if the total being minted is greater than the max supply
	 */
	function _isLessThanMaxSupply(uint256 id, uint256 quantity) internal view {
		uint256 _maxSupply = _maxSupplies[id];
		if (totalSupply(id) + quantity > _maxSupply) {
			revert MaxSupplyExceeded(totalSupply(id) + quantity, _maxSupply);
		}
	}

	/**
	 * @dev Mint function for reserved tokens.
	 * @param minter is the address minting the token(s).
	 * @param quantity is total tokens to mint.
	 */
	function _internalMintTokens(
		address minter,
		uint256 id,
		uint256 quantity
	) internal {
		_isLessThanMaxSupply(id, quantity);
		_mint(minter, id, quantity, "");
	}

	/**
	 * @dev Allows us to specify the collection name.
	 */
	function name() public view returns (string memory) {
		return name_;
	}

	/**
	 * @dev Allows us to specify the token symbol.
	 */
	function symbol() public view returns (string memory) {
		return symbol_;
	}

	/**
	 * @dev Pause the contract
	 */
	function pause() public onlyOwner {
		_pause();
	}

	/**
	 * @dev Unpause the contract
	 */
	function unpause() public onlyOwner {
		_unpause();
	}

	/**
	 * @notice Reserve token(s) to multiple team members.
	 *
	 * @param frens addresses to send tokens to
	 * @param quantity the number of tokens to mint.
	 */
	function reserve(
		address[] memory frens,
		uint256 id,
		uint256 quantity
	) external onlyOwner {
		_isMintingOne(quantity);
		_isValidBatchSize(id, quantity);
		_isLessThanMaxSupply(id, quantity);

		uint256 idx;
		for (idx = 0; idx < frens.length; idx++) {
			require(frens[idx] != address(0), "Zero address");
			_internalMintTokens(frens[idx], id, quantity);
			tokensReserved += quantity;
			emit ReservedToken(_msgSender(), frens[idx], quantity);
		}
	}

	/**
	 * @notice Reserve multiple tokens to a single team member.
	 *
	 * @param fren Address to send tokens to
	 * @param id Token id to mint
	 * @param quantity Number of tokens to mint
	 */
	function reserveSingle(
		address fren,
		uint256 id,
		uint256 quantity
	) external onlyOwner {
		_isMintingOne(quantity);
		_isValidBatchSize(id, quantity);
		_isLessThanMaxSupply(id, quantity);

		uint256 _maxBatchSize = _maxBatchSizes[id];
		uint256 multiple = quantity / _maxBatchSize;
		for (uint256 i = 0; i < multiple; i++) {
			_internalMintTokens(fren, id, _maxBatchSize);
		}
		uint256 remainder = quantity % _maxBatchSize;
		if (remainder != 0) {
			_internalMintTokens(fren, id, remainder);
		}
		tokensReserved += quantity;
		emit ReservedToken(_msgSender(), fren, quantity);
	}

	/**
	 * @dev The public mint function.
	 * @param id Token id to mint.
	 * @param quantity Total number of tokens to mint.
	 */
	function mint(uint256 id, uint256 quantity)
		public
		payable
		nonReentrant
		onlyUsers
	{
		_isPublicSaleActive();
		_isMaxTokensPerWallet(id, quantity);
		_isCorrectAmountProvided(id, quantity);
		_isMintingOne(quantity);
		_isLessThanMaxSupply(id, quantity);

		_mint(_msgSender(), id, quantity, "");
		emit TokensMinted(_msgSender(), id, quantity);
	}

	/**
	 * @notice This is a mint cost override (must be in wei)
	 * @dev Handles setting the mint cost
	 * @param id token id to set the cost for
	 * @param _cost new cost to associate with minting tokens (in wei)
	 */
	function setMintCost(uint256 id, uint256 _cost) public onlyOwner {
		_isNotFree(_cost);
		uint256 currentCost = _costs[id];
		_costs[id] = _cost; // in wei
		emit CostUpdated(currentCost, _cost);
	}

	/**
	 * @dev Handles updating the status
	 */
	function setStatus(Status _status) external onlyOwner {
		status = _status;
		emit StatusChanged(_status);
	}

	/**
	 * @dev override for before token transfer method
	 */
	function _beforeTokenTransfer(
		address operator,
		address from,
		address to,
		uint256[] memory ids,
		uint256[] memory amounts,
		bytes memory data
	) internal override(ERC1155, ERC1155Supply) whenNotPaused {
		super._beforeTokenTransfer(operator, from, to, ids, amounts, data);
		require(!paused(), "token transfer while paused");
	}

	/**
	 * @dev override for the uri that allows IPFS to be used
	 * @param id token id to update uri for
	 */
	function uri(uint256 id) public view override returns (string memory) {
		return (_uris[id]);
	}

	/**
	 * @dev handles returning the cost for a token
	 * @param id token id to update uri for
	 */
	function cost(uint256 id) public view returns (uint256) {
		return (_costs[id]);
	}

	/**
	 * @dev override for the uri that allows IPFS to be used
	 * @param id token id to update uri for
	 * @param _uri uri for token id
	 */
	function setTokenUri(uint256 id, string memory _uri) public onlyOwner {
		_uris[id] = _uri;
	}

	/**
	 * @dev handles returning the max supply for a token
	 * @param id token id to update uri for
	 */
	function maxSupply(uint256 id) public view returns (uint256) {
		return (_maxSupplies[id]);
	}

	/**
	 * @dev handles returning the max batch size for a token
	 * @param id token id to update uri for
	 */
	function maxBatchSize(uint256 id) public view returns (uint256) {
		return (_maxBatchSizes[id]);
	}

	/**
	 * @dev handles adjusting the max supply
	 * @param id token id to update uri for
	 * @param quantity to change the max supply to
	 */
	function setMaxSupply(uint256 id, uint256 quantity) public onlyOwner {
		_maxSupplies[id] = quantity;
	}

	/**
	 * @dev handles adjusting the max batch size
	 * @param id token id to update uri for
	 * @param quantity to change the max supply to
	 */
	function setMaxBatchSize(uint256 id, uint256 quantity) public onlyOwner {
		_maxBatchSizes[id] = quantity;
	}

	/** @dev EIP2981 royalties implementation. */

	// Maintain flexibility to modify royalties recipient (could also add basis points).
	function _setRoyalties(address newRecipient) internal {
		require(newRecipient != address(0), "royalty recipient zero address");
		_recipient = newRecipient;
	}

	function setRoyalties(address newRecipient) external onlyOwner {
		_setRoyalties(newRecipient);
	}

	// EIP2981 standard royalties return.
	function royaltyInfo(uint256 _tokenId, uint256 _salePrice)
		external
		view
		override
		returns (address receiver, uint256 royaltyAmount)
	{
		return (_recipient, (_salePrice * 500) / 10000); // 5% (500 basis points)
	}

	// EIP2981 standard Interface return. Adds to ERC1155 and ERC165 Interface returns.
	function supportsInterface(bytes4 interfaceId)
		public
		view
		virtual
		override(ERC1155, IERC165)
		returns (bool)
	{
		return (interfaceId == type(IERC2981).interfaceId ||
			super.supportsInterface(interfaceId));
	}
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.4;

/// @author FOMOLOL (fomolol.com)

contract RoyaltySplits {
	address[] internal addresses = [
		0xb1759409c127De32974b14c6390738920c74847e // founder
	];

	uint256[] internal splits = [100];
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.4;

/**
 * @title BetterBoolean
 * @author FOMOLOL (fomolol.com)
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
// OpenZeppelin Contracts v4.4.1 (interfaces/IERC2981.sol)

pragma solidity ^0.8.0;

import "./IERC165.sol";

/**
 * @dev Interface for the NFT Royalty Standard
 */
interface IERC2981 is IERC165 {
    /**
     * @dev Called with the sale price to determine how much royalty is owed and to whom.
     * @param tokenId - the NFT asset queried for royalty information
     * @param salePrice - the sale price of the NFT asset specified by `tokenId`
     * @return receiver - address of who should be sent the royalty payment
     * @return royaltyAmount - the royalty payment amount for `salePrice`
     */
    function royaltyInfo(uint256 tokenId, uint256 salePrice)
        external
        view
        returns (address receiver, uint256 royaltyAmount);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (token/ERC1155/ERC1155.sol)

pragma solidity ^0.8.0;

import "./IERC1155.sol";
import "./IERC1155Receiver.sol";
import "./extensions/IERC1155MetadataURI.sol";
import "../../utils/Address.sol";
import "../../utils/Context.sol";
import "../../utils/introspection/ERC165.sol";

/**
 * @dev Implementation of the basic standard multi-token.
 * See https://eips.ethereum.org/EIPS/eip-1155
 * Originally based on code by Enjin: https://github.com/enjin/erc-1155
 *
 * _Available since v3.1._
 */
contract ERC1155 is Context, ERC165, IERC1155, IERC1155MetadataURI {
    using Address for address;

    // Mapping from token ID to account balances
    mapping(uint256 => mapping(address => uint256)) private _balances;

    // Mapping from account to operator approvals
    mapping(address => mapping(address => bool)) private _operatorApprovals;

    // Used as the URI for all token types by relying on ID substitution, e.g. https://token-cdn-domain/{id}.json
    string private _uri;

    /**
     * @dev See {_setURI}.
     */
    constructor(string memory uri_) {
        _setURI(uri_);
    }

    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId) public view virtual override(ERC165, IERC165) returns (bool) {
        return
            interfaceId == type(IERC1155).interfaceId ||
            interfaceId == type(IERC1155MetadataURI).interfaceId ||
            super.supportsInterface(interfaceId);
    }

    /**
     * @dev See {IERC1155MetadataURI-uri}.
     *
     * This implementation returns the same URI for *all* token types. It relies
     * on the token type ID substitution mechanism
     * https://eips.ethereum.org/EIPS/eip-1155#metadata[defined in the EIP].
     *
     * Clients calling this function must replace the `\{id\}` substring with the
     * actual token type ID.
     */
    function uri(uint256) public view virtual override returns (string memory) {
        return _uri;
    }

    /**
     * @dev See {IERC1155-balanceOf}.
     *
     * Requirements:
     *
     * - `account` cannot be the zero address.
     */
    function balanceOf(address account, uint256 id) public view virtual override returns (uint256) {
        require(account != address(0), "ERC1155: balance query for the zero address");
        return _balances[id][account];
    }

    /**
     * @dev See {IERC1155-balanceOfBatch}.
     *
     * Requirements:
     *
     * - `accounts` and `ids` must have the same length.
     */
    function balanceOfBatch(address[] memory accounts, uint256[] memory ids)
        public
        view
        virtual
        override
        returns (uint256[] memory)
    {
        require(accounts.length == ids.length, "ERC1155: accounts and ids length mismatch");

        uint256[] memory batchBalances = new uint256[](accounts.length);

        for (uint256 i = 0; i < accounts.length; ++i) {
            batchBalances[i] = balanceOf(accounts[i], ids[i]);
        }

        return batchBalances;
    }

    /**
     * @dev See {IERC1155-setApprovalForAll}.
     */
    function setApprovalForAll(address operator, bool approved) public virtual override {
        _setApprovalForAll(_msgSender(), operator, approved);
    }

    /**
     * @dev See {IERC1155-isApprovedForAll}.
     */
    function isApprovedForAll(address account, address operator) public view virtual override returns (bool) {
        return _operatorApprovals[account][operator];
    }

    /**
     * @dev See {IERC1155-safeTransferFrom}.
     */
    function safeTransferFrom(
        address from,
        address to,
        uint256 id,
        uint256 amount,
        bytes memory data
    ) public virtual override {
        require(
            from == _msgSender() || isApprovedForAll(from, _msgSender()),
            "ERC1155: caller is not owner nor approved"
        );
        _safeTransferFrom(from, to, id, amount, data);
    }

    /**
     * @dev See {IERC1155-safeBatchTransferFrom}.
     */
    function safeBatchTransferFrom(
        address from,
        address to,
        uint256[] memory ids,
        uint256[] memory amounts,
        bytes memory data
    ) public virtual override {
        require(
            from == _msgSender() || isApprovedForAll(from, _msgSender()),
            "ERC1155: transfer caller is not owner nor approved"
        );
        _safeBatchTransferFrom(from, to, ids, amounts, data);
    }

    /**
     * @dev Transfers `amount` tokens of token type `id` from `from` to `to`.
     *
     * Emits a {TransferSingle} event.
     *
     * Requirements:
     *
     * - `to` cannot be the zero address.
     * - `from` must have a balance of tokens of type `id` of at least `amount`.
     * - If `to` refers to a smart contract, it must implement {IERC1155Receiver-onERC1155Received} and return the
     * acceptance magic value.
     */
    function _safeTransferFrom(
        address from,
        address to,
        uint256 id,
        uint256 amount,
        bytes memory data
    ) internal virtual {
        require(to != address(0), "ERC1155: transfer to the zero address");

        address operator = _msgSender();

        _beforeTokenTransfer(operator, from, to, _asSingletonArray(id), _asSingletonArray(amount), data);

        uint256 fromBalance = _balances[id][from];
        require(fromBalance >= amount, "ERC1155: insufficient balance for transfer");
        unchecked {
            _balances[id][from] = fromBalance - amount;
        }
        _balances[id][to] += amount;

        emit TransferSingle(operator, from, to, id, amount);

        _doSafeTransferAcceptanceCheck(operator, from, to, id, amount, data);
    }

    /**
     * @dev xref:ROOT:erc1155.adoc#batch-operations[Batched] version of {_safeTransferFrom}.
     *
     * Emits a {TransferBatch} event.
     *
     * Requirements:
     *
     * - If `to` refers to a smart contract, it must implement {IERC1155Receiver-onERC1155BatchReceived} and return the
     * acceptance magic value.
     */
    function _safeBatchTransferFrom(
        address from,
        address to,
        uint256[] memory ids,
        uint256[] memory amounts,
        bytes memory data
    ) internal virtual {
        require(ids.length == amounts.length, "ERC1155: ids and amounts length mismatch");
        require(to != address(0), "ERC1155: transfer to the zero address");

        address operator = _msgSender();

        _beforeTokenTransfer(operator, from, to, ids, amounts, data);

        for (uint256 i = 0; i < ids.length; ++i) {
            uint256 id = ids[i];
            uint256 amount = amounts[i];

            uint256 fromBalance = _balances[id][from];
            require(fromBalance >= amount, "ERC1155: insufficient balance for transfer");
            unchecked {
                _balances[id][from] = fromBalance - amount;
            }
            _balances[id][to] += amount;
        }

        emit TransferBatch(operator, from, to, ids, amounts);

        _doSafeBatchTransferAcceptanceCheck(operator, from, to, ids, amounts, data);
    }

    /**
     * @dev Sets a new URI for all token types, by relying on the token type ID
     * substitution mechanism
     * https://eips.ethereum.org/EIPS/eip-1155#metadata[defined in the EIP].
     *
     * By this mechanism, any occurrence of the `\{id\}` substring in either the
     * URI or any of the amounts in the JSON file at said URI will be replaced by
     * clients with the token type ID.
     *
     * For example, the `https://token-cdn-domain/\{id\}.json` URI would be
     * interpreted by clients as
     * `https://token-cdn-domain/000000000000000000000000000000000000000000000000000000000004cce0.json`
     * for token type ID 0x4cce0.
     *
     * See {uri}.
     *
     * Because these URIs cannot be meaningfully represented by the {URI} event,
     * this function emits no events.
     */
    function _setURI(string memory newuri) internal virtual {
        _uri = newuri;
    }

    /**
     * @dev Creates `amount` tokens of token type `id`, and assigns them to `to`.
     *
     * Emits a {TransferSingle} event.
     *
     * Requirements:
     *
     * - `to` cannot be the zero address.
     * - If `to` refers to a smart contract, it must implement {IERC1155Receiver-onERC1155Received} and return the
     * acceptance magic value.
     */
    function _mint(
        address to,
        uint256 id,
        uint256 amount,
        bytes memory data
    ) internal virtual {
        require(to != address(0), "ERC1155: mint to the zero address");

        address operator = _msgSender();

        _beforeTokenTransfer(operator, address(0), to, _asSingletonArray(id), _asSingletonArray(amount), data);

        _balances[id][to] += amount;
        emit TransferSingle(operator, address(0), to, id, amount);

        _doSafeTransferAcceptanceCheck(operator, address(0), to, id, amount, data);
    }

    /**
     * @dev xref:ROOT:erc1155.adoc#batch-operations[Batched] version of {_mint}.
     *
     * Requirements:
     *
     * - `ids` and `amounts` must have the same length.
     * - If `to` refers to a smart contract, it must implement {IERC1155Receiver-onERC1155BatchReceived} and return the
     * acceptance magic value.
     */
    function _mintBatch(
        address to,
        uint256[] memory ids,
        uint256[] memory amounts,
        bytes memory data
    ) internal virtual {
        require(to != address(0), "ERC1155: mint to the zero address");
        require(ids.length == amounts.length, "ERC1155: ids and amounts length mismatch");

        address operator = _msgSender();

        _beforeTokenTransfer(operator, address(0), to, ids, amounts, data);

        for (uint256 i = 0; i < ids.length; i++) {
            _balances[ids[i]][to] += amounts[i];
        }

        emit TransferBatch(operator, address(0), to, ids, amounts);

        _doSafeBatchTransferAcceptanceCheck(operator, address(0), to, ids, amounts, data);
    }

    /**
     * @dev Destroys `amount` tokens of token type `id` from `from`
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `from` must have at least `amount` tokens of token type `id`.
     */
    function _burn(
        address from,
        uint256 id,
        uint256 amount
    ) internal virtual {
        require(from != address(0), "ERC1155: burn from the zero address");

        address operator = _msgSender();

        _beforeTokenTransfer(operator, from, address(0), _asSingletonArray(id), _asSingletonArray(amount), "");

        uint256 fromBalance = _balances[id][from];
        require(fromBalance >= amount, "ERC1155: burn amount exceeds balance");
        unchecked {
            _balances[id][from] = fromBalance - amount;
        }

        emit TransferSingle(operator, from, address(0), id, amount);
    }

    /**
     * @dev xref:ROOT:erc1155.adoc#batch-operations[Batched] version of {_burn}.
     *
     * Requirements:
     *
     * - `ids` and `amounts` must have the same length.
     */
    function _burnBatch(
        address from,
        uint256[] memory ids,
        uint256[] memory amounts
    ) internal virtual {
        require(from != address(0), "ERC1155: burn from the zero address");
        require(ids.length == amounts.length, "ERC1155: ids and amounts length mismatch");

        address operator = _msgSender();

        _beforeTokenTransfer(operator, from, address(0), ids, amounts, "");

        for (uint256 i = 0; i < ids.length; i++) {
            uint256 id = ids[i];
            uint256 amount = amounts[i];

            uint256 fromBalance = _balances[id][from];
            require(fromBalance >= amount, "ERC1155: burn amount exceeds balance");
            unchecked {
                _balances[id][from] = fromBalance - amount;
            }
        }

        emit TransferBatch(operator, from, address(0), ids, amounts);
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
        require(owner != operator, "ERC1155: setting approval status for self");
        _operatorApprovals[owner][operator] = approved;
        emit ApprovalForAll(owner, operator, approved);
    }

    /**
     * @dev Hook that is called before any token transfer. This includes minting
     * and burning, as well as batched variants.
     *
     * The same hook is called on both single and batched variants. For single
     * transfers, the length of the `id` and `amount` arrays will be 1.
     *
     * Calling conditions (for each `id` and `amount` pair):
     *
     * - When `from` and `to` are both non-zero, `amount` of ``from``'s tokens
     * of token type `id` will be  transferred to `to`.
     * - When `from` is zero, `amount` tokens of token type `id` will be minted
     * for `to`.
     * - when `to` is zero, `amount` of ``from``'s tokens of token type `id`
     * will be burned.
     * - `from` and `to` are never both zero.
     * - `ids` and `amounts` have the same, non-zero length.
     *
     * To learn more about hooks, head to xref:ROOT:extending-contracts.adoc#using-hooks[Using Hooks].
     */
    function _beforeTokenTransfer(
        address operator,
        address from,
        address to,
        uint256[] memory ids,
        uint256[] memory amounts,
        bytes memory data
    ) internal virtual {}

    function _doSafeTransferAcceptanceCheck(
        address operator,
        address from,
        address to,
        uint256 id,
        uint256 amount,
        bytes memory data
    ) private {
        if (to.isContract()) {
            try IERC1155Receiver(to).onERC1155Received(operator, from, id, amount, data) returns (bytes4 response) {
                if (response != IERC1155Receiver.onERC1155Received.selector) {
                    revert("ERC1155: ERC1155Receiver rejected tokens");
                }
            } catch Error(string memory reason) {
                revert(reason);
            } catch {
                revert("ERC1155: transfer to non ERC1155Receiver implementer");
            }
        }
    }

    function _doSafeBatchTransferAcceptanceCheck(
        address operator,
        address from,
        address to,
        uint256[] memory ids,
        uint256[] memory amounts,
        bytes memory data
    ) private {
        if (to.isContract()) {
            try IERC1155Receiver(to).onERC1155BatchReceived(operator, from, ids, amounts, data) returns (
                bytes4 response
            ) {
                if (response != IERC1155Receiver.onERC1155BatchReceived.selector) {
                    revert("ERC1155: ERC1155Receiver rejected tokens");
                }
            } catch Error(string memory reason) {
                revert(reason);
            } catch {
                revert("ERC1155: transfer to non ERC1155Receiver implementer");
            }
        }
    }

    function _asSingletonArray(uint256 element) private pure returns (uint256[] memory) {
        uint256[] memory array = new uint256[](1);
        array[0] = element;

        return array;
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (token/ERC1155/extensions/ERC1155Supply.sol)

pragma solidity ^0.8.0;

import "../ERC1155.sol";

/**
 * @dev Extension of ERC1155 that adds tracking of total supply per id.
 *
 * Useful for scenarios where Fungible and Non-fungible tokens have to be
 * clearly identified. Note: While a totalSupply of 1 might mean the
 * corresponding is an NFT, there is no guarantees that no other token with the
 * same id are not going to be minted.
 */
abstract contract ERC1155Supply is ERC1155 {
    mapping(uint256 => uint256) private _totalSupply;

    /**
     * @dev Total amount of tokens in with a given id.
     */
    function totalSupply(uint256 id) public view virtual returns (uint256) {
        return _totalSupply[id];
    }

    /**
     * @dev Indicates whether any token exist with a given id, or not.
     */
    function exists(uint256 id) public view virtual returns (bool) {
        return ERC1155Supply.totalSupply(id) > 0;
    }

    /**
     * @dev See {ERC1155-_beforeTokenTransfer}.
     */
    function _beforeTokenTransfer(
        address operator,
        address from,
        address to,
        uint256[] memory ids,
        uint256[] memory amounts,
        bytes memory data
    ) internal virtual override {
        super._beforeTokenTransfer(operator, from, to, ids, amounts, data);

        if (from == address(0)) {
            for (uint256 i = 0; i < ids.length; ++i) {
                _totalSupply[ids[i]] += amounts[i];
            }
        }

        if (to == address(0)) {
            for (uint256 i = 0; i < ids.length; ++i) {
                _totalSupply[ids[i]] -= amounts[i];
            }
        }
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
// OpenZeppelin Contracts v4.4.1 (security/Pausable.sol)

pragma solidity ^0.8.0;

import "../utils/Context.sol";

/**
 * @dev Contract module which allows children to implement an emergency stop
 * mechanism that can be triggered by an authorized account.
 *
 * This module is used through inheritance. It will make available the
 * modifiers `whenNotPaused` and `whenPaused`, which can be applied to
 * the functions of your contract. Note that they will not be pausable by
 * simply including this module, only once the modifiers are put in place.
 */
abstract contract Pausable is Context {
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
    constructor() {
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
        require(!paused(), "Pausable: paused");
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
        require(paused(), "Pausable: not paused");
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

pragma solidity 0.8.4;

import "@openzeppelin/contracts/utils/Address.sol";
import "@openzeppelin/contracts/utils/Context.sol";

/**
 * @title SlimPaymentSplitter
 * @author @NiftyMike, NFT Culture (original)
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
// OpenZeppelin Contracts v4.4.1 (interfaces/IERC165.sol)

pragma solidity ^0.8.0;

import "../utils/introspection/IERC165.sol";

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
// OpenZeppelin Contracts v4.4.1 (token/ERC1155/IERC1155Receiver.sol)

pragma solidity ^0.8.0;

import "../../utils/introspection/IERC165.sol";

/**
 * @dev _Available since v3.1._
 */
interface IERC1155Receiver is IERC165 {
    /**
        @dev Handles the receipt of a single ERC1155 token type. This function is
        called at the end of a `safeTransferFrom` after the balance has been updated.
        To accept the transfer, this must return
        `bytes4(keccak256("onERC1155Received(address,address,uint256,uint256,bytes)"))`
        (i.e. 0xf23a6e61, or its own function selector).
        @param operator The address which initiated the transfer (i.e. msg.sender)
        @param from The address which previously owned the token
        @param id The ID of the token being transferred
        @param value The amount of tokens being transferred
        @param data Additional data with no specified format
        @return `bytes4(keccak256("onERC1155Received(address,address,uint256,uint256,bytes)"))` if transfer is allowed
    */
    function onERC1155Received(
        address operator,
        address from,
        uint256 id,
        uint256 value,
        bytes calldata data
    ) external returns (bytes4);

    /**
        @dev Handles the receipt of a multiple ERC1155 token types. This function
        is called at the end of a `safeBatchTransferFrom` after the balances have
        been updated. To accept the transfer(s), this must return
        `bytes4(keccak256("onERC1155BatchReceived(address,address,uint256[],uint256[],bytes)"))`
        (i.e. 0xbc197c81, or its own function selector).
        @param operator The address which initiated the batch transfer (i.e. msg.sender)
        @param from The address which previously owned the token
        @param ids An array containing ids of each token being transferred (order and length must match values array)
        @param values An array containing amounts of each token being transferred (order and length must match ids array)
        @param data Additional data with no specified format
        @return `bytes4(keccak256("onERC1155BatchReceived(address,address,uint256[],uint256[],bytes)"))` if transfer is allowed
    */
    function onERC1155BatchReceived(
        address operator,
        address from,
        uint256[] calldata ids,
        uint256[] calldata values,
        bytes calldata data
    ) external returns (bytes4);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (token/ERC1155/extensions/IERC1155MetadataURI.sol)

pragma solidity ^0.8.0;

import "../IERC1155.sol";

/**
 * @dev Interface of the optional ERC1155MetadataExtension interface, as defined
 * in the https://eips.ethereum.org/EIPS/eip-1155#metadata-extensions[EIP].
 *
 * _Available since v3.1._
 */
interface IERC1155MetadataURI is IERC1155 {
    /**
     * @dev Returns the URI for token type `id`.
     *
     * If the `\{id\}` substring is present in the URI, it must be replaced by
     * clients with the actual token type ID.
     */
    function uri(uint256 id) external view returns (string memory);
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