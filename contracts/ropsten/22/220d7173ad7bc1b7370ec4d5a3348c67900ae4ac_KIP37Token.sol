/**
 *Submitted for verification at Etherscan.io on 2022-04-21
*/

// File: contracts/introspection/IKIP13.sol

pragma solidity ^0.5.0;

/**
 * @dev Interface of the KIP-13 standard, as defined in the
 * [KIP-13](http://kips.klaytn.com/KIPs/kip-13-interface_query_standard).
 *
 * Implementers can declare support of contract interfaces, which can then be
 * queried by others.
 *
 * For an implementation, see `KIP13`.
 */
interface IKIP13 {
    /**
     * @dev Returns true if this contract implements the interface defined by
     * `interfaceId`. See the corresponding
     * [KIP-13 section](http://kips.klaytn.com/KIPs/kip-13-interface_query_standard#how-interface-identifiers-are-defined)
     * to learn more about how these ids are created.
     *
     * This function call must use less than 30 000 gas.
     */
    function supportsInterface(bytes4 interfaceId) external view returns (bool);
}

// File: contracts/token/KIP37/IKIP37.sol

// SPDX-License-Identifier: MIT

pragma solidity ^0.5.2;


/**
 * @dev Required interface of an KIP37 compliant contract, as defined in the
 * https://kips.klaytn.com/KIPs/kip-37
 */
