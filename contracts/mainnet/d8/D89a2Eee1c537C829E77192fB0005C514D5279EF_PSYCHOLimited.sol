// SPDX-License-Identifier: AGPL-3.0-only

pragma solidity ^0.8.4;

import "../../interface/IERC173.sol";
import "../../interface/extensions/IOperator.sol";
import "../../interface/errors/IERC173Errors.sol";
import "../../interface/errors/extensions/IOperatorErrors.sol";

contract Operator is IERC173, IOperator, IERC173Errors, IOperatorErrors {
	address private _owner;
	address private _operator;

	constructor(address owner_) {
		_transferOwnership(owner_);
	}

	modifier ownership() {
		if (owner() != msg.sender) {
			revert NonOwnership(owner(), msg.sender);
		}
		_;
	}

	modifier operatorship() {
		if (owner() == msg.sender || operator() == msg.sender) {
			_;
		} else {
			revert NonOperator(operator(), msg.sender);
		}
	}

	function transferOwnership(
		address _to
	) public virtual override(IERC173) ownership {
		if (_to == address(0)) {
			revert TransferOwnershipToZeroAddress(owner(), _to);
		}
		_transferOwnership(_to);
	}

	function transferOperatorship(
		address _to
	) public virtual override(IOperator) ownership {
		_transferOperatorship(_to);
	}

	function owner() public view virtual override(IERC173) returns (address) {
		return _owner;
	}

	function operator()
		public
		view
		virtual
		override(IOperator)
		returns (address)
	{
		return _operator;
	}

	function _transferOwnership(address _to) internal virtual {
		address _from = _owner;
		_owner = _to;
		delete _operator;
		emit OwnershipTransferred(_from, _to);
	}

	function _transferOperatorship(address _to) internal virtual {
		address _from = _operator;
		_operator = _to;
		emit OperatorshipTransferred(_from, _to);
	}
}

// SPDX-License-Identifier: AGPL-3.0-only

pragma solidity ^0.8.4;

interface IOperatorErrors {
	error NonOperator(address _operator, address _sender);
}

// SPDX-License-Identifier: AGPL-3.0-only

pragma solidity ^0.8.4;

interface IERC173Errors {
	error NonOwnership(address _owner, address _sender);

	error TransferOwnershipToZeroAddress(address _from, address _to);
}

// SPDX-License-Identifier: AGPL-3.0-only

pragma solidity ^0.8.4;

interface IERC721Errors {
	error NonApprovedNonOwner(
		bool _isApprovedForAll,
		address _getApproved,
		address _ownerOf,
		address _sender
	);

	error FromAddressNonOwner(address _from, address _ownerOf);

	error NonOwnerApproval(address _ownerOf, address _sender);

	error CannotApproveOwner(address _ownerOf, address _approved);

	error TransferToZeroAddress(address _from, address _to, uint256 _tokenId);

	error TransferToNonERC721Receiver(address _contract);

	error TxOriginNonSender(address _origin, address _sender);
}

// SPDX-License-Identifier: AGPL-3.0-only

pragma solidity ^0.8.4;

interface IOperator {
	event OperatorshipTransferred(address indexed _from, address indexed _to);

	function operator() external view returns (address);

	function transferOperatorship(address _to) external;
}

// SPDX-License-Identifier: AGPL-3.0-only

pragma solidity ^0.8.4;

interface IERC165 {
	function supportsInterface(bytes4 interfaceId) external view returns (bool);
}

// SPDX-License-Identifier: AGPL-3.0-only

pragma solidity ^0.8.4;

interface IERC173 {
	event OwnershipTransferred(address indexed _from, address indexed _to);

	function owner() external view returns (address);

	function transferOwnership(address _to) external;
}

// SPDX-License-Identifier: AGPL-3.0-only

pragma solidity ^0.8.4;

interface IERC721 {
	event Transfer(
		address indexed _from,
		address indexed _to,
		uint256 indexed _tokenId
	);

	event Approval(
		address indexed _owner,
		address indexed _approved,
		uint256 indexed _tokenId
	);

	event ApprovalForAll(
		address indexed _owner,
		address indexed _operator,
		bool _approved
	);

	function balanceOf(address _owner) external view returns (uint256);

