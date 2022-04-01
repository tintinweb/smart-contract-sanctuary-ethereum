/**
 *Submitted for verification at Etherscan.io on 2022-04-01
*/

/**
 *Submitted for verification at Etherscan.io on 2022-03-22
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

library SafeMath {

    /**
    * @dev Multiplies two numbers, throws on overflow.
    */
    function mul(uint256 a, uint256 b) internal pure returns (uint256 c) {
        // Gas optimization: this is cheaper than asserting 'a' not being zero, but the
        // benefit is lost if 'b' is also tested.
        // See: https://github.com/OpenZeppelin/openzeppelin-solidity/pull/522
        if (a == 0) {
            return 0;
        }

        c = a * b;
        assert(c / a == b);
        return c;
    }

    /**
    * @dev Integer division of two numbers, truncating the quotient.
    */
    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        // assert(b > 0); // Solidity automatically throws when dividing by 0
        // uint256 c = a / b;
        // assert(a == b * c + a % b); // There is no case in which this doesn't hold
        return a / b;
    }

    /**
    * @dev Subtracts two numbers, throws on overflow (i.e. if subtrahend is greater than minuend).
    */
    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        assert(b <= a);
        return a - b;
    }

    /**
    * @dev Adds two numbers, throws on overflow.
    */
    function add(uint256 a, uint256 b) internal pure returns (uint256 c) {
        c = a + b;
        assert(c >= a);
        return c;
    }
} library Address {

    /**
     * Returns whether the target address is a contract
     * @dev This function will return false if invoked during the constructor of a contract,
     * as the code is not actually created until after the constructor finishes.
     * @param account address of the account to check
     * @return whether the target address is a contract
     */
    function isContract(address account) internal view returns (bool) {
        uint256 size;
        // XXX Currently there is no better way to check if there is a contract in an address
        // than to check the size of the code at that address.
        // See https://ethereum.stackexchange.com/a/14016/36603
        // for more details about how this works.
        // TODO Check this again before the Serenity release, because all addresses will be
        // contracts then.
        // solium-disable-next-line security/no-inline-assembly
        assembly { size := extcodesize(account) }
        return size > 0;
    }

} interface IERC165 {
    /**
     * @dev Returns true if this contract implements the interface defined by
     * `interfaceId`. See the corresponding
     * https://eips.ethereum.org/EIPS/eip-165#how-interfaces-are-identified[EIP section]
     * to learn more about how these ids are created.
     *
     * This function call must use less than 30 000 gas.
     */
    function supportsInterface(bytes4 interfaceId) external view returns (bool);
} abstract contract Context {
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }
    function _msgData() internal view virtual returns (bytes calldata) {
        return msg.data;
    }
} abstract contract ERC165 is IERC165 {
    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId) public view virtual override returns (bool) {
        return interfaceId == type(IERC165).interfaceId;
    }
} interface IERC1155 is IERC165 {
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
} interface IERC1155MetadataURI is IERC1155 {
    /**
     * @dev Returns the URI for token type `id`.
     *
     * If the `\{id\}` substring is present in the URI, it must be replaced by
     * clients with the actual token type ID.
     */
    function uri(uint256 id) external view returns (string memory);
} interface IERC1155Receiver is IERC165 {
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
} contract CommonConstants {
    bytes4 constant internal ERC1155_ACCEPTED = 0xf23a6e61; // bytes4(keccak256("onERC1155Received(address,address,uint256,uint256,bytes)"))
    bytes4 constant internal ERC1155_BATCH_ACCEPTED = 0xbc197c81; // bytes4(keccak256("onERC1155BatchReceived(address,address,uint256[],uint256[],bytes)"))
} contract ERC1155 is Context, ERC165, IERC1155, IERC1155MetadataURI {
    using Address for address;

    // Mapping from token ID to account balances
    mapping(uint256 => mapping(address => uint256)) private _balances;

    // Mapping from account to operator approvals
    mapping(address => mapping(address => bool)) private _operatorApprovals;

    // Used as the URI for all token types by relying on ID substitution, e.g. https://token-cdn-domain/{id}.json
    string private _uri;

    /**
     * @dev See {_setURI}.
     */
    constructor(string memory uri_) {
        _setURI(uri_);
    }

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
    ) public virtual override {
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
} abstract contract Ownable is Context {
    address private _owner;
    event OwnershipTransferred(
        address indexed previousOwner,
        address indexed newOwner
    );
    constructor() {
        _setOwner(_msgSender());
    }function owner() public view virtual returns (address) {
        return _owner;
    }
    modifier onlyOwner() {
        require(owner() == _msgSender(), "Ownable: caller is not the owner");
        _;
    }function renounceOwnership() public virtual onlyOwner {
        _setOwner(address(0));
    }
    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(
            newOwner != address(0),
            "Ownable: new owner is the zero address"
        );
        _setOwner(newOwner);
    }

    function _setOwner(address newOwner) private {
        address oldOwner = _owner;
        _owner = newOwner;
        emit OwnershipTransferred(oldOwner, newOwner);
    }
} library Counters {
    struct Counter {
        uint256 _value; // default: 0
    }
    function current(Counter storage counter) internal view returns (uint256) {
        return counter._value;
    }
    function increment(Counter storage counter) internal {
        unchecked {
        counter._value += 1;
        }
    }
    function decrement(Counter storage counter) internal {
        uint256 value = counter._value;
        require(value > 0, "Counter: decrement overflow");
    unchecked {
    counter._value = value - 1;
    }
    }
    function reset(Counter storage counter) internal {
        counter._value = 0;
    }
} interface PIZZANFT{
    struct Pizzas {
        address from;
        uint256 _pizzaId;
        uint256 base;
        uint256 sauce;
        uint256 cheese;
        uint256[] meats;
        uint256[] toppings;
        bool isRandom;
        bool unbaked;
        bool calculated;
        uint256 rarity;
    }
    struct PizzasResponse {
        uint256 _pizzaId;
        uint256 base;
        uint256 sauce;
        uint256 cheese;
        uint256[] meats;
        uint256[] toppings;
    }
    function bakePizzaAndMint(string memory metadata, uint256 base, uint256 sauce, uint256[] memory cheese, uint256[] memory meats, uint256[] memory toppings) external returns (PizzasResponse memory);
    function buyAndBakePizzaAndMint(string memory metadata, uint256 base, uint256 sauce, uint256[] memory cheese, uint256[] memory meats, uint256[] memory toppings) external returns (PizzasResponse memory);
    function randomBakePizzaAndMint(string memory metadata, uint256 base, uint256 sauce, uint256[] memory cheese, uint256[] memory meats, uint256[] memory toppings) external returns (PizzasResponse memory);
    function unbakePizza(uint256 _pizzaId) external;
    function rebakePizza(uint256 _pizzaId, string memory metadata, uint256 base, uint256 sauce, uint256[] memory cheese, uint256[] memory meats, uint256[] memory toppings) external;
    function getTotalPizzas() external returns(uint256);
} contract ingredientNFT is ERC1155, Ownable{

    mapping(address=>bool) whitlistedUsers;
    
    address pizzaNFTAddress;
    
    using Counters for Counters.Counter;
    using SafeMath for uint256;
    
    uint ARTIST_SHARE = 10;
    uint RARITY_REWARD_SHARE = 1;

    Counters.Counter private _IngredientIds;
    Counters.Counter private _nftIds;

    bool public randomBakePizzaAvailable = true;
    bool public buyAndBakePizzaAvailable = true;
    bool public unbakePizzaAvailable = true;
    bool public rebakePizzaAvailable  = true;

    uint256 public onlywhitlistedUsersStartTime;
    uint256 public onlywhitlistedUsersEndTime;

    uint256 totalIngredients;
    uint256 [] meatIngredients;
    uint256 [] toppingIngredients;
    uint256 totalClaimable = 0;
    address developerFundWallet;
    uint256 hundered = 100;
    uint256 totalRarityRewards = 0;

    event createIngredientEvent( uint256 indexed _ingredientId, string ingredientTokenURI, uint256 price, address artist, uint256 ingType);
    event transferIngredients( uint256[] balancesTransferred);

    event mintRandomPizza( uint256 indexed _nftId, PIZZANFT.PizzasResponse);  

    modifier pizzaTypeAvailableValidation(uint pizzaType) {
        if(pizzaType == 1) {
            require (randomBakePizzaAvailable, "1");
            _;
        }
        else if(pizzaType == 2) {
            require (buyAndBakePizzaAvailable, "2");
            _;
        }
        else if(pizzaType == 3) {
            require (unbakePizzaAvailable, "3");
            _;
        }
        else if(pizzaType == 4) {
            require (rebakePizzaAvailable, "4");
            _;
        }
    }

    // is whitelisted user
    modifier isWhitelisted() {
        if(block.timestamp < onlywhitlistedUsersEndTime){
            require(isUserWhitelisted(msg.sender), "Your are not Whitelisted, and only whitlisted can perform this tx for the specified period.");
            _;
        }else {
            _;
        }
    }

    struct Ingredients {
        string name;
        uint256 _ingredientId;
        string metadata;
        uint256 price;
        uint256 created;
        address artist;
        uint256 ingType;
        uint256 totalCount;
    }

    struct RarityReward {
        address wallet;
        bool claimed;
        uint256 rewardPrice;
        uint256 price;
        uint256 nftId;
        uint256 rarityScore;
        string imageUrl;
    }

    struct IngredientCountResponse {
        uint256 total;
        uint256 minted;
    }

    struct IngredientResponse {
        string name;
        uint256 rarity;
        uint256 usedIn;
    }

    mapping(uint256 => uint256) ingredientMintCount; // ingredientId => totalMinted
    mapping(uint256 => uint256) ingredientTotalCount; // ingredientId => totalAllowedCount
    mapping(uint256 => Ingredients) ingredientsList; // autoIncrementNumber => Ingredients
    mapping(uint256 => uint256) ingredientTypes; // ingredientId => type
    mapping(uint256 => uint256) ingredientUsedCount; // ingredientId => ingredientCountInPizza
    mapping(address => uint256[]) rarityRewardOwnerIds;
    mapping(uint256 => RarityReward) rarityRewardsList; 
    mapping(uint256 => uint256) ingredientRarityPercent; 
    mapping(uint256 => uint256) rarityRewardsIds;
    mapping(address => uint256) claimableList; // address => claimableAmount

    // constructor 
    constructor(address pizzaNFTAddr) ERC1155("Ingredient NFT") {
        pizzaNFTAddress = pizzaNFTAddr;
    }

    function getRarityRewardPizza(uint256 pizzaId) public view returns(RarityReward memory) {
        RarityReward memory rarityReward = rarityRewardsList[pizzaId];
        return rarityReward;
    }

    function getTotalRarityRewards() public view returns(uint256) {
        return totalRarityRewards;
    }

    function getRarityRewardId(uint256 index) public view returns(uint256) {
        return rarityRewardsIds[index];
    }

    // trait rarity
    function traitRarity() internal {
        
        // creating the pizzaNft objects to call its functions
        PIZZANFT pizzaNft = PIZZANFT(pizzaNFTAddress);

        uint256 totalPizzas = pizzaNft.getTotalPizzas();
        if(totalPizzas > 0) {
            for(uint256 i = 1; i <= totalIngredients; i++) {
                Ingredients memory ingredientDetail = ingredientsList[i];
                uint256 ingredientId = ingredientDetail._ingredientId;
                uint256 count = ingredientUsedCount[ingredientId];
                if(count > 0) {
                    ingredientRarityPercent[ingredientDetail._ingredientId] = (1 ether * ingredientUsedCount[ingredientId]).mul(100).div(totalPizzas);
                }
                else {
                    ingredientRarityPercent[ingredientDetail._ingredientId] = 0;
                }
            }
        }
        else {
            for(uint256 i = 1; i <= totalIngredients; i++) {
                Ingredients memory ingredientDetail = ingredientsList[i];
                uint256 ingredientId = ingredientDetail._ingredientId;
                ingredientRarityPercent[ingredientId] = 0;
            }
        }
    }

    // calculate Rarity 
    function sendRewardToRarestPizzaOwner( uint256 _pizzaId, uint256 rarityLowest, address pizzaCurrentOwner, string memory imageUrl) external payable {
        if(pizzaCurrentOwner != address(0)) {

            uint256 totalContractBalance = address(this).balance;
            uint256 availableContractBalance = totalContractBalance.sub(totalClaimable);
            uint256 rarityRewardShare = availableContractBalance.mul(RARITY_REWARD_SHARE).div(hundered);

            totalClaimable+=rarityRewardShare;
            RarityReward memory rarityReward = RarityReward(
                pizzaCurrentOwner,
                false,
                rarityRewardShare,
                rarityRewardShare,
                _pizzaId,
                rarityLowest,
                imageUrl
            );
            rarityRewardsList[totalRarityRewards] = rarityReward;
            rarityRewardsIds[totalRarityRewards] = _pizzaId;
            uint256[] storage userRareNfts = rarityRewardOwnerIds[pizzaCurrentOwner];
            userRareNfts.push(totalRarityRewards);
            rarityRewardOwnerIds[pizzaCurrentOwner] = userRareNfts;
            totalRarityRewards+=1;
            
            //for developer wallet
            uint256 currentClaimable = claimableList[developerFundWallet];
            currentClaimable += rarityRewardShare;
            claimableList[developerFundWallet] = currentClaimable;
            totalClaimable += currentClaimable;

            //for creator wallet
            currentClaimable = claimableList[owner()];
            currentClaimable += rarityRewardShare;
            claimableList[owner()] = currentClaimable;
            totalClaimable += currentClaimable;
        }
    }

    // update the developer fund wallet
    function updateDelevoperFundWallet(address wallet) public onlyOwner {
        developerFundWallet = wallet;
    }

    // check mints by ingredient id
    function checkMints(uint256 ingredientId) public view returns (IngredientCountResponse memory) {
        uint256 mintCount = ingredientMintCount[ingredientId];
        uint256 totalCount = ingredientTotalCount[ingredientId];
        IngredientCountResponse memory ingredientCount = IngredientCountResponse(
            totalCount,
            mintCount
        );
        return ingredientCount;
    }

    // get ingredients rarity
    function getIngredientRarity(uint256 ingredientId) public view returns (IngredientResponse memory) {
        uint256 rarity = ingredientRarityPercent[ingredientId];
        uint256 usedIn =  ingredientUsedCount[ingredientId];
        Ingredients memory ingredientDetails = ingredientsList[ingredientId];
        IngredientResponse memory ingredientResponse = IngredientResponse(
            ingredientDetails.name,
            rarity,
            usedIn
        );
        return (ingredientResponse);
    }

    // check claim reward
    function checkclaimableReward(address userAddress) public view returns(uint256) {
        uint256 claimableAmount = claimableList[userAddress];
        uint256 nftId = 0;
        uint256[] memory userRareNfts = rarityRewardOwnerIds[userAddress];
        for(uint256 x = 0; x < userRareNfts.length; x++) {
            nftId = userRareNfts[x];
            RarityReward memory rarityReward = rarityRewardsList[nftId];
            if(rarityReward.rewardPrice > 0 && !rarityReward.claimed) {
                claimableAmount+=rarityReward.rewardPrice;
            }
        }
        return claimableAmount;
    }

    // claim reward
    function claimReward() public payable {
        uint256 claimableAmount = claimableList[msg.sender];
        uint256 nftId = 0;
        uint256[] memory userRareNfts = rarityRewardOwnerIds[msg.sender];
        for(uint256 x = 0; x < userRareNfts.length; x++) {
            nftId = userRareNfts[x];
            RarityReward memory rarityReward = rarityRewardsList[nftId];
            if(rarityReward.rewardPrice > 0 && !rarityReward.claimed) {
                claimableAmount+=rarityReward.rewardPrice;
            }
        }
        require( claimableAmount > 0, "4");
        payable(msg.sender).transfer(claimableAmount);
        for(uint256 x = 0; x < userRareNfts.length; x++) {
            nftId = userRareNfts[x];
            RarityReward memory rarityReward = rarityRewardsList[nftId];
            rarityReward.rewardPrice = 0;
            rarityReward.claimed = true;
            rarityRewardsList[nftId] = rarityReward;
        }
        claimableList[msg.sender] = 0;
        totalClaimable -= claimableAmount;
    }

    // fn to transfer ingredient
    function _ingredientTransfer(uint256 base, uint256 sauce, uint256[] memory cheese, uint256[] memory meats, uint256[] memory toppings) internal {
        if(base > 0) {
            transerIngredient(base);
            increaseUsedCountByIngredientId(base);
        }
        if(sauce > 0) {
            transerIngredient(sauce);
            increaseUsedCountByIngredientId(sauce);
        }

        for(uint256 x = 0; x < cheese.length; x++) {
            if(cheese[x] > 0) {
                transerIngredient(cheese[x]);
                increaseUsedCountByIngredientId(cheese[x]);
            }
        }

        for(uint256 x = 0; x < meats.length; x++) {
            if(meats[x] > 0) {
                transerIngredient(meats[x]);
                increaseUsedCountByIngredientId(meats[x]);
            }
        }
        for(uint256 x = 0; x < toppings.length; x++) {
            if(toppings[x] > 0) {
                transerIngredient(toppings[x]);
                increaseUsedCountByIngredientId(toppings[x]);
            }
        }
    }

    // 1- create Ingredient (Admin)
    function createIngredient( string memory ingredientTokenURI, uint256 price, address artist, uint256 ingType, uint256 totalCount, string memory name) public {
        _IngredientIds.increment();
        uint256 _ingredientId = _IngredientIds.current();
        Ingredients memory ingredientDetail = Ingredients(
            name,
            _ingredientId,
            ingredientTokenURI,
            price,
            1,
            artist,
            ingType,
            totalCount
        );
        ingredientTotalCount[_ingredientId] = totalCount;
        ingredientsList[_ingredientId] = ingredientDetail;
        ingredientTypes[_ingredientId] = ingType; 
        totalIngredients+=1;  
        if(ingType == 4) { 
            meatIngredients.push(_ingredientId); 
        } 
        if(ingType == 5) { 
            toppingIngredients.push(_ingredientId);
        }
        _mint(owner(), _ingredientId, totalCount, "https://res.cloudinary.com/arhamsoftorg/image/upload/v1647174736/jdlvwplb5fu3dtr1d28q.png");
        emit createIngredientEvent(_ingredientId, ingredientTokenURI, price, artist, ingType);
    }

    // 2- user purchaseIngredients   
    function purchaseIngredients( uint256[] memory _ingredientIds) public payable isWhitelisted { 
        Ingredients memory ingredientDetail;
        uint256 totalPrice = 0;
        uint[] memory ingredientsBalanceTransfer = new uint[](_ingredientIds.length);
        for(uint256 i = 0; i < _ingredientIds.length; i++) {
            ingredientDetail = ingredientsList[_ingredientIds[i]];
            require(ingredientDetail.created > 0, "one of the provided ingredient is not created yet!");
            ingredientsBalanceTransfer[i] = 1;
            totalPrice+=ingredientDetail.price;
        }
        require(msg.value >= totalPrice, "Not Provided enough Ethers!`");

        for(uint256 i = 0; i < _ingredientIds.length; i++) {
            ingredientDetail = ingredientsList[_ingredientIds[i]];
            address payable artist = payable(ingredientDetail.artist);
            uint256 currentMintCount = ingredientMintCount[_ingredientIds[i]]; 
            uint256 totalCount = ingredientTotalCount[_ingredientIds[i]];

            require(currentMintCount < totalCount, "one of the provided ingredient is not having enough balance to transfer!");

            // tranfering the token to the purchaser
            _safeBatchTransferFrom(owner(), msg.sender, _ingredientIds, ingredientsBalanceTransfer, "0x00");

            if(artist != address(0)) {
                uint256 currentClaimable = claimableList[ingredientDetail.artist];
                uint256 artistShare = ingredientDetail.price.mul(ARTIST_SHARE).div(hundered);
                currentClaimable += artistShare;
                claimableList[ingredientDetail.artist] = currentClaimable;
                totalClaimable += artistShare;
            }
            
            ingredientMintCount[_ingredientIds[i]] = currentMintCount + 1;
        }
        
        emit transferIngredients(ingredientsBalanceTransfer);
    }
    
    // 3- buy and bake pizza and mint
    function buyAndBakePizzaAndMint(string memory metadata, uint256 base, uint256 sauce, uint256[] memory cheese, uint256[] memory meats, uint256[] memory toppings ) public payable pizzaTypeAvailableValidation(2) isWhitelisted {
        
        require(pizzaValidation(base, sauce, cheese), "Pizza Validation Failed.");

        // creating the pizzaNft objects to call its functions
        PIZZANFT pizzaNft = PIZZANFT(pizzaNFTAddress);

        _ingredientTransfer(base, sauce, cheese, meats, toppings);
        
        PIZZANFT.PizzasResponse memory pizzasResponse = pizzaNft.buyAndBakePizzaAndMint(metadata, base, sauce, cheese, meats, toppings);
        traitRarity();
        emit mintRandomPizza(pizzasResponse._pizzaId, pizzasResponse);

    }

    // 4- random bake pizza and mint
    function randomBakePizzaAndMint(string memory metadata, uint256 base, uint256 sauce, uint256[] memory cheese, uint256[] memory meats, uint256[] memory toppings ) public payable pizzaTypeAvailableValidation(1) isWhitelisted {
        
        require(pizzaValidation(base, sauce, cheese), "Pizza Validation Failed.");

        // creating the pizzaNft objects to call its functions
        PIZZANFT pizzaNft = PIZZANFT(pizzaNFTAddress);

        _ingredientTransfer(base, sauce, cheese, meats, toppings);
        
        PIZZANFT.PizzasResponse memory pizzasResponse = pizzaNft.randomBakePizzaAndMint(metadata, base, sauce, cheese, meats, toppings);
        traitRarity();
        emit mintRandomPizza(pizzasResponse._pizzaId, pizzasResponse);
    }

    // 5- unbake pizza 
    function unbakePizza( uint256 _pizzaId, uint256[] memory ingredientIds) public payable pizzaTypeAvailableValidation(3) isWhitelisted {
        
        // creating the pizzaNft objects to call its functions
        PIZZANFT pizzaNft = PIZZANFT(pizzaNFTAddress);

        for(uint8 i=0; i<ingredientIds.length; i++) {
            decreaseUsedCountByIngredientId(ingredientIds[i]);
        }

        // calling unbake Pizza Nft function
        pizzaNft.unbakePizza(_pizzaId);
        traitRarity();
    }

    function _increasedIngredientCount(uint256 base, uint256 sauce, uint256[] memory cheese, uint256[] memory meats, uint256[] memory toppings) internal {
        if(base > 0) {
            increaseUsedCountByIngredientId(base);
        }
        if(sauce > 0) {
            increaseUsedCountByIngredientId(sauce);
        }

        for(uint256 x = 0; x < cheese.length; x++) {
            if(cheese[x] > 0) {
                increaseUsedCountByIngredientId(cheese[x]);
            }
        }
        
        for(uint256 x = 0; x < meats.length; x++) {
            if(meats[x] > 0) {
                increaseUsedCountByIngredientId(meats[x]);
            }
        }
        for(uint256 x = 0; x < toppings.length; x++) {
            if(toppings[x] > 0) {
                increaseUsedCountByIngredientId(toppings[x]);
            }
        }
    } 

    // 6- rebake pizza
    function rebakePizza( uint256 _pizzaId, string memory metadata, uint256 base, uint256 sauce, uint256[] memory cheese, uint256[] memory meats, uint256[] memory toppings, uint256[] memory allOldIngs, uint256[] memory oldIngs ) public payable pizzaTypeAvailableValidation(4) isWhitelisted {
        
        require(pizzaValidation(base, sauce, cheese), "Pizza Validation Failed.");

        // creating the pizzaNft objects to call its functions
        PIZZANFT pizzaNft = PIZZANFT(pizzaNFTAddress);

        for(uint256 a = 0; a < allOldIngs.length; a++) {
            decreaseUsedCountByIngredientId(allOldIngs[a]);
        }
        for(uint256 a = 0; a < oldIngs.length; a++) {
            burnIngredient(oldIngs[a]);
        }

        _increasedIngredientCount(base, sauce, cheese, meats, toppings);
        
        // calling the rebake pizza function of pizza nft contract
        pizzaNft.rebakePizza(_pizzaId, metadata, base, sauce, cheese, meats, toppings);
        traitRarity();
    }

    // 7- buy and bake pizza and mint
    function bakePizzaAndMint(string memory metadata, uint256 base, uint256 sauce, uint256[] memory cheese, uint256[] memory meats, uint256[] memory toppings ) public payable pizzaTypeAvailableValidation(2) isWhitelisted { 
        
        require(pizzaValidation(base, sauce, cheese), "Pizza Validation Failed.");

        // creating the pizzaNft objects to call its functions
        PIZZANFT pizzaNft = PIZZANFT(pizzaNFTAddress);

        _increasedIngredientCount(base, sauce, cheese, meats, toppings);
        PIZZANFT.PizzasResponse memory pizzasResponse = pizzaNft.bakePizzaAndMint(metadata, base, sauce, cheese, meats, toppings);
        traitRarity();
        emit mintRandomPizza(pizzasResponse._pizzaId, pizzasResponse);

    }

    // change the status of pizza functions availabaility
    function changePizzaAvailable(uint256 pizzaType, bool status) public onlyOwner {
        if(pizzaType == 1) {
            randomBakePizzaAvailable = status;
        }
        else if(pizzaType == 2) {
            buyAndBakePizzaAvailable = status;
        }
        else if(pizzaType == 3) {
            unbakePizzaAvailable = status;
        }
        else if(pizzaType == 4) {
            rebakePizzaAvailable = status;
        }
    }

    /** internal functions */ 
    // pizza validation

    function pizzaValidation(uint256 base, uint256 sauce, uint256[] memory cheese) internal pure returns(bool) {
        bool validation = true;
        if(base == 0){
            validation = false;
        }
        if(sauce == 0){
            validation = false;
        }

        for (uint256 x = 0; x < cheese.length; x++) {
            if(cheese[x] == 0){
                validation = false;
            }
        }
        return validation;
    }

    // createUserIngredient
    function transerIngredient(uint256 _ingredientId) internal returns(bool) {
        Ingredients memory ingredientDetail = ingredientsList[_ingredientId];
        address payable artist = payable(ingredientDetail.artist);
        uint256 currentMintCount = ingredientMintCount[_ingredientId];
        uint256 totalCount = ingredientTotalCount[_ingredientId];

        require(currentMintCount < totalCount, "one of the provided ingredient is not having enough balance to transfer!");
            
        // tranfering the token to the purchaser
         _safeTransferFrom(owner(), msg.sender, _ingredientId, 1, "0x00");

        // _setTokenURI(_nftId, ingredientDetail.metadata);
        if(artist != address(0)) {
            uint256 currentClaimable = claimableList[ingredientDetail.artist];
            uint256 artistShare = ingredientDetail.price.mul(ARTIST_SHARE).div(hundered);
            currentClaimable += artistShare;
            claimableList[ingredientDetail.artist] = currentClaimable;
            totalClaimable += artistShare;
        }

        ingredientMintCount[_ingredientId] = currentMintCount + 1;
        return true;
    }

    function increaseUsedCountByIngredientId(uint256 ingredientId) internal {   
        uint256 ingCountUsed = ingredientUsedCount[ingredientId]+1;
        ingredientUsedCount[ingredientId] = ingCountUsed;
    }

    function decreaseUsedCountByIngredientId(uint256 ingredientId) internal {
        if(ingredientUsedCount[ingredientId] > 0) {
            uint256 ingCountUsed = ingredientUsedCount[ingredientId]-1;
            ingredientUsedCount[ingredientId] = ingCountUsed;
        }
    }

    function burnIngredient(uint256 ingredientId) internal {
        uint256 currentMintCount = ingredientMintCount[ingredientId];
        ingredientMintCount[ingredientId] = currentMintCount - 1;
    }

    // function to check whitelist address
    function isUserWhitelisted(address userAddress) public view returns (bool success) {
        return whitlistedUsers[userAddress];
    }

    // function to add whitelisted address 
    function whitelistUsers( address[] memory userAddress ) public onlyOwner {
        for(uint8 x = 0; x < userAddress.length; x++) {
            whitlistedUsers[userAddress[x]] = true;
        }
    }

    // funtion to remove whitelisted address 
    function removeWhitelistedUsers( address[] memory userAddress ) public onlyOwner {
        for(uint8 x = 0; x < userAddress.length; x++) {
            whitlistedUsers[userAddress[x]] = false;
        }
    }

    // set time for the whitlisted user
    function onlywhitlistedUsersPeriod(uint256 startTime, uint256 endTime) public onlyOwner {
        onlywhitlistedUsersStartTime = startTime;
        onlywhitlistedUsersEndTime = endTime;
    }

    // reward to be won
    function rewardToBeWon() public view returns (uint256 amt){
        uint256 totalContractBalance = address(this).balance;
        return totalContractBalance.sub(totalClaimable);
    }

    // new deploy for final
}