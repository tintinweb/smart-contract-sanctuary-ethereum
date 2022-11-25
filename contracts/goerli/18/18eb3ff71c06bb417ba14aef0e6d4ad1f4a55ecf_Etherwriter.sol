/**
 *Submitted for verification at Etherscan.io on 2022-11-25
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

	function tokenURI(uint256 tokenId) public view virtual override returns(string memory) {
		//Overriden
		return "";
	}

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
	uint256 private _maxCap = 160;
	address private _smartContractOwner = 0x4DaE7E6c0Ca196643012cDc526bBc6b445A2ca59;
	mapping(uint256 => Texts) private tokenData;
	mapping(uint256 => address) private owners;
	string private _name = "ETHWRITER";
	string private _symbol = "ETHWRITER";
	string private _description = "Four lines, fourty characters each of censorship-resistant microblogging.";
	string private _strWebsite = "https://arielbecker.com/etherwriter/";
	string private _strNotAuthorized = "Not authorized!";
	string private _strNotEnoughETH = "Not enough ETH!";
	string private _strTransferFailed = "Transfer failed.";
	string private _strAlreadyMinted = "Already minted!";
	string private _strOutOfBounds = "Overflow";
	string private _strContractJSON = string(
		abi.encodePacked(
			'{',
				'"name": "Etherwriter",',
				'"description": "',  _description, '",',
				'"image": "', _strWebsite, '/cover.png",',
				'"external_link": "', _strWebsite, '",',
				'"seller_fee_basis_points": 500,',
				'"fee_recipient": "', _smartContractOwner, '"',
			'}'
		)
	);
	string private _font = "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";

	constructor() ERC721("ETHWRITER", "ETHWRITER", "Freedom!") {
		_smartContractOwner = msg.sender;
	}

	// Aux internal functions
	function _stringLength(string memory s) internal pure returns(uint256) {
		return bytes(s).length;
	}

	function _determineColor(uint256 _tokenId) private pure returns(string memory) {
		string memory color = "#333";
		if(_tokenId > 99 && _tokenId < 150) {
			color = "#345434";
		}
		else if(_tokenId > 149 && _tokenId < 161) {
			color = "#442487";
		}

		return color;
	}

	function _createTextBlock(uint256 tokenId, uint256 level) internal view returns(string memory) {
		string memory text = tokenData[tokenId].texta;
		string memory visibility = '';
		if(level > 0) {
			visibility = 'visibility="hidden"';
		}
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
				'<text id="t', (level + 1), '" ', visibility, ' x="100" y="', level, '90" font-family="Xe" font-size="40" fill="', tokenData[tokenId].color, '">',
				text
			)
		);
	}

	// Main public functions
	function generateAnimation(uint256 tokenId) public view returns(string memory) {
		bytes memory svg = abi.encodePacked(
			'<svg xmlns="http://www.w3.org/2000/svg" width="1084" height="400">',
			'<defs>',
			'<style type="text/css">',
			'@font-face {',
				'font-family: "Xe";',
				'src: url("data:application/x-font-ttf;base64,',
			_font,
			'");',
			'}',
			'</style>',
			'</defs>',
			_createTextBlock(tokenId, 0),
			'</text>',
			_createTextBlock(tokenId, 1),
			'<set id="s31" begin="m2e" to="visible" attributeType="auto" attributeName="visibility"></set>',
			'<set id="s32" begin="m8e" to="hidden" attributeType="auto" attributeName="visibility"></set>',
			'</text>',
			_createTextBlock(tokenId, 2),
			'<set id="s41" begin="m4e" to="visible" attributeType="auto" attributeName="visibility"></set>',
			'<set id="s42" begin="m8e" to="hidden" attributeType="auto" attributeName="visibility"></set>',
			'</text>',
			_createTextBlock(tokenId, 3),
			'<set id="s51" begin="m6e" to="visible" attributeType="auto" attributeName="visibility"></set>',
			'<set id="s52" begin="m8e" to="hidden" attributeType="auto" attributeName="visibility"></set>',
			'</text>',
			'<g id="cursor">',
			'<rect x="100" y="40" width="23.5" height="60" fill="#333">',
			'<animate id="bl1" begin="1; m8e" to="#AAA" dur="0.5s" repeatCount="5" attributeType="auto" attributeName="fill"></animate>',
			'<animate id="bl2" begin="m1.end" to="#AAA" dur="0.5s" repeatCount="5" attributeType="auto" attributeName="fill"></animate>',
			'<animate id="bl3" begin="m2e" to="#AAA" dur="0.5s" repeatCount="5" attributeType="auto" attributeName="fill"></animate>',
			'<animate id="bl4" begin="m3e" to="#AAA" dur="0.5s" repeatCount="5" attributeType="auto" attributeName="fill"></animate>',
			'<animate id="bl5" begin="m4e" to="#AAA" dur="0.5s" repeatCount="5" attributeType="auto" attributeName="fill"></animate>',
			'<animate id="bl6" begin="m5e" to="#AAA" dur="0.5s" repeatCount="5" attributeType="auto" attributeName="fill"></animate>',
			'<animate id="bl7" begin="m6e" to="#AAA" dur="0.5s" repeatCount="5" attributeType="auto" attributeName="fill"></animate>',
			'<animate id="bl8" begin="m7e" to="#AAA" dur="0.5s" repeatCount="5" attributeType="auto" attributeName="fill"></animate>',
			'<set id="s11" begin="m2b" to="140" fill="freeze" attributeType="auto" attributeName="y"></set>',
			'<set id="s12" begin="m4b" to="240" fill="freeze" attributeType="auto" attributeName="y"></set>',
			'<set id="s13" begin="m6b" to="340" fill="freeze" attributeType="auto" attributeName="y"></set>',
			'<set id="s14" begin="m8b" to="40" fill="freeze" attributeType="auto" attributeName="y"></set>',
			'</rect>',
			'<rect x="125" y="40" width="1000" height="60" fill="#FFF">',
			'<set id="s21" begin="m2b" to="140" fill="freeze" attributeType="auto" attributeName="y"></set>',
			'<set id="s22" begin="m4b" to="240" fill="freeze" attributeType="auto" attributeName="y"></set>',
			'<set id="s23" begin="m6b" to="340" fill="freeze" attributeType="auto" attributeName="y"></set>',
			'<set id="s24" begin="m8b" to="40" fill="freeze" attributeType="auto" attributeName="y"></set>',
			'</rect>',
			'<animateTransform id="m1" begin="x1e" attributeName="transform" type="translate" from="0,0" to="23.5,0" dur="0.50s" accumulate="sum" calcMode="discrete" repeatCount="',
			_stringLength(tokenData[tokenId].texta),
			'" fill="freeze"></animateTransform>',
			'<animateTransform id="m2" begin="x2e" attributeName="transform" type="translate" from="456,0" to="0,0" dur="0.10s" fill="freeze"></animateTransform>',
			'<animateTransform id="m3" begin="x3e" attributeName="transform" type="translate" from="0,0" to="23.5,0" dur="0.250s" accumulate="sum" calcMode="discrete" repeatCount="',
			_stringLength(tokenData[tokenId].textb),
			'" fill="freeze"></animateTransform>',
			'<animateTransform id="m4" begin="x4e" attributeName="transform" type="translate" from="456,0" to="0,0" dur="0.10s" fill="freeze"></animateTransform>',
			'<animateTransform id="m5" begin="x5e" attributeName="transform" type="translate" from="0,0" to="23.5,0" dur="0.250s" accumulate="sum" calcMode="discrete" repeatCount="',
			_stringLength(tokenData[tokenId].textc),
			'" fill="freeze"></animateTransform>',
			'<animateTransform id="m6" begin="x6e" attributeName="transform" type="translate" from="456,0" to="0,0" dur="0.10s" fill="freeze"></animateTransform>',
			'<animateTransform id="m7" begin="x7e" attributeName="transform" type="translate" from="0,0" to="23.5,0" dur="0.250s" accumulate="sum" calcMode="discrete" repeatCount="',
			_stringLength(tokenData[tokenId].textd),
			'" fill="freeze"></animateTransform>',
			'<animateTransform id="m8" begin="x8e" attributeName="transform" type="translate" from="456,0" to="0,0" dur="0.10s" fill="freeze"></animateTransform>',
			'</g>',
			'</svg>'
		);

		return string(
			abi.encodePacked(
				"data:image/svg+xml;base64,",
				Base64.encode(svg)
			)
		);
	}

	function getTokenURI(uint256 tokenId) public view returns(string memory) {
		bytes memory dataURI = abi.encodePacked(
			'{',
				'"name": "Etherwriter #', Strings.toString(tokenId), '",',
				'"description":', _description, '",',
				'"background_color": "FFFFFF"',
				'"attributes": [',
					'{',
						'"trait_type": "Color", ',
						'"value": "#333"',
					'},',
				'],',
				'"image_data": "', generateAnimation(tokenId), '"',
			'}'
		);

		return string(
			abi.encodePacked(
				"data:application/json;base64,",
				Base64.encode(dataURI)
			)
		);
	}

	function contractURI() public view returns (string memory) {
		return string(
			abi.encodePacked(
				"data:application/json;base64,",
				Base64.encode(
					abi.encodePacked(
						_strContractJSON
					)
				)
			)
		);
    }

	function mint(string memory firstLine, string memory secondLine, string memory thirdLine, string memory fourthLine) public payable {
		uint index = _mintedTokens;
		require(index >= 0, _strOutOfBounds);
		require(index < _maxCap, _strOutOfBounds);

		if(msg.sender != _smartContractOwner) {
			require(msg.value >= _mintFee, _strNotEnoughETH);
		}

		tokenData[index].texta = firstLine;
		tokenData[index].textb = secondLine;
		tokenData[index].textc = thirdLine;
		tokenData[index].textd = fourthLine;
		tokenData[index].color = _determineColor(index);

		_mintedTokens++;
		owners[index] = msg.sender;
		_mint(msg.sender, index);
	}

	function changeText(uint256 tokenId, string memory a, string memory b, string memory c, string memory d) public {
		require(msg.sender == owners[tokenId], _strNotAuthorized);
		tokenData[tokenId].texta = a;
		tokenData[tokenId].textb = b;
		tokenData[tokenId].textc = c;
		tokenData[tokenId].textd = d;
	}

	/// @dev Allows to withdraw any ETH available on this contract.
	///      Note: Only the contract's owner can withdraw.
	function withdraw() public payable {
		require(msg.sender == _smartContractOwner, _strNotAuthorized);
		uint balance = address(this).balance;
		require(balance > 0, _strNotEnoughETH);
		(bool success, ) = (msg.sender).call{value: balance}("");
		require(success, _strTransferFailed);
	}
}