contract IKIP37 is IKIP13 {
    /**
     * @dev Emitted when `value` tokens of token type `id` are transfered from `from` to `to` by `operator`.
     */
    event TransferSingle(
        address indexed operator,
        address indexed from,
        address indexed to,
        uint256 id,
        uint256 value
    );

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
    event ApprovalForAll(
        address indexed account,
        address indexed operator,
        bool approved
    );

    /**
     * @dev Emitted when the URI for token type `id` changes to `value`, if it is a non-programmatic URI.
     */
    event URI(string value, uint256 indexed id);

    /**
     * @dev Returns the amount of tokens of token type `id` owned by `account`.
     *
     * Requirements:
     *
     * - `account` cannot be the zero address.
     */
    function balanceOf(address account, uint256 id)
        external
        view
        returns (uint256);

    /**
     * @dev Batch-operations version of {balanceOf}.
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
    function isApprovedForAll(address account, address operator)
        external
        view
        returns (bool);

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
     * - If `to` refers to a smart contract, it must implement {IKIP37Receiver-onKIP37Received} and return the
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
     * @dev Batch-operations version of {safeTransferFrom}.
     *
     * Emits a {TransferBatch} event.
     *
     * Requirements:
     *
     * - `ids` and `amounts` must have the same length.
     * - If `to` refers to a smart contract, it must implement {IKIP37Receiver-onKIP37BatchReceived} and return the
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

// File: contracts/token/KIP37/IKIP37MetadataURI.sol

// SPDX-License-Identifier: MIT

pragma solidity ^0.5.0;


/**
 * @dev Interface of the optional KIP37MetadataExtension interface
 */
contract IKIP37MetadataURI is IKIP37 {
    /**
     * @dev Returns the URI for token type `id`.
     *
     * If the `\{id\}` substring is present in the URI, it must be replaced by
     * clients with the actual token type ID.
     */
    function uri(uint256 id) external view returns (string memory);
}

// File: contracts/token/KIP37/IKIP37Receiver.sol

// SPDX-License-Identifier: MIT

pragma solidity ^0.5.0;


contract IKIP37Receiver is IKIP13 {
    /**
        @dev Handles the receipt of a single KIP37 token type. This function is
        called at the end of a `safeTransferFrom` after the balance has been updated.
        To accept the transfer, this must return
        `bytes4(keccak256("onKIP37Received(address,address,uint256,uint256,bytes)"))`
        (i.e. 0xe78b3325, or its own function selector).
        @param operator The address which initiated the transfer (i.e. msg.sender)
        @param from The address which previously owned the token
        @param id The ID of the token being transferred
        @param value The amount of tokens being transferred
        @param data Additional data with no specified format
        @return `bytes4(keccak256("onKIP37Received(address,address,uint256,uint256,bytes)"))` if transfer is allowed
    */
    function onKIP37Received(
        address operator,
        address from,
        uint256 id,
        uint256 value,
        bytes calldata data
    ) external returns (bytes4);

    /**
        @dev Handles the receipt of a multiple KIP37 token types. This function
        is called at the end of a `safeBatchTransferFrom` after the balances have
        been updated. To accept the transfer(s), this must return
        `bytes4(keccak256("onKIP37BatchReceived(address,address,uint256[],uint256[],bytes)"))`
        (i.e. 0x9b49e332, or its own function selector).
        @param operator The address which initiated the batch transfer (i.e. msg.sender)
        @param from The address which previously owned the token
        @param ids An array containing ids of each token being transferred (order and length must match values array)
        @param values An array containing amounts of each token being transferred (order and length must match ids array)
        @param data Additional data with no specified format
        @return `bytes4(keccak256("onKIP37BatchReceived(address,address,uint256[],uint256[],bytes)"))` if transfer is allowed
    */
    function onKIP37BatchReceived(
        address operator,
        address from,
        uint256[] calldata ids,
        uint256[] calldata values,
        bytes calldata data
    ) external returns (bytes4);
}

// File: contracts/token/KIP37/IERC1155Receiver.sol

// SPDX-License-Identifier: MIT

pragma solidity ^0.5.0;


contract IERC1155Receiver is IKIP13 {
    /**
        @dev Handles the receipt of a single ERC1155 token type. This function is
        called at the end of a `safeTransferFrom` after the balance has been updated.
        To accept the transfer, this must return
        `bytes4(keccak256("onERC1155Received(address,address,uint256,uint256,bytes)"))`
        (i.e. 0xf23a6e61, or its own function selector).
        @param operator The address which initiated the transfer (i.e. msg.sender)
        @param from The address which previously owned the token
        @param id The ID of the token being transferred
        @param value The amount of tokens being transferred
        @param data Additional data with no specified format
        @return `bytes4(keccak256("onERC1155Received(address,address,uint256,uint256,bytes)"))` if transfer is allowed
    */
    function onERC1155Received(
        address operator,
        address from,
        uint256 id,
        uint256 value,
        bytes calldata data
    ) external returns (bytes4);

    /**
        @dev Handles the receipt of a multiple ERC1155 token types. This function
        is called at the end of a `safeBatchTransferFrom` after the balances have
        been updated. To accept the transfer(s), this must return
        `bytes4(keccak256("onERC1155BatchReceived(address,address,uint256[],uint256[],bytes)"))`
        (i.e. 0xbc197c81, or its own function selector).
        @param operator The address which initiated the batch transfer (i.e. msg.sender)
        @param from The address which previously owned the token
        @param ids An array containing ids of each token being transferred (order and length must match values array)
        @param values An array containing amounts of each token being transferred (order and length must match ids array)
        @param data Additional data with no specified format
        @return `bytes4(keccak256("onERC1155BatchReceived(address,address,uint256[],uint256[],bytes)"))` if transfer is allowed
    */
    function onERC1155BatchReceived(
        address operator,
        address from,
        uint256[] calldata ids,
        uint256[] calldata values,
        bytes calldata data
    ) external returns (bytes4);
}

// File: contracts/GSN/Context.sol

pragma solidity ^0.5.0;

/*
 * @dev Provides information about the current execution context, including the
 * sender of the transaction and its data. While these are generally available
 * via msg.sender and msg.data, they should not be accessed in such a direct
 * manner, since when dealing with GSN meta-transactions the account sending and
 * paying for execution may not be the actual sender (as far as an application
 * is concerned).
 *
 * This contract is only required for intermediate, library-like contracts.
 */
contract Context {
    // Empty internal constructor, to prevent people from mistakenly deploying
    // an instance of this contract, which should be used via inheritance.
    constructor () internal { }
    // solhint-disable-previous-line no-empty-blocks

    function _msgSender() internal view returns (address payable) {
        return msg.sender;
    }

    function _msgData() internal view returns (bytes memory) {
        this; // silence state mutability warning without generating bytecode - see https://github.com/ethereum/solidity/issues/2691
        return msg.data;
    }
}

// File: contracts/introspection/KIP13.sol

pragma solidity ^0.5.0;


/**
 * @dev Implementation of the `IKIP13` interface.
 *
 * Contracts may inherit from this and call `_registerInterface` to declare
 * their support of an interface.
 */
contract KIP13 is IKIP13 {
    /*
     * bytes4(keccak256('supportsInterface(bytes4)')) == 0x01ffc9a7
     */
    bytes4 private constant _INTERFACE_ID_KIP13 = 0x01ffc9a7;

    /**
     * @dev Mapping of interface ids to whether or not it's supported.
     */
    mapping(bytes4 => bool) private _supportedInterfaces;

    constructor () internal {
        // Derived contracts need only register support for their own interfaces,
        // we register support for KIP13 itself here
        _registerInterface(_INTERFACE_ID_KIP13);
    }

    /**
     * @dev See `IKIP13.supportsInterface`.
     *
     * Time complexity O(1), guaranteed to always use less than 30 000 gas.
     */
    function supportsInterface(bytes4 interfaceId) external view returns (bool) {
        return _supportedInterfaces[interfaceId];
    }

    /**
     * @dev Registers the contract as an implementer of the interface defined by
     * `interfaceId`. Support of the actual KIP13 interface is automatic and
     * registering its interface id is not required.
     *
     * See `IKIP13.supportsInterface`.
     *
     * Requirements:
     *
     * - `interfaceId` cannot be the KIP13 invalid interface (`0xffffffff`).
     */
    function _registerInterface(bytes4 interfaceId) internal {
        require(interfaceId != 0xffffffff, "KIP13: invalid interface id");
        _supportedInterfaces[interfaceId] = true;
    }
}

// File: contracts/math/SafeMath.sol

pragma solidity ^0.5.0;

/**
 * @dev Wrappers over Solidity's arithmetic operations with added overflow
 * checks.
 *
 * Arithmetic operations in Solidity wrap on overflow. This can easily result
 * in bugs, because programmers usually assume that an overflow raises an
 * error, which is the standard behavior in high level programming languages.
 * `SafeMath` restores this intuition by reverting the transaction when an
 * operation overflows.
 *
 * Using this library instead of the unchecked operations eliminates an entire
 * class of bugs, so it's recommended to use it always.
 */
library SafeMath {
    /**
     * @dev Returns the addition of two unsigned integers, reverting on
     * overflow.
     *
     * Counterpart to Solidity's `+` operator.
     *
     * Requirements:
     * - Addition cannot overflow.
     */
    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;
        require(c >= a, "SafeMath: addition overflow");

        return c;
    }

    /**
     * @dev Returns the subtraction of two unsigned integers, reverting on
     * overflow (when the result is negative).
     *
     * Counterpart to Solidity's `-` operator.
     *
     * Requirements:
     * - Subtraction cannot overflow.
     */
    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        return sub(a, b, "SafeMath: subtraction overflow");
    }

    /**
     * @dev Returns the subtraction of two unsigned integers, reverting with custom message on
     * overflow (when the result is negative).
     *
     * Counterpart to Solidity's `-` operator.
     *
     * Requirements:
     * - Subtraction cannot overflow.
     *
     * _Available since v2.4.0._
     */
    function sub(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b <= a, errorMessage);
        uint256 c = a - b;

        return c;
    }

    /**
     * @dev Returns the multiplication of two unsigned integers, reverting on
     * overflow.
     *
     * Counterpart to Solidity's `*` operator.
     *
     * Requirements:
     * - Multiplication cannot overflow.
     */
    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        // Gas optimization: this is cheaper than requiring 'a' not being zero, but the
        // benefit is lost if 'b' is also tested.
        // See: https://github.com/OpenZeppelin/openzeppelin-contracts/pull/522
        if (a == 0) {
            return 0;
        }

        uint256 c = a * b;
        require(c / a == b, "SafeMath: multiplication overflow");

        return c;
    }

    /**
     * @dev Returns the integer division of two unsigned integers. Reverts on
     * division by zero. The result is rounded towards zero.
     *
     * Counterpart to Solidity's `/` operator. Note: this function uses a
     * `revert` opcode (which leaves remaining gas untouched) while Solidity
     * uses an invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     * - The divisor cannot be zero.
     */
    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        return div(a, b, "SafeMath: division by zero");
    }

    /**
     * @dev Returns the integer division of two unsigned integers. Reverts with custom message on
     * division by zero. The result is rounded towards zero.
     *
     * Counterpart to Solidity's `/` operator. Note: this function uses a
     * `revert` opcode (which leaves remaining gas untouched) while Solidity
     * uses an invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     * - The divisor cannot be zero.
     *
     * _Available since v2.4.0._
     */
    function div(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        // Solidity only automatically asserts when dividing by 0
        require(b > 0, errorMessage);
        uint256 c = a / b;
        // assert(a == b * c + a % b); // There is no case in which this doesn't hold

        return c;
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers. (unsigned integer modulo),
     * Reverts when dividing by zero.
     *
     * Counterpart to Solidity's `%` operator. This function uses a `revert`
     * opcode (which leaves remaining gas untouched) while Solidity uses an
     * invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     * - The divisor cannot be zero.
     */
    function mod(uint256 a, uint256 b) internal pure returns (uint256) {
        return mod(a, b, "SafeMath: modulo by zero");
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers. (unsigned integer modulo),
     * Reverts with custom message when dividing by zero.
     *
     * Counterpart to Solidity's `%` operator. This function uses a `revert`
     * opcode (which leaves remaining gas untouched) while Solidity uses an
     * invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     * - The divisor cannot be zero.
     *
     * _Available since v2.4.0._
     */
    function mod(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b != 0, errorMessage);
        return a % b;
    }
}

