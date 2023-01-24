/**
 *Submitted for verification at Etherscan.io on 2023-01-24
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;
// CAUTION
// This version of SafeMath should only be used with Solidity 0.8 or later,
// because it relies on the compiler's built in overflow checks.
// 2023-01-24
library SafeMath {
	function tryAdd(uint256 a, uint256 b) internal pure returns (bool, uint256) {
		unchecked {
			uint256 c = a + b;
			if (c < a) return (false, 0);
			return (true, c);
		}
	}
	function trySub(uint256 a, uint256 b) internal pure returns (bool, uint256) {
		unchecked {
			if (b > a) return (false, 0);
			return (true, a - b);
		}
	}
	function tryMul(uint256 a, uint256 b) internal pure returns (bool, uint256) {
		unchecked {
			// Gas optimization: this is cheaper than requiring 'a' not being zero, but the
			// benefit is lost if 'b' is also tested.
			// See: https://github.com/OpenZeppelin/openzeppelin-contracts/pull/522
			if (a == 0) return (true, 0);
			uint256 c = a * b;
			if (c / a != b) return (false, 0);
			return (true, c);
		}
	}
	function tryDiv(uint256 a, uint256 b) internal pure returns (bool, uint256) {
		unchecked {
			if (b == 0) return (false, 0);
			return (true, a / b);
		}
	}
	function tryMod(uint256 a, uint256 b) internal pure returns (bool, uint256) {
		unchecked {
			if (b == 0) return (false, 0);
			return (true, a % b);
		}
	}
	function add(uint256 a, uint256 b) internal pure returns (uint256) {
		return a + b;
	}
	function sub(uint256 a, uint256 b) internal pure returns (uint256) {
		return a - b;
	}
	function mul(uint256 a, uint256 b) internal pure returns (uint256) {
		return a * b;
	}
	function div(uint256 a, uint256 b) internal pure returns (uint256) {
		return a / b;
	}
	function mod(uint256 a, uint256 b) internal pure returns (uint256) {
		return a % b;
	}
	function sub(
		uint256 a,
		uint256 b,
		string memory errorMessage
	) internal pure returns (uint256) {
		unchecked {
			require(b <= a, errorMessage);
			return a - b;
		}
	}
	function div(
		uint256 a,
		uint256 b,
		string memory errorMessage
	) internal pure returns (uint256) {
		unchecked {
			require(b > 0, errorMessage);
			return a / b;
		}
	}
	function mod(
		uint256 a,
		uint256 b,
		string memory errorMessage
	) internal pure returns (uint256) {
		unchecked {
			require(b > 0, errorMessage);
			return a % b;
		}
	}
}
// File: @openzeppelin/contracts/utils/Context.sol
abstract contract Context {
	function _msgSender() internal view virtual returns (address) {
		return msg.sender;
	}
	function _msgData() internal view virtual returns (bytes calldata) {
		return msg.data;
	}
}
// File: @openzeppelin/contracts/access/Ownable.sol
abstract contract Ownable is Context {
	address private _owner;
	event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);
	constructor() {
		_transferOwnership(_msgSender());
	}
	function owner() public view virtual returns (address) {
		return _owner;
	}
	modifier onlyOwner() {
		require(owner() == _msgSender(), "Ownable: caller is not the owner");
		_;
	}
	function renounceOwnership() public virtual onlyOwner {
		_transferOwnership(address(0));
	}
	function transferOwnership(address newOwner) public virtual onlyOwner {
		require(newOwner != address(0), "Ownable: new owner is the zero address");
		_transferOwnership(newOwner);
	}
	function _transferOwnership(address newOwner) internal virtual {
		address oldOwner = _owner;
		_owner = newOwner;
		emit OwnershipTransferred(oldOwner, newOwner);
	}
}
// File: @openzeppelin/contracts/utils/introspection/IERC165.sol
interface IERC165 {
	function supportsInterface(bytes4 interfaceId) external view returns (bool);
}
// File: @openzeppelin/contracts/utils/introspection/ERC165.sol
abstract contract ERC165 is IERC165 {
	function supportsInterface(bytes4 interfaceId) public view virtual override returns (bool) {
		return interfaceId == type(IERC165).interfaceId;
	}
}
// File: @openzeppelin/contracts/token/ERC1155/IERC1155Receiver.sol
interface IERC1155Receiver is IERC165 {
	function onERC1155Received(
		address operator,
		address from,
		uint256 id,
		uint256 value,
		bytes calldata data
	) external returns (bytes4);
	function onERC1155BatchReceived(
		address operator,
		address from,
		uint256[] calldata ids,
		uint256[] calldata values,
		bytes calldata data
	) external returns (bytes4);
}
// File: @openzeppelin/contracts/token/ERC1155/IERC1155.sol
interface IERC1155 is IERC165 {
	event TransferSingle(address indexed operator, address indexed from, address indexed to, uint256 id, uint256 value);
	event TransferBatch(
		address indexed operator,
		address indexed from,
		address indexed to,
		uint256[] ids,
		uint256[] values
	);
	event ApprovalForAll(address indexed account, address indexed operator, bool approved);
	event URI(string value, uint256 indexed id);
	function balanceOf(address account, uint256 id) external view returns (uint256);
	function balanceOfBatch(address[] calldata accounts, uint256[] calldata ids)
		external
		view
		returns (uint256[] memory);
	function setApprovalForAll(address operator, bool approved) external;
	function isApprovedForAll(address account, address operator) external view returns (bool);
	function safeTransferFrom(
		address from,
		address to,
		uint256 id,
		uint256 amount,
		bytes calldata data
	) external;
	function safeBatchTransferFrom(
		address from,
		address to,
		uint256[] calldata ids,
		uint256[] calldata amounts,
		bytes calldata data
	) external;
}
// File: @openzeppelin/contracts/token/ERC1155/extensions/IERC1155MetadataURI.sol
interface IERC1155MetadataURI is IERC1155 {
	function uri(uint256 id) external view returns (string memory);
}
// File: @openzeppelin/contracts/utils/Address.sol
pragma solidity ^0.8.1;
library Address {
	function isContract(address account) internal view returns (bool) {
		// This method relies on extcodesize/address.code.length, which returns 0
		// for contracts in construction, since the code is only stored at the end
		// of the constructor execution.
		return account.code.length > 0;
	}
	function sendValue(address payable recipient, uint256 amount) internal {
		require(address(this).balance >= amount, "Address: insufficient balance");
		(bool success, ) = recipient.call{value: amount}("");
		require(success, "Address: unable to send value, recipient may have reverted");
	}
	function functionCall(address target, bytes memory data) internal returns (bytes memory) {
		return functionCall(target, data, "Address: low-level call failed");
	}
	function functionCall(
		address target,
		bytes memory data,
		string memory errorMessage
	) internal returns (bytes memory) {
		return functionCallWithValue(target, data, 0, errorMessage);
	}
	function functionCallWithValue(
		address target,
		bytes memory data,
		uint256 value
	) internal returns (bytes memory) {
		return functionCallWithValue(target, data, value, "Address: low-level call with value failed");
	}
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
	function functionStaticCall(address target, bytes memory data) internal view returns (bytes memory) {
		return functionStaticCall(target, data, "Address: low-level static call failed");
	}
	function functionStaticCall(
		address target,
		bytes memory data,
		string memory errorMessage
	) internal view returns (bytes memory) {
		require(isContract(target), "Address: static call to non-contract");
		(bool success, bytes memory returndata) = target.staticcall(data);
		return verifyCallResult(success, returndata, errorMessage);
	}
	function functionDelegateCall(address target, bytes memory data) internal returns (bytes memory) {
		return functionDelegateCall(target, data, "Address: low-level delegate call failed");
	}
	function functionDelegateCall(
		address target,
		bytes memory data,
		string memory errorMessage
	) internal returns (bytes memory) {
		require(isContract(target), "Address: delegate call to non-contract");
		(bool success, bytes memory returndata) = target.delegatecall(data);
		return verifyCallResult(success, returndata, errorMessage);
	}
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
// File: @openzeppelin/contracts/token/ERC1155/ERC1155.sol
pragma solidity ^0.8.0;
contract ERC1155 is Context, ERC165, IERC1155, IERC1155MetadataURI {
	using Address for address;
	// Mapping from token ID to account balances
	mapping(uint256 => mapping(address => uint256)) private _balances;
	// Mapping from account to operator approvals
	mapping(address => mapping(address => bool)) private _operatorApprovals;
	// Used as the URI for all token types by relying on ID substitution, e.g. https://token-cdn-domain/{id}.json
	string private _uri;
	constructor(string memory uri_) {
		_setURI(uri_);
	}
	function supportsInterface(bytes4 interfaceId) public view virtual override(ERC165, IERC165) returns (bool) {
		return
			interfaceId == type(IERC1155).interfaceId ||
			interfaceId == type(IERC1155MetadataURI).interfaceId ||
			super.supportsInterface(interfaceId);
	}
	function uri(uint256) public view virtual override returns (string memory) {
		return _uri;
	}
	function balanceOf(address account, uint256 id) public view virtual override returns (uint256) {
		require(account != address(0), "ERC1155: address zero is not a valid owner");
		return _balances[id][account];
	}
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
	function setApprovalForAll(address operator, bool approved) public virtual override {
		_setApprovalForAll(_msgSender(), operator, approved);
	}
	function isApprovedForAll(address account, address operator) public view virtual override returns (bool) {
		return _operatorApprovals[account][operator];
	}
	function safeTransferFrom(
		address from,
		address to,
		uint256 id,
		uint256 amount,
		bytes memory data
	) public virtual override {
		require(
			from == _msgSender() || isApprovedForAll(from, _msgSender()),
			"ERC1155: caller is not token owner nor approved"
		);
		_safeTransferFrom(from, to, id, amount, data);
	}
	function safeBatchTransferFrom(
		address from,
		address to,
		uint256[] memory ids,
		uint256[] memory amounts,
		bytes memory data
	) public virtual override {
		require(
			from == _msgSender() || isApprovedForAll(from, _msgSender()),
			"ERC1155: caller is not token owner nor approved"
		);
		_safeBatchTransferFrom(from, to, ids, amounts, data);
	}
	function _safeTransferFrom(
		address from,
		address to,
		uint256 id,
		uint256 amount,
		bytes memory data
	) internal virtual {
		require(to != address(0), "ERC1155: transfer to the zero address");
		address operator = _msgSender();
		uint256[] memory ids = _asSingletonArray(id);
		uint256[] memory amounts = _asSingletonArray(amount);
		_beforeTokenTransfer(operator, from, to, ids, amounts, data);
		uint256 fromBalance = _balances[id][from];
		require(fromBalance >= amount, "ERC1155: insufficient balance for transfer");
		unchecked {
			_balances[id][from] = fromBalance - amount;
		}
		_balances[id][to] += amount;
		emit TransferSingle(operator, from, to, id, amount);
		_afterTokenTransfer(operator, from, to, ids, amounts, data);
		_doSafeTransferAcceptanceCheck(operator, from, to, id, amount, data);
	}
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
		_afterTokenTransfer(operator, from, to, ids, amounts, data);
		_doSafeBatchTransferAcceptanceCheck(operator, from, to, ids, amounts, data);
	}
	function _setURI(string memory newuri) internal virtual {
		_uri = newuri;
	}
	function _mint(
		address to,
		uint256 id,
		uint256 amount,
		bytes memory data
	) internal virtual {
		require(to != address(0), "ERC1155: mint to the zero address");
		address operator = _msgSender();
		uint256[] memory ids = _asSingletonArray(id);
		uint256[] memory amounts = _asSingletonArray(amount);
		_beforeTokenTransfer(operator, address(0), to, ids, amounts, data);
		_balances[id][to] += amount;
		emit TransferSingle(operator, address(0), to, id, amount);
		_afterTokenTransfer(operator, address(0), to, ids, amounts, data);
		_doSafeTransferAcceptanceCheck(operator, address(0), to, id, amount, data);
	}
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
		_afterTokenTransfer(operator, address(0), to, ids, amounts, data);
		_doSafeBatchTransferAcceptanceCheck(operator, address(0), to, ids, amounts, data);
	}
	function _burn(
		address from,
		uint256 id,
		uint256 amount
	) internal virtual {
		require(from != address(0), "ERC1155: burn from the zero address");
		address operator = _msgSender();
		uint256[] memory ids = _asSingletonArray(id);
		uint256[] memory amounts = _asSingletonArray(amount);
		_beforeTokenTransfer(operator, from, address(0), ids, amounts, "");
		uint256 fromBalance = _balances[id][from];
		require(fromBalance >= amount, "ERC1155: burn amount exceeds balance");
		unchecked {
			_balances[id][from] = fromBalance - amount;
		}
		emit TransferSingle(operator, from, address(0), id, amount);
		_afterTokenTransfer(operator, from, address(0), ids, amounts, "");
	}
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
		_afterTokenTransfer(operator, from, address(0), ids, amounts, "");
	}
	function _setApprovalForAll(
		address owner,
		address operator,
		bool approved
	) internal virtual {
		require(owner != operator, "ERC1155: setting approval status for self");
		_operatorApprovals[owner][operator] = approved;
		emit ApprovalForAll(owner, operator, approved);
	}
	function _beforeTokenTransfer(
		address operator,
		address from,
		address to,
		uint256[] memory ids,
		uint256[] memory amounts,
		bytes memory data
	) internal virtual {}
	function _afterTokenTransfer(
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
// File: @openzeppelin/contracts/token/ERC20/extensions/draft-IERC20Permit.sol
interface IERC20Permit {
	function permit(
		address owner,
		address spender,
		uint256 value,
		uint256 deadline,
		uint8 v,
		bytes32 r,
		bytes32 s
	) external;
	function nonces(address owner) external view returns (uint256);
	// solhint-disable-next-line func-name-mixedcase
	function DOMAIN_SEPARATOR() external view returns (bytes32);
}
// File: @openzeppelin/contracts/token/ERC20/IERC20.sol
interface IERC20 {
	event Transfer(address indexed from, address indexed to, uint256 value);
	event Approval(address indexed owner, address indexed spender, uint256 value);
	function totalSupply() external view returns (uint256);
	function balanceOf(address account) external view returns (uint256);
	function transfer(address to, uint256 amount) external returns (bool);
	function allowance(address owner, address spender) external view returns (uint256);
	function approve(address spender, uint256 amount) external returns (bool);
	function transferFrom(
		address from,
		address to,
		uint256 amount
	) external returns (bool);
}
// File: @openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol
library SafeERC20 {
	using Address for address;
	function safeTransfer(
		IERC20 token,
		address to,
		uint256 value
	) internal {
		_callOptionalReturn(token, abi.encodeWithSelector(token.transfer.selector, to, value));
	}
	function safeTransferFrom(
		IERC20 token,
		address from,
		address to,
		uint256 value
	) internal {
		_callOptionalReturn(token, abi.encodeWithSelector(token.transferFrom.selector, from, to, value));
	}
	function safeApprove(
		IERC20 token,
		address spender,
		uint256 value
	) internal {
		// safeApprove should only be called when setting an initial allowance,
		// or when resetting it to zero. To increase and decrease it, use
		// 'safeIncreaseAllowance' and 'safeDecreaseAllowance'
		require(
			(value == 0) || (token.allowance(address(this), spender) == 0),
			"SafeERC20: approve from non-zero to non-zero allowance"
		);
		_callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, value));
	}
	function safeIncreaseAllowance(
		IERC20 token,
		address spender,
		uint256 value
	) internal {
		uint256 newAllowance = token.allowance(address(this), spender) + value;
		_callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
	}
	function safeDecreaseAllowance(
		IERC20 token,
		address spender,
		uint256 value
	) internal {
		unchecked {
			uint256 oldAllowance = token.allowance(address(this), spender);
			require(oldAllowance >= value, "SafeERC20: decreased allowance below zero");
			uint256 newAllowance = oldAllowance - value;
			_callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
		}
	}
	function safePermit(
		IERC20Permit token,
		address owner,
		address spender,
		uint256 value,
		uint256 deadline,
		uint8 v,
		bytes32 r,
		bytes32 s
	) internal {
		uint256 nonceBefore = token.nonces(owner);
		token.permit(owner, spender, value, deadline, v, r, s);
		uint256 nonceAfter = token.nonces(owner);
		require(nonceAfter == nonceBefore + 1, "SafeERC20: permit did not succeed");
	}
	function _callOptionalReturn(IERC20 token, bytes memory data) private {
		// We need to perform a low level call here, to bypass Solidity's return data size checking mechanism, since
		// we're implementing it ourselves. We use {Address.functionCall} to perform this call, which verifies that
		// the target address contains contract code and also asserts for success in the low-level call.
		bytes memory returndata = address(token).functionCall(data, "SafeERC20: low-level call failed");
		if (returndata.length > 0) {
			// Return data is optional
			require(abi.decode(returndata, (bool)), "SafeERC20: ERC20 operation did not succeed");
		}
	}
}
// File: contracts/WLAuction2.sol
contract WhitelistAuctionV2 is ERC1155, Ownable {
	using SafeMath for uint256;
	using SafeERC20 for IERC20;
	struct Auction {
		address creator;
		uint256 startTime; // start timestamp of an auction 
		uint256 endTime; // end timestamp of an auction 
		uint256 claimed;
		string ipfs;
		IERC20 currency;
	}
	// CURRENT VERSION ACCESTS ONLY FOLLOWING 4 CURRENCIES
	address[4] ACCPCETABLE_CURRENCY = [
		0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2, // WETH
		0xdAC17F958D2ee523a2206206994597C13D831ec7, // USDT
		0xA0b86991c6218b36c1d19D4a2e9Eb0cE3606eB48, // USDC
		0x882e5b370D595E50c24b2a0e7a94e87Cc32ADdA1 // GAME
	];
	address public MODERATOR;
	string public constant name = 'WLAuction2';
	bytes32 public DOMAIN_SEPARATOR;
	// keccak256("bid(address bidder,uint256 auctionId,uint256 weiValue)");
	bytes32 public constant SET_TYPEHASH = 0xc8c9a0dce70409f2aa3b4173608e11d2c7cf5021dcb65b2f8c6fb6cc16d789dc;
	uint256 private _nonce = 24; // should be sync with V2
	mapping(uint256 => Auction) public auctions;
	mapping(uint256 => mapping(address => bool)) public win_claimed;
	mapping(address => bool) public traders;
	event AuctionCreated(uint256 idx, string ipfs_url);
	event AuctionClosed(uint256 idx);
	event WinnerClaimed(uint256 idx, address user, uint256 price);
	constructor(
		address _moderator
	) ERC1155("") {
		MODERATOR = _moderator;
		traders[msg.sender] = true;
		uint chainId;
		assembly {
			chainId := chainid()
		}
		DOMAIN_SEPARATOR = keccak256(
			abi.encode(
				keccak256('EIP712Domain(string name,string version,uint256 chainId,address verifyingContract)'),
				keccak256(bytes(name)),
				keccak256(bytes('1')),
				chainId,
				address(this)
			)
		);
	}
	/**
		Create a new Whitelist auction
	 */
	function openAuction(
		uint256 _startTime,
		uint256 _endTime,
		uint8 _currencyIdx,
		string memory _ipfs
	) external onlyTrader {
		// TODO parameters value checking
		require(
			_startTime > block.timestamp &&
			_startTime < _endTime,
			"invalid_time" 
		);
		require(
			_currencyIdx < ACCPCETABLE_CURRENCY.length,
			"invalid_setting" 
		);
		// register new auction
		_nonce = _nonce + 1;
		auctions[_nonce] = Auction(
			msg.sender,
			_startTime,
			_endTime,
			0,
			_ipfs,
			IERC20(ACCPCETABLE_CURRENCY[_currencyIdx])
		);
		emit AuctionCreated(_nonce, _ipfs);
	}
	function closeAuction(uint256 _auctionId) external {
		Auction storage a = auctions[_auctionId];
		require(a.creator == msg.sender, 'only_creator_can_cancel');
		delete auctions[_auctionId];
		emit AuctionClosed(_auctionId);
	}
	function claimWinning(
		uint256 _index,
		uint256 _price,
		uint256 _maxSupply,
		address _buyer,
		bytes calldata signatureA,
		bytes calldata signatureB
	) external payable {
		// prevent double claim
		require(!win_claimed[_index][_buyer], 'already_claimed');
		// check aution status and restriction
		Auction storage a = auctions[_index];
		require(a.endTime < block.timestamp, 'aution_not_end');
		// check auction max supply
		require(a.claimed < _maxSupply, 'all_claimed');
		bytes32 messageA = keccak256(
			abi.encodePacked(
				'\x19\x01',
				DOMAIN_SEPARATOR,
				keccak256(abi.encode(SET_TYPEHASH, _buyer, _index, _price))
			)
		);
		// validate client signature, _maxSupply
		bytes32 messageB = prefixed(keccak256(abi.encodePacked(
			signatureA,
			_maxSupply
		)));
		require(recoverSigner(messageA, signatureA) == _buyer, 'client_not_signed');
		require(recoverSigner(messageB, signatureB) == MODERATOR, 'moderator_not_signed');
		// update auction state
		a.claimed = a.claimed.add(1);
		win_claimed[_index][_buyer] = true;
		// transfer payment
		// check if the auction is in ETH
		if (a.currency == IERC20(ACCPCETABLE_CURRENCY[0])) {
			require(msg.value >= _price, 'not_enough_fund');
			(bool transferSuccess,) = a.creator.call{value : _price}("");
			require(transferSuccess, "ETH_transfer_failed");
		} else {
			a.currency.safeTransferFrom(_buyer, a.creator, _price);
		}
		// mint new NFTs to contract itself
		_mint(address(_buyer), _index, 1, "");
		emit WinnerClaimed(_index, _buyer, _price);
	}
	function claimPriceReduction(
		uint256 _index,
		uint256 _price,
		uint256 _maxSupply,
		address _buyer,
		bytes calldata signatureA
	) external payable {
		// prevent double claim
		require(!win_claimed[_index][_buyer], 'already_claimed');
		// check aution status and restriction
		Auction storage a = auctions[_index];
		// check auction max supply
		require(a.claimed < _maxSupply, 'all_claimed');
		bytes32 messageA = prefixed(keccak256(abi.encodePacked(
			_buyer,
			_index, 
			_price,
			_maxSupply
		)));
		require(recoverSigner(messageA, signatureA) == MODERATOR, 'worng_sign');
		// update auction state
		a.claimed = a.claimed.add(1);
		win_claimed[_index][_buyer] = true;
		// transfer payment
		if (a.currency == IERC20(ACCPCETABLE_CURRENCY[0])) {
			require(msg.value >= _price, 'not_enough_fund');
			(bool transferSuccess,) = a.creator.call{value : _price}("");
			require(transferSuccess, "ETH_transfer_failed");
		} else {
			a.currency.safeTransferFrom(_buyer, a.creator, _price);
		}
		// mint new NFTs to contract itself
		_mint(address(_buyer), _index, 1, "");
		emit WinnerClaimed(_index, _buyer, _price);
	}
	// EIP-1155 customize
	function uri(uint256 _id) public view virtual override returns (string memory) {
		Auction storage a = auctions[_id];
		if (a.creator == address(0)) {
			return "";
		}
		return string(abi.encodePacked('ipfs://', a.ipfs));
	}
	function updateTrader(address _trader, bool _approved) external onlyOwner {
		traders[_trader] = _approved;
	}
	// ERC-1155 reciver functions
	function onERC1155Received(
		address operator,
		address from,
		uint256 id,
		uint256 value,
		bytes calldata data
	) external returns (bytes4) {
		return bytes4(keccak256("onERC1155Received(address,address,uint256,uint256,bytes)"));
	}
	function onERC1155BatchReceived(
		address operator,
		address from,
		uint256[] calldata ids,
		uint256[] calldata values,
		bytes calldata data
	) external returns (bytes4) {
		return bytes4(keccak256("onERC1155BatchReceived(address,address,uint256[],uint256[],bytes)"));
	}
	// utils for message sign
	function prefixed(bytes32 hash) internal pure returns (bytes32) {
		return keccak256(abi.encodePacked(
			'\x19Ethereum Signed Message:\n32', 
			hash
		));
	}
	function recoverSigner(bytes32 message, bytes memory sig)
		internal
		pure
		returns (address)
	{
		uint8 v;
		bytes32 r;
		bytes32 s;
		(v, r, s) = splitSignature(sig);
		return ecrecover(message, v, r, s);
	}
	function splitSignature(bytes memory sig)
		internal
		pure
		returns (uint8, bytes32, bytes32)
	{
		require(sig.length == 65);
		bytes32 r;
		bytes32 s;
		uint8 v;
		assembly {
			// first 32 bytes, after the length prefix
			r := mload(add(sig, 32))
			// second 32 bytes
			s := mload(add(sig, 64))
			// final byte (first byte of the next 32 bytes)
			v := byte(0, mload(add(sig, 96)))
		}
		return (v, r, s);
	}
	// modifiers
	modifier onlyTrader() {
		require(traders[msg.sender] == true, "Not trader");
		// Underscore is a special character only used inside
		// a function modifier and it tells Solidity to
		// execute the rest of the code.
		_;
	}
}