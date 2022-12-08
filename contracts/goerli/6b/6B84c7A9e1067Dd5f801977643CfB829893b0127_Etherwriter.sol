/**
 *Submitted for verification at Etherscan.io on 2022-12-07
*/

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.17;
interface IERC165 {
	function supportsInterface(bytes4 interfaceId) external view returns(bool);
}

pragma solidity ^0.8.17;
interface IERC721 is IERC165 {
	event Transfer(address indexed from, address indexed to, uint256 indexed tokenId);
	event Approval(address indexed owner, address indexed approved, uint256 indexed tokenId);
	event ApprovalForAll(address indexed owner, address indexed operator, bool approved);

	function balanceOf(address owner) external view returns(uint256 balance);
	function ownerOf(uint256 tokenId) external view returns(address owner);
	function safeTransferFrom(address from, address to, uint256 tokenId) external;
	function transferFrom(address from, address to, uint256 tokenId) external;
	function approve(address to, uint256 tokenId) external;
	function getApproved(uint256 tokenId) external view returns(address operator);
	function setApprovalForAll(address operator, bool _approved) external;
	function isApprovedForAll(address owner, address operator) external view returns(bool);
	function safeTransferFrom(address from, address to, uint256 tokenId, bytes calldata data) external;
}

pragma solidity ^0.8.17;
interface IERC721Receiver {
	function onERC721Received(address operator, address from, uint256 tokenId, bytes calldata data) external returns(bytes4);
}

pragma solidity ^0.8.17;
interface IERC721Metadata is IERC721 {
	function name() external view returns(string memory);
	function symbol() external view returns(string memory);
	function tokenURI(uint256 tokenId) external view returns(string memory);
}

pragma solidity ^0.8.17;
library Address {
	function isContract(address account) internal view returns(bool) {
		uint256 size;
		assembly {
			size := extcodesize(account)
		}
		return size > 0;
	}

	function sendValue(address payable recipient, uint256 amount) internal {
		require(address(this).balance >= amount, "Insufficient balance");
		(bool success, ) = recipient.call{value: amount}("");
		require(success, "Address: unable to send value, recipient may have reverted");
	}

	function functionCall(address target, bytes memory data) internal returns(bytes memory) {
		return functionCall(target, data, "Address: low-level call failed");
	}

	function functionCall(address target, bytes memory data, string memory errorMessage) internal returns(bytes memory) {
		return functionCallWithValue(target, data, 0, errorMessage);
	}

	function functionCallWithValue(address target, bytes memory data, uint256 value) internal returns(bytes memory) {
		return functionCallWithValue(target, data, value, "Address: low-level call with value failed");
	}

	function functionCallWithValue(address target, bytes memory data, uint256 value, string memory errorMessage) internal returns(bytes memory) {
		require(address(this).balance >= value, "Insufficient balance!");
		require(isContract(target), "Address: call to non-contract");
		(bool success, bytes memory returndata) = target.call{value: value}(data);
		return verifyCallResult(success, returndata, errorMessage);
	}

	function functionStaticCall(address target, bytes memory data) internal view returns(bytes memory) {
		return functionStaticCall(target, data, "Address: low-level static call failed");
	}

	function functionStaticCall( address target, bytes memory data, string memory errorMessage) internal view returns(bytes memory) {
		require(isContract(target), "Address: static call to non-contract");
		(bool success, bytes memory returndata) = target.staticcall(data);
		return verifyCallResult(success, returndata, errorMessage);
	}

	function functionDelegateCall(address target, bytes memory data) internal returns(bytes memory) {
		return functionDelegateCall(target, data, "Address: low-level delegate call failed");
	}

	function functionDelegateCall(address target, bytes memory data, string memory errorMessage) internal returns(bytes memory) {
		require(isContract(target), "Address: delegate call to non-contract");
		(bool success, bytes memory returndata) = target.delegatecall(data);
		return verifyCallResult(success, returndata, errorMessage);
	}

	function verifyCallResult(bool success, bytes memory returndata, string memory errorMessage) internal pure returns(bytes memory) {
		if(success) {
			return returndata;
		}
		else {
			if(returndata.length > 0) {
				assembly {
					let returndata_size := mload(returndata)
					revert(add(32, returndata), returndata_size)
				}
			}
			else {
				revert(errorMessage);
			}
		}
	}
}