// File: contracts/utils/Address.sol

pragma solidity ^0.5.0;

/**
 * @dev Collection of functions related to the address type,
 */
library Address {
    /**
     * @dev Returns true if `account` is a contract.
     *
     * This test is non-exhaustive, and there may be false-negatives: during the
     * execution of a contract's constructor, its address will be reported as
     * not containing a contract.
     *
     * > It is unsafe to assume that an address for which this function returns
     * false is an externally-owned account (EOA) and not a contract.
     */
    function isContract(address account) internal view returns (bool) {
        // This method relies in extcodesize, which returns 0 for contracts in
        // construction, since the code is only stored at the end of the
        // constructor execution.

        uint256 size;
        // solhint-disable-next-line no-inline-assembly
        assembly { size := extcodesize(account) }
        return size > 0;
    }
}

// File: contracts/token/KIP37/KIP37.sol

// SPDX-License-Identifier: MIT

pragma solidity ^0.5.0;









/**
 *
 * @dev Implementation of the basic standard multi-token.
 * Originally based on code by Enjin: https://github.com/enjin/erc-1155
 */
contract KIP37 is Context, KIP13, IKIP37, IKIP37MetadataURI {
    using SafeMath for uint256;
    using Address for address;

    // Mapping from token ID to account balances
    mapping(uint256 => mapping(address => uint256)) private _balances;

    // Mapping from account to operator approvals
    mapping(address => mapping(address => bool)) private _operatorApprovals;

    // Mapping from token ID to the total supply of the token
    mapping(uint256 => uint256) private _totalSupply;

    // Used as the URI for all token types by relying on ID substition, e.g. https://token-cdn-domain/{id}.json
    string internal _uri;

    /*
     *     bytes4(keccak256('balanceOf(address,uint256)')) == 0x00fdd58e
     *     bytes4(keccak256('balanceOfBatch(address[],uint256[])')) == 0x4e1273f4
     *     bytes4(keccak256('setApprovalForAll(address,bool)')) == 0xa22cb465
     *     bytes4(keccak256('isApprovedForAll(address,address)')) == 0xe985e9c5
     *     bytes4(keccak256('safeTransferFrom(address,address,uint256,uint256,bytes)')) == 0xf242432a
     *     bytes4(keccak256('safeBatchTransferFrom(address,address,uint256[],uint256[],bytes)')) == 0x2eb2c2d6
     *     bytes4(keccak256('totalSupply(uint256)')) == 0xbd85b039
     *
     *     => 0x00fdd58e ^ 0x4e1273f4 ^ 0xa22cb465 ^
     *        0xe985e9c5 ^ 0xf242432a ^ 0x2eb2c2d6 ^ 0xbd85b039 == 0x6433ca1f
     */
    bytes4 private constant _INTERFACE_ID_KIP37 = 0x6433ca1f;

    /*
     *     bytes4(keccak256('uri(uint256)')) == 0x0e89341c
     */
    bytes4 private constant _INTERFACE_ID_KIP37_METADATA_URI = 0x0e89341c;

    bytes4 private constant _INTERFACE_ID_KIP37_TOKEN_RECEIVER = 0x7cc2d017;

    bytes4 private constant _INTERFACE_ID_ERC1155_TOKEN_RECEIVER = 0x4e2312e0;

    // Equals to `bytes4(keccak256("onKIP37Received(address,address,uint256,uint256,bytes)"))`
    // which can be also obtained as `IKIP37Receiver(0).onKIP37Received.selector`
    bytes4 private constant _KIP37_RECEIVED = 0xe78b3325;

    // Equals to `bytes4(keccak256("onERC1155Received(address,address,uint256,uint256,bytes)"))`
    // which can be also obtained as `IERC1155Receiver(0).onERC1155Received.selector`
    bytes4 private constant _ERC1155_RECEIVED = 0xf23a6e61;

    // Equals to `bytes4(keccak256("onKIP37BatchReceived(address,address,uint256[],uint256[],bytes)"))`
    // which can be also obtained as `IKIP37Receiver(0).onKIP37BatchReceived.selector`
    bytes4 private constant _KIP37_BATCH_RECEIVED = 0x9b49e332;

    // Equals to `bytes4(keccak256("onERC1155BatchReceived(address,address,uint256[],uint256[],bytes)"))`
    // which can be also obtained as `IERC1155Receiver(0).onERC1155BatchReceived.selector`
    bytes4 private constant _ERC1155_BATCH_RECEIVED = 0xbc197c81;

    /**
     * @dev See {_setURI}.
     */
    constructor(string memory uri) public {
        _setURI(uri);

        // register the supported interfaces to conform to KIP37 via KIP13
        _registerInterface(_INTERFACE_ID_KIP37);

        // register the supported interfaces to conform to KIP37MetadataURI via KIP13
        _registerInterface(_INTERFACE_ID_KIP37_METADATA_URI);
    }

    /**
     * @dev See {IKIP37MetadataURI-uri}.
     *
     * This implementation returns the same URI for *all* token types. It relies
     * on the token type ID substituion mechanism
     * http://kips.klaytn.com/KIPs/kip-37#metadata
     *
     * Clients calling this function must replace the `\{id\}` substring with the
     * actual token type ID.
     */
    function uri(uint256) external view returns (string memory) {
        return _uri;
    }

    /**
     * @dev See {IKIP37-balanceOf}.
     *
     * Requirements:
     *
     * - `account` cannot be the zero address.
     */
    function balanceOf(address account, uint256 id)
        public
        view
        returns (uint256)
    {
        require(
            account != address(0),
            "KIP37: balance query for the zero address"
        );
        return _balances[id][account];
    }

    /**
     * @dev See {IKIP37-balanceOfBatch}.
     *
     * Requirements:
     *
     * - `accounts` and `ids` must have the same length.
     */
    function balanceOfBatch(address[] memory accounts, uint256[] memory ids)
        public
        view
        returns (uint256[] memory)
    {
        require(
            accounts.length == ids.length,
            "KIP37: accounts and ids length mismatch"
        );

        uint256[] memory batchBalances = new uint256[](accounts.length);

        for (uint256 i = 0; i < accounts.length; ++i) {
            require(
                accounts[i] != address(0),
                "KIP37: batch balance query for the zero address"
            );
            batchBalances[i] = _balances[ids[i]][accounts[i]];
        }

        return batchBalances;
    }

    /**
     * @dev See {IKIP37-setApprovalForAll}.
     */
    function setApprovalForAll(address operator, bool approved) public {
        require(
            _msgSender() != operator,
            "KIP37: setting approval status for self"
        );

        _operatorApprovals[_msgSender()][operator] = approved;
        emit ApprovalForAll(_msgSender(), operator, approved);
    }

    /**
     * @dev See {IKIP37-isApprovedForAll}.
     */
    function isApprovedForAll(address account, address operator)
        public
        view
        returns (bool)
    {
        return _operatorApprovals[account][operator];
    }

    function totalSupply(uint256 _tokenId) public view returns (uint256) {
        return _totalSupply[_tokenId];
    }

    /**
     * @dev See {IKIP37-safeTransferFrom}.
     */
    function safeTransferFrom(
        address from,
        address to,
        uint256 id,
        uint256 amount,
        bytes memory data
    ) public {
        require(to != address(0), "KIP37: transfer to the zero address");
        require(
            from == _msgSender() || isApprovedForAll(from, _msgSender()),
            "KIP37: caller is not owner nor approved"
        );

        address operator = _msgSender();

        _beforeTokenTransfer(
            operator,
            from,
            to,
            _asSingletonArray(id),
            _asSingletonArray(amount),
            data
        );

        _balances[id][from] = _balances[id][from].sub(
            amount,
            "KIP37: insufficient balance for transfer"
        );
        _balances[id][to] = _balances[id][to].add(amount);

        emit TransferSingle(operator, from, to, id, amount);

        require(
            _doSafeTransferAcceptanceCheck(
                operator,
                from,
                to,
                id,
                amount,
                data
            ),
            "KIP37: transfer to non KIP37Receiver implementer"
        );
    }

    /**
     * @dev See {IKIP37-safeBatchTransferFrom}.
     */
    function safeBatchTransferFrom(
        address from,
        address to,
        uint256[] memory ids,
        uint256[] memory amounts,
        bytes memory data
    ) public {
        require(
            ids.length == amounts.length,
            "KIP37: ids and amounts length mismatch"
        );
        require(to != address(0), "KIP37: transfer to the zero address");
        require(
            from == _msgSender() || isApprovedForAll(from, _msgSender()),
            "KIP37: transfer caller is not owner nor approved"
        );

        address operator = _msgSender();

        _beforeTokenTransfer(operator, from, to, ids, amounts, data);

        for (uint256 i = 0; i < ids.length; ++i) {
            uint256 id = ids[i];
            uint256 amount = amounts[i];

            _balances[id][from] = _balances[id][from].sub(
                amount,
                "KIP37: insufficient balance for transfer"
            );
            _balances[id][to] = _balances[id][to].add(amount);
        }

        emit TransferBatch(operator, from, to, ids, amounts);

        require(
            _doSafeBatchTransferAcceptanceCheck(
                operator,
                from,
                to,
                ids,
                amounts,
                data
            ),
            "KIP37: batch transfer to non KIP37Receiver implementer"
        );
    }

    /**
     * @dev Sets a new URI for all token types, by relying on the token type ID
     * substituion mechanism
     * http://kips.klaytn.com/KIPs/kip-37#metadata.
     *
     * By this mechanism, any occurence of the `\{id\}` substring in either the
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
    function _setURI(string memory newuri) internal {
        _uri = newuri;
    }

    /**
     * @dev Creates `amount` tokens of token type `id`, and assigns them to `account`.
     *
     * Emits a {TransferSingle} event.
     *
     * Requirements:
     *
     * - `account` cannot be the zero address.
     * - If `to` refers to a smart contract, it must implement {IKIP37Receiver-onKIP37Received} and return the
     * acceptance magic value.
     */
    function _mint(
        address account,
        uint256 id,
        uint256 amount,
        bytes memory data
    ) internal {
        require(account != address(0), "KIP37: mint to the zero address");

        address operator = _msgSender();

        _beforeTokenTransfer(
            operator,
            address(0),
            account,
            _asSingletonArray(id),
            _asSingletonArray(amount),
            data
        );

        _balances[id][account] = _balances[id][account].add(amount);
        _totalSupply[id] = _totalSupply[id].add(amount);
        emit TransferSingle(operator, address(0), account, id, amount);

        require(
            _doSafeTransferAcceptanceCheck(
                operator,
                address(0),
                account,
                id,
                amount,
                data
            ),
            "KIP37: transfer to non KIP37Receiver implementer"
        );
    }

    /**
     * @dev Batch-operations version of {_mint}.
     *
     * Requirements:
     *
     * - `ids` and `amounts` must have the same length.
     * - If `to` refers to a smart contract, it must implement {IKIP37Receiver-onKIP37BatchReceived} and return the
     * acceptance magic value.
     */
    function _mintBatch(
        address to,
        uint256[] memory ids,
        uint256[] memory amounts,
        bytes memory data
    ) internal {
        require(to != address(0), "KIP37: mint to the zero address");
        require(
            ids.length == amounts.length,
            "KIP37: ids and amounts length mismatch"
        );

        address operator = _msgSender();

        _beforeTokenTransfer(operator, address(0), to, ids, amounts, data);

        for (uint256 i = 0; i < ids.length; i++) {
            _balances[ids[i]][to] = amounts[i].add(_balances[ids[i]][to]);
            _totalSupply[ids[i]] = amounts[i].add(_totalSupply[ids[i]]);
        }

        emit TransferBatch(operator, address(0), to, ids, amounts);

        require(
            _doSafeBatchTransferAcceptanceCheck(
                operator,
                address(0),
                to,
                ids,
                amounts,
                data
            ),
            "KIP37: batch transfer to non KIP37Receiver implementer"
        );
    }

    /**
     * @dev Destroys `amount` tokens of token type `id` from `account`
     *
     * Requirements:
     *
     * - `account` cannot be the zero address.
     * - `account` must have at least `amount` tokens of token type `id`.
     */
    function _burn(
        address account,
        uint256 id,
        uint256 amount
    ) internal {
        require(account != address(0), "KIP37: burn from the zero address");

        address operator = _msgSender();

        _beforeTokenTransfer(
            operator,
            account,
            address(0),
            _asSingletonArray(id),
            _asSingletonArray(amount),
            ""
        );

        _balances[id][account] = _balances[id][account].sub(
            amount,
            "KIP37: burn amount exceeds balance"
        );

        _totalSupply[id] = _totalSupply[id].sub(
            amount,
            "KIP37: burn amount exceeds total supply"
        );

        emit TransferSingle(operator, account, address(0), id, amount);
    }

    /**
     * @dev Batch-operations version of {_burn}.
     *
     * Requirements:
     *
     * - `ids` and `amounts` must have the same length.
     */
    function _burnBatch(
        address account,
        uint256[] memory ids,
        uint256[] memory amounts
    ) internal {
        require(account != address(0), "KIP37: burn from the zero address");
        require(
            ids.length == amounts.length,
            "KIP37: ids and amounts length mismatch"
        );

        address operator = _msgSender();

        _beforeTokenTransfer(operator, account, address(0), ids, amounts, "");

        for (uint256 i = 0; i < ids.length; i++) {
            _balances[ids[i]][account] = _balances[ids[i]][account].sub(
                amounts[i],
                "KIP37: burn amount exceeds balance"
            );

            _totalSupply[ids[i]] = _totalSupply[ids[i]].sub(
                amounts[i],
                "KIP37: burn amount exceeds total supply"
            );
        }

        emit TransferBatch(operator, account, address(0), ids, amounts);
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
    ) internal {}

    function _doSafeTransferAcceptanceCheck(
        address operator,
        address from,
        address to,
        uint256 id,
        uint256 amount,
        bytes memory data
    ) private returns (bool) {
        bool success;
        bytes memory returndata;

        if (!to.isContract()) {
            return true;
        }

        (success, returndata) = to.call(
            abi.encodeWithSelector(
                _ERC1155_RECEIVED,
                operator,
                from,
                id,
                amount,
                data
            )
        );
        if (
            returndata.length != 0 &&
            abi.decode(returndata, (bytes4)) == _ERC1155_RECEIVED
        ) {
            return true;
        }

        (success, returndata) = to.call(
            abi.encodeWithSelector(
                _KIP37_RECEIVED,
                operator,
                from,
                id,
                amount,
                data
            )
        );
        if (
            returndata.length != 0 &&
            abi.decode(returndata, (bytes4)) == _KIP37_RECEIVED
        ) {
            return true;
        }

        return false;
    }

    function _doSafeBatchTransferAcceptanceCheck(
        address operator,
        address from,
        address to,
        uint256[] memory ids,
        uint256[] memory amounts,
        bytes memory data
    ) private returns (bool) {
        bool success;
        bytes memory returndata;

        if (!to.isContract()) {
            return true;
        }

        (success, returndata) = to.call(
            abi.encodeWithSelector(
                _ERC1155_BATCH_RECEIVED,
                operator,
                from,
                ids,
                amounts,
                data
            )
        );
        if (
            returndata.length != 0 &&
            abi.decode(returndata, (bytes4)) == _ERC1155_BATCH_RECEIVED
        ) {
            return true;
        }

        (success, returndata) = to.call(
            abi.encodeWithSelector(
                _KIP37_BATCH_RECEIVED,
                operator,
                from,
                ids,
                amounts,
                data
            )
        );
        if (
            returndata.length != 0 &&
            abi.decode(returndata, (bytes4)) == _KIP37_BATCH_RECEIVED
        ) {
            return true;
        }

        return false;
    }

    function _asSingletonArray(uint256 element)
        private
        pure
        returns (uint256[] memory)
    {
        uint256[] memory array = new uint256[](1);
        array[0] = element;

        return array;
    }
}

