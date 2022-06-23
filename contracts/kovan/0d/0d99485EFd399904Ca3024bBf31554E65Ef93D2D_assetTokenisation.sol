/**
 *Submitted for verification at Etherscan.io on 2022-06-23
*/

/**
 *Submitted for verification at Etherscan.io on 2022-05-30
*/

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

//import 'hardhat/console.sol';

interface IERC20 {
  /**
   * @dev Returns the amount of tokens in existence.
   */
  function totalSupply() external view returns (uint256);

  /**
   * @dev Returns the token decimals.
   */
  function decimals() external view returns (uint8);

  /**
   * @dev Returns the token symbol.
   */
  function symbol() external view returns (string memory);

  /**
  * @dev Returns the token name.
  */
  function name() external view returns (string memory);

  /**
   * @dev Returns the bep token owner.
   */
  function getOwner() external view returns (address);

  /**
   * @dev Returns the amount of tokens owned by `account`.
   */
  function balanceOf(address account) external view returns (uint256);

  /**
   * @dev Moves `amount` tokens from the caller's account to `recipient`.
   *
   * Returns a boolean value indicating whether the operation succeeded.
   *
   * Emits a {Transfer} event.
   */
  function transfer(address recipient, uint256 amount) external returns (bool);

  /**
   * @dev Returns the remaining number of tokens that `spender` will be
   * allowed to spend on behalf of `owner` through {transferFrom}. This is
   * zero by default.
   *
   * This value changes when {approve} or {transferFrom} are called.
   */
  function allowance(address _owner, address spender) external view returns (uint256);

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
   * @dev Moves `amount` tokens from `sender` to `recipient` using the
   * allowance mechanism. `amount` is then deducted from the caller's
   * allowance.
   *
   * Returns a boolean value indicating whether the operation succeeded.
   *
   * Emits a {Transfer} event.
   */
  function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);

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
}

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
     *
     * [IMPORTANT]
     * ====
     * You shouldn't rely on `isContract` to protect against flash loan attacks!
     *
     * Preventing calls from contracts is highly discouraged. It breaks composability, breaks support for smart wallets
     * like Gnosis Safe, and does not provide security since it can be circumvented by calling from a contract
     * constructor.
     * ====
     */
    function isContract(address account) internal view returns (bool) {
        // This method relies on extcodesize/address.code.length, which returns 0
        // for contracts in construction, since the code is only stored at the end
        // of the constructor execution.

        return account.code.length > 0;
    }
}


interface IERC165 {
    /**
     * @dev Returns true if this contract implements the interface defined by
     * `interfaceId`. See the corresponding
     * https://eips.ethereum.org/EIPS/eip-165#how-interfaces-are-identified[EIP section]
     * to learn more about how these ids are created.
     *
     * This function call must use less than 30 000 gas.
     */
    function supportsInterface(bytes4 interfaceId) external view returns (bool);
}

abstract contract ERC165 is IERC165 {
    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId) public view virtual override returns (bool) {
        return interfaceId == type(IERC165).interfaceId;
    }
}

abstract contract Context {
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes calldata) {
        return msg.data;
    }
}

interface IERC1155 is IERC165 {
    /**
     * @dev Emitted when `value` tokens of token type `id` are transferred from `from` to `to` by `operator`.
     */
    event TransferSingle(address indexed operator, address indexed from, address indexed to, uint256 id, uint256 value);

    /**
     * @dev Equivalent to multiple {TransferSingle} events, where `operator`, `from` and `to` are the same for all
     * transfers.
     */
    event TransferBatch(
        address indexed operator,
        address indexed from,
        address indexed to,
        uint256[] ids,
        uint256[] values
    );

    /**
     * @dev Emitted when `account` grants or revokes permission to `operator` to transfer their tokens, according to
     * `approved`.
     */
    event ApprovalForAll(address indexed account, address indexed operator, bool approved);

    /**
     * @dev Emitted when the URI for token type `id` changes to `value`, if it is a non-programmatic URI.
     *
     * If an {URI} event was emitted for `id`, the standard
     * https://eips.ethereum.org/EIPS/eip-1155#metadata-extensions[guarantees] that `value` will equal the value
     * returned by {IERC1155MetadataURI-uri}.
     */
    event URI(string value, uint256 indexed id);

