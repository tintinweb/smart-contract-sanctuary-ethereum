/**
 *Submitted for verification at Etherscan.io on 2022-09-08
*/

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

/**
 * @dev Interface of the ERC20 standard as defined in the EIP.
 */
interface IERC20 {
	/**
	 * @dev Emitted when `value` tokens are moved from one account (`from`) to
	 * another (`to`).
	 *
	 * Note that `value` may be zero.
	 */
	event Transfer(address indexed from, address indexed to, uint256 value);
	
	/**
	 * @dev Emitted when the allowance of a `spender` for an `owner` is set by
	 * a call to {approve}. `value` is the new allowance.
	 */
	event Approval(address indexed owner, address indexed spender, uint256 value);
	
	/**
	 * @dev Returns the amount of tokens in existence.
	 */
	function totalSupply() external view returns (uint256);
	
	/**
	 * @dev Returns the amount of tokens owned by `account`.
	 */
	function balanceOf(address account) external view returns (uint256);
	
	/**
	 * @dev Moves `amount` tokens from the caller's account to `to`.
	 *
	 * Returns a boolean value indicating whether the operation succeeded.
	 *
	 * Emits a {Transfer} event.
	 */
	function transfer(address to, uint256 amount) external returns (bool);
	
	/**
	 * @dev Returns the remaining number of tokens that `spender` will be
	 * allowed to spend on behalf of `owner` through {transferFrom}. This is
	 * zero by default.
	 *
	 * This value changes when {approve} or {transferFrom} are called.
	 */
	function allowance(address owner, address spender) external view returns (uint256);
	
	/**
	 * @dev Sets `amount` as the allowance of `spender` over the caller's tokens.
	 *
	 * Returns a boolean value indicating whether the operation succeeded.
	 *
	 * IMPORTANT: Beware that changing an allowance with this method brings the risk
	 * that someone may use both the old and the new allowance by unfortunate
	 * transaction ordering. One possible solution to mitigate this race
	 * condition is to first reduce the spender's allowance to 0 and set the
	 * desired value afterwards:
	 * https://github.com/ethereum/EIPs/issues/20#issuecomment-263524729
	 *
	 * Emits an {Approval} event.
	 */
	function approve(address spender, uint256 amount) external returns (bool);
	
	/**
	 * @dev Moves `amount` tokens from `from` to `to` using the
	 * allowance mechanism. `amount` is then deducted from the caller's
	 * allowance.
	 *
	 * Returns a boolean value indicating whether the operation succeeded.
	 *
	 * Emits a {Transfer} event.
	 */
	function transferFrom(
		address from,
		address to,
		uint256 amount
	) external returns (bool);
}


pragma solidity ^0.8.0;