	function ownerOf(uint256 _tokenId) external view returns (address);

	function safeTransferFrom(
		address _from,
		address _to,
		uint256 _tokenId,
		bytes calldata _data
	) external;

	function safeTransferFrom(
		address _from,
		address _to,
		uint256 _tokenId
	) external;

	function transferFrom(
		address _from,
		address _to,
		uint256 _tokenId
	) external;

	function approve(address _to, uint256 _tokenId) external;

	function setApprovalForAll(address _operator, bool _approved) external;

	function getApproved(uint256 _tokenId) external view returns (address);

	function isApprovedForAll(
		address _owner,
		address _operator
	) external view returns (bool);
}

// SPDX-License-Identifier: AGPL-3.0-only

pragma solidity ^0.8.4;

interface IERC721Metadata {
	function name() external view returns (string memory);

	function symbol() external view returns (string memory);

	function tokenURI(uint256 _tokenId) external view returns (string memory);
}

// SPDX-License-Identifier: AGPL-3.0-only

pragma solidity ^0.8.4;

interface IERC721Receiver {
	function onERC721Received(
		address _operator,
		address _from,
		uint256 _tokenId,
		bytes calldata _data
	) external returns (bytes4);
}

// SPDX-License-Identifier: AGPL-3.0-only

pragma solidity ^0.8.4;

import "./Log.sol";