    /**
     * @dev Returns the amount of tokens of token type `id` owned by `account`.
     *
     * Requirements:
     *
     * - `account` cannot be the zero address.
     */
    function balanceOf(address account, uint256 id) external view returns (uint256);

    /**
     * @dev xref:ROOT:erc1155.adoc#batch-operations[Batched] version of {balanceOf}.
     *
     * Requirements:
     *
     * - `accounts` and `ids` must have the same length.
     */
    function balanceOfBatch(address[] calldata accounts, uint256[] calldata ids)
        external
        view
        returns (uint256[] memory);

    /**
     * @dev Grants or revokes permission to `operator` to transfer the caller's tokens, according to `approved`,
     *
     * Emits an {ApprovalForAll} event.
     *
     * Requirements:
     *
     * - `operator` cannot be the caller.
     */
    function setApprovalForAll(address operator, bool approved) external;

    /**
     * @dev Returns true if `operator` is approved to transfer ``account``'s tokens.
     *
     * See {setApprovalForAll}.
     */
    function isApprovedForAll(address account, address operator) external view returns (bool);

    /**
     * @dev Transfers `amount` tokens of token type `id` from `from` to `to`.
     *
     * Emits a {TransferSingle} event.
     *
     * Requirements:
     *
     * - `to` cannot be the zero address.
     * - If the caller is not `from`, it must be have been approved to spend ``from``'s tokens via {setApprovalForAll}.
     * - `from` must have a balance of tokens of type `id` of at least `amount`.
     * - If `to` refers to a smart contract, it must implement {IERC1155Receiver-onERC1155Received} and return the
     * acceptance magic value.
     */
    function safeTransferFrom(
        address from,
        address to,
        uint256 id,
        uint256 amount,
        bytes calldata data
    ) external;

    /**
     * @dev xref:ROOT:erc1155.adoc#batch-operations[Batched] version of {safeTransferFrom}.
     *
     * Emits a {TransferBatch} event.
     *
     * Requirements:
     *
     * - `ids` and `amounts` must have the same length.
     * - If `to` refers to a smart contract, it must implement {IERC1155Receiver-onERC1155BatchReceived} and return the
     * acceptance magic value.
     */
    function safeBatchTransferFrom(
        address from,
        address to,
        uint256[] calldata ids,
        uint256[] calldata amounts,
        bytes calldata data
    ) external;
}

interface IERC1155Receiver is IERC165 {
    /**
     * @dev Handles the receipt of a single ERC1155 token type. This function is
     * called at the end of a `safeTransferFrom` after the balance has been updated.
     *
     * NOTE: To accept the transfer, this must return
     * `bytes4(keccak256("onERC1155Received(address,address,uint256,uint256,bytes)"))`
     * (i.e. 0xf23a6e61, or its own function selector).
     *
     * @param operator The address which initiated the transfer (i.e. msg.sender)
     * @param from The address which previously owned the token
     * @param id The ID of the token being transferred
     * @param value The amount of tokens being transferred
     * @param data Additional data with no specified format
     * @return `bytes4(keccak256("onERC1155Received(address,address,uint256,uint256,bytes)"))` if transfer is allowed
     */
    function onERC1155Received(
        address operator,
        address from,
        uint256 id,
        uint256 value,
        bytes calldata data
    ) external returns (bytes4);

    /**
     * @dev Handles the receipt of a multiple ERC1155 token types. This function
     * is called at the end of a `safeBatchTransferFrom` after the balances have
     * been updated.
     *
     * NOTE: To accept the transfer(s), this must return
     * `bytes4(keccak256("onERC1155BatchReceived(address,address,uint256[],uint256[],bytes)"))`
     * (i.e. 0xbc197c81, or its own function selector).
     *
     * @param operator The address which initiated the batch transfer (i.e. msg.sender)
     * @param from The address which previously owned the token
     * @param ids An array containing ids of each token being transferred (order and length must match values array)
     * @param values An array containing amounts of each token being transferred (order and length must match ids array)
     * @param data Additional data with no specified format
     * @return `bytes4(keccak256("onERC1155BatchReceived(address,address,uint256[],uint256[],bytes)"))` if transfer is allowed
     */
    function onERC1155BatchReceived(
        address operator,
        address from,
        uint256[] calldata ids,
        uint256[] calldata values,
        bytes calldata data
    ) external returns (bytes4);
}

