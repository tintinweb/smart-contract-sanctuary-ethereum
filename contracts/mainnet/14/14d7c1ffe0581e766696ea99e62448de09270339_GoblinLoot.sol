/**
 *Submitted for verification at Etherscan.io on 2022-05-27
*/

// SPDX-License-Identifier: CC0-1.0
//
//
//
//
// oooOooooo looka fren wats dis... shIneez?
// YUMMZ many manY shineEz, deez mine now teeheeE
// wat? wat it is?
//
// AAAAAAAUUUUUGGGHHHHH shineez on da blokcHin?
// waaaaaaaaitttt you wan sum?
// okieee fren, u use how uuu want teeheeE...
//
//
//     _,   _,  __  ,  ___,,  , ,    _,  _,  ___,
//    / _  / \,'|_) | ' |  |\ | |   / \,/ \,' |
//   '\_|`'\_/ _|_)'|___|_,|'\|'|__'\_/'\_/   |
//     _|  '  '       '    '  `   ' '   '     '
//    '      '      '            '          '
//
//               _    |.-""-.)    /\
//              | \   /   .= \)  /  \
//              |  \ / =. --  \ /  ) |   '
//     '        \ ( \   o\/0   /     /
//               \_, '- /   \   ,___/
//                 /    \__ /    \
//                 \, ___/\___,  /    '
//          '       \  ----     /            '
//                   \         /
//      '             '--___--'
//                       [ ]             '
//              '       { }
//                       [ ]    '             '
//         '            { }
//                       [ ]           '
//
//
//
// iNspired bY gObLiNtOwn, the lOOt pRojecT, sEttLementS...
//
// a Cc0 pRojeCt frOm imp0ster, zhOug & jAytHin stAyTHin...
//
//          ...enJoy... teEEhheeeEEEe...
//
//
//
//

// File: @openzeppelin/contracts/utils/Base64.sol

// OpenZeppelin Contracts (last updated v4.5.0) (utils/Base64.sol)

pragma solidity ^0.8.0;

/**
 * @dev Provides a set of functions to operate with Base64 strings.
 *
 * _Available since v4.5._
 */
library Base64 {
	/**
	 * @dev Base64 Encoding/Decoding Table
	 */
	string internal constant _TABLE =
		'ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789+/';

	/**
	 * @dev Converts a `bytes` to its Bytes64 `string` representation.
	 */
	function encode(bytes memory data) internal pure returns (string memory) {
		/**
		 * Inspired by Brecht Devos (Brechtpd) implementation - MIT licence
		 * https://github.com/Brechtpd/base64/blob/e78d9fd951e7b0977ddca77d92dc85183770daf4/base64.sol
		 */
		if (data.length == 0) return '';

		// Loads the table into memory
		string memory table = _TABLE;

		// Encoding takes 3 bytes chunks of binary data from `bytes` data parameter
		// and split into 4 numbers of 6 bits.
		// The final Base64 length should be `bytes` data length multiplied by 4/3 rounded up
		// - `data.length + 2`  -> Round up
		// - `/ 3`              -> Number of 3-bytes chunks
		// - `4 *`              -> 4 characters for each chunk
		string memory result = new string(4 * ((data.length + 2) / 3));

		assembly {
			// Prepare the lookup table (skip the first "length" byte)
			let tablePtr := add(table, 1)

			// Prepare result pointer, jump over length
			let resultPtr := add(result, 32)

			// Run over the input, 3 bytes at a time
			for {
				let dataPtr := data
				let endPtr := add(data, mload(data))
			} lt(dataPtr, endPtr) {

			} {
				// Advance 3 bytes
				dataPtr := add(dataPtr, 3)
				let input := mload(dataPtr)

				// To write each character, shift the 3 bytes (18 bits) chunk
				// 4 times in blocks of 6 bits for each character (18, 12, 6, 0)
				// and apply logical AND with 0x3F which is the number of
				// the previous character in the ASCII table prior to the Base64 Table
				// The result is then added to the table to get the character to write,
				// and finally write it in the result pointer but with a left shift
				// of 256 (1 byte) - 8 (1 ASCII char) = 248 bits

				mstore8(resultPtr, mload(add(tablePtr, and(shr(18, input), 0x3F))))
				resultPtr := add(resultPtr, 1) // Advance

				mstore8(resultPtr, mload(add(tablePtr, and(shr(12, input), 0x3F))))
				resultPtr := add(resultPtr, 1) // Advance

				mstore8(resultPtr, mload(add(tablePtr, and(shr(6, input), 0x3F))))
				resultPtr := add(resultPtr, 1) // Advance

				mstore8(resultPtr, mload(add(tablePtr, and(input, 0x3F))))
				resultPtr := add(resultPtr, 1) // Advance
			}

			// When data `bytes` is not exactly 3 bytes long
			// it is padded with `=` characters at the end
			switch mod(mload(data), 3)
			case 1 {
				mstore8(sub(resultPtr, 1), 0x3d)
				mstore8(sub(resultPtr, 2), 0x3d)
			}
			case 2 {
				mstore8(sub(resultPtr, 1), 0x3d)
			}
		}

		return result;
	}
}