// File: contracts/token/KIP37/KIP37Burnable.sol

// SPDX-License-Identifier: MIT

pragma solidity ^0.5.0;


/**
 * @dev Extension of {KIP37} that allows token holders to destroy both their
 * own tokens and those that they have been approved to use.
 */
contract KIP37Burnable is KIP37 {
    /*
     *     bytes4(keccak256('burn(address,uint256,uint256)')) == 0xf5298aca
     *     bytes4(keccak256('burnBatch(address,uint256[],uint256[])')) == 0x6b20c454
     *
     *     => 0xf5298aca ^ 0x6b20c454 == 0x9e094e9e
     */
    bytes4 private constant _INTERFACE_ID_KIP37_BURNABLE = 0x9e094e9e;

    constructor() public {
        _registerInterface(_INTERFACE_ID_KIP37_BURNABLE);
    }

    function burn(
        address account,
        uint256 id,
        uint256 value
    ) public {
        require(
            account == _msgSender() || isApprovedForAll(account, _msgSender()),
            "KIP37: caller is not owner nor approved"
        );

        _burn(account, id, value);
    }

    function burnBatch(
        address account,
        uint256[] memory ids,
        uint256[] memory values
    ) public {
        require(
            account == _msgSender() || isApprovedForAll(account, _msgSender()),
            "KIP37: caller is not owner nor approved"
        );

        _burnBatch(account, ids, values);
    }
}

