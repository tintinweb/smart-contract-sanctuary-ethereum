/**
 *Submitted for verification at Etherscan.io on 2022-12-26
*/

// SPDX-License-Identifier: CC-BY-4.0
/*

░█▀▀░▀█▀░█░█░█▀▀░█▀▄░█░█░█▀▄░▀█▀░▀█▀░█▀▀░█▀▄
░█▀▀░░█░░█▀█░█▀▀░█▀▄░█▄█░█▀▄░░█░░░█░░█▀▀░█▀▄
░▀▀▀░░▀░░▀░▀░▀▀▀░▀░▀░▀░▀░▀░▀░▀▀▀░░▀░░▀▀▀░▀░▀

v1.0 - 2022

written by Ariel Sebastián Becker

NOTICE
======

This is a custom contract, tailored and pruned to fit Spurious Dragon's limit of 24,576 bytes.
Because of that, you will see some modifications made to third-party libraries such as OpenZeppelin's.
The reason behind that is I needed to accomodate a SVG generator complete with an embedded font and custom colors.

THIS SOFTWARE IS PROVIDED “AS IS”, WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE
WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT.

THE AUTHOR WILL NOT BE LIABLE, UNDER ANY CIRCUMSTANCE, FOR THE CONTENT STORED BY THE OWNERS.

*/

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
	bytes16 private constant _SYMBOLS = "0123456789abcdef";
	uint8 private constant _ADDRESS_LENGTH = 20;

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

	function toHexString(uint256 value, uint256 length) internal pure returns(string memory) {
		bytes memory buffer = new bytes(2 * length + 2);
		buffer[0] = "0";
		buffer[1] = "x";
		for (uint256 i = 2 * length + 1; i > 1; --i) {
			buffer[i] = _SYMBOLS[value & 0xf];
			value >>= 4;
		}

		return string(buffer);
	}

	function toHexString(address addr) internal pure returns(string memory) {
		return toHexString(uint256(uint160(addr)), _ADDRESS_LENGTH);
	}

	function stringLength(string memory s) internal pure returns(uint256) {
		return bytes(s).length;
	}
}

pragma solidity ^0.8.17;
abstract contract ERC165 is IERC165 {
	function supportsInterface(bytes4 interfaceId) public view virtual override returns(bool) {
		return interfaceId == type(IERC165).interfaceId;
	}
}