// File: @openzeppelin/contracts/utils/Strings.sol

// OpenZeppelin Contracts v4.4.1 (utils/Strings.sol)

pragma solidity ^0.8.0;

/**
 * @dev String operations.
 */
library Strings {
	bytes16 private constant _HEX_SYMBOLS = '0123456789abcdef';

	/**
	 * @dev Converts a `uint256` to its ASCII `string` decimal representation.
	 */
	function toString(uint256 value) internal pure returns (string memory) {
		// Inspired by OraclizeAPI's implementation - MIT licence
		// https://github.com/oraclize/ethereum-api/blob/b42146b063c7d6ee1358846c198246239e9360e8/oraclizeAPI_0.4.25.sol

		if (value == 0) {
			return '0';
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
			return '0x00';
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
	function toHexString(uint256 value, uint256 length)
		internal
		pure
		returns (string memory)
	{
		bytes memory buffer = new bytes(2 * length + 2);
		buffer[0] = '0';
		buffer[1] = 'x';
		for (uint256 i = 2 * length + 1; i > 1; --i) {
			buffer[i] = _HEX_SYMBOLS[value & 0xf];
			value >>= 4;
		}
		require(value == 0, 'Strings: hex length insufficient');
		return string(buffer);
	}
}

// File: @rari-capital/solmate/src/tokens/ERC721.sol

pragma solidity >=0.8.0;

/// @notice Modern, minimalist, and gas efficient ERC-721 implementation.
/// @author Solmate (https://github.com/Rari-Capital/solmate/blob/main/src/tokens/ERC721.sol)
abstract contract ERC721 {
	/*//////////////////////////////////////////////////////////////
                                 EVENTS
    //////////////////////////////////////////////////////////////*/

	event Transfer(address indexed from, address indexed to, uint256 indexed id);

	event Approval(
		address indexed owner,
		address indexed spender,
		uint256 indexed id
	);

	event ApprovalForAll(
		address indexed owner,
		address indexed operator,
		bool approved
	);

	/*//////////////////////////////////////////////////////////////
                         METADATA STORAGE/LOGIC
    //////////////////////////////////////////////////////////////*/

	string public name;

	string public symbol;

	function tokenURI(uint256 id) public view virtual returns (string memory);

	/*//////////////////////////////////////////////////////////////
                      ERC721 BALANCE/OWNER STORAGE
    //////////////////////////////////////////////////////////////*/

	mapping(uint256 => address) internal _ownerOf;

	mapping(address => uint256) internal _balanceOf;

	function ownerOf(uint256 id) public view virtual returns (address owner) {
		require((owner = _ownerOf[id]) != address(0), 'NOT_MINTED');
	}

	function balanceOf(address owner) public view virtual returns (uint256) {
		require(owner != address(0), 'ZERO_ADDRESS');

		return _balanceOf[owner];
	}

	/*//////////////////////////////////////////////////////////////
                         ERC721 APPROVAL STORAGE
    //////////////////////////////////////////////////////////////*/

	mapping(uint256 => address) public getApproved;

	mapping(address => mapping(address => bool)) public isApprovedForAll;

	/*//////////////////////////////////////////////////////////////
                               CONSTRUCTOR
    //////////////////////////////////////////////////////////////*/

	constructor(string memory _name, string memory _symbol) {
		name = _name;
		symbol = _symbol;
	}

	/*//////////////////////////////////////////////////////////////
                              ERC721 LOGIC
    //////////////////////////////////////////////////////////////*/

	function approve(address spender, uint256 id) public virtual {
		address owner = _ownerOf[id];

		require(
			msg.sender == owner || isApprovedForAll[owner][msg.sender],
			'NOT_AUTHORIZED'
		);

		getApproved[id] = spender;

		emit Approval(owner, spender, id);
	}

	function setApprovalForAll(address operator, bool approved) public virtual {
		isApprovedForAll[msg.sender][operator] = approved;

		emit ApprovalForAll(msg.sender, operator, approved);
	}

	function transferFrom(
		address from,
		address to,
		uint256 id
	) public virtual {
		require(from == _ownerOf[id], 'WRONG_FROM');

		require(to != address(0), 'INVALID_RECIPIENT');

		require(
			msg.sender == from ||
				isApprovedForAll[from][msg.sender] ||
				msg.sender == getApproved[id],
			'NOT_AUTHORIZED'
		);

		// Underflow of the sender's balance is impossible because we check for
		// ownership above and the recipient's balance can't realistically overflow.
		unchecked {
			_balanceOf[from]--;

			_balanceOf[to]++;
		}

		_ownerOf[id] = to;

		delete getApproved[id];

		emit Transfer(from, to, id);
	}

	function safeTransferFrom(
		address from,
		address to,
		uint256 id
	) public virtual {
		transferFrom(from, to, id);

		require(
			to.code.length == 0 ||
				ERC721TokenReceiver(to).onERC721Received(msg.sender, from, id, '') ==
				ERC721TokenReceiver.onERC721Received.selector,
			'UNSAFE_RECIPIENT'
		);
	}

	function safeTransferFrom(
		address from,
		address to,
		uint256 id,
		bytes calldata data
	) public virtual {
		transferFrom(from, to, id);

		require(
			to.code.length == 0 ||
				ERC721TokenReceiver(to).onERC721Received(msg.sender, from, id, data) ==
				ERC721TokenReceiver.onERC721Received.selector,
			'UNSAFE_RECIPIENT'
		);
	}

	/*//////////////////////////////////////////////////////////////
                              ERC165 LOGIC
    //////////////////////////////////////////////////////////////*/

	function supportsInterface(bytes4 interfaceId)
		public
		view
		virtual
		returns (bool)
	{
		return
			interfaceId == 0x01ffc9a7 || // ERC165 Interface ID for ERC165
			interfaceId == 0x80ac58cd || // ERC165 Interface ID for ERC721
			interfaceId == 0x5b5e139f; // ERC165 Interface ID for ERC721Metadata
	}

	/*//////////////////////////////////////////////////////////////
                        INTERNAL MINT/BURN LOGIC
    //////////////////////////////////////////////////////////////*/

	function _mint(address to, uint256 id) internal virtual {
		require(to != address(0), 'INVALID_RECIPIENT');

		require(_ownerOf[id] == address(0), 'ALREADY_MINTED');

		// Counter overflow is incredibly unrealistic.
		unchecked {
			_balanceOf[to]++;
		}

		_ownerOf[id] = to;

		emit Transfer(address(0), to, id);
	}

	function _burn(uint256 id) internal virtual {
		address owner = _ownerOf[id];

		require(owner != address(0), 'NOT_MINTED');

		// Ownership check above ensures no underflow.
		unchecked {
			_balanceOf[owner]--;
		}

		delete _ownerOf[id];

		delete getApproved[id];

		emit Transfer(owner, address(0), id);
	}

	/*//////////////////////////////////////////////////////////////
                        INTERNAL SAFE MINT LOGIC
    //////////////////////////////////////////////////////////////*/

	function _safeMint(address to, uint256 id) internal virtual {
		_mint(to, id);

		require(
			to.code.length == 0 ||
				ERC721TokenReceiver(to).onERC721Received(
					msg.sender,
					address(0),
					id,
					''
				) ==
				ERC721TokenReceiver.onERC721Received.selector,
			'UNSAFE_RECIPIENT'
		);
	}

	function _safeMint(
		address to,
		uint256 id,
		bytes memory data
	) internal virtual {
		_mint(to, id);

		require(
			to.code.length == 0 ||
				ERC721TokenReceiver(to).onERC721Received(
					msg.sender,
					address(0),
					id,
					data
				) ==
				ERC721TokenReceiver.onERC721Received.selector,
			'UNSAFE_RECIPIENT'
		);
	}
}

/// @notice A generic interface for a contract which properly accepts ERC721 tokens.
/// @author Solmate (https://github.com/Rari-Capital/solmate/blob/main/src/tokens/ERC721.sol)
abstract contract ERC721TokenReceiver {
	function onERC721Received(
		address,
		address,
		uint256,
		bytes calldata
	) external virtual returns (bytes4) {
		return ERC721TokenReceiver.onERC721Received.selector;
	}
}

// File: contracts/GoblinLoot.sol

pragma solidity ^0.8.0;

contract GoblinLoot is ERC721 {
	using Strings for uint256;

	uint256 public constant MAX_SUPPLY = 5000;
	uint256 public constant MINT_DURATION = 48 hours;
	uint256 public totalSupply;
	uint256 public mintClosingTime;
	bool public mintIsActive;
	address public tipWithdrawer;

	address private imp0ster = 0x023006cED81c7Bf6D17A5bC1e1B40104114d0019;
	address private zhoug = 0xc99547f73B0Aa2C69E56849e8986137776D72474;

	// -------------------------------------------------------------------------------------------------- kOonstrukktorr
	constructor() ERC721('GoblinLoot', 'gObLooT') {
		tipWithdrawer = msg.sender;
		mintClosingTime = block.timestamp + MINT_DURATION;
		mintIsActive = true;
		_batchMint(imp0ster, 50);
		_batchMint(zhoug, 50);
	}

	// -------------------------------------------------------------------------------------------------- sLott KeYsss
	uint256 internal constant SLOT_WEAP = 1;
	uint256 internal constant SLOT_HEAD = 2;
	uint256 internal constant SLOT_BODY = 3;
	uint256 internal constant SLOT_HAND = 4;
	uint256 internal constant SLOT_FOOT = 5;
	uint256 internal constant SLOT_NECK = 6;
	uint256 internal constant SLOT_RING = 7;
	uint256 internal constant SLOT_TRI1 = 8;
	uint256 internal constant SLOT_TRI2 = 9;

	// -------------------------------------------------------------------------------------------------- matEriallss
	string[] internal heavyMaterials = [
		'bone',
		'stone',
		'bronze',
		'wood',
		'rubber',
		'iron',
		'gold',
		'copper',
		'tin',
		'goblinsteel',
		'scrap'
	];

	string[] internal lightMaterials = [
		'linen',
		'fur',
		'leather',
		'bark',
		'cotton',
		'cardboard',
		'hide',
		'scrap',
		'burlap',
		'goblinmail',
		'paper',
		'snakeskin '
	];

	// -------------------------------------------------------------------------------------------------- iTEMs
	string[] internal weapons = [
		'club',
		'scythe',
		'hammer',
		'sickle',
		'longspear',
		'shortspear',
		'staff',
		'slingshot',
		'shortbow',
		'longbow',
		'mace',
		'dagger',
		'totem',
		'wand',
		'pickaxe',
		'hatchet',
		'maul',
		'knife'
	];

	string[] internal headGear = [
		'cap',
		'hood',
		'helmet',
		'crown',
		'earring',
		'top hat',
		'bonnet',
		'kettle',
		'pot lid',
		'goggles',
		'monocle',
		'bowler',
		'eyepatch'
	];

	string[] internal bodyGear = [
		'husk',
		'cloak',
		'pads',
		'pauldrons',
		'waistcoat',
		'loincloth',
		'trousers',
		'robe',
		'rags',
		'harness',
		'tunic',
		'wrappings',
		'cuirass',
		'crop top',
		'sash',
		'toga',
		'belt',
		'vest',
		'cape'
	];

	string[] internal handGear = [
		'hooks',
		'gloves',
		'bracers',
		'gauntlets',
		'bangles',
		'knuckleguards',
		'bracelets',
		'claws',
		'handwraps',
		'mittens',
		'wristbands',
		'talons'
	];

	string[] internal footGear = [
		'sandals',
		'boots',
		'footwraps',
		'greaves',
		'anklets',
		'shackles',
		'booties',
		'socks',
		'shinguards',
		'toe rings',
		'slippers',
		'shoes',
		'clogs'
	];

	string[] internal necklaces = [
		'chain',
		'amulet',
		'locket',
		'pendant',
		'choker'
	];

	string[] internal rings = [
		'gold ring',
		'silver ring',
		'bronze ring',
		'iron ring'
	];

	string[] internal trinkets1 = [
		'pipe',
		'sundial',
		'clock',
		'bellows',
		'brush',
		'comb',
		'candle',
		'candlestick',
		'torch',
		'scratcher',
		'gaslamp',
		'shoehorn',
		'dice',
		'spoon',
		'periscope',
		'spyglass',
		'lute',
		'drum',
		'tamborine',
		'whistle',
		'pocketwatch',
		'compass',
		'whip'
	];

	string[] internal trinkets2 = [
		'potato',
		'pickle',
		'ruby',
		'herb pouch',
		'tooth',
		'jawbone',
		'dandelions',
		'sapphire',
		'diamond',
		'mushroom',
		'emerald',
		'sardines',
		'sulfur',
		'seeds',
		'beans',
		'quicksilver',
		'skull',
		'blueberries',
		'egg',
		'meat',
		'oil',
		'chalk',
		'charcoal',
		'twigs',
		'sweets',
		'amethyst',
		'obsidian',
		'pebbles',
		'goo',
		'rose',
		'seaweed',
		'feathers'
	];

	string[] internal trinkets3 = [
		'sailcloth',
		'cog',
		'rope',
		'vial',
		'flask',
		'jar',
		'gasket',
		'shears',
		'nails',
		'screws',
		'thread',
		'sewing needle',
		'mallet',
		'fishing rod',
		'grindstone',
		'bowl',
		'paintbrush',
		'scroll',
		'scraper',
		'???',
		'grappling hook',
		'sand',
		'stein',
		'teapot',
		'wineskin'
	];

	// -------------------------------------------------------------------------------------------------- preEefiX aN SUFfixxx
	string[] internal jewelryPrefixes = [
		'crude',
		'flawed',
		'rusty',
		'perfect',
		'fine',
		'flawless',
		'noble',
		'embossed',
		'tainted',
		'chipped',
		'worn',
		'sooty',
		'stolen'
	];

	string[] internal prefixes = [
		'sparkling',
		'shiny',
		'slick',
		'glowing',
		'polished',
		'damp',
		'blighty',
		'bloody',
		'thorny',
		'doomed',
		'gloomy',
		'grim',
		'makeshift',
		'noxious',
		'hairy',
		'mossy',
		'stinky',
		'dusty',
		'charred',
		'spiky',
		'cursed',
		'scaly',
		'crusty',
		'damned',
		'briny',
		'dirty',
		'slimy',
		'muddy',
		'lucky',
		"artificer's",
		"wayfarer's",
		"thief's",
		"captain's",
		"henchman's",
		"daredevil's",
		"bandit's",
		"inspector's",
		"raider's",
		"miner's",
		"builder's"
	];

	string[] internal suffixes = [
		'of RRRAAAAAHHH',
		'of AAAUUUGGHHH',
		'of power',
		'of sneak',
		'of strike',
		'of smite',
		'of charm',
		'of trade',
		'of anger',
		'of rage',
		'of fury',
		'of ash',
		'of fear',
		'of havoc',
		'of rapture',
		'of terror',
		'of the cliffs',
		'of the swamp',
		'of the bog',
		'of the rift',
		'of the sewers',
		'of the woods',
		'of the caves',
		'of the grave'
	];

	// -------------------------------------------------------------------------------------------------- eRRorzZ aaN modIffieerss
	error MintInactive();
	error NotEnoughLoot();
	error NotAuthorized();
	error NotMinted();

	modifier mintControl() {
		_;
		if (totalSupply == MAX_SUPPLY || block.timestamp > mintClosingTime) {
			mintIsActive = false;
		}
	}

	// -------------------------------------------------------------------------------------------------- wRiTez
	function _batchMint(address _recipient, uint256 _amount) private {
		unchecked {
			for (uint256 i = 1; i < _amount + 1; ++i) {
				_safeMint(_recipient, totalSupply + i);
			}
			totalSupply += _amount;
		}
	}

	function mint() public mintControl {
		if (!mintIsActive) revert MintInactive();
		if (totalSupply == MAX_SUPPLY) revert NotEnoughLoot();
		unchecked {
			++totalSupply;
		}
		_safeMint(msg.sender, totalSupply);
	}

	function mintThreeWithATip() public payable mintControl {
		if (!mintIsActive) revert MintInactive();
		if (totalSupply + 3 > MAX_SUPPLY) revert NotEnoughLoot();
		if (msg.value <= 0) revert NotAuthorized();
		_batchMint(msg.sender, 3);
	}

	function burn(uint256 _tokenId) public {
		if (
			msg.sender != address(_ownerOf[_tokenId]) ||
			isApprovedForAll[_ownerOf[_tokenId]][msg.sender]
		) revert NotAuthorized();
		_burn(_tokenId);
	}

	function updateTipWithdrawer(address _newWithdrawer) public {
		if (msg.sender != tipWithdrawer) revert NotAuthorized();
		tipWithdrawer = _newWithdrawer;
	}

	function withdrawTips() external payable {
		if (msg.sender != tipWithdrawer) revert NotAuthorized();
		(bool os, ) = payable(tipWithdrawer).call{value: address(this).balance}('');
		require(os);
	}

	// -------------------------------------------------------------------------------------------------- rEEdz
	function isHeavyMaterial(uint256 _key) internal pure returns (bool) {
		return (_key == SLOT_WEAP || _key == SLOT_HEAD || _key == SLOT_HAND);
	}

	function isLightMaterial(uint256 _key) internal pure returns (bool) {
		return (_key == SLOT_BODY || _key == SLOT_FOOT);
	}

	function isTrinket(uint256 _key) internal pure returns (bool) {
		return (_key == SLOT_TRI1 || _key == SLOT_TRI2);
	}

	function isJewelry(uint256 _key) internal pure returns (bool) {
		return (_key == SLOT_NECK || _key == SLOT_RING);
	}

	function random(uint256 _seedOne, uint256 _seedTwo)
		internal
		pure
		returns (uint256)
	{
		return
			uint256(
				keccak256(
					abi.encodePacked('AUuuU', _seedOne, 'UuUu', _seedTwo, 'uUgHH')
				)
			);
	}

	function join(string memory _itemOne, string memory _itemTwo)
		internal
		pure
		returns (string memory)
	{
		return string(abi.encodePacked(_itemOne, ' ', _itemTwo));
	}

	function pluck(
		uint256 _tokenId,
		uint256 _slotKey,
		string[] memory _sourceArray
	) internal view returns (string memory) {
		uint256 rand = random(_tokenId, _slotKey);
		uint256 AUUUGH = rand % 69;
		string memory output = _sourceArray[rand % _sourceArray.length];

		if (isHeavyMaterial(_slotKey)) {
			output = join(heavyMaterials[rand % heavyMaterials.length], output);
		}

		if (isLightMaterial(_slotKey)) {
			output = join(lightMaterials[rand % lightMaterials.length], output);
		}

		if (isJewelry(_slotKey)) {
			output = join(jewelryPrefixes[rand % jewelryPrefixes.length], output);
		}

		// no prefix or suffix
		if (AUUUGH < 23 || isTrinket(_slotKey)) {
			return output;
		}

		// both prefix & suffix
		if (AUUUGH > 55) {
			// if jewelry, apply only the suffix
			if (isJewelry(_slotKey)) {
				return join(output, suffixes[rand % suffixes.length]);
			}

			return
				join(
					join(prefixes[rand % prefixes.length], output),
					suffixes[rand % suffixes.length]
				);
		}

		// prefix only
		if (AUUUGH > 40 && !isJewelry(_slotKey)) {
			return join(prefixes[rand % prefixes.length], output);
		}

		// suffix only
		return join(output, suffixes[rand % suffixes.length]);
	}

	function getWeapon(uint256 _tokenId) public view returns (string memory) {
		return pluck(_tokenId, SLOT_WEAP, weapons);
	}

	function getHead(uint256 _tokenId) public view returns (string memory) {
		return pluck(_tokenId, SLOT_HEAD, headGear);
	}

	function getBody(uint256 _tokenId) public view returns (string memory) {
		return pluck(_tokenId, SLOT_BODY, bodyGear);
	}

	function getHand(uint256 _tokenId) public view returns (string memory) {
		return pluck(_tokenId, SLOT_HAND, handGear);
	}

	function getFoot(uint256 _tokenId) public view returns (string memory) {
		return pluck(_tokenId, SLOT_FOOT, footGear);
	}

	function getNeck(uint256 _tokenId) public view returns (string memory) {
		return pluck(_tokenId, SLOT_NECK, necklaces);
	}

	function getRing(uint256 _tokenId) public view returns (string memory) {
		return pluck(_tokenId, SLOT_RING, rings);
	}

	function getTrinket1(uint256 _tokenId) public view returns (string memory) {
		return pluck(_tokenId, SLOT_TRI1, trinkets1);
	}

	function getTrinket2(uint256 _tokenId) public view returns (string memory) {
		return pluck(_tokenId, SLOT_TRI2, trinkets2);
	}

	function getTrinket3(uint256 _tokenId) public view returns (string memory) {
		return pluck(_tokenId, SLOT_TRI2, trinkets3);
	}

	function getShinee(uint256 _tokenId) public pure returns (uint256) {
		return (random(_tokenId, 420) % 10) + 1;
	}

	function buildSVG(uint256 _tokenId) internal view returns (string memory) {
		string[24] memory parts;
		parts[
			0
		] = '<svg xmlns="http://www.w3.org/2000/svg" preserveAspectRatio="xMinYMin meet" viewBox="0 0 350 350"><style>.base { fill: #AFB886; font-family: monospace; font-size: 16px; letter-spacing: -0.05em; }</style><rect width="100%" height="100%" fill="#242910" /><text x="10" y="20" class="base">';
		parts[1] = getWeapon(_tokenId);
		parts[2] = '</text><text x="10" y="40" class="base">';
		parts[3] = getHead(_tokenId);
		parts[4] = '</text><text x="10" y="60" class="base">';
		parts[5] = getBody(_tokenId);
		parts[6] = '</text><text x="10" y="80" class="base">';
		parts[7] = getHand(_tokenId);
		parts[8] = '</text><text x="10" y="100" class="base">';
		parts[9] = getFoot(_tokenId);
		parts[10] = '</text><text x="10" y="120" class="base">';
		parts[11] = getNeck(_tokenId);
		parts[12] = '</text><text x="10" y="140" class="base">';
		parts[13] = getRing(_tokenId);
		parts[14] = '</text><text x="10" y="160" class="base">';
		parts[15] = getTrinket1(_tokenId);
		parts[16] = '</text><text x="10" y="180" class="base">';
		parts[17] = getTrinket2(_tokenId);
		parts[18] = '</text><text x="10" y="200" class="base">';
		parts[19] = getTrinket3(_tokenId);
		parts[
			20
		] = '</text><text x="10" y="220" class="base">---------------------';
		parts[21] = '</text><text x="10" y="240" class="base">';
		parts[22] = Strings.toString(getShinee(_tokenId));
		parts[23] = ' shinee</text></svg>';

		string memory svg = string(
			abi.encodePacked(
				parts[0],
				parts[1],
				parts[2],
				parts[3],
				parts[4],
				parts[5],
				parts[6],
				parts[7],
				parts[8]
			)
		);
		svg = string(
			abi.encodePacked(
				svg,
				parts[9],
				parts[10],
				parts[11],
				parts[12],
				parts[13],
				parts[14],
				parts[15],
				parts[16]
			)
		);
		return
			string(
				abi.encodePacked(
					svg,
					parts[17],
					parts[18],
					parts[19],
					parts[20],
					parts[21],
					parts[22],
					parts[23]
				)
			);
	}

	function buildAttr(string memory _traitType, string memory _value)
		internal
		pure
		returns (string memory)
	{
		return
			string(
				abi.encodePacked(
					'{"trait_type": "',
					_traitType,
					'", "value": "',
					_value,
					'"},'
				)
			);
	}

	function buildAttrList(uint256 _tokenId)
		internal
		view
		returns (string memory)
	{
		string[12] memory parts;
		parts[0] = '[';
		parts[1] = buildAttr('weapon', getWeapon(_tokenId));
		parts[2] = buildAttr('head', getHead(_tokenId));
		parts[3] = buildAttr('body', getBody(_tokenId));
		parts[4] = buildAttr('hand', getHand(_tokenId));
		parts[5] = buildAttr('foot', getFoot(_tokenId));
		parts[6] = buildAttr('neck', getNeck(_tokenId));
		parts[7] = buildAttr('ring', getRing(_tokenId));
		parts[8] = buildAttr('trinket_one', getTrinket1(_tokenId));
		parts[9] = buildAttr('trinket_two', getTrinket2(_tokenId));
		parts[10] = buildAttr('trinket_three', getTrinket3(_tokenId));
		parts[11] = string(
			abi.encodePacked(
				'{"trait_type": "shinee", "value": ',
				Strings.toString(getShinee(_tokenId)),
				', "max_value": 10}]'
			)
		);

		string memory output = string(
			abi.encodePacked(
				parts[0],
				parts[1],
				parts[2],
				parts[3],
				parts[4],
				parts[5],
				parts[6],
				parts[7],
				parts[8]
			)
		);

		return string(abi.encodePacked(output, parts[9], parts[10], parts[11]));
	}

	function tokenURI(uint256 _tokenId)
		public
		view
		override
		returns (string memory)
	{
		if (_ownerOf[_tokenId] == address(0)) revert NotMinted();

		string memory json = Base64.encode(
			bytes(
				string(
					abi.encodePacked(
						'{"name": "sack #',
						Strings.toString(_tokenId),
						'", "description": "oooOooooo looka fren wats dis... shIneez?\\nYUMMZ\\n\\nmany manY shineEz, deez mine now teeheeE\\n\\nwat? wat it is?\\nAAAAAAAUUUUUGGGHHHHH shineez on da blokcHin?\\n\\nwaaaaaaaaitttt you wan sum?\\nokieee fren, u use how uuu want teeheeE", "image": "data:image/svg+xml;base64,',
						Base64.encode(bytes(buildSVG(_tokenId))),
						'", "attributes": ',
						buildAttrList(_tokenId),
						'}'
					)
				)
			)
		);

		string memory output = string(
			abi.encodePacked('data:application/json;base64,', json)
		);
		return output;
	}

	function getSacksOwned(address _address)
		public
		view
		returns (uint256[] memory ownedIds)
	{
		uint256 balance = _balanceOf[_address];
		uint256 idCounter = 1;
		uint256 ownedCounter = 0;
		ownedIds = new uint256[](balance);

		while (ownedCounter < balance && idCounter < MAX_SUPPLY + 1) {
			address ownerAddress = _ownerOf[idCounter];
			if (ownerAddress == _address) {
				ownedIds[ownedCounter] = idCounter;
				ownedCounter++;
			}
			idCounter++;
		}
	}
}