// File: contracts/access/Roles.sol

pragma solidity ^0.5.0;

/**
 * @title Roles
 * @dev Library for managing addresses assigned to a Role.
 */
library Roles {
    struct Role {
        mapping (address => bool) bearer;
    }

    /**
     * @dev Give an account access to this role.
     */
    function add(Role storage role, address account) internal {
        require(!has(role, account), "Roles: account already has role");
        role.bearer[account] = true;
    }

    /**
     * @dev Remove an account's access to this role.
     */
    function remove(Role storage role, address account) internal {
        require(has(role, account), "Roles: account does not have role");
        role.bearer[account] = false;
    }

    /**
     * @dev Check if an account has this role.
     * @return bool
     */
    function has(Role storage role, address account) internal view returns (bool) {
        require(account != address(0), "Roles: account is the zero address");
        return role.bearer[account];
    }
}

// File: contracts/access/roles/PauserRole.sol

pragma solidity ^0.5.0;


contract PauserRole {
    using Roles for Roles.Role;

    event PauserAdded(address indexed account);
    event PauserRemoved(address indexed account);

    Roles.Role private _pausers;

    constructor () internal {
        _addPauser(msg.sender);
    }

    modifier onlyPauser() {
        require(isPauser(msg.sender), "PauserRole: caller does not have the Pauser role");
        _;
    }

    function isPauser(address account) public view returns (bool) {
        return _pausers.has(account);
    }

    function addPauser(address account) public onlyPauser {
        _addPauser(account);
    }

    function renouncePauser() public {
        _removePauser(msg.sender);
    }

    function _addPauser(address account) internal {
        _pausers.add(account);
        emit PauserAdded(account);
    }

    function _removePauser(address account) internal {
        _pausers.remove(account);
        emit PauserRemoved(account);
    }
}

