// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.11;
import './AppStorage.sol';
import '@openzeppelin/contracts/token/ERC721/IERC721Receiver.sol';
import '@openzeppelin/contracts/utils/Address.sol';

contract ERC721Facet is AccessControlAppStorageEnumerable721 {
	using Address for address;

	bytes32 public constant TRADER = keccak256("TRADER");
	bytes32 public constant MINTER = keccak256("MINTER");
	bytes32 public constant CREATOR = keccak256("CREATOR");

	event ProductCompleted(uint indexed productIndex);
	event RangeCompleted(uint indexed rangeIndex, uint productIndex);
	
	event TradingUnlocked(uint indexed rangeIndex, uint from, uint to);

	event Transfer(address indexed from, address indexed to, uint256 indexed tokenId);
	event Approval(address indexed owner, address indexed approved, uint256 indexed tokenId);
	event ApprovalForAll(address indexed owner, address indexed operator, bool approved);
	
	function name() public view returns (string memory) {
		return s._name;
	}

	function symbol() public view returns (string memory) {
		return s._symbol;
	}

	function balanceOf(address owner) public view returns (uint256) {
		require(owner != address(0), "ERC721: balance query for the zero address");
		return s._balances[owner];
	}

	function tokenOfOwnerByIndex(address owner, uint256 index) public view returns (uint256) {
		require(index < balanceOf(owner), "ERC721Enumerable: owner index out of bounds");
		return s._ownedTokens[owner][index];
	}

	function totalSupply() public view returns (uint256) {
		return s._allTokens.length;
	}

	function tokenByIndex(uint256 index) public view returns (uint256) {
		require(index < totalSupply(), "ERC721Enumerable: global index out of bounds");
		return s._allTokens[index];
	}

	/// @notice Queries if an operator can act on behalf of an owner on all of their tokens
	/// @dev Overrides the OpenZeppelin standard by allowing anyone with the TRADER role to transfer tokens
	/// @param owner 		Owner of the tokens.
	/// @param operator 	Operator of the tokens.
	function isApprovedForAll(address owner, address operator) public view virtual returns (bool) {
		return (hasRole(TRADER, operator) || s._operatorApprovals[owner][operator]);
	}

	function nextMintableTokenInRange(uint rangeIndex) public view returns (uint) {
		require(s.ranges.length > rangeIndex, "RAIR ERC721 Ranges: Range does not exist");
		range memory selectedRange = s.ranges[rangeIndex];
		product memory selectedProduct = s.products[s.rangeToProduct[rangeIndex]];
		for (uint i = selectedRange.rangeStart; i < selectedRange.rangeEnd; i++) {
			if (!_exists(selectedProduct.startingToken + i)) {
				return i;
			}
		}
		require(false, 'RAIR ERC721: There are no tokens available for minting');
	}

	function _mintFromRange(address to, uint rangeId, uint indexInRange) internal {
		require(s.ranges.length > rangeId, "RAIR ERC721: Range does not exist");
		range storage selectedRange = s.ranges[rangeId];
		product storage selectedProduct = s.products[s.rangeToProduct[rangeId]];
		require(selectedProduct.mintableTokens > 0, 'RAIR ERC721: Cannot mint more tokens from this product!');
		require(selectedRange.mintableTokens > 0, 'RAIR ERC721: Cannot mint more tokens from this range!');
		require(selectedRange.tokensAllowed > 0, 'RAIR ERC721: Not allowed to mint more tokens from this range!');
		require(indexInRange >= selectedRange.rangeStart && indexInRange <= selectedRange.rangeEnd, "RAIR ERC721: Invalid token index");
		_safeMint(to, selectedProduct.startingToken + indexInRange, '');
		
		if (selectedRange.tokensAllowed > 0) {
			selectedRange.tokensAllowed--;
		}
		if (selectedRange.mintableTokens > 0) {
			selectedRange.mintableTokens--;
			if (selectedRange.mintableTokens == 0) {
				emit RangeCompleted(rangeId, s.rangeToProduct[rangeId]);
			}
		}
		if (selectedRange.lockedTokens > 0) {
			selectedRange.lockedTokens--;
			if (selectedRange.lockedTokens == 0) {
				emit TradingUnlocked(rangeId, selectedRange.rangeStart, selectedRange.rangeEnd);
			}
		}
		if (selectedProduct.mintableTokens > 0) {
			selectedProduct.mintableTokens--;
			if (selectedProduct.mintableTokens == 0) {
				emit ProductCompleted(s.rangeToProduct[rangeId]);
			}
		}
		s.tokenToProduct[selectedProduct.startingToken + indexInRange] = s.rangeToProduct[rangeId];
		s.tokenToRange[selectedProduct.startingToken + indexInRange] = rangeId;
		s.tokensByProduct[s.rangeToProduct[rangeId]].push(selectedProduct.startingToken + indexInRange);
	}

	function mintFromRangeBatch(
		address[] calldata to,
		uint rangeId,
		uint[] calldata indexInRange
	) external onlyRole(MINTER) {
		require(to.length > 0, "RAIR ERC721: Empty array");
		require(to.length == indexInRange.length, "RAIR ERC721: Both arrays should have the same length");
		for (uint i = 0; i < to.length; i++) {
			_mintFromRange(to[i], rangeId, indexInRange[i]);
		}
	}

	function mintFromRange(address to, uint rangeId, uint indexInRange) external onlyRole(MINTER) {
		_mintFromRange(to, rangeId, indexInRange);
	}

	function _isApprovedOrOwner(address spender, uint256 tokenId) internal view returns (bool) {
		require(_exists(tokenId), "ERC721: operator query for nonexistent token");
		address owner = ownerOf(tokenId);
		return (spender == owner || getApproved(tokenId) == spender || isApprovedForAll(owner, spender));
	}

	function approve(address to, uint256 tokenId) public {
		address owner = ownerOf(tokenId);
		require(to != owner, "ERC721: approval to current owner");

		require(
			_msgSender() == owner || isApprovedForAll(owner, _msgSender()),
			"ERC721: approve caller is not owner nor approved for all"
		);

		_approve(to, tokenId);
	}

	function setApprovalForAll(address operator, bool approved) public {
		_setApprovalForAll(_msgSender(), operator, approved);
	}

	function _setApprovalForAll(
		address owner,
		address operator,
		bool approved
	) internal virtual {
		require(owner != operator, "ERC721: approve to caller");
		s._operatorApprovals[owner][operator] = approved;
		emit ApprovalForAll(owner, operator, approved);
	}

	function _approve(address to, uint256 tokenId) internal virtual {
		s._tokenApprovals[tokenId] = to;
		emit Approval(ownerOf(tokenId), to, tokenId);
	}

	function getApproved(uint256 tokenId) public view returns (address) {
		require(_exists(tokenId), "ERC721: approved query for nonexistent token");
		return s._tokenApprovals[tokenId];
	}
	
	function _exists(uint256 tokenId) internal view virtual returns (bool) {
		return s._owners[tokenId] != address(0);
	}

	function _safeMint(address to, uint256 tokenId) internal virtual {
		_safeMint(to, tokenId, "");
	}

	function _safeMint(
		address to,
		uint256 tokenId,
		bytes memory _data
	) internal virtual {
		_mint(to, tokenId);
		require(
			_checkOnERC721Received(address(0), to, tokenId, _data),
			"ERC721: transfer to non ERC721Receiver implementer"
		);
	}

	function _mint(address to, uint256 tokenId) internal virtual {
		require(to != address(0), "ERC721: mint to the zero address");
		require(!_exists(tokenId), "ERC721: token already minted");

		_beforeTokenTransfer(address(0), to, tokenId);

		s._balances[to] += 1;
		s._owners[tokenId] = to;
		s._minted[tokenId] = true;

		emit Transfer(address(0), to, tokenId);
	}

	function ownerOf(uint256 tokenId) public view returns (address) {
		address owner = s._owners[tokenId];
		require(owner != address(0), "ERC721: owner query for nonexistent token");
		return owner;
	}

	/// @notice Hook being called before every transfer
	/// @dev	Transfer locking happens here!
	/// @param	_from		Token's original owner
	/// @param	_to			Token's new owner
	/// @param	_tokenId	Token's ID
	function _beforeTokenTransfer(address _from, address _to, uint256 _tokenId) internal {
		// If it's not minting or burning 
		if (_from != address(0) && _to != address(0)) {
			_checkRole(TRADER, msg.sender);
			require(s.ranges[s.tokenToRange[_tokenId]].lockedTokens == 0, "RAIR ERC721: Cannot transfer from a locked range!");
		}
		if (_from == address(0)) {
			_addTokenToAllTokensEnumeration(_tokenId);
		} else if (_from != _to) {
			_removeTokenFromOwnerEnumeration(_from, _tokenId);
		}
		if (_to == address(0)) {
			_removeTokenFromAllTokensEnumeration(_tokenId);
		} else if (_to != _from) {
			_addTokenToOwnerEnumeration(_to, _tokenId);
		}
		//require(hasRole(TRADER, _from), 'RAIR ERC721: Transfers cannot be made outside RAIR marketplaces!');
	}

	/**
	 * @dev Private function to add a token to this extension's ownership-tracking data structures.
	 * @param to address representing the new owner of the given token ID
	 * @param tokenId uint256 ID of the token to be added to the tokens list of the given address
	 */
	function _addTokenToOwnerEnumeration(address to, uint256 tokenId) private {
		uint256 length = balanceOf(to);
		s._ownedTokens[to][length] = tokenId;
		s._ownedTokensIndex[tokenId] = length;
	}

	/**
	 * @dev Private function to add a token to this extension's token tracking data structures.
	 * @param tokenId uint256 ID of the token to be added to the tokens list
	 */
	function _addTokenToAllTokensEnumeration(uint256 tokenId) private {
		s._allTokensIndex[tokenId] = s._allTokens.length;
		s._allTokens.push(tokenId);
	}

	/**
	 * @dev Private function to remove a token from this extension's ownership-tracking data structures. Note that
	 * while the token is not assigned a new owner, the `_ownedTokensIndex` mapping is _not_ updated: this allows for
	 * gas optimizations e.g. when performing a transfer operation (avoiding double writes).
	 * This has O(1) time complexity, but alters the order of the _ownedTokens array.
	 * @param from address representing the previous owner of the given token ID
	 * @param tokenId uint256 ID of the token to be removed from the tokens list of the given address
	 */
	function _removeTokenFromOwnerEnumeration(address from, uint256 tokenId) private {
		// To prevent a gap in from's tokens array, we store the last token in the index of the token to delete, and
		// then delete the last slot (swap and pop).

		uint256 lastTokenIndex = balanceOf(from) - 1;
		uint256 tokenIndex = s._ownedTokensIndex[tokenId];

		// When the token to delete is the last token, the swap operation is unnecessary
		if (tokenIndex != lastTokenIndex) {
			uint256 lastTokenId = s._ownedTokens[from][lastTokenIndex];

			s._ownedTokens[from][tokenIndex] = lastTokenId; // Move the last token to the slot of the to-delete token
			s._ownedTokensIndex[lastTokenId] = tokenIndex; // Update the moved token's index
		}

		// This also deletes the contents at the last position of the array
		delete s._ownedTokensIndex[tokenId];
		delete s._ownedTokens[from][lastTokenIndex];
	}

	/**
	 * @dev Private function to remove a token from this extension's token tracking data structures.
	 * This has O(1) time complexity, but alters the order of the _allTokens array.
	 * @param tokenId uint256 ID of the token to be removed from the tokens list
	 */
	function _removeTokenFromAllTokensEnumeration(uint256 tokenId) private {
		// To prevent a gap in the tokens array, we store the last token in the index of the token to delete, and
		// then delete the last slot (swap and pop).

		uint256 lastTokenIndex = s._allTokens.length - 1;
		uint256 tokenIndex = s._allTokensIndex[tokenId];

		// When the token to delete is the last token, the swap operation is unnecessary. However, since this occurs so
		// rarely (when the last minted token is burnt) that we still do the swap here to avoid the gas cost of adding
		// an 'if' statement (like in _removeTokenFromOwnerEnumeration)
		uint256 lastTokenId = s._allTokens[lastTokenIndex];

		s._allTokens[tokenIndex] = lastTokenId; // Move the last token to the slot of the to-delete token
		s._allTokensIndex[lastTokenId] = tokenIndex; // Update the moved token's index

		// This also deletes the contents at the last position of the array
		delete s._allTokensIndex[tokenId];
		s._allTokens.pop();
	}

	function transferFrom(
		address from,
		address to,
		uint256 tokenId
	) public {
		require(_isApprovedOrOwner(_msgSender(), tokenId), "ERC721: transfer caller is not owner nor approved");
		_transfer(from, to, tokenId);
	}

	/**
	 * @dev See {IERC721-safeTransferFrom}.
	 */
	function safeTransferFrom(
		address from,
		address to,
		uint256 tokenId
	) public {
		safeTransferFrom(from, to, tokenId, "");
	}

	/**
	 * @dev See {IERC721-safeTransferFrom}.
	 */
	function safeTransferFrom(
		address from,
		address to,
		uint256 tokenId,
		bytes memory _data
	) public {
		require(_isApprovedOrOwner(_msgSender(), tokenId), "ERC721: transfer caller is not owner nor approved");
		_safeTransfer(from, to, tokenId, _data);
	}

	/**
	 * @dev Safely transfers `tokenId` token from `from` to `to`, checking first that contract recipients
	 * are aware of the ERC721 protocol to prevent tokens from being forever locked.
	 *
	 * `_data` is additional data, it has no specified format and it is sent in call to `to`.
	 *
	 * This internal function is equivalent to {safeTransferFrom}, and can be used to e.g.
	 * implement alternative mechanisms to perform token transfer, such as signature-based.
	 *
	 * Requirements:
	 *
	 * - `from` cannot be the zero address.
	 * - `to` cannot be the zero address.
	 * - `tokenId` token must exist and be owned by `from`.
	 * - If `to` refers to a smart contract, it must implement {IERC721Receiver-onERC721Received}, which is called upon a safe transfer.
	 *
	 * Emits a {Transfer} event.
	 */
	function _safeTransfer(
		address from,
		address to,
		uint256 tokenId,
		bytes memory _data
	) internal {
		_transfer(from, to, tokenId);
		require(_checkOnERC721Received(from, to, tokenId, _data), "ERC721: transfer to non ERC721Receiver implementer");
	}

	/**
	 * @dev Transfers `tokenId` from `from` to `to`.
	 *  As opposed to {transferFrom}, this imposes no restrictions on msg.sender.
	 *
	 * Requirements:
	 *
	 * - `to` cannot be the zero address.
	 * - `tokenId` token must be owned by `from`.
	 *
	 * Emits a {Transfer} event.
	 */
	function _transfer(
		address from,
		address to,
		uint256 tokenId
	) internal {
		require(ownerOf(tokenId) == from, "ERC721: transfer from incorrect owner");
		require(to != address(0), "ERC721: transfer to the zero address");

		_beforeTokenTransfer(from, to, tokenId);

		// Clear approvals from the previous owner
		_approve(address(0), tokenId);

		s._balances[from] -= 1;
		s._balances[to] += 1;
		s._owners[tokenId] = to;

		emit Transfer(from, to, tokenId);
	}

	function _checkOnERC721Received(
		address from,
		address to,
		uint256 tokenId,
		bytes memory _data
	) private returns (bool) {
		if (to.isContract()) {
			try IERC721Receiver(to).onERC721Received(_msgSender(), from, tokenId, _data) returns (bytes4 retval) {
				return retval == IERC721Receiver.onERC721Received.selector;
			} catch (bytes memory reason) {
				if (reason.length == 0) {
					revert("ERC721: transfer to non ERC721Receiver implementer");
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

// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.11; 

import '../../common/AccessControl.sol';

struct range {
	uint rangeStart;
	uint rangeEnd;
	uint tokensAllowed;
	uint mintableTokens;
	uint lockedTokens;
	uint rangePrice;
	string rangeName;
}

struct product {
	uint startingToken;
	uint endingToken;
	uint mintableTokens;
	string name;
	uint[] rangeList;
}

struct AppStorage721 {
	// ERC721
	string _name;
	string _symbol;
	mapping(uint256 => address) _owners;
	mapping(address => uint256) _balances;
	mapping(uint256 => address) _tokenApprovals;
	mapping(address => mapping(address => bool)) _operatorApprovals;
	// ERC721 Enumerable
	mapping(address => mapping(uint256 => uint256)) _ownedTokens;
	mapping(uint256 => uint256) _ownedTokensIndex;
	uint256[] _allTokens;
	mapping(uint256 => uint256) _allTokensIndex;
	// Access Control Enumerable
	mapping(bytes32 => RoleData) _roles;
	mapping(bytes32 => EnumerableSet.AddressSet) _roleMembers;
	// App
	string baseURI;
	address factoryAddress;
	uint16 royaltyFee;
	product[] products;
	range[] ranges;
	mapping(uint => uint) tokenToProduct;
	mapping(uint => uint) tokenToRange;
	mapping(uint => string) uniqueTokenURI;
	mapping(uint => string) productURI;
	mapping(uint => bool) appendTokenIndexToProductURI;
	bool appendTokenIndexToBaseURI;
	mapping(uint => uint[]) tokensByProduct;
	string contractMetadataURI;
	mapping(uint => uint) rangeToProduct;
	mapping(uint => bool) _minted;
	// Always add new variables at the end of the struct
}

library LibAppStorage721 {
	function diamondStorage() internal pure	returns (AppStorage721 storage ds) {
		assembly {
			ds.slot := 0
		}
	}
}

contract AccessControlAppStorageEnumerable721 is Context {
	AppStorage721 internal s;

	using EnumerableSet for EnumerableSet.AddressSet;

	event RoleAdminChanged(bytes32 indexed role, bytes32 indexed previousAdminRole, bytes32 indexed newAdminRole);
	event RoleGranted(bytes32 indexed role, address indexed account, address indexed sender);
	event RoleRevoked(bytes32 indexed role, address indexed account, address indexed sender);

	modifier onlyRole(bytes32 role) {
		_checkRole(role, _msgSender());
		_;
	}

	function renounceRole(bytes32 role, address account) public {
		require(account == _msgSender(), "AccessControl: can only renounce roles for self");
		_revokeRole(role, account);
	}

	function grantRole(bytes32 role, address account) public onlyRole(getRoleAdmin(role)) {
		_grantRole(role, account);
	}

	function revokeRole(bytes32 role, address account) public onlyRole(getRoleAdmin(role)) {
		_revokeRole(role, account);
	}

	function _checkRole(bytes32 role, address account) internal view {
		if (!hasRole(role, account)) {
			revert(
				string(
					abi.encodePacked(
						"AccessControl: account ",
						Strings.toHexString(uint160(account), 20),
						" is missing role ",
						Strings.toHexString(uint256(role), 32)
					)
				)
			);
		}
	}

	function hasRole(bytes32 role, address account) public view returns (bool) {
		return s._roles[role].members[account];
	}

	function getRoleAdmin(bytes32 role) public view returns (bytes32) {
		return s._roles[role].adminRole;
	}

	function getRoleMember(bytes32 role, uint256 index) public view returns (address) {
		return s._roleMembers[role].at(index);
	}

	function getRoleMemberCount(bytes32 role) public view returns (uint256) {
		return s._roleMembers[role].length();
	}

	function _setRoleAdmin(bytes32 role, bytes32 adminRole) internal {
		bytes32 previousAdminRole = getRoleAdmin(role);
		s._roles[role].adminRole = adminRole;
		emit RoleAdminChanged(role, previousAdminRole, adminRole);
	}

	function _grantRole(bytes32 role, address account) internal {
		if (!hasRole(role, account)) {
			s._roles[role].members[account] = true;
			emit RoleGranted(role, account, _msgSender());
			s._roleMembers[role].add(account);
		}
	}

	function _revokeRole(bytes32 role, address account) internal {
		if (hasRole(role, account)) {
			s._roles[role].members[account] = false;
			emit RoleRevoked(role, account, _msgSender());
			s._roleMembers[role].remove(account);
		}
	}
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (token/ERC721/IERC721Receiver.sol)

pragma solidity ^0.8.0;

/**
 * @title ERC721 token receiver interface
 * @dev Interface for any contract that wants to support safeTransfers
 * from ERC721 asset contracts.
 */
interface IERC721Receiver {
    /**
     * @dev Whenever an {IERC721} `tokenId` token is transferred to this contract via {IERC721-safeTransferFrom}
     * by `operator` from `from`, this function is called.
     *
     * It must return its Solidity selector to confirm the token transfer.
     * If any other value is returned or the interface is not implemented by the recipient, the transfer will be reverted.
     *
     * The selector can be obtained in Solidity with `IERC721.onERC721Received.selector`.
     */
    function onERC721Received(
        address operator,
        address from,
        uint256 tokenId,
        bytes calldata data
    ) external returns (bytes4);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/Address.sol)

pragma solidity ^0.8.0;

/**
 * @dev Collection of functions related to the address type
 */
library Address {
    /**
     * @dev Returns true if `account` is a contract.
     *
     * [IMPORTANT]
     * ====
     * It is unsafe to assume that an address for which this function returns
     * false is an externally-owned account (EOA) and not a contract.
     *
     * Among others, `isContract` will return false for the following
     * types of addresses:
     *
     *  - an externally-owned account
     *  - a contract in construction
     *  - an address where a contract will be created
     *  - an address where a contract lived, but was destroyed
     * ====
     */
    function isContract(address account) internal view returns (bool) {
        // This method relies on extcodesize, which returns 0 for contracts in
        // construction, since the code is only stored at the end of the
        // constructor execution.

        uint256 size;
        assembly {
            size := extcodesize(account)
        }
        return size > 0;
    }

    /**
     * @dev Replacement for Solidity's `transfer`: sends `amount` wei to
     * `recipient`, forwarding all available gas and reverting on errors.
     *
     * https://eips.ethereum.org/EIPS/eip-1884[EIP1884] increases the gas cost
     * of certain opcodes, possibly making contracts go over the 2300 gas limit
     * imposed by `transfer`, making them unable to receive funds via
     * `transfer`. {sendValue} removes this limitation.
     *
     * https://diligence.consensys.net/posts/2019/09/stop-using-soliditys-transfer-now/[Learn more].
     *
     * IMPORTANT: because control is transferred to `recipient`, care must be
     * taken to not create reentrancy vulnerabilities. Consider using
     * {ReentrancyGuard} or the
     * https://solidity.readthedocs.io/en/v0.5.11/security-considerations.html#use-the-checks-effects-interactions-pattern[checks-effects-interactions pattern].
     */
    function sendValue(address payable recipient, uint256 amount) internal {
        require(address(this).balance >= amount, "Address: insufficient balance");

        (bool success, ) = recipient.call{value: amount}("");
        require(success, "Address: unable to send value, recipient may have reverted");
    }

    /**
     * @dev Performs a Solidity function call using a low level `call`. A
     * plain `call` is an unsafe replacement for a function call: use this
     * function instead.
     *
     * If `target` reverts with a revert reason, it is bubbled up by this
     * function (like regular Solidity function calls).
     *
     * Returns the raw returned data. To convert to the expected return value,
     * use https://solidity.readthedocs.io/en/latest/units-and-global-variables.html?highlight=abi.decode#abi-encoding-and-decoding-functions[`abi.decode`].
     *
     * Requirements:
     *
     * - `target` must be a contract.
     * - calling `target` with `data` must not revert.
     *
     * _Available since v3.1._
     */
    function functionCall(address target, bytes memory data) internal returns (bytes memory) {
        return functionCall(target, data, "Address: low-level call failed");
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`], but with
     * `errorMessage` as a fallback revert reason when `target` reverts.
     *
     * _Available since v3.1._
     */
    function functionCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal returns (bytes memory) {
        return functionCallWithValue(target, data, 0, errorMessage);
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
     * but also transferring `value` wei to `target`.
     *
     * Requirements:
     *
     * - the calling contract must have an ETH balance of at least `value`.
     * - the called Solidity function must be `payable`.
     *
     * _Available since v3.1._
     */
    function functionCallWithValue(
        address target,
        bytes memory data,
        uint256 value
    ) internal returns (bytes memory) {
        return functionCallWithValue(target, data, value, "Address: low-level call with value failed");
    }

    /**
     * @dev Same as {xref-Address-functionCallWithValue-address-bytes-uint256-}[`functionCallWithValue`], but
     * with `errorMessage` as a fallback revert reason when `target` reverts.
     *
     * _Available since v3.1._
     */
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

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
     * but performing a static call.
     *
     * _Available since v3.3._
     */
    function functionStaticCall(address target, bytes memory data) internal view returns (bytes memory) {
        return functionStaticCall(target, data, "Address: low-level static call failed");
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-string-}[`functionCall`],
     * but performing a static call.
     *
     * _Available since v3.3._
     */
    function functionStaticCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal view returns (bytes memory) {
        require(isContract(target), "Address: static call to non-contract");

        (bool success, bytes memory returndata) = target.staticcall(data);
        return verifyCallResult(success, returndata, errorMessage);
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
     * but performing a delegate call.
     *
     * _Available since v3.4._
     */
    function functionDelegateCall(address target, bytes memory data) internal returns (bytes memory) {
        return functionDelegateCall(target, data, "Address: low-level delegate call failed");
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-string-}[`functionCall`],
     * but performing a delegate call.
     *
     * _Available since v3.4._
     */
    function functionDelegateCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal returns (bytes memory) {
        require(isContract(target), "Address: delegate call to non-contract");

        (bool success, bytes memory returndata) = target.delegatecall(data);
        return verifyCallResult(success, returndata, errorMessage);
    }

    /**
     * @dev Tool to verifies that a low level call was successful, and revert if it wasn't, either by bubbling the
     * revert reason using the provided one.
     *
     * _Available since v4.3._
     */
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

// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.11; 

import "@openzeppelin/contracts/utils/Context.sol";
import "@openzeppelin/contracts/utils/Strings.sol";
import "@openzeppelin/contracts/utils/structs/EnumerableSet.sol";

struct RoleData {
	mapping(address => bool) members;
	bytes32 adminRole;
}

abstract contract AccessControlEnumerable is Context {	
	event RoleAdminChanged(bytes32 indexed role, bytes32 indexed previousAdminRole, bytes32 indexed newAdminRole);
	event RoleGranted(bytes32 indexed role, address indexed account, address indexed sender);
    event RoleRevoked(bytes32 indexed role, address indexed account, address indexed sender);

    modifier onlyRole(bytes32 role) {
        _checkRole(role, _msgSender());
        _;
    }

    function renounceRole(bytes32 role, address account) public {
        require(account == _msgSender(), "AccessControl: can only renounce roles for self");
        _revokeRole(role, account);
    }

    function grantRole(bytes32 role, address account) public onlyRole(getRoleAdmin(role)) {
        _grantRole(role, account);
    }

    function revokeRole(bytes32 role, address account) public onlyRole(getRoleAdmin(role)) {
        _revokeRole(role, account);
    }

    function _checkRole(bytes32 role, address account) internal view {
        if (!hasRole(role, account)) {
            revert(
                string(
                    abi.encodePacked(
                        "AccessControl: account ",
                        Strings.toHexString(uint160(account), 20),
                        " is missing role ",
                        Strings.toHexString(uint256(role), 32)
                    )
                )
            );
        }
    }

	function hasRole(bytes32 role, address account) public view virtual returns (bool);

	function getRoleAdmin(bytes32 role) public view virtual returns (bytes32);

	function getRoleMember(bytes32 role, uint256 index) public view virtual returns (address);

	function getRoleMemberCount(bytes32 role) public view virtual returns (uint256);

	function _setRoleAdmin(bytes32 role, bytes32 adminRole) internal virtual;

	function _grantRole(bytes32 role, address account) internal virtual;

	function _revokeRole(bytes32 role, address account) internal virtual;
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/Context.sol)

pragma solidity ^0.8.0;

/**
 * @dev Provides information about the current execution context, including the
 * sender of the transaction and its data. While these are generally available
 * via msg.sender and msg.data, they should not be accessed in such a direct
 * manner, since when dealing with meta-transactions the account sending and
 * paying for execution may not be the actual sender (as far as an application
 * is concerned).
 *
 * This contract is only required for intermediate, library-like contracts.
 */
abstract contract Context {
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes calldata) {
        return msg.data;
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/Strings.sol)

pragma solidity ^0.8.0;

/**
 * @dev String operations.
 */
library Strings {
    bytes16 private constant _HEX_SYMBOLS = "0123456789abcdef";

    /**
     * @dev Converts a `uint256` to its ASCII `string` decimal representation.
     */
    function toString(uint256 value) internal pure returns (string memory) {
        // Inspired by OraclizeAPI's implementation - MIT licence
        // https://github.com/oraclize/ethereum-api/blob/b42146b063c7d6ee1358846c198246239e9360e8/oraclizeAPI_0.4.25.sol

        if (value == 0) {
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

    /**
     * @dev Converts a `uint256` to its ASCII `string` hexadecimal representation.
     */
    function toHexString(uint256 value) internal pure returns (string memory) {
        if (value == 0) {
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

    /**
     * @dev Converts a `uint256` to its ASCII `string` hexadecimal representation with fixed length.
     */
    function toHexString(uint256 value, uint256 length) internal pure returns (string memory) {
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

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/structs/EnumerableSet.sol)

pragma solidity ^0.8.0;

/**
 * @dev Library for managing
 * https://en.wikipedia.org/wiki/Set_(abstract_data_type)[sets] of primitive
 * types.
 *
 * Sets have the following properties:
 *
 * - Elements are added, removed, and checked for existence in constant time
 * (O(1)).
 * - Elements are enumerated in O(n). No guarantees are made on the ordering.
 *
 * ```
 * contract Example {
 *     // Add the library methods
 *     using EnumerableSet for EnumerableSet.AddressSet;
 *
 *     // Declare a set state variable
 *     EnumerableSet.AddressSet private mySet;
 * }
 * ```
 *
 * As of v3.3.0, sets of type `bytes32` (`Bytes32Set`), `address` (`AddressSet`)
 * and `uint256` (`UintSet`) are supported.
 */
library EnumerableSet {
    // To implement this library for multiple types with as little code
    // repetition as possible, we write it in terms of a generic Set type with
    // bytes32 values.
    // The Set implementation uses private functions, and user-facing
    // implementations (such as AddressSet) are just wrappers around the
    // underlying Set.
    // This means that we can only create new EnumerableSets for types that fit
    // in bytes32.

    struct Set {
        // Storage of set values
        bytes32[] _values;
        // Position of the value in the `values` array, plus 1 because index 0
        // means a value is not in the set.
        mapping(bytes32 => uint256) _indexes;
    }

    /**
     * @dev Add a value to a set. O(1).
     *
     * Returns true if the value was added to the set, that is if it was not
     * already present.
     */
    function _add(Set storage set, bytes32 value) private returns (bool) {
        if (!_contains(set, value)) {
            set._values.push(value);
            // The value is stored at length-1, but we add 1 to all indexes
            // and use 0 as a sentinel value
            set._indexes[value] = set._values.length;
            return true;
        } else {
            return false;
        }
    }

    /**
     * @dev Removes a value from a set. O(1).
     *
     * Returns true if the value was removed from the set, that is if it was
     * present.
     */
    function _remove(Set storage set, bytes32 value) private returns (bool) {
        // We read and store the value's index to prevent multiple reads from the same storage slot
        uint256 valueIndex = set._indexes[value];

        if (valueIndex != 0) {
            // Equivalent to contains(set, value)
            // To delete an element from the _values array in O(1), we swap the element to delete with the last one in
            // the array, and then remove the last element (sometimes called as 'swap and pop').
            // This modifies the order of the array, as noted in {at}.

            uint256 toDeleteIndex = valueIndex - 1;
            uint256 lastIndex = set._values.length - 1;

            if (lastIndex != toDeleteIndex) {
                bytes32 lastvalue = set._values[lastIndex];

                // Move the last value to the index where the value to delete is
                set._values[toDeleteIndex] = lastvalue;
                // Update the index for the moved value
                set._indexes[lastvalue] = valueIndex; // Replace lastvalue's index to valueIndex
            }

            // Delete the slot where the moved value was stored
            set._values.pop();

            // Delete the index for the deleted slot
            delete set._indexes[value];

            return true;
        } else {
            return false;
        }
    }

    /**
     * @dev Returns true if the value is in the set. O(1).
     */
    function _contains(Set storage set, bytes32 value) private view returns (bool) {
        return set._indexes[value] != 0;
    }

    /**
     * @dev Returns the number of values on the set. O(1).
     */
    function _length(Set storage set) private view returns (uint256) {
        return set._values.length;
    }

    /**
     * @dev Returns the value stored at position `index` in the set. O(1).
     *
     * Note that there are no guarantees on the ordering of values inside the
     * array, and it may change when more values are added or removed.
     *
     * Requirements:
     *
     * - `index` must be strictly less than {length}.
     */
    function _at(Set storage set, uint256 index) private view returns (bytes32) {
        return set._values[index];
    }

    /**
     * @dev Return the entire set in an array
     *
     * WARNING: This operation will copy the entire storage to memory, which can be quite expensive. This is designed
     * to mostly be used by view accessors that are queried without any gas fees. Developers should keep in mind that
     * this function has an unbounded cost, and using it as part of a state-changing function may render the function
     * uncallable if the set grows to a point where copying to memory consumes too much gas to fit in a block.
     */
    function _values(Set storage set) private view returns (bytes32[] memory) {
        return set._values;
    }

    // Bytes32Set

    struct Bytes32Set {
        Set _inner;
    }

    /**
     * @dev Add a value to a set. O(1).
     *
     * Returns true if the value was added to the set, that is if it was not
     * already present.
     */
    function add(Bytes32Set storage set, bytes32 value) internal returns (bool) {
        return _add(set._inner, value);
    }

    /**
     * @dev Removes a value from a set. O(1).
     *
     * Returns true if the value was removed from the set, that is if it was
     * present.
     */
    function remove(Bytes32Set storage set, bytes32 value) internal returns (bool) {
        return _remove(set._inner, value);
    }

    /**
     * @dev Returns true if the value is in the set. O(1).
     */
    function contains(Bytes32Set storage set, bytes32 value) internal view returns (bool) {
        return _contains(set._inner, value);
    }

    /**
     * @dev Returns the number of values in the set. O(1).
     */
    function length(Bytes32Set storage set) internal view returns (uint256) {
        return _length(set._inner);
    }

    /**
     * @dev Returns the value stored at position `index` in the set. O(1).
     *
     * Note that there are no guarantees on the ordering of values inside the
     * array, and it may change when more values are added or removed.
     *
     * Requirements:
     *
     * - `index` must be strictly less than {length}.
     */
    function at(Bytes32Set storage set, uint256 index) internal view returns (bytes32) {
        return _at(set._inner, index);
    }

    /**
     * @dev Return the entire set in an array
     *
     * WARNING: This operation will copy the entire storage to memory, which can be quite expensive. This is designed
     * to mostly be used by view accessors that are queried without any gas fees. Developers should keep in mind that
     * this function has an unbounded cost, and using it as part of a state-changing function may render the function
     * uncallable if the set grows to a point where copying to memory consumes too much gas to fit in a block.
     */
    function values(Bytes32Set storage set) internal view returns (bytes32[] memory) {
        return _values(set._inner);
    }

    // AddressSet

    struct AddressSet {
        Set _inner;
    }

    /**
     * @dev Add a value to a set. O(1).
     *
     * Returns true if the value was added to the set, that is if it was not
     * already present.
     */
    function add(AddressSet storage set, address value) internal returns (bool) {
        return _add(set._inner, bytes32(uint256(uint160(value))));
    }

    /**
     * @dev Removes a value from a set. O(1).
     *
     * Returns true if the value was removed from the set, that is if it was
     * present.
     */
    function remove(AddressSet storage set, address value) internal returns (bool) {
        return _remove(set._inner, bytes32(uint256(uint160(value))));
    }

    /**
     * @dev Returns true if the value is in the set. O(1).
     */
    function contains(AddressSet storage set, address value) internal view returns (bool) {
        return _contains(set._inner, bytes32(uint256(uint160(value))));
    }

    /**
     * @dev Returns the number of values in the set. O(1).
     */
    function length(AddressSet storage set) internal view returns (uint256) {
        return _length(set._inner);
    }

    /**
     * @dev Returns the value stored at position `index` in the set. O(1).
     *
     * Note that there are no guarantees on the ordering of values inside the
     * array, and it may change when more values are added or removed.
     *
     * Requirements:
     *
     * - `index` must be strictly less than {length}.
     */
    function at(AddressSet storage set, uint256 index) internal view returns (address) {
        return address(uint160(uint256(_at(set._inner, index))));
    }

    /**
     * @dev Return the entire set in an array
     *
     * WARNING: This operation will copy the entire storage to memory, which can be quite expensive. This is designed
     * to mostly be used by view accessors that are queried without any gas fees. Developers should keep in mind that
     * this function has an unbounded cost, and using it as part of a state-changing function may render the function
     * uncallable if the set grows to a point where copying to memory consumes too much gas to fit in a block.
     */
    function values(AddressSet storage set) internal view returns (address[] memory) {
        bytes32[] memory store = _values(set._inner);
        address[] memory result;

        assembly {
            result := store
        }

        return result;
    }

    // UintSet

    struct UintSet {
        Set _inner;
    }

    /**
     * @dev Add a value to a set. O(1).
     *
     * Returns true if the value was added to the set, that is if it was not
     * already present.
     */
    function add(UintSet storage set, uint256 value) internal returns (bool) {
        return _add(set._inner, bytes32(value));
    }

    /**
     * @dev Removes a value from a set. O(1).
     *
     * Returns true if the value was removed from the set, that is if it was
     * present.
     */
    function remove(UintSet storage set, uint256 value) internal returns (bool) {
        return _remove(set._inner, bytes32(value));
    }

    /**
     * @dev Returns true if the value is in the set. O(1).
     */
    function contains(UintSet storage set, uint256 value) internal view returns (bool) {
        return _contains(set._inner, bytes32(value));
    }

    /**
     * @dev Returns the number of values on the set. O(1).
     */
    function length(UintSet storage set) internal view returns (uint256) {
        return _length(set._inner);
    }

    /**
     * @dev Returns the value stored at position `index` in the set. O(1).
     *
     * Note that there are no guarantees on the ordering of values inside the
     * array, and it may change when more values are added or removed.
     *
     * Requirements:
     *
     * - `index` must be strictly less than {length}.
     */
    function at(UintSet storage set, uint256 index) internal view returns (uint256) {
        return uint256(_at(set._inner, index));
    }

    /**
     * @dev Return the entire set in an array
     *
     * WARNING: This operation will copy the entire storage to memory, which can be quite expensive. This is designed
     * to mostly be used by view accessors that are queried without any gas fees. Developers should keep in mind that
     * this function has an unbounded cost, and using it as part of a state-changing function may render the function
     * uncallable if the set grows to a point where copying to memory consumes too much gas to fit in a block.
     */
    function values(UintSet storage set) internal view returns (uint256[] memory) {
        bytes32[] memory store = _values(set._inner);
        uint256[] memory result;

        assembly {
            result := store
        }

        return result;
    }
}