contract BURNER is Context, ERC721Burnable {
	event ReceivedRoyalties(address indexed creator, address indexed buyer, uint256 indexed amount);
	using SafeMath for uint256;
	bytes4 public constant _INTERFACE_ID_ERC2981 = 0x2a55205a;

	uint256 private _royaltiesPercentage = 7;
	uint256 private _mintFee = 50000000000000000; //0.05 ETH
	uint256 private _maxCap = 256;
	uint256 private _maxMintPerWallet = 25;
	uint256 private _mintedTokens = 0;
	address private _smartContractOwner = 0x65C7432E6662A96f4e999603991d5E929E57f60A;
	address private _smartContractCopilot = 0x4DaE7E6c0Ca196643012cDc526bBc6b445A2ca59;
	string private _name = "";
	string private _symbol = "";
	string private _description = "";
	string private _basePath = "https://crashblossom.co/burner/"; //returns the base path.
	string private _projectURI = ""; // Home web page, please leave it empty unless it's stored on a new path.
	string private _contractURI = "contract.php"; //return a JSON with the metadata of the contract.
	string private _baseTokenURI = "token.php"; //return a JSON with the metadata of any given token.
	string private _animationURI = "presentation.php"; //animation_url, it mixes and shows the final image dynamically.
	string private _tokenStaticImagePath = "assets/covers/";
	string private _banner_collection_URI = "assets/img/banner.jpg"; //Collection's banner.
	string private _contractImageURI = "assets/img/icon.jpg"; //Collection's icon.
	uint[16] _arrayGasTiers = [0, 3, 6, 9, 12, 15, 20, 65535]; //Tiers for layers 1-7. Layer 0 is base layer, always on. Layers 8 and 9 are special.
	mapping(uint => uint) private _tokenIdTracker;
	bool private _paused = false;
	bool private _frozen = false;

	string private _strNotAuthorized = "Not authorized!";
	string private _strIDOutBounds = "ID out of bounds!";
	string private _strIndexOutOfBounds = "Index out of bounds!";
	string private _strNotMintedYet = "Not minted yet!";
	string private _strPaused = "Contract is paused!";
	string private _strFrozen = "Contract is frozen!";

	string private _str1Block = "High Speed";
	string private _str2Block = "Medium Speed";
	string private _str4Block = "Low Speed";

	string private _jsCode = "";
	string private _ipfsLayers = "";
	string private _serverRepo = "";

	// CONSTRUCTOR
	constructor(string memory name, string memory symbol, string memory description) ERC721(name, symbol, description) {
		_name = name;
		_symbol = symbol;
		_description = description;
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

	function _getBlocksTierName(uint256 _tokenId) private view returns(string memory) {
		if(_tokenId > 0 && _tokenId < 16) {
			return _str1Block;
		}
		else if(_tokenId > 15 && _tokenId < 22) {
			return _str2Block;
		}
		else if(_tokenId > 21 && _tokenId < 25) {
			return _str4Block;
		}
		else if(_tokenId > 24 && _tokenId < 60) {
			return _str1Block;
		}
		else if(_tokenId > 59 && _tokenId < 72) {
			return _str2Block;
		}
		else if(_tokenId > 71 && _tokenId < 77) {
			return _str4Block;
		}
		else if(_tokenId > 76 && _tokenId < 205) {
			return _str1Block;
		}
		else if(_tokenId > 204 && _tokenId < 246) {
			return _str2Block;
		}
		else if(_tokenId > 245 && _tokenId < 257) {
			return _str4Block;
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

	/// @dev Returns the base URL (root folder) of the server storing all the scripts.
	function _basePathURI() internal view virtual returns(string memory) {
		return _basePath;
	}
	
	/// @dev Returns a URI pointing to the token-level JSON.
	function _baseURI() internal view virtual override returns(string memory) {
		return string(abi.encodePacked(_basePath, _baseTokenURI));
	}

	/// @dev Returns a URI pointing to the collection's icon.
	function contractImageURI() public view returns(string memory) {
		return string(abi.encodePacked(_basePath, _contractImageURI));
	}

	/// @dev Returns a URI pointing to the contract-level JSON.
	function contractURI() public view returns(string memory) {
		return string(abi.encodePacked(_basePath, _contractURI));
	}
	
	/// @dev Returns the description of the project.
	function description() public view returns(string memory) {
		return _description;
	}

	/// @dev Returns the max amount of allowed mints per wallet.
	function _getMaxMintsPerWallet() public view returns(uint) {
		return _maxMintPerWallet;
	}
	
	/// @dev Returns a string that can be the actual JSON listing of all the IPFS layers, or a URI pointing at it.
	function getIPFSJSON() public view returns(string memory) {
		return _ipfsLayers;
	}
	
	/// @dev Returns a string that can be the actual JS code or a URI pointing at it.
	function getJSCode() public view returns(string memory) {
		return _jsCode;
	}
	
	/// @dev Returns a URI pointing to a remote repo holding all the server-side scripts.
	function getRemoteRepo() public view returns(string memory) {
		return _serverRepo;
	}

	/// @dev Returns a boolean telling whether this contract has royalties or not.
	function hasRoyalties() public pure returns(bool) {
		return true;
	}

	/// @dev Returns the max amount of tokens this contract can hold (256).
	function maxCap() public view returns(uint256) {
		return _maxCap;
	}

	/// @dev Returns the mint fee, expressed in wei.
	function mintfee() public view returns(uint256) {
		return _mintFee;
	}

	/// @dev Returns the name of the project (BURNER).
	function name() public view override returns(string memory) {
		return _name;
	}

	/// @dev Returns a JSON containing all the contract-level data.
	function retrieveContractMetadata() public view returns(string memory data) {
		bytes memory json;
		uint royalties = _royaltiesPercentage * 100;

		json = abi.encodePacked('{', '"name": "');
		json = abi.encodePacked(json, _name);
		json = abi.encodePacked(json, '"');

		json = abi.encodePacked(json, ', ');
		json = abi.encodePacked(json, '"description": "');
		json = abi.encodePacked(json, _description);
		json = abi.encodePacked(json, '"');

		json = abi.encodePacked(json, ', ');
		json = abi.encodePacked(json, '"image": "');
		json = abi.encodePacked(json, _basePath);
		json = abi.encodePacked(json, _contractImageURI);
		json = abi.encodePacked(json, '"');

		json = abi.encodePacked(json, ', ');
		json = abi.encodePacked(json, '"external_link": "');
		json = abi.encodePacked(json, _basePath);
		json = abi.encodePacked(json, _projectURI);
		json = abi.encodePacked(json, '"');

		json = abi.encodePacked(json, ', ');
		json = abi.encodePacked(json, '"banner_image_url": "');
		json = abi.encodePacked(json, _basePath);
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

	/// @dev Returns a list of all the minted tokens so far.
	///      Note: Return value is an array containing all the tokenIDs stored onchain. Unconfirmed tx will not show up here.
	function retrieveTokenIDList() public view returns(string memory data) {
		bytes memory json;

		json = abi.encodePacked('[');

		if(_mintedTokens > 0) {
			for(uint i = 1; i <= _mintedTokens; i++) {
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

	/// @dev Returns a JSON containing all the associated data to a given token.
	/// @param _tokenId Token ID.
	function retrieveData(uint256 _tokenId) external view returns(string memory data) {
		// This function returns the metadata of a given token.
		require(_tokenId > 0, _strIDOutBounds);
		require(_tokenId <= _maxCap, _strIDOutBounds);
		require(_exists(_tokenId), _strNotMintedYet);

		uint256 rarity = 0;
		bytes memory json;

		rarity = _getTokenTier(_tokenId);

		json = abi.encodePacked('{', '"name": "');
		json = abi.encodePacked(json, _symbol);
		json = abi.encodePacked(json, ' #');
		json = abi.encodePacked(json, _uint2str(_tokenId));
		json = abi.encodePacked(json, '"');
		json = abi.encodePacked(json, ', ');
		json = abi.encodePacked(json, '"description": "');
		json = abi.encodePacked(json, _description);
		json = abi.encodePacked(json, ' Artist: crashblossom, Dev: Ariel Becker.');
		json = abi.encodePacked(json, '"');
		json = abi.encodePacked(json, ', ');
		json = abi.encodePacked(json, '"owner": "0x');
		json = abi.encodePacked(json, toAsciiString(ownerOf(_tokenId)));
		json = abi.encodePacked(json, '"');
		json = abi.encodePacked(json, ', ');
		json = abi.encodePacked(json, '"external_url": "');
		json = abi.encodePacked(json, _basePath);
		json = abi.encodePacked(json, _animationURI);
		json = abi.encodePacked(json, '?t=0&local=1&id=');
		json = abi.encodePacked(json, _uint2str(_tokenId));
		json = abi.encodePacked(json, '"');
		json = abi.encodePacked(json, ', ');
		json = abi.encodePacked(json, '"animation_url": "');
		json = abi.encodePacked(json, _basePath);
		json = abi.encodePacked(json, _animationURI);
		json = abi.encodePacked(json, '?t=1&id=');
		json = abi.encodePacked(json, _uint2str(_tokenId));
		json = abi.encodePacked(json, '"');
		json = abi.encodePacked(json, ', ');
		json = abi.encodePacked(json, '"image": "');
		json = abi.encodePacked(json, _basePath);
		json = abi.encodePacked(json, _tokenStaticImagePath);
		json = abi.encodePacked(json, _uint2str(_tokenId));
		json = abi.encodePacked(json, '.jpg');
		json = abi.encodePacked(json, '"');
		json = abi.encodePacked(json, ', ');
		json = abi.encodePacked(json, '"attributes": [');

		json = abi.encodePacked(json, '{');
		json = abi.encodePacked(json, '"trait_type": "Speed"');
		json = abi.encodePacked(json, ', ');
		json = abi.encodePacked(json, '"value": "');
		json = abi.encodePacked(json, _getBlocksTierName(_tokenId));
		json = abi.encodePacked(json, '"');
		json = abi.encodePacked(json, '},');

		json = abi.encodePacked(json, '{');
		json = abi.encodePacked(json, '"trait_type": "Layer"');
		json = abi.encodePacked(json, ', ');
		json = abi.encodePacked(json, '"value": "Shared"');
		json = abi.encodePacked(json, '}');

		if(rarity == 2 || rarity == 3) {
			json = abi.encodePacked(json, ', ');
			json = abi.encodePacked(json, '{');
			json = abi.encodePacked(json, '"trait_type": "Layer"');
			json = abi.encodePacked(json, ', ');
			json = abi.encodePacked(json, '"value": "Dark"');
			json = abi.encodePacked(json, '}');
		}
		if(rarity == 3) {
			json = abi.encodePacked(json, ', ');
			json = abi.encodePacked(json, '{');
			json = abi.encodePacked(json, '"trait_type": "Layer"');
			json = abi.encodePacked(json, ', ');
			json = abi.encodePacked(json, '"value": "Bright"');
			json = abi.encodePacked(json, '}');
		}

		json = abi.encodePacked(json, ']');
		json = abi.encodePacked(json, '}');

		return string(json);
	}

	/// @dev Returns a URI pointing to the server-side script that will display the animation for any token.
	function _renderURI() internal view virtual returns(string memory) {
		return string(abi.encodePacked(_basePath, _animationURI));
	}

	/// @dev Returns the royalties' percentage assigned to the project.
	function royaltyAmount() public view returns(uint256) {
		return _royaltiesPercentage;
	}

	/// @dev Returns the royalties that will be paid according to token ID and sale price.
	///      Note: Return value is expressed in wei.
	/// @param _tokenId Token ID.
	/// @param _salePrice Sale price, in wei.
	function royaltyInfo(uint256 _tokenId, uint256 _salePrice) external view returns(address receiver, uint256 royaltiesAmount) {
		require(_tokenId > 0, _strIDOutBounds);
		require(_tokenId <= _maxCap, _strIDOutBounds);
		require(_exists(_tokenId), _strNotMintedYet);
		require(_salePrice > 99, "Price is too small!");

		uint256 retValue = _salePrice.div(100).mul(_royaltiesPercentage);
		return(_smartContractOwner, retValue);
	}

	/// @dev Returns a URI pointing to the token's JSON.
	/// @param _tokenId Token ID.
	function tokenURI(uint256 _tokenId) public view virtual override returns(string memory) {
		// Example: https://opensea-creatures-api.herokuapp.com/api/creature/3
		require(_tokenId > 0, _strIDOutBounds);
		require(_tokenId <= _maxCap, _strIDOutBounds);
		require(_exists(_tokenId), _strNotMintedYet);

		string memory baseURI = _baseURI();
		return bytes(baseURI).length > 0 ? string(abi.encodePacked(baseURI, "?id=", Strings.toString(_tokenId))) : "";
	}

	function supportsInterface(bytes4 interfaceId) public view virtual override(ERC721) returns(bool) {
		return interfaceId == 0x2a55205a || super.supportsInterface(interfaceId);
	}

	/// @dev Returns the contract's symbol (BURNER).
	function symbol() public view override returns(string memory) {
		return _symbol;
	}

	/// @dev Returns a URI pointing to the folder containing all the layers images.
	function tokenImageURI() public view returns(string memory) {
		return string(abi.encodePacked(_basePath, _tokenStaticImagePath));
	}

	/// @dev Returns the animation's renderer URI (the one that initializes the JS script).
	/// @param _tokenId Token ID.
	function tokenShowcaseURI(uint _tokenId) public view returns(string memory) {
		require(_tokenId > 0, _strIDOutBounds);
		require(_tokenId <= _maxCap, _strIDOutBounds);
		require(_exists(_tokenId), _strNotMintedYet);
		string memory uri = string(abi.encodePacked(_basePath, _animationURI));
		return bytes(uri).length > 0 ? string(abi.encodePacked(uri, "?t=0&id=", Strings.toString(_tokenId))) : "";
	}

	// SETTERS

	/// @dev Changes the contract's description.
	/// @param _desc New description.
	function changeDescription(string memory _desc) public {
		require(_msgSender() == _smartContractOwner, _strNotAuthorized);
		require(!_frozen, _strFrozen);
		_description = _desc;
	}
	
	/// @dev Freezes the contract, disabling some functions forever.
	///      WARNING: ONCE SET, THIS STATE CANNOT BE REVERSED.
	///      This is the list of functions that will be disabled by it:
	///      changeDescription, setMaxMintsPerWallet, setMintFee, setRoyaltyAmount, setIPFSLayers, setJS, setServerRepoURI.
	function freeze() public virtual {
		require(_msgSender() == _smartContractOwner, _strNotAuthorized);
		require(!_frozen, _strFrozen);
		_frozen = true;
	}

	/// @dev Pauses some functions of the contract, like minting.
	function pause() public virtual {
		require(_msgSender() == _smartContractOwner, _strNotAuthorized);
		require(!_paused, _strPaused);
		_paused = true;
	}

	/// @dev Sets the admin's address.
	/// @param _newAddress New address.
	function setAdmin(address _newAddress) public {
		require((_msgSender() == _smartContractOwner || _msgSender() == _smartContractCopilot), _strNotAuthorized);
		_smartContractOwner = _newAddress;
	}

	/// @dev Sets the base URI for all the relative paths.
	/// @param _uri Base URI.
	function setBasePath(string memory _uri) public {
		require(_msgSender() == _smartContractOwner, _strNotAuthorized);
		_basePath = _uri;
	}

	/// @dev Sets the relative path to token.php (or any other server-side script responsible for rendering the token's JSON).
	/// @param _relativePath Relative path and filename.
	function setBaseTokenURI(string memory _relativePath) public {
		require(_msgSender() == _smartContractOwner, _strNotAuthorized);
		_baseTokenURI = _relativePath;
	}

	/// @dev Sets the relative path to the contract's image.
	/// @param _relativePath Relative path and filename.
	function setContractImage(string memory _relativePath) public {
		require(_msgSender() == _smartContractOwner, _strNotAuthorized);
		_contractImageURI = _relativePath;
	}

	/// @dev Sets the relative path to contract.php (or any other server-side script responsible for rendering the contract's JSON).
	/// @param _relativePath Relative path and filename.
	function setContractURI(string memory _relativePath) public {
		require(_msgSender() == _smartContractOwner, _strNotAuthorized);
		_contractURI = _relativePath;
	}

	/// @dev Sets the maximum amount of tokens a single wallet can mint.
	///      Note: default value is 25.
	/// @param _maxAmount New value, expressed in percent points.
	function setMaxMintsPerWallet(uint256 _maxAmount) public {
		require(_msgSender() == _smartContractOwner, _strNotAuthorized);
		require(!_frozen, _strFrozen);
		require(_maxAmount < 257, "Cannot exceed total supply!");
		require(_maxAmount > 0, "Must be 1 or higher!");
		_maxMintPerWallet = _maxAmount;
	}

	/// @dev Changes the value of the minting fee. Expressed in wei.
	///      Note: default value is 0.01 ETH.
	/// @param _newfee New value, expressed in wei.
	function setMintFee(uint256 _newfee) public {
		require(_msgSender() == _smartContractOwner, _strNotAuthorized);
		require(!_frozen, _strFrozen);
		_mintFee = _newfee;
	}

	/// @dev Relative path for the webpage.
	///      Note: Relative to base URI.
	/// @param _relativePath New relative path.
	function setProjectURI(string memory _relativePath) public {
		require(_msgSender() == _smartContractOwner, _strNotAuthorized);
		_projectURI = _relativePath;
	}

	/// @dev Changes the value of the royalty percentage. Expressed in percent points.
	///      Note: default value is 7.
	/// @param _percentage New value, expressed in percent points.
	function setRoyaltyAmount(uint256 _percentage) public {
		require(_msgSender() == _smartContractOwner, _strNotAuthorized);
		require(!_frozen, _strFrozen);
		_royaltiesPercentage = _percentage;
	}
	
	/// @dev Sets the relative path where all the static imagery (gallery images) for each token is stored.
	/// @param _relativePath Path relative to base URL.
	function setTokenStaticImageURI(string memory _relativePath) public {
		require(_msgSender() == _smartContractOwner, _strNotAuthorized);
		_tokenStaticImagePath = _relativePath;
	}

	/// @dev Sets the relative path where all the dynamic imagery for each token is stored.
	/// @param _relativePath Path relative to base URL.
	function setTokenImageURI(string memory _relativePath) public {
		require(_msgSender() == _smartContractOwner, _strNotAuthorized);
		_animationURI = _relativePath;
	}
	
	/// @dev Stores a JSON containing the list of all the imagery used for the token layers.
	///      Note: It can store the list itself or a URI pointing to the actual list.
	/// @param _json A JSON object containing the list of all the hashes for both full-size and thumbnails, or a URI pointing to a valid JSON.
	function setIPFSLayers(string memory _json) public {
		require(_msgSender() == _smartContractOwner, _strNotAuthorized);
		require(!_frozen, _strFrozen);
		_ipfsLayers = _json;
	}
	
	/// @dev Stores the code of the contract, or a URI pointing to it.
	///      Note: You can minify then ZIP and base64 it to reduce the amount of data. Remember to modify the PHP on the gateway to reflect this.
	/// @param _str URI to the code, or the code itself.
	function setJS(string memory _str) public {
		require(_msgSender() == _smartContractOwner, _strNotAuthorized);
		require(!_frozen, _strFrozen);
		_jsCode = _str;
	}
	
	/// @dev Stores a URI pointing to the server-side code of the project.
	/// @param _uri URI to the repository.
	function setServerRepoURI(string memory _uri) public {
		require(_msgSender() == _smartContractOwner, _strNotAuthorized);
		require(!_frozen, _strFrozen);
		_serverRepo = _uri;
	}
	
	/// @dev Unpauses the contract, allowing some functions to operate again.
	function unpause() public virtual {
		require(_msgSender() == _smartContractOwner, _strNotAuthorized);
		require(_paused, "Contract is already unpaused!");
		_paused = false;
	}

	// MINT AND OTHER FUNCTIONS
	function royaltiesReceived(address _creator, address _buyer, uint256 _amount) external {
		emit ReceivedRoyalties(_creator, _buyer, _amount);
	}

	/// @dev Allows to withdraw any ETH available on this contract.
	///      Note: Only the contract's owner can withdraw.
	function withdraw() public payable {
		require(!_paused, _strPaused);
		require(_msgSender() == _smartContractOwner, _strNotAuthorized);
		uint balance = address(this).balance;
		require(balance > 0, "No ether left to withdraw");
		(bool success, ) = (msg.sender).call{value: balance}("");
		require(success, "Transfer failed.");
	}
	
	/// @dev Allows to withdraw any ERC-20 token sent by error to this contract.
	///      Note: Only the contract's owner can withdraw.
	function withdrawERC20(IERC20 token) public payable {
		require(!_paused, _strPaused);
		require(_msgSender() == _smartContractOwner, _strNotAuthorized);
		require(token.transfer(msg.sender, token.balanceOf(address(this))), "Transfer failed");
	}
	
	/// @dev Mints a random token. Non-admins must pay a fee for it.
	///      Note: The fees are always transferred, even if the user transaction fails.
	function mint() public payable {
		// Shouldn't be paused.
		require(!_paused, _strPaused);
		// Shouldn't attempt to mint more tokens than allowed per address.
		require(ERC721.balanceOf(_msgSender()) < (_maxMintPerWallet), "More than max mints allowed for this addy!");
		// Shouldn't attempt to mint more tokens than the allowed by the contract.
		require(ERC721.balanceOf(_msgSender()) < (_maxCap - _mintedTokens), "This action will surpass the mint cap!");
		// Shouldn't be minted by the zero addy.
		require(_msgSender() != address(0), "Zero address");

		if(_msgSender() != _smartContractOwner) {
			require(msg.value >= _mintFee, "Not enough ETH!");
		}

		bool boolBreakLoop = false;

		while(!boolBreakLoop) {
			//Create a pseudorandom seed in the form of a hash
			bytes32 seed = keccak256(abi.encodePacked(block.timestamp, block.difficulty, _msgSender()));
			// Extract the last byte.
			uint8 _index = uint8(bytes1(seed[0]));
			// Add one so it goes from 1 to 256.
			uint index = _index + 1;

			// And use that index to mint a pseudorandom tokenID.
			if(!_exists(index)) {
				if(index > 0 && index <= _maxCap) {
					_mint(_msgSender(), index);
					_mintedTokens++;
					_tokenIdTracker[_mintedTokens] = index;
					boolBreakLoop = true;
				}
			}
		}
	}
}