// File: contracts/lifecycle/Pausable.sol

pragma solidity ^0.5.0;


/**
 * @dev Contract module which allows children to implement an emergency stop
 * mechanism that can be triggered by an authorized account.
 *
 * This module is used through inheritance. It will make available the
 * modifiers `whenNotPaused` and `whenPaused`, which can be applied to
 * the functions of your contract. Note that they will not be pausable by
 * simply including this module, only once the modifiers are put in place.
 */
contract Pausable is PauserRole {
    /**
     * @dev Emitted when the pause is triggered by a pauser (`account`).
     */
    event Paused(address account);

    /**
     * @dev Emitted when the pause is lifted by a pauser (`account`).
     */
    event Unpaused(address account);

    bool private _paused;

    /**
     * @dev Initializes the contract in unpaused state. Assigns the Pauser role
     * to the deployer.
     */
    constructor () internal {
        _paused = false;
    }

    /**
     * @dev Returns true if the contract is paused, and false otherwise.
     */
    function paused() public view returns (bool) {
        return _paused;
    }

    /**
     * @dev Modifier to make a function callable only when the contract is not paused.
     */
    modifier whenNotPaused() {
        require(!_paused, "Pausable: paused");
        _;
    }

    /**
     * @dev Modifier to make a function callable only when the contract is paused.
     */
    modifier whenPaused() {
        require(_paused, "Pausable: not paused");
        _;
    }

    /**
     * @dev Called by a pauser to pause, triggers stopped state.
     */
    function pause() public onlyPauser whenNotPaused {
        _paused = true;
        emit Paused(msg.sender);
    }

    /**
     * @dev Called by a pauser to unpause, returns to normal state.
     */
    function unpause() public onlyPauser whenPaused {
        _paused = false;
        emit Unpaused(msg.sender);
    }
}

