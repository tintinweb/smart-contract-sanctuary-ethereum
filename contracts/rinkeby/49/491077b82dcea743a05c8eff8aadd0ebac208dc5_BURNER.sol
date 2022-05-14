/**
 *Submitted for verification at Etherscan.io on 2022-05-14
*/

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;
interface IERC165 {
	function supportsInterface(bytes4 interfaceId) external view returns(bool);
}

pragma solidity ^0.8.0;
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

pragma solidity ^0.8.0;
interface IERC721Receiver {
	function onERC721Received(address operator, address from, uint256 tokenId, bytes calldata data) external returns(bytes4);
}

pragma solidity ^0.8.0;
interface IERC721Metadata is IERC721 {
	function name() external view returns(string memory);
	function symbol() external view returns(string memory);
	function tokenURI(uint256 tokenId) external view returns(string memory);
}

pragma solidity ^0.8.0;
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

pragma solidity ^0.8.0;
abstract contract Context {
	function _msgSender() internal view virtual returns(address) {
		return msg.sender;
	}
	
	function _msgData() internal view virtual returns(bytes calldata) {
		return msg.data;
	}
}

pragma solidity ^0.8.0;
library Strings {
	bytes16 private constant _HEX_SYMBOLS = "0123456789abcdef";
	
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
	
	function toHexString(uint256 value) internal pure returns(string memory) {
		if(value == 0) {
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
	
	function toHexString(uint256 value, uint256 length) internal pure returns(string memory) {
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

pragma solidity ^0.8.0;
abstract contract ERC165 is IERC165 {
	function supportsInterface(bytes4 interfaceId) public view virtual override returns(bool) {
		return interfaceId == type(IERC165).interfaceId;
	}
}

pragma solidity ^0.8.0;
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
		require(tokenId != tokenId, "Disabled!");
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

pragma solidity ^0.8.0;
abstract contract ERC721Burnable is Context, ERC721 {
	function burn(uint256 tokenId) public virtual {
		//solhint-disable-next-line max-line-length
		require(_isApprovedOrOwner(_msgSender(), tokenId), "Not authorized!");
		_burn(tokenId);
	}
}

pragma solidity ^0.8.0;

pragma solidity ^0.8.0;
library SafeMath {
	function add(uint256 a, uint256 b) internal pure returns(uint256) {
		uint256 c = a + b;
		require(c >= a, "Addition overflow!");
		
		return c;
	}
	
	function sub(uint256 a, uint256 b) internal pure returns(uint256) {
		require(b <= a, "Subtraction overflow!");
		uint256 c = a - b;
		
		return c;
	}
	
	function mul(uint256 a, uint256 b) internal pure returns(uint256) {
		// Gas optimization: this is cheaper than requiring 'a' not being zero, but the
		// benefit is lost if 'b' is also tested.
		// See: https://github.com/OpenZeppelin/openzeppelin-solidity/pull/522
		if(a == 0) {
			return 0;
		}
		
		uint256 c = a * b;
		require(c / a == b, "Multiplication overflow!");
		
		return c;
	}
	
	function div(uint256 a, uint256 b) internal pure returns(uint256) {
		// Solidity only automatically asserts when dividing by 0
		require(b > 0, "Division by zero!");
		uint256 c = a / b;
		// assert(a == b * c + a % b); // There is no case in which this doesn't hold
		
		return c;
	}
	
	function mod(uint256 a, uint256 b) internal pure returns(uint256) {
		require(b != 0, "Modulo by zero!");
		return a % b;
	}
}

pragma solidity ^0.8.0;

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

pragma solidity ^0.8.0;

contract IERC2309  {
	event ConsecutiveTransfer(uint256 indexed fromTokenId, uint256 toTokenId, address indexed fromAddress, address indexed toAddress);
}

pragma solidity ^0.8.0;

contract BURNER is Context, ERC721Burnable {
	event ReceivedRoyalties(address indexed creator, address indexed buyer, uint256 indexed amount);
	using SafeMath for uint256;
	bytes4 public constant _INTERFACE_ID_ERC2981 = 0x2a55205a;
	
	uint256 private _royaltiesPercentage = 7;
	uint256 private _mintFee = 10000000000000000; //0.01 ETH
	uint256 private _maxCap = 256;
	uint256 private _maxMintPerWallet = 25;
	uint256 private _tokenCounter = 0;
	address private _smartContractOwner = 0x61C62a92f9624454a398D28298e9297B2Ab34806;
	address private _smartContractCopilot = 0xC12Df5F402A8B8BEaea49ed9baD9c95fCcbfE907;
	string private _name = "BURNER";
	string private _symbol = "BURNER";
	string private _description = "BURNER is a series created using the information content in Ethereum gas prices. A total of 256 interconnected artworks that all dynamically react to the price of gas as well as block transactions. As Ethereum network usage increases, due to price changes, NFT sales or other factors, a more complex BURNER appears.";
	string private _projectURI = "https://crashblossom.co/burner";
	string private _baseTokenURI = "https://crashblossom.co/burner/token.php";
	string private _contractURI = "https://crashblossom.co/burner/contract.php";
	string private _showcaseURI = "https://crashblossom.co/burner/display.php";
	string private _banner_collection_URI = "https://crashblossom.co/burner/assets/img/banner.jpg";
	string private _contractImageURI = "https://crashblossom.co/burner/assets/img/icon.jpg";
	uint[16] _arrayGasTiers = [0, 15, 30, 60, 90, 145, 200, 65535];
	string private _imagesPath = "";
	mapping(uint => uint) private _tokenIdTracker;
	bool private _paused = false;
	bool private _frozen = false;
	
	string private _strNotAuthorized = "Not authorized!";
	string private _strIDOutBounds = "ID out of bounds!";
	string private _strIndexOutOfBounds = "Index out of bounds!";
	string private _strNotMintedYet = "Not minted yet!";
	string private _strPaused = "Contract is paused!";
	string private _strFrozen = "Contract is frozen!";
	
	// CONSTRUCTOR
	constructor(string memory name, string memory symbol, string memory description) ERC721(name, symbol, description) {
		name = _name;
		symbol = _symbol;
		description = _description;
		
		_smartContractOwner = _msgSender();
	}
	
	// INTERNAL AUX FUNCTIONS
	
	function char(bytes1 b) internal pure returns(bytes1 c) {
		if(uint8(b) < 10) return bytes1(uint8(b) + 0x30);
		else return bytes1(uint8(b) + 0x57);
	}
	
	function _getGasTier(uint gasCost) private view returns(uint) {
		uint retValue = 7;
		for(uint i = 0; i < 7; i++) {
			if(gasCost > _arrayGasTiers[i] && gasCost <= _arrayGasTiers[i + 1]) {
				retValue = i;
				break;
			}
		}
		
		return retValue;
	}
	
	function _getTokenTier(uint256 _tokenId) private pure returns(uint256) {
		if(_tokenId > 0 && _tokenId < 25) {
			return 3;
		}
		else if(_tokenId > 24 && _tokenId < 77) {
			return 2;
		}
		else {
			return 1;
		}
	}
	
	function _getTokenTierName(uint256 _tokenId) private pure returns(string memory) {
		if(_tokenId > 0 && _tokenId < 25) {
			return 'Bright';
		}
		else if(_tokenId > 24 && _tokenId < 77) {
			return 'Dark';
		}
		else {
			return 'Collective layers';
		}
	}
	
	function toAsciiString(address x) internal pure returns(string memory) {
		bytes memory s = new bytes(40);
		for (uint i = 0; i < 20; i++) {
			bytes1 b = bytes1(uint8(uint(uint160(x)) / (2**(8*(19 - i)))));
			bytes1 hi = bytes1(uint8(b) / 16);
			bytes1 lo = bytes1(uint8(b) - 16 * uint8(hi));
			s[2*i] = char(hi);
			s[2*i+1] = char(lo);
		}
		return string(s);
	}
	
	function _uint2str(uint256 _i) internal pure returns(string memory str) {
		if (_i == 0)  {
			return "0";
		}
		uint256 j = _i;
		uint256 length;
		while (j != 0) {
			length++;
			j /= 10;
		}
		bytes memory bstr = new bytes(length);
		uint256 k = length;
		j = _i;
		while (j != 0) {
			bstr[--k] = bytes1(uint8(48 + j % 10));
			j /= 10;
		}
		str = string(bstr);
		
		return str;
	}
	
	// GETTERS
	
	function _baseURI() internal view virtual override returns(string memory) {
		return _baseTokenURI;
	}
	
	function contractImageURI() public view returns(string memory) {
		return _contractImageURI;
	}
	
	function contractURI() public view returns(string memory) {
		return _contractURI;
	}
	
	function getImagesPath() public view returns(string memory) {
		return _imagesPath;
	}
	
	function _getMaxMintsPerWallet() public view returns(uint) {
		return _maxMintPerWallet;
	}
	
	function getRenderData(uint tokenIndex, uint currentGas, uint currentDay) public view returns(bytes memory data) {
		require(tokenIndex >= 0, _strIDOutBounds);
		require(tokenIndex < _maxCap, _strIDOutBounds);
		require(_exists(tokenIndex), _strNotMintedYet);
		
		bytes memory currentSetup;
		uint tokenTier = _getTokenTier(tokenIndex);
		bytes32 seed = keccak256(abi.encodePacked(currentDay, tokenIndex));
		uint baseL;
		
		if(tokenTier == 3) {// Brights, 1 to 24, 24
			baseL = ((uint8(bytes1(seed[0])) * uint(24)) / 255) + 1;
		}
		else if(tokenTier == 2) {// Darks, 25 to 76, 51
			baseL = ((uint8(bytes1(seed[0])) * uint(51)) / 255) + 25;
		}
		else if(tokenTier == 1) { // Commoners, 77 to 256, 178
			baseL = ((uint8(bytes1(seed[0])) * uint(178)) / 255) + 77;
		}
		
		currentSetup = abi.encodePacked(currentSetup, baseL);
		
		for(uint i = 2; i <= 7; i++) {
			if(_getGasTier(currentGas) >= i) {
				currentSetup = abi.encodePacked(currentSetup, seed[i - 1]);
			}
			else if(_getGasTier(currentGas) < i) {
				currentSetup = abi.encodePacked(currentSetup, '0');
			}
		}
		
		for(uint i = 8; i <= 9; i++) {
			if(tokenTier == 1) {
				currentSetup = abi.encodePacked(currentSetup, '0');
			}
			else {
				if(i == 8) {
					if(tokenTier == 2) {
						currentSetup = abi.encodePacked(currentSetup, seed[7]);
					}
					else if(tokenTier == 3) {
						currentSetup = abi.encodePacked(currentSetup, seed[7]);
					}
					else {
						currentSetup = abi.encodePacked(currentSetup, '0');
					}
				}
				
				if(i == 9) {
					if(tokenTier == 2) {
						currentSetup = abi.encodePacked(currentSetup, '0');
					}
					else if(tokenTier == 3) {
						currentSetup = abi.encodePacked(currentSetup, seed[8]);
					}
					else {
						currentSetup = abi.encodePacked(currentSetup, '0');
					}
				}
			}
		}
		
		return currentSetup;
	}
	
	function hasRoyalties() public pure returns(bool) {
		return true;
	}
	
	function maxCap() public view returns(uint256) {
		return _maxCap;
	}
	
	function mintfee() public view returns(uint256) {
		return _mintFee;
	}
	
	function name() public view override returns(string memory) {
		return _name;
	}
	
	function retrieveContractMetadata() public view returns(string memory data) {
		bytes memory json;
		uint royalties = _royaltiesPercentage * 100;
		// Example: https://docs.opensea.io/docs/contract-level-metadata
		// {"name": "BURNER","description": "Layers that change according to gas cost.","image": "https://crashblossom.co/burner/icon.gif","external_link": "https://crashblossom.co/burner","seller_fee_basis_points": 700, "fee_recipient": "0xC12Df5F402A8B8BEaea49ed9baD9c95fCcbfE907"}
		
		json = abi.encodePacked('{', '"name": "');
		json = abi.encodePacked(json, _name);
		json = abi.encodePacked(json, '"');
		
		json = abi.encodePacked(json, ', ');
		json = abi.encodePacked(json, '"description": "');
		json = abi.encodePacked(json, _description);
		json = abi.encodePacked(json, '"');
		
		json = abi.encodePacked(json, ', ');
		json = abi.encodePacked(json, '"image": "');
		json = abi.encodePacked(json, _contractImageURI);
		json = abi.encodePacked(json, '"');
		
		json = abi.encodePacked(json, ', ');
		json = abi.encodePacked(json, '"external_link": "');
		json = abi.encodePacked(json, _projectURI);
		json = abi.encodePacked(json, '"');
		
		json = abi.encodePacked(json, ', ');
		json = abi.encodePacked(json, '"banner_image_url": "');
		json = abi.encodePacked(json, _banner_collection_URI);
		json = abi.encodePacked(json, '"');
		
		json = abi.encodePacked(json, ', ');
		json = abi.encodePacked(json, '"seller_fee_basis_points": ');
		json = abi.encodePacked(json, _uint2str(royalties));
		
		json = abi.encodePacked(json, ', ');
		json = abi.encodePacked(json, '"fee_recipient": "');
		json = abi.encodePacked(json, toAsciiString(_smartContractOwner));
		json = abi.encodePacked(json, '"');
		
		json = abi.encodePacked(json, '}');
		
		return string(json);
	}
	
	function retrieveTokenIDList() public view returns(string memory data) {
		bytes memory json;
		
		json = abi.encodePacked('[');
		
		if(_tokenCounter > 0) {
			for(uint i = 1; i <= _tokenCounter; i++) {
				if(i == 1) {
					json = abi.encodePacked(json, _uint2str(_tokenIdTracker[i]));
				}
				else {
					json = abi.encodePacked(json, ',', _uint2str(_tokenIdTracker[i]));
				}
			}
		}
		
		json = abi.encodePacked(json, ']');
		
		return string(json);
	}
	
	function retrieveData(uint256 _tokenId) external view returns(string memory data) {
		// This function returns the metadata of a given token.
		require(_tokenId >= 0, _strIDOutBounds);
		require(_tokenId < _maxCap, _strIDOutBounds);
		require(_exists(_tokenId), _strNotMintedYet);
		
		uint256 rarity = 0;
		string memory trait;
		bytes memory json;
		
		rarity = _getTokenTier(_tokenId);
		trait = _getTokenTierName(_tokenId);
		
		json = abi.encodePacked('{', '"name": "');
		json = abi.encodePacked(json, _symbol);
		json = abi.encodePacked(json, ' #');
		json = abi.encodePacked(json, _uint2str(_tokenId));
		json = abi.encodePacked(json, '"');
		json = abi.encodePacked(json, ', ');
		json = abi.encodePacked(json, '"description": "');
		json = abi.encodePacked(json, _description);
		json = abi.encodePacked(json, '"');
		json = abi.encodePacked(json, ', ');
		json = abi.encodePacked(json, '"owner": "0x');
		json = abi.encodePacked(json, toAsciiString(ownerOf(_tokenId)));
		json = abi.encodePacked(json, '"');
		json = abi.encodePacked(json, ', ');
		json = abi.encodePacked(json, '"external_url": "');
		json = abi.encodePacked(json, _showcaseURI);
		json = abi.encodePacked(json, '?t=0&id=');
		json = abi.encodePacked(json, _uint2str(_tokenId));
		json = abi.encodePacked(json, '"');
		json = abi.encodePacked(json, ', ');
		json = abi.encodePacked(json, '"animation_url": "');
		json = abi.encodePacked(json, _showcaseURI);
		json = abi.encodePacked(json, '?t=1&id=');
		json = abi.encodePacked(json, _uint2str(_tokenId));
		json = abi.encodePacked(json, '"');
		json = abi.encodePacked(json, ', ');
		json = abi.encodePacked(json, '"image": "');
		json = abi.encodePacked(json, _showcaseURI);
		json = abi.encodePacked(json, '?t=1&id=');
		json = abi.encodePacked(json, _uint2str(_tokenId));
		json = abi.encodePacked(json, '"');
		json = abi.encodePacked(json, ', ');
		json = abi.encodePacked(json, '"attributes": [');
		json = abi.encodePacked(json, '{');
		json = abi.encodePacked(json, '"value": "');
		json = abi.encodePacked(json, trait);
		json = abi.encodePacked(json, '"');
		json = abi.encodePacked(json, '}');
		json = abi.encodePacked(json, ']');
		json = abi.encodePacked(json, '}');
		
		return string(json);
	}
	
	function _renderURI() internal view virtual returns(string memory) {
		// https://crashblossom.co/burner/render.php
		return _showcaseURI;
	}
	
	function royaltyAmount() public view returns(uint256) {
		return _royaltiesPercentage;
	}
	
	function royaltyInfo(uint256 _tokenId, uint256 _salePrice) external view returns(address receiver, uint256 royaltiesAmount) {
		require(_tokenId >= 0, _strIDOutBounds);
		require(_tokenId < _maxCap, _strIDOutBounds);
		require(_exists(_tokenId), _strNotMintedYet);
		require(_salePrice > 99, "Price is too small!");
		
		uint256 valorRoyalties = _salePrice.div(100).mul(_royaltiesPercentage);
		return(_smartContractOwner, valorRoyalties);
	}
	
	function tokenURI(uint256 _tokenId) public view virtual override returns(string memory) {
		// Example: https://opensea-creatures-api.herokuapp.com/api/creature/3
		require(_tokenId >= 0, _strIDOutBounds);
		require(_tokenId < _maxCap, _strIDOutBounds);
		require(_exists(_tokenId), _strNotMintedYet);
		
		string memory baseURI = _baseURI();
		return bytes(baseURI).length > 0 ? string(abi.encodePacked(baseURI, "?id=", Strings.toString(_tokenId))) : "";
	}
	
	function supportsInterface(bytes4 interfaceId) public view virtual override(ERC721) returns(bool) {
		return interfaceId == 0x2a55205a || super.supportsInterface(interfaceId);
	}
	
	function symbol() public view override returns(string memory) {
		return _symbol;
	}
	
	function tokenImageURI() public view returns(string memory) {
		return _showcaseURI;
	}
	
	function tokenShowcaseURI(uint _tokenId) public view returns(string memory) {
		require(_tokenId >= 0, _strIDOutBounds);
		require(_tokenId < _maxCap, _strIDOutBounds);
		require(_exists(_tokenId), _strNotMintedYet);
		string memory uri = _showcaseURI;
		return bytes(uri).length > 0 ? string(abi.encodePacked(uri, "?id=", Strings.toString(_tokenId))) : "";
	}
	
	// SETTERS
	
	function changeDescription(string memory _desc) public {
		require(_msgSender() == _smartContractOwner, _strNotAuthorized);
		require(!_frozen, _strFrozen);
		_description = _desc;
	}
	
	function pause() public virtual {
		require(_msgSender() == _smartContractOwner, _strNotAuthorized);
		require(!_paused, _strPaused);
		_paused = true;
	}
	
	function setAdmin(address newadmin) public {
		require((_msgSender() == _smartContractOwner || _msgSender() == _smartContractCopilot), _strNotAuthorized);
		_smartContractOwner = newadmin;
	}
	
	function setBaseTokenURI(string memory _uri) public {
		require(_msgSender() == _smartContractOwner, _strNotAuthorized);
		_baseTokenURI = _uri;
	}
	
	function setContractImage(string memory _uri) public {
		require(_msgSender() == _smartContractOwner, _strNotAuthorized);
		_contractImageURI = _uri;
	}
	
	function setContractURI(string memory _uri) public {
		require(_msgSender() == _smartContractOwner, _strNotAuthorized);
		_contractURI = _uri;
	}
	
	function setImagesPath(string memory _newImagesPath) public {
		require(_msgSender() == _smartContractOwner, _strNotAuthorized);
		_imagesPath = _newImagesPath;
	}
	
	function setMaxCap(uint256 new_value) public {
		require(_msgSender() == _smartContractOwner, _strNotAuthorized);
		require(!_frozen, _strFrozen);
		_maxCap = new_value;
	}
	
	function setMaxMintsPerWallet(uint256 new_value) public {
		require(_msgSender() == _smartContractOwner, _strNotAuthorized);
		require(!_frozen, _strFrozen);
		_maxMintPerWallet = new_value;
	}
	
	function setMintFee(uint256 newfee) public {
		require(_msgSender() == _smartContractOwner, _strNotAuthorized);
		require(!_frozen, _strFrozen);
		_royaltiesPercentage = newfee;
	}
	
	function setProjectURI(string memory _uri) public {
		require(_msgSender() == _smartContractOwner, _strNotAuthorized);
		_projectURI = _uri;
	}
	
	function setRoyaltyAmount(uint256 newfee) public {
		require(_msgSender() == _smartContractOwner, _strNotAuthorized);
		require(!_frozen, _strFrozen);
		_mintFee = newfee;
	}
	
	function setTokenDisplayURI(string memory _uri) public {
		require(_msgSender() == _smartContractOwner, _strNotAuthorized);
		_showcaseURI = _uri;
	}
	
	function setTokenImageURI(string memory _uri) public {
		require(_msgSender() == _smartContractOwner, _strNotAuthorized);
		_showcaseURI = _uri;
	}
	
	function unpause() public virtual {
		require(_msgSender() == _smartContractOwner, _strNotAuthorized);
		require(_paused, "Contract is already unpaused!");
		_paused = false;
	}
	
	// MINT AND OTHER FUNCTIONS
	
	function royaltiesReceived(address _creator, address _buyer, uint256 _amount) external {
		emit ReceivedRoyalties(_creator, _buyer, _amount);
	}
	
	function withdraw() public payable {
		require(!_paused, _strPaused);
		require(_msgSender() == _smartContractOwner, _strNotAuthorized);
		uint balance = address(this).balance;
		require(balance > 0, "No ether left to withdraw");
		(bool success, ) = (msg.sender).call{value: balance}("");
		require(success, "Transfer failed.");
	}
	
	function mint() public payable {
		// Shouldn't be paused.
		require(!_paused, _strPaused);
		// Shouldn't attempt to mint more tokens than allowed per address.
		require(ERC721.balanceOf(_msgSender()) < (_maxMintPerWallet), "More than max mints allowed for this addy!");
		// Shouldn't attempt to mint more tokens than the allowed by the contract.
		require(ERC721.balanceOf(_msgSender()) < (_maxCap - _tokenCounter), "This action will surpass the mint cap!");
		// Shouldn't be minted by the zero addy.
		require(_msgSender() != address(0), "Zero address");
		
		if(_msgSender() != _smartContractOwner) {
			require(msg.value >= _mintFee, "Not enough ETH!");
		}
		
		bool boolBreakLoop = false;

		while(!boolBreakLoop) {
			bytes32 seed = keccak256(abi.encodePacked(block.timestamp, block.difficulty, _msgSender()));
			uint8 _index = uint8(bytes1(seed[0]));
			
			if(!_exists(_index)) {
				if(_index > 0 && _index < _maxCap) {
					_mint(_msgSender(), _index);
					_tokenCounter++;
					_tokenIdTracker[_tokenCounter] = _index;
					boolBreakLoop = true;
				}
			}
		}
	}
	
	/**
	 *	Constructor arguments, ABI-encoded:
	 * 000000000000000000000000000000000000000000000000000000000000006000000000000000000000000000000000000000000000000000000000000000a000000000000000000000000000000000000000000000000000000000000000e000000000000000000000000000000000000000000000000000000000000000064255524e4552000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000064255524e45520000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000013b4255524e45522069732061207365726965732063726561746564207573696e672074686520696e666f726d6174696f6e20636f6e74656e7420696e20457468657265756d20676173207072696365732e204120746f74616c206f662032353620696e746572636f6e6e656374656420617274776f726b73207468617420616c6c2064796e616d6963616c6c7920726561637420746f20746865207072696365206f66206761732061732077656c6c20617320626c6f636b207472616e73616374696f6e732e20417320457468657265756d206e6574776f726b20757361676520696e637265617365732c2064756520746f207072696365206368616e6765732c204e46542073616c6573206f72206f7468657220666163746f72732c2061206d6f726520636f6d706c6578204255524e455220617070656172732e0000000000
	 */
}