library Encode {
	string internal constant _TABLE =
		"ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789+/";
	bytes16 private constant _SYMBOLS = "0123456789abcdef";
	uint8 private constant _ADDRESS_LENGTH = 20;

	function toBase64(
		bytes memory _data
	) internal pure returns (string memory) {
		if (_data.length == 0) return "";
		string memory table = _TABLE;
		string memory result = new string(4 * ((_data.length + 2) / 3));
		assembly {
			let tablePtr := add(table, 1)
			let resultPtr := add(result, 32)
			for {
				let dataPtr := _data
				let endPtr := add(_data, mload(_data))
			} lt(dataPtr, endPtr) {

			} {
				dataPtr := add(dataPtr, 3)
				let input := mload(dataPtr)
				mstore8(
					resultPtr,
					mload(add(tablePtr, and(shr(18, input), 0x3F)))
				)
				resultPtr := add(resultPtr, 1)
				mstore8(
					resultPtr,
					mload(add(tablePtr, and(shr(12, input), 0x3F)))
				)
				resultPtr := add(resultPtr, 1)
				mstore8(
					resultPtr,
					mload(add(tablePtr, and(shr(6, input), 0x3F)))
				)
				resultPtr := add(resultPtr, 1)
				mstore8(resultPtr, mload(add(tablePtr, and(input, 0x3F))))
				resultPtr := add(resultPtr, 1)
			}
			switch mod(mload(_data), 3)
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

	function toBytes32(string memory _string) internal pure returns (bytes32) {
		return keccak256(abi.encodePacked(_string));
	}

	function toString(uint256 _value) internal pure returns (string memory) {
		unchecked {
			uint256 _ptr;
			uint256 _length = Log.log10(_value) + 1;
			string memory buffer = new string(_length);
			assembly {
				_ptr := add(buffer, add(32, _length))
			}
			while (true) {
				_ptr--;
				assembly {
					mstore8(_ptr, byte(mod(_value, 10), _SYMBOLS))
				}
				_value /= 10;
				if (_value == 0) break;
			}
			return buffer;
		}
	}

	function toHexString(uint256 _value) internal pure returns (string memory) {
		unchecked {
			return toHexString(_value, Log.log256(_value) + 1);
		}
	}

	function toHexString(address _addr) internal pure returns (string memory) {
		return toHexString(uint256(uint160(_addr)), _ADDRESS_LENGTH);
	}

	function toHexString(
		uint256 _value,
		uint256 _length
	) internal pure returns (string memory) {
		bytes memory buffer = new bytes(2 * _length + 2);
		buffer[0] = "0";
		buffer[1] = "x";
		for (uint256 i = 2 * _length + 1; i > 1; --i) {
			buffer[i] = _SYMBOLS[_value & 0xf];
			_value >>= 4;
		}
		require(_value == 0);
		return string(buffer);
	}
}

// SPDX-License-Identifier: AGPL-3.0-only

pragma solidity ^0.8.4;

library Log {
	function log2(uint256 _value) internal pure returns (uint256) {
		uint256 result = 0;
		unchecked {
			if (_value >> 128 > 0) {
				_value >>= 128;
				result += 128;
			}
			if (_value >> 64 > 0) {
				_value >>= 64;
				result += 64;
			}
			if (_value >> 32 > 0) {
				_value >>= 32;
				result += 32;
			}
			if (_value >> 16 > 0) {
				_value >>= 16;
				result += 16;
			}
			if (_value >> 8 > 0) {
				_value >>= 8;
				result += 8;
			}
			if (_value >> 4 > 0) {
				_value >>= 4;
				result += 4;
			}
			if (_value >> 2 > 0) {
				_value >>= 2;
				result += 2;
			}
			if (_value >> 1 > 0) {
				result += 1;
			}
		}
		return result;
	}

	function log10(uint256 _value) internal pure returns (uint256) {
		uint256 result = 0;
		unchecked {
			if (_value >= 10 ** 64) {
				_value /= 10 ** 64;
				result += 64;
			}
			if (_value >= 10 ** 32) {
				_value /= 10 ** 32;
				result += 32;
			}
			if (_value >= 10 ** 16) {
				_value /= 10 ** 16;
				result += 16;
			}
			if (_value >= 10 ** 8) {
				_value /= 10 ** 8;
				result += 8;
			}
			if (_value >= 10 ** 4) {
				_value /= 10 ** 4;
				result += 4;
			}
			if (_value >= 10 ** 2) {
				_value /= 10 ** 2;
				result += 2;
			}
			if (_value >= 10 ** 1) {
				result += 1;
			}
		}
		return result;
	}

	function log256(uint256 _value) internal pure returns (uint256) {
		uint256 result = 0;
		unchecked {
			if (_value >> 128 > 0) {
				_value >>= 128;
				result += 16;
			}
			if (_value >> 64 > 0) {
				_value >>= 64;
				result += 8;
			}
			if (_value >> 32 > 0) {
				_value >>= 32;
				result += 4;
			}
			if (_value >> 16 > 0) {
				_value >>= 16;
				result += 2;
			}
			if (_value >> 8 > 0) {
				result += 1;
			}
		}
		return result;
	}
}

// SPDX-License-Identifier: AGPL-3.0-only

pragma solidity ^0.8.4;

import "../interface/IERC165.sol";

contract ERC165 is IERC165 {
	function supportsInterface(
		bytes4 interfaceId
	) public pure virtual override(IERC165) returns (bool) {
		return interfaceId == type(IERC165).interfaceId;
	}
}

// SPDX-License-Identifier: AGPL-3.0-only

pragma solidity ^0.8.4;

import "../interface/IERC721.sol";
import "../interface/errors/IERC721Errors.sol";
import "../interface/receiver/IERC721Receiver.sol";

contract ERC721 is IERC721, IERC721Errors {
	uint256 private _currentId;
	uint256 private _subtractId;
	mapping(address => uint256) private _balanceOf;
	mapping(uint256 => address) private _ownerOf;
	mapping(uint256 => address) private _getApproved;
	mapping(address => mapping(address => bool)) private _isApprovedForAll;

	function balanceOf(
		address _owner
	) public view virtual override(IERC721) returns (uint256) {
		return _balanceOf[_owner];
	}

	function ownerOf(
		uint256 _tokenId
	) public view virtual override(IERC721) returns (address) {
		return _ownerOf[_tokenId];
	}

	function safeTransferFrom(
		address _from,
		address _to,
		uint256 _tokenId
	) public virtual override(IERC721) {
		safeTransferFrom(_from, _to, _tokenId, "");
	}

	function safeTransferFrom(
		address _from,
		address _to,
		uint256 _tokenId,
		bytes memory _data
	) public virtual override(IERC721) {
		if (!_isApprovedOrOwner(msg.sender, _tokenId)) {
			revert NonApprovedNonOwner(
				_isApprovedForAll[_ownerOf[_tokenId]][msg.sender],
				_getApproved[_tokenId],
				_ownerOf[_tokenId],
				msg.sender
			);
		}
		_transfer(_from, _to, _tokenId);
		_onERC721Received(_from, _to, _tokenId, _data);
	}

	function transferFrom(
		address _from,
		address _to,
		uint256 _tokenId
	) public virtual override(IERC721) {
		if (!_isApprovedOrOwner(msg.sender, _tokenId)) {
			revert NonApprovedNonOwner(
				_isApprovedForAll[_ownerOf[_tokenId]][msg.sender],
				_getApproved[_tokenId],
				_ownerOf[_tokenId],
				msg.sender
			);
		}
		_transfer(_from, _to, _tokenId);
	}

	function approve(
		address _to,
		uint256 _tokenId
	) public virtual override(IERC721) {
		if (_ownerOf[_tokenId] != msg.sender) {
			revert NonOwnerApproval(_ownerOf[_tokenId], msg.sender);
		}
		if (_ownerOf[_tokenId] == _to) {
			revert CannotApproveOwner(_ownerOf[_tokenId], _to);
		}
		_getApproved[_tokenId] = _to;
		emit Approval(msg.sender, _to, _tokenId);
	}

	function setApprovalForAll(
		address _operator,
		bool _approved
	) public virtual override(IERC721) {
		if (msg.sender == _operator) {
			revert CannotApproveOwner(msg.sender, _operator);
		}
		_isApprovedForAll[msg.sender][_operator] = _approved;
		emit ApprovalForAll(msg.sender, _operator, _approved);
	}

	function getApproved(
		uint256 _tokenId
	) public view virtual override(IERC721) returns (address) {
		return _getApproved[_tokenId];
	}

	function isApprovedForAll(
		address _owner,
		address _operator
	) public view virtual override(IERC721) returns (bool) {
		return _isApprovedForAll[_owner][_operator];
	}

	function totalSupply() public view virtual returns (uint256) {
		return _currentId - _subtractId;
	}

	function _mintHook(uint256 _tokenId) internal virtual {}

	function _burnHook(uint256 _tokenId) internal virtual {}

	function _transferHook(
		address _from,
		address _to,
		uint256 _tokenId
	) internal virtual {}

	function _isApprovedOrOwner(
		address _address,
		uint256 _tokenId
	) internal view virtual returns (bool) {
		return
			_ownerOf[_tokenId] == _address ||
			_isApprovedForAll[_ownerOf[_tokenId]][_address] ||
			_getApproved[_tokenId] == _address;
	}

	function _transfer(
		address _from,
		address _to,
		uint256 _tokenId
	) internal virtual {
		if (_from != _ownerOf[_tokenId]) {
			revert FromAddressNonOwner(_from, _ownerOf[_tokenId]);
		}
		if (_to == address(0)) {
			revert TransferToZeroAddress(_from, _to, _tokenId);
		}
		delete _getApproved[_tokenId];
		unchecked {
			_balanceOf[_from] -= 1;
			_balanceOf[_to] += 1;
		}
		_ownerOf[_tokenId] = _to;
		_transferHook(_from, _to, _tokenId);
		emit Transfer(_from, _to, _tokenId);
	}

	function _totalMinted() internal view virtual returns (uint256) {
		return _currentId;
	}

	function _totalBurned() internal view virtual returns (uint256) {
		return _subtractId;
	}

	function _safeMint(address _to) internal virtual {
		_safeMint(_to, "");
	}

	function _safeMint(address _to, bytes memory _data) internal virtual {
		_mint(_to, 1);
		if (!_onERC721Received(address(0), _to, _currentId, _data)) {
			revert TransferToNonERC721Receiver(_to);
		}
	}

	function _eoaMint(address _to, uint256 _quantity) internal virtual {
		if (tx.origin != msg.sender) {
			revert TxOriginNonSender(tx.origin, msg.sender);
		}
		_mint(_to, _quantity);
	}

	function _mint(address _to, uint256 _quantity) internal virtual {
		unchecked {
			for (uint256 i = 0; i < _quantity; i++) {
				uint256 _tokenId = _currentId + i + 1;
				_mintHook(_tokenId);
				_ownerOf[_tokenId] = _to;
				emit Transfer(address(0), _to, _tokenId);
			}
			_balanceOf[_to] += _quantity;
			_currentId += _quantity;
		}
	}

	function _burn(address _from, uint256 _tokenId) internal virtual {
		if (_from != _ownerOf[_tokenId]) {
			revert FromAddressNonOwner(_from, _ownerOf[_tokenId]);
		}
		delete _getApproved[_tokenId];
		_ownerOf[_tokenId] = address(0);
		unchecked {
			_balanceOf[_from] -= 1;
			_subtractId += 1;
		}
		_burnHook(_tokenId);
		emit Transfer(_from, address(0), _tokenId);
	}

	function _onERC721Received(
		address _from,
		address _to,
		uint256 _tokenId,
		bytes memory _data
	) private returns (bool) {
		if (_to.code.length > 0) {
			try
				IERC721Receiver(_to).onERC721Received(
					msg.sender,
					_from,
					_tokenId,
					_data
				)
			returns (bytes4 retval) {
				return retval == IERC721Receiver.onERC721Received.selector;
			} catch (bytes memory reason) {
				if (reason.length == 0) {
					revert TransferToNonERC721Receiver(_to);
				} else {
					assembly {
						revert(add(32, reason), mload(reason))
					}
				}
			}
		} else {
			return true;
		}
	}
}

// SPDX-License-Identifier: AGPL-3.0-only

pragma solidity ^0.8.4;

import "../ERC721.sol";
import "../../interface/metadata/IERC721Metadata.sol";
import "../../library/Encode.sol";

contract ERC721Metadata is ERC721, IERC721Metadata {
	string private _name;
	string private _symbol;

	constructor(string memory name_, string memory symbol_) {
		_name = name_;
		_symbol = symbol_;
	}

	function name()
		public
		view
		virtual
		override(IERC721Metadata)
		returns (string memory)
	{
		return _name;
	}

	function symbol()
		public
		view
		virtual
		override(IERC721Metadata)
		returns (string memory)
	{
		return _symbol;
	}

	function tokenURI(
		uint256 _tokenId
	) public view virtual override(IERC721Metadata) returns (string memory) {
		bytes memory data;
		if (_customTokenURI(_tokenId).length == 0) {
			if (_extendedTokenURI(_tokenId).length == 0) {
				data = abi.encodePacked("{", _baseTokenURI(_tokenId), "}");
			} else {
				data = abi.encodePacked(
					"{",
					_baseTokenURI(_tokenId),
					",",
					_extendedTokenURI(_tokenId),
					"}"
				);
			}
		} else {
			data = abi.encodePacked(
				"{",
				_baseTokenURI(_tokenId),
				",",
				_customTokenURI(_tokenId),
				"}"
			);
		}
		if (ownerOf(_tokenId) == address(0)) {
			return "INVALID_ID";
		} else {
			return
				string(
					abi.encodePacked(
						"data:application/json;base64,",
						Encode.toBase64(data)
					)
				);
		}
	}

	function _baseTokenURI(
		uint256 _tokenId
	) internal view virtual returns (bytes memory) {
		return
			abi.encodePacked(
				'"name":"',
				name(),
				" #",
				Encode.toString(_tokenId),
				'"'
			);
	}

	function _extendedTokenURI(
		uint256 _tokenId
	) internal view virtual returns (bytes memory) {}

	function _customTokenURI(
		uint256 _tokenId
	) internal view virtual returns (bytes memory) {}
}

// SPDX-License-Identifier: AGPL-3.0-only

pragma solidity ^0.8.4;

/// @title PSYCHO Limited
/// @notice A network of fashionable (limited) avatars
interface IPSYCHOLimited {
	/// @notice Mints up to 1001 avatars
	/// @param _quantity max 20 per transaction
	/// @dev Requires `fee(_quantity)` and `stock() != 0`
	function mint(uint256 _quantity) external payable;

	/// @notice Set custom metadata for an avatar
	/// @param _avatarId to customize must be owner or approved owner
	/// @param _image should be URL or "" to reset metadata properties
	/// @param _animation should be URL or "" to remove this metadata property
	/// @dev Requires minimum `fee(1)`
	function metadata(
		uint256 _avatarId,
		string memory _image,
		string memory _animation
	) external payable;

	/// @notice Mint and metadata fee
	/// @param _quantity multiplied by mint quantity or 1 for metadata
	/// @return Wei fee
	function fee(uint256 _quantity) external view returns (uint256);

	/// @notice Available public avatars to mint
	/// @return Avatar stock
	function stock() external view returns (uint256);

	/// @notice Available reserved avatars to mint
	/// @return Avatar chest
	function chest() external view returns (uint256);
}

// SPDX-License-Identifier: AGPL-3.0-only

pragma solidity ^0.8.4;

interface IPSCYHOLimitedErrors {
	error ExceedsMintLimit(uint256 _excess);

	error ExceedsStockLimit(uint256 _excess);

	error FundAccount(uint256 _required);
}

// SPDX-License-Identifier: AGPL-3.0-only

pragma solidity ^0.8.4;

import "./IPSYCHOLimited.sol";
import "./PSYCHOSetup.sol";

/// @title See {IPSYCHOLimited}
/// @notice See {IPSYCHOLimited}
contract PSYCHOLimited is IPSYCHOLimited, PSYCHOSetup {
	/// @dev See {IPSYCHOLimited-mint}
	function mint(uint256 _quantity) public payable override(IPSYCHOLimited) {
		if (!_isOwnerOrOperator(msg.sender)) {
			if (msg.value < _fee(_quantity)) {
				revert FundAccount(_fee(_quantity) - msg.value);
			}
			if (_quantity > _stock()) {
				revert ExceedsStockLimit(_quantity - _stock());
			}
			if (_quantity > 20) {
				revert ExceedsMintLimit(_quantity - 20);
			}
			_addStockCount(_quantity);
		} else {
			if (_quantity > _chest()) {
				revert ExceedsChestLimit(_quantity - _chest());
			}
			_addChestCount(_quantity);
		}
		_eoaMint(msg.sender, _quantity);
	}

	/// @dev See {IPSYCHOLimited-metadata}
	function metadata(
		uint256 _avatarId,
		string memory _image,
		string memory _animation
	) public payable override(IPSYCHOLimited) {
		if (!_isApprovedOrOwner(msg.sender, _avatarId)) {
			revert NonApprovedNonOwner(
				isApprovedForAll(ownerOf(_avatarId), msg.sender),
				getApproved(_avatarId),
				ownerOf(_avatarId),
				msg.sender
			);
		}
		if (!_isOwnerOrOperator(msg.sender)) {
			if (msg.value < _fee(1)) {
				revert FundAccount(_fee(1) - msg.value);
			}
		}
		if (abi.encodePacked(_animation).length == 0) {
			_setCustomImage(_avatarId, _image);
		} else {
			_setCustomImage(_avatarId, _image);
			_setCustomAnimation(_avatarId, _animation);
		}
	}

	/// @dev See {IPSYCHOLimited-fee}
	function fee(
		uint256 _multiplier
	) public view override(IPSYCHOLimited) returns (uint256) {
		return _fee(_multiplier);
	}

	/// @dev See {IPSYCHOLimited-stock}
	function stock() public view override(IPSYCHOLimited) returns (uint256) {
		return _stock();
	}

	/// @dev See {IPSYCHOLimited-chest}
	function chest() public view override(IPSYCHOLimited) returns (uint256) {
		return _chest();
	}
}

// SPDX-License-Identifier: AGPL-3.0-only

pragma solidity ^0.8.4;

import "@0xver/solver/supports/ERC165.sol";
import "@0xver/solver/auth/extensions/Operator.sol";
import "@0xver/solver/token/metadata/ERC721Metadata.sol";
import "./IPSYCHOLimitedErrors.sol";

contract PSYCHOSetup is IPSCYHOLimitedErrors, ERC165, Operator, ERC721Metadata {
	error ExceedsChestLimit(uint256 _excess);
	error InitiatedStatus(bool _status);

	bool private _initiated = false;
	bool private _locked = false;

	uint256 private _stockCount = 0;
	uint256 private _chestCount = 0;
	uint256 private _weiFee = 66600000000000000;

	mapping(uint256 => uint256) private _block;
	mapping(uint256 => string) private _customImage;
	mapping(uint256 => string) private _customAnimation;

	event Withdraw(address operator, address receiver, uint256 value);

	receive() external payable {}

	fallback() external payable {}

	constructor()
		ERC721Metadata("PSYCHO Limited", "PSYCHO")
		Operator(msg.sender)
	{
		_mint(msg.sender, 1);
		_addChestCount(1);
	}

	function supportsInterface(
		bytes4 interfaceId
	) public pure virtual override(ERC165) returns (bool) {
		return
			interfaceId == type(IERC173).interfaceId ||
			interfaceId == type(IERC721).interfaceId ||
			interfaceId == type(IERC721Receiver).interfaceId ||
			interfaceId == type(IERC721Metadata).interfaceId ||
			super.supportsInterface(interfaceId);
	}

	function withdraw(address _to) public ownership {
		_withdraw(_to);
	}

	function initialize() public ownership {
		if (_initiated == false) {
			_initiated = true;
		} else {
			revert InitiatedStatus(_initiated);
		}
	}

	function setFee(uint256 _wei) public ownership {
		_weiFee = _wei;
	}

	function _initialized() internal view returns (bool) {
		if (totalSupply() != 1101) {
			return _initiated;
		} else {
			return false;
		}
	}

	function _fee(uint256 _multiplier) internal view returns (uint256) {
		return _weiFee * _multiplier;
	}

	function _stock() internal view returns (uint256) {
		if (_initialized()) {
			return 1001 - _stockCount;
		} else {
			return 0;
		}
	}

	function _chest() public view returns (uint256) {
		return 100 - _chestCount;
	}

	function _addStockCount(uint256 _amount) internal {
		unchecked {
			_stockCount += _amount;
		}
	}

	function _addChestCount(uint256 _amount) internal {
		unchecked {
			_chestCount += _amount;
		}
	}

	function _isOwnerOrOperator(address _address) internal view returns (bool) {
		return owner() == _address || operator() == _address;
	}

	function _mintHook(uint256 _avatarId) internal override(ERC721) {
		_block[_avatarId] = block.number;
	}

	function _extendedTokenURI(
		uint256 _avatarId
	) internal view override(ERC721Metadata) returns (bytes memory) {
		return
			abi.encodePacked(
				_description(_avatarId),
				',"image":"ipfs://bafybeidob7iaynjg6h6c3igqnac2qnprlzsfatybuqkxhcizcgpfowwgm4",',
				'"animation_url":"ipfs://bafybeihmygiurvygn7oaruaz66njkvlicbfg7lnsc64ttxbc3o3x4fezfi",',
				_attributes(_avatarId)
			);
	}

	function _customTokenURI(
		uint256 _avatarId
	) internal view override(ERC721Metadata) returns (bytes memory) {
		if (abi.encodePacked(_customImage[_avatarId]).length == 0) {
			return "";
		} else {
			return
				abi.encodePacked(
					_description(_avatarId),
					",",
					_customExtension(_avatarId),
					",",
					_attributes(_avatarId)
				);
		}
	}

	function _customExtension(
		uint256 _avatarId
	) internal view returns (bytes memory) {
		if (abi.encodePacked(_customAnimation[_avatarId]).length == 0) {
			return abi.encodePacked('"image":', _customImage[_avatarId]);
		} else {
			return
				abi.encodePacked(
					'"image":',
					_customImage[_avatarId],
					',"animation_url":',
					_customAnimation[_avatarId]
				);
		}
	}

	function _setCustomImage(uint256 _avatarId, string memory _url) internal {
		_customImage[_avatarId] = _url;
	}

	function _setCustomAnimation(
		uint256 _avatarId,
		string memory _url
	) internal {
		_customAnimation[_avatarId] = _url;
	}

	function _description(
		uint256 _avatarId
	) internal view returns (bytes memory) {
		return
			abi.encodePacked(
				'"description":"',
				Encode.toString(_block[_avatarId]),
				'"'
			);
	}

	function _attributes(
		uint256 _avatarId
	) internal view returns (bytes memory) {
		return
			abi.encodePacked(
				'"attributes":[{"trait_type":"Block","value":"',
				Encode.toHexString(_block[_avatarId]),
				'"}]'
			);
	}

	function _withdraw(address _to) private {
		uint256 balance = address(this).balance;
		(bool success, ) = payable(_to).call{value: address(this).balance}("");
		require(success, "ETH_TRANSFER_FAILED");
		emit Withdraw(msg.sender, _to, balance);
	}
}