// File: contracts/token/KIP37/KIP37Pausable.sol

// SPDX-License-Identifier: MIT

pragma solidity ^0.5.0;



/**
 * @dev KIP37 token with pausable token transfers, minting and burning.
 *
 * Useful for scenarios such as preventing trades until the end of an evaluation
 * period, or having an emergency switch for freezing all token transfers in the
 * event of a large bug.
 *
 * _Available since v3.1._
 */
contract KIP37Pausable is KIP37, Pausable {
    mapping(uint256 => bool) private _tokenPaused;

    /*
     *     bytes4(keccak256('pause()')) == 0x8456cb59
     *     bytes4(keccak256('pause(uint256)')) == 0x136439dd
     *     bytes4(keccak256('paused()')) == 0x5c975abb
     *     bytes4(keccak256('paused(uint256)')) == 0x00dde10e
     *     bytes4(keccak256('unpause()')) == 0x3f4ba83a
     *     bytes4(keccak256('unpause(uint256)')) == 0xfabc1cbc
     *
     *     => 0x8456cb59 ^ 0x136439dd ^ 0x5c975abb ^
     *        0x00dde10e ^ 0x3f4ba83a ^ 0xfabc1cbc == 0x0e8ffdb7
     */
    bytes4 private constant _INTERFACE_ID_KIP37_PAUSABLE = 0x0e8ffdb7;

    constructor() public {
        _registerInterface(_INTERFACE_ID_KIP37_PAUSABLE);
    }

    /**
     * @dev Emitted when the pause is triggered by a pauser (`account`) with token ID.
     */
    event Paused(uint256 tokenId, address account);

    /**
     * @dev Emitted when the pause is lifted by a pauser (`account`) with token ID.
     */
    event Unpaused(uint256 tokenId, address account);

    /// @notice Checks whether the specific token is paused.
    /// @return True if the specific token is paused, false otherwise
    function paused(uint256 _id) public view returns (bool) {
        return _tokenPaused[_id];
    }

    /// @notice Pauses actions related to transfer and approval of the specific token.
    /// @dev Throws if `msg.sender` is not allowed to pause.
    ///   Throws if the specific token is paused.
    function pause(uint256 _id) public onlyPauser {
        require(_tokenPaused[_id] == false, "KIP37Pausable: already paused");
        _tokenPaused[_id] = true;
        emit Paused(_id, msg.sender);
    }

    /// @notice Resumes from the paused state of the specific token.
    /// @dev Throws if `msg.sender` is not allowed to unpause.
    ///   Throws if the specific token is not paused.
    function unpause(uint256 _id) public onlyPauser {
        require(_tokenPaused[_id] == true, "KIP37Pausable: already unpaused");
        _tokenPaused[_id] = false;
        emit Unpaused(_id, msg.sender);
    }

    /**
     * @dev See {KIP37-_beforeTokenTransfer}.
     *
     * Requirements:
     *
     * - the contract must not be paused.
     */
    function _beforeTokenTransfer(
        address operator,
        address from,
        address to,
        uint256[] memory ids,
        uint256[] memory amounts,
        bytes memory data
    ) internal {
        require(!paused(), "KIP37Pausable: token transfer while paused");
        for (uint256 i = 0; i < ids.length; i++) {
            require(
                _tokenPaused[ids[i]] == false,
                "KIP37Pausable: the token is paused"
            );
        }
    }
}

// File: contracts/access/roles/MinterRole.sol

pragma solidity ^0.5.0;


contract MinterRole {
    using Roles for Roles.Role;

    event MinterAdded(address indexed account);
    event MinterRemoved(address indexed account);

    Roles.Role private _minters;

    constructor () internal {
        _addMinter(msg.sender);
    }

    modifier onlyMinter() {
        require(isMinter(msg.sender), "MinterRole: caller does not have the Minter role");
        _;
    }

    function isMinter(address account) public view returns (bool) {
        return _minters.has(account);
    }

    function addMinter(address account) public onlyMinter {
        _addMinter(account);
    }

    function renounceMinter() public {
        _removeMinter(msg.sender);
    }

    function _addMinter(address account) internal {
        _minters.add(account);
        emit MinterAdded(account);
    }

    function _removeMinter(address account) internal {
        _minters.remove(account);
        emit MinterRemoved(account);
    }
}