pragma solidity ^0.8.17;
contract ERC721 is Context, ERC165, IERC721 {
	using Address for address;
	using Strings for uint256;

	mapping(uint256 => address) private _owners;
	mapping(address => uint256) private _balances;
	mapping(uint256 => address) private _tokenApprovals;
	mapping(address => mapping(address => bool)) private _operatorApprovals;

	function supportsInterface(bytes4 interfaceId) public view virtual override(ERC165, IERC165) returns(bool) {
		return
		interfaceId == type(IERC721).interfaceId ||
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

	function _transfer(address from, address to, uint256 tokenId) internal virtual {
		require(ERC721.ownerOf(tokenId) == from, "Not authorized!");
		require(to != address(0), "Cannot transfer to zero addy!");
		require(to != address(0), "Cannot transfer to zero addy!");
		require(tokenId > 0, "Cannot transfer token 0!");
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
contract Ownable {
	string public constant NOT_CURRENT_OWNER = "018001";
	string public constant CANNOT_TRANSFER_TO_ZERO_ADDRESS = "018002";
	address public owner;
	event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

	constructor() {
		owner = msg.sender;
	}

	modifier onlyOwner() {
		require(msg.sender == owner, NOT_CURRENT_OWNER);
		_;
	}

	function transferOwnership(address _newOwner) public onlyOwner {
		require(_newOwner != address(0), CANNOT_TRANSFER_TO_ZERO_ADDRESS);
		emit OwnershipTransferred(owner, _newOwner);
		owner = _newOwner;
	}
}

pragma solidity ^0.8.17;
library Base64 {
	string internal constant _TABLE = "ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789+/";

	function encode(bytes memory data) internal pure returns(string memory) {
		if(data.length == 0) return "";
		string memory table = _TABLE;
		string memory result = new string(4 * ((data.length + 2) / 3));

		assembly {
			let tablePtr := add(table, 1)
			let resultPtr := add(result, 32)
			for {
				let dataPtr := data
				let endPtr := add(data, mload(data))
			} lt(dataPtr, endPtr) {

			} {
				dataPtr := add(dataPtr, 3)
				let input := mload(dataPtr)
				mstore8(resultPtr, mload(add(tablePtr, and(shr(18, input), 0x3F))))
				resultPtr := add(resultPtr, 1) // Advance
				mstore8(resultPtr, mload(add(tablePtr, and(shr(12, input), 0x3F))))
				resultPtr := add(resultPtr, 1) // Advance
				mstore8(resultPtr, mload(add(tablePtr, and(shr(6, input), 0x3F))))
				resultPtr := add(resultPtr, 1) // Advance
				mstore8(resultPtr, mload(add(tablePtr, and(input, 0x3F))))
				resultPtr := add(resultPtr, 1) // Advance
			}

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
contract Etherwriter is Context, ERC721 {
	struct Texts {
		string texta;
		string textb;
		string textc;
		string textd;
		string color;
	}

	bool private _paused = true;

	uint256 private _mintFee = 10000000000000000; //10000000000000000, 0.01 ETH
	uint256 private _mintedTokens = 0;
	uint256 private _maxCap = 10000; // 0 to 9999.
	address private _smartContractOwner = 0x4DaE7E6c0Ca196643012cDc526bBc6b445A2ca59;

	mapping(uint256 => Texts) private tokenData;

	string private _name = 'Etherwriter v1.1';
	string private _symbol = 'EWR1';
	string private _description = '140 characters of pure freedom.';
	string private _strWebsite = 'https://arielbecker.com/etherwriter/';
	string private _strCoverImage = string(abi.encodePacked(_strWebsite, 'logo.png'));
	string private _strPaused = "Contract is paused.";
	string private _strNotAuthorized = 'Not authorized!';
	string private _strNotEnoughETH = 'Not enough ETH!';
	string private _strTransferFailed = 'Transfer failed.';
	string private _strOutOfBounds = 'Out of bounds!';
	string private _strTextTooLong = 'Text too long!';
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

	string private _font = '@font-face{font-family:"Xe";font-style:normal;font-weight:400;font-stretch:100%;src:url(data:font/woff2;base64,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) format("woff2");unicode-range:U+0000-00FF,U+0131,U+0152-0153,U+02BB-02BC, U+02C6,U+02DA,U+02DC,U+2000-206F,U+2074,U+20AC,U+2122,U+2191,U+2193,U+2212,U+2215,U+FEFF,U+FFFD;}';

	event ChangedText(address indexed Owner, uint256 indexed tokenId, string firstLine, string secondLine, string thirdLine, string fourthLine);

	modifier onlyAdmin {
		require(_msgSender() == _smartContractOwner, _strNotAuthorized);
		_;
	}

	modifier onlyOwner(uint256 tokenId) {
		require(_msgSender() == ownerOf(tokenId), _strNotAuthorized);
		_;
	}

	constructor() ERC721() {
		_smartContractOwner = msg.sender;
	}

	// Aux internal functions

	function _createTextBlock(uint256 tokenId, uint256 level) private view returns(string memory) {
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
				'<text visibility="hidden" x="100" y="', Strings.toString(level), '90" font-family="Xe" font-size="40" fill="', tokenData[tokenId].color, '">',
				text
			)
		);
	}

	function _determineColor(uint256 _tokenId) private pure returns(string memory) {
		string memory _color = '#888888';
		if(_tokenId == 0) {
			// 1, token 0, electric pink, 0.01%, non-transferrable.
			_color = '#F9016A';
		}
		else if(_tokenId > 0 && _tokenId < 11) {
			// 10, 1 to 10, phosphor cerulean, 0.1%.
			_color = '#01B3F9';
		}
		else if(_tokenId > 10 && _tokenId < 111) {
			//100, 11 to 110, phosphor red, 1%.
			_color = '#FF1900';
		}
		else if(_tokenId > 110 && _tokenId < 1111) {
			//1000, 111 to 1110, phosphor green, 10%.
			_color = '#19FF00';
		}
		// 8889, 1111 to 9999, light gray, 88.89%.

		return _color;
	}

	function modifyTokenData(uint256 tokenId, string memory a, string memory b, string memory c, string memory d) private {
		require(Strings.stringLength(a) < 41, _strTextTooLong);
		require(Strings.stringLength(b) < 41, _strTextTooLong);
		require(Strings.stringLength(c) < 41, _strTextTooLong);
		require(Strings.stringLength(d) < 41, _strTextTooLong);

		tokenData[tokenId].texta = a;
		tokenData[tokenId].textb = b;
		tokenData[tokenId].textc = c;
		tokenData[tokenId].textd = d;
	}

	// Main public functions

	/// @dev Use this function to change the token's text.
	///	 Note: Only token's owner can change this.
	/// @param tokenId token ID.
	/// @param firstLine First line of text. Must be 40 characters or less.
	/// @param secondLine Second line of text. Must be 40 characters or less.
	/// @param thirdLine Third line of text. Must be 40 characters or less.
	/// @param fourthLine Fourth line of text. Must be 40 characters or less.
	function changeTokenText(uint256 tokenId, string memory firstLine, string memory secondLine, string memory thirdLine, string memory fourthLine) onlyOwner(tokenId) public {
		require(tokenId < _mintedTokens, _strOutOfBounds);
		modifyTokenData(tokenId, firstLine, secondLine, thirdLine, fourthLine);
		emit ChangedText(_msgSender(), tokenId, firstLine, secondLine, thirdLine, fourthLine);
	}

	/// @dev Changes the website URI.
	///	 Note: Only contract's owner can change this.
	/// @param _newWebsite New URI.
	function changeWebURI(string memory _newWebsite) onlyAdmin public {
		_strWebsite = _newWebsite;
	}

	/// @dev Returns the URI to the contract's JSON.
	///	 Note: can be a URL or a base64-encoded JSON.
	function contractURI() public view returns(string memory) {
		string memory _retValue = string(
			abi.encodePacked(
				'data:application/json;base64,',
				Base64.encode(abi.encodePacked(_strContractJSON))
			)
		);

		return _retValue;
	}

	/// @dev Creates a dynamic base-64 representation of a SMIL SVG containing the token's text.
	/// @param tokenId Token ID.
	function generateAnimation(uint256 tokenId) public view returns(string memory) {
		require(tokenId < _mintedTokens, _strOutOfBounds);
		bytes memory svg = abi.encodePacked(
			'<svg xmlns="http://www.w3.org/2000/svg" version="1.1" viewBox="0 0 1010 460" width="100%" height="100%" preserveAspectRatio="xMinYMin meet" style="background-color:#0A0A0A;"><style xmlns="http://www.w3.org/2000/svg" type="text/css">',
			_font,
			'</style>',
			_createTextBlock(tokenId, 0),
			'<set begin="1" to="visible" attributeType="auto" attributeName="visibility"></set></text>',
			_createTextBlock(tokenId, 1),
			'<set begin="mv2.end" to="visible" attributeType="auto" attributeName="visibility"></set><set begin="mv8.end" to="hidden" attributeType="auto" attributeName="visibility"></set></text>',
			_createTextBlock(tokenId, 2),
			'<set begin="mv4.end" to="visible" attributeType="auto" attributeName="visibility"></set><set begin="mv8.end" to="hidden" attributeType="auto" attributeName="visibility"></set></text>',
			_createTextBlock(tokenId, 3),
			'<set begin="mv6.end" to="visible" attributeType="auto" attributeName="visibility"></set><set begin="mv8.end" to="hidden" attributeType="auto" attributeName="visibility"></set></text><g><rect x="100" y="40" width="30" height="60" fill="', tokenData[tokenId].color, '"><animate id="bl1" begin="1; mv8.end" to="#0A0A0A" dur="0.5s" repeatCount="2" attributeType="auto" attributeName="fill"></animate><animate id="bl2" begin="mv1.end" to="#0A0A0A" dur="0.5s" repeatCount="2" attributeType="auto" attributeName="fill"></animate><animate id="bl3" begin="mv2.end" to="#0A0A0A" dur="0.5s" repeatCount="2" attributeType="auto" attributeName="fill"></animate><animate id="bl4" begin="mv3.end" to="#0A0A0A" dur="0.5s" repeatCount="2" attributeType="auto" attributeName="fill"></animate><animate id="bl5" begin="mv4.end" to="#0A0A0A" dur="0.5s" repeatCount="2" attributeType="auto" attributeName="fill"></animate><animate id="bl6" begin="mv5.end" to="#0A0A0A" dur="0.5s" repeatCount="2" attributeType="auto" attributeName="fill"></animate><animate id="bl7" begin="mv6.end" to="#0A0A0A" dur="0.5s" repeatCount="2" attributeType="auto" attributeName="fill"></animate><animate id="bl8" begin="mv7.end" to="#0A0A0A" dur="0.5s" repeatCount="10" attributeType="auto" attributeName="fill"></animate><set begin="mv2.begin" to="140" fill="freeze" attributeType="auto" attributeName="y"></set><set begin="mv4.begin" to="240" fill="freeze" attributeType="auto" attributeName="y"></set><set begin="mv6.begin" to="340" fill="freeze" attributeType="auto" attributeName="y"></set><set begin="mv8.begin" to="40" fill="freeze" attributeType="auto" attributeName="y"></set></rect><rect x="125" y="40" width="800" height="60" fill="#0A0A0A"><set begin="mv2.begin" to="140" fill="freeze" attributeType="auto" attributeName="y"></set><set begin="mv4.begin" to="240" fill="freeze" attributeType="auto" attributeName="y"></set><set begin="mv6.begin" to="340" fill="freeze" attributeType="auto" attributeName="y"></set><set begin="mv8.begin" to="40" fill="freeze" attributeType="auto" attributeName="y"></set></rect><animateTransform id="mv1" begin="bl1.end" attributeName="transform" type="translate" from="0,0" to="20,0" dur="0.05s" accumulate="sum" calcMode="discrete" repeatCount="',
			Strings.toString(Strings.stringLength(tokenData[tokenId].texta)),
			'" fill="freeze"></animateTransform><animateTransform id="mv2" begin="bl2.end" attributeName="transform" type="translate" from="456,0" to="0,0" dur="0.05s" fill="freeze"></animateTransform><animateTransform id="mv3" begin="bl3.end" attributeName="transform" type="translate" from="0,0" to="20,0" dur="0.05s" accumulate="sum" calcMode="discrete" repeatCount="',
			Strings.toString(Strings.stringLength(tokenData[tokenId].textb)),
			'" fill="freeze"></animateTransform><animateTransform id="mv4" begin="bl4.end" attributeName="transform" type="translate" from="456,0" to="0,0" dur="0.05s" fill="freeze"></animateTransform><animateTransform id="mv5" begin="bl5.end" attributeName="transform" type="translate" from="0,0" to="20,0" dur="0.05s" accumulate="sum" calcMode="discrete" repeatCount="',
			Strings.toString(Strings.stringLength(tokenData[tokenId].textc)),
			'" fill="freeze"></animateTransform><animateTransform id="mv6" begin="bl6.end" attributeName="transform" type="translate" from="456,0" to="0,0" dur="0.05s" fill="freeze"></animateTransform><animateTransform id="mv7" begin="bl7.end" attributeName="transform" type="translate" from="0,0" to="20,0" dur="0.05s" accumulate="sum" calcMode="discrete" repeatCount="',
			Strings.toString(Strings.stringLength(tokenData[tokenId].textd)),
			'" fill="freeze"></animateTransform><animateTransform id="mv8" begin="bl8.end" attributeName="transform" type="translate" from="456,0" to="0,0" dur="0.05s" fill="freeze"></animateTransform></g></svg>'
		);

		return string(
			abi.encodePacked(
				'data:image/svg+xml;base64,',
				Base64.encode(svg)
			)
		);
	}

	/// @dev Mints a new token with the specified lines of text.
	/// @param firstLine First line of text. Must be 40 characters or less.
	/// @param secondLine Second line of text. Must be 40 characters or less.
	/// @param thirdLine Third line of text. Must be 40 characters or less.
	/// @param fourthLine Fourth line of text. Must be 40 characters or less.
	function mint(string memory firstLine, string memory secondLine, string memory thirdLine, string memory fourthLine) public payable {
		uint256 index = _mintedTokens;
		require(!_paused, _strPaused);
		require(index >= 0, _strOutOfBounds);
		require(index < _maxCap, _strOutOfBounds);

		if(_msgSender() != _smartContractOwner) {
			require(msg.value >= _mintFee, _strNotEnoughETH);
		}

		modifyTokenData(index, firstLine, secondLine, thirdLine, fourthLine);
		tokenData[index].color = _determineColor(index);

		_mintedTokens++;
		_mint(_msgSender(), index);
	}

	/// @dev Returns the contract's name.
	function name() public view returns(string memory) {
		return _name;
	}

	/// @dev Pauses the contract.
	///	 Note: Only contract's owner can change this.
	function pause() onlyAdmin public {
		_paused = true;
	}

	/// @dev Returns the contract's symbol, or ticker.
	function symbol() public view returns(string memory) {
		return _symbol;
	}

	/// @dev Returns a base64-encoded JSON that describes the given tokenID
	/// @param tokenId Token ID.
	function tokenURI(uint256 tokenId) public view returns(string memory) {
		require(tokenId < _mintedTokens, _strOutOfBounds);
		return string(
			abi.encodePacked(
				'data:application/json;base64,',
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
						'"cover": "', _strCoverImage, '",',
						'"l1": "', tokenData[tokenId].texta, '",',
						'"l2": "', tokenData[tokenId].textb, '",',
						'"l3": "', tokenData[tokenId].textc, '",',
						'"l4": "', tokenData[tokenId].textd, '",',
						'"c": "', tokenData[tokenId].color, '"',
					'}'
				))
			)
		);
	}

	/// @dev Unpauses the contract.
	///	 Note: Only contract's owner can change this.
	function unpause() onlyAdmin public {
		_paused = false;
	}

	/// @dev Allows to withdraw any ETH available on this contract.
	///	 Note: Only contract's owner can withdraw.
	function withdraw() public onlyAdmin payable {
		uint balance = address(this).balance;
		require(balance > 0, _strNotEnoughETH);
		(bool success, ) = (_msgSender()).call{value: balance}("");
		require(success, _strTransferFailed);
	}
}