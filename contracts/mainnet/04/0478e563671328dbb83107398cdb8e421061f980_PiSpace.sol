/**
 *Submitted for verification at Etherscan.io on 2022-09-02
*/

// SPDX-License-Identifier: MIT
pragma solidity 0.8.9;

interface IERC165 {
	function supportsInterface(bytes4 interfaceId) external view returns (bool);
}

interface IERC721 is IERC165 {
	event Transfer(address indexed from, address indexed to, uint256 indexed tokenId);
	event Approval(address indexed owner, address indexed approved, uint256 indexed tokenId);
	event ApprovalForAll(address indexed owner, address indexed operator, bool approved);
	function balanceOf(address owner) external view returns (uint256 balance);
	function ownerOf(uint256 tokenId) external view returns (address owner);
	function safeTransferFrom(address from, address to, uint256 tokenId) external;
	function transferFrom(address from, address to, uint256 tokenId) external;
	function approve(address to, uint256 tokenId) external;
	function getApproved(uint256 tokenId) external view returns (address operator);
	function setApprovalForAll(address operator, bool _approved) external;
	function isApprovedForAll(address owner, address operator) external view returns (bool);
	function safeTransferFrom(address from, address to, uint256 tokenId, bytes calldata data) external;
}

interface IERC721Receiver {
	function onERC721Received(address operator, address from, uint256 tokenId, bytes calldata data) external returns (bytes4);
}

interface IERC721Metadata is IERC721 {
	function name() external view returns (string memory);
	function symbol() external view returns (string memory);
	function tokenURI(uint256 tokenId) external view returns (string memory);
}

abstract contract Context {
	function _msgSender() internal view virtual returns (address) {
		return msg.sender;
	}
	function _msgData() internal view virtual returns (bytes calldata) {
		this; // silence state mutability warning without generating bytecode - see https://github.com/ethereum/solidity/issues/2691
		return msg.data;
	}
}

abstract contract ERC165 is IERC165 {
	function supportsInterface(bytes4 interfaceId) public view virtual override returns (bool) {
		return interfaceId == type(IERC165).interfaceId;
	}
}