// File: contracts/token/KIP37/KIP37Mintable.sol

pragma solidity ^0.5.0;



/**
 * @dev Extension of {KIP37} that allows token holders to destroy both their
 * own tokens and those that they have been approved to use.
 */
contract KIP37Mintable is KIP37, MinterRole {
    /*
     *     bytes4(keccak256('create(uint256,uint256,string)')) == 0x4b068c78
     *     bytes4(keccak256('mint(uint256,address,uint256)')) == 0x836a1040
     *     bytes4(keccak256('mint(uint256,address[],uint256[])')) == 0xcfa84fc1
     *     bytes4(keccak256('mintBatch(address,uint256[],uint256[])')) == 0xd81d0a15
     *
     *     => 0x4b068c78 ^ 0x836a1040 ^ 0xcfa84fc1 ^ 0xd81d0a15 == 0xdfd9d9ec
     */
    bytes4 private constant _INTERFACE_ID_KIP37_MINTABLE = 0xdfd9d9ec;

    // id => creators
    mapping(uint256 => address) public creators;

    mapping(uint256 => string) _uris;

    constructor() public {
        _registerInterface(_INTERFACE_ID_KIP37_MINTABLE);
    }

    function _exists(uint256 tokenId) internal view returns (bool) {
        address creator = creators[tokenId];
        return creator != address(0);
    }

    /**
     * @dev See {IKIP37MetadataURI-uri}.
     *
     * This implementation returns the same URI for *all* token types. It relies
     * on the token type ID substituion mechanism
     * http://kips.klaytn.com/KIPs/kip-37#metadata
     *
     * Clients calling this function must replace the `\{id\}` substring with the
     * actual token type ID.
     */
    function uri(uint256 tokenId) external view returns (string memory) {
        string memory customURI = string(_uris[tokenId]);
        if(bytes(customURI).length != 0) {
            return customURI;
        }

        return _uri;
    }

    /// @notice Creates a new token type and assigns _initialSupply to the minter.
    /// @dev Throws if `msg.sender` is not allowed to create.
    ///   Throws if the token id is already used.
    /// @param _id The token id to create.
    /// @param _initialSupply The amount of tokens being minted.
    /// @param _uri The token URI of the created token.
    /// @return A boolean that indicates if the operation was successful.
    function create(
        uint256 _id,
        uint256 _initialSupply,
        string memory _uri
    ) public onlyMinter returns (bool) {
        require(!_exists(_id), "KIP37: token already created");

        creators[_id] = msg.sender;
        _mint(msg.sender, _id, _initialSupply, "");

        if (bytes(_uri).length > 0) {
            _uris[_id] = _uri;
            emit URI(_uri, _id);
        }
    }

    /// @notice Mints tokens of the specific token type `_id` and assigns the tokens according to the variables `_to` and `_value`.
    /// @dev Throws if `msg.sender` is not allowed to mint.
    ///   MUST emit an event `TransferSingle`.
    /// @param _id The token id to mint.
    /// @param _to The address that will receive the minted tokens.
    /// @param _value The quantity of tokens being minted.
    function mint(
        uint256 _id,
        address _to,
        uint256 _value
    ) public onlyMinter {
        require(_exists(_id), "KIP37: nonexistent token");
        _mint(_to, _id, _value, "");
    }

    /// @notice Mints tokens of the specific token type `_id` in a batch and assigns the tokens according to the variables `_toList` and `_values`.
    /// @dev Throws if `msg.sender` is not allowed to mint.
    ///   MUST emit one or more `TransferSingle` events.
    ///   MUST revert if the length of `_toList` is not the same as the length of `_values`.
    /// @param _id The token id to mint.
    /// @param _toList The list of addresses that will receive the minted tokens.
    /// @param _values The list of quantities of tokens being minted.
    function mint(
        uint256 _id,
        address[] memory _toList,
        uint256[] memory _values
    ) public onlyMinter {
        require(_exists(_id), "KIP37: nonexistent token");
        require(
            _toList.length == _values.length,
            "KIP37: toList and _values length mismatch"
        );
        for (uint256 i = 0; i < _toList.length; ++i) {
            address to = _toList[i];
            uint256 value = _values[i];
            _mint(to, _id, value, "");
        }
    }

    /// @notice Mints multiple KIP37 tokens of the specific token types `_ids` in a batch and assigns the tokens according to the variables `_to` and `_values`.
    /// @dev Throws if `msg.sender` is not allowed to mint.
    ///   MUST emit one or more `TransferSingle` events or a single `TransferBatch` event.
    ///   MUST revert if the length of `_ids` is not the same as the length of `_values`.
    /// @param _to The address that will receive the minted tokens.
    /// @param _ids The list of the token ids to mint.
    /// @param _values The list of quantities of tokens being minted.
    function mintBatch(
        address _to,
        uint256[] memory _ids,
        uint256[] memory _values
    ) public onlyMinter {
        for (uint256 i = 0; i < _ids.length; ++i) {
            require(_exists(_ids[i]), "KIP37: nonexistent token");
        }
        _mintBatch(_to, _ids, _values, "");
    }
}

// File: contracts/token/KIP37/KIP37Token.sol

pragma solidity ^0.5.0;





contract KIP37Token is KIP37, KIP37Burnable, KIP37Pausable, KIP37Mintable {
    constructor(string memory uri) public KIP37(uri) {}
}