pragma solidity ^0.8.17;
abstract contract Context {
	function _msgSender() internal view virtual returns(address) {
		return msg.sender;
	}

	function _msgData() internal view virtual returns(bytes calldata) {
		return msg.data;
	}
}

pragma solidity ^0.8.17;
library Strings {
	//bytes16 private constant _HEX_SYMBOLS = "0123456789abcdef";

	function toString(uint256 value) internal pure returns(string memory) {
		if(value == 0) {
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
}

pragma solidity ^0.8.17;
abstract contract ERC165 is IERC165 {
	function supportsInterface(bytes4 interfaceId) public view virtual override returns(bool) {
		return interfaceId == type(IERC165).interfaceId;
	}
}

pragma solidity ^0.8.17;
contract ERC721 is Context, ERC165, IERC721, IERC721Metadata {
	using Address for address;
	using Strings for uint256;

	string private _name;
	string private _symbol;
	string private _description;
	mapping(uint256 => address) private _owners;
	mapping(address => uint256) private _balances;
	mapping(uint256 => address) private _tokenApprovals;
	mapping(address => mapping(address => bool)) private _operatorApprovals;

	constructor(string memory name_, string memory symbol_, string memory description_) {
		//_name = name_;
		//_symbol = symbol_;
		//_description = description_;
	}

	function supportsInterface(bytes4 interfaceId) public view virtual override(ERC165, IERC165) returns(bool) {
		return
		interfaceId == type(IERC721).interfaceId ||
		interfaceId == type(IERC721Metadata).interfaceId ||
		super.supportsInterface(interfaceId);
	}

	function balanceOf(address owner) public view virtual override returns(uint256) {
		require(owner != address(0), "ERC721: balance query for the zero address");
		return _balances[owner];
	}

	function ownerOf(uint256 tokenId) public view virtual override returns(address) {
		address owner = _owners[tokenId];
		require(owner != address(0), "Not minted yet!");
		return owner;
	}

	function name() public view virtual override returns(string memory) {
		// Overriden
		return "";
	}

	function symbol() public view virtual override returns(string memory) {
		// Overriden
		return "";
	}

	function tokenURI(uint256 tokenId) public view virtual override returns(string memory) {}

	function _baseURI() internal view virtual returns(string memory) {
		// Overriden
		return "";
	}

	function approve(address to, uint256 tokenId) public virtual override {
		address owner = ERC721.ownerOf(tokenId);
		require(to != owner, "Not authorized!");
		require(
			_msgSender() == owner || isApprovedForAll(owner, _msgSender()),
				"Not authorized!"
		);
		_approve(to, tokenId);
	}

	function getApproved(uint256 tokenId) public view virtual override returns(address) {
		require(_exists(tokenId), "Nonexistent token!");
		return _tokenApprovals[tokenId];
	}

	function setApprovalForAll(address operator, bool approved) public virtual override {
		require(operator != _msgSender(), "ERC721: approve to caller");
		_operatorApprovals[_msgSender()][operator] = approved;
		emit ApprovalForAll(_msgSender(), operator, approved);
	}

	function isApprovedForAll(address owner, address operator) public view virtual override returns(bool) {
		return _operatorApprovals[owner][operator];
	}

	function transferFrom(address from, address to, uint256 tokenId) public virtual override {
		//solhint-disable-next-line max-line-length
		require(_isApprovedOrOwner(_msgSender(), tokenId), "Not authorized!");
		_transfer(from, to, tokenId);
	}

	function safeTransferFrom(address from, address to, uint256 tokenId) public virtual override {
		safeTransferFrom(from, to, tokenId, "");
	}

	function safeTransferFrom(address from, address to, uint256 tokenId, bytes memory _data) public virtual override {
		require(_isApprovedOrOwner(_msgSender(), tokenId), "Not authorized!");
		_safeTransfer(from, to, tokenId, _data);
	}

	function _safeTransfer(address from, address to, uint256 tokenId, bytes memory _data) internal virtual {
		_transfer(from, to, tokenId);
		require(_checkOnERC721Received(from, to, tokenId, _data), "Attempted transfer to non ERC721Receiver implementer!");
	}

	function _exists(uint256 tokenId) internal view virtual returns(bool) {
		return _owners[tokenId] != address(0);
	}

	function _isApprovedOrOwner(address spender, uint256 tokenId) internal view virtual returns(bool) {
		require(_exists(tokenId), "Token does not exist!");
		address owner = ERC721.ownerOf(tokenId);
		return (spender == owner || getApproved(tokenId) == spender || isApprovedForAll(owner, spender));
	}

	function _safeMint(address to, uint256 tokenId) internal virtual {
		_safeMint(to, tokenId, "");
	}

	function _safeMint(address to, uint256 tokenId, bytes memory _data) internal virtual {
		_mint(to, tokenId);
		require(
			_checkOnERC721Received(address(0), to, tokenId, _data),
				"ERC721: transfer to non ERC721Receiver implementer"
		);
	}

	function _mint(address to, uint256 tokenId) internal virtual {
		_balances[to] += 1;
		_owners[tokenId] = to;
		emit Transfer(address(0), to, tokenId);
	}

	function _burn(uint256 tokenId) internal virtual {
	}

	function _transfer(address from, address to, uint256 tokenId) internal virtual {
		require(ERC721.ownerOf(tokenId) == from, "Not authorized!");
		require(to != address(0), "Cannot transfer to zero addy!");
		require(to != address(0), "Cannot transfer to zero addy!");
		_approve(address(0), tokenId);
		_balances[from] -= 1;
		_balances[to] += 1;
		_owners[tokenId] = to;
		emit Transfer(from, to, tokenId);
	}

	function _approve(address to, uint256 tokenId) internal virtual {
		_tokenApprovals[tokenId] = to;
		emit Approval(ERC721.ownerOf(tokenId), to, tokenId);
	}

	function _checkOnERC721Received(address from, address to, uint256 tokenId, bytes memory _data) private returns(bool) {
		if(to.isContract()) {
			try IERC721Receiver(to).onERC721Received(_msgSender(), from, tokenId, _data) returns(bytes4 retval) {
				return retval == IERC721Receiver.onERC721Received.selector;
			} catch (bytes memory reason) {
				if(reason.length == 0) {
					revert("ERC721: transfer to non ERC721Receiver implementer");
				} else {
					assembly {
						revert(add(32, reason), mload(reason))
					}
				}
			}
		}
		else {
			return true;
		}
	}
}

pragma solidity ^0.8.17;
abstract contract ERC721Burnable is Context, ERC721 {
	function burn(uint256 tokenId) public virtual {
		//solhint-disable-next-line max-line-length
		require(tokenId != tokenId, "Disabled!");
	}
}

pragma solidity ^0.8.17;

/**
 * @dev The contract has an owner address, and provides basic authorization control whitch
 * simplifies the implementation of user permissions. This contract is based on the source code at:
 * https://github.com/OpenZeppelin/openzeppelin-solidity/blob/master/contracts/ownership/Ownable.sol
 */
contract Ownable {

	/**
	 * @dev Error constants.
	 */
	string public constant NOT_CURRENT_OWNER = "018001";
	string public constant CANNOT_TRANSFER_TO_ZERO_ADDRESS = "018002";

	/**
	 * @dev Current owner address.
	 */
	address public owner;

	/**
	 * @dev An event which is triggered when the owner is changed.
	 * @param previousOwner The address of the previous owner.
	 * @param newOwner The address of the new owner.
	 */
	event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

	/**
	 * @dev The constructor sets the original `owner` of the contract to the sender account.
	 */
	constructor() {
		owner = msg.sender;
	}

	/**
	 * @dev Throws if called by any account other than the owner.
	 */
	modifier onlyOwner() {
		require(msg.sender == owner, NOT_CURRENT_OWNER);
		_;
	}

	/**
	 * @dev Allows the current owner to transfer control of the contract to a newOwner.
	 * @param _newOwner The address to transfer ownership to.
	 */
	function transferOwnership(address _newOwner) public onlyOwner {
		require(_newOwner != address(0), CANNOT_TRANSFER_TO_ZERO_ADDRESS);
		emit OwnershipTransferred(owner, _newOwner);
		owner = _newOwner;
	}
}

// OpenZeppelin Contracts (last updated v4.7.0) (utils/Base64.sol)

pragma solidity ^0.8.17;

/**
 * @dev Provides a set of functions to operate with Base64 strings.
 *
 * _Available since v4.5._
 */

library Base64 {
	/**
	 * @dev Base64 Encoding/Decoding Table
	 */
	string internal constant _TABLE = "ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789+/";

	/**
	 * @dev Converts a `bytes` to its Bytes64 `string` representation.
	 */
	function encode(bytes memory data) internal pure returns (string memory) {
		/**
		 * Inspired by Brecht Devos (Brechtpd) implementation - MIT licence
		 * https://github.com/Brechtpd/base64/blob/e78d9fd951e7b0977ddca77d92dc85183770daf4/base64.sol
		 */
		if (data.length == 0) return "";

		// Loads the table into memory
		string memory table = _TABLE;

		// Encoding takes 3 bytes chunks of binary data from `bytes` data parameter
		// and split into 4 numbers of 6 bits.
		// The final Base64 length should be `bytes` data length multiplied by 4/3 rounded up
		// - `data.length + 2`  -> Round up
		// - `/ 3`			  -> Number of 3-bytes chunks
		// - `4 *`			  -> 4 characters for each chunk
		string memory result = new string(4 * ((data.length + 2) / 3));

		/// @solidity memory-safe-assembly
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

pragma solidity ^0.8.17;

contract Etherwriter is Context, ERC721Burnable {
	// leer https://docs.alchemy.com/docs/how-to-make-nfts-with-on-chain-metadata-hardhat-and-javascript
	//using SafeMath for uint256;

	struct Texts {
		string texta;
		string textb;
		string textc;
		string textd;
		string color;
	}

	uint256 private _mintFee = 250000000000000000; //0.25 ETH
	uint256 private _mintedTokens = 0;
	uint256 private _maxCap = 10000; // 0 to 9999.
	address private _smartContractOwner = 0x4DaE7E6c0Ca196643012cDc526bBc6b445A2ca59;
	mapping(uint256 => Texts) private tokenData;
	mapping(uint256 => address) private owners;
	string private _strSpace = " ";
	string private _name = "Etherwriter";
	string private _symbol = "EWR";
	string private _description = "140 characters of pure freedom.";
	string private _strWebsite = "https://arielbecker.com/etherwriter/";
	string private _strCoverImage = string(abi.encodePacked(_strWebsite, 'logo.png'));
	string private _strNotAuthorized = "Not authorized!";
	string private _strNotEnoughETH = "Not enough ETH!";
	string private _strTransferFailed = "Transfer failed.";
	string private _strAlreadyMinted = "Already minted!";
	string private _strOutOfBounds = "Overflow";
	string private _strTextTooLong = "Text too long!";
	string private _strb64HTML = "https://arielbecker.com/etherwriter/contract.json";
	string private _strContractJSON = string(abi.encodePacked(
		'{',
			'"name": "', _name, '",',
			'"description": "', _description, '",',
			'"image": "', _strCoverImage, '",',
			'"external_link": "', _strWebsite, '",',
			'"seller_fee_basis_points": 500,',
			'"fee_recipient": "0x4DaE7E6c0Ca196643012cDc526bBc6b445A2ca59"',
		'}'
	));
	string private _strForbidden = '<svg width="400" height="400" preserveAspectRatio="xMinYMin meet" viewBox="0 0 160 160" version="1.1" xmlns="http://www.w3.org/2000/svg" xmlns:svg="http://www.w3.org/2000/svg"><g style="display:inline" transform="scale(0.16)"><circle style="display:inline;fill:#ffffff" cx="500" cy="500" r="360" id="circle2" /><path style="fill:#aa0000" d="M 500,0 A 500,500 0 0 0 0,500 500,500 0 0 0 500,1000 500,500 0 0 0 1000,500 500,500 0 0 0 500,0 Z m 0,140 A 360,360 0 0 1 860,500 360,360 0 0 1 798.27148,699.27734 L 300.72266,201.72852 A 360,360 0 0 1 500,140 Z M 201.72852,300.72266 699.27734,798.27148 A 360,360 0 0 1 500,860 360,360 0 0 1 140,500 360,360 0 0 1 201.72852,300.72266 Z" id="path4" /></g></svg>';
	string private _font = "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";

	event ChangedText(address indexed Owner, uint256 indexed tokenId);

	constructor() ERC721("Etherwriter", "EWR", "Four lines, fourty characters each of censorship-resistant billboard.") {
		_smartContractOwner = msg.sender;
	}

	function _createTextBlock(uint256 tokenId, uint256 level) internal view returns(string memory) {
		string memory text = tokenData[tokenId].texta;
		if(level == 1) {
			text = tokenData[tokenId].textb;
		}
		if(level == 2) {
			text = tokenData[tokenId].textc;
		}
		else if(level == 3) {
			text = tokenData[tokenId].textd;
		}

		return string(
			abi.encodePacked(
				'<text id="t', Strings.toString(level), '" visibility="hidden" x="100" y="', Strings.toString(level), '90" font-family="Xe" font-size="40" fill="', tokenData[tokenId].color, '">',
				text
			)
		);
	}

	function _determineColor(uint256 _tokenId) internal pure returns(string memory) {
		// 1001 to 9999, light gray.
		string memory _color = "#888888";
		if(_tokenId == 0) {
			// 0, unique color, electric pale blue.
			_color = "#00A2FF";
		}
		else if(_tokenId > 0 && _tokenId < 11) {
			//1 to 10, phosphor blue.
			_color = "#003EFF";
		}
		else if(_tokenId > 10 && _tokenId < 51) {
			//11 to 50, phosphor red.
			_color = "#FF1900";
		}
		else if(_tokenId > 50 && _tokenId < 251) {
			//51 to 250, phosphor green.
			_color = "#19FF00";
		}
		else if(_tokenId > 250 && _tokenId < 1001) {
			// 251 to 1000, amber.
			_color = "#FFBF00";
		}

		return _color;
	}

	function modifyTokenData(uint256 tokenId, string memory a, string memory b, string memory c, string memory d) private {
		require(_stringLength(a) < 41, _strTextTooLong);
		require(_stringLength(b) < 41, _strTextTooLong);
		require(_stringLength(c) < 41, _strTextTooLong);
		require(_stringLength(d) < 41, _strTextTooLong);

		tokenData[tokenId].texta = a;
		tokenData[tokenId].textb = b;
		tokenData[tokenId].textc = c;
		tokenData[tokenId].textd = d;
	}

	// Aux internal functions
	function _stringLength(string memory s) internal pure returns(uint256) {
		return bytes(s).length;
	}

	// Main public functions

	/// @dev Changes the external_url parameter.
	///	  Note: Only contract's owner can change this.
	/// @param b64HTML URI to the external site, or base64-encoded html.
	function changeEmbeddedWeb(string memory b64HTML) public {
		require(msg.sender == _smartContractOwner, _strNotAuthorized);
		_strb64HTML = b64HTML;
	}

	/// @dev Use this function to change the token's text.
	///	  Note: Only token's owner can change this.
	/// @param tokenId token ID.
	/// @param firstLine First line of text. Must be 40 characters or less.
	/// @param secondLine Second line of text. Must be 40 characters or less.
	/// @param thirdLine Third line of text. Must be 40 characters or less.
	/// @param fourthLine Fourth line of text. Must be 40 characters or less.
	function changeText(uint256 tokenId, string memory firstLine, string memory secondLine, string memory thirdLine, string memory fourthLine) public {
		require(msg.sender == owners[tokenId], _strNotAuthorized);
		modifyTokenData(tokenId, firstLine, secondLine, thirdLine, fourthLine);

		emit ChangedText(msg.sender, tokenId);
	}

	/// @dev Returns the URI to the contract's JSON.
	///	  Note: can be a URL or a base64-encoded JSON.
	function contractURI() public view returns (string memory) {
		return _strb64HTML;
	}

	/// @dev Creates on-the-fly a base-64 representation of a SMIL SVG containing the text defined during minting.
	function generateAnimation(uint256 tokenId) public view returns(string memory) {
		bytes memory svg = abi.encodePacked(_strForbidden);
		if(tokenId < _mintedTokens) {
			svg = abi.encodePacked(
				'<svg width="100%" height="100%" preserveAspectRatio="xMinYMin meet" xmlns="http://www.w3.org/2000/svg" style="background-color:#0A0A0A;" viewBox="0 0 1010 460"><style xmlns="http://www.w3.org/2000/svg" type="text/css">@font-face {font-family: "Xe";font-style: normal;font-weight: 400;font-stretch: 100%;src: url(data:font/woff2;base64,',
				_font,
				') format("woff2");unicode-range: U+0000-00FF, U+0131, U+0152-0153, U+02BB-02BC, U+02C6, U+02DA, U+02DC, U+2000-206F, U+2074, U+20AC, U+2122, U+2191, U+2193, U+2212, U+2215, U+FEFF, U+FFFD;}</style>',
				_createTextBlock(tokenId, 0),
				'<set id="set21" begin="1" to="visible" attributeType="auto" attributeName="visibility"></set></text>',
				_createTextBlock(tokenId, 1),
				'<set id="set31" begin="mv2.end" to="visible" attributeType="auto" attributeName="visibility"></set><set id="set32" begin="mv8.end" to="hidden" attributeType="auto" attributeName="visibility"></set></text>',
				_createTextBlock(tokenId, 2),
				'<set id="set41" begin="mv4.end" to="visible" attributeType="auto" attributeName="visibility"></set><set id="set42" begin="mv8.end" to="hidden" attributeType="auto" attributeName="visibility"></set></text>',
				_createTextBlock(tokenId, 3),
				'<set id="set51" begin="mv6.end" to="visible" attributeType="auto" attributeName="visibility"></set><set id="set52" begin="mv8.end" to="hidden" attributeType="auto" attributeName="visibility"></set></text><g id="cursor"><rect x="100" y="40" width="30" height="60" fill="', tokenData[tokenId].color, '"><animate id="bl1" begin="1; mv8.end" to="#0A0A0A" dur="0.5s" repeatCount="5" attributeType="auto" attributeName="fill"></animate><animate id="bl2" begin="mv1.end" to="#0A0A0A" dur="0.5s" repeatCount="5" attributeType="auto" attributeName="fill"></animate><animate id="bl3" begin="mv2.end" to="#0A0A0A" dur="0.5s" repeatCount="5" attributeType="auto" attributeName="fill"></animate><animate id="bl4" begin="mv3.end" to="#0A0A0A" dur="0.5s" repeatCount="5" attributeType="auto" attributeName="fill"></animate><animate id="bl5" begin="mv4.end" to="#0A0A0A" dur="0.5s" repeatCount="5" attributeType="auto" attributeName="fill"></animate><animate id="bl6" begin="mv5.end" to="#0A0A0A" dur="0.5s" repeatCount="5" attributeType="auto" attributeName="fill"></animate><animate id="bl7" begin="mv6.end" to="#0A0A0A" dur="0.5s" repeatCount="5" attributeType="auto" attributeName="fill"></animate><animate id="bl8" begin="mv7.end" to="#0A0A0A" dur="0.5s" repeatCount="5" attributeType="auto" attributeName="fill"></animate><set id="set11" begin="mv2.begin" to="140" fill="freeze" attributeType="auto" attributeName="y"></set><set id="set12" begin="mv4.begin" to="240" fill="freeze" attributeType="auto" attributeName="y"></set><set id="set13" begin="mv6.begin" to="340" fill="freeze" attributeType="auto" attributeName="y"></set><set id="set14" begin="mv8.begin" to="40" fill="freeze" attributeType="auto" attributeName="y"></set></rect><rect x="125" y="40" width="800" height="60" fill="#0A0A0A"><set id="set21" begin="mv2.begin" to="140" fill="freeze" attributeType="auto" attributeName="y"></set><set id="set22" begin="mv4.begin" to="240" fill="freeze" attributeType="auto" attributeName="y"></set><set id="set23" begin="mv6.begin" to="340" fill="freeze" attributeType="auto" attributeName="y"></set><set id="set24" begin="mv8.begin" to="40" fill="freeze" attributeType="auto" attributeName="y"></set></rect><animateTransform id="mv1" begin="bl1.end" attributeName="transform" type="translate" from="0,0" to="20,0" dur="0.10s" accumulate="sum" calcMode="discrete" repeatCount="',
				Strings.toString(_stringLength(tokenData[tokenId].texta)),
				'" fill="freeze"></animateTransform><animateTransform id="mv2" begin="bl2.end" attributeName="transform" type="translate" from="456,0" to="0,0" dur="0.10s" fill="freeze"></animateTransform><animateTransform id="mv3" begin="bl3.end" attributeName="transform" type="translate" from="0,0" to="20,0" dur="0.10s" accumulate="sum" calcMode="discrete" repeatCount="',
				Strings.toString(_stringLength(tokenData[tokenId].textb)),
				'" fill="freeze"></animateTransform><animateTransform id="mv4" begin="bl4.end" attributeName="transform" type="translate" from="456,0" to="0,0" dur="0.10s" fill="freeze"></animateTransform><animateTransform id="mv5" begin="bl5.end" attributeName="transform" type="translate" from="0,0" to="20,0" dur="0.10s" accumulate="sum" calcMode="discrete" repeatCount="',
				Strings.toString(_stringLength(tokenData[tokenId].textc)),
				'" fill="freeze"></animateTransform><animateTransform id="mv6" begin="bl6.end" attributeName="transform" type="translate" from="456,0" to="0,0" dur="0.10s" fill="freeze"></animateTransform><animateTransform id="mv7" begin="bl7.end" attributeName="transform" type="translate" from="0,0" to="20,0" dur="0.10s" accumulate="sum" calcMode="discrete" repeatCount="',
				Strings.toString(_stringLength(tokenData[tokenId].textd)),
				'" fill="freeze"></animateTransform><animateTransform id="mv8" begin="bl8.end" attributeName="transform" type="translate" from="456,0" to="0,0" dur="0.10s" fill="freeze"></animateTransform></g></svg>'
			);
		}

		return string(
			abi.encodePacked(
				"data:image/svg+xml;base64,",
				Base64.encode(svg)
			)
		);
	}

	/// @dev Returns the amount of minted tokens so far.
	function getMintedTokens() public view returns (uint256) {
		return _mintedTokens;
	}

	/// @dev Mints a new token with the specified lines of text.
	/// @param firstLine First line of text. Must be 40 characters or less.
	/// @param secondLine Second line of text. Must be 40 characters or less.
	/// @param thirdLine Third line of text. Must be 40 characters or less.
	/// @param fourthLine Fourth line of text. Must be 40 characters or less.
	function mint(string memory firstLine, string memory secondLine, string memory thirdLine, string memory fourthLine) public payable {
		uint256 index = _mintedTokens;
		require(index >= 0, _strOutOfBounds);
		require(index < _maxCap, _strOutOfBounds);

		if(msg.sender != _smartContractOwner) {
			require(msg.value >= _mintFee, _strNotEnoughETH);
		}

		modifyTokenData(index, firstLine, secondLine, thirdLine, fourthLine);
		tokenData[index].color = _determineColor(index);

		_mintedTokens++;
		owners[index] = msg.sender;
		_mint(msg.sender, index);
	}

	/// @dev Use this function to change the mint fee.
	///	  Note: Only the contract's owner can change this.
	/// @param _newMintFee New mint fee in wei.
	function setMintFee(uint256 _newMintFee) public {
		require(msg.sender == _smartContractOwner, _strNotAuthorized);
		_mintFee = _newMintFee;
	}

	/// @dev Returns a base64-encoded JSON that describes the given tokenID
	/// @param tokenId Token ID.
	function tokenURI(uint256 tokenId) public view override returns(string memory) {
		return string(
			abi.encodePacked(
				"data:application/json;base64,",
				Base64.encode(abi.encodePacked(
					'{',
						'"name": "Etherwriter #', Strings.toString(tokenId), '",',
						'"description": "', _description, '",',
						'"attributes": [',
							'{',
								'"trait_type": "Color", ',
								'"value": "', tokenData[tokenId].color, '"',
							'}',
						'],',
						'"animation_url": "', generateAnimation(tokenId), '",',
						'"cover": "', _strCoverImage, '"',
					'}'
				))
			)
		);
	}

	/// @dev Allows to withdraw any ETH available on this contract.
	///	  Note: Only contract's owner can withdraw.
	function withdraw() public payable {
		require(msg.sender == _smartContractOwner, _strNotAuthorized);
		uint balance = address(this).balance;
		require(balance > 0, _strNotEnoughETH);
		(bool success, ) = (msg.sender).call{value: balance}("");
		require(success, _strTransferFailed);
	}
}