contract ERC721 is Context, ERC165, IERC721, IERC721Metadata {
	using Address for address;
	using Strings for uint256;
	string private _name;
	string private _symbol;
	mapping (uint256 => address) private _owners;
	mapping (address => uint256) private _balances;
	mapping (uint256 => address) private _tokenApprovals;
	mapping (address => mapping (address => bool)) private _operatorApprovals;
	constructor (string memory name_, string memory symbol_) {
		_name = name_;
		_symbol = symbol_;
	}
	function supportsInterface(bytes4 interfaceId) public view virtual override(ERC165, IERC165) returns (bool) {
		return interfaceId == type(IERC721).interfaceId || interfaceId == type(IERC721Metadata).interfaceId || super.supportsInterface(interfaceId);
	}
	function balanceOf(address owner) public view virtual override returns (uint256) {
		require(owner != address(0), "ERC721: balance query for the zero address");
		return _balances[owner];
	}
	function ownerOf(uint256 tokenId) public view virtual override returns (address) {
		address owner = _owners[tokenId];
		require(owner != address(0), "ERC721: owner query for nonexistent token");
		return owner;
	}
	function name() public view virtual override returns (string memory) {
		return _name;
	}
	function symbol() public view virtual override returns (string memory) {
		return _symbol;
	}
	function tokenURI(uint256 tokenId) public view virtual override returns (string memory) {
		require(_exists(tokenId), "ERC721Metadata: URI query for nonexistent token");
		string memory baseURI = _baseURI();
		return bytes(baseURI).length > 0 ? string(abi.encodePacked(baseURI, tokenId.toString())) : '';
	}
	function _baseURI() internal view virtual returns (string memory) {
		return "";
	}
	function approve(address to, uint256 tokenId) public virtual override {
		address owner = ERC721.ownerOf(tokenId);
		require(to != owner, "ERC721: approval to current owner");
		require(_msgSender() == owner || isApprovedForAll(owner, _msgSender()), "ERC721: approve caller is not owner nor approved for all");
		_approve(to, tokenId);
	}
	function getApproved(uint256 tokenId) public view virtual override returns (address) {
		require(_exists(tokenId), "ERC721: approved query for nonexistent token");
		return _tokenApprovals[tokenId];
	}
	function setApprovalForAll(address operator, bool approved) public virtual override {
		require(operator != _msgSender(), "ERC721: approve to caller");
		_operatorApprovals[_msgSender()][operator] = approved;
		emit ApprovalForAll(_msgSender(), operator, approved);
	}
	function isApprovedForAll(address owner, address operator) public view virtual override returns (bool) {
		return _operatorApprovals[owner][operator];
	}
	function transferFrom(address from, address to, uint256 tokenId) public virtual override {
		require(_isApprovedOrOwner(_msgSender(), tokenId), "ERC721: transfer caller is not owner nor approved");
		_transfer(from, to, tokenId);
	}
	function safeTransferFrom(address from, address to, uint256 tokenId) public virtual override {
		safeTransferFrom(from, to, tokenId, "");
	}
	function safeTransferFrom(address from, address to, uint256 tokenId, bytes memory _data) public virtual override {
		require(_isApprovedOrOwner(_msgSender(), tokenId), "ERC721: transfer caller is not owner nor approved");
		_safeTransfer(from, to, tokenId, _data);
	}
	function _safeTransfer(address from, address to, uint256 tokenId, bytes memory _data) internal virtual {
		_transfer(from, to, tokenId);
		require(_checkOnERC721Received(from, to, tokenId, _data), "ERC721: transfer to non ERC721Receiver implementer");
	}
	function _exists(uint256 tokenId) internal view virtual returns (bool) {
		return _owners[tokenId] != address(0);
	}
	function _isApprovedOrOwner(address spender, uint256 tokenId) internal view virtual returns (bool) {
		require(_exists(tokenId), "ERC721: operator query for nonexistent token");
		address owner = ERC721.ownerOf(tokenId);
		return (spender == owner || getApproved(tokenId) == spender || isApprovedForAll(owner, spender));
	}
	function _safeMint(address to, uint256 tokenId) internal virtual {
		_safeMint(to, tokenId, "");
	}
	function _safeMint(address to, uint256 tokenId, bytes memory _data) internal virtual {
		_mint(to, tokenId);
		require(_checkOnERC721Received(address(0), to, tokenId, _data), "ERC721: transfer to non ERC721Receiver implementer");
	}
	function _mint(address to, uint256 tokenId) internal virtual {
		require(to != address(0), "ERC721: mint to the zero address");
		require(!_exists(tokenId), "ERC721: token already minted");
		_beforeTokenTransfer(address(0), to, tokenId);
		_balances[to] += 1;
		_owners[tokenId] = to;
		emit Transfer(address(0), to, tokenId);
	}
	function _burn(uint256 tokenId) internal virtual {
		address owner = ERC721.ownerOf(tokenId);
		_beforeTokenTransfer(owner, address(0), tokenId);
		_approve(address(0), tokenId);
		_balances[owner] -= 1;
		delete _owners[tokenId];
		emit Transfer(owner, address(0), tokenId);
	}
	function _transfer(address from, address to, uint256 tokenId) internal virtual {
		require(ERC721.ownerOf(tokenId) == from, "ERC721: transfer of token that is not own");
		require(to != address(0), "ERC721: transfer to the zero address");
		_beforeTokenTransfer(from, to, tokenId);
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
	function _checkOnERC721Received(address from, address to, uint256 tokenId, bytes memory _data) private returns (bool)
	{
		if (to.isContract()) {
			try IERC721Receiver(to).onERC721Received(_msgSender(), from, tokenId, _data) returns (bytes4 retval) {
				return retval == IERC721Receiver(to).onERC721Received.selector;
			} catch (bytes memory reason) {
				if (reason.length == 0) {
					revert("ERC721: transfer to non ERC721Receiver implementer");
				} else {
					// solhint-disable-next-line no-inline-assembly
					assembly {
						revert(add(32, reason), mload(reason))
					}
				}
			}
		} else {
			return true;
		}
	}
	function _beforeTokenTransfer(address from, address to, uint256 tokenId) internal virtual { }
}

abstract contract Ownable is Context {
	address private _owner;
	event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);
	constructor () {
		address msgSender = _msgSender();
		_owner = msgSender;
		emit OwnershipTransferred(address(0), msgSender);
	}
	function owner() public view virtual returns (address) {
		return _owner;
	}
	modifier onlyOwner() {
		require(owner() == _msgSender(), "Ownable: caller is not the owner");
		_;
	}
	function renounceOwnership() public virtual onlyOwner {
		emit OwnershipTransferred(_owner, address(0));
		_owner = address(0);
	}
	function transferOwnership(address newOwner) public virtual onlyOwner {
		require(newOwner != address(0), "Ownable: new owner is the zero address");
		emit OwnershipTransferred(_owner, newOwner);
		_owner = newOwner;
	}
}