interface IERC1155MetadataURI is IERC1155 {
    /**
     * @dev Returns the URI for token type `id`.
     *
     * If the `\{id\}` substring is present in the URI, it must be replaced by
     * clients with the actual token type ID.
     */
    function uri(uint256 id) external view returns (string memory);
}
/**
 * @dev Implementation of the basic standard multi-token.
 * See https://eips.ethereum.org/EIPS/eip-1155
 * Originally based on code by Enjin: https://github.com/enjin/erc-1155
 *
 * _Available since v3.1._
 */
contract ERC1155 is Context, ERC165, IERC1155MetadataURI {
    using Address for address;

    // Mapping from token ID to account balances
    mapping(uint256 => mapping(address => uint256)) private _balances;

    // Mapping from account to operator approvals
    mapping(address => mapping(address => bool)) private _operatorApprovals;

    // Used as the URI for all token types by relying on ID substitution, e.g. https://token-cdn-domain/{id}.json
    string private _uri;

    mapping(address => mapping(address => bool)) public isWhiteListed;

    modifier checker(address _sender,address _reciever) {
        require(isWhiteListed[_sender][_reciever],"User Cannot Transfer");
        _;
    } 

    /**
     * @dev See {_setURI}.
     */

    // constructor(string memory uri_) {
    //     _setURI(uri_);
    // }

    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId) public view virtual override(ERC165, IERC165) returns (bool) {
        return
            interfaceId == type(IERC1155).interfaceId ||
            interfaceId == type(IERC1155MetadataURI).interfaceId ||
            super.supportsInterface(interfaceId);
    }

    /**
     * @dev See {IERC1155MetadataURI-uri}.
     *
     * This implementation returns the same URI for *all* token types. It relies
     * on the token type ID substitution mechanism
     * https://eips.ethereum.org/EIPS/eip-1155#metadata[defined in the EIP].
     *
     * Clients calling this function must replace the `\{id\}` substring with the
     * actual token type ID.
     */
    function uri(uint256) public view virtual override returns (string memory) {
        return _uri;
    }

    /**
     * @dev See {IERC1155-balanceOf}.
     *
     * Requirements:
     *
     * - `account` cannot be the zero address.
     */
    function balanceOf(address account, uint256 id) public view virtual override returns (uint256) {
        require(account != address(0), "ERC1155: balance query for the zero address");
        return _balances[id][account];
    }

    /**
     * @dev See {IERC1155-balanceOfBatch}.
     *
     * Requirements:
     *
     * - `accounts` and `ids` must have the same length.
     */
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

    /**
     * @dev See {IERC1155-setApprovalForAll}.
     */
    function setApprovalForAll(address operator, bool approved) public virtual override {
        _setApprovalForAll(_msgSender(), operator, approved);
    }

    /**
     * @dev See {IERC1155-isApprovedForAll}.
     */
    function isApprovedForAll(address account, address operator) public view virtual override returns (bool) {
        return _operatorApprovals[account][operator];
    }

    /**
     * @dev See {IERC1155-safeTransferFrom}.
     */
    function safeTransferFrom(
        address from,
        address to,
        uint256 id,
        uint256 amount,
        bytes memory data
    ) public virtual override checker(from, to){
        require(
            from == _msgSender() || isApprovedForAll(from, _msgSender()),
            "ERC1155: caller is not owner nor approved"
        );
        _safeTransferFrom(from, to, id, amount, data);
    }

    /**
     * @dev See {IERC1155-safeBatchTransferFrom}.
     */
    function safeBatchTransferFrom(
        address from,
        address to,
        uint256[] memory ids,
        uint256[] memory amounts,
        bytes memory data
    ) public virtual override {
        require(
            from == _msgSender() || isApprovedForAll(from, _msgSender()),
            "ERC1155: transfer caller is not owner nor approved"
        );
        _safeBatchTransferFrom(from, to, ids, amounts, data);
    }

    /**
     * @dev Transfers `amount` tokens of token type `id` from `from` to `to`.
     *
     * Emits a {TransferSingle} event.
     *
     * Requirements:
     *
     * - `to` cannot be the zero address.
     * - `from` must have a balance of tokens of type `id` of at least `amount`.
     * - If `to` refers to a smart contract, it must implement {IERC1155Receiver-onERC1155Received} and return the
     * acceptance magic value.
     */
    function _safeTransferFrom(
        address from,
        address to,
        uint256 id,
        uint256 amount,
        bytes memory data
    ) internal virtual {
        require(to != address(0), "ERC1155: transfer to the zero address");

        address operator = _msgSender();

        _beforeTokenTransfer(operator, from, to, _asSingletonArray(id), _asSingletonArray(amount), data);

        uint256 fromBalance = _balances[id][from];
        require(fromBalance >= amount, "ERC1155: insufficient balance for transfer");
        unchecked {
            _balances[id][from] = fromBalance - amount;
        }
        _balances[id][to] += amount;

        emit TransferSingle(operator, from, to, id, amount);

        _doSafeTransferAcceptanceCheck(operator, from, to, id, amount, data);
    }

    /**
     * @dev xref:ROOT:erc1155.adoc#batch-operations[Batched] version of {_safeTransferFrom}.
     *
     * Emits a {TransferBatch} event.
     *
     * Requirements:
     *
     * - If `to` refers to a smart contract, it must implement {IERC1155Receiver-onERC1155BatchReceived} and return the
     * acceptance magic value.
     */
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

        _doSafeBatchTransferAcceptanceCheck(operator, from, to, ids, amounts, data);
    }

    /**
     * @dev Sets a new URI for all token types, by relying on the token type ID
     * substitution mechanism
     * https://eips.ethereum.org/EIPS/eip-1155#metadata[defined in the EIP].
     *
     * By this mechanism, any occurrence of the `\{id\}` substring in either the
     * URI or any of the amounts in the JSON file at said URI will be replaced by
     * clients with the token type ID.
     *
     * For example, the `https://token-cdn-domain/\{id\}.json` URI would be
     * interpreted by clients as
     * `https://token-cdn-domain/000000000000000000000000000000000000000000000000000000000004cce0.json`
     * for token type ID 0x4cce0.
     *
     * See {uri}.
     *
     * Because these URIs cannot be meaningfully represented by the {URI} event,
     * this function emits no events.
     */
    function _setURI(string memory newuri) internal virtual {
        _uri = newuri;
    }

    /**
     * @dev Creates `amount` tokens of token type `id`, and assigns them to `to`.
     *
     * Emits a {TransferSingle} event.
     *
     * Requirements:
     *
     * - `to` cannot be the zero address.
     * - If `to` refers to a smart contract, it must implement {IERC1155Receiver-onERC1155Received} and return the
     * acceptance magic value.
     */
    function _mint(
        address to,
        uint256 id,
        uint256 amount,
        bytes memory data
    ) internal virtual {
        require(to != address(0), "ERC1155: mint to the zero address");

        address operator = _msgSender();

        _beforeTokenTransfer(operator, address(0), to, _asSingletonArray(id), _asSingletonArray(amount), data);

        _balances[id][to] += amount;
        emit TransferSingle(operator, address(0), to, id, amount);

        _doSafeTransferAcceptanceCheck(operator, address(0), to, id, amount, data);
    }

    /**
     * @dev xref:ROOT:erc1155.adoc#batch-operations[Batched] version of {_mint}.
     *
     * Requirements:
     *
     * - `ids` and `amounts` must have the same length.
     * - If `to` refers to a smart contract, it must implement {IERC1155Receiver-onERC1155BatchReceived} and return the
     * acceptance magic value.
     */
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

        _doSafeBatchTransferAcceptanceCheck(operator, address(0), to, ids, amounts, data);
    }

    /**
     * @dev Destroys `amount` tokens of token type `id` from `from`
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `from` must have at least `amount` tokens of token type `id`.
     */
    function _burn(
        address from,
        uint256 id,
        uint256 amount
    ) internal virtual {
        require(from != address(0), "ERC1155: burn from the zero address");

        address operator = _msgSender();

        _beforeTokenTransfer(operator, from, address(0), _asSingletonArray(id), _asSingletonArray(amount), "");

        uint256 fromBalance = _balances[id][from];
        require(fromBalance >= amount, "ERC1155: burn amount exceeds balance");
        unchecked {
            _balances[id][from] = fromBalance - amount;
        }

        emit TransferSingle(operator, from, address(0), id, amount);
    }

    /**
     * @dev xref:ROOT:erc1155.adoc#batch-operations[Batched] version of {_burn}.
     *
     * Requirements:
     *
     * - `ids` and `amounts` must have the same length.
     */
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
    }

    /**
     * @dev Approve `operator` to operate on all of `owner` tokens
     *
     * Emits a {ApprovalForAll} event.
     */
    function _setApprovalForAll(
        address owner,
        address operator,
        bool approved
    ) internal virtual {
        require(owner != operator, "ERC1155: setting approval status for self");
        _operatorApprovals[owner][operator] = approved;
        emit ApprovalForAll(owner, operator, approved);
    }

    /**
     * @dev Hook that is called before any token transfer. This includes minting
     * and burning, as well as batched variants.
     *
     * The same hook is called on both single and batched variants. For single
     * transfers, the length of the `id` and `amount` arrays will be 1.
     *
     * Calling conditions (for each `id` and `amount` pair):
     *
     * - When `from` and `to` are both non-zero, `amount` of ``from``'s tokens
     * of token type `id` will be  transferred to `to`.
     * - When `from` is zero, `amount` tokens of token type `id` will be minted
     * for `to`.
     * - when `to` is zero, `amount` of ``from``'s tokens of token type `id`
     * will be burned.
     * - `from` and `to` are never both zero.
     * - `ids` and `amounts` have the same, non-zero length.
     *
     * To learn more about hooks, head to xref:ROOT:extending-contracts.adoc#using-hooks[Using Hooks].
     */
    function _beforeTokenTransfer(
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

abstract contract Ownable {
    address private _owner;
    
    event OwnershipTransferred(
    address indexed previousOwner,
    address indexed newOwner
    );
    
    constructor()  {
    _owner = msg.sender;
    emit OwnershipTransferred(address(0), _owner);
    }
    
    function owner() public view returns (address) {
    return _owner;
    }
    
    modifier onlyOwner() {
    require(isOwner(), "Ownable: caller is not the owner");
    _;
    }
    
    function isOwner() public view returns (bool) {
    return msg.sender == _owner;
    }
    
    function renounceOwnership() public onlyOwner {
    emit OwnershipTransferred(_owner, address(0));
    _owner = address(0);
    }
    
    function transferOwnership(address newOwner) public onlyOwner {
    _transferOwnership(newOwner);
    }
    
    function _transferOwnership(address newOwner) internal {
    require(
    newOwner != address(0), 
    "Ownable: new owner is the zero address"
    );
    emit OwnershipTransferred(_owner, newOwner);
    _owner = newOwner;
    }
}

contract assetTokenisation is ERC1155, Ownable {

    uint256 Id;
    IERC20 USDC = IERC20(0x05b32da9f8e984E587D828793eC2eF608Af2a25F);   //For Kovan Testnet   //0x2519f6FC924BE4ac916152059C46E1bFeB5CfFcC
    uint256 maintenanceFees;

    struct Property {
        string propertyId;
        uint256 propertyTokenId;
        uint256 propertyNFTId;
        uint256 propertyPrice;
        uint256 totalinvestmentPortion;
        uint256 leftinvestmentPortion;
        uint256 rentAmount;
        uint256 propertyEpochTime;
        bool isPropertyAdded;
    }

     struct User {
        string userId;
        address user;
        bool isUserAdded;
        bool hasProperty;
        bool isOwner;                           
        string[] properties;
    }

    struct userDividend {
        string userId;
        uint256 amount;
    }

    struct Token {
        uint256 tokenId;
        uint256 totalTokens;
        bool isNFT;
    }

    mapping(string => mapping(string => uint256)) public propertywiseInvestment;    //userid ; propertyid ; balance
    mapping(uint256 => mapping(address => uint256)) balances;                       //tokenid ; user address; balance
    mapping(string => User) public userDetails;                                     //userid ; User Struct
    mapping(string => Property) public propertyDetails;                             //propertyid; Property struct
    mapping(uint256 => Token) public tokenDetails;                                  //tokenid ; Token Struct
    mapping(string => string) public propertyOwner;                                 //propertyid; user address
    mapping(string => mapping(string => bool)) isInvestor;                          //propertyid; userid; true/false
    mapping(string => string[]) public investors;                                   //propertyid; investorid's
    mapping(string => mapping(string => uint256)) public investmentTime;            //investorid; propertyid; timestamp
    mapping(string => mapping(string => uint256)) public paymentTokenId;            //userid; propertyid; tokenid

    event UserAdded(string _userId, address user);
    event PropertyAdded(string _userId, string _propertyId, uint256 _propertyNFTId); 
    event PropertyListed(string _userId, string _propertyId, uint256 _propertyTokenId);
    event DividendTransferred(string _userId, string indexed _propertyId, uint256 _dividendAmount);
    event propertyBought(string _userId, string _propertyId, uint256 _amountInvested);
    event propertySold(string _userId, string _propertyId, uint256 _amountWithdrawn);

    modifier hasProperty(string memory userId) {
        require(userDetails[userId].hasProperty, "Property hasn't been added yet");
        _;
    }

    function setMaintenancePer(uint256 _percentValue) public onlyOwner {
        maintenanceFees = _percentValue;
    }

    function getMaintenancePer() public view returns (uint256) {
        return maintenanceFees;
    }

    function _generateId() internal returns (uint256) {       
        Id = Id + 1;
        return Id;

    }

    function updateRent(string memory _propertyId, uint256 _updatedAmount) public onlyOwner {
        propertyDetails[_propertyId].rentAmount = _updatedAmount;

    }

    function addProperty(string memory _userId, address _user, string memory _propertyId, uint256 _propertyPrice,
        uint256 _rentAmount, uint256 _investmentPortion) public onlyOwner {
            
        require(!propertyDetails[_propertyId].isPropertyAdded, "Property is already registered/added");
        if(!userDetails[_userId].isUserAdded) {
            userDetails[_userId].userId = _userId;
            userDetails[_userId].user = _user;
            userDetails[_userId].hasProperty = false;
            userDetails[_userId].isUserAdded = true;
        
            emit UserAdded(_userId, userDetails[_userId].user);
        }
          
        propertyDetails[_propertyId].propertyId = _propertyId;
        propertyDetails[_propertyId].propertyPrice = _propertyPrice;
        propertyDetails[_propertyId].rentAmount = _rentAmount;
        uint256 _propertyTokenId = _generateId();
        propertyDetails[_propertyId].propertyTokenId = _propertyTokenId;
        tokenDetails[_propertyTokenId].tokenId= _propertyTokenId;
        tokenDetails[_propertyTokenId].isNFT = false;
        propertyOwner[_propertyId] = userDetails[_userId].userId;
        userDetails[_userId].isOwner = true;
        userDetails[_userId].hasProperty = true;
        userDetails[_userId].properties.push(_propertyId);
        uint256 _tokenId = _generateId();
        propertyDetails[_propertyId].propertyNFTId = _tokenId;
        tokenDetails[_tokenId].tokenId = _tokenId;
        tokenDetails[_tokenId].totalTokens = 1;   
        _mint(userDetails[_userId].user, tokenDetails[_tokenId].tokenId, tokenDetails[_tokenId].totalTokens, "");
        tokenDetails[_tokenId].isNFT = true; 
        balances[_tokenId][userDetails[_userId].user] = 1;
        propertyDetails[_propertyId].isPropertyAdded = true;
        propertyDetails[_propertyId].propertyEpochTime = block.timestamp; 

        emit PropertyAdded(_userId, _propertyId, propertyDetails[_propertyId].propertyNFTId);

        propertyDetails[_propertyId].totalinvestmentPortion = _investmentPortion;   //investmentPortion is the part of the property the owner wants investment for
        propertyDetails[_propertyId].leftinvestmentPortion = _investmentPortion;
        _mint(owner(), propertyDetails[_propertyId].propertyTokenId, _investmentPortion, "" );    //Create Property specific fungible tokens based on ERC1155 standard
        tokenDetails[propertyDetails[_propertyId].propertyTokenId].totalTokens = _investmentPortion; //The amount of property specific tokens created is equals to investment portion
        balances[propertyDetails[_propertyId].propertyTokenId][userDetails[_userId].user] = _investmentPortion;

        emit PropertyListed(_userId, _propertyId, propertyDetails[_propertyId].propertyTokenId);
    }

    function getUserDetails(string memory _userId) public view returns(string memory, address , bool) {
        return(userDetails[_userId].userId, userDetails[_userId].user, userDetails[_userId].hasProperty);
    }
    
    function getPropertyDetails(string memory _propertyId) public view returns(string memory, uint256, uint256, uint256, uint256) {
        return(propertyDetails[_propertyId].propertyId, propertyDetails[_propertyId].propertyPrice, 
                    propertyDetails[_propertyId].totalinvestmentPortion, propertyDetails[_propertyId].rentAmount, propertyDetails[_propertyId].propertyTokenId);
    }

    function getTokenDetails(uint256 _tokenId) public view returns(uint256, uint256, bool) {
        return(tokenDetails[_tokenId].tokenId, tokenDetails[_tokenId].totalTokens, tokenDetails[_tokenId].isNFT);
    }

    function invest(string memory _investoruserId, address _user, string memory _propertyId, uint256 _amount) public onlyOwner { 
        require(propertyDetails[_propertyId].leftinvestmentPortion >= _amount , "Insufficient investment portion");
        if(!userDetails[_investoruserId].isUserAdded) {
            userDetails[_investoruserId].userId = _investoruserId;
            userDetails[_investoruserId].user = _user;
            userDetails[_investoruserId].hasProperty = false;
            userDetails[_investoruserId].isUserAdded = true;
            isWhiteListed[owner()][_user] = true;
            isWhiteListed[_user][owner()] = true;
        
            emit UserAdded(_investoruserId, userDetails[_investoruserId].user);
        }

        safeTransferFrom(owner(), userDetails[_investoruserId].user, propertyDetails[_propertyId].propertyTokenId, _amount, "");
        propertyDetails[_propertyId].leftinvestmentPortion -= _amount;
        propertywiseInvestment[_investoruserId][_propertyId] += _amount;
        investmentTime[_investoruserId][_propertyId] = block.timestamp;
        investors[_propertyId].push(_investoruserId);
        isInvestor[_propertyId][_investoruserId] = true;

        emit propertyBought(_investoruserId, _propertyId, _amount);
    }

    function transferDividend(string memory _propertyId) public onlyOwner returns(userDividend[] memory){ 
        require(USDC.balanceOf(owner()) >= propertyDetails[_propertyId].rentAmount,"Insufficient owner balance");
        require(maintenanceFees != 0, "Set Maintenance Fees");
        require(propertyDetails[_propertyId].isPropertyAdded, "Property is not added yet");
        uint256 _rentAmount = propertyDetails[_propertyId].rentAmount;
        uint256 _maintenanceFee = (_rentAmount * maintenanceFees) / 100 ;
        _rentAmount = _rentAmount - _maintenanceFee;
        uint256 _investmentPortion = propertyDetails[_propertyId].totalinvestmentPortion;
        uint256 currentTime = block.timestamp;
        uint256 epochTime = currentTime - propertyDetails[_propertyId].propertyEpochTime;
        userDividend[] memory dividendAmountList = new userDividend[](investors[_propertyId].length);


        for(uint256 i = 0; i< investors[_propertyId].length; i++) {
            string memory _investoruserId = userDetails[investors[_propertyId][i]].userId;
            if(isInvestor[_propertyId][_investoruserId]) {
                uint256 investment = propertywiseInvestment[_investoruserId][_propertyId];
                uint256 dividendAmount =  (_rentAmount* investment)/_investmentPortion  ;
                uint256 recordedTime = currentTime - investmentTime[_investoruserId][_propertyId];
                uint256 _dividendAmount = (recordedTime * dividendAmount)/ epochTime;
                investmentTime[_investoruserId][_propertyId] = block.timestamp;
                address _investor = userDetails[_investoruserId].user;
                USDC.transferFrom(owner(), _investor, _dividendAmount);
                userDividend memory _userDividend;
                
                _userDividend.userId =  _investoruserId;
                _userDividend.amount = _dividendAmount;
                dividendAmountList[i] =_userDividend;

                emit DividendTransferred(_investoruserId, _propertyId, _dividendAmount);
            }
        }

        propertyDetails[_propertyId].propertyEpochTime = currentTime;
        return dividendAmountList;
    }


    function withdrawInvestment(string memory _investoruserId, string memory _propertyId, uint256 _amount) public {
        require(propertywiseInvestment[_investoruserId][_propertyId] >= _amount,"Insufficient investment amount");      
        require(msg.sender == userDetails[_investoruserId].user,"Caller is not the Investor");
        safeTransferFrom(userDetails[_investoruserId].user, owner(), propertyDetails[_propertyId].propertyTokenId,_amount,"");
        propertywiseInvestment[_investoruserId][_propertyId] -= _amount;
        propertyDetails[_propertyId].leftinvestmentPortion += _amount;

        emit propertySold(_investoruserId, _propertyId, _amount);
    }


}