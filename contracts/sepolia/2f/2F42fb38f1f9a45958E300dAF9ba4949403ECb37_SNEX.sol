/**
 *Submitted for verification at Etherscan.io on 2023-06-09
*/

// SPDX-License-Identifier: CC-BY-4.0
/*
▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄
██░▄▄▄░██░▀██░██░▄▄▄█▄▀█▀▄██
██▄▄▄▀▀██░█░█░██░▄▄▄███░████
██░▀▀▀░██░██▄░██░▀▀▀█▀▄█▄▀██
▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀

v1.0 - 2023

written by Ariel Sebastián Becker

NOTICE
======

This is a custom contract, tailored and pruned to fit Spurious Dragon's limit of 24,576 bytes.
Because of that, you will see some modifications made to third-party libraries such as OpenZeppelin's.

THIS SOFTWARE IS PROVIDED “AS IS”, WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE
WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT.

*/
pragma solidity ^0.8.17;

string constant _strReverted = "Unable to send value; recipient may have reverted!";
string constant _strLowCallFailed = "Address: low-level call failed.";
string constant _strNonContract = "Address: call to non-contract.";
string constant _strDelegateCallFailed = "Address: low-level delegate call failed.";
string constant _strDelegateCallNonContract = "Address: low-level delegate call to non-contract.";
string constant _strBalanceZeroAddy = "Balance query for the zero address.";
string constant _strTransferZeroAddy = "Cannot transfer to the zero address!";
string constant _strNotAuthorized = "Not authorized!";
string constant _strTransferFailed = "Transfer failed.";
string constant _strOutOfBounds = "Out of bounds!";
string constant _strPaused = "Contract is paused.";
string constant _strNotEnoughBalance = "Insufficient balance!";
string constant _strTransferToNon721 = "Attempted transfer to non ERC721Receiver implementer!";
string constant _strTokenName = "SNEX v1.0";
string constant _strTokenDescription = "Lorem ipsum dolor sit amet";
string constant _strTokenTicker = "SNEX";
string constant _strContractOwner = "0x4DaE7E6c0Ca196643012cDc526bBc6b445A2ca59";
string constant _strFrozen = "Contract is frozen.";

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
		require(address(this).balance >= amount, _strNotEnoughBalance);
		(bool success, ) = recipient.call{value: amount}("");
		require(success, _strReverted);
	}

	function functionCall(address target, bytes memory data) internal returns(bytes memory) {
		return functionCall(target, data, _strLowCallFailed);
	}

	function functionCall(address target, bytes memory data, string memory errorMessage) internal returns(bytes memory) {
		return functionCallWithValue(target, data, 0, errorMessage);
	}

	function functionCallWithValue(address target, bytes memory data, uint256 value) internal returns(bytes memory) {
		return functionCallWithValue(target, data, value, _strLowCallFailed);
	}

	function functionCallWithValue(address target, bytes memory data, uint256 value, string memory errorMessage) internal returns(bytes memory) {
		require(address(this).balance >= value, _strNotEnoughBalance);
		require(isContract(target), _strNonContract);
		(bool success, bytes memory returndata) = target.call{value: value}(data);
		return verifyCallResult(success, returndata, errorMessage);
	}

	function functionStaticCall(address target, bytes memory data) internal view returns(bytes memory) {
		return functionStaticCall(target, data, _strLowCallFailed);
	}

	function functionStaticCall( address target, bytes memory data, string memory errorMessage) internal view returns(bytes memory) {
		require(isContract(target), _strNonContract);
		(bool success, bytes memory returndata) = target.staticcall(data);
		return verifyCallResult(success, returndata, errorMessage);
	}

	function functionDelegateCall(address target, bytes memory data) internal returns(bytes memory) {
		return functionDelegateCall(target, data, _strDelegateCallFailed);
	}

	function functionDelegateCall(address target, bytes memory data, string memory errorMessage) internal returns(bytes memory) {
		require(isContract(target), _strDelegateCallNonContract);
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
		for(uint256 i = 2 * length + 1; i > 1; --i) {
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
		require(owner != address(0), _strBalanceZeroAddy);
		return _balances[owner];
	}

	function ownerOf(uint256 tokenId) public view virtual override returns(address) {
		address owner = _owners[tokenId];
		require(owner != address(0), "Not minted yet!");
		return owner;
	}

	function approve(address to, uint256 tokenId) public virtual override {
		address owner = ERC721.ownerOf(tokenId);
		require(to != owner, _strNotAuthorized);
		require(
			_msgSender() == owner || isApprovedForAll(owner, _msgSender()),
				_strNotAuthorized
		);
		_approve(to, tokenId);
	}

	function getApproved(uint256 tokenId) public view virtual override returns(address) {
		require(_exists(tokenId), _strOutOfBounds);
		return _tokenApprovals[tokenId];
	}

	function setApprovalForAll(address operator, bool approved) public virtual override {
		require(operator != _msgSender(), _strNotAuthorized);
		_operatorApprovals[_msgSender()][operator] = approved;
		emit ApprovalForAll(_msgSender(), operator, approved);
	}

	function isApprovedForAll(address owner, address operator) public view virtual override returns(bool) {
		return _operatorApprovals[owner][operator];
	}

	function transferFrom(address from, address to, uint256 tokenId) public virtual override {
		require(_isApprovedOrOwner(_msgSender(), tokenId), _strNotAuthorized);
		_transfer(from, to, tokenId);
	}

	function safeTransferFrom(address from, address to, uint256 tokenId) public virtual override {
		safeTransferFrom(from, to, tokenId, "");
	}

	function safeTransferFrom(address from, address to, uint256 tokenId, bytes memory _data) public virtual override {
		require(_isApprovedOrOwner(_msgSender(), tokenId), _strNotAuthorized);
		_safeTransfer(from, to, tokenId, _data);
	}

	function _safeTransfer(address from, address to, uint256 tokenId, bytes memory _data) internal virtual {
		_transfer(from, to, tokenId);
		require(_checkOnERC721Received(from, to, tokenId, _data), _strTransferToNon721);
	}

	function _exists(uint256 tokenId) internal view virtual returns(bool) {
		return _owners[tokenId] != address(0);
	}

	function _isApprovedOrOwner(address spender, uint256 tokenId) internal view virtual returns(bool) {
		require(_exists(tokenId), _strOutOfBounds);
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
				_strTransferToNon721
		);
	}

	function _mint(address to, uint256 tokenId) internal virtual {
		require(!_exists(tokenId), _strOutOfBounds);
		_balances[to] += 1;
		_owners[tokenId] = to;
		emit Transfer(address(0), to, tokenId);
	}

	function _transfer(address from, address to, uint256 tokenId) internal virtual {
		require(ERC721.ownerOf(tokenId) == from, _strNotAuthorized);
		require(to != address(0), _strTransferZeroAddy);
		require(_exists(tokenId), _strOutOfBounds);
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
					revert(_strTransferToNon721);
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
contract SNEX is Context, ERC721 {
	bool private _paused = false;
	bool private _frozen = false;

	uint256 private _mintFee = 50000000000000000; //50000000000000000, 0.05 ETH
	uint256 private _mintedTokens = 0;
	uint256 private _maxCap = 5; // ToDo: change it back to 5000.
	uint256 private _sellerFeePoints = 500; //5%

	address private _contractOwner = 0x4DaE7E6c0Ca196643012cDc526bBc6b445A2ca59;

	string private _strBaseURI = 'https://arielbecker.com/SNEX/'; // TEMPORARY, PLEASE CHANGE BEFORE PRODUCTION.
	string private _strCoverImage = string(abi.encodePacked(_strBaseURI, 'snex.png'));
	string private _strJSONURI = 'https://arielbecker.com/etc/snex/colors.json?r=121';
	string private _strScript = '';
	string private _strContractJSON = string(abi.encodePacked(
		'{',
			'"name": "', _strTokenName, '",',
			'"description": "', _strTokenDescription, '",',
			'"symbol": "', _strTokenTicker, '",',
			'"image": "', _strCoverImage, '",',
			'"external_link": "', _strBaseURI, '",',
			'"seller_fee_basis_points": "', Strings.toString(_sellerFeePoints),'",',
			'"fee_recipient": "', _strContractOwner, '"'
		'}'
	));

	string[27] private _strPalette = ["#00a5e3","#8dd7bf","#ff96c5","#ff5768","#ffbf65","#fc6238","#ffd872","#f2d4cc","#e77577","#6c88c4","#c05780","#ff828b","#e7c582","#00b0ba","#0065a2","#00cdac","#ff6f68","#ffdacc","#ff60a8","#cff800","#ff5c77","#4dd091","#ffec59","#ffa23a","#74737a","#ffffff","#292929"];

	struct TokenProperties {
		uint256 rarity;
		uint256[] tokenColors;
	}

	mapping(uint => TokenProperties) private tokenData;

	modifier onlyAdmin {
		require(_msgSender() == _contractOwner, _strNotAuthorized);
		_;
	}

	modifier insideBounds(uint256 tokenId) {
		require(tokenId > 0, _strOutOfBounds);
		require(tokenId <= _mintedTokens, _strOutOfBounds);
		_;
	}

	constructor() ERC721() {
	}

	// Aux internal functions

	function _ownerBalance(uint256 tokenId) internal view returns(uint256) {
		address owner = ownerOf(tokenId);
		return owner.balance;
	}

	function _rarity(uint256 _index) internal view returns(string memory) {
		string memory retValue = '';
		if(_index == 1) {
			retValue = "common-black";
		}
		else if(_index == 2) {
			retValue = "common-white";
		}
		else if(_index == 3) {
			retValue = "common-black-common-black";
		}
		else if(_index == 6) {
			retValue = "common-white-common-white";
		}
		else if(_index == 6) {
			retValue = "common-common";
		}
		else if(_index == 6) {
			retValue = "common-common-common-common";
		}

		return retValue;
	}

	function _buildArrayHexTriplet(uint256 tokenId) internal view returns(string memory) {
		string memory _retValue = "[";
		uint _length = tokenData[tokenId].tokenColors.length;

		for(uint i = 1; i < _length; i++) {
			_retValue = string(abi.encodePacked(_retValue, _strPalette[tokenData[tokenId].tokenColors[i]]));
			if(i < _length - 1) {
				_retValue = string(abi.encodePacked(_retValue, ","));
			}
		}
		_retValue = string(abi.encodePacked(_retValue, "]"));

		return _retValue;
	}

	// Main public functions

	/// @dev Changes the website URI.
	///	 Note: Only contract's owner can change this.
	/// @param _newURI New URI.
	function changeWebURI(string memory _newURI) onlyAdmin public {
		_strBaseURI = _newURI;
	}

	/// @dev Reveals the traits of the given tokens.
	///	 Note: Only contract's owner can use this function.
	/// @param _tokenRarity Rarity expressed as an index, array.
	/// @param _colorList List containing array of colors for each token.
	/// @param _initialToken First token number to be revealed.
	/// @param _finalToken Last token number to be revealed.
	function reveal(uint256[] memory _tokenRarity, uint256[][] memory _colorList, uint256 _initialToken, uint256 _finalToken) onlyAdmin public {
		require(!_frozen, _strFrozen);
		require(_initialToken > 0, _strOutOfBounds);
		require(_finalToken <= _mintedTokens, _strOutOfBounds);
		for(uint i = _initialToken; i <= _finalToken ; i++) {
			tokenData[i].rarity = _tokenRarity[i - 1];
			tokenData[i].tokenColors = _colorList[i - 1];
		}
	}

	/// @dev Changes the JSON URI.
	///	 Note: Only contract's owner can change this.
	function Freeze() onlyAdmin public {
		require(!_frozen, _strFrozen);
		_frozen = true;
	}

	/// @dev Changes the javascript content.
	///	 Note: Only contract's owner can change this.
	/// @param _newScript JS script.
	function changeJS(string memory _newScript) onlyAdmin public {
		require(!_frozen, _strFrozen);
		_strScript = _newScript;
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
	function generateHTML(uint256 tokenId) insideBounds(tokenId) public view returns(string memory) {
		bytes memory html = abi.encodePacked(
			'<!DOCTYPE html><html><head><meta charset="UTF-8" /><style>body{margin: 0;}canvas{background:#000;display:block;}</style></head><body><canvas id="snex"></canvas><script>const tokenId=', Strings.toString(tokenId),';let minimum=5;let balance=', Strings.toString(_ownerBalance(tokenId)),';if(balance==0){minimum=0}let snakeLength=Math.floor(balance/1000000000000000000)+minimum;if(snakeLength>9995){snakeLength=9995}const tokenColors="', _buildArrayHexTriplet(tokenId),'";</script><script>', _strScript, '</script></body></html>'
		);

		return string(
			abi.encodePacked(
				'data:text/html;base64,',
				Base64.encode(html)
			)
		);
	}

	/// @dev Mints a new token with the specified lines of text.
	function mint() public payable {
		uint256 index = _mintedTokens + 1;
		require(!_paused, _strPaused);
		require(index > 0, _strOutOfBounds);
		require(index <= _maxCap, _strOutOfBounds);

		if(_msgSender() != _contractOwner) {
			require(msg.value >= _mintFee, _strNotEnoughBalance);
		}

		_mintedTokens++;
		_mint(_msgSender(), index);
	}

	/// @dev Returns the contract's name.
	function name() public view returns(string memory) {
		return _strTokenName;
	}

	/// @dev Pauses the contract.
	///	 Note: Only contract's owner can change this.
	function pause() onlyAdmin public {
		_paused = true;
	}

	/// @dev Returns the contract's symbol, or ticker.
	function symbol() public view returns(string memory) {
		return _strTokenTicker;
	}

	/// @dev Returns a base64-encoded JSON that describes the given tokenID
	/// @param tokenId Token ID.
	function tokenURI(uint256 tokenId) insideBounds(tokenId) public view returns(string memory) {
		return string(
			abi.encodePacked(
				'data:application/json;base64,',
				Base64.encode(abi.encodePacked(
					'{',
						'"name": "SNEX #', Strings.toString(tokenId), '",',
						'"description": "', _strTokenDescription, '",',
						'"attributes": [',
							'{',
								'"trait_type": "Rarity", ',
								'"value": "', Strings.toString(tokenData[tokenId].rarity), '"',
							'}',
						'],',
						'"animation_url": "', generateHTML(tokenId), '",',
						'"cover": "', _strCoverImage, '"'
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
		require(balance > 0, _strNotEnoughBalance);
		(bool success, ) = (_msgSender()).call{value: balance}("");
		require(success, _strTransferFailed);
	}
}