abstract contract ReentrancyGuard {
	uint256 private constant _NOT_ENTERED = 1;
	uint256 private constant _ENTERED = 2;
	uint256 private _status;
	constructor() {
		_status = _NOT_ENTERED;
	}
	modifier nonReentrant() {
		require(_status != _ENTERED, "ReentrancyGuard: reentrant call");
		_status = _ENTERED;
		_;
		_status = _NOT_ENTERED;
	}
}

library Strings {
	bytes16 private constant _HEX_SYMBOLS = "0123456789abcdef";
	function toString(uint256 value) internal pure returns (string memory) {
		if (value == 0) return "0";
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
	function toAsciiString(address x) internal pure returns (string memory) {
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
	function char(bytes1 b) internal pure returns (bytes1 c) {
		if (uint8(b) < 10) return bytes1(uint8(b) + 0x30);
		else return bytes1(uint8(b) + 0x57);
	}
}

library Base64 {
	bytes internal constant TABLE = "ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789+/";
	function encode(bytes memory data) internal pure returns (string memory) {
		uint256 len = data.length;
		if (len == 0) return "";
		uint256 encodedLen = 4 * ((len + 2) / 3);
		bytes memory result = new bytes(encodedLen + 32);
		bytes memory table = TABLE;
		assembly {
			let tablePtr := add(table, 1)
			let resultPtr := add(result, 32)

			for {
				let i := 0
			} lt(i, len) {
			} {
				i := add(i, 3)
				let input := and(mload(add(data, i)), 0xffffff)
				let out := mload(add(tablePtr, and(shr(18, input), 0x3F)))
				out := shl(8, out)
				out := add(out, and(mload(add(tablePtr, and(shr(12, input), 0x3F))), 0xFF))
				out := shl(8, out)
				out := add(out, and(mload(add(tablePtr, and(shr(6, input), 0x3F))), 0xFF))
				out := shl(8, out)
				out := add(out, and(mload(add(tablePtr, and(input, 0x3F))), 0xFF))
				out := shl(224, out)
				mstore(resultPtr, out)
				resultPtr := add(resultPtr, 4)
			}
			switch mod(len, 3)
			case 1 {
				mstore(sub(resultPtr, 2), shl(240, 0x3d3d))
			}
			case 2 {
				mstore(sub(resultPtr, 1), shl(248, 0x3d))
			}
			mstore(result, encodedLen)
		}
		return string(result);
	}
}

library DynamicBuffer {
	function allocate(uint256 capacity) internal pure returns (bytes memory buffer) {
		assembly {
			let container := mload(0x40)
			{
				let size := add(capacity, 0x60)
				let newNextFree := add(container, size)
				mstore(0x40, newNextFree)
			}
			{
				let length := add(capacity, 0x40)
				mstore(container, length)
			}
			buffer := add(container, 0x20)
			mstore(buffer, 0)
		}
		return buffer;
	}
	function appendUnchecked(bytes memory buffer, bytes memory data) internal pure {
		assembly {
			let length := mload(data)
			for {
				data := add(data, 0x20)
				let dataEnd := add(data, length)
				let copyTo := add(buffer, add(mload(buffer), 0x20))
			} lt(data, dataEnd) {
				data := add(data, 0x20)
				copyTo := add(copyTo, 0x20)
			} {
				mstore(copyTo, mload(data))
			}
			mstore(buffer, add(mload(buffer), length))
		}
	}
	function appendSafe(bytes memory buffer, bytes memory data) internal pure {
		uint256 capacity;
		uint256 length;
		assembly {
			capacity := sub(mload(sub(buffer, 0x20)), 0x40)
			length := mload(buffer)
		}
		require(length + data.length <= capacity, "DynamicBuffer: Appending out of bounds.");
		appendUnchecked(buffer, data);
	}
}

library Address {
	function isContract(address account) internal view returns (bool) {
		uint256 size;
		// solhint-disable-next-line no-inline-assembly
		assembly { size := extcodesize(account) }
		return size > 0;
	}
	function sendValue(address payable recipient, uint256 amount) internal {
		require(address(this).balance >= amount, "Address: insufficient balance");
		// solhint-disable-next-line avoid-low-level-calls, avoid-call-value
		(bool success, ) = recipient.call{ value: amount }("");
		require(success, "Address: unable to send value, recipient may have reverted");
	}
	function functionCall(address target, bytes memory data) internal returns (bytes memory) {
	  return functionCall(target, data, "Address: low-level call failed");
	}
	function functionCall(address target, bytes memory data, string memory errorMessage) internal returns (bytes memory) {
		return functionCallWithValue(target, data, 0, errorMessage);
	}
	function functionCallWithValue(address target, bytes memory data, uint256 value) internal returns (bytes memory) {
		return functionCallWithValue(target, data, value, "Address: low-level call with value failed");
	}
	function functionCallWithValue(address target, bytes memory data, uint256 value, string memory errorMessage) internal returns (bytes memory) {
		require(address(this).balance >= value, "Address: insufficient balance for call");
		require(isContract(target), "Address: call to non-contract");
		// solhint-disable-next-line avoid-low-level-calls
		(bool success, bytes memory returndata) = target.call{ value: value }(data);
		return _verifyCallResult(success, returndata, errorMessage);
	}
	function functionStaticCall(address target, bytes memory data) internal view returns (bytes memory) {
		return functionStaticCall(target, data, "Address: low-level static call failed");
	}
	function functionStaticCall(address target, bytes memory data, string memory errorMessage) internal view returns (bytes memory) {
		require(isContract(target), "Address: static call to non-contract");
		// solhint-disable-next-line avoid-low-level-calls
		(bool success, bytes memory returndata) = target.staticcall(data);
		return _verifyCallResult(success, returndata, errorMessage);
	}
	function functionDelegateCall(address target, bytes memory data) internal returns (bytes memory) {
		return functionDelegateCall(target, data, "Address: low-level delegate call failed");
	}
	function functionDelegateCall(address target, bytes memory data, string memory errorMessage) internal returns (bytes memory) {
		require(isContract(target), "Address: delegate call to non-contract");
		// solhint-disable-next-line avoid-low-level-calls
		(bool success, bytes memory returndata) = target.delegatecall(data);
		return _verifyCallResult(success, returndata, errorMessage);
	}
	function _verifyCallResult(bool success, bytes memory returndata, string memory errorMessage) private pure returns(bytes memory) {
		if (success) {
			return returndata;
		} else {
			if (returndata.length > 0) {
				// solhint-disable-next-line no-inline-assembly
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

contract PiSpace is ERC721, ReentrancyGuard, Ownable
{
	using Strings for int;
	using Strings for uint;
	using Strings for bytes32;
	using DynamicBuffer for bytes;

	bool public sale_active = false;
	uint public sale_price = 0.0314 ether;
	uint public max_supply = 314;
	uint public pies_baked = 0;

	string[] blend_modes = ["overlay", "lighten", "multiply"];

	mapping(uint => string) public pie_ingredients;


	/**
	 * @dev Setup all the variables for the Traits and the Collection.
	 */
	constructor() ERC721("Pi-Space", "PIES") {}


	/**
	* @dev Calculate the total amount minted so far.
	*/
	function totalSupply() public view returns (uint)
	{
		return pies_baked;
	}


	/**
	 * @dev Bake a Pi-Space and add the ingredients to the mapping.
	 */
	function bake() public payable nonReentrant
	{
		// require(totalSupply() < max_supply, "All the Pies have already been baked.");
		// require(sale_active, "The Pies are not on sale at the moment.");
		// require(msg.value >= sale_price, "Insufficient funds to bake a Pie.");

		uint pie = totalSupply() + 1;

		string memory ingredients = prepareIngredients(msg.sender);

		_safeMint(msg.sender, pie);

		pie_ingredients[pie] = ingredients;
		pies_baked++;
	}


	/**
	 * @dev Generate the random seed for the `_pie`.
	 */
	function prepareIngredients(address _sender) internal view returns (string memory)
	{
		uint balance = this.balanceOf(_sender);
		address address_string;

		if (balance > 0)
		{
			address_string = address(uint160(uint(keccak256(abi.encodePacked(_sender, balance.toString())))));
		}
		else
		{
			address_string = _sender;
		}

		return Strings.toAsciiString(address_string);
	}


	/**
	 * @dev Get the Ingredients for the `_pie`.
	 */
	function getIngredients(uint _pie) public view returns (string memory)
	{
		return pie_ingredients[_pie];
	}


	/**
	 * @dev Output the svg in the json array for the lols.
	 */
	function tokenURI(uint _pie) public view override returns (string memory)
	{
		require(_exists(_pie), "This Pie doesn't exist.");

		string memory ingredients = getIngredients(_pie);
		string[] memory colours = new string[](6);

		uint num_circles = rand(ingredients, 0, 13) + 10;

		colours[0] = "ffffff";
		colours[1] = getSliceFromBytesString(ingredients, 0, 6);
		colours[2] = getSliceFromBytesString(ingredients, 2, 6);
		colours[3] = getSliceFromBytesString(ingredients, 20, 6);
		colours[4] = getSliceFromBytesString(ingredients, 22, 6);
		colours[5] = getSliceFromBytesString(ingredients, 32, 6);

		bytes memory svg = generateSVG(_pie, ingredients, num_circles, colours);

		string memory json = string(abi.encodePacked(
			'data:application/json,{"name":"Pi-Space #',
			bytes(_pie.toString()),
			'","description":"Pi-Space is the second blockchain generative art project from Rant&Code. Each piece is generated using unique data from the wallet used to mint it.\\n\\n[Website](https://rantandcode.co.uk/pi-space) | [Twitter](https://twitter.com/rantandcode_)","image":"data:image/svg+xml;base64,',
			bytes(Base64.encode(svg)),
			'","attributes":[{"trait_type": "Circles", "value": "',
			bytes(num_circles.toString()),
			'"},{"trait_type": "Colour 1", "value": "#',
			colours[1],
			'"},{"trait_type": "Colour 2", "value": "#',
			colours[2],
			'"},{"trait_type": "Colour 3", "value": "#',
			colours[3],
			'"},{"trait_type": "Colour 4", "value": "#',
			colours[4],
			'"},{"trait_type": "Background", "value": "#',
			colours[5],
			'"}], "background_color": "#',
			colours[5],
			'"}'
		));

		return json;
	}


	/**
	 * @dev Build the entire SVG using the randomly generated attributes/traits.
	 */
	function generateSVG(uint _pie, string memory _ingredients, uint _num_circles, string[] memory _colours) internal view returns (bytes memory)
	{
		bytes memory svg = abi.encodePacked(
			'<svg id="ps',
			bytes(_pie.toString()),
			'" xmlns="http://www.w3.org/2000/svg" width="1200" height="1200" viewBox="0 0 1200 1200" style="background-color:#',
			_colours[5],
			';" class="max-w-full">',
			generateSVGStyles(_pie, _ingredients),
			generateSVGCircles(_ingredients, _num_circles, _colours, 3),
			'</svg>'
		);

		return svg;
	}


	/**
	 * @dev Build the animations for the Pie using random variables from the `_ingredients`.
	 */
	function generateSVGStyles(uint _pie, string memory _ingredients) internal pure returns (bytes memory)
	{
		bytes memory svg = abi.encodePacked(
			'<style>#ps',
			bytes(_pie.toString()),
			' circle{transform-origin: center;}#ps',
			bytes(_pie.toString()),
			' circle:nth-child(3n){animation:aS ',
			(17 + rand(_ingredients, 1, 5)).toString(), // duration
			's ease-in-out ',
			rand(_ingredients, 2, 5).toString(), // delay
			's infinite alternate both;}#ps',
			bytes(_pie.toString()),
			' circle:nth-child(5n){animation:aX ',
			(23 + rand(_ingredients, 3, 5)).toString(), // duration
			's ease-in-out ',
			rand(_ingredients, 4, 3).toString(), // delay
			's infinite alternate both;}#ps',
			bytes(_pie.toString()),
			' circle:nth-child(7n){animation:aY ',
			(29 + rand(_ingredients, 5, 5)).toString(), // duration
			's linear ',
			(8 + rand(_ingredients, 6, 4)).toString(), // delay
			's infinite alternate both;}@keyframes aS{0%{transform:scale(1);}100%{transform:scale(1.314);}}@keyframes aX{0%{transform:translateX(0) scale(1);}100%{transform:translateX(131px) scale(3.14);}}@keyframes aY{0%{transform:translateY(0);}100%{transform:translateY(-31px);}}</style>'
		);

		return svg;
	}


	/**
	 * @dev Loop through and add `_num_circles` circles to the SVG using random variables from the `_ingredients`.
	 */
	function generateSVGCircles(string memory _ingredients, uint _num_circles, string[] memory _colours, uint _nonce) internal view returns (bytes memory)
	{
		uint i;
		bytes memory svg;

		for (i = 0; i < _num_circles;)
		{
			svg = abi.encodePacked(
				svg,
				'<circle cx="',
				bytes(rand(_ingredients, (++_nonce), 1200).toString()),
				'" cy="',
				bytes(rand(_ingredients, (++_nonce), 1200).toString()),
				'" r="',
				bytes(rand(_ingredients, (++_nonce), 800).toString()),
				'" fill="#',
				_colours[rand(_ingredients, (++_nonce), _colours.length)],
				'" style="mix-blend-mode: ',
				blend_modes[rand(_ingredients, (++_nonce), blend_modes.length)],
				'; opacity: 0.',
				bytes((rand(_ingredients, (++_nonce), 65) + 10).toString()),
				';"></circle>'
			);

			unchecked { i++; }
		}

		return svg;
	}


	/**
	 * @dev Get a random number from the `_seed` using `_mod` to limit it.
	 */
	function rand(string memory _seed, uint _nonce, uint _mod) internal pure returns (uint256)
	{
		return uint256(keccak256(abi.encode(_seed, _nonce))) % _mod;
	}


	/**
	 * @dev Return a slice of `_length` characters from the given `_string`.
	 */
	function getSliceFromBytesString(string memory _string, uint _offset, uint _length) internal pure returns (string memory)
	{
		bytes memory characters = bytes(_string);

		bytes memory slice = new bytes(_length);

		for (uint i=0; i<_length;)
		{
			slice[i] = characters[_offset + i];

			unchecked { i++; }
		}

		return string(slice);
	}


	/**
	* @dev Toggle the Sale state.
	*/
	function toggleSaleState() public onlyOwner
	{
		sale_active = !sale_active;
	}


	/**
	 * @dev Allow withdrawal of funds to the Owner's wallet.
	 */
	function withdrawFunds() public payable onlyOwner
	{
		(bool success, ) = payable(msg.sender).call{value: address(this).balance}("");
		